# R50 — install-smoke-test (bundle, Focused) — raw report

Engine: Opus (`research-opus-2026-09-17T020715Z-b7ef95f12806`, model `claude-opus-5`).
All endpoint retrievals in this report were made on **2026-09-17 (UTC)**, between
`04:37:18Z` and `04:42:12Z`; each figure names its endpoint beside it.
**Nothing was built, installed, packaged or written** outside this one file: no Rust
template exists yet (P03 builds it), so every recipe and workflow fragment below is a
**proposed** check, explicitly distinguished from the checks this run actually executed.

### Landscape

**The category this item decides.** Not a library choice. It is a *verification
procedure plus its cadence*: (a) which artifact is put under test, (b) by what
mechanism it is installed into a throwaway location, (c) what is asserted about the
resulting command, and (d) whether that procedure gates every code-touching pull
request or stays a developer-invoked recipe. The binary under test is `rslbp`
(R49, `docs/port/PARAMETERS.md` `build-tool-output-shape`); the package is
`rs-launch-blueprint`.

**Three-bin map of the Rust field.**

| Bin | Candidates found | What each actually answers |
|---|---|---|
| **Built-in / first-party toolchain** | `cargo package` (produces `target/package/<pkg>-<ver>.crate` and, unless `--no-verify`, compiles the extracted copy); `cargo install` with `--path`, `--root`, `--locked`, `--debug`, `--profile`, `--target-dir`, `--no-track`, `--bin`, `--features`; `cargo publish --dry-run`; `cargo run --locked`; `cargo metadata` | the whole question. Rust has no third-party layer between "source" and "installed command" — `cargo install` **is** the ecosystem's install verb |
| **Established industry standard (third-party, widely adopted)** | `cargo-binstall` 1.23.0 (installs a **prebuilt** binary from a GitHub release); `cross` (cross-compilation); `cargo-local-registry` 0.2.12 (builds a directory registry for `[source]` replacement) | `cargo-binstall` answers "does the *released* binary install", which is **R68**'s row, not F221/F222. `cargo-local-registry` answers this item's question most faithfully but at the cost of a registry fixture (see *Excluded / rejected* in Member 1) |
| **Up-and-comer** | `dist` (axodotdev, formerly `cargo-dist`) — release-artifact orchestration | R68's territory. The crates.io name `dist` is **not** that tool: `GET https://crates.io/api/v1/crates/dist` returns `max_stable_version` `0.0.0`, `downloads` 3154, newest un-yanked version `0.0.0` created `2016-08-04T21:30:39Z`, `repository: null` (retrieved 2026-09-17) — a 2016 placeholder. Any candidate list that names `dist` by crate name is naming the wrong crate |

Every shortlisted candidate in Member 1 comes from bin 1 or bin 2 of this map.

**Authoritative sources used, and why each counts.**

| Source | Why authoritative | Used for |
|---|---|---|
| `https://doc.rust-lang.org/cargo/commands/cargo-install.html` (retrieved 2026-09-17) | The Cargo Book is the Cargo team's own normative reference for the command's contract | the lockfile rule, the temporary-target-directory default, the installation-root precedence, `--debug`, `--target-dir` |
| `rust-lang/cargo` source at tag `rust-1.98.0`, read through `GET https://api.github.com/repos/rust-lang/cargo/contents/<path>?ref=rust-1.98.0` (retrieved 2026-09-17) | The implementation itself; settles behaviour the prose does not state. R49 set the precedent of reading this repository at this tag | `cargo package`'s ephemeral-workspace verification, which is the fact the recommended recipe is built around |
| Locally installed `cargo 1.98.0 (797e8a9bc 2026-08-05)` / `rustc 1.98.0 (88d9e12ae 2026-08-18)` (Homebrew), `cargo install --help` executed 2026-09-17 | Primary artifact: the flag surface as shipped, not as documented | confirming every flag the proposed recipe uses exists on a current toolchain |
| `https://static.rust-lang.org/dist/channel-rust-stable.toml` (retrieved 2026-09-17) | The release channel manifest served by the Rust project | current stable is `1.98.1 (48a229cea 2026-09-01)`, which fixes the `msrv-policy` floor at **1.96.0** |
| `https://crates.io/api/v1/crates/<name>` and `/versions` (retrieved 2026-09-17) | The registry's own API — the figure source this programme's spec §7.6 mandates | all download/release figures |
| `https://api.github.com/repos/<o>/<r>` and `https://api.github.com/search/issues` (retrieved 2026-09-17, authenticated `gh api`) | GitHub's own API | stars, archived, `pushed_at`, open-issue counts, issue responsiveness |
| `https://rustsec.org/packages/<name>.html` (retrieved 2026-09-17) | The Rust Secure Code WG's advisory database rendering | advisory checks, with the 404/200 semantics established by a control probe (below) |
| The two source repositories read **at the programme pins**: `git -C ~/c/py-launch-blueprint show b08bccfb…:<path>` and `git -C ~/c/ts-launch-blueprint show cb1cbcb2…:<path>` (read 2026-09-17) | The evidence base the ledger cites; the working trees are ahead of the pins | py's `build-smoke` job and ts's `pack-check` recipe, including the ledger correction below |

A note on one probe's semantics, because a bare 404 proves nothing on its own:
`https://rustsec.org/packages/just.html` and `.../cargo-binstall.html` both returned
HTTP 404, while the control `https://rustsec.org/packages/time.html` — a crate with a
known advisory (`RUSTSEC-2020-0071`) — returned HTTP 200 (all retrieved 2026-09-17).
The site publishes a package page only where advisories exist, so 404 is the
no-advisory answer, not a broken URL.

**Practice evidence — what mainstream, well-regarded Rust projects actually do.**
Selection rule: cross-platform Rust CLIs and packaging-critical Rust projects, weighted
toward recently active ones, with the "well regarded" claim carried by a figure rather
than asserted. All figures from `GET https://api.github.com/repos/<o>/<r>` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, retrieved
2026-09-17; workflow bodies from `GET https://api.github.com/repos/<o>/<r>/contents/<path>`,
same date.

| Project | Evidence it is well regarded | What its CI does about install/packaging |
|---|---|---|
| `astral-sh/uv` | 89 890 stars, `archived: false`, `pushed_at` `2026-09-17T02:33:02Z`, 2 360 open issues; **the authors of `uvx`**, the very tool F222 records py using | **`cargo publish --workspace --dry-run`** as a pull-request gate. `.github/workflows/check-publish.yml` runs it on `depot-ubuntu-24.04-8` with `timeout-minutes: 20`, `permissions: contents: read`, `Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2` (`save-if: ${{ github.ref == 'refs/heads/main' }}`). `.github/workflows/ci.yml:58-61` wires it as `check-publish`, `needs: plan`, `if: ${{ needs.plan.outputs.test-code == 'true' }}` — i.e. **path-filtered, every code-touching PR**. Separately, `.github/workflows/test-smoke.yml` downloads the *built release binary* and runs it (`chmod +x ./uv`, `./uv run --no-project scripts/smoke-test`) |
| `sharkdp/bat` | 60 472 stars, `archived: false`, `pushed_at` `2026-09-04T19:10:30Z`, 330 open issues | **`cargo install --locked --path .`** run inside CI, three times across two jobs (`.github/workflows/CICD.yml:99`, `:103`, `:129`), each followed by running the installed command (`bat --list-languages`, `bat --list-themes`) on `ubuntu-latest` |
| `BurntSushi/ripgrep` | canonical Rust CLI; its `ci.yml` uses `cargo install` only to fetch `cargo-fuzz` (`:266`) | no install-smoke of its own artifact in `ci.yml` |
| `casey/just`, `sharkdp/fd`, `ajeetdsouza/zoxide` | the task runner this template already uses (F176) and two widely used Rust CLIs | grep of their CI files for `cargo install`, `cargo package`, `cargo publish`, `publish --dry-run`, `smoke` returned **no match** in `casey/just .github/workflows/ci.yaml`, `sharkdp/fd .github/workflows/CICD.yml` and `ajeetdsouza/zoxide .github/workflows/ci.yml` |
| `starship/starship` | `cargo install --version 0.3.9 cargo-wix` (`.github/workflows/workflow.yml:174`) — tooling, not self-install | — |
| `rust-lang/cargo` | the toolchain itself | `ci/fetch-smoke-test.sh` (`.github/workflows/main.yml:266-267`) — a network smoke test, unrelated to install |

**The honest gap in that evidence.** The specific composition this report recommends —
`cargo package`, then install **from the extracted `.crate`** — is not a visible
mainstream pattern. A GitHub code search for the literal
`"cargo install --path target/package"` (`GET https://api.github.com/search/code`,
retrieved 2026-09-17) returned `total_count: 7`, every hit a Markdown document or a
test fixture in a small repository, none in a project that meets the "well regarded"
bar used above. The field's two live patterns are uv's `cargo publish --dry-run` and
bat's `cargo install --locked --path .`. The recommendation below therefore rests on
documented first-party primitives plus a stated argument about what each pattern does
and does not exercise — not on an appeal to adoption — and the `## Confidence` field
prices that in.

**Fit over abstract best.** The use case is CLI + library + optional web service.
`cargo install` installs **binary** targets only ("Only packages which have executable
`[[bin]]` or `[[example]]` targets can be installed", cargo-install docs, retrieved
2026-09-17), so the CLI surface is directly testable and the library surface is
exercised only transitively; the optional web surface adds a *second* binary whose
`required-features` change what an install produces. Each of the three surfaces is
handled explicitly in Member 1 rather than being folded into a single "run the binary".

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

Ledger rows: **F221** (`docs/port/COMMONALITY.md:225`, `packaging-distribution`, origin
`different`, verdict `DIVERGENT`) — the *cadence* of a CI-wired build-and-install smoke
test. **F222** (`:226`, origin recorded as `py-only`) — the *mechanism*, an ephemeral
install-and-run of the just-built artifact.

Read at the pins, the two source repositories agree on more than the ledger records.

| # | Behavior that must agree | py at pin `b08bccfb` | ts at pin `cb1cbcb2` | Level | Rust realization |
|---|---|---|---|---|---|
| B1 | The artifact that ships is installed the way a consumer installs it, in a location that is not the developer's environment, and the resulting command is **executed** | `.github/workflows/ci.yml:220-223` — `uvx --from "$(ls dist/*.whl)" plbp --version` and `uvx --from "$(ls dist/*.tar.gz)" plbp --version`; `uvx` builds a throwaway environment per invocation | `Justfile:299-312` — `SCRATCH=$(mktemp -d /private/tmp/ts-pack-check.XXXXXX)`, `npm pack` into `$SCRATCH`, `npm install --no-save --no-package-lock "$SCRATCH/$TARBALL"`, then `"$SCRATCH/node_modules/.bin/<cmd>" --version` | **capability** — present in **both** repos | `cargo package` → extract → `cargo install --root <tmp>` → run `<tmp>/bin/rslbp --version` |
| B2 | The artifact under test is the **packaged** artifact, not the working tree | `uv build` (`ci.yml:216`) then install `dist/*.whl` and `dist/*.tar.gz` | `npm pack` output tarball (`Justfile:302`) | **architectural pattern** — present in both | the `.crate` from `cargo package`, extracted outside the repository |
| B3 | Failure is loud and blocks something | py: a required CI job | ts: a non-zero exit from the recipe, blocking the developer only | **policy** — **this is where they diverge (F221)** | to decide |
| B4 | The assertion made about the installed command | py: `--version` exits 0; output unchecked | ts: `--version` output compared for **equality** against `"<cmd> <version>"` (`Justfile:306-310`), **plus** a library-surface check — `node -e 'import("<pkg>").then(m => …VERSION…)'` (`:312`) | **policy** — differs in strength | to decide (see the MEDIUM question) |

BASELINE-REVIEW: F222 — principle: the artifact that reaches a consumer is installed as a consumer installs it and then executed (B1/B2 above) — proposed change: change F222's `origin` from `py-only` to `different`, give it a ts evidence cell, and correct the three places that say ts has no install-and-run step — evidence: ts's `pack-check` at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` is a six-step recipe whose steps 5 and 6 are exactly an install-and-run smoke test: `Justfile:299` `SCRATCH=$(mktemp -d /private/tmp/ts-pack-check.XXXXXX)`; `:300` `trap 'rm -rf "$SCRATCH"' EXIT`; `:301` `echo "[5/6] pack + install tarball into $SCRATCH"`; `:302` `TARBALL=$(npm pack --ignore-scripts --pack-destination "$SCRATCH" --json | …)`; `:304` `( cd "$SCRATCH" && npm install --no-save --no-package-lock "$SCRATCH/$TARBALL" )`; `:305` `echo "[6/6] smoke: installed bin --version + ESM lib import"`; `:306-310` run `"$SCRATCH/node_modules/.bin/{{command_name}}" --version` and fail unless it equals `"{{command_name}} $VERSION"`; `:312` import the installed package and assert `VERSION` is a string. The recipe's own header comment says so at `:268-269`: *"then pack + install into a /private/tmp scratch project and smoke-test the bin + ESM lib import"*, and `docs/port/areas/release-versioning.md:24` already describes `pack-check` as ending in an *"install smoke test"*. The three statements contradicted are: `docs/port/COMMONALITY.md:226` (`origin` `py-only`); `docs/port/areas/packaging-distribution.md:20` (ts cell `—`); and this item's own prompt, `## Context`, *"ts: none (py-only; ts's `pack-check` recipe covers packed-content assertion, not an install-and-run step)"* — the packed-content assertion is `pack-check` step 4 (`Justfile:288-298`), which is genuinely R26's F039/F078 subject, but steps 5–6 are a distinct install-and-run half that the row drops. **Affected items:** R50 (this item — the correction *strengthens* rather than weakens the case for adopting the pattern, and it moves ts's contribution from "absent" to "present, richer than py's"); R26 (`packed-artifact-content-guard`, informationally — its F039/F078 scope is unchanged, because step 4 remains the content half). **Not changed by this report:** no ledger row, index row, prompt or registry file was edited.

**What follows from the correction.** F222 is not a py-only invention that Rust may
or may not want; it is a capability **both** source repositories implement, in two
ecosystems with entirely different install machinery, which is the strongest available
evidence that the capability is the shared principle and the mechanism is the free
variable. The only genuine divergence left is **F221's policy question**: py blocks a
pull request with it, ts blocks only a developer who chooses to run it.

**Does the pattern remain appropriate in Rust? Yes for B1 and B2, with one
mechanism-level consequence.** In py and ts the packaged artifact is *pre-built* — a
wheel contains compiled-or-not modules, a tarball contains built JS — so "install" is
a cheap unpack-and-link and the smoke test's whole cost is the dependency resolution.
In Rust the `.crate` is a **source** archive: installing it means compiling it. That
single fact is what makes F221's cadence question real here and nearly free in py, and
it is the reason the cost analysis below is a first-class part of the answer rather
than a footnote.

**Architectural alternatives, compared before any tool is chosen.** All five operate on
the same binary (`rslbp`) and differ only in what they put under test.

| Option | Procedure | Exercises the packaged file set (R49's `include`)? | Exercises a consumer's install path? | Executes the command? | Verdict |
|---|---|---|---|---|---|
| **A** | `cargo run --locked -- --version` | no | no | yes, from the working tree | **Reject.** It is a build-and-run of the developer's tree. It cannot fail for any of the reasons F222 exists to catch (a file missing from `include`, a `[[bin]]` that does not produce a command, metadata that stops an install) |
| **B** | `cargo install --path . --root "$tmp" --locked` | **no** — `--path` builds the directory as it stands, so a source file absent from `include` is still present on disk | partly — the install verb and `--root` are real | yes | **Runner-up.** This is the ledger's own guess (`COMMONALITY.md:226`) and bat's live CI pattern (`CICD.yml:99`). Cheap and honest about the *install* half; blind to the *packaging* half, which is precisely the half py's `uv build` + `uvx --from dist/*.whl` covers |
| **C** | `cargo package` → extract the `.crate` into a temp dir **outside the repository** → `cargo install --path "$tmp/rs-launch-blueprint-<ver>" --root "$tmp/root"` → run `"$tmp/root/bin/rslbp" --version` | **yes** — the extracted tree is byte-for-byte what crates.io would serve | yes | yes | **Recommended.** The only option that puts the *packaged* artifact under the *install* verb, which is what py does with `uvx --from dist/*.whl` and ts with `npm install "$SCRATCH/$TARBALL"` |
| **D** | Build a local directory registry (`cargo-local-registry`) or a `[source]` replacement, then `cargo install rs-launch-blueprint --registry local` | yes | **most faithfully** — resolution goes through a registry, as a real consumer's does | yes | **Reject on cost.** It adds a third-party tool (`cargo-local-registry` 0.2.12; 6 159 90-day downloads, 161 stars — figures in Member 1), a registry fixture to maintain, and a checksum/index step, to close a gap that is one indirection wide: option C already installs the exact published bytes. Revisit only if a *registry-visible* metadata failure is ever observed |
| **E** | `cargo publish --dry-run --locked` | yes | no | **no** | **Reject as a substitute, adopt as a neighbour.** It packages and compiles but never runs the command, so it cannot answer "does the installed `rslbp` work". It is uv's live PR gate and it is **already R26's element 3**, bound to the publish workflow's verify job — so this item must not re-decide it |

**The fact option C is built around, and why C extracts outside the repository.**
`cargo package` writes the extracted copy to `<build-dir>/package/<name>-<version>` and
then compiles it in a *manufactured* workspace. From `rust-lang/cargo` at tag
`rust-1.98.0`, `src/cargo/ops/cargo_package/verify.rs` (retrieved 2026-09-17):

- `:48-53` — `let dst = ws.build_dir().as_path_unlocked().join(&format!("package/{}-{}", pkg.name(), pkg.version()));`
- `:60` — `archive.unpack(dst.parent().unwrap())?;`
- `:62-63` — the comment, verbatim: *"Manufacture an ephemeral workspace to ensure that even if the top-level package has a workspace we can still build our new crate."*
- `:69-72` — *"When packaging we use an ephemeral workspace but reuse the build cache to reduce verification time…"*, then `Workspace::ephemeral(new_pkg, gctx, Some(ws.build_dir()), true)?`
- `:94-…` — `ops::compile_with_exec(… UserIntent::Build …)` — it **builds**, it does not run

Two consequences, both load-bearing. First, Cargo's own maintainers found it necessary
to bypass workspace-root discovery to build an extracted package that sits **inside**
the workspace; the `cargo install` CLI performs no such bypass, so
`cargo install --path target/package/rs-launch-blueprint-<ver>` invites exactly the
workspace-membership problem `verify.rs` documents. Extracting to `$(mktemp -d)`
removes the question by construction rather than by hoping. (**Not executed** — no Rust
package exists in this repository to test the failing form against; the citation
establishes *why* Cargo avoids the in-tree path, not that the CLI form fails.)
Second, `cargo package`'s default verification is a **second full compile** of the same
tree the install is about to compile again, so `--no-verify` on the packaging step is a
cost lever that removes duplicated work rather than coverage.

**The lockfile axis, and why it maps onto two different lanes.** The cargo-install docs
(retrieved 2026-09-17) state: *"By default, the `Cargo.lock` file that is included with
the package will be ignored. This means that Cargo will recompute which versions of
dependencies to use, possibly using newer versions that have been released since the
package was published. The `--locked` flag can be used to force Cargo to use the
packaged `Cargo.lock` file if it is available."* So:

- **Unlocked** reproduces what `uvx --from dist/*.whl` actually does — resolve fresh
  against the index — and answers *"would a fresh install work **today**"*. It is also
  non-deterministic and network-coupled: a dependency published an hour ago can turn a
  pull request red for a reason the pull request did not cause.
- **`--locked`** reproduces the dependency set the lockfile pins, which is what every
  other gate in this template already tests, and makes the job deterministic.

Recommendation: **`--locked` on the pull-request lane.** The fresh-resolution question
is real but it belongs to a lane that already exists for exactly this class of
question — **R34**'s `canary.yml` `latest-deps` leg (`research/topics/34-scheduled-freshness-lanes/DECISION.md`,
`## Decision`: weekly `schedule` + `workflow_dispatch`, `cargo update --verbose`, no
dependency cache, a `report` job opening a `canary`-labelled issue). This report
**recommends to R34, without changing it**, that the `latest-deps` leg run the same
recipe with `--locked` dropped; R34's decision states its legs run "the test command
R32 selects", so adding this is R34's and R11's call, not R50's.

**Observable acceptance criteria.** Numbered so `## Validation strategy` can point at
them. Every one of these is **proposed**; none has been executed.

- **AC1** — `cargo package -p rs-launch-blueprint --locked --no-verify` exits 0 and
  `target/package/rs-launch-blueprint-<ver>.crate` exists, where `<ver>` is the version
  `cargo metadata --no-deps --format-version 1` reports for the package.
- **AC2** — extracting that `.crate` into a directory outside the repository yields
  `rs-launch-blueprint-<ver>/` containing `Cargo.toml` and `Cargo.lock`.
- **AC3** — `cargo install --path <extracted> --root <tmp-root> --locked --debug` exits
  0 **and** `<tmp-root>/bin/rslbp` exists and is executable — the two halves are
  separate assertions, for a reason verified in Cargo's own test suite rather than
  assumed. The cargo-install docs state binaries go to "the installation root's `bin`
  folder" and that `--root` is first in the root precedence order (retrieved
  2026-09-17). The `required-features` behaviour comes from
  `tests/testsuite/required_features.rs` at tag `rust-1.98.0`, test
  `install_default_features` (`:715-797`, retrieved 2026-09-17), which pins three
  distinct outcomes: (a) with the feature on, `cargo install --path .` installs the
  binary; (b) with the feature off and **no** `--bin`, cargo **warns**
  *"none of the package's binaries are available for install using the selected
  features"* and **succeeds having installed nothing** — the test asserts
  `assert_has_not_installed_exe` after a plain `.run()`; (c) with the feature off and
  `--bin=foo`, cargo **fails with status 101**. Outcome (b) is why the exit status
  alone cannot carry AC3: a manifest change that feature-gated every binary would leave
  a status-0 smoke test that installed and ran nothing. Exactly **one** binary
  (`rslbp`) is the expected count here because R69's `<app>-serve` carries
  `required-features = ["web"]` and the `web` feature is off by default, while `rslbp`
  carries no `required-features` at all (R49 decision-table row 3), so it is always
  selected and no `--bin` flag is needed — and per outcome (c), adding one would be
  actively wrong on the default leg.
- **AC4** — `<tmp-root>/bin/rslbp --version` exits 0 and its stdout contains the
  version string from AC1.
- **AC5** — nothing is left behind: the temp root and the extracted tree are removed on
  every exit path, and no binary is written to `$CARGO_HOME/bin`.
- **AC6** (web leg, conditional on R69's feature) — with `--features web`, the install
  creates **two** executables, `rslbp` and R69's `<app>-serve`, and each exits 0 for
  `--version`. R69's value fixes the second target's name as the literal
  `"<app>-serve"`; whether that resolves to `rslbp-serve` alongside R49's `rslbp`
  ruling is **unverified here** and is R69/R49's to state.
- **AC7** (negative control, proposed) — deleting a file from the `[package] include`
  allow-list that the build needs makes AC3 fail. This is the check that distinguishes
  option C from option B, and a template that cannot demonstrate it has not proved it
  is running option C.

**Minimal realistic example, and how it composes.** One `just` recipe holds the whole
procedure; one CI job runs `just install-check` and nothing else. That keeps the
local and CI paths byte-identical — the defect ts's split has: `pack-check` exists but
no workflow invokes it, verified by grepping all eight of ts's workflow files at the
pin (`ci.yml`, `codeql.yml`, `dependency-review.yml`, `difftree-pr-comment.yml`,
`manual-pr-security-scan.yml`, `publish.yml`, `release-please.yml`,
`update-contributors.yml`) for `pack-check`/`pack_check`: **no match in any file**, so
F221's ts evidence at `Justfile:276` stands as recorded.

**Cost, stated with its workload and its levers rather than as a number.** No timing
was measured and none is invented; no Rust package exists to measure. The workload is:
compile `rs-launch-blueprint`'s full dependency tree plus the crate, once, on a
GitHub-hosted `ubuntu-latest` runner. The cost drivers, each with its documented
source (cargo-install docs, retrieved 2026-09-17):

| Driver | Default | Lever | Effect |
|---|---|---|---|
| Profile | **release** | `--debug` ("Build with the dev profile instead of the release profile") | dev-profile compile, and it is the *better* smoke profile: `debug-assertions` and `overflow-checks` are on, so a startup path that trips an assertion fails loudly instead of silently |
| Target directory | *"Defaults to a new temporary folder located in the temporary directory of the platform"*; and *"When using `--path`, by default it will use target directory in the workspace of the local crate unless `--target-dir` is specified"* — but the extracted package is **not** in the workspace, so it gets its own throwaway `target/` | `--target-dir` (or `CARGO_TARGET_DIR`) pointed at a stable path | lets R10's cache action cover the smoke build. The docs call this out explicitly: *"this can be useful for caching build artifacts on continuous integration systems"* |
| Duplicate verification build | `cargo package` verifies by compiling the extracted tree | `--no-verify` on the packaging step | removes one of two compiles of the same tree; the install compiles it anyway |
| Feature set | default (`web` off) | `--features web` as a second, path-gated step | a second dependency tree (`axum`, `tokio`) — the expensive leg, and the reason it is conditioned |

With `--debug` + a cached `--target-dir`, the marginal cost over the test job is
recompiling the crate itself against already-cached dependencies. That is the basis for
answering HIGH-2 **no** — Rust's compile time does not argue for ts's local-only
cadence — with the caveat stated in `## Confidence`: the claim is a cost *model* backed
by documented behaviour and by three well-regarded projects doing compile-heavy
packaging checks on pull requests, not a measurement.

**What the smoke test adds over what the template already has.** Honestly bounded:
R26's element 3 (`cargo publish --dry-run --locked`) already packages **and compiles**
the packaged tree at publish time, and R26's element 1 already diffs the packed file
list. The marginal coverage of this item is the last step of B1 — **the installed
`rslbp` is executed, exits 0, and reports its version** — plus moving the packaging
compile from publish time to pull-request time. A report that claimed more would be
overselling it.

**The library surface (B4's ts half).** ts checks the installed *library* too
(`Justfile:312`). The Rust analogue would be a scratch consumer crate with
`rs-launch-blueprint = { path = "<extracted>" }` that `use`s a public item and builds.
**Recommendation: do not bind it; record it as hardening.** Reason: `cargo install`
builds the packaged `[[bin]]`, and this template's `src/main.rs` is a thin CLI over the
library crate (R49 decision-table rows 2–3; R01's port lives in the library), so the
`[lib]` is compiled transitively and a missing or broken `src/lib.rs` already fails
AC3. What a scratch consumer would additionally catch — a public item that exists in
the tree but not in the packaged set — is **R26**'s packed-file diff and **R04**'s
public-API surface gate, both resolved. The condition under which this flips is
explicit: **if `src/main.rs` ever stops depending on the library crate**, the `[lib]`
is packaged but never compiled by the install, and the scratch-consumer check becomes
necessary rather than optional. That is a re-verify trigger, listed below.

### Recommendation

**One stack, entirely first-party, adding no crate and no GitHub Action to the
template: `cargo package --no-verify` → extract the `.crate` outside the repository →
`cargo install --path … --root <tmp> --locked --debug --target-dir <cached>` → run
`<tmp>/bin/rslbp --version`, held in a single `just` recipe named `install-check`, and
wired into pull-request CI as one `install-smoke` job on `ubuntu-latest` only, gated by
R11's path-filter mechanism — py's cadence, ts's mechanism depth.**

Answering the prompt's questions directly:

- **HIGH-1 — closest analogue of `uvx`'s throwaway install-and-run.** Option C, not the
  ledger's option B and not `cargo run --locked`. `cargo install --root <tmp>` is the
  throwaway-location half; installing **from the extracted `.crate`** is the
  just-built-artifact half that `uvx --from dist/*.whl` supplies and that `--path .`
  drops. It genuinely exercises the same question, with one ecosystem difference stated
  rather than hidden: `uvx` resolves fresh from the index by default and `cargo install`
  ignores the packaged lockfile by default — so the *unlocked* form is the literal
  behavioural twin, and this report deliberately trades that twinhood for determinism
  on the PR lane and hands the fresh-resolution question to R34's existing canary.
- **HIGH-2 — does gating every PR cost meaningfully more in Rust, and does that argue
  for ts's cadence?** It costs more in kind (a compile, not an unpack), and **no**, it
  does not argue for local-only. Three levers (`--debug`, cached `--target-dir`,
  `--no-verify`) plus the path filter py itself already applies bring it down to a
  recompile of the crate against cached dependencies; and the "path-filtered subset"
  the question offers as a third option is **what py already does** — `build-smoke` is
  `needs: changes` / `if: needs.changes.outputs.code == 'true'`, on one runner, not the
  OS matrix (`ci.yml:206-209` at pin `b08bccfb`). uv gates `cargo publish --dry-run` the
  same way (`ci.yml:58-61`). Adopt py's cadence *including* its path filter.
- **HIGH-3 — principles, agreement level, and justified differences.** In the table
  under `### Principles and implementation`: B1 (install the packaged artifact into a
  throwaway location and run it) and B2 (the packaged artifact is the subject) must
  agree at **capability** and **architectural-pattern** level, and — per the
  `BASELINE-REVIEW` above — **already do** in both source repositories. B3 (what a
  failure blocks) and B4 (how strong the assertion is) are **policy**, where rs follows
  py on B3 and ts on B4. The justified ecosystem difference is mechanical and one line
  long: py and ts install a pre-built artifact, Rust compiles a source archive, so the
  Rust realization needs a profile and a cache lever that neither source needs. Nothing
  about the principle changes.
- **MEDIUM-4 — assert more than "exits 0"?** **Yes, one step further, and one step
  short of ts.** Assert exit 0 **and** that `--version`'s stdout contains the version
  `cargo metadata` reports — a round-trip from the manifest through the packaged
  artifact to the installed command, which is the ts principle (`Justfile:307-310`)
  made format-agnostic because R22 (`runtime-version-accessor`) is open. When R22 and
  R60 fix the exact string the assertion can tighten to ts's equality form. Do **not**
  add the library-surface check (reasoning and its flip condition above). For the web
  surface, **yes, conditionally**: R69 is resolved in the working tree and its
  `web-extra-surface` value adds `[[bin]] name = "<app>-serve"` with
  `required-features = ["web"]`, whose `-V/--version` prints to stdout and exits 0 — so
  AC6 is a second `cargo install --features web` step in the same recipe, run only when
  R11's web path filter fires, because it drags in `axum` and `tokio`.
- **LOW-5 — recipe vocabulary.** Yes, it belongs to the F176–F178 vocabulary, which is
  `just` (F176) + `[group(…)]` attributes (F177) + short aliases (F178) — not a fixed
  list of recipe names. Recommended: recipe **`install-check`**, attributes
  `[group('build'), group('releases')]`, **no alias**. Evidence for each part: ts's
  closest recipe carries `[group('releases'), group('build')]` (`Justfile:275`) and has
  **no** alias, and in both sources aliases are reserved for the daily loop — ts
  `alias b := build`, `f := format`, `l := lint`, `t := test`, `a := all`, `c := check-deps`,
  `fc := format-check`, `tc := typecheck`, `pc := pre-commit-run`; py `alias c`, `f`,
  `ft`, `ct`, `l`, `tc`, `li`, `t`, `ca`, `b`, `hooks`, `cycle`, `contributors` (both
  read at their pins, 2026-09-17). The name deliberately differs from ts's `pack-check`
  because in rs the packed-content half is **R26**'s and lives in the publish workflow,
  so a recipe called `pack-check` would promise a check it does not perform. The CI job
  name `install-smoke` echoes py's `build-smoke` family while naming what it does.

### Members

#### Rust toolchain packaging and install primitives (`cargo package` + `cargo install`)

##### Landscape

Bin 1 of the three-bin map — built-in / first-party toolchain. The candidate set is the
five options A–E tabulated under `### Principles and implementation`; each is built
from `cargo` subcommands except D, which adds `cargo-local-registry`. There is no
third-party crate that wraps "install this package's artifact into a scratch root and
run it": the GitHub code search for `"cargo install --path target/package"`
(`GET https://api.github.com/search/code`, retrieved 2026-09-17) returned
`total_count: 7`, all documents or fixtures, and no crates.io search surfaced a
maintained wrapper. The ecosystem norm here is a few lines of shell over first-party
commands — the same conclusion R26 reached for the packed-content half.

##### Principles and implementation

The principle: take the bytes the registry would serve, install them with the verb a
consumer uses, into a location that is not the developer's environment, and execute the
resulting command. `cargo package` supplies the first, `cargo install --root` the
second and third, and running `<root>/bin/rslbp` the fourth. The one ecosystem-specific
design choice is **where the extraction lands**: outside the repository, because
`rust-lang/cargo`'s own verification path manufactures an ephemeral workspace to build
an extracted package that sits inside one (`src/cargo/ops/cargo_package/verify.rs:62-72`
at tag `rust-1.98.0`, retrieved 2026-09-17) and the `cargo install` CLI does not.

##### Dominant choice

`cargo install`. It is the ecosystem's install verb, it is what the Cargo Book
documents for this purpose, and it is what a well-regarded project runs in CI today:
`sharkdp/bat` `.github/workflows/CICD.yml:99`, `:103`, `:129` — `cargo install --locked --path .`,
followed by running the installed command (60 472 stars, `archived: false`, `pushed_at`
`2026-09-04T19:10:30Z`, 330 open issues; `GET https://api.github.com/repos/sharkdp/bat`
and `GET https://api.github.com/search/issues?q=repo:sharkdp/bat+is:issue+is:open`,
retrieved 2026-09-17).

##### Qualified shortlist

Options **C** (recommended), **B** (runner-up), **E** (adopted elsewhere — R26's
element 3) and **D** (rejected on cost). Flag surface verified on the locally installed
`cargo 1.98.0 (797e8a9bc 2026-08-05)` by running `cargo install --help` on 2026-09-17;
every flag the recipe uses is present: `--path <PATH>`, `--root <DIR>`, `--locked`,
`--offline`, `--frozen`, `--debug`, `--profile <PROFILE-NAME>`, `--target-dir <DIRECTORY>`,
`--no-track`, `--bin [<NAME>]`, `--bins`, `-F/--features`, `--all-features`,
`--no-default-features`, `-n/--dry-run` (marked *unstable* in the help text and
therefore **not** used).

##### Excluded by gate

**None.** No candidate in this member fails a fitness gate. Options A, B, D and E are
set aside on **fit** — a different and weaker test, argued in the option table — and
are named there rather than here so the two judgments are not conflated. Gate results
for the recommended option:

1. **Licence** — `inapplicable — owner ruling 2026-09-12 (Q7.B)`.
2. **MSRV** — `inapplicable` as a crate gate: no crates.io dependency is added, so
   there is no dependency-tree MSRV to bound. The toolchain floor the recipe implies is
   satisfied by any toolchain in the `msrv-policy` window — current stable is
   `1.98.1 (48a229cea 2026-09-01)`
   (`https://static.rust-lang.org/dist/channel-rust-stable.toml`, retrieved 2026-09-17),
   so the floor is **1.96.0**, and every flag used is long-established, verified present
   on 1.98.0. Whether the smoke job *also* runs on the MSRV toolchain is R11/R42's
   matrix question, untouched here.
3. **RustSec / `unsafe`** — `inapplicable`: nothing is added to the dependency tree, so
   there is no package page to consult. No `unsafe` is introduced; the recipe is shell
   plus first-party commands. (Probe semantics established by the `time` → HTTP 200 vs
   `just` → HTTP 404 control on `https://rustsec.org/packages/<name>.html`, retrieved
   2026-09-17.)
4. **`ubuntu-latest, macos-latest`** — passes. `cargo`, `tar`, `mktemp` are present on
   both images; `tar -xzf` is handled by GNU tar on Ubuntu and by bsdtar on macOS
   (`/usr/bin/tar` confirmed present on the macOS 25.4 host used for this run,
   2026-09-17). Windows: `cargo install --root` works, but the POSIX shell body would
   need a separate form — **noted, not required** (`target-os-matrix` excludes Windows).
5. **Default features / async-runtime coupling** — the install runs with the package's
   default features, which per R69 leave `web` **off**, so the default leg installs one
   binary, `rslbp`, and pulls in no async runtime. The `--features web` leg adds `tokio`
   — R69's coupling, surfaced here, not created here.
6. **Binary size / compile time** — the dominant cost of the whole item; the driver
   table under `### Principles and implementation` states it with its levers.
   Binary size is not asserted by this check; a size budget would be R68's.

##### Up-and-comers

`dist` (axodotdev) for release-artifact orchestration and `cargo-binstall` for
prebuilt-binary installs are the two moving parts of this area, and **both are R68's**,
not this item's: they answer "does the released binary install", where this row asks
"does the package a consumer builds install". Figures so the boundary is drawn against
data rather than assertion — `cargo-binstall`: `recent_downloads` 126 854, `downloads`
3 492 732, newest un-yanked `1.23.0` created `2026-09-05T16:59:01Z`
(`https://crates.io/api/v1/crates/cargo-binstall` and `/versions`); 2 876 stars,
`archived: false`, `pushed_at` `2026-09-15T01:23:02Z`, 94 open issues, licence
`GPL-3.0` (`https://api.github.com/repos/cargo-bins/cargo-binstall`, `search/issues`);
no RustSec page (HTTP 404). All retrieved 2026-09-17. Maintenance: **active**.

##### Fit for this template

The template is CLI + library + optional web service, and the fit is exact on the CLI
axis, transitive on the library axis and conditional on the web axis — spelled out in
AC3, AC6 and the library-surface paragraph. One template-specific detail decides the
expected count: because R69's second binary carries `required-features = ["web"]` and
R49 verified that such a target is **skipped when its features are off**, the
default-feature install must produce exactly one binary, `rslbp`, and an install that
produces two is a signal that the feature gate leaked.

##### Recommendation

Option **C**, with `--locked --debug --target-dir <cached>` on the pull-request lane and
`--no-verify` on the packaging step.

##### Ranked runner-up

Option **B**, `cargo install --locked --path . --root "$tmp"`. Take it if the
extract-and-install step ever proves fragile in P03: it keeps the install-and-run half
of the principle, is one line, and has live precedent in `sharkdp/bat`'s CI. What it
gives up is stated once more so the trade is explicit — it can never fail because of a
file missing from R49's `include` allow-list, which is the half py buys with
`uv build` + `uvx --from dist/*.whl`.

##### Tradeoffs

| Axis | Option C (recommended) | Option B (runner-up) |
|---|---|---|
| Catches a broken `include` allow-list | yes (AC7) | no |
| Steps in the recipe | 5 | 2 |
| Failure modes of the recipe itself | extraction path, version interpolation, temp-dir cleanup | none beyond `cargo install` |
| Precedent in a well-regarded project | **none found** (code search, 7 weak hits) | `sharkdp/bat` CI |
| Faithfulness to F222 (`uvx --from dist/*.whl`) | high | partial |

##### Parameters

Owns nothing. `assumes build-tool-output-shape` (R49, owner-accepted) for three
values the recipe reads: the binary name `rslbp`, the single `[[bin]]`, and the
`[package] include` allow-list whose contents AC7 exercises. No `CONFLICT:` — the
recipe works unchanged at R49's published value, including the deliberate divergence
between the distribution name `rs-launch-blueprint` and the command `rslbp`
(`cargo install rs-launch-blueprint` installs `rslbp` with no `--bin` flag, R49
check 8).

##### Migration implications

None in `Cargo.toml`; no dependency, no `[dev-dependencies]` entry, no build script.
The whole member is shell inside one `just` recipe.

##### Validation strategy

AC1–AC5 and AC7 (proposed). Executed in this run: the flag surface
(`cargo install --help`, cargo 1.98.0, 2026-09-17); the documented defaults for
profile, target directory, installation root and lockfile handling
(`https://doc.rust-lang.org/cargo/commands/cargo-install.html`, 2026-09-17); the
ephemeral-workspace behaviour (`rust-lang/cargo` `src/cargo/ops/cargo_package/verify.rs`
at `rust-1.98.0`, 2026-09-17). **Not executed:** any packaging, install, or run — no
Rust package exists here and this run wrote no file but this report.

##### Confidence & re-verify trigger

**Medium-high** on the mechanism (first-party, documented, flags verified on a current
toolchain); **medium** on the composition, because the exact pipeline has no
well-regarded adopter. Re-verify if: `cargo install`'s lockfile default changes;
`cargo package`'s output path or verification behaviour changes; `cargo install --path`
on an extracted package is observed to fail for a workspace reason even outside the
repository; or R49's `include` allow-list moves.

##### Sources

`https://doc.rust-lang.org/cargo/commands/cargo-install.html` (2026-09-17);
`https://api.github.com/repos/rust-lang/cargo/contents/src/cargo/ops/cargo_package/verify.rs?ref=rust-1.98.0` (2026-09-17);
`https://api.github.com/repos/rust-lang/cargo/contents/src/cargo/ops/cargo_package/mod.rs?ref=rust-1.98.0` (2026-09-17);
`https://api.github.com/repos/rust-lang/cargo/contents/src/cargo/core/workspace.rs?ref=rust-1.98.0` (2026-09-17);
`https://api.github.com/repos/rust-lang/cargo/contents/tests/testsuite/required_features.rs?ref=rust-1.98.0` (2026-09-17);
`https://static.rust-lang.org/dist/channel-rust-stable.toml` (2026-09-17);
`https://api.github.com/repos/sharkdp/bat/contents/.github/workflows/CICD.yml` (2026-09-17);
`https://crates.io/api/v1/crates/cargo-binstall`, `/versions` (2026-09-17);
`https://api.github.com/repos/cargo-bins/cargo-binstall` (2026-09-17);
`https://rustsec.org/packages/cargo-binstall.html`, `.../time.html` (2026-09-17);
local `cargo install --help`, `cargo --version` (cargo 1.98.0, 2026-09-17).

#### `just` 1.58.0 — the recipe host

##### Landscape

Bin 2 of the map for task runners, and **already settled upstream of this item**:
F176 (`docs/port/COMMONALITY.md:180`, `COMMON → REUSE`) records `just` as the
task-runner tool for both sources, with F177 (recipe grouping via attributes) and F178
(short aliases) as its syntax features. The alternatives a fresh survey would raise —
`make`, `cargo xtask`, `cargo-make` — are foreclosed here by R49's decision-table row 1
(*"No `[build-dependencies]` entry, no `build.rs`, no `cargo-make`, no `dist`, no
`xtask`"*) and by R42's toolchain decision. This member therefore **re-verifies the
settled choice against this item's gates** rather than re-opening it.

##### Principles and implementation

The principle the recipe host must preserve: the local and the CI path run the **same**
procedure, so that "it passes on my machine" and "it passes in CI" are the same claim.
That is exactly where ts's split leaks — `pack-check` exists and no workflow calls it
(no match for `pack-check` in any of ts's eight workflow files at pin `cb1cbcb2`,
checked 2026-09-17) — and the fix is not a different tool but a one-line CI step that
invokes the recipe.

##### Dominant choice

`just`. Figures, each with its endpoint, all retrieved **2026-09-17**:

| Figure | Value | Endpoint / rule |
|---|---|---|
| 90-day downloads | 533 628 | `GET https://crates.io/api/v1/crates/just` → `crate.recent_downloads` |
| All-time downloads | 2 597 663 | same → `crate.downloads` |
| Last release | `1.58.0`, `created_at` `2026-08-03T20:29:15Z` | `GET https://crates.io/api/v1/crates/just/versions`, newest with `yanked: false` |
| Stars | 35 828 | `GET https://api.github.com/repos/casey/just` → `stargazers_count` |
| Archived | `false` | same → `archived` |
| Last push | `2026-09-01T20:47:57Z` | same → `pushed_at` |
| Open issues | 171 | `GET https://api.github.com/search/issues?q=repo:casey/just+is:issue+is:open` → `total_count` |
| Issue responsiveness | **median 0.53 days; 0 unanswered** | the 10 most recently opened issues (`#3707, 3704, 3703, 3702, 3700, 3699, 3698, 3695, 3694, 3691`, pull requests excluded), each compared against its first comment whose `author_association` is `OWNER`/`MEMBER`/`COLLABORATOR`. All ten answered, all by `casey` (`OWNER`). Per-issue days: 2.41, 0.42, 0.64, 0.68, 2.48, 2.68, 0.07, 0.01, 0.02, 0.16 |
| Advisories | **none** | `https://rustsec.org/packages/just.html` → HTTP 404, against the `time` → HTTP 200 control |
| Adopters | `py-launch-blueprint` `Justfile` at pin `b08bccfb` and `ts-launch-blueprint` `Justfile` at pin `cb1cbcb2`; F176 records `casey/just v1.58.0` checked 2026-09-02 | the two source repositories are the relevant, well-regarded reference for this template because the template ports them |

**Maintenance state: `active`** — a release six weeks before retrieval, a push two
weeks before, not archived, and a maintainer median first response under 13 hours
across the ten most recent issues.

##### Qualified shortlist

`just` only. `make` and an `xtask` crate are excluded upstream (R49 row 1, R42), and
re-litigating a `COMMON → REUSE` row inside this item would be exactly the silent
cross-item change the charter forbids.

##### Excluded by gate

**None.** Gate results:

1. **Licence** — `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Recorded for the
   reader's context only: `GET https://api.github.com/repos/casey/just` reports
   `license.spdx_id` `CC0-1.0` (2026-09-17). `just` is a developer-invoked executable,
   not a linked dependency; it never enters `rs-launch-blueprint`'s dependency tree.
2. **MSRV** — passes, and is doubly `inapplicable` in the strict sense. `just`'s own
   manifest declares `rust-version = "1.89.0"` and `edition = "2024"`
   (`GET https://api.github.com/repos/casey/just/contents/Cargo.toml`, 2026-09-17),
   which is below the `msrv-policy` floor of **1.96.0** derived from stable `1.98.1`.
   But it is installed as a binary, not compiled into this template, so its MSRV
   constrains nothing here.
3. **RustSec / `unsafe`** — no advisory (HTTP 404, control-validated). `unsafe` posture:
   `GET https://api.github.com/search/code?q=repo:casey/just+unsafe+language:rust`
   returns `total_count: 1` (2026-09-17) — effectively no `unsafe` surface, and in any
   case not linked into this template.
4. **`ubuntu-latest, macos-latest`** — passes, wider than required: `casey/just`
   `.github/workflows/ci.yaml:94-99` runs its test matrix over `ubuntu-latest`,
   `macos-latest` **and** `windows-latest` (2026-09-17).
5. **Default features / async-runtime coupling** — `inapplicable`; `just` is invoked as
   a process and couples the template to no runtime.
6. **Binary size / compile time** — `inapplicable` to the template's artifacts: `just`
   contributes nothing to `rslbp`'s size or build time. Its own acquisition cost is
   R42's `package-manager-invocation` question, already settled.

##### Up-and-comers

None worth naming for this member: the task-runner slot is settled by F176 and the
programme is not re-deciding it here.

##### Fit for this template

Exact. The recipe needs POSIX shell, a temp directory, an interpolated version string
and an early exit — all of which `just`'s `#!/usr/bin/env sh` recipe form already
carries in both sources, and ts's `pack-check` is a working demonstration of precisely
this recipe shape (`Justfile:276-313` at pin `cb1cbcb2`). One portability correction is
needed when porting that shape: ts hardcodes `mktemp -d /private/tmp/ts-pack-check.XXXXXX`
(`Justfile:299`), a macOS-only path; the Rust recipe uses a bare `mktemp -d`, which
works on both runner images.

##### Recommendation

`just` 1.58.0 (whatever version R42's provisioning installs), one recipe named
`install-check`, attributes `[group('build'), group('releases')]`, no alias.

##### Ranked runner-up

A plain `ci/install-check.sh` invoked by both the Justfile and the workflow. Take it
only if the recipe ever needs to run where `just` is absent. It is a strictly worse
default here because it splits the procedure across two files and reopens F176.

##### Tradeoffs

Using a recipe rather than inlining the shell in the workflow costs one indirection and
buys the property that made this item's F221 divergence worth researching: the
developer and CI run the *same* text. The cost is that CI must have `just` — which R42
already requires for every other check.

##### Parameters

Owns nothing. `assumes package-manager-invocation` (R42, resolved) for how the recipe
names its commands: `cargo package`, `cargo install`, `cargo metadata` are Cargo's own
built-in subcommands written as they are; `just`, `tar` and `jq` are bare executables
resolved on `PATH`, with `command -v` as their presence test. No new tool is
introduced — `jq` and `tar` are already required by R26's element 2. No `CONFLICT:`.

##### Migration implications

`Justfile`: one recipe added, with its two group attributes and its doc comment. No
alias line. `just check-deps`: unchanged, since the recipe adds no tool.

##### Validation strategy

Proposed: `just --list` shows `install-check` under both the `build` and `releases`
groups; `just install-check` exits 0 on a clean tree and non-zero for AC7's negative
control. Executed in this run: `just --version` on the host reports **1.57.0** — one
minor behind the 1.58.0 that F176 and crates.io record (2026-09-17), which changes
nothing in the recipe's syntax but is reported rather than smoothed over.

##### Confidence & re-verify trigger

**High.** Re-verify if F176's task-runner row changes, if R42's invocation rules change,
or if `just` goes dormant by the rubric (no release plus an unpatched advisory or a
maintainer notice — none of which holds today).

##### Sources

`https://crates.io/api/v1/crates/just`, `/versions` (2026-09-17);
`https://api.github.com/repos/casey/just` (2026-09-17);
`https://api.github.com/search/issues?q=repo:casey/just+is:issue+is:open` (2026-09-17);
`https://api.github.com/repos/casey/just/issues/<n>` and `/comments` for the ten issues
listed above (2026-09-17);
`https://api.github.com/repos/casey/just/contents/Cargo.toml` (2026-09-17);
`https://api.github.com/repos/casey/just/contents/.github/workflows/ci.yaml` (2026-09-17);
`https://rustsec.org/packages/just.html` (2026-09-17);
`git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:Justfile` (2026-09-17);
`git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:Justfile` (2026-09-17).

#### The `install-smoke` pull-request job (GitHub Actions)

##### Landscape

Bin 1 of a different map — this member is a **workflow pattern**, not a crate, so the
spec §7.6 crate figures (90-day downloads, all-time downloads, last release, RustSec
advisories, reverse dependencies) are **`inapplicable`: a CI job has no crates.io
identity to query**. The pattern fields used instead are: which projects run it, on
what trigger, on how many runners, with what gating, and with what cost controls — all
sourced from live workflow files below. The field has three observable shapes:
(i) a gated pull-request job (py, uv); (ii) an ungated pull-request job (bat);
(iii) no CI job at all, recipe-only (ts).

##### Principles and implementation

The principle at stake is F221's, and it is a **policy** one: what a packaging failure
blocks. py blocks the pull request; ts blocks only a developer who opts in. The
observable acceptance criterion for adopting py's cadence is that a pull request that
breaks packaging or the installed command turns red **before** merge, on a job whose
name says what it checks.

##### Dominant choice

A single path-filtered pull-request job, which is what both authoritative precedents
do:

- **py at pin `b08bccfb`**, `.github/workflows/ci.yml:204-223` — job `build-smoke`,
  `runs-on: ${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`, `needs: changes`,
  `if: needs.changes.outputs.code == 'true'`, `permissions: contents: read`; steps:
  checkout, install uv, `uv build`, `uv sync --locked --only-group dev`,
  `uv run --no-sync twine check dist/*`, then the two smoke steps
  `uvx --from "$(ls dist/*.whl)" plbp --version` and
  `uvx --from "$(ls dist/*.tar.gz)" plbp --version`. Its own header comment states the
  rationale: *"Catches packaging breakage (missing files, broken entry point, bad
  metadata) at PR time instead of at the release tag."* Note two things the ledger row
  does not: py runs it on **one** runner, not its three-OS test matrix, and py already
  path-filters it — the "path-filtered subset" HIGH-2 offers as an alternative is py's
  existing cadence.
- **`astral-sh/uv`**, `.github/workflows/check-publish.yml` + `ci.yml:58-61` — the same
  shape for a Rust project: `cargo publish --workspace --dry-run`, `needs: plan`,
  `if: ${{ needs.plan.outputs.test-code == 'true' }}`, one runner,
  `timeout-minutes: 20`, `permissions: contents: read`, with `Swatinem/rust-cache`
  pinned by 40-hex SHA and `save-if` restricted to `main`.

##### Qualified shortlist

(i) gated PR job — recommended; (ii) ungated PR job — bat's shape, rejected because it
runs a compile on documentation-only pull requests; (iii) recipe-only — ts's shape,
rejected because F221 is the divergence this item exists to close and because a recipe
nothing calls decays silently; (iv) merge-queue-only or scheduled-only — rejected
because it detects the breakage after review rather than during it, though the
*unlocked* variant belongs on R34's schedule, as argued above.

##### Excluded by gate

**None**, and the gates map onto a workflow job as follows:

1. **Licence** — `inapplicable — owner ruling 2026-09-12 (Q7.B)`.
2. **MSRV** — `inapplicable` to a job; the toolchain the job installs is R42/R34's.
3. **RustSec / `unsafe`** — `inapplicable`; no crate. The security surface of a job is
   its third-party actions, which is **R20**'s policy (enforced owner-prefix SHA pinning
   with a trailing `# vX.Y.Z` release comment) and **R08**'s permissions hardening.
4. **`ubuntu-latest, macos-latest`** — the job is recommended on **`ubuntu-latest` only**,
   with an argument rather than by inheritance from py: what this check exercises —
   `include` completeness, manifest metadata, the install verb, the produced command
   `rslbp` — is OS-independent in Cargo, because the `.crate` is a source archive with
   no per-OS variant analogous to a wheel's platform tag. A macOS-specific build break
   in the packaged tree is caught by the ordinary test job, which does run on
   `macos-latest`; and macOS coverage of the *recipe itself* comes free from developers
   running `just install-check` locally. Widening to both runners is a one-line matrix
   change if a macOS-only packaging failure is ever observed.
5. **Default features / async-runtime coupling** — the default leg installs with default
   features (one binary, `rslbp`); the `--features web` leg is a second step conditioned
   on R11's web path filter.
6. **Binary size / compile time** — the whole cost question; driver table above.

##### Up-and-comers

Nothing new in the field worth adopting for this job. The only moving part is the
runner/caching layer (`Swatinem/rust-cache` and the hosted-runner tiers uv uses), and
the cache-action choice is **R10**'s open item, consumed here, not decided here.

##### Fit for this template

Fits R11's unresolved `ci-job-structure` without prejudging it: the job is one unit of
work whose body is a single `just install-check`, so whichever shape R11 picks — a
dedicated job or a step inside a shared job — the content is unchanged and the skip
gate is R11's mechanism, not a second one invented here.

##### Recommendation

One job named `install-smoke`, `runs-on: ubuntu-latest`, gated by R11's code path
filter, `permissions: contents: read` under R08's top-level `permissions: {}` baseline,
an explicit `timeout-minutes`, the toolchain installed by whatever action R42/R34 fix
(R34 records `dtolnay/rust-toolchain`, `archived: false`, MIT, referenced with an
explicit `toolchain:` input and pinned in the form R20 selects), the dependency cache
supplied by R10's action, and a single body step `run: just install-check`. Illustrative
skeleton — **proposed, not executed**, with every third-party pin left as a placeholder
because each is another item's to fix:

```yaml
  install-smoke:
    name: install-smoke
    runs-on: ubuntu-latest
    needs: changes                      # R11 owns the skip-gate mechanism
    if: needs.changes.outputs.code == 'true'
    permissions:
      contents: read                    # under R08's top-level `permissions: {}`
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7       # actions/* stays major-tag-pinned per R20
        with:
          persist-credentials: false
      - uses: <toolchain action>@<40-hex>   # R42/R34 choose it; R20 fixes the pin form
      - uses: <cache action>@<40-hex>       # R10 chooses it
      - run: just install-check
      - if: needs.changes.outputs.web == 'true'   # R11 owns this filter's name
        run: just install-check web
```

Two deliberate absences in that skeleton. There is **no `CARGO_TARGET_DIR` override**:
the recipe reads `cargo metadata`'s `target_directory` and derives both the `.crate`
path and its `--target-dir` from it, so setting the variable in the job would only move
what the cache action must cover, and hardcoding a different value in the workflow than
the recipe reads is precisely how a recipe stops working in the job that calls it.
And there is **no network restriction**: `cargo package` performs registry verification
and `cargo install` resolves and downloads dependencies, so this job needs outbound
network — the same note R26 recorded for its publish-time verify job, handed to **R08**
(`workflow-permission-hardening`) rather than settled here.

`Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2` is quoted from
uv's `check-publish.yml` (retrieved 2026-09-17) **only** as evidence that an R20-shaped
pin for a cache action exists in the wild — it is not this item's selection.

##### Ranked runner-up

Fold the step into R11's shared build job instead of a dedicated job. Take it if R11
chooses the one-job shape; the only loss is a named red check on the pull request,
which is what makes a packaging failure legible to a reviewer.

##### Tradeoffs

Gating costs one compile per code-touching pull request and buys a failure caught at
review time rather than at the release tag — py's own stated rationale. Not gating
costs nothing and buys nothing; ts demonstrates the end state, a correct recipe that no
automation has ever run.

##### Parameters

Owns nothing. `assumes ci-job-structure = —` (R11, unresolved — the job shape and the
skip mechanism are R11's, and this recommendation is written to be shape-neutral).
Also reads, without registering a consumption: R20's pinning policy, R08's permissions
baseline, R10's cache action, R42/R34's toolchain action, R69's `web` feature.
No `CONFLICT:`.

##### Migration implications

`.github/workflows/ci.yml`: one job added. No change to `Cargo.toml`, no new action
beyond the toolchain and cache actions other items already introduce.

##### Validation strategy

Proposed: the job appears in the pull-request check list and is red when AC7's negative
control is introduced; it is skipped on a documentation-only pull request. Executed in
this run: the two precedent workflows were read in full at their sources (py at its
pin; uv via the GitHub contents API), and ts's eight workflow files were grepped for
`pack-check` with no match.

##### Confidence & re-verify trigger

**High** on the cadence (two authoritative precedents, one of them a Rust project by
the authors of the tool py uses); **medium** on the ubuntu-only scope, which rests on an
argument about Cargo's OS-independence rather than on an observation. Re-verify when
R11 resolves, if a macOS-only packaging failure is observed, or if R10's cache choice
makes a cached `CARGO_TARGET_DIR` unavailable.

##### Sources

`git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:.github/workflows/ci.yml` (2026-09-17);
`https://api.github.com/repos/astral-sh/uv/contents/.github/workflows/check-publish.yml` (2026-09-17);
`https://api.github.com/repos/astral-sh/uv/contents/.github/workflows/ci.yml` (2026-09-17);
`https://api.github.com/repos/astral-sh/uv/contents/.github/workflows/test-smoke.yml` (2026-09-17);
`https://api.github.com/repos/astral-sh/uv` (2026-09-17);
`https://api.github.com/repos/sharkdp/bat/contents/.github/workflows/CICD.yml` (2026-09-17);
`git -C ~/c/ts-launch-blueprint show cb1cbcb2…:.github/workflows/*.yml` (2026-09-17);
`research/topics/34-scheduled-freshness-lanes/DECISION.md`;
`research/topics/20-third-party-action-pinning-policy/DECISION.md`.

### Compatibility

The three members are not a novel combination; each pair has a live demonstration, and
the version matrix below is what was actually observed.

**Shared adopter for (task runner × pack-install-run smoke).** `ts-launch-blueprint`
itself, at pin `cb1cbcb2`: `Justfile:276-313` is a `just` recipe whose steps 5–6 pack
the artifact, install it into a scratch directory and run the installed command and a
library import. That is members 2 and the procedural core of member 1 composed, in
production, in one of this template's two source repositories.

**Shared adopter for (`cargo install` × GitHub Actions on `ubuntu-latest`).**
`sharkdp/bat` `.github/workflows/CICD.yml:99`, `:103`, `:129` — `cargo install --locked --path .`
inside Actions, followed by running the installed command (retrieved 2026-09-17).

**Shared adopter for (a compile-heavy packaging check × a path-filtered PR gate ×
`Swatinem/rust-cache`).** `astral-sh/uv` `check-publish.yml` + `ci.yml:58-61`
(retrieved 2026-09-17).

**Shared adopter for (`just` × this template's own CI).** Both source repositories ship
a `Justfile` and both wire recipes into CI; F176 records the tool as `COMMON → REUSE`.

**Version matrix observed.**

| Component | Version | How observed |
|---|---|---|
| Rust stable channel | `1.98.1 (48a229cea 2026-09-01)` | `https://static.rust-lang.org/dist/channel-rust-stable.toml`, 2026-09-17 |
| Cargo used to verify the flag surface | `cargo 1.98.0 (797e8a9bc 2026-08-05)` (Homebrew) | `cargo --version`, `cargo install --help`, 2026-09-17 |
| Cargo source read for behaviour | tag `rust-1.98.0` | GitHub contents API, 2026-09-17 |
| `just` — latest | `1.58.0` (`created_at` `2026-08-03T20:29:15Z`) | crates.io API, 2026-09-17 |
| `just` — on this host | `1.57.0` | `just --version`, 2026-09-17 |
| `just` MSRV | `rust-version = "1.89.0"`, `edition = "2024"` | `casey/just` `Cargo.toml`, 2026-09-17 |
| `msrv-policy` floor implied | **1.96.0** | stable `1.98.1` minus 2 minors |

The matrix has no conflict: `just` 1.58.0's MSRV (1.89.0) is far below the floor, the
recipe uses only long-stable `cargo` flags verified on 1.98.0, and nothing in the stack
requires a nightly feature.

**Not verified together.** The three members have never been run as one pipeline —
there is no Rust template to run them in. That is the compatibility gap this report
does not close, and it is why every acceptance criterion is labelled *proposed*.

### Parameters

- **Owns:** nothing. R50's `owns` cell is `—` in `research/CLAUDE.md` and in
  `docs/port/COMMONALITY.md`; this report introduces no new parameter.
- `assumes rust-edition = 2024` (fixed, owner 2026-09-02).
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed) — with stable `1.98.1` on 2026-09-17 this makes the floor **1.96.0**.
- `assumes license = MIT OR Apache-2.0` (fixed) — relevant only to R49's `include` allow-list, which must carry `LICENSE-MIT` and `LICENSE-APACHE`; not evaluated as a gate, per the owner ruling.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed) — the CI job is recommended on `ubuntu-latest` only, with the argument given under Member 3 gate 4; the macOS half of the matrix is covered for this procedure by the local `just` recipe and by the ordinary test job.
- `assumes build-tool-output-shape = <R49's published value>` (R49, owner-accepted, **read but not registered as a registry consumption**, per this prompt's `## Couplings`) — the three values read are: the single `[[bin]]` named **`rslbp`**; the package/distribution name `rs-launch-blueprint`; and the `[package] include` allow-list `["/src", "/README.md", "/LICENSE-MIT", "/LICENSE-APACHE", "/CHANGELOG.md"]`, whose completeness AC7 exercises. Also read: that `cargo package` adds a minimized `Cargo.lock` to the archive, which is what makes `--locked` meaningful on the install step.
- `assumes ci-job-structure = —` (R11, unresolved) — the job shape and skip-gate mechanism are R11's; this recommendation is written to be shape-neutral.
- `assumes package-manager-invocation = <R42's published value>` (R42, resolved, read not consumed) — `cargo package`/`cargo install`/`cargo metadata` written as built-in subcommands, `just`/`tar`/`jq` as bare executables on `PATH` with `command -v` presence tests.
- `assumes web-extra-surface = —` **as this run's `inputs/PARAMETERS.md` records it**; the repository's working tree shows R69 resolved, with a second `[[bin]] name = "<app>-serve"` carrying `required-features = ["web"]`. AC6 is written conditionally so it holds either way. See `Method notes`.
- **`CONFLICT:` lines: none.** No consumed or read parameter needs to change for this recommendation to hold.

### Migration implications

File-level changes in the template, all additive:

| File | Change |
|---|---|
| `Justfile` | **+1 recipe.** `install-check`, attributes `[group('build'), group('releases')]`, no alias, a doc comment naming F221/F222 and the binary `rslbp`, body as in `## Validation strategy` below |
| `.github/workflows/ci.yml` | **+1 job.** `install-smoke` on `ubuntu-latest`, gated by R11's code path filter, body `just install-check` |
| `Cargo.toml` | **no change.** No dependency, no `[dev-dependencies]` entry, no build script, no profile |
| `README.md` / contributor docs | one row in the recipe table, if the template ships one |
| `just check-deps` | **no change.** `jq` and `tar` are already required by R26's element 2; `cargo` and `just` by R42 |
| `.gitignore` | **no change.** The recipe's `--target-dir` is `<target_directory>/install-check`, a subdirectory of whatever `cargo metadata` reports as the target directory, which is already ignored |
| R34's `canary.yml` | **no change made here.** Recommended to R34: run the same recipe with `--locked` dropped on the `latest-deps` leg. R34's call, not this item's |

Nothing is removed and nothing existing is edited; no other item's file is touched.

### Validation strategy

**Proposed recipe** — the executable form of AC1–AC5, written to run identically on
`ubuntu-latest` and `macos-latest` and by a developer. It has **not been run**; no Rust
package exists to run it against.

```just
# Build the publishable artifact, install it into a throwaway root, and run it.
# Rust analogue of py's `uvx --from dist/*.whl plbp --version` (F222) and of the
# install half of ts's `pack-check` (F221). Installs the command `rslbp`.
# FEATURES is empty by default; pass `just install-check web` for R69's web leg.
[group('build'), group('releases')]
install-check FEATURES="":
    #!/usr/bin/env sh
    set -eu
    PKG=rs-launch-blueprint
    BIN=rslbp
    META=$(cargo metadata --no-deps --format-version 1)
    VER=$(printf '%s' "$META" | jq -r --arg p "$PKG" '.packages[] | select(.name==$p) | .version')
    TDIR=$(printf '%s' "$META" | jq -r '.target_directory')
    FEAT='{{FEATURES}}'
    echo "[1/4] cargo package $PKG $VER (target dir $TDIR)"
    cargo package -p "$PKG" --locked --no-verify
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' EXIT
    echo "[2/4] extract the .crate outside the workspace -> $TMP"
    tar -xzf "$TDIR/package/$PKG-$VER.crate" -C "$TMP"
    echo "[3/4] install into a throwaway root"
    if [ -n "$FEAT" ]; then set -- --features "$FEAT"; else set -- ; fi
    cargo install --path "$TMP/$PKG-$VER" --root "$TMP/root" \
        --locked --debug --no-track --target-dir "$TDIR/install-check" "$@"
    test -x "$TMP/root/bin/$BIN"
    echo "[4/4] run the installed command"
    OUT=$("$TMP/root/bin/$BIN" --version)
    case "$OUT" in
        *"$VER"*) echo "  $BIN --version = $OUT" ;;
        *) echo "installed $BIN --version ($OUT) does not contain $VER"; exit 1 ;;
    esac
    printf 'install-check passed\n'
```

Notes on five deliberate choices in that text. (1) The `.crate` path and the
`--target-dir` are both derived from `cargo metadata`'s `target_directory` field rather
than from the literal string `target/`, because R49's `build-tool-output-shape` states
that the directory is *"relocatable by `CARGO_TARGET_DIR`, `build.target-dir` or
`--target-dir`"* and the CI job below sets `CARGO_TARGET_DIR`; a hardcoded `target/`
would make the recipe fail in the very job that invokes it. (2) `--no-verify` avoids a
second compile of the same tree the install is about to compile. (3) `--no-track` keeps
Cargo from writing install-tracking state, which is pointless for a root that is deleted
on exit. (4) `--debug` is both the cheaper and the stricter profile for a smoke test
(`debug-assertions`, `overflow-checks`); the release-profile path is already exercised by
R68's release build and R26's publish-time `cargo publish --dry-run`. (5) `test -x
"$TMP/root/bin/$BIN"` is not defensive padding — see AC3's citation: `cargo install`
**exits 0 after installing nothing** when every binary's `required-features` are unmet,
so the exit status alone cannot carry this assertion.

**Web leg (AC6), conditional on R69, proposed:** `just install-check web` — the same
recipe with its `FEATURES` parameter set, which adds `--features web` to the install and
makes the expected count **two** installed binaries, `rslbp` and R69's `<app>-serve`,
against **one** (`rslbp`) with the feature off. The parameter form is deliberate: a
`just` recipe run on a developer's machine cannot know which paths a pull request
touched, so the "only when web sources changed" condition belongs in the workflow as a
**step-level `if`** on a second `run: just install-check web` step, keyed on R11's web
path filter, and never as shell logic inside the recipe. A second `--version` assertion
on `<app>-serve` completes the leg; R69's value states that binary prints `-V/--version`
to stdout and exits 0.

**Negative control (AC7), proposed:** remove a needed entry from `[package] include`,
confirm `install-check` fails at step 3, restore it. Without this, nobody can tell
option C from option B by looking at a green check.

**What this run actually executed**, kept strictly separate from the above:

| # | Check | Result |
|---|---|---|
| 1 | `cargo --version`, `rustc --version` on the host | `cargo 1.98.0 (797e8a9bc 2026-08-05)`, `rustc 1.98.0 (88d9e12ae 2026-08-18)` (Homebrew) |
| 2 | `cargo install --help` | every flag the recipe uses is present; `--dry-run` is marked *unstable* and is therefore not used |
| 3 | `just --version` | `1.57.0` (crates.io latest is 1.58.0) |
| 4 | `curl` the cargo-install reference | the four documented defaults quoted above (profile, target directory, install root, lockfile) |
| 5 | `gh api` the cargo source at `rust-1.98.0` | `verify.rs:62-72` ephemeral workspace, `:94` build-not-run |
| 6 | py `ci.yml` and ts `Justfile` + all eight ts workflows, read **through the pins** | py's `build-smoke` shape; ts's install-and-run steps; no CI reference to `pack-check` |
| 7 | crates.io / GitHub / RustSec figure endpoints | all figures in this report, with the RustSec 404-vs-200 control |
| 8 | GitHub code search for the recommended composition | `total_count: 7`, no well-regarded adopter |
| 9 | `gh api` Cargo's test suite at `rust-1.98.0` for `required-features` under the install verb | `install_default_features` (`:715-797`) pins all three outcomes quoted in AC3, including the status-0-installed-nothing case |
| 10 | `/usr/bin/grep -n 'Justfile\|just ' research/topics/26-packed-artifact-content-guard/DECISION.md` | **no match** — R26 claims no `just` recipe name, so `install-check` collides with nothing |

**Not executed:** any `cargo package`, `cargo install`, `cargo build`, `just` recipe, or
workflow run. No file was created, edited or deleted anywhere except this report.

### Confidence & re-verify trigger

**Overall: medium-high.**

| Claim | Confidence | Why |
|---|---|---|
| The shared principle is B1/B2 at capability + architectural-pattern level, present in **both** sources | **high** | read at both pins, with line numbers; the `BASELINE-REVIEW` correction rests on quoted text |
| py's cadence (gated, path-filtered, one runner) is the right cadence for rs | **high** | two authoritative precedents, one of them a Rust project (uv), plus py's own stated rationale |
| Option C is the right mechanism | **medium-high** | first-party and documented, but with **no well-regarded adopter of this exact composition** (code search, 7 weak hits) |
| The cost is acceptable with `--debug` + cached `--target-dir` + `--no-verify` | **medium** | a cost *model* from documented behaviour plus three projects running compile-heavy packaging checks on PRs; **no timing was measured** |
| `ubuntu-latest` alone suffices | **medium** | an argument about Cargo's OS-independence, not an observation |
| Extracting outside the repository avoids the workspace-root problem | **medium-high** | Cargo's own verification path documents needing an ephemeral workspace for the in-tree case; the CLI failure itself was **not reproduced** |
| The library surface needs no separate consumer check | **medium** | holds while `src/main.rs` depends on the library crate — an explicit, checkable condition |
| AC3's "exit 0 is not enough, assert the file exists" | **high** | Cargo's own test `install_default_features` pins the status-0-installed-nothing outcome verbatim |

**Re-verify triggers.** (1) `cargo install`'s default lockfile handling or its default
target directory changes. (2) `cargo package`'s output path, its default verification,
or `--no-verify` semantics change. (3) R49 moves the binary name `rslbp`, the single
`[[bin]]`, or the `include` allow-list. (4) R11 fixes `ci-job-structure` in a way that
makes a dedicated job unavailable. (5) R69's `<app>-serve` name is resolved to a
literal, or its `required-features` gate changes. (6) R22 or R60 fixes `--version`'s
exact output, at which point the substring assertion should tighten to ts's equality
form. (7) `src/main.rs` stops depending on the library crate — the trigger that makes
the scratch-consumer library check necessary. (8) A macOS-only packaging failure is
observed. (9) R34 accepts or declines the unlocked `latest-deps` leg recommended here.
(10) The ledger's F222 row is corrected or the correction is rejected.

### Sources

Every URL below was retrieved on **2026-09-17 (UTC)**; repository paths without a URL
were read through the programme pins on the same date.

**Authoritative documentation and source**
- `https://doc.rust-lang.org/cargo/commands/cargo-install.html` — installation-root precedence and the "installation root's `bin` folder" rule; *"By default, the `Cargo.lock` file that is included with the package will be ignored"*; *"Defaults to a new temporary folder located in the temporary directory of the platform"*; *"When using `--path`, by default it will use target directory in the workspace of the local crate unless `--target-dir` is specified"*; *"this can be useful for caching build artifacts on continuous integration systems"*; `--debug` = *"Build with the dev profile instead of the release profile"*; *"Only packages which have executable `[[bin]]` or `[[example]]` targets can be installed"*.
- `https://api.github.com/repos/rust-lang/cargo/contents/src/cargo/ops/cargo_package/verify.rs?ref=rust-1.98.0` — `:48-53` extraction path, `:60` unpack, `:62-63` the ephemeral-workspace comment, `:69-72` build-cache reuse, `:94-…` `compile_with_exec(… UserIntent::Build …)`.
- `https://api.github.com/repos/rust-lang/cargo/contents/src/cargo/ops/cargo_package/mod.rs?ref=rust-1.98.0` — `:751` `Workspace::ephemeral` in `build_lock`.
- `https://api.github.com/repos/rust-lang/cargo/contents/src/cargo/core/workspace.rs?ref=rust-1.98.0` — `find_root` at `:832`; the membership errors at `:1104` (*"is a member of the wrong workspace"*) and `:1177` (*"current package believes it's in a workspace when it's not"*).
- `https://api.github.com/repos/rust-lang/cargo/contents/tests/testsuite/required_features.rs?ref=rust-1.98.0` — `install_default_features` at `:715-797`: installs when the feature is on; warns *"none of the package's binaries are available for install using the selected features"* and **exits 0 installing nothing** when it is off and no `--bin` is given; **fails with status 101** when `--bin` names a target whose features are unmet.
- `https://static.rust-lang.org/dist/channel-rust-stable.toml` — stable `1.98.1 (48a229cea 2026-09-01)`.

**Figure endpoints**
- `https://crates.io/api/v1/crates/just`, `/versions`; `.../cargo-binstall`, `/versions`; `.../cargo-local-registry`, `/versions`; `.../dist`, `/versions`; `.../cargo-nextest`, `/versions`.
- `https://api.github.com/repos/casey/just`, `.../cargo-bins/cargo-binstall`, `.../dhovart/cargo-local-registry`, `.../astral-sh/uv`, `.../sharkdp/bat`.
- `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for each of the five repositories above.
- `https://api.github.com/repos/casey/just/issues?state=all&sort=created&direction=desc`, and `/issues/<n>` + `/issues/<n>/comments` for `#3707, 3704, 3703, 3702, 3700, 3699, 3698, 3695, 3694, 3691`.
- `https://rustsec.org/packages/just.html` (404), `.../cargo-binstall.html` (404), `.../time.html` (200, control).
- `https://api.github.com/search/code?q=%22cargo+install+--path+target%2Fpackage%22` — `total_count: 7`.

**Practice evidence (workflow bodies)**
- `https://api.github.com/repos/astral-sh/uv/contents/.github/workflows/check-publish.yml`, `.../ci.yml`, `.../test-smoke.yml`.
- `https://api.github.com/repos/sharkdp/bat/contents/.github/workflows/CICD.yml`.
- `https://api.github.com/repos/casey/just/contents/.github/workflows/ci.yaml`, `.../Cargo.toml`.
- `https://api.github.com/repos/BurntSushi/ripgrep/contents/.github/workflows/ci.yml`, `.../sharkdp/fd/contents/.github/workflows/CICD.yml`, `.../ajeetdsouza/zoxide/contents/.github/workflows/ci.yml`, `.../starship/starship/contents/.github/workflows/workflow.yml`, `.../rust-lang/cargo/contents/.github/workflows/main.yml` — surveyed, results tabulated under `### Landscape`.

**Source repositories, read through the programme pins**
- `git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:.github/workflows/ci.yml` — `:204-223`, the `build-smoke` job.
- `git -C ~/c/py-launch-blueprint show b08bccfb…:Justfile` — alias inventory.
- `git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:Justfile` — `:268-313`, `pack-check`, including the install-and-run steps at `:299-312`; group attributes and alias inventory.
- `git -C ~/c/ts-launch-blueprint show cb1cbcb2…:.github/workflows/<each of eight files>` — grepped for `pack-check`/`pack_check`, no match.

**Programme documents (this repository, working tree)**
- `docs/port/COMMONALITY.md:225-226` (F221, F222), `:180-182` (F176–F178).
- `docs/port/areas/packaging-distribution.md:19-20`; `docs/port/areas/ci-workflows.md:32`; `docs/port/areas/release-versioning.md:24`.
- `docs/port/DIVERGENCE-ANALYSIS.md:180-182`, `:268`.
- `docs/port/PARAMETERS.md` — the four fixed parameters and the `build-tool-output-shape`, `package-manager-invocation`, `web-extra-surface`, `ci-job-structure` rows.
- `research/topics/49-build-target-declaration/DECISION.md` — `## Decision` table rows 1–6, the `rslbp` ruling, the `required-features`/`CARGO_BIN_EXE_<name>` finding.
- `research/topics/26-packed-artifact-content-guard/DECISION.md` — elements 1–4 and their publish-workflow placement.
- `research/topics/20-third-party-action-pinning-policy/DECISION.md` — `## Decision`, the `enforced-owner-prefix-pinning` pattern.
- `research/topics/34-scheduled-freshness-lanes/DECISION.md` — `## Decision`, the `canary.yml` legs.
- `research/topics/42-dev-toolchain-provisioning/DECISION.md` — invocation and presence rules.
- `research/topics/69-web-framework-stack/DECISION.md` and the working tree's `docs/port/PARAMETERS.md` `web-extra-surface` row — the second `[[bin]]` and its `required-features`.

**Method notes.** Endpoints queried: the Cargo Book page for `cargo install`; the Rust
stable channel manifest; the GitHub contents API against `rust-lang/cargo` at tag
`rust-1.98.0` for three source files; `https://crates.io/api/v1/crates/<name>` and
`/versions` for `just`, `cargo-binstall`, `cargo-local-registry`, `dist` and
`cargo-nextest`; `https://api.github.com/repos/<o>/<r>` and
`https://api.github.com/search/issues` for five repositories;
`https://api.github.com/repos/casey/just/issues…` for the ten-issue responsiveness
sample; `https://rustsec.org/packages/<name>.html` for two candidates plus a control;
`https://api.github.com/search/code` twice; the GitHub contents API for
`tests/testsuite/required_features.rs` at `rust-1.98.0`; and the GitHub contents API for
nine workflow files across eight projects. Locally executed, read-only: `cargo --version`,
`rustc --version`, `cargo install --help`, `just --version`, and `git show` against both
source pins. **All figures come from those endpoints; none is recalled or estimated.**

Could **not** verify, listed rather than smoothed over: (1) any timing — no Rust package
exists here and nothing was compiled, so the cost analysis is a model with its levers
named, not a measurement; (2) that `cargo install --path target/package/<pkg>-<ver>`
actually fails inside a workspace — the ephemeral-workspace citation explains why Cargo
avoids that path, and the recommendation sidesteps it by extracting outside the
repository; (3) the literal name of R69's second binary — R69's value carries the
placeholder string `"<app>-serve"`, and whether that resolves to `rslbp-serve` under
R49's `rslbp` ruling is R69/R49's to state; (4) whether any well-regarded project
installs from an extracted `.crate` — the code search found 7 weak hits and no such
adopter, which is reported as an evidence gap rather than papered over; (5) the exact
`--version` output format, which is R22/R60's, hence the substring rather than equality
assertion. One input discrepancy is recorded rather than resolved: this run's
`inputs/PARAMETERS.md` shows `web-extra-surface = —` and `inputs/CLAUDE.md` lists R69 as
`open`, while the repository's working tree shows R69 **resolved** with a published
value; AC6 and the web leg are written conditionally so they hold under either state,
and no input file was modified. Finally, per the owner ruling of 2026-09-12
(`docs/port/OWNER-REVIEW.md`, *"no licence check for anything the template uses (Q4,
superseded and widened by Q7.B)"*), fitness gate 1 is recorded throughout as
`inapplicable — owner ruling 2026-09-12 (Q7.B)` and **nothing was excluded on licence
grounds**; `just`'s `CC0-1.0` and `cargo-binstall`'s `GPL-3.0` are reported as context
only.
