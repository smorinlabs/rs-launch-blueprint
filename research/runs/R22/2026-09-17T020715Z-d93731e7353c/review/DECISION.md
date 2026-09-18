# 2026-09-18 — R22 — runtime-version-accessor (pattern, Light) — decision (revision 1)

## Decision

**Recommendation: one public compile-time constant, declared once in the library
crate and read by every surface that reports the version.**

```rust
// src/lib.rs -- the single accessor. Cargo injects CARGO_PKG_VERSION from
// [package] version when this crate is compiled; env! expands it to a
// &'static str at that moment.
/// The version of this package, from `Cargo.toml`.
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
```

The CLI's `--version`/`-V`, any diagnostics output, and the optional web
surface's health/status response all read `rs_launch_blueprint::VERSION`. **No
accessor crate, no `build.rs`, no generated module, and no runtime metadata
lookup.** The mechanism is a language feature plus a Cargo-injected variable;
nothing is added to the dependency graph.

**Where it goes.** `src/lib.rs`, because R49's published `build-tool-output-shape`
fixes exactly one `[lib]` target at `src/lib.rs` with crate name
`rs_launch_blueprint`, and exactly one `[[bin]]` at `src/main.rs` named `rslbp`
(`## Parameters`). If the constant is ever moved into a private module, the
crate root re-exports it, so `rs_launch_blueprint::VERSION` stays the one path
every call site names.

**This answers F064 in the ts direction on timing and in a Rust-native way on
mechanism.** py resolves at runtime because Python has an installed-package
registry to interrogate; ts resolves at build time because a bundler can inline
a manifest field. Rust has no installed-package registry to interrogate at all —
a Rust library is compiled into its consumer's binary, not installed beside it —
so the py shape has no Rust implementation to choose, and the ts shape has a
first-party one.

**Ledger rows.** This decision settles **F064** — *runtime version accessor*,
`release-versioning`, origin `different`, verdict `DIVERGENT`, item `R22`
(`docs/port/COMMONALITY.md:70`; assertion A8a). Two neighbouring rows are
**confirmed, not amended**:

| Row | What it says | This decision's effect |
|---|---|---|
| **F063** *version source of truth*, `COMMON → REUSE`, no item (`COMMONALITY.md:69`, A8b) | `Cargo.toml`'s `[package] version` is the single authored value | confirmed — the recommended accessor derives from that field and adds no second authored copy |
| **F133** *test asserting the version stays single-sourced across manifests*, `COMMON → REUSE`, no item (`COMMONALITY.md:139`, A8c–A8d) | the accessor-equality assertion stays, "and its mechanism follows R22" | confirmed, and now supported by measurement rather than by argument — see the F133 paragraph below |
| **F267** *extended version output*, `DIVERGENT`, item `R60` (`COMMONALITY.md:271`, A8f) | whether `--version` also prints target triple and `rustc` version | untouched; out of scope by this item's prompt |

**No `BASELINE-REVIEW:` finding is raised.** The raw report raised one against
F133 proposing that the accessor-equality assertion be retained. That is already
the ledger's recorded state: the 2026-09-04 baseline review heard the opposite
challenge — that the assertion "cannot fail" — and **rejected** it
(`docs/port/BASELINE-REVIEW.md`, "F133 finding unsupported (accessor test cannot
fail) | Accepted: an accessor wired to a literal or the wrong package is
catchable | Assertion retained"; assertion A8e). Raising it again would restate
a settled row. What this item adds instead is evidence: the assertion was
retained on an argument, and `## Empirical check` row E1 now shows it failing on
demand (checks C6b–C6d and C7a–C7b).

**Status of this document.** Every decision in this programme is a **proposal
validated in the implementation phase** (owner ruling, 2026-09-10). It records
what the research found and what it recommends. **Nothing was built here.** The
`rs-launch-blueprint` template does not exist; P03 builds it, and P03's CI proves
this recommendation. The probes under `## Empirical check` are throwaway packages
created under `$TMPDIR` and deleted on exit — they measure how `env!`,
`option_env!`, Cargo features and workspace members behave, they are not a
template scaffold, a seam, or a fixture set. What P03 must validate is listed
under `## Engines`. A decision that does not survive implementation is revised
against this recorded research rather than researched again from scratch.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B):
licence compatibility is not evaluated for any dependency or tool`**
(`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check for anything the
template uses"). The row is kept, not deleted, because this item's binding prompt
still lists the gate and requires a stated `inapplicable` with its reason rather
than a silent omission. Licences are still recorded as figures in the candidate
table below and **exclude nothing**. The recommended mechanism adds no
dependency, so no third-party licence is implicated by it at all.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** Every version a user or operator can see traces to exactly one
authored value. The owner stated it directly on 2026-09-04: *"We want to use the
same principle. The principle is that all versions have a single source of
truth"* (`inputs/prompt.md`, `## Context`). The agreement level is an
**architectural pattern**, not a capability, a standard or a tool: py and ts
already realise it with unlike mechanisms — py reads installed distribution
metadata at import time (`py: src/py_launch_blueprint/__init__.py:24`), ts imports
`package.json` and lets the bundler inline the field (`ts: src/version.ts:6`) —
and both satisfy the principle. What must agree is that there is one authored
value and one accessor; what may vary is when and how the value is bound.

**Essential behaviors.**

1. `Cargo.toml`'s `[package] version` is the only place a human writes the
   version. release-please edits that field (F063).
2. Exactly one symbol in the codebase evaluates to it. No call site writes a
   version literal and no call site derives one independently.
3. The value an artifact reports is **the artifact's own identity** — what it was
   built from — not what a file sitting next to it happens to say.
4. The value is SemVer with no leading `v`, so the CLI's output conforms to the
   org CLI Design Standard R4.6 (see below).
5. Enabling or disabling the optional `web` feature cannot change the value.
6. A drifted accessor is caught by a test, not by review.

**Observable acceptance criteria**, each one a test P03 can write:

| AC | Assertion | Proven achievable here by |
|---|---|---|
| AC1 | `rs_launch_blueprint::VERSION == env!("CARGO_PKG_VERSION")` in an integration test of the package | C6a |
| AC2 | that test **fails** when `VERSION` is replaced by a stale literal | C6b, C6c, C6d |
| AC3 | `rslbp --version`, diagnostics and the web health/status body print the same string, and that string is `VERSION` | C1, C5b (one value, one symbol, feature-invariant) |
| AC4 | building with and without `--features web` yields a byte-identical version | C5a, C5b |
| AC5 | the reported string matches `^\d+\.\d+\.\d+` with no leading `v` | C9a, C9b, C9c — Cargo refuses to parse a manifest whose `version` carries a leading `v`, so the value cannot acquire one |
| AC6 | the shipped binary reports its version with no `Cargo.toml` and no package metadata anywhere on disk | C4a, C4b |

AC1–AC6 are **proposed** checks for P03. None of them has been run against the
template, because the template does not exist. What has been run is the
underlying mechanism, on throwaway packages, and the check ids above name the
rows in `## Empirical check` that did it.

**The architectural alternatives, compared before any library.** There are four
ways to get a version into a running Rust artifact, and only the first two are
genuinely distinct architectures:

| Architecture | When the value is bound | What it costs | Verdict |
|---|---|---|---|
| **A. Compile-time, from Cargo's own variable** — `env!("CARGO_PKG_VERSION")` | while the crate compiles | nothing: no dependency, no build script, no I/O | **selected** |
| **B. Compile-time, from a generated module** — a `build.rs` emitting `cargo::rustc-env` or writing a file into `OUT_DIR`, as `built`, `vergen-gix` and `shadow-rs` do | while the crate compiles | a build script, a generated-code surface, and a dependency tree | rejected for the **base version**; it is the right shape for *provenance*, which is R60's |
| **C. Runtime, from a file beside the artifact** — parse a `Cargo.toml`, a sidecar, or a registry directory at startup | while the program runs | an invented convention, file I/O on a hot path, and a failure mode with no correct answer | rejected |
| **D. Runtime, from an installed-package registry** — py's `importlib.metadata.version()` | while the program runs | **has no Rust implementation** | not available |

Architecture B is **not** a runtime lookup and it is worth saying so explicitly,
because it is easy to file it opposite A. The Cargo Book's own description of
`cargo::rustc-env` is that "the value can be then retrieved by the `env!` macro
in the compiled crate" (assertion A6h): a build script moves *where the string
comes from*, never *when it is bound*. So the real question this item decides is
A versus C/D — compile-time versus runtime — and B is a variant of A that buys
extra fields at the price of a build script.

**Architecture D is unavailable, not merely unattractive, and the reason is
structural.** `importlib.metadata.version()` answers "what version of the
distribution named X is installed in *this interpreter's environment*". Rust has
no such environment at runtime: a library is compiled into its consumer's binary
and leaves no installed record behind, and a `cargo install`ed binary, a release
archive, a container layer and a cross-compiled artifact all ship without the
manifest they were built from. Check C4b makes that concrete rather than
assumed — a binary copied into a directory holding no `Cargo.toml` and no
`.rlib` still reports its version correctly, because there is nothing for it to
look up and nothing it needs to.

**The one py capability that has no `env!` analogue, stated as a limit rather
than argued away.** A runtime lookup can report the version of something the
process learned about *after* it was compiled — a dynamically loaded plugin, or
a sibling distribution in the same environment. `env!` cannot do that, and no
arrangement of it can. This template has no such surface: R01's driven-I/O seam
is a compile-time Rust trait erased to `Arc<dyn ProjectsPort>` at the composition
root, not a loader, and nothing in the CLI, library or web shape loads code at
runtime. **If P03 ever adds a plugin surface, this decision does not cover the
plugin's version and must be revisited** — that is on the `re-verify:` line.

**Why the selected design preserves each principle.** Principle 2 (one symbol) is
preserved by putting the constant in the library crate rather than in the CLI
crate: R49 fixes one `[lib]` and one `[[bin]]` in one package, R69 adds the web
surface as an additive Cargo feature on the crate that hosts the binaries, and a
library constant is visible to all three. Principle 3 (the artifact's own
identity) is preserved because the value travels *inside* the artifact — measured
at C3a/C3b, where a binary built before a manifest edit keeps reporting its own
version while the edited manifest sits in the same directory. Principle 5
(feature invariance) is preserved because a Cargo feature changes which items
compile, not which package is being compiled — measured at C5a/C5b. Principle 6
(caught by a test) is the F133 paragraph below.

**The web surface, specifically, because the prompt asks.** R69's published
`web-extra-surface` makes `web` an additive, off-by-default feature on the same
package, adding one `[[bin]]` with `required-features = ["web"]` beside the CLI
binary. Both binaries are compiled from one package and therefore carry one
string; the feature cannot move it (C5b). The staleness the prompt asks about is
real but is not an accessor problem: an old process can still be running after a
new artifact is published. A runtime lookup does not fix that — the old process
would read whatever manifest the host presents, which is either the same value it
already has or a *different artifact's* value, and reporting another artifact's
version from a health endpoint is strictly worse than reporting your own. Health
output must describe the running artifact. **This paragraph is a reasoned
conclusion resting on C3 and C4, not on a deployment experiment; no service was
deployed in this run.**

**Do any of the accessor crates earn a place? No, and the gate verdicts had to be
re-derived to say so correctly.** The fitness gates were applied per candidate
before popularity. Figures are from the required endpoints, snapshotted 2026-09-18
(`review/evidence/snapshots/`, hash-verified at A1a) and re-checked live the same
day (`r22-live-recheck.log`).

| Candidate | 90-day / all-time downloads | Newest non-yanked | Declared `rust-version` | Gate 2 (MSRV floor 1.96) | Gate 3 (advisories) | Gate 5 (defaults) | Verdict |
|---|---|---|---|---|---|---|---|
| **`env!("CARGO_PKG_VERSION")`** | `inapplicable — a language macro and a Cargo-injected variable, not a crates.io package` | n/a (ships with the toolchain) | n/a | **pass** — no crate, so nothing to floor | **pass** — nothing to advise against | n/a | **selected** |
| `clap` version paths | see R60 (`clap 4.6.6`, already in the stack for the CLI binary) | 4.6.6 | 1.85 (R60) | pass | pass | `crate_version!` needs the non-default `cargo` feature | **not a separate option** — both paths *are* `CARGO_PKG_VERSION`; see below |
| `built` | 18,238,136 / 63,168,750 | 0.8.1, 2026-05-21 | **1.87** | **pass** — 1.87 is *below* the floor, which is headroom | **pass** — no RustSec page | default features empty; metadata features add `git2`/`gix`/`chrono`/`semver` | rejected **on fit**, not on a gate |
| `vergen-gix` | 546,530 / 2,035,682 | 10.0.3, 2026-08-24 | **1.96.0** | **pass**, with **zero headroom** — it sits exactly on the floor | **pass** — no RustSec page | defaults empty; requires a `build.rs` | rejected on scope — it is R60's provenance tool, not a base-version source |
| `shadow-rs` | 2,184,341 / 10,812,524 | 2.0.0, 2026-04-23 | **none declared** | not established — an undeclared `rust-version` is not itself a failure | **FAIL on the dependency tree** | defaults include `git2` and `build` | **excluded by gate 3** |

Licences, recorded as figures and excluding nothing (gate 1 inapplicable):
`built` MIT; `vergen-gix` `MIT OR Apache-2.0`; `shadow-rs` `MIT AND Apache-2.0`
(A3a–A3c). Gate 4 (`ubuntu-latest, macos-latest`): the selected mechanism is a
`rustc` macro, so it works wherever `rustc` does; the probes in
`## Empirical check` ran on `macos-latest`-class hardware (Darwin arm64) and the
mechanism is target-independent — **no Linux run was made in this session**, and
that is recorded as unproven under `## Engines`. Gate 6 (binary size, compile
time): `env!` contributes one `&'static str` in read-only data and no code; the
three crates add a build script, a generated module and a dependency tree. **No
size or timing measurement was taken**, so this is a qualitative statement and
nothing stronger.

**The `shadow-rs` exclusion, stated precisely.** `shadow-rs` itself has **no**
RustSec advisory — `https://rustsec.org/packages/shadow-rs.html` returns 404, and
404 on that path means *no advisory on record*, not *status unknown*: the site
publishes a package page only for a crate that has at least one advisory, which
the live re-check establishes with controls in both directions (`serde` → 404,
`tokio` → 200, `git2` → 200; log `r22-live-recheck.log`, checks `L1-serde`,
`L1-tokio`, `L1-git2`). Its **default feature set** pulls `git2 ^0.20.0`, which
resolves to `git2 0.20.4`, and `git2` *does* have a package page listing
**RUSTSEC-2026-0183** and **RUSTSEC-2026-0184** (A4a, A4b). The project's own
open issue #262, *"Upgrade git2 to >= 0.21 to fix RUSTSEC-2026-0183/0184 unsound
advisories"*, records that the `^0.20.0` pin prevents downstream consumers from
upgrading past it (A4c–A4e). Gate 3 covers the crate *and* its dependency tree,
so this is a genuine gate failure — but it is a failure of the tree, not of the
crate, and the decision says which.

**`clap` is a spelling of the recommendation, not an alternative to it — verified
in clap's source rather than inferred from its documentation.** R60 selected
`clap 4.6.6` with features `derive`, `env`, `wrap_help` for the CLI binary, so
"just use clap's version support" is the obvious competing answer and it had to
be read at source. Both clap paths bottom out in the same variable:

- `clap::crate_version!()` is declared at `clap_builder/src/macros.rs:16` and its
  **entire body** is `env!("CARGO_PKG_VERSION")` (`:18`), behind
  `#[cfg(feature = "cargo")]` (`:14`) — a feature R60's selected set does **not**
  enable (A6a–A6c).
- `#[command(version)]` in the derive front end reaches
  `Method::from_env(attr.name.clone(), "CARGO_PKG_VERSION")`
  (`clap_derive/src/item.rs:554`), and `from_env` does `match env::var(env_var)`
  (`:1272`) in the proc-macro process, baking the result in as a string literal
  (A6d, A6e). The `clap_derive` snapshot is a **numbered excerpt** — only the two
  cited regions, each line carrying its original line number — because the full
  file's copyright header carries the maintainers' personal email addresses,
  which are not committed here (A6e2 asserts the excerpt holds none).

Both are compile-time and both read the same value. The difference that decides
the design is **scope**: either clap path binds the value inside the *CLI crate*,
where the library and the web module cannot see it, which would leave the health
endpoint to re-derive its own. So the library constant is the sharing mechanism
and clap consumes it explicitly —
`#[command(version = rs_launch_blueprint::VERSION)]` — which also avoids adding
clap's `cargo` feature to R60's argued-for set. This is a note on how R60's
already-decided wiring is fed, not a re-decision of it.

**F133's accessor-equality test, and why it is not vacuous.** The 2026-09-04
baseline review rejected the claim that the assertion cannot fail, on the ground
that "an accessor wired to a literal or the wrong package is catchable". This run
measured both failure modes:

- **Wired to a literal.** With `pub const VERSION: &str = "0.0.0";` and
  `Cargo.toml` at `1.2.3`, `cargo test` exits **101**, names
  `accessor_matches_cargo_package_version`, and prints the drifted literal
  (C6b–C6d). With the accessor correct, the same test passes (C6a).
- **Wired to the wrong package.** In a two-member workspace with `verlib` at
  `0.1.0` and `verbin` at `0.2.0`, a binary printing both `verlib::VERSION` and
  its own `env!("CARGO_PKG_VERSION")` prints `lib=0.1.0 bin=0.2.0` — each crate's
  macro expands to **its own** package's version, so a re-export from the wrong
  member is directly observable (C7a, C7b).

The Rust analogue of `tests/meta/test_version_consistency.py:56` and
`tests/version.test.ts:11` is therefore `tests/version_consistency.rs` in the
package, asserting `rs_launch_blueprint::VERSION == env!("CARGO_PKG_VERSION")`.
Its scope is **the accessor half only**. The manifest half of F133 —
`Cargo.toml` against `.release-please-manifest.json` — and the lockfile half,
live only if **R23** requires the sync, are separate assertions belonging to
those rows, and this decision does not fold them in.

**Practice evidence, at pinned commits.** Two maintained, well-regarded Rust
projects were read at resolved commit ids rather than at a moving branch, so the
citations survive the next push:

- **Apache Arrow** (`apache/arrow-rs`, 3,613 stars, not archived, pushed
  2026-09-18) exports its public version constant directly:
  `arrow/src/lib.rs:412` at commit `d506e145f42169e9c188b627f341da499bf09859` is
  `pub const ARROW_VERSION: &str = env!("CARGO_PKG_VERSION");`, and that is the
  file's **only** mention of the variable (A5b, A5c). It is a relevant reference
  because it is a library consumed by other crates, which is this template's
  library shape.
- **rav1e** (`xiph/rav1e`, 4,151 stars, not archived, pushed 2026-09-18) at
  commit `31435de9d76fddd38f6dcc31d4014574cebb2092` practices **exactly the split
  this decision recommends**: `src/lib.rs:216` gives `version::short()` as
  `env!("CARGO_PKG_VERSION").to_string()` — the base version, always from Cargo —
  while git provenance arrives separately through a generated module included at
  `:54` (`include!(concat!(env!("OUT_DIR"), "/built.rs"));`) and is gated behind
  its own `git_version` Cargo feature (A5d–A5g). A project that ships both, and
  keeps them apart, is stronger evidence for the layering than a project that
  ships only one.

**Reference implementation for P03**, minimal and realistic:

```rust
// src/lib.rs
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

// tests/version_consistency.rs  (F133's accessor half)
#[test]
fn accessor_matches_cargo_package_version() {
    assert_eq!(rs_launch_blueprint::VERSION, env!("CARGO_PKG_VERSION"));
}

// src/main.rs -- R60 owns the clap wiring; this is only how the value reaches it
#[derive(clap::Parser)]
#[command(name = "rslbp", version = rs_launch_blueprint::VERSION)]
struct Cli { /* R60's grammar */ }
```

**Conformance to the org CLI Design Standard v1.4.14** (blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7`). R4.1 `(MUST)` puts `--version`/`-V`
in the required global core (A7a) and R4.6 requires the version value to be
"SemVer without a leading `v`" (A7b). The recommended accessor satisfies R4.6
**structurally**: the value is the manifest field, and Cargo refuses to parse a
manifest whose `version` is `v0.1.0` while accepting the same manifest with
`0.1.0` and nothing else changed (C9a–C9c). AC5 still asserts it observably
rather than resting on that argument alone. R60 has already decided the surface
that prints it, and its JSON version object already sources its `version` field
from `CARGO_PKG_VERSION` (A10e), so this decision confirms R60's assumption
rather than disturbing it; R60's re-verify trigger fires only "if R22 …
chang[es] where the version value comes from" (A10f), and it does not.

**Performance.** The workload is three or more short formatting or serialization
paths per process or request. The accessor contributes a `&'static str` load: no
syscall, no allocation, no parsing, no lock. Formatting and JSON serialization
dominate it by orders of magnitude. **No latency, throughput, binary-size or
compile-time measurement was taken in this run**, so no absolute ranking is
claimed against the three crates — only the structural statement that a build
script and a dependency tree cost more than a macro that is already in the
language.

re-verify: 2027-03-18, or earlier on any of — **R02 (`crate-boundary-enforcement`,
still `open`) selecting a multi-crate workspace**, which makes "which package's
version" a live question and turns C7's measured behaviour from a demonstration
into a requirement (the constant then lives in the library package and members
inherit through `[workspace.package] version` with `version.workspace = true`);
**R23 (`lockfile-version-sync`) requiring a `Cargo.lock` comparison**, which adds
a second assertion to F133's suite without changing this accessor; **R49
republishing `build-tool-output-shape` with more than one package or with a
`build.rs` for the package's own targets**; **R60 changing where `--version`
sources its base value** (today it takes it from `CARGO_PKG_VERSION`, A10e);
**P03 adding any surface that loads code at runtime** — a plugin host, a
`dlopen`ed extension — because this decision covers only the versions of crates
compiled into the artifact and explicitly does not cover a dynamically loaded
one; or **Cargo changing the `CARGO_PKG_VERSION` contract**, detectable by
re-running `bash review/evidence/r22-cargo-probe.sh`, whose checks C1 and C2b
fail the moment the variable stops tracking `[package] version`. Two live-source
triggers are made executable in `review/evidence/r22-live-recheck.sh`: check `L3`
fails when Rust stable moves off `1.98.1`, which moves the MSRV floor off 1.96
and re-opens every gate-2 verdict in the candidate table; checks `L1-built`,
`L1-vergen-gix` and `L1-shadow-rs` fail the moment RustSec opens an advisory
against any of the three, and `L1-serde`/`L1-tokio`/`L1-git2` fail if the site
stops distinguishing the two cases the way this decision reads it.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's

**There is no `- owns` line.** This item's `## Couplings` block reads `owns:`
with nothing after it and `consumes: R49: build-tool-output-shape`
(`inputs/prompt.md`; assertions A9g, A9h), so R22 owns no registry parameter and
consumes exactly one. **There is no `CONFLICT:` line**: no consumed value needs
to change for this recommendation to hold. All five lines above were rendered
mechanically from `docs/port/PARAMETERS.md` and byte-compared against it by
`## Empirical check` row E2, checks A9a–A9f.

How each bears on the decision, said here rather than on the lines themselves:

- **`build-tool-output-shape`** is **load-bearing twice over.** Its "exactly one
  `[lib]` … `src/lib.rs`" and "exactly one `[[bin]]` … `src/main.rs`" clauses are
  why one library constant can serve every surface without a workspace-inheritance
  question, and its "**no `build.rs`** and no build-orchestration crate" clause
  independently rules out architecture B for the package's own targets — `built`,
  `vergen-gix` and `shadow-rs` all require one (A10b).
- **`msrv-policy`** is load-bearing for the candidate table: it fixes the floor at
  **1.96**, derived here from the live stable release `1.98.1` of 2026-09-03
  (A2a–A2c), and the gate reads *declared `rust-version` at or below the floor
  passes*. The selected mechanism has no MSRV of its own — `env!` and
  `CARGO_PKG_VERSION` long predate any floor this policy can produce.
- **`target-os-matrix`** is not load-bearing for the mechanism: a `rustc` macro is
  target-independent. It is load-bearing for the *evidence*, and the gap is named
  under `## Engines`: the probes ran on Darwin arm64 only.
- **`rust-edition`** is not load-bearing. `env!` and `option_env!` are edition-
  independent; nothing here depends on 2024.
- **`license`** is not evaluated against any candidate (gate 1 inapplicable) and
  the recommendation adds no dependency whose licence could be at issue. It
  governs this repository's own declared expression.

Two items are **related but are not registry dependencies of R22** and are
therefore deliberately absent from the list above. **R60**
(`cli-parsing-framework`) prints the value this item sources; its own decision
records that "which of compile-time `env!` and a runtime metadata lookup supplies
the value is **R22's** decision, not this item's; both satisfy the `MUST`
identically" (A10d). **R69** (`web-framework-stack`, owns `web-extra-surface`)
shapes the web surface that consumes the constant; the raw report emitted an
`assumes web-extra-surface` line for it, which is dropped here because this
item's prompt does not consume that parameter (A9k) and a validator comparing it
byte-for-byte against the registry would be comparing a line this item has no
standing to write.

## Empirical check

**Toolchain and environment.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4 on Darwin arm64;
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` invoked as `/usr/bin/grep`;
`curl 8.7.1`; `shellcheck` clean on all three scripts. Working directory for
every command: `research/runs/R22/2026-09-17T020715Z-d93731e7353c/review/evidence`.
Every network request carried
`User-Agent: rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)`
— no personal address, no credential, and no token byte appears in any script,
log or snapshot. All scratch work happened in a directory created by
`mktemp -d` under `$TMPDIR` and removed by an `EXIT` trap; every probe package
was created with `cargo new --vcs none`, and check C10 asserts that no nested git
repository was written.

| Row | Command | Log | Result |
|---|---|---|---|
| **E1** | `bash r22-cargo-probe.sh` | `review/evidence/r22-cargo-probe.log` | exit **0**, `CHECKS RUN: 24  PASS: 24  FAIL: 0  SKIP: 0` |
| **E2** | `bash r22-sources.sh` | `review/evidence/r22-sources.log` | exit **0**, `CHECKS RUN: 75  PASS: 75  FAIL: 0  SKIP: 0` |
| **E3** | `bash r22-live-recheck.sh` | `review/evidence/r22-live-recheck.log` | exit **0**, `CHECKS RUN: 10  PASS: 10  FAIL: 0  SKIP: 0` |
| **E4** | `bash r22-sources.sh` and `bash r22-cargo-probe.sh` from a `git archive HEAD` extraction | `review/evidence/r22-archive-rerun.log` | see the clean-extraction paragraph below |

109 checks in total, no failures, **no skips** — so there is no skip to name.
**No log line carries an absolute path**: each script prints file locations
relative to the repository root, which is what lets E4's extraction rerun be
diffed against the in-place run rather than merely inspected.
Every check asserts on content: a version string, a line of source at a numbered
line, a JSON field, an HTTP status against controls in both directions, or a
non-zero exit paired with the text that explains it. Each script sets
`set -euo pipefail` on its first executable line, counts `PASS`/`FAIL`/`SKIP`,
prints their sum, and exits non-zero on any failure.

**E1 — what the probe measured** (`r22-cargo-probe.sh`; ids as used above):

| Check | What it ran | Observed |
|---|---|---|
| C1, C1b | build a package, print `VERSION`, compare with the `version` line parsed out of `Cargo.toml` | `0.1.0`, non-empty, equal |
| C2a, C2b | edit the manifest to `9.8.7-rc.1`, rebuild, print again | `9.8.7-rc.1` — the accessor tracks the manifest |
| C3a, C3b | run the binary built **before** the edit, with the edited manifest in place | still `0.1.0`; the two binaries disagree |
| C4a, C4b | copy that binary into a directory holding no `Cargo.toml` and no `.rlib`, run it there | `0` such files found; still `0.1.0` |
| C5a, C5b | build with and without `--features web` | `1.2.3` both times, byte-identical |
| C6a–C6d | the accessor-equality test, correct then wired to the literal `"0.0.0"` | pass, then exit **101** naming `accessor_matches_cargo_package_version` and printing `0.0.0` |
| C7a, C7b | two-member workspace, `verlib 0.1.0` and `verbin 0.2.0`, printing both | `lib=0.1.0 bin=0.2.0` |
| C8a–C8d | `option_env!` of an unset variable; the same variable set **at run time**; then `env!` of it | `none`; still `none`; compile error at exit **101** naming the missing environment variable |
| C9a–C9c | `version = "v0.1.0"`, then `version = "0.1.0"` with nothing else changed | exit **101** naming `v0.1.0`; then exit **0** |
| C10 | `find` for `.git` under the scratch tree | `0` |

C8 is the check behind the sentence "there is no runtime fallback": setting the
variable in the *running process's* environment changes nothing, because the
expansion already happened. C9's pair is what makes AC5 structural — the control
build isolates the leading `v` as the cause of the rejection.

**E2 — what the source assertions covered.** Snapshot integrity (A1a: 25 files
against `snapshots/SHA256SUMS.txt`, with `snapshots/MANIFEST.txt` recording each
one's endpoint and retrieval date); the MSRV floor and the **direction** of gate 2
(A2a–A2g); the published crate figures (A3a–A3c); advisories and issue #262
(A4a–A4e); the pinned practice sources and the raw report's wrong line citations
(A5a–A5m); clap's two version paths at source (A6a–A6e2); the Cargo Book's actual
wording (A6f–A6k); the CLI Design Standard's R4.1 and R4.6 (A7a, A7b); the four
ledger rows (A8a–A8f); the five parameter lines against the live registry
(A9a–A9k); R49's and R60's published decisions (A10a–A10f); and this run's raw
report and manifest (A11a–A11g).

**E3 — what varies, and the rule for comparing across it.** `r22-live-recheck.sh`
queries live endpoints, so **its log does not reproduce byte-for-byte and is not
claimed to.** Three things move and are *printed* rather than asserted: the
`run-started-utc` line, the `DRIFT` lines carrying download counters (crates.io's
`recent_downloads` is a rolling 90-day window and can fall as well as rise), and
the stable-release comparison. What is asserted is the small set of facts this
decision rests on: six RustSec statuses with controls in both directions, three
newest-published-version pins, and the current stable release. Compare two runs
of this log by its `PASS`/`FAIL` lines only; a changed `DRIFT` number is expected
and a changed `PASS`/`FAIL` line is the re-verify trigger firing. Everything the
decision *quotes* is read from the hash-verified snapshots by `r22-sources.sh`
instead, which is why that log does reproduce.

**Reproduction, run rather than asserted.** Both deterministic scripts were
re-executed immediately before this document was written and each output diffed
against the log committed beside it:
`diff <(/usr/bin/grep -v '^run-started-utc:' r22-sources.log) <(/usr/bin/grep -v '^run-started-utc:' <rerun>)`
and the same for `r22-cargo-probe.log` both printed nothing. **`r22-cargo-probe.log`
and `r22-sources.log` are byte-identical across runs except for their
`run-started-utc:` line**, which carries the wall-clock time of the run. That is
the only varying line in either file.

**E4 — the clean-extraction rerun.** `r22-archive-rerun.log` records
`r22-sources.sh` and `r22-cargo-probe.sh` re-executed inside a `tar` extraction of
`git archive HEAD`, which has **no `.git` at all** — neither the directory a
normal checkout has nor the *file* this shared worktree has. Both scripts locate
the repository root by walking up for `docs/port/PARAMETERS.md` rather than for
`.git`, and `r22-sources.sh` reports which of the three cases it is in (check
A0b, which uses `-e` and not `-d`). The log states the observed result; it was
committed after the commit it reads, because a `git archive HEAD` extraction can
only contain files that are already committed.

## Engines

**codex `raw/codex.md`** — Codex CLI 0.154.0, model `gpt-5.6-luna`, registered by
the controller as
`raw/codex-6ebf723a4e5b801e2c787bc388779e68a2c714c9377c4f9407a7e211bae32915.md`;
the working copy at `raw/codex.md` hashes to that same sha256 (A11a, A11b). This
is the only research report in the run: `raw/` holds exactly two `.md` files, the
report and its sha-named registration (A11d). `raw/codex-transcript.txt` is
gitignored and is not evidence. The report passes the programme's own shape check
for a `pattern` answer — `validate_answer_text(open('raw/codex.md').read(),
'pattern')` returns `[]`.

**There were no engine disagreements to settle, because only one engine ran.**
This is a Light-tier item and its prompt registers `engines: codex` and
`evidence-checks: terra` (A9i, A9j). **The Terra evidence check is DEFERRED by the
controller under owner ruling W1-CODEX3 of 2026-09-18** — the Codex account is at
its usage limit — so the raw report reached this synthesis **unchecked**. It has
therefore been treated as an engine leg to be verified, not as a source to rely
on, and every load-bearing claim was re-verified at source before use. That
verification is what `r22-sources.sh` is.

**What the luna report got wrong. Four findings, each one re-derived at a named
endpoint.**

1. **The gate-2 exclusion of `built` is inverted, and the exclusion is
   withdrawn.** The report reads: "`built` 0.8.1: excluded by gate 2. Its
   published manifest declares `rust-version = "1.87"`, **below the current policy
   floor of Rust 1.96**" (A11e quotes that clause from the report itself). The
   gate runs the other way. `msrv-policy` sets the template's floor at 1.96; a
   dependency declaring 1.87 compiles on 1.96 and every later compiler, so 1.87 is
   **headroom**, and only a declared `rust-version` *above* the floor fails. The
   figure itself is right — `crate.rust_version` for the newest non-yanked
   version is `1.87`, from
   `GET https://crates.io/api/v1/crates/built/versions`, retrieved
   **2026-09-18 UTC** (A2d) — and the floor is right: `[pkg.rust] version` in
   `https://static.rust-lang.org/dist/channel-rust-stable.toml` is
   `1.98.1 (48a229cea 2026-09-01)` with the channel dated 2026-09-03, giving
   1.98 − 2 = **1.96** (A2a–A2c). R60's published decision reads the gate the same
   way ("the highest declared `rust-version` … is **1.85**, so the current 1.96
   floor has eleven minors of headroom"). **`built` therefore passes gates 2 and
   3**, and it is rejected in this decision on **fit** — it needs a `build.rs`,
   which R49's published value forbids for this package's targets, and it
   generates a module for a value Cargo already injects. The outcome is unchanged;
   the reason is not, and an exclusion recorded against the wrong gate would have
   made a later reader distrust a correct floor.
2. **The advisory 404s were read as "unverified" when they are a negative
   result.** The report records, for all three crates, that "the required RustSec
   URL returned a page-not-found response, so open-advisory status was not
   independently verified". `https://rustsec.org/packages/<name>.html` is served
   only for a crate that has at least one advisory. Establishing that took
   controls in both directions, run live on **2026-09-18 UTC**: `serde` → 404 and
   `clap` → 404 (enormous crates with no advisory), `tokio` → 200 and `git2` → 200
   (crates with advisories). So `built` → 404 and `vergen-gix` → 404 mean **no
   advisory**, and gate 3 passes for both. The controls are checks `L1-serde`,
   `L1-tokio` and `L1-git2` in `r22-live-recheck.sh`, kept in the script precisely
   so the inference is re-testable rather than asserted here.
3. **The `shadow-rs` exclusion was right but imprecisely grounded.** The report
   excluded it "by gate 3 pending advisory verification and by gate 2 evidence
   quality". `shadow-rs` itself has no advisory (404, same reading as above) and
   its undeclared `rust-version` is not a gate-2 failure. The real failure is in
   the **dependency tree**: default features pull `git2 ^0.20.0`, and `git2`'s
   RustSec page lists RUSTSEC-2026-0183 and RUSTSEC-2026-0184 (A4a, A4b), with
   the project's open issue #262 recording that the `^0.20.0` pin blocks the
   patched `0.21` (A4c–A4e, from
   `GET https://api.github.com/repos/baoyachi/shadow-rs/issues/262`, retrieved
   2026-09-18 UTC). Same verdict, correctly attributed.
4. **Three source citations name lines that say something else, and one
   attribution is to a sentence that does not exist.**
   - Apache Arrow: the report cites `arrow/src/lib.rs` **L1822-1824**. At the
     pinned commit the file is **440 lines long**, and its single
     `CARGO_PKG_VERSION` is at **`:412`** (A5b, A5c, A5i).
   - rav1e: the report cites `src/lib.rs` **L937-943** in one place and
     **L1223-1233** in another, for the same claim. Neither range contains
     `CARGO_PKG_VERSION` (A5j, A5k); the constant is at **`:216`** and the
     generated-module include at **`:54`** (A5d, A5f).
   - OpenTelemetry Rust: the report lists it among projects whose "source trees
     expose package version constants or version-reporting APIs".
     `opentelemetry-sdk/src/lib.rs` exports **no** version constant (A5l), and the
     occurrence in `opentelemetry-zipkin/src/lib.rs:203` is inside a
     **doc-comment example** (A5m). It is therefore not used as practice evidence
     in this decision.
   - The Cargo Book: the report states that "Cargo's build-script guidance says
     runtime checking of Cargo-provided variables is discouraged because it ties
     execution to Cargo's environment", and rests part of its rejection of the py
     shape on it. **That sentence is not on the page.** The only occurrence of
     "discouraged" on `build-scripts.html` concerns dynamic-library search paths
     (A6i), and no quoted line of either page contains the word "runtime" at all
     (A6j, with A6k as the control that the search is not vacuous). The rejection
     of architectures C and D in this decision rests instead on what the pages do
     say — "Cargo exposes these environment variables to your crate **when it is
     compiled**", with `let version = env!("CARGO_PKG_VERSION");` as the documented
     access form (A6f, A6g) — and on measurement (C4b).

Two smaller corrections, reported rather than fixed quietly: the report records
`shadow-rs`'s licence as MIT, where crates.io gives `MIT AND Apache-2.0` (A3b) —
immaterial, since gate 1 is inapplicable; and it emitted an
`assumes web-extra-surface` line for a parameter this item does not consume
(A11f), which is dropped (A9k).

**What the luna report got right, and is carried.** The core judgment —
compile-time `env!("CARGO_PKG_VERSION")` in a shared library constant, no
accessor crate, no runtime lookup, provenance left to R60 — is sound and is this
decision's recommendation. Its reading of the principle (single source of truth
as an architectural pattern, not a demand for identical mechanisms), its
identification of `vergen-gix` as the conditional companion for provenance, and
its BASELINE-REVIEW position that F133's accessor assertion should be retained
all survive. The candidate set is complete for this category as far as the
three-bin survey reaches.

**Claims carried without independent verification, named so an auditor does not
have to find them.**

- **Issue-responsiveness medians.** The report gives 0.15 days for `built`, 3.92
  for `shadow-rs` and 0.23 for `vergen-gix`. Not re-derived. Non-load-bearing: no
  crate is recommended, and the two crates whose maintenance would matter are
  rejected on other grounds.
- **Complete dependency-tree MSRV for `vergen-gix`.** The report did not establish
  it and neither did this synthesis; only its own declared `rust-version = 1.96.0`
  was verified (A2f). It sits exactly on the floor, with zero headroom. This
  matters only if R60 later adopts it.
- **Star counts and download figures.** Verified as of 2026-09-18 UTC at the
  required endpoints and snapshotted, but they are moving numbers; the log's own
  `DRIFT` lines are the record of that.
- **`shadow-rs`'s and `built`'s default-feature lists**, read by the report from
  `docs.rs/crate/<name>/<version>/source/Cargo.toml`. Not re-read here. The
  `shadow-rs` exclusion does not depend on the list alone — issue #262 states the
  `git2 ^0.20.0` dependency in the project's own words (A4e).

**Not proven here, and left for P03 to prove in the real template.**

1. **Every AC1–AC6 assertion.** They are proposals. The mechanism behind each was
   measured on throwaway packages; none has run against `rs-launch-blueprint`,
   which does not exist.
2. **Linux.** Every probe ran on Darwin arm64. The mechanism is a `rustc` macro
   and is target-independent, but `ubuntu-latest` is half the required matrix and
   no run was made on it. P03's CI closes this the first time it runs.
3. **The end-to-end identity of the three printed surfaces.** C1 and C5b show one
   symbol yielding one feature-invariant value; they do not show `rslbp --version`,
   a diagnostics line and a web health body agreeing, because none of the three
   exists. AC3 is the check that will.
4. **Deployment staleness.** The web reasoning above rests on C3 and C4 plus the
   structure of R69's feature; no service was deployed, no rollout was observed.
5. **Binary-size and compile-time cost.** Stated qualitatively only. Nothing was
   measured, and the decision makes no numeric comparison against `built`,
   `vergen-gix` or `shadow-rs`.

**One observation outside this item's scope, recorded rather than acted on.**
R49's published `build-tool-output-shape` says "no `build.rs` and no
build-orchestration crate" (A10b), while R60's published decision puts a
"dependency-free `build.rs` reading Cargo's `TARGET` and running `$RUSTC -vV`" in
the CLI binary crate for F267. Whether those two published values are in tension
is for their owners and the controller, not for R22: this item's recommendation
needs **no** build script under either reading, so no `CONFLICT:` line is raised
and no consumed value needs to change.

**A note on shape.** This document follows the synthesizer role contract — four
H2 sections (`## Decision`, `## Parameters`, `## Empirical check`, `## Engines`),
one H3 (`### Principles and implementation`), no `## Supersedes` in a first
revision, and one `re-verify:` line. `validate_answer_text(text, "pattern")`
models the fifteen-H3 shape of a **raw answer**, not of a decision, and reports
its H3-ordering diagnostic against any decision in this programme, including
accepted ones — running it against
`research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/DECISION.md` returns the
same diagnostic. It returns `[]` for this run's `raw/codex.md`, which is the
artifact it is written for.
