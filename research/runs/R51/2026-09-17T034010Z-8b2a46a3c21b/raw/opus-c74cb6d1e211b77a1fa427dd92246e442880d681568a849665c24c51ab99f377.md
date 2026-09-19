# R51 — container-image (bundle, Focused tier) — Opus raw research report

Engine: `claude-opus-5`, family anthropic. Run `research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b`.
Research date: **2026-09-18** (all retrieval dates below are UTC on that date unless stated otherwise).
The Codex leg of this item is deferred under owner ruling W1-CODEX3 (2026-09-18), so this report is
written to stand alone.

**Gate 1 (licence) is `inapplicable` for every candidate in this report**, under the owner ruling of
2026-09-12 recorded verbatim at `docs/port/OWNER-REVIEW.md` lines 47–68 (Q4, superseded and widened by
Q7.B): "Here, we don't need to check the licensing for any tool we use. Zero license check." Declared
licences appear below as recorded facts only, because the prompt's figure table asks for the field.

### Landscape

**The category this item decides.** Not "a Dockerfile" but five separable decisions that together form
one artifact: (1) how the image build caches Rust dependency compilation across rebuilds; (2) what the
builder stage compiles in; (3) what the runtime stage runs on, and how it acquires a non-root identity;
(4) how the image declares its own liveness, given a runtime base with no shell; (5) whether the image
is a published release artifact or a checked-in recipe. Each is a member below.

**The three-bin map of the Rust/container field.**

| Bin | Candidates found | Note |
|---|---|---|
| **Built-in / first-party toolchain** | BuildKit's own Dockerfile frontend: multi-stage `FROM … AS`, `RUN --mount=type=cache`, `COPY --from`, `USER`, `HEALTHCHECK`, `ARG`-carried digest pins. Cargo's own `--release --locked --features --bin` and `[profile.release]`. Docker Official Image `rust:<ver>-slim-<suite>`. Google's `gcr.io/distroless/cc-debian12` and `cc-debian13`, with a built-in `nonroot` identity | This bin is large for this item. Most of what py solves with tooling, Docker solves natively |
| **Established industry standard** | `cargo-chef` 0.1.78 and the `lukemathwalker/cargo-chef` builder images; the manual "dummy `src/main.rs`, copy manifests first" layer trick; `debian:<suite>-slim` + `groupadd`/`useradd` runtime; `docker/build-push-action` with `cache-from/cache-to type=gha` for CI layer caching; `curl`/`wget` re-added to a slim runtime purely for `HEALTHCHECK` | `cargo-chef` is the dominant answer to HIGH question 2 by adoption. It does not survive fitness gate 2 — see *Excluded by gate* under member 1 |
| **Up-and-comer** | `reproducible-containers/buildkit-cache-dance` (a GitHub Action that extracts and re-injects cache-mount contents so they survive a fresh CI runner); Chainguard/Wolfi minimal base images; `cargo-zigbuild` or `x86_64-unknown-linux-musl` producing a fully static binary for `FROM scratch`; Docker Hardened Images (commercial) | The cache-dance action exists *because* cache mounts are builder-local; its README states the purpose in its first sentence |

**Authorities used, and why each is authoritative.**

| Source | Why it is an authority, not a lead |
|---|---|
| The Dockerfile reference at `moby/buildkit` tag `v0.26.1`, `frontend/dockerfile/docs/reference.md` (retrieved 2026-09-18) | It is the normative documentation shipped *inside* the frontend implementation that parses the file, not a third-party restatement. Every `HEALTHCHECK` and `--mount=type=cache` semantic quoted below is read from it at that tag |
| `GoogleContainerTools/distroless` registry API (`https://gcr.io/v2/distroless/<repo>/tags/list`, `…/manifests/<tag>`, retrieved 2026-09-18) and the images themselves, run locally | The registry is the publisher's own distribution endpoint; the image contents were read by executing them rather than asserted |
| `crates.io` API and GitHub REST, per the prompt's figure table | The prompt's own required endpoints |
| `cargo-chef`'s `Cargo.toml` at tag `v0.1.78` (`raw.githubusercontent.com`, retrieved 2026-09-18) | The manifest fitness gate 2 is read against, fetched from the tag rather than from a package summary |
| `https://static.rust-lang.org/dist/channel-rust-stable.toml` (retrieved 2026-09-18) | The Rust project's own release channel manifest; it settles "current stable" without recall |
| The Kubernetes `pod-lifecycle` page source (`kubernetes/website`, `content/en/docs/concepts/workloads/pods/pod-lifecycle.md`, retrieved 2026-09-18) | The normative definition of the probe model that a deployed container is actually judged by |
| `py-launch-blueprint` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`; `ts-launch-blueprint` at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` | The programme's pinned source precedent. Every py and ts claim below is read through the pin with `git show`, never from the working tree |
| `docs/port/OWNER-REVIEW.md` and `docs/planning/p02/execution-ledger.md` | The owner's own rulings on how the fitness gates are read |

A single blog post was treated as a lead throughout; no claim below rests on one.

**Well-regarded Rust projects surveyed, with the evidence that they are well regarded.** Stars,
`archived` and `pushed_at` from `GET https://api.github.com/repos/<o>/<r>`, retrieved 2026-09-18
22:19–22:21 UTC; Dockerfiles read from `raw.githubusercontent.com` at each project's default branch on
the same date.

| Project | Stars / state | What its Dockerfile actually does |
|---|---|---|
| `astral-sh/uv` | 89,956, not archived, pushed 2026-09-18 | `ubuntu:24.04` pinned **by digest** as the build stage, `RUN --mount=type=cache` for apt, `FROM scratch` as the final stage. No chef, no healthcheck |
| `meilisearch/meilisearch` | 59,328, not archived, pushed 2026-09-17 | `rust:1.89-alpine3.22` → `alpine:3.22` (musl). No chef, no non-root `USER`, no healthcheck |
| `atuinsh/atuin` | 31,698, not archived, pushed 2026-09-18 | `lukemathwalker/cargo-chef:latest-rust-slim-bookworm@sha256:e406ad0b…` **pinned by digest**, `cargo chef prepare`/`cook`, then `debian:bookworm-20260713-slim`, `useradd` + `USER atuin`, and `HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD curl -fsS -o /dev/null "http://localhost:${ATUIN_PORT:-8888}/healthz"` (lines 45–46), with `curl` installed at line 34 under the comment "curl for the healthcheck" |
| `LemmyNet/lemmy` | 14,601, not archived, pushed 2026-09-16 | `lukemathwalker/cargo-chef:latest-rust-${RUST_VERSION}` (tag, not digest), `debian:sid-slim` runner, `useradd` + `USER`. No healthcheck |
| `paritytech/polkadot-sdk` | surveyed for the runtime-identity row only | a vendored `paritytech/base-bin` runtime with `useradd -m -u 1001` + `USER polkadot` |

`atuinsh/atuin` is the single most relevant reference implementation in the survey: a Rust HTTP server
whose image is built by cargo-chef, runs as a created non-root user, and declares a `HEALTHCHECK`
probing `/healthz` — the exact triple this item decides (F223, F336, F337). It is also the source of the
best-evidenced *limitation* of cargo-chef found anywhere in this survey, written in its own Dockerfile
at lines 19–21: "cargo-chef does not skeleton patched crates, so the real sources are needed".

**Source precedent, read at the pins.** py `Dockerfile` (32 lines, read at `b08bccfb`): a two-stage
`ghcr.io/astral-sh/uv:python3.12-bookworm-slim` builder with the dependency layer installed before the
source copy (`:10-13`, `uv sync --frozen --no-install-project --no-dev --extra web`), then a
`python:3.12-slim-bookworm` runtime that creates a user (`:19`, `groupadd -r app && useradd -r -g app app`),
switches to it (`:21`, `USER app`), sets `PLBP_WEB_HOST=0.0.0.0` with the comment "Containers bind all
interfaces; the in-code default stays loopback" (`:23-25`), `EXPOSE 8000`, and a `HEALTHCHECK` at `:29-30`
whose command is `python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz').read()" || exit 1`
under the comment "urllib — the slim base image has no curl". ts at `cb1cbcb2` contains **no** Docker
file of any kind: `git ls-tree -r --name-only cb1cbcb2 | grep -i -E "docker|container"` returns nothing.

**Two facts about py's image that the ledger rows do not carry, and that change this item's answer.**
First, py's image is never built by CI. `git grep -c -i -E "ghcr\.io|docker build|docker/build-push|buildx|docker/login|docker push" b08bccfb -- .github` exits **1** (no match), and the complete, untruncated list of every `docker` hit under `.github` at that pin is a single line — a comment in `api-contract.yml:28` about a third-party action that happens to be container-packaged. Second, the only thing that builds it is a Justfile recipe: `Justfile:317-318`, `@docker-web tag="plbp-web:dev": _guard` / `docker build -t {{tag}} .`. So py's precedent is **a checked-in recipe built on demand, never published and never verified in CI** — not a published distribution artifact. The F223 row's wording, "container image as a distribution artifact", overstates what the pinned source does.

### Principles and implementation

**The shared requirement, its source, and the agreement level.** The principle behind py's Dockerfile is:
*an optional web-service build must be runnable by someone who has neither the language toolchain nor the
project's dependency manager, in a form that does not run as root and that reports its own liveness to
whatever supervises it.* Source: py `Dockerfile` at pin `b08bccfb` in full, and the WEB-32 note recorded at
`docs/port/areas/web-service.md:43` ("lockfile-frozen, bytecode-compiled, dependency layer cached
separately from source"). ts contributes nothing: `docs/port/areas/web-service.md` F303 records that no
web/HTTP-server code, dependency or test exists anywhere in the ts repo, so there is no second data point
and no `TS_PORT_DECISIONS.md` entry to carry forward.

The agreement level is **capability**, not standard and not pattern. What must agree across the three
repositories is: *the optional web build is distributable as a container; that container does not run as
root; that container declares its own liveness.* What may vary is every mechanism, because every mechanism
here is bound to the language's build model. py's dependency layer exists because `uv sync` can install
dependencies without the project; Rust's analogue is not an installer step at all but a compilation cache,
and the two are not the same kind of object. py's `urllib` healthcheck exists because its runtime base
happens to contain a Python interpreter; a Rust runtime base contains nothing at all.

**Essential behaviors, each observable.**

| # | Behavior | Observable as |
|---|---|---|
| B1 | The image runs the `web`-gated server binary and nothing else | `docker image inspect --format '{{.Config.Entrypoint}}'` names the serve binary; the image contains no toolchain |
| B2 | The process is not root | `docker top <c>` reports a non-zero UID for PID 1 |
| B3 | The image reports its own liveness without an orchestrator | `docker inspect --format '{{.State.Health.Status}}'` reaches `healthy` |
| B4 | A rebuild after a source-only edit does not recompile the dependency graph | the build log names only workspace crates under `Compiling` |
| B5 | Every base image is pinned by digest, so the build is reproducible and a base bump is a reviewable diff | every `FROM` in the file carries `@sha256:` |
| B6 | The build uses the same profile as the release build, so the shipped binary is the shipped binary | the build command is `cargo build --release --locked`, inheriting R68's `[profile.release]` |
| B7 | SIGTERM drains rather than kills | the stopped container's `ExitCode` is R67's SIGTERM integer, not 137 |

**Architectural alternatives, compared before any library.** Four whole-shape alternatives exist, and the
choice between them is prior to the choice of caching tool or base image.

| Alternative | Shape | Verdict |
|---|---|---|
| **A. No container at all** | The `web` feature ships only as a `cargo install --features web` instruction | **Rejected.** It makes the optional surface unusable by anyone without a Rust toolchain, and F223/F336/F337 would all resolve to OMIT, which the `DIVERGENT` verdict and py's precedent do not support. It also leaves R68's own statement — "the web surface's delivery vehicle is R51's container image" (`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md` line 32) — with nothing behind it *at all*. Alternative B leaves it with a recipe rather than a downloadable, which is a weaker but non-empty answer; that difference is stated and handed to R68 under member 5's `Parameters` |
| **B. A checked-in, CI-verified Dockerfile; no registry publication** | One `Dockerfile` + `.dockerignore` at the repository root, one `just` recipe, one path-gated CI job that builds it | **Selected.** See member 5 |
| **C. B plus publication to GHCR on every release** | B, plus a follower job on release-please's tag that logs in and pushes `ghcr.io/<owner>/rs-launch-blueprint:<version>` | **Rejected on fit, not on cost.** Nobody deploys a template. The published image would be a web service with one demo resource, and every fork that wants an image wants *its own*. It also adds `packages: write` to a workflow under R08's unresolved hardening decision and three or four third-party actions to pin under R20, for an artifact with no consumer |
| **D. A `docker-compose.yml` development stack** | B plus a compose file wiring the service and a database | **Rejected as out of scope.** The template has no database (R69 selects axum and tokio only); a compose file with one service is a `docker run` line with extra syntax |

**How the recommended design preserves each principle, and where Rust needs a different design from py.**

- *Dependency layer before source* (WEB-32). py's `uv sync --frozen --no-install-project` is an *installer*
  step: it materialises a virtualenv that does not depend on the project's own code, so Docker's layer cache
  alone preserves it. Rust has no such step, because compiling a dependency graph writes into one
  `target/` directory that also holds the project's own artifacts. The two mechanisms that recover the
  property are structurally different: `cargo-chef` *fabricates* a project skeleton so a dependency-only
  build can be a distinct image layer, and `RUN --mount=type=cache` *moves* `target/` and the cargo registry
  out of the layer graph entirely. Both preserve the principle; only the second needs no third party.
- *Non-root* (F336). py creates a user because `python:3.12-slim-bookworm` has none. `gcr.io/distroless/cc-debian13:nonroot`
  ships one: `id` inside it reports `uid=65532(nonroot) gid=65532(nonroot)` (verified, check C7 below). Rust
  therefore needs *no* `groupadd`/`useradd` layer at all, which is a strictly better realisation of the same
  principle — one fewer mutable step, one fewer thing to get wrong.
- *Self-declared liveness* (F337). py's `urllib` line is a workaround for the absence of `curl`. A Rust
  runtime base is *more* austere, not less: the distroless runtime has no `sh`, no `bash`, no `curl` and no
  `wget` (verified, check C8). The principle survives only if something is added back. The design adds the
  smallest possible thing — a single statically linked `busybox` binary copied from a digest-pinned image,
  measured at 813,465 bytes — rather than an apt layer.
- *Same binary as the release* (B6, R68). py's image installs the same wheel the release publishes. The Rust
  analogue is that the image build must be a plain `cargo build --release --locked`, inheriting R68's
  `[profile.release] lto = "fat"`, `codegen-units = 1`. This has a measured cost the design accepts rather
  than overrides: fat LTO is the *dominant* term in the incremental rebuild (check C4 below shows 10.72 s of
  which the dependency compile is already cached away), and no caching tool can remove it.

**Maintained reference implementation.** `atuinsh/atuin`'s `Dockerfile` (31,698 stars, pushed 2026-09-18)
is the closest maintained composition of the same triple — Rust HTTP server, non-root `USER`, `HEALTHCHECK`
on `/healthz`. This design differs from it in three places, each on ground stated in the relevant member:
digest-pinning every `FROM` (atuin pins its chef image by digest but its runtime by a dated tag), a
distroless runtime instead of `debian-slim`+`curl` (measured: 12.31 MB against 35.68 MB), and cache mounts
instead of cargo-chef (gate 2, plus no third-party tool).

**A minimal realistic example and an executable acceptance check — what was actually run.** A four-package
stand-in workspace matching R02's accepted topology (root facade `rs-launch-blueprint` with `[lib]`,
`[[bin]] rslbp` and `[[bin]] rslbp-serve` carrying `required-features = ["web"]`; `crates/core`,
`crates/cli`, `crates/web`), with `crates/web` holding `axum` 0.8.9 and `tokio` 1.53.1 at R69's feature
list, a `/healthz` route, `axum::serve(...).with_graceful_shutdown(...)` on SIGTERM/SIGINT, and
`ExitCode::from(143)` after a SIGTERM-initiated drain. Root manifest carried `edition = "2024"`,
`rust-version = "1.96"` and R68's `[profile.release] lto = "fat"`, `codegen-units = 1`. `cargo generate-lockfile`
reported "Locking 54 packages to latest Rust 1.96 compatible versions", so the MSRV floor was exercised by
the resolver, not merely declared. Built and run with **Docker Desktop 29.5.2, buildx v0.34.0-desktop.1, on
macOS/Apple Silicon, platform `linux/arm64`**, on 2026-09-18. The stand-in and all images were deleted afterwards.

| Check | What it ran | Result |
|---|---|---|
| **C1** cold build | `docker build` of the recommended Dockerfile | exit 0; cargo reported `Finished \`release\` profile [optimized] target(s) in 22.88s`; 47.0 s wall including base-image pulls |
| **C2** image shape | `docker image inspect` | `User=nonroot:nonroot`; `Entrypoint=[/usr/local/bin/rslbp-serve]`; `Healthcheck=[CMD /bin/busybox wget --spider -q -T 3 http://127.0.0.1:8080/healthz] interval=30s timeout=3s startperiod=5s retries=3`; size **12,312,783 bytes**; `arch=arm64 os=linux` |
| **C3** runtime identity and liveness | `docker run -d`, then `docker top`, `docker inspect` | PID 1 is `/usr/local/bin/rslbp-serve` with **UID 65532**; health `Status: healthy`, `FailingStreak: 0`, first probe `ExitCode 0` in 47.7 ms; `curl` from the host returned **200** |
| **C4** dependency-cache behavior | appended one line to `crates/web/src/lib.rs`, rebuilt | only `rs-launch-blueprint-web` and `rs-launch-blueprint` appear under `Compiling`; `Finished … in 10.72s`, 12.15 s wall |
| **C5** counterfactual | same two builds with the two `--mount=type=cache` lines deleted | cold 21.82 s cargo / 24.29 s wall; after the identical source touch **21.80 s** cargo / 23.31 s wall, with all 54 packages recompiled. Cache mounts therefore cut the incremental rebuild **21.80 s → 10.72 s, a 50.8 % reduction**, on a 54-package tree |
| **C6** graceful shutdown | `docker stop -t 10` | container `ExitCode=143`, `OOMKilled=false` |
| **C7** non-root identity in both distroless suites | `id` in `cc-debian12:debug-nonroot` and `cc-debian13:debug-nonroot` | `uid=65532(nonroot) gid=65532(nonroot) groups=65532(nonroot)` in both |
| **C8** the runtime really is bare | ran the copied busybox against the image | `sh`, `bash`, `curl`, `wget` all absent; `/bin` and `/usr/bin` hold no applets |
| **C9** size of each runtime alternative | built three variants | distroless + busybox **12,312,783 B**; distroless with no probe and no `HEALTHCHECK` **11,499,318 B** (busybox costs **813,465 B**, +7.1 %); `debian:trixie-slim` + `curl` + `useradd` **35,680,357 B** (+189.8 %) |
| **C10** the `debian-slim` alternative works too | ran it | healthy, PID 1 UID **999** — it is a real alternative, priced not disqualified |
| **C11** glibc floor | `objdump -T` on the built binary; `libc.so.6 --version` in each base | binary requires at most **GLIBC_2.34**; `rust:1.98.1-slim-trixie` and `cc-debian13` both carry **2.41-12+deb13u4**; `cc-debian12` carries **2.36-9+deb12u14** |
| **C12** the suite-mismatch hypothesis, tested rather than asserted | built the trixie-compiled binary onto `cc-debian12:nonroot` and ran it | it **worked** — container healthy. The mismatch is latent, not actual, for this binary, because nothing in `std`+`axum`+`tokio` reached past GLIBC_2.34 |

C12 is recorded because it refutes a plausible claim this report would otherwise have made. Matching the
Debian suite between builder and runtime is still recommended in member 3, but as a structural guarantee
rather than as a fix for an observed failure.

**Proposed checks, not run here.** Everything in `### Validation strategy` is proposed for P03: this run
built on `linux/arm64` and nothing here proves the `linux/amd64` build that `target-os-matrix`'s
`ubuntu-latest` would produce, and no CI workflow was executed.

**`BASELINE-REVIEW` findings: none.** F223, F336 and F337 are all `DIVERGENT` rows, and
`grep -n -E "F223|F336|F337" docs/port/BASELINE-REVIEW.md` returns nothing, so this item has no recorded
`COMMON → REUSE` or `ADOPT` baseline to challenge. The one baseline this item touches, F017, is recorded as
`retained` at `docs/port/BASELINE-REVIEW.md:39` and this design does not contest it. The observation that
F223's Notes overstate py's precedent (py never builds or publishes the image in CI — see `### Landscape`)
is recorded here as a fact for the synthesizer, not raised as a `BASELINE-REVIEW:` line, because the
process reserves that line for `COMMON → REUSE` and `ADOPT` rows.

### Recommendation

**Ship the container image as a checked-in, CI-verified build recipe rather than as a published registry
artifact.** One `Dockerfile` and one `.dockerignore` at the repository root, digest-pinned throughout, in
three stages: a `busybox:1.38.0-musl` probe stage that contributes exactly one static binary; a
`rust:1.98.1-slim-trixie` builder that runs a single
`cargo build --release --locked --features web --bin rslbp-serve` under two BuildKit cache mounts
(`/usr/local/cargo/registry` and `/src/target`, both `sharing=locked`); and a
`gcr.io/distroless/cc-debian13:nonroot` runtime that holds the serve binary, the busybox probe,
`USER nonroot:nonroot`, and a `HEALTHCHECK` in exec form that probes the liveness endpoint with
`busybox wget --spider`. No `cargo-chef`, no `useradd`, no `apt-get`, no registry login, no third-party
GitHub Action. One path-gated CI job on `ubuntu-latest` builds the image and asserts B1–B3 and B7, so the
recipe cannot rot the way py's does.

| Member | Selected | Version / pin | Why, in one line |
|---|---|---|---|
| 1 Dependency-layer caching | **BuildKit `RUN --mount=type=cache`** | Dockerfile frontend `docker/dockerfile:1` | `cargo-chef` fails fitness gate 2; cache mounts are first-party, need no tool, and measured a 50.8 % incremental-rebuild cut |
| 2 Builder base | **`rust:1.98.1-slim-trixie`** | `@sha256:ca5c572a3d4e8acfa44bc065aa6d9dafbee398bf14ec376d2bcf955820a4c9f3` | Docker Official Image at current stable; `slim` omits the docs and extra targets a container build never reads |
| 3 Runtime base and identity | **`gcr.io/distroless/cc-debian13:nonroot`** | `@sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97` | glibc without a distribution: 11.50 MB against 34.03 MB for `debian-slim`+`curl`, a built-in uid 65532, and the same Debian suite as the builder |
| 4 Liveness healthcheck | **one static `busybox` applet binary + exec-form `HEALTHCHECK`** | `busybox:1.38.0-musl@sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37` | the smallest thing that restores py's principle to a shell-less base: 813,465 bytes, no package manager, no `CONFLICT` with R69's serve-binary surface |
| 5 Build and publication channel | **checked-in recipe + one path-gated CI build job; no registry push** | — | matches what py actually does, fixes what py does not do (verify it), and publishes nothing nobody would deploy |

### Members

#### Dependency-layer caching for the image build

##### Landscape

The category: how an image build avoids recompiling the dependency graph when only first-party source has
changed. **Built-in/first-party bin:** BuildKit's `RUN --mount=type=cache`, and Docker's ordinary layer
cache applied to a manifests-first `COPY` order. **Established-standard bin:** `cargo-chef` 0.1.78 with its
`prepare`/`cook` two-stage protocol and the `lukemathwalker/cargo-chef` builder images; the hand-rolled
"dummy `src/main.rs`" trick that cargo-chef automates; `docker/build-push-action` (5,404 stars, not
archived, pushed 2026-09-17) with `cache-from/cache-to type=gha` for exporting *layers*.
**Up-and-comer bin:** `reproducible-containers/buildkit-cache-dance`, whose README's first sentence states
its purpose exactly — "Save `RUN --mount=type=cache` caches on GitHub Actions or other CI platforms" —
which is also the authoritative statement of the cache mount's one limitation.

Authorities: the Dockerfile reference at `moby/buildkit` `v0.26.1` for cache-mount semantics; cargo-chef's
own manifest at tag `v0.1.78` for the gate; crates.io and GitHub REST for the figures; and four production
Dockerfiles (uv, meilisearch, atuin, lemmy) for practice. Practice is split, and the split is informative:
the two largest Rust projects surveyed (`astral-sh/uv` 89,956 stars; `meilisearch/meilisearch` 59,328) use
**no** dependency-caching tool at all — uv uses cache mounts for apt and nothing for cargo, meilisearch
caches nothing — while the two web servers (`atuinsh/atuin` 31,698; `LemmyNet/lemmy` 14,601) both use
cargo-chef. So cargo-chef's adoption is real but concentrated in exactly this item's use case.

##### Principles and implementation

The principle is WEB-32's third clause, "dependency layer cached separately from source"
(`docs/port/areas/web-service.md:43`), whose observable is behavior B4: after a source-only edit, the
build log names only workspace crates under `Compiling`. py realises it with an installer step; Rust has no
installer step, so the two candidate realisations are structurally different objects.

`cargo-chef` reifies the dependency build as an image *layer*: `cargo chef prepare` writes a `recipe.json`
describing the workspace's manifests, and `cargo chef cook` builds a skeleton project from it, so the
resulting layer is invalidated only when a manifest changes. Because it is a layer, it participates in
`--cache-from`/`--cache-to` and survives a fresh CI runner.

`RUN --mount=type=cache` removes `target/` and `$CARGO_HOME/registry` from the layer graph instead. The
Dockerfile reference at `moby/buildkit` `v0.26.1` states the contract in full (lines 860–866): "Contents of
the cache directories persists between builder invocations without invalidating the instruction cache.
Cache mounts should only be used for better performance. Your build should work with any contents of the
cache directory as another build may overwrite the files or GC may clean it if more storage space is
needed." Two consequences follow directly and are the whole comparison: a cache mount is *builder-local*
and is not exported by any layer-cache backend, and a build must be correct with the cache empty. The
`sharing=locked` option, documented at line 853 ("`locked` pauses the second writer until the first one
releases the mount"), is required here because two concurrent builds must not write one `target/`.

Measured, on the stand-in described in `### Principles and implementation` (checks C1, C4, C5;
`linux/arm64`, Docker Desktop 29.5.2, 2026-09-18): with cache mounts, a rebuild after appending one line to
`crates/web/src/lib.rs` recompiled **only** `rs-launch-blueprint-web` and `rs-launch-blueprint` and
finished in **10.72 s** of cargo time; with the two mount lines deleted, the identical edit recompiled all
**54** packages and took **21.80 s**. That is a **50.8 %** cut on a tree of 54 packages, and the ratio grows
with the dependency count. The residual 10.72 s is dominated by the fat-LTO link that R68's
`[profile.release]` mandates, which no caching strategy removes.

##### Dominant choice

**`cargo-chef` 0.1.78**, by adoption and by mindshare. Figures, `GET https://crates.io/api/v1/crates/cargo-chef`
and `/versions`, retrieved 2026-09-18: `crate.recent_downloads` **997,778**; `crate.downloads`
**4,245,274**; newest non-yanked version **0.1.78**, `created_at` **2026-08-12T06:19:24.814981Z**;
`license` "Apache-2.0 OR MIT". `GET https://api.github.com/repos/LukeMathWalker/cargo-chef` retrieved
2026-09-18 22:01:30Z: `stargazers_count` **2,709**, `archived` **false**, `pushed_at`
**2026-08-12T06:19:27Z**. `GET https://api.github.com/search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue+is:open`
retrieved 2026-09-18 22:01:52Z: `total_count` **35**. Advisories:
`https://rustsec.org/packages/cargo-chef.html` returns **HTTP 404**, retrieved 2026-09-18; the convention
was verified rather than assumed — `time` and `tokio` return 200, `serde` and `axum` return 404 — so 404
means **no open advisory**.

**Issue responsiveness, and it is the one soft signal that matters here.** Of the ten most recently created
items on `GET https://api.github.com/repos/LukeMathWalker/cargo-chef/issues?state=all&sort=created&direction=desc&per_page=10`
(retrieved 2026-09-18 22:02:14Z), six are issues: #367 (2026-09-10), #366 (2026-07-07), #365 (2026-06-30),
#363 (2026-06-10), #361 (2026-06-10), #359 (2026-06-05). **All six carry `comments: 0`.** Median days to
first maintainer response is therefore **undefined — there were no responses**; unanswered count **6 of 6**,
spanning 2026-06-05 to 2026-09-10. Two of the six are the repository's own RustSec bot notices about its
*dependency tree* — #366 "RUSTSEC-2026-0204: Invalid pointer dereference in `fmt::Poin…`" and #365
"RUSTSEC-2026-0190: Unsoundness in `Error::downcast_mut()`" — open for 73 and 80 days with no reply.
Maintenance state by the rubric: **at-risk**, on a **sample of 6, not 10** — the rubric asks for the ten most recently opened issues, and the ten most recently created items on this repository contain only six issues, the other four being pull requests. The release cadence is current (0.1.78 five weeks before the
research date, repository pushed the same day), so this is not `dormant`; but "no maintainer reply on any of
the six most recent issues over three months, two of them its own advisory notices" is the concrete signal
`at-risk` requires, not an inference from a release gap.

`unsafe` posture: not audited in this run; `cargo-chef` is a build-time binary that never links into the
shipped artifact, so its `unsafe` surface does not reach the template's process. Default features and
async-runtime coupling: none reach the template — it is invoked as a `cargo` subcommand inside a builder
stage. Binary-size cost to the shipped image: **zero** (the builder stage is discarded). Compile-time cost:
either a `cargo install cargo-chef` step in the builder, or adopting the `lukemathwalker/cargo-chef` image
as the builder base, which is what both surveyed adopters do.

##### Qualified shortlist

| Candidate | Kind | Gates 2–6 | Practice |
|---|---|---|---|
| **BuildKit `RUN --mount=type=cache`** (selected) | pattern; no crate | crate figures **inapplicable — it is a Dockerfile-frontend feature, not a package**; gate 2 inapplicable for the same reason (there is no manifest to declare `rust-version`); gate 3 `unsafe` posture inapplicable, no RustSec entry can exist; gate 4 the *image* builds on `ubuntu-latest` only by design (see member 5), while the Rust binary's own `macos-latest` leg is R68's release build, unaffected; gate 5 no default features, no async-runtime coupling; gate 6 zero bytes in the image, and it *reduces* compile time | `astral-sh/uv` (89,956 stars) uses cache mounts in its Dockerfile; `reproducible-containers/buildkit-cache-dance` exists solely to extend them to CI |
| **Manifests-first `COPY` order with stub sources** | pattern; no crate | same inapplicability profile | Nobody in the survey hand-rolls it; it is what cargo-chef automates. Correctness in a four-package workspace requires a stub `lib.rs`/`main.rs` per member, hand-maintained and silently wrong when a member is added |
| **No caching at all** | pattern | inapplicable throughout | `meilisearch/meilisearch` (59,328 stars) ships exactly this |

##### Excluded by gate

**`cargo-chef` 0.1.78 — excluded by fitness gate 2.** Its `[package]` table declares **no `rust-version`
key**. Verified at the tag, not from a summary: `https://raw.githubusercontent.com/LukeMathWalker/cargo-chef/v0.1.78/Cargo.toml`
retrieved 2026-09-18, `grep -i rust-version` over the whole file exits **1**; the manifest declares
`edition = "2018"` and no minimum version anywhere. crates.io agrees: the `rust_version` field of version
0.1.78 in `GET https://crates.io/api/v1/crates/cargo-chef/versions` is `null`.

Gate 2 requires the candidate to be "within *stable minus 2 minor versions, raised only in a minor release,
declared as rust-version in Cargo.toml and tested in CI*". The owner settled how an undeclared version is
read, and settled it **against** the lenient reading: `docs/planning/p02/execution-ledger.md:414` —
"RULING WITHDRAWN: fitness gate 2 is read strictly. … BOTH argued for it, independently, and their argument
is better than mine. The prompt's gate 2 quotes the policy in full, declaration and CI testing included,
and the instruction that follows says every candidate is gate-checked before popularity is weighed and that
a failed gate excludes the candidate. So an unknown effective version is not evidence of incompatibility,
as I said, but it is insufficient evidence to PASS a gate the prompt says must be passed."
`docs/planning/p02/owner-decisions.md:452-460` records the same withdrawal.

The precedent for applying it to a tool that is not linked into the artifact is recent and directly on
point: R69 revision 10 (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` line 1288)
excludes **`watchexec-cli` 2.7.2** — a contributor-installed developer tool, not a dependency — with
"**none declared** — fails … **Excluded by gate 2**, under the strict reading settled 2026-09-11".

**The strongest argument the other way, recorded so the synthesizer and the owner can weigh it rather than
rediscover it.** `cargo-chef` would be consumed here in a form that is *weaker* than watchexec-cli's: not
`cargo install`ed and compiled on a contributor's machine, but pulled as a prebuilt
`lukemathwalker/cargo-chef@sha256:…` image layer and executed inside a builder stage. It would never be
compiled by this template, on any OS in `target-os-matrix`, ever. If the MSRV gate is understood as "the
template must be able to build this from source under its own floor", that condition is vacuous for a
prebuilt image. R69 revision 10's own re-verify trigger names this exact open question — "or the owner
rules on whether the MSRV gate reaches non-linked developer tools" — so the question is live, and the rule
in force answers it strictly. **This report applies the rule in force and excludes the candidate.**

Two things keep that exclusion from being the load-bearing part of this member's answer. First, the
maintenance signal is independent of the gate: 6 of 6 most recent issues unanswered over three months, two
of them its own RustSec notices. Second, even at full fitness cargo-chef's *unique* benefit over cache
mounts — an exportable dependency layer — is only realisable if the template also configures a registry or
GHA layer cache, which member 5's "build-only, path-gated, no publication" job does not, and should not.

*Gate ledger for cargo-chef, stated in full rather than abbreviated:* gate 1 **inapplicable** (owner ruling
2026-09-12, Q7.B); gate 2 **FAIL**, no `rust-version` declared; gate 3 **pass** — no open RustSec advisory
(404, verified convention), `unsafe` posture not audited and not reachable from the shipped process; gate 4
**pass in substance** — it runs in a Linux builder stage and its host OS is not a template constraint, and
its own CI is not a `target-os-matrix` obligation because nothing in the template compiles it; gate 5
**pass** — no default-feature or async-runtime coupling reaches the template; gate 6 **pass** — zero bytes
in the shipped image, and it reduces rather than adds compile time.

##### Up-and-comers

`reproducible-containers/buildkit-cache-dance` — a GitHub Action that extracts a cache mount's contents
after a build and injects them before the next, so cache mounts survive a fresh runner. It is the missing
half of the selected option in CI, and it is **not** recommended here: it adds a third-party action to pin
under R20 and a pair of extra steps to a job that, under member 5, runs only on pull requests that touch
`crates/web/**`. Recorded as the successor if that job's cold-build time ever becomes a complaint.
Chainguard/Wolfi images and Docker Hardened Images are adjacent up-and-comers but belong to member 3.

##### Fit for this template

The use case is CLI + library + optional web service, where the container exists **only** for the optional
surface. Three facts about that shape decide this member. (1) The image build is rare: R69's accepted
skip-gating keys on `crates/web/**`, so a web-less pull request never triggers it. (2) Under member 5 there
is no registry publication and therefore no persistent builder, so cargo-chef's exportable layer has
nowhere to be exported *to* without additional machinery the template would otherwise not need. (3) The
frequent, real user of this Dockerfile is a **contributor rebuilding locally**, and there both mechanisms
work — cache mounts measurably (C4/C5), cargo-chef equally — so the tiebreaker is cost, and cache mounts
cost one line of Dockerfile syntax against a third-party tool, an extra `planner` stage, a `recipe.json`
artifact, and a documented skeletonisation limitation that `atuinsh/atuin` had to work around in its own
file ("cargo-chef does not skeleton patched crates, so the real sources are needed", lines 19–21).

##### Recommendation

Two cache mounts on the single build `RUN`, both `sharing=locked`:

```dockerfile
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,target=/src/target,sharing=locked \
    cargo build --release --locked --features web --bin rslbp-serve \
 && install -D -m 0755 target/release/rslbp-serve /out/rslbp-serve
```

The `install` in the same `RUN` is load-bearing: `target/` is a mount, so nothing under it exists for a
later `COPY --from=builder` to read. The binary must be copied out of the mount within the instruction that
holds it. Set `ENV CARGO_INCREMENTAL=0` in the builder stage — incremental artifacts are useless in a
release build and only grow the cache.

##### Ranked runner-up

**`cargo-chef` 0.1.78, pinned as the builder image by digest** — `atuinsh/atuin`'s exact shape. It wins
immediately if any of three things becomes true: the owner rules that fitness gate 2 does not reach
non-linked tools *and* the maintenance signal reverses; or the template starts publishing images (member 5
alternative C), which creates the persistent registry cache that makes an exportable dependency layer
worth having; or the dependency graph grows enough that a cold CI build becomes the binding constraint.
Second runner-up: **no caching at all**, meilisearch's shape, which is the right answer if the Dockerfile is
built once a month and the 11 s difference measured here never matters.

##### Tradeoffs

| | Cache mounts (selected) | cargo-chef (runner-up) |
|---|---|---|
| Third-party surface | none | one crate, one image, one generated `recipe.json` |
| Local rebuild after a source edit | 10.72 s cargo (measured, C4) | comparable; the cook layer is reused on the same builder |
| Fresh CI runner | no cache; cold build | no cache either, unless a registry/GHA layer cache is also configured |
| Correctness when the cache is empty | guaranteed by the frontend's own contract ("your build should work with any contents of the cache directory") | guaranteed; the cook layer is just rebuilt |
| Known failure mode | none found; the cache can be silently GC'd, which only costs time | skeletonisation gaps, e.g. `[patch.crates-io]` path dependencies (`atuinsh/atuin` Dockerfile lines 19–21) |
| Concurrency | needs `sharing=locked`, or two builds corrupt one `target/` | safe by construction — each build has its own layer |

##### Parameters

This member owns no registry parameter and needs none changed. It consumes `web-extra-surface` only for the
`--features web --bin rslbp-serve` build command; the full `- assumes` lines are in the item-level
`### Parameters` field. No `CONFLICT:` line.

##### Migration implications

One `Dockerfile` at the repository root carrying the `RUN` above and `ENV CARGO_INCREMENTAL=0`; one
`.dockerignore` excluding `.git`, `target` and `**/target` and — deliberately — **not** `Cargo.lock`, which
`--locked` requires in the build context. No manifest change, no new dependency, no `xtask`.

##### Validation strategy

Proposed for P03, the shape actually executed here as C4/C5: build the image; append a comment line to
`crates/web/src/lib.rs`; rebuild capturing `--progress=plain`; assert that the build log's `Compiling`
lines name only workspace members. Expected behavior: exactly the four workspace crates or fewer, never a
third-party crate. The counterfactual (delete the two mount lines, repeat) is the check that proves the
assertion is testing the cache rather than the layer cache, and is worth keeping as a one-off rather than a
CI job.

##### Confidence & re-verify trigger

**High** on the mechanism and the measurement (both executed, C1/C4/C5), **high** on the gate-2 exclusion
(manifest read at the tag; ruling quoted verbatim; sibling precedent at R69 r10 line 1288),
**medium** on the claim that cache mounts are the better long-run choice, because that rests on member 5's
"do not publish" answer. Re-verify when: `cargo-chef` publishes a release declaring `rust-version`; the
owner rules on whether the MSRV gate reaches non-linked developer tools; BuildKit ships a cache-mount
export in a layer-cache backend, which would remove cargo-chef's last unique benefit; or member 5's
publication answer moves.

##### Sources

`moby/buildkit` `v0.26.1` `frontend/dockerfile/docs/reference.md`, lines 843–892 (cache-mount options and
the persistence contract), retrieved 2026-09-18 —
`https://raw.githubusercontent.com/moby/buildkit/v0.26.1/frontend/dockerfile/docs/reference.md`.
`GET https://crates.io/api/v1/crates/cargo-chef` and `/versions`, retrieved 2026-09-18.
`GET https://api.github.com/repos/LukeMathWalker/cargo-chef`, `…/issues?state=all&sort=created&direction=desc&per_page=10`,
and `GET https://api.github.com/search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue+is:open`, retrieved
2026-09-18 22:01:30Z / 22:02:14Z / 22:01:52Z.
`https://rustsec.org/packages/cargo-chef.html` → 404, retrieved 2026-09-18, convention checked against
`time`, `tokio`, `serde`, `axum`.
`https://raw.githubusercontent.com/LukeMathWalker/cargo-chef/v0.1.78/Cargo.toml`, retrieved 2026-09-18.
`https://raw.githubusercontent.com/atuinsh/atuin/main/Dockerfile` and
`https://raw.githubusercontent.com/LemmyNet/lemmy/main/docker/Dockerfile` and
`https://raw.githubusercontent.com/astral-sh/uv/main/Dockerfile` and
`https://raw.githubusercontent.com/meilisearch/meilisearch/main/Dockerfile`, all retrieved 2026-09-18.
`https://raw.githubusercontent.com/reproducible-containers/buildkit-cache-dance/main/README.md`, retrieved
2026-09-18. `docs/planning/p02/execution-ledger.md:414`; `docs/planning/p02/owner-decisions.md:452-460`;
`docs/port/OWNER-REVIEW.md:47-68`; `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1288`.
Checks C1, C4, C5 executed locally 2026-09-18 on Docker Desktop 29.5.2 / buildx v0.34.0-desktop.1,
`linux/arm64`.

#### Builder stage base image

##### Landscape

The category: what the compile stage runs in. **Built-in/first-party bin:** the `rust` Docker Official
Image, in its `-slim-<suite>` and full variants, and `rustup` installed onto a plain `debian`/`ubuntu`
base. **Established-standard bin:** `lukemathwalker/cargo-chef:<ver>-rust-slim-<suite>` (a `rust` image
with the chef binary baked in); `rust:<ver>-alpine<ver>` for musl targets; organisation-internal CI images
such as `paritytech/ci-unified`. **Up-and-comer bin:** `cargo-zigbuild` images for glibc-version-targeted
cross-compilation; Chainguard's Rust builder.

Authorities: `https://static.rust-lang.org/dist/channel-rust-stable.toml` (the Rust project's own release
channel file) for what "current stable" is; the Docker Hub registry API
(`https://hub.docker.com/v2/repositories/library/rust/tags…`) for tags and digests. Practice: of the four
Rust Dockerfiles surveyed, two use a `rust` official image directly (`meilisearch` — `rust:1.89-alpine3.22`),
two use `lukemathwalker/cargo-chef` images derived from it (`atuin`, `lemmy`), and `astral-sh/uv` installs
its toolchain onto `ubuntu:24.04`.

##### Principles and implementation

The principle is B5 and B6: the compile stage must be reproducible (a digest, not a moving tag) and must
produce the *same* binary the release profile produces. Two derived requirements follow. First, the
builder's Rust version must be at or above the template's floor — `msrv-policy` puts the floor at
**stable minus 2 minor versions**, and stable is **1.98.1 (48a229cea 2026-09-01)**, channel date
**2026-09-03**, so the floor is **1.96** and any `rust:1.96`-or-newer image satisfies it. Second, the
builder's glibc should not be *newer* than the runtime's, because a binary links against the versioned
glibc symbols present where it was compiled. That second requirement is why this member and member 3 are
decided together rather than independently.

Measured (check C11): the binary this stand-in produced requires at most **GLIBC_2.34**;
`rust:1.98.1-slim-trixie` carries **Debian GLIBC 2.41-12+deb13u4** and reports `/etc/debian_version` as
**13.6**. Check C12 then falsified the obvious worry: the trixie-built binary ran fine on
`cc-debian12` (glibc 2.36) because nothing in `std` + `axum` + `tokio` reached past 2.34. The suite-matching
rule is therefore a **structural guarantee against a future dependency that does reach further**, not a fix
for a failure observed here — and this report states it at that strength.

##### Dominant choice

**The `rust` Docker Official Image, `-slim` variant.** Crate figures are **inapplicable — a container image
is not a crates.io package and has no `recent_downloads`, `downloads`, `versions` or RustSec page**. The
image-registry equivalents, `GET https://hub.docker.com/v2/repositories/library/rust/tags?page_size=100&name=slim`,
retrieved 2026-09-18: tags `1.98.1-slim-trixie`, `1.98.1-slim-bookworm`, `1.98.1-slim` and the floating
`slim`/`1-slim`/`1.98-slim` aliases were all republished **2026-09-18T19:46–19:47Z**, i.e. on the research
date — the image is rebuilt continuously, which is the maintenance signal that matters for a base image.
Maintenance state: **active**. Note that `slim` and `1.98.1-slim` now resolve to the **trixie** (Debian 13)
digest, not bookworm: both carry `sha256:ca5c572a3d4e8acfa44bc065aa6d9dafbee398bf14ec376d2bcf955820a4c9f3`,
while `1.98.1-slim-bookworm` is a different digest, `sha256:8d50cf1cfb8929fbf0c2c1bf654c1f21693862c1facf42d2926d7fed716422ac`.
Anyone carrying `rust:<ver>-slim` forward from an older file silently changed Debian suites.

##### Qualified shortlist

| Candidate | Gates 2–6 | Note |
|---|---|---|
| **`rust:1.98.1-slim-trixie`** (selected) | gate 2: supplies 1.98.1 ≥ floor 1.96 — **pass**; gate 3: no RustSec page can exist for an image, **inapplicable**, and `unsafe` is not a property of a base image; gate 4: it is a Linux image and the *image* is built on `ubuntu-latest` only — **`macos-latest` inapplicable by design**, see member 5, while the binary's macOS leg is R68's and unaffected; gate 5: no default features, no async-runtime coupling; gate 6: adds **zero** bytes to the shipped image (discarded stage) and pulls 291 MB (arm64) / 328 MB (amd64) once | measured amd64 layer size 327,954,032 B, arm64 291,185,108 B, from the Docker Hub tag endpoint |
| **`rust:1.98.1-slim-bookworm`** | identical, except it pairs with `cc-debian12` | the right pick if the runtime stays on `cc-debian12` |
| **`rust:1.98.1-alpine3.22`** | gate 2 pass; gate 6 produces a musl binary, so it pairs with `scratch`/`alpine` and not with distroless | meilisearch's shape; carries the musl allocator and DNS behaviours the owner reference itself flags |
| **`rustup` on `debian:trixie-slim`** | gate 2 pass, but the version is pinned in a `RUN` line instead of in the `FROM` digest | strictly worse for B5: the toolchain stops being part of the pinned base |

##### Excluded by gate

None. No candidate in this member fails a gate — the differences are fit, not admissibility. The
`lukemathwalker/cargo-chef:<ver>-rust-slim-<suite>` image is not evaluated here because it exists only to
carry the tool excluded under member 1; if that exclusion is lifted, this member's answer becomes
"the same `rust` image, with the chef binary baked in", which changes no other row.

##### Up-and-comers

`cargo-zigbuild` builder images, which let a newer Rust toolchain target an *older* glibc explicitly
(`--target x86_64-unknown-linux-gnu.2.28`), removing the suite-matching constraint entirely. Recorded, not
recommended: it is a third-party toolchain in the hottest path of the build, for a constraint that check
C12 showed is not currently binding. Chainguard's Rust builder is the other, and its free tier's
versioned-tag availability was not verified in this run — recorded as an evidence gap.

##### Fit for this template

The template compiles four workspace crates and 54 total packages. It needs `cargo`, `rustc` and a linker,
and nothing else — no `pkg-config`, no `libssl-dev`, because R05's selected HTTP client is `ureq` with
`rustls` and R69's web stack is `axum` + `tokio` with no native-TLS dependency. `-slim` is therefore
sufficient as-is, with **no `apt-get` layer at all**, which is a genuine simplification over `atuinsh/atuin`,
whose builder needs `apt install build-essential libssl-dev pkg-config` at line 16. Choosing **trixie** over
bookworm follows from member 3 selecting `cc-debian13`, and from `rust:<ver>-slim` already meaning trixie.

##### Recommendation

```dockerfile
ARG RUST_IMAGE=rust:1.98.1-slim-trixie@sha256:ca5c572a3d4e8acfa44bc065aa6d9dafbee398bf14ec376d2bcf955820a4c9f3
FROM ${RUST_IMAGE} AS builder
WORKDIR /src
ENV CARGO_TERM_COLOR=never CARGO_INCREMENTAL=0
COPY . .
```

The digest is carried in an `ARG` so a single line is the diff when Dependabot's `docker` ecosystem (see
member 5 and `### Migration implications`) advances it, and so a fork can override the base without editing
the file. The human-readable tag stays in front of the digest, which is R20's principle — a pinned
identifier with a legible version beside it — applied to base images rather than actions.

##### Ranked runner-up

**`rust:1.98.1-slim-bookworm@sha256:8d50cf1cfb8929fbf0c2c1bf654c1f21693862c1facf42d2926d7fed716422ac`**,
paired with `gcr.io/distroless/cc-debian12:nonroot`. It is the owner reference's implied pairing and it
works; it is ranked second only because Debian 12 is the older suite and `rust:<ver>-slim` no longer points
at it, so the pairing must be spelled out to stay correct. Second runner-up: the alpine/musl builder, which
is a different architecture rather than a different image, and belongs to member 3's rejected alternatives.

##### Tradeoffs

Pinning by digest costs a Dependabot pull request per base rebuild — and the Docker Hub data shows `rust`
republishing on the research date itself, so that cadence is real. The alternative, a floating tag, costs
reproducibility and makes "the image changed" invisible in review; B5 settles it. `-slim` costs nothing
here because no native dependency needs `apt`; it would cost an `apt-get` layer the moment a crate needs
`pkg-config`, at which point the full `rust:<ver>` image becomes the cheaper answer.

##### Parameters

Consumes `msrv-policy` (the 1.96 floor the builder must meet), `rust-edition` (2024, which 1.98.1
supports), and `target-os-matrix` — the last of which this member reads as governing where CI *runs*, and
the image build runs on `ubuntu-latest` only, with `macos-latest` recorded as `inapplicable` for a Linux
image artifact rather than as a gap. No `CONFLICT:` line.

##### Migration implications

The `ARG RUST_IMAGE` line and the builder `FROM` in the root `Dockerfile`. If R42's
`rust-toolchain.toml` pins a channel, the builder should either use a matching image tag or run
`rustup toolchain install` from that file the way `atuinsh/atuin` does at lines 5–7 — recorded as a
hand-off to R42's published value rather than decided here, because R42 owns the channel string.

##### Validation strategy

Proposed for P03: `docker build` on `ubuntu-latest` for `linux/amd64`, then
`docker run --rm --entrypoint ... ` asserting the binary executes; plus a one-line assertion that every
`FROM` in the Dockerfile matches `@sha256:[0-9a-f]{64}`. Executed here on `linux/arm64` only (C1, C11): the
builder produced a working binary whose glibc floor is GLIBC_2.34.

##### Confidence & re-verify trigger

**High** — the version, the digest and the glibc reading were all fetched or measured, not recalled.
Re-verify when: Rust stable advances and the `msrv-policy` floor moves past 1.96; Docker Hub republishes
the tag (a digest bump, which Dependabot's `docker` ecosystem would raise); Debian promotes a new stable
suite, which moves what `rust:<ver>-slim` means again; or a crate entering the tree needs a native library,
which invalidates `-slim`.

##### Sources

`https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`,
channel `date = "2026-09-03"`, retrieved 2026-09-18.
`GET https://hub.docker.com/v2/repositories/library/rust/tags?page_size=100&name=slim` and
`…/tags/1.98.1-slim-trixie`, retrieved 2026-09-18.
`https://raw.githubusercontent.com/atuinsh/atuin/main/Dockerfile` lines 5–7 and 16, retrieved 2026-09-18.
Checks C1, C11, C12 executed locally 2026-09-18.
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` (ureq + rustls, no native-TLS);
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (axum 0.8.9, tokio 1.53.1).

#### Runtime stage base image and non-root identity

##### Landscape

The category: what the shipped image actually contains, and how PID 1 comes to be a non-root user.
**Built-in/first-party bin:** `gcr.io/distroless/cc-debian12` and `gcr.io/distroless/cc-debian13`, each
with `latest`, `debug`, `nonroot` and `debug-nonroot` tags, published by `GoogleContainerTools/distroless`;
`FROM scratch` with a fully static binary; the Dockerfile `USER` instruction itself.
**Established-standard bin:** `debian:<suite>-slim` or `ubuntu:<ver>` plus `groupadd -r`/`useradd -r` —
py's own shape, and `atuin`'s, `lemmy`'s and `polkadot-sdk`'s; `alpine:<ver>` for musl builds.
**Up-and-comer bin:** Chainguard/Wolfi minimal images; Docker Hardened Images.

Authorities: the distroless registry's own tag and manifest endpoints; the images executed locally; the
Dockerfile reference for `USER` semantics; the four surveyed Dockerfiles for practice. The owner reference's
C15 row is an input weighed under `### Compatibility`, not an authority.

##### Principles and implementation

F336's principle is "the production image is a non-root multi-stage build". The *agreement* is at
capability level — the process must not be uid 0 — and every mechanism may vary. py must create a user
because `python:3.12-slim-bookworm` ships none; that is a consequence of its base, not of the principle.

A second principle, not in the ledger rows but implied by every one of them, is **minimum content**: an
image that contains a package manager, a shell and a C toolchain is an image whose CVE surface is mostly
things the service never executes. This is where Rust differs most sharply from Python: a Python runtime
image *must* contain a Python interpreter and a standard library; a Rust runtime image needs a dynamic
loader, libc, libgcc and CA certificates, and nothing else. `cc-debian13` is exactly that set.

Measured (C7, C9, C11): `gcr.io/distroless/cc-debian13:nonroot` and `:debug-nonroot` both report
`uid=65532(nonroot) gid=65532(nonroot) groups=65532(nonroot)`; `cc-debian13` carries
`GNU C Library (Debian GLIBC 2.41-12+deb13u4) … 2.41` and `cc-debian12` carries `2.36-9+deb12u14`; the
image built on `cc-debian13:nonroot` with the busybox probe is **12,312,783 B**, without it
**11,499,318 B**, and the `debian:trixie-slim` + `curl` + `useradd` equivalent is **35,680,357 B**. Both the
distroless and the `debian-slim` variants reached `healthy` and ran as non-root (uid 65532 and uid 999
respectively, C3 and C10), so this is a comparison of cost, not of capability.

##### Dominant choice

**`gcr.io/distroless/cc-debian13:nonroot`.** Crate figures **inapplicable — an OCI image has no crates.io
record**. Repository figures, `GET https://api.github.com/repos/GoogleContainerTools/distroless`, retrieved
2026-09-18 22:02:35Z: `stargazers_count` **23,084**, `archived` **false**, `pushed_at`
**2026-09-18T20:38:17Z** (the research date), `license.spdx_id` **Apache-2.0**.
`GET https://api.github.com/search/issues?q=repo:GoogleContainerTools/distroless+is:issue+is:open`, retrieved
2026-09-18 22:02:57Z: `total_count` **8**. Eight open issues against 23,084 stars, with a push on the day of
measurement, is a strong maintenance profile; issue responsiveness was **not** sampled for this repository
(evidence gap, recorded). Registry state, `GET https://gcr.io/v2/distroless/cc-debian13/tags/list` retrieved
2026-09-18: **6,044** tags, of which the named ones are `latest`, `nonroot`, `debug`, `debug-nonroot` and
their per-architecture suffixes (`-amd64`, `-arm64`, `-arm`, `-ppc64le`, `-riscv64`, `-s390x`), so
`:nonroot` is a multi-architecture index. Maintenance state: **active**. RustSec: **inapplicable**, an image
has no advisory page; the Debian CVE stream is the relevant feed and is not a RustSec input.

The **Debian 13 line exists** — this is the single fact that most changes the answer relative to the owner
reference. `gcr.io/distroless/cc-debian13` returned a populated tag list with `latest` and `nonroot`
present, so pairing it with the trixie builder needs no compromise.

##### Qualified shortlist

| Candidate | Gates 2–6 | Measured cost |
|---|---|---|
| **`gcr.io/distroless/cc-debian13:nonroot`** (selected) | gate 2 inapplicable (no Rust manifest); gate 3 no RustSec entry possible, `unsafe` not a property of an image; gate 4 Linux artifact built on `ubuntu-latest`, `macos-latest` **inapplicable by design**; gate 5 no features, no runtime coupling; gate 6 **11,499,318 B** total image without the probe | built-in uid/gid 65532, glibc 2.41 matching the builder exactly |
| **`gcr.io/distroless/cc-debian12:nonroot`** | identical profile | glibc 2.36; worked with the trixie-built binary (C12), but the suites no longer match |
| **`debian:trixie-slim` + `groupadd`/`useradd` + `curl`** | same inapplicability profile; gate 6 **35,680,357 B** | +189.8 % size, one `apt-get` layer, a shell and a package manager in the shipped image; ran healthy as uid 999 (C10) |
| **`FROM scratch` + `x86_64-unknown-linux-musl`** | gate 6 smallest of all, but not measured in this run | requires a musl target in the builder and a numeric `USER 65532:65532` since there is no `/etc/passwd`; brings the musl allocator and DNS behaviours |

##### Excluded by gate

None on a gate. Two are **rejected on measured or sourced ground** rather than gated out.
`debian:trixie-slim` + `curl`: rejected on the measured **+189.8 %** size and on the surface it adds — the
selected runtime has no `sh`, `bash`, `curl` or `wget` at all (C8), and the slim alternative reintroduces
all of them plus `apt`. `alpine`/musl/`scratch`: rejected on the ground the owner reference itself states
("musl DNS/TLS quirks; alpine libc perf", C15 row) and on the build-complexity cost of adding a musl target
to the builder, which this run did not measure and therefore does not quantify.

##### Up-and-comers

Chainguard/Wolfi minimal images — nightly-rebuilt, SBOM-carrying, and a genuine alternative to distroless.
Not recommended here, and the reason is an **evidence gap this run did not close**: whether Chainguard's
free tier still publishes *versioned* (rather than only `:latest`) tags was not verified, and a base image
that can only be pinned to a floating tag cannot satisfy B5. Recorded as the successor to evaluate if
distroless's cadence ever slips. Docker Hardened Images are commercial and were not evaluated.

##### Fit for this template

The shipped process is one statically-analysable Rust binary — measured at **1,271,520 B** (arm64, fat LTO,
`codegen-units = 1`, `strip` left at `"none"` per R68) — that opens a TCP listener and answers HTTP. It
needs libc, the dynamic loader, libgcc and CA certificates. `cc-debian13` supplies exactly that and sets
`SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt` in the image config (observed in C2's `Env` output), which
matters the moment a fork's handler makes an outbound HTTPS call through R05's `ureq`+`rustls`. It supplies
the non-root identity without a mutable `useradd` step, which is a strictly smaller attack surface and one
fewer instruction than py needs. The template is also a *teaching artifact*: "the runtime has no shell, so
here is how you probe it" is a better lesson than "we installed curl".

##### Recommendation

```dockerfile
ARG RUNTIME_IMAGE=gcr.io/distroless/cc-debian13:nonroot@sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97
FROM ${RUNTIME_IMAGE}
COPY --from=builder /out/rslbp-serve /usr/local/bin/rslbp-serve
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/usr/local/bin/rslbp-serve"]
```

`USER nonroot:nonroot` is written explicitly even though the `:nonroot` tag already sets it, for the same
reason R68 writes `[profile.release]` keys that match Cargo's defaults: a reader of the file should not have
to know the tag's convention, and a fork that changes the base tag gets a compile-time-visible contradiction
rather than a silent escalation to root. `EXPOSE` is documentation, not enforcement, and is included because
py's file includes it.

##### Ranked runner-up

**`gcr.io/distroless/cc-debian12:nonroot`** paired with `rust:1.98.1-slim-bookworm`. This is the owner
reference's C15 pairing, it is fully supported, and C12 showed the cross-suite combination even works. It is
ranked second on one sourced ground only: Debian 13 is the current stable suite, `rust:<ver>-slim` already
resolves to it, and choosing the older pair means the template starts one suite behind on the day it ships.
Second runner-up: `debian:trixie-slim` + `useradd`, which becomes correct the moment a fork needs a shell in
the image for an entrypoint script or a sidecar-free migration step.

##### Tradeoffs

Distroless's cost is debuggability: `docker exec <c> sh` does not work, and the answer is to redeploy the
`:debug-nonroot` tag, which ships a busybox shell. That is a real operational cost and it is the honest
price of the 23 MB saved. Its second cost is that the runtime cannot run an entrypoint *script*, so every
startup concern must live in the binary — which R69's `serve_until`/`shutdown_signal` design already assumes.
Its benefit beyond size is that there is no package manager to be told to update and no shell for an
injected command to land in.

##### Parameters

Consumes `target-os-matrix` as the CI-host constraint (`ubuntu-latest`; `macos-latest` **inapplicable** — a
Linux OCI image is not built on a macOS runner) and `web-extra-surface` for the binary name. It also
consumes, in prose rather than as a registry row, R68's `[profile.release]` and R67's exit integers. No
`CONFLICT:` line.

##### Migration implications

The `ARG RUNTIME_IMAGE`, the final `FROM`, the `COPY --from=builder`, `EXPOSE`, `USER` and `ENTRYPOINT`
lines of the root `Dockerfile`. Nothing outside the Dockerfile changes. Note for R57/R54: the container has
no `$HOME` for uid 65532 and no `/etc/xdg` content, so a fork that wants the system config tier
(R54's tier 5, `$XDG_CONFIG_DIRS` defaulting to `/etc/xdg`) must `COPY` a file there explicitly; the
template ships none, and R56's rule that secrets never live in config files means the token tier stays
`RSLBP_TOKEN` in the environment, which is exactly how a container supplies it.

##### Validation strategy

Proposed for P03 on `ubuntu-latest`/`linux/amd64`; executed here on `linux/arm64`. Executed (C2, C3, C7):
`docker image inspect --format '{{.Config.User}}'` returned `nonroot:nonroot`; `docker top` reported PID 1
as `/usr/local/bin/rslbp-serve` running as **UID 65532**; `id` inside both distroless suites returned
`uid=65532(nonroot)`. Proposed additionally: assert the image contains no shell by checking that
`docker run --rm --entrypoint /bin/sh <image> -c true` **fails**, which is a positive test of the minimum-content
property rather than a claim about it.

##### Confidence & re-verify trigger

**High** on identity, glibc and size — all executed. **Medium** on the suite-matching rule's necessity,
because C12 showed the constraint is not currently binding and the rule is therefore precautionary; it is
stated at that strength. Re-verify when: distroless publishes a `cc-debian14` or retires `cc-debian13`; the
`:nonroot` digest moves (a Dependabot `docker` pull request); Debian's stable suite advances; a dependency
enters the tree that raises the binary's glibc floor above the runtime's — the re-check is one
`objdump -T | grep -o 'GLIBC_[0-9.]*' | sort -uV`; or Chainguard's versioned-tag availability is confirmed.

##### Sources

`GET https://gcr.io/v2/distroless/cc-debian13/tags/list` and `…/cc-debian12/tags/list`, retrieved 2026-09-18.
`HEAD https://gcr.io/v2/distroless/cc-debian13/manifests/nonroot` with
`Accept: application/vnd.oci.image.index.v1+json`, `docker-content-digest:
sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97`, retrieved 2026-09-18T22:01:10Z.
`GET https://api.github.com/repos/GoogleContainerTools/distroless`, retrieved 2026-09-18T22:02:35Z;
`GET https://api.github.com/search/issues?q=repo:GoogleContainerTools/distroless+is:issue+is:open`, retrieved
2026-09-18T22:02:57Z. `moby/buildkit` `v0.26.1` Dockerfile reference (`USER`, `EXPOSE`). Checks C2, C3, C7,
C8, C9, C10, C11, C12 executed locally 2026-09-18.
`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md` lines 51–62 and 76;
`research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md` (system tier);
`research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/DECISION.md` (`RSLBP_TOKEN` env tier);
`research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md` (XDG bases).

#### Container liveness healthcheck

##### Landscape

The category: how an image whose runtime stage contains no shell and no HTTP client declares its own
liveness (F337). **Built-in/first-party bin:** the `HEALTHCHECK` instruction itself, in shell form and exec
form, with `--interval/--timeout/--start-period/--start-interval/--retries`; `HEALTHCHECK NONE`; and, on the
consuming side, Kubernetes' `livenessProbe`/`readinessProbe`/`startupProbe`, which are defined in the Pod
spec and are a different mechanism entirely. **Established-standard bin:** install `curl` or `wget` into the
runtime and probe with it (py's shape modulo the interpreter; `atuinsh/atuin`'s shape exactly); copy a
static `busybox` from a pinned image and probe with `busybox wget`; give the server binary a self-probe
subcommand or flag; ship a second, purpose-built probe binary. **Up-and-comer bin:** small dedicated probe
images and `grpc_health_probe`-style helpers — neither applicable to a plain HTTP liveness path.

Authorities: the Dockerfile reference at `moby/buildkit` `v0.26.1` §`HEALTHCHECK` (lines 2819–2880) for the
instruction's full semantics and exit-code contract; the Kubernetes `pod-lifecycle` source for what a
cluster actually consults; `atuinsh/atuin`'s Dockerfile for production practice; py's own `Dockerfile:27-30`
at the pin for the source principle.

##### Principles and implementation

F337's principle: *the image carries its own liveness statement, so a bare `docker run` — with no
orchestrator, no compose file and no Kubernetes manifest — can tell a hung server from a healthy one.*
py states the constraint in a comment at `Dockerfile:27-28`: "Liveness probe against the unversioned ops
endpoint (WEB-02); urllib — the slim base image has no curl."

**Who consumes the instruction, stated exactly.** The Dockerfile reference is explicit that this is a Docker
Engine concept: "The `HEALTHCHECK` instruction tells **Docker** how to test a container to check that it's
still working", and "When a container has a healthcheck specified, it has a health status in addition to its
normal status. This status is initially `starting`. Whenever a health check passes, it becomes `healthy` …
After a certain number of consecutive failures, it becomes `unhealthy`." Kubernetes does not consult it: the
`pod-lifecycle` page defines liveness, readiness and startup probes entirely within the Pod spec, and a
case-insensitive search of that page for `healthcheck` returns **zero** matches while `probe` appears
throughout (retrieved 2026-09-18). So the instruction's real consumers are Docker Engine, Compose and Swarm,
and the value it adds in a cluster is zero. That is an argument for *modesty* about the feature, not for
omitting it: the template's own contributors and any fork's `docker run`/`docker compose up` are exactly the
Docker Engine consumers it serves, and F337 records the capability as one the source repository has.

**The exit-code contract, which decides the command's form.** The reference states it as: "The command's
exit status indicates the health status of the container. The possible values are: 0: success … 1: unhealthy
… 2: reserved - don't use this exit code." And: "The command after the `CMD` keyword can be either a shell
command … or an exec array". With no shell in the image, the exec array is the *only* available form, and
`|| exit 1` — py's trailing clause — is unavailable and unnecessary, because `busybox wget` already exits 1
on failure.

**Timing options, read rather than copied.** Defaults per the reference: `--interval=30s`, `--timeout=30s`,
`--start-period=0s`, `--start-interval=5s`, `--retries=3`. "The health check will first run **interval**
seconds after the container is started"; "**start interval** is the time between health checks during the
start period. This option requires Docker Engine version 25.0 or later." py sets
`--interval=30s --timeout=3s --start-period=5s --retries=3`, which is three deviations from the defaults and
all three are right: a 3-second timeout for a local loopback probe, and a start period so a slow boot is not
counted as failure. Carrying py's four values is therefore a justified carry, not a copy — and the measured
first probe landed at **47.7 ms** (C3), two orders of magnitude inside the timeout.

##### Dominant choice

**Install an HTTP client into the runtime and probe with it** — this is what practice does. `atuinsh/atuin`
(31,698 stars) installs `curl` explicitly for this purpose (`Dockerfile:34`, comment "curl for the
healthcheck") and probes at lines 45–46 with
`HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD curl -fsS -o /dev/null "http://localhost:${ATUIN_PORT:-8888}/healthz"`.
py does the same thing with the interpreter it already has. Crate figures **inapplicable — this member
selects between Dockerfile constructs and prebuilt image contents, none of which is a crates.io package**;
RustSec **inapplicable** for the same reason; `unsafe` posture **inapplicable**.

Measured cost of the dominant choice in this template's runtime (C9): moving from
`gcr.io/distroless/cc-debian13:nonroot` to `debian:trixie-slim` + `curl` + `useradd` takes the image from
**12,312,783 B** to **35,680,357 B**, **+189.8 %**, and reintroduces `apt`, a shell and a package database.

##### Qualified shortlist

| Option | Mechanism | Measured / sourced cost | Verdict |
|---|---|---|---|
| **A. Static `busybox` copied from a pinned image** (selected) | `COPY --from=probe /bin/busybox /bin/busybox`; `HEALTHCHECK … CMD ["/bin/busybox","wget","--spider","-q","-T","3","http://127.0.0.1:8080/healthz"]` | **+813,465 B** (12,312,783 − 11,499,318), +7.1 % on the image; one extra digest to pin and to keep fresh | **Selected** |
| **B. `debian-slim` runtime with `curl`** | atuin's and py's shape | **+23,367,574 B** over A (35,680,357 vs 12,312,783); adds `apt`, a shell, a package database | Rejected on measured size and surface; verified working (C10) so it is priced, not disqualified |
| **C. A `--health-check` flag or subcommand on the serve binary** | the most idiomatic Rust answer: the binary already has an HTTP stack | **zero** bytes; but R69 revision 10's accepted value says the `rslbp-serve` binary "carries the org CLI Design Standard v1.4.14 R4.1 required global core **and nothing beyond it**" | **Rejected without raising a `CONFLICT:`** — see below |
| **D. A second, purpose-built probe binary in the workspace** | a tiny `no_std`-ish HTTP GET | zero third-party images; but R49's owned `build-tool-output-shape` says "Binary target: exactly one … `autobins = false`", and R69 adds exactly **one** more | Rejected on two owned-parameter collisions |
| **E. No `HEALTHCHECK` at all** | `meilisearch`, `lemmy` and `uv` all ship none | zero cost; F337's capability is simply not provided, and `docker run` cannot distinguish hung from healthy | Rejected: F337 records the capability and nothing in the Rust ecosystem makes it infeasible |

**Why C is rejected rather than raised as a `CONFLICT:`.** A `CONFLICT:` line is for a consumed value the
recommendation *genuinely needs* changed. This recommendation does not need it: option A provides the same
capability for 813,465 bytes and no change to any other item's decision. Option C would be cheaper in bytes
and cleaner in spirit — the process that owns the port is the process best able to say whether it is
listening — and it is recorded here so the owner can see the trade rather than discover it later. If the
owner would rather spend a CLI-surface exception than 0.78 MB, the line R51 would then raise is
`CONFLICT: R69 web-extra-surface — the rslbp-serve binary additionally accepts a hidden --health-check flag that performs one loopback GET against the liveness path and exits 0 or 1 — reason: it removes the only non-Rust binary from the runtime image`.
**This report does not raise that line.**

##### Excluded by gate

None. No option in this member is excluded by a fitness gate: gates 1–3 are inapplicable to Dockerfile
constructs and prebuilt image contents, gate 4 resolves the same way as members 2 and 3 (`ubuntu-latest`
builds the Linux image; `macos-latest` inapplicable to a Linux OCI artifact), gate 5 finds no feature or
async-runtime coupling, and gate 6's binary-size cost is measured above for every option rather than gated.
Options C and D are excluded by **owned-parameter collisions** — R69's "nothing beyond it" and R49's
"exactly one" plus `autobins = false` — which is a different kind of exclusion and is labelled as such.

##### Up-and-comers

None worth naming. The probe-helper category (`grpc_health_probe` and similar) exists for protocols where a
plain HTTP GET is not the health signal, which is not this template's case. Recorded as an evidence gap:
this run did not survey whether a distroless-compatible single-purpose HTTP probe image has emerged that is
smaller than busybox.

##### Fit for this template

The template's runtime image is 11.5 MB of which 1.27 MB is the service binary. Adding 0.78 MB of busybox is
a 7.1 % increase on an image that is already an order of magnitude smaller than the `debian-slim`
alternative, and it buys back exactly the capability F337 names. The probe path is **whatever R80 resolves
`/healthz` to** — R80 is open, so the Dockerfile must carry the path as a single, obvious literal and the
README must say it is R80's. The port is **whatever R77 names** — also open — so the same applies: the
example above uses `PORT=8080` as a placeholder, and the reference architecture's C15 row also uses `PORT`
with default 8080, which is corroboration rather than a decision. Both are re-verify triggers.

##### Recommendation

```dockerfile
ARG PROBE_IMAGE=busybox:1.38.0-musl@sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37
FROM ${PROBE_IMAGE} AS probe
...
COPY --from=probe /bin/busybox /bin/busybox
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/busybox","wget","--spider","-q","-T","2","http://127.0.0.1:8080/healthz"]
```

Four details are load-bearing. The applet must be invoked as `/bin/busybox wget`, not `wget`: the copied
binary brings no applet symlinks, and C8 confirmed that `wget` alone is not resolvable in the runtime.
`--spider` makes it a HEAD-style liveness check that discards the body. `-T 2` bounds busybox's own network
wait **strictly inside** the instruction's `--timeout=3s`, so a slow endpoint fails by busybox's own exit
status rather than by being `SIGKILL`ed — the reference states that a check exceeding the timeout "is
abruptly stopped with a `SIGKILL`". **The executed image used `-T 3`**, which is equal to the instruction
timeout rather than inside it and therefore races it; the observed run (C2, C3) is reported with the value
it actually carried, and the recommendation tightens it to `-T 2`. The difference is not exercised by any
measurement here, because the probe returned in 47.7 ms.
`127.0.0.1` rather than `localhost` avoids a name lookup in an image with no resolver configuration, which is
the same reasoning py used in choosing `http://127.0.0.1:8000/healthz`.

##### Ranked runner-up

**Option B, `debian:trixie-slim` + `curl`**, which is atuin's and py's shape and is the right answer for any
fork that already needs a shell in the runtime for other reasons — at which point the busybox copy is
redundant and the 23 MB is already spent. Second runner-up: **option C**, the self-probe flag, which becomes
first-choice the moment the owner rules that R69's serve-binary surface may carry an operational flag.

##### Tradeoffs

Busybox adds a third image to track and a third digest for Dependabot to advance; its musl build is fully
static, so it runs unchanged on a glibc runtime (verified by C3 — the probe executed and returned 0 inside
`cc-debian13`). It also, unavoidably, puts a general-purpose multi-call binary into an image chosen for
having nothing in it — an honest cost: `busybox sh` is present in that binary and is now reachable by anyone
who can execute in the container. The counter is that the applet is invoked by an absolute path from a
pinned digest, and that the alternative, option B, ships a *real* shell plus `apt`. A fork that considers
even this too much has option E documented and one line to delete.

##### Parameters

Consumes nothing from the registry directly. It consumes two **unpublished** values in prose: R80's liveness
path and R77's port variable name, both recorded as placeholders and as re-verify triggers rather than as
`CONFLICT:` lines, because neither item has published a value for this recommendation to conflict with. No
`CONFLICT:` line.

##### Migration implications

Three lines in the root `Dockerfile` (`ARG PROBE_IMAGE`, `FROM … AS probe`, `COPY --from=probe`) plus the
two-line `HEALTHCHECK`. One README paragraph stating that the path is R80's and the port is R77's, and that
Kubernetes ignores this instruction in favour of Pod-spec probes. No Rust source change, no manifest change.

##### Validation strategy

Executed here (C3): started the image, polled
`docker inspect --format '{{.State.Health.Status}}'`, observed `starting` → **`healthy`**, with
`State.Health.Log[0]` showing `ExitCode: 0` and a 47.7 ms duration, `FailingStreak: 0`; independently
confirmed the endpoint with an HTTP request from the host returning **200**. Proposed for P03, and
deliberately the harder half: a **negative** test — stop the server inside a running container, or start the
image with the listener bound elsewhere, and assert the status reaches `unhealthy` after `retries`
consecutive failures. A healthcheck that has only ever been observed passing is not known to detect anything.

##### Confidence & re-verify trigger

**High** on the mechanism, the exit-code contract and the measured pass. **Medium** on the choice of busybox
over the self-probe flag, because that turns on an owner call about R69's serve-binary surface rather than on
evidence. **Low-confidence and explicitly unproven:** the failure path — no `unhealthy` transition was
observed in this run. Re-verify when: R80 publishes the liveness path or changes it from `/healthz`; R77
publishes the port variable's name; the owner rules on whether `rslbp-serve` may carry an operational flag;
busybox publishes a new `-musl` digest; or Docker's `HEALTHCHECK` semantics change in the reference.

##### Sources

`moby/buildkit` `v0.26.1`, `frontend/dockerfile/docs/reference.md` lines 2819–2880, retrieved 2026-09-18.
`kubernetes/website` `content/en/docs/concepts/workloads/pods/pod-lifecycle.md`, retrieved 2026-09-18 —
zero `healthcheck` matches, probes defined in the Pod spec.
`git -C ~/c/py-launch-blueprint show b08bccfb:Dockerfile` lines 27–30, read 2026-09-18.
`https://raw.githubusercontent.com/atuinsh/atuin/main/Dockerfile` lines 33–34 and 45–46, retrieved 2026-09-18.
`GET https://hub.docker.com/v2/repositories/library/busybox/tags?page_size=50&name=musl`, retrieved
2026-09-18: `1.38.0-musl` → `sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37`.
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (serve-binary surface);
`research/topics/49-build-target-declaration/DECISION.md` (`build-tool-output-shape`, one binary target,
`autobins = false`). Checks C3, C8, C9, C10 executed locally 2026-09-18.

#### Build and publication channel

##### Landscape

The category: whether the image is a released artifact, a CI-verified recipe, or an unverified file.
**Built-in/first-party bin:** `docker build` as an ordinary CI `run:` step (BuildKit is the Docker Engine
default builder, so the `# syntax` directive and `--mount` work without any action); `docker buildx build
--platform` for multi-architecture; GHCR as the registry that needs no account setup for a GitHub
repository. **Established-standard bin:** `docker/build-push-action` (5,404 stars, not archived, pushed
2026-09-17) with `docker/login-action`, `docker/setup-buildx-action` and `docker/metadata-action`; a
follower job triggered by the release tag, the shape R68 already uses for `dist`. **Up-and-comer bin:**
attestation and provenance flows (`--provenance`, cosign signing, SBOM attachment), which distroless itself
uses.

Authorities: the pinned py repository for what the source precedent actually does; R68's published
recommendation for how a follower job behind release-please is shaped; R19's published decision for what
shipping a Dockerfile obliges.

##### Principles and implementation

Two principles compete and both are real. *Distributability* (F223): an artifact nobody can obtain is not a
distribution artifact. *Verifiability* (implied by every guard item in this programme, and by py's own
failure): a recipe nobody builds rots silently.

The evidence settles them in opposite directions from where the ledger row points. py, at pin `b08bccfb`,
**publishes nothing** — `git grep -c -i -E "ghcr\.io|docker build|docker/build-push|buildx|docker/login|docker push" b08bccfb -- .github`
exits 1, and the complete set of `docker` mentions under `.github` at that pin is one comment in
`api-contract.yml:28` about an unrelated third-party action. And py **verifies nothing** — the only thing
that builds the image is `Justfile:317-318`. So the source precedent supports "recipe, not artifact", and
simultaneously exhibits the defect that a recipe with no build gate acquires.

The decisive fit argument for not publishing is what the artifact would *be*. R68 publishes cross-compiled
`rslbp` binaries because someone genuinely wants to run the CLI. Nobody wants to run *the template's* web
service: it serves one demo resource. A fork wants an image of **its own** code, which it gets by building
this Dockerfile after renaming the package. Publishing `ghcr.io/<owner>/rs-launch-blueprint:<version>` would
produce a registry entry with no consumer, while adding `packages: write` to a workflow under R08's
unresolved permission-hardening decision, three or four third-party actions to pin under R20, and a second
release-follower job to keep working alongside `dist`'s.

##### Dominant choice

**Publish on release**, in the wider container ecosystem — most server projects push to a registry, and all
four surveyed Rust projects do. Figures are **inapplicable — this member selects a workflow shape, not a
package**; no crates.io record, no RustSec page, no `unsafe` posture. The supporting tool if the dominant
choice were taken, `docker/build-push-action`: **5,404** stars, `archived` **false**, `pushed_at`
**2026-09-17T11:52:52Z**, `license.spdx_id` **Apache-2.0** (`GET https://api.github.com/repos/docker/build-push-action`,
retrieved 2026-09-18T22:03:19Z) — maintenance state **active**. The dominant choice is nonetheless rejected
on fit, and the fit argument is about what a *template* is, which is exactly the axis on which surveyed
*applications* provide no evidence.

##### Qualified shortlist

| Option | Shape | Cost / benefit |
|---|---|---|
| **B. Recipe + CI build gate, no publication** (selected) | `Dockerfile`, `.dockerignore`, one `just` recipe, one path-gated CI job running `docker build` as a plain `run:` step | **zero** new third-party actions, **zero** new workflow permissions; the Dockerfile cannot rot; nothing is published |
| **C. B + GHCR publication on release** | plus `docker/login-action`, `docker/setup-buildx-action`, `docker/metadata-action`, `docker/build-push-action`, `packages: write`, a release-tag follower job | an image nobody deploys; four SHA pins to maintain under R20; a permission R08 has not yet ruled on |
| **F. Recipe only, no CI gate** (py's actual shape) | `Dockerfile` + `just` recipe | cheapest; and demonstrably the shape in which a Dockerfile goes stale unnoticed |

##### Excluded by gate

None. Gate 1 inapplicable (owner ruling); gates 2, 3 and 5 inapplicable — a workflow shape has no manifest,
no advisory feed, no `unsafe` and no features; gate 4 resolves as **`ubuntu-latest` only, `macos-latest`
inapplicable**, because a Linux OCI image is not built on a macOS runner and the Docker daemon is not
available there; gate 6's cost is the CI minutes measured under C1/C5 rather than binary size. Option F is
rejected on evidence (py's own file is the demonstration), not on a gate.

##### Up-and-comers

Build attestation and provenance: `docker buildx build --provenance=true --sbom=true`, cosign signing, and
SBOM attachment to the pushed manifest. `GoogleContainerTools/distroless` signs its own images this way, so
the practice is real and adjacent. It is **not** recommended, for a structural reason rather than a fitness
one: provenance and signatures attach to a *published* artifact, and the selected option publishes nothing,
so there is nothing to sign. Recorded as the first thing to add if option C is ever taken — it would arrive
with the registry push, not before it. The other up-and-comer is `reproducible-containers/buildkit-cache-dance`,
evaluated under member 1, which becomes relevant here only if the CI build job's cold-build time becomes a
complaint.

##### Fit for this template

R69's accepted skip-gating keys on `crates/web/**`, so the image job runs only on pull requests that touch
the web member — which is the right frequency for a job whose cold build, measured without cache mounts at
**24.29 s** wall on this stand-in (C5), will be minutes on a real dependency tree on a GitHub-hosted runner.
R11 owns `ci-job-structure` and its registry value is still **`—`** (unresolved), so this member states a
*requirement on* R11's answer rather than a job definition: one job, path-gated on `crates/web/**` plus
`Dockerfile` and `.dockerignore`, on `ubuntu-latest`, building `linux/amd64` — the single Linux triple R68's
`targets` already names.

##### Recommendation

Ship `Dockerfile` and `.dockerignore` at the repository root; add one `just` recipe mirroring py's
`docker-web` (`docker build -t rslbp-serve:dev .`); add one CI job, path-gated, that runs
`DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t rslbp-serve:ci .` and then asserts the four
behaviors that make the image correct rather than merely buildable — non-root PID 1, `healthy` status, a 200
from the liveness path, and exit **143** after `docker stop`. Do **not** log in to a registry, do **not**
push, do **not** add a release-follower job. Document in the README that a fork publishes its own image and
what the three or four lines are that do it. `DOCKER_BUILDKIT=1` is written explicitly even though modern
Docker Engine defaults to BuildKit, because the `# syntax` directive and `--mount=type=cache` silently fail
without it, and a runner image is not a thing this template controls.

##### Ranked runner-up

**Option C, GHCR publication on release**, which becomes correct the moment the template stops being a
template — that is, for the first fork. It is also the right answer earlier than that if the owner decides a
published image is itself documentation ("here is what the template produces"), which is a legitimate view
this report has no evidence against. Second runner-up: option F, py's shape, which is what this
recommendation reduces to if R11's resolved job structure makes a container job impractical.

##### Tradeoffs

The CI gate costs runner minutes on web-touching pull requests and nothing otherwise. Not publishing costs
discoverability: someone who wants to *see* the web service running must build it, which takes a Docker
daemon and a few minutes. Publishing would cost four action pins, one new workflow permission under an
unresolved item (R08), and the standing obligation to keep a release-follower job green alongside `dist`'s.
The asymmetry — a recurring maintenance obligation against a one-time convenience — is what decides it.

##### Parameters

Consumes `target-os-matrix` (`ubuntu-latest` builds the image; `macos-latest` **inapplicable** for a Linux
OCI artifact) and `web-extra-surface` (the path filter and the build's `--features web`).

**A coupling with R68 that this member must state rather than leave implied.** R68 left the `web`-gated
binary out of its release archives on the stated premise that "the web surface's delivery vehicle is R51's
container image" (`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md` line 32). Under this
member's selected option the image is a **recipe**, not a downloadable: no release archive contains
`rslbp-serve` and no registry serves an image, so nobody can obtain a runnable web artifact without a Docker
daemon and a build. That is a deliberate consequence of "a template's web service has no consumers but its
forks", and it is the right outcome if that premise holds. If the owner wants a downloadable web artifact,
there are exactly two places to get one and they belong to two different items: **R51 takes option C**
(publish to GHCR on release), or **R68 adds `features = ["web"]` to dist's build** so `rslbp-serve` ships in
the release archives beside `rslbp`. This is recorded as a **hand-off to R68**, not a `CONFLICT:` line,
because this recommendation needs no value of R68's changed — it needs the owner to know which of the two
doors is the one to open.

It creates a further **hand-off, not a conflict**, to two open items: R11 (`ci-job-structure`, registry value `—`) must place this
job, and R19's published decision already anticipates it — F053 records that the `docker` and `devcontainers`
Dependabot ecosystems are "conditional on R51 and R44 shipping those files"
(`research/topics/19-dependabot-config-shape/DECISION.md:66`). **This recommendation ships those files, so
R19's condition is met and a third `package-ecosystem: "docker"` entry becomes due.** That is the mechanism
that keeps the three digest pins in members 2–4 fresh, and it is why digest-pinning is affordable at all.
No `CONFLICT:` line.

##### Migration implications

New files: `Dockerfile`, `.dockerignore`. Changed files: the `Justfile` (one recipe), the CI workflow (one
path-gated job, whose exact placement is R11's), `.github/dependabot.yml` (one `docker` entry, which is
R19's to add), and the README (one section: how to build, what the healthcheck probes, that Kubernetes uses
Pod-spec probes instead, and how a fork publishes). The root package's `[package] include` allow-list from
R49's `build-tool-output-shape` — `/src`, `/README.md`, `/LICENSE-MIT`, `/LICENSE-APACHE`, `/CHANGELOG.md` —
already excludes `Dockerfile`, so the file does **not** enter the published `.crate`, which is the correct
outcome and needs no change to that parameter.

##### Validation strategy

Proposed for P03, all four on `ubuntu-latest`/`linux/amd64`; the same four were executed here on
`linux/arm64` as C1, C2, C3 and C6 and passed: build succeeds; `docker top` shows a non-zero UID for PID 1;
`docker inspect --format '{{.State.Health.Status}}'` reaches `healthy` within the start period;
`docker stop -t 10` leaves `State.ExitCode` at **143**, R67's SIGTERM integer as R69 records it, proving the
graceful-shutdown path rather than a `SIGKILL` at 137. Proposed additionally: assert that the workflow file
contains no `docker/login-action` and no `push: true`, so "we do not publish" is a checked property rather
than a convention.

##### Confidence & re-verify trigger

**High** on the py precedent (grep exited 1; the complete match set was read, not sampled) and on the four
behaviors (executed). **Medium** on the recommendation itself, because "do not publish" is a judgment about
what a template is for, and the owner may simply disagree — this is the member most likely to be overruled,
and it is stated so. Re-verify when: R11 publishes `ci-job-structure`; R08 publishes its permission model,
which prices option C properly; the owner rules that the template should publish an image; R68's
follower-mode release flow changes shape; or R19 adds the `docker` ecosystem, which is this member's own
hand-off landing.

##### Sources

`git -C ~/c/py-launch-blueprint grep -c -i -E "ghcr\.io|docker build|docker/build-push|buildx|docker/login|docker push" b08bccfb -- .github` → exit 1, and
`git grep -n -i "docker" b08bccfb -- .github` → one line, `api-contract.yml:28`; `Justfile:317-318`; all read 2026-09-18.
`GET https://api.github.com/repos/docker/build-push-action`, retrieved 2026-09-18T22:03:19Z.
`GET https://api.github.com/repos/moby/buildkit`, retrieved 2026-09-18T22:03:41Z: 10,275 stars, not archived,
pushed 2026-09-18T17:18:12Z, 849 open issues.
`research/topics/19-dependabot-config-shape/DECISION.md:66`;
`research/topics/49-build-target-declaration/DECISION.md` (`include` allow-list);
`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md` lines 32 and 76;
`docs/port/PARAMETERS.md:12` (`ci-job-structure`, value `—`). Checks C1, C2, C3, C5, C6 executed locally
2026-09-18.

### Compatibility

**The five members were composed into one file and built, run and probed together.** That is this item's
primary compatibility proof and it is direct rather than inferred: checks C1–C12 in
`### Principles and implementation` were all executed against a **single** Dockerfile containing the
selected option from every member — busybox probe stage, `rust:1.98.1-slim-trixie` builder with both cache
mounts, `gcr.io/distroless/cc-debian13:nonroot` runtime, `USER nonroot:nonroot`, the exec-form `HEALTHCHECK`
using the copied applet, and no registry push — over a four-package workspace matching R02's accepted
topology with R69's axum 0.8.9 / tokio 1.53.1 and R68's `[profile.release]`. The composite built (C1), ran
as uid 65532 (C3), answered 200 on the liveness path (C3), reached `healthy` in 47.7 ms (C3), rebuilt
incrementally with only workspace crates recompiled (C4), and exited **143** on `docker stop` (C6).
Platform: `linux/arm64`, Docker Desktop 29.5.2, buildx v0.34.0-desktop.1, 2026-09-18.

**Version matrix, every element pinned and verified at the source on 2026-09-18.**

| Element | Pin | Verified against |
|---|---|---|
| Dockerfile frontend | `# syntax=docker/dockerfile:1` | `moby/buildkit` `v0.26.1` reference; local buildx v0.34.0-desktop.1 parsed the file |
| Builder | `rust:1.98.1-slim-trixie@sha256:ca5c572a3d4e8acfa44bc065aa6d9dafbee398bf14ec376d2bcf955820a4c9f3` | Docker Hub tag endpoint; `ldd --version` in the image → Debian GLIBC 2.41-12+deb13u4, `/etc/debian_version` 13.6 |
| Runtime | `gcr.io/distroless/cc-debian13:nonroot@sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97` | gcr.io manifest `docker-content-digest`; `libc.so.6 --version` → 2.41-12+deb13u4; `id` → uid 65532 |
| Probe | `busybox:1.38.0-musl@sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37` | Docker Hub tag endpoint; the applet executed inside the distroless runtime and returned 0 |
| Rust toolchain | 1.98.1, floor 1.96 | `channel-rust-stable.toml`; `cargo generate-lockfile` reported "Locking 54 packages to latest Rust 1.96 compatible versions" |
| Web stack | axum 0.8.9, tokio 1.53.1 | R69 revision 10; resolved and compiled in the builder |

**The glibc pairing is the one place the members could silently disagree, and it was checked rather than
assumed.** Builder glibc 2.41-12+deb13u4 and runtime glibc 2.41-12+deb13u4 are the *same Debian build*, and
the binary's own floor is GLIBC_2.34 (C11) — so the pairing has 7 minor versions of headroom. C12 additionally
showed the binary runs on `cc-debian12` (2.36), so the pairing is a guarantee rather than a necessity today.

**Shared adopters, as external corroboration that these elements are used together in production.**
`atuinsh/atuin` (31,698 stars, pushed 2026-09-18) composes a Rust HTTP server, a non-root `USER`, and a
`HEALTHCHECK` on `/healthz` in one file — members 3, 4 and 5's capabilities together, with member 1's
runner-up. `astral-sh/uv` (89,956 stars, pushed 2026-09-18) composes BuildKit cache mounts with a digest-pinned
builder and a contents-minimal final stage — members 1, 2 and 3's selections together, in a project whose
release engineering is itself the reference for this programme's R68. No single external repository composes
all five selections, which is why the executed composite above is the primary evidence rather than the
supporting evidence.

**Reconciliation with the owner-supplied reference architecture** (`inputs/owner-reference-axum-companion-stack-2026-09-16.md`,
a STANDING INPUT under `docs/planning/p02/owner-decisions.md` section 11 — not a standard and not a
pre-decision). Rows this item touches, each answered:

| Reference row | Reference says | This item |
|---|---|---|
| C15 *Container*, table row — base family | "distroless/cc-debian12" over "musl/scratch; alpine", because of "musl DNS/TLS quirks; alpine libc perf" | **Agree** on the family, and independently measured: distroless + probe **12,312,783 B** against `debian:trixie-slim` + `curl` **35,680,357 B** (C9). The musl caveats are accepted as stated; this run did not measure them |
| C15 *Details* — exact suite `cc-debian12` | "Recommend **distroless/cc-debian12**" | **Differ, on sourced ground.** `gcr.io/distroless/cc-debian13` exists and publishes `latest`/`nonroot` as multi-arch indexes (`GET https://gcr.io/v2/distroless/cc-debian13/tags/list`, 6,044 tags, retrieved 2026-09-18), and `rust:<ver>-slim` now resolves to **trixie** (same digest as `1.98.1-slim-trixie`, Docker Hub, retrieved 2026-09-18). Pairing trixie with `cc-debian12` crosses suites for no benefit |
| C15 *Details* / C14 — `cargo-chef` | "Build with cargo-chef (planner → `cargo chef cook` → build)"; C14 lists "bacon + **cargo-chef** + mold" | **Differ, on gate and on measurement.** `cargo-chef` 0.1.78 declares no `rust-version` (manifest read at tag `v0.1.78`) and is excluded by fitness gate 2 under the owner's strict reading (`docs/planning/p02/execution-ledger.md:414`), the same reading R69 r10 applied to `watchexec-cli`. Independently, BuildKit cache mounts delivered a **50.8 %** incremental-rebuild cut (21.80 s → 10.72 s, C4/C5) with no third-party tool. The reference's own *Caveats* note that its patterns were "compiled in my head, not against the toolchain" |
| C15 *Details* — run as `nonroot` | "run as `nonroot`" | **Agree**, and measured: PID 1 runs as **uid 65532** (C3); `id` in the base returns `uid=65532(nonroot) gid=65532(nonroot)` (C7) |
| C15 *Details* — `bind PORT (default 8080)` | "bind `PORT` (default 8080)" | **Agree as a placeholder only.** The variable's name is R77's (open). The Dockerfile carries `ENV PORT=8080` and the README says so; R77's publication is a re-verify trigger |
| C15 *Details* — `expose /healthz (liveness)` | "expose `/healthz` (liveness)" | **Agree** that the container's `HEALTHCHECK` probes the liveness path; the path's own value and behavior are R80's (open) and this item does not decide them |
| C15 *Details* — `/readyz (readiness, checks DB)` | "`/readyz` (readiness, checks DB)" | **Not this item's row** — `docs/planning/p02/owner-decisions.md` section 11 assigns C15 probes to **R80**. Recorded as a hand-off. Noted for R80: this template has no database (R69 selects axum and tokio only), so "checks DB" has nothing to check here |
| Reference *Dockerfile (Variant A)* — `FROM lukemathwalker/cargo-chef:latest-rust-slim` | an unpinned `latest-` tag | **Differ, on sourced ground.** B5 and R20's pinning principle both require a digest. The reference's own Caveats flag its unpinned versions as "verify". Every `FROM` in this recommendation carries `@sha256:` |
| Reference *Dockerfile (Variant A)* — final stage shape | `FROM gcr.io/distroless/cc-debian12` / `COPY --from=builder … /app` / `USER nonroot:nonroot` / `ENV PORT=8080` / `ENTRYPOINT ["/app"]` | **Agree** on the shape, line for line, with the suite and the digest changed per the rows above and the binary installed at `/usr/local/bin/rslbp-serve` rather than `/app` |
| Reference *Dockerfile* — no `HEALTHCHECK` in either variant | neither Variant A nor Variant B contains a `HEALTHCHECK` instruction | **Differ.** F337 records the capability as one the source repository has, and Docker Engine, Compose and Swarm consume it. The reference's omission is consistent with its Cloud Run target, where platform probes replace it; this template's target is unconstrained |
| Reference — Cloud Run deployment, Variant B `node:20`/Vite stage, `SQLX_OFFLINE`, Artifact Registry, `gcloud run deploy` | a full GCP deployment path | **Inapplicable.** Section 11 records these as rows with no P02 item, "NOT decided and NOT researched by this instruction". This template has no database, no frontend build and no cloud target |
| C14 — `mold` linker | "mold/lld linker for faster link" | **Not adopted, and recorded rather than silently dropped.** R69 r10 line 399 hands `cargo-chef` and `mold` to R51/R68. A linker swap changes the *release* link and therefore R68's measured `[profile.release]` numbers; it is not an image-layout decision, and this item declines to make it inside a Dockerfile where it would apply only to container builds and diverge from the release binary (B6) |

**Tally: 4 agree, 4 differ (all on measured or sourced ground), 1 agree-as-placeholder, 2 hand-offs
(C15 `/readyz` → R80; C14 `mold` → R68), 1 inapplicable (the GCP deployment rows).**

### Parameters

R51 owns no registry parameter (`docs/port/PARAMETERS.md` lists twelve rows and none names R51; the prompt's
`## Couplings` records `- owns:` empty), so no `- owns` line appears below.

- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**The `web-extra-surface` line above is the live `docs/port/PARAMETERS.md` row, byte for byte, which is
revision 9's `src/web/` form — and this recommendation is not written against it.** R69 **revision 10** is
owner-accepted and unpublished (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, its
`- owns web-extra-surface` line at line 1791; owner rulings W1-R02 / W0-R69c), and it moves the gated tree to
**`crates/web/src/`**, the web tests to **`crates/web/tests/`**, the skip-gating key to **`crates/web/**`**,
and the feature declaration to `web = ["dep:rs-launch-blueprint-web"]` on the root package with axum 0.8.9
and tokio 1.53.1 declared non-optionally inside `crates/web/Cargo.toml`. Every path in this report — the CI
job's path filter, the `.dockerignore`, the stand-in workspace that checks C1–C12 were executed against —
uses **revision 10's `crates/web` form**, together with R02 revision 1's accepted four-package workspace
(`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md`). The registry bytes are preserved
above because the row has not republished. **R69's republication is a re-verify trigger for this item.** No
`CONFLICT:` line is raised for those paths, and none is raised at all.

`target-os-matrix` deserves one sentence rather than a silent pass: it is consumed here as a constraint on
**where CI runs**, and the artifact this item produces is a Linux OCI image, so the image build is
`ubuntu-latest`-only and `macos-latest` is recorded as **`inapplicable` for the image artifact** in every
member's gate 4. The Rust binary's own `macos-latest` obligation is unaffected — R68 already builds
`x86_64-apple-darwin` and `aarch64-apple-darwin` release binaries there, and nothing in this item changes
that.

Other consumed values, recorded in prose because they are not registry rows this item consumes: R68's
`[profile.release] lto = "fat"`, `codegen-units = 1`, `strip = "none"` (the image build must not override
them — B6); R67's exit integers as R69 records them (143 after a SIGTERM drain — asserted by C6); R05's
synchronous core with async confined to the `web` feature (which is why the image's only async surface is
the serve binary); R56's rule that secrets never appear in config files, with `RSLBP_TOKEN` as the
environment tier (which is exactly how a container receives one); R57's XDG bases and R54's `/etc/xdg`
system tier (the image ships no file at either, and a fork that wants one must `COPY` it); R49's
`[package] include` allow-list, which already keeps `Dockerfile` out of the published `.crate`; and R20's
SHA-pinning principle, applied here to base-image digests rather than to actions.

**`CONFLICT:` lines: none.**

### Migration implications

| Path | Change | Owner |
|---|---|---|
| `Dockerfile` | **new**, ~22 lines: three `ARG`-carried digest pins, a `probe` stage, a `builder` stage with two cache mounts and one `cargo build --release --locked --features web --bin rslbp-serve`, a `gcr.io/distroless/cc-debian13:nonroot` runtime with `COPY --from=probe`, `COPY --from=builder`, `ENV PORT=8080`, `EXPOSE 8080`, `USER nonroot:nonroot`, exec-form `HEALTHCHECK`, `ENTRYPOINT` | R51 |
| `.dockerignore` | **new**: `.git`, `target`, `**/target`. **Not** `Cargo.lock` — `--locked` needs it in the build context | R51 |
| `Justfile` | **one recipe**, mirroring py's `Justfile:317-318`: `docker build -t rslbp-serve:dev .` | R51; the invocation form is **R42's** published `package-manager-invocation`, which requires a tool that is not a cargo subcommand to be invoked as a bare executable resolved on `PATH` with no provisioner prefix — `docker` is exactly that case |
| CI workflow | **one job**, `ubuntu-latest`, path-gated on `crates/web/**`, `Dockerfile`, `.dockerignore`; runs `DOCKER_BUILDKIT=1 docker build --platform linux/amd64`, then asserts non-root PID 1, `healthy`, HTTP 200, and exit 143. **No** third-party action, **no** added workflow permission | placement is **R11's** (`ci-job-structure` is still `—`) |
| `.github/dependabot.yml` | **one new `package-ecosystem: "docker"` entry**, `directory: "/"`, matching R19's existing shape, so the three base digests are advanced automatically | **R19's** — its published F053 row already records this as "conditional on R51 … shipping those files", and this recommendation ships them |
| `README.md` | **one section**: how to build the image; that the healthcheck probes R80's liveness path on R77's port; that Kubernetes ignores `HEALTHCHECK` in favour of Pod-spec probes; and the three or four lines a fork adds to publish to its own registry | R51, under R81's docs model |
| `Cargo.toml` (root and `crates/web`) | **no change.** No new dependency, no new feature, no new binary target, no `build.rs` | — |

Nothing in `src/` or `crates/*/src/` changes. Nothing in the published `.crate` changes.

### Validation strategy

**Executed in this run** (stand-in workspace, `linux/arm64`, Docker Desktop 29.5.2, 2026-09-18; the
workspace and every image were deleted afterwards). These are results, not proposals.

| # | Command | Expected | Observed |
|---|---|---|---|
| C1 | `docker build -t rslbp-serve:probe .` | exit 0 | exit 0; `Finished \`release\` profile [optimized] target(s) in 22.88s`; 47.0 s wall |
| C2 | `docker image inspect --format '{{.Config.User}} {{.Config.Healthcheck.Test}} {{.Size}}'` | non-root user; exec-form probe; small image | `nonroot:nonroot`; `[CMD /bin/busybox wget --spider -q -T 3 http://127.0.0.1:8080/healthz]`; **12,312,783** |
| C3 | `docker run -d`; `docker top`; `docker inspect --format '{{.State.Health.Status}}'`; `curl -o /dev/null -w '%{http_code}' …/healthz` | PID 1 non-root; `healthy`; 200 | UID **65532**; `healthy`, `FailingStreak: 0`, first probe `ExitCode 0` in 47.7 ms; **200** |
| C4 | touch `crates/web/src/lib.rs`; rebuild with `--progress=plain` | only workspace crates under `Compiling` | only `rs-launch-blueprint-web` and `rs-launch-blueprint`; `Finished … in 10.72s` |
| C5 | same two builds with the cache mounts removed | full recompile both times | 21.82 s then **21.80 s**, all 54 packages — a 50.8 % cache benefit |
| C6 | `docker stop -t 10` | R67's SIGTERM integer | `ExitCode=143`, `OOMKilled=false` |
| C7 | `id` in `cc-debian12:debug-nonroot` and `cc-debian13:debug-nonroot` | uid 65532 in both | `uid=65532(nonroot) gid=65532(nonroot)` in both |
| C8 | probe the runtime for `sh`, `bash`, `curl`, `wget` | all absent | all absent; `/bin` and `/usr/bin` hold no applets |
| C9 | build three runtime variants and compare `.Size` | distroless smallest | **12,312,783** / **11,499,318** (no probe) / **35,680,357** (`debian:trixie-slim`+`curl`) |
| C10 | run the `debian-slim`+`curl` variant | healthy, non-root | `healthy`, uid **999** |
| C11 | `objdump -T <binary> \| grep -o 'GLIBC_[0-9.]*' \| sort -uV`; `libc.so.6 --version` in each base | binary floor ≤ runtime glibc | binary ≤ **GLIBC_2.34**; builder and `cc-debian13` **2.41-12+deb13u4**; `cc-debian12` **2.36-9+deb12u14** |
| C12 | build the trixie binary onto `cc-debian12:nonroot` and run it | hypothesis: fails | **it worked** — hypothesis refuted; the suite rule is precautionary |

**Proposed for P03, not run here.** (1) Every check above, re-run on `ubuntu-latest` for `linux/amd64` —
nothing in this report proves the amd64 build. (2) The **negative** healthcheck: kill the listener inside a
running container and assert the status reaches `unhealthy` after `--retries` consecutive failures; the
passing path alone does not show the probe detects anything. (3) A grammar assertion that every `FROM` in
the Dockerfile matches `@sha256:[0-9a-f]{64}`. (4) A property assertion that the workflow contains no
`docker/login-action` and no `push: true`, so "we do not publish" is checked rather than conventional.
(5) `docker run --rm --entrypoint /bin/sh <image> -c true` **must fail**, as a positive test of the
minimum-content property. (6) A `cargo build --release --locked --features web --bin rslbp-serve` at the
repository root outside Docker, asserting the image build and the host build are the same command.

### Confidence & re-verify trigger

**High** on everything measured: the image shape, the non-root identity, the healthy transition, the
graceful-shutdown exit code, the three size comparisons, the cache-mount benefit and its counterfactual, and
the glibc readings. All were executed on 2026-09-18 and are reported with the command and the observed
value. **High** on the gate-2 exclusion of `cargo-chef`: the manifest was read at tag `v0.1.78`, the ruling
is quoted verbatim from `docs/planning/p02/execution-ledger.md:414`, and R69 revision 10 line 1288 is the
sibling precedent for applying it to a non-linked tool. **Medium** on two judgments: that the template should
not publish an image (a view about what a template is for, which the owner may simply reverse), and that
builder and runtime Debian suites should match (precautionary — C12 refuted the failure it guards against).
**Explicitly unproven:** the `linux/amd64` build, the `unhealthy` transition, the musl/alpine costs the owner
reference asserts and this run did not measure, and Chainguard's versioned-tag availability.

Re-verify when any of these happens, whichever comes first: **R69 republishes** `web-extra-surface` (the
`- assumes` line above carries revision 9's `src/web/` bytes while the design uses revision 10's
`crates/web` paths); **R80 publishes** the liveness path, or moves it off `/healthz`; **R77 publishes** the
port and host environment variable names; **R11 publishes** `ci-job-structure`, which places the build job;
**R19** adds the `docker` ecosystem, which is this item's own hand-off landing; **R08 publishes** its
permission model, which prices the publish-on-release alternative properly; **R68 publishes** or changes its
`[profile.release]` or its follower-mode flow; the owner rules on whether fitness gate 2 reaches non-linked
developer tools, or `cargo-chef` ships a release declaring `rust-version` — either readmits the runner-up in
member 1; **distroless** publishes `cc-debian14` or retires `cc-debian13`; **Debian** promotes a new stable
suite, which moves what `rust:<ver>-slim` means; any of the three pinned digests moves; the `msrv-policy`
floor advances past 1.96; or **2027-03-18**, twelve months from the research date.

### Sources

**Primary specifications and first-party documentation.**
`https://raw.githubusercontent.com/moby/buildkit/v0.26.1/frontend/dockerfile/docs/reference.md` — the
Dockerfile frontend's own reference at tag `v0.26.1`; `RUN --mount=type=cache` options and persistence
contract at lines 843–892, `HEALTHCHECK` forms, options and exit-code contract at lines 2819–2880. Retrieved
2026-09-18.
`https://raw.githubusercontent.com/kubernetes/website/main/content/en/docs/concepts/workloads/pods/pod-lifecycle.md`
— the Pod probe model; zero occurrences of `healthcheck`. Retrieved 2026-09-18.
`https://static.rust-lang.org/dist/channel-rust-stable.toml` — `[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`,
channel `date = "2026-09-03"`. Retrieved 2026-09-18.

**Registry and package endpoints, with the field read.**
`GET https://crates.io/api/v1/crates/cargo-chef` → `crate.recent_downloads` 997,778, `crate.downloads`
4,245,274; `GET https://crates.io/api/v1/crates/cargo-chef/versions` → newest non-yanked `0.1.78`,
`created_at` 2026-08-12T06:19:24.814981Z, `license` "Apache-2.0 OR MIT", `rust_version` **null**. Retrieved
2026-09-18.
`https://raw.githubusercontent.com/LukeMathWalker/cargo-chef/v0.1.78/Cargo.toml` — no `rust-version` key;
`edition = "2018"`. Retrieved 2026-09-18.
`https://rustsec.org/packages/cargo-chef.html` → **404** (no advisories); convention verified against `time`
(200), `tokio` (200), `serde` (404), `axum` (404). Retrieved 2026-09-18.
`GET https://hub.docker.com/v2/repositories/library/rust/tags?page_size=100&name=slim` and
`…/tags/1.98.1-slim-trixie` → index digest `sha256:ca5c572a…`, amd64 `sha256:d61ede89…` 327,954,032 B, arm64
`sha256:eabef6ff…` 291,185,108 B, `last_updated` 2026-09-18T19:46:48Z; `1.98.1-slim-bookworm` →
`sha256:8d50cf1c…`. Retrieved 2026-09-18.
`GET https://hub.docker.com/v2/repositories/library/busybox/tags?page_size=50&name=musl` → `1.38.0-musl`
`sha256:32b5cdad…`, `last_updated` 2026-08-02T04:57:53Z. Retrieved 2026-09-18.
`GET https://gcr.io/v2/distroless/cc-debian13/tags/list` → 6,044 tags including `latest`, `nonroot`, `debug`,
`debug-nonroot` and per-architecture suffixes; `GET https://gcr.io/v2/distroless/cc-debian12/tags/list` →
17,103 tags. `HEAD https://gcr.io/v2/distroless/cc-debian13/manifests/nonroot` with
`Accept: application/vnd.oci.image.index.v1+json` → `docker-content-digest: sha256:54df941e…`,
`content-type: application/vnd.oci.image.index.v1+json`. Retrieved 2026-09-18T22:01:10Z.

**GitHub REST, one call per ≥20 s, each with its retrieval timestamp.**
`repos/LukeMathWalker/cargo-chef` 22:01:30Z — 2,709 stars, `archived` false, `pushed_at` 2026-08-12T06:19:27Z.
`search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue+is:open` 22:01:52Z — `total_count` 35.
`repos/LukeMathWalker/cargo-chef/issues?state=all&sort=created&direction=desc&per_page=10` 22:02:14Z — six
issues (#367, #366, #365, #363, #361, #359) spanning 2026-06-05 to 2026-09-10, **all with `comments: 0`**.
`repos/GoogleContainerTools/distroless` 22:02:35Z — 23,084 stars, not archived, pushed 2026-09-18T20:38:17Z.
`search/issues?q=repo:GoogleContainerTools/distroless+is:issue+is:open` 22:02:57Z — `total_count` 8.
`repos/docker/build-push-action` 22:03:19Z — 5,404 stars, not archived, pushed 2026-09-17T11:52:52Z.
`repos/moby/buildkit` 22:03:41Z — 10,275 stars, not archived, pushed 2026-09-18T17:18:12Z, 849 open issues.
`repos/atuinsh/atuin` 22:19:54Z — 31,698. `repos/LemmyNet/lemmy` 22:20:16Z — 14,601.
`repos/meilisearch/meilisearch` 22:20:37Z — 59,328. `repos/astral-sh/uv` 22:20:59Z — 89,956. All 2026-09-18.

**Adopter Dockerfiles, read at each project's default branch on 2026-09-18.**
`https://raw.githubusercontent.com/atuinsh/atuin/main/Dockerfile` (48 lines; chef digest line 1, the
skeletonisation caveat lines 19–21, `useradd` line 32, "curl for the healthcheck" line 33, `USER` line 37,
`HEALTHCHECK` lines 45–46).
`https://raw.githubusercontent.com/LemmyNet/lemmy/main/docker/Dockerfile` (chef image line 6, runner
`debian:sid-slim` line 7, `useradd` line 70, `USER` line 71).
`https://raw.githubusercontent.com/astral-sh/uv/main/Dockerfile` (digest-pinned `ubuntu:24.04` line 1, cache
mount line 14, `FROM scratch` line 70).
`https://raw.githubusercontent.com/meilisearch/meilisearch/main/Dockerfile` (alpine compiler line 2, alpine
runtime line 21).
`https://raw.githubusercontent.com/paritytech/polkadot-sdk/master/docker/dockerfiles/polkadot/polkadot_builder.Dockerfile`
(`useradd` line 23, `USER` line 32).
`https://raw.githubusercontent.com/reproducible-containers/buildkit-cache-dance/main/README.md` (first line:
"Save `RUN --mount=type=cache` caches on GitHub Actions or other CI platforms").

**Pinned source repositories, read through the pin.**
`git -C ~/c/py-launch-blueprint show b08bccfb:Dockerfile` (32 lines: builder `:6`, `uv sync --frozen
--no-install-project` `:10-13`, `groupadd`/`useradd` `:19`, `USER app` `:21`, `PLBP_WEB_HOST=0.0.0.0`
`:23-25`, `EXPOSE 8000` `:26`, `HEALTHCHECK` `:29-30`, `CMD` `:32`);
`git show b08bccfb:.dockerignore`; `git grep -n -i "docker" b08bccfb -- .github` → one line,
`api-contract.yml:28`; `git grep -c -i -E "ghcr\.io|docker build|docker/build-push|buildx|docker/login|docker push" b08bccfb -- .github`
→ exit 1; `git grep -n "docker" b08bccfb -- Justfile` → `:317-318`.
`git -C ~/c/ts-launch-blueprint ls-tree -r --name-only cb1cbcb2 | grep -i -E "docker|container"` → no output.
All read 2026-09-18.

**Programme records.**
`docs/port/COMMONALITY.md` rows F017 (`:23`), F223 (`:227`), F303 (`:307`), F328 (`:332`), F336 (`:340`),
F337 (`:341`). `docs/port/areas/web-service.md` `:43-44`; `docs/port/areas/packaging-distribution.md` `:21`.
`docs/port/BASELINE-REVIEW.md` `:39` and `:416` (F017 `retained`); no F223/F336/F337 row exists there.
`docs/port/PARAMETERS.md` `:12` (`ci-job-structure` = `—`), `:15` (`build-tool-output-shape`), `:17`
(`web-extra-surface`). `docs/port/README.md` (verdict vocabulary).
`docs/port/OWNER-REVIEW.md` `:47-68` (the licence ruling, gate 1 `inapplicable`).
`docs/planning/p02/execution-ledger.md` `:414` (fitness gate 2 read strictly);
`docs/planning/p02/owner-decisions.md` §11 (the reference architecture as STANDING INPUT) and `:452-460`.
`inputs/owner-reference-axum-companion-stack-2026-09-16.md` (C14 and C15 table rows, the C15 *Details*
paragraph, the Variant A and Variant B Dockerfile listings, the *Caveats* section).
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (revision 10, accepted and
unpublished; `- owns web-extra-surface` at `:1791`; `watchexec-cli` gate-2 exclusion at `:1288`; the
cargo-chef/mold hand-off at `:399`).
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (revision 1, four-package workspace).
`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md` (revision 1; `[profile.release]`
`:51-62`; the R51 hand-offs at `:32` and `:76`).
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` (synchronous core, `ureq` + rustls).
`research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md` (system tier `/etc/xdg`);
`research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/DECISION.md` (`RSLBP_TOKEN` env tier);
`research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md` (XDG bases).
`research/topics/49-build-target-declaration/DECISION.md` (`build-tool-output-shape`, `include` allow-list,
one binary target, `autobins = false`); `research/topics/19-dependabot-config-shape/DECISION.md` `:66`
(F053, `docker` ecosystem conditional on R51); `research/topics/20-third-party-action-pinning-policy/DECISION.md`
(SHA-pinning principle); `research/topics/25-semver-bump-strategy/DECISION.md` and
`research/topics/26-packed-artifact-content-guard/DECISION.md` (release mechanics, read for consistency; this
item creates no obligation on either).

**Method notes.** Endpoints queried: `crates.io` (`/api/v1/crates/cargo-chef`, `/versions`); GitHub REST via
a keyring-authenticated `gh api` for eleven repository, search and issue-list calls, each separated by 21
seconds and each stamped with its own UTC retrieval time; `rustsec.org/packages/<name>.html` for five crates,
to establish the 200-versus-404 convention before relying on it; Docker Hub's registry API
(`hub.docker.com/v2/repositories/library/{rust,busybox}/tags…`); Google's container registry
(`gcr.io/v2/distroless/{cc-debian12,cc-debian13}/{tags/list,manifests/nonroot}`, the manifest with an OCI
index `Accept` header); `static.rust-lang.org`; and `raw.githubusercontent.com` for the buildkit and
kubernetes documentation at pinned refs and for six adopter Dockerfiles. Both source repositories were read
only through their pins with `git show` and `git grep` against the pinned commit, never from a working tree.
All empirical results are from a disposable four-package stand-in workspace built under a subdirectory of
`$TMPDIR` that was deleted afterwards, with Docker Desktop 29.5.2 and buildx v0.34.0-desktop.1 on macOS
Apple Silicon; every image and container created was removed and the builder cache pruned. No image was
pushed anywhere. **What could not be verified, stated plainly:** (1) nothing here was built for
`linux/amd64` — every measurement is `linux/arm64`, and the amd64 numbers may differ, particularly the image
sizes; (2) the `unhealthy` failure transition was never observed, only the healthy one; (3) the musl and
alpine costs the owner reference asserts were not measured in this run and are carried as its claim;
(4) `GoogleContainerTools/distroless` issue responsiveness was not sampled, only its open-issue count;
(5) whether Chainguard's free tier still publishes versioned tags was not checked, so that candidate is
recorded as an evidence gap rather than ranked; (6) the Docker documentation site's Rust language guide was
not readable by `curl` (the pages are client-rendered and `docs.docker.com/guides/rust/containerize/`
returned 404 while `/guides/rust/` returned an empty link set), so the first-party Rust-specific guidance is
cited through the Dockerfile reference in `moby/buildkit` instead, which is the normative document in any
case; and (7) no GitHub Actions workflow was executed, so every CI claim in this report is a proposal for
P03 rather than a result.
