# R53 — config-schema-validation (crate) — raw report, Opus engine

Engine identity `research-opus-2026-09-17T020714Z-d0b567b4b9f1`, model `claude-opus-5`.
Item kind `crate`, effort tier `focused`. Written 2026-09-17 (UTC).

**Retrieval date convention.** Every figure and quotation below was retrieved on
**2026-09-17 (UTC)** unless the line states otherwise. The harness reports the local
date as 2026-09-16; all endpoint calls in this run were made after 04:02 UTC on
2026-09-17, so the UTC date is used throughout and is the one to re-verify against.

**Nothing here was built.** No Rust code exists in this repository and none was
written, compiled or run. Every "expected output" below is a **planned** check for
P03, explicitly labelled; nothing in `### Validation strategy` was executed.

**Toolchain baseline used for gate 2.** Current Rust stable is **1.98.1 (48a229cea,
released 2026-09-01)**, from `[pkg.rust] version` in
`https://static.rust-lang.org/dist/channel-rust-stable.toml` (retrieved 2026-09-17).
The fixed `msrv-policy` ("stable minus 2 minor versions") therefore puts the floor at
**1.96**, which matches the illustrative `rust-version = "1.96"` already recorded in
`research/topics/06-unsafe-code-policy/DECISION.md`. Edition 2024 independently needs
1.85 or newer.

### Landscape

**The category this item decides.** *Post-parse schema validation for a
user-editable configuration document*: given bytes that a TOML parser has accepted as
well-formed, decide (a) whether each key's value is one the program will accept, and
(b) what shape the rejection report takes. It is the Rust seat of py's `pydantic` and
ts's `zod`. It is **not** the parser (R52), **not** the per-key failure-tolerance
policy (R55), and **not** the question of whether a `token` key exists (R56).

**Three-bin map of the Rust field.**

| Bin | Members found | What each offers here |
|---|---|---|
| **Built-in / first-party toolchain** | `serde` derive (`Deserialize`); fieldless `enum`s as the analogue of py `Literal` / zod `z.enum`; `std::num::NonZeroU32` and the sized integer types; `#[serde(try_from = "Raw")]` and `#[serde(deserialize_with = …)]` newtypes; `#[serde(deny_unknown_fields)]`; `#[serde(default)]` | Per-field type and domain rejection generated at compile time, with no crate beyond `serde` itself |
| **Established industry standard** | `validator` (Keats), `serde` itself, `serde_path_to_error` (dtolnay) | `validator` is the long-standing derive-based validation crate; `serde_path_to_error` names the key an error occurred at |
| **Up-and-comer** | `garde` (an explicit full rewrite of `validator`), `serde_valid` (JSON-Schema-shaped), `nutype` (validated newtype generator), `validify` (validator fork with modification), `toml-span` (Embark; span-carrying TOML with multi-error deserialization) | Newer aggregation and type-state models; `toml-span` sits at the parse layer and so straddles this item and R52 |

`serde` is placed in the first bin deliberately. It is not a Rust-project crate, but
it is the de-facto toolchain layer every candidate in the other two bins is built on
top of: `validator`, `serde_valid` and `nutype` all list `serde` as a dependency, and
`garde` offers it as a feature
(`https://crates.io/api/v1/crates/<name>/<version>/dependencies`, retrieved
2026-09-17).

**Ruled out of the map in one line each, as out-of-scope neighbours.** `figment`,
`config`, `confique`, `confy` and `schematic` are *configuration loaders* — they
merge layers and discover files, which is R52/R54 territory, and each still delegates
the actual schema to `serde` derive. `schemars` generates JSON Schema from Rust types;
it is a documentation/export concern, not a runtime gate, and it appears here only
because it depends optionally on both `garde` and `validator`
(`https://crates.io/api/v1/crates/garde/reverse_dependencies`, retrieved 2026-09-17).

**Authoritative sources drawn on, and why each counts.**

1. **serde's own reference, `https://serde.rs/container-attrs.html`** (retrieved
   2026-09-17) — maintainers' documentation for the crate that defines the
   deserialization contract every candidate builds on. Used for the exact semantics of
   `deny_unknown_fields`, `try_from`, `default`.
2. **serde's source at the published tag `v1.0.229`** (`gh api
   repos/serde-rs/serde/contents/serde_core/src/de/impls.rs?ref=v1.0.229`, retrieved
   2026-09-17) — primary evidence, not documentation, for what `NonZeroU32` rejects.
3. **`serde-rs/serde` pull request #2891**, "Support `#[serde(validate = "function")]`
   for container, compatible with `validator` crate" (`gh api
   repos/serde-rs/serde/pulls/2891`, retrieved 2026-09-17) — authoritative because it
   is the project's own open decision record on whether serde should own validation.
   Opened 2025-02-11 by `zao111222333`, **still open and unmerged** 19 months later;
   the only maintainer comment is `oli-obk` (`author_association: MEMBER`,
   2025-02-12). It establishes that serde deliberately has no validation hook and that
   the supported composition today is "derive `Deserialize`, then call a separate
   validator".
4. **docs.rs API pages for `toml` 1.1.6, `garde` 0.23.0, `validator` 0.21.0,
   `serde_valid` 3.1.2, `toml-span` 0.7.1** (retrieved 2026-09-17) — maintainers'
   generated reference; used for exact type signatures, which are the load-bearing
   facts in this item.
5. **The Rust CLI working group book, "Using config files"**
   (`https://rust-cli.github.io/book/in-depth/config-files.html`, retrieved
   2026-09-17) — working-group output, and cited here for an **evidence gap**: the
   chapter recommends `confy` for the simple case and its "Configuration
   environments" section is literally three `TODO` bullets ("Evaluate crates that
   exist", "Cli-args + multiple configs + env variables", "Can configure do all
   this?"). The Rust CLI WG publishes **no** guidance on config schema validation.
   Nothing in this report rests on it.
6. **The 2025 State of Rust Survey**
   (`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`,
   found by web search on 2026-09-17) — the annual Rust survey, published 2026-03-02,
   7156 responses. **I did not open the linked full report and so cite no crate-usage
   figure from it.** Recorded as consulted-and-not-used rather than silently omitted.

**Well-regarded Rust projects surveyed, with the evidence that they are well
regarded.** Each project's `Cargo.toml` was read at a named commit via
`gh api repos/<o>/<r>/contents/Cargo.toml?ref=<sha>` and filtered with `grep`; star
counts are `stargazers_count` from `gh api repos/<o>/<r>` (all retrieved
2026-09-17).

| Project | Stars | `pushed_at` | Commit read | Validation-relevant dependencies |
|---|---|---|---|---|
| `alacritty/alacritty` | 65,740 | 2026-08-31 | `d692748d3f61253ebe9f5094320120d22f6a046f` | `toml = "0.9.11"`; no validation crate |
| `starship/starship` | 59,920 | 2026-09-17 | `4ff40d066af2dd316dcb4742544254436e7e8190` | `serde = { version = "1.0.229", features = ["derive"] }`, `toml = { version = "1.1.6", features = ["preserve_order"] }`, optional `schemars`; no validation crate |
| `helix-editor/helix` | 46,250 | 2026-09-15 | `079a789e8cb08ead67f19e1971a1b7438b37354b` | `toml = "1.1"`, `thiserror = "2.0"`; no validation crate |
| `zellij-org/zellij` | 35,434 | 2026-09-14 | `474ea0cef620c83d6ec05a7c28c7f80c4f63bbbb` | `serde` 1.0, `thiserror` 2.0.18, `anyhow` 1.0.70; no validation crate |
| `jj-vcs/jj` | 31,623 | 2026-09-17 | `e6dd2c0d60f22ef8d21d171b5fb8e4178f0af1d9` | `serde` 1.0, `toml = "1.1.0"`, `thiserror = "2.0.17"`; no validation crate |
| `rust-lang/mdBook` | 22,148 | 2026-09-15 | `afe6eb8836bf49bf6e23d15ccf1b87d8a5395ca4` | `serde = "1.0.229"`, `toml = "1.1.4"`, `anyhow = "1.0.104"`; no validation crate |
| `EmbarkStudios/cargo-deny` | 2,426 | 2026-09-03 | `79d7f54dc1bfd8cc8105fac917d3dcc7675eb026` | `serde = { version = "1.0", features = ["derive"] }`, **`toml-span = { version = "0.7", features = ["reporting"] }`**; no validation crate |

Why these are relevant references rather than merely popular: all seven are Rust
**CLI or CLI-adjacent** programs that read a user-editable TOML configuration file and
must report a bad value back to a human — this item's exact use case. `rust-lang/mdBook`
is a Rust-project-owned tool. `cargo-deny` is the closest analogue of all: a
Rust CLI whose entire job is reading a `deny.toml` and emitting diagnostics about it.

**The single most important practice finding: seven out of seven use `serde` derive
with a TOML crate, and zero use `validator`, `garde`, `serde_valid`, `nutype` or
`validify`** (counted with `grep` over each `Cargo.toml` at the commit named above,
2026-09-17). Where a project needs more than fail-fast type rejection, it writes the
validation pass itself — `cargo-deny` declares its own
`pub trait UnvalidatedConfig { type ValidCfg; fn validate(self, ctx: ValidationContext<'_>) -> Self::ValidCfg; }`
and a `ValidationContext` holding `diagnostics: &'ctx mut Vec<diag::Diagnostic>`
(`gh api repos/EmbarkStudios/cargo-deny/contents/src/cfg.rs?ref=79d7f54d…`, lines
6–52, retrieved 2026-09-17).

The counter-evidence is equally clear about where validation crates *do* live. The top
reverse dependencies of `garde` are `garde-actix-web`, `axum-valid`, `apistos-gen` and
`schemars`; of `serde_valid` they are `axum_serde_valid`, `argentum_rest_infrastructure`
and `swagger` (`https://crates.io/api/v1/crates/<name>/reverse_dependencies`, retrieved
2026-09-17). These crates are predominantly **HTTP request-body validators**, not CLI
config validators — which matters directly for `### Fit for this template`, because
this template has a web surface too.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**
A configuration file is untrusted input authored by hand. The requirement is:
*no value read from that file reaches program logic until it has been checked against
a declared schema, and a value the schema rejects produces a report that names the
offending key.* The agreement level is an **architectural pattern plus an observable
standard**, not a library: F229 (`docs/port/COMMONALITY.md:233`, `COMMON → REUSE`)
records the pattern, and its 2026-09-04 baseline review
(`docs/port/BASELINE-REVIEW.md:106`, finding at `:279`) supplies the acceptance
criterion — "validation-before-use with constrained types or explicit checks, and
representative rejected values" — precisely because typed deserialization alone
accepts values the sources reject. F228 (`:232`, `DIVERGENT`) is the library seat and
is what this item fills.

**What must agree, and what may vary.**

| Must agree (behaviour observable from outside) | May vary (mechanism) |
|---|---|
| A value outside a key's allowed set is rejected, not silently coerced | Whether the check is a type, a derive attribute or a hand-written predicate |
| The report names the offending key by its dotted path | Whether the path comes from a validator, a parser span, or a hand-built string |
| Every invalid key in the document is reported, not only the first (see the `BASELINE-REVIEW:` line below) | Whether aggregation happens in the parser, a validation crate, or a per-key loop |
| No value is used before the check runs | Whether that is enforced by discipline, by a type-state, or by call order |

**The essential behaviours, taken from the sources at their pins.**

- py `src/py_launch_blueprint/core/settings.py:40-46,49-57` (`git -C ~/c/py-launch-blueprint
  show b08bccfb:…`) declares `class OutputSettings(BaseModel)` with
  `format: Literal["text", "json", "markdown"] = "text"` and
  `color: Literal["auto", "always", "never"] = "auto"`, and every model sets
  `model_config = {"extra": "ignore"}` — **unknown keys are tolerated**.
- py `:138-176` `settings_from_layers` catches one `ValidationError` and iterates
  `exc.errors()`, popping each offending `(section, key)` and appending
  `f"ignoring invalid config value {section}.{key} = {bad!r}"`. Its docstring states
  the reason: "config must never brick the CLI — the user needs `config set`/`config
  path` working in order to repair the file." **This loop is only possible because
  pydantic returns every field error at once.**
- ts `src/lib/config.ts:33-41` (`git -C ~/c/ts-launch-blueprint show cb1cbcb2:…`)
  declares `configFileSchema = z.object({ token: z.string().optional(), workspace:
  z.string().optional(), limit: z.number().int().positive().optional() })`; `z.object`
  strips unknown keys by default, so ts also **tolerates unknown keys**.
- ts `:124-130` calls `configFileSchema.safeParse(parsed)` and, on failure, joins
  **all** issues: `result.error.issues.map((issue) => \`${issue.path.join('.') ||
  '(root)'}: ${issue.message}\`).join('; ')`, then throws one `ConfigError`.

So both sources aggregate; they differ only in what they do with the aggregate (py
drops per key and continues, ts fails the file). That difference is R55's, not this
item's — but **both policies require the aggregate to exist**, and py's is
unimplementable without it.

**Architectural alternatives, compared before any library.**

*Alternative 1 — parse-don't-validate (types carry the invariants).* Express each
constraint in the field's type: a fieldless `enum` for py's `Literal`s,
`NonZeroU32` for ts's `.positive()`, and `#[serde(try_from = "String")]` newtypes for
anything else. serde then rejects at deserialization and no separate validation step
exists. Verified mechanics: for an enum, `serde::de::Error::unknown_variant(variant:
&str, expected: &'static [&'static str])` produces "unknown variant `yaml`, expected
one of …" — which is py's `_allowed_hint` "(allowed: …)" string for free
(`https://docs.rs/toml/latest/toml/de/struct.Error.html`, trait impl listing, retrieved
2026-09-17). For `NonZeroU32`, serde at tag `v1.0.229`
(`serde_core/src/de/impls.rs:90-103`, with the nonzero visit arms at `:165-176` and
`:256-267`) defines `NonZeroVisitor` whose `expecting` writes
`concat!("a nonzero ", stringify!($primitive))` and whose visit arm
rejects a zero with `Error::invalid_value(…, &self)`. Two sibling macro arms exist and
TOML decides which fires: a TOML integer arrives as `i64`, so the `int_to_uint` arm at
`:256-267` is the one that runs — `if let Ok(v) = u32::try_from(v as i64) { if let
Some(nonzero) = Self::Value::new(v) { return Ok(nonzero); } } Err(Error::invalid_value(
Unexpected::Signed(v as i64), &self))` — while the unsigned arm at `:165-176` uses
`Unexpected::Unsigned(0)`. Both render as "integer `0`", so `limit = 0` yields
`invalid value: integer 0, expected a nonzero u32` either way. **Cost: strictly fail-fast.**

*Alternative 2 — deserialize permissively, then validate (the pydantic/zod shape).*
Derive `Deserialize` for a loose struct, then run a rule set over it. This is what
`validator`, `garde`, `serde_valid` and `validify` do. **The decisive limitation, which
I have not seen stated in any comparison and which changes the answer: a
post-deserialization validator cannot aggregate *type* errors, only *constraint*
errors.** `serde`'s derived `Deserialize` early-returns on the first field that fails
to deserialize, because `serde::de::Error` is a single value — every constructor
(`custom`, `invalid_type`, `invalid_value`, `unknown_variant`, `unknown_field`)
returns `Self`, one error, and the generated code propagates it with `?`. Corroborating
maintainers' evidence: `serde_path_to_error`'s own type is documented as "Original
deserializer error together with **the** path at which it occurred", singular
(`https://docs.rs/serde_path_to_error/latest/serde_path_to_error/`, retrieved
2026-09-17). So for a file containing both `format = "yaml"` and `limit = "abc"`,
`garde`/`validator` never run: serde fails first and reports one error. zod's
`safeParse` reports both. **No serde-layered validation crate reproduces zod's
aggregate shape.**

*Alternative 3 — aggregate at the parse layer.* `toml-span` 0.7.1 exposes
`pub struct DeserError { pub errors: Vec<Error> }`, documented as "When deserializing,
it's possible to collect multiple errors instead of earlying out at the first error",
and `TableHelper { pub table: Table<'de>, pub errors: Vec<Error>, … }` whose `required`
method states "Errors that occur when calling this method are automatically added to
the set of errors that are reported from `Self::finalize`"
(`https://docs.rs/toml-span/latest/toml_span/struct.DeserError.html` and
`.../de_helpers/struct.TableHelper.html`, retrieved 2026-09-17). This *does* aggregate
type errors, with spans. **But it replaces the parser and serde's derive with
toml-span's own `Deserialize` trait and hand-written impls — which is R52's decision,
not this item's.**

*Alternative 4 — per-key deserialization over an intermediate table.* Parse to
`toml::Table`, then deserialize each known key independently, pushing a
`(path, message)` pair per failure. This aggregates both type and constraint errors,
keeps `serde` derive for the types, and needs no crate beyond what R52 already brings.
It is the shape `cargo-deny` hand-writes and the shape py's `settings_from_layers`
loop produces.

**Two independent constraints force the intermediate table, which answers the prompt's
MEDIUM integration question.**

1. *Aggregation*, per Alternative 2's limitation above.
2. *R67's error catalog.* `error-taxonomy-exit-codes` splits `RSLB202` "config
   document unparsable" from `RSLB203` "config value invalid", both exiting 2. With
   the `toml` crate the two are **indistinguishable from the error value**:
   `toml::de::Error` is `pub struct Error { /* private fields */ }` with exactly three
   inherent methods — `message(&self) -> &str`, `span(&self) -> Option<Range<usize>>`,
   `set_input(&mut self, input: Option<&str>)` — and no kind, variant or discriminant,
   while `impl serde::de::Error for Error` routes every serde-originated type failure
   into that same type (`https://docs.rs/toml/latest/toml/de/struct.Error.html`, toml
   `1.1.6+spec-1.1.0`, retrieved 2026-09-17). String-matching `message()` would be
   fragile. A two-stage parse decides it structurally: `toml::from_str::<toml::Table>`
   failing is a syntax error (`RSLB202`); the same bytes succeeding as a `Table` but
   failing per key is a value error (`RSLB203`).

**How the recommended design preserves each principle.** `serde` derive with
constrained field types supplies *constrained types and representative rejected
values* (F229's criterion) and, for enums, supplies the allowed-values hint text that
py builds by reflection. The per-key loop over `toml::Table` supplies *aggregate
reporting with dotted paths* (both sources' behaviour) and the per-key independence
R55 needs if it chooses py's drop-with-warning. A `Valid<T>` newtype constructible only
through `validate()` supplies *before use* mechanically rather than by convention —
the same type-state `garde` ships as `Unvalidated<T>`/`Valid<T>`
(`pub fn validate(self) -> Result<Valid<T>, Report>`; "This is the only way to create
an instance of `Valid<T>`",
`https://docs.rs/garde/latest/garde/validate/struct.Unvalidated.html`, retrieved
2026-09-17) and `cargo-deny` hand-writes as `UnvalidatedConfig::ValidCfg`.

**Where a different ecosystem needs a different design.** py and ts both have a runtime
type-erasure problem this template does not: a Python `dict` or a JS object carries no
declared field types, so a schema library must re-declare them at runtime, and
re-declaring them is the natural place to also declare `.positive()`. Rust declares
them at compile time, so the constraint layer collapses into the type layer for
everything a type can express. What Rust does *not* get for free is exactly what py
and ts get for free from a runtime schema walk: aggregation. The port therefore moves
work in the opposite direction from the naive mapping — **less** library for
constraints, **more** deliberate structure for reporting.

**Maturity, dependability, performance and integration cost.** Registry and repository
figures are in `### Qualified shortlist`; the discriminating dependency facts, all
from `https://crates.io/api/v1/crates/<name>/<version>/dependencies` retrieved
2026-09-17, are:

- `serde` 1.0.229: one non-optional dependency, `serde_core =1.0.229`, plus optional
  `serde_derive`. Feature map `{"default":["std"], "derive":["serde_derive"], …}`.
- `garde` 0.23.0: two non-optional dependencies, `compact_str ^0.9.0` and
  `smallvec ^1.15.1`, both with `default_features=false`; **no `default` feature key at
  all**, so `features = ["derive"]` pulls only `garde_derive`. `regex`, `url`, `idna`,
  `phonenumber`, `card-validate`, `rust_decimal`, `unicode-segmentation` are every one
  of them optional.
- `validator` 0.21.0: **six non-optional dependencies** — `idna ^1`, `regex ^1`,
  `serde ^1`, `serde_derive ^1`, `serde_json ^1`, `url ^2` — none of which this use
  case needs, and none of which a feature flag can remove.
- `serde_valid` 3.1.2: ten non-optional dependencies including `regex ^1.12`,
  `indexmap ^2.0`, `itertools ^0.14.0`, `num-traits ^0.2`, `serde_json ^1.0`,
  `unicode-segmentation ^1.7` and **`thiserror ^1.0`**. That last one matters: R67 fixes
  `thiserror = "2.0.20"` for the library crate, and `^1.0` is semver-incompatible with
  `^2.0`, so both major versions would be resolved and compiled into the tree.
- `nutype` 0.7.0: one non-optional dependency, `nutype_macros ^0.7.0`.

Performance is not a discriminator and I decline to manufacture one: config validation
runs once per process on a file of tens of lines. No candidate publishes a benchmark
for that workload, I ran none, and comparing library microbenchmarks across unlike
harnesses would violate the prompt's instruction not to infer a fastest option from
unlike benchmarks. The measurable cost here is **compile time and dependency count**,
addressed per candidate under gate 6.

**Minimal realistic example (proposed; not built).** Field names are taken from
resolved sibling decisions so the example is not invented: `output.format` uses R66's
enum `table | json | markdown | name` (`research/topics/66-output-format-surface/
DECISION.md:35-44`), `output.color` uses the `auto | always | never` triple py
declares at `settings.py:46`, and `output.limit` carries ts's `.positive()` constraint
from `config.ts:40`.

```toml
# Cargo.toml — library crate. `toml` appears only to make the example runnable;
# the parser is R52's decision, and this schema sits downstream of whatever it returns.
[dependencies]
serde     = { version = "1.0.229", features = ["derive"] }
toml      = "1.1"
thiserror = "2.0.20"          # R67, library crate only
```

```rust
// crates/rs-launch-blueprint/src/config/schema.rs
use std::num::NonZeroU32;
use std::ops::Range;
use serde::Deserialize;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OutputFormat { #[default] Table, Json, Markdown, Name }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ColorChoice { #[default] Auto, Always, Never }

#[derive(Debug, Clone, Default, Deserialize)]
#[serde(default)]   // missing keys take Default; unknown keys are ignored by serde's
                    // baseline behaviour, since `deny_unknown_fields` is NOT set
pub struct OutputSettings {
    pub format: OutputFormat,
    pub color:  ColorChoice,
    pub limit:  Option<NonZeroU32>,
}

#[derive(Debug, Clone, Default, Deserialize)]
#[serde(default)]
pub struct ConfigFile { pub output: OutputSettings }

/// One rejected key. `path` is the dotted key, matching zod `issue.path.join('.')`
/// and pydantic `err["loc"]`; `span` feeds R67's `hint`.
#[derive(Debug, Clone)]
pub struct Issue { pub path: String, pub message: String, pub span: Option<Range<usize>> }

/// A parsed-but-unchecked document. `Valid` has no other constructor, so no value
/// can be read before validation — F229's "before use", enforced by the type system.
pub struct Unvalidated(toml::Table);
pub struct Valid(ConfigFile);

impl Valid { pub fn get(&self) -> &ConfigFile { &self.0 } }

impl Unvalidated {
    pub fn validate(self) -> Result<Valid, Vec<Issue>> {
        let mut issues = Vec::new();
        let mut cfg = ConfigFile::default();
        if let Some(t) = self.0.get("output").and_then(toml::Value::as_table) {
            if let Some(v) = field(t, "output", "format", &mut issues) { cfg.output.format = v; }
            if let Some(v) = field(t, "output", "color",  &mut issues) { cfg.output.color  = v; }
            if let Some(v) = field(t, "output", "limit",  &mut issues) { cfg.output.limit  = Some(v); }
        }
        if issues.is_empty() { Ok(Valid(cfg)) } else { Err(issues) }
    }
}

// `impl Deserializer for toml::Value` is listed in the toml crate root docs, so each
// key is deserialized on its own and one failure does not abort the others.
fn field<T: serde::de::DeserializeOwned>(
    table: &toml::Table, section: &str, key: &str, issues: &mut Vec<Issue>,
) -> Option<T> {
    let value = table.get(key)?.clone();
    match T::deserialize(value) {
        Ok(v)  => Some(v),
        Err(e) => { issues.push(Issue {
            path: format!("{section}.{key}"), message: e.to_string(), span: None }); None }
    }
}
```

```rust
// The R67 boundary: two stages, because toml::de::Error cannot tell them apart.
pub fn load(raw: &str) -> Result<Valid, ConfigError> {
    let doc: toml::Table = toml::from_str(raw)
        .map_err(|e| ConfigError::Unparsable {                       // RSLB202 -> exit 2
            message: e.message().to_owned(), span: e.span() })?;
    Unvalidated(doc).validate()
        .map_err(ConfigError::InvalidValues)                         // RSLB203 -> exit 2
}
```

**Span caveat, stated rather than glossed.** `toml::Table` is
`toml::map::Map<String, toml::Value>` and carries no source offsets, so the loop above
leaves `Issue::span` as `None`. Two ways to restore it with the `toml` crate, both
P03's to pick: deserialize the intermediate as a map of `toml::Spanned<toml::Value>`
(the `Spanned` struct is exported from the crate root and `serde_spanned` is one of
`toml`'s non-optional dependencies), or re-run `toml::from_str::<ConfigFile>(raw)` once
on the error path and take `e.span()` for the first offender only. This is the one
place where `toml-span`'s design is strictly better, and it is R52's call, not this
item's — recorded under `### Parameters` as a requirement passed to R52.

**Executable acceptance check — proposed, not run.** See `### Validation strategy`.
Nothing was compiled: this repository contains no Rust code, the role forbids writing
anything but this file, and the prompt forbids scaffolding.

**Baseline-review finding.**

BASELINE-REVIEW: F229 — the parsed file is validated against a typed schema before any value is used — add to the acceptance criteria that every invalid key in the document is reported in one pass rather than only the first, because the recorded criterion ("validation-before-use with constrained types or explicit checks, with representative rejected values") is satisfied by a fail-fast mechanism that cannot carry py's per-key drop behaviour — evidence: py `b08bccfb:src/py_launch_blueprint/core/settings.py:158-176` iterates `exc.errors()` and pops each offending `(section, key)` in turn, which requires pydantic to have returned them all; ts `cb1cbcb2:src/lib/config.ts:126-129` maps over every `result.error.issues` entry and joins them into one message; whereas serde's derived `Deserialize` early-returns on the first bad field because `serde::de::Error`'s constructors each return one `Self` value (`https://serde.rs/container-attrs.html` and `serde` `v1.0.229` `serde_core/src/de/impls.rs`, retrieved 2026-09-17), and `serde_path_to_error` documents its own type as "Original deserializer error together with the path at which it occurred", singular (`https://docs.rs/serde_path_to_error/latest/serde_path_to_error/`, retrieved 2026-09-17). Affected items: R53 (this item, mechanism), R55 (F238, per-key failure tolerance — the policy is unimplementable on a fail-fast mechanism), R52 (F225/F226, because with `toml` the aggregation must be built on an intermediate `toml::Table`, while `toml-span` supplies it natively). Affected records: `docs/port/COMMONALITY.md:233`, `docs/port/BASELINE-REVIEW.md:106` and its finding line at `:279`.

### Dominant choice

**`serde` with the `derive` feature, version range `>= 1.0.229, < 2.0.0`** (Cargo:
`serde = { version = "1.0.229", features = ["derive"] }`), carrying the schema in
Rust's own type system — fieldless enums for literal sets, `NonZeroU32` and sized
integers for numeric domains, `#[serde(try_from = "…")]` newtypes for anything a type
cannot express — with **no dedicated validation crate**.

The floor is 1.0.229 for two stated reasons, not by preference: it is the version
`serde` split its core out into `serde_core` (its only non-optional dependency is
`serde_core =1.0.229`), and it is the version sibling decision R66 already names
(`research/topics/66-output-format-surface/DECISION.md:25`). `starship` pins
`1.0.229` and `mdBook` pins `1.0.229` at the commits read above.

Figures (`https://crates.io/api/v1/crates/serde`, `/versions`, and
`gh api repos/serde-rs/serde`, all retrieved 2026-09-17): 90-day downloads
**308,308,063** (`crate.recent_downloads`); all-time **1,402,408,950**
(`crate.downloads`); newest non-yanked version **1.0.229**, `created_at`
**2026-07-18T23:05:13Z**; stars **10,826**; `archived` **false**; `pushed_at`
**2026-08-25T03:53:14Z**; open issues **319** via
`gh api "search/issues?q=repo:serde-rs/serde+is:issue+is:open"` `.total_count`
(not `open_issues_count`, which reads 399 and includes pull requests).

That this item's answer names a crate the template already depends on is the finding,
not an evasion: the role py's `pydantic` and ts's `zod` play is, in Rust, played by
the type system plus `serde`'s derive, and the part neither covers — aggregation — is
**not available from any validation crate either** and must be built at the parse
boundary. F229's own Notes anticipated the shape ("serde's typed deserialization
preserves this same pattern, so this is a substitution in spirit, not an override"),
so no `OVERRIDE (OV-nn)` is opened for it.

### Qualified shortlist

Four candidates passed every applicable gate. Fewer than five is itself a finding: the
Rust validation-crate field is thin, and two of the four are single-maintainer
projects. All figures retrieved 2026-09-17; download figures are
`crate.recent_downloads` / `crate.downloads` from
`https://crates.io/api/v1/crates/<name>`, release dates are the newest non-yanked
`num`/`created_at` from `/versions`, stars are `stargazers_count` from
`gh api repos/<o>/<r>`, and open-issue counts are `.total_count` from
`gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"` (counted with `jq` 1.8.2 in
the first case, `gh` 2.98.0 in the others).

| Name | Role | 90-day dl | All-time dl | Stars | Last release | Maintenance | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| **`serde`** | Schema definition + per-field type/domain rejection | 308,308,063 | 1,402,408,950 | 10,826 | 1.0.229, 2026-07-18 | **active** | every project in the `### Landscape` table | Universal and near-free, but strictly fail-fast: one error per document |
| **`garde`** | Post-deserialization constraint validator with aggregate `Report` | 1,800,800 | 4,321,159 | 898 | 0.23.0, 2026-05-23 | **at-risk** (signal below) | `garde-actix-web` 0.12.0, `axum-valid` 0.25.0, `schemars` 1.2.2 (optional integration) | Best error shape of any validation crate and the smallest tree, but it only aggregates constraint errors, never type errors |
| **`validator`** | The long-standing derive validator | 11,775,106 | 65,165,401 | 2,516 | 0.21.0, 2026-07-27 | **active** | `cargo-cyclonedx` 0.5.9 (1.18M dl), `package_json_schema` 0.3.0 (1.15M dl), `deltalake-core` 0.32.4 (320k dl) | Six unavoidable non-optional dependencies (`regex`, `url`, `idna`, `serde_json`…) and a `HashMap` error container with no defined ordering |
| **`serde_valid`** | JSON-Schema-shaped validator with nested JSON error tree | 1,579,995 | 4,363,036 | 90 | 3.1.2, 2026-09-10 | **active** (most responsive of all) | `axum_serde_valid` 1.1.0, `swagger` 7.0.1, `tari_core` 5.6.0 | Ten non-optional dependencies including `thiserror ^1.0`, which collides with R67's `thiserror = "2.0.20"` |

**Maintenance-state derivations, by the prompt's rubric.** Issue responsiveness was
measured over the 10 most recently opened **issues** (pull requests filtered out with
`jq`'s `select(.pull_request == null)`), taking the first comment whose
`author_association` is `OWNER`, `MEMBER` or `COLLABORATOR` and is not the issue's own
author (`gh api "repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=100"`,
retrieved 2026-09-17).

- **`serde` — active.** 1.0.229 released 2026-07-18, `pushed_at` 2026-08-25.
  Responsiveness sample: **0 of 10** most recent issues (#3083–#3100, 2026-07-15 to
  2026-09-06) drew a maintainer comment. I record the figure and decline to read it as
  a risk signal: serde's maintainer triages by closing rather than commenting, and the
  release cadence and push activity contradict any disengagement reading.
- **`garde` — at-risk, with the concrete signal named.** The 6-month release trigger
  has **not** fired: 0.23.0 is 3.8 months old at 2026-09-17. The concrete signal is
  elsewhere: **0 of 10** most recently opened issues drew any comment at all, spanning
  #158 (2026-01-17) to #204 (2026-08-22) — eight months of unanswered reports; the
  only commits since 2026-05-29 are a Dependabot Actions bump and its merge
  (`gh api "repos/jprochazk/garde/commits?since=2026-05-23T00:00:00Z"`, 11 entries, of
  which the newest human commit is 2026-05-23); and 6 pull requests are open. Counter-
  evidence recorded in fairness: this is a single-maintainer project with a historically
  batched cadence (0.22.0 2025-01-19, 0.22.1 2025-11-30, 0.23.0 2026-05-23), it carries
  no advisory, and its 2026-05 release cleared a backlog including a community fix.
  Not `dormant`: no unpatched advisory, no broken build, no maintainer notice.
- **`validator` — active.** 0.21.0 released 2026-07-27; 11 commits in 2026, every one
  by the owner `Keats` (`gh api "repos/Keats/validator/commits?since=2026-01-01T00:00:00Z"`,
  counted with `jq`), the most recent four in July 2026 raising MSRV and edition.
  Responsiveness: **3 of 10** answered; days-to-first-maintainer-response for the
  answered three were 31, 0 and 8, median **8 days**; **7 unanswered**.
- **`serde_valid` — active.** 3.1.2 released 2026-09-10; more than 100 commits in 2026
  (the `per_page=100` page was full, so this is a floor, not an exact count).
  Responsiveness: **10 of 10** answered, days 0, 5, 1, 0, 0, 0, 0, 0, 0, 6 — median
  **0 days**, **0 unanswered**. The most responsive maintainer in the field by a wide
  margin, against the smallest star count.

### Excluded by gate

**No candidate was excluded by a fitness gate.** Gate-by-gate, for every candidate
named in this report:

1. **Licence — `inapplicable — owner ruling 2026-09-12 (Q7.B)`.** The owner ruled on
   2026-09-12 (`docs/port/OWNER-REVIEW.md`, "no licence check for anything the
   template uses (Q4, superseded and widened by Q7.B)") that licence compatibility is
   not evaluated for any dependency or tool. Nothing is excluded on licence. Recorded
   for completeness only, from `https://crates.io/api/v1/crates/<name>/versions`
   (2026-09-17): `serde` 1.0.229 `MIT OR Apache-2.0`; `garde` 0.23.0
   `MIT OR Apache-2.0`; `validator` 0.21.0 `MIT`; `serde_valid` 3.1.2 `MIT`; `nutype`
   0.7.0 `MIT`; `toml-span` 0.7.1 `MIT OR Apache-2.0`.
2. **MSRV within stable-minus-2 (floor 1.96).** Declared `rust_version` from
   `https://crates.io/api/v1/crates/<name>/<version>` (2026-09-17): `serde` 1.0.229 =
   **1.56** (pass); `garde` 0.23.0 = **1.87** (pass); `validator` 0.21.0 = **1.88**
   (pass); `serde_valid` 3.1.2 = **null**, `nutype` 0.7.0 = **null** — *undeclared*,
   which is an evidence gap, not a breach: the policy's "declared as rust-version in
   Cargo.toml and tested in CI" clause binds this template's own crates, not third
   parties. **Unverified for every candidate: the transitive tree.** I checked direct
   `rust_version` only; `compact_str`, `smallvec`, `regex`, `idna`, `url`,
   `serde_json`, `indexmap`, `itertools`, `num-traits` and `unicode-segmentation` were
   not resolved, and P03 must confirm the whole tree with `cargo +1.96 check`.
3. **No open RustSec advisory; `unsafe` posture stated.** `https://rustsec.org/packages/<name>.html`
   returned **HTTP 404** for `serde`, `validator`, `garde`, `serde_valid`, `nutype`,
   `serde_path_to_error`, `toml-span` and `validify` (2026-09-17). 404 is the
   no-advisory response, validated against controls in the same run: `atty`, `time` and
   `openssl` each returned **HTTP 200**, and a nonexistent crate name also returned
   404. So: **zero open advisories for every candidate**, with the caveat that a 404
   is indistinguishable between "no advisory" and "crate name unknown to RustSec".
   `unsafe` posture, from `gh api search/code` restricted per repository plus reading
   the matching files (2026-09-17): `validator` — **0 matches**, no `unsafe` in its own
   source. `garde` — **4 files match**, three of them real: a `transmute(&next.value)`
   at `garde/src/error/rc_list/mod.rs:93` (on the default path, since `rc_list` backs
   `garde::error::Path`), `unsafe impl<T> Send/Sync for SyncWrapper<T>` at
   `garde/src/rules/pattern.rs:139-140` (js-sys only), and a raw-pointer deref
   `unsafe { p.as_ref() }` at `garde/src/i18n.rs:402`. `nutype` — `unsafe` only behind
   the opt-in `new_unchecked` feature, off by default
   (`nutype/src/lib.rs:692,702`). `serde` — not audited here; its `serde_core` split
   and its universal presence in every surveyed project make it out of scope for an
   exclusion decision. **No exclusion follows from any of this**: R06 decided the
   template forbids `unsafe` in *its own* code via `[workspace.lints.rust] unsafe_code
   = "forbid"` and explicitly "makes no claim about `unsafe` inside its dependency
   tree", because Cargo compiles dependencies with `--cap-lints allow`
   (`research/topics/06-unsafe-code-policy/DECISION.md`, `## Decision`).
4. **Builds and is tested on `ubuntu-latest` and `macos-latest`.** **This gate is
   satisfied by portability, not by upstream CI, for every candidate including the
   dominant choice — and I am recording that rather than passing it silently.** Reading
   each repository's `.github/workflows/` with `gh api` and extracting runner labels
   with `grep` (2026-09-17): `garde` `ci.yml` — `ubuntu-latest` only; `validator`
   `ci.yml` — `ubuntu-latest` only; `serde_valid` `CI.yml`/`Publish.yml` —
   `ubuntu-latest` only; `nutype` `ci.yml` — `ubuntu-latest` only; `serde` `ci.yml` —
   `ubuntu-latest` and `windows-latest`, **no macOS leg**. docs.rs builds only
   `x86_64-unknown-linux-gnu` for all of them. None of these crates links C code or is
   known to me to contain platform-conditional code, and I did **not** prove the
   absence of `cfg(target_os)` paths — a repository-scoped code search for `cfg`
   returned 15 undifferentiated hits each for `garde` and `validator`, which is
   feature-gate noise, not evidence. The proof obligation therefore falls on this
   template's own `macos-latest` CI leg, and P03 must treat a green macOS job as the
   gate-4 receipt. Windows is noted, not required.
5. **Default features and async-runtime coupling.** Every candidate is synchronous and
   couples to **no** async runtime; none has a `tokio`, `async-std` or `futures`
   dependency in its `normal` dependency list (2026-09-17). Defaults: `serde`
   `default = ["std"]`, so `features = ["derive"]` is additive and `default-features =
   false` reaches `no_std`; `garde` and `validator` declare **no `default` key at all**,
   so `features = ["derive"]` is the whole surface; `nutype` `default = ["std"]`;
   `serde_valid` was not observed to declare a `default` key in the fields read, and
   its ten dependencies are non-optional regardless.
6. **Binary size and compile-time cost, qualitatively.** `serde` — already in the tree
   for R52 and R66, so the marginal cost of this item is **zero crates**; `serde_derive`
   is a proc macro and contributes compile time, not binary bytes. `garde` — adds three
   crates at `features = ["derive"]` (`garde`, `garde_derive`, `compact_str`,
   `smallvec`; the last two are small and `default-features = false`), plus one proc
   macro; the smallest addition of any validation crate. `validator` — adds at minimum
   `validator`, `validator_derive`, `regex` (and its `regex-automata`/`regex-syntax`
   subtree), `idna`, `url`, `serde_json`; `regex` alone is among the more expensive
   compile-time dependencies in common use, and its DFA tables are linked into the
   binary. `serde_valid` — adds all of validator's weight plus `indexmap`,
   `itertools`, `num-traits`, `unicode-segmentation` and a **second major version of
   `thiserror`**. I measured no wall-clock compile times and state none.

**Excluded for reasons other than a gate, recorded here so the exclusion is not
silent.**

- **`validify`** — maintenance. Newest non-yanked version **2.0.0, `created_at`
  2025-02-09** (19 months before this run), 90-day downloads **11,123**, all-time
  **72,844**, stars **74**, `archived` false, `pushed_at` 2025-11-21, open issues
  **3**, RustSec HTTP 404 (no advisory). Maintenance state **at-risk**: the 6-month
  release trigger has fired and the investigation finds a 19-month release gap against
  a still-live repository, on a crate that is a fork of a candidate already in the
  shortlist. Nothing it offers is unavailable from `garde`.
- **`serde_path_to_error`** (90-day 80,853,700; all-time 280,245,735; 0.1.20,
  2025-09-15; stars 426; open issues 5) — not excluded on quality; **made redundant by
  the parse layer**. Its purpose is naming the key a single serde error occurred at,
  and `toml::de::Error::span()` already returns a byte range into the original
  document. It would earn its place only if R52 selected a TOML crate whose error type
  carries no location.
- **`toml-span`** (90-day 4,822,732; all-time 15,289,889; 0.7.1, 2026-03-06; stars 7;
  open issues 3; RustSec 404) — **out of this item's scope by the prompt's own
  boundary**: it is a TOML parser, and "which crate parses/writes the raw TOML bytes"
  is R52's. It is carried through this report because its `DeserError { errors: Vec<Error> }`
  is the only mechanism found that aggregates *type* errors, and because `cargo-deny`
  uses it for precisely this job. See `### Parameters` for the requirement passed to
  R52. Note for R52's own gate work, not adjudicated here: 7 GitHub stars is a weak
  popularity signal that its 4.8M 90-day downloads contradict, and its GitHub licence
  field reads `NOASSERTION` while crates.io reads `MIT OR Apache-2.0`.

### Up-and-comers

- **`garde` 0.23.0** — the field's most interesting design, and this item's ranked
  runner-up. Two properties are genuinely ahead of `validator`, both verified from the
  maintainer's own reference (2026-09-17): `Report` is documented as "a flat list of
  `(Path, Error)`" with `iter()` and `into_inner() -> Vec<(Path, Error)>`
  (`https://docs.rs/garde/latest/garde/error/struct.Report.html`) — an **ordered**
  sequence, so CLI stderr output is deterministic and snapshot-testable, where
  `validator`'s `HashMap` is not; and `Unvalidated<T>`/`Valid<T>` make validation a
  type-state rather than a convention. Its own README states it is "essentially a full
  rewrite of `validator`" prompted by community discussion
  (`https://docs.rs/garde/latest/garde/`, "Acknowledgements"). Held back by the
  at-risk signal above, and by the structural limitation that it cannot see type
  errors at all.
- **`nutype` 0.7.0** — 90-day 1,774,984; all-time 5,798,730; stars 1,770; open issues
  11; `pushed_at` 2026-09-01; newest **stable** 0.7.0 `created_at` 2026-04-25, with
  `0.8.0-beta.2` published 2026-09-01 (a prerelease, not the recommended pin);
  responsiveness 2 of 10 answered, days 9 and 28. It generates a newtype with a
  private field and a fallible constructor, so an invariant cannot be bypassed —
  the purest parse-don't-validate expression in the field, edition 2024, and a
  single dependency (`nutype_macros`). It is a **complement, not a competitor**: it
  strengthens Alternative 1 and is strictly fail-fast, so it cannot supply the
  aggregation this item needs. Worth revisiting for R56 if a `token` field arrives
  with a format constraint.
- **`serde_valid` 3.1.2** — the most actively maintained crate in the field
  (median 0 days to first maintainer response, 10 of 10 answered) and the only one
  whose error type is a nested JSON document out of the box, which suits an HTTP
  problem envelope. Held back for a CLI by its ten non-optional dependencies and the
  `thiserror ^1.0` collision with R67's `2.0.20`.
- **`toml-span` 0.7.1** — the only mechanism found that aggregates type errors, with
  spans; R52's to adjudicate, not this item's.

### Fit for this template

**CLI.** The strongest fit, and the surface that drives the answer. The CLI is where
a human edits the file, where R67's `RSLB202`/`RSLB203` split lands, where R55's
per-key tolerance policy applies and where a deterministic, snapshot-testable stderr
message matters. All seven surveyed CLI projects use `serde` derive with no validation
crate; `cargo-deny`, the closest analogue, hand-writes exactly the
`Unvalidated → Valid` + accumulated-diagnostics structure this report recommends. The
per-key loop over `toml::Table` gives the CLI both the aggregate report and the
per-key independence, and serde's enum error text
("unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`") is
already the allowed-values hint py builds by reflection at `settings.py:129-135`.

**Library.** The schema types live in the library crate and are part of its public
API, so two library-specific constraints bind. First, R67 forbids the library crate
from depending on `anyhow` and requires `thiserror` for its typed errors — which is
why `serde_valid`'s non-optional `thiserror ^1.0` is a real cost here rather than a
detail: a library crate would compile two major versions of its own error-derive
dependency. Second, R04's public-API-surface enforcement means every type a validation
crate's derive forces into the signature (`garde::Report`, `validator::ValidationErrors`)
becomes part of the library's semver surface, and a 0.x crate's breaking change then
becomes the library's. The recommendation puts a project-owned `Vec<Issue>` there
instead, whose stability the template controls. `garde` is the least bad of the
validation crates on this axis because `Report` is `Serialize`/`Deserialize` and
stable in shape, but it is still a 0.x type in a public signature.

**Web.** The one surface where a validation crate is the ecosystem's actual answer —
and where this item's decision does not reach. Request-body validation over an
extractor is a different problem from config-file validation: many small untrusted
payloads per second, arbitrary user-supplied shapes, and an aggregate field-error
response that maps onto RFC 9457. That is exactly where `garde` and `serde_valid`
live, evidenced by their reverse dependencies (`garde-actix-web`, `axum-valid`,
`apistos-gen`; `axum_serde_valid`, `swagger`). **If the web surface later wants
request validation, that is R69/R70's decision and `garde` is a live candidate there —
this item's "no validation crate" answer is scoped to the config file and must not be
read as a workspace-wide ban.** The config schema itself is shared unchanged across
all three surfaces: typed deserialization is format-agnostic, so whatever R77
(`web-env-settings`, still `open`) decides for environment-variable layering can reuse
these same types unchanged.

### Recommendation

**Use `serde` 1.0.229 (`>= 1.0.229, < 2.0.0`) with `features = ["derive"]` as the
config schema mechanism. Add no validation crate.** Express every constraint the type
system can hold as a type: a fieldless `enum` per literal set (R66's
`table | json | markdown | name`; the `auto | always | never` colour triple),
`NonZeroU32` for ts's `.positive()` bound, and `#[serde(try_from = "String")]`
newtypes for anything else. Build the report layer in the library crate as three small
pieces: an `Unvalidated`/`Valid` type-state so no value can be read before the check,
a `Vec<Issue>` of `(dotted path, message, optional span)`, and a per-key
deserialization loop over the parsed table so every bad key is reported in one pass.

**Four reasons, in the order they should be weighed.**

1. **A validation crate does not solve the problem this item actually has.** The one
   capability `serde` lacks is aggregation, and no serde-layered validator supplies it:
   `garde` and `validator` run *after* `Deserialize` has already early-returned on the
   first type error. A file with `format = "yaml"` and `limit = "abc"` yields one error
   with `garde` in the tree and one error without it. Adding the crate buys rules the
   types already enforce and does not buy the shape zod produces.
2. **The aggregation has to be built at the parse boundary regardless**, and once it is
   built, the validation crate's remaining job for this schema is empty. Every
   constraint in either source's schema — three literal sets and one positive integer —
   is a type. There is no length bound, no pattern, no cross-field rule, and no
   `token` field yet (R56).
3. **Practice agrees, in this exact niche.** Seven of seven surveyed Rust CLIs do this;
   zero use a validation crate; and the closest analogue, `cargo-deny`, hand-writes the
   same `UnvalidatedConfig`/accumulated-diagnostics structure recommended here.
4. **It is the cheapest thing that satisfies the consumed contract.** R67's
   `RSLB202`/`RSLB203` split already forces a two-stage parse, because
   `toml::de::Error` exposes no kind discriminant. The per-key loop is the second half
   of a structure the error contract requires anyway.

**The one thing this recommendation depends on that it does not own**, stated plainly
so it is not lost: the aggregation loop needs an intermediate parsed value it can walk
key by key, and spans for `hint` need that intermediate to carry source offsets. With
the `toml` crate the first is free (`toml::Table`) and the second needs
`toml::Spanned`. With `toml-span` both are native. This is a requirement passed to R52,
recorded in `### Parameters`.

### Ranked runner-up

**`garde`, `>= 0.23.0, < 0.24.0`** — `garde = { version = "0.23.0", default-features =
false, features = ["derive"] }`, layered over the same `serde` schema types and called
through `Unvalidated<T>::validate()` at the same point the hand-written pass would run.

**The condition under which it wins.** The moment the config schema acquires a
constraint the type system cannot hold, and there is more than one of them. Concretely,
any of: a string key with a length or pattern bound (R56 adding a `token` with a
minimum length or a prefix rule); a numeric key whose valid range is not "nonzero" (a
`logging.max_file_size` with an upper bound); a cross-field rule (`logging.file_level`
must not be coarser than `logging.level`, which `garde`'s
`#[garde(custom(…))]` with `self` access expresses directly); or a fourth-plus rule of
any kind. At that point the hand-written pass begins reimplementing `garde`'s rule set
with worse error messages, and the trade flips. `garde` is preferred over `validator`
for this seat on three verified grounds: its `Report` is an ordered
`Vec<(Path, Error)>` where `validator`'s `ValidationErrors` is an unordered `HashMap`
that a CLI must sort before printing; it adds three crates where `validator` adds
`regex`, `url`, `idna` and `serde_json` unavoidably; and its `Unvalidated`/`Valid`
type-state matches the structure this item recommends building anyway.

**The condition under which `garde` must be re-examined before adoption, not merely
preferred**: its at-risk signal. If, at the time P03 needs it, the 6-month release
trigger has fired (0.23.0 would reach that on 2026-11-23) *and* the unanswered-issue
run has continued, `validator` becomes the runner-up on maintenance grounds despite its
heavier tree and unordered errors, and `serde_valid` becomes the runner-up if the web
surface (R69) has by then created a second caller that wants a JSON error tree.

### Tradeoffs

**What the pick gives up versus `garde`, and why that cost is accepted.**

- *A maintained rule library.* `garde` ships `length`, `range`, `pattern`, `contains`,
  `prefix`, `suffix`, `email`, `url`, `ip`, `credit_card`, `phone_number`, `dive`,
  `custom` and conditional `if(cond = …)`, with tested messages and i18n. The template
  ships none of that. Accepted because the current schema needs exactly zero of them:
  three literal sets and a positive integer are types. The cost is real and is bounded
  by the runner-up condition above — the moment it stops being zero, adopt `garde`.
- *A ready-made type-state.* `Unvalidated<T>`/`Valid<T>` arrive free; the template
  writes ~15 lines instead. Accepted because those 15 lines are in the library crate's
  public API, where owning the type is worth more than saving the lines (R04).
- *Ordered per-field errors with a `Path` type.* The template builds `Vec<Issue>` with
  a `String` path instead. Accepted; the shape is the same and the template controls
  its semver.
- *What the pick gains and `garde` does not offer at all*: aggregation of **type**
  errors. This is not a tie-break, it is the item's central requirement, and `garde`
  cannot meet it.

**What the pick gives up versus `validator`.** The same rule library, plus a larger
adopter set (`cargo-cyclonedx`, `package_json_schema`, `deltalake-core`) and a better
maintenance record (3 of 10 issues answered against `garde`'s 0 of 10; releases in
2026-07 against 2026-05). Accepted because `validator`'s six non-optional
dependencies — `regex`, `idna`, `url`, `serde_json`, `serde`, `serde_derive` — are
unavoidable and unused here, its `HashMap` error container has no defined iteration
order (so error output would be nondeterministic across runs unless sorted, which
breaks snapshot testing), and it shares `garde`'s structural inability to see type
errors.

**What the pick gives up versus `serde_valid`.** The field's best maintainer
responsiveness and a nested-JSON error tree that would map cleanly onto an HTTP
problem document. Accepted because its ten non-optional dependencies include
`thiserror ^1.0`, which is semver-incompatible with R67's fixed `thiserror = "2.0.20"`
and would put two major versions of the same error-derive crate in the library crate's
tree, and because its JSON-shaped error is a poor fit for a CLI's line-oriented stderr.

**What the pick gives up versus `toml-span`.** Native multi-error deserialization with
spans, and the reference implementation `cargo-deny` already runs on it. Accepted only
in the sense that it is not this item's to accept: the parser is R52's decision. If R52
selects `toml-span`, this item's per-key loop is replaced by `TableHelper` and the
recommendation's *schema* half (serde-derived enums and `NonZeroU32`) is replaced by
hand-written `toml_span::Deserialize` impls — a material change to this item's answer,
recorded as its re-verify trigger.

**The cost nobody should discount: this recommendation ships code rather than a
dependency.** Roughly 60 lines of library code (the type-state, `Issue`, the per-key
loop) become the template's to test and maintain, where a crate would carry them. That
is accepted because the lines are simple, sit in the crate's own public API where
ownership is an asset, and would have to be written anyway to satisfy R67's two-stage
split — but it is a maintenance transfer, not a free saving, and P03 should hold it to
the same test coverage a dependency would have earned.

### Parameters

- *owns*: **none.** R53 owns no registry parameter (`research/CLAUDE.md`, R53 row,
  `owns` column reads `—`; `docs/port/PARAMETERS.md` lists no `R53` owner).
- `assumes error-taxonomy-exit-codes = ` the R67 value as published in
  `research/topics/67-error-and-exit-code-contract/DECISION.md` and mirrored in
  `docs/port/PARAMETERS.md`. The four clauses this item actually consumes: **(a)**
  `RSLB202` "config document unparsable" → exit 2 and `RSLB203` "config value invalid"
  → exit 2 are distinct catalog rows; **(b)** the envelope is a single stderr JSON
  object `{"error":{"code","message","hint"?}}` with stdout byte-empty on the error
  path; **(c)** `hint` "must be able to name the offending input per R7.6, so a
  borrowed-or-owned string is expected rather than a `&'static str`"; **(d)**
  `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only, and
  the library crate must not depend on `anyhow`. Clause (a) is what forces the
  two-stage parse; clause (c) is what makes the span question load-bearing; clause (d)
  is what makes `serde_valid`'s `thiserror ^1.0` a cost.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release,
  declared as rust-version in Cargo.toml and tested in CI` → floor **1.96** against
  stable 1.98.1 on 2026-09-17.
- `assumes rust-edition = 2024`; `assumes license = MIT OR Apache-2.0` (not evaluated
  for dependencies, per the 2026-09-12 owner ruling); `assumes target-os-matrix =
  ubuntu-latest, macos-latest`.

**No `CONFLICT:` line is emitted.** Nothing in this recommendation requires a consumed
parameter to change; R67's contract is satisfied as published.

**One requirement is passed to a related item that owns no registry parameter, so it
cannot take the `CONFLICT:` form and is recorded explicitly instead.**

> **Requirement passed to R52 (`toml-crate`, F225/F226).** This item's schema layer
> needs two things from whatever parser R52 selects: (1) an addressable intermediate
> value the loader can walk key by key — `toml::Table` satisfies this — because the
> aggregate report and R67's `RSLB202`/`RSLB203` split both require per-key
> independence, and (2) a source location for a rejected key, so R67's `hint` can name
> the offending input. With `toml` 1.1.x, (1) is `toml::Table` and (2) needs
> `toml::Spanned` in the intermediate; with `toml-span` 0.7.x both are native
> (`DeserError { errors: Vec<Error> }`, `TableHelper::finalize`). A parser that offers
> neither would push the aggregation into a hand-written tokenizer, which no evidence
> in this report supports. **If R52 selects `toml-span`, this item's answer changes
> materially** — see `### Confidence & re-verify trigger`.

**One `OVERRIDE` candidate identified and deliberately not opened.**
`#[serde(deny_unknown_fields)]` is named in this item's HIGH question, but adopting it
would depart from both sources: py sets `model_config = {"extra": "ignore"}` on all
three models (`b08bccfb:src/py_launch_blueprint/core/settings.py:43,52,63`) and zod's
`z.object` strips unknown keys by default, so **both sources tolerate unknown keys**.
The recommendation therefore *omits* `deny_unknown_fields` and preserves the sources'
behaviour; the mechanism supports either policy by adding or removing one attribute,
and the choice belongs with R55's failure-tolerance work. Two facts for whoever takes
it: serde documents the attribute as "Always error during deserialization when
encountering unknown fields" and warns it "is not supported in combination with
`flatten`, neither on the outer struct nor on the flattened field"
(`https://serde.rs/container-attrs.html`, retrieved 2026-09-17); and under the per-key
loop recommended here, unknown-key *detection* is free (any key in the table not
consumed by the loop), so the policy is a one-line branch rather than an attribute
decision.

### Migration implications

File-level changes in the template that P03 will make. No file below exists yet.

| File | Change |
|---|---|
| `Cargo.toml` (workspace) | `[workspace.dependencies] serde = { version = "1.0.229", features = ["derive"] }`. **No new dependency is added by this item** — `serde` is already required by R66's result-data contract and by R52's typed deserialization. |
| `crates/rs-launch-blueprint/Cargo.toml` | `serde.workspace = true`; `thiserror` per R67. No validation crate. |
| `crates/rs-launch-blueprint/src/config/schema.rs` | **New.** The typed schema: `ConfigFile`, `OutputSettings`, and one fieldless `enum` per literal set. The Rust seat of py `core/settings.py:40-67` and ts `src/lib/config.ts:33-41`. |
| `crates/rs-launch-blueprint/src/config/validate.rs` | **New.** `Unvalidated`/`Valid` type-state, `Issue`, the per-key loop, and `writable_keys()` — the analogue of py `settings.py:76-84`, which a Rust template gets by listing the enum's own variants rather than by reflecting over model fields. |
| `crates/rs-launch-blueprint/src/config/loader.rs` | **New,** and shared with R52/R54/R55. Holds the two-stage boundary: `toml::from_str::<toml::Table>` failure → `RSLB202`; `Unvalidated::validate()` failure → `RSLB203`. |
| `crates/rs-launch-blueprint/src/error.rs` | Two `ErrorCode` variants wired to the two stages, per R67's catalog. No new codes are requested. |
| `crates/rs-launch-blueprint/tests/config_schema.rs` | **New.** The rejected-value table from `### Validation strategy`, as the executable form of F229's "representative rejected values" criterion. |
| `docs/` | The config reference lists each key's allowed values. With enums these can be generated from the variant list rather than hand-maintained, which is what py's `allowed_values()` does at `settings.py:117-127`. |

**What does *not* change.** No `build.rs`, no proc-macro crate of the template's own,
no feature flag, no CI job beyond the existing test lane, and no entry in R42's
tool-provisioning surface — this item adds no binary to `PATH`.

### Validation strategy

**Every command below is proposed, not run.** No Rust source exists in this
repository; this engine compiled nothing and executed no `cargo` command. The three
things that *were* executed in this run are registry and repository queries
(`curl`, `gh api`, `jq`) and pinned-source reads (`git -C … show`); their results are
the figures and quotations cited above, and nothing else.

**Planned check 1 — one invalid value is rejected with its allowed set named (F229's
"representative rejected values").**

```bash
printf '[output]\nformat = "yaml"\n' > "$TMP/bad-format.toml"
rslbp --config "$TMP/bad-format.toml" projects list ; echo "exit=$?"
```

Expected: stdout byte-empty; stderr one envelope with `code` `RSLB203` and a `hint`
containing `output.format: unknown variant \`yaml\`, expected one of \`table\`,
\`json\`, \`markdown\`, \`name\``; `exit=2`. The variant list is generated by serde,
not hand-written — that is the property under test.

**Planned check 2 — the ts `.positive()` bound, which typed deserialization alone would
have accepted.**

```bash
printf '[output]\nlimit = 0\n' > "$TMP/zero-limit.toml"
rslbp --config "$TMP/zero-limit.toml" projects list ; echo "exit=$?"
```

Expected: `RSLB203`, `exit=2`, hint containing `output.limit: invalid value: integer
\`0\`, expected a nonzero u32`. This is the check that distinguishes the
recommendation from a plain `u32` field, and it is the exact case
`docs/port/BASELINE-REVIEW.md:279` cites.

**Planned check 3 — aggregation, the decisive behaviour.**

```bash
printf '[output]\nformat = "yaml"\nlimit = 0\ncolor = "rainbow"\n' > "$TMP/three.toml"
rslbp --config "$TMP/three.toml" projects list -o json 2>&1 >/dev/null \
  | jq -r '.error.hint' | tr ';' '\n' | wc -l
```

Expected: **3**. A fail-fast mechanism — serde derive alone, or serde derive plus
`garde`/`validator` — prints **1**. Counting with `jq` 1.8.2 and `wc`; the whole
stderr stream is piped, not a `head`-truncated prefix, so the count is a census.

**Planned check 4 — the `RSLB202`/`RSLB203` boundary R67 requires.**

```bash
printf '[output\nformat = "json"\n' > "$TMP/syntax.toml"   # unterminated table header
rslbp --config "$TMP/syntax.toml" projects list -o json 2>&1 >/dev/null | jq -r '.error.code'
```

Expected: `RSLB202`, `exit=2`, distinct from check 1's `RSLB203` on the same exit code.
A single-stage `toml::from_str::<ConfigFile>` cannot produce this distinction, which is
what the check proves.

**Planned check 5 — "before use", enforced rather than asserted.** A compile-fail test
under `trybuild` (or `tests/ui/`) that constructs the config value without validating:

```rust
let v: Valid = Valid(ConfigFile::default());   // must not compile: tuple field is private
```

Expected: `cargo test` reports the UI test passing because the snippet failed to
compile with `E0603`/`E0451`. This converts F229's "before use" from a convention into
a compiler-checked property, and it is the property `garde::Valid<T>` would otherwise
have supplied.

**Planned check 6 — unknown keys are tolerated, matching both sources.**

```bash
printf '[output]\nformat = "json"\nnonsense = 1\n' > "$TMP/extra.toml"
rslbp --config "$TMP/extra.toml" projects list ; echo "exit=$?"
```

Expected: `exit=0`, no envelope. This pins the deliberate *non*-adoption of
`deny_unknown_fields` (see `### Parameters`) so that a later change to it is a visible
test edit rather than a silent behaviour change.

**Planned check 7 — the gate-4 receipt.** The whole test file runs in the template's CI
on both `ubuntu-latest` and `macos-latest`. Because no candidate crate has a macOS CI
leg upstream, this job **is** the macOS evidence for this item, and P03 should not
record gate 4 as satisfied until it is green.

**What none of these checks covers, stated so it is not assumed.** Transitive MSRV
(needs `cargo +1.96 check --workspace` once a lockfile exists), compile-time cost
(needs `cargo build --timings` against a real tree), and the span-carrying variant of
`Issue` (needs R52's parser fixed first).

### Confidence & re-verify trigger

**Confidence: high on the mechanism, medium on the framing, and the two differ for a
stated reason.**

*High* on the technical findings, because each rests on primary evidence read this run
rather than on recollection: that serde's derive is fail-fast (`serde` `v1.0.229`
source plus the still-open serde PR #2891); that a post-deserialization validator
therefore cannot aggregate type errors (follows from the first); that
`toml::de::Error` carries no kind discriminant and so cannot separate `RSLB202` from
`RSLB203` (three inherent methods, listed in full); that `NonZeroU32` rejects `0` with
a named message (macro arm quoted); and that seven of seven surveyed Rust CLIs use
serde with no validation crate (`Cargo.toml` read at a named commit each).

*Medium* on the framing — specifically on whether "no validation crate" is the right
call rather than a defensible one. Two honest weaknesses. First, the argument leans on
the current schema being small (three literal sets and one integer); R56 has not yet
decided whether a `token` field exists, and a schema that grows string constraints
flips the runner-up condition. Second, this recommendation transfers ~60 lines from a
dependency to the template, and the survey that justifies it is seven projects, not
seventy — a broader survey could find a CLI cohort that does reach for `garde`.

**Re-verify triggers, in the order they are likely to fire.**

1. **R52 selects `toml-span` (or any parser with native multi-error deserialization).**
   This item's per-key loop is then redundant, and its schema half changes from
   serde-derived types to hand-written `toml_span::Deserialize` impls. **Material
   change; re-open this item.**
2. **R56 adds a `token` field, or R55 chooses per-key drop-with-warning with a rule
   set.** If two or more constraints appear that types cannot express, adopt the
   ranked runner-up. Re-check `garde`'s maintenance state first.
3. **`garde` crosses the 6-month release trigger on 2026-11-23 with the unanswered-issue
   run unbroken.** The runner-up changes to `validator`; re-run the responsiveness
   sample before deciding.
4. **serde PR #2891 merges.** serde would then carry a `#[serde(validate = "…")]` hook,
   which changes the composition story for every candidate in this report. It has been
   open 19 months; treat this as unlikely but cheap to check.
5. **Rust stable reaches 1.100 or later**, moving the MSRV floor and re-opening gate 2
   for every crate in the shortlist.
6. **Routine**: re-pull the crates.io and GitHub figures if this decision is still
   unratified 90 days after 2026-09-17, since `recent_downloads` is a rolling window.

### Sources

Pinned source repositories, read through their pins as the role requires, never from a
working tree.

- py `b08bccfb:src/py_launch_blueprint/core/settings.py` — `:33` `from pydantic import
  BaseModel, ValidationError`; `:40-46` `class OutputSettings(BaseModel)` with
  `model_config = {"extra": "ignore"}`, `format: Literal["text","json","markdown"]`,
  `color: Literal["auto","always","never"]`; `:49-57` `LoggingSettings`; `:76-84`
  `writable_keys()`; `:105-113` `coerce_value`; `:117-127` `allowed_values`; `:129-135` `_allowed_hint`;
  `:138-176` `settings_from_layers` and its `exc.errors()` loop. Read 2026-09-17 via
  `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`.
- py `b08bccfb:src/py_launch_blueprint/core/config.py:95-182` — `_read_layer`,
  `_read_explicit`, `_discovery_paths`, `load_config`. Read 2026-09-17.
- ts `cb1cbcb2:src/lib/config.ts` — `:1-17` the D-017 header comment naming smol-toml
  and zod v4; `:21` `import { z } from 'zod'`; `:33-41` `configFileSchema` with
  `z.number().int().positive().optional()`; `:124-130` `safeParse` and the
  `issues.map(...).join('; ')` aggregate; `:131-138` the loose-permissions warning.
  Read 2026-09-17 via `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>`.
- **Pin disagreement note:** I read only these two files from each repository and
  observed no HEAD-versus-pin divergence in them. The programme's recorded divergence
  (action pinning in py's workflows) does not touch this item, and no claim above
  mixes the two commits.

Repository records.

- `docs/port/COMMONALITY.md:232` (F228, `DIVERGENT`, `R53`) and `:233` (F229,
  `COMMON → REUSE`, pattern row).
- `docs/port/BASELINE-REVIEW.md:106` (F229 row, `retained`) and `:279` (the
  `BASELINE-REVIEW: F229` finding line).
- `docs/port/PARAMETERS.md` — the four `fixed` rows and the `error-taxonomy-exit-codes`
  researched row.
- `research/topics/67-error-and-exit-code-contract/DECISION.md` — revision 4,
  2026-09-10; `## Decision` stack table and catalog rows.
- `research/topics/66-output-format-surface/DECISION.md:25,35-44` — `serde = 1.0.229`
  and the `table | json | markdown | name` enum.
- `research/topics/06-unsafe-code-policy/DECISION.md` — `unsafe_code = "forbid"`, the
  `--cap-lints allow` dependency carve-out, and `rust-version = "1.96"`.
- `docs/port/OWNER-REVIEW.md:47-55` — heading "2026-09-12 — no licence check for
  anything the template uses (Q4, superseded and widened by Q7.B)", with the owner's
  verbatim ruling at `:51-55`: "Here, we don't need to check the licensing for any tool
  we use. Zero license check. That accounts for other tools and libraries we're
  including. The license we have only applies to the source code in the repo itself
  directly, not anything it includes or depends on." Read in this run, 2026-09-17.

Registry, repository and documentation endpoints — all retrieved 2026-09-17 (UTC).

- `https://static.rust-lang.org/dist/channel-rust-stable.toml` — `[pkg.rust] version =
  "1.98.1 (48a229cea 2026-09-01)"`.
- `https://crates.io/api/v1/crates/{serde,validator,garde,serde_valid,nutype,serde_path_to_error,toml-span,validify}`
  — `crate.recent_downloads`, `crate.downloads`, `crate.max_stable_version`.
- `https://crates.io/api/v1/crates/<name>/versions` — newest non-yanked `num`,
  `created_at`, `rust_version`, `license`.
- `https://crates.io/api/v1/crates/<name>/<version>` — `rust_version`, `edition`,
  `license`, `crate_size`, `features`.
- `https://crates.io/api/v1/crates/<name>/<version>/dependencies` — the
  optional/non-optional dependency lists quoted in `### Principles and implementation`.
- `https://crates.io/api/v1/crates/<name>/reverse_dependencies` — adopter evidence.
- `gh api repos/{serde-rs/serde,Keats/validator,jprochazk/garde,ya7010/serde_valid,greyblake/nutype,dtolnay/path-to-error,EmbarkStudios/toml-span,biblius/validify}`
  — `stargazers_count`, `archived`, `pushed_at`.
- `gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"` — `.total_count`.
- `gh api "repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=100"`
  and `.../issues/<n>/comments` — the responsiveness samples.
- `gh api "repos/<o>/<r>/commits?since=…"` — commit-activity counts.
- `gh api repos/serde-rs/serde/pulls/2891` and `.../issues/2891/comments` — the open
  validation-hook proposal and `oli-obk`'s `MEMBER` comment of 2025-02-12.
- `gh api repos/serde-rs/serde/contents/serde_core/src/de/impls.rs?ref=v1.0.229` —
  `NonZeroVisitor` at `:85-103`, the nonzero visit arms at `:165-176` (unsigned) and
  `:256-267` (`int_to_uint`, the arm a TOML `i64` takes).
- `gh api repos/EmbarkStudios/cargo-deny/contents/{Cargo.toml,src/cfg.rs}?ref=79d7f54dc1bfd8cc8105fac917d3dcc7675eb026`
  — `toml-span = { version = "0.7", features = ["reporting"] }` and
  `UnvalidatedConfig`/`ValidationContext`.
- `gh api repos/<o>/<r>/contents/Cargo.toml?ref=<sha>` for the six other surveyed
  projects, at the commits named in `### Landscape`.
- `gh api repos/<o>/<r>/contents/.github/workflows/<file>` — the runner-label extraction
  for gate 4.
- `https://serde.rs/container-attrs.html` — `deny_unknown_fields`, `try_from`,
  `default`, `transparent`.
- `https://docs.rs/toml/latest/toml/` and `.../toml/de/struct.Error.html` — toml
  `1.1.6+spec-1.1.0`; `Table`, `Value`, `Spanned`, and `Error`'s three inherent methods.
- `https://docs.rs/garde/latest/garde/`, `.../garde/error/struct.Report.html`,
  `.../garde/validate/struct.Unvalidated.html` — garde 0.23.0 rule table, feature
  table, `Report`, `Unvalidated`/`Valid`.
- `https://docs.rs/validator/latest/validator/struct.ValidationErrors.html` —
  `pub struct ValidationErrors(pub HashMap<Cow<'static, str>, ValidationErrorsKind>)`.
- `https://docs.rs/serde_valid/latest/serde_valid/` — the JSON-Schema validator table
  and `from_json_value`.
- `https://docs.rs/serde_path_to_error/latest/serde_path_to_error/` — "Original
  deserializer error together with the path at which it occurred".
- `https://docs.rs/toml-span/latest/toml_span/struct.DeserError.html` and
  `.../toml_span/de_helpers/struct.TableHelper.html` — `errors: Vec<Error>` and
  `finalize`.
- `https://rustsec.org/packages/<name>.html` — advisory checks, with the 404/200
  control described under gate 3.
- `https://rust-cli.github.io/book/in-depth/config-files.html` — the CLI working
  group's config chapter and its `TODO` section.
- `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` — the 2025
  State of Rust Survey results, consulted and **not** used for any figure.

**Method notes.** Endpoints queried this run: `https://static.rust-lang.org` (the
stable-channel manifest, for the MSRV floor); the crates.io v1 API for
`/crates/<name>`, `/crates/<name>/versions`, `/crates/<name>/<version>`,
`/crates/<name>/<version>/dependencies` and `/crates/<name>/reverse_dependencies`,
every call sending a `User-Agent` header as crates.io requires; the GitHub REST API
exclusively through the authenticated `gh` CLI (2.98.0) for `repos/<o>/<r>`,
`search/issues`, `search/code`, `repos/<o>/<r>/commits`, `repos/<o>/<r>/issues`,
`repos/<o>/<r>/issues/<n>/comments`, `repos/<o>/<r>/pulls/<n>` and
`repos/<o>/<r>/contents/<path>[?ref=<sha>]`; `https://rustsec.org/packages/<name>.html`;
`https://serde.rs`; `https://docs.rs`; `https://rust-cli.github.io`. Counts were
produced with `jq` 1.8.2 and `gh` 2.98.0; text extraction from docs.rs HTML used
`python3`; source filtering used `grep` and `base64`. Pinned source reads used
`git -C ~/c/py-launch-blueprint show b08bccfb:<path>` and
`git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>`; no git command in this run
modified anything. No token or environment value was printed.

*What I could not verify, listed rather than glossed.* **(1)** Transitive-tree MSRV for
every candidate — I read each crate's own declared `rust_version` and did not resolve
`compact_str`, `smallvec`, `regex`, `idna`, `url`, `serde_json`, `indexmap`,
`itertools`, `num-traits` or `unicode-segmentation`; gate 2 is therefore a
direct-dependency pass with an open tree question for P03. **(2)** macOS support for
every candidate including `serde` — no upstream CI leg exists and I did not prove the
absence of platform-conditional code; gate 4 rests on the template's own
`macos-latest` job. **(3)** `serde_valid` 3.1.2 declares no `rust_version` and I did
not locate a `default` feature key for it. **(4)** No compile-time or binary-size
measurement was taken; gate 6 is qualitative by dependency count, as the gate permits.
**(5)** RustSec's 404 response cannot distinguish "no advisory" from "name unknown",
though the 200-responding controls (`atty`, `time`, `openssl`) establish that 404 is
the no-advisory case for a real crate name. **(6)** The 2025 State of Rust Survey's
full report was not downloaded, so no crate-popularity figure is cited from it.
**(7)** Nothing in `### Validation strategy` was executed — no Rust code exists to
execute it against.
