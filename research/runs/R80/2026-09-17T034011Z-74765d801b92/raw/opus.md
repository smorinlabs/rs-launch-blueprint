# R80 — health-probe-endpoints (bundle, Focused) — Opus raw research report

Engine: Claude Opus 5. Run `research/runs/R80/2026-09-17T034011Z-74765d801b92/`.
Retrieval date for every figure and quotation below is **2026-09-18 (UTC)** unless the
line states otherwise; each figure carries its endpoint. Source-repository reads are
through the programme pins — `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`
(written `py@b08bccfb`) and `ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`
(`ts@cb1cbcb2`) — never from a working tree.

The Codex leg for this item is deferred (owner ruling W1-CODEX3, 2026-09-18), so this
report is written to stand alone for the synthesizer.

### Landscape

**The category this item decides.** Not a library choice. It is the *contract* of two
unversioned HTTP endpoints — what each returns, when each fails, and which code path both
share with the CLI — plus the question of whether any crate is needed to produce them. The
survey below is therefore a census of two fields at once: the orchestrator-side standard that
defines what a probe *means*, and the Rust-side supply of anything that implements it.

**Three-bin map of the Rust field.**

| Bin | Candidates found | What each would supply |
|---|---|---|
| **Built-in / first-party toolchain** | `std::env::consts::{OS, ARCH}`; Cargo's compile-time `env!("CARGO_PKG_VERSION")`; `std::sync::atomic::AtomicBool`; `std::time::Instant`; axum 0.8.9's `MethodRouter`, `StatusCode` and `Json` (first-party to the framework R69 selected); `tokio::task::spawn_blocking` 1.53.1 | the whole recommendation: build identity, the readiness latch, routing, status codes, and the sync→async bridge |
| **Established industry standard** | the **Kubernetes probe contract** (`livenessProbe` / `readinessProbe` / `startupProbe`, `httpGet` success = HTTP 200–399); the **gRPC Health Checking Protocol** as shipped by `tonic-health` 0.14.6 (11,044,769 recent downloads); **RFC 9457** problem documents (R70's); `serde` 1.0.229 as the serialization standard; the build-metadata family `built` 0.8.1, `vergen` 10.0.3, `shadow-rs` 2.0.0, `git-version` 0.3.9 | the semantics the endpoints must satisfy; the payload types; optional build metadata |
| **Up-and-comer** | **effectively empty for HTTP probes.** `rocket_healthz` 0.5.0 (1,281 recent downloads, `updated_at` 2024-05-21) is the only crate on crates.io whose name and description are specifically an HTTP health endpoint. `kubert` 0.25.0 (15,970 recent downloads) is a Kubernetes *runtime* helper that happens to ship an admin server with `/live` and `/ready` | nothing this template would depend on |

Endpoint for every download and `updated_at` figure in that table:
`GET https://crates.io/api/v1/crates?q=<term>&per_page=12&sort=downloads` and
`GET https://crates.io/api/v1/crates/<name>`, both 2026-09-18.

**The census that answers the prompt's LOW question, with its denominator.** Five crates.io
searches were run — `q=health+check`, `q=readiness`, `q=healthz`, `q=kubernetes+probe`,
`q=axum+health` — plus three single-word sweeps, `q=health` (`meta.total` **6,487**),
`q=probe` (`meta.total` **5,271**) and `q=liveness` (`meta.total` **28,351**), each sorted by
downloads and read to twelve results. **No crate in any of those result sets is a first-class
HTTP liveness/readiness library with meaningful adoption.** What the top of each list actually
contains is connection pools advertising a "health check" on a pooled connection (`deadpool`
0.13.1, `bb8` 0.9.1, `r2d2` 0.8.10), the gRPC health protocol (`tonic-health` 0.14.6), and
crates whose only match is an unrelated English word. The strongest `q=healthz` hit is
`rocket_healthz` 0.5.0 at **1,281** recent downloads. **The absence is the finding**, and it is
consistent with what the three production systems surveyed below do: each writes its two
handlers by hand, in fewer than forty lines.

**Authorities used, and why each is authoritative.**

1. **The Kubernetes documentation** (`https://kubernetes.io/docs/concepts/workloads/pods/probes/`
   and `.../docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/`).
   Authoritative because it is the normative definition of the consumer these two endpoints
   exist to satisfy: the words "liveness" and "readiness" have no meaning in this item except
   the one the kubelet gives them. Not a blog post; the project's own reference.
2. **The Rust standard library and Cargo references** (`https://doc.rust-lang.org/std/env/consts/index.html`,
   `https://doc.rust-lang.org/cargo/reference/environment-variables.html`,
   `https://doc.rust-lang.org/cargo/reference/build-scripts.html`). First-party toolchain
   documentation for every built-in mechanism the recommendation uses.
3. **Maintainers' own documentation** for the build-metadata family — the `built`, `vergen`,
   `shadow-rs` and `git-version` READMEs and `src/lib.rs`, read at
   `raw.githubusercontent.com`. Used for one load-bearing fact each: whether the crate needs a
   Cargo build script.
4. **The RustSec advisory database** (`https://rustsec.org/packages/<name>.html`), the
   ecosystem's advisory register, used for fitness gate 3 with `atty` as a positive control.
5. **crates.io and GitHub REST APIs**, the population figures the prompt's figure table
   prescribes.
6. **Production source read at an exact URL** — three systems, below. Read, not asserted.
7. **`py-launch-blueprint` at `b08bccfb`**, the source precedent this item ports, including
   its own tests, which turn out to say something the prose does not.

**Well-regarded projects surveyed, with the evidence that they are well regarded.**

| Project | Evidence it is a relevant reference | What it does about probes |
|---|---|---|
| `rust-lang/crates.io` | operated by the Rust project itself; it is the registry this entire programme's figures come from; GitHub `stargazers_count` **3,699**, `archived` false, `pushed_at` 2026-09-18, open issues **89** (`GET https://api.github.com/repos/rust-lang/crates.io` and `GET https://api.github.com/search/issues?q=repo:rust-lang/crates.io+is:issue+is:open`). R69 revision 10 already names it as its reference implementation for the axum surface | Serves **no** `/healthz` or `/readyz`: `src/router.rs` registers `site_metadata::get_site_metadata` and `/api/private/metrics/{kind}` and no probe route. Its build identity comes from a **runtime environment variable**, not a build script — `crates/crates_io_version/src/lib.rs` documents `commit()` as reading "Heroku environment variables (`HEROKU_BUILD_COMMIT`, `HEROKU_SLUG_COMMIT`)", implemented in `crates/crates_io_heroku/src/lib.rs` |
| `olix0r/kubert` | the Kubernetes runtime crate maintained by a Linkerd maintainer; its sibling `kubert-prometheus-process` has 38,151 recent downloads (`GET https://crates.io/api/v1/crates/kubert-prometheus-process`); GitHub `stargazers_count` **182**, `archived` false, `pushed_at` 2026-08-14, open issues **7** (`GET https://api.github.com/search/issues?q=repo:olix0r/kubert+is:issue+is:open`) | `kubert/src/admin.rs` serves **`/live`** → `200` `text/plain` `"alive\n"` and **`/ready`** → `200` `"ready\n"` or **`500`** `"not ready\n"`, decided by an `Arc<AtomicBool>` **latch** (`Readiness`) with `set_ready()`; anything but `GET`/`HEAD` is `405` with `Allow: GET, HEAD`; the two paths are hard-reserved — the code panics if a caller tries to register them ("the built-in `/ready` handler cannot be overridden") |
| `apollographql/router` | Apollo's production GraphQL router; GitHub `stargazers_count` **978**, `archived` false, `pushed_at` 2026-09-18 (`GET https://api.github.com/repos/apollographql/router`) | `apollo-router/src/plugins/healthcheck/mod.rs` — "Provides liveness and readiness checks for the router". One path (default `/health`) discriminated by query string `?ready` / `?live`; two `Arc<AtomicBool>` **latches**; body is a `#[derive(Serialize)] struct Health { status: HealthStatus }` with `#[serde(rename_all = "UPPERCASE")] enum HealthStatus { Up, Down }`; failure status is **`503 SERVICE_UNAVAILABLE`**. Its own comment states the design rule verbatim: *"It's hard to get k8s to parse payloads. Especially since we can't install curl or jq into our docker images because of CVEs. So, compromise, k8s will interpret this as probe fail."* |

Note on the apollographql/router row: its open-issue `total_count` is **193**
(`GET https://api.github.com/search/issues?q=repo:apollographql/router+is:issue+is:open`,
2026-09-18), and its declared licence resolves as `NOASSERTION` through the GitHub licence
field, which is a fact about the reference project and not a fitness input — nothing in this
report depends on that repository as a dependency.

**py and ts, read at the pins, because "fit" is judged against them.** `py@b08bccfb`
`src/py_launch_blueprint/web/app.py:153` registers `@app.get("/healthz", tags=["ops"])`
returning `Health(status="ok", version=__version__, python=platform.python_version())` —
docstring *"Liveness + build info (the web analog of ``--version``)"*; line 184 `async def
readyz(` calls `run_diagnostics(config)` from `core/diagnostics.py` and, on
`report.has_error()`, returns `problem_response(..., status_code=503, ...,
extensions={"diagnostics": report.model_dump(mode="json")})`. `ts@cb1cbcb2` has neither: a
case-insensitive search for `healthz|readyz|diagnostics|doctor` across `src/` returns exactly
one file, `src/router.ts`, whose three matches are the *stderr diagnostics stream* and a
`--debug` flag description — no web service, no `doctor` command. This confirms ledger rows
F328/F329 (`py-only`, `DIVERGENT`) and F303 as recorded.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is owed.**

| Level | What must agree across py, ts and rs | Source |
|---|---|---|
| **Architectural pattern** (shared; verified below to remain appropriate in Rust) | the readiness endpoint and the CLI's `doctor` command run **the same function**, in one place, with no second copy of the check list | `py@b08bccfb` `web/app.py:49` and `cli/main.py:37` both `from py_launch_blueprint.core.diagnostics import ... run_diagnostics`; ledger F329's Note, *"one source of truth with the CLI"* |
| **Capability** | a liveness endpoint exists that reports the build's identity and is answerable without reaching any dependency | F328; `py@b08bccfb` `web/app.py:153` |
| **Capability** | a readiness endpoint exists that fails with a non-2xx status a probe reads, carrying the diagnostic detail in the body | F329; `py@b08bccfb` `web/app.py:184-198` |
| **Policy** (verbatim paths) | the two endpoints are **unversioned**: `/healthz`, `/readyz`, not `/v1/healthz` | F308, verdict `ADOPT`, ledger Note *"URL-prefix convention, trivial in any Rust router; nothing to choose"*; applied, not re-derived |
| **Nothing** — free to vary | the payload's field list; the status code for "not ready" (any code outside 200–399 works); whether readiness is computed per request or latched; the transport-level plumbing | Kubernetes only reads the status code (quoted below); the three production systems surveyed disagree on every one of these |

**What Kubernetes actually requires, quoted, because the whole contract hangs on it.**
From `https://kubernetes.io/docs/concepts/workloads/pods/probes/` (2026-09-18):

> Liveness probes determine when to restart a container. … If a container fails its liveness
> probe more times than the configured tolerance, the kubelet restarts that container.

> Readiness probes determine when a container is ready to accept traffic. … If the readiness
> probe returns a failed state, the EndpointSlice controller removes the Pod's IP address from
> the EndpointSlices of all Services that match the Pod.

> Liveness probes can be a powerful way to recover from application failures, but they should
> be used with caution. Liveness probes must be configured carefully to ensure that they truly
> indicate unrecoverable application failure, for example a deadlock. Incorrect implementation
> of liveness probes can lead to cascading failures.

> Caution: When your app has a strict dependency on back-end services, you can implement both a
> liveness and a readiness probe. The liveness probe passes when the app itself is healthy, but
> the readiness probe additionally checks that each required back-end service is available.

From `https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/`
(2026-09-18):

> Any code greater than or equal to 200 and less than 400 indicates success. Any other code
> indicates failure.

Three consequences fix the design and are not matters of taste. **(a)** Liveness failure is a
*restart*, so `/healthz` must never be able to fail for a reason a restart cannot fix — it must
reach no dependency, no lock and no pool. **(b)** Readiness failure is *traffic removal*, so
`/readyz` is the correct and only place for anything conditional. **(c)** The probe reads the
**status code**; the body is for humans and for `curl`, which is exactly what Apollo Router's
in-source comment says it learned the hard way.

**Observable acceptance criteria.** Numbered `AC1`–`AC10`. Criteria marked **executed** were
run in this report against a throwaway workspace built under `$TMPDIR` with the exact
crate versions R69 and R66 select (axum 0.8.9, tokio 1.53.1, serde 1.0.229, serde_json 1.0.151,
tower 0.5.3, edition 2024); the check ids `T1`–`T8` and `C9`–`C11` are reproduced under
`### Validation strategy`. The rest are P03's.

| # | Behavior | Observable criterion | State |
|---|---|---|---|
| AC1 | Liveness answers 200 and names the build | `GET /healthz` → `200`, body `{"status":"ok","version":…,"os":…,"arch":…}` | **executed** (`T1`) |
| AC2 | The liveness body is byte-stable for the process's life | two successive `GET /healthz` bodies are byte-identical | **executed** (`T2`) |
| AC3 | Liveness reaches no dependency | the `/healthz` handler's signature names no `State`, no pool and no port | **executed by construction** (`T1`, `T5`); enforceable in P03 by a one-line review of `routes/ops.rs` |
| AC4 | Warn-level findings do not remove traffic | a missing config file and a missing credential leave `GET /readyz` at `200` | **executed** (`T3`) |
| AC5 | An error-level finding removes traffic | a hand-built report containing one `error` check yields `503` | **executed** (`T6`) |
| AC6 | Readiness reports not-ready as soon as the drain begins | after `Readiness::begin_draining()`, `GET /readyz` → `503` | **executed** (`T4`) |
| AC7 | Draining is not a restart signal | after `begin_draining()`, `GET /healthz` is still `200` | **executed** (`T5`) |
| AC8 | Method handling is correct for a probe | `POST /healthz` → `405` with `Allow: GET,HEAD`; `HEAD /healthz` → `200` | **executed** (`T7`, `T8`) |
| AC9 | The CLI and the web service share one function | `crates/cli` and `crates/web` both call `rs_launch_blueprint_core::diagnostics::run_diagnostics`; no second check list exists — a `grep` for the check names finds them in exactly one file | P03 |
| AC10 | The probe surface disappears with the feature | a default `cargo build` produces no probe route and no `axum` in the dependency graph | **executed** (`C9`) |

**Architectural alternatives, compared before any library was considered.** This is the
substance of the item; the crate question turns out to be nearly empty.

| # | Alternative | Mechanism | Disposition |
|---|---|---|---|
| **A** | **Re-run the diagnostics on every readiness probe** — py's literal shape | `/readyz` calls `run_diagnostics(config)` per request, 503 if any check errors | **Adopted for the diagnostic half.** It is the only shape that satisfies the shared pattern ("the same function as `doctor`"), and the check set is local and cheap. Its weakness is that it says nothing about process lifecycle |
| **B** | **Latch process state in an `AtomicBool`** — kubert's and Apollo Router's shape | `/readyz` reads `Arc<AtomicBool>`; startup sets it true, shutdown sets it false | **Adopted for the lifecycle half.** Both surveyed production systems chose it independently. It is the only shape that can report *draining*, which is the state Kubernetes most needs to see |
| **C** | **A + B: latch OR'd with the shared diagnostics** | `/readyz` → 503 if draining, else run diagnostics, 503 if any check errors, else 200 | **Selected.** See the two independent arguments below |
| **D** | **Move the probes to a second listener on a second port** — Apollo Router's and kubert's deployment shape | a separate `axum::serve` on an admin address | **Rejected for this template, recorded as the scale-out path.** It buys isolation of ops traffic from request-path middleware and lets probes outlive the main server during drain; it costs a second bound port, a second `serve_until`, a second address in R77's settings and a second row in R51's container contract. py binds one port and this template ships no deployment. R75 already owns excluding the probes from access logs (F320), which is the concrete benefit D would otherwise buy |
| **E** | **Adopt a probe crate** | `rocket_healthz`, or a hand-rolled `tower` layer | **Rejected on the census above.** No crate exists at adoption worth depending on, and the surface is two handlers |
| **F** | **Speak the gRPC Health Checking Protocol** (`tonic-health` 0.14.6) | a gRPC `Health` service | **Rejected on fit, recorded because it is the one real standard in this space.** This template serves HTTP/1.1 JSON; the protocol is for gRPC servers, and adopting it would add `tonic` to a template that has no gRPC surface |

**The two independent reasons alternative C, not A, is the recommendation.**

*Reason one — the drain race is real and R69 has already built the hook for it.* R69's accepted
revision 10 puts `shutdown_signal()` and `serve_until(..)` in `crates/web/src/lib.rs`, and its
`serve_until` starts the grace clock **at the signal**. Kubernetes removes a Pod from its
EndpointSlices only once a readiness probe has *failed*, which takes at least one probe period.
**Flipping the latch is necessary but, on its own, not sufficient, and this report says so
rather than overclaiming.** Once `shutdown_signal()` resolves, `axum::serve` stops accepting,
so a kubelet opening a *fresh* connection to `/readyz` gets a connection refusal — already a
probe failure — and never reads the latch at all. A flip immediately followed by resolution
therefore changes nothing observable on a fresh-connection probe; what it changes is the answer
given on a connection that is already open. **What actually closes the race is a nonzero
pre-drain pause inside `shutdown_signal()`**: flip the latch, keep the listener open for a
readiness-propagation window during which `/readyz` answers 503 and the EndpointSlice controller
removes the Pod, *then* resolve and let the drain begin. The latch is what makes that pause do
anything — without it the endpoint would answer 200 throughout — and the pause is what makes the
latch observable to a probe. **R77 owns the window's value, and the mechanism is inert if that
value is zero.** R69 itself records the surrounding
platform datum, verified at Google's own page: Cloud Run *"sends a SIGTERM signal … indicating
the start of a 10 second period before the actual shutdown occurs, at which point Cloud Run
sends a SIGKILL signal."* Whatever window R77 chooses must hold *both* the readiness-propagation
delay and the drain inside that budget; this item fixes the mechanism and hands the number to
R77, exactly as R69 handed it the drain deadline.

*Reason two — in the ported design, the latch is the only thing that makes the 503 branch
reachable at all, and py's own test says so.* py's four checks are `python`, `platform`,
`config-file` and `token` (`py@b08bccfb` `core/diagnostics.py:47-91`). Only `python` can ever
be `error`, and only when the interpreter is older than `MIN_PYTHON = (3, 12)` — which the
package's own floor already forbids. `config-file` and `token` are `warn`. py's own test states
the consequence in a comment: `py@b08bccfb` `tests/web/test_app.py:70-75`,
`def test_readyz_returns_doctor_report`, *"# Missing token/config are warnings, not errors, so
readiness holds."* — and **there is no test in that file for the 503 branch**. Rust has no
runtime-toolchain check to port at all (below), so a literal port of alternative A would ship a
readiness endpoint that can never return 503. That is not a defect to inherit. The latch gives
the endpoint one state it can genuinely report, and the diagnostics list stays open for the
checks other items will add. **Which checks can error in Rust is not decided here**: the two
live candidates are an unparsable configuration document, owned by **R55**
(`config-error-tolerance`), and an unusable state or config directory, owned by **R57**
(`xdg-directory-set`). Both are open; this item names them and decides neither.

**Where the shared function lives, and why that placement is forced rather than chosen.**
`run_diagnostics` goes in **`crates/core`**, the member R02 revision 1 (owner-accepted,
unpublished) defines as *"models, ports, services, the error catalogue, the shipped
`InMemoryProjectsPort`. No CLI or web framework, no HTTP client"*. Both front ends depend on
core and on nothing else — R02's table gives `crates/cli` and `crates/web` the same edge,
"Depends on `core` only" — so core is the *only* place a function can sit and be reachable from
both. Putting it anywhere else would either duplicate it or create the front-end-to-front-end
edge R02's F005 mechanism refuses at the Cargo level. This is the Rust analogue of py's
`core/diagnostics.py`, and it is stronger than py's: in py the placement is a convention that
`import-linter` polices, whereas here Cargo's own resolver refuses the alternative.

**The signature, and the three published decisions it has to satisfy simultaneously.**

```rust
// crates/core/src/diagnostics.rs
pub enum CheckStatus { Ok, Warn, Error }          // #[serde(rename_all = "lowercase")]
pub struct Check { pub name: &'static str, pub status: CheckStatus, pub detail: String }
pub struct Diagnostics { pub checks: Vec<Check> }
impl Diagnostics { pub fn has_error(&self) -> bool }

pub fn run_diagnostics(config: &Config) -> Diagnostics;   // synchronous, blocking, infallible
```

- **R05 revision 2** (synchronous core) makes this an ordinary `fn`, not `async fn`, and makes
  the web side reach it through `tokio::task::spawn_blocking` — the bridge R05 selected and
  executed (its check C14). The CLI calls it directly.
- **R03 revision 1** (`absent is a value, broken is an error`) is why the return type is
  `Diagnostics` and **not** `Result<Diagnostics, _>`. A failing check is a *fact about the
  environment that the report exists to carry*, not a failure of the function that collected
  it. R03's rule 1 governs driven-I/O port reads; this is not a port read, and the discipline
  it expresses — do not smuggle an expected outcome into the error channel — applies directly.
  A `Result` here would force every caller to decide what a collection failure means, which is
  precisely the translation R03 puts in one place.
- **R02 revision 1** forbids a web or CLI type in core. So core derives **`serde::Serialize`
  and nothing else**. No `IntoResponse`, no `utoipa::ToSchema`, no `clap` attribute ever goes
  on `Diagnostics` (see the R71 hand-off under *OpenAPI*).

**The liveness payload: the one place where a faithful port is the wrong answer, argued rather
than asserted.** py reports `python: platform.python_version()` — *the version of the
interpreter that is at this moment executing the process*. Rust has no such fact at runtime. A
Rust binary is statically compiled; there is no toolchain in the container to report, and the
nearest equivalent — the `rustc` version that produced the binary — is only obtainable through a
Cargo build script (`built`, `vergen`, `shadow-rs`) or a build-time proc macro (`git-version`).
The **principle** py's field serves is *"the liveness payload identifies which build is
answering"* — that is what an operator uses it for and what the docstring, *"the web analog of
``--version``"*, says. Rust preserves that principle with facts it already has for free:

```rust
#[derive(Serialize)] pub struct LivenessReport {
    pub status:  LiveStatus,     // "ok"
    pub version: &'static str,   // the crate version, via R22's accessor defined once in core
    pub os:      &'static str,   // std::env::consts::OS
    pub arch:    &'static str,   // std::env::consts::ARCH
}
```

`std::env::consts::OS` and `ARCH` are `&'static str` constants in the standard library; a
probe executed here (`T1`, and the `Cargo.toml`/`ls` of check `A`) confirms they resolve with
**no build script present** — the probe workspace has no `build.rs`. The executed body is
`{"status":"ok","version":"0.4.2","os":"macos","arch":"aarch64"}`. This is a **justified
ecosystem difference, not drift**: the capability ("identify the build") agrees; the field that
realizes it differs because the underlying fact differs.

**A workspace hazard this item must state because it silently breaks the field it just
specified.** `env!("CARGO_PKG_VERSION")` expands to the version of *the package being
compiled*. Under R02's four-package workspace, evaluating it inside `crates/web` yields the web
member's version, not the facade's. Executed, check `A`: with the facade at `0.4.2` and
`crates/web` at `0.1.0`, `/healthz` reading the macro inside the web member reports **`0.1.0`**.
Check `B` shows the fix — `[workspace.package] version` plus `version.workspace = true` on every
member makes both report `0.4.2`. **The mechanism is R22's** (`runtime-version-accessor`, open,
Light tier, no decision published; `research/runs/R22/2026-09-17T020715Z-d93731e7353c/` has no
`review/DECISION.md`). What this item fixes is narrower and is a genuine constraint on R22's
answer: **`/healthz` reports the version of the distributed artifact, and the accessor is
defined once in `crates/core` and consumed by `crates/web`** — never re-derived at the web
member's own call site. R22's own MEDIUM question asks for exactly that ("a typed constant
reused across the CLI, library, and web crates without duplicating a string literal"), so this
is a hand-off with a stated requirement, not a conflict.

**Uptime: asked by the prompt, and declined.** The prompt names uptime as a candidate field. It
is cheap — one `Instant` at startup and one monotonic subtraction. It is **not recommended**,
for three reasons, one of which is a real cost to another item's tests. (1) A body that changes
on every request destroys AC2: R69's validation strategy names "one `oneshot` test per route"
and R33 (`property-and-snapshot-testing`, resolved) selects snapshot testing — a
monotonically-increasing field forces every such test to redact a field before comparing.
(2) Neither surveyed production system emits it: kubert's `/live` body is the four bytes
`"alive\n"`; Apollo's is `{"status":"UP"}`. (3) Kubernetes never reads the body at all. The
operational question uptime answers — "did this process restart?" — is better answered by the
container runtime's own restart count, which the orchestrator already records. Recorded as the
alternative so the synthesizer can overturn it cheaply: if the owner wants it, it is one `pub
started: Instant` field on `AppState` and one line in the handler, and AC2 is deleted.

**Structured types versus a minimal body (the prompt's MEDIUM).** **Structured, `serde`-derived
types.** Three pieces of evidence, in ascending order of force. `apollographql/router` derives
`Serialize` on its `Health` struct rather than writing a literal. `rust-lang/crates.io` derives
both `Serialize` and `utoipa::ToSchema` on `MetadataResponse` for the analogous
build-identity endpoint. And py records the concrete cost of not doing it, in a comment at the
`/readyz` decorator: *"response_model declares the 200 shape in OpenAPI (contract safety,
WEB-50): without it the snapshot publishes an empty `{}` schema."* Since R71
(`openapi-generation-pipeline`) will publish a spec that must survive R83's contract fuzzing, an
untyped ops body is a hole in that spec. **The hand-off to R71, stated precisely because it
collides with R02:** if R71 selects `utoipa`, its `ToSchema` derive must **not** be placed on
`crates/core`'s `Diagnostics` — that would put an OpenAPI crate inside the member R02's
allow-list mechanism exists to keep free of framework dependencies. R71's options are a
`crates/web` DTO built by `From<Diagnostics>`, or a hand-written schema fragment. This item
states the constraint and decides nothing for R71.

**Does the readiness check dial the upstream API?** **No, by default** — and the extension point
is specified rather than left implicit. py's `run_diagnostics` never contacts the upstream
service: its four checks are interpreter, platform, config-file presence and token presence, all
local (`py@b08bccfb` `core/diagnostics.py:47-91`). Kubernetes explicitly permits the other
choice — *"the readiness probe additionally checks that each required back-end service is
available"* — when the app "has a strict dependency on back-end services", but pairs it with the
cascading-failure caution quoted above, and a correlated upstream blip would then remove **every**
replica from service simultaneously. So: **local checks only by default; an upstream check is an
opt-in.** When a template user wants one, the shape is fixed by R01's published
`http-transport-injection-seam`: the check calls the erased `ProjectsService` held in `AppState`
— core's port — **never a concrete adapter**, inside the same `spawn_blocking` hop, with a
timeout strictly shorter than the probe's `timeoutSeconds` and a short result cache so that N
probes per second do not become N upstream calls per second. Adding it changes no signature in
this design: it is one more `Check` pushed onto the report.

**Compile-time and binary cost, and what is not measured.** The recommendation adds **zero
crates**: every mechanism is `std`, or axum/tokio/serde, all of which R69, R05 and R66 already
put in the tree. Check `C11` shows `crates/core`'s entire resolved dependency tree is `serde`
and its four proc-macro dependencies; check `C9` shows a default (feature-off) build of the
facade contains **no** `axum` at all. The marginal cost of the probe surface is two handler
functions, three structs and one `AtomicBool` — qualitatively, a rounding error against axum's
own code size. **No latency, throughput or binary-size figure is claimed by this report**: none
was measured. The one cost worth naming and not measuring is the `spawn_blocking` hop on
`/readyz`, which R05 already records as the open measurement in its own decision.

**`BASELINE-REVIEW:` findings: none.** The only `ADOPT` row this item touches is **F308**
(unversioned ops endpoints), which the prompt instructs be applied rather than re-derived and
which this report applies unchanged. The unreachable-503 finding above concerns **F329**, a
`DIVERGENT` row this item owns the answer to, so it is reported as a design finding in this
field rather than as a challenge to a classified baseline.

**Agreement and difference with the owner-supplied reference architecture**
(`inputs/owner-reference-axum-companion-stack-2026-09-16.md`; standing input under
`docs/planning/p02/owner-decisions.md` section 11, which places **C15** in this item's overlap
set). Row-by-row for every row that touches this item:

| Reference row | What it says | This item |
|---|---|---|
| **C15**, *Container & Cloud Run* | "expose `/healthz` (liveness) and `/readyz` (readiness, checks DB)" | **Agree on the two paths and their roles** — they are also F308's and py's. **Differ on "checks DB", on sourced ground**: the reference's readiness dials a backing store; this template has no database, its single driven dependency is an upstream HTTP API behind R01's port, and the Kubernetes cascading-failure caution plus py's own local-only check set make an unconditional dependency dial the wrong default here. The capability is preserved as the specified opt-in above |
| **C15**, *distroless/cc-debian12*, run as `nonroot`, bind `PORT` | the image shape | **Not this item's** — R51 owns it. One consequence is stated, not fixed, below |
| **C4**, *Error contract* | "One `AppError` enum (`thiserror`) implementing `IntoResponse` … RFC 9457 Problem Details JSON" | **Agree that `/readyz`'s 503 reuses the single envelope**, which is what py does. **The envelope itself is R70's**, still open; this item names the `diagnostics` extension member as its requirement on it and decides nothing else |
| **C10**, *Observability* | JSON logs, trace correlation | **No position.** R58/R75/R78/R79. The only interaction is F320 (probes excluded from access-log volume), which is R75's |
| **C13**, *Project structure* | "feature-vertical modules" | **Agree**, as realized by R69 revision 10: the probe handlers are one module, `crates/web/src/routes/ops.rs` |
| **Reference `Cargo.toml`** | `edition = "2021"`, `rust-version = "1.85"` | **Differ — owner-fixed parameters override**, per section 11's own rule: `rust-edition` = `2024` and `msrv-policy` as registered. The executed probe workspace uses edition 2024 throughout |

Tally over the six rows: **3 agree, 2 differ** (both differences on the grounds section 11 requires — one measured
and sourced, one an owner-fixed parameter), plus 2 rows recorded as belonging to other items.

**The R51 coupling, stated and not fixed.** R51 (`container-image`, being researched in
parallel) consumes `/healthz` for F337, "container declares its own liveness healthcheck". Two
facts it will need, both established here rather than guessed. First, what `/healthz` returns:
`200` with a JSON body, on `GET` and `HEAD`, with no state and no dependency, for the life of
the process. Second, the *probe client* problem: py solves it with the interpreter it already
ships — `py@b08bccfb` `Dockerfile:27-30`, commented *"urllib — the slim base image has no
curl"*, running `HEALTHCHECK … CMD python -c "import urllib.request; …urlopen('http://127.0.0.1:8000/healthz')…"`.
A Rust distroless image has **neither** a shell nor an interpreter nor `curl`; Apollo Router's
source comment records the same constraint from the other side ("we can't install curl or jq
into our docker images because of CVEs"). So R51's options are a self-probing subcommand on the
template's own binary, a second tiny static probe binary, or omitting `HEALTHCHECK` and letting
the orchestrator's `httpGet` probe do the work — the latter being what both surveyed production
systems rely on. **This item does not choose among them.** Note also that every Kubernetes
document read for this report configures probes on the Pod spec (`livenessProbe.httpGet`) and
none of them mentions a Dockerfile `HEALTHCHECK` directive at all; that is an observation about
the pages read, not a claim about kubelet behavior.

**The open scoping question this item surfaces and does not answer.** The CLI `doctor` command
is presupposed by F329 but is **owned by no item**: a search of `docs/port/COMMONALITY.md` for
"doctor" returns F185 and F186, which are contributor-facing `Justfile`/`Makefile` recipes, and
`docs/port/areas/dev-experience-repo-hygiene.md:88` says so explicitly — the ADR it cites
"describes the `plbp doctor` CLI product subcommand (a shipped-product feature), not a
repo-hygiene tool". py's `doctor` exits `int(ExitCode.CONFIG)` when `report.has_error()`
(`py@b08bccfb` `cli/main.py:118-124`). R67's accepted `error-taxonomy-exit-codes` catalog is
**append-only** and contains no diagnostics row; the nearest existing rows are `RSLB104` (config
layer unreadable → 1) and `RSLB203` (config value invalid → 2). **This item does not assign
one.** It records that whoever specifies `doctor` must either reuse one of those or add a row
through R67's append-only process, and that today — with no check able to reach `error` —
`doctor` would exit `0` on every machine.

### Recommendation

**`probe-contract/v1` — one shared synchronous diagnostics function in `crates/core`, two
hand-written axum handlers in `crates/web/src/routes/ops.rs`, and an `AtomicBool` readiness
latch flipped by R69's shutdown signal. No new crate, at any version.** Concretely:
`GET /healthz` is a stateless handler returning `200` and
`{"status":"ok","version","os","arch"}` built from R22's core-defined version accessor and
`std::env::consts::{OS, ARCH}`; `GET /readyz` reads the latch, then calls
`rs_launch_blueprint_core::diagnostics::run_diagnostics` — the same function the CLI's `doctor`
command calls — through `tokio::task::spawn_blocking`, answering `200` with the serialized
report when the process is accepting and no check is `error`, and `503` carrying R70's problem
document with the report under a `diagnostics` extension member otherwise. Both paths are
unversioned per F308, both accept `GET` and `HEAD`, and both vanish with the `web` feature. The
members below are the five pieces that stack composes; three of them are consumed from
owner-accepted decisions and are re-verified here rather than re-selected, and the two that this
item actually decides — the shared diagnostics contract and the build-identity source — are the
two that carry a full shortlist.

### Members

Five members. Two are decided by this item (`rs-launch-blueprint-core::diagnostics`,
`std` build-identity); three are consumed from owner-accepted decisions and carry their
figures but not a re-selection (`serde`, `axum`, `tokio`).

**Figures common to the crate members**, collected once, each with its endpoint. 90-day
downloads = `crate.recent_downloads`; all-time = `crate.downloads`; both from
`GET https://crates.io/api/v1/crates/<name>`, 2026-09-18. Last release = newest
`yanked: false` entry from `GET https://crates.io/api/v1/crates/<name>/versions`, 2026-09-18.
Stars / `archived` / `pushed_at` from `GET https://api.github.com/repos/<o>/<r>`; open issues
from `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`,
never `open_issues_count`) — both 2026-09-18, one call per 20 s.

| Crate | 90-day | all-time | last release | declared `rust-version` | licence | stars | archived | `pushed_at` | open issues |
|---|---|---|---|---|---|---|---|---|---|
| `serde` | 314,208,639 | 1,410,307,353 | 1.0.229, 2026-07-18 | 1.56 | MIT OR Apache-2.0 | 10,826 | false | 2026-08-25 | 319 |
| `serde_json` | 317,743,616 | 1,313,719,716 | 1.0.151, 2026-07-20 | 1.71 | MIT OR Apache-2.0 | 5,635 | false | 2026-08-08 | 191 |
| `axum` | 118,234,751 | 475,506,585 | 0.8.9, 2026-04-14 | 1.80 | MIT | 27,176 | false | 2026-09-18 | 33 |
| `tokio` | 228,862,107 | 978,381,970 | 1.53.1, 2026-07-20 | 1.71 | MIT | 33,173 | false | 2026-09-18 | 320 |
| `built` | 18,238,136 | 63,168,750 | 0.8.1, 2026-05-21 | 1.87 | MIT | 198 | false | 2026-06-07 | 8 |
| `vergen` | 8,605,373 | 52,213,287 | 10.0.3, 2026-08-24 | 1.96.0 | MIT OR Apache-2.0 | 473 | false | 2026-09-06 | 4 |
| `shadow-rs` | 2,184,341 | 10,812,524 | 2.0.0, 2026-04-23 | **none declared** | MIT AND Apache-2.0 | 702 | false | 2026-05-19 | 8 |
| `git-version` | 5,528,772 | 24,871,629 | 0.3.9, **2023-12-13** | **none declared** | BSD-2-Clause | 131 | false | 2023-12-13 | **not retrieved** |

`git-version`'s open-issue count could not be retrieved: the search endpoint answered
HTTP 422 *"The listed users and repositories cannot be searched"* for
`repo:fusion-engineering/rust-git-version` on 2026-09-18, while the plain repository endpoint
answered 200 for the same path. The prompt forbids substituting `open_issues_count`, so the
figure is **absent**, not estimated.

**Advisories (fitness gate 3).** `https://rustsec.org/packages/<name>.html`, 2026-09-18, with
`atty` as a positive control (HTTP 200, `RUSTSEC-2021-0145`, `RUSTSEC-2024-0375`). `serde`,
`serde_json`, `axum`, `built`, `vergen`, `shadow-rs` and `git-version` each return **HTTP 404**
— no advisory page exists, therefore no advisory. `tokio` returns **HTTP 200** listing five
historical entries, newest `RUSTSEC-2025-0023` (type INFO, unsound `broadcast` clone), whose
advisory page gives `Patched >=1.38.2, <1.39.0 | >=1.42.1, <1.43.0 | >=1.43.1, <1.44.0 |
>=1.44.2` — **1.53.1 is unaffected**, and the other four are older still.

**Issue responsiveness.** Computed for **`lukaslueg/built`** only, the one member whose
selection a reviewer might genuinely contest, and stated as **not computed** for the rest with
its reason. `GET https://api.github.com/repos/lukaslueg/built/issues?state=all&sort=created&direction=desc&per_page=10`
(2026-09-18) returns ten items of which **four are issues** (the rest are pull requests, which
the rubric's "issues" excludes): #101, #100, #98, #93. Each received a first maintainer
(`lukaslueg`) comment — 3 h 35 m, 3 h 15 m, 6 h 37 m and 1 h 19 m after opening respectively
(`GET https://api.github.com/repos/lukaslueg/built/issues/<n>/comments?per_page=5`,
2026-09-18). **Median days to first maintainer response: 0 (about 3.4 hours). Unanswered: 0 of
4.** For the other seven crates the figure is **not computed**: each needs about eleven GitHub
API calls at the mandated one-per-20-seconds, roughly 3.7 minutes per crate, and no member's
verdict turns on it — `serde`, `serde_json`, `axum` and `tokio` each released inside the last
five months and are consumed rather than selected, `vergen` released three weeks ago, and
`shadow-rs` and `git-version` are excluded on a declared-MSRV gate that responsiveness cannot
change.

#### rs-launch-blueprint-core::diagnostics (the shared diagnostics contract — no crate)

##### Landscape

Bin 1, built-in: this member is ordinary Rust in the template's own core crate — a data type, a
predicate and a function. The category is "where does shared logic live when two front ends must
run it", and the Rust field offers exactly one mechanism worth surveying (a library crate both
front ends depend on) plus two anti-patterns that appear in the wild (duplicating the check list
per front end; putting the shared logic in a front end and having the other depend on it). The
crate figure table is **inapplicable to this member**: it introduces no crate, so there is no
`recent_downloads`, no release date and no advisory page. Pattern fields are used instead. The
relevant authorities are the two prior decisions that constrain the placement — R02 revision 1
(package topology) and R05 revision 2 (execution model) — plus the py precedent at the pin.

##### Principles and implementation

The principle is F329's, in the ledger's own words: *"one source of truth with the CLI"*. The
agreement level is **architectural pattern**: py and rs must both have exactly one function that
produces the diagnostic report, and both front ends must call it; the check list itself, the
type names and the rendering are free to vary. `ts@cb1cbcb2` has neither front end, so nothing
to preserve there. The essential behaviors are: one function; two callers; a value-typed report;
no web or CLI type in the shared module. In Rust the pattern is not merely appropriate, it is
**enforced**: R02's four-package workspace gives `crates/cli` and `crates/web` an edge to
`crates/core` and to nothing else, and Cargo refuses the front-end-to-front-end edge as a cycle,
so a second copy of the check list is the *only* way to violate the pattern — and a `grep` finds
that. py achieves the same with an `import-linter` contract, a checker that must be run.

The signature and its three constraints (R05 synchronous, R03 value-not-error, R02 no framework
types) are argued in the H3 `Principles and implementation` field above and not repeated. The
minimal realistic example is the executed probe workspace: `crates/core/src/lib.rs` holds
`CheckStatus`, `Check`, `Diagnostics`, `has_error()` and `run_diagnostics(&Path, bool)`, whose
whole external dependency tree is `serde` (check `C11`); `crates/web` calls it from the
`/readyz` handler inside `spawn_blocking` (checks `T3`, `T4`); a CLI caller would call it
directly. The executable acceptance check is `AC9`, plus `T3`/`T4`/`T6` which exercise the
function through the handler and the pure response function independently.

##### Dominant choice

**A shared library crate both front ends depend on** — dominant in the sense that no other
mechanism was found in any surveyed system. `py@b08bccfb` does it (`core/diagnostics.py`
imported by both `web/app.py:49` and `cli/main.py:37`). It is what R02's topology exists to make
enforceable. There is no competing Rust idiom: Rust has no runtime plugin registry, no dependency
container in this template (R01's composition root is "plain functions, no DI container"), and no
reason to reach for either.

##### Qualified shortlist

Two, distinguished only by *what the shared function returns*. **(i) `Diagnostics` (a value)** —
selected. **(ii) `Result<Diagnostics, DiagnosticsError>`** — a function that can fail to collect.
(ii) is qualified, not absurd: a check that must read a file could plausibly fail in a way that
is not itself a diagnostic finding. It is rejected because R03's published discipline puts the
translation of an expected outcome in exactly one place and forbids smuggling it into the error
channel, and because both callers would then need an identical `match` — the CLI to print
something and the handler to pick a status code — which re-creates the duplication the pattern
exists to remove. py chose (i); `run_diagnostics` has no failure mode and returns `DoctorReport`.

##### Excluded by gate

**Inapplicable** — the six fitness gates are written against crates (licence, dependency-tree
MSRV, RustSec advisory, per-OS CI, default features and async-runtime coupling, binary and
compile cost). This member introduces no crate. Read against the *template's own* code the gates
are satisfied trivially: the licence is the repository's `MIT OR Apache-2.0`; the MSRV is the
template's own, since the member uses only `std` and `serde` 1.0.229 (declared `rust-version`
1.56); there is no advisory surface; it compiles on both `ubuntu-latest` and `macos-latest`
because it is target-independent `std` (executed on macOS 26.4 `arm64`, rustc 1.98.0); it
declares no features and no runtime coupling; and its cost is three structs.

##### Up-and-comers

None. The two things that could be called up-and-coming in this space both fail on inspection:
an "architecture framework" that would own the seam (`hexser` 0.6.0, which **R02 revision 1
explicitly rejected** as "an invasive macro and dependency-injection framework that would couple
the domain to an external opinionated macro library"), and a derive-based check registry, of
which the census found no Rust instance with adoption.

##### Fit for this template

Exact. The template is CLI + library + web service, which is precisely the two-front-ends-one-core
shape this member assumes, and R02 has already built the package topology it needs. The one fit
question worth stating is whether `run_diagnostics` belongs in `crates/core` or in the root
facade `rs-launch-blueprint`: the facade is reachable from neither `crates/cli` nor `crates/web`
(both depend on `core` only, and the facade depends on *them*), so `core` is the only placement
that works. Nothing about the choice is contingent on R80's other members.

##### Recommendation

```rust
// crates/core/src/diagnostics.rs — the only place the check list exists
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize)]
#[serde(rename_all = "lowercase")]
pub enum CheckStatus { Ok, Warn, Error }

#[derive(Debug, Clone, serde::Serialize)]
pub struct Check { pub name: &'static str, pub status: CheckStatus, pub detail: String }

#[derive(Debug, Clone, serde::Serialize)]
pub struct Diagnostics { pub checks: Vec<Check> }

impl Diagnostics {
    pub fn has_error(&self) -> bool {
        self.checks.iter().any(|c| c.status == CheckStatus::Error)
    }
}

/// Synchronous (R05), infallible (R03), framework-free (R02).
pub fn run_diagnostics(config: &Config) -> Diagnostics;
```

The initial check set ports py's minus the one with no Rust analogue: `build` (version, OS,
arch — informational, always `ok`), `config-file` (`ok`/`warn`), `credential` (`ok`/`warn`).
`name` is `&'static str` because every check name is a literal; `detail` is `String` because it
interpolates paths and values.

##### Ranked runner-up

**`Result<Diagnostics, DiagnosticsError>`**, the qualified-shortlist entry (ii), for the reasons
under that heading. If P03 finds a check whose *collection* can fail in a way that is genuinely
not a finding, this is the shape to move to, and the migration is mechanical: the CLI adds one
`?` and the handler adds one `match` arm mapping the error to 503.

##### Tradeoffs

The cost of one shared function is that the CLI and the web service cannot diverge cheaply: a
check that only makes sense for the server (a bound port, a warm cache) has nowhere natural to
go, and py has the same problem. The mitigation, not adopted here because nothing needs it yet,
is a second function in the same module — `run_web_diagnostics(config) -> Diagnostics` appending
to `run_diagnostics`'s output — which keeps one check list per concern and still one module. The
second cost is that `Vec<Check>` with `String` details allocates per probe; at a Kubernetes
readiness cadence (seconds) that is irrelevant, and it would matter only if `/readyz` were
polled at request rates, which no orchestrator does.

##### Parameters

Owns nothing in the registry. Assumes, in prose rather than as registry lines (the byte-identical
`assumes` lines are in the H3 `Parameters` field): R02 revision 1's `crates/core` role and its
front-end edges; R05 revision 2's synchronous core; R03 revision 1's absence-versus-failure
discipline. No `CONFLICT:` line: none of the three needs to change.

##### Migration implications

One new file, `crates/core/src/diagnostics.rs`, and one `pub mod diagnostics;` line in
`crates/core/src/lib.rs`. `crates/core/Cargo.toml` gains nothing: `serde` with `derive` is
already there for R66's result contract. Whether `Diagnostics` is re-exported from the root
facade's barrel is R04's (`public-api-surface-enforcement`, resolved) rule to apply, not this
item's to decide.

##### Validation strategy

`AC9` is the criterion and it is **P03's, not executed here**: assert that `crates/cli` and
`crates/web` both name `rs_launch_blueprint_core::diagnostics::run_diagnostics` and that a
search for the check-name literals finds them in exactly one file. What **was** executed is the
function's behavior through both of its intended consumption shapes — directly (`T6`, feeding a
hand-built `Diagnostics` to the pure response function) and through the handler inside
`spawn_blocking` (`T3`, `T4`) — plus `C11`, which shows the core member's resolved tree contains
no web crate.

##### Confidence & re-verify trigger

**High.** The placement is forced by R02's published topology rather than chosen; the signature
is forced by R05 and R03; and the behavior was executed. Re-verify if: R02's four-package
topology changes (its own re-verify trigger names the `OVERRIDE (OV-03)` ruling); R05 is
reopened and the core becomes async, which turns the function into `async fn` and deletes the
`spawn_blocking` hop; R03 is revised; or R55 or R57 publishes a check that can reach
`CheckStatus::Error`, which does not change this member but does change what `/readyz` can
report.

##### Sources

`py@b08bccfb:src/py_launch_blueprint/core/diagnostics.py` (lines 47–91, `run_diagnostics`);
`py@b08bccfb:src/py_launch_blueprint/core/models.py:148-174` (`DoctorCheck`, `DoctorReport`,
`has_error`); `py@b08bccfb:src/py_launch_blueprint/cli/main.py:37,110-124`;
`py@b08bccfb:src/py_launch_blueprint/web/app.py:49,184-198`;
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (package table,
enforcement table, the `hexser` rejection);
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` (synchronous core,
`spawn_blocking` bridge, check C14);
`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/DECISION.md` (rules 1–4);
`docs/port/COMMONALITY.md` F329; executed checks `T3`, `T4`, `T6`, `C11` (this report).

#### std build-identity (`std::env::consts` + Cargo's compile-time version — no crate)

##### Landscape

Bin 1 (built-in) against bin 2 (established). The category is "where does a Rust binary get the
facts that identify which build is answering". Bin 1 offers `env!("CARGO_PKG_VERSION")` — a
Cargo-set compile-time environment variable — and `std::env::consts::{OS, ARCH, FAMILY}`, which
are `&'static str` constants. Bin 2 offers the build-metadata family, four crates that give you
strictly more (compiler version, git SHA, build timestamp, feature list, dirty-tree flag) at the
cost of a mechanism the template has already ruled out: `built` 0.8.1, `vergen` 10.0.3,
`shadow-rs` 2.0.0 (all three Cargo **build scripts**) and `git-version` 0.3.9 (a proc macro, no
build script, but a `git` binary and a `.git` tree at compile time). Bin 3 is empty. The
authorities are the Rust and Cargo references for bin 1, each crate's own README and `src/lib.rs`
for bin 2, and one production counter-example read at source.

##### Principles and implementation

The principle, extracted from py rather than copied from it: **the liveness payload identifies
which build is answering.** py realizes it with `version=__version__` plus
`python=platform.python_version()`, and the docstring names the intent — *"Liveness + build info
(the web analog of ``--version``)"*. The agreement level is **capability**, not value: the
*fields* cannot agree across ecosystems because the underlying facts do not exist in both. There
is no interpreter in a Rust container to report; the analogous fact, the compiler that produced
the binary, is not available at runtime without a build script. Reporting the target's OS and
architecture instead preserves the capability with facts the binary already carries, at zero
cost, and adds something py's field cannot give: on a multi-architecture image it tells the
operator which arch's image the orchestrator actually pulled.

A maintained production counter-example to the build-script family, read rather than asserted:
`rust-lang/crates.io` reports its deployed commit from a **runtime environment variable**.
`crates/crates_io_version/src/lib.rs` documents `commit()` as determining the SHA "through
various methods: Heroku environment variables (`HEROKU_BUILD_COMMIT`, `HEROKU_SLUG_COMMIT`)",
delegating to `crates_io_heroku::commit()`, which is `var("HEROKU_SLUG_COMMIT")`. The Rust
project's own registry — a service under continuous deployment, where knowing the running commit
matters more than in most systems — declines the build-script approach. That is the path open to
this template if it later wants a commit SHA: an environment variable set by the deployment,
read at startup, which also survives the re-deploy of an unchanged binary that a compile-time
constant cannot.

##### Dominant choice

**`std` + Cargo's compile-time version — dominant on availability, not on downloads.** Every
Rust binary already has both; there is no adoption figure because there is nothing to adopt. On
raw population the *build-script* family is not close to dominant either: the largest, `built`,
has 18,238,136 recent downloads against `serde`'s 314,208,639, i.e. roughly one crate in
seventeen that pulls `serde` pulls `built`. Executed confirmation that the built-in path needs no
build script: check `A`, a two-member workspace whose directory listing contains no `build.rs`,
printing `std_env_consts_OS=macos`, `std_env_consts_ARCH=aarch64` and binding both to
`&'static str`.

##### Qualified shortlist

Three, in the order a reviewer should weigh them.

1. **`std::env::consts::{OS, ARCH}` + the crate version through R22's accessor** — selected. No
   crate, no build script, no git dependency, works identically from a crates.io tarball, from a
   git checkout and inside a container build.
2. **`built` 0.8.1** — the most-adopted of the build-script family (18,238,136 recent downloads;
   declared `rust-version` 1.87; MIT; no RustSec page; maintainer median first response about
   3.4 hours over the four most recent issues). It is the runner-up if the owner later decides
   the payload must carry the compiler version or the git SHA.
3. **`vergen` 10.0.3** — 8,605,373 recent downloads, MIT OR Apache-2.0, released 2026-08-24,
   declared `rust-version` **1.96.0**. Qualified, but note that 1.96.0 sits exactly on the
   `stable minus 2` floor as of rustc 1.98.0 on this machine: one more stable release with no
   corresponding `vergen` change and it clears the bar only by moving with it.

##### Excluded by gate

**By gate 2 (declared MSRV within `stable minus 2 minor versions …`), on the strict reading the
auditors established and the owner adopted** (`docs/planning/p02/owner-decisions.md`, "Two things
you should know" — the provisional ruling that an undeclared version is "unproven rather than
failed" was **withdrawn**; a failed gate excludes):

- **`shadow-rs` 2.0.0** — `GET https://crates.io/api/v1/crates/shadow-rs/versions` returns
  `rust_version: null` for the newest non-yanked version. No declared minimum. **Excluded.**
- **`git-version` 0.3.9** — same endpoint, `rust_version: null`. **Excluded.** It would
  otherwise be the most interesting candidate in bin 2, because it is a proc macro with **no
  build script** (`git-version/src/lib.rs` is `#![no_std]` and re-exports
  `git_version_macro::git_version`), so R49's no-`build.rs` clause would not touch it. Two further
  facts are recorded so the exclusion is not mistaken for the only objection: its README states
  *"These macros do not depend on libgit, but simply uses the `git` binary directly. So you must
  have `git` installed somewhere in your `PATH`"*, and `git-version-macro/src/lib.rs` only
  substitutes a value when an explicit `fallback` argument is supplied — a crates.io source
  tarball contains no `.git` tree, so `cargo install rs-launch-blueprint` would compile against a
  fallback string rather than a real SHA. Its last release is **2023-12-13**, which under the
  maintenance rubric is a trigger to investigate, and the investigation is that `pushed_at` is
  the same day: no commits in 2 years 9 months.

**Excluded on fit — not a fitness gate, and labelled as such** because the ground is a consumed
parameter rather than one of the six gates:

- **`built` 0.8.1** and **`vergen` 10.0.3**, together with `shadow-rs` had it cleared gate 2, all
  require a **Cargo build script**, and R49's owner-accepted `build-tool-output-shape` states
  *"no `build.rs` and no build-orchestration crate"* (quoted from the live registry row; R02's
  own check `EF5d` quotes the same clause and uses it to exclude every `xtask`-based tool).
  Verified from the maintainers' own documentation rather than inferred: `built`'s README shows
  the usage under the comment `// In build.rs`; `vergen`'s README says its tools are configured
  "in cargo [build scripts]" and that it "Will emit `cargo:rerun-if-changed=build.rs`";
  `shadow-rs`'s README instructs `build = "build.rs"`, a `[build-dependencies]` entry and
  *"2) Create `build.rs` file"*. **No `CONFLICT:` line is raised**, because the recommendation
  does not need R49's value changed — it needs none of these crates.

##### Up-and-comers

None with adoption. The category is old and settled: the build-script crates date from the
mid-2010s and `std::env::consts` has been stable since Rust 1.0. The genuinely newer idea in this
space is the one `rust-lang/crates.io` uses — read the deployment's identity from the environment
at runtime — and it needs no crate either.

##### Fit for this template

Decisive on three template-specific grounds. **(1)** R49's published no-`build.rs` clause
excludes the whole build-script family on fit before any comparison of their merits.
**(2)** The template is distributed through `cargo install` from a crates.io tarball, which has
no `.git` directory — so any git-derived field is absent or a fallback string for exactly the
users who install it the documented way. **(3)** The `web` surface is off by default (R69), so a
mechanism whose cost lands on *every* build — a build script runs for the CLI-only build too —
buys a field only the optional surface displays. Against that, the facts `std` supplies are
already correct in all three distribution paths.

##### Recommendation

```rust
// crates/core — one accessor, defined once, consumed by the CLI and by /healthz
pub const VERSION: &str = env!("CARGO_PKG_VERSION");   // mechanism is R22's to fix
// crates/web/src/routes/ops.rs
LivenessReport {
    status:  LiveStatus::Ok,
    version: rs_launch_blueprint_core::VERSION,
    os:      std::env::consts::OS,
    arch:    std::env::consts::ARCH,
}
```

with one binding constraint on R22's answer, derived from an executed check rather than asserted:
**the accessor is evaluated in `crates/core` (or in a package that inherits
`[workspace.package] version`), never at the web member's own call site.** Check `A`: with the
facade at `0.4.2` and `crates/web` at `0.1.0`, `env!("CARGO_PKG_VERSION")` inside the web member
yields **`0.1.0`** — the endpoint would report the wrong version, correctly, forever. Check `B`:
`[workspace.package] version = "0.4.2"` with `version.workspace = true` on both manifests makes
both report `0.4.2`.

##### Ranked runner-up

**`built` 0.8.1**, and only if the owner decides `/healthz` must carry the compiler version, the
git SHA or a build timestamp. Adopting it costs an amendment to R49's `build-tool-output-shape`
(a `CONFLICT:` line filed by whichever item needs it), a `build.rs`, a `[build-dependencies]`
entry and a build script on every build including the CLI-only one. Before paying that, the
cheaper path is the one `rust-lang/crates.io` took: read the SHA from an environment variable the
deployment sets, which costs nothing at build time and is more accurate across re-deploys.

##### Tradeoffs

What is given up is real and should be stated plainly: the recommended payload cannot tell you
*which commit* is running, nor which compiler built it. An operator debugging a
`0.4.2`-versus-`0.4.2` discrepancy between two deployed replicas gets no help from `/healthz`.
The counter-argument is that a compile-time SHA does not help there either when the binary is
redeployed unchanged, and the environment-variable path does. What is gained is that the endpoint
has zero build-time machinery, identical behavior across all three installation paths, and a
byte-stable body (`T2`) that a snapshot test can pin.

##### Parameters

Owns nothing. The version accessor's mechanism is **R22's** (`runtime-version-accessor`, open;
`ls research/runs/R22` gives `2026-09-17T020715Z-d93731e7353c`, whose `review/` holds no
`DECISION.md`). This member states one requirement on that answer — core-defined, workspace-safe
— and no `CONFLICT:`, since R22 has published no value to conflict with. R49's
`build-tool-output-shape` is consumed unchanged; its no-`build.rs` clause is what excludes the
build-script family, and nothing here asks it to change.

##### Migration implications

Nothing new in any manifest. `crates/core` gains one `pub const` (or whatever form R22 selects);
`crates/web/src/routes/ops.rs` gains the three-field struct literal. If R22 selects workspace
version inheritance, the root `Cargo.toml` gains `[workspace.package] version` and each member
manifest replaces its literal `version` with `version.workspace = true` — a change that touches
four manifests and is R22's and R02's to write, not this item's.

##### Validation strategy

Executed here: check `A` (the workspace version hazard, both halves printed), check `B` (the
inheritance fix), `T1` (the served body, field by field, including `os` and `arch` compared
against `std::env::consts` in the test process) and `T2` (byte stability across two calls).
Proposed for the template's CI, wiring owned by R11: a test asserting the `version` field of
`GET /healthz` equals the value the `--version` flag prints, which is the Rust analogue of py's
`tests/meta/test_version_consistency.py` and of ts's `tests/version.test.ts`, and which fails
loudly if the accessor is ever evaluated in the wrong package.

##### Confidence & re-verify trigger

**High** for the mechanism and the hazard — both executed on this machine (rustc 1.98.0, macOS
26.4 `arm64`, edition 2024). **Medium** for the exact field list, because the owner may want a
commit SHA and that is a one-field change. Re-verify if: **R22** publishes and selects a
different accessor; **R49**'s no-`build.rs` clause is amended, which reopens `built` and
`vergen`; `GET https://crates.io/api/v1/crates/shadow-rs/versions` or
`.../git-version/versions` begins returning a non-null `rust_version`, which reverses a gate-2
exclusion; or `vergen`'s declared `rust-version` rises above the `stable minus 2` floor.

##### Sources

`https://doc.rust-lang.org/std/env/consts/index.html`;
`https://doc.rust-lang.org/cargo/reference/environment-variables.html`;
`https://doc.rust-lang.org/cargo/reference/build-scripts.html`;
`https://crates.io/api/v1/crates/{built,vergen,shadow-rs,git-version}` and `/versions`;
`https://api.github.com/repos/{lukaslueg/built,rustyhorde/vergen,baoyachi/shadow-rs,fusion-engineering/rust-git-version}`;
`https://api.github.com/search/issues?q=repo:lukaslueg/built+is:issue+is:open`;
`https://api.github.com/repos/lukaslueg/built/issues?state=all&sort=created&direction=desc&per_page=10`
and the per-issue comments endpoint;
`https://rustsec.org/packages/{built,vergen,shadow-rs,git-version}.html` (all 404) with
`https://rustsec.org/packages/atty.html` as the 200 control;
`https://raw.githubusercontent.com/lukaslueg/built/master/README.md`;
`https://raw.githubusercontent.com/rustyhorde/vergen/master/README.md`;
`https://raw.githubusercontent.com/baoyachi/shadow-rs/master/README.md`;
`https://raw.githubusercontent.com/fusion-engineering/rust-git-version/master/git-version/README.md`
and `.../git-version/src/lib.rs` and `.../git-version-macro/src/lib.rs`;
`https://raw.githubusercontent.com/rust-lang/crates.io/main/crates/crates_io_version/src/lib.rs`
and `.../crates_io_heroku/src/lib.rs`;
`py@b08bccfb:src/py_launch_blueprint/web/app.py:93-99,153-159`; executed checks `A`, `B`, `T1`,
`T2` — all retrieved or run 2026-09-18.

#### serde 1.0.229

##### Landscape

Bin 2, established industry standard, and functionally unopposed: `serde` is the serialization
framework of the Rust ecosystem at 314,208,639 recent downloads. For this member the landscape
question is not "which serializer" but "does the probe payload get a derived type at all", which
is the prompt's MEDIUM question and is answered under the H3 `Principles and implementation`
field. Alternatives that exist and were considered: a hand-written `&'static str` JSON literal
(kubert's `"alive\n"` is the degenerate form) and `serde_json::json!` built ad hoc in the
handler.

##### Principles and implementation

**Not re-selected here.** `serde` 1.0.229 with `features = ["derive"]` in the library crate is
**R66**'s published decision (`research/topics/66-output-format-surface/DECISION.md`, the
recommended-stack table: "Result data contract (wire shape) | `serde` | `1.0.229` |
`features = ["derive"]` | library crate"), and **R69**'s owned `web-extra-surface` states the
`web` feature "does not gate … `serde`, `serde_json`", i.e. both are unconditional. This member
records that the probe payloads join that existing contract rather than inventing a second one:
`LivenessReport` and `Diagnostics` are `#[derive(Serialize)]` types like every other result the
template emits, `CheckStatus` carries `#[serde(rename_all = "lowercase")]` so the wire values are
`"ok"`/`"warn"`/`"error"` exactly as py's `CheckStatus` literal does, and the CLI renders the
same `Diagnostics` through R66's columns/rows contract.

##### Dominant choice

Dominant on every figure and by a wide margin: 314,208,639 recent downloads and 1,410,307,353
all-time, 10,826 stars, `archived` false, `pushed_at` 2026-08-25, 319 open issues. No serialization
alternative in the Rust ecosystem is within an order of magnitude for derive-based struct
serialization.

##### Qualified shortlist

**Inapplicable — consumed from R66's published decision and R69's owned parameter, not
re-selected.** For completeness, the shortlist R66 itself ran is in that decision; nothing about
an ops payload distinguishes it from any other result type, so re-running it here would be
duplicated work with a foregone conclusion.

##### Excluded by gate

**Inapplicable for the crate** (it passes every gate: MIT OR Apache-2.0 per gate 1; declared
`rust-version` 1.56 per gate 2; no RustSec page — HTTP 404 against the `atty` 200 control — per
gate 3; it builds on both matrix OSes, executed here on macOS and relied on by R66 and R69 on
both, per gate 4; `derive` is the only feature this template enables and it carries no
async-runtime coupling, per gate 5; `serde_derive` is a proc macro whose compile cost is real but
already paid by R66's result contract, per gate 6). What **is** excluded, at the design level, is
the alternative to using it: a hand-written JSON literal for the probe bodies. Excluded because
py records the cost — *"without it the snapshot publishes an empty `{}` schema"* — and R71 will
publish that schema.

##### Up-and-comers

`serde_core` 1.0.229 appears in the resolved tree (check `C11`) as `serde`'s own factored-out
core. It is not a candidate for direct use here; it is an implementation detail of the crate
already selected. No other up-and-comer is relevant: this member consumes a settled choice.

##### Fit for this template

Exact, and it is what makes the boundary work. `serde` is the **only** external crate
`crates/core` needs for this item — check `C11` shows the core member's entire resolved tree is
`serde` plus its four proc-macro dependencies — so the shared `Diagnostics` type can be
serializable without any framework crate entering the member R02 protects. A derive from a web
framework or an OpenAPI generator could not be placed there; `serde`'s can.

##### Recommendation

`serde = { version = "1.0.229", features = ["derive"] }` in `crates/core` — **the existing
dependency, unchanged**. `#[derive(Serialize)]` on `CheckStatus`, `Check` and `Diagnostics` in
core, and on `LiveStatus` and `LivenessReport` in `crates/web`. `Deserialize` is **not** derived:
nothing in the template parses a probe body, and the template's own tests read it as
`serde_json::Value` (`T1`, `T3`).

##### Ranked runner-up

**A hand-written JSON literal** — kubert's shape, `"alive\n"` as four bytes with a
`text/plain` content type. It is a real and defensible engineering choice for a probe that only a
kubelet will ever read, and it would remove the derive from the hot path entirely. It is the
runner-up rather than the pick because R71 publishes a spec over these routes and R83 fuzzes it,
and because py demonstrates the failure mode of an undeclared ops response shape.

##### Tradeoffs

`serde_derive` is a proc macro and proc macros cost compile time. That cost is already paid: R66
puts `serde` with `derive` in the library crate for the result contract, so these five derives are
marginal. The second tradeoff is that a derived wire shape becomes a contract the moment it is
published in an OpenAPI document, so renaming a field in `Diagnostics` later is a spec change, not
a refactor — which is exactly the property R71 and R83 exist to enforce and is therefore a benefit
wearing a cost's clothes.

##### Parameters

Assumes R66's published `serde` selection and R69's owned `web-extra-surface` clause that the
feature does not gate `serde`/`serde_json`. The byte-identical `assumes` line for
`web-extra-surface` is in the H3 `Parameters` field. No `CONFLICT:`.

##### Migration implications

`crates/core/Cargo.toml`: **no change** — R66 already places `serde` with `derive` there.
`crates/web/Cargo.toml`: **one added row**, `serde = { version = "1.0.229", features =
["derive"] }`, because R69 revision 10's manifest row for that member lists only `axum`, `tokio`
and the `tower` dev-dependency, and `LivenessReport`'s derive lives in the web member. The
executed probe workspace required this row to compile. Plus five `#[derive(Serialize)]`
attributes across the two new source files.

##### Validation strategy

Executed: `T1` decodes the served `/healthz` body as JSON and asserts all four fields including
`status == "ok"`; `T3` decodes `/readyz` and asserts the check names; `T2` asserts the serialized
liveness body is byte-stable. `C11` asserts the core member's dependency tree. Proposed for CI
(R11's wiring): the same assertions as template integration tests, plus R71's spec-drift gate
once it publishes.

##### Confidence & re-verify trigger

**High**, and largely inherited: the crate is not selected by this item. Re-verify if R66 or R69
changes its `serde` version or features, if `https://rustsec.org/packages/serde.html` begins
returning 200 while the `atty` control still does, or if R71 requires a schema derive — in which
case the constraint stated under `Principles and implementation` (no OpenAPI derive in
`crates/core`) is the thing to re-read.

##### Sources

`https://crates.io/api/v1/crates/serde` and `/versions`;
`https://api.github.com/repos/serde-rs/serde`;
`https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open`;
`https://rustsec.org/packages/serde.html` (404) with `https://rustsec.org/packages/atty.html`
(200) as control; `research/topics/66-output-format-surface/DECISION.md` (recommended-stack
table); `docs/port/PARAMETERS.md` row `web-extra-surface`;
`py@b08bccfb:src/py_launch_blueprint/web/app.py:166-182` (the `response_model` comment);
`https://raw.githubusercontent.com/rust-lang/crates.io/main/src/controllers/site_metadata.rs`;
`https://raw.githubusercontent.com/apollographql/router/dev/apollo-router/src/plugins/healthcheck/mod.rs`;
executed checks `T1`, `T2`, `T3`, `C11` — all 2026-09-18.

#### axum 0.8.9

##### Landscape

Bin 1 relative to this item: axum is first-party to the framework decision already made, so for
R80 it is not a candidate but a given. **R69 revision 10 (owner-accepted, unpublished) selects it
at exactly 0.8.9**, and its owned `web-extra-surface` names the version and the default feature
set. The landscape question this member answers is narrower: which of axum's own facilities the
probe routes use, and whether any of them needs supplementing. Answer: `Router`, `routing::get`,
`extract::State`, `http::StatusCode`, `Json` and `response::IntoResponse` — all in the default
feature set — and nothing needs supplementing.

##### Principles and implementation

**Not re-selected here.** What this member establishes is that axum's defaults already satisfy
three probe requirements that would otherwise need code, each verified by execution rather than
by reading the documentation.

- **Method handling.** `get(handler)` answers a `POST` to the same path with **`405 Method Not
  Allowed` and `Allow: GET,HEAD`** — check `T7`, printed literally as
  `T7 POST /healthz status=405 Method Not Allowed allow=Some("GET,HEAD")`. kubert hand-writes
  the same behavior over raw `hyper` (`kubert/src/admin.rs`, the `_ =>` arm of `handle_live`);
  on axum it is free.
- **`HEAD` is served by the `GET` handler** — check `T8`, `HEAD /healthz` → `200`. This matters
  because a probe or a container healthcheck may use `HEAD`, and py's Starlette router behaves
  the same way.
- **A handler may decline state.** `async fn healthz() -> Json<LivenessReport>` is a valid
  handler in a `Router<AppState>`; it simply never receives the state. That is what makes
  requirement AC3 — liveness reaches no dependency — a property of the signature rather than a
  convention, and it was executed as part of `T1` and `T5`.

Router composition follows R69's recorded shape exactly: `routes/ops.rs` exposes
`pub(crate) fn router() -> Router<AppState>` and `build_router` merges it —
`.merge(ops::router())`, the line R69's snippet already annotates `// /healthz now; /readyz is
R80's`. Because it is `.merge` and not `.nest("/v1", …)`, the two paths are unversioned, which is
F308 applied.

##### Dominant choice

Dominant both in the ecosystem and, decisively for this item, by prior decision: 118,234,751
recent downloads, 475,506,585 all-time, 27,176 stars, `archived` false, `pushed_at` 2026-09-18,
33 open issues. R69 compared it against `actix-web`, `poem`, `salvo`, `dropshot` and a
no-framework `hyper` baseline and selected it; nothing in an ops endpoint would reopen that.

##### Qualified shortlist

**Inapplicable — consumed from R69 revision 10, not re-selected.** The prompt's own
`## Out of scope` says so: "this item does not pick a framework, it decides the two probe
endpoints' behavior and describes how they attach to any candidate framework's router". What the
design's portability costs, stated once: the probe contract is framework-independent — a
status code, a JSON body, two paths, a latch, a shared function — and only the thirty lines of
handler wiring are axum-shaped.

##### Excluded by gate

**Inapplicable to the selection** (already made by R69), but the gates are answered for the
record. Gate 1: MIT, compatible with `MIT OR Apache-2.0`. Gate 2: declared `rust-version` 1.80,
comfortably under the floor. Gate 3: `https://rustsec.org/packages/axum.html` → HTTP **404**, no
advisory; **`unsafe` posture stated and verified** — the axum workspace sets
`[workspace.lints.rust] unsafe_code = "forbid"` and `axum/Cargo.toml` opts in with
`[lints] workspace = true`, so the crate forbids `unsafe` outright. Gate 4: R69 records CI on
both matrix OSes; this report additionally built and exercised it on macOS 26.4 `arm64` under
rustc 1.98.0. Gate 5: default features on, per R69's owned value; the async-runtime coupling is
`tokio`, the next member. Gate 6: qualitatively the largest single contributor to the gated
surface's compile time — the offline probe build compiled axum and its tree in **18.0 s** on this
machine — but it is a cost R69 already accepted and one this item adds nothing to.

##### Up-and-comers

**Inapplicable for the framework** (R69 surveyed them). None exists for the narrow thing this
member uses: a probe-specific axum extension. The crates.io census under `### Landscape` found
`q=axum+health`'s top twelve to be OpenTelemetry, MCP and proxy crates, with no health-endpoint
helper among them.

##### Fit for this template

Exact by construction, since the template's web surface is axum. The one fit observation worth
recording is the one that made alternative D (a second admin listener) the scale-out path rather
than the default: axum makes both routes and the request-path middleware share one `Router`, so
excluding the probes from access logs is a middleware concern (F320, R75's) rather than a
topology one — which is the right place for it when the template binds a single port.

##### Recommendation

```rust
// crates/web/src/routes/ops.rs
pub(crate) fn router() -> Router<AppState> {
    Router::new()
        .route("/healthz", get(healthz))   // no State: liveness reaches nothing
        .route("/readyz",  get(readyz))
}
// crates/web/src/lib.rs — R69's recorded composition, unchanged
Router::new().nest("/v1", projects::router()).merge(ops::router()).with_state(state)
```

`axum = "0.8.9"` with default features, declared non-optionally in `crates/web/Cargo.toml` —
**exactly R69 revision 10's manifest row, unchanged.** This member adds no feature and no
dependency.

##### Ranked runner-up

**Inapplicable** — R69 owns the framework choice and records its own runner-up. Recording a
different one here would be this item deciding something the prompt puts out of scope.

##### Tradeoffs

The tradeoff belongs to R69 and is stated there. The one this member adds is small and real: the
probe handlers sit behind whatever middleware stack R75 builds, so a bug in an outer layer can
make `/healthz` fail and trigger a container restart for a reason unrelated to liveness. Both
surveyed production systems avoid it by serving probes on a separate listener (alternative D).
The mitigation available without D is R75's: order the layers so the probes' path is reached
before anything that can reject, and keep `CatchPanicLayer` outside them — which is R75's call,
recorded here as an input to it.

##### Parameters

Assumes R69's owned `web-extra-surface`. The byte-identical registry line is in the H3
`Parameters` field, together with the prose note that revision 10 moves the tree to
`crates/web/` while the registry still carries revision 9's `src/web/` form. No `CONFLICT:`: the
probe routes need nothing in that value changed, and the `crates/web` paths this design uses are
the accepted revision's own.

##### Migration implications

No manifest change. One new file, `crates/web/src/routes/ops.rs`, which R69's file map already
lists with the annotation "`/healthz` now; `/readyz` and its payload are R80's" — this item fills
it in. One `mod ops;` line wherever R69's route modules are declared, and the `.merge(ops::router())`
call that R69's snippet already contains.

##### Validation strategy

Executed here against axum 0.8.9 itself: `T1`, `T3`, `T4`, `T5` (routing and status through
`tower::ServiceExt::oneshot`, R69's own recorded test idiom), `T7` (405 and `Allow`), `T8`
(`HEAD`), `C9`/`C10` (the routes vanish and reappear with the feature). Proposed for the
template's CI, wiring R11's and tiers R32's: the same `oneshot` tests plus a real-listener test,
which is the pairing R69's validation strategy already names.

##### Confidence & re-verify trigger

**High.** Every claim in this member was executed against the exact version. Re-verify if: R69
publishes at a different axum version or feature set; `GET https://crates.io/api/v1/crates/axum/versions`
stops giving 0.8.9 as the newest non-yanked version **in a release that changes `MethodRouter`'s
405/`Allow` behavior or `Json`'s `IntoResponse`** — the two behaviors checks `T7` and `T1` pin;
or `https://rustsec.org/packages/axum.html` begins returning 200 while the `atty` control does.

##### Sources

`https://crates.io/api/v1/crates/axum` and `/versions`;
`https://api.github.com/repos/tokio-rs/axum`;
`https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open`;
`https://rustsec.org/packages/axum.html` (404) with the `atty` 200 control;
`https://raw.githubusercontent.com/tokio-rs/axum/main/Cargo.toml` (`[workspace.lints.rust]
unsafe_code = "forbid"`) and `.../axum/Cargo.toml` (`[lints] workspace = true`);
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (router composition
snippet, file map, owned parameter at line 1791);
`https://raw.githubusercontent.com/olix0r/kubert/main/kubert/src/admin.rs`;
executed checks `T1`, `T3`, `T4`, `T5`, `T7`, `T8`, `C9`, `C10` — all 2026-09-18.

#### tokio 1.53.1

##### Landscape

Bin 1 relative to this item, for the same reason as axum: the runtime is fixed by R69's owned
parameter at **1.53.1** with features `rt-multi-thread`, `net`, `signal`, `macros`, `time`,
`sync`. What this member decides is narrower and is genuinely R80's: **whether `/readyz` calls
the synchronous core function directly or through `tokio::task::spawn_blocking`**, and what the
readiness latch is made of. The alternatives surveyed are `spawn_blocking`, a direct call from
the async handler, and `tokio::task::block_in_place`.

##### Principles and implementation

The principle is R05 revision 2's: the core is synchronous, and *"when — and only when — the
`web` feature is on, axum's `async fn` handlers reach the same synchronous port through
`tokio::task::spawn_blocking`"*. `run_diagnostics` is exactly such a call — it is synchronous and
it touches the filesystem (py's `config-file` check is `cfg_path.exists()`, a `stat`). The
recommendation follows R05 rather than carving an exception:

```rust
let report = tokio::task::spawn_blocking(move || run_diagnostics(&config)).await?;
```

executed as written in checks `T3` and `T4`. **The honest counter-argument is recorded**: a
single `stat` is on the order of microseconds, far below the threshold at which tokio's own
guidance says blocking matters, so a direct call would work today. It is not recommended for two
reasons — consistency with R05's rule, so that no reader has to relitigate which core calls are
"small enough"; and extensibility, because the checks R55 and R57 may add, and the opt-in upstream
check specified above, are exactly the ones that would make a direct call a reactor stall. The
cost is one blocking-pool hop per probe, **unmeasured here**, and R05 already records the
concurrency cost of this bridge as its own open measurement.

The **latch** is `std`, not tokio: `Arc<AtomicBool>` with `Ordering::Release` on the store and
`Ordering::Acquire` on the load. `tokio::sync::watch` would also serve and would let a future
consumer await a readiness transition; it is not used because nothing awaits one and `AtomicBool`
adds nothing to the resolved tree. Where the latch is flipped is the part that matters and it is
R69's function: inside `shutdown_signal()`, before that future resolves, so `/readyz` reports
not-ready for the entire drain window rather than only after the listener has already stopped
accepting.

##### Dominant choice

Dominant in the ecosystem and fixed by prior decision: 228,862,107 recent downloads, 978,381,970
all-time, 33,173 stars, `archived` false, `pushed_at` 2026-09-18, 320 open issues. axum's I/O
path is tokio's, so the runtime is not independently selectable once axum is chosen.

##### Qualified shortlist

For the bridge mechanism — the only thing this member actually chooses — three:

1. **`tokio::task::spawn_blocking`** — selected. R05's own mechanism, executed by R05's check
   C14 and by `T3`/`T4` here.
2. **A direct synchronous call from the `async fn` handler** — qualified, and correct for today's
   check set alone. Rejected on the extensibility ground above.
3. **`tokio::task::block_in_place`** — qualified only on a multi-thread runtime, which R69's
   `rt-multi-thread` feature does give. Rejected because it panics on a current-thread runtime,
   which is what a `#[tokio::test]` uses by default, so it would make the probe untestable in the
   idiom R69 selected — a concrete cost, not a stylistic one.

##### Excluded by gate

**Inapplicable to the selection** (R69's), gates answered for the record. Gate 1: MIT.
Gate 2: declared `rust-version` 1.71. Gate 3: `https://rustsec.org/packages/tokio.html` returns
**HTTP 200** with five historical entries; the newest, `RUSTSEC-2025-0023` (type INFO, unsound
`broadcast` clone), is `Patched … >=1.44.2`, so **1.53.1 carries no open advisory**, and the four
older entries are patched further back still. `unsafe` posture: tokio **uses `unsafe`**
extensively in its runtime internals and does not forbid it — the opposite of axum's posture, and
unavoidable for a work-stealing scheduler and an I/O driver; the mitigation is the crate's
Miri/loom test suite and its advisory record, both public. Gate 4: R69 records both matrix OSes;
executed here on macOS. Gate 5: features exactly as R69's owned value lists them, `sync` included
— R69 verified that `sync` is enabled by none of `signal`, `net`, `rt-multi-thread`, `time` or
`macros` and added it for `serve_until`'s `oneshot` channel; this member relies on `rt-multi-thread`
for `spawn_blocking` and adds none. Gate 6: the dominant compile-time cost of the gated surface
alongside axum; nothing added by this item.

##### Up-and-comers

`smol`, `async-std` and `glommio` exist as runtime alternatives and are **irrelevant here**: axum
is built on tokio's `hyper` stack, so the runtime is not separately choosable. No up-and-comer
exists for the narrow mechanism this member selects; `spawn_blocking` is tokio's own documented
answer for calling blocking code from async and has no challenger.

##### Fit for this template

Exact, and it is the seam that makes the whole item work. A synchronous shared function callable
by both a CLI and an async handler is precisely the arrangement R05 designed the bridge for, and
`/readyz` is arguably its cleanest instance: one call, no streaming, no cancellation subtleties.
The only fit wrinkle is that `spawn_blocking`'s `JoinHandle` can report a panic in the closure,
so the handler must decide what a panicking diagnostics collection means. The recommendation is
that it maps to the same `503` as a failed check, since a probe that panics is by definition not
ready; the executed probe used `.expect(...)`, which is **not** the recommended production shape
and is named here as such.

##### Recommendation

`tokio = { version = "1.53.1", features = ["rt-multi-thread", "net", "signal", "macros",
"time", "sync"] }` in `crates/web/Cargo.toml` — **exactly R69 revision 10's row, unchanged**.
`/readyz` calls `run_diagnostics` inside `spawn_blocking`; a `JoinError` maps to `503` rather
than propagating. The readiness latch is `std::sync::Arc<std::sync::atomic::AtomicBool>` on
`AppState`, flipped by `Readiness::begin_draining()` inside R69's `shutdown_signal()` before it
resolves.

##### Ranked runner-up

**The direct synchronous call** (shortlist entry 2). It is the shape to adopt if P03 measures the
`spawn_blocking` hop and finds it material at probe cadence — which is unlikely, since probe
cadence is seconds — and it becomes *wrong* the moment any check does real I/O. For the latch,
the runner-up is `tokio::sync::watch::Sender<bool>`, which costs nothing extra in the manifest
(`sync` is already enabled) and is the shape to take if anything ever needs to *await* the
transition rather than read it.

##### Tradeoffs

`spawn_blocking` moves work to a pool whose default bound is large, so a pathological check that
blocks forever consumes a pool thread per probe rather than stalling the reactor — a better
failure mode, but not a free one, and the reason the specified opt-in upstream check carries a
timeout. The second tradeoff is the one R05 already owns: no concurrency measurement of this
bridge exists, in that decision or in this one.

##### Parameters

Assumes R69's owned `web-extra-surface` (byte-identical line in the H3 `Parameters` field,
with the `crates/web` prose note) and R05 revision 2's synchronous-core decision, which is not a
registry parameter. No `CONFLICT:`.

##### Migration implications

No manifest change — R69's row already carries every feature this member uses. In
`crates/web/src/lib.rs`: a `Readiness` newtype, one field on `AppState`, and one
`readiness.begin_draining()` call inside `shutdown_signal()`. R69's own confidence note already
records that `AppState`'s exact field list is expected to be refined by later items, so this is
the anticipated kind of change rather than a departure.

##### Validation strategy

Executed: `T3` and `T4` run the handler's `spawn_blocking` path end to end on a multi-thread
runtime; `T4` proves the latch changes the served status; `T5` proves it does **not** change
`/healthz`. Proposed for the template's CI, and **this is the check that would catch the
highest-consequence regression**: a process-level test that sends `SIGTERM` to the running
`<app>-serve` binary and asserts that a `GET /readyz` issued during the drain window answers
`503` while the in-flight request completes and the process exits `143` — the R69/R67 integers.
It is P03's because no binary exists.

##### Confidence & re-verify trigger

**High** for the bridge and the latch, both executed. **Medium** for the drain-window behavior,
which is reasoned from R69's `serve_until` shape and not executed, since it needs a process.
Re-verify if: R05 is reopened and the core becomes async, which deletes this member entirely;
R69 changes tokio's version or feature list; `https://rustsec.org/packages/tokio.html` gains an
entry whose `Patched` range excludes 1.53.1; or R77 publishes a readiness-propagation delay,
which adds one `sleep` between the latch flip and the drain.

##### Sources

`https://crates.io/api/v1/crates/tokio` and `/versions`;
`https://api.github.com/repos/tokio-rs/tokio`;
`https://api.github.com/search/issues?q=repo:tokio-rs/tokio+is:issue+is:open`;
`https://rustsec.org/packages/tokio.html` (200) and
`https://rustsec.org/advisories/RUSTSEC-2025-0023.html` (the `Patched` ranges), with the `atty`
200 control; `research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` (the
`spawn_blocking` rule and check C14);
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (`serve_until`, the
`sync`-feature finding, the Cloud Run SIGTERM quotation);
`https://raw.githubusercontent.com/apollographql/router/dev/apollo-router/src/plugins/healthcheck/mod.rs`
and `https://raw.githubusercontent.com/olix0r/kubert/main/kubert/src/admin.rs` (both latch
designs); executed checks `T3`, `T4`, `T5` — all 2026-09-18.

### Compatibility

The five members are proven to work together by a **version matrix resolved, built and exercised
in this run**, not by assertion. A throwaway workspace was created under `$TMPDIR`, built
`--offline`, run, and deleted: root package `facade` plus `crates/core` and `crates/web`, edition
**2024** throughout, `rust-version = "1.96"` declared on every manifest, resolving **axum
0.8.9 · tokio 1.53.1 · serde 1.0.229 · serde_json 1.0.151 · tower 0.5.3** (dev-dependency, for
the `ServiceExt::oneshot` idiom) — the exact versions R69 revision 10 and R66 select. It compiled
in 18.0 s on macOS 26.4 `arm64` under rustc 1.98.0 and cargo 1.98.0, and all **thirteen**
checks passed — the two version-hazard checks `A` and `B`, eight behavioral tests `T1`-`T8`,
and three graph assertions `C9`-`C11`. That is the compatibility evidence: the members were
not merely shown to resolve, they were shown to serve the recommended contract.

Three graph facts from the same matrix, each a compatibility claim in its own right:

- `cargo tree -p facade --edges normal` with the feature **off** contains **zero** occurrences of
  `axum` (check `C9`). The probe surface and its whole transitive cost are absent from a default
  build, which is what R69's owned parameter promises and what R51's image will rely on.
- `cargo tree -p facade --features web --edges normal` brings in the `crates/web` member and,
  through it, axum and tokio (check `C10`).
- `cargo tree -p probe-core --edges normal` is **`serde` and its four proc-macro dependencies and
  nothing else** (check `C11`) — the member that holds the shared diagnostics function names no
  web crate at all, which is the compatibility property R02's boundary mechanism exists to
  guarantee and the reason the CLI can call the same function without pulling a runtime.

**A shared adopter for the pattern, distinct from the version matrix:** `apollographql/router`
ships axum, tokio and serde in one binary and serves a liveness/readiness endpoint out of them —
the same four-piece stack, in production, at scale (GitHub `stargazers_count` **978**,
`pushed_at` 2026-09-18, 193 open issues, `GET https://api.github.com/repos/apollographql/router`
and the `search/issues` endpoint, 2026-09-18). **The evidence gap, stated:** no public repository
was found that ships *this template's exact combination* — a synchronous shared diagnostics
function called from both a CLI and an axum readiness handler — so the cross-member claim rests on
the resolved-and-executed matrix here plus R05's own executed bridge (its check C14), not on a
third-party reference implementation. R05 records the same gap for the same reason.

### Parameters

**Owned parameters: none.** `research/CLAUDE.md`'s row for R80 carries `—` in the `owns` column,
and this report adds no registry parameter. The contract it fixes — the two paths, their status
codes, their payloads and the shared function — is recorded in the decision text, not in the
shared-parameter registry.

**Consumed parameters.** The item's `## Couplings` block declares an empty `- consumes:` list, so
none of the following is a registered dependency; each is nonetheless load-bearing for the
recommendation and is therefore declared rather than left implicit. Every value below is
**byte-identical to its row in `docs/port/PARAMETERS.md`** as read on 2026-09-18.

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**Prose note beside the `web-extra-surface` line, required because the registry and the accepted
revision disagree about paths.** The line above carries the registry's current bytes, which are
**revision 9's**: it names the library module `src/web/`, tests "gated file-level with
`#![cfg(feature = "web")]`", and `web = ["dep:axum", "dep:tokio"]` on one manifest. **R69
revision 10 is owner-accepted and unpublished** (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`,
its `- owns web-extra-surface` line at line 1791; owner rulings W1-R02 / W0-R69c) and moves the
tree to the optional workspace member `crates/web/`, with `web = ["dep:rs-launch-blueprint-web"]`
on the root package, `axum` and `tokio` declared **non-optionally** in `crates/web/Cargo.toml`,
and the web tests in `crates/web/tests/` with **no** file-level `cfg` because the whole member is
optional. **This report's design uses revision 10's paths** — `crates/web/src/routes/ops.rs`,
`crates/web/src/lib.rs`, `crates/core/src/diagnostics.rs` — and its executed probe workspace is
built in that shape. **This is not a `CONFLICT:`**: the recommendation needs nothing in R69's
value changed, only the accepted revision's paths, which R69 will publish itself. **R69's
republication is a re-verify trigger** for every file path in this report's
`### Migration implications`.

Two further published values bind the recommendation without being consumed as values, so they
are named here rather than given an `assumes` line. **R67's `error-taxonomy-exit-codes`**: the
serve binary's drain exits (143 / 130 / 1 / 0) are R69's application of it and are untouched here;
separately, the CLI `doctor` command's exit code is **not assigned by this report** and is
recorded under `### Migration implications` as an open scoping question against R67's append-only
catalog. **R01's `http-transport-injection-seam`** appears as an `assumes` line above because the
specified opt-in upstream readiness check calls the erased service — core's port — and never a
concrete adapter; with the check off by default, nothing in the shipped design dials it.

**`CONFLICT:` lines: none.** No consumed value needs to change for this recommendation. The two
places a reader might expect one, and why neither is: R49's `build-tool-output-shape`
no-`build.rs` clause **excludes** `built`, `vergen` and `shadow-rs`, and the recommendation
declines all three rather than asking for the clause to move; R69's `web-extra-surface` differs
between the registry and the accepted revision, which is a publication lag, not a needed change.

### Migration implications

File-level, written against R02 revision 1's four-package workspace and R69 revision 10's
accepted paths.

| File | Change |
|---|---|
| `crates/core/src/diagnostics.rs` (new) | `CheckStatus`, `Check`, `Diagnostics`, `Diagnostics::has_error`, `run_diagnostics(&Config) -> Diagnostics`. `#[derive(Serialize)]` only — no framework or OpenAPI derive ever enters this member |
| `crates/core/src/lib.rs` | one `pub mod diagnostics;`. Whether it is re-exported from the facade's barrel is R04's rule to apply |
| `crates/core/Cargo.toml` | **no change** — `serde` with `derive` is already present for R66's result contract |
| `crates/web/src/routes/ops.rs` | filled in. `LiveStatus`, `LivenessReport`, `async fn healthz()` (no `State`), `pub fn readiness_response(draining: bool, report: Diagnostics) -> Response`, `async fn readyz(State(..))`, `pub(crate) fn router() -> Router<AppState>` registering `/healthz` and `/readyz`. R69's file map already reserves this file with the note "`/healthz` now; `/readyz` and its payload are R80's" |
| `crates/web/src/lib.rs` | a `Readiness(Arc<AtomicBool>)` newtype with `accepting()`, `is_accepting()`, `begin_draining()`; one `readiness: Readiness` field on `AppState`; one `readiness.begin_draining()` call inside `shutdown_signal()`, **before** that future resolves. `build_router`'s `.merge(ops::router())` line is already in R69's recorded snippet |
| `crates/web/tests/web_api.rs` | the eight probe tests `T1`–`T8` of this report, adapted to the template's types |
| `crates/web/Cargo.toml` | **gains `serde = { version = "1.0.229", features = ["derive"] }`**, and `serde_json` only if R70's envelope is constructed in this member directly. R69 revision 10's row for this manifest lists **only** `axum` 0.8.9 (defaults on), `tokio` 1.53.1 with `rt-multi-thread`/`net`/`signal`/`macros`/`time`/`sync`, and `tower` 0.5.3 under `[dev-dependencies]` — R66 places `serde` in the *library* crate, which under R02's topology is `crates/core`, not here. The executed probe workspace had to add exactly these rows to compile `#[derive(Serialize)]` on `LivenessReport`; a manifest written from "no change" would not build. `axum`, `tokio` and `tower` are unchanged |
| `Cargo.toml` (root) | **no change from this item.** If R22 selects workspace version inheritance — which check `A` shows is required for `/healthz` to report the facade's version — the `[workspace.package] version` key and each member's `version.workspace = true` are R22's and R02's edit, not this one's |

**Not created by this item**, and named so a later reader does not look for them here:
`problems.rs` (R70 — the envelope `/readyz`'s 503 reuses); the OpenAPI annotations on these
routes and any DTO they need (R71, subject to the no-derive-in-core constraint stated above); the
access-log exclusion for both paths (R75, F320); `settings.rs` and any readiness-propagation
delay value (R77); the `Dockerfile` and its `HEALTHCHECK` decision (R51, F337); the CLI `doctor`
subcommand's flag surface and exit code — **owned by no item**, with R67's append-only catalog
offering `RSLB104` (→ 1) and `RSLB203` (→ 2) as the nearest existing rows and py using
`ExitCode.CONFIG`; and any check capable of reaching `CheckStatus::Error` (R55 for an unparsable
config document, R57 for an unusable directory).

### Validation strategy

**Executed in this run.** A throwaway Cargo workspace under `$TMPDIR` (created, built `--offline`,
run, and deleted), edition 2024, `rust-version = "1.96"`, on macOS 26.4 `arm64` with rustc 1.98.0
/ cargo 1.98.0, resolving axum 0.8.9, tokio 1.53.1, serde 1.0.229, serde_json 1.0.151, tower
0.5.3. Commands: `cargo build --offline -p probe-web`, `cargo test --offline -p probe-web --test
probes -- --nocapture`, and three `cargo tree --offline` invocations. **All thirteen checks in
the table below passed** — `A` and `B`, `T1`-`T8`, and `C9`-`C11`.

| Check | What it asserts | Observed |
|---|---|---|
| `A` | `env!("CARGO_PKG_VERSION")` inside a workspace member reports the **member's** version, and `std::env::consts::{OS, ARCH}` resolve with no `build.rs` in the tree | `facade_env_CARGO_PKG_VERSION=0.4.2`, `web_member_env_CARGO_PKG_VERSION=0.1.0`, `std_env_consts_OS=macos`, `std_env_consts_ARCH=aarch64`, `os_and_arch_are_static_str=true` |
| `B` | `[workspace.package] version` + `version.workspace = true` repairs it | both packages report `0.4.2` |
| `T1` | `GET /healthz` → 200 and the four fields | `{"status":"ok","version":"0.4.2","os":"macos","arch":"aarch64"}` |
| `T2` | the liveness body is byte-stable across calls | `byte-stable=true` |
| `T3` | warn-only checks keep readiness | `200`, body carries `build`/`config-file`/`credential` with `warn` details |
| `T4` | the drain latch removes traffic | `503 Service Unavailable`, body carries the report under `diagnostics` |
| `T5` | draining is not a restart signal | `GET /healthz` still `200` |
| `T6` | a hand-built error report yields 503 **without touching the environment** | `503` from the pure `readiness_response(false, report)` |
| `T7` | probe method handling | `POST /healthz` → `405 Method Not Allowed`, `Allow: GET,HEAD` |
| `T8` | `HEAD` is served by the `GET` handler | `200` |
| `C9` | a default build has no probe surface | `axum` occurs **0** times in `cargo tree -p facade --edges normal` |
| `C10` | `--features web` brings it back | the `crates/web` member and axum appear |
| `C11` | the shared-function member names no web crate | `probe-core` → `serde` → `serde_core` + `serde_derive` and nothing else |

`T6` is the check that matters most for the synthesizer: because it drives the pure
`readiness_response` function rather than the handler, the 503 branch is provable on any machine
in any environment — which is exactly what py's suite lacks, and why py's own comment records that
its readiness test can only ever see 200.

**Proposed for the template's CI, not run** (job wiring is R11's, tiers are R32's): `cargo test
--features web` and `cargo build --features web --bin <app>-serve` on `ubuntu-latest` and
`macos-latest`; `T1`–`T8` as template integration tests through `oneshot` and once against a real
listener; a version-consistency test asserting `GET /healthz`'s `version` equals what `--version`
prints, the Rust analogue of py's `tests/meta/test_version_consistency.py`; a `cargo check` leg
pinned to the declared `rust-version`; and — the highest-value check that needs a process — a
`SIGTERM` test asserting that `GET /readyz` answers `503` during the drain while an in-flight
request completes and the process exits `143`, which is the R69/R67 integer pair. None of these
can run today: no Rust code exists in this repository.

### Confidence & re-verify trigger

**High** for the endpoint contract, the shared-function placement, the latch, the method
handling, the liveness payload's mechanism and the feature gating: each rests on a published
artifact or a prior owner-accepted decision, **and** on a check executed on this machine against
the exact crate versions. **High** for the census answering the LOW question, which has a printed
denominator (`meta.total` 6,487 / 5,271 / 28,351 across three single-word sweeps plus five
targeted queries). **Medium-high** for the drain-window behavior: the latch is executed, but the
interaction with R69's `shutdown_signal()` and `serve_until` is reasoned from R69's recorded
snippet, not run, because it needs a process. **Medium** for the exact field list of
`LivenessReport` — declining uptime is a judgement with a stated cost, and adding a commit SHA is
a one-field change — and for the initial check set, which R55 and R57 will extend. **Low
confidence is claimed nowhere**, and two figures are explicitly absent rather than estimated:
`git-version`'s open-issue count (HTTP 422) and issue responsiveness for seven of the eight
crates.

Re-verify on any of: **R69** republishing `web-extra-surface` at revision 10, which fixes every
file path in `### Migration implications` and is the single most likely trigger; **R70**
publishing the problem envelope, which fixes the 503 body's member names and whether
`diagnostics` is legal as an extension; **R71** publishing and requiring a schema derive, which
meets the stated no-derive-in-`crates/core` constraint; **R22** publishing the version accessor,
which must satisfy the core-defined, workspace-safe requirement check `A` demonstrates;
**R55** or **R57** publishing a check that can reach `CheckStatus::Error`, which makes the
diagnostic half of the 503 branch reachable on its own; **R77** publishing the readiness
propagation delay and drain deadline, whose sum must fit the platform's kill window; **R51**
publishing, which decides how a shell-free image probes `/healthz`; **R75** publishing the
middleware order, which decides what can fail *in front of* `/healthz`; **R05** being reopened to
an async core, which deletes the `spawn_blocking` hop; `GET https://crates.io/api/v1/crates/axum/versions`
ceasing to give 0.8.9 as newest non-yanked **in a release changing `MethodRouter`'s 405/`Allow`
behavior or `Json`'s `IntoResponse`**; `https://rustsec.org/packages/{axum,serde,tokio}.html`
changing status while the `atty` control holds at 200;
`GET https://crates.io/api/v1/crates/{shadow-rs,git-version}/versions` beginning to return a
non-null `rust_version`, which reverses a gate-2 exclusion; or the Kubernetes probe documentation
changing the quoted sentences. Calendar re-verify: **2027-03-18**.

### Sources

**Kubernetes (normative for what a probe means)** —
`https://kubernetes.io/docs/concepts/workloads/pods/probes/` (liveness restarts the container;
readiness failure removes the Pod's IP from EndpointSlices; the cascading-failure caution; the
back-end-dependency caution), 2026-09-18;
`https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/`
("Any code greater than or equal to 200 and less than 400 indicates success"; the canonical
`httpGet: path: /healthz` example), 2026-09-18;
`https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/`, 2026-09-18 (fetched; its
probe definitions are carried on the `probes/` page above);
`https://kubernetes.io/docs/concepts/containers/images/`, 2026-09-18 (fetched to look for a
`HEALTHCHECK` statement; the page does not mention one).

**Rust and Cargo first-party references** —
`https://doc.rust-lang.org/std/env/consts/index.html`;
`https://doc.rust-lang.org/cargo/reference/environment-variables.html`;
`https://doc.rust-lang.org/cargo/reference/build-scripts.html`.

**Figures** — `https://crates.io/api/v1/crates/<name>` and `/versions` for `serde`, `serde_json`,
`axum`, `tokio`, `built`, `vergen`, `git-version`, `shadow-rs`, `rustc_version`,
`kubert-prometheus-process`; `https://crates.io/api/v1/crates?q=<term>&per_page=<n>&sort=downloads`
for `health+check`, `readiness`, `healthz`, `kubernetes+probe`, `axum+health`, `health`, `probe`,
`liveness`; `https://api.github.com/repos/<o>/<r>` and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for `serde-rs/serde`,
`serde-rs/json`, `tokio-rs/axum`, `tokio-rs/tokio`, `lukaslueg/built`, `rustyhorde/vergen`,
`fusion-engineering/rust-git-version`, `baoyachi/shadow-rs`, `olix0r/kubert`,
`apollographql/router`, `rust-lang/crates.io`;
`https://api.github.com/repos/lukaslueg/built/issues?state=all&sort=created&direction=desc&per_page=10`
and `https://api.github.com/repos/lukaslueg/built/issues/{101,100,98,93}/comments?per_page=5`.
All 2026-09-18.

**Advisories** — `https://rustsec.org/packages/{serde,serde_json,axum,tokio,built,vergen,git-version,shadow-rs}.html`
and `https://rustsec.org/packages/atty.html` (control); `https://rustsec.org/advisories/RUSTSEC-2025-0023.html`.
All 2026-09-18.

**Production source, read at a URL** —
`https://raw.githubusercontent.com/olix0r/kubert/main/kubert/src/admin.rs`;
`https://raw.githubusercontent.com/apollographql/router/dev/apollo-router/src/plugins/healthcheck/mod.rs`
and `.../apollo-router/src/axum_factory/axum_http_server_factory.rs`;
`https://raw.githubusercontent.com/rust-lang/crates.io/main/src/router.rs`,
`.../src/controllers/site_metadata.rs`, `.../crates/crates_io_version/src/lib.rs`,
`.../crates/crates_io_heroku/src/lib.rs`;
`https://raw.githubusercontent.com/tokio-rs/axum/main/Cargo.toml` and `.../axum/Cargo.toml`;
`https://raw.githubusercontent.com/lukaslueg/built/master/README.md`;
`https://raw.githubusercontent.com/rustyhorde/vergen/master/README.md` and
`.../vergen/src/lib.rs`;
`https://raw.githubusercontent.com/baoyachi/shadow-rs/master/README.md`;
`https://raw.githubusercontent.com/fusion-engineering/rust-git-version/master/git-version/README.md`,
`.../git-version/src/lib.rs`, `.../git-version-macro/src/lib.rs`. All 2026-09-18.

**Pinned source repositories** — `py@b08bccfb`:
`src/py_launch_blueprint/web/app.py` (lines 49, 93–99, 153–159, 166–198),
`src/py_launch_blueprint/core/diagnostics.py` (lines 47–91, 116),
`src/py_launch_blueprint/core/models.py` (lines 148–174),
`src/py_launch_blueprint/cli/main.py` (lines 37, 103–124),
`tests/web/test_app.py` (lines 61–75), `Dockerfile` (lines 27–32) — all read via
`git -C ~/c/py-launch-blueprint show b08bccfb:<path>`. `ts@cb1cbcb2`: `src/router.ts`, read via
`git show cb1cbcb2:src/router.ts`, together with a case-insensitive `git grep -lni` over `src/`
at the pin for `healthz|readyz|diagnostics|doctor`, which returns that one file and three
unrelated matches.

**This repository** — `docs/port/COMMONALITY.md` (F303, F305, F306, F308, F317, F320, F328,
F329, F336, F337, F185, F186); `docs/port/areas/web-service.md:35`;
`docs/port/areas/dev-experience-repo-hygiene.md:16,88`; `docs/port/PARAMETERS.md` (every
`assumes` value, read for byte-identity on 2026-09-18); `docs/port/README.md` (verdict
vocabulary); `docs/planning/p02/owner-decisions.md` §11 (the reference architecture's standing
status) and its "Two things you should know" section (the withdrawn MSRV-gate ruling);
`inputs/owner-reference-axum-companion-stack-2026-09-16.md` (C4, C10, C13, C15, the reference
`Cargo.toml`, the Cloud Run runbook);
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (revision 10);
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (revision 1);
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` (revision 2);
`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/DECISION.md` (revision 1);
`research/topics/66-output-format-surface/DECISION.md`;
`research/topics/22-runtime-version-accessor/prompts/runtime-version-accessor.prompt.md`;
`research/CLAUDE.md` (the R80 row's empty `owns` column).

**Method notes.** Endpoints queried: the crates.io crate, versions and search APIs; the GitHub
REST repository, issue-search, issue-list and issue-comments endpoints, via keyring-authenticated
`gh api` at no more than one call per 20 seconds (a shell script with `sleep 21` between calls,
which is why the retrieval timestamps in the collection log advance in 21-second steps);
`rustsec.org` package and advisory pages over `curl` with a descriptive User-Agent; four
`kubernetes.io` documentation pages; `raw.githubusercontent.com` for production source and
maintainer READMEs; and the two pinned source repositories through `git show <pin>:<path>`.
**What could not be verified, listed rather than smoothed over.** (1) `git-version`'s open-issue
`total_count`: `GET https://api.github.com/search/issues?q=repo:fusion-engineering/rust-git-version+is:issue+is:open`
answered HTTP 422 *"The listed users and repositories cannot be searched"* while
`GET https://api.github.com/repos/fusion-engineering/rust-git-version` answered 200 for the same
path; `open_issues_count` was **not** substituted, because the figure table forbids it.
(2) Issue responsiveness for seven of the eight crates — computed only for `lukaslueg/built`,
with the cost and the reason stated in full under `### Members`.
(3) No latency, throughput, memory or binary-size figure is claimed anywhere in this report;
none was measured, and in particular the cost of the `spawn_blocking` hop under concurrency is
unmeasured here exactly as it is in R05.
(4) The drain-window behavior — `/readyz` answering 503 for the whole window between the signal
and the exit — is reasoned from R69's recorded `serve_until` snippet and **not executed**, because
it needs a running binary and none exists.
(5) Whether Kubernetes honours a Dockerfile `HEALTHCHECK` is **not claimed**: the four
`kubernetes.io` pages read for this report configure probes on the Pod spec and none mentions the
directive, which is an observation about those pages and not a statement about kubelet behavior.
(6) All executed checks ran on **macOS 26.4 `arm64` only**; `ubuntu-latest` was not exercised,
and every member's gate-4 answer for Linux rests on the crates' own CI and on R69's and R66's
prior records rather than on a run here.
