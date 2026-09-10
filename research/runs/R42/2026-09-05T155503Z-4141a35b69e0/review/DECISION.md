# R42 — dev-toolchain-provisioning (bundle, Deep) — DECISION

## Decision

**Status.** This decision is a **proposal to be validated in the implementation
phase against the real template**. P02 is research only: the template does not
exist yet, P03 builds it, and P03's CI is what proves these recommendations. The
recommendation below records what the research found, what it verified, and what
it could not verify; the unverified parts are listed under `## Engines` as what
P03 must validate. A recommendation that does not survive implementation is
**revised against this recorded research**, not researched again from scratch.
No owner acceptance is claimed or implied — the owner has reviewed R01 only.

**Recommendation — one native, origin-routed stack, with no provisioner layer.**

| # | Layer | Decision | Settles |
|---|---|---|---|
| 1 | Rust toolchain and its components | Commit `rust-toolchain.toml` with `profile = "minimal"` and `components = ["rustfmt", "clippy"]`. The `channel` **value** is R27's through F103/F190 and is not set here. No `install-rustfmt`/`install-clippy` recipe is ever written. | — (evidence for F190/F103) |
| 2 | crates.io-published dev tools | One **generic** `install-tool <spec>` recipe over a single declared tool table in the `Justfile`, whose body is `cargo install --locked <name>@<version>`. Not one recipe per tool, and no per-tool shell script. `cargo-binstall` 1.23.0 is the faster prebuilt backend and is **not** the default recommendation — see the licence finding below. | **F183** |
| 3 | Declarative provisioner manifest | **None.** No `mise.toml`, no `.mise.toml`, no `.tool-versions`, no `.flox/env/manifest.toml`, and no `flake.nix`. The declared tool set has exactly one authoritative location, so the manual-sync obligation py records in `mise.toml:1` never exists. | **F187, F188, F189** |
| 4 | Non-crates.io tools (the residue) | Name **`ubi` 0.12.0** (`MIT OR Apache-2.0`) as the single sanctioned backend, reached through a second spec form on the *same* generic recipe, and ship **zero** such tools in the default tool table. Standing rule for consuming items: prefer a crates.io-published tool; a release-only tool must justify itself. | — (reserves the slot for R37/R39/R40) |
| 5 | Invocation surface | The split rule in `## Parameters`: `cargo <sub>` when the executable is `cargo-<sub>`; a bare `<tool>` on `PATH` otherwise; **no wrapper prefix anywhere**. | the owned parameter |

**The licence finding on `cargo-binstall`, stated as a finding and not as a
ruling.** `cargo-binstall`'s newest unyanked version is `1.23.0`, published
`2026-09-05T16:59:01.959145Z`, declaring `license: GPL-3.0-only`
(`GET https://crates.io/api/v1/crates/cargo-binstall/versions`, retrieved
2026-09-10; log `evidence/crates-io.log`). Fitness gate 1 requires compatibility
with the fixed `license = MIT OR Apache-2.0`, and `docs/port/PARAMETERS.md`
words that gate as "candidate crates must be compatible". Under the plain
reading `cargo-binstall` **fails gate 1** and is excluded, which is codex's
position. `raw/opus.md` argues it should pass because the tool is executed as a
separate process and never linked into the template's artifact, citing the FSF's
mere-aggregation position (`https://www.gnu.org/licenses/gpl-faq.html#MereAggregation`,
retrieved 2026-09-05). **That argument is recorded, not adopted:** whether gate 1
covers separate-process developer tools is an owner ruling, and no owner ruling
exists. This decision therefore recommends the backend that is clean under
either reading — first-party `cargo install --locked`, `Apache-2.0 OR MIT`,
already present on every contributor machine — and pays for it in compile time
rather than in an unresolved licence question. The stack degrades gracefully
because only the recipe *body* changes: if the owner rules that gate 1 does not
reach separate-process tools, substituting `cargo binstall --locked --no-confirm`
edits one line and no invocation line anywhere. `cargo-quickinstall` 0.3.53
(`MIT OR Apache-2.0`, retrieved 2026-09-10) is the licence-clean prebuilt
alternative if compile time proves unacceptable.

**Ledger rows settled** (verdict strings remain the controller's to set, per
`docs/port/README.md`): **F183** — decided, one generic recipe replaces py's
`install-taplo`/`install-gitleaks`/`install-actionlint`/`install-yamlfmt`
(py `Justfile:159`, `:476`, `:482`, `:713`) and both of py's per-tool shell
scripts, which have no Rust analogue; **F187** — not adopted; **F188** — not
adopted; **F189** — not adopted, so the three-provisioner sync obligation never
comes into existence.

BASELINE-REVIEW: F181 — capability: one command reports the full dev-tool
inventory with a per-tool remediation string — **retain `just check-deps` as a
distinct Level-2 check; do not collapse it into F180, and keep `command -v` as
the presence test** — evidence: the two checks have disjoint scopes even after
the installer layer shrinks (F180 tests a machine that may have no Rust
toolchain at all; F181 tests crates.io tools and may assume `cargo` exists), and
`command -v` is provably the correct test for both tool classes because Cargo
dispatches `cargo <sub>` to a `cargo-<sub>` executable found on `PATH` — a stub
`cargo-demo` on `PATH` invoked as `cargo demo --flag 1` printed
`cargo-demo invoked argv: demo --flag 1` and exited 0 on this host, and
`command -v cargo-demo` resolved it (log `evidence/invocation-mechanism.log`).
What changes is F181's *implementation*, not its existence: py's per-tool
`if`-blocks become one loop over the declared tool table. Affected: F181, F180.

BASELINE-REVIEW: F179 — a base-toolchain bootstrap layer precedes project
dev tasks and uses only what a bare machine already has — **retain the two-layer
split, but record `make` as a deliberate cross-repository consistency choice
carrying a measured ecosystem cost, and drop any claim that it is the ecosystem's
natural entry point** — evidence: a root-file survey of 17 widely adopted Rust
repositories re-measured for this decision found **0 of 17** carrying a root
`Makefile`, against 9 of 17 carrying `rust-toolchain.toml`, 5 carrying
`flake.nix` and 4 carrying a `justfile`
(`GET https://api.github.com/repos/<o>/<r>/contents/`, retrieved 2026-09-10; log
`evidence/repo-survey.log`). Affected: F179 Notes, F180, and R37's lefthook
bootstrap, which lands in whichever layer the owner keeps.

**Coordination note, not a `CONFLICT:`** — layer 1 recommends `profile` and
`components` for `rust-toolchain.toml` and supplies R27 with measured `channel`
evidence (8 of the 9 surveyed repositories pin an exact version, 1 uses
`channel = "stable"`), but the `channel` value belongs to **R27 through
F103/F190** and is not set here. R42 consumes no parameter, so no registered
value needs to change.

### Principles and implementation

**Shared requirement, its source, and the level of agreement.** Both source
repositories implement one principle: *a contributor runs one command, learns
exactly which development tools are missing, receives the exact command that
installs each one, and every repeatable task then invokes those tools by a
single stable name that does not depend on how they were installed.* py realises
it with `check-deps` plus per-tool installer recipes and two extra declarative
manifests kept in manual sync (py `Justfile:94`, `:159`, `:476`, `:482`, `:713`,
`mise.toml:1`, `mise.toml:23`, `.flox/env/manifest.toml:14`); ts realises the
same principle by deleting most of the tools — Oxfmt absorbs taplo and yamlfmt
per D-014(6) and D-014(7) — and demoting the remainder to advisory
(ts `Justfile:83`). Source-repository line references are quoted **as recorded in
this run's `inputs/prompt.md` `## Context`**; neither source repository was
checked out for this decision. The agreement level is **architectural pattern
plus policy** — a discover-report-remediate loop and a stable invocation
vocabulary — not a capability and not a specific tool.

**What must agree, and what may vary.** Must agree: one presence-check command;
one remediation string per missing tool; one invocation form per tool class; and
exactly one authoritative location for the declared tool set. May vary: the
acquisition backend, the number of tools, which tools are chosen (R27–R29, R32,
R37, R39, R40 each own their own pick), and whether the residue slot ever
acquires an occupant.

**Essential behaviors.** (1) A contributor with a bare machine reaches a working
environment through a documented, finite sequence. (2) Exactly one command
reports the tool inventory as pass/fail with a per-tool remediation command.
(3) Every `Justfile` recipe and every lefthook job names a tool identically
regardless of which backend installed it. (4) Two locations that must be
hand-synchronised are a defect, not a feature.

**Observable acceptance criteria** (proposed for P03; none of these was run
here, because running them means building the template):
(A) `just check-deps` exits non-zero and prints one `MISSING <tool> -> RUN <command>`
line per absent tool, and exits zero when all are present.
(B) In a fresh clone, `cargo fmt --version` and `cargo clippy --version` succeed
after `rustup` alone, with no installer recipe run.
(C) `rustup show active-toolchain` names the committed `rust-toolchain.toml` as
the override source, on both `ubuntu-latest` and `macos-latest`.
(D) Adding a tool to the template edits exactly one list.
(E) No recipe or hook line contains a provisioner prefix (`mise exec`,
`cargo bin`, `nix develop -c`, `flox activate`, or any `uv run` analogue), and
`mise.toml`, `.mise.toml`, `.tool-versions` and `.flox/` are absent.

**Architecture alternatives compared, before any tool was chosen.**

| Architecture | What it is | Why it was or was not chosen |
|---|---|---|
| **Toolchain file + package-manager acquisition** (selected) | `rust-toolchain.toml` supplies the compiler-adjacent tools; crates.io supplies the rest through one generic recipe; tools are invoked by name | Matches the re-measured field (9/17 carry the toolchain file, 0/17 carry a provisioner manifest); collapses py's five installer recipes and two shell scripts into one recipe; preserves the single-authoritative-list principle |
| **Polyglot version manager** (`mise`, `asdf`) | one manifest pins tool versions across languages | The problem it solves is a Python + Node + CLI mix — py's problem, not this template's. Measured adoption in the surveyed Rust field is **0 of 17**. Adopted *alongside* native installs it reproduces F189's unenforced sync obligation; adopted *instead of* them it forces `mise exec --` into every recipe and hook line, breaking essential behavior (3) |
| **Hermetic environment** (Nix flake, `flox`, `devenv`, `devbox`) | one manifest describes compiler, tools and system libraries; a shell command enters the environment | Strongest reproducibility and the only declarative option with real Rust-field adoption (5/17 carry `flake.nix`). Rejected for a **template**: it imposes a Nix installation on every downstream consumer and puts an environment prefix on every recipe and hook line. `flox` additionally is not published on crates.io at all and is GPL-2.0 (`GET https://api.github.com/repos/flox/flox`, `license.spdx_id`, retrieved 2026-09-10) |
| **Per-tool installer recipes with pinned URL + SHA-256** (codex's shape) | one recipe per external tool owning its version, URL, checksum and OS artifact mapping | The right **provenance** boundary, and retained inside the generic recipe as the pinned `name@version` spec. Rejected as a *per-tool* structure: it reproduces exactly the maintenance surface F183 exists to remove, for a residue this decision measures as empty by default |
| **In-repo Rust automation** (`xtask/`, `cargo-make`) | provisioning and tasks are compiled Rust in the repo | Real (2/17 use `xtask`), and the parameter survives it intact, so it is the ranked runner-up for the *task surface*. Not selected: it adds a build step before any check can run on a cold clone, and it does not itself acquire foreign binaries. `cargo-make` is separately **at-risk** (last release 0.37.24, 2025-01-18; retrieved 2026-09-10) |

**Why the shared pattern survives in Rust for the loop and dies for the per-tool
layer.** The reason is structural, not stylistic. py's tools (`taplo`,
`gitleaks`, `actionlint`, `yamlfmt`) sat outside `uv`'s reach because `uv`
installs Python distributions, so each needed bespoke acquisition. The Rust
equivalents are themselves crates — `taplo-cli`, `typos-cli`, `cargo-nextest` —
so the primary package manager *does* reach them, and rustup reaches `rustfmt`
and `clippy` by definition. The per-tool layer exists in py because of a gap
Rust largely does not have.

**Answers to the prompt's five questions.**

- **HIGH — does rustup plus cargo remove the per-tool installer layer (F183)?**
  It removes the *per-tool* part, not the layer. Partially verified here: with a
  `rust-toolchain.toml` present, `cargo fmt --version` returned `rustfmt 1.9.0`
  and `cargo clippy --version` returned `clippy 0.1.98` with **no installer
  step**, and the toolchain that file selects does carry both components —
  `rustup component list --installed` lists `rustfmt-aarch64-apple-darwin` and
  `clippy-aarch64-apple-darwin`, and `rustup which cargo-fmt` resolves inside
  `~/.rustup/toolchains/stable-aarch64-apple-darwin/bin/`. What this host does
  **not** prove is that the `cargo fmt` invocation *routed through* that rustup
  proxy, because a Homebrew Rust installation shadows it on `PATH` — see the
  hazard note in `## Empirical check` and unproven item 2 (log
  `evidence/invocation-mechanism.log`). What remains is one generic
  install-if-missing recipe over a declared tool table.
- **HIGH — is a declarative provisioner common practice (F187/F188)?** No.
  **0 of 17** surveyed repositories carry `mise.toml`, `.mise.toml`,
  `.tool-versions` or `.flox`; **5** carry `flake.nix`
  (log `evidence/repo-survey.log`, retrieved 2026-09-10). Any declarative-provisioner
  argument in the Rust field has to be made against `flake.nix`, not `mise.toml`.
- **MEDIUM — one manifest or two, if a provisioner is adopted (F189)?**
  Neither. If the owner later wants a hermetic option it should be exactly one
  file and it should be `flake.nix`, on the 5-versus-0 adoption evidence, added
  as an optional convenience that no recipe depends on.
- **MEDIUM — the idiomatic `package-manager-invocation` answer?** Both forms,
  split by a mechanical rule stated in `## Parameters`. This is not a compromise:
  it is what Cargo's custom-subcommand dispatch makes true, verified directly
  here, and it is what all four surveyed `justfile`s do — zero wrapper-prefix
  lines across `oxc`, `biome`, `just` and `cargo-binstall`
  (log `evidence/reference-impls.log`).
- **LOW — one script per tool, or one generic recipe?** One generic recipe. The
  two maintained reference implementations that provision tools at all both write
  a single bootstrap recipe listing every tool and **no** per-tool recipe:
  `oxc-project/oxc` `init` is one `cargo binstall watchexec-cli cargo-insta
  typos-cli cargo-shear@1.13.1 -y` line, and `biomejs/biome` `install-tools` is
  `cargo install cargo-binstall` then two `cargo binstall` lines
  (log `evidence/reference-impls.log`, retrieved 2026-09-10).

**Reference implementations.** `cargo-bins/cargo-binstall` commits literally the
`rust-toolchain.toml` layer 1 recommends — `channel = "stable"`,
`profile = "minimal"`, `components = ["rustfmt", "clippy"]` — and invokes
everything by the split rule. `zed-industries/zed` uses the same
minimal-plus-explicit-components shape at `channel = "1.97.1"`.
`oxc-project/oxc` (22694 stars) and `biomejs/biome` (25753 stars) each combine a
committed toolchain file, one generic tool-acquisition recipe, no provisioner
manifest, and split-rule invocation — four of this decision's five layers, twice
over, independently. All read 2026-09-10; `evidence/reference-impls.log`.
The gap: **no maintained project was found that composes all five layers
including the residue backend**, because layer 4 has zero occupants by default.

**Minimal realistic example, as a description and not as built code.** A fresh
clone contains `rust-toolchain.toml` (channel per R27, `profile = "minimal"`,
`components = ["rustfmt", "clippy"]`), a `Justfile` holding one tool-table
variable, one `check-deps` recipe and one `install-tool` recipe, and a
`lefthook.yml` whose jobs name tools by the parameter's rule. A contributor runs
the Level-1 bootstrap, then `just check-deps`, then the printed
`just install-tool <spec>` lines, then `just check-deps` again to green. Nothing
is hand-synchronised, because the tool table is the only list. **This example
was not built.** Building it is P03's job and is what the acceptance criteria
above are written to test.

**Earlier re-verify events**, any of which fires before the date below: R27
settles F103 with a `channel` or `profile` that conflicts with
`components = ["rustfmt", "clippy"]`; R37, R39 or R40 selects a tool not
published on crates.io, which activates layer 4 for the first time; the owner
rules on whether fitness gate 1 reaches separate-process developer tools;
`cargo-binstall` relicenses; a RustSec advisory appears for `ubi` or `just`; or a
repeat of the 17-repository survey finds provisioner manifests in a material
fraction of well-regarded Rust repositories.

re-verify: 2027-03-10, or any earlier event listed immediately above

## Parameters

- owns package-manager-invocation = `cargo <sub>` for any tool whose executable is named `cargo-<sub>` — including the rustup components rustfmt and clippy, invoked as `cargo fmt` and `cargo clippy`; a bare `<tool>` binary resolved on `PATH` for every other tool; **no provisioner, runner or package-manager prefix** (`mise exec`, `cargo bin`, `nix develop -c`, `flox activate`, or any `uv run` analogue) in any Justfile recipe or lefthook job; presence tested with `command -v <executable>`, where the executable is `cargo-<sub>` for the first class and `<tool>` for the second.
- assumes msrv-policy = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed, `docs/port/PARAMETERS.md`). Used here only to establish what it does **not** govern: dev tools are not built by the MSRV floor job, so a candidate's `rust_version` is measured against the development channel instead.
- assumes rust-edition = `2024` (fixed, `docs/port/PARAMETERS.md`).
- assumes target-os-matrix = `ubuntu-latest, macos-latest` (fixed, `docs/port/PARAMETERS.md`). Every recommended component runs on both; Windows support is noted where it exists and is not required.
- assumes license = `MIT OR Apache-2.0` (fixed, `docs/port/PARAMETERS.md`). Gate 1 is applied to every candidate; the `cargo-binstall` finding is recorded in `## Decision` as a finding, with the owner ruling listed as unproven.
- No `CONFLICT:` line. R42's `- consumes:` list is empty, no raw report raised a conflict, and nothing in this recommendation requires a registered parameter value to change.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `rustup 1.29.1 (d95a37b6a 2026-08-13)`;
`Darwin 25.4.0 arm64`, macOS 26.4 (25E246). Recorded 2026-09-10T05:14:53Z;
log `review/evidence/toolchain.log`. **All retrieval timestamps in this decision
and in every evidence log are UTC**; the local date of the run is 2026-09-09
(America/Los_Angeles), so a UTC stamp of `2026-09-10T05:xxZ` is not a future date.

**Working directory.** Read-only network queries ran from the run directory
`research/runs/R42/2026-09-05T155503Z-4141a35b69e0`. The two commands that need
files on disk ran in the session scratchpad
(`…/scratchpad/r42`), **outside the repository**: one four-line
`rust-toolchain.toml` and one three-line stub executable named `cargo-demo`.
Nothing was installed, and nothing outside `review/` was modified.

**Nothing recommended was implemented.** No template, workspace, `Justfile`,
`check-deps` recipe, `install-tool` recipe, `lefthook.yml` or acceptance script
was written. Every check below either queries a recorded endpoint, reads a
maintained project's committed file, or exercises a documented Cargo/rustup
mechanism against a stub input.

| # | Check | Command | Exit | Result | Log |
|---|---|---|---:|---|---|
| 1 | Toolchain and OS | `rustc --version`; `cargo --version`; `rustup --version`; `uname -a`; `sw_vers` | 0 | recorded above | `evidence/toolchain.log` |
| 2 | Provisioner-manifest practice, re-measured | `gh api repos/<o>/<r>/contents/` over 17 repositories | 0 | **0/17** `mise.toml`, `.mise.toml`, `.tool-versions`, `.flox`; **5/17** `flake.nix`; **9/17** `rust-toolchain.toml`; **4/17** `justfile`; **0/17** root `Makefile` | `evidence/repo-survey.log` |
| 3 | Cargo custom-subcommand dispatch | stub `cargo-demo` on `PATH`, then `cargo demo --flag 1`; `command -v cargo-demo`; negative control off `PATH` | 0 / 0 / 1 | printed `cargo-demo invoked argv: demo --flag 1`; `command -v` resolved it; resolved nothing off `PATH` | `evidence/invocation-mechanism.log` |
| 4 | Toolchain-file override + component availability | `rustup show active-toolchain`; `cargo fmt --version`; `cargo clippy --version`; `rustup which cargo-fmt`; `rustup component list --installed` | 0 | `stable-aarch64-apple-darwin (overridden by '<scratch>/rust-toolchain.toml')`; `rustfmt 1.9.0`; `clippy 0.1.98`, no installer step; the selected toolchain carries both components. **Caveat:** whether the `cargo fmt` call routed through the rustup proxy is **unproven on this host** — see the hazard note below and unproven item 2 | `evidence/invocation-mechanism.log` |
| 5 | crates.io figures and licences | `GET https://crates.io/api/v1/crates/<name>` and `/versions` for 7 crates | 0 | table below | `evidence/crates-io.log` |
| 6 | GitHub figures and open issues | `gh api repos/<o>/<r>`; `gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"` for 8 repositories | 0 | table below | `evidence/github-rustsec.log` |
| 7 | RustSec advisories, with HTTP-200 controls | `curl -s -o /dev/null -w '%{http_code}' https://rustsec.org/packages/<name>.html` | 0 | 404 for `cargo-binstall`, `ubi`, `mise`, `just`, `cargo-run-bin`; 200 for the `time` and `atty` controls, so 404 means "no advisory page", not a transport failure | `evidence/github-rustsec.log` |
| 8 | Reference implementations | `curl https://raw.githubusercontent.com/<repo>/HEAD/{rust-toolchain.toml,justfile}` for 4 repositories | 0 | `cargo-binstall` commits `channel="stable"`, `profile="minimal"`, `components=["rustfmt","clippy"]`; `oxc` and `biome` each use one generic tool-acquisition recipe; **0** wrapper-prefix lines across all four `justfile`s | `evidence/reference-impls.log` |

**Figures, all retrieved 2026-09-10** (endpoints per the prompt's evidence table;
open issues from `search/issues` `total_count`, never `open_issues_count`):

| Candidate | 90-day / all-time downloads | Newest unyanked | Licence (crates.io) | `rust_version` | Stars | `archived` | `pushed_at` | Open issues | RustSec |
|---|---|---|---|---|---:|---|---|---:|---|
| `cargo install --locked` | inapplicable — part of Cargo, not a separate crate | ships with the toolchain | Apache-2.0 OR MIT | n/a | n/a | n/a | n/a | n/a | inapplicable |
| `cargo-binstall` | 125152 / 3482994 | 1.23.0, 2026-09-05T16:59:01Z | **GPL-3.0-only** | 1.79.0 | 2864 | false | 2026-09-10T01:22:53Z | 93 | none (404) |
| `cargo-quickinstall` | 7802 / 501029 | 0.3.53, 2026-07-12T05:43:44Z | MIT OR Apache-2.0 | none declared | — | — | — | — | not queried |
| `ubi` | 83205 / 304322 | 0.12.0, 2026-08-31T03:45:16Z | MIT OR Apache-2.0 | 1.88 | 595 | false | 2026-09-07T21:12:11Z | 11 | none (404) |
| `mise` | 9199 / 443403 | 2026.9.4, 2026-09-09T19:23:59Z | MIT | 1.95 | 33724 | false | 2026-09-10T00:53:53Z | 26 | none (404) |
| `flox` | **not on crates.io** — the endpoint returns the error detail "crate `flox` does not exist" | inapplicable | GPL-2.0 (GitHub `license.spdx_id`) | inapplicable | 4123 | false | 2026-09-09T21:20:03Z | 380 | inapplicable |
| `just` | 511896 / 2540667 | 1.58.0, 2026-08-03T20:29:15Z | CC0-1.0 | 1.89.0 | 35716 | false | 2026-09-01T20:47:57Z | 171 | none (404) |
| `cargo-run-bin` | 82261 / 293046 | 1.7.5, **2025-07-14T14:31:29Z** | MIT | 1.70.0 | 237 | false | **2025-12-19T02:30:12Z** | 7 | none (404) |
| `cargo-make` | 246864 / 3670537 | 0.37.24, **2025-01-18T15:20:30Z** | Apache-2.0 | none declared | — | — | — | — | not queried |
| `rustup` | inapplicable — distributed via `rustup-init`, not crates.io | n/a | Apache-2.0 OR MIT | n/a | 7034 | false | 2026-09-09T14:33:39Z | 392 | none (404) |
| `taiki-e/install-action` | inapplicable — a GitHub Action, not a crate | n/a | Apache-2.0 | n/a | 537 | false | 2026-09-09T11:24:03Z | 15 | inapplicable |

**Maintenance state by the prompt's rubric.** `cargo-binstall`, `ubi`, `mise`,
`flox`, `just`, `rustup`, `taiki-e/install-action`: **active** (all pushed within
four days of retrieval). `cargo-run-bin`: **at-risk** on concrete signals rather
than the six-month trigger alone — last release 2025-07-14 (about 14 months
before retrieval) and last push 2025-12-19 (about 9 months). `cargo-make`:
**at-risk** — last release 2025-01-18 (about 20 months). Issue responsiveness
medians were **not measured in this decision**; they are carried from
`raw/opus.md` where cited and are listed as unproven where that report itself
recorded them as unmeasurable.

**Fitness gates, answered for the recommended stack.** Every candidate here is a
developer tool executed as a **separate process**, linked into nothing, and the
gates are answered in that light rather than silently skipped. Gate 1 (licence):
`cargo install --locked` is `Apache-2.0 OR MIT`, `ubi` is `MIT OR Apache-2.0`,
`just` is `CC0-1.0` — all clean under any reading; `cargo-binstall` is
`GPL-3.0-only` and is handled in `## Decision`. Gate 2 (MSRV): **inapplicable**
for a prebuilt install, because nothing is compiled on the contributor's machine;
for a source install the binding floor is the *development* channel from
`rust-toolchain.toml`, not `msrv-policy`, which governs `rust-version` and the CI
floor job only. Gate 3: no RustSec page for any candidate, verified against
HTTP-200 controls; `unsafe` posture **not audited and not asserted** — a separate
process cannot reach the template's address space, and the residual risk is
supply-chain, which the pinned `name@version` spec and `--locked` narrow but do
not eliminate. Gate 4 (OS): `ubuntu-latest` and `macos-latest` are covered by
rustup, Cargo and `ubi`; **verified on macOS/arm64 only in this decision** —
Linux is unproven here and listed below. Gate 5 (default features, async
coupling): **inapplicable** — nothing is linked, so no feature unification or
coupling with R05's execution model can occur. Gate 6 (binary size, compile
time): **zero on both for the template's artifact**, since no dependency is
added; for the contributor, `cargo install --locked` costs one source compile per
tool, which is the price paid for the licence-clean backend.

**An observed hazard, recorded because it is evidence for the split rule.** On
this host `command -v cargo` resolves to `/opt/homebrew/bin/cargo`, and
`cargo-fmt`/`cargo-clippy` likewise resolve to Homebrew builds rather than to
rustup's proxies, while `rustup which rustc` points into
`~/.rustup/toolchains/stable-aarch64-apple-darwin/bin/rustc`. The dispatch and
component checks therefore prove that `cargo fmt`/`cargo clippy` resolve with no
installer step, and that `rustup show active-toolchain` honours the committed
file — but they do **not** prove, on this host, that `cargo fmt` reaches the
toolchain-file-selected rustfmt *through the rustup proxy*, because a second
Rust installation shadows it on `PATH`. That is exactly the drift a bare-binary
`PATH` lookup can hide, and it is the strongest single argument for the
`cargo <sub>` half of the owned parameter. Proving proxy resolution needs a clean
runner; it is listed below as P03's.

## Engines

- **codex** `raw/codex.md` (gpt-5.6-terra, figures retrieved 2026-09-05) — native origin-routed stack; no mise, no flox; conditional **per-tool** installer recipes with pinned URL and SHA-256 for any later-selected external tool; excludes `cargo-binstall` on the plain gate-1 reading.
- **opus** `raw/opus.md` (claude-opus-5[1m], retrieved 2026-09-05) — same no-provisioner conclusion reached from a 17-repository measurement; **one generic** recipe rather than per-tool recipes; `cargo-binstall` admitted under a mere-aggregation reading with a licence-clean fallback stack named; `ubi` reserved for the residue; the split invocation rule.
- **doxa/openai** `raw/doxa-openai.normalized.md` (gpt-5.6-sol, retrieved 2026-09-09) — adopt `mise` 2026.9.3 plus a committed `mise.lock`; external tools invoked as `mise --locked exec -- <tool>`; lefthook delegates to `just`.
- **doxa/gemini** `raw/doxa-gemini.normalized.md` (deep-research-preview-04-2026, retrieved 2026-09-09) — adopt `mise` + `cargo-run-bin` + `just`; invocation `mise exec <tool>` and `cargo bin <tool>`.
- **doxa/perplexity** `raw/doxa-perplexity.normalized.md` (sonar-deep-research, retrieved 2026-09-09) — adopt rustup/Cargo **and** `cargo-binstall` **and** a single `mise.toml`, but invoke first-party tools as cargo subcommands and everything else as bare binaries on `PATH`.

**Disagreements, and the evidence that settled each.**

1. **Adopt a declarative provisioner manifest, or not?** codex and opus say no;
   all three Doxa engines say yes (`mise`). Settled **against** the provisioner
   by re-measurement rather than by counting engines: a fresh root-file survey of
   17 widely adopted Rust repositories run for this decision found **0 of 17**
   carrying `mise.toml`, `.mise.toml`, `.tool-versions` or `.flox`, and 5 of 17
   carrying `flake.nix` (`evidence/repo-survey.log`, 2026-09-10) — reproducing
   opus's independent 2026-09-05 measurement exactly. The pro-mise reports'
   practice evidence does not survive contact with that measurement: gemini
   asserts that `uv`, `dioxus` and `leptos` "heavily leverage" these tools, but
   `astral-sh/uv`'s repository root carries no `mise.toml`, no `.mise.toml` and
   no `.tool-versions`; perplexity's strongest adoption example is a **polyglot**
   project (Rust + Python + Kubernetes tooling), which is py's problem shape, not
   this template's. The honest counterweight is openai's own concession, quoted:
   *"a declarative polyglot provisioner is not a universal Rust-community
   convention… A single external-tool manifest is therefore justified by this
   template's fit, not by claiming ecosystem-wide dominance."* That is a
   fit argument, and the fit fails here for a stated reason: a Rust-only template
   has nothing for the manifest to declare that `rust-toolchain.toml` and the
   Justfile tool table do not already declare.
2. **Does the invocation line carry a wrapper prefix?** openai wants
   `mise --locked exec -- <tool>`; gemini wants `mise exec <tool>` **and**
   `cargo bin <tool>`; codex, opus and perplexity all want bare binaries and
   cargo subcommands with no prefix. Settled against the prefix by mechanism and
   by practice: Cargo's `cargo <sub>` → `cargo-<sub>` `PATH` dispatch was
   exercised directly here, and all four surveyed `justfile`s contain **zero**
   wrapper-prefix lines (`evidence/reference-impls.log`). A prefix would also
   propagate into six consumer items' recipes and hooks.
3. **`cargo-run-bin` (gemini's second pillar).** gemini rates its own stack
   "Extremely High" confidence without assessing that crate's maintenance.
   Verified independently: newest unyanked `1.7.5`, published **2025-07-14**, last
   push **2025-12-19** (`evidence/crates-io.log`, `evidence/github-rustsec.log`,
   2026-09-10) — **at-risk** on concrete signals, and its `cargo bin <tool>`
   prefix is the form disagreement (2) already rejects.
4. **`cargo-binstall`'s licence.** codex excludes it on gate 1; opus admits it
   under mere aggregation; perplexity and gemini split (perplexity adopts it,
   gemini excludes it on the same GPL ground codex uses). Verified: `1.23.0`,
   `GPL-3.0-only` (2026-09-10). **Not settled by evidence, because it is not an
   evidentiary question** — it is a reading of a fixed parameter, and only the
   owner can rule. This decision recommends the backend that is clean either way
   and records the ruling as needed.
5. **Per-tool recipes versus one generic recipe (F183's shape).** codex keeps one
   recipe per external tool; opus and every Doxa engine collapse to one. Settled
   for the generic recipe by the two maintained reference implementations that
   provision tools at all — `oxc`'s `init` and `biome`'s `install-tools` are each
   a single bootstrap recipe listing every tool, with no per-tool recipe
   (`evidence/reference-impls.log`, 2026-09-10). codex's provenance concern is
   preserved inside the generic recipe as the pinned `name@version` spec.

**Perplexity's incomplete body, and what is genuinely unsupported.** As the
normalization log records (`doxa/normalization.json`), the perplexity body lacks
four top-level fields: `Parameters`, `Migration implications`,
`Validation strategy`, and `Confidence & re-verify trigger`. Its owned-parameter
value is nonetheless recoverable verbatim from its `### Recommendation` prose
("first-party Rust tools via cargo subcommands; all non-cargo dev tools via
provisioned binaries on PATH; installation via rustup components, cargo-binstall,
and mise according to `mise.toml`"), and it is weighed above on that basis. Its
migration file list, validation commands and confidence rating are **absent**,
so perplexity contributes no evidence on those three questions and is not counted
as agreement on them. One of its figures also fails verification: it reports
`mise` as declaring `rust-version` **1.85**, where the registry returns **1.95**
for the newest unyanked version `2026.9.4` (`evidence/crates-io.log`,
retrieved 2026-09-10). Separately, **gemini's report does not meet the prompt's
evidence rule**: it cites with bare `[cite: N]` markers carrying no URLs and no
retrieval dates, and it emits two conflicting `owns package-manager-invocation`
lines. Its conclusions are weighed as assertions, not as sourced evidence.
Neither report's contribution to the recommendation is load-bearing: every claim
this decision relies on is independently verified above or carried from codex or
opus with a cited endpoint and retrieval date.

**Unproven — what P03 must validate against the real template.** Each item names
what would prove it.

1. **Linux.** Every command in `## Empirical check` ran on macOS 26.4 / arm64
   only. Proof: run checks 3, 4 and 8's equivalents on `ubuntu-latest`.
2. **Component resolution through the rustup proxy.** This host's `cargo`,
   `cargo-fmt` and `cargo-clippy` are Homebrew builds shadowing rustup's proxies,
   so `cargo fmt` reaching the *toolchain-file-selected* rustfmt is unproven here.
   Proof: on a clean runner with no second Rust installation, assert
   `command -v cargo` equals `rustup which cargo` and that `cargo clippy --version`
   changes when the committed `channel` changes.
3. **The whole loop.** `just check-deps` printing one
   `MISSING <tool> -> RUN <command>` line per absent tool and exiting non-zero,
   then zero after `just install-tool` — acceptance criteria (A) and (D). Not run
   here, because running it means writing the `Justfile` this decision only
   recommends. Proof: build the template and run it in CI on both runners.
4. **The acquisition backend end to end.** `cargo install --locked <name>@<version>`
   installing a real tool and `command -v <tool>` finding it. Not run: it writes
   binaries into the owner's `~/.cargo/bin`. Proof: run it on a CI runner.
5. **Compile-time cost of the licence-clean backend.** The decision trades
   `cargo-binstall`'s prebuilt download for a source build and asserts the cost
   qualitatively only. Proof: time a cold `cargo install --locked` of the actually
   selected tool set on both runners, and compare against `cargo binstall`, with
   the tool set, versions and runner class stated.
6. **Layer 4 (`ubi`) has never been exercised.** It has zero occupants by default
   and no maintained project was found composing it with the other four layers.
   Note the evidence *against* it that `raw/opus.md` surfaced and this decision
   repeats rather than suppresses: `ubi`'s own maintainer writes that for
   per-project tooling he "strongly recommend[s] using mise instead of ubi",
   endorsing it only for global installs — which is the narrow role assigned here.
   Proof: when R37, R39 or R40 selects a non-crates.io tool, install it with
   `ubi --project <owner>/<repo> --in ./bin` on both runners.
7. **The owner's reading of fitness gate 1** for separate-process developer
   tools, which decides whether `cargo-binstall` is available as the backend.
   Not researchable — an owner ruling. Proof: the owner rules.
8. **The `rust-toolchain.toml` `channel` value** is R27's through F103/F190; only
   `profile` and `components` are recommended here. Proof: R27's decision, then a
   CI run confirming the two components are present on that channel.
9. **The prohibition is unenforced.** Acceptance criterion (E) — no wrapper
   prefix, no provisioner manifest — is a proposed standing guard, a natural fit
   for the drift check R15 owns. No such guard was written. Proof: P03 implements
   and runs it.
10. **Issue-responsiveness medians** for every candidate were not measured in this
    decision; `raw/opus.md` additionally records `jdx/mise` and `flox/flox` as
    unmeasurable by the prescribed method. Proof: sample the 10 most recently
    opened issues per repository at re-verify time.
