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

`BASELINE-REVIEW: F179 — a base-toolchain bootstrap layer precedes project dev tasks and uses only what a bare machine already has — retain the two-layer split, but record `make` as a deliberate cross-repository consistency choice carrying a measured ecosystem cost, and delete the claim that it is "the only dependency-free entry point" — evidence: zero of seventeen widely adopted Rust repositories carry a root `Makefile`, while nine carry `rust-toolchain.toml`, five carry `flake.nix` and four carry a `justfile` (`GET https://api.github.com/repos/<o>/<r>/contents/` over `denoland/deno`, `zed-industries/zed`, `astral-sh/uv`, `BurntSushi/ripgrep`, `starship/starship`, `typst/typst`, `astral-sh/ruff`, `helix-editor/helix`, `nushell/nushell`, `casey/just`, `tokio-rs/tokio`, `tokio-rs/axum`, `biomejs/biome`, `oxc-project/oxc`, `rust-lang/cargo`, `rust-lang/rustup`, `cargo-bins/cargo-binstall`, 2026-09-05); rustup's own documented install path is a shell pipeline, not `make` (https://rust-lang.github.io/rustup/installation/index.html, HTTP 200, 2026-09-05), so the dependency-free entry point in this ecosystem is `sh` + `curl`, which `make` wraps rather than replaces; affected items: F179 Notes, F180 (whose Level-1 tool list becomes rustup/cargo plus `just`), F181 (whose Level-2 scope this report retains), and R37, whose lefthook bootstrap lands in whichever layer the owner keeps.`

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
