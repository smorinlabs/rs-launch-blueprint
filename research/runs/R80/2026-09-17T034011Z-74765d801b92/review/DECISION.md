# 2026-09-18 — R80 — health-probe-endpoints (bundle, Focused) — decision (revision 1)

Synthesized 2026-09-18 by a fresh context that produced none of this item's raw
reports. Inputs read in full: `inputs/prompt.md` (binding), `inputs/PARAMETERS.md`
and the live `docs/port/PARAMETERS.md`, `inputs/owner-reference-axum-companion-stack-2026-09-16.md`
with `docs/planning/p02/owner-decisions.md` section 11, `docs/port/README.md`,
`docs/port/COMMONALITY.md` rows F303/F308/F320/F328/F329/F337, `research/CLAUDE.md`,
and the single registered engine report `raw/opus.md`. No template code exists in
this repository and none was written here; every executed check runs against a
throwaway workspace created under `$TMPDIR` and deleted, or against a live source.

## Decision

**Every decision in this programme is a proposal validated in the implementation
phase** (owner ruling, 2026-09-10). This one records what the research found and
what it recommends; P03 builds the template and its CI proves the recommendation.
The list of what P03 must validate is under `## Engines`. A decision that does not
survive implementation is revised against this recorded research, not researched
again from scratch.

**Recommendation — `probe-contract/v1`: one shared synchronous diagnostics
function in `crates/core`, two hand-written axum handlers in
`crates/web/src/routes/ops.rs`, and an `AtomicBool` readiness latch flipped by
R69's shutdown signal. No new crate, at any version.**

Concretely:

- `GET /healthz` is a **stateless** handler — it declines axum's `State`, so it
  can reach no dependency, no lock and no pool by construction — answering `200`
  with `{"status":"ok","version":…,"os":…,"arch":…}`, built from a version
  accessor defined once in `crates/core` (the mechanism is R22's) and
  `std::env::consts::{OS, ARCH}`.
- `GET /readyz` reads the readiness latch, then calls
  `rs_launch_blueprint_core::diagnostics::run_diagnostics` — the same function
  the CLI's `doctor` command calls — through `tokio::task::spawn_blocking`. It
  answers `200` with the serialized report when the process is accepting and no
  check is `error`, and `503` otherwise, carrying the report in the body through
  R70's problem envelope (see the standing constraint on R70 below).
- Both paths are **unversioned**, per F308 applied rather than re-derived; both
  accept `GET` and `HEAD`; both live inside the optional `crates/web` member and
  therefore vanish from a default build.

**Ledger rows this settles.** **F328** (liveness endpoint reports version +
runtime info) and **F329** (readiness endpoint runs the same diagnostics as the
CLI `doctor` command), both `DIVERGENT`, both owned by R80
(`docs/port/COMMONALITY.md:332-333`, asserted by check `O7`). **F308** (`ADOPT`,
owned by no item) is applied to the two paths, not re-derived, exactly as the
prompt instructs. No `BASELINE-REVIEW:` finding is raised: the one `ADOPT` row
this item touches is applied unchanged, and the design findings below concern
F329, a row this item owns the answer to.

**Fitness gate 1** is recorded, for every candidate named in this decision, as:

inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool

The reason is that the owner struck the
gate from every item's evaluation, knowingly extending it to crates compiled into
the shipped artifact (`docs/port/OWNER-REVIEW.md`, asserted by check `O11`). The
licence strings in the figures table below are recorded as facts about the crates,
not as a compatibility verdict. `raw/opus.md` answers gate 1 per candidate; those
verdicts are **not carried**. What the ruling does not touch is untouched here:
this repository's own `license = MIT OR Apache-2.0` expression stands, and nothing
in this recommendation commits a third-party file into the repository.

### The recommendation — one stack

Five members. Two are decided by this item; three are consumed from
owner-accepted decisions and are re-verified here rather than re-selected.

| # | Member | Version | Status in this decision | What it supplies |
|---|---|---|---|---|
| 1 | `rs_launch_blueprint_core::diagnostics` (the shared contract — no crate) | — | **decided here** | `CheckStatus`, `Check`, `Diagnostics`, `Diagnostics::has_error`, `run_diagnostics`; the one place the check list exists |
| 2 | `std` build identity (`std::env::consts::{OS, ARCH}` + Cargo's compile-time version — no crate) | — | **decided here** | the liveness payload's fields, with no build script and no git dependency |
| 3 | `serde` | 1.0.229, `features = ["derive"]` | consumed from R66 | the derived wire shape for both payloads |
| 4 | `axum` | 0.8.9, default features | consumed from R69 revision 10 | `Router`, `routing::get`, `State`, `StatusCode`, `Json`, and — free — `405` with `Allow: GET,HEAD` and `HEAD` served by the `GET` handler |
| 5 | `tokio` | 1.53.1, features `rt-multi-thread, net, signal, macros, time, sync` | consumed from R69 revision 10 | `spawn_blocking`, R05's bridge from the async handler to the synchronous core |

The **marginal cost of this recommendation is zero crates**: every mechanism is
`std`, or one of the three crates R69, R66 and R05 already put in the tree. Check
`C11` shows that the member holding `run_diagnostics` resolves `serde v1.0.229`
and its four proc-macro dependencies and names no web crate at all; check `C9`
shows a default build's normal dependency graph contains `axum` on **0** lines.

**Figures, collected exactly as the prompt's table prescribes** — 90-day downloads
= `crate.recent_downloads` and all-time = `crate.downloads` from
`GET https://crates.io/api/v1/crates/<name>`; last release = the newest
`yanked: false` entry from `GET https://crates.io/api/v1/crates/<name>/versions`;
stars, `archived` and `pushed_at` from `GET https://api.github.com/repos/<o>/<r>`;
open issues from `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`, never `open_issues_count`). All retrieved **2026-09-18 (UTC)**,
GitHub at no more than one call per 20 s. Download counters move between runs; see
the comparison rule under `## Empirical check`.

| Crate | 90-day | all-time | last release | declared `rust-version` | licence (fact, not a gate) | stars | archived | open issues |
|---|---|---|---|---|---|---|---|---|
| `serde` | 314,208,639 | 1,410,307,353 | 1.0.229, 2026-07-18 | 1.56 | MIT OR Apache-2.0 | 10,826 | false | 319 |
| `serde_json` | 317,743,616 | 1,313,719,716 | 1.0.151, 2026-07-20 | 1.71 | MIT OR Apache-2.0 | 5,635 | false | 191 |
| `axum` | 118,234,751 | 475,506,585 | 0.8.9, 2026-04-14 | 1.80 | MIT | 27,176 | false | 33 |
| `tokio` | 228,862,107 | 978,381,970 | 1.53.1, 2026-07-20 | 1.71 | MIT | 33,173 | false | 320 |
| `built` | 18,238,136 | 63,168,750 | 0.8.1, 2026-05-21 | 1.87 | MIT | 198 | false | 8 |
| `vergen` | 8,605,373 | 52,213,287 | 10.0.3, 2026-08-24 | 1.96.0 | MIT OR Apache-2.0 | 473 | false | 4 |
| `shadow-rs` | 2,184,341 | 10,812,524 | 2.0.0, 2026-04-23 | **none declared** | MIT AND Apache-2.0 | 702 | false | 8 |
| `git-version` | 5,528,772 | 24,871,629 | 0.3.9, **2023-12-13** | **none declared** | BSD-2-Clause | 131 | false | **absent (HTTP 422)** |

The `serde`, `serde_json`, `axum` and `tokio` GitHub rows are **carried from
`raw/opus.md` without re-collection**; only their crates.io pins were re-verified
here (check `L1`). The four build-metadata repositories' GitHub rows **were**
re-collected (check `L9`) because a gate-2 exclusion turns on them.
`git-version`'s open-issue figure is **absent, not estimated**: the issue-search
endpoint answered HTTP 422 *"The listed users and repositories cannot be
searched"* for `repo:fusion-engineering/rust-git-version` on both 2026-09-18
collections, while the plain repository endpoint answered 200 for the same path.
The prompt forbids substituting `open_issues_count`, so nothing is substituted.

**Fitness gates 2 to 6**, answered per candidate before popularity was weighed.
Gate 2 (declared MSRV within `msrv-policy`) **excludes `shadow-rs` 2.0.0 and
`git-version` 0.3.9**: `GET https://crates.io/api/v1/crates/<name>/versions`
returns `rust_version: null` for the newest non-yanked version of each (check
`L2`), and the owner withdrew the provisional "unproven rather than failed"
reading in favour of the auditors' strict one
(`docs/planning/p02/owner-decisions.md`, *"Two things you should know"*), under
which a failed gate excludes. Gate 3: `https://rustsec.org/packages/<name>.html`
answers **404** for `serde`, `serde_json`, `axum`, `built`, `vergen`, `shadow-rs`
and `git-version`, and **200** for `tokio`, whose newest entry
`RUSTSEC-2025-0023` lists an open-ended patched range `>=1.44.2` that 1.53.1
satisfies — with `atty` answering **200** as a positive control, so the 404s are
evidence of absence rather than of an outage (checks `L3`, `L4`). `unsafe`
posture: axum's workspace sets `[workspace.lints.rust] unsafe_code = "forbid"`
and `axum/Cargo.toml` opts in with `[lints] workspace = true`, so axum forbids
`unsafe`; tokio uses `unsafe` extensively in its runtime internals and does not
forbid it, which is unavoidable for a work-stealing scheduler and is mitigated by
its Miri/loom suite and its public advisory record. Both postures are carried
from `raw/opus.md`; the axum manifest read was not re-executed here. Gate 4:
every executed check in this decision ran on **macOS 26.4 `arm64` only**;
`ubuntu-latest` was **not** exercised, and each member's Linux answer rests on the
crates' own CI and on R66's and R69's prior records. Gate 5: default features for
axum, the six-feature list R69 owns for tokio, `derive` only for serde; the
async-runtime coupling is tokio, and this item adds no feature to any of them.
Gate 6: qualitatively, axum and tokio dominate the gated surface's compile time —
the probe workspace compiled the whole tree from a warm registry cache in the
time recorded under `## Empirical check` — and this item adds two handler
functions, three structs and one `AtomicBool` to it. **No latency, throughput,
memory or binary-size figure is claimed anywhere in this decision; none was
measured.**

**Excluded, and on which ground.** `shadow-rs` 2.0.0 and `git-version` 0.3.9 are
excluded **by gate 2**, above. `built` 0.8.1 and `vergen` 10.0.3 are excluded
**on fit, which is not a fitness gate and is labelled as such**, because both
require a Cargo build script and R49's owner-accepted `build-tool-output-shape`
states *"no build.rs and no build-orchestration crate"* (check `O6`, quoted from
the live registry row). The requirement is read from the maintainers' own
documentation rather than inferred: `built`'s README shows its usage under the
comment `// In build.rs`, `vergen`'s says its tools are configured in cargo build
scripts, and `shadow-rs`'s instructs creating a `build.rs` (check `L6`). **No
`CONFLICT:` line is raised for this**: the recommendation does not need R49's
value changed — it needs none of these crates. `rocket_healthz` 0.5.0 and every
other name-matched candidate are excluded on adoption (check `L8`). The gRPC
Health Checking Protocol as shipped by `tonic-health` is excluded on fit: it is
the one real standard in this space, and it is for gRPC servers, which this
template is not.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is owed.**

| Level | What must agree across py, ts and rs | Source |
|---|---|---|
| **Architectural pattern** | the readiness endpoint and the CLI's `doctor` command run **the same function**, in one place, with no second copy of the check list | F329's ledger Note, *"one source of truth with the CLI"*; py at pin `b08bccfb` imports `run_diagnostics` from `core/diagnostics.py` into **both** `web/app.py` and `cli/main.py` (check `O21`) |
| **Capability** | a liveness endpoint exists that reports the build's identity and is answerable without reaching any dependency | F328; py `web/app.py:153` (check `O20`) |
| **Capability** | a readiness endpoint exists that fails with a non-2xx status a probe reads, carrying the diagnostic detail in the body | F329; py `web/app.py:184-198` (check `O20`) |
| **Policy** (verbatim paths) | the two endpoints are unversioned: `/healthz`, `/readyz` | F308, `ADOPT`; applied, not re-derived |
| **Nothing — free to vary** | the payload's field list; which non-2xx status means "not ready"; whether readiness is computed per request or latched; the transport plumbing | Kubernetes reads only the status code; the surveyed production systems disagree on every one of these |

`ts` has neither front end at pin `cb1cbcb2`: a case-insensitive search for
`healthz|readyz` across `src/` matches **0** files (check `O23`), which is F303 as
recorded. Nothing cross-repo is owed to ts by this item; changes to py remain a
follow-on project, and this decision supplies their rationale rather than making
them.

**What Kubernetes requires, re-verified at source on 2026-09-18 (check `L5`),
because the whole contract hangs on it.** From
`https://kubernetes.io/docs/concepts/workloads/pods/probes/`: *"Liveness probes
determine when to restart a container"*; *"Readiness probes determine when a
container is ready to accept traffic"*, and a readiness failure makes the
EndpointSlice controller remove the Pod's IP address. From
`https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/`:
*"Any code greater than or equal to 200 and less than 400 indicates success. Any
other code indicates failure."*

Three consequences fix the design and are not matters of taste. **(a)** Liveness
failure is a *restart*, so `/healthz` must never be able to fail for a reason a
restart cannot fix — it reaches no dependency, no lock and no pool. **(b)**
Readiness failure is *traffic removal*, so `/readyz` is the correct and only place
for anything conditional. **(c)** The probe reads the **status code**; the body is
for humans and for a command-line client. Apollo Router's own source records
learning (c) the hard way — *"It's hard to get k8s to parse payloads. Especially
since we can't install curl or jq into our docker images because of CVEs. So,
compromise, k8s will interpret this as probe fail."* (check `L7`).

**Observable acceptance criteria.** Criteria marked **executed** were run here
against a throwaway workspace resolving the exact versions R69 revision 10 and
R66 select; the check identifiers are reproduced under `## Empirical check`. The
rest are P03's.

| # | Behavior | Observable criterion | State |
|---|---|---|---|
| AC1 | Liveness answers 200 and names the build | `GET /healthz` → `200`, body exactly `{"status","version","os","arch"}` | **executed** (`T1`) |
| AC2 | The liveness body is byte-stable for the process's life | two successive `GET /healthz` bodies are byte-identical | **executed** (`T2`) |
| AC3 | Liveness reaches no dependency | the `/healthz` handler's signature names no `State`, no pool and no port | **executed by construction** (`T1`, `T5`); enforceable in P03 by a one-line review of `routes/ops.rs` |
| AC4 | Warn-level findings do not remove traffic | a missing config file and a missing credential leave `GET /readyz` at `200` | **executed** (`T3`) |
| AC5 | An error-level finding removes traffic | a hand-built report containing one `error` check yields `503` | **executed** (`T6`) |
| AC6 | Readiness reports not-ready as soon as the drain begins | after `Readiness::begin_draining()`, `GET /readyz` → `503` | **executed** (`T4`) |
| AC7 | Draining is not a restart signal | after `begin_draining()`, `GET /healthz` is still `200` | **executed** (`T5`) |
| AC8 | Method handling is correct for a probe | `POST /healthz` → `405` with `Allow: GET,HEAD`; `HEAD /healthz` → `200` | **executed** (`T7`, `T8`) |
| AC9 | The CLI and the web service share one function | `crates/cli` and `crates/web` both call `rs_launch_blueprint_core::diagnostics::run_diagnostics`, and a search for the check-name literals finds them in exactly one file | **P03** |
| AC10 | The probe surface disappears with the feature | a default `cargo build` produces no probe route and no `axum` in the dependency graph | **executed** (`C9`, with `C10` as its converse) |
| AC11 | `/readyz` answers 503 for the whole drain window and the process exits 143 | a process test: send `SIGTERM`, assert `GET /readyz` → `503` while an in-flight request completes, then assert exit `143` | **P03** — needs a running binary; see the honesty note on the drain race below |

**Architectural alternatives, compared before any library was considered.**

| # | Alternative | Mechanism | Disposition |
|---|---|---|---|
| **A** | Re-run the diagnostics on every readiness probe — py's literal shape | `/readyz` calls `run_diagnostics(config)` per request, 503 if any check errors | **Adopted for the diagnostic half.** It is the only shape that satisfies the shared pattern, and the check set is local and cheap. Its weakness is that it says nothing about process lifecycle |
| **B** | Latch process state in an `AtomicBool` — kubert's and Apollo Router's shape | `/readyz` reads `Arc<AtomicBool>`; startup sets it true, shutdown sets it false | **Adopted for the lifecycle half.** Both surveyed production systems chose it independently (check `L7`). It is the only shape that can report *draining*, the state Kubernetes most needs to see |
| **C** | **A + B: the latch OR'd with the shared diagnostics** | `/readyz` → 503 if draining, else run diagnostics, 503 if any check errors, else 200 | **Selected.** The two arguments below |
| **D** | Move the probes to a second listener on a second port — Apollo Router's and kubert's *deployment* shape | a separate `axum::serve` on an admin address | **Rejected for this template; recorded as the scale-out path.** It buys isolation of ops traffic from request-path middleware and lets probes outlive the main server during drain; it costs a second bound port, a second `serve_until`, a second variable in R77's settings and a second row in R51's container contract. py binds one port, this template ships no deployment, and R75 already owns excluding the probes from access logs (F320) — the concrete benefit D would otherwise buy |
| **E** | Adopt a probe crate | `rocket_healthz`, or a hand-rolled `tower` layer | **Rejected on the census** (check `L8`). No crate exists at adoption worth depending on, and the surface is two handlers |
| **F** | Speak the gRPC Health Checking Protocol (`tonic-health`) | a gRPC `Health` service | **Rejected on fit, recorded because it is the one real standard here.** This template serves HTTP/1.1 JSON and has no gRPC surface; adopting it would add `tonic` for nothing |

**The first reason alternative C, not A, is the recommendation — and the honest
limit of that reason.** R69 revision 10 puts `shutdown_signal()` and
`serve_until(..)` in `crates/web/src/lib.rs`, and `serve_until` starts the grace
clock at the signal. Kubernetes removes a Pod from its EndpointSlices only once a
readiness probe has *failed*, which takes at least one probe period. **Flipping
the latch is necessary but, on its own, not sufficient.** Once `shutdown_signal()`
resolves, `axum::serve` stops accepting, so a kubelet opening a *fresh* connection
to `/readyz` gets a connection refusal — already a probe failure — and never reads
the latch at all. A flip immediately followed by resolution therefore changes
nothing observable on a fresh-connection probe; what it changes is the answer
given on a connection that is already open. **What actually closes the race is a
nonzero pre-drain pause inside `shutdown_signal()`**: flip the latch, keep the
listener open for a readiness-propagation window during which `/readyz` answers
503 and the EndpointSlice controller removes the Pod, *then* resolve and let the
drain begin. The latch is what makes that pause do anything; the pause is what
makes the latch observable to a fresh-connection probe. **The mechanism is inert
if that window is zero, and no item owns its value today** — see the correction
under `## Engines`: `raw/opus.md` says R77 owns it, and R77's own in-flight report
owns a drain *deadline* (`RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`, recommended 8 s)
and names no propagation pause on any line (check `O15`). This decision therefore
**hands R77 a requirement rather than citing a fact**: whatever window R77 or a
later item chooses must hold both the readiness-propagation delay and the drain
inside the platform's kill budget, of which the Cloud Run 10-second SIGTERM window
R69 records is the recorded instance. That datum is **carried from R69, not
re-verified here.**

**The second reason: in the ported design the latch is the only thing that makes
the 503 branch reachable from a real environment — and `raw/opus.md` overstates
this, so the corrected form is recorded here.** py's four checks are `python`,
`platform`, `config-file` and `token`; exactly one of them, `python`, can be
`error`, and only when the interpreter is older than `MIN_PYTHON = (3, 12)`, which
the package's own floor already forbids (check `O27`). py's passing-path test says
so in a comment: *"# Missing token/config are warnings, not errors, so readiness
holds."* **`raw/opus.md` then claims "there is no test in that file for the 503
branch". That is wrong.** `tests/web/test_app.py:248-262` is
`test_readyz_failure_is_a_problem_with_diagnostics`, and it does assert `503` — but
it reaches that branch only by `monkeypatch.setattr(app_module, "run_diagnostics",
lambda _config: failing)`, substituting the function with a hand-built failing
report (check `O22`). The substitution is itself the evidence: the branch is
reachable in a test and unreachable from any real environment. Rust has no
runtime-toolchain check to port at all, so a literal port of alternative A would
ship a readiness endpoint whose diagnostic half can never return 503. The latch
gives the endpoint one state it can genuinely report, and the check list stays open
for whatever later items add. **Which checks can reach `CheckStatus::Error` in Rust
is not decided here, and no accepted decision defines one**: R55
(`config-error-tolerance`, accepted at revision 3, unpublished) and R57
(`xdg-directory-set`, accepted at revision 2, unpublished) are the two items whose
subject matter could produce one, and neither's accepted decision defines a
diagnostics check at all. The check list is unowned; this decision names that gap
rather than filling it.

**Where the shared function lives, and why the placement is forced rather than
chosen.** `run_diagnostics` goes in **`crates/core`**, the member R02 revision 2
(owner-accepted, unpublished) defines as models, ports, services, the error
catalogue and the shipped `InMemoryProjectsPort`, with no CLI or web framework
(check `O18`). Both front ends depend on core and on nothing else, so core is the
*only* place a function can sit and be reachable from both; anywhere else would
either duplicate it or create the front-end-to-front-end edge Cargo refuses as a
cycle. This is the Rust analogue of py's `core/diagnostics.py`, and it is stronger
than py's: in py the placement is a convention an `import-linter` contract polices,
whereas here Cargo's own resolver refuses the alternative. Check `C11` demonstrates
the consequence — the member holding the function names no web crate.

**The signature, and the three accepted decisions it satisfies simultaneously.**

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

/// Synchronous (R05 revision 3), infallible (R03 revision 1), framework-free (R02 revision 2).
pub fn run_diagnostics(config: &Config) -> Diagnostics;
```

- **R05 revision 3** (synchronous core) makes this an ordinary `fn`, not `async
  fn`, and makes the web side reach it through `tokio::task::spawn_blocking`
  (check `O19`). The CLI calls it directly.
- **R03 revision 1** (`absent is a value, broken is an error`) is why the return
  type is `Diagnostics` and **not** `Result<Diagnostics, _>`. A failing check is a
  fact about the environment that the report exists to carry, not a failure of the
  function that collected it. A `Result` would force both callers into an
  identical `match` — the CLI to print something, the handler to pick a status code
  — re-creating the duplication the pattern exists to remove. py chose the same:
  `run_diagnostics` has no failure mode and returns `DoctorReport`.
- **R02 revision 2** forbids a web or CLI type in core, so core derives
  **`serde::Serialize` and nothing else**. No `IntoResponse`, no `utoipa::ToSchema`
  and no `clap` attribute ever goes on `Diagnostics`; the hand-off to R71 is below.

**Ranked runner-up for the shared contract:** `Result<Diagnostics,
DiagnosticsError>`. It is qualified, not absurd — a check that must read a file
could fail in a way that is not itself a finding — and it is the shape to move to
if P03 finds one. The migration is mechanical: the CLI adds one `?` and the
handler adds one `match` arm mapping the error to 503.

**The initial check set** ports py's minus the one with no Rust analogue: `build`
(version, OS, arch — informational, always `ok`), `config-file` (`ok`/`warn`) and
`credential` (`ok`/`warn`). `name` is `&'static str` because every check name is a
literal; `detail` is `String` because it interpolates paths and values. The
executed probe ran exactly this set (`T3`).

**The liveness payload: the one place where a faithful port is the wrong answer.**
py reports `python: platform.python_version()` — the version of the interpreter
*at this moment executing the process*. Rust has no such fact at runtime: the
binary is statically compiled, there is no toolchain in the container to report,
and the nearest equivalent (the `rustc` that produced the binary) is obtainable
only through a Cargo build script or a compile-time proc macro — the mechanisms
R49 excludes and gate 2 excludes respectively. The **principle** py's field serves
is *"the liveness payload identifies which build is answering"*, which is what its
docstring says (*"Liveness + build info (the web analog of ``--version``)"*). Rust
preserves that principle with facts it already carries for free:

```rust
#[derive(Serialize)] pub struct LivenessReport {
    pub status:  LiveStatus,     // "ok"
    pub version: &'static str,   // the crate version, via R22's accessor defined once in core
    pub os:      &'static str,   // std::env::consts::OS
    pub arch:    &'static str,   // std::env::consts::ARCH
}
```

This is a **justified ecosystem difference, not drift**: the capability ("identify
the build") agrees, and the field that realizes it differs because the underlying
fact differs. On a multi-architecture image the `arch` field also tells an operator
which image the orchestrator actually pulled, which py's field cannot. Check `T1`
served exactly `{"status":"ok","version":"0.4.2","os":"macos","arch":"aarch64"}`
from a workspace containing **no** `build.rs`, and `T2` shows the body is
byte-stable across calls.

**A workspace hazard this decision must state, because it silently breaks the
field just specified.** `env!("CARGO_PKG_VERSION")` expands to the version of *the
package being compiled*. Under R02's four-package workspace, evaluating it inside
`crates/web` yields the web member's version, not the distributed artifact's.
Executed as check `A`: with the facade at `0.4.2` and the web member at `0.1.0`,
the macro read inside the web member reports **`0.1.0`** — the endpoint would
report the wrong version, correctly, forever. Check `B` shows the repair:
`[workspace.package] version` plus `version.workspace = true` on every member
makes all three packages report `0.4.2`. **The accessor's mechanism is R22's**
(`runtime-version-accessor`, open; `research/runs/R22/2026-09-17T020715Z-d93731e7353c/review/`
holds no `DECISION.md`). What this item fixes is narrower and is a genuine
constraint on R22's answer: **`/healthz` reports the version of the distributed
artifact, and the accessor is evaluated in `crates/core` — or in a package that
inherits `[workspace.package] version` — never at the web member's own call site.**
R22's own MEDIUM question asks for exactly that, so this is a hand-off with a
stated requirement, not a conflict.

**Uptime: asked by the prompt, and declined, with the cost stated.** It is cheap —
one `Instant` at startup and one monotonic subtraction — and it is not
recommended, for three reasons. (1) A body that changes on every request destroys
AC2, and R33 (`property-and-snapshot-testing`, published) selects snapshot
testing, so a monotonically-increasing field forces every such test to redact a
field before comparing. (2) Neither surveyed production system emits it: kubert's
`/live` body is the five bytes `"alive\n"` and Apollo's is `{"status":"UP"}`
(check `L7`). (3) Kubernetes never reads the body. The operational question uptime
answers — "did this process restart?" — is better answered by the container
runtime's own restart count. **Recorded as the alternative so the owner can
overturn it cheaply**: if wanted, it is one `pub started: Instant` field on
`AppState`, one line in the handler, and AC2 is deleted.

**Structured types versus a minimal body (the prompt's MEDIUM question):
structured, `serde`-derived types.** Three pieces of evidence in ascending order
of force. `apollographql/router` derives `Serialize` on its `Health` struct rather
than writing a literal (check `L7`). `rust-lang/crates.io` derives both
`Serialize` and `utoipa::ToSchema` on the analogous build-identity response
(carried from `raw/opus.md`, not re-read here). And py records the concrete cost of
not doing it, in a comment at the `/readyz` decorator: *"response_model declares
the 200 shape in OpenAPI (contract safety, WEB-50): without it the snapshot
publishes an empty `{}` schema."* Since R71 will publish a spec that R83 fuzzes, an
untyped ops body is a hole in that spec. The **ranked runner-up** is the
hand-written literal — kubert's `"alive\n"` with a `text/plain` content type — a
defensible choice for a body only a kubelet reads, rejected here because a spec is
published over these routes. **The hand-off to R71, stated precisely because it
collides with R02:** if R71 selects `utoipa`, its `ToSchema` derive must **not** be
placed on `crates/core`'s `Diagnostics`; R71's options are a `crates/web` DTO built
by `From<Diagnostics>`, or a hand-written schema fragment. This item states the
constraint and decides nothing for R71.

**Does the readiness check dial the upstream API? No, by default — and the
extension point is specified rather than left implicit.** py's `run_diagnostics`
never contacts the upstream service: all four of its checks are local (check
`O27`). Kubernetes explicitly permits the other choice — *"the readiness probe
additionally checks that each required back-end service is available"* — when the
app has a strict dependency on back-end services, but pairs it with the
cascading-failure caution, and a correlated upstream blip would then remove **every**
replica from service simultaneously. So: **local checks only by default; an
upstream check is an opt-in.** When a template user wants one, its shape is fixed
by R01's published `http-transport-injection-seam`: the check calls the erased
service held in `AppState` — core's port — **never a concrete adapter**, inside the
same `spawn_blocking` hop, with a timeout strictly shorter than the probe's
`timeoutSeconds` and a short result cache so that N probes per second do not become
N upstream calls per second. Adding it changes no signature in this design: it is
one more `Check` pushed onto the report.

**The bridge, and the latch, in tokio's terms.** `/readyz` reaches the synchronous
core through `tokio::task::spawn_blocking`, which is R05 revision 3's own
mechanism. The honest counter-argument is recorded: today's check set is a single
`stat`, far below the threshold at which blocking matters, so a direct call would
work. It is not recommended, for consistency with R05's rule (so no reader has to
relitigate which core calls are "small enough") and for extensibility (the opt-in
upstream check above, and whatever checks later items add, are exactly the ones
that would stall the reactor). `tokio::task::block_in_place` is the third
candidate and is rejected on a concrete cost, not a stylistic one: it panics on a
current-thread runtime, which is what `#[tokio::test]` uses by default, so it would
make the probe untestable in the idiom R69 selected. The **latch** is `std`, not
tokio: `Arc<AtomicBool>` with `Ordering::Release` on the store and `Ordering::Acquire`
on the load. `tokio::sync::watch` would also serve and is the runner-up, to be
taken if anything ever needs to *await* the transition rather than read it; nothing
does. `spawn_blocking`'s `JoinHandle` can report a panic in the closure, and the
handler maps a `JoinError` to **503**, since a probe that panics is by definition
not ready — the executed probe used `.expect(..)`, which is **not** the recommended
production shape and is marked as such in the committed probe source.

**Agreement and difference with the owner-supplied reference architecture**
(`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, the standing input
`docs/planning/p02/owner-decisions.md` section 11 places in this item's overlap set
at row C15). Row by row, for every row that touches this item:

| Reference row | What it says | This item |
|---|---|---|
| **C15**, *Container & Cloud Run* | "expose `/healthz` (liveness) and `/readyz` (readiness, checks DB)" (check `O24`) | **Agree on the two paths and their roles.** **Differ on "checks DB", on sourced ground**: this template has no database, its single driven dependency is an upstream HTTP API behind R01's port, and the Kubernetes cascading-failure caution plus py's local-only check set make an unconditional dependency dial the wrong default. The capability is preserved as the specified opt-in above |
| **C15**, *distroless/cc-debian12*, run as `nonroot`, bind `PORT` | the image shape | **Not this item's** — R51 owns it. One consequence is stated below, not fixed |
| **C4**, *Error contract* | "One `AppError` enum (`thiserror`) implementing `IntoResponse` … RFC 9457 Problem Details JSON" | **Agree that `/readyz`'s 503 reuses the single envelope**, which is what py does. The envelope itself is R70's and is still in flight; the standing constraint this item places on it is below |
| **C10**, *Observability* | JSON logs, trace correlation | **No position** — R58/R75/R78/R79. The only interaction is F320, which is R75's |
| **C13**, *Project structure* | "feature-vertical modules" | **Agree**, as realized by R69 revision 10: the probe handlers are one module, `crates/web/src/routes/ops.rs` |
| **Reference `Cargo.toml`** | `edition = "2021"`, `rust-version = "1.85"` (check `O24`) | **Differ — owner-fixed parameters override**, per section 11's own rule: `rust-edition` = 2024 and `msrv-policy` as registered. The executed probe workspace uses edition 2024 throughout |

Tally over the six rows: **3 agree, 2 differ** — one difference on sourced ground,
one on an owner-fixed parameter, both grounds section 11 requires — plus 2 rows
recorded as belonging to other items. Two of the six are the same C15 row read for
its two halves.

### What this decision does not decide

Each of these is a coupling stated at the strength the evidence supports. None is
a `CONFLICT:` line: a `CONFLICT:` records a consumed *parameter value* that must
change, and none must.

**R70 (`http-problem-envelope`) — a standing constraint, and the one place a
reader should expect friction.** This design needs the diagnostic report carried
in the 503 body, which is what py does: `problem_response(..., status_code=503,
extensions={"diagnostics": report.model_dump(mode="json")})`, with the 503
declared in py's own OpenAPI responses as *"RFC 9457 problem document with a
`diagnostics` extension"* (check `O20`). **R70's in-flight raw report chooses an
envelope that "adds one extension member and no more"** — `code` — plus an optional
`errors` map, and in the same report hands `/readyz`'s failure body to R80 (check
`O12`). Those two sentences are in tension, and R70 is being researched in
parallel, so this item **states the requirement and decides nothing**: the
diagnostic report must be reachable from the 503 response. Three ways satisfy it —
a second extension member named `diagnostics`; the report folded into the existing
`errors` map; or a `detail` string that names the failing checks with the full
report left to the logs. R70 owns the choice. **Until R70 publishes, the executed
probe's 503 body is a plain JSON stand-in, and this decision claims nothing about
the envelope's member names.**

**R51 (`container-image`) — what `/healthz` returns, for it to probe.** Two facts
are established here rather than guessed. First, `/healthz` answers `200` with a
JSON body, on `GET` and on `HEAD`, with no state and no dependency, for the life of
the process. Second, the *probe client* problem: py solves it with the interpreter
it already ships (`Dockerfile:27-30`, commented *"urllib — the slim base image has
no curl"*), and a Rust distroless image has neither a shell nor an interpreter nor
`curl`. R51's in-flight raw report answers it with a static `busybox` applet stage
and an exec-form `HEALTHCHECK` against `/healthz` (check `O13`). **This item does
not choose among R51's options**; it records that `/healthz` is `HEAD`-safe, which
is what makes the cheapest probe clients viable.

**R79 (`prometheus-metrics`) — a third unversioned ops route is coming.** R79's
in-flight raw report names a three-path exclusion set, `/metrics`, `/healthz` and
`/readyz` (check `O14`). Whether `/metrics` is registered in the same
`routes/ops.rs` module or its own is R79's; F308's unversioned convention applies
to it identically.

**R77 (`web-env-settings`) — the readiness-propagation pause.** Stated above: R77's
in-flight report owns a drain deadline and names no pause (check `O15`). This item
hands R77 the requirement; if R77 declines it, the pause needs an owner.

**R75 (`http-middleware-stack`) — what can fail in front of `/healthz`.** The probe
handlers sit behind whatever middleware stack R75 builds, so a bug in an outer
layer can make `/healthz` fail and trigger a container restart for a reason
unrelated to liveness. Both surveyed production systems avoid this with
alternative D's separate listener. The mitigation available without D is R75's:
order the layers so the probes' path is reached before anything that can reject,
and keep a catch-panic layer outside them. Recorded as an input to R75, not a
decision for it.

**The CLI `doctor` subcommand — presupposed by F329 and owned by no item, and it is
not R60's to carry.** R60 (`cli-parsing-framework`, published) put three options
for the extended `--version` data to the owner, of which **(c)** was "extended data
moved to a `doctor` verb"; **the owner's ruling was (b)**, the `--version -o json`
path, and R60's decision records that ruling verbatim (check `O8`). R60 would fall
back to (c) only if R66 refused a root format flag, which R66 did not. So no
published or accepted item specifies `doctor`'s flag surface or its exit code, and
`docs/port/COMMONALITY.md`'s only "doctor" rows (F185, F186) are contributor-facing
recipes, not the product subcommand. R67's accepted `error-taxonomy-exit-codes`
catalog is append-only and contains **no** diagnostics row; the nearest existing
rows are `RSLB104` (config layer unreadable → 1) and `RSLB203` (config value
invalid → 2) (check `O16`). **This item assigns no exit code.** It records that
whoever specifies `doctor` must reuse one of those or add a row through R67's
append-only process, and that today — with no check able to reach `error` —
`doctor` would exit `0` on every machine.

re-verify: when R69 republishes web-extra-surface at revision 10, which fixes every file path in this decision's migration table and is the single most likely trigger; when R70 publishes the problem envelope, which decides how the 503 body carries the diagnostic report; when R71 publishes and requires a schema derive, which must meet the no-OpenAPI-derive-in-crates/core constraint; when R22 publishes the version accessor, which must be core-defined and workspace-safe as check A demonstrates; when R55, R57 or any later item publishes a diagnostics check that can reach CheckStatus::Error; when R77 publishes a readiness-propagation pause or moves the drain deadline; when R51 publishes the container probe client; when R75 publishes the middleware order; when R79 publishes /metrics as a third unversioned ops route; when R05 is reopened to an async core, which deletes the spawn_blocking hop; when GET https://crates.io/api/v1/crates/axum/versions stops giving 0.8.9 as the newest non-yanked version in a release that changes MethodRouter's 405/Allow behaviour or Json's IntoResponse; when https://rustsec.org/packages/axum.html, .../serde.html or .../tokio.html changes status while the atty control holds at 200; when GET https://crates.io/api/v1/crates/shadow-rs/versions or .../git-version/versions begins returning a non-null rust_version, which reverses a gate-2 exclusion; when the Kubernetes probe documentation changes the quoted sentences; or by 2027-03-18, whichever comes first

## Parameters

**Owned parameters: none.** `research/CLAUDE.md`'s R80 row carries `—` in the
`owns` column and the binding prompt's `- owns:` coupling line is empty, so this
decision adds no registry parameter and carries no `- owns` line (check `O4`). The
contract it fixes — the two paths, their status codes, their payloads and the
shared function — is recorded in this decision's text, not in the shared-parameter
registry.

**Consumed parameters.** The prompt's `- consumes:` line is also empty, so none of
the following is a registered dependency; each is nonetheless load-bearing and is
declared rather than left implicit. Every value below is **byte-identical to its
row in `docs/port/PARAMETERS.md`** as read on 2026-09-18, asserted mechanically by
check `O3`, which parses the registry table and compares each value character for
character.

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**`CONFLICT:` lines: none.** No consumed value needs to change for this
recommendation. The two places a reader might expect one, and why neither is: R49's
`build-tool-output-shape` no-`build.rs` clause **excludes** `built`, `vergen` and
`shadow-rs`, and this decision declines all three rather than asking for the clause
to move; and R69's `web-extra-surface` differs between the registry and the
accepted revision, which is a publication lag, not a needed change.

**Prose note beside the `web-extra-surface` line, required because the registry and
the accepted revision disagree about paths.** The line above carries the registry's
current bytes, which are **revision 9's**: it names the library module `src/web/`,
gates the web tests file-level with `#![cfg(feature = "web")]`, and declares
`web = ["dep:axum", "dep:tokio"]` with both crates optional on one manifest.
**R69 revision 10 is owner-accepted and unpublished**
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, its
`- owns web-extra-surface` line at **line 1791**, verified by check `O5` together
with the registry's surviving `src/web/` form): it moves the tree to the optional
workspace member `crates/web/`, declares `web = ["dep:rs-launch-blueprint-web"]` on
the root package, declares `axum` and `tokio` **non-optionally** in
`crates/web/Cargo.toml`, and puts the web tests in `crates/web/tests/` with **no**
file-level `cfg` because the whole member is optional. **This decision's design
uses revision 10's paths** — `crates/web/src/routes/ops.rs`,
`crates/web/src/lib.rs`, `crates/core/src/diagnostics.rs` — and the executed probe
workspace is built in that shape. **This is not a `CONFLICT:`**: the recommendation
needs nothing in R69's value changed, only the accepted revision's paths, which R69
will publish itself. **R69's republication is a re-verify trigger** for every file
path in the migration table below.

**Two further published values bind the recommendation without being consumed as
values**, so they are named here rather than given an `assumes` line. **R67's
`error-taxonomy-exit-codes`**: the serve binary's drain exits (143 / 130 / 1 / 0)
are R69's application of it and are untouched here; the CLI `doctor` command's exit
code is **not assigned by this decision** and is recorded above as an open scoping
question against R67's append-only catalog. **R01's
`http-transport-injection-seam`** carries an `assumes` line above because the
specified opt-in upstream readiness check calls the erased service — core's port —
and never a concrete adapter; with that check off by default, nothing in the
shipped design dials it.

**Migration implications, file by file**, written against R02 revision 2's
four-package workspace and R69 revision 10's accepted paths.

| File | Change |
|---|---|
| `crates/core/src/diagnostics.rs` (new) | `CheckStatus`, `Check`, `Diagnostics`, `Diagnostics::has_error`, `run_diagnostics(&Config) -> Diagnostics`. `#[derive(Serialize)]` only — no framework or OpenAPI derive ever enters this member |
| `crates/core/src/lib.rs` | one `pub mod diagnostics;`. Whether it is re-exported from the facade's barrel is R04's rule to apply, not this item's to decide |
| `crates/core/Cargo.toml` | **no change** — `serde` with `derive` is already present for R66's result contract |
| `crates/web/src/routes/ops.rs` | filled in: `LiveStatus`, `LivenessReport`, `async fn healthz()` (no `State`), `pub fn readiness_response(draining: bool, report: Diagnostics) -> Response`, `async fn readyz(State(..))`, and a `router()` registering `/healthz` and `/readyz`. R69's file map already reserves this file with the note "`/healthz` now; `/readyz` and its payload are R80's" |
| `crates/web/src/lib.rs` | a `Readiness(Arc<AtomicBool>)` newtype with `accepting()`, `is_accepting()`, `begin_draining()`; one `readiness: Readiness` field on `AppState`; one `readiness.begin_draining()` call inside `shutdown_signal()`, **before** that future resolves. `build_router`'s `.merge(ops::router())` line is already in R69's recorded snippet |
| `crates/web/tests/web_api.rs` | the eight probe tests `T1`–`T8`, adapted to the template's types |
| `crates/web/Cargo.toml` | **gains `serde = { version = "1.0.229", features = ["derive"] }`**, and `serde_json` only if R70's envelope is constructed in this member directly. R69 revision 10's manifest row for that member lists only `axum`, `tokio` and the `tower` dev-dependency, because R66 places `serde` in the *library* crate, which under R02's topology is `crates/core`. The executed probe workspace had to add exactly these rows to compile the `#[derive(Serialize)]` on `LivenessReport`; a manifest written from "no change" would not build |
| `Cargo.toml` (root) | **no change from this item.** If R22 selects workspace version inheritance — which check `A` shows is required for `/healthz` to report the artifact's version — the `[workspace.package] version` key and each member's `version.workspace = true` are R22's and R02's edit |

**Not created by this item**, named so a later reader does not look for them here:
the problem envelope `/readyz`'s 503 reuses (R70); the OpenAPI annotations on these
routes and any DTO they need (R71, subject to the no-derive-in-core constraint);
the access-log exclusion for both paths (R75, F320); the settings module and any
readiness-propagation pause (R77); the `Dockerfile` and its `HEALTHCHECK` (R51,
F337); the `/metrics` route (R79); the CLI `doctor` subcommand's flag surface and
exit code (unowned); and any check capable of reaching `CheckStatus::Error`.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4 (`Darwin 25.4.0`)
on `arm64`, `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` at `/usr/bin/grep`,
`Python 3.13.9`, `curl 8.7.1`, `jq-1.8.2`, `shellcheck` on `PATH`. Working
directory for every command: the repository root,
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. **No template code exists in
this repository and none was written**: the recommendation is verified, never
implemented.

**Three scripts, 49 checks.** Each asserts on content, not on an exit code; each
carries `set -euo pipefail`; each counts PASS/FAIL/SKIP and exits non-zero on any
FAIL. A check that could not fail is not counted as evidence.

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R80/2026-09-17T034011Z-74765d801b92/review/evidence
bash check-offline.sh   # 27 checks O1..O27  -> check-offline.log
bash check-probe.sh     # 13 checks A,B,T1..T8,C9..C11 -> check-probe.log
bash check-live.sh      #  9 checks L1..L9   -> check-live.log
shellcheck check-offline.sh check-probe.sh check-live.sh   # -> shellcheck.log, exit 0
```

**`check-offline.sh` — 27 checks, all offline.** It re-verifies at source the
claims of `raw/opus.md` that need no network: the registered report's digest
(`O1`); its bundle answer shape through
`validate_answer_text(text, "bundle")` from `scripts/research_validation.py`,
including the `### Members` window rule that keeps every H5 field inside a named
member (`O2`, **0 errors**); the byte-identity of all seven `- assumes` values in
this decision against the live registry, compared character for character by a
table parser rather than by eye (`O3`); the absence of any `- owns` line (`O4`);
R69 revision 10's owned value at line 1791 *and* the registry's surviving
revision-9 `src/web/` form, which is what earns the publication-lag note (`O5`);
R49's no-`build.rs` clause (`O6`); the F308/F328/F329 ledger rows (`O7`); R60's
recorded ruling (b) (`O8`); the acceptance rows for R55, R57, R02, R05, R03 and
R56 (`O9`); the W1-CODEX3 ruling (`O10`); the owner's licence ruling (`O11`); the
in-flight coupling facts in R70's, R51's, R79's and R77's raw reports
(`O12`–`O15`); R67's catalog rows and the absence of a diagnostics row (`O16`);
the accepted revision numbers of R02, R05 and R03 (`O17`); R02's `crates/core`
(`O18`); R05's `spawn_blocking` (`O19`); py's `/healthz`, `readyz` and 503 at the
pin (`O20`); py's one-function-two-callers pattern (`O21`); **both** of py's
readyz tests including the monkeypatched 503 (`O22`); py's four checks with
exactly one error-capable status (`O27`); ts's zero matches (`O23`); the owner
reference's C15 sentence and its edition 2021 line (`O24`); and this decision's
own shape — exactly one `re-verify:` line, no `## Supersedes`, exactly four H2
sections (`O25`) — and its gate-1 wording (`O26`).

Result in place: **27 PASS, 0 FAIL, 0 SKIP**, exit 0, saved as
`review/evidence/check-offline.log`.

**`check-probe.sh` — 13 checks against a throwaway axum workspace.** The workspace
is created by `mktemp -d` under `$TMPDIR` from the committed sources in
`review/evidence/probe/`, built, exercised, and **deleted on exit by a trap**; no
`target/` tree and no nested git repository is ever committed. It resolves
**axum 0.8.9 · tokio 1.53.1 · serde 1.0.229 · serde_json 1.0.151 · tower 0.5.3**
(dev-dependency, for the `ServiceExt::oneshot` idiom R69 selects), edition **2024**
throughout, `rust-version = "1.96"` on every manifest, and builds `--offline` from
the warm registry cache. It **measures**; it does not assert a latency or a
throughput, and it does not build the template.

| Check | What it asserts | Observed |
|---|---|---|
| `A` | `env!("CARGO_PKG_VERSION")` inside a member reports the **member's** version, and `std::env::consts::{OS, ARCH}` resolve as `&'static str` with no `build.rs` anywhere in the tree | `facade_env_CARGO_PKG_VERSION=0.4.2`, `web_member_env_CARGO_PKG_VERSION=0.1.0`, `std_env_consts_OS=macos`, `std_env_consts_ARCH=aarch64`, `os_and_arch_are_static_str=true` |
| `B` | `[workspace.package] version` + `version.workspace = true` repairs it | all three packages report `0.4.2` |
| `T1` | `GET /healthz` → 200 with exactly four fields | `{"status":"ok","version":"0.4.2","os":"macos","arch":"aarch64"}` |
| `T2` | the liveness body is byte-stable across calls | `byte-stable=true` |
| `T3` | warn-only checks keep readiness | `200`; checks `build`/`config-file`/`credential` with statuses `ok`/`warn`/`warn` |
| `T4` | the drain latch removes traffic | `503 Service Unavailable`, body still carrying the report under `diagnostics` |
| `T5` | draining is not a restart signal | `GET /healthz` still `200` |
| `T6` | a hand-built error report yields 503 **without touching the environment** | `503` from the pure `readiness_response(false, report)` |
| `T7` | probe method handling | `POST /healthz status=405 Method Not Allowed allow=Some("GET,HEAD")` |
| `T8` | `HEAD` is served by the `GET` handler | `200`, `body_len=0` |
| `C9` | a default build has no probe surface | `axum` occurs on **0** lines of `cargo tree -p facade --edges normal` |
| `C10` | `--features web` brings it back | the optional member and `axum v0.8.9` reappear |
| `C11` | the member holding the shared function names no web crate | `probe-core` → `serde v1.0.229` → `serde_core` + `serde_derive`; `axum|tokio|hyper|tower` matched on **0** lines |

Result in place: **13 PASS, 0 FAIL, 0 SKIP**, exit 0, saved as
`review/evidence/check-probe.log`. `T6` is the check that matters most: because it
drives the pure `readiness_response` function rather than the handler, the 503
branch is provable on any machine in any environment — which is exactly the
property py has to reach with a monkeypatch.

**`check-live.sh` — 9 checks against the live sources.** `L1` the eight crates'
`max_stable_version` against the pins this decision names; `L2` the declared-MSRV
facts that decide gate 2 (`shadow-rs` and `git-version` still `rust_version: null`;
`built` 1.87; `vergen` 1.96.0); `L3` the RustSec picture with `atty` as a 200
control; `L4` `RUSTSEC-2025-0023`'s open-ended `>=1.44.2` patched range; `L5` the
three Kubernetes sentences quoted above; `L6` the build-script requirement in
`built`'s, `vergen`'s and `shadow-rs`'s own READMEs and `git-version`'s git-binary
requirement; `L7` the two production probe implementations read at
`raw.githubusercontent.com`; `L8` the crates.io census; `L9` the four
build-metadata repositories through keyring-authenticated `gh api`, **never faster
than one call per 20 s** (the script enforces the spacing itself), with the
`git-version` HTTP 422 reproduced and recorded absent. No token bytes and no
personal email address appear in any script, log, snapshot or User-Agent; the
User-Agent is
`rs-launch-blueprint-research (+https://github.com/smorinlabs/rs-launch-blueprint)`.

Result in place: **9 PASS, 0 FAIL, 0 SKIP**, exit 0, saved as
`review/evidence/check-live.log`.

**Reproduction, stated exactly rather than asserted.** Every log cited above was
rerun and diffed before this sentence was written; the diffs are committed, and
what varies is named rather than smoothed over. Two lines cannot repeat and are
normalised out of every comparison: the `date(UTC):` stamp, and the `mktemp`
workspace path the probe prints and `cargo tree` echoes back. **`check-offline.log`
then reproduces byte-for-byte** — `check-offline.rerun.diff` is **0 bytes**. **For
`check-probe.log` the assertion lines reproduce byte-for-byte and the rest does
not**: `check-probe.rerun.assertions.diff` (every `PASS`/`FAIL`/`SKIP` and the
totals line) is **0 bytes**, while `check-probe.rerun.diff` (the whole log) carries
**44 differing lines, every one of them a cargo `Compiling` / `Blocking waiting for
file lock` / `Finished` progress line** whose order and timing vary between runs —
`0` differing lines are anything else.

**All three scripts were then rerun from a clean `git archive HEAD` extraction
into a fresh `$TMPDIR` directory, after the commit that carries them**, and all
**49 checks passed there with 0 FAIL and — the point of naming them — 0 SKIP**:
27 + 13 + 9. The extraction has no `.git` at all, which the offline script reports
rather than assumes (it tests with `-e`, not `-d`, because a worktree's `.git` is a
file). The archive diffs are committed: `check-offline.archive.diff` differs on
**exactly one line**, `git metadata: present` versus
`git metadata: absent (archive extraction)`; `check-probe.archive.diff` differs on
**47 lines, every one a cargo progress line**; and
`check-live.archive.assertions.diff` differs on **exactly one line**, the
`mode: fetch` versus `mode: snapshots` banner. The three
`*.archive.assertions.diff` files — every `PASS`/`FAIL`/`SKIP` line and every
totals line of all three scripts — are **0 bytes**. The archive run's live log is
committed as `check-live.archive-snapshots.log`. **`check-live.sh` cannot reproduce byte-for-byte
and this decision does not claim that it does**: crates.io download counters and
search denominators advance continuously. Its assertions are therefore written on
**structure and pins** — version strings, `rust_version` null-ness, HTTP status
codes, quoted sentences — and never on a counter; every moving figure is *printed*
beside its endpoint so a reader can see what it was. The three census denominators
had already moved between `raw/opus.md`'s collection and this one, on the same day:
`q=health` 6,487 → **6,488**, `q=probe` 5,271 → **5,273**, `q=liveness` 28,351 →
**28,356**. Every reduced response body it read is snapshotted under
`review/evidence/snapshots/`, and `bash check-live.sh --snapshots` re-runs every
assertion against those committed bytes with no network at all — which is how the
archive extraction reruns it deterministically. The snapshots of crates.io JSON and
of the two kubernetes.io pages are **reduced in place** by a projection the script
documents and applies before any assertion, so the committed artifact and the
artifact the assertions read are the same bytes in both modes; nothing else is
reduced.

**Not run, and why.** No `ubuntu-latest` execution: every check above ran on macOS
only, so each member's gate-4 Linux answer rests on the crates' own CI and on R66's
and R69's prior records. No process-level test of the drain window (AC11): it needs
a running `<app>-serve` binary and none exists. No measurement of the
`spawn_blocking` hop under concurrency: R05 records the same gap for the same
bridge. No issue-responsiveness figure for seven of the eight crates: each needs
roughly eleven GitHub calls at the mandated one-per-20-seconds, and no member's
verdict turns on it — the figure `raw/opus.md` did compute, for `lukaslueg/built`
(median 0 days, about 3.4 hours, 0 of 4 unanswered), is **carried without
re-collection**.

**Proposed for the template's CI, not run here** (job wiring is R11's, tiers are
R32's): `cargo test --features web` and `cargo build --features web --bin
<app>-serve` on `ubuntu-latest` and `macos-latest`; `T1`–`T8` as template
integration tests through `oneshot` and once against a real listener; a
version-consistency test asserting `GET /healthz`'s `version` equals what
`--version` prints, the Rust analogue of py's `tests/meta/test_version_consistency.py`,
which fails loudly if the accessor is ever evaluated in the wrong package; a
`cargo check` leg pinned to the declared `rust-version`; and the AC11 `SIGTERM`
test. None of these can run today: no Rust code exists in this repository.

## Engines

- **opus** `raw/opus.md`, sha256
  `dd3bdeae9566ae10ea300c1c2e6727264075523cb2ccce1e95eea9eccc06a0fb` (Claude Opus
  5, collected 2026-09-18T22:26:40Z, registered in `manifest.json`; digest and
  bundle answer shape re-verified here by checks `O1` and `O2`).
- **codex** — **absent.** The Focused tier's Codex research leg was **deferred by
  the controller under owner ruling W1-CODEX3 of 2026-09-18** (the Codex account is
  at its usage limit; the owner's instruction was to test it and, if unavailable,
  "do without it"), recorded in `docs/planning/p02/owner-decisions.md` section 12
  and asserted by check `O10`. The run's `manifest.json` still lists
  `required_engines: ["codex", "opus"]` and its state is `partial`.

**This is therefore a single-engine synthesis, and there is no second engine to
disagree with.** The cross-check a second engine would have supplied is replaced
here by re-verification at source: every load-bearing claim was re-executed or
re-read rather than carried on the report's authority. The two lists below say
exactly which.

**Re-verified here, with the check that did it.** The registered report's digest
and shape (`O1`, `O2`). The seven `- assumes` values against the live registry
(`O3`). R69 revision 10's owned value and the registry's lag (`O5`). R49's
no-`build.rs` clause (`O6`). The ledger rows (`O7`). R60's ruling (`O8`). The
acceptance record (`O9`). The W1-CODEX3 and licence rulings (`O10`, `O11`). The
four in-flight couplings (`O12`–`O15`). R67's catalog (`O16`). The accepted
revisions and clauses of R02, R05 and R03 (`O17`–`O19`). The py and ts source
precedent at the programme pins, including both readyz tests and the error-capable
check count (`O20`–`O22`, `O27`, `O23`). The owner reference's two rows (`O24`).
The whole endpoint contract in axum 0.8.9 and tokio 1.53.1 — routing, statuses,
the latch, the `spawn_blocking` bridge, `405` with `Allow: GET,HEAD`, `HEAD`
handling, byte stability, the feature gating and the core member's dependency
graph (`A`, `B`, `T1`–`T8`, `C9`–`C11`). The crates.io pins and MSRV facts, the
RustSec picture with its control, the Kubernetes sentences, the build-script
requirement in three maintainers' own READMEs, the two production probe
implementations, the census, and the four build-metadata repositories' GitHub
rows (`L1`–`L9`).

**Carried from `raw/opus.md` without re-verification, and therefore held at the
report's own confidence.** The GitHub rows for `serde`, `serde_json`, `axum` and
`tokio` (stars, `archived`, open issues) — only their crates.io pins were
re-checked. The `unsafe` postures read from axum's and tokio's manifests. The
issue-responsiveness figure for `lukaslueg/built` and the statement that it was not
computed for the other seven. `rust-lang/crates.io`'s use of a runtime environment
variable for its deployed commit, and its `utoipa::ToSchema` derive on the
analogous build-identity response. The Cloud Run 10-second SIGTERM window, which
reaches this decision through R69. The observation that the four kubernetes.io
pages read for the report configure probes on the Pod spec and none mentions a
Dockerfile `HEALTHCHECK` — an observation about those pages, not a claim about
kubelet behaviour.

**Claims of `raw/opus.md` found wrong or overstated, and corrected above rather
than carried.**

1. **Wrong.** *"there is no test in that file for the 503 branch"* (py's
   `tests/web/test_app.py`). There is:
   `test_readyz_failure_is_a_problem_with_diagnostics` at lines 248-262 asserts
   `503`, reaching the branch by monkeypatching `run_diagnostics` with a hand-built
   failing report (check `O22`). The corrected form is in
   `### Principles and implementation`: the substitution is the evidence that the
   branch is unreachable from a real environment, which is the point the report was
   reaching for. **The recommendation does not move**: alternative C is selected
   for the drain state it can report, which alternative A cannot report at all.
2. **Stale citations.** The report cites **R02 revision 1** and **R05 revision 2**.
   The accepted revisions are **R02 revision 2** (`9e8f8e8c…`) and **R05 revision
   3** (`3ca4b81a…`), both evidence-only re-binds whose substance is unchanged
   (check `O17`). This decision cites the current revisions.
3. **Wrong status.** The report calls **R55 and R57 "open"**. Both are
   **owner-accepted and unpublished** — W1-R55 at revision 3 (2026-09-17) and
   W1-R57 at revision 2 (2026-09-16) (check `O9`). The substantive point survives
   in a stronger form: neither accepted decision defines a diagnostics check at
   all, so the check list that could reach `CheckStatus::Error` is **unowned**, not
   merely unpublished.
4. **Overstated.** *"R77 owns the window's value"* for the pre-drain
   readiness-propagation pause. R77's in-flight report owns a drain **deadline**
   (`RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`, recommended 8 s) and mentions a
   propagation or pre-drain pause on **0** lines (check `O15`). Recorded above as a
   requirement this item hands to R77, not as a fact about R77.
5. **Not carried.** The report answers **fitness gate 1** per candidate ("MIT,
   compatible with `MIT OR Apache-2.0`"). Those verdicts are struck; gate 1 is
   recorded as `inapplicable — owner ruling 2026-09-12 (Q7.B)` in the wording the
   revision rules prescribe (check `O26`).
6. **Newly surfaced, not in the report.** R70's in-flight raw report both reserves
   its envelope to "one extension member and no more" and hands `/readyz`'s failure
   body to R80 (check `O12`). The report assumed a `diagnostics` extension member
   was available. This decision states the requirement three ways and leaves the
   choice to R70.
7. **Drift, not error.** The census denominators moved between the report's
   collection and this one on the same day (6,487→6,488, 5,271→5,273,
   28,351→28,356). The comparison rule is under `## Empirical check`.
8. **Probe fidelity, stated so it is not mistaken for the recommendation.** The
   executed probe's shared function takes `(&Path, bool)` rather than the
   recommendation's `&Config`, because no published item defines `Config` yet; and
   its 503 body is a plain JSON stand-in, not R70's envelope. The probe exercises
   the *shape* — status codes, field sets, the latch, the bridge, the graph — and
   claims nothing about the final signature or the envelope's member names. Its
   `.expect(..)` on the `JoinHandle` is marked in the committed source as not the
   production shape.

**Unproven, and left for P03 to prove in the real template.** AC9 (one function,
two callers, one check list — needs the template's crates to exist). AC11 (the
drain window: `/readyz` answering 503 for the whole interval between the signal and
the exit, with the in-flight request completing and the process exiting 143 — needs
a running binary; the latch itself is executed, its interaction with R69's
`shutdown_signal()` and `serve_until` is reasoned from R69's recorded snippet). The
nonzero pre-drain pause that makes the latch observable to a fresh-connection probe
(needs an owner first). Every member's gate-4 answer on `ubuntu-latest`. The
concurrency cost of the `spawn_blocking` hop. And the 503 body's exact member names,
which are R70's to fix.

**Confidence.** **High** for the endpoint contract, the shared-function placement,
the latch, the method handling, the liveness payload's mechanism, the version
hazard and the feature gating: each rests on a published or owner-accepted artifact
*and* on a check executed here against the exact crate versions. **High** for the
census answering the prompt's LOW question, which has a printed denominator.
**Medium-high** for the drain-window behaviour, executed at the latch and reasoned
at the signal. **Medium** for the exact field list of `LivenessReport` — declining
uptime is a judgement with a stated cost, and adding a commit SHA is a one-field
change — and for the initial check set, which later items will extend. **Low
confidence is claimed nowhere**, and two figures are explicitly absent rather than
estimated: `git-version`'s open-issue count (HTTP 422, reproduced) and issue
responsiveness for seven of the eight crates.
