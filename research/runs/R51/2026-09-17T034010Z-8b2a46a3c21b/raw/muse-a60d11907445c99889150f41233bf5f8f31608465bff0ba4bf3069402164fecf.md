# R51 container-image — raw research report (Muse engine)

Actor: research-muse-2026-09-17T034010Z-8b2a46a3c21b. Retrieval date for all live queries below: 2026-09-21 (UTC).
Item kind: bundle. Members: container-image-artifact (F223), multistage-nonroot-build (F336), liveness-healthcheck (F337).
Conditions: R69 `web-extra-surface` is ADOPTed (a `web` feature exists), so the contingency in the prompt is satisfied and this report recommends unconditionally on that axis. R69 revision 10 (accepted, unpublished at retrieval time) renames the feature to `web = ["dep:rs-launch-blueprint-web"]` on a workspace root with the gated tree at `crates/web/`; per standing rules it is a prose-only design input here, and every `assumes` line below stays byte-identical to the live registry (revision 9 value).

### Landscape

Category decided: whether the template ships a container image for its optional web-service build, and the image's build layering, runtime user, and liveness probe. Three-bin map of the Rust/Docker field (candidates are drawn only from this map):

- Built-in / first-party toolchain: Docker multi-stage builds (`FROM ... AS`, `COPY --from=`) and `USER` / `HEALTHCHECK` instructions (Docker Dockerfile reference); BuildKit cache mounts (`RUN --mount=type=cache`) for cargo registry/git/target persistence; official `rust:<version>-slim` builder images; `cargo build --locked` lockfile-frozen builds; `debian:<release>-slim` as the default glibc runtime.
- Established industry standard: `cargo-chef` planner/cook dependency-layer caching plus the `lukemathwalker/cargo-chef` builder images; `gcr.io/distroless` (`cc`/`base`/`static`) minimal runtimes with a built-in `nonroot` user; `useradd`-created app users on `debian-slim`/`ubuntu` runtimes; shell-form `HEALTHCHECK CMD curl -f ...` probing (Docker's own documented example shape).
- Up-and-comer: Chainguard (`cgr.dev`) minimal images; cache-mount-only Dockerfiles that drop cargo-chef; `sccache` compilation-artifact caching inside Docker builds; `docker buildx` bake/HCL-driven multi-target builds.

Authoritative sources used, and why each counts: (1) Docker Dockerfile reference (`docs.docker.com/reference/dockerfile`), the tool vendor's normative instruction semantics (HEALTHCHECK forms/defaults, shell vs exec, USER). (2) GoogleContainerTools/distroless README, the image maintainer's statement of what distroless contains (no shells/package managers) and its current `*-debian13` line. (3) cargo-chef README and issue tracker, the tool maintainer's (LukeMathWalker, author of Zero to Production in Rust) canonical 3-stage Dockerfile and flag-parity rule, corroborated by 1.0M recent crates.io downloads and 5.6M Docker Hub pulls. (4) Depot's "Optimal Dockerfile for Rust" guide, a commercial container-build vendor's public recommendation (cargo-chef + cache mounts + sccache + non-root user). No single blog post is treated as authoritative; individual write-ups below are leads corroborated by primary sources.

Practice evidence (well-regarded = high adoption, active maintenance, cited as reference; figures retrieved 2026-09-21 via `GET https://api.github.com/repos/<o>/<r>`): Qdrant (`qdrant/qdrant`, 34,736 stars, pushed 2026-09-21) — `Dockerfile` uses `lukemathwalker/cargo-chef` planner/builder stages, a `debian:13-slim` runtime, `groupadd`/`useradd` with `USER "$USER_ID:$USER_ID"`, no `HEALTHCHECK`. Lemmy (`LemmyNet/lemmy`, 14,605 stars, pushed 2026-09-21) — `docker/Dockerfile` uses cargo-chef stages, `debian:sid-slim` runtime with `apt install ... curl` commented "curl can be used for healthchecks", `groupadd`/`useradd` with `USER $UNAME`, no `HEALTHCHECK`. Meilisearch (`meilisearch/meilisearch`, 59,363 stars, pushed 2026-09-21) — `Dockerfile` uses plain `rust:1.89-alpine3.22` builder with no dependency caching, `alpine:3.22` runtime with `curl`+`tini`, runs as root, no `HEALTHCHECK` (dissenting practice on caching and user). Depot guide — chef + cache mounts + sccache, `ubuntu:24.04` runtime, `groupadd`/`useradd` + `USER`, no `HEALTHCHECK`. cargo-chef README canonical example — chef stages + `debian:trixie-slim` runtime, no `USER`/`HEALTHCHECK`.

Fit over abstract best: the template is CLI + library + optional axum web service (R69: `web` feature, `<app>-serve` binary, env-driven knobs). The image exists only for the `web` build, serves forks running `docker build`/`docker run`/Compose locally and in CI, and must preserve py's three principles (image exists for the optional web extra; dependency layer cached separately from source with a frozen lockfile; container declares its own liveness) while fitting Rust idioms (compiled binary, no interpreter in the runtime).

### Principles and implementation

Shared requirement and source. F223 (packaging-distribution, py-only): the template ships a container image as a distribution artifact for its optional web-service build — py `Dockerfile:6`, multi-stage `uv sync` build, tied to the optional `web` extra (`docs/port/areas/packaging-distribution.md:21`). F336 (web-service, py-only): the production image is a non-root multi-stage build — py `Dockerfile:13` (`uv sync --frozen --no-install-project --no-dev --extra web`) then `Dockerfile:21` (`USER app`); notes record WEB-32: lockfile-frozen, dependency layer cached separately from source (`docs/port/areas/web-service.md:43`). F337 (web-service, py-only): the container declares its own liveness healthcheck — py `Dockerfile:29` (`HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3`); probes `/healthz` via `urllib` since the slim base has no `curl` (`docs/port/areas/web-service.md:44`). ts has no web service and no image (F303), so there is no ts mechanism to reconcile — only the absence to note. Agreement level: capability + architectural pattern (ship an image; multi-stage with cached frozen dependency layer; non-root runtime; self-declared liveness probe). What must agree: presence of the `Dockerfile`, dependency-before-source layering, frozen lockfile, non-root `USER`, a `HEALTHCHECK` probing the R80 liveness endpoint. What may vary: exact base-image tags, builder-image vendor, whether BuildKit cache mounts supplement layer caching, curl vs another probe binary.

Essential behaviors and observable acceptance criteria: (1) `docker build` from a clean checkout with no network except registry pulls produces a runnable image for the `web` build. (2) Rebuilding after touching only `src/` reuses the dependency-compile layer (observable: the `cargo chef cook` step reports `CACHED`, or rebuild wall-time stays near the incremental cost). (3) The build fails rather than resolving fresh versions if `Cargo.lock` is stale (`--locked`). (4) `docker inspect` shows `Config.User` non-root/nonempty. (5) `docker inspect` shows a `Healthcheck` whose `Test` probes `/healthz`; a started container reaches `healthy` (observable via `docker inspect --format '{{.State.Health.Status}}'`).

Architectural alternatives compared before choosing libraries. (A) cargo-chef layer caching vs BuildKit cache mounts vs dummy-COPY trick. Chef's recipe (all `Cargo.toml` + `Cargo.lock`, per its README) is the direct Cargo analogue of py's `uv sync --frozen --no-install-project` pre-source-copy pattern, it is workspace-aware (matters under R69 revision 10's `crates/web` member), and it is what current practice uses (Qdrant, Lemmy, Depot, chef README). Cache mounts (`--mount=type=cache` on `/usr/local/cargo/registry`, `/usr/local/cargo/git`, `target/`) persist cargo's own caches outside the layer system; small projects have replaced chef with them (e.g. `scylla-ops/scylla` commit 2026-04-07, `mcaney006/pack-plan` commit 2026-05-02 — leads, not authorities), while Depot combines both (chef for layer separation, mounts for registry/git/sccache persistence). They complement rather than supersede: mounts do not give layer-level dependency separation on a cold builder, and chef does not persist the registry download cache. The pre-chef dummy-`COPY Cargo.toml` + stub `main.rs` trick is superseded by chef (same effect, manual skeleton, no workspace handling). Decision: chef layer caching as the required mechanism; cache mounts as an allowed supplement, not required (keeps the template buildable on plain `docker build` without BuildKit syntax assumptions beyond multi-stage). (B) Runtime base: `debian-slim` vs distroless vs `scratch`/musl vs alpine. `debian:trixie-slim` keeps glibc (no musl DNS/TLS/allocator edge cases, agreeing with owner-reference C15's musl/alpine rejection grounds), ships a shell and `apt` so `curl` + `ca-certificates` install in one layer, and matches dominant practice (Qdrant `debian:13-slim`, Lemmy `debian:sid-slim`, chef README `debian:trixie-slim`). Distroless (`cc-debian13`) is smaller and has a built-in `nonroot` user, but ships no shell (distroless README: "They do not contain package managers, shells or any other programs"), so py's F337 principle (self-declared shell-form probe) cannot transfer without adding a probe binary — none of the surveyed Rust projects do that; all three omit `HEALTHCHECK` instead. `scratch`/musl-static is smallest but inherits the musl risks C15 rejects and likewise has no probe tooling. Alpine (Meilisearch's choice) is musl-based with the same C15 ground against it. Decision: `debian:trixie-slim` runtime. This differs from owner-reference C15 (`cargo-chef → distroless/cc-debian12`, `Dockerfile` `FROM gcr.io/distroless/cc-debian12`, `USER nonroot:nonroot`) on the runtime base only, with ground: F337's self-declared `HEALTHCHECK` (shell form per Docker's documented `curl` example) requires a shell + curl in the runtime, distroless provides neither, and every surveyed production Dockerfile pairs chef with a shell-carrying slim runtime. The chef stages, the non-root requirement, and the musl/alpine rejection in C15 are agreed with. (C) Probe tooling: add `curl` to the runtime vs exec-form probe vs orchestrator-only probes. Rust has no py-style `urllib` fallback (no interpreter in a minimal runtime), so a shell-form probe needs `curl` installed (Lemmy does exactly this, citing healthchecks). Exec-form `HEALTHCHECK CMD ["..."]` avoids the shell (Docker reference: the command "can be either a shell command ... or an exec array") but still needs a probe binary in the image — the template's serve binary has no health-probe subcommand and adding one is outside this item's scope (R69 owns the binary's surface). Orchestrator probes (Kubernetes, Cloud Run) ignore Dockerfile `HEALTHCHECK` entirely, which is why Qdrant/Lemmy/Meilisearch omit it — but the template's image also serves `docker run`/Compose users, where the instruction is honored, and declaring it is harmless under orchestrators. Decision: install `curl` (+ `ca-certificates`) in the runtime and declare a shell-form `HEALTHCHECK` probing `/healthz`, preserving F337. (D) Publish vs build-on-demand: the port evidence records the Dockerfile's presence/content but no image build/publish CI step, and the template owns no registry; R68 owns release artifact channels (undecided at retrieval). Decision: ship the `Dockerfile`, smoke-build it in CI, publish nothing from the template itself — forks build on demand and R68 may later adopt this file as its image definition.

How the recommended design preserves each principle: F223 — a root `Dockerfile` builds exactly the `web` feature's serve binary (`--features web --bin <app>-serve`), the Cargo analogue of py's `--extra web` image. F336/WEB-32 — `cargo chef prepare` (planner) then `cargo chef cook --release --features web` (builder) cache the compiled dependency layer before `COPY . .`, mirroring `uv sync --frozen --no-install-project`; `--locked` on the final build gives the frozen-lockfile guarantee; `groupadd`/`useradd` + `USER app` give the non-root runtime (py `USER app`). F337 — `HEALTHCHECK` with py's exact timings (`--interval=30s --timeout=3s --start-period=5s --retries=3`) probes `/healthz` via `curl -f`, the documented Docker idiom, substituting installed-`curl` for py's `urllib` workaround for the same `curl`-less-slim problem.

Maturity, dependability, performance, integration cost. cargo-chef 0.1.78 (2026-08-12) is `active`: 1,005,246 recent / 4,277,400 all-time crates.io downloads, 2,712 GitHub stars, 5,649,508 Docker Hub pulls of `lukemathwalker/cargo-chef`, release cadence sustained into 2026; issue triage is quiet (10/10 most recent issues unanswered) but releases, not chatter, are its maintenance signal. Dependability risk: single-maintainer tool; mitigation is that the recipe/cook contract is simple and the builder pin is one `ARG`. Representative performance: chef's whole value is avoiding dependency recompilation (the dominant Rust docker-build cost); no absolute figure is claimed — acceptance criterion (2) above measures it comparatively per build. Integration cost: one `Dockerfile`, no new Cargo dependency (chef runs only in the builder image), runtime cost of one `curl` package.

Minimal realistic example (proposed; the full build/run half is planned, the static half executed — see Validation strategy). `<app>-serve` is the R69 `[[bin]]` name; R69 revision 10 (prose-only input) additionally implies the build runs at the workspace root with `--features web` resolving the optional `crates/web` member, which chef supports because the recipe captures every workspace `Cargo.toml`:

```dockerfile
# syntax=docker/dockerfile:1
ARG RUST_VERSION=1.89
ARG RUNTIME_IMAGE=debian:trixie-slim

FROM lukemathwalker/cargo-chef:latest-rust-${RUST_VERSION} AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --features web --recipe-path recipe.json
COPY . .
RUN cargo build --release --locked --features web --bin <app>-serve

FROM ${RUNTIME_IMAGE} AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -r app && useradd -r -g app -u 10001 app
WORKDIR /srv
COPY --from=builder --chown=app:app /app/target/release/<app>-serve /srv/<app>-serve
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8080}/healthz || exit 1
ENTRYPOINT ["/srv/<app>-serve"]
```

Executable acceptance check (planned; needs a Docker daemon, unavailable here — see Validation strategy): `docker build -t r51check .` from the template root; `touch src/main.rs && docker build` reuses the cook layer; `docker inspect` asserts `Config.User == "app"` and a `Healthcheck.Test` containing `/healthz`; `docker run -d -p 8080:8080 r51check`, then poll `docker inspect --format '{{.State.Health.Status}}'` to `healthy` and `docker exec` `id -u` to `10001`. The `/healthz` path and `PORT` default follow R80/R77 respectively (both undecided; the spellings above are conditional, recorded in prose, no registered value contradicted).

No `BASELINE-REVIEW:` finding: F223/F336/F337 are DIVERGENT rows this item decides, not REUSE/ADOPT baselines, and no retained mechanism was challenged.

### Recommendation

One stack. Ship a root `Dockerfile` for the `web` build: `lukemathwalker/cargo-chef` planner/cook/builder stages (`ARG RUST_VERSION`, cook and build both `--release --features web`, final build `--locked --bin <app>-serve`); `debian:trixie-slim` runtime with installed `curl` + `ca-certificates`, `groupadd`/`useradd` app user (uid 10001) and `USER app`; py's `HEALTHCHECK` timings (`30s`/`3s`/`5s`/`3`) with `CMD curl -f http://localhost:${PORT:-8080}/healthz || exit 1`; exec-form `ENTRYPOINT`. Build-on-demand, smoke-built in CI on the ubuntu leg; no image publishing from the template (publish channels are R68's scope).

### Members

#### container-image-artifact

##### Landscape

Pattern member (F223): whether the template ships a container image for the optional web-service build. Field map: built-in — a hand-written `Dockerfile` at the repo root built with plain `docker build`; established — root `Dockerfile` multi-stage builds in Rust web projects (Qdrant `Dockerfile`, Lemmy `docker/Dockerfile`, Meilisearch `Dockerfile`, all retrieved 2026-09-21); up-and-comer — generated images via `nixpacks`/`buildpacks` and `docker buildx bake` HCL targets. Authorities: the three adopter Dockerfiles (practice) and py `Dockerfile:6` (source precedent, `docs/port/areas/packaging-distribution.md:21`).

##### Principles and implementation

Principle (py-only, F223): the optional web extra gets a runnable container image as a distribution artifact. Agreement level: capability (an image exists and runs the web build) — the build tool is this bundle's other members. Essential behavior: one documented build command from a clean checkout yields an image that starts the serve binary. Acceptance: `docker build -t img .` succeeds; `docker run` starts `<app>-serve` and serves traffic. ts contributes no mechanism (no web service, F303). The R69 `web` feature (adopted) is the Cargo analogue of py's `web` extra, so the image builds `--features web` (under accepted-but-unpublished R69 revision 10, resolving the optional `crates/web` member — prose-only input here). No crate figures apply to this pattern member (no Rust crate is selected by it); the builder tooling figures live under `multistage-nonroot-build`.

##### Dominant choice

A root `Dockerfile` building the web-service binary, as all three surveyed production Rust services do (Qdrant, Lemmy, Meilisearch Dockerfiles, retrieved 2026-09-21). No surveyed project generates its image or omits container distribution for its server component.

##### Qualified shortlist

Root multi-stage `Dockerfile` (recommended form; layering decided by the next member). Single-stage `rust:<version>` image (builds and runs in one stage): qualifies on correctness but is dominated on size, attack surface, and secret leakage (toolchain + sources ship in the runtime).

##### Excluded by gate

Nixpacks/buildpacks-generated image: excluded by gate 2-fit — the generated builder toolchain is outside the template's MSRV declaration and `Cargo.lock` control, and no surveyed Rust reference uses it; recorded as unproven for this template rather than license- or advisory-failed. No candidate failed gates 1–4 on license/advisory/OS grounds at the pattern level.

##### Up-and-comers

`docker buildx bake` HCL target definitions alongside the `Dockerfile` (one surveyed-adjacent lead: cache-mount-era Dockerfiles increasingly pair with bake files). Watched, not recommended: adds a second definition surface for one image.

##### Fit for this template

Exact fit: the template's `web` feature is off by default, so the image is the distributable form of the non-default build — the same role py's image plays for its `web` extra. The CLI/library need no image (native binaries, R68's scope).

##### Recommendation

ADOPT F223: ship a root `Dockerfile` that builds the `web` feature's `<app>-serve` binary.

##### Ranked runner-up

No `Dockerfile`; document `cargo build --release --features web` + forks write their own image. Loses: drops py's distribution-artifact capability and leaves every fork to re-derive the layering this bundle researches.

##### Tradeoffs

Maintaining a `Dockerfile` adds base-image-update burden (Dependabot/docker row territory, R19) and a CI build leg; in return forks get a working, reviewed starting point instead of N bespoke images.

##### Parameters

Member owns no parameter. Member consumes `web-extra-surface` (the `web` feature is what the image builds — full registry value under `### Parameters`, byte-identical) and the four fixed parameters (edition, MSRV policy, OS matrix, license — values under `### Parameters`). No `CONFLICT:` line: no registered value needs to change.

##### Migration implications

Add `Dockerfile` at the template root; document `docker build -t <app> .` in the web README section. No `Cargo.toml` change (no new dependency).

##### Validation strategy

Planned (needs a Docker daemon; none accessible here — see top-level Validation strategy): `docker build` from a clean checkout succeeds and `docker run` serves `/healthz`. Executed for this member: none beyond the tag-existence checks recorded at top level (base tags resolve, so the file's `FROM` lines are buildable inputs).

##### Confidence & re-verify trigger

High on ADOPT. Re-verify if R69's published decision stops shipping a `web` build at all, or if R68 adopts container publishing with requirements this file cannot meet.

##### Sources

py `Dockerfile:6` via `docs/port/areas/packaging-distribution.md:21`; Qdrant/Lemmy/Meilisearch Dockerfiles (raw.githubusercontent.com, retrieved 2026-09-21); R69 `web-extra-surface` registry value (parameters.json); owner-reference C15 `Dockerfile` (container-agreed, runtime-differed — see next member).

#### multistage-nonroot-build

##### Landscape

Pattern + tool member (F336/WEB-32): multi-stage, dependency-cached, non-root build. Field map: built-in — Docker multi-stage `FROM`/`COPY --from`, official `rust:<version>-slim` builders, `cargo build --locked`; established — cargo-chef planner/cook + `lukemathwalker/cargo-chef` images, `debian-slim`/`ubuntu` runtimes, distroless runtimes, `groupadd`/`useradd` + `USER`; up-and-comer — BuildKit cache-mount-only builds, Chainguard runtimes, `sccache` in builders. Authorities: Docker reference (stage semantics), cargo-chef README (maintainer's canonical 3-stage file), Depot Rust guide (independent vendor: chef + cache mounts + sccache + non-root), distroless README (no-shell statement + `*-debian13` line), Qdrant/Lemmy/Meilisearch Dockerfiles (practice).

##### Principles and implementation

Principle (py-only, F336/WEB-32): production image is a non-root multi-stage build with a lockfile-frozen dependency layer cached separately from source. Agreement level: architectural pattern (dependency-before-source layering; frozen lockfile; non-root runtime user). Essential behaviors: (1) dependency compilation layer invalidates only when manifests/lockfile change; (2) the build resolves nothing fresh (`--locked`/`--frozen` equivalent); (3) runtime runs as a non-root user. Acceptance: source-only rebuild reuses the cook layer; stale-lockfile build fails; `Config.User` is non-root. cargo-chef is the direct Cargo analogue of py's `uv sync --frozen --no-install-project` pre-source-copy step: `cargo chef prepare` emits a recipe (all `Cargo.toml` + `Cargo.lock`, hence workspace-aware for R69 revision 10's `crates/web` member) and `cargo chef cook` compiles dependencies before `COPY . .`. Flag parity between cook and build is mandatory (maintainer statement on issue #322, 2026-03-03). Runtime `debian:trixie-slim` keeps glibc, a shell, and `apt` (needed by the healthcheck member); `groupadd -r app && useradd -r -g app -u 10001 app` + `USER app` + `--chown` on the binary copy mirror py's `USER app` and the Qdrant/Lemmy/Depot idiom.

##### Dominant choice

cargo-chef 3-stage (planner → cook → build) on `lukemathwalker/cargo-chef`, runtime `debian-slim`, `useradd`-created app user. Figures (retrieved 2026-09-21): crates.io `GET /api/v1/crates/cargo-chef` — all-time 4,277,400, recent (90-day) 1,005,246 downloads; `GET /api/v1/crates/cargo-chef/versions` — newest non-yanked 0.1.78 created 2026-08-12 (a `0.49.0` yanked entry also listed); GitHub `GET /repos/LukeMathWalker/cargo-chef` — 2,712 stars, archived false, pushed 2026-08-12; search `repo:... is:issue is:open` total_count 35 (`open_issues_count` 50 includes PRs); Docker Hub `lukemathwalker/cargo-chef` — 5,649,508 pulls, updated 2026-09-19. Maintenance rubric: `active` (release + pushes within 6 weeks of retrieval, 1M recent downloads). Adopters: Qdrant `Dockerfile:19` (`FROM ... lukemathwalker/cargo-chef:latest-rust-1.98.0-bookworm AS chef`), Lemmy `docker/Dockerfile:6` (`ARG BUILDER_IMAGE=lukemathwalker/cargo-chef:latest-rust-${RUST_VERSION}`); reverse-dependencies endpoint is uninformative for a build tool (1 build-dep), so adoption is measured via Dockerfiles + Hub pulls. License `Apache-2.0 OR MIT` (versions endpoint) — gate 1 passes. Gate 2: chef ships no code into the template (builder-only), so template MSRV is unaffected; no `rust-version` declared on 0.1.78 (verified); the builder toolchain version is set by the `RUST_VERSION` ARG tracking the toolchain item (R42). Gate 3: no advisory names cargo-chef — `https://rustsec.org/packages/cargo-chef.html` returns HTTP 404 and an OSV `api.osv.dev/v1/query` for `cargo-chef` returns `[]` (both 2026-09-21); two bot-filed dependency-tree RUSTSEC issues (#365 RUSTSEC-2026-0190, #366 RUSTSEC-2026-0204, 2026-06/07) are unanswered and their applicability to 0.1.78 is an unverified gap (recorded under Validation strategy), not a verdict. `unsafe` posture: not audited (builder-only tool; none of its code ships in the image) — stated, not hidden. Gate 4: builder and runtime are Linux images; the CI build leg runs on `ubuntu-latest` (in-matrix); macOS runners do not build images. Gate 5: no default features / no async runtime in the template (not a dependency). Gate 6: chef adds builder-stage time only; runtime size unaffected; cache hits remove the dominant rebuild cost.

##### Qualified shortlist

`rust:<version>-slim` builder + `cargo install cargo-chef --locked` + same 3-stage flow (Depot's shape): qualifies; dominated on builder reproducibility (compiles chef per build unless cached) but avoids a third-party base image. Plain `rust:<version>-slim` multi-stage with the dummy-manifest COPY trick and no chef: qualifies on correctness; dominated on maintenance (hand-rolled skeleton, weak workspace handling) — this is the trick the HIGH question asks about, and current practice has not reverted to it. `ubuntu:24.04` runtime (Depot): qualifies; dominated for this template only by image size and by Qdrant/Lemmy/chef-README convergence on `debian-slim`.

##### Excluded by gate

`scratch` + musl-static runtime: excluded by fit-gate — musl DNS/TLS/allocator risks (same ground as owner-reference C15's musl rejection) and no shell for the healthcheck member; would also force a musl target into the builder. `alpine` runtime (Meilisearch's shape): excluded by the same musl ground (C15 concurs). Neither exclusion is a license/advisory/OS-matrix failure.

##### Up-and-comers

Chainguard `cgr.dev` minimal runtimes (not surveyed deeply enough to shortlist — gap noted); BuildKit `--mount=type=cache` registry/target mounts as a supplement (Depot combines them with chef; two small-project leads dropped chef for mounts alone — insufficient weight against Qdrant/Lemmy/Depot practice); `sccache` in builders (Depot; extra moving part, not needed for a template default).

##### Fit for this template

Exact fit: chef's recipe covers the whole workspace (R69 revision 10's `crates/web` member included), cook/build flag parity (`--release --features web`) matches the single-feature build, and `debian:trixie-slim` + `useradd` + `USER` transfers py's `USER app` with the ecosystem's dominant idiom. Builder pin via `ARG RUST_VERSION` (Lemmy's shape) keeps the toolchain version explicit and fork-overridable.

##### Recommendation

ADOPT F336: chef planner/cook/builder stages on `lukemathwalker/cargo-chef:latest-rust-${RUST_VERSION}`; `cargo chef cook --release --features web`; `cargo build --release --locked --features web --bin <app>-serve`; `debian:trixie-slim` runtime; `groupadd`/`useradd` app user (uid 10001); `USER app`.

##### Ranked runner-up

Distroless `cc-debian13` runtime with `USER nonroot` (owner-reference C15's shape). Loses on the healthcheck member's need for a shell + curl (distroless ships neither); wins on size and CVE signal. Revisit if the template ever drops the in-Dockerfile `HEALTHCHECK` in favor of orchestrator-only probes.

##### Tradeoffs

Depending on `lukemathwalker/cargo-chef` adds a third-party base image (single-maintainer project, though 5.6M pulls and current releases); the `rust:<version>-slim` + `cargo install chef` shortlist entry removes that at the cost of slower cold builds. `debian-slim` (~80MB class) is larger than distroless (~20MB class with a small binary) in exchange for shell/curl/apt debuggability.

##### Parameters

Member owns no parameter. Member consumes `web-extra-surface` (cook/build flag parity keys on the `web` feature name — full registry value under `### Parameters`, byte-identical) and the four fixed parameters (values under `### Parameters`). No `CONFLICT:` line.

##### Migration implications

The builder/runtime/`USER` stages of the root `Dockerfile` (see top-level example); `.dockerignore` excluding `target/` (standard; prevents host artifacts entering the planner context). No `Cargo.toml` change.

##### Validation strategy

Planned (needs a daemon): cold `docker build`; `touch` one file under the gated tree and rebuild — `cargo chef cook` step must report `CACHED`; `docker inspect` shows `Config.User == "app"`; stale-lockfile build (`--locked`) fails. Executed: Docker Hub tag checks — `debian:trixie-slim` 200, `debian:13-slim` 200, `debian:bookworm-slim` 200, `lukemathwalker/cargo-chef` tag `latest-rust-1` exists (updated 2026-09-19) — so every `FROM` input resolves; hadolint lint of the recommended file (see top-level Validation strategy for the run record).

##### Confidence & re-verify trigger

High on chef + `debian-slim` + `useradd`/`USER`. Re-verify if cargo-chef passes 6 months without a release, if a `RUSTSEC` names it or its tree is shown affected, or if Chainguard/distroless practice among top Rust services shifts the runtime consensus.

##### Sources

cargo-chef README + issues #322/#359/#361/#363/#365/#366/#367 (github.com/LukeMathWalker/cargo-chef, retrieved 2026-09-21); crates.io `cargo-chef` + `/versions` endpoints; Docker Hub `lukemathwalker/cargo-chef` repository + tags endpoints; OSV `v1/query` (empty); rustsec.org 404; Qdrant `Dockerfile:12-28,143,217-231` (chef + `debian:13-slim` + useradd + `USER`); Lemmy `docker/Dockerfile:1-40,51-70` (chef `ARG` shape + `debian:sid-slim` + curl + useradd + `USER`); Meilisearch `Dockerfile` (dissent: alpine, root, no chef); Depot `rust-dockerfile.mdx` (chef + cache mounts + sccache + `ubuntu:24.04` + useradd + `USER`); distroless README (no shell; `*-debian13` line); Docker reference (`USER`, multi-stage); owner-reference C15 (chef agreed; distroless runtime differed with ground above); py `Dockerfile:13,21` via `docs/port/areas/web-service.md:43`.

#### liveness-healthcheck

##### Landscape

Pattern member (F337): the container's self-declared liveness probe. Field map: built-in — `HEALTHCHECK [OPTIONS] CMD` shell form and `CMD ["..."]` exec form, `HEALTHCHECK NONE` (Docker reference); established — shell-form `curl -f http://localhost/<path> || exit 1` (Docker's own documented example), `curl`/`wget` installed into slim runtimes for probing (Lemmy installs curl "for healthchecks"; Meilisearch ships curl); up-and-comer — exec-form probes against a purpose-built `/healthz` subcommand binary, orchestrator-only probing (Kubernetes/Cloud Run, which ignore the Dockerfile instruction). Authorities: Docker reference (forms, defaults `30s`/`30s`/`0s`/`5s`/`3`, exit-code contract, single-instruction rule); distroless README (no shell ⇒ shell form unusable there); py `Dockerfile:29` (source precedent with `30s`/`3s`/`5s`/`3` timings).

##### Principles and implementation

Principle (py-only, F337): the container declares its own liveness healthcheck probing the service's liveness endpoint. Agreement level: capability (a declared probe exists and gates `healthy`) + pattern (probe the R80 liveness endpoint over HTTP). Essential behavior: Docker reports `starting` then `healthy` for a serving container and `unhealthy` after consecutive probe failures. Acceptance: `docker inspect` shows `Healthcheck.Test` containing `/healthz`; a started container reaches `healthy`; a wedged server reaches `unhealthy`. The ecosystem wrinkle: py probes with the interpreter it already ships (`urllib`, because its slim base has no `curl`); a Rust runtime has no interpreter, so the shell-form probe needs `curl` installed — the exact reversal of py's workaround for the same `curl`-less-slim problem, and Lemmy's Dockerfile documents the same conclusion ("curl can be used for healthchecks"). Exec form avoids the shell but still needs a probe binary in the image; the serve binary has no probe subcommand and its surface is R69's scope, so no exec-form target exists without scope creep. Timings carry py's values verbatim (`--interval=30s --timeout=3s --start-period=5s --retries=3`), which also match Docker's documented example shape (`--interval=5m --timeout=3s`, `curl -f ... || exit 1`). Target URL probes `/healthz` on `${PORT:-8080}`: the path follows R80 and the variable/default follow R77 (both undecided at retrieval — conditional spellings recorded in prose, no registered value contradicted). No crate figures apply (no Rust crate selected); probe tooling is the `curl` system package in the runtime stage.

##### Dominant choice

Shell-form `HEALTHCHECK CMD curl -f http://localhost:<port>/<liveness-path> || exit 1` with `curl` (+ `ca-certificates`) installed in a shell-carrying slim runtime. This is Docker's documented example idiom, py's principle transferred, and Lemmy/Meilisearch's installed-curl practice — though none of the three surveyed Rust projects declares the instruction itself (all rely on orchestrator probes), a tension resolved under Fit.

##### Qualified shortlist

Exec-form `HEALTHCHECK CMD ["curl", "-f", "http://localhost:..."]` (same tooling, no shell expansion — loses `${PORT:-...}` defaulting, so the port must be baked in). `HEALTHCHECK NONE` + documented orchestrator (Kubernetes/Compose) probe snippets: qualifies where the deploy target ignores the instruction (Cloud Run, Kubernetes); dominated for `docker run`/Compose users, who lose the built-in signal.

##### Excluded by gate

Shell-form `HEALTHCHECK` on a distroless/`scratch` runtime: excluded by fit — no `/bin/sh` exists to run it (distroless README), so the probe can never pass; pairing distroless with a probe requires a purpose-built static probe binary, for which no surveyed reference or maintained implementation was found (evidence gap, not a recommendation). No license/advisory/OS-matrix failure involved.

##### Up-and-comers

A `<app>-serve probe` / `healthcheck` subcommand enabling an exec-form probe with zero extra runtime packages (clean, but owned by R69's binary surface — noted as a future simplification, not decided here); Compose-level `healthcheck:` blocks duplicating the file's instruction (redundant if the file declares it).

##### Fit for this template

Adopting the in-Dockerfile probe preserves py's F337 capability for the template's primary image consumers (`docker build`/`docker run`/Compose forks and CI smoke runs), at the cost of one `curl` package. It is inert under Kubernetes/Cloud Run (which ignore the instruction and use their own probes), so it costs orchestrator deploys nothing — this resolves the tension with Qdrant/Lemmy/Meilisearch practice (they omit it because their deploy targets ignore it; the template serves a broader audience). The probe target stays conditional on R80 (path) and R77 (port variable).

##### Recommendation

ADOPT F337: declare `HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD curl -f http://localhost:${PORT:-8080}/healthz || exit 1` with `curl` + `ca-certificates` installed in the runtime stage.

##### Ranked runner-up

Omit the instruction (the Qdrant/Lemmy/Meilisearch shape) and document orchestrator probes only. Loses py's self-declared-liveness capability and the `docker run` health signal; wins a smaller runtime and zero probe maintenance. Correct choice only if the template's image is defined as orchestrator-only — it is not.

##### Tradeoffs

`curl` + `ca-certificates` widen the runtime package set (more CVE surface to track, mitigated by `--no-install-recommends` + `rm -rf /var/lib/apt/lists/*`); the `HEALTHCHECK` adds a per-interval localhost request (negligible; R80's access-log exclusion for probes, if adopted from py's F320, keeps it out of logs). Benefit: any Docker-native consumer gets liveness gating with no extra configuration.

##### Parameters

Member owns no parameter. Member consumes `web-extra-surface` (the probe target is the `web` build's serve binary — full registry value under `### Parameters`, byte-identical) and the four fixed parameters (values under `### Parameters`). The `/healthz` path and `PORT` spellings assume R80/R77 resolutions not yet registered; recorded as prose conditionals, not `assumes` lines. No `CONFLICT:` line.

##### Migration implications

The runtime `apt-get install curl ca-certificates` layer and the `HEALTHCHECK` instruction in the root `Dockerfile` (see top-level example). No `Cargo.toml` change; no new service code (the probe target is R80's endpoint, referenced, not implemented here).

##### Validation strategy

Planned (needs a daemon): build, `docker run -d`, poll `docker inspect --format '{{.State.Health.Status}}'` to `healthy` within ~30s; stop the in-container server (or point the probe at a closed port in a negative control) and observe `unhealthy` after 3 retries; `docker inspect` shows the `Test` array containing `/healthz`. A stub-server variant of this check (python one-liner standing in for the not-yet-existing serve binary) is staged at `/tmp/r51check/` but could not run here — see top-level Validation strategy. Executed: Docker reference semantics verified by reading (forms, defaults, exit codes, single-instruction rule); hadolint lint covers instruction syntax (see top-level run record).

##### Confidence & re-verify trigger

High on adopting the probe with curl. Re-verify if R80 renames the liveness path (mechanical target update), if R77 names the port variable differently (mechanical update), or if the template drops shell-carrying runtimes (forces the exec-form/probe-binary redesign).

##### Sources

Docker reference `HEALTHCHECK` section (forms, `--interval/--timeout/--start-period/--start-interval/--retries` defaults, exit-status contract, `curl -f http://localhost/ || exit 1` example; docs.docker.com, retrieved 2026-09-21); distroless README (no shells); Lemmy `docker/Dockerfile:53` (`apt install ... curl`, "can be used for healthchecks") and absence of any `HEALTHCHECK` in the Qdrant/Lemmy/Meilisearch Dockerfiles (orchestrator-probe practice, retrieved 2026-09-21); py `Dockerfile:29` + `/healthz`-via-`urllib` note via `docs/port/areas/web-service.md:44`; R80/R77 as unregistered-but-referenced follow-ups (prose conditionals only).

### Compatibility

Proof the members compose: the top-level example `Dockerfile` is the single composed artifact — the `container-image-artifact` member is the file itself, `multistage-nonroot-build` is its stages 1–4 plus `USER`, `liveness-healthcheck` is its runtime package install plus `HEALTHCHECK`. Interface contracts between members: (1) builder emits exactly one binary at `/app/target/release/<app>-serve` (R69 `[[bin]]` name `<app>-serve` with `required-features = ["web"]`), which the runtime stage copies — the `--bin` name and `--features web` flag are the shared contract, both from the assumed `web-extra-surface` value; (2) cook/build flag parity (`--release --features web` on both) per the chef maintainer's rule; (3) the runtime installs `curl` before declaring the shell-form probe that needs it, and `USER app` precedes `HEALTHCHECK` (same order as py `Dockerfile:21` then `:29`); (4) the probe target `/healthz` on `${PORT:-8080}` is conditional on undecided R80 (path) and R77 (variable/default) — no version matrix applies (no Cargo dependencies selected; the only versioned inputs are the `RUST_VERSION` ARG default, the `debian:trixie-slim` tag, and chef 0.1.x in the builder image, all verified resolvable on 2026-09-21). Shared-adopter corroboration of the composition (chef stages + slim runtime + created user): Qdrant and Lemmy Dockerfiles; the `HEALTHCHECK`-on-top composition is additionally corroborated by Docker's documented `curl` example rather than by an adopter (all three surveyed adopters omit the instruction — see Fit discussion in the healthcheck member).

### Parameters

R51 owns no parameter (per `## Couplings`, `owns:` is empty).

assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI

assumes rust-edition = 2024

assumes target-os-matrix = ubuntu-latest, macos-latest

assumes license = MIT OR Apache-2.0

No `CONFLICT:` line — the recommendation needs no registered value changed. (Accepted-but-unpublished R69 revision 10 renames the `web` feature to `web = ["dep:rs-launch-blueprint-web"]` on the workspace root with the gated tree at `crates/web/`; noted in prose only per standing rules. The `/healthz` path and `PORT` spellings are conditional on undecided R80/R77, recorded in prose, not as `assumes` lines.)

### Migration implications

Template changes: (1) add root `Dockerfile` (the recommended file under Principles and implementation, `<app>-serve` replaced by the real binary name); (2) add `target/` (and typically `.git/`) to `.dockerignore` so host build artifacts never enter the planner context; (3) document `docker build -t <app> .` + `docker run -p 8080:8080 <app>` in the web README section. No `Cargo.toml` change (cargo-chef runs only inside the builder image; no new dependency). CI wiring (which job smoke-builds the image, path-based skip keys on the `Dockerfile` + gated tree) belongs to R11/R50/R68 and is not specified here beyond the constraint that the build leg must run on `ubuntu-latest` (Linux Docker daemon). If R68 later adopts image publishing, this file is its build definition unchanged.

### Validation strategy

Executed checks (commands + outputs recorded; all run 2026-09-21):

1. `curl -A ... https://crates.io/api/v1/crates/cargo-chef` → 200, `downloads: 4277400, recent_downloads: 1005246, max_version: 0.1.78`. `.../cargo-chef/versions?per_page=10` → newest non-yanked `0.1.78 2026-08-12`, license `Apache-2.0 OR MIT`, `rust_version: None`; a `0.49.0` yanked entry also present.
2. `curl https://api.github.com/repos/LukeMathWalker/cargo-chef` → `stargazers_count: 2712, archived: False, pushed_at: 2026-08-12T06:19:27Z`. Search-issues `q=repo:LukeMathWalker/cargo-chef+is:issue+is:open` → `total_count: 35` (`open_issues_count: 50` includes PRs). Ten most recently opened non-PR issues (#367, #366, #365, #363, #361, #359, #356, #355, #353, #350; 2026-04-01..2026-09-10) all have 0 comments → maintainer first-response median undefined, unanswered 10/10; last maintainer replies observed on #322 and #315 (both 2026-03-03, OWNER). Verdict input: triage-quiet, release-active.
3. `curl https://rustsec.org/packages/cargo-chef.html` → HTTP 404 (no advisory page). `POST api.osv.dev/v1/query {"package":{"name":"cargo-chef","ecosystem":"crates.io"}}` → `[]`. Gate-3 crate verdict: no open advisory names cargo-chef. Open watch: bot-filed #365 (RUSTSEC-2026-0190) and #366 (RUSTSEC-2026-0204) against the dependency tree, unanswered — applicability to 0.1.78 NOT resolved (gap, see below).
4. `curl https://hub.docker.com/v2/repositories/lukemathwalker/cargo-chef/` → `pull_count: 5649508, updated: 2026-09-19`. Tag checks: `library/debian/tags/trixie-slim` → 200, `13-slim` → 200, `bookworm-slim` → 200; `lukemathwalker/cargo-chef/tags/latest-rust-1` → exists, `last_updated: 2026-09-19`. Every `FROM` input in the recommendation resolves.
5. Adopter-star checks: `qdrant/qdrant` 34,736 stars pushed 2026-09-21; `LemmyNet/lemmy` 14,605 pushed 2026-09-21; `meilisearch/meilisearch` 59,363 pushed 2026-09-21. Adopter Dockerfiles fetched and grepped for `chef|FROM|HEALTHCHECK|USER` (Qdrant: chef + `debian:13-slim` + useradd + `USER`, no HEALTHCHECK; Lemmy: chef-ARG + `debian:sid-slim` + curl-for-healthchecks + useradd + `USER`, no HEALTHCHECK; Meilisearch: no chef, alpine, root, no HEALTHCHECK).
6. hadolint v2.15.1 (`hadolint-macos-arm64` from GitHub releases; first fetch hit a wrong asset name `hadolint-Darwin-arm64` → 404, corrected after listing release assets) run against the exact recommended file staged at `/tmp/r51check/Dockerfile`: 3 findings, 0 errors — `DL3008 warning` (pin apt versions: accepted deviation — pinning Debian snapshot versions makes template builds brittle on point-release turnover; Qdrant/Lemmy do not pin), `DL3066 info` (non-numeric `USER app`: accepted — matches py `USER app` and the Qdrant/Lemmy/Depot idiom), `DL3025 warning` on the `HEALTHCHECK` line (JSON/exec notation suggested: rejected with ground — shell form is required for `${PORT:-8080}` expansion and `|| exit 1`, and is Docker's documented healthcheck idiom). Exit code 1 solely from these triaged findings.

Planned checks (specified, NOT executed — no Docker daemon accessible: `docker info` fails with `permission denied ... unix:///Users/stevemorin/.docker/run/docker.sock`, socket present but no Docker processes running; starting Docker Desktop + multi-GB pulls was judged out of scope for a research leg):

P1. Cold `docker build -t r51check <template-root>` succeeds. P2. Layer-cache proof: `touch` one file under the gated tree, rebuild, `cargo chef cook` step reports `CACHED`. P3. `docker inspect --format '{{.Config.User}}'` → `app`; `Healthcheck.Test` contains `/healthz`. P4. `docker run -d -p 8080:8080 r51check`; poll `docker inspect --format '{{.State.Health.Status}}'` to `healthy` within ~60s; `docker exec <c> id -u` → `10001`. P5. Negative control: run with the probe pointed at a closed port (override `--health-cmd`) → `unhealthy` after 3 retries. A stub-server variant (python one-liner standing in for the not-yet-implemented serve binary, staged at `/tmp/r51check/Dockerfile.test` + `stub-server.py`) lets P4 run before R69's binary exists. The empirical auditor must execute P1–P5 (or a subset with stated coverage) before acceptance; the hadolint + tag checks above do not substitute for them.

### Confidence & re-verify trigger

Confidence: high on all three ADOPTs (image, chef + debian-slim + non-root user, curl HEALTHCHECK with py's timings) — each rests on a py precedent, a primary-source authority, and current production practice. Known gaps (see Validation strategy): cargo-chef dependency-tree RUSTSEC applicability (#365/#366) unresolved; Chainguard runtimes not deeply surveyed; full build/run/impl checks P1–P5 unexecuted here. Re-verify if: cargo-chef goes 6 months without a release or a RUSTSEC names it/affects its tree; R69's published decision stops shipping a `web` build or renames the binary/feature (mechanical `Dockerfile` update); R80 renames the liveness path or R77 the port variable (mechanical probe-target update); R68 adopts image publishing with requirements beyond this file; top-Rust-service practice converges on distroless/Chainguard + orchestrator-only probes.

### Sources

Retrieved 2026-09-21 unless noted. Primary/tool sources: Docker Dockerfile reference (`https://docs.docker.com/reference/dockerfile/` — multi-stage, `USER`, `HEALTHCHECK` forms/defaults/example); GoogleContainerTools/distroless README (`.../distroless/main/README.md` — no shells/package managers, `*-debian13` line); cargo-chef README (`.../LukeMathWalker/cargo-chef/main/README.md` — recipe semantics, canonical 3-stage file, `debian:trixie-slim` runtime); cargo-chef issues #322 (flag parity), #350/#353/#355/#356/#359/#361/#363/#365/#366/#367 (responsiveness sample); crates.io `GET /api/v1/crates/cargo-chef` + `/versions`; `GET https://api.github.com/repos/LukeMathWalker/cargo-chef` + `/issues` + `/search/issues`; Docker Hub `lukemathwalker/cargo-chef` repository + tags endpoints and `library/debian` tags endpoint; OSV `v1/query`; rustsec.org 404; hadolint v2.15.1 release assets + lint run. Independent/practice sources: Depot `rust-dockerfile.mdx` (chef + cache mounts + sccache + `ubuntu:24.04` + useradd); Qdrant `Dockerfile`, Lemmy `docker/Dockerfile`, Meilisearch `Dockerfile` (raw.githubusercontent.com); small-project cache-mount leads (`scylla-ops/scylla`, `mcaney006/pack-plan`, `ultish/rakko` commits — leads only). Port sources: `docs/port/areas/packaging-distribution.md:21` (F223), `docs/port/areas/web-service.md:43,44` (F336, F337), `docs/port/COMMONALITY.md` F223/F336/F337 rows; `research/runs/R51/.../inputs/parameters.json` (assumes values); R69 revision 9 DECISION (consumed prerequisite) + revision 10 note (prose-only input); owner-reference C15 (`research/runs/R51/.../inputs/owner-reference-axum-companion-stack-2026-09-16.md` — chef/nonroot/musl-rejection agreed; distroless runtime differed with ground).
