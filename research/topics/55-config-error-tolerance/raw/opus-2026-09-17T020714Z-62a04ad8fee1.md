# R55 — config-error-tolerance (bundle) — raw report, Opus engine

Engine identity `research-opus-2026-09-17T020714Z-62a04ad8fee1`, model `claude-opus-5`.
All retrieval dates in this report are **2026-09-17** (UTC; `date -u` on the research
machine returned `2026-09-17T04:15:15Z`). No template code exists; nothing here was
scaffolded into the repository. The one executable check reported below ran in a
throwaway package in this session's scratchpad, outside every repository.

### Landscape

**The category this item decides.** Not "which config library" — R52 (`toml-crate`),
R53 (`config-schema-validation`) and R54 (`config-discovery-tiers`) own the parsing
crate, the validation mechanism and the tier set. This item decides a **failure
policy**: for each of three faults (missing explicit path, unparsable discovered
layer, invalid individual value), whether the loader degrades with a visible warning
or fails the process, and — where it degrades — at what granularity (one key, one
layer, the whole load). In Rust the policy is inseparable from one mechanism
question, because `serde`'s derived `Deserialize` is **fail-fast**: it returns the
first error and no value, where `pydantic` (`ValidationError.errors()`) and `zod`
(`safeParse(...).error.issues`) both return a *collection* of per-field errors from a
single pass. Any per-key tolerance in Rust must therefore be built, not configured.

**Three-bin map of the Rust field.**

*Built-in / first-party toolchain.*
- `serde` derive with `#[serde(default)]` on every field — the language-level
  tolerance primitive: a **missing** key is already tolerated with no crate at all.
  It gives no tolerance for a *present but wrong* value.
- An untyped intermediate document (`toml::Value`, `toml::de::DeTable`) that
  implements `serde::Deserializer`, then a typed pass over it. This is not a crate
  choice so much as a shape: it is what `cargo` itself does
  (`rust-lang/cargo` `src/workspace/parser/mod.rs:186-203`, retrieved 2026-09-17 via
  `gh api repos/rust-lang/cargo/contents/src/workspace/parser/mod.rs`): `parse_document`
  produces `toml::Spanned<toml::de::DeTable>`, `deserialize_toml` then builds the
  typed `TomlManifest` from it.
- `std::io::ErrorKind::NotFound` — the std distinction that separates "the file is not
  there" from "the file is there and I cannot read it". Free, and load-bearing for (a).
- `std::process::ExitCode` + the R67 `ErrorCode`/`Exit` taxonomy for the fatal branches.

*Established industry standard.*
- `serde_path_to_error` (dtolnay) — turns serde's fail-fast error into a *machine-readable
  key path*, which is what makes drop-and-continue implementable. Adopted by `axum` for
  its `Json`/`Form` extractors (`tokio-rs/axum` `axum/Cargo.toml:139`,
  `serde_path_to_error = { version = "0.1.8", optional = true }`, and `:61`
  `json = ["dep:serde_json", "dep:serde_path_to_error"]`, retrieved 2026-09-17).
- `serde_ignored` (dtolnay) — side-channel report of keys the typed struct ignored.
  Adopted by `cargo` for its "unused manifest key" warnings (`rust-lang/cargo`
  `Cargo.toml:103` `serde_ignored = "0.1.14"`; use at `src/workspace/parser/mod.rs:198`,
  retrieved 2026-09-17).
- `config` (`rust-cli/config-rs`) — layered config with `File::with_name(..).required(false)`,
  i.e. missing-layer tolerance as a builder flag. Extraction is all-or-nothing.
- `figment` (`SergioBenitez/Figment`, Rocket's config engine) — provider layering with
  `Metadata` provenance and an error type that **accumulates** several failures
  (`figment::Error` is an iterator of `figment::Error` with `path` and `metadata`).
  Still no drop-and-continue: extraction either yields the value or the error set.
- `thiserror` for the typed library error, already fixed by R67.

*Up-and-comers / narrower options.*
- `serde_with`'s `DefaultOnError` — per-field tolerance as a field attribute. It is the
  *silent* version of what this item needs: it swallows the error with no hook to report
  which key was dropped, so it cannot produce py's warning.
- A project-local derive that makes every field tolerant and logs — `alacritty`'s
  `alacritty_config_derive` is the known instance of this shape. Not evaluated in depth
  here: it is a build-your-own-macro cost that `serde_path_to_error` avoids.
- `toml`'s `Spanned<T>` — carries byte spans, so a warning can point at a line/column
  rather than a key path. Attractive, but it is R52's surface, not this item's.

**Authoritative sources used, and why each counts.**
- **serde's own documentation** on field attributes (`https://serde.rs/field-attrs.html`,
  retrieved 2026-09-17) — the project's maintained reference for `default`,
  `deserialize_with`, `flatten` and `deny_unknown_fields`. Authoritative because serde
  defines the deserialization model the whole question turns on.
- **`serde_ignored`'s own docs** (`serde_ignored-0.1.14/src/lib.rs:17`, from the crate
  tarball `https://static.crates.io/crates/serde_ignored/serde_ignored-0.1.14.crate`,
  sha256 `115dffd5f3853e06e746965a20dcbae6ee747ae30b543d91b0e089668bb07798`, retrieved
  2026-09-17) — states that a project wanting hard failure should use
  `#[serde(deny_unknown_fields)]` *instead*; the two are alternatives, not a stack.
- **`serde_path_to_error`'s source** (`serde_path_to_error-0.1.20/src/de.rs:71,79`, from
  `https://static.crates.io/crates/serde_path_to_error/serde_path_to_error-0.1.20.crate`,
  sha256 `10a9ff822e371bb5403e391ecd83e182e0e77ba7f6fe0160b795797109d1b457`, retrieved
  2026-09-17) — `pub struct Deserializer` with `pub fn new(de: D, track: &mut Track)`
  is what makes the crate *composable* with `serde_ignored` rather than exclusive of it.
  Read from source rather than from prose because the composition is the load-bearing claim.
- **The org CLI Design Standard as already applied by R67** (`research/topics/67-.../DECISION.md:255-277`)
  — authoritative for this item by consumption, not re-derivation: R67 is owner-accepted
  and fixes which fault gets which exit code.
- **The pinned source repositories** (`py-launch-blueprint` at `b08bccfb`,
  `ts-launch-blueprint` at `cb1cbcb2`) — authoritative for what the precedent *is*,
  read through the pins as the role file requires.
- A single blog post was not used as an authority anywhere in this report.

**Practice evidence: what well-regarded Rust projects actually do.** Every file below
was read at its current default-branch content through `gh api repos/<o>/<r>/contents/<path>`
on 2026-09-17; ripgrep's `master` was at `3fce3b5bb0236da2df6d99672afb8a719642eca7`.

| Project | Why it is a relevant, well-regarded reference | What it does with a config fault |
|---|---|---|
| `ripgrep` (BurntSushi) | The reference Rust CLI. `GET https://api.github.com/repos/BurntSushi/ripgrep` (2026-09-17): **68,336** stars, `pushed_at` **2026-08-04T13:59:44Z** | **Explicit path that cannot be read (incl. missing) → warn and continue with no config**: `crates/core/flags/config.rs:32-40` — `Err(err) => { message!("failed to read the file specified in RIPGREP_CONFIG_PATH: {}", err); return vec![]; }`. **Bad *lines* inside a readable config → report each, keep the good ones**: `:41-45` prints every element of `errs` while `args` (the successfully parsed arguments) are returned and used. `message!` writes to stderr and is suppressed by `--no-messages` (`crates/core/messages.rs`) |
| `cargo` (rust-lang) | The toolchain's own CLI and the highest-stakes TOML consumer in the ecosystem. `GET https://api.github.com/repos/rust-lang/cargo` (2026-09-17): **15,484** stars, `pushed_at` **2026-09-16T13:22:52Z** | **Two-phase load**: untyped `toml::de::DeTable` document, then typed deserialize from it (`src/workspace/parser/mod.rs:186-203`). **Unknown keys → warning, not failure**, via `serde_ignored::deserialize(deserializer, |path| { unused.insert(key); })` (`:198`). **Warnings are returned as data, not logged at the point of degradation**: they accumulate in a `Vec<String>` and are attached to the manifest at `:148-152` (`manifest.warnings_mut().add_warning(warning)`). **A `--config` argument naming a path that does not exist is an error**, not an empty layer — but for a reason specific to cargo: the flag is overloaded, so a non-existent path falls through to the `KEY=VALUE` branch and fails as `failed to parse value from --config argument` (`src/context/mod.rs:1553-1566`) |
| `starship` (59,920 stars, `pushed_at` 2026-09-17T03:32:48Z, `GET https://api.github.com/repos/starship/starship`) | Very large, very current adoption; a shell prompt, so its tolerance posture is deliberate and documented in code | **Every fault degrades.** Unparsable file → `log::error!("Unable to parse the config file: {error}")` and `None`, the program still runs (`src/config.rs:139-149`). Missing/unreadable file → log and `None` (`:151-165`, level chosen from `e.kind() == ErrorKind::NotFound`). **Invalid value → per-unit drop with a warning and a default**: `ModuleConfig::load` at `:31-39` — `Err(e) => { log::warn!("Failed to load config value: {e}"); Self::default() }`. **Unknown key → warn, then re-deserialize leniently**: `:53-62` detects the unknown-key error, warns, and retries with `with_allow_unknown_keys()` — an independent instance of the detect-warn-retry loop recommended below |
| `axum` (tokio-rs) | The dominant Rust web framework, relevant because this template has a web surface. `GET https://api.github.com/repos/tokio-rs/axum` (2026-09-17): **27,156** stars, `pushed_at` **2026-09-15T07:20:31Z** | Uses `serde_path_to_error` in its `Json`/`Form` extractors so a deserialization failure can name the offending field (`axum/Cargo.toml:139`, `axum/src/json.rs`) |

Practice is **unanimous on (b) and (c)-in-discovered-layers** (degrade with a visible
warning, keep what parsed) and **split on (a)**: ripgrep tolerates a missing explicit
path with a warning; cargo errors. The split is explained, not left open: cargo's
`--config` is not a pure path flag.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

*P1 — a configuration fault must never leave the user unable to repair it.* Source:
py states it in the code, not just in the ledger — `core/settings.py:141-145`
(`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/settings.py`):
"Invalid values are **dropped with a warning** rather than raised: config must never
brick the CLI — the user needs `config set`/`config path` working in order to repair
the file." Agreement level: **policy**. All three repos must satisfy it; the mechanism
may differ.

*P2 — the blast radius of a fault matches how deliberately the user pointed at the
file.* This is not stated anywhere as a principle, but it is what the ledger's settled
rows already encode: F237 (`COMMON → REUSE`) makes an unparsable **explicit** file a
hard error in both repos, while F236 makes an unparsable **discovered** file a warning
in py. Agreement level: **architectural pattern**. Deriving both rows from one rule is
the main analytical claim of this report.

*P3 — a degraded load is never silent.* py satisfies it for (b) and (c) (it returns
warning strings) and **violates it for (a)**: `_read_explicit` returns `{}` for a
missing path with no warning at all — `core/config.py:114-115`, `if not path.exists():` / `return {}`, read line-for-line at the pin on 2026-09-17. ts satisfies it
trivially by never degrading. Agreement level: **observable acceptance criterion**.

*P4 — the library crate decides, the binary prints.* Source: R67's Layering clause (the
library must write to no process stream) and R01's composition-root shape. Agreement
level: **architectural pattern**, and it is where py and rs must agree on shape while
differing in type: py returns `list[str]`, rs should return a typed `Vec<ConfigWarning>`.

**What must agree, and what may vary.** Must agree: P1–P4, and the three-way
classification itself (missing / unparsable / invalid-value are distinct cases with
distinct answers — this is the thing ts collapsed and py did not). May vary: the
granularity of the drop (per-key in py and rs, per-file in ts today), the warning
carrier (`list[str]`, an injected `warn` callback, a typed `Vec<ConfigWarning>`), and
the mechanism (pydantic's error collection vs. a serde prune-and-retry loop). The
ecosystem difference is real and justified: serde is fail-fast and pydantic/zod collect,
so the same policy costs ~60 lines in Rust and ~0 in Python.

**Architectural alternatives for (c), compared before any library is chosen.**

| Alternative | How it works | Per-key drop? | Names the key in a warning? | Cost |
|---|---|---|---|---|
| **A. All-or-nothing typed deserialize** (ts's shape) | `toml::from_str::<ConfigFile>(text)?` | No | Only in the fatal message | Zero. Loses P1 for discovered layers |
| **B. Prune-and-retry over the untyped document** (recommended) | Parse to `toml::Value`; typed pass through `serde_path_to_error::Deserializer`; on error remove the leaf the tracked path names and retry; bound the loop by leaf count | Yes | Yes, by key path | ~60 lines + 2 tiny crates; N passes for N bad keys |
| **C. Per-field `deserialize_with` wrapper / project derive** (alacritty's shape) | Every field deserializes through a wrapper that falls back to `Default` | Yes | Only if the wrapper can reach a collector — a side channel or `RefCell` | A derive macro to maintain, or an attribute on every field. `serde_with::DefaultOnError` is the version with **no** reporting |
| **D. Hand-rolled per-key extraction** | No derived `Deserialize`; read each key out of `toml::Value` explicitly | Yes | Yes | Boilerplate proportional to the schema; drifts from R53's validation choice |
| **E. `figment`** | Providers + `Metadata` provenance; `figment::Error` accumulates several failures | **No** — extraction is still all-or-nothing | Yes, with file provenance | Adopts a whole config framework, pre-empting R52/R53/R54 |

B is chosen because it is the only option that delivers per-key drop *with* a
machine-readable key name while leaving R52/R53/R54 free. E is the ranked runner-up
architecture and would be revisited only if R54 chooses a provider-style layering model.

**The recommended design, stated as rules.**

1. Every layer the loader handles carries provenance:
   `enum ConfigSource { Explicit { path, origin: Flag | Env }, Discovered { path, tier } }`.
   "Explicit" includes an env-supplied path, not only `--config`.
2. **Explicit layer → strict.** Unparsable document → `RSLB202` / exit 2. Invalid value →
   `RSLB203` / exit 2. Unreadable (any `io::Error` whose kind is **not** `NotFound`) →
   `RSLB104` / exit 1. **Missing (`ErrorKind::NotFound`) → tolerated as an empty layer,
   with a warning naming the path.**
3. **Discovered layer → tolerant.** Unreadable, unparsable, invalid value and unknown key
   all degrade: the loader keeps every key it could use, emits one warning per dropped
   thing naming the file and the key path, and never changes the exit code.
4. Warnings are returned, never printed: `Result<(Config, Vec<ConfigWarning>), ConfigError>`
   with `struct ConfigWarning { source: ConfigSource, key: Option<String>, reason: ConfigWarningKind }`.
5. The config struct carries `#[serde(default)]` and **must not use `#[serde(flatten)]`**
   (see the verified limitation below).

**How N layers compose into one `Config`: sanitize untyped → merge → type once.** The
provenance rule forces validation to happen *per layer* (strictness is a function of the
layer's origin), but per-layer typed values cannot then be merged: with
`#[serde(default)]` on every field, a `limit: 0` produced by `Default` is
indistinguishable from a written `limit = 0`, so merging typed structs would let a
lower layer's default overwrite a higher layer's value or vice versa, with no way to tell
which keys were actually present. The loader therefore returns the **sanitized untyped
document** from each tolerant layer, not a typed value: the prune loop already mutates
the untyped document in place, so what it hands back is that document with the
unusable keys removed, plus the warnings explaining each removal. The loader merges the
sanitized documents in R54's precedence order and then runs **exactly one** typed pass
over the merged document, through the same `serde_ignored` + `serde_path_to_error`
composition. That final pass cannot fail on a value fault by construction — every key
that survived sanitization already deserialized successfully in its own layer — so it is
the strict pass, and a failure there is a bug, not a user error. (The spike's
`load_tolerant` returns a typed value only because it demonstrates a single layer;
returning `doc` instead of the typed value is a one-line change.) Merge order and merge
depth — whole-table replacement versus per-key override — are R54's and D-017(1)'s to
fix; the only thing this item fixes is the **sequence**.

Sanitizing before merging is strictly better than py, which pops the offending key out of
the **merged** dictionary (`b08bccfb:src/py_launch_blueprint/core/settings.py:162`,
`bad = merged[section].pop(key, None)`). If a project layer writes an invalid
`output.format` over a user layer's valid one, py drops the merged key and falls back to
the built-in default, silently discarding the user layer's good value; sanitizing each
layer first keeps it. rs gains that for free from the ordering, and it is worth carrying
back to py as part of the follow-on project rather than treated as a Rust-only nicety.

Rule 2's tolerance for a *missing* explicit path is py's outcome but **not py's
rationale**. py justifies it as "a valid target for `config set`"
(`core/config.py:109-112`). That argument does not carry in Rust: `config set` and
`config path` operate on the file path and the document (a `toml_edit`-style
round-trip), not on the typed loader, so they keep working whether or not the typed load
tolerates absence — exactly as they keep working when a value is invalid. The rationale
that does carry is narrower and worth stating on its own: an **env-supplied** explicit
path is set once in a shell profile, a container image or a CI job, and a hard failure
there makes every invocation fail until a file exists — ripgrep's `RIPGREP_CONFIG_PATH`
handling (`crates/core/flags/config.rs:32-40`) is precisely that case, and it warns and
continues. ts's contrary behavior additionally rests on a premise the ledger already
flagged as false: its code comment says `click.Path(exists=True)` parity
(`ts: src/lib/config.ts:153`), but the pinned py commit's `--config` option does not set
`exists=True` (`docs/port/areas/config-env-logging.md:18`;
`docs/port/DIVERGENCE-ANALYSIS.md:297`).

Both answers to (a) are expressible in R67's catalogue, so **no `CONFLICT:` line is
needed either way**: the recommended tolerant branch raises nothing at all, and the
strict alternative would be `RSLB201` (usage/parse) at exit 2 — R67's row explicitly
covers "usage/parse (including the CLI parser's own errors)". R67 has no dedicated
"explicit config missing" row, and none is needed.

BASELINE-REVIEW: F237 — a corrupt config file the user explicitly named is a hard failure, not a degraded load — keep the row inherited but record that "inherited as-is" cannot be literal in `rs-launch-blueprint`: the single `ConfigError` both sources raise becomes two catalogue rows, `RSLB104` (config layer unreadable → exit 1) and `RSLB202` (config document unparsable → exit 2); affected items: R55 (this item, which routes to both rows) and R52/R53, which must not assume one error type covers both faults — evidence: py raises one `ConfigError` for both `tomllib.TOMLDecodeError` and `OSError` (`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/config.py`, `_read_explicit` lines 114-120, retrieved 2026-09-17) and ts throws one `ConfigError` for both a failed `readFileSync` and a failed `parse` (`git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/config.ts`, read catch at lines 109-115, parse catch at 117-123, retrieved 2026-09-17), while R67 — owner-accepted, consumed here — assigns the two faults different exit codes (`research/topics/67-error-and-exit-code-contract/DECISION.md:258-263`). The split is R67's, not a new proposal by this item; it is recorded so F237's "inherited as-is" is not read as a promise that one error type survives the port.

**Minimal realistic example and the executable check — actually run.** A throwaway
package (`r55-spike`, edition 2024) was built and run in this session's scratchpad with
`cargo 1.98.0 (797e8a9bc 2026-08-05)` / `rustc 1.98.0 (88d9e12ae 2026-08-18)`. Resolved
versions from its `Cargo.lock`: `serde 1.0.229`, `toml 1.1.6+spec-1.1.0`,
`serde_path_to_error 0.1.20`, `serde_ignored 0.1.14`, and no other non-transitive crate.
It implements rules 2–4 over a two-table `ConfigFile`, for **one layer**, and asserts
the behavior. The multi-layer sequence above is designed, not executed. Executed
results (`cargo run --quiet`, 2026-09-17):

- **A. Discovered layer, one bad value among good ones.** Input
  `verbose = true` / `[output] format = "yaml"` / `limit = 7`. Result
  `ConfigFile { output: Output { format: Text, limit: 7 }, verbose: true }` with one
  warning `ignoring invalid config value /etc/x/config.toml: output.format (unknown
  variant `yaml`, expected `text` or `json`)`. **Per-key drop works: the sibling key and
  the other table both survived**, and the warning names the key path.
- **B. Two bad values.** Both dropped in two loop passes, `limit = 7` preserved.
- **C. Unknown key.** `output.colour` reported through `serde_ignored` as a warning;
  the load succeeded and `output.limit = 3` survived.
- **D. Unparsable discovered layer.** Degraded to `ConfigFile::default()` plus
  `ignoring unparsable config file …` — no error returned.
- **E. Explicit layer, same inputs.** Both faults returned errors carrying the R67 codes:
  `RSLB202 invalid TOML in config file ./my.toml: …` and
  `RSLB203 invalid config value ./my.toml: output.format: …`.
- **G. A whole table of the wrong shape** (`output = 5`): the tracked path is `output`,
  so the prune drops the table and the sibling `verbose = true` still survives.
- **H. `#[serde(flatten)]` — a verified limitation.** With a flattened field, the tracked
  path collapses to `"."`: it does not address a prunable leaf, so per-key drop silently
  degrades to whole-layer drop. **Rule 5 exists because of this measured result**, not
  because of documentation.

The composition itself is therefore verified, not assumed: `toml::Value` →
`IntoDeserializer` → `serde_path_to_error::Deserializer::new(inner, &mut track)` →
`serde_ignored::deserialize(de, cb)` compiles and runs on stable 1.98.0, edition 2024,
and the two side channels (key path, ignored keys) do not interfere.

No performance measurement is claimed. The qualitative cost is stated instead: the loop
re-runs the typed pass once per dropped key over an already-parsed in-memory
`toml::Value`, bounded by the document's leaf count; for a config file of a few dozen
keys this is microseconds against the file read, and the common case (no bad keys) is
exactly one pass. Nothing here is on a request path.

### Recommendation

**`serde_path_to_error` 0.1.20 + `serde_ignored` 0.1.14 + `thiserror` 2.0.20 (reused
from R67), composed as a provenance-aware two-phase loader**: parse each layer to the
untyped document R52 selects, deserialize typed through
`serde_ignored::deserialize(serde_path_to_error::Deserializer::new(doc.into_deserializer(),
&mut track), cb)`, and branch on the layer's provenance — explicit layers fail loudly
with R67's `RSLB104`/`RSLB202`/`RSLB203`, discovered layers drop the offending key (or,
where the path cannot be isolated, the table or the layer) and keep going. A *missing*
explicit path is an empty layer with a warning, never an error. Layers compose as **sanitize untyped → merge in R54's order → one typed pass**, never
by merging typed values. Warnings are returned to the caller as a typed
`Vec<ConfigWarning>`; the library prints nothing.

### Members

#### serde_path_to_error

##### Landscape
Established-industry-standard bin. It is the only maintained crate whose job is to turn
serde's fail-fast error into a machine-readable path, which is the precondition for any
per-key tolerance. The alternatives in its slot are not crates: reading the key out of
the error's `Display` string (fragile — `toml`'s own rendering appends ``in `output.format` ``
but that is a formatting detail, not an API), or abandoning derived deserialization
(option D above).

##### Principles and implementation
Serves P1 (repairability: the loader can drop exactly the offending key) and P3 (the
warning can name the key). Used as `serde_path_to_error::Deserializer::new(de, &mut track)`
— the *wrapping deserializer* form, verified public at
`serde_path_to_error-0.1.20/src/de.rs:71,79` — rather than the simpler
`serde_path_to_error::deserialize(de)` free function, because the wrapping form is what
composes with `serde_ignored`. Reference implementation: `axum`'s `Json` extractor
(`tokio-rs/axum` `axum/src/json.rs`, `axum/Cargo.toml:139`, retrieved 2026-09-17).

##### Dominant choice
Yes — dominant by adoption and by being dtolnay's, the same maintainer as `serde_derive`,
`thiserror` and `anyhow`, all already in this template's dependency set.

##### Qualified shortlist
`serde_path_to_error` 0.1.20 (recommended). No second crate qualifies; the qualified
*alternatives* are architectural (options C and D above), not libraries.

##### Excluded by gate
None. Gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`.

##### Up-and-comers
None identified in this slot. `toml`'s `Spanned<T>` offers a different localization axis
(byte spans rather than key paths) and belongs to R52.

##### Fit for this template
CLI · library · web service all benefit. In the library crate it is a pure data
transformation with no I/O, no global state and no runtime coupling — compatible with
R67's rule that the library writes to no process stream. In the web surface, axum
already pulls it in behind its `json` feature, so the template's two surfaces share it.
No async coupling; `no_std`-categorized; nothing platform-specific, so
`ubuntu-latest, macos-latest` is trivially satisfied.

##### Recommendation
Adopt at `serde_path_to_error = "0.1.20"` in the library crate.

##### Ranked runner-up
Parse the key out of the error's `Display` text and prune on that. Rejected: it makes
the prune loop depend on another crate's message formatting, which is not a stability
surface.

##### Tradeoffs
Costs one small dependency (its only dependency is `serde`, which is already present)
and an extra `Track` allocation per typed pass. Gains the only reliable key identity.
Its path degrades to `"."` under `#[serde(flatten)]` (measured, case H), which
constrains the config struct's shape — stated as rule 5 rather than discovered in P03.

##### Parameters
`assumes rust-edition = 2024` (spike built on edition 2024, `rust_version` of the crate
is 1.61 so the edition is unconstrained by it). `assumes msrv-policy = stable minus 2
minor versions…` — crate `rust-version = 1.61`, far below any plausible floor; its only
dependency is `serde`. No `CONFLICT:`.

##### Migration implications
New line in the library crate's `[dependencies]`; used in exactly one module (the
tolerant typed pass).

##### Validation strategy
Covered by the executed spike cases A, B, G and H above; in the template, by unit tests
over the loader asserting that a bad key is dropped and its siblings survive.

##### Confidence & re-verify trigger
High. Re-verify if the crate has no release for 18 months *and* an open issue reports
breakage on current stable, or if R53 selects a validation mechanism that does not run
through `serde::Deserialize` (in which case this member's slot disappears).

##### Sources
`GET https://crates.io/api/v1/crates/serde_path_to_error` (retrieved 2026-09-17):
`crate.recent_downloads` **80,853,700**; `crate.downloads` **280,245,735**.
`GET https://crates.io/api/v1/crates/serde_path_to_error/versions` (2026-09-17): newest
non-yanked **0.1.20**, `created_at` **2025-09-15T15:05:54Z**, `rust_version` **1.61**,
`license` **MIT OR Apache-2.0**.
`GET https://api.github.com/repos/dtolnay/path-to-error` (2026-09-17):
`stargazers_count` **426**, `archived` **false**, `pushed_at` **2026-06-24T03:04:53Z**.
`GET https://api.github.com/search/issues?q=repo:dtolnay/path-to-error+is:issue+is:open`
(2026-09-17): `total_count` **5**.
Issue responsiveness — the repository has only **4** issues (PRs excluded) in its whole
recent history, so "10 most recently opened" is `inapplicable — fewer than 10 issues
exist`; of those four, #33 (opened 2025-03-31) was answered and closed the same day,
#34 (2025-06-18) answered and closed the same day, #30 (2024-07-25) has 1 comment and is
open, #31 (2024-08-07) has 0 comments and is open. Median days to first maintainer
response across the answered ones: **0**; unanswered: **1 of 4**.
Advisories: `https://rustsec.org/packages/serde_path_to_error.html` returns **HTTP 404**,
i.e. no advisory page exists for the crate — control: `https://rustsec.org/packages/anyhow.html`
returns **200** (anyhow has RUSTSEC-2026-0190 per R67), confirming 404 means "no
advisories filed" rather than "site unreachable" (both retrieved 2026-09-17).
`unsafe` posture: **zero** occurrences of `unsafe` in `src/` of the 0.1.20 tarball
(`grep -rn unsafe serde_path_to_error-0.1.20/src/ | wc -l` → `0`, 2026-09-17).
Default features: `std` (the crate is `no_std`-capable); no async runtime coupling.
Binary-size and compile-time cost: negligible — one small crate, no proc-macro of its
own, no new transitive dependency beyond `serde`, which the template already has.
Maintenance state: **stable-quiet**. The 12-month gap since 0.1.20 is a trigger, not a
verdict; `pushed_at` 2026-06-24 (three months ago) shows live maintenance, the repo is
not archived, there is no advisory, and it builds on current stable (proven by the spike).
Adopters: `axum` (`axum/Cargo.toml:139`, retrieved 2026-09-17) — relevant because it is
the dominant Rust web framework and this template ships a web surface.

#### serde_ignored

##### Landscape
Established-industry-standard bin, in a slot that would otherwise be filled by
`#[serde(deny_unknown_fields)]` — the crate's own documentation names that attribute as
the alternative for projects that want failure instead of a report
(`serde_ignored-0.1.14/src/lib.rs:17`).

##### Principles and implementation
Serves a fourth, forward-compatibility principle that the three ledger rows do not state
but the template needs: a config file written by a newer version of the template must not
brick an older binary. Used exactly as `cargo` uses it — wrap the deserializer, collect
ignored key paths into a set, turn each into a warning
(`rust-lang/cargo` `src/workspace/parser/mod.rs:196-203`, retrieved 2026-09-17).

##### Dominant choice
Yes for the "report unknown keys" slot, by virtue of cargo's adoption and having no
maintained competitor.

##### Qualified shortlist
`serde_ignored` 0.1.14 (recommended); `#[serde(deny_unknown_fields)]` (zero-cost, but
it converts an unknown key into a hard failure and cannot coexist with this crate).

##### Excluded by gate
None. Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`.

##### Up-and-comers
None.

##### Fit for this template
Good, with one honest caveat: **unknown-key policy is arguably R53's** (schema
validation), not this item's — the three F-rows this item owns say nothing about unknown
keys. This member is therefore recommended **contingent on R53 not selecting a
validation mechanism that already decides unknown-key handling**, and it is not one of
this item's load-bearing claims. It also does not see through `#[serde(flatten)]`, which
rule 5 already forbids for an unrelated reason.

##### Recommendation
Adopt at `serde_ignored = "0.1.14"`, contingent on R53 as stated.

##### Ranked runner-up
`#[serde(deny_unknown_fields)]` on the config struct, making an unknown key a hard
`RSLB203`. Rejected as the default because it breaks forward compatibility, but it is
the right answer if the owner prefers strictness over forward compatibility.

##### Tradeoffs
One small dependency (only dependency: `serde`); mutually exclusive with
`deny_unknown_fields`; blind to `flatten`.

##### Parameters
`assumes msrv-policy = stable minus 2 minor versions…` — crate `rust-version = 1.61`.
No `CONFLICT:`.

##### Migration implications
One `[dependencies]` line and a closure in the same loader module as the member above.

##### Validation strategy
Executed spike case C (unknown key reported, load succeeds, siblings survive).

##### Confidence & re-verify trigger
Medium-high on the mechanism, medium on whether this item should own the decision.
Re-verify when R53 resolves.

##### Sources
`GET https://crates.io/api/v1/crates/serde_ignored` (2026-09-17):
`crate.recent_downloads` **11,429,284**; `crate.downloads` **51,134,001**.
`GET https://crates.io/api/v1/crates/serde_ignored/versions` (2026-09-17): newest
non-yanked **0.1.14**, `created_at` **2025-09-14T15:55:10Z**, `rust_version` **1.61**,
`license` **MIT OR Apache-2.0**.
`GET https://api.github.com/repos/dtolnay/serde-ignored` (2026-09-17):
`stargazers_count` **106**, `archived` **false**, `pushed_at` **2026-06-24T03:05:30Z**.
`GET https://api.github.com/search/issues?q=repo:dtolnay/serde-ignored+is:issue+is:open`
(2026-09-17): `total_count` **6**.
Issue responsiveness: only **4** issues (PRs excluded) appear in the most recent page,
so the 10-issue window is `inapplicable — fewer than 10 issues exist`. #14 (2022-02-15)
was answered and closed within 2 days; #17 (2022-10-23), #15 (2022-02-17) and #13
(2021-08-15) are open with 2, 1 and 2 comments respectively — i.e. **answered but not
closed**. Median days to first maintainer response: **≤2** on the evidence available;
unanswered: **0 of 4**. Comment authorship was not individually attributed to the
maintainer, so treat the median as approximate.
Advisories: `https://rustsec.org/packages/serde_ignored.html` → **HTTP 404**, no
advisories (same control as above, 2026-09-17).
`unsafe` posture: **zero** occurrences in `src/` of the 0.1.14 tarball (2026-09-17).
Default features: `std`; no async coupling. Compile-time and binary-size cost:
negligible, one small crate, no new transitive dependency.
Maintenance state: **stable-quiet** — same reasoning as the member above, and cargo
tracks its releases (`rust-lang/cargo` `Cargo.toml:103` pins exactly `0.1.14`).
Adopters: `cargo` (`rust-lang/cargo` `Cargo.toml:103`, use at
`src/workspace/parser/mod.rs:198`, retrieved 2026-09-17) — the most relevant possible
reference for TOML configuration handling in Rust.

#### thiserror (reused from R67, not re-selected)

##### Landscape
Built-in-adjacent: the de-facto standard derive for library error types, already fixed
for this template by R67's Layering clause. It appears here only because a bundle member
list must show the crate that carries this item's tolerated-vs-fatal distinction; **R67
owns the selection and this item does not re-open it**.

##### Principles and implementation
Serves P4 and the LOW question: the fatal branches return a typed
`ConfigError` enum whose variants map 1:1 onto R67 codes
(`Unreadable → RSLB104`, `Unparsable → RSLB202`, `InvalidValue → RSLB203`), while the
tolerated outcomes are **not errors at all** — they are `ConfigWarning` values in the
success arm. That is the same absence-vs-failure split R03 establishes for the I/O seam.
**R03 is `open` in `research/CLAUDE.md` as of 2026-09-17, so this item states the
constraint and does not assume R03's answer**: whatever shape R03 lands, this loader
should reuse it rather than invent a parallel one, and the only requirement this item
imposes is that "tolerated" must be representable in the `Ok` arm.

##### Dominant choice
Yes (settled by R67).

##### Qualified shortlist
`thiserror` 2.0.20 (R67's selection). Not re-shortlisted here.

##### Excluded by gate
None. Gate 1 `inapplicable — owner ruling 2026-09-12 (Q7.B)`.

##### Up-and-comers
Not surveyed — out of this item's scope by R67 ownership.

##### Fit for this template
Already established by R67 for the library crate; this item adds no new requirement
beyond three variants and their code mapping.

##### Recommendation
Reuse at the version R67 fixed; add no second error-derive crate.

##### Ranked runner-up
`inapplicable — R67 owns the selection`.

##### Tradeoffs
`inapplicable — R67 owns the selection`. The tradeoff this item does own is that
`ConfigWarning` is a plain struct, not an error type, so it cannot be `?`-propagated by
accident.

##### Parameters
`assumes error-taxonomy-exit-codes = error-contract/v1` (R67). No `CONFLICT:`.

##### Migration implications
Three new variants on the config error enum and three arms in the `ErrorCode` mapping.

##### Validation strategy
Executed spike case E demonstrates the two fatal codes are distinguishable at the point
of failure; in the template, a test asserting each fault's `ErrorCode` and exit status.

##### Confidence & re-verify trigger
High. Re-verify only if R67 is revised.

##### Sources
`GET https://crates.io/api/v1/crates/thiserror` (2026-09-17): `crate.recent_downloads`
**361,877,868**; `crate.downloads` **1,469,796,188**.
`GET https://crates.io/api/v1/crates/thiserror/versions` (2026-09-17): newest non-yanked
**2.0.20**, `created_at` **2026-08-08T06:22:23Z**, `rust_version` **1.71**, `license`
**MIT OR Apache-2.0** — the same version R67 recorded on 2026-09-09, so no drift.
`GET https://api.github.com/repos/dtolnay/thiserror` (2026-09-17): `stargazers_count`
**5,544**, `archived` **false**, `pushed_at` **2026-09-05T05:32:25Z**.
`GET https://api.github.com/search/issues?q=repo:dtolnay/thiserror+is:issue+is:open`
(2026-09-17): `total_count` **27**.
Issue responsiveness: of the most recent issues (PRs excluded) #455 (2026-08-17) and
#452 (2026-06-29) are open with 0 comments; #447 (2026-02-19) was answered and closed
within 1 day; #446 (2026-02-17) is open with 1 comment. Median days to first response on
the answered ones: **≤1**; unanswered: **2** of the 4 examined. The 10-issue window was
truncated by the PR filter, so this is a partial sample — stated rather than rounded up.
Advisories: `https://rustsec.org/packages/thiserror.html` → **HTTP 404**, no advisories
(2026-09-17).
`unsafe` posture: not re-audited here — R67 covers it.
Maintenance state: **active** (release six weeks ago, push twelve days ago).
Adopters: ubiquitous; R67 records the relevant ones.

### Compatibility

The three members are proven to work together, twice over.

1. **Executed together.** The spike package resolved and ran all three composition
   layers in one binary on `cargo 1.98.0` / `rustc 1.98.0`, edition 2024, macOS arm64:
   `serde 1.0.229` + `toml 1.1.6+spec-1.1.0` + `serde_path_to_error 0.1.20` +
   `serde_ignored 0.1.14`, with `serde_ignored::deserialize` wrapping
   `serde_path_to_error::Deserializer` wrapping `toml::Value`'s `IntoDeserializer`. The
   full `Cargo.lock` for that run contains **no** crate outside those plus their shared
   transitive set (`serde_core`, `serde_derive`, `syn`, `quote`, `proc-macro2`,
   `indexmap`, `hashbrown`, `equivalent`, `itoa`, `winnow`, `toml_*`,
   `unicode-ident`) — i.e. the two new members add **zero** transitive dependencies
   beyond what `serde` already brings.
2. **Shared adopter.** `cargo` depends on `serde_ignored 0.1.14` and `toml 1.1.5` in the
   same manifest (`rust-lang/cargo` `Cargo.toml:103,115-116`, retrieved 2026-09-17), and
   `axum 0.8.9` depends on `serde_path_to_error 0.1.8`+ (`axum/Cargo.toml:139`). Both are
   in the same `serde`-derived-deserialization ecosystem and both are transitively
   depended on by this template's own likely stack. All three members are maintained by
   the same author as `serde_derive`, `thiserror` and `anyhow`, which is why their MSRV
   and release cadence move together.
3. **Version matrix.** `rust-version` floors: `serde_path_to_error` 1.61,
   `serde_ignored` 1.61, `thiserror` 1.71. The binding floor is therefore **1.71**, far
   below `stable minus 2 minor versions` at any plausible 2026 stable.

### Parameters

- `owns` — **none**. R55's `owns:` field in `## Couplings` is empty; this item publishes
  no repo-wide parameter.
- `assumes error-taxonomy-exit-codes = error-contract/v1` (R67, owner-accepted). This
  item routes to four existing rows and invents none: `RSLB104` (config layer unreadable
  → 1), `RSLB202` (config document unparsable → 2), `RSLB203` (config value invalid → 2),
  and `RSLB201` (usage/parse → 2) only if the owner rejects the tolerant answer to (a).
- `assumes rust-edition = 2024` (fixed). Verified: the spike is an edition-2024 package.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release,
  declared as rust-version in Cargo.toml and tested in CI` (fixed). Binding member floor
  is 1.71.
- `assumes license = MIT OR Apache-2.0` (fixed). Gate 1 recorded as
  `inapplicable — owner ruling 2026-09-12 (Q7.B)`; nothing was excluded on licence.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed). All three members are
  pure-Rust, platform-agnostic, `no_std`-categorized; the spike ran on macOS arm64.
- **No `CONFLICT:` lines.** R67's catalogue expresses every failure this design produces,
  including the strict alternative to (a).
- Constraints this item places on other items, stated as constraints rather than
  assumptions: **R52** must expose an untyped intermediate that implements
  `serde::Deserializer` (`toml::Value` does, via `IntoDeserializer` — verified;
  `toml_edit::DocumentMut` is expected to through `toml_edit::de`, **not verified here** —
  cargo depends on `toml_edit = { version = "0.25.10", features = ["serde"] }`
  (`Cargo.toml:116`), which makes it plausible, not proven; cargo's own untyped
  intermediate is `toml::de::DeTable`).
  **R53** must validate through `serde::Deserialize` for the prune loop to localize
  failures, and owns unknown-key policy. **R54** must tag each layer it discovers with
  provenance (`Explicit` vs `Discovered`) — the tolerance rule is a function of that tag,
  not of the tier count. **R58** must accept a `Vec<ConfigWarning>` rendered by the
  binary after logging is initialized; the library must not log at the point of
  degradation, because config loading precedes logger setup.

### Migration implications

File-level changes in the template (which does not exist yet; this is P03's work list):

- `crates/<lib>/src/config/source.rs` — new: `ConfigSource` enum with `Explicit { path,
  origin }` / `Discovered { path, tier }`, plus `fn is_strict(&self) -> bool`.
- `crates/<lib>/src/config/load.rs` — new: per-layer read that maps
  `ErrorKind::NotFound` to an empty layer plus a warning for explicit sources, to a
  silent-but-warned skip for discovered ones, and every other `io::Error` to
  `ConfigError::Unreadable` (`RSLB104`) for explicit sources.
- `crates/<lib>/src/config/tolerant.rs` — new: the bounded prune-and-retry pass
  (`try_typed` + `prune` + leaf-count bound), roughly 60 lines. It returns the **sanitized
  untyped document** plus warnings, not a typed value.
- `crates/<lib>/src/config/merge.rs` — new: merge the sanitized untyped documents in
  R54's precedence order, then run the single typed pass that produces `Config`.
- `crates/<lib>/src/config/warning.rs` — new: `ConfigWarning { source, key, kind }` and
  its `Display`.
- `crates/<lib>/src/config/mod.rs` — the loader signature becomes
  `Result<(Config, Vec<ConfigWarning>), ConfigError>`.
- `crates/<lib>/src/error.rs` — three variants and their `ErrorCode` arms (R67).
- `crates/<lib>/Cargo.toml` — two new dependency lines.
- The config struct definition (wherever R53 places it) — `#[serde(default)]` on every
  table, and **no `#[serde(flatten)]`**.
- The CLI binary's startup path — render the returned warnings once, after the logger
  exists; `config set` / `config path` must not require a successful typed load.
- Tests — one case per spike scenario A–E, G, H.

### Validation strategy

**Executed (results above, 2026-09-17):**

```
cd <scratchpad>/spike && cargo run --quiet
```

with the dependency set `serde 1`, `toml 1`, `serde_path_to_error 0.1.20`,
`serde_ignored 0.1.14` on `cargo 1.98.0`. Every assertion passed; the run printed
`ALL ASSERTIONS PASSED`. What it proves: the three-layer deserializer composition
compiles on stable edition 2024; per-key drop preserves siblings across tables;
a bounded loop handles multiple bad keys; unknown keys are reported without failing;
an unparsable discovered layer degrades; the explicit path produces distinguishable
`RSLB202`/`RSLB203` failures; a mis-shaped table degrades to a table drop; and
`#[serde(flatten)]` defeats path-based pruning.

**Proposed for P03 (not run — no template exists):**

- `cargo test -p <lib> config::tolerant` — unit tests mirroring cases A–E, G.
- A test asserting the exact `ErrorCode` for each fatal branch, and asserting that no
  tolerated branch returns `Err`.
- A CLI-level test asserting exit status: `--config <missing>` exits **0** and prints one
  warning to stderr with stdout untouched; `--config <corrupt>` exits **2** with an
  `RSLB202` envelope on stderr and byte-empty stdout (R67's envelope clause); a corrupt
  *discovered* layer exits **0**. The harness for this is R32's choice, so the assertion
  is specified and the tool is not.
- A multi-layer test that is **not covered by the spike, which is single-layer**: a
  user layer with a valid `output.format` under a project layer with an invalid one must
  yield the user layer's value plus one warning — the assertion that distinguishes
  sanitize-then-merge from py's merge-then-drop.
- A test asserting the loader emits no output itself (R67 Layering): capture the
  library's streams and assert they are empty.
- A test that the warning text names both the file and the key path, so P3 is observable.

### Confidence & re-verify trigger

**High** on the mechanism claims for (b) and (c): they were executed, not reasoned about,
and the two failure modes the design must handle (non-leaf paths, `flatten`) were
measured rather than assumed. **High** on (c)'s policy for discovered layers — py's
precedent, starship's independent instance and cargo's unknown-key handling all agree.
**Medium-high** on (a): practice is genuinely split (ripgrep tolerant, cargo strict for
a flag-specific reason), py's own stated rationale does not survive scrutiny in Rust, and
the recommendation rests on the narrower env-supplied-path argument plus P3's requirement
that the degradation be visible — this is the one place an owner could reasonably decide
the other way, at a cost of one branch and one catalogue row (`RSLB201`).
**Medium** on whether `serde_ignored` belongs to this item at all rather than to R53.

Re-verify when: R53 publishes (unknown-key policy and whether validation runs through
`serde::Deserialize`); R54 publishes (whether a discovered tier exists at all — if it
does not, question (b) and half of rule 3 become moot and F236 has no target); R52
publishes (if the selected intermediate is not a `serde::Deserializer`, the prune loop
must be re-designed); R58 publishes (the warning rendering point); or if
`serde_path_to_error` goes 18 months without a release *and* accrues an unanswered
breakage report on current stable.

### Sources

Pinned source repositories, read through their pins as the role file requires:
- py at `b08bccfb`: `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/config.py`
  — `_read_toml` (missing/invalid read as empty), `_read_layer:96-103` (discovered layer
  returns `({}, "ignoring unreadable config file …")`), `_read_explicit:106-121` (missing
  path → `{}` **with no warning**, lines 114-115; `TOMLDecodeError` → `ConfigError`,
  118-119; `OSError` → `ConfigError`, 120-121), `_discovery_paths:124-139` (`--config` collapses discovery to one file).
  `…:src/py_launch_blueprint/core/settings.py:138-176` — `settings_from_layers` merges,
  validates, and on `ValidationError` pops each offending `section.key`, appends
  `ignoring invalid config value …`, revalidates, and falls back to `Settings()` on a
  double fault. Retrieved 2026-09-17.
- ts at `cb1cbcb2`: `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/config.ts`
  — `readConfigFile:102-130` (read failure → `ConfigError`, lines 109-115; `parse` failure
  → `ConfigError`, 117-123; `configFileSchema.safeParse` failure → `ConfigError` for the
  whole file with every issue joined into one message, 124-130), `resolveConfig:147-160`
  (`!fs.existsSync(options.configPathFlag)` → `UsageError`, with the
  `click.Path(exists=True) parity` comment). Retrieved 2026-09-17.
- Ledger and analysis: `docs/port/COMMONALITY.md:239-242` (F235–F238),
  `docs/port/areas/config-env-logging.md:18-21`,
  `docs/port/DIVERGENCE-ANALYSIS.md:188-190,297`,
  `research/topics/67-error-and-exit-code-contract/DECISION.md:255-277,383,587-594`,
  `docs/port/PARAMETERS.md`. Retrieved 2026-09-17.

Registry and API endpoints (all retrieved 2026-09-17; figures are in each member's
`Sources` field): `GET https://crates.io/api/v1/crates/{serde_path_to_error,serde_ignored,thiserror,figment,config}`,
`GET https://crates.io/api/v1/crates/{serde_path_to_error,serde_ignored,thiserror}/versions`,
`GET https://api.github.com/repos/{dtolnay/path-to-error,dtolnay/serde-ignored,dtolnay/thiserror,SergioBenitez/Figment,rust-cli/config-rs,starship/starship}`,
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`,
`GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=10`,
`https://rustsec.org/packages/<name>.html`,
`https://static.crates.io/crates/<name>/<name>-<version>.crate`.

Landscape figures not repeated elsewhere (context for the two rejected frameworks, all
`GET https://crates.io/api/v1/crates/<name>` + `https://api.github.com/repos/<o>/<r>`,
retrieved 2026-09-17): `figment` — `recent_downloads` **9,802,644**, `downloads`
**38,331,318**, `max_stable_version` **0.10.19**, repo `SergioBenitez/Figment`
**913** stars, `archived` **false**, `pushed_at` **2024-09-13T04:51:49Z** (a two-year
push gap: a maintenance **trigger**, and the reason figment is a runner-up architecture
rather than a member — it was not investigated to a verdict because the design does not
select it). `config` — `recent_downloads` **18,162,896**, `downloads` **113,748,521**,
`max_stable_version` **0.15.25**, repo `rust-cli/config-rs` **3,210** stars,
`archived` **false**, `pushed_at` **2026-09-15T17:13:57Z** (**active**).

Practice-evidence files (retrieved 2026-09-17 via `gh api repos/<o>/<r>/contents/<path>`):
`BurntSushi/ripgrep` `crates/core/flags/config.rs` and `crates/core/messages.rs` at
`master` = `3fce3b5bb0236da2df6d99672afb8a719642eca7`; `rust-lang/cargo`
`src/workspace/parser/mod.rs`, `src/context/mod.rs`, `Cargo.toml`; `tokio-rs/axum`
`axum/Cargo.toml`; `starship/starship` `src/config.rs`.

**Method notes.** Figures came from `https://crates.io/api/v1/crates/<name>` and
`/versions` (curl with a `User-Agent` header), `https://api.github.com/repos/<o>/<r>`,
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (never
`open_issues_count`), `https://api.github.com/repos/<o>/<r>/issues?...` for
responsiveness, `https://rustsec.org/packages/<name>.html` for advisories, and
`https://static.crates.io/crates/...` tarballs for licence, MSRV, `unsafe` posture and
API shape. GitHub calls went through the machine-authenticated `gh api`; no token was
printed. Source files in both source repositories were read through their pins
(`b08bccfb`, `cb1cbcb2`), never from the working tree.

*What could not be verified.* (i) **Issue responsiveness medians are approximate for all
three members**: `dtolnay/path-to-error` and `dtolnay/serde-ignored` have fewer than ten
issues in total (4 each on the page retrieved), so the rubric's "10 most recently opened"
window is `inapplicable — fewer than 10 issues exist`; for `thiserror` the ten-item page
was reduced to four items by excluding pull requests, so that sample is partial. Comment
authors were not individually checked against the maintainer's login, so "first
maintainer response" is inferred from the presence of a comment. (ii) **RustSec 404s are
interpreted, not asserted**: `rustsec.org` returns 404 for crates with no advisory page;
this was controlled against `anyhow` (200, known advisory) and `serde` (404) on the same
day, but no advisory-db clone was searched. (iii) **No performance measurement** was
taken for the prune-and-retry loop; only a qualitative cost is stated. (iv) **The strict
alternative for (a)** (`RSLB201` at exit 2) was not exercised in the spike; only the
recommended tolerant branch and the two strict *parse/value* branches were. (v) **The
`figment` architecture was not prototyped**; its lack of drop-and-continue is read from
its documented `Error` semantics, not measured. (vi) **`alacritty`'s
`alacritty_config_derive`** is named in the landscape from general knowledge as an
instance of the per-field-derive shape; no file was retrieved for it, so it carries no
`file:line` citation and no claim in this report rests on it. (vii) The spike ran on
macOS arm64 only; `ubuntu-latest` was not exercised, though nothing in the three members
is platform-specific. (viii) **The multi-layer composition was not executed**: the spike
validates one layer, so `sanitize → merge → type once`, and the claim that it beats py's
merge-then-drop when two layers set the same key, are designed and argued but not run.
(ix) Whether `toml_edit::DocumentMut` implements `serde::Deserializer` through
`toml_edit::de` was **not** checked; only `toml::Value` was verified, and R52 owns that
choice anyway.
