# R10 — dependency-cache-action (crate) — raw report (Opus engine)

Engine identity: `research-opus-2026-09-17T020715Z-b3b67fdb5328`, model `claude-opus-5`.
All retrievals in this report were made on **2026-09-17 (UTC)** unless a different date is
stated on the line. Current Rust stable at retrieval: **1.98.1 (48a229cea 2026-09-01)**,
manifest `date = "2026-09-03"` (`GET https://static.rust-lang.org/dist/channel-rust-stable.toml`,
retrieved 2026-09-17), so the `msrv-policy` floor ("stable minus 2 minor versions") is **1.96**.

### Landscape

**The category this item decides.** Not "a crate". The decision is *the CI cache
mechanism for Cargo's three caches* — the registry index and downloaded `.crate`
archives under `$CARGO_HOME`, the `git` checkouts under `$CARGO_HOME/git`, and the
workspace `target/` build-artifact directory — together with **the cache key that
decides when each is reused and when it is discarded**. The key is the substance of
the decision; the action is the delivery vehicle for a key strategy. Every candidate
below is therefore judged first on its key, then on its maintenance.

**Three-bin map of the Rust field.**

| Bin | Candidates found | What it is |
|---|---|---|
| Built-in / first-party | **`actions/cache`** (GitHub's own generic cache action, v6.1.0) with the Rust recipe GitHub itself publishes in `examples.md`; **no caching at all** (Cargo's own defaults, `cargo build --locked`); GitHub Actions' cache *service*, which every other candidate here is layered on | GitHub, `actions/` owner |
| Established industry standard | **`Swatinem/rust-cache`** v2.9.2 — a Rust-specific action whose key is derived from `rustc -vV`, the runner OS/arch, compiler env vars, and a *normalised* parse of every `Cargo.toml`/`Cargo.lock` in the workspace, and which prunes `target/` and `$CARGO_HOME` before saving | third-party, single maintainer |
| Up-and-comer | **`actions-rust-lang/setup-rust-toolchain`** v2.0.0 (a composite action that installs the toolchain *and* delegates caching to `Swatinem/rust-cache` at a pinned SHA — the true Rust analogue of `setup-uv`/`setup-node`); **`mozilla-actions/sccache-action`** v0.0.11 + `sccache` 0.18.0 (compiler-level object caching through `RUSTC_WRAPPER`, backed by the same GitHub Actions cache service); **`moonrepo/setup-rust`** v1.3.0 (a second setup-plus-cache action — but **not** a delegate: `action.yml` declares `runs: main: 'dist/index.js'`, i.e. its own cache implementation, with `cache`, `cache-base`, `cache-target` and `cache-extra-identifier` inputs); **`Leafwing-Studios/cargo-cache`** (a composite that computes a key and calls **`actions/cache@v4`** — `action.yml:168` — *not* a wrapper of `Swatinem/rust-cache`); managed third-party cache backends reachable through `rust-cache`'s own `cache-provider: warpbuild` input |

**A correction to this prompt's `## Context`, established from primary source.** The
prompt states that "Rust has no single canonical toolchain-setup action that bundles
caching this way". That is true of `dtolnay/rust-toolchain` — its README documents
toolchain installation only and exposes a `cachekey` *output* for you to feed to some
other cache action, never a cache of its own
(`GET https://api.github.com/repos/dtolnay/rust-toolchain/contents/README.md`, lines 1–4
and 68–69, retrieved 2026-09-17). It is **false in general**:
`actions-rust-lang/setup-rust-toolchain@v2.0.0` has `cache` defaulting to `"true"` and
its own `action.yml` line 263 reads
`uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2`, with
twelve `cache-*` inputs that it forwards verbatim
(`GET https://api.github.com/repos/actions-rust-lang/setup-rust-toolchain/contents/action.yml?ref=ecabd13d1c56bd1345c230e542e9144811ad706f`,
retrieved 2026-09-17). The setup-integrated shape py and ts use **does exist in Rust**;
what does not exist is a setup-integrated action that caches with an engine of its own.
This changes the evidence note on the ledger row, not its verdict — see
`### Principles and implementation`.

**Authoritative sources used, and why each is authoritative.**

| Source | Why authoritative | Used for |
|---|---|---|
| `docs.github.com` — "Dependency caching" reference | GitHub is the operator of the cache service every candidate uses; its limits are not opinion | the 10 GB budget, the 7-day eviction rule, branch scoping, the fact that keys are **not** auto-scoped by OS |
| `actions/cache` repository at tag `v6.1.0` (`README.md`, `examples.md`) | GitHub's own first-party action and GitHub's own published Rust recipe | the hand-rolled baseline, verbatim; the Feb-2025 cache-service-v2 migration |
| `Swatinem/rust-cache` **source** (`src/config.ts`) and `action.yml` at the v2.9.2 commit | the implementation itself, read at the pin — not a description of it | the exact key derivation, the prune rules, every default |
| `actions/runner-images` **Packer templates and build scripts** | the code that builds the GitHub-hosted images | that `ImageOS`/`ImageVersion` are real env vars and what `ImageOS` contains |
| `rust-lang/cargo`, `rust-lang/rust-analyzer` CI workflows | the Rust project's own CI | first-party practice, including the decision *not* to cache |
| `cargo-bins/cargo-binstall` source (`crates/binstalk/src/ops/resolve.rs`) | the tool R42 selected, read at source | whether a cached `~/.cargo/bin` can serve a stale tool |
| Issue `Swatinem/rust-cache#341` and its five comments | a reproduced production failure with named third-party corroboration (NomicFoundation/edr, Homebrew/homebrew-core) | the cross-OS defect that decides the MEDIUM question |

A single blog post was used nowhere. The annual Rust survey does not cover CI cache
mechanisms; no RFC or working-group output covers them either — **stated as an evidence
gap**: this category has no Rust-project-level normative guidance, which is itself the
reason practice evidence carries the weight here.

**Practice evidence — well-regarded Rust projects surveyed.** Counts are
`total_count` from `GET https://api.github.com/search/code?q=repo:<o>/<r>+Swatinem%2Frust-cache+in:file+path:.github/workflows`,
retrieved 2026-09-17.

| Project | Why it is a relevant, well-regarded reference | What it does |
|---|---|---|
| **astral-sh/uv** | the Rust implementation of the very tool that supplies py's precedent (`astral-sh/setup-uv`, py `.github/workflows/ci.yml:87` at pin `b08bccfb`); large, new, heavily adopted | 13 hits. `.github/workflows/test.yml:42–51`: `run: rustup toolchain install --profile minimal` then `uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2` with `prefix-key: v1-rust-workspace`, `key: ${{ hashFiles('Cargo.toml') }}`, `cache-workspace-crates: "true"`, `save-if: ${{ inputs.save-rust-cache == 'true' }}` |
| **clap-rs/clap** | the de-facto Rust CLI argument parser; directly relevant to this template's CLI surface | 3 hits; `.github/workflows/ci.yml` lines 78, 101, 118, 157, 177, 209, 223, 241 all read `uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2` — SHA pin plus version comment, exactly R20's shape |
| **tokio-rs/tokio** | the dominant Rust async runtime | 3 hits; `.github/workflows/ci.yml:71–82`: `dtolnay/rust-toolchain@stable` then `Swatinem/rust-cache@v2` with `cache-bin: ${{ matrix.os != 'macos-latest' }}` and a `FIXME` citing issue #341 |
| **astral-sh/ruff** | same maintainer standing as uv; very large Rust workspace | 8 hits |
| **helix-editor/helix**, **starship/starship** | large, popular end-user Rust binaries | 1 hit each (line not individually cited — see `Method notes`) |
| **rust-lang/cargo** | Cargo itself; first-party | **no cache action at all** — `.github/workflows/main.yml` uses bare `rustup update stable && rustup default stable` (lines 61, 82, 90, 97) |
| **BurntSushi/ripgrep**, **serde-rs/serde** | two of the most-depended-on Rust projects, by two maintainers of the highest standing | **no cache action at all**; `dtolnay/rust-toolchain` only (ripgrep `ci.yml:128`; serde `ci.yml:50`) |
| **rust-lang/rust-analyzer** | the Rust language server; first-party org | `Swatinem/rust-cache` present but **commented out** at `ci.yaml:112–117`, `151–152`, `217`, with no stated reason at that revision |

The survey is deliberately reported with its counter-evidence: three of the most
authoritative Rust codebases cache nothing. Their shape explains it and is *not* this
template's shape — see `### Fit for this template`.

### Principles and implementation

**The shared requirement, and the level at which agreement is required.** F035
(`docs/port/COMMONALITY.md:41`, `COMMON → REUSE`) states the principle: *dependency
fetches and build artifacts are reused across CI runs rather than re-fetched and
re-built on every run.* The level of agreement required is a **capability plus a
correctness policy**, not an architectural pattern and not a specific action:

- **P1 — Reuse.** A run that has not changed its resolved dependency set or its
  toolchain must not re-download or re-compile that dependency set.
- **P2 — Never serve a stale dependency.** A run whose resolved dependency set
  *has* changed must not be able to link an artifact built from the previous set.
- **P3 — Bounded cost.** The cache must not grow without bound into the repository's
  shared storage budget, and eviction of this repository's caches must not be caused
  by this mechanism's own leftovers.

**What must agree; what may vary.** *Must agree*: the key must include the compiler
identity, the runner identity, and a digest of the resolved dependency set; the save
key and the restore key must differ, the save key strictly finer. *May vary*: which
action delivers that key, whether the cache step is standalone or an input block on
a toolchain-setup step, and per-job tuning (`save-if`, `cache-targets`).

**Does the py/ts architectural pattern remain appropriate here? Partly — and this is
the one place the target ecosystem genuinely needs a different design.** py and ts
cache *one* thing: the package manager's download store, keyed on a lockfile. py gets
it from `astral-sh/setup-uv@v8.3.2` with no cache input at all (py `.github/workflows/ci.yml:87`
at pin `b08bccfb`, read via `git -C ~/c/py-launch-blueprint show b08bccfb:.github/workflows/ci.yml`);
ts gets it from `actions/setup-node@v7` with `cache: 'pnpm'` (ts `.github/workflows/ci.yml:69–74`
at pin `cb1cbcb2`, whose own comment cites D-022(3)). Neither ecosystem has a
compiled-artifact directory, so neither source repo's mechanism has ever had to answer
the question that dominates in Rust: **`target/` is the expensive cache and the
dangerous one.** It is large enough to exhaust the 10 GB repository budget, it is
invalidated by things a lockfile hash cannot see (the `rustc` version, `RUSTFLAGS`,
the target triple), and it accumulates artifacts that no current dependency needs.
A design that ports "hash the lockfile, cache the download store" straight across —
which is precisely GitHub's own published Rust recipe — reproduces the py/ts shape and
fails P1 and P3 in Rust. The principle ports; the mechanism must not.

**Architectural alternatives, compared before libraries.**

| Alternative | P1 Reuse | P2 No stale dependency | P3 Bounded cost | Verdict |
|---|---|---|---|---|
| **A. No cache** (`rust-lang/cargo`, ripgrep, serde) | fails by construction | trivially holds | trivially holds | Rejected for this template: it is a CLI + library + web service whose dependency tree will be large (a CLI parser, an async runtime, a web framework, a tracing stack), so the re-build cost is the dominant CI cost, not a rounding error. Correct for ripgrep/serde because their dependency-to-own-code ratio is near zero — `Swatinem/rust-cache` README states the effectiveness rule explicitly: "This action only caches the _dependencies_ of a crate, so it is more effective if the dependency / own code ratio is higher." |
| **B. Generic `actions/cache` with a hand-written key** (GitHub's published recipe) | fails: the key is `${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}` with **no `restore-keys`**, so a one-line lockfile change is a 100 % miss and a full rebuild | fails a second way: `rustc` version is absent from the key, so a toolchain change restores a `target/` built by a different compiler (Cargo's own fingerprinting then rebuilds — so no *link-time* staleness, but the reuse claim is false) | fails: `target/` is never pruned, so the cache grows monotonically and every lockfile change writes a *new* multi-hundred-megabyte entry | Rejected. Verbatim source: `actions/cache` `examples.md:610–622` at tag `v6.1.0` (commit `55cc8345863c7cc4c66a329aec7e433d2d1c52a9`) |
| **C. Compiler-level object cache** (`sccache` via `RUSTC_WRAPPER`, `mozilla-actions/sccache-action`) | partial: caches object files, so it survives some changes a directory cache does not; but with the GitHub Actions backend it competes for the *same* 10 GB budget | holds — content-addressed by compiler input | weakest: doubles the storage claim if run alongside a directory cache | Rejected as the default; kept as an up-and-comer |
| **D. Rust-aware directory cache with a derived key** (`Swatinem/rust-cache`) | holds — see the key below | holds — see the key below | holds — it prunes before saving | **Selected** |
| **E. D, packaged inside the toolchain-setup step** (`actions-rust-lang/setup-rust-toolchain`) | identical to D — it *is* D, at the same commit | identical to D | identical to D | Not this item's to choose: see `### Parameters` |

**How the selected design preserves each principle — read from the source at the pin,
not from documentation.** `src/config.ts` at commit `6323deb102c322ba6fcbdcafc7e3dddab59af2b6`
builds two keys:

- **restore key** = `{prefix-key}` + `-{shared-key}` *or* `-{key}-{GITHUB_JOB}`
  + `-{os.type()}-{os.arch()}` + `-sha1(`every installed toolchain's `rustc -vV`
  output, gathered by `getRustVersions` at lines 390–415, + every environment variable
  whose name starts with one of `CARGO CC CFLAGS CXX CMAKE RUST` plus the `env-vars`
  input, sorted, at lines 110–126`)` — lines 66–131.
- **save key** = the restore key + `-sha1(` a *normalised* parse of every workspace
  `Cargo.toml` and `Cargo.lock` plus every `rust-toolchain{,.toml}` and
  `.cargo/config.toml` `)` — lines 154–240.

That two-key split **is** the answer to the HIGH key-strategy question, and it is the
mechanism GitHub's own recipe lacks. The save key carries the lockfile digest, so a
dependency change can never hit an exact match (P2). The restore key omits it, so a
dependency change still restores the newest cache that agrees on compiler, runner and
flags, and Cargo rebuilds only what actually changed (P1). The README states the
consequence: "The action will try to restore from a previous `Cargo.lock` version as
well, so lockfile updates should only re-build changed dependencies."

The normalisation matters for P1 in a workspace: the manifest hash sets
`package.version` to `"0.0.0"` and blanks `path` dependencies' `version`/`path`
(lines 181–206), and the `Cargo.lock` hash keeps only packages that have a `source`
or `checksum` key — i.e. it **excludes the workspace's own crates** (lines 235–240).
A version bump or an edit to a sibling crate therefore does not throw the dependency
cache away. That is the LOW question answered: the design is workspace-aware by
construction, and `cargo metadata` (invoked via `getWorkspaceMembers`) enumerates the
members, so a single virtual workspace with N members needs **no** `workspaces:` input.
The input is needed only for genuinely *separate* workspace roots or a relocated
target directory — the case `.github/workflows/workspaces.yml` exercises at the pin.

P3 is met by pruning before save, documented in the README and implemented in the save
path: files present in `~/.cargo/bin` *before the action ran*, dependencies no longer
used, anything that is not a dependency, incremental artifacts, and any artifact with an
`mtime` older than one week. The action also sets `CARGO_INCREMENTAL=0`.

**Production usage and maintained reference examples.** The reference implementation to
copy is **astral-sh/uv** `.github/workflows/test.yml` (lines 42–51): bare
`rustup toolchain install --profile minimal`, then `Swatinem/rust-cache` pinned by full
SHA with a version comment. It composes exactly as this template would: no toolchain
action, a `prefix-key` for manual cache busting, an explicit `key`, and `save-if` used to
gate saving. `clap-rs/clap` is the second, at eight call sites and the identical pin.
The action's own CI is the third and most useful: `.github/workflows/` at the pin
contains fourteen scenario workflows — including `binstall.yml`, `install.yml`,
`workspaces.yml`, `target-dir.yml`, `save-restore.yml`, `multi-job-cache.yml`, `nix.yml`
— each run on `[ubuntu-latest, macos-latest, windows-latest]`.

**Performance, with workload and instrumentation stated — and its limits.** No absolute
speedup figure is asserted here. The template does not exist, so there is no workload to
measure, and cross-project CI timings are unlike benchmarks that cannot be compared. What
*is* measurable and stated: the storage budget is **10 GB per repository** and entries
"not accessed in over 7 days" are removed; when the budget is exceeded, GitHub deletes
"in order of last access date, from oldest to most recent"
(`https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching`,
retrieved 2026-09-17). With `add-job-id-key` at its default `"true"` and the fixed two-OS
matrix, the template will hold **2 × (number of jobs)** distinct cache entries. The
instrumentation P03 must add is named under `### Validation strategy`; the figure P03 must
record is the per-entry size reported by the GitHub Actions cache API, against the 10 GB
budget. Treat any build-time speedup number in this report's absence as **not measured**.

**BASELINE-REVIEW finding — one line, on F036's evidence note only.**

BASELINE-REVIEW: F036 — dependency caching is a capability plus a key-correctness policy (the save key strictly finer than the restore key), and whether it is packaged inside the toolchain-setup step is a separable delivery choice, not part of the principle — replace F036's evidence note "py/ts each get caching free from their language-setup action, Rust has no single canonical equivalent" with "py/ts get caching from their language-setup action; in Rust the caching engine (`Swatinem/rust-cache`) and the toolchain-setup step are separately selectable, and `actions-rust-lang/setup-rust-toolchain` packages the same engine into the setup step, so the setup-integrated shape *is* available but is a packaging choice belonging to the toolchain-install decision (R42), not to this one; what the mechanism must agree on is the key — save key carries the lockfile digest, restore key omits it"; verdict `COMMON → SUBSTITUTE` and the F036 → R10 assignment are unchanged — evidence: `actions-rust-lang/setup-rust-toolchain` `action.yml` line 263 at commit `ecabd13d1c56bd1345c230e542e9144811ad706f` reads `uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2`, its `cache` input defaults to `"true"`, and its README line 57 documents `cache` as "Automatically configure Rust cache (using [`Swatinem/rust-cache`])" (both retrieved 2026-09-17); `dtolnay/rust-toolchain`'s README documents no cache, only a `cachekey` output (lines 68–69, retrieved 2026-09-17), which is the narrower claim F036's note generalised from; the two-key split is read from `src/config.ts:66–240` at the same pin.

**F035 is deliberately not challenged.** Its row already carries the 2026-09-04 restatement
"principle restated: dependency fetches and Cargo build artifacts are cached across CI runs;
'integrated into the language-setup step' was the py/ts mechanism" (`docs/port/COMMONALITY.md:41`).
This item's findings **confirm** that row rather than amend it, so no `BASELINE-REVIEW:` line
is raised against F035.

### Dominant choice

**`Swatinem/rust-cache`, at `v2.9.2` = commit `6323deb102c322ba6fcbdcafc7e3dddab59af2b6`.**

It is dominant on three independent measures, all retrieved 2026-09-17:

1. **It is the engine inside the one competitor that matters.**
   `actions-rust-lang/setup-rust-toolchain@v2.0.0` — the only Rust action that reproduces
   py's and ts's setup-integrated shape — delegates to it at a pinned SHA
   (`action.yml:262–275`, verified at commit `ecabd13d…`). Choosing "the setup-integrated
   action" is therefore not choosing a different cache; it is choosing the same cache with
   a different call site. (The two other wrappers are **not** delegates and are not
   evidence for this point: `Leafwing-Studios/cargo-cache` calls `actions/cache@v4`
   (`action.yml:168`) and `moonrepo/setup-rust` ships its own `dist/index.js` — both
   verified 2026-09-17.)
2. **Adoption among the projects most like this template.** `astral-sh/uv`,
   `astral-sh/ruff`, `clap-rs/clap`, `tokio-rs/tokio`, `helix-editor/helix`,
   `starship/starship` — see `### Landscape`. Two of them (`uv`, `clap`) are pinned to the
   *exact* SHA recommended here.
3. **It is the only candidate whose key is derived rather than hand-written**, which is
   the property a template meant to be forked needs most: a fork that adds a dependency,
   adds a workspace member, changes `RUSTFLAGS`, or bumps `rust-toolchain.toml` gets a
   correct key with **no workflow edit**. Every hand-rolled `actions/cache` key must be
   re-derived by hand on each of those events, and silently degrades when it is not.

Figures (endpoints as given in `## Required evidence`; crates.io fields are
**inapplicable** — this is a GitHub Action, not a published crate; see `### Qualified shortlist`):

- `GET https://api.github.com/repos/Swatinem/rust-cache` — `stargazers_count` **1917**, `archived` **false**, `pushed_at` **2026-09-07T21:44:07Z**, `license.spdx_id` **LGPL-3.0**. Retrieved 2026-09-17.
- `GET https://api.github.com/search/issues?q=repo:Swatinem/rust-cache+is:issue+is:open` — `total_count` **69**. Retrieved 2026-09-17.
- Latest release **v2.9.2**, published **2026-08-06T06:26:27Z** (`GET https://api.github.com/repos/Swatinem/rust-cache/releases/latest`). Preceding eight: v2.9.1 2026-03-12, v2.9.0 2026-03-12, v2.8.2 2025-11-26, v2.8.1 2025-09-18, v2.8.0 2025-06-25, v2.7.8 2025-03-19, v2.7.7 2024-12-29. Retrieved 2026-09-17.
- Tag → commit: `GET .../git/ref/tags/v2.9.2` → annotated tag `63fed3e2fecf6f7b51dc6f043341b79ef82a9ae7` → `GET .../git/tags/63fed3e2…` → commit **`6323deb102c322ba6fcbdcafc7e3dddab59af2b6`**. Retrieved 2026-09-17.
- **Issue responsiveness**, from the 10 most recently opened issues (`GET https://api.github.com/repos/Swatinem/rust-cache/issues?state=all&sort=created&direction=desc&per_page=100`, `pull_request == null` filtered): #381, #375, #374, #370, #369, #352, #348, #344, #341, #337. A first comment by the maintainer (`Swatinem`) exists on **3 of 10**: #375 (36 minutes ≈ 0.03 d), #337 (2 h 45 m ≈ 0.11 d), #370 (1.00 d). **Median days to first maintainer response among the answered = 0.11 d; unanswered by the maintainer = 7 of 10.** The median over all ten is undefined (more than half unanswered) — reported as such rather than imputed. Retrieved 2026-09-17.
- **Maintenance state: `active`.** Rubric applied: a release 6 weeks before retrieval (v2.9.2, 2026-08-06); commits within 5 weeks (`2026-08-17`, `GET .../commits?per_page=10`); an outside contributor's bug fix merged (`TethysSvensson`, "fix: stop cleanup timestamp pruning after the first entry (#377)", 2026-08-12); Dependabot active. No `at-risk` signal is present. The concrete risk that *is* present — and is not the rubric's `at-risk` — is a **bus factor of one**: `Swatinem` authored every release commit, and the 7-of-10 unanswered-issue figure is consistent with a single maintainer triaging selectively.

### Qualified shortlist

Gate 1 is recorded once for every candidate: **`inapplicable — owner ruling 2026-09-12 (Q7.B)`**
(`docs/port/OWNER-REVIEW.md`). Licence is recorded as a figure and excludes nothing.

Four candidates passed every applicable gate; the prompt allows five. **Fewer than five
is itself a finding**: the Rust CI-cache field is narrow, and two of the four are the same
engine behind different call sites.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| **`Swatinem/rust-cache`** v2.9.2 | Rust-aware directory cache for `~/.cargo` + `target/`, derived key | `inapplicable` — not a crates.io crate; no `crate.recent_downloads` field exists. GitHub stars substituted | `inapplicable` — same | **1917** | **v2.9.2, 2026-08-06T06:26:27Z** | **active** | astral-sh/uv, clap-rs/clap (both at this exact SHA); tokio-rs/tokio, astral-sh/ruff, helix-editor/helix, starship/starship | one maintainer; its key omits the runner **image** version, which broke macOS builds once (#341) |
| **`actions-rust-lang/setup-rust-toolchain`** v2.0.0 | toolchain install **plus** the same cache engine, delegated | `inapplicable` — not a crate | `inapplicable` | **403** | **v2.0.0, 2026-09-07T21:53:31Z** | **active** (release 10 days before retrieval; 3 open issues) | referenced by rust-analyzer's CI for its problem matcher (`ci.yaml:107`) | caching is identical to the row above because it *is* that row; choosing it also decides the toolchain installer, which is R42's |
| **`actions/cache`** v6.1.0 | GitHub's generic cache primitive | `inapplicable` — not a crate | `inapplicable` | **5550** | **v6.1.0, 2026-06-26T19:17:06Z** | **active** | universal across ecosystems; GitHub publishes a Rust recipe for it | passes every gate as a *primitive*, but GitHub's own published Rust key fails P1 and P3 (see `### Principles and implementation`, alternative B) |
| **`mozilla-actions/sccache-action`** v0.0.11 + `sccache` 0.18.0 | compiler-level object cache via `RUSTC_WRAPPER` | `sccache`: **129 817** (`crate.recent_downloads`) | `sccache`: **1 335 826** (`crate.downloads`) | 206 (action) / **7685** (`mozilla/sccache`) | action **v0.0.11, 2026-07-29T11:19:11Z**; crate **0.18.0, 2026-09-16T14:34:17.177895Z** | **active** | Mozilla; Firefox build infrastructure | complementary, not a substitute: it caches compiler *outputs*, not the registry, and on the GitHub backend it spends the same 10 GB budget twice |

Endpoints for the crates.io figures: `GET https://crates.io/api/v1/crates/sccache` and
`GET https://crates.io/api/v1/crates/sccache/versions` (newest unyanked: `num` `0.18.0`,
`created_at` `2026-09-16T14:34:17.177895Z`, `license` `Apache-2.0`, `rust_version`
`1.91.0`), both retrieved 2026-09-17 with a `User-Agent` header.

**Fitness gates, per candidate, answered before popularity was weighed.**

*`Swatinem/rust-cache` v2.9.2*
1. Licence — `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Figure recorded: `LGPL-3.0` (`license.spdx_id`, `GET https://api.github.com/repos/Swatinem/rust-cache`, retrieved 2026-09-17). Not evaluated, excludes nothing.
2. MSRV — **`inapplicable`**: this is a TypeScript action executed by the runner's Node runtime (`action.yml`: `using: "node24"`), not a crate in the template's dependency tree. It contributes no `rust-version` and no transitive Rust dependency. It imposes a *runner* requirement instead: Node 24, i.e. a runner new enough to provide it — satisfied by both fixed GitHub-hosted runners, and a coupling for R09 (`self-hosted-runner-indirection`) if a self-hosted runner is ever substituted.
3. RustSec — **`inapplicable`**: not a crate, so `https://rustsec.org/packages/rust-cache.html` has no meaning. `unsafe` posture: **`inapplicable`** — no Rust code. Supply-chain posture instead, which is the real question: it is third-party JavaScript executing in the CI job, so R20's SHA pin is the control, and `check-dist.yml` in its own CI verifies the committed `dist/` matches the sources.
4. Platforms — **passes**. Its own CI runs every scenario workflow on `[ubuntu-latest, macos-latest, windows-latest]`, verified in the matrix block of `simple.yml`, `binstall.yml`, `install.yml` and `workspaces.yml` at commit `6323deb…` (retrieved 2026-09-17). Both fixed matrix entries are covered; Windows is covered and not required. The README further documents an automatic workaround for `rust-lang/cargo#8603` / `actions/cache#403`, "which would otherwise corrupt the cache on macOS builds."
5. Default features / async-runtime coupling — **`inapplicable`**: a GitHub Action has no Cargo features and links no async runtime into the template. The nearest true statement is its *input defaults*, which are load-bearing and are listed under `### Recommendation`.
6. Binary size / compile time — **`inapplicable`**: nothing is compiled into the template's binary, so neither cost exists. The real cost is CI wall-clock and cache storage: two extra steps per job (a restore before the build, a save in `post`), a `cargo metadata` invocation, and one cache entry per job per OS against the 10 GB budget.

*`actions-rust-lang/setup-rust-toolchain` v2.0.0* — gates 1, 2, 3, 5, 6 resolve identically and for identical reasons (composite action; `node24` via the delegate). Gate 4 **passes** transitively through the same delegate at the same commit.

*`actions/cache` v6.1.0* — gates 1, 3, 5, 6 `inapplicable` for the same reasons (first-party JavaScript action; licence `MIT`, not evaluated). Gate 2 `inapplicable`; it states a *runner* floor instead — the README requires Actions Runner ≥ `2.327.1` for the Node 24 runtime at v5+, another R09 coupling. Gate 4 **passes** (GitHub-hosted runners universally).

*`sccache` 0.18.0 / `mozilla-actions/sccache-action` v0.0.11* — Gate 1 `inapplicable` (figure: `Apache-2.0`). Gate 2: the crate declares `rust_version` **`1.91.0`**, within the **1.96** floor; but it is a **standalone binary downloaded onto the runner**, never a dependency of the template, so its MSRV does not enter the template's dependency tree. Gate 3: `https://rustsec.org/packages/sccache.html` returns **HTTP 404** — no advisory page, therefore **no open advisory**. Control for that inference, run the same minute: `atty` (a crate with a known advisory) returns **200**, `serde` returns **404**. `unsafe` posture of the shipped binary: **not verified in this run** (see `Method notes`). Gate 4 **passes**: `mozilla/sccache` ships Linux and macOS release artifacts and the action installs them. Gates 5 and 6 `inapplicable` for the template binary; the runner cost is a downloaded binary plus an `RUSTC_WRAPPER` indirection on every `rustc` invocation.

### Excluded by gate

**None.** No candidate was excluded by a fitness gate. That is a direct consequence of
the 2026-09-12 owner ruling plus the item's shape: gate 1 is inapplicable by ruling, and
gates 2, 3, 5 and 6 are inapplicable to GitHub Actions, which every serious candidate is.
Gate 4 (platforms) is the only gate with force here, and every shortlisted candidate
passes it.

Candidates excluded for reasons that are **not** gates, recorded so the exclusion is
visible rather than silent:

- **`moonrepo/setup-rust`** v1.3.0 — excluded on **maintenance and provenance**, not a gate. `stargazers_count` **133**, `pushed_at` **2026-03-19T17:30:54Z** (six months before retrieval), last release **v1.3.0, 2026-03-19T17:30:23Z**, open issues **11**, and `license` is **`null`** — the repository declares no licence GitHub can detect (`GET https://api.github.com/repos/moonrepo/setup-rust`, retrieved 2026-09-17). Maintenance state by rubric: **`stable-quiet`** — six months without a release is a trigger to investigate, not a verdict, and no `at-risk` signal (no unpatched advisory, no broken build observed, no maintainer notice) was found. It is excluded because it is dominated: a second setup-plus-cache action with one third the stars of `actions-rust-lang/setup-rust-toolchain`, a key implementation of its own that nothing in this survey adopts, and no advantage this item can name. Its `cache-extra-identifier` input ("Additional identifier to include in cache key for matrix jobs or custom cache separation", `action.yml:18–19`) is the one idea worth carrying across — it is the same need the matrix caveat under `### Recommendation` records for the recommended action's `key` input.
- **`Leafwing-Studios/cargo-cache`** — excluded as **a hand-rolled key in a wrapper**: its composite `action.yml` computes a key from the cargo version, a `Cargo.lock` it generates if absent, and a workflow-path "cache group", then calls `actions/cache@v4` at line 168 (retrieved 2026-09-17). It is therefore alternative B with better ergonomics, not alternative D, and inherits B's pruning gap. `stargazers_count` **24**, `pushed_at` **2025-11-03T18:59:39Z** (over 10 months before retrieval), `archived` **false**. Maintenance state: **`stable-quiet`**, trending toward at-risk; no concrete `at-risk` signal was established, so the rubric's verdict is not upgraded.
- **`useblacksmith/rust-cache`** — excluded as **archived**: `archived` **true**, `pushed_at` **2025-10-14T21:49:49Z**, 1 star. Maintenance state: **`archived`** by the rubric's own term. Listed only because a search for forks surfaces it.
- **"No cache at all"** — not excluded by a gate; rejected on fit. See `### Principles and implementation`, alternative A, and `### Fit for this template`.

### Up-and-comers

- **`actions-rust-lang/setup-rust-toolchain` v2.0.0 (2026-09-07)** — the genuinely new development in this category and the one that falsifies this prompt's premise. It reads `rust-toolchain`/`rust-toolchain.toml` from the repository root and installs everything the file names (README lines 45–49), which is exactly the artifact R42 decided to commit (`rust-toolchain.toml` with `profile = "minimal"`, `components = ["rustfmt", "clippy"]`). Its v2.0.0 release replaced the `RUSTFLAGS="-D warnings"` default with `CARGO_BUILD_WARNINGS` (cargo 1.97+) — a change that matters to *this* item because `RUSTFLAGS` is in `rust-cache`'s default env-var key prefix set, so v1's default silently participated in the cache key and v2's does not. Watch it; it is the shape py and ts have.
- **`mozilla-actions/sccache-action` v0.0.11 with `sccache` 0.18.0** — `sccache` 0.18.0 shipped the day before retrieval (2026-09-16T14:34:17.177895Z). The action sets `RUSTC_WRAPPER=sccache` and `SCCACHE_GHA_ENABLED=true`, its README notes "Versions prior to sccache v0.11.0 probably will not work". It is the only candidate that caches at a granularity below the crate. Worth revisiting if P03 measures `target/` restore/save time as the dominant CI cost, or if the template later gains a Docker build where directory caching composes badly.
- **Managed cache backends** — `rust-cache`'s `cache-provider` input accepts `github` (default) or `warpbuild`, and its CI carries a `warpbuild.yml` scenario. Relevant only if the 10 GB GitHub budget becomes binding; it introduces a third-party data processor and is **not** recommended for a public template.

### Fit for this template

The template is one repository producing three surfaces. The cache decision is made once,
at the workflow level, but the three surfaces load it differently.

- **CLI.** The dominant fit case and the one that most needs the cache. R60 resolved to a CLI parsing framework and R67 to an error contract layering `thiserror` and `anyhow`; R49 fixed exactly one `[[bin]]` named `rslbp` at `src/main.rs`. A CLI's dependency tree is wide and its own code small — precisely the ratio `rust-cache`'s README names as where it is "more effective". Additionally, R32's built-binary test tier resolves the binary through `CARGO_BIN_EXE_rslbp`, which requires the binary to have been *built*, so the cached `target/` is on the critical path of the test job, not only the build job.
- **Library.** The weakest fit case, and the README says why: "Library repositories with only a `Cargo.toml` file have limited benefits, as cargo will _always_ use the most up-to-date dependency versions, which may not be cached." That caveat **does not apply here**: R49's decision has `cargo package` adding a minimised `Cargo.lock` and the template commits one, so the library surface is resolved, not floating. The MSRV job is the one place to watch — `msrv-policy` requires testing the floor (1.96) in CI, which means a second toolchain, a different `rustc -vV`, and therefore a **separate cache entry**, doubling that job's share of the budget. That is correct behaviour (a 1.96 `target/` must never be restored into a 1.98 build), not a defect.
- **Web service.** The largest `target/` of the three and the strongest argument against the hand-rolled key. The web surface sits behind a Cargo feature per **F017** (recorded in R49's decision text; the *content* of that surface is R69's `web-extra-surface`, whose value is `—` in `docs/port/PARAMETERS.md` at retrieval), so the web build is a *superset* of the CLI build's dependency graph and must not share a `target/` with it. `Swatinem/rust-cache`'s default `add-job-id-key: "true"` separates them **if and only if R11 makes them two job ids**; if R11 instead expresses the feature as a matrix leg inside one job, the separation must be spelled as `key: ${{ matrix.features }}` — see the `add-job-id-key` row under `### Recommendation`. Either way the separation is one line. Under GitHub's published `actions/cache` recipe — one key, no job component, no feature component, no escape hatch — every job shares one `target/` and thrashes with no way to say otherwise. This is the clearest single reason the derived-key action beats the primitive for this template specifically.

Against the py/ts precedent: py and ts each cache one store keyed on one lockfile, and
this template will cache two object classes keyed on compiler-plus-lockfile. The *step*
looks like py's and ts's — one line in the workflow, defaults mostly untouched. The
*substance* underneath is necessarily richer, and the recommendation below keeps the
surface as thin as py's and ts's so a forker sees one step, not a key-engineering exercise.

### Recommendation

**Adopt `Swatinem/rust-cache`, pinned per R20 as
`Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2`**, as a standalone
step placed immediately after the toolchain-install step that R42's decision implies and
before any `cargo` or tool-install step, with a **version range of `>= 2.9.1, < 3`**. The
floor is 2.9.1, not 2.9.0, for two reasons read from the CHANGELOG at the pin: 2.9.0 is
the release that moved the action to the `node24` runtime and made the key "Consider all
installed toolchains" (which the MSRV job needs), but 2.9.0 also shipped a defect in the
very mechanism this recommendation rests on — 2.9.1's sole entry is "Fix regression in
hash calculation". The ceiling is `< 3` because a major version would be free to change
the key derivation this recommendation is built on.

Three inputs are set; every other input keeps its default.

```yaml
- uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2
  with:
    env-vars: "ImageOS"
    cache-on-failure: "true"
    prefix-key: "v1-rslbp"
```

**Why each, and only these three.**

1. **`env-vars: "ImageOS"` — this is the correctness fix, and it is the answer to the
   MEDIUM cross-OS question.** The default key ends with `-{os.type()}-{os.arch()}`
   (`config.ts:90–93`), which on GitHub-hosted macOS is `Darwin-arm64` both before and
   after GitHub repointed `macos-latest` from macOS 15 to macOS 26. The runner *image*
   is therefore **not** in the key, and GitHub does not add it: the docs state that a
   key is whatever you make it and the reference example has to spell `${{ runner.os }}`
   out by hand. The observable consequence is issue **`Swatinem/rust-cache#341`**, "`cache-bin: true`
   breaks cargo subcommands on new github macos runner", opened 2026-05-13, closed
   2026-05-29 with 5 comments: a cache saved on the old image restored `~/.cargo/bin`
   onto the new one and broke the `rustc`/`cargo` rustup shims, so `cargo fmt` failed with
   `error: unexpected argument 'fmt' found / Usage: rustup-init[EXE]`. Corroborated by a
   second project in-thread (`NomicFoundation/edr`, on v2.9.1, predating the suspected PR)
   and diagnosed in-thread by a third reporter: "this is only a problem if `cache-bin` was
   `true` and a macos-26 target uses a cache from an older macos builder". A commenter
   drew the right conclusion — "seems like a good idea for the cache key to include the OS
   version then" — and the issue was closed **without that change**: the CHANGELOG at the
   v2.9.2 pin lists no fix for it, and the reporter's closing comment says only that
   "the homebrew people have shipped a workaround … although they still believe the bug is
   in the `rust-cache` action". The defect is therefore **live at the recommended pin**,
   and the template must fix it in its own configuration. `env-vars` is *appended* to the
   built-in prefix list rather than replacing it (`config.ts:111–112`), and matching is
   `key.startsWith(prefix)` and case-sensitive (`config.ts:120`), so `"ImageOS"` adds
   exactly one variable and keeps `CARGO CC CFLAGS CXX CMAKE RUST`. `ImageOS` is set into
   `/etc/environment` at image-build time by
   `images/ubuntu/scripts/build/configure-environment.sh:11–13`
   (`set_etc_environment_variable "ImageOS" "${IMAGE_OS}"`), and its value is the image
   generation: the Packer templates declare `variable "image_os" { default = "macos26" }`
   and `… = "macos15"` respectively
   (`images/macos/templates/macOS-26.arm64.anka.pkr.hcl:82–84`,
   `macOS-15.arm64.anka.pkr.hcl:82–84`), all retrieved 2026-09-17 from
   `actions/runner-images`. **One limit on that evidence, stated rather than glossed:** the
   *export* path I read is the Ubuntu one (`configure-environment.sh`); for macOS I have the
   Packer variable's value but did not read the script that places `ImageOS` into the job's
   environment. The variable is widely relied on across the Actions ecosystem on macOS
   runners, but this report does not assert it from a primary source — V9 in
   `### Validation strategy` is what confirms it is non-empty on `macos-latest`.
   **`ImageVersion` is deliberately *not* added**: it is the build
   id and changes roughly weekly, so including it would convert every image refresh into a
   total cache miss — trading failure mode A for failure mode B.
2. **`cache-on-failure: "true"`.** The default is `"false"`; `actions-rust-lang/setup-rust-toolchain`
   overrides it to `"true"` for its users. A template's most common CI loop is "a test
   failed, push a fix", and under the default that loop re-downloads and re-compiles the
   whole dependency graph every iteration. It is safe because P2 is enforced by the key,
   not by the save condition: a partially-built `target/` saved after a failure is still
   keyed to the exact lockfile and compiler that produced it, and Cargo's own fingerprints
   revalidate every unit on restore. `action.yml` implements it as
   `post-if: "success() || env.CACHE_ON_FAILURE == 'true'"`.
3. **`prefix-key: "v1-rslbp"`.** The default is `"v0-rust"`. A named, versioned prefix
   gives a forker of this template the documented escape hatch — bump `v1` to `v2` to
   invalidate every cache at once — without editing key logic. `astral-sh/uv` uses the same
   device (`prefix-key: v1-rust-workspace`).

**Defaults deliberately left alone, with the reason each was considered and kept.**

| Input | Default kept | Why |
|---|---|---|
| `cache-bin` | `"true"` | This is the input #341 implicates, and `tokio` disables it on macOS (`cache-bin: ${{ matrix.os != 'macos-latest' }}`). Keeping it is the reasoned position **because `env-vars: "ImageOS"` fixes the cause rather than dropping the feature**, and because the feature is worth keeping under R42: R42 installs dev tools with `cargo binstall --locked --no-confirm <name>@<version>`, those land in `$CARGO_HOME/bin`, and the prune rule removes only files present *before* the action ran — so a tool installed *after* the cache step is cached and the next run skips the download entirely. The action's own `binstall.yml` scenario workflow exercises exactly this ordering on all three OSes at the pin. **No stale-tool risk arises**, verified in `cargo-binstall`'s source: `PackageInfo::resolve` returns "already installed" only when `new_version == curr_version`, where `new_version` is what the requested version requirement resolves to (`crates/binstalk/src/ops/resolve.rs:520–528`, retrieved 2026-09-17), so R42's version-pinned spec reinstalls on a version bump even from a warm cache. **Integrity note, stated not resolved:** R42 records that the `cargo binstall` prebuilt path "carries a weaker integrity guarantee than the compile fallback it replaces"; caching `$CARGO_HOME/bin` means that verification runs once and the binary is then replayed from the cache on subsequent runs. Whether that is acceptable is R42's posture to hold, not this item's to change. |
| `add-job-id-key` | `"true"` | Gives each CI **job id** its own `target/` cache. Essential given the feature-gated web surface and the MSRV job — see `### Fit for this template`. **Its limit must be stated, because it is the one place this configuration can silently fail P1:** `config.ts:84` reads `process.env.GITHUB_JOB`, which is the YAML job id **and does not include matrix values**. A matrix dimension that changes the *build graph* without changing the lockfile, the `rustc` version, the OS/arch or a key env var — most plausibly a Cargo-feature leg such as `features: [default, web]` — therefore produces the **same key on every leg**, and the legs overwrite one another's cache. The fix costs one line and is the one R11 must apply if it chooses that topology: add `key: ${{ matrix.<dimension> }}`. The README sanctions exactly this — "An additional input `key` can be provided if the builtin keys are not sufficient" — and its `save-if` guidance names the same situation ("Useful for jobs where the matrix is additive e.g. additional Cargo features"). A matrix over `os` alone is already safe, because `{os.type()}-{os.arch()}` is in the key. |
| `add-rust-environment-hash-key` | `"true"` | This *is* P2. Turning it off removes the lockfile digest from the save key. |
| `workspaces` | `". -> target"` | Correct for a single Cargo workspace however many members R02 produces; `cargo metadata` enumerates them. Needed only for a second, separate workspace root or a relocated target dir. |
| `cache-all-crates`, `cache-workspace-crates` | `"false"` | `uv` sets `cache-workspace-crates: "true"`; that pays off for a very large workspace whose own crates are slow to build and rarely change. This template's own crates are small and change constantly, so caching them would spend budget on artifacts that are stale by construction. |
| `save-if` | `"true"` | **Conditional, and the one input P03 may need to change.** If P03 measures the template's total cache footprint approaching the **10 GB** repository budget — 2 OSes × the number of R11 jobs — the remedy is `save-if: ${{ github.ref == format('refs/heads/{0}', github.event.repository.default_branch) }}`, so pull requests restore from the default branch but never save. Not recommended pre-emptively: it removes intra-PR reuse, which is the reuse a contributor feels. |

R20 compliance is explicit: `Swatinem` is neither `actions` nor `github`, so the full
40-character SHA plus a trailing release comment is mandatory, and the recommended line
is written in that exact form. `astral-sh/uv` and `clap-rs/clap` both already pin this
identical SHA with this identical comment — independent confirmation that the form is
what Dependabot maintains in the wild.

### Ranked runner-up

**`actions-rust-lang/setup-rust-toolchain@ecabd13d1c56bd1345c230e542e9144811ad706f # v2.0.0`**,
used with `cache: true` (its default) and `cache-key`/`cache-on-failure` carrying the same
values recommended above.

**The condition under which it wins: if R42's implementation phase (P03) selects a
GitHub-Actions toolchain-install step rather than bare `rustup`.** In that case this
action installs the toolchain *from the `rust-toolchain.toml` R42 commits* and configures
the cache in the same block, which reproduces the py/ts single-step shape exactly and
removes one workflow step per job. Its cache behaviour is **not a different answer** — it
runs `Swatinem/rust-cache` at the identical commit `6323deb102c322ba6fcbdcafc7e3dddab59af2b6`.
The one gap to close if it wins: it exposes `cache-key` (→ `key`) and `cache-shared-key`
(→ `shared-key`) but **no `env-vars` passthrough**, so the `ImageOS` fix of
`### Recommendation` cannot be expressed through it. The substitute is
`cache-key: ${{ env.ImageOS }}`, which puts the same value in the key by a different
route. **That substitute is reasoned, not tested — P03 must validate it.**

Second runner-up, ranked below it: **`actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0`**
with a hand-written key. It wins only in a scenario this template does not have: a
repository forbidden from running third-party actions, where GitHub's `actions/` owner is
the only permitted source. Even then the key must be hand-built to match — at minimum
`${{ runner.os }}-${{ runner.arch }}-${{ env.ImageOS }}-${{ steps.toolchain.outputs.cachekey }}-${{ hashFiles('**/Cargo.lock') }}`
with a `restore-keys:` ladder dropping the lockfile hash, plus a manual `target/` prune
step — reimplementing, by hand and without tests, what the recommended action derives.

### Tradeoffs

**Versus `actions-rust-lang/setup-rust-toolchain` (runner-up 1).** Given up: one step per
job, and the py/ts "caching comes free with setup" shape that F035 records. Also given up:
`cache-on-failure: "true"` as a default someone else maintains. Accepted because the
alternative cost is worse — selecting it would decide *which tool provisions the Rust
toolchain in CI*, which this prompt's `## Out of scope` assigns to R42, and R42 is
**resolved** without naming a CI toolchain action. Deciding it here would settle a
resolved item's parameter from outside it. The cost of the standalone step is one workflow
line; the cost of the encroachment is a decision made in the wrong place.

**Versus `actions/cache` (runner-up 2).** Given up: a first-party-only dependency
surface, and a key a reader can see in full without reading TypeScript. Both are real
losses for a template meant to be forked and modified — the derived key is *opaque*, and
a forker who wants to change it must read `config.ts`. Accepted because the visible key
is visibly wrong: GitHub's own `examples.md:610–622` recipe has no `restore-keys`, no
`rustc` version, no `runner.arch`, and no `target/` pruning, so it fails P1 and P3 on
day one and degrades further with every fork edit. Opacity that is correct beats
transparency that is wrong, and the mitigation for the opacity is the `prefix-key`
escape hatch plus a comment in the workflow. The third-party-action risk is not waved
away: it is the exact risk R20's SHA-pin policy exists to bound, and the action's own
`check-dist.yml` verifies its committed bundle.

**Versus `sccache`.** Given up: sub-crate caching granularity, and reuse that survives
changes a directory cache cannot. Accepted because sccache is a *complement* whose cost
lands in the same 10 GB budget, and because adding a `RUSTC_WRAPPER` to a template
changes how every fork's builds are compiled — a large, surprising default for a
template. Revisit if P03 measures otherwise.

**Versus no cache (ripgrep, serde, `rust-lang/cargo`).** Given up: absolute simplicity,
zero third-party JavaScript in CI, and immunity to every cache-staleness failure mode in
this report. Accepted because those three projects have a dependency-to-own-code ratio
near zero and this template will not: a CLI parser, an error stack, a tracing pipeline,
an async runtime and a web framework are already decided or in flight. The honest
statement of the cost is that this template is accepting a **live, unfixed defect**
(#341) and a **bus factor of one** in exchange for CI time it has not yet measured.

### Parameters

This item `owns` no parameter (`## Couplings`: `owns:` is empty), so there is no
`owns <param> = <value>` line to write.

- `assumes rust-edition = 2024` — fixed, owner-decided 2026-09-02 (`docs/port/PARAMETERS.md`). Not load-bearing for this item; the cache mechanism is edition-independent.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — fixed. **Load-bearing**: the CI floor job runs a second toolchain, which the recommended key separates automatically via `getRustVersions` and doubles that job's cache footprint. Correct behaviour; a budget input.
- `assumes license = MIT OR Apache-2.0` — fixed. Not evaluated against any candidate: gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — fixed. **Load-bearing**: it is the whole of the MEDIUM question, and the `env-vars: "ImageOS"` recommendation exists because of the macOS half of it.
- `assumes package-manager-invocation = ` R42's resolved value (`docs/port/PARAMETERS.md`), specifically that crates.io dev tools are acquired by `cargo binstall --locked --no-confirm <name>@<version>` into `$CARGO_HOME/bin` and that a rustup component's presence is tested through the toolchain's component state. **Load-bearing** for the `cache-bin` decision, as analysed under `### Recommendation`.
- `assumes ci-job-structure = ` R11's value, **unresolved at retrieval** (`research/CLAUDE.md`: R11 `open`). The **choice of action** is independent of it. Two *configuration* details are not, and are handed to R11 rather than guessed: (a) the number of cache entries against the 10 GB budget is `2 × (number of job ids)`, which is the input to the `save-if` decision; (b) `add-job-id-key` separates by **job id only, not by matrix leg**, so if R11 expresses a build-graph-changing dimension (most plausibly a Cargo-feature leg) as a matrix inside one job rather than as separate jobs, that job must add `key: ${{ matrix.<dimension> }}`. Neither changes the recommendation; both are one line in R11's workflow.

**No `CONFLICT:` line is emitted.** No consumed parameter needs a different value for this
recommendation to hold.

**Handoff note to the controller, not a conflict.** `## Out of scope` assigns "which tool
provisions the Rust toolchain itself in CI" to R42, and R42's published `DECISION.md` is
**resolved without naming one** — a search of that file for `dtolnay`, `setup-rust-toolchain`,
`actions-rust-lang`, `rust-cache` and `Swatinem` returns nothing (run 2026-09-17). The gap
does not block this item: the recommended cache engine and every input value above are
**identical** under any of the three plausible CI toolchain-install steps (bare `rustup`,
`dtolnay/rust-toolchain`, or `actions-rust-lang/setup-rust-toolchain`), because the third
of those *is* the recommended engine at the same commit. The only thing that varies is
whether the cache is a standalone step or an input block, and the one behavioural
difference between those two forms is the missing `env-vars` passthrough recorded under
`### Ranked runner-up`. The controller should decide **where** that gap is closed — an R42
revision or a P03 implementation choice — rather than leaving it implicit.

### Migration implications

The Rust template does not exist; P03 builds it. These are the file-level changes this
decision *obliges* P03 to make, stated as obligations on a future tree.

1. **`.github/workflows/ci.yml` (created by R11)** — in every job that runs `cargo`, one
   step is added between the toolchain-install step and the first `cargo`/tool-install step:

   ```yaml
   # Rust-aware CI cache for ~/.cargo and target/ (R10).
   # Third-party action -> full-SHA pin + version comment (R20).
   # env-vars ImageOS keys the cache to the runner image generation, so a
   # macos-latest image bump cannot restore a stale ~/.cargo/bin (rust-cache#341).
   - uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2
     with:
       env-vars: "ImageOS"
       cache-on-failure: "true"
       prefix-key: "v1-rslbp"
   ```

   Ordering is a correctness requirement, not style, in both directions: **after** the
   toolchain step because the key reads `rustc -vV` and `rustup toolchain list`
   (`config.ts:390–415`) and a cache taken before the toolchain exists is keyed to the
   runner's preinstalled Rust; **before** the `just install-tool …` steps R42 implies, so
   that binstalled tools land in `$CARGO_HOME/bin` *after* the action's pre-existing-file
   snapshot and are therefore cached rather than pruned.
2. **`.github/dependabot.yml` (R19's file)** — the `github-actions` ecosystem must cover
   `/.github/workflows`, which is how the SHA pin and its `# v2.9.2` comment stay current.
   R20's recorded evidence is that Dependabot rewrites the comment to the upstream tag.
   No new ecosystem entry; a dependency on R19's existing one.
3. **Nothing in `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, the `Justfile`, or
   `lefthook.yml`.** This decision adds **no crate, no dev-dependency, no tool to R42's
   tool table, and no recipe.** It is CI-only. That is worth stating plainly because the
   item is registered `kind = crate`: the answer is an action, and it changes no Rust
   manifest.
4. **`docs/` (R81's surface)** — one short note is owed to a forker, because the two
   template-specific inputs are otherwise unexplained magic: that `prefix-key` is the
   manual cache-invalidation lever, and that `env-vars: "ImageOS"` must not be removed.
5. **`docs/port/COMMONALITY.md`** — F036's evidence note and F035's principle wording per
   the two `BASELINE-REVIEW:` lines above. **Proposed only**; this report changes no ledger
   row.

### Validation strategy

Nothing below was executed. This run had no GitHub Actions runner, and the template it
would run against does not exist. **Every check in this section is `planned`; zero are
`executed`.** The only commands actually run in this session were the read-only HTTP and
`gh api` retrievals listed under `### Sources`.

*Planned — the item-specific empirical acceptance check.* The realistic minimal example
is the template itself at P03: a workspace with the `[lib]` and the single `[[bin]] rslbp`
R49 fixed, a committed `Cargo.lock`, `rust-toolchain.toml`, and a CI job matrix over
`ubuntu-latest` and `macos-latest`.

| # | Check | Command / trigger | Expected result | Principle |
|---|---|---|---|---|
| V1 | Warm cache is reused | Run CI twice on an unchanged tree. Read the action's own log lines and the step output `cache-hit`; run `cargo build --timings` or `CARGO_LOG=cargo::core::compiler::fingerprint=info cargo build -v` on the second run | `cache-hit == 'true'`; no dependency unit recompiles; the second run's `cargo build` wall time is a small fraction of the first's | P1 |
| V2 | A changed dependency set can never hit an exact match | `cargo update -p <one transitive dep> --precise <newer>`; commit `Cargo.lock`; re-run | `cache-hit == 'false'`, **and** the run still restores through the restore key: only the changed dependency and its dependents recompile, not the whole graph | P2 **and** P1 — this single check is the one that distinguishes the recommended action from GitHub's published `actions/cache` recipe, which would rebuild everything |
| V3 | A toolchain change partitions the cache | Bump `rust-toolchain.toml`'s channel, or compare the `stable` job against the MSRV-floor job in the same run | Distinct cache entries; no `target/` restored across `rustc` versions | P2 |
| V4 | The two fixed runners do not share a cache | Inspect the cache list for the run (`gh api repos/<o>/<r>/actions/caches`) | Separate entries for `ubuntu-latest` and `macos-latest`; keys differ in the `{os.type()}-{os.arch()}` segment | P2, MEDIUM question |
| V5 | R42's tools survive the cache and are not stale | Run CI; then bump one tool's version in the `Justfile` tool table and re-run | Run 1: tool present from cache, no download. Run 2: `cargo binstall` installs the **new** version despite the warm cache (predicted by `resolve.rs:520–528`, not observed) | P1, P2 |
| V6 | Footprint stays inside the budget | `gh api repos/<o>/<r>/actions/cache/usage` after a full matrix run | `active_caches_size_in_bytes` well under 10 GB; if not, apply the `save-if` remedy from `### Recommendation` | P3 |
| V7 | Pruning works | After ~10 runs with dependency churn, re-read V6 | Total does not grow monotonically | P3 |
| V8 | R20 conformance | The R20 CI checks (SHA-pin rule and comment-grammar rule, disjoint jobs) | Both pass on the added `uses:` line | R20 |

*Planned — and explicitly not simulable.* **V9, the `ImageOS` regression.** The failure
`env-vars: "ImageOS"` prevents can only be observed when GitHub next repoints
`macos-latest` to a new image generation. It cannot be forced in CI and is not simulable
here. P03 should record the value of `$ImageOS` on both runners in the job log
(`- run: echo "ImageOS=$ImageOS"`) so that the key's dependence on it is *visible*, and
confirm the value is non-empty — `config.ts:120` only folds an environment variable into
the key `&& value`, so an empty `ImageOS` would silently contribute nothing.

*Also unverified and owed to P03:* the `cache-key: ${{ env.ImageOS }}` substitute named
under `### Ranked runner-up`, if that branch is taken.

### Confidence & re-verify trigger

**High** on the choice of mechanism. It is over-determined: the engine is the same one
reached by every serious alternative path, two of the most relevant reference projects
(`astral-sh/uv`, `clap-rs/clap`) already pin the exact recommended SHA, and the key
strategy was read from the implementation at that commit rather than from its
documentation.

**High** on the key-strategy answer to the HIGH question — it is a source-level reading,
and the contrast with GitHub's published recipe is verbatim from `examples.md`.

**Medium** on the `env-vars: "ImageOS"` remedy. The *defect* is high-confidence:
reproduced by three parties in issue #341, explained by the key derivation in `config.ts`,
and unfixed in the CHANGELOG at the recommended pin. The *fix* is reasoned from source
(`config.ts:111–126`) and from the image-build scripts, **not observed working**, and its
first real test is the next `macos-latest` image bump.

**Medium** on the `save-if` guidance: it depends on a footprint measurement that cannot be
made before the template exists and before R11 fixes the job count.

**Low-to-medium** on the claim that `cache-bin: "true"` is net-positive under R42. The
no-stale-tool half is high-confidence (source-verified). The *desirability* half trades a
live macOS defect and a weaker install-integrity replay against saved download time, and
that trade is a judgement P03's measurements should re-open.

**Re-verify triggers.**

1. **`Swatinem/rust-cache` publishes v3, or any release that changes key derivation.** Re-read `src/config.ts`; every claim in `### Principles and implementation` is pinned to `6323deb…`.
2. **GitHub repoints `macos-latest` to a new image generation.** This is when V9 either validates or falsifies the `ImageOS` remedy. Watch `actions/runner-images` announcements.
3. **R42 is revised to name a CI toolchain-install action.** If it names `actions-rust-lang/setup-rust-toolchain`, this item's recommendation collapses into that step and the `env-vars` passthrough gap must be closed.
4. **R11 resolves with a job count materially above ~6 per OS**, or P03's V6 measurement approaches 10 GB. Re-open `save-if` and `cache-targets`.
5. **`Swatinem` stops releasing** — the single-maintainer risk. Trigger: no release *and* no commit for 9 months, or an unanswered security-relevant issue. `actions-rust-lang/setup-rust-toolchain`'s maintainers are the natural successors, since they already vendor the pin.
6. **GitHub changes the cache service or its limits again**, as it did on 2025-02-01 with the v2 backend. That migration hard-failed workflows on deprecated action versions; a pinned SHA does not protect against a service-side change, only a release does.

### Sources

All retrieved **2026-09-17 (UTC)** unless stated. `gh api <path>` denotes an authenticated
`https://api.github.com/<path>` request; no token value was printed or recorded.

**Source repositories, read through their pins (never from a working tree):**
- py `.github/workflows/ci.yml` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` — `git -C ~/c/py-launch-blueprint show b08bccfb:.github/workflows/ci.yml`. Line 87 `uses: astral-sh/setup-uv@v8.3.2`, with no cache input, repeated at 106, 128, 160, 214, 238. **All six are tag pins at this commit**, consistent with the role file's note that the py repository is entirely tag-pinned at the programme pin and SHA-pinned at HEAD.
- ts `.github/workflows/ci.yml` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` — `git -C ~/c/ts-launch-blueprint show cb1cbcb2:.github/workflows/ci.yml`. Lines 69–74: `actions/setup-node@v7` with `cache: 'pnpm'` and the in-file comment citing D-022(3); line 62 `pnpm/action-setup@0ebf47130e4866e96fce0953f49152a61190b271 # v6.0.9`; repeated at 163–166.

**Programme documents:** `docs/port/PARAMETERS.md` (the four fixed parameters and R42's `package-manager-invocation` value); `docs/port/COMMONALITY.md:41–42` (F035, F036); `research/topics/42-dev-toolchain-provisioning/DECISION.md` (revision 10, 2026-09-14 — layers 1, 2 and 5, the 2026-09-12 owner ruling, the binstall integrity paragraph); `research/topics/20-third-party-action-pinning-policy/DECISION.md` (revision 2, 2026-09-10 — `## Decision`, `enforced-owner-prefix-pinning`); `research/CLAUDE.md` (R11 status); `docs/port/OWNER-REVIEW.md` per the task's citation of the 2026-09-12 (Q7.B) ruling.

**GitHub REST (`gh api`):** `repos/{Swatinem/rust-cache, actions/cache, actions-rust-lang/setup-rust-toolchain, mozilla-actions/sccache-action, moonrepo/setup-rust, dtolnay/rust-toolchain, mozilla/sccache, Leafwing-Studios/cargo-cache, useblacksmith/rust-cache}`; `.../releases/latest` and `.../releases?per_page=8`; `search/issues?q=repo:<o>/<r>+is:issue+is:open`; `repos/Swatinem/rust-cache/issues?state=all&sort=created&direction=desc&per_page=100` and `.../issues/{n}` + `.../issues/{n}/comments` for #381, #375, #374, #370, #369, #352, #348, #344, #341, #337; `repos/Swatinem/rust-cache/commits?per_page=10`; `git/ref/tags/<tag>` and `git/tags/<sha>` for the four pins dereferenced in this report; `contents/` reads of `Swatinem/rust-cache` `action.yml`, `README.md`, `CHANGELOG.md`, `src/config.ts`, `.github/workflows/{simple,binstall,install,workspaces}.yml` (all at `?ref=6323deb102c322ba6fcbdcafc7e3dddab59af2b6`); `actions-rust-lang/setup-rust-toolchain` `action.yml` + `README.md` at `?ref=ecabd13d1c56bd1345c230e542e9144811ad706f` and `releases/tags/v2.0.0`; `actions/cache` `README.md` + `examples.md` at `?ref=55cc8345863c7cc4c66a329aec7e433d2d1c52a9`; `Mozilla-Actions/sccache-action` `README.md` at `?ref=fc920bf0ec8de6ee65d409111f7ec508035751ba`; `dtolnay/rust-toolchain` `README.md`; `Leafwing-Studios/cargo-cache` `action.yml` and `moonrepo/setup-rust` `action.yml` (default branch, to establish what each actually calls); `cargo-bins/cargo-binstall` `crates/bin/src/args.rs` and `crates/binstalk/src/ops/resolve.rs`; `actions/runner-images` `images/ubuntu/scripts/build/configure-environment.sh`, `images/macos/templates/macOS-26.arm64.anka.pkr.hcl`, `images/macos/templates/macOS-15.arm64.anka.pkr.hcl`; `astral-sh/uv` `.github/workflows/` listing and `test.yml`; `clap-rs/clap`, `tokio-rs/tokio`, `BurntSushi/ripgrep`, `serde-rs/serde`, `rust-lang/rust-analyzer`, `rust-lang/cargo` workflow files; `search/code?q=repo:<o>/<r>+Swatinem%2Frust-cache+in:file+path:.github/workflows` for the adoption counts.

**crates.io (with a `User-Agent` header):** `GET https://crates.io/api/v1/crates/sccache` → `crate.recent_downloads` 129817, `crate.downloads` 1335826, `crate.max_stable_version` 0.18.0. `GET https://crates.io/api/v1/crates/sccache/versions` → newest unyanked `num` 0.18.0, `created_at` 2026-09-16T14:34:17.177895Z, `license` Apache-2.0, `rust_version` 1.91.0.

**RustSec:** `https://rustsec.org/packages/sccache.html` → HTTP **404** (no advisory page ⇒ no open advisory). Controls run the same minute: `https://rustsec.org/packages/atty.html` → **200**; `https://rustsec.org/packages/serde.html` → **404**.

**Rust release channel:** `GET https://static.rust-lang.org/dist/channel-rust-stable.toml` → `date = "2026-09-03"`, `[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`.

**GitHub documentation:** `https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching` — quoted verbatim in `### Principles and implementation`: "By default, the limit is 10 GB per repository, but this limit can be increased by enterprise owners, organization owners, or repository administrators."; "GitHub will remove any cache entries that have not been accessed in over 7 days."; on exceeding capacity, "the cache eviction policy will create space by deleting the caches in order of last access date, from oldest to most recent."; "Workflow runs cannot restore caches created for child branches or sibling branches."; and the finding that keys are **not** automatically scoped by runner OS or architecture — the reference example has to write `${{ runner.os }}` into the key by hand.

**Method notes.** Figures came from the endpoints named in `## Required evidence` and above;
web search was used once, only to locate the `actions/runner-images` files that were then read
through `gh api` as the primary source. The role file's instruction not to list the run's `raw/`
directory was observed: no listing of `raw/` was performed, and this file was written by its
full path. No git command that modifies anything was run; nothing was committed.
**What I could not verify, stated as gaps rather than filled in:** (1) **No CI was executed** —
the template does not exist, so every check in `### Validation strategy` is `planned` and
none is `executed`; no build-time or cache-restore-time figure is asserted anywhere in this
report, and any speedup claim would have been an invention. (2) The **`env-vars: "ImageOS"`
remedy is reasoned from `config.ts:111–126` and the `runner-images` Packer templates, not
observed working**; its first real test is the next `macos-latest` image generation change. I read the `ImageOS` *export* mechanism in the Ubuntu image-build script only; the macOS export path was **not read**, so that half rests on the Packer variable's value plus ecosystem-wide reliance, not on a primary source.
(3) The **`cache-key: ${{ env.ImageOS }}` substitute** for the runner-up path is reasoned,
not tested. (4) `sccache`'s **`unsafe` posture was not inspected**; it is a standalone runner
binary and never enters the template's dependency tree, but the gate-3 sub-question is
recorded as unanswered rather than asserted. (5) Adoption for **`helix-editor/helix` and
`starship/starship` rests on the code-search `total_count` only** (1 hit each); I did not
open the individual workflow lines, so those two rows are weaker evidence than `uv`, `clap`
and `tokio`, whose exact lines are quoted. (6) Two code searches — `rust-lang/cargo` and
`denoland/deno` — **returned HTTP 403 "API rate limit exceeded"** on the first pass; I
re-checked `rust-lang/cargo` directly through the contents API (`.github/workflows/main.yml`,
no cache action present) and **dropped `denoland/deno` entirely rather than report a count I
did not retrieve**. (7) `rust-analyzer`'s reason for commenting out its cache step is not
stated in the file at the revision read, and I did not reconstruct it from history. (8) The
**`moonrepo/setup-rust` licence is `null`** in the API response — recorded as the figure it
is; per the owner ruling it was not evaluated and excluded nothing.
