# R42 — dev-toolchain provisioning (bundle) — raw report

Engine: Claude Opus. Actor: `research-opus-2026-09-05T155503Z-4141a35b69e0`.
Model ID quoted from this engine's own system prompt: `claude-opus-5[1m]`.
Retrieval date for every figure and claim below: **2026-09-05** (local clock,
America/Los_Angeles). GitHub and crates.io return UTC timestamps, so a few
`pushed_at` and `created_at` values below read `2026-09-06` while still being
the value returned on the 2026-09-05 retrieval.

### Landscape

**Category this item decides.** Not "which dev tool", but *tool acquisition and
tool invocation*: (a) how a non-`cargo`-native developer tool arrives on a
contributor's machine, and (b) what literal command a Justfile recipe or a
lefthook job writes to run it. The category has four moving parts — the Rust
toolchain itself, cargo-published tool binaries, non-cargo tool binaries, and
the optional declarative manifest that would describe all three — plus the
invocation surface that consumes them. The five bundle members below are those
five parts.

**Three-bin map of the Rust field.**

| Bin | Candidates found | What each provisions |
|---|---|---|
| Built-in / first-party | `rustup` + `rust-toolchain.toml` (channel, `profile`, `components`, `targets`); `cargo install` / `cargo install --locked`; `cargo` custom-subcommand dispatch (`cargo-<name>` on `PATH`) | the compiler, `rustfmt`, `clippy`, `rust-src`, `rust-analyzer`, cross targets; any crates.io-published tool, built from source |
| Established industry standard | `cargo-binstall`; `just` as the recipe surface; `taiki-e/install-action` on the CI side; Nix flakes (`flake.nix`) for whole-environment provisioning | prebuilt tool binaries without a compile; the recipe/hook invocation surface; CI-side tool acquisition; a hermetic environment including non-Rust tools |
| Up-and-comer | `cargo-quickinstall` (binstall's own third strategy, also usable standalone); `ubi` (universal GitHub/GitLab-release binary installer, written in Rust); `mise` (polyglot per-project tool manager); `flox` (Nix frontend with a `manifest.toml`); `devenv`, `devbox` (Nix frontends); `cargo-run-bin` (`cargo bin <tool>`, tools declared in `Cargo.toml` metadata) | prebuilt binaries; foreign-language release binaries; declarative multi-language pins; declarative Nix environments; per-project tool pinning with a runner prefix |

Every shortlisted candidate in every member below comes from this map. Nothing
was shortlisted from familiarity: `mise` and `flox` enter because the prompt's
F187/F188 rows name them, `ubi` and `cargo-run-bin` because they are the only
two crates.io-published entrants in this category with materially growing
download counts, and Nix flakes because the practice survey (below) found them
in five of seventeen surveyed repositories — more than `mise` and `flox`
combined, which appeared in zero.

**Authoritative sources used, and why each is authoritative.**

| Source | Why authoritative |
|---|---|
| The rustup book, `https://rust-lang.github.io/rustup/overrides.html` and `.../concepts/components.html` (both HTTP 200, 2026-09-05) | Published by the Rust project's rustup team; it is the normative specification of toolchain-file precedence and of the `components` list, not a third-party description of it |
| The Cargo book, `https://doc.rust-lang.org/cargo/reference/external-tools.html` and `https://doc.rust-lang.org/cargo/commands/cargo-install.html` (2026-09-05) | The Cargo team's own reference; it defines custom-subcommand dispatch (`cargo <command>` to `cargo-<command>` on `$PATH`) and the semantics of `--locked`, which are the two mechanisms the owned parameter turns on |
| The Cargo book's Rust-version chapter, `https://doc.rust-lang.org/cargo/reference/rust-version.html` (cited in `docs/port/BASELINE-REVIEW.md`, re-checked 2026-09-05) | The normative statement that `rust-version` governs diagnostics and resolution, which is what keeps MSRV separate from the development toolchain channel |
| Maintainers' own documentation: `cargo-bins/cargo-binstall` `README.md`, `houseabsolute/ubi` `README.md`, `rust-lang/rustup` `README.md`, `casey/just` `README.md` (all fetched from `raw.githubusercontent.com/<repo>/HEAD/README.md`, 2026-09-05) | First-party statements of licence, install strategy, signature posture, and — in `ubi`'s case — the maintainer's own recommendation against using it for per-project tooling, which is evidence against my own shortlist and is reported as such |
| The committed configuration of seventeen widely adopted Rust repositories, read through `GET https://api.github.com/repos/<o>/<r>/contents/` and `raw.githubusercontent.com` (2026-09-05) | Production practice, measured rather than recalled. Adoption is evidenced by `stargazers_count` from the same `GET /repos/<o>/<r>` call, listed per repository below |
| crates.io and GitHub REST figure endpoints, and `https://rustsec.org/packages/<name>.html` | The figure sources the prompt's evidence table mandates |

A single blog post is nowhere used as an authority in this report; every
mechanism claim traces to a Rust-project publication or a maintainer's own
repository content.

**Practice evidence: seventeen well-regarded Rust projects, surveyed not
recalled.** For each, `GET https://api.github.com/repos/<o>/<r>/contents/`
(2026-09-05) listed the repository root; `stargazers_count` from
`GET https://api.github.com/repos/<o>/<r>` (2026-09-05) is the adoption
evidence. Newer, fast-moving projects are weighted first, as the prompt
directs.

| Repository | Stars | `rust-toolchain.toml` | `justfile` | root `Makefile` | `mise.toml` / `.mise.toml` / `.tool-versions` | `.flox` | `flake.nix` | `xtask/` |
|---|---:|---|---|---|---|---|---|---|
| `denoland/deno` | 108382 | yes | — | — | — | — | yes | — |
| `zed-industries/zed` | 89822 | yes | — | — | — | — | yes | — |
| `astral-sh/uv` | 89499 | yes | — | — | — | — | — | — |
| `BurntSushi/ripgrep` | 67989 | — | — | — | — | — | — | — |
| `starship/starship` | 59798 | — | — | — | — | — | — | — |
| `typst/typst` | 55864 | — | — | — | — | — | — | — |
| `astral-sh/ruff` | 49508 | yes | — | — | — | — | — | — |
| `helix-editor/helix` | 46095 | yes | — | — | — | — | yes | yes |
| `nushell/nushell` | 40419 | yes | — | — | — | — | — | — |
| `casey/just` | 35655 | — | yes | — | — | — | yes | — |
| `tokio-rs/tokio` | 33077 | — | — | — | — | — | — | — |
| `tokio-rs/axum` | 27029 | — | — | — | — | — | — | — |
| `biomejs/biome` | 25717 | yes | yes | — | — | — | — | yes |
| `oxc-project/oxc` | 22649 | yes | yes | — | — | — | — | — |
| `rust-lang/cargo` | 15453 | — | — | — | — | — | — | — |
| `rust-lang/rustup` | 7032 | — | — | — | — | — | yes | — |
| `cargo-bins/cargo-binstall` | 2858 | yes | yes | — | — | — | — | — |
| **Totals (of 17)** | | **9** | **4** | **0** | **0** | **0** | **5** | **2** |

Four results in that table decide most of this item, and none of them was
predictable from the py/ts precedent:

1. **Zero of seventeen carry a declarative provisioner manifest** — no
   `mise.toml`, no `.mise.toml`, no `.tool-versions`, no `.flox`. This is the
   direct empirical answer to the prompt's HIGH question about F187/F188.
2. **Nix flakes beat `mise` and `flox` five to zero** as the whole-environment
   mechanism actually used, so any "declarative provisioner" argument in the
   Rust field has to be made against `flake.nix`, not against `mise.toml`.
3. **Zero of seventeen carry a root `Makefile`.** Make is not a Rust-ecosystem
   norm; it is a cross-repository consistency choice this template may still
   make, but it must be argued rather than assumed. This produces the one
   `BASELINE-REVIEW:` line in this report (F179).
4. **`rust-toolchain.toml` is the single most common file in the category**
   (9/17), and it carries `components` explicitly in 5 of those 9 — which is
   exactly the layer that removes `rustfmt` and `clippy` from any
   installer-recipe set.

**How the four `justfile` repositories actually provision tools** (fetched from
`https://raw.githubusercontent.com/<repo>/HEAD/justfile`, 2026-09-05) — this is
the maintained reference-implementation evidence for members 2 and 5:

- `biomejs/biome`, `install-tools` recipe, verbatim: `cargo install cargo-binstall`, then `cargo binstall cargo-insta wasm-opt cargo-deny`, then `cargo binstall wasm-bindgen-cli --version 0.2.117`, then `pnpm install`. Its sibling `upgrade-tools` repeats the same three lines with `--force`. This is one generic bootstrap recipe covering every tool, not one recipe per tool, and it is the closest maintained analogue of what this template needs.
- `oxc-project/oxc`, `init` recipe, verbatim: `cargo binstall watchexec-cli cargo-insta typos-cli cargo-shear@1.13.1 -y`, then `pnpm install`. Its `ready` recipe then invokes the installed tools as `typos` (a bare binary on `PATH`) alongside `cargo lintgen`, `just fmt`, `cargo ck` (cargo subcommands) — the exact two-rule invocation shape member 5 recommends, observed in production.
- `cargo-bins/cargo-binstall`'s own `justfile` invokes `cargo`, `cargo-zigbuild`, `cross` and `cargo-nextest` as `PATH` binaries and cargo subcommands, with no installer recipe at all.
- `casey/just`'s own `justfile` invokes `cargo fmt --all`, `cargo lclippy`, `cargo doc`, and `shellcheck` — again cargo subcommands for cargo-native tools, a bare binary for the foreign one.

**CI-side practice, for contrast** (`GET https://api.github.com/search/code?q=repo:<o>/<r>+taiki-e/install-action`, 2026-09-05): `zed-industries/zed` 10 hits, `biomejs/biome` 6, `astral-sh/uv` 5, `oxc-project/oxc` 4, `astral-sh/ruff` 0. The same search for the literal string `cargo-binstall` returns `biomejs/biome` 2, `oxc-project/oxc` 1, and 0 for `uv`, `ruff` and `zed`. `taiki-e/install-action` (`GET /repos/taiki-e/install-action`, 2026-09-05: `stargazers_count` 537, `archived: false`, `pushed_at` 2026-09-06T03:40:12Z, licence Apache-2.0) is therefore the dominant *CI* acquisition mechanism while `cargo-binstall` is the dominant *local* one. Both leave the invocation line identical, which is why this item can settle `package-manager-invocation` without settling the CI wiring (R11/R20 own that).

Three further code-search probes (`nushell/nushell`, `denoland/deno`,
`helix-editor/helix`) returned HTTP 403 "API rate limit exceeded" and are
reported as **not measured**, not as zero.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
needed.** Both source repositories implement one principle: *a contributor
runs one command, learns exactly which development tools are missing, and gets
the exact command that installs each one; every repeatable task then invokes
those tools by a single stable name that does not depend on how they were
installed.* py realises it with `check-deps` plus per-tool installer recipes
(`Justfile:94`, `Justfile:159`, `:476`, `:482`, `:713`) and two extra
declarative manifests kept in manual sync (`mise.toml:23`,
`.flox/env/manifest.toml:14`, `mise.toml:1`). ts realises the same principle by
deleting most of the tools (D-014(6), D-014(7): Oxfmt absorbs taplo and
yamlfmt) and demoting the remainder to advisory (`ts: Justfile:83`). The
agreement level is **architectural pattern plus policy** — a
discover-report-remediate loop and a stable invocation vocabulary — not a
capability and not a specific tool. What must agree: one presence-check
command, one remediation string per missing tool, one invocation form per tool
class. What may vary: the acquisition backend, the number of tools, and
whether a manifest file exists at all.

**Essential behaviors.** (1) A contributor with only a bare machine can reach a
working development environment through a documented, finite sequence.
(2) Exactly one command reports the full tool inventory as pass/fail with a
per-tool remediation command. (3) Every Justfile recipe and every lefthook job
names a tool the same way regardless of which backend installed it. (4) The
declared tool set has exactly one authoritative location; two locations that
must be hand-synchronised are a defect, not a feature.

**Observable acceptance criteria.** (A) `just check-deps` exits non-zero and
prints `MISSING <tool> -> RUN <command>` for each absent tool, and exits zero
when all are present. (B) `cargo fmt --version` and `cargo clippy --version`
succeed in a fresh clone after `rustup` alone, with no installer recipe run.
(C) `rustup show active-toolchain` reports the committed `rust-toolchain.toml`
as the override source. (D) Adding a tool to the template requires editing
exactly one list. (E) No recipe or hook line contains a provisioner prefix
(`mise exec`, `cargo bin`, `nix run`).

**Architectural alternatives compared before any library was chosen.** Four
whole-shape alternatives exist, not merely four libraries:

| Architecture | What it is | Why it was or was not chosen |
|---|---|---|
| **Toolchain-file + package-manager acquisition** (recommended) | `rust-toolchain.toml` supplies compiler-adjacent tools; crates.io supplies the rest through one generic recipe; tools are invoked by name | Matches the measured field (9/17 use the toolchain file); collapses py's five installer recipes and two shell scripts into one recipe; single source of truth |
| **Hermetic environment** (Nix flake, `flox`, `devenv`, `devbox`) | one manifest describes compiler, tools and system libraries; a shell command enters the environment | Strongest reproducibility and the only credible declarative option in this field (5/17 carry `flake.nix`). Rejected for a *template*: it imposes a Nix installation on every consumer of the template, and every recipe and hook line then needs an environment prefix, which contradicts essential behavior (3) |
| **Polyglot version manager** (`mise`, `asdf`) | one manifest pins tool versions across languages | The problem it solves — a Python + Node + CLI mix — is py's problem, not this template's. Measured adoption in the surveyed Rust field is zero. Adopting it *in addition to* native installs reproduces F189's manual-sync defect |
| **In-repo Rust automation** (`xtask/`, `cargo-make`) | provisioning and tasks are Rust code compiled by the repo | Real (2/17 use `xtask`), and it removes `just` as a bootstrap dependency, but it moves task definitions into compiled code, is slower on a cold clone, and does not itself acquire foreign binaries. Kept as member 5's ranked runner-up |

**Does the shared pattern remain appropriate in Rust?** Yes for the
discover-report-remediate loop, and no for the per-tool installer layer. The
reason is structural, not stylistic: py's tools (`taplo`, `gitleaks`,
`actionlint`, `yamlfmt`) were outside `uv`'s reach because `uv` installs Python
distributions, so each needed bespoke acquisition. Rust's equivalent tools are
themselves crates — `taplo-cli` (`recent_downloads` 187793,
`downloads` 2170979), `typos-cli` (109350 / 974400), `cargo-nextest`
(1714760 / 12426195), all from
`GET https://crates.io/api/v1/crates/<name>`, 2026-09-05 — so the primary
package manager *does* reach them. The per-tool layer exists in py because of a
gap that Rust largely does not have.

**Answers to the prompt's five questions.**

- **HIGH, does rustup plus cargo remove the per-tool installer layer (F183)?** It removes the *per-tool* part but not the layer. `rustup` covers `rustfmt` and `clippy` through `rust-toolchain.toml`'s `components` (executed proof below: `cargo fmt --version` returns `rustfmt 1.9.0` and `cargo clippy --version` returns `clippy 0.1.98` with no installer run). `cargo install` / `cargo-binstall` covers every crates.io-published tool. What remains is one generic install-if-missing recipe over a declared tool table — not five recipes and two shell scripts. A residual non-crates.io tool (lefthook, actionlint, gitleaks) still needs a backend, but the template ships zero such tools by default and R37/R39/R40 own whether any appear.
- **HIGH, is a declarative provisioner common practice (F187/F188)?** No. Zero of seventeen surveyed repositories carry `mise.toml`, `.mise.toml`, `.tool-versions` or `.flox`. Five carry `flake.nix`. The narrower Rust non-cargo tool surface is exactly the reason: the manifest would declare a tool list that `rust-toolchain.toml` and `Cargo.toml` already imply.
- **MEDIUM, one manifest or two if a provisioner is adopted (F189)?** Neither. Two hand-synchronised manifests plus a native path is a three-way consistency obligation whose only enforcement is a comment (`py: mise.toml:1`). If the owner nonetheless wants a hermetic option, it should be exactly one file and it should be `flake.nix`, on the measured-adoption evidence — never two.
- **MEDIUM, the idiomatic invocation answer (`package-manager-invocation`)?** Both forms, split by a mechanical rule: `cargo <sub>` whenever the executable is named `cargo-<sub>` (which includes `cargo fmt` and `cargo clippy`), a bare binary on `PATH` otherwise. This is not a compromise; it is what the Cargo book's custom-subcommand dispatch makes true, and it is what `oxc`, `biome`, `just` and `cargo-binstall` all do in their own `justfile`s.
- **LOW, one script per tool or one generic recipe?** One generic recipe. Executed below: a nine-line `check-deps` loop over a `"<probe-binary>:<install-spec>"` table reproduces py's per-tool output and exit status with no per-tool code.

**Baseline obligations this item was handed.**

- **F181 (`just check-deps`, `COMMON → REUSE`, held pending this item) — retained, not collapsed into F180, and no `BASELINE-REVIEW:` is emitted for it.** Two independent reasons. First, F180 (`make check`) and F181 have different scopes even after the installer layer shrinks: F180 tests the Level-1 set (a Rust toolchain and `just`) on a machine that may have neither, while F181 tests the Level-2 set (cargo-published tools) and can assume cargo exists. Second, `command -v` *is* the correct presence test under the recommended parameter, and this is a consequence of the mechanism rather than a preference: the Cargo book states that `cargo <command>` dispatches to an external `cargo-<command>` found in a `$PATH` directory, so a cargo plugin's presence is literally a `PATH` lookup. Executed confirmation is in `Validation strategy`. What does change is F181's *implementation*: py's per-tool `if`-blocks become one loop over a declared table, and its remediation strings become one generated `just install-tool <spec>` line.
- **F179 (two-level bootstrap split) — layering retained, entry mechanism challenged.** See the `BASELINE-REVIEW:` line below.
- **F190 / F103 (the toolchain pin file) — evidence supplied, ownership not claimed.** This item recommends that the committed `rust-toolchain.toml` carry `profile = "minimal"` plus `components = ["rustfmt", "clippy"]`, because that single line is what deletes two installer recipes. The `channel` **value** is R27's through F103 and is not decided here. New measured evidence for R27: of the nine surveyed repositories carrying the file, eight pin an exact version (`deno` 1.95.0, `helix` 1.90.0, `nushell` 1.96.1, `zed` 1.97.1, `biome` 1.98.0, `ruff` 1.98.0, `oxc` 1.98.1, `uv` 1.98.1) and one uses `channel = "stable"` (`cargo-binstall`); five of the nine declare `components` explicitly. `nushell/nushell`'s file carries the comment "The current plan is to be 2 releases behind the latest stable release", which is the owner's `msrv-policy` shape appearing as a *development channel* policy in production — R27 should weigh it, and this item does not. No `CONFLICT:` line arises, because R42 consumes no parameter.

BASELINE-REVIEW: F179 — a base-toolchain bootstrap layer precedes project dev tasks and uses only what a bare machine already has — retain the two-layer split, but record `make` as a deliberate cross-repository consistency choice carrying a measured ecosystem cost, and delete the claim that it is "the only dependency-free entry point" — evidence: zero of seventeen widely adopted Rust repositories carry a root `Makefile`, while nine carry `rust-toolchain.toml`, five carry `flake.nix` and four carry a `justfile` (`GET https://api.github.com/repos/<o>/<r>/contents/` over `denoland/deno`, `zed-industries/zed`, `astral-sh/uv`, `BurntSushi/ripgrep`, `starship/starship`, `typst/typst`, `astral-sh/ruff`, `helix-editor/helix`, `nushell/nushell`, `casey/just`, `tokio-rs/tokio`, `tokio-rs/axum`, `biomejs/biome`, `oxc-project/oxc`, `rust-lang/cargo`, `rust-lang/rustup`, `cargo-bins/cargo-binstall`, 2026-09-05); rustup's own documented install path is a shell pipeline, not `make` (https://rust-lang.github.io/rustup/installation/index.html, HTTP 200, 2026-09-05), so the dependency-free entry point in this ecosystem is `sh` + `curl`, which `make` wraps rather than replaces; affected items: F179 Notes, F180 (whose Level-1 tool list becomes rustup/cargo plus `just`), F181 (whose Level-2 scope this report retains), and R37, whose lefthook bootstrap lands in whichever layer the owner keeps.

**Minimal realistic example and how it composes.** A fresh clone of the
template contains `rust-toolchain.toml` (channel per R27, `profile = "minimal"`,
`components = ["rustfmt", "clippy"]`), a `Justfile` holding one `dev-tools`
table variable, one `check-deps` recipe and one `install-tool` recipe, and a
`lefthook.yml` whose jobs name tools by the parameter's rule. A contributor
runs the Level-1 bootstrap (rustup, then `just`), then `just check-deps`, then
the printed `just install-tool <spec>` lines, then `just check-deps` again to
green. Nothing else is hand-synchronised: the tool table is the only list.

**Proposed versus executed checks.** The checks under `Validation strategy`
marked *executed* were actually run on this host on 2026-09-05 against
`rustc 1.98.0`, `cargo 1.98.0`, `just 1.57.0` on `aarch64-apple-darwin`, and
their real output is reproduced. The checks marked *proposed* were not run,
because running them would install binaries into `~/.cargo/bin` on the owner's
machine, which is outside this report's mandate.

### Recommendation

One stack: **`rustup` with a committed `rust-toolchain.toml` carrying
`profile = "minimal"` and `components = ["rustfmt", "clippy"]`; `cargo-binstall`
(pinned via `cargo install cargo-binstall --locked`) as the acquisition backend
for every crates.io-published dev tool, with `cargo install --locked` as the
always-available fallback; `ubi` named as the single generic backend for any
future tool that is published only as a GitHub/GitLab release; no `mise.toml`,
no `.flox/env/manifest.toml`, and no other declarative provisioner manifest;
and one generic `just check-deps` / `just install-tool` pair driven by a single
declared tool table, replacing py's five per-tool recipes and two per-tool shell
scripts.** Tools are invoked as `cargo <sub>` when the executable is
`cargo-<sub>` and as a bare `PATH` binary otherwise, with no provisioner prefix
anywhere.

### Members

#### Rust toolchain and components — rustup with a committed rust-toolchain.toml

##### Landscape
This member decides how the compiler-adjacent tools (`rustfmt`, `clippy`, and
optionally `rust-src`, `rust-analyzer`, extra targets) reach a machine. Bin
placement: **built-in / first-party** — `rustup` plus the `rust-toolchain.toml`
file it reads; **established industry standard** — none competing, because
`rustup` is the Rust project's own installer; **up-and-comer** — `mise` and Nix
flakes both offer to install the Rust toolchain instead of `rustup`, and are
evaluated here rather than in member 4 because that is the slot they would
occupy. Practice evidence: 9 of the 17 surveyed repositories commit
`rust-toolchain.toml`, more than any other file in this category, and 5 of
those 9 declare `components` explicitly (`zed` `["rustfmt", "clippy",
"rust-analyzer", "rust-src"]`, `helix` `["rustfmt", "rust-src", "clippy"]`,
`deno` `["rustfmt", "clippy", "rust-src", "rust-analyzer"]`, `cargo-binstall`
`["rustfmt", "clippy"]`; `biome` and `nushell` instead set `profile = "default"`,
which the rustup book states "includes all of components in the minimal
profile, and adds rust-docs, rustfmt, and clippy"
(https://rust-lang.github.io/rustup/concepts/profiles.html, 2026-09-05)). All
read
from `https://raw.githubusercontent.com/<repo>/HEAD/rust-toolchain.toml`,
2026-09-05.

##### Principles and implementation
Principle: the tools that ship *with* the compiler must not appear in any
installer recipe, because a second acquisition path for them is a second thing
that can drift from the compiler. Mechanism: rustup resolves the active
toolchain in a documented precedence order — a `+toolchain` shorthand, then
`RUSTUP_TOOLCHAIN`, then a `rustup override` directory setting, then
`rust-toolchain.toml`, then the default — with the toolchain file and directory
overrides additionally preferred by proximity, discovered by walking up toward
the filesystem root (https://rust-lang.github.io/rustup/overrides.html,
2026-09-05). Committing the file therefore makes every in-directory `cargo` and
`rustc` invocation use the declared toolchain and its declared components,
without any recipe doing anything. Observable criterion: in a fresh clone,
`cargo fmt --version` and `cargo clippy --version` both succeed with no
installer run, and `rustup show active-toolchain` names the file as the override
source. Both were executed on this host (output in `Validation strategy`).
This is also the layer that answers the prompt's HIGH F183 question for two of
the four py tool classes: py needed `install-taplo` and friends precisely
because Python's package manager could not reach them; rustup reaches
`rustfmt` and `clippy` by definition.

##### Dominant choice
`rustup` with a committed `rust-toolchain.toml`. Figures — crates.io is the
wrong distribution channel for this tool and its numbers say so, which is
itself the finding: `GET https://crates.io/api/v1/crates/rustup` (2026-09-05)
returns `crate.recent_downloads` **3** and `crate.downloads` **1488**, and
`GET https://crates.io/api/v1/crates/rustup/versions` (2026-09-05) returns
**zero** unyanked versions, so *Last release* is **inapplicable via crates.io**
— rustup is distributed through `rustup-init` / `https://rustup.rs`
(https://rust-lang.github.io/rustup/installation/index.html, HTTP 200,
2026-09-05), and GitHub figures are the meaningful ones.
`GET https://api.github.com/repos/rust-lang/rustup` (2026-09-05):
`stargazers_count` **7032**, `archived` **false**, `pushed_at`
**2026-09-05T07:03:41Z**. Open issues,
`GET https://api.github.com/search/issues?q=repo:rust-lang/rustup+is:issue+is:open`
(2026-09-05): `total_count` **392**. Issue responsiveness: of the 30 most
recently created items on
`GET /repos/rust-lang/rustup/issues?state=all&sort=created&direction=desc`,
five were issues rather than pull requests (created 2026-08-23 to 2026-09-02);
median days to first maintainer response **0.06**, unanswered **0**.
Advisories: `https://rustsec.org/packages/rustup.html` returns HTTP **404**
(2026-09-05) — no advisory page exists; the control probes
`https://rustsec.org/packages/time.html` and `.../atty.html` both return HTTP
200 on the same date, so 404 here means "no RustSec page for this package",
verified by contrast rather than assumed. Maintenance state: **active** — the
Rust project's own tool, pushed the day of retrieval, sub-hour median issue
response.

##### Qualified shortlist
`rustup` + `rust-toolchain.toml` (recommended). `rustup` + `rustup component
add` invoked from a Justfile recipe (same tool, imperative instead of
declarative). `mise` managing the Rust toolchain (`GET /repos/jdx/mise`,
2026-09-05: `stargazers_count` 33517, `archived` false, `pushed_at`
2026-09-06T04:34:49Z, licence MIT). A Nix flake providing the toolchain
(`flake.nix` present in `denoland/deno`, `zed-industries/zed`,
`helix-editor/helix`, `casey/just`, `rust-lang/rustup`).

##### Excluded by gate
*Gate framing first, because it recurs in every member:* the prompt's six gates
are written for crates that enter this template's **dependency tree**. Every
candidate in this bundle is a **developer tool executed as a separate process**
and linked into nothing, so gates 1, 2, 5 and 6 are answered in that light and
the reasoning is stated rather than assumed.

- **`mise` as the Rust toolchain provider — excluded by fit, not by gate.** It passes gate 1 (MIT, `GET https://crates.io/api/v1/crates/mise`, 2026-09-05, newest unyanked version 2026.9.1 published 2026-09-02, `license` `MIT`). It is excluded because it would replace the Rust project's own toolchain manager with a third-party one for a template whose contributors already need `rustup` for `cargo`, and because measured adoption for that role in the surveyed field is zero of seventeen.
- **Nix flake as the toolchain provider — excluded by fit.** Highest reproducibility of any candidate and genuinely used (5/17), but it makes a Nix installation a precondition for contributing to a *template*, and it forces an environment prefix into every recipe and hook line, breaking essential behavior (3).
- No candidate in this member fails gate 1 (licence), gate 3 (advisory) or gate 4 (OS support).

##### Up-and-comers
`mise` (2026.9.1, released 2026-09-02) and the Nix-frontend family (`flox`,
`devenv`, `devbox`) are the live entrants that would displace `rustup` here.
Note for the record that `devenv` and `devbox` on crates.io are unrelated
projects by different authors (`GET https://crates.io/api/v1/crates/devenv`
returns `repository: https://github.com/lyssieth/devenv`, `recent_downloads` 76;
`.../devbox` returns `https://github.com/peterkozelj/devbox`,
`recent_downloads` 15; both 2026-09-05), so crates.io figures must not be used
as adoption evidence for `cachix/devenv` or `jetify-com/devbox`.

##### Fit for this template
The template is CLI + library + web service with a `ubuntu-latest,
macos-latest` matrix. `rustup` is a precondition on both runners and on every
contributor machine regardless of this decision, so choosing it adds zero new
dependencies — the strongest possible fit argument. `profile = "minimal"` plus
an explicit `components` list keeps a fresh install small while guaranteeing
the two tools every recipe and hook needs. Relative to py, this layer alone
deletes the need for any `rustfmt`/`clippy` analogue of `install-taplo`;
relative to ts, it achieves ts's "fold the tools into something already
present" outcome without deleting any capability.

##### Recommendation
Commit `rust-toolchain.toml` with `profile = "minimal"` and
`components = ["rustfmt", "clippy"]`. The `channel` value is **R27's decision
through F103** and is not set here; supply R27 with the measured evidence in
`Principles and implementation` (8 of 9 surveyed repositories pin an exact
version; 1 uses `"stable"`). Add no `rustup component add` recipe: the file is
declarative and rustup applies it automatically.

##### Ranked runner-up
`rustup` with an imperative `just install-components` recipe running
`rustup component add rustfmt clippy`. Same tool, same result, but it
reintroduces a second acquisition path for the two tools rustup already owns
and it only runs when a contributor remembers to run it. Rank 2 of 4; ranks 3
and 4 are the Nix flake and `mise`, both excluded above by fit.

##### Tradeoffs
Committing a toolchain file makes every in-directory invocation use that
toolchain, so a contributor cannot silently build with a newer compiler; that
is the point, and `cargo +nightly` and `RUSTUP_TOOLCHAIN` remain available as
higher-precedence escapes (https://rust-lang.github.io/rustup/overrides.html,
2026-09-05). `profile = "minimal"` is documented as "as few components as
possible to get a working compiler (rustc, rust-std, and cargo)"
(https://rust-lang.github.io/rustup/concepts/profiles.html, 2026-09-05), so it
omits `rust-docs` and `rust-analyzer` even after the explicit `components` list
restores `rustfmt` and `clippy`; editors that expect `rust-analyzer` from
rustup will need it added to `components` — a one-line change, and `zed` and `deno` both do exactly that.
Binary-size cost: none, no linked code. Compile-time cost: none; components are
downloaded prebuilt.

##### Parameters
Contributes to `package-manager-invocation` (owned by R42): because `rustfmt`
and `clippy` arrive as rustup components whose executables are `cargo-fmt` and
`cargo-clippy`, they are invoked as `cargo fmt` and `cargo clippy`, which is
the cargo-subcommand half of the parameter's rule. Assumes the fixed
parameters `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions,
raised only in a minor release, declared as rust-version in Cargo.toml and
tested in CI`, `target-os-matrix = ubuntu-latest, macos-latest`,
`license = MIT OR Apache-2.0`. No `CONFLICT:` line. Coordinates with R27 on
F103/F190 for the `channel` value without claiming it.

##### Migration implications
New file `rust-toolchain.toml` at the repository root. No `install-rustfmt` or
`install-clippy` recipe is ever written. `Makefile` Level-1 `check` target
tests for `rustup`/`cargo` instead of `uv`. Nothing in `Justfile` references
component installation.

##### Validation strategy
Executed on this host, 2026-09-05, in a scratch directory containing only the
recommended `rust-toolchain.toml`: `rustup show active-toolchain` printed
`stable-aarch64-apple-darwin (overridden by '<scratch>/rust-toolchain.toml')`,
proving the file is the override source; `cargo fmt --version` printed
`rustfmt 1.9.0` and `cargo clippy --version` printed `clippy 0.1.98`, both
through the rustup proxy at `~/.cargo/bin/cargo`, with no installer step.
Proposed for CI: the same three commands as the first step of the build job on
both `ubuntu-latest` and `macos-latest`.

##### Confidence & re-verify trigger
Confidence **high** — first-party mechanism, documented precedence, executed
locally, 9/17 measured adoption. Re-verify if rustup changes toolchain-file
precedence or the `profile`/`components` schema, if R27 settles F103 with a
`channel` value that conflicts with `profile = "minimal"`, or by 2027-03-05,
whichever is first.

##### Sources
https://rust-lang.github.io/rustup/overrides.html (2026-09-05, HTTP 200) ·
https://rust-lang.github.io/rustup/concepts/components.html (2026-09-05, HTTP
200) · https://rust-lang.github.io/rustup/concepts/profiles.html (2026-09-05,
HTTP 200; minimal = "rustc, rust-std, and cargo", default adds "rust-docs,
rustfmt, and clippy") · https://rust-lang.github.io/rustup/installation/index.html (2026-09-05,
HTTP 200) · https://raw.githubusercontent.com/rust-lang/rustup/HEAD/README.md
(2026-09-05; "Licensed under either of Apache License, Version 2.0 ... MIT
license ... at your option") · GET https://crates.io/api/v1/crates/rustup and
/versions (2026-09-05) · GET https://api.github.com/repos/rust-lang/rustup
(2026-09-05) ·
GET https://api.github.com/search/issues?q=repo:rust-lang/rustup+is:issue+is:open
(2026-09-05) · https://rustsec.org/packages/rustup.html (2026-09-05, HTTP 404;
controls https://rustsec.org/packages/time.html and .../atty.html both HTTP
200) · https://raw.githubusercontent.com/<repo>/HEAD/rust-toolchain.toml for
`oxc-project/oxc`, `biomejs/biome`, `astral-sh/uv`, `astral-sh/ruff`,
`zed-industries/zed`, `helix-editor/helix`, `nushell/nushell`, `denoland/deno`,
`cargo-bins/cargo-binstall` (all 2026-09-05).

#### Cargo-published dev-tool binaries — cargo-binstall with a cargo install --locked fallback

##### Landscape
This member decides how a tool that *is* on crates.io (`taplo-cli`,
`typos-cli`, `cargo-nextest`, `cargo-deny`, `cargo-llvm-cov`, `cargo-audit`,
and whatever R27–R29/R32/R39/R40 pick) reaches a machine. Bin placement:
**built-in / first-party** — `cargo install` and `cargo install --locked`;
**established industry standard** — `cargo-binstall`; **up-and-comer** —
`cargo-quickinstall` (also `cargo-binstall`'s own third strategy) and
`cargo-run-bin`. Practice evidence, measured: of the four surveyed
repositories with a `justfile`, two provision tools and **both use
`cargo binstall`** — `biomejs/biome` (`install-tools`:
`cargo install cargo-binstall` then
`cargo binstall cargo-insta wasm-opt cargo-deny`) and `oxc-project/oxc`
(`init`: `cargo binstall watchexec-cli cargo-insta typos-cli cargo-shear@1.13.1 -y`),
both from `https://raw.githubusercontent.com/<repo>/HEAD/justfile`, 2026-09-05.
Neither writes a per-tool recipe; both write one bootstrap recipe listing every
tool. On the CI side the equivalent standard is `taiki-e/install-action`
(`GET /repos/taiki-e/install-action`, 2026-09-05: 537 stars, `archived` false,
`pushed_at` 2026-09-06T03:40:12Z), with 10 hits in `zed`, 6 in `biome`, 5 in
`uv`, 4 in `oxc` (`GET /search/code?q=repo:<o>/<r>+taiki-e/install-action`,
2026-09-05).

##### Principles and implementation
Principle: acquiring a development tool must not require compiling it, and must
not require bespoke code per tool. Mechanism: `cargo-binstall` reads the
crate's metadata to locate a prebuilt release artifact, falling back through a
documented strategy list — the maintainers' README documents
`--disable-strategies quick-install` and `--strategies` as the controls over
that list, and `compile` as the terminal strategy
(https://raw.githubusercontent.com/cargo-bins/cargo-binstall/HEAD/README.md,
2026-09-05). The first-party floor underneath it is
`cargo install <crate> --locked`, which the Cargo book documents as forcing use
of the crate's packaged `Cargo.lock` "for ensuring reproducible builds, to use
the exact same set of dependencies that were available when the package was
published" (https://doc.rust-lang.org/cargo/commands/cargo-install.html,
2026-09-05) — the property that makes a tool install survive an unrelated
upstream dependency breakage. Observable criterion: one recipe, given a tool
spec, installs it; the same recipe with a different spec installs a different
tool; no per-tool file exists. Architectural alternative genuinely considered
and rejected: `cargo-run-bin`, which declares tools in `Cargo.toml`'s
`[package.metadata.bin]` and runs them as `cargo bin <tool>` — elegant and it
removes the presence check entirely, but it puts a wrapper prefix on every
invocation line, which is the one thing the owned parameter forbids, and its
maintenance signals are the weakest in this member (below).

##### Dominant choice
`cargo-binstall`. Figures, `GET https://crates.io/api/v1/crates/cargo-binstall`
(2026-09-05): `crate.recent_downloads` **123101** (90-day),
`crate.downloads` **3474822** (all-time).
`GET https://crates.io/api/v1/crates/cargo-binstall/versions` (2026-09-05):
newest unyanked `num` **1.23.0**, `created_at` **2026-09-05T16:59:01.959145Z**,
`license` **GPL-3.0-only**, `rust_version` **1.79.0**.
`GET https://api.github.com/repos/cargo-bins/cargo-binstall` (2026-09-05):
`stargazers_count` **2858**, `archived` **false**, `pushed_at`
**2026-09-05T16:59:16Z**.
`GET https://api.github.com/search/issues?q=repo:cargo-bins/cargo-binstall+is:issue+is:open`
(2026-09-05): `total_count` **94**. Issue responsiveness, 10 most recently
created issues (2026-05-01 to 2026-08-14, obtained through
`GET /search/issues?q=repo:cargo-bins/cargo-binstall+is:issue&sort=created&order=desc`
because the plain issues endpoint is dominated by bot pull requests): median
days to first maintainer response **0.9**, unanswered **2**. Advisories:
`https://rustsec.org/packages/cargo-binstall.html` HTTP **404** (2026-09-05) —
no advisory page. Maintenance state: **active** (released and pushed on the
retrieval date; sub-day median issue response).

##### Qualified shortlist
| Candidate | 90-day / all-time downloads | Newest unyanked | Licence (crates.io) | `rust_version` | Stars | `pushed_at` | Open issues | Responsiveness (10 newest issues) | Maintenance |
|---|---|---|---|---|---:|---|---:|---|---|
| `cargo install --locked` (first-party) | inapplicable — part of Cargo, not a separate crate | ships with the toolchain | Apache-2.0 OR MIT (Rust project) | n/a | n/a | n/a | n/a | inapplicable | **active** (Rust release train) |
| `cargo-binstall` | 123101 / 3474822 | 1.23.0, 2026-09-05T16:59:01Z | GPL-3.0-only | 1.79.0 | 2858 | 2026-09-05T16:59:16Z | 94 | median 0.9 d, 2 unanswered | **active** |
| `cargo-quickinstall` | 7348 / 500307 | 0.3.53, 2026-07-12T05:43:44Z | MIT OR Apache-2.0 | none declared | 313 | 2026-09-06T00:57:11Z | 70 | median 0.35 d, 0 unanswered (issues 2025-03-23..2025-10-02) | **active** |
| `cargo-run-bin` | 79263 / 287839 | 1.7.5, 2025-07-14T14:31:29Z | MIT | 1.70.0 | 236 | 2025-12-19T02:30:12Z | 7 | median 121.91 d, 4 unanswered (issues 2025-01-30..2026-02-01) | **at-risk** |

All figures 2026-09-05 from `GET https://crates.io/api/v1/crates/<name>` and
`/versions`, `GET https://api.github.com/repos/<o>/<r>`, and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`.
RustSec: `https://rustsec.org/packages/<name>.html` returns HTTP 404 for
`cargo-binstall`, `cargo-quickinstall` and `cargo-run-bin` (2026-09-05); the
404-means-absent reading is verified by the HTTP 200 controls named in member 1.
`cargo-run-bin`'s **at-risk** verdict rests on concrete signals, not on the
6-month release trigger alone: last release 2025-07-14 (about 14 months before
retrieval), last push 2025-12-19 (about 9 months), and a measured 121.91-day
median to first maintainer response with 4 of 10 sampled issues unanswered.

##### Excluded by gate
- **`cargo-binstall`, gate 1 (licence) — the strict reading is answered, not skipped.** Its newest unyanked version declares `license` **`GPL-3.0-only`** (crates.io, 2026-09-05), which is *not* compatible with `MIT OR Apache-2.0` for a crate linked into this template. It is nonetheless **not excluded**, for a stated reason: gate 1 protects the template's distributable artifact, and `cargo-binstall` never enters it. It is a standalone executable a contributor runs to fetch other executables — the same relationship the template has to `git`, `make` or `gh`. The FSF's own GPL FAQ describes this as mere aggregation: separate programs shipped or used alongside each other, communicating only at arm's length, do not combine into one work (https://www.gnu.org/licenses/gpl-faq.html#MereAggregation, 2026-09-05). No GPL-3.0 term reaches the template's `MIT OR Apache-2.0` grant. **Strict-reading fallback for the synthesizer, if the owner reads gate 1 as covering tools as well as crates:** drop `cargo-binstall` and use `cargo install --locked` (first-party, Apache-2.0 OR MIT, no new tool at all — the cost is compile time, minutes per tool per fresh machine) or `cargo-quickinstall` (`MIT OR Apache-2.0`, 2026-09-05, prebuilt, same no-compile benefit, one third of binstall's velocity signals). The stack degrades gracefully in either direction because the *recipe* is generic; only the backend command changes.
- **`cargo-run-bin` — excluded, two independent reasons.** (i) Fit: it requires every invocation to be prefixed `cargo bin <tool>`, which the owned parameter forbids and which would propagate a wrapper into every consumer item's recipes and hooks. (ii) Maintenance: **at-risk** on the concrete signals listed above. Not excluded on licence (MIT), advisory (none) or OS.
- **Gate 2 (MSRV), answered per candidate.** For a **prebuilt** install the gate is **inapplicable** — no source is compiled on the contributor's machine, so the tool's `rust_version` never meets this template's toolchain. For the **source fallback** (`cargo install cargo-binstall --locked`), the relevant floor is the *development* channel from `rust-toolchain.toml`, not `msrv-policy`: `msrv-policy` governs `rust-version` in `Cargo.toml` and the dedicated CI floor job (`docs/port/PARAMETERS.md`), and dev tools are not built by that job. `cargo-binstall` declares `rust_version` 1.79.0 and `cargo-quickinstall` declares none, both far below any plausible current-stable channel, so the source fallback compiles. `ubi`'s 1.88 (member 3) and `mise`'s 1.95 (member 4) are the two candidates where this distinction actually bites.
- **Gate 3 (advisories, `unsafe` posture).** No RustSec page for any candidate (all HTTP 404, 2026-09-05). `unsafe` posture: not separately audited here and **not asserted** — for a tool executed as a separate process with no linkage into the template, an `unsafe` block cannot reach the template's address space; the residual risk is supply-chain, which member 2's `--locked` pin and binstall's signature support address instead (https://raw.githubusercontent.com/cargo-bins/cargo-binstall/HEAD/README.md, 2026-09-05, "Signatures" section: "initial, limited support ... not a lot of the ecosystem produces signatures at the moment"). Recording that as a **known gap**, in the maintainers' own words.
- **Gate 4 (OS).** `cargo-binstall` publishes and tests Linux and macOS artifacts and its own `justfile` computes `target-os` for `linux`, `macos` and `windows` (`https://raw.githubusercontent.com/cargo-bins/cargo-binstall/HEAD/justfile`, 2026-09-05); both required runners are covered, Windows additionally.
- **Gate 5 (default features, async coupling).** Inapplicable in the linking sense — nothing is linked, so no feature unification or runtime coupling with this template's async choice (R05) can occur. `cargo-binstall` selects its own runtime internally; that choice is invisible here.
- **Gate 6 (binary size, compile time).** For the template's artifact: **zero on both** — no dependency is added. For the contributor: `cargo-binstall` itself costs one source compile at bootstrap (`cargo install cargo-binstall --locked`), after which every subsequent tool install is a download rather than a compile, which is the entire benefit.

##### Up-and-comers
`cargo-quickinstall` (0.3.53, 2026-07-12) is the credible one and doubles as
`cargo-binstall`'s own `quick-install` strategy, so adopting binstall already
gets its benefit; its standalone velocity (7348 90-day downloads against
binstall's 123101) does not justify choosing it directly. `cargo-run-bin`
(1.7.5, 2025-07-14) is the interesting architectural entrant and is analysed
above. Neither `devenv` nor `devbox` competes in this member.

##### Fit for this template
The template's plausible tool set is overwhelmingly crates.io-published, which
is the precise condition under which this member does all the work. Concrete
evidence that these tools exist as crates, all from
`GET https://crates.io/api/v1/crates/<name>` (2026-09-05): `taplo-cli`
`recent_downloads` 187793 / `downloads` 2170979; `typos-cli` 109350 / 974400;
`cargo-nextest` 1714760 / 12426195. Named only as illustrations of the tool
*class* — which of these the template ships is R27, R29, R32, R39 and R40's
decision, never this item's. Against py: this member replaces `install-taplo`,
`install-gitleaks`, `install-actionlint`, `install-yamlfmt` and two shell
scripts with one recipe. Against ts: it achieves ts's economy without ts's
capability loss, because nothing has to be deleted to be provisioned cheaply.
CLI, library and web-service targets make no difference to this member.

##### Recommendation
Bootstrap `cargo-binstall` once with `cargo install cargo-binstall --locked`
(the maintainers' own documented line,
https://raw.githubusercontent.com/cargo-bins/cargo-binstall/HEAD/README.md,
2026-09-05), then acquire every crates.io tool through one generic recipe
whose body is `cargo binstall --locked --no-confirm <spec>`, where `<spec>` is
`name@version` from the single declared tool table (`--no-confirm` is the
maintainers' documented flag "for unattended use (e.g. in CI)",
https://raw.githubusercontent.com/cargo-bins/cargo-binstall/HEAD/README.md,
2026-09-05; `oxc-project/oxc` uses the equivalent short form `-y`). Keep
`cargo install --locked <spec>` documented as the always-available fallback
that needs no third-party tool at all. Do not write a second recipe for a
second tool.

##### Ranked runner-up
Rank 2: **`cargo install --locked` alone**, no `cargo-binstall`. It is
first-party, licence-clean under the strictest gate reading, and identical from
the recipe's point of view — only slower. This is the fallback to take if the
owner reads gate 1 strictly. Rank 3: `cargo-quickinstall`. Rank 4:
`cargo-run-bin`, excluded above.

##### Tradeoffs
`cargo-binstall` adds one bootstrap step and one GPL-3.0-licensed tool to a
contributor's machine (not to the artifact). Its prebuilt path trusts release
artifacts whose signature coverage the maintainers themselves describe as
limited, which is a real supply-chain surface that `cargo install --locked`
does not have — `--locked` and pinned `name@version` specs narrow but do not
eliminate it. Against that: a fresh contributor reaches a working environment
in seconds rather than the minutes-per-tool a source build costs, and CI cold
starts shrink correspondingly. `oxc` and `biome` both accepted this trade.

##### Parameters
Contributes to `package-manager-invocation`: cargo-published tools whose
executable is `cargo-<sub>` are invoked `cargo <sub>`; cargo-published tools
whose executable is a plain name (`taplo`, `typos`) are invoked as bare `PATH`
binaries — the acquisition backend is invisible at the invocation site, which
is what makes the parameter stable under a later backend change. Assumes the
four fixed parameters unchanged. No `CONFLICT:` line.

##### Migration implications
`Justfile` gains one `dev-tools` table variable and one `install-tool` recipe.
`scripts/install-gitleaks.sh` and `scripts/install-actionlint.sh` have **no**
Rust analogue and are not ported. `install-taplo`, `install-gitleaks`,
`install-actionlint`, `install-yamlfmt` (py `Justfile:159`, `:476`, `:482`,
`:713`) are not ported as individual recipes. A `bootstrap` step gains
`cargo install cargo-binstall --locked`.

##### Validation strategy
Executed, 2026-09-05: the generic `check-deps` loop over a
`"<probe>:<crate>"` table printed
`MISSING cargo-nextest -> RUN `just install-tool cargo-nextest``, `ok taplo`,
`ok typos`, and exited **1** — proving one recipe reproduces py's per-tool
report and exit status. **Proposed, not executed:**
`cargo install cargo-binstall --locked` followed by
`cargo binstall --locked --no-confirm taplo-cli@0.10.0` and
`command -v taplo`, on both `ubuntu-latest` and `macos-latest`; not run here
because it would write binaries into the owner's `~/.cargo/bin`.

##### Confidence & re-verify trigger
Confidence **high** on the mechanism and on the generic-recipe shape (executed;
two maintained reference implementations); **medium** on `cargo-binstall`
specifically versus `cargo install --locked`, because that choice turns on the
owner's reading of gate 1 for a non-linked tool. Re-verify if `cargo-binstall`
relicenses, if signature coverage materially changes, if a RustSec advisory
appears, or by 2027-03-05.

##### Sources
GET https://crates.io/api/v1/crates/cargo-binstall and /versions (2026-09-05) ·
GET https://crates.io/api/v1/crates/cargo-quickinstall, /cargo-run-bin,
/taplo-cli, /typos-cli, /cargo-nextest (2026-09-05) ·
GET https://api.github.com/repos/cargo-bins/cargo-binstall,
/cargo-bins/cargo-quickinstall, /dustinblackman/cargo-run-bin,
/taiki-e/install-action (2026-09-05) ·
GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open for
each (2026-09-05) · https://rustsec.org/packages/cargo-binstall.html,
.../cargo-quickinstall.html, .../cargo-run-bin.html (all HTTP 404, 2026-09-05) ·
https://raw.githubusercontent.com/cargo-bins/cargo-binstall/HEAD/README.md and
/justfile (2026-09-05) ·
https://raw.githubusercontent.com/biomejs/biome/HEAD/justfile and
https://raw.githubusercontent.com/oxc-project/oxc/HEAD/justfile (2026-09-05) ·
https://doc.rust-lang.org/cargo/commands/cargo-install.html (2026-09-05) ·
https://www.gnu.org/licenses/gpl-faq.html#MereAggregation (2026-09-05) ·
GET https://api.github.com/search/code?q=repo:<o>/<r>+taiki-e/install-action
(2026-09-05).

#### Non-cargo dev-tool binaries — ubi as the single generic release-fetch backend

##### Landscape
This member decides the residue: a tool that is *not* on crates.io and is
therefore unreachable by member 2. In py that residue was large — `gitleaks`,
`actionlint` and `yamlfmt` are Go programs, which is exactly why py needed
`scripts/install-gitleaks.sh` and `scripts/install-actionlint.sh` (py
`Justfile:476`, `:482`). In Rust the residue is small and may be empty:
`lefthook` (Go) is R37's to distribute, `actionlint` (Go) has no Rust
equivalent but is usually run by a CI action rather than locally, and the
secret-scanner and spell-checker slots have crates.io-published options that
R39 and R40 may choose. Bin placement: **built-in / first-party** — none, this
is by definition outside cargo's reach; **established industry standard** — a
per-tool vendor install script piped from `curl` (py's pattern, and what most
projects in any language do), plus `taiki-e/install-action` on the CI side;
**up-and-comer** — `ubi`, a universal GitHub/GitLab release-asset installer
written in Rust, and `mise`, which also fetches release binaries. Practice
evidence: none of the 17 surveyed repositories provisions a foreign-language
tool through a declarative manifest; `biomejs/biome` and `oxc-project/oxc` both
reach for their **JavaScript** package manager (`pnpm install`) for the
non-Rust half of their toolchain, which is not an option this template has.

##### Principles and implementation
Principle: the residue must not reintroduce per-tool code. One backend, one
recipe, N table rows. Mechanism: `ubi` resolves a GitHub or GitLab release,
picks the asset for the host platform, and places the executable at a chosen
path — its maintainer states the scope precisely: "it downloads binaries from
GitHub or GitLab releases ... it handles single-file executables like those
created by most Go and Rust projects"
(https://raw.githubusercontent.com/houseabsolute/ubi/HEAD/README.md,
2026-09-05). Observable criterion: adding a Go-distributed tool to the template
adds one row to the tool table and zero files. Architectural alternative
considered: leave the residue **unprovisioned locally** and let CI install it
(ts's D-014 shape — `actionlint` is advisory-only inside ts `Justfile:83`).
That is genuinely viable for a lint that only ever gates CI, and it is this
member's ranked runner-up.

##### Dominant choice
There is **no dominant choice in the Rust field for this slot** — that is the
measured finding, not an evasion: 0 of 17 surveyed repositories provision a
foreign-language tool through any shared mechanism, and the two that provision
one at all use a JavaScript package manager this template does not have. The
strongest *available* candidate is `ubi`. Figures,
`GET https://crates.io/api/v1/crates/ubi` (2026-09-05):
`crate.recent_downloads` **80668**, `crate.downloads` **299735**.
`GET https://crates.io/api/v1/crates/ubi/versions` (2026-09-05): newest
unyanked `num` **0.12.0**, `created_at` **2026-08-31T03:45:16.743966Z**,
`license` **MIT OR Apache-2.0**, `rust_version` **1.88**.
`GET https://api.github.com/repos/houseabsolute/ubi` (2026-09-05):
`stargazers_count` **594**, `archived` **false**, `pushed_at`
**2026-09-05T13:52:55Z**.
`GET https://api.github.com/search/issues?q=repo:houseabsolute/ubi+is:issue+is:open`
(2026-09-05): `total_count` **11**. Issue responsiveness, 10 most recently
created issues (2026-01-24 to 2026-08-07): median days to first maintainer
response **4.08**, unanswered **1**. Advisories:
`https://rustsec.org/packages/ubi.html` HTTP **404** (2026-09-05).
Maintenance state: **active** — released 5 days before retrieval, pushed on the
retrieval date, single-digit open issue count, measurable response median.

##### Qualified shortlist
| Candidate | 90-day / all-time downloads | Newest unyanked | Licence | `rust_version` | Stars | `pushed_at` | Open issues | Maintenance |
|---|---|---|---|---|---:|---|---:|---|
| `ubi` | 80668 / 299735 | 0.12.0, 2026-08-31 | MIT OR Apache-2.0 | 1.88 | 594 | 2026-09-05T13:52:55Z | 11 | **active** |
| per-tool vendor script (py's pattern) | inapplicable — not a package | inapplicable | inapplicable | inapplicable | n/a | n/a | n/a | inapplicable (no upstream to assess) |
| CI-only via `taiki-e/install-action` | inapplicable — a GitHub Action, not a crate | action releases, `pushed_at` 2026-09-06T03:40:12Z | Apache-2.0 | n/a | 537 | 2026-09-06T03:40:12Z | not measured (code-search rate limit) | **active** |
| `mise` | 9303 / 443084 | 2026.9.1, 2026-09-02 | MIT | 1.95 | 33517 | 2026-09-06T04:34:49Z | 26 | **active** (fully assessed in member 4) |

Crate figures are marked **inapplicable** for the two non-crate candidates with
the reason stated, per the prompt's instruction; the reverse-dependency
*Adopters* rule is likewise **inapplicable to every candidate in this bundle**,
because no project depends on a developer-tool binary as a library — the
seventeen-repository configuration survey substitutes for it throughout this
report.

##### Excluded by gate
- **Per-tool vendor script (`scripts/install-<tool>.sh`) — excluded by principle, not by gate.** It reintroduces exactly the per-tool code this item exists to remove, and py's own two scripts are the evidence of the maintenance cost. No gate applies: it is shell, not a crate.
- **`mise` for this slot — excluded by fit.** Adopting a whole polyglot version manager to fetch one Go binary is disproportionate, and it would contradict member 4's finding. It passes gates 1 (MIT) and 3 (no RustSec page, HTTP 404, 2026-09-05); gate 2 is **inapplicable** for a prebuilt install and would be the binding constraint only if built from source, where its declared `rust_version` **1.95** is the highest of any candidate in this bundle.
- **Gate 1 for `ubi`: passes** — `MIT OR Apache-2.0` is exactly this template's licence, so even under the strictest reading of gate 1 there is no question, which is one reason it is preferred here over any GPL-licensed fetcher.
- **Gate 2 for `ubi`:** **inapplicable** for a prebuilt install (no compilation on the contributor's machine). For a source install its declared `rust_version` **1.88** is the floor; that is a *development-channel* question, not an `msrv-policy` question, for the reason given in member 2, and 1.88 sits below every `channel` value observed in the surveyed field (lowest: `helix` 1.90.0).
- **Gate 3:** no RustSec page for `ubi` (HTTP 404, 2026-09-05). `unsafe` posture: not separately audited and **not asserted**; as a separate process it cannot violate the template's memory safety. Its real risk is that it downloads and executes third-party release assets, which is inherent to the slot and equally true of a `curl | sh` vendor script — `ubi` at least centralises it in one auditable tool.
- **Gate 4 (OS):** the maintainer documents Linux, macOS, FreeBSD and NetBSD bootstrap scripts and Windows support (https://raw.githubusercontent.com/houseabsolute/ubi/HEAD/README.md, 2026-09-05); both required runners covered.
- **Gate 5:** inapplicable — nothing linked, no async-runtime coupling with the template.
- **Gate 6:** zero binary-size and zero compile-time cost to the template's artifact; one prebuilt download for the contributor.

##### Up-and-comers
`ubi` is itself the up-and-comer in this slot (0.12.0, 2026-08-31; 80668
90-day downloads against 299735 all-time, so roughly a quarter of its lifetime
downloads occurred in the last quarter — a growth signal, computed from the two
crates.io fields, 2026-09-05). Its maintainer publishes an explicit caveat that
counts as evidence *against* this recommendation and is reported for that
reason: "If you want to manage per-project tooling, I strongly recommend using
mise instead of ubi. But if you just want a simple tool for globally installing
tools ... then ubi is a good choice"
(https://raw.githubusercontent.com/houseabsolute/ubi/HEAD/README.md,
2026-09-05). That caveat is why `ubi` is recommended here as a *global
install-if-missing backend behind one recipe*, which is the use its maintainer
endorses, and not as a per-project version pin, which is the use he steers
away from.

##### Fit for this template
Fit is dominated by one fact: **the template ships zero non-crates.io dev tools
by default under this recommendation.** The Rust equivalents of py's residue
are crates (`taplo-cli`, `typos-cli`, and cargo-published secret scanners) and
therefore land in member 2. The one likely exception is `lefthook`, whose
distribution is explicitly R37's (F143/F144/F174) and out of scope here. So
this member's job is to name the sanctioned backend *in advance*, so that R37,
R39 or R40 can add a row to the tool table rather than invent a second
mechanism. On the `ubuntu-latest, macos-latest` matrix `ubi` covers both.

##### Recommendation
Name `ubi` as the single sanctioned backend for a tool distributed only as a
GitHub/GitLab release, wired into the **same** `install-tool` recipe through a
second spec form (for example `gh:<owner>/<repo>` versus a bare crate name), and
ship **zero** such tools in the template's default tool table. Add a standing
rule to the template's contributor documentation: *prefer a crates.io-published
tool when one exists; a release-only tool must justify itself.* If R37 chooses
to install `lefthook` locally, this is the mechanism it should use.

##### Ranked runner-up
Rank 2: **the ts pattern** — no local provisioning at all; the tool is advisory
in `check-deps` and CI installs it with `taiki-e/install-action` (measured as
the dominant CI mechanism: 10 hits in `zed`, 6 in `biome`, 5 in `uv`, 4 in
`oxc`, 2026-09-05). Correct for a tool that only ever gates CI, such as
`actionlint`. Rank 3: a per-tool vendor script (py's pattern), rejected above.
Rank 4: `mise`, rejected in member 4.

##### Tradeoffs
`ubi` adds a second acquisition backend that must be bootstrapped before it can
fetch anything, and it is a 594-star tool rather than a first-party one — the
smallest maintenance base in the recommended stack. Against that, it is
`MIT OR Apache-2.0`, actively maintained, and it keeps the residue inside one
generic recipe instead of `N` shell scripts. If the residue truly stays empty,
the cost is one documented spec form and no runtime cost at all. The honest
alternative reading is that a slot with zero occupants should have no
mechanism; the counter-argument is that R37, R39 and R40 will each face this
question independently and, without a named answer, will each answer it
differently.

##### Parameters
Contributes to `package-manager-invocation`: a release-fetched tool has a plain
executable name, so it is invoked as a **bare `PATH` binary** — never
`ubi run <tool>` and never any other prefix. `ubi`'s role ends at install time,
which is precisely why it does not perturb the parameter. Assumes the four
fixed parameters unchanged. No `CONFLICT:` line.

##### Migration implications
`Justfile`: one additional spec form understood by the existing `install-tool`
recipe; no new recipe and no new file. `scripts/install-gitleaks.sh` and
`scripts/install-actionlint.sh` are **not** ported. `CONTRIBUTING`-level
documentation gains the prefer-a-crate rule. If R37 lands `lefthook` here, one
row is added to the tool table.

##### Validation strategy
**Proposed, not executed** (it would write a binary into the owner's `PATH`):
on `ubuntu-latest` and `macos-latest`, `ubi --project <owner>/<repo> --in ./bin`
followed by `./bin/<tool> --version` (both flags read from the maintainer's
options table: `-p, --project <project>` "The project you want to install" and
`-i, --in <in>` "The directory in which the binary should be placed. Defaults
to ./bin", https://raw.githubusercontent.com/houseabsolute/ubi/HEAD/README.md,
2026-09-05), then `just check-deps` reporting the tool
present. **Executed** on this host, 2026-09-05: the generic `check-deps` loop
already treats a bare-binary tool identically to a cargo plugin — `ok taplo`
and `ok typos` were produced by the same `command -v` branch that reported
`MISSING cargo-nextest`, which is the property that lets one recipe serve both
backends.

##### Confidence & re-verify trigger
Confidence **medium**. The mechanism and the licence are certain; what is
uncertain is whether this slot ever acquires an occupant, since that depends on
R37, R39 and R40. Confidence in the *policy* (prefer a crate; one backend if
not) is **high**. Re-verify when R37, R39 or R40 selects a tool that is not on
crates.io, if `ubi` goes six months without a release *and* shows a second
at-risk signal, or by 2027-03-05.

##### Sources
GET https://crates.io/api/v1/crates/ubi and /versions (2026-09-05) ·
GET https://api.github.com/repos/houseabsolute/ubi (2026-09-05) ·
GET https://api.github.com/search/issues?q=repo:houseabsolute/ubi+is:issue+is:open
(2026-09-05) · https://rustsec.org/packages/ubi.html (2026-09-05, HTTP 404) ·
https://raw.githubusercontent.com/houseabsolute/ubi/HEAD/README.md (2026-09-05) ·
GET https://api.github.com/repos/taiki-e/install-action (2026-09-05) ·
GET https://api.github.com/search/code?q=repo:<o>/<r>+taiki-e/install-action
(2026-09-05) · https://raw.githubusercontent.com/biomejs/biome/HEAD/justfile,
https://raw.githubusercontent.com/oxc-project/oxc/HEAD/justfile (2026-09-05) ·
GET https://crates.io/api/v1/crates/mise and /versions (2026-09-05) ·
py `Justfile:476`, `Justfile:482`, `scripts/install-gitleaks.sh`,
`scripts/install-actionlint.sh`; ts `Justfile:83` (as cited in the prompt's
`## Context`).

#### Declarative provisioner manifest — none adopted (mise, flox and Nix evaluated)

##### Landscape
This member decides F187 (a `mise.toml`), F188 (a `.flox/env/manifest.toml`)
and F189 (three provisioners kept in manual sync). Bin placement: **built-in /
first-party** — none; Rust has no first-party provisioner manifest beyond
`rust-toolchain.toml` (member 1) and `Cargo.toml`, and those two already
declare everything a Rust project provisions; **established industry
standard** — Nix flakes (`flake.nix`), the only declarative environment
mechanism with measurable adoption in the surveyed field; **up-and-comer** —
`mise`, `flox`, `devenv`, `devbox`, `asdf`. The decisive practice evidence is
the survey table in the report-level `Landscape`: across 17 widely adopted Rust
repositories totalling over 800000 GitHub stars, **`mise.toml` appears 0 times,
`.mise.toml` 0 times, `.tool-versions` 0 times, `.flox` 0 times**, and
`flake.nix` appears **5** times (`denoland/deno`, `zed-industries/zed`,
`helix-editor/helix`, `casey/just`, `rust-lang/rustup`). All from
`GET https://api.github.com/repos/<o>/<r>/contents/`, 2026-09-05.

##### Principles and implementation
Principle at stake: *the declared tool set has exactly one authoritative
location.* py violates it structurally and says so in its own header —
`mise.toml:1` describes the file as "one of the project's three first-class dev
environments ... keep them in sync" (prompt `## Context`). Three locations with
a comment as the only enforcement is a consistency obligation with no
mechanism; F189 is that obligation. The architectural question is therefore not
"mise or flox" but "does this template have a problem that a provisioner
manifest solves". py's problem was a genuinely polyglot toolchain: its
`mise.toml` `[tools]` block pins `python`, `uv`, `ruff`, `taplo`, `gitleaks`,
`just`, `bun`, `gh`, `lefthook`, `make` and `actionlint` (prompt `## Context`,
py `mise.toml:23`) — two language runtimes plus nine CLIs. This template's
equivalent list is: a Rust toolchain (declared in `rust-toolchain.toml`), a set
of crates.io tools (declared in the Justfile tool table and installable by one
recipe), and `just` itself (a Level-1 bootstrap tool, F179). A manifest would
restate all three. Observable criterion for the recommendation: adding a tool
to the template requires editing exactly **one** list, and `grep -rl` for a
provisioner manifest in the repository returns nothing.

##### Dominant choice
**None.** The dominant practice in the Rust field, measured, is to carry no
declarative provisioner manifest at all: 17 of 17 surveyed repositories carry
no `mise.toml`, `.mise.toml`, `.tool-versions` or `.flox`
(`GET https://api.github.com/repos/<o>/<r>/contents/`, 2026-09-05). Because the
recommendation is the absence of a package, the crate figures for a "dominant
choice" are **inapplicable** and the substitute evidence is that survey. The
runner-up field's figures are given in full below so the synthesizer can weigh
the alternative on its own numbers rather than on this member's conclusion.

##### Qualified shortlist
| Candidate | 90-day / all-time downloads | Newest unyanked | Licence | `rust_version` | Stars | `archived` | `pushed_at` | Open issues | Advisories | Maintenance |
|---|---|---|---|---|---:|---|---|---:|---|---|
| no manifest (recommended) | inapplicable — not a package | inapplicable | inapplicable | inapplicable | n/a | n/a | n/a | n/a | inapplicable | inapplicable |
| Nix flake (`flake.nix`) | inapplicable — Nix is not a crate | inapplicable | LGPL-2.1 (Nix itself: `https://raw.githubusercontent.com/NixOS/nix/HEAD/COPYING` reads "GNU LESSER GENERAL PUBLIC LICENSE Version 2.1, February 1999", 2026-09-05; no gate applies to a build system executed as a separate process) | inapplicable | n/a | n/a | n/a | n/a | inapplicable | **active** (5 of 17 surveyed repos carry one) |
| `mise` (`jdx/mise`) | 9303 / 443084 | 2026.9.1, 2026-09-02T12:30:37Z | MIT | 1.95 | 33517 | false | 2026-09-06T04:34:49Z | 26 | none (HTTP 404) | **active** |
| `flox` (`flox/flox`) | **not on crates.io** — `GET https://crates.io/api/v1/crates/flox` returns `{"errors":[{"detail":"crate \`flox\` does not exist"}]}` | inapplicable via crates.io | **GPL-2.0** (GitHub `license.spdx_id`) | inapplicable | 4121 | false | 2026-09-06T03:19:24Z | 381 | inapplicable (no crates.io package) | **active** |

All figures 2026-09-05, from `GET https://crates.io/api/v1/crates/<name>` and
`/versions`, `GET https://api.github.com/repos/<o>/<r>`, and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`.
`mise` advisories: `https://rustsec.org/packages/mise.html` HTTP 404
(2026-09-05). **Issue responsiveness for `jdx/mise` could not be measured by
the prescribed method and is reported as unmeasured, not as good or bad:** the
first 300 items returned by
`GET /repos/jdx/mise/issues?state=all&sort=created&direction=desc&per_page=100`
(pages 1-3, 2026-09-05) are all pull requests, and
`GET /search/issues?q=repo:jdx/mise+is:issue&sort=created&order=desc` returns
`"items": []` alongside `"total_count": 1570`. What was verified: 26 open
issues against 1570 total issues (2026-09-05). Responsiveness for `flox/flox`
was likewise not sampled.

##### Excluded by gate
- **`mise` — not excluded by any gate; excluded by fit and by principle.** Gate 1: passes (MIT). Gate 2: **inapplicable** for a prebuilt install; its declared `rust_version` **1.95** is the highest in this bundle and would bind only a source build. Gate 3: no RustSec page (HTTP 404, 2026-09-05); `unsafe` posture **not asserted** — separate process, no linkage. Gate 4: cross-platform, both required runners covered. Gate 5: inapplicable, nothing linked. Gate 6: zero artifact cost. It is excluded because (i) measured adoption for this role in the surveyed Rust field is 0 of 17, (ii) the tool list it would declare is already declared by `rust-toolchain.toml` and the Justfile tool table, and (iii) adding it *alongside* the native path recreates F189's unenforced sync obligation.
- **`flox` — excluded by fit, with two additional concrete marks against it.** (i) It is not published on crates.io at all, so a Rust-template contributor acquires it entirely outside the toolchain they already have. (ii) Its licence is **GPL-2.0** (`GET https://api.github.com/repos/flox/flox`, `license.spdx_id`, 2026-09-05) — like `cargo-binstall` this is a separate-process tool so gate 1 does not bar it (https://www.gnu.org/licenses/gpl-faq.html#MereAggregation, 2026-09-05), but where a same-role alternative is `MIT OR Apache-2.0` or first-party, the GPL tool has no compensating advantage. (iii) It is a Nix frontend, so anything it offers is available more directly from `flake.nix`, which has 5 of 17 measured adoption against `flox`'s 0.
- **Nix flake — not excluded by gate; not recommended, but ranked first among alternatives.** No licence, advisory or OS gate applies to a build-environment description. It is the only alternative with real Rust-field adoption. It is not recommended for a *template* because it makes a Nix installation a precondition for every downstream consumer and forces an environment prefix into every recipe and hook line.
- **`asdf`, `devenv`, `devbox` — excluded on evidence.** Zero occurrences in the survey; `devenv` and `devbox` additionally have crates.io namesakes that are unrelated projects (member 1's `Up-and-comers`), so no crates.io figure can be used for them.

##### Up-and-comers
`mise` is the live up-and-comer overall — 33517 stars, releasing on a
calendar-version cadence (2026.9.1 on 2026-09-02) — and this member's verdict
is explicitly *not* a judgement that `mise` is a poor tool. It is a judgement
that a Rust-only template has nothing for it to declare. Note the direction of
travel worth re-checking later: `mise`'s crates.io figures (9303 90-day
downloads) understate it badly, because it is distributed mainly through its
own installer and OS package managers, so the honest adoption signal is its
33517 stars plus the survey's zero — two figures that point in opposite
directions and are both reported here rather than reconciled by assertion.

##### Fit for this template
The template is Rust-only: no second language runtime to pin, no `bun`, no
`uv`, no `python`. Its Level-1 set is a Rust toolchain plus `just`; its Level-2
set is crates.io tools. A provisioner manifest would restate `rust-toolchain.toml`
and the Justfile tool table in a third syntax, and its only unique contribution
would be pinning `just` itself — which is a Level-1 bootstrap concern (F179)
that a Level-2 manifest cannot solve anyway, because reading the manifest
requires the provisioner to already be installed. Against py: this deletes
three files and one unenforceable sync rule. Against ts: it reaches the same
end state (no manifest) without ts's capability deletions.

##### Recommendation
Adopt **no** declarative provisioner manifest. Settle **F187** (mise) and
**F188** (flox) as *not adopted*, and **F189** (three provisioners in manual
sync) as *not adopted*, so the manual-sync obligation never exists. Note for
the ledger, since the closed verdict set in `docs/port/README.md` must still be
applied by the controller: the closest legal verdict for these three `py-only`
rows is `OMIT` on the ground that the *need* they serve — pinning a
Python + Node + CLI mix — has no Rust analogue, rather than on the ground that
the tools lack Rust analogues (they do not). **This report proposes the
decision, not the ledger verdict string.** If the owner later wants a hermetic
option, it should be exactly **one** file and it should be `flake.nix`, on the
5-versus-0 adoption evidence, added as an optional convenience that no recipe
depends on.

##### Ranked runner-up
Rank 2: a single `flake.nix`, optional and depended on by nothing. Rank 3: a
single `mise.toml` and no flox manifest — strictly better than py's three-way
split because it removes the sync obligation, still unjustified by the evidence.
Rank 4: py's pattern reproduced (native plus `mise.toml` plus
`.flox/env/manifest.toml`), rejected: it is the only option that guarantees the
consistency defect.

##### Tradeoffs
What is given up: a one-command hermetic environment, and a single file a new
contributor could point a provisioner at. What is gained: one authoritative
tool list instead of three, no third-party provisioner in the critical path of
contributing, no GPL-2.0 or 1.95-MSRV tool in the bootstrap, and recipes with
no environment prefix. The risk if this is wrong is small and cheap to reverse:
adding a `flake.nix` or `mise.toml` later is additive and breaks nothing,
whereas removing one after downstream users depend on it is not.

##### Parameters
Contributes decisively to `package-manager-invocation`: because no provisioner
is adopted, **no recipe or hook line carries a provisioner prefix** — no
`mise exec --`, no `flox activate --`, no `nix develop -c`. That prohibition is
written into the parameter value so that R27, R28, R29, R32, R37 and R40 cannot
each reintroduce one. Assumes the four fixed parameters unchanged. No
`CONFLICT:` line.

##### Migration implications
`mise.toml` is **not** created (py `mise.toml:23`, `mise.toml:1` have no
analogue). `.flox/env/manifest.toml` is **not** created (py
`.flox/env/manifest.toml:14` has no analogue). No `flake.nix` is created. The
tool table in `Justfile` is the single authoritative list. `README` /
`CONTRIBUTING` states that the template deliberately has one provisioning path.

##### Validation strategy
**Executed** as a repository-shape check rather than a command: the survey
across 17 repositories found zero provisioner manifests
(`GET https://api.github.com/repos/<o>/<r>/contents/`, 2026-09-05), which is
the evidence the recommendation rests on. **Proposed** as a standing template
check, suitable for the drift guard R15 owns: assert that
`mise.toml`, `.mise.toml`, `.tool-versions` and `.flox/` are absent, so a later
contributor cannot reintroduce a second tool list without an explicit decision.
**Proposed** acceptance: adding one tool to the template requires exactly one
edited file; verify by diffing a branch that adds a tool.

##### Confidence & re-verify trigger
Confidence **high** — the 0-of-17 measurement is unambiguous and the principle
argument (one authoritative list) is independent of it. Re-verify if the
template ever gains a second language runtime (a Node-based docs pipeline, a
Python script suite), if a repeat of the 17-repository survey shows provisioner
manifests appearing in a material fraction, or by 2027-03-05.

##### Sources
GET https://api.github.com/repos/<o>/<r>/contents/ for all 17 surveyed
repositories (2026-09-05; per-repository results in the report-level
`Landscape` table) · GET https://crates.io/api/v1/crates/mise and /versions
(2026-09-05) · GET https://api.github.com/repos/jdx/mise (2026-09-05) ·
GET https://api.github.com/search/issues?q=repo:jdx/mise+is:issue+is:open and
...+is:issue (2026-09-05) · https://rustsec.org/packages/mise.html (2026-09-05,
HTTP 404) · GET https://crates.io/api/v1/crates/flox (2026-09-05, "crate `flox`
does not exist") · GET https://api.github.com/repos/flox/flox (2026-09-05) ·
GET https://api.github.com/search/issues?q=repo:flox/flox+is:issue+is:open
(2026-09-05) · GET https://crates.io/api/v1/crates/devenv and /devbox
(2026-09-05) · https://raw.githubusercontent.com/NixOS/nix/HEAD/COPYING
(2026-09-05) · https://www.gnu.org/licenses/gpl-faq.html#MereAggregation
(2026-09-05, HTTP 200) · `docs/port/README.md` verdict vocabulary; py
`mise.toml:1`, `mise.toml:23`, `.flox/env/manifest.toml:14` (as cited in the
prompt's `## Context`).

#### Invocation surface — Justfile recipes and lefthook jobs (package-manager-invocation)

##### Landscape
This member is the owned parameter. It decides the literal text every consumer
item (R27, R28, R29, R32, R37, R40) writes on a recipe or hook line. Bin
placement: **built-in / first-party** — Cargo's custom-subcommand dispatch
(`cargo <name>` to `cargo-<name>` on `$PATH`) and the rustup proxies that make
`cargo fmt` and `cargo clippy` work; **established industry standard** — `just`
as the recipe surface holding those lines, with bare `PATH` binaries for
non-plugin tools; **up-and-comer** — wrapper-prefix forms: `cargo bin <tool>`
(`cargo-run-bin`), `mise exec -- <tool>`, `nix develop -c <tool>`, plus the
in-repo alternatives `cargo xtask` and `cargo-make`. Practice evidence, read
from the actual files (`https://raw.githubusercontent.com/<repo>/HEAD/justfile`,
2026-09-05): **all four** surveyed repositories with a `justfile` use the
split form and **none** uses a wrapper prefix — `oxc`'s `ready` recipe runs
`typos` (bare) next to `cargo lintgen` and `cargo ck`; `just`'s own `ci` recipe
runs `cargo fmt --all -- --check` and `cargo lclippy` next to a `shellcheck`
recipe invoking `shellcheck` bare; `biome` runs `cargo run -p xtask_codegen`
and `cargo binstall`; `cargo-binstall`'s justfile runs `cargo`, `cross`,
`cargo-zigbuild` and `cargo-nextest` directly.

##### Principles and implementation
Principle: a tool's invocation name must be stable under a change of
acquisition backend, so that changing *how* a tool is installed never edits a
recipe or a hook. Mechanism, and the reason the split is not arbitrary: the
Cargo book specifies that "a cargo invocation of the form `cargo
(?<command>[^ ]+)`" is translated "into an invocation of an external tool
`cargo-${command}`", and that "the external tool must be present in one of the
user's `$PATH` directories"
(https://doc.rust-lang.org/cargo/reference/external-tools.html, 2026-09-05). So
`cargo <sub>` is *itself* a `PATH` lookup with a prefix; the two halves of the
rule are one mechanism, not two conventions. Two things follow that matter for
this bundle. First, `command -v cargo-<sub>` is a correct presence test for a
cargo plugin, which is why F181's `command -v` loop survives intact. Second,
the `cargo` prefix is what makes `cargo +<toolchain> <sub>` and
`rust-toolchain.toml` resolution work for the tool, so dropping the prefix for
a cargo-native tool would silently lose toolchain pinning. Observable
criterion: no recipe or hook line contains `mise exec`, `cargo bin`,
`nix develop -c`, `flox activate` or any equivalent prefix; every line names
either `cargo <sub> ...` or `<tool> ...`.

##### Dominant choice
The **split rule**: `cargo <sub>` when the executable is `cargo-<sub>`, a bare
`PATH` binary otherwise. Its carrier is `just`. Figures for `just`,
`GET https://crates.io/api/v1/crates/just` (2026-09-05):
`crate.recent_downloads` **509598**, `crate.downloads` **2515825**.
`GET https://crates.io/api/v1/crates/just/versions` (2026-09-05): newest
unyanked `num` **1.58.0**, `created_at` **2026-08-03T20:29:15.411846Z**,
`license` **CC0-1.0**, `rust_version` **1.89.0**.
`GET https://api.github.com/repos/casey/just` (2026-09-05):
`stargazers_count` **35655**, `archived` **false**, `pushed_at`
**2026-09-01T20:47:57Z**.
`GET https://api.github.com/search/issues?q=repo:casey/just+is:issue+is:open`
(2026-09-05): `total_count` **171**. Issue responsiveness, 10 most recently
created issues (2026-08-06 to 2026-09-01): median days to first maintainer
response **0.37**, unanswered **0**. Advisories:
`https://rustsec.org/packages/just.html` HTTP **404** (2026-09-05).
Maintenance state: **active**. Cargo's dispatch mechanism itself is
first-party and its figures are **inapplicable** (it is part of the toolchain,
not a separately released package).

##### Qualified shortlist
| Candidate invocation form | Carrier | 90-day / all-time downloads | Newest unyanked | Licence | Stars | `pushed_at` | Open issues | Responsiveness | Maintenance |
|---|---|---|---|---|---:|---|---:|---|---|
| `cargo <sub>` + bare `PATH` binary (recommended) | `just` | 509598 / 2515825 | 1.58.0, 2026-08-03 | CC0-1.0 | 35655 | 2026-09-01T20:47:57Z | 171 | median 0.37 d, 0 unanswered | **active** |
| `cargo xtask <task>` (tasks compiled in-repo) | Cargo | inapplicable — a convention over first-party Cargo | inapplicable | Apache-2.0 OR MIT | n/a | n/a | n/a | inapplicable | **active** (2 of 17 surveyed repos: `biome`, `helix`) |
| `cargo make <task>` | `cargo-make` | 247452 / 3656150 | 0.37.24, 2025-01-18T15:20:30Z | Apache-2.0 | 2950 | 2026-02-05T18:50:48Z | 64 | 9 of 9 sampled issues unanswered (2025-11-04..2026-07-16), median unmeasurable | **at-risk** |
| `cargo bin <tool>` (wrapper prefix) | `cargo-run-bin` | 79263 / 287839 | 1.7.5, 2025-07-14 | MIT | 236 | 2025-12-19T02:30:12Z | 7 | median 121.91 d, 4 unanswered | **at-risk** |
| `mise exec -- <tool>` (wrapper prefix) | `mise` | 9303 / 443084 | 2026.9.1, 2026-09-02 | MIT | 33517 | 2026-09-06T04:34:49Z | 26 | unmeasurable by the prescribed method (see member 4) | **active** |

All figures 2026-09-05 from the endpoints named in the prompt's evidence table.
RustSec: HTTP 404 for `just`, `cargo-make`, `cargo-run-bin` and `mise`
(2026-09-05). `cargo-make`'s **at-risk** verdict rests on concrete signals, not
on elapsed time alone: last release 2025-01-18 (about 19 months before
retrieval), last push 2026-02-05 (about 7 months), and **9 of 9** sampled
issues with no maintainer response, spanning 2025-11-04 to 2026-07-16.

##### Excluded by gate
- **`cargo bin <tool>` (`cargo-run-bin`) — excluded.** Fit: a wrapper prefix on every invocation line is exactly what this parameter must prevent, because it would propagate into six consumer items' recipes and hooks and make the tool list a second authority. Maintenance: **at-risk** (signals above). Gates 1 (MIT) and 3 (no advisory page) pass; gate 2 is **inapplicable** for a prebuilt install; gates 5 and 6 are **inapplicable** (nothing linked).
- **`mise exec -- <tool>` — excluded**, following member 4: adopting no provisioner makes a provisioner prefix impossible. Gate 1 passes (MIT); gate 3 passes (HTTP 404); gate 2 **inapplicable** prebuilt, `rust_version` 1.95 if built from source.
- **`cargo make <task>` — excluded on maintenance and on scope.** **At-risk** as evidenced above, and it replaces `just` rather than the invocation form, which is a decision F179/F176 already settled outside this item. Gate 1 passes (Apache-2.0, compatible). Gate 3: no advisory page (HTTP 404, 2026-09-05).
- **`cargo xtask <task>` — not excluded by gate; retained as the ranked runner-up.** It is first-party, licence-free of any question, and genuinely used (`biome`, `helix`). It is not recommended because it converts every recipe into compiled Rust, adds a build step before any check can run on a cold clone, and does not remove the need to name external tools — inside an `xtask` the same split rule reappears as `Command::new("cargo").arg("fmt")` versus `Command::new("taplo")`.
- **`just` itself, gate 1:** licence **CC0-1.0** — a public-domain dedication, which its README describes as "the maximally permissive CC0 public domain dedication and fallback license" (https://raw.githubusercontent.com/casey/just/HEAD/README.md, 2026-09-05). Compatible with `MIT OR Apache-2.0` under any reading, and in any case `just` is a separate-process tool, not a dependency.
- **Gates 2, 5, 6 for the recommended form:** gate 2 **inapplicable** — the invocation form compiles nothing; `just`'s own `rust_version` 1.89.0 binds only a source install of `just`, which is a Level-1 bootstrap concern (F179), not an `msrv-policy` concern. Gate 5 **inapplicable** — no linkage, no async-runtime coupling; this parameter is therefore independent of R05's execution-model decision. Gate 6 **inapplicable** to the artifact — zero binary-size and zero compile-time cost, because an invocation form adds no code.
- **Gate 4 (OS):** the recommended form works identically on `ubuntu-latest` and `macos-latest`; `just`'s own justfile shows it also handles Windows shells (`set windows-shell`, `set windows-powershell` in `oxc` and `biome`), which is noted, not required.

##### Up-and-comers
`cargo-run-bin` is the notable architectural entrant — declaring dev tools in
`Cargo.toml` `[package.metadata.bin]` would put the tool table in a file that
already exists, which is attractive against this bundle's single-list
principle. It is rejected on the prefix and on maintenance, but it is the one
candidate worth re-checking at the next review: if it acquired a mode that
placed binaries on `PATH` rather than requiring `cargo bin`, it would satisfy
both this parameter and member 2 at once.

##### Fit for this template
The template's three shapes (CLI, library, web service) do not change the
invocation form, which is why one rule can serve all six consumer items. What
does matter is the *number* of consumers: R27, R28, R29, R32, R37 and R40 each
write recipe and hook lines. A rule they can apply mechanically, without
re-deriving it, is worth more than a marginally better rule they must
interpret. The split rule is mechanical: look at the executable's name. Against
py: py's Justfile mixes `uv run <tool>` (a package-manager run-wrapper) with
bare binaries; the Rust template has no `uv run` analogue, and this parameter
forbids inventing one. Against ts: ts folds tools into one formatter and
invokes it directly, which is the same bare-binary half of this rule.

##### Recommendation
`package-manager-invocation` = **a cargo subcommand (`cargo <sub>`) for any tool
whose executable is named `cargo-<sub>` — including the rustup components
rustfmt and clippy, invoked as `cargo fmt` and `cargo clippy`; a bare `<tool>`
binary resolved on `PATH` for every other tool; and no provisioner, runner or
package-manager prefix (`mise exec`, `cargo bin`, `nix develop -c`,
`flox activate`, or any `uv run` analogue) in any Justfile recipe or lefthook
job.** Presence is tested with `command -v <executable>`, where the executable
is `cargo-<sub>` for the first class and `<tool>` for the second. Tool names
above are illustrations of the two classes only; which tools the template
ships is decided by R27, R28, R29, R32, R37 and R40.

##### Ranked runner-up
Rank 2: `cargo xtask <task>` for the task surface, with the same split rule
applied inside the xtask's `Command` invocations. It trades `just` as a
bootstrap dependency for a compile step, and it keeps the parameter's substance
intact — which is the useful property: the parameter survives even if F176/F179
later replace `just`. Rank 3: `cargo make`. Rank 4: any wrapper-prefix form.

##### Tradeoffs
The split rule requires a contributor to know which class a tool is in, but the
test is mechanical and visible in the tool table. Bare `PATH` invocation means
a recipe silently uses whatever version of a tool is on `PATH`, with no pinning
at the call site — the mitigation is the pinned `name@version` spec in the tool
table plus `check-deps`, not a wrapper prefix, and this is the one place where
`cargo bin`'s rejected design is genuinely better. The `cargo <sub>` half
inherits toolchain resolution automatically, which is a real benefit the bare
form does not have and the reason the rule is split rather than uniform.

##### Parameters
`owns package-manager-invocation` = the value stated under `Recommendation`
above. Consumed by R27, R28, R29, R32, R37 and R40. Assumes
`rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions, raised
only in a minor release, declared as rust-version in Cargo.toml and tested in
CI`, `target-os-matrix = ubuntu-latest, macos-latest`,
`license = MIT OR Apache-2.0` — all four unchanged. **No `CONFLICT:` line:**
R42 consumes no parameter, and nothing in this recommendation requires a
registered value to change.

##### Migration implications
`Justfile`: every check recipe reads `cargo fmt --all -- --check`,
`cargo clippy --all-targets --all-features -- -D warnings`, `<tool> ...` for
non-plugin tools. `lefthook.yml`: every job's `run:` uses the same two forms.
`check-deps`: one loop over the tool table using `command -v`. Nothing anywhere
uses a wrapper prefix. Consumer items R27, R28, R29, R32, R37 and R40 take this
rule as given and do not restate it.

##### Validation strategy
**Executed** on this host, 2026-09-05, all four checks: (1) `cargo fmt
--version` returned `rustfmt 1.9.0` and `cargo clippy --version` returned
`clippy 0.1.98` through the rustup proxy, proving the cargo-subcommand half for
rustup components; (2) a stub executable `cargo-demo` placed on `PATH` and
invoked as `cargo demo --flag 1` printed `cargo-demo invoked argv: demo --flag
1`, proving the Cargo book's dispatch contract literally and proving that
`command -v cargo-<sub>` is the right presence test; (3) `just check-deps` over
a mixed table printed `MISSING cargo-nextest -> RUN ...`, `ok taplo`, `ok
typos` and exited 1, proving one loop serves both classes; (4) `just --version`
reported `just 1.57.0` as the carrier. **Proposed, not executed:** the same
recipes run in CI on `ubuntu-latest` and `macos-latest`, plus a grep-based
guard asserting that no `Justfile` or `lefthook.yml` line matches
`mise exec|cargo bin |nix develop|flox activate`.

##### Confidence & re-verify trigger
Confidence **high**. The mechanism is specified by the Cargo book, executed
here directly, and observed unanimously in all four surveyed `justfile`s.
Re-verify if Cargo changes custom-subcommand dispatch, if F176/F179 replace
`just` with `xtask` (the rule survives but its wording should name the new
carrier), if any consumer item reports a tool that fits neither class, or by
2027-03-05.

##### Sources
https://doc.rust-lang.org/cargo/reference/external-tools.html (2026-09-05) ·
https://rust-lang.github.io/rustup/overrides.html (2026-09-05) ·
GET https://crates.io/api/v1/crates/just and /versions (2026-09-05) ·
GET https://api.github.com/repos/casey/just (2026-09-05) ·
GET https://api.github.com/search/issues?q=repo:casey/just+is:issue+is:open
(2026-09-05) · https://rustsec.org/packages/just.html (2026-09-05, HTTP 404) ·
https://raw.githubusercontent.com/casey/just/HEAD/README.md (2026-09-05) ·
GET https://crates.io/api/v1/crates/cargo-make and /versions,
/cargo-run-bin, /mise (2026-09-05) ·
GET https://api.github.com/repos/sagiegurari/cargo-make,
/dustinblackman/cargo-run-bin, /jdx/mise (2026-09-05) ·
https://raw.githubusercontent.com/oxc-project/oxc/HEAD/justfile,
/biomejs/biome/HEAD/justfile, /casey/just/HEAD/justfile,
/cargo-bins/cargo-binstall/HEAD/justfile (all 2026-09-05) ·
`docs/port/PARAMETERS.md` (`package-manager-invocation` consumers).

### Compatibility

The five members are not merely individually defensible; three independent
kinds of proof show they work together.

**1. A shared adopter that runs four of the five members simultaneously.**
`oxc-project/oxc` (22649 stars, `GET /repos/oxc-project/oxc`, 2026-09-05)
commits `rust-toolchain.toml` (member 1, `channel = "1.98.1"`,
`profile = "default"`, documented as adding "rust-docs, rustfmt, and clippy"
to the minimal set,
https://rust-lang.github.io/rustup/concepts/profiles.html, 2026-09-05), acquires its tools with one `cargo binstall` line in its `init`
recipe (member 2), carries no provisioner manifest of any kind (member 4), and
invokes tools with the split rule in its `ready` recipe — `typos` bare next to
`cargo ck` and `cargo lintgen` (member 5). `biomejs/biome` (25717 stars) is a
second independent instance of the same four:
`rust-toolchain.toml` at `channel = "1.98.0"`, an `install-tools` recipe whose
body is `cargo install cargo-binstall` then `cargo binstall ...`, no provisioner
manifest, and cargo-subcommand invocation throughout.
`cargo-bins/cargo-binstall` is a third: `rust-toolchain.toml` with
`channel = "stable"`, `profile = "minimal"`, `components = ["rustfmt",
"clippy"]` — the literal configuration member 1 recommends — plus a `justfile`
that invokes everything by the split rule. All read 2026-09-05 from
`https://raw.githubusercontent.com/<repo>/HEAD/{rust-toolchain.toml,justfile}`.

**2. A version matrix, executed on this host on 2026-09-05.** `rustc 1.98.0`
and `cargo 1.98.0` on `aarch64-apple-darwin`, `just 1.57.0`, with a
`rust-toolchain.toml` at `channel = "stable"`, `profile = "minimal"`,
`components = ["rustfmt", "clippy"]`: `rustup show active-toolchain` named the
file as the override source, `cargo fmt --version` gave `rustfmt 1.9.0`,
`cargo clippy --version` gave `clippy 0.1.98`, the generic `check-deps` recipe
ran and exited 1 with correct per-tool output, and `cargo demo` dispatched to a
`cargo-demo` stub on `PATH`. Members 1, 2 (its recipe half), 4 (by absence) and
5 therefore ran together in one directory. What was **not** executed is member
2's `cargo binstall` step and member 3's `ubi` fetch, because both write
binaries outside the working directory; those remain proposed.

**3. Interface compatibility, by construction.** The members compose through
exactly two contracts and nothing else. (a) *Every member terminates in an
executable on `PATH`* — rustup places component proxies there, `cargo binstall`
and `cargo install` place binaries in `$CARGO_HOME/bin`, `ubi` places one at a
chosen path. Member 5 therefore never needs to know which member installed a
tool, which is the property that makes the parameter stable if the backend
changes. (b) *Exactly one tool table exists*, in the `Justfile`; members 2 and
3 read spec strings from it and member 5 reads probe names from it. Member 4's
recommendation (no manifest) is what guarantees contract (b) has no second
authority. The one composition risk worth naming: Cargo prioritises
`$CARGO_HOME/bin` over the rest of `$PATH` for custom subcommands
(https://doc.rust-lang.org/cargo/reference/external-tools.html, 2026-09-05), so
a cargo plugin installed by `ubi` into a different directory could be shadowed
by an older copy in `$CARGO_HOME/bin` — which is a further reason member 3's
backend is reserved for **non**-crates.io tools, whose executables are never
`cargo-<sub>`.

### Parameters

- `owns package-manager-invocation` = "cargo subcommand (cargo <sub>) for any tool whose executable is named cargo-<sub>, including the rustup components rustfmt and clippy invoked as cargo fmt and cargo clippy; a bare <tool> binary resolved on PATH for every other tool; no provisioner, runner or package-manager prefix (mise exec, cargo bin, nix develop -c, flox activate, or any uv run analogue) in any Justfile recipe or lefthook job; presence tested with command -v <executable>."
- `assumes rust-edition = 2024` (fixed, owner-decided 2026-09-02).
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed). Used here only to establish what it does **not** govern: dev tools are not built by the MSRV floor job, so their `rust_version` values are measured against the development channel instead, and this is stated per candidate in each member's `Excluded by gate`.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed). Every recommended component runs on both; Windows support is noted where it exists and is not required.
- `assumes license = MIT OR Apache-2.0` (fixed). Gate 1 is applied to every candidate and the separate-process reasoning for `cargo-binstall` (GPL-3.0-only) and `flox` (GPL-2.0) is stated explicitly in members 2 and 4 rather than assumed, with a licence-clean fallback stack named in member 2.
- **No `CONFLICT:` line is emitted.** R42's `- consumes:` list is empty and no recommendation here requires a registered parameter value to change.
- Coordination note, not a conflict: member 1 recommends `profile = "minimal"` and `components = ["rustfmt", "clippy"]` for `rust-toolchain.toml`, and supplies R27 with measured `channel` evidence, but the `channel` value belongs to **R27 through F103/F190** and is not set by this report.

### Migration implications

| File | Change | Source row |
|---|---|---|
| `rust-toolchain.toml` | **new**; `profile = "minimal"`, `components = ["rustfmt", "clippy"]`; `channel` supplied by R27 | F190 / F103 (R27), coordinated |
| `Justfile` | **new** `dev-tools` table variable — the single authoritative tool list, entries `"<probe-executable>:<install-spec>"` | F183 |
| `Justfile` | **new** single generic `install-tool <spec>` recipe (`cargo binstall --locked --no-confirm`, `cargo install --locked` fallback, `ubi` for a release-only spec) — replaces py's `install-taplo`, `install-gitleaks`, `install-actionlint`, `install-yamlfmt` (py `Justfile:159`, `:476`, `:482`, `:713`) | F183 |
| `Justfile` | `check-deps` **rewritten** from per-tool `if`-blocks to one loop over `dev-tools`, printing `MISSING <tool> -> RUN just install-tool <spec>` and exiting non-zero | F181 (retained, re-implemented) |
| `Justfile`, `lefthook.yml` | every tool invocation follows `package-manager-invocation`: `cargo <sub>` or bare `<tool>`; no prefix anywhere | owned parameter |
| `scripts/install-gitleaks.sh`, `scripts/install-actionlint.sh` | **not ported** — no per-tool script exists | F183 |
| `mise.toml` | **not created** (py `mise.toml:23`, `mise.toml:1` have no analogue) | F187, F189 |
| `.flox/env/manifest.toml` | **not created** (py `.flox/env/manifest.toml:14` has no analogue) | F188, F189 |
| `flake.nix` | **not created**; named as the sole acceptable hermetic option if the owner later wants one | F187/F188 alternatives |
| `Makefile` (Level 1) | `check` target tests `rustup`/`cargo` and `just`, not `uv`; `bootstrap` gains `cargo install cargo-binstall --locked`. Retained as a deliberate choice — see the F179 `BASELINE-REVIEW:` line | F179, F180 |
| `CONTRIBUTING` / `README` | states the one-provisioning-path rule and the prefer-a-crates.io-tool rule | F183, F187-F189 |

Ledger dispositions this report proposes (verdict strings remain the
controller's to set, per `docs/port/README.md`): **F183** — decided, replaced by
one generic recipe, no per-tool recipes or scripts; **F187** — not adopted;
**F188** — not adopted; **F189** — not adopted, so the manual-sync obligation
never exists; **F181** — retained, re-implemented as a generic loop, does *not*
collapse into F180; **F179** — layering retained, entry mechanism carries the
`BASELINE-REVIEW:` line above; **F190/F103** — evidence supplied, decision
R27's.

### Validation strategy

**Executed on this host, 2026-09-05.** Toolchain and OS: `rustc 1.98.0
(88d9e12ae 2026-08-18)`, `cargo 1.98.0 (797e8a9bc 2026-08-05)`,
`just 1.57.0`, `aarch64-apple-darwin`, macOS (Darwin 25.4.0). Working
directory: a scratch directory outside the repository, containing only the
recommended `rust-toolchain.toml` and a `Justfile` implementing the
recommended generic recipes. Nothing in the repository was modified and no
binary was installed.

1. `rustup show active-toolchain` -> `stable-aarch64-apple-darwin (overridden by '<scratch>/rust-toolchain.toml')`. **Proves** member 1: the committed file is the active override source.
2. `cargo fmt --version` -> `rustfmt 1.9.0`; `cargo clippy --version` -> `clippy 0.1.98`, both through `~/.cargo/bin/cargo`. **Proves** that `components = ["rustfmt", "clippy"]` removes any need for a formatter or linter installer recipe, which is half the answer to the HIGH F183 question.
3. `just check-deps` over the table `cargo-nextest:cargo-nextest taplo:taplo-cli typos:typos-cli` -> `MISSING cargo-nextest -> RUN \`just install-tool cargo-nextest\``, `ok taplo`, `ok typos`, exit status **1**. **Proves** that one generic loop reproduces py's per-tool report and failure semantics, answering the LOW question, and that F181's `command -v` test survives.
4. A stub `cargo-demo` on `PATH` invoked as `cargo demo --flag 1` -> `cargo-demo invoked argv: demo --flag 1`. **Proves** the Cargo book's custom-subcommand dispatch literally, and therefore that `command -v cargo-<sub>` is the correct presence test for a cargo plugin.
5. The 17-repository configuration survey (`GET /repos/<o>/<r>/contents/`) and the four `justfile` fetches. **Prove** the practice claims underpinning members 2, 4 and 5, including the 0-of-17 provisioner-manifest result and the 0-of-17 root-`Makefile` result behind the F179 finding.

**Proposed, not executed** (each would install software onto the owner's
machine, which is outside this report's mandate). On both `ubuntu-latest` and
`macos-latest`, from a fresh clone: (a) `cargo install cargo-binstall --locked`,
then `just install-tool taplo-cli@0.10.0`, then `command -v taplo` and
`just check-deps` exiting **0** — the end-to-end acceptance check for members 2
and 5; (b) the same flow with `cargo install --locked` substituted for
`cargo binstall`, proving the licence-clean fallback stack is equivalent;
(c) `ubi --project <owner>/<repo> --in ./bin` followed by `./bin/<tool>
--version` — member 3, to be run only when R37, R39 or R40 actually selects a
release-only tool; (d) a repository guard asserting that `mise.toml`,
`.mise.toml`, `.tool-versions` and `.flox/` are absent and that no `Justfile`
or `lefthook.yml` line matches `mise exec|cargo bin |nix develop|flox activate`
— the standing enforcement of members 4 and 5, a natural fit for the drift
guard R15 owns.

### Confidence & re-verify trigger

**High** on: the toolchain-file and components mechanism (first-party
documentation plus executed proof); the split invocation rule and therefore the
owned parameter (Cargo book specification, executed proof, unanimous in all
four surveyed `justfile`s); the decision to adopt no declarative provisioner
manifest (0 of 17 measured, plus an independent single-list principle
argument); and the replacement of per-tool recipes and scripts by one generic
recipe (executed).

**Medium** on: `cargo-binstall` specifically versus first-party
`cargo install --locked`, because that turns on the owner's reading of gate 1
for a GPL-3.0 tool that is executed rather than linked — the recommendation
degrades to a licence-clean stack with only a compile-time cost, and the
synthesizer has both paths; and on member 3, whose slot may never acquire an
occupant.

**Low / unmeasured, stated rather than papered over:** `jdx/mise` issue
responsiveness could not be obtained by the prescribed method; three
`taiki-e/install-action` code-search probes returned HTTP 403 rate-limit
errors; `flox/flox` responsiveness was not sampled; and no `unsafe` audit was
performed for any candidate (argued inapplicable for separate-process tools,
not verified).

**Re-verify triggers:** (1) R27 settles F103 with a `rust-toolchain.toml`
`channel` or `profile` that conflicts with `components = ["rustfmt",
"clippy"]`; (2) R37, R39 or R40 selects a tool that is not published on
crates.io, which activates member 3 for the first time; (3) `cargo-binstall`
relicenses, or a RustSec advisory appears for `cargo-binstall`, `ubi` or
`just`; (4) a repeat of the 17-repository survey finds provisioner manifests in
a material fraction of well-regarded Rust repositories; (5) `cargo-run-bin`
gains a `PATH`-placement mode, which would make it a serious member 2 and 5
candidate simultaneously; (6) otherwise **2027-03-05**.

### Sources

Rust project and Cargo team publications (all retrieved 2026-09-05):
https://rust-lang.github.io/rustup/overrides.html (HTTP 200) ·
https://rust-lang.github.io/rustup/concepts/components.html (HTTP 200) ·
https://rust-lang.github.io/rustup/concepts/profiles.html (HTTP 200) ·
https://rust-lang.github.io/rustup/installation/index.html (HTTP 200) ·
https://doc.rust-lang.org/cargo/reference/external-tools.html ·
https://doc.rust-lang.org/cargo/commands/cargo-install.html ·
https://doc.rust-lang.org/cargo/reference/rust-version.html.

Maintainers' own documentation (all retrieved 2026-09-05):
https://raw.githubusercontent.com/cargo-bins/cargo-binstall/HEAD/README.md ·
https://raw.githubusercontent.com/houseabsolute/ubi/HEAD/README.md ·
https://raw.githubusercontent.com/rust-lang/rustup/HEAD/README.md ·
https://raw.githubusercontent.com/casey/just/HEAD/README.md ·
https://www.gnu.org/licenses/gpl-faq.html#MereAggregation (HTTP 200) ·
https://raw.githubusercontent.com/NixOS/nix/HEAD/COPYING.

Figure endpoints (all retrieved 2026-09-05):
GET https://crates.io/api/v1/crates/<name> and
GET https://crates.io/api/v1/crates/<name>/versions for `rustup`,
`cargo-binstall`, `cargo-quickinstall`, `cargo-run-bin`, `ubi`, `mise`, `just`,
`cargo-make`, `flox`, `devenv`, `devbox`, `taplo-cli`, `typos-cli`,
`cargo-nextest` ·
GET https://api.github.com/repos/<o>/<r> for `rust-lang/rustup`,
`cargo-bins/cargo-binstall`, `cargo-bins/cargo-quickinstall`,
`dustinblackman/cargo-run-bin`, `houseabsolute/ubi`, `jdx/mise`, `casey/just`,
`sagiegurari/cargo-make`, `flox/flox`, `taiki-e/install-action`, and the 17
survey repositories ·
GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open for
each candidate (`total_count`, never `open_issues_count`) ·
GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc
and GET https://api.github.com/repos/<o>/<r>/issues/<n>/comments for issue
responsiveness · https://rustsec.org/packages/<name>.html for every candidate,
with https://rustsec.org/packages/time.html and
https://rustsec.org/packages/atty.html as HTTP-200 controls.

Practice evidence (all retrieved 2026-09-05):
GET https://api.github.com/repos/<o>/<r>/contents/ for `denoland/deno`,
`zed-industries/zed`, `astral-sh/uv`, `BurntSushi/ripgrep`, `starship/starship`,
`typst/typst`, `astral-sh/ruff`, `helix-editor/helix`, `nushell/nushell`,
`casey/just`, `tokio-rs/tokio`, `tokio-rs/axum`, `biomejs/biome`,
`oxc-project/oxc`, `rust-lang/cargo`, `rust-lang/rustup`,
`cargo-bins/cargo-binstall` ·
https://raw.githubusercontent.com/<repo>/HEAD/rust-toolchain.toml for the nine
repositories carrying one ·
https://raw.githubusercontent.com/<repo>/HEAD/justfile for `oxc-project/oxc`,
`biomejs/biome`, `casey/just`, `cargo-bins/cargo-binstall` ·
GET https://api.github.com/search/code?q=repo:<o>/<r>+taiki-e/install-action and
...+cargo-binstall for `astral-sh/uv`, `astral-sh/ruff`, `oxc-project/oxc`,
`biomejs/biome`, `zed-industries/zed`.

Repository documents: `docs/port/PARAMETERS.md` (fixed parameters and the
`package-manager-invocation` consumer list), `docs/port/README.md` (verdict
vocabulary), `docs/port/COMMONALITY.md` rows F103, F179, F180, F181, F183,
F187, F188, F189, F190, `docs/port/BASELINE-REVIEW.md` (F179, F181, F190
adjudications), `research/RUNBOOK.md` sections 4 and 5. Source-repository
evidence (py `Justfile:94`, `:159`, `:476`, `:482`, `:713`, `mise.toml:1`,
`mise.toml:23`, `.flox/env/manifest.toml:14`; ts `Justfile:83`; ts
`docs/port/TS_PORT_DECISIONS.md` D-014(6), D-014(7)) is quoted **as recorded in
this prompt's `## Context`**; the two source repositories were not checked out
for this run, and that limitation is stated rather than implied.

**Method notes.** Endpoints queried: `GET https://crates.io/api/v1/crates/<name>`
and `/versions` (with a `User-Agent` header, per the role contract) for all
fourteen crate names listed above; `GET https://api.github.com/repos/<o>/<r>`,
`/contents/`, `/issues`, `/issues/<n>/comments`,
`GET https://api.github.com/search/issues` and
`GET https://api.github.com/search/code` (authenticated, 5000/hour core limit);
`https://rustsec.org/packages/<name>.html` with two HTTP-200 controls to
establish that a 404 means "no advisory page for this package" rather than a
transport failure; `https://raw.githubusercontent.com/<repo>/HEAD/<file>` for
justfiles, toolchain files and READMEs; and four Rust-project documentation
pages, each confirmed HTTP 200 where it carries a load-bearing claim. **What I
could not verify:** (1) issue responsiveness for `jdx/mise` — the first 300
items on the repository issues endpoint are pull requests and the search
endpoint returns an empty `items` array for sorted queries against that
repository, so only the counts (26 open, 1570 total) are reported; (2) issue
responsiveness for `flox/flox`, not sampled; (3) `taiki-e/install-action`
code-search counts for `nushell/nushell`, `denoland/deno` and
`helix-editor/helix` — three probes returned HTTP 403 "API rate limit
exceeded" and are recorded as not measured, not as zero; (4) any `unsafe`-code
audit of any candidate — argued inapplicable for separate-process tools and
explicitly **not** asserted as clean; (5) the `cargo binstall` and `ubi`
install flows end to end, deliberately not executed because they would write
binaries into the owner's environment; (6) the py and ts source trees, which
were not checked out — their line references are reproduced from this prompt's
`## Context` and are flagged as such. No figure in this report was estimated,
recalled, or carried over from another engine's output; `raw/codex.md` in this
run directory was deliberately not read, per the role contract.
