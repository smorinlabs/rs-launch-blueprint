# R81 — docs-delivery-model (bundle, Focused) — DECISION (revision 1, 2026-09-10)

## Decision

**Status.** This decision is a **proposal to be validated in the implementation
phase against the real template** (owner ruling, 2026-09-10). P02 is research
only: `rs-launch-blueprint` has no Rust template yet, P03 builds it, and P03's CI
is what proves these recommendations. What this decision records is what the
research found, what this run verified, and what it could not verify; the
unverified parts are listed under `## Engines` as what P03 must validate. A
recommendation that does not survive implementation is **revised against this
recorded research**, not researched again from scratch. No owner acceptance is
claimed or implied.

**Recommendation — one corpus, decided unconditionally; one generator layer,
decided conditionally.** Ship a single CommonMark/GFM documentation corpus under
`docs/` that GitHub renders in place and that an mdBook build could consume
unchanged. Whether the mdBook build and its GitHub Pages deployment actually ship
is **conditional on an owner ruling that does not exist** — see **the licence
condition** below, which every conditional sentence in this decision refers back
to. Absent that ruling, **branch B ships**.

| Ledger row | Corpus / mechanism | Branch A — the owner rules that fitness gate 1 does **not** reach a never-linked build-time binary | Branch B — the owner rules that it **does**, or rules nothing (the default) |
|---|---|---|---|
| **F341** delivery model | one `docs/` tree, GitHub-renderable in place | the same tree **plus** `mdbook` 0.5.4 → GitHub Pages | the same tree, **no generator, no site** (ts's shape) |
| **F343** markdown dialect | **GFM ∩ mdBook-0.5-default**: CommonMark + tables + strikethrough + task lists + footnotes + `> [!NOTE]`-family alerts. Forbidden: heading attributes `{ #id }`, definition lists, `{{#include}}`, `{{#playground}}`, `hidelines`, code-block attributes beyond the language tag | identical | identical |
| **F344** section navigation | `docs/SUMMARY.md` as the single navigation source, in mdBook's `SUMMARY.md` grammar (a plain nested bullet list of relative `.md` links, which GitHub renders as a working table of contents with no generator present); per-section `README.md` files carry prose overviews and do **not** re-list their pages | identical; drift is a build failure via `[build] create-missing = false` | identical file; drift is caught by R82's link walk instead, because no build exists to fail |
| **F345** landing-page duplication | **differentiate**: root `README.md` is the forge front door; `docs/README.md` is a short orientation map with disjoint content. No `docs/index.md` | identical (`docs/README.md` is also the book's prefix chapter → `index.html`) | identical (`docs/README.md` is what GitHub auto-renders when a reader browses `docs/`) |
| **F346** README pointer | one "Documentation" section with **one** link into the tree; no inline re-listing of the categories | that link, then the hosted Pages URL second | that link only; no hosted URL exists |
| **F351** local preview server | — | `mdbook serve --open` via `just docs-dev` | **none** (an editor preview or a pushed branch, as ts directs) |
| **F352** scaffold/init recipe | — | `mdbook init` via `just docs-init`, documented as new-book-only | **none** |

The corpus row and F343/F344/F345 are the same artifact under both branches, so
the branch choice is a **one-commit move in either direction**: branch A adds
`book.toml`, `.github/workflows/docs.yml` and the hosted URL to the README;
branch B removes them. Nothing in the prose, the file layout, the dialect or the
navigation file changes. The dialect row's purpose — one corpus that reads
correctly on both surfaces — is a design property supported by the maintainers'
documented conversion rules (check 5) and by GitHub's own renderer on the GitHub
side (check 6); it is **not** verified as identical rendering, and `## Engines`
gap 2 records what would verify it.

**The licence condition (this decision does not resolve it).** `mdbook` 0.5.4
declares `license: MPL-2.0` (`GET https://crates.io/api/v1/crates/mdbook/versions`,
newest unyanked `0.5.4`, `rust_version` `1.88.0`, retrieved 2026-09-10; check 2)
and `rust-lang/mdBook` reports `license.spdx_id` `MPL-2.0` (check 3). MPL-2.0's
reciprocity is file-level: Mozilla's own FAQ states that "The MPL's 'file-level'
copyleft is designed to encourage contributors to share modifications they make
to your code, while still allowing them to combine your code with code under
other licenses (open or proprietary) with minimal restrictions"
(`https://www.mozilla.org/en-US/MPL/2.0/FAQ/`, retrieved 2026-09-10; check 9).
mdBook is invoked as a separate build-time process and is never linked into this
template's crates.

Fitness gate 1 requires compatibility with the fixed `license = MIT OR Apache-2.0`,
and `docs/port/PARAMETERS.md` words that gate as "candidate crates must be
compatible". **Whether gate 1 reaches a tool that is never linked into the shipped
artifact is an owner ruling, and no owner ruling exists.** The same unmade ruling
is already recorded against R42: its published decision
(`research/topics/42-dev-toolchain-provisioning/DECISION.md`, "The licence finding
on `cargo-binstall`, stated as a finding and not as a ruling") says of the
mere-aggregation argument "**That argument is recorded, not adopted:** whether
gate 1 covers separate-process developer tools is an owner ruling, and no owner
ruling exists". This decision takes the same position and adds nothing to it. Two
differences from R42's case are stated so the owner is not deciding a false
equivalence: R42's candidate was GPL-3.0-only, whose reciprocity is not
file-scoped, and R42's candidate had a licence-clean drop-in replacement
(`cargo install --locked`) whereas this item's branch-B substitute is the removal
of the tool rather than its replacement.

**The dependency tree was walked, and it is clean of anything stronger than
MPL-2.0.** Resolving `mdbook = "=0.5.4"` produced a lock of 218 registry packages
(`review/evidence/mdbook-0.5.4-Cargo.lock`); each package's declared licence was
read from `GET https://crates.io/api/v1/crates/<name>/<version>` (check 8,
retrieved 2026-09-10). Exactly **8** are MPL-2.0 and they are exactly the mdBook
family — `mdbook`, `mdbook-core`, `mdbook-driver`, `mdbook-html`,
`mdbook-markdown`, `mdbook-preprocessor`, `mdbook-renderer`, `mdbook-summary`,
all `0.5.4`. The other 210 are permissive (120 `MIT OR Apache-2.0`, 49 `MIT`, the
remainder Apache-2.0, ISC, BSD, Unlicense and equivalent disjunctions). **No
GPL, AGPL, LGPL-only, EUPL or SSPL package appears anywhere in the tree.** Two
tree facts are recorded rather than glossed: `font-awesome-as-a-crate` 0.3.1 is
`CC-BY-4.0 AND MIT`, an attribution obligation that would attach to bundled icon
assets **if** mdBook's default theme emits them into the built site — this run
did not build a site and therefore did not confirm that it does, so P03 must
check it under branch A; and `r-efi` 5.3.0/6.0.0 offer
`MIT OR Apache-2.0 OR LGPL-2.1-or-later`, a disjunction whose permissive arms
are selectable, not an LGPL obligation.

**The substitute under branch B, and why no third-party substitute is named.**
The substitute is **no generator**: the same corpus, rendered by GitHub, which is
`codex`'s recommendation in full and `opus`'s own stated runner-up. It introduces
no crate and therefore has **no dependency tree to walk**, which is precisely
what makes it clean under either reading of gate 1. A permissively licensed
generator that would keep the book model was searched for and none is offered:
`cobalt-bin` 0.20.4 is `MIT` (check 2) but is a blog-shaped static-site generator
with no chapter/`SUMMARY.md` model and no documentation-site adoption evidence in
this survey; `zola`'s crates.io entry is a placeholder whose only version `0.1.1`
is yanked (check 2) and the real project `getzola/zola` is **EUPL-1.2** (check 3),
a stronger reciprocity than MPL-2.0, so it is worse on the very gate it would be
offered to satisfy; Docusaurus, Astro Starlight, VitePress and MkDocs Material are
MIT-family but require a Node or Python toolchain in a Cargo-shaped template, and
**their npm/pip dependency trees were not audited in this run, so they are not
offered as a substitute**. No surveyed candidate passes fit *and* carries an
audited tree.

**Rules that hold under both branches.** Never run `mdbook init --theme` and
never commit a `theme/` directory: that flag copies the default theme into the
source tree (`https://rust-lang.github.io/mdBook/cli/init.html`, "When you use the
`--theme` flag, the default theme will be copied into a directory called `theme`
in your source directory so that you can modify it", retrieved 2026-09-10;
check 5), which would place MPL-2.0 files inside an `MIT OR Apache-2.0`
repository and create a licensing question that no ruling about build-time
binaries answers. Under branch B the rule is vacuous because no mdBook command is
run; it is recorded so a later promotion to branch A cannot lose it. Theme
customization, if ever wanted under branch A, goes through
`output.html.additional-css`, which adds an original file rather than copying MPL
files.

**Ledger rows settled** (verdict strings remain the controller's to set, per
`docs/port/README.md`): **F341** — decided as the two-branch answer above, with
branch B as the default absent a ruling; **F343**, **F344**, **F345** — decided
unconditionally; **F346**, **F351**, **F352** — decided per branch. F342 (the
Diátaxis category set) and F347 (the authoring guide's existence) are untouched;
this item supplies F347's content mechanics only. F353 is R82's.

**Baseline-review lines, carried through unresolved.** Neither is resolved here;
both are recorded for the reconciliation.

BASELINE-REVIEW: F357 — one orientation page states the internal-docs bucket split and which buckets are normative — replace py's inherited wording ("not part of the published Sphinx site") with an explicit statement of the disposition selected, because that wording is false under branch A and true only by construction under branch B — evidence: py's exclusion is structural, `py docs/README.md:1-4` at pin `b08bccfb` scopes the site to the `docs/source/` subdirectory, so the internal buckets sit outside it; under branch A with `[book] src = "docs"` mdBook states "All other files in the `src` directory will be included in the output" (`https://rust-lang.github.io/mdBook/guide/creating.html`, retrieved 2026-09-10; check 5), so `docs/adr/`, `docs/design/` and `docs/research/` (F354–F356) are in the book source either as listed chapters or as verbatim copies; `docs/port/BASELINE-REVIEW.md:133` records the framing as conditional on R81 shipping a generated site. Affected items: F354, F355, F356, F357. No verdict change proposed (all four stay `ADOPT`); the placement choice under branch A — list the buckets as a `SUMMARY.md` suffix part, or move them to a sibling top-level directory outside the book source — is **not made here** and is an owner disposition.

BASELINE-REVIEW: F358 — a docs system records the upgrade path it would take if requirements outgrow the shipped delivery model — keep `ADOPT`, and record that the note's subject is branch-dependent: under branch B the upgrade path is mdBook itself (one commit, unchanged corpus); under branch A the residual gap mdBook does not cover is versioned or multi-language documentation and rich interactive components, and the migration is a generator swap over an unchanged CommonMark corpus — evidence: `docs/port/BASELINE-REVIEW.md:134` marks the row "blocked pending R81" and `:415` records that Astro Starlight is "documented, not shipped" in ts and is neither designated nor excluded for Rust; both `codex` and `opus` raise this row and agree the note should name a trigger and a fresh decision rather than a preselected generator. Affected item: F358 only.

### Principles and implementation

**Shared requirement, its source and agreement level.** A contributor writes one
Markdown file per documentation topic inside a purpose-organized tree; a reader
reaches any topic through a navigation index the contributor maintains in the
repository; and the root `README.md` names exactly one entry point into that
tree. Both pinned sources satisfy this and differ only in mechanism — py through
MyST + `{toctree}` + a Sphinx site on Read the Docs
(`py .readthedocs.yaml:44`, `docs/source/conf.py:32`, read through pin
`b08bccfb`), ts through CommonMark/GFM + bullet-list indexes rendered by GitHub
(`ts docs/docs.md:1-8`, `docs/reference/index.md:5`, read through pin
`cb1cbcb2`). The agreement level is therefore **architectural pattern**, not tool
and not policy, which is what `docs/port/BASELINE-REVIEW.md:129` already records
for F347.

**Essential behaviors.** (1) *Zero-tooling readability* — a reader with nothing
installed can read every page; py fails this partially because `{toctree}` and
`{figure}` render as literal text on GitHub, ts satisfies it fully. (2)
*Single-source navigation* — exactly one artifact per section states what it
contains. (3) *One README pointer* — one "Documentation" link, not a duplicated
table of contents; ts partially violates this by re-listing seven sections inline
at `README.md:137-148`. (4) *No landing-page duplication* — py duplicates its
README into `docs/source/index.md`; ts eliminated it by merging. (5) *Authorable
without a build* — editing a page must not require a running toolchain.

**Observable acceptance criteria.** (a) Every file under `docs/` renders
correctly in GitHub's Markdown viewer with no literal directive text; (b) every
relative link in `README.md` and under `docs/` resolves to an existing file —
R82 owns the checker, this item owns the property; (c) exactly one navigation
artifact per section, and a page added without registering it there is
detectable; (d) the root README's Documentation section contains one link into
the tree; (e) no page's prose is a copy of another page's prose.

**What must agree, what may vary.** Must agree across py, ts and rs: the pattern
above, the Diátaxis category set (F342, fixed) and the existence of an authoring
guide (F347, fixed). May vary by ecosystem: the generator, the hosting target,
the dialect's extension set and whether a preview server exists — the rows the
ledger marks `DIVERGENT` precisely because they are mechanism. Neither py nor ts
should be told to adopt this item's answer: Sphinx's value in py is
`sphinx.ext.autodoc` reaching into Python docstrings and Python has no docs.rs,
so py's hosted site is also its API channel; and ts's equivalent dual-readable
generator would be Starlight or VitePress, which ts's D-023(6) already declined
on maturity grounds (`ts docs/port/TS_PORT_DECISIONS.md`, pin `cb1cbcb2`). Rust
is the only one of the three whose first-party generator both exists and is
documented as preserving raw-source fidelity.

**Architectural alternatives compared, before any tool was chosen.** (A)
*Generated hosted site only* (py's shape) — rejected: a forked template's `docs/`
would be unreadable in place until someone built it. (B) *README-centric plain
tree only* (ts's shape) — not rejected; it is branch B and the default absent a
ruling. Its costs are stated rather than dismissed: no search, no defined reading
order across six categories, and no pointer that resolves for a reader who is not
browsing the repository. (C) *Dual-readable tree — one corpus that GitHub renders
in place and that mdBook can build* — recommended for the corpus, and for the
generator layer under branch A. (D) *Narrative inside rustdoc*
(`#![doc = include_str!(…)]`) — rejected: a CLI binary and a web surface have no
rustdoc home, and contributor-facing content has no business in an API
reference. (E) *Separate documentation repository* (the ratatui/tokio shape) —
rejected: a template must be forkable as one unit.

**Why the recommended corpus preserves each principle, and the evidence that it
does.** The dual-readable property rests on four documented mdBook behaviors,
each verified against the maintainers' current pages in this run (check 5) rather
than carried from the raws: relative `.md` links are converted to `.html` and
"It is recommended to use `.md` links when possible. This is useful when viewing
the Markdown file outside of mdBook, for example on GitHub or GitLab"; "Links to
`README.md` will be converted to `index.html`. This is done since some services
like GitHub render README files automatically"; admonitions are written as
GitHub's own alert syntax (`> [!NOTE]` and its family); and `SUMMARY.md` is
itself plain Markdown, without which "there is no book". Behaviors (1) and (5)
therefore hold under both branches; (2) holds through `docs/SUMMARY.md`; (3) and
(4) hold through the differentiate policy in the branch table.

**The dialect claim was tested against GitHub's own renderer, not asserted.**
`POST https://api.github.com/markdown` with `mode: gfm` (check 6, 2026-09-10)
returned, for one four-element input: `> [!NOTE]` rendered as
`<div class="markdown-alert markdown-alert-note">`; `# Head { #id .cls }`
rendered as `<h1>Head { #id .cls }</h1>`, braces literal; a definition-list pair
rendered as one `<p>term<br>: definition</p>`; and `[link](./other.md)` kept its
`.md` href. That is the empirical basis for the allowed set and for the two
forbidden default extensions. **It is not a proof of identical rendering**: the
endpoint renders GitHub's side only, no mdBook output was produced in this run,
and no differential comparison was made — see `## Engines`, gap 2.

**Reference implementations, with what this run verified marked.** Under branch A the closest
structural analogues are `rust-lang/goals` and `Spotifyd/spotifyd`, each of which
runs mdBook through the first-party GitHub Pages action triple in a committed
workflow (check 7, blobs pinned by SHA); `cargo-generate/cargo-generate` keeps an
mdBook guide inside the tool's own repository (`guide/book.toml`, `opus`
raw, retrieved 2026-09-10, not re-verified here). Under branch B the reference
implementation is `ts-launch-blueprint` itself at pin `cb1cbcb2`, plus the
majority Rust CLI shape (`ripgrep`, `clap`, `serde`, `ratatui` — README plus
docs.rs, `opus` raw, retrieved 2026-09-10, not re-verified here).

**Cost, stated qualitatively and not measured.** Under branch A the template's
own binaries are unaffected: mdBook is never linked, so it adds nothing to
`cargo build --release` output size or to `cargo test` compile time, and it
enters no `Cargo.toml`. The cost is acquiring the tool; mdBook's own CI guidance
recommends the prebuilt release archive because that path "is relatively fast,
and does not necessarily require dealing with caching", and recommends
`--no-default-features --features search` for a source install because it
"Disables features like the HTTP server used by `mdbook serve`" (check 5). **No
wall-clock or byte figure is asserted; nothing was timed or built in this run.**

**Minimal realistic example, as a description and not as built code.** Under
branch B: `docs/README.md` (orientation map), `docs/SUMMARY.md` (the navigation
index), six category directories each with a `README.md` prose overview, and a
root `README.md` whose Documentation section is one sentence with one link. Under
branch A the same tree plus `book.toml` at the repository root with
`[book] src = "docs"`, `[rust] edition = "2024"` (mdBook's default is `"2015"`,
so leaving it unset would make an edition-2024 doc example fail under
`mdbook test`), `[build] create-missing = false`, `[output.html]
definition-lists = false`; a `justfile` with `docs-build`, `docs-dev`,
`docs-init`, `docs-clean` invoking bare `mdbook` per R42's resolved
`package-manager-invocation`; and `.github/workflows/docs.yml` with an unguarded
`docs-build` job (`contents: read`) plus a `docs-deploy` job guarded to the
upstream repository and the default branch (`pages: write`, `id-token: write`,
`github-pages` environment). **This example was not built.**

re-verify: when the owner rules on whether fitness gate 1 reaches never-linked build-time binaries; or on mdBook 0.6; or 2027-03-10, whichever is first.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

R81 owns no registry parameter: the prompt's `## Couplings` block records an
empty `- owns:` line and an empty `- consumes:` line, and `research/CLAUDE.md`'s
R81 row records `owns` = `—`. This item's outputs are ledger-row resolutions, not
a shared value other items read. **No `CONFLICT:` line is emitted**; no
recommendation here needs a consumed parameter to take a different value. The
four values above were generated from `docs/port/PARAMETERS.md` and diffed
against this file rather than typed (check 10).

How each fixed parameter bears on the decision. `license` is the parameter the
whole F341 branch turns on — see the licence condition in `## Decision`; under
branch B no third-party tool is involved and the gate has no subject.
`target-os-matrix` is satisfied under both branches: Markdown is
platform-independent, and under branch A mdBook publishes prebuilt binaries for
Linux and macOS (both x86_64 and aarch64) at release v0.5.4, with the docs job
itself pinned to `ubuntu-latest` because building the same book twice tests
nothing. `msrv-policy` is satisfied under branch A and has no subject under
branch B; under branch A it is also largely vacuous, because `mdbook` 0.5.4 declares
`rust_version` 1.88.0 against a floor of 1.96 (stable `1.98.1`, per `opus`
raw, retrieved 2026-09-10), and it contributes nothing to the workspace MSRV
because it is not a dependency. `rust-edition` has one branch-A consequence
already stated in the minimal example: `book.toml` must set
`[rust] edition = "2024"`, because mdBook's default is `"2015"`.

One unregistered coupling is recorded, and it is not a conflict:
`package-manager-invocation` (R42, resolved) requires bare-executable invocation
on `PATH` for a tool acquired from crates.io or a release, and presence testing
with `command -v <executable>`. Under branch A `mdbook` is acquired that way, so
recipes call bare `mdbook` and the presence test is `command -v mdbook`. A second
is recorded for R11: under branch A the docs build and docs deploy halves cannot
share one job, because they need different `permissions` and the deploy half
needs an `environment` — a constraint `ci-job-structure` should accommodate, not
a value that must change.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `gh 2.98.0`;
`Darwin 25.4.0 arm64`, macOS 26.4. All retrieval timestamps are UTC.

**Working directory and what was written.** The check script is
`review/evidence/docs-delivery-claims.sh` and runs from the run directory
`research/runs/R81/2026-09-05T183003Z-c02279aa76ae`. It writes only inside
`review/evidence/` (the log and `review/evidence/snapshots/`). The one input it
needs on disk is `review/evidence/mdbook-0.5.4-Cargo.lock` (plus, for check 8's
default mode, `review/evidence/mdbook-0.5.4-licences.json`, described below). The
lock was produced **outside
the repository** in the session scratchpad from a two-field `Cargo.toml` naming
`mdbook = "=0.5.4"` and an empty `main.rs`; `cargo metadata` refused to include
mdbook ("ignoring invalid dependency `mdbook` which is missing a lib target" —
mdBook 0.5 is a binary-only crate), so the resolution was read from the
`Cargo.lock` Cargo generated. That lock is a **snapshot of the resolution on
2026-09-10**; a later resolution may select newer compatible dependency versions.

**How check 8 avoids lying about a rate-limited sweep.** The full walk — one
crates.io request per package, 218 of them, 0.12 s apart — was run once on
2026-09-10 and its result is committed as
`review/evidence/mdbook-0.5.4-licences.json`. A second full sweep in the same
session was refused by crates.io with HTTP 429 for every package, which would
have printed a wall of `ERROR` rather than a licence. So the script's default
mode recomputes the summary from that snapshot, asserts that the snapshot's key
set equals the lock's package set, and **re-queries a fixed 12-package sample
live** (the eight `mdbook*` crates, `font-awesome-as-a-crate`, `r-efi`,
`pulldown-cmark`, `handlebars`), failing if any live answer differs from the
snapshot. Passing `--full-walk` re-queries all 218 at wider spacing. The
published licence of a published crate version does not change, which is why a
snapshot is legitimate evidence here and a snapshot of a download counter would
not be.

**Nothing recommended was implemented.** No `docs/` tree, no `book.toml`, no
`SUMMARY.md`, no workflow, no template scaffold and no acceptance script was
written. `mdbook` was not installed and was never executed; no book was built,
no generator was initialised, and nothing was deployed. Every check below queries
a recorded endpoint, reads a maintained project's committed blob at a pinned SHA,
reads a snapshot of the maintainers' documentation, or reads a file this run
already created outside the repository.

`set -o pipefail` is set at the top of the script and every check asserts on the
content it expected, not on an exit code alone; the script exits non-zero if any
assertion fails. As run, it made **52 assertions, all `PASS`, exit status 0**.
Three assertions failed on the first run and are recorded here rather than
quietly fixed: the RustSec advisory field is `patched`, not `patched_versions`;
a grep count for mdBook installation in the `rust-lang/goals` workflow returned
2 because that workflow installs `mdbook-mermaid` as well; and the parameter
round-trip pointed `awk` at the wrong repository root. All three were defects in
the check, not in the claims.

| # | Check | Command | Exit | Result | Log |
|---|---|---|---:|---|---|
| 1 | Toolchain and host | `rustc --version`; `cargo --version`; `gh --version`; `uname`; `sw_vers` | 0 | recorded above | `evidence/docs-delivery-claims.log` |
| 2 | crates.io licences and versions | `GET https://crates.io/api/v1/crates/<name>/versions` for `mdbook`, `cobalt-bin`, `mdbook-mermaid`, `mdbook-admonish`, `mdbook-alerts`, `zola` | 0 | `mdbook` 0.5.4 **MPL-2.0** `rust_version` 1.88.0; `cobalt-bin` 0.20.4 **MIT**; `mdbook-mermaid` 0.17.1 **MPL-2.0**; `mdbook-admonish` 1.20.0 MIT; `mdbook-alerts` 0.8.0 MIT; **`zola` has no unyanked version** — one version, `0.1.1`, `yanked: true`, so the registry entry is a placeholder, not the project | same |
| 3 | GitHub repository facts | `gh api repos/<o>/<r>` for `rust-lang/mdBook`, `getzola/zola`, `lambdalisue/rs-mdbook-alerts`, `badboy/mdbook-mermaid`, `actions/{configure-pages,upload-pages-artifact,deploy-pages}` | 0 | `rust-lang/mdBook` `MPL-2.0`, `archived: false`; `getzola/zola` **`EUPL-1.2`**, `archived: false`; `lambdalisue/rs-mdbook-alerts` **`archived: true`** (the archived component — excluded here, not recommended); `badboy/mdbook-mermaid` `archived: false`; all three Pages actions `MIT`, `archived: false` | same |
| 4 | RustSec | `curl -o /dev/null -w '%{http_code}' https://rustsec.org/packages/{mdbook,mdbook-mermaid}.html`; the advisory-db raw file for `RUSTSEC-2021-0001` | 0 | `mdbook` page **200**, `mdbook-mermaid` **404** (the 404/200 pair shows 404 means "no advisory page", not a transport failure); the advisory records `patched = [">= 0.4.5"]`, so 0.5.4 carries **no open advisory** | same |
| 5 | Maintainer-documentation claims | `curl` of six mdBook User Guide pages into `evidence/snapshots/`, then tag-stripped substring assertions | 0 | all present: the `.md`→`.html` rule and its stated GitHub motivation; `README.md`→`index.html`; the `> [!NOTE]` admonition family; the definition-list section and its `definition-lists` switch; the heading-attribute example `{ #first .class1 .class2 }`; "Without this file, there is no book"; `[book] src` configurability; `create-missing`; the `[rust] edition` default `"2015"`; `--theme` copies the default theme into `theme`; "All other files in the `src` directory will be included in the output"; the CI page's prebuilt-binary and `--no-default-features` wording | same |
| 6 | GitHub's renderer, on the dialect | `POST https://api.github.com/markdown` (`mode: gfm`) on one four-element input | 0 | alert → `markdown-alert-note` div; heading attributes → literal `{ #id .cls }` inside `<h1>`; definition list → one `<p>` with a literal `: definition`; `./other.md` href preserved | same |
| 7 | Adopters of mdBook + the first-party Pages triple | `gh api repos/rust-lang/goals/git/blobs/4dce369a600e57b9cae2e2a5b3edca0a27942ecc`; `.../Spotifyd/spotifyd/git/blobs/8dfc018421bca766fe7c1d772b5a6dfc3c1a1bd3`; `gh api repos/rust-lang/goals/actions/runs/34280395920`; `gh api repos/rust-lang/goals/pages`; `curl` the published URL | 0 | **the gap `opus` recorded is closed at the pattern level**: `rust-lang/goals` `.github/workflows/mdbook.yml` runs `mdbook` with `actions/configure-pages@v5` + `actions/upload-pages-artifact@v3` + `actions/deploy-pages@v4`; `Spotifyd/spotifyd` `.github/workflows/docs.yml` does the same with `@v3`/`@v3`/`@v4`; pinned run `34280395920` (push, `main`, 2026-09-08) `conclusion: success`; `repos/rust-lang/goals/pages` reports `html_url` `https://goals.rust-lang.org/` with `build_type: workflow`, and that URL returns **200**. **The pinned major versions differ** from the ones `opus` recommends (`v6.0.0`/`v5.0.0`/`v5.0.1`), so no adopter of those exact majors is verified | same |
| 8 | Dependency-tree licence walk | `GET https://crates.io/api/v1/crates/<name>/<version>` for every registry package in `evidence/mdbook-0.5.4-Cargo.lock` | 0 | 218 packages; **8 MPL-2.0, all of them the `mdbook*` 0.5.4 family; 0 GPL/AGPL/EUPL/SSPL with no permissive arm**; `font-awesome-as-a-crate` 0.3.1 `CC-BY-4.0 AND MIT`; `r-efi` `MIT OR Apache-2.0 OR LGPL-2.1-or-later` (a disjunction, so its permissive arms are selectable) | same |
| 9 | MPL-2.0 file-level scope | `curl https://www.mozilla.org/en-US/MPL/2.0/FAQ/`, tag-stripped assertion | 0 | the "file-level" copyleft sentence quoted in `## Decision` is present verbatim | same |
| 10 | Parameter round-trip | `awk` over the `docs/port/PARAMETERS.md` `fixed` rows → generated `- assumes` lines → `diff` against the four lines in this file | 0 | **empty diff** — the four values are byte-identical to the registry | same |

**Reproducibility.** After this decision was finalized, the script was rerun
twice and each run's output diffed against
`review/evidence/docs-delivery-claims.log`; both diffs were empty, so **the log
is the complete output of the script, reproducible byte-for-byte on this host**. Two comparison rules an auditor needs.
First, the check-1 banner names this host's `rustc`, `cargo`, `gh` and OS
versions and will differ on another machine; nothing else in the log is
host-dependent. Second, checks 2–9 are assertion-shaped on purpose — they print
`PASS`/`FAIL` and stable fields (licence strings, `yanked`, `archived`, a pinned
run's `conclusion`, a pinned blob's grep counts, tag-stripped documentation
substrings) and deliberately carry **no** volatile counter: no `stargazers_count`,
no `recent_downloads`, no `pushed_at`, no open-issue `total_count`. Those figures
appear in this decision only where they are attributed to a raw report with its
retrieval date. A future rerun therefore differs only if a fact the decision
depends on has actually changed, which is the point.

## Engines

- **codex** `raw/codex-68292e725a5f2d94365ebeb889c4ae4cf88ee3975a8bcbdd11dc6cd6668e190f.md`, retrieved 2026-09-05 — recommends the README-centric CommonMark/GFM tree with no generator, no hosting, no preview server and no scaffold recipe; names `mdBook` 0.5.4 as the conditional successor and rejects Zola; raises one `BASELINE-REVIEW` line (F358).
- **opus** `raw/opus-a80f5625f09deaf7e9534e4f3b5a656d8e106da7ac1f2918b05fab6acc084747.md`, retrieved 2026-09-10 — recommends the dual-readable tree built by `mdbook` 0.5.4 and deployed to GitHub Pages through the first-party action triple; supplies the dialect intersection, the `SUMMARY.md` navigation decision and the differentiate policy; raises two `BASELINE-REVIEW` lines (F357, F358).

**Disagreement 1 — ship a generator, or not (F341).** `codex` says no
requirement for generated HTML, hosted search or a public site has been
established, so a generator is excluded on fit; `opus` says the corpus is
book-sized by fiat (F342 fixes six categories, ts already carries 39-plus files)
and that mdBook 0.5 removes the historical cost of a generator by keeping the
source GitHub-faithful. **What settled it: neither, and the disagreement is
recorded as a live branch rather than resolved by preference.** Both engines
agree on the corpus, and check 5 confirms that `opus`'s fidelity mechanisms are
stated in the maintainers' current documentation rather than inferred by the
engine — which is a check on the citation, not on the rendering — so the corpus is
decided unconditionally and the generator is decided per branch. The tiebreaker
is not a fit judgement but the licence condition: gate 1's reach is an owner
ruling, and R42's published decision records that the same ruling is unmade.
Absent it, this decision defaults to the option that is clean under either
reading, which is `codex`'s shape, and keeps `opus`'s shape one commit away.

**Disagreement 2 — Zola's standing.** `codex` records Zola 0.19.1 as a qualified
general-static-site alternative and notes its crates.io record looks obsolete;
`opus` records the crates.io entry as a yanked placeholder and the project as
EUPL-1.2. **Settled for `opus` by check 2 and check 3**: `zola` has no unyanked
version on crates.io (one version, `0.1.1`, yanked) and `getzola/zola` reports
`license.spdx_id` `EUPL-1.2`. `codex`'s "0.19.1" version figure comes from Zola's
own documentation, not from the registry, and this run did not verify it.

**Disagreement 3 — plugins.** `opus` excludes `mdbook-alerts` on maintenance and
`mdbook-admonish` on fidelity, and records `mdbook-mermaid` as a cheap future
addition; `codex` recommends no plugin at all. **Settled toward "no plugin
ships", with the facts verified**: `lambdalisue/rs-mdbook-alerts` is
`archived: true` (check 3) and is therefore excluded here rather than
recommended — **no component of this recommendation is archived or unmaintained
under either branch**. `badboy/mdbook-mermaid` is `archived: false` (check 3) but
is **MPL-2.0** (check 2), so adopting it later would sit inside the same licence
condition as mdBook itself and is not a way around it. No plugin is recommended
in either branch.

**Disagreement 4 — the mdBook MSRV and figure set.** `codex` reports 859,844
90-day downloads, 22,119 stars and 566 open issues (2026-09-05); `opus` reports
867,415, 22,127 and 566 (2026-09-10). These are the same figures a working week
apart and nothing turns on the difference. **This run deliberately did not
re-collect them** (see the reproducibility rule in `## Empirical check`); they
are carried with their engines' retrieval dates and are not load-bearing for any
conclusion here.

**Unproven, with what would prove it.**

1. **The first-party Pages action triple, narrowed but not closed.** `opus`
   recorded that no repository was found running mdBook through
   `actions/configure-pages` + `upload-pages-artifact` + `deploy-pages`, its own
   repository publishing through a `gh-pages` worktree instead. Check 7 narrows
   that: two committed workflows do exactly this (`rust-lang/goals`,
   `Spotifyd/spotifyd`), one pinned run of the first succeeded, and the resulting
   site answers 200. What remains unproven is the **exact version matrix** this
   decision would ship — those adopters pin `configure-pages@v5`,
   `upload-pages-artifact@v3` and `deploy-pages@v4`, not the `v6.0.0`/`v5.0.0`/`v5.0.1`
   majors `opus` recommends — and the fork-guard behavior, which no external
   repository can demonstrate because it is a property of a template. What would
   prove both: P03's own `docs.yml` running once upstream (deploy green, site
   200) and once on a fork (build green, deploy skipped) under branch A.
2. **Identical rendering on both surfaces is inspected, not verified.** `opus`
   recorded that no local renderer reproducing GitHub's exact Markdown semantics
   was identified, so the property rests on three `grep` guards plus review. This
   run improved the GitHub half only: check 6 exercised GitHub's own
   `POST /markdown` endpoint and confirmed the allowed and forbidden syntax
   behave as claimed. **No mdBook output was produced and no differential
   comparison was made**, so the sentence "one corpus renders identically in two
   places" remains a design intention supported by the maintainers' documented
   conversion rules — not a verified identity. What would prove it: under branch
   A, `mdbook build` over three representative pages (a table-and-links page, an
   alert page, a fenced-Rust page) with the resulting HTML normalized and diffed
   against this same endpoint's output for the same sources — P03.
3. **mdBook's `unsafe` posture** was not established from a source audit or a
   `cargo-geiger` run in either engine's run or this one; it is bounded only by
   the tool's build-time role. What would prove it: a `cargo-geiger` run over the
   pinned tree, which R06's policy owns the standard for.
4. **Whether mdBook's default theme emits the CC-BY-4.0 Font Awesome assets** into
   the built site (check 8 found the crate in the tree; nothing was built). What
   would prove it: inspecting `book/` after a P03 `mdbook build` under branch A.
5. **Wall-clock and byte cost** of installing and running mdBook: nothing was
   timed or measured in this run or in either raw; only the maintainers'
   qualitative wording is carried.

**What P03 must validate.** Under either branch: acceptance criteria (a)–(e),
with (b) handed to R82's checker and (e) enforced by review because it has no
executable form. Under branch A additionally: that `mdbook build` with
`[build] create-missing = false` fails on an unregistered page rather than
fabricating one; that `docs/README.md` and each section `README.md` become
`index.html`; that the two-job workflow behaves as described upstream and on a
fork; gaps 1, 2 and 4 above. Under branch B additionally: that R82's link walk
treats `docs/SUMMARY.md` as the authoritative navigation artifact, since no build
failure will catch drift.

**Uncertainty.** High confidence in the mechanism facts (checks 2–9 read them
from the maintainers' documentation, the registry, the advisory database or
GitHub's own renderer). Medium confidence in the two content-policy judgements
`opus` originated and this decision adopts — dropping per-directory page lists in
favor of a single `SUMMARY.md`, and the differentiate position on F345/F346 —
because both depart from ts's shipped shape and are the kind of call an owner may
reverse. The branch default is a procedural choice mirroring R42, not a finding.
