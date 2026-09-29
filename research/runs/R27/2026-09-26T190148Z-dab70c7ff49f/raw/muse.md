# R27 — formatter-config-surface (bundle) — raw report

Actor: `research-muse-2026-09-26T190148Z-dab70c7ff49f`. Model: `muse-spark` (Meta).
Item kind: `bundle`. Tier: focused. Retrieval date for every figure and claim below: **2026-09-26**.

Toolchain facts this report is measured against, observed locally on 2026-09-26:
`rustc 1.98.1 (48a229cea 2026-09-01)` with `rustfmt 1.9.0` on the active stable
toolchain, so the owner-fixed `msrv-policy` ("stable minus 2 minor versions") puts this
template's declared floor at **1.96**. Every executed probe below was run on macOS 15 /
aarch64 with the `stable` toolchain (1.98.1) and, where noted, the installed `1.96.0`
floor toolchain.

### Landscape

**Step 1 — the category and its three bins.** The category this item decides is *the
tool, configuration, and enforcement surfaces that keep every Rust source file in the
template machine-formatted*: which formatter runs, what `rustfmt.toml` sets, where
exclusions live, how the tool version is pinned, whether the pre-commit hook blocks or
rewrites, and whether the composite recipe includes a format check.

| Bin | Candidates found |
|---|---|
| Built-in or first-party toolchain | `rustfmt` as a rustup component, invoked `cargo fmt` / `cargo fmt --check`; `rustfmt.toml` stable options (`max_width`, `newline_style`, `reorder_imports`, `style_edition`); per-item `#[rustfmt::skip]`; `rust-toolchain.toml` channel + components pin |
| Established industry standard | `rustfmt` itself — the tool and the standard coincide; no second standard exists. Adjacent but not a file formatter: `prettyplease` (library that prints in-memory `syn` trees, used for generated code) |
| Up-and-comer | `topiary` (Tree-sitter "uniform formatter for simple languages"; no Rust formatting support evidenced); `dprint` (no Rust plugin on crates.io); `chloro` (776 all-time downloads), `cargo-spaced` (94), `prettify` (6,194) — negligible-adoption experiments; `rustfmt-nightly` crate (last release 1.4.21 on 2020-09-06 — an abandoned distribution channel) |

No candidate below was shortlisted from familiarity: each one appears in the map above and
each was then measured against the fitness gates before any download figure was weighed.
Per the prompt, tool-selection surveying was deliberately bounded: the ledger frames the
question as rustfmt's *config surface*, and the survey confirmed there is no contest to spend.

**Step 2 — authorities used, and why each counts.**

| Source | Why it is authoritative |
|---|---|
| `rust-lang/rustfmt` repository and its `Configurations.md` (maintainer documentation, `https://github.com/rust-lang/rustfmt`) | The formatter's own maintainers define which options exist and which are stable; every stability claim below was additionally re-verified by executing the installed stable `rustfmt` |
| `rust-lang/rust`'s own `rustfmt.toml` (fetched 2026-09-26) | The Rust project's production config for its own 119,207-star repository; demonstrates which options the project itself uses and that the advanced ones require nightly |
| The Cargo Book, `cargo fmt` reference (`https://doc.rust-lang.org/cargo/commands/cargo-fmt.html`) | First-party documentation of the invocation this template uses |
| `rust-lang/crates.io`, `tokio-rs/tokio`, `serde-rs/serde`, `clap-rs/clap`, `BurntSushi/ripgrep` repository contents and CI (fetched 2026-09-26) | Current production practice from projects chosen for standing (below); configs and CI jobs read at source, not asserted |
| Executed local probes on rustfmt 1.9.0 (stable 1.98.1) and the 1.96.0 floor toolchain | Direct observation of stable-vs-nightly behavior on the exact compilers this template targets; distinguishes this report's claims from documentation that may lag releases |

A single blog post was treated as a lead only; none is cited. Everything numeric below comes
from the endpoints in the prompt's evidence table.

**Step 3 — practice evidence from well-regarded, current projects.** Five projects were read
at source (repo figures from `GET https://api.github.com/repos/<o>/<r>`, 2026-09-26):

- **`tokio-rs/tokio`** — 33,246 stars, `archived: false`, `pushed_at: 2026-09-26T15:24:17Z`.
  Well regarded as the de-facto async runtime; the closest ecosystem analogue of production
  Rust at scale. No `rustfmt.toml` (pure defaults). CI has a dedicated `fmt` job
  (`.github/workflows/ci.yml:831`) that installs the `rustfmt` component and runs a blocking
  `rustfmt --check` that exits 1 with "Please run `rustfmt ...` to fix rustfmt errors".
  No lefthook or pre-commit config exists.
- **`serde-rs/serde`** — 10,834 stars, `archived: false`, `pushed_at: 2026-09-22T03:42:04Z`.
  Well regarded as the universal serialization framework. No `rustfmt.toml`. No lefthook or
  pre-commit config.
- **`rust-lang/crates.io`** — 3,703 stars, `archived: false`, `pushed_at: 2026-09-26T19:29:10Z`.
  Well regarded because it *is* the crate registry, operated by the Rust project, and it is
  the closest structural match to this template (CLI · library · web service workspace).
  No `rustfmt.toml`. No lefthook or pre-commit config.
- **`clap-rs/clap`** — 16,725 stars, `archived: false`, `pushed_at: 2026-09-21T18:47:13Z`.
  Well regarded as the standard CLI parser — directly relevant to this template's CLI shape.
  No `rustfmt.toml`. CI has a dedicated blocking `rustfmt` job (`ci.yml:228`). Its
  `.pre-commit-config.yaml` runs hygiene hooks only (check-yaml/json/toml, typos, committed,
  zizmor) — formatting is deliberately *not* a rewrite hook; CI owns enforcement.
- **`BurntSushi/ripgrep`** — 68,626 stars, `archived: false`, `pushed_at: 2026-08-04T13:59:44Z`.
  Well regarded as the reference Rust CLI. The sole surveyed project with a `rustfmt.toml`,
  and it sets only three stable values: `max_width = 79`, `use_small_heuristics = "max"`,
  `edition = "2024"` — an author style choice inside the stable subset, not a nightly setup.
- **`rust-lang/rust`** — 119,207 stars, `archived: false`, `pushed_at: 2026-09-26T19:15:42Z`.
  The language itself. Its `rustfmt.toml` sets `style_edition = "2024"` plus nightly-only
  options (`group_imports`, `imports_granularity`, `ignore`, `merge_derives`,
  `use_field_init_shorthand`) — possible only because compiler development runs nightly
  rustfmt. This bounds the template: those options exist but are unavailable on stable.

The pattern is stark: 4 of 5 mainstream projects ship *zero* formatter config (defaults
everywhere), enforcement is a blocking `--check` in CI, and none uses a write-and-restage
pre-commit formatter.

**Step 4 — fit, not abstract best.** The template is a stable-only, edition-2024 Cargo
workspace producing a CLI, a library and a web service, formatted through three surfaces
(Justfile recipe, lefthook hook, CI job) like both sources. That triple discriminates the
candidates: anything requiring nightly rustfmt cannot run on the MSRV floor or in a
minimal stable CI; anything that is not `cargo fmt` breaks the `package-manager-invocation`
contract (R42) and the zero-dependency expectation every surveyed project demonstrates.
Popularity figures were weighed only after those gates.

### Principles and implementation

**The shared requirement.** Stated at the level the ledger and
`docs/port/DIVERGENCE-ANALYSIS.md:111-116` support: *one dedicated formatter, wired
identically through the Justfile recipe, the pre-commit hook, and CI, so that no
unformatted source file can be committed or merged and every surface reports the same
verdict.* The analysis records the item as "one dedicated formatter (`ruff format`) via
Justfile/lefthook/CI" versus "`oxfmt` via same three surfaces" — the three-surface
wiring is the agreed shape; the per-setting values are the open question.

**Source and agreement level.** Per-row, from `docs/port/DIVERGENCE-ANALYSIS.md:111-116`:

| Row | Subject | `harmonize` | Agreement level this report assigns |
|---|---|---|---|
| F084 | formatter tool | no | policy/mechanism — Rust decides alone (rustfmt, uncontested) |
| F087, F089, F092, F100, F102, F104 | width, endings, import sorting, exclude scope, composite placement, hook mode | yes | **capability/standard — must agree on the capability** (bounded width, normalized endings, ordered imports, enforced on all surfaces); the literal values are ecosystem-idiom and **may vary** |
| F103 | version-pinning strategy | partly | structural — collapses for Rust (rustup component, not a Cargo dependency) |
| F091 | trailing-comma style | no | mechanism — Rust decides alone (stable default; nightly option omitted like py) |
| F162 | hook exclude-list drift guard | partly | conditional — needed only if excludes split across files; they do not on stable Rust, so no test |

So what must agree is a *capability*: machine-enforced formatting, one tool, three
surfaces, blocking verdict. What may vary is the *mechanism and the literal style values*:
py's 88, ts's 100, and rustfmt's default 100 are three ecosystem-appropriate realizations,
and nothing in the evidence makes one width correct for all three.

**Essential behaviors and observable acceptance criteria.**

1. One formatter formats all Rust sources. *Observable:* `cargo fmt --check` passes on a
   clean tree and fails (exit 1) after any whitespace-only corruption of any `.rs` file.
2. The same verdict on all three surfaces. *Observable:* the Justfile recipe, the lefthook
   job, and the CI step invoke the same `cargo fmt --check` command; corrupting one file
   fails all three identically.
3. Bounded line width. *Observable:* a line exceeding the configured width is rewrapped by
   `cargo fmt` (or flagged by `--check`).
4. Normalized line endings. *Observable:* a file with CRLF line endings is rewritten to LF
   by `cargo fmt`.
5. Ordered imports. *Observable:* unsorted `use` items are reordered by `cargo fmt`.
6. Stable-only operation. *Observable:* `cargo fmt --check` emits no "unstable features are
   only available in nightly channel" warning on the MSRV floor toolchain (1.96.0).
7. No silent exclusion. *Observable:* no `ignore` list exists in any tool config, so every
   `.rs` file the workspace owns is covered; any per-item skip is a visible
   `#[rustfmt::skip]` attribute at the skip site.

**Architectural alternatives compared before any value was chosen.**

| Alternative | What it is | Why it was or was not chosen |
|---|---|---|
| A. No formatter; review-enforced style | No tool, no config | Fails criteria 1–5 outright. Rejected. |
| B. rustfmt on the stable subset (chosen) | `cargo fmt` + a `rustfmt.toml` containing only stable options + `rust-toolchain.toml` channel pin | Satisfies all seven criteria on the MSRV floor; matches 4-of-5 surveyed projects (defaults) plus ripgrep (stable-only config). **Chosen.** |
| C. rustfmt with nightly-only options | Same tool plus `imports_granularity`, `group_imports`, `ignore`, `trailing_comma` overrides | Fails criterion 6: this run observed stable rustfmt warn-and-ignore every one of these options. Would need a nightly toolchain, violating the fixed stable-only constraint and the MSRV floor. Rejected; `rust-lang/rust` is the existence proof that this tier is for compiler development, not templates. |
| D. Third-party formatter (dprint plugin, Topiary, `chloro`-class) | A non-rustfmt Rust formatter | No credible candidate exists: no dprint Rust plugin on crates.io, Topiary covers "simple languages" with no Rust support evidenced, and the crates.io search leaders have 94–6,194 all-time downloads. Rejected. |

**How the chosen design preserves each principle, and where an ecosystem needs a different
one.** The stable subset carries every agreed capability: `max_width` bounds width,
`newline_style = "Unix"` normalizes endings, `reorder_imports` orders imports, and the
same `cargo fmt --check` on three surfaces preserves the one-tool agreement. Literal
values differ where the ecosystem idiom differs (100 columns is rustfmt's default, not
ts's `printWidth` imported blindly). Exclusion scope differs structurally: py shares one
`[tool.ruff] exclude` and ts splits per-tool `ignorePatterns`, but stable rustfmt offers
*no* config-file exclusion at all, so Rust keeps zero lists — a justified tool-capability
difference, not drift by choice.

**Cross-repo adjudication (HIGH question, owner clarification 2026-09-04).** Changes to py
and ts are a follow-on project; this is their rationale.

- **F087 width (py 88 / ts 100 / rs 100).** Justified ecosystem differences. 88 is a Python
  (Black-norm) value with no Rust evidence; ts's 100 came from Prettier/Biome precedent
  (D-014(2)); rs's 100 is rustfmt's own default, confirmed by 4-of-5 surveyed projects
  running defaults. No shared low-level value is recommended — the agreement is "bounded
  width", preserved at the capability level.
- **F089 endings (py auto / ts LF / rs LF).** py is the outlier and this looks like
  **accidental drift**: `auto` sniffs the first line per file, which is non-hermetic, and
  no decision records the choice. ts (fixed LF) and rs (fixed `Unix`) preserve the
  "normalized endings" principle; follow-on rationale for py is to pin LF.
- **F091 trailing comma (py absent / ts es5 / rs default).** Tool-capability difference
  (class D, as the analysis records). rs omits the option like py because setting it needs
  nightly; the stable default (`Vertical`) already adds trailing commas in multiline
  constructs, which is the es5-equivalent behavior. No action for any repo.
- **F092 import sorting (py lint rule / ts formatter option / rs formatter default).**
  Justified mechanism difference preserving one capability ("ordered imports, enforced").
  rs lands on ts's side structurally (formatter-owned via stable `reorder_imports`), with
  merge granularity omitted as nightly-only. No action for any repo.
- **F100 exclude scope (py shared / ts per-tool / rs none).** Justified structural
  difference: stable rustfmt has no exclusion mechanism to share or split (observed
  warn-and-ignore). No action for any repo.
- **F102 composite (py omits / ts includes / rs includes).** No reason is recorded for the
  py/ts split; against the "every surface enforces" principle, **py's omission is the
  drift**. rs includes the check (0.2 s observed — negligible cost). Follow-on rationale
  for py is to add the format check to its composite; ts already conforms.
- **F104 hook mode (py blocks / ts writes+restages / rs blocks).** Both modes enforce, but
  the Rust-ecosystem evidence supports blocking only: tokio and clap enforce via blocking
  CI checks, and clap's pre-commit config deliberately omits formatting as a hook. ts's
  write mode is a defensible local choice (D-020(6)), not drift worth a follow-on; rs
  picks blocking because restaging rewrites the tree the developer staged and tested.
- **F103 pinning (py floating+lock / ts exact / rs channel pin).** Justified structural
  difference: rustfmt is not a versioned dependency, so "range vs. pin" has no meaning;
  the `rust-toolchain.toml` channel pin is the complete strategy. No action for any repo.
- **F162 drift guard (py none / ts consistency test / rs none).** Correctly absent in both
  py and rs: the test exists only to guard ts's per-tool split, which neither py's shared
  list nor rs's zero lists can develop. No action for any repo.
- **No shared low-level value is recommended.** Neither an explicit owner requirement nor
  evidence of the same tradeoff in all three ecosystems supports one; the LF follow-on
  rationale for py is a principle repair, not a cross-ecosystem value mandate.

**BASELINE-REVIEW finding.** None. The ledger's framing of F084 as "rustfmt's config
surface, not tool selection" is confirmed, and the 2026-09-04 F103/F190 review (channel
decided here, not derived from the MSRV floor) is followed, not challenged.

**Minimal realistic example and its acceptance check.** A Cargo workspace with
`rustfmt.toml` (`max_width = 100`, `newline_style = "Unix"`, `reorder_imports = true`,
`style_edition = "2024"`), `rust-toolchain.toml` (`channel = "stable"`, components
`rustfmt` + `clippy`), a `fmt` recipe running `cargo fmt` and a composite running
`cargo fmt --check`, a lefthook job running `cargo fmt --check`, and a CI step running
the same. The formatting half was **executed** in this run (see `### Validation
strategy`); the Justfile/lefthook/CI wiring is *proposed* (recipe phrasing and job
topology belong to R42/R11).

### Recommendation

**One stack: stable `rustfmt` via `cargo fmt`, a four-key `rustfmt.toml`, a
`channel = "stable"` toolchain pin, zero exclude lists, no drift test, a blocking
`cargo fmt --check` in the composite recipe, the pre-commit hook, and CI.**

Concretely, and with versions (rustfmt is versioned only by its toolchain):

1. **Tool (F084)** — `rustfmt`, the rustup component, invoked as `cargo fmt` (write) and
   `cargo fmt --check` (verify), per R42's `package-manager-invocation`. No crate, no
   version number, no alternative named in the template.
2. **Config (F087, F089, F091, F092)** — `rustfmt.toml` with exactly:
   `max_width = 100`, `newline_style = "Unix"`, `reorder_imports = true`,
   `style_edition = "2024"`. All four are stable on the 1.96 floor (observed).
   `trailing_comma`, `imports_granularity`, `imports_layout`, `group_imports`, `ignore`,
   and `edition` are deliberately absent (nightly-only, or owned by `Cargo.toml`).
3. **Exclude scope + drift guard (F100, F162)** — no exclude list in any tool config; no
   `exclude` keys on the formatter hook/CI scoping; exceptional per-item opt-out via
   `#[rustfmt::skip]`; no drift test. Holds under both open R28 outcomes (below).
4. **Composite recipe (F102)** — include `cargo fmt --check` in the composite recipe that
   runs lint + typecheck + test (the composite's name is owned elsewhere; this item
   decides inclusion only).
5. **Version pin (F103)** — `rust-toolchain.toml` with `channel = "stable"` and
   `components = ["rustfmt", "clippy"]` (`clippy` shared with R28). No version number
   exists to pin; F103 collapses to this file.
6. **Hook mode (F104)** — blocking: the pre-commit job runs `cargo fmt --check` with no
   write and no `stage_fixed` restage.

**Conditional on R28 (`linter-and-editor-tooling`), which is open.** If R28 lands clippy
configuration in `clippy.toml`, the F100 answer is unchanged: there is still no
rustfmt-side list to share or mirror on stable, so the two files coexist without a shared
scope and without a drift test. If R28 lands in-code attributes only, the same holds
trivially. Either way this member needs no revision; revisit only if Rust stabilizes
rustfmt's `ignore`.

### Members

#### Formatter tool (F084) — rustfmt via cargo fmt

##### Landscape

Category: the executable that formats Rust source files. Bins — *built-in/first-party*:
`rustfmt` as a rustup component (`cargo fmt`); *established industry standard*: `rustfmt`
itself — the survey found no second standard (`GET https://crates.io/api/v1/crates?q=rust+code+formatter`,
2026-09-26, returns only negligible-adoption experiments: `chloro` 776, `cargo-spaced` 94,
`prettify` 6,194 all-time downloads); *up-and-comer*: `topiary` (868 stars, no Rust
support evidenced), `dprint` (no Rust plugin on crates.io), the `rustfmt-nightly` crate
(last release 1.4.21, 2020-09-06 — an abandoned channel). Authorities: the
`rust-lang/rustfmt` maintainers' repository; the five surveyed projects' configs and CI,
read at source; executed local probes.

##### Principles and implementation

The shared requirement is one dedicated formatter on three identical surfaces (Justfile,
hook, CI). rustfmt is the only candidate that can fill it: it ships with every toolchain
(`rustup component add rustfmt`, preinstalled in most distributions), it is what all five
surveyed projects enforce (tokio's blocking `fmt` job, clap's blocking `rustfmt` job),
and it is the only option compatible with R42's `package-manager-invocation`
(`cargo <sub>` for rustup components). The `rustfmt-nightly` crate path would violate the
fixed stable-only constraint. Practice evidence doubles as the maturity argument: the
formatter that formats the Rust compiler's own 119,207-star repository needs no further
dependability case. Performance: `cargo fmt --check` on a scratch workspace completed in
0.2 s wall time (executed 2026-09-26); tokio and clap run it as a standalone CI job with
no caching concern.

##### Dominant choice

`rustfmt`, invoked `cargo fmt` / `cargo fmt --check`. Figures
(`GET https://api.github.com/repos/rust-lang/rustfmt`, 2026-09-26): 6,974 stars,
`archived: false`, `pushed_at: 2026-09-24T13:36:12Z`. Open issues: 718
(`GET https://api.github.com/search/issues?q=repo:rust-lang/rustfmt+is:issue+is:open`,
`total_count`, 2026-09-26). Issue responsiveness over the 10 most recently opened issues:
3 answered by maintainers (latencies ~0.01, ~0.23, ~0.6 days; median ~0.23 days),
7 unanswered — a scale artifact of being the default formatter for the whole ecosystem,
not an at-risk signal. Maintenance state: **active** (pushed 2 days before retrieval;
ships with every stable release). Crate figures: **inapplicable** — rustfmt is a rustup
component, not a Cargo dependency; the `rustfmt-nightly` crate
(`GET https://crates.io/api/v1/crates/rustfmt-nightly`: 475,872 all-time / 8,368 recent
downloads; last release 1.4.21 on 2020-09-06) is its abandoned legacy channel.

##### Qualified shortlist

`rustfmt` is the sole qualified candidate. It passes every fitness gate (below), is the
unanimous choice of all surveyed projects, and is the only candidate compatible with the
stable-only constraint and R42's invocation contract. No second candidate qualified.

##### Excluded by gate

- `rustfmt-nightly` (crate): fails gate 2 (MSRV/stable) — it exists solely to expose
  nightly-only behavior, and its channel is dormant (no release since 2020-09-06).
- `prettyplease`: excluded at admission, before the numbered gates — it is a library for
  printing in-memory `syn` syntax trees (generated/macro code), with no file-formatting
  CLI, so it cannot be wired to a recipe, hook, or CI step as `fmt --check`. Its license
  and maintenance are not in question (510,823,069 all-time / 118,494,924 recent downloads;
  `dtolnay/prettyplease`: 774 stars, `archived: false`, 6 open issues, pushed 2026-07-18;
  no advisory page, HTTP 404) — it is simply the wrong category.
- `chloro`, `cargo-spaced`, `prettify`: no maintained reference implementation or
  production adopter evidenced; cannot satisfy the "maintained reference" bar of the
  required evidence. Not weighed further.

##### Up-and-comers

- `topiary` (`tweag/topiary`: 868 stars, pushed 2026-09-18, fetched 2026-09-26): "a uniform
  formatter for simple languages" in the Tree-sitter ecosystem (README, same fetch); no
  Rust formatting support is evidenced in the surveyed material. Watch only.
- `dprint`: a real multi-language formatter, but the crates.io search for a Rust plugin
  returns only `dprint-core`/development crates — no Rust language support exists to
  evaluate. Watch only.

##### Fit for this template

Exact fit. The template needs a zero-dependency, stable-only, cross-platform (ubuntu +
macOS) formatter callable identically from a Justfile recipe, a lefthook job, and CI.
rustfmt is preinstalled or one `rustup component add` away on every target, adds no
dependency to any `Cargo.toml`, and runs in a fraction of a second. `rust-lang/crates.io`
— the surveyed project with this template's exact CLI · library · web-service shape —
uses it with zero config.

##### Recommendation

`rustfmt` via `cargo fmt` (write) and `cargo fmt --check` (verify). No version number:
the tool is versioned only by its toolchain (see the F103 member). Name no alternative
in the template.

##### Ranked runner-up

None viable. The nearest conceivable fallback — pinning the `rustfmt-nightly` crate to
reach nightly-only options — fails the stable-only constraint outright and is therefore
not ranked as a runner-up. This member has a single-candidate outcome.

##### Tradeoffs

Choosing rustfmt trades configurability for universality: nightly-only options
(import merging, file exclusion, trailing-comma override) are unavailable, and style
control is limited to the stable subset. In return the template gets the formatter every
Rust developer already has, zero new dependencies, MSRV-floor compatibility, and
enforcement commands (`cargo fmt --check`) that any contributor recognizes. The
alternatives trade the reverse — marginal style control for a dependency nobody else
uses — which is the wrong trade for a template.

##### Parameters

Fixed parameters applied: `rust-edition = 2024` (rustfmt reads the edition from
`Cargo.toml` automatically under `cargo fmt`); `msrv-policy` (floor 1.96 ships rustfmt —
observed working on the installed 1.96.0 toolchain); `target-os-matrix`
(ubuntu + macOS both serve the rustfmt component; tokio's CI installs it on
ubuntu-latest); `license = MIT OR Apache-2.0` (repo root carries `LICENSE-MIT` and
`LICENSE-APACHE`, fetched 2026-09-26). Consumed: `package-manager-invocation` (R42) —
this member's `cargo fmt` phrasing is exactly what that contract prescribes. No
`CONFLICT:` line: nothing needs changing.

##### Migration implications

No new file for the tool itself. The Justfile gains `fmt` (`cargo fmt`) and `fmt-check`
(`cargo fmt --check`) recipes (phrasing per R42); `lefthook.yml` gains a pre-commit job
running `cargo fmt --check`; `ci.yml` gains the same command as a step (slot per R11).
`rust-toolchain.toml` ensures the component is present (F103 member).

##### Validation strategy

Executed 2026-09-26 on macOS/aarch64, rustfmt 1.9.0 (stable 1.98.1): `cargo fmt --check`
on a clean scratch workspace exited 0 in 0.2 s; after corrupting one line it exited 1;
`#[rustfmt::skip]` left a deliberately misformatted item untouched. Proposed for the
template: the same `cargo fmt --check` in recipe, hook, and CI, each expected to fail on
a one-line corruption and pass after `cargo fmt`.

##### Confidence & re-verify trigger

High. rustfmt's position is structural (bundled, universal, surveyed-unanimous), not a
fashion. Re-verify if: a credible stable-channel Rust formatter appears with production
adoption; rustfmt is unbundled from rustup; or the `ignore`/granularity options stabilize
(which affects the config member, not this one). Otherwise no date-based re-verification
is needed beyond the quarterly trigger.

##### Sources

- `GET https://api.github.com/repos/rust-lang/rustfmt` — 2026-09-26 — stars/archived/pushed/license.
- `GET https://api.github.com/search/issues?q=repo:rust-lang/rustfmt+is:issue+is:open` — 2026-09-26 — `total_count` 718.
- `GET https://api.github.com/repos/rust-lang/rustfmt/issues?state=open&sort=created&direction=desc&per_page=10` + per-issue comments — 2026-09-26 — responsiveness sample.
- `GET https://api.github.com/repos/rust-lang/rustfmt/contents/` — 2026-09-26 — `LICENSE-MIT`, `LICENSE-APACHE`.
- `GET https://crates.io/api/v1/crates/rustfmt-nightly` + `/versions` — 2026-09-26 — downloads, last release 1.4.21 (2020-09-06).
- `GET https://crates.io/api/v1/crates/prettyplease`, `GET https://api.github.com/repos/dtolnay/prettyplease`, issue search — 2026-09-26 — adjacent-candidate figures.
- `GET https://crates.io/api/v1/crates?q=rust+code+formatter`, `?q=dprint+rust` — 2026-09-26 — no credible alternative.
- `GET https://api.github.com/repos/tweag/topiary` + readme — 2026-09-26 — Topiary scope.
- `https://rustsec.org/packages/rustfmt-nightly.html`, `.../prettyplease.html` — 2026-09-26 — no advisory page (HTTP 404), i.e., no recorded advisories.
- Local probes: `rustc --version`, `cargo fmt --check` timing/exit codes, `#[rustfmt::skip]` — executed 2026-09-26.

#### Config surface (F087, F089, F091, F092) — rustfmt.toml stable subset

##### Landscape

Category: the key-value surface of `rustfmt.toml`. Bins — *built-in/first-party*: the
stable options observed on rustfmt 1.9.0 (`max_width`, `newline_style`,
`reorder_imports`, `style_edition`, `hard_tabs`, `use_small_heuristics`, `edition`);
*established industry standard*: the de-facto standard is "defaults", evidenced by 4 of 5
surveyed projects shipping no `rustfmt.toml` at all; *up-and-comer*: the nightly-only
options (`trailing_comma` override, `imports_granularity`, `imports_layout`,
`group_imports`, `ignore`, `merge_derives`, `use_field_init_shorthand`) — real, used by
`rust-lang/rust` on nightly, but unavailable to this template. Authorities: the
maintainers' option definitions plus executed stability probes on both the current stable
and the 1.96.0 floor.

##### Principles and implementation

Each source setting maps to one rustfmt decision, and the stable/nightly boundary —
observed, not documented-from-memory — decides each:

| Source setting | rustfmt option | Stable? (observed 2026-09-26) | Resolution |
|---|---|---|---|
| F087 max width (py 88 / ts 100) | `max_width` (default 100) | Yes — accepted silently on 1.98.1 and 1.96.0 | Set `100`: the default, confirmed by 4-of-5 projects running defaults; py's 88 is a Python norm with no Rust evidence; ripgrep's 79 is author idiosyncrasy, not a reference |
| F089 endings (py auto / ts LF) | `newline_style` (default Auto) | Yes — accepted silently on both toolchains | Set `"Unix"` (fixed LF): hermetic, matches ts; `Auto` sniffs each file's first line, weakening the normalization guarantee |
| F091 trailing comma (py none / ts es5) | `trailing_comma` (default Vertical) | **No** — `Warning: can't set ... nightly channel` on 1.98.1 | Omit: the default `Vertical` already adds trailing commas in multiline constructs (the es5-equivalent behavior); setting it is dead config with warning noise |
| F092 import sorting (py lint rule / ts formatter option) | `reorder_imports` (default true), `imports_granularity` / `imports_layout` / `group_imports` | `reorder_imports` yes; the other three **no** (same nightly warning) | Set `reorder_imports = true` explicitly (documents the ts-`sortImports` capability); omit merge granularity (nightly-only) |
| Style edition | `style_edition` | Yes — accepted silently on both toolchains | Set `"2024"`: matches the fixed edition; `rust-lang/rust` sets it too |
| Edition | `edition` | Yes | Omit: `cargo fmt` passes the edition from `Cargo.toml` automatically; a second copy can only drift |

A nightly-only key on stable does not fail the check — this run observed exit 0 on a
formatted file with `imports_granularity` set — but it prints a stderr warning on every
invocation, so including such keys means permanent CI noise for zero effect. They stay out.

##### Dominant choice

A four-key `rustfmt.toml`: `max_width = 100`, `newline_style = "Unix"`,
`reorder_imports = true`, `style_edition = "2024"`. This is "defaults, written down,
plus fixed LF": every value except `newline_style` equals the rustfmt default, which is
precisely why it is dominant — it records the adjudicated F087/F089/F092 decisions for
the reader while changing tool behavior only where the principle (normalized endings)
requires it. Figures are inapplicable (a config file has no downloads/issues); the
supporting figures are the practice survey (4 of 5 projects on defaults; ripgrep's three
stable keys) and the executed stability probes.

##### Qualified shortlist

The four-key file above is the sole qualified candidate. A zero-key file (pure defaults,
the tokio/serde/clap/crates.io shape) was considered and differs only in `newline_style`:
pure defaults leave endings on `Auto` per-file sniffing, which fails essential-behavior
criterion 4 as stated (deterministic LF normalization). It is recorded here as the
adjudicated-against variant, not a second recommendation.

##### Excluded by gate

- Any `rustfmt.toml` containing `trailing_comma`, `imports_granularity`,
  `imports_layout`, `group_imports`, or `ignore`: fails gate 2 (stable/MSRV) — observed
  warn-and-ignore on both stable 1.98.1 and floor 1.96.0. These are `rust-lang/rust`'s
  nightly-tier options, not template options.
- `max_width = 88`: fails the evidence bar, not a numbered gate — no Rust project or
  authority supports 88; it would import a Python norm into a Rust template. Recorded here
  as the rejected py-mirror value.
- `newline_style = "Auto"` / `"Windows"` / `"Native"`: `Auto` fails criterion 4
  (non-hermetic); `Windows`/`Native` contradict the cross-platform template and the ts LF
  precedent.

##### Up-and-comers

`imports_granularity` (merge `use` items to crate/module/item granularity) and
`group_imports` (std/external/crate grouping) are the two nightly options with genuine
user demand — they are what `rust-lang/rust` runs. If either stabilizes, the F092 answer
gains a merge tier. Until then they are watch-only; the re-verify trigger below names the
condition.

##### Fit for this template

Exact fit. All four keys work on the 1.96 floor (observed), cost nothing (no dependency,
no nightly toolchain, no per-OS divergence), and compose with the three enforcement
surfaces unchanged. The file also serves as the readable record of the F087/F089/F092
adjudications — a future contributor sees *why* the width is 100 (a decision, not an
accident) without consulting the research archive.

##### Recommendation

Ship `rustfmt.toml` with exactly these four keys, each with a one-line comment naming its
source row:

```toml
max_width = 100          # F087: rustfmt default; py's 88 is a Python norm, not portable
newline_style = "Unix"   # F089: fixed LF; Auto sniffs per file and is non-hermetic
reorder_imports = true   # F092: ts-sortImports-equivalent; stable default, made explicit
style_edition = "2024"   # edition-2024 formatting rules (stable)
```

##### Ranked runner-up

The zero-key file (pure rustfmt defaults, the tokio/serde/clap/crates.io shape). It loses
only on `newline_style`: `Auto` preserves whatever each file already has, so a CRLF file
stays CRLF and the "normalized endings" capability rests on `.gitattributes` alone rather
than on the formatter. If a future owner prefers byte-minimal config, this is the
documented fallback.

##### Tradeoffs

Writing the four keys trades four lines of config for decision legibility and hermetic
endings. The cost is nil at runtime (rustfmt reads one TOML file) and the benefit is that
`git log` on `rustfmt.toml` tells the width/ending/import story without archaeology.
Omitting the nightly tier trades import-merging and file-exclusion power for
floor-compatibility — the only legal trade under the stable-only constraint.

##### Parameters

Fixed parameters applied: `rust-edition = 2024` (carried by `style_edition`; the `edition`
key itself is omitted because `cargo fmt` forwards `Cargo.toml`'s edition); `msrv-policy`
(every recommended key observed working on the 1.96.0 floor toolchain); `target-os-matrix`
(options are platform-independent; `Unix` endings are enforced identically on both
runners); `license` (no code involved). Consumed: none directly. No `CONFLICT:` line.

##### Migration implications

New file `rustfmt.toml` at the repository root with the four keys above. No other file
changes for this member; enforcement wiring lives in the F102/F104 members.

##### Validation strategy

Executed 2026-09-26 on rustfmt 1.9.0 (stable 1.98.1) plus the 1.96.0 floor: each of 11
candidate options was placed alone in `rustfmt.toml` and `rustfmt --check --edition 2024`
run — `max_width`, `newline_style`, `reorder_imports`, `style_edition`, `hard_tabs`,
`use_small_heuristics` applied silently; `trailing_comma`, `imports_granularity`,
`imports_layout`, `group_imports`, `ignore` each printed `Warning: can't set ... nightly
channel`. A formatted file with a nightly key still exited 0 (warning only). Proposed for
the template: a CRLF-ended fixture and an unsorted-imports fixture that `cargo fmt`
normalizes and `--check` flags — expected to pass on both CI runners.

##### Confidence & re-verify trigger

High — the stability boundary was observed on both ends of the supported compiler range,
not read from documentation. Re-verify if a new stable release stabilizes
`imports_granularity`, `group_imports`, `trailing_comma`, or `ignore` (rerun the
eleven-option probe; any newly stable option becomes a candidate for the file), or if
rustfmt changes a default. Otherwise the quarterly trigger suffices.

##### Sources

- Local eleven-option stability probe on rustfmt 1.9.0 (stable 1.98.1) and 1.96.0 — executed 2026-09-26.
- `GET https://api.github.com/repos/rust-lang/rust/contents/rustfmt.toml` — 2026-09-26 — nightly-tier reference config.
- `GET https://api.github.com/repos/BurntSushi/ripgrep/contents/rustfmt.toml` — 2026-09-26 — `max_width = 79`, `use_small_heuristics = "max"`, `edition = "2024"`.
- `GET https://api.github.com/repos/<o>/<r>/contents/rustfmt.toml` for tokio-rs/tokio, serde-rs/serde, rust-lang/crates.io, clap-rs/clap — 2026-09-26 — all HTTP 404 (defaults).
- `https://github.com/rust-lang/rustfmt/blob/main/Configurations.md` — maintainer option definitions — cited 2026-09-26.

#### Exclude-list scope and drift guard (F100, F162) — no lists, no test

##### Landscape

Category: where path exclusions for the formatter (and, jointly, the linter) are
configured. Bins — *built-in/first-party*: rustfmt's `ignore` option and
`#[rustfmt::skip]`; *established industry standard*: none — the surveyed projects carry no
formatter exclusions at all (4 of 5 have no `rustfmt.toml`; ripgrep's has no `ignore`);
*up-and-comer*: rustfmt's `ignore` with gitignore syntax (used by `rust-lang/rust` on
nightly). The decisive observation: `ignore` is nightly-only on stable rustfmt 1.9.0
(`Warning: can't set ... nightly channel`, executed 2026-09-26). Authorities: the
executed probe, `rust-lang/rust`'s `rustfmt.toml` (which demonstrates the option's
nightly tier), and the surveyed projects' absence of exclusions.

##### Principles and implementation

F100 asks whether Rust shares one exclude scope (py's `[tool.ruff] exclude`) or keeps
per-tool files (ts's split `ignorePatterns`); F162's drift test exists only because ts
split. On stable Rust the question dissolves: there is no rustfmt-side list to share or
split, so neither source shape is reproducible and no drift between lists is possible.
The per-item escape hatch is `#[rustfmt::skip]`, which this run verified works on stable
(a deliberately misformatted item survived `rustfmt` untouched). Path scoping for "which
files the hook/CI looks at" therefore lives only in lefthook/CI path filters — and the
recommendation is to put *no* `exclude` keys on the formatter's hook job or CI step at
all, so there is not even a hook-side list to drift against a tool-side list. ts's
`repo-hygiene.test.ts:81` consistency test has nothing to compare and is correctly omitted
— the same logic by which py (one shared list) needs no test, taken one step further
(zero lists).

##### Dominant choice

Zero exclude lists: no `ignore` in `rustfmt.toml`, no `exclude` keys on the formatter's
lefthook job or CI step, no drift test; exceptional opt-outs via `#[rustfmt::skip]` at the
item. Dominant because it is the only stable-compatible shape — any list-based alternative
requires nightly — and because it matches all five surveyed projects, none of which
excludes anything from formatting. Figures are inapplicable (no artifact involved).

##### Qualified shortlist

The zero-list shape is the sole qualified candidate. No list-based variant can qualify on
stable rustfmt.

##### Excluded by gate

- A shared lint+format exclude list (py's shape): fails gate 2 — stable rustfmt has no
  list to share; there is nothing to point clippy's scope at.
- Per-tool `ignore` files plus a drift test (ts's shape): fails gate 2 for the same
  reason — `ignore` is nightly-only (observed). The drift test is then a test of nothing.
- `ignore` in `rustfmt.toml` on stable "for when it stabilizes": fails on evidence — this
  run observed it warn on every invocation while doing nothing; shipping known-dead config
  with permanent stderr noise is not a qualified state.

##### Up-and-comers

Stabilization of rustfmt's `ignore` (gitignore-syntax file exclusion, as used by
`rust-lang/rust`). If it stabilizes, F100 reopens as a real py-vs-ts question and F162's
test becomes worth revisiting. Watch-only until then.

##### Fit for this template

Exact fit. A greenfield template has no generated or vendored `.rs` files to exclude, so
"format everything" is both the simplest and the most correct scope. `#[rustfmt::skip]`
covers the rare exceptional item (e.g., a whitespace-sensitive macro fixture) with the
exemption visible at the site rather than in a distant list. Both open R28 outcomes keep
this answer unchanged (see top-level Recommendation).

##### Recommendation

No exclude list in any tool config; no `exclude` keys on the formatter hook job or CI
step; no drift test. Document `#[rustfmt::skip]` as the exceptional escape hatch.

##### Ranked runner-up

Scoping the lefthook formatter job to `*.rs` file globs while leaving CI unscoped. It
loses because include-globs on one surface and no scoping on another reintroduce exactly
the surface-divergence the shared principle forbids ("the same verdict on all three
surfaces"). If hook performance ever matters (it does not at 0.2 s), revisit with a
symmetric scope on all surfaces.

##### Tradeoffs

Zero lists trade future flexibility (no ready-made place to exclude a future `generated/`
directory) for present impossibility-of-drift. The cost is theoretical — when generated
code arrives, `#[rustfmt::skip]` or a stabilized `ignore` covers it — while the benefit
is that F162's entire failure mode cannot occur.

##### Parameters

Fixed parameters applied: `msrv-policy` (the nightly-only status of `ignore` was observed
on the 1.96.0 floor as well as current stable, so the zero-list answer holds across the
whole supported range). Related, not consumed: R28's clippy config shape — addressed under
both outcomes with no change to this member. No `CONFLICT:` line.

##### Migration implications

No file carries an exclusion for this member: `rustfmt.toml` has no `ignore` key,
`lefthook.yml`'s formatter job has no `exclude` key, and no drift-test file is created.
If the template's hook scaffolding emits a default `exclude` stanza, delete it for the
formatter job.

##### Validation strategy

Executed 2026-09-26: `ignore = ["src/generated.rs"]` in `rustfmt.toml` on stable 1.98.1
printed the nightly warning and was ignored; `#[rustfmt::skip]` preserved a misformatted
item through a `rustfmt` write run. Proposed for the template: none beyond the F084
`--check` coverage proof (every owned `.rs` file is formatted, so the empty scope is
demonstrated by the passing check itself).

##### Confidence & re-verify trigger

High — the nightly-only status of `ignore` was observed on both ends of the supported
range. Re-verify if `ignore` stabilizes (rerun the probe; F100/F162 reopen), or if R28's
accepted answer introduces a clippy-side path list that a rustfmt-side list must mirror
(impossible today; would itself need a stabilization). Otherwise the quarterly trigger
suffices.

##### Sources

- Local `ignore` probe on rustfmt 1.9.0 (stable 1.98.1) and 1.96.0 — executed 2026-09-26.
- Local `#[rustfmt::skip]` write-run — executed 2026-09-26.
- `GET https://api.github.com/repos/rust-lang/rust/contents/rustfmt.toml` — 2026-09-26 — `ignore` in nightly-tier use.
- Absence of `ignore`/`exclude` in all five surveyed projects' configs — fetched 2026-09-26 (same calls as the F084/F087 member).

#### Composite recipe placement (F102) — include cargo fmt --check

##### Landscape

Category: whether the composite local recipe (the `just check` / `just all` analogue that
runs lint + typecheck + test) also runs the format check. Bins — *built-in/first-party*:
`cargo fmt --check` as a recipe step (zero new tooling); *established industry standard*:
inclusion — ts's `all` composite includes the format check, and both tokio and clap run
formatting as a blocking CI job alongside their other gates; *up-and-comer*: none — this
is a placement decision, not a tool market. The divergence to adjudicate: py's `check`
composite omits the format check (`Justfile:277`), ts's `all` includes it
(`Justfile:178`), with no recorded reason for the split. Authorities: the two source
Justfiles (via the prompt's cited evidence), tokio's and clap's CI topologies (fetched),
and the executed 0.2 s timing.

##### Principles and implementation

The shared principle — "the same verdict on all three surfaces" — decides this member:
a composite recipe that omits formatting is a surface where unformatted code passes, which
is exactly the gap the principle forbids. Cost cannot rescue omission: `cargo fmt --check`
ran in 0.2 s wall time on the scratch workspace (executed 2026-09-26), so inclusion is
free in practice, and formatting needs no compilation, so it never contends with the
compile-heavy steps. The MEDIUM question's "low-stakes either way" framing is therefore
half right: the cost is low-stakes, but the principle is not — py's omission is drift
(see the cross-repo adjudication), and the template follows ts. Note the boundary: this
member decides *inclusion only*. The composite's name, the recipe phrasing, and the CI
job topology belong to R42 (invocation) and R11 (`ci-job-structure`, whose hygiene job
hosts non-compiling checks); this member requires only that the format check appear in
the composite and that it be the same `cargo fmt --check` command as the hook and CI.

##### Dominant choice

Include `cargo fmt --check` as a step of the composite recipe (ts's shape). Dominant by
principle (every surface enforces), by precedent (ts's composite; tokio's and clap's
blocking CI jobs), and by cost (0.2 s observed). Figures are inapplicable (a recipe
placement has no downloads/issues).

##### Qualified shortlist

Inclusion is the sole qualified candidate. Omission was evaluated and rejected on
principle (below), not merely deprioritized.

##### Excluded by gate

- Omitting the format check from the composite (py's shape): excluded on the shared
  principle rather than a numbered fitness gate — it creates a surface where unformatted
  code passes, violating essential-behavior criterion 2. No cost, compatibility, or
  ecosystem argument for omission was found; py's omission carries no recorded reason.
- A write-mode (`cargo fmt`) step in the composite instead of `--check`: excluded on
  hermeticity — a check recipe must not mutate the tree it verifies; writes belong to the
  standalone `fmt` recipe.

##### Up-and-comers

None. Recipe placement has no emerging technology; the only future change would be a
faster checker, and 0.2 s leaves nothing to gain.

##### Fit for this template

Exact fit. The template's composite already pays for clippy, typecheck, and test runs;
a sub-second formatting gate is noise by comparison, and its failure message ("run
`cargo fmt`") is actionable by any contributor. tokio's CI demonstrates the shape at
scale: `fmt` sits beside `clippy` as a peer gate.

##### Recommendation

The composite recipe includes `cargo fmt --check` as an early step (before the
compile-heavy steps, so a formatting failure fails fast without waiting for a build).
Recipe name and phrasing per R42; CI slot per R11.

##### Ranked runner-up

Omitting the check from the composite while keeping it in the hook and CI (py's shape).
It loses on the three-surface principle and saves 0.2 s. Ranked only to record that the
py shape was considered and rejected with a reason, not overlooked.

##### Tradeoffs

Inclusion trades 0.2 s per composite run for the guarantee that `just check` passing
means "formatted" as well as "linted, typed, and tested". There is no credible
counter-trade: the cost is below measurement noise and the failure mode it closes (merge
with unformatted code that hook+CI would have caught anyway) is pure contributor friction.

##### Parameters

Consumed: `ci-job-structure` (R11) — the CI counterpart of this recipe step lands in the
hygiene job, which hosts non-compiling checks; `package-manager-invocation` (R42) —
the step is phrased `cargo fmt --check`. This member assumes both values as recorded and
needs no change to either. No `CONFLICT:` line.

##### Migration implications

One step added to the composite Justfile recipe: the `fmt-check` recipe (or inline
`cargo fmt --check`) placed before the compile-heavy steps. No new file.

##### Validation strategy

Executed 2026-09-26: `cargo fmt --check` timed at 0.2 s wall (`time` on the scratch
workspace) with exit 0 clean / exit 1 corrupted. Proposed for the template: corrupt one
line, run the composite, expect failure naming the format step; run `cargo fmt`, rerun
the composite, expect pass — on both CI runners.

##### Confidence & re-verify trigger

High. The timing was measured, the principle is explicit, and both source repos plus two
surveyed projects concur on inclusion (3-to-1 against py's unexplained omission).
Re-verify only if the composite recipe itself is restructured (then re-confirm the step
survived) or if a future formatter is pathologically slow. Otherwise the quarterly
trigger suffices.

##### Sources

- Local timing: `time cargo fmt --check` on the scratch workspace — executed 2026-09-26.
- `GET https://api.github.com/repos/tokio-rs/tokio/contents/.github/workflows/ci.yml` — 2026-09-26 — `fmt` job at lines 831–850 (blocking check).
- `GET https://api.github.com/repos/clap-rs/clap/contents/.github/workflows/ci.yml` — 2026-09-26 — `rustfmt` job at line 228.
- Prompt-cited source evidence: py `Justfile:277` (omits), ts `Justfile:178` (includes).

#### Version-pinning strategy (F103) — rust-toolchain.toml channel pin

##### Landscape

Category: how the formatter's version is pinned. Bins — *built-in/first-party*:
`rust-toolchain.toml` (`channel` + `components`), the rustup-native mechanism;
*established industry standard*: for rustfmt specifically, the channel pin *is* the
standard — every surveyed CI installs a toolchain and adds the `rustfmt` component
(tokio: `dtolnay/rust-toolchain@stable` with `components: rustfmt`; clap:
`rustup component add rustfmt`); *up-and-comer*: none — no finer-grained rustfmt
versioning exists on the stable channel. The divergence-analysis prediction is confirmed:
py's "floating range + lockfile" versus ts's "exact pin" has no Rust analogue because
rustfmt is not a versioned dependency. Authorities: the toolchain-component model
(observed locally — `rustup toolchain list`, `cargo fmt --version`), the surveyed CIs'
install steps, and the 2026-09-04 baseline review that assigns `channel`/`components` to
this item.

##### Principles and implementation

F103 collapses, exactly as `docs/port/DIVERGENCE-ANALYSIS.md:114` foresaw ("this may
collapse to a `rust-toolchain.toml` component pin instead"). There is no version number
to float or pin: `cargo fmt --version` reports the component build of the active
toolchain, and the only selectors rustup offers are the channel (`stable`, `beta`,
`nightly`, or a dated/archive version) and the component set. The decision is therefore:
`channel = "stable"` plus `components = ["rustfmt", "clippy"]`. Three points fix the
channel at `stable` rather than anywhere else. First, the 2026-09-04 baseline review
(F190/F103) explicitly forbids deriving `channel` from the MSRV floor: pinning the
channel to the floor compiler would put local builds and CI on the oldest supported
toolchain. Second, `stable` is what the surveyed projects install (tokio pins
`rust_stable` via `dtolnay/rust-toolchain`; the template equivalent is the channel
string). Third, the MSRV floor remains enforced where the fixed parameter says it is:
`rust-version` in `Cargo.toml` plus the CI floor job — the toolchain file must not
duplicate that duty. `clippy` rides in the same components list because the file holds
exactly one list and clippy is a rustup component too; R28 owns clippy's configuration,
this member owns the shared file's channel + component entries, and the clippy entry is
recorded as shared-with-R28 rather than decided twice.

##### Dominant choice

`rust-toolchain.toml` with `channel = "stable"` and
`components = ["rustfmt", "clippy"]`. Dominant because it is the only mechanism rustup
provides, it follows the baseline review, and it matches surveyed practice. Figures are
inapplicable (a toolchain pin has no downloads/issues).

##### Qualified shortlist

The `channel = "stable"` pin is the sole qualified candidate.

##### Excluded by gate

- `channel` pinned to the MSRV floor (e.g., `1.96`): fails the baseline-review constraint
  (2026-09-04, F190/F103) — it would put everyday builds on the oldest compiler. Excluded
  by binding prior adjudication, recorded here.
- A dated or version-pinned channel (e.g., `1.98.1`): fails on maintenance fit — it
  freezes the whole toolchain (compiler, cargo, clippy, rustfmt) for the sake of a
  formatter whose formatting rules the template already constrains via `style_edition`;
  no surveyed project does this for formatting. Rejected as unneeded rigidity.
- `rustfmt-nightly` crate pin: fails gate 2 (stable/MSRV) and the channel is dormant
  (see the F084 member).
- No toolchain file (ambient toolchain): fails determinism — contributors' varying
  toolchains would format with varying rustfmt builds. The file costs four lines.

##### Up-and-comers

None. rustup's channel model is stable infrastructure; no alternative pinning mechanism
for components exists or is emerging.

##### Fit for this template

Exact fit. The file is four lines, works identically on ubuntu and macOS runners and
developer machines, guarantees the `rustfmt` component exists wherever `cargo fmt` runs
(closing the "component not installed" failure mode), and coordinates with R42 (rustup
is the acquisition channel) and R28 (shared `clippy` entry) without duplicating either.

##### Recommendation

Ship `rust-toolchain.toml` at the repository root:

```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]  # clippy entry shared with R28
```

##### Ranked runner-up

`channel = "stable"` with `components = ["rustfmt"]` only, leaving clippy's component to
R28's answer. It loses only on file mechanics: two writers cannot own one TOML list, and
this item was assigned the file by the baseline review. If R28's acceptance prefers to
restate the shared entry, that is editorial, not a second decision.

##### Tradeoffs

`stable` trades day-to-day toolchain freshness (developers and CI track current stable)
against formatting-rule drift across rustfmt releases. The drift risk is contained twice:
`style_edition = "2024"` constrains rule changes to the edition's compatibility promise,
and the blocking `--check` on all surfaces surfaces any drift immediately as a check
failure rather than silent reformatting. A frozen channel would trade the reverse and
rot the compiler for the template's real work — the wrong trade.

##### Parameters

Fixed parameters applied: `msrv-policy` (deliberately *not* propagated to `channel`, per
the 2026-09-04 baseline review; the floor lives in `rust-version` + the CI floor job);
`target-os-matrix` (rustup serves `stable` + both components on ubuntu and macOS).
Coordination: R42 (rustup acquisition channel; invocation phrasing) and R28 (shared
`clippy` component entry — input to R28, not a conflict). No `CONFLICT:` line.

##### Migration implications

New file `rust-toolchain.toml` at the repository root with the content above. No other
file changes for this member. CI's toolchain-install step becomes a no-op confirmation
(rustup reads the file automatically); keep an explicit install step only if the chosen
CI action requires one.

##### Validation strategy

Executed 2026-09-26: `rustup toolchain list` showed `stable` active with floor toolchains
co-installed; `cargo fmt --version` reported the component build. Proposed for the
template: on a machine with only the `stable` toolchain and no preinstalled components,
`cargo fmt --check` in the template directory auto-installs/uses the pinned components
via the toolchain file and exits 0 — expected to pass on both CI runners.

##### Confidence & re-verify trigger

High — the mechanism is rustup's documented behavior, the baseline review assigns it
here, and surveyed CIs demonstrate it. Re-verify if rustup changes the toolchain-file
schema, if R28's acceptance disputes the shared `clippy` entry (editorial reconciliation
only), or if the owner revisits the channel-vs-floor separation. Otherwise the quarterly
trigger suffices.

##### Sources

- Local: `rustup toolchain list`, `cargo fmt --version` — observed 2026-09-26.
- `GET https://api.github.com/repos/tokio-rs/tokio/contents/.github/workflows/ci.yml` — 2026-09-26 — `dtolnay/rust-toolchain@stable` + `components: rustfmt` (lines 835–840).
- `GET https://api.github.com/repos/clap-rs/clap/contents/.github/workflows/ci.yml` — 2026-09-26 — `rustup component add rustfmt` (line 239).
- `docs/port/BASELINE-REVIEW.md` (F190/F103, 2026-09-04) — channel decided here, not from the MSRV floor.

#### Pre-commit hook mode (F104) — blocking cargo fmt --check

##### Landscape

Category: what the pre-commit formatter job does — verify-and-block (`--check`) or
write-and-restage (`stage_fixed`). Bins — *built-in/first-party*: `cargo fmt --check`
(exit 1 on unformatted, observed) versus `cargo fmt` + restage; *established industry
standard*: blocking verification — tokio's CI check exits 1 with a "please run rustfmt"
message, clap runs a blocking `rustfmt` CI job, and clap's `.pre-commit-config.yaml`
deliberately carries *no* formatting hook at all (formatting is CI-owned, never
restaged); *up-and-comer*: none — no new hook technology is in play. The divergence to
adjudicate: py blocks (`ruff format --check`, `lefthook.yml:114`), ts writes and
restages (`stage_fixed: true`, `lefthook.yml:32`, via D-020(6)). Notably, none of the
five surveyed Rust projects uses lefthook or a write-mode formatting hook. Authorities:
the surveyed hook configs and CI jobs (fetched), the executed exit-code behavior, and
the two sources' recorded shapes.

##### Principles and implementation

Both modes enforce "no unformatted commit", so the principle alone does not separate
them; fit and ecosystem evidence do, and both favor blocking. First, restaging rewrites
the tree the developer staged and (perhaps) tested: the committed content differs from
what pre-commit checks validated, which is exactly the surface-divergence the shared
principle forbids in spirit. Second, the same-command-everywhere property: blocking lets
the hook run byte-identically the CI step (`cargo fmt --check`), so a hook failure and a
CI failure mean the same thing and carry the same fix ("run `cargo fmt`", as tokio's job
prints). Third, cost: at 0.2 s observed, the convenience argument for auto-fixing in the
hook is negligible — the developer runs one fast command. Fourth, ecosystem unanimity:
zero of five surveyed projects restage formatting; one (clap) explicitly keeps
formatting out of hooks entirely. ts's write mode remains a defensible local choice under
D-020(6) — it is not recorded as drift — but it is not the shape Rust practice supports,
so the template does not import it.

##### Dominant choice

Blocking: the pre-commit job runs `cargo fmt --check` with no write and no `stage_fixed`
(py's shape). Dominant by ecosystem evidence (unanimous blocking among surveyed
projects), by the same-command property, and by tree integrity (never commit what was not
reviewed). Figures are inapplicable (a hook mode has no downloads/issues).

##### Qualified shortlist

Blocking `--check` is the sole qualified candidate.

##### Excluded by gate

- Write-and-restage (`cargo fmt` + `stage_fixed: true`, ts's shape): excluded on fit and
  evidence rather than a numbered gate — no surveyed Rust project uses it, it commits
  unreviewed modifications, and it makes the hook command differ from the CI command.
  Recorded as the considered-and-rejected ts mirror, not an oversight.
- No formatter hook at all (rely on CI only; clap's literal shape): excluded on the
  shared three-surface principle — the sources agree the hook is a surface, and this item
  preserves that agreement. (Clap's choice is noted as evidence for *blocking over
  rewriting*, not for dropping the hook.)

##### Up-and-comers

None. Lefthook's `stage_fixed` mechanism is the only restage technology and it is
assessed above, not emerging.

##### Fit for this template

Exact fit. A template's contributors are disproportionately new to the repo; a blocking
hook that prints "run `cargo fmt`" teaches the workflow once, while silent restaging
teaches nothing and can surprise (a `git commit` that modifies the index mid-flight).
The 0.2 s cost keeps the hook instantaneous, and hook/CI command identity keeps
debugging trivial ("CI failed the same way my hook did").

##### Recommendation

The lefthook pre-commit formatter job runs `cargo fmt --check` (blocking, exit 1 fails
the commit), with no `stage_fixed` and no `exclude` keys (per the F100 member).

##### Ranked runner-up

Write-and-restage per ts/D-020(6). It loses on tree integrity, hook/CI command identity,
and the unanimous surveyed practice. Ranked to record the ts shape's consideration; adopt
it only if a future owner explicitly prefers autofix ergonomics over the blocking
property.

##### Tradeoffs

Blocking trades one manual step (`cargo fmt` after a hook failure) for the guarantee that
what was staged is what gets committed and that every surface speaks the same command.
The cost is one fast, memorable command; the benefit is the absence of an entire class of
"what just changed under me" confusion. Given the hook runs in a fraction of a second,
this is the cheapest guarantee in the stack.

##### Parameters

Consumed: `package-manager-invocation` (R42) — the job is phrased `cargo fmt --check`
with no provisioner prefix. Related: R37 (`hook-manager-distribution`) owns the hook
manager itself; this member assumes lefthook is the manager (as in both sources) and
decides only this job's mode. No `CONFLICT:` line.

##### Migration implications

`lefthook.yml` gains a pre-commit formatter job running `cargo fmt --check` (blocking, no
`stage_fixed`, no `exclude`). No new file for this member.

##### Validation strategy

Executed 2026-09-26: `cargo fmt --check` exited 1 on a corrupted file and 0 after
`cargo fmt` — the exact blocking semantics the hook needs. Proposed for the template:
stage an unformatted file, attempt commit, expect the hook to fail naming the formatter
job; run `cargo fmt`, re-stage, expect the commit to proceed. (Hook-runner behavior is
R37's; this member's expectation is the command's exit code, already observed.)

##### Confidence & re-verify trigger

High. The exit-code contract was observed, the surveyed practice is unanimous, and the
cost is measured negligible. Re-verify only if R37 selects a hook manager without
blocking semantics (unlikely — blocking is definitional for pre-commit) or if a future
owner prefers autofix ergonomics. Otherwise the quarterly trigger suffices.

##### Sources

- Local exit-code probe: `cargo fmt --check` exit 1 corrupted / 0 clean — executed 2026-09-26.
- `GET https://api.github.com/repos/<o>/<r>/contents/{lefthook.yml,.pre-commit-config.yaml,.lefthook.yml}` for all five surveyed projects — 2026-09-26 — no lefthook configs; only clap has a pre-commit config, without any formatting hook.
- `GET https://api.github.com/repos/clap-rs/clap/contents/.pre-commit-config.yaml` — 2026-09-26 — full config (hygiene hooks only).
- Prompt-cited source evidence: py `lefthook.yml:114` (blocks), ts `lefthook.yml:32` (writes + `stage_fixed`).

### Compatibility

Proof the members are tested together, three ways. First, the executed probe ran the
recommended combination as one unit: the four-key `rustfmt.toml` plus `cargo fmt --check`
on both the 1.98.1 stable and the 1.96.0 floor toolchains, with zero nightly warnings —
tool, config, and pin verified together, not in isolation. Second, shared adopters:
tokio-rs/tokio and clap-rs/clap each run the same triple this report recommends
(stable-channel rustfmt component + blocking `--check` gate + zero formatter config),
demonstrating the members compose in production at scale. Third, the version matrix is
degenerate by construction and that is the point: there is exactly one version in play
(the `stable` channel), and `rustfmt.toml` keys, the toolchain pin, the recipe step, the
hook job, and the CI step all ride it — no cross-product of versions exists to go stale.
The `clippy` component entry is the one shared edge (with R28); it is additive (a second
list item) and cannot conflict with any formatting behavior.

### Parameters

This item owns no parameters.

`assumes ci-job-structure` = the full R11 value as recorded in `inputs/parameters.json`
(2026-09-26 snapshot): tiered `ci.yml` with a `plan` detector job, a `hygiene` job
hosting every non-compiling check, and a compiling `check` job — the format check lands
as a step of `hygiene` per that job's stated rule. Assumed unchanged.

`assumes package-manager-invocation` = `invoke a tool whose executable is named
cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as
cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on
PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or
package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias
in the template; test presence by acquisition channel - command -v <executable> for a
tool installed from crates.io or from a release, and the active toolchain's component
state via rustup component list --installed for a tool rustup installs, never
command -v for a rustup component`. Assumed unchanged; every recipe and job in this
answer is already phrased per it.

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release,
declared as rust-version in Cargo.toml and tested in CI` (fixed, owner; resolved to floor
1.96 against observed stable 1.98.1, and executed at 1.96.0).
`assumes rust-edition = 2024` (fixed, owner; carried by `style_edition` and `Cargo.toml`).
`assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed, owner; macOS executed,
Ubuntu via surveyed CI evidence).
`assumes license = MIT OR Apache-2.0` (fixed, owner; rustfmt carries `LICENSE-MIT` and
`LICENSE-APACHE`).

No `CONFLICT:` line is required: the recommendation needs no registered value changed.
For the record, two adjacent items receive inputs rather than conflicts — R28 receives
"the `clippy` component entry in `rust-toolchain.toml` is shared; configuration stays
yours" and "no rustfmt-side exclude list exists on stable, so no shared exclude scope is
possible", and R37 receives "the formatter hook job is blocking `cargo fmt --check` with
no `stage_fixed`".

### Migration implications

File-level changes in the template:

- `rustfmt.toml` (new, repository root): the four keys from the config member, each with
  its one-line source-row comment. No other keys.
- `rust-toolchain.toml` (new, repository root): `[toolchain] channel = "stable"`,
  `components = ["rustfmt", "clippy"]`.
- `Justfile`: new `fmt` recipe (`cargo fmt`), new `fmt-check` recipe
  (`cargo fmt --check`), and the `fmt-check` step added early in the composite recipe
  (recipe names and phrasing finalized per R42).
- `lefthook.yml`: pre-commit formatter job running `cargo fmt --check` — blocking, no
  `stage_fixed`, no `exclude` keys (manager mechanics per R37).
- `.github/workflows/ci.yml`: the same `cargo fmt --check` as a step of the `hygiene`
  job per R11's `ci-job-structure` (non-compiling check slot).
- No drift-test file is created (F162 correctly absent); if hook scaffolding emits a
  default `exclude` stanza on the formatter job, delete it.
- `Cargo.toml`: no dependency added by this item. `rust-version = "1.96"` and
  `edition = "2024"` are assumed from the fixed parameters, not set here.

### Validation strategy

Executed in this run (macOS 15/aarch64, stable 1.98.1 + rustfmt 1.9.0, floor 1.96.0),
all on a scratch workspace under `/tmp/rustfmt-probe`:

1. Eleven-option stability probe: each candidate `rustfmt.toml` key placed alone and
   `rustfmt --check --edition 2024` run. `max_width`, `newline_style`,
   `reorder_imports`, `style_edition`, `hard_tabs`, `use_small_heuristics` applied
   silently; `trailing_comma`, `imports_granularity`, `imports_layout`,
   `group_imports`, `ignore` each printed `Warning: can't set ... nightly channel`.
   The four recommended keys plus `imports_granularity` were re-run under
   `rustup run 1.96.0` with identical results. Expected behavior held: stable keys
   silent, nightly keys warned-and-ignored.
2. Warning-is-nonfatal check: a formatted file with `imports_granularity` set exited 0
   with the warning on stderr — confirming nightly keys are noise, not failures.
3. `#[rustfmt::skip]` write-run: a deliberately misformatted item survived `rustfmt`
   untouched — confirming the escape hatch works on stable.
4. Timing and exit codes: `cargo fmt --check` on a clean tree exited 0 in 0.2 s wall
   time; after a one-line corruption it exited 1 — confirming the speed and blocking
   semantics the F102/F104 members rely on.
5. Toolchain observation: `rustup toolchain list` (stable active, floor co-installed)
   and `cargo fmt --version` (component build of the active toolchain).

Proposed for the template's CI (not executed here — the template does not exist yet):
on both `ubuntu-latest` and `macos-latest`, (a) a CRLF-ended fixture and an
unsorted-imports fixture that `cargo fmt` normalizes and `--check` flags; (b) the
one-line-corruption round-trip through the composite recipe, the lefthook hook, and the
CI step, each expected to fail identically before `cargo fmt` and pass identically
after; (c) a floor-toolchain run asserting no nightly warning appears. Checks 1–5 above
are executed; (a)–(c) are proposed.

### Confidence & re-verify trigger

Overall confidence: high. The tool choice is structural and surveyed-unanimous; the
stable/nightly boundary under every config decision was observed on both ends of the
supported compiler range; the timing and exit-code contracts were measured; and the
hook/composite placements follow fetched production CI, not recollection. The softest
point is the F104 hook-mode evidence — it rests on five projects' configs (none using
lefthook) rather than on a lefthook-user survey — but the unanimity of blocking
enforcement and the 0.2 s cost make the residual risk negligible.

Re-verify triggers (any one reopens the affected member only): rustfmt stabilizes
`ignore`, `imports_granularity`, `group_imports`, or `trailing_comma` (rerun the
eleven-option probe); rustfmt changes a stable default; rustup changes the
toolchain-file schema; R28's accepted answer disputes the shared `clippy` component
entry; R37 selects a hook manager without blocking semantics; or a credible
stable-channel Rust formatter gains production adoption. Otherwise the quarterly
repository trigger suffices.

### Sources

Every figure below was retrieved 2026-09-26; endpoints are quoted verbatim per spec §7.6.

| # | Fact | Endpoint / source |
|---|---|---|
| 1 | rustfmt: 6,974 stars, `archived: false`, `pushed_at: 2026-09-24T13:36:12Z` | `GET https://api.github.com/repos/rust-lang/rustfmt` |
| 2 | rustfmt open issues: `total_count` 718 | `GET https://api.github.com/search/issues?q=repo:rust-lang/rustfmt+is:issue+is:open` |
| 3 | 10 most recent open issues + first maintainer responses (3 answered, median ~0.23 d; 7 unanswered) | `GET https://api.github.com/repos/rust-lang/rustfmt/issues?state=open&sort=created&direction=desc&per_page=10` + per-issue `.../issues/<n>/comments` |
| 4 | `LICENSE-MIT`, `LICENSE-APACHE` in repo root | `GET https://api.github.com/repos/rust-lang/rustfmt/contents/` |
| 5 | `rustfmt-nightly`: 475,872 all-time / 8,368 recent downloads; last release 1.4.21 on 2020-09-06 | `GET https://crates.io/api/v1/crates/rustfmt-nightly`, `.../versions?per_page=5` |
| 6 | `prettyplease`: 510,823,069 all-time / 118,494,924 recent downloads, max 0.3.0; repo 774 stars, 6 open issues, pushed 2026-07-18 | `GET https://crates.io/api/v1/crates/prettyplease`, `GET https://api.github.com/repos/dtolnay/prettyplease`, issue search |
| 7 | No credible file-formatter alternative (`chloro` 776, `cargo-spaced` 94, `prettify` 6,194); no dprint Rust plugin | `GET https://crates.io/api/v1/crates?q=rust+code+formatter`, `?q=dprint+rust` |
| 8 | Topiary: 868 stars, pushed 2026-09-18, "uniform formatter for simple languages", no Rust support evidenced | `GET https://api.github.com/repos/tweag/topiary`, `.../readme` |
| 9 | No recorded advisories (no advisory page, HTTP 404) | `https://rustsec.org/packages/rustfmt-nightly.html`, `https://rustsec.org/packages/prettyplease.html` |
| 10 | tokio 33,246 stars, no `rustfmt.toml`, blocking `fmt` CI job (lines 831–850) | `GET https://api.github.com/repos/tokio-rs/tokio`, `.../contents/rustfmt.toml` (404), `.../contents/.github/workflows/ci.yml` |
| 11 | serde 10,834 stars, no `rustfmt.toml`, no hook configs | `GET https://api.github.com/repos/serde-rs/serde`, `.../contents/rustfmt.toml` (404), hook-config contents calls (404) |
| 12 | crates.io 3,703 stars, no `rustfmt.toml`, no hook configs | `GET https://api.github.com/repos/rust-lang/crates.io`, `.../contents/rustfmt.toml` (404), hook-config contents calls (404) |
| 13 | clap 16,725 stars, no `rustfmt.toml`, blocking `rustfmt` CI job (line 228), pre-commit config without formatting hook | `GET https://api.github.com/repos/clap-rs/clap`, `.../contents/rustfmt.toml` (404), `.../contents/.github/workflows/ci.yml`, `.../contents/.pre-commit-config.yaml` |
| 14 | ripgrep 68,626 stars; `rustfmt.toml` = `max_width = 79`, `use_small_heuristics = "max"`, `edition = "2024"` | `GET https://api.github.com/repos/BurntSushi/ripgrep`, `.../contents/rustfmt.toml` |
| 15 | rust-lang/rust 119,207 stars; `rustfmt.toml` uses `style_edition = "2024"` + nightly-only options | `GET https://api.github.com/repos/rust-lang/rust`, `.../contents/rustfmt.toml` |
| 16 | Stability boundary, warning-is-nonfatal, `#[rustfmt::skip]`, 0.2 s timing, exit 0/1, toolchain observations | Local probes on rustfmt 1.9.0 (stable 1.98.1) and 1.96.0 — executed 2026-09-26 |
| 17 | `cargo fmt` command reference; rustfmt option definitions | `https://doc.rust-lang.org/cargo/commands/cargo-fmt.html`, `https://github.com/rust-lang/rustfmt/blob/main/Configurations.md` — cited 2026-09-26 |
| 18 | Item principle rows and harmonize levels | `docs/port/DIVERGENCE-ANALYSIS.md:111-116` (repository) |
| 19 | `channel`/`components` decided here, not from MSRV floor | `docs/port/BASELINE-REVIEW.md` (F190/F103, 2026-09-04) |
| 20 | Consumed values assumed | run `inputs/parameters.json` (R11/R42 snapshot, 2026-09-26) |
