# 2026-09-27 — R76 — cors-middleware (crate, Focused) — decision (revision 5)

## Decision

This decision is a **proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. The list of claims P03 must validate is
under `## Engines`. A decision that does not survive implementation is revised against
this recorded research, not researched again from scratch.

**Revision note (revision 5, 2026-09-27).** Revision 4 (sha256
`c732bf24633eb386db07c186324af00a74c7d43f9932e4327c519a37aa40d641`, preserved verbatim
at `review/R76-r4-snapshot.md`) is touched up for the `web-extra-surface` flag day and
nothing else. Owner ruling W1-R02 changed R69's owned value at R69 revision 10 — the web
tree becomes the workspace member `crates/web`, `web = ["dep:rs-launch-blueprint-web"]` on
the root package, `axum` and `tokio` declared non-optionally in `crates/web/Cargo.toml` —
and R69 revision 11 (sha256 `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`) carries that value unchanged and is approved for
re-accept under owner decision Q3.A (flag day now). This revision therefore replaces the
`- assumes web-extra-surface` line, which held the registry's revision-9 bytes, with R69
revision 11's `- owns web-extra-surface` line at line 1885, prefix-swapped and otherwise
byte-identical; updates the prose that described that line's standing (`## Parameters`,
re-verify trigger 1, and the four places that named R69 revision 10 as the source of the
paths); and re-targets `review/evidence/decision-self-check.sh` at the new title, the new
source of that one line, and R69's line 1885. The design already used the `crates/web`
paths, so no design claim moves. **The recommendation — `tower-http` 0.7.1 with the `cors`
feature, installed only when the allowlist is non-empty — does not move.** Revision 4's
own note follows unchanged, as that revision's record.

**Revision note (revision 4, 2026-09-27).** Revision 3 (sha256
`950f53664fe727d3fc7f2ce4790ad62ef2e1eb626a0b9fc97d9f5404c55eafae`, preserved verbatim
at `review/R76-r3-snapshot.md`) was rejected by both audits: `review/audit-claude.r3.md`
(empirical, finding EA-1) and `review/audit-fable.r3.md` (judgment, findings 1 and 2).
Revision 4 repairs those three findings and nothing else. **The recommendation —
`tower-http` 0.7.1 with the `cors` feature, installed only when the allowlist is
non-empty — does not move.** Revision 3's own note follows this table unchanged, as that
revision's record.

| Finding | Disposition in this revision | Where |
|---|---|---|
| **EA-1** (empirical, blocking) — OV-08 option 2 was offered as literal R4.17 conformance, but its check `X10` showed a preflight carrying `allow` under an expose list that did not name it | **Repaired with the audit's one-token fix.** `allow` joins `request-id` in the single expose-list floor, so `CorsLayer` and option 2's stamp carry one list; checks `X1`, `X9`, `X10` and `X11` are re-recorded with it. Option 2's preflight definition now matches the probe's `expose_on_preflight`: an `OPTIONS` request carrying `access-control-request-method` | the `expose_headers` row; the R75 hand-off; `### OVERRIDE (OV-08)` option 2; criterion 8; the X-check table; `rest-conformance-r2.sh` |
| **Finding 1** (judgment, blocking) — `hyper-cors` was called "gates 2–5 cleared" yet left off the qualified shortlist | **Repaired as the owner directive prescribes, which overrules both auditor repairs.** `tower-http` 0.7.1 stays adopted. The `hyper-cors` entry changes from "unusable here" to "no direct axum layer (untested Hyper-boundary adapter path; 41 downloads, 0 dependents)", presented as a substrate-compatible but unproven alternative. `actix-cors` stays the framework-bound runner-up that needs actix-web beside axum. The entry no longer claims gates this run did not measure, so the shortlist count stays two | `Excluded by gate` |
| **Finding 2** (judgment, minor) — trigger 14 counted two Fetch Standard sentences where the prose and the log count three | Trigger 14 and the section-G description both now read "the three sentences OV-08's Argument rests on, two quoted and one paraphrased" | re-verify trigger 14; `## Empirical check` |

The owner directive for finding 1, verbatim as it reached this round:

> owner overrules both auditor repairs: KEEP tower-http 0.7.1 as the adopted decision; reword hyper-cors from "unusable here" to "no direct axum layer (untested Hyper-boundary adapter path; 41 downloads, 0 dependents)" presented as a substrate-compatible but unproven alternative; keep actix-cors as the framework-bound runner-up that needs actix-web beside axum; S53 evidence at /tmp/s53-actix-cors.md + /tmp/s53-hyper-cors.md, read-only

The two `/tmp` briefs are this round's scratch files, not repository artifacts; the
figures taken from them are cited below with their public endpoints. Ledgering the
directive is the controller's step.

**Revision note (revision 3, 2026-09-27).** Revision 2 (sha256
`55d7df033a12683fff26d3e8e7d6199b56b31e1628a6e27d27afc25ee170baeb`, preserved verbatim
at `review/R76-r2-snapshot.md`) was rejected by both audits. Revision 3 repairs every
finding. **The recommended crate, version, configuration and conditional-install policy
do not move.** What moves is the record around them: a second engine's report is now
adjudicated, one standard rule that revision 2 called "not engaged" is now recorded as a
written deviation, and every figure is re-measured and dated.

| Finding | Repair in this revision | Where |
|---|---|---|
| **JA-1** (judgment, blocking) — the Muse report `raw/muse.md` is not represented; the engine set is stated against a superseded prompt | `## Engines` lists Muse with its sha256, states the `muse, opus` engine set and its authority, and settles every disagreement with evidence. `actix-cors` is re-dispositioned as **gate-passing and fit-excluded**, which changes `Qualified shortlist` and `Excluded by gate` | `## Engines`; the shortlist and exclusions below; new script `muse-adjudication.sh` |
| **JA-2** (judgment, blocking) — "R4.17 not engaged on a preflight" rested on a false ground; "Deviations: none" was unsupported | The preflight **does** carry standard-bound headers (`allow`; `request-id` under the order R11.7 requires) with no expose list. That is now recorded as **`OVERRIDE (OV-08)`** with an Argument grounded in the Fetch Standard's own text and three Options, one of them measured. The conformance note's Deviations line names it | the R4.17 row; `### OVERRIDE (OV-08)`; `rest-conformance-r2.sh` sections C, D, G |
| **JA-3** (judgment) — "six" acceptance criteria against a seven-row table | Every count now says seven, and P03's planned check (3) covers criterion 7 | the criteria table; `## Empirical check`; `## Engines` |
| **F1** (empirical) — the gate-2 assertion `= 1.80` fails since `hyper-util` 0.1.21 (2026-09-24) declared `rust-version` 1.85 | The probe now builds from committed lockfiles with `--locked`; the assertion is the gate's own property, `≤ 1.96`, compared numerically; the maximum is a dated figure | gate 2; `probe-checks.sh` |
| **F2** (empirical) — binary sizes drifted (+166,480 B claimed, +166,464 B observed) | Sizes are re-measured and stated as bound to the toolchain and the committed lockfiles, not as "identical across runs" | gate 6; `## Empirical check` |
| **F3** (empirical) — the probe aborts under an inherited `CARGO_TARGET_DIR` | The scripts unset `CARGO_TARGET_DIR` and `CARGO_BUILD_TARGET_DIR`; every build lands in its own scratch `target/`. Verified by running with the variable exported | `probe-checks.sh` |
| **F4** (empirical) — the committed conformance log was produced from an earlier draft | Both scripts that read this document print its sha256 in their log header; the logs were recorded against these final bytes | `## Empirical check` |
| **F5** (empirical) — point-in-time figures and one cited line number drifted | Every figure is re-fetched and dated 2026-09-27; the `rust-lang/crates.io` pin is cited by commit sha and line | throughout |

**Revision 2's own note, corrected.** Revision 2 was occasioned by owner ruling
**W2-REST** of 2026-09-18 (`docs/port/OWNER-REVIEW.md`, heading *"2026-09-18 — the REST
API Design Standard binds the HTTP surface (W2-REST)"*). That ruling makes the
organisation's **REST API Design Standard v2.0.0** bind this template's HTTP surface. The
standard is pinned at commit `0850d43e45d919ef5e37f7174c4212b46013c49f`, file blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9` (190,161 bytes, 3,427 lines, read with
`git -C /Users/stevemorin/c/rest-standards cat-file blob 71bd813c…`). Revision 2 moved the
recommendation once, for **R4.17**: with an allowlist configured, revision 1's
`CorsLayer` emitted no `Access-Control-Expose-Headers` at all, so a cross-origin browser
client could not read `request-id`, which R11.7 makes mandatory on every response. The
recommendation now configures `expose_headers`, and `apply_cors` carries the list as a
third parameter. Revision 2 then said that "every quoted rule conforms or is not engaged"
and that OV-08 "stays unused". **Both statements were wrong for preflight responses**, and
revision 3 replaces them with `OVERRIDE (OV-08)` below.

**Adopt `tower-http` **0.7.1** with the `cors` feature, and install
`tower_http::cors::CorsLayer` from a plain conditional branch in the composition root
that fires only when the configured origin allowlist is non-empty.** The dependency line
goes in `crates/web/Cargo.toml`; the branch goes in the `build_router` assembly R69
fixed. When the allowlist is empty — the default — no layer is constructed, no layer is
applied, and the router is observably identical to one built from a template with no
CORS code in it at all.

```toml
# crates/web/Cargo.toml
[dependencies]
tower-http = { version = "0.7.1", default-features = false, features = ["cors"] }
```

```rust
// crates/web/src/cors.rs
use axum::Router;
use axum::http::{HeaderName, HeaderValue};
use std::time::Duration;
use tower_http::cors::{Any, CorsLayer};

/// Install the CORS layer only when an origin allowlist is configured.
/// An empty allowlist (the default) leaves the router byte-identical to a build
/// with no CORS code: no layer, no `Vary`, and `OPTIONS` on a GET-only route
/// still answers 405.
///
/// `exposed_headers` lists every standard-bound response header this service
/// emits, which REST API Design Standard R4.17 makes mandatory wherever the
/// API serves cross-origin browser clients. It is never empty: R11.7 puts
/// `request-id` on every response unconditionally.
pub fn apply_cors(
    router: Router,
    allowed_origins: &[HeaderValue],
    exposed_headers: &[HeaderName],
) -> Router {
    if allowed_origins.is_empty() {
        return router;
    }
    router.layer(
        CorsLayer::new()
            .allow_origin(allowed_origins.to_vec())
            .allow_methods(Any)
            .allow_headers(Any)
            .expose_headers(exposed_headers.to_vec())
            .max_age(Duration::from_secs(600)),
    )
}
```

| Setting | Value | Ground |
|---|---|---|
| crate and version requirement | `tower-http = "0.7.1"` — a caret requirement (`>= 0.7.1, < 0.8`), not the exact pin `rust-lang/crates.io` uses, and not the looser `"0.7"` the Muse report proposes | 0.7.1 is the newest non-yanked version, published `2026-08-31T14:49:25.697237Z` (`GET https://crates.io/api/v1/crates/tower-http/versions`, re-read 2026-09-27). `crates/web` is a *published library* under R02 revision 2's four-package workspace. An exact pin in a library propagates a resolution constraint to every downstream consumer. The floor is 0.7.1 rather than 0.7.0 because 0.7.1 is the version every check in this run measured; the adjudication is under `## Engines`, Muse disagreement 3 |
| feature list | exactly `["cors"]`, with `default-features = false` written for explicitness | `tower-http` declares `default = []` (`tower-http-0.7.1/Cargo.toml:161`) and `cors = []` (`:117`), so the `cors` feature activates no optional dependency at all. R75 owns the aggregate feature list on this one line and may extend it; it must not remove `"cors"` |
| installation mechanism | a re-binding `if` over the `Router` in the composition root | `axum::Router::layer` returns `Router<S>` — the same type it was called on — so `app = app.layer(cors)` inside an `if` type-checks. Executed: `review/evidence/probe-checks.log`, section B |
| trigger | the configured allowlist is non-empty | `F322`'s recorded principle is *absence*, not *permissive-but-empty*. The difference is measured, not asserted: see the two rows below |
| `allow_methods` / `allow_headers` | `Any` (the literal `*`) | matches what py's `allow_methods=["*"], allow_headers=["*"]` permits. The emitted header text differs cosmetically; the permission is the same |
| `expose_headers` | an **explicit list** of every standard-bound response header the service emits, never the `Any` wildcard, and never empty | added in revision 2 to satisfy **R4.17** on actual responses. The wildcard is not an option: it emits a bare `access-control-expose-headers: *`, which lists no header name and so does not do what R4.17 says to do, and the Fetch Standard ignores `*` outright once credentials are in play. The list's floor is `request-id`, because **R11.7** makes that header unconditional, and `allow`, because **R5.11** makes it mandatory on every `405` and axum stamps it on the preflight (check `X4`) — added in revision 4 (EA-1); R75 assembles the rest from the layers it installs. Measured in `review/evidence/rest-conformance-r2.log`, checks `X1`, `X2` and `X3`. `CorsLayer` applies this list **only to non-preflight responses** (`tower-http-0.7.1/src/cors/mod.rs:728`–`729`), so preflight responses are covered by `OVERRIDE (OV-08)` below |
| `max_age` | `Duration::from_secs(600)` | Starlette emits `Access-Control-Max-Age: 600` unconditionally; `tower-http` emits nothing unless asked. Without this call a browser re-preflights every request. **Compiled and measured in this run** (`probe-checks.log`, check `E`: `access-control-max-age=600`), closing the one gap the Opus report left open |
| `allow_credentials` | not set, so off | agrees with Starlette's `allow_credentials: bool = False`. Setting it alongside a wildcard *panics* through `ensure_usable_cors_rules` (`tower-http-0.7.1/src/cors/mod.rs:820`); the recommended configuration never does, and a future item that exposes the knob must convert that panic to a boot-time error |
| call site | `Router::layer`, never `Router::route_layer` | `route_layer` does not run for a request no route matched, so a preflight to an unmatched path returns a bare `404` with no CORS headers (`probe-checks.log`, checks `P2` and `P3`) |

**The ledger row this settles.** `F322` — *CORS middleware installed only when an
allowlist is configured* — `docs/port/COMMONALITY.md:326`, origin `py-only`, verdict
`DIVERGENT`. `DIVERGENT` is the verdict `docs/port/README.md:71` assigns when "precedents
disagree, or one exists and Rust needs a decision"; this is the second case, and this
decision is that decision. No other ledger row is touched and **no `BASELINE-REVIEW:`
finding is raised**: `F322` is not an inherited `COMMON → REUSE` or `ADOPT` baseline, so
there is no inherited mechanism here to adjudicate. `docs/port/BASELINE-REVIEW.md`
contains no `F322` and no `R76` entry, which is consistent with that.

**The conditional is load-bearing, and that is a measurement rather than a preference.**
Installing `CorsLayer` unconditionally and configuring it with an empty allowlist is
*not* observationally equivalent to not installing it. Two observables change, both
executed in `review/evidence/probe-checks.log`:

| Observable | Layer absent (recommended) | Layer present, allowlist empty |
|---|---|---|
| `GET /a` with `Origin: https://evil.example` | `200`, headers `{content-length, content-type}` — no `vary` | `200` **plus `vary: origin`** on every response |
| `OPTIONS /a` on a `GET`-only route | **`405 Method Not Allowed`**, `allow: GET,HEAD` | **`200`**, and with py's literal configuration it also advertises `access-control-allow-headers: *` and `access-control-allow-methods: *` |

Both differences have a single cause in the shipped source: `Cors::call` short-circuits
on `parts.method == Method::OPTIONS` (`tower-http-0.7.1/src/cors/mod.rs:715`) regardless
of what the allowlist holds, and emits the derived `Vary` header on every response it
handles (asserted at source in `review/evidence/registry-figures.log`, section G). A
service that answers `200 OK` with an empty body to `OPTIONS /v1/projects` when nobody
configured CORS is reporting something untrue about itself. One `if` is the proportionate
price.

**Why 0.7.1 rather than the owner reference's 0.6, and what the move actually changes.**
The reference architecture (`inputs/owner-reference-axum-companion-stack-2026-09-16.md:141`)
names `tower-http = { version = "0.6", … }`. 0.7.0 shipped **2026-06-15** and 0.7.1
**2026-08-31**, both before that document's own 2026-09-16 date. The Rust project's own
registry service pins `tower-http = { version = "=0.7.1", … }` in production, at
`rust-lang/crates.io` `Cargo.toml@765bbf478827f421a93ea2634997b2b4f55c87f4:168` (read
through `gh api` at that commit on 2026-09-27; revision 2 cited a bare `Cargo.toml:170`
on the moving default branch, and the line has since moved). The 0.7.0 changelog carries
exactly **one** `cors` entry — "`cors`: relax the `Vary` header defaults (#674)" — and
**seven** `**breaking:**` entries, none of them in `cors`; they land in `compression`,
`follow-redirect`, `services`, `trace`/`classify`, and the removal of the no-op
`tokio`/`async-compression` features.

That relaxation is not invisible in this template's own configuration, and this decision
states what it is rather than calling it "no change". The same thirteen observations were
run against **0.6.11** and **0.7.1** (`probe-checks.log`, section C). Every status code is
identical. The one difference is the `Vary` value: with the recommended
`allow_origin(list)` configuration, 0.6.11 emits
`vary: origin, access-control-request-method, access-control-request-headers` and 0.7.1
emits `vary: origin` alone, because 0.7.1 derives the header in `update_vary_header` from
which CORS response headers are actually request-dependent instead of always sending the
fixed preflight-header list. The move is a narrowing, it is more cache-correct, and it
touches nothing else this item depends on.

**The gates, answered in full, in the prompt's order.**

1. **Licence — `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is
   not evaluated for any dependency or tool`.** The ruling is recorded at
   `docs/port/OWNER-REVIEW.md`, section *"2026-09-12 — no licence check for anything the
   template uses (Q4, superseded and widened by Q7.B)"*, and it strikes this gate from
   every item's evaluation, including crates compiled into the shipped artifact. The row
   is kept rather than deleted because the binding prompt still carries the gate and its
   hash is cited by published acceptance records. **Stated plainly, per the honesty
   contract: striking this gate changes nothing in this decision.** Every candidate below
   is selected or excluded on a ground that does not mention it — `tower-http` wins on
   being the maintained `tower::Layer` implementation of the protocol, and each exclusion
   names an MSRV, an integration, a fit or a scope ground.
2. **MSRV — pass, with the tree resolved rather than assumed.** `msrv-policy` is *stable
   minus two minor versions*; stable `rustc` is on the 1.98 line (`1.98.1` on this host),
   which puts the floor at **1.96**. `tower-http` 0.7.1 declares `rust-version = 1.65`.
   The gate applies to the dependency tree, so the tree was resolved: `cargo metadata
   --locked --format-version 1 --all-features` on the probe reports **57** packages. The
   highest declared `rust-version` among the dependencies is **1.85 (`hyper-util`
   0.1.21)** under the lockfile committed at `review/evidence/snapshots/probe-with.Cargo.lock`
   and resolved on 2026-09-27. Revision 2 reported **1.80 (`axum` 0.8.9)**, which was true
   as resolved on 2026-09-18; `hyper-util` 0.1.21 was published on 2026-09-24 with
   `rust-version` 1.85 and moved the maximum. **The gate is `≤ 1.96`, and both values
   pass it.** Nine packages declare no `rust-version` — `httparse`, `matchit`, `mime`,
   `serde_urlencoded`, `smallvec`, `sync_wrapper`, `tower-layer`, `tower-service`, `wasi`
   — and a differential resolution asserts that **none of the nine is introduced by this
   item**: they arrive with `axum` and `tokio`, which R69 already accepted. Recorded so the
   fact is not lost; R69 is not re-litigated.
3. **Advisories and `unsafe` — pass, zero open.** `https://rustsec.org/packages/tower-http.html`
   answers `200` and lists exactly two entries (control: `https://rustsec.org/packages/atty.html`
   also answers `200`, so a `404` would mean the site changed rather than that an advisory
   cleared). `RUSTSEC-2021-0135` is marked **withdrawn**. `RUSTSEC-2022-0043` declares
   `patched = [">= 0.2.1", ">= 0.1.3, < 0.2.0"]`, `os = ["windows"]`, and affects
   `tower_http::services::fs::ServeDir` — a feature this dependency line never enables, on
   an operating system `target-os-matrix` does not name, patched many minor lines before
   0.7.1. `unsafe` posture: `#![deny(unsafe_code)]` at `tower-http-0.7.1/src/lib.rs:200`;
   the crate's only `unsafe` block is a Windows-only test helper at
   `src/services/fs/serve_dir/tests.rs:1246`; the `cors` module contains the token
   `unsafe` **zero** times, asserted file by file.
4. **OS coverage — pass.** `tower-rs/tower-http` `.github/workflows/CI.yml` runs its main
   `test` jobs on `ubuntu-latest`, a `test-os` job on `os: [macos-latest, windows-latest]`,
   and a `test-msrv` job pinned to `dtolnay/rust-toolchain@1.65`. Both members of
   `target-os-matrix` are covered upstream; Windows, which is not required, is covered too;
   and the declared MSRV is enforced upstream rather than merely declared.
5. **Default features and runtime coupling — pass, stated.** `default = []`, so the
   dependency line must name `cors` explicitly and nothing else is pulled in; `cors = []`,
   so the feature activates no optional dependency. With only `cors` on,
   `cargo tree -e normal -p tower-http --depth 1` lists `bitflags`, `bytes`, `http`,
   `percent-encoding`, `pin-project-lite`, `tower-layer`, `tower-service` — and **no
   `tokio` edge**, asserted. The layer is executor-agnostic and runs under whatever
   runtime R69's `tokio` provides. Gate 5 is a **disclosure** gate — the prompt asks for
   default features and runtime coupling to be *stated* — and revision 3 uses it only that
   way for every candidate; see `Excluded by gate` below.
6. **Binary size and compile time — pass, measured, and one half of it withdrawn.**
   Two otherwise identical probe binaries, one with the dependency and the conditional
   layer and one without, each built from a removed `target/` directory on
   `rustc 1.98.1` / macOS 26.4 `arm64`, from the committed lockfiles. Stripped:
   **502,264 → 668,728 bytes** (**+166,464 B**, 2026-09-27). Revision 2 reported
   +166,480 B on `rustc 1.98.0` with the 2026-09-18 resolution. The 16-byte difference
   coincides with the toolchain and lockfile change; this run did not isolate which of the
   two caused it. The byte sizes reproduce only for a fixed toolchain and lockfile. **Compile time: no delta is claimed.** Across two clean release
   builds per arm the arms did not separate beyond this host's run-to-run variation —
   `probe-checks.log` records 11.5 s and 11.8 s without the dependency against 11.4 s and
   11.7 s with it. The Opus report's `+4.1 s` is recorded under `## Engines` as a figure
   this run could not reproduce. The absolute byte delta is the meaningful figure; its
   percentage form must not be carried forward, because the probes contain almost no
   other code.

**Conformance to the REST API Design Standard v2.0.0 (owner ruling W2-REST), rule by
rule.** Every rule below was located by searching the pinned blob for CORS, cross-origin
access, browser clients, allowed origins, and the security and deployment profile, then
quoted at its line. `review/evidence/rest-conformance-r2.sh` asserts the quoted bytes at
the blob, so a quotation cannot drift from its source, and then measures each conformance
claim.

| Rule | Line | Quoted | Disposition |
|---|---|---|---|
| **R4.17** | 864, 868 | "Where an API serves cross-origin browser clients, every response MUST list the standard-bound response headers it emits … in `Access-Control-Expose-Headers`." | **Actual responses: CONFORMS since revision 2.** Revision 1 set no expose list, so its response carried no `access-control-expose-headers` (check `X2`); the recommendation now configures an explicit list, emitted naming each header (check `X1`). The wildcard form was rejected on measurement: it emits `*`, which lists nothing (check `X3`). **CORS preflight responses: DEVIATES, recorded as `OVERRIDE (OV-08)`.** The preflight `200` carries `allow: GET,HEAD` (check `X4`) and, under the order R11.7 requires, `request-id` (check `X7`), with no expose list; no `CorsLayer` configuration adds one (`mod.rs:728`–`729`). Revision 2 called this "not engaged" on the ground that a preflight carries no standard-bound header, which `X4` itself contradicts |
| **R11.7** | 1752 | "Every response, including errors, MUST carry the `request-id` correlation header (§1.10)." | **CONFORMS, with an ordering constraint now required rather than advised.** A CORS preflight short-circuits before the inner service, so a request-id layer placed *inside* `CorsLayer` leaves the preflight `200` with no `request-id` (check `X6`) — a MUST violated. Placed *outside*, the same preflight carries it (check `X7`). R76 owns neither the header nor the order; it hands R75 a rule-backed constraint. `OVERRIDE (OV-08)` does not relax this: `request-id` stays on every preflight |
| **R5.11** | 1008 | "`405 Method Not Allowed` MUST carry an `Allow` header." | **CONFORMS, and the conditional install is what makes it true.** With the allowlist empty the layer is absent and `OPTIONS` on a `GET`-only route answers `405` carrying `allow: GET,HEAD` (check `X5`). The rejected alternative B destroys that response entirely, turning it into a `200` — an independent, standard-level reason for the branch this item recommends |
| **R4.11** | 856 | "Every response whose content was selected by a request header MUST send `Vary` listing each header that influenced selection. **Exception:** responses with no negotiation." | **CONFORMS in both branches.** Allowlist empty: no layer, no negotiation, no `Vary` — the rule's own stated exception (check `X8`). Allowlist configured: `Origin` selects whether `access-control-allow-origin` is emitted, and `vary: origin` names it (check `X9`). Emitting `Vary` more broadly than the rule compels is not a deviation; the rule fixes a floor, not a ceiling |
| **R4.10** | 846 | "The default media type … is `application/json` … Media-type selection MUST use HTTP content negotiation, never a `format` query parameter." | **NOT ENGAGED by the CORS layer, measured rather than assumed.** The preflight `200` in check `X4` carries `content-length: 0` and no `content-type`, so no media type was selected and no negotiation arises. (That same response does carry `allow`, which is the R4.17 matter above, not an R4.10 one.) The rule binds the endpoints R70 and R71 own |
| **R1.6** | 229, 237, 241 | "The switch vocabulary: `webhooks` · `async-operations` · `bulk-operations` · `streaming`." · "…client audience — belong in the conformance note's free text, not here." | **CONFORMS, and it closes a tempting escape route.** There is **no applicability switch for CORS, cross-origin access or browser clients** — asserted by counting those words in the vocabulary lines, which finds **zero**. A CLI-first template therefore *cannot* declare these rules N/A by switch. R4.17 is scoped by its own conditional clause instead, and this item meets that clause on actual responses and records its one gap in writing |
| **R1.7** | 271 | "An API deviates from this standard only in writing… silent deviation from any rule strength is nonconformance regardless of the deviation's merits." | **CONFORMS, with one deviation recorded in writing.** R1.7 also says a MUST deviation makes the API nonconformant "unless it is recorded as an approved exception in the conformance note" (blob lines 273–275). The R4.17 preflight gap is therefore written up as `OVERRIDE (OV-08)` and handed to the conformance note's Deviations line; it becomes an *approved* exception only by the owner's ruling. `rest-conformance-r2.sh` section D asserts that the decision names every rule quoted here and that OV-08 carries an Argument and Options |
| **R8.10** | 1387 | "Each axis below carries a ratified default and named threat-model flip triggers. An API MUST adopt each axis default unless a named trigger applies, and MUST record any flip in its conformance note." | **NOT ENGAGED; hand-off recorded.** None of the five axes — sender-constrained tokens, token format, rate-limit aggressiveness, replay window, object-level authorization — is a CORS axis, asserted by counting CORS terms in the axis table, which finds **zero**. This item flips nothing. It does, however, *establish the fact* that a browser client exists whenever the allowlist is non-empty, and that fact is an input to the sender-constrained-tokens axis ("hostile-environment public clients → DPoP"). Recorded for whoever owns the auth axes, not decided here |
| **R8.1** | 1317 | "APIs MUST be served only over TLS 1.2 or higher…" | **NOT ENGAGED.** The CORS layer neither terminates nor negotiates TLS. Stated rather than skipped, because a security-section rule passed over in silence is indistinguishable from one overlooked |
| **R8.2** | 1323 | "Access tokens MUST NOT be accepted or emitted in URI query parameters." | **NOT ENGAGED.** The layer reads the `Origin` request header and writes `Access-Control-*` response headers; it touches no query string and no credential. The recommendation sets no `allow_credentials`, so it emits nothing a token could ride on |
| **R8.11** | 1414 | "Caller-supplied URLs (webhook targets, callbacks) MUST be validated and restricted against internal address ranges." | **NOT ENGAGED, and worth saying why, because it looks as though it should be.** R8.11 governs URLs *the server fetches*. The origin allowlist is the opposite direction: an operator-supplied set of inbound origins matched against a request header, never dereferenced. No SSRF surface is created by this item |

Two supporting registry rows were quoted with the rules that rest on them: §1.10's
`request-id` row at line 348 ("emitted on every response including errors") and its
`Allow` row at line 351 ("Mandatory on every `405 Method Not Allowed`"). Appendix A's
checklist row for R4.17 stands at line 2696, and Appendix E's worked example states the
same obligation in prose at lines 2913–2915 — a conformant API "serves cross-origin
browser clients, so every response also carries `Access-Control-Expose-Headers` listing
the standard-bound headers it emits (R4.17)".

**The conformance-note lines this item owes** (R1.7's template, §1.9). R76 does not own
the template's conformance note, so these are supplied for whoever assembles it rather
than written into it here:

- *Context (free text):* "The HTTP surface serves cross-origin browser clients only when
  the operator configures a non-empty origin allowlist; with the default empty allowlist
  no CORS middleware is installed and the service emits no `Access-Control-*` header."
- *N/A declarations:* none owed by this item. R4.17 is not declared N/A. Where its
  condition holds it is met on actual responses, and its preflight gap is a deviation,
  below — not an N/A. Where its condition does not hold, there is nothing to declare:
  under R1.6 an unmet conditional clause is not an off switch.
- *Deviations:* `OVERRIDE (OV-08)` — R4.17 on CORS preflight responses: with the allowlist
  configured, a CORS preflight response carries `allow` and `request-id` without an
  `Access-Control-Expose-Headers` list; every other response carries the list. Pending
  the owner's ruling, which is what makes it an approved exception under R1.7.

**Couplings, stated and not decided.**

- **R69 (`web-framework-stack`, F303)** fixed `axum` 0.8.9 on `tokio` 1.53.1 and fixed
  `tower` 0.5.3 as `crates/web`'s **dev-dependency only**, for the
  `tower::ServiceExt::oneshot` in-process test idiom. *What this recommendation adds to
  the tree is exactly two packages: `tower-http` 0.7.1 and `bitflags` 2.13.2* — 57
  resolved packages against 55 without the line, with **nothing removed**. `tower` itself
  **stays a dev-dependency declaration and is not promoted**: `tower-http` depends on
  `tower-layer` and `tower-service`, not on `tower`, and `tower` 0.5.3 is in the non-dev
  graph already, transitively through `axum` — which R69's own published decision records
  (`cargo tree --invert tower` showing `tower v0.5.3 └── axum v0.8.9`) and which this run
  re-measured. The addition lands on the **web** graph only; the CLI's default build never
  resolves it. R69 settled on axum, which is also why the Muse report's conditional
  runner-up, `actix-cors`, cannot currently win; a republished R69 naming a non-`tower`
  framework is re-verify trigger 1.
- **R75 (`http-middleware-stack`, F317)** owns where this layer sits when present and owns
  the aggregate feature list on `crates/web`'s single `tower-http` line. This item
  contributes exactly `"cors"` and hands R75 one measured constraint: **a preflight
  short-circuits before the inner service runs** — handler invocations `0` — so any layer
  that must stamp preflight responses (request id, security headers) has to sit
  **outside** `CorsLayer`. Under owner ruling W2-REST that is grounded on a rule:
  **R11.7** puts `request-id` on every response, a preflight response included, and checks
  `X6` and `X7` measure both sides. R75 also owns the `expose_headers` list R4.17 obliges,
  since R75 decides which standard-bound headers the stack emits — this item fixes only
  that the list exists, is explicit rather than a wildcard, and contains `request-id` and
  `allow` as a floor. If the owner refuses `OVERRIDE (OV-08)`, R75 also installs its option 2, an
  outermost stamp. R75 must read the 0.7.0 breaking entries itself for whichever other
  features it adds; this item's confidence covers `cors` and nothing else.
- **R77 (`web-env-settings`, F324)** owns the variable name and the parse. Its research
  names `RSLBP_WEB_CORS_ORIGINS`, comma-separated, with an unset or empty variable meaning
  the empty list, and raises the question of whether R76 needs an encoding that survives
  commas. **It does not:** an origin is `scheme://host[:port]` and cannot contain a comma,
  so comma-splitting is lossless for this field. This item consumes only "a possibly-empty
  ordered collection of allowed origins reaches the composition root", wants it as
  `Vec<HeaderValue>` parsed once at boot, and leaves naming and decoding to R77.
- **R74 (`rate-limiting`) and R73 (`idempotency`)** are being researched in parallel and
  are ordered by R75, not here. R74's research recommends a layer built from `axum` itself
  and adds no crate, so it does not change this item's dependency arithmetic.
- **R67 (`error-taxonomy-exit-codes`)** supplies the failure code for a bad origin. An
  unparseable allowlist entry is a config value that is invalid, which R67's published
  catalog maps to `RSLB203` and exit code **2**. This item consumes that mapping and asks
  for no new catalog row.
- **R01 (`ports-and-adapters-seam`)** is untouched: CORS is an HTTP-transport concern that
  lives entirely on the front-end side of R01's port, so `crates/core`'s external
  dependency allow-list and R02's `tests/workspace_edges.rs` guard both keep passing
  unamended. **R05 revision 3** (synchronous core, `spawn_blocking` in the handlers) is
  likewise unaffected, since the layer never touches the port.

### OVERRIDE (OV-08) — no `Access-Control-Expose-Headers` on CORS preflight responses (REST API Design Standard R4.17)

**Numbering.** OV-08 is the number the controller allocated to this item. The allocation
table was ledgered at commit `69a635ec` ("OV-08 R76", 2026-09-18), after two syntheses
collided on OV-04 by searching for free numbers. Revision 2 left OV-08 unused; revision 3
uses it. No number was searched for.

**This is an `OVERRIDE (OV-nn)` in the AGENTS.md sense** — a departure from a binding
standard's rule, argued with options — and not a ledger verdict. `F322` stays `DIVERGENT`
and no ledger file changes.

**What deviates, measured.** R4.17 (blob lines 864–868) requires that where an API serves
cross-origin browser clients, "every response" lists its standard-bound response headers
in `Access-Control-Expose-Headers`. With the allowlist configured, the recommended stack
answers a CORS preflight on a `GET`-only route with a `200` that carries:

- `allow: GET,HEAD` — `Allow` is a §1.10 response header (blob line 351). It is stamped by
  axum, not by `tower-http`: an `OPTIONS` request on a `GET`-only route takes the method
  router's fallback, `Router::layer` wraps that fallback in `CorsLayer`, and axum adds
  `Allow` to whatever the fallback returned
  (`axum-0.8.9/src/routing/method_routing.rs:1168`–`1174`; `axum-0.8.9/src/routing/route.rs:180`–`182`;
  both asserted in `rest-conformance-r2.log`, section C). Check `X4`.
- `request-id`, under the layer order R11.7 requires. Check `X7`.
- no `access-control-expose-headers`, in either check.

No `CorsLayer` setting changes that: `tower-http` applies the expose list only on the
non-preflight branch (`tower-http-0.7.1/src/cors/mod.rs:715`, `:728`–`729`, asserted in
`registry-figures.log`, section G). Actual responses do carry the list (check `X1`). The
gap is therefore confined to responses to CORS preflight requests.

> **Argument:** R4.17 states its own purpose: the listed fields are not CORS-safelisted,
> "so without this header a cross-origin browser client cannot read them at all" (blob
> lines 868–870). On a preflight response that purpose cannot arise, and the WHATWG Fetch
> Standard says so in its own text (`GET https://fetch.spec.whatwg.org/`, "Living
> Standard — Last Updated 21 September 2026", read 2026-09-27; sentences asserted in
> `rest-conformance-r2.log`, section G). First, the Fetch Standard defines
> `Access-Control-Expose-Headers` as a header of "an HTTP response to a CORS request that
> is not a CORS-preflight request". Second, in its HTTP fetch algorithm the preflight
> response is handed back to the caller only when it is a network error ("If
> preflightResponse is a network error, then return preflightResponse."); otherwise the
> response the caller receives is the actual request's. Third, the header-name list is
> consumed by the CORS filtered response built for that actual response. A browser client
> therefore cannot read a preflight's headers with the list or without it. The
> recommendation already emits the list on every actual response, which is where R4.17's
> purpose is served. Emitting it on preflights as well would add inert header bytes,
> produced by hand-written code outside the CORS implementation, which is the kind of
> hand-rolled CORS code alternative D rejects.
>
> **Options:**
> 1. **Record the deviation for preflight responses (recommended).** No code changes; the
>    conformance note's Deviations line carries OV-08 as written above. Cost: one written
>    exception in the conformance note, which R1.7 makes the owner's to approve. If
>    approved, the template is conformant under R1.7's "approved exception" clause.
> 2. **Conform literally with an outermost stamp.** A `from_fn` middleware, placed
>    outside `CorsLayer` and outside the request-id layer, adds the same list to the
>    response to any CORS preflight — an `OPTIONS` request carrying
>    `access-control-request-method` — when that response carries
>    `access-control-allow-origin` and no expose header. **Measured:** check `X10` shows
>    the preflight then carries `allow` and `request-id` under an expose list that names
>    both; check `X11` shows actual responses unchanged, with one
>    expose header and no duplicate. It needs no crate and no feature. Cost: about fifteen
>    lines of hand-written CORS-adjacent middleware in R75's stack, whose only effect is
>    inert header bytes on preflights, plus one more acceptance criterion. `tower-http`'s
>    `SetResponseHeaderLayer::if_not_present`, behind its `set-header` feature, is the
>    tower-native form of the same option; it was not measured here.
> 3. **Argue that R4.17 is "not engaged" on preflights, with no written deviation.** This
>    was revision 2's position. Rejected: R1.7's text offers no interpretive-scoping path —
>    a MUST deviation is nonconformance "unless it is recorded as an approved exception",
>    "regardless of the deviation's merits". The Fetch reading above is an argument for
>    approving the exception, not a substitute for recording it.

**What the owner's ruling does.** Approval of option 1 leaves the recommendation exactly as
written. Refusal means P03 adopts option 2, which is already measured (check `X10`), with
no re-research. Either way `request-id` stays on every preflight (R11.7), and the ruling is
re-verify trigger 13.

### Principles and implementation

**The shared requirement, its source, and its agreement level.** The principle is
*cross-origin relaxation is opt-in, and when it is not opted into it is absent from the
request path.* Its source is `py-launch-blueprint` at pin `b08bccfb`, which states it in
three registers: the mechanism (`src/py_launch_blueprint/web/app.py:136`,
`if settings.cors_origins:` guarding the single `add_middleware` call), the configuration
(`src/py_launch_blueprint/web/settings.py:60-62`, "Empty (the default) means the CORS
middleware is not installed at all"), and the policy
(`docs/adr/0013-web-service-best-practices.md:40-41`, "Risky features (CORS, rate
limiting, tracing) are wired but **off by default**; one env var enables each").
`ts-launch-blueprint` at pin `cb1cbcb2` has no web service to reconcile with
(`docs/port/areas/web-service.md:100`), which is why `F322` is `py-only`. Both research
reports reach the same principle at the same agreement level (capability plus policy).

**The agreement level is the policy, not the mechanism.** What all three repositories must
agree on is the observable: *with no allowlist configured, a cross-origin browser request
receives no `Access-Control-Allow-Origin` header and the service behaves exactly as if no
CORS code existed.* What may vary is everything under it — the type name, the header set,
the default `max-age`, and the language construct that expresses "not installed". Python
expresses it by not calling `add_middleware`; Rust expresses it by not calling
`Router::layer`. These are one policy in two type systems, not a shared low-level value,
and **no shared low-level value is recommended**: none is an owner requirement, and the
two ecosystems' defaults genuinely differ, so a shared constant would be wrong in one of
them.

**Observable acceptance criteria**, numbered so each binds to an executed check:
criteria 1–6 in `review/evidence/probe-checks.log`, criterion 7 in
`review/evidence/rest-conformance-r2.log`.

| # | Criterion | Executed as |
|---|---|---|
| 1 | With the allowlist empty, a `GET` carrying `Origin` returns no `access-control-allow-origin` **and no `vary`** | check `A` |
| 2 | With the allowlist empty, an `OPTIONS` preflight to a `GET`-only route returns `405 Method Not Allowed` | check `Q1` |
| 3 | With the allowlist holding `https://app.example`, a `GET` from that origin echoes it back | check `C` |
| 4 | With that allowlist, a `GET` from a different origin receives no `access-control-allow-origin` | check `D` |
| 5 | With that allowlist, a preflight on a `GET`-only route returns `200` carrying `access-control-max-age: 600`, and the handler is not invoked | checks `E` and `R1` |
| 6 | A syntactically invalid origin string fails at construction, before the listener binds | check `H` |
| 7 | With that allowlist, a `GET` from the allowed origin carries `access-control-expose-headers` naming every standard-bound response header the service emits, `request-id` among them | check `X1` (added in revision 2 for R4.17) |

If the owner refuses `OVERRIDE (OV-08)`, an eighth criterion joins these: a preflight
from the allowed origin carries the same expose list, naming `allow` and `request-id`
(check `X10`).

**Architectural alternatives compared before any library was chosen.** The prompt's second
HIGH question asks for exactly this comparison, so the wrapper and the hand-rolled forms
are answered on evidence rather than dismissed. Both research reports compared the same
three core shapes (conditional branch, always-installed, hand-rolled) and reached the same
verdicts on them.

| # | Alternative | Verdict and the ground for it |
|---|---|---|
| **A** | `CorsLayer` installed by a plain `if !origins.is_empty()` branch in the composition root | **Selected.** All seven criteria executed green. Adds two crates to R69's accepted graph. The conditionality itself costs no dependency, because `Router::layer` is type-preserving |
| **B** | `CorsLayer` installed unconditionally, configured with an empty allowlist when none is set | **Rejected on measured behaviour.** Fails criteria 1 and 2: `vary: origin` appears on every response and `OPTIONS` on a `GET`-only route becomes `200` instead of `405`. It remains the **ranked runner-up on the mechanism axis**, because it is the only alternative that keeps the recommended crate, adds no dependency and removes a branch |
| **C** | A conditional-layer *wrapper*: `tower::util::option_layer` or `axum_extra::middleware::option_layer` | **Rejected on cost with no benefit, and the cost is stated precisely.** It adds no crate and no feature to the resolved graph — this run measured that `axum` 0.8.9 **already activates** `tower`'s `util` feature. Its actual price is a **direct `tower` dependency declaration** on `crates/web`, moving `tower` out of the dev-dependency slot R69 fixed, so that `tower::util::option_layer` is nameable from non-test code. Both wrapper forms exist to solve a *type* problem — two branches producing different service types — that `Router::layer` does not have. The `axum-extra` form additionally carries a pending 0.9 `option_layer` body-type break that the owner reference itself flags (`inputs/owner-reference-axum-companion-stack-2026-09-16.md:36`, Key Finding 1) |
| **D** | Hand-roll the layer with `axum::middleware::from_fn` | **Rejected.** It saves two crates and ~166 kB and costs a from-scratch implementation of origin matching, the preflight short-circuit, `Vary` correctness, `max-age` and the credentials/wildcard interaction — security-relevant code a *template* should not ship hand-written, and whose last item `tower-http` encodes as an explicit runtime assertion precisely because getting it wrong is easy |
| **E** | Terminate CORS at a reverse proxy or gateway | **Rejected on fit.** The template must run under `cargo run` and be testable in-process through `ServiceExt::oneshot`, R69's fixed idiom. A gateway-only policy is untestable at that seam and unavailable to a template user with no gateway |
| **F** | Serve browser assets same-origin so CORS is never needed (owner reference, line 87) | **Agreed with in principle; not applicable in fact.** R69's `web-extra-surface` contains no static-asset or SPA head — the gated tree is `AppState`, `build_router`, route modules, handlers, `shutdown_signal` and `serve_until`. An API-only surface consumed by a browser front end elsewhere is exactly the case CORS exists for |
| **G** | A `loco`-style middleware registry: a `MiddlewareLayer` trait with `is_enabled()`, filtered before application | **Rejected as disproportionate here; handed to R75.** `loco-rs/loco` (9,267 stars, `pushed_at 2026-09-24T11:26:24Z`, both 2026-09-27) does exactly this, and this run read the two source lines that prove it. It is the right shape for loco's ten-plus independently switchable middlewares. This template has one conditional layer today. If R75's stack lands with three or more independently gated layers, this becomes the right refactor, and R75 owns that call |

**How py's behaviour differs from `tower-http`'s, and which difference is worth importing.**
Read from Starlette 1.3.1 — the version `py-launch-blueprint` locks at pin `b08bccfb` —
against `tower-http-0.7.1/src/cors/`.

| Behaviour | py, as it configures Starlette | `tower-http` 0.7.1 | Disposition |
|---|---|---|---|
| Allowed origins | explicit list from settings | `AllowOrigin::list(iter)`, a runtime iterator | equivalent; nothing to change |
| Allowed methods and headers | `["*"]` | `Any` → the literal `*` | cosmetically different header text, identical permission |
| Credentials | off by default | off unless asked; asking alongside a wildcard panics | agree on the default; the panic is documented as a trap for whoever exposes the knob |
| `Access-Control-Max-Age` | `600`, always emitted | absent unless `.max_age(...)` is called | **imported.** `.max_age(Duration::from_secs(600))` is in the recommendation and is compiled and measured here |
| `Vary` on a simple response | added only when the origin is allowed | derived from which CORS headers are request-dependent, so `vary: origin` on every response under the recommended configuration | a justified ecosystem difference; `tower-http` is the more cache-correct of the two. Parity is not chased |
| Preflight trigger | `OPTIONS` **and** an `access-control-request-method` header | **any** `OPTIONS` request | the cause of alternative B's failure on criterion 2 |
| Disallowed preflight | `400` with a diagnostic body | `200` with the CORS headers simply absent | a justified difference; both are spec-legal, since the browser enforces the policy. Not worth reimplementing |

**Where a different ecosystem needs a different design.** Python's `add_middleware` takes a
class and keyword arguments, so py's conditional is a statement. Rust's layer is a value
with a type, so the natural Rust form is a re-binding `if` over a `Router` — which works
only because `Router::layer` is type-preserving; had it not been, alternative C's wrapper
would have been forced, and that is why axum publishing a `0.9` is a re-verify trigger.
Under actix-web the same policy would read `if !allowlist.is_empty() { app = app.wrap(cors) }`,
which is the shape the Muse report records for its conditional runner-up. TypeScript, if a
web surface is ever added there, faces the same choice in Hono's `app.use()` form and
should take the same policy — skip the `use` call rather than install a
permissive-but-empty middleware. That is the follow-on project's rationale, recorded here;
no change is made to py or ts by this decision.

**Reference implementations, and why each counts as practice evidence.** `tower-http` has
**3,532** reverse dependencies on crates.io (`GET
https://crates.io/api/v1/crates/tower-http/reverse_dependencies`, `meta.total`,
2026-09-27). Three well-regarded projects were shown activating **this exact feature** by
reading the manifest line rather than asserting it: `tokio-rs/console` (4,604 stars,
2026-09-27; the Tokio project's own diagnostics tool) at
`console-subscriber/Cargo.toml:65`; `tonic-web` (the gRPC organisation's Rust
implementation, where gRPC-Web *requires* CORS, so the use is load-bearing) at
`Cargo.toml:31`; and axum's own maintained example at `examples/cors/Cargo.toml:10`. A
fourth, `rust-lang/crates.io`, does not use the `cors` feature — the registry is
same-origin — but pins `tower-http` at `=0.7.1` in production, which is the strongest
available evidence that the 0.7 line is shippable. `loco-rs/loco` supplies the
config-gated-middleware pattern and the `.max_age` call this decision imports.

**Maturity, dependability and representative performance.** `tower-http` has **39**
published versions, **33** non-yanked, and is maintained in the `tower-rs` organisation
alongside `tower` itself; **918** stars, `archived: false`, `pushed_at
2026-09-26T12:33:00Z`; **32** open issues by the prompt's required `search/issues`
`total_count` field (all 2026-09-27). Maintenance state: **active** — a release 27 days
before retrieval and a push one day before it. Issue responsiveness was **recomputed** on
2026-09-27 from a new field-projected snapshot
(`review/evidence/snapshots/tower-http-issue-triage-2026-09-27.json`) over the rubric's
window, the ten most recently opened non-pull-request issues (`#741` back to `#701`). By
`author_association`, not by name, **two** carry a maintainer comment — `#713` after
**0.05 h** and `#702` after **4.55 h**, a median over that answered subset of **2.30 h** —
and **eight** carry none, of which **two** were nonetheless closed and **one** (`#725`) was
opened by a maintainer. A single median across all ten would be an invention, so the
figures are reported separately. The fetched comment page reaches back to `2026-05-22`,
before every issue in the window, so each absence is measured. The five newest issues
(`#741`, `#740`, `#737`, `#736`, `#732`, opened 2026-09-01 to 2026-09-25) have no
maintainer reply yet, which is the Muse report's observation over its narrower window.
This is a quiet-but-live triage pattern; it does not reach the rubric's `at-risk` bar,
which requires a concrete signal. Representative performance: the layer adds one
`HeaderMap` construction per request and, on a matched CORS request, up to four header
insertions; the preflight path avoids calling the inner service entirely. **No latency or
throughput benchmark was run and none is cited**, so no performance figure is claimed
beyond the measured byte cost. When the allowlist is empty the layer is absent, so the
cost is exactly zero.

**Reconciliation with the owner-supplied reference architecture** (standing input,
`docs/planning/p02/owner-decisions.md` §11), row by row for the rows this item touches.
Each position was re-checked against this run's own evidence rather than carried.

| Reference row | Position | Ground |
|---|---|---|
| Line 80, "Level One — what Axum + tower-http already give you (don't add crates for these)", listing `CorsLayer` | **Agree** | This item adds no CORS crate beyond `tower-http`, and enumerating the category found no maintained tower-native alternative to add |
| Line 141, the single `tower-http` dependency line with `"cors"` in its feature list | **Agree on the feature, differ on the version** | The feature name is right and this item contributes exactly `"cors"`. The version is stale against the registry this run read: 0.7.0 shipped 2026-06-15 and 0.7.1 on 2026-08-31, both before the reference's own date, and `rust-lang/crates.io` pins `=0.7.1`. The differ rests on those sourced release facts, and on the measured finding that the 0.6→0.7 `cors` change narrows the `Vary` value and alters nothing else |
| Line 114, the recommended layer order placing `CorsLayer` between `CatchPanicLayer` and `NormalizePathLayer` | **Differ on the *unconditional* framing; the position itself is R75's** | The reference lists `CorsLayer` as an always-present stack member. This item installs it only when the allowlist is non-empty, on the two observables measured above. Where it sits **when present** is F317's and is not decided here |
| Lines 49, 87 and 421, Variant B's "serve the SPA from the same Cloud Run service … no CORS" | **Agree in principle; not applicable to R69's surface** | See alternative F |

Tally over the four rows: **1 agree** · **1 agree on the feature and differ on the
version** · **1 differ** · **1 agree in principle but not applicable**.

**The category, enumerated rather than recalled.** The decision is not "a CORS library" in
the abstract; it is *which artifact supplies the Fetch-standard CORS response algorithm to
the HTTP service R69 fixed, and by what mechanism it is kept out of the request path when
no origins are configured.* CORS is defined by the WHATWG Fetch Standard §3.2, and in the
axum world a middleware layer is a `tower::Layer`. That fixes the category and the fit
every candidate must meet; the six fitness gates are applied separately.

| Bin | What the enumeration found |
|---|---|
| **Built-in / first-party toolchain** | `tower-http`'s `cors` feature, maintained in `tower-rs` — the same organisation as `tower`. axum ships **no** CORS of its own and its maintainers' own example reaches for `tower-http` |
| **Established industry standard, framework-bound** | `actix-cors` 0.7.2 (actix-web's first-party crate), `rocket_cors` 0.6.0, `salvo-cors` 0.96.0, `ntex-cors` 4.0.0, `routerify-cors` 3.0.0, `trillium-cors` 0.1.0, `corsware` 0.2.0 and `iron-cors` 0.8.0 (both Iron, pre-async). Each implements a different framework's middleware trait; none exposes a `tower::Layer` |
| **Up-and-comer** | `tower-http-cors-config` 0.1.3, `hyper-cors` 0.2.0, `axum_cors` 0.1.8, `rok-cors` 0.1.0, `cors-core` 0.1.1, `axum-stack` 0.2.0, `bunner_cors_rs` 0.1.2, `blazingly-middleware` 0.2.2, `lily_middleware` 0.1.0, `apollo-cors` 0.4.0, `toxi-middleware` 3.1.1, `volter-middleware` 0.1.0, `rok-guard` 0.6.0, the `corx` family, and `vary-header` 0.1.0 — all with four-figure-or-smaller download counts, most of them two- or three-figure |

The enumeration is reproducible: `GET https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads`
plus its `&page=2` returns **36** crates and this run read **all 36**, printing every name
with its figures into `registry-figures.log`; `GET https://crates.io/api/v1/crates?q=cors&per_page=40`
reports **1,476** name matches (2026-09-27), of which the 40 highest-ranked were read as a
cross-check. `tower-http` appears on neither keyword page — its name does not contain
"cors" and it does not carry the keyword — which is asserted rather than assumed, and is
why it had to be reached from the axum side.

**Excluded by gate, or by fit or scope — every one of the 36 dispositioned.** Gate numbers
are the prompt's. **Revision 3 correction:** revision 2 excluded `actix-cors` and the other
framework-bound crates "on gate 5". Gate 5 asks that default features and runtime coupling
be *stated*; it is a disclosure gate, not a disqualifier. Those crates are now excluded on
**fit** — none can attach to R69's axum service — and `actix-cors`, whose gates were
evaluated one by one, is on the qualified shortlist.

- **Excluded by gate 2 (MSRV):**
  - **`axum_cors` 0.1.8**, **`rok-cors` 0.1.0**, **`cors-core` 0.1.1**,
    **`tower-http-cors-config` 0.1.3** — `rust_version` is `null` for each, asserted at the
    versions endpoint. Under the owner's recorded reading
    (`docs/planning/p02/owner-decisions.md`, "an unknown version is insufficient to clear a
    bar the prompt says must be cleared") an undeclared MSRV is a failure, not merely
    unproven. `tower-http-cors-config` is additionally not an alternative: it supplies
    `serde`-deserializable config *types for* `tower_http::cors`, so it presupposes this
    recommendation rather than competing with it, and it is the most *interesting* crate in
    the group — **watch, do not adopt**, and revisit if R77's settings shape ever grows
    beyond a `Vec<HeaderValue>`.
  - **`lily_middleware` 0.1.0** — fails gate 2 the other way: it declares
    `rust-version = "1.96.1"`, **above** the 1.96 floor. It is also bound to the Lilyrs
    framework.
- **Excluded on integration fit — a substrate-compatible but unproven alternative:**
  **`hyper-cors` 0.2.0**, which has no direct axum layer (untested Hyper-boundary adapter
  path; 41 downloads, 0 dependents). This run measured two facts about it. Its declared
  `rust-version = "1.80"` is inside the floor, at crate level only (`registry-figures.log`
  section C). Its published dependency list is `bytes, http, hyper, itoa, pin-project-lite`
  — **no `tower`, `tower-layer` or `tower-service`** (section D) — because it implements
  `hyper::service::Service`, not `tower_layer::Layer`, so `axum::Router::layer` cannot
  take it. It shares this stack's Hyper 1.x substrate, and the S53 technology-fit brief
  W53H (retrieved 2026-09-27 UTC, cited read-only) names the one route in: wrapping the
  axum service with `hyper_util::service::TowerToHyperService` at the Hyper serving
  boundary, a path that brief did not compile or test. The same brief is the source for
  `unsafe_code = "deny"` in the published manifest, a CI matrix of `ubuntu-latest` and
  `macos-latest`, and 0 reverse dependencies (`GET
  https://crates.io/api/v1/crates/hyper-cors/reverse_dependencies`, `meta.total`). The 41
  downloads, 90-day and all-time, are also this run's own figure (`registry-figures.log`
  section B), and W53H confirms them at `crate.downloads`. Its remaining gates were not evaluated to the locked-tree standard applied
  to `actix-cors`, whose gates were run one by one to settle Muse disagreement 2, so
  `hyper-cors` is not claimed gate-passing and is not on the qualified shortlist.
- **Excluded on framework fit; gates not evaluated beyond stating gate 5** — adopting one
  means adopting its framework beside R69's axum, whatever its gate results, so gates 2–4
  and 6 were not run for these and are recorded as *not evaluated* rather than passed:
  **`rocket_cors` 0.6.0** (Rocket; it also carries a concrete `at-risk` signal — no push to
  `lawliet89/rocket_cors` since `2023-11-20T00:42:55Z` and issue `#118`, opened 2024-11-16,
  still open with zero comments, per `muse-adjudication.log` section D), **`salvo-cors`
  0.96.0**, **`ntex-cors` 4.0.0**, **`routerify-cors` 3.0.0**, **`trillium-cors` 0.1.0**,
  **`iron-cors` 0.8.0** and **`corsware` 0.2.0** (the last two target Iron, whose last
  release predates the async ecosystem entirely). Likewise the framework-bound middleware
  bundles `reinhardt-middleware` 0.3.20 (Reinhardt), `elif-security` 0.2.2 (elif.rs),
  `armature-security` 0.4.0 (Armature), `oxidite-middleware` (Oxidite; no stable release
  at all), `htmstd` 0.8.6 (Hotaru), `rocket_ext` 0.3.1 (Rocket),
  `fandhe-backend-plugin-cors` 0.4.1 (fandhe-backend), `rok-guard` 0.6.0 (rok),
  `blazingly-middleware` 0.2.2 (Blazingly), `toxi-middleware` 3.1.1 (Toxi),
  `volter-middleware` 0.1.0 (volter), `apollo-cors` 0.4.0 (Apollo) and `bunner_cors_rs`
  0.1.2 (Bunner). Each is a young framework's own middleware set; none exposes a
  `tower::Layer` for axum, and each carries two- or three-digit download counts. Versions
  are as enumerated on 2026-09-27; four moved since revision 2's enumeration.
- **Excluded on scope, not on a gate** — `tauri-plugin-cors-fetch` 5.0.0 and
  `tauri-plugin-better-cors-fetch` 1.8.0 relax CORS inside a **Tauri desktop webview**, a
  client-side problem; `pdk-cors-lib` 1.10.0 is a policy library for an API-gateway policy
  development kit; `warp-cors` 0.3.0, `cors-proxy` 1.0.2, and the `corx` family
  (`corx` 0.2.0, `corx-core` 0.2.0, `corx-server` 0.2.0) are **forwarding proxies** — a
  standalone process that adds CORS headers to a third-party upstream, a different
  artifact from a layer inside this service; `wasm-dev-server` 0.1.1 and `just-serve`
  0.1.0 are static development servers; `vary-header` 0.1.0 manipulates the `Vary` header
  and implements no part of the CORS protocol; `axum-stack` 0.2.0 is a grab-bag
  ("shutdown, CORS, request ID, health routes") that would pull one opinionated bundle
  across four of this programme's independently-researched items.

**Two candidates passed every gate evaluated; one fits.** The prompt allows up to five. The
qualified shortlist is `tower-http` and `actix-cors`, which is also the Muse report's
shortlist. Only `tower-http` can attach to R69's axum service, because "a CORS middleware
for axum" and "a CORS middleware for tower" are the same artifact.

| name | role | 90-day downloads | all-time downloads | stars | last release | maintenance state | notable adopters | one-line trade-off |
|---|---|---|---|---|---|---|---|---|
| `tower-http` (`cors` feature) | the `tower::Layer` implementing the Fetch CORS protocol for any `tower`/`hyper`/axum service | **155,482,963** | **479,378,847** | **918** | **0.7.1**, `2026-08-31T14:49:25.697237Z` | **active** | `tokio-rs/console`, `tonic-web`, `loco-rs/loco`, `rust-lang/crates.io`; 3,532 reverse dependencies | you take a 35-feature middleware crate for one of its features, and a future advisory against a module you never enable will still surface in `cargo audit` output and need triage |
| `actix-cors` | actix-web's first-party CORS middleware (`App::wrap`) | **2,914,000** | **21,295,772** | **890** (the whole `actix/actix-extras` monorepo, not this crate alone) | **0.7.2**, `2026-08-24T14:19:03.269184Z` | **active** (monorepo `pushed_at 2026-09-25T17:07:10Z`) | 214 reverse dependencies; the actix-web ecosystem's own crate | the right answer for an actix-web service, and unusable here: `App::wrap` middleware cannot attach to axum's `Router`, and adopting it adds actix-web and `actix-rt` beside R69's stack |

Figures: downloads from `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`); release from `.../versions` (newest with `yanked: false`); stars,
`archived` and `pushed_at` from `GET https://api.github.com/repos/<owner>/<repo>`;
`tower-http`'s open issues from `GET https://api.github.com/search/issues?q=repo:tower-rs/tower-http+is:issue+is:open`
(`total_count` — the repository's own `open_issues_count` reads **40** and is deliberately
not used, because it counts pull requests); `actix-extras`'s open issues **16** by the
same field, for the whole monorepo. All retrieved **2026-09-27** UTC
(`registry-figures.log` for `tower-http`, `muse-adjudication.log` for `actix-cors`).

**`actix-cors` 0.7.2, gate by gate** (`muse-adjudication.log`, section C). Gate 1:
inapplicable, as for every candidate. Gate 2: `rust_version` 1.88, and its locked tree of
110 packages declares at most 1.88.0 (`time-macros`) — inside the 1.96 floor. Gate 3: no
RustSec page (`404`, with the `atty` control answering `200`); `#![forbid(unsafe_code)]`
at `actix-cors-0.7.2/src/lib.rs:53` and no `unsafe` block. Gate 4: `actix/actix-extras`
CI runs Linux (`ubuntu-latest`) and macOS/Windows jobs, each with test steps, and an MSRV
job on 1.88.0. Gate 5, stated: one optional feature (`draft-private-network-access`);
required dependencies include `actix-web`, and the tree carries `actix-rt` 2.15.0 and
`tokio` 1.53.1 — actix's executor model beside R69's axum. Gate 6, qualitatively: a second
complete HTTP framework, so a large binary and compile cost relative to `tower-http`'s two
crates. It passes every gate and fails fit.

**Ranked runner-up, on each of the two axes this item decides.**

- **Mechanism axis — alternative B**, unconditional installation with an empty allowlist.
  It wins if the owner or R75 rules that an unconditional `Vary: Origin` and a `200`
  answer to every `OPTIONS` are desirable (re-verify trigger 9).
- **Crate axis — `actix-cors` 0.7.2**, with the same conditional branch (`app.wrap(cors)`
  only when the allowlist is non-empty). It wins if and only if R69 is republished with
  actix-web, or any other framework whose middleware model cannot take a `tower::Layer`
  (re-verify trigger 1). This is the Muse report's runner-up and its condition, adopted.

**Fit for this template, surface by surface.**

- **CLI — no effect, and that is the point.** R05 revision 3 fixes a synchronous core and a
  CLI binary with no executor in its default dependency tree. Under R69 revision 11
  `tower-http` is a dependency of the optional `crates/web` member only, so a default
  `cargo build` never resolves, downloads or compiles it. The differential resolution
  measures this from the other side: the two crates land on the **web** graph.
- **Library — no effect.** R02 revision 2 fixes a four-package workspace in which
  `crates/web` depends on `core` and `core` depends on neither front end. The CORS layer is
  an HTTP-transport concern living entirely on the far side of R01's port, so
  `crates/core`'s external-dependency allow-list is untouched and R02's
  `tests/workspace_edges.rs` guard keeps passing unamended.
- **Web — the whole surface this touches.** One module in the gated tree, one call in
  `build_router`, one dependency line, one environment variable named by R77, and the seven
  acceptance criteria exercised through the in-process `ServiceExt::oneshot` idiom.

**Tradeoffs, against each alternative in turn.** Versus the mechanism runner-up
(unconditional installation with an empty allowlist): given up is a branch-free
composition root, one fewer thing for a template reader to understand, and `Vary: Origin`
on every response, which is genuinely the more cache-correct default. Accepted, because
`F322`'s recorded principle is absence, and because the `OPTIONS` change is not cosmetic.
Versus the crate runner-up, `actix-cors`: given up is portability to an actix-web service.
Accepted, because R69 fixed axum, and `actix-cors` would bring a second HTTP framework and
executor model into a stack that already has one. Versus the `option_layer` wrapper: given
up is a uniform, declarative way to say "maybe this layer" that would compose well if more
optional layers appear. Accepted, because today there is exactly one, and paying for it
means moving `tower` out of the dev-dependency slot R69 fixed for zero behavioural gain.
Versus a hand-rolled `from_fn`: given up is two crates and ~166 kB, all measured, all
small. Accepted, because what is bought is a spec-conformant, `deny(unsafe_code)`,
advisory-clean implementation of a browser security protocol used in production by the
Tokio project, the gRPC organisation and the Rust project's own registry — and because a
template that hand-rolls CORS teaches every one of its users to hand-roll CORS. Versus the
other framework-bound crates: given up is nothing this template can use. Versus a
same-origin deployment: given up is the simplest possible answer, which is not available,
because R69's surface ships an API with no front end attached to it.

**Accepted residual risks, named rather than hidden.** (a) `tower-http` is a 35-feature
crate and this item uses one; an advisory against an unused module would still appear in
`cargo audit` output and need triage. (b) `CorsLayer` *panics* when `allow_credentials(true)`
is combined with any wildcard; the recommended configuration never sets credentials, but
if a later item exposes that knob the panic must be converted to a boot-time error the way
`loco` does. (c) The mechanism rests on one fact — `Router::layer` being type-preserving —
so an axum `0.9` re-opens it; that is a re-verify trigger below, not a hidden assumption.
(d) CORS preflight responses carry no expose list; that is `OVERRIDE (OV-08)`, pending the
owner's ruling.

**What P03 must validate, beyond what this run executed**, is listed under `## Engines`.

**Migration implications — file-level changes in the template**, using R69 revision 11's
paths (see `## Parameters` for the standing of that value against the live registry row).

| File | Change |
|---|---|
| `crates/web/Cargo.toml` | add one `[dependencies]` line: `tower-http = { version = "0.7.1", default-features = false, features = ["cors"] }`. Non-optional, because the member itself is what the root's `web` feature gates. R75 may extend the `features` array; it must not remove `"cors"` |
| `Cargo.lock` | two new entries, `tower-http 0.7.1` and `bitflags 2.13.2`. Nothing else moves |
| `crates/web/src/cors.rs` | **new**, about 30 lines: the `apply_cors` function shown above, with the doc comment that states the empty-allowlist contract and the R4.17 obligation on `exposed_headers` |
| `crates/web/src/lib.rs` | one `mod cors;` declaration |
| `crates/web/src/` composition root (R69's `build_router`) | one call site. Whether it reads `apply_cors(router, &settings.cors_origins, &exposed_headers)` or an inlined `if` is P03's taste; the branch is the decision. The `exposed_headers` argument is assembled by R75 from the layers it installs |
| R77's settings type | one field carrying the allowlist. Named and typed by R77; this item states only that it must reach the composition root as a possibly-empty ordered collection of `HeaderValue` and must fail at boot on an unparseable entry |
| `crates/web/tests/` | one new integration test file carrying criteria 1–7, written against the `ServiceExt::oneshot` idiom, needing no new dev-dependency |
| Documentation | one row in the template's environment-variable table, stating that an empty allowlist means the middleware is not installed; and the conformance note's OV-08 Deviations line, as handed over above |
| CI | **none.** Path-based skip-gating already keys on `crates/web/**` per R69 revision 11; no new job, no new tool, no new runner |

**Not changed:** the root package's `Cargo.toml`, `crates/core`, `crates/cli`, R01's port,
R02's `tests/workspace_edges.rs` allow-list, and the CLI binary's dependency graph. If the
owner refuses OV-08, R75's stack gains the option-2 stamp and `crates/web/tests/` gains
criterion 8; no other file changes.

re-verify: on the earlier of 2027-03-27 or any of these events — (1) **R69 republishes** `web-extra-surface` with a value other than revision 11's, because every file path above and the `- assumes` line come from revision 11 (sha256 `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`), whose owned value was set at revision 10 under owner ruling W1-R02 and is adopted here ahead of the registry under owner decision Q3.A (flag day), and a published value that differs moves all of them — and if it names actix-web or any framework whose middleware cannot take a `tower::Layer`, the crate-axis runner-up `actix-cors` wins; (2) **R75 publishes**, since it fixes this layer's ordering and the aggregate `tower-http` feature list, and must read the 0.7.0 breaking entries itself for whatever features it adds; (3) **R77 publishes**, fixing the variable name and the parsed type this item consumes as a possibly-empty `Vec<HeaderValue>`; (4) **R02 publishes** a topology other than the four-package workspace this design is written against; (5) `GET https://crates.io/api/v1/crates/tower-http/versions` reports a newest non-yanked `num` outside `0.7.x`, since a `0.8` needs its changelog read for `cors` changes; (6) `https://rustsec.org/packages/tower-http.html` acquires a third entry or `RUSTSEC-2022-0043`'s `patched` range changes — re-run `review/evidence/registry-figures.sh`, whose `atty` control distinguishes a site change from a cleared advisory; (7) `GET https://api.github.com/repos/tower-rs/tower-http` reports `archived: true`, or `pushed_at` falls more than twelve months behind; (8) **axum publishes `0.9`**, which re-opens whether `Router::layer` is still type-preserving — the single fact the conditional branch rests on; (9) the owner or R75 rules that an unconditional `Vary: Origin` and a `200` answer to every `OPTIONS` are desirable, which is the stated condition under which the mechanism-axis runner-up wins; (10) `msrv-policy`'s floor advances past **1.96**, the number gate 2 was evaluated against here, or a dependency in the locked tree declares a `rust-version` above the floor — re-run `review/evidence/probe-checks.sh` after refreshing its lockfiles with `R76_RECORD_LOCKS=1`; (11) the **REST API Design Standard** moves off blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` — re-run `review/evidence/rest-conformance-r2.sh`, whose blob-size and line-count assertions fail closed when the pinned object is not the one quoted, and re-read R4.17, R4.11, R5.11 and R11.7 at their new lines; (12) **R75 publishes** its layer order or its `expose_headers` list, since R11.7's ordering constraint and R4.17's list are both satisfied by R75's choices and only stated by this item; (13) **the owner rules on `OVERRIDE (OV-08)`** — approval leaves this decision as written, refusal adopts option 2 (the measured outermost stamp, checks `X10` and `X11`) and adds criterion 8; (14) the WHATWG Fetch Standard changes the three sentences OV-08's Argument rests on, two quoted and one paraphrased — re-run `rest-conformance-r2.sh`, whose section G asserts them.

## Parameters

This item **owns no parameter**: `inputs/prompt.md`'s `## Couplings` block carries an empty
`- owns:` line and `docs/port/PARAMETERS.md` registers no row owned by R76, so this
decision writes no `- owns` line. Inventing a registry row would be a registry edit, not a
research finding. Its `- consumes:` line is empty too; the six values below are the four
owner-fixed parameters plus the two researched values this design actually rests on, each
quoted byte-identically from the live registry (compared again on 2026-09-27 by
`decision-self-check.sh` section B). The Muse report's three `- assumes` lines name
parameters that are not registry rows and are not carried forward; see `## Engines`, Muse
disagreement 5.

- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on the root package rs-launch-blueprint; web = ["dep:rs-launch-blueprint-web"], with axum 0.8.9 declared non-optionally in crates/web/Cargo.toml and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 declared non-optionally in crates/web/Cargo.toml with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is crates/web's dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module crates/web/src/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests in crates/web/tests/, with no file-level #![cfg(feature = "web")] because the whole member is optional, and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated crates/web/src/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on crates/web/**, the serve binary's source file and the web test files
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**Standing of the `web-extra-surface` line, and why it is not a `CONFLICT:`.** The bytes
above are R69 **revision 11**'s owned value (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, sha256
`2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`, its `- owns web-extra-surface` line at line 1885), with only the `- owns` prefix
swapped for `- assumes`. That value was set at R69 revision 10 by owner ruling W1-R02 and
did not move at revision 11; owner decision Q3.A adopts it now, as a flag day, ahead of
the registry row, which until R69 republishes still carries revision 9's form — the gated
tree at `src/web/`, `web = ["dep:axum", "dep:tokio"]`, and `tower` as the declaring
package's dev-dependency. Revision 11 moves the web tree into the optional workspace member
`crates/web`: `web = ["dep:rs-launch-blueprint-web"]` on the root package, `axum` 0.8.9 and
`tokio` 1.53.1 declared **non-optionally** inside `crates/web/Cargo.toml`, `tower` 0.5.3 as
`crates/web`'s dev-dependency, the gated tree reading `crates/web/src/`, tests in
`crates/web/tests/`, and skip-gating keyed on `crates/web/**`. **This decision's design
uses those paths** — `crates/web/src/cors.rs` and `crates/web/Cargo.toml` — and the
`- assumes` line now names them too. R69's republication is recorded as re-verify
trigger 1. This is deliberately **not** a `CONFLICT:`: nothing in this recommendation
needs R69's value changed.

**How the other five bear on the decision.** `msrv-policy` is what turns stable `rustc`
1.98 into the **1.96** floor that gate 2 was evaluated against, over the whole resolved
tree and not just the recommended crate. `rust-edition` is the edition the probe crates
declared throughout, so every behavioural result above was observed under `2024`.
`target-os-matrix` is what makes `RUSTSEC-2022-0043`'s `os = ["windows"]` scope
irrelevant here and what upstream CI's `macos-latest` and `ubuntu-latest` jobs satisfy;
it is also why no Windows behaviour was exercised. `license` is recorded and, per the
owner ruling of 2026-09-12 (Q7.B), evaluated against nothing — the gate-1 row under
`## Decision` carries the required `inapplicable` string and its reason.
`error-taxonomy-exit-codes` supplies the code for acceptance criterion 6: an unparseable
allowlist entry is an invalid config value, which R67's catalog maps to `RSLB203` and exit
code `2`. This item consumes that mapping and adds no catalog row.

`CONFLICT:` lines: **none.** No consumed parameter has to change for this recommendation
to hold.

## Empirical check

**Toolchain and host.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4, `arm64`, 2026-09-27.
`gh version 2.101.0 (2026-09-15)`, `curl 8.7.1`, `jq-1.8.2`,
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` — invoked throughout as `/usr/bin/grep`
by absolute path, and its version is printed at the top of every log. The toolchain is
not pinned by a `rust-toolchain.toml`; the byte sizes and the resolved tree are stated as
bound to this toolchain and to the committed lockfiles.

**Working directory for every script:**
`research/runs/R76/2026-09-17T034010Z-d958540e8834/review/evidence/`.

**Commands executed, and their status.**

```
./registry-figures.sh    > registry-figures.log    2>&1   # exit 0, RESULT: PASS, 56 assertions, 0 SKIP
./probe-checks.sh        > probe-checks.log        2>&1   # exit 0, RESULT: PASS, 29 assertions, 0 SKIP
./muse-adjudication.sh   > muse-adjudication.log   2>&1   # exit 0, RESULT: PASS, 27 assertions, 0 SKIP
./decision-self-check.sh > decision-self-check.log 2>&1   # exit 0, RESULT: PASS, 73 assertions, 0 SKIP
./rest-conformance-r2.sh > rest-conformance-r2.log 2>&1   # exit 0, RESULT: PASS, 66 assertions, 0 SKIP
```

The last two read this document, so they ran last, against these final bytes; each
prints `sha256(DECISION.md)` in its log header (finding F4). `rest-conformance-r2.sh`
section E runs `decision-self-check.sh` again inside itself and asserts that it passes.

**What revision 4 changed in the scripts.** `rest-conformance-r2.sh`: the probe's
stand-in list `EXPOSED` gains `allow` beside `request-id`, and option 2's stamp now builds
its value from that same constant, so there is one list; the `X1`, `X9`, `X10` and `X11`
expectations and the `X10` assertion message follow (EA-1). The assertion count is
unchanged at 66. `decision-self-check.sh`: its H1 literal names revision 4, a consequence
of this revision's title rather than of a finding. Both logs were re-recorded against
these bytes; the other three scripts and logs are unchanged from revision 3.

**What revision 3 changed in the scripts, and why.** Revision 2 kept the three revision-1
scripts byte-identical. Revision 3 does not, because the audits found faults in them:

| Script | Change | Finding |
|---|---|---|
| `probe-checks.sh` | every arm copies a committed lockfile (`snapshots/probe-{with,v06,without}.Cargo.lock`) and every cargo call carries `--locked`; `CARGO_TARGET_DIR` and `CARGO_BUILD_TARGET_DIR` are unset; the gate-2 assertion is `≤ 1.96` by numeric comparison; byte sizes are figures bounded by assertions | F1, F2, F3 |
| `registry-figures.sh` | section G asserts `tower-http`'s preflight/non-preflight split at `mod.rs:715` and `:728`–`729`; section H resolves `rust-lang/crates.io`'s default branch to a commit and reads `Cargo.toml` at it | JA-2, F5 |
| `rest-conformance-r2.sh` | X4's assertion states what the preflight carries; `X10`/`X11` measure OV-08's option 2; axum's `Allow` source lines are read; section D asserts the OV-08 block and the Deviations line; section E asserts that the self-check passes; section F asserts OV-08 as this decision's only override; new section G reads the Fetch Standard; the header prints the decision's sha256; the probe builds `--locked` | JA-2, F4 |
| `decision-self-check.sh` | re-targeted at revision 3: title, engine record for both reports, dated figures, and a new section G that resolves every `path:line` citation in this document | JA-1, JA-3, F5 |
| `muse-adjudication.sh` | **new**: the evidence for each Muse disagreement | JA-1 |

The F3 repair was verified in the condition that exposed it: this host exports
`CARGO_TARGET_DIR` to every command, and `probe-checks.sh` ran to `RESULT: PASS` under it.
The lockfiles were written once with `R76_RECORD_LOCKS=1` (and
`snapshots/actix-cors-probe.Cargo.lock` plus the new triage snapshot with `R76_RECORD=1`),
then every log above was produced by a normal run that reads them. The record run and the
normal run of `probe-checks.sh` produced the same stripped sizes, 502,264 and 668,728
bytes.

Each script sets `set -euo pipefail` at the top, so a failing command inside a pipeline
cannot be masked by a succeeding one. Each asserts on **content**, never on an exit code
alone, and each prints `PASS=`, `FAIL=` and `SKIP=` counts that sum to its total and exits
non-zero on any `FAIL`. Every `SKIP` branch names its reason; none was taken in the runs
cited above, which is recorded as `SKIP=0` rather than left implicit. **On `.git`
dependence:** `registry-figures.sh`, `probe-checks.sh` and `decision-self-check.sh` need no
`.git`. `muse-adjudication.sh` section A reads this repository's `research/` and `docs/`
files but not its index. `rest-conformance-r2.sh` section F enumerates the `OVERRIDE`
namespace through the repository index and skips by name without it. **Not re-verified in
revision 3:** revision 2 re-ran its scripts from a clean `git archive HEAD` extraction.
Revision 3's scripts are not committed yet (this seat makes no git writes), so that
extraction test was not repeated. No personal address appears in any script,
`User-Agent` header or log; the `User-Agent` the registry scripts send is the repository
URL `https://github.com/smorinlabs/rs-launch-blueprint`. All scratch work happens inside
one `mktemp -d` directory under `$TMPDIR` that a `trap` removes on exit, and no nested
Git repository and no `target/` tree is ever created inside this repository.

**What this ran, and what it deliberately did not.** It verified claims. It did not
implement the recommendation: there is no working seam, no service, no composition root,
no settings type, no acceptance scaffold and no template fixture. The probes are
throwaway crates whose only purpose is to make installation policies and header
behaviour observable side by side, and they are deleted when each script exits.

**`rest-conformance-r2.sh` — 66 assertions over seven sections.**
(A) The pinned artifact is identified before anything is quoted from it: blob type, size
**190,161** bytes, **3,427** lines, the sha256 of the extracted bytes, the `# REST API
Design Standard` first line, the `**Version 2.0.0.**` marker, and the blob's reachability
from commit `0850d43e…`. (B) Seventeen line-addressed quotations, each asserted
byte-for-byte at its line: R1.6 with its switch vocabulary and its "client audience"
clause, R1.7, the §1.10 `request-id` and `Allow` register rows, R4.10, R4.11, R4.17 with
its continuation line, R5.11, R8.1, R8.2, R8.10, R8.11, R11.7, and Appendix A's R4.17
checklist row. Two counting assertions do the work the prose rests on: **zero**
occurrences of CORS terms in the applicability-switch vocabulary, and **zero** in the
five-axis deployment-profile table. (C) Eleven probe observations measuring each
conformance claim, listed below, plus axum's `Allow` source lines. (D) A loop asserting
that the decision names every one of the eleven rules, plus assertions that it names the
ruling, pins the blob, and records OV-08 with an Argument, Options and a Deviations line.
(E) `decision-self-check.sh`, run and asserted to pass. (F) The `OVERRIDE` namespace
enumerated from the repository index, printed as an explicitly labelled snapshot and
asserted only where the assertion survives another agent's commit — that `OV-01` is
taken, that the namespace is populated, and that this decision uses exactly one numbered
override, OV-08. (G) The three Fetch Standard sentences OV-08's Argument rests on, two
quoted and one paraphrased, asserted on the live Living Standard with its "Last Updated" date printed.

| Observation | Result | Rule it settles |
|---|---|---|
| `X1` | `access-control-expose-headers=request-id,allow,retry-after,ratelimit` | R4.17 conforms on actual responses |
| `X2` | **no** `access-control-expose-headers` at all | R4.17 was violated by revision 1 — the measurement that moved the recommendation in revision 2 |
| `X3` | `access-control-expose-headers=*` | the wildcard lists no header name, so it does not satisfy R4.17 |
| `X4` | preflight `200` carrying `allow=GET,HEAD`, `content-length: 0`, no `content-type`, **no expose header** | R4.17 is not met on the preflight → `OVERRIDE (OV-08)`; R4.10 is not engaged, since no representation is selected |
| `X5` | `405 Method Not Allowed`, `allow: GET,HEAD` | R5.11 conforms, and the conditional install is what preserves the response |
| `X6` | preflight `200` with **no** `request-id` | R11.7 violated when the stamping layer sits inside `CorsLayer` |
| `X7` | preflight `200` **with** `request-id=req_probe` and `allow`, no expose header | R11.7 conforms when it sits outside — the constraint handed to R75; the second half of the OV-08 gap |
| `X8` | `200`, no `vary` | R4.11's stated exception, with the allowlist empty |
| `X9` | `200`, `vary: origin`, no `access-control-allow-origin` | R4.11 conforms with the allowlist configured |
| `X10` | preflight `200` with `access-control-expose-headers=request-id,allow,retry-after,ratelimit`, `allow` and `request-id` | OV-08 option 2 conforms literally, measured: the list names both §1.10 headers the preflight carries (revision 4, EA-1) |
| `X11` | actual `200` with one `access-control-expose-headers`, unchanged | OV-08 option 2 leaves actual responses as they were |

**`registry-figures.sh` — 56 assertions over ten sections.** (A) `tower-http`'s newest
non-yanked version is `0.7.1`, published `2026-08-31T14:49:25.697237Z`, declaring
`rust-version 1.65`, with `0.7.0` at `2026-06-15T14:01:18.432430Z`. (B) The `cors` category
enumerated: `meta.total` **36**, all 36 read across two pages and printed by name with
their figures, `q=cors` reporting **1,476** name matches of which the 40 highest-ranked
were read, and an assertion that `tower-http` appears on **neither** keyword page. (C) The
declared `rust_version` of every candidate excluded on gate 2, asserted one by one —
`null` for `axum_cors`, `rok-cors`, `cors-core` and `tower-http-cors-config`; `1.96.1` for
`lily_middleware`; `1.80` for `hyper-cors` and `1.88` for `actix-cors`, both of which clear
the gate. (D) `hyper-cors` 0.2.0's published dependency list contains **no** `tower`,
`tower-layer` or `tower-service`. (E) RustSec answers `200` for `tower-http` and for the
`atty` control, lists exactly the two known entries, and `RUSTSEC-2022-0043`'s own record
declares `patched = [">= 0.2.1", ">= 0.1.3, < 0.2.0"]`, `os = ["windows"]` and `ServeDir`.
(F) The 0.7.0 changelog section carries exactly **one** `cors` entry and **seven**
`breaking:` entries, **none** of which names `cors`. (G) The published `.crate` artifacts
for 0.6.11 and 0.7.1 are downloaded, their sha256 printed, and read: `default = []`,
`cors = []`, `#![deny(unsafe_code)]`, zero `unsafe` in the `cors` module, the
`Method::OPTIONS` short-circuit, the unconditional `vary.to_header()` call,
`ensure_usable_cors_rules`, `AllowOrigin::list`, `OriginInner::default()` being an empty
`List`, `update_vary_header` present in 0.7.1 and absent in 0.6.11, and — new in revision
3 — the expose list applied only on the non-preflight branch (`mod.rs:715`, `:728`–`729`).
(H) Four `gh api` calls, spaced 21 s apart: the repository (918 stars, `archived: false`,
`pushed_at 2026-09-26T12:33:00Z`), the open-issue `search/issues` `total_count` (**32**,
with `open_issues_count`'s **40** printed and explicitly not used), the
`rust-lang/crates.io` default-branch commit `765bbf478827f421a93ea2634997b2b4f55c87f4`,
and that commit's `Cargo.toml`, asserted to contain `tower-http = { version = "=0.7.1"`
at line 168. (I) The three adopter manifests, each asserted to activate `"cors"`; upstream
CI's `os: [macos-latest, windows-latest]` job and its `rust-toolchain@1.65` MSRV job; and
`loco`'s `fn is_enabled` and `cors.max_age(Duration::from_secs(max_age))` lines. (J) The
revision-1 issue-responsiveness figures, recomputed from the committed 2026-09-18
snapshot `snapshots/tower-http-issue-triage.json`: 2 answered, 8 unanswered, 4 of those
closed, at least one opened outside that snapshot's comment window. That snapshot is kept
as the record of revision 1's window; the current figures come from
`muse-adjudication.sh` section F.

**`probe-checks.sh` — 29 assertions over five sections.** The probe pins `axum =0.8.9`,
`tokio =1.53.1` with R69's feature list, `tower-http =0.7.1` with only `cors`, and
`tower =0.5.3` with `util` as a **dev-dependency only**, and resolves everything else
from its committed lockfiles. It prints **thirteen** `CHECK` lines, which are the ten
behavioural rows the Opus report tabulated with its `Q2`, `Q3` and `P2`/`P3` rows split
into one line each for `GET` and `OPTIONS`; the report's remaining two rows, the
dependency-tree delta and the build measurement, are sections D and E below. Every one of
them reproduced, and check `E` additionally carries the `access-control-max-age: 600`
assertion the report could not make.

| Observation | Result | What it settles |
|---|---|---|
| `A` | `200`, headers `{content-length, content-type}` — no CORS header, **no `vary`** | criterion 1 |
| `Q1` | `405 Method Not Allowed`, `allow: GET,HEAD` | criterion 2 |
| `Q2-get` / `Q2-options` | `200` **+ `vary: origin`** / **`200`**, not `405` | falsifies alternative B with a bare layer |
| `Q3-get` / `Q3-options` | `200` **+ `vary: origin`** / **`200`** also advertising `access-control-allow-headers: *` and `access-control-allow-methods: *` | falsifies alternative B with py's literal empty-list configuration |
| `C` | `access-control-allow-origin: https://app.example` | criterion 3 |
| `D` | no `access-control-allow-origin` | criterion 4 |
| `E` | `200` with allow-origin, allow-methods, allow-headers **and `access-control-max-age: 600`** | criterion 5, and the report's one un-compiled claim, now compiled |
| `R1` | `status=200 handler_hits=0` | criterion 5 from the handler's side; the constraint handed to R75 |
| `P2` / `P3` | `.layer()` → `200` with the CORS headers / `.route_layer()` → **`404`, no headers** | why `.layer()` is the right call |
| `H` | `parse_is_err=true` | criterion 6 |

Section C re-runs all thirteen against **0.6.11**: every status code is identical to
0.7.1's, and the sole difference is that 0.6.11 emits
`vary: origin, access-control-request-method, access-control-request-headers` where 0.7.1
emits `vary: origin`. Section D resolves the graph with and without the dependency line —
**57** packages against **55**, delta exactly `tower-http 0.7.1` and `bitflags 2.13.2`,
nothing removed, maximum declared dependency `rust-version` **1.85** (`hyper-util`) under
the committed lockfile and asserted `≤ 1.96`, nine packages declaring none and **neither
added package among them** — and then asserts three facts about `tower`'s placement: it is
already in the non-dev graph through `axum`; `axum` already activates its `util` feature,
so the rejected `option_layer` alternative costs no crate and no feature but does cost a
direct dependency declaration; and `tower-http` with only `cors` on has **no `tokio`
edge**. Section E measures gate 6: stripped binaries **502,264 → 668,728 bytes**, a cost
of **+166,464 B**, asserted to be positive and under 400 kB. Build seconds are printed for
two runs per arm and are **never asserted**.

**`muse-adjudication.sh` — 27 assertions over seven sections.** (A) The engine set: the
live prompt equals the frozen `inputs/prompt.md` and reads `- engines: muse, opus`;
`research/EXECUTION.json` `engine_overrides.R76` is `["muse","opus"]`; RUNBOOK §2 lists
R76 in the substitution set beside Q9.B; the manifest records the `codex->muse` migration
under Q5.A; `raw/muse.md` hashes to the cited value and validates as a `crate` answer; its
three `- assumes` names are not registry rows; it states that it ran no command. The log
also prints the sha256 of `research/EXECUTION.json` and `research/RUNBOOK.md` as read,
because both are uncommitted working-tree state. (B) The version floor: 0.7.0 is not
yanked; `src/cors` is byte-identical between the published 0.7.0 and 0.7.1 `.crate`
files; the 0.7.1 changelog names no `cors` change and does fix a regression introduced in
0.7.0 (`#712`, decompression). (C) `actix-cors` 0.7.2, gate by gate, as summarised under
the shortlist. (D) `rocket_cors`'s maintenance signal. (E) Reverse-dependency counts,
`tower-http` **3,532** and `actix-cors` **214**. (F) Issue responsiveness recomputed from
the new snapshot over both the rubric's window and the Muse report's narrower one. (G)
Repository figures quoted here that no other log carried: `actix/actix-extras`,
`loco-rs/loco` and `tokio-rs/console`.

**`decision-self-check.sh` — 73 assertions over seven sections**, covering the
obligations a reader cannot check by reading. (A) The exact title line, the four H2
sections in order with no fifth, no `## Supersedes`, the one `### Principles and
implementation` heading, and exactly one `re-verify:` line closing `## Decision`. (B) The
six `- assumes` lines extracted from `docs/port/PARAMETERS.md` by a Python reader and
`diff`ed against the decision's own, plus the absence of any `- owns` or `CONFLICT:` line.
(C) The gate-1 `inapplicable` string in full, and a mechanical enumeration of every
occurrence of the gate's root word, so surviving gate-1 reasoning would fail the check.
(D) No email-shaped token anywhere under `review/`. (E) Both raw reports hashing to the
values `## Engines` cites, both validating as `crate` answers, and the engine-set record
naming its authority. (F) Every figure quoted from a sibling log present **both** in that
log and in this document, plus each of those logs ending in `RESULT: PASS` with no `ASSERT
FAIL` line. (G) Every `path:line` citation in this document resolved: a repository file
must exist with at least that many lines, a `py-launch-blueprint` path is checked at pin
`b08bccfb`, and anything else must be on an explicit list of published-artifact paths that
the other scripts read, so a mistyped local path cannot pass as "external".

**Reproduction, stated precisely rather than claimed.** What reproduces, and under what
condition:

- **Byte-for-byte:** every `BLOB`, `PINNED` and `SNAP` line, because each reads an
  immutable git blob, a published `.crate` artifact or a committed snapshot.
- **Under the committed lockfiles and `rustc 1.98.1`:** every `CHECK` observation, the
  dependency-tree delta, the maximum `rust-version`, and the two stripped byte sizes. A
  different toolchain may change the byte sizes; the assertions on them are bounds.
- **Point-in-time by construction:** every line prefixed `FIGURE` or `HEAD` — download
  counters, stars, issue counts, `pushed_at`, a search's `meta.total`, default-branch file
  contents, the Fetch Standard's Living Standard text. They carry their endpoint and are
  quoted in this document with the date 2026-09-27.
- **Never:** build seconds and the `mktemp` path in one `cargo tree` line.
- **The rule for comparing across runs:** every line prefixed `ASSERT` is identical in
  text and in verdict on every run, and so are the `PASS`/`FAIL`/`SKIP` counts, except
  where a moving source crosses an asserted bound. That is what an auditor diffs.

**What could not be verified here, and is left for P03** (also listed under `## Engines`):
no latency or throughput benchmark of the layer was run, so no performance figure is
claimed beyond the measured byte cost; no compile-time cost is claimed at all; whether
`cargo audit` ever reports `RUSTSEC-2022-0043` against 0.7.1 was not executed — the
advisory's own `patched` range was read instead; Windows behaviour was not exercised,
which `target-os-matrix` does not require; no browser was run, so OV-08's Argument rests
on the Fetch Standard's text rather than on an observed user agent; and the `q=cors` name
search read the 40 highest-ranked of 1,476 results rather than all of them, with the
keyword enumeration (all 36) being the complete one and the name search a cross-check
against it.

**Planned for P03, not run here**, because each needs the template, which does not exist:

```bash
# 1. The default build never resolves the CORS crate.
cargo tree -p rs-launch-blueprint -e normal | grep -q tower-http && exit 1
# 2. The web member builds with the feature on, on both fixed runners.
cargo build --features web --locked
# 3. The seven acceptance criteria, as ordinary integration tests.
cargo test --features web --locked -p rs-launch-blueprint-web cors
# 4. The MSRV gate, over the tree the feature pulls in.
cargo +1.96 check --features web --locked
# 5. No open advisory in the resolved graph.
cargo deny --all-features check advisories
```

Expected: (1) exits 0, because `tower-http` sits behind the optional member; (2) succeeds
on `ubuntu-latest` and `macos-latest`; (3) all seven criteria green, with the
empty-allowlist cases asserting the **absence** of `access-control-allow-origin` *and* of
`vary`, asserting `405` on an unconfigured preflight — the assertion that fails if anyone
ever "simplifies" the branch away — and asserting the explicit expose list on an actual
response (criterion 7), plus criterion 8 if OV-08 is refused; (4) succeeds, since the
probe's locked tree tops out at 1.85, inside the 1.96 floor — the real template's tree is
what this check proves; (5) exits 0, since the only live `tower-http` advisory is
Windows-only, `fs`-only and patched since 0.2.1.

## Engines

- **Muse (Meta) — `raw/muse.md`** (sha256
  `31be2e15e942401a98031416eef2d7ab2043ddae1a343016c929b87ba88c67c5`, 20,628 bytes; figures
  retrieved 2026-09-25; 15 H3 fields, shape validated by
  `validate_answer_text(text, "crate")`, which reports no error). The report states that it
  ran no command ("Proposed, not executed"), so its behavioural claims are proposals, and
  its figures are API reads. **Collection gap, not closed from this seat:**
  `operations/muse.json` still reads `state: "submitting"` with no `raw_sha256`, the
  manifest `state` is `partial`, and `raw/muse.md` and `operations/muse.json` are
  untracked. The artifact exists on disk and is adjudicated below from those exact bytes;
  registering it through the runner, so its hash lands in the operation record, is the
  controller's step.
- **Claude Opus 5 — `raw/opus.md`** (sha256
  `c2792a6957df5b84fcb6438f2f14312fcae8bbd801055e07f1235e63333a5cf4`; 15 H3 fields, shape
  validated, no error; collected 2026-09-18 and registered in `operations/opus.json`).
- **The REST API Design Standard v2.0.0** — not an engine, but a binding input added
  after revision 1 by owner ruling W2-REST, read at blob
  `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` of commit
  `0850d43e45d919ef5e37f7174c4212b46013c49f` (190,161 bytes, 3,427 lines).
  `review/evidence/rest-conformance-r2.sh` asserts the blob's size, line count, version
  marker and reachability from that commit before quoting a single rule.

**The engine set, and its authority.** This item's required engines are **`muse, opus`**,
and this decision is synthesized from both. The authority, as read on 2026-09-27
(`muse-adjudication.log` section A):

- the live prompt `research/topics/76-cors-middleware/prompts/cors-middleware.prompt.md`
  (sha256 `99e9acac…`, byte-identical to the frozen `inputs/prompt.md`) reads
  `- engines: muse, opus` and says "This item substitutes Muse (Meta) for Codex under the
  `engine_overrides` pilot; its mirrored `- engines:` line is authoritative";
- the live policy `research/EXECUTION.json` records `engine_overrides.R76 = ["muse","opus"]`;
- `research/RUNBOOK.md` §2 lists R76 in the Muse substitution set in the sentence that
  records owner decision **Q9.B** retiring Codex from P02, and that paragraph was amended
  at owner decision **Q17.A** (2026-09-27) to extend the substitution to the research wave.
  R76's own substitution is the earlier bulk set: the run manifest records the
  `codex -> muse` migration at 2026-09-21T23:06:20Z under owner decision **Q5.A**. Q17.A
  names the wave items, not R76; it is cited here as the current state of the policy text.

`research/EXECUTION.json` and `research/RUNBOOK.md` are uncommitted working-tree edits at
this reading; their sha256 values are printed in `muse-adjudication.log` so the citation
is checkable. Revisions 1 and 2 were written before the Q5.A migration. They described the
item as FOCUSED with engines `codex, opus` and recorded Codex as absent under owner ruling
W1-CODEX3; that framing is superseded, and Codex is not a required engine for this item.

**Frozen inputs, as found.** The run's `inputs/prompt.md` is byte-identical to the live
prompt (sha256 `99e9acac…`, which is also the manifest's `input_hashes.prompt`). The other
three frozen inputs differ from their live files: `inputs/EXECUTION.json` (`ed5042be…`
against live `acdcbfff…`; its `engine_overrides.R76` already reads `["muse","opus"]`, and
the difference is the Q17.A wave entries), `inputs/CLAUDE.md` (`e82053f1…` against live
`6b86e81a…`, other items' status rows) and `inputs/PARAMETERS.md` (`8ad1b72c…` against live
`85f998c1…`, other items' rows). The six rows this decision assumes match the live
registry byte for byte. Re-freezing the inputs is the controller's step; this synthesis
did not edit them.

**Revision history.**

- **Revision 1** — 2026-09-18, commit `3b933872`, sha256
  `6fd6e1f90348047fe72996a0f4ade667d91c062c305c70571b57ac8c6b83740b`. The research
  synthesis from the Opus report: the crate selection, the conditional-install policy, all
  six fitness gates, the category enumeration, and three evidence scripts.
- **Revision 2** — 2026-09-18, commit `1228ae55`, sha256
  `55d7df033a12683fff26d3e8e7d6199b56b31e1628a6e27d27afc25ee170baeb`, preserved verbatim at
  `review/R76-r2-snapshot.md`. A pre-audit revision occasioned by owner ruling W2-REST:
  eleven rules quoted and dispositioned, and the recommendation moved for R4.17 on actual
  responses. Rejected by both audits (`review/audit-fable.md`, JA-1 to JA-3;
  `review/audit-claude.md`, findings 1 to 5).
- **Revision 3** — 2026-09-27, sha256
  `950f53664fe727d3fc7f2ce4790ad62ef2e1eb626a0b9fc97d9f5404c55eafae`, preserved verbatim at
  `review/R76-r3-snapshot.md`. Repairs every revision-2 finding (its table follows revision
  4's at the top of `## Decision`). The recommendation does not move; `OVERRIDE (OV-08)` is
  added; the Muse report is adjudicated; every figure is re-measured and dated; the
  evidence scripts are made deterministic and re-recorded against its bytes. Rejected by
  both audits (`review/audit-claude.r3.md`, EA-1; `review/audit-fable.r3.md`, findings 1
  and 2).
- **Revision 4** — 2026-09-27, this document. Repairs those three findings (table at the
  top of `## Decision`), finding 1 as the owner directive prescribes. The recommendation
  does not move; `rest-conformance-r2.log` and `decision-self-check.log` are re-recorded
  against these bytes.

**What the standard changed, and what it left alone.** The ruling reached this item after
its research was complete, so the honest account is not "the design anticipated the
standard". The design met it in ten rules and missed it in one, R4.17, on two kinds of
response:

1. **R4.17 on actual responses — missed by revision 1, fixed in revision 2.** Revision 1
   configured `allow_origin`, `allow_methods`, `allow_headers` and `max_age`, and no
   `expose_headers`. Check `X2` shows the consequence: with an allowlist configured, the
   response carries no `access-control-expose-headers`, so a cross-origin browser client
   cannot read `request-id`, `Retry-After`, `RateLimit` or any other standard-bound header.
   The recommendation moved.
2. **R4.17 on preflight responses — missed by revision 2's reading, recorded in revision 3
   as `OVERRIDE (OV-08)`.** Revision 2 asserted that a preflight "carries none of the
   standard-bound headers". Its own check `X4` showed `allow`, and `X7` showed
   `request-id`. The judgment audit (JA-2) caught this. The deviation, its Argument and its
   Options are under `## Decision`.
3. **R11.7 — met, now for a rule-grounded reason.** Checks `X6` and `X7` ground the
   request-id ordering constraint on a MUST: inside, the preflight `200` carries no
   `request-id`; outside, it does.
4. **R5.11 — met, and the standard supplies a second reason for the central decision.**
   Under R5.11 the `405` an unconfigured preflight receives is obliged to carry `Allow`,
   and unconditional installation deletes the response that carries it.
5. **R1.6 — a tempting escape route, closed by reading rather than assuming.** There is no
   applicability switch for CORS; R1.6 places "client audience" in the conformance note's
   free text explicitly.
6. **R1.7, R4.10, R4.11, R8.1, R8.2, R8.10, R8.11 — met or not engaged, each stated.** R1.7
   is met by writing OV-08 down.

**OV-08, and how the number was obtained.** An earlier draft of revision 2 stated that
`OV-01` was free, on the strength of a search a timeout had killed, whose empty output was
read as an empty result — the truncated-search failure this programme has hit before. Run
properly, `git grep -o -E "OV-[0-9]{2,}" -- research docs` shows **`OV-01` is in use**: it
is R60's deviation from the CLI Design Standard, refused by the owner on 2026-09-14. The
namespace was then being allocated concurrently by sibling items, two syntheses collided
on `OV-04`, and **the controller took allocation over** (ledgered with its allocation
table at commit `69a635ec`). Numbers are assigned, not discovered. **OV-08 is this item's
allocation**, and revision 3 uses it. `rest-conformance-r2.sh` section F still enumerates
the namespace, labelled as a live snapshot, to prove that `OV-01` is taken and that this
decision uses OV-08 and no other number.

**What P03 must additionally validate under the standard.** That the assembled
`exposed_headers` list actually names every standard-bound header the finished stack
emits — this run measured the mechanism with a four-name stand-in, not the real list,
which only exists once R70, R72, R74, R75 and R80 have landed. That R75's published order
puts every preflight-stamping layer outside `CorsLayer`, which check `X7` shows is the
only arrangement satisfying R11.7 on a preflight. And, if the owner refuses OV-08, that
option 2's stamp puts the same list on preflights (check `X10`).

**The Opus report against this synthesis — what reproduced, what did not, and what this
run corrected.**

1. **Reproduced.** Every crates.io and GitHub figure the report gave reproduced exactly
   when revision 1 re-fetched it on 2026-09-18, and the release timestamps, version counts,
   excluded candidates' `rust_version` values, RustSec state, source lines, adopter
   manifest lines, upstream CI jobs and dependency-tree delta still reproduce on
   2026-09-27. The counters have moved since, as counters do; this document quotes the
   2026-09-27 values, and the table under Muse disagreement 6 shows all three dates. Every
   behavioural observation the report tabulated reproduced **character for character** in
   status and header set.
2. **Gap closed.** The report stated plainly that `.max_age(Duration::from_secs(600))`
   appeared in its recommendation "**not** on an executed check in this run". This run
   **compiled and measured it**: check `E` observes `access-control-max-age: 600`.
3. **Figure recomputed, and one of its two components corrected.** The report gave issue
   responsiveness as `#713` answered "**3 minutes**" after opening and `#702`
   "**4 h 41 m**". Recomputing by `author_association` gives `#713` at **0.05 h** and
   `#702` at **4.55 h** — **4 h 33 m, not 4 h 41 m**. Both figures reproduce again in
   revision 3's 2026-09-27 window.
4. **Claim narrowed on new evidence.** The report wrote that the `cors` module's "only
   change across 0.7.0 is 'relax the `Vary` header defaults (#674)' — non-breaking for this
   use". The changelog reading is exact, but the change is observable: in **this
   template's own recommended configuration** the emitted `Vary` value narrows from
   `origin, access-control-request-method, access-control-request-headers` to `origin`.
5. **Framing corrected on measurement.** The report rejected alternative C on the ground
   that `option_layer` "promotes `tower` from *dev-dependency only* … to a normal
   dependency". Measured: `tower` is already in the non-dev graph and `axum` already
   activates its `util` feature, so the real and only cost is a direct dependency
   declaration.
6. **Could not reproduce, and withdrawn.** The report's gate-6 compile-time figure,
   "`+4.1 s` of clean release build", did not reproduce: revision 1's run recorded 17.7 s
   and 21.4 s without the dependency against 16.4 s and 13.3 s with it (its
   `probe-checks.log` as committed at `3b933872`), and revision 3's
   run records 11.5 s and 11.8 s against 11.4 s and 11.7 s. **No compile-time cost is
   claimed.** The binary-size direction and order of magnitude did reproduce on a
   differently shaped probe: **+166,464 B** here (rustc 1.98.1, committed lockfiles)
   against the report's **+149,056 B**.
7. **Over-claim found and repaired.** The report said all 36 `cors`-keyword crates were
   dispositioned; **fourteen** were named nowhere in it. All 36 are dispositioned here, and
   `registry-figures.sh` prints every one by name.
8. **Stale citations corrected.** The report cited **R02 revision 1** and **R05 revision
   2**; the current accepted revisions are **R02 revision 2** and **R05 revision 3**. Both
   still hold everything this item leans on.

**The Muse report against this synthesis — every disagreement settled.** Both engines
reach the same recommendation: `tower-http` 0.7.x with `default-features = false,
features = ["cors"]`, a runtime `AllowOrigin::list`, and a conditional registration
branch in the composition root that installs nothing when the allowlist is empty. Both
reject an always-installed layer and a hand-rolled one on the same grounds. Where they
differ:

1. **Runner-up.** Muse ranks `actix-cors` 0.7.2 as runner-up, winning "if and only if R69
   selects actix-web"; revisions 1 and 2 ranked alternative B. **Settled: both are right on
   different axes, and both are now recorded.** B is the runner-up on the mechanism axis;
   `actix-cors` is the runner-up on the crate axis. R69 settled on axum (published
   revision 9; revision 11, carrying revision 10's owner-accepted value, adopted under Q3.A), so Muse's condition does not hold today, and a
   republished R69 naming a non-`tower` framework is re-verify trigger 1.
2. **Gate status of `actix-cors`.** Muse says it passes every gate; revision 2 excluded it
   "on gate 5 and on fit". **Settled for Muse.** Gate 5 reads "default features and any
   async-runtime coupling stated" — a disclosure gate. `muse-adjudication.log` section C
   checks gates 2–5 at source and all pass: tree MSRV 1.88.0 ≤ 1.96, no advisory,
   `forbid(unsafe_code)`, ubuntu and macOS CI with test steps; gate 5 is stated. It is now
   on the qualified shortlist and excluded on fit. The same correction moves every other
   framework-bound crate from "gate 5" to "fit", with gates recorded as not evaluated.
3. **Version requirement: `"0.7"` (Muse) against `"0.7.1"` (this decision).** **Settled
   for 0.7.1, on narrow grounds.** CORS behaviour does not separate them: `src/cors` is
   byte-identical in the published 0.7.0 and 0.7.1 `.crate` files, and the 0.7.1 changelog
   names no `cors` change (`muse-adjudication.log` section B). The ground is what a
   published library's floor promises. Every check in this run measured 0.7.1, none
   measured 0.7.0, and 0.7.1 fixes a regression 0.7.0 introduced (`#712`, in
   decompression, which this line does not enable). A fresh resolution picks 0.7.1 under
   either requirement; the floor matters only to a downstream consumer resolving minimal
   versions, and for that consumer the floor should be the version that was verified.
4. **Issue responsiveness.** Muse observed no maintainer first-response in its window;
   revision 2 reported 2 of 10 answered. **Settled: both are true, over different
   windows.** Muse read the non-PR issues among the ten most recently created *items*,
   pull requests included; the rubric names the ten most recently opened *issues*.
   Recomputed on 2026-09-27 from one snapshot over both windows
   (`muse-adjudication.log` section F): the rubric window gives 2 of 10 answered (`#713`,
   `#702`); Muse's window gives 0 of 4. This decision reports the rubric's window and
   states the newer silence in prose. Neither reaches `at-risk`.
5. **Muse's `### Parameters`.** It carries `- assumes` lines for `web-framework-stack`,
   `cors-allowlist-value` and `middleware-ordering`, with parenthetical values. None is a
   row of `docs/port/PARAMETERS.md` (asserted). **Recorded as a report defect and not
   carried forward.** This decision's six `- assumes` lines are the registry's.
6. **Figures.** The two reports and the two syntheses read the same endpoints on different
   days. **Settled by dating every figure and quoting the newest.**

   | Figure | 2026-09-18 (revisions 1–2) | 2026-09-25 (Muse) | 2026-09-27 (this revision) |
   |---|---|---|---|
   | 90-day downloads | 149,725,960 | 154,784,730 | **155,482,963** |
   | all-time downloads | 462,114,603 | 476,178,922 | **479,378,847** |
   | stars | 913 | 918 | **918** |
   | open issues (`total_count`) | 30 | 32 | **32** |
   | `pushed_at` | `2026-09-13T22:53:22Z` | `2026-09-19T15:23:28Z` | **`2026-09-26T12:33:00Z`** |
   | reverse dependencies | 3,486 (quoted with no log line) | 3,520 | **3,532** |

   Revision 2's 3,486 appeared in no committed log; revision 3 sources the count in
   `muse-adjudication.log` section E.
7. **Up-and-comers.** Muse found "no standalone CORS-crate newcomer". **Settled for the
   enumeration:** the keyword category holds 36 crates, seventeen of them in the up-and-comer bin
   (`hyper-cors`, `tower-http-cors-config` and others), all read and dispositioned. The
   outcome agrees — none qualifies — but "none found" is not the finding.
8. **R69's status.** Muse writes as if R69 were undecided. **Stale:** R69 is published
   with axum. Nothing in Muse's recommendation depends on the difference.
9. **`rocket_cors` maintenance.** Muse calls it `at-risk`. **Confirmed at source** (no
   push since 2023-11-20; `#118` open with zero comments since 2024-11-16) and recorded
   beside its fit exclusion. It changes nothing, since fit already excludes it.
10. **Smaller points, reconciled rather than contested.** Muse's three acceptance criteria
    are contained in criteria 1, 2, 3 and 4 here. Muse's "`cors` feature adds zero extra
    dependencies" and this decision's "adds `tower-http` and `bitflags`" are both true:
    `cors = []` activates no optional dependency, and `bitflags` is a required dependency
    of `tower-http` itself. Muse read `unsafe` from the default branch and this run from
    the published `.crate`; both find zero in `src/cors`.

**Uncertainty, stated where the evidence is incomplete.** Confidence is **high on the
crate** — the category was enumerated rather than recalled, two engines from different
model families (Meta and Anthropic) independently reached it, three well-regarded
projects were shown activating this exact feature by reading their manifest lines, and
the framework's own maintainers document the idiom in their own example. Confidence is
**high on the mechanism**, because the alternative was not argued away but measured away,
and both engines chose the same branch shape. Confidence is **medium on the version**:
0.7.1 was 27 days old at retrieval, the owner reference says 0.6, and a caret requirement
on a young minor line carries more exposure than a mature one; the `cors` module's only
0.7 change is the narrowing measured here, and the Rust project's own registry pins
`=0.7.1`. Confidence is **medium on OV-08's outcome**, which is the owner's ruling, not a
research result; both branches are measured. Three further limits are named rather than
papered over. First, **no published Rust web-service *template* was found that documents
allowlist-gated CORS installation as a named, reusable pattern** — both engines report
this — so the prompt's LOW question is answered *affirmatively for a framework*
(`loco-rs/loco`'s `is_enabled()` registry) and *negatively for templates*. Second, the
Muse report executed nothing, so the independent second lens covers selection and
figures but not behaviour; every behavioural claim here rests on this run's probes.
Third, the Muse leg is uncollected in the runner's records, as stated above.

**What P03 must validate.** (1) That the conditional branch survives contact with R69's
real `build_router` and R77's real settings type, with `Router::layer` still
type-preserving at whatever axum version the template pins. (2) The seven acceptance
criteria as ordinary integration tests, with the empty-allowlist cases asserting the
absence of both `access-control-allow-origin` and `vary` and asserting `405` on an
unconfigured preflight — the assertions that fail if the branch is ever "simplified" away
— and criterion 7 asserting the explicit expose list. (3) That `cargo tree -e normal` on
the default build finds no `tower-http`. (4) That `cargo +1.96 check --features web
--locked` passes over the real tree, not the probe's. (5) That `cargo deny check
advisories` is clean over the real graph. (6) That `.max_age` survives whatever shape R77
gives the settings type. (7) The compile-time and binary-size cost of the dependency **in
the real template**, where the surrounding code is large enough for the figures to mean
something. (8) The outcome of the owner's ruling on `OVERRIDE (OV-08)`: nothing if
approved; option 2's stamp and criterion 8 if refused.
