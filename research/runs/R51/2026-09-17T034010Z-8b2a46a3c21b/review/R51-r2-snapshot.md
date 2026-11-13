# 2026-09-26 — R51 — container-image (bundle, Focused) — decision (revision 2)

**Revision note, revision 2.** This is fix round 1, against revision 1 (sha256
`11b9150d1a4a8df336f17a8e96054eafcfd695f03ff693e5618d5f5610a95231`, preserved
byte-identical at `review/R51-r1-snapshot.md`). Both revision-1 audits rejected
it: the empirical audit (`review/audit-claude.md`, findings F1–F7) and the
judgment audit (`review/audit-fable.md`, findings 1–5). Revision 1 was a draft
written before this run's second engine existed: the Muse leg was collected on
2026-09-22, after the synthesis agent had stopped (ledger line 1086). **The
recommendation does not move.** No finding required it to, and every
disagreement the Muse report raises is adjudicated in `## Engines` against
executed evidence or an owner ruling.

| Finding | What the audit found | Disposition in revision 2 |
|---|---|---|
| emp **F1** / jmt **2** | `r51-sources.log` ended `FAIL=5`, and revision 1 reported it only as "see the summary line" | **Fixed.** F2–F5 are repaired below, all three scripts were rerun, and `## Empirical check` states each script's `SUMMARY` line, including this one's |
| emp **F2** | a fenced `## Conformance note …` line made `S3b` fail | **Fixed as prescribed.** The fenced line is now `###`; `S3b` passes, and `S3g` checks the four H2s against published `research/topics/11-…/DECISION.md` |
| emp **F3** | the gate-1 string was line-wrapped, so `S4a`'s fixed-string search missed it | **Fixed.** Both occurrences are now one line each; `S4a` requires at least two |
| emp **F4** / jmt **5** | R77 was cited as "accepted revision 1" at lines 606 and 723 | **Fixed.** R77 is cited as revision 3 (sha256 `5985ee47…`, ledger line 1082) at lines 678 and 931, with its status stated: `open`, and its approving audit binds revision 2 only (ledger line 1083). `S10e`, `S10f`, `S10i`, `S10j`, `S10l` |
| emp **F5** / jmt **4** | `OV-04` was attributed to R80, and `OV-14` re-argued R77's R8.1 deviation without citing it | **Fixed.** `OV-04` is R77's (ledger line 1073; `S9b`, `S9e`); R80 holds `OV-05` (`S9d`). `OV-14` is re-scoped to the container-side record of R77's `OV-04` and no longer decides options that belong to R77 or R69 |
| emp **F6** / jmt **3** | four cited logs did not exist | **Two produced, two dropped.** `shellcheck.log` and `reproduction.log` now exist, produced by running the stated commands (`reproduction.log` by a new script, `r51-reproduce.sh`). The `r51-*.archive.log` clean-extraction claim is **dropped**: `review/` and the Muse leg are untracked, so an extraction of `HEAD` cannot contain them. The `tree-check.log` claim is **dropped**: the tree check takes the controller's publication lock, which a synthesis worker must not hold. Both gaps are recorded in `## Empirical check` and `## Engines` |
| emp **F7** | tags moved, R11 moved, the prompt and manifest moved | **Fixed.** `D1a`, `D2a` and `D3a` now assert that each **pinned digest resolves** (HTTP 200, with an all-zero digest returning 404 as the control `D1e`); tags' current digests are logged as dated observations. R11 is cited at published revision 7, line 270. The prompt's engines and the manifest's two operations are asserted (`S13d`, `S14a`–`S14f`) |
| jmt **1** | `## Engines` omitted the collected Muse report | **Fixed.** `## Engines` lists both reports with their hashes and adjudicates six disagreements. Muse's 10-issue sample was re-read at the rubric's own endpoint (`G2d`, `G2e`) |
| jmt non-blocking | `C13` ran a variant; `-T 2` is asserted only as a literal | **Stated** at B3′ and in member 4 |
| — | (found while repairing F5) | Other items' overrides are named here by bare number (`OV-04`, `OV-05`), never by the `OVERRIDE (OV-nn)` declaration token, because R77's census counts every `.md` file that carries its token and allows no third holder (`research/runs/R77/…/review/evidence/ov-allocation-r3.sh:91`–`:112`). The `re-verify:` line's closing date is unchanged, 2027-03-18; revision 1 labelled it "twelve months" from the research date, and it is six |

Revision 1's evidence logs were overwritten by the reruns except where kept:
`r51-container.r1.log` and `r51-sources.r1.log` are revision 1's logs, byte for
byte. Revision 1's `r51-registries.log` was overwritten before it was copied;
both audits quote its summary line, `PASS=28 FAIL=0 SKIP=0 TOTAL=28`.

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
| 4 | Liveness healthcheck | **one static `busybox` applet + exec-form `HEALTHCHECK`** | `busybox:1.38.0-musl@sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37` | the smallest thing that restores py's principle to a shell-less base: **812,604 bytes** of compressed layer content, measured, no package manager, no change to any other item's decision |
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
  instruction's timeout expires. **This corrects the Opus raw report**, whose executed
  image carried `-T 3` — equal to the instruction timeout, and therefore racing
  it — while its prose recommended `-T 2`. The image measured here carries `-T 2`.
  `C15e` and `C15f` assert the two literals only. No check drives a slow
  endpoint, so "busybox's timeout fires first" is a **proposed** property that
  P03 must execute, not a measured one.
- **`127.0.0.1`, not `localhost`** (`C2c`): no resolver is configured in this
  image. py chose the same literal for the same reason (`S15e`).
- **`ENV RSLBP_WEB_HOST=0.0.0.0`, and no `RSLBP_WEB_PORT`** (`C15g`, `C15h`,
  `C2e`): R77's revision 3 assigns exactly this line to this item and no other
  (`research/runs/R77/…/review/DECISION.md:931`, `S10e`), and its port default of
  `8000` (`:678`, `S10f`) stays R77's to change. Restating the port in the image
  would fork R77's default into two places. R77 is `open`; its revision 3 is not
  yet audited (ledger line 1083, `S10l`), so this line is a coupling to a
  proposal, and R77's movement is a `re-verify:` trigger.

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

**B3′ is new in this decision.** The Opus raw report recorded the failure path as
"**Low-confidence and explicitly unproven** … no `unhealthy` transition was
observed in this run", and wrote that a healthcheck only ever observed passing
"is not known to detect anything". That gap is now closed by execution: started
with the server bound to a port the probe does not read, the container reaches
`unhealthy`, its `FailingStreak` reaches the configured retry count, and the
failing probe exits **1** — the reference's *unhealthy* code, not the reserved
**2**. **`C13` runs a variant of the fixture, not the fixture itself**, and the
variant is stated here: the image is the one `C1` built from
`Dockerfile.candidate`, but the run sets `RSLBP_WEB_PORT=8001` so nothing
listens on the probed 8000, and overrides the health timings at `docker run`
(`--health-interval=1s --health-retries=2 --health-start-period=1s
--health-timeout=3s`) so the transition takes seconds. The probe command, the
path and the port it probes are the fixture's; the retry count is 2, not the
fixture's 3.

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
  third party — and, a corroboration the Opus raw report did not draw, **py's own
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
  binary, measured at **812,604 B**, **6.6 %** of the image's compressed layer content (`C9a`) — rather
  than an `apt` layer.
- *Same binary as the release* (B6, R68). py's image installs the same wheel the
  release publishes. The Rust analogue is that the image build must be a plain
  `cargo build --release --locked`, inheriting R68's `[profile.release] lto =
  "fat"`, `codegen-units = 1` with `strip` left at its `"none"` default. This has
  a cost the design accepts rather than overrides: the fat-LTO link dominates the
  incremental rebuild and no caching strategy removes it.

**Maintained reference implementations.** `atuinsh/atuin` is the closest
maintained composition of the same triple — a Rust HTTP server, a created
non-root `USER`, and a `HEALTHCHECK` on `/healthz` — and the Opus raw report read its
`Dockerfile` at its default branch on 2026-09-18. This design differs from it in
three places, each on ground stated in the member that owns it: digest-pinning
every `FROM` (atuin pins its chef image by digest but its runtime by a dated
tag), a distroless runtime rather than `debian-slim` + `curl` (measured:
12,302,310 B against 36,869,229 B of compressed layer content, `C9b`), and cache mounts rather than
`cargo-chef` (gate 2, plus no third-party tool). `astral-sh/uv` composes cache
mounts with a digest-pinned builder and a contents-minimal final stage. Neither
composes all five selections, which is why the composite built here is the
primary compatibility evidence and the adopters are the corroboration.

#### Member 1 — dependency-layer caching

**Dominant choice: `cargo-chef` 0.1.78**, by adoption. `recent_downloads`
**1,036,172**, `downloads` **4,360,576**, newest non-yanked **0.1.78** published
**2026-08-12** out of 78 live versions (`D5a`–`D5e`, `GET
https://crates.io/api/v1/crates/cargo-chef` and `/versions`, retrieved
2026-09-27T00:48Z; 997,338 and 4,249,535 on 2026-09-19). Two of the four Rust Dockerfiles the Opus raw report surveyed use
it, and both are the web servers — so its adoption is real and concentrated in
exactly this item's use case.

**Excluded by fitness gate 2.** `cargo-chef`'s `[package]` table declares **no
`rust-version` key**. Read at the tag rather than from a package summary: the
manifest at `v0.1.78` is 1,170 bytes and contains **0** `rust-version` keys and
**1** `edition` key, `edition = "2018"` (`G1a`–`G1d`, keyring-authenticated
`gh api "repos/LukeMathWalker/cargo-chef/contents/Cargo.toml?ref=v0.1.78"`,
2026-09-27T00:48:33Z). crates.io agrees: `rust_version` is `null` (`D5b`). The
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
maintenance signal is independent of the gate. The prompt's rubric samples the
**10 most recently opened issues**. Revision 1 read the ten most recent *items*,
six of them issues; revision 2 reads the rubric's own sample, issues only,
through `GET https://api.github.com/search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue&sort=created&order=desc&per_page=10`
(`gh-call-2b-utc` 2026-09-27T00:49:16Z). All **10** sampled issues, #350 to
#367, opened 2026-04-01 to 2026-09-10, carry **`comments: 0`** (`G2d`, `G2e`),
two of them the repository's own RustSec bot notices about its dependency tree.
The Muse report read the same ten issue numbers and the same zero (`raw/muse.md:291`).
Median days to first maintainer response is therefore **undefined — there were
no responses**; unanswered **10 of 10**. Maintenance state by the rubric:
**at-risk**, on that concrete signal rather than on a release gap — the release
cadence is current (0.1.78 on 2026-08-12, `D5c`; **35** open issues, `G3a`).
Muse reads the same facts as `active`; `## Engines` adjudicates the difference,
which does not decide this member. Second, cargo-chef's one
*unique* benefit over cache mounts — an exportable dependency **layer** — is
realisable only with a registry or GHA layer cache that member 5's build-only,
no-publication job does not configure and should not.

*Gate ledger for `cargo-chef`, stated in full rather than abbreviated:* gate 1
**inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool**
(`S4a`; the declared `Apache-2.0 OR MIT`
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

Measured on the stand-in (`linux/arm64`, Docker 29.8.0, 2026-09-27):
appending one line to `crates/web/src/lib.rs` and rebuilding recompiled **only**
the two affected workspace crates — **0** third-party crates (`C4b`) — in **10 s**
of wall time. With the two mount lines deleted, the identical edit recompiled
**50** third-party crates (`C5b`) in **17 s** (`C5c`). Revision 1's run on
Docker 29.5.2 on 2026-09-19 found the same 0 and 50, in 15 s and 28 s. Fifty is the whole
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
the day before revision 1's check, and has been republished again since — on
2026-09-27 `rust:1.98.1-slim-trixie` points at `sha256:4cd82946…`, not the
pinned `sha256:ca5c572a…` (dated `observed-tag-digest` line in
`r51-registries.log`). **That re-push is the pinning working, not a broken
pin**: the pinned digest still resolves, HTTP 200 on
`registry-1.docker.io/v2/library/rust/manifests/sha256:ca5c572a…` (`D1a`), and
an all-zero digest returns 404 on the same endpoint (`D1e`). The Dockerfile
builds the pinned bytes until a reviewed diff moves the pin, which is R19's
`docker` ecosystem's job (`### What this decision does not decide`).

**The suite trap, verified rather than asserted.** `rust:1.98.1-slim` and
`rust:1.98.1-slim-trixie` carry the **same** current digest, while
`rust:1.98.1-slim-bookworm` carries a different one (`D1b`, `D1c`, both
re-read on 2026-09-27 after the re-push). Anyone carrying `rust:<ver>-slim`
forward from an older file has silently changed Debian suites. The digest in the
`ARG` is what makes that visible in review.

The builder needs `cargo`, `rustc` and a linker and nothing else — no
`pkg-config`, no `libssl-dev`, because R05's selected HTTP client is `ureq` with
`rustls` and R69's web stack is `axum` + `tokio` with no native-TLS dependency.
`-slim` is therefore sufficient **with no `apt-get` layer at all**, which is a
genuine simplification over `atuinsh/atuin`, whose builder installs
`build-essential libssl-dev pkg-config`. The cost of `-slim` is that it becomes
wrong the moment a crate needs a native library, at which point the full
`rust:<ver>` image is cheaper than an `apt` layer.

**No candidate in this member fails a gate**; the differences are fit.
Runner-up: `rust:1.98.1-slim-bookworm@sha256:8d50cf1c…` (still resolves, `D1d`) paired with
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
multi-architecture OCI index (`D3b`, `HEAD https://gcr.io/v2/distroless/cc-debian13/manifests/nonroot`
with an OCI-index `Accept` header, 2026-09-27T00:48Z) whose current digest is
still the pinned
`sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97`
(`observed-tag-digest` line), and the pinned digest resolves by digest (`D3a`,
HTTP 200). The repository publishes **6,156** tags on 2026-09-27 (6,044 on
2026-09-19), including `latest`, `nonroot`, `debug` and `debug-nonroot`
(`D3c`, `D3-*`). Maintenance state **active**.

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

**Measured comparison, three variants built from the same workspace.** Size is
the sum of the compressed layer sizes in each image's manifest, read from
`docker save` — the bytes a registry pull transfers (`## Empirical check` says
why revision 2 measures it this way).

| Runtime | Image size | Delta | Runs non-root | Reaches `healthy` |
|---|---|---|---|---|
| `cc-debian13:nonroot` + busybox probe (**selected**) | **12,302,310 B** | — | uid **65532** (`C3a`) | yes (`C3c`) |
| `cc-debian13:nonroot`, no probe, no `HEALTHCHECK` | **11,489,706 B** | −812,604 B (`C9a`) | uid 65532 | n/a — no probe |
| `debian:trixie-slim` + `curl` + `ca-certificates` + `useradd` | **36,869,229 B** | **+199 %** (`C9b`) | uid **999** (`C10b`) | yes (`C10a`) |

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
| **A. Static `busybox` copied from a pinned image** | `COPY --from=probe /bin/busybox /bin/busybox` plus an exec-form `HEALTHCHECK` | **+812,604 B**, +6.6 %; one more digest to keep fresh | **Selected** |
| **B. `debian-slim` runtime with `curl`** | atuin's and py's shape | **+24,566,919 B** over A; adds `apt`, a shell, a package database | Rejected on measured size and surface; verified working (`C10a`), so priced, not disqualified |
| **C. A `--health-check` flag or subcommand on the serve binary** | the most idiomatic Rust answer — the binary already has an HTTP stack | **zero** bytes | **Rejected without raising a `CONFLICT:`** — see below |
| **D. A second, purpose-built probe binary in the workspace** | a tiny HTTP GET | zero third-party images | Rejected on two owned-parameter collisions: R49's `build-tool-output-shape` says "Binary target: exactly one … `autobins = false`", and R69 adds exactly one more |
| **E. No `HEALTHCHECK` at all** | `meilisearch`, `lemmy` and `uv` all ship none | zero | Rejected: F337 records the capability and nothing in the Rust ecosystem makes it infeasible |

**Why option C is rejected rather than raised as a `CONFLICT:`, and why this
decision keeps that line unraised.** A `CONFLICT:` line is for a consumed value
the recommendation *genuinely needs* changed. This recommendation does not need
it. R69's accepted revision 10 still says the `rslbp-serve` binary carries the
org CLI Design Standard's required global core "and nothing beyond it" — verified
at the owned line itself (`S10c`), not carried from the Opus raw report — and option A
supplies the same capability for 812,604 bytes with no change to any other item's
decision. Option C would be cheaper in bytes and cleaner in spirit: the process
that owns the port is the process best able to say whether it is listening. So
the trade is recorded here for the owner to see rather than to discover later,
together with the exact line R51 would raise if the owner preferred to spend a
CLI-surface exception instead of 0.81 MB:
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

**Where the CI job goes — this is a correction to both raw reports.** Both
reports left the placement to R11 (Opus: "one path-gated CI job"; Muse: "belongs
to R11/R50/R68", `raw/muse.md:284`). R11 is now **published** at revision 7
(`research/topics/11-ci-workflow-job-structure/DECISION.md`, `S10m`), and it
answers the question directly: "No container or deploy job enters `ci.yml`; R51
owns the image and R68 the release workflow" (`:270`, `S10g`). R11's own rule for
a check that needs a different toolchain and a `target/` it must not share is
that it becomes its own job, and its R44 row spells out the placement for a check
that must not claim a cache entry: "its own job in its own workflow file"
(`:297`, `S10o`). A Docker build compiles Rust inside the builder container, claims
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
`Pending` and blocks merging (`:165`, `S10n`), while a job skipped by a conditional reports
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
| R8.1 | 1317 | MUST | "APIs MUST be served only over TLS 1.2 or higher, preferring 1.3; SSL 2/3 and TLS 1.0/1.1 MUST be rejected" | **`OVERRIDE (OV-14)`**, the container-side companion of R77's `OV-04` — the listener's deviation is R77's; the image's `0.0.0.0` default, `EXPOSE 8000` and `http://` probe are this item's |
| R8.2 | 1323 | MUST | access tokens MUST NOT travel in URI query parameters | **CONFORMS, and the image is the reason it is easy to keep** — the only request the image itself issues is the loopback liveness probe, which carries no credential at all; R56's `RSLBP_TOKEN` reaches the process as an environment variable, which is exactly how a container supplies one |
| R8.3–R8.5 | 1329–1351 | MUST/SHOULD | the authentication mechanism, OAuth hygiene, credential scoping | **N/A to this item** — the image selects no mechanism and mints no credential. R69 owns the surface; the rows belong to whichever item introduces authentication |
| R8.10 | 1387 | MUST | each of five deployment-profile axes MUST take its ratified default unless a named trigger applies, and any flip MUST be recorded in the conformance note | **N/A with reason** — sender-constrained tokens, token format, rate-limit aggressiveness, replay window and object-level authorization are all properties of the running API, and the image configures none of them. It flips no axis, so it has nothing to record. R74 owns rate limiting; the token axes belong to whichever item introduces authentication |
| R1.7 | 1271 | MUST | no silent deviation; a MUST deviation is nonconformance unless recorded as an approved exception | **CONFORMS** — `OVERRIDE (OV-14)` below is that record, and it is *requested, not granted*, until the owner rules |

**The standard names no health, liveness, readiness, container or port rule
anywhere.** **0** numbered rules match `health|liveness|readiness|container|healthcheck`,
where the same pattern finds **139** numbered rules in total, so the zero is a
fact about the standard rather than a failed search (`S8f`, `S8g`). R80's
revision 3 reached the same conclusion for the probe endpoints: "The standard
names no health, readiness, liveness or ops-endpoint rule anywhere"
(`research/runs/R80/…/review/DECISION.md:548`, `S10p`, `S10q`). This item
therefore judges the image by the general rules above and invents no ops
carve-out.

**One row is handed on rather than answered.** R8.6 (line 1356) requires every
request to be authorized against the specific object. The liveness request this
image issues is unauthenticated by design, and whether an unauthenticated ops
route is a deviation from R8.6 is **R80's** question, not this item's — the image
merely calls whatever route R80 defines. R80's revision 3 names R8.6 on **0**
lines, while it names `/healthz` on many (`S10r`, `S10s`), so the row is named
here as an open hand-off rather than treated as settled.

#### `OVERRIDE (OV-14)` — the image's container-side exposure of R77's plaintext listener

**Ownership first, because revision 1 got it wrong.** The R8.1 deviation itself —
a plaintext listener with no TLS setting on the web surface — is **R77's**
`OV-04` (`research/runs/R77/…/review/DECISION.md:806`, `S9b`), and the
controller's allocation table gives that number to R77: "OV-04 R77 revision 2
(R8.1 plaintext listener; committed first, keeps the number); OV-05 R80
(renumbered from OV-04 in a revision 3)" (`docs/planning/p02/execution-ledger.md:1073`,
`S9e`). R80's revision 3 carries `OV-05` as its only override and declares
`OV-04` on **0** lines (`S9d`). Revision 1 attributed `OV-04` to R80
and re-argued R77's options as if R51 decided them. It does not: whether the
server terminates TLS is R77's and R69's question. R77's option (b), TLS in
process, is rejected there on R77's own grounds (`:840`–`:845`).

**What is R51's, and therefore what `OV-14` records.** R77 keeps the listener
unreachable off-host by defaulting `RSLBP_WEB_HOST` to `127.0.0.1`, and names
the moment the duty passes to the operator: "that moment, which R51's Dockerfile
makes explicit, is exactly when the operator takes on R8.1's duty at the edge"
(R77 `:827`–`:828`). R77 rejects refusing the `0.0.0.0` bind because "it would
make R51's container image unusable, and R51 owns the Dockerfile" (`:847`,
`S10k`). So three lines of **this item's** artifact turn R77's latent deviation
into the image's default behavior, and `OV-14` is the record of those three
lines and nothing else:

1. `ENV RSLBP_WEB_HOST=0.0.0.0` — every container started from the image listens
   on all interfaces by default (`C2e`).
2. `EXPOSE 8000` — the image advertises the plaintext port (`C2d`).
3. The `HEALTHCHECK` probes `http://127.0.0.1:8000/healthz`, cleartext on
   loopback (`C2c`).

`OV-14` is the **container-side companion** of R77's `OV-04`. It does not
restate R77's deviation, and it lapses with it: if R69 later adopts an
in-process TLS terminator (R77's stated withdrawal condition, `:863`–`:864`), `OV-14`
is withdrawn and the three lines above are revisited.

**Numbering — allocated, not searched.** The controller allocated **`OV-14`**
to this item (`execution-ledger.md:1073`, `S9f`; kept by the correction at
`:1074`, `S9g`). Gaps in the sequence are expected and are not evidence of a
missing override. The scan this decision runs is therefore a collision check on
an allocated number, not a claim to a free one: `OV-14` appears in no other
decision and in no port record (`S9a`), while `OV-01` (R60's CLI-standard
waiver, refused 2026-09-14), `OV-02` (R61), `OV-03` (R02) and `OV-04` (R77) are
all found by that same scan, which keeps `S9a`'s zero from being a failed search
(`S9-01`…`S9-04`).

**This is an `OVERRIDE (OV-nn)` in the AGENTS.md sense** — a departure argued
with options, recorded in the shape of the standard's own §1.9 deviation note —
and **not** the ledger verdict `COMMON → OVERRIDE (OV-nn)`, which is legal only
for origin `same`. F223's, F336's and F337's verdicts stay `DIVERGENT` and no
ledger file changes.

**Argument.** R8.1 is a **MUST** with no tier scope and no applicability switch,
and the standard grants it no edge-termination exemption anywhere. That is a
claim about the text and it is checked rather than asserted: **0** lines in §8
carry any form of the word *terminat* (`S8h`), and the occurrences elsewhere in
the document are about something else (`S8k`) — R5.12's carve-out at line 1019
for "reverse proxies, CDNs, WAFs, rate limiters, load balancers terminating
**before application code**", which governs the media type of *error responses*
rather than transport (`S8j`), and lines in §13 about *stream* termination.
**R5.12 cuts slightly against this override and is recorded rather than
omitted**: it shows the standard does contemplate a proxy in front of the
application. What it does not do is exempt the origin behind that proxy from
R8.1. Someone who runs `docker run -p 8000:8000` on a public host is therefore
serving the API in cleartext, and the image's three lines are what make that
the default rather than an operator's explicit choice.

The container-side deviation is nonetheless the right engineering answer.
**(1)** A container that binds only loopback answers nobody, which is R77's own
reason for handing the `0.0.0.0` line to this item. **(2)** Every deployment
target a container image is aimed at — Kubernetes ingress, a reverse proxy,
Cloud Run, a load balancer — terminates TLS in front of the container as its
normal mode, which is why the owner reference's own Variant A Dockerfile also
exposes cleartext. **(3)** The only TLS-bearing alternative this item owns is a
second process inside the image (option c below), which contradicts member 3.
The cost is real and is stated: an operator who exposes this container directly
to the internet gets a cleartext API and nothing in the image warns them, which
is why the README paragraph in option (a) is part of the recommendation rather
than a nicety.

**Options** — the ones this item owns. In-process TLS is not among them: it is
R77's option (b), decided there.

| | Option | Effect | Conformance |
|---|---|---|---|
| a | **Recommended.** Keep the three lines; the README states in terms that the container is an **origin server** that MUST sit behind a TLS-terminating ingress, and that exposing it directly is nonconformant with R8.1; the owner records `OV-14` as approved together with R77's `OV-04` | zero bytes, zero dependencies, matches every mainstream deployment shape and the owner reference's own container | Deviates from one MUST, recorded and approved per R1.7, as the container-side half of `OV-04` |
| b | Omit `ENV RSLBP_WEB_HOST=0.0.0.0`, so the image keeps R77's loopback default and the operator must pass `-e RSLBP_WEB_HOST=0.0.0.0` | the default container is unreachable; the deviation moves to each operator's command line | Does not remove the deviation, only its default. It is the outcome R77 rejects as making "R51's container image unusable" (`:847`) |
| c | Ship a TLS-terminating sidecar or a second stage (nginx, Caddy) in the same image | conformant without touching the Rust binary | Contradicts member 3's minimum-content principle outright, multiplies the image by an order of magnitude, and puts a second network-facing daemon in a template that has one |
| d | Declare the surface `internal` tier and argue that R8.1 relaxes | no change to the artifact | Rejected on the standard's own text: §1.7 says "Every rule in this standard applies at every tier unless the rule itself states a tier scope", and R8.1 states none |

**What settles it.** The owner records `OV-14` as approved — naturally in the
same ruling as R77's `OV-04` — or selects (b), (c) or (d). Until then the
deviation is **requested, not granted**, exactly as `OV-01` was recorded before
its refusal.

#### Conformance note — the rows this item creates

Recorded in the standard's own §1.9 template, and **provisional**: this item owns
no endpoint, so the tier, the switches and the rest of the deviation list belong
to the template as a whole. R69 owns the surface; R80's rows are already written;
R70 to R76 each add their own.

The note's own heading is written one level down, as `###`, so that this file
carries exactly the four H2 headings of a decision even inside a fence (`S3b`);
where the note is assembled, its heading takes whatever level the template's
document needs.

```markdown
### Conformance note — rs-launch-blueprint optional web surface (R51 rows only)

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
- OV-14 · MUST (R8.1) · container-side companion of R77's OV-04 (the plaintext
  listener): the image sets RSLBP_WEB_HOST=0.0.0.0, exposes 8000, and its own
  HEALTHCHECK probes http:// on loopback, so a started container serves
  cleartext on all interfaces by default · a loopback-only container answers
  nobody, and TLS for a deployed image is terminated by the ingress in front of
  it; whether the server itself terminates TLS is R77's OV-04, not this row ·
  approver: PENDING OWNER · date: PENDING

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
  it. R80's revision 3 resolves the path to `/healthz` (`S10s`); if it moves,
  this `HEALTHCHECK` line moves with it.
- **The port and host variable names and defaults** are R77's. This decision
  reads `RSLBP_WEB_HOST` and the `8000` default from R77's revision 3 (lines 931
  and 678, `S10e`, `S10f`), which is `open` and not yet audited, and restates
  neither.
- **The R8.1 listener deviation** is R77's `OV-04`; this item records
  only the container-side `OV-14` above.
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

re-verify: when R69 republishes `web-extra-surface` and the registry row moves from revision 9's `src/web/` bytes to revision 10's `crates/web` form (check `S10d` fails the moment it does, and the `- assumes` line and every path here must then be re-checked); when R80 publishes or moves the liveness path off `/healthz` (check `S10s`); when R77 moves off revision 3 (check `S10j` fails on any byte change), is audited, publishes, or changes `RSLBP_WEB_HOST`, `RSLBP_WEB_PORT` or the `8000` default, any of which changes the `HEALTHCHECK` literal and `EXPOSE`; when the owner rules on R77's `OV-04`, which `OV-14` accompanies, or R69 adopts an in-process TLS terminator, which withdraws both; when R11 republishes `ci-job-structure` off revision 7 (checks `S10g`, `S10m`) or R12 decides whether the image job is a required status; when R19 adds the `docker` ecosystem, which is this item's own hand-off landing; when R08 publishes its permission model, which prices the publish-on-release alternative properly; when R68 publishes or changes `[profile.release]` or its follower-mode release flow; when the owner rules on `OVERRIDE (OV-14)`, or on whether fitness gate 2 reaches non-linked developer tools, or when `cargo-chef` ships a release declaring `rust-version` — either of the last two readmits member 1's runner-up (checks `D5b`, `G1b`); when any of the three pinned digests stops resolving (checks `D1a`, `D2a`, `D3a` fail on the spot) — a re-pushed tag alone is not a trigger, it is logged as an `observed-tag-digest` line; when `rust:1.98.1-slim` stops sharing the trixie tag's digest (check `D1b`); when distroless publishes `cc-debian14` or retires `cc-debian13` (check `D3-nonroot`); when Rust stable advances far enough that the `msrv-policy` floor passes 1.96 (check `D4b`); when the org REST API Design Standard moves off blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, which invalidates every `:<line>` citation in `### Conformance with the REST API Design Standard v2.0.0` (check `S8a` fails immediately); or by **2027-03-18**, six months from the original research date, whichever comes first

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
executed against — uses **revision 10's `crates/web` form**, together with the
four-package topology of R02's revision 2
(`research/runs/R02/…/review/DECISION.md:22`, `S10t`, `S10u`; R02 is `open` in
`research/CLAUDE.md`, so this is a coupling to a proposal). The registry bytes are preserved
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
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`.

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

**Toolchain and host.** Host `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)` and
`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, used only to generate the
stand-in's `Cargo.lock`; the image itself compiles with the pinned
`rust:1.98.1-slim-trixie` builder. macOS `Darwin 25.4.0 arm64`; Docker server
**29.8.0** with the containerd image store; `buildx v0.37.1`; a dedicated
BuildKit **v0.32.2** builder (`docker-container` driver) that the container
script creates and removes; daemon platform **`linux/arm64`**;
`/usr/bin/grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`; `curl 8.7.1`;
`ShellCheck 0.11.0` (`shellcheck.log`). Working directory for every script:
`research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence`. Run dates
2026-09-27T00:48Z (registries), 2026-09-27T00:56Z (container) and
2026-09-27 (sources; the exact minute is its log's `date-utc` line) (sources), which is 2026-09-26 in the programme's own timezone.
Revision 1's runs were on 2026-09-19 with Docker 29.5.2; its container and
sources logs are kept as `r51-container.r1.log` and `r51-sources.r1.log`.

**Nothing was implemented.** The template does not exist; P03 builds it. What was
built is a disposable four-package stand-in matching R02's revision-2 topology —
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
than merely declared. Every image, container and builder the script created was
removed; **no image was pushed anywhere**.

**Two changes to how the container script runs, both disclosed.**

1. **An isolated builder.** Revision 1 built on Docker's default builder and ran
   `docker builder prune -af`, which empties that builder's cache for every
   project on the host. Revision 2 builds through `docker buildx build --builder
   r51-<suffix> --load` on a builder it creates, prunes only that builder, and
   removes it on exit; containers, tags and the host port carry a per-run suffix.
   The Dockerfile under test is unchanged. The CI recommendation in member 5
   stays `DOCKER_BUILDKIT=1 docker build`: both paths run the same BuildKit
   frontend, and the cache-mount behavior measured by `C4`/`C5` is BuildKit's.
2. **What "image size" means.** On Docker 29.8's containerd image store,
   `docker image inspect --format '{{.Size}}'` reports disk usage — compressed
   content plus the unpacked snapshot — so the first revision-2 run measured the
   selected image at 57,769,770 B and failed `C2g` and `C9a`
   (`r51-container.r2-inspect-size.log`, `PASS=52 FAIL=2`). Revision 2 therefore
   measures the **sum of the compressed layer sizes in the image manifest**, read
   from `docker save`, which is the bytes a registry pull transfers and does not
   depend on the store. That quantity reproduces revision 1's figures within
   0.1 % (12,302,310 B against 12,312,852 B), which shows revision 1's
   `inspect .Size` on Docker 29.5.2 was reporting the same content size. Disk
   usage is still logged, as `measured-disk-usage-*`, and not asserted.

**The four scripts, their commands, and their results.**

```
$ cd research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence
$ ./r51-container.sh   > r51-container.log  2>&1   # → SUMMARY: PASS=54 FAIL=0 SKIP=0 TOTAL=54, exit 0
$ ./r51-registries.sh  > r51-registries.log 2>&1   # → SUMMARY: PASS=32 FAIL=0 SKIP=0 TOTAL=32, exit 0
$ ./r51-sources.sh     > r51-sources.log    2>&1   # → SUMMARY: PASS=132 FAIL=0 SKIP=0 TOTAL=132, exit 0
$ ./r51-reproduce.sh   > reproduction.log   2>&1   # → reproduction-exit: 0
```

Revision 1 reported the sources script only as "see the summary line in that
log". That line read `SUMMARY: PASS=101 FAIL=5 SKIP=0 TOTAL=106`
(`r51-sources.r1.log`), and revision 1 did not say so. The five failures were
`S3b`, `S4a`, `S9b`, `S10e` and `S10f`; each is repaired above and each passes
now.

Each script sets `set -euo pipefail` on its first executable line, calls
`/usr/bin/grep` by absolute path and logs that grep's version, asserts on
**content** rather than on an exit code, and exits non-zero on any `FAIL`. The
three check scripts count `PASS`/`FAIL`/`SKIP` and print a `SUMMARY:` line
whose three numbers sum to the total. `shellcheck -S warning` over all four
scripts exits **0** with no findings (`shellcheck.log`, asserted by `S16b`).

| Script | What it proves | Checks |
|---|---|---|
| `r51-container.sh` | the recommendation, built and run | `C0a`, `C1a`–`C1b`, `C2a`–`C2g`, `C3a`–`C3f`, `C4a`–`C4b`, `C5a`–`C5c`, `C6a`–`C6b`, `C7-*`, `C8-*`, `C9a`–`C9b`, `C10a`–`C10b`, `C11a`–`C11b`, `C12a`, `C13a`–`C13c`, `C14a`, `C15a`–`C15l` |
| `r51-registries.sh` | every live figure this decision carries | `D1a`–`D1e`, `D2a`, `D3a`–`D3c`, `D3-*`, `D4a`–`D4b`, `D5a`–`D5e`, `D6a`–`D6b`, `G1a`–`G1d`, `G2a`–`G2e`, `G3a` |
| `r51-sources.sh` | every repository citation, the parameter lines and this file's own shape | `S1-*`, `S1d`–`S1g`, `S2a`–`S2f`, `S3a`–`S3g`, `S4a`–`S4b`, `S5c`–`S5d`, `S6a`–`S6e`, `S6-*`, `S7a`–`S7e`, `S7-*`, `S8a`–`S8k`, `S9a`–`S9g`, `S9-*`, `S10a`–`S10u`, `S10-*`, `S11a`–`S11d`, `S11-*`, `S12a`–`S12e`, `S13a`–`S13d`, `S14a`–`S14f`, `S15a`–`S15l`, `S16a`–`S16b`, `S16-*` |
| `r51-reproduce.sh` | that the committed logs reproduce | reruns the registries and sources scripts and diffs them; compares the container log with revision 1's |

**Observed values, in the form an auditor can diff.** The container log carries
each figure on its own `measured-` line: image **12,302,310 B**; the same image
without the probe **11,489,706 B**, so busybox costs **812,604 B**; the
`debian:trixie-slim` + `curl` + `ca-certificates` + `useradd` equivalent
**36,869,229 B**; the serve binary **1,271,368 B**; incremental rebuild wall time
**10 s** with cache mounts against **17 s** without. `docker image inspect`
returned `User=nonroot:nonroot`, `Entrypoint=/usr/local/bin/rslbp-serve`,
`Healthcheck.Test=CMD /bin/busybox wget --spider -q -T 2 http://127.0.0.1:8000/healthz`,
`ExposedPorts=8000/tcp` and `RSLBP_WEB_HOST=0.0.0.0`. `docker top` reported PID 1
as uid **65532**; the health status reached `healthy` with `FailingStreak: 0` and
a first probe exiting **0**; an HTTP request from the host returned **200**;
`docker stop -t 10` left `ExitCode=143` with `OOMKilled=false`.

**Two checks close gaps the Opus raw report left open.** `C13` started the image
with the server bound to a port the probe does not read, with the run-time
health overrides stated at B3′: the status reached **`unhealthy`**,
`FailingStreak` reached the run's 2 retries, and the failing probe exited **1**.
`C14` asserted that `docker run --rm --entrypoint /bin/sh <image> -c true`
**fails**, which is a positive test of the minimum-content property rather than
a claim about it.

**Reproduction, and exactly what varies.** `r51-reproduce.sh` reruns the
registries and sources scripts in place and diffs each fresh log against the
committed one after removing the lines declared volatile; its output is
`reproduction.log`. The declared volatile classes are: (i) the `date-utc`,
`gh-call-*-utc`, `scratch:` and `builder:` lines, which carry a timestamp or a
`mktemp` suffix; (ii) every wall-clock figure — `C1b`,
`measured-wall-incremental-with-mounts`, `measured-wall-incremental-no-mounts` —
which is why **no check asserts a duration**, and why `C5c` asserts only the
**ordering** `with-mounts < without-mounts`; (iii) live counters asserted by
range, not value: `D3c`'s tag count, `D5e`'s download counters, and the
sources script's file counts (`override-scan-files`, `S9c`, `S6c`), which grow
as other items add files to the shared tree. Every other line — every `PASS`/`FAIL` verdict, every digest and every figure asserted by value — was identical in the fresh runs: both `RESULT` lines in `reproduction.log` read "identical outside the volatile classes", and the volatile lines of both runs are printed beside them so the filtering can be checked by eye.

The container script is not rerun by `r51-reproduce.sh`; instead the same
script's revision-2 log is compared with revision 1's log, run eight days
earlier on Docker 29.5.2. The same check ids carry the same verdicts in both.
Every byte figure moved by less than 0.1 % except one: the binary by 320 B, the
selected image by 10,542 B, the busybox delta by 867 B — the builder stage and
the two runtime images are pinned by digest, so these are layer-archive
differences between two BuildKit exporters, not content changes. The exception
is the `debian:trixie-slim` comparison variant, 40,163,283 B then 36,869,229 B:
that variant is built from the **unpinned** `debian:trixie-slim` tag with a live
`apt-get install`, so it tracks Debian's current packages. It is a comparison
point, not a recommendation, and its ratio to the selected image stays above
+190 %.

**Not run by this worker: `scripts/check-research-tree.sh`.** Revision 1 cited
a `tree-check.log` that did not exist. The tree check acquires
`research/runs/.publication.lock` (`scripts/research_cli.py:113`–`:117`), the
lock the controller's publisher holds, so a synthesis worker running it could
make a concurrent publication fail. It is therefore left to the controller's
pre-PR gate, and no claim about its result is made here.

**Checks that SKIP, by name.** A host without a Docker daemon or without `cargo`
skips `C1`–`C14` by name, printing the reason; a host without network reach skips
`D1a`–`D6b`; a host without an authenticated `gh` skips `G1a`–`G3a`; a host
without the org REST standard clone skips `S8a`–`S8k`; a host without the pinned
`py-launch-blueprint` or `ts-launch-blueprint` repositories skips `S15a`–`S15l`.
On the host that produced these logs, **nothing skipped**. Path resolution is
relative to each script's own directory.

**Rate limits and privacy.** The four `gh api` calls are separated by at least
21 seconds and each stamps its own UTC time in the log (`gh-call-1-utc`
00:48:33Z, `gh-call-2-utc` 00:48:54Z, `gh-call-2b-utc` 00:49:16Z,
`gh-call-3-utc` 00:49:37Z). `cargo-chef`'s manifest contains a maintainer's
address, so the script reads **key counts** out of it and never echoes its
contents; `S6a` and `S6b` then assert that **no** file this synthesis wrote —
this decision, the revision-1 snapshot and `evidence/` — contains an
address-shaped or token-shaped string, with `S6c` as the control that the
recursive search reaches files at all. The audit files in `review/` belong to
other actors and are outside that sweep. `S6-*`, `S6d` and `S6e` assert that the
run directory contains no `Cargo.toml`, no `Cargo.lock`, no `.rs` file, no
`target/` tree and no nested git repository. The crates.io requests identify
themselves with the repository URL, never a personal address.

**Shape validation.** `S3a`–`S3d` assert the title line, the four H2 headings in
order and nothing else, the absence of `## Supersedes`, and exactly one line
beginning `re-verify:`. `S3g` checks the expected H2 list against published
`research/topics/11-ci-workflow-job-structure/DECISION.md`, so the shape is the
published one. This file carries **no** `#####` heading and **no**
`### Members` section (`S3e`, `S3f`). Revision 1 also ran the raw-answer
validator `validate_answer_text` on this decision (`S5a`, `S5b`); that validator
governs raw answers, not decisions, so revision 2 retires those two checks and
runs it only on the two raw reports, both clean (`S5c`, `S5d`).

## Engines

Two reports are registered for this run, and both are adjudicated below.

| Engine | Report | sha256 | Registered in `manifest.json` | Research date |
|---|---|---|---|---|
| `opus` | `raw/opus.md` (1,470 lines) | `c74cb6d1e211b77a1fa427dd92246e442880d681568a849665c24c51ab99f377` | `operations.opus`, `succeeded` (`S14a`, `S14d`) | 2026-09-18 |
| `muse` | `raw/muse.md` (307 lines) | `a60d11907445c99889150f41233bf5f8f31608465bff0ba4bf3069402164fecf` | `operations.muse`, `succeeded`, collected 2026-09-22T01:34:43Z (`S14c`, `S14d`) | 2026-09-21 |

**Why Muse and not Codex.** The prompt's Focused tier pairs Codex with Opus.
Owner ruling W1-CODEX3 of 2026-09-18 deferred the Codex leg while Codex was
usage-limited (`docs/planning/p02/owner-decisions.md:488`, `S12a`). Owner
decision Q5.A of 2026-09-21 then substituted Muse for the remaining Codex legs
(`docs/planning/p02/execution-ledger.md:1114`, `S12d`). The run records that
substitution as a migration event on 2026-09-21T23:06:19Z, `from: codex` to
`muse` (`S14f`); `research/EXECUTION.json` lists R51's engines as `muse`, `opus`
(`S12e`); the prompt's mirrored line reads `- engines: muse, opus` (`S13d`); and
the manifest now holds two operations in state `collected` (`S14b`, `S14e`).
Both raw reports validate clean as bundles (`S5c`, `S5d`). Revision 1 predates
the Muse leg, which is why it listed one engine.

**Where the two reports agree.** Both ship a root `Dockerfile` for the `web`
build only and publish nothing from the template. Both carry py's
`HEALTHCHECK` timings `30s`/`3s`/`5s`/`3` verbatim. Both build with
`cargo build --release --locked --features web --bin <serve>`. Both keep a
glibc runtime and reject `alpine`, musl and `scratch` on the owner reference's
ground. Both require a non-root runtime user. Both keep `target/` out of the
build context. Both find that cargo-chef 0.1.78 declares no `rust-version`, that
rustsec.org has no page for it, and that its ten most recently opened issues are
all unanswered. Neither raises a `CONFLICT:` line, and neither raises a
`BASELINE-REVIEW:` line.

**Where they disagree, and what resolves each disagreement.** Muse recommends a
different stack on every build member. Each difference is settled below by an
owner ruling, an owned value of another item, or a check executed in this run —
not by preferring one engine.

| # | Topic | Muse's position (`raw/muse.md`) | This decision | What resolves it |
|---|---|---|---|---|
| E1 | Dependency caching | cargo-chef planner/cook is **required**; cache mounts are an optional supplement. Gate 2 read as not binding because "chef ships no code into the template" (`:150`, `:170`) | BuildKit cache mounts only; cargo-chef excluded by gate 2 | **An owner ruling.** Gate 2 is read strictly: an undeclared `rust-version` "is insufficient evidence to PASS a gate the prompt says must be passed" (`execution-ledger.md:414`, `S12c`). Muse's lenient reading is exactly the reading the owner withdrew; this decision records it as the strongest counter-argument and hands it back as a re-verify trigger. The mechanism is also measured: a source-only edit recompiles **0** third-party crates with mounts and **50** without (`C4b`, `C5b`) |
| E2 | Runtime base | `debian:trixie-slim` with installed `curl` and `ca-certificates`; distroless is the ranked runner-up, which "wins on size and CVE signal" (`:27`, `:174`) | distroless `cc-debian13:nonroot` | **Measured.** Muse's runtime was built and run here (`C10a` healthy, `C10b` non-root). It is **+199 %** larger by compressed layer content (36,869,229 B against 12,302,310 B, `C9b`), and carries `sh`, `apt` and `curl`, which the selected runtime lacks (`C8-*`, `C14a`). Muse's only argument against distroless is the probe, settled by E4 |
| E3 | Non-root identity | `groupadd`/`useradd`, uid **10001**, `USER app` (`:170`) | the base's built-in uid **65532** `nonroot` | **Measured, and both are non-root.** PID 1 runs at uid 65532 (`C3a`); the built-in identity exists in both suites (`C7-*`). The built-in user removes one mutable layer. Muse's choice is correct for Muse's runtime, which ships no such user |
| E4 | `HEALTHCHECK` form and tool | shell-form `CMD curl -f http://localhost:${PORT:-8080}/healthz \|\| exit 1`; a static probe binary on distroless has "no surveyed reference or maintained implementation" (`:220`, `:232`) | exec-form `/bin/busybox wget` from a digest-pinned `busybox:1.38.0-musl` | **Executed.** The selected probe reaches `healthy` (`C3c`–`C3e`), detects a dead listener with exit 1 (`C13a`–`C13c`), and costs 812,604 B of compressed content (`C9a`). Muse's gap was a survey gap; this run's fixture is the implementation. Muse's own `HEALTHCHECK` was not executed by Muse (its P1–P5 are "specified, NOT executed", `:297`) |
| E5 | Probe port and host | `${PORT:-8080}` on `localhost`, both flagged as conditional on R77 (`:66`) | literal `8000` on `127.0.0.1` | **Another item's value.** R77's revision 3 names `RSLBP_WEB_PORT` with default `8000` (R77 `:678`, `S10f`); there is no `PORT` variable. py probes `127.0.0.1:8000` for the same no-resolver reason (`S15e`) |
| E6 | cargo-chef maintenance | `active`: releases current; "10/10 most recent issues unanswered", read as triage-quiet (`:31`, `:291`) | `at-risk` on the same 10-of-10 signal | **The facts now agree; the label is an interpretation.** This run re-read the rubric's own sample: the same ten issue numbers, all at 0 comments (`G2d`, `G2e`). Revision 1's "6 of 6" was a mixed items sample, and is superseded. The prompt's rubric says "`at-risk` needs a concrete signal"; ten unanswered issues across five months is one, which is why this decision keeps `at-risk`. **The difference is not load-bearing**: gate 2 excludes cargo-chef in either state |
| E7 | CI placement | deferred to R11, R50 and R68 (`:284`) | its own workflow file | **Published R11**, revision 7: "No container or deploy job enters `ci.yml`" (`research/topics/11-…/DECISION.md:270`, `S10g`) |

**What changes because of the Muse report, even though the recommendation does
not.** (1) The maintenance sample is now the rubric's ten issues rather than six
(E6). (2) The adopter evidence for cargo-chef is broader than revision 1 said:
Muse reports Qdrant and Lemmy use chef stages on a `debian-slim` runtime with a
created user, Meilisearch uses neither chef nor a non-root user, Depot's guide
combines chef with cache mounts and `sccache`, and **none of those four declares
a `HEALTHCHECK`** (`:17`). That strengthens member 1's statement that chef's
adoption is real and concentrated among web servers, and it sharpens member 4:
the in-image probe is F337's requirement and Docker's documented feature, not
the surveyed adopters' habit. `atuinsh/atuin` (Opus) remains the one surveyed
adopter that declares one. (3) Muse's point that cache mounts give no layer-level
separation on a **cold** builder is correct and already priced: it is why
`reproducible-containers/buildkit-cache-dance` is member 1's up-and-comer and
why a persistent cache is one of the runner-up's three winning conditions.

**Re-verified in this run, at the source, by a named check.**

| Claim | Check | Result on 2026-09-27 |
|---|---|---|
| The three pinned base-image digests resolve | `D1a`, `D2a`, `D3a`, control `D1e` | all three HTTP 200; the all-zero digest 404. The `rust` and `busybox` tags have been re-pushed since revision 1 (logged `observed-tag-digest` lines); the `cc-debian13:nonroot` tag still points at the pin |
| `rust:<ver>-slim` means **trixie** | `D1b`, `D1c` | `slim` and `slim-trixie` share a current digest; `slim-bookworm` differs |
| The runner-up bookworm builder pin resolves | `D1d` | HTTP 200 |
| The `cc-debian13` line exists and publishes `:nonroot` | `D3b`, `D3c`, `D3-*` | 6,156 tags, `:nonroot` a multi-arch OCI index |
| Stable is 1.98.1 and the floor is 1.96 | `D4a`, `D4b` | confirmed at the Rust project's channel file |
| `cargo-chef` 0.1.78 declares no `rust-version` | `G1b` (control `G1c`), `D5b` | confirmed at tag `v0.1.78`; crates.io `rust_version` is `null` |
| Its maintenance signal | `G2d`, `G2e`, `G3a` | 10 of 10 sampled issues at 0 comments; 35 open issues |
| No open RustSec advisory | `D6a`, `D6b` | 404 where the `atty` control returns 200 |
| Every container check, rerun on a newer Docker | `C1`–`C15` | `PASS=54 FAIL=0 SKIP=0`; every check id carries the same verdict as in revision 1's run — see `## Empirical check` for what moved |
| The cache-mount benefit against a deleted-mount counterfactual | `C4b`, `C5a`–`C5c` | 0 third-party crates rebuilt with mounts, 50 without |
| The busybox `HEALTHCHECK`, built and probed | `C2c`, `C3c`–`C3f`, `C13a`–`C13c` | confirmed, including the failure path |
| py publishes and verifies no image; ts has none | `S15i`–`S15l` | confirmed at both pins |
| The five `- assumes` values against the live registry | `S2c` | diff empty |
| The REST standard's blob id and quoted lines | `S8a`–`S8k` | confirmed by hashing the file and reading each line |
| R77, R80, R11, R02 and the ledger at the lines cited | `S9b`–`S9g`, `S10e`–`S10u` | every line holds at the revision named |

**Carried from a raw report without independent verification, and named so an
auditor can see what rests on one engine.** From Opus: the four surveyed adopter
Dockerfiles (`atuinsh/atuin`, `LemmyNet/lemmy`, `astral-sh/uv`,
`meilisearch/meilisearch`) and their star counts, read on 2026-09-18; the
`moby/buildkit` `v0.26.1` reference quotations; the Kubernetes `pod-lifecycle`
page's zero `healthcheck` matches; the `GoogleContainerTools/distroless` and
`docker/build-push-action` repository figures; the
`reproducible-containers/buildkit-cache-dance` README sentence; and the owner
reference's musl and alpine caveats, which neither engine measured. From Muse:
the Qdrant, Lemmy, Meilisearch and Depot Dockerfile readings and star counts
(`:17`), the `lukemathwalker/cargo-chef` Docker Hub pull count 5,649,508, the
OSV query returning `[]`, the cargo-chef issue #322 flag-parity statement, and
the hadolint run (`:295`). Where the two engines read the same fact
independently — the adopters Lemmy and Meilisearch, chef's missing
`rust-version`, the rustsec.org 404, the unanswered issues — they agree.

**The Opus raw report's own statements corrected here, each with the evidence
that moved it.**

1. **The port and the host variable.** The Opus report used `ENV PORT=8080` and
   probed `http://127.0.0.1:8080/healthz`, calling both placeholders pending R77.
   R77's revision 3 names the variables `RSLBP_WEB_HOST` and `RSLBP_WEB_PORT`,
   sets their defaults to `127.0.0.1` and **8000** (`:678`, `S10f`), and assigns
   *this item* the line `ENV RSLBP_WEB_HOST=0.0.0.0` in terms (`:931`, `S10e`).
   The fixture and every executed check use 8000 and the R77 names. py's own image
   exposes 8000 and probes 8000 (`S15c`, `S15e`), so the correction also brings
   the Rust image back into line with its source precedent.
2. **The CI job's placement.** Both reports deferred it to R11. R11's published
   revision 7 says no container job enters `ci.yml` (`S10g`), so member 5 places
   the job in its own workflow file on R11's own rule, and hands the
   required-status question to R12.
3. **The probe's own timeout.** The Opus report's executed image carried `-T 3`
   while its prose recommended `-T 2`; the fixture and this run carry `-T 2`
   (`C15e`).

**Figures that did not reproduce exactly, and why none changes a conclusion.**
Revision 1 recorded two of the Opus report's figures as not reproducing: its `debian-slim` comparison measured **35,680,357 B** (+189.8 %), and its cache-mount benefit was **50.8 %** of *cargo* time (21.80 s → 10.72 s). This run measures the `debian-slim` variant at **36,869,229 B** (+199 %) — it also installs `ca-certificates`, which the selected runtime supplies for free, and it tracks an unpinned tag — and the rebuild at **10 s** against **17 s** of *wall* time. Neither figure is load-bearing: what decides member 1 is `C4b`'s **0** against `C5b`'s **50**, which is a count, not a duration, and what decides member 3 is a size ratio that has stayed near three to one in every run.

**What P03 must validate, because this run could not.**

1. **Every check above, re-run on `ubuntu-latest` for `linux/amd64`.** Nothing
   here proves the amd64 build, and the byte sizes in particular will differ.
2. **The image job inside a real GitHub Actions workflow**, in the slot R11
   describes and with R12's answer on required status — no workflow was executed
   here, so every CI claim in this decision is a proposal.
3. **A property assertion that the workflow contains no `docker/login-action` and
   no `push: true`**, so "we do not publish" is a checked property rather than a
   convention.
4. **`cargo build --release --locked --features web --bin rslbp-serve` at the
   repository root outside Docker**, asserting that the image build and the host
   build are the same command against the real template.
5. **The `.dockerignore` against the real tree**, which will contain files this
   stand-in did not.
6. **A slow-endpoint probe**, showing that busybox's `-T 2` fires before the
   instruction's `--timeout=3s` (member 4 asserts only the two literals).
7. **`C13` against the fixture's own timings** (`--retries=3`, `--interval=30s`),
   which this run shortened.

**Evidence gaps, stated rather than papered over.** Chainguard's free tier's
versioned-tag availability was not checked by either engine, so that base-image
candidate is recorded as a gap rather than ranked. `GoogleContainerTools/distroless`
issue responsiveness was not sampled, only its open-issue count. The musl and
alpine costs the owner reference asserts were not measured. No benchmark of the
running service was taken, and none is claimed. The `unsafe` posture of
`cargo-chef` was not audited — it is a build-time binary that never links into
the shipped artifact. Muse's open question whether the RustSec notices filed as
cargo-chef issues #365 and #366 affect 0.1.78 is not resolved here; it bears on
an excluded candidate only. **A clean-extraction rerun was not performed**:
`review/`, the Muse leg and the run's modified `manifest.json` and `prompt.md`
are not committed, so a `git archive HEAD` extraction cannot contain the inputs
the scripts read; once the controller commits them, that rerun is a publication
step.

**Reconciliation with the owner-supplied reference architecture**
(`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, a **standing
input** under `docs/planning/p02/owner-decisions.md` section 11 — not a standard
and not a pre-decision; its own Caveats record that its patterns were "compiled
in my head, not against the toolchain"). Twelve rows touch this item.

| Reference row | Reference says | This decision |
|---|---|---|
| C15 base family | "distroless/cc-debian12" over "musl/scratch; alpine" | **Agree**, and independently measured: 12,302,310 B against 36,869,229 B (`C9b`). Muse differs from the reference here and recommends `debian:trixie-slim` (`## Engines`, E2) |
| C15 exact suite | "Recommend **distroless/cc-debian12**" | **Differ, on sourced ground.** `cc-debian13` publishes `:latest` and `:nonroot` (`D3c`, `D3-*`) and `rust:<ver>-slim` already means trixie (`D1b`); pairing trixie with `cc-debian12` crosses suites for no benefit |
| C15 / C14 `cargo-chef` | "Build with cargo-chef"; C14 lists "bacon + **cargo-chef** + mold" | **Differ, on gate and on measurement.** No `rust-version` at tag `v0.1.78` (`G1b`), excluded under the strict reading (`S12c`); cache mounts cut the rebuild from 50 recompiled crates to 0 (`C4b`, `C5b`) with no third-party tool. Muse agrees with the reference on chef; `## Engines` E1 adjudicates |
| C15 run as `nonroot` | "run as `nonroot`" | **Agree**, measured: PID 1 at uid 65532 (`C3a`); `id` in the base returns `uid=65532(nonroot)` (`C7-cc-debian13`) |
| C15 `bind PORT (default 8080)` | "bind `PORT` (default 8080)" | **Differ, on another item's value.** R77's revision 3 names `RSLBP_WEB_PORT` with default **8000** and `RSLBP_WEB_HOST` with default `127.0.0.1` (R77 `:678`, `S10f`), which is also py's port. R77 is `open`, so this row moves with it. The Opus raw report recorded this row as agree-as-placeholder |
| C15 `/healthz (liveness)` | "expose `/healthz` (liveness)" | **Agree** that the `HEALTHCHECK` probes the liveness path; the path's own value and behavior are R80's |
| C15 `/readyz (readiness, checks DB)` | "`/readyz` (readiness, checks DB)" | **Not this item's row** — section 11 assigns C15 probes to **R80**. Recorded as a hand-off. Noted for R80: this template has no database, so "checks DB" has nothing to check here |
| Variant A `FROM lukemathwalker/cargo-chef:latest-rust-slim` | an unpinned `latest-` tag | **Differ, on sourced ground.** B5 and R20's pinning principle (`S11c`) both require a digest; the reference's own Caveats flag its unpinned versions as "verify". All three `FROM`s here carry `@sha256:` (`C15b`) |
| Variant A final-stage shape | `FROM gcr.io/distroless/cc-debian12` / `COPY --from=builder … /app` / `USER nonroot:nonroot` / `ENV PORT=8080` / `ENTRYPOINT ["/app"]` | **Agree** on the shape, line for line, with the suite and digest changed per the rows above, the port and variable name per R77, and the binary installed at `/usr/local/bin/rslbp-serve` rather than `/app` |
| Neither variant carries a `HEALTHCHECK` | no `HEALTHCHECK` instruction in Variant A or B | **Differ.** F337 records the capability and Docker Engine, Compose and Swarm consume it. The reference's omission is consistent with its Cloud Run target, where platform probes replace it; this template's target is unconstrained |
| C14 `mold` linker | "mold/lld linker for faster link" | **Not adopted, and recorded rather than silently dropped** — see `### What this decision does not decide`. R69 hands it to R51/R68, R68 declared it out of scope, and this item declines it because a linker swap inside a Dockerfile would make the container binary differ from the released one |
| Cloud Run deployment, Variant B `node:20`/Vite stage, `SQLX_OFFLINE`, Artifact Registry, `gcloud run deploy` | a full GCP deployment path | **Inapplicable.** Section 11 records these as rows with no P02 item, "NOT decided and NOT researched by this instruction". This template has no database, no frontend build and no cloud target |

**Tally: 4 agree, 5 differ (each on a measured figure, a published endpoint or
another item's value), 2 hand-offs (C15 `/readyz` → R80; C14 `mold` → R68, which
declined it), 1 inapplicable.** That is twelve rows. The Opus raw report's tally was
4 agree / 4 differ / 1 agree-as-placeholder / 2 hand-offs / 1 inapplicable; the
placeholder row moved into `differ` when R77 set its port default, and the
row count is unchanged.

**Sources.** Primary specifications: the BuildKit Dockerfile frontend reference at
`moby/buildkit` tag `v0.26.1`
(`https://raw.githubusercontent.com/moby/buildkit/v0.26.1/frontend/dockerfile/docs/reference.md`,
cache-mount options and persistence contract at lines 843–892, `HEALTHCHECK`
forms and exit-code contract at lines 2819–2880, retrieved 2026-09-18 by the Opus
raw report); the Kubernetes `pod-lifecycle` page source
(`kubernetes/website`, `content/en/docs/concepts/workloads/pods/pod-lifecycle.md`,
retrieved 2026-09-18 by the Opus raw report); `https://static.rust-lang.org/dist/channel-rust-stable.toml`
(retrieved 2026-09-27T00:48Z here). Registry and package endpoints, each re-read
here on 2026-09-27: `https://hub.docker.com/v2/repositories/library/rust/tags/{1.98.1-slim-trixie,1.98.1-slim,1.98.1-slim-bookworm}`
and `…/library/busybox/tags/1.38.0-musl` (current tag digests, logged);
`https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/{rust,busybox}:pull`
(anonymous pull token) and `HEAD https://registry-1.docker.io/v2/library/{rust,busybox}/manifests/<digest>`
(pinned-digest resolution — the OCI distribution endpoint behind the Hub tag
pages, added in revision 2); `https://gcr.io/v2/distroless/cc-debian13/{manifests/nonroot,manifests/<digest>,tags/list}`;
`https://crates.io/api/v1/crates/cargo-chef` and `/versions`;
`https://rustsec.org/packages/{cargo-chef,atty}.html`. GitHub REST through a
keyring-authenticated `gh`, one call per ≥21 s, each stamped:
`repos/LukeMathWalker/cargo-chef/contents/Cargo.toml?ref=v0.1.78`,
`repos/LukeMathWalker/cargo-chef/issues?state=all&sort=created&direction=desc&per_page=10`,
`search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue&sort=created&order=desc&per_page=10`
(the rubric's ten-issue sample, added in revision 2),
`search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue+is:open`. Pinned source
repositories, read only through their pins: `py-launch-blueprint` at `b08bccfb`
(`Dockerfile`, `.dockerignore`, `Justfile:317-318`, the `.github` searches) and
`ts-launch-blueprint` at `cb1cbcb2` (the empty container-path listing). Raw
reports: `raw/opus.md` (sha256 `c74cb6d1…`) and `raw/muse.md` (sha256
`a60d1190…`), both registered in `manifest.json`. Programme records:
`docs/port/COMMONALITY.md` F017 `:23`, F223 `:227`, F303 `:307`, F328 `:332`,
F336 `:340`, F337 `:341`; `docs/port/BASELINE-REVIEW.md` `:39`;
`docs/port/areas/web-service.md` `:43`; `docs/port/PARAMETERS.md`;
`docs/port/OWNER-REVIEW.md` (Q7.B, W2-REST);
`docs/planning/p02/execution-ledger.md` `:414`, `:1073`, `:1074`, `:1082`,
`:1083`, `:1086`, `:1114`; `docs/planning/p02/owner-decisions.md` `:488` and
section 11; `research/EXECUTION.json` (`engine_overrides.R51`);
`scripts/research_cli.py` `:113`–`:117`. The org REST API Design Standard v2.0.0
at blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, lines 271, 1019, 1271, 1317,
1320, 1323, 1329–1351, 1356 and 1387. Published decisions:
`research/topics/11-ci-workflow-job-structure/DECISION.md` revision 7 (`:1`,
`:165`, `:270`, `:297`), `research/topics/19-dependabot-config-shape/DECISION.md:66`,
`research/topics/49-build-target-declaration/DECISION.md`,
`research/topics/20-third-party-action-pinning-policy/DECISION.md`,
`research/topics/17-secret-scanning-ci-workflow/DECISION.md`,
`research/topics/18-ai-assisted-review-workflows/DECISION.md`,
`research/topics/25-semver-bump-strategy/DECISION.md` and
`research/topics/26-packed-artifact-content-guard/DECISION.md` (the last two read
for consistency; this item creates no obligation on either). Unpublished
decisions, each at the revision named: R69 revision 10, owner-accepted
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`);
R68 revision 1 (`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md:32`);
R77 revision 3, `open`
(`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md:1,678,806,827–828,840–845,847,863–864,931`);
R80 revision 3, `open`
(`research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md:1,548`);
R02 revision 2, `open`
(`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md:1,22`);
R05, R54, R56, R57.
