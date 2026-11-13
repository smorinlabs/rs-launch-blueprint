# R03 — port-absence-vs-failure-contract — Opus raw report

Engine: Claude Opus 5, identity `research-opus-2026-09-17T033527Z-cd9e6a9555b6`.
Item kind: `pattern`. Effort tier: Deep. All network retrievals and pinned-repository
reads in this report were made on **2026-09-17** (UTC; the local session clock read
2026-09-16, and the run identity timestamp is `2026-09-17T033527Z`). Every figure
names the endpoint it came from. Every tool count names the binary that produced it.

### Landscape

**The category this item decides.** Not an error-reporting library and not an error
catalogue — R67 owns both and this report assumes them unchanged. The category is
narrower: **the return-type contract of a driven-I/O read that can legitimately find
nothing, plus the layer that converts "nothing" into a domain error.** Concretely, for
a port method shaped `get(id) -> ???`, which of three observable states — found,
legitimately absent, transport broke — travel in the success channel, which travel in
the error channel, and which layer collapses "absent" into a failure. Everything in the
three bins below is a way of answering exactly that.

**Bin 1 — built-in or first-party toolchain (language and standard library; no crate).**
Read at tag `1.96.0`, the `msrv-policy` floor, so nothing cited is newer than the floor
allows:

| Mechanism | Where, at `rust-lang/rust` tag `1.96.0` |
|---|---|
| `Option<T>` as the absence channel | `library/core/src/option.rs:1-20` module docs list "Return values for functions that are not defined over their entire input range (partial functions)" as a primary use |
| `Result<T, E>` as the failure channel | `library/core/src/result.rs` |
| `Result<Option<T>, E>` — the three-state shape | composition of the two; no dedicated std type |
| A dedicated not-found *error variant* | `library/std/src/io/error.rs:235-238` — `pub enum ErrorKind { /// An entity was not found, often a file. NotFound, … }`, `#[non_exhaustive]` at `:234` |
| `Option::ok_or_else` — the translation combinator | `library/core/src/option.rs:1361-1363`, `#[stable(feature = "rust1", since = "1.0.0")]` |
| `Option::transpose` — `Option<Result<T,E>>` → `Result<Option<T>,E>` | `library/core/src/option.rs:2234-2237`, `#[stable(feature = "transpose_result", since = "1.33.0")]` |
| `let … else` — the non-combinator translation idiom | stabilized in Rust **1.65.0** (2022-11-03): `RELEASES.md:4090,4096` at tag `1.96.0`, "Stabilize `let else`" (`https://github.com/rust-lang/rust/pull/93628/`) |
| `?` plus `From`/`Into` — the propagation mechanism | `library/core/src/result.rs` |
| `#[non_exhaustive]` on the error enum | `library/std/src/io/error.rs:234` |
| `std::error::Error::source` — the cause chain | required by API Guidelines C-GOOD-ERR (below) |

Two std facts about *where* absence is signalled matter to the argument and are quoted
rather than paraphrased. First, in-memory lookup returns `Option`:
`library/std/src/collections/hash/map.rs:1030` — `pub fn get<Q: ?Sized>(&self, k: &Q) -> Option<&V>`.
Second, filesystem lookup does **not**; absence arrives as an `Err` carrying
`ErrorKind::NotFound` (`library/std/src/fs.rs:1882,1884,1914`, the `OpenOptions::open`
Errors section, `* [`NotFound`]: The specified file does not exist …`). std draws that
line because the filesystem check is racy, and it says so:
`library/std/src/path.rs:3489-3493` — "Warning: this method may be error-prone, consider
using [`try_exists()`] instead! It also has a risk of introducing time-of-check to
time-of-use ([TOCTOU]) bugs", with a module-level TOCTOU section at
`library/std/src/fs.rs:3190`. `Path::exists` is literally `fs::metadata(self).is_ok()`
(`:3517-3518`). The lesson is **not** "I/O absence must be an error"; it is "never add a
separate existence probe — the one fallible operation must report absence as part of its
own answer." Both the recommended shape and its runner-up honour that; a
`fn exists(id) -> Result<bool, E>` port method violates it and is excluded below.

**Bin 2 — established industry standard (conventions practised by mainstream crates).**
Three rival conventions, all mature, all with named practitioners:

1. **`Result<Option<T>, E>` — absence in the success channel** (`sqlx::Executor::fetch_optional`; `crates_io_github::GitHubClient::team_membership`/`org_membership`).
2. **A dedicated `NotFound` variant on the error enum** (`object_store::Error::NotFound`; `jj`'s `BackendError::ObjectNotFound`; `sqlx::Error::RowNotFound`; std's `io::ErrorKind::NotFound`).
3. **A three-state enum inside the success channel** (`sccache`'s `Cache::{Hit, Miss, None, Recache}` and `GetPathResult::{Found, Miss, Unsupported}`).

The error-library layer beneath all three (`thiserror` in the library, `anyhow` at the
binary boundary) is **R67's settled choice and is assumed here, not re-surveyed**.

**Bin 3 — up-and-comer.** `snafu`'s `OptionExt` (the Option→typed-error translation as a
library trait), nightly `try` blocks and the `Try` trait, and `trait-variant`. All three
are treated under `### Up-and-comers`; none is adopted.

**Authorities used, and why each is authoritative.**

| Source | Why it counts | Retrieved |
|---|---|---|
| `rust-lang/rust` source at tag `1.96.0` (`https://raw.githubusercontent.com/rust-lang/rust/1.96.0/…`) | The normative artifact itself, read at the MSRV floor, not a description of it. Same method R67 used. | 2026-09-17 |
| The Rust Book, ch. 9.3 "To panic! or Not to panic!" (`https://raw.githubusercontent.com/rust-lang/book/main/src/ch09-03-to-panic-or-not-to-panic.md`) | The Rust project's own teaching text. Lines 97-101: "when failure is expected, it's more appropriate to return a `Result` … returning a `Result` indicates that failure is an expected possibility that the calling code must decide how to handle." | 2026-09-17 |
| Rust API Guidelines, C-GOOD-ERR (`https://raw.githubusercontent.com/rust-lang/api-guidelines/97a0969cb07fe4cabb0eed8a56234053f47d83dc/src/interoperability.md:190-230`) | The Rust project's library-design checklist; the same document R01 cited (C-OBJECT). It requires error types to implement `std::error::Error` + `Send` + `Sync`, and names `Error + Send + Sync + 'static` as "the most useful for callers" of boxed sources — which is what fixes `PortError`'s source-field type below. | 2026-09-17 |
| Rust CLI Working Group book, errors chapter (`https://raw.githubusercontent.com/rust-cli/book/master/src/tutorial/errors.md`) | The working group's published guidance for this exact target shape; R67 used its signals and exit-code chapters as authority. Opening line: "All possible error states are often encoded in the return types of functions." | 2026-09-17 |
| `py-launch-blueprint` at pin `b08bccfb`, `docs/design/0005-hexagonal-architecture-and-enforcement.md:134-159` | The owner's recorded statement of the pattern under a stable ID, **HEX-12**. This is the "hex pattern we've used before" the owner named on 2026-09-04. | 2026-09-17 |

A single blog post was not used as an authority anywhere in this report; every
convention claim is backed by source read at a recorded commit.

**Practice evidence — well-regarded Rust projects surveyed.** Figures from
`GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`)
and `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`, never `open_issues_count`), both via the authenticated `gh` binary
(`gh api`), retrieved 2026-09-17:

| Project | Stars | Archived | `pushed_at` | Open issues | Why it is a relevant, well-regarded reference |
|---|---:|---|---|---:|---|
| `rust-lang/crates.io` | 3,699 | false | 2026-09-16T20:55:39Z | 92 | The Rust project's own production web service; the *only* surveyed project with this template's exact shape (Cargo workspace, library crates + web service), and R01's primary reference for the port seam this item decorates |
| `transact-rs/sqlx` (redirect target of `launchbadge/sqlx`) | 17,501 | false | 2026-09-14T15:02:33Z | 682 | The dominant async SQL toolkit in the Rust ecosystem; the one surveyed API that ships **both** rival shapes side by side and documents when each applies |
| `jj-vcs/jj` | 31,623 | false | 2026-09-17T05:15:56Z | 813 | Highest-star project surveyed; a storage-backend trait with a shipped fake — R01's reference for the same seam |
| `mozilla/sccache` | 7,685 | false | 2026-09-16T08:47:42Z | 413 | Mozilla-maintained production build tool; R01's reference for `pub trait Storage: Send + Sync`; a cache read is the canonical "absence is normal" operation |
| `apache/arrow-rs-object-store` | 323 | false | 2026-09-15T15:15:22Z | 128 | Apache Software Foundation project (the `object_store` crate); low star count reflects a recent split from `apache/arrow-rs`, not obscurity — it is the de-facto object-storage abstraction under DataFusion, Delta and InfluxDB |

Issue-responsiveness (median days to first maintainer response over the 10 most recently
opened issues) is **`inapplicable`** for this item: none of these projects is a candidate
this template would depend on. They are read as *evidence of practice*, not shortlisted
for adoption. No crate is selected by this item at all.

### Principles and implementation

**The shared requirement, and the level at which agreement is required.** The principle
is not "use `Option`" — that is a spelling. It is: **a driven-I/O read that finds nothing
reports a normal outcome, and the decision that "nothing" is a user-facing failure
belongs to the use case, not to the adapter that performed the I/O.** Two independently
valuable consequences follow: the adapter cannot know whether a caller wants absence to
be fatal (a `delete --if-exists` and a `show <id>` disagree), and absence and transport
failure can never be confused for each other by a caller reading only the type.

*Source of the requirement.* It is recorded, under an ID, in py:
`py-launch-blueprint` at pin `b08bccfb`, `docs/design/0005-hexagonal-architecture-and-enforcement.md:134-138`
— **"HEX-12 — `None` means 'absent', exceptions mean 'broke'.** A port method returns
`None`/`[]` for *legitimate absence* (no such id, empty result) and *raises* `APIError`
for *transport failure*. The **application service**, not the adapter, decides that
absence is a user-facing error and raises the application error". Its companion HEX-13
(`:161-175`) pins the adapter's half: `def get_project(self, project_id) -> Project | None:   # None on 404, raise on 5xx`.
The code matches the document at the pin: `src/py_launch_blueprint/core/ports.py:47,49`
(`get_project(...) -> Project | None`, `resolve_workspace_gid(...) -> str | None`) and
`src/py_launch_blueprint/core/services/projects.py:56-63` (the service raises
`ProjectNotFoundError`). ts has **no** recorded decision here — `TS_PORT_DECISIONS.md`
carries no `D-0nn` for this split, and `src/lib/api.ts` at pin `cb1cbcb2` folds all three
states into one function: `:179` `workspaces.find(…)`, `:182` `if (workspace === undefined)`,
`:184` `throw new NotFoundError(…)`, inside `createApiClient().getProjects` — the same
function that issues the HTTP request.

*Agreement level.* **Architectural pattern** — specifically a *layer assignment*: which
ring converts absence into a domain error. That is the thing that must agree across py,
ts and rs. What may vary is every mechanical detail: py spells absence `None` and failure
as a raised exception because Python has no sum type in the return position; ts would
spell it `undefined` (or a discriminated union) and failure as a thrown `Error`; Rust
spells both in one return type because it has one. `docs/port/DIVERGENCE-ANALYSIS.md:58,80`
classes F012 `harmonize: no` (cause class F), and `:242` records the classifier's own
doubt about that class. The owner's 2026-09-04 direction (`docs/port/OWNER-REVIEW.md`,
quoted in `inputs/prompt.md` `## Context`) asks for one best-practice pattern across all
three. **Those are reconcilable, and this report reconciles them rather than overturning
the label**: `harmonize: no` is correct about the *mechanism* (Rust decides `Result<Option<T>, E>`
alone; nothing about it transfers to Python or TypeScript), and the owner is right about
the *layer assignment*, which is the level at which agreement is actually required and
which py already documents as HEX-12. No `BASELINE-REVIEW:` line is raised: F012 is this
item's own `DIVERGENT` research row, not a retained REUSE/ADOPT baseline being
challenged, and the one wording change worth making (below) is to the row this decision
itself settles.

*One wording correction to F012, carried in the answer body rather than as a
`BASELINE-REVIEW:` line.* The ledger row (`docs/port/COMMONALITY.md:18`, and
`docs/port/areas/workspace-architecture.md:18`) states the pattern as "`None`/empty means
absent". The two must be separated in Rust. `Ok(vec![])` from a `list` operation is a
**successful, complete answer that happens to be empty** and must never become a
not-found error; `Ok(None)` from a `get` operation is absence of an addressed thing. py
inherits the conflation from a language where `None` and `[]` are both falsy; Rust has
distinct types for the two and the pattern must use them distinctly. This is a statement
about the row this item owns and settles, not a challenge to another item's baseline.

**Essential behaviors.**

1. A read that addresses one resource by identity returns three distinguishable states in
   one value: found, absent, failed.
2. Absence travels in the success channel. It is never an `Err`, never a sentinel value,
   never a magic empty struct.
3. Transport, protocol, I/O and authorization failures travel in the error channel, in a
   port-owned error type whose variants map onto R67 catalogue rows.
4. The adapter, and only the adapter, decides which upstream signal means "absent". That
   decision is made per operation and is opt-in, never blanket.
5. The use case, and only the use case, decides that absence is a domain error, and names
   the offending input when it does.
6. A collection read returns `Ok(Vec<T>)`; an empty vector is success, not absence.
7. The port exposes no separate existence probe (`exists`/`contains`); absence is reported
   by the same fallible call that would have returned the value.
8. Forgetting step 5 is a compile error, not a runtime surprise.

**Observable acceptance criteria.** AC1–AC7 were executed in this run (see the empirical
check below); AC8–AC10 are proposals for P03.

| # | Criterion | Status |
|---|---|---|
| AC1 | A found resource returns `Ok(value)` from the use case | **executed** |
| AC2 | An absent resource produces a domain error whose code is `RSLB301` and whose exit is `3`, with a message naming the offending input | **executed** |
| AC3 | An absent resource's domain error has **no** `source()` — absence has no transport cause | **executed** |
| AC4 | A transport failure produces `RSLB102`/exit `1` and its `source()` chain still reaches the original `io::Error` after crossing `?` | **executed** |
| AC5 | A local I/O failure produces `RSLB101`/exit `1` | **executed** |
| AC6 | An empty collection read is `Ok` and empty — never a not-found error | **executed** |
| AC7 | A use case that calls the port and forgets the absence translation **fails to compile** | **executed** (`error[E0308]`) |
| AC8 | An adapter contract test proves upstream 404 on a by-identity read yields `Ok(None)`, while 404 on a collection endpoint and any 5xx yield `Err` | proposed (needs a real adapter; P03) |
| AC9 | A malformed 200 response yields `Err(PortError::RemoteApi)`, never `Ok(None)` | proposed (P03) |
| AC10 | The web handler maps the same absence to HTTP 404 with no second translation site | proposed; R70 owns the status table |

AC9 is not hypothetical. py's adapter comment at pin `b08bccfb`,
`src/py_launch_blueprint/core/adapters/py_api.py:188-195`, records the bug it was written
to close: "This is now the ONLY path that yields `None` — a 200 we cannot parse raises
below instead of sharing this channel, **which is what previously let schema drift
masquerade as 'not found'**." That is the failure mode the absence channel invites, and
Rust does not prevent it by construction — the adapter still has to be written correctly.
The same file's `_fetch(..., allow_not_found: bool = False)` at `:174` is the per-operation
opt-in that behavior 4 above requires; it is a recorded, load-bearing design detail and
the Rust design keeps it (as an explicit `match` arm per method, not a bool parameter —
C-CUSTOM-TYPE, `api-guidelines/src/type-safety.md:39`, warns against exactly that `bool`).

**Architectural alternatives compared, before any library was weighed.**

| Alt | Shape at the seam | Verdict and the principle at stake |
|---|---|---|
| A | `fn get(&self, id) -> Result<T, PortError>` with `PortError::NotFound` | **Ranked runner-up.** The fold. Honest and idiomatic — it is `object_store`, `jj`, `sqlx::fetch_one` and std's `fs`. It loses behavior 5: the adapter has already declared absence a failure, and a caller who wants "absent is fine" must match an *error* variant to recover a normal outcome. Also loses AC7 — forgetting to handle not-found compiles, and the resource silently reports as a generic error. |
| B | `fn get(&self, id) -> Option<T>` (absence only; failure panics or is swallowed) | **Rejected.** Drops the failure channel entirely. This is py's *port signature* read literally, but py's port raises for transport failure — the exception channel is Python's `Err`. In Rust it would make a network call infallible in the type system. Violates behaviors 1 and 3 and the CLI WG's "All possible error states are often encoded in the return types of functions." |
| C | `fn get(&self, id) -> Option<Result<T, PortError>>` | **Rejected.** Structurally wrong direction: you cannot know whether the resource is absent until the fallible operation has *succeeded*, so absence cannot be the outer layer. std supplies `Option::transpose` (`option.rs:2234-2237`, stable 1.33.0) precisely to convert this nesting into D's, which is the ecosystem's own statement of which nesting is canonical. This is the direct answer to the prompt's second HIGH question about "two separate return channels … composed via `Option<Result<T, E>>`". |
| **D** | **`fn get(&self, id) -> Result<Option<T>, PortError>`**, translated at the use case with `ok_or_else` | **Chosen.** Three states, one value, no information lost. Preserves every behavior; AC7 makes the translation compiler-enforced; it is the exact Rust realization of HEX-12. Practised by `rust-lang/crates.io`'s port and by `sqlx`'s primitive. |
| E | `fn get(&self, id) -> Result<Lookup<T>, PortError>` with a bespoke `enum Lookup { Found(T), Absent }` | **Rejected as the default.** Isomorphic to D but invents a type the ecosystem already has; `Option` carries dozens of combinators, `Lookup` carries none. `sccache`'s `Cache` enum (`src/cache/cache_io.rs:36-46`) is this shape and earns it, because `Cache::Hit(CacheRead)` carries a payload a bare `Option` could not name well, and because it needs four states, not two. Kept as a documented variation for any future port where absence has sub-kinds. |
| F | Add `fn exists(&self, id) -> Result<bool, PortError>` beside `get` | **Rejected outright.** Two round trips and a TOCTOU window that std warns about by name (`path.rs:3489-3493`). Whatever shape the read takes, there is exactly one call. |

**How the chosen design preserves each principle, and what it looks like.** The seam
(the exact port method set is R01's `ProjectsPort`):

```rust
pub trait ProjectsPort: Send + Sync {
    /// `Ok(None)` means the upstream authoritatively has no such project.
    /// `Err` means the lookup could not be completed.
    fn get(&self, id: &str) -> Result<Option<Project>, PortError>;
    /// An empty `Vec` is a complete answer, never an absence.
    fn list(&self, workspace: Option<&str>) -> Result<Vec<Project>, PortError>;
}
```

The port's failure vocabulary is a `thiserror`-derived, `#[non_exhaustive]` enum whose
every variant maps to exactly one R67 catalogue row, and whose cause fields are
`Box<dyn std::error::Error + Send + Sync + 'static>` so that no HTTP client type appears
in the library's public API (C-GOOD-ERR names that bound "the most useful for callers";
`object_store` uses that exact field type at `src/lib.rs:2258,2267`, and `jj` at
`core/src/backend.rs:330`):

| `PortError` variant | R67 catalogue row | Exit |
|---|---|---|
| `Io { source: std::io::Error }` | `RSLB101` I/O | 1 |
| `Transport { source: Box<dyn Error + Send + Sync> }` (DNS, connect, timeout, TLS) | `RSLB102` transport | 1 |
| `RemoteApi { source: … }` (non-2xx that is not 404/401/403/409; unparsable 200) | `RSLB103` remote-API failure | 1 |
| `Unauthorized { source: … }` (401/403) | `RSLB402` credentials rejected | 4 |
| `Conflict { source: … }` (409, failed precondition) | `RSLB501` conflict | 5 |
| `Unavailable { detail: String }` (R01's poisoned-`Mutex` case) | `RSLB101` I/O | 1 |

`Unavailable` deserves its one sentence: R01 names `PortError::Unavailable` as where a
poisoned `std::sync::Mutex` in `InMemoryProjectsPort` goes, "never a panic". It is
expressible under R67 two ways — `RSLB000` unexpected or `RSLB101` I/O, both exit `1`, so
the user-visible outcome is identical either way. **`RSLB101` is the pick**, because
`RSLB000` is R67's *sentinel for the unexpected class*, and R67 routes that class to the
crash-record sink; a poisoned in-memory fake is a diagnosed, named adapter state, not an
unexpected one, and it should not feed a crash record. **No `CONFLICT:` line is needed:**
every failure this pattern can produce lands on an existing R67 row.

The use case is the single translation site, and the whole translation is one expression:

```rust
impl<P: ProjectsPort> ProjectsService<P> {
    pub fn get_project(&self, id: &str) -> Result<Project, DomainError> {
        self.port.get(id)?                                        // transport failure -> Err, via From
            .ok_or_else(|| DomainError::NotFound { kind: "project", id: id.to_owned() })
    }
}
```

`DomainError` wraps rather than flattens — `#[error(transparent)] Port(#[from] PortError)`
beside `NotFound { kind, id }`. **Wrapping is the pick over flattening** (copying
`PortError`'s variants into `DomainError`) for three reasons: `#[from]` is what makes the
first `?` above a one-token conversion; `source()` still reaches the original
`io::Error`, which C-GOOD-ERR's whole rationale rests on and which the empirical check
verifies; and the library keeps one place to change when R01's port grows a method. The
cost is one extra hop in the chain, which R67's envelope does not render anyway (its
`{"error":{"code","message","hint"?}}` has no cause array).

*Answering the prompt's MEDIUM ergonomics question directly.* No, the split costs nothing
against py's two-step — it *is* py's two-step, with the compiler checking it. The
translation is `?` followed by `.ok_or_else(…)`: two operators on one expression, versus
py's `x = repo.get(...)` / `if x is None: raise`. Where a guard clause reads better,
`let … else` (stable since 1.65.0) gives the imperative form with no combinator:
`let Some(p) = self.port.get(id)? else { return Err(DomainError::NotFound { … }); };`.
The conversion stays explicit at the boundary because `Option` has no `From` into a
domain error and cannot acquire one — `?` on an `Option` in a `Result`-returning function
does not compile. That is the property that makes AC7 work, and it is the standard,
testable idiom the question asks for.

*Answering the prompt's MEDIUM R67-coupling question directly.* The absence variant does
**not** need a new stable catalogue member decided now. R67 already ships `RSLB301`
resource not found → exit 3, and R67 requires the `message` to name the offending input
(R7.6, "`error: project 'demo' not found`"). One row therefore covers every resource
kind, with the kind carried in `DomainError::NotFound { kind, id }` and rendered into the
message. py has two not-found codes (`PLBP005` project, `PLBP006` workspace,
`src/py_launch_blueprint/core/errors.py:56-57` at the pin), so machine-distinguishable
codes per resource are a reasonable thing for the owner to want later — and R67's catalogue
is explicitly append-only over a `#[non_exhaustive]` enum, so adding `RSLB302` is a
non-breaking append R67 permits. This item recommends **not** taking it now: a second row
is dead weight until a caller actually branches on resource kind, and the `kind` field
carries the distinction inside the process for free.

**Cross-repo adjudication** (changes to py and ts are a follow-on project; this supplies
the rationale). **py: no change** — HEX-12 already is the principle, correctly layered,
with an ADR-grade written statement and a per-operation `allow_not_found` opt-in. The one
suggestion is wording: HEX-12's "`None`/`[]`" should separate "no such id" from "empty
result", for the reason given above; py's code already treats them separately
(`list_projects` returns `list[Project]`, never `None`). **ts: accidental drift, not a
justified ecosystem difference.** There is no `D-0nn` recording the fold as a decision —
`docs/port/DIVERGENCE-ANALYSIS.md:80` says "no recorded reason (ts-decisions: —)" — and
nothing in TypeScript prevents the split: `getWorkspaces().find(…)` already produces
`undefined`, so the client would simply return it. Proposed follow-on: `createApiClient`'s
`getProjects` returns the resolved workspace or `undefined` (or splits into
`resolveWorkspace(name): Promise<Workspace | undefined>`), and the `NotFoundError` throw
at `src/lib/api.ts:184` moves to the router/service layer that owns the use case. This is
the same finding shape R01 reached for F013 (a per-test fake that should be an exported
factory): a capability ts has the materials for but never assigned to a layer.

**Empirical check — executed.** A throwaway crate was built under a `$TMPDIR`
subdirectory, run, and deleted. Toolchain: `rustc` **1.98.0** (`88d9e12ae`, 2026-08-18,
Homebrew) and `cargo` **1.98.0** on macOS **26.4**, `arm64`. Manifest: `edition = "2024"`,
`rust-version = "1.96"`, one dependency, `thiserror = "2"`, which resolved offline to
**2.0.20** (with `syn` 3.0.6, `quote`, `proc-macro2`); `cargo build` + `cargo test` from
clean took **11.20 s** wall on that machine, reported by `cargo` itself. The crate
contained the `PortError`/`DomainError`/`ErrorCode`/`Exit` shapes above, R01's
`ProjectsPort` with the blanket `impl … for Arc<T>`, a `ProjectsService<P: ProjectsPort>`
erased to `Arc<dyn ProjectsPort>`, and a programmable fake.

`cargo test` (binary: `cargo` 1.98.0) reported **8 passed, 0 failed**:
`present_is_ok`, `absence_becomes_not_found_rslb301_exit3`,
`transport_failure_becomes_rslb102_exit1_and_keeps_its_cause`, `io_failure_is_rslb101_exit1`,
`poisoned_fake_state_is_a_failure_not_an_absence`, `empty_list_is_not_absence`,
`transpose_converts_the_other_nesting`, `every_catalog_member_has_a_code_and_an_exit`.
Verified inside them: the absence error's `Display` is `project 'demo' not found` and its
`source()` is `None`; the transport error's chain is exactly
`["transport failed", "connect timed out"]` after crossing `?`, i.e. `#[from]` +
`#[error(transparent)]` preserve the cause; `Option::transpose` converts alternative C's
nesting into D's.

A ninth, deliberately broken test file proved AC7. A use case written
`Ok(port.get(id)?)` — the `ok_or_else` omitted — fails to compile with, verbatim from
`cargo`:

```
error[E0308]: `?` operator has incompatible types
 --> tests/forgot_translation.rs:3:8
  | ^^^^^^^^^^^^^ expected `Project`, found `Option<Project>`
```

That is the concrete advantage of D over A, observed rather than argued: under A the same
omission compiles and ships. **Caveats on what this proves:** it exercises the shapes, the
code/exit mapping and the cause chain against a *fake* port. It does not exercise a real
HTTP adapter, a 404 discrimination, an async port, the web surface, or R67's envelope
writer — AC8, AC9 and AC10 remain proposals for P03. The `ErrorCode`/`Exit` types in the
probe are minimal stand-ins for R67's, sufficient to prove routing and nothing more.

**Performance.** No benchmark is offered and none would be honest. The pattern's entire
runtime cost is one `Option` discriminant test and one enum construction on a code path
that has just completed a network or filesystem round trip; for the types std enumerates —
`&U`, `Box<U>`, `NonNull<U>`, `num::NonZero*`, `fn` — "Rust guarantees to optimize the
following types `T` such that `Option<T>` has the same size, alignment, and function call
ABI as `T`" (`library/core/src/option.rs:119-156` at tag `1.96.0`, the null-pointer
optimization). Whether the template's own `Project` struct qualifies is an implementation
detail nothing here depends on. Any measurement at this granularity would be measuring the
allocator. Compile-time and binary-size cost:
zero beyond R67's already-selected `thiserror`, since the pattern adds no dependency.

### Dominant choice

**Counted across the surveyed field, the dominant shape is *not* the one this report
recommends.** Reported honestly, because the survey says so: a **dedicated `NotFound`
variant on the error enum** (alternative A, the fold) is what most Rust I/O abstractions
expose — `std::io::ErrorKind::NotFound` (`library/std/src/io/error.rs:236-238`),
`object_store::Error::NotFound { path, source }` (`src/lib.rs:2261-2268`),
`jj`'s `BackendError::ObjectNotFound { object_type, hash, source }`
(`core/src/backend.rs:321-331`), and `sqlx::Error::RowNotFound` (`sqlx-core/src/error.rs:62-64`).
Four of five surveyed projects expose it. If "dominant" means "most frequently seen at a
crate's public surface", A wins.

Two qualifications change what that count means, and both come from the same sources.

First, **where a Rust API is shaped as a *port with a substitutable implementation* and
the caller is expected to choose what absence means, the split shape is what appears.**
`rust-lang/crates.io` — the Rust project's own service, and R01's primary reference for
this exact seam — declares `#[cfg_attr(feature = "mock", mockall::automock)] #[async_trait] pub trait GitHubClient: Send + Sync`
at `crates/crates_io_github/src/lib.rs:74-76` and mixes the two shapes **deliberately,
per operation**: `get_user`, `org_by_name` and `team_by_name` return `Result<T>` (`:78-86`),
while `team_membership` and `org_membership` return `Result<Option<GitHubTeamMembership>>`
and `Result<Option<GitHubOrgMembership>>` (`:87-99`). The adapter is where the 404 is
interpreted, and only for those two methods (`:279-307`):

```rust
match self.request(&url, auth).await {
    Ok(membership) => Ok(Some(membership)),
    // Officially how `false` is returned
    Err(GitHubError::NotFound(_)) => Ok(None),
    Err(err) => Err(err),
}
```

The internal `GitHubError` is a `thiserror` enum with a typed `NotFound(anyhow::Error)`
built from the status code (`:396-418`: `Some(Status::NOT_FOUND) => Self::NotFound(error.into())`),
and it is *not* the port's public vocabulary for these methods — it is the raw material
the adapter converts. That is behavior 4 of this pattern, in production, in the Rust
project's own codebase.

Second, **`sqlx` ships both and makes the precedence explicit in code.** `fetch_optional`
is the *required* trait method with no default body (`sqlx-core/src/executor.rs:153-160`:
`fn fetch_optional<'e, 'q: 'e, E>(self, query: E) -> BoxFuture<'e, Result<Option<Row>, Error>>;`),
and `fetch_one` is a *provided* method **derived from it** (`:134-151`):

```rust
self.fetch_optional(query)
    .and_then(|row| future::ready(match row {
        Some(row) => Ok(row),
        None => Err(Error::RowNotFound),
    }))
```

The three-state form is the primitive; the fold is a convenience layered on top, exactly
the relationship this report recommends between the port and the use case. A driver author
implements only the split shape.

`sccache` is the third data point and shows the cost of leaving the translation to a
catch-all. `Storage::get` returns `Result<Cache>` (`src/cache/cache.rs:83`) where
`pub enum Cache { Hit(CacheRead), Miss, None, Recache }` (`src/cache/cache_io.rs:36-46`);
the trait's own contract is at `src/cache/cache.rs:77-83` — "If nothing fails but the
entry is not found in the cache, it should return a `Cache::Miss`". So sccache **has**
both channels: a live `Err` and an `Ok`-channel `Miss`. Its remote adapter translates the
upstream not-found correctly at `:270` — `Err(e) if e.kind() == opendal::ErrorKind::NotFound => Ok((Cache::Miss, None))`
— and then, at `:271-274`, folds *every other* transport error into a miss too, with only
a `warn!`, discarding the error channel it was given. (The same doc comment at `:78` tells
implementors to "return a `Cache::Error`"; the enum at `cache_io.rs:36-46` has no such
variant, which is stale documentation, not a fourth shape.) For a build cache that
degradation is deliberate; for this template it is precisely the confusion the pattern
exists to prevent, and it is why rule 3 below fixes the translation per operation instead
of in a catch-all arm.

### Options

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **D — `Result<Option<T>, E>` at the seam; use case translates with `ok_or_else`/`let … else`** | `core::option` module docs, "partial functions" (`library/core/src/option.rs:1-20`, tag `1.96.0`); `Option::ok_or_else` `option.rs:1361-1363`; HEX-12 (`py … docs/design/0005-…md:134-138`, pin `b08bccfb`) | `rust-lang/crates.io` `GitHubClient::team_membership`/`org_membership` (`crates/crates_io_github/src/lib.rs:87-99,279-307`); `sqlx::Executor::fetch_optional` (`sqlx-core/src/executor.rs:153-160`) | crates.io source at commit `3a31e6c8`, `pushed_at` 2026-09-16 |
| **A — dedicated `NotFound` variant on the port's error enum** | Rust API Guidelines C-GOOD-ERR (`api-guidelines/src/interoperability.md:190-230`); `std::io::ErrorKind::NotFound` (`library/std/src/io/error.rs:236-238`) | `object_store::Error::NotFound` (`src/lib.rs:2261-2268`); `jj` `BackendError::ObjectNotFound` (`core/src/backend.rs:321-331`); `sqlx::Error::RowNotFound` (`sqlx-core/src/error.rs:62-64`); ts `src/lib/api.ts:184` at pin `cb1cbcb2` | jj source at commit `e6dd2c0d`, `pushed_at` 2026-09-17 |
| **E — bespoke three-state enum in the success channel** | `sccache` `Storage::get` docs (`src/cache/cache.rs:77-83`) | `mozilla/sccache` `Cache::{Hit, Miss, None, Recache}` (`src/cache/cache_io.rs:36-46`, used at `src/cache/cache.rs:270,273`) and `GetPathResult::{Found, Miss, Unsupported}` (`src/cache/cache.rs:62-71`) | sccache source at commit `0f9467c4`, `pushed_at` 2026-09-16 |
| **C — `Option<Result<T, E>>`** | `Option::transpose` (`library/core/src/option.rs:2234-2237`, stable since 1.33.0) — std supplies the conversion *out* of this nesting | none found in the surveyed field | std at tag `1.96.0` |
| **B — bare `Option<T>`, failure elsewhere** | `HashMap::get` (`library/std/src/collections/hash/map.rs:1030`) — correct for infallible in-memory lookup only | std collections; no I/O-backed adopter found | std at tag `1.96.0` |
| **F — separate `exists()` probe beside `get()`** | Documented as an **anti-pattern**: `Path::exists` warning (`library/std/src/path.rs:3489-3493`), `fs` TOCTOU section (`library/std/src/fs.rs:3190`) | none (std offers `try_exists` only as a convenience and warns against relying on it) | std at tag `1.96.0` |

### Excluded by gate

**No candidate is excluded by a fitness gate.** This item selects a language-level pattern
and adds **no crate to the dependency tree** — the only error crates in the picture,
`thiserror` in the library and `anyhow` (`>= 1.0.103`) in binary crates, are R67's
settled choices, assumed here and not re-evaluated. The six gates are recorded rather
than omitted, per the prompt's instruction to state `inapplicable` with a reason:

| Gate | Verdict |
|---|---|
| 1. Licence compatible with `MIT OR Apache-2.0` | **`inapplicable — owner ruling 2026-09-12 (Q7.B)`** (`docs/port/OWNER-REVIEW.md`; "no licence check for anything the template uses", superseding and widening Q4). Nothing in this report is admitted, ranked, preferred or excluded on a licence. Declared licences of the *surveyed reference projects* are not reported at all, since they are evidence of practice, not candidates. |
| 2. MSRV within `stable minus 2 minor versions …` | `inapplicable` — no crate. For the record, every language feature the pattern uses predates the 1.96 floor by a wide margin: `Option`/`Result`/`?`/`ok_or_else` since 1.0.0; `Option::transpose` since **1.33.0**; `let … else` since **1.65.0**. Verified against `rust-lang/rust` at tag `1.96.0` (`library/core/src/option.rs:1361-1363,2234-2237`; `RELEASES.md:4090,4096`). `#[non_exhaustive]` long predates the floor — std itself applies it to `io::ErrorKind` at `library/std/src/io/error.rs:234` at that tag — but its stabilization release was **not** located in `RELEASES.md` and no version is claimed here. |
| 3. No open RustSec advisory; `unsafe` posture | `inapplicable` — no crate to query at `https://rustsec.org/packages/<name>.html`. `unsafe` posture of the pattern: **none**; every construct is safe stable Rust and the probe crate compiled with no `unsafe` block. |
| 4. Builds/tested on `ubuntu-latest, macos-latest` | `inapplicable` as a crate-CI question. Substantively satisfied: the constructs are core-language and platform-independent; the empirical check compiled and ran on macOS 26.4 `arm64` with `rustc` 1.98.0. Linux was **not** exercised in this run — recorded as unverified. Windows: the pattern is platform-neutral and would work there; not required. |
| 5. Default features and async-runtime coupling | `inapplicable` — no crate, no features. Async coupling: **none of its own.** Under an async R05 the signature becomes `async fn get(&self, id: &str) -> Result<Option<Project>, PortError>` behind R01's `#[async_trait]`; `Result<Option<T>, E>` is runtime-agnostic and `?`/`ok_or_else` work identically inside an `async fn`. |
| 6. Binary-size and compile-time cost | `inapplicable` as a crate metric. Qualitatively **zero added cost**: no dependency, no generated code, no monomorphization beyond what R01's `ProjectsService<P>` already produces. The 11.20 s clean build measured in the probe is `thiserror`'s proc-macro tree, which R67 already pays for. |

One thing *is* excluded, by a **constraint** rather than a gate, and is named here so it
is not silently dropped: **nightly `try` blocks** (`#![feature(try_blocks)]`) and any
hand-implementation of the unstable `Try` trait, which would let a `?` chain scope its
`Option`/`Result` interaction more tightly. Excluded by `## Constraints`, "Stable Rust
only". Same disposition R67 gave `-Zon-broken-pipe`.

### Up-and-comers

- **`snafu`'s `OptionExt`** — the Option→typed-error translation packaged as a library
  trait: "Convert an `Option` into a `Result` with additional context-sensitive
  information", with a doc example whose error variant is `UserLookup { user_id: i32 }`
  (`https://raw.githubusercontent.com/shepmaster/snafu/d6b22be7e31fdd308bfe637349263781edcaac29/src/lib.rs:953-975`,
  retrieved 2026-09-17) — literally this pattern's translation step with the offending
  input attached. Figures from `GET https://crates.io/api/v1/crates/snafu` (retrieved
  2026-09-17, `User-Agent` set): `crate.recent_downloads` **17,267,147**,
  `crate.downloads` **109,672,444**, `max_stable_version` **0.9.2**, `updated_at`
  2026-07-21T17:52:51Z, repository `https://github.com/shepmaster/snafu`. **Noted, not
  adopted:** R67 selected `thiserror` as the library's error-derive crate, and
  `ok_or_else` needs no crate. It is the right escape hatch if the translation ever grows
  a lot of contextual fields.
- **Nightly `try` blocks / the `Try` trait** — would let a fallible sub-expression be
  scoped without a helper function. Watch; excluded by the stable-Rust constraint today.
- **`trait-variant` 0.1.3** — relevant only via R01 (async port shape) and, as R01 already
  recorded, it has no `dyn` support shipped. No bearing on the absence contract; listed
  so the async interaction is not read as unexamined.
- **Rust's own direction of travel** is worth one line: nothing in the language is moving
  away from `Option`. `Option::transpose` gained `const` stability in 1.83.0
  (`library/core/src/option.rs:2236`) and `ok_or_else`'s `const`-ness is still tracked
  unstable (`:1362`, `issue = "143956"`), which is a refinement of this pattern's
  ergonomics, not a replacement for it.

### Fit for this template

**CLI.** Best fit of the three, and the one where the split visibly earns its keep. A
user typing `rslbp show demo` supplies the identity, so "no such project" is an ordinary,
expected answer, not a system fault — precisely the Rust Book's "failure is an expected
possibility that the calling code must decide how to handle"
(`ch09-03-to-panic-or-not-to-panic.md:97-101`). The use case converts it to
`DomainError::NotFound { kind: "project", id }` → `RSLB301` → exit **3**, and R67's R7.6
requirement that the message name the offending input is satisfied by the `id` field:
`error[RSLB301]: project 'demo' not found`. The CLI also has commands where absence is
*not* an error — a `--if-exists` delete, an idempotent `ensure`, a `--quiet` existence
check that should exit 0 — and under the fold those commands would have to recover a
normal outcome by matching an error variant. Under D they match `Ok(None)`.

**Library.** The decisive case, and the reason not to follow the ecosystem's dominant
shape. A downstream crate depending on `rs-launch-blueprint` gets a port whose type says
what actually happened, and gets to make its own layer assignment: it can call
`ProjectsPort::get` and handle `Ok(None)` itself, or call `ProjectsService::get_project`
and receive the template's opinion as `DomainError::NotFound`. Both are public, and the
second is built from the first in two tokens — the `sqlx` relationship
(`fetch_optional` required, `fetch_one` derived, `sqlx-core/src/executor.rs:134-160`). The
fold offers only the opinion. This also satisfies C-GOOD-ERR without argument:
`PortError` and `DomainError` implement `std::error::Error` via `thiserror`, are `Send`
and `Sync` (required anyway by R01's `pub trait ProjectsPort: Send + Sync`), and box their
causes as `dyn Error + Send + Sync + 'static`.

**Web service.** Fits, and removes a translation site rather than adding one. R01 fixed
the web layer as a thin adapter over the same `ErasedProjectsService` the CLI uses (F018),
so the handler calls `get_project` and maps `DomainError::NotFound` → HTTP **404** — one
arm in the status table **R70 owns**, fed by the same `ErrorCode` R67 defines. The
alternative — a handler that calls `ProjectsPort::get` directly and returns
`Json<Option<Project>>`, which R01 explicitly contemplates — also works and maps `None` →
404 without constructing a domain error at all. Both are available precisely *because*
absence rides the success channel; under the fold the handler must downcast an error to
discover that nothing went wrong. Note the asymmetry the split preserves and the fold
loses: `RSLB301` → exit 3 for the CLI and → 404 for the web surface are the same domain
fact rendered twice, whereas `RSLB102` (transport) is 500 on the web and exit 1 on the
CLI. Keeping absence typed separately from transport failure all the way to the boundary
is what lets R70 write that table by exhaustive `match` instead of string comparison —
the same property R67's alternative A3 was chosen to protect.

### Recommendation

Adopt the pattern, named **"absent is a value, broken is an error, the use case decides"**
— the Rust realization of py's **HEX-12**. Six binding rules:

1. **Seam signature.** A driven-I/O read addressing one resource by identity returns
   `Result<Option<T>, PortError>`. A read returning a collection returns
   `Result<Vec<T>, PortError>`; an empty vector is success. No port method returns bare
   `Option<T>`, bare `T`, or `Option<Result<T, E>>`, and no port exposes an `exists`
   probe. This holds whether R01's boundary is a trait method, a generic bound or an
   injected closure — the rule is about the return type, not the binding mechanism.
2. **`PortError` is transport vocabulary only.** A `thiserror`-derived, `#[non_exhaustive]`
   enum with the six variants and R67 mappings tabulated above; causes boxed as
   `Box<dyn std::error::Error + Send + Sync + 'static>` so no HTTP client type reaches the
   public API. `PortError` has **no** `NotFound` variant — that is the whole point.
3. **The adapter owns the absence rule, per operation, explicitly.** `GET /projects/{id}`
   → 404 → `Ok(None)`. A 404 from a *collection* endpoint, a 404 from a misconfigured base
   URL, any 5xx, any unparsable 200, and any timeout → `Err`. The rule is written as an
   explicit `match` arm in each method that has one, never as a shared `bool` parameter
   (C-CUSTOM-TYPE) and never as a blanket "404 anywhere means absent". This is
   `rust-lang/crates.io`'s shape at `crates/crates_io_github/src/lib.rs:279-307`.
4. **The use case is the only translation site.**
   `self.port.get(id)?.ok_or_else(|| DomainError::NotFound { kind, id: id.to_owned() })`,
   or the `let … else` form. No adapter constructs a `DomainError`; no front end
   constructs one from a port result.
5. **`DomainError` wraps `PortError`** via `#[error(transparent)] Port(#[from] PortError)`,
   preserving the `source()` chain, and exposes `code() -> ErrorCode` / the exit mapping
   R67 defines. `DomainError::NotFound` maps to the existing `RSLB301` → exit 3; **no new
   catalogue row is requested**, and the resource kind lives in the variant's `kind` field
   rather than in a second code.
6. **The prohibition is testable and tested.** A doc test or an integration test proves
   that omitting rule 4 fails to compile (`error[E0308]`), and the R01 contract suite
   `assert_projects_port_contract` gains the three absence/failure assertions so every
   adapter — real and fake — is held to rules 1 and 3.

### Ranked runner-up

**Alternative A — a dedicated `PortError::NotFound { … }` variant, translation folded into
the port.** It is the ecosystem's more common shape, it is what `jj`, `object_store`,
`sqlx::fetch_one` and std's `fs` do, and it is what ts already does at
`src/lib/api.ts:184`. It is a defensible template and nobody reading it would think it
wrong.

**The condition under which it wins.** When the caller could not have invented the
identity it is looking up — a content hash, an internal surrogate key, a handle the system
itself issued — absence genuinely *is* corruption rather than a normal answer, and there
is no legitimate caller who wants to proceed on `None`. `jj` is the clean example:
`BackendError::ObjectNotFound { object_type, hash, source }` (`core/src/backend.rs:321-331`)
describes a repository whose store lost an object it references, which is never a routine
outcome. If `rs-launch-blueprint`'s example domain were reshaped so that every port read
took an internally issued handle rather than a user-supplied project id or workspace name,
A would become the better fit. It also wins for **mutations**: `delete(id)`, `update(id, …)`
and similar have no useful `Ok(None)` — "there was nothing to update" is an error or a
no-op decided by the operation's own contract, and those methods should return
`Result<(), PortError>` with a not-found variant or an explicit outcome enum rather than
being forced into shape D. Rule 1 above is scoped to *reads* for exactly this reason.

A secondary runner-up, ranked below A: **alternative E**, the bespoke
`Result<Lookup<T>, PortError>` enum. It wins if absence ever acquires sub-kinds the
template must distinguish (`Absent` versus `Redacted` versus `Expired`), which is
`sccache`'s situation. Migrating D→E is mechanical; migrating A→D is not.

### Tradeoffs

**What the pick gives up versus A (the fold).**

- *Conformity.* Four of five surveyed projects expose a not-found error variant. A reviewer
  arriving from `object_store` or std's `fs` will find `Result<Option<T>, E>` slightly
  unfamiliar at the seam, and the template must document why. Accepted because the
  template's purpose is to demonstrate a layered architecture, and the layer assignment is
  the thing being demonstrated; the two most architecturally similar references —
  `rust-lang/crates.io`'s port and `sqlx`'s primitive — both use the split.
- *One extra token at every happy-path call site.* `?` plus `.ok_or_else(…)` instead of a
  bare `?`. Accepted: that token *is* the layer assignment, made visible and
  compiler-enforced (AC7), and py pays the identical cost with `if x is None: raise`.
- *Type-signature noise.* `Result<Option<Project>, PortError>` is a mouthful and reads
  worse in rustdoc than `Result<Project, PortError>`. Accepted; a `pub type Found<T> = Result<Option<T>, PortError>;`
  alias is available if P03 finds it grating, though the explicit form is more honest in
  generated docs.
- *No free error message.* A's `NotFound` variant carries a `Display` impl for free; D's
  absence has no message until the use case builds one. Accepted — that is the same fact
  as rule 4, and it is what forces the message to name the offending input (R67 R7.6).

**What the pick gives up versus E (the bespoke success-channel enum).**

- *Nameability.* `Cache::Hit(CacheRead)` / `Cache::Miss` documents itself; `Some`/`None`
  needs the doc comment to say what absence means. Accepted: `Option` brings dozens of std
  combinators, `transpose`, `?`-interop and universal reader familiarity, and the doc
  comment is one line per method.

**What the pick gives up versus B and C.** Nothing; both are strictly worse (B deletes the
failure channel; C is the wrong nesting and std ships `transpose` to escape it).

**One thing the pick does *not* buy, and should not be credited with.** It does not prevent
an adapter from mislabelling a failure as an absence. py's own adapter comment at
`src/py_launch_blueprint/core/adapters/py_api.py:188-195` (pin `b08bccfb`) records exactly
that regression — "what previously let schema drift masquerade as 'not found'" — and Rust's
type system is silent about it, because `Ok(None)` is well-typed whatever caused it. Only
AC8 and AC9 (adapter contract tests) catch it, which is why they are listed as mandatory
P03 work rather than optional.

### Parameters

**Owns:** none. R03 owns no row in `docs/port/PARAMETERS.md`; the `owns` field of this
item's `## Couplings` block is empty. It settles ledger row **F012** only.

**Assumes (consumed, unchanged, quoted from `docs/port/PARAMETERS.md`, read 2026-09-17):**

- `assumes error-taxonomy-exit-codes = error-contract/v1` (R67, owner-accepted). Used
  unmodified. The specific clauses this pattern depends on: `RSLB301` resource not found →
  exit `3`; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103`
  remote-API failure → 1; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition
  failed → 5; `RSLB000` unexpected → 1 as the sentinel that feeds the crash record; the
  append-only `#[non_exhaustive] ErrorCode` enum with `const fn as_str` and `pub const ALL`;
  and **Layering** — `thiserror` in the library crate, `anyhow` in binary crates only, the
  library crate depending on neither `anyhow` nor any process-stream writer. Every failure
  this pattern can produce maps onto an existing row; **no new catalogue row is requested
  and no existing row needs to change.**
- `assumes http-transport-injection-seam = trait-object port erased at the composition root …`
  (R01, owner-accepted, revision 3). Used as the binding shape: `pub trait ProjectsPort: Send + Sync`,
  the blanket `impl … for Arc<T>`, `ProjectsService<P: ProjectsPort>`, the
  `Arc<dyn ProjectsPort>` erasure at `production_service`, and `InMemoryProjectsPort` as the
  shipped fake. R01's `src/core/ports.rs` migration line already reserves this item's slot:
  "the port error type (vocabulary R67's, **absence shape R03's**)". Nothing in this pattern
  requires that shape, however — rule 1 is a statement about return types and applies
  identically to a generic bound or an injected closure, which is what the prompt's
  `## Couplings` note requires.
- `assumes rust-edition = 2024`, `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`,
  `assumes license = MIT OR Apache-2.0`, `assumes target-os-matrix = ubuntu-latest, macos-latest`
  (all `fixed`, owner-decided 2026-09-02). Satisfied: every construct is stable-Rust core
  language far below the 1.96 floor, the pattern adds no crate whose licence could matter,
  and it is platform-neutral.
- Related but **not** consumed: R05 (`sync-async-execution-model`) and R69/R70 (web surface
  and its problem envelope). The pattern is unchanged under either sync or async, and R70's
  domain-error→HTTP-status table consumes this item's output rather than constraining it.

**`CONFLICT:` lines: none.** No consumed parameter needs to change for this recommendation
to hold.

### Migration implications

File-level changes in the template, against R01's layout (the core crate's name and
workspace placement are R02's, and the file paths follow R01's `## Migration implications`
verbatim so the two decisions compose):

- **`src/core/ports.rs`** (R01 creates it; this item fills two of its slots) — add
  `pub enum PortError` (the `thiserror`-derived, `#[non_exhaustive]` six-variant enum with
  boxed `source` fields and a `pub const fn code(&self) -> ErrorCode`), and fix every
  `ProjectsPort` method's return type: `fn get(&self, id: &str) -> Result<Option<Project>, PortError>`,
  `fn list(&self, workspace: Option<&str>) -> Result<Vec<Project>, PortError>`. Each method
  carries a doc comment stating what `Ok(None)` means for that method, because that sentence
  is the contract the adapters are tested against. The blanket `impl … for Arc<T>` forwards
  unchanged. Under an async R05, `#[async_trait]` wraps it with no other change.
- **`src/core/errors.rs`** (new, or wherever R67's catalogue lands) — `pub enum DomainError`
  with `NotFound { kind: &'static str, id: String }` and
  `#[error(transparent)] Port(#[from] PortError)`, plus `const fn code(&self) -> ErrorCode`
  routing `NotFound` to `ErrorCode::NotFound` (`RSLB301`) and delegating otherwise. R67 owns
  `ErrorCode` and `Exit` themselves; this file adds only the domain enum and its mapping.
- **`src/core/adapters/http.rs`** (R01 creates it) — the 404 discrimination lives here, one
  explicit `match` arm per by-identity method, following
  `crates_io_github`'s `Err(GitHubError::NotFound(_)) => Ok(None)` shape. An internal,
  private status-to-variant conversion (`impl From<reqwest::Error> for PortError`-style)
  keeps the HTTP crate out of the public type. Nothing here constructs a `DomainError`.
- **`src/core/adapters/in_memory.rs`** (R01 creates it) — `get` returns `Ok(None)` for a
  missing id and `Ok(Some(..))` otherwise; a poisoned `Mutex` returns
  `Err(PortError::Unavailable { .. })`, never a panic and never `Ok(None)`.
- **`src/core/service.rs`** (R01 creates it) — `get_project` gains the one-expression
  translation; `list_projects` propagates with a bare `?`. This is the only file in the
  crate that names `DomainError::NotFound`.
- **`src/core/testing.rs`** (R01 creates it, exporting `assert_projects_port_contract`) —
  the shared contract function gains three assertions every adapter must satisfy: a known-
  present id yields `Ok(Some(_))`; a known-absent id yields `Ok(None)`; an adapter put into
  its failure mode yields `Err(_)` and never `Ok(None)`.
- **`tests/projects_port_contract.rs`** (R01 creates it) — no new file; the added assertions
  ride the existing per-adapter tests.
- **`tests/absence_vs_failure.rs`** (new) — the service-level tests: absence → `RSLB301`/exit 3
  with the id in the message and no `source()`; transport failure → `RSLB102`/exit 1 with the
  cause chain intact; empty list is `Ok` and empty.
- **`src/core/ports.rs` doc test** (new, inside the port's rustdoc) — a `compile_fail`
  doctest holding the `Ok(port.get(id)?)` mistake, so AC7 is a permanent regression guard
  rather than a one-off observation. This is the same device R01 uses for E0046/E0038.
- **`src/lib.rs`** (R01 changes it) — re-export `PortError` and `DomainError` alongside the
  port; the public-surface policy is R04's.
- **Web handler** (R69/R70, once the web surface exists) — one arm mapping
  `DomainError::NotFound` → 404. No change requested to R70's table beyond it consuming
  `ErrorCode::NotFound`.
- **Documentation** — one paragraph in the template's architecture doc stating the rule, so
  a template user does not "helpfully" add a `NotFound` variant to `PortError`. py's
  equivalent is HEX-12 in `docs/design/0005-…md`; this is the rs analogue and the artifact
  that keeps the three repos agreeing at the layer-assignment level.

### Validation strategy

**Executed in this run** (throwaway crate under a `$TMPDIR` subdirectory, created and
deleted; `rustc` 1.98.0 / `cargo` 1.98.0, macOS 26.4 `arm64`, `edition = "2024"`,
`rust-version = "1.96"`, one dependency `thiserror` resolving offline to 2.0.20):

```
cargo test --offline
# -> running 8 tests ... test result: ok. 8 passed; 0 failed; 0 ignored
```

covering AC1–AC6 and the `transpose` direction, plus:

```
cargo test --offline --test forgot_translation     # deliberately broken file
# -> error[E0308]: `?` operator has incompatible types
#       expected `Project`, found `Option<Project>`
```

covering AC7. The cause-chain assertion inside the transport test is the load-bearing one
and is quoted here because a summary would hide it: after crossing `?` through
`#[from] PortError`, walking `std::error::Error::source` yields exactly
`["transport failed", "connect timed out"]` — so `#[error(transparent)]` plus `#[source]`
preserve the chain C-GOOD-ERR exists to protect.

**Planned for P03** (proposed, not run here; each states its expected behavior):

1. `cargo test -p <core> --test projects_port_contract` — expected: one `ok` line per
   adapter, each naming `assert_projects_port_contract`, with the three absence/failure
   assertions inside. Proves rules 1 and 3 hold for *every* adapter, real and fake, which is
   the only mechanism that catches an adapter mislabelling a failure as an absence.
2. `cargo test -p <core> --test http_adapter_absence` against a local stub server
   (`wiremock`/`mockito`-class; the crate is R48's to choose) — expected: `GET /projects/{id}`
   answering 404 → `Ok(None)`; `GET /projects` answering 404 → `Err(PortError::RemoteApi)`;
   a 200 whose body does not deserialize → `Err(PortError::RemoteApi)`, **never** `Ok(None)`;
   a connect timeout → `Err(PortError::Transport)`. This is AC8 + AC9 and closes py's
   recorded schema-drift-masquerading-as-not-found regression.
3. `cargo test --doc` — expected: the `compile_fail` doctest passes, i.e. the omitted
   translation still does not compile. Permanent AC7 guard.
4. `rslbp show does-not-exist; echo $?` — expected: stderr carries exactly one
   `{"error":{"code":"RSLB301","message":"project 'does-not-exist' not found"}}` in machine
   mode (or `error[RSLB301]: project 'does-not-exist' not found` in human mode), stdout is
   byte-empty, and `$?` is **3**. This is R67's AC2/AC3 exercised through this item's
   translation; it is the end-to-end proof that the layer assignment produces the contracted
   exit code.
5. `rslbp show any-id` with the upstream unreachable — expected: code `RSLB102`, exit **1**,
   and the absence path demonstrably *not* taken.
6. `curl -i localhost:<port>/projects/does-not-exist` once the web surface exists —
   expected: HTTP **404** from the same `DomainError::NotFound`, one mapping arm, no second
   translation site. R70 owns the assertion's table.
7. `cargo test` on `ubuntu-latest` in CI — expected: identical results to the macOS run.
   Recorded as unverified in this run; the pattern is platform-neutral but Linux was not
   exercised.

### Confidence & re-verify trigger

**Confidence: high** on the recommendation, with the qualifications below stated rather
than smoothed over.

*What is solid.* The layer-assignment principle is recorded under an ID in py (HEX-12) and
matches what the owner asked for on 2026-09-04. The Rust realization is not invented here:
it is `rust-lang/crates.io`'s own port shape, read at commit `3a31e6c8`, and `sqlx`'s
primitive, read at commit `b54008a3`. The compile-time enforcement claim (AC7) was observed,
not argued. Every failure the pattern can produce lands on an existing R67 row, so the
recommendation needs nothing from another item.

*Where a reasonable reviewer could land differently.* The *dominant* ecosystem shape is the
runner-up, not the pick, and this report says so under `### Dominant choice` rather than
burying it. An owner who weights ecosystem conformity above the layer assignment should
choose A; the cost of being wrong is small and one-directional — moving A→D later means
touching every port method signature and every call site, while moving D→A means deleting
the `ok_or_else` calls. That asymmetry is itself an argument for starting at D.

*Confidence is lower on two specifics.* (a) The mutation carve-out in rule 1 (reads only)
is reasoned, not evidenced: no surveyed project's mutation methods were examined for their
not-found handling. (b) The `PortError` variant list is a proposal sized to the template's
example domain; a real adapter may find it needs one more variant (rate-limiting, say,
which would be `RSLB103` or a new R67 row that R74 might want anyway).

**Re-verify triggers.**

1. **R01 revises its seam shape** away from a trait port — re-check that rule 1 still reads
   naturally against a closure-valued seam. (Expected outcome: it does; the rule is about
   return types.)
2. **R05 selects async** — re-check that `Result<Option<T>, PortError>` behind
   `#[async_trait]` still boxes cleanly and that `ok_or_else` on an awaited value reads
   well. (Expected: no change; verified in principle, not in code, in this run.)
3. **R67 amends the catalogue** — specifically if `RSLB301` is split per resource kind, or
   if the `hint` field's signature settles in a way that changes how `DomainError::NotFound`
   renders the offending input.
4. **R70 publishes its status table** — confirm `ErrorCode::NotFound` → 404 is the single
   arm and that no second absence translation appeared in the web layer.
5. **R48 selects a mocking crate** — confirm the chosen crate can express "the port returned
   `Ok(None)`" as distinct from "the port returned `Err`", which `mockall` can trivially and
   any HTTP-level mock cannot.
6. **Any of the five surveyed reference projects changes its shape** — in particular, if
   `rust-lang/crates.io` moves `team_membership`/`org_membership` to a `NotFound` error
   variant, the strongest single piece of practice evidence for D would be gone and the pick
   should be re-argued. Cheap to check: re-read
   `crates/crates_io_github/src/lib.rs:87-99` at a fresh commit.
7. **The MSRV floor rises past 1.96** — no effect expected (every construct predates 1.65),
   but worth a single confirming read if `let … else` is used in the shipped code.

### Sources

**Pinned source repositories** (read through their pins, never from a working tree; all
2026-09-17):

- `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, via
  `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`:
  `docs/design/0005-hexagonal-architecture-and-enforcement.md:115-132` (HEX-11), `:134-159`
  (HEX-12), `:161-175` (HEX-13, "`None` on 404, raise on 5xx");
  `src/py_launch_blueprint/core/ports.py:20-33` (module docstring stating the rule),
  `:40-41` (`class ProjectsRepository(Protocol)`), `:47,49` (the two `| None` returns);
  `src/py_launch_blueprint/core/services/projects.py:37-63` (the class, and the two
  `is None` → `raise` sites at `:52-53` and `:62-63`);
  `src/py_launch_blueprint/core/errors.py:51-57` (the `PLBP###` constants, including
  `PLBP005` at `:56` and `PLBP006` at `:57`), `:60-115` (the exception hierarchy, with
  `ProjectNotFoundError` at `:100` and `WorkspaceNotFoundError` at `:112`);
  `src/py_launch_blueprint/core/adapters/py_api.py:119`, `:173-204` (the `allow_not_found`
  parameter and the schema-drift comment).
- `ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, via
  `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>`:
  `src/lib/api.ts:168-188` (`getProjects` folding resolve + 404 + throw into the HTTP
  function), `:12`; `src/lib/errors.ts:1-10` (the R6.1 mapping comment), `:53-58`
  (`NotFoundError` → exit 3), `:84-92` (`exitCodeFor`).
  Both repositories are private and return HTTP 404 from the network, so every claim above
  comes from the local checkout read at the pin.

**Rust project sources** (all `https://raw.githubusercontent.com/…`, retrieved 2026-09-17):

- `rust-lang/rust` at tag **`1.96.0`** — `library/core/src/option.rs` (module docs `:1-20`;
  `ok_or_else` `:1360-1363`; `transpose` `:2233-2237`), `library/core/src/result.rs`,
  `library/std/src/io/error.rs:232-238`, `library/std/src/fs.rs:1882-1914,3190`,
  `library/std/src/path.rs:3489-3518`,
  `library/std/src/collections/hash/map.rs:1030`, `RELEASES.md:4090,4096`.
- `rust-lang/book` — `src/ch09-03-to-panic-or-not-to-panic.md:79-101,226-233`
  (`https://raw.githubusercontent.com/rust-lang/book/main/src/ch09-03-to-panic-or-not-to-panic.md`).
- `rust-lang/api-guidelines` at `97a0969cb07fe4cabb0eed8a56234053f47d83dc` —
  `src/interoperability.md:190-230` (C-GOOD-ERR), `src/type-safety.md:39-53` (C-CUSTOM-TYPE).
- `rust-cli/book` at `master` — `src/tutorial/errors.md:1-20`
  (`https://raw.githubusercontent.com/rust-cli/book/master/src/tutorial/errors.md`).

**Practice evidence, read at recorded commits** (all retrieved 2026-09-17):

- `rust-lang/crates.io` @ `3a31e6c87ee884a3ff0608f0d65ede1f01454c98` —
  `crates/crates_io_github/src/lib.rs:74-103` (the port trait and its mixed return shapes),
  `:279-307` (the two `Err(GitHubError::NotFound(_)) => Ok(None)` adapters), `:396-418`
  (`GitHubError` and the status-code conversion); `crates/crates_io_github/Cargo.toml`
  (`edition = "2024"`, `thiserror = "=2.0.20"`, `async-trait = "=0.1.92"`,
  `mockall = { version = "=0.15.0", optional = true }`, `[features] mock = ["dep:mockall"]`).
- `transact-rs/sqlx` @ `b54008a329541c0ce230d8b203e0c00fc8e8ea48` (the redirect target of
  `launchbadge/sqlx`) — `sqlx-core/src/executor.rs:134-160`, `sqlx-core/src/error.rs:62-64`.
- `jj-vcs/jj` @ `e6dd2c0d60f22ef8d21d171b5fb8e4178f0af1d9` — `core/src/backend.rs:319-336`.
  (Note for anyone re-reading: the file moved from `lib/src/backend.rs`, which R01 cited on
  2026-09-05, to `core/src/backend.rs`; `lib/src/backend.rs` now returns HTTP 404.)
- `mozilla/sccache` @ `0f9467c40e012ef7ea103ac11e0c6935830b18f0` —
  `src/cache/cache.rs:62-71` (`GetPathResult`), `:73-83` (`pub trait Storage: Send + Sync`
  and the `Storage::get` contract), `:259-276` (the adapter's
  `opendal::ErrorKind::NotFound → Ok(Cache::Miss)` translation and its catch-all);
  `src/cache/cache_io.rs:36-46` (the `Cache` enum itself, which lives in a sibling module,
  not in `cache.rs`).
- `apache/arrow-rs-object-store` @ `279572ea60f3a7a6e5237e066a6f4a35eee611e0` —
  `src/lib.rs:2253-2268` (`Error::Generic`/`Error::NotFound` and their boxed sources),
  `:2371-2379` (`From<Error> for std::io::Error` mapping `NotFound` to
  `io::ErrorKind::NotFound`).
- `shepmaster/snafu` @ `d6b22be7e31fdd308bfe637349263781edcaac29` — `src/lib.rs:953-975`
  (`NoneError`, `OptionExt`).

**Metric endpoints** (all retrieved 2026-09-17):

- `GET https://api.github.com/repos/<o>/<r>` via the authenticated `gh` binary (`gh api`) —
  `stargazers_count`, `archived`, `pushed_at`, `default_branch`, for `transact-rs/sqlx`,
  `jj-vcs/jj`, `mozilla/sccache`, `apache/arrow-rs-object-store`, `rust-lang/crates.io`.
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` via `gh api` —
  `total_count` for the same five.
- `GET https://api.github.com/repos/<o>/<r>/commits/HEAD` via `gh api` — the commit SHAs
  quoted above.
- `GET https://crates.io/api/v1/crates/snafu` with a `User-Agent` header, via `curl` —
  `crate.recent_downloads`, `crate.downloads`, `crate.max_stable_version`, `crate.updated_at`.

**Repository documents read** (working tree of `rs-launch-blueprint-p02-plan`, 2026-09-17):
`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/inputs/prompt.md` (binding),
`.../inputs/PARAMETERS.md`, `research/topics/01-ports-and-adapters-seam/DECISION.md`
(R01, revision 3, owner-accepted), `research/topics/67-error-and-exit-code-contract/DECISION.md`
(R67, owner-accepted), `docs/port/COMMONALITY.md:18` (F012),
`docs/port/areas/workspace-architecture.md:18`, `docs/port/DIVERGENCE-ANALYSIS.md:58,80,242`,
`docs/port/PARAMETERS.md`.

**Method notes.** Endpoints queried: `https://raw.githubusercontent.com/…` for every source
file quoted (`rust-lang/rust` at tag `1.96.0`, `rust-lang/book`, `rust-lang/api-guidelines`,
`rust-cli/book`, and the five practice repositories at the commit SHAs recorded above);
`https://api.github.com/repos/<o>/<r>`, `https://api.github.com/repos/<o>/<r>/commits/HEAD`
and `https://api.github.com/search/issues?q=…` through the authenticated `gh` binary; and
`https://crates.io/api/v1/crates/snafu` through `curl` with a `User-Agent` header. Both
pinned source repositories were read exclusively through
`git -C <repo> show <pin>:<path>`; neither working tree was read by path, and no `git`
command that modifies anything was run. The empirical check ran in a directory created
under `$TMPDIR` with `mktemp -d` and removed afterwards. **Scratch-file disclosure:** three
downloads used for citation checks landed in `/tmp` rather than inside that `$TMPDIR`
subdirectory — `/tmp/rel.md` (`RELEASES.md`), `/tmp/snafu.html`, `/tmp/snafu_lib.rs` — and
were deleted; a later `sccache`/`option.rs` re-check used a second `mktemp -d` directory
under `$TMPDIR`, also deleted. Inside this repository the only file written, at any point,
is `raw/opus.md`.

*Not verified, and stated as such:* (1) **Linux.** Every compile and test ran on macOS 26.4
`arm64` only; `ubuntu-latest` from `target-os-matrix` was not exercised. The constructs are
core-language and platform-independent, so the risk is low, but the claim is untested.
(2) **rustc version versus the MSRV floor.** The probe ran on `rustc` 1.98.0, not on 1.96.0;
`rust-version = "1.96"` was declared in the probe manifest but no 1.96 toolchain was
installed to prove the crate builds there. Stability attributes read from the 1.96.0 source
are the evidence that nothing used is newer than the floor. (3) **`https://rustsec.org/packages/<name>.html`
was not queried** for any crate — gate 3 is `inapplicable` because this item adds no crate,
and `thiserror`/`anyhow` advisories are R67's, already adjudicated there
(`RUSTSEC-2026-0190`, floor `>= 1.0.103`). (4) **No real HTTP adapter, no async port, no web
handler and no R67 envelope writer was exercised** — AC8, AC9 and AC10 are proposals, and
the 404-discrimination rule (rule 3) is evidenced from `rust-lang/crates.io`'s production
code rather than from a run of this template's own adapter, which does not exist yet.
(5) **Issue-responsiveness medians and adopter reverse-dependency counts** were not
collected: the surveyed projects are evidence of practice, not candidates for adoption, and
the prompt's crate-figure table applies to crate candidates, of which this item has none.
(6) **`sqlx` repository identity:** `https://api.github.com/repos/launchbadge/sqlx` now
resolves to `transact-rs/sqlx`; the rename was observed in the API response and not
independently confirmed against a maintainer announcement.
