# 2026-09-17 — R03 — port-absence-vs-failure-contract (pattern, Deep) — decision (revision 1)

Synthesized 2026-09-17 by a fresh context that produced none of this item's raw
reports, from the engine reports in `raw/` plus the three verification scripts
recorded under `## Empirical check`. No template code exists, and none was
written: the only code in this run is a throwaway probe crate built under
`$TMPDIR` by `review/evidence/r03-probe.sh` and deleted when that script exits.

## Decision

**Status: a proposal, to be validated in the implementation phase** (owner
ruling 2026-09-10). This is a P02 research decision, not a shipped design. P03
builds the template and its CI proves the recommendation; the list of what P03
must validate is under `## Engines`. A recommendation that does not survive
implementation is **revised against this recorded research** — the raws, the
alternatives comparison, the engine disagreements and the evidence logs cited
below — rather than researched again from scratch.

`rs-launch-blueprint` **splits absence from failure at the seam and translates
absence in the use case**. The pattern, named here so the template can refer to
it in one phrase: **absent is a value, broken is an error, the use case
decides.** It adds no crate. Six binding rules:

1. **Seam signature.** A driven-I/O *read* that addresses one resource by
   identity returns `Result<Option<T>, PortError>`. A read that returns a
   collection returns `Result<Vec<T>, PortError>`, where an empty vector is a
   complete, successful answer and never an absence. No port method returns bare
   `Option<T>`, bare `T`, or `Option<Result<T, E>>`, and no port exposes a
   separate `exists`/`contains` probe. The rule is about the return type, not
   about the binding mechanism, so it holds whether R01's boundary is a trait
   method, a generic bound or an injected closure.
2. **`PortError` is transport vocabulary only.** A `thiserror`-derived,
   `#[non_exhaustive]` enum whose cause fields are
   `Box<dyn std::error::Error + Send + Sync + 'static>`, so no HTTP-client type
   reaches the library's public API. **`PortError` has no `NotFound` variant** —
   that is the point of rule 1.
3. **The adapter owns the absence rule, per operation, written out explicitly.**
   `GET /projects/{id}` answering 404 → `Ok(None)`. A 404 from a *collection*
   endpoint, a 404 from a misconfigured base URL, any 5xx, any unparsable 200 and
   any timeout → `Err`. Each such rule is an explicit `match` arm in the method
   that has one — never a shared `bool` parameter, never a blanket "404 anywhere
   means absent".
4. **The use case is the only translation site.**
   `self.port.get(id)?.ok_or_else(|| DomainError::NotFound { kind, id: id.to_owned() })`,
   or the equivalent `let … else` guard. No adapter constructs a `DomainError`;
   no front end constructs one from a port result.
5. **`DomainError` wraps `PortError`** via `#[error(transparent)]
   Port(#[from] PortError)`, so the `source()` chain reaches the original cause,
   and exposes the `ErrorCode`/exit mapping R67 owns. `DomainError::NotFound`
   maps to the **existing** `RSLB301` → exit `3`; **no new catalogue row is
   requested**, and the resource kind travels in the variant's `kind` field
   rather than in a second code.
6. **The prohibition is testable and tested.** Omitting rule 4 is a compile
   error, not a runtime surprise, and the template keeps a `compile_fail`
   doctest saying so; R01's shared contract function
   `assert_projects_port_contract` gains three absence/failure assertions so
   every adapter, real and fake, is held to rules 1 and 3.

Every failure this pattern can produce lands on an R67 catalogue row that
already exists (verified, `## Empirical check` §1.5):

| `PortError` variant | R67 catalogue row | Exit |
|---|---|---|
| `Io { source: std::io::Error }` | `RSLB101` I/O | 1 |
| `Transport { source: Box<dyn Error + Send + Sync> }` — DNS, connect, timeout, TLS | `RSLB102` transport | 1 |
| `RemoteApi { source: … }` — a non-2xx that is not 404/401/403/409, and any unparsable 200 | `RSLB103` remote-API failure | 1 |
| `Unauthorized { source: … }` — 401/403 | `RSLB402` credentials rejected | 4 |
| `Conflict { source: … }` — 409, failed precondition | `RSLB501` conflict/precondition failed | 5 |
| `Unavailable { detail: String }` — R01's poisoned-`Mutex` case | `RSLB101` I/O (proposal; see `## Engines`) | 1 |
| *(no variant — absence is not an error here)* | `RSLB301` resource not found, constructed by the use case | 3 |

**Ranked runner-up: the fold** — `fn get(&self, id) -> Result<T, PortError>` with
a `PortError::NotFound` variant. It is the more common shape at Rust crate
surfaces (verified: `object_store::Error::NotFound`, `jj`'s
`BackendError::ObjectNotFound`, `sqlx::Error::RowNotFound`, and std's
`io::ErrorKind::NotFound`; `## Empirical check` §3.1, §3.4). It wins when the
caller could not have invented the identity it is looking up — a content hash, an
internal surrogate key, a handle the system itself issued — because absence is
then corruption rather than a normal answer, and when the operation is a
*mutation* (`delete(id)`, `update(id, …)`), where `Ok(None)` names nothing
useful. Rule 1 is scoped to reads for exactly that reason.

Settled ledger row: **F012** (`docs/port/COMMONALITY.md:18`, origin `different`,
verdict `DIVERGENT`, item `R03` — verified, §1.7). No `BASELINE-REVIEW:` line is
raised: F012 is this item's own research row, not a retained `REUSE`/`ADOPT`
baseline being challenged.

### Principles and implementation

**The shared requirement, and the level at which agreement is required.** The
principle is not "use `Option`", which is a spelling. It is: **a driven-I/O read
that finds nothing reports a normal outcome, and the decision that "nothing" is
a user-facing failure belongs to the use case, not to the adapter that performed
the I/O.** Two consequences follow independently. First, the adapter cannot know
whether a caller wants absence to be fatal — a `delete --if-exists` and a
`show <id>` disagree about the same `Ok(None)`. Second, absence and transport
failure can never be confused by a caller reading only the type.

*Source of the requirement, and its agreement level.* The requirement is
recorded under a stable ID in the Python source repo: **HEX-12**, in
`py-launch-blueprint` at pin `b08bccfb`,
`docs/design/0005-hexagonal-architecture-and-enforcement.md:134-138` — "*`None`
means 'absent', exceptions mean 'broke'. … The **application service**, not the
adapter, decides that absence is a user-facing error*" — with HEX-13 (`:161-175`)
pinning the adapter's half (`# None on 404, raise on 5xx`). The code matches the
document at that pin (`core/ports.py:47,49`; `core/services/projects.py:56-63`).
TypeScript has **no** recorded decision here: `TS_PORT_DECISIONS.md` carries no
`D-0nn` for this split, and `src/lib/api.ts` at pin `cb1cbcb2` folds the
workspace resolution, the HTTP call and the `NotFoundError` throw into one
function (`:179`, `:182`, `:184`). Both readings are `raw/opus.md`'s, taken from
the pinned checkouts; this synthesis did not re-read the two source repositories
(see `## Engines`, *unproven*).

The agreement level is an **architectural pattern**, specifically a *layer
assignment*: which ring converts absence into a domain error. That is what must
agree across py, ts and rs. What may vary is every mechanical detail — Python
spells absence `None` and failure as a raised exception because it has no sum
type in the return position; TypeScript would spell absence `undefined` and
failure as a thrown `Error`; Rust spells both in one return type because it has
one. `docs/port/DIVERGENCE-ANALYSIS.md:58,80` labels F012 `harmonize: no`, and
the owner's 2026-09-04 direction asks for one best-practice pattern across all
three repos. Those reconcile rather than collide: `harmonize: no` is right about
the *mechanism* (nothing about `Result<Option<T>, E>` transfers to Python or
TypeScript), and the owner is right about the *layer assignment*, which is the
level at which agreement is actually required and which py already documents.

**One wording correction to F012, carried here rather than as a
`BASELINE-REVIEW:` line, because this decision is what settles that row.** The
ledger states the pattern as "`None`/empty means absent". Rust must separate the
two. `Ok(vec![])` from a `list` operation is a **successful, complete answer that
happens to be empty** and must never become a not-found error; `Ok(None)` from a
`get` operation is the absence of an addressed thing. Python inherits the
conflation from a language where `None` and `[]` are both falsy; Rust has
distinct types and the pattern uses them distinctly (rule 1).

**Essential behaviors.**

1. A read addressing one resource by identity returns three distinguishable
   states in one value: found, absent, failed.
2. Absence travels in the success channel — never an `Err`, never a sentinel
   value, never an empty struct standing in for "missing".
3. Transport, protocol, I/O and authorization failures travel in the error
   channel, in a port-owned error type whose variants map onto R67 rows.
4. The adapter, and only the adapter, decides which upstream signal means
   "absent", per operation and opt-in, never blanket.
5. The use case, and only the use case, decides that absence is a domain error,
   and names the offending input when it does.
6. A collection read returns `Ok(Vec<T>)`; an empty vector is success.
7. The port exposes no separate existence probe; absence is reported by the same
   fallible call that would have returned the value.
8. Forgetting behavior 5 is a compile error.

**Observable acceptance criteria.** AC1–AC6 were executed in this run against a
throwaway probe with a fake port; AC7 is a compiler observation from the same
probe. AC8–AC10 are requirements on P03's template, not results.

| # | Criterion | Status |
|---|---|---|
| AC1 | A found resource returns `Ok(value)` from the use case | **executed** (§2.2, `present_is_ok`) |
| AC2 | An absent resource produces a domain error whose code is `RSLB301` and whose exit is `3`, with a message naming the offending input | **executed** (§2.2, `absence_is_rslb301_exit3_names_the_input_and_has_no_source`) |
| AC3 | That absence error has **no** `source()` — absence has no transport cause | **executed** (same test) |
| AC4 | A transport failure produces `RSLB102`/exit `1` and its `source()` chain still reaches the original `io::Error` after crossing `?` | **executed** (§2.2, `transport_failure_is_rslb102_exit1_and_keeps_its_cause_chain`) |
| AC5 | A local I/O failure produces `RSLB101`/exit `1`, and an unavailable adapter state is a failure rather than an absence | **executed** (§2.2, two tests) |
| AC6 | An empty collection read is `Ok` and empty, never a not-found error | **executed** (§2.2, `empty_list_is_success_not_absence`) |
| AC7 | A use case that calls the port and forgets the absence translation **fails to compile** | **executed** (§2.3, `error[E0308]`; and `error[E0277]` for `?` applied to the `Option`) |
| AC8 | An adapter contract test proves that a 404 on a by-identity read yields `Ok(None)`, while a 404 on a collection endpoint and any 5xx yield `Err` | proposed — needs a real adapter; P03 |
| AC9 | A malformed 200 response yields `Err(PortError::RemoteApi)`, never `Ok(None)` | proposed; P03 |
| AC10 | The web handler maps the same absence to HTTP 404 with no second translation site | proposed; R70 owns the status table |

AC9 is not hypothetical. py's adapter comment at pin `b08bccfb`,
`src/py_launch_blueprint/core/adapters/py_api.py:188-195`, records the regression
it was written to close — a 200 that could not be parsed once shared the absence
channel, "which is what previously let schema drift masquerade as 'not found'"
(quoted from `raw/opus.md`; not re-read here). That is the failure mode the
absence channel invites, and Rust does **not** prevent it by construction:
`Ok(None)` is well-typed whatever produced it. Only AC8 and AC9 catch it, which
is why they are mandatory P03 work rather than optional.

**Architectural alternatives, compared before any library was weighed.**

| Alt | Shape at the seam | Verdict and the principle at stake |
|---|---|---|
| A | `fn get(&self, id) -> Result<T, PortError>` with `PortError::NotFound` | **Ranked runner-up.** Idiomatic and common. Loses behavior 5 — the adapter has already declared absence a failure, so a caller who wants "absent is fine" must match an *error* variant to recover a normal outcome. Loses AC7: forgetting to handle not-found compiles. |
| B | `fn get(&self, id) -> Option<T>` | **Rejected.** Deletes the failure channel; a network call would be infallible in the type system. This is py's *signature* read literally, but py's port raises for transport failure — the exception channel is Python's `Err`. |
| C | `fn get(&self, id) -> Option<Result<T, PortError>>` | **Rejected.** Wrong nesting: absence is not knowable until the fallible operation has succeeded. std ships `Option::transpose` (stable since 1.33.0, verified §3.1) to convert *out of* this nesting into D's, which is the ecosystem's own statement of which nesting is canonical. This answers the prompt's second HIGH question directly. |
| **D** | **`fn get(&self, id) -> Result<Option<T>, PortError>`**, translated at the use case | **Chosen.** Three states, one value, nothing lost; every behavior preserved; AC7 makes the translation compiler-enforced. |
| E | `fn get(&self, id) -> Result<Lookup<T>, PortError>` with a bespoke `enum Lookup { Found(T), Absent }` | **Rejected as the default**, kept as a documented variation. Isomorphic to D but invents a type the ecosystem already has: `Option` carries the std combinators, `?`-interop and universal familiarity. It earns its keep only when absence acquires sub-kinds — `sccache`'s `Cache::{Hit, Miss, None, Recache}` is that case, on `raw/opus.md`'s reading, which this synthesis did not re-read. Migrating D→E is mechanical; migrating A→D is not. |
| F | Add `fn exists(&self, id) -> Result<bool, PortError>` beside `get` | **Rejected outright.** Two round trips and a time-of-check-to-time-of-use window std warns about by name: `Path::exists` carries "this method may be error-prone, consider using [`try_exists()`] instead!" at tag `1.96.0` (verified §3.1). |

**How the chosen design preserves each principle.** The seam (the method set
itself is R01's):

```rust
pub trait ProjectsPort: Send + Sync {
    /// `Ok(None)` means the upstream authoritatively has no such project.
    /// `Err` means the lookup could not be completed.
    fn get(&self, id: &str) -> Result<Option<Project>, PortError>;
    /// An empty `Vec` is a complete answer, never an absence.
    fn list(&self, workspace: Option<&str>) -> Result<Vec<Project>, PortError>;
}
```

The whole translation is one expression, in one file:

```rust
impl<P: ProjectsPort> ProjectsService<P> {
    pub fn get_project(&self, id: &str) -> Result<Project, DomainError> {
        self.port.get(id)?                    // transport failure -> Err, via #[from]
            .ok_or_else(|| DomainError::NotFound { kind: "project", id: id.to_owned() })
    }
}
```

Behaviors 1–3 are the return type. Behavior 4 is rule 3, and it is what
`rust-lang/crates.io` does in production: its `GitHubClient` port declares
`team_membership` and `org_membership` as `Result<Option<…>>` while its other
methods return `Result<T>`, and exactly two adapter methods carry the arm
`Err(GitHubError::NotFound(_)) => Ok(None),` (verified at commit `3a31e6c8`,
§3.2 — two occurrences, no more). Behavior 5 is rule 4.
Behavior 6 is the `Vec` half of rule 1. Behavior 7 is alternative F, rejected.
Behavior 8 is AC7: `Option` has no `From` into a domain error and cannot acquire
one, so the conversion cannot hide inside `?` — dropping it produces
`error[E0308]: `?` operator has incompatible types … expected `Project`, found
`Option<Project>``, and applying `?` to the `Option` itself produces
`error[E0277]: the `?` operator can only be used on `Result`s, not `Option`s, in
a function that returns `Result``. Both were observed, not argued (§2.3).

*Wrapping rather than flattening.* `DomainError` holds
`#[error(transparent)] Port(#[from] PortError)` beside `NotFound { kind, id }`
instead of copying `PortError`'s variants. `#[from]` is what makes the first `?`
above a one-token conversion; the `source()` chain survives it, which is what
Rust API Guidelines C-GOOD-ERR exists to protect — observed in the probe as the
exact chain `["transport failed", "connect timed out"]` after crossing `?`
(§2.2). The cost is one extra hop that R67's envelope does not render anyway,
its `{"error":{"code","message","hint"?}}` having no cause array.

*The prompt's MEDIUM ergonomics question, answered.* The split costs nothing
against py's two-step, because it **is** py's two-step with the compiler checking
it: `?` then `.ok_or_else(…)`, two operators on one expression, against py's
`x = repo.get(...)` / `if x is None: raise`. Where a guard clause reads better,
`let Some(p) = self.port.get(id)? else { return Err(DomainError::NotFound { … }); };`
gives the imperative form with no combinator (`let … else` is stable since
1.65.0, well below the 1.96 floor).

*The prompt's MEDIUM R67-coupling question, answered.* The absence variant does
**not** need a new stable catalogue member decided now. `RSLB301` resource not
found → exit `3` already exists, and R67 requires the message to name the
offending input: "*it must be able to name the offending input as R7.6 requires
— `error: project 'demo' not found`*" (`research/topics/67-…/DECISION.md:169`).
One row therefore covers every resource kind, with the kind carried in
`DomainError::NotFound { kind, id }` and rendered into the message. py has two
not-found codes (`PLBP005` project, `PLBP006` workspace), so per-resource codes
are a reasonable thing for the owner to want later, and R67's catalogue is
append-only over a `#[non_exhaustive]` enum, so adding `RSLB302` would be a
non-breaking append (no `RSLB302` exists today — verified §1.5). This item
recommends **not** taking it now: a second row is dead weight until a caller
actually branches on resource kind.

**Fit per target shape.** *CLI*: the best fit, and where the split earns its
keep. `rslbp show demo` supplies the identity, so "no such project" is an
ordinary answer; the use case converts it to `DomainError::NotFound` → `RSLB301`
→ exit **3**. The CLI also has commands where absence is *not* an error — an
`--if-exists` delete, an idempotent `ensure` — and under the fold those would
have to recover a normal outcome by matching an error variant; under D they
match `Ok(None)`. *Library*: the decisive case. A downstream crate gets a port
whose type says what happened and may make its own layer assignment — call
`ProjectsPort::get` and handle `Ok(None)`, or call `ProjectsService::get_project`
and take the template's opinion. That is exactly the `sqlx` relationship:
`fetch_optional` is the **required** trait method, declared with no body and
returning `Result<Option<…>, Error>`, and `fetch_one` is a *provided* method
built from it that supplies `None => Err(Error::RowNotFound)` (verified at commit
`b54008a3`, §3.3). *Web service*: it removes a translation site rather than adding
one. R01 fixed the web layer as a thin adapter over the same service the CLI
uses (F018), so the handler maps `DomainError::NotFound` → HTTP **404**, one arm
in the table **R70 owns**; R01 also contemplates a handler returning
`Json<Option<Project>>` directly, which works only because absence rides the
success channel (verified: R01 names that type, §1.6).

**Reference implementations cited, each read at a pin in this run.**
`rust-lang/crates.io` @ `3a31e6c8` (`crates/crates_io_github/src/lib.rs`) for the
port with per-operation 404 translation; `sqlx` @ `b54008a3`
(`sqlx-core/src/executor.rs`, `error.rs`) for the split-as-primitive /
fold-as-derived relationship; `apache/arrow-rs-object-store` @ `279572ea`
(`src/lib.rs`) and `jj-vcs/jj` @ `e6dd2c0d` (`core/src/backend.rs`) for the
runner-up shape and its boxed-cause field convention; `rust-lang/rust` @ tag
`1.96.0` for `Option`'s partial-function framing, `ok_or_else`, `transpose`,
`io::ErrorKind::NotFound` and the `Path::exists` TOCTOU warning.

**Cross-repo adjudication** (changes to py and ts are a follow-on project; this
supplies the rationale only). **py: no change.** HEX-12 already states the
principle, correctly layered, with a per-operation `allow_not_found` opt-in; the
one suggestion is the HEX-12 wording separating "no such id" from "empty
result", as above. **ts: accidental drift, not a justified ecosystem
difference.** There is no `D-0nn` recording the fold as a decision
(`DIVERGENCE-ANALYSIS.md:80` — "no recorded reason"), and nothing in TypeScript
prevents the split: `getWorkspaces().find(…)` already yields `undefined`.
Proposed follow-on: the client returns the resolved workspace or `undefined`,
and the `NotFoundError` throw at `src/lib/api.ts:184` moves to the layer that
owns the use case.

**Performance.** No benchmark is offered and none would be honest. The pattern's
entire runtime cost is one `Option` discriminant test and one enum construction
on a path that has just completed a network or filesystem round trip; any
measurement at that granularity measures the allocator. Compile-time and
binary-size cost: zero beyond `thiserror`, which R67 already selected.

re-verify: on any of — R01 revising the seam away from a trait port (re-check that rule 1 still reads naturally against a closure-valued seam; the rule is about return types, so no change is expected); R05 selecting async (re-check that `Result<Option<T>, PortError>` behind `#[async_trait]` still boxes cleanly — verified in principle, never in code, in this run); R67 amending the catalogue, specifically splitting `RSLB301` per resource kind or settling the `hint` signature in a way that changes how `DomainError::NotFound` renders the offending input; R70 publishing its status table (confirm `NotFound` → 404 is the single arm and no second absence translation appeared in the web layer); R48 selecting a mocking crate (confirm it can express "the port returned `Ok(None)`" as distinct from "the port returned `Err`"); `rust-lang/crates.io` moving `team_membership`/`org_membership` to a `NotFound` error variant, which would remove the strongest single piece of practice evidence for the split — cheap to check by re-reading `crates/crates_io_github/src/lib.rs` at a fresh commit; the `msrv-policy` floor rising past 1.96, where no effect is expected because every construct used predates 1.65; or 2027-03-17, whichever comes first.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**No owned parameter.** The prompt's `## Couplings` block carries an empty
`- owns:` line and `- consumes: R67: error-taxonomy-exit-codes`; the registry
names no row whose owner is R03, and `research/CLAUDE.md` records `—` in R03's
`owns` column (all three verified, `## Empirical check` §1.2). There is therefore
no `- owns` line above, and this file contains zero of them.

**No `CONFLICT:` line.** Every failure the pattern can produce lands on an R67
catalogue row that already exists, and the one row the pattern's *absence* path
needs — `RSLB301` resource not found → exit `3` — is already published. Nothing
in R67 has to change for this recommendation to hold. The five values above are
byte-identical to the current `docs/port/PARAMETERS.md`, which is itself
byte-identical to the run's `inputs/PARAMETERS.md` on every row this item
consumes; the two files differ on exactly one row, `web-extra-surface`, which
this item does not consume (verified, §1.1 and §1.3).

How each bears on the decision. `error-taxonomy-exit-codes` is the load-bearing
one: it supplies `RSLB301` → 3 for the absence path, `RSLB101`/`RSLB102`/
`RSLB103`/`RSLB402`/`RSLB501` for the `PortError` variants, the append-only
`#[non_exhaustive] ErrorCode` enum that makes a future per-resource code a
non-breaking addition, the R7.6 requirement that the message name the offending
input, and the layering rule — `thiserror` in the library crate, `anyhow` in
binary crates only — that keeps `PortError` and `DomainError` concrete and
matchable. `rust-edition = 2024` and `msrv-policy` are satisfied by construction:
every construct the pattern uses is core-language and long predates the 1.96
floor the policy evaluates to against the 1.98.0 stable recorded in
`review/evidence/toolchain.txt` (`Option`, `Result`, `?` and `ok_or_else` since
1.0.0; `transpose` since 1.33.0, verified §3.1; `let … else` since 1.65.0, taken
from `raw/opus.md` and not re-verified here). `target-os-matrix` is **not**
satisfied by this run: the probe compiled and ran on macOS only, and
`ubuntu-latest` was not exercised (recorded under `## Engines`). `license` is
recorded and **not** evaluated as a gate, under the owner ruling of 2026-09-12
(Q7.B, `docs/port/OWNER-REVIEW.md:47`): licence gate 1 is `inapplicable — owner
ruling 2026-09-12 (Q7.B)`, nothing here is admitted or excluded on a licence, and
no surveyed project's licence is reported at all. The pattern adds no crate, so
gates 2, 3, 5 and 6 are `inapplicable` for want of a candidate — stated, not
omitted — with the `unsafe` posture recorded as **none**: every construct is safe
stable Rust and the probe crate contains no `unsafe` block. Gate 4 is
`inapplicable` as a crate-CI question and is answered substantively above: the
constructs are platform-independent, and only macOS was exercised.

R01's `http-transport-injection-seam` is **not** listed above, because this item
does not consume it: the prompt names R01 as "related (not a registry
dependency)" and requires the pattern to work against a trait method, a generic
bound or an injected closure alike. R01's published decision is nonetheless the
seam this pattern decorates — it reserves this item's slot in so many words, "the
port error type (vocabulary R67's, absence shape R03's)" — and it is pinned into
this run by `inputs/prerequisites.json`, whose sha256 for R01's and R67's
published `DECISION.md` both match the files on disk (verified, §1.4 and §1.6).

## Empirical check

**Toolchain.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0
(797e8a9bc 2026-08-05)`, macOS 26.4 on `arm64` (`Darwin 25.4.0`). The full
strings, plus the probe's manifest settings, are in
`review/evidence/toolchain.txt`; they are kept out of the logs so that a rerun
diffs clean. `shellcheck` 0.11.0 was run over all three scripts and is clean.

**Working directory.** Every command below was run from
`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/evidence` inside the
repository worktree. Each script resolves its own paths from `$0`, so it runs
unchanged from anywhere, including a clean `git archive HEAD` extraction; the
sections that need something outside such an extraction — a Rust toolchain, the
network, `gh` — print `SKIP <name>` with the reason instead of failing. **Nothing
was implemented.** No template module, port, adapter, service, CLI, web handler
or acceptance harness was written into this repository; the only code is the
throwaway crate described in §2, created under `$TMPDIR` by `mktemp -d` and
deleted by the script's `trap` on exit.

| # | Command | Exit | Log |
|---|---|---|---|
| 1 | `bash r03-contract.sh` | `0`, all checks PASS | `review/evidence/r03-contract.log` |
| 2 | `bash r03-probe.sh` | `0`, all checks PASS | `review/evidence/r03-probe.log` |
| 3 | `bash r03-practice.sh` | `0`, all checks PASS | `review/evidence/r03-practice.log` |

Each script sets `-o pipefail`, asserts on the *content* it expected rather than
on an exit status, names `/usr/bin/grep` beside every count, and returns the
number of failed assertions as its exit status. Each log in the table is the
complete stdout of its script: each script was re-run after its log was written
and `bash <script> | diff - <log>` was empty, on the same toolchain and against
the snapshots already in `review/evidence/snap/`.

**§1 — the record (`r03-contract.sh`, 32 assertions, 0 failures).** Reads only files in this
repository; no network, no `.git`.

- §1.1 The five `- assumes` values are **generated from `docs/port/PARAMETERS.md`
  by the script**, never typed, and diffed against the five lines in this file:
  identical, and this file carries zero `- owns` lines.
- §1.2 The prompt's `- owns:` line is empty; its only `- consumes:` line is
  `R67: error-taxonomy-exit-codes`; the registry has **0** rows whose owner is
  `R03`; `research/CLAUDE.md`'s R03 row carries `—`.
- §1.3 `inputs/PARAMETERS.md` and `docs/port/PARAMETERS.md` differ on exactly one
  row, `web-extra-surface` (R69 published after this run's inputs were frozen);
  all five consumed/fixed rows are byte-identical between the two files.
- §1.4 `shasum -a 256` of the published `research/topics/01-…/DECISION.md` and
  `research/topics/67-…/DECISION.md` equals the values in
  `inputs/prerequisites.json` — `44bf9ae9…` and `16947ab1…`.
- §1.5 Each of the seven catalogue rows this decision cites is present verbatim
  in the registry cell, including `` `RSLB301` resource not found → 3 ``;
  `RSLB302` is **absent**; the append-only clause, the `main`-returns-`ExitCode`
  clause and the "library crate must not depend on `anyhow`" clause are all
  present.
- §1.6 R01's published decision reserves this item's slot (two occurrences of
  "absence shape R03"), names `PortError::Unavailable`, and names
  `Json<Option<Project>>`.
- §1.7 `docs/port/COMMONALITY.md:18` is the F012 row, `different` / `DIVERGENT` /
  `R03`.

**§2 — the shape, in the compiler (`r03-probe.sh`, 9 assertions, 0 failures).** A throwaway crate
(`edition = "2024"`, `rust-version = "1.96"`, one dependency `thiserror = "=2.0.20"`
resolved `--offline` from the local registry cache) holding the `PortError`,
`DomainError`, `ErrorCode`, `ProjectsPort` and `ProjectsService` shapes above
plus a programmable fake. `ErrorCode` and the exit mapping are **minimal stand-ins
for R67's**, sufficient to prove routing and nothing more.

- §2.1 `cargo build --offline` exits `0`; the generated lockfile pins
  `thiserror 2.0.20`.
- §2.2 `cargo test --offline --test absence_vs_failure` →
  `test result: ok. 7 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out`.
  The seven names are printed in the log. Asserted inside them: the absence
  error's `Display` is `project 'demo' not found`, its code is `RSLB301` and its
  exit is `3`, and its `source()` is `None`; the transport error's chain after
  crossing `?` is exactly `["transport failed", "connect timed out"]` with code
  `RSLB102`/exit `1`; a local I/O failure and an `Unavailable` adapter state are
  both `RSLB101`/exit `1` and neither is `RSLB301`; an empty `list` is `Ok` and
  empty; and `Option::transpose` converts alternative C's nesting into D's.
- §2.3 Two deliberately broken use cases, each its own test target so each
  reports its own compiler error. `Ok(port.get(id)?)` — rule 4 omitted — fails
  with `error[E0308]: `?` operator has incompatible types` … `expected `Project`,
  found `Option<Project>``. Applying `?` to the returned `Option` fails with
  `error[E0277]: the `?` operator can only be used on `Result`s, not `Option`s,
  in a function that returns `Result``. Raw cargo output for both, and for §2.2,
  is snapshotted under `review/evidence/snap/`.

**§3 — the practice and language claims (`r03-practice.sh`, 21 assertions, 0 failures).**
Every source file is fetched at an immutable ref — a git tag for `rust-lang/rust`
and a full commit SHA for each practice repository — and snapshotted into
`review/evidence/snap/`, so the quoted bytes cannot drift; retrieval timestamps
are in `snap/RETRIEVED.txt`.

- §3.1 `rust-lang/rust` @ tag `1.96.0`: `core/src/option.rs` frames `Option` as
  the return of functions "not defined over their entire input range (partial
  functions)"; `ok_or_else` carries `#[stable(feature = "rust1", since = "1.0.0")]`;
  `transpose` carries `#[stable(feature = "transpose_result", since = "1.33.0")]`;
  `std/src/io/error.rs` is `#[non_exhaustive]` and documents `NotFound` as "An
  entity was not found, often a file."; `std/src/path.rs` carries the
  `Path::exists` TOCTOU warning quoted under alternative F.
- §3.2 `rust-lang/crates.io` @ `3a31e6c8`: `pub trait GitHubClient: Send + Sync`;
  `Result<Option<GitHubTeamMembership>>` and `Result<Option<GitHubOrgMembership>>`
  each appear twice (trait declaration plus impl); the arm
  `Err(GitHubError::NotFound(_)) => Ok(None),` appears **exactly twice**, which is
  the per-operation, opt-in rule this decision's rule 3 requires, quoted with its
  surrounding `match` in the log.
- §3.3 `sqlx` @ `b54008a3`: `fn fetch_optional<…>` is declared with **no body**
  (its `where` clause ends in `;`) and returns
  `Result<Option<<Self::Database as Database>::Row>, Error>`; `fetch_one` is built
  from it and supplies `None => Err(Error::RowNotFound),`; `Error::RowNotFound`
  exists.
- §3.4 The runner-up shape at its own pins: `object_store` @ `279572ea` has
  `NotFound { path, source }` whose cause field is
  `Box<dyn std::error::Error + Send + Sync + 'static>`; `jj` @ `e6dd2c0d` has
  `ObjectNotFound {`.
- §3.5 `GET https://crates.io/api/v1/crates/thiserror`, retrieved 2026-09-17:
  `crate.recent_downloads` **362,994,715**, `crate.downloads` **1,470,911,701**,
  `crate.max_stable_version` **2.0.20**. Reported because `raw/doxa-gemini`
  quotes different figures for the same fields (see `## Engines`); the crate
  itself is R67's selection and is not re-evaluated here.
- §3.6 Source-repository visibility, through the already-authenticated `gh`
  binary (no token is read, printed or passed): `repos/smorinlabs/py-launch-blueprint`,
  `…/ts-launch-blueprint` and `…/rs-launch-blueprint` all report
  `.private = false`, and the three GitHub URLs `raw/doxa-openai.normalized.md`
  cites as evidence each return HTTP **200** unauthenticated. This **contradicts
  `raw/opus.md`**, which states "Both repositories are private and return HTTP
  404 from the network"; see `## Engines`.

## Engines

This synthesis rests on **two engines, Opus and Doxa**. The Codex leg is
**absent** by owner direction of 2026-09-16, recorded at
`docs/planning/p02/owner-decisions.md` §12 as `W1-CODEX` — "*Let's skip codex for
now*", with the consequence that "*Codex research legs and empirical audits are
deferred*". `raw/codex-transcript.txt` records the stopped runner and there is no
`raw/codex.md`. A later Codex report would be folded in by **revision** of this
decision, not by a fresh research run.

- **opus** `raw/opus.md` — Claude Opus 5 (sha256 `5b023ff3cfbd32b0323e0f6d136cfa907399b3bfffee153ab07a147df4025719`),
  15 H3 sections, shape OK. Recommends shape D with the adapter owning the
  per-operation 404 rule and the use case as the only translation site; runner-up
  A, which it reports as the *dominant* ecosystem shape; `PortError` with six
  variants mapped onto R67 rows; no new catalogue row; reports its own probe at
  8 tests plus a compile-fail proof.
- **doxa** `raw/doxa.md` — one engine, three provider bodies from operation
  `research-20260916-204519-57c7dae1a3e040ef`; `raw/doxa.normalized.md` regroups
  the same three bodies per field, and `raw/doxa-{openai,perplexity,gemini}.normalized.md`
  are the per-provider twins.
  - `raw/doxa-openai.normalized.md` — shape OK. Recommends the same split under
    the project-coined name "Lookup–Require Split", with `MUST`/`MUST NOT` rules,
    an explicit `map_err(ApplicationError::Source)?` at the call site, and a
    `find_*` / `get_*`-or-`require_*` naming pair.
  - `raw/doxa-perplexity.normalized.md` — shape OK. Recommends the same split as
    the "Port Absence–Failure Split" with `TransportError`/`DomainError`;
    proposes two *owned* parameters and a hypothetical `CONFLICT:` line; routes
    the CLI entry point through `anyhow::Result<()>`.
  - `raw/doxa-gemini.normalized.md` — shape OK. Recommends the same split as the
    "Result-Option Split" with `InfrastructureError`, and is the only body that
    excludes candidate error crates by gate (`anyhow` at intermediate
    boundaries, `snafu` on fit); its crate figures carry `[cite: n]` markers
    rather than endpoints.

**All four bodies converge on the recommended shape** — `Result<Option<T>, E>` at
the seam, translated in the use case — and none argues for the fold as the
template's default. Every disagreement below is downstream of that agreement.

1. *How the transport failure crosses the boundary.* Opus uses
   `#[error(transparent)] Port(#[from] PortError)` and a bare `?`; openai
   **requires** an explicit `.map_err(ApplicationError::Source)?`, arguing it
   "teaches where the abstraction crossing occurs"; perplexity accepts either.
   **Settled for `#[from]`,** on the ground that the property openai wants
   protected — the failure's identity surviving the crossing — is the one this
   run measured: the probe's chain assertion shows `source()` still reaching the
   original `io::Error` as `["transport failed", "connect timed out"]` after `?`
   (§2.2), and C-GOOD-ERR is satisfied either way. The explicit form remains
   permissible at any call site that wants to add context; the rule is that the
   *absence* translation stays explicit (rule 4), not that the *failure*
   conversion must be.
2. *Method naming.* openai asks for a `find_project` (optional) / `get_project`
   or `require_project` (required) pair, citing SeaORM's `one`/`require_one`.
   **Not adopted as a rename,** because R01's published decision already names
   the port method `get` — R01's own recorded compile-fail output reads
   `missing: get`, read there and not re-executed here — and the port/use-case
   split already carries the distinction
   openai's names would carry. Recorded instead as a **doc-comment convention**
   (rule 1's per-method sentence saying what `Ok(None)` means). Naming inside the
   template is P03's.
3. *Owned parameters.* perplexity writes `owns R03.seam_contract = …` and
   `owns R03.domain_translation = …`. **Rejected on the record:** the prompt's
   `- owns:` line is empty, `docs/port/PARAMETERS.md` has zero rows whose owner
   is R03, and `research/CLAUDE.md` records `—` (§1.2). A pattern item that owns
   no registry row cannot introduce one in its answer.
4. *What `main` returns.* perplexity says the CLI entry point "should be
   structured to return `anyhow::Result<()>`". **Rejected against R67**, whose
   accepted value states "`main` returns `ExitCode` and does not call
   `process::exit` on the error path" and confines `anyhow` to binary crates with
   "the library crate must not depend on `anyhow`" (both verified verbatim in the
   registry cell, §1.5). R67 owns that boundary; this item does not reopen it.
5. *Exit integers.* gemini writes that not-found maps to "a predictable and
   stable `EXIT_NOT_FOUND` (e.g., code 2 or 3)" and a network failure to "e.g.
   code 77". **Rejected against R67**, which fixes not-found → `3` and
   `RSLB102` transport → `1`; `77` belongs to a `sysexits.h` tradition this
   template does not follow. The pattern's mapping is the table under
   `## Decision`.
6. *`CONFLICT:` lines.* perplexity raises a **conditional** one ("if R67 were to
   require a single NotFound code that lumps transport failure and resource
   absence together"). That condition is false: R67 publishes separate rows for
   absence (`RSLB301`) and transport (`RSLB102`), verified §1.5. No `CONFLICT:`
   line is carried.
7. *Crate figures for `thiserror`.* gemini reports `crate.recent_downloads`
   268,005,132 and `crate.downloads` 1,099,987,875 with `[cite: 6, 12]` markers
   and no retrieval date; this run's own read of
   `GET https://crates.io/api/v1/crates/thiserror` on 2026-09-17 returns
   362,994,715 and 1,470,911,701 (§3.5). gemini's figures are recorded as
   **unsourced and stale**; nothing in this decision rests on them, and
   `thiserror` is R67's selection, not this item's.
8. *Provenance of the two source repositories.* `raw/opus.md` states that both
   are private and answer HTTP 404, and reads them only through local pinned
   checkouts; `raw/doxa-openai.normalized.md` cites public `github.com` URLs for
   the same files. **Opus's provenance sentence does not hold at this run's
   retrieval time**: on 2026-09-17 all three `smorinlabs` repositories report
   `.private = false` and every cited URL returns 200 unauthenticated (§3.6).
   Whether the visibility changed between Opus's retrieval and this check is not
   determinable from either record, so this is recorded as an observation with
   its date, not as a finding that the engine misreported. This corrects a
   statement *about* the evidence, not the evidence: Opus's py and ts readings
   are quoted here as its readings, at their pins, and were **not** re-read by
   this synthesis (see below). openai's citations were therefore fetchable, but
   they point at `main` rather than at the pins, so they are not interchangeable
   with the pinned readings either.

**Unproven here; P03's to prove in the real template.** Each row is a claim this
decision makes that no check in this run establishes.

| Claim | Status | What would prove it |
|---|---|---|
| A real HTTP adapter maps 404-on-a-by-identity-read to `Ok(None)` and everything else to `Err` (rule 3, AC8) | Unproven. No adapter exists; the rule is evidenced from `crates.io`'s production code, not from this template. | A contract test against a local stub server: `GET /projects/{id}` 404 → `Ok(None)`; `GET /projects` 404 → `Err`; 5xx → `Err`; connect timeout → `Err(PortError::Transport)`. The stub crate is R48's to choose. |
| A malformed 200 yields `Err(PortError::RemoteApi)` and never `Ok(None)` (AC9) | Unproven, and **not** prevented by the type system — `Ok(None)` is well-typed whatever produced it. | The same contract test with a body that fails to deserialize. This is the regression py's adapter comment records. |
| The web handler maps the same absence to HTTP 404 with no second translation site (AC10) | Unproven; blocked on R69/R70. | Once the web surface exists: `curl -i` against a bound listener for an absent id, asserting 404 from one mapping arm. |
| The pattern is unchanged under an async port | Unproven. No async code was written or compiled in this run. | A port with `async fn` methods under `#[async_trait]`, erased to `Arc<dyn ProjectsPort>`, with `?` and `ok_or_else` applied to the awaited value, compiling at the then-current floor. |
| `Unavailable` (R01's poisoned-`Mutex` case) belongs on `RSLB101` rather than on the `RSLB000` sentinel | **A proposal, not a finding.** Both exit `1`, so the user-visible outcome is identical; the argument is that `RSLB000` is R67's *unexpected* sentinel and feeds the crash-record sink, while a poisoned fake is a diagnosed, named adapter state. The probe asserts the routing the proposal describes, which is not evidence that the proposal is right. | R67's disposition, or P03's crash-record wiring showing that an `Unavailable` should not produce a crash record. |
| The six-variant `PortError` list is the right size | Unproven; it is sized to the template's example domain. A real adapter may need one more variant — rate limiting, say, which would be `RSLB103` or a new R67 row R74 might want anyway. | P03's real adapter, and R74 if rate limiting acquires its own signal. |
| The pattern behaves identically on `ubuntu-latest` | Unproven. Every compile and test in this run ran on macOS 26.4 `arm64`. The constructs are core-language and platform-independent, so the risk is low, but the claim is untested. | The template's CI matrix (R11): `cargo test --workspace --locked` on both legs of `target-os-matrix`. |
| The pattern compiles at the MSRV floor itself | Unproven. The probe declared `rust-version = "1.96"` but ran on `rustc` 1.98.0; no 1.96 toolchain was installed. The stability attributes read at tag `1.96.0` (§3.1) are the evidence that nothing used is newer than the floor. | A `cargo check` leg pinned to the declared `rust-version`. |
| py's and ts's current behavior, as described under `### Principles and implementation` | Taken from `raw/opus.md` at its recorded pins (`b08bccfb`, `cb1cbcb2`) and **not re-read** by this synthesis. Quoted as its readings, with the provenance correction in disagreement 8. | Re-reading both files at those pins. |

**Uncertainty.** The honest summary of the field is the one `raw/opus.md` reports
against its own recommendation: counted across public crate surfaces, the
*dominant* shape is the runner-up, not the pick — `object_store`, `jj`, `sqlx`'s
`fetch_one` and std's `fs` all expose a not-found error variant, and this run
verified each of those four. The pick rests on a narrower and more apposite
class: APIs shaped as a **port with a substitutable implementation**, where
`rust-lang/crates.io` and `sqlx`'s *primitive* both split, and on the layer
assignment the owner asked to keep across the three repos. A reviewer who weights
ecosystem conformity above the layer assignment should choose A; the cost of
being wrong is small and asymmetric — moving A→D later means touching every port
method signature and every call site, while moving D→A means deleting the
`ok_or_else` calls. That asymmetry is itself part of the argument for starting at
D, and it is an argument, not a measurement.
