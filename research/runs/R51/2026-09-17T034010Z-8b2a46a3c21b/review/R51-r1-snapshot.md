# 2026-09-18 — R51 — container-image (bundle, Focused) — decision (revision 1)

## Decision

**Status.** This decision is a **proposal to be validated in the implementation
phase** (owner ruling, 2026-09-10). `rs-launch-blueprint` has no `Dockerfile`, no
`crates/web` tree and no CI workflow today; P02 is research and P03 builds the
template. What is recorded here is what the research found and what it
recommends, together with the checks that were actually executed against a
disposable stand-in. A recommendation that does not survive implementation is
**revised against this recorded research**, not researched again from scratch.
`## Engines` lists what P03 must validate and what this run could not.

**The answer to the prompt's decision question.** `rs-launch-blueprint` **does**
ship a container image for its optional `web` build, and it ships it as a
**checked-in, CI-verified build recipe rather than as a published registry
artifact**: one `Dockerfile` and one `.dockerignore` at the repository root, one
`just` recipe, and one path-gated CI job in its own workflow file. Nothing is
pushed to any registry. That settles ledger rows **F223** (`docs/port/COMMONALITY.md:227`,
container image as a distribution artifact), **F336** (`:340`, non-root
multi-stage build) and **F337** (`:341`, the container's own liveness
healthcheck), all three `DIVERGENT` and all three this item's.

This answer is contingent, as the prompt says, on R69 adopting a web surface at
all. It has: R69 is `resolved`, and its accepted revision 10 declares the `web`
feature and the `rslbp-serve` binary the image runs.

### The recommendation — one stack

| # | Member | Selected | Pin | Why, in one line |
|---|---|---|---|---|
| 1 | Dependency-layer caching | **BuildKit `RUN --mount=type=cache`** | frontend `docker/dockerfile:1` | `cargo-chef` fails fitness gate 2; cache mounts are first-party, need no third-party tool, and are the mechanism py's own Dockerfile already uses |
| 2 | Builder base | **`rust:1.98.1-slim-trixie`** | `@sha256:ca5c572a3d4e8acfa44bc065aa6d9dafbee398bf14ec376d2bcf955820a4c9f3` | the Docker Official Image at current stable (1.98.1), rebuilt continuously; `-slim` needs no `apt` layer because nothing in this tree links a native library |
| 3 | Runtime base and identity | **`gcr.io/distroless/cc-debian13:nonroot`** | `@sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97` | glibc, loader, libgcc and CA certificates and nothing else; a built-in uid/gid 65532, so no mutable `useradd` step; the same Debian suite as the builder |
| 4 | Liveness healthcheck | **one static `busybox` applet + exec-form `HEALTHCHECK`** | `busybox:1.38.0-musl@sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37` | the smallest thing that restores py's principle to a shell-less base: **813,471 bytes** measured, no package manager, no change to any other item's decision |
| 5 | Build and publication channel | **checked-in recipe + one path-gated CI job in its own workflow file; no registry push** | — | it is what py actually does, it fixes what py does not do (verify it), and it publishes nothing that has a consumer |

The whole recommendation is one file. It is committed as a fixture at
`review/evidence/Dockerfile.candidate` and every check below was executed
against **that** file, not against a transcription of it:

```dockerfile
# syntax=docker/dockerfile:1
ARG PROBE_IMAGE=busybox:1.38.0-musl@sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37
ARG RUST_IMAGE=rust:1.98.1-slim-trixie@sha256:ca5c572a3d4e8acfa44bc065aa6d9dafbee398bf14ec376d2bcf955820a4c9f3
ARG RUNTIME_IMAGE=gcr.io/distroless/cc-debian13:nonroot@sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97

FROM ${PROBE_IMAGE} AS probe

FROM ${RUST_IMAGE} AS builder
WORKDIR /src
ENV CARGO_TERM_COLOR=never CARGO_INCREMENTAL=0
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,target=/src/target,sharing=locked \
    cargo build --release --locked --features web --bin rslbp-serve \
 && install -D -m 0755 target/release/rslbp-serve /out/rslbp-serve

FROM ${RUNTIME_IMAGE}
COPY --from=probe /bin/busybox /bin/busybox
COPY --from=builder /out/rslbp-serve /usr/local/bin/rslbp-serve
# Containers bind all interfaces; the in-code default stays loopback (R77).
ENV RSLBP_WEB_HOST=0.0.0.0
EXPOSE 8000
USER nonroot:nonroot
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/busybox","wget","--spider","-q","-T","2","http://127.0.0.1:8000/healthz"]
ENTRYPOINT ["/usr/local/bin/rslbp-serve"]
```

Six details in that file are load-bearing and each is asserted by a named check.

- **`install` inside the same `RUN`** (no check needed beyond `C1a`/`C2b`, which
  fail without it): `target/` is a cache mount, so nothing under it exists for a
  later `COPY --from=builder` to read. The binary must leave the mount inside
  the instruction that holds it.
- **`sharing=locked`** (`C15k`): two concurrent builds must not write one
  `target/`.
- **`/bin/busybox wget`, by absolute path** (`C15d`, `C8-*`): the copied applet
  brings no symlinks, and `wget` alone does not resolve in this runtime.
- **`-T 2` strictly inside `--timeout=3s`** (`C15e`, `C15f`): a slow endpoint then
  fails by busybox's own exit status rather than by being `SIGKILL`ed when the
  instruction's timeout expires. **This corrects the raw report**, whose executed
  image carried `-T 3` — equal to the instruction timeout, and therefore racing
  it — while its prose recommended `-T 2`. The image measured here carries `-T 2`.
- **`127.0.0.1`, not `localhost`** (`C2c`): no resolver is configured in this
  image. py chose the same literal for the same reason (`S15e`).
- **`ENV RSLBP_WEB_HOST=0.0.0.0`, and no `RSLBP_WEB_PORT`** (`C15g`, `C15h`,
  `C2e`): R77 revision 1 assigns exactly this line to this item and no other
  (`S10e`), and its port default of `8000` stays R77's to change. Restating the
  port in the image would fork R77's default into two places.

`.dockerignore` is three lines — `.git`, `target`, `**/target` — and
deliberately **not** `Cargo.lock`, which `--locked` needs in the build context
(`C15l`).

### Principles and implementation

**The shared requirement, its source, and the agreement level.** *An optional
web-service build must be runnable by someone who has neither the language
toolchain nor the project's dependency manager, in a form that does not run as
root and that reports its own liveness to whatever supervises it.* Source: py's
`Dockerfile` in full at pin `b08bccfb` (32 lines, read through the pin at
`S15a`–`S15h`), and the WEB-32 note at `docs/port/areas/web-service.md:43`
("lockfile-frozen, bytecode-compiled, dependency layer cached separately from
source"). ts contributes nothing: no container-related path exists anywhere in
that repository at pin `cb1cbcb2` (`S15k`, with `S15l` as the control that the
listing was not empty).

The agreement level is **capability**, not standard and not architectural
pattern. What must agree across the three repositories is that *the optional web
build is distributable as a container, that the container does not run as root,
and that the container declares its own liveness.* What may vary is every
mechanism, because each is bound to its language's build model. py's dependency
layer exists because `uv sync` can install dependencies without the project;
Rust has no such step, because compiling a dependency graph writes into the same
`target/` directory that holds the project's own artifacts. py's `urllib` probe
exists because its runtime base happens to contain a Python interpreter; a Rust
runtime base contains nothing at all.

**Essential behaviors, each observable, each measured.**

| # | Behavior | Observable as | Executed |
|---|---|---|---|
| B1 | The image runs the `web`-gated serve binary and nothing else | `docker image inspect` names it as the entrypoint; no shell resolves | `C2b`, `C14a`, `C8-sh`/`C8-bash`/`C8-curl`/`C8-wget` |
| B2 | The process is not root | `docker top` reports a non-zero UID for PID 1 | `C3a` (**uid 65532**) |
| B3 | The image reports its own liveness without an orchestrator | health status reaches `healthy` | `C3c`, `C3d`, `C3e`, `C3f` |
| B3′ | …and the probe actually **detects** a dead listener | health status reaches `unhealthy` after the configured retries | `C13a`, `C13b`, `C13c` |
| B4 | A rebuild after a source-only edit does not recompile the dependency graph | the build log's `Compiling` lines name only workspace crates | `C4a`, `C4b`, with `C5b` as the counterfactual |
| B5 | Every base is pinned by digest, so a base bump is a reviewable diff | every `FROM` resolves through an `ARG` carrying `@sha256:` | `C15a`, `C15b`, `C15c` |
| B6 | The build uses the release profile, so the shipped binary is the shipped binary | the build command is `cargo build --release --locked`, inheriting R68's `[profile.release]` | `C1a` |
| B7 | SIGTERM drains rather than kills | the stopped container's exit code is R67's SIGTERM integer | `C6a` (**143**), `C6b` |

**B3′ is new in this decision.** The raw report recorded the failure path as
"**Low-confidence and explicitly unproven** … no `unhealthy` transition was
observed in this run", and wrote that a healthcheck only ever observed passing
"is not known to detect anything". That gap is now closed by execution: started
with the server bound to a port the probe does not read, the container reaches
`unhealthy`, its `FailingStreak` reaches the configured retry count, and the
failing probe exits **1** — the reference's *unhealthy* code, not the reserved
**2**.

**Architectural alternatives, compared before any tool was chosen.** The choice
between these four whole shapes is prior to the choice of caching mechanism or
base image.

| Alternative | Shape | Verdict |
|---|---|---|
| **A. No container at all** | the `web` feature ships only as a `cargo install --features web` instruction | **Rejected.** It makes the optional surface unusable by anyone without a Rust toolchain, and F223/F336/F337 would all resolve to OMIT, which neither the `DIVERGENT` verdict nor py's precedent supports. It would also leave R68's own premise — "the web surface's delivery vehicle is R51's container image" (`S10h`) — with nothing behind it at all |
| **B. A checked-in, CI-verified Dockerfile; no registry publication** | one `Dockerfile` + `.dockerignore`, one `just` recipe, one path-gated CI job | **Selected.** See member 5 below |
| **C. B plus publication to GHCR on every release** | B, plus a follower job on release-please's tag that logs in and pushes `ghcr.io/<owner>/rs-launch-blueprint:<version>` | **Rejected on fit, not on cost.** Nobody deploys a template: the published image would be a web service with one demo resource, and every fork that wants an image wants *its own*. It also adds `packages: write` under R08's unresolved permission model and three or four third-party actions to pin under R20, for an artifact with no consumer |
| **D. A `docker-compose.yml` development stack** | B plus a compose file wiring the service and a database | **Rejected as out of scope.** The template has no database — R69 selects `axum` and `tokio` only — and a compose file with one service is a `docker run` line with extra syntax |

**How the recommended design preserves each principle, and where Rust needs a
different design from py.**

- *Dependency layer before source* (WEB-32). py's `uv sync --frozen
  --no-install-project` is an **installer** step: it materialises a virtualenv
  that does not depend on the project's own code, so Docker's ordinary layer
  cache preserves it. Rust has no installer step. The two mechanisms that recover
  the property are structurally different objects: `cargo-chef` *fabricates* a
  project skeleton so a dependency-only build can be a distinct image layer, and
  `RUN --mount=type=cache` *moves* `target/` and the cargo registry out of the
  layer graph entirely. Both preserve the principle; only the second needs no
  third party — and, a corroboration the raw report did not draw, **py's own
  Dockerfile already uses BuildKit cache mounts**, two of them, at `:10` and
  `:15` (`S15h`). Choosing cache mounts for Rust continues py's mechanism rather
  than departing from it.
- *Non-root* (F336). py creates a user because `python:3.12-slim-bookworm` ships
  none. `gcr.io/distroless/cc-debian13:nonroot` ships one: `id` inside it returns
  `uid=65532(nonroot) gid=65532(nonroot) groups=65532(nonroot)`, and so does
  `cc-debian12` (`C7-cc-debian13`, `C7-cc-debian12`). Rust therefore needs **no**
  `groupadd`/`useradd` layer — one fewer mutable step, one fewer thing to get
  wrong, and the same capability.
- *Self-declared liveness* (F337). py's `urllib` line is a workaround for the
  absence of `curl`. A Rust runtime base is *more* austere, not less: `sh`,
  `bash`, `curl` and `wget` are all absent from the selected runtime (`C8-*`),
  and `/bin/sh` is not merely missing from `PATH` but not executable at all
  (`C14a`). The principle survives only if something is added back, and the
  design adds the smallest thing that works — one statically linked multi-call
  binary, measured at **813,471 B**, **7.1 %** of the image (`C9a`) — rather
  than an `apt` layer.
- *Same binary as the release* (B6, R68). py's image installs the same wheel the
  release publishes. The Rust analogue is that the image build must be a plain
  `cargo build --release --locked`, inheriting R68's `[profile.release] lto =
  "fat"`, `codegen-units = 1` with `strip` left at its `"none"` default. This has
  a cost the design accepts rather than overrides: the fat-LTO link dominates the
  incremental rebuild and no caching strategy removes it.

**Maintained reference implementations.** `atuinsh/atuin` is the closest
maintained composition of the same triple — a Rust HTTP server, a created
non-root `USER`, and a `HEALTHCHECK` on `/healthz` — and the raw report read its
`Dockerfile` at its default branch on 2026-09-18. This design differs from it in
three places, each on ground stated in the member that owns it: digest-pinning
every `FROM` (atuin pins its chef image by digest but its runtime by a dated
tag), a distroless runtime rather than `debian-slim` + `curl` (measured:
12,312,852 B against 40,163,283 B, `C9b`), and cache mounts rather than
`cargo-chef` (gate 2, plus no third-party tool). `astral-sh/uv` composes cache
mounts with a digest-pinned builder and a contents-minimal final stage. Neither
composes all five selections, which is why the composite built here is the
primary compatibility evidence and the adopters are the corroboration.

#### Member 1 — dependency-layer caching

**Dominant choice: `cargo-chef` 0.1.78**, by adoption. `recent_downloads`
**997,338**, `downloads` **4,249,535**, newest non-yanked **0.1.78** published
**2026-08-12** out of 78 live versions (`D5a`–`D5e`, `GET
https://crates.io/api/v1/crates/cargo-chef` and `/versions`, retrieved
2026-09-19T01:22Z). Two of the four Rust Dockerfiles the raw report surveyed use
it, and both are the web servers — so its adoption is real and concentrated in
exactly this item's use case.

**Excluded by fitness gate 2.** `cargo-chef`'s `[package]` table declares **no
`rust-version` key**. Read at the tag rather than from a package summary: the
manifest at `v0.1.78` is 1,170 bytes and contains **0** `rust-version` keys and
**1** `edition` key, `edition = "2018"` (`G1a`–`G1d`, keyring-authenticated
`gh api "repos/LukeMathWalker/cargo-chef/contents/Cargo.toml?ref=v0.1.78"`,
2026-09-19T01:23:47Z). crates.io agrees: `rust_version` is `null` (`D5b`). The
`edition` count is the positive control that keeps the `rust-version` zero from
being a failed read.

Gate 2 requires the candidate to be within *stable minus 2 minor versions,
raised only in a minor release, declared as rust-version in Cargo.toml and
tested in CI*. The owner settled how an undeclared version is read, and settled
it **against** the lenient reading: `docs/planning/p02/execution-ledger.md:414`
(`S12c`) — "RULING WITHDRAWN: fitness gate 2 is read strictly. … an unknown
effective version is not evidence of incompatibility, as I said, but it is
insufficient evidence to PASS a gate the prompt says must be passed." R69
revision 10 applied the same reading to `watchexec-cli` 2.7.2, a
contributor-installed tool that is likewise not linked into the artifact.

**The strongest argument the other way is recorded rather than buried.**
`cargo-chef` would be consumed here in a form weaker than `watchexec-cli`'s: not
`cargo install`ed on a contributor's machine but pulled as a prebuilt
`lukemathwalker/cargo-chef@sha256:…` layer and run inside a builder stage. It
would never be compiled by this template on any OS in `target-os-matrix`, ever,
so a gate understood as "the template must be able to build this under its own
floor" is vacuous for it. **This decision applies the rule in force and excludes
the candidate**, and hands the general question to the owner as a re-verify
trigger, exactly as R69 revision 10 does.

Two things keep that exclusion from carrying the member on its own. First, the
maintenance signal is independent of the gate: of the ten most recently created
items on the repository, six are issues and **all six carry `comments: 0`**,
spanning 2026-06-05 to 2026-09-10, two of them the repository's own RustSec bot
notices about its dependency tree (`G2a`–`G2c`, 2026-09-19T01:24:08Z). Median
days to first maintainer response is therefore **undefined — there were no
responses**; unanswered **6 of 6**, on a sample of **6, not the rubric's 10**,
because the other four recent items are pull requests. Maintenance state by the
rubric: **at-risk**, on that concrete signal rather than on a release gap — the
release cadence is current (**35** open issues, `G3a`). Second, cargo-chef's one
*unique* benefit over cache mounts — an exportable dependency **layer** — is
realisable only with a registry or GHA layer cache that member 5's build-only,
no-publication job does not configure and should not.

*Gate ledger for `cargo-chef`, stated in full rather than abbreviated:* gate 1
**inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not
evaluated for any dependency or tool** (`S4a`; the declared `Apache-2.0 OR MIT`
is recorded as a fact, not weighed); gate 2 **FAIL**, no `rust-version`
declared; gate 3 **pass** — no open RustSec advisory (`https://rustsec.org/packages/cargo-chef.html`
returns **404** where the `atty` control returns **200**, `D6a`/`D6b`), `unsafe`
posture not audited and not reachable from the shipped process; gate 4 **pass in
substance** — it runs in a Linux builder stage and its host OS is not a template
constraint; gate 5 **pass** — no default-feature or async-runtime coupling
reaches the template; gate 6 **pass** — zero bytes in the shipped image, and it
reduces rather than adds compile time.

**Selected: two cache mounts on the single build `RUN`, both `sharing=locked`.**
The BuildKit Dockerfile frontend's own reference at tag `v0.26.1` states the
contract the design relies on: "Contents of the cache directories persists
between builder invocations without invalidating the instruction cache. … Your
build should work with any contents of the cache directory as another build may
overwrite the files or GC may clean it if more storage space is needed." Two
consequences follow and are the whole comparison: a cache mount is
**builder-local** and is exported by no layer-cache backend, and a build must be
correct with the cache empty. `ENV CARGO_INCREMENTAL=0` is set in the builder
because incremental artifacts are useless in a release build and only grow the
cache.

Measured on the stand-in (`linux/arm64`, Docker Desktop 29.5.2, 2026-09-19):
appending one line to `crates/web/src/lib.rs` and rebuilding recompiled **only**
the two affected workspace crates — **0** third-party crates (`C4b`) — in **15 s**
of wall time. With the two mount lines deleted, the identical edit recompiled
**50** third-party crates (`C5b`) in **28 s** (`C5c`). Fifty is the whole
dependency graph: `cargo generate-lockfile` reported "Locking 54 packages to
latest Rust 1.96 compatible versions", of which four are the workspace's own
members. The **direction** is the reproducible result; the seconds are not, and
`## Empirical check` states the comparison rule.

**Ranked runner-up: `cargo-chef` 0.1.78, pinned as the builder image by digest**
— `atuinsh/atuin`'s exact shape. It wins immediately if any of three things
becomes true: the owner rules that gate 2 does not reach non-linked tools *and*
the maintenance signal reverses; or the template starts publishing images
(alternative C), which creates the persistent cache that makes an exportable
dependency layer worth having; or the dependency graph grows enough that the
cold CI build becomes the binding constraint. Second runner-up: **no caching at
all**, `meilisearch`'s shape, which is correct if the image is built once a month
and the difference measured here never matters.

**Up-and-comer, recorded and not recommended:**
`reproducible-containers/buildkit-cache-dance`, a GitHub Action that extracts a
cache mount's contents after a build and re-injects them before the next, so
cache mounts survive a fresh runner. It is the missing half of the selected
option in CI. It adds a third-party action to pin under R20 and two steps to a
job that runs only on web-touching pull requests; it is the successor if that
job's cold-build time ever becomes a complaint.

#### Member 2 — builder stage base image

**`rust:1.98.1-slim-trixie`, pinned by digest.** Crate figures are
**inapplicable — a container image is not a crates.io package and has no
`recent_downloads`, `downloads`, `versions` or RustSec page**; the registry
equivalents are read instead. Current stable is **1.98.1 (48a229cea
2026-09-01)** on channel date **2026-09-03** (`D4a`, `D4b`,
`https://static.rust-lang.org/dist/channel-rust-stable.toml`), so `msrv-policy`'s
"stable minus 2 minor versions" puts the floor at **1.96** and this image clears
it. Maintenance state **active**: the tag was republished 2026-09-18T19:46Z,
the day before this check.

**The suite trap, verified rather than asserted.** `rust:1.98.1-slim` and
`rust:1.98.1-slim-trixie` now carry the **same** digest, while
`rust:1.98.1-slim-bookworm` is a different one (`D1a`, `D1b`, `D1c`). Anyone
carrying `rust:<ver>-slim` forward from an older file has silently changed Debian
suites. The digest in the `ARG` is what makes that visible in review.

The builder needs `cargo`, `rustc` and a linker and nothing else — no
`pkg-config`, no `libssl-dev`, because R05's selected HTTP client is `ureq` with
`rustls` and R69's web stack is `axum` + `tokio` with no native-TLS dependency.
`-slim` is therefore sufficient **with no `apt-get` layer at all**, which is a
genuine simplification over `atuinsh/atuin`, whose builder installs
`build-essential libssl-dev pkg-config`. The cost of `-slim` is that it becomes
wrong the moment a crate needs a native library, at which point the full
`rust:<ver>` image is cheaper than an `apt` layer.

**No candidate in this member fails a gate**; the differences are fit.
Runner-up: `rust:1.98.1-slim-bookworm@sha256:8d50cf1c…` paired with
`cc-debian12`, which is the owner reference's implied pairing and works — it is
second only because Debian 13 is the current stable suite and `rust:<ver>-slim`
already points at it. Second runner-up, and a different architecture rather than
a different image: the alpine/musl builder, which belongs to member 3's rejected
alternatives. `cargo-zigbuild` images, which let a newer toolchain target an
older glibc explicitly, are recorded as an up-and-comer and not recommended: a
third-party toolchain in the hottest path of the build, for a constraint `C12a`
shows is not currently binding. Chainguard's Rust builder was **not** evaluated
— see `## Engines`.

#### Member 3 — runtime stage base image and non-root identity

**`gcr.io/distroless/cc-debian13:nonroot`, pinned by digest.** Crate figures
**inapplicable — an OCI image has no crates.io record**; RustSec **inapplicable**
— an image has no advisory page, and the Debian CVE stream, which is the
relevant feed, is not a RustSec input. Registry state: the `:nonroot` tag is a
multi-architecture OCI index at
`sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97`
(`D3a`, `D3b`, `HEAD https://gcr.io/v2/distroless/cc-debian13/manifests/nonroot`
with an OCI-index `Accept` header, 2026-09-19T01:22Z), and the repository
publishes **6,044** tags including `latest`, `nonroot`, `debug` and
`debug-nonroot` (`D3c`, `D3-*`). Maintenance state **active**.

**That the `cc-debian13` line exists at all is the single fact that moves this
member away from the owner reference's `cc-debian12`**, so it is read from the
registry rather than assumed.

A second principle, not in the ledger rows but implied by all of them, is
**minimum content**: an image carrying a package manager, a shell and a C
toolchain is an image whose CVE surface is mostly things the service never
executes. This is where Rust differs most sharply from Python. A Python runtime
image *must* contain an interpreter and a standard library; a Rust runtime image
needs a dynamic loader, libc, libgcc and CA certificates. `cc-debian13` is
exactly that set, and it also sets `SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt`
in the image config (`C2f`), which matters the moment a fork's handler makes an
outbound HTTPS call through R05's `ureq` + `rustls`.

**Measured comparison, three variants built from the same workspace.**

| Runtime | Image size | Delta | Runs non-root | Reaches `healthy` |
|---|---|---|---|---|
| `cc-debian13:nonroot` + busybox probe (**selected**) | **12,312,852 B** | — | uid **65532** (`C3a`) | yes (`C3c`) |
| `cc-debian13:nonroot`, no probe, no `HEALTHCHECK` | **11,499,381 B** | −813,471 B (`C9a`) | uid 65532 | n/a — no probe |
| `debian:trixie-slim` + `curl` + `ca-certificates` + `useradd` | **40,163,283 B** | **+226 %** (`C9b`) | uid **999** (`C10b`) | yes (`C10a`) |

Both variants run non-root and both reach `healthy`, so this is a comparison of
**cost, not of capability**, and the `debian-slim` alternative is priced rather
than disqualified. It is rejected on the measured size and on the surface it
adds: the selected runtime has no `sh`, `bash`, `curl` or `wget` at all
(`C8-*`, `C14a`), and the slim alternative reintroduces all of them plus `apt`
and a package database. `alpine`/musl/`scratch` is rejected on the ground the
owner reference itself states — "musl DNS/TLS quirks; alpine libc perf" — and on
the build-complexity cost of adding a musl target, neither of which this run
measured; that is carried as the reference's claim, not as this item's finding.

**The glibc pairing is the one place members 2 and 3 could silently disagree, so
it was checked.** The built binary's highest required versioned symbol is
**GLIBC_2.34** (`C11a`) and the runtime carries **GNU C Library (Debian GLIBC
2.41-12+deb13u4) … 2.41** (`C11b`) — the same Debian build as the builder, with
seven minors of headroom. `C12a` then falsified the obvious worry by building the
trixie binary onto `cc-debian12` and running it: it **worked**, because nothing
in `std` + `axum` + `tokio` reaches past 2.34. **The suite-matching rule is
therefore a structural guarantee against a future dependency that does reach
further, not a fix for an observed failure**, and it is stated here at that
strength and nowhere stronger.

Distroless's honest cost is debuggability: `docker exec <c> sh` does not work,
and the answer is to redeploy the `:debug-nonroot` tag. Its second cost is that
the runtime cannot run an entrypoint *script*, so every startup concern must live
in the binary — which R69's `serve_until`/`shutdown_signal` design already
assumes. **Runner-up:** `cc-debian12:nonroot` with the bookworm builder, the
owner reference's pairing, fully supported and shown to work even across suites.
**Second runner-up:** `debian:trixie-slim` + `useradd`, which becomes correct the
moment a fork needs a shell in the image.

`USER nonroot:nonroot` is written explicitly even though the `:nonroot` tag
already sets it (`C15j`, `C2a`), for the same reason R68 writes
`[profile.release]` keys that match Cargo's defaults: a reader should not have to
know the tag's convention, and a fork that changes the base tag then gets a
visible contradiction rather than a silent escalation to root.

#### Member 4 — the container's own liveness healthcheck

**Who consumes the instruction, stated exactly.** The Dockerfile reference is
explicit that `HEALTHCHECK` is a Docker Engine concept — "The `HEALTHCHECK`
instruction tells **Docker** how to test a container to check that it's still
working" — and Kubernetes does not consult it: the `pod-lifecycle` page defines
liveness, readiness and startup probes entirely within the Pod spec. So the
instruction's consumers are Docker Engine, Compose and Swarm, and its value
inside a cluster is zero. That is an argument for **modesty** about the feature,
not for omitting it: the template's own contributors and any fork's `docker run`
or `docker compose up` are exactly those consumers, and F337 records the
capability as one the source repository has. The README must say so.

**The exit-code contract decides the command's form.** The reference states it as
"0: success … 1: unhealthy … 2: reserved - don't use this exit code", and offers
either a shell command or an exec array. With no shell in the image the exec
array is the *only* available form, and py's trailing `|| exit 1` is both
unavailable and unnecessary — `busybox wget` already exits 1 on failure, which
`C13c` measured rather than assumed.

**The timings are a justified carry, not a copy.** Defaults per the reference are
`--interval=30s --timeout=30s --start-period=0s --retries=3`. py sets
`--interval=30s --timeout=3s --start-period=5s --retries=3` (`S15d`), three
deviations from the defaults, and all three are right for a loopback probe
against a service that takes a moment to bind. This design carries all four
values (`C2c`).

**Options compared.**

| Option | Mechanism | Cost | Verdict |
|---|---|---|---|
| **A. Static `busybox` copied from a pinned image** | `COPY --from=probe /bin/busybox /bin/busybox` plus an exec-form `HEALTHCHECK` | **+813,471 B**, +7.1 %; one more digest to keep fresh | **Selected** |
| **B. `debian-slim` runtime with `curl`** | atuin's and py's shape | **+27,850,431 B** over A; adds `apt`, a shell, a package database | Rejected on measured size and surface; verified working (`C10a`), so priced, not disqualified |
| **C. A `--health-check` flag or subcommand on the serve binary** | the most idiomatic Rust answer — the binary already has an HTTP stack | **zero** bytes | **Rejected without raising a `CONFLICT:`** — see below |
| **D. A second, purpose-built probe binary in the workspace** | a tiny HTTP GET | zero third-party images | Rejected on two owned-parameter collisions: R49's `build-tool-output-shape` says "Binary target: exactly one … `autobins = false`", and R69 adds exactly one more |
| **E. No `HEALTHCHECK` at all** | `meilisearch`, `lemmy` and `uv` all ship none | zero | Rejected: F337 records the capability and nothing in the Rust ecosystem makes it infeasible |

**Why option C is rejected rather than raised as a `CONFLICT:`, and why this
decision keeps that line unraised.** A `CONFLICT:` line is for a consumed value
the recommendation *genuinely needs* changed. This recommendation does not need
it. R69's accepted revision 10 still says the `rslbp-serve` binary carries the
org CLI Design Standard's required global core "and nothing beyond it" — verified
at the owned line itself (`S10c`), not carried from the raw report — and option A
supplies the same capability for 813,471 bytes with no change to any other item's
decision. Option C would be cheaper in bytes and cleaner in spirit: the process
that owns the port is the process best able to say whether it is listening. So
the trade is recorded here for the owner to see rather than to discover later,
together with the exact line R51 would raise if the owner preferred to spend a
CLI-surface exception instead of 0.78 MB:
`CONFLICT: R69 web-extra-surface — the rslbp-serve binary additionally accepts a hidden --health-check flag that performs one loopback GET against the liveness path and exits 0 or 1 — reason: it removes the only non-Rust binary from the runtime image`.
**This decision does not raise that line.**

**No option in this member is excluded by a fitness gate**: gates 1–3 are
inapplicable to Dockerfile constructs and prebuilt image contents, gate 4
resolves as members 2 and 3 do, gate 5 finds no feature or async-runtime
coupling, and gate 6's cost is measured above for every option. Options C and D
are excluded by **owned-parameter collisions**, which is a different kind of
exclusion and is labelled as such.

Busybox's honest cost is that it puts a general-purpose multi-call binary into an
image chosen for having nothing in it: `busybox sh` is inside that binary and is
now reachable by anyone who can already execute in the container. The counter is
that the applet is invoked by absolute path from a pinned digest, and that option
B ships a *real* shell plus `apt`. A fork that finds even this too much has
option E documented and one instruction to delete.

**The probed path and port, and the one operational cost of a shell-less
image.** The path is `/healthz`, R80's liveness route. The port is `8000`,
R77's default for `RSLBP_WEB_PORT`. Because the runtime has no shell, the
`HEALTHCHECK` cannot expand a variable the way `atuinsh/atuin`'s shell-form probe
expands `${ATUIN_PORT:-8888}`: the exec array must carry a literal. **A fork that
changes `RSLBP_WEB_PORT` must therefore edit the `HEALTHCHECK` line too**, or
run with `--no-healthcheck`. That is a real cost of the minimum-content choice
and the README must state it.

#### Member 5 — build and publication channel

**Two principles compete and both are real.** *Distributability* (F223): an
artifact nobody can obtain is not a distribution artifact. *Verifiability*
(implied by every guard item in this programme): a recipe nobody builds rots
silently.

**The evidence settles them in the opposite direction from where the F223 row's
wording points, and that is recorded as a fact rather than as a challenge.** py,
at pin `b08bccfb`, **publishes nothing**: a search of everything under `.github`
for `ghcr.io`, `docker build`, `docker/build-push`, `buildx`, `docker/login` or
`docker push` returns no match (`S15i`), and the only thing that builds the image
is a Justfile recipe, `docker build -t {{tag}} .` (`S15j`, the control that keeps
`S15i`'s no-match from being a broken search). So py's precedent is **a
checked-in recipe built on demand, never published and never verified in CI** —
not a published distribution artifact — and it simultaneously exhibits the defect
that a recipe with no build gate acquires. The F223 row's Notes overstate what
the pinned source does. **No `BASELINE-REVIEW:` line is raised for it**: F223,
F336 and F337 are all `DIVERGENT` rows and none appears in
`docs/port/BASELINE-REVIEW.md` (`S7-F223`, `S7-F336`, `S7-F337`, with `S7e` — F017
does appear there — as the control), and the process reserves that line for
`COMMON → REUSE` and `ADOPT` rows. The one baseline this item touches, F017, is
recorded `retained` and this design does not contest it.

**The decisive fit argument for not publishing is what the artifact would be.**
R68 publishes cross-compiled `rslbp` binaries because someone genuinely wants to
run the CLI. Nobody wants to run *the template's* web service: it serves one demo
resource. A fork wants an image of **its own** code, which it gets by building
this Dockerfile after renaming the package.

**Where the CI job goes — this is a correction to the raw report.** The raw
report left the placement to R11 and described "one path-gated CI job". R11's
accepted revision 1 has since published `ci-job-structure`, and it answers the
question directly: "**No container or deploy job enters `ci.yml`**; R51 owns the
image and R68 owns the release workflow" (`S10g`). R11's own rule for a check
that needs a different toolchain and a `target/` it must not share is that it
becomes its own job, and its R44 row spells out the placement for a check that
compiles no Rust into *this* repository's `target/`: its own job in its own
workflow file. A Docker build compiles Rust inside the builder container, claims
no `actions/cache` entry, and must not share the `check` job's cache key. So the
recommendation is **one job in its own workflow file on `ubuntu-latest`**,
building `linux/amd64` — the single Linux triple R68's `targets` already names —
path-gated on `crates/web/**`, `Dockerfile` and `.dockerignore`, exactly the
shape R17 already ships for `.github/workflows/secret-scan.yml` (`S11d`).

The job runs `DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t
rslbp-serve:ci .` and then asserts the four behaviors that make the image correct
rather than merely buildable: non-root PID 1, `healthy` status, a 200 from the
liveness path, and exit **143** after `docker stop`. It does **not** log in to a
registry, does **not** push, and adds **no** third-party action and **no**
workflow permission. `DOCKER_BUILDKIT=1` is written explicitly even though modern
Docker Engine defaults to BuildKit, because the `# syntax` directive and
`--mount=type=cache` fail silently without it and a runner image is not something
this template controls.

**Whether that workflow is a required status is R12's**, not this item's: R11
records that a workflow skipped by trigger-level path filtering leaves its checks
`Pending` and blocks merging, while a job skipped by a conditional reports
`Success`. If R12 makes this check required, the gating must be a job-level
conditional rather than a trigger-level `paths:` filter. That is stated as a
**requirement on R12's answer**, not decided here.

**Ranked runner-up: option C, GHCR publication on release**, which becomes
correct the moment the template stops being a template — that is, for the first
fork — and is also right earlier if the owner decides a published image is itself
documentation. This is the member most likely to be overruled, and it is stated
so. **Second runner-up: option F**, py's own shape (recipe, no CI gate), which is
what this reduces to if a container job proves impractical. Build attestation and
provenance (`--provenance`, `--sbom`, cosign signing) are recorded as the
up-and-comer and not recommended for a structural reason rather than a fitness
one: they attach to a *published* artifact, and this option publishes nothing.

### Conformance with the REST API Design Standard v2.0.0

Owner ruling **W2-REST** (2026-09-18, `docs/port/OWNER-REVIEW.md`, `S12b`) binds
the org REST API Design Standard v2.0.0 — `/Users/stevemorin/c/rest-standards/rest-api-standard.md`,
commit `0850d43e45d919ef5e37f7174c4212b46013c49f`, blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, verified by hashing the file (`S8a`)
— to the template's HTTP surface. This item does not design an endpoint, but the
container **hosts** that surface, so the rules that reach a deployment artifact
are answered here, at their lines.

| Rule | Line | Strength | What it requires | The image |
|---|---|---|---|---|
| R8.1 | 1317 | MUST | "APIs MUST be served only over TLS 1.2 or higher, preferring 1.3; SSL 2/3 and TLS 1.0/1.1 MUST be rejected" | **`OVERRIDE (OV-14)`** — the image terminates no TLS and serves cleartext HTTP on the port it exposes |
| R8.2 | 1323 | MUST | access tokens MUST NOT travel in URI query parameters | **CONFORMS, and the image is the reason it is easy to keep** — the only request the image itself issues is the loopback liveness probe, which carries no credential at all; R56's `RSLBP_TOKEN` reaches the process as an environment variable, which is exactly how a container supplies one |
| R8.3–R8.5 | 1329–1351 | MUST/SHOULD | the authentication mechanism, OAuth hygiene, credential scoping | **N/A to this item** — the image selects no mechanism and mints no credential. R69 owns the surface; the rows belong to whichever item introduces authentication |
| R8.10 | 1387 | MUST | each of five deployment-profile axes MUST take its ratified default unless a named trigger applies, and any flip MUST be recorded in the conformance note | **N/A with reason** — sender-constrained tokens, token format, rate-limit aggressiveness, replay window and object-level authorization are all properties of the running API, and the image configures none of them. It flips no axis, so it has nothing to record. R74 owns rate limiting; the token axes belong to whichever item introduces authentication |
| R1.7 | 1271 | MUST | no silent deviation; a MUST deviation is nonconformance unless recorded as an approved exception | **CONFORMS** — `OVERRIDE (OV-14)` below is that record, and it is *requested, not granted*, until the owner rules |

**The standard names no health, liveness, readiness, container or port rule
anywhere.** **0** numbered rules match `health|liveness|readiness|container|healthcheck`,
where the same pattern finds **139** numbered rules in total, so the zero is a
fact about the standard rather than a failed search (`S8f`, `S8g`). R80 revision
2 reached the same conclusion for the probe endpoints. This item therefore judges
the image by the general rules above and invents no ops carve-out.

**One row is handed on rather than answered.** R8.6 (line 1356) requires every
request to be authorized against the specific object. The liveness request this
image issues is unauthenticated by design, and whether an unauthenticated ops
route is a deviation from R8.6 is **R80's** question, not this item's — the image
merely calls whatever route R80 defines. R80 revision 2's conformance note does
not list R8.6, so the row is named here as an open hand-off rather than treated
as settled.

#### `OVERRIDE (OV-14)` — the container serves cleartext HTTP and terminates no TLS

**Numbering — allocated, not searched.** Override numbers are no longer chosen
by the writer. Two syntheses collided on `OV-04` on 2026-09-18 by each searching
for the next free number concurrently, so **the controller now allocates the
number and ledgers the allocation**, and it allocated **`OV-14`** to this item.
Gaps in the sequence are expected and are not evidence of a missing override.
The scan this decision runs is therefore no longer a claim to a free number but
a collision check on an allocated one: `OV-14` appears in no published decision
and in no port record (`S9a`), while `OV-01` (R60's CLI-standard waiver,
requested 2026-09-12 and **refused** by the owner 2026-09-14, retired-as-refused
rather than deleted), `OV-02` (R61), `OV-03` (R02) and `OV-04` (R80 revision 2,
for its unversioned probe paths) are all found by that same scan, which is the
control that keeps `S9a`'s zero from being a failed search (`S9-01`…`S9-04`,
`S9b`).

**This is an `OVERRIDE (OV-nn)` in the AGENTS.md sense** — a departure argued
with options, recorded in the shape of the standard's own §1.9 deviation note —
and **not** the ledger verdict `COMMON → OVERRIDE (OV-nn)`, which is legal only
for origin `same`. F223's, F336's and F337's verdicts stay `DIVERGENT` and no
ledger file changes.

**Argument.** R8.1 is a **MUST** with no tier scope and no applicability switch,
and the standard grants it no edge-termination exemption anywhere. That is a
claim about the text and it is checked rather than asserted: **0** lines in §8
carry any form of the word *terminat* (`S8h`), and the five occurrences
elsewhere in the document are about something else — R5.12's carve-out at line
1019 for "reverse proxies, CDNs, WAFs, rate limiters, load balancers terminating
**before application code**", which governs the media type of *error responses*
rather than transport, and four lines in §13 about *stream* termination. **The
first of those five cuts slightly against this override and is recorded rather
than omitted**: R5.12 shows the standard does contemplate a proxy in front of
the application. What it does not do is exempt the origin behind that proxy from
R8.1, which is stated as a transport requirement on the API with no mention of
where TLS is terminated. So there is no textual basis for reading "served over
TLS" as satisfied by an ingress, and the deviation is real. The image as shipped
listens for
plaintext HTTP on the port it exposes, binds `0.0.0.0` (which R77 assigns to this
item precisely so a container is reachable), and probes itself over `http://` on
loopback. Someone who runs `docker run -p 8000:8000` on a public host is serving
the API in cleartext.

The deviation is nonetheless the right engineering answer, for three reasons
stated as claims rather than assumed. **(1)** The template ships no certificate,
no key and no ACME client, and acquiring any of them is a deployment concern that
a template cannot make for its forks. **(2)** Terminating TLS inside
`rslbp-serve` would require a TLS listener and its configuration surface on a
binary that R69's accepted value says carries the required global core "and
nothing beyond it" (`S10c`), so that path is a `CONFLICT:` against another item's
owned parameter, not a free choice. **(3)** Every deployment target a container
image is aimed at — Kubernetes ingress, a reverse proxy, Cloud Run, a load
balancer — terminates TLS in front of the container as its normal mode, which is
why the owner reference's own Variant A Dockerfile also exposes cleartext. The
cost of the deviation is real and is stated: an operator who exposes this
container directly to the internet gets a cleartext API and nothing in the image
warns them, which is why the README paragraph below is part of the
recommendation rather than a nicety.

**Options.**

| | Option | Effect | Conformance |
|---|---|---|---|
| a | **Recommended.** The image stays cleartext; the README states in terms that the container is an **origin server** that MUST sit behind a TLS-terminating ingress, and that exposing it directly is nonconformant with R8.1; the owner records `OV-14` as approved | zero bytes, zero dependencies, matches every mainstream deployment shape and the owner reference's own container | Deviates from one MUST, recorded and approved per R1.7 |
| b | Terminate TLS inside `rslbp-serve` with `rustls` | fully conformant with no external component | Requires certificate paths, a key, a reload story and at least two new environment variables on a binary R69 says carries nothing beyond the required global core — so it is a `CONFLICT:` against `web-extra-surface`, which this recommendation does not need and does not raise |
| c | Ship a TLS-terminating sidecar or a second stage (nginx, Caddy) in the same image | conformant without touching the Rust binary | Contradicts member 3's minimum-content principle outright, multiplies the image by an order of magnitude, and puts a second network-facing daemon in a template that has one |
| d | Declare the surface `internal` tier and argue that R8.1 relaxes | no change to the artifact | Rejected on the standard's own text: §1.7 says "Every rule in this standard applies at every tier unless the rule itself states a tier scope", and R8.1 states none |

**What settles it.** The owner records `OV-14` as approved, or selects (b), (c)
or (d). Until then the deviation is **requested, not granted**, exactly as
`OV-01` was recorded before its refusal.

#### Conformance note — the rows this item creates

Recorded in the standard's own §1.9 template, and **provisional**: this item owns
no endpoint, so the tier, the switches and the rest of the deviation list belong
to the template as a whole. R69 owns the surface; R80's rows are already written;
R70 to R76 each add their own.

```markdown
## Conformance note — rs-launch-blueprint optional web surface (R51 rows only)

Standard: rest-api-standard v2.0.0
Tier: internal
Switches: webhooks=off, async-operations=off,
  bulk-operations=off, streaming=off
  (declared by R80; this item adds no switch and flips none)
Context: the deployment artifact is a container image that hosts the surface.
  It terminates no TLS, mints no credential, and configures none of the five
  §8.3 deployment-profile axes. It is an origin server intended to run behind
  a TLS-terminating ingress.

Deviations:
- OV-14 · MUST (R8.1) · the image serves cleartext HTTP on its exposed port and
  its own HEALTHCHECK probes http:// on loopback · the template ships no
  certificate material and TLS termination is a deployment concern a template
  cannot decide for its forks; terminating inside the binary would conflict with
  R69's "nothing beyond it" serve-binary surface · approver: PENDING OWNER ·
  date: PENDING

N/A declarations:
- R8.3, R8.4, R8.5 · the image selects no authentication mechanism and mints no
  credential
- R8.10 (all five axes) · every axis is a property of the running API; the image
  configures none and therefore flips none
- R8.6 · the only request the image issues is an unauthenticated liveness probe;
  whether that route may be unauthenticated is R80's row, not this item's
```

### What this decision does not decide

Each of these is a coupling stated at the strength the evidence supports.

- **The liveness endpoint's own behavior** is R80's (F328), as the prompt's
  `## Out of scope` says. This item decides only that the `HEALTHCHECK` probes
  it. R80 revision 2 resolves the path to `/healthz`; if it moves, this
  `HEALTHCHECK` line moves with it.
- **The port and host variable names and defaults** are R77's. This decision
  reads `RSLBP_WEB_HOST` and the `8000` default from R77's accepted revision 1
  (`S10e`, `S10f`) and restates neither.
- **Where the CI job is declared** is R11's and **whether it is required** is
  R12's, as set out in member 5.
- **The `docker` Dependabot ecosystem** is R19's. Its published F053 row records
  the `docker` and `devcontainers` ecosystems as "conditional on R51 and R44
  shipping those files" (`S11a`). **This recommendation ships them, so R19's
  condition is met and a third `package-ecosystem: "docker"` entry becomes due.**
  That is the mechanism that keeps the three digest pins fresh, and it is why
  digest-pinning is affordable at all.
- **A `mold`/`lld` linker swap is adopted by nobody, and that is said rather than
  left implied.** R69 revision 10 hands `cargo-chef` and `mold` to R51 and R68.
  R68 records the linker as "**out of scope here**; the toolchain-file question is
  R27's and no `[profile.*]` key is involved". This item also declines it: a
  linker swap changes the release link, so applying it only inside a Dockerfile
  would make the container binary differ from the released one, against B6. **The
  hand-off therefore lands nowhere**, and if the owner wants `mold` it needs an
  item of its own or an addition to R27's scope.
- **The `linux/amd64` build.** Everything measured here is `linux/arm64`. P03
  must re-run all of it on `ubuntu-latest`.

**A coupling with R68 that must be stated rather than left implied.** R68 left
the `web`-gated binary out of its release archives on the premise that "the web
surface's delivery vehicle is R51's container image" (`S10h`). Under this
decision the image is a **recipe**, not a downloadable: no release archive
contains `rslbp-serve` and no registry serves an image, so nobody obtains a
runnable web artifact without a Docker daemon and a build. That is a deliberate
consequence of "a template's web service has no consumers but its forks", and it
is the right outcome if that premise holds. If the owner wants a downloadable web
artifact there are exactly two doors, and they belong to two different items:
**R51 takes option C** (publish to GHCR on release), or **R68 adds `features =
["web"]` to dist's build** so `rslbp-serve` ships beside `rslbp`. This is a
**hand-off to R68**, not a `CONFLICT:` line, because this recommendation needs no
value of R68's changed — it needs the owner to know which door to open.

re-verify: when R69 republishes `web-extra-surface` and the registry row moves from revision 9's `src/web/` bytes to revision 10's `crates/web` form (check `S10d` fails the moment it does, and the `- assumes` line and every path here must then be re-checked); when R80 publishes or moves the liveness path off `/healthz`; when R77 publishes and fixes `RSLBP_WEB_HOST`, `RSLBP_WEB_PORT` or the `8000` default, either of which changes the `HEALTHCHECK` literal and `EXPOSE`; when R11 publishes `ci-job-structure` or R12 decides whether the image job is a required status; when R19 adds the `docker` ecosystem, which is this item's own hand-off landing; when R08 publishes its permission model, which prices the publish-on-release alternative properly; when R68 publishes or changes `[profile.release]` or its follower-mode release flow; when the owner rules on `OVERRIDE (OV-14)`, or on whether fitness gate 2 reaches non-linked developer tools, or when `cargo-chef` ships a release declaring `rust-version` — either of the last two readmits member 1's runner-up (checks `D5b`, `G1b`); when any of the three pinned digests moves (checks `D1a`, `D2a`, `D3a` fail on the spot); when `rust:1.98.1-slim` stops resolving to the trixie digest (check `D1b`); when distroless publishes `cc-debian14` or retires `cc-debian13` (check `D3-nonroot`); when Rust stable advances far enough that the `msrv-policy` floor passes 1.96 (check `D4b`); when the org REST API Design Standard moves off blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, which invalidates every `:<line>` citation in `### Conformance with the REST API Design Standard v2.0.0` (check `S8a` fails immediately); or by **2027-03-18**, twelve months from the research date, whichever comes first

## Parameters

R51 owns no registry parameter. The binding prompt's `## Couplings` carries an
empty `- owns:` line (`S13a`, with `## Couplings` itself as the control at
`S13c`), `research/CLAUDE.md`'s R51 row carries `—` in its `owns` column, and no
row in `docs/port/PARAMETERS.md` names R51 as owner (`S2e`, with R69's
`web-extra-surface` row as the positive control at `S2f`). So no `- owns` line
appears below (`S2d`).

- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**`CONFLICT:` lines: none.**

**The set is five, and it is fixed plus consumed with nothing else.** The four
`fixed` rows are `msrv-policy`, `rust-edition`, `target-os-matrix` and `license`;
the one consumed row is `web-extra-surface`, which the prompt's `- consumes:` line
names and nothing else does (`S13b`). All five values are extracted from the live
`docs/port/PARAMETERS.md` table by script and diffed against the lines above; the
diff is **empty** (`S2a`, `S2b`, `S2c`).

**The `web-extra-surface` line above is the live registry row byte for byte,
which is revision 9's `src/web/` form — and this decision's design is not written
against it.** R69 **revision 10** is owner-accepted and unpublished
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, its
`- owns web-extra-surface` line at **1791**, read at that line by `S10a`). It
moves the gated tree to **`crates/web/src/`**, the web tests to
`crates/web/tests/`, the skip-gating key to **`crates/web/**`**, and the feature
declaration to `web = ["dep:rs-launch-blueprint-web"]` on the root package with
`axum` 0.8.9 and `tokio` 1.53.1 declared non-optionally inside
`crates/web/Cargo.toml` (`S10b`). Every path in this decision — the CI job's path
filter, the `.dockerignore`, and the stand-in workspace the container checks were
executed against — uses **revision 10's `crates/web` form**, together with R02
revision 1's accepted four-package topology. The registry bytes are preserved
above because the row has not republished (`S10d` asserts that it still carries
`src/web/`), and **R69's republication is a re-verify trigger for this item**. No
`CONFLICT:` line is raised for those paths, and none is raised at all.

**`target-os-matrix` deserves a sentence rather than a silent pass.** It is
consumed here as a constraint on **where CI runs**, and the artifact this item
produces is a Linux OCI image, so the image build is `ubuntu-latest`-only and
`macos-latest` is recorded as **`inapplicable` for the image artifact** in every
member's gate 4 rather than as a gap. The Rust binary's own `macos-latest`
obligation is untouched: R68 already builds `x86_64-apple-darwin` and
`aarch64-apple-darwin` release binaries there, and nothing here changes that.

**`msrv-policy`** fixes the builder's floor at **1.96** given stable 1.98.1
(`D4b`), which `rust:1.98.1-slim-trixie` clears, and it is the parameter that
excludes `cargo-chef` through fitness gate 2. **`rust-edition`** is `2024`, which
1.98.1 supports and which the stand-in declared. **`license`** is the repository's
own expression and bears on nothing this item selects, because gate 1 is
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not
evaluated for any dependency or tool`.

**Other consumed values, recorded in prose because they are not registry rows
this item consumes:** R68's `[profile.release] lto = "fat"`, `codegen-units = 1`
with `strip` left at `"none"` — the image build must not override them (B6);
R67's exit integers as R69 records them, 143 after a SIGTERM-initiated drain
(asserted by `C6a`); R77's `RSLBP_WEB_HOST` and `RSLBP_WEB_PORT` with defaults
`127.0.0.1` and `8000`, of which the image overrides exactly the host; R80's
`/healthz` liveness path; R05's synchronous core with async confined to the `web`
feature, which is why the image's only async surface is the serve binary; R56's
rule that secrets never live in config files, with `RSLBP_TOKEN` as the
environment tier — exactly how a container receives one; R57's XDG bases and
R54's `/etc/xdg` system tier, at neither of which this image ships a file, so a
fork wanting the system config tier must `COPY` one in; R49's `[package] include`
allow-list, which already keeps `Dockerfile` out of the published `.crate`
(`S11b`); and R20's SHA-pinning principle (`S11c`), applied here to base-image
digests rather than to actions.

## Empirical check

**Toolchain and host.** `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`;
`rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`; macOS `Darwin 25.4.0 arm64`;
Docker Desktop server **29.5.2** with `buildx v0.34.0-desktop.1`; daemon platform
**`linux/arm64`**; `/usr/bin/grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`;
`curl 8.7.1`. Working directory for every script:
`research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence`. Run dates
2026-09-19T01:17Z (container) and 2026-09-19T01:22Z (registries), which is
2026-09-18 in the programme's own timezone and the same research date the raw
report carries.

**Nothing was implemented.** The template does not exist; P03 builds it. What was
built is a disposable four-package stand-in matching R02's accepted topology —
root facade `rs-launch-blueprint` with `[lib]`, `[[bin]] rslbp` and `[[bin]]
rslbp-serve` carrying `required-features = ["web"]` and `autobins = false`, plus
`crates/core`, `crates/cli` and `crates/web` — written by the evidence script
into a directory it creates under `$TMPDIR` and deletes on exit. `crates/web`
carries `axum` 0.8.9 and `tokio` 1.53.1 at R69's feature list, one `/healthz`
route, `axum::serve(...).with_graceful_shutdown(...)` on SIGTERM and SIGINT, and
`ExitCode::from(143)` after a SIGTERM-initiated drain. The root manifest carried
`edition = "2024"`, `rust-version = "1.96"` and R68's `[profile.release]`.
`cargo generate-lockfile` reported **"Locking 54 packages to latest Rust 1.96
compatible versions"**, so the MSRV floor was exercised by the resolver rather
than merely declared. Every image and container was removed and the builder cache
pruned; **no image was pushed anywhere**.

**The three scripts, their commands, and their results.**

```
$ cd research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence
$ ./r51-container.sh   > r51-container.log  2>&1   # → 54 PASS, 0 FAIL, 0 SKIP, exit 0
$ ./r51-registries.sh  > r51-registries.log 2>&1   # → 28 PASS, 0 FAIL, 0 SKIP, exit 0
$ ./r51-sources.sh     > r51-sources.log    2>&1   # → see the summary line in that log
```

Each script sets `set -euo pipefail` on its first executable line, calls
`/usr/bin/grep` by absolute path and logs that grep's version beside every count,
asserts on **content** rather than on an exit code, counts `PASS`/`FAIL`/`SKIP`,
prints a `SUMMARY:` line whose three numbers sum to the total, and exits non-zero
on any `FAIL`. All three are `shellcheck -S warning` clean (`shellcheck.log`).

| Script | What it proves | Checks |
|---|---|---|
| `r51-container.sh` | the recommendation, built and run | `C0a`, `C1a`–`C1b`, `C2a`–`C2g`, `C3a`–`C3f`, `C4a`–`C4b`, `C5a`–`C5c`, `C6a`–`C6b`, `C7-*`, `C8-*`, `C9a`–`C9b`, `C10a`–`C10b`, `C11a`–`C11b`, `C12a`, `C13a`–`C13c`, `C14a`, `C15a`–`C15l` |
| `r51-registries.sh` | every live figure this decision carries | `D1a`–`D1c`, `D2a`, `D3a`–`D3c`, `D3-*`, `D4a`–`D4b`, `D5a`–`D5e`, `D6a`–`D6b`, `G1a`–`G1d`, `G2a`–`G2c`, `G3a` |
| `r51-sources.sh` | every repository citation, the parameter lines and this file's own shape | `S1-*`, `S2a`–`S2f`, `S3a`–`S3f`, `S4a`–`S4b`, `S5a`–`S5c`, `S6a`–`S6e`, `S7a`–`S7e`, `S8a`–`S8h`, `S9a`–`S9b`, `S9-*`, `S10a`–`S10h`, `S11a`–`S11d`, `S12a`–`S12c`, `S13a`–`S13d`, `S14a`–`S14b`, `S15a`–`S15l`, `S16-*` |

**Observed values, in the form an auditor can diff.** The container log carries
each figure on its own `measured-` line: image **12,312,852 B**; the same image
without the probe **11,499,381 B**, so busybox costs **813,471 B**; the
`debian:trixie-slim` + `curl` + `ca-certificates` + `useradd` equivalent
**40,163,283 B**; the serve binary **1,271,048 B**; incremental rebuild wall time
**15 s** with cache mounts against **28 s** without. `docker image inspect`
returned `User=nonroot:nonroot`, `Entrypoint=/usr/local/bin/rslbp-serve`,
`Healthcheck.Test=CMD /bin/busybox wget --spider -q -T 2 http://127.0.0.1:8000/healthz`,
`ExposedPorts=8000/tcp` and `RSLBP_WEB_HOST=0.0.0.0`. `docker top` reported PID 1
as uid **65532**; the health status reached `healthy` with `FailingStreak: 0` and
a first probe exiting **0**; an HTTP request from the host returned **200**;
`docker stop -t 10` left `ExitCode=143` with `OOMKilled=false`.

**Two checks are new here and close gaps the raw report left open.** `C13`
started the image with the server bound to a port the probe does not read: the
status reached **`unhealthy`**, `FailingStreak` reached the configured retry
count, and the failing probe exited **1**. `C14` asserted that
`docker run --rm --entrypoint /bin/sh <image> -c true` **fails**, which is a
positive test of the minimum-content property rather than a claim about it.

**Reproduction, and exactly what varies.** Each script was re-run in place after
its first run and re-run again from a clean extraction — `git archive HEAD |
tar -x` into a fresh directory under `$TMPDIR` — and the summary lines are
recorded in `reproduction.log` beside `r51-*.archive.log`. **The scripts are
rerunnable; their logs are not byte-identical, and the rule for comparing across
them is stated rather than waved at.** Three classes of line move between runs and
no others: (i) the `date-utc`, `gh-call-N-utc` and `scratch:` lines, which carry a
timestamp or a `mktemp` suffix; (ii) every wall-clock figure — `C1b`,
`measured-wall-incremental-with-mounts`, `measured-wall-incremental-no-mounts` —
which is why **no check asserts a duration**, and why `C5c` asserts only the
**ordering** `with-mounts < without-mounts`; (iii) `D5e`'s download counters,
which are live crates.io figures and are asserted by range, not by value. Every
other line, including every `PASS`/`FAIL` verdict and every byte figure, is
identical across runs. **The claim made here is exactly that**, and it was checked
by diffing, not assumed: `reproduction.log` records the diff of the in-place
re-run against the first log, filtered to those three classes.

**Checks that SKIP, by name.** A host without a Docker daemon or without `cargo`
skips `C1`–`C14` by name, printing the reason; a host without network reach skips
`D1a`–`D6b`; a host without an authenticated `gh` skips `G1a`–`G3a`; a host
without the org REST standard clone skips `S8a`–`S8h`; a host without the pinned
`py-launch-blueprint` or `ts-launch-blueprint` repositories skips `S15a`–`S15l`.
On the host that produced these logs, **nothing skipped** in the container and
registry scripts. Path resolution is relative to each script's own directory, and
the repository-root probe tests `.git` with `-e` and reports whether it is a
worktree file, a directory, or absent, so the extracted-tree run resolves the same
paths.

**Rate limits and privacy.** The three `gh api` calls are separated by at least
21 seconds and each stamps its own UTC time in the log (`gh-call-1-utc`
01:23:47Z, `gh-call-2-utc` 01:24:08Z, `gh-call-3-utc` 01:24:30Z). `cargo-chef`'s
manifest contains a maintainer's address, so the script reads **key counts** out
of it and never echoes its contents; `S6a` and `S6b` then assert that **no** file
under `review/` contains an address-shaped or token-shaped string, with `S6c` as
the control that the recursive search reaches files at all. `S6-*`, `S6d` and
`S6e` assert that the run directory contains no `Cargo.toml`, no `Cargo.lock`, no
`.rs` file, no `target/` tree and no nested git repository. The crates.io requests
identify themselves with the repository URL, never a personal address.

**Shape validation.** `validate_answer_text(text, "bundle")` returns **exactly one**
diagnostic against this file — the H3-template line — which is the same single
diagnostic the accepted Wave 1 bundle decision R54 produces, because that H3
template governs the **raw answer**, not a decision (`S5a`, `S5b`). It returns
**zero** against the registered `raw/opus.md` (`S5c`). This file carries **no**
`#####` heading and **no** `### Members` section (`S3e`, `S3f`), so the Members
window rule is satisfied with nothing outside a window. `S3a`–`S3d` assert the
title line, the four H2 headings in order and nothing else, the absence of
`## Supersedes`, and exactly one line beginning `re-verify:`. `bash
scripts/check-research-tree.sh .` was run before the commit and its output is
recorded in `tree-check.log`.

## Engines

- `opus` `raw/opus.md` — Claude Opus 5, sha256
  `c74cb6d1e211b77a1fa427dd92246e442880d681568a849665c24c51ab99f377`, matching
  the value registered in the run's `manifest.json` (`S14a`). Research date
  2026-09-18.
- `codex` — **absent by the controller's deferral, not failed.** Owner ruling
  **W1-CODEX3** of 2026-09-18 — "Test Codex if it's available now, and if it is,
  use it. If not, do without it." — recorded at
  `docs/planning/p02/owner-decisions.md:488` (`S12a`), with the probe of
  2026-09-18T21:53Z returning a usage-limit refusal. The run's `manifest.json`
  holds exactly one research operation (`S14b`) and its state is `partial`.

**There are therefore no inter-engine disagreements to settle, and that is a
weakness of this decision, not a convenience.** A single engine cannot be
cross-examined, so every load-bearing claim was re-verified at its source before
being relied on. What follows is the split.

**Re-verified in this run, at the source, by a named check.**

| Claim | Check | Result |
|---|---|---|
| The three base-image digests | `D1a`, `D2a`, `D3a` | all three unchanged, byte for byte |
| `rust:<ver>-slim` now means **trixie** | `D1b`, `D1c` | confirmed: `slim` and `slim-trixie` share a digest; `slim-bookworm` differs |
| The `cc-debian13` line exists and publishes `:nonroot` | `D3b`, `D3c`, `D3-*` | 6,044 tags, `:nonroot` a multi-arch OCI index |
| Stable is 1.98.1 and the floor is 1.96 | `D4a`, `D4b` | confirmed at the Rust project's own channel file |
| `cargo-chef` 0.1.78 declares no `rust-version` | `G1b` (with `G1c` as the control), `D5b` | confirmed at tag `v0.1.78`; crates.io `rust_version` is `null` |
| Its maintenance signal is `at-risk` | `G2a`–`G2c`, `G3a` | confirmed: 6 of 6 recent issues at 0 comments, sample of 6 not 10 |
| No open RustSec advisory | `D6a`, `D6b` | 404 where the `atty` control returns 200 |
| All twelve container checks the raw report ran | `C1`–`C12` | every one reproduced, on the same Docker version and platform |
| The cache-mount benefit **against a deleted-mount counterfactual** | `C4b`, `C5a`–`C5c` | confirmed: 0 third-party crates rebuilt with mounts, 50 without |
| The busybox `HEALTHCHECK`, built and probed | `C2c`, `C3c`–`C3f`, `C13a`–`C13c` | confirmed, and the failure path is now proven too |
| py publishes and verifies no image; ts has none | `S15i`, `S15j`, `S15k`, `S15l` | confirmed at both pins |
| The five `- assumes` values against the live registry | `S2c` | diff empty |
| The REST standard's blob id and quoted lines | `S8a`–`S8e` | confirmed by hashing the file and reading each line |

**Carried from `raw/opus.md` without independent verification, and named so an
auditor can see what rests on one engine.** The four surveyed adopter Dockerfiles
(`atuinsh/atuin`, `LemmyNet/lemmy`, `astral-sh/uv`, `meilisearch/meilisearch`)
and their star counts, read by the raw report on 2026-09-18 and not re-fetched
here; the `moby/buildkit` `v0.26.1` reference quotations, read by the raw report
at a pinned tag and quoted here without re-fetching that file; the Kubernetes
`pod-lifecycle` page's zero `healthcheck` matches; the `GoogleContainerTools/distroless`
and `docker/build-push-action` repository figures; the `reproducible-containers/buildkit-cache-dance`
README sentence; and the owner reference's musl and alpine caveats, which this run
did not measure and which are carried as its claim.

**Three of the raw report's own statements are corrected here, each with the
evidence that moved it.**

1. **The port and the host variable.** The raw report used `ENV PORT=8080` and
   probed `http://127.0.0.1:8080/healthz`, calling both placeholders pending R77.
   R77's accepted revision 1 names the variables `RSLBP_WEB_HOST` and
   `RSLBP_WEB_PORT`, sets their defaults to `127.0.0.1` and **8000**, and assigns
   *this item* the line `ENV RSLBP_WEB_HOST=0.0.0.0` in terms (`S10e`, `S10f`).
   The fixture and every executed check use 8000 and the R77 names. py's own image
   exposes 8000 and probes 8000 (`S15c`, `S15e`), so the correction also brings
   the Rust image back into line with its source precedent.
2. **The CI job's placement.** The raw report deferred it to R11. R11's accepted
   revision 1 says no container job enters `ci.yml` (`S10g`), so member 5 places
   the job in its own workflow file on R11's own rule, and hands the
   required-status question to R12.
3. **The probe's own timeout.** The raw report's executed image carried `-T 3`
   while its prose recommended `-T 2`; the fixture and this run carry `-T 2`
   (`C15e`).

**Two of the raw report's figures could not be reproduced exactly, and neither
changes a conclusion.** Its `debian-slim` comparison measured **35,680,357 B**
(+189.8 %); the variant built here measures **40,163,283 B** (+226 %), because
this one also installs `ca-certificates`, which the selected runtime supplies for
free and which an honest comparison must therefore include. And its cache-mount
benefit was **50.8 %** of *cargo* time (21.80 s → 10.72 s) where this run measured
**46 %** of *wall* time (28 s → 15 s) — a different instrument on a different
build, pointing the same way. Neither figure is load-bearing: what decides member
1 is `C4b`'s **0** against `C5b`'s **50**, which is a count, not a duration.

**What P03 must validate, because this run could not.**

1. **Every check above, re-run on `ubuntu-latest` for `linux/amd64`.** Nothing
   here proves the amd64 build, and the byte sizes in particular will differ.
2. **The image job inside a real GitHub Actions workflow**, in whatever slot R11
   and R12 settle — no workflow was executed here, so every CI claim in this
   decision is a proposal.
3. **A property assertion that the workflow contains no `docker/login-action` and
   no `push: true`**, so "we do not publish" is a checked property rather than a
   convention.
4. **`cargo build --release --locked --features web --bin rslbp-serve` at the
   repository root outside Docker**, asserting that the image build and the host
   build are the same command against the real template.
5. **The `.dockerignore` against the real tree**, which will contain files this
   stand-in did not.

**Evidence gaps, stated rather than papered over.** Chainguard's free tier's
versioned-tag availability was not checked, so that base-image candidate is
recorded as a gap rather than ranked. `GoogleContainerTools/distroless` issue
responsiveness was not sampled, only its open-issue count. The musl and alpine
costs the owner reference asserts were not measured. No benchmark of the running
service was taken, and none is claimed. The `unsafe` posture of `cargo-chef` was
not audited — it is a build-time binary that never links into the shipped
artifact, so its `unsafe` surface does not reach the template's process, which is
a reason the question does not bind rather than an answer to it.

**Reconciliation with the owner-supplied reference architecture**
(`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, a **standing
input** under `docs/planning/p02/owner-decisions.md` section 11 — not a standard
and not a pre-decision; its own Caveats record that its patterns were "compiled
in my head, not against the toolchain"). Twelve rows touch this item.

| Reference row | Reference says | This decision |
|---|---|---|
| C15 base family | "distroless/cc-debian12" over "musl/scratch; alpine" | **Agree**, and independently measured: 12,312,852 B against 40,163,283 B (`C9b`) |
| C15 exact suite | "Recommend **distroless/cc-debian12**" | **Differ, on sourced ground.** `cc-debian13` publishes `:latest` and `:nonroot` (`D3c`, `D3-*`) and `rust:<ver>-slim` already means trixie (`D1b`); pairing trixie with `cc-debian12` crosses suites for no benefit |
| C15 / C14 `cargo-chef` | "Build with cargo-chef"; C14 lists "bacon + **cargo-chef** + mold" | **Differ, on gate and on measurement.** No `rust-version` at tag `v0.1.78` (`G1b`), excluded under the strict reading (`S12c`); cache mounts cut the rebuild from 50 recompiled crates to 0 (`C4b`, `C5b`) with no third-party tool |
| C15 run as `nonroot` | "run as `nonroot`" | **Agree**, measured: PID 1 at uid 65532 (`C3a`); `id` in the base returns `uid=65532(nonroot)` (`C7-cc-debian13`) |
| C15 `bind PORT (default 8080)` | "bind `PORT` (default 8080)" | **Differ, on an accepted decision.** R77 revision 1 names `RSLBP_WEB_PORT` with default **8000** and `RSLBP_WEB_HOST` with default `127.0.0.1` (`S10f`), which is also py's port. The raw report recorded this row as agree-as-placeholder; R77's publication moves it |
| C15 `/healthz (liveness)` | "expose `/healthz` (liveness)" | **Agree** that the `HEALTHCHECK` probes the liveness path; the path's own value and behavior are R80's |
| C15 `/readyz (readiness, checks DB)` | "`/readyz` (readiness, checks DB)" | **Not this item's row** — section 11 assigns C15 probes to **R80**. Recorded as a hand-off. Noted for R80: this template has no database, so "checks DB" has nothing to check here |
| Variant A `FROM lukemathwalker/cargo-chef:latest-rust-slim` | an unpinned `latest-` tag | **Differ, on sourced ground.** B5 and R20's pinning principle (`S11c`) both require a digest; the reference's own Caveats flag its unpinned versions as "verify". All three `FROM`s here carry `@sha256:` (`C15b`) |
| Variant A final-stage shape | `FROM gcr.io/distroless/cc-debian12` / `COPY --from=builder … /app` / `USER nonroot:nonroot` / `ENV PORT=8080` / `ENTRYPOINT ["/app"]` | **Agree** on the shape, line for line, with the suite and digest changed per the rows above, the port and variable name per R77, and the binary installed at `/usr/local/bin/rslbp-serve` rather than `/app` |
| Neither variant carries a `HEALTHCHECK` | no `HEALTHCHECK` instruction in Variant A or B | **Differ.** F337 records the capability and Docker Engine, Compose and Swarm consume it. The reference's omission is consistent with its Cloud Run target, where platform probes replace it; this template's target is unconstrained |
| C14 `mold` linker | "mold/lld linker for faster link" | **Not adopted, and recorded rather than silently dropped** — see `### What this decision does not decide`. R69 hands it to R51/R68, R68 declared it out of scope, and this item declines it because a linker swap inside a Dockerfile would make the container binary differ from the released one |
| Cloud Run deployment, Variant B `node:20`/Vite stage, `SQLX_OFFLINE`, Artifact Registry, `gcloud run deploy` | a full GCP deployment path | **Inapplicable.** Section 11 records these as rows with no P02 item, "NOT decided and NOT researched by this instruction". This template has no database, no frontend build and no cloud target |

**Tally: 4 agree, 5 differ (each on a measured figure, a published endpoint or an
accepted decision), 2 hand-offs (C15 `/readyz` → R80; C14 `mold` → R68, which
declined it), 1 inapplicable.** That is twelve rows. The raw report's tally was
4 agree / 4 differ / 1 agree-as-placeholder / 2 hand-offs / 1 inapplicable; the
placeholder row moved into `differ` when R77 published its port default, and the
row count is unchanged.

**Sources.** Primary specifications: the BuildKit Dockerfile frontend reference at
`moby/buildkit` tag `v0.26.1`
(`https://raw.githubusercontent.com/moby/buildkit/v0.26.1/frontend/dockerfile/docs/reference.md`,
cache-mount options and persistence contract at lines 843–892, `HEALTHCHECK`
forms and exit-code contract at lines 2819–2880, retrieved 2026-09-18 by the raw
report); the Kubernetes `pod-lifecycle` page source
(`kubernetes/website`, `content/en/docs/concepts/workloads/pods/pod-lifecycle.md`,
retrieved 2026-09-18 by the raw report); `https://static.rust-lang.org/dist/channel-rust-stable.toml`
(retrieved 2026-09-19T01:22Z here). Registry and package endpoints, each re-read
here: `https://hub.docker.com/v2/repositories/library/rust/tags/{1.98.1-slim-trixie,1.98.1-slim,1.98.1-slim-bookworm}`;
`…/library/busybox/tags/1.38.0-musl`;
`https://gcr.io/v2/distroless/cc-debian13/{manifests/nonroot,tags/list}`;
`https://crates.io/api/v1/crates/cargo-chef` and `/versions`;
`https://rustsec.org/packages/{cargo-chef,atty}.html`. GitHub REST through a
keyring-authenticated `gh`, one call per ≥21 s, each stamped:
`repos/LukeMathWalker/cargo-chef/contents/Cargo.toml?ref=v0.1.78`,
`repos/LukeMathWalker/cargo-chef/issues?state=all&sort=created&direction=desc&per_page=10`,
`search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue+is:open`. Pinned source
repositories, read only through their pins: `py-launch-blueprint` at `b08bccfb`
(`Dockerfile`, `.dockerignore`, `Justfile:317-318`, the `.github` searches) and
`ts-launch-blueprint` at `cb1cbcb2` (the empty container-path listing). Programme
records: `docs/port/COMMONALITY.md` F017 `:23`, F223 `:227`, F303 `:307`, F328
`:332`, F336 `:340`, F337 `:341`; `docs/port/BASELINE-REVIEW.md` `:39`;
`docs/port/areas/web-service.md` `:43`; `docs/port/PARAMETERS.md`;
`docs/port/OWNER-REVIEW.md` (Q7.B, W2-REST);
`docs/planning/p02/execution-ledger.md` `:414`;
`docs/planning/p02/owner-decisions.md` `:488` and section 11. The org REST API
Design Standard v2.0.0 at blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, lines
271, 1019, 1271, 1317, 1320, 1323, 1329–1351, 1356 and 1387. Accepted-but-unpublished decisions:
R69 revision 10 (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`),
R68 (`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md:32`),
R77 (`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md:606,723`),
R11 (`research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/DECISION.md:144`),
R80 revision 2 (`research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md`),
R02, R05, R54, R56, R57. Published decisions:
`research/topics/19-dependabot-config-shape/DECISION.md:66`,
`research/topics/49-build-target-declaration/DECISION.md`,
`research/topics/20-third-party-action-pinning-policy/DECISION.md`,
`research/topics/17-secret-scanning-ci-workflow/DECISION.md`,
`research/topics/18-ai-assisted-review-workflows/DECISION.md`,
`research/topics/25-semver-bump-strategy/DECISION.md` and
`research/topics/26-packed-artifact-content-guard/DECISION.md` (the last two read
for consistency; this item creates no obligation on either).
