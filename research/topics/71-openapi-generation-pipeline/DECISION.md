# 2026-09-27 — R71 — openapi-generation-pipeline (bundle, Deep) — decision (revision 3)

**Revision note, revision 3.** Revision 3 is a directed repair of revision 2 (sha256 `702cec90549c412c900155d47c17e18f378e9fac87d3745d47a93ec824667bb4`, preserved byte-identical as `review/R71-r2-snapshot.md`). Both revision-2 audits approved: the judgment audit (`review/audit-fable.r2.md`) with two MECHANICAL findings, and the empirical audit (`review/audit-codex.r2.md`) with three. Revision 3 applies exactly those repairs. **The recommendation does not move**, and no claim, evidence item or command is added beyond the repairs. No file under `review/evidence/` was edited or regenerated; every rerun for this revision wrote to `/tmp`. Both audits must review revision 3.

| Finding | Disposition in this revision |
|---|---|
| **Fable 1 (JF-8)** — `r71-oasdiff.sh` executes `O1`–`O4` only, but the decision says it covers `O1`–`O6` | **Repaired by rewording (alternative b).** Blocker 2, the `r71-oasdiff.sh` row of the evidence table, the first *What P03 must validate* item and the A10 and A11 status cells now say: cases `O1`–`O4` executed by `r71-oasdiff.sh`; `O5` and `O6` are manual follow-on steps whose expectations the log records. The script and its log are unchanged. |
| **Fable 2 (JF-2)** — the per-crate 90-day and all-time download figures are missing | **Repaired.** A download table for `utoipa`, `utoipa-gen`, `utoipa-axum` and `expectorate` now opens *Maintenance state, by the rubric*, from `r71-figures.log` `A` (lines 5, 8, 11 and 20), retrieved 2026-09-27T03:43:23Z. |
| **Codex M1** — the revision-1 citation checker is not replayable against the current decision | **Repaired in text; the committed script is unchanged.** `r71-citations.sh` hardcodes `review/DECISION.md` and takes no path argument. The legacy replay was therefore run from an unmodified copy of the script in a `/tmp` mirror whose `review/DECISION.md` is `review/R71-r1-snapshot.md`. It exited 0 with 124 resolved and 0 unresolved, and its output is byte-identical to the committed `r71-citations.log`. The exact invocation is under `## Empirical check`, beside the historical row. `r71-r2-citations.sh` remains the current-decision check. |
| **Codex M2** — five raw rerun logs differ in run-specific fields | **Repaired.** `## Empirical check` gains a *Revision-2 empirical rerun* note naming the five non-identical byte comparisons and their volatile fields, and stating which stable claims matched. |
| **Codex M3** — mutable counts and branch heads moved | **Repaired.** "py's `main` today" is replaced by the retrieval time. Popularity figures and branch-head evidence are labelled as dated snapshots, and the rerun values are recorded with the 2026-09-27T17:56Z rerun time. The `rust-lang/crates.io` manifest lines are bound to the head commit the same retrieval recorded. |

Revision 3 actor: directed-repair worker, model `claude-opus-5-5`, family anthropic, fresh context, CLI seat, run 2026-09-27 (UTC, host clock). It read the two revision-2 audits named above in full and wrote none of the raw reports, checks or earlier revisions. **Family overlap, recorded for the controller:** this seat shares a model with the `raw/opus.md` leg and with the revision-2 synthesizer.

**Revision note, revision 2.** Revision 2 answers the round-1 judgment audit (`review/audit-fable.md`, verdict `reject`, findings JF-2 and JF-3) of revision 1 (sha256 `f0f9450f226e1b7f53d9fc4664fc8de2fa93af683741cf8effc12b9314e2a4fc`, preserved byte-identical as `review/R71-r1-snapshot.md`). **The recommendation does not move**: the same six members at the same versions, the same exclusions, the same `CONFLICT:` and the same `assumes` lines. The one change to a recommended command is an added flag, `--allow-external-refs=false`, on the F333 `oasdiff` invocation. The round-1 empirical audit (`review/audit-claude.md`) approved revision 1; its approval does not carry over to this revision, and both audits must review revision 2 (both did; revision 3 above applies their repairs). There is no `## Supersedes`, because nothing is reversed.

| Finding | Disposition in this revision |
|---|---|
| **JF-2** — fitness gates 3, 5 and 6 are silently omitted for the selected `oasdiff` binary, and gate 5 for `expectorate`; the prompt says "state `inapplicable` and the reason … do not omit it silently" | **Accepted in full.** Gates 3–6 are now answered for every selected member, from a new read-only check, `review/evidence/r71-r2-gates.sh` / `.log`. For `oasdiff`: gate 3 states RustSec as `inapplicable` (Go, not a crate), lists the two published GitHub advisories, and shows that both are patched below the v1.32.1 pin. It also states the build posture (`CGO_ENABLED=0`). Gate 4 lists the release targets. Gate 5 lists the defaults the invocation relies on, including the working-directory configuration-file lookup. Gate 6 gives download sizes. For `expectorate`, gate 5 lists its one optional feature and its dependencies. The audit's security point is adopted: the invocation now passes `--allow-external-refs=false`, because the compared file is authored by the pull request. The flag is in member 6, the `api-breaking` recipe, the CI step and `r71-oasdiff.sh`. See *Gates 3–6 for every selected member* under `## Decision`. |
| **JF-3** — `## Engines` and `### Landscape` say all four legs reject the same three architectures and reject `build.rs` generation, and list an F312 point with a Gemini divergence under "Where all four legs agree" | **Accepted in full.** *Architectures compared before libraries* now attributes each rejection to the legs that make it, with a per-leg table and raw-line cites. The same correction is made to the last bullet of *Where all four legs agree*. The F312 bullet moves to a new *Where three legs agree* list. The Landscape table's "all four legs agree" note on first-party generators is narrowed the same way: all four legs say the Rust toolchain ships none, and only Muse and Opus also say axum ships none. The decision's own reason for each rejection is unchanged. |

**Evidence in this revision.** Four r1 check pairs are carried **byte-identical**: `r71-figures`, `r71-sources`, `r71-detector` and `r71-probe`, plus `r71-probe-openapi.json` and `oasdiff-fixtures/`. `r71-citations.sh` / `.log` are also byte-identical; they now document the citation check of revision 1. One r1 pair is **regenerated**. `r71-oasdiff.sh` gained the new flag, and its rerun changed only the timestamp and the four `PLANNED` command lines. The six `F0` fixture hashes are identical to revision 1's. Two pairs are **new**: `r71-r2-gates.sh` / `.log` (gate answers) and `r71-r2-citations.sh` / `.log` (the citation check of this file). All three touched scripts are `shellcheck`-clean.

**Provenance carried from revision 1.** This decision synthesizes the four raw reports of run `research/runs/R71/2026-09-26T190301Z-1a03914990f8`: `raw/muse.md`, `raw/opus.md`, `raw/doxa-openai.normalized.md` and `raw/doxa-gemini.normalized.md`. The Doxa legs are read through their normalized copies; the provider dumps beside them were not opened. The consumed decisions are R11 (sha256 `410e88e5…62418c`, revision 7) and R69 (sha256 `d4507f5b…c10d`, revision 9). Both hashes equal `inputs/prerequisites.json`. Every figure, source line and executed result below comes from the checks under `review/evidence/`: the five empirical checks the revision 1 synthesizer wrote and ran, and the revision 2 gate check `r71-r2-gates.sh`.

**Two blockers stand before acceptance. Neither changes the recommendation.**

1. **This decision raises a `CONFLICT:` against R69's `web-extra-surface`.** The generator crates must join the `web` feature, and the registered value lists only `dep:axum` and `dep:tokio` (see `## Parameters`). Under RUNBOOK §4, R71 stays `in-progress` until R69 republishes a value that admits them. The `assumes` line below carries the current registered text, not the needed one.
2. **The F333 breaking-change invocation has not executed.** No `oasdiff` binary is on this host. Every install route — GitHub release assets, `proxy.golang.org`, Docker Hub, Homebrew bottles — lies outside this topic's named endpoints. The fixture pairs, the severity file and the exact commands are committed under `review/evidence/` so the empirical auditor can run them: cases `O1`–`O4` executed by `r71-oasdiff.sh`; `O5` and `O6` are manual follow-on steps whose expectations the log records. **For the controller:** the round-1 empirical audit (`review/audit-claude.md`, §4) reports running `O1`–`O6` against a v1.32.1 binary that it fetched from a host outside the named endpoints. It reports 6 of 6 cases matching their expectation, and it reports the `O5` acceptance-line syntax. That run is the audit's evidence, not this decision's, and it used revision 1's command without `--allow-external-refs=false`. This decision therefore keeps A9–A11 labelled *Planned*. Whether that audit run counts toward acceptance is the controller's call.

Actor `synth-opus-2026-09-26T190301Z-1a03914990f8-r2`, model `claude-opus-5-5`, family anthropic, fresh context, CLI seat, run 2026-09-27 (UTC). Item kind `bundle`, effort tier `deep`. This context wrote neither the raw reports nor revision 1. It read the rejecting judgment audit in full; it read the approving empirical audit for reference only. **Family overlap, recorded for the controller:** RUNBOOK §2 names a fresh Claude Fable context as the default synthesizer. This seat is Claude Opus, the same model as the `raw/opus.md` leg. This context produced none of the raw reports and none of their checks, but the synthesizer and one raw producer share a model.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`**, the wording R69 records under its own gate table. Licences are still reported as facts.

## Decision

**Status: a proposal, to be validated in the implementation phase** (owner ruling, 2026-09-10). `rs-launch-blueprint` has no `src/web/` tree yet. The recommendation below was executed in a throwaway probe crate pinned to R69's versions (`review/evidence/r71-probe.sh`), not in the template. P03 builds the template, and its CI proves or disproves what is recorded here.

**The owner's question — "look at the principle of what Py Launch Blueprint is doing and if we should do the same at all" (`docs/port/OWNER-REVIEW.md`, quoted in the prompt) — is answered yes, for all four rows.** The principle is a machine-checkable HTTP contract: generated from the code, telling the truth about errors, naming operations deliberately, committed for review, and gated against breaking changes. Two registered consumers depend on it. R83's contract fuzzing and R84's typed client each read the committed document, and `research/EXECUTION.json` makes R71 an acceptance prerequisite of both (`acceptance_after: ["R71"]` on R83 and R84). A contract that lies about errors breaks R83's oracle; one that churns operation ids breaks R84's method names. The cost, measured below, is two optional crates, one dev-dependency and one Go binary in CI. Rust's own package registry, `rust-lang/crates.io`, runs the same generation stack at the same pins (`V`, `W` in `r71-sources.log`).

**Recommendation — one stack, six members, all behind R69's `web` feature.**

| # | Member | Ledger row | Mechanism | Version |
|---|---|---|---|---|
| 1 | Code-first generator | F332 (source of truth) | `#[utoipa::path]` on each handler, `#[derive(ToSchema)]` on web DTOs, one `#[derive(OpenApi)]` root | `utoipa` **6.0.0**, optional under `web`, default features (`["macros"]`, which brings `utoipa-gen` 6.0.1) |
| 2 | Router binding | F332 (router and document cannot diverge) | `OpenApiRouter` + `routes!`; `build_router` calls `split_for_parts()` once, yielding `(axum::Router, OpenApi)` | `utoipa-axum` **0.3.0**, optional under `web` |
| 3 | Problem-response declaration pass | **F307** | a plain function over the **merged** document, called right after `split_for_parts()`: it registers R70's envelope schema once and adds a `400` `application/problem+json` `$ref` response to every input-taking operation | template code, about 30 lines in `src/web/openapi.rs`; no crate |
| 4 | Curated operation ids | **F312** | an explicit `operation_id = "<tag>-<name>"` on every `#[utoipa::path]`, enforced by a test that every id is present, unique and prefixed by its first tag | template code; no crate |
| 5 | Committed contract and staleness test | **F332** | `openapi/openapi.json` is committed at the repository root. `tests/openapi.rs` (`#![cfg(feature = "web")]`) compares it with the generated document and prints a unified diff on mismatch. `EXPECTORATE=overwrite` turns the same test into the regenerator, behind `just export-openapi`. `info.version` is a document constant, `"0.0.0"`, not the crate version | `expectorate` **1.3.0**, `[dev-dependencies]` only |
| 6 | Breaking-change gate | **F333** | `oasdiff breaking <base> openapi/openapi.json --allow-external-refs=false --fail-on ERR --severity-levels openapi/oasdiff-levels.txt --err-ignore openapi/breaking-accepted.txt`, a non-compiling CI step whose placement is R11's; `oasdiff-levels.txt` raises `api-operation-id-removed` to `err`; `--allow-external-refs=false` stops oasdiff from resolving any `$ref` outside the file, because the pull request authors the file | `oasdiff` **v1.32.1** release binary, pinned by version and sha256 (`linux_amd64.tar.gz` `sha256:7c8939fc…a1ee7f`, `darwin_all.tar.gz` `sha256:e4d74b7e…1f7187e`; `H` in `r71-figures.log`) |

**Ledger rows this decision settles: F307, F312, F332, F333** (`docs/port/COMMONALITY.md`, all `py-only`, `DIVERGENT`, per the prompt). ts has no web service to compare (`docs/port/areas/web-service.md:100`, per the prompt).

**Not selected**, each with its reason under *Excluded by gate and by fit* below or under `## Engines`:

- **Alternative generators:** `aide` 0.15.1 and `oasgen` 0.25.0 fail gate 2. `poem-openapi` 5.1.16, `dropshot` 0.17.1, `okapi` 0.7.0, `paperclip` 0.9.7 and `apistos` 0.9.0 are bound to another framework.
- **Alternative post-processing:** a `utoipa::Modify` on the derive root.
- **Alternative regenerators and snapshot locations:** a second `[[bin]]` exporter, a `build.rs` writer, and a snapshot under `docs/`.
- **Alternative comparisons:** a hand-rolled `assert_eq!` comparison, and `insta` `.snap` files.
- **Alternative breaking-change engines:** the `oasdiff-action` Docker action as the primary form, `oasdiff` 1.23.0, `--fail-on WARN`, and the Rust differs `jsoncompat`, `brake`, `schemadoc-diff` and `rusty-schema-diff`.

### Landscape, and the architectures compared before any library

**The category.** The API-contract pipeline for the optional `web` surface. It covers five things:

1. How an OpenAPI document is derived from Rust service code.
2. How the document is corrected to describe what the runtime returns (F307).
3. How operation identities stay stable (F312).
4. How the document is committed and kept honest by a test (F332).
5. How a pull request that breaks the contract is caught (F333).

| Bin | Generation (code → OpenAPI) | Snapshot / staleness | Breaking-change detection |
|---|---|---|---|
| Built-in or first-party toolchain | **None.** Neither the Rust project nor `tokio-rs/axum` ships a generator. All four legs say the Rust toolchain ships none (`raw/muse.md:9`, `raw/opus.md:44`, `raw/doxa-openai.normalized.md:11`, `raw/doxa-gemini.normalized.md:7`); only Muse and Opus also say axum ships none | `cargo test` plus a committed file, compared by hand or by a test crate | **None** in Rust |
| Established industry standard | **`utoipa`** + **`utoipa-axum`** (framework-neutral core, axum binding); framework-bound: `poem-openapi`, `dropshot`, `paperclip`, `apistos`, `okapi` | `insta` (general snapshots), `expectorate` (Oxide, plain file), `snapbox` (assert-rs, plain file) | **`oasdiff`** (Go; CLI, library, Docker image, GitHub Action) |
| Up-and-comer | `aide` (axum-native, schemars-based; stable line 0.15.1 since 2025-08-19, 0.16 in alpha); `oasgen` (quiet since 2025-02-25) | — | `jsoncompat`, `brake`, `schemadoc-diff`, `rusty-schema-diff` (all immature; see the gate table) |

**Authorities, and why each counts.**

- **The crates.io API** (`/api/v1/crates/<n>`, `/versions`, `/reverse_dependencies`) is the registry of record for downloads, releases, declared `rust_version` and licence (`A`–`D` in `r71-figures.log`).
- **The GitHub REST API** gives maintenance evidence: stars, archive state, issue search, first maintainer replies (`E`, `F`). It also carries the maintainers' own sources, read at tags: utoipa `utoipa-6.0.0` and `utoipa-axum-0.3.0`, oasdiff `v1.32.1`, oasdiff-action `v0.1.17` (`r71-sources.log` `U`, `Q`, `R`).
- **The OpenAPI Specification 3.1.1**, read from `OAI/OpenAPI-Specification` `versions/3.1.1.md` at `main` at 2026-09-27T03:42:30Z (a dated snapshot), is normative for `info.version` and `operationId` (`O`).
- **RustSec** package pages, checked against a control that returns 200 (`G`).
- **The py precedent** at pin `b55b8c26364cb0f42e56116e6780921976334751`, which was also py's `main` at retrieval, 2026-09-27T03:42:30Z (`P`, `r71-sources.log` line 5). At the revision-2 empirical rerun, 2026-09-27T17:56Z, py `main` was `d39f07fa4801a2d3545862e6aa647e5e95b3a50c` (`review/audit-codex.r2.md`). It is the precedent the principle is extracted from: evidence, not a winner.
- **The annual Rust survey and Rust project publications say nothing specific about OpenAPI tooling.** That is recorded as a gap rather than cited for a claim they do not make.

**Practice evidence — who runs what, read from their own manifests** (`V`, `W`). Star counts, push dates, dependent counts and every `@main` read below are dated snapshots taken at 2026-09-27T03:42:30Z (`r71-sources.log`) and 03:43:23Z (`r71-figures.log`); they are not live values.

| Project | Evidence | Why it is a relevant reference |
|---|---|---|
| **`rust-lang/crates.io`** | `Cargo.toml:82` `axum = { version = "=0.8.9", … }`; `:173` `utoipa = { version = "=6.0.0", … }`; `:174` `utoipa-axum = "=0.3.0"`, read at `main` at 03:42:30Z, whose head the same retrieval recorded as `067b45e1a15fc1b97f7321792b86bdf8d6371d7c` (`W`). At commit `067b45e1`: routes merge through `BaseOpenApi::router()` … `.split_for_parts()` (`src/router.rs:16`, `:113`). Its path-level pass `apply_visibility` runs on the merged document (`src/openapi.rs:118`, `:128`). Its only `Modify` adds security schemes to components (`:55`, `:74`, `:76`). `info` pins `version = "0.0.0"` (`:53`). The served document is snapshot-tested with `insta::assert_json_snapshot!` (`src/tests/openapi.rs:2`, `:10`) | Maintained by the Rust project; 3,703 stars; pushed 2026-09-27. **The exact recommended pins**, and the same pass placement and version constant this decision adopts |
| `meilisearch/meilisearch` | `crates/meilisearch/Cargo.toml:94` `utoipa = { version = "5.5.0", …` (with actix-web) | 59,418 stars, pushed 2026-09-24 |
| `loco-rs/loco-openapi-Initializer` | `Cargo.toml:30` `axum = { version = "0.8.1" }`, `:33` `utoipa = { version = "5.0.0", … }`, `:34` `utoipa-axum = { version = "0.2.0" }` | The official OpenAPI initializer of `loco` (9,266 stars) |
| `oxidecomputer/dropshot`, `oxidecomputer/omicron` | `dropshot/Cargo.toml:105` `expectorate = "1.2.0"`; omicron commits 17 entries under a root `openapi/` directory | Oxide ships a commercial rack on this stack. It is the closest named instance of "generate → commit a plain OpenAPI file at the root → check" |
| `utoipa` reverse dependencies | **1,813** dependents (`D`); `utoipa-axum` 72; `aide` 50 | ecosystem breadth |

**No published Rust template names the generate → snapshot → diff pipeline as a pattern** (the prompt's LOW question). Oxide's `dropshot-api-manager`, cited by the Opus leg (`raw/opus.md:75`), is the nearest product, and it is dropshot-only. The OpenAI leg's VelesDB lead came through a mirror host, and no leg or check verified it at a named endpoint. This is recorded as a gap.

**Architectures compared before libraries.** The legs agree on only one rejected architecture: all four reject design-first. Each other rejection comes from two legs or one, as the table shows. "Not addressed" means the leg neither names the alternative nor gives a position on it.

| Alternative architecture | Muse | Opus | OpenAI | Gemini |
|---|---|---|---|---|
| Design-first (hand-written spec → server stubs) | rejects (`raw/muse.md:21`) | rejects (`raw/opus.md:168`) | rejects "Handwritten/schema-first OpenAPI" (`raw/doxa-openai.normalized.md:62`) | rejects (`raw/doxa-gemini.normalized.md:35`) |
| Runtime-served only, with no committed file | rejects (`raw/muse.md:21`) | rejects (`raw/opus.md:170`) | rejects only "Export from a running server with `curl`" as the export mechanism (`raw/doxa-openai.normalized.md:66`); it does not address a served-only contract | not addressed |
| No contract at all | not addressed | rejects (`raw/opus.md:171`) | implied only, by "Do not adopt only schema generation" (`raw/doxa-openai.normalized.md:196`) | not addressed |
| `build.rs` writes the contract | rejects (`raw/muse.md:117`) | not addressed | rejects (`raw/doxa-openai.normalized.md:67`, `:403`) | not addressed |

This decision rejects all four, each for its own reason. None of the reasons rests on the count of legs:

- **Design-first**: it inverts py's code-is-truth principle, and generated stubs fight R69's hand-written router.
- **Runtime-served only**: it gives R83 and R84 no file to pin and loses review.
- **No contract at all**: R83 and R84 are registered consumers.
- **`build.rs` generation**: a build script that writes a tracked file puts repository side effects into ordinary builds, and it cannot make CI fail on drift. The regenerator this decision selects is the staleness test, under *Where Rust needs a different design from py*, item 3.

Framework-intrinsic generation (`dropshot`, `poem-openapi`) is excluded on fit, because R69 selected axum. **Code-first derive over the axum router is selected.**

### Principles and implementation

**Shared requirement, source and agreement level.** Each row below was read at py's pin (`P` in `r71-sources.log`).

| Row | Principle | Agreement level | py evidence at `b55b8c26` | What may vary in Rust |
|---|---|---|---|---|
| F307 | The published contract describes the error body the runtime actually sends | **Policy** | `web/problems.py:97` docstring "Make the OpenAPI schema tell the truth about 422s"; `:104` `original_openapi = app.openapi`; `:116`–`:119` rewrite each `422` to problem+json; `:125` drops `HTTPValidationError` | rewrite versus insertion; the status set (R70's) |
| F312 | An operation id is a public, reviewed name | **Policy**, plus one observable property: ids are present, unique, and change only by deliberate edit | `web/app.py:77` `def _operation_id(route: APIRoute) -> str:`, `:80` `return f"{prefix}{route.name}"`, `:119` `generate_unique_id_function=_operation_id`; committed ids `ops-healthz`, `ops-readyz`, `projects-list_projects`, `projects-get_project` (`docs/api/openapi.json:16`, `:38`, `:70`, `:147`) | derived versus declared ids |
| F332 | The contract is a committed, reviewable file; CI fails when code and file disagree; one command regenerates it; a release does not stale it | **Architectural pattern** (generate → commit → compare) | `tests/web/test_openapi_snapshot.py:25` asserts the runtime carries `__version__`, `:30` sets `generated["info"]["version"] = SNAPSHOT_VERSION`, `:32`–`:33` compares and names `just export-openapi`; `scripts/export_openapi.py:23` `SNAPSHOT_VERSION = "0.0.0"`; `Justfile:318` `@export-openapi` | file path; regeneration command; how `info.version` is kept out of the diff |
| F333 | A pull request that breaks existing clients fails against the base branch | **Capability**: the check must compare base with head and fail on ERR-level breaks | `.github/workflows/api-contract.yml:44` `uses: oasdiff/oasdiff-action/breaking@v0.1.15`, `:48` `fail-on: ERR`, triggered by `paths:` `docs/api/openapi.json` (`:10`–`:11`) | tool form; CI placement (R11's) |

**Observable acceptance criteria, each labelled by what has actually run.** Labels refer to `review/evidence/r71-probe.log` (`P*`), `r71-detector.log` (`D*`) and `r71-oasdiff.log` (`O*`).

| # | Criterion | Row | Status |
|---|---|---|---|
| A1 | Every input-taking operation documents the framework-rejection status with `application/problem+json` and a `$ref` to the envelope schema | F307 | **Executed** — `P2`: `get /v1/projects/{id} 400 -> "#/components/schemas/Problem"`; `P4`: responses `["200","400","404"]` |
| A2 | The envelope schema appears once under `components.schemas` and is referenced, not inlined | F307 | **Executed** — `P4`: `components.schemas=["Problem","Project"]` |
| A3 | Every operation has an `operationId`; ids are unique; each starts with its first tag and a hyphen | F312 | **Executed** — `P2` passes; `P6`: deleting one attribute fails with `operationId "get_project" lacks the \`projects-\` prefix` |
| A4 | Renaming a handler function does not change its `operationId` or the contract | F312 | **Executed** — `P7`: `get_project` → `fetch_project`, snapshot test still `ok` |
| A5 | `cargo test --features web` fails with a readable diff when the generated document differs from the committed file | F332 | **Executed** — `P5`: a four-line unified diff (`-    "/v1/projects/{id}": {` / `+    "/v1/projects/{project_id}": {` …) and `set EXPECTORATE=overwrite if these changes are intentional` |
| A6 | One documented command regenerates the committed file, byte-identically on a repeat | F332 | **Executed** — `P2`, `P3`: sha256 `d51ddf0b…d714fb` twice, `identical=yes` |
| A7 | A release version bump does not stale the committed file | F332 | **Executed** — `P8`: `version = "0.2.0"`, snapshot test `ok` |
| A8 | Router paths and documented paths cannot diverge | F332 | **Executed** — `P5`: one edit to `#[utoipa::path]` moved the route and the document together |
| A9 | A PR removing an operation fails the breaking check; an additive change passes | F333 | **Planned, not executed** — `O2` (expect exit 1) and `O3` (expect exit 0) |
| A10 | An intended break is accepted by a reviewed, committed line rather than by disabling the check | F333 | **Planned, not executed** — `O5`, a manual follow-on step whose expectation `r71-oasdiff.log` records; `r71-oasdiff.sh` does not execute it |
| A11 | Renaming an `operationId` fails the breaking check | F312, F333 | **Planned, not executed** — `O4` (expect 1 with the severity override), one of the four cases `r71-oasdiff.sh` runs when `oasdiff` is on PATH; `O6` (expect 0 without it), a manual follow-on step whose expectation `r71-oasdiff.log` records |
| A12 | A hand edit of only the committed contract still runs the staleness test on a pull request | F332 | **Executed** against R11's detector body — `D7`: `openapi/openapi.json` gives `code=true web=true` |
| A13 | With `web` off, no generator crate is in the graph and no web test runs | R69 boundary | **Executed** — `P9`: `utoipa` crates on normal edges without `--features web`: `0`; `cargo test --locked` passes with 0 tests |

**Where Rust needs a different design from py, and why each is justified rather than drift.** Every item below was decided on executed evidence.

1. **F307 is an insertion, not a rewrite.** FastAPI documents a `422 HTTPValidationError` on every input-taking operation, and py rewrites it. The utoipa-axum document declares **no** framework error response at all. The raw merged document lists `["200"]` and `["200","404"]` (`P2`, test `raw_document_declares_no_framework_error_response`). At runtime, an axum `Path` rejection is `400 text/plain; charset=utf-8` (`P2`, `runtime_rejection_is_not_yet_problem_json`). So there is nothing to rewrite. The pass **adds** the problem response. Making the runtime match is R70's work; this item only makes the document promise it. That is the right direction for a client, and it is handed to R70 and R83 below.
2. **The pass runs on the merged document, not in a `Modify`.** A `Modify` on the `#[derive(OpenApi)]` root runs inside `ApiDoc::openapi()`, before `utoipa-axum` merges the routed paths. The probe's modifier saw **0** paths while the merged document had **2** (`P2`, `doc_level_modifier_runs_before_routes_are_merged`). The same modifier sees **2** when the paths are listed in the derive instead (`doc_level_modifier_sees_paths_listed_in_the_derive`). Listing them there gives up A8, because the route and the document would then be declared separately. `rust-lang/crates.io` is built exactly this way. Its `Modify` touches only components (`src/openapi.rs:74`–`:76`), and its path-level pass runs on the merged document (`:118`, `:128`–`:129`). This is the direct analogue of py's rule that the wrapper runs after every router is included.
3. **The regenerator is the staleness test.** R49's registered `build-tool-output-shape` allows exactly one `[[bin]]` (`rslbp`, `autobins = false`), and R69 adds only `<app>-serve`, so a dedicated exporter binary breaks a consumed value. The Muse leg's example target is **not** excluded: examples are not `[[bin]]` targets, and the probe's `--example export-openapi` wrote a byte-identical file and refused to run without `web` (`P10`). The test is still preferred, because it is one code path: the comparison and the regeneration cannot disagree, and no second target exists. The example form is the ranked runner-up.
4. **The contract lives at `openapi/openapi.json`, not `docs/api/openapi.json`.** R11's detector skip-list is `^docs/|^\.vscode/|^\.github/ISSUE_TEMPLATE/|^[^/]+\.md$`, extracted verbatim from R11's hash-asserted candidate (`S0` in `r71-detector.log`). A pull request that edits only `docs/api/openapi.json` gives `code=false web=false` (`D1`). That skips `check`, where the staleness test runs, and R11's `openapi-snap` slot, which is gated on `web`. Such a pull request would merge a hand-edited contract past a required check. At the root, `openapi/openapi.json`, `openapi/oasdiff-levels.txt` and `openapi/breaking-accepted.txt` each give `code=true web=true` (`D7`, `D8`, `D3`). The path is also outside R49's `[package] include` allow-list, so it is not packaged. Oxide's omicron keeps its contracts in a root `openapi/` directory (`V`).
5. **`info.version` is the document's own version, not the crate's.** OpenAPI 3.1.1 defines it as "The version of the OpenAPI Document (which is distinct from the OpenAPI Specification version or the version of the API being described or the version of the OpenAPI Description)" (`versions/3.1.1.md:352`, `O`). Setting it to a constant `"0.0.0"` in the derive root, as `rust-lang/crates.io` does (`src/openapi.rs:53`), meets A7 without py's normalization step. The served document and the committed file are then the same bytes. The probe asserts the constant (`document_version_is_the_document_constant_not_the_crate_version`, `P2`), and a version bump leaves the contract untouched (`P8`). This adopts the OpenAI leg's F332 proposal (`raw/doxa-openai.normalized.md:173`); see `## Engines`, Disagreement 6.
6. **The breaking check is a step, not a path-triggered workflow.** R11 forbids trigger-level `paths:` filters, and py's `on: pull_request: paths:` shape (`api-contract.yml:10`–`:11`) does not transfer. A non-compiling check defaults to a step of `hygiene`. The invocation below is a tool call that either an R11 `hygiene` step or R11's `openapi-snap` slot can host. Identical documents exit 0, so running on every event costs one small download.
7. **An operation-id rename must be raised to an error explicitly.** oasdiff v1.32.1 registers `api-operation-id-removed` at `INFO` (`checker/rules.go:616`, `R` in `r71-sources.log`). So `--fail-on ERR`, and `--fail-on WARN` too, would pass a pull request that renames an operation. oasdiff documents a `--severity-levels <file>` override (`docs/BREAKING-CHANGES.md:154`, `:159`). The committed `openapi/oasdiff-levels.txt` holds one line, `api-operation-id-removed err`. Removing a path is already ERR (`rules.go:184`). This half of F312's enforcement is planned, not executed (`O4`, `O6`).

**Minimal realistic example — executed in the probe.** The full sources are the heredocs in `r71-probe.sh`. The core of `src/web/mod.rs` is below. `ApiDoc` is the `#[derive(OpenApi)]` root carrying `info(title = …, version = "0.0.0")`, `tags(…)` and `components(schemas(Problem))`. In the template it carries no modifier. The probe's root carries a `modifiers(&CountRouted)` hook only to measure when a `Modify` runs.

```rust
#[utoipa::path(get, path = "/v1/projects/{id}", tag = "projects",
    operation_id = "projects-get_project",
    params(("id" = u32, Path, description = "Project id")),
    responses(
        (status = 200, body = Project),
        (status = 404, body = Problem, content_type = "application/problem+json")))]
pub async fn get_project(Path(id): Path<u32>) -> Json<Project> { /* … */ }

pub fn build() -> (axum::Router, utoipa::openapi::OpenApi) {
    let (router, mut doc) = OpenApiRouter::with_openapi(ApiDoc::openapi())
        .routes(routes!(list_projects))
        .routes(routes!(get_project))
        .split_for_parts();
    declare_problem_responses(&mut doc); // F307, on the merged document
    (router, doc)
}

pub fn openapi_json() -> String {
    let (_, doc) = build();
    serde_json::to_string_pretty(&doc).expect("OpenAPI serializes") + "\n"
}
```

`declare_problem_responses` walks `doc.paths.paths`. For every operation with parameters or a request body, it inserts a `"400"` response. That response's `application/problem+json` content has the schema `Ref::from_schema_name("Problem")`, built with utoipa's public `ResponseBuilder` and `ContentBuilder`. The probe also sets `doc.info.version = API_DOCUMENT_VERSION` in `build()`; that line is redundant with the derive's `version = "0.0.0"`, so the template needs only one of the two. `tests/openapi.rs` (`#![cfg(feature = "web")]`) holds the staleness test and the id, problem and version tests:

```rust
/// Regenerate with: EXPECTORATE=overwrite cargo test --locked --features web --test openapi openapi_snapshot_is_current
#[test]
fn openapi_snapshot_is_current() {
    expectorate::assert_contents("openapi/openapi.json", &web::openapi_json());
}
```

The committed probe document is `review/evidence/r71-probe-openapi.json` (2,972 bytes, sha256 `d51ddf0b…d714fb`, `openapi` `3.1.0`). Its `info.description` and `info.license.name` are empty only because the probe's `Cargo.toml` has neither field. utoipa fills them from package metadata at compile time. So in the template, an edit to the package description re-stales the contract, visibly and reviewably.

**Recipes and CI invocation.** Recipes invoke `cargo` bare, per R42's `package-manager-invocation`.

```just
# Regenerate the committed OpenAPI contract (F332). Run after any route or schema change.
export-openapi:
    mkdir -p openapi
    EXPECTORATE=overwrite cargo test --locked --features web --test openapi openapi_snapshot_is_current

# Compare the working contract with a base ref's (F333); needs oasdiff v1.32.1 on PATH.
api-breaking base="origin/main":
    mkdir -p target
    git show {{base}}:openapi/openapi.json > target/openapi.base.json
    oasdiff breaking target/openapi.base.json openapi/openapi.json --allow-external-refs=false --fail-on ERR --severity-levels openapi/oasdiff-levels.txt --err-ignore openapi/breaking-accepted.txt
```

The `mkdir -p` is required. `expectorate` does not create the parent directory: the first overwrite without it failed with `unable to write to openapi/openapi.json: No such file or directory` (`P2`, `overwrite-without-dir`).

The CI step body, for whichever placement R11 applies:

```bash
set -euo pipefail
snap=openapi/openapi.json
# BASE_SHA: pull_request.base.sha, merge_group.base_sha, or push `before`, set in the step's env.
if [ -z "${BASE_SHA:-}" ] || [ "${BASE_SHA}" = "0000000000000000000000000000000000000000" ]; then
  echo "no base commit to compare against"; exit 0
fi
git fetch --no-tags --depth=1 origin "${BASE_SHA}"
if ! git cat-file -e "${BASE_SHA}:${snap}" 2>/dev/null; then
  echo "the base commit has no committed contract; this change introduces it"; exit 0
fi
git show "${BASE_SHA}:${snap}" > "${RUNNER_TEMP}/openapi.base.json"
oasdiff breaking "${RUNNER_TEMP}/openapi.base.json" "${snap}" \
  --allow-external-refs=false --fail-on ERR --severity-levels openapi/oasdiff-levels.txt --err-ignore openapi/breaking-accepted.txt
```

`oasdiff` v1.32.1 is installed from its release tarball and verified against the pinned sha256 above. It is presence-tested with `command -v oasdiff` (R42: a tool installed from a release). The acquisition step is R42's to write. **This block is a proposal; no runner has executed it.**

**Why `--allow-external-refs=false`.** oasdiff v1.32.1 registers the flag with default `true` and the help text "disable to prevent SSRF when processing untrusted specs" (`internal/cmd_flags.go:26`, `X` in `r71-r2-gates.log`). The `breaking` command inherits it (`internal/breaking_changes.go:20`). The step runs on `pull_request`, and the pull request's author, including a fork's author, controls `openapi/openapi.json`. With the default, a `$ref` to a URL or a local path would make the runner fetch or read it. The committed contract needs no external reference: the committed probe document `review/evidence/r71-probe-openapi.json` has 4 `$ref` values, and each is `#/components/schemas/Problem` or `#/components/schemas/Project` (read from the file for this revision; `P4` lists those two schemas). So the flag costs nothing today. A future contract that is split across files would have to turn it back on deliberately, and that change would be reviewed.

**Fitness gates, answered before popularity.** The floor is **1.96**: stable `rustc 1.98.1` (`P0`) minus two minors. Gate 2 reads the newest non-yanked stable version's declared `rust_version` from `/api/v1/crates/<n>/versions` (`A`, `B`). A candidate that declares none fails gate 2, the reading R69 applied to `warp`, `viz`, `pavex` and `tide`.

| Candidate | Newest stable (date) | Licence (reported, not gated) | Gate 2 `rust_version` | Outcome |
|---|---|---|---|---|
| `utoipa` | 6.0.0 (2026-09-22) | MIT OR Apache-2.0 | 1.88 — pass | **Selected** |
| `utoipa-gen` (via `macros`) | 6.0.1 (2026-09-23) | MIT OR Apache-2.0 | 1.88 — pass | selected transitively |
| `utoipa-axum` | 0.3.0 (2026-09-22) | MIT OR Apache-2.0 | 1.88 — pass | **Selected** |
| `expectorate` | 1.3.0 (2026-08-20) | Apache-2.0 | 1.85 — pass | **Selected** (dev-dependency) |
| `aide` | 0.15.1 (2025-08-19); newest 0.16.0-alpha.4 (2026-04-14) | MIT OR Apache-2.0 | **none declared, in all 53 published versions — FAIL** | **Excluded by gate 2** |
| `oasgen` | 0.25.0 (2025-02-25) | MIT | **none declared — FAIL** | **Excluded by gate 2**; quiet since 2025-02-25 |
| `poem-openapi` | 5.1.16 (2025-07-28) | MIT OR Apache-2.0 | 1.85 — pass | Excluded on **fit**: requires `poem`, and R69 selected axum |
| `dropshot` | 0.17.1 (2026-06-02) | Apache-2.0 | 1.85 — pass | Excluded on **fit**: its own server; R69 already weighed it |
| `apistos` | 0.9.0 (2026-09-18) | MIT OR Apache-2.0 | 1.88.0 — pass | Excluded on **fit**: actix-web only |
| `paperclip` | 0.9.7 (2026-04-20) | MIT OR Apache-2.0 | **none declared — FAIL** | Excluded by gate 2; actix-web only |
| `okapi` | 0.7.0 (2024-01-14) | MIT | **none declared — FAIL** | Excluded by gate 2; Rocket only |
| `insta` (text `.snap`) | 1.48.0 (2026-06-11) | Apache-2.0 | 1.66.0 — pass | Excluded **by requirement**, not by gate: a `.snap` file carries a YAML header and is not a consumable OpenAPI document (see Disagreement 5) |
| `snapbox` | 1.2.2 (2026-05-26) | MIT OR Apache-2.0 | 1.85 — pass | Qualified alternative; not probed |
| `jsoncompat` | 0.4.2 (2026-08-05) | MIT | **none declared — FAIL** | Excluded by gate 2; 17 stars |
| `brake` | 2026.9.3 (2026-09-19) | MIT | **1.98.1 — FAIL**, above the 1.96 floor | Excluded by gate 2; 119 downloads, 0 stars |
| `schemadoc-diff` | 0.1.20 (2023-07-13) | Apache-2.0 | **none declared — FAIL** | Excluded by gate 2; no repository; 6 downloads in 90 days |
| `rusty-schema-diff` | 0.1.1 (2024-12-11) | `non-standard` (reported only) | **none declared — FAIL** | Excluded by gate 2; 6 downloads in 90 days |
| `oasdiff` (Go binary) | v1.32.1 (2026-09-15); v1.33.0-rc.1 is a prerelease | Apache-2.0 (oasdiff `v1.32.1` licence file, line 1: "Apache License"; `R`) | **inapplicable** — not a Cargo dependency, adds nothing to `Cargo.lock` | **Selected** |

**Gates 3–6 for every selected member.** Revision 2 adds the `oasdiff` and `expectorate` answers that revision 1 omitted. Their source is `review/evidence/r71-r2-gates.log`: `X` lines for `oasdiff`, `Y` lines for `expectorate`.

- **Gate 3 — advisories and `unsafe`.** RustSec returns 404 for `utoipa`, `utoipa-gen`, `utoipa-axum` and `expectorate`, against a `time.html` control that returns 200 (`G`). That is a reading, not a scan. `cargo audit` needs the advisory database from `github.com`, which is not a named endpoint, so it was not run. The `unsafe` keyword appears on **0** lines of `utoipa-6.0.0`, `utoipa-gen-6.0.1`, `utoipa-axum-0.3.0` and `expectorate-1.3.0` sources, against control `fn` counts of 592, 719, 60 and 21. None declares `forbid(unsafe_code)` (`P15`).
  - **`oasdiff`: RustSec is `inapplicable`**, because oasdiff is a Go program, not a crate. Its published GitHub security advisories were read instead (`X`). There are two, both medium severity:

    | Advisory | Summary | Affected | Patched |
    |---|---|---|---|
    | `GHSA-2jcc-mxv7-p3f9` | `--allow-external-refs=false` not enforced on the git-revision load path (SSRF, local file read) | `>= 1.13.2, <= 1.18.0` | `1.18.1` |
    | `GHSA-m3wq-w7x2-4q6m` | a git revision parsed as a git option, allowing an arbitrary file write | `<= 1.26.0` | `1.26.1` |

    **Neither affects the v1.32.1 pin, so gate 3 passes.** Both advisories concern loading a spec from a git revision. This invocation compares two plain files and leaves `--fetch` at its default, `false` (`internal/cmd_flags.go:28`).
  - **`oasdiff` memory-safety posture.** Go is garbage-collected and bounds-checked. The release binaries are built with `CGO_ENABLED=0` (`.goreleaser.yml:13`), so no C code is linked in. Use of Go's `unsafe` package by oasdiff or its modules was **not scanned**, because the source-archive host is not a named endpoint (gap 10). The remaining exposure is oasdiff parsing a file the pull request authored. `--allow-external-refs=false` confines that parsing to the file itself (see *Why `--allow-external-refs=false`* above).
- **Gate 4 — OS.** utoipa's upstream CI runs on `ubuntu-latest` only (`build.yaml:34`, `H`). macOS evidence is this probe on Darwin arm64, where every test passed on 1.98.1 and on 1.96.1 (`P2`, `P12`). `expectorate`'s CI matrix is `[ubuntu-22.04, windows-2022, macos-latest]` (`rust.yml:24`). **No Linux run of the probe exists**; P03's `check` matrix is the first. Windows is not required and was not verified.
  - **`oasdiff`.** The v1.32.1 release carries 12 assets (`X`). `oasdiff_1.32.1_linux_amd64.tar.gz` serves `ubuntu-latest`, and the universal `oasdiff_1.32.1_darwin_all.tar.gz` serves `macos-latest`, so both `target-os-matrix` entries have a release binary. The release is built for `darwin`, `linux` and `windows` on `amd64` and `arm64` (`.goreleaser.yml:5`–`:11`). No OS has executed the invocation here (blocker 2).
- **Gate 5 — features and runtime coupling.** `utoipa` 6.0.0 has `default = ["macros"]` (`C`). The OpenAI leg's `default-features = false, features = ["macros"]` is therefore the same feature set, spelled out. `utoipa-axum` 0.3.0 depends on `axum ^0.8.4`, `pastey`, `tower-layer`, `tower-service` and `utoipa ^6.0.0`, and on **no** `tokio` (`C`). Its only runtime coupling is axum's, which R69 already carries. The core `utoipa` is pure data plus a proc-macro.
  - **`expectorate` 1.3.0.** It has one feature, `predicates`, which is optional and not enabled by default (`features={"predicates":["dep:predicates"]}`, `Y`). Its non-optional normal dependencies are `atomicwrites`, `console`, `newline-converter` and `similar` (`Y`). It has no async-runtime coupling. It is a `[dev-dependencies]` entry only, declared with default features (`expectorate = "=1.3.0"` in the probe), so it never reaches a built artifact.
  - **`oasdiff`.** It has no Cargo features and no runtime coupling; it runs as a separate process that reads two files. These are the defaults the invocation relies on, all read from `internal/cmd_flags.go` at v1.32.1 (`X`):

    | Flag | Default | What the default means for this gate |
    |---|---|---|
    | `match-path`, `unmatch-path` | empty (`internal/cmd_flags.go:13`, `:14`) | every path is compared |
    | `include-path-params` | `false` (`:20`) | renaming only a path parameter does not count as removing the path |
    | `fetch` | `false` (`:28`) | no git objects are fetched |
    | `deprecation-days-beta`, `deprecation-days-stable` | oasdiff's built-in values (`:99`, `:100`) | the deprecation windows are oasdiff's own |
    | `allow-external-refs` | `true` (`:26`) | **overridden** to `false` by this invocation |

    One further input is implicit. Without `--config` or `OASDIFF_CONFIG`, oasdiff reads a `.oasdiff.{json,yaml,yml,toml,hcl}` file, or a legacy `oasdiff.*` file, from the working directory (`internal/viper.go:106`–`:107`, `:124`–`:125`; `internal/run.go:44`). The step runs at the repository root. So a pull request that commits such a file changes the gate's settings. That file joins `oasdiff-levels.txt` and `breaking-accepted.txt` as a control that review must catch. oasdiff reads the file and then binds the command-line flags (`internal/viper.go:48`, `:56`, `:161`). Whether an explicitly passed flag outranks a configuration value is the `viper` library's precedence rule. This synthesizer neither read that rule at a named endpoint nor executed it; the comment at `internal/viper.go:62` ("values where the user explicitly set the corresponding CLI flag") is consistent with it. If the rule holds, a committed configuration file cannot override the four flags this invocation passes, but it can set a flag that is not passed, such as `unmatch-path`. P03 validates this.
- **Gate 6 — cost.** The resolved web graph is 92 locked packages with **no** duplicate crates on normal edges (`P1`; `syn` 3.0.6 appears once). A clean debug build with `--features web` took 16 s wall in the recorded run (`P13`, one run on a loaded macOS arm64 host; two earlier runs of the same script this session measured 10 s and 32 s). The Opus leg's timings attribute about 2.8 s each to `utoipa-gen` and `utoipa` (`raw/opus.md:189`–`:192`). None of this is paid with `web` off (`P9`). Binary size was not measured; the document-building code is linked only where `build()` is.
  - **`expectorate`.** It adds no cost to any shipped build, because it is a dev-dependency. Its compile cost falls on `cargo test --features web` only.
  - **`oasdiff`.** It adds nothing to `Cargo.lock` and nothing is compiled. The cost is one download per CI run: `oasdiff_1.32.1_linux_amd64.tar.gz` is 6,815,540 bytes. A macOS contributor downloads `oasdiff_1.32.1_darwin_all.tar.gz` once: 13,336,632 bytes (`H` in `r71-figures.log`; `X`).

**Maintenance state, by the rubric.**

Registry download figures for each selected crate member, from `r71-figures.log` `A` (lines 5, 8, 11 and 20; `crate.recent_downloads` and `crate.downloads`), retrieved 2026-09-27T03:43:23Z. They are dated snapshots:

| Crate | 90-day downloads | All-time downloads |
|---|---|---|
| `utoipa` | 15,462,313 | 48,906,319 |
| `utoipa-gen` | 15,468,242 | 48,938,245 |
| `utoipa-axum` | 3,181,337 | 7,552,921 |
| `expectorate` | 278,769 | 1,683,740 |

Star counts, open-issue counts and reverse-dependency counts in this section and elsewhere in this decision are likewise snapshots, taken at 2026-09-27T03:43:23Z (`r71-figures.log`) or 03:42:30Z (`r71-sources.log`). The revision-2 empirical rerun at 2026-09-27T17:56Z (`review/audit-codex.r2.md`) recorded these moved values, none of which changes a gate or the recommendation: `utoipa` reverse dependencies 1,810 (was 1,813), `utoipa` stars 4,107 (was 4,106), `oasdiff` stars 1,389 (was 1,387), and `rust-lang/crates.io` `main` at `765bbf47…` (was `067b45e1…`), with the cited code lines and selected dependency pins unchanged.

- **`utoipa` and `utoipa-axum`: `active`.** Release 6.0.0 on 2026-09-22 and `utoipa-gen` 6.0.1 on 2026-09-23. The repository has 4,106 stars, was pushed 2026-09-25, and has 164 open issues (`search/issues`). Of its ten most recently opened issues, 5 were answered, with a median of 0.25 days to the first maintainer reply, and 5 were unanswered (`F`).
- **`expectorate`: `stable-quiet`.** Its only release this year was 2026-08-20. It has 32 stars and 0 open issues. Four issues have ever been filed; two were answered, the most recent in 4.64 days. It has 33 reverse dependencies, including `dropshot`.
- **`oasdiff`: `active`.** Five releases between 2026-08-30 and 2026-09-15. It has 1,387 stars and 48 open issues. Of its ten most recent issues, 4 were answered with a median of 1.1 days; the unanswered six include collaborator-filed tracking issues, which this count does not separate.

**Handed on, not decided here.**

- **R70.** Owns the envelope type, its schema name (the probe uses `Problem`) and the rejection status set. This decision documents `400` for every input-taking operation. `415` and `422` for JSON request bodies join the pass once R70 maps `JsonRejection`. R70, or R83, must add the runtime assertion that a malformed request returns `application/problem+json`. The probe shows it does not yet (`P2`).
- **R83 and R84.** They inherit this contract:
  - the path `openapi/openapi.json`;
  - OpenAPI `3.1.0`;
  - `operationId` values of the form `<tag>-<name>`, identical to py's committed ids;
  - `info.version` `"0.0.0"`.

  R84 must confirm that its generator maps hyphenated ids to valid method names. OpenAPI 3.1.1 makes ids case-sensitive strings and only RECOMMENDS common naming conventions (`versions/3.1.1.md:978`).
- **R11.** Two slot notes for the controller. The staleness test needs no slot of its own, because it runs inside `check`'s "cargo test over the workspace with the feature on" step. The breaking check compiles nothing, so R11's rule makes it a `hygiene` step by default. R11's `openapi-snap` slot, gated on `web`, is therefore **flagged as possibly unnecessary, not removed**. It remains a valid host, because `web` contains every input of the check (`D3`, `D7`, `D8`).
- **R20.** Pinning applies only if the action form is chosen.
- **R37.** Decides whether a hook runs `cargo test --features web --test openapi`.
- **R42.** Owns how `oasdiff` is acquired and presence-tested.

**`BASELINE-REVIEW:`** — none raised by this decision. F307, F312, F332 and F333 are `DIVERGENT` rows appointed to this item, so choosing their Rust mechanisms is deciding them, not challenging a baseline. The two `BASELINE-REVIEW:` lines in the OpenAI leg are dispositioned under `## Engines`, Disagreements 2 and 6.

re-verify: when R69 republishes `web-extra-surface` (the CONFLICT below), when R70's decision is accepted (envelope type name, rejection status set), when R83 or R84 select their tools (confirm OpenAPI 3.1.0 input, `operationId` keying, hyphenated ids), on any `utoipa` 6.0.x/6.1 or `utoipa-axum` 0.3.x/0.4 release, when utoipa emits OpenAPI 3.2 by default, on `oasdiff` v1.33 GA or any change to the level of `api-operation-id-removed`, on any new security advisory against `oasdiff` or any change to the default of `allow-external-refs`, when `aide` publishes a stable release declaring a `rust-version` within the floor, if `expectorate` is archived or R33 is revised toward `snapbox`, if any crate in the `web` graph enables `serde_json/preserve_order`, at the next msrv-policy floor advance, or by 2027-03-27, whichever comes first

## Parameters

This item owns no parameter (the prompt's `- owns:` line is empty). The consumed and fixed values, verbatim from `inputs/parameters.json` (whose `PARAMETERS.md` twin hashes to the manifest's `input_hashes.parameters`, `85f998c1…e9e7fa`):

- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

CONFLICT: R69 web-extra-surface — web = ["dep:axum", "dep:tokio", "dep:utoipa", "dep:utoipa-axum"], adding utoipa 6.0.0 optional with its default features (macros) and utoipa-axum 0.3.0 optional, every other clause of the value unchanged — R71's generator must be on whenever web is on (clause (4) of the value places R71's OpenAPI generation inside the gated src/web/ tree), but the literal dependency list names only axum and tokio; a nested openapi = ["web", ...] feature would leave R71 off under plain --features web and would force every route module to carry cfg-duplicated registration

**Why the CONFLICT is needed, and why the value's own "nest on top" clause does not already cover it.** The registered value says "heavier opt-ins nest on top rather than widening it, as separate features that require web". Read alone, that clause suggests `openapi = ["web", "dep:utoipa", "dep:utoipa-axum"]`. Three facts rule it out.

- **Clause (4) keeps R71 on with `web`.** It names "R71's OpenAPI generation" among the layers that are "on when web is on". A separate feature contradicts that.
- **The annotations are not an optional layer.** `#[utoipa::path]` annotates every handler, and `OpenApiRouter` replaces `Router` in every route module. A nested feature would need `cfg_attr` on each handler and two router constructions per module. That reintroduces the router-and-document divergence A8 exists to prevent.
- **The staleness test would run less often.** It would run only under `--features openapi` or `--all-features`, not on R11's `--features web` step.

The feature-off property is unaffected by widening `web`: without `web`, no `utoipa` crate is in the graph (`P9`). The controller may judge that R69's prose already anticipates this and fold the change into R69's next revision. R11's re-verify line already anticipates an R69 revision 10. Either way, the literal registered value must change before a consumer may adopt it (RUNBOOK §4).

## Empirical check

**Toolchain and OS.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and `cargo 1.98.1 (797e8a9bc 2026-08-05)`; floor `cargo 1.96.1 (356927216 2026-06-26)` through `rustup run 1.96`; Darwin arm64 (`P0`). Private `CARGO_HOME=/tmp/cargo-s13-R71`. Network: the topic's named endpoints — `crates.io/api/v1`, `api.github.com`, `rustsec.org/packages` — plus Cargo's own index and download host for resolution. Retrieval times are UTC on 2026-09-27; Pacific local date 2026-09-26: figures `03:43:23Z`, sources `03:42:30Z`, probe `03:39:01Z`. Revision 2 runs, on the same host: gates `16:52:36Z`, oasdiff `16:53:04Z` (Pacific 2026-09-27). The revision 2 gate check used only `api.github.com` and `crates.io/api/v1`.

**Six empirical checks and two citation checks, one `.sh` and one `.log` each, all under `review/evidence/`.** All eight are `shellcheck`-clean. Every `SC2016` directive carries its reason inline. The label after each script name, `(r1)` or `(r2)`, says which revision last ran it. Scripts marked r1 are byte-identical to revision 1 and were not rerun for revision 2.

| Script | Working directory | What it does | Result |
|---|---|---|---|
| `r71-r2-gates.sh` (r2, new) | any | gates 3–6 for `oasdiff` (`X`: GitHub advisories, `.goreleaser.yml`, `go.mod`, the `breaking` flags and defaults, the configuration-file lookup, every v1.32.1 asset with its size) and gate 5 for `expectorate` (`Y`: features and dependencies from `crates.io/api/v1`) | exit 0; 78 lines |
| `r71-r2-citations.sh` (r2, new) | any | revision 1's citation checker with one change: external cites also resolve against `r71-r2-gates.log` | revision 2: exit 0; 159 resolved, 0 unresolved. The committed log records revision 2's sha256 (`702cec90…67bb4`) and documents that check only. **Revision 3:** the committed script, run in place with its output redirected to `/tmp`, exited 0 against this file with 159 resolved and 0 unresolved |
| `r71-figures.sh` (r1) | repository root (any) | registry, forge, responsiveness, RustSec and release figures (`A`–`H`) | exit 0; 230 lines |
| `r71-sources.sh` (r1) | repository root (any) | primary-source lines through `api.github.com` contents: py at pin (`P`), OpenAPI 3.1.1 (`O`), oasdiff-action (`Q`), oasdiff rules and docs (`R`), utoipa sources (`U`), adopter manifests (`V`), crates.io's pipeline (`W`) | exit 0 |
| `r71-detector.sh` (r1) | repository root | extracts R11's detector body verbatim from `research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/evidence/ci.candidate.r2.yml` (sha256 asserted, `S0`), replaces only the `git diff` line (`S2`), runs eight path fixtures (`D1`–`D8`) | exit 0 |
| `r71-probe.sh` (r1) | a `mktemp -d` directory outside the repository | builds the probe crate from heredocs; 15 steps `P0`–`P15`; writes `r71-probe-openapi.json` and `oasdiff-fixtures/` | exit 0 |
| `r71-oasdiff.sh` (r2, regenerated) | `review/evidence/oasdiff-fixtures/` | the F333 cases against the probe-derived fixtures: cases `O1`–`O4` executed by `r71-oasdiff.sh`; `O5` and `O6` are manual follow-on steps whose expectations the log records; revision 2 adds `--allow-external-refs=false` to every case | exit 0, **NOT EXECUTED**: `oasdiff on PATH: no` (`F1`); the six `F0` fixture hashes equal revision 1's |
| `r71-citations.sh` (r1) | any | resolves every `path:line` cite in the decision: local cites against the run's files, external cites against the `r71-sources.log` and `r71-figures.log` lines captured from `api.github.com` | revision 1: exit 0; 124 resolved, 0 unresolved. Its log records revision 1's sha256 and documents that check only. **Replayed for revision 3** against the preserved revision-1 snapshot: exit 0, 124 resolved, 0 unresolved, output byte-identical to the committed log (see *Legacy citation replay* below) |

**Legacy citation replay (revision 3, codex M1).** `r71-citations.sh` accepts no decision path: it reads `$RUN/review/DECISION.md`, where `RUN` is two directories above the script (script lines 11, 13 and 18). Run in place, it therefore checks the current decision, not revision 1. The revision-2 empirical audit ran it that way against revision 2: exit 1, 139 resolved and 20 unresolved, every unresolved cite a revision-2 gate-source line absent from its revision-1 log inputs (`review/audit-codex.r2.md`). The replay against revision 1 was run from a `/tmp` mirror, with the committed script unchanged:

1. `/tmp/r71-legacy/` mirrors the repository by symlink, except the path to this run's `review/` directory.
2. `/tmp/r71-legacy/research/runs/R71/2026-09-26T190301Z-1a03914990f8/review/DECISION.md` is a copy of `review/R71-r1-snapshot.md`. Its `review/evidence/` holds copies of `r71-citations.sh`, `r71-sources.log` and `r71-figures.log`. `cmp` confirmed all four copies byte-identical to the committed files, and `shellcheck` passed on the script copy and on the mirror-building script.
3. Invocation: `bash /tmp/r71-legacy/research/runs/R71/2026-09-26T190301Z-1a03914990f8/review/evidence/r71-citations.sh > /tmp/r71-legacy-replay.log 2>&1`.

Result: exit 0. Line 1 is `# decision sha256=f0f9450f226e1b7f53d9fc4664fc8de2fa93af683741cf8effc12b9314e2a4fc`; the last line is `# citations resolved=124 unresolved=0`. `cmp` against the committed `r71-citations.log` reports no difference; both hash to `f1c97cccdf97fd987c63e4142ae395a9658c57fe919cf57a99fe873fb397d9c9`. `r71-r2-citations.sh` remains the current-decision check.

**Revision-2 empirical rerun (codex M2).** The revision-2 empirical audit reran all eight scripts at 2026-09-27T17:55–17:56Z and compared each fresh log with its committed log byte for byte (`review/audit-codex.r2.md`). Two comparisons were byte-identical: `r71-detector` and `r71-r2-citations`. The legacy `r71-citations` comparison differed because it read revision 2; the replay above covers it. Five were **not byte-identical**, and in each the first changed line is the retrieval or run timestamp:

| Log | Volatile fields that changed |
|---|---|
| `r71-figures.log` | retrieval timestamp (`03:43:23Z` → `17:56:47Z`); download figures and a few popularity counts |
| `r71-sources.log` | retrieval timestamp (`03:42:30Z` → `17:56:26Z`); moving `main` commits and popularity counts |
| `r71-r2-gates.log` | retrieval timestamp (`16:52:36Z` → `17:56:14Z`); remaining lines identical |
| `r71-oasdiff.log` | run timestamp (`16:53:04Z` → `17:55:22Z`); remaining lines identical |
| `r71-probe.log` | run timestamp (`03:39:01Z` → `17:55:33Z`); the private `CARGO_HOME`; the temporary atomic-write path; a thread ID; test durations; and `P13` wall time (16 s → 9 s) |

The stable claims were compared separately and matched: every expected exit status, the test counts, the generated JSON document and the six fixture hashes. Both raw logs of each pair are retained: the committed logs under `review/evidence/`, unchanged, and the audit's fresh logs in `/tmp/r71-codex-r2.dgjxrl/` on the audit host, outside the repository.

**Observed output of the probe, in the order it ran.**

- **`P1` — resolution.** `cargo generate-lockfile` printed `Locking 91 packages to latest Rust 1.96 compatible versions`; `Cargo.lock` has 92 `name =` entries, sha256 `bc2b62ea…c6b76a`. The tree resolved `axum v0.8.9`, `tokio v1.53.1`, `utoipa v6.0.0`, `utoipa-axum v0.3.0`, `utoipa-gen v6.0.1 (proc-macro)`, `serde_json v1.0.151` and `syn v3.0.6`, with **0** duplicate-crate lines on normal edges.
- **`P2` — regeneration and the full test file.** The overwrite without the `openapi/` directory exited 101 with `unable to write to openapi/openapi.json: No such file or directory`. After `mkdir -p openapi` it exited 0 and wrote 2,972 bytes. The plain run of `cargo test --locked --features web --test openapi` passed **10 of 10**, printing:
  - `routed: modifier saw 0 paths; merged document has 2`;
  - `listed: modifier saw 2 paths`;
  - `raw get /v1/projects responses=["200"]` and `raw get /v1/projects/{id} responses=["200", "404"]`;
  - `default operationId=Some("uncurated_handler")`;
  - `operationIds={"projects-get_project", "projects-list_projects"}`;
  - `get /v1/projects/{id} 400 -> "#/components/schemas/Problem"`;
  - `info.version=0.0.0 CARGO_PKG_VERSION=0.1.0`;
  - `runtime status=400 Bad Request content-type=Some("text/plain; charset=utf-8")`.
- **`P3` — idempotence.** A second regeneration gave the same sha256, `d51ddf0b…d714fb` (`identical=yes`).
- **`P4` — the committed document.** `openapi=3.1.0 info.version=0.0.0`; the two operations with their ids and response sets; `components.schemas=["Problem","Project"]`.
- **`P5` — path-parameter rename.** The expectorate test exited 101 with the four-line unified diff and `set EXPECTORATE=overwrite if these changes are intentional`. The hand-rolled `assert_eq!` test exited 101 with a panic message of **6,918 bytes** of escaped JSON (`left: "{\n  \"openapi\": \"3.1.0\",\n …`).
- **`P6` — deleted `operation_id`.** Exit 101: `get /v1/projects/{id}: operationId "get_project" lacks the \`projects-\` prefix`.
- **`P7` — handler rename.** Exit 0; the snapshot is unchanged.
- **`P8` — `version = "0.2.0"`.** Exit 0; the snapshot is unchanged.
- **`P9` — feature off.** `utoipa` crates on normal edges: `0`; `cargo test --locked` exit 0.
- **`P10` — example-target regenerator.** Output is identical to the committed snapshot. Without `web` it exits 101: `target \`export-openapi\` in package \`r71-probe\` requires the features: \`web\``.
- **`P11` — lint.** `cargo clippy --locked --features web --all-targets -- -D warnings` exit 0, no warnings.
- **`P12` — floor.** `rustup run 1.96 cargo test --locked --features web --test openapi` passed 10 of 10.
- **`P13` — cost.** A clean debug build with `--features web` took 16 s wall in this run.
- **`P14` — fixtures.** Four fixture documents and two control files, with sha256s. `base.json` is byte-identical to `r71-probe-openapi.json`.
- **`P15` — unsafe posture.** Zero `unsafe` lines in the four selected crates.

**Observed output of the detector.** The body that ran is R11's current detector, not an earlier revision's. It carries revision 5's here-string path tests (`research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/evidence/ci.candidate.r2.yml:95`) and revision 6's `^\.github/actions/` workflows pattern (`:108`).

- `D1` `docs/api/openapi.json` gives `code=false web=false workflows=false docs=true`.
- `D5` `docs/api/openapi.json` plus `docs/api/README.md` gives the same.
- `D2`, `D3`, `D4`, `D7`, `D8` (`openapi/…` and `src/web/openapi.rs`) give `code=true web=true`.
- `D6` `README.md` gives `code=true web=true`, because R49's allow-list forces it.

**Not executed, and why.**

- **(1) The oasdiff cases `O1`–`O6`.** They need the binary, and no install route is a named endpoint. The expected exit of each case is written in `r71-oasdiff.log`, and each expectation rests on read rule levels (`rules.go:184`, `:616`). **Required of the empirical auditor:** run `r71-oasdiff.sh` on a host with `oasdiff` v1.32.1 on PATH. The expectations are exit 0 for `O1` and `O3`, and exit 1 for `O2` and `O4`, and the audit should record the finding texts. The acceptance-line syntax for `O5` must then be read from `O4`'s output. Revision 2's cases pass `--allow-external-refs=false`. The round-1 empirical audit ran revision 1's cases, without that flag, against a binary from outside the named endpoints; see blocker 2.
- **(2) `cargo audit`.** Its advisory database is fetched from `github.com`.
- **(3) Any Linux run of the probe.** Only macOS arm64 ran.
- **(4) The CI step block, the Justfile `api-breaking` recipe and the release-binary install.** They are proposals. The `export-openapi` recipe's command ran verbatim, as `P3`'s filtered form.

## Engines

**Legs, identities and substitution.**

| Leg | Actor / model | Family | Report | Collected (UTC) | Headline |
|---|---|---|---|---|---|
| Muse | Muse engine (Meta), per `raw/muse.md:3` | meta | `raw/muse.md` (243 lines) | file time 2026-09-26 13:27 local | utoipa 6 + utoipa-axum 0.3; `Modify` pass; `docs/api/openapi.json`; example-target exporter; `oasdiff-action/breaking@v0.1.17`; **no CONFLICT** |
| Opus | `claude-opus-5-5`, fresh context (`raw/opus.md:3`) | anthropic | `raw/opus.md` (1,030 lines) | file time 2026-09-26 18:28 local | same crates; post-merge pass; `openapi/` path; expectorate; `oasdiff` binary v1.32.1; **CONFLICT R69**; executed probe |
| Doxa — OpenAI | `gpt-5.6-sol` deep research via doxa-research 3.3.0, `scripts/doxa_no_retry.py`, op `research-20260926-153713-53e951db599f4aa0`, job `resp_0e99a18b…d316` | openai | `raw/doxa-openai.normalized.md` (959 lines) | 2026-09-26T22:50:30Z | utoipa 6 with framework left open; `Modify` `ContractPolicy`; dedicated `[[bin]]` exporter; `oasdiff 1.23.0` `--fail-on WARN`; figures `DATA-GAP` |
| Doxa — Gemini | `deep-research-preview-04-2026`, op `research-20260926-153822-06fe8febd60b4851` | google | `raw/doxa-gemini.normalized.md` (434 lines) | 2026-09-27T00:09:00Z | utoipa (framework-agnostic); `Modify` for errors and auto-generated ids; `[[bin]]` exporter; `oasdiff-action/breaking@v0` |

Doxa identities and times come from `operations/doxa.json`. The OpenAI leg estimated USD 1.515 and the Gemini leg USD 6.492, both recorded there as list-price estimates.

**Engine substitution.** The run's input snapshot still lists `- engines: codex, opus, doxa`. The published prompt now reads `- engines: muse, opus, doxa`, and adds a sentence naming the Muse substitution under `engine_overrides`. `diff inputs/prompt.md research/topics/71-openapi-generation-pipeline/prompts/openapi-generation-pipeline.prompt.md` shows exactly those two lines. RUNBOOK §2 records owner decision Q17.A (2026-09-27) extending the substitution to R71 ("muse+opus; plus doxa for Deep … R71"). The legs that ran — Muse, Opus, OpenAI and Gemini — are those the published prompt names. The run's `inputs/prompt.md` hash, `e6d1e4fc…f30acb`, equals the manifest's, so the snapshot is internally consistent and simply predates Q17.A. The Opus leg states its input was "byte-identical" to the topic prompt (`raw/opus.md:5`–`:7`); at synthesis time the two differ by those two lines.

**Where all four legs agree** (settled by agreement plus the evidence cited, never by agreement alone):

- adopt the pipeline, all four rows;
- code-first generation with `utoipa`;
- a committed JSON contract with a test that fails on drift;
- `oasdiff` as the engine, because no Rust differ qualifies;
- reject design-first (`raw/muse.md:21`, `raw/opus.md:168`, `raw/doxa-openai.normalized.md:62`, `raw/doxa-gemini.normalized.md:35`).

**Where three legs agree:**

- explicit per-route `operation_id` for F312 (Muse, Opus, OpenAI). Gemini diverges; see Disagreement 8.

**Where two legs or one address an alternative architecture.** Each position is attributed in the table under *Architectures compared before libraries*:

- Runtime-served only: rejected by Muse and Opus. OpenAI rejects only exporting from a running server with `curl`. Gemini does not address it.
- `build.rs` generation: rejected by Muse and OpenAI. Opus and Gemini do not address it.
- No contract at all: rejected by Opus. OpenAI implies it. Muse and Gemini do not address it.

**Disagreement 1 — whether R71 conflicts with R69's `web-extra-surface`. Settled for the Opus leg: a `CONFLICT:` is required.**
- **Opus:** raises it (`raw/opus.md:926`).
- **Muse:** extends `web` with `dep:utoipa` and `dep:utoipa-axum` (`raw/muse.md:83`) while stating "No `CONFLICT:` lines — the stack fits both consumed values as accepted" (`raw/muse.md:227`).
- **OpenAI, Gemini:** assume R69 still open and write `assumes` placeholders (`raw/doxa-openai.normalized.md:684`; `raw/doxa-gemini.normalized.md:308`).

**Evidence.** The registered value's literal list is `web = ["dep:axum", "dep:tokio"]` (`## Parameters`). Muse's own Cargo edit changes it. A consumer never adopts an unregistered value (RUNBOOK §4). The nested-feature reading is ruled out under `## Parameters`.

**Disagreement 2 — where the F307 pass runs. Settled for the Opus leg on an executed result.**
- **Muse, OpenAI, Gemini:** a `utoipa::Modify` (`raw/muse.md:23`; `raw/doxa-openai.normalized.md:75`, `:171`; `raw/doxa-gemini.normalized.md:46`).
- **Opus:** a function over the document `split_for_parts()` returns (`raw/opus.md:136`–`:141`).

**Evidence.** Under `utoipa-axum` registration, a root `Modify` runs before the routed paths exist: it saw 0 paths against 2 merged (`P2`). OpenAI's example does work, but only because it lists `paths(get_widget)` in the derive (`raw/doxa-openai.normalized.md:122`, `:128`). The probe reproduces that: 2 paths seen when listed. That shape declares routes twice and gives up A8. `rust-lang/crates.io`, on the same pins, uses `Modify` only for components and runs its path pass after the merge (`W`).

**Disposition of the OpenAI leg's `BASELINE-REVIEW: F307`.** Its principle — runtime/schema agreement is the principle, not py's JSON-wrapper mechanism — is **accepted**. Its mechanism, `Modify`, is **rejected** for this router.

The premise that axum emits a default validation schema to rewrite is also wrong. Gemini's "rewriting default 422 validation schemas" (`raw/doxa-gemini.normalized.md:46`) and OpenAI's "replaces or adds framework validation responses" (`raw/doxa-openai.normalized.md:77`) both assume it. The raw document has none (`P2`).

**Disagreement 3 — the committed contract's path. Settled for the Opus leg on an executed detector run.**
- **Muse, OpenAI, Gemini:** py's `docs/api/openapi.json`.
- **Opus:** a root `openapi/` directory (`raw/opus.md:149`–`:156`).

**Evidence.** `D1` and `D5`: a snapshot-only change under `docs/` skips both the staleness test and R11's `web` slot. `D7`: the root path fails closed. File name: Opus's `openapi/rs-launch-blueprint.json` becomes **`openapi/openapi.json`**. The consumers' path then does not change when a template user renames the package. `D2` shows any path under `openapi/` behaves the same.

**Disagreement 4 — what regenerates the contract. Settled: the staleness test itself, with Muse's example target as ranked runner-up.**

| Leg | Proposal | Disposition |
|---|---|---|
| OpenAI | dedicated `export-openapi` `[[bin]]` (`raw/doxa-openai.normalized.md:163`–`:169`) | **Excluded by R49's registered value**: exactly one `[[bin]]`, `autobins = false` |
| Gemini | the same kind of dedicated `[[bin]]` (`raw/doxa-gemini.normalized.md:47`) | **Excluded by R49's registered value**, for the same reason |
| Muse | example target (`raw/muse.md:105`) | Compatible with R49 and executed (`P10`). The Opus leg's R49 argument (`raw/opus.md:142`–`:148`) does not reach it. Ranked **second**: it is a second code path and a second target for one job |
| Opus | `EXPECTORATE=overwrite` on the test | **Selected** (`P2`, `P3`) |

**Disagreement 5 — how the test compares. Settled for `expectorate` on the executed failure output.**
- **Muse:** a hand-rolled compare (`raw/muse.md:109`).
- **OpenAI:** direct string equality (`raw/doxa-openai.normalized.md:149`–`:160`).
- **Gemini:** `pretty_assertions::assert_eq!` (`raw/doxa-gemini.normalized.md:47`).
- **Opus:** `expectorate` (`raw/opus.md:663`–`:737`).

**Evidence.**
- **Failure output.** The same one-parameter rename produced a four-line unified diff from `expectorate`. It produced a 6,918-byte escaped panic from `assert_eq!` (`P5`). That difference decides it for a contract reviewed by humans. `pretty_assertions` was not probed; it would add a dependency to reach what `expectorate` already gives, plus overwrite.
- **Why not insta.** `insta`, R33's snapshot crate as reported by the Opus leg (`R33` was not re-read by this synthesizer), writes `.snap` files with a YAML header, which R83, R84 and oasdiff cannot read as OpenAPI. `rust-lang/crates.io` uses `assert_json_snapshot!` for its served document (`src/tests/openapi.rs:10`). That fits a project whose document is only a test artefact, not one whose file is a consumer contract.
- **insta binary snapshots.** The Opus leg's probe of `assert_binary_snapshot!` and its "(Experimental)" doc comment (`raw/opus.md:675`–`:681`) were not re-run here.
- **Runner-up order:** `snapbox` 1.2.2 (plain file, passes gate 2, not probed), then a hand-rolled compare.
- **The dependency's own risk.** `expectorate` is small (32 stars, 33 dependents). Its failure mode is local, not CI: a contributor who exports `EXPECTORATE=overwrite` globally accepts drift locally. CI never sets it, so CI still fails closed (`raw/opus.md:745`–`:748`).

**Disagreement 6 — `info.version`. Settled for the OpenAI leg's proposal.**
- **Muse and Opus:** normalize at test time as py does (`raw/muse.md:105`; `raw/opus.md:683`–`:685`).
- **OpenAI:** raises `BASELINE-REVIEW: F332` to set a constant in the builder so the served and committed documents are byte-identical (`raw/doxa-openai.normalized.md:173`).
- **Gemini:** silent.

**Evidence.**
- OpenAPI 3.1.1 separates the document's version from "the version of the API being described" (`versions/3.1.1.md:352`).
- `rust-lang/crates.io` sets `version = "0.0.0"` in its derive (`src/openapi.rs:53`).
- The probe meets A7 with the constant (`P8`).

**Disposition.** Adopted as F332's mechanism. Because F332 is `DIVERGENT` and appointed to R71, this is decided here rather than raised against a baseline. The cost is that the served document no longer reports the crate version; R22's runtime version accessor and `--version` do.

**Disagreement 7 — the breaking-change tool's form, version and threshold. Settled for the release binary v1.32.1 at `--fail-on ERR`, with an explicit severity override.**

| Leg | Form | Version | Threshold |
|---|---|---|---|
| Muse | action `oasdiff-action/breaking@v0.1.17` (`raw/muse.md:171`) | v0.1.17 (bundles oasdiff v1.32.1) | not stated |
| Gemini | action `oasdiff-action/breaking@v0` (`raw/doxa-gemini.normalized.md:48`) | floating `v0` | not stated |
| OpenAI | CLI | **1.23.0** | **`--fail-on WARN`** (`raw/doxa-openai.normalized.md:207`) |
| Opus | binary pinned by version and sha256 (`raw/opus.md:851`) | v1.32.1 | ERR |

**Evidence for each part.**

- **Version.** v1.32.1 is the newest non-prerelease release, published 2026-09-15 (`H`). OpenAI's 1.23.0 came from a leg whose API access was blocked (`raw/doxa-openai.normalized.md:3`).
- **Form: why the action loses.**
  - Its Dockerfile is `FROM tufin/oasdiff:v1.32.1` followed by `RUN apk add --no-cache curl jq` (`breaking/Dockerfile:1`–`:2`, `Q`). A commit-SHA pin of the action (`v0.1.17` is commit `5e81b5c3…33620b`) therefore still pulls a mutable image tag and unpinned Alpine packages.
  - Its `review` input defaults to `'true'`, uploading the comparison to oasdiff.com (`action.yml:59`–`:62`).
  - Its entrypoint posts a telemetry event to `https://www.oasdiff.com/api/telemetry` (`entrypoint.sh:49`).
  - It is a Docker action, so it runs only on Linux runners. py works around this by writing the base file inside the workspace (`api-contract.yml:28`–`:29`).
  - The binary has none of these properties, and contributors on macOS run the same command locally.
- **Ranked runner-up.** The action at commit `5e81b5c3…` with `review: false`, `github-token: ''`, `fail-on: ERR` and `err-ignore`.
- **Threshold.** py's `fail-on: ERR` (`api-contract.yml:48`) is kept. WARN-level findings are "potentially breaking" and are shown for review, not gated.
- **Severity override.** OpenAI raised the right question: does oasdiff catch an operation-id change (`raw/doxa-openai.normalized.md:184`)? Answered from source: no, not at ERR or WARN (`rules.go:616`, `INFO`). Hence `oasdiff-levels.txt`. The planned cases `O4` and `O6` would confirm it. OpenAI's fallback, a project-owned id comparator, is not needed if `O4` exits 1.

**Disagreement 8 — how operation ids are formed.**

**Explicit attribute versus Gemini's auto-generation. Settled for the explicit attribute.**
- **Muse, Opus, OpenAI:** an explicit attribute.
- **Gemini:** a `Modify` pass that auto-generates `{method}_{path}` ids for routes without one (`raw/doxa-gemini.normalized.md:130`).
- **Evidence.** A path-derived id changes whenever the path changes, so it is not curated. The same `Modify`-timing defect as Disagreement 2 applies. utoipa's default when an id is missing is the bare function name (`P2`), and the conformance test rejects it (`P6`).

**Spelling. Settled for py's `<tag>-<name>`.** OpenAI proposes `widgets_get` snake case; Muse is silent.
- The probe's ids equal py's committed ids byte for byte (`P4` versus py `docs/api/openapi.json:70`, `:147`). That keeps cross-implementation client parity available.
- OpenAPI 3.1.1 permits the hyphen and only RECOMMENDS programming-language conventions (`versions/3.1.1.md:978`).
- **The trade-off is carried to R84's re-verify:** its generator must map a hyphen to a valid method name.

**Disagreement 9 — `aide` against gate 2. Settled against the Opus and Gemini legs.**
- **Opus:** "None of the shortlist fails a numbered gate" (`raw/opus.md:323`).
- **Gemini:** lists no gate exclusion.
- **Muse:** calls the MSRV "unverifiable".
- **OpenAI:** fails it (`raw/doxa-openai.normalized.md:37`).

**Evidence.** Every one of `aide`'s 53 published versions has `rust_version: null` (`B`). Under the reading R69 applied, "none declared" fails gate 2. `aide` therefore leaves the generator shortlist. **No generator runner-up passes the gates.** The re-verify line names the event that would restore one: a stable `aide` release declaring a `rust-version` within the floor.

**Disagreement 10 — gate 1. Settled by owner ruling Q7.B.**
- **Muse:** excludes `rusty-schema-diff` on its licence (`raw/muse.md:179`).
- **Gemini and OpenAI:** report "License: pass".
- **Disposition.** Gate 1 is inapplicable for every candidate. `rusty-schema-diff` is re-based on gate 2 (no `rust_version`) and maturity (6 downloads in 90 days).

**Disagreement 11 — facts one leg got wrong, corrected from primary sources.**

| Claim | Leg | Correct value, with source |
|---|---|---|
| py pins `oasdiff-action/breaking@v0.1.6` | prompt, and Muse (`raw/muse.md:171`) | **`@v0.1.15`** at `api-contract.yml:44`, at pin and at `main` as read at 2026-09-27T03:42:30Z (`P`); the Opus leg had it right (`raw/opus.md:101`) |
| utoipa CI "runs on ubuntu + macos runners" | Muse (`raw/muse.md:47`) | **`runs-on: ubuntu-latest`** only (`build.yaml:34`, `H`) |
| `utoipa-axum` "requires tokio macros/rt" | Muse (`raw/muse.md:47`) | **No `tokio` dependency** in `/utoipa-axum/0.3.0/dependencies` (`C`) |
| `apistos` newest is `1.0.0-pre-release.14` | Muse (`raw/muse.md:55`) | the newest by `created_at` is **0.9.0**, 2026-09-18, `rust_version` 1.88.0 (`A`). The exclusion on fit is unchanged |
| `utoipa` stars "~2,500+", open issues "~120", responsiveness "~3 days" | Gemini (`raw/doxa-gemini.normalized.md:106`–`:108`) | **4,106** stars, **164** open issues, median **0.25** days (`E`, `F`) |
| `oasdiff` licence "MIT" | Gemini (`raw/doxa-gemini.normalized.md:291`) | **Apache-2.0** (the oasdiff `v1.32.1` licence file, line 1, `R`; `E`) |
| `expectorate` responsiveness "1 answered (61.2 days), 3 unanswered" | Opus | **2 answered** (4.64 and 61.17 days), 2 unanswered (`F`) |
| All crate figures `DATA-GAP` | OpenAI (`raw/doxa-openai.normalized.md:3`) | filled from the named endpoints (`A`–`G`) |

**Disagreement 12 — ownership claims. Settled: this item owns nothing.** Two legs claimed ownership:
- **OpenAI:** `owns generator-choice`, `snapshot-path`, `compatibility-engine` and others (`raw/doxa-openai.normalized.md:311`).
- **Gemini:** `owns openapi-generator` and three more (`raw/doxa-gemini.normalized.md:87`, `:304`).

The prompt's `- owns:` line is empty and none of these is a registered parameter. The snapshot path is published here as a contract R83 and R84 inherit through `acceptance_after`, not as a registry value. The controller may decide whether it deserves a row.

**Leads not taken up.** Gemini's CodeRifts, TypeMorph and PactFlow, and OpenAI's `axum-autoroute`, are either commercial or unverified at a named endpoint. Opus's `jsoncompat` is the one Rust differ with modest traction (17,585 90-day downloads, 17 stars). It fails gate 2.

**What P03 must validate** — each a proposal this research could not execute:
- the oasdiff cases with `--allow-external-refs=false` (cases `O1`–`O4` executed by `r71-oasdiff.sh`; `O5` and `O6` are manual follow-on steps whose expectations the log records), and the exact `--err-ignore` line syntax;
- that a committed `.oasdiff.*` file cannot override the four flags the invocation passes (gate 5 for `oasdiff`);
- the probe's test file on `ubuntu-latest` in R11's `check` matrix;
- the release-binary install and its sha256 verification in `hygiene`;
- a snapshot-only pull request running `check`, per `D7`, on a real runner;
- R70's runtime making the documented `400` true;
- R84's generator accepting hyphenated ids.

**Confidence.**
- **High:** adopting the pipeline, and the `utoipa` + `utoipa-axum` pair. Both are executed on stable and on the floor, and Rust's own registry runs the same pins.
- **High:** the post-merge pass, the root `openapi/` path and the test-as-regenerator. Each rests on an executed result.
- **Medium:** the `utoipa` 6.0.0 pin, released four days before retrieval. Mitigated by the exact pin and a snapshot test that surfaces any generator change as a diff.
- **Medium:** `expectorate` as a dependency (low traffic).
- **Medium-low:** the oasdiff invocation. The tool is well established, but the invocation and the severity override are not executed.
- **Medium:** the F307 status set, until R70 is accepted.

**Gaps recorded.**
1. oasdiff not executed (no named-endpoint install route).
2. `cargo audit` not run (advisory-database host not named); RustSec pages read instead.
3. No Linux run of the probe; utoipa's upstream CI is ubuntu-only, so macOS rests on this probe and Linux on upstream CI.
4. No published Rust template names the pipeline as a pattern; the VelesDB lead is unverified.
5. The Rust survey and project publications say nothing on OpenAPI tooling.
6. Binary-size delta not measured.
7. `insta` binary snapshots not re-probed here.
8. The dependency-tree MSRV is established by the successful 1.96 build of the probe graph, not by a per-crate `rust_version` audit of all 92 packages.
9. R33's `insta` selection was taken from the Opus leg, not re-read.
10. `oasdiff`'s use of Go's `unsafe` package, and its Go module dependencies, were not scanned: the source-archive host is not a named endpoint. Gate 3 for `oasdiff` rests on its published advisories and its `CGO_ENABLED=0` build.
11. `oasdiff`'s precedence between a passed flag and a working-directory `.oasdiff.*` file is not executed or read at the library's source; it is inferred from the `viper` binding order.
