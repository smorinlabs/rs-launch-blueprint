# 2026-09-17 — R10 — dependency-cache-action (crate, Focused) — decision (revision 1)

## Decision

**Recommendation: adopt `Swatinem/rust-cache`, referenced from every CI job that
runs `cargo` as**

```yaml
# Rust-aware CI cache for $CARGO_HOME and target/ (R10).
# Third-party action -> full-SHA pin + version comment (R20).
# env-vars ImageOS keys the cache to the runner image generation, so a
# macos-latest image bump cannot restore a stale $CARGO_HOME/bin
# (Swatinem/rust-cache#341, live at this pin).
- uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2
  with:
    env-vars: "ImageOS"
    cache-on-failure: "true"
    prefix-key: "v1-rslbp"
```

**Version.** The pinned commit is `6323deb102c322ba6fcbdcafc7e3dddab59af2b6`,
which is release `v2.9.2`. The tag-to-commit resolution was executed here, not
copied: `GET https://api.github.com/repos/Swatinem/rust-cache/git/ref/tags/v2.9.2`
returns an annotated tag object `63fed3e2fecf6f7b51dc6f043341b79ef82a9ae7`, and
`GET https://api.github.com/repos/Swatinem/rust-cache/git/tags/63fed3e2fecf6f7b51dc6f043341b79ef82a9ae7`
returns commit `6323deb102c322ba6fcbdcafc7e3dddab59af2b6` (retrieved 2026-09-17
UTC; `review/evidence/r10-pinned-sources.log`, assertions A1.1–A1.4). The
**accepted version range is `>= 2.9.1, < 3`**. The floor is 2.9.1 and not 2.9.0
because 2.9.0 shipped a defect in the exact mechanism this recommendation rests
on: the `CHANGELOG.md` at the pin records 2.9.1's sole entry as
`Fix regression in hash calculation` (assertion A4.2). The ceiling is `< 3`
because a major version is free to change the key derivation that every claim
below is read from.

**Placement.** A standalone step, **after** the toolchain-install step and
**before** the first `cargo` or tool-install step. Both directions are
correctness requirements, not style, and the reasons are given under
`### Principles and implementation`.

**Ledger rows settled.** `F036` — *Dependency caching built into the
language-setup action (tool)*, `ci-workflows`, origin `same`, verdict
`COMMON → SUBSTITUTE`, item `R10` (`docs/port/COMMONALITY.md:42`, assertion
A9.7). Its parent pattern row `F035` (`docs/port/COMMONALITY.md:41`,
`COMMON → REUSE`, assertion A9.6) is **confirmed, not amended**: this item's
findings agree with the 2026-09-04 restatement already on that row. One
`BASELINE-REVIEW:` line is raised against F036's *evidence note only* and is
carried in full under `### Principles and implementation`. This decision changes
no ledger row, prompt, index or registry.

**Status of this document.** Every decision in this programme is a **proposal
validated in the implementation phase** (owner ruling, 2026-09-10). It records
what the research found and what it recommends. **Nothing was built here.** The
`rs-launch-blueprint` template does not exist yet; P03 builds it, and P03's CI
proves this recommendation. **No CI run was possible from this machine** — there
is no workflow, no repository under GitHub Actions and no runner — so every
behavioural claim about cache hits, misses, restores and build time is recorded
as *planned* under `## Engines` and none is reported as observed. A decision
that does not survive implementation is revised against this recorded research,
rather than researched again from scratch.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`**
(`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check for anything the
template uses", assertion A9.5). The licence of every candidate is recorded as a
figure and **excludes nothing**. For the recommended action the figure is
`LGPL-3.0` (`.license.spdx_id`,
`GET https://api.github.com/repos/Swatinem/rust-cache`, retrieved 2026-09-17;
`review/evidence/figures/repo-Swatinem_rust-cache.json`), corroborated by the
bundled `LICENSE` file at the pinned commit (assertion A5.1). This is the single
point on which the two engines' recommendations differ, and settling it settles
the item; see `## Engines`.

**Item kind is `crate`; the answer is a GitHub Action.** `research/CLAUDE.md`
registers R10 with `kind = crate`, but the mechanism that caches Cargo's
registry, git checkouts and `target/` on GitHub Actions is an action, not a
crates.io package. The consequence is stated rather than hidden: **no crate
figure exists for the recommended candidate.** `crate.recent_downloads` and
`crate.downloads` are recorded as `inapplicable — not a crates.io package`, and
GitHub stars, releases and issue figures are substituted with their endpoints
named. The one true crate in the candidate set is `sccache`, and its crate
figures are reported in full. This decision adds **no crate, no dev-dependency
and no Cargo feature** to the template: it is CI-only.

**The four questions this item's prompt asks, answered.**

**HIGH — `Swatinem/rust-cache` or a hand-rolled `actions/cache` step?**
`Swatinem/rust-cache`, and the deciding property is that **its key is derived
rather than written down**. For a template meant to be forked and modified, a
fork that adds a dependency, adds a workspace member, changes `RUSTFLAGS` or
bumps `rust-toolchain.toml` gets a correct key with no workflow edit. Every
hand-rolled key must be re-derived by hand on each of those events and degrades
silently when it is not. The template also does not lose `actions/cache`: the
recommended action is a layer over the same GitHub cache service.

**HIGH — what cache-key strategy avoids both failure modes?** A **two-key
split**, read from `src/config.ts` at the pinned commit rather than from any
documentation (assertions A3.1–A3.8):

| Key | Composition | Failure mode it closes |
|---|---|---|
| **restore key** | `prefix-key` + (`shared-key`, or `key` and `GITHUB_JOB`) + `os.type()` + `os.arch()` + `sha1(`every installed toolchain's `rustc -vV`, plus every environment variable whose name starts with `CARGO`, `CC`, `CFLAGS`, `CXX`, `CMAKE`, `RUST` or an `env-vars` entry`)` | invalidating too eagerly: a lockfile edit still restores the newest cache that agrees on compiler, runner and flags, and Cargo's own fingerprints rebuild only what changed |
| **save key** | the restore key **plus** `sha1(` a normalised parse of every workspace `Cargo.toml` and `Cargo.lock`, every `rust-toolchain{,.toml}` and every `.cargo/config.toml` `)` | never invalidating: a changed resolved dependency set can never produce an exact-key hit |

The save key is strictly finer than the restore key. That asymmetry is the whole
answer, and it is exactly what a hand-written key most often omits: GitHub's own
published Rust recipe (`actions/cache` `examples.md:610–622` at tag `v6.1.0`,
commit `55cc8345863c7cc4c66a329aec7e433d2d1c52a9`) is
`key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}` with **no
`restore-keys` at all**, no compiler identity, no runner architecture and no
pruning — verified verbatim here, assertions A7.1–A7.3.

**MEDIUM — does behaviour differ across `ubuntu-latest` and `macos-latest`?**
The action's inputs, `restore-keys` semantics and save-on-failure semantics are
platform-neutral, and GitHub's storage budget and eviction policy are
per-repository rather than per-OS. **One difference matters, and it is a live
defect.** The key ends in `os.type()`-`os.arch()`, which on GitHub-hosted macOS
is `Darwin`-`arm64` both before and after GitHub repoints `macos-latest` to a
new image generation, so the runner *image* is not in the key. Issue
`Swatinem/rust-cache#341` — "``cache-bin: true`` breaks cargo subcommands on new
github macos runner", opened 2026-05-13, **closed** 2026-05-29 with 5 comments
(`GET https://api.github.com/repos/Swatinem/rust-cache/issues/341`, retrieved
2026-09-17) — is that defect observed: a cache saved on the old image restored
`$CARGO_HOME/bin` onto the new one and broke the rustup shims. **The CHANGELOG
at the recommended pin records no image-keying fix for it**: a case-insensitive
search over the whole file returns zero lines matching `imageos`, `runner image`,
`image generation`, `macos-latest` or `341` (assertion A4.5). That negative is
bounded rather than absolute — the file does carry exactly two macOS entries,
`Only run macOsWorkaround() on macOS` (2.7.5) and `Work around macOS cache
corruption.` (1.0.1), both printed verbatim in the log and both the
`macOsWorkaround` for `rust-lang/cargo#8603` and `actions/cache#403`, which is a
different defect from #341 (assertion A4.6). The load-bearing proof that the
#341 behaviour is live at `v2.9.2` is not the CHANGELOG's silence but the key
itself: it still ends in `os.type()`-`os.arch()` with no image component
(assertions A3.4 and A3.5). The template must therefore close it in its own
configuration, which is what `env-vars: "ImageOS"` is for.

**LOW — extra configuration for a multi-crate workspace?** No input is needed
for the workspace R02 may produce. The manifest digest normalises
`package.version` to `"0.0.0"` and blanks path dependencies, and the `Cargo.lock`
digest keeps only packages carrying a `source` or `checksum` key — that is,
**it excludes the workspace's own crates** (assertion A3.8). A version bump or an
edit to a sibling crate therefore does not discard the dependency cache, and
`cargo metadata` enumerates the members, so `workspaces: ". -> target"` (the
code default read from `src/config.ts`, not an `action.yml` `default:` key) is correct for one workspace root however many members it has. The
`workspaces:` input is needed only for a genuinely separate workspace root or a
relocated target directory. **One configuration caveat is handed to R11 rather
than guessed:** `add-job-id-key` reads `process.env.GITHUB_JOB` (assertion A3.6),
which is the YAML job id and **does not include matrix values**, so a matrix
dimension that changes the build graph without changing the lockfile, the
compiler, the OS or a keyed environment variable — most plausibly a Cargo-feature
leg such as `features: [default, web]` — produces the same key on every leg and
the legs overwrite one another's cache. The fix is one line, `key: ${{ matrix.<dimension> }}`,
and it belongs in R11's workflow. A matrix over `os` alone is already safe.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** `F035` (`docs/port/COMMONALITY.md:41`, `COMMON → REUSE`) states the
principle: *dependency fetches and Cargo build artifacts are reused across CI
runs rather than re-fetched and re-built on every run.* The row already carries
its 2026-09-04 restatement recording that "integrated into the language-setup
step" was the py/ts **mechanism**, not the principle. Agreement is required at
the level of a **capability plus a correctness policy**, not at the level of a
named action and not at the level of an architectural pattern:

- **P1 — Reuse.** A run whose resolved dependency set and toolchain are
  unchanged must not re-download or re-compile that dependency set.
- **P2 — Never serve a stale dependency.** A run whose resolved dependency set
  has changed must not be able to link an artifact built from the previous set.
- **P3 — Bounded cost.** The cache must not grow without bound into the
  repository's shared storage budget, and this mechanism's own leftovers must not
  cause eviction of the repository's other caches.

**What must agree; what may vary.** *Must agree*: the key carries the compiler
identity, the runner identity and a digest of the resolved dependency set; and
the save key is strictly finer than the restore key. *May vary*: which action
delivers that key, whether the cache is a standalone step or an input block on a
toolchain-setup step, and per-job tuning (`save-if`, `cache-targets`, an extra
`key` segment).

**Does the py/ts pattern remain appropriate in Rust? Partly, and this is where
the ecosystem genuinely needs a different design.** py gets its cache from
`astral-sh/setup-uv` with no cache input (py `.github/workflows/ci.yml` at the
programme pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, six `setup-uv` clauses,
assertion A12.py); ts gets its cache from `actions/setup-node` with
`cache: 'pnpm'` (ts `.github/workflows/ci.yml` at the programme pin
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, two `cache: 'pnpm'` clauses,
assertion A12.ts). Both cache **one** thing — a package manager's download store,
keyed on a lockfile. Neither ecosystem has a compiled-artifact directory, so
neither source mechanism ever had to answer the question that dominates in Rust:
`target/` is simultaneously the expensive cache and the dangerous one. It is
large enough to matter against the repository storage budget; it is invalidated
by things a lockfile hash cannot see (the `rustc` version, `RUSTFLAGS`, the target
triple); and it accumulates artifacts no current dependency needs. Porting
"hash the lockfile, cache the store" straight across reproduces the py/ts shape
and fails P1 and P3 in Rust. **The principle ports; the mechanism must not.**

**Architectural alternatives, compared before libraries.**

| Alternative | P1 Reuse | P2 No stale dependency | P3 Bounded cost | Verdict |
|---|---|---|---|---|
| **A. No cache** — the choice of `rust-lang/cargo`, `BurntSushi/ripgrep` and `serde-rs/serde` | fails by construction | trivially holds | trivially holds | **Rejected on fit.** Those three have a dependency-to-own-code ratio near zero. This template is a CLI plus a library plus an optional web service, whose tree already includes a CLI parser (R60), an error stack (R67) and, behind the `web` feature (R69), `axum` and `tokio` — so dependency rebuild is the dominant CI cost, not a rounding error |
| **B. `actions/cache` with a hand-written key** | depends entirely on the key written; GitHub's *published* Rust recipe fails it outright (no `restore-keys`, assertion A7.2) | holds if, and only if, the author puts the compiler identity in the key — the published recipe does not (assertion A7.3) | fails: `target/` is never pruned, so every lockfile change writes a new multi-hundred-megabyte entry and nothing is ever removed | **Runner-up, second-ranked.** Not rejected as incapable — a carefully hand-written key satisfies P1 and P2 — but rejected as the default for a *template*, because the key must be re-derived by hand on every fork edit and no pruning exists at all |
| **C. Compiler-level object cache** — `sccache` via `RUSTC_WRAPPER` | partial: survives some changes a directory cache cannot, but on the GitHub backend competes for the same storage budget | holds: content-addressed by compiler input | weakest: doubles the storage claim when run alongside a directory cache | **Rejected as the default, retained as an up-and-comer.** It caches compiler outputs, not the Cargo registry, git checkouts and `target/` this item must cache; it is a complement, not a substitute |
| **D. Rust-aware directory cache with a derived key** — `Swatinem/rust-cache` | holds, by the restore key | holds, by the save key | holds: it prunes before saving and sets `CARGO_INCREMENTAL=0` | **Selected** |
| **E. D packaged inside the toolchain-setup step** — `actions-rust-lang/setup-rust-toolchain` | identical to D — it *is* D | identical to D | identical to D | **Runner-up, first-ranked.** Not a different cache: its `action.yml` line 263 at commit `ecabd13d1c56bd1345c230e542e9144811ad706f` reads `uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2` — the identical commit this decision pins (assertion A6.1) |

**Why the selected design preserves each principle.** P1 and P2 are the two-key
split tabulated above, read from the implementation at the pin. P3 is pruning
before save: files present in `$CARGO_HOME/bin` before the action ran,
dependencies no longer used, non-dependencies, incremental artifacts and
artifacts older than one week are removed, and `CARGO_INCREMENTAL=0` is set. The
budget figure that bounds P3 is GitHub's documented 10 GB per repository with
eviction of entries unused for 7 days and, on overflow, deletion by oldest last
access (`https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching`,
retrieved 2026-09-17). **That figure is carried from `raw/opus.md` and was
not re-queried in this run**; every later mention of *the 10 GB budget* in
this decision — in the `save-if` row, in acceptance criterion A5, in the
`re-verify:` line and in unproven row U9 — refers to this sentence and to
that limit.

**Why exactly three inputs, and why every other default is kept.**

| Input | Value | Ground |
|---|---|---|
| `env-vars` | `"ImageOS"` | **The correctness fix, and the answer to the MEDIUM question.** The `env-vars` input is *appended* to the built-in prefix list `CARGO CC CFLAGS CXX CMAKE RUST` rather than replacing it (assertion A3.2), and matching is a case-sensitive `startsWith` that additionally requires a non-empty value (assertion A3.3) — so `"ImageOS"` adds exactly one variable and keeps the six built-ins. `ImageVersion` is deliberately **not** added: it is the image build id, it moves roughly weekly, and including it would turn every image refresh into a total miss — trading one failure mode for another |
| `cache-on-failure` | `"true"` | The input's own description at the pin reads "Cache even if the build fails. Defaults to false." (assertion A2.6) and `post-if: "success() \|\| env.CACHE_ON_FAILURE == 'true'"` implements it (assertion A2.2). A template's most common CI loop is *a test failed, push a fix*; under the default that loop re-downloads and re-compiles the whole dependency graph on every iteration. It is safe because **P2 is enforced by the key, not by the save condition**: a partially-built `target/` saved after a failure is still keyed to the exact lockfile and compiler that produced it, and Cargo's fingerprints revalidate every unit on restore |
| `prefix-key` | `"v1-rslbp"` | The default is `"v0-rust"` (assertion A2.3). A named, versioned prefix gives a forker the documented escape hatch — bump `v1` to `v2` to invalidate every cache at once — without touching key logic |
| `add-job-id-key` | *default* `"true"` | Gives each CI job id its own `target/` cache, which the feature-gated web surface and the MSRV floor job both need. Its limit is the matrix caveat handed to R11 above |
| `add-rust-environment-hash-key` | *default* `"true"` | This **is** P2. Turning it off removes the lockfile digest from the save key |
| `cache-bin` | *default* `"true"` | This is the input issue #341 implicates, and keeping it is a reasoned position rather than an oversight: `env-vars: "ImageOS"` addresses the cause instead of dropping the feature, and the feature pays under R42, whose recipe body installs dev tools with `cargo binstall --locked --no-confirm <name>@<version>` into `$CARGO_HOME/bin` (assertion A9.3). Because the prune rule removes only files present *before* the action ran, a tool installed after the cache step is cached. **Integrity note, stated and not resolved here:** R42 records that the `cargo binstall` prebuilt path carries a weaker integrity guarantee than the compile fallback it replaces; caching `$CARGO_HOME/bin` means that verification runs once and the binary is replayed from cache thereafter. Whether that is acceptable is R42's posture to hold, not this item's to change |
| `cache-all-crates`, `cache-workspace-crates` | *defaults* `"false"` | This template's own crates are small and change constantly, so caching them would spend budget on artifacts that are stale by construction |
| `save-if` | *default* `"true"` | **The one input P03 may need to change.** If P03 measures the footprint approaching the 10 GB budget, the remedy is `save-if: ${{ github.ref == format('refs/heads/{0}', github.event.repository.default_branch) }}`. Not applied pre-emptively: it removes intra-pull-request reuse, which is the reuse a contributor feels |
| `cache-targets`, `cache-provider` | *defaults* `"true"`, `"github"` | Correct as they stand; `cache-provider: warpbuild` would introduce a third-party data processor into a public template and is not recommended |
| `workspaces` | *code default* `". -> target"` | Correct for one Cargo workspace however many members R02 produces, because `cargo metadata` enumerates them. Needed only for a second, separate workspace root or a relocated target directory |

**Where each of those values was read, stated exactly rather than in bulk.**
Eight are literal `default:` keys in `action.yml` at the pinned commit, asserted
one by one — `add-job-id-key`, `add-rust-environment-hash-key`, `cache-targets`,
`cache-all-crates`, `cache-workspace-crates`, `save-if`, `cache-bin` and
`cache-provider` (assertion group A2.7, eight result lines). `prefix-key`'s
`"v0-rust"` is assertion A2.3. **`cache-on-failure` carries no `default:` key at
all**: its default of `false` is documented in its own description text, which is
what assertion A2.6 asserts, and its effect is implemented by the `post-if`
expression of assertion A2.2. **`workspaces` likewise carries no `default:`
key**: its effective `". -> target"` behaviour is a code default in
`src/config.ts` — `core.getInput("workspaces") || "."`, with the target segment
defaulting to `target` — which was read at the pin but is not separately
asserted.

**R20 compliance is explicit.** `Swatinem` is neither `actions` nor `github`, so
R20's published rule applies: the clause is pinned to a full 40-character commit
SHA and carries a trailing release comment (`research/topics/20-third-party-action-pinning-policy/DECISION.md`,
assertion A9.4). The recommended line is written in exactly that form.

**Reference implementations, and the counter-evidence.** The closest reference is
`astral-sh/uv` — the Rust implementation of the very tool that supplies py's
precedent — whose `.github/workflows/test.yml` runs bare
`rustup toolchain install --profile minimal` and then `Swatinem/rust-cache`
pinned by full SHA with a version comment, plus `prefix-key`, an explicit `key`
and `save-if`. `clap-rs/clap` is the second, at eight call sites and the same
pin; `tokio-rs/tokio`, `astral-sh/ruff`, `helix-editor/helix` and
`starship/starship` also adopt it. Those adoption readings are **carried from
`raw/opus.md` and were not re-executed here**, because they rest on
`GET https://api.github.com/search/code`, which rate-limited that report itself
(it returned HTTP 403 twice and dropped one project rather than report an
unretrieved count) and is the least reproducible endpoint in the required-evidence
table. The counter-evidence is reported with equal weight: `rust-lang/cargo`,
`BurntSushi/ripgrep` and `serde-rs/serde` cache **nothing**, and
`rust-lang/rust-analyzer` has its cache step commented out. Alternative A above
states why their shape is not this template's shape.

**Observable acceptance criteria.** These are the criteria P03's CI must
demonstrate; none is demonstrated here.

1. **A1 (P1).** Two consecutive runs on an unchanged tree: the second reports the
   step output `cache-hit == 'true'` and recompiles no dependency unit.
2. **A2 (P2 and P1).** A `Cargo.lock` change: `cache-hit == 'false'`, **and** the
   run still restores through the restore key, so only the changed dependency and
   its dependents recompile. This single criterion is what distinguishes the
   recommendation from GitHub's published `actions/cache` recipe, which rebuilds
   everything.
3. **A3 (P2).** A toolchain change — including the MSRV floor job beside the
   stable job — produces distinct cache entries and restores no `target/` across
   `rustc` versions.
4. **A4 (P2, MEDIUM question).** `ubuntu-latest` and `macos-latest` never share a
   cache entry; their keys differ in the `os.type()`-`os.arch()` segment, and
   with `env-vars: "ImageOS"` also in the environment digest.
5. **A5 (P3).** After a full matrix run, `active_caches_size_in_bytes` from
   `GET /repos/<o>/<r>/actions/cache/usage` is well inside the 10 GB budget and
   does not grow monotonically across runs with dependency churn.
6. **A6 (R20).** The added `uses:` clause passes both R20 checks — the SHA-pin
   rule and the comment-grammar rule.
7. **A7 (ImageOS).** `$ImageOS` is non-empty in the job environment on **both**
   runners. This is not a formality: see the finding below.

**A finding this synthesis adds, which neither raw report established.** Opus
recommended `env-vars: "ImageOS"` and recorded, honestly, that it had read the
Ubuntu export path only. Both paths were read here (assertions A8.1 and A8.2),
and **they are not equivalent**:

- Ubuntu: `images/ubuntu/scripts/build/configure-environment.sh` calls
  `set_etc_environment_variable "ImageOS" "${IMAGE_OS}"`, writing it to
  `/etc/environment`, which every process on the runner inherits.
- macOS: `images/macos/scripts/build/configure-preimagedata.sh` executes
  `echo "export ImageOS=$IMAGE_OS" >> $HOME/.bashrc` — a **shell-scoped** export
  appended to an interactive shell's startup file, not a process-wide one.

Whether `process.env.ImageOS` is therefore non-empty inside the action's Node
process on `macos-latest` depends on how the runner process itself was started,
which no primary source read here establishes. Because `config.ts` folds an
environment variable into the key only when its value is truthy (assertion A3.3),
an empty `ImageOS` would contribute **nothing, silently** — the remedy would
appear to be configured and would not be in force. **Acceptance criterion A7 is
therefore mandatory rather than cosmetic**, and P03 must add
`- run: echo "ImageOS=$ImageOS"` on both runners and assert the value is
non-empty before relying on the remedy. If it is empty on macOS, the fallback is
an explicit key segment carrying the same value from the workflow expression
context rather than from the process environment. Both readings are of the
default branch of `actions/runner-images` and are the one place in the evidence
script where upstream can drift; that is stated in `## Empirical check`.

**BASELINE-REVIEW finding, carried from `raw/opus.md` with this item's
disposition.**

BASELINE-REVIEW: F036 — dependency caching is a capability plus a key-correctness policy (the save key strictly finer than the restore key), and whether it is packaged inside the toolchain-setup step is a separable delivery choice, not part of the principle — replace F036's evidence note "py/ts each get caching free from their language-setup action, Rust has no single canonical equivalent" with "py/ts get caching from their language-setup action; in Rust the caching engine (`Swatinem/rust-cache`) and the toolchain-setup step are separately selectable, and `actions-rust-lang/setup-rust-toolchain` packages the same engine into the setup step, so the setup-integrated shape *is* available but is a packaging choice belonging to the toolchain-install decision (R42), not to this one; what the mechanism must agree on is the key — save key carries the lockfile digest, restore key omits it"; verdict `COMMON → SUBSTITUTE` and the F036 → R10 assignment are unchanged — evidence: `actions-rust-lang/setup-rust-toolchain` `action.yml` line 263 at commit `ecabd13d1c56bd1345c230e542e9144811ad706f` reads `uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2`, its `cache` input defaults to `"true"`, and its README line 57 documents `cache` as "Automatically configure Rust cache (using [`Swatinem/rust-cache`])" (both retrieved 2026-09-17); `dtolnay/rust-toolchain`'s README documents no cache, only a `cachekey` output (lines 68–69, retrieved 2026-09-17), which is the narrower claim F036's note generalised from; the two-key split is read from `src/config.ts:66–240` at the same pin.

**R10's position: adopted as an evidence-note amendment, and routed to the
controller; nothing is changed here.** The load-bearing half of the finding was
re-executed in this run and holds: the delegate line and the `cache: "true"`
default are assertions A6.1 and A6.2, and the two-key split is assertions
A3.1–A3.8. The verdict `COMMON → SUBSTITUTE` and the `F036 → R10` assignment are
unchanged, so this is a note correction and not a verdict change, which
`docs/port/README.md:77` reserves for `OVERRIDE`. Two limits on the adoption are
recorded rather than glossed: the README line-57 quotation was **not**
re-executed here (only `action.yml` was), and the finding's practical
consequence is not a change to this recommendation — it is the observation that
the setup-integrated shape *exists* in Rust, which makes runner-up E a live
option for R42 rather than a hypothetical. The ledger edit itself is the
controller's to make.

**F035 is deliberately not challenged.** Its row already carries the 2026-09-04
restatement. This item's findings confirm it, so no `BASELINE-REVIEW:` line is
raised against F035.

**Migration implications — obligations on a tree that does not exist yet.**

1. `.github/workflows/ci.yml` (created by R11): the step quoted at the top of
   this decision, in every job that runs `cargo`, between the toolchain-install
   step and the first `cargo` or tool-install step. Ordering is a correctness
   requirement in both directions — **after** the toolchain step because the key
   reads every installed toolchain's `rustc -vV`, so a cache taken before the
   toolchain exists is keyed to the runner's preinstalled Rust; **before** the
   tool-install steps R42 implies, so binstalled tools land in `$CARGO_HOME/bin`
   after the action's pre-existing-file snapshot and are cached rather than
   pruned.
2. `.github/workflows/ci.yml`, same jobs: `- run: echo "ImageOS=$ImageOS"` on
   both runners, so acceptance criterion A7 is observable in the job log.
3. `.github/dependabot.yml` (R19's file): the existing `github-actions` ecosystem
   entry must cover `/.github/workflows`, which is how the SHA pin and its
   `# v2.9.2` comment stay current. No new ecosystem entry.
4. `docs/` (R81's surface): one short note to a forker — `prefix-key` is the
   manual cache-invalidation lever, and `env-vars: "ImageOS"` must not be
   removed.
5. **Nothing** in `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, the
   `Justfile` or `lefthook.yml`. No crate, no dev-dependency, no tool-table
   entry, no recipe.
6. `docs/port/COMMONALITY.md`: F036's evidence note, per the `BASELINE-REVIEW:`
   line above — **proposed only**; this decision edits no ledger row.

re-verify: on any of — (1) the pinned reference `Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2` ceasing to be the current release, i.e. a Dependabot pull request moving the SHA, at which point `src/config.ts` is re-read at the new commit; (2) the first `Swatinem/rust-cache` v3 release, which voids the `< 3` ceiling and every claim read from `src/config.ts`; (3) the `#341` remedy landing upstream — a `Swatinem/rust-cache` CHANGELOG entry or release note adding the runner image to the key — at which point `env-vars: "ImageOS"` becomes redundant and should be removed; (4) GitHub repointing `macos-latest` to a new image generation, which is when acceptance criterion A7 and the `ImageOS` remedy are first genuinely tested; (5) R42 being revised to name a CI toolchain-install action, which decides runner-up E and, if it names `actions-rust-lang/setup-rust-toolchain`, requires closing the missing `env-vars` passthrough recorded under `## Engines`; (6) R11 resolving with a job count materially above six per OS, or P03's criterion-A5 measurement approaching 10 GB, either of which re-opens `save-if`; and in any case (7) 2027-03-17, six months from this decision.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

This item's `## Couplings` block names no owned and no consumed parameter
(`inputs/prompt.md`: `owns:` and `consumes:` are both empty), so there is no
`- owns` line and no consumed-parameter line. **No `CONFLICT:` line is emitted**
by either raw report or by this decision: no parameter needs a different value
for this recommendation to hold. All four lines above were compared
byte-for-byte against `docs/port/PARAMETERS.md` rows 7–10 and against this run's
`inputs/PARAMETERS.md` (`## Empirical check`, assertion group A10).

How each bears on the decision, stated here rather than on the lines above:

- **`msrv-policy`** is **load-bearing**. Testing the floor in CI means a second
  toolchain in a second job, whose `rustc -vV` differs, so the derived key
  partitions it automatically into its own cache entry. That is correct
  behaviour — a floor-toolchain `target/` must never be restored into a stable
  build — and it is also a budget input, because it doubles that job's share.
- **`target-os-matrix`** is **load-bearing**: it is the whole of the MEDIUM
  question, and `env-vars: "ImageOS"` exists because of its macOS half.
- **`rust-edition`** is not load-bearing; the cache mechanism is
  edition-independent.
- **`license`** is not evaluated against any candidate. Fitness gate 1 is
  `inapplicable — owner ruling 2026-09-12 (Q7.B)`; this parameter governs the
  repository's own declared licence, not what its CI may use.

Two items are related but are **not** registry dependencies of R10 and are
therefore deliberately absent from the list above. **R42** (`dev-toolchain-provisioning`,
owns `package-manager-invocation`) supplies the toolchain-install step this cache
step sits beside; its recipe body is what makes the `cache-bin` default pay, and
its install-integrity posture is what caching `$CARGO_HOME/bin` replays. **R11**
(`ci-workflow-job-structure`, owns `ci-job-structure`) fixes the job topology;
the *choice* of action is independent of it, while two configuration details are
handed to it — the entry count against the storage budget is two times the number
of job ids, and a build-graph-changing matrix leg needs one extra `key` segment.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4 on `arm64`;
`gh version 2.98.0 (2026-08-20)`; counting binary `/usr/bin/grep`, which reports
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`. Every count in both logs names
that binary on its own result line.

**Working directory.** `/Users/stevemorin/c/rs-launch-blueprint-p02-plan` — the
repository root. Both scripts resolve the repository root from their own location
and change into it, so either may be invoked by absolute path from anywhere.

**What was and was not done.** These scripts **verify**; they build nothing.
No template, workflow, scaffold, seam, fixture or cache was created, no Cargo
project was compiled, and **no CI run was executed or is possible from this
machine** — there is no repository under GitHub Actions and no runner. Everything
the recommendation asserts about runtime cache behaviour is therefore recorded as
planned under `## Engines`, not as observed. No `gh` token value was printed,
echoed or written; `gh` reads its own credential. No personal email address
appears in any script, log or snapshot.

**Commands executed, from the repository root:**

```
research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/evidence/r10-pinned-sources.sh \
  > research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/evidence/r10-pinned-sources.log 2>&1
research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/evidence/r10-live-figures.sh \
  > research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/evidence/r10-live-figures.log 2>&1
shellcheck research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/evidence/r10-pinned-sources.sh
shellcheck research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/evidence/r10-live-figures.sh
```

**Observed results.**

| Script | Log | Exit | Outcome |
|---|---|---|---|
| `r10-pinned-sources.sh` | `review/evidence/r10-pinned-sources.log` | **0** | `checks: 60 passed, 0 failed, 0 skipped` / `VERDICT: PASS` |
| `r10-live-figures.sh` | `review/evidence/r10-live-figures.log` | **0** | figures only; reports no verdict, and says so |
| `shellcheck` on both | — | **0** | no findings |

Both scripts begin with `set -o pipefail`, so a failure anywhere in a pipeline is
not masked by the last command's success. Neither script derives any count from
`head`- or `cut`-truncated output; every count is `/usr/bin/grep -c -E` over a
whole file, and the block-scoped counts in section A7 are taken over a file
extracted for that purpose rather than over a truncated stream.

**Every check asserts on content, and the assertions are shown to be able to
fail.** `r10-pinned-sources.sh` compares an expected *value* or an expected
*match count* against what the source actually contains, and prints
`PASS`/`FAIL` per assertion with both numbers; exit status alone is never the
verdict. Section **A13** is four negative controls that repeat an earlier
assertion with exactly one input perturbed and require the perturbed form to
mismatch — the commit SHA with one character appended (A13.1), `restore-keys`
expected present in a recipe that omits it (A13.2), the `env-vars:` pattern
found in `rust-cache` (1) and absent from `setup-rust-toolchain` (0) with the
same expression (A13.3), and the action-name pattern that returns 0 in R42
returning 3 in R20 (A13.4). All four fired.

**What the 60 assertions cover**, by section: A1 the tag-to-commit resolution;
A2 the `action.yml` contract and its input defaults at the pin; A3 the key
derivation read from `src/config.ts` at the pin; A4 the CHANGELOG, including the
**case-insensitive negative** assertion A4.5 that no entry records an
image-keying or #341 fix, paired with A4.6 counting the two macOS entries that
do exist so the negative is bounded; A5 the licence figure; A6 the `setup-rust-toolchain` delegate line, its
`cache` default and its **absent** `env-vars` passthrough; A7 GitHub's published
Rust recipe, quoted verbatim, with `restore-keys` counted at zero; A8 the two
`ImageOS` export paths; A9 this repository — the published R42 `DECISION.md`
hashing to `a2504aa7e3ad210e788e41ef53fbf37505a5254f54fd31955f9d1d2b574f5e1c`,
exactly the value `inputs/prerequisites.json` binds this run to, R42 naming no CI
toolchain action, R20's pin rule, the owner ruling and the two ledger rows; A10
the four fixed parameter rows, run inputs against the live registry; A11 both raw
reports hashing to their own filenames; A12 the py and ts source precedent at the
programme pins; A13 the negative controls.

**Reproducibility, stated as a checkable relation rather than as a claim.**
`r10-pinned-sources.sh` was re-run into a scratch file immediately after the
committed log was written, and `diff` reported **no difference**: the committed
log is the byte-for-byte output of the committed script as of 2026-09-17 UTC. It
is designed to stay that way — every remote read in it is pinned to a commit SHA
or an immutable tag object, and every local read is of a file tracked here. Three
drift surfaces are named rather than assumed away: the six lines of section A0
report this host's `rustc`, `cargo`, OS, `gh` and `/usr/bin/grep` versions and
the resolved repository root, all of which differ in another checkout,
extraction directory or host; section A8 reads two `actions/runner-images` paths on that
repository's default branch, which are the only unpinned remote reads in the
script and could be renamed upstream; and the `gh` credential must be present, or
the A1–A8 reads fail loudly rather than silently. `r10-live-figures.log` is
explicitly **not** byte-reproducible — every value in it is a live counter — and
the script says so at the top; each figure is also written to
`review/evidence/figures/*.json` carrying its endpoint and retrieval date, and
those snapshots, not the log, are what the decision cites.

**Checks requiring `.git`.** Section A12 reads the py and ts workflows at the
programme pins through local clones. It prints `SKIP <name>` and is excluded
from the failure count when `$HOME/c/py-launch-blueprint/.git` or
`$HOME/c/ts-launch-blueprint/.git` is absent, or when the pin is not present in
the clone, so the script runs to completion from a clean `git archive HEAD`
extraction. On this host both clones were present and both assertions ran and
passed, which is why the committed log shows `0 skipped`. No other check needs
`.git`.

**Live figures observed** (`r10-live-figures.log`, snapshots under
`review/evidence/figures/`, all retrieved 2026-09-17 UTC):

| Repository | Stars | Archived | `pushed_at` | Licence (figure only) | Open issues | Latest release |
|---|---|---|---|---|---|---|
| `Swatinem/rust-cache` | 1917 | false | 2026-09-07T21:44:07Z | LGPL-3.0 | 69 | v2.9.2, 2026-08-06T06:26:27Z |
| `actions/cache` | 5550 | false | 2026-07-15T18:13:46Z | MIT | 163 | v6.1.0, 2026-06-26T19:17:06Z |
| `actions-rust-lang/setup-rust-toolchain` | 403 | false | 2026-09-07T22:03:58Z | MIT | 3 | v2.0.0, 2026-09-07T21:53:31Z |
| `mozilla-actions/sccache-action` | 206 | false | 2026-09-10T22:20:34Z | Apache-2.0 | 16 | v0.0.11, 2026-07-29T11:19:11Z |
| `moonrepo/setup-rust` | 133 | false | 2026-03-19T17:30:54Z | null | — | — |

Stars, `archived`, `pushed_at` and the licence come from
`GET https://api.github.com/repos/<o>/<r>`; open issues from
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
`.total_count` — never `open_issues_count`; releases from
`GET https://api.github.com/repos/<o>/<r>/releases/latest`.

**Crate figures.** Only `sccache` is a crates.io package
(`GET https://crates.io/api/v1/crates/sccache` and `/versions`, retrieved
2026-09-17): `crate.recent_downloads` **129 817**, `crate.downloads`
**1 335 826**, newest unyanked `num` **0.18.0** created
**2026-09-16T14:34:17.177895Z**, `license` Apache-2.0, `rust_version` **1.91.0**
— inside the 1.96 floor implied by `msrv-policy` against current stable, and in
any case a standalone runner binary rather than a template dependency. For
`Swatinem/rust-cache`, `actions/cache`, `actions-rust-lang/setup-rust-toolchain`
and `mozilla-actions/sccache-action`, `crate.recent_downloads` and
`crate.downloads` are **`inapplicable` — they are GitHub Actions and have no
crates.io package**, so no such field exists to read.

**Issue responsiveness**, `Swatinem/rust-cache`, from the ten most recently
*opened* issues with pull requests excluded (#381, #375, #374, #370, #369, #352,
#348, #344, #341, #337;
`GET https://api.github.com/repos/Swatinem/rust-cache/issues?state=all&sort=created&direction=desc&per_page=100`
plus each `/issues/<n>/comments`, retrieved 2026-09-17): the maintainer replied
on **3 of 10** — #375 at 0.025 d, #337 at 0.115 d, #370 at 1.171 d — leaving
**7 unanswered**. Median among the answered: **0.115 d**. The median over all
ten is **undefined**, because more than half are unanswered; it is reported as
undefined rather than imputed.

**Maintenance state: `active`**, by the prompt's rubric. A release six weeks
before retrieval (v2.9.2, 2026-08-06), a push within five weeks
(2026-09-07T21:44:07Z), not archived, and no `at-risk` signal — no unpatched
advisory, no broken build observed, no maintainer notice. The concrete risk that
*is* present, and that the rubric does not call `at-risk`, is a **bus factor of
one**, consistent with the 7-of-10 unanswered figure; it is the first re-verify
trigger's subject matter and is recorded, not smoothed over.

**RustSec.** `https://rustsec.org/packages/rust-cache.html` returns **HTTP 404**
and `https://rustsec.org/packages/sccache.html` returns **HTTP 404** (retrieved
2026-09-17). The positive control run in the same pass is
`https://rustsec.org/packages/atty.html` → **HTTP 200**, a crate with a known
advisory, which is what makes a 404 an absence of advisory rather than a broken
lookup; `serde` → **404** is the negative control. For `rust-cache` the correct
reading is stronger than "no advisory": it has no crates.io package at all, so
**fitness gate 3 is `inapplicable` to it, not passed by it**, and the `unsafe`
posture is likewise `inapplicable` — the action contains no Rust code. The
supply-chain question that *does* apply is that third-party JavaScript executes
in the CI job, and R20's SHA pin is the control for it.

**Fitness gates, recorded per the prompt and never omitted silently.** Gate 1
licence: `inapplicable — owner ruling 2026-09-12 (Q7.B)`, figure recorded above.
Gate 2 MSRV: `inapplicable` — a Node action (`using: "node24"`, assertion A2.1)
contributes no `rust-version` and no transitive Rust dependency; it imposes a
*runner* requirement instead, a runner providing Node 24, satisfied by both fixed
GitHub-hosted runners and a coupling for R09 if a self-hosted runner is ever
substituted. Gate 3 advisories and `unsafe`: `inapplicable`, as just stated.
Gate 4 platforms: **passes** — this is the only gate with force here, and the
action's own CI runs its scenario workflows on `ubuntu-latest`, `macos-latest`
and `windows-latest` (carried from `raw/opus.md`, which read the matrix blocks at
the pin; Windows is covered and not required). Gate 5 default features and
async-runtime coupling: `inapplicable` — a GitHub Action has no Cargo features
and links no runtime into the template; the nearest true statement is its input
defaults, tabulated above. Gate 6 binary size and compile time: `inapplicable` —
nothing is compiled into the template's binary; the real cost is two extra steps
per job, one `cargo metadata` invocation, and one cache entry per job per OS
against the storage budget. **Excluded by gate: none.** That is a direct
consequence of the owner ruling plus the item's shape, and it is a finding rather
than an oversight.

## Engines

Two engines, no Doxa — `research/EXECUTION.json` sets the Focused tier to Codex
plus Opus for this item, and both returned.

- **codex** `raw/codex.md` — actor `research-codex-2026-09-17T020715Z-b3b67fdb5328`,
  model `gpt-5.6-terra` via `codex-cli-0.153.2` (family openai), sha256
  `74afacbc4e5c12376873cfd37eee46255bc5519486756c2278453a5c1f5e007e`; 15 H3
  fields, no `CONFLICT:` line, no `BASELINE-REVIEW:` line. Recommends
  `actions/cache@v6` with a hand-written key, having excluded
  `Swatinem/rust-cache` by the licence gate.
- **opus** `raw/opus.md` — actor `research-opus-2026-09-17T020715Z-b3b67fdb5328`,
  model `claude-opus-5` via `claude-agent-tool`, sha256
  `49b673aef41e0729b6dace3fae827240d64a4bbd2ee88b3a0b1e8cbde283d50d`; 15 H3
  fields, no `CONFLICT:` line, one `BASELINE-REVIEW: F036` line against the
  evidence note only. Recommends
  `Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2`, range
  `>= 2.9.1, < 3`, with `env-vars: "ImageOS"`, `cache-on-failure: "true"` and
  `prefix-key: "v1-rslbp"`.

Both raw files' content hashes were re-computed here and match their filenames
(assertion group A11).

**Disagreements, and the evidence that settled each.**

**1. The licence gate — and it is the only disagreement that changes the
answer.** Codex excluded `Swatinem/rust-cache` *before* weighing popularity, on
fitness gate 1: its bundled `LICENSE` is LGPL-3.0, which is not compatible with
`license = MIT OR Apache-2.0`. Opus recorded LGPL-3.0 as a figure and evaluated
nothing against it. **Settled for Opus, on a standing owner ruling rather than on
judgement.** `docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check for
anything the template uses (Q4, superseded and widened by Q7.B)", strikes fitness
gate 1 from every item's evaluation; decisions record it as `inapplicable` with
the ruling named rather than deleting the row (assertion A9.5). Codex's report
predates nothing — the ruling is eleven days older than this run — so the
exclusion is simply void, not wrong-at-the-time. **Two consequences are worth
stating.** First, the licence figure itself is confirmed, not disputed: both
engines read LGPL-3.0, and this run re-read the bundled `LICENSE` at the pin
(assertion A5.1). Second, and more usefully, **the engines converge once the
ruling is applied**: Codex's own `### Ranked runner-up` says
`Swatinem/rust-cache@v2` "would win only if the owner changes the candidate-licence
gate to permit LGPL-3.0 GitHub Action code", and its
`### Tradeoffs` concedes the specialist's "maintained Cargo-aware keying,
cleanup, and workspace controls". That condition is met. Read that way, both
engines recommend the same action, and the second disagreement below is about how
much is lost when it is unavailable.

**2. Derived key versus hand-written key.** Opus rejected the whole
`actions/cache` alternative as failing P1 and P3. That is accurate against
**GitHub's published Rust recipe** — verified verbatim here (assertions
A7.1–A7.3) — but it is not a fair description of **Codex's** key, and the
distinction is recorded rather than flattened. Codex proposed
`cargo-${{ runner.os }}-${{ steps.rustc.outputs.cache-key }}-${{ hashFiles('**/Cargo.lock', '**/Cargo.toml', '**/.cargo/config.toml') }}`
with the restore prefix `cargo-${{ runner.os }}-${{ steps.rustc.outputs.cache-key }}-`,
which is a genuine two-key split carrying the compiler identity — it satisfies P1
and P2. **Settled on the grounds Codex's key does not answer**, which are three:
it has no `target/` pruning at all, so P3 is unaddressed; it has no per-job or
per-feature `target/` separation, which the feature-gated web surface (R69) and
the MSRV floor job both need; and it must be re-derived by hand on every fork
edit, in a repository whose entire purpose is to be forked and modified. The
recommended action provides all three by construction. **What both engines agree
on is recorded as agreement**: the key must carry compiler identity and runner
identity, and the save key must be strictly finer than the restore key. That
agreement is the F036 principle, and it is what makes GitHub's published recipe
the alternative both engines reject.

**3. Save on failure.** Codex made "a failed job does not save a new cache" an
acceptance criterion, resting on `actions/cache`'s `post-if: success()` default
and offering no argument for it. Opus set `cache-on-failure: "true"`, arguing
that P2 is enforced by the key rather than by the save condition. **Settled for
Opus.** The ground is that Codex's criterion protects against a risk the key
already excludes: a partially-built `target/` saved after a failure is keyed to
the exact lockfile and compiler that produced it, and Cargo's fingerprints
revalidate every unit on restore, so what is saved cannot be served to a
different dependency set. Against that, the cost of the default is concrete and
recurring — a template's most common CI loop is *a test failed, push a fix*, and
under the default every iteration re-downloads and re-compiles the whole
dependency graph. Corroboration rather than proof: `actions-rust-lang/setup-rust-toolchain`
overrides the same input to `"true"` for its own users. **This is listed under
"what P03 must validate" below**, because the argument is a reading of the key
derivation and not an observation of a saved cache being restored after a
failure.

**4. The setup-integrated shape.** Codex reported Rust as having no
setup-integrated caching action, following the prompt's own `## Context`. Opus
falsified that and named `actions-rust-lang/setup-rust-toolchain`. **Settled for
Opus, and re-executed here**: its `action.yml` at commit `ecabd13d…` delegates to
`Swatinem/rust-cache` at the identical commit this decision pins, and its `cache`
input defaults to `"true"` (assertions A6.1, A6.2). The prompt's narrower claim —
that `dtolnay/rust-toolchain` does not cache — stands. This is the substance of
the `BASELINE-REVIEW: F036` line and of runner-up E.

**5. Figures.** Every figure the two engines report in common was re-queried here
and agreed to the digit: 1917 stars, 69 open issues, v2.9.2 at
2026-08-06T06:26:27Z, LGPL-3.0, 3-of-10 maintainer replies with 7 unanswered,
`actions/cache` at 5550 stars and 163 open issues, `moonrepo/setup-rust` with a
`null` licence. Codex reported the responsiveness median as 2.75 hours and Opus
as 0.11 d; those are the same number for the same issue (#337), and this run
measures 0.115 d. **No figure disagreement survives.**

**Unproven — what P03 must validate, and what would settle each.**

Nothing was built and no CI was run, so every row below is a claim this research
could not close from a workstation.

| # | Claim | What would settle it |
|---|---|---|
| U1 | A warm cache is actually reused: an unchanged tree's second run reports `cache-hit == 'true'` and recompiles no dependency unit | Acceptance criterion A1, run twice on each fixed OS, with `cargo build --timings` or fingerprint logging on the second run |
| U2 | A lockfile change misses exactly and restores approximately: `cache-hit == 'false'`, yet only the changed dependency and its dependents recompile | Criterion A2. This is the one check that distinguishes the recommendation from GitHub's published `actions/cache` recipe |
| U3 | A toolchain change partitions the cache, including the MSRV floor job beside stable | Criterion A3 |
| U4 | The two fixed runners never share an entry | Criterion A4, read from `gh api repos/<o>/<r>/actions/caches` |
| U5 | **`$ImageOS` is non-empty in the action's process on `macos-latest`.** The Ubuntu export is process-wide (`/etc/environment`); the macOS export is shell-scoped (`$HOME/.bashrc`) — both read here, assertions A8.1 and A8.2 — and an empty value contributes nothing to the key *silently* | Criterion A7: `- run: echo "ImageOS=$ImageOS"` on both runners, asserted non-empty. **This is the highest-value unproven row**, because the remedy appears configured either way |
| U6 | The `ImageOS` remedy actually prevents the `#341` failure | Only observable when GitHub next repoints `macos-latest` to a new image generation. Not simulable in CI and not simulable here |
| U7 | `cache-bin: "true"` is net-positive under R42 — a cached `$CARGO_HOME/bin` serves no stale tool | Criterion: install a tool, warm the cache, bump its pinned version, re-run, and observe `cargo binstall` installing the new version. Opus predicts this from `cargo-binstall`'s `resolve.rs`; that source reading was **not** re-executed here |
| U8 | `cache-on-failure: "true"` is safe — disagreement 3 above rests on a reading of the key derivation, not on an observation | Fail a job deliberately, confirm an entry is saved, then confirm the next run with a changed lockfile does not receive it as an exact hit |
| U9 | The footprint stays inside the 10 GB budget and pruning holds across runs with dependency churn | Criterion A5, from `gh api repos/<o>/<r>/actions/cache/usage`, repeated over roughly ten runs |
| U10 | The runner-up-E substitute `cache-key: ${{ env.ImageOS }}`, needed because `setup-rust-toolchain` exposes no `env-vars` passthrough (assertion A6.3) | Only if R42 is revised to select that action; reasoned by Opus, never tested |
| U11 | No build-time or cache-restore-time figure is asserted anywhere in this decision | Nothing to settle — this row exists so that the absence is explicit. Any speedup number would have been invented |
| U12 | Adoption counts for `astral-sh/uv`, `clap-rs/clap`, `tokio-rs/tokio`, `astral-sh/ruff`, `helix-editor/helix` and `starship/starship` | Carried from `raw/opus.md` and **not re-executed here**; they rest on `GET https://api.github.com/search/code`, which rate-limited that report itself. `helix-editor/helix` and `starship/starship` rest on a search count alone with no workflow line quoted, and are weaker evidence than the three whose exact lines Opus quotes |
| U13 | The `setup-rust-toolchain` README line-57 quotation inside the `BASELINE-REVIEW: F036` line | Only `action.yml` was re-executed here (assertions A6.1–A6.3). The README quotation is carried from `raw/opus.md` |
| U14 | The action's own scenario workflows run on all three OSes — the evidence behind fitness gate 4 | Carried from `raw/opus.md`, which read the matrix blocks at the pin; not re-executed here |

**Confidence.** **High** on the mechanism: it is over-determined, because every
serious alternative path arrives at the same engine, and the key strategy was
read from the implementation at the pinned commit rather than from documentation.
**High** on the key-strategy answer to the HIGH question, for the same reason,
and because the contrast with GitHub's published recipe is verbatim. **Medium**
on the `env-vars: "ImageOS"` remedy: the *defect* is high-confidence — reproduced
by three parties in issue #341, explained by the key derivation, and unfixed in
the CHANGELOG at the pin — but the *fix* is reasoned from source and from the
image-build scripts, is not observed working, and this synthesis has narrowed the
uncertainty to a specific question (U5) rather than removed it. **Medium** on the
`save-if` guidance, which depends on a footprint measurement that cannot be made
before the template exists and before R11 fixes the job count.
**Low-to-medium** on `cache-bin: "true"` being net-positive: the no-stale-tool
half is a source reading not re-executed here (U7), and the desirability half
trades a live macOS defect and a weaker install-integrity replay against saved
download time — a judgement P03's measurements should re-open.

**The honest statement of what this recommendation accepts**, in one sentence:
a third-party JavaScript action with a **bus factor of one** and a **live,
unfixed macOS defect** (#341), bounded by R20's SHA pin and by one configuration
input whose effect on `macos-latest` is itself unproven (U5), in exchange for CI
time that has not been measured and cannot be measured until P03 exists.
