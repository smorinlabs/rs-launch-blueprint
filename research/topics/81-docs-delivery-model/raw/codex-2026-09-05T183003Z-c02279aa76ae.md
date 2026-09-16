### Landscape

R81 decides a delivery architecture, not an API-reference generator: the latter remains R82.  The field map is: (1) built-in/first-party practice: Rust's own project uses `mdBook` for book-style material, while GitHub renders repository Markdown; (2) established standards: CommonMark 0.31.2 plus GitHub Flavored Markdown (GFM) for source files, and static HTML publishing through `mdBook` or a general static-site generator; and (3) up-and-comers: the TypeScript decision's Astro Starlight note, which is a JavaScript tool that is documented but not shipped and is not a Rust candidate.  The Rust Project's use makes `mdBook` an authoritative, maintained reference for a *book*; GitHub's documentation is authoritative for relative links in a repository; and the CommonMark specification is the normative syntax reference.  Sources retrieved 2026-09-05: [mdBook introduction](https://rust-lang.github.io/mdBook/), [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax), and [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/).

The surveyed practice supports both architectures but does not make them interchangeable.  `mdBook` states that the Rust Project and *The Rust Programming Language* book use it, and Rust's main repository README points readers to The Book; that is strong evidence for a navigable, generated book when the product is a book.  `cargo-generate` demonstrates that Rust templates are ordinary Git repositories consumed through a README-driven generator workflow, but it does not establish a documentation-site default.  Sources retrieved 2026-09-05: [mdBook introduction](https://rust-lang.github.io/mdBook/), [rust-lang/rust README](https://github.com/rust-lang/rust/blob/main/README.md), and [cargo-generate README](https://github.com/cargo-generate/cargo-generate).

For this template's small, source-controlled Diataxis tree, the fit comparison is different from a language book: a plain tree gives GitHub readers the files they cloned, avoids a second published representation, and lets a root README link work on every branch.  `mdBook` is the qualified hosted-book alternative because it supplies a chapter manifest, HTML build, live server, search, and code-block testing.  Zola is a qualified general static-site alternative, but its content sections, templates, required `base_url`, and site configuration solve a broader web-site problem than this documentation tree.  The last statement is an inference from each tool's documented structure, not a performance claim.  Sources retrieved 2026-09-05: [mdBook book anatomy](https://rust-lang.github.io/mdBook/guide/creating.html), [mdBook SUMMARY.md format](https://rust-lang.github.io/mdBook/format/summary.html), [Zola overview](https://www.getzola.org/documentation/getting-started/overview/), and [Zola configuration](https://www.getzola.org/documentation/getting-started/configuration/).

### Principles and implementation

The shared requirement is a discoverable, maintained documentation capability for a CLI, library, and optional web-service template.  Its agreement level is **capability and information architecture**, not a shared hosted-site architecture: F342 preserves the owner-approved Diataxis categories, F347 preserves an authoring guide, and F341/F343-F346/F351-F352 deliberately record divergent py and ts mechanisms.  The Rust implementation must therefore preserve six observable behaviors: a reader can find the documentation from `README.md`; every Diataxis section has a stable entry in a navigation index; every page uses a portable Markdown subset; there is one canonical landing narrative; contributors have a documented page-addition path; and R82 can later check links in the chosen tree.  Repository evidence retrieved 2026-09-05: `docs/port/COMMONALITY.md` F341-F353 and `docs/port/PARAMETERS.md` fixed parameters.

The recommended architecture is a README-centric plain-markdown tree: `README.md` is the short product landing page and points to `docs/docs.md`; `docs/docs.md` is the single bullet-list navigation index for the preserved categories; each content page uses CommonMark plus only portable GFM features; and no generated site, Pages deployment, preview server, or scaffold command ships.  This preserves source readability because GitHub resolves relative links in rendered repository files.  Sources retrieved 2026-09-05: [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) and [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/).

`mdBook` is a sound alternative only when the template has a demonstrated need for generated HTML navigation, integrated search, rendered code-example tests, or an independently branded public documentation URL.  It is not a drop-in rendition of raw GFM: its parser is CommonMark with documented extensions, and `SUMMARY.md` is a strict additional navigation manifest.  It does provide the py-like mechanics `mdbook init`, `mdbook serve`, and `mdbook build`; those benefits do not establish their need in the initial template.  Sources retrieved 2026-09-05: [mdBook Markdown](https://rust-lang.github.io/mdBook/format/markdown.html), [mdBook SUMMARY.md](https://rust-lang.github.io/mdBook/format/summary.html), [mdBook CLI](https://rust-lang.github.io/mdBook/cli/), and [mdBook creating a book](https://rust-lang.github.io/mdBook/guide/creating.html).

GitHub Pages would be a reasonable publisher if a generated site is later selected: GitHub documents an Actions deployment that uploads a built artifact and deploys it with `pages: write` and `id-token: write` permissions.  It is not a reason to select a generator now, because it adds a deploy workflow and hosted output to a template whose current deliverable can be read directly in its repository.  The second sentence is a fit inference from the documented workflow and the R81 scope.  Sources retrieved 2026-09-05: [GitHub Pages Actions deployment](https://docs.github.com/en/get-started/start-your-journey/deploying-your-website-automatically) and repository prompt `inputs/prompt.md` (retrieved 2026-09-05).

BASELINE-REVIEW: F358 — a docs system records an upgrade path when requirements outgrow the shipped delivery model — retain a short conditional note naming the trigger and a fresh decision, not Astro Starlight or another preselected generator — evidence: `docs/port/BASELINE-REVIEW.md` F358 says the TypeScript Starlight note is documented but not shipped and R81 determines whether an upgrade note has a subject (retrieved 2026-09-05).

### Recommendation

Ship one stack: **CommonMark 0.31.2 source with portable GFM, rendered as a README-centric repository tree on GitHub; `README.md` points to `docs/docs.md`; `docs/docs.md` owns a relative-link bullet index; no site generator, hosting workflow, local preview server, or init recipe ships.**  Keep one canonical landing narrative in `README.md`; do not duplicate it in `docs/index.md`.  This is a named reference pattern, not a crate stack: it intentionally adds no Cargo dependency or executable version.  CommonMark 0.31.2 is the dialect baseline; GFM additions must remain readable as plain Markdown.  Sources retrieved 2026-09-05: [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/) and [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).

### Members

#### README-centric CommonMark/GFM tree (recommended reference pattern)

##### Landscape

This member is an architecture and standard, not a crate.  Crate downloads, release, GitHub stars, RustSec advisories, unsafe posture, default features, async-runtime coupling, binary size, and compile time are **inapplicable** because it adds no executable or dependency.  The governing standards are CommonMark 0.31.2 and GitHub's documented relative-link rendering.  Sources retrieved 2026-09-05: [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/) and [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).

##### Principles and implementation

Keep documentation discoverable, source-readable, and non-duplicated while retaining the fixed Diataxis categories and an authoring guide.  `README.md` contains the product introduction and one relative Documentation link; `docs/docs.md` contains the category index; all other pages are linked from that index or a category index.  This realizes the required capability without selecting a site-hosting architecture.  Repository sources retrieved 2026-09-05: `docs/port/COMMONALITY.md` F341-F347.

##### Dominant choice

Use CommonMark 0.31.2 as the baseline and portable GFM only where GitHub's repository renderer is the intended reader.  GitHub documents branch-aware relative links, which is the navigation mechanism this member relies on.  Sources retrieved 2026-09-05: [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/) and [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).

##### Qualified shortlist

The qualified alternatives are `mdBook` 0.5.4 for a generated book and Zola 0.19.1 for a general static site.  Both can render CommonMark-derived Markdown and serve locally, but each adds a build configuration and published-output concern.  Sources retrieved 2026-09-05: [mdBook 0.5.4 documentation](https://rust-lang.github.io/mdBook/), [mdBook configuration](https://rust-lang.github.io/mdBook/format/configuration/general.html), and [Zola 0.19.1 overview](https://www.getzola.org/documentation/getting-started/overview/).

##### Excluded by gate

No candidate is excluded by a crate fitness gate because this recommendation introduces no crate.  A generated-site architecture is excluded **by fit**, not by popularity: R81 has no established requirement for generated HTML, hosted search, versioned pages, or a public-site identity.  This is an architectural judgment grounded in `inputs/prompt.md`, retrieved 2026-09-05.

##### Up-and-comers

Astro Starlight is only a documented TypeScript future option in F358; it is neither shipped nor designated for Rust.  Do not add it to this scaffold or treat it as the next default.  Repository source retrieved 2026-09-05: `docs/port/BASELINE-REVIEW.md` F358.

##### Fit for this template

This template starts as a CLI, library, and optional web service, so repository documentation must work before any public website exists.  A raw tree works in clone, pull request, package source, and GitHub; it keeps the same source visible to readers and contributors.  The multi-surface assertion is an inference from repository Markdown and GitHub's relative-link behavior.  Source retrieved 2026-09-05: [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).

##### Recommendation

Ship this member with no crate version.  Add `docs/docs.md`, the Diataxis category directories, and `docs/authoring.md`; point `README.md` to the index; do not add `book.toml`, `SUMMARY.md`, a `docs/index.md` landing duplicate, or a docs deployment workflow.  Repository source retrieved 2026-09-05: `docs/port/COMMONALITY.md` F341-F347 and F351-F352.

##### Ranked runner-up

`mdBook` 0.5.4 is the runner-up.  It becomes preferable if a later owner decision requires a hosted, searchable book or executable Rust snippets, because its documented `build`, `serve`, and `test` commands then pay for their operational cost.  Sources retrieved 2026-09-05: [mdBook CLI](https://rust-lang.github.io/mdBook/cli/) and [mdBook introduction](https://rust-lang.github.io/mdBook/).

##### Tradeoffs

The cost is no generated navigation UI, full-text site search, hot-reload server, or automatic site deployment.  The benefit is no duplicated landing page, no special Markdown directive syntax, no docs-only binary, and no hosting permissions.  The costs and benefits are direct consequences of the documented `mdBook` manifest/build model and GitHub repository rendering.  Sources retrieved 2026-09-05: [mdBook book anatomy](https://rust-lang.github.io/mdBook/guide/creating.html), [mdBook SUMMARY.md](https://rust-lang.github.io/mdBook/format/summary.html), and [GitHub Pages deployment](https://docs.github.com/en/get-started/start-your-journey/deploying-your-website-automatically).

##### Parameters

No R81-owned or consumed registered parameter is needed.  This pattern respects `assumes rust-edition = 2024`, `assumes msrv-policy = stable minus 2 minor versions`, `assumes target-os-matrix = ubuntu-latest, macos-latest`, and `assumes license = MIT OR Apache-2.0` because it adds no Rust toolchain component.  Repository source retrieved 2026-09-05: `docs/port/PARAMETERS.md` rows 7-10.

##### Migration implications

Create the source tree directly in the template and explain page addition in `docs/authoring.md`: create the Markdown file, add its relative link to the appropriate index, and keep the root introduction only in `README.md`.  No generated output directory enters version control.  This is a proposed migration, not an executed change.

##### Validation strategy

Planned acceptance: confirm that `README.md` links to `docs/docs.md`, every Diataxis category appears in that index, and the index has only relative Markdown links; R82 must then provide the internal/external link oracle.  Do not represent a local editor preview or a pushed branch as a CI check.  Repository scope source retrieved 2026-09-05: `inputs/prompt.md` Out of scope and R82 coupling.

##### Confidence & re-verify trigger

Confidence is high for the initial template because this is a dependency-free, directly rendered source model.  Re-evaluate before adding search, versioned documentation, a public branded URL, a significant volume of generated API guides, or any requirement that raw GitHub rendering cannot meet.

##### Sources

[CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/) and [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax), retrieved 2026-09-05.

#### mdBook 0.5.4 (rejected hosted-book alternative)

##### Landscape

`mdBook` is an established Rust-project book generator, not a first-party Cargo component.  Its crates.io figures from `GET https://crates.io/api/v1/crates/mdbook`, retrieved 2026-09-05, are 859,844 90-day downloads and 10,120,336 all-time downloads; `GET https://crates.io/api/v1/crates/mdbook/versions` reports newest non-yanked 0.5.4, created 2026-07-06T19:18:00Z, `rust_version` 1.88.0.  `GET https://api.github.com/repos/rust-lang/mdBook`, retrieved 2026-09-05, reports 22,119 stars, `archived: false`, and `pushed_at: 2026-09-03T12:50:46Z`; `GET https://api.github.com/search/issues?q=repo:rust-lang/mdBook+is:issue+is:open` reports 566 open issues.  The issue-responsiveness median is unverified: unauthenticated issue comments do not establish which first responder is a maintainer.  The RustSec package page lists RUSTSEC-2021-0001 but marks versions >=0.4.5 patched, so 0.5.4 has no listed open instance of that advisory.  Sources retrieved 2026-09-05: [crates.io crate endpoint](https://crates.io/api/v1/crates/mdbook), [crates.io versions endpoint](https://crates.io/api/v1/crates/mdbook/versions), [GitHub repository endpoint](https://api.github.com/repos/rust-lang/mdBook), [GitHub issue-search endpoint](https://api.github.com/search/issues?q=repo%3Arust-lang%2FmdBook%2Bis%3Aissue%2Bis%3Aopen), and [RustSec RUSTSEC-2021-0001](https://rustsec.org/advisories/RUSTSEC-2021-0001.html).

##### Principles and implementation

`mdBook` creates a chapter tree from `book.toml`, `src/`, and mandatory `SUMMARY.md`; it renders HTML, supplies search, supports preprocessors, and can test Rust snippets.  It preserves the documentation capability and offers a native Rust implementation of py's hosted-site mechanics, but it changes the agreement level from capability to a generated-site architecture.  Sources retrieved 2026-09-05: [mdBook creating a book](https://rust-lang.github.io/mdBook/guide/creating.html), [mdBook SUMMARY.md](https://rust-lang.github.io/mdBook/format/summary.html), and [mdBook introduction](https://rust-lang.github.io/mdBook/).

##### Dominant choice

If a generated book is selected later, pin the tool as `mdBook` 0.5.4 and install a released binary or use the documented locked Cargo install.  The official documentation says version 0.5.4 requires Rust 1.88 and recommends `--locked` for a source install.  Sources retrieved 2026-09-05: [mdBook installation](https://rust-lang.github.io/mdBook/guide/installation.html) and [mdBook CI](https://rust-lang.github.io/mdBook/continuous-integration.html).

##### Qualified shortlist

`mdBook` is qualified: MPL-2.0 source license, no repository archive flag, current maintenance activity, a Rust Project reference, documented macOS/Linux release binaries, default HTML renderer, and no async-runtime coupling in the site configuration.  It passes the fixed MSRV floor because 1.88 is below the 1.96 floor implied by Rust 1.98 stable minus two minors on 2026-09-05; it is a build tool rather than a template runtime dependency.  Its binary-size and compile-time cost are qualitative: a prebuilt binary avoids local compilation, while the official CI guide warns that `cargo install` can be somewhat slow.  Unsafe posture is unverified from the queried endpoints; do not infer it.  Sources retrieved 2026-09-05: [GitHub repository endpoint](https://api.github.com/repos/rust-lang/mdBook), [Rust release announcements](https://blog.rust-lang.org/releases/), [mdBook installation](https://rust-lang.github.io/mdBook/guide/installation.html), and [mdBook CI](https://rust-lang.github.io/mdBook/continuous-integration.html).

##### Excluded by gate

None of the fixed fitness gates excludes `mdBook` 0.5.4: the historical RustSec advisory is patched in this version, Rust 1.88 meets the declared floor, and the official project distributes macOS and Linux binaries.  It is excluded from the initial stack by the architectural fit gate: the template has not established a requirement that justifies generated output and a deployment workflow.  Sources retrieved 2026-09-05: [RustSec RUSTSEC-2021-0001](https://rustsec.org/advisories/RUSTSEC-2021-0001.html), [mdBook installation](https://rust-lang.github.io/mdBook/guide/installation.html), and `inputs/prompt.md` (retrieved 2026-09-05).

##### Up-and-comers

No mdBook plugin is recommended.  Preprocessors and alternative backends are explicitly extensibility mechanisms, but adding one would introduce a separate compatibility and maintenance decision outside R81.  Source retrieved 2026-09-05: [mdBook developer guide](https://rust-lang.github.io/mdBook/for_developers/index.html).

##### Fit for this template

This is a good future fit for a long tutorial/reference book with executable snippets and public HTML readers.  It is a poor initial fit for a small repository tree because navigation must be duplicated into `SUMMARY.md`, raw-source readers can encounter mdBook extensions, and hosted delivery adds deployment policy.  The last two conclusions are inferences from mdBook's required manifest and extended Markdown documentation.  Sources retrieved 2026-09-05: [mdBook SUMMARY.md](https://rust-lang.github.io/mdBook/format/summary.html), [mdBook Markdown](https://rust-lang.github.io/mdBook/format/markdown.html), and [GitHub Pages deployment](https://docs.github.com/en/get-started/start-your-journey/deploying-your-website-automatically).

##### Recommendation

Do not ship `mdBook` 0.5.4 in the first template revision.  Name it as the conditional successor only after an owner chooses generated hosted documentation for a stated reader need.

##### Ranked runner-up

Zola 0.19.1 is the next generated-site alternative, but it ranks below `mdBook` because it requires general site templates and configuration rather than a purpose-built book manifest.  Sources retrieved 2026-09-05: [Zola overview](https://www.getzola.org/documentation/getting-started/overview/) and [Zola directory structure](https://www.getzola.org/documentation/getting-started/directory-structure/).

##### Tradeoffs

`mdbook serve` watches sources, rebuilds, and refreshes browsers; `mdbook init` creates a starter directory; `mdbook build` emits HTML.  Those are direct py-like authoring benefits.  They require a pinned tool, `book.toml`, `SUMMARY.md`, output handling, and—if public hosting is selected—a Pages workflow and permissions.  Sources retrieved 2026-09-05: [mdBook serve](https://rust-lang.github.io/mdBook/cli/serve.html), [mdBook creating a book](https://rust-lang.github.io/mdBook/guide/creating.html), and [GitHub Pages deployment](https://docs.github.com/en/get-started/start-your-journey/deploying-your-website-automatically).

##### Parameters

No R81-owned parameter applies.  A later adoption assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions`, `target-os-matrix = ubuntu-latest, macos-latest`, and `license = MIT OR Apache-2.0`; the first three are satisfied by the recorded 1.88 tool MSRV and documented platform binaries, while the license is a build-tool distribution fact rather than a template dependency.  Repository source retrieved 2026-09-05: `docs/port/PARAMETERS.md`; external sources retrieved 2026-09-05: [mdBook installation](https://rust-lang.github.io/mdBook/guide/installation.html) and [GitHub repository endpoint](https://api.github.com/repos/rust-lang/mdBook).

##### Migration implications

If promoted, add `book.toml`, move published source under `docs/src/`, create `docs/src/SUMMARY.md`, add a non-duplicated book introduction that links back to the root README, pin `mdbook` 0.5.4 in the development-tool mechanism chosen by R42, and add a Pages build/deploy workflow only after its authorization is settled.  This is a proposed future migration, not an executed change.

##### Validation strategy

Planned future acceptance on Ubuntu and macOS: install the exact release binary, run `mdbook build docs`, run `mdbook test docs` when Rust snippets exist, run `mdbook serve docs --open` during manual authoring, and verify the built artifact with R82's selected link gate before deployment.  No command was run because this report recommends no generator and must not mistake a proposed check for evidence.  Sources retrieved 2026-09-05: [mdBook CLI](https://rust-lang.github.io/mdBook/cli/) and [mdBook CI](https://rust-lang.github.io/mdBook/continuous-integration.html).

##### Confidence & re-verify trigger

Confidence is high that `mdBook` is the strongest native generated-book fallback and medium that 0.5.4 remains the correct pin.  Re-verify the release, MSRV, RustSec page, repository activity, and plugin-free configuration when a hosted-site requirement is approved.

##### Sources

[mdBook documentation](https://rust-lang.github.io/mdBook/), [crates.io crate endpoint](https://crates.io/api/v1/crates/mdbook), [crates.io versions endpoint](https://crates.io/api/v1/crates/mdbook/versions), [GitHub repository endpoint](https://api.github.com/repos/rust-lang/mdBook), [GitHub issue-search endpoint](https://api.github.com/search/issues?q=repo%3Arust-lang%2FmdBook%2Bis%3Aissue%2Bis%3Aopen), and [RustSec advisory](https://rustsec.org/advisories/RUSTSEC-2021-0001.html), retrieved 2026-09-05.

#### Zola 0.19.1 (rejected general-static-site alternative)

##### Landscape

Zola is an established Rust-written static-site generator, but it is a general site system rather than a book-specific tool.  The official documentation identifies version 0.19.1, CommonMark-based content, `zola init`, `zola build`, and `zola serve`.  Its GitHub figures from `GET https://api.github.com/repos/getzola/zola`, retrieved 2026-09-05, are 17,398 stars, `archived: false`, and `pushed_at: 2026-09-04T08:15:05Z`; `GET https://api.github.com/search/issues?q=repo:getzola/zola+is:issue+is:open` reports 180 open issues.  The crates.io `zola` endpoint returned an obsolete-looking 0.0.0 record with 8 recent and 2,424 all-time downloads and no non-yanked newest version, so it is not valid evidence for the distributed Zola CLI; the version and download figures must not be invented.  RustSec did not return a matching package result for that endpoint, so advisory status is unverified rather than clear.  Issue-responsiveness median is likewise unverified without authenticated maintainer-identity classification.  Sources retrieved 2026-09-05: [Zola overview](https://www.getzola.org/documentation/getting-started/overview/), [GitHub repository endpoint](https://api.github.com/repos/getzola/zola), [GitHub issue-search endpoint](https://api.github.com/search/issues?q=repo%3Agetzola%2Fzola%2Bis%3Aissue%2Bis%3Aopen), [crates.io crate endpoint](https://crates.io/api/v1/crates/zola), and [crates.io versions endpoint](https://crates.io/api/v1/crates/zola/versions).

##### Principles and implementation

Zola turns CommonMark-derived content into a static site using content sections, templates, static assets, and a mandatory `base_url`.  It can serve and check internal anchor links locally.  That can meet documentation capability, but it introduces site layout and templating responsibilities not required by the source-tree pattern.  Sources retrieved 2026-09-05: [Zola overview](https://www.getzola.org/documentation/getting-started/overview/), [Zola directory structure](https://www.getzola.org/documentation/getting-started/directory-structure/), and [Zola configuration](https://www.getzola.org/documentation/getting-started/configuration/).

##### Dominant choice

Do not select Zola for this template.  If a general branded website—not merely documentation—is later needed, assess the official 0.19.1 distribution independently of the stale crates.io package record.  Source retrieved 2026-09-05: [Zola installation](https://www.getzola.org/documentation/getting-started/installation/).

##### Qualified shortlist

Zola is qualified as an architectural alternative because it is active, distributed for macOS and Linux, and documents CommonMark parsing plus a live server.  It is not qualified as a Cargo dependency pin because the queried crates.io package identity does not describe the current CLI release.  Sources retrieved 2026-09-05: [Zola installation](https://www.getzola.org/documentation/getting-started/installation/), [Zola overview](https://www.getzola.org/documentation/getting-started/overview/), and [crates.io versions endpoint](https://crates.io/api/v1/crates/zola/versions).

##### Excluded by gate

Zola is excluded from a pinned Rust-template toolchain choice because this investigation cannot verify its distributed CLI through the required crate endpoint, including dependency-tree MSRV and RustSec package evidence.  It is also excluded by fit because `zola.toml`, templates, and site sections are unnecessary for the selected repository tree.  Sources retrieved 2026-09-05: [crates.io crate endpoint](https://crates.io/api/v1/crates/zola), [Zola directory structure](https://www.getzola.org/documentation/getting-started/directory-structure/), and [Zola configuration](https://www.getzola.org/documentation/getting-started/configuration/).

##### Up-and-comers

No Zola theme or plugin is shortlisted.  A theme would make visual design and its upgrade path a new decision, while R81 is deciding documentation delivery rather than website branding.

##### Fit for this template

Zola would fit a project that needs a custom, static marketing or documentation website.  It is not a good initial fit for a Rust template whose documentation must first be a transparent source tree: Zola requires a `base_url`, content structure, and templates beyond portable Markdown.  This is an inference from Zola's official structure and configuration.  Sources retrieved 2026-09-05: [Zola overview](https://www.getzola.org/documentation/getting-started/overview/) and [Zola configuration](https://www.getzola.org/documentation/getting-started/configuration/).

##### Recommendation

Reject Zola 0.19.1 for R81.  Retain it only as a fresh-research candidate if future requirements explicitly ask for a custom site, not merely generated documentation.

##### Ranked runner-up

No lower-ranked generator is recommended.  `mdBook` ranks above Zola for a future book because it has a direct Rust Project documentation reference and a smaller book-specific configuration model.  Sources retrieved 2026-09-05: [mdBook introduction](https://rust-lang.github.io/mdBook/) and [Zola overview](https://www.getzola.org/documentation/getting-started/overview/).

##### Tradeoffs

Zola provides a `zola serve` live server and can check internal links with anchors, but it introduces templates, static asset directories, configuration, and a base URL.  The official Docker example provides a pinned 0.19.1 image, while source build requires Rust, Cargo, and a C compiler; these are more moving parts than the recommended raw tree.  Sources retrieved 2026-09-05: [Zola overview](https://www.getzola.org/documentation/getting-started/overview/) and [Zola installation](https://www.getzola.org/documentation/getting-started/installation/).

##### Parameters

No R81-owned parameter applies.  The intended tool would need to honor the fixed `target-os-matrix = ubuntu-latest, macos-latest`; Zola's official installation page lists Linux and macOS binaries, but its MSRV/dependency-tree status remains unverified through the required crate endpoint.  Repository source retrieved 2026-09-05: `docs/port/PARAMETERS.md`; external source retrieved 2026-09-05: [Zola installation](https://www.getzola.org/documentation/getting-started/installation/).

##### Migration implications

Selecting Zola later would add `zola.toml`, `content/`, `templates/`, `static/`, and generated `public/` handling, then require a deployment choice.  Do not add those paths to the initial template.  This is a proposed future migration, not an executed change.  Source retrieved 2026-09-05: [Zola directory structure](https://www.getzola.org/documentation/getting-started/directory-structure/).

##### Validation strategy

Planned future acceptance would pin the official distribution, run `zola build` and `zola serve` on Ubuntu and macOS, prove the configured base URL works under the eventual host path, and feed the generated tree to R82's link checks.  None was run because Zola is rejected and its crate identity/MSRV evidence is incomplete.  Sources retrieved 2026-09-05: [Zola installation](https://www.getzola.org/documentation/getting-started/installation/) and [Zola overview](https://www.getzola.org/documentation/getting-started/overview/).

##### Confidence & re-verify trigger

Confidence is high that Zola is not the initial choice and low-to-medium for any future pinned-tool recommendation until the release distribution, MSRV, advisory status, and licensing treatment are reverified from authoritative endpoints.

##### Sources

[Zola overview](https://www.getzola.org/documentation/getting-started/overview/), [Zola installation](https://www.getzola.org/documentation/getting-started/installation/), [GitHub repository endpoint](https://api.github.com/repos/getzola/zola), [GitHub issue-search endpoint](https://api.github.com/search/issues?q=repo%3Agetzola%2Fzola%2Bis%3Aissue%2Bis%3Aopen), and [crates.io endpoint](https://crates.io/api/v1/crates/zola), retrieved 2026-09-05.

### Compatibility

The recommended stack has no crates to compose and no async runtime: it is portable Markdown plus GitHub's renderer.  Its shared compatibility proof is GitHub's documented rule that relative links are transformed for the currently viewed branch, so the `README.md` pointer and `docs/docs.md` navigation use the same repository-relative source files.  This is compatible with Ubuntu and macOS authoring because no platform executable is required; rendering occurs in GitHub.  A generated-site compatibility test is deliberately deferred: `mdBook` is demonstrated by the Rust Project, but no integrated CLI/library/web-service template example was built in this run.  Sources retrieved 2026-09-05: [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) and [mdBook introduction](https://rust-lang.github.io/mdBook/).

### Parameters

This item owns no registered parameter and consumes no research-owned parameter.  It assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions, raised only in a minor release`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest`; the recommendation adds no Rust dependency that can conflict with them.  No `CONFLICT:` line is emitted.  Repository source retrieved 2026-09-05: `docs/port/PARAMETERS.md` rows 7-10.

### Migration implications

For the initial scaffold, create `docs/docs.md` as the canonical navigation page; create the preserved Diataxis directories beneath `docs/`; add `docs/authoring.md`; and add one relative Documentation link in `README.md`.  Keep the landing copy only in `README.md`.  Do not create `book.toml`, `docs/src/SUMMARY.md`, `docs/index.md` as a duplicated landing page, a `docs-dev` recipe, an `init-docs` recipe, generated HTML, or a Pages workflow.  Add an optional F358 note that a future owner decision can evaluate a generator when a stated trigger occurs; do not name Astro Starlight as the planned Rust tool.  These are proposed template changes, not changes made by this report.  Repository sources retrieved 2026-09-05: `docs/port/COMMONALITY.md` F341-F358 and `docs/port/BASELINE-REVIEW.md` F358.

### Validation strategy

Planned initial acceptance, after the template exists: (1) verify `README.md` contains a relative link to `docs/docs.md`; (2) verify `docs/docs.md` has a relative-link entry for each required Diataxis category; (3) verify no shipped `book.toml`, `SUMMARY.md`, generated output directory, or Pages deployment workflow exists; and (4) hand the resulting tree to R82 for internal and external link checking.  The expected result is one source-of-truth landing page and a GitHub-renderable navigation tree with no generator-specific syntax.  These checks were not run because no Rust template source exists and R82 owns the correctness gate.  Sources retrieved 2026-09-05: `inputs/prompt.md` (Out of scope and Couplings) and [GitHub relative links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).

### Confidence & re-verify trigger

Confidence is high for the delivery-model decision and medium for the conditional `mdBook` 0.5.4 fallback because it is version-sensitive.  Re-open R81 before adding a public documentation domain, integrated search, versioned documentation, a large body of tested Rust examples, custom visual branding, or nonportable Markdown extensions; re-query the crates.io, GitHub, RustSec, MSRV, and platform evidence at that point.

### Sources

Repository sources retrieved 2026-09-05: `inputs/prompt.md`, `docs/port/COMMONALITY.md` F341-F358, `docs/port/PARAMETERS.md` rows 7-10, and `docs/port/BASELINE-REVIEW.md` F358.  External authoritative sources retrieved 2026-09-05: [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/), [GitHub Markdown links](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax), [GitHub Pages deployment](https://docs.github.com/en/get-started/start-your-journey/deploying-your-website-automatically), [mdBook documentation](https://rust-lang.github.io/mdBook/), [Zola documentation](https://www.getzola.org/documentation/getting-started/overview/), the mdBook and Zola crates.io/GitHub/RustSec endpoints named above, and [Rust release announcements](https://blog.rust-lang.org/releases/).  Method notes: queried the required crates.io crate and versions endpoints, GitHub repository and issue-search endpoints, RustSec package/advisory pages, and maintainers' documentation using `curl -sS` with a User-Agent on 2026-09-05.  The unauthenticated GitHub data could not establish maintainer identity for the 10-issue response-time median; Zola's crates.io package endpoint did not identify the current distributed CLI; no proposed build or preview command was executed.
