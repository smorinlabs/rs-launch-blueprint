# R52 — TOML crate (bundle) — raw report, Opus engine

Engine identity `research-opus-2026-09-17T020714Z-4e96c68a620c`, model `claude-opus-5`.
All retrieval dates below are **2026-09-17 UTC** (2026-09-16 in the machine's local
zone) unless a different date is stated on the line. No Rust template exists; this is
research for P03 to implement, not an implementation.

Licence gate note applied throughout: **gate 1 is `inapplicable — owner ruling
2026-09-12 (Q7.B)`** (`docs/planning/p02/owner-decisions.md` section 7). No candidate
is excluded on licence grounds, and licence strings are reported as metadata only.

### Landscape

**The category this item decides.** Not "which TOML library is best" but *which crate
or crates carry the two distinct operations the template performs on one file*:
(a) **read** `<tool>_config.toml` into a typed Rust value that R53's schema layer can
validate, and (b) **write** that file back after `config set` mutates one key. TOML
itself is fixed (F224, `COMMON → REUSE`) and the filename convention is fixed (F227);
neither is re-litigated here.

**Three-bin map of the Rust field.**

| Bin | Members found | What puts it in this bin |
|---|---|---|
| Built-in / first-party toolchain | `toml` 1.1.6+spec-1.1.0; `toml_edit` 0.25.15+spec-1.1.0; and their shared internals `toml_parser` 1.1.3, `toml_writer` 1.1.2, `toml_datetime` 1.1.1, `serde_spanned` 1.1.1 | Rust has **no** TOML support in `std`. The nearest thing to first-party is the `toml-rs/toml` workspace: it is the parser Cargo itself links (`rust-lang/cargo` `Cargo.toml` lines 115–118 and 224–227, `https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml`, retrieved 2026-09-17), and its maintainer Ed Page (`epage`) is a member of the rust-lang **Cargo team** (`https://raw.githubusercontent.com/rust-lang/team/master/teams/cargo.toml` line 10, retrieved 2026-09-17). |
| Established industry standard | `toml` and `toml_edit` again — they *are* the standard, by an order of magnitude on every adoption figure below. Also `taplo` 0.14.0 (the library behind the `taplo` TOML formatter/LSP, a tool rather than a config-reading dependency). | `toml` has 18,793 reverse dependencies; `toml_edit` 1,595; the next non-`toml-rs` contender, `basic-toml`, has 36 (`GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=1` → `meta.total`, retrieved 2026-09-17). The independent crate index lib.rs ranks `toml` first and `toml_edit` second under the `#toml` keyword (`https://lib.rs/keywords/toml`, retrieved 2026-09-17). |
| Up-and-comer | `toml-span` 0.7.1 (Embark Studios / Jake Shadle, span-carrying deserializer used by `cargo-deny`); `boml` 2.0.0 (zero-dependency, `no_std`); `tomling` 0.3.0 (zeenix) | All three are recent, single-maintainer, low-adoption alternatives with a narrow thesis (spans, zero deps, minimalism). `tomling` recorded **30** 90-day downloads against `toml`'s 217,379,722 — that is a hobby-scale crate, not a template dependency. |
| Legacy / fork | `basic-toml` 0.1.10 (dtolnay), `toml_write` 0.1.2 (renamed to `toml_writer`) | `basic-toml` is a "stripped down fork of version 0.5 of the `toml` crate (from before the `toml_edit` rewrite)" and its README states, verbatim, *"(This project is no longer maintained.)"* (`https://raw.githubusercontent.com/dtolnay/basic-toml/master/README.md`, retrieved 2026-09-17). `toml_write` was renamed; `toml_writer` 1.1.2 is the live crate. |

**Authoritative sources used, and why each counts.**

| Source | Why authoritative | Retrieved |
|---|---|---|
| `rust-lang/cargo` `Cargo.toml` (`https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml`) | Cargo is the Rust project's own package manager; what it links is the closest thing Rust has to a blessed TOML stack. It pins `toml = "1.1.5"` **and** `toml_edit = { version = "0.25.10", features = ["serde"] }` together. | 2026-09-17 |
| `rust-lang/team` `teams/cargo.toml` | The rust-lang project's machine-readable governance record; it names `epage` as a Cargo team member, which is what makes the `toml-rs/toml` maintainer's own guidance authoritative rather than merely popular. | 2026-09-17 |
| `toml-rs/toml` `README.md` and the two crates' rustdoc headers (`crates/toml/src/lib.rs`, `crates/toml_edit/src/lib.rs`) | Maintainer's own documentation, which states the intended division of labour explicitly (quoted under `### Principles and implementation`). | 2026-09-17 |
| `toml-lang/toml-test` compliance suite, consumed by both crates as `toml-test-harness` 1.14.0 / `toml-test-data` 2.14.0 dev-dependencies with `decoder_compliance`, `encoder_compliance` and `encoder_pretty_compliance` harnesses (`crates/toml/Cargo.toml`) | The TOML language project's own cross-implementation conformance suite; running it is external, checkable evidence of spec conformance rather than a maintainer assertion. | 2026-09-17 |
| toml.io specification, version tag `+spec-1.1.0` carried in both crates' version strings | The format specification itself; the crates' own version metadata records which spec revision they implement. | 2026-09-17 |
| lib.rs `#toml` keyword ranking (`https://lib.rs/keywords/toml`) | An independent third-party crate index (not crates.io, not the maintainer), used here only as a corroborating popularity ordering. | 2026-09-17 |

**Authority explicitly *not* claimed.** The annual Rust survey does not rank
serialization or TOML crates, so it is not cited as evidence for this choice.
`blessed.rs` was attempted (`https://raw.githubusercontent.com/nicoburns/blessed-rs/main/data/crates.json`,
HTTP 200, 76,423 bytes) but did not parse as a single JSON document and no TOML entry
could be extracted; it is recorded as **unverified** and carries no weight here.

**Well-regarded projects surveyed, with the evidence that they are well regarded.**
Each manifest was read directly; each project's standing is a retrieved figure, not an
assertion.

| Project | Standing (evidence) | What its manifest declares |
|---|---|---|
| `rust-lang/cargo` | 15,484 stars, `archived: false`, `pushed_at: 2026-09-16T13:22:52Z` (`gh api repos/rust-lang/cargo`). It is Rust's official package manager — relevance is definitional for a Cargo-shaped template. | `toml = { version = "1.1.5", default-features = false }`; `toml_edit = { version = "0.25.10", features = ["serde"] }`; `toml_parser = "1.1.2"`; `toml_writer = "1.1.1"`. Workspace member re-enables `toml` with `["std","serde","parse","display","preserve_order"]`. |
| `astral-sh/uv` | 89,887 stars, `archived: false`, `pushed_at: 2026-09-17T02:33:02Z`. A newer, heavily adopted Rust CLI — exactly the "weight newer popular ones" case the survey method asks for, and the reference the owner's own Python guidance already uses for tooling. | `toml = { version = "1.1.0", default-features = false, … }`; `toml_edit = { version = "0.25.8", default-features = false, … }`; `toml_parser` with `["alloc","simd"]`; `toml_writer` with `["alloc"]`. |
| `starship/starship` | 59,920 stars, `archived: false`, `pushed_at: 2026-09-17T03:32:48Z`. A cross-platform Rust CLI whose entire configuration surface is a user-edited TOML file — the closest analogue to this template's `config set` use case. | `toml = { version = "1.1.6", features = ["preserve_order"] }`; `toml_edit = "0.25.15"`. |

All three ship **both** crates. That is the practice evidence for the recommended
shape, and it is also the compatibility proof recorded under `### Compatibility`.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

The principle both source repositories implement is: *the tool's persistent
configuration is a human-authored, human-editable text document that the tool can both
read into a validated typed value and write back after a programmatic change, without
the user losing what they wrote.* Agreement is required at the level of **capability
and observable behaviour**, not library: py and ts already disagree about the library
count (py `tomllib` + `tomli_w`; ts `smol-toml` alone) while agreeing about behaviour,
which is precisely why F225/F226 are `DIVERGENT` and this item exists.

Evidence for the requirement, read through the programme pins:

- py, pin `b08bccfb`, `src/py_launch_blueprint/core/config.py:40` — `import tomllib`;
  line 45 — `import tomli_w`. Read: `tomllib.loads(path.read_text(encoding="utf-8"))`.
  Write: `write_config_data()` renders with `tomli_w.dumps(data)`, then
  `tempfile.mkstemp(dir=config_path.parent, …)` + `os.fdopen` + `flush` + `os.fsync` +
  `os.replace(tmp_name, config_path)`, with `parent.mkdir(…, mode=0o700)`.
- ts, pin `cb1cbcb2`, `src/lib/config.ts:20` — `import { parse, stringify } from 'smol-toml'`.

**Four essential behaviours, extracted from those sources.**

| # | Behaviour | Where the source shows it |
|---|---|---|
| P1 | A config document parses into a typed value a schema layer can validate. | py hands the parsed dict to `settings_from_layers()` (`core/settings.py`); ts hands `parse(raw)` to `configFileSchema` (zod). R53 owns the Rust equivalent. |
| P2 | A parse failure is **distinguishable** from a missing file and from an I/O failure, and carries enough detail to name the offending input. | py `_read_explicit` raises `ConfigError(f"invalid TOML in config file {path}: {exc}")` for `tomllib.TOMLDecodeError` but returns `{}` for a missing file; ts `readConfigFile` raises `ConfigError` separately for the read failure and the parse failure. |
| P3 | A programmatic write **never destroys** the user's existing file. | py `read_config_for_write` refuses to touch an unparsable file — *"refusing to modify {config_path}: existing file cannot be parsed … Fix or remove it first."* — and `write_config_data` writes a sibling temp file then `os.replace`s it, so an interrupted write cannot truncate. |
| P4 | The written file is owner-only from creation, and the replacement is atomic (F243). | py `tempfile.mkstemp` creates 0600 before the first byte; `os.replace` is atomic. F243's ledger note records this as the required guarantee precisely because ts's chmod-after-write leaves a window. |

**Where both sources fall short, and why that is this item's business.** P3 is honoured
only against *truncation*. Both sources destroy the user's **comments, key order and
spacing** on every `config set`, because both round-trip through a plain data
structure: py does `tomllib.loads` → `dict` → `tomli_w.dumps`, and ts does `parse` →
object → `stringify`. Neither library can do better; neither Python's `tomli_w` nor
`smol-toml` retains trivia. The prompt names round-trip fidelity as a HIGH question, so
choosing a Rust design that preserves it is inside this item's scope. This is **not** a
`BASELINE-REVIEW:` finding: no recorded feature row is challenged (F225/F226 are
`DIVERGENT` with no inherited pattern, and F243's atomic-0600 shape is untouched and
still required). It is also not an `OVERRIDE (OV-nn)`, for the same reason — there is
no recorded pattern to depart from.

**Observable acceptance criteria** (behaviour a P03 test can assert, library-agnostic):

| AC | Assertion |
|---|---|
| AC1 | A valid `<tool>_config.toml` deserializes into the typed config struct with every field present, and an unknown key behaves as R53 specifies. |
| AC2 | A malformed document yields an error distinct from "file absent" and distinct from "I/O failed", carrying a line/column position and a byte span over the offending token. |
| AC3 | After `config set output.format json` on a file containing a header comment, a per-key comment and a trailing comment, the file still contains all three, in their original positions, with only the target value changed. |
| AC4 | After the same `config set`, the file re-reads into the typed struct with the new value (write/read closure). |
| AC5 | The file is mode `0600` from creation and the replacement is atomic; an interrupted write leaves the previous file intact (F243, inherited). |
| AC6 | An existing file that cannot be parsed causes `config set` to refuse, not to overwrite (P3). |

**Architectural alternatives, compared before libraries.** Four designs can satisfy
P1–P4. The choice between them is the real decision; the crate names follow from it.

| Design | Shape | Satisfies AC3? | Assessment |
|---|---|---|---|
| **A1 — single serde crate, full re-serialize** | `toml::from_str` to read, `toml::to_string_pretty` to write. This is ts's `smol-toml` shape and py's `tomli_w` shape transplanted. | **No.** | Simplest; one dependency; but it reproduces the sources' defect. Measured: a document whose first line is `# rslbp configuration — keep this comment` comes back without it (`PLAIN_KEEPS_COMMENT = false`, executed run below). |
| **A2 — single format-preserving crate for both directions** | `toml_edit` alone, with its `serde` feature, for both the typed read and the surgical write. | Yes. | One dependency, both directions, comments kept. Cost: `toml_edit` is `0.25.x` — pre-1.0, so a breaking release is a minor bump and the template's Dependabot lane will see more churn; and the maintainer's own docs steer serde users to `toml`. |
| **A3 — two crates split by direction** | One crate parses, a different crate writes — py's literal shape (`tomllib` + `tomli_w`). | No. | The split buys nothing in Rust: any crate that can write TOML can also parse it, so the second crate adds surface without adding capability. Rejected on the merits, not on availability. |
| **A4 — two crates split by *operation*: typed read vs surgical edit** | `toml` for `from_str` into the typed schema (P1, AC1, AC2); `toml_edit::DocumentMut` for the read-modify-write path (P3, AC3, AC4, AC6). | Yes. | **Recommended.** It is py's *two-crate shape* on a different, better-motivated axis. Both crates come from one workspace, one release train, one MSRV. Cargo, uv and starship all ship exactly this pair. |

**Why A4 over A2.** A2's single-crate economy is real but the economy is smaller than it
looks and the stability cost is larger. Measured on this machine (see
`### Validation strategy` for the full method): adding `toml_edit` on top of `toml`
adds exactly **four** crates to the normal dependency graph — `toml_edit`, `indexmap`
2.14.2, `equivalent` 1.0.2, `hashbrown` 0.17.1 — because `toml_parser`, `toml_writer`,
`toml_datetime` and `winnow` are already shared (`cargo tree -e normal`, executed
2026-09-17). Dropping `toml` and keeping only `toml_edit` would save those four minus
`toml`'s own three unshared crates — a wash — while moving the template's primary
deserialization path onto a `0.x` crate and off the `1.x` crate the maintainer
designates for serde. A4 keeps the stable-semver crate on the hot path and confines the
`0.x` crate to the one operation only it can perform.

**Maintainer's own documentation, quoted.** The `toml_edit` rustdoc header says: *"This
crate allows you to parse and modify toml documents, while preserving comments, spaces
**and relative order** of items. If you also need the ease of a more traditional API,
see the [`toml`] crate."* (`crates/toml_edit/src/lib.rs` lines 1–7, retrieved
2026-09-17). The workspace README splits them the same way: *"`toml` crate for serde
support · `toml_edit` crate for format-preserving editing of TOML"*
(`https://raw.githubusercontent.com/toml-rs/toml/main/README.md`, retrieved
2026-09-17). A4 is the shape the maintainers document, not an invention of this report.

**A structural change since the ts decision was taken.** D-017(2) rejected `@iarna/toml`
and `toml` (npm) as stale or parse-only. The Rust field has moved in a way that changes
the arithmetic that historically motivated `basic-toml`: as of `toml` 1.0 (2026-02-11)
the `toml` crate **no longer depends on `toml_edit`**. Its normal dependencies are
`serde_core`, `serde_spanned`, `toml_datetime`, `toml_parser`, `toml_writer`, `winnow`
(`crates/toml/Cargo.toml`, retrieved 2026-09-17; confirmed by `cargo tree -e normal -p toml`).
`basic-toml` existed to avoid the old `toml`-on-`toml_edit` weight; measured here, a
`basic-toml` binary is 478,976 bytes against `toml`'s 532,032 bytes — a 53,056-byte,
roughly 10% saving on a stripped release binary — which does not buy an unmaintained,
TOML-1.1-incapable fork.

**How the recommended design composes, end to end.** Read path: R54's discovery tiers
hand a path to a loader that does `std::fs::read_to_string` → `toml::from_str::<ConfigFile>()`
→ R53's validation. Write path: `config set` does `std::fs::read_to_string` →
`src.parse::<toml_edit::DocumentMut>()` (which is the P3 refusal point: a parse failure
here means "refuse to modify", never "rewrite from scratch") → mutate the one key in
place, preserving its decor → render `doc.to_string()` → hand that string to F243's
atomic-0600 writer. Verified reference implementations for each half:
`rust-lang/cargo` (both crates, Cargo team), `starship/starship` (both crates, a
user-edited TOML config identical in role to this template's).

**R67 consumption — the distinguishable error requirement (P2, AC2).** R67's
`error-contract/v1` (`research/topics/67-error-and-exit-code-contract/DECISION.md`,
revision 4, 2026-09-10) is consumed, not amended. The mapping this item's crates must
support, and the evidence that they do:

| Condition | R67 row | Exit | What the crate must supply |
|---|---|---|---|
| Config file unreadable (permission, I/O) — `std::io::Error` from the read, before any TOML crate is involved | `RSLB104` config layer unreadable | 1 | Nothing from the TOML crate; this is `std::io`. |
| Document will not parse — read path | `RSLB202` config document unparsable | 2 | A distinct error type. **Executed:** `toml::de::Error::span()` returned `Some(17..17)` and `Display` rendered `TOML parse error at line 2, column 9` with `Error::message()` = `string values must be quoted, expected literal string`. That satisfies R67's requirement that `hint` be able to name the offending input. |
| Document will not parse — write path, before mutation (P3/AC6) | `RSLB202` | 2 | **Executed:** `toml_edit::TomlError::span()` returned `Some(17..17)` with the same `TOML parse error at line 2, column 9` first line. |
| Parsed fine but a value is out of range or the wrong type | `RSLB203` config value invalid | 2 | **R53's**, not this item's. This item stops at "it is syntactically TOML". |

No `CONFLICT:` arises: nothing in the recommendation needs `error-taxonomy-exit-codes`,
`msrv-policy`, `rust-edition`, `license` or `target-os-matrix` to change.

**Performance, stated with its workload and configuration rather than inferred.**
Config-file parsing here is a single read of a file measured in hundreds of bytes,
once per process start. Parse throughput is therefore **not** a selection criterion and
no throughput benchmark is cited or relied on; the costs that do matter to a template
are compile time and binary size, measured below on a stated machine. Declaring
throughput irrelevant is itself a finding: it removes the only axis on which the
`no_std` minimalists (`boml`, `tomling`) could have competed.

**No `BASELINE-REVIEW:` finding is raised by this item.**

### Recommendation

**One stack:** `toml = "1.1.6"` (default features `std`, `serde`, `parse`, `display`)
for the typed read and any from-scratch serialization, **plus** `toml_edit = "0.25.15"`
(default features `parse`, `display`; the `serde` feature is *not* needed) for the
`config set` read-modify-write path that must preserve the user's comments, key order
and spacing.

This is a **two-crate split by responsibility**, matching py's crate *count* but not
py's axis: the split is typed-read versus surgical-edit, not parse versus write.
Neither crate performs file I/O, so F243's atomic-0600 write stays hand-rolled
`std::fs` regardless of this choice.

### Members

#### toml

##### Landscape

Bin: **built-in / first-party toolchain** and **established industry standard** at once
— Rust ships no TOML support in `std`, and `toml` is what Cargo links in its place
(`rust-lang/cargo` `Cargo.toml:115`, retrieved 2026-09-17). Category: serde-integrated
TOML deserialization and serialization. Competitors in the same bin: none at comparable
scale; `basic-toml` (legacy fork, unmaintained), `toml-span` and `boml` (up-and-comers)
are the field. Authorities as listed in the top-level `### Landscape`: the Cargo
manifest, the rust-lang/team Cargo roster naming `epage`, the crate's own rustdoc, the
`toml-lang/toml-test` conformance harnesses wired into its `[[test]]` sections, and
lib.rs's independent `#toml` ranking (first).

##### Principles and implementation

`toml` carries P1 (typed read) and P2 (distinguishable, located parse error). Its
rustdoc header describes it as *"A [serde]-compatible [TOML]-parsing library"* and
notes the format *"tends to be relatively common throughout the Rust community for
configuration, notably being used by [Cargo]"* (`crates/toml/src/lib.rs` lines 1–15,
retrieved 2026-09-17). It deliberately does **not** carry P3's fidelity guarantee: a
`from_str` → `to_string_pretty` round-trip discards comments, which the executed probe
confirms (`PLAIN_KEEPS_COMMENT = false`). It carries no part of P4 — it does no file
I/O at all. Reference implementations: `rust-lang/cargo`, `astral-sh/uv`,
`starship/starship` (manifests and standing figures in the top-level `### Landscape`).

##### Dominant choice

`toml` **1.1.6+spec-1.1.0**, released 2026-09-10T20:28:39Z, `yanked: false`
(`GET https://crates.io/api/v1/crates/toml/versions`, newest unyanked entry, retrieved
2026-09-17).

| Figure | Value | Endpoint / rule |
|---|---|---|
| 90-day downloads | 217,379,722 | `GET https://crates.io/api/v1/crates/toml` → `crate.recent_downloads` |
| All-time downloads | 912,211,500 | same → `crate.downloads` |
| Last release | `1.1.6+spec-1.1.0`, `2026-09-10T20:28:39.522017Z` | `GET https://crates.io/api/v1/crates/toml/versions`, newest `yanked: false` |
| Stars / archived / pushed | 1,074 / `false` / `2026-09-15T14:53:24Z` | `gh api repos/toml-rs/toml` → `stargazers_count`, `archived`, `pushed_at` |
| Open issues | 57 | `gh api "search/issues?q=repo:toml-rs/toml+is:issue+is:open"` → `total_count` (not `open_issues_count`, which reported 71 because it counts PRs) |
| Issue responsiveness | median **0.67 days** to first maintainer response; **3 of 10** unanswered | 10 most recently opened non-PR issues (#1214, #1213, #1210, #1206, #1188, #1181, #1175, #1172, #1162, #1158) via `gh api repos/toml-rs/toml/issues?state=all&sort=created&direction=desc&per_page=100`, PRs filtered, first comment whose `author_association` ∈ {OWNER, MEMBER, COLLABORATOR} and whose author is not the reporter |
| Advisories | **none** | `https://rustsec.org/packages/toml.html` → HTTP 404 (no package page = no advisory ever filed; verified against `https://rustsec.org/packages/time.html` → HTTP 200 listing RUSTSEC-2020-0071 and RUSTSEC-2026-0009). Cross-checked `POST https://api.osv.dev/v1/query {"package":{"name":"toml","ecosystem":"crates.io"}}` → `{}` |
| Reverse dependencies | 18,793 | `GET https://crates.io/api/v1/crates/toml/reverse_dependencies?per_page=1` → `meta.total` |

Maintenance state by rubric: **active**. Last release 6 days before retrieval; repository
pushed 2 days before retrieval; median first-response 0.67 days. No `at-risk` signal.

##### Qualified shortlist

- **`toml_edit` 0.25.15** — passes every gate; can also do the typed read via its
  `serde` feature. It is the other recommended member rather than a competitor, and is
  the fallback if `toml` ever became unsuitable (design A2).
- **`toml-span` 0.7.1** — passes gates 2–6. 90-day downloads 4,822,732; all-time
  15,289,889; last release 0.7.1 on 2026-03-06T07:19:38Z; `EmbarkStudios/toml-span`
  7 stars, `archived: false`, `pushed_at: 2026-03-06T07:20:50Z`, 3 open issues
  (`gh api "search/issues?q=repo:EmbarkStudios/toml-span+is:issue+is:open"`); no RustSec
  page (HTTP 404) and OSV `{}`; 29 reverse dependencies; `rust-version = "1.70"`,
  licence string `MIT OR Apache-2.0` on crates.io while GitHub reports `NOASSERTION`
  (licence is `inapplicable` per Q7.B either way). Maintenance: **stable-quiet** — six
  months without a release is a trigger to investigate, and the investigation finds a
  deliberate single-purpose crate with a live maintainer, not decay. Not recommended:
  its thesis is carrying spans into a hand-written deserializer, which trades away
  `serde` derive support — the exact integration R53 needs (MEDIUM question 3).
  Issue responsiveness **not computed** (shortlist-only candidate).

##### Excluded by gate

- **`basic-toml` 0.1.10** — **fails gate 2 (MSRV)**. Its `Cargo.toml` declares no
  `rust-version` field (`https://raw.githubusercontent.com/dtolnay/basic-toml/master/Cargo.toml`,
  retrieved 2026-09-17; crates.io `rust_version: null` for every published version), and
  no MSRV is stated in its README or anywhere else in the repository. The owner-fixed
  policy requires an MSRV *declared as `rust-version` in Cargo.toml*; an undeclared,
  unverifiable floor cannot be shown to sit within `stable minus 2 minor versions`, and
  an unmaintained crate will never raise it "only in a minor release". Gate 1
  `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Gate 3: no RustSec page (HTTP 404),
  OSV `{}`; `unsafe` posture not verified. Gate 4: CI badge present but the matrix was
  not read; moot. Independently of the gate, the maintenance rubric returns
  **archived**: `gh api repos/dtolnay/basic-toml` → `archived: true`,
  `pushed_at: 2025-03-03T04:43:39Z`, and the README carries the maintainer's own notice
  *"(This project is no longer maintained.)"* — a `dormant`-or-worse signal of exactly
  the kind the rubric demands. Figures for the record: 90-day downloads 14,324,113;
  all-time 63,353,663; last release `0.1.10` on 2025-03-03T04:41:42Z; 83 stars; 4 open
  issues; 36 reverse dependencies. It is also a fork of `toml` 0.5 and so predates the
  TOML 1.0/1.1 conformance work; it cannot parse the TOML 1.1 constructs `toml` 1.1.6
  accepts.
- **`tomling` 0.3.0** — **fails gate 6 as unassessable and fails the maintenance
  rubric**: 90-day downloads **30**, all-time 2,280, last release 2025-07-09T10:31:56Z
  (14 months before retrieval), `https://crates.io/api/v1/crates/tomling`. There is no
  adoption base from which to state a binary-size or compile-time cost for a real
  workload, and nothing to investigate the release gap against. Not a template
  dependency.

##### Up-and-comers

- **`boml` 2.0.0** — zero-dependency, `no_std`, `rust-version = "1.85.0"`, released
  2026-03-24T01:02:07Z; 90-day downloads 116,110, all-time 737,176; `bright-shard/boml`
  14 stars, `archived: false`, `pushed_at: 2026-03-24T01:01:20Z`, **0** open issues;
  RustSec 404 / OSV `{}`; 4 reverse dependencies. Watch-list only: its advantage is
  embedded/`no_std` footprint, and `toml` already supports `no_std` by disabling its
  default `std` feature, so the advantage does not apply to a hosted CLI. No serde
  derive integration.
- **`toml-span` 0.7.1** — detailed under `##### Qualified shortlist`. The one to watch
  if R53 later demands byte spans for every validation error; note that `toml` already
  offers spans through `serde_spanned` 1.1.1 (a normal dependency of `toml`, so no new
  crate) and through `toml::de::Error::span()`, executed above.
- **`taplo` 0.14.0** — 90-day downloads 716,818, all-time 3,481,354, last release
  2025-05-22T23:38:33Z. A TOML *toolkit* (formatter, LSP) rather than a config-reading
  dependency; if the template wants a TOML formatter that is R27/R29's question, not
  this one.

##### Fit for this template

| Surface | Fit |
|---|---|
| CLI (`rslbp`) | Direct. `toml::from_str::<ConfigFile>()` on the discovered config path; the error carries line, column and span for R67's `RSLB202` envelope and `hint`. |
| Library (`rs_launch_blueprint`) | Direct and correctly layered. `toml` is `#![forbid(unsafe_code)]`, does no file or stream I/O, installs no handler, and needs no `anyhow` — it satisfies R67's rule that the library crate stay free of process-level behaviour. |
| Web service (optional Cargo feature per F017) | Neutral. The web surface reads env settings (R77), not this file; if it ever loads the same config, the same `from_str` call serves. No async-runtime coupling: `toml` depends on no runtime, no executor and no futures crate. |
| py/ts precedent | Covers py's `tomllib` role and ts's `parse` half of `smol-toml`, with strictly more error detail than either (py's `TOMLDecodeError` carries a message; `toml::de::Error` carries a byte span). |

##### Recommendation

`toml = "1.1.6"` with **default features** (`std`, `serde`, `parse`, `display`).
Do **not** enable `preserve_order`: Cargo and starship enable it because they
re-serialize whole manifests through `toml::Value`, whereas this template's write path
goes through `toml_edit` (which preserves order natively), so `preserve_order` would
only pull `indexmap` into `toml` for no gain. Declare it in the workspace
`[workspace.dependencies]` and inherit in the library and binary crates.

##### Ranked runner-up

1. **`toml_edit` 0.25.15 with `features = ["serde"]`** (design A2, single crate for both
   directions). Everything works; the template's primary deserialization path would sit
   on a `0.x` crate against the maintainer's documented steer. Adopt only if `toml` 1.x
   ever became unmaintained.
2. **`toml-span` 0.7.1**. Costs serde derive integration, which is the one thing R53
   most needs.
3. **`basic-toml` 0.1.10**. Excluded by gate above; listed to record the ordering. The
   footprint argument that once justified it is now worth 53,056 bytes (measured), and
   it cannot parse TOML 1.1.

##### Tradeoffs

- **Gained:** the ecosystem's default, Cargo-linked, serde-native TOML reader; TOML
  1.1 spec support (`toml` CHANGELOG 0.9.10, 2025-12-18: *"TOML 1.1 parse support —
  multi-line inline tables, trailing commas on inline tables, `\e` string escape
  character, `\xHH` string escape character, optional seconds in times"*); `1.x`
  semver stability since 2026-02-11; conformance tested against `toml-lang/toml-test`.
- **Given up:** round-trip fidelity on write — which is exactly why `toml_edit` is the
  second member rather than an optional extra.
- **Cost (measured, Apple M4 Pro, 14 cores, `rustc 1.98.0`, `cargo 1.98.0`,
  `opt-level = 3`, `lto = false`, `strip = true`, fresh `target/` per run, executed
  2026-09-17):** adding `toml` + `serde` (derive) to a `println!`-only binary moved the
  stripped release binary from **342,000** to **532,032** bytes (**+190,032**) and the
  cold release build from 0.21–0.26 s to 4.09–5.60 s across two repetitions. Most of
  that delta is `serde_derive`'s proc-macro chain (`syn`, `quote`, `proc-macro2`), which
  the template pays for anyway.
- **Risk accepted:** a `1.x` → `2.x` bump would be a coordinated ecosystem event, not a
  surprise; the `+spec-1.1.0` build-metadata convention makes the implemented spec
  revision visible in `Cargo.lock`.

##### Parameters

`owns` — none. This member owns no registry parameter.

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — satisfied. Current stable is
**1.98.1** (`https://raw.githubusercontent.com/rust-lang/rust/stable/src/version`,
retrieved 2026-09-17), so the template floor is **1.96**. `toml` 1.1.6 declares
`rust-version = "1.85"`. Whole resolved tree, via `cargo metadata --format-version 1`
executed 2026-09-17 on a probe crate declaring `rust-version = "1.96"`: `toml` 1.85,
`toml_datetime` 1.85, `toml_parser` 1.85, `toml_writer` 1.85, `serde_spanned` 1.85,
`winnow` 1.65.0, `serde`/`serde_core` 1.56, `serde_derive`/`syn`/`quote`/`proc-macro2`
1.71, `memchr` 1.61, `unicode-ident` 1.71 — maximum **1.85.0**, comfortably ≤ 1.96.
Note `toml` raised its own MSRV to 1.85 in a **minor** release (1.1.0, 2026-03-23,
CHANGELOG *"Compatibility — Update MSRV to 1.85"*), which is the same discipline the
policy imposes.

`assumes rust-edition = 2024` — satisfied; `toml` 1.1.6 is itself `edition = "2024"`.

`assumes license = MIT OR Apache-2.0` — **gate 1 inapplicable — owner ruling
2026-09-12 (Q7.B)**. Recorded as metadata only: crates.io reports `MIT OR Apache-2.0`
for `toml` 1.1.6.

`assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied and exceeded;
see gate 4 below.

`assumes error-taxonomy-exit-codes = error-contract/v1` (R67, `research/topics/67-error-and-exit-code-contract/DECISION.md`,
revision 4, 2026-09-10) — consumed unchanged. `std::io::Error` on the read →
`RSLB104`/1; `toml::de::Error` → `RSLB202`/2; a parsed-but-invalid value → `RSLB203`/2,
which is R53's to raise. `toml::de::Error::span()` supplies the offending-input
location R67's `hint` requires (executed evidence under `##### Validation strategy`).

No `CONFLICT:` lines.

**Fitness gates, answered before popularity was weighed.**

| Gate | Result |
|---|---|
| 1 — licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)` |
| 2 — MSRV, crate and tree | **Pass.** Crate 1.85; whole-tree maximum 1.85.0; template floor 1.96 (stable 1.98.1). `rust-version` is declared in `Cargo.toml` and the upstream project runs a dedicated `msrv` CI job (`.github/workflows/ci.yml:67–72`). |
| 3 — advisories and `unsafe` | **Pass.** No RustSec page (HTTP 404) and OSV `{}`. `unsafe` posture: `crates/toml/src/lib.rs:150` is `#![forbid(unsafe_code)]`, with the comment *"Makes rustc abort compilation if there are any unsafe blocks in the crate … lets them ensure that there is indeed no unsafe code as opposed to something they couldn't detect (e.g. unsafe added via macro expansion)"*. `toml_writer/src/lib.rs:53` is likewise `#![forbid(unsafe_code)]`. `toml_parser/src/lib.rs:18` is `#![cfg_attr(not(feature = "unsafe"), forbid(unsafe_code))]` and `toml`'s default features request `toml_parser` with `alloc` only — the `unsafe` and `simd` features stay **off**, so the forbid applies. Honest caveat: with `toml_edit` also present, `indexmap` 2.14.2 and `hashbrown` 0.17.1 enter the tree and both do use `unsafe` internally. |
| 4 — CI on `ubuntu-latest, macos-latest` | **Pass, exceeded.** `.github/workflows/ci.yml:38–42` declares `matrix.os: ["ubuntu-latest", "windows-latest", "macos-latest"]` with `runs-on: ${{ matrix.os }}`. Windows is supported (noted, not required). |
| 5 — default features, async coupling | **Pass.** `default = ["std", "serde", "parse", "display"]`. Non-default features available: `preserve_order`, `fast_hash`, `unbounded`, `debug`. **No async-runtime coupling** — no `tokio`, `async-std`, `futures` or executor appears anywhere in the resolved tree (`cargo tree -e normal`, executed). |
| 6 — binary size and compile time | **Pass, quantified.** +190,032 bytes stripped and ~4–5.5 s of cold release build over an empty binary on the stated machine; see `##### Tradeoffs`. Qualitatively: small, and dominated by the `serde_derive` proc-macro chain the template pays for regardless. |

##### Migration implications

There is no Rust template yet, so these are the files P03 creates or touches:

- `Cargo.toml` (workspace root) — add `toml = "1.1.6"` under `[workspace.dependencies]`.
- `crates/<lib>/Cargo.toml` — `toml = { workspace = true }` (the library does the typed read).
- `crates/<lib>/src/config.rs` (or wherever R54 lands discovery) — the `toml::from_str::<ConfigFile>()` call site and the `toml::de::Error` → `RSLB202` mapping.
- `crates/<lib>/src/error.rs` — a `#[from]`-or-explicit `thiserror` variant carrying the parse error's message and span for R67's envelope.
- `Cargo.lock` — regenerated; the six `toml`-side crates appear.
- `deny.toml` (R13) — no new advisory or licence exception needed.

##### Validation strategy

**Executed 2026-09-17** in a throwaway crate under the session scratchpad (nothing
written into the repository), `rustc 1.98.0` / `cargo 1.98.0` on Apple M4 Pro:

| Check | Command | Result |
|---|---|---|
| Typed read (AC1) | `toml::from_str::<ConfigFile>(SRC)` on a document with a header comment, a per-key comment and a trailing comment | `ConfigFile { output: Some(Output { color: Some("auto"), format: Some("text") }) }` — **pass** |
| Re-serialize loses comments (evidence for A1's rejection) | `toml::to_string_pretty(&typed)` | `PLAIN_KEEPS_COMMENT = false` — the header comment is gone. **Confirms the defect.** |
| Located parse error (AC2) | `toml::from_str::<ConfigFile>("[output]\ncolor = \n")` | `Err`; `span() = Some(17..17)`; `Display` first line `TOML parse error at line 2, column 9`; `message() = "string values must be quoted, expected literal string"` — **pass** |
| Whole-tree MSRV (gate 2) | `cargo metadata --format-version 1 --offline` | maximum `rust-version` in the resolved graph = `1.85.0` — **pass** |
| Dependency count | `cargo tree -e normal -p toml` | 6 crates beneath `toml`: `serde_core`, `serde_spanned`, `toml_datetime`, `toml_parser`, `toml_writer`, `winnow` — **no `toml_edit`**, confirming the 1.0 restructure |
| Cost (gate 6) | `/usr/bin/time -p cargo build --release --offline` with a fresh `target/`, two repetitions | 342,000 → 532,032 bytes; 0.21–0.26 s → 4.09–5.60 s |

**Proposed for P03** (not run — no template exists): a `#[test]` asserting AC1 and AC2
against a fixture `rslbp_config.toml`; an `insta` (R33) snapshot of the `RSLB202`
envelope rendered from a deliberately malformed fixture, pinning the `code`, `message`
and `hint` keys R67 specifies; a `cargo test --locked` run under the MSRV toolchain in
the `msrv` CI job so gate 2 stays true as the tree moves.

##### Confidence & re-verify trigger

**Confidence: high.** The crate is the ecosystem default by a margin no other candidate
approaches, is linked by Cargo itself, is `1.x` stable, is conformance-tested against
the TOML project's own suite, has zero advisories in two independent databases, forbids
`unsafe`, and every load-bearing behavioural claim above was executed rather than
inferred. The residual uncertainty is not about `toml` but about the two-member shape,
which R53 and R54 will exercise.

**Re-verify when any of these occurs:** `toml` announces a `2.0`; `toml` declares a
`rust-version` above the template's then-current `stable minus 2` floor; a RustSec
advisory is filed against `toml`, `toml_parser`, `toml_writer`, `toml_datetime`,
`serde_spanned` or `winnow`; `toml-rs/toml` is archived or `epage` announces a
hand-off; or R53 concludes it needs per-field byte spans that `serde_spanned` cannot
supply, which would reopen `toml-span`. Routine re-verification otherwise at the
programme's next dependency-freshness sweep (R34).

##### Sources

- `GET https://crates.io/api/v1/crates/toml` — `crate.recent_downloads` 217,379,722; `crate.downloads` 912,211,500; `max_stable_version` `1.1.6+spec-1.1.0`; `updated_at` `2026-09-10T20:28:39.522017Z`. Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/toml/versions` — newest `yanked: false`: `num` `1.1.6+spec-1.1.0`, `created_at` `2026-09-10T20:28:39.522017Z`, `rust_version` `1.85`, `license` `MIT OR Apache-2.0`, `edition` `2024`. Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/toml/reverse_dependencies?per_page=1` — `meta.total` 18,793. Retrieved 2026-09-17.
- `gh api repos/toml-rs/toml` — `stargazers_count` 1074, `archived` false, `pushed_at` `2026-09-15T14:53:24Z`. Retrieved 2026-09-17.
- `gh api "search/issues?q=repo:toml-rs/toml+is:issue+is:open"` — `total_count` 57. Retrieved 2026-09-17.
- `gh api "repos/toml-rs/toml/issues?state=all&sort=created&direction=desc&per_page=100"` plus `repos/toml-rs/toml/issues/{n}/comments` for #1214, #1213, #1210, #1206, #1188, #1181, #1175, #1172, #1162, #1158 — median 0.67 days, 3 unanswered. Retrieved 2026-09-17.
- `https://rustsec.org/packages/toml.html` — HTTP 404 (no advisories). Control: `https://rustsec.org/packages/time.html` HTTP 200 listing RUSTSEC-2020-0071, RUSTSEC-2026-0009. `POST https://api.osv.dev/v1/query` for `toml` → `{}`. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/crates/toml/Cargo.toml` — features, dependency list, `[[test]]` conformance harnesses. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/crates/toml/CHANGELOG.md` — 1.0.0 on 2026-02-11; 1.1.0 MSRV 1.85 on 2026-03-23; 0.9.10 TOML 1.1 parse support on 2025-12-18. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/crates/toml/src/lib.rs` — rustdoc header; `#![forbid(unsafe_code)]` at line 150. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/Cargo.toml` — `[workspace.package]` `rust-version = "1.85"`, `edition = "2024"`, `license = "MIT OR Apache-2.0"`. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/.github/workflows/ci.yml` — `matrix.os: ["ubuntu-latest", "windows-latest", "macos-latest"]` (lines 38–42); dedicated `msrv` job (lines 67–72). Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml` — lines 115–118, 224–227. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/rust-lang/team/master/teams/cargo.toml` — `epage` at line 10. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/rust-lang/rust/stable/src/version` — `1.98.1`. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/dtolnay/basic-toml/master/README.md` and `.../Cargo.toml`; `gh api repos/dtolnay/basic-toml`. Retrieved 2026-09-17.
- `https://lib.rs/keywords/toml` — `toml` ranked first, `toml_edit` second. Retrieved 2026-09-17.
- py pin `b08bccfb`: `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/config.py` — lines 40, 45, `_read_toml`, `_read_layer`, `_read_explicit`, `read_config_for_write`, `write_config_data`. Read 2026-09-17.
- ts pin `cb1cbcb2`: `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/config.ts` — line 20, `readConfigFile`. Read 2026-09-17.
- `research/topics/67-error-and-exit-code-contract/DECISION.md`, revision 4, 2026-09-10 — `error-contract/v1`; rows `RSLB104`, `RSLB202`, `RSLB203`. Read 2026-09-17.

#### toml_edit

##### Landscape

Bin: **built-in / first-party toolchain** — same workspace, same maintainer, same
release train as `toml`, and linked by Cargo for exactly the operation recommended here
(`rust-lang/cargo` `Cargo.toml:116`: `toml_edit = { version = "0.25.10", features = ["serde"] }`).
Category: format-preserving TOML parsing and editing. It has essentially no competitor
in Rust: no other crate in the surveyed field claims to preserve comments, spacing and
relative item order across a read-modify-write cycle. `taplo` 0.14.0 comes closest but
is a formatter/LSP toolkit whose last release was 2025-05-22, not a config-editing
dependency.

##### Principles and implementation

`toml_edit` carries P3 in full — *"parse and modify toml documents, while preserving
comments, spaces and relative order of items"* (`crates/toml_edit/src/lib.rs` lines 1–7,
retrieved 2026-09-17) — and P2 on the write path (its `TomlError` carries a span, so a
refusal to modify an unparsable file is reportable as `RSLB202`). It carries **no part
of P4**: like `toml`, it performs no file I/O, so F243's atomic-0600 write remains
`std::fs` work. The rustdoc's own worked example shows the guarantee:
`assert_eq!(doc.to_string(), toml)` for an unmodified document, then a targeted
`doc["a"]["b"]["c"]["d"] = value("hello")` that leaves `"hello" = 'toml!' # comment`
untouched. Reference implementations: `rust-lang/cargo` (`cargo add`, `cargo remove`
and every manifest edit go through it), `starship/starship`, `astral-sh/uv`.

##### Dominant choice

`toml_edit` **0.25.15+spec-1.1.0**, released 2026-09-11T01:44:08Z, `yanked: false`.

| Figure | Value | Endpoint / rule |
|---|---|---|
| 90-day downloads | 198,995,334 | `GET https://crates.io/api/v1/crates/toml_edit` → `crate.recent_downloads` |
| All-time downloads | 820,233,998 | same → `crate.downloads` |
| Last release | `0.25.15+spec-1.1.0`, `2026-09-11T01:44:08.521316Z` | `GET https://crates.io/api/v1/crates/toml_edit/versions`, newest `yanked: false` |
| Stars / archived / pushed | 1,074 / `false` / `2026-09-15T14:53:24Z` | `gh api repos/toml-rs/toml` (same repository as `toml`) |
| Open issues | 57 | `gh api "search/issues?q=repo:toml-rs/toml+is:issue+is:open"` → `total_count` (repository-level; the tracker is not split per crate) |
| Issue responsiveness | median **0.67 days**; **3 of 10** unanswered | Same repository, same 10 issues and method as `toml`; the tracker is shared, so the figure is shared |
| Advisories | **none** | `https://rustsec.org/packages/toml_edit.html` → HTTP 404; OSV query → `{}` |
| Reverse dependencies | 1,595 | `GET https://crates.io/api/v1/crates/toml_edit/reverse_dependencies?per_page=1` → `meta.total` |

Maintenance state by rubric: **active**. Released 5 days before retrieval, from the same
repository and release train as `toml`.

##### Qualified shortlist

- **`taplo` 0.14.0** — 90-day downloads 716,818; all-time 3,481,354; last release
  2025-05-22T23:38:33Z (16 months before retrieval — a rubric trigger to investigate,
  and the investigation finds a toolkit whose consumers are editors and a CLI, not a
  library used for programmatic single-key edits). Maintenance: **stable-quiet**, with
  no concrete `at-risk` signal found; figures for the repository were not retrieved.
  Not recommended: wrong shape (a formatter/LSP toolkit, a much larger surface, and no
  documented single-key edit API comparable to `DocumentMut`).
- **Hand-rolled line-oriented editing** (no crate: read the file, locate `key = ` with
  a regex or manual scan, splice the new value). Rejected: it re-implements TOML lexing
  badly, cannot handle dotted keys, multi-line strings, inline tables or arrays of
  tables, and silently corrupts documents it does not understand — the opposite of P3.

##### Excluded by gate

None. No candidate evaluated for this member failed a gate. `basic-toml` and `tomling`
were excluded under the `toml` member and are not re-evaluated here, since neither
claims format preservation and so neither is a candidate for this role at all.

##### Up-and-comers

None with the format-preserving capability. `toml-span` 0.7.1 and `boml` 2.0.0 are
read-only deserializers (figures under the `toml` member); neither writes TOML at all,
so neither can serve this role. This is a **real gap in the field**, and it is why the
recommendation accepts a `0.x` crate for this member: there is no `1.x` alternative to
prefer. Recorded honestly as a concentration risk rather than papered over.

##### Fit for this template

| Surface | Fit |
|---|---|
| CLI (`rslbp`) | This is the whole point. `rslbp config set <section>.<key> <value>` parses the user's file into a `DocumentMut`, mutates one value, and renders the document back with the user's comments and ordering intact. Verified by execution below. |
| Library (`rs_launch_blueprint`) | Fine wherever the `config set` logic lives. `toml_edit` does no file or stream I/O, installs no handler, and needs no `anyhow` — R67's library-crate rules hold. No unsafe appears in its library source. |
| Web service (optional Cargo feature) | Not used. The web surface never writes the CLI's config file. The dependency can be confined to whichever crate owns `config set` if P03 prefers a narrower graph. |
| py/ts precedent | Supersedes both. py's `tomli_w.dumps` and ts's `stringify` produce a correct but comment-free file; `toml_edit` produces a correct file that is still the user's file. |

##### Recommendation

`toml_edit = "0.25.15"` with **default features only** (`parse`, `display`). Do **not**
enable its `serde` feature: `toml` owns the typed read, and leaving `serde` off keeps
`serde_core` and `serde_spanned` out of `toml_edit`'s own feature closure.

**The edit recipe P03 must use, with the trap that was found by executing it.** The
obvious assignment `doc["output"]["format"] = value("json")` replaces the whole `Item`
*including its decor*, so a trailing comment on that key's line is lost — measured:
`NAIVE_KEEPS_TRAILING = false`. Mutating the existing `Value` in place and restoring
its decor keeps everything — measured: `DECOR_KEEPS_TRAILING = true`,
`DECOR_APPLIED = true`:

```rust
if let toml_edit::Item::Value(v) = &mut doc["output"]["format"] {
    let decor = v.decor().clone();
    *v = toml_edit::Value::from("json");
    *v.decor_mut() = decor;
}
```

Adding a key that does not yet exist needs no such care: `doc["output"]["width"] = value(100i64)`
left the header comment, the per-key comment and the trailing comment all intact
(`NEWKEY_KEEPS_ALL = true true true`).

##### Ranked runner-up

1. **`toml` alone with full re-serialization** (design A1). Drops AC3 — the template
   would ship py's and ts's defect. Acceptable only if the owner decides comment
   preservation is not worth 136 KB and four crates.
2. **`taplo` 0.14.0.** Much larger surface, 16 months since release, no comparable
   single-key edit API.
3. **Hand-rolled line editing.** Rejected on correctness, above.

##### Tradeoffs

- **Gained:** AC3 and AC4 — the user's comments, key order and spacing survive every
  `config set`; a defect both source repositories ship is designed out.
- **Given up:** a `1.x` stability guarantee. `toml_edit` is `0.25.x`, so any breaking
  change arrives as a minor bump and the template's Dependabot lane (R19) will see it
  as such. Mitigation: the crate is on its 25th minor line with a stable `DocumentMut`
  API, moves in lockstep with `toml`, and is depended on by Cargo — a gratuitous break
  is expensive for its maintainer too.
- **Cost (measured, same machine and profile, executed 2026-09-17):** adding
  `toml_edit` *on top of* `toml` + `serde` moved the stripped release binary from
  **532,032** to **667,952** bytes (**+135,920**, about +26%) and the cold release
  build from 4.09–5.60 s to 4.37–6.13 s (two repetitions; the ranges overlap, so the
  build-time delta is within measurement noise at this size). The dependency graph grew
  by exactly **four** crates — `toml_edit`, `indexmap` 2.14.2, `equivalent` 1.0.2,
  `hashbrown` 0.17.1 — because `toml_parser`, `toml_writer`, `toml_datetime` and
  `winnow` are shared with `toml` (`cargo tree -e normal`, executed).
- **Risk accepted:** `indexmap` and `hashbrown` use `unsafe` internally. They are among
  the most-audited crates in the ecosystem and carry no open advisory (OSV and RustSec
  checked), but the template can no longer claim an entirely `unsafe`-free config path.
  R06's `unsafe` policy governs first-party code, which is unaffected.

##### Parameters

`owns` — none.

`assumes msrv-policy = stable minus 2 minor versions, …` — satisfied. `toml_edit`
0.25.15 declares `rust-version = "1.85"` (workspace-inherited). Its two crates not
shared with `toml` declare `indexmap` 1.85, `hashbrown` 1.85.0, `equivalent` 1.6
(`cargo metadata --format-version 1`, executed 2026-09-17). Tree maximum stays
**1.85.0** ≤ the 1.96 floor derived from stable 1.98.1.

`assumes rust-edition = 2024` — satisfied; `toml_edit` 0.25.15 is `edition = "2024"`.

`assumes license = MIT OR Apache-2.0` — **gate 1 inapplicable — owner ruling
2026-09-12 (Q7.B)**. Metadata only: crates.io reports `MIT OR Apache-2.0`.

`assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied; same CI workflow
as `toml`, `matrix.os: ["ubuntu-latest", "windows-latest", "macos-latest"]`.

`assumes error-taxonomy-exit-codes = error-contract/v1` (R67, revision 4, 2026-09-10) —
consumed unchanged. `toml_edit::TomlError` on the write-path parse → `RSLB202`/2, which
is the mechanism behind P3's "refuse to modify an unparsable file" (AC6). Executed:
`"[output]\ncolor = \n".parse::<DocumentMut>()` returned `Err` with
`span() = Some(17..17)` and first `Display` line `TOML parse error at line 2, column 9`.

No `CONFLICT:` lines.

**Fitness gates, answered before popularity was weighed.**

| Gate | Result |
|---|---|
| 1 — licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)` |
| 2 — MSRV, crate and tree | **Pass.** Crate 1.85; the four crates it adds top out at 1.85.0; floor 1.96. `rust-version` declared in `Cargo.toml` (workspace-inherited) and covered by the repository's `msrv` CI job. |
| 3 — advisories and `unsafe` | **Pass, with a stated caveat.** No RustSec page (HTTP 404); OSV `{}`. `unsafe` posture: no `unsafe` appears anywhere in `toml_edit`'s library source — `gh api "search/code?q=repo:toml-rs/toml+unsafe+in:file+path:crates/toml_edit"` returned `total_count: 1`, and the single hit is `crates/toml_edit/tests/compliance/parse.rs`, a test file. Unlike `toml` it carries no `#![forbid(unsafe_code)]` attribute, so this is an observed absence rather than a compiler-enforced one. Caveat: its transitive `indexmap`/`hashbrown` do use `unsafe`. |
| 4 — CI on `ubuntu-latest, macos-latest` | **Pass, exceeded.** Same `.github/workflows/ci.yml`, `matrix.os: ["ubuntu-latest", "windows-latest", "macos-latest"]`. Windows supported (noted, not required). |
| 5 — default features, async coupling | **Pass.** `default = ["parse", "display"]`. Non-default: `serde`, `debug`, `unbounded`. `indexmap` is a **non-optional** dependency, so it enters the tree whatever features are chosen. **No async-runtime coupling** — no runtime, executor or futures crate in the resolved tree. |
| 6 — binary size and compile time | **Pass, quantified.** +135,920 bytes stripped on top of `toml`; build-time delta within noise; +4 crates. See `##### Tradeoffs`. |

##### Migration implications

- `Cargo.toml` (workspace root) — add `toml_edit = "0.25.15"` under `[workspace.dependencies]`.
- The crate that owns `config set` (library, or the CLI crate if P03 puts command logic there) — `toml_edit = { workspace = true }`.
- `crates/<lib>/src/config.rs` (or a sibling `config/write.rs`) — the `DocumentMut` parse, the decor-preserving assignment shown above, and `doc.to_string()` handed to F243's writer.
- `crates/<lib>/src/error.rs` — a `thiserror` variant for `toml_edit::TomlError` mapping to `RSLB202`, distinct from the read-path variant only if P03 wants distinct messages; the code is the same.
- The F243 atomic-0600 writer (R54/F243's file, not this item's) — receives a `String`, unchanged by this choice.
- `Cargo.lock` — regenerated; `toml_edit`, `indexmap`, `equivalent`, `hashbrown` appear.
- `deny.toml` (R13) — no new advisory or licence exception needed.

##### Validation strategy

**Executed 2026-09-17**, same throwaway crate and machine as the `toml` member; the
fixture document was `# header comment` / `[output]` / `# why auto` /
`color = "auto"` / `format = "text"   # trailing note`:

| Check | Result |
|---|---|
| AC3 — surgical edit keeps comments | `doc["output"]["format"] = value("json")` → `EDIT_KEEPS_COMMENT = true`, `EDIT_APPLIED = true`, but `EDIT_KEEPS_INLINE = false`. **Partial pass**, and the cause is the decor-replacement trap documented under `##### Recommendation`. |
| AC3 — decor-preserving variant | Mutating the `Value` in place and restoring `decor()` → `DECOR_KEEPS_TRAILING = true`, `DECOR_APPLIED = true`. **Full pass.** Rendered output: `# header comment` / `[output]` / `# why auto` / `color = "auto"` / `format = "json"   # trailing note`. |
| AC3 — new key | `doc["output"]["width"] = value(100i64)` → `NEWKEY_KEEPS_ALL = true true true`. **Pass.** |
| AC4 — edited document re-reads | `toml::from_str::<ConfigFile>(&edited)` → `ConfigFile { output: Some(Output { color: Some("auto"), format: Some("json") }) }`. **Pass** — and this is also the cross-member compatibility proof. |
| AC6 — refusal on unparsable input | `"[output]\ncolor = \n".parse::<DocumentMut>()` → `Err`, `span() = Some(17..17)`, `TOML parse error at line 2, column 9`. **Pass.** |
| Gate 6 | 532,032 → 667,952 bytes; build 4.09–5.60 s → 4.37–6.13 s; +4 crates via `cargo tree -e normal`. |

**Proposed for P03** (not run): a golden-file test that runs `rslbp config set` against
a fixture carrying a header comment, an inter-key comment, a trailing comment and a
deliberately unusual key order, then byte-compares the result against an expected file
differing in exactly one value — this is AC3 as a regression gate, and it is the check
that would catch the decor trap if someone later simplifies the assignment. Plus an
AC6 test asserting exit code `2` and error code `RSLB202` when the existing file is
corrupt, and an AC5 test (F243's, listed for completeness) asserting mode `0600` and
that an interrupted write leaves the original intact.

##### Confidence & re-verify trigger

**Confidence: medium-high.** High on capability — the format-preserving behaviour was
executed here, not inferred, including the non-obvious decor trap; and Cargo, uv and
starship all ship the crate. The deduction from high is the `0.x` version line and the
absence of any alternative should the crate stall: this member is a genuine single
point of dependency, recorded under `##### Up-and-comers` rather than hidden.

**Re-verify when any of these occurs:** `toml_edit` reaches `1.0` (adopt promptly — it
removes this member's only real weakness); a breaking `0.26` lands and the `DocumentMut`
decor API changes; a RustSec advisory is filed against `toml_edit`, `indexmap`,
`hashbrown` or `equivalent`; `toml-rs/toml` is archived or hands off; Cargo drops
`toml_edit` from its own manifest; or P03 concludes the comment-preservation benefit is
not worth 135,920 bytes, which would reopen design A1. Routine re-verification at R34's
next freshness sweep.

##### Sources

- `GET https://crates.io/api/v1/crates/toml_edit` — `crate.recent_downloads` 198,995,334; `crate.downloads` 820,233,998; `max_stable_version` `0.25.15+spec-1.1.0`; `updated_at` `2026-09-11T01:44:08.521316Z`. Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/toml_edit/versions` — newest `yanked: false`: `num` `0.25.15+spec-1.1.0`, `created_at` `2026-09-11T01:44:08.521316Z`, `rust_version` `1.85`, `license` `MIT OR Apache-2.0`, `edition` `2024`. Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/toml_edit/reverse_dependencies?per_page=1` — `meta.total` 1,595. Retrieved 2026-09-17.
- `gh api repos/toml-rs/toml`; `gh api "search/issues?q=repo:toml-rs/toml+is:issue+is:open"` — as cited under the `toml` member (shared repository). Retrieved 2026-09-17.
- `https://rustsec.org/packages/toml_edit.html` — HTTP 404 (no advisories); `POST https://api.osv.dev/v1/query` for `toml_edit` → `{}`. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/crates/toml_edit/Cargo.toml` — `default = ["parse", "display"]`; non-optional `indexmap = { version = "2.13.0", features = ["std"] }`; dev-dependency `toml_types = { path = "../toml", package = "toml", default-features = false, features = ["serde", "preserve_order"] }`. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/crates/toml_edit/src/lib.rs` — rustdoc header lines 1–45, including the `assert_eq!(doc.to_string(), toml)` fidelity example. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/README.md` — the documented `toml` / `toml_edit` division of labour. Retrieved 2026-09-17.
- `gh api "search/code?q=repo:toml-rs/toml+unsafe+in:file+path:crates/toml_edit"` — `total_count` 1, sole hit `crates/toml_edit/tests/compliance/parse.rs`. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/toml-rs/toml/main/.github/workflows/ci.yml` — OS matrix and `msrv` job. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml` line 116; `https://raw.githubusercontent.com/starship/starship/master/Cargo.toml` lines 88–89; `https://raw.githubusercontent.com/astral-sh/uv/main/Cargo.toml` lines 311–324. Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/taplo` — `recent_downloads` 716,818; `downloads` 3,481,354; newest `0.14.0`, `2025-05-22T23:38:33.564Z`. Retrieved 2026-09-17.
- Executed probe (session scratchpad, nothing written to the repository): `cargo build --release`, `cargo run`, `cargo tree -e normal`, `cargo metadata --format-version 1`, `rustc 1.98.0` / `cargo 1.98.0`, Apple M4 Pro, 14 cores, 2026-09-17.

### Compatibility

The two members are not merely compatible; they are the same project, and three
independent well-regarded consumers ship them as a pair.

| Proof | Evidence | Retrieved |
|---|---|---|
| **One workspace, one release train** | Both crates live in `toml-rs/toml` and inherit `[workspace.package]`: `edition = "2024"`, `rust-version = "1.85"`, `license = "MIT OR Apache-2.0"` (`https://raw.githubusercontent.com/toml-rs/toml/main/Cargo.toml` lines 5–9). They release together: `toml` 1.1.6 at `2026-09-10T20:28:39Z`, `toml_edit` 0.25.14 at `2026-09-10T20:28:40Z` and 0.25.15 at `2026-09-11T01:44:08Z`. | 2026-09-17 |
| **Upstream tests them together** | `toml_edit`'s own `[dev-dependencies]` include `toml_types = { path = "../toml", package = "toml", default-features = false, features = ["serde", "preserve_order"] }` — the `toml_edit` test suite links `toml`. Both also run the same `toml-lang/toml-test` corpus (`toml-test-harness` 1.14.0, `toml-test-data` 2.14.0). | 2026-09-17 |
| **Shared internals, no version skew** | Executed `cargo tree -e normal` on a crate depending on both resolves **one** copy of each shared crate: `toml_parser` 1.1.3, `toml_writer` 1.1.2, `toml_datetime` 1.1.1, `winnow` 1.0.4 — no duplicate-version compilation. | 2026-09-17 |
| **Shared adopters** | `rust-lang/cargo` (`toml` 1.1.5 + `toml_edit` 0.25.10), `astral-sh/uv` (`toml` 1.1.0 + `toml_edit` 0.25.8), `starship/starship` (`toml` 1.1.6 + `toml_edit` 0.25.15). Standing figures under `### Landscape`. | 2026-09-17 |
| **Executed round-trip across the seam** | A document edited through `toml_edit::DocumentMut` re-read cleanly through `toml::from_str::<ConfigFile>()` into the expected typed value (`REREAD = ConfigFile { output: Some(Output { color: Some("auto"), format: Some("json") }) }`). This is the version matrix the prompt asks for, run at `toml` 1.1.6 + `toml_edit` 0.25.15. | 2026-09-17 |

**Version matrix P03 should pin and test:** `toml` `1.1` (caret, `1.1.6` resolved) with
`toml_edit` `0.25` (caret, `0.25.15` resolved), both inherited from
`[workspace.dependencies]`, with `Cargo.lock` committed and `cargo test --locked` in CI
(R41's lockfile-freshness lane governs the lockfile itself).

### Parameters

`owns` — **none.** R52 owns no row in `docs/port/PARAMETERS.md`; the registry's `owns`
column for R52 is `—` and this report does not claim one.

`assumes rust-edition = 2024` — both members are themselves edition 2024.

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — the combined resolved tree's
maximum `rust-version` is **1.85.0**, against a floor of **1.96** derived from stable
**1.98.1** (`https://raw.githubusercontent.com/rust-lang/rust/stable/src/version`,
retrieved 2026-09-17). Headroom: 11 minor versions.

`assumes license = MIT OR Apache-2.0` — **gate 1 recorded as
`inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every candidate in this report;
nothing was excluded on licence. Metadata for the record: both members report
`MIT OR Apache-2.0` on crates.io.

`assumes target-os-matrix = ubuntu-latest, macos-latest` — both members' upstream CI runs
`ubuntu-latest`, `windows-latest` and `macos-latest`, covering the matrix and more.

`assumes error-taxonomy-exit-codes = error-contract/v1` (owned by R67,
`research/topics/67-error-and-exit-code-contract/DECISION.md`, revision 4, 2026-09-10) —
consumed unchanged. This item's crates satisfy R67's "surface a distinguishable error"
requirement: `std::io::Error` → `RSLB104`/1; `toml::de::Error` and
`toml_edit::TomlError` → `RSLB202`/2, both carrying a byte span and a line/column
`Display` that R67's `hint` field can use to name the offending input; a parsed-but-
invalid value is `RSLB203`/2 and belongs to R53.

`assumes` (not a registry parameter, recorded for the reader) F224 config format = TOML,
F227 filename `<tool>_config.toml`, F243 atomic write at mode 0600 — all
`COMMON → REUSE`, inherited, untouched by this item.

**No `CONFLICT:` lines.** Nothing in this recommendation requires a consumed parameter
to change.

### Migration implications

File-level changes P03 makes in the template that does not yet exist:

| File | Change |
|---|---|
| `Cargo.toml` (workspace root) | Add to `[workspace.dependencies]`: `toml = "1.1.6"` and `toml_edit = "0.25.15"`. No feature overrides — defaults for both; specifically **not** `toml`'s `preserve_order` and **not** `toml_edit`'s `serde`. |
| `crates/<lib>/Cargo.toml` | `toml = { workspace = true }`; `toml_edit = { workspace = true }` (or confine `toml_edit` to whichever crate owns `config set`). |
| `crates/<lib>/src/config.rs` (R54 owns discovery; this is the parse call site) | `toml::from_str::<ConfigFile>(&text)` for the read path. |
| `crates/<lib>/src/config/write.rs` (new, or a sibling module) | `src.parse::<toml_edit::DocumentMut>()`, the decor-preserving in-place assignment, `doc.to_string()`. Hands the rendered `String` to the F243 writer; performs no file I/O itself. |
| F243's atomic-0600 writer (R54/F243's file) | Unchanged by this item, and **required regardless of crate choice** — see the HIGH-question answer below. |
| `crates/<lib>/src/error.rs` | `thiserror` variants wrapping `toml::de::Error` and `toml_edit::TomlError`, both mapping to `RSLB202`, plus the `std::io::Error` variant mapping to `RSLB104`. |
| `Cargo.lock` | Regenerated. Ten crates enter for this item: `toml`, `toml_edit`, `toml_parser`, `toml_writer`, `toml_datetime`, `serde_spanned`, `winnow`, `indexmap`, `equivalent`, `hashbrown`. |
| `deny.toml` (R13) | No new advisory or licence exception required. |
| `tests/` | The AC3 golden-file test and the AC6 refusal test named under `##### Validation strategy`. |

**Answer to HIGH question 2, stated plainly because it changes what P03 builds.** No
TOML crate in the Rust field performs file I/O. `toml`, `toml_edit`, `basic-toml`,
`toml-span` and `boml` all take and return `&str`/`String`. Therefore F243's
"mode 0600 from creation, then atomic replace" guarantee is hand-rolled `std::fs`
**whatever crate is chosen**, and it is not an argument for or against any candidate.
The Rust shape of py's `mkstemp` + `os.replace` is
`std::fs::OpenOptions::new().write(true).create_new(true).mode(0o600)` (via
`std::os::unix::fs::OpenOptionsExt`, under `#[cfg(unix)]`) on a sibling temp path,
`write_all`, `sync_all`, then `std::fs::rename` — `rename` being portable and only the
permission bit Unix-specific, which the fixed `ubuntu-latest, macos-latest` matrix
permits. The `tempfile` crate is a reasonable convenience for the temp-path half
(`tempfile::Builder::new().permissions(...)`) but is **not** a member of this bundle: it
is file-I/O infrastructure belonging to F243/R54, not TOML handling, and this item takes
no position on whether P03 adopts it.

### Validation strategy

**Executed 2026-09-17** — a throwaway crate in the session scratchpad only; nothing was
written into the repository and no repository state was modified. Machine: Apple M4
Pro, 14 cores, macOS; toolchain `rustc 1.98.0 (88d9e12ae 2026-08-18)`, `cargo 1.98.0
(797e8a9bc 2026-08-05)`; profile `opt-level = 3`, `lto = false`, `strip = true`; a fresh
`target/` directory before each timing run; two repetitions for every timing.

```
# 1. dependency shape and MSRV of the whole resolved graph
cargo tree -e normal                 # -> toml (6 deps) + toml_edit adds exactly 4 crates
cargo metadata --format-version 1    # -> max rust-version in the graph = 1.85.0

# 2. behaviour (the acceptance criteria)
cargo run                            # the probe below

# 3. cost
/usr/bin/time -p cargo build --release --offline   # per variant, fresh target/
stat -f%z target/release/<bin>
```

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| AC1 typed read | fields populated | `ConfigFile { output: Some(Output { color: Some("auto"), format: Some("text") }) }` | pass |
| AC2 located parse error | distinct error with a position | `toml::de::Error` `span() = Some(17..17)`, `TOML parse error at line 2, column 9`, `message() = "string values must be quoted, expected literal string"` | pass |
| A1 loses comments | comments gone | `PLAIN_KEEPS_COMMENT = false` | confirms the defect being designed out |
| AC3 naive edit | comments kept | `EDIT_KEEPS_COMMENT = true`, `EDIT_APPLIED = true`, `EDIT_KEEPS_INLINE = false` | partial — the decor trap |
| AC3 decor-preserving edit | all comments kept | `DECOR_KEEPS_TRAILING = true`, `DECOR_APPLIED = true` | pass |
| AC3 new key | nothing disturbed | `NEWKEY_KEEPS_ALL = true true true` | pass |
| AC4 write/read closure | edited file re-reads | `REREAD = ConfigFile { output: Some(Output { color: Some("auto"), format: Some("json") }) }` | pass |
| AC6 refuse corrupt file | parse error before mutation | `toml_edit::TomlError` `span() = Some(17..17)`, `TOML parse error at line 2, column 9` | pass |
| Gate 2 | tree MSRV ≤ 1.96 | 1.85.0 | pass |
| Gate 6 | quantified cost | base 342,000 B / 0.21–0.26 s → `toml` 532,032 B / 4.09–5.60 s → both 667,952 B / 4.37–6.13 s; `basic-toml` comparison 478,976 B / 6.27 s | pass |

**Not executed, proposed for P03** (distinguished as the prompt requires): AC5 (F243's
mode-0600-from-creation and interrupted-write survival) was not tested here because it
belongs to the file-writing layer this item does not choose; the `RSLB202` envelope
snapshot test; the golden-file `config set` regression gate; and a `cargo test --locked`
run on the MSRV toolchain in CI. None of these can run before P03 builds the template.

**Gap recorded honestly:** no benchmark of parse throughput was run, and none is cited,
because the workload is a sub-kilobyte file read once per process — the prompt's
instruction not to infer an absolute fastest option from unlike benchmarks is met by
declining to rank on speed at all.

### Confidence & re-verify trigger

**Overall confidence: high on the stack, medium-high on the second member.**

What makes it high: `toml` is the ecosystem default by an order of magnitude on every
retrieved adoption figure, is linked by Cargo itself, is `1.x`, forbids `unsafe`, and
has no advisory in either RustSec or OSV. The two-crate pairing is not this report's
invention — it is what the maintainers document, what Cargo ships, and what two of the
most-starred modern Rust CLIs (`uv`, 89,887 stars; `starship`, 59,920 stars) ship. Every
behavioural claim that decides between designs was executed on this machine at the
recommended versions, including the non-obvious decor trap that a code review would
otherwise have missed.

What holds it back from full confidence: `toml_edit` is `0.25.x`, and the survey found
**no** alternative with its capability — a genuine concentration risk, recorded rather
than smoothed over. And the whole recommendation is research for a template that does
not exist; AC5's interaction with F243's writer, and R53's exact schema needs, can only
be confirmed in P03.

**Re-verify when any of these occurs:**

1. `toml_edit` reaches `1.0` — adopt promptly; it removes this stack's only structural weakness.
2. `toml` announces a `2.0`, or either crate declares a `rust-version` above the then-current `stable minus 2` floor.
3. A RustSec advisory is filed against any of `toml`, `toml_edit`, `toml_parser`, `toml_writer`, `toml_datetime`, `serde_spanned`, `winnow`, `indexmap`, `hashbrown`, `equivalent`.
4. `toml-rs/toml` is archived, or `epage` announces a hand-off, or Cargo drops either crate from its own manifest.
5. R53 concludes it needs per-field byte spans beyond what `serde_spanned` and `toml::de::Error::span()` provide — that would reopen `toml-span`.
6. The owner decides comment preservation is not worth 135,920 stripped bytes and four crates — that collapses the stack to design A1, `toml` alone, and knowingly reproduces the source repositories' defect.
7. Otherwise, at R34's next scheduled dependency-freshness sweep.

### Sources

Every URL below was retrieved on **2026-09-17 UTC** (2026-09-16 local) unless the line
says otherwise. Per-member source lists appear under each member's `##### Sources`; this
list carries the cross-cutting and repository sources.

**Registry and advisory endpoints**
- `GET https://crates.io/api/v1/crates/{toml, toml_edit, basic-toml, toml_write, toml_parser, toml_datetime, serde_spanned, toml-span, tomling, boml, taplo, toml_writer}` — `crate.recent_downloads`, `crate.downloads`, `max_stable_version`, `updated_at`, `repository`.
- `GET https://crates.io/api/v1/crates/{name}/versions` — newest `yanked: false` entry's `num`, `created_at`, `rust_version`, `license`, `edition`.
- `GET https://crates.io/api/v1/crates/{name}/reverse_dependencies?per_page=1` — `meta.total`: `toml` 18,793; `toml_edit` 1,595; `basic-toml` 36; `toml-span` 29; `boml` 4.
- `https://rustsec.org/packages/{name}.html` — HTTP 404 for `toml`, `toml_edit`, `basic-toml`, `toml-span`, `toml_parser`, `toml_writer`, `serde_spanned`, `toml_datetime`, `boml`. Control HTTP 200 pages: `time` (RUSTSEC-2020-0071, RUSTSEC-2026-0009), `atty` (RUSTSEC-2021-0145, RUSTSEC-2024-0375).
- `POST https://api.osv.dev/v1/query` with `{"package":{"name":"<name>","ecosystem":"crates.io"}}` — `{}` for `toml`, `toml_edit`, `basic-toml`, `toml-span`.

**GitHub (via `gh api`, authenticated)**
- `gh api repos/{toml-rs/toml, dtolnay/basic-toml, EmbarkStudios/toml-span, bright-shard/boml, rust-lang/cargo, astral-sh/uv, starship/starship}` — `stargazers_count`, `archived`, `pushed_at`.
- `gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"` — `total_count`: toml-rs/toml 57; dtolnay/basic-toml 4; EmbarkStudios/toml-span 3; bright-shard/boml 0.
- `gh api "repos/toml-rs/toml/issues?state=all&sort=created&direction=desc&per_page=100"` and `repos/toml-rs/toml/issues/{n}/comments?per_page=100` for the 10 most recently opened non-PR issues.
- `gh api "search/code?q=repo:toml-rs/toml+unsafe+in:file+path:crates/toml_edit"` and `…path:crates/toml_parser`.

**Maintainer documentation and upstream source**
- `https://raw.githubusercontent.com/toml-rs/toml/main/README.md`, `Cargo.toml`, `.github/workflows/ci.yml`, `crates/toml/Cargo.toml`, `crates/toml/CHANGELOG.md`, `crates/toml/src/lib.rs`, `crates/toml_edit/Cargo.toml`, `crates/toml_edit/src/lib.rs`, `crates/toml_parser/Cargo.toml`, `crates/toml_parser/src/lib.rs`, `crates/toml_writer/src/lib.rs`.
- `https://raw.githubusercontent.com/dtolnay/basic-toml/master/README.md` and `Cargo.toml`.

**Rust project publications**
- `https://raw.githubusercontent.com/rust-lang/rust/stable/src/version` — `1.98.1`.
- `https://raw.githubusercontent.com/rust-lang/team/master/teams/cargo.toml` — `epage` at line 10.
- `https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml` — lines 115–118, 224–227.

**Practice evidence (adopter manifests)**
- `https://raw.githubusercontent.com/astral-sh/uv/main/Cargo.toml` — lines 311–324.
- `https://raw.githubusercontent.com/starship/starship/master/Cargo.toml` — lines 88–89.

**Independent index**
- `https://lib.rs/keywords/toml` — `toml` first, `toml_edit` second.
- `https://lib.rs/config` — the Configuration category, used only to confirm that the general-purpose config crates (`config`, `figment`) are a different category from TOML parsing and are not candidates here.

**Programme sources, read through their pins**
- `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/config.py` — `import tomllib` (line 40), `import tomli_w` (line 45), `_read_toml`, `_read_layer`, `_read_explicit`, `read_config_for_write`, `write_config_data`.
- `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/config.ts` — `import { parse, stringify } from 'smol-toml'` (line 20), `readConfigFile`.
- `docs/port/COMMONALITY.md` rows F224 (line 228), F225 (229), F226 (230), F227 (231), F243 (247).
- `docs/port/PARAMETERS.md` — the four fixed rows and `error-taxonomy-exit-codes`.
- `research/topics/67-error-and-exit-code-contract/DECISION.md`, revision 4, 2026-09-10 — `error-contract/v1`; rows `RSLB104`, `RSLB202`, `RSLB203`; Disagreement 4.
- `docs/planning/p02/owner-decisions.md` section 7 — ruling Q7.B, licence compatibility not evaluated.

**Method notes.** Registry figures came from `https://crates.io/api/v1/crates/<name>`,
`/versions` and `/reverse_dependencies` with a `User-Agent` header set, per the prompt's
figure table. GitHub figures came from `gh api` (authenticated via the machine's `gh`
keyring, per the coordinator's mid-task correction); open-issue counts used
`search/issues` `total_count`, never `open_issues_count` — for `toml-rs/toml` the two
differ, 57 against 71, because the latter counts pull requests. Advisory checks used
`https://rustsec.org/packages/<name>.html`, whose 404 was first validated as meaning
"no advisory has ever been filed" against two known-vulnerable controls (`time`,
`atty`, both HTTP 200 with advisory IDs listed), and were cross-checked against
`https://api.osv.dev/v1/query`. Upstream manifests, changelogs, rustdoc headers and CI
workflows were read from `raw.githubusercontent.com`. The behavioural and cost figures
were produced by building and running a throwaway crate in the session scratchpad with
`rustc 1.98.0` / `cargo 1.98.0` on an Apple M4 Pro; nothing was written into the
repository and no git state was modified. Source-repository evidence was read through
the programme pins (`b08bccfb` for py, `cb1cbcb2` for ts), never from a working tree.

*Could not verify (recorded as unverified, not guessed):*
(1) **blessed.rs** — `https://raw.githubusercontent.com/nicoburns/blessed-rs/main/data/crates.json`
returned HTTP 200 and 76,423 bytes but did not parse as a single JSON document
(`Extra data: line 1 column 4`), and the rendered `https://blessed.rs/crates` page is
JavaScript-driven with no TOML text in its HTML; no blessed.rs recommendation is cited.
(2) **Issue responsiveness for `basic-toml`, `toml-span`, `boml` and `taplo`** — not
computed; `basic-toml` is excluded by gate and archived, and the other three are
shortlist or watch-list entries whose selection did not turn on responsiveness.
(3) **`taplo` repository figures** (stars, archived, pushed_at, open issues) — not
retrieved; only its crates.io figures are cited, and it is not recommended.
(4) **`basic-toml` gate 3 `unsafe` posture and gate 4 CI matrix** — not read, moot after
its gate 2 failure.
(5) **Annual Rust survey** — deliberately not cited: it does not rank TOML or
serialization crates, and stretching it would be a false authority.
