# R49 — build-target-declaration (crate, Deep) — DECISION (revision 4, 2026-09-13)

**What changed in revision 4, and what did not.** Revision 3 (sha256
`85eddc5806c820229f9ad84b82fdc5d9c8e8098c9562105707a6584011794770`) was
**rejected** by `review/audit-codex.md` (actor
`audit-codex-2026-09-05T155504Z-2107cffb3ecf-r3`, model `gpt-5.6-terra`, family
openai) on one unresolved finding: *"false claim that no raw report excluded
`cargo-binstall` on a licence ground"*. **The finding is correct and the false
claim was mine.** The canonical Opus raw report does state a licence ground:
`raw/opus-93a5d89f571b19ea2bc7cdb9ccb956052b1a414c82a9256bb31a0a71454d3059.md:353-356`
reads *"**`cargo-binstall` 1.23.0** — fails **gate 1** *as a dependency*: license
`GPL-3.0-only` … which is not compatible with `MIT OR Apache-2.0` for anything
linked"*. That same report then gives scope as an independent ground at
`:359-362`: *"It is excluded here regardless because the
`[package.metadata.binstall]` table it reads is an artifact-distribution decision
that **R68 owns (F214)**, explicitly out of scope for this item."*

**Why revision 3 got it wrong — the method, not just the sentence.** The search
behind that claim was `grep -rn 'binstall' raw/*.md | head -30`. The glob was
right and did match the Opus file; the `head -30` was not. The true count is
**56** matches across six files, of which the canonical Opus report carries 14
and its `raw/opus.md` alias another 14. The truncation cut the stream inside the
Opus files, leaving visible only their lines 28 and 74 — a landscape-bin row and
an adopter row, neither carrying licence content — which made a partial read look
like a complete one. The figure "28" reported at the time was the truncated
stream's length, not a census. The defect is general and is named here rather
than quietly patched: **a truncated search result was treated as a complete
search result.** The other searches in this revision chain were not truncated
that way. The enumeration greps over `DECISION.md` (`licen`, `gate 1`, copyleft
and licence identifiers, `binstall`) ran with no `head`; the only truncation
applied to them shortened each matched line's displayed text without dropping any
line from the list, so those line lists are complete and re-running them returns
the same lists.

**What revision 4 changes.** Three locations, none of them the recommendation.
(a) The false sentence in the revision-3 note below is corrected **in place**, so
a reader of this decision's own history is not left holding it. (b) The
`cargo-binstall` exclusion under `### Principles and implementation` now records
both licence grounds that existed before the ruling — this decision's and the
Opus raw's — and says which the ruling voids. (c) The `## Engines` entry for
`opus` now records that report's `cargo-binstall` exclusion on both of its
grounds, which revision 3 wrongly said needed no entry.

**What revision 4 does not change.** The recommendation does not move: declare
every build target in `Cargo.toml` itself and add no build backend, bundler or
build-orchestration crate, a pick that is dominant because Cargo's manifest is
the only candidate in the three-bin map that declares a build target at all.
Fitness gate 1 stays `inapplicable` under the owner's 2026-09-12 ruling (Q7.B);
this revision is a decision-history and provenance correction and is **not** a
reinstatement of that gate. `cargo-binstall` remains excluded, on the scope
ground alone — a ground the Opus raw itself called sufficient before any ruling
existed, in the word *"regardless"*. Every `- owns` and `- assumes` line is
byte-identical to revisions 2 and 3. No evidence script, log, figure or empirical
check is altered, and this revision makes no new empirical claim; the audit's own
rerun of `review/evidence/check-lockfile-inclusion.sh` reproduced against
revision 3, and nothing that check exercises is touched here.

**What changed in revision 3, and what did not.** Revision 2 (sha256
`1b5a6b99ecedb88f7358d16a4567aa9b56838a2102e9e4feda99d00bc787513f`) was
**approved** by `review/audit-codex.r2.md` (actor
`audit-codex-2026-09-05T155504Z-2107cffb3ecf-r2`, model `gpt-5.6-terra`) with no
unresolved finding. It is revised here only because the owner ruled on 2026-09-12
(Q4 as superseded by Q7.B) that licence compatibility is not checked for any tool
or dependency this project uses, which strikes fitness gate 1 from every item's
evaluation. **The recommendation does not move.** Nothing in the pick — declare
every build target in `Cargo.toml` itself and add no build backend, bundler or
build-orchestration crate — rested on a licence fact: the pick is dominant
because Cargo's manifest is the only candidate in the three-bin map that declares
a build target at all. What moves is one piece of reasoning. A mechanical search
for `licen`, `gate 1`, copyleft and licence identifiers, and `binstall` produced
the full line list recorded in this revision's commit message; three locations
carried a *licence-as-gate* claim and all three are edited — the gate-1 row under
`### Principles and implementation`, the `cargo-binstall` exclusion in the same
section, and the `## Empirical check` sentence that read gate exclusions off
check 6's table. Gate 1 is recorded as `inapplicable` with the ruling as its
reason and is **not** deleted, because this item's binding prompt still lists it
and the prompt directs that an inapplicable metric be stated with its reason
rather than omitted. The `cargo-binstall` exclusion **survives intact on its
scope ground**, which revision 2 already stated as sufficient on its own ("out of
scope regardless") and which sits in this decision's own voice in
`### Principles and implementation`, not in any quoted provider report: the
`[package.metadata.binstall]` table that crate reads belongs to R68 (F214), which
this item's prompt places out of scope in those words. *[Sentence corrected in
revision 4. This paragraph originally continued: "No raw report excluded
`cargo-binstall` on a licence ground, so no engine position is disturbed and
`## Engines` is unchanged." That was false. The canonical Opus raw does state a
licence ground, at `raw/opus-93a5d89f571b19ea2bc7cdb9ccb956052b1a414c82a9256bb31a0a71454d3059.md:353-356`,
alongside an independent scope ground at `:359-362`; an engine position therefore
was affected, and `## Engines` now records it. See the revision-4 note above for
how the error was made.]* Every `- owns` and `- assumes` line is byte-identical
to revision 2. Besides this paragraph itself, two presentational edits are the
only other changes: the title's revision number, and the removal of bold emphasis from the `GPL-3.0-only` cell in
check 6's table, where the bold marked a gate failure that no longer exists — the
measured value itself is unchanged, being a transcription of
`review/evidence/registry-figures.log`. No evidence script, log or empirical
check was altered, and this revision makes no new empirical claim; the one
execution this revision performed was a rerunnability confirmation —
`review/evidence/check-lockfile-inclusion.sh` was re-run from the run directory
after the revision commit and its output matches
`review/evidence/lockfile-inclusion-conditions.log` line-for-line except the
`retrieved:` timestamp, which is the same variance revision 2's audit recorded. The
repository's own `license` field, its `LICENSE-MIT` + `LICENSE-APACHE` pair and
the `include` allow-list entries naming them are untouched: the ruling covers
dependencies and tools, not this repository's own declared licence.

**What changed in revision 2, and nothing else changed.** Revision 1 (sha256
`b7adf7d8f8ff380cdb25b40ff331d6b83291b2f7ea75a42407684ce2919cbcf9`) was rejected
by `review/audit-codex.r1.md` (actor `audit-codex-2026-09-05T155504Z-2107cffb3ecf-r1`,
model `gpt-5.6-terra`) on one unresolved finding: *"owned parameter overstates
Cargo.lock inclusion as unconditional"*. This revision narrows that claim to the
conditions the toolchain documents and implements. A search for every line
mentioning `Cargo.lock`, a lockfile, or an unconditional-inclusion verb returned
five carrying the claim, and all five are edited: the owned parameter value, the
`## Decision` table row 5, acceptance criterion AC3, and checks A and 4. The
revision adds check L, which establishes the conditions from `rust-lang/cargo` at
the `rust-1.98.0` tag and from the installed `cargo 1.98.0`. Two further edits
were made and are the only other changes to the document: this paragraph and the
title's revision number, and one sentence of the `## Empirical check` preamble,
which said no `cargo package` or `cargo publish` "was run" while checks 8 and L
print those subcommands' `--help` — it now says no such invocation did any
packaging or publishing work, which is what the checks support. Every finding the
audit
confirmed is carried unchanged: the re-measured `dist` responsiveness figures,
the refinement that `[workspace.metadata.dist]` is deprecated but still
supported so a second configuration file is a direction of travel rather than a
present requirement, the narrowed F218 baseline-review line about the packaging
default and the dirty-tree guard, and the recorded medium confidence on the
allow-list choice against a 7:2 practice majority.

## Decision

**Status.** This decision is a **proposal to be validated in the implementation
phase against the real template** (owner ruling, 2026-09-10). P02 is research
only: `rs-launch-blueprint` contains no Rust source tree yet, P03 builds the
template, and P03's CI is what proves these recommendations. What follows records
what the research found, what this run verified against the toolchain and the
registry, and what it could not verify; the unverified parts are listed under
`## Engines` as what P03 must validate. A recommendation that does not survive
implementation is **revised against this recorded research**, not researched
again from scratch. No owner acceptance is claimed or implied.

**Recommendation — declare every build target in `Cargo.toml` itself; add no
build backend, bundler, or build-orchestration crate.** Rust has no pluggable
layer to substitute for py's PEP 517 backend or ts's bundler: Cargo is
simultaneously the build system, the target declarer, the packager and the
publisher, and its declaration surface is the manifest. The correct dependency
value for this item is therefore **absent**, not a crate name and a version
range.

| # | What is declared | Decision | Settles |
|---|---|---|---|
| 1 | Build backend / bundler | **None.** No `[build-dependencies]` entry, no `build.rs`, no `cargo-make`, no `dist`, no `xtask`. Cargo's own manifest is the whole declaration surface. The compatibility contract is expressed as `edition = "2024"` plus `rust-version` in `[package]`, per the fixed `rust-edition` and `msrv-policy` parameters. | **F212** |
| 2 | Library target | Exactly one, declared explicitly as `[lib]`, `path = "src/lib.rs"`, crate name `rs_launch_blueprint` (Cargo's default: the package name with dashes replaced by underscores). This is the crate downstream users depend on, and the crate R01's port trait and R67's `thiserror` error catalog live in. `doctest` is **not** set here — that value is R82's (`docs-correctness-gate`). | **F213** |
| 3 | Binary target | Exactly one, declared explicitly as `[[bin]]`, `path = "src/main.rs"`, `name = "rs-launch-blueprint"` — the same string as the package name. Plus `autobins = false`, so no `src/bin/*.rs` file can become a second published command without a manifest edit. `default-run` stays unset while there is one binary. | **F213**, **F216** |
| 4 | Console-script / bin entry | The `[[bin]]` `name` field, and nothing else. Rust has no entry-point abstraction to declare: `cargo build` emits a native executable whose filename **is** `name`, with no wrapper script to generate and no shebang to preserve. This confirms F217 (`OMIT`) rather than adding to it. | **F216** |
| 5 | Packaged-file scope | An explicit `[package] include` allow-list — `["/src", "/README.md", "/LICENSE-MIT", "/LICENSE-APACHE", "/CHANGELOG.md"]` — reviewed whenever a file that must ship is added. Not `exclude`; the two fields are mutually exclusive. `Cargo.toml` and any `license-file` are included by Cargo whatever `include` or `exclude` says. A minimized `Cargo.lock` is outside that selection too — `cargo package` adds it, generating one when none is on disk — but it is not unconditional: `cargo package --exclude-lockfile` omits it, and `cargo publish` has no such flag. Stated in full in `## Empirical check`, check L. | **F218** |
| 6 | Distribution name vs. binary name | **They match.** `cargo install rs-launch-blueprint` installs the command `rs-launch-blueprint`; no `uvx --from` analogue and no `--bin` flag is needed. Divergence is idiomatic in Rust and costs no install-time flag, so a fork that wants a short command changes one `name =` line. | **F219** |

**Ledger rows settled** (the verdict strings remain the controller's to set, per
`docs/port/README.md`): **F212** — substituted by the Cargo toolchain itself,
with no crates.io dependency; **F213** — `[lib]` + one `[[bin]]`, the Rust
analogue of ts's two-entry `entry: ['src/cli.ts', 'src/lib.ts']`; **F216** — the
`[[bin]]` `name` field; **F218** — an explicit `include` allow-list; **F219** —
no divergence in the template as shipped.

**Coupling boundaries respected, and what is deliberately not decided here.**
This item decides the manifest-level declaration of build targets and entry
points. It does **not** decide which distributable artifact types ship beyond the
`.crate` that `cargo publish` produces — **R68 owns F214** — and it does **not**
decide how a built artifact is install-and-run smoke tested — **R50 owns
F221/F222**. It also does not decide whether CI asserts the packaged file list;
that is R26's (F039/F078). The `[[bin]]`/`[lib]` names fixed above are the input
R68's release matrix and R32's built-binary test tier consume, and the target
directory layout in `## Parameters` is the input R22's version accessor reads.

**The optional web surface adds no target here.** F017 is already `ADOPT` in the
ledger — *"Web service as an optional, separately installed capability … direct
Cargo-optional-feature analogue of py's optional-dependencies extra; nothing to
choose"* (`docs/port/COMMONALITY.md:23`) — so feature-gating is settled upstream
of this item. What is **not** settled is whether that feature also brings a
second executable, and **that is R69's** (`web-extra-surface`, unresolved). This
decision declares one `[[bin]]` today and is shape-neutral either way: if R69
chooses a separate server process, the manifest gains one `[[bin]]` block plus a
`default-run` line and nothing else in this decision moves. One verified fact is
handed to R69 and R32 as input rather than used to pre-empt R69: a `[[bin]]`
carrying `required-features` is **skipped when those features are off**, and
`CARGO_BIN_EXE_<name>` is then not set for integration tests (check 3 below), so
a second feature-gated binary needs feature-aware test wiring.

**Two BASELINE-REVIEW findings are carried through, not resolved.** Neither the
ledger, the index, the prompt nor the registry has been edited by this decision.

BASELINE-REVIEW: F212 — principle: the build backend/bundler is a *selectable third-party tool*, which is what makes R49 an item of kind `crate` in `research/CLAUDE.md` and makes the prompt's crate figure table (90-day downloads, last release, advisories, adopters) the required evidence — proposed change: reclassify R49's item kind from `crate` to `pattern`, or to an explicit `crate (first-party toolchain, zero added dependencies)` sub-kind, and record F212's substitute as "the Cargo toolchain, no crates.io dependency", so downstream items and the `check-research-tree.sh` gate do not expect a version range for a crate that does not exist — evidence: (a) the Cargo Book documents `[lib]`/`[[bin]]`/`include`/`exclude` as manifest fields of the toolchain itself, with no pluggable backend interface analogous to PEP 517 (`src/doc/src/reference/cargo-targets.md` and `src/doc/src/reference/manifest.md` at the `rust-1.98.0` tag of `rust-lang/cargo`, read 2026-09-10, log `evidence/cargo-docs-1.98.log`); (b) the ledger row already anticipates it — "Cargo is Rust's native build system with no separate backend/bundler crate needed" (`docs/port/COMMONALITY.md:216`); (c) every crate figure this prompt requires is `inapplicable` to the recommended answer, as recorded under `### Principles and implementation`; affected items: R49 (this item), and informationally R68 and R50, whose prompts describe R49 as declaring build targets — neither statement changes. Raised by `raw/opus-93a5d89f571b19ea2bc7cdb9ccb956052b1a414c82a9256bb31a0a71454d3059.md`; carried here unresolved, per the prompt's instruction to report a challenged baseline rather than change it.

BASELINE-REVIEW: F218 — principle: the set of files that reaches the consumer is bounded by a declaration, not by whatever is in the working tree — proposed change: replace the row's parenthetical premise "(default: git-tracked files only)" with Cargo's actual default rule and with the explicit `include` allow-list this decision selects — evidence: the manifest reference at the `rust-1.98.0` tag states *"The default if neither field is specified is to include all files from the root of the package, except for the exclusions listed below"*, and the only listed exclusions are hidden dotfiles when the package is **not** in a git repository, gitignored files when it **is**, sub-packages, and a root `target` directory (`src/doc/src/reference/manifest.md:391-411` at that tag, read 2026-09-10, log `evidence/cargo-docs-1.98.log`). A file that is untracked but not gitignored therefore falls **inside** the default packaged set, which "git-tracked files only" says it does not. The practical exposure is narrower than that gap sounds, and this decision states it at that width: `cargo package` refuses a dirty working tree unless `--allow-dirty` is passed, and its dirty walk is configured with `emit_untracked(EmissionMode::Matching)`, so an untracked packaged source file makes the tree dirty and packaging stops (`src/cargo/ops/cargo_package/vcs.rs` at the same tag, checks A and H). What the dirty guard does **not** catch is a *committed* directory nobody meant to publish — `.github/`, `docs/`, `research/` — which under the default or under an `exclude` deny-list ships to every crates.io consumer. Affected items: R49 (this item, which sets the value) and R26 (`packed-artifact-content-guard`, F039/F078), which owns whether CI asserts the resulting file list. Raised by `raw/codex-cd14ccfbbefdabb73358b9b75dd288f863c9984100d6d5e3d21f796e3c37f183.md`; carried here unresolved.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** F211 (`docs/port/COMMONALITY.md:215`, `COMMON → REUSE`) is the
tool-free pattern: the project's build system turns source into a distributable
package whose contents are declared, not incidental. F212 (line 216,
`COMMON → SUBSTITUTE`, owned by this item) is the tool row under it. Read at
their pins, the two source repos agree on four behaviors and differ on the
mechanism of each. Agreement is required at the **capability and policy** level,
not at the level of sharing a backend library.

| # | Behavior that must agree | py evidence (pin `b08bccfb`) | ts evidence (pin `cb1cbcb2`) | Level | Rust realization |
|---|---|---|---|---|---|
| B1 | One manifest declares every produced artifact; no second, out-of-band build description | `pyproject.toml:131-133` `[build-system] requires = ["uv_build>=0.5,<1.0"]`, `build-backend = "uv_build"`, plus `[tool.uv.build-backend]` at `:138-141` — one file | `package.json` **plus** `tsdown.config.ts` — two files, a known cost of the JS ecosystem | capability | `Cargo.toml` alone |
| B2 | The consumable library and the executable are declared as separate, named outputs | `pyproject.toml:139` `module-name = "py_launch_blueprint"`, `:141` `module-root = "src"` — one package root, the whole package is one build unit | `tsdown.config.ts:9` `entry: ['src/cli.ts', 'src/lib.ts']` — two explicit entries | architectural pattern | `[lib]` + `[[bin]]` |
| B3 | The executable's name is declared explicitly, independently of the distribution name | `pyproject.toml:120` `plbp = "py_launch_blueprint.cli.main:cli"` — a `module:function` callable reference | `package.json:17-19` `"bin": {"ts-projects": "dist/cli.js"}` — a built-file path | policy | the `[[bin]]` `name` field |
| B4 | The file set that reaches the consumer is bounded by a declaration, not by the working tree | `:139`/`:141` bound wheel content implicitly through the package root | `package.json:20-22` `"files": ["dist"]` — an explicit allow-list | policy | `[package] include` |
| — | **May vary** | allow-list vs deny-list; callable reference vs file path; one process or two | | — | |

All four lines above were read through the programme pins with
`git -C ~/c/py-launch-blueprint show b08bccfb…:<path>` and
`git -C ~/c/ts-launch-blueprint show cb1cbcb2…:<path>`, never from a working
tree (check 5; log `evidence/source-pins.log`).

**Does the pattern remain appropriate in Rust? B1, B2 and B4 do, unchanged. B3
survives but its mechanism collapses.** In py, `[project.scripts]` exists because
a wheel contains no executable: the backend must generate a wrapper script from a
callable reference at install time. In ts, `bin` exists because npm must symlink
a built file and the shebang must survive bundling. In Rust neither indirection
exists — the `[[bin]]` `name` field is the output filename, verified against the
target reference: *"The `name` field specifies the name of the target, which
corresponds to the filename of the artifact that will be generated"*, and *"For
`src/main.rs`, the default binary name is the package name"* (check 2). That is
why F217 (`OMIT`) is correct and why no third-party tool is needed to close the
gap: there is no gap.

**Landscape — the three-bin map, and why only one bin contains a candidate.**
*Built-in / first-party toolchain:* Cargo's manifest target tables (`[lib]`,
`[[bin]]`, `[[example]]`, `[[test]]`, `[[bench]]` with `name`, `path`,
`required-features`, `doc`, `test`, `crate-type`), `[package]`
`include`/`exclude`/`default-run`/`autobins`/`rust-version`, `cargo package` /
`cargo publish`, `build.rs`, and Cargo features. *Established third-party tools
that orchestrate around Cargo:* `dist` (crate `cargo-dist`), `cargo-make`,
`cross`, `cargo-zigbuild`, `cargo-binstall`, `cbindgen`, `maturin`, `wasm-pack`,
the `cargo-xtask` pattern. *Up-and-comer:* `cargo-packager`, `rules_rust` and
Buck2 as whole-build-system replacements. **Only the first bin contains a
candidate that declares a build target at all.** Every tool in the other two bins
*reads* `[[bin]]`/`[lib]` to produce something else, which is why this is a
dominant choice in the strict sense rather than a close comparison.

**Every crate figure this prompt requires is `inapplicable` to the
recommendation, and each is stated rather than omitted.** 90-day downloads,
all-time downloads, last release, adopters-by-reverse-dependency and the RustSec
page are all crates.io concepts; Cargo ships in the toolchain and is never listed
under `[dependencies]`, so `crate.recent_downloads` and its siblings have no
value to report, and `https://rustsec.org/packages/cargo.html` addresses a crate
this template does not consume. Stars and repository state do exist for
`rust-lang/cargo` (15,462 stars, `archived: false`, `pushed_at`
2026-09-08T15:46:17Z, recorded by `raw/opus…`, 2026-09-10) and maintenance is
`active` on the six-week stable train. This inapplicability is **by construction,
not by omission** — it is the substance of the F212 baseline-review line above.

**The six fitness gates, answered for the recommendation before any popularity
figure was weighed.** (1) *License* — `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`.
The row is stated rather than omitted because this item's binding prompt still lists
the gate and directs that an inapplicable metric carry its reason. The underlying
fact is unchanged and is kept here as a fact rather than as a gate verdict: this
recommendation adds no dependency, so nothing enters the tree's license set at
all. (2) *MSRV* — pass; Cargo is the toolchain,
not a dependency, and has no `rust-version` to test against the policy. The
manifest fields recommended here impose no floor above `edition = "2024"`, which
requires Rust 1.85.0 or newer. (3) *RustSec and `unsafe`* — pass; declaring
targets introduces no code, so the template's `unsafe` posture is entirely R06's
to set. (4) *`ubuntu-latest, macos-latest`* — pass; `cargo build`, `cargo package`
and `cargo publish --dry-run` are the same commands on both, with the single
difference that a Windows binary carries `.exe` (noted, not required). (5)
*Default features and async-runtime coupling* — `inapplicable`; manifest fields
have neither. The template's own `[features]` table is a separate matter whose
async coupling belongs to R69 and R05. (6) *Binary size and compile time* — zero
added bytes and zero added compile time; the declaration is metadata. The one
cost this item introduces is `cargo package`'s verification rebuild, documented
as step 3, *"This will rebuild your package from scratch to ensure that it can be
built from a pristine state"* (check 4) — one clean build, which is why it
belongs in a release lane and not in the default check loop. **No latency,
throughput, binary-size or compile-time figure is given anywhere in this
decision**, because no Rust source exists in this repository to measure; that is
recorded as an evidence gap, not filled with an invented number.

**Candidates excluded, and on what.** `cargo-make` **fails gate 2**: its newest
non-yanked release 0.37.24 (2025-01-18) declares **no `rust_version` at all**
(check 6, re-measured this run), and the fixed policy requires a declared,
CI-tested floor. `cargo-binstall` is **excluded by scope, and by scope alone**:
the `[package.metadata.binstall]` table it reads is R68's (F214), which this
item's own prompt places out of scope in those words — *"crates.io-only vs.
`cargo-dist` cross-compiled GitHub Release binaries vs. `cargo-binstall`
metadata; R68 (`release-binary-artifacts`) owns F214"* (`inputs/prompt.md`,
`## Out of scope`). Gate 1 is `inapplicable` to it for the reason given above, so
no licence ground is carried forward. **Two licence grounds existed before the
ruling; the ruling voids both, and in each case the scope ground it does not
touch was already stated as sufficient on its own.** The first was this
decision's own: revisions 1 and 2 wrote *"fails gate 1 as a dependency"* with the
registry value `GPL-3.0-only` immediately beside the clause *"out of scope
regardless"* — that clause byte-identical in revision 1 (sha256
`b7adf7d8f8ff380cdb25b40ff331d6b83291b2f7ea75a42407684ce2919cbcf9`) and revision
2 — and revision 3 removed the gate-1 half. The second was the Opus raw's, at
`raw/opus-93a5d89f571b19ea2bc7cdb9ccb956052b1a414c82a9256bb31a0a71454d3059.md:353-356`,
which likewise paired it with an independent scope ground at `:359-362`: *"It is
excluded here regardless because the `[package.metadata.binstall]` table it reads
is an artifact-distribution decision that **R68 owns (F214)**, explicitly out of
scope for this item."* That report is recorded as it stands and is not rewritten;
what the ruling changes is that this decision no longer carries its gate-1 half
forward. Its registry `license` value is still recorded in check 6 as measured
metadata.
`cross` **fails gate 4**: it runs the build inside Docker or Podman, which the
GitHub-hosted macOS image does not ship (measured by `raw/opus…` against the
`actions/runner-images` manifests, 2026-09-10). `cargo-zigbuild`, `cbindgen`,
`maturin`, `wasm-pack`, `cargo-packager` and `rules_rust` are excluded **by
scope, not by a gate**: they are cross-compilation linkers, other ecosystems'
build backends, or release/desktop bundlers. One of those exclusions answers a
prompt question directly: `cbindgen` is the closest thing Rust has to ts's
`dts: true`, but it emits **C headers for an FFI surface**, whereas this template
exposes a Rust library to Rust consumers whose type information already travels
in the `.rlib` metadata and is rendered by `cargo doc`. **The `dts`-equivalent
question has no candidate in Rust because it has no referent in Rust.**

**Architectural alternatives compared before libraries.** *A1 — single package,
one binary, web behind a Cargo feature.* Maintained reference implementation:
**mdBook** (22,127 stars; `rust-lang/mdBook/Cargo.toml`, read 2026-09-10) — a
CLI, a consumable library and an axum HTTP server in one package, the server
gated by a `serve` feature and reached through an `mdbook serve` subcommand.
*A2 — single package, two binaries, the second carrying `required-features`.*
Legitimate and is what `required-features` exists for; its documented cost is the
skip behavior verified in check 3. *A3 — workspace split into `-core`, `-cli`,
`-server`.* Reference implementations: **atuin** (31,579 stars) and **typos**
(4,125 stars, `default-members = ["crates/typos-cli"]`). Its cost here is that it
pre-empts **R02** (`crate-boundary-enforcement`), which owns the workspace-shape
question and is still open. *A4 — Cargo plus an orchestration layer* (`dist`,
`cargo-xtask`). Its cost is a maintained third-party dependency for a decision
(F214) that belongs to R68, and — for `dist` specifically — a pull toward a
second configuration file, stated at the width check 10 supports: `dist`'s own
book at v0.32.0 marks the in-`Cargo.toml` `[workspace.metadata.dist]` form
*"(deprecated in 0.23.0)"* and initializes new Rust projects into
`dist-workspace.toml`, while still reading the in-manifest form, so adopting
`dist` today does not force a second file but is documented as moving away from
the one-file declaration that behavior B1 names. **A1 is selected**, and the selection is shape-neutral: if R02 chooses
a workspace, every field above moves to the member manifests unchanged, exactly
as `typos` and `atuin` do it.

**Why `include` rather than `exclude`, stated with the practice evidence that
runs the other way.** An independent sweep of nine well-regarded manifests this
run (check 7; log `evidence/practice-manifests.log`) measured **7 of 9 using
`exclude`** — ripgrep, bat, just, mdBook, wasmtime-cli, fd-find, atuin — against
**2 of 9 using `include`** — helix-term, and typos-cli through
`include.workspace = true` inherited from the `crate-ci/typos` workspace root.
That majority is real and this decision goes against it, so the reason has to
carry the weight rather than the count. Three things decide it. First, **B4
fidelity**: an allow-list is the literal expression of the shared behavior both
sources encode, and ts's `files: ["dist"]` is an allow-list. Second, **the
repository shapes differ**: the seven `exclude` users are applications whose
packages carry large asset trees they prune (bat's syntaxes, atuin's vendored
submodule, mdBook's guide, just's book); this template's shape is the opposite —
a small source tree inside a repository carrying `.github/`, `docs/`,
`research/`, a `justfile` and CI, none of which ships, and that non-shipping list
will grow with every P03 addition while the shipping list will not. Third, a
deny-list **fails open on exactly the direction that matters here**: under
`exclude` (or under Cargo's default) a committed directory nobody thought to name
is published to every crates.io consumer, which is the F218 finding above.
**The failure mode this choice accepts, named plainly:** an allow-list fails
closed on a fork's new directory — a fork that adds `assets/` and does not extend
`include` ships a `.crate` without it. That failure is loud for anything the
build needs, because `cargo package`'s step-3 verification rebuild fails if
`include` omitted a compile-time input (check 4), and silent only for files read
at *runtime*, of which a source-only template has none. One further verified
property is recorded because it is a genuine footgun of the field chosen:
*"If `include` is specified, gitignore rules of the repository and global git
configuration are not applied"* (check A), so an `include` pattern that reaches
into a gitignored path would ship it. The patterns recommended here (`/src`,
`/README.md`, the two license files, `/CHANGELOG.md`) do not. **Confidence on
this sub-decision is medium**, and it is cheap to reverse: it is one manifest
field, and R26 (F039/F078) owns the CI guard that would catch a wrong value
either way.

**Why the names match, and what that claim does and does not assert.** The
divergence py needs — `uvx --from py-launch-blueprint plbp`, annotated in py's
own README at pin `b08bccfb` as needed *"because the distribution name differs
from the console-script name"* (check 5) — **has no Rust analogue**:
`cargo install`'s `--bins` option is documented *"Install all binaries. This is
the default behavior"*, and the installed cargo 1.98.0 prints the same
(check 8). So `cargo install <package>` installs the package's binaries whatever
they are named, and `--bin` selects a *subset* rather than resolving a name
divergence. **Divergence is therefore free in Rust and common** — 5 of the 9
manifests swept diverge (`ripgrep`/`rg`, `wasmtime-cli`/`wasmtime`,
`typos-cli`/`typos`, `fd-find`/`fd`, `helix-term`/`hx`). This decision still
makes them match, for a reason that is about templates rather than about Cargo:
`rs-launch-blueprint` is a placeholder every fork replaces, the five divergent
projects diverge because a short *product* name was already established or taken,
and a matching pair is the value that needs no owner naming call to publish.
`raw/opus…` proposes `rslbp` and Doxa's Gemini provider proposes `rsbp`; **both
label the string as a naming proposal rather than a research finding**, and this
decision does not adopt either. **The name remains owner-reviewable**: changing
it is one `name =` line plus one README sentence, and if R68 later adopts
`cargo-binstall` metadata a divergent pair additionally requires the `bin-dir`
template to interpolate `{ bin }` rather than `{ name }`.

**Why `autobins = false`, at the strength the evidence supports.** Cargo's own
reference says *"Disabling automatic discovery should only be needed for
specialized situations"* and illustrates it with a library that wants a module
named `bin` (check 2). This template's specialized situation is different and is
stated as a **policy choice rather than as documented advice**: an unreviewed
`src/bin/*.rs` file would otherwise become a second *published, installed
command*, which is precisely the artifact this item exists to declare, and
`cargo install` installs all binaries by default (check 8). The same argument
does **not** extend to `build = false`, which Doxa's OpenAI provider proposes: an
accidental `build.rs` changes compile-time behavior but adds no shipped
executable, so the manifest is not asked to carry metadata disabling a thing that
does not exist. `default-run` is declined on the same ground — with one binary it
is dead metadata, and it is added in the same commit as any second `[[bin]]`,
never before.

**Minimal realistic example.** One package. `src/lib.rs` is the library target's
root and hosts the R01 port trait, the R67 error catalog, and — when R69 says so
— a feature-gated `web` module. `src/main.rs` is the binary target's root:
argument parsing, the composition root, and `fn main() -> ExitCode` per R67's
resolved `error-taxonomy-exit-codes`, which already presumes this library/binary
split (*"`thiserror` in the library crate, `anyhow` … in binary crates only"*).
`Cargo.toml` carries `[package]` (with the crates.io metadata `cargo publish`
requires), `include`, `[lib]`, one `[[bin]]`, and `[features]`. **This example was
not built.** Building it is P03's job.

**Observable acceptance criteria.** Each is machine-checkable against the
finished template, and **none was executed here** — there is no Rust source tree
to run them against, and this run did not create one.

- AC1 — `cargo metadata --no-deps --format-version 1` reports exactly one target
  of kind `lib` and exactly one of kind `bin`, and the bin's `name` equals the
  value recorded in `build-tool-output-shape`.
- AC2 — `cargo build --release` produces `target/release/rs-launch-blueprint`.
- AC3 — `cargo package --list`, invoked with no `--exclude-lockfile` (check L —
  that flag is the one thing that drops the lockfile, and neither this check nor
  the release lane passes it), prints `Cargo.toml`, `Cargo.lock`, `src/**`,
  `README.md` and the two license files, **and** prints no path under `.github/`,
  `docs/` or `research/`. Written as two assertions because a positive-only check
  passes trivially.
- AC4 — `cargo publish --dry-run` exits 0, which runs the step-3 verification
  build and so fails if `include` omitted anything the build needs.
- AC5 — with the web feature off and on, the produced binary set is unchanged in
  count, so R68's artifact list does not change shape with the feature flag.
- AC6 — an integration test resolves the executable through
  `env!("CARGO_BIN_EXE_rs-launch-blueprint")` with no non-default feature enabled.

Where AC3 and AC4 are wired is **R26's and R11's**, not this item's; AC4 is a
full clean rebuild and belongs in a release lane.

**Re-verify triggers, any of which fires before the date below.** R69 resolves to
a separate server process, which adds a second `[[bin]]` and a `default-run` line
to the owned parameter; R02 resolves to a workspace, which moves these fields to
member manifests under `[workspace.package]` inheritance; R68 resolves F214 to
cross-compiled release binaries, which is the condition under which the runner-up
wins and which requires re-checking whether `dist`'s `[workspace.metadata.dist]`
deprecation has become a removal at the version R68 would adopt; a Rust edition
beyond 2024 is adopted, since edition changes have altered `Cargo.toml` semantics
before; or the owner rules on the binary name.

re-verify: 2027-03-10, or any earlier event listed immediately above

## Parameters

- owns build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rs-launch-blueprint, matching the package name, so cargo install rs-launch-blueprint installs the command rs-launch-blueprint and integration tests resolve it through CARGO_BIN_EXE_rs-launch-blueprint; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- No `CONFLICT:` line. This item's `- consumes:` line in the prompt is empty, no raw report raised a conflict, and nothing in this recommendation requires a registered parameter value to change.

**Format note.** The five lines above carry a value and nothing else — no
backticks, no citation, no commentary — because the packaging validator reads
everything after `= ` as the value and compares it byte-for-byte with
`docs/port/PARAMETERS.md`, and the owned value is additionally written into that
registry's table cell. Three earlier items in this programme each cost a full
audit round to exactly that mistake. Everything those lines would otherwise have
said is in prose here.

**How each fixed parameter bears on this decision.** `rust-edition` is
load-bearing rather than incidental: the 2024 edition implies `resolver = "3"`,
Cargo's Rust-version-aware dependency resolver, which does more for the MSRV
policy than any third-party tool in this category could, and it is the edition
whose stabilization sets the floor at Rust 1.85.0 or newer. `msrv-policy` is
declared by the `rust-version` field this item places in `[package]`; on this
host today, with stable at `rustc 1.98.0`, "stable minus 2 minor versions"
computes to **1.96** — stated as a computed value at a date, not baked into the
owned parameter, because it moves every six weeks and the policy, not the number,
is what is fixed. `license` becomes the `[package] license` field and, through
the Rust API Guidelines' C-PERMISSIVE convention already recorded on F206, the
root `LICENSE-MIT` + `LICENSE-APACHE` pair that the `include` allow-list names.
`target-os-matrix` is satisfied because every command named in this decision is
the same command on both runners.

**Consuming items get concrete values from the owned parameter above.** R22
(`runtime-version-accessor`) reads `env!("CARGO_PKG_VERSION")`; R32's
built-binary tier resolves the executable through
`env!("CARGO_BIN_EXE_rs-launch-blueprint")` rather than hardcoding a path or a
profile; R68's release matrix uploads the filename
`target/release/rs-launch-blueprint`.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; rustup's active toolchain
`stable-aarch64-apple-darwin`; `Darwin 25.4.0 arm64`, macOS 26.4 (25E246).
Recorded 2026-09-10T15:24:28Z; log `review/evidence/toolchain.log`. **Every
retrieval timestamp in this decision and in every evidence log is UTC.**

**Working directory.** All checks ran read-only from the repository root
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`, except the two `git show`
reads in check 5, which address the pinned source repositories through
`git -C ~/c/py-launch-blueprint` and `git -C ~/c/ts-launch-blueprint` and touch
no working tree. **Nothing was scaffolded, built or published**: no `Cargo.toml`
was written, no crate was created, and no `cargo build`, `cargo package` or
`cargo publish` did any work — the only invocations of those subcommands were
`--help` printings in checks 8 and L, and no dry run of any kind was
performed. The checks read the toolchain's own documentation and
source at the tag matching the installed toolchain, printed the installed
`cargo`'s effective help, and queried the registry and the GitHub API.

**Check 1 — the toolchain reference at the tag matching the installed cargo.**
`gh api "repos/rust-lang/cargo/contents/src/doc/src/<page>?ref=rust-1.98.0"` for
`reference/manifest.md`, `reference/cargo-targets.md`,
`reference/environment-variables.md`, `reference/build-cache.md`,
`commands/cargo-package.md` and `commands/cargo-install.md`. All six fetched;
byte counts and SHA-256 digests recorded. Exit status 0.
Log `review/evidence/cargo-docs-1.98.log`. **The source at a tag was read in
preference to the published page** so that every quotation below is the text
shipped with the installed `cargo 1.98.0` rather than whatever the live site
serves; the published equivalents, all retrieved 2026-09-10, are
<https://doc.rust-lang.org/cargo/reference/manifest.html>,
<https://doc.rust-lang.org/cargo/reference/cargo-targets.html>,
<https://doc.rust-lang.org/cargo/reference/environment-variables.html>,
<https://doc.rust-lang.org/cargo/reference/build-cache.html>,
<https://doc.rust-lang.org/cargo/commands/cargo-package.html> and
<https://doc.rust-lang.org/cargo/commands/cargo-install.html>. The other
documentation this decision relies on, carried over from the raw reports with
their retrieval dates: the Rust Edition Guide's 2024 chapter for the
`resolver = "3"` implication (<https://doc.rust-lang.org/edition-guide/print.html>,
2026-09-10) and the Rust 1.85.0 release announcement for the edition's
stabilization (<https://blog.rust-lang.org/2025/02/20/Rust-1.85.0/>, 2026-09-10),
both from `raw/opus…`; `dist`'s own book
(<https://axodotdev.github.io/cargo-dist/book/workspaces/structure.html>,
2026-09-10, `raw/opus…`), read here at the `v0.32.0` tag instead (check 10);
`cargo-xtask`'s README, whose own words are *"not an officially recommended
workflow"* (<https://raw.githubusercontent.com/matklad/cargo-xtask/master/README.md>,
2026-09-10, `raw/opus…`); and the manifests of the nine surveyed projects at
`https://github.com/<owner>/<repo>/blob/<default-branch>/Cargo.toml`, fetched
through the contents API in check 7, 2026-09-10.

**Check A (packaged-file default, the F218 finding).** `manifest.md:391-411` at
that tag: *"The default if neither field is specified is to include all files
from the root of the package, except for the exclusions listed below"*; the
exclusions are hidden dotfiles when **not** in a git repository, gitignored files
when in one, sub-packages, and a root `target` directory. Also verified there:
*"If `include` is specified, gitignore rules of the repository and global git
configuration are not applied"*; *"The options are mutually exclusive; setting
`include` will override an `exclude`"*; and, under the heading *"The
following files are always included"*, that `Cargo.toml` and any `license-file`
are always included and that *"A minimized `Cargo.lock` is automatically
included"* — a sentence that speaks only to `include`/`exclude` selection, and
whose command-line limit is check L. **Observed outcome:** the
ledger's "(default: git-tracked files only)" is not what the toolchain
documents — an untracked, non-ignored file is inside the default set.

**Check H (how far that gap actually reaches).**
`src/cargo/ops/cargo_package/vcs.rs` at the same tag: `check_repo_state` bails
with *"N files in the working directory contain changes that were not yet
committed into git … pass the `--allow-dirty` flag"*, and its dirty walk is
configured `emit_untracked(gix::dir::walk::EmissionMode::Matching)`.
**Observed outcome:** the untracked-file path is guarded at package time by the
dirty refusal; the unguarded path is a *committed* directory nobody excluded.
Both statements appear in the F218 baseline-review line at exactly that width.

**Check 2 — target names, paths and auto-discovery.** `cargo-targets.md` at the
tag. **Observed:** *"The filename defaults to `src/lib.rs`, and the name of the
library defaults to the name of the package, with any dashes replaced with
underscores. A package can have only one library."*; *"For `src/main.rs`, the
default binary name is the package name."*; *"The `name` field specifies the name
of the target, which corresponds to the filename of the artifact that will be
generated."*; and, on auto-discovery, *"Setting the keys `autolib`, `autobins`,
`autoexamples`, `autotests`, or `autobenches` to `false` in the `[package]`
section will disable auto-discovery"*, with the caveat *"Disabling automatic
discovery should only be needed for specialized situations."*

**Check 3 — the `required-features` skip, the fact handed to R69 and R32.**
`cargo-targets.md`: *"The `required-features` field specifies which features the
target needs in order to be built. If any of the required features are not
enabled, the target will be skipped."* `environment-variables.md`:
*"`CARGO_BIN_EXE_<name>` — The absolute path to a binary target's executable.
This is only set when building an integration test or benchmark. … Binaries are
automatically built when the test is built, unless the binary has required
features that are not enabled."* **Observed outcome:** a second feature-gated
binary disappears from the default test build; this is recorded as R69's and
R32's input, not used to decide R69.

**Check 4 — `cargo package`'s steps and its verification rebuild.**
`cargo-package.md` at the tag, step 3: *"Extract the `.crate` file and build it to
verify it can build. This will rebuild your package from scratch to ensure that
it can be built from a pristine state. The `--no-verify` flag can be used to skip
this step."* Also verified, in that page's step 2: *"`Cargo.lock` is always
included. When missing, a new lock file will be generated unless the
`--exclude-lockfile` flag is used."* — quoted with its second sentence, which is
the condition; `--list` prints the file list without making a package; and
`--allow-dirty` exists to override the dirty-tree refusal.

**Check L — the conditions on lockfile inclusion, stated once in full here.**
Script `review/evidence/check-lockfile-inclusion.sh`, log
`review/evidence/lockfile-inclusion-conditions.log`, run from the repository
root; 13 content assertions, `RESULT all assertions passed`, exit status 0. It
reads documentation and source at the `rust-1.98.0` tag and prints the installed
`cargo 1.98.0`'s own help; it scaffolds, builds and publishes nothing, and does
no packaging or publishing work — the only `cargo package`/`cargo publish`
invocations are `--help` printings, and no dry run was performed. **Observed:**

1. *Automatic with respect to the manifest.* `reference/manifest.md` lists *"A
   minimized `Cargo.lock` is automatically included"* under *"The following files
   are always included"*, a list the page itself scopes to *"Regardless of
   whether `exclude` or `include` is specified"*. So no `include` allow-list and
   no `exclude` deny-list can drop it — which is the claim this decision needs,
   since the allow-list is what it selects.
2. *Not unconditional at the command line.* `commands/cargo-package.md` documents
   `--exclude-lockfile` as *"Don't include the lock file when packaging"*, adding
   *"This flag is not for general use."*; the installed cargo prints
   `--exclude-lockfile         Don't include the lock file when packaging` in
   `cargo package --help`, with no `-Z` gate, so the override is stable and
   available in 1.98.0.
3. *Where the condition lives in the source.*
   `src/bin/cargo/commands/package.rs:89` sets
   `include_lockfile: !args.flag("exclude-lockfile")`;
   `src/cargo/ops/cargo_package/mod.rs:513` drops any on-disk `Cargo.lock` from
   the source file list (`"Cargo.lock" => continue`) and `:559` re-adds it as a
   generated archive entry only `if include_lockfile`.
4. *An absent lockfile is generated, not omitted.* Same block, `:561`:
   `let lockfile_path = lockfile_path.exists().then_some(lockfile_path);` — the
   entry is added either way and `build_lock` produces the contents.
5. *The publish path has no override.*
   `src/cargo/ops/registry/publish.rs:171` constructs `PackageOpts` with
   `include_lockfile: true` hardcoded, and the installed `cargo publish --help`
   prints no line containing `exclude-lockfile` (0 matching lines, asserted as an
   absence).
6. *That override is the only one — checked exhaustively, not by sampling.* The
   word "only" is an exhaustive claim, so the script downloads the whole tag
   tarball (`gh api repos/rust-lang/cargo/tarball/rust-1.98.0`) and searches
   every `.rs` file in it. `include_lockfile` appears in exactly three files —
   `src/cargo/ops/cargo_package/mod.rs` (the `PackageOpts` field at `:85`, the
   `build_ar_list` parameter at `:502`, and three reads at `:263`, `:281`,
   `:492`), `src/bin/cargo/commands/package.rs` and
   `src/cargo/ops/registry/publish.rs` — and it is *assigned* in exactly two
   places, `commands/package.rs:89` and `ops/registry/publish.rs:171`, the two
   quoted above. Both the file set and the assignment-site set are asserted as
   exact string equality, so a fourth file or a third assignment fails the check.

**Observed outcome:** the correct width is *automatic under manifest selection,
generated when absent, and omitted only by `cargo package --exclude-lockfile`* —
not "included regardless", which revision 1's owned value and four supporting
lines asserted. The owned parameter now carries that qualification in full; the
`## Decision` table row, AC3 and check 4 carry it by reference to this check.
**Reproducibility:** the script was re-run against the cited log immediately
before this sentence was written; the two outputs differ on exactly one line, the
`retrieved:` timestamp in the header, every other byte identical. The two
documentation pages are addressed by tag *and* by recorded SHA-256, so they
cannot drift under a re-run without the digest assertion failing; the four source
files and the tarball are addressed by tag and their digests or derived line
lists are printed into the log, so drift would show as a log diff. **Three
negative controls were run**, each on a copy of the script: an asserted
documentation string altered, the expected assignment-site set altered, and the
`cargo publish` absence assertion pointed at the one help text that does contain
`--exclude-lockfile`. All three exited 1 with `ASSERT FAIL`, so this check can
fail in both directions — a missing string and an unexpectedly present one.

**Check D — where artifacts land.** `build-cache.md` at the tag: *"By default,
both directories point to a directory named `target` in the root of your
workspace"*, overridable by `CARGO_TARGET_DIR`, `build.target-dir` or
`--target-dir`; `target/debug/` for `dev`, `target/release/` for `release`, a
directory named for a user-defined profile, and a `target/<triple>/` level under
`--target`. Note for P03: this release of the reference splits *final* build
artifacts (the binary — in the target-dir) from *intermediate* ones (in a
build-dir settable by `CARGO_BUILD_BUILD_DIR`); the owned parameter describes the
final artifacts only.

**Check 8 — the installed cargo's own effective configuration.**
`cargo package --help` and `cargo install --help`, run against the installed
cargo 1.98.0. **Observed:** `cargo install --help` prints
`--bins  Install all binaries` and `--bin [<NAME>]  Install only the specified
binary`, matching `cargo-install.md`'s *"Install all binaries. This is the default
behavior."*; `cargo package --help` prints `-l, --list`, `--no-verify` and
`--allow-dirty`. Exit status 0. Same log.

**Check 9 — `raw/opus…`'s first self-correction, re-measured rather than
inherited: `cargo-dist` issue responsiveness by login.** Commit authorship on
`axodotdev/cargo-dist`'s default branch over the 100 most recent commits gives
the commit-access logins `mistydemeo` (26) and `woodruffw` (6), beside
`dependabot[bot]` (63). Measuring the first comment by either login across the
same ten most recently opened issues, and excluding a comment by the issue's own
author: **6 of 10 answered, 4 unanswered, median 0.190 days (4.6 hours)**. Every
one of those maintainer comments carries `author_association: CONTRIBUTOR`, and a
filter on `MEMBER`/`OWNER`/`COLLABORATOR` returns **0 comments on all six
answered issues** — the artifact reproduced directly. With `archived: false`,
`pushed_at` 2026-09-08, 297 open issues, a last non-yanked release 2026-05-22
(3.6 months, below the rubric's six-month investigate trigger) and no RustSec
record, **the rubric verdict is `active`, not `at-risk`**, confirming the
withdrawal in the raw report. Exit status 0.
Log `review/evidence/cargo-dist-responsiveness.log`.

**Check 10 — `raw/opus…`'s second self-correction, read at the stated versions,
and refined.** At the **v0.32.0** tag — the newest non-yanked crates.io release,
2026-05-22, `MIT OR Apache-2.0`, `rust_version` 1.74 — `book/src/workspaces/
structure.md` lists the workspace configuration file as `dist-workspace.toml` or
*"(deprecated in 0.23.0) `Cargo.toml` (Rust users only, goes in
`[workspace.metadata.dist]`)"*. The deprecation is therefore real and still
current at the newest release. **It is not a removal, and this decision does not
say it is:** `book/src/reference/config.md` at the same tag still reads
configuration from *"Your language-specific project manifests like Cargo.toml"*
and states that *"all references to the `[dist]` section in dist-workspace.toml
and dist.toml may also refer to `[workspace.metadata.dist]` or
`[package.metadata.dist]` in your Cargo.toml"*, and the 0.23.0 changelog entry
says newly initialized Rust projects use the new format while *"Existing projects
will be given the option to opt into the new format, but by default will keep
their existing format for now."* Exit status 0.
Log `review/evidence/cargo-dist-config-location.log`.

**Check 6 — registry, advisory and license figures, re-measured this run**
(`GET https://crates.io/api/v1/crates/<name>` for `crate.recent_downloads` and
`crate.downloads`; `/versions` for the newest non-yanked `num`, `created_at`,
`license` and `rust_version`; `https://rustsec.org/packages/<name>.html` for
advisories). Retrieved 2026-09-10; log `review/evidence/registry-figures.log`.

| crate | 90-day | all-time | newest non-yanked | created_at | license | rust_version | RustSec |
|---|---|---|---|---|---|---|---|
| `cargo-dist` | 19,922 | 175,385 | 0.32.0 | 2026-05-22 | MIT OR Apache-2.0 | 1.74 | HTTP 404 |
| `cargo-make` | 248,798 | 3,672,469 | 0.37.24 | 2025-01-18 | Apache-2.0 | **absent** | HTTP 404 |
| `cargo-binstall` | 125,820 | 3,483,662 | 1.23.0 | 2026-09-05 | GPL-3.0-only | 1.79.0 | HTTP 404 |
| `cross` | 307,766 | 6,269,217 | 0.2.5 | 2023-02-04 | MIT OR Apache-2.0 | absent | HTTP 404 |
| `cargo-zigbuild` | 1,547,057 | 7,034,852 | 0.23.4 | 2026-09-02 | MIT | 1.88 | HTTP 404 |
| `cbindgen` | 13,646,147 | 101,705,742 | 0.29.4 | 2026-06-09 | MPL-2.0 | 1.74 | HTTP 404 |
| `cargo-packager` | 47,349 | 178,600 | 0.11.8 | 2025-11-27 | Apache-2.0 OR MIT | absent | HTTP 404 |

An HTTP 404 on a RustSec package page means **no advisory record exists**, not
that the query failed. **One** gate exclusion above rests on this table:
`cargo-make`'s `rust_version` is absent. The `license` column is retained because
it is what the endpoint returned and what `review/evidence/registry-figures.log`
records, and it is evaluated against **no gate**: under the owner's 2026-09-12
ruling (Q7.B), licence compatibility is not a fitness criterion for any
dependency or tool. `cargo-binstall`'s `GPL-3.0-only` value therefore excludes
nothing, and that crate's exclusion is by scope.

**Check 7 — the packaged-file mechanism and the name-divergence rate in
well-regarded manifests, measured independently of the raw reports.** Nine
manifests fetched through `gh api repos/<o>/<r>/contents/<path>` on their default
branches, 2026-09-10. **Observed:** `exclude` 7 of 9 (ripgrep 68,148 stars; bat
60,399; just 35,726; mdBook 22,127; wasmtime-cli 18,616; fd-find 44,354; atuin
31,579); `include` 2 of 9 (helix-term 46,164; typos-cli 4,125, through
`include.workspace = true` inherited from the `crate-ci/typos` workspace root);
Cargo's bare default 0 of 9. Explicit `[[bin]]` block: 7 of 9 (bat and atuin
auto-discover). Explicit `[lib]` block: 2 of 9 (just and wasmtime-cli, both only
to set `doctest = false`). Package name differs from bin name in 5 of 9:
`ripgrep`/`rg`, `wasmtime-cli`/`wasmtime`, `typos-cli`/`typos`, `fd-find`/`fd`,
`helix-term`/`hx`. **A correction recorded in the log rather than quietly fixed:**
my first pass grepped only `crates/typos-cli/Cargo.toml`, found neither field,
and would have contradicted `raw/opus…`'s "typos uses include"; reading the
workspace root showed the allow-list is inherited, so the raw report was right
and my first tally was wrong. Exit status 0.
Log `review/evidence/practice-manifests.log`.

**Check 5 — the py and ts precedent, read through the programme pins.**
`git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:<path>`
and `git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:<path>`.
**Observed, each at the line the prompt cites:** py `pyproject.toml:120`
`plbp = "py_launch_blueprint.cli.main:cli"`; `:131-133`
`requires = ["uv_build>=0.5,<1.0"]` and `build-backend = "uv_build"`; `:139`
`module-name = "py_launch_blueprint"`; `:141` `module-root = "src"`; py
`README.md:45` `uvx --from py-launch-blueprint plbp` with the parenthetical
*"(uvx needs `--from` because the distribution name differs from the
console-script name)"*. ts `package.json:2` `"name": "ts-launch-blueprint"`;
`:17-19` `"bin": {"ts-projects": "dist/cli.js"}`; `:20-22` `"files": ["dist"]`;
`tsdown.config.ts` `entry: ['src/cli.ts', 'src/lib.ts']` with `dts: true`. Exit
status 0. Log `review/evidence/source-pins.log`.

**What these checks establish, and what they do not.** They establish that every
manifest semantic this decision relies on is what the toolchain of the day
actually documents and implements, that both of the raw report's self-corrections
hold when re-measured from scratch (with the `dist` one refined from "deprecated"
to "deprecated but still supported at 0.32.0"), that the two gate exclusions rest
on current registry facts, and that the practice split on `include`/`exclude` runs
7:2 *against* the field this decision selects. **They do not establish that the
recommended manifest works**, because no manifest was written and no build was
run. AC1–AC6 are the checks that would establish it and they are P03's to
execute, as recorded under `## Engines`.

## Engines

- **codex** `raw/codex-cd14ccfbbefdabb73358b9b75dd288f863c9984100d6d5e3d21f796e3c37f183.md` (retrieved 2026-09-05) — Cargo-native, no backend crate; explicit `[lib]` + one `[[bin]]`; `autobins = false`; **`include` allow-list**; package and bin names **match**; no web `[[bin]]` now. Excludes `cargo-make` on the absent-`rust_version` gate and `cargo-dist` on scope. Raised the F218 baseline-review line carried above. Could not measure issue responsiveness — the unauthenticated GitHub core limit was exhausted — and said so rather than inventing a figure.
- **opus** `raw/opus-93a5d89f571b19ea2bc7cdb9ccb956052b1a414c82a9256bb31a0a71454d3059.md` (retrieved 2026-09-10) — the same Cargo-native conclusion reached from an eight-project manifest survey, plus the F212 baseline-review line carried above; **`exclude` deny-list**; names **diverge** (`rslbp`, labelled a naming proposal needing an owner decision); web behind a feature following mdBook rather than a second `[[bin]]`; `default-run` unset; no `build.rs`. Carries two recorded self-corrections, both re-measured here in checks 9 and 10. Excluded `cargo-binstall` on **two** grounds: fitness gate 1 at `:353-356` (licence `GPL-3.0-only`, *"not compatible with `MIT OR Apache-2.0` for anything linked"*) and, independently, scope at `:359-362` (*"excluded here regardless"*, the `[package.metadata.binstall]` table being R68's F214). Under the owner's 2026-09-12 ruling (Q7.B) the gate-1 ground is void and is not carried forward; the scope ground is the one this decision adopts.
- **doxa** `raw/doxa.normalized.md` — three providers regrouped under the template's fields; per-provider originals in `raw/doxa-openai.normalized.md`, `raw/doxa-perplexity.normalized.md`, `raw/doxa-gemini.normalized.md`; every repair recorded in `doxa/normalization.json`. All three reach Cargo-native with no backend crate and split on the sub-decisions below.
  - **doxa/openai** (gpt-5.6-sol, retrieved 2026-09-09) — `include` allow-list; names match; `autobins = false`; **also** `build = false` and `default-run` set; proposes a concrete `rust-version = "1.96"`.
  - **doxa/perplexity** (sonar-deep-research, retrieved 2026-09-09) — names match; **neither `include` nor `exclude`**, relying on Cargo's default and documenting that as deliberate; a **second `[[bin]]`** `rs-launch-blueprint-web` with `required-features = ["web-service"]` and CLI at `src/bin/cli.rs`.
  - **doxa/gemini** (deep-research-preview-04-2026, retrieved 2026-09-09) — `include` allow-list, argued from 2024-edition design discussions about `.github` leaking into published crates; a **second `[[bin]]`** for the web service; names **diverge** (`rsbp`, likewise a naming proposal).

**Disagreement 1 — is any build-orchestration crate warranted?** No engine says
yes. Settled by the structure of the field rather than by a vote: the three-bin
map has exactly one bin containing a candidate that declares a target, and checks
2, 4 and A show Cargo's manifest already expresses every behavior B1–B4 — target
naming and paths, the packaging steps, and the packaged-file bound respectively. **No
residual uncertainty.**

**Disagreement 2 — `include`, `exclude`, or Cargo's default?** Three engines say
`include` (codex, doxa/openai, doxa/gemini), one says `exclude` (opus), one says
neither (doxa/perplexity). Settled **against the practice majority** and for
`include`, on the three reasons argued under `### Principles and implementation`;
"neither" is eliminated outright by check A, because the default publishes
`.github/`, `docs/` and `research/` to every consumer. **Residual uncertainty is
real and is recorded as medium confidence**: check 7 measures 7 of 9 well-regarded
manifests using `exclude`, and the counter-argument rests on a difference in
repository shape rather than on a measurement. It is one manifest field to
reverse, and R26 (F039/F078) owns the CI guard that catches a wrong value.

**Disagreement 3 — does the binary name diverge from the package name?** Three
say match (codex, doxa/openai, doxa/perplexity), two say diverge (opus `rslbp`,
doxa/gemini `rsbp`). Settled for **match**, on the ground that both divergent
proposals label their string as a naming proposal rather than a research finding,
that a value carrying an open owner call cannot be published to the registry, and
that check 8 shows divergence costs no install-time flag in either direction, so
a fork adopts it for one `name =` line. **Residual uncertainty:** the name itself
is owner-reviewable, and check 7 shows 5 of 9 surveyed projects diverge.

**Disagreement 4 — does the web surface get a second `[[bin]]` now?** Two say yes
(doxa/perplexity, doxa/gemini), three say no (codex, opus, doxa/openai). Settled
for **no**, and on ownership rather than on preference: F017 is already `ADOPT`
for the optional-feature shape, and R69 owns whether the feature also brings a
second process. Check 3 supplies the verified cost of the two-binary form — a
`required-features` binary is skipped when the features are off, and
`CARGO_BIN_EXE_<name>` is then unset — and that fact is handed to R69 and R32
rather than used to close R69's question. **Residual uncertainty is R69's, not
this item's**, and this decision is written so that R69 resolving either way
changes one manifest block and nothing else.

**Disagreement 5 — `build = false` and `default-run`?** Only doxa/openai sets
them. Declined, on the asymmetry argued above: an accidental `src/bin/*.rs`
produces a shipped, installed command — this item's own subject — while an
accidental `build.rs` does not, and `default-run` is dead metadata with one
binary. **Low residual uncertainty**; both are one-line additions if a second
binary or a build script ever appears.

**What P03 must validate, because this run could not.** AC1–AC6 in
`### Principles and implementation`, every one of which needs a Rust source tree
that does not exist: that `cargo metadata` reports exactly one `lib` and one
`bin` target with the recorded names; that `cargo build --release` produces
`target/release/rs-launch-blueprint`; that `cargo package --list` contains the
allow-listed files **and** nothing under `.github/`, `docs/` or `research/`; that
`cargo publish --dry-run` exits 0, which is the check that fails if the `include`
list omitted a compile-time input; that the binary count is unchanged with the
web feature on and off; and that an integration test resolves
`env!("CARGO_BIN_EXE_rs-launch-blueprint")` with no non-default feature enabled.
A useful negative control for P03, proposed here and not run: temporarily adding
`required-features` to the `[[bin]]` block must make the AC6 test fail to
compile with an unset `CARGO_BIN_EXE_rs-launch-blueprint`, which is the executable
form of the Disagreement 4 argument. **No performance figure of any kind is
claimed in this decision**, and none should be inferred from it; measuring build
or package wall-clock cost is P03's, against the real template.
