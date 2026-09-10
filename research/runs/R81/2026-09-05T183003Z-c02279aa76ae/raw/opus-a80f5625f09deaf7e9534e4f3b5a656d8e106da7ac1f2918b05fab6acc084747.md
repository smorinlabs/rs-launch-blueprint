# R81 — docs-delivery-model (bundle) — Opus raw report

All figures retrieved 2026-09-10 unless a different date is stated inline. Current
Rust stable at the time of writing is `1.98.1 (48a229cea 2026-09-01)`
(`https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust] version`,
retrieved 2026-09-10), so `stable minus 2 minor versions` = **1.96**.

### Landscape

**Category this item decides.** The *narrative-documentation delivery channel*: how the
six-category Diátaxis prose corpus that F342 fixes (`about`, `tasks`, `tools`,
`tutorials`, `reference`, `contributing`) reaches a reader — as raw Markdown that a
forge renders, as a generated static site, or both — plus the five mechanics that
follow from that pick (F343 dialect, F344 navigation, F345 landing-page duplication,
F346 README pointer, F351 preview server, F352 scaffold recipe). It does **not**
decide the API-reference channel; rustdoc/`cargo doc` moved to R82 (F353), and this
answer assumes rustdoc-on-docs.rs exists beside whatever this item ships.

**Three-bin map of the Rust field.**

| Bin | Candidates found | Why it lands in this bin |
|---|---|---|
| Built-in / first-party toolchain | **rustdoc** (`cargo doc`, ships with every toolchain — R82's, out of scope here); **mdBook** (`rust-lang/mdBook`, owned by the Rust project itself, `https://api.github.com/repos/rust-lang/mdBook` shows owner `rust-lang`, retrieved 2026-09-10); **no generator at all** — a plain `docs/` tree rendered by GitHub/GitLab, which is the zero-dependency floor | mdBook is not merely popular in Rust: it is the tool the Rust project wrote for, and uses for, its own book-length documentation. "No generator" is listed as a bin member because it is the incumbent in ts and the empirical majority among Rust CLI/library crates (see Practice evidence) |
| Established industry standard | **Zola** (`getzola/zola`, general-purpose Rust SSG, 17,412 stars, `https://api.github.com/repos/getzola/zola`, retrieved 2026-09-10); **Docusaurus**, **Astro Starlight**, **VitePress**, **MkDocs Material** (JavaScript/Python docs generators that can render a Rust project's Markdown without any Rust involvement — Starlight is what ts documented as its unshipped upgrade path, F358) | These are mature, widely deployed docs generators; none is Rust-first, and all but Zola bring a Node or Python toolchain into a Rust template |
| Up-and-comer | **mdBook 0.5 line** itself (0.5.0 2025-11-17, 0.5.4 2026-07-06, `https://crates.io/api/v1/crates/mdbook/versions`, retrieved 2026-09-10) — the first breaking release in ~7 years, adding native admonitions, definition lists, sidebar heading navigation and a split crate API; **mdBook preprocessor ecosystem** (`mdbook-mermaid` 0.17.1, `mdbook-admonish` 1.20.0, `mdbook-alerts` 0.8.0); **`rustdoc` book-adjacent features** (`#![doc = include_str!(...)]` pulling Markdown into rustdoc, which lets a crate's narrative live in rustdoc rather than in a separate site) | The 0.5 line is new enough that its defaults changed materially, and it is the single most consequential fact for this item (see `### Principles and implementation`) |

**Authoritative sources used, and why each counts.**

| Source | Why authoritative |
|---|---|
| `https://rust-lang.github.io/mdBook/` (mdBook User Guide, retrieved 2026-09-10) | The maintainers' own reference documentation, published by the `rust-lang` GitHub organization. It is normative for mdBook's dialect, `SUMMARY.md` grammar, `serve`, `init` and CI guidance |
| `https://raw.githubusercontent.com/rust-lang/mdBook/master/CHANGELOG.md` (retrieved 2026-09-10) | The project's own release record, including a written "0.5 Migration Guide". Establishes exactly which extensions are on by default in 0.5 and what broke from 0.4 |
| `rust-lang/*` documentation repositories (`book`, `reference`, `nomicon`, `rust-by-example`, `rustc-dev-guide`, `api-guidelines`, `rustup`) via `https://api.github.com/repos/<o>/<r>/contents/...` (retrieved 2026-09-10) | Rust project and working-group output. These are the language's own normative documents; what they are built with is the strongest available statement of Rust-project practice, not a blog assertion |
| `https://rustsec.org/packages/mdbook.html` and `https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/mdbook/RUSTSEC-2021-0001.md` (retrieved 2026-09-10) | The Rust Security Response WG's advisory database — the authority for fitness gate 3 |
| `https://github.com/actions/deploy-pages`, `actions/upload-pages-artifact`, `actions/configure-pages` (`action.yml`, releases, retrieved 2026-09-10) | GitHub's own first-party actions; `action.yml` is normative for input semantics and required permissions |
| `https://diataxis.fr/` (Diátaxis, cited via `docs/port/BASELINE-REVIEW.md:467`) | The information-architecture authority F342 rests on; used here only to confirm that this item does not touch the category set |
| `~/c/py-launch-blueprint` at `b08bccfb` and `~/c/ts-launch-blueprint` at `cb1cbcb2` (read through the pin, `git show <pin>:<path>`) | The programme's pinned source implementations — evidence of the two precedents, not winners |

A single blog post is nowhere load-bearing in this report; every mechanism claim
traces to maintainer documentation, a project's own repository contents, or an API
endpoint.

**Practice evidence: what well-regarded Rust projects actually do.** Checked by
requesting `contents/book.toml` (and known alternate paths) and the repository root
listing through `https://api.github.com/repos/<o>/<r>/contents/...`, retrieved
2026-09-10.

| Project | Stars / standing | `book.toml`? | Docs shape observed |
|---|---|---|---|
| `rust-lang/book` | The Rust Programming Language, the language's official book | **yes** (`book.toml`) | mdBook |
| `rust-lang/reference` | The Rust Reference, normative language reference | **yes** | mdBook |
| `rust-lang/nomicon` | The Rustonomicon, the official `unsafe` guide | **yes** | mdBook |
| `rust-lang/rust-by-example` | Official learn-by-example course | **yes** | mdBook |
| `rust-lang/rustc-dev-guide` | Compiler-team onboarding guide | **yes** | mdBook |
| `rust-lang/api-guidelines` | The Rust API Guidelines (library-team output) | **yes** | mdBook |
| `rust-lang/rustup` | The official toolchain installer | **yes** (`doc/user-guide/book.toml`, plus `doc/dev-guide`) | mdBook, two books in-repo |
| `cargo-generate/cargo-generate` | 2,485 stars (`https://api.github.com/search/repositories?q=topic:cargo-generate+stars:>100`, retrieved 2026-09-10); the de facto Rust template-instantiation tool | **yes** (`guide/book.toml`, with `git-repository-url` and `edit-url-template` set) | mdBook — a Rust **CLI tool**, not a language book |
| `BurntSushi/ripgrep` | The reference fast-grep, near-universal in Rust CLI discussion | no | Root `README.md` + root `GUIDE.md`, `FAQ.md`; **no `docs/` directory** |
| `sharkdp/bat` | Widely adopted `cat` replacement | no | `README.md` + a `doc/` folder of loose files; no site |
| `clap-rs/clap` | The dominant Rust CLI argument parser | no | `README.md` + `examples/` + docs.rs; **no `docs/` directory** |
| `serde-rs/serde` | The dominant Rust serialization framework | no | `README.md` + docs.rs; narrative lives on a hand-built `serde.rs` site outside the crate repo |
| `ratatui/ratatui` | The dominant Rust TUI library | no | `README.md` + `ARCHITECTURE.md`; narrative docs live in a **separate repo** `ratatui/ratatui-website` (187 stars) built with Astro Starlight (`astro.config.mjs`, `wrangler.jsonc` in its root listing) |
| `tokio-rs/tokio` | The dominant Rust async runtime | no | Narrative docs in a separate `tokio-rs/website` repo, a bespoke Next.js site |
| `astral-sh/uv` | Newest widely-adopted Rust CLI (Python package manager) | no | MkDocs Material (Python toolchain), not mdBook |
| `rust-github/template`, `ratatui/templates` | Rust project templates, 237 / 420 stars | no | `README.md` only — but these are minimal scaffolds carrying no narrative corpus |

**Reading of the practice evidence (this is the LOW question's answer).** The Rust
field splits by *corpus size*, not by project kind. A project whose narrative
documentation is a handful of paragraphs keeps it in `README.md` and lets docs.rs
carry the API surface — that is ripgrep, clap, serde, ratatui-the-crate, and every
minimal `cargo-generate` template. A project whose narrative documentation is
book-sized builds a site, and when that project is inside or adjacent to the Rust
project itself, the site is mdBook (`rust-lang/*` × 7, `cargo-generate`). Projects
that chose a non-Rust generator (ratatui-website/Starlight, tokio/Next.js,
uv/MkDocs) all did so in a **separate repository**, accepting a second toolchain
rather than putting one in the crate repo. `rs-launch-blueprint` inherits a
book-sized corpus by fiat: F342 fixes six Diátaxis categories, and ts already
carries 39-plus files across them. So the "README-only" bin, which the raw
head-count favors, does not actually describe a project with this template's
corpus.

**Fit framing (survey step 4).** The template presents three reader surfaces at once
— CLI users, library consumers, and web-service operators — and it is a *template*,
so every consumer forks it. That adds two constraints ordinary projects do not have:
the docs system must be readable with zero tooling for the fork's first hour, and any
CI it ships must not fail in a fork that has not configured anything.

### Principles and implementation

**The shared requirement.** Stated at the level of an *architectural pattern plus one
observable policy*, and derived from what py and ts genuinely agree on rather than
from either implementation:

> A contributor writes one Markdown file per documentation topic inside a
> purpose-organized tree; a reader reaches any topic through a navigation index the
> contributor maintains in the repository; and the root `README.md` names exactly one
> entry point into that tree.

Source and agreement level: both pinned repositories satisfy this requirement and
differ only in mechanism. py realizes it as MyST + `{toctree}` + a Sphinx site on
Read the Docs (`.readthedocs.yaml:44` `configuration: docs/source/conf.py`, read
through `b08bccfb`); ts realizes it as CommonMark/GFM + bullet-list indexes rendered
by GitHub (`docs/docs.md:1-8`, read through `cb1cbcb2`: "there is no Sphinx, no MyST,
and no generated site"). The agreement level is therefore **architectural pattern**,
not tool and not policy — which is exactly what `docs/port/BASELINE-REVIEW.md:129`
records for F347 ("both sources prove the page persists across a generator change
while only its mechanics change").

**Essential behaviors.**

1. **Zero-tooling readability.** A reader who lands on the repository with nothing
   installed can read every documentation page. py fails this partially (MyST
   `{toctree}` blocks and `{figure}` directives render as literal junk on GitHub);
   ts satisfies it fully and made it the point of D-023(1).
2. **Single-source navigation.** Exactly one artifact per section states what the
   section contains, and adding a page means editing it. py: `{toctree}`. ts:
   per-directory bullet lists.
3. **One README pointer.** The root `README.md` has one "Documentation" link, not a
   duplicated table of contents. py points at the hosted URL (`README.md:20`); ts
   points at `docs/docs.md` and then re-lists all seven sections inline
   (`README.md:137-148`) — a partial violation ts accepted.
4. **No landing-page duplication.** py duplicates: `docs/source/index.md:1-20`
   repeats the README's badges, logo and pitch. ts eliminated it by merging
   (D-023(5)). Both agree duplication is a defect; they disagree on the cure.
5. **Authorable without a build.** Editing a page must not require a running
   toolchain. py's `sphinx-autobuild` (`Justfile:450`) is a convenience over a
   requirement; ts has no server at all (`docs/docs.md:11-13`).

**Observable acceptance criteria.** (a) Every file under `docs/` renders correctly in
GitHub's Markdown viewer with no literal directive text; (b) every relative link in
`README.md` and under `docs/` resolves to an existing file — R82 owns the checker,
this item owns the property; (c) exactly one navigation artifact per section, and a
page added without registering it there is detectable; (d) the root README's
Documentation section contains one link into the tree; (e) no page's prose is a copy
of another page's prose.

**What must agree, what may vary.** Must agree across py/ts/rs: the pattern above,
the Diátaxis category set (F342, already fixed), and the existence of an authoring
guide (F347, already fixed). May vary by ecosystem: the generator, the hosting
target, the dialect's extension set, and whether a preview server exists — all of
which are `DIVERGENT` in the ledger precisely because they are mechanism.

**Is the shared pattern still appropriate in Rust?** Yes, with one Rust-specific
addition the sources do not have: Rust splits documentation into two channels by
convention — narrative prose, and rustdoc-generated API reference published on
docs.rs automatically for every published crate. `docs/port/BASELINE-REVIEW.md:128`
already flags this ("Rust adds an automatic API-reference channel (rustdoc published
on docs.rs) that R81/R82 must reconcile with the `reference/` category"). This item's
answer must not put API reference into the narrative tree; F353/R82 owns that channel.

**Architectural alternatives compared, before libraries.**

| Alternative | What it is | Verdict for this template |
|---|---|---|
| **A. Generated hosted site only** (py's shape, Rust-native realization: mdBook → GitHub Pages) | `docs/` becomes generator source; readers are expected to use the site | Rejected as stated. It re-imports py's zero-tooling failure: a forked template's `docs/` is unreadable-in-place until someone builds it, and the fork's site does not exist until the fork enables Pages |
| **B. README-centric plain tree only** (ts's shape) | No generator, no site, no preview, no scaffold | Rejected. It is the correct answer for a small corpus and the wrong answer for a fixed six-category Diátaxis corpus with three reader audiences: no search, no cross-page navigation, no single reading order, and — decisively — Rust readers of a *template* expect a book, because every Rust document they learned from is one |
| **C. Dual-readable tree: one Markdown corpus that GitHub renders in place *and* mdBook builds into a site** | `book.toml` at the repo root with `[book] src = "docs"`; the tree stays flat and GitHub-shaped; `SUMMARY.md` is simultaneously mdBook's navigation grammar and a valid GitHub-rendered bullet index | **Recommended.** This is not a compromise between A and B; mdBook 0.5 was designed so that this is the *default* behavior, and the design intent is documented (below) |
| **D. Narrative inside rustdoc** (`#![doc = include_str!("../docs/…")]`) | Fold prose into the crate docs so docs.rs hosts everything | Rejected. It works for a library crate's guide and collapses for a CLI + web-service template: the CLI binary and the web surface have no rustdoc home, and docs.rs would carry contributor-facing content (`contributing/`, `tools/`) that has no business in an API reference |
| **E. Separate documentation repository** (ratatui/tokio shape) | Prose lives in its own repo with its own toolchain | Rejected. A template must be forkable as one unit; a second repository is not inheritable by `cargo generate` |

**Why alternative C is available at all — the load-bearing finding.** mdBook 0.5
deliberately keeps its source tree readable as plain GitHub Markdown. Four mechanisms,
each from the maintainers' own documentation, retrieved 2026-09-10:

1. *Relative `.md` links survive both surfaces.* "Relative links that end with `.md`
   will be converted to the `.html` extension. It is recommended to use `.md` links
   when possible. This is useful when viewing the Markdown file outside of mdBook,
   for example on GitHub or GitLab which render Markdown automatically."
   (`https://rust-lang.github.io/mdBook/format/markdown.html`). The stated design goal
   *is* GitHub-raw fidelity.
2. *`README.md` is the section landing page on both surfaces.* "Links to `README.md`
   will be converted to `index.html`. This is done since some services like GitHub
   render README files automatically" (same page). GitHub auto-renders a directory's
   `README.md` when a reader browses to that directory; mdBook turns the same file
   into that section's `index.html`. mdBook's own guide uses this
   (`cli/README.md`, `format/README.md`, `format/configuration/README.md` in its
   `SUMMARY.md`, `https://rust-lang.github.io/mdBook/format/summary.html`).
3. *Admonitions use GitHub's own alert syntax.* mdBook 0.5.0 "Added support for
   admonitions … enabled by default" (CHANGELOG, 0.5 Migration Guide), written as
   `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`
   (`https://rust-lang.github.io/mdBook/format/markdown.html`). That is exactly GFM's
   alert syntax, which GitHub renders natively. mdBook adopted GitHub's syntax rather
   than inventing one — the opposite of MyST's `:::{note}` colon fences, which py
   enabled at `docs/source/conf.py:32` (`colon_fence`) and which GitHub shows as
   literal text.
4. *`SUMMARY.md` is a plain nested bullet list of relative `.md` links.* Its grammar
   is `- [Title](path/to/file.md)` with `#` part headings and `---` separators
   (`https://rust-lang.github.io/mdBook/format/summary.html`). GitHub renders it as a
   working table of contents with no generator present. It is structurally the same
   artifact ts hand-maintains as its bullet-list index (`ts docs/reference/index.md:5`),
   only centralized into one file instead of scattered across six.

So the DIVERGENT framing in F341 ("generated hosted site **or** README-centric plain
tree") rests on a premise that was true of Sphinx/MyST and is not true of mdBook 0.5:
that adopting a generator costs you the raw-source reader. It does not. The two
principles the sources appeared to trade off — py's "readers get a navigable searchable
site" and ts's "readers need no tooling" — are jointly satisfiable by one tree.

**Where each ecosystem still needs a different design.** py should *not* be told to
adopt this: Sphinx's value there is `sphinx.ext.autodoc` reaching into Python
docstrings, and Python has no docs.rs, so the hosted site is the API channel too.
ts should *not* be told to adopt it either: the equivalent dual-readable generator in
Node is Starlight or VitePress, and D-023(6) already recorded (2026-07-07) that
Starlight is pre-1.0 with 0.x churn and VitePress's stable line was dormant — a
justified ecosystem difference, not drift. Rust is the only one of the three whose
first-party generator both exists and was designed for raw-source fidelity. The
principle is preserved at the architectural-pattern level in all three; the mechanism
differs for a reason each can state.

**Maturity, dependability, representative cost, integration cost.** mdBook is
maintained inside `rust-lang` with an active release cadence (0.5.0 2025-11-17 →
0.5.4 2026-07-06, `https://crates.io/api/v1/crates/mdbook/versions`) and a
`pushed_at` of 2026-09-08 (`https://api.github.com/repos/rust-lang/mdBook`). Its issue
triage lags (566 open, 8 of the 10 most recent issues unanswered — figures and method
in the `mdbook` member below), which is a signal about responsiveness, not about
whether the tool works; the tool is exercised on every build of the Rust
documentation set. Representative cost, stated with configuration rather than
inferred from a benchmark: mdBook's own CI guidance recommends installing it as a
prebuilt release binary (`curl … mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz |
tar -xz`) precisely because that path "is relatively fast, and does not necessarily
require dealing with caching. This does not require installing Rust"
(`https://rust-lang.github.io/mdBook/continuous-integration.html`), and recommends
`cargo install mdbook --no-default-features --features search --vers "^0.5.4"
--locked` when building from source, noting `--no-default-features` "will speed up
the build time significantly" by dropping the `serve` HTTP server. Those are the
maintainers' own qualitative statements; no wall-clock figure is asserted here
because none was measured in this run (see `### Sources`, Method notes).

**Minimal realistic example.** A repository root containing `book.toml` with
`[book] src = "docs"`, a `docs/SUMMARY.md` listing `docs/README.md` as the prefix
chapter and the six Diátaxis sections as parts, one `README.md` per section
directory, and a `justfile` with `docs-build`, `docs-dev`, `docs-init` and
`docs-clean` recipes. Acceptance is checked by the commands in
`### Validation strategy`; none of them was executed in this run, because the Rust
template does not exist yet — they are proposed checks, and the report says so where
it names them.

**BASELINE-REVIEW findings.**

BASELINE-REVIEW: F357 — one orientation page states the internal-docs bucket split and which buckets are normative — replace py's inherited wording ("not part of the published Sphinx site") with an explicit statement of the disposition this item selects, because that wording becomes false under the recommended layout: this report recommends publishing the buckets as a `SUMMARY.md` suffix part, and under a shipped mdBook rooted at `src = "docs"` the internal buckets (`docs/adr/`, `docs/design/`, `docs/research/`, F354–F356) are in the book source either way — listed as chapters, or copied verbatim into the published output if left unlisted — evidence: mdBook, "All other files in the `src` directory will be included in the output" (`https://rust-lang.github.io/mdBook/guide/creating.html`, retrieved 2026-09-10); `docs/port/BASELINE-REVIEW.md:133` records the framing as conditional on R81 shipping a generated site, and this answer ships one. Affected items: F354, F355, F356, F357; no verdict change proposed (all four stay `ADOPT`), only the framing and one placement decision, which this report makes in `### Migration implications`.

BASELINE-REVIEW: F358 — a docs system records the upgrade path it would take if requirements outgrow the shipped delivery model — keep `ADOPT`, and record that under this item's pick the note has a subject and stays short — evidence: `docs/port/BASELINE-REVIEW.md:134` marks the row "blocked pending R81"; with mdBook shipped, the residual risk mdBook does not cover is versioned/multi-language documentation and rich interactive components, and the migration is cheap because the corpus stays CommonMark+GFM — Zola (`getzola/zola`, 17,412 stars, retrieved 2026-09-10) and Astro Starlight both consume a CommonMark tree, so the upgrade path is a generator swap over an unchanged corpus. No Rust-side exclusion of Starlight is asserted, consistent with the 2026-09-04 review finding at `docs/port/BASELINE-REVIEW.md:415`. Affected item: F358 only.

No `BASELINE-REVIEW:` line is raised against F341, F343, F344, F345, F346, F351 or
F352: their `DIVERGENT` verdicts are correct, and this item resolves them.

### Recommendation

**Ship a dual-readable documentation tree: one CommonMark/GFM corpus under `docs/`
that GitHub renders in place, built by `mdbook` 0.5.4 into a GitHub Pages site.**

The stack, with versions:

| Component | Pick | Version pinned for P03 |
|---|---|---|
| Generator | `mdbook` (CLI binary, `cargo install` or prebuilt release) | `0.5.4` (`^0.5.4` in CI per the maintainers' guidance) |
| Book root | `book.toml` at the **repository root**, `[book] src = "docs"`, `[build] create-missing = false` | — |
| Navigation (F344) | `docs/SUMMARY.md`, single authoritative navigation source | mdBook `SUMMARY.md` grammar |
| Dialect (F343) | **GFM ∩ mdBook-0.5-default**: CommonMark + tables + strikethrough + task lists + footnotes + `> [!NOTE]`-style alerts. Heading attributes and definition lists **disabled**; `{{#include}}`, `{{#playground}}`, `hidelines` and `,editable` code attributes **forbidden by the authoring guide** | — |
| Landing pages (F345) | Per-section `README.md` (GitHub auto-renders on directory browse; mdBook emits `index.html`). `docs/README.md` is a short orientation map, **not** a copy of the root README | — |
| README pointer (F346) | One "Documentation" section in the root `README.md` naming `docs/README.md` first and the hosted Pages URL second; **no inline re-listing of the six sections** | — |
| Preview server (F351) | `mdbook serve --open` via `just docs-dev` | built into `mdbook` |
| Scaffold recipe (F352) | `mdbook init` via `just docs-init`, documented as "only for a brand-new book" | built into `mdbook` |
| Hosting | GitHub Pages, `actions/configure-pages` + `actions/upload-pages-artifact` + `actions/deploy-pages` | `v6.0.0` / `v5.0.0` / `v5.0.1` |
| CI shape | An unguarded `docs-build` job (runs in every fork) and a `docs-deploy` job guarded to the upstream repository | — |

### Members

#### mdbook

##### Landscape

Bin: **built-in / first-party toolchain**. `mdbook` is owned by the `rust-lang`
GitHub organization (`https://api.github.com/repos/rust-lang/mdBook`, retrieved
2026-09-10; repository created 2015-07-07) and is the tool the Rust project uses for
its own long-form documentation. The alternatives surveyed in this bin's neighborhood
were Zola (established-standard bin, general SSG), the JavaScript/Python docs
generators (Docusaurus, Astro Starlight, VitePress, MkDocs Material — established
standard, non-Rust toolchain), and "no generator" (the ts incumbent). Up-and-comer
within the same slot: the mdBook 0.5 line itself, first released 2025-11-17, which is
the version this recommendation depends on.

##### Principles and implementation

The principle this member realizes is *single-source navigation over a
purpose-organized Markdown tree, without costing the raw-source reader*. mdBook
realizes it by treating the `.md` tree as canonical and the site as derived: relative
`.md` links are rewritten to `.html` at build time, `README.md` becomes `index.html`,
and `SUMMARY.md` is itself valid Markdown
(`https://rust-lang.github.io/mdBook/format/markdown.html`,
`.../format/summary.html`, retrieved 2026-09-10). The architectural alternative to
mdBook-as-generator is mdBook-as-library: 0.5.0 split the Rust API into `mdbook-driver`,
`mdbook-preprocessor`, `mdbook-renderer`, `mdbook-markdown`, `mdbook-summary`,
`mdbook-html` and `mdbook-core` (CHANGELOG, "0.5 Migration Guide", retrieved
2026-09-10). This template must **not** take that alternative — it needs the CLI
binary as a dev tool, and depending on `mdbook-driver` would put a docs generator into
the workspace's dependency graph and its MSRV surface for no benefit. Reference
implementations: `rust-lang/book`, `rust-lang/reference`, `rust-lang/nomicon`,
`rust-lang/rust-by-example`, `rust-lang/rustc-dev-guide`, `rust-lang/api-guidelines`,
`rust-lang/rustup` (`doc/user-guide/book.toml`), and `cargo-generate/cargo-generate`
(`guide/book.toml`) — each verified by fetching the `book.toml` path through
`https://api.github.com/repos/<o>/<r>/contents/...`, retrieved 2026-09-10.

##### Dominant choice

`mdbook`. Within the Rust ecosystem there is no second candidate for "generated
narrative documentation site": the language's own book, reference, nomicon,
by-example course, compiler guide, API guidelines and toolchain-installer guide are
all mdBook, and the one widely used Rust CLI in this survey with a Diátaxis-sized
corpus (`cargo-generate`, 2,485 stars) is mdBook too.

##### Qualified shortlist

- **`mdbook` 0.5.4** — recommended.
- **`mdbook` 0.4.x line** — qualified but not recommended: 0.4 lacks native
  admonitions and definition lists, so a 0.4 book that wants callouts needs the
  `mdbook-admonish` preprocessor and its non-GFM `` ```admonish `` fence, which
  breaks GitHub-raw fidelity — the exact property this recommendation is built on.
- **`zola`** — qualified only as a general SSG, and only from GitHub releases; see
  *Excluded by gate*.

##### Excluded by gate

- **`zola` (crates.io)** — **fails gate 1 as a crates.io artifact and fails the
  figure protocol.** `GET https://crates.io/api/v1/crates/zola` returns
  `crate.newest_version` `0.0.0`, `crate.recent_downloads` `8`,
  `crate.downloads` `2424`, `crate.repository` `null`, `crate.updated_at`
  `2022-04-12T15:33:36.847581Z`; `GET .../zola/versions` returns exactly one version,
  `0.1.1` (2022-04-12), **yanked**. The crates.io entry is a placeholder, not the
  project. The real project is `getzola/zola`
  (`https://api.github.com/repos/getzola/zola`, retrieved 2026-09-10:
  `stargazers_count` 17,412, `archived` false, `pushed_at` 2026-09-09T19:06:41Z,
  `license.spdx_id` **EUPL-1.2**; `GET https://api.github.com/search/issues?q=repo:getzola/zola+is:issue+is:open`
  → `total_count` 182). Excluded on fit before license even matters: Zola is a
  general-purpose website generator with no book/chapter model, no `SUMMARY.md`
  equivalent, and a Tera-template theme requirement — adopting it means authoring a
  theme, which is strictly more work than mdBook for strictly less documentation
  structure. Its EUPL-1.2 license is noted for completeness: as a build-time binary it
  imposes nothing on this repository's MIT-OR-Apache-2.0 output, but EUPL-1.2 is a
  reciprocal license and would matter if any Zola source were vendored.
- **`mdbook-alerts` 0.8.0** — **fails gate on maintenance.** `GET https://api.github.com/repos/lambdalisue/rs-mdbook-alerts`
  returns `"archived": true` (retrieved 2026-09-10; 65 stars, `pushed_at`
  2025-11-21T06:48:45Z, MIT). Rubric verdict **archived** — the maintainer's own
  notice. It is also functionally obsolete: mdBook 0.5.0 added the same GFM alert
  syntax natively and enabled by default (CHANGELOG, retrieved 2026-09-10).
- **`mdbook-admonish` 1.20.0** — not gate-failed, **excluded on fit**. Figures for the
  record: `GET https://crates.io/api/v1/crates/mdbook-admonish` →
  `recent_downloads` 12,166, `downloads` 195,950; newest non-yanked `1.20.0` created
  `2025-06-06T14:00:17.780046Z`; `GET https://api.github.com/repos/tommilligan/mdbook-admonish`
  → 250 stars, `archived` false, `pushed_at` 2025-10-22T12:41:11Z, MIT;
  `search/issues` open-issue `total_count` 8; `https://rustsec.org/packages/mdbook-admonish.html`
  returns HTTP 404, which on RustSec means no advisory page exists for the crate.
  Excluded because its `` ```admonish note `` fence is not GFM and renders as a bare
  code block on GitHub, and because mdBook 0.5's native `> [!NOTE]` supersedes it.
- **`mdbook-mermaid` 0.17.1** — not gate-failed, **excluded on scope**. Figures:
  `recent_downloads` 81,655, `downloads` 569,231; `0.17.1` created
  `2026-08-14T12:00:13.247024Z`; `https://api.github.com/repos/badboy/mdbook-mermaid`
  → 453 stars, `archived` false, `pushed_at` 2026-08-17T09:40:41Z, MPL-2.0;
  open issues `total_count` 1. Excluded because GitHub renders ```` ```mermaid ````
  fences natively while mdBook 0.5 does not, so adding the preprocessor is a *fidelity
  improvement* available later, not a launch requirement — and this item's dialect
  policy currently contains no diagrams. Recorded as a deliberate, cheap future
  addition rather than a rejection.
- **Docusaurus / Astro Starlight / VitePress / MkDocs Material** — excluded on fit,
  not on any gate: each requires a Node or Python toolchain in a Rust template whose
  entire premise is a single `cargo`-shaped developer environment. Starlight is
  explicitly **not** excluded as a future target (see F358 above and
  `docs/port/BASELINE-REVIEW.md:415`); it is excluded as *this* template's shipped
  generator.

##### Up-and-comers

The mdBook 0.5 line is itself the up-and-comer that changes this item's answer:
0.5.0 (2025-11-17) added native admonitions, definition lists and sidebar heading
navigation, made unknown config fields an error, and moved to a newer
`pulldown-cmark` (CHANGELOG "0.5 Migration Guide", retrieved 2026-09-10). Because
0.5 is under a year old, a P03 implementer reading older mdBook tutorials will find
advice that no longer applies — notably `curly-quotes` (removed, use
`output.html.smart-punctuation`), `output.html.copy-fonts` (removed), and
google-analytics support (removed). The preprocessor ecosystem is the other
up-and-comer surface; `mdbook-mermaid` is the one member of it with adoption figures
that would justify adding later.

##### Fit for this template

The template is CLI + library + web service and is *forked* by every consumer. Three
fit consequences:

1. **Fork readability.** With the dual-readable tree, a fork's `docs/` is fully
   readable on the fork's own GitHub page from minute zero — no build, no Pages, no
   toolchain. mdBook is the only generator surveyed that gives this for free.
2. **No workspace coupling.** `mdbook` is a standalone binary, so it contributes
   nothing to `Cargo.toml`, nothing to the workspace dependency tree, nothing to the
   MSRV surface, and nothing to compile times of `cargo build`/`cargo test`.
3. **Rust-reader expectation.** The template's audience learned Rust from mdBook
   sites; a Rust template whose documentation looks like the Rust Book is legible to
   its readers in a way a bare directory listing is not.

**Answering the prompt's second MEDIUM question directly — is this a fair drop-in for
py's `sphinx-autobuild`/`sphinx-quickstart` UX, or does the Justfile recipe surface
need materially different wiring? It is a drop-in, and the wiring gets *simpler*.**
py's four docs recipes map one-to-one: `docs` → `docs-build` (`mdbook build`),
`docs-dev` → `docs-dev` (`mdbook serve --open`), `init-docs` → `docs-init`
(`mdbook init`), `docs-clean` → `docs-clean`. Two differences, both reductions.
First, py's recipes carry a provisioning prefix (`uv run --group docs …`,
`Justfile:434-455` at pin `b08bccfb`) because Sphinx, `sphinx-autobuild` and
`sphinx-quickstart` are three separate Python packages in a dependency group; mdBook
is one binary, so per R42's resolved rule the recipes are bare `mdbook …` with no
prefix and no install step. Second, py's `docs-help` recipe exists because
`sphinx-build -M help` enumerates output formats (html/latexpdf/epub/htmlzip);
mdBook's HTML renderer needs no such enumeration, so that recipe has no analogue and
is dropped rather than translated. The `docs-init` recipe inherits py's caveat
verbatim — py comments it "Not usually needed, Initialize docs only if you are
starting a new project" (`Justfile:433`, pin `b08bccfb`) — and `mdbook init` earns
the same warning for an additional reason: run inside an existing book it will
generate files from `SUMMARY.md`
(`https://rust-lang.github.io/mdBook/cli/init.html`, retrieved 2026-09-10).

Fitness gates, answered before popularity:

| Gate | Answer |
|---|---|
| 1. License compatible with `MIT OR Apache-2.0` | **Pass, with one operational rule.** `mdbook` is **MPL-2.0** (`crates.io/api/v1/crates/mdbook/versions` → `license: "MPL-2.0"` on 0.5.4; `api.github.com/repos/rust-lang/mdBook` → `license.spdx_id` `MPL-2.0`; both retrieved 2026-09-10). MPL-2.0 is file-level reciprocal: it attaches to MPL-licensed *files*, not to output a binary produces. mdBook is invoked as a build-time tool and is never linked into this template's crates, so it imposes no obligation on the template's code, its `docs/` prose, or the generated HTML content. **Operational rule for P03: do not run `mdbook init --theme` and do not commit a `theme/` directory.** That flag "copies the default theme into a directory called `theme`" (`https://rust-lang.github.io/mdBook/cli/init.html`, retrieved 2026-09-10), which would place MPL-2.0 source files inside an `MIT OR Apache-2.0` repository and create a real licensing question. Theme customization, if ever needed, should go through `output.html.additional-css`, which adds an original file rather than copying MPL files. |
| 2. MSRV within `stable minus 2 minor versions` | **Pass.** `mdbook` 0.5.4 declares `rust_version` `1.88.0` (`GET https://crates.io/api/v1/crates/mdbook/versions`, `rust_version` field, retrieved 2026-09-10). Current stable is `1.98.1` (`https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust] version`, retrieved 2026-09-10), so the policy floor is 1.96 and mdBook's floor sits 8 minors below it. The gate is in any case only about `cargo install mdbook` succeeding on the CI toolchain; mdBook is not in the template's dependency tree, so it contributes nothing to the workspace MSRV. |
| 3. No open RustSec advisory; `unsafe` posture | **Pass.** `https://rustsec.org/packages/mdbook.html` (HTTP 200, retrieved 2026-09-10) lists exactly one advisory, `RUSTSEC-2021-0001` (alias CVE-2020-26297, "XSS in mdBook's search page", categories `code-execution`, CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N). Its advisory file (`https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/mdbook/RUSTSEC-2021-0001.md`, retrieved 2026-09-10) records `patched = [">= 0.4.5"]`, so 0.5.4 is unaffected — **no open advisory**. `unsafe` posture: not asserted from a source audit in this run (see Method notes). The exposure is bounded by role — mdBook runs as a developer/CI tool over the repository's own trusted Markdown and never runs inside the shipped binaries. |
| 4. Builds and is tested on `ubuntu-latest, macos-latest` | **Pass, with prebuilt binaries for both.** Release v0.5.4 publishes `mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz`, `-x86_64-unknown-linux-musl`, `-aarch64-unknown-linux-musl`, `-x86_64-apple-darwin`, `-aarch64-apple-darwin` and `-x86_64-pc-windows-msvc.zip` (`GET https://api.github.com/repos/rust-lang/mdBook/releases/tags/v0.5.4`, `.assets[].name`, retrieved 2026-09-10). mdBook's own CI matrix (`.github/workflows/main.yml`, fetched via `contents` API, retrieved 2026-09-10) runs `ubuntu-latest` (stable/beta/nightly), `ubuntu-22.04`, `ubuntu-24.04-arm`, `macos-latest` (x86_64 and aarch64), `windows-latest` and `windows-11-arm`. Windows is supported though not required by `target-os-matrix`. |
| 5. Default features and async-runtime coupling | **Stated.** Default features include the `serve`/`watch` HTTP server and the built-in `search` index. The maintainers recommend `--no-default-features --features search` for CI, which "disables features like the HTTP server used by `mdbook serve` that is likely not needed on CI" (`https://rust-lang.github.io/mdBook/continuous-integration.html`, retrieved 2026-09-10). **Async-runtime coupling: none for this template.** mdBook's server is internal to the `mdbook` binary process; it is not a library dependency and cannot constrain R05's sync/async decision or R69's web runtime. |
| 6. Binary-size and compile-time cost | **Stated qualitatively, from the maintainers.** Zero cost to the template's own binaries — mdBook is never linked in, so it adds nothing to `cargo build --release` output size or to `cargo test` compile time. Cost is confined to acquiring the tool: the maintainers describe the prebuilt-binary path as "relatively fast … does not require installing Rust", and describe `--no-default-features` on the source path as speeding "up the build time significantly" (same page). No wall-clock or byte figure is asserted; none was measured in this run. |

##### Recommendation

Adopt **`mdbook` 0.5.4** as a developer/CI tool, pinned as `^0.5.4` in CI per the
maintainers' own semver guidance, installed from the prebuilt release archive in CI
and via `cargo install mdbook --locked` (or a prebuilt binary) locally. Configure it
from a repository-root `book.toml` with `[book] src = "docs"` so the corpus keeps a
flat, GitHub-shaped layout — `src` is documented as configurable: "By default, the
source directory is found in the directory named `src` … But this is configurable
with the `src` key in the configuration file"
(`https://rust-lang.github.io/mdBook/format/configuration/general.html`, retrieved
2026-09-10). Set `[build] create-missing = false`, which makes mdBook "exit with an
error if any files do not exist" rather than silently fabricating empty chapters
(same page) — turning `SUMMARY.md` drift into a build failure R82 can gate on. Never
run `mdbook init --theme`; never commit `theme/`.

##### Ranked runner-up

1. **No generator at all** (ts's shape, `docs/` rendered by GitHub only). This is the
   honest runner-up, not Zola: it costs nothing, satisfies zero-tooling readability
   perfectly, and is what most Rust CLI/library repositories do. It loses on search,
   on a defined reading order across six categories, and on matching what a Rust
   reader expects a template's documentation to look like. Adopting the
   recommendation and later deleting `book.toml` recovers this option in one commit,
   because the corpus is identical — which is precisely why the downside risk here is
   small.
2. **`zola`** — a distant second and only as a general SSG; no book model, theme
   authoring required, EUPL-1.2, and no usable crates.io distribution.

##### Tradeoffs

| Gain | Cost |
|---|---|
| Search, sidebar navigation, prev/next chapter flow, a stable published URL | One dev tool to install, one CI job, and a `book.toml` to keep valid — mdBook 0.5 makes unknown config fields an error (CHANGELOG), so a stale key fails the build rather than being ignored |
| Raw `docs/` stays readable on GitHub with no build | The authoring guide must forbid the two default-on non-GFM extensions and the `{{#…}}` helpers; without that discipline the fidelity guarantee erodes silently |
| Zero coupling to the workspace's dependency graph and MSRV | mdBook version drift is invisible to `cargo update`; CI must pin it explicitly |
| Rust-ecosystem legibility | mdBook's issue triage is slow (8 of the 10 most recent issues unanswered, below), so a bug that blocks the template may need a local workaround rather than an upstream fix |

##### Parameters

R81 owns no registry parameter (`research/CLAUDE.md`, R81 row: `owns` = `—`), and its
`## Couplings` block records no `consumes` entry, so this member declares no
`owns`/`assumes` line of its own. It relies on the repo-wide fixed values
`license = MIT OR Apache-2.0`, `target-os-matrix = ubuntu-latest, macos-latest`,
`msrv-policy` and `rust-edition = 2024` (`docs/port/PARAMETERS.md`, read 2026-09-10);
all four are satisfied above. One unregistered coupling is recorded, not a conflict:
`package-manager-invocation` (R42, resolved) says "invoke every other tool as a bare
executable resolved on PATH" and "test presence by acquisition channel — `command -v
<executable>` for a tool installed from crates.io or from a release". `mdbook` is
acquired that way, so recipes call bare `mdbook` and presence is tested with
`command -v mdbook`. No `CONFLICT:` line is emitted; the recommendation needs no
parameter to change.

##### Migration implications

New files: `book.toml` (repository root). Changed files: `justfile` gains
`docs-build`, `docs-dev`, `docs-init`, `docs-clean`; `.gitignore` gains the build
output directory (`book/` by default, or whatever `[build] build-dir` names). No
change to `Cargo.toml`, no change to any crate. The `docs/` tree itself is created by
this bundle's other members.

##### Validation strategy

Proposed, not executed (the Rust template does not exist yet):

```
mdbook build            # expect exit 0; with create-missing=false, a SUMMARY.md
                        # entry with no file must fail instead of being created
mdbook serve --open     # expect a server on localhost:3000 that rebuilds on save
command -v mdbook       # presence test per package-manager-invocation (R42)
```

Executed in this run: the endpoint and documentation queries listed in
`### Sources`. No `mdbook` binary was run.

##### Confidence & re-verify trigger

**High** on the mechanism claims (all four fidelity behaviors are stated in the
maintainers' reference documentation, not inferred) and **high** on the ecosystem
dominance claim (seven `rust-lang/*` repositories plus `cargo-generate` verified by
API). **Medium** on maintenance headroom, because triage responsiveness is weak and
the project's recent commit history is concentrated in one person. Re-verify if:
mdBook publishes 0.6 (the 0.5 defaults this answer depends on could change again);
`https://rustsec.org/packages/mdbook.html` gains an advisory with no patched version;
`api.github.com/repos/rust-lang/mdBook` reports `archived: true` or a `pushed_at`
older than six months; or `rust-lang/book` stops shipping a `book.toml`.

##### Sources

- `GET https://crates.io/api/v1/crates/mdbook` (retrieved 2026-09-10) — `crate.recent_downloads` **867,415**; `crate.downloads` **10,171,618**; `crate.max_stable_version` `0.5.4`; `crate.updated_at` `2026-07-06T19:18:00.019118Z`; `crate.repository` `https://github.com/rust-lang/mdBook`.
- `GET https://crates.io/api/v1/crates/mdbook/versions` (retrieved 2026-09-10) — newest with `yanked: false`: `num` **0.5.4**, `created_at` **2026-07-06T19:18:00.019118Z**, `license` `MPL-2.0`, `rust_version` `1.88.0`. Prior: 0.5.3 (2026-05-19), 0.5.2 (2025-12-11), 0.5.1 (2025-11-20), 0.5.0 (2025-11-17).
- `GET https://api.github.com/repos/rust-lang/mdBook` (retrieved 2026-09-10) — `stargazers_count` **22,127**; `archived` **false**; `pushed_at` **2026-09-08T15:44:55Z**; `license.spdx_id` `MPL-2.0`; `created_at` 2015-07-07T00:57:25Z.
- `GET https://api.github.com/search/issues?q=repo:rust-lang/mdBook+is:issue+is:open` (retrieved 2026-09-10) — `total_count` **566**.
- Issue responsiveness (retrieved 2026-09-10). Method: `GET https://api.github.com/repos/rust-lang/mdBook/issues?state=all&sort=created&direction=desc&per_page=40`, pull requests filtered out, first ten taken (#3221, #3220, #3216, #3215, #3212, #3202, #3201, #3200, #3199, #3197); for each, `GET .../issues/<n>/comments` and the first comment whose `author_association` is `MEMBER`, `OWNER` or `COLLABORATOR` and whose author is not the issue author. Result: **2 of 10 answered** — #3200 in **1.3 days** (opened 2026-08-27T12:34:39Z, replied 2026-08-28T20:39:10Z), #3202 in **10.1 days** (opened 2026-08-29T13:29:05Z, replied 2026-09-08T17:03:46Z, by `GuillaumeGomez`, `MEMBER`). **8 unanswered** as of 2026-09-10, so the **median days to first maintainer response is unbounded** (no response). Maintainer identity corroborated by `GET https://api.github.com/repos/rust-lang/mdBook/commits?per_page=30`: `GuillaumeGomez` authored 16 of the last 30 commits.
- **Maintenance state: `active`.** Rubric application: the six-month no-release trigger does **not** fire (0.5.4 released 2026-07-06, ~2 months before retrieval), `pushed_at` is 2026-09-08 (2 days before retrieval), `archived` is false, there is no unpatched advisory and no maintainer notice. The slow triage and single-maintainer commit concentration are recorded as concrete signals to watch; per the rubric neither is sufficient for `at-risk` (no broken build on current stable, no unpatched advisory, no maintainer notice), so the verdict is `active` with that caveat stated rather than folded into the verdict.
- `https://rustsec.org/packages/mdbook.html` (HTTP 200, retrieved 2026-09-10) and `https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/mdbook/RUSTSEC-2021-0001.md` (retrieved 2026-09-10) — one historical advisory, `patched = [">= 0.4.5"]`; **no open advisory against 0.5.4**.
- Adopters (all retrieved 2026-09-10, via `GET https://api.github.com/repos/<o>/<r>/contents/<path>`): `rust-lang/book` → `book.toml`; `rust-lang/reference` → `book.toml`; `rust-lang/nomicon` → `book.toml`; `rust-lang/rust-by-example` → `book.toml`; `rust-lang/rustc-dev-guide` → `book.toml`; `rust-lang/api-guidelines` → `book.toml`; `rust-lang/rustup` → `doc/user-guide/book.toml` and `doc/dev-guide`; `cargo-generate/cargo-generate` → `guide/book.toml` (contents show `[book] title = "Cargo Generate Documentation"`, `output.html.git-repository-url`, `edit-url-template`, and a tuned `output.html.search` block). Why these are relevant, well-regarded references: the first six are the Rust project's own normative documents produced by its teams and working groups; `rustup` is the official toolchain installer; `cargo-generate` is the 2,485-star de facto template-instantiation tool for Rust and is the closest structural analogue to this template (a Rust CLI with a large narrative corpus).
- Maintainer documentation cited above: `https://rust-lang.github.io/mdBook/format/markdown.html`, `.../format/summary.html`, `.../format/mdbook.html`, `.../format/configuration/general.html`, `.../guide/creating.html`, `.../cli/serve.html`, `.../cli/init.html`, `.../continuous-integration.html`, and `https://raw.githubusercontent.com/rust-lang/mdBook/master/CHANGELOG.md` — all retrieved 2026-09-10.
- `https://static.rust-lang.org/dist/channel-rust-stable.toml` (retrieved 2026-09-10) — `manifest date = 2026-09-03`, `[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`.

#### GitHub Pages deployment (hosting, F341's hosting half)

##### Landscape

Bin: **established industry standard**, realized through first-party GitHub Actions.
This member answers the prompt's second HIGH question: given the owner has already
left Read the Docs' Sphinx-specific hosting model, what hosts the built book. Field
map for hosting a static book produced in a GitHub repository: (a) **GitHub Pages via
the first-party artifact pipeline** — `actions/configure-pages` +
`actions/upload-pages-artifact` + `actions/deploy-pages`; (b) **GitHub Pages via a
`gh-pages` branch push** — the older pattern, which is what mdBook's own repository
still uses (`ci/publish-guide.sh`, fetched 2026-09-10: `git fetch origin gh-pages`,
`git worktree add gh-pages gh-pages`, commit-amend to keep history from ballooning);
(c) **Read the Docs' non-Sphinx path** — RTD does host arbitrary static output, but
this is the model the owner departed from and it adds an external account to a
GitHub-Actions-everywhere repository; (d) **Netlify / Cloudflare Pages** — what
`tokio-rs/website` (`netlify.toml`) and `ratatui/ratatui-website` (`wrangler.jsonc`)
use, each an external service; (e) **no hosting at all** — ts's answer.

##### Principles and implementation

The principle is *the README's documentation pointer resolves for a reader who is not
looking at the repository*. py satisfies it with `https://py-launch-blueprint.readthedocs.io/en/latest/`
(`README.md:20`, read through `b08bccfb`); ts satisfies it only within GitHub, by
pointing at `./docs/docs.md` (`README.md:137`, read through `cb1cbcb2`). The
architectural choice is not "which host" but **"who is allowed to publish"** — and
for a *template*, that is the whole question, because a fork inherits every workflow.
Three designs were compared: publish unconditionally (breaks in every fork that has
not enabled Pages); publish nowhere and document the steps (ts's effective position);
publish from the upstream repository only, with the *build* running everywhere. The
third preserves the principle for the template's own readers while giving every fork
a working docs check on day one and a two-line diff to turn on its own site.

##### Dominant choice

GitHub Pages through the first-party artifact pipeline: `actions/configure-pages`,
`actions/upload-pages-artifact`, `actions/deploy-pages`. All three are published by
the `actions` organization under MIT and are the documented current path for
deploying static output to Pages from a workflow.

##### Qualified shortlist

- **First-party artifact pipeline** (recommended) — `configure-pages@v6.0.0`,
  `upload-pages-artifact@v5.0.0`, `deploy-pages@v5.0.1`.
- **`gh-pages` branch push** — qualified, in production at `rust-lang/mdBook` itself.
  Not recommended: it needs `permissions: contents: write` on the workflow, which is
  a materially wider grant than the artifact pipeline's `pages: write` + `id-token:
  write`, and it puts generated HTML into the repository's git history.
- **`peaceiris/actions-mdbook`** — a third-party action that installs mdBook
  (`https://api.github.com/repos/peaceiris/actions-mdbook`, retrieved 2026-09-10: 329
  stars, MIT, `archived` false, `pushed_at` 2026-05-11T16:49:42Z; latest release
  `v2.0.0` published **2024-04-08T15:39:50Z**). Qualified but not recommended: it
  replaces two lines of `curl | tar` with a third-party supply-chain dependency whose
  last release is over two years old, and the maintainers' own CI guidance describes
  the direct download as the simplest path.

##### Excluded by gate

- **`actions/configure-pages` with `enablement: true`** — **excluded on permissions.**
  The action's own `action.yml` (`https://raw.githubusercontent.com/actions/configure-pages/main/action.yml`,
  retrieved 2026-09-10) documents the input as: "Try to enable Pages for the
  repository if it is not already enabled. **This option requires a token other than
  `GITHUB_TOKEN` to be provided.** In the context of a Personal Access Token, the
  `repo` scope or Pages write permission is required. In the context of a GitHub App,
  the `administration:write` and `pages:write` permissions are required." A template
  cannot ship a workflow that requires a PAT or an installed App to work in a fork, so
  auto-enablement is not the fix for the fork problem. The fix is the repository guard
  below.
- **Read the Docs** — excluded on fit, consistent with the recorded ts rationale
  (D-023(5), `ts docs/port/TS_PORT_DECISIONS.md`, read through `cb1cbcb2`) and the
  owner's existing departure. It adds an external account and a second CI system to a
  repository whose every other gate runs in GitHub Actions.
- **Netlify / Cloudflare Pages** — excluded on fit: an external account and secret
  that a template consumer inherits and cannot use.

##### Up-and-comers

None material. The Pages artifact pipeline is stable and first-party; the movement
visible in the figures is ordinary maintenance (`deploy-pages` v5.0.1 published
2026-09-01, `upload-pages-artifact` v5.0.0 2026-04-10, `configure-pages` v6.0.0
2026-03-25).

##### Fit for this template

Fitness gates, answered per the prompt's rubric with `inapplicable` stated where the
gate presumes a crate:

| Gate | Answer |
|---|---|
| 1. License compatible with `MIT OR Apache-2.0` | **Pass.** All three actions report `license.spdx_id` `MIT` (`GET https://api.github.com/repos/actions/{configure-pages,upload-pages-artifact,deploy-pages}`, retrieved 2026-09-10). |
| 2. MSRV | **`inapplicable`** — these are JavaScript GitHub Actions executed by the runner, not Rust crates; they have no `rust-version` and enter no Cargo dependency tree. |
| 3. RustSec advisory / `unsafe` posture | **`inapplicable`** — RustSec indexes crates.io packages; a GitHub Action has no crates.io identity and therefore no RustSec page. `unsafe` is a Rust concept and does not apply. Supply-chain posture is instead addressed by pinning, which R20 (`third-party-action-pinning-policy`) owns; these are first-party `actions/*` publishers, the lowest-risk category. |
| 4. Runs on `ubuntu-latest, macos-latest` | **Pass, with a design note.** The actions run on any GitHub-hosted runner. The docs job should be pinned to `ubuntu-latest` alone: building the book twice on two operating systems produces one artifact and tests nothing about the docs, so the `target-os-matrix` parameter is satisfied by the *template's* CI covering both operating systems, not by this single job doing so. |
| 5. Default features / async-runtime coupling | **`inapplicable`** — no Cargo features and no Rust runtime are involved. The workflow-level equivalents are stated instead: the deploy job needs `permissions: pages: write, id-token: write` and a `github-pages` `environment`; the build job needs only `contents: read`. |
| 6. Binary-size and compile-time cost | **`inapplicable` for binary size** — nothing is linked. Wall-clock cost is one extra CI job that downloads a ~few-megabyte prebuilt `mdbook` archive and runs `mdbook build`; no figure is asserted, none was measured. |

##### Recommendation

Ship **two jobs, not one**.

1. `docs-build` — runs on every pull request and push, on `ubuntu-latest`, with
   `permissions: contents: read`. It installs `mdbook` from the prebuilt release
   archive, runs `mdbook build`, and uploads the output with
   `actions/upload-pages-artifact@v5.0.0`. **Unguarded**, so every fork gets a
   working documentation check with no configuration.
2. `docs-deploy` — `needs: docs-build`, runs only on the default branch **and** only
   in the upstream repository, guarded by a condition on `github.repository` (or an
   equivalent repository-variable opt-in). It uses
   `actions/configure-pages@v6.0.0` (without `enablement`) and
   `actions/deploy-pages@v5.0.1`, declares `permissions: pages: write` and
   `id-token: write`, and targets the `github-pages` environment.

A fork therefore sees a green docs build immediately and turns on its own site by
enabling Pages and editing one condition. **Cost if wrong:** if the guard is omitted,
every fork's first push produces a red `docs-deploy` job with a Pages-not-enabled
error, which is exactly the kind of inherited breakage a template must not ship; if
the guard is too tight (for example keyed to a branch name a consumer renames), the
upstream site silently stops updating, which the re-verify trigger below catches.

##### Ranked runner-up

1. **`gh-pages` branch push**, as `rust-lang/mdBook` does it — proven, works without
   the Pages artifact pipeline, but needs `contents: write` and stores generated HTML
   in git.
2. **No hosting**, documented as an opt-in with the workflow present but disabled —
   the closest position to ts's, and the fallback if the owner decides a template
   should publish nothing.

##### Tradeoffs

| Gain | Cost |
|---|---|
| The README's documentation pointer resolves for readers who are not browsing the repository, restoring the capability py had | One workflow file, one environment, and a repository-scoped guard that a consumer must understand before their own site works |
| `permissions: pages: write` + `id-token: write` is narrower than the `gh-pages` branch pattern's `contents: write` | The artifact pipeline is a GitHub-hosted-runner feature; a self-hosted-only consumer (R09's territory) would need the branch pattern instead |
| The build job runs everywhere, so documentation breakage is caught in forks | The deploy path is only exercised upstream, so a deploy-only regression is invisible until it reaches the default branch |

##### Parameters

No `owns`, no `assumes` from the registry. **Related, unregistered:** the two-job
shape interacts with `ci-job-structure` (R11, value pending). If R11 resolves to
"every check is a step inside one shared job", the `docs-deploy` half cannot fold in,
because it needs different `permissions` and an `environment` — a job-level split is
required regardless of R11's answer for the general case. This is recorded as a design
constraint for R11 to honor, not as a conflict: R11's parameter does not need to
change, and R81 does not consume it. No `CONFLICT:` line.

##### Migration implications

New file: `.github/workflows/docs.yml` (or two jobs inside whatever workflow R11
selects). New repository setting: Pages source set to "GitHub Actions" on the
upstream repository — a one-time manual step the owner performs, not something the
template can do for itself. `README.md` gains the hosted URL beside the in-repo link
(see the README-pointer member).

##### Validation strategy

Proposed, not executed:

```
gh workflow run docs.yml                       # expect docs-build green, docs-deploy skipped on a fork
gh api repos/<owner>/<repo>/pages --jq .html_url   # expect the published site URL upstream
curl -sSf <pages-url>/index.html > /dev/null   # expect HTTP 200 for the landing page
curl -sSf <pages-url>/reference/index.html     # expect 200: proves README.md -> index.html conversion
```

Executed in this run: the version, license and `action.yml` queries listed under
Sources. No workflow was created or run.

##### Confidence & re-verify trigger

**High** on the permission facts (read from the action's own `action.yml`) and on the
version figures (read from the releases endpoint). **Medium** on the guard design,
which is a judgement about template ergonomics rather than a documented mechanism.
Re-verify if: GitHub publishes a new major of `deploy-pages` or `configure-pages`; the
`enablement` input's token requirement changes (that would make auto-enablement viable
and simplify this member materially); or `gh api repos/<owner>/<repo>/pages` stops
returning the expected `html_url`.

##### Sources

- `GET https://api.github.com/repos/actions/deploy-pages` and `.../releases/latest` (retrieved 2026-09-10) — 952 stars, `archived` false, `pushed_at` 2026-09-07T16:52:52Z, MIT; latest release **v5.0.1**, published **2026-09-01T21:31:19Z**.
- `GET https://api.github.com/repos/actions/upload-pages-artifact` and `.../releases/latest` (retrieved 2026-09-10) — 511 stars, `archived` false, `pushed_at` 2026-08-03T06:24:27Z, MIT; latest release **v5.0.0**, published **2026-04-10T18:22:59Z**.
- `GET https://api.github.com/repos/actions/configure-pages` and `.../releases/latest` (retrieved 2026-09-10) — 241 stars, `archived` false, `pushed_at` 2026-04-02T17:05:58Z, MIT; latest release **v6.0.0**, published **2026-03-25T17:00:49Z**.
- `https://raw.githubusercontent.com/actions/configure-pages/main/action.yml` (retrieved 2026-09-10) — the `enablement` input's documented token requirement, quoted above.
- `GET https://api.github.com/repos/peaceiris/actions-mdbook` and `.../releases/latest` (retrieved 2026-09-10) — 329 stars, MIT, `archived` false, `pushed_at` 2026-05-11T16:49:42Z; latest release `v2.0.0` published 2024-04-08T15:39:50Z.
- `GET https://api.github.com/repos/rust-lang/mdBook/contents/.github/workflows/deploy.yml` and `.../contents/ci/publish-guide.sh` (retrieved 2026-09-10) — mdBook's own `pages` job runs `ci/publish-guide.sh`, which builds with `cargo run --no-default-features -F search -- build guide` and publishes through a `gh-pages` worktree.
- crates.io figures: **`inapplicable`** for all three actions — they are not crates and have no crates.io identity, so `recent_downloads`, `downloads` and version rows cannot be collected by the prescribed rule.
- Issue responsiveness and advisories: **`inapplicable`** for the same reason for RustSec; issue responsiveness was not collected for the three first-party actions, and is recorded as unverified in Method notes rather than estimated.
- **Maintenance state: `active`** for all three (`archived` false; releases within the last six months for `deploy-pages` and `upload-pages-artifact`; `configure-pages`'s last release 2026-03-25 is inside six months of the 2026-09-10 retrieval date, so the trigger does not fire).

#### Markdown dialect policy — GFM ∩ mdBook (F343)

##### Landscape

Bin: **policy over a built-in toolchain surface** — there is no third-party tool to
choose here, only a decision about which syntax the authoring guide permits. The
field of dialects available to a Rust template: (a) **strict CommonMark** — the
zero-risk floor, no tables; (b) **CommonMark + GFM** — tables, strikethrough, task
lists, footnotes, alerts; what GitHub renders and what ts standardized on
(`ts docs/docs.md:3`, read through `cb1cbcb2`); (c) **mdBook 0.5 defaults** — GFM
plus heading attributes and definition lists; (d) **mdBook 0.5 defaults plus
`{{#…}}` helpers** — `{{#include}}`, `{{#playground}}`, `hidelines`, `,editable`
code attributes; (e) **MyST** — py's, Python-only, not available here.

##### Principles and implementation

This member answers the prompt's MEDIUM question directly: *does mdBook introduce
extended syntax that risks rendering-fidelity loss if a reader views the raw source on
GitHub, the same tension MyST created?* The answer is **partly, and the exposure is
smaller and fully controllable — unlike MyST's**.

Measured against GitHub's renderer, mdBook 0.5's default extension set
(`https://rust-lang.github.io/mdBook/format/markdown.html`, retrieved 2026-09-10)
divides in three:

| mdBook 0.5 default extension | Renders correctly on GitHub? | Disposition |
|---|---|---|
| Strikethrough `~~text~~` | Yes — mdBook states it "follows the GitHub Strikethrough extension" | **Allowed** |
| Tables (pipe syntax) | Yes — mdBook cites "the specification for the GitHub Tables extension" | **Allowed** |
| Task lists `- [x]` | Yes — GFM task list extension | **Allowed** |
| Footnotes `[^note]` | Yes — GitHub renders footnotes | **Allowed** |
| Admonitions `> [!NOTE]` … `> [!CAUTION]` | Yes — this is GitHub's own alert syntax; on GitHub it renders as a styled callout, in mdBook as an admonition | **Allowed** |
| Smart punctuation (`--` → –, `...` → …) | Not applicable — it is a *rendering* transform with no source syntax; the source is plain ASCII either way | **Allowed** (no fidelity risk) |
| Heading attributes `# Title { #id .class }` | **No** — GitHub renders the braces as literal text in the heading | **Forbidden by the authoring guide** |
| Definition lists (`term` / `: definition`) | **No** — GitHub renders the `:` lines as literal paragraphs | **Disabled in `book.toml` *and* forbidden** |

And the opt-in, non-default surface, all of it mdBook-only and all of it forbidden
here: `{{#include}}` file inclusion, `{{#playground}}`, Rust `hidelines` (`# ` line
prefixes inside code blocks, which GitHub shows as real code lines — a *silently
wrong* rendering, the worst failure mode), and code-block attributes such as
`,editable` (`https://rust-lang.github.io/mdBook/format/mdbook.html`, retrieved
2026-09-10).

The contrast with MyST is the point. py enabled `colon_fence` and `deflist`
explicitly (`docs/source/conf.py:32-35`, read through `b08bccfb`) and used
`{toctree}` and `{figure}` directives (`docs/source/reference/index.md:4`,
`docs/source/index.md:1`) — syntax with **no GitHub equivalent**, so py's tree could
not be made GitHub-faithful by policy alone; ts had to rewrite files (D-023(3),
which "strip[ped] 8 `{toctree}` blocks, convert[ed] `{figure}` and MyST admonitions").
mdBook's non-GFM surface is two default extensions, one of which has a config switch,
and a set of opt-in helpers nobody is obliged to use. The residual risk is therefore a
**discipline problem with a linting answer**, not a structural incompatibility.

##### Dominant choice

**GFM ∩ mdBook-0.5-default.** Every syntax in the intersection renders identically on
GitHub and in the built book; nothing outside it is used.

##### Qualified shortlist

- **GFM ∩ mdBook-0.5-default** (recommended).
- **mdBook 0.5 defaults as shipped**, accepting two degrading extensions — qualified
  and simpler to configure, but it reintroduces exactly the failure mode ts spent
  D-023(3) removing.
- **Strict CommonMark** — qualified and maximally safe, but it gives up tables, which
  the existing corpus uses heavily (the six-category tree and both source repositories'
  reference sections are table-dense).

##### Excluded by gate

- **MyST** — excluded by ecosystem: `myst_parser` is a Sphinx extension for Python
  (`py docs/source/conf.py:32`, read through `b08bccfb`); there is no Rust consumer.
- **mdBook `{{#include}}` / `{{#playground}}` / `hidelines` / `,editable`** — excluded
  by the fidelity gate this member defines. `hidelines` is excluded most firmly: it
  fails *silently*, showing GitHub readers lines the site hides, so a reviewer reading
  the diff sees different code than a reader of the published page.
- **`mdbook-admonish` fences** — excluded; see the `mdbook` member.

##### Up-and-comers

GitHub's own Markdown surface is the moving part, not mdBook's. GitHub natively
renders a fenced code block whose language tag is `mermaid` as a diagram; mdBook 0.5
does not, which is why diagrams sit outside the intersection today and why `mdbook-mermaid` 0.17.1 is
recorded as the cheap future addition that would move them inside it (figures in the
`mdbook` member).

##### Fit for this template

| Gate | Answer |
|---|---|
| 1. License | **`inapplicable`** — a syntax policy has no license. The files it governs are the template's own, under `MIT OR Apache-2.0`. |
| 2. MSRV | **`inapplicable`** — no crate, no `rust-version`. |
| 3. RustSec / `unsafe` | **`inapplicable`** — no crate. One security-adjacent note that is *not* an advisory: the historical `RUSTSEC-2021-0001` was an XSS in mdBook's generated search page, which is a generator concern already resolved in 0.5.4, not a dialect concern. |
| 4. `ubuntu-latest, macos-latest` | **Pass** — Markdown syntax is platform-independent; the policy is enforced by whatever linter R82 or R29 selects, which must itself run on both. |
| 5. Default features / async coupling | **`inapplicable`**, with the closest analogue stated: the policy requires `output.html.definition-lists = false` in `book.toml`. Heading attributes have no documented disable switch in the material retrieved, so they are handled by the authoring guide and review rather than by configuration — recorded as a known asymmetry. |
| 6. Binary size / compile time | **`inapplicable`** — nothing is compiled. |

##### Recommendation

Adopt **GFM ∩ mdBook-0.5-default** as the template's documentation dialect. Concretely:

1. `book.toml` sets `output.html.definition-lists = false`.
2. The F347 authoring guide (`docs/docs.md`, whose existence is already fixed) states
   the allowed set — CommonMark, tables, strikethrough, task lists, footnotes,
   `> [!NOTE]`-family alerts — and names the forbidden set explicitly: heading
   attributes, definition lists, `{{#include}}`, `{{#playground}}`, `hidelines`
   prefixes, and code-block attributes other than the plain language tag.
3. The rule is stated as a property, not a preference: **every `docs/` file must
   render identically on GitHub and in the built book.**

##### Ranked runner-up

1. **mdBook 0.5 defaults as shipped** — one fewer config line, two degrading
   extensions, and the loss of the property in (3).
2. **Strict CommonMark** — safest and poorest; loses tables.

##### Tradeoffs

| Gain | Cost |
|---|---|
| One corpus, two faithful surfaces, checkable as a property | Two authoring rules a contributor must learn, one of which (heading attributes) is enforced only by review |
| The dialect is a strict subset of what ts already writes, so the ts corpus ports with no rewrite | Definition lists — which py used via `deflist` — are unavailable; glossary content must use tables or bold-term paragraphs |
| Diagrams stay out for now, so no fence renders differently on the two surfaces | Diagram-shaped content must be expressed as tables or images until `mdbook-mermaid` is adopted |

##### Parameters

No `owns`, no `assumes`. No `CONFLICT:`. This member supplies the mechanics that F347
(`COMMON → REUSE`, already decided to exist) will document; per
`docs/port/BASELINE-REVIEW.md:129` that content is downstream of this item, so no
ledger change is proposed for F347.

##### Migration implications

`book.toml` gains `[output.html] definition-lists = false`. `docs/docs.md` (the
authoring guide) gains an "Allowed and forbidden syntax" section. Every ported ts page
is already inside the intersection — D-023(3) recorded the source corpus as "~90%
generator-agnostic CommonMark already" and ts then normalized the remainder — so the
expected rewrite volume for the ts-derived tree is zero, and only py-derived material
(if any is ported directly) needs conversion.

##### Validation strategy

Proposed, not executed:

```
grep -rnE '^\s*#{1,6} .*\{ *#' docs/            # expect no matches: heading attributes
grep -rn '{{#' docs/                            # expect no matches: mdBook helpers
grep -rnE '^: '  docs/                          # expect no matches: definition lists
grep -rn '```rust' -A20 docs/ | grep -n '^# '   # expect no hidelines prefixes
mdbook build && diff <(render-on-github) <(built)   # property statement, not a runnable command
```

The last line is deliberately not presented as executable: no tool was identified in
this run that renders GitHub-flavored Markdown locally with GitHub's exact semantics,
so the property is enforced by the three `grep` guards plus review. Recorded as an
evidence gap.

##### Confidence & re-verify trigger

**High** — the allowed/forbidden split is read directly from mdBook's own dialect
reference and from GitHub's documented alert syntax, and the two degrading extensions
are named in mdBook's 0.5 changelog as new defaults. Re-verify if mdBook enables a new
extension by default (the 0.5.0 entry shows this does happen), if GitHub adds native
rendering for definition lists or heading attributes (which would widen the
intersection), or if `mdbook-mermaid` is adopted.

##### Sources

- `https://rust-lang.github.io/mdBook/format/markdown.html` (retrieved 2026-09-10) — the extension list quoted above, including "This follows the GitHub Strikethrough extension", "See the specification for the GitHub Tables extension", the `> [!NOTE]`/`> [!TIP]`/`> [!IMPORTANT]`/`> [!WARNING]`/`> [!CAUTION]` admonition set, the heading-attribute syntax `# Example heading { #first .class1 .class2 }`, the definition-list syntax and its `output.html.definition-lists` disable switch, and the `.md`→`.html` and `README.md`→`index.html` link conversions.
- `https://rust-lang.github.io/mdBook/format/mdbook.html` (retrieved 2026-09-10) — `hidelines` (`# ` prefix, `[output.html.code.hidelines]`), the Rust playground play button and `noplayground`, and Rust code-block attributes including `ignore` and `editable`.
- `https://raw.githubusercontent.com/rust-lang/mdBook/master/CHANGELOG.md` (retrieved 2026-09-10) — 0.5.0 "Added support for definition lists … enabled by default, with the option `output.html.definition-lists` to disable it" and "Added support for admonitions … enabled by default, with the option `output.html.admonitions` to disable it".
- `py docs/source/conf.py:32-35` and `docs/source/reference/index.md:4`, read through pin `b08bccfb` — `myst_parser`, `myst_heading_anchors = 3`, `myst_enable_extensions = ['colon_fence', 'deflist']`, and a live `{toctree}` block.
- `ts docs/docs.md:1-8` and `docs/reference/index.md:5`, read through pin `cb1cbcb2` — "there is no Sphinx, no MyST, and no generated site … `docs/` is a folder of GitHub-Flavored Markdown (GFM) files that GitHub renders directly", and a plain bullet-list index.
- `ts docs/port/TS_PORT_DECISIONS.md` D-023(3), read through pin `cb1cbcb2` — the "~90% generator-agnostic CommonMark already" measurement (dated 2026-07-07 in the source).
- crates.io / GitHub / RustSec / adopter figures: **`inapplicable`** — this member is a syntax policy, not a crate or an action; the prescribed figure rules have no subject. Its enforcement tooling belongs to R82 and R29.
- **Maintenance state: `inapplicable`** — a policy has no release cadence. The surface it constrains (mdBook 0.5) is `active`; see the `mdbook` member.

#### SUMMARY.md navigation (F344)

##### Landscape

Bin: **built-in toolchain feature**. The navigation mechanisms available: (a)
**`SUMMARY.md`** — mdBook's single, centralized, required navigation file; (b)
**per-directory bullet-list `index.md`** — ts's mechanism (`ts docs/reference/index.md:5`,
read through `cb1cbcb2`); (c) **`{toctree}`** — py's, Sphinx-only
(`py docs/source/reference/index.md:4`, read through `b08bccfb`), unavailable here;
(d) **no index at all**, relying on the directory listing GitHub shows — the
zero-maintenance floor, and what most Rust CLI repositories effectively do.

##### Principles and implementation

The shared principle is *single-source navigation*: exactly one artifact states what a
section contains, and adding a page means editing it. All three source mechanisms
satisfy it; they differ in **where** the single source lives, and that difference has
a consequence this item must decide rather than describe.

mdBook makes `SUMMARY.md` mandatory and authoritative: "The summary file is used by
mdBook to know what chapters to include, in what order they should appear, what their
hierarchy is and where the source files are. **Without this file, there is no book.**"
and "Before a chapter can be viewed, it must be added to this list"
(`https://rust-lang.github.io/mdBook/format/summary.html` and `.../guide/creating.html`,
retrieved 2026-09-10). Its grammar is plain Markdown — `- [Title](path.md)` bullets,
`#` part headings, `---` separators, and `[Title](path.md)` prefix/suffix chapters —
so GitHub renders it as a working table of contents with no generator present.

**The decision this forces.** If the template keeps both `SUMMARY.md` and ts's
per-directory bullet-list `index.md` files, every section's page list exists twice and
the two can drift — reintroducing at the navigation layer exactly the duplication
defect F345 exists to prevent at the landing-page layer. **Decision: `SUMMARY.md` is
the single authoritative navigation source. Per-section pages become prose overviews
that describe the section's purpose and do not enumerate its pages.** They are also
renamed from `index.md` to `README.md`, because mdBook converts `README.md` to
`index.html` while GitHub auto-renders a directory's `README.md` when a reader browses
to that directory — one file, both surfaces. mdBook's own guide uses precisely this
convention: its `SUMMARY.md` lists `cli/README.md`, `format/README.md` and
`format/configuration/README.md` as section chapters
(`https://rust-lang.github.io/mdBook/format/summary.html`, retrieved 2026-09-10). R82
needs this answer to know which file its link walk treats as authoritative: it is
`docs/SUMMARY.md`.

##### Dominant choice

`docs/SUMMARY.md`, in mdBook's documented grammar, as the sole navigation source.

##### Qualified shortlist

- **`SUMMARY.md` alone** (recommended).
- **`SUMMARY.md` plus per-directory link lists** — qualified; mdBook does not forbid
  it, and a reader browsing GitHub inside a subdirectory sees a local list. Rejected on
  the duplication principle; the cure for that reader is that `SUMMARY.md` is one click
  away and GitHub's own directory listing already enumerates the files.
- **Per-directory lists alone** — not available: mdBook requires `SUMMARY.md`.

##### Excluded by gate

- **`{toctree}`** — excluded by ecosystem; it is a Sphinx directive with no Rust
  consumer, and it renders as literal text on GitHub, which is the fidelity failure
  this bundle is designed to eliminate.
- **Draft chapters** (`- [Title]()` with no path, a documented `SUMMARY.md` feature)
  — excluded by policy for this template: they render as disabled links in the book
  and as empty links on GitHub, so they violate the identical-rendering property.
  Recorded as available but unused.

##### Up-and-comers

mdBook 0.5.0 added **sidebar heading navigation** — in-page heading links in the
sidebar, with `output.html.sidebar-header-nav` to disable it (CHANGELOG, retrieved
2026-09-10). This reduces the pressure to split pages finely for navigability, which
is a mild argument for fewer, longer, more readable pages in the ported tree.

##### Fit for this template

| Gate | Answer |
|---|---|
| 1. License | **`inapplicable`** — `SUMMARY.md` is a file the template authors under `MIT OR Apache-2.0`. Its *grammar* is defined by mdBook (MPL-2.0), which no more licenses the file than a compiler licenses source code. |
| 2. MSRV | **`inapplicable`** — no crate. |
| 3. RustSec / `unsafe` | **`inapplicable`** — no crate. |
| 4. `ubuntu-latest, macos-latest` | **Pass** — a Markdown file; `mdbook build` parses it identically on both, and mdBook's CI covers both (see the `mdbook` member). One portability note: `SUMMARY.md` paths are `/`-separated relative paths, which are correct on both target runners. |
| 5. Default features / async coupling | **`inapplicable`**, with the relevant configuration stated instead: `[build] create-missing = false` turns a `SUMMARY.md` entry with no backing file into a build error rather than an auto-created empty page (`https://rust-lang.github.io/mdBook/format/configuration/general.html`, retrieved 2026-09-10). That is what makes navigation drift *detectable*, satisfying acceptance criterion (c). |
| 6. Binary size / compile time | **`inapplicable`** — nothing is compiled. |

##### Recommendation

Ship `docs/SUMMARY.md` as the single navigation source, structured with one `#` part
heading per Diátaxis category and `docs/README.md` as the prefix chapter, with
`[build] create-missing = false` set so that an unregistered or missing page fails the
build. Rename ts's per-directory `index.md` files to `README.md` and rewrite them as
prose overviews with no page enumeration.

##### Ranked runner-up

1. **`SUMMARY.md` plus per-directory link lists**, accepting duplication in exchange
   for in-directory navigation on GitHub. Choose this only if the owner judges
   sub-directory browsing to be a primary reading path.
2. **`SUMMARY.md` plus per-directory `README.md` prose that links only to *adjacent
   sections*, not to its own pages** — a middle position that adds cross-section
   navigation without re-listing pages. Recorded as a viable refinement.

##### Tradeoffs

| Gain | Cost |
|---|---|
| One file to edit when adding a page; drift is a build failure, not a silent omission | A contributor who adds a page and forgets `SUMMARY.md` gets a *missing page* rather than an *unlisted* one — a louder but less obvious failure than ts's, which the authoring guide must explain |
| `SUMMARY.md` renders as a usable table of contents on GitHub with no build | The whole tree's ordering lives in one file, which is a merge-conflict hotspot on branches that both add pages |
| Section `README.md` files serve GitHub directory browsing and the site's `index.html` from one file | Renaming ts's `index.md` files touches every relative link that pointed at them — mechanical, but repository-wide |

##### Parameters

No `owns`, no `assumes`, no `CONFLICT:`. One statement R82 depends on:
**`docs/SUMMARY.md` is the authoritative navigation artifact**, so a link walk should
treat a page reachable from `README.md` and `docs/SUMMARY.md` as reachable, and should
not expect per-directory indexes to enumerate pages.

##### Migration implications

New file: `docs/SUMMARY.md`. Renamed: `docs/<section>/index.md` → `docs/<section>/README.md`
for all six Diátaxis categories. Rewritten: those six files lose their bullet lists and
keep their overview prose. Changed: `book.toml` gains `[build] create-missing = false`.
Every relative link that named `index.md` is updated.

##### Validation strategy

Proposed, not executed:

```
mdbook build                        # with create-missing=false, a SUMMARY entry with no file fails
comm -13 <(sed -nE 's/.*\]\(([^)]+\.md)\).*/\1/p' docs/SUMMARY.md | sort -u) \
         <(cd docs && find . -name '*.md' | sed 's|^\./||' | sort -u)
                                    # expect only the intentionally unlisted internal buckets
grep -c '^- \[' docs/SUMMARY.md     # expect one entry per shipped page
```

Executed in this run: none of the above — the tree does not exist. The `SUMMARY.md`
grammar and the `create-missing` semantics were read from mdBook's documentation.

##### Confidence & re-verify trigger

**High** on the mechanism (grammar, `create-missing`, `README.md`→`index.html`, all
from maintainer documentation, and the `README.md`-as-section-page convention observed
in mdBook's own `SUMMARY.md`). **Medium** on the drop-the-per-directory-lists decision,
which trades a real reader convenience for a real duplication risk and is the kind of
call the owner may reverse. Re-verify if mdBook changes `SUMMARY.md`'s grammar in a
0.6 release, or if R82 selects a link checker that requires a per-directory index.

##### Sources

- `https://rust-lang.github.io/mdBook/format/summary.html` (retrieved 2026-09-10) — "Without this file, there is no book"; the prefix/numbered/suffix chapter, part-title, separator and draft-chapter grammar; and mdBook's own `SUMMARY.md`, which lists `cli/README.md`, `format/README.md` and `format/configuration/README.md` as section pages.
- `https://rust-lang.github.io/mdBook/guide/creating.html` (retrieved 2026-09-10) — "Before a chapter can be viewed, it must be added to this list" and "All other files in the `src` directory will be included in the output".
- `https://rust-lang.github.io/mdBook/format/configuration/general.html` (retrieved 2026-09-10) — `[book] src`, `[build] create-missing` ("If this is false then the build process will instead exit with an error if any files do not exist"), `[build] build-dir`.
- `https://rust-lang.github.io/mdBook/format/markdown.html` (retrieved 2026-09-10) — the `README.md`→`index.html` conversion rule and its stated motivation.
- `py docs/source/reference/index.md:4` (pin `b08bccfb`) — the `{toctree}` directive with `maxdepth: 2`.
- `ts docs/reference/index.md:5` (pin `cb1cbcb2`) — the plain bullet list of four relative links.
- `https://raw.githubusercontent.com/rust-lang/mdBook/master/CHANGELOG.md` (retrieved 2026-09-10) — 0.5.0 sidebar heading navigation and `output.html.sidebar-header-nav`.
- crates.io / GitHub / RustSec / adopter figures and issue responsiveness: **`inapplicable`** — a navigation-file convention is not a distributable package. Adoption evidence is instead the eight `book.toml`-bearing repositories listed in the `mdbook` member, each of which necessarily ships a `SUMMARY.md`.
- **Maintenance state: `inapplicable`** — a file convention has no release cadence.

#### Landing page and README documentation pointer (F345, F346)

##### Landscape

Bin: **policy** — no tool is selected here. The field of positions the two sources and
the Rust ecosystem occupy: (a) **duplicate** — a site landing page that repeats the
README's content (py: `docs/source/index.md:1-20` repeats the logo, badges, title,
tagline and pitch that `README.md:14-24` carries, read through `b08bccfb`); (b)
**merge** — no separate landing page; the README is the landing content, and the
README then re-lists every section (ts: `README.md:137-148`, read through `cb1cbcb2`);
(c) **differentiate** — a short site landing page with a distinct job, and a README
pointer that names one entry point; (d) **README-only**, no docs landing page at all
(ripgrep, clap, serde, ratatui — verified root listings, retrieved 2026-09-10).

##### Principles and implementation

Two principles collide here and this member resolves them:

- *No page's prose is a copy of another page's prose* (acceptance criterion (e)).
  py violates it by duplicating; the ledger records the duplication as the problem
  (F345, `docs/port/COMMONALITY.md:349`).
- *The root README names exactly one entry point* (acceptance criterion (d)). ts's
  merge cures duplication but then re-lists all seven sections inline in the README —
  which recreates the same drift surface one layer up, because a section added to
  `docs/` must now also be added to `README.md`.

Neither source is right by construction. The resolution is to give the two files
**different jobs** rather than the same job in two places:

| File | Job | What it must not do |
|---|---|---|
| `README.md` (repository root) | The forge front door: what the template is, how to instantiate it, the quick start, and **one** "Documentation" section with **one** link into the tree plus the hosted URL | Enumerate the six Diátaxis sections; repeat the docs landing page's orientation prose |
| `docs/README.md` (book landing page, `index.html` on the site) | A short orientation map: what each of the six categories is for and who should read it, in one or two sentences each | Repeat the README's pitch, badges, logo, or quick start |

This satisfies F345 (no duplication — the pages have disjoint content, so there is
nothing to keep in sync) and F346 (one pointer) simultaneously, and it is the only one
of the four positions that satisfies both. It also removes ts's inline section list,
whose maintenance burden ts accepted as the price of having no landing page — a price
that disappears once a landing page with a distinct job exists.

Two mechanism facts make it cheap. First, `docs/README.md` is the book's prefix
chapter and becomes `index.html` (`https://rust-lang.github.io/mdBook/format/markdown.html`,
retrieved 2026-09-10), so no `index.md` is authored and no duplication is created by
the generator. Second, GitHub auto-renders `docs/README.md` when a reader browses to
`docs/`, so the same file is the in-repo landing page — the root README's single link
target and the site's landing page are literally one file.

##### Dominant choice

**Differentiate.** `README.md` is the front door with one Documentation pointer;
`docs/README.md` is a short orientation map that is also the site's landing page.

##### Qualified shortlist

- **Differentiate** (recommended).
- **Merge** (ts's) — qualified and proven; it works, at the cost of an inline
  section list in the README that drifts.
- **Duplicate** (py's) — qualified only in the sense that it functions; it is the
  defect F345 records and is not recommended under any delivery model.

##### Excluded by gate

- **README-only, no docs landing page** — excluded because F342 fixes a six-category
  tree that needs an entry point; a tree with no landing page is navigable only through
  `SUMMARY.md`, which is a table of contents, not an orientation.
- **A generated landing page** (some generators synthesize an index) — excluded
  because mdBook does not synthesize one; the prefix chapter is authored, which is what
  makes the differentiate position available at zero tooling cost.

##### Up-and-comers

None. This is a policy with no moving parts. The one relevant ecosystem observation is
that the Rust projects with the largest narrative corpora (`rust-lang/book`,
`cargo-generate`) keep a terse repository `README.md` that points at the book rather
than reproducing it — the same shape recommended here.

##### Fit for this template

| Gate | Answer |
|---|---|
| 1. License | **`inapplicable`** — a content policy over the template's own files, which are `MIT OR Apache-2.0`. |
| 2. MSRV | **`inapplicable`** — no crate. |
| 3. RustSec / `unsafe` | **`inapplicable`** — no crate. |
| 4. `ubuntu-latest, macos-latest` | **Pass** — Markdown files; nothing is platform-dependent. One caveat worth stating: the hosted URL in the README is only correct once Pages is enabled upstream, so the README must not present it as the primary link until then. |
| 5. Default features / async coupling | **`inapplicable`**; the closest analogue is that `docs/README.md` must be listed as `SUMMARY.md`'s prefix chapter for mdBook to render it as `index.html`. |
| 6. Binary size / compile time | **`inapplicable`** — nothing is compiled. |

##### Recommendation

Root `README.md` carries one section:

```
## Documentation

Full documentation lives in [`docs/`](./docs/README.md) — plain GitHub-Flavored
Markdown, readable here or as a built book at <hosted-pages-url>.
```

`docs/README.md` carries a one-or-two-sentence orientation for each of the six
Diátaxis categories and nothing that appears in `README.md`. Neither file lists the
other's contents. `docs/SUMMARY.md` — not the README — is where the section
enumeration lives.

##### Ranked runner-up

1. **Merge (ts's position)** — keep the README as the only landing content and accept
   the inline section list. Choose this if the owner decides `docs/README.md` cannot
   be kept meaningfully distinct from the README in practice.
2. **Differentiate, but with the hosted URL first and the in-repo link second** — the
   py-leaning variant. Rejected as the default because a forked template has no hosted
   URL, so a fork's README would lead with a dead link.

##### Tradeoffs

| Gain | Cost |
|---|---|
| F345 and F346 are satisfied at once; nothing is duplicated and nothing is re-listed | A reviewer must enforce the "disjoint jobs" rule, which is a judgement, not a `grep` |
| A fork's README link works immediately; the hosted URL is additive | The hosted URL is upstream-specific and becomes stale in a fork unless the consumer edits it — a one-line edit, and the authoring guide should say so |
| One file serves as both the in-repo `docs/` landing page and the site's `index.html` | `docs/README.md` must be the `SUMMARY.md` prefix chapter or the site gets no landing page |

##### Parameters

No `owns`, no `assumes`, no `CONFLICT:`.

##### Migration implications

Changed: `README.md` — the "Documentation" section is reduced from ts's eight-line
bullet list to a single sentence with one link plus the hosted URL. New:
`docs/README.md` (the orientation map and the book's prefix chapter). Not created:
any `docs/index.md`, and any file whose content duplicates `README.md`.

##### Validation strategy

Proposed, not executed:

```
grep -c '](./docs/' README.md            # expect exactly 1 link into the docs tree
test ! -e docs/index.md                  # expect absent: README.md is the landing page
head -1 docs/SUMMARY.md; sed -n '2p' docs/SUMMARY.md   # expect [.. ](README.md) prefix chapter
curl -sSf <pages-url>/ -o /dev/null      # expect 200: docs/README.md became index.html
```

The disjoint-content property has no executable check and is enforced by review;
recorded as an evidence gap.

##### Confidence & re-verify trigger

**High** on the mechanism (`README.md`→`index.html` is documented) and on the
characterization of both sources' positions (read from the pinned files at their
pins). **Medium** on the recommendation itself, which is a content-policy judgement
that departs from both sources rather than following either — the owner may prefer
ts's merge for consistency with the rest of the org's repositories. Re-verify if the
owner reverses the hosted-site decision (the differentiate position loses most of its
value if there is no site) or if F342's directory names change under the pending
disposition recorded at `docs/port/BASELINE-REVIEW.md:280`.

##### Sources

- `py README.md:14-24` and `py docs/source/index.md:1-20`, read through pin `b08bccfb` — the README's "Full documentation on ReadTheDocs" pointer to `https://py-launch-blueprint.readthedocs.io/en/latest/`, and the landing page's duplicated logo/badges/title/tagline.
- `ts README.md:137-148`, read through pin `cb1cbcb2` — "Full documentation lives in [`docs/`](./docs/docs.md) — plain GitHub-Flavored Markdown, no generated site" followed by an inline eight-item section list.
- `ts docs/port/TS_PORT_DECISIONS.md` D-023(5), read through pin `cb1cbcb2` — "merge index.md landing content into README to eliminate duplication".
- `docs/port/COMMONALITY.md:349-350` (F345, F346) — the ledger rows this member resolves.
- `https://rust-lang.github.io/mdBook/format/markdown.html` and `.../format/summary.html` (retrieved 2026-09-10) — `README.md`→`index.html` and the prefix-chapter grammar.
- Root listings of `BurntSushi/ripgrep`, `clap-rs/clap`, `serde-rs/serde`, `ratatui/ratatui` via `GET https://api.github.com/repos/<o>/<r>/contents/` (retrieved 2026-09-10) — none has a `docs/` directory; each is README-plus-docs.rs.
- crates.io / GitHub / RustSec figures and issue responsiveness: **`inapplicable`** — a content policy is not a package.
- **Maintenance state: `inapplicable`** — a policy has no release cadence.

### Compatibility

The members are not independently chosen libraries that must be proved
interoperable; four of the five are policies over one tool's documented behavior, so
compatibility is mostly a property of that tool. Evidence that the combination works
as a whole, in decreasing strength:

1. **A single repository exercises mdBook + `SUMMARY.md` + per-section `README.md` +
   GitHub Pages together: `rust-lang/mdBook` itself.** Its user guide is the book at
   `https://rust-lang.github.io/mdBook/`; its `SUMMARY.md` lists `cli/README.md`,
   `format/README.md` and `format/configuration/README.md` as section chapters
   (`.../format/summary.html`, retrieved 2026-09-10); and its
   `.github/workflows/deploy.yml` contains a `pages` job that runs
   `ci/publish-guide.sh`, which builds with
   `cargo run --no-default-features -F search -- build guide` and publishes to Pages
   (fetched via the contents API, retrieved 2026-09-10). This is the shared-adopter
   proof for the generator, the navigation mechanism, the section-landing-page
   convention and the hosting target in one repository. **One difference is recorded
   rather than glossed:** mdBook publishes through a `gh-pages` worktree, not through
   `actions/deploy-pages`. So this adopter proves mdBook-output-on-GitHub-Pages, not
   the specific first-party action triple.
2. **A second adopter of the same four, at template scale: `cargo-generate/cargo-generate`.**
   `guide/book.toml` sets `output.html.git-repository-url` and `edit-url-template`
   pointing at `.../tree/main/guide` and `.../edit/main/guide/{path}` (contents API,
   retrieved 2026-09-10), which is a book kept in a tool repository and published as a
   site — the exact composition recommended here.
3. **Version matrix.** The four version-bearing components are independent by
   construction: `mdbook` 0.5.4 runs as a process and produces a directory of static
   files; `actions/upload-pages-artifact@v5.0.0` consumes that directory;
   `actions/configure-pages@v6.0.0` and `actions/deploy-pages@v5.0.1` are GitHub's own
   pipeline and know nothing about mdBook. There is no shared dependency, no ABI, no
   linkage, and no version constraint between them beyond "the build job produces a
   directory the upload action can read". The dialect policy and the navigation policy
   are constraints on file content that mdBook 0.5.4 parses by documented behavior.
4. **Where compatibility was *not* proved.** No repository was found in this run that
   runs `mdbook` through `actions/configure-pages` + `upload-pages-artifact` +
   `deploy-pages` specifically. That combination is documented by GitHub as the
   general path for static output and is used pervasively for other generators, but
   this report does not cite a verified mdBook-plus-first-party-triple adopter.
   Recorded as an evidence gap, and it is the single most useful thing for a
   verification pass to close.

### Parameters

**Owned:** none. `research/CLAUDE.md`'s R81 row records `owns` = `—`, and the
prompt's `## Couplings` block has an empty `owns:` list. This item introduces no new
registry parameter; its outputs are ledger-row resolutions (F341, F343, F344, F345,
F346, F351, F352), not a shared value other items read.

**Assumed (consumed):** none from the registry — `## Couplings` records an empty
`consumes:` list. The repo-wide `fixed` values it relies on, all from
`docs/port/PARAMETERS.md` (read 2026-09-10), are satisfied and restated for the record:

- `assumes license = MIT OR Apache-2.0` — satisfied. `mdbook` is MPL-2.0 but is a
  build-time binary, never linked; the three Pages actions are MIT. The one operational
  consequence is the prohibition on `mdbook init --theme` and on committing `theme/`.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied. mdBook
  publishes prebuilt binaries for both and tests on both (plus Windows); the docs job
  itself is pinned to `ubuntu-latest` because building the same book twice tests
  nothing.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — satisfied and largely
  vacuous here: `mdbook` declares `rust_version` 1.88.0 against a 1.96 floor, and it
  contributes nothing to the workspace's own MSRV because it is not a dependency.
- `assumes rust-edition = 2024` — no interaction, except that `book.toml` should set
  `[rust] edition = "2024"` so Rust code blocks in the docs are checked and played
  under the template's own edition (mdBook's default is `"2015"`,
  `https://rust-lang.github.io/mdBook/format/configuration/general.html`, retrieved
  2026-09-10). **This is a real trap:** left at the default, a doc example using
  edition-2024 syntax fails under `mdbook test`.

**Related, unregistered, recorded so the reconciliation can see them — none is a conflict:**

- `package-manager-invocation` (R42, resolved) — its value requires bare-executable
  invocation on PATH for a tool acquired from crates.io or a release, and presence
  testing with `command -v <executable>`. `mdbook` is acquired that way, so recipes
  call bare `mdbook` and the presence test is `command -v mdbook`. The recommendation
  fits the existing value unchanged.
- `ci-job-structure` (R11, value pending) — the docs build and docs deploy halves
  cannot share a job, because they need different `permissions` and the deploy half
  needs an `environment`. R11's parameter does not need to change; this is a
  constraint R11's answer should accommodate.
- `web-extra-surface` (R69, value pending) — out of scope by the prompt, and genuinely
  independent: whether a web surface ships changes what the `docs/` tree *says*, not
  how it is delivered.

**No `CONFLICT:` lines.** No recommendation in this report requires a consumed
parameter to take a different value.

### Migration implications

File-level changes in the template, relative to a tree ported from ts's shape.

**New files**

| Path | Contents |
|---|---|
| `book.toml` (repository root) | `[book] title`, `authors`, `description`, `src = "docs"`, `language = "en"`; `[rust] edition = "2024"`; `[build] build-dir = "book"`, `create-missing = false`; `[output.html] definition-lists = false`, `git-repository-url`, `edit-url-template` |
| `docs/SUMMARY.md` | Prefix chapter `[Overview](README.md)`, then one `#` part heading per Diátaxis category with its pages as `-` bullets |
| `docs/README.md` | The book's landing page and the `docs/` directory's GitHub-rendered index: a short orientation map of the six categories. **Not** a copy of the root README |
| `.github/workflows/docs.yml` | `docs-build` (unguarded, `contents: read`, installs `mdbook` from the prebuilt release archive, `mdbook build`, `actions/upload-pages-artifact@v5.0.0`) and `docs-deploy` (`needs: docs-build`, guarded to the upstream repository and default branch, `pages: write` + `id-token: write`, `github-pages` environment, `actions/configure-pages@v6.0.0` + `actions/deploy-pages@v5.0.1`) |

**Renamed files**

`docs/<section>/index.md` → `docs/<section>/README.md` for all six Diátaxis
categories, so one file serves GitHub directory browsing and the site's section
`index.html`. Every relative link naming `index.md` is updated.

**Changed files**

| Path | Change |
|---|---|
| `README.md` | The "Documentation" section collapses to one sentence with one link to `./docs/README.md` plus the hosted Pages URL; the inline eight-item section list is deleted (it now lives only in `docs/SUMMARY.md`) |
| `docs/docs.md` (the F347 authoring guide) | Moved to `docs/contributing/docs.md` and listed in `docs/SUMMARY.md` under the Contributing part, so it is a chapter rather than a raw file copied into the output (the same rule applied to the internal buckets above). Rewritten mechanics: how to add a page (create the file, register it in `docs/SUMMARY.md`), the allowed/forbidden syntax list, `just docs-dev` for preview, and a note that the hosted URL is upstream-specific and a fork should edit it |
| `docs/<section>/README.md` × 6 | Bullet lists of pages removed; overview prose kept |
| `justfile` | `docs-build` → `mdbook build`; `docs-dev` → `mdbook serve --open`; `docs-init` → `mdbook init` (documented as new-book-only, mirroring py's `init-docs` comment at `Justfile:434`); `docs-clean` → remove the build directory |
| `.gitignore` | Add `/book` (the `[build] build-dir`) |

**A placement decision this report makes, flagged in the F357 baseline review.**
mdBook copies every non-chapter file under `src` into the output verbatim
(`https://rust-lang.github.io/mdBook/guide/creating.html`, retrieved 2026-09-10). With
`src = "docs"`, the internal-docs buckets F354–F356 fix (`adr/`, `design/`,
`research/`) would be copied as raw `.md` into the published site — reachable by URL,
unrendered, and outside navigation. Two dispositions, and this report recommends the
first: **(a) list each bucket's `README.md` in `docs/SUMMARY.md` under a suffix part
named "Project internals"**, which makes them proper chapters and makes py's framing
false rather than half-true. py's exclusion is **structural**, not merely stated:
read firsthand through the pin, `py docs/README.md:1-4` says "Version-controlled
engineering docs that are **not** part of the published Sphinx site
(`docs/source/`)" — the site source is a *subdirectory* of `docs/`, so the buckets sit
outside it by construction. With `src = "docs"` that structural separation is gone,
which is exactly why the framing must be restated rather than inherited; or **(b) move the buckets to a sibling top-level
directory outside the book source**, preserving py's exclusion framing at the cost of
splitting "documentation" across two top-level directories. Whichever the owner picks,
F357's orientation page must state it, which is why the BASELINE-REVIEW line above
exists.

**Not changed:** `Cargo.toml` (no crate dependency is added), any crate source, and
the Diátaxis category set itself (F342, fixed).

### Validation strategy

Every command below is **proposed**; none was executed, because `rs-launch-blueprint`
has no Rust template yet and this is a research programme. The one thing this run did
execute is evidence collection — the endpoints and documentation pages listed under
`### Sources` — and no local build, no `mdbook` invocation and no workflow run.

**Tier 1 — the tool is present and the book builds.**

```
command -v mdbook                       # presence test per R42's acquisition rule
mdbook --version                        # expect 0.5.x
mdbook build                            # expect exit 0 and a populated ./book
```

Expected behavior: with `[build] create-missing = false`, a `SUMMARY.md` entry naming
a file that does not exist must **fail** the build rather than create an empty page.
That is the executable form of acceptance criterion (c).

**Tier 2 — the dual-readability property, which is this answer's whole claim.**

```
grep -rnE '^\s*#{1,6} .*\{ *#' docs/    # expect no output: no heading attributes
grep -rn  '{{#' docs/                   # expect no output: no mdBook-only helpers
grep -rnE '^: ' docs/                   # expect no output: no definition lists
test ! -e docs/index.md                 # expect pass: docs/README.md is the landing page
```

Expected behavior: all four pass on a conforming tree. These are the enforceable part
of the dialect policy. The unenforceable part — that a page renders *identically* on
both surfaces — has no local checker (no tool was found in this run that reproduces
GitHub's renderer exactly), so it is a review rule. **Stated as an evidence gap, not
as a passing check.**

**Tier 3 — navigation is single-source and complete.**

```
comm -13 <(sed -nE 's/.*\]\(([^)]+\.md)\).*/\1/p' docs/SUMMARY.md | sort -u) \
         <(cd docs && find . -name '*.md' | sed 's|^\./||' | sort -u)
```

Expected behavior: the only unlisted files are the internal buckets, if disposition
(b) above is chosen. Under disposition (a), the output is empty.

**Tier 4 — the pointer resolves, and the fork guard holds.**

```
grep -c '](./docs/' README.md                       # expect 1
gh workflow run docs.yml                            # on a fork: docs-build green, docs-deploy skipped
gh api repos/<owner>/<repo>/pages --jq .html_url    # upstream: expect the site URL
curl -sSf <pages-url>/ -o /dev/null                 # expect 200 (docs/README.md -> index.html)
curl -sSf <pages-url>/reference/ -o /dev/null       # expect 200 (section README.md -> index.html)
```

Expected behavior: the last two are the empirical proof that the `README.md` →
`index.html` conversion this whole design rests on actually fired.

**Tier 5 — the item-specific empirical acceptance check.** Build the book, then open
one representative page on both surfaces and compare them element by element:
`docs/reference/README.md` (tables and links), a page containing a `> [!NOTE]` alert,
and a page containing a fenced Rust code block. The check passes when no element
present on one surface is absent or literal on the other. This is the check that
distinguishes the recommendation from its runner-up and it must be run in P03 before
the docs tree is populated at scale — running it after the corpus is written converts
a policy decision into a rewrite.

### Confidence & re-verify trigger

**Overall confidence: high on the mechanism, medium-high on the recommendation.**

What is high-confidence, because it was read from maintainer documentation or an API
rather than inferred: mdBook's dialect and its GFM overlap; the `.md`→`.html` and
`README.md`→`index.html` conversions and their stated GitHub-fidelity motivation;
`SUMMARY.md`'s grammar and mandatory role; `create-missing`, `src` and `[rust] edition`
configuration semantics; `mdbook serve`'s watch-and-refresh behavior and
`mdbook init`'s scaffolding behavior; mdBook's licensing, MSRV, advisory status,
platform coverage and release cadence; the three Pages actions' versions, licenses and
the `enablement` token requirement; and which well-known Rust repositories do and do
not ship a `book.toml`.

What is medium-confidence, because it is judgement rather than a documented mechanism:
the decision to ship a generator at all rather than follow ts (the head-count of Rust
CLI repositories favors README-only, and the counter-argument rests on corpus size, a
reading of the evidence rather than a measurement); dropping per-directory page lists
(a real reader convenience traded for a real duplication risk); and the differentiate
position on F345/F346, which departs from both sources rather than following either.

What is **not verified** and would change the answer if it came back differently:
whether any repository runs mdBook through the first-party Pages action triple
specifically (§`### Compatibility`, gap 4); mdBook's `unsafe` posture from a source
audit; and any wall-clock or byte figure for mdBook's install and build cost.

**Re-verify triggers.**

| Trigger | Why it matters | Where to look |
|---|---|---|
| mdBook publishes 0.6 | 0.5.0 changed default extensions; a 0.6 could widen the non-GFM default surface and break the dual-readability property | `https://crates.io/api/v1/crates/mdbook/versions`; CHANGELOG |
| `https://rustsec.org/packages/mdbook.html` gains an advisory with no patched version | Fitness gate 3 flips | RustSec |
| `api.github.com/repos/rust-lang/mdBook` reports `archived: true`, or `pushed_at` older than six months, or the single-maintainer commit concentration persists alongside a stalled release cadence | Maintenance verdict moves from `active` toward `at-risk`; the runner-up (delete `book.toml`, keep the corpus) becomes live | GitHub repos endpoint; commits endpoint |
| `rust-lang/book` or `cargo-generate` stops shipping a `book.toml` | The ecosystem-dominance argument weakens | contents API |
| `actions/configure-pages` relaxes `enablement`'s token requirement | Auto-enablement becomes viable and the fork guard simplifies | `action.yml` |
| GitHub adds native rendering for definition lists or heading attributes | The allowed dialect widens | GitHub Docs |
| The owner's F342 disposition changes the six directory names (`docs/port/BASELINE-REVIEW.md:280`, pending) | `SUMMARY.md`'s part headings and every section `README.md` path change | The owner |
| R82 selects a link checker that requires per-directory indexes | The F344 single-source decision would need revisiting | R82's answer |

### Sources

Consolidated; per-member sources with their figures appear under each member's
`##### Sources`. All retrievals 2026-09-10 unless stated.

**Registry and figure endpoints**
- `GET https://crates.io/api/v1/crates/mdbook` and `/versions` — 867,415 recent / 10,171,618 all-time downloads; 0.5.4 (2026-07-06), MPL-2.0, `rust_version` 1.88.0.
- `GET https://crates.io/api/v1/crates/{zola,mdbook-admonish,mdbook-alerts,mdbook-mermaid}` and `/versions` — figures in the `mdbook` member's *Excluded by gate*.
- `GET https://api.github.com/repos/{rust-lang/mdBook,getzola/zola,tommilligan/mdbook-admonish,badboy/mdbook-mermaid,lambdalisue/rs-mdbook-alerts,actions/deploy-pages,actions/configure-pages,actions/upload-pages-artifact,peaceiris/actions-mdbook,ratatui/ratatui-website}`.
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for `rust-lang/mdBook` (566), `getzola/zola` (182), `tommilligan/mdbook-admonish` (8), `badboy/mdbook-mermaid` (1), `lambdalisue/rs-mdbook-alerts` (3).
- `GET https://api.github.com/repos/rust-lang/mdBook/issues?...`, `/issues/<n>/comments`, `/commits?per_page=30` — the responsiveness method and result in the `mdbook` member.
- `https://rustsec.org/packages/mdbook.html` (200), `.../mdbook-admonish.html` (404), `.../mdbook-mermaid.html` (404); `https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/mdbook/RUSTSEC-2021-0001.md`.
- `GET https://api.github.com/repos/rust-lang/mdBook/releases/tags/v0.5.4` — the six prebuilt asset names.
- `GET https://api.github.com/repos/<o>/<r>/contents/...` for the adopter and non-adopter survey: `rust-lang/{book,reference,nomicon,rust-by-example,rustc-dev-guide,api-guidelines,rustup,cargo,mdBook}`, `cargo-generate/cargo-generate`, `BurntSushi/ripgrep`, `sharkdp/bat`, `sharkdp/fd`, `clap-rs/clap`, `serde-rs/serde`, `ratatui/ratatui`, `tokio-rs/{tokio,website}`, `astral-sh/uv`, `rust-github/template`, `ratatui/templates`.
- `GET https://api.github.com/search/repositories?q=topic:cargo-generate+stars:>100&sort=stars` — the template survey behind the LOW question.
- `https://static.rust-lang.org/dist/channel-rust-stable.toml` — stable `1.98.1 (48a229cea 2026-09-01)`, manifest date 2026-09-03.

**Maintainer documentation**
- `https://rust-lang.github.io/mdBook/` — `format/markdown.html`, `format/mdbook.html`, `format/summary.html`, `format/configuration/general.html`, `guide/creating.html`, `cli/serve.html`, `cli/init.html`, `continuous-integration.html`.
- `https://raw.githubusercontent.com/rust-lang/mdBook/master/CHANGELOG.md` — the 0.5 Migration Guide and 0.5.0–0.5.4 entries.
- `https://raw.githubusercontent.com/actions/configure-pages/main/action.yml` — the `enablement` input.

**Pinned source repositories** (read through their pins, never from the working tree)
- `~/c/py-launch-blueprint` at **`b08bccfb`**: `.readthedocs.yaml` (`sphinx: configuration: docs/source/conf.py`, `formats: pdf, epub, htmlzip`), `docs/source/conf.py` (`myst_parser`, `myst_heading_anchors = 3`, `myst_enable_extensions = ['colon_fence','deflist']`, `sphinx.ext.autodoc`), `docs/source/index.md`, `docs/source/reference/index.md` (`{toctree}`), `README.md`, `Justfile` (`init-docs` → `sphinx-quickstart`; `docs-dev` → `sphinx-autobuild`; `docs`, `docs-help`, `docs-clean`).
- `~/c/ts-launch-blueprint` at **`cb1cbcb2`**: `docs/docs.md`, `docs/reference/index.md`, `README.md`, `docs/port/TS_PORT_DECISIONS.md` (D-023(1) through D-023(6)).

**Repository context** (read, not modified)
- `docs/port/COMMONALITY.md:345-362` (F341–F358), `docs/port/PARAMETERS.md`, `docs/port/BASELINE-REVIEW.md:128-134, 144, 255, 280, 333-334, 414-415, 445, 467, 476`, `research/CLAUDE.md`, and the run's `inputs/prompt.md`.

**Method notes**

Figures were collected from `https://crates.io/api/v1/crates/<name>` and `/versions`
(with a User-Agent header), `https://api.github.com/repos/<o>/<r>`,
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`,
`https://api.github.com/repos/<o>/<r>/releases/{latest,tags/<tag>}`,
`https://api.github.com/repos/<o>/<r>/contents/<path>`,
`https://api.github.com/search/repositories`, `https://rustsec.org/packages/<name>.html`,
the RustSec advisory-db raw files, `https://static.rust-lang.org/dist/channel-rust-stable.toml`,
and the mdBook User Guide and CHANGELOG. The unauthenticated
`https://api.github.com/repos/...` endpoint returned HTTP 403 "API rate limit
exceeded" partway through the run; those queries were re-issued through the
authenticated `gh api` client against the same REST paths, and every GitHub figure in
this report comes from an authenticated response. The `search/issues` counts were
obtained both ways and agreed. Open-issue counts use `search/issues` `total_count`,
never `open_issues_count`, per the prompt's rule.

Not verified, stated as gaps rather than estimated: (1) no repository was found that
runs `mdbook` through `actions/configure-pages` + `actions/upload-pages-artifact` +
`actions/deploy-pages` specifically — mdBook's own repository publishes through a
`gh-pages` worktree instead, so the shared-adopter proof covers mdBook-on-Pages but
not the first-party action triple; (2) mdBook's `unsafe` posture was not established
from a source audit or a `cargo-geiger` run, only bounded by its build-time-tool role;
(3) no wall-clock or byte figure is asserted for installing or running `mdbook` —
nothing was timed in this run, and the cost statements are the maintainers' own
qualitative wording; (4) issue-responsiveness figures were not collected for
`actions/configure-pages`, `actions/upload-pages-artifact` or `actions/deploy-pages`;
(5) no local renderer reproducing GitHub's exact Markdown semantics was identified, so
the "renders identically on both surfaces" property is enforced by three `grep` guards
plus review rather than by a checker; (6) `https://api.github.com/repos/rust-lang/cargo/contents/src/doc`
returned 404, so Cargo's book location was not confirmed — Cargo has a top-level `doc`
directory, but its `book.toml` path was not verified and Cargo is therefore **not**
counted among the eight verified mdBook adopters; (7) no Rust code was written, no
`mdbook` binary was executed, and no workflow was created — every command in
`### Validation strategy` is proposed.
