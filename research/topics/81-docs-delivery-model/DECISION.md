# R81 — docs-delivery-model (bundle, Focused) — DECISION (revision 5, 2026-09-15)

**Revision note (revision 5) — one recorded repair to the decision's account of
its own evidence, written from a run. No re-research and no change of
recommendation.** `review/audit-codex.md` approved revision 4 with no unresolved
findings; `review/audit-fable.md` rejected it on a single finding, J4, and stated
that "the recommendation follows from the evidence, and J4 does not touch it".
This revision repairs exactly that finding and changes nothing else.

- **J4** — "the disclosed failure of `review/evidence/docs-delivery-claims.sh`
  names the wrong assertion — the decision attributes check 16's `FAIL` to the
  whole-file hunk-count tripwire, but that assertion still passes
  (`ASSERT hunk_count_is_17=True`) and the failing one is check 16's
  byte-identical-region assertion for unproven entry 3, whose end anchor
  `4. **Whether mdBook` no longer matches because revision 4 rewrote unproven
  entry 4's opener; `review/audit-codex.md` states the correct mechanism and the
  decision contradicts it, and the decision does not record that check 17
  re-anchors that same region on `4. **Wh` in order to keep asserting it".
  **Repair:** both scripts were rerun in an isolated clone before this paragraph
  was written, and the disclosure below now quotes the assertion names that
  actually printed — `FAIL  region marker not found: unproven entry 3 (unsafe
  posture)  r2=True r3=False` and the shell assertion it sets,
  `FAIL  revision-3 untouched-region diff  expected=0 actual=1`, with
  `ASSERT hunk_count_is_17=True` recorded as still passing. The re-anchoring is
  recorded in the prose **and** in check 17's own table row. The false causal
  clause ("Revision 4's edits are exactly such a change … **so** a rerun … now
  reports `FAIL` in check 16") and the overstated "carries every region assertion
  check 16 made" are both gone.

**Revision 5 trips check 17's title assertion the way revision 4 tripped check
16's entry-3 anchor, and the failure is disclosed from a run rather than
predicted — the run showing that check 17's hunk-count gate, contrary to
expectation, still passes.** `review/evidence/docs-delivery-claims-r4.sh`
and its log are left byte-identical as history, their sha256 values asserted by
the new check 20, and the new script `review/evidence/docs-delivery-claims-r5.sh`
re-targets the revision-diff mechanism at the **revision-4** blob.

**The recommendation, the crate, the version, the corpus figures, the shipped-site
notice rule, the six-gate block, the confidence statement and the four
`- assumes` lines are unchanged**, and every evidence artifact revision 3's and
revision 4's audits reproduced is byte-identical. The revision-4 and revision-3
notes that follow are kept verbatim, because the recommendation they explain is
revision 5's recommendation too.

**Revision note (revision 4) — three recorded repairs, no re-research and no
change of recommendation.** `review/audit-codex.md` approved revision 3 with no
unresolved findings; `review/audit-fable.md` rejected it on three findings, all
of them about what the decision fails to record *around* its recommendation, and
stated that the recommendation itself follows from the evidence. This revision
repairs exactly those three and changes nothing else.

- **J1** — "the shipped-site attribution duty is recorded only for Font Awesome
  icon assets, and the decision gives no reason why one `AND`-conjunct in its own
  table creates a distribution duty while `elasticlunr-rs`'s does not, although
  check 14 establishes that search ships by default". **Repair:** a new
  **shipped-site notice rule** states the test that separates a
  source-redistribution notice from a shipped-content notice, applies it to
  `elasticlunr-rs` explicitly, and widens `## Engines` gap 4 from the Font Awesome
  icons to **every third-party asset the default theme and the default search
  runtime emit into `book/`**.
- **J2** — "fitness gate 5 (default features and any async-runtime coupling) has
  no answer anywhere in the decision, and gates 2, 3, 4 and 6 are answered in
  substance but never recorded as gate answers". **Repair:** a
  **Fitness gates, answered for the recommended tool** block records all six in
  the shape R42 and R67 use — gate 1 keeping its `inapplicable` line verbatim —
  and gate 5 resolves which install line this template's recipe uses, what that
  implies for `mdbook serve`, and why no async-runtime coupling reaches R05 or
  R69.
- **J3** — "the medium-confidence fit judgement states its reversal cost but never
  states what would raise its confidence or what P03 signal would show the call
  wrong, its bolded 'Rust practice splits on exactly that' reaches past the body's
  own 'the one surveyed Rust project', and it does not draw on the seven further
  verified `book.toml` adopters `opus`'s raw already carries". **Repair:** the
  bolded claim is narrowed to the five repositories check 13 surveys; `opus`'s
  seven further adopters — including `rust-lang/rustup`, a Rust CLI rather than a
  language book — are cited with their endpoint and retrieval date and marked as
  carried, not re-verified here; a new **What would raise this above medium, and
  what would show it wrong** paragraph supplies the missing half of the confidence
  statement; and the runner-up's "gains nothing in return" is replaced by ground
  4's own cost list.

**The recommendation, the crate, the version, the corpus figures and the four
`- assumes` lines are unchanged**, and every evidence artifact revision 3's
audits reproduced is byte-identical. The revision-3 note that follows is kept
verbatim, because the recommendation it explains is revision 4's recommendation
too.

**Revision note — the recommendation changed, and the reason it changed is not
the reason you would expect.** Revision 2 (sha256
`5ab7479c7d5e0485fa1c05aef9a894f4c36b56de3692bef89c17efc33a09404e`, approved by
`review/audit-codex.md` with no unresolved findings) decided the documentation
corpus unconditionally and the generator layer **conditionally**, on an owner
ruling about whether fitness gate 1 reaches a never-linked build-time binary. It
withheld the generator absent that ruling. The owner has now ruled
(2026-09-12, Q4 as superseded by Q7.B): licence compatibility is **not evaluated
for any dependency or tool**, so gate 1 is struck from every item's evaluation.

Striking the gate does **not** reveal an answer that was hiding behind it.
Revision 2's own words were that "the tiebreaker is not a fit judgement but the
licence condition" — so with the licence condition gone, **no fit rationale for
shipping the generator over withholding it existed anywhere in the document.**
Revision 3 therefore does the work revision 2 declined to do: it makes the fit
judgement, on the merits, independent of licence. **The judgement is to ship the
generator layer**, and `## Decision` states it under **The fit judgement** with
the evidence that decided it (checks 12–15, new in this revision). The decision
is now unconditional in both halves — one corpus, one generator layer — and the
branch structure is gone.

**What the ruling does not touch, and what this revision therefore kept.** The
repository's own declared `license = MIT OR Apache-2.0` stands (it is this repo's
own source, not a dependency). The finding that no licence in the surveyed tree
reaches the template's own source stands, and its 218-package walk is retained
below as a finding rather than as a gate. The rule forbidding a committed
`theme/` directory stands, because committing MPL-2.0 files into this repository
would make them this repository's own source — the one case the ruling preserves.
The Font Awesome attribution notice stands, because it is a distribution duty on
shipped content, not a licence-compatibility check. *(That sentence is revision
3's and is kept as written; revision 4 widens what it covers — the rule it rests
on reaches every third-party asset the built site carries, not the icons alone.
See **The shipped-site notice rule** below.)*

Two candidates that revision 2 weighed partly on licence re-enter and were
re-evaluated on fit alone: `mdbook-mermaid` (a preprocessor, not a competing
generator) and `zola` (a general site generator with no chapter model and a
yanked registry placeholder). Neither changes the answer; the re-evaluation is in
`## Decision` under **The generator slot: what else was considered, and why it
lost on fit** and in `## Engines` disagreements 2 and 3. One consequence of the
mermaid re-evaluation *is* a change: ` ```mermaid ` fences join F343's forbidden
set, because they render differently on the two surfaces (check 14).

No `## Supersedes` section is present: R81 is not published, and nothing
published is reversed. The per-revision record is under `## Engines`.

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

**Recommendation — one corpus and one generator layer, both decided
unconditionally.** Ship a single CommonMark/GFM documentation corpus under
`docs/` that GitHub renders in place, **and** build it with `mdbook` 0.5.4 into a
GitHub Pages site published from the upstream repository. The corpus is the
canonical artifact and the site is derived from it: the same bytes serve both
readers.

| Ledger row | Decision |
|---|---|
| **F341** delivery model | one `docs/` tree, GitHub-renderable in place, **plus** `mdbook` 0.5.4 → GitHub Pages |
| **F343** markdown dialect | **GFM ∩ mdBook-0.5-default**: CommonMark + tables + strikethrough + task lists + footnotes + `> [!NOTE]`-family alerts. Forbidden: heading attributes `{ #id }`, definition lists, ` ```mermaid ` fences, `{{#include}}`, `{{#playground}}`, `hidelines`, code-block attributes beyond the language tag |
| **F344** section navigation | `docs/SUMMARY.md` as the single navigation source, in mdBook's `SUMMARY.md` grammar (a plain nested bullet list of relative `.md` links, which GitHub renders as a working table of contents with no generator present); per-section `README.md` files carry prose overviews and do **not** re-list their pages; drift is a build failure via `[build] create-missing = false` |
| **F345** landing-page duplication | **differentiate**: root `README.md` is the forge front door; `docs/README.md` is a short orientation map with disjoint content, and is also the book's prefix chapter → `index.html`. No `docs/index.md` |
| **F346** README pointer | one "Documentation" section with **one** link into the tree, then the hosted Pages URL second; no inline re-listing of the categories |
| **F351** local preview server | `mdbook serve --open` via `just docs-dev` |
| **F352** scaffold/init recipe | `mdbook init` via `just docs-init`, documented as new-book-only |

**The generator layer is four artifacts, and removing it is one commit.** The
layer consists of (1) `book.toml` at the repository root, (2) the four `justfile`
recipes `docs-build`, `docs-dev`, `docs-init` and `docs-clean`, each invoking
bare `mdbook` (rows F351 and F352), (3) `.github/workflows/docs.yml`, and (4) the
hosted Pages URL as a second link in the README's Documentation section (row
F346). **Nothing in the corpus depends on it**: the prose, the file layout, the
dialect and the navigation file are exactly what a no-generator tree would carry,
so deleting those four artifacts yields ts's shape without touching a page. That
reversibility bounds the cost of being wrong about the fit judgement below, and
it is why the judgement is recorded at medium confidence rather than deferred
again. The dialect row's purpose — one corpus that reads correctly on both
surfaces — is a design property supported by the maintainers' documented
conversion rules (check 5) and by GitHub's own renderer on the GitHub side
(check 6); it is **not** verified as identical rendering, and `## Engines` gap 2
records what would verify it.

**The fit judgement — the question revision 2 left unanswered.** Revision 2 chose
to withhold the generator using the licence condition as a tiebreaker and said in
terms that this was not a fit judgement. With gate 1 struck, the question is open
and is answered here on four grounds, in the order of how much weight each
carries.

1. **The generator costs the zero-tooling reader nothing, so it is a superset
   rather than a trade.** The historical reason to refuse a documentation
   generator in this programme is py's: MyST's `{toctree}` and `:::{note}` colon
   fences render as literal junk on GitHub, so adopting Sphinx cost the raw-source
   reader. mdBook 0.5 is built the other way. Check 5 verifies, against the
   maintainers' current pages, that relative `.md` links are converted to `.html`
   with the stated motivation "This is useful when viewing the Markdown file
   outside of mdBook, for example on GitHub or GitLab"; that `README.md` becomes
   `index.html` "since some services like GitHub render README files
   automatically"; that admonitions use GitHub's own `> [!NOTE]` alert syntax;
   and that `SUMMARY.md` is itself plain Markdown. Check 6 verifies GitHub's half
   against GitHub's own renderer. So every reader guarantee the no-generator tree
   offers is still offered with the generator present, and the site adds
   full-text search — `[output.html.search] enable` is documented as "on by
   default" (check 14). Nothing was traded away.
2. **The corpus this template is required to carry is a nested multi-category
   tree, and the five Rust projects surveyed here split on exactly that
   structure — four flat, one nested.** That is the scope of the claim, and it is
   stated once here for every place this decision refers to the split: **five
   repositories, one of them on the nested side**, chosen as widely used Rust CLI
   and library projects rather than by a stated sampling rule, which is the
   limit this ground carries. It is not a measurement of Rust practice at large.
   F342 fixes six Diátaxis
   categories as an owner decision already made. Measured at the ts pin
   `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` through the GitHub tree API
   (check 12, retrieved 2026-09-13): **35 `.md` files totalling 171,225 bytes**
   across those six category directories — `about` 3, `tasks` 7, `tools` 12,
   `tutorials` 2, `reference` 5, `contributing` 6 — inside a `docs/` tree of 48
   `.md` files. Against that, check 13 walks five widely used Rust projects at
   pinned commits: `BurntSushi/ripgrep`, `clap-rs/clap`, `serde-rs/serde` and
   `ratatui/ratatui` have **no `docs/`, `doc/`, `guide/` or `book/` directory at
   all** and no `book.toml` — their narrative is a flat handful of
   repository-root files (ripgrep `GUIDE.md` 40,895 B, `FAQ.md` 42,243 B,
   `README.md` 21,599 B; clap `README.md` 1,827 B) — while
   `cargo-generate/cargo-generate`, the Rust CLI in this survey that *does* carry
   a nested narrative tree (`guide/src` with `SUMMARY.md` and the subdirectories
   `templates/` and `usage/`), ships `guide/book.toml`. The split is by
   **structure**, not by raw byte count: a flat set of three root files needs no
   navigation index, and a six-category nested tree does. `rs-launch-blueprint`
   sits on the mdBook side of that split by a decision the owner already took.
   This answers `codex`'s "no established requirement" directly: F342 *is* an
   established owner requirement for a six-category information architecture, and
   the only open question was whether a hand-maintained bullet list is adequate
   navigation for 35 nested files. The one surveyed Rust project that faces the
   same question answered it with a generator; none of the four README-fronted
   projects has a nested tree to navigate.

   **Seven further adopters, carried from `opus`'s raw rather than re-verified
   here.** A one-of-five sample is thin for the weight this ground carries, and
   `opus` already recorded more of it. Through
   `GET https://api.github.com/repos/<o>/<r>/contents/<path>` (retrieved
   2026-09-10, `raw/opus-a80f5625….md`): `rust-lang/book`, `rust-lang/reference`,
   `rust-lang/nomicon`, `rust-lang/rust-by-example`, `rust-lang/rustc-dev-guide`
   and `rust-lang/api-guidelines` each ship a `book.toml`, and **`rust-lang/rustup`
   ships `doc/user-guide/book.toml`** (plus a second book under `doc/dev-guide`).
   The first six are the Rust project's own normative documents, so they say what
   the language's teams do for book-shaped material; `rustup` is the one that bears
   on ground 2, because it is **a Rust CLI tool with a nested in-repo guide, not a
   language book** — the same structure `cargo-generate` presents, from a second
   project. These eight repositories are **not** part of check 13, which pins and
   walks five trees at immutable commits; they are `opus`'s figures with `opus`'s
   endpoint and retrieval date, and this run did not re-verify them. Re-verifying
   `rustup`'s guide at a pinned commit is the cheapest evidence that would raise
   this judgement's confidence, and it is named as such below.
3. **It restores a capability the shared principle names and ts lost.** py's
   README pointer resolves for a reader who is not browsing the repository
   (`py README.md:20` → the Read the Docs URL, pin `b08bccfb`); ts's does not
   (`ts README.md:137` → `./docs/docs.md`, pin `cb1cbcb2`). A hosted site restores
   it. This is stated as a capability regained, not as a requirement satisfied —
   no owner has asked for a public documentation URL.
4. **The cost is bounded, and none of it touches the workspace.** `mdbook` is a
   standalone binary: it enters no `Cargo.toml`, contributes nothing to the
   workspace MSRV surface, and adds nothing to `cargo build --release` output size
   or `cargo test` compile time. The running cost is one `ubuntu-latest` CI job
   and a tool pin that `cargo update` cannot see, so CI must pin it explicitly.

**What weighs against, and why it does not win.** `codex`'s position — no owner
has established a requirement for generated HTML, hosted search or a public site
— is correct as stated and is answered by ground 2: the requirement that exists
is F342's information architecture, and the generator is how that architecture
becomes navigable. mdBook's issue triage is weak (`opus` measured 8 of the 10
most recent issues unanswered at 2026-09-10, method in its raw), which is a real
signal; it is bounded by the tool's build-time-only role and by the one-commit
reversal above. A template's consumers fork it, and a fork inherits the workflow;
that is answered by the two-job shape in the minimal example — the build job runs
everywhere unguarded, the deploy job is guarded to the upstream repository. **The
judgement is a design call at medium confidence**, recorded as such under
`## Engines`; the facts it rests on are high confidence because they are
failure-gated in checks 5, 6 and 12–14.

**What would raise this above medium, and what would show it wrong.** Revision 3
stated the cost of being wrong — four artifacts, one commit, the corpus untouched
— but not the other half, although every unproven entry in this document carries
a "what would prove it". Both halves are stated here.

*Raising it.* Two things would, and neither is expensive. (i) **A pinned
re-verification of `rust-lang/rustup`'s `doc/user-guide` tree** at an immutable
commit, walked the way check 13 walks its five: a second Rust CLI carrying a
nested in-repo guide would take ground 2's structural sample from one-of-five to
two-of-six on the nested side and would answer the selection-rule objection with
a case nobody picked to win an argument. `opus`'s raw already names the path, so
the work is one tree read. (ii) **An owner statement of preference about a public
documentation URL.** Ground 3 is currently recorded as a capability regained
rather than a requirement satisfied, precisely because no owner has asked for one;
an owner who says the template should have a hosted site turns ground 3 into a
requirement and makes this judgement high confidence without any further
research. No source can supply that: it is an owner input, not a finding.

*Showing it wrong in P03.* Three signals, in the order they would arrive. (i)
**The corpus does not become nested.** Ground 2 rests on F342's six categories
producing a nested tree like the 35-file one measured at the ts pin; if the Rust
template's `docs/` settles as a flat handful of files, the structure the
generator is justified by is absent and the no-generator runner-up wins on its
own terms. (ii) **The generator costs the raw-source reader something after
all.** Ground 1 is a documented-behavior argument, not an observation: if gap 2's
differential — `mdbook build` output normalized and diffed against GitHub's
rendering of the same sources — shows the two surfaces disagreeing on syntax
inside the `GFM ∩ mdBook-0.5-default` set, then the superset claim fails and the
trade this decision says does not exist does exist. (iii) **The layer costs more
than a pin.** If the docs job becomes recurring maintenance — `create-missing =
false` producing false failures, the pinned archive needing attention on a
cadence, forks broken by the inherited workflow — the bounded-cost ground 4 is
overstated. Any one of the three is enough to take the one-commit deletion; none
of them requires re-researching the corpus, which is why the reversal is cheap.

**Fitness gate 1** is recorded, not omitted, and its answer is:

> `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`

The prompt's
`## Required evidence` block lists gate 1 as "license compatible with
`MIT OR Apache-2.0`", and the prompt cannot be edited because published
acceptance records cite its sha256. The prompt itself directs that an
inapplicable metric be recorded with its reason rather than omitted, so the row
is recorded and not deleted. The reason is the ruling: licence compatibility is
not evaluated for any dependency or tool, which knowingly includes crates
compiled into the shipped artifact and therefore *a fortiori* a tool like
`mdbook` that is never linked at all. **Revision 2 held the generator layer
hostage to this gate; that dependency is gone**, and the generator layer is
decided on fit above.

What the ruling does not reach is the repository's own declared licence
expression, which stands: `license = MIT OR Apache-2.0` in `## Parameters` is
this repository's own source, not a dependency.

**Fitness gates, answered for the recommended tool.** The prompt's six gates are
recorded here as gate answers, in the shape the sibling post-ruling decisions R42
and R67 use, because revision 3 answered gates 2, 3, 4 and 6 in substance in four
different places and left gate 5 unanswered. `mdbook` 0.5.4 is a **build-time
binary executed as a separate process**, linked into nothing, and the gates are
answered in that light rather than skipped.

**Gate 1 (licence).** `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`, exactly as recorded
above. The declared expressions in the table below are figures, and they exclude
nothing.

**Gate 2 (crate and dependency-tree MSRV).** **Inapplicable to the workspace
surface**: `mdbook` enters no `Cargo.toml`, so it contributes nothing to
`rust-version` and nothing to the CI floor job that `msrv-policy` governs. The
figure is recorded anyway — `mdbook` 0.5.4 declares `rust_version` 1.88.0 (check
2), below a floor of 1.96 derived from stable 1.98.1 (`opus` raw, retrieved
2026-09-10). On this decision's acquisition path nothing is compiled at all
(gate 5); where a contributor falls through to a source install, the binding
floor is the *development* toolchain from `rust-toolchain.toml`, not
`msrv-policy` — the same reading R42 (resolved) records for tools acquired by
`cargo install`.

**Gate 3 (open advisories; `unsafe` posture).** **Pass on advisories**:
`rustsec.org/packages/mdbook.html` answers 200 while `mdbook-mermaid.html`
answers 404 in the same run, so the 200 is a page and not a transport artifact,
and the single advisory it carries, `RUSTSEC-2021-0001`, records
`patched = [">= 0.4.5"]` — 0.5.4 is patched, and no open advisory applies (check
4). **`unsafe` posture: not audited and not asserted.** Neither engine ran a
source audit or `cargo-geiger`, and neither did this run; it is `## Engines`
unproven entry 3, bounded — not resolved — by the fact that a separate build-time
process cannot reach this template's address space. The residual risk is
supply-chain, and what narrows it is the **version pin alone**: check 11 asserts
that the v0.5.4 release publishes exactly six assets and every one of them is an
archive, so **there is no published checksum asset to verify against**. Recording
a digest at first download is a P03 step, not something this release supplies.

**Gate 4 (builds and is tested on `ubuntu-latest, macos-latest`).** **Pass, by
published artifact rather than by CI badge**: the v0.5.4 release publishes exactly
six assets (check 11), mapping `ubuntu-latest` →
`mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz` and `macos-latest` →
`mdbook-v0.5.4-aarch64-apple-darwin.tar.gz`. There is **no**
`aarch64-unknown-linux-gnu` asset, so an aarch64 glibc Linux host — outside this
matrix — takes the musl archive or a source install. A Windows asset exists
(`x86_64-pc-windows-msvc.zip`); Windows is noted, not required. The corpus itself
is platform-independent Markdown.

**Gate 5 (default features and any async-runtime coupling).** Unanswered in
revision 3 and answered here, because two statements in this decision needed
reconciling: F351 ships `just docs-dev` running `mdbook serve --open`, while the
maintainers' CI page — quoted under **Cost** — recommends installing with
`--no-default-features --features search` because that "Disables features like
the HTTP server used by `mdbook serve`" (check 5).

- **Default features include the HTTP server.** That is the content of the
  maintainers' sentence read in the other direction: the flag pair is what
  *removes* `serve`, so the default set is what F351 needs.
- **Which install line the contributor recipe uses: R42's, unchanged, with no
  feature flag — and that is the resolution.** R81 defines **no** install recipe;
  acquisition belongs to R42 (`dev-toolchain-provisioning`, resolved), which
  routes every crates.io-published tool through one generic `install-tool <spec>`
  recipe. R42's published decision (revision 6) gives that recipe the body
  `cargo install --locked <name>@<version>`; its current unpublished revision
  gives it `cargo binstall --locked --no-confirm <name>@<version>`, which takes a
  prebuilt artifact where one exists for the target and falls through to
  `cargo install --locked` otherwise. **This item does not depend on which body
  R42 lands**, and states nothing about that choice: neither body passes a feature
  flag, so both take mdBook's **default** features, and `mdbook serve` survives on
  either path. **`--no-default-features --features search` is therefore not this
  template's install line**, and adding it to the contributor path would delete
  the server F351 ships.
- **CI is the one place the trimmed feature set is available, and it changes
  nothing.** The docs job runs `mdbook build` and never `mdbook serve`, so it may
  take either of the two paths mdBook's own CI page offers — the prebuilt release
  archive, which that page recommends because it "is relatively fast, and does not
  necessarily require dealing with caching" (check 5, and check 11's six assets
  give the two matrix targets), or a source install with
  `--no-default-features --features search`. Which one the docs job takes is a P03
  choice with **no consequence for F351**, because F351 is a contributor recipe.
- **Not verified by execution, and recorded as such.** Nothing was installed and
  `mdbook serve` was never run — the role contract forbids implementing the
  recommendation. That a default-feature mdBook, however acquired, yields a
  working `serve` rests on the maintainers scoping the disabling flag pair to an
  install that opts out of defaults, not on an observation; it is `## Engines`
  unproven entry 7, and the first `just docs-dev` in P03 proves or refutes it.
- **Async-runtime coupling: confined to mdBook's own process, and it reaches
  nothing here.** mdBook's serve path carries an async stack: the resolved lock
  committed as `review/evidence/mdbook-0.5.4-Cargo.lock` contains `tokio`
  1.53.1, `axum` 0.8.9 and `tokio-tungstenite` 0.29.0 (check 18). None of those
  enters this template's `Cargo.toml`, appears in its lock, or constrains it in
  any way, because mdBook is a separate binary. **R05 (`sync-async-execution-model`)
  and R69 (`web-framework-stack`) are therefore unconstrained by this item**, and
  no `CONFLICT:` line follows from this gate.

**Gate 6 (binary-size and compile-time cost, qualitatively).** **Stated, not
measured.** The template's own binaries are unaffected: mdBook is never linked,
so it adds nothing to `cargo build --release` output size and nothing to
`cargo test` compile time, and it adds no `Cargo.toml` entry. What it does cost is
ground 4's list — one `ubuntu-latest` CI job with an archive download, and a tool
pin `cargo update` cannot see. **No wall-clock or byte figure is asserted here**;
nothing was timed, downloaded or built in this run, which is `## Engines`
unproven entry 5.

**The facts below are retained as findings, not as a gate.** They are kept
because the ruling changes what is *evaluated*, not what is *true*, and two of
them carry duties the ruling explicitly does not void — the `theme/` rule and the
attribution notices owed on the shipped site, of which the Font Awesome one is
the sharpest but, as **The shipped-site notice rule** below states, not the only
one.

`mdbook` 0.5.4 declares `license: MPL-2.0`
(`GET https://crates.io/api/v1/crates/mdbook/versions`, newest unyanked `0.5.4`,
`rust_version` `1.88.0`, retrieved 2026-09-10; check 2) and `rust-lang/mdBook`
reports `license.spdx_id` `MPL-2.0` (check 3). MPL-2.0's reciprocity is
file-level: Mozilla's own FAQ states that "The MPL's 'file-level' copyleft is
designed to encourage contributors to share modifications they make to your code,
while still allowing them to combine your code with code under other licenses
(open or proprietary) with minimal restrictions"
(`https://www.mozilla.org/en-US/MPL/2.0/FAQ/`, retrieved 2026-09-10; check 9).
mdBook is invoked as a separate build-time process and is never linked into this
template's crates.

**The dependency tree was walked, and no package in it declares a reciprocal
obligation stronger than MPL-2.0's file-level scope.** Resolving
`mdbook = "=0.5.4"` produced a lock of 218 registry packages
(`review/evidence/mdbook-0.5.4-Cargo.lock`); each package's declared licence was
read from `GET https://crates.io/api/v1/crates/<name>/<version>` and is committed
as `review/evidence/mdbook-0.5.4-licences.json` (check 8, retrieved 2026-09-10).
**The 218 are partitioned rather than summarised, because a conjunctive (`AND`)
expression is not a permissive one and must not be counted as one**: a
disjunction (`A OR B`) lets the redistributor pick one arm, whereas a conjunction
requires every named licence's conditions to be satisfied at once. Check 8
asserts this partition — `218 = 8 + 4 + 2 + 8 + 196` — and fails if it moves.

| Class | Count | Packages and their declared expressions, verbatim |
|---|---:|---|
| `MPL-2.0` | 8 | `mdbook`, `mdbook-core`, `mdbook-driver`, `mdbook-html`, `mdbook-markdown`, `mdbook-preprocessor`, `mdbook-renderer`, `mdbook-summary`, all `0.5.4` — the mdBook family and nothing else |
| **Conjunctive (`AND`)** | **4** | `elasticlunr-rs` 3.1.0 `(MIT OR Apache-2.0) AND MIT`; `font-awesome-as-a-crate` 0.3.1 `CC-BY-4.0 AND MIT`; `matchit` 0.8.4 `MIT AND BSD-3-Clause`; `unicode-ident` 1.0.24 `(MIT OR Apache-2.0) AND Unicode-3.0` |
| Disjunction with a non-permissive arm | 2 | `r-efi` 5.3.0 and 6.0.0, both `MIT OR Apache-2.0 OR LGPL-2.1-or-later` |
| Legacy slash syntax (Cargo's pre-SPDX disjunction form) | 8 | `fnv` 1.0.7 `Apache-2.0 / MIT`; `ident_case` 1.0.1, `pathdiff` 0.2.3, `serde_urlencoded` 0.7.1, `siphasher` 1.0.3, `version_check` 0.9.5 all `MIT/Apache-2.0`; `same-file` 1.0.6 and `walkdir` 2.5.0 both `Unlicense/MIT` |
| Single or disjunctive permissive expression | 196 | 120 `MIT OR Apache-2.0`, 49 `MIT`, 7 `Apache-2.0 OR MIT`, 5 `Unlicense OR MIT`, 5 `Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT`, 3 `Apache-2.0`, 3 `ISC`, 2 `BSD-2-Clause OR Apache-2.0 OR MIT`, 1 `Apache-2.0 OR BSL-1.0`, 1 `CC0-1.0` |

**What each class means for the fixed `license = MIT OR Apache-2.0`.** The
disjunctive classes impose nothing beyond notice retention, because an `MIT` or
`Apache-2.0` arm is always selectable — including `r-efi`, whose `LGPL-2.1-or-later`
arm is one option among three and therefore is **not** an LGPL obligation. Of the
four conjunctions, three combine only notice-retention terms: `MIT`,
`BSD-3-Clause` and `Unicode-3.0` each require the copyright and permission notice
to travel with a redistributed copy, which `MIT OR Apache-2.0` redistribution
already does. The fourth is different and is the reason this paragraph does not
say "permissive": `font-awesome-as-a-crate` 0.3.1 declares `CC-BY-4.0 AND MIT`,
and `CC-BY-4.0` is a content licence, not a software one — it carries a specific
attribution and licence-notice requirement (and no share-alike term, which is why
it is not a reciprocity stronger than MPL-2.0). **No `GPL`-, `AGPL`-, `EUPL`- or
`SSPL`-only declaration appears anywhere in the tree** (check 8 asserts this, and
the only `LGPL` mention is `r-efi`'s disjunctive arm).

**None of these 218 packages is linked into this template, so none of them
reaches the template's own `MIT OR Apache-2.0` source.** They are the
dependencies of a separate build-time binary. What the `CC-BY-4.0` conjunct bears
on is narrower and **survives the ruling**: the **attribution owed for icon
assets in the built site**, and only **if** mdBook's default theme emits them.
That is a distribution-notice duty on shipped content, not a tool-licence
compatibility check, so the ruling does not void it. This run did not build a
site and therefore did not confirm that the theme emits those assets, so P03 must
check it — it is `## Engines` gap 4, and it is now unconditional work because the
generator ships.

**The shipped-site notice rule, and why the duty is not scoped to icons.**
Revision 3 recorded the Font Awesome duty and stopped there, without stating why
one conjunct in the table above creates a duty on the built site while
`elasticlunr-rs`'s `AND MIT` conjunct is disposed of as source redistribution.
The rule is this: **a licence expression is owed against an act of
redistribution, and this template performs two different acts.**

| The act | What it hands to a recipient | Which notices that act owes |
|---|---|---|
| publishing this repository | this repository's own source, which contains no third-party file — the `theme/` rule below exists to keep it that way | none of the 218: they are a separate build-time binary's dependencies and no byte of them is in this repository |
| publishing `book/` to GitHub Pages | the files mdBook's default theme and its default search runtime emit — stylesheets, fonts, icon assets, JavaScript | whatever notices those specific emitted files carry, from whichever upstream they came |

The table of 218 packages answers only the first act, which is what its reading
("which `MIT OR Apache-2.0` redistribution already does") is about. It cannot
answer the second, and not merely because this run built no site: **a crate's
declared licence expression is not a list of the third-party files that crate
vendors**, so a walk over crate metadata cannot enumerate what lands in `book/`
even in principle. Only inspecting a built `book/` can.

`elasticlunr-rs` is the case that makes the asymmetry visible, and it is the
reason the duty is widened rather than merely restated. Check 14 establishes that
`[output.html.search] enable` is "on by default", so a default build ships a
search runtime. If any file in that runtime originates in `elasticlunr-rs` or in
the JavaScript it vendors, its `MIT` notice-retention term is owed **a second
time** — by whoever publishes the site, not only by whoever redistributes this
repository's source. **This decision asserts nothing about which files a built
`book/` actually contains**; what it fixes is that the question is a file-list
question for P03 rather than a licence-arithmetic question already answered
above, and that it is asked of every emitted third-party asset rather than of the
icons alone.

**The generator slot: what else was considered, and why it lost on fit.** With
gate 1 struck, every candidate is judged on fit alone, and two candidates that
revision 2 weighed partly on licence are re-evaluated here rather than carried
forward on their old reasoning.

- **No generator at all** — the same corpus rendered by GitHub, which is
  `codex`'s recommendation in full and `opus`'s stated runner-up. This is the
  honest runner-up and it remains available as a one-commit deletion. It loses on
  the fit judgement's grounds 1–3 above: it forgoes search, a defined reading
  order across six categories and an off-repository pointer. **What it buys back
  is ground 4's cost list, and revision 3 wrongly said it was nothing**: one
  `ubuntu-latest` CI job, a tool pin `cargo update` cannot see, a workflow every
  fork inherits, and a dependence on a tool whose issue triage this decision
  itself measures as weak. The trade is those four costs against grounds 1–3, not
  a free choice; it goes to the generator because ground 1 means none of the
  three capabilities is paid for by the raw-source reader.
- **`zola`** — re-evaluated on fit alone, and it still loses, for reasons that
  never depended on its licence. Its crates.io entry is a placeholder: one
  version, `0.1.1`, `yanked: true`, so there is **no unyanked registry artifact at
  all** (check 2) — the version figures in `codex`'s raw come from Zola's own
  documentation, not the registry. The real project is `getzola/zola`
  (`archived: false`, `license.spdx_id` `EUPL-1.2`, check 3), and its own
  configuration documentation states that `base_url` is "the only required
  configuration variable", with **no `SUMMARY`, chapter or book model anywhere on
  that page** (check 15, retrieved 2026-09-13). It is a general website generator:
  adopting it means authoring a Tera theme to obtain strictly less documentation
  structure than mdBook gives by default. It loses to a first-party generator
  whose raw-source fidelity is documented by its maintainers (check 5). Its
  EUPL-1.2 licence is recorded as a fact and is **not** a reason for this
  exclusion.
- **`mdbook-mermaid` 0.17.1** — re-evaluated on fit alone. It is not a competing
  generator; it is an mdBook preprocessor, and `opus`'s raw calls it "a
  deliberate, cheap future addition rather than a rejection". That standing is
  unchanged: `badboy/mdbook-mermaid` is `archived: false` (check 3) and its
  MPL-2.0 licence (check 2) is no longer evaluated. It is **not adopted now**
  because this item's dialect policy contains no diagrams, and because adding it
  would not close the fidelity gap it appears to close — see the F343 consequence
  below and `## Engines` disagreement 3.
- **`cobalt-bin` 0.20.4** — `MIT` (check 2), and excluded on fit exactly as
  before: a blog-shaped static-site generator with no chapter/`SUMMARY.md` model
  and no documentation-site adoption evidence in this survey.
- **Docusaurus, Astro Starlight, VitePress, MkDocs Material** — excluded on fit:
  each requires a Node or Python toolchain inside a Cargo-shaped template. Astro
  Starlight remains neither designated nor excluded as a *future* target
  (`docs/port/BASELINE-REVIEW.md:415`); it is excluded as this template's shipped
  generator.

**One F343 consequence of the mermaid re-evaluation.** ` ```mermaid ` fences are
now in the forbidden set, and they were not in revision 2's. GitHub documents
that "To create a Mermaid diagram, add Mermaid syntax inside a fenced code block
with the mermaid language identifier"
(`https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams`,
retrieved 2026-09-13; check 14), and mdBook 0.5's own Markdown reference page
contains **no occurrence of the string `mermaid`** (check 14 asserts the count is
zero against the committed snapshot). The two surfaces therefore differ on that
fence, which is precisely what the `GFM ∩ mdBook-0.5-default` rule excludes.
Adding `mdbook-mermaid` would make the fence work on both surfaces, but it is
recorded as a future option and not adopted, so the fence is forbidden today.
This run verified GitHub's *documentation* of diagram rendering and mdBook's
*absence* of it; it did not observe GitHub's web UI render a diagram —
`POST https://api.github.com/markdown` returns a highlighted code block
(`class="highlight highlight-source-mermaid"`, check 14), which shows the API
recognizes the language, not that the UI draws the picture.

**The `theme/` rule, which the ruling explicitly preserves.** Never run
`mdbook init --theme` and never commit a `theme/` directory: that flag copies the
default theme into the source tree
(`https://rust-lang.github.io/mdBook/cli/init.html`, "When you use the `--theme`
flag, the default theme will be copied into a directory called `theme` in your
source directory so that you can modify it", retrieved 2026-09-10; check 5),
which would place MPL-2.0 files **inside** an `MIT OR Apache-2.0` repository. The
owner's ruling scopes the repository's licence to "the source code in the repo
itself directly", so copied-in third-party files become exactly the case the
ruling still governs — this rule is not voided by it, it is the reason the rule
exists. Theme customization, if ever wanted, goes through
`output.html.additional-css`, which adds an original file rather than copying MPL
files.

**Ledger rows settled** (verdict strings remain the controller's to set, per
`docs/port/README.md`): **F341**, **F343**, **F344**, **F345**, **F346**,
**F351** and **F352** are all decided unconditionally, as the table above states.
Four of them — **F341**, **F346**, **F351**, **F352** — take a different value
from revision 2's default branch: a generator and hosted site ship (F341), the
README carries the hosted Pages URL as a second link (F346), `just docs-dev` runs
`mdbook serve --open` where revision 2 had "none" (F351), and `just docs-init`
runs `mdbook init` where revision 2 had "none" (F352). **F343** takes one added
exclusion (` ```mermaid ` fences) and **F344** loses its conditional sentence:
drift is caught by the build, not by R82's link walk. F342 (the Diátaxis category
set) and F347 (the authoring guide's existence) are untouched; this item supplies
F347's content mechanics only. F353 is R82's.

**Baseline-review lines.** Neither row is R81's to resolve; both are recorded for
the reconciliation. F357's placement question, which revision 2 could describe as
hypothetical, **is now live**, because the condition it was waiting on — R81
shipping a generated site — has been met.

BASELINE-REVIEW: F357 — one orientation page states the internal-docs bucket split and which buckets are normative — replace py's inherited wording ("not part of the published Sphinx site") with an explicit statement of the disposition selected, because that wording is now false: this item ships a generated site — evidence: py's exclusion is structural, `py docs/README.md:1-4` at pin `b08bccfb` scopes the site to the `docs/source/` subdirectory, so the internal buckets sit outside it; with `[book] src = "docs"` mdBook states "All other files in the `src` directory will be included in the output" (`https://rust-lang.github.io/mdBook/guide/creating.html`, retrieved 2026-09-10; check 5), so `docs/adr/`, `docs/design/` and `docs/research/` (F354–F356) are in the book source either as listed chapters or as verbatim copies; `docs/port/BASELINE-REVIEW.md:133` records the framing as conditional on R81 shipping a generated site, and that condition is now met. Affected items: F354, F355, F356, F357. No verdict change proposed (all four stay `ADOPT`); the placement choice — list the buckets as a `SUMMARY.md` suffix part, which is `opus`'s recommendation, or move them to a sibling top-level directory outside the book source — is **not made here**, because F354–F357 are not R81's rows: it is an owner disposition that the reconciliation must now take rather than defer.

BASELINE-REVIEW: F358 — a docs system records the upgrade path it would take if requirements outgrow the shipped delivery model — keep `ADOPT`, and record that with mdBook shipped the note's subject is the residual gap mdBook does not cover: versioned or multi-language documentation and rich interactive components. The migration is a generator swap over an unchanged CommonMark corpus, and the note should name that trigger and a fresh decision rather than a preselected generator — evidence: `docs/port/BASELINE-REVIEW.md:134` marks the row "blocked pending R81" and `:415` records that Astro Starlight is "documented, not shipped" in ts and is neither designated nor excluded for Rust; both `codex` and `opus` raise this row and agree the note should name a trigger and a fresh decision. Affected item: F358 only.

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
tree only* (ts's shape) — **rejected on fit**, and it is the ranked runner-up
rather than a dismissal: it is the correct answer for a flat handful of root
files, which is what four of the five Rust projects check 13 pins actually carry,
and the wrong answer for the six-category nested tree F342 fixes (check 12). Its
costs are no search, no defined reading order across six categories, and no
pointer that resolves for a reader who is not browsing the repository; what it
buys back is ground 4's list — one CI job, a pin, an inherited workflow and a
dependence on mdBook's maintenance — and because mdBook takes nothing away from
the raw-source reader (check 5, check 6), none of the three costs buys a reader
guarantee. The full argument is `## Decision`'s **fit judgement**. (C) *Dual-readable tree — one corpus that GitHub renders
in place and that mdBook can build* — **recommended**, for the corpus and the
generator layer alike. (D) *Narrative inside rustdoc*
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
therefore hold with the generator present, which is the whole basis of ground 1
of the fit judgement; (2) holds through `docs/SUMMARY.md`; (3) and (4) hold
through the differentiate policy in the decision table.

**The dialect claim was tested against GitHub's own renderer, not asserted.**
`POST https://api.github.com/markdown` with `mode: gfm` (check 6, 2026-09-10)
returned, for one four-element input: `> [!NOTE]` rendered as
`<div class="markdown-alert markdown-alert-note">`; `# Head { #id .cls }`
rendered as `<h1>Head { #id .cls }</h1>`, braces literal; a definition-list pair
rendered as one `<p>term<br>: definition</p>`; and `[link](./other.md)` kept its
`.md` href. Check 14 adds the mermaid fence: the endpoint returns
`class="highlight highlight-source-mermaid"`, a highlighted code block. That is
the empirical basis for the allowed set and for the forbidden default extensions.
**It is not a proof of identical rendering**: the
endpoint renders GitHub's side only, no mdBook output was produced in this run,
and no differential comparison was made — see `## Engines`, gap 2.

**Reference implementations, with what this run verified marked.** The closest
structural analogues are `rust-lang/goals` and `Spotifyd/spotifyd`, each of which
runs mdBook through the first-party GitHub Pages action triple in a committed
workflow (check 7, blobs pinned by SHA), and `cargo-generate/cargo-generate`,
which keeps an mdBook guide inside the tool's own repository — `guide/book.toml`
plus `guide/src/SUMMARY.md` and the subdirectories `templates/` and `usage/`,
re-verified here at pinned commit `b1def653c6104a5e98024f56208b243dc6294de9`
(check 13, retrieved 2026-09-13). **A second CLI-shaped analogue is carried from
`opus`'s raw and not re-verified here**: `rust-lang/rustup` keeps its user guide
as an in-repo mdBook at `doc/user-guide/book.toml` (`opus` raw, contents API,
retrieved 2026-09-10), alongside the six `rust-lang` documentation repositories
listed at ground 2. The rejected alternative (B)'s reference
implementations are `ts-launch-blueprint` itself at pin `cb1cbcb2` and the flat
Rust CLI shape — `ripgrep`, `clap`, `serde`, `ratatui`, each re-verified here at
a pinned commit as carrying **no** `docs/`-like narrative directory and no
`book.toml` (check 13).

**Cost, stated qualitatively and not measured.** The template's
own binaries are unaffected: mdBook is never linked, so it adds nothing to
`cargo build --release` output size or to `cargo test` compile time, and it
enters no `Cargo.toml`. The cost is acquiring the tool; mdBook's own CI guidance
recommends the prebuilt release archive because that path "is relatively fast,
and does not necessarily require dealing with caching", and recommends
`--no-default-features --features search` for a source install because it
"Disables features like the HTTP server used by `mdbook serve`" (check 5). **No
wall-clock or byte figure is asserted; nothing was timed or built in this run.**

**Minimal realistic example, as a description and not as built code.** The
corpus: `docs/README.md` (orientation map), `docs/SUMMARY.md` (the navigation
index), six category directories each with a `README.md` prose overview, and a
root `README.md` whose Documentation section is one sentence with one in-tree
link plus the hosted URL. The generator layer: `book.toml` at the repository root
with `[book] src = "docs"`, `[rust] edition = "2024"` (mdBook's default is
`"2015"`, so leaving it unset would make an edition-2024 doc example fail under
`mdbook test`), `[build] create-missing = false`, `[output.html]
definition-lists = false`; a `justfile` with `docs-build`, `docs-dev`,
`docs-init`, `docs-clean` invoking bare `mdbook` per R42's resolved
`package-manager-invocation`; and `.github/workflows/docs.yml` with an unguarded
`docs-build` job (`contents: read`) plus a `docs-deploy` job guarded to the
upstream repository and the default branch (`pages: write`, `id-token: write`,
`github-pages` environment). The hosted URL the README names is the derived
GitHub project-pages default for this repository's slug,
`https://smorinlabs.github.io/rs-launch-blueprint/`. **It does not resolve yet**:
`GET https://api.github.com/repos/smorinlabs/rs-launch-blueprint` reports
`has_pages: false` and `GET .../pages` returns HTTP 404 (recorded, not gated —
see `## Empirical check`, retrieved 2026-09-13), because enabling Pages with
source "GitHub Actions" is a one-time manual repository setting the owner must
perform and no workflow can perform for itself. **This example was not built.**

re-verify: on mdBook 0.6 (the 0.5 defaults this answer depends on could change again); or if `rustsec.org/packages/mdbook.html` gains an advisory with no patched version; or if `api.github.com/repos/rust-lang/mdBook` reports `archived: true`; or 2027-03-10, whichever is first.

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

How each fixed parameter bears on the decision. `license` is the repository's own
declared expression and it stands unchanged; the owner's ruling of 2026-09-12
(Q7.B) means it is **not** compared against any dependency's or tool's licence,
so fitness gate 1 is recorded `inapplicable` in `## Decision` and no longer
governs the F341 answer as it did in revision 2.
`target-os-matrix` is satisfied: Markdown is
platform-independent, and the release mdBook v0.5.4 publishes
prebuilt binaries covering both matrix operating systems. The asset set is
recorded per platform rather than summarised, because "Linux and macOS, both
x86_64 and aarch64" would overstate it —
`GET https://api.github.com/repos/rust-lang/mdBook/releases/tags/v0.5.4` returns
exactly six assets (check 11, retrieved 2026-09-12):
`mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz` and
`mdbook-v0.5.4-x86_64-unknown-linux-musl.tar.gz` (Linux x86_64, glibc and musl),
`mdbook-v0.5.4-aarch64-unknown-linux-musl.tar.gz` (Linux aarch64, **musl only**),
`mdbook-v0.5.4-x86_64-apple-darwin.tar.gz` and
`mdbook-v0.5.4-aarch64-apple-darwin.tar.gz` (macOS x86_64 and aarch64), and
`mdbook-v0.5.4-x86_64-pc-windows-msvc.zip` (Windows x86_64, outside this
matrix). **There is no `aarch64-unknown-linux-gnu` asset**, so no glibc aarch64
Linux prebuilt exists at this release and none is implied here; an aarch64 glibc
Linux host would take the musl archive or a source install. The matrix maps to
`ubuntu-latest` → `mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz` and
`macos-latest` → `mdbook-v0.5.4-aarch64-apple-darwin.tar.gz`; the docs job is
itself pinned to `ubuntu-latest` anyway, because building the same book twice
tests nothing. `msrv-policy` is satisfied and is largely vacuous here, because
`mdbook` 0.5.4 declares
`rust_version` 1.88.0 against a floor of 1.96 (stable `1.98.1`, per `opus`
raw, retrieved 2026-09-10), and it contributes nothing to the workspace MSRV
because it is not a dependency. `rust-edition` has one consequence
already stated in the minimal example: `book.toml` must set
`[rust] edition = "2024"`, because mdBook's default is `"2015"`.

One unregistered coupling is recorded, and it is not a conflict:
`package-manager-invocation` (R42, resolved) requires bare-executable invocation
on `PATH` for a tool acquired from crates.io or a release, and presence testing
with `command -v <executable>`. `mdbook` is acquired that way, so
recipes call bare `mdbook` and the presence test is `command -v mdbook`. A second
is recorded for R11: the docs build and docs deploy halves cannot
share one job, because they need different `permissions` and the deploy half
needs an `environment` — a constraint `ci-job-structure` should accommodate, not
a value that must change. Revision 2 recorded both as conditional on the
generator shipping; they are now unconditional.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `gh 2.98.0`;
`Darwin 25.4.0 arm64`, macOS 26.4. All retrieval timestamps are UTC. Revision 3's
run was on this same host on 2026-09-13; checks 12–15 are new in revision 3 and
check 16 replaces revision 2's check 12, and **every check revision 2 carried
forward reproduced its values unchanged**. That statement is verified rather than
asserted, and by hand after the log was written rather than inside the script, so
it is not one of the gated checks counted below: of the **92** `PASS` lines in
`review/evidence/audit-docs-delivery-model-r2.log` — the revision-2 auditor's
byte-identical rerun of revision 2's script — **77 appear verbatim in
revision 3's log and 15 do not**
(`while IFS= read -r l; do grep -Fqx -- "$l" evidence/docs-delivery-claims.log ||
echo "MISSING: $l"; done < <(grep '^PASS' evidence/audit-docs-delivery-model-r2.log)`).
All 15 are output of revision 2's own check 12 — the
revision-diff check, which revision 3 re-targets from the revision-1 blob to
the revision-2 blob and renumbers to check 16; its region names, line counts
and blob sha256 therefore necessarily differ. **No check that reads an external
source changed its answer**: all 77 `PASS` lines from checks 1–11 reproduce
verbatim.

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
set equals the lock's package set, and **re-queries a fixed 16-package sample
live** — the eight `mdbook*` crates, all four conjunctive-expression packages
(`font-awesome-as-a-crate` 0.3.1, `elasticlunr-rs` 3.1.0, `matchit` 0.8.4,
`unicode-ident` 1.0.24), both `r-efi` versions (5.3.0 and 6.0.0), and
`pulldown-cmark` and `handlebars` as controls — failing if any live answer
differs from the snapshot. Every package this decision names by licence is
therefore re-verified live, not read from the snapshot alone; the sample was 12
in revision 1 and did not cover three of the four conjunctions.
Passing `--full-walk` re-queries all 218 at wider spacing. The
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

`set -o pipefail` is set at the top of the script, and **every fact this decision
cites from a check is failure-gated on its expected content, not on an exit code
alone**; the script exits non-zero if any gate fails. As run for revision 3, it
made **162 failure-gated checks: 154 lines reporting `PASS`** — 123 from the
shell's own `assert`/`assert_has` helpers (four of those 123 are in check 16) and
31 printed by check 16's Python region comparison, whose failure path sets the
exit status that the shell assertion `revision-3 untouched-region diff` reads —
**plus 8 gated `ASSERT <name>=True` lines** (7 inside check 8's licence
walk and 1 in check 16), each feeding its block's exit status. **0 `FAIL` lines; 0
failed assertions; exit status 0.**

**The distinction between a gate and recorded output, stated because revision 1
got it wrong.** Revision 1 claimed that every check asserted on its content. That
was false: several commands printed a value the decision then cited without any
assertion on it — `mdbook-admonish` and `mdbook-alerts` licences in check 2, the
three Pages actions' `archived` fields in check 3, and `Spotifyd/spotifyd`'s
`configure-pages` and `upload-pages-artifact` uses in check 7 — and check 8's
`lock_matches_snapshot` and `mpl_are_exactly_the_mdbook_family` lines printed
`True` without feeding the exit status. Revision 2 adds a gate for each of those
and for every other cited fact (the full list is in the script's commit), so no
cited fact now rests on printed output alone; revision 3 keeps that discipline
for checks 12–16. What remains deliberately
**unasserted recorded output** is: check 1's
toolchain and host banner (host-dependent by design, and reported in the
paragraph above rather than asserted); check 7's `grep -nE` listing of each
workflow's mdBook and action lines, whose content is gated by the pin and count
assertions that follow it; check 8's declared-expression frequency table,
whose arithmetic is gated by the `partition_is_218_8_4_2_8_196` assertion; check
12's and check 13's per-directory and per-repository tallies, each of which is
gated by the assertion that follows it; and — the one item cited as a finding —
**the upstream Pages state of `smorinlabs/rs-launch-blueprint`**, printed under
its own `recorded (not gated)` heading. That one is deliberately ungated, and the
reason is stated rather than assumed: `has_pages` and the `/pages` status flip
the moment the owner performs the one-time "Pages source = GitHub Actions"
setting the decision asks for, so gating them would turn the owner doing the
right thing into a failed audit. The decision therefore cites them only as of
2026-09-13 and derives the hosted URL from the repository slug, recording that
derivation as `## Engines` unproven entry 6.

Three assertions failed on revision 1's first run and are recorded here rather
than quietly fixed: the RustSec advisory field is `patched`, not
`patched_versions`; a grep count for mdBook installation in the
`rust-lang/goals` workflow returned 2 because that workflow installs
`mdbook-mermaid` as well; and the parameter round-trip pointed `awk` at the wrong
repository root. All three were defects in the check, not in the claims.

| # | Check | Command | Exit | Result | Log |
|---|---|---|---:|---|---|
| 1 | Toolchain and host | `rustc --version`; `cargo --version`; `gh --version`; `uname`; `sw_vers` | 0 | recorded above | `evidence/docs-delivery-claims.log` |
| 2 | crates.io licences and versions | `GET https://crates.io/api/v1/crates/<name>/versions` for `mdbook`, `cobalt-bin`, `mdbook-mermaid`, `mdbook-admonish`, `mdbook-alerts`, `zola` | 0 | `mdbook` 0.5.4 **MPL-2.0** `rust_version` 1.88.0; `cobalt-bin` 0.20.4 **MIT**; `mdbook-mermaid` 0.17.1 **MPL-2.0**; `mdbook-admonish` 1.20.0 MIT; `mdbook-alerts` 0.8.0 MIT; **`zola` has no unyanked version** — one version, `0.1.1`, `yanked: true`, so the registry entry is a placeholder, not the project | same |
| 3 | GitHub repository facts | `gh api repos/<o>/<r>` for `rust-lang/mdBook`, `getzola/zola`, `lambdalisue/rs-mdbook-alerts`, `badboy/mdbook-mermaid`, `actions/{configure-pages,upload-pages-artifact,deploy-pages}` | 0 | `rust-lang/mdBook` `MPL-2.0`, `archived: false`; `getzola/zola` **`EUPL-1.2`**, `archived: false`; `lambdalisue/rs-mdbook-alerts` **`archived: true`** (the archived component — excluded here, not recommended); `badboy/mdbook-mermaid` `archived: false`; all three Pages actions `MIT`, `archived: false` | same |
| 4 | RustSec | `curl -o /dev/null -w '%{http_code}' https://rustsec.org/packages/{mdbook,mdbook-mermaid}.html`; the advisory-db raw file for `RUSTSEC-2021-0001` | 0 | `mdbook` page **200**, `mdbook-mermaid` **404** (the 404/200 pair shows 404 means "no advisory page", not a transport failure); the advisory records `patched = [">= 0.4.5"]`, so 0.5.4 carries **no open advisory** | same |
| 5 | Maintainer-documentation claims | `curl` of six mdBook User Guide pages into `evidence/snapshots/`, then tag-stripped substring assertions | 0 | all present: the `.md`→`.html` rule and its stated GitHub motivation; `README.md`→`index.html`; the `> [!NOTE]` admonition family; the definition-list section and its `definition-lists` switch; the heading-attribute example `{ #first .class1 .class2 }`; "Without this file, there is no book"; `[book] src` configurability; `create-missing`; the `[rust] edition` default `"2015"`; `--theme` copies the default theme into `theme`; "All other files in the `src` directory will be included in the output"; the CI page's prebuilt-binary and `--no-default-features` wording | same |
| 6 | GitHub's renderer, on the dialect | `POST https://api.github.com/markdown` (`mode: gfm`) on one five-element input | 0 | alert → `markdown-alert-note` div; heading attributes → literal `{ #id .cls }` inside `<h1>`; definition list → one `<p>` with a literal `: definition`; `./other.md` href preserved; a ` ```mermaid ` fence → `class="highlight highlight-source-mermaid"` (asserted in check 14) | same |
| 7 | Adopters of mdBook + the first-party Pages triple | `gh api repos/rust-lang/goals/git/blobs/4dce369a600e57b9cae2e2a5b3edca0a27942ecc`; `.../Spotifyd/spotifyd/git/blobs/8dfc018421bca766fe7c1d772b5a6dfc3c1a1bd3`; `gh api repos/rust-lang/goals/actions/runs/34280395920`; `gh api repos/rust-lang/goals/pages`; `curl` the published URL | 0 | **the gap `opus` recorded is closed at the pattern level**: `rust-lang/goals` `.github/workflows/mdbook.yml` runs `mdbook` with `actions/configure-pages@v5` + `actions/upload-pages-artifact@v3` + `actions/deploy-pages@v4`; `Spotifyd/spotifyd` `.github/workflows/docs.yml` does the same with `@v3`/`@v3`/`@v4`; pinned run `34280395920` (push, `main`, 2026-09-08) `conclusion: success`; `repos/rust-lang/goals/pages` reports `html_url` `https://goals.rust-lang.org/` with `build_type: workflow`, and that URL returns **200**. **The pinned major versions differ** from the ones `opus` recommends (`v6.0.0`/`v5.0.0`/`v5.0.1`), so no adopter of those exact majors is verified | same |
| 8 | Dependency-tree licence walk | `GET https://crates.io/api/v1/crates/<name>/<version>` for every registry package in `evidence/mdbook-0.5.4-Cargo.lock` | 0 | **`218 = 8 + 4 + 2 + 8 + 196`, asserted as a partition**: 8 `MPL-2.0`, all of them the `mdbook*` 0.5.4 family; **4 conjunctive (`AND`) expressions — `elasticlunr-rs` 3.1.0 `(MIT OR Apache-2.0) AND MIT`, `font-awesome-as-a-crate` 0.3.1 `CC-BY-4.0 AND MIT`, `matchit` 0.8.4 `MIT AND BSD-3-Clause`, `unicode-ident` 1.0.24 `(MIT OR Apache-2.0) AND Unicode-3.0`**, asserted to be exactly these four; 2 `r-efi` (5.3.0, 6.0.0) `MIT OR Apache-2.0 OR LGPL-2.1-or-later`, asserted to be the tree's only `LGPL` mention and disjunctive; 8 legacy slash-syntax disjunctions; 196 single or disjunctive permissive expressions. **0 `GPL`/`AGPL`/`EUPL`/`SSPL` declaration with no permissive arm**; 0 packages with no declared licence | same |
| 9 | MPL-2.0 file-level scope | `curl https://www.mozilla.org/en-US/MPL/2.0/FAQ/`, tag-stripped assertion | 0 | the "file-level" copyleft sentence quoted in `## Decision` is present verbatim | same |
| 10 | Parameter round-trip | `awk` over the `docs/port/PARAMETERS.md` `fixed` rows → generated `- assumes` lines → `diff` against the four lines in this file | 0 | **empty diff** — the four values are byte-identical to the registry | same |
| 11 | mdBook v0.5.4 release assets | `gh api repos/rust-lang/mdBook/releases/tags/v0.5.4 --jq '.assets[].name'` | 0 | **exactly 6 assets**, each asserted by name: `x86_64-unknown-linux-gnu`, `x86_64-unknown-linux-musl`, `aarch64-unknown-linux-musl` (Linux); `x86_64-apple-darwin`, `aarch64-apple-darwin` (macOS); `x86_64-pc-windows-msvc` (Windows). **`aarch64-unknown-linux-gnu` asset count asserted to be 0** — no glibc aarch64 Linux prebuilt exists at this release. Matrix mapping asserted: `ubuntu-latest` → the `x86_64-unknown-linux-gnu` archive, `macos-latest` → the `aarch64-apple-darwin` archive | same |
| 12 | The corpus F342 fixes, measured at the ts pin | `gh api "repos/smorinlabs/ts-launch-blueprint/git/trees/cb1cbcb2e88b898e8c081b0abbfabc1630079c00?recursive=1"` | 0 | **35 `.md` files, 171,225 bytes** across the six fixed categories, each per-category count asserted (`about` 3, `tasks` 7, `tools` 12, `tutorials` 2, `reference` 5, `contributing` 6); 48 `.md` files under `docs/` in total; all six categories asserted to be **directories**, which is the structural property the fit judgement turns on. Read at an immutable commit SHA, so it reproduces off this machine | same |
| 13 | Rust practice splits on narrative structure | `gh api repos/<o>/<r>/git/trees/<sha>?recursive=1` for `BurntSushi/ripgrep` `3fce3b5b…`, `clap-rs/clap` `48ed7869…`, `serde-rs/serde` `a874a1b1…`, `ratatui/ratatui` `982cd76b…`, `cargo-generate/cargo-generate` `b1def653…` | 0 | the first four asserted to have **zero** files under `docs/`, `doc/`, `guide/` or `book/` and **zero** `book.toml`; `ripgrep`'s flat root narrative asserted by **size**, because the decision quotes those figures (`GUIDE.md` 40,895 B, `FAQ.md` 42,243 B, `README.md` 21,599 B), and `clap`'s `README.md` 1,827 B; `cargo-generate` asserted to ship `guide/book.toml` **and** `guide/src/SUMMARY.md` **and** exactly 2 nested subdirectories under `guide/src` | same |
| 14 | mdBook default search; mermaid on both surfaces | `curl` of `format/configuration/renderers.html`; negative `grep` on the `format/markdown.html` snapshot; `curl` of GitHub's "Creating diagrams" doc; the check-6 probe output | 0 | "search feature enabled (on by default)" and "enable: Enables the search feature" present; **`mermaid` occurs 0 times in mdBook's Markdown reference** (a non-zero count would falsify the F343 exclusion, so the assertion can fail); GitHub documents "add Mermaid syntax inside a fenced code block with the mermaid language identifier"; `POST /markdown` returns `class="highlight highlight-source-mermaid"` — the API recognizes the language and returns a code block, which is recorded rather than read as "GitHub rendered a diagram" | same |
| 15 | Zola's site model | `curl https://www.getzola.org/documentation/getting-started/configuration/`, tag-stripped assertions | 0 | "The base URL of the site; the only required configuration variable." present; **`SUMMARY` occurs 0 times and `chapter` occurs 0 times** on that page — the fit reason for excluding Zola, stated independently of its licence | same |
| 16 | Revision-3 diff against the revision-2 blob | `git cat-file blob 9f2bcb9ddf5266bf4face766e98b7cd1be3616ad`; region extraction and `difflib.unified_diff` against this file | 0 | revision-2 blob sha256 asserted `5ab7479c…`; **nine regions asserted byte-identical** (the licence-partition table, its reading, the shared-requirement through what-may-vary block, the four `- assumes` lines, check 8's snapshot rationale, the revision-1 check-defect record, disagreement 4, unproven entry 3, and the revision-1 history entry); **five regions the ruling does change** asserted to have changed *and* to carry their marker sentence; five required texts asserted present (the one-line gate-1 record, the `theme/` prohibition, the Font Awesome duty, the "reaches the template's own source" finding, the mermaid exclusion); **the branch vocabulary asserted absent from the live decision and still present in the revision history**; no `## Supersedes`; **whole-file hunk count asserted to be exactly 17** | same |

**What revision 5 ran, what it did not run, and what actually fails in checks 16
and 17.** Revision 5 answers one judgment finding about how this decision reports
its own evidence; it re-researches nothing, so **checks 1–15 were not re-run**
and the table above, `review/evidence/docs-delivery-claims.sh` and
`review/evidence/docs-delivery-claims.log` are revision 3's artifacts, left
byte-identical (asserted by sha256 in check 20, together with the three auditors'
logs, the lock, the licence snapshot, and revision 4's script and log).

**Check 16 no longer passes, and this is what a rerun actually prints.** Both
preserved scripts were rerun for this revision in an isolated `git clone` of this
repository at `research/p02-execution`, before this paragraph was written; nothing
in the working repository was touched and nothing was written inside
`review/evidence/`. `bash review/evidence/docs-delivery-claims.sh` exits 1 with
**152 `PASS` lines — 119 in checks 1–15 and 33 in check 16 — 2 `FAIL` lines, and
`failed assertions: 1`**. The failing assertion is **not** the whole-file
hunk-count tripwire: that assertion still passes and still prints
`ASSERT hunk_count_is_17=True` for the revision-2-to-live diff. It is check 16's
**byte-identical-region assertion for unproven entry 3**, and the two `FAIL`
lines it prints are, verbatim:

```
FAIL  region marker not found: unproven entry 3 (unsafe posture)      r2=True r3=False
FAIL  revision-3 untouched-region diff                           expected=0 actual=1
```

the second being the shell assertion whose status the Python region comparison
sets. The cause is an end anchor, not a line count: check 16 extracts that region
with the end marker `"4. **Whether mdBook"`
(`review/evidence/docs-delivery-claims.sh:514`), which was revision 3's opener for
unproven entry 4, and revision 4's J1 repair rewrote that entry to open on
**Which third-party assets a default `mdbook build` emits into `book/`** instead
of **Whether mdBook…**. So revision 4's intended edit to entry **4** left check 16
unable to *evaluate* its preservation assertion for entry **3**; it did not report
that entry 3 had changed. Checks 1–15 are unaffected. This paragraph is the repair
for finding J4, and `review/audit-codex.md` recorded the same mechanism
independently on revision 4: "The old script's revision-2 hunk-count assertion
still passes at 17; the changed-region assertion is the direct failure."

**The preservation claim survives because check 17 re-anchored that region.**
Rather than edit a script two audits reproduced, revision 4 added a **new**
script, `review/evidence/docs-delivery-claims-r4.sh`, whose check 17 re-targets
the same revision-diff mechanism from the revision-2 blob to the **revision-3**
blob `460e6f9002663f7e00921406c3bd9bc2785328fe`. Check 17 carries the nine
regions check 16 asserted from revision 2, but **unproven entry 3 is carried on a
deliberately looser end marker — `"4. **Wh"`
(`review/evidence/docs-delivery-claims-r4.sh:98`) in place of check 16's
`"4. **Whether mdBook"`** — which is why check 17 can still assert that region
byte-identical to revision 3, and does, and passes. One of check 16's nine region
assertions therefore had to be re-anchored to keep asserting the same region; the
other eight are carried as written, alongside the regions revision 4's brief named
as preservation targets.

**Check 17 now fails by construction as well, and that is disclosed from a run
rather than predicted.** Check 17 asserts that the title names revision 4, and it
also gates the hunk count of the revision-3-to-live diff at 17; a revision 5
necessarily moves the title, and whether it moves the hunk count is a question
only a run answers. In the same isolated clone, with revision 5's
`DECISION.md` in place, `bash review/evidence/docs-delivery-claims-r4.sh` exits 1
with **99 `PASS` lines — 86 in check 17 and 13 in check 18 — 2 `FAIL` lines, and
`failed assertions: 1`**. Exactly one region-or-text assertion fails, and it is
the title:

```
FAIL  title does not name revision 4
FAIL  revision-4 region and text diff                            expected=0 actual=1
```

Every preservation region check 17 asserts still passes. **The hunk-count gate
does not move**, contrary to what an author writing this paragraph by
construction would have predicted: check 17 still prints
`ASSERT hunk_count_is_17=True` for the revision-3-to-live diff, because revision
5's edits fall inside hunks revision 4 had already opened. That is finding J4's
lesson applied rather than repeated — the assertion named here is the one that
printed. Revision 5 therefore takes the handling revision 4 chose:
`review/evidence/docs-delivery-claims-r4.sh` and
`review/evidence/docs-delivery-claims-r4.log` are left **byte-identical** as the
record of the revision-4 run — their sha256 values asserted by the new check 20,
so the r4 log stands as the complete output of that script *as run against
revision 4*, not as a claim about what it prints now — and a new script,
`review/evidence/docs-delivery-claims-r5.sh`, re-targets the mechanism at the
**revision-4** blob `ec356a0d8492a349292807db6cf888aac53619a1`. Its check 19
re-asserts each region check 17 asserted — the twenty-six preservation
regions on their check-17 anchors, plus the eight regions check 17 required
revision 4 to *change*, which revision 5 must now leave alone — and adds the
regions and texts this revision must not touch.

Both new checks are **offline and deterministic** — no network, no `gh`, no
`curl` — and the script writes nothing inside `review/evidence/`, using a
`mktemp` directory it removes on exit, so a rerun cannot disturb
`review/evidence/snapshots/`. That risk is not hypothetical: rerunning the **old**
script in the isolated clone rewrote three files under that directory
(`github-creating-diagrams.html`, `mpl-2.0-faq.html`, `n_github-diagrams.txt`)
without moving a single assertion — which both shows those assertions survive
upstream byte drift and shows why the `mktemp` design matters. As run for revision
5, `docs-delivery-claims-r5.sh` made **127 failure-gated checks: 126 lines
reporting `PASS`** — 21 from the shell's own `assert` helper (5 in check 19, 16 in
check 20) and 105 printed by check 19's Python region comparison, whose failure
path sets the exit status that the shell assertion
`revision-5 region and text diff` reads — **plus 1 gated
`ASSERT r5_hunk_count_is_4=True`**. **0 `FAIL` lines; 0 failed assertions; exit
status 0.** Every line of that log is
content-asserted; the script prints no unasserted recorded output at all, and it
reads no host-dependent or volatile value — not even a toolchain banner — so
nothing in it drifts. After this revision was finalized, the script was rerun
twice and each run's output diffed against
`review/evidence/docs-delivery-claims-r5.log`; both diffs were empty, so **that
log is the complete output of that script, reproducible byte-for-byte on any
checkout whose object database holds the revision-4 blob**. The one way it can
legitimately differ is the one check 16 already documents: a run from a plain file
copy with no `.git` cannot read the blob, so check 19 reports `FAIL` and the
script exits 1.

| # | Check | Command | Exit | Result | Log |
|---|---|---|---:|---|---|
| 17 | Revision-4 diff against the revision-3 blob | `git cat-file blob 460e6f9002663f7e00921406c3bd9bc2785328fe`; region extraction and `difflib.unified_diff` against this file | 0 | revision-3 blob sha256 asserted `4647372666…`; **26 regions asserted byte-identical** — the nine check 16 carried from revision 2 (the licence-partition table, its reading, the shared-requirement block, the four `- assumes` lines, check 8's snapshot rationale, the revision-1 defect record, disagreement 4, unproven entry 3, the revision-1 history entry) — **unproven entry 3 re-anchored** on the deliberately looser end marker `4. **Wh` (`docs-delivery-claims-r4.sh:98`) in place of check 16's `4. **Whether mdBook`, which revision 4's J1 rewrite of unproven entry 4's opener invalidated, so check 17 asserts the same region check 16 could no longer locate — plus seventeen more revision 4 must not touch (the revision-3 recommendation-change note in two parts, the ledger decision table, the four-artifacts paragraph, the `theme/` rule, the ledger-rows-settled paragraph, both `BASELINE-REVIEW` lines, the minimal example, the `re-verify:` line, the **whole `## Parameters` section**, the 16-row check table, the gated-count paragraph, the reproducibility paragraph, disagreements 2–3, the revision-2 history entry, and the revision-3 entry's body below the sha256 line revision 4 substitutes for its "this document" opener); **eight regions the findings require changed** asserted to have changed *and* to carry their marker sentence; **34 required texts** asserted present and **11 absent** from the live decision — including the two overreaching practice sentences and both "gains nothing"/"buys nothing" clauses; the title asserted to name revision 4; no `## Supersedes`; **whole-file hunk count asserted to be exactly 17**. Recorded as run against **revision 4**; against revision 5 the title and hunk-count assertions fail by construction, as disclosed above and re-asserted by check 19 | `evidence/docs-delivery-claims-r4.log` |
| 18 | Preserved artifacts, and gate 5's async facts | `shasum -a 256` over seven evidence artifacts; a `[[package]]` reader over `evidence/mdbook-0.5.4-Cargo.lock` | 0 | all seven artifacts asserted **byte-identical** to revision 3 (`docs-delivery-claims.sh`, `docs-delivery-claims.log`, the three auditors' logs, the lock, the licence snapshot); gate 5's async stack read from the lock and asserted by version — `tokio` **1.53.1**, `axum` **0.8.9**, `tokio-tungstenite` **0.29.0** — together with `font-awesome-as-a-crate` **0.3.1** and `elasticlunr-rs` **3.1.0**, the two packages the shipped-site notice rule reasons about; a control asserts that a package absent from the lock reports `NONE`, so the reader can fail | same |
| 19 | Revision-5 diff against the revision-4 blob | `git cat-file blob ec356a0d8492a349292807db6cf888aac53619a1`; region extraction and `difflib.unified_diff` against this file | 0 | revision-4 blob sha256 asserted `ebcbe23606…`; **37 regions asserted byte-identical** — every one of check 17's twenty-six preservation regions on its check-17 anchor (including unproven entry 3 on the re-anchored `4. **Wh`), plus the eight regions check 17 required revision 4 to change and revision 5 must now leave alone (the shipped-site notice rule, gap 4, the six-gate block, ground 2, the confidence statement, the runner-up, disagreement 1, and `**Uncertainty.**` to end of file), plus the check-18 table row and the revision-4 history entry's body below its new sha256 line; **3 regions the finding requires changed** asserted to have changed *and* to carry their marker sentence (the disclosure paragraph, check 17's table row, the revision-4 history entry's opener); **46 required texts** asserted present — including the two verbatim `FAIL` lines this revision quotes, `ASSERT hunk_count_is_17=True`, both end anchors, and the revision-4 sha256 — and **15 absent** from the live decision, among them the three false or overstated clauses J4 names and one mis-citation this revision corrects on its own; the title asserted to name **revision 5**; no `## Supersedes`; **whole-file hunk count asserted to be exactly 4** | `evidence/docs-delivery-claims-r5.log` |
| 20 | Preserved artifacts under revision 5, and the gate-5 facts re-read | `shasum -a 256` over nine evidence artifacts; a `[[package]]` reader over `evidence/mdbook-0.5.4-Cargo.lock` | 0 | all nine artifacts asserted **byte-identical**: check 18's seven (`docs-delivery-claims.sh`, `docs-delivery-claims.log`, the three auditors' logs, the lock, the licence snapshot) **plus `docs-delivery-claims-r4.sh` and `docs-delivery-claims-r4.log`**, which revision 5 preserves as history exactly as revision 4 preserved revision 3's pair; gate 5's async stack re-read from the lock and re-asserted by version — `tokio` **1.53.1**, `axum` **0.8.9**, `tokio-tungstenite` **0.29.0** — with `font-awesome-as-a-crate` **0.3.1** and `elasticlunr-rs` **3.1.0**, and the same absent-package control, so those five figures stay gated by a script that exits 0 | same |

**Reproducibility.** `review/evidence/docs-delivery-claims.log` is **regenerated
for revision 3** and is the output of the revision-3 script; it necessarily
differs from revision 2's log, which the revision-2 auditor reproduced
byte-for-byte into `review/evidence/audit-docs-delivery-model-r2.log` (that file
is the auditor's artifact and is left untouched, as is the revision-1 auditor's
`audit-docs-delivery-model-r1.log`). After this decision was
finalized, the revision-3 script was rerun twice and each run's output diffed
against the committed log; both diffs were empty, so **the log is the complete
output of the script, reproducible byte-for-byte on this host**. Four comparison
rules an auditor needs.
First, the check-1 banner names this host's `rustc`, `cargo`, `gh` and OS
versions and will differ on another machine; nothing else in the log is
host-dependent. **Second, check 16 reads the repository's own git history** —
`git -C <repo root> cat-file blob 9f2bcb9ddf5266bf4face766e98b7cd1be3616ad` — and
therefore requires `$REPO_ROOT` to be a git checkout (a clone or a worktree)
whose object database contains that blob. **A rerun from a plain file copy of the
tree, with no `.git`, cannot run check 16**: the blob read fails, check 16 reports
`FAIL`, and the script exits 1. That is a precondition of the check, not a
regression; revision 1's auditor reran from exactly such a copy, so an auditor
who repeats that arrangement must either clone or copy the `.git` directory with
it. Checks 1–15 are unaffected and do not read git. **Third, the
`recorded (not gated)` block is the one place a rerun may legitimately differ
without anything being wrong**: it prints `smorinlabs/rs-launch-blueprint`'s
`has_pages` and `/pages` status, which change when the owner enables Pages. That
block asserts nothing, so the script's exit status does not depend on it, and the
decision cites it only as of 2026-09-13. Fourth, checks 2–16 are otherwise
assertion-shaped on purpose — they print
`PASS`/`FAIL` and stable fields (licence strings, `yanked`, `archived`, a pinned
run's `conclusion`, a pinned blob's or pinned tree's grep counts, tag-stripped
documentation substrings) and deliberately carry **no** volatile counter: no
`stargazers_count`, no `recent_downloads`, no `pushed_at`, no open-issue
`total_count`. **The trees checks 12 and 13 read are pinned to commit SHAs**, so
they are immutable and do not drift with the projects' default branches. Those
figures appear in this decision only where they are attributed to a raw report
with its retrieval date. A future rerun therefore differs only if a fact the
decision depends on has actually changed, which is the point.

## Engines

- **codex** `raw/codex-68292e725a5f2d94365ebeb889c4ae4cf88ee3975a8bcbdd11dc6cd6668e190f.md`, retrieved 2026-09-05 — recommends the README-centric CommonMark/GFM tree with no generator, no hosting, no preview server and no scaffold recipe; names `mdBook` 0.5.4 as the conditional successor and rejects Zola; raises one `BASELINE-REVIEW` line (F358).
- **opus** `raw/opus-a80f5625f09deaf7e9534e4f3b5a656d8e106da7ac1f2918b05fab6acc084747.md`, retrieved 2026-09-10 — recommends the dual-readable tree built by `mdbook` 0.5.4 and deployed to GitHub Pages through the first-party action triple; supplies the dialect intersection, the `SUMMARY.md` navigation decision and the differentiate policy; raises two `BASELINE-REVIEW` lines (F357, F358).

**Disagreement 1 — ship a generator, or not (F341).** `codex` says no
requirement for generated HTML, hosted search or a public site has been
established, so a generator is excluded on fit; `opus` says the corpus is
book-sized by fiat (F342 fixes six categories, ts already carries 39-plus files)
and that mdBook 0.5 removes the historical cost of a generator by keeping the
source GitHub-faithful. **Settled for `opus`, on fit, in revision 3.** Revision 2
did not settle it: it recorded the disagreement as a live branch and used the
licence condition as the tiebreaker, saying in terms that the tiebreaker "is not
a fit judgement". The owner's ruling of 2026-09-12 struck that tiebreaker and
left the question genuinely open, so revision 3 answered it. **The evidence that
decided it**, in the order it carried weight: (i) check 5 and check 6 together
show the generator takes nothing away from the raw-source reader — mdBook 0.5's
`.md`→`.html` and `README.md`→`index.html` conversions and its use of GitHub's
own alert syntax are stated by the maintainers, and GitHub's renderer behaves as
claimed — so adopting it is a superset of `codex`'s shape, not a trade against
it; (ii) check 12 measures the corpus F342 fixes at the ts pin (35 `.md` files,
171,225 bytes, six nested category directories) and check 13 shows **the five
repositories it pins** splitting on exactly that structure — `ripgrep`, `clap`,
`serde` and `ratatui` carry flat root files with no `docs/`-like directory and no
`book.toml`, while `cargo-generate`, the one surveyed Rust CLI with a nested
narrative tree, ships `guide/book.toml`. That sample is one-of-five on the nested
side and carries no stated selection rule; its scope is stated in full at ground
2, which also cites the seven further `book.toml` adopters `opus`'s raw carries
(including `rust-lang/rustup`, a Rust CLI) as figures carried rather than
re-verified here; (iii) check 14 records that mdBook's HTML renderer enables
search by default, which is the capability a bullet list cannot supply over 35
files. `codex`'s "no established requirement" is answered rather than overruled:
F342 is an established owner requirement for a six-category information
architecture, and the open question was only whether a hand-maintained bullet
list is adequate navigation for it. The full statement is `## Decision`'s **fit
judgement**; its confidence is medium, its reversal is one commit, and
`## Decision` also states what would raise it above medium and which three P03
signals would show it wrong.

**Disagreement 2 — Zola's standing.** `codex` records Zola 0.19.1 as a qualified
general-static-site alternative and notes its crates.io record looks obsolete;
`opus` records the crates.io entry as a yanked placeholder and the project as
EUPL-1.2. **Settled for `opus`, and — re-examined in revision 3 — on grounds that
never depended on the licence.** Check 2: `zola` has no unyanked version on
crates.io (one version, `0.1.1`, yanked), so there is no registry artifact to
pin; `codex`'s "0.19.1" figure comes from Zola's own documentation, not from the
registry, and this run did not verify it. Check 3: `getzola/zola` reports
`license.spdx_id` `EUPL-1.2` — **recorded as a fact and no longer weighed**,
because gate 1 is inapplicable. Check 15, new in revision 3, supplies the reason
that stands on its own: Zola's own configuration documentation names `base_url`
as "the only required configuration variable" and contains no `SUMMARY`, chapter
or book concept at all. It is the wrong shape for the job, and it loses to a
first-party generator whose source fidelity its maintainers document (check 5).

**Disagreement 3 — plugins.** `opus` excludes `mdbook-alerts` on maintenance and
`mdbook-admonish` on fidelity, and records `mdbook-mermaid` as a cheap future
addition rather than a competitor; `codex` recommends no plugin at all.
**Settled toward "no plugin ships", with the facts verified and — in revision 3 —
with `mdbook-mermaid` re-judged on fit alone.** `lambdalisue/rs-mdbook-alerts` is
`archived: true` (check 3) and is therefore excluded here rather than
recommended — **no component of this recommendation is archived or unmaintained**.
`badboy/mdbook-mermaid` is `archived: false` (check 3) and **MPL-2.0** (check 2);
revision 2 declined it partly because it "would sit inside the same licence
condition as mdBook itself", which the owner's ruling voids. Re-judged on fit, it
still does not ship: it is a preprocessor, not a generator, so it never competed
for this item's decision, and this item's dialect policy contains no diagrams.
What revision 3 adds is the consequence of *not* adopting it — ` ```mermaid `
fences render differently on the two surfaces (check 14: GitHub documents diagram
rendering for that fence; mdBook's Markdown reference contains no occurrence of
`mermaid`), so the fence goes into F343's forbidden set. Adopting the
preprocessor later would remove that exclusion; it is recorded as a cheap future
addition, exactly as `opus` framed it.

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
   200) and once on a fork (build green, deploy skipped).
2. **Identical rendering on both surfaces is inspected, not verified.** `opus`
   recorded that no local renderer reproducing GitHub's exact Markdown semantics
   was identified, so the property rests on three `grep` guards plus review. This
   run improved the GitHub half only: check 6 exercised GitHub's own
   `POST /markdown` endpoint and confirmed the allowed and forbidden syntax
   behave as claimed. **No mdBook output was produced and no differential
   comparison was made**, so the sentence "one corpus renders identically in two
   places" remains a design intention supported by the maintainers' documented
   conversion rules — not a verified identity. What would prove it:
   `mdbook build` over three representative pages (a table-and-links page, an
   alert page, a fenced-Rust page) with the resulting HTML normalized and diffed
   against this same endpoint's output for the same sources — P03. This run did
   not build a book, because the role contract forbids implementing the
   recommendation.
3. **mdBook's `unsafe` posture** was not established from a source audit or a
   `cargo-geiger` run in either engine's run or this one; it is bounded only by
   the tool's build-time role. What would prove it: a `cargo-geiger` run over the
   pinned tree, which R06's policy owns the standard for.
4. **Which third-party assets a default `mdbook build` emits into `book/`, and
   what notice each one carries.** Revision 3 scoped this entry to the CC-BY-4.0
   Font Awesome icons; revision 4 widens it, under **The shipped-site notice
   rule** in `## Decision`, to **every** third-party file the default theme and
   the default search runtime write into `book/` — stylesheets, web fonts, icon
   assets and JavaScript, the search runtime included, whether or not the crate
   it came from appears in the 218-package walk. Nothing was built in this run and
   **no asset list is asserted here**; check 8 found `font-awesome-as-a-crate`
   0.3.1 (`CC-BY-4.0 AND MIT`) and `elasticlunr-rs` 3.1.0 (`(MIT OR Apache-2.0)
   AND MIT`) in mdBook's dependency tree, and check 14 found search enabled by
   default, which is why the question is open rather than answered. What would
   prove it: `mdbook build` over a sample corpus in P03, then enumerating
   `book/`'s non-content files and reading each one's upstream notice; the output
   is a `book/` third-party-notices file, or a finding that none is owed. This is
   unconditional work because the generator ships, and the duty it may trigger is
   a distribution-notice duty on shipped content that the owner's licence ruling
   does not void.
5. **Wall-clock and byte cost** of installing and running mdBook: nothing was
   timed or measured in this run or in either raw; only the maintainers'
   qualitative wording is carried.
6. **The hosted Pages URL.** `https://smorinlabs.github.io/rs-launch-blueprint/`
   is the derived GitHub project-pages default for this repository's slug, not an
   observed URL: `GET https://api.github.com/repos/smorinlabs/rs-launch-blueprint`
   reports `has_pages: false` and `GET .../pages` returns HTTP 404 (retrieved
   2026-09-13, recorded and not gated). What would prove it: the owner setting the
   Pages source to "GitHub Actions" — a one-time manual repository setting no
   workflow can perform — and a deploy run publishing a page that answers 200.
7. **That an mdBook acquired by R42's recipe carries a working `mdbook serve`**
   (gate 5, new in revision 4). Nothing was installed and `mdbook serve` was never
   run in this run or in either raw; the claim rests on the maintainers scoping
   `--no-default-features --features search` to an install that opts out of
   defaults (check 5), which is an inference about the default feature set, not an
   observation of a binary — and it must hold on both of R42's candidate recipe
   bodies, the prebuilt artifact and the `cargo install --locked` fallback. What
   would prove it: the first `just docs-dev` in P03 opening a served book.

**What P03 must validate.** Acceptance criteria (a)–(e),
with (b) handed to R82's checker and (e) enforced by review because it has no
executable form. Additionally: that `mdbook build` with
`[build] create-missing = false` fails on an unregistered page rather than
fabricating one; that `docs/README.md` and each section `README.md` become
`index.html`; that the two-job workflow behaves as described upstream and on a
fork; and gaps 1, 2, 4, 6 and 7 above. Revision 2 split this list across two
branches; with the generator decided, the whole list applies. One item revision 2
placed on the no-generator side is retained anyway as a belt-and-braces
requirement for R82: the link walk should treat `docs/SUMMARY.md` as the
authoritative navigation artifact, so that navigation drift is caught even in a
fork that has not run the book build.

**Revision history.**

- **Revision 1**, 2026-09-10, sha256
  `204949689ccc0c3190c2479ca80d5c18f9fd9753931cffcf78706190d75ff21d`. Rejected by
  `review/audit-codex.md` on four findings, all of them supporting claims stated
  more absolutely than their evidence. No finding challenged the recommendation,
  the branch split, the branch default, the substitute analysis, or either
  unproven entry.
- **Revision 2**, 2026-09-12, sha256
  `5ab7479c7d5e0485fa1c05aef9a894f4c36b56de3692bef89c17efc33a09404e`. **Approved**
  by `review/audit-codex.md` (actor `audit-codex-…-r2`, model `gpt-5.6-terra`,
  `unresolved-findings: none`). What each finding changed:
  **F1** — the claim "the other 210 are permissive" is replaced by an asserted
  five-class partition of all 218 packages with every conjunctive expression
  named verbatim; this revision's own walk found **four** conjunctions where the
  auditor named one, and the `CC-BY-4.0` obligation is now tied explicitly to
  branch-A site assets (gap 4) rather than sitting next to a contradicting
  aggregate. **F2** — the "Linux and macOS, both x86_64 and aarch64" sentence is
  replaced by the six-asset mapping from the release endpoint, with the absent
  `aarch64-unknown-linux-gnu` asset stated and asserted; new check 11 gates it.
  **F3** — the branch-A delta now enumerates the four `justfile` recipes
  alongside `book.toml`, `docs.yml` and the README URL, at all three places the
  one-commit move is described. **F4** — the false "every check asserts on its
  content" claim is replaced by an explicit gate-versus-recorded-output
  distinction, and gates were added for every cited fact that lacked one,
  including check 8's two previously ungated `ASSERT` lines. Gated checks rose
  from 52 to 100, and new check 12 proves mechanically which regions of revision 1
  this revision did not touch. Nothing else changed: the unproven entries (the Pages action
  triple's exact version matrix, and identical rendering resting on inspection
  because no local renderer matching the host's dialect was identified) are
  carried unaltered, and `## Empirical check` check 12 proves the untouched
  regions by diff against the revision-1 blob.
- **Revision 3**, 2026-09-13, sha256
  `4647372666b7e94537d75fb684c6ca5ec5cca6929841330bab8832ddb6e7328e`. **Approved**
  by `review/audit-codex.md` (empirical, `unresolved-findings: none`) and
  **rejected** by `review/audit-fable.md` (judgment, findings J1, J2, J3), which
  confirmed that the recommendation follows from the evidence. Driven by the owner's licence ruling
  of 2026-09-12 (Q4 as superseded by Q7.B), not by an audit finding: revision 2's
  audit recorded `verdict: approve`, `unresolved-findings: none`. **The
  recommendation changed.** Revision 2 decided the generator layer conditionally
  on that ruling and withheld it by default; the ruling struck fitness gate 1
  from every item's evaluation, and because revision 2 had stated that its
  tiebreaker "is not a fit judgement but the licence condition", striking the gate
  left the question unanswered rather than answered. Revision 3 makes the fit
  judgement and ships the generator. Consequences worked through: the
  two-branch table collapses to one decided table; **F341**, **F346**, **F351**
  and **F352** move to the shipping value; **F344** loses its conditional
  drift sentence; **F343** gains ` ```mermaid ` in the forbidden set; the hosted
  Pages URL enters the README pointer and is recorded as derived-and-not-yet-live
  (new unproven entry 6); gap 4's Font Awesome attribution becomes unconditional;
  F357's placement question goes live; F358 collapses to the shipped-generator
  text; and the two unregistered couplings (R42's `package-manager-invocation`,
  R11's job split) become unconditional. Gate 1 is recorded `inapplicable` with
  the ruling as its reason rather than deleted, because the binding prompt still
  contains it. Retained unchanged by the ruling: the repository's own `license`
  expression, the 218-package tree walk (now a finding, not a gate), the `theme/`
  prohibition, and the Font Awesome attribution duty. Re-evaluated on fit alone:
  `zola` (check 15) and `mdbook-mermaid` (check 14); neither changes the answer.
  Four checks are new — 12 (the corpus measured at the ts pin), 13 (the practice
  split by narrative structure), 14 (mdBook's default search, its absence of
  mermaid support, and GitHub's documentation of it), 15 (Zola's site model) —
  and check 16 replaces revision 2's check 12, diffing this file against the
  revision-2 blob.
- **Revision 4**, 2026-09-15, sha256
  `ebcbe236064e05558895d2acc2ee5f6b7f9a6c712f6527c76c9fb92fdeecbf51`. **Approved**
  by `review/audit-codex.md` (empirical, `unresolved-findings: none`) and
  **rejected** by `review/audit-fable.md` (judgment, finding J4), which confirmed
  that the recommendation follows from the evidence and that J4 does not touch it.
  Driven by the judgment audit of revision 3
  (`verdict: reject`, findings J1, J2, J3), while the empirical audit of revision 3
  recorded `verdict: approve` and
  `unresolved-findings: none` on that revision. **The recommendation did not
  change**, and neither did the crate, the version, the ledger-row values, the
  corpus figures, the four `- assumes` lines or any evidence artifact; the
  judgment auditor stated that the recommendation follows and that revision 4 is
  an editing pass. **J1**: a **shipped-site notice rule** is added — a licence
  expression is owed against an act of redistribution, this template performs two
  (publishing the repository, publishing `book/`), the 218-package walk answers
  only the first, and crate metadata cannot enumerate emitted files in any case;
  `elasticlunr-rs`'s conjunct is disposed of explicitly against check 14's
  default search; and gap 4 widens from the Font Awesome icons to every
  third-party asset the default theme and default search runtime emit into
  `book/`. **J2**: a **Fitness gates, answered for the recommended tool** block
  records all six gates in R42's and R67's shape, gate 1 keeping its
  `inapplicable` line verbatim; gate 5 is answered for the first time — default
  features include the `mdbook serve` HTTP server, the contributor install line is
  R42's generic recipe with no feature flag (so `serve` survives on either of
  R42's candidate bodies), `--no-default-features --features search` is available
  only to a CI job that never serves and is explicitly not this template's install
  line, the unverified half is
  recorded as new unproven entry 7, and mdBook's `tokio`/`axum`/`tokio-tungstenite`
  stack is shown to stay inside mdBook's own process so R05 and R69 are
  unconstrained. **J3**: the bolded practice claim is narrowed to the five
  repositories check 13 pins, with the sample's scope and its missing selection
  rule stated once in full at ground 2 and referred to from disagreement 1;
  `opus`'s seven further `book.toml` adopters — the six `rust-lang` documentation
  repositories and `rust-lang/rustup` at `doc/user-guide/book.toml`, a Rust CLI
  rather than a language book — are cited with `opus`'s endpoint and retrieval
  date and marked as carried, not re-verified; a **What would raise this above
  medium, and what would show it wrong** paragraph supplies the missing half of
  the confidence statement; and the runner-up's "gains nothing in return", with
  its alternative-(B) twin, is replaced by ground 4's own cost list. Two new
  offline checks, 17 and 18, are added in a **new** script
  (`review/evidence/docs-delivery-claims-r4.sh`); checks 1–15 were not re-run and
  revision 3's script and log are untouched.
- **Revision 5**, 2026-09-15, this document. Driven by `review/audit-fable.md`
  (judgment audit of revision 4, `verdict: reject`, single finding J4), while
  `review/audit-codex.md` (empirical) recorded `verdict: approve` and
  `unresolved-findings: none` on the same revision. **Nothing about the
  recommendation moved**: not the crate, the version, the ledger-row values, the
  corpus figures, the four `- assumes` lines, the shipped-site notice rule, the
  six-gate block, the confidence statement, or any evidence artifact. **J4**: the
  paragraph disclosing `review/evidence/docs-delivery-claims.sh`'s failure named
  the wrong assertion — it blamed check 16's whole-file hunk-count tripwire, which
  in fact still passes and prints `ASSERT hunk_count_is_17=True`, when the failing
  assertion is check 16's byte-identical-region assertion for unproven entry 3,
  whose end anchor `4. **Whether mdBook` stopped matching once revision 4 rewrote
  unproven entry 4's opener. Both preserved scripts were rerun in an isolated
  clone before the paragraph was rewritten, and the paragraph now quotes the two
  `FAIL` lines verbatim, records the `PASS`/`FAIL` tallies, and records that check
  17 keeps asserting that same region only because it re-anchors it on the looser
  end marker `4. **Wh` — a fact check 17's table row now carries as well. The
  false causal clause and the overstated "carries every region assertion check 16
  made" are gone. Revision 5 trips check 17's title assertion the same way
  revision 4 tripped check 16's entry-3 anchor — a rerun shows that assertion is
  the only one that fails, and that check 17's hunk-count gate still passes — so
  `docs-delivery-claims-r4.sh` and its log
  are preserved byte-identical as the record of the revision-4 run and two new
  offline checks, 19 and 20, are added in a **new** script
  (`review/evidence/docs-delivery-claims-r5.sh`) that re-targets the revision-diff
  mechanism at the revision-4 blob; checks 1–15 were not re-run.

**Uncertainty.** High confidence in the mechanism facts (checks 2–15 read them
from the maintainers' documentation, the registry, the advisory database, pinned
repository trees, or GitHub's own renderer). **Medium confidence in the fit
judgement itself**, which is the one call this decision makes that no source
states for it: it weighs a measured corpus shape and a **five-repository
structural sample, one of them on the nested side and chosen without a stated
selection rule**, against an unstated owner preference, and it is the kind of
call an owner may reverse — which costs one commit, because the corpus does not
change. **What would move it off medium, and what would show it wrong, are stated
in `## Decision`** under *What would raise this above medium*: a pinned
re-verification of `rust-lang/rustup`'s nested guide or an owner statement about a
public documentation URL would raise it; a corpus that stays flat, a rendering
differential inside the agreed dialect (gap 2), or a docs job that turns into
recurring maintenance would show it wrong. Medium
confidence likewise in the two content-policy judgements
`opus` originated and this decision adopts — dropping per-directory page lists in
favor of a single `SUMMARY.md`, and the differentiate position on F345/F346 —
because both depart from ts's shipped shape.
