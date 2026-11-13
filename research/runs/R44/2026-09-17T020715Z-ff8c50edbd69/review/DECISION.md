# 2026-09-17 — R44 — devcontainer-environment (pattern, Focused) — decision (revision 1)

## Decision

**Status.** This decision is a **proposal validated in the implementation phase**
(owner ruling, 2026-09-10). P02 is research only: the template does not exist yet,
P03 builds it, and P03's CI is what proves the recommendation. This document
records what the research found, what was verified here, and what was not; the
unverified parts are enumerated under `## Engines` as what P03 must validate. A
decision that does not survive implementation is revised against this recorded
research, not researched again from scratch. Nothing was built for this decision
and no container was run: every container fact below is read from the registry's
HTTP API, which needs no container runtime.

**Fitness gate 1 (licence compatibility) is `inapplicable — owner ruling
2026-09-12 (Q7.B)`** (`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check
for anything the template uses"). Licences appear below as recorded figures, never
as tests, and **nothing is excluded on licence**.

**Recommendation — adopt a devcontainer in the minimal image-only form. Named
pattern: `inherited-image-devcontainer`.** Two files, no `Dockerfile`, no
`features` block, no extension list. The image is
`mcr.microsoft.com/devcontainers/rust:2.1.1-trixie`, pinned to its index digest
`sha256:1648c1ac19ef6b55a001048d832956c109a5a9ad37fc6b3c82d37b6cd462bbf3`
(`GET https://mcr.microsoft.com/v2/devcontainers/rust/manifests/2.1.1-trixie`,
`docker-content-digest` response header, retrieved 2026-09-17; check 1a).

`.devcontainer/devcontainer.json` — `devcontainer.json` permits `//` comments:

```jsonc
{
  "name": "rs-launch-blueprint",

  // Digest-pinned per R20's principle applied to an OCI reference: the
  // immutable identity is pinned, the human-readable release identity travels
  // beside it as a trailing comment. Pin the INDEX digest, not a child
  // manifest digest, so the reference stays multi-architecture.
  "image": "mcr.microsoft.com/devcontainers/rust:2.1.1-trixie@sha256:1648c1ac19ef6b55a001048d832956c109a5a9ad37fc6b3c82d37b6cd462bbf3", // 2.1.1-trixie

  // No "features": the image already bakes common-utils, git and the rust
  // feature (its own devcontainer.metadata label, check 1f). A features block
  // would be a second toolchain declaration beside rust-toolchain.toml — the
  // F187/F189 shape R42 removed.

  // No "customizations": the image contributes rust-analyzer, even-better-toml
  // and lldb (check 1f); .vscode/extensions.json (F193) is the only other list.

  // Keep the cargo registry, crate sources and $CARGO_HOME/bin tools across
  // rebuilds. The path is the image's own CARGO_HOME (check 1e). RUSTUP_HOME
  // (/usr/local/rustup) is NOT under this mount, so installed toolchains are
  // not persisted by it.
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

`.devcontainer/post-create.sh`, mode `0755`:

```sh
#!/bin/sh
# Devcontainer setup. The repository's own chain, nothing parallel to it:
#   Level 0: rustup toolchain install  (materialize rust-toolchain.toml)
#   Level 1: make bootstrap            (F179-F182 Level 1)
#   Level 2: just setup                (F179-F182 Level 2)
# Unlike py's slim uv base, this image already carries make, curl, git and
# ca-certificates, so there is no apt-get step here.
set -eu

rustup toolchain install

make bootstrap
just setup
```

**Ledger rows this settles.** `F200` (devcontainer — base image, `postCreate`
bootstrap, in-container VS Code config; origin `py-only`, verdict `DIVERGENT`,
item R44) is the row this decision answers, and the answer is *adopt, in the shape
above*. The row's verdict and origin do not change; a `DIVERGENT` row is settled
by its item's decision, not by a verdict rewrite. `F193` (VS Code
recommended-extensions list, `COMMON → REUSE`) is **not** settled here: this
decision proposes an amendment to its Notes and applies nothing — see the
`BASELINE-REVIEW` under `### Principles and implementation` and its disposition
under `## Engines`.

**How macOS hosts reach a Linux devcontainer — stated, because a reader cannot
infer it.** The image index lists `linux/amd64` **and** `linux/arm64` (check 1b),
so an Apple-Silicon macOS host runs the container natively rather than under
emulation. Reaching it takes one of two things, **neither of which the template
ships or provisions**: locally, a third-party container runtime — Docker Desktop,
OrbStack, Colima or Podman — plus the VS Code Dev Containers extension; or
remotely, GitHub Codespaces, which needs no local runtime at all. **The CI job
that exercises the devcontainer runs on `ubuntu-latest` only.** `macos-latest`
resolves to GitHub's macOS 26 Arm64 runner image (check 3a), whose published
software inventory contains **0** case-insensitive matches for `docker` across its
261 lines, where the Ubuntu 24.04 inventory lists a Docker Client, Docker Server
and Docker Compose (check 3b). That is a statement about the *runner*, not about a
developer's Mac.

**Windows.** `target-os-matrix` is fixed at `ubuntu-latest, macos-latest`, so a
Windows contributor has **no CI-validated, supported path** today. They can still
install `rustup` and build; what they cannot get is a first-class environment this
template stands behind. The devcontainer, reached through the same local-runtime
path as macOS, is that path. This is the strongest single reason to adopt, and it
follows from an owner decision already taken rather than from a preference
expressed here.

**Why each line is there.**

| Element | Why | What would be wrong without it |
|---|---|---|
| Digest pin + trailing tag comment | R20's decided pattern for `uses:` clauses is `owner/repo@<40-hex> # vX.Y.Z`, whose principle is that the immutable identity is pinned and the readable release identity travels beside it. An OCI reference's immutable identity is its `@sha256:` digest | A floating tag silently changes the environment between two contributors' rebuilds |
| Index digest, not a child digest | The index carries both `linux/amd64` and `linux/arm64` (check 1b) | Pinning a child manifest would drop Apple-Silicon hosts to emulation or to failure |
| `trixie`, not `bookworm`, not `bullseye` | `rust-lang/docker-rust` removed EOL Debian bullseye (`fix!: Remove EOL Debian Bullseye`, 2026-09-08, cited from `raw/opus.md`; **not** re-executed here). Trixie is current Debian stable and the smaller of the two live variants — 831 MiB against bookworm's 870 MiB, the bookworm figure likewise carried from `raw/opus.md` and not re-executed (see `## Empirical check`) | A bullseye tag still resolves in the registry, so the trap is silent |
| No `features` block | `rust-toolchain.toml` is the template's single toolchain declaration (R42 layer 1). A `features` block with `version`/`profile`/`components` options is a second one | It also removes a second OCI reference from the pinning surface and sidesteps the feature installer's weaker rustup provenance (check 5a vs 5d) |
| No `customizations` block | The image metadata already contributes `rust-lang.rust-analyzer`, `tamasfe.even-better-toml`, `vadimcn.vscode-lldb` and `files.watcherExclude` on `target/` (check 1f) | A second extension list is a second source of truth with no mechanism keeping it honest — measured in py at check 7b |
| Cargo-cache volume mount on `/usr/local/cargo` | The image's own `CARGO_HOME` (check 1e); the first-party `devcontainers/templates` `src/rust` template documents this mount and `astral-sh/ruff` uses it | Without it every rebuild re-downloads the registry index and every crate source. It also caches what R42's generic `install-tool` recipe puts in Cargo's install root, which is `$CARGO_HOME/bin` by default — **asserted from R42's recipe shape, not observed in a container; P03 confirms** |
| `rustup toolchain install`, no arguments | rustup's own help reads "Install or update the given toolchains, or by default the active toolchain" (check 6b), and inside a directory carrying `rust-toolchain.toml` the active toolchain is the one that file names | rustup ≥ 1.28.1 auto-installs anyway (check 6a), but silently, inside whichever `cargo` call a contributor happens to make first. This line moves that download to create time, where it reports progress and where a failure is visible |
| `make bootstrap` then `just setup`, unchanged | The shared principle in one line: py's `post-create.sh` ends in exactly those two commands (check 7a), and so does this one | Any install line here would be a second setup script beside F179–F182 |
| No `apt-get` preamble | The image descends from `buildpack-deps:trixie` (check 5d) and bakes the `git` and `common-utils` features (check 1f), so `make`, `curl` and `git` are present | py needs its preamble because its uv base is slim (check 7a); copying it would be cargo-culting py's base image constraint |
| No `forwardPorts` | R69 has since published `web-extra-surface`, and it fixes **no** port: "every service knob such as host, port, log format and drain deadline stays an environment variable named by R77" (check 9d) | Hard-coding a port would invent a value R77 owns. Adding one line, `"forwardPorts": [<port>]`, is the whole change if R77 ever fixes one |
| `cargo fetch` deliberately omitted | `ruff`'s `post-create.sh` runs it; `just setup` is where this repository decides what to pre-build | Adding it here is the first step back toward a parallel setup script. If first-build latency proves too high, `cargo fetch --locked` belongs in `just setup`, not in `post-create.sh` — a P03 measurement, not a decision taken here |

**Keys deliberately absent** from `devcontainer.json`, each because the image
already supplies it or because another item owns it: `features`, `customizations`,
`remoteUser` (baked as `vscode`, check 1f), `remoteEnv` (the image exports
`CARGO_HOME`, `RUSTUP_HOME` and `PATH`, check 1e), `forwardPorts`, `runArgs`,
`capAdd`/`securityOpt` (baked as `SYS_PTRACE` and `seccomp=unconfined`, check 1f),
and `build`.

**Dependabot: do not add a `devcontainers` ecosystem entry.** R19's decision leaves
that ecosystem "conditional on R51 and R44 shipping those files", so this item owes
the answer, and the answer is **no**. Dependabot's `devcontainers` ecosystem parses
**features only**: its parser entry point calls `parse_features(config_dependency_file)`
and the file contains no image parsing at all (check 4a), and the pull request that
would have added stale-image detection, `dependabot/dependabot-core` #9271
"Devcontainers integration for stale images", is closed (2026-03-26, check 4b).
With no features declared the ecosystem would have nothing to do. **The image
digest therefore has no automated bumper.** That is the single real cost of this
recommendation; it is carried explicitly by the re-verify trigger below rather than
left implicit, and it is the condition that makes the runner-up win. This is a
downstream implication for R19, not a `CONFLICT:` — R19 anticipated it and R44
consumes no registered parameter.

**Positioning in the README.** The devcontainer is documented as the **secondary**
path, after the native `make check` / `make bootstrap` / `just setup` chain, and
its entry states the three facts a reader cannot infer: it is Linux-only; on macOS
or Windows it needs a container runtime the template does not install, or
Codespaces with none; and it is **not** the deployment image, which is R51's and is
a different artifact with different constraints (no `SYS_PTRACE`, no
`seccomp=unconfined`, no `vscode` user, no rustup).

**Fitness gates, applied before popularity was weighed.** Gates 3, 5 and 6 have no
literal crate meaning for a `pattern` item; the substitute is given rather than the
gate dropped. Crate figures (90-day and all-time downloads, crates.io last release,
RustSec advisories) are `inapplicable`: this item recommends no crate and there is
no `https://rustsec.org/packages/<name>.html` page for an OCI image.

| Gate | Application here | Verdict |
|---|---|---|
| 1 · licence | — | **`inapplicable — owner ruling 2026-09-12 (Q7.B)`**. Recorded as figures only: `rust-lang/docker-rust` Apache-2.0 (`GET https://api.github.com/repos/rust-lang/docker-rust`, `.license.spdx_id`, 2026-09-17); `devcontainers/*` MIT per `raw/opus.md`. Nothing excluded on licence |
| 2 · MSRV | Does the candidate constrain the toolchain the repository declares? | **Passes, by not constraining it.** The image bakes `RUST_VERSION=1.98.1` (check 1e) but carries `rustup`, and `rust-toolchain.toml` governs with auto-install (check 6a). Nothing in `.devcontainer/` touches `rust-version` in `Cargo.toml` or the MSRV CI job. **The devcontainer is not an MSRV matrix cell and must not be treated as one** |
| 3 · advisories / `unsafe` | No crate. Substitute: installer integrity | **Stated, with a real difference measured.** The image's upstream fetches `rustup-init` from a **versioned** archive path (`rustup/archive/1.29.0/`) and verifies it against **7 hard-coded per-architecture sha256 constants** in the Dockerfile (check 5d). The `rust` feature fetches the **unversioned** `rustup/dist/` binary and verifies it against `rustup-init.sha256` served from the same host, with **0** hard-coded constants (check 5a) — corruption protection, not provenance. This is a point for the image over the feature. No `unsafe` posture applies |
| 4 · runs on `ubuntu-latest, macos-latest` | The decisive gate | **Passes, with a stated asymmetry.** Native `linux/arm64` and `linux/amd64` children (check 1b), so a macOS developer host runs it natively; but the `macos-latest` runner ships no container runtime (check 3b), so **CI validation is `ubuntu-latest`-only**. The container is not a CI matrix cell, so this bounds where the check runs, not whether the pattern is admissible |
| 5 · default features / async-runtime coupling | No crate. Substitute: what the image turns on by default | **Stated.** Baked: `common-utils:2`, `git:1`, `rust:1`; `remoteUser: vscode`; `capAdd: ["SYS_PTRACE"]`; `securityOpt: ["seccomp=unconfined"]` (check 1f). The last two loosen the default sandbox so a debugger can attach — accepted for a development container, and the reason it must never be confused with R51's deployment image. No async-runtime coupling exists |
| 6 · binary-size / compile-time cost | No crate. Substitute: cold-pull size | **Stated, and bounded honestly.** `devcontainers/rust:2.1.1-trixie`, arm64: **15 layers, 871,370,327 compressed bytes ≈ 831 MiB** (check 1d). `devcontainers/universal:6`: amd64-only (check 2a) and, per `raw/opus.md`, ≈ 3,821 MiB. **Wall-clock pull and create time was not measured**; 871,370,327 is a byte total, not a duration |

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** Read from py's two files at the pinned commit `b08bccfb` (check 7a):

> A contributor with no project toolchain installed, on a host the template does
> not otherwise support, can reach a fully bootstrapped working environment by
> opening the repository — and that environment is produced by the repository's
> own single bootstrap chain, not by a second, parallel set of setup instructions.

The second clause is the load-bearing one, and py demonstrates it literally: its
`post-create.sh` ends in exactly `make bootstrap` and `just setup` (check 7a), the
same Level-1/Level-2 pair a native contributor runs (F179–F182, `COMMON → REUSE`).

**Agreement level — architectural pattern and policy, not value.**

| Element | Level at which agreement is required | Must agree across py / ts / rs? |
|---|---|---|
| Whether a containerised path exists at all | **policy** — a project-wide call about how contributors are onboarded | **Yes.** `docs/port/DIVERGENCE-ANALYSIS.md` classifies F200 as cause class **D**, `harmonize: partly`, with the adopt-or-drop half marked `yes`: "adopt-or-drop is a shared org call" |
| `postCreate` delegates to the repository's own bootstrap chain rather than restating it | **architectural pattern** | **Yes.** This is the principle above, and it is what keeps the devcontainer from becoming a second source of truth |
| The repository declares its editor-extension set exactly once | **architectural pattern** | **Yes** — and py violates it today; see the `BASELINE-REVIEW` below |
| Base image, tag, `remoteUser`, cache mounts, ecosystem-specific pre-steps | **capability**, realised natively | **No.** Rust-specific; the same divergence row marks this half `no` |

**Is the pattern still appropriate in this ecosystem? Partly, and its value is
narrower in Rust than in Python.** py's devcontainer exists partly because
Python's interpreter-plus-virtualenv story is host-entangled, and the image's whole
contribution there is a pre-provisioned CPython and `uv`. Rust has no analogue:
`rustup` is one installer, identical on every host, and `rust-toolchain.toml`
already makes the toolchain a committed fact (R42 layer 1). The container's
contribution in Rust reduces to four narrower goods, in descending strength:

1. **Hosts the template does not support.** Windows is off the fixed
   `target-os-matrix`; the container is the only first-class path left for that
   population. This follows from an owner decision already taken.
2. **Zero-install onboarding.** Codespaces consumes `devcontainer.json` directly,
   so a drive-by contributor reaches a built environment in a browser. The four
   devcontainer adopters the survey found (check 8a) are exactly the
   drive-by-contributor-heavy projects — `astral-sh/ruff`, `biomejs/biome`,
   `denoland/deno`, `tauri-apps/tauri` — which is the shape a *template* produces.
3. **A pinned, uniform Linux for reproducing a Linux-only CI failure**, which a
   macOS contributor otherwise cannot do at all.
4. **Agent sandboxing.** `anthropics/claude-code` ships a `.devcontainer` pairing
   `--cap-add=NET_ADMIN` with an egress-firewall `postStartCommand`. R43 and R86
   own that surface, not this item; recorded as a *consequence* of shipping the
   file, never as a reason chosen here.

What the container does **not** buy, and must not be sold as: it does not make
builds reproducible (`Cargo.lock` plus `rust-toolchain.toml` do), it does not
define the MSRV floor (`rust-version` plus a CI job do, R42/R27), and it is not the
deployment image (R51).

**Architecture alternatives compared — four architectures, not four images.**

| # | Architecture | What it is | Consequence |
|---|---|---|---|
| A | **No devcontainer** | The ts shape. Native chain only | Zero maintenance surface, zero rot. Windows contributors get no first-class path; no Codespaces onboarding |
| B | **Image-only** | One `image:` reference to a prebuilt Rust devcontainer image; no `Dockerfile`, no `features` | Smallest artifact. Exactly one third-party reference to keep pinned. The image publisher owns layer composition |
| C | **Base image + features** | `devcontainers/base` or `universal` plus `ghcr.io/devcontainers/features/rust` | Maximum configurability. Every contributor pays a feature install on first create, and the template pins two OCI references |
| D | **Local `Dockerfile`** | The `deno` / `tauri` shape | Total control; the template owns and must patch a Debian base with no CVE pipeline |

**B is selected, and the reason is structural rather than aesthetic.** The
configurability C exists to provide — `profile`, `components` and `targets` as
feature options — is configurability *this* repository must not use, because using
it would create a second toolchain declaration beside the `rust-toolchain.toml`
R42 deliberately made singular (F187/F189). C's own strength is this template's
anti-pattern. B lets the image be a **cache** of a toolchain whose authority stays
in the repository. Two independent facts confirm the choice rather than merely
rationalising it: C's installer carries weaker rustup provenance than B's image
(gate 3, checks 5a and 5d), and C's installer has an open version-resolution
defect at its current tag (check 5b, `devcontainers/features` #1726 open, check
5c). D is excluded on demonstrated rot — a judgement resting entirely on the
adopters' last-touched dates carried from `raw/opus.md` and **not** re-executed
here (see `## Empirical check`); C's `universal:6` variant is additionally
excluded on gate 4 (amd64-only, check 2a).

**The decisive fact about the selected image.**
`mcr.microsoft.com/devcontainers/rust` is not a vendor's reimplementation of a Rust
environment: its own config blob carries
`org.opencontainers.image.source = https://github.com/rust-lang/docker-rust`
(check 1e), so it is the Rust project's own image with three first-party
devcontainer features baked in (check 1f). Choosing it is not choosing a vendor's
interpretation of a Rust environment over the Rust project's.

**Reference implementations.** `devcontainers/templates` `src/rust` — the
first-party template — is in its entirety a `name` and an
`"image": "mcr.microsoft.com/devcontainers/rust:2-1-${templateOption:imageVariant}"`,
with the cargo-cache mount present as commented guidance (cited from
`raw/opus.md`, retrieved 2026-09-17; **not** re-executed here).
`astral-sh/ruff` is the maintained adopter of the same image plus the same mount,
and its `post-create.sh` is the shape this pattern deliberately trims (likewise
cited from `raw/opus.md` and **not** re-executed here; only ruff's *presence* of a
`.devcontainer` directory was re-probed, at check 8a): it restates
the toolchain resolution (`rustup default < rust-toolchain`), the component list
(`rustup component add clippy rustfmt`) and a tool install (`cargo install
--locked cargo-insta@…`) — all three of which this template expresses through
`rust-toolchain.toml` and `just setup` instead.

**Observable acceptance criteria — all five are `planned` for P03; none was
executed against a template, because no template exists.**

1. From a checkout and nothing else, `devcontainer up` succeeds and a subsequent
   `devcontainer exec` of the repository's own aggregate verification recipe
   passes. (Recipe *name* is P03's and is deliberately not asserted here.)
2. `rustc --version` inside the container equals the channel `rust-toolchain.toml`
   names (R27's value), not the image's baked `RUST_VERSION`.
3. `.devcontainer/post-create.sh` contains no install command for any tool
   `make bootstrap` or `just setup` installs, and no `apt-get` line.
4. `.devcontainer/devcontainer.json` contains no `extensions` array.
5. Every OCI reference under `.devcontainer/` is digest-pinned with a trailing
   human-readable tag comment, enforced by a repository-local script in the shape
   of R20's `scripts/check-action-pin-comments.sh` and **separate from it** —
   `zizmor` reads workflows, not `devcontainer.json`.

**Criterion 2 needs a control, or it is a status check rather than a test.** A
check asserting only that `rustc --version` exits 0 passes on the image's baked
toolchain and proves nothing. P03 must run it once with `rust-toolchain.toml`'s
channel deliberately set to a version the image does *not* bake, confirm the
reported version follows the file, and confirm the run fails when the assertion is
inverted.

**BASELINE-REVIEW: F193 — principle: the repository declares its recommended
editor-extension set exactly once — proposed change: record on F193 that where a
devcontainer exists it carries no `customizations.vscode.extensions` array, so
`.vscode/extensions.json` plus whatever the base image's `devcontainer.metadata`
already contributes remain the only two lists, neither of them hand-synchronised —
evidence:** in `py-launch-blueprint` at `b08bccfb` the two lists have already
drifted. `.devcontainer/devcontainer.json` names **4** extensions,
`.vscode/extensions.json` names **11**, and only **3** are common
(`charliermarsh.ruff`, `ms-python.python`, `tamasfe.even-better-toml`);
`EditorConfig.EditorConfig` appears only in the devcontainer and **8** entries only
in the recommendations, withheld from a container contributor for no recorded
reason (check 7b, executed). The Dev Container specification merges an image's
`devcontainer.metadata` label with `devcontainer.json`, and
`mcr.microsoft.com/devcontainers/rust:2.1.1-trixie` already contributes
`rust-lang.rust-analyzer`, `tamasfe.even-better-toml` and `vadimcn.vscode-lldb`
(check 1f, executed), so restating them would duplicate rather than add. **Affected:
F193, F200, and R28 (`linter-and-editor-tooling`), which populates
`.vscode/extensions.json`.** This finding constrains only *where* the list lives,
never what is in it, and it stands whichever way the adopt-or-drop call goes. It is
recorded here and **not applied**: this decision edits no ledger row.

**Cross-repo answer (HIGH question 3, `harmonize: partly`).** ts carries no
`.devcontainer` at its pin — `git -C ~/c/ts-launch-blueprint ls-tree cb1cbcb2 --
.devcontainer` returns **0** entries (check 7c) — and `TS_PORT_DECISIONS.md` has no
`D-0nn` explaining it. The inferred reason on record ("ts's Node toolchain needs no
isolated container") is not sufficient on its own, because the same
"the toolchain is already portable" argument applies at least as strongly to
`rustup`, which means it cannot be what actually decided it. The honest
classification is **accidental drift in ts, with a justified difference in
realisation**: the *policy* (ship a devcontainer) should hold for all three; the
*artifact* differs, because ts would use a `typescript-node` image and its own
chain, py keeps its uv image, and rs uses the Rust image. Propagating this to py
and ts is a follow-on project; this decision supplies its rationale, and the F193
finding above is the concrete repair py needs either way.

**Ranked runner-up — architecture A: ship no devcontainer (the ts shape), and
record the reason.** This is a serious runner-up, not a foil: **27 of the 31
well-regarded Rust repositories re-probed for this decision carry no
`.devcontainer` directory** (check 8a, executed 2026-09-17), including every
`rust-lang/*` repository and every recent high-growth project (`uv`, `zed`,
`codex`, `typst`, `polars`). It has zero maintenance surface and cannot rot.
**The condition under which it wins:** if the owner is unwilling to carry an OCI
digest that nothing automatically bumps (checks 4a and 4b), because a stale pinned
digest is strictly worse than no devcontainer. It also wins outright if the owner
decides Windows and Codespaces contributors are out of scope, which removes goods 1
and 2 above and leaves only a convenience. **Because the adopt-or-drop half is an
org-wide policy call, choosing A does not merely delete two files from rs: the
follow-on project then deletes py's `.devcontainer/` as well.** A second, weaker
runner-up is architecture B with a floating tag (`2-trixie`) instead of a digest;
it wins only if the owner prefers automatic currency to reproducibility, at the
cost of the environment changing silently under contributors.

**Tradeoffs the recommendation accepts.** Against A: an unautomated pin (one
string, no bot); a second supported path to document, including a runtime
prerequisite the template cannot provision; an 831 MiB cold pull for anyone who
tries it. Against C: configurability, given up deliberately because exercising it
recreates the second toolchain declaration R42 removed; and a smaller base layer,
given up because C pays it back at every contributor's first create and fetches
rustup with weaker provenance. Against D: total control of the base, given up
because the template would then own a Debian image with no CVE pipeline. What the
recommendation does **not** give up, contrary to the obvious worry: MSRV fidelity —
the container does not pin the compiler the project builds with.

re-verify: 2027-03-17, or earlier on any of — the pinned digest stops resolving or
stops being multi-architecture (check 1a/1b fails in a scheduled lane, R34);
`mcr.microsoft.com/devcontainers/rust:2-trixie` stops resolving to the pinned
digest (check 1c fails — the bump signal, since nothing bumps it automatically);
`rust-lang/docker-rust` retires `trixie` the way it retired `bullseye`;
`devcontainers/images` publishes a new major image line beyond `2.x`; Dependabot
gains image support for the `devcontainers` ecosystem (`dependabot-core` #9271
reopens or is superseded, or its `file_parser.rb` gains an image parser beside
`parse_features`); rustup changes toolchain auto-install again; the
`devcontainers/features` `rust` feature gains an option meaning "install rustup and
let the repository decide everything else"; R77 fixes a web port (one
`forwardPorts` line); R51 lands a deployment image (one README sentence); or GitHub
adds a container runtime to macOS runners.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**No `- owns` line, and that is checked rather than assumed.** `inputs/prompt.md`
`## Couplings` carries an empty `owns:` field and an empty `consumes:` field, so
this decision introduces no registry parameter and consumes none. The four lines
above are the fixed rows, and each was verified byte-identical between
`docs/port/PARAMETERS.md` and this run's `inputs/PARAMETERS.md` (check 9a).

**No `CONFLICT:` lines.** No consumed parameter needs a different value for this
recommendation to hold.

How the parameters bear on the decision, in prose rather than on the lines:

- `target-os-matrix` is used twice and in opposite directions. It is *why* the
  pattern is worth adopting — Windows has no runner, so Windows contributors have
  no CI-validated path without it — and it is what bounds the CI validation job to
  `ubuntu-latest`, because the `macos-latest` runner image ships no container
  runtime (check 3b).
- `msrv-policy` is untouched by this decision. The devcontainer neither sets nor
  tests the MSRV; `rust-version` in `Cargo.toml` plus the MSRV CI job do, and the
  container is not a matrix cell.
- `rust-edition` has no bearing on this item.
- `license` is not evaluated: gate 1 is `inapplicable — owner ruling 2026-09-12
  (Q7.B)`, and nothing here is excluded on licence.

**Alignment with items this decision does not consume.** R44's `## Couplings` names
R42 as *related, not a registry dependency*, and names no consumed parameter at
all, so the following are alignment statements and deliberately **not**
`- assumes` lines:

- **R42** (`dev-toolchain-provisioning`, resolved; `DECISION.md` sha256
  `a2504aa7…`, matching this run's `inputs/prerequisites.json`, check 9c). Layer 1
  is the committed `rust-toolchain.toml` that `rustup toolchain install` reads;
  layer 3 is "no provisioner manifest", which is why a `features` block is
  refused here on the same ground `mise.toml` and `flake.nix` were refused there;
  layer 5's invocation rule is why `post-create.sh` calls `rustup`, `make` and
  `just` as bare executables on `PATH` with no provisioner prefix. R42's generic
  `install-tool` recipe is also the reason the cargo-cache mount is worth its line.
- **R69** (`web-framework-stack`, resolved) fixes no port: host and port are
  environment variables R77 names (check 9d). Hence no `forwardPorts` key, and the
  reason is stronger than "the value was unset in this run's snapshot".
- **R11** (`ci-job-structure`) owns whether the devcontainer check is its own job
  or a step and whether it is path-filtered. This decision states the *content* of
  the check and defers its wiring shape.
- **R20** (`third-party-action-pinning-policy`, resolved) governs
  `.github/workflows/`. The CI job pins `devcontainers/ci` by SHA with a version
  comment exactly as R20 requires; the `@sha256:` image pin inside `.devcontainer/`
  is R20's *principle* applied to a new file type, not R20's checker extended.
- **R19** (`dependabot-config-shape`, resolved): the answer it left conditional on
  this item is **do not add the `devcontainers` ecosystem** (checks 4a, 4b).
- **R28** and **R51**: see `### Principles and implementation` and the README
  positioning paragraph.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`,
`rustup 1.29.1 (d95a37b6a 2026-08-13)`, macOS on `arm64` (`Darwin 25.4.0`),
`gh version 2.98.0`, `jq-1.8.2`. The exact strings are recorded in
`review/evidence/toolchain.txt` rather than in the log, deliberately: keeping
machine-dependent text off stdout is what lets the log be byte-identical across
reruns and across hosts.

**Working directory.**
`research/runs/R44/2026-09-17T020715Z-ff8c50edbd69/review/evidence`.

**Command.**

```bash
bash r44-claims.sh > r44-claims.log 2>&1
```

**Result: exit 0 — 53 assertions, 53 `PASS`, 0 `FAIL`, 0 `SKIP`.** Full output:
`review/evidence/r44-claims.log`. The script is `shellcheck`-clean (exit 0, with a
single documented file-wide `SC2016` disable for literal single-quoted search
patterns containing backticks). It has `set -uo pipefail` at the top, every check
asserts on expected **content** rather than on an exit code, and `/usr/bin/grep` is
called by absolute path and named beside every count it produces. No count in this
decision or in the log comes from output truncated by `head` or `cut`: the
261-line macOS runner inventory is counted with `/usr/bin/grep -ci` over the whole
file, and the 31-repository survey is counted over the whole snapshot file.

**Nothing was built and no container was run.** Every image fact is read from the
registry's HTTP API — index manifest, child manifest, config blob — which needs no
container runtime and no `docker` binary. A `docker` client *is* present on this
host (`/usr/local/bin/docker`, recorded by the script in
`review/evidence/toolchain.txt`); it was **never invoked**, deliberately, because
building or running the recommended environment is P03's work and is forbidden to
this decision. There is no `.devcontainer/` in this repository, no CI job, no acceptance
harness and no fixture: the pattern this decision recommends is P03's to build.

**What each section verified** (section numbers are the log's):

| § | Claim verified | Outcome |
|---|---|---|
| 1a–1c | The image tag resolves to the digest this decision pins, over HTTP 200, and the index is an OCI image index offering `linux/amd64` **and** `linux/arm64`; the rolling `2-trixie` tag currently resolves to the same digest | PASS ×5 |
| 1d | Compressed pull size, arm64: 15 layers, 871,370,327 bytes | PASS ×2 |
| 1e | `org.opencontainers.image.source = https://github.com/rust-lang/docker-rust`; `RUST_VERSION=1.98.1`; `CARGO_HOME=/usr/local/cargo`; `RUSTUP_HOME=/usr/local/rustup` | PASS ×4 |
| 1f | Baked features (`common-utils:2`, `git:1`, `rust:1`); contributed extensions (`rust-lang.rust-analyzer`, `tamasfe.even-better-toml`, `vadimcn.vscode-lldb`); `remoteUser: vscode`; `files.watcherExclude`; `capAdd: SYS_PTRACE` | PASS ×5 |
| 2a | `devcontainers/universal:6` offers `linux/amd64` only — the gate-4 exclusion of the `biome` shape | PASS ×1 |
| 3a–3b | `macos-latest` → macOS 26 Arm64 image, `ubuntu-latest` → Ubuntu 24.04 image; 0 case-insensitive `docker` lines in the 261-line macOS inventory; Docker Client and Docker Server in the Ubuntu inventory | PASS ×5 |
| 4a–4b | Dependabot's `devcontainers` parser calls `parse_features` and contains 0 references to an image parser; `dependabot-core` #9271 is `closed` (2026-03-26) | PASS ×3 |
| 5a–5d | The `rust` feature at `feature_rust_1.6.0` fetches an unversioned `rustup-init` with a same-host checksum and 0 hard-coded sha256 constants, and its "fully specified version" test is `grep -o "." \| wc -l`, so resolution reaches `git ls-remote`; `devcontainers/features` #1726 is `open`; the image's upstream Dockerfile pins `rustup/archive/1.29.0/` with 7 hard-coded sha256 constants and is `FROM buildpack-deps:trixie` | PASS ×9 |
| 6a–6b | rustup's CHANGELOG records `RUSTUP_AUTO_INSTALL` and `set auto-install disable`; `rustup toolchain install --help` on this host states "or by default the active toolchain" | PASS ×3 |
| 7a–7c | py at `b08bccfb`: `post-create.sh` runs `make bootstrap` and `just setup` and carries an `apt-get install` preamble; its two extension lists are 4 and 11 with 3 in common and 8 recommendations-only; ts at `cb1cbcb2` has 0 entries under `.devcontainer` | PASS ×8 |
| 8a | 31 well-regarded Rust repositories re-probed via `GET /repos/<o>/<r>/contents/.devcontainer`; **4** return HTTP 200 | PASS ×2 |
| 9a–9d | The four fixed registry rows are byte-identical between `docs/port/PARAMETERS.md` and this run's `inputs/PARAMETERS.md`; R42's published `DECISION.md` sha256 matches `inputs/prerequisites.json`; R69's published `web-extra-surface` leaves host and port to an R77-named environment variable | PASS ×6 |

**One naming note, so an auditor is not surprised by it.** The snapshot of the
third-party `devcontainers/features` installer is stored as
`snap/features-rust-install.sh.snapshot`, not `…install.sh`. The repository's
`pre-commit` hook shellchecks every staged `*.sh`, and linting somebody else's
installer would fail the commit on their style, not on this decision's. The
extension is the only thing that changed; the bytes are the upstream file's, and
the log is byte-identical either way.

**Endpoints and retrieval date.** Every network read was retrieved **2026-09-17
(UTC)**, recorded in `review/evidence/snap/RETRIEVED.txt`, and snapshotted into
`review/evidence/snap/`. The endpoints are: the MCR registry v2 API
(`https://mcr.microsoft.com/v2/devcontainers/{rust,universal}/manifests/<tag|digest>`
and `/blobs/<digest>`, with OCI index and manifest `Accept` headers); and the
GitHub REST API through authenticated `gh api` for `repos/actions/runner-images`,
`repos/dependabot/dependabot-core`, `repos/devcontainers/features`,
`repos/rust-lang/docker-rust`, `repos/rust-lang/rustup`, and
`repos/<o>/<r>/contents/.devcontainer` for the 31 survey repositories. **No token
and no environment was printed**; `gh` reads its own credential. No personal email
appears in the script, the log or the snapshots.

**Reproducibility, stated as a rule rather than as a claim.** The log was produced,
then the script was re-run twice and both outputs `diff`ed against it:

- a plain re-run in place — **byte-identical**;
- a re-run from a **clean `git archive HEAD` extraction with no `.git`**, with the
  `review/evidence` directory copied in — **byte-identical**.

The rule: **the log is byte-identical on any re-run while `./snap/` is present**,
because every network response is read from the snapshot and every
machine-dependent string goes to `toolchain.txt` instead of stdout. Deleting
`./snap/` re-fetches, and then three classes of line may legitimately differ, which
is why they are named rather than glossed: the content-addressed registry reads
(sections 1d–1f, 2a) reproduce from the digest whatever the tag later points at,
but the current-state checks will drift — the `2-trixie` alias digest (1c) when a
new `2.x` image is published, the two branch-head commit shas printed in 4a and 5d,
the issue states in 4b and 5c, and the per-repository HTTP statuses in 8a.

**A named-skip control, so the `SKIP` paths are shown to work.** Re-running the
same script from the same extraction with `./snap/` deleted, `HOME` pointed at an
empty directory and `PATH` restricted to `/usr/bin:/bin:/usr/sbin:/sbin` produces
`review/evidence/r44-claims-skip-control.log`: 23 `PASS`, **8 named `SKIP`s**, 0
`FAIL`, exit 0 — each naming what was missing (`gh absent`, `no rustup on this
host`, the two sibling checkouts by path). The exact invocation is:

```bash
HOME=<empty-dir> PATH=/usr/bin:/bin:/usr/sbin:/sbin bash r44-claims.sh
```

Re-running that control reproduces the saved log except for exactly **two lines**
— the `7a/7b` and `7c` skips, which name the absent sibling checkout by its
**absolute path**, and therefore quote whatever `<empty-dir>` the rerun chose.
That difference is the check working, not drifting.

**Claims carried from the raws that this check did *not* re-execute**, listed so
no reader mistakes them for verified here: the `fix!: Remove EOL Debian Bullseye`
commit date (2026-09-08); the `devcontainers/templates` `src/rust` file content;
the `.devcontainer` **contents and last-touched dates** of all four adopters —
`ruff` (2024-08-28), `biome` (2026-09-09), `deno` (**2023-12-19**) and `tauri`
(**2022-06-06**) — which are the whole basis of every "rot" statement in this
decision, at `### Principles and implementation` ("D is excluded on demonstrated
rot"), in the runner-up paragraph, and at `## Engines` ground 3 ("three of them
have let the file rot"); the `2.1.1-bookworm` compressed total (912,332,031
bytes ≈ 870 MiB), which is the whole basis of calling `trixie` "the smaller live
variant"; `universal:6`'s ≈3,821 MiB compressed total; the star counts and
open-issue counts for the supporting repositories; and `devcontainers/features`'
issue-responsiveness sample. Only the four adopters' **presence** of a
`.devcontainer` directory was re-executed here (check 8a); their file contents and
dates were not. Each claim is cited to `raw/opus.md` or `raw/codex.md` with its own
retrieval date where it appears above, and none of them carries the recommendation
on its own — the recommendation rests on checks 1–9.

## Engines

- Codex (gpt-5.6-terra) — `raw/codex.md`, sha256
  `6c8e968da12e3cc880ba9b58a993663765df20f70f228034a6651756177359c3`, 15 H3
  sections. Recommends **omission**; carries `BASELINE-REVIEW: F200`.
- Claude Opus 5 — `raw/opus.md`, sha256
  `187dc17c35a217f788ce3c58f2ea897876bb4a45a0957fdabeff1f61a391d3ec`, 15 H3
  sections. Recommends **`inherited-image-devcontainer`**; runner-up: no
  devcontainer; carries `BASELINE-REVIEW: F193`.

**Disagreement 1 — adopt or omit. Settled for adopt, on four grounds; Codex's
proposal is declined, not ignored.** Codex recommends recording F200 as *OMIT for
the initial Rust template*; Opus recommends adopting architecture B. The grounds
that decide it:

1. **Codex's decisive gate is a category error, and its own Landscape section says
   so.** Codex excludes the containerised options under `### Excluded by gate`:
   "It also fails the required fit gate as a replacement for host validation: the
   feature supports Linux distributions, while the owner requires CI on both
   Ubuntu and macOS." No candidate in either report proposes the container as a
   replacement for the `macos-latest` CI lane, and Codex's own `### Landscape`
   already concedes, of the containerised bins, that "they do not replace the
   required native `macos-latest` CI lane". A
   devcontainer is a contributor environment, not a matrix cell. Gate 4 is
   therefore answered as it is in the gate table above — native on both
   architectures for a developer host (check 1b), CI-validated on `ubuntu-latest`
   only (check 3b) — rather than as an exclusion.
2. **Codex's one concrete defect reaches architecture C only, and C is rejected by
   both reports.** The `grep -o "."` version test and the `git ls-remote` fallback
   are in `devcontainers/features` `src/rust/install.sh`, re-executed and confirmed
   at tag `feature_rust_1.6.0` (check 5b) with issue #1726 open (check 5c). The
   recommendation declares **no features**, so that installer never runs. The same
   evidence is used above, in the direction it actually supports: as a second
   reason B beats C.
3. **Practice does not discriminate between the engines, because both found the
   same direction.** Codex probed 3 repositories and found 0 with a
   `.devcontainer`; Opus probed 31 and found 4. Re-probed here: **4 of 31**
   (check 8a). The signal is against adopting, both reports say so, and this
   decision carries it as the runner-up's case rather than as a refutation — the
   four adopters are the drive-by-contributor-heavy projects a template most
   resembles, and three of them have let the file rot — the last-touched dates
   behind that sentence are carried from `raw/opus.md` and were **not**
   re-executed here (see `## Empirical check`); only the four adopters' presence
   was re-probed.
4. **The positive grounds are owner decisions already taken, not preferences.**
   `target-os-matrix` excludes Windows, which is what creates a population with no
   CI-validated path; and `DIVERGENCE-ANALYSIS.md` records the adopt-or-drop half
   of F200 as `harmonize: yes` — a shared org call — so omission in rs is not a
   local tidy-up but a decision to delete py's `.devcontainer/` too.

**Residual uncertainty, stated rather than hidden.** Confidence is **high on the
mechanics and medium on the adopt-or-drop call itself.** Every mechanical claim in
`## Decision` was executed against a first-party artifact (53 assertions, check
list above). The adopt-or-drop call rests on weighing an ecosystem signal that runs
against it (27 of 31) above or below a template's contributor story and an owner
decision on the OS matrix. A reader who weighs ecosystem practice higher should
choose the runner-up, and the condition under which it wins is stated in
`## Decision` so that choice needs no further research.

**Disagreement 2 — the two `BASELINE-REVIEW` lines. Both dispositions, one row
each.**

- **`BASELINE-REVIEW: F200` (Codex).** Principle: reproducible, repository-owned
  contributor bootstrap. Proposed change: omit a Rust devcontainer. **Disposition:
  declined on grounds 1–4 above.** The principle Codex names is accepted in full
  and is the same principle `### Principles and implementation` states; what is
  declined is the inference that the principle makes the container unnecessary,
  because the principle is silent about the contributor population the fixed OS
  matrix leaves without a path. **F200's ledger row is unchanged** — origin
  `py-only`, verdict `DIVERGENT`, item R44 — and is settled by this decision rather
  than by a verdict rewrite. If the owner takes the runner-up, this line is the
  recorded argument for it and the row is settled the other way.
- **`BASELINE-REVIEW: F193` (Opus).** Principle: the repository declares its
  recommended editor-extension set exactly once. Proposed change: record on F193
  that where a devcontainer exists it carries no `customizations.vscode.extensions`
  array. **Disposition: carried forward verbatim as a proposed Notes amendment,
  applied to nothing here.** Its evidence was re-executed (py's 4 / 11 / 3 / 8
  split, check 7b; the image's three contributed extensions, check 1f). It affects
  **F193, F200 and R28**, and it **stands whichever way the adopt-or-drop call
  goes**, because py's two lists have drifted regardless of what rs ships. This
  decision edits no ledger row; the amendment is the owner's and R28's to apply.

**Disagreement 3 — B versus C, where the two reports agree on the conclusion and
disagree on the reason.** Codex reaches "no container" partly by faulting C's
installer; Opus reaches "image-only" by faulting C's configurability as a second
toolchain declaration. Both faults are real and both were verified here — the
integrity asymmetry at checks 5a and 5d, the version-resolution defect at check
5b — and they compose rather than compete: C is excluded twice over, and neither
fault touches B.

**Disagreement 4 — figures retrieved one day apart.** Codex retrieved on
2026-09-16 and Opus on 2026-09-17, and their star counts differ slightly
(`rust-lang/rust` 118,965 versus 118,927; `tokio-rs/tokio` and `tokio-rs/axum`
identical in both). Non-substantive: no argument above turns on a star count, and
the figures that do carry weight — the image digest, the layer bytes, the runner
inventory, the parser contents, the py/ts pinned trees — are content-addressed or
pinned and were re-executed here.

**What P03 must validate, because this decision could not.**

1. **Acceptance criteria 1 and 2 against the real template** — `devcontainer up`,
   `devcontainer exec`, and the toolchain-provenance assertion with the inverted
   control described above. Nothing was built here.
2. **Wall-clock cold-create and pull time.** 871,370,327 bytes is a compressed
   total, not a duration; no pull and no create was timed.
3. **The cargo-cache volume's runtime behaviour**, on three points: that a new
   named volume is pre-populated from the image directory so `cargo` is still on
   `PATH` for `postCreate` (cited from Docker's documentation in `raw/opus.md`, not
   observed); that the `vscode` user can write to a fresh volume at
   `/usr/local/cargo`; and whether R42's `install-tool` backend does write into
   `$CARGO_HOME/bin` inside this image, which is the mount's second justification.
   A second volume on `RUSTUP_HOME` to persist installed toolchains across a
   container **rebuild** is recorded as a P03 option, untested, and is not
   recommended here.
4. **Whether R27's `rust-toolchain.toml` channel differs from the image's baked
   `1.98.1`.** R27 was open at the time of this run; criterion 2 is written against
   whatever R27 fixes, and is vacuous if the two coincide — hence the control.
5. **Codespaces behaviour specifically**, as distinct from a local
   `devcontainer up`.
6. **Line endings.** `post-create.sh` must be LF; a CRLF checkout on a Windows
   host — the population this file exists for — makes `#!/bin/sh\r` fail inside the
   container. The repository's `.gitattributes` policy is not decided in this item.
7. **Whether `devcontainer outdated`, and therefore Dependabot, reports updates for
   a digest-pinned *feature* reference.** Not exercised; it does not bear on a
   features-free recommendation, but it would matter if C were ever adopted.
