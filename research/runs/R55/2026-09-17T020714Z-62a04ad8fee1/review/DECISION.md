# 2026-09-17 — R55 — config-error-tolerance (bundle, Focused) — decision (revision 1)

## Decision

**Recommendation — one stack.** Adopt `serde_path_to_error` 0.1.20 and
`serde_ignored` 0.1.14 in the library crate, composed with the `thiserror` 2.0.20
that R67 already fixes, as a **provenance-aware two-phase config loader**. The
policy itself needs no crate: R55 adds exactly those two small crates, and both
are pure data transformations with no I/O, no global state and no async coupling.
`serde_ignored` is recommended **contingent on R53**, which owns schema validation
and may decide unknown-key handling itself; nothing else here depends on it.

This decision is a **proposal validated in the implementation phase** (owner
ruling, 2026-09-10). It records what the research found and what it recommends.
P03 builds the template and its CI proves the recommendation; a recommendation
that does not survive implementation is revised against this recorded research,
not researched again from scratch. What P03 must validate is listed under
`## Engines`.

**Ledger rows settled:** `F235` (explicit `--config` pointing at a missing file),
`F236` (unparsable *discovered* layer), `F238` (invalid config *value*). `F237`
(unparsable *explicit* file, `COMMON → REUSE`) is **not** reopened; this decision
records one `BASELINE-REVIEW:` against it, in `### Principles and implementation`.

**The rule, in four clauses.** Every one of the four ledger rows follows from the
first three; the fourth is the composition order they force.

1. **Absence is not a fault.** An explicit config path (`--config`, or an
   env-supplied path) that does not exist — `std::io::ErrorKind::NotFound` — is an
   **empty layer plus a warning naming the path**, never an error. Under the org
   CLI Design Standard R5.2 an explicit `--config <path>` *replaces* the
   discovered project/user/system files and "becomes the sole config file in the
   chain", so the outcome is well-defined: the file layer contributes nothing, and
   flags, environment variables and built-in defaults still resolve normally
   (R5.1). No discovered file silently reappears. This settles **F235** to py's
   outcome.
2. **A document-level fault is judged by provenance.** "Document-level" means the
   layer could not be turned into a document at all: an `io::Error` whose kind is
   **not** `NotFound` (permissions, a directory where a file was named, a device
   error), or a TOML parse failure.
   - *Explicit* layer → **fatal**. Unreadable is `RSLB104` at exit `1`;
     unparsable is `RSLB202` at exit `2`. This **preserves F237**, which this item
     does not own and does not settle: F237's `Item` column is `—`, it is already
     `COMMON → REUSE`, and this clause is the Rust behavior that keeps it true.
   - *Discovered* layer → **one warning naming the file, the layer skipped, the
     exit code unchanged**. This settles **F236**, and applies only if R54 adopts
     a discovered (non-explicit) tier; if R54 adopts none, this clause has no
     target and F236 has no Rust instance.
3. **A value-level fault is judged by granularity, not provenance.** A leaf that
   the typed pass rejects — right TOML, wrong value — is **dropped from its own
   layer with a warning naming the file and the dotted key path**, in explicit and
   discovered layers alike. The load continues and the exit code is unchanged.
   The fatal branch is narrow and real: when the fault cannot be localized to a
   prunable leaf, the layer fails with `RSLB203` at exit `2`. Measured
   non-localizable cases are a root-level shape fault (`## Empirical check`, F1)
   and a leaf inside a `#[serde(flatten)]` target (H1). Cross-field invariant
   failures are not leaf-local either, and are R53's to define; they route to
   `RSLB203` when R53 makes them fatal. This settles **F238** to py's outcome and
   answers the prompt's HIGH question: serde's derived `Deserialize` is fail-fast
   and cannot itself drop a key, but it does not force an all-or-nothing outcome —
   `serde_path_to_error` makes the failing key **addressable**, and a bounded
   prune-and-retry loop over the untyped document drops exactly that key.
4. **Layers compose as sanitize untyped → merge in R54's order → one typed pass.**
   Each layer is sanitized as an *untyped* document (the prune loop already
   mutates one), the sanitized documents are merged in R54's precedence order, and
   exactly one typed pass runs over the merged document. Merging *typed* values is
   not available: with `#[serde(default)]` on every field, a `limit = 0` produced
   by `Default` is indistinguishable from a written `limit = 0`, so a lower
   layer's default would overwrite a higher layer's value with no way to tell
   which keys were present.

**Two rules the design imposes on code P03 writes.** The config struct carries
`#[serde(default)]` on every field, and **no fallible field may sit inside a
`#[serde(flatten)]` target** — measured, not documented: when the failing leaf is
inside the flattened target the tracked path collapses to `"."` and addresses
nothing prunable, so per-key drop silently degrades to a whole-layer failure
(`## Empirical check`, H1). A flattened field is safe when no leaf inside it can
fail; a leaf *outside* the flattened target keeps its prunable path (H2).

**Warnings are returned, never printed.** The loader's signature is
`Result<(Config, Vec<ConfigWarning>), ConfigError>` with
`ConfigWarning { source: ConfigSource, key: Option<String>, kind: ConfigWarningKind }`.
Two independent reasons, and the second is the stronger one: R67's Layering clause
forbids the library crate from writing to any process stream, and **config loading
precedes logger initialization** — R58 has not published, and a `tracing::warn!`
emitted before a subscriber exists is discarded. The binary renders the returned
warnings once, after the logger exists, to **stderr** (R7.1), naming the offending
input (R7.6).

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** Four principles, each with the pinned evidence that states it.

| # | Principle | Source | Agreement level |
|---|---|---|---|
| P1 | A configuration fault must never leave the user unable to repair it | py states it in code: `b08bccfb:src/py_launch_blueprint/core/settings.py:141-145` — "Invalid values are dropped with a warning rather than raised: config must never brick the CLI — the user needs `config set`/`config path` working in order to repair the file" | **policy** — all three repos must satisfy it; the mechanism may differ |
| P2 | A degraded load is never silent, and the warning names the file and the key | py returns warning strings for the unparsable-discovered and invalid-value cases (`core/config.py:102`, `core/settings.py:169`); the org CLI Design Standard R5.8 requires "precise file/key diagnostics" and names `❌ silently ignoring bad config` as the anti-pattern | **observable acceptance criterion** |
| P3 | The fate of a fault is decided by what the fault is, not by how the code happens to be organized | derived: the ledger's four rows split cleanly into *document-level* (provenance decides) and *value-level* (granularity decides); see the rule above | **architectural pattern** |
| P4 | The library crate decides, the binary prints | R67's Layering clause (the library writes to no process stream) plus R01's composition-root shape | **architectural pattern** — py and rs agree on shape and differ in type: py returns `list[str]`, rs returns a typed `Vec<ConfigWarning>` |

P2 is where py itself falls short and rs should not: py's `_read_explicit` returns
`{}` for a missing explicit path with **no warning at all**
(`b08bccfb:src/py_launch_blueprint/core/config.py:114-115`). This decision warns.

**What must agree, and what may vary.** Must agree: P1–P4, and the three-way
classification itself — missing, unparsable and invalid-value are *distinct* cases
with distinct answers. That is the thing ts collapsed and py did not. May vary:
the granularity of the drop (per key in py and rs, per file in ts today), the
warning carrier (`list[str]`, an injected callback, a typed `Vec<ConfigWarning>`),
and the mechanism. The ecosystem difference is real and justified: `pydantic`
(`ValidationError.errors()`) and `zod` (`safeParse(...).error.issues`) both return
a *collection* of per-field errors from one pass, while serde's derived
`Deserialize` returns the first error and no value. The same policy therefore
costs roughly sixty lines in Rust and roughly zero in Python. That is a mechanism
difference at a level where agreement is not required, not a capability gap.

**py's stated rationale for F235 does not carry into Rust; a narrower one does.**
py justifies tolerating a missing explicit path as "a valid target for `config
set`" (`core/config.py:109-112`). In Rust `config set` and `config path` operate
on the path and the document through a round-trip editor, not on the typed loader,
so they keep working whether or not the typed load tolerates absence — exactly as
they keep working when a value is invalid. The rationale that does carry is
narrower: an **env-supplied** explicit path is set once in a shell profile, a
container image or a CI job, and a hard failure there makes every invocation fail
until a file exists. `ripgrep` handles precisely that case and warns rather than
failing (`BurntSushi/ripgrep` `crates/core/flags/config.rs:32-40`, retrieved
2026-09-17). ts's contrary behavior additionally rests on a premise the ledger has
already flagged as false: its code comment claims `click.Path(exists=True)` parity
(`ts: src/lib/config.ts:153`), but the pinned py commit's `--config` option does
not set `exists=True` (`docs/port/DIVERGENCE-ANALYSIS.md:297`).

**Architectural alternatives for the value-level case, compared before any library
was chosen.**

| Alternative | Mechanism | Per-key drop | Names the key | Cost / why not |
|---|---|---|---|---|
| **A. All-or-nothing typed deserialize** (ts's shape) | `toml::from_str::<ConfigFile>(text)?` | no | only in the fatal message | zero cost, but loses P1 |
| **B. Prune-and-retry over the untyped document** (**selected**) | parse to the untyped document; typed pass through `serde_path_to_error::Deserializer`; on error remove the leaf the tracked path names; retry; bound the loop by leaf count | yes | yes, by dotted key path | ~60 lines and two crates that add zero transitive dependencies; N passes for N bad keys |
| **C. Per-field `deserialize_with` wrapper or a project derive** (`alacritty`'s shape) | every field deserializes through a wrapper that falls back to `Default` | yes | only if the wrapper can reach a collector | a macro to maintain, or an attribute on every field. `serde_with`'s `DefaultOnError` is the version with **no** reporting, so it fails P2 |
| **D. Hand-rolled per-key extraction** | no derived `Deserialize`; read each key out of the untyped tree explicitly | yes | yes | boilerplate proportional to the schema, and it drifts from whatever R53 selects |
| **E. `figment`** | providers plus `Metadata` provenance; `figment::Error` accumulates several failures | **no** — extraction is still all-or-nothing | yes, with file provenance | adopts a whole config framework, pre-empting R52, R53 and R54 |

**B is selected** because it is the only option that delivers per-key drop *with* a
machine-readable key name while leaving R52, R53 and R54 free, and because its
composition was executed rather than reasoned about (`## Empirical check`). E is
the ranked runner-up *architecture*, to be revisited only if R54 chooses a
provider-style layering model; its repository `SergioBenitez/Figment` shows
`pushed_at` `2024-09-13T04:51:49Z` (retrieved 2026-09-17), a two-year push gap that
is a maintenance **trigger**, not a verdict — it was not investigated to a verdict
because the design does not select it. D is what a `toml::Value::get` plus
per-leaf `try_into` design becomes in practice: it needs the schema's leaves
enumerated independently of the derive.

**Reference implementations — what well-regarded Rust projects actually do.**

| Project | Why it is a relevant reference | What it does with a config fault |
|---|---|---|
| `cargo` (`rust-lang/cargo`, 15,484 stars, `pushed_at` 2026-09-16T13:22:52Z) | the toolchain's own CLI and the highest-stakes TOML consumer in the ecosystem | two-phase load — untyped `toml::de::DeTable`, then a typed deserialize from it (`src/workspace/parser/mod.rs:186-203`); unknown keys become warnings through `serde_ignored` (`:198`, pinned `serde_ignored = "0.1.14"` at `Cargo.toml:103`); **warnings accumulate as data and are attached to the manifest** (`:148-152`), not logged at the point of degradation |
| `ripgrep` (`BurntSushi/ripgrep`, 68,336 stars, `pushed_at` 2026-08-04T13:59:44Z) | the reference Rust CLI | an explicit path that cannot be read, including missing → warn and continue (`crates/core/flags/config.rs:32-40`); bad *lines* inside a readable explicit config → report each, keep the good ones (`:41-45`) |
| `starship` (`starship/starship`, 59,920 stars, `pushed_at` 2026-09-17T03:32:48Z) | very large, very current adoption, and its tolerance posture is deliberate | every fault degrades: unparsable → `log::error!` and `None` (`src/config.rs:139-149`); missing or unreadable → log and `None` (`:151-165`, level chosen from `ErrorKind::NotFound`); **invalid value → per-unit drop with a warning and a default** (`:31-39`); unknown key → warn, then re-deserialize leniently (`:53-62`) |
| `axum` (`tokio-rs/axum`, 27,156 stars, `pushed_at` 2026-09-15T07:20:31Z) | the dominant Rust web framework; this template ships a web surface | uses `serde_path_to_error` in its `Json`/`Form` extractors so a deserialization failure can name the offending field (`axum/Cargo.toml:139`) |

Practice is unanimous on the discovered-layer and value-level cases — degrade with
a visible warning, keep what parsed — and split on the missing explicit path:
ripgrep tolerates, cargo errors. The split is explained rather than left open:
cargo's `--config` is not a pure path flag, so a non-existent path falls through
to its `KEY=VALUE` branch and fails as `failed to parse value from --config
argument` (`src/context/mod.rs:1553-1566`). All figures above retrieved
2026-09-17 from `GET https://api.github.com/repos/<owner>/<repo>`; file contents
read at default branch through `gh api repos/<o>/<r>/contents/<path>` the same day.

**Observable acceptance criteria.** P03's CI proves the recommendation by
asserting each of these:

1. `--config <path-that-does-not-exist>` exits `0`, applies defaults, environment
   variables and flags, and writes exactly one warning naming that path to stderr;
   stdout is byte-empty of diagnostics.
2. `--config <unparsable>` exits `2` with an `RSLB202` envelope on stderr and
   byte-empty stdout (R67's envelope clause).
3. `--config <unreadable, not NotFound>` exits `1` with an `RSLB104` envelope.
4. A corrupt *discovered* layer exits `0`, emits one warning naming that file, and
   leaves the other layers active.
5. One invalid leaf in any layer exits `0`, emits one warning naming that file and
   that dotted key, preserves sibling keys and the other tables, and falls back to
   the next valid lower-precedence value, or to the built-in default when none
   exists.
6. A fault that cannot be localized to a prunable leaf exits `2` with `RSLB203`.
7. The library crate writes nothing to any process stream on any of these paths.
8. No tolerated branch returns `Err`.

**`BASELINE-REVIEW: F237` — a corrupt config file the user explicitly named is a
hard failure, not a degraded load — keep the row inherited, but record that
"inherited as-is" cannot be literal in `rs-launch-blueprint`: the single
`ConfigError` both sources raise becomes two catalogue rows, `RSLB104` (config
layer unreadable → exit 1) and `RSLB202` (config document unparsable → exit 2);
affected items: R55 (this item, which routes to both rows) and R52/R53, which must
not assume one error type covers both faults — evidence: py raises one
`ConfigError` for both `tomllib.TOMLDecodeError` and `OSError`
(`b08bccfb:src/py_launch_blueprint/core/config.py`, `_read_explicit` lines
114-120) and ts throws one `ConfigError` for both a failed `readFileSync` and a
failed `parse` (`cb1cbcb2:src/lib/config.ts`, read catch 109-115, parse catch
117-123), while R67 — owner-accepted and consumed here — assigns the two faults
different exit codes.** Raised by the opus raw report; **accepted and carried**.
The split is R67's, already published, not a new proposal by this item; it is
recorded so F237's "inherited as-is" is not read as a promise that one error type
survives the port. This changes no ledger row and no other item's decision.

**`BASELINE-REVIEW: F238` — local recoverability must preserve a valid
lower-precedence value — validate each layer's leaves before the precedence merge
rather than py's merge-then-pop — pinned py code merges before removing the
invalid key, while an untyped document supplies the required leaf boundary;
affected R53, R54, R55, R58, R67.** Raised by the codex raw report;
**accepted and carried, and now proven rather than argued.** py pops the offending
key out of the **merged** dictionary
(`b08bccfb:src/py_launch_blueprint/core/settings.py:162`,
`bad = merged[section].pop(key, None)`). On identical two-layer inputs — a user
layer with a valid `output.format` under a project layer with an invalid one —
the executed check shows merge-then-drop falling back to the built-in default and
**losing the user layer's good value** (`## Empirical check`, N1), while
sanitize-then-merge keeps it (M1). Neither engine executed this; it was the main
unproven claim on both sides and is now measured. It is worth carrying back to py
as part of the follow-on project rather than treated as a Rust-only nicety.

**Fitness gates, per member.** Gate 1 (licence) is
`inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate; nothing was
excluded on licence, and the SPDX strings below are reported as figures only.
*Excluded by gate:* **none** — no candidate failed a gate. `serde_with`'s
`DefaultOnError` and `figment` were excluded on **fitness**, not by a gate:
the first cannot report which key it dropped (P2), the second has no
drop-and-continue.

| Gate | `serde_path_to_error` 0.1.20 | `serde_ignored` 0.1.14 |
|---|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; crates.io reports `MIT OR Apache-2.0` | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; crates.io reports `MIT OR Apache-2.0` |
| 2 MSRV | `rust_version` **1.61**; sole dependency `serde` | `rust_version` **1.61**; sole dependency `serde` |
| 3 advisories / `unsafe` | `https://rustsec.org/packages/serde_path_to_error.html` → **HTTP 404**, no advisory page (controlled: `anyhow` → **200**); `unsafe` posture **carried from the opus raw report, not re-audited here** | `https://rustsec.org/packages/serde_ignored.html` → **HTTP 404** (same control); `unsafe` posture likewise carried, not re-audited |
| 4 OS matrix | pure Rust, no platform-specific code; **executed on macOS arm64 only — `ubuntu-latest` unexercised** | same, and same limitation |
| 5 default features / async | default `std`; **no async-runtime coupling** | default `std`; **no async-runtime coupling** |
| 6 binary size / compile cost | negligible, and measured structurally: the spike lockfile holds 20 packages and the two members add **zero** transitive dependencies beyond `serde`'s own set | same |

Maintenance state, by the rubric: both **stable-quiet**. The ~12-month gap since
each crate's release (0.1.20 on 2025-09-15, 0.1.14 on 2025-09-14) is a trigger to
investigate, never the verdict. Investigated: `pushed_at` 2026-06-24 on both
repositories (about three months ago) shows live maintenance; neither is archived;
neither has an advisory; both build and run on current stable, proven by the
executed check; and `cargo` pins `serde_ignored` at exactly `0.1.14`. No concrete
`at-risk` signal exists, and no `dormant` condition (unpatched advisory, broken
build on current stable, maintainer's own notice) is present.

**Compatibility of the members.** Proven twice. (i) **Executed together**: one
binary resolved and ran `serde` 1.0.229, `toml` 1.1.6+spec-1.1.0,
`serde_path_to_error` 0.1.20 and `serde_ignored` 0.1.14 on `cargo 1.98.0` /
`rustc 1.98.0`, edition 2024, with `serde_ignored::deserialize` wrapping
`serde_path_to_error::Deserializer` wrapping the untyped document's
`IntoDeserializer` — the two side channels (key path, ignored keys) do not
interfere. (ii) **Shared adopters**: `cargo` depends on `serde_ignored` and `toml`
in the same manifest; `axum` depends on `serde_path_to_error`. (iii) **Version
matrix**: the `rust-version` floors are 1.61, 1.61 and — for R67's `thiserror`
2.0.20 — 1.71, so the binding floor is **1.71**, far below `stable minus 2 minor
versions` at any plausible 2026 stable.

**Migration implications** (P03's work list; the template does not exist yet):
a `ConfigSource` type carrying `Explicit { path, origin: Flag | Env }` and
`Discovered { path, tier }` with an `is_strict`-style predicate; a per-layer read
that maps `ErrorKind::NotFound` to an empty layer plus a warning and every other
`io::Error` to `RSLB104` for explicit sources; the bounded prune-and-retry pass
returning the **sanitized untyped document** plus warnings; a merge step over the
sanitized documents in R54's order followed by the single typed pass; a
`ConfigWarning` type and its `Display`; three variants on the config error enum
with their `ErrorCode` arms; two `[dependencies]` lines; `#[serde(default)]` on
the config struct with no fallible field inside a `#[serde(flatten)]` target; and
a CLI startup path that renders the returned warnings once, after the logger
exists, with `config set` and `config path` not requiring a successful typed load.
Module names are P03's choice; nothing was scaffolded here.

re-verify: 2027-03-17, or earlier on any of — R52 publishing an intermediate
representation that does not implement `serde::Deserializer` (the prune loop must
then be redesigned); R53 publishing (whether validation runs through
`serde::Deserialize`, whether it owns unknown-key policy and therefore whether
`serde_ignored` belongs to this item, and whether cross-field invariants are
fatal); R54 publishing (whether a discovered tier exists at all — if none does,
clause 2's tolerant limb and F236 have no Rust instance); R58 publishing (the
point at which returned warnings are rendered); R03 publishing (this loader reuses
its absence-versus-failure shape rather than inventing a parallel one); R67 being
revised; a RustSec advisory filed against `serde_path_to_error` or
`serde_ignored`; either crate going 18 months without a release **and** accruing
an unanswered breakage report on current stable; or Rust stable advancing far
enough that `stable minus 2 minor versions` rises above 1.71.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

No `- owns` line appears above because the prompt's `## Couplings` records an
empty `owns:` field: this item publishes no repo-wide parameter.

**No `CONFLICT:` line is raised.** The codex raw report raised one against
`RSLB203`; it is quoted, adjudicated and rejected under `## Engines`. R67's
catalogue expresses every failure this design produces, and the strict
alternative to clause 1 would need no new row either — it would be `RSLB201`
(usage/parse), whose published row explicitly covers "usage/parse (including the
CLI parser's own errors)".

How the parameters bear on the decision. `error-taxonomy-exit-codes` is the only
consumed parameter; this decision routes to four of its existing rows — `RSLB104`,
`RSLB202`, `RSLB203` and, only under the rejected strict alternative for the
missing-path case, `RSLB201` — and invents none. Its Layering clause (the library
crate writes to no process stream or file) is why warnings are returned rather
than printed, and its envelope clause fixes what the fatal branches emit.
`msrv-policy` is satisfied with wide headroom: the binding floor across the
members is `thiserror`'s 1.71. `rust-edition` was exercised directly — the
verification spike is an edition-2024 package. `license` constrains nothing here
under the owner's 2026-09-12 ruling; the repository's own licence text is
unaffected by this item. `target-os-matrix` is satisfied by construction — all
three members are pure Rust with no platform-specific code — but only
`macos-latest` was exercised; see `## Engines`.

Constraints this item places on other items, stated as constraints rather than as
assumptions, because none of them is a parameter yet: **R52** must expose an
untyped intermediate that implements `serde::Deserializer` (`toml::Value` does,
through `IntoDeserializer` — verified below; whether `toml_edit::DocumentMut` does
through `toml_edit::de` was **not** checked, and R52 owns that choice).
**R53** must validate through `serde::Deserialize` for the prune loop to localize
failures, and owns unknown-key policy and cross-field invariants. **R54** must tag
each layer it discovers with provenance — the document-level tolerance rule is a
function of that tag, not of the tier count — and owns merge depth and precedence
order; this item fixes only the *sequence*. **R58** must accept a
`Vec<ConfigWarning>` rendered by the binary after logging is initialized.

## Empirical check

**Toolchain.** `cargo 1.98.0 (797e8a9bc 2026-08-05)` (Homebrew),
`rustc 1.98.0 (88d9e12ae 2026-08-18)` (Homebrew), `Darwin arm64` (macOS),
`shellcheck` on `PATH`, `/usr/bin/grep` (BSD grep) as the counting binary.
Working directory: `research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/`.

**Command.**

```
./evidence/check.sh 2>&1 | tee evidence/check.log
```

**Result: `PASS=25 FAIL=0 SKIP=0`, exit status `0`.** The full output is
`evidence/check.log`. The script asserts on content in every check; a check whose
external input is unavailable prints `SKIP` with its own name rather than passing
vacuously. It locates the repository root by looking for `docs/port/PARAMETERS.md`
rather than `.git`, so it reruns from a clean `git archive HEAD` extraction. That
was executed, not assumed: `git archive HEAD | tar -x -C "$(mktemp -d)"` followed
by the extracted copy of the script produced the same `PASS=25 FAIL=0 SKIP=0` and
exit `0`. On a machine without the org CLI Design Standard repository,
`C06-cli-standard-absent` skips by name rather than passing vacuously; on this
machine the standard is present, so that check ran.

What the checks establish:

- **C01–C03 — the `CONFLICT` is settled from R67's own text.** R67 publishes the
  row `` `RSLB203` config value invalid → 2 `` and also publishes, three
  paragraphs earlier: "Each case gets its own catalog entry so R54–R56 can route
  to any of them without inventing a code. R55 and R56 own whether a given
  condition is tolerated, warned about, or fatal; this item only guarantees the
  entry and the code exist." The rows `RSLB104`, `RSLB202` and `RSLB201` are
  likewise present.
- **C04 — the ledger rows.** F235, F236, F237 (`COMMON → REUSE`, origin `same`)
  and F238 are present with the row text this decision quotes. F238's row text
  carries **no layer qualifier**, which is the evidence for clause 3 applying to
  explicit layers as well as discovered ones.
- **C05 — parameter format.** Every `- assumes` line in this file is byte-identical
  to its `docs/port/PARAMETERS.md` row (compared field-by-field, not by eye), and
  the file carries zero `- owns` lines, matching the prompt's empty `owns:` field.
- **C06 — the org CLI Design Standard.** The file read is blob
  `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, the blob this decision cites, and it
  contains the R5.2 replace clause, R5.8's "precise file/key diagnostics" and its
  `❌ silently ignoring bad config` anti-pattern, and R7.6's "name the offending
  input in quotes" requirement.
- **C07 — crate figures, asserted from snapshots.** `GET
  https://crates.io/api/v1/crates/<name>/versions`, retrieved 2026-09-17, saved to
  `evidence/serde_path_to_error-versions.json` and
  `evidence/serde_ignored-versions.json`; the assertions read the snapshots, not
  the live endpoint, so they are stable on rerun. Newest non-yanked
  `serde_path_to_error` **0.1.20** (`created_at` 2025-09-15T15:05:54Z, `license`
  `MIT OR Apache-2.0`, `rust_version` **1.61**) and `serde_ignored` **0.1.14**
  (`created_at` 2025-09-14T15:55:10Z, same licence, `rust_version` **1.61**).
  Download counts (`recent_downloads` 80,853,700 and 11,429,284; `downloads`
  280,245,735 and 51,134,001, from `GET https://crates.io/api/v1/crates/<name>`,
  retrieved 2026-09-17, snapshotted beside the script) move daily and are
  therefore **reported, never asserted**. GitHub figures were taken by hand with
  the authenticated `gh api` on 2026-09-17 and are not in the script, because the
  script must not require a token: `GET https://api.github.com/repos/dtolnay/path-to-error`
  → `stargazers_count` **426**, `archived` **false**, `pushed_at`
  **2026-06-24T03:04:53Z**; `GET https://api.github.com/repos/dtolnay/serde-ignored`
  → **106**, **false**, **2026-06-24T03:05:30Z**; `GET
  https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` →
  `total_count` **5** and **6** respectively.
- **C08 — the verification spike.** `evidence/spike/` holds the spike's source as
  the check's input; the script copies it to a temporary directory and builds it
  **outside the repository**, exactly as the opus engine did. Nothing was built
  in-tree: P03 builds the template. Resolved versions from its lockfile: `serde`
  1.0.229, `toml` 1.1.6+spec-1.1.0, `serde_path_to_error` 0.1.20, `serde_ignored`
  0.1.14, in a 20-package graph. Sixteen assertions, all passing:

  | Case | What it measures | Result |
  |---|---|---|
  | A1–A4 | one bad leaf among good ones | dropped; sibling `output.limit = 7` and the other table survive; exactly one warning naming `output.format` |
  | B1 | two bad leaves | both dropped in two loop passes; `limit = 7` preserved |
  | C1 | unknown key | reported through `serde_ignored`; load succeeds; sibling survives |
  | D1 | unparsable document | maps to `RSLB202` |
  | E1–E2 | a whole table of the wrong shape (`output = 5`) | the tracked path is `output`, so the table is a prunable leaf; the sibling `verbose = true` survives |
  | F1 | a root-level shape fault | not localizable to a prunable leaf → fatal `RSLB203`; this is the branch that keeps `RSLB203` from being orphaned |
  | H1 | failing leaf **inside** a `#[serde(flatten)]` target | tracked path collapses to `"."`, addressing nothing prunable |
  | H2 | failing leaf **outside** the flattened target | tracked path stays `output.format` and prunes cleanly |
  | M1–M3 | two layers, sanitize → merge → one typed pass | the lower layer's valid `output.format` survives the higher layer's invalid one; one warning, naming the higher layer; the final typed pass over the merged document did not fail |
  | N1 | the same two layers under py's merge-then-drop order | falls back to the built-in default, **losing** the user layer's valid value |

**Reproducibility, stated exactly.** `evidence/check.log` is the output of one
executed run of `evidence/check.sh`. The script was then rerun and diffed against
that log before this sentence was written. The complete diff is
`evidence/rerun.diff`, and it is **one line**: the `date (UTC)` value in the
environment header. Every assertion line, every count and every figure is
byte-identical across the two runs. The crates.io and
GitHub figures are read from snapshots committed beside the script rather than
from the live endpoints, so no live-source drift can change an assertion; the
snapshots' retrieval date is 2026-09-17.

## Engines

- codex (gpt-5.6-terra) `raw/codex-523260b7256c2c89acef409e57c29369daa1ccdee3f0c4674e4b6bb14248d550.md`
- opus (claude-opus-5) `raw/opus-92427e8b93642e3ff8c4f482636b9cdc7ca2b78729468a7d7e79c31563f92b7f.md`

**Disagreement 1 — does R67's `RSLB203` row conflict with per-leaf recovery? It
does not; codex's reading was wrong.** codex wrote, verbatim:

> CONFLICT: R67 error-taxonomy-exit-codes — `RSLB203 config value invalid` cannot mean every invalid file leaf — R55 requires an individually invalid declared config value to warn-and-drop, reserving `RSLB203` for a fatal nonrecoverable validation outcome such as R53's cross-field invariant.

opus reported **no** conflict, holding that R67's catalogue expresses every
failure this design produces. **Settled for opus, from R67's own text rather than
from either engine's argument.** The row reads, in full:
`` `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**) ``.
That is a catalogue *entry*: a fault class, a stable code, an exit integer. It is
not a rule about when the fault is raised. R67 says so itself, in the paragraph
that introduces the configuration rows: "Each case gets its own catalog entry so
R54–R56 can route to any of them without inventing a code. **R55 and R56 own
whether a given condition is tolerated, warned about, or fatal; this item only
guarantees the entry and the code exist.**" (verified, `## Empirical check`, C02.)
codex's error is reading an entry as a mandate. A tolerated leaf raises no error
at all — it is a `ConfigWarning` in the `Ok` arm — so it never reaches the
catalogue, and there is nothing for the row to exclude. The narrowing codex asked
for is therefore not a change to R67; it is exactly what this decision does under
its own ownership, and `RSLB203` keeps a real target (measured: case F1, and R53's
cross-field invariants). **No `CONFLICT:` line is carried forward**, and R67
needs no revision. Recorded, not escalated, on the same grounds R67 revision 1
used for the one `CONFLICT:` line its own raws raised.

**Disagreement 2 — is a bad *value* in an **explicit** layer fatal or tolerated?**
codex tolerates a bad leaf in every layer (its essential outcome 4 is unqualified
by provenance). opus makes a bad leaf fatal in an explicit layer (`RSLB203`) and
tolerates only discovered layers. **Settled for codex**, on three pieces of
evidence and against opus's structural argument:
(i) F238's ledger row carries **no layer qualifier** (verified, C04d), and py's
`settings_from_layers` validates the **merged** dictionary — under py's own
`--config` handling the explicit file *is* the sole file layer, so py demonstrably
tolerates a bad value in an explicit file;
(ii) py's stated rationale — "config must never brick the CLI" — is about
repairability, which does not weaken because the user named the file;
(iii) opus derives explicit-strictness from F237, but F237 is about an
**unparsable** document, not an invalid value; extending it to values would extend
a settled row beyond its own text.
opus's practice evidence argues against opus's own rule: ripgrep reports bad
*lines* in an explicitly named config and keeps the good ones, and starship drops
a bad value per unit with a warning. The cost if this is wrong is one branch:
routing the explicit-layer value fault to `RSLB203` instead of to a warning. That
is the one place in this decision an owner could reasonably decide the other way.

**Disagreement 3 — the mechanism for per-key drop.** codex proposes parsing to
`toml::Value` and converting each declared leaf independently, and admits in its
own Parameters field that this "assumes R53 validation = independently callable
declared-field validation". That is alternative D — hand-rolled extraction — and
it drifts from whatever R53 selects. opus proposes prune-and-retry through
`serde_path_to_error` and executed it. **Settled for opus**, and re-executed
independently here (`## Empirical check`, C08): the composition works against any
derived `Deserialize`, so it leaves R53 free.

**Disagreement 4 — where the degrade warning is emitted.** codex says the CLI or
web composition root emits it, "eventually `tracing::warn!`", citing R67's
layering rule. opus adds the stronger reason: config loading **precedes** logger
initialization, so a `warn!` at the point of degradation has no subscriber and is
discarded. **Settled for opus's reasoning, same outcome** — warnings are returned
as data and rendered once by the binary, which is also what `cargo` does
(`src/workspace/parser/mod.rs:148-152`).

**Disagreement 5 — is a missing explicit path warned about or silent?** py is
silent (`core/config.py:114-115`) and codex's essential outcome 1 does not require
a warning; opus requires one. **Settled for opus**, on the standard: R5.8 names
`❌ silently ignoring bad config` as the anti-pattern and R5.7 exists so a user can
see why a setting took the value it did (verified, C06d).

**A raw claim this synthesis corrected.** opus's case H states that the tracked
path "collapses to `.`" under `#[serde(flatten)]`, and rule 5 (no `flatten` at all)
rests on it. Re-running that measurement here found the claim **true but narrower
than stated**: the collapse happens when the failing leaf is *inside* the
flattened target (H1); a leaf *outside* it keeps a prunable path (H2). The
constraint this decision carries is correspondingly narrower — no **fallible**
field inside a `flatten` target — rather than a blanket prohibition.

**Both engines' `BASELINE-REVIEW:` lines are accepted and carried**, with their
dispositions in `### Principles and implementation`: opus's against F237 (the
single `ConfigError` becomes two catalogue rows) and codex's against F238
(sanitize per layer before the precedence merge). Neither engine executed the
second; it is now measured (M1, N1).

**Unproven, and left for P03 to prove in the real template.**

1. **`ubuntu-latest` was not exercised.** Every check here ran on macOS arm64.
   Nothing in the members is platform-specific, but the claim is structural, not
   measured.
2. **The `unsafe` posture of both crates was not re-audited here.** opus reports
   zero occurrences of `unsafe` in the `src/` of each 0.1.20 and 0.1.14 tarball;
   that figure is carried, not independently reproduced.
3. **No performance measurement.** Only a qualitative cost is stated: the loop
   re-runs the typed pass once per dropped key over an already-parsed in-memory
   document, bounded by leaf count; the common case (no bad keys) is exactly one
   pass, and nothing here is on a request path. No workload, latency or throughput
   figure is claimed, because none was taken.
4. **The strict alternative for the missing-path case (`RSLB201` at exit 2) was
   not exercised.** Only the recommended tolerant branch and the two strict
   document-level branches were.
5. **The unreadable-but-present explicit layer (`RSLB104`) was not exercised**
   either: the spike models document-level faults through parse failures, not
   through a permission error.
6. **Whether `toml_edit::DocumentMut` implements `serde::Deserializer` through
   `toml_edit::de` was not checked.** Only `toml::Value` was verified. R52 owns
   that choice, and if it selects an intermediate that is not a
   `serde::Deserializer`, the prune loop must be redesigned.
7. **Issue-responsiveness medians are approximate.** Both repositories have fewer
   than ten issues in total, so the rubric's "10 most recently opened" window is
   `inapplicable — fewer than 10 issues exist`; open-issue `total_count` is
   reported instead (5 and 6, from the search endpoint, never
   `open_issues_count`).
8. **The RustSec 404s are interpreted, not asserted.** `rustsec.org` returns 404
   for a crate with no advisory page; this was controlled against `anyhow`, which
   returns 200 and has a known advisory. No advisory-db clone was searched.
9. **`figment` was not prototyped.** Its lack of drop-and-continue is read from
   its documented `Error` semantics, not measured.
10. **Whether `serde_ignored` belongs to this item at all** rather than to R53 is
    genuinely open; opus flags it and this decision carries the member
    contingently. No load-bearing claim rests on it.

**What P03 must validate**: the eight observable acceptance criteria above; the
multi-layer behavior inside the real schema, on both runners in
`ubuntu-latest, macos-latest`; that the library crate's streams stay empty on
every path; that the warning text names both the file and the dotted key; that
`config set` and `config path` work without a successful typed load; and that the
prune loop's bound is never reached in practice on a realistic config.
