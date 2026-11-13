# R44 — devcontainer-environment (pattern, Focused) — Opus raw report

Engine identity: `research-opus-2026-09-17T020715Z-ff8c50edbd69` (claude-opus-5).
Every endpoint in this report was queried on **2026-09-17 (UTC)** unless a different
retrieval date is stated on the line. Where a number is quoted, the endpoint that
produced it is named beside it. Where a check was *run*, it is labelled **executed**;
where it is a proposal for P03, it is labelled **planned**. No Rust template exists
yet; this is research, and nothing was scaffolded.

**Fitness gate 1 (licence compatibility) is `inapplicable — owner ruling 2026-09-12
(Q7.B)`** for every candidate in this report, per `docs/port/OWNER-REVIEW.md`
("2026-09-12 — no licence check for anything the template uses (Q4, superseded and
widened by Q7.B)"). Licences are recorded below as figures, never as tests, and
nothing is excluded on licence.

---

### Landscape

**The category this item decides.** Not "which container image" but: *does the
template ship a second, containerised path to a working development environment
beside the native `make bootstrap` / `just setup` chain, and if so, what is the
smallest artifact that delivers it?* The decidable unit is a pair of files —
`.devcontainer/devcontainer.json` and (optionally) `.devcontainer/post-create.sh` —
governed by the Development Containers Specification, an open specification with its
own repository, schema and reference CLI.

**Three-bin map of the Rust field.**

| Bin | Candidates found |
|---|---|
| Built-in / first-party toolchain | `rustup` itself (the toolchain provisioner the template already commits `rust-toolchain.toml` for, per R42 layer 1); `rust-lang/docker-rust`, the Rust project's own Docker images published as Docker Hub `library/rust` — `stable/trixie/Dockerfile`, `stable/trixie/slim/Dockerfile`, `stable/alpine3.24/` |
| Established industry standard | The **Dev Container Specification** (`containers.dev`, `devcontainers/spec`); **`mcr.microsoft.com/devcontainers/rust`**, built by `devcontainers/images` *from* `rust-lang/docker-rust` (proved by its own image label, below); **`ghcr.io/devcontainers/features/rust`**, the composable feature; `mcr.microsoft.com/devcontainers/base` + that feature; `mcr.microsoft.com/devcontainers/universal`; the first-party template `devcontainers/templates` `src/rust`; `devcontainers/cli` and the `devcontainers/ci` GitHub Action; GitHub Codespaces as the hosted consumer |
| Up-and-comer | Agent-sandbox devcontainers — `anthropics/claude-code`'s own `.devcontainer` with `--cap-add=NET_ADMIN` and an egress-firewall `postStartCommand`; Nix/`devenv`-backed devcontainers; DevPod / Daytona as non-VS-Code devcontainer runners. Treated as leads, not shortlisted, because none is first-party or spec-defining |
| Always-a-candidate | **No devcontainer at all** — the `ts-launch-blueprint` shape. HIGH question 2 makes this a real option, evaluated below on the same evidence as the rest |

**Authoritative sources used, and why each is authoritative.**

| Source | Why authoritative | Retrieved |
|---|---|---|
| `https://containers.dev/implementors/spec/` and `/implementors/features/` | The specification itself; it defines the `features` reference grammar, the `devcontainer.metadata` image label and the merge order | 2026-09-17 |
| `https://github.com/rust-lang/docker-rust` (`stable/trixie/Dockerfile`) | The Rust project's own repository; the image every other Rust devcontainer image derives from | 2026-09-17 |
| `https://github.com/rust-lang/rustup` `CHANGELOG.md` | rustup's maintainers' own release record; the authority on toolchain auto-install behaviour | 2026-09-17 |
| `https://github.com/devcontainers/features` `src/rust/devcontainer-feature.json`, `src/rust/install.sh` at tag `feature_rust_1.6.0` | The maintainers' own feature definition — the only place the defaults and the VS Code contributions are actually stated | 2026-09-17 |
| `https://github.com/dependabot/dependabot-core` `devcontainers/lib/dependabot/devcontainers/` | Primary source for what Dependabot's `devcontainers` ecosystem does and does not parse | 2026-09-17 |
| `https://github.com/actions/runner-images` `images/macos/macos-26-arm64-Readme.md`, `images/ubuntu/Ubuntu2404-Readme.md` | GitHub's own published software inventory per runner image — the authority on whether a container runtime exists on a runner | 2026-09-17 |
| `https://code.visualstudio.com/docs/devcontainers/containers` | The maintainer's documentation for the dominant client | 2026-09-17 |
| `https://github.blog/changelog/2024-01-24-dependabot-version-updates-support-devcontainers/` | GitHub's own changelog announcing the ecosystem; dated 2024-01-24 | 2026-09-17 |

A single blog post was treated as a lead throughout; every figure below comes from an
API endpoint or a file in a maintainer's repository.

**Practice evidence — the survey, and what "well regarded" means here.** I probed
`GET https://api.github.com/repos/<o>/<r>/contents/.devcontainer` (HTTP 200 = present,
404 = absent) across 32 widely adopted repositories, 31 of them Rust-primary by the
`language` field of `GET https://api.github.com/repos/<o>/<r>`. Well-regarded is
evidenced by `stargazers_count` from that same endpoint, not asserted. Binary used for
all counting: `/usr/bin/grep` and `/usr/bin/head`; no count in this report passes
through a truncating pipe.

**Result: 4 of 31 Rust-primary repositories carry a `.devcontainer` directory
(13%).** Retrieved 2026-09-17.

| Repository | stars | `.devcontainer` | What it contains |
|---|---|---|---|
| `astral-sh/ruff` | 49,651 | **present** | `image: mcr.microsoft.com/devcontainers/rust:0-1-bullseye`; cargo-cache volume mount on `/usr/local/cargo`; `post-create.sh`; python feature. Last touched **2024-08-28** (`GET /repos/astral-sh/ruff/commits?path=.devcontainer/devcontainer.json&per_page=1`) |
| `biomejs/biome` | 25,854 | **present** | `image: mcr.microsoft.com/devcontainers/universal:6` + `ghcr.io/devcontainers/features/rust:1` + a third-party `just` feature. Last touched **2026-09-09**, by an automated dependency bump (`chore(deps): update mcr.microsoft.com/devcontainers/universal docker tag to v6`) |
| `denoland/deno` | 108,451 | **present** | Local `Dockerfile` build; `runArgs` `--cap-add=SYS_PTRACE`; `postCreateCommand: git submodule update --init`. Last touched **2023-12-19** |
| `tauri-apps/tauri` | 111,123 | **present** | Local `Dockerfile`; uses the **deprecated** top-level `settings`/`extensions`/short-form `features` schema and cites `vscode-dev-containers` v0.234.0. Last touched **2022-06-06** |
| Absent (27) | — | absent | `rust-lang/rust` (118,927), `rustdesk/rustdesk` (123,929), `openai/codex` (124,801), `zed-industries/zed` (90,361), `astral-sh/uv` (89,891), `BurntSushi/ripgrep` (68,336), `rust-lang/rustlings` (64,162), `sharkdp/bat` (60,472), `starship/starship` (59,920), `meilisearch/meilisearch` (59,306), `typst/typst` (56,066), `helix-editor/helix` (46,250), `nushell/nushell` (40,520), `pola-rs/polars` (39,745), `tokio-rs/tokio` (33,164), `influxdata/influxdb` (31,744), `tokio-rs/axum` (27,156), `vectordotdev/vector` (22,574), `bytecodealliance/wasmtime` (18,639), `gfx-rs/wgpu` (18,080), `rust-lang/rust-analyzer` (16,857), `clap-rs/clap` (16,708), `rust-lang/cargo` (15,484), `serde-rs/serde` (10,826), `SeaQL/sea-orm` (9,896), `rust-lang/rustup` (7,044), `paritytech/polkadot-sdk` (2,807) |
| Non-Rust control | — | **present** | `anthropics/claude-code` (145,614, TypeScript) — agent sandbox with `NET_ADMIN` and an egress firewall; cited only for the up-and-comer bin |

**What the survey actually shows, read honestly in both directions.** The absence rate
is the headline: 27 of the 31 most-regarded Rust projects, including every
`rust-lang/*` repository and every one of the "new and popular" cohort the survey
method asks me to weight (`uv`, `zed`, `codex`, `typst`, `polars`), ship no
devcontainer. `rustup` plus a C toolchain is already a one-command, cross-platform
environment, so the container earns far less in Rust than the Python and Node
ecosystems it was designed around. But the four that do carry one are not a random
sample: `ruff`, `biome`, `deno` and `tauri` are all high-traffic,
many-drive-by-contributor projects — precisely the shape a *template* is meant to
produce. And three of the four have rotted: `tauri`'s file still targets a 2022
schema, `deno`'s is from 2023, and `ruff`'s names `bullseye`, a Debian release
`rust-lang/docker-rust` deleted on 2026-09-08 (`fix!: Remove EOL Debian Bullseye`,
`GET /repos/rust-lang/docker-rust/commits?per_page=5`). **Rot, not adoption, is the
dominant failure mode, and the recommendation below is shaped by that.**

**Fit over abstract best.** Every candidate is judged against: a Rust CLI + library +
optional web-service template whose toolchain is already declared in
`rust-toolchain.toml` (R42 layer 1), whose bootstrap is already a two-level
`make bootstrap` → `just setup` chain (F179–F182, `COMMON → REUSE`), whose CI matrix
is fixed at `ubuntu-latest, macos-latest`, and whose editor extension list already
exists once at `.vscode/extensions.json` (F193, `COMMON → REUSE`).

---

### Principles and implementation

**The shared requirement, its source, and the level of agreement.** Reading py's two
files at the pinned commit `b08bccfb` (`git -C ~/c/py-launch-blueprint show
b08bccfb:.devcontainer/devcontainer.json` and `:.devcontainer/post-create.sh`,
retrieved 2026-09-17), the principle behind py's devcontainer is:

> *A contributor with no project toolchain installed, on a host the template does not
> otherwise support, can reach a fully bootstrapped working environment by opening the
> repository — and that environment is produced by the repository's own single
> bootstrap chain, not by a second, parallel set of setup instructions.*

The second clause is the load-bearing one, and py's file demonstrates it literally:
`post-create.sh` ends in exactly two lines, `make bootstrap` and `just setup`, the
same Level-1/Level-2 pair a native contributor runs. The devcontainer adds *only* a
base image and the three packages that image lacks (`make`, `curl`, `ca-certificates`).

**Agreement level: architectural pattern and policy, not value.** Decomposed:

| Element | Level at which agreement is required | Must agree across py/ts/rs? |
|---|---|---|
| Whether a containerised path exists at all | **policy** — a project-wide call about how contributors are onboarded | **Yes.** `DIVERGENCE-ANALYSIS.md:172` classifies F200 as cause class **D** (one-sided, language-neutral), `harmonize: partly`, with the adopt-or-drop half marked `yes`: "adopt in all three or drop in all three" |
| `postCreate` delegates to the repo's own bootstrap chain rather than restating it | **architectural pattern** | **Yes.** This is the principle above; it is what keeps the devcontainer from becoming a second source of truth |
| The container carries exactly one declaration of the editor-extension set | **architectural pattern** | **Yes** — and py violates it today; see the `BASELINE-REVIEW` below |
| Base image, image tag, `remoteUser`, cache mounts, ecosystem-specific pre-steps | **capability**, realised natively | **No.** Rust-specific; `DIVERGENCE-ANALYSIS.md:172` marks this half `no` |

**Is the pattern still appropriate in the target ecosystem?** Partly, and the honest
answer is that its value is narrower in Rust than in Python, for a reason specific to
each ecosystem's provisioning story. py's devcontainer exists in part because Python's
interpreter-plus-virtualenv story is host-entangled: the image's whole contribution is
a pre-provisioned CPython 3.12 and `uv`. Rust has no analogue of that problem —
`rustup` is one installer, the same on every host, and `rust-toolchain.toml` already
makes the toolchain a committed, reproducible fact. So the container's contribution in
Rust reduces to four narrower goods, each of which I can point at concretely:

1. **Hosts the template does not support.** `target-os-matrix` is fixed at
   `ubuntu-latest, macos-latest`; Windows is explicitly not a supported target
   (`docs/port/PARAMETERS.md`, owner decision 2026-09-02). A Windows contributor's only
   first-class path is a Linux container. This is the single strongest reason to adopt
   and it follows directly from an owner decision already taken.
2. **Zero-install onboarding.** GitHub Codespaces consumes `devcontainer.json`
   directly, so a drive-by contributor gets a built environment in a browser. The four
   adopters found by the survey are exactly the drive-by-contributor-heavy projects.
3. **A pinned, uniform Linux for reproducing a CI failure locally**, which a macOS
   contributor otherwise cannot do at all.
4. **Agent sandboxing** — the up-and-comer bin. `anthropics/claude-code`'s own
   `.devcontainer` pairs `--cap-add=NET_ADMIN` with an egress-firewall
   `postStartCommand` (`GET /repos/anthropics/claude-code/contents/.devcontainer/devcontainer.json`,
   2026-09-17). R43 (`ai-assistant-repo-furniture`, resolved) and R86
   (`codex-assisted-review-workflows`, open) own that surface, not this item; it is
   recorded as a *consequence* of shipping a devcontainer, not as a reason chosen here.

What the container does **not** buy in Rust, and must not be sold as: it does not make
builds reproducible (`Cargo.lock` plus `rust-toolchain.toml` do that), it does not
define the MSRV floor (`rust-version` in `Cargo.toml` plus a CI job do that, R42/R27),
and it is not the deployment image (R51 owns that, and is open).

**Architectural alternatives compared, before any image is chosen.** There are four
distinct architectures here, not four images:

| # | Architecture | What it is | Consequence |
|---|---|---|---|
| A | **No devcontainer** | The ts shape. Native chain only | Zero maintenance surface, zero rot. Windows contributors have no first-class path; no Codespaces onboarding |
| B | **Image-only** | One `image:` reference to a prebuilt Rust devcontainer image; no `Dockerfile`, no `features` block | Smallest possible artifact. Exactly one third-party reference to keep pinned. Image publisher owns the layer composition |
| C | **Base image + features** | `devcontainers/base` (or `universal`) plus `ghcr.io/devcontainers/features/rust` composed at build time | Maximum configurability (`profile`, `components`, `targets` as JSON options). Every contributor pays a multi-minute feature install on first create, and the template now pins *two* third-party OCI references |
| D | **Local `Dockerfile`** | The `deno`/`tauri` shape | Total control; the template now owns and must patch a Debian base, and its build is not cached for contributors. Both surveyed examples rotted (2023, 2022) |

Architecture **B** is the right shape for this template, and the reason is structural
rather than aesthetic: the template's toolchain is *already* declared in
`rust-toolchain.toml`, so the configurability architecture C exists to provide —
choosing `profile`, `components` and `targets` as feature options — is configurability
this repository must not use, because using it would create a second declaration of
the toolchain that R42 deliberately made singular. Architecture C's own strength is
this template's F189 anti-pattern. Architecture B lets the image be a *cache* of a
toolchain whose authority lives in the repository.

**The image, and the decisive fact about it.** `mcr.microsoft.com/devcontainers/rust`
is not a Microsoft reimplementation of a Rust environment; it is the Rust project's
own image with three first-party devcontainer features baked in. This is stated by the
image's own config blob, read **executed** at
`GET https://mcr.microsoft.com/v2/devcontainers/rust/manifests/2.1.1-trixie`, then the
arm64 child manifest, then its config blob (2026-09-17):

```
org.opencontainers.image.source = https://github.com/rust-lang/docker-rust
dev.containers.id       = rust
dev.containers.release  = v0.4.33
dev.containers.variant  = trixie
dev.containers.timestamp = Thu, 10 Sep 2026 12:17:32 GMT
devcontainer.metadata   = [ {"id":"ghcr.io/devcontainers/features/common-utils:2"},
                            {"id":"ghcr.io/devcontainers/features/git:1", ...},
                            {"id":"ghcr.io/devcontainers/features/rust:1", ...},
                            {"remoteUser":"vscode"} ]
RUST_VERSION  = 1.98.1
RUSTUP_HOME   = /usr/local/rustup
CARGO_HOME    = /usr/local/cargo
PATH          = /usr/local/cargo/bin:...
```

Four consequences follow, and they answer three of the prompt's questions outright:

- **HIGH question 1 is answered yes, and by a first-party artifact.** The canonical
  Rust devcontainer base image exists, it is the Rust project's own image
  (`rust-lang/docker-rust`, Apache-2.0, 537 stars, `archived: false`,
  `pushed_at: 2026-09-08T18:15:07Z` — `GET https://api.github.com/repos/rust-lang/docker-rust`,
  2026-09-17), and it tracks stable essentially without lag: stable is `1.98.1
  (48a229cea 2026-09-01)`, channel date `2026-09-03`
  (`GET https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust]`,
  2026-09-17), and `docker-rust`'s `chore: Update Rust to 1.98.1` commit is dated
  **2026-09-03**. The devcontainer repackaging lagged by seven days
  (`dev.containers.timestamp`, 2026-09-10).
- **The image already carries `rustup`**, not a bare `rustc`. This is what makes
  architecture B compatible with `rust-toolchain.toml`: the baked 1.98.1 is a warm
  cache, and if `rust-toolchain.toml` names a different channel, rustup installs it.
- **`remoteUser: vscode` and the VS Code extension contributions are baked into the
  image metadata**, and the spec merges image metadata with `devcontainer.json`, the
  JSON file applied last (`https://containers.dev/implementors/spec/`, "Image
  Metadata", 2026-09-17). The baked contributions from the rust feature are
  `rust-lang.rust-analyzer`, `tamasfe.even-better-toml`, `vadimcn.vscode-lldb`, plus
  the setting `files.watcherExclude: {"**/target/**": true}`
  (`src/rust/devcontainer-feature.json`, `GET /repos/devcontainers/features/contents/...`,
  2026-09-17).
- **`make`, `curl` and `git` are already present**, unlike py's slim uv base. The image
  descends from `buildpack-deps:trixie`, whose `Dockerfile` installs `make` at line 48
  (`GET /repos/docker-library/buildpack-deps/contents/debian/trixie/Dockerfile`,
  2026-09-17), and the `git` and `common-utils` features are baked. **So the
  `apt-get install make curl ca-certificates` preamble that occupies the first eight
  lines of py's `post-create.sh` has no counterpart here and must not be copied.**

**MEDIUM question 1 — is a Rust-specific pre-step needed before `make bootstrap`?
Yes, exactly one, and it is not the one py's file would suggest.** rustup's own
CHANGELOG records that automatic toolchain installation, removed in 1.28.0, was
restored in **1.28.1 (2025-03-05)** — "Automatic install is enabled by default but can
be opted out by setting `RUSTUP_AUTO_INSTALL` environment variable to `0`" — and that
1.28.2 added `rustup set auto-install disable` as a lower-priority equivalent
(`GET /repos/rust-lang/rustup/contents/CHANGELOG.md`, 2026-09-17). So a container
whose baked toolchain differs from `rust-toolchain.toml` *will* work — but it will
work by silently downloading a whole toolchain inside the first `cargo` invocation a
contributor happens to make, which is a multi-minute stall at an arbitrary moment.
The fix is one line, and rustup documents its no-argument form in its own help:
`rustup toolchain install` with no `TOOLCHAIN` argument is "Install or update the
given toolchains, **or by default the active toolchain**" (**executed**:
`rustup toolchain install --help`, rustup 1.29.1 (d95a37b6a 2026-08-13), macOS,
2026-09-17), and inside a directory carrying `rust-toolchain.toml` the active
toolchain is the one that file names, with its `profile` and `components` honoured.
That single line moves the download into `postCreate`, where the tool shows progress
and where a failure is visible.

`ruff`'s `post-create.sh` is the maintained reference implementation of exactly this
shape (`GET /repos/astral-sh/ruff/contents/.devcontainer/post-create.sh`, 2026-09-17):

```sh
rustup default < rust-toolchain
rustup component add clippy rustfmt
cargo install --locked cargo-insta@1.48.0
cargo fetch

pip install maturin prek
```

Read as evidence rather than as a template: ruff confirms that a Rust devcontainer's
`postCreate` is *toolchain-materialisation followed by project setup*, and that
`cargo fetch` is the accepted registry-warming step. But lines 1–3 are precisely the
parallel-setup anti-pattern the shared principle forbids: ruff restates the toolchain
resolution, the component list, and a tool install that its own task runner should
own. This template must express all three through `rust-toolchain.toml` and
`just setup`, and reduce `postCreate` to `rustup toolchain install` + the existing
two-level chain.

**MEDIUM question 2 — in-container VS Code configuration.** The template needs
**none beyond what the image already contributes**, and that is a finding rather than
an omission. The image's `devcontainer.metadata` already supplies
`rust-lang.rust-analyzer`, `tamasfe.even-better-toml`, `vadimcn.vscode-lldb`,
`files.watcherExclude` on `target/`, `CARGO_HOME`/`RUSTUP_HOME`/`PATH`, and
`capAdd: ["SYS_PTRACE"]` + `securityOpt: ["seccomp=unconfined"]` so a debugger works.
This report adds no `settings` of its own and found no evidence that rust-analyzer
requires a container-specific one. The one setting `ruff` adds
(`rust-analyzer.updates.askBeforeDownload: false`) is recorded as an observed
practice, not adopted: whether it is redundant given the baked `rust-analyzer` rustup
component was **not verified**, so it is neither copied nor argued against.

The template must therefore **declare no `customizations.vscode.extensions` array at
all**. This is not merely economy; it is the same principle R42 applied when it
refused `mise.toml` and `flake.nix`: one declared set, one location. VS Code's own
documentation describes `devcontainer.json`'s list as the mechanism for extensions
installed at container creation and does not document `.vscode/extensions.json`
recommendations being installed automatically inside a container
(`https://code.visualstudio.com/docs/devcontainers/containers`, 2026-09-17), so a
second list is a second source of truth with no mechanism keeping it honest.

**The evidence that the second list rots is in py itself, measured.** At `b08bccfb`,
`.devcontainer/devcontainer.json` names 4 extensions and `.vscode/extensions.json`
names 11. They share **3** (`ms-python.python`, `charliermarsh.ruff`,
`tamasfe.even-better-toml`). `EditorConfig.EditorConfig` is in the devcontainer and
not in the recommendations; **8** entries — including `redhat.vscode-yaml`,
`eamodio.gitlens`, `GitHub.vscode-pull-request-github` and `Anthropic.claude-code` —
are recommended to a native contributor and withheld from a container contributor,
for no recorded reason. That is the F189 manual-sync obligation reappearing one
directory over.

BASELINE-REVIEW: F193 — principle: the repository declares its recommended editor
extension set exactly once — **proposed change: record on F193 that where a
devcontainer exists it carries no `customizations.vscode.extensions` array, so
`.vscode/extensions.json` plus whatever the base image's `devcontainer.metadata`
already contributes remain the only two lists, neither of them hand-synchronised** —
evidence: in `py-launch-blueprint` at `b08bccfb` the two lists have already drifted —
`.devcontainer/devcontainer.json` names 4 extensions, `.vscode/extensions.json`
names 11, and only 3 are common (`ms-python.python`, `charliermarsh.ruff`,
`tamasfe.even-better-toml`); `EditorConfig.EditorConfig` appears only in the
devcontainer and 8 entries only in the recommendations. The Dev Container
specification merges an image's `devcontainer.metadata` label with `devcontainer.json`
(`https://containers.dev/implementors/spec/`, 2026-09-17), and
`mcr.microsoft.com/devcontainers/rust:2.1.1-trixie` already contributes
`rust-lang.rust-analyzer`, `tamasfe.even-better-toml` and `vadimcn.vscode-lldb`
(image config blob, read 2026-09-17), so restating them would duplicate rather than
add. Affected: F193, F200, and R28 (`linter-and-editor-tooling`), which populates
`.vscode/extensions.json`.

**Cross-repo answer (HIGH question 3, `harmonize: partly`).** `DIVERGENCE-ANALYSIS.md:172`
records that ts has no `.devcontainer` and no `D-0nn` entry explaining the omission,
with the inferred reason "ts's Node toolchain needs no isolated container". Verified
at the pin: `git -C ~/c/ts-launch-blueprint ls-tree cb1cbcb2 -- .devcontainer` returns
0 entries (2026-09-17). My survey supplies the evidence that the inferred reason is
*not* sufficient on its own — because the same "the toolchain is already portable"
argument applies at least as strongly to Rust, and yet the principle (a contributor on
an unsupported host, or with no local toolchain, reaches a working environment) is
real in all three ecosystems. The honest classification is **accidental drift in ts,
with a justified difference in realisation**: the *policy* (ship a devcontainer)
should hold for all three; the *artifact* differs, because ts would use
`mcr.microsoft.com/devcontainers/typescript-node` and a `postCreate` calling its own
chain, py keeps its uv image, and rs uses the Rust image. Propagating this to py and
ts is a follow-on project; this answer supplies its rationale, and the F193 finding
above is the concrete repair py needs.

**Observable acceptance criteria** (what "the principle holds" means, testably):

1. Starting from a checkout and nothing else, `devcontainer up` succeeds and a
   subsequent `devcontainer exec` of the repository's own verification recipe passes.
2. `rustc --version` inside the container equals the channel named in
   `rust-toolchain.toml`, not the image's baked `RUST_VERSION`.
3. `.devcontainer/post-create.sh` contains no install command for any tool that
   `make bootstrap` or `just setup` installs, and no `apt-get` line.
4. `.devcontainer/devcontainer.json` contains no `extensions` array.
5. Every OCI reference in `.devcontainer/` is digest-pinned with a trailing
   human-readable tag comment.

**Fitness gates, applied to every candidate before popularity.** Gates 3, 5 and 6 have
no literal crate meaning for a pattern item; the stated substitute is given rather
than the gate being dropped.

| Gate | Application to this item | Verdict |
|---|---|---|
| 1 · licence | — | **`inapplicable — owner ruling 2026-09-12 (Q7.B)`**. Recorded as figures only: `rust-lang/docker-rust` Apache-2.0; `devcontainers/features`, `devcontainers/images`, `devcontainers/ci`, `devcontainers/cli`, `devcontainers/templates` MIT; `devcontainers/spec` CC-BY-4.0 (`GET https://api.github.com/repos/<o>/<r>`, `.license.spdx_id`, 2026-09-17) |
| 2 · MSRV | Does the candidate constrain the toolchain the repository declares? | **Passes, by not constraining it.** The image ships `RUST_VERSION=1.98.1`, exactly current stable, but carries `rustup`, and `rust-toolchain.toml` overrides it with auto-install (rustup CHANGELOG 1.28.1). The floor under `stable minus 2 minor versions` is 1.96.x; nothing in the devcontainer touches `rust-version` in `Cargo.toml` or the MSRV CI job. **The devcontainer is not an MSRV matrix cell and must not be treated as one** |
| 3 · advisories / `unsafe` | No crate, so no RustSec page. Substitute: installer integrity | **Stated, with a real difference recorded.** `rust-lang/docker-rust` pins rustup to `https://static.rust-lang.org/rustup/archive/1.29.0/${rustArch}/rustup-init` with a **hard-coded per-architecture sha256** in the Dockerfile. `devcontainers/features` `src/rust/install.sh` (tag `feature_rust_1.6.0`) fetches the *unversioned* `dist/${arch}/rustup-init` and verifies it against `rustup-init.sha256` **served from the same host**, i.e. corruption protection, not provenance. This is a point in favour of architecture B (image, first-party pinning) over architecture C (feature). No `unsafe` posture applies |
| 4 · runs on `ubuntu-latest, macos-latest` | **The decisive gate** | **Passes with a stated asymmetry.** The image index for `mcr.microsoft.com/devcontainers/rust:2.1.1-trixie` lists `linux/amd64` and `linux/arm64` (**executed**, `GET https://mcr.microsoft.com/v2/devcontainers/rust/manifests/2.1.1-trixie`, `Accept: application/vnd.oci.image.index.v1+json`, 2026-09-17), so an Apple-Silicon macOS host runs it natively, not emulated. **But the devcontainer cannot be *validated in CI* on `macos-latest`**: `images/macos/macos-26-arm64-Readme.md` in `actions/runner-images` contains **0** case-insensitive matches for `docker` across its 261 lines, while `images/ubuntu/Ubuntu2404-Readme.md` lists `Docker Client 28.0.4`, `Docker Server 28.0.4`, `Docker Compose 2.38.2` (**executed**, `gh api .../contents/... -H "Accept: application/vnd.github.raw" \| /usr/bin/grep -ci docker`, 2026-09-17). **How macOS hosts reach the container:** locally, through a third-party runtime the template neither ships nor provisions — Docker Desktop, OrbStack, Colima or Podman — plus the VS Code Dev Containers extension; or remotely, with no local runtime at all, through GitHub Codespaces. This is stated in `README.md` prose, and the CI job that exercises the devcontainer runs `ubuntu-latest` only. Windows: supported via the same local-runtime path, and it is the population the container exists for |
| 5 · default features / async-runtime coupling | No crate. Substitute: what the image turns on by default | **Stated.** Baked features and their defaults: `common-utils:2`, `git:1`, `rust:1` with `profile=minimal` and `components=rust-analyzer,rust-src,rustfmt,clippy`; `capAdd: SYS_PTRACE`; `securityOpt: seccomp=unconfined`; `remoteUser: vscode`. The last two loosen the container's default sandbox to let a debugger attach — accepted for a development container, and noted as a reason this image must never be confused with R51's deployment image. No async-runtime coupling exists |
| 6 · binary-size / compile-time cost | Substitute: cold-start pull size and first-create time | **Stated.** Compressed layer totals, arm64, summed from each child manifest (**executed**, 2026-09-17): `devcontainers/rust:2.1.1-trixie` = **871,370,327 bytes ≈ 831 MiB** over 15 layers; `devcontainers/rust:2.1.1-bookworm` = 912,332,031 bytes ≈ 870 MiB; `devcontainers/base:trixie` = 377,158,395 bytes ≈ 360 MiB; `devcontainers/universal:6` (amd64) = 4,006,294,640 bytes ≈ **3,821 MiB**. Wall-clock pull and create time was **not measured** — no timing was run in this item, and nothing below claims one |

---

### Dominant choice

**`mcr.microsoft.com/devcontainers/rust`, referenced as a bare `image:` with no
`features` block** is the dominant choice in the Rust devcontainer field, on three
independent lines of evidence:

1. **It is what the first-party template emits.** `devcontainers/templates` `src/rust`
   `.devcontainer/devcontainer.json` is, in its entirety, a `name` and
   `"image": "mcr.microsoft.com/devcontainers/rust:2-1-${templateOption:imageVariant}"`,
   with everything else present as commented-out guidance — including the cargo-cache
   volume mount (`GET /repos/devcontainers/templates/contents/src/rust/.devcontainer/devcontainer.json`,
   2026-09-17).
2. **It is what the most-maintained Rust adopter in the survey uses.** `ruff` uses the
   same image plus the same cargo-cache mount the first-party template suggests.
3. **It is the Rust project's own image**, as its `org.opencontainers.image.source`
   label proves, so choosing it is not choosing a vendor's interpretation of a Rust
   environment over the Rust project's.

The competing shape found in practice — `universal` plus the `rust` feature, as
`biome` does — is dominant in *Codespaces defaults*, not in Rust practice, and fails
gate 4's spirit for this template (see *Excluded by gate*).

---

### Options

Name · where documented · adopters that practice it · date of the most recent
authoritative write-up. No download columns; these are patterns and images, not crates.

| Option | Where documented | Adopters practising it | Most recent authoritative write-up |
|---|---|---|---|
| **B1 · image-only, `mcr.microsoft.com/devcontainers/rust`** | `https://github.com/devcontainers/images/tree/main/src/rust`; first-party template `devcontainers/templates` `src/rust` | `astral-sh/ruff` (49,651 stars) — same image, same cargo-cache mount | Image `2.1.1-trixie` published **2026-09-10** (`dev.containers.timestamp` label); `devcontainers/images` `pushed_at: 2026-09-16T12:32:33Z` |
| **B2 · image-only, official `library/rust` (`rust:1.98.1-trixie`)** | `https://github.com/rust-lang/docker-rust` | Not practised as a devcontainer base in the survey; it is the *upstream* of B1 | `chore: Update Rust to 1.98.1`, **2026-09-03** |
| **C1 · `devcontainers/base` + `ghcr.io/devcontainers/features/rust`** | `https://containers.dev/features`; `devcontainers/features` `src/rust/` | `biomejs/biome` (25,854 stars), on `universal` rather than `base` | Feature `1.6.0`; `feat(rust) — Add "none" value for Rust feature "components"` merged **2026-09-16** |
| **C2 · `devcontainers/universal` + rust feature** | same | `biomejs/biome` | image tag `v6` bumped in biome **2026-09-09** |
| **D · local `Dockerfile`** | `https://containers.dev/guide/dockerfile` | `denoland/deno` (108,451), `tauri-apps/tauri` (111,123) | deno's last touch **2023-12-19**; tauri's **2022-06-06** |
| **A · no devcontainer** | `ts-launch-blueprint` at `cb1cbcb2` (0 entries under `.devcontainer`) | 27 of 31 surveyed Rust repositories, incl. every `rust-lang/*` repo, `uv`, `zed`, `codex`, `tokio`, `ripgrep` | n/a — an omission has no write-up, which is itself the finding: no `D-0nn` entry in `TS_PORT_DECISIONS.md` records it |

---

### Excluded by gate

| Candidate | Gate failed | Evidence |
|---|---|---|
| **`mcr.microsoft.com/devcontainers/universal:6`** (C2, biome's choice) | **Gate 4** — architecture coverage | Its manifest index lists **`linux/amd64` only** (plus an `unknown/unknown` attestation entry) — **executed**, `GET https://mcr.microsoft.com/v2/devcontainers/universal/manifests/6` with `Accept: application/vnd.oci.image.index.v1+json`, 2026-09-17. On an Apple-Silicon macOS host, half of the fixed target matrix, it runs only under emulation. Also fails gate 6 hard: 3,821 MiB compressed against 831 MiB for the Rust image, for a multi-language toolchain this template does not use |
| **Any `*-bullseye` tag**, including `ruff`'s pinned `0-1-bullseye` | **Maintenance rubric** — the base distribution is retired upstream | `rust-lang/docker-rust` merged `fix!: Remove EOL Debian Bullseye` on **2026-09-08** (`GET /repos/rust-lang/docker-rust/commits?per_page=5`, 2026-09-17). Tags still resolve in the MCR registry, so this is a silent trap rather than a hard failure |
| **Architecture D, local `Dockerfile`** | **Maintenance rubric** — `at-risk` by demonstrated practice | Both surveyed instances rotted: `tauri`'s `devcontainer.json` last changed **2022-06-06** and still uses the top-level `settings`/`extensions` schema superseded by `customizations`; `deno`'s last changed **2023-12-19** (`GET /repos/<o>/<r>/commits?path=.devcontainer/devcontainer.json&per_page=1`, 2026-09-17). Adopting D would make this template the owner of a Debian base image with no CVE pipeline, duplicating R51's job in the wrong directory |
| **Nix/`devenv`-backed devcontainers** | **Consistency with R42**, not a numbered gate | R42 decided `flake.nix` is **not adopted** (F188, F189). Introducing Nix through the devcontainer would reinstate exactly the provisioner R42 removed. Excluded on that ground and recorded as such |
| Nothing is excluded on licence | — | Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)` |

---

### Up-and-comers

| Candidate | State | Why it is watched, not chosen |
|---|---|---|
| **Agent-sandbox devcontainers** | Live and spreading | `anthropics/claude-code` (145,614 stars) ships `.devcontainer/` with `Dockerfile`, `init-firewall.sh`, `runArgs: ["--cap-add=NET_ADMIN","--cap-add=NET_RAW"]` and `postStartCommand: sudo /usr/local/bin/init-firewall.sh`, plus named volumes for agent config and shell history. This is the fastest-growing *reason* to ship a devcontainer, and it is a genuine second consumer of the same file. **Out of scope here**: R43 (`ai-assistant-repo-furniture`, resolved) and R86 (`codex-assisted-review-workflows`, open) own the agent surface. Recorded so that whichever item wants it knows the file already exists and what it would add — `runArgs`, a firewall script, and volume mounts — none of which belong in the minimal recommendation below |
| **`devcontainers/cli` outside VS Code** (DevPod, Daytona, JetBrains) | Growing | `devcontainers/cli` — 2,953 stars, `archived: false`, `pushed_at: 2026-09-03T07:27:05Z`, MIT — makes `devcontainer.json` portable beyond VS Code, and is what `devcontainers/ci` and Dependabot both drive. It strengthens the case for a *spec-clean* file (no VS-Code-only assumptions), which the recommendation honours by carrying no `extensions` array and no editor-specific settings |
| **`devcontainers/features` `rust` option growth** | Active | `components` gained a `none` value on 2026-09-16 (`feat(rust) — Add "none" value for Rust feature "components"`, PR #1725). Watched because a future option could make architecture C safe for a `rust-toolchain.toml`-governed repository — specifically, a way to say "install rustup, install nothing else, let the repository decide" |

**Maintenance state by rubric.**

| Project | Verdict | Concrete signals |
|---|---|---|
| `rust-lang/docker-rust` | **active** | 537 stars; `archived: false`; `pushed_at: 2026-09-08T18:15:07Z`; tracked stable 1.98.1 the same day the channel moved (2026-09-03); 36 open issues (`GET https://api.github.com/search/issues?q=repo:rust-lang/docker-rust+is:issue+is:open`, `total_count`, 2026-09-17) |
| `devcontainers/images` | **active, with an issue-triage backlog** | 2,127 stars; `archived: false`; `pushed_at: 2026-09-16T12:32:33Z`; 51 open issues. **Responsiveness: of the 10 most recently opened issues (#1987, #1981, #1980, #1976, #1967, #1965, #1963, #1956, #1955, #1954), 9 have no comment from an `OWNER`/`MEMBER`/`COLLABORATOR`; the one that does (#1963) was answered in under 1 day. Median days to first maintainer response is undefined because the majority are unanswered; unanswered count = 9/10** (`GET /repos/devcontainers/images/issues/<n>/comments`, filtering on `author_association`, 2026-09-17). This is a backlog, not a `dormant` trigger: the rubric requires an unpatched advisory, a broken build on current stable, or a maintainer's notice, and none is present — the image was rebuilt on 2026-09-10 against a stable released on 2026-09-03 |
| `devcontainers/features` | **active, with an issue-triage backlog** | 1,535 stars; `archived: false`; `pushed_at: 2026-09-16T13:54:04Z`; 168 open issues. **Responsiveness: 10 of the 10 most recently opened issues (#1737, #1730, #1727, #1726, #1719, #1716, #1712, #1710, #1709, #1707) have no maintainer comment; median undefined; unanswered = 10/10.** Against that, the 10 most recent commits are all merged pull requests from 2026-08-26 to 2026-09-16, including one touching `src/rust`. Verdict: PRs land, issues do not get answered. Recorded because it is a real cost of architecture C, which this report does not recommend |
| `devcontainers/spec` | **stable-quiet** | 5,716 stars; `archived: false`; `pushed_at: 2026-03-20T11:13:13Z` — ~6 months. Investigated rather than judged: this is a specification repository whose implementations (`cli`, `features`, `images`) are all active, so quiet is the expected state of a stable spec, and no `at-risk` signal exists |
| `devcontainers/ci` | **stable-quiet** | 496 stars; `archived: false`; `pushed_at: 2026-06-01T11:34:12Z`; latest release `v0.3.1900000450`, published 2026-06-01; 66 open issues |
| `devcontainers/templates` | **active** | 1,438 stars; `archived: false`; `pushed_at: 2026-09-16T13:00:50Z` |

---

### Fit for this template

**CLI target.** The strongest fit of the three, and still a modest one. Building and
running a CLI needs `cargo`, a linker and nothing else; a contributor on Linux or
macOS gains nothing from the container that `rustup` did not already give them. What
the container adds for the CLI shape is entirely about *who* is contributing: a
Windows contributor gets the only first-class path the fixed `target-os-matrix`
leaves them, and a drive-by contributor gets Codespaces. One further CLI-specific
good is real and worth naming: reproducing a Linux-only CI failure — a path-separator
assumption, a `/proc` read, a terminal-detection difference relevant to R64/R65 —
is something a macOS contributor cannot otherwise do at all.

**Library target.** The weakest fit, and it should be stated plainly rather than
padded. A library consumer never touches the devcontainer; a library contributor
needs `cargo test`, `cargo doc` and `cargo clippy`, all of which `rustup` supplies
identically on every host. The only library-specific gain is that `rust-src` and
`rust-analyzer` arrive pre-installed as components of the baked feature, which
shortens first-open latency in the editor. That is a convenience, not a capability,
and it does not on its own justify the file.

**Web target.** The best *argument* for a devcontainer in principle and, on the
evidence available to me, the weakest in practice for this template — because the
system dependencies that normally justify a web devcontainer are absent here.
R69 (`web-framework-stack`) owns `web-extra-surface`, and in this run's
`inputs/PARAMETERS.md` its value is unset (`—`), so I cannot claim a database, a TLS
stack or a native dependency exists. What I can say: `F017` makes the web surface a
Cargo feature, so it compiles in the same container with no extra provisioning, and a
Rust web service built on a pure-Rust stack typically needs no `libpq`, no `libssl`
and no system package at all. **One devcontainer definition is therefore sufficient
for all three target shapes** (LOW question answered: yes, one definition; no
per-target variant, no Docker Compose).

The one web-specific element a devcontainer would add is port forwarding, and the
correct call today is to add nothing: VS Code and Codespaces forward a port
automatically when a process starts listening
(`https://code.visualstudio.com/docs/devcontainers/containers`, 2026-09-17), and
`forwardPorts` is an optimisation that makes the forward appear before the process
starts. Hard-coding a port number now would invent a value R69 owns. **Recommended
rule: no `forwardPorts` key until R69 fixes a port; add
`"forwardPorts": [<R69's port>]` in one line when it does.**

**Fit against the py and ts precedent.** Against py: same principle, four fewer
moving parts — no `apt-get` preamble (the base already has `make`, `curl`, `git`), no
`remoteEnv` `PATH` surgery (the image exports `CARGO_HOME`/`RUSTUP_HOME`/`PATH`
itself), no root user (`remoteUser: vscode` is baked, where py's uv image runs as
root and hard-codes `/root/.bun`), and no second extension list. Against ts: this
report treats ts's omission as accidental drift, because no `D-0nn` entry records a
reason and the inferred one ("the Node toolchain is lightweight") applies at least as
strongly to `rustup` — which means it cannot be what actually decided it.

---

### Recommendation

**Adopt a devcontainer, in the minimal image-only form. Named pattern:
`inherited-image-devcontainer`.** Two files, roughly 25 lines together, no
`Dockerfile`, no `features` block, no extension list.

`.devcontainer/devcontainer.json` (`devcontainer.json` permits `//` comments — `ruff`
and `tauri` both use them):

```jsonc
{
  "name": "rs-launch-blueprint",

  // Pinned by digest per R20's principle applied to OCI references; the trailing
  // comment carries the release identity the digest hides.
  "image": "mcr.microsoft.com/devcontainers/rust:2.1.1-trixie@sha256:1648c1ac19ef6b55a001048d832956c109a5a9ad37fc6b3c82d37b6cd462bbf3", // 2.1.1-trixie

  // No "features": the image already bakes common-utils, git and the rust feature
  // (see its devcontainer.metadata label). A features block here would be a second
  // toolchain declaration beside rust-toolchain.toml — the F187/F189 shape R42 removed.

  // No "customizations": the image contributes rust-analyzer, even-better-toml and
  // lldb; .vscode/extensions.json (F193) is the repository's only other list.

  // Keep the cargo registry, crate sources and $CARGO_HOME/bin tools across rebuilds.
  // The path is the image's own CARGO_HOME. RUSTUP_HOME (/usr/local/rustup) is NOT
  // under this mount, so installed toolchains are not persisted by it. Same mount the
  // first-party devcontainers/templates src/rust template documents and ruff uses.
  "mounts": [
    {
      "source": "devcontainer-cargo-cache-${devcontainerId}",
      "target": "/usr/local/cargo",
      "type": "volume"
    }
  ],

  "postCreateCommand": "sh .devcontainer/post-create.sh"
}
```

`.devcontainer/post-create.sh`:

```sh
#!/bin/sh
# Devcontainer setup — the two-level flow (see CLAUDE.md / AGENTS.md):
#   Level 0: rustup toolchain install  (materialize rust-toolchain.toml deterministically)
#   Level 1: make bootstrap            (base toolchain: just, and whatever F180 checks)
#   Level 2: just setup                (dev env sync, git hooks, hook toolchain)
# Unlike py's slim uv base, this image already carries make, curl, git and
# ca-certificates, so there is no apt-get step here.
set -eu

# rustup >= 1.28.1 auto-installs the toolchain rust-toolchain.toml names on first use.
# Doing it here rather than inside a contributor's first `cargo` call makes the
# download visible, progress-reporting, and a create-time failure instead of a stall.
rustup toolchain install

make bootstrap
just setup
```

**Why each line is there, and what would be wrong without it.**

- **Digest pin + tag comment.** R20's decided pattern is `owner/repo@<40-hex> # vX.Y.Z`
  for third-party `uses:` clauses, enforced by two disjoint checks. Its principle —
  *the immutable identity is what is pinned; the human-readable release identity
  travels beside it as a comment* — transfers directly to an OCI reference, where the
  immutable identity is the `@sha256:` digest. The task message extends R20 to
  devcontainer features; this recommendation has no features, so the obligation lands
  entirely on the image. `mcr.microsoft.com/devcontainers/rust:2.1.1-trixie` resolved
  to index digest `sha256:1648c1ac19ef6b55a001048d832956c109a5a9ad37fc6b3c82d37b6cd462bbf3`
  (**executed**, `docker-content-digest` response header, 2026-09-17). **Pin the index
  digest, not a child manifest digest**, so the reference stays multi-architecture and
  an Apple-Silicon host still gets `linux/arm64`.
- **`trixie`, not `bookworm`, not `bullseye`.** Bullseye is retired upstream
  (`fix!: Remove EOL Debian Bullseye`, 2026-09-08). Trixie is the current Debian
  stable and the smaller of the two live variants (831 MiB against 870 MiB compressed,
  arm64).
- **No `features` block.** Stated above as the structural reason architecture B beats
  C for this repository: `rust-toolchain.toml` is the single toolchain declaration, and
  a `features` block with `version`/`profile`/`components` options would be a second
  one. It also removes a whole OCI reference from the pinning and re-verification
  surface, and sidesteps the feature's weaker rustup-fetch integrity (gate 3).
- **No `customizations` block.** See the `BASELINE-REVIEW` on F193.
- **The cargo-cache volume mount.** Both the first-party template and `ruff` use it;
  without it every container rebuild re-downloads the registry index and every crate
  source. Mounting the image's own `CARGO_HOME` (`/usr/local/cargo`) also caches the
  tools `just setup` installs through R42's generic `install-tool` recipe, since
  `cargo binstall` writes into `$CARGO_HOME/bin`. **Two properties of this mount must
  be stated rather than discovered, because both are easy to get backwards.** First,
  the mount does *not* hide the image's `/usr/local/cargo`: a new named volume is
  pre-populated from the image's directory content — "Docker copies the directory's
  contents into the volume. The container then mounts and uses the volume, and other
  containers which use the volume also have access to the pre-populated content"
  (`https://docs.docker.com/engine/storage/volumes/`, retrieved 2026-09-17) — which is
  why the `cargo`, `rustc` and `rustup` proxies under `/usr/local/cargo/bin` are still
  there for `postCreate` to use at all. Second, and this is the real cost:
  **`RUSTUP_HOME` is `/usr/local/rustup`, which is *not* under this mount** (image
  config blob, read 2026-09-17), so an installed *toolchain* is not persisted by it.
  If `rust-toolchain.toml` names a channel other than the image's baked `1.98.1`, that
  toolchain is re-downloaded after every **Rebuild Container**, though not between
  ordinary container starts. A second volume on `/usr/local/rustup` would fix that;
  it is **recorded as a P03 option, not recommended here**, because nothing in this
  item measured the cost it would remove or tested a volume-mounted `RUSTUP_HOME`.
  None of this is why `postCreate` runs `rustup toolchain install` — that line's
  justification is the one given above and nothing else: it makes a download that
  rustup would otherwise perform silently inside a contributor's first `cargo`
  invocation into a visible, progress-reporting, create-time step.
- **`rustup toolchain install`, no arguments.** Reads the active toolchain from
  `rust-toolchain.toml`, honouring its `profile = "minimal"` and
  `components = ["rustfmt", "clippy"]` (R42 layer 1).
- **`make bootstrap` then `just setup`, unchanged.** The principle in one line: py's
  `post-create.sh` ends in exactly those two commands, and so does this one.
- **`cargo fetch` deliberately omitted.** `ruff` runs it; I do not recommend it,
  because `just setup` is where the repository decides what to pre-build, and adding a
  fetch here would be the first step back toward a parallel setup script. **Flagged as
  a P03 measurement, not a decision**: if first-`cargo build` latency after create is
  judged too high, adding `cargo fetch --locked` to `just setup` — not to
  `post-create.sh` — is the change that preserves the principle.

**Dependabot: do not add a `devcontainers` entry.** R19's decision records `docker`/
`devcontainers` as "conditional on R51 and R44 shipping those files"
(`research/topics/19-dependabot-config-shape/DECISION.md:66`), so this item owes that
answer. It is **no**, and the reason is a primary-source finding: Dependabot's
`devcontainers` ecosystem parses **features only**. Its parser is literally
`FeatureDependencyParser` and its entry point is `parse_features(config_dependency_file)`
(`devcontainers/lib/dependabot/devcontainers/file_parser.rb` and
`file_parser/feature_dependency_parser.rb`,
`GET /repos/dependabot/dependabot-core/contents/...`, 2026-09-17), and it works by
shelling out to `devcontainer outdated --workspace-folder . --config <path>
--output-format json`. GitHub's own announcement matches: "update the listed
**Features** to latest … Features are pinned to the latest `major` version"
(`https://github.blog/changelog/2024-01-24-dependabot-version-updates-support-devcontainers/`,
2024-01-24). The pull request that would have added stale-**image** detection,
`dependabot/dependabot-core` #9271 "Devcontainers integration for stale images", was
**closed by stalebot on 2026-03-26 after two years with no activity**
(`GET /repos/dependabot/dependabot-core/issues/9271`, 2026-09-17). With no features
declared, the ecosystem would have nothing to do, and it would not bump the image
either way. **The image digest therefore has no automated bumper**, which is a real
cost and is carried explicitly by the re-verify trigger below rather than left
implicit. This is a downstream implication for R19, not a `CONFLICT:` — R19 already
anticipated it and R44 consumes no registered parameter.

**Positioning in the README.** The devcontainer is documented as the **secondary**
path, after the native `make check` / `make bootstrap` / `just setup` chain, and its
entry states the three things a reader cannot infer: it is Linux-only; on macOS or
Windows it needs a container runtime the template does not install (Docker Desktop,
OrbStack, Colima or Podman) or GitHub Codespaces with no local runtime at all; and it
is not the deployment image (R51).

---

### Ranked runner-up

**Runner-up 1 — architecture A: ship no devcontainer (the `ts-launch-blueprint`
shape), and record the reason.**

This is a serious runner-up, not a foil. It is what 27 of 31 surveyed Rust
repositories do, including every `rust-lang/*` repository and every recent high-growth
Rust project. It has zero maintenance surface and cannot rot.

**The condition under which it wins:** if the owner is unwilling to carry an OCI
digest that **nothing automatically bumps** — Dependabot will not (proved above), so
upkeep is either a manual bump on the re-verify trigger or adopting Renovate, which
is a new tool decision this item has no mandate to make (and note that `biome`'s
devcontainer image bump on 2026-09-09 came from exactly such a bot). A stale pinned
digest is strictly worse than no devcontainer: `ruff` is the live demonstration,
still pinning an image variant whose Debian base was deleted upstream. It also wins
outright if the owner decides Windows and Codespaces contributors are out of scope,
since that removes goods 1 and 2 of the four in `### Principles and implementation`
and leaves only a convenience.

If A wins, the deliverable changes shape rather than disappearing: `ts` and `rs` agree,
`py` becomes the outlier, and the follow-on project deletes py's `.devcontainer/` —
and in either direction the F193 `BASELINE-REVIEW` above still stands, because py's
two extension lists have drifted regardless of what rs does.

**Runner-up 2 — architecture B with a floating tag instead of a digest:**
`"image": "mcr.microsoft.com/devcontainers/rust:2-trixie"`, no digest, no pin.
**Wins if** the owner accepts that a development container is not part of the release
supply chain and prefers automatic currency to reproducibility. Cost: the container
silently changes under contributors, and `rebuild container` can produce a different
environment from the one a colleague has — the failure mode a template most wants to
avoid.

---

### Tradeoffs

**What the recommendation gives up against runner-up 1 (no devcontainer):**

- **An unautomated pin.** Two files, one OCI digest, and no bot that bumps it. This is
  the single real cost and the recommendation does not minimise it; it is carried by
  an explicit re-verify trigger, and the pattern is designed so that the entire
  maintenance surface is *one string*.
- **A second supported path to document and answer questions about**, including the
  macOS/Windows runtime prerequisite the template cannot provision.
- **A 831 MiB cold pull** for anyone who tries it.

Accepted because the owner has already fixed `target-os-matrix` to exclude Windows,
which leaves Windows contributors with no first-class path at all unless this file
exists; because the cost is bounded at two files with no `Dockerfile` to patch; and
because dropping it would diverge from py on a policy the divergence analysis marks as
one that should be decided once for all three repositories.

**What it gives up against architecture C (base + `rust` feature):**

- **Configurability** — `profile`, `components`, `targets` as JSON options. Deliberately
  given up: exercising it would create the second toolchain declaration R42 removed.
- **A smaller base layer** (360 MiB for `devcontainers/base:trixie` against 831 MiB).
  Given up because C pays it back at create time by installing rustup and four
  components on every contributor's first create, and because C's rustup fetch is
  unversioned where the image's is pinned with a hard-coded sha256.

**What it gives up against architecture D (local `Dockerfile`):**

- **Total control** of the base — including the ability to pre-install `just` or the
  R42 tool table into the image. Given up because the template would then own a Debian
  image with no CVE pipeline, and because both surveyed D adopters rotted.

**What it gives up against runner-up 2 (floating tag):** automatic currency. Given up
because a template's job is to hand every generated project a reproducible
environment.

**What the recommendation does *not* give up, contrary to the obvious worry:** MSRV
fidelity. The container does not pin the compiler the project builds with;
`rust-toolchain.toml` does, and rustup installs it.

---

### Parameters

**Owns:** none. R44's `owns:` field in `## Couplings` is empty, and this report
introduces no new registry parameter. The decision's outputs are file-level content
(the pattern above), not a shared value other items read.

**Assumes** (fixed, `docs/port/PARAMETERS.md`, owner-decided 2026-09-02):

- `assumes target-os-matrix = ubuntu-latest, macos-latest` — used twice and in opposite
  directions: it is *why* the pattern is worth adopting (Windows has no runner, so
  Windows contributors need the container), and it is what bounds the CI validation job
  to `ubuntu-latest` (GitHub's `macos-26-arm64` runner image ships no container
  runtime).
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release,
  declared as rust-version in Cargo.toml and tested in CI` — the devcontainer neither
  sets nor tests the MSRV; it is not a matrix cell.
- `assumes rust-edition = 2024` — no effect on this item.
- `assumes license = MIT OR Apache-2.0` — not evaluated; gate 1 is
  `inapplicable — owner ruling 2026-09-12 (Q7.B)`.

**Assumes (researched, read from this run's `inputs/PARAMETERS.md`, 2026-09-17):**

- `assumes package-manager-invocation = <R42's value>` — the `post-create.sh` body
  invokes `rustup`, `make` and `just` as bare executables on `PATH` and adds no
  provisioner prefix, which is exactly what R42's rule prescribes. R44 is *related to*
  R42, not a registry consumer of it (`## Couplings`), so this is alignment, not
  consumption.
- `assumes web-extra-surface = <unset in this run's inputs/PARAMETERS.md>` — R69 owns
  it and its value is `—` in the snapshot I was given. This is why the recommendation
  declares **no** `forwardPorts` key: the port number is R69's to fix. No value needs
  to change, so no `CONFLICT:` is raised.
- `assumes ci-job-structure = <unset in this run's inputs/PARAMETERS.md>` — R11 owns
  whether the devcontainer check is its own job or a step, and whether it is
  path-filtered. The validation strategy below states the *content* of the check and
  defers its wiring shape.

**`CONFLICT:` lines: none.** No consumed parameter needs a different value for this
recommendation to hold.

**Non-conflicting downstream implications, recorded so no reader has to infer them:**

- **R19** (`dependabot-config-shape`, resolved): its decision leaves `devcontainers`
  conditional on this item. The answer is **do not add the ecosystem** — see
  `### Recommendation`. R19's own re-verify list already names "R44 lands a
  devcontainer (add that ecosystem)"; this report supplies the evidence that adding it
  would be inert for a features-free `devcontainer.json`.
- **R51** (`container-image`, open): a *deployment* image is a different artifact with
  different constraints (no `SYS_PTRACE`, no `seccomp=unconfined`, no `vscode` user,
  no rustup). Nothing here pre-empts R51's base-image choice; the only ask is that
  README prose distinguishes the two.
- **R28** (`linter-and-editor-tooling`, open): owns `.vscode/extensions.json`'s
  contents (F193). The `BASELINE-REVIEW` above constrains only *where* the list lives,
  never what is in it.
- **R20** (`third-party-action-pinning-policy`, resolved): its pattern governs
  `.github/workflows/`. The CI job below pins `devcontainers/ci` by SHA with a version
  comment, exactly as R20's rule requires; the `@sha256:` image pin inside
  `.devcontainer/` is R20's *principle* applied to a new file type, not R20's checker
  extended — `zizmor` reads workflows, not `devcontainer.json`.

---

### Migration implications

File-level changes in the template. The template does not exist yet; this is what P03
creates, not a diff against anything.

| File | Change | Detail |
|---|---|---|
| `.devcontainer/devcontainer.json` | **new**, ~20 lines with comments | Exactly the content in `### Recommendation`. Keys present: `name`, `image` (digest-pinned, tag comment), `mounts`, `postCreateCommand`. Keys deliberately absent: `features`, `customizations`, `remoteUser`, `remoteEnv`, `forwardPorts`, `runArgs`, `build` |
| `.devcontainer/post-create.sh` | **new**, ~8 executable lines | `#!/bin/sh`, `set -eu`, `rustup toolchain install`, `make bootstrap`, `just setup`. Mode `0755`. No `apt-get`, no `rustup component add`, no `cargo install` |
| `rust-toolchain.toml` | **no change** | Already R42 layer 1's; the devcontainer reads it, never writes it |
| `Makefile` / `Justfile` | **no change** | The principle is that the devcontainer adds no recipe. If P03 finds it wants `just devcontainer-up` as a convenience, that is a new recipe wrapping `devcontainer up`, not a change to `bootstrap` or `setup` |
| `.vscode/extensions.json` | **no change** | Remains the single recommendation list (F193) |
| `.github/dependabot.yml` | **no change** | No `devcontainers` entry; see `### Recommendation` |
| `.github/workflows/` | **one job added**, shape owned by R11 | A `devcontainer` check on `ubuntu-latest` only, path-filtered to `.devcontainer/**`, using `devcontainers/ci@513af61f4de4f75d37e4438f184ba4358f0fc1ca # v0.3.1900000450` (tag SHA from `GET /repos/devcontainers/ci/tags`, 2026-09-17), pinned per R20 |
| `README.md` / `CONTRIBUTING.md` | **one section added** | The devcontainer as the secondary path, with the Linux-only fact, the local-runtime prerequisite on macOS and Windows, and the Codespaces alternative |
| `.gitattributes` / line endings | **check** | `post-create.sh` must be LF; a CRLF checkout on a Windows host — the population this file exists for — makes `#!/bin/sh\r` fail inside the container. Flagged as a P03 item because the repository's `.gitattributes` policy is not decided in this item |

---

### Validation strategy

**Nothing in this section was executed against the template, because the template does
not exist.** These are **planned** checks for P03. Separately, the checks labelled
**executed** below were run in this research session against public endpoints and
against this host's `rustup`; they are the evidence base, not acceptance of the
template.

**Executed in this session (evidence, not acceptance):**

| # | Check | Result |
|---|---|---|
| E1 | `GET https://mcr.microsoft.com/v2/devcontainers/rust/manifests/2.1.1-trixie` with `Accept: application/vnd.oci.image.index.v1+json` | `mediaType: application/vnd.oci.image.index.v1+json`; platforms `linux/amd64`, `linux/arm64`; `docker-content-digest: sha256:1648c1ac19ef6b55a001048d832956c109a5a9ad37fc6b3c82d37b6cd462bbf3` |
| E2 | arm64 child manifest + config blob for the same tag | 15 layers, 871,370,327 bytes compressed; `RUST_VERSION=1.98.1`; `remoteUser: vscode`; `org.opencontainers.image.source = https://github.com/rust-lang/docker-rust` |
| E3 | Same for `devcontainers/universal:6` | `linux/amd64` only; 4,006,294,640 bytes compressed |
| E4 | `rustup toolchain install --help` on this host | "Install or update the given toolchains, **or by default the active toolchain**"; rustup 1.29.1 (d95a37b6a 2026-08-13) |
| E5 | `.devcontainer` presence probe across 32 repositories | 4 of 31 Rust-primary repositories present |
| E6 | `actions/runner-images` macOS-26-arm64 readme, case-insensitive `docker` count | **0** matches in 261 lines; Ubuntu 24.04 readme lists Docker Client/Server 28.0.4 |
| E7 | GHCR anonymous-token manifest read for `ghcr.io/devcontainers/features/rust` | tags `1` and `1.6.0` both resolve to `sha256:846c949f52c9dea98d4f90a11957cbf152fb3f6e8a70ddd7cb83014a7d1d0c98` |

**Planned for P03 — the item-specific empirical acceptance check.** Run on
`ubuntu-latest`; `macos-latest` cannot run any of it (E6).

```bash
# V1 — the container builds and the repository's own gate passes inside it.
npx --yes @devcontainers/cli up --workspace-folder .
npx --yes @devcontainers/cli exec --workspace-folder . just <verify>
#   <verify> is the repository's own aggregate verification recipe; its NAME is P03's
#   to choose and is deliberately not asserted here.
# Expected: exit 0 for both. V1 is the whole principle in two commands — a contributor
# with nothing installed reaches a state where the repository's own verification passes.

# V2 — the container runs the toolchain the REPOSITORY declares, not the image's.
npx --yes @devcontainers/cli exec --workspace-folder . rustc --version
# Expected: the version implied by rust-toolchain.toml's channel (R27's value), NOT
# necessarily the image's baked RUST_VERSION. This check is what proves the devcontainer
# is a cache and not a second toolchain declaration. It must be written to FAIL if the
# two coincide only by accident — assert against the parsed rust-toolchain.toml channel.

# V3 — postCreate invents no parallel setup (text check, no network, no container).
! /usr/bin/grep -nE '^[[:space:]]*(apt-get|rustup component add|cargo install|pip |npm )' \
    .devcontainer/post-create.sh
# Expected: exit 0 (no match). Guards the shared principle directly.

# V4 — no second extension list.
! /usr/bin/grep -n '"extensions"' .devcontainer/devcontainer.json
# Expected: exit 0 (no match). Enforces the F193 BASELINE-REVIEW.

# V5 — every OCI reference in .devcontainer/ is digest-pinned with a tag comment.
#     R20's principle, applied to OCI refs; the R20 regex adapted from 40-hex to sha256.
/usr/bin/grep -nE '"(image|[a-z0-9.-]+/[a-z0-9./-]+)"[[:space:]]*:' .devcontainer/devcontainer.json \
  | /usr/bin/grep -vE '@sha256:[0-9a-f]{64}"[,]?[[:space:]]*//[[:space:]][A-Za-z0-9._-]+'
# Expected: no output. Written by P03 as scripts/check-devcontainer-pins.sh, in the
# same shape as R20's scripts/check-action-pin-comments.sh, and a SEPARATE check from it.

# V6 — the pinned digest still resolves and is still multi-arch (scheduled lane, R34).
curl -sS -H "Accept: application/vnd.oci.image.index.v1+json" \
  "https://mcr.microsoft.com/v2/devcontainers/rust/manifests/sha256:<pinned>" \
  | jq -e '[.manifests[] | select(.platform.os=="linux") | .platform.architecture]
           | (index("amd64") != null) and (index("arm64") != null)'
# Expected: exit 0. This is the substitute for the Dependabot bump that does not exist.
```

**Control that makes V2 non-vacuous.** A check that only asserts `rustc --version`
exits 0 would pass on the image's baked toolchain and prove nothing. P03 must run V2
once with `rust-toolchain.toml`'s channel deliberately set to a version the image does
*not* bake, confirm the reported version follows the file, and confirm the run fails
when the assertion is inverted. Without that control the check is a status check, not
a test — the failure mode R42's revision-9 audit rejected.

**Explicitly not validated here and left as unproven items for P03:**

1. **Wall-clock cold-create time.** The 831 MiB figure is a compressed-byte total, not
   a duration. Nothing in this item timed a pull or a create.
2. **Whether `devcontainer outdated` (hence Dependabot) reports updates for a
   digest-pinned *feature* reference.** Not exercised. It does not affect the
   recommendation, which declares no features, but it would matter if architecture C
   were ever adopted.
3. **The cargo-cache volume's runtime behaviour**, on two points. (a) Docker's
   pre-population of a new named volume from the image directory is cited from Docker's
   own documentation, **not observed in this container** — P03 should confirm that
   `cargo --version` succeeds inside a freshly created container with the mount in
   place. (b) Whether the `vscode` user can write to a fresh named volume at
   `/usr/local/cargo`: predicted benign (the rust feature's `install.sh` sets
   `chmod g+r+w+s` on `CARGO_HOME`), **not observed**. A second volume on
   `RUSTUP_HOME` (`/usr/local/rustup`) to persist installed toolchains across a
   container rebuild was likewise **not tested** and is recorded as a P03 option only.
4. **Codespaces behaviour specifically**, as opposed to local `devcontainer up`.
5. **Line-ending behaviour of `post-create.sh` on a Windows checkout** — the
   `.gitattributes` item in `### Migration implications`.

---

### Confidence & re-verify trigger

**Confidence: high on the mechanics, medium on the adopt-or-drop call.**

High on every mechanical claim, because each is read from a first-party artifact and
most were executed: that a canonical first-party Rust devcontainer image exists and is
the Rust project's own image (its `org.opencontainers.image.source` label); that it is
multi-architecture (its index); that it already carries rustup, `make`, `git`,
`remoteUser: vscode` and the rust-analyzer extension contribution (its config blob and
metadata label); that `rust-toolchain.toml` governs over the baked version (rustup's
CHANGELOG 1.28.1); that `rustup toolchain install` with no argument installs the active
toolchain (its own `--help`); that Dependabot parses features and not images
(dependabot-core's own parser, plus the stalebot-closed #9271); and that
`macos-latest` has no container runtime (GitHub's own image inventory).

Medium on *whether to adopt at all*, and the reason is the survey: 27 of 31 of the
most-regarded Rust projects decline this file, and three of the four that carry one
have let it rot. That is a genuine ecosystem signal against, and it is weighed against
an owner decision that already exists (Windows off the CI matrix), a template's
different relationship to drive-by contributors, and a cross-repo policy the
divergence analysis says should be decided once. **A reader who weighs ecosystem
practice above the template's own contributor story should choose runner-up 1, and
this report has tried to give them the evidence to do so rather than only the evidence
for its own recommendation.**

**Re-verify by 2027-03-17, or earlier on any of:**

1. **The pinned digest stops resolving or stops being multi-arch** (V6 fails in the
   scheduled lane). Since nothing bumps this pin automatically, V6 *is* the maintenance
   mechanism and its failure is the bump trigger.
2. **`devcontainers/images` publishes a new major image line** (currently `2.x`;
   `dev.containers.release v0.4.33`), or `rust-lang/docker-rust` retires `trixie` the
   way it retired `bullseye` on 2026-09-08.
3. **Dependabot gains image support for the `devcontainers` ecosystem** — i.e.
   `dependabot-core` reopens or supersedes #9271, or its
   `devcontainers/lib/dependabot/devcontainers/file_parser.rb` gains an image parser
   beside `parse_features`. That would remove the single real cost in `### Tradeoffs`
   and strengthen the recommendation against runner-up 1.
4. **rustup changes toolchain auto-install again.** It was removed in 1.28.0 and
   restored in 1.28.1; a second removal would make `rustup toolchain install` in
   `postCreate` load-bearing rather than merely well-mannered — which is an argument
   for keeping that line whatever happens.
5. **`devcontainers/features` `rust` gains an option meaning "install rustup and let
   the repository decide everything else"** — the `components: "none"` work merged
   2026-09-16 is the first step. That would make architecture C safe here and reopen
   the base-plus-feature comparison on size grounds.
6. **R69 fixes a web port**, which adds one `forwardPorts` line; or **R51 lands a
   deployment image**, which adds one README sentence distinguishing the two.
7. **`devcontainers/images` or `devcontainers/features` shows a `dormant` signal under
   the rubric** — an unpatched advisory, a broken build on current stable, or a
   maintainer's notice. The 9/10 and 10/10 unanswered-issue counts recorded above are
   *not* that signal today, but they are the thing to watch: if commit activity stops
   while issues stay unanswered, the verdict moves to `at-risk` and runner-up 1 gains.
8. **GitHub adds a container runtime to macOS runners**, which would let the V1/V2
   acceptance check run on both cells of the fixed matrix instead of one.

---

### Sources

Every URL below was retrieved **2026-09-17 (UTC)** unless another date is given.

**Specification and client documentation**
- `https://docs.docker.com/engine/storage/volumes/` — a new named volume is
  pre-populated from the image directory: "Docker copies the directory's contents into
  the volume. The container then mounts and uses the volume, and other containers which
  use the volume also have access to the pre-populated content."
- `https://containers.dev/implementors/spec/` — image metadata (`devcontainer.metadata`
  label), merge order, "the `devcontainer.json` is considered last".
- `https://containers.dev/implementors/features/` — feature reference grammar; digest
  references (`@sha256:…`); "The `:latest` version annotation is added implicitly if
  omitted".
- `https://code.visualstudio.com/docs/devcontainers/containers` — extensions installed
  at container creation from `devcontainer.json`; `forwardPorts`; temporary forwarding.

**First-party Rust artifacts**
- `https://github.com/rust-lang/docker-rust` — `stable/trixie/Dockerfile` (rustup
  pinned to archive `1.29.0` with per-architecture sha256; `FROM buildpack-deps:trixie`);
  `stable/trixie/slim/Dockerfile`; commits `chore: Update Rust to 1.98.1` (2026-09-03)
  and `fix!: Remove EOL Debian Bullseye` (2026-09-08).
- `https://static.rust-lang.org/dist/channel-rust-stable.toml` — `date = "2026-09-03"`,
  `[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`.
- `https://github.com/rust-lang/rustup` — `CHANGELOG.md`, 1.28.1 (2025-03-05)
  "Automatic install is enabled by default but can be opted out by setting
  `RUSTUP_AUTO_INSTALL`… to `0`"; 1.28.2 `rustup set auto-install disable`.
- `rustup toolchain install --help`, rustup 1.29.1 (d95a37b6a 2026-08-13), executed on
  this host.

**Devcontainer images, features and templates**
- `https://mcr.microsoft.com/v2/devcontainers/rust/tags/list` (432 tags);
  `/manifests/2.1.1-trixie`, `/manifests/2.1.1-bookworm`, and the arm64 child
  manifests and config blobs.
- `https://mcr.microsoft.com/v2/devcontainers/base/manifests/trixie`;
  `https://mcr.microsoft.com/v2/devcontainers/universal/manifests/6`.
- `https://ghcr.io/v2/devcontainers/features/rust/manifests/{1,1.6.0}` and
  `/tags/list` (anonymous token from `https://ghcr.io/token?scope=repository:devcontainers/features/rust:pull`).
- `https://github.com/devcontainers/features` — `src/rust/devcontainer-feature.json`
  (v1.6.0 defaults, `customizations.vscode`, `containerEnv`, `capAdd`, `securityOpt`);
  `src/rust/install.sh` at tag `feature_rust_1.6.0` (rustup fetch and `sha256sum -c`);
  `/commits?path=src/rust`.
- `https://github.com/devcontainers/templates` — `src/rust/.devcontainer/devcontainer.json`.
- `https://github.com/devcontainers/cli` — `src/spec-configuration/containerCollectionsOCI.ts`
  (digest parsing for feature references; sha256-only).
- `https://github.com/devcontainers/ci` — `/tags`, `v0.3.1900000450` =
  `513af61f4de4f75d37e4438f184ba4358f0fc1ca`, published 2026-06-01.
- `https://github.com/docker-library/buildpack-deps` — `debian/trixie/Dockerfile`
  line 48, `make`.

**Dependabot**
- `https://github.com/dependabot/dependabot-core` —
  `devcontainers/lib/dependabot/devcontainers/file_parser.rb` (`parse_features`),
  `file_parser/feature_dependency_parser.rb` (`devcontainer outdated … --output-format json`);
  issue/PR #9271 "Devcontainers integration for stale images", closed 2026-03-26 by
  stalebot after two years; issue #7000, closed.
- `https://github.blog/changelog/2024-01-24-dependabot-version-updates-support-devcontainers/`
  (2024-01-24) — Features updated to the latest major version; security updates not
  supported.
- `https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories`
  — `devcontainers`: version updates ✓, security updates ✗.

**GitHub runner images**
- `https://github.com/actions/runner-images` — `images/macos/macos-26-arm64-Readme.md`
  (261 lines, 0 case-insensitive `docker` matches);
  `images/ubuntu/Ubuntu2404-Readme.md` (Docker Client 28.0.4, Docker Server 28.0.4,
  Docker Compose 2.38.2).

**Practice survey and figures** — all via `gh api` (authenticated; no token printed):
- `GET https://api.github.com/repos/<o>/<r>/contents/.devcontainer` for the 32
  repositories listed in `### Landscape`.
- `GET https://api.github.com/repos/<o>/<r>` for `stargazers_count`, `archived`,
  `pushed_at`, `language`, `license.spdx_id`.
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for
  `total_count` (never `open_issues_count`).
- `GET https://api.github.com/repos/<o>/<r>/commits?path=.devcontainer/devcontainer.json&per_page=1`
  for each adopter's last-touched date.
- `GET https://api.github.com/repos/<o>/<r>/issues/<n>/comments` filtered on
  `author_association ∈ {OWNER, MEMBER, COLLABORATOR}` for the responsiveness rows.
- `GET https://api.github.com/repos/{astral-sh/ruff,biomejs/biome,denoland/deno,tauri-apps/tauri,anthropics/claude-code}/contents/.devcontainer/*`
  for each adopter's file content.

**Source repositories, read through their pins**
- `git -C ~/c/py-launch-blueprint show b08bccfb:.devcontainer/devcontainer.json`,
  `…:.devcontainer/post-create.sh`, `…:.vscode/extensions.json` — all claims about py
  in this report are from commit **`b08bccfb`**, never from that checkout's HEAD.
- `git -C ~/c/ts-launch-blueprint ls-tree cb1cbcb2 -- .devcontainer` → 0 entries;
  `git -C ~/c/ts-launch-blueprint show cb1cbcb2:.vscode/extensions.json` — all ts
  claims are from commit **`cb1cbcb2`**.

**Repository context (this repo, working tree)**
- `docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md` (F179–F183, F187–F189, F193,
  F200), `docs/port/DIVERGENCE-ANALYSIS.md:172` and its "How to read a row" and
  "Cause classes" tables, `research/topics/42-dev-toolchain-provisioning/DECISION.md`
  (revision 10), `research/topics/20-third-party-action-pinning-policy/DECISION.md`
  (`## Decision`), `research/topics/19-dependabot-config-shape/DECISION.md:66` and its
  re-verify paragraph, `research/CLAUDE.md`, and this run's `inputs/PARAMETERS.md`.

**Method notes.** Endpoints queried: the MCR registry v2 API (`/tags/list`,
`/manifests/<tag|digest>`, `/blobs/<digest>`, with OCI index and manifest `Accept`
headers and redirect-following for blobs); the GHCR v2 API with an anonymous pull
token; `https://static.rust-lang.org/dist/channel-rust-stable.toml`; the GitHub REST
API through authenticated `gh api` for `/repos/<o>/<r>`, `/contents/<path>` (including
`Accept: application/vnd.github.raw` for files above the base64 size limit),
`/commits`, `/tags`, `/releases`, `/issues/<n>`, `/issues/<n>/comments` and
`/search/issues`; and `https://containers.dev/`, `https://code.visualstudio.com/docs/`
and `https://docs.github.com/` / `https://github.blog/` for documentation. No token or
environment was printed. All counting used `/usr/bin/grep` and `/usr/bin/head`
explicitly, and no count in this report was taken from output truncated by a pipe —
the case-insensitive `docker` count on the macOS runner readme was taken with
`/usr/bin/grep -ci` over the whole 261-line file.

**Crate-figure table: `inapplicable` with reasons.** R44 is a `pattern` item and
recommends no crate, so the six crate figures do not apply and are not silently
omitted: *90-day downloads* — `inapplicable`, no crates.io package; *all-time
downloads* — `inapplicable`, same; *last release* — `inapplicable` as a crates.io
figure, and replaced by the pattern-appropriate equivalents actually retrieved
(`dev.containers.release v0.4.33` / `dev.containers.timestamp` 2026-09-10 for the
image; `feature_rust_1.6.0` for the feature; `v0.3.1900000450`, 2026-06-01 for the
action); *stars / archived / pushed_at* — **retrieved and reported** for all seven
supporting repositories; *open issues* — **retrieved via `/search/issues` `total_count`**
for six of them; *issue responsiveness* — **retrieved** for the two repositories whose
maintenance actually bears on the recommendation; *advisories* — `inapplicable`, there
is no `https://rustsec.org/packages/<name>.html` page for an OCI image, and the stated
substitute is the installer-integrity comparison under gate 3.

**What I could not verify.** (1) Wall-clock cold-create and pull time — no timing was
run; every size figure is compressed bytes from a manifest. (2) Whether
`devcontainer outdated`, and therefore Dependabot, reports an available update for a
**digest-pinned feature** reference — not exercised; it does not bear on the
recommendation, which declares no features. (3) The cargo-cache volume's runtime
behaviour: Docker's pre-population of a new named volume is cited from Docker's own
documentation but was not observed in this container, the `vscode` user's write access
to a fresh volume is predicted benign from the feature's `chmod g+r+w+s` but not
observed, and a second volume on `RUSTUP_HOME` was not tested.
(4) Codespaces-specific behaviour, as distinct from local `devcontainer up`. (5) Any
authoritative GitHub documentation sentence stating that container jobs require a
Linux runner — two candidate documentation pages were fetched and neither contained
such a statement, so the claim in gate 4 rests instead on GitHub's own published
software inventory for the macOS-26-arm64 and Ubuntu-24.04 runner images, which is
stronger evidence and is cited in its place. (6) `rust-toolchain.toml`'s `channel`
value, which R27 owns and which was open at the time of this run — V2's assertion is
written against whatever R27 fixes.
