# R68 — release-binary-artifacts (crate, Deep) — raw report

Engine: Opus (`research-opus-2026-09-17T033528Z-e504b7806e0c`, model `claude-opus-5`).
Item kind: `crate`. Two subjects: (A) which distributable artifact types ship beyond
the single `.crate` file, and (B) the Cargo release build profile (owner ruling
W0-R69p, 2026-09-16). All figures retrieved 2026-09-17 unless a different date is
given beside them.

### Landscape

**The category this item decides, stated in two halves.** Subject A is *post-registry
binary distribution*: given that `cargo publish` produces exactly one artifact — "a
distributable, compressed `.crate` file with the source code of the package"
(`https://doc.rust-lang.org/cargo/commands/cargo-package.html`, retrieved 2026-09-17)
— which *additional* artifact types the template builds and uploads, and by what tool.
Subject B is the *compiler-settings surface* of the manifest: which `[profile.release]`
keys the template writes and which it leaves at Cargo's documented default.

**Three-bin map — subject A (binary distribution).**

| Bin | Members found | Note |
|---|---|---|
| Built-in / first-party toolchain | `cargo publish`/`cargo package` (the `.crate` file); `cargo install` (source compile from the registry); `cargo build --target` (cross-compilation where the host toolchain can link it) | Cargo ships no archive-building, no GitHub-Release-uploading and no installer-script generator. There is no first-party answer to subject A. |
| Established industry standard | `dist` (formerly `cargo-dist`, crate `cargo-dist`, repo `axodotdev/cargo-dist`) — plans, cross-builds, archives, installers and *generates its own release CI*; `cargo-binstall` (`cargo-bins/cargo-binstall`) — the consumer-side fetcher that end users run; `taiki-e/upload-rust-binary-action` — a single-purpose GitHub Action that builds one binary and uploads one archive to an existing Release | These three are not alternatives to each other in the same slot: dist and the taiki-e action compete as *producers*; binstall is a *consumer* that either side can feed. |
| Up-and-comer / adjacent | `cargo-zigbuild` (zig as linker, Linux glibc/musl cross); `cargo-xwin` (Windows cross); `houseabsolute/actions-rust-cross` (a `cross`-wrapping Action); `cargo-quickinstall` (third-party prebuilt host binstall falls back to); `axoupdater` (dist's self-update library) | These are cross-compilation or update mechanisms that sit *under* or *beside* a producer, not producers themselves. |

**Three-bin map — subject B (release profile).**

| Bin | Members | Note |
|---|---|---|
| Built-in / first-party | Cargo's four built-in profiles (`dev`, `release`, `test`, `bench`), custom profiles via `inherits`, and per-package/`build-override` overrides — all documented in the Cargo Book's profiles chapter | This subject is **entirely first-party**. There is no crate to choose; the decision is which documented keys to write. |
| Established industry standard | The de-facto "shippable binary" profile conventions visible in well-regarded CLIs (`lto` + `codegen-units = 1`, sometimes `strip`, sometimes `panic = "abort"`) | A convention, not a tool. Surveyed below as practice evidence. |
| Up-and-comer | `[profile.dist]` — a custom profile that `dist init` writes (`inherits = "release"`, `lto = "thin"`) | Relevant only because subject A's dominant tool creates it. |

**Authoritative sources used, and why each is authoritative.**

1. **The Cargo Book, "Profiles" chapter** (`https://doc.rust-lang.org/cargo/reference/profiles.html`,
   retrieved 2026-09-17) — the Rust project's own normative reference for every profile
   key, its permitted values, its default and the override precedence. It is the only
   source that can settle "what is the documented default", which subject B's HIGH
   question asks for by name.
2. **The Cargo Book, `cargo-package(1)`** (`https://doc.rust-lang.org/cargo/commands/cargo-package.html`,
   retrieved 2026-09-17) — establishes the base artifact this item builds on top of.
3. **`dist`'s own book, at the tag being evaluated** (read from the repository at
   `ref=v0.33.0` via the authenticated GitHub contents API, retrieved 2026-09-17):
   `book/src/reference/config.md`, `book/src/reference/concepts.md`,
   `book/src/installers/other.md`, `book/src/ci/index.md`. Maintainer documentation
   read at a pin rather than from a rendered site, because the previously advertised
   docs host does not resolve (see the maintenance-state paragraph).
4. **`cargo-binstall`'s `SUPPORT.md` and `README.md`** (`cargo-bins/cargo-binstall`,
   default branch, retrieved 2026-09-17) — the maintainers' normative statement of the
   default URL and `bin-dir` inference rules, which decides whether metadata is needed.
5. **`taiki-e/upload-rust-binary-action`'s `README.md`** (retrieved 2026-09-17) — the
   action's own input table, which gives its default archive name and its `profile` input.
6. **release-please's own configuration reference** (`googleapis/release-please`,
   `docs/manifest-releaser.md`, retrieved 2026-09-17) — the `draft` and
   `force-tag-creation` keys that make the release-please → dist hand-off work.
7. **Published manifests of well-regarded Rust projects**, read as primary artifacts
   over `raw.githubusercontent.com` (retrieved 2026-09-17) — practice evidence for
   subject B, cited per project below.
8. **crates.io and GitHub REST APIs** — the figure endpoints named in `## Required evidence`.
9. **This item's own measurements** — a probe crate built 25 times on macOS and 17 times
   in a Linux container, tabulated under `### Recommendation`. Owner ruling W0-R69p makes
   measurement, not citation, the deciding evidence for subject B.

A single blog post was not used as an authority anywhere in this report; no
non-primary write-up is cited.

**Practice evidence — projects surveyed, and the evidence that they are well regarded.**
Eighteen widely-used Rust CLIs were checked for a `dist` configuration. The census was
run by requesting `dist-workspace.toml`, `dist.toml` and the root `Cargo.toml` over
`https://raw.githubusercontent.com/<o>/<b>/<path>` and keying on the HTTP status code.
(An earlier attempt through `gh api repos/<o>/<r>/contents/<path>` produced a false
"present" for all eighteen, because `gh api` prints the 404 body to stdout; that census
was discarded and is reported here so the correction is on the record.)

| Project | Regarded because | Uses `dist`? |
|---|---|---|
| `astral-sh/uv` | Astral's Python package manager; 3.49 M all-time downloads on its Rust CLI's sibling registry entries, and the most-watched new Rust CLI of the period | **yes** (`dist-workspace.toml`) |
| `astral-sh/ruff` | Astral's Python linter, the reference example the owner's own py template uses (`pyproject.toml` dev group) | **yes** |
| `atuinsh/atuin` | widely adopted shell-history tool | **yes** |
| `BurntSushi/ripgrep` | 8.3 k-star-class tool by a Rust-library maintainer of long standing (`regex`, `memchr`) | no |
| `sharkdp/fd`, `sharkdp/bat` | the two canonical "modern Unix" Rust CLIs | no |
| `casey/just` | the command runner this template itself adopts (R42, `package-manager-invocation`) | no |
| `jj-vcs/jj` | Google-originated VCS, heavy current adoption | no |
| `nextest-rs/nextest` | the Rust test runner recommended by its own working group | no |
| `starship/starship`, `ajeetdsouza/zoxide` | two of the most-installed Rust end-user CLIs | no |
| `oxc-project/oxc` | the JS toolchain whose formatter `oxfmt` the owner's ts template pins | no |
| `rust-lang/rust-analyzer` | a rust-lang org project | no |
| `crate-ci/typos` | used in `dist`'s own CI (seen in its dependabot commits) | no |
| `Canop/bacon` | the dev watcher R69's accepted value names | no |
| `rust-lang/mdBook`, `sigoden/aichat`, `helix-editor/helix` | rust-lang org; popular LLM CLI; popular editor | no |

**Reading of that census: 3 of 18 (17%).** `dist` is *not* the majority practice among
well-regarded Rust CLIs; the majority ship release binaries from hand-written GitHub
Actions matrices. What `dist` is, is the only tool that does the whole job — cross-build,
archive, checksum, installer script, Homebrew formula, machine-readable manifest — from
one config block, and its three adopters here include the two highest-profile new Rust
CLIs of the period.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**
The principle both source repositories realise is: *an end user installs the tool with
one documented command that does not require them to have the project's build toolchain
configured, and CI proves that command works before the release is announced.* In py it
is realised as "build every distributable format the ecosystem defines and check them"
(`uv build` → sdist + wheel, then `twine check dist/*`, then
`uvx --from "$(ls dist/*.whl)" plbp --version`;
`py .github/workflows/ci.yml:215-222` at pin `b08bccfb`); in ts as "one package format,
because npm defines exactly one" (`"type": "module"` with a `files: ["dist"]` allow-list;
`ts package.json:20-23` at pin `cb1cbcb2`). The agreement level is **capability**, not
mechanism: the ecosystems' artifact formats differ so completely that no mechanism ports.

**Why the py precedent does not decide this item, stated precisely.** py's two formats
are not two *distribution channels*; they are one channel (PyPI) with two payload shapes
that PyPI itself requires. A wheel *is* a pre-built artifact — installing it runs no
compiler. The Rust analogue of "the ecosystem hands the user a pre-built artifact from the
registry" **does not exist**: crates.io stores source only, and `cargo install` compiles it.
So the capability py gets for free from its registry is exactly the capability this item
must decide whether to build by hand. That is the substantive finding behind F214's
`DIVERGENT` verdict, and it argues *for* shipping binaries rather than against: matching
py's observable outcome (user runs one command, no compile) requires a mechanism py
never needed.

**Essential behaviors.** (1) One documented install command per audience. (2) The artifact
the user downloads runs on `x86_64-unknown-linux-gnu`, `x86_64-apple-darwin` and
`aarch64-apple-darwin` without a Rust toolchain. (3) The release that publishes the
`.crate` and the release that publishes the binaries are the *same* release, announced
once, with the tag release-please already owns (F063, F073). (4) A shipped binary's panic
output identifies the failing function, because an end user cannot rebuild it.

**Observable acceptance criteria.** AC1: after a release, `GET
/repos/<o>/<r>/releases/tags/v<X.Y.Z>` lists one archive per target triple plus a
`sha256` file and an installer script. AC2: `cargo binstall rs-launch-blueprint` on a
clean machine installs `rslbp` without invoking `rustc` — provable from binstall's own
"strategies" output naming `crate-meta-data`, not `compile`. AC3: `cargo install --locked
rs-launch-blueprint` still works and still produces a byte-size equal to a local
`cargo build --release` of the same source (measured below: it does). AC4:
`RUST_BACKTRACE=1 rslbp <panicking input>` on a downloaded binary prints at least the
Rust symbol names of the frames (measured below: it does at the recommended profile, and
does **not** if `strip` is set). AC5: the GitHub Release is created by release-please and
completed by the binary job — not created twice.

**Architectural alternatives, compared before libraries.** Four shapes exist:

| Shape | What it is | Cost | Where it fails |
|---|---|---|---|
| **S1 crates.io-only** | publish the `.crate`; README says `cargo install --locked rs-launch-blueprint` | zero release-CI cost | every user pays a full optimised compile of the whole dependency tree; measured at the recommended profile that is a ~29 s build of a 47-crate tree on an M4 Pro, and a template's tree will be larger |
| **S2 hand-written matrix** | a `release.yml` job per target running `cargo build --release --target …`, `tar`, `gh release upload` | ~60 lines of YAML the template owns forever; no tool dependency; the majority practice (15 of 18 above) | the template must hand-write checksums, archive layout, installer script and the naming scheme binstall infers from; every one of those is a place to get it subtly wrong once and not notice |
| **S3 single-purpose Action** | `taiki-e/upload-rust-binary-action` in a matrix | ~25 lines; one pinned Action | its default archive name is `$bin-$target`, which does **not** match binstall's default `{ name }-{ target }` when the binary name differs from the crate name — and R49 made them differ (`rslbp` vs `rs-launch-blueprint`), so binstall metadata becomes mandatory rather than free |
| **S4 whole-job tool** | `dist` generates and owns `release.yml` | a generated workflow the template does not hand-edit; a tool version to track | the generator writes runner labels and a `[profile.dist]` stub the template must then reconcile with its own fixed parameters |

**How the recommended design preserves each principle.** S4 with `create-release = false`
is the only shape where the *same* GitHub Release carries both the changelog
release-please wrote and the binaries, without either side racing the other: dist's own
documentation states that with `create-release = false` "dist will assume a draft GitHub
Release for the current git tag already exists with the title/body you want, and just
upload artifacts to it, undrafting when all artifacts are uploaded"
(`book/src/reference/config.md`, `#create-release`, `ref=v0.33.0`, retrieved 2026-09-17).
release-please supplies exactly that draft: its manifest reference documents `"draft": true`
("create those as 'Draft' releases") and `force-tag-creation`, whose documented purpose is
that "By default, GitHub does not create a Git tag for draft releases until they are
published" (`googleapis/release-please`, `docs/manifest-releaser.md`, retrieved 2026-09-17).
**The load-bearing precondition** is F072's auth mechanism: the ledger records
`actions/create-github-app-token v3.2.0` as the release-please token source
(`docs/port/COMMONALITY.md:78`). A tag pushed with the default `GITHUB_TOKEN` does not
trigger another workflow; a tag pushed with an App token does. Without F072's App token
the dist workflow would never fire, so this coupling must be stated in the plan rather
than discovered in CI.

**Where a different ecosystem needs a different design.** py needs none of this because
PyPI stores wheels; ts needs none because npm stores one built tarball. Only Rust puts a
compiler between the registry and the user, and only Rust therefore needs a second
channel to reach the outcome the other two get from their registry.

**Minimal realistic example.** A `dist-workspace.toml` with `targets` = the three triples
buildable on the two fixed runners, `installers = ["shell"]`, `create-release = false`,
`[dist.github-custom-runners]` pinning `global`/Linux to `ubuntu-latest` and both Darwin
triples to `macos-latest`, `features` left at its default `[]` so the `web`-gated
`rslbp-serve` is not built, plus `[profile.release] lto = "fat"` / `codegen-units = 1`
in `Cargo.toml`. Executable acceptance checks are listed under `### Validation strategy`,
separated into checks this item ran and checks it proposes.

**`BASELINE-REVIEW:` findings: none.** F220 (`documented end-user install method`,
`ADOPT`, `docs/port/COMMONALITY.md:224`) asks for a derived value rather than a change,
and that value is supplied under `### Recommendation`. F214's row already names this
item's option set correctly. No ledger row is challenged.

### Dominant choice

**`dist` (formerly `cargo-dist`) — crate `cargo-dist`, repo `axodotdev/cargo-dist` — at
`v0.33.0`, operated in follower mode (`create-release = false`) behind release-please,
paired with `cargo-binstall` compatibility that costs no configuration; and, for subject B,
Cargo's own `[profile.release]` with exactly two keys written (`lto = "fat"`,
`codegen-units = 1`) and four left silent.**

The two subjects have one dominant choice each because they are different kinds of
question: subject A picks a tool from a surveyed field, subject B picks values from a
first-party surface where there is no tool to pick.

`dist` is dominant on capability, not on popularity — its 17% adoption rate among the
surveyed projects is a minority. What makes it dominant is that it is the only candidate
that produces, from one config block, the complete artifact set the acceptance criteria
name: per-target archives, `sha256` sidecars, a `sha256.sum`, a POSIX installer script, a
Homebrew formula, and a machine-readable `dist-manifest.json`. Verified against the real
asset list of `v0.33.0` (`GET /repos/axodotdev/cargo-dist/releases/tags/v0.33.0`,
retrieved 2026-09-17): 23 assets including `cargo-dist-aarch64-apple-darwin.tar.xz`,
its `.sha256`, `cargo-dist-installer.sh`, `cargo-dist.rb`, `dist-manifest.json` and
`sha256.sum`. Its own release is built by itself, which is the strongest available
evidence that the generated pipeline works.

**Maintenance state: `at-risk`.** The signal that decides it is a *publication gap*, not
a silence: the newest GitHub release is `v0.33.0`, published 2026-09-11T05:40:23Z, but
`GET https://crates.io/api/v1/crates/cargo-dist/0.33.0` returns
`{"errors":[{"detail":"crate `cargo-dist` does not have a version `0.33.0`"}]}` and the
newest non-yanked registry version is `0.32.0`, created 2026-05-22T05:58:59Z — so the
registry install path is four months behind the tool's own releases. Corroborating
concrete signals: of the 10 most recently opened issues
(`GET /search/issues?q=repo:axodotdev/cargo-dist+is:issue&sort=created&order=desc&per_page=10`),
**10 of 10 have no comment from an `OWNER`, `MEMBER` or `COLLABORATOR`** — median days to
first maintainer response is undefined, unanswered count 10 — against 297 open issues
(`GET /search/issues?q=repo:axodotdev/cargo-dist+is:issue+is:open` → `total_count` 297);
and the docs host the README's own badges and the wider ecosystem point at,
`opensource.axo.dev`, returns `NXDOMAIN` (the book is served from
`https://axodotdev.github.io/cargo-dist/book/`, HTTP 200, retrieved 2026-09-17).
Countervailing active signals, recorded rather than suppressed: `archived: false`,
`pushed_at: 2026-09-13T18:13:07Z`, and the last ten commits include
`release: 0.33.0` and CI work by the two top contributors (`mistydemeo`, 1 244 commits;
`Gankra`, 1 248). The verdict is `at-risk` rather than `active` because the deciding
signal — a tool whose newest release cannot be installed from the registry, with a
maintainer team that is committing but not answering users — is exactly the risk a
template takes on when it makes that tool a permanent part of its release pipeline.

That verdict changes the recommendation's *shape*, not its direction: the pipeline dist
generates is ordinary GitHub Actions YAML checked into the repository, so a fork that
outgrows dist deletes the tool and keeps the workflow. The recommendation below is
written so that the escape hatch is real.

### Qualified shortlist

Gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)` for every row; see
`### Excluded by gate` for the full gate table. Figures: crates.io
`GET /api/v1/crates/<name>` and `/versions`, GitHub `GET /repos/<o>/<r>` and
`GET /search/issues?q=repo:<o>/<r>+is:issue+is:open`, all retrieved 2026-09-17.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| `cargo-dist` (the tool calls itself `dist`) | producer: cross-build, archive, checksum, installer, generated release CI | 19 489 | 176 671 | 2 115 | `0.32.0`, 2026-05-22 (crates.io); a newer `v0.33.0` exists on GitHub 2026-09-11 and is **not** on crates.io | **at-risk** — registry four months behind its own releases; 10/10 recent issues unanswered; 297 open; but `archived: false`, pushed 2026-09-13 | `astral-sh/uv`, `astral-sh/ruff`, `atuinsh/atuin` (each verified by a `dist-workspace.toml` at HTTP 200) | does the entire job, and owns a generated `release.yml` plus a `[profile.dist]` stub the template must reconcile |
| `cargo-binstall` | consumer: the command an end user runs to fetch a prebuilt binary | 126 854 | 3 493 101 | 2 876 | `1.23.0`, 2026-09-05 | **active** — released 12 days before retrieval; pushed 2026-09-15; 8 of 10 recent issues answered, median 0.9 days; 94 open | it is itself the adopter surface: any project whose Release assets match its inference rules | costs the template **nothing** if the archive names match its defaults; costs a `[package.metadata.binstall]` block if they do not |
| `taiki-e/upload-rust-binary-action` | producer: build one binary, archive it, upload to an existing Release | inapplicable — a GitHub Action, not a crate; the crate figures do not apply because it is never resolved by Cargo and has no crates.io entry | inapplicable, same reason | 323 | `v1.30.2`, 2026-04-17 | **active** — pushed 2026-09-02; 8 of 10 recent issues answered, median 0.04 days; 23 open | smallest possible surface and a maintainer who answers within an hour; but its default archive name `$bin-$target` breaks binstall's default inference for this template's `rslbp` ≠ `rs-launch-blueprint` pair |
| `cargo-quickinstall` | third-party prebuilt host that binstall falls back to | 8 338 | 502 322 | inapplicable — evaluated as a fallback channel the template does not operate, so repository standing is not a selection input | `0.3.53`, 2026-07-12 | **stable-quiet** — released 2 months before retrieval, no at-risk signal found | binstall's documented fallback for any crate | requires no action and gives no guarantee; listed so that "binstall works even with no Release assets, slowly" is on the record |

Four rows, not five. **That is a finding**: the producer field has exactly two serious
members for this template's shape (`dist` and the taiki-e Action), because everything
else in the landscape is either a cross-compilation backend that still needs a producer
around it, or a consumer.

### Excluded by gate

Gates answered per candidate **before** popularity was weighed. Gate 1 is recorded, not
deleted, per the prompt's constraint.

| Candidate | G1 licence | G2 MSRV | G3 advisories / `unsafe` | G4 OS matrix | G5 default features / async coupling | G6 size & compile cost | Verdict |
|---|---|---|---|---|---|---|---|
| `cargo-dist` | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | passes — declares `rust-version` `1.74` (crates.io `/versions`, `0.32.0`), far under the `stable minus 2` floor of `1.96`; and it is a **host tool**, never a dependency of the template, so its tree never enters the template's MSRV surface | `https://rustsec.org/packages/cargo-dist.html` → HTTP 404, i.e. no advisory page exists (control: `time`, `openssl`, `chrono` → HTTP 200); `unsafe` posture not measured and **not needed** — it is a build-time binary, so no `unsafe` of its reaches the shipped artifact | passes — it *is* a cross-target build tool; its default runner map assigns `ubuntu-22.04`, `ubuntu-22.04-arm`, `macos-14`, `macos-15-intel` (`cargo-dist/src/backend/ci/github.rs`, `github_runner_for_target`, `ref=v0.33.0`), which are **outside** the fixed `target-os-matrix` and must be overridden — see `### Recommendation` | inapplicable — not a Cargo dependency, so it has no feature or runtime coupling with the template | measured: adds zero bytes to the shipped binary; adds one tool download and N build jobs to release CI only | **qualified** |
| `cargo-binstall` | `inapplicable — owner ruling 2026-09-12 (Q7.B)` (its registry licence is `GPL-3.0-only`, recorded as a fact and explicitly **not** evaluated) | passes — `rust-version` `1.79.0`; and it is installed by the *end user*, never by the template | `https://rustsec.org/packages/cargo-binstall.html` → HTTP 404 (no advisory page); `unsafe` posture not reached — not linked into anything this template ships | passes — publishes its own binaries for both Linux and macOS targets | inapplicable — not a dependency | zero cost to the template; the whole point is that it *saves* the user a compile | **qualified** |
| `taiki-e/upload-rust-binary-action` | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | inapplicable — a GitHub Action, no Rust manifest, no MSRV | `rustsec` inapplicable — not a crate; no advisory surface | passes — its README's matrix examples run `ubuntu-latest` and `macos-latest` | inapplicable | adds ~25 lines of YAML per target; no runtime cost | **qualified, ranked runner-up** |
| `cross` (`cross-rs/cross`) | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | not reached | not reached | **FAILS gate 4** — it executes builds inside Docker containers, and GitHub's macOS runners provide no container runtime, so it cannot produce the two `*-apple-darwin` targets from `macos-latest`. Corroborating maintenance signal: newest crates.io version `0.2.5`, created 2023-02-04 — 3.6 years before retrieval (90-day downloads 309 245; all-time 6 296 683; stars 8 316) | not reached | not reached | **excluded by gate 4** |
| `cargo-zigbuild` (`rust-cross/cargo-zigbuild`) | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | not reached | not reached | **FAILS gate 4 as a standalone producer** — it is a linker wrapper for cross-compiling to Linux glibc/musl, not a release pipeline; it uploads nothing and creates no Release. Figures recorded because it is a real up-and-comer: 90-day 1 544 669; all-time 7 145 985; stars 2 653; `0.23.4` 2026-09-02; pushed 2026-09-14 | not reached | not reached | **excluded — wrong layer** (a backend, not a producer); see `### Up-and-comers` |
| `cargo-xwin` (`rust-cross/cargo-xwin`) | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | not reached | not reached | **excluded by fit** — Windows cross-compilation only, and `target-os-matrix` fixes no Windows target. Figures: 90-day 816 085; all-time 4 591 129; `0.23.1` 2026-08-13 | not reached | not reached | **excluded — no target in the fixed matrix needs it** |
| `axoupdater` | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | not evaluated | not evaluated | not evaluated | **FAILS gate 5 by scope** — it is a *runtime* dependency linked into the shipped binary that adds a self-update command, a network call and an update-check surface no requirement in this item or F214 asks for. Figures: 90-day 417 057; all-time 1 036 781; `0.10.2` 2026-08-12 | would add bytes to every shipped binary for an unasked capability | **excluded — adds an unrequested runtime surface** (`dist`'s `install-updater` is left at its default `false`, as `astral-sh/uv` also does) |
| `houseabsolute/actions-rust-cross` | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | inapplicable (Action) | inapplicable (Action) | inherits `cross`'s container constraint for the Linux leg | inapplicable | ~20 lines of YAML | **excluded — subsumed by the runner-up** (stars 215, pushed 2026-08-04, `v1.0.8` 2026-06-21; strictly more machinery than S3 for the same result on this two-OS matrix) |

For subject B there is no candidate to gate: the surface is Cargo's own. Gates 1–5 are
`inapplicable — the decision selects values on a first-party manifest surface, not a
crate`; gate 6 (binary-size and compile-time cost) is the entire subject and is answered
quantitatively under `### Recommendation`.

### Up-and-comers

- **`cargo-zigbuild`** (90-day 1 544 669 — the highest 90-day figure of anything surveyed
  here, and 8× `cargo-binstall`'s; `0.23.4` 2026-09-02; stars 2 653; pushed 2026-09-14).
  Its trajectory is the clearest signal in the field that *cross-compiling Linux targets
  without containers* is becoming the default technique. It becomes relevant to this
  template the day someone wants `aarch64-unknown-linux-gnu` or a musl target without
  adding an ARM runner — it can produce both from `ubuntu-latest`. It is a **backend**,
  so it would sit under `dist` (`github-build-setup`) or under the runner-up's matrix,
  never instead of them. Recorded as the named re-verify trigger below.
- **`dist`'s own `v0.33.0`-era direction** — `github-attestations` (build provenance via
  `actions/attest-build-provenance`) and `github-action-commits` (commit-pinning every
  Action in the generated workflow) are both configuration keys in the v0.33.0 reference,
  and `astral-sh/uv`'s `dist-workspace.toml` sets both. Supply-chain provenance for
  release binaries is the direction of travel; the template can adopt it later with two
  config lines, and this item does not decide it (no requirement here asks for it).
- **`cargo-quickinstall`** (all-time 502 322; `0.3.53` 2026-07-12) — a third-party build
  farm that gives *any* crate a binstall path without the project doing anything. It is
  the reason "crates.io-only" is not quite as slow for users as it looks on paper, and
  the reason the runner-up's weakness is smaller than it appears.

### Fit for this template

**CLI.** This is where the decision has teeth. R49's accepted value makes the shipped
command `rslbp` while the distribution name stays `rs-launch-blueprint`
(`docs/port/PARAMETERS.md`, `build-tool-output-shape`; R49 `DECISION.md` revision 8,
owner ruling W0-R49n). That pair is *exactly* the case binstall's default inference was
built for: its `bin-dir` default concatenates the discovered directory with
`"{ bin }{ binary-ext }"`, where "`bin` is the cargo binary name", while its default
`pkg-url` filenames are built from `{ name }`, the crate name
(`cargo-bins/cargo-binstall`, `SUPPORT.md`, "Defaults", retrieved 2026-09-17). `dist`
names its archives after the **package**: its own `v0.33.0` assets are
`cargo-dist-<triple>.tar.xz` although its binary is `dist`. So a dist-produced archive
matches binstall's versionless default filename `{ name }-{ target }{ archive-suffix }`
and its `{ bin }` extraction rule **with no `[package.metadata.binstall]` block at all** —
which is what dist's own book claims in one sentence: `cargo-binstall` works "through no
active effort of our own", because "the URL schema we use for Github Releases is
auto-detected" (`book/src/installers/other.md`, `ref=v0.33.0`, retrieved 2026-09-17).
That answers the second HIGH question directly: **binstall support is free under dist and
is not free under the runner-up**, whose default archive name is `$bin-$target`
(`taiki-e/upload-rust-binary-action` README input table, retrieved 2026-09-17) — i.e.
`rslbp-<triple>`, which binstall's `{ name }`-based defaults will not find, forcing an
explicit `pkg-url` using `{ bin }`.

**Library.** A consumer that depends on `rs_launch_blueprint` as a library inherits
**nothing** from this decision. The Cargo Book is unambiguous: "Cargo only looks at the
profile settings in the `Cargo.toml` manifest at the root of the workspace. Profile
settings defined in dependencies will be ignored"
(`https://doc.rust-lang.org/cargo/reference/profiles.html`, retrieved 2026-09-17). So the
`lto = "fat"` recommended below governs *this* repository's builds and the builds of
anyone who runs `cargo install rs-launch-blueprint` (measured: it does — see
`### Recommendation`, the install check), and governs nothing in a downstream
application's build. That is the answer to profile question 5 and it must be written into
the template's README, because a downstream user reading `[profile.release] lto = "fat"`
in this manifest will otherwise assume they inherit the build cost.

**Web.** R69's accepted value adds a second binary, `[[bin]] name = "<app>-serve"` with
`required-features = ["web"]` (`docs/port/PARAMETERS.md`, `web-extra-surface`). `dist`
builds a package with default features unless told otherwise — `features` defaults to
`[]`, `default-features` to `true`, `all-features` to `false`
(`book/src/reference/config.md`, retrieved 2026-09-17) — so with no configuration at all,
**the serve binary is not built and not shipped in the release archives**, and only
`rslbp` is. That is the right disposition and it should be made explicit rather than
left to the default: the web surface's delivery vehicle is R51's container image, whose
own reference Dockerfile copies `target/release/app` after a plain `cargo build --release`
(`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, the Dockerfile in
the *Details* → C15 material). The profile coupling that creates is stated under
`### Migration implications`.

### Recommendation

**Subject A — artifact types.** Ship **both**: the `.crate` on crates.io (which
`cargo publish` produces anyway and which F075's Trusted Publishing already covers) **and**
`dist`-produced cross-compiled GitHub Release binaries in follower mode behind
release-please, with `cargo-binstall` compatibility taken for free from the naming scheme
rather than configured. Concretely:

| Setting | Value | Why |
|---|---|---|
| tool | `dist` (crate `cargo-dist`), pinned by `cargo-dist-version` in `dist-workspace.toml` | the only candidate producing the full artifact set in one config block |
| `targets` | `["x86_64-unknown-linux-gnu", "x86_64-apple-darwin", "aarch64-apple-darwin"]` | exactly the triples the two fixed runners can build. `aarch64-apple-darwin` and `x86_64-apple-darwin` both build on `macos-latest` (Apple's toolchain targets both architectures); `x86_64-unknown-linux-gnu` is native on `ubuntu-latest` |
| `[dist.github-custom-runners]` | `global = "ubuntu-latest"`, `x86_64-unknown-linux-gnu = "ubuntu-latest"`, both Darwin triples = `"macos-latest"` | **required**, not optional: dist's defaults are `ubuntu-22.04` / `macos-14` / `macos-15-intel` (`cargo-dist/src/backend/ci/github.rs`, `ref=v0.33.0`), none of which is in the fixed `target-os-matrix` |
| `create-release` | `false` | release-please creates the draft Release and the tag; dist uploads into it and undrafts |
| `installers` | `["shell"]` | one POSIX installer script; `powershell` is pointless with no Windows target, and `homebrew` needs a tap this item does not own |
| `features`, `all-features`, `default-features` | left at defaults (`[]`, `false`, `true`) | so `rslbp-serve` (R69, `required-features = ["web"]`) is **not** in the archives; the web surface ships via R51's container |
| `install-updater` | `false` (the default) | `axoupdater` is excluded above; `astral-sh/uv` also sets `install-updater = false` |
| `[package.metadata.binstall]` | **not written** | binstall's defaults already match dist's `{ name }-{ target }` archive and `{ bin }` extraction; adding metadata would be an unverified duplicate of inference that already works |
| README (F220's derived value) | document **both**, in this order: (1) `cargo binstall rs-launch-blueprint`, (2) the `curl … installer.sh` one-liner, (3) `cargo install --locked rs-launch-blueprint` as the from-source path | F220 `ADOPT`, `docs/port/COMMONALITY.md:224`; `--locked` because dist's own book warns `cargo install` "disrespects your lockfile unless you pass `--locked`" (`book/src/installers/other.md`, retrieved 2026-09-17) |

Answer to the MEDIUM question on matrix width: **mirror the fixed two-OS set, but not the
two-*triple* set** — three triples, because `macos-latest` is Apple Silicon and shipping
only `aarch64-apple-darwin` would strand Intel Mac users who are not CI contributors,
while `x86_64-apple-darwin` costs one extra `rustup target add` on a runner that is
already provisioned. `aarch64-unknown-linux-gnu` is **excluded**, because dist's runner
map assigns it `ubuntu-22.04-arm` and no ARM Linux runner exists in the fixed matrix;
it is recorded as the documented widening (add the runner label, add the triple).

Answer to the LOW deferral question: **do not defer.** The CI cost is N parallel build
jobs on the release path only — release-please already gates that path behind a merged
release PR, so it runs once per release, not per pull request (`pr-run-mode` is left at
its default so dist adds nothing to PR CI). The complexity cost is a generated workflow,
and a fork that wants out deletes one config file and keeps the YAML.

**Subject B — release build profile.** Write **two** keys; leave **four** at Cargo's
documented default. Declare **no** custom profile of this item's own.

| Key | Recommended | Written or silent | Cargo's documented default | Measured basis |
|---|---|---|---|---|
| `codegen-units` | `1` | **written** | `16` for non-incremental builds (Cargo Book, `codegen-units`) | −14.8% (macOS) / −16.4% (Linux) binary size on its own; a further −6.9% on top of fat LTO; clean-build cost indistinguishable from baseline at this stand-in (13.23 s vs 14.29 s, both inside a 30% noise floor) |
| `lto` | `"fat"` | **written** | `false`, which the Book defines as "thin local LTO … on the local crate only across its codegen units" — i.e. the default is *not* "no LTO" | with `codegen-units = 1`: −24.4% (macOS, 1 992 016 → 1 506 624 B) / −27.5% (Linux, 2 285 976 → 1 657 040 B). Cost: clean release build roughly doubles (min 14.29 s → 28.94 s) and the bin-only release rebuild goes from ~0.8 s to ~15 s |
| `opt-level` | leave at `3` | **silent** | `3` for `release` | measured: both size-oriented levels made this binary **larger** — `"s"` +12.8%, `"z"` +21.9% on macOS; `"z"` +24.2% on Linux. The Book warns of exactly this ("the `"s"` and `"z"` levels not being necessarily smaller"); writing a key that loses on both axes would be a defect |
| `strip` | leave at `"none"` | **silent** | `"none"` (Book: "The default is `none`") | it is the single largest size win measured (−22.8% macOS / −30.9% Linux) and it is still refused, because it is the only setting measured here that **destroys** an end user's diagnostic output: with `strip = "symbols"` the panic backtrace printed by the built binary is `stack backtrace:` followed by nothing — zero frames — on both macOS and Linux, versus four named frames at the default |
| `panic` | leave at `"unwind"` | **silent** | `'unwind'` | three independent grounds, two measured: (i) the built binary's exit status on panic becomes **134** (SIGABRT) instead of **101**, measured on macOS, and neither is in R67's taxonomy but 134 additionally skips the flush-before-exit path R67's contract shape depends on; (ii) on macOS the abort build's backtrace lost every user frame (2 frames vs 4); (iii) the Book states that "when using the abort strategy and building a test, all of the dependencies will also be forced to build with the unwind strategy" — a second full dependency build in every CI test job, against a −20.3%/−16.7% size gain that `lto = "fat"` already largely supplies |
| `debug` | leave at `false`/`"none"` | **silent** | `0`, `false` or `"none"` for `release` | measured, and the OS asymmetry is decisive: `debug = "line-tables-only"` costs **+12.1%** on macOS but **+550.8%** on Linux (2 285 976 → 14 876 256 B), because Linux embeds DWARF in the ELF while Cargo's `split-debuginfo` default is `unpacked` on macOS. Worse, the macOS gain is an illusion for an end user: the same binary, copied out and run after `target/` was deleted, printed function names with **no** `at ./src/lib.rs:44` line info — the line tables live in `.o` files the user never receives |
| custom profile | **none of this item's own**; keep the `[profile.dist]` stub dist writes, as `inherits = "release"` with **no** keys | — | custom profiles require `inherits` (Book, "Custom profiles") | practice: `astral-sh/uv` and `astral-sh/ruff`, the two largest dist adopters, both ship `[profile.dist] inherits = "release"` with zero overrides and put the real settings in `[profile.release]` (both `Cargo.toml`, retrieved 2026-09-17). Measured ground: the incremental cost of fat LTO (~15 s) lands only on `--release` rebuilds, and nothing in the daily loop uses them — R50's install smoke test builds with `--debug` (R50 `review/DECISION.md`, revision 1) |

**Agreement or ground for differing with the reference architecture.** The owner-supplied
reference's `Reference Cargo.toml` section states `[profile.release]`, `lto = "thin"`,
`codegen-units = 1`
(`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, section
*Reference `Cargo.toml`*). **Agreed on `codegen-units = 1`; differed on `lto`, with
ground.** The ground is measured and corroborated: `lto = "thin"` buys **1.1%** on macOS
and **3.7%** on Linux over the default, and even paired with `codegen-units = 1` it lands
at −16.7%/−20.6% where `"fat"` reaches −24.4%/−27.5% — so `"thin"` gives up roughly a
third of the available size reduction for a clean-build saving (18.99 s vs 28.94 s) that
falls on a build the template runs once per release. The practice evidence points the
same way: of the nine well-regarded projects whose release profiles were read
(`uv`, `ruff`, `ripgrep`, `fd`, `bat`, `just`, `typos`, `zoxide`, `jj`), **not one uses
`lto = "thin"`** — six use fat LTO (`lto = true` or `"fat"`) and the rest set no `lto` at
all. Probable provenance of the reference's row, offered as an observation: `lto = "thin"`
with `inherits = "release"` is byte-for-byte what `dist init` writes as `[profile.dist]`
(`book/src/reference/concepts.md`, `ref=v0.33.0`), so the reference's row most likely
reproduces dist's generated stub rather than an independently measured value — and the
reference's own caveat records that its material was "compiled in my head, not against
the toolchain". The reference's C15 container rows (distroless/cc-debian12, cargo-chef,
`nonroot`, `PORT`) are **handed off to R51**, which owns F223/F336/F337; this item states
only the profile coupling they create (below).

**The empirical anchor that ties the two subjects together.** With
`[profile.release] lto = "fat"` and `codegen-units = 1` written into the manifest,
`cargo install --path . --root <scratch> --locked` produced an `rslbp` of **1 470 416
bytes** — byte-for-byte the size of the `fat-cu1` build and 26.0% smaller than the
1 987 552-byte default-profile build. So `cargo install` **does** honour the published
package's own `[profile.release]`, which means every crates.io-only user pays the fat-LTO
link. That is the strongest argument for shipping binaries: the profile chosen for a good
shipped artifact is the same profile that makes the from-source path slowest.

**Full measurement tables.** Probe composition, stated with its unlikeness: a two-binary,
one-library crate named `rs-launch-blueprint`, edition `2024`, `rust-version = "1.96"`,
mirroring R49's target shape (`[lib] rs_launch_blueprint`, `[[bin]] rslbp`,
`[[bin]] rslbp-serve` with `required-features = ["web"]`) and R69's feature shape
(`web = ["dep:axum", "dep:tokio"]`; resolved to `axum 0.8.9` and `tokio 1.53.1`, the exact
versions R69's accepted value names). Other dependencies `clap 4.6.7`, `serde 1.0.229`,
`serde_json 1.0.151`, `anyhow 1.0.104`, `thiserror 2.0.20`, `tracing 0.1.44`,
`tracing-subscriber 0.3.23`. Dependency tree: **81 unique crates** with `--all-features`,
**47** with default features (`cargo tree --edges normal --prefix none | sort -u | wc -l`).
**Unlikeness to the real template, stated:** it contains a port trait, an in-memory
adapter, three axum routes and a clap parser but no real domain logic, no error catalog,
no config layering and no observability stack — so it is *smaller* than the template will
be, and every absolute size below is a floor while every *percentage* is the transferable
figure. Builds used `cargo build --release --offline` with `--config
'profile.release.<key>=<value>'` overrides so that no two rows differ by a manifest edit;
the `cargo install` check above used the manifest form instead, deliberately, because it
is the form a published crate carries. Lockfile generated once; `cargo fetch` once; every
build offline.

Toolchain and hosts (`docs/port/PARAMETERS.md` fixes no toolchain channel — F103/F190
leave `rust-toolchain.toml` to R27 — so this is the newest stable on the host, recorded
exactly):

- **macOS rows:** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
  `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4, Apple M4 Pro,
  `aarch64-apple-darwin`, 2026-09-17.
- **Linux rows:** `rustc 1.98.0 (88d9e12ae 2026-08-18)`, `cargo 1.98.0 (797e8a9bc 2026-08-05)`,
  image `rust:1.98.0-slim-bookworm` digest
  `sha256:1469a27c125cb5a3aebfa4f4e4665d935b02fb72cc093b2c974b3d740e43f157`,
  `linux/arm64` under Docker Desktop 29.5.2 on the same M4 Pro, 2026-09-17.

Binary measured: **`rslbp`** (the CLI binary R49 names), built with `--features web`.
Baseline row is Cargo's own `release` defaults, as the prompt requires.

*macOS — sizes in bytes, `aarch64-apple-darwin`:*

| Profile setting under test | `rslbp` as built | Δ vs baseline | after external `strip -S -x` |
|---|---|---|---|
| **baseline (Cargo `release` defaults)** | **1 992 016** | — | 1 628 016 |
| `lto = "thin"` | 1 969 680 | −1.1% | 1 604 080 |
| `lto = "fat"` | 1 617 696 | −18.8% | 1 313 552 |
| `codegen-units = 1` | 1 696 752 | −14.8% | 1 430 080 |
| `lto = "thin"` + `codegen-units = 1` (**the reference's row**) | 1 659 232 | −16.7% | 1 406 576 |
| `lto = "fat"` + `codegen-units = 1` (**recommended**) | 1 506 624 | −24.4% | 1 230 576 |
| `opt-level = "s"` | 2 246 240 | **+12.8%** | 1 991 824 |
| `opt-level = "z"` | 2 429 200 | **+21.9%** | 2 019 616 |
| `strip = "symbols"` | 1 537 216 | −22.8% | — |
| `strip = "debuginfo"` | 1 992 016 | **0.0%** (no-op: `release` carries no debuginfo) | 1 628 016 |
| `panic = "abort"` | 1 588 208 | −20.3% | 1 296 304 |
| `debug = "line-tables-only"` | 2 232 520 | +12.1% | 1 628 000 |
| `debug = true` | 2 233 192 | +12.1% | 1 627 888 |
| `opt-level="z"` + `lto="fat"` + `cu=1` + `panic="abort"` + `strip="symbols"` | 769 952 | −61.3% | — |

*Linux (`aarch64-unknown-linux-gnu`, container) — sizes in bytes:*

| Profile setting under test | `rslbp` as built | Δ vs baseline | after `strip --strip-all` |
|---|---|---|---|
| **baseline (Cargo `release` defaults)** | **2 285 976** | — | 1 579 072 |
| `lto = "thin"` | 2 201 288 | −3.7% | 1 513 528 |
| `lto = "fat"` | 1 759 904 | −23.0% | 1 316 920 |
| `codegen-units = 1` | 1 912 144 | −16.4% | 1 382 464 |
| `lto = "thin"` + `codegen-units = 1` (**the reference's row**) | 1 814 240 | −20.6% | 1 316 920 |
| `lto = "fat"` + `codegen-units = 1` (**recommended**) | 1 657 040 | −27.5% | 1 251 384 |
| `opt-level = "z"` | 2 839 496 | **+24.2%** | 1 448 000 |
| `strip = "symbols"` | 1 579 072 | −30.9% | 1 579 072 |
| `strip = "debuginfo"` | 2 285 976 | **0.0%** | 1 579 072 |
| `panic = "abort"` | 1 903 920 | −16.7% | 1 316 928 |
| `debug = "line-tables-only"` | **14 876 256** | **+550.8%** | 1 579 152 |
| min-size stack (as above) | 923 704 | −59.6% | 923 704 |

*Build wall time — macOS, quiet machine, default features, two runs per config, minimum
reported:*

| Config | clean (s), run 1 / run 2 | min | bin-only rebuild (s), run 1 / run 2 | min |
|---|---|---|---|---|
| baseline | 18.64 / 14.29 | **14.29** | 2.12 / 0.77 | **0.77** |
| `codegen-units = 1` | 15.01 / 13.23 | **13.23** | 1.77 / 1.85 | **1.77** |
| `lto="thin"` + `cu=1` | 18.99 / 26.81 | **18.99** | 6.76 / 5.99 | **5.99** |
| `lto = "fat"` | 35.64 / 28.78 | **28.78** | 17.97 / 11.93 | **11.93** |
| `lto="fat"` + `cu=1` | 28.94 / 37.75 | **28.94** | 15.05 / 18.05 | **15.05** |

**The noise floor, stated so no reader over-reads a timing.** Same-config spread on this
host reached **30%** (baseline 14.29–18.64 s; `fat`+`cu=1` 28.94–37.75 s). Only two
build-time claims survive it: fat LTO roughly **doubles** the clean release build
(14.29 → 28.94 s, a 2.0× separation far outside a 30% band), and fat LTO raises the
bin-only release rebuild by roughly **20×** (0.77 → 15.05 s, reproduced across four
independent fat-LTO rows: 11.93, 12.45, 12.86, 13.62, 15.05, 18.05 s). Every finer
comparison — `codegen-units=1` versus baseline, `strip` versus baseline, `opt-level="s"`
versus baseline — is **indistinguishable at this stand-in** and is reported as such rather
than as a finding. Linux **wall times are not evidence at all** and none is quoted: the
Linux baseline and its rerun measured 20.07 s and 11.04 s for byte-identical output, an
82% spread produced by the Docker Desktop VM. Linux **sizes** are evidence — every rerun
reproduced its size byte-for-byte.

*Backtrace behaviour of the built binary (`RUST_BACKTRACE=1 rslbp panic`), executed:*

| Profile | macOS, run from `target/` | macOS, binary copied out and `target/` deleted | Linux |
|---|---|---|---|
| baseline | 4 frames, Rust symbol names, no file:line | same | 4 frames, symbol names |
| `debug = "line-tables-only"` | 5 frames **with** `at ./src/lib.rs:44:21` | **4 frames, names only — the line info did not travel** | 5 frames with `at ./src/lib.rs:44:21` |
| `strip = "symbols"` | `stack backtrace:` then **nothing** | — | `stack backtrace:` then **nothing** |
| `panic = "abort"` | **2 frames**, no user frames; process exits **134** | — | 4 frames; exits 134 |
| baseline, exit status | **101** | — | 101 |

That table is the whole of the answer to profile question 3: for a binary an end user
cannot rebuild, `strip` is the setting that costs the most diagnostically and `debug` is
the setting that cannot be bought cheaply on both platforms at once. Note the limit the
prompt names: **R67 imposes no symbol requirement** — its contract covers returned errors
and its crash record carries "a sanitized cause chain, not a stack trace", with stack
traces deliberately left to F301 — so the requirement above is asserted *here*, on the
evidence in this table, and not inherited.

Answer to profile question 6 (MSRV, targets, CI length): **no**. The Book's version notes
put `debug`'s string forms at 1.71, and `strip`, `lto`, `codegen-units`, `opt-level` and
`panic` are older still — all far under the `stable minus 2` floor of `1.96`; the two
recommended keys restrict no target in the fixed matrix (both were measured on both OSes);
and the CI cost is a doubled clean build on the release path only.

### Ranked runner-up

**`taiki-e/upload-rust-binary-action` in a hand-written three-target matrix, triggered by
`release: published` (or by the tag release-please pushes), with an explicit
`[package.metadata.binstall]` block.** Figures: stars 323; `v1.30.2` 2026-04-17;
`pushed_at` 2026-09-02; 23 open issues; 8 of 10 most recently opened issues answered by a
maintainer, **median 0.04 days** — the most responsive maintainer measured anywhere in
this item. It has a `profile` input (default `release`), so it composes with subject B's
recommendation without change.

**The condition under which it wins.** It wins the moment `dist`'s `at-risk` signal
becomes an `at-risk` *event* — specifically, if `cargo-dist`'s crates.io publication gap
widens past its next release, or if the 10-of-10 unanswered-issue sample persists into a
period where the template hits a dist bug. It also wins immediately for a fork that wants
Windows: the runner-up needs one more matrix row, whereas the fixed `target-os-matrix`
gives dist no Windows runner to target. Its price is paid up front and is exactly
quantified: because its default archive name is `$bin-$target` while binstall's default
`pkg-url` filenames are built from `{ name }`, and R49 made `rslbp ≠ rs-launch-blueprint`,
the template must write and maintain a `[package.metadata.binstall]` block whose `pkg-url`
uses `{ bin }` — a hand-maintained duplicate of a naming convention that is free under the
dominant choice. R49's revision-8 note anticipated exactly this ("if R68 later adopts
`cargo-binstall` metadata, the `bin-dir` template must interpolate `{ bin }` rather than
`{ name }`"); under the dominant choice no such block is needed at all.

Second runner-up, ranked below it: **crates.io-only (S1)**. It wins only if the owner
decides the template's audience is exclusively Rust developers who already have a
toolchain — in which case `cargo install --locked rs-launch-blueprint` is a complete
answer and every line of release-binary machinery is waste. The measured cost of choosing
it is the one in the install check above: every user pays the fat-LTO link that this
item's own profile recommendation makes more expensive.

### Tradeoffs

**Versus the runner-up (`taiki-e` action).** The dominant choice gives up (a) *maintainer
responsiveness* — median 0.04 days against 10-of-10 unanswered; (b) *surface area* — dist
generates a whole `release.yml` the template does not hand-edit, where the runner-up is
~25 lines the template owns outright; and (c) *independence* — a pinned
`cargo-dist-version` is a tool the template now tracks. Those costs are accepted because
the thing bought is not convenience but *correctness of a naming contract the template
cannot otherwise verify*: dist's archive layout is the layout binstall's defaults infer,
so AC2 holds with zero configuration, whereas the runner-up makes AC2 depend on a
hand-written `pkg-url` template that nothing in CI checks. The mitigation that makes the
cost bounded is structural: dist's output is checked-in GitHub Actions YAML, so the exit
from the dominant choice to the runner-up is "delete `dist-workspace.toml`, keep the
workflow", not a rewrite.

**Versus crates.io-only.** The dominant choice gives up simplicity — one publish step
becomes a publish step plus N build jobs plus an upload phase — and accepts an
`at-risk` tool in the release path. It is accepted because crates.io-only cannot satisfy
the capability the two source repos both realise (install without the language toolchain),
and because the measurement above shows the cost it imposes on users grows with the
profile this item independently recommends.

**Subject B, versus the reference's `lto = "thin"`.** The recommendation gives up roughly
10 s of clean release build time per release and roughly 9 s of bin-only rebuild time,
and gains ~7.7 percentage points of binary size on macOS and ~6.9 on Linux. It is accepted
because the build happens once per release in CI while the download happens once per user,
and because the *incremental* penalty that makes fat LTO unpleasant lands only on
`--release` rebuilds, which neither the contributor loop (dev profile) nor R50's install
smoke test (`--debug`) performs.

**Subject B, versus setting `strip = true`.** The recommendation gives up the single
largest measured size reduction available (−22.8%/−30.9%, roughly 0.45–0.71 MB per
archive, which `xz` compression will shrink further). It is accepted on the executed
evidence that stripping empties the backtrace entirely, and it is corroborated by the one
surveyed project that states a rationale: `nextest-rs/nextest` writes
`[profile.release] strip = "none"` with the comment "Ensure that symbols and debuginfo
aren't stripped. They're useful for debugging issues with nextest in the field, and don't
bloat up binaries too much" (`nextest-rs/nextest`, `Cargo.toml`, retrieved 2026-09-17) —
the same judgement, made by a project that ships to the same audience. The counter-practice
is recorded honestly: `uv`, `fd`, `bat` and `zoxide` all set `strip = true`.

**Subject B, versus a separate `dist`/`release-lto` profile.** The recommendation gives up
the ability to keep a contributor's local `cargo build --release` cheap while CI builds
aggressively — which is `dist`'s own stated reason for the split ("We define a separate
profile from `release` so that it can be tuned more aggressively for builds that are
longer or more resource-intensive without making it tedious to develop locally",
`book/src/reference/concepts.md`, `ref=v0.33.0`). It is accepted because the split's real
cost is *divergence*: two profiles means the binary CI ships was compiled differently from
the binary a contributor tested and from the binary `cargo install` produces, and nothing
in CI would catch a fat-LTO-only miscompilation or link failure. `ripgrep` takes the other
side of this trade (`[profile.release] debug = 1` plus a separate `[profile.release-lto]`
carrying `lto = "fat"`, `strip = "symbols"`, `panic = "abort"`), and that is a coherent
choice for a project with a benchmarking discipline; this template has none yet, and
`uv` and `ruff` — both of which *do* benchmark, and both of which run dist — nonetheless
keep `[profile.dist]` empty and put the settings in `[profile.release]`.

### Parameters

- This item has **no `owns:` entry** in its `## Couplings` block, and
  `docs/port/PARAMETERS.md` registers no parameter owned by R68. No `owns` line is
  written here; inventing a registry row would be a change to the registry this item is
  not authorised to make. The two decisions above are recorded as decision values, and
  if the controller wants either as a registry parameter that is a registry edit, not a
  research finding.
- `assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory — target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed — relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp; autobins = false; default-run unset; no build.rs. Packaged-file scope: an explicit [package] include allow-list — /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md. The optional web surface adds no target here (R49, accepted, published).`
  Two consequences are load-bearing here and are used above: the `--target` level
  (`target/<triple>/release/`) is where dist finds cross-compiled output, and the
  `rslbp` ≠ `rs-launch-blueprint` pair is what makes binstall's `{ bin }`-based
  `bin-dir` default the right one and the runner-up's `$bin-$target` archive name the
  wrong one.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed). Both recommended profile keys and every key deliberately left silent predate the resulting floor of `1.96` by many releases.
- `assumes rust-edition = 2024` (fixed). The probe was built at edition 2024 throughout.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed). The recommendation stays inside it by pinning `[dist.github-custom-runners]`, and excludes `aarch64-unknown-linux-gnu` rather than asking for an ARM runner.
- `assumes license = MIT OR Apache-2.0` (fixed). Recorded; not evaluated against any candidate, per the 2026-09-12 ruling.
- Related, not assumed (R69 is not in this item's `consumes` list): R69's accepted
  `web-extra-surface` adds `[[bin]] "<app>-serve"` with `required-features = ["web"]`.
  This item leaves dist's `features` at `[]` so that binary is not shipped in the release
  archives. Stated in prose rather than as an `assumes` line, because the couplings block
  does not consume it.
- **`CONFLICT:` lines: none.** No consumed parameter needs to change for this
  recommendation to hold. The one place a fixed parameter constrains the answer —
  `target-os-matrix` excluding an ARM Linux runner, and therefore
  `aarch64-unknown-linux-gnu` — is resolved by narrowing the target list, not by asking
  for the parameter to move.

### Migration implications

File-level changes in the template, each stated as a whole-file addition or a named edit:

1. **`Cargo.toml` — add, at the workspace root manifest only:**
   ```toml
   [profile.release]
   lto = "fat"
   codegen-units = 1
   ```
   Nothing else. No `strip`, no `panic`, no `debug`, no `opt-level`. Add a one-line
   comment recording that the omissions are deliberate, so a later contributor does not
   read silence as oversight.
2. **`Cargo.toml` — after running `dist init`, edit the stub it writes.** `dist init`
   writes `[profile.dist] inherits = "release"` **with `lto = "thin"`**
   (`book/src/reference/concepts.md`, `ref=v0.33.0`). **Delete that `lto` line** and keep
   the stub as `inherits = "release"` alone, matching `astral-sh/uv` and `astral-sh/ruff`.
   If this edit is skipped, the split profile this item argued against arrives by default
   *and* silently overrides `lto = "fat"` back down to `"thin"` for every released binary
   — which is precisely the outcome the measurement above rejects.
3. **`dist-workspace.toml` — new file** carrying the settings tabulated under
   `### Recommendation`: `cargo-dist-version`, `ci = "github"`,
   `targets` (three triples), `installers = ["shell"]`, `create-release = false`,
   `install-updater = false`, and `[dist.github-custom-runners]` pinning `global` and the
   Linux triple to `ubuntu-latest` and both Darwin triples to `macos-latest`.
4. **`.github/workflows/release.yml` — generated by `dist init`, committed, not
   hand-edited.** It triggers on the tag release-please pushes and uploads into the draft
   Release.
5. **`release-please-config.json` — set `"draft": true` and `"force-tag-creation": true`**
   on the released package. Both are required: `draft` so dist has a draft to fill, and
   `force-tag-creation` because, in release-please's own words, "By default, GitHub does
   not create a Git tag for draft releases until they are published"
   (`docs/manifest-releaser.md`, retrieved 2026-09-17) — and without the tag, dist's
   workflow never fires.
6. **No `[package.metadata.binstall]` block is added.** Recorded as a deliberate
   non-change, with the inference rules it relies on cited in `### Fit for this template`,
   so that a later contributor who "fixes" the missing block knows it was measured as
   unnecessary.
7. **`README.md` — F220's derived value:** document `cargo binstall rs-launch-blueprint`
   first, the installer-script one-liner second, and `cargo install --locked
   rs-launch-blueprint` third, plus one sentence stating that `[profile.release]` in this
   manifest governs this repository's own builds and `cargo install`, and is **not**
   inherited by a downstream application that depends on the library — because Cargo
   "only looks at the profile settings in the `Cargo.toml` manifest at the root of the
   workspace".
8. **Hand-offs, recorded rather than actioned.** To **R51**: the container image built by
   a plain `cargo build --release` inherits `[profile.release]` and therefore the fat-LTO
   link; if R51 adopts the reference's cargo-chef layering, the dependency-cook layer and
   the final build must use the *same* profile or the cache will miss. If a `dist` profile
   is ever reinstated, R51's Dockerfile must pass `--profile dist` or silently lose the
   settings. To **R50**: its install smoke test builds with `--debug`, so it does not
   exercise this profile at all — that is a correct scoping choice, and it means nothing
   in PR CI proves the release profile links until a release runs; a
   `cargo build --release` step somewhere in release CI is the cheap cover, and dist's own
   build jobs supply it. To **R22** (`runtime version accessor`): the installer script and
   the archive names encode the version, so whatever R22 picks must agree with the git tag
   release-please produces.

### Validation strategy

**Checks executed in this item** (results are reported above; commands are given so they
can be re-run):

1. `cargo build --release --offline --features web --config 'profile.release.<key>=<value>'`
   across 25 macOS configurations and 17 Linux configurations, each into a fresh
   `CARGO_TARGET_DIR`, with size recorded by `stat` and wall time by `/usr/bin/time -p`
   (macOS) and `date +%s.%N` (Linux). **Expected:** measurable, reproducible size deltas.
   **Observed:** sizes byte-identical across every rerun; timings with a 30% noise floor
   on macOS and an unusable 82% spread on Linux.
2. `cargo install --path . --root <scratch> --locked --no-track` with
   `[profile.release] lto = "fat"` / `codegen-units = 1` written into `Cargo.toml`.
   **Expected:** if `cargo install` honours the package's own profile, the installed
   binary equals the `fat`+`cu=1` build. **Observed:** 1 470 416 bytes, exactly equal;
   the default-profile build of the same source is 1 987 552 bytes.
3. `RUST_BACKTRACE=1 ./rslbp panic` against binaries built at four profiles, on both OSes,
   plus one run with the binary copied out and `target/` deleted. **Expected:** `strip`
   and `debug` change what a user can see. **Observed:** the table under
   `### Recommendation`; `strip = "symbols"` yields zero frames; macOS line-tables do not
   travel outside `target/`.
4. Exit-status capture on panic. **Expected:** unwind and abort differ. **Observed:** 101
   versus 134.
5. Registry and repository figure collection at the endpoints named in
   `## Required evidence`, plus a RustSec control (`time`, `openssl`, `chrono` → HTTP 200;
   `cargo-dist`, `cargo-binstall` → HTTP 404) establishing that 404 means "no advisory
   page", not "fetch failed".
6. The 18-project adoption census and the 9-project release-profile census, both read from
   `raw.githubusercontent.com` at HTTP 200.

**Checks proposed for the implementation phase** (not run here; no Rust source tree exists):

7. `cargo dist plan --output-format=json` in CI on every PR that touches
   `dist-workspace.toml`. **Expected:** exit 0 and a manifest naming exactly three
   archives and one installer; a fourth artifact or a missing one fails the job.
8. After a release, `gh api repos/<o>/<r>/releases/tags/v<X.Y.Z> --jq '.assets[].name'`
   asserted against the expected set, and `.draft == false`. **Expected:** three
   `rs-launch-blueprint-<triple>.tar.xz` archives, their `.sha256` sidecars,
   `sha256.sum`, `rs-launch-blueprint-installer.sh`, `dist-manifest.json`; undrafted.
9. `cargo binstall --no-confirm --dry-run rs-launch-blueprint` on `ubuntu-latest` and
   `macos-latest` after the release. **Expected:** the resolved strategy is
   `crate-meta-data` (the project's own Release assets), not `compile` — which is AC2,
   and the only check that proves binstall's inference actually matched the archive names.
10. A profile guard: assert that `cargo read-manifest`-visible `[profile.dist]` carries no
    key other than `inherits`, so a future `dist init` re-run cannot silently restore
    `lto = "thin"`. **Expected:** exit 0; a regenerated stub fails the check.
11. On the release binary, one `RUST_BACKTRACE=1` run of a deliberately panicking
    subcommand asserted to print at least one frame containing `rs_launch_blueprint`.
    **Expected:** non-empty backtrace — the executable form of the reason `strip` is
    left silent.

Checks 7–11 are **proposals**; 1–6 are **executed results**.

### Confidence & re-verify trigger

**Confidence.** *Subject B: high.* The values are settled by measurement this item
produced on both OSes of the fixed matrix, the sizes reproduce byte-for-byte, the
directional claims (fat > thin; `"s"`/`"z"` larger, not smaller; `strip` empties the
backtrace; Linux embedded DWARF versus macOS split debuginfo) all agree across the two
hosts, and the two build-time claims that are asserted survive an explicitly stated 30%
noise floor. The one acknowledged weakness is the stand-in: a 47/81-crate probe with no
real domain logic will under-state absolute sizes, though percentages should hold.

*Subject A: medium-high on the shape, medium on the tool.* The shape — ship both the
`.crate` and cross-compiled Release binaries, in follower mode behind release-please — is
strongly supported: it is the only arrangement that satisfies AC1, AC2 and AC5 together,
and every mechanism it depends on was read at a primary source (`create-release = false`,
`draft`, `force-tag-creation`, binstall's inference rules). The *tool* carries the
`at-risk` verdict argued above, and that is the residual risk.

**Re-verify triggers, each with the observation that fires it:**

1. **`cargo-dist`'s registry gap closes or widens.** Re-run
   `GET https://crates.io/api/v1/crates/cargo-dist` and compare `max_stable_version`
   against the newest non-prerelease GitHub tag. If a second release lands on GitHub
   without reaching crates.io, promote `at-risk` to a decision to move to the runner-up.
   If `0.33.0` (or later) appears on crates.io and the unanswered-issue sample improves,
   re-verify the maintenance state upward. **Check no later than the template's second
   release.**
2. **The unanswered-issue sample.** Re-run the 10-issue responsiveness probe on
   `axodotdev/cargo-dist`. 10 of 10 unanswered was the sample on 2026-09-17; a repeat
   result after six months, combined with any dist bug the template actually hits, is the
   condition under which the runner-up wins.
3. **`dist init` regenerating `[profile.dist]`.** Any `dist` version bump. Proposed check
   10 exists for exactly this: a regenerated `lto = "thin"` would silently revert the
   measured recommendation.
4. **`cargo-zigbuild`'s trajectory** (90-day 1 544 669 on 2026-09-17). If the template
   ever wants `aarch64-unknown-linux-gnu` or a musl target without adding an ARM runner —
   i.e. without touching `target-os-matrix` — re-verify whether dist's
   `github-build-setup` can host it.
5. **Any change to R49's `[[bin]]` name or to the package name.** The whole
   zero-configuration binstall result rests on the `rslbp` / `rs-launch-blueprint` pair
   matching binstall's `{ bin }` / `{ name }` defaults; changing either re-opens the
   metadata question.
6. **A new stable Rust changing a profile default.** Re-read the profiles chapter's
   default blocks for `release` (currently `opt-level = 3`, `debug = false`,
   `strip = "none"`, `lto = false`, `panic = 'unwind'`, `codegen-units = 16`).
   Re-verify at each MSRV floor raise, which the `msrv-policy` schedules anyway.

### Sources

Primary specifications and maintainer documentation:

- The Cargo Book, *Profiles* — `https://doc.rust-lang.org/cargo/reference/profiles.html` (retrieved 2026-09-17). Source of every documented default, the `lto = false` "thin local LTO" definition, `strip`'s "The default is `none`", the `debug` MSRV note ("MSRV: 1.71 is required for none, limited, full, line-directives-only, and line-tables-only"), the `split-debuginfo` "default value for this option is unpacked on macOS" rule, the `panic`+tests rule, the workspace-root-only rule, the custom-profile `inherits` rule and the override precedence list.
- The Cargo Book, *cargo-package(1)* — `https://doc.rust-lang.org/cargo/commands/cargo-package.html` (retrieved 2026-09-17). "This command will create a distributable, compressed `.crate` file with the source code of the package".
- `dist` book at `ref=v0.33.0`, read through the authenticated GitHub contents API (retrieved 2026-09-17): `book/src/reference/config.md` (`create-release`, `targets`, `features`/`default-features`/`all-features`, `binaries`, `github-custom-runners`, `github-release`, `dispatch-releases`, `tag-namespace`), `book/src/reference/concepts.md` (the generated `[profile.dist] inherits = "release" / lto = "thin"` and its stated rationale), `book/src/installers/other.md` (cargo-binstall auto-detection; `cargo install` uses `--release` and "disrespects your lockfile unless you pass `--locked`"), `book/src/ci/index.md`. Rendered book confirmed live at `https://axodotdev.github.io/cargo-dist/book/` (HTTP 200); the previously advertised `https://opensource.axo.dev/cargo-dist/book/` returns `NXDOMAIN`.
- `axodotdev/cargo-dist`, `cargo-dist/src/backend/ci/github.rs` at `ref=v0.33.0` (retrieved 2026-09-17) — `DEFAULT_LINUX_RUNNER = "ubuntu-22.04"` and `github_runner_for_target`'s map to `ubuntu-22.04-arm`, `macos-14`, `macos-15-intel`.
- `cargo-bins/cargo-binstall`, `SUPPORT.md` and `README.md`, default branch (retrieved 2026-09-17) — the `Defaults` section's `bin-dir` directory list and `"{ bin }{ binary-ext }"` rule, the GitHub `pkg-url` path/filename product including the versionless `{ name }-{ target }{ archive-suffix }` form, the template-variable list, and the `disabled-strategies` key.
- `taiki-e/upload-rust-binary-action`, `README.md` (retrieved 2026-09-17) — input table: `archive` default `$bin-$target`, `profile` default `release`, `tar` default `unix`, `leading-dir` default `false`.
- `googleapis/release-please`, `docs/manifest-releaser.md` (retrieved 2026-09-17) — `"draft": true` and `force-tag-creation` with its stated reason.
- Source repositories at their programme pins: `git -C ~/c/py-launch-blueprint show b08bccfb:.github/workflows/ci.yml` lines 215–222 (`uv build`; `twine check dist/*`; `uvx --from "$(ls dist/*.whl)" plbp --version`) and `:README.md` line 45 (`uvx --from py-launch-blueprint plbp` / `pip install py-launch-blueprint && plbp`); `git -C ~/c/ts-launch-blueprint show cb1cbcb2:package.json` lines 20–23 (`"files": ["dist"]`, `"type": "module"`). Both read at the pin, never from the working tree.
- This repository: `docs/port/PARAMETERS.md` (the four fixed parameters; R49's `build-tool-output-shape`; R69's `web-extra-surface`; R67's `error-taxonomy-exit-codes`); `docs/port/COMMONALITY.md` rows F214 (:218), F220 (:224), F221 (:225), F223 (:227), F063–F077 (:69–:83, including F072's `actions/create-github-app-token v3.2.0` and F073's "push opens PR, merge tags"), F103 (:109), F190 (:194); `docs/port/OWNER-REVIEW.md` §*"2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)"* (:47) and §*"2026-09-16 — Release build profile ownership: R68 (W0-R69p)"* (:136); `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, section *Reference `Cargo.toml`* and *Details* → C14/C15; `research/topics/49-build-target-declaration/DECISION.md` revision 8; `research/topics/69-web-framework-stack/DECISION.md` revision 9 (row 11 of its reconciliation, the hand-off that created this item's second subject); `research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/DECISION.md` revision 1 (the `--debug` install check); `research/topics/67-error-and-exit-code-contract/DECISION.md` (the crash-record scope and the F301 gap).

Figure endpoints (all retrieved 2026-09-17): `GET https://crates.io/api/v1/crates/<name>` and `/versions` for `cargo-dist`, `cargo-binstall`, `cross`, `cargo-zigbuild`, `cargo-xwin`, `cargo-quickinstall`, `axoupdater` (User-Agent header sent); `GET https://api.github.com/repos/<o>/<r>` for `axodotdev/cargo-dist`, `cargo-bins/cargo-binstall`, `taiki-e/upload-rust-binary-action`, `cross-rs/cross`, `rust-cross/cargo-zigbuild`, `houseabsolute/actions-rust-cross`; `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the open-issue counts; `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue&sort=created&order=desc&per_page=10` plus `GET /repos/<o>/<r>/issues/<n>/comments` for responsiveness; `GET https://api.github.com/repos/axodotdev/cargo-dist/releases` and `/releases/tags/v0.33.0`; `https://rustsec.org/packages/<name>.html`.

Manifests read for the release-profile practice census (all `raw.githubusercontent.com`, HTTP 200, retrieved 2026-09-17): `astral-sh/uv` (`[profile.release] strip = true, lto = "fat", panic = "abort"`; `[profile.dist] inherits = "release"` with no keys); `astral-sh/ruff` (`lto = "fat"`, `codegen-units = 16` with per-package `codegen-units = 1` overrides; `[profile.dist] inherits = "release"` with no keys); `BurntSushi/ripgrep` (`[profile.release] debug = 1`; separate `[profile.release-lto]` with `lto = "fat"`, `strip = "symbols"`, `panic = "abort"`); `sharkdp/fd` and `sharkdp/bat` (`lto = true`, `strip = true`, `codegen-units = 1`); `casey/just` (`lto = true`, `codegen-units = 1`); `crate-ci/typos` (`panic = "abort"`, `codegen-units = 1`, `lto = true`, `debug = "line-tables-only"`); `ajeetdsouza/zoxide` (`codegen-units = 1`, `debug = 0`, `lto = true`, `strip = true`); `nextest-rs/nextest` (`strip = "none"`, with its stated rationale); `jj-vcs/jj` (`strip = "debuginfo"`, `codegen-units = 1`).

**Method notes.** Endpoints queried: crates.io `/api/v1/crates/<name>` and
`/api/v1/crates/<name>/versions` (User-Agent header sent) and one direct version probe
`/api/v1/crates/cargo-dist/0.33.0`; GitHub REST `/repos/<o>/<r>`,
`/repos/<o>/<r>/releases`, `/repos/<o>/<r>/releases/tags/<tag>`,
`/repos/<o>/<r>/contents/<path>[?ref=<tag>]`, `/repos/<o>/<r>/commits`,
`/repos/<o>/<r>/contributors`, `/repos/<o>/<r>/issues/<n>/comments` and
`/search/issues?q=…` (authenticated `gh api`; no token or environment was printed);
`rustsec.org/packages/<name>.html`; `doc.rust-lang.org/cargo/reference/profiles.html` and
`/commands/cargo-package.html`; `raw.githubusercontent.com` for third-party manifests;
Docker Hub for the pinned `rust:1.98.0-slim-bookworm` image. **Two method corrections are
on the record rather than hidden.** First, an adoption census run through
`gh api repos/<o>/<r>/contents/<path>` reported all 18 projects as `dist` users; `gh api`
prints the 404 body to stdout, so the presence test was vacuously true. The census was
re-run keying on the HTTP status of `raw.githubusercontent.com` and the corrected result
(3 of 18) is what this report uses. Second, the first Linux matrix run reported `FAIL` for
all 17 rows because `/usr/bin/time` is absent from the Debian slim image; the timer was
replaced with `date +%s.%N` and the matrix re-run, and no figure from the failed run
appears here. **What could not be verified.** (a) No measurement was taken on
`ubuntu-latest`'s actual architecture: the Linux rows are `linux/arm64` inside a Docker
Desktop VM on Apple Silicon, whereas `ubuntu-latest` is `x86_64` on a bare runner —
Linux *sizes* are reported as evidence of the glibc/ELF behaviour and the direction of
each delta, and Linux *wall times* are reported as non-evidence and used for nothing (the
baseline and its byte-identical rerun differed by 82%). (b) No `x86_64` binary of any kind
was built, so every absolute byte count is for an `aarch64` target. (c) `dist` was never
executed: its behaviour is taken from its documentation and source read at `ref=v0.33.0`,
and the release-please → dist hand-off is assembled from both projects' documentation —
**neither project documents the other**, so that pairing is a reasoned composition of two
documented mechanisms, not a documented integration, and proposed checks 8 and 9 exist to
prove it in the implementation phase. (d) `cargo-binstall`'s inference was not exercised
against a real release; the zero-metadata claim rests on its `SUPPORT.md` defaults plus
dist's own statement and the observed `cargo-dist-<triple>.tar.xz` asset names, and
proposed check 9 is the executable form of it. (e) `unsafe` posture was not measured for
any candidate, because none of them is a dependency of the template or is linked into any
shipped artifact; gate 3's advisory half was answered at `rustsec.org` with a control.
(f) The probe is a stand-in, not the template: 47 crates at default features and 81 with
`--all-features`, no domain logic, no config layering, no observability — absolute sizes
are floors and percentages are the transferable figures. (g) `cargo install` was verified
to honour the package's own `[profile.release]` by size equality against a
locally-built binary, not by inspecting the compiler invocation. The probe directory was
deleted after the run.
