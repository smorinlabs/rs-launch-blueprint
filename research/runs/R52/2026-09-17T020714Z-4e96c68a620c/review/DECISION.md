# 2026-09-17 — R52 — toml-crate (bundle, Focused) — decision (revision 1)

Actor `synth-opus-2026-09-17T020714Z-4e96c68a620c-r1`, model `claude-opus-5`, item kind
`bundle`, effort tier `focused` (two engines, no Doxa). This is the first revision; nothing
has been published for R52, so there is no `## Supersedes`.

Retrieval dates: **2026-09-17 (UTC)** for everything this decision checked itself through
`review/evidence/verify.sh`, and each raw report's own date for anything carried from a raw —
**2026-09-16** for `raw/codex.md` (Codex, `gpt-5.6-terra`, sha256 `8918f7a9…`) and
**2026-09-17** for `raw/opus.md` (Claude Opus 5, sha256 `88e0d54e…`).

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every
candidate below. Nothing is excluded on licence; licence strings are reported as metadata
only. The ruling is recorded in `docs/port/OWNER-REVIEW.md` under
"2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by
Q7.B)" (evidence log check `S09`), and `docs/planning/p02/owner-decisions.md` section 5, "The
licence gate's reach", now carries `ANSWERED 2026-09-12 (Q7.B)` and points at it (`S10`).
Neither raw excluded any candidate on licence, so no candidate needed re-evaluating on the
other gates for that reason.

## Decision

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; **P03 builds the
template and its CI proves the recommendation.** No Rust source exists in this repository —
`rs-launch-blueprint` is still a research tree — so nothing here is an implemented result. The
list of what P03 must validate closes `## Engines`. A decision that does not survive
implementation is revised against this recorded research, not researched again from scratch.

### The recommended stack

Two crates from one upstream workspace, split by **operation**, not by direction:

| Role | Crate | Version | Features | Where it runs |
|---|---|---|---|---|
| Typed read of `<tool>_config.toml` into the config struct R53 will define | `toml` | `1.1.6` (resolves `1.1.6+spec-1.1.0`) | **default only** — `std`, `serde`, `parse`, `display`; **not** `preserve_order` | the read path, every process start |
| Read-modify-write for `config set`, preserving the user's comments, key order and spacing | `toml_edit` | `0.25.15` (resolves `0.25.15+spec-1.1.0`) | **default only** — `parse`, `display`; **not** `serde` | the `config set` write path only |

Neither crate performs file I/O. Both take and return `&str`/`String`, so **F243's
"mode 0600 from creation, then atomic replace" guarantee is hand-rolled `std::fs` work
whatever crate is chosen** — see the `BASELINE-REVIEW: F243` disposition in `## Engines`.

**Feature selection, stated because both raws and the ecosystem differ here.** `toml`'s
published manifest makes `preserve_order` a non-default feature that pulls `dep:indexmap`
into `toml` (evidence checks `S63e`, `S63f`). Cargo and starship both enable it because they
re-serialize whole manifests through `toml::Value`; this template's write path goes through
`toml_edit`, which preserves order natively, so enabling it would add `indexmap` to `toml`'s
own closure for no gain. `toml_edit`'s `serde` feature is likewise non-default (`S73c`) and is
not enabled here because `toml` owns the typed read; Cargo enables it because Cargo
deserializes through `toml_edit` as well.

**Ledger rows this settles.** F225 and F226 (`docs/port/COMMONALITY.md`, both `DIVERGENT` —
`S12`, `S14`, `S15`): the parse library and the serialize library. F224 (TOML is the format),
F227 (the `<tool>_config.toml` filename) and F243 (atomic write at mode 0600) are
`COMMON → REUSE`, inherited, and untouched by this item (`S13`, `S16`).

**What this decision does not decide.** The typed schema and its validation (R53, F228); where
the file is discovered (R54) and the XDG set it sits in (R57); how a parse failure becomes a
user-visible message (R55, and R67 for the code and exit status); whether P03 reaches for
`tempfile` to write the temp file (F243/R54's call — R66's published stack already names
`tempfile 3.27.0` for atomic replacement, so a consistent crate is available, but this item
takes no position).

**Re-verification triggers**, each mechanical enough to be checked without judgment:

1. `toml_edit` publishes a `1.0` release — adopt promptly; it removes this stack's only
   structural weakness, and the trigger is a version string, not an opinion.
2. `toml` publishes a `2.0` release.
3. Either crate's published `rust_version` rises above the then-current stable-minus-2 floor
   (`GET https://crates.io/api/v1/crates/<name>/versions` against
   `https://raw.githubusercontent.com/rust-lang/rust/stable/src/version`).
4. A RustSec or OSV advisory is filed against `toml`, `toml_edit`, `toml_parser`,
   `toml_writer`, `toml_datetime`, `serde_spanned`, `winnow`, `indexmap`, `hashbrown` or
   `equivalent`.
5. `gh api repos/toml-rs/toml` reports `archived: true`, or `rust-lang/cargo`'s manifest stops
   declaring either crate.
6. R53 concludes it needs per-field byte spans beyond `serde_spanned` and
   `toml::de::Error::span()` — that reopens `toml-span`.
7. The owner decides comment preservation is not worth the second crate — that collapses the
   stack to `toml` alone (Codex's recommendation, recorded as the fallback in `## Engines`).

Otherwise at the scheduled date below, which is R34's next dependency-freshness sweep window.

re-verify: 2026-12-17, or earlier on any of — toml_edit publishing 1.0; toml publishing 2.0; either crate's published rust_version rising above the then-current stable-minus-2 floor; a RustSec or OSV advisory against toml, toml_edit, toml_parser, toml_writer, toml_datetime, serde_spanned, winnow, indexmap, hashbrown or equivalent; gh api repos/toml-rs/toml reporting archived true or rust-lang/cargo's manifest dropping either crate; R53 needing per-field byte spans beyond serde_spanned and toml::de::Error::span(); or the owner deciding comment preservation is not worth the second crate, collapsing the stack to toml alone.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**
Both source repositories implement the same principle: *the tool's persistent configuration is
a human-authored, human-editable text document that the tool reads into a validated typed
value and writes back after a programmatic change, without the user losing what they wrote.*
Agreement is required at the level of **capability and observable behaviour**, not library.
py and ts already disagree on library count while agreeing on behaviour — py splits
`tomllib` (read) from `tomli_w` (write) at `src/py_launch_blueprint/core/config.py:40` and
`:45`, ts uses one library for both at `src/lib/config.ts:20`
(`import { parse, stringify } from 'smol-toml'`) — which is exactly why F225 and F226 are
`DIVERGENT` and why this item exists. Both raws read these through the programme pins
(`b08bccfb` for py, `cb1cbcb2` for ts) and agree on what they say; this synthesis did not
re-read the pinned source repositories, and says so under `## Engines`.

The **org CLI Design Standard v1.4.14** (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`,
blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, verified at that blob by check `S22`) binds
this port by the owner's ruling of 2026-09-14, and two of its rules bear here:

- **R5.2** — "The canonical config format **MUST** be **TOML**" (`S24`). This is the
  standard's ground for F224, which is inherited, not re-litigated. The standard fixes the
  *format* and never a TOML crate. That is a deliberate silence, not an oversight: its
  Appendix E does name Rust crates for other roles — `clap`, `figment`/`config`,
  `directories`/`etcetera` (`S28`) — while no TOML crate appears anywhere in the document
  (`S29`). The crate choice below is therefore this template's to make and is not org-locked.
- **R5.8** — a tool with project/user config "**SHOULD** validate config files with precise
  file/key diagnostics" (`S25`), "back up files before rewriting them" (`S26`, which is the
  schema-migration clause, not a comment-preservation clause), and "Tools that write shared
  config/state/cache **SHOULD** use atomic writes" (`S27`). The diagnostics clause is the
  standard-level requirement that a candidate's parse error must carry a position; the atomic
  clause restates F243's half and belongs to the file adapter, not to a TOML crate.

**Essential behaviours, extracted from the sources and the standard.**

| # | Behaviour | Where it comes from |
|---|---|---|
| P1 | A config document parses into a typed value a schema layer can validate. | py hands the parsed mapping to its settings layer; ts hands `parse(raw)` to a zod schema. R53 owns the Rust schema. |
| P2 | A parse failure is distinguishable from a missing file and from an I/O failure, and carries enough detail to name the offending input. | py raises a distinct error for `tomllib.TOMLDecodeError` but returns an empty mapping for a missing file; ts separates the read failure from the parse failure. CLI standard R5.8's "precise file/key diagnostics". R67's `RSLB202` versus `RSLB104`. |
| P3 | A programmatic write never destroys the user's existing file. | py refuses to modify an unparsable file and writes a sibling temp file then replaces it, so an interrupted write cannot truncate. |
| P4 | The written file is owner-only from creation and the replacement is atomic. | F243, `COMMON → REUSE`, inherited; py creates the temp file at 0600 before the first byte. |

**Observable acceptance criteria** — behaviour a P03 test can assert, stated
library-agnostically so a later revision can re-test them against a different crate:

| AC | Assertion |
|---|---|
| AC1 | A valid `<tool>_config.toml` deserializes into the typed config struct; unknown-key behaviour is R53's to specify. |
| AC2 | A malformed document yields an error distinct from "file absent" and from "I/O failed", carrying a line/column position and a byte span over the offending token. |
| AC3 | After `config set output.format json` on a file carrying a header comment, a per-key comment and a trailing comment, all three survive in their original positions and only the target value changes. |
| AC4 | After that write, the file re-reads into the typed struct with the new value. |
| AC5 | The file is mode `0600` from creation and the replacement is atomic; an interrupted write leaves the previous file intact. **(F243's, inherited; not this item's to prove.)** |
| AC6 | An existing file that cannot be parsed makes `config set` refuse rather than overwrite. |

**Architectural alternatives, compared before libraries.** The real decision is the design;
the crate names follow from it. AC3 is the discriminator.

| Design | Shape | AC3 | Assessment |
|---|---|---|---|
| **A1 — one serde crate, full re-serialize** | `toml::from_str` to read, `toml::to_string_pretty` to write. ts's `smol-toml` shape and py's `tomli_w` shape transplanted. | **No** | Simplest, one dependency — and it reproduces a defect both sources ship. Executed here: a document whose first line is `# header comment` comes back without it, and without its trailing comment (`P2_PLAIN_KEEPS_HEADER = false`, `P2_PLAIN_KEEPS_TRAILING = false`, checks `S81`/`S82`). |
| **A2 — one format-preserving crate for both directions** | `toml_edit` alone with its `serde` feature. | Yes | One dependency, both directions, comments kept. Cost: it moves the template's primary deserialization path onto a `0.x` crate, against the maintainer's own documented steer toward `toml` for serde. |
| **A3 — two crates split by direction** | One crate parses, another writes — py's literal shape. | No | Buys nothing in Rust: any crate that can write TOML can also parse it, so the second crate adds surface without adding capability. Rejected on the merits, not on availability. |
| **A4 — two crates split by operation: typed read vs surgical edit** | `toml` for `from_str` into the typed schema; `toml_edit::DocumentMut` for read-modify-write. | Yes | **Recommended.** py's two-crate *count* on a better-motivated axis. One workspace, one release train, one MSRV. |

**Why A4 and not A1.** Three things decide it, in order of weight.

1. **The research mandate forbids the argument A1 rests on.** Codex's ground for A1 is that
   the pinned Python writer also rewrites presentation, so semantic preservation suffices. The
   prompt's own mandate (owner clarification 2026-09-04, spec §2/A5) says source
   implementations "are evidence, not predetermined winners", and the prompt names round-trip
   fidelity as a HIGH question rather than a settled non-requirement. "py loses comments too"
   is therefore a description of the baseline, not a justification for reproducing it.
2. **A1's defect is real and was measured, not inferred.** `S81`/`S82` above.
3. **A4 is the shape the maintainers document and three well-regarded consumers ship.** Read at
   pinned commits, `rust-lang/cargo` declares `toml = { version = "1.1.5", … }` and
   `toml_edit = { version = "0.25.10", features = ["serde"] }`; `astral-sh/uv` declares both;
   `starship/starship` — whose entire configuration surface is a user-edited TOML file, the
   closest analogue to this template's `config set` — declares `toml = { version = "1.1.6", … }`
   and `toml_edit = "0.25.15"` (checks `S110`–`S115`, each read at a pinned SHA rather than a
   moving branch).

**Why A4 and not A2.** A2's single-crate economy is smaller than it looks and its stability
cost is larger. Adding `toml_edit` on top of `toml` adds exactly **four** crates to the normal
dependency graph — `toml_edit`, `indexmap` 2.14.2, `equivalent` 1.0.2, `hashbrown` 0.17.1 —
because `toml_parser`, `toml_writer`, `toml_datetime` and `winnow` are already shared
(`cargo tree -e normal`, executed; checks `S96`–`S98`). Dropping `toml` and keeping only
`toml_edit` would trade those four for `toml`'s own unshared crates — roughly a wash — while
moving the hot deserialization path onto a `0.x` crate. A4 keeps the `1.x` crate on the read
path and confines the `0.x` crate to the one operation only it can perform.

**How the design composes, end to end.** Read path: R54's discovery hands a path to a loader
that does `std::fs::read_to_string` → `toml::from_str::<ConfigFile>()` → R53's validation.
Write path: `config set` does `std::fs::read_to_string` → `src.parse::<toml_edit::DocumentMut>()`
— **this parse is the P3/AC6 refusal point: a failure here means "refuse to modify", never
"rewrite from scratch"** — → mutate the one key in place → `doc.to_string()` → hand that
`String` to F243's atomic-0600 writer.

**The edit recipe P03 must use, and the trap that only execution finds.** The obvious
assignment `doc["output"]["format"] = value("json")` replaces the whole `Item` *including its
decor*, so the trailing comment on that key's line is lost — measured here:
`P6_NAIVE_KEEPS_TRAILING = false` with `P6_NAIVE_APPLIED = true` (`S88`, `S89`). Mutating the
existing `Value` in place and restoring its decor keeps everything —
`P7_DECOR_KEEPS_HEADER/PERKEY/TRAILING = true` and `P7_DECOR_APPLIED = true`
(`S90`–`S93`):

```rust
if let toml_edit::Item::Value(v) = &mut doc["output"]["format"] {
    let decor = v.decor().clone();
    *v = toml_edit::Value::from("json");
    *v.decor_mut() = decor;
}
```

This is a finding, not a style note: a P03 reviewer simplifying the assignment would silently
reintroduce AC3's failure, which is why the golden-file regression test below is named as a
must-validate item rather than a nice-to-have.

**R67 consumption — the distinguishable-error requirement (P2, AC2).** R67's
`error-contract/v1` is consumed unchanged, never amended. The mapping the chosen crates must
support, with what this check observed:

| Condition | R67 row | Exit | Evidence |
|---|---|---|---|
| Config file unreadable (permission, I/O), before any TOML crate is involved | `RSLB104` config layer unreadable | 1 | `std::io::Error`; nothing from a TOML crate. R67 row present (`S19`). |
| Document will not parse — read path | `RSLB202` config document unparsable | 2 | `toml::de::Error::span()` returned `Some(17..17)`; `Display` first line `TOML parse error at line 2, column 9`; `Error::message()` = `string values must be quoted, expected literal string` (`S83`, `S84`). That is what R67's optional `hint` needs in order to name the offending input, and what CLI standard R5.8's "precise file/key diagnostics" asks for. |
| Document will not parse — write path, before mutation (P3/AC6) | `RSLB202` | 2 | `toml_edit::TomlError::span()` returned `Some(17..17)` with the same first line (`S85`, `S86`). |
| Parsed, but a value is out of range or the wrong type | `RSLB203` config value invalid | 2 | **R53's**, not this item's. This item stops at "it is syntactically TOML". R67 row present (`S20`). |

**Maturity, dependability and integration cost, with the numbers' endpoints.** Every figure
below carries its endpoint and the retrieval date 2026-09-17; download counts, star counts and
`pushed_at` move between runs and are recorded rather than asserted (they appear in the
evidence log behind a `VOLATILE` marker).

| | `toml` 1.1.6+spec-1.1.0 | `toml_edit` 0.25.15+spec-1.1.0 |
|---|---|---|
| 90-day / all-time downloads (`GET https://crates.io/api/v1/crates/<name>` → `crate.recent_downloads`, `crate.downloads`) | 217,379,722 / 912,211,500 | 198,995,334 / 820,233,998 |
| Newest unyanked release (`/versions`) | `1.1.6+spec-1.1.0`, 2026-09-10T20:28:39Z (`S30`) | `0.25.15+spec-1.1.0`, 2026-09-11T01:44:08Z (`S33`) |
| `rust_version` / `edition` / `license` (same endpoint) | 1.85 / 2024 / `MIT OR Apache-2.0` (`S31`, `S32`, and the manifest at `S60`–`S62`) | 1.85 / 2024 / `MIT OR Apache-2.0` (`S34`, `S35`, `S70`–`S72`) |
| Repository (`gh api repos/toml-rs/toml`) | 1,074 stars, `archived: false` (`S40`), `pushed_at` 2026-09-15T14:53:24Z | same repository, same figures |
| Open issues (`gh api "search/issues?q=repo:toml-rs/toml+is:issue+is:open"` → `total_count`, never `open_issues_count`, which reported 71 because it counts PRs) | 57 | 57 (shared tracker) |
| Issue responsiveness (10 most recently opened non-PR issues, each comment's `author_association`) | **7 of 10** carry at least one `OWNER`/`MEMBER`/`COLLABORATOR` comment; 3 unanswered; 15 such comments in total, all by `epage` as `MEMBER` (`S42`–`S44`) | same tracker, same figure |
| Advisories | none: `https://rustsec.org/packages/toml.html` HTTP 404 (`S52`) against a `time` control that returns HTTP 200 and lists `RUSTSEC-2020-0071` (`S50`, `S51`); OSV query returns `{}` (`S55`) | none: HTTP 404 (`S53`); OSV `{}` (`S56`) |
| Maintenance state by rubric | **active** — released 7 days before retrieval, repository pushed 2 days before | **active** — released 6 days before retrieval, same release train |

**Fitness gates, answered per candidate before popularity was weighed.**

| Gate | `toml` 1.1.6 | `toml_edit` 0.25.15 |
|---|---|---|
| 1 — licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | `inapplicable — owner ruling 2026-09-12 (Q7.B)` |
| 2 — MSRV, crate and whole tree | **Pass.** Declares `rust-version = "1.85"` in its published manifest (`S60`). Whole resolved graph, excluding the probe package: maximum `rust_version` = **1.85.0** (`S99`, `S99c`), against a floor of **1.96** derived from published stable **1.98.1** (`https://raw.githubusercontent.com/rust-lang/rust/stable/src/version`, `S100`). The clause's second half, "tested in CI", is met upstream by a dedicated `msrv` job (`S121`, `S122`). | **Pass**, same workspace, same declaration (`S70`), same graph maximum, same CI job. |
| 3 — advisories and `unsafe` | **Pass.** No RustSec page with a validated control, OSV `{}` (`S50`–`S52`, `S55`). `unsafe` posture: the published `src/lib.rs` carries `#![forbid(unsafe_code)]` (`S66`), a compiler-enforced guarantee. | **Pass, with a stated caveat.** No RustSec page, OSV `{}` (`S53`, `S56`). `unsafe` posture is an **observed absence, not a compiler-enforced one**: no file under the published `src/` contains the token `unsafe` (`S78`) and there is no `forbid` attribute (`S77`). Caveat: its non-optional `indexmap` and that crate's `hashbrown` do use `unsafe` internally — see `## Engines` for what was and was not counted here. |
| 4 — CI on `ubuntu-latest, macos-latest` | **Pass, exceeded.** The workspace CI declares `os: ["ubuntu-latest", "windows-latest", "macos-latest"]`, read at pinned commit `3b81b064` (`S120`). Windows supported, noted not required. | **Pass, exceeded** — one workspace, one workflow, same line. |
| 5 — default features and async coupling | **Pass.** Published `[features] default` is `std`, `serde`, `parse`, `display` (`S63a`–`S63d`); `preserve_order` is non-default and pulls `dep:indexmap` (`S63e`, `S63f`). **No async-runtime coupling**: no runtime, executor or futures crate appears anywhere in the resolved graph (`cargo tree -e normal`, executed). | **Pass.** Published `default` is `parse`, `display` (`S73a`, `S73b`); `serde` is non-default (`S73c`). `indexmap` is a **non-optional** dependency (`S74`, `S76`), so it enters the tree at any feature selection. No async-runtime coupling. |
| 6 — binary size and compile-time cost | **Stated qualitatively, and one figure is carried rather than re-measured.** Qualitatively: a parser plus a writer plus serde support — small, and dominated by the `serde_derive` proc-macro chain (`syn`, `quote`, `proc-macro2`) the template pays for regardless. The Opus raw measured +190,032 stripped bytes over a `println!`-only binary on an Apple M4 Pro at `rustc 1.98.0`; this decision did **not** re-measure it. See `## Engines`. | **Same treatment.** Qualitatively: a document model plus `indexmap`. The Opus raw measured +135,920 stripped bytes on top of `toml` (about +26%) with the build-time delta inside measurement noise; not re-measured here. The graph cost **was** re-measured: exactly four added crates (`S96`–`S98`). |

**Candidates excluded by gate.**

- **`basic-toml` 0.1.10 — fails gate 2.** The owner-fixed `msrv-policy` requires an MSRV
  "declared as rust-version in Cargo.toml"; `basic-toml` declares none. `rust_version` is
  `null` for its newest unyanked version (`S36`) and for **every** published version — the
  count of versions declaring one is `0` (`S38`). An undeclared floor cannot be shown to sit
  within stable-minus-2, and an unmaintained crate will never raise one "only in a minor
  release". This is the same reading of the same clause that R64 used to prefer `shlex` over
  `shell-words`, so the programme is consistent rather than newly strict. Independently, the
  maintenance rubric returns **archived**: `gh api repos/dtolnay/basic-toml` reports
  `archived: true` (`S41`) and `pushed_at` 2025-03-03, and the README carries the maintainer's
  own "(This project is no longer maintained.)" notice (carried from `raw/opus.md`; not
  re-read here). Gate 1 is `inapplicable`, so its `MIT OR Apache-2.0` string excludes nothing
  and rescues nothing.
- **`taplo` 0.14.0 — not excluded by a gate; excluded on fit.** It is a TOML *toolkit* —
  parser, analyzer, formatter, LSP — not a config-reading dependency: a much larger default
  dependency surface, a last release of 2025-05-22, and no documented single-key edit API
  comparable to `DocumentMut`. If the template wants a TOML *formatter*, that is R27/R29's
  question, not this one.
- **Hand-rolled line-oriented editing (no crate)** — rejected on correctness. It re-implements
  TOML lexing badly, cannot handle dotted keys, multi-line strings, inline tables or arrays of
  tables, and silently corrupts documents it does not understand: the opposite of P3.

**Up-and-comers, watch-list only.** `toml-span` 0.7.1 (Embark Studios; 4,822,732 90-day
downloads; `rust_version` 1.70) carries byte spans into a hand-written deserializer and so
trades away `serde` derive support — the one integration R53 most needs; it is the crate to
revisit if R53 later demands per-field spans. `boml` 2.0.0 (zero-dependency, `no_std`;
116,110 90-day downloads) competes only on an embedded footprint this hosted CLI does not
have, and offers no serde derive integration. `tomling` 0.3.0 recorded **30** 90-day downloads
against `toml`'s 217,379,722 — there is no adoption base to evaluate it against, which is a
judgment about evidence rather than a gate failure. All three figures from
`GET https://crates.io/api/v1/crates/<name>`, retrieved 2026-09-17.

**Performance, stated with its workload rather than inferred.** The workload is a single read
of a sub-kilobyte file, once per process start, plus an occasional single-key write. Parse
throughput is therefore **not** a selection criterion, no throughput benchmark is cited or
relied on, and no candidate is ranked on speed. Declaring throughput irrelevant is itself a
finding: it removes the only axis on which the `no_std` minimalists could have competed.

**Reference implementations.** `rust-lang/cargo` (Rust's own package manager; both crates,
maintained by a Cargo team that includes the `toml-rs` maintainer `epage`, whose membership is
recorded in `rust-lang/team` — check `S116`), `astral-sh/uv` (both crates), `starship/starship`
(both crates; a user-edited TOML config identical in role to this template's). All three read
at pinned commits (`S110`–`S115`).

## Parameters

R52 owns **no** registry parameter. The prompt's `## Couplings` block carries an empty
`- owns:` line and `- consumes: R67: error-taxonomy-exit-codes` (checks `S01`, `S02`), and
`research/CLAUDE.md` records `—` in R52's `owns` column (`S21`). There is therefore no
`- owns` line below, and check `S07` counts zero of them in this file.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**No `CONFLICT:` line.** Nothing in this recommendation requires a consumed parameter to
change, and neither raw raised one.

How the parameters bear on the decision. **`msrv-policy`** is the parameter that excluded a
candidate: not by its numeric window — every shortlisted crate's floor sits far below the
current 1.96 — but by the clause "declared as rust-version in Cargo.toml", which `basic-toml`
does not satisfy at any published version. The floor itself is computed from published stable
`1.98.1`, and the whole resolved graph for the recommended pair tops out at `1.85.0`, eleven
minor versions of headroom. **`rust-edition`** is not exercised as a constraint — editions are
per-crate — but both members are themselves `edition = "2024"`, so nothing in the tree predates
the template's own ruleset. **`license`** is gate 1, which is `inapplicable` by the owner's
2026-09-12 ruling; recorded as metadata only, both members declare `MIT OR Apache-2.0`.
**`target-os-matrix`** is satisfied and exceeded: both members share one upstream CI workflow
that runs `ubuntu-latest`, `windows-latest` and `macos-latest` (`S120`), so both required
runners are covered upstream and a third is covered beyond the requirement. The only
Unix-specific element in the *composed* design is F243's `0600` permission bit, which belongs
to the file adapter rather than to either crate. This decision did not audit either crate's
source for `#[cfg(...)]` platform branches, so it makes no claim that none exists; what it
relies on is the upstream matrix and the fact that both members are pure-Rust `&str`-in,
`String`-out libraries that do no I/O.
**`error-taxonomy-exit-codes`** is consumed unchanged; the table under
`### Principles and implementation` names each row this item's crates must be able to feed, and
the spans and line/column positions both crates return are what let `RSLB202` carry a `hint`
that names the offending input.

Three values this decision fixes that no registry row owns, recorded here rather than in the
registry: the two version pins in the stack table, and the feature selection (`toml` defaults
without `preserve_order`; `toml_edit` defaults without `serde`). If a later item registers a
parameter covering dependency version pinning, these move there unchanged.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4 build 25E246,
`Darwin 25.4.0 arm64`. `curl 8.7.1`, `/usr/bin/grep` (BSD grep, GNU compatible, 2.6.0-FreeBSD
— named because a bare `grep` in an agent shell may be `ugrep`), `gh` authenticated
against GitHub. Current published stable channel at check time: **1.98.1**
(`https://raw.githubusercontent.com/rust-lang/rust/stable/src/version`, retrieved 2026-09-17),
which is what makes the policy floor 1.96.

**What this check does and does not do.** It verifies the raws' claims by querying the recorded
endpoints (crates.io, the GitHub API, RustSec, OSV), reading both candidate crates' **published
`.crate` artifacts** rather than a moving default branch, reading three adopter manifests and
the upstream CI workflow at **pinned commit SHAs**, reading this repository's own prompt,
registry, ledger and owner-review files, and **running the two candidate crates on three
literal strings** to observe the four behaviours that decide between the architectural
designs. It **implements nothing**: no template file, no config adapter, no file I/O, no error
mapping, no schema, no CI wiring. The only Rust it compiles is a throwaway probe in a
temporary directory holding a two-field struct and a `main` that prints booleans; the probe is
deleted when the script exits and nothing was written into the repository outside
`review/`.

**Working directory.** The repository root,
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. The script derives every repository path
from its own location and creates its scratch directory under `$TMPDIR`.

**Command.** One script, `review/evidence/verify.sh`, run as

    bash research/runs/R52/2026-09-17T020714Z-4e96c68a620c/review/evidence/verify.sh \
      > research/runs/R52/2026-09-17T020714Z-4e96c68a620c/review/evidence/r52-toml-crate.log 2>&1

**Exit status 0**, which for this script means **zero failed assertions**: it counts its
failures and exits with that count, so a non-zero status names how many claims did not hold.

**Why it is capable of failing.** It opens with `set -uo pipefail`, so a failing command inside
a pipeline cannot be masked by a succeeding `grep` or `head` after it. Every load-bearing claim
goes through one of five helpers that compare the **content** expected — `assert_has` (a
literal substring must be present), `assert_hasre` (a pattern must match), `assert_absent` (a
pattern must **not** match), `assert_eq` (two values compared, both printed when they differ)
and `assert_ge` (an integer floor). There are **106** such assertions, each printed inline with
its identifier (`S01`…`S122`), and this run reported **106 run, 0 failed, 0 skipped**. That the
script can fail is not asserted but observed and retained: `review/evidence/r52-first-run.log`
is an **earlier** draft's output, in which 19 assertions failed and the run exited `19` —
because that draft computed the repository root one directory too shallow, looked for `uv` on
`PATH` only, expected the published manifests' `[features] default` arrays on one line, and
compared the graph MSRV against `1.85` where `hashbrown` declares `1.85.0`. All 19 were defects
in the *check*, never in a finding; all 19 were fixed by changing the check; and that log
carries a header saying it is an earlier draft's output rather than being passed off as this
one's.

**Counts in this decision are never truncated listings.** Every count the script reports comes
from `/usr/bin/grep -c` or `jq … | length` over a whole file, invoked by absolute path and
named beside the number, never from output piped through `head`.

**Volatile figures, and the rule for comparing across a rerun.** Download counts, star counts,
`pushed_at`, open-issue totals and the maintainer-response tallies move between runs. The
script prints each with its endpoint and retrieval date behind a `VOLATILE` marker and **does
not assert an exact value** for any of them; what it asserts about them are their stable
properties (`archived` is `false`/`true`; at least one maintainer-association comment exists).
So the log is **not** byte-for-byte reproducible in general, and this decision does not claim
it is. The rule for comparing across a rerun: the `VOLATILE` lines, the `retrieval date` line,
and the two lines carrying the probe's `$TMPDIR` path (which embeds the shell's PID) may
differ; the `HTTP 404`/`HTTP 200` lines, version strings, `rust_version` values, manifest
contents, feature arrays, pinned-commit manifests, the probe's `P1`…`P8` outputs and every
`PASS` line must not. **This was checked, not assumed**: the exact committed script was re-run
immediately before this sentence was written and its output diffed against the log cited here.
The diff was **two lines**, both the `$TMPDIR` probe path — everything else, including the
download counts, was identical at that interval. Over a longer interval the `VOLATILE` figures
will move as well, which is what the marker is for.

**What the check covers, by section.**

    0   toolchain, host, retrieval date, and which capabilities are present
    1   this repository: the prompt's Couplings block; the five `- assumes` lines rebuilt
        from docs/port/PARAMETERS.md and diffed against this file; the zero `- owns` lines;
        the single `re-verify:` line; the 2026-09-12 licence ruling in OWNER-REVIEW.md and
        the ANSWERED marker in owner-decisions.md section 5; ledger rows F224/F225/F226/
        F227/F243; the R67 DECISION.md sha256 against inputs/prerequisites.json; the index slug
    2   the org CLI Design Standard at blob f9de0437: version line, R5.2, R5.8's three
        clauses, that Appendix E names Rust crates for other roles, and that no Rust TOML
        crate appears anywhere in the document
    3   crates.io for toml, toml_edit, basic-toml, taplo, toml-span, boml, tomling: downloads,
        newest unyanked version, created_at, rust_version, license, edition
    4   GitHub: archived state for both repositories; open issues by search/issues total_count
        against open_issues_count; and the issue-responsiveness re-query that settles the
        engine conflict, printing every comment's author_association
    5   RustSec pages for toml, toml_edit, basic-toml with a `time` control that returns 200
        and lists advisories; OSV cross-check for both members
    6   the published .crate artifacts: manifests, rust-version, edition, licence, the
        [features] default arrays, toml's absent toml_edit dependency, the forbid(unsafe_code)
        attribute, toml_edit's non-optional indexmap and its unsafe-free src
    7   the behavioural probe: typed read; comment loss on re-serialize; located parse errors
        from both crates; unmodified round-trip identity; the naive-assignment decor trap; the
        decor-preserving edit; the edited document re-read through toml; cargo tree; whole-graph
        MSRV; the published stable channel
    8   adopter manifests at pinned commits, and the rust-lang/team Cargo roster
    9   the upstream CI workflow at a pinned commit: the OS matrix and the MSRV job

**The observations that decide something**, quoted from the log:

    P1_TYPED_READ = Probe { output: Some(Out { color: Some("auto"), format: Some("text") }) }
    P2_PLAIN_KEEPS_HEADER = false          <- A1's defect, measured
    P2_PLAIN_KEEPS_TRAILING = false
    P3_TOML_DE_SPAN = Some(17..17)
    P3_TOML_DE_FIRSTLINE = TOML parse error at line 2, column 9
    P3_TOML_DE_MESSAGE = string values must be quoted, expected literal string
    P4_EDIT_SPAN = Some(17..17)
    P4_EDIT_FIRSTLINE = TOML parse error at line 2, column 9
    P5_UNMODIFIED_ROUNDTRIP_IDENTICAL = true
    P6_NAIVE_KEEPS_TRAILING = false        <- the decor trap
    P6_NAIVE_APPLIED = true
    P7_DECOR_KEEPS_TRAILING = true         <- the recipe that works
    P7_DECOR_APPLIED = true
    P8_REREAD = Probe { output: Some(Out { color: Some("auto"), format: Some("json") }) }

    issues with at least one OWNER/MEMBER/COLLABORATOR comment: 7 of 10
    issues with none:                                          3 of 10
    maximum rust_version across the resolved graph = 1.85.0

**Evidence files, with the digests that tie this prose to them.**

| File | sha256 | What it is |
|---|---|---|
| `review/evidence/verify.sh` | `1da3c38126a12e948adeafe3b4c036a61e29a95c507e965da67718823f4a4254` | the script, 681 lines, ShellCheck-clean with no file-level `disable` directive |
| `review/evidence/r52-toml-crate.log` | `7e13c66153c8992caef324b2ea44325521f5d240ff9af9c22477a44cdc690174` | its output, exit `0`, 106 assertions run, 0 failed, 0 skipped |
| `review/evidence/r52-first-run.log` | `7e51352a43f6d115470e25897db61cb29879d324cc8f7264ebe8065228ec5241` | an **earlier draft's** output, exit `19`, retained as proof the harness can fail; its own first line says so |

## Engines

- Codex `gpt-5.6-terra` — `raw/codex.md`, sha256
  `8918f7a9845eb66ac84cac97c85cb6436448577a42e28a655548ce398af1edd6`, 10 H3 sections,
  one member, recommendation `toml = "1.1.6"` alone.
- Claude Opus 5 — `raw/opus.md`, sha256
  `88e0d54e16e92b22de2b68bca584127d5c1edb4911cc35b90ad8d29b6f6ef54d`, 10 H3 sections,
  two members, recommendation `toml 1.1.6` + `toml_edit 0.25.15`, `basic-toml` excluded on
  gate 2.

**Disagreement 1 — one crate or two.** Codex recommended `toml` alone: its ground is that the
pinned Python writer also rewrites presentation, so "the source precedent needs semantic
preservation, not a user-authored-format preservation guarantee". Opus recommended the pair,
with the comment loss and the preserving edit both executed. **Settled for the pair**, on three
grounds, in order of weight: the prompt's research mandate says source implementations are
evidence, not winners, so "py loses comments too" describes the baseline instead of justifying
it; the prompt lists round-trip fidelity as a HIGH question rather than a settled
non-requirement; and A1's defect was reproduced here (`S81`, `S82`) while A4's remedy was
reproduced too (`S90`–`S93`). **Codex's position is recorded as the named fallback**: if the
owner decides comment preservation is not worth the second crate, the stack collapses to
`toml` alone and the template knowingly ships the sources' defect. That collapse is listed in
this decision's `re-verify:` triggers so the choice stays visible rather than being buried.

**Disagreement 2 — why `basic-toml` is out.** Codex excluded it on its archived repository and
noted separately that it declares no `rust-version`. Opus excluded it on **gate 2**, treating
`archived` as a corroborating maintenance verdict. **Settled Opus's way, and the distinction
matters**: a gate failure is a rule, an archived repository is a judgment. `rust_version` is
`null` for every published version of `basic-toml` (`S36`, `S38`), which fails the
`msrv-policy` clause "declared as rust-version in Cargo.toml" on the same reading R64 applied
to `shell-words`. The archived state is true as well (`S41`) and is recorded as the
maintenance rubric's verdict, not as the exclusion ground. Neither engine excluded it on
licence, so the 2026-09-12 ruling changes nothing here.

**Disagreement 3 — whether fitness gate 3 could be answered.** Codex recorded gate 3 as
**unverified** because `https://rustsec.org/packages/<name>.html` returned HTTP 404 for all
four of its candidates and it drew no conclusion from a 404. Opus recorded gate 3 as **pass**,
having first validated what a 404 means against known-vulnerable controls. **Settled Opus's
way, and the control is the reason.** This check reproduced both halves: `time` returns
HTTP 200 and its page lists `RUSTSEC-2020-0071` (`S50`, `S51`), while `toml`, `toml_edit` and
`basic-toml` return HTTP 404 (`S52`–`S54`); an independent OSV query returns `{}` for both
members (`S55`, `S56`). Codex's caution was methodologically right and its conclusion was
avoidable: a 404 with no control proves nothing, and a 404 with a control proves that no
advisory page exists.

**Disagreement 4 — maintainer responsiveness, a flat factual conflict.** Same repository, same
endpoint, same ten issues, opposite results. Codex: "no comment whose GitHub
`author_association` was `OWNER`, `MEMBER`, or `COLLABORATOR`… unanswered count is 10/10".
Opus: "median 0.67 days to first maintainer response; 3 of 10 unanswered". **Re-queried here,
and Codex is wrong.** Across the ten issues both raws named (#1214, #1213, #1210, #1206,
#1188, #1181, #1175, #1172, #1162, #1158), **7 carry at least one maintainer-association
comment and 3 do not** — matching Opus's unanswered count exactly — and `/usr/bin/grep -c`
counts **15** such comment lines, every one of them by `epage` with
`author_association: MEMBER` (`S42`, `S43`, `S44`; the raw associations are printed in full in
section 4 of the log). Nothing in the recommendation turned on this figure, but a false
"the maintainers never reply" would have been carried into a future re-verification, so it is
corrected here rather than averaged. **Opus's median of 0.67 days is not re-verified**: this
check counted responders, not elapsed time.

**Disagreement 5 — an owned parameter Codex invented.** Codex's `### Parameters` field
declares `owns toml-codec-stack = …`. No such parameter exists: the prompt's `- owns:` line is
empty (`S01`), `research/CLAUDE.md` records `—` for R52 (`S21`), and `docs/port/PARAMETERS.md`
has no such row. The packaging validator fails publication on any mismatch between a decision's
owned set and the prompt's, so this decision declares **zero** `- owns` lines (`S07`) and the
two version pins are recorded as unregistered values under `## Parameters` instead. Opus
declared `owns — none`, correctly.

**Disagreement 6 — feature selection.** Codex said "default features" for `toml` and stopped.
Opus went further and argued both non-defaults off by name. **Settled Opus's way, with the
manifests re-read**: `preserve_order` is not a default of `toml` and pulls `dep:indexmap`
(`S63e`, `S63f`), and `serde` is not a default of `toml_edit` (`S73c`). Cargo and starship
enable `preserve_order`, and Cargo enables `toml_edit`'s `serde`; the reason this template
does neither is recorded in `## Decision` so a later reader does not "fix" the divergence from
Cargo by adding features back.

**`BASELINE-REVIEW: F243`, carried from `raw/codex.md` with its disposition.** Codex's line
reads: *"BASELINE-REVIEW: F243 — preserve restrictive permission before exposure and atomic
replacement behavior through a standard-library file adapter; do not attribute either property
to the selected TOML crate"*. **Disposition: carried, and it is not a challenge to the recorded
row.** F243 stays `COMMON → REUSE` (`S16`); no ledger change is proposed and none is needed.
What the line actually asserts is a scope boundary, and Opus reached it independently: no TOML
crate in the surveyed Rust field performs file I/O — `toml`, `toml_edit`, `basic-toml`,
`toml-span` and `boml` all take and return `&str`/`String` — so F243's "0600 from creation,
then atomic replace" is hand-rolled `std::fs` **whatever crate is chosen**, and is therefore
an argument for or against no candidate. The Rust shape of py's `mkstemp` + `os.replace` is
`OpenOptions::new().write(true).create_new(true).mode(0o600)` (via
`std::os::unix::fs::OpenOptionsExt`, under `#[cfg(unix)]`) on a sibling temp path, then
`write_all`, `sync_all`, `std::fs::rename` — `rename` portable, only the permission bit
Unix-specific, which the fixed `ubuntu-latest, macos-latest` matrix permits. This decision
records that boundary and takes no position on whether P03 reaches for `tempfile` for the
temp-path half; that is F243/R54's call. **No `CONFLICT:` line was raised by either engine and
none is raised here.**

**A provenance caveat the Opus raw raised, and its resolution.** `raw/opus.md` reports that the
licence-ruling pointer in its task message — `docs/planning/p02/owner-decisions.md` section 7 —
did not resolve, that section 7 is "The baseline-review questions", and that the string `Q7.B`
appeared nowhere under `docs/` or `research/`. **Resolved in the repository's favour, with the
citation corrected.** The ruling does exist: `docs/port/OWNER-REVIEW.md` carries
"2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by
Q7.B)" (`S09`), and `owner-decisions.md` section **5**, "The licence gate's reach", is now
marked `ANSWERED 2026-09-12 (Q7.B)` and points at it (`S10`); section 7 is indeed the
baseline-review questions (`S11`). The engine followed the instruction correctly and flagged
the bad pointer rather than papering over it; the pointer, not the ruling, was wrong. This
decision cites `OWNER-REVIEW.md`. Nothing in the recommendation turned on it — both members
declare `MIT OR Apache-2.0` and would pass gate 1 under any reading.

**What this synthesis did not verify, stated as unproven rather than smoothed over.**

1. **Binary-size and compile-time deltas** (+190,032 bytes for `toml`; +135,920 bytes for
   `toml_edit` on top; the 342,000 → 532,032 → 667,952 byte series; the 4.09–5.60 s and
   4.37–6.13 s build ranges; the `basic-toml` 478,976-byte comparison). These are Opus's
   measurements on an Apple M4 Pro at `rustc 1.98.0`, single machine, two repetitions, and
   this check did **not** re-measure any of them. Gate 6 is answered qualitatively here and the
   figures are attributed. What would prove them: P03's own release build with `strip = true`
   on both CI runners, which is where a binary-size budget belongs anyway.
2. **`unsafe` counts inside `indexmap` and `hashbrown`** (Opus: 12 and 337 occurrences). Not
   re-counted; the raw obtained them by grepping vendored registry sources, and a typed `grep`
   in an agent shell is not necessarily `/usr/bin/grep`. What **is** verified here is the first
   party posture: `toml` carries `#![forbid(unsafe_code)]` (`S66`) and `toml_edit`'s published
   `src/` contains no `unsafe` token at all (`S78`). The honest statement is that the composed
   config path is not entirely `unsafe`-free once `indexmap`/`hashbrown` enter, and that R06's
   `unsafe` policy governs first-party code, which is unaffected.
3. **Opus's median first-response time of 0.67 days.** Responders were counted here; elapsed
   days were not.
4. **The pinned source repositories.** Both raws read py at `b08bccfb` and ts at `cb1cbcb2` and
   agree on every line they quote; this synthesis did not re-read either working tree or pin.
   The P1–P4 behaviours rest on that agreement.
5. **`taplo`'s repository figures** (stars, archived, `pushed_at`, open issues) were never
   retrieved by either engine; only its crates.io figures are cited, and it is not recommended.
6. **`basic-toml`'s maintainer notice** ("This project is no longer maintained.") is carried
   from `raw/opus.md`; this check verified the archived flag (`S41`) but did not re-read the
   README.
7. **Everything behavioural is a probe, not the template.** AC5 was not tested at all: it is
   F243's guarantee and belongs to a file adapter this item does not choose.

**What P03 must validate, and what evidence closes each row.**

| # | Claim | How P03 proves it |
|---|---|---|
| V1 | AC1/AC2 — the typed read, and a located parse error distinct from "absent" and "I/O failed". | A `#[test]` over a fixture `rslbp_config.toml` plus a deliberately malformed one, asserting the error's line, column and span. |
| V2 | AC3 — `config set` preserves a header comment, a per-key comment, a trailing comment and key order. | A **golden-file** test: run `config set` against a fixture carrying all three plus an unusual key order, byte-compare against an expected file differing in exactly one value. This is the regression gate that catches the decor trap if anyone simplifies the assignment. |
| V3 | AC4 — the edited file re-reads into the typed struct with the new value. | Assert inside the same golden-file test, through `toml::from_str`. |
| V4 | AC6 — an unparsable existing file makes `config set` refuse, with `RSLB202` and exit `2`. | A test asserting the error code and the exit status, plus an `insta` snapshot (R33) of the rendered envelope pinning R67's `code`, `message` and `hint` keys. |
| V5 | AC5 — mode `0600` from creation and an interrupted write leaving the previous file intact. | **F243's, not this item's**; listed so it is not lost. Unix-only assertion on the two fixed runners. |
| V6 | Gate 2 stays true as the tree moves. | `cargo test --locked` under the MSRV toolchain in the dedicated CI job, on `ubuntu-latest` and `macos-latest`. |
| V7 | Gate 6's numbers on this template rather than on a probe. | Record stripped release binary size and cold build time in CI, at the point a size budget is set. |
| V8 | The feature selection holds. | Assert in CI that `cargo tree -e normal` shows `indexmap` beneath `toml_edit` only, never beneath `toml` — i.e. that nobody enabled `preserve_order`. |
