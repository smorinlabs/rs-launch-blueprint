# 2026-09-18 — R76 — cors-middleware (crate, Focused) — decision (revision 2)

## Decision

This decision is a **proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. The list of claims P03 must validate is
under `## Engines`. A decision that does not survive implementation is revised against
this recorded research, not researched again from scratch.

**Revision note (revision 2, pre-audit).** Revision 1 (committed `3b933872`, sha256
`6fd6e1f9…`) was written before owner ruling **W2-REST** of 2026-09-18
(`docs/port/OWNER-REVIEW.md`, heading *"2026-09-18 — the REST API Design Standard binds
the HTTP surface (W2-REST)"*), which makes the organisation's **REST API Design Standard
v2.0.0** bind this template's HTTP surface the way the CLI Design Standard binds its CLI.
The standard is pinned at commit `0850d43e45d919ef5e37f7174c4212b46013c49f`, file blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9` (190,161 bytes, 3,427 lines, read here with
`git -C /Users/stevemorin/c/rest-standards cat-file blob 71bd813c…`). This revision reads
that blob for every rule touching CORS, cross-origin access, browser clients, allowed
origins and the security and deployment profile, quotes each at its line, and states rule
by rule whether the recommendation conforms.

**The recommendation moved, and this says so plainly rather than burying it.** One rule,
**R4.17**, is not satisfied by revision 1's configuration, and the gap was *measured*, not
argued: with an allowlist configured, revision 1's `CorsLayer` emits **no**
`Access-Control-Expose-Headers` header at all, so a cross-origin browser client cannot
read `request-id` — a header R11.7 makes mandatory on every response. The fix is
mechanical and is taken here, which a pre-acceptance revision is allowed to do: the
recommendation now configures `expose_headers`, and `apply_cors` grows a third parameter
carrying the list. **No `OVERRIDE (OV-nn)` is recorded**, because after that move every
quoted rule conforms or is not engaged, so there is nothing to argue against. This item
therefore claims no override number — see `## Engines` for the state of that namespace,
which sibling revisions are allocating concurrently.
**Unchanged from revision 1:** the crate and its version, the conditional-install policy
that is this item's whole subject, every gate result, every figure, and all six
`- assumes` lines. Revision 1's evidence — `registry-figures.sh`, `probe-checks.sh`,
`decision-self-check.sh` and their three logs — is retained **byte-identical**; this
revision's checks live in the new `rest-conformance-r2.sh` and its log.

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
| crate and version requirement | `tower-http = "0.7.1"` — a caret requirement, not the exact pin `rust-lang/crates.io` uses | 0.7.1 is the newest non-yanked version, published `2026-08-31T14:49:25.697237Z` (`GET https://crates.io/api/v1/crates/tower-http/versions`, retrieved 2026-09-18). `crates/web` is a *published library* under R02 revision 2's four-package workspace, and an exact pin in a library propagates a resolution constraint to every downstream consumer |
| feature list | exactly `["cors"]`, with `default-features = false` written for explicitness | `tower-http` declares `default = []` (`tower-http-0.7.1/Cargo.toml:161`) and `cors = []` (`:117`), so the `cors` feature activates no optional dependency at all. R75 owns the aggregate feature list on this one line and may extend it; it must not remove `"cors"` |
| installation mechanism | a re-binding `if` over the `Router` in the composition root | `axum::Router::layer` returns `Router<S>` — the same type it was called on — so `app = app.layer(cors)` inside an `if` type-checks. Executed: `review/evidence/probe-checks.log`, section B |
| trigger | the configured allowlist is non-empty | `F322`'s recorded principle is *absence*, not *permissive-but-empty*. The difference is measured, not asserted: see the two rows below |
| `allow_methods` / `allow_headers` | `Any` (the literal `*`) | matches what py's `allow_methods=["*"], allow_headers=["*"]` permits. The emitted header text differs cosmetically; the permission is the same |
| `expose_headers` | an **explicit list** of every standard-bound response header the service emits, never the `Any` wildcard, and never empty | **added in revision 2** to satisfy **R4.17**. The wildcard is not an option: it emits a bare `access-control-expose-headers: *`, which lists no header name and so does not do what R4.17 says to do, and the Fetch Standard ignores `*` outright once credentials are in play. The list's floor is `request-id`, because **R11.7** makes that header unconditional; R75 assembles the rest from the layers it installs. Measured in `review/evidence/rest-conformance-r2.log`, checks `X1`, `X2` and `X3` |
| `max_age` | `Duration::from_secs(600)` | Starlette emits `Access-Control-Max-Age: 600` unconditionally; `tower-http` emits nothing unless asked. Without this call a browser re-preflights every request. **Compiled and measured in this run** (`probe-checks.log`, check `E`: `access-control-max-age=600`), closing the one gap the research report left open |
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
on `parts.method == Method::OPTIONS` regardless of what the allowlist holds, and emits
the derived `Vary` header on every response it handles (`tower-http-0.7.1/src/cors/mod.rs`,
asserted at source in `review/evidence/registry-figures.log`, section G). A service that
answers `200 OK` with an empty body to `OPTIONS /v1/projects` when nobody configured CORS
is reporting something untrue about itself. One `if` is the proportionate price.

**Why 0.7.1 rather than the owner reference's 0.6, and what the move actually changes.**
The reference architecture (`inputs/owner-reference-axum-companion-stack-2026-09-16.md:141`)
names `tower-http = { version = "0.6", … }`. 0.7.0 shipped **2026-06-15** and 0.7.1
**2026-08-31**, both before that document's own 2026-09-16 date, and the Rust project's
own registry service pins `tower-http = { version = "=0.7.1", … }` in production
(`rust-lang/crates.io`, `Cargo.toml:170`, read through `gh api`). The 0.7.0 changelog
carries exactly **one** `cors` entry — "`cors`: relax the `Vary` header defaults (#674)" —
and **seven** `**breaking:**` entries, none of them in `cors`; they land in `compression`,
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
   being the only maintained `tower::Layer` implementation of the protocol, and each
   exclusion names an MSRV, an integration or a fit ground.
2. **MSRV — pass, with the tree resolved rather than assumed.** `msrv-policy` is *stable
   minus two minor versions*; `rustc 1.98.0 (88d9e12ae 2026-08-18)` puts the floor at
   **1.96**. `tower-http` 0.7.1 declares `rust-version = 1.65`. The gate applies to the
   dependency tree, so the tree was resolved: `cargo metadata --format-version 1
   --all-features` on the probe reports **57** packages, and the highest declared
   `rust-version` among the dependencies is **1.80** (`axum` 0.8.9). Nine packages declare
   none — `httparse`, `matchit`, `mime`, `serde_urlencoded`, `smallvec`, `sync_wrapper`,
   `tower-layer`, `tower-service`, `wasi` — and a differential resolution asserts that
   **none of the nine is introduced by this item**: they arrive with `axum` and `tokio`,
   which R69 already accepted. Recorded so the fact is not lost; R69 is not re-litigated.
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
   runtime R69's `tokio` provides.
6. **Binary size and compile time — pass, measured, and one half of it withdrawn.**
   Two otherwise identical probe binaries, one with the dependency and the conditional
   layer and one without, each built from a removed `target/` directory on
   `rustc 1.98.0` / macOS 26.4 `arm64`. Stripped: **502,264 → 668,744 bytes**
   (**+166,480 B**). **Compile time: no delta is claimed.** Across two clean release
   builds per arm the arms did not separate beyond this host's run-to-run variation —
   `probe-checks.log` records 17.7 s and 21.4 s without the dependency against 16.4 s and
   13.3 s with it, so on that run the *cheaper* arm was the one carrying the extra crate.
   The research report's `+4.1 s` is recorded under `## Engines` as a figure this run
   could not reproduce. The absolute
   byte delta is the meaningful figure; its percentage form must not be carried forward,
   because the probes contain almost no other code.

**Conformance to the REST API Design Standard v2.0.0 (owner ruling W2-REST), rule by
rule.** Every rule below was located by searching the pinned blob for CORS, cross-origin
access, browser clients, allowed origins, and the security and deployment profile, then
quoted at its line; `review/evidence/rest-conformance-r2.sh` asserts the quoted bytes at
the blob so a quotation cannot drift from its source, and then measures each conformance
claim.

| Rule | Line | Quoted | Disposition |
|---|---|---|---|
| **R4.17** | 864, 868 | "Where an API serves cross-origin browser clients, every response MUST list the standard-bound response headers it emits … in `Access-Control-Expose-Headers`." | **MOVED — recommendation changed.** Revision 1 set no expose list, so with an allowlist configured its response carried no `access-control-expose-headers` at all (check `X2`). Revision 2 configures an explicit list and the header is emitted naming each one (check `X1`). The wildcard form was rejected on measurement: it emits `*`, which lists nothing (check `X3`) |
| **R11.7** | 1752 | "Every response, including errors, MUST carry the `request-id` correlation header (§1.10)." | **CONFORMS, with an ordering constraint now required rather than advised.** A CORS preflight short-circuits before the inner service, so a request-id layer placed *inside* `CorsLayer` leaves the preflight `200` with no `request-id` (check `X6`) — a MUST violated. Placed *outside*, the same preflight carries it (check `X7`). R76 owns neither the header nor the order; it hands R75 a rule-backed constraint in place of revision 1's precedent-backed one |
| **R5.11** | 1008 | "`405 Method Not Allowed` MUST carry an `Allow` header." | **CONFORMS, and the conditional install is what makes it true.** With the allowlist empty the layer is absent and `OPTIONS` on a `GET`-only route answers `405` carrying `allow: GET,HEAD` (check `X5`). The rejected alternative B destroys that response entirely, turning it into a `200` — an independent, standard-level reason for the branch this item recommends |
| **R4.11** | 856 | "Every response whose content was selected by a request header MUST send `Vary` listing each header that influenced selection. **Exception:** responses with no negotiation." | **CONFORMS in both branches.** Allowlist empty: no layer, no negotiation, no `Vary` — the rule's own stated exception (check `X8`). Allowlist configured: `Origin` selects whether `access-control-allow-origin` is emitted, and `vary: origin` names it (check `X9`). Emitting `Vary` more broadly than the rule compels is not a deviation; the rule fixes a floor, not a ceiling |
| **R4.10** | 846 | "The default media type … is `application/json` … Media-type selection MUST use HTTP content negotiation, never a `format` query parameter." | **NOT ENGAGED, measured rather than assumed.** A preflight response serves no representation: check `X4` shows `content-length: 0` and no `content-type`, so no media type was selected and no negotiation arises. The rule binds the endpoints R70 and R71 own, not this layer |
| **R1.6** | 229, 237, 241 | "The switch vocabulary: `webhooks` · `async-operations` · `bulk-operations` · `streaming`." · "…client audience — belong in the conformance note's free text, not here." | **CONFORMS, and it closes a tempting escape route.** There is **no applicability switch for CORS, cross-origin access or browser clients** — asserted by counting those words in the vocabulary lines, which finds **zero**. A CLI-first template therefore *cannot* declare these rules N/A by switch. R4.17 is scoped by its own conditional clause instead, and this item satisfies that clause's demand in the branch where it fires |
| **R1.7** | 271 | "An API deviates from this standard only in writing… silent deviation from any rule strength is nonconformance regardless of the deviation's merits." | **CONFORMS by construction.** Every rule this run quoted is dispositioned above; `rest-conformance-r2.sh` section D asserts that the decision names each one, so a rule cannot fall silently out of the table. The conformance-note lines this item owes are handed over below |
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
- *N/A declarations:* none owed by this item. R4.17 is not declared N/A — it is satisfied
  in the branch where its condition holds, and its condition simply does not hold in the
  other branch. The distinction matters under R1.6: an unmet conditional clause is not an
  off switch, and there is no switch here to turn off.
- *Deviations:* none. No `OVERRIDE (OV-nn)` is recorded by this item.

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
  resolves it.
- **R75 (`http-middleware-stack`, F317)** owns where this layer sits when present and owns
  the aggregate feature list on `crates/web`'s single `tower-http` line. This item
  contributes exactly `"cors"` and hands R75 one measured constraint: **a preflight
  short-circuits before the inner service runs** — handler invocations `0` — so any layer
  that must stamp preflight responses (request id, security headers) has to sit
  **outside** `CorsLayer`. Revision 1 grounded that on py's recorded ordering contract;
  under owner ruling W2-REST it is now grounded on a rule. **R11.7** puts `request-id` on
  every response, a preflight response included, and checks `X6` and `X7` measure both
  sides: with the stamping layer inside `CorsLayer` the preflight `200` carries no
  `request-id` and the MUST is violated; outside, it carries one. R75 also owns the
  `expose_headers` list R4.17 obliges, since R75 decides which standard-bound headers the
  stack emits — this item fixes only that the list exists, is explicit rather than a
  wildcard, and contains `request-id` as a floor. R75 must also read the 0.7.0 breaking
  entries itself for whichever other features it adds; this item's confidence covers
  `cors` and nothing else.
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
(`docs/port/areas/web-service.md:100`), which is why `F322` is `py-only`.

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

**Observable acceptance criteria**, numbered so each binds to an executed check in
`review/evidence/probe-checks.log`.

| # | Criterion | Executed as |
|---|---|---|
| 1 | With the allowlist empty, a `GET` carrying `Origin` returns no `access-control-allow-origin` **and no `vary`** | check `A` |
| 2 | With the allowlist empty, an `OPTIONS` preflight to a `GET`-only route returns `405 Method Not Allowed` | check `Q1` |
| 3 | With the allowlist holding `https://app.example`, a `GET` from that origin echoes it back | check `C` |
| 4 | With that allowlist, a `GET` from a different origin receives no `access-control-allow-origin` | check `D` |
| 5 | With that allowlist, a preflight on a `GET`-only route returns `200` carrying `access-control-max-age: 600`, and the handler is not invoked | checks `E` and `R1` |
| 6 | A syntactically invalid origin string fails at construction, before the listener binds | check `H` |
| 7 | With that allowlist, a `GET` from the allowed origin carries `access-control-expose-headers` naming every standard-bound response header the service emits, `request-id` among them | check `X1` (added in revision 2 for R4.17) |

**Architectural alternatives compared before any library was chosen.** The prompt's second
HIGH question asks for exactly this comparison, so the wrapper and the hand-rolled forms
are answered on evidence rather than dismissed.

| # | Alternative | Verdict and the ground for it |
|---|---|---|
| **A** | `CorsLayer` installed by a plain `if !origins.is_empty()` branch in the composition root | **Selected.** All six criteria executed green. Adds two crates to R69's accepted graph. The conditionality itself costs no dependency, because `Router::layer` is type-preserving |
| **B** | `CorsLayer` installed unconditionally, configured with an empty allowlist when none is set | **Rejected on measured behaviour.** Fails criteria 1 and 2: `vary: origin` appears on every response and `OPTIONS` on a `GET`-only route becomes `200` instead of `405`. It remains the **ranked runner-up**, because it is the only alternative that keeps the recommended crate, adds no dependency and removes a branch |
| **C** | A conditional-layer *wrapper*: `tower::util::option_layer` or `axum_extra::middleware::option_layer` | **Rejected on cost with no benefit, and the cost is now stated precisely.** It adds no crate and no feature to the resolved graph — this run measured that `axum` 0.8.9 **already activates** `tower`'s `util` feature. Its actual price is a **direct `tower` dependency declaration** on `crates/web`, moving `tower` out of the dev-dependency slot R69 fixed, so that `tower::util::option_layer` is nameable from non-test code. Both wrapper forms exist to solve a *type* problem — two branches producing different service types — that `Router::layer` does not have. The `axum-extra` form additionally carries a pending 0.9 `option_layer` body-type break that the owner reference itself flags (`inputs/owner-reference-axum-companion-stack-2026-09-16.md:36`, Key Finding 1) |
| **D** | Hand-roll the layer with `axum::middleware::from_fn` | **Rejected.** It saves two crates and ~166 kB and costs a from-scratch implementation of origin matching, the preflight short-circuit, `Vary` correctness, `max-age` and the credentials/wildcard interaction — security-relevant code a *template* should not ship hand-written, and whose last item `tower-http` encodes as an explicit runtime assertion precisely because getting it wrong is easy |
| **E** | Terminate CORS at a reverse proxy or gateway | **Rejected on fit.** The template must run under `cargo run` and be testable in-process through `ServiceExt::oneshot`, R69's fixed idiom. A gateway-only policy is untestable at that seam and unavailable to a template user with no gateway |
| **F** | Serve browser assets same-origin so CORS is never needed (owner reference, line 87) | **Agreed with in principle; not applicable in fact.** R69's `web-extra-surface` contains no static-asset or SPA head — the gated tree is `AppState`, `build_router`, route modules, handlers, `shutdown_signal` and `serve_until`. An API-only surface consumed by a browser front end elsewhere is exactly the case CORS exists for |
| **G** | A `loco`-style middleware registry: a `MiddlewareLayer` trait with `is_enabled()`, filtered before application | **Rejected as disproportionate here; handed to R75.** `loco-rs/loco` (9,152 stars, `pushed_at 2026-09-16T08:07:59Z`) does exactly this, and this run read the two source lines that prove it. It is the right shape for loco's ten-plus independently switchable middlewares. This template has one conditional layer today. If R75's stack lands with three or more independently gated layers, this becomes the right refactor, and R75 owns that call |

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
TypeScript, if a web surface is ever added there, faces the same choice in Hono's
`app.use()` form and should take the same policy — skip the `use` call rather than install
a permissive-but-empty middleware. That is the follow-on project's rationale, recorded
here; no change is made to py or ts by this decision.

**Reference implementations, and why each counts as practice evidence.** `tower-http` has
**3,486** reverse dependencies on crates.io. Three well-regarded projects were shown
activating **this exact feature** by reading the manifest line rather than asserting it:
`tokio-rs/console` (4,598 stars; the Tokio project's own diagnostics tool) at
`console-subscriber/Cargo.toml:65`; `tonic-web` (the gRPC organisation's Rust
implementation, where gRPC-Web *requires* CORS, so the use is load-bearing) at
`Cargo.toml:31`; and axum's own maintained example at `examples/cors/Cargo.toml:10`. A
fourth, `rust-lang/crates.io`, does not use the `cors` feature — the registry is
same-origin — but pins `tower-http` at `=0.7.1` in production, which is the strongest
available evidence that the 0.7 line is shippable. `loco-rs/loco` supplies the
config-gated-middleware pattern and the `.max_age` call this decision imports.

**Maturity, dependability and representative performance.** `tower-http` has **39**
published versions, **33** non-yanked, and is maintained in the `tower-rs` organisation
alongside `tower` itself; **913** stars, `archived: false`, `pushed_at
2026-09-13T22:53:22Z`; **30** open issues by the prompt's required `search/issues`
`total_count` field. Maintenance state: **active** — a release 18 days before retrieval
and a push five days before it. Issue responsiveness was **recomputed** from the fetched
API pages rather than carried: of the ten most recently opened non-pull-request issues,
**two** carry a comment from a maintainer (by `author_association`, not by name) —
`#713` after **0.05 h** and `#702` after **4.55 h**, a median over that answered subset of
**2.30 h** — and **eight** carry none on the fetched page, of which **four** were
nonetheless closed. A single median across all ten would be an invention, so two figures
are reported. **A limit the research report did not state:** the comments page reaches
back only to `2026-05-22`, so for `#676` and `#668`, both opened earlier, the absence of a
maintainer comment is *unproven* rather than measured. This is a quiet-but-live triage
pattern; it does not reach the rubric's `at-risk` bar, which requires a concrete signal.
Representative performance: the layer adds one `HeaderMap` construction per request and,
on a matched CORS request, up to four header insertions; the preflight path avoids calling
the inner service entirely. **No latency or throughput benchmark was run and none is
cited**, so no performance figure is claimed beyond the measured byte cost. When the
allowlist is empty the layer is absent, so the cost is exactly zero.

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
axum world a middleware layer is a `tower::Layer`. That fixes the category and the gate
every candidate must clear.

| Bin | What the enumeration found |
|---|---|
| **Built-in / first-party toolchain** | `tower-http`'s `cors` feature, maintained in `tower-rs` — the same organisation as `tower`. axum ships **no** CORS of its own and its maintainers' own example reaches for `tower-http` |
| **Established industry standard, framework-bound** | `actix-cors` 0.7.2, `rocket_cors` 0.6.0, `salvo-cors` 0.96.0, `ntex-cors` 4.0.0, `routerify-cors` 3.0.0, `trillium-cors` 0.1.0, `corsware` 0.2.0 and `iron-cors` 0.8.0 (both Iron, pre-async). Each implements a different framework's middleware trait; none exposes a `tower::Layer` |
| **Up-and-comer** | `tower-http-cors-config` 0.1.3, `hyper-cors` 0.2.0, `axum_cors` 0.1.8, `rok-cors` 0.1.0, `cors-core` 0.1.1, `axum-stack` 0.2.0, `bunner_cors_rs` 0.1.2, `blazingly-middleware` 0.2.2, `lily_middleware` 0.1.0, `apollo-cors` 0.3.0, `toxi-middleware` 3.1.0, `volter-middleware` 0.1.0, `rok-guard` 0.6.0, the `corx` family, and `vary-header` 0.1.0 — all with four-figure-or-smaller download counts, most of them two-figure |

The enumeration is reproducible: `GET https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads`
plus its `&page=2` returns **36** crates and this run read **all 36**, printing every name
with its figures into `registry-figures.log`; `GET https://crates.io/api/v1/crates?q=cors&per_page=40`
reports **1,452** name matches, of which the 40 highest-ranked were read as a cross-check.
`tower-http` appears on neither keyword page — its name does not contain "cors" and it does
not carry the keyword — which is asserted rather than assumed, and is why it had to be
reached from the axum side.

**Excluded by gate, or by scope — every one of the 36 dispositioned.** Gate numbers are the
prompt's.

- **`hyper-cors` 0.2.0** — *excluded on integration, and it is worth being precise: it
  clears gates 2 through 5.* `rust-version = "1.80"`, inside the floor; `unsafe_code =
  "deny"`; a CI matrix of exactly `[ubuntu-latest, macos-latest]`. It fails on the one
  thing that decides this item: its published dependency list is `bytes, http, hyper,
  itoa, pin-project-lite` — **no `tower`, `tower-layer` or `tower-service`** — because it
  implements `hyper::service::Service`, not `tower_layer::Layer`. `axum::Router::layer`
  cannot take it. The best-engineered newcomer found, and unusable here.
- **`axum_cors` 0.1.8**, **`rok-cors` 0.1.0**, **`cors-core` 0.1.1**,
  **`tower-http-cors-config` 0.1.3** — *all fail gate 2*: `rust_version` is `null` for each,
  asserted at the versions endpoint. Under the owner's recorded reading
  (`docs/planning/p02/owner-decisions.md`, "an unknown version is insufficient to clear a
  bar the prompt says must be cleared") an undeclared MSRV is a failure, not merely
  unproven. `tower-http-cors-config` is additionally not an alternative: it supplies
  `serde`-deserializable config *types for* `tower_http::cors`, so it presupposes this
  recommendation rather than competing with it, and it is the most *interesting* crate in
  the group — **watch, do not adopt**, and revisit if R77's settings shape ever grows
  beyond a `Vec<HeaderValue>`.
- **`lily_middleware` 0.1.0** — *fails gate 2 the other way*: it declares
  `rust-version = "1.96.1"`, **above** the 1.96 floor. Also bound to the Lilyrs framework.
- **`actix-cors` 0.7.2** — *excluded on gate 5 and on fit, and it clears gates 2, 3 and 6.*
  `rust_version` 1.88, inside the floor; no RustSec page. It fails gate 5 as a
  disqualifier in this context: its runtime coupling is `actix-web`/`actix-rt`, a second
  HTTP stack and a second executor beside the `axum` 0.8.9 + `tokio` 1.53.1 R69 fixed.
  It is the right answer for an Actix Web service and the wrong answer here.
- **`rocket_cors` 0.6.0**, **`salvo-cors` 0.96.0**, **`ntex-cors` 4.0.0**,
  **`routerify-cors` 3.0.0**, **`trillium-cors` 0.1.0**, **`iron-cors` 0.8.0**,
  **`corsware` 0.2.0** — *excluded on gate 5 and on fit*, for the same reason: adopting one
  means adopting its framework. The last two target Iron, whose last release predates the
  async ecosystem entirely.
- **Framework-bound middleware bundles, each excluded on gate 5 and on fit** —
  `reinhardt-middleware` 0.3.18 (Reinhardt), `elif-security` 0.2.2 (elif.rs),
  `armature-security` 0.4.0 (Armature), `oxidite-middleware` (Oxidite; no stable release
  at all), `htmstd` 0.8.6 (Hotaru), `rocket_ext` 0.3.1 (Rocket),
  `fandhe-backend-plugin-cors` 0.4.0 (fandhe-backend), `rok-guard` 0.6.0 (rok),
  `blazingly-middleware` 0.2.2 (Blazingly), `toxi-middleware` 3.1.0 (Toxi),
  `volter-middleware` 0.1.0 (volter), `apollo-cors` 0.3.0 (Apollo),
  `bunner_cors_rs` 0.1.2 (Bunner). Each is a young framework's own middleware set; none
  exposes a `tower::Layer` for axum, and each carries two- or three-digit download counts.
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

**One candidate passed every applicable gate, and that is itself the finding.** The prompt
allows up to five; the category genuinely contains one, because "a CORS middleware for
axum" and "a CORS middleware for tower" are the same artifact.

| name | role | 90-day downloads | all-time downloads | stars | last release | maintenance state | notable adopters | one-line trade-off |
|---|---|---|---|---|---|---|---|---|
| `tower-http` (`cors` feature) | the `tower::Layer` implementing the Fetch CORS protocol for any `tower`/`hyper`/axum service | **149,725,960** | **462,114,603** | **913** | **0.7.1**, `2026-08-31T14:49:25.697237Z` | **active** | `tokio-rs/console`, `tonic-web`, `loco-rs/loco`, `rust-lang/crates.io` | you take a 35-feature middleware crate for one of its features, and a future advisory against a module you never enable will still surface in `cargo audit` output and need triage |

Figures: downloads from `GET https://crates.io/api/v1/crates/tower-http` (`crate.recent_downloads`,
`crate.downloads`); release from `.../versions` (newest with `yanked: false`); stars,
`archived` and `pushed_at` from `GET https://api.github.com/repos/tower-rs/tower-http`;
open issues from `GET https://api.github.com/search/issues?q=repo:tower-rs/tower-http+is:issue+is:open`
(`total_count` — the repository's own `open_issues_count` reads **37** and is deliberately
not used, because it counts pull requests). All retrieved **2026-09-18** UTC.

**Fit for this template, surface by surface.**

- **CLI — no effect, and that is the point.** R05 revision 3 fixes a synchronous core and a
  CLI binary with no executor in its default dependency tree. Under R69 revision 10
  `tower-http` is a dependency of the optional `crates/web` member only, so a default
  `cargo build` never resolves, downloads or compiles it. The differential resolution
  measures this from the other side: the two crates land on the **web** graph.
- **Library — no effect.** R02 revision 2 fixes a four-package workspace in which
  `crates/web` depends on `core` and `core` depends on neither front end. The CORS layer is
  an HTTP-transport concern living entirely on the far side of R01's port, so
  `crates/core`'s external-dependency allow-list is untouched and R02's
  `tests/workspace_edges.rs` guard keeps passing unamended.
- **Web — the whole surface this touches.** One module in the gated tree, one call in
  `build_router`, one dependency line, one environment variable named by R77, and the six
  acceptance criteria exercised through the in-process `ServiceExt::oneshot` idiom.

**Tradeoffs, against each alternative in turn.** Versus the ranked runner-up (unconditional
installation with an empty allowlist): given up is a branch-free composition root, one
fewer thing for a template reader to understand, and `Vary: Origin` on every response,
which is genuinely the more cache-correct default. Accepted, because `F322`'s recorded
principle is absence, and because the `OPTIONS` change is not cosmetic. Versus the
`option_layer` wrapper: given up is a uniform, declarative way to say "maybe this layer"
that would compose well if more optional layers appear. Accepted, because today there is
exactly one, and paying for it means moving `tower` out of the dev-dependency slot R69
fixed for zero behavioural gain. Versus a hand-rolled `from_fn`: given up is two crates and
~166 kB, all measured, all small. Accepted, because what is bought is a spec-conformant,
`deny(unsafe_code)`, advisory-clean implementation of a browser security protocol used in
production by the Tokio project, the gRPC organisation and the Rust project's own registry
— and because a template that hand-rolls CORS teaches every one of its users to hand-roll
CORS. Versus the framework-bound crates: given up is nothing this template can use.
Versus a same-origin deployment: given up is the simplest possible answer, which is not
available, because R69's surface ships an API with no front end attached to it.

**Accepted residual risks, named rather than hidden.** (a) `tower-http` is a 35-feature
crate and this item uses one; an advisory against an unused module would still appear in
`cargo audit` output and need triage. (b) `CorsLayer` *panics* when `allow_credentials(true)`
is combined with any wildcard; the recommended configuration never sets credentials, but
if a later item exposes that knob the panic must be converted to a boot-time error the way
`loco` does. (c) The mechanism rests on one fact — `Router::layer` being type-preserving —
so an axum `0.9` re-opens it; that is a re-verify trigger below, not a hidden assumption.

**What P03 must validate, beyond what this run executed**, is listed under `## Engines`.

**Migration implications — file-level changes in the template**, using R69 revision 10's
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
| Documentation | one row in the template's environment-variable table, stating that an empty allowlist means the middleware is not installed |
| CI | **none.** Path-based skip-gating already keys on `crates/web/**` per R69 revision 10; no new job, no new tool, no new runner |

**Not changed:** the root package's `Cargo.toml`, `crates/core`, `crates/cli`, R01's port,
R02's `tests/workspace_edges.rs` allow-list, and the CLI binary's dependency graph.

re-verify: on the earlier of 2027-03-18 or any of these events — (1) **R69 republishes** `web-extra-surface`, because every file path above comes from revision 10, which is owner-accepted but unpublished, and a published value that differs moves all of them; (2) **R75 publishes**, since it fixes this layer's ordering and the aggregate `tower-http` feature list, and must read the 0.7.0 breaking entries itself for whatever features it adds; (3) **R77 publishes**, fixing the variable name and the parsed type this item consumes as a possibly-empty `Vec<HeaderValue>`; (4) **R02 publishes** a topology other than the four-package workspace this design is written against; (5) `GET https://crates.io/api/v1/crates/tower-http/versions` reports a newest non-yanked `num` outside `0.7.x`, since a `0.8` needs its changelog read for `cors` changes; (6) `https://rustsec.org/packages/tower-http.html` acquires a third entry or `RUSTSEC-2022-0043`'s `patched` range changes — re-run `review/evidence/registry-figures.sh`, whose `atty` control distinguishes a site change from a cleared advisory; (7) `GET https://api.github.com/repos/tower-rs/tower-http` reports `archived: true`, or `pushed_at` falls more than twelve months behind; (8) **axum publishes `0.9`**, which re-opens whether `Router::layer` is still type-preserving — the single fact the conditional branch rests on; (9) the owner or R75 rules that an unconditional `Vary: Origin` and a `200` answer to every `OPTIONS` are desirable, which is the stated condition under which the ranked runner-up wins; (10) `msrv-policy`'s floor advances past **1.96**, the number gate 2 was evaluated against here; (11) the **REST API Design Standard** moves off blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` — re-run `review/evidence/rest-conformance-r2.sh`, whose blob-size and line-count assertions fail closed when the pinned object is not the one quoted, and re-read R4.17, R4.11, R5.11 and R11.7 at their new lines; (12) **R75 publishes** its layer order or its `expose_headers` list, since R11.7's ordering constraint and R4.17's list are both satisfied by R75's choices and only stated by this item.

## Parameters

This item **owns no parameter**: `inputs/prompt.md`'s `## Couplings` block carries an empty
`- owns:` line and `docs/port/PARAMETERS.md` registers no row owned by R76, so this
decision writes no `- owns` line. Inventing a registry row would be a registry edit, not a
research finding. Its `- consumes:` line is empty too; the six values below are the four
owner-fixed parameters plus the two researched values this design actually rests on, each
quoted byte-identically from the live registry.

- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**Standing of the `web-extra-surface` line, and why it is not a `CONFLICT:`.** The bytes
above are the registry's, which still carry R69 **revision 9**'s form — the gated tree at
`src/web/`, `web = ["dep:axum", "dep:tokio"]`, and `tower` as the declaring package's
dev-dependency. R69 **revision 10** is owner-accepted but unpublished
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, its
`- owns web-extra-surface` line at line 1791), and it moves the web tree into the optional
workspace member `crates/web`: `web = ["dep:rs-launch-blueprint-web"]` on the root package,
`axum` 0.8.9 and `tokio` 1.53.1 declared **non-optionally** inside `crates/web/Cargo.toml`,
`tower` 0.5.3 as `crates/web`'s dev-dependency, the gated tree reading `crates/web/src/`,
tests in `crates/web/tests/`, and skip-gating keyed on `crates/web/**`. **This decision's
design uses revision 10's paths** — `crates/web/src/cors.rs` and `crates/web/Cargo.toml` —
while the `- assumes` line above keeps the registry's current bytes, because the line must
match the registry byte-for-byte or publication fails. R69's republication is recorded as
a re-verify trigger. This is deliberately **not** a `CONFLICT:`: nothing in this
recommendation needs R69's value changed, only the paths R69 has already accepted.

**How the other five bear on the decision.** `msrv-policy` is what turns
`rustc 1.98.0` into the **1.96** floor that gate 2 was evaluated against, over the whole
resolved tree and not just the recommended crate. `rust-edition` is the edition the probe
crate declared throughout, so every behavioural result above was observed under `2024`.
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

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4, `arm64`, 2026-09-18.
`gh version 2.98.0 (2026-08-20)`, `curl 8.7.1`, `jq-1.8.2`,
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` — invoked throughout as `/usr/bin/grep`
by absolute path, and its version is printed beside every count in both logs.

**Working directory for both scripts:**
`research/runs/R76/2026-09-17T034010Z-d958540e8834/review/evidence/`.

**Commands executed, and their status.**

```
# revision 2 — the new check
./rest-conformance-r2.sh > rest-conformance-r2.log 2>&1   # exit 0, RESULT: PASS, 57 assertions, 0 SKIP

# revision 1 — retained byte-identical, logs as committed at 3b933872
./registry-figures.sh    > registry-figures.log    2>&1   # exit 0, RESULT: PASS, 54 assertions, 0 SKIP
./probe-checks.sh        > probe-checks.log        2>&1   # exit 0, RESULT: PASS, 29 assertions, 0 SKIP
./decision-self-check.sh > decision-self-check.log 2>&1   # exit 0, RESULT: PASS, 43 assertions, 0 SKIP
```

**One revision-1 script now fails when re-run, by construction, and this revision refuses
to hide it.** `decision-self-check.sh` asserts the H1 line byte-for-byte, and that line
names revision 1. Retitling the document makes exactly that assertion false. The script
and its log are kept byte-identical as the revision brief requires, so rather than leave a
committed script that fails for an unexplained reason, `rest-conformance-r2.sh` **runs it
and bounds the damage**: section E asserts that it fails on the H1 assertion and on
**nothing else**, that its other 42 assertions still pass, and that its `FAIL` count is
exactly 1. An auditor rerunning revision 1's evidence therefore sees a failure this
document predicted, located and measured, confined to the revision marker.

Each script sets `set -euo pipefail` at the top, so a failing command inside a pipeline
cannot be masked by a succeeding one. Each asserts on **content**, never on an exit code
alone, and each prints `PASS=`, `FAIL=` and `SKIP=` counts that sum to its total and exits
non-zero on any `FAIL`. Every `SKIP` branch names its reason; no branch was taken in these
runs, which is recorded as `SKIP=0` rather than left implicit. None of the three needs a
`.git` directory, so all three run unchanged from a clean `git archive HEAD` extraction —
verified by extracting one and re-running all three there. No personal address appears in
any script, `User-Agent` header or log; the `User-Agent` the registry scripts send is the
repository URL `https://github.com/smorinlabs/rs-launch-blueprint`. All scratch work
happens inside one `mktemp -d` directory under `$TMPDIR` that a `trap` removes on exit;
the probe crate is created with `cargo new --vcs none`, so no nested Git repository and no
`target/` tree is ever created inside this repository.

**What this ran, and what it deliberately did not.** It verified claims. It did not
implement the recommendation: there is no working seam, no service, no composition root,
no settings type, no acceptance scaffold and no template fixture. The probe is a throwaway
crate whose only purpose is to make three installation policies observable side by side,
and it is deleted when the script exits.

**`rest-conformance-r2.sh` — 57 assertions over six sections, the revision-2 check.**
(A) The pinned artifact is identified before anything is quoted from it: blob type, size
**190,161** bytes, **3,427** lines, the sha256 of the extracted bytes, the `# REST API
Design Standard` first line, the `**Version 2.0.0.**` marker, and the blob's reachability
from commit `0850d43e…` — so a reader who cannot reproduce those numbers knows immediately
that they are reading a different document, rather than discovering it through a quotation
that silently moved. (B) Seventeen line-addressed quotations, each asserted byte-for-byte
at its line: R1.6 with its switch vocabulary and its "client audience" clause, R1.7, the
§1.10 `request-id` and `Allow` register rows, R4.10, R4.11, R4.17 with its continuation
line, R5.11, R8.1, R8.2, R8.10, R8.11, R11.7, and Appendix A's R4.17 checklist row. Two
counting assertions do the work the prose rests on: **zero** occurrences of CORS terms in
the applicability-switch vocabulary, and **zero** in the five-axis deployment-profile
table. (C) Nine probe observations measuring each conformance claim, listed below. (D) A
loop asserting that the decision names every one of the eleven rules, so R1.7's
no-silent-deviation discipline is enforced mechanically rather than by re-reading, plus
assertions that the document names the ruling and pins the blob. (E) The bounded
revision-1 breakage described above. (F) The `OVERRIDE` namespace enumerated from the
repository index, printed as an explicitly labelled snapshot and asserted only where the
assertion survives another agent's commit — that `OV-01` is taken, that the namespace is
populated, and that this decision allocates no number from it. It skips by name, rather
than passing silently, in an archive extraction with no `.git`.

| Observation | Result | Rule it settles |
|---|---|---|
| `X1` | `access-control-expose-headers=request-id,retry-after,ratelimit` | R4.17 conforms under revision 2 |
| `X2` | **no** `access-control-expose-headers` at all | R4.17 was violated by revision 1 — the measurement that moved the recommendation |
| `X3` | `access-control-expose-headers=*` | the wildcard lists no header name, so it does not satisfy R4.17 |
| `X4` | preflight `200`, `content-length: 0`, no `content-type`, no expose header | R4.17 not engaged on a preflight; R4.10 not engaged either, since no representation is selected |
| `X5` | `405 Method Not Allowed`, `allow: GET,HEAD` | R5.11 conforms, and the conditional install is what preserves the response |
| `X6` | preflight `200` with **no** `request-id` | R11.7 violated when the stamping layer sits inside `CorsLayer` |
| `X7` | preflight `200` **with** `request-id=req_probe` | R11.7 conforms when it sits outside — the constraint handed to R75 |
| `X8` | `200`, no `vary` | R4.11's stated exception, with the allowlist empty |
| `X9` | `200`, `vary: origin`, no `access-control-allow-origin` | R4.11 conforms with the allowlist configured |

**`registry-figures.sh` — 54 assertions over nine sections.** (A) `tower-http`'s newest
non-yanked version is `0.7.1`, published `2026-08-31T14:49:25.697237Z`, declaring
`rust-version 1.65`, with `0.7.0` at `2026-06-15T14:01:18.432430Z` — the sourced release
facts the version differ against the owner reference rests on. (B) The `cors` category
enumerated: `meta.total` **36**, all 36 read across two pages and printed by name with
their figures, `q=cors` reporting **1,452** name matches of which the 40 highest-ranked
were read, and an assertion that `tower-http` appears on **neither** keyword page. (C) The
declared `rust_version` of every candidate excluded on gate 2, asserted one by one —
`null` for `axum_cors`, `rok-cors`, `cors-core` and `tower-http-cors-config`; `1.96.1` for
`lily_middleware`; `1.80` for `hyper-cors` and `1.88` for `actix-cors`, both of which clear
the gate and are excluded on other grounds. (D) `hyper-cors` 0.2.0's published dependency
list contains **no** `tower`, `tower-layer` or `tower-service`, which is the ground it is
excluded on. (E) RustSec answers `200` for `tower-http` and for the `atty` control, lists
exactly the two known entries, and `RUSTSEC-2022-0043`'s own record declares
`patched = [">= 0.2.1", ">= 0.1.3, < 0.2.0"]`, `os = ["windows"]` and `ServeDir`. (F) The
0.7.0 changelog section carries exactly **one** `cors` entry and **seven** `breaking:`
entries, **none** of which names `cors`. (G) The published `.crate` artifacts for 0.6.11
and 0.7.1 are downloaded, their sha256 printed, and read: `default = []`, `cors = []`,
`#![deny(unsafe_code)]`, zero occurrences of `unsafe` anywhere in the `cors` module, the
`Method::OPTIONS` short-circuit, the unconditional `vary.to_header()` call,
`ensure_usable_cors_rules`, `AllowOrigin::list`, and `OriginInner::default()` being an
empty `List` rather than a `Const` — which is why even a bare `CorsLayer::new()` still
derives `Vary: origin` in 0.7.1. It also asserts that `update_vary_header` exists in 0.7.1
and **does not exist** in 0.6.11, which is the #674 relaxation in source form. (H) Three
`gh api` calls, spaced 21 s apart: the repository (913 stars, `archived: false`,
`pushed_at 2026-09-13T22:53:22Z`), the open-issue `search/issues` `total_count` (**30**,
with `open_issues_count`'s **37** printed and explicitly not used), and
`rust-lang/crates.io`'s `Cargo.toml`, asserted to contain `tower-http = { version = "=0.7.1"`.
(I) The three adopter manifests, each asserted to activate `"cors"`; upstream CI's
`os: [macos-latest, windows-latest]` job and its `rust-toolchain@1.65` MSRV job; and
`loco`'s `fn is_enabled` and `cors.max_age(Duration::from_secs(max_age))` lines. (J) The
issue-responsiveness figures recomputed from the committed snapshot by
`author_association` rather than by maintainer name, asserting 2 answered, 8 unanswered, 4
of those closed, and at least one opened outside the fetched comment page's window.

**`probe-checks.sh` — 29 assertions over five sections.** The probe pins `axum =0.8.9`,
`tokio =1.53.1` with R69's feature list, `tower-http =0.7.1` with only `cors`, and
`tower =0.5.3` with `util` as a **dev-dependency only**. It prints **thirteen** `CHECK`
lines, which are the ten behavioural rows the research report tabulated with its `Q2`,
`Q3` and `P2`/`P3` rows split into one line each for `GET` and `OPTIONS`; the report's
remaining two rows, the dependency-tree delta and the build measurement, are sections D
and E below. Every one of them reproduced, and check `E` additionally carries the
`access-control-max-age: 600` assertion the report could not make. In summary:

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
nothing removed, maximum declared dependency `rust-version` **1.80**, nine packages
declaring none and **neither added package among them** — and then asserts three facts
about `tower`'s placement: it is already in the non-dev graph through `axum`; `axum`
already activates its `util` feature, so the rejected `option_layer` alternative costs no
crate and no feature but does cost a direct dependency declaration; and `tower-http` with
only `cors` on has **no `tokio` edge**. Section E measures gate 6: stripped binaries
**502,264 → 668,744 bytes**, a cost of **+166,480 B**, asserted to be positive and under
400 kB. Build seconds are printed for two runs per arm and are **never asserted**.

**`decision-self-check.sh` — 43 assertions over six sections**, covering the obligations a
reader cannot check by reading. (A) The exact H1, the four H2 sections in order with no
fifth, the absence of `## Supersedes`, the presence of `### Principles and implementation`,
and exactly one `re-verify:` occurrence in the whole file — at line start, and nowhere
else. (B) The six `- assumes` lines extracted from `docs/port/PARAMETERS.md` by a Python
reader and `diff`ed against the decision's own, so the byte-for-byte comparison the
packaging validator performs is executed here rather than promised; plus the absence of any
`- owns` or `CONFLICT:` line and a spot-check that two values are written bare, with no
backticks or commentary after the `= `. (C) The gate-1 `inapplicable` string in full, and
then a **mechanical enumeration**: every case-insensitive occurrence of the gate's own
root word is listed and its count asserted to be exactly the four accounted-for locations,
with six struck terms asserted absent — so surviving gate-1 reasoning would fail the check
rather than have to be spotted by re-reading. (D) No email-shaped token anywhere under
`review/`. (E) `raw/opus.md` hashing to the value `## Engines` cites, that hash appearing
in the document, `validate_answer_text(raw, "crate")` reporting zero shape errors, and the
deferred Codex leg recorded by its ruling identifier. (F) Eleven figures the decision
quotes, each asserted to be present **both** in the sibling log that produced it and in the
decision that cites it, plus both logs ending in `RESULT: PASS` with no `ASSERT FAIL` line.

**Reproduction, stated precisely rather than claimed.** Each script was re-run in place
before this decision was committed and the rerun `diff`ed against the log cited here, and
then extracted from a clean `git archive HEAD` and re-run there. What the diffs actually
showed, rather than what would be convenient to say:

- **`rest-conformance-r2.log` reproduces byte-for-byte apart from its header `date(UTC)`
  line and section F's namespace snapshot.** Everything it *asserts* is read either from
  an immutable git blob or from a probe pinned to exact crate versions, so sections A
  through E have no counter and no wall-clock measurement in them to drift. Section F is
  the exception and says so in the log itself: it prints the live `OVERRIDE` namespace,
  which sibling agents are changing, and its assertions are written to survive that.

- **`registry-figures.log` reproduced byte-for-byte apart from its header `date(UTC)`
  line** on a rerun twelve minutes later — every `FIGURE`, every enumerated crate name and
  every `ASSERT` line matched exactly. That is a same-day result and must not be read as a
  durable one: the lines prefixed `FIGURE` are point-in-time by construction, and the two
  download counters, the star count, the open-issue `total_count`, the `pushed_at`
  timestamp and a search's `meta.total` will all move as the ecosystem does.
- **`probe-checks.log` does not reproduce byte-for-byte.** Three things vary: the header
  `date(UTC)`, the `mktemp` path embedded in one `cargo tree` line, and the four
  build-second figures — which is exactly why no compile-time claim is made. The two
  stripped byte sizes, the dependency-tree delta and all thirteen `CHECK` observations
  were identical across runs.
- **The rule for comparing across the difference:** every line prefixed `ASSERT` is
  identical in text and in verdict on every run of both scripts, and so are the
  `PASS`/`FAIL`/`SKIP` counts. Those are what an auditor diffs. Both were confirmed
  identical on the reruns behind this paragraph.

Where a source was
volatile enough that a *derived* number had to be stable, it was snapshotted rather than
re-fetched: `review/evidence/snapshots/tower-http-issue-triage.json` holds the
field-projected issue and comment records (issue number, timestamp, author login,
`author_association` — comment bodies are deliberately omitted), and section J computes the
responsiveness figures from that file, so those numbers do reproduce byte-for-byte.

**What could not be verified here, and is left for P03** (also listed under `## Engines`):
no latency or throughput benchmark of the layer was run, so no performance figure is
claimed beyond the measured byte cost; no compile-time cost is claimed at all; whether
`cargo audit` ever reports `RUSTSEC-2022-0043` against 0.7.1 was not executed — the
advisory's own `patched` range was read instead; Windows behaviour was not exercised,
which `target-os-matrix` does not require; and the `q=cors` name search read the 40
highest-ranked of 1,452 results rather than all of them, with the keyword enumeration
(all 36) being the complete one and the name search a cross-check against it.

**Planned for P03, not run here**, because each needs the template, which does not exist:

```bash
# 1. The default build never resolves the CORS crate.
cargo tree -p rs-launch-blueprint -e normal | grep -q tower-http && exit 1
# 2. The web member builds with the feature on, on both fixed runners.
cargo build --features web --locked
# 3. The six acceptance criteria, as ordinary integration tests.
cargo test --features web --locked -p rs-launch-blueprint-web cors
# 4. The MSRV gate, over the tree the feature pulls in.
cargo +1.96 check --features web --locked
# 5. No open advisory in the resolved graph.
cargo deny --all-features check advisories
```

Expected: (1) exits 0, because `tower-http` sits behind the optional member; (2) succeeds
on `ubuntu-latest` and `macos-latest`; (3) all six criteria green, with the empty-allowlist
cases asserting the **absence** of `access-control-allow-origin` *and* of `vary`, and
asserting `405` on an unconfigured preflight — the assertion that fails if anyone ever
"simplifies" the branch away; (4) succeeds, since the measured tree maximum is 1.80;
(5) exits 0, since the only live `tower-http` advisory is Windows-only, `fs`-only and
patched since 0.2.1.

## Engines

- **Claude Opus 5 — `raw/opus.md`** (sha256
  `c2792a6957df5b84fcb6438f2f14312fcae8bbd801055e07f1235e63333a5cf4`; 15 H3 fields, shape
  validated by `validate_answer_text(text, "crate")`, which reports no error). The only
  research report registered for this item.
- **The REST API Design Standard v2.0.0** — not an engine, but a binding input added
  after revision 1 by owner ruling W2-REST, read at blob
  `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` of commit
  `0850d43e45d919ef5e37f7174c4212b46013c49f` (190,161 bytes, 3,427 lines).
  `review/evidence/rest-conformance-r2.sh` asserts the blob's size, line count, version
  marker and reachability from that commit before quoting a single rule, so a quotation
  that drifted from its source would fail the check rather than pass unnoticed.
- **Codex — absent, by the controller's deferral under owner ruling W1-CODEX3**
  (2026-09-18, `docs/planning/p02/owner-decisions.md` section 12: the Codex account is at
  its usage limit, tested that day, so "the programme proceeds without Codex"). This item
  is FOCUSED tier, whose engine set is `codex, opus`, so **this decision is synthesized
  from a single engine** and has no independent second model family to cross-check its
  figures against. That is recorded as a reduction in the evidence base, not treated as
  complete coverage. Because no second engine could contradict the report, **every
  load-bearing claim was re-verified at source in this run** rather than carried: the
  crates.io and GitHub figures were re-fetched with their endpoints and this run's UTC
  date, the `cors` module's 0.6→0.7 change was read from both published `.crate`
  artifacts and then measured behaviourally, the `rust-lang/crates.io` pin was read through
  `gh api`, and every behavioural probe check was re-executed on `axum` 0.8.9 + `tokio` 1.53.1.

**Revision history.**

- **Revision 1** — 2026-09-18, commit `3b933872`, sha256
  `6fd6e1f90348047fe72996a0f4ade667d91c062c305c70571b57ac8c6b83740b`. The research
  synthesis: the crate selection, the conditional-install policy, all six fitness gates,
  the category enumeration, and the three evidence scripts whose 126 assertions this
  revision leaves untouched. Its full text is one commit away in this repository's
  history; it is not reproduced here, because this revision adds to that document rather
  than replacing its reasoning, and the four-H2 contract leaves no place to carry a
  verbatim copy.
- **Revision 2** — 2026-09-18, this document. A **pre-audit** revision occasioned by owner
  ruling **W2-REST**, which made the REST API Design Standard v2.0.0 binding on the HTTP
  surface after revision 1 was written. Eleven rules were located in the pinned blob,
  quoted at their lines and dispositioned; one of them, **R4.17**, moved the
  recommendation. Nothing was re-researched: the crate, the version, the policy, every
  gate result, every figure and all six `- assumes` lines are byte-identical to revision 1.

**What the standard changed, and what it left alone.** The ruling reached this item after
its research was complete, so the honest account is not "the design anticipated the
standard" but "the design met it in ten places and missed it in one".

1. **R4.17 — missed, and the miss was measured.** Revision 1 configured
   `allow_origin`, `allow_methods`, `allow_headers` and `max_age`, and no `expose_headers`.
   Check `X2` shows the consequence: with an allowlist configured, the response carries no
   `access-control-expose-headers`, so a cross-origin browser client cannot read
   `request-id`, `Retry-After`, `RateLimit` or any other standard-bound header — they are
   not CORS-safelisted, which is the mechanism R4.17's own text explains. The
   recommendation moved. This is allowed before acceptance and is stated in the revision
   note rather than folded quietly into the code block.
2. **R11.7 — met, but for a weaker reason than now available.** Revision 1 already handed
   R75 the constraint that request-id and security-header layers must sit outside
   `CorsLayer`, grounded on py's ordering contract. Checks `X6` and `X7` now ground it on
   a MUST: inside, the preflight `200` carries no `request-id`; outside, it does. The
   hand-off did not change; its authority did.
3. **R5.11 — met, and the standard supplies a second reason for the central decision.**
   Revision 1 rejected unconditional installation because it turns a `405` into a `200`.
   Under R5.11 that `405` is obliged to carry `Allow`, and the unconditional form deletes
   the response that carries it. The argument for the conditional branch is now
   protocol-grounded as well as precedent-grounded.
4. **R1.6 — a tempting escape route, closed by reading rather than assuming.** A
   CLI-first template might hope to declare CORS out of scope by an applicability switch.
   There is no such switch: the vocabulary is `webhooks`, `async-operations`,
   `bulk-operations` and `streaming`, asserted by counting CORS terms in those lines and
   finding zero, and R1.6 places "client audience" in the conformance note's free text
   explicitly. R4.17 binds through its own conditional clause instead, which this design
   satisfies where it fires.
5. **R4.10, R4.11, R8.1, R8.2, R8.10, R8.11 — met or not engaged, each stated.** Under
   R1.7 a rule passed over in silence is nonconformance regardless of merit, so each is
   dispositioned in the table under `## Decision` and `rest-conformance-r2.sh` section D
   asserts that the document names it.

**No `OVERRIDE (OV-nn)` is recorded, and this item deliberately reserves no number.**
After the R4.17 move, every quoted rule conforms or is not engaged, so there is nothing to
argue against. **A correction is owed here, because an earlier draft of this revision got
it wrong, and the way it was wrong is worth more than the number.** That draft stated that
`OV-01` was free, on the strength of a search a timeout had killed, whose empty output was
read as an empty result — the truncated-search failure this programme has hit before. Run
properly, `git grep -o -E "OV-[0-9]{2,}" -- research docs` shows **`OV-01` is in use**: it
is R60's deviation from the CLI Design Standard, refused by the owner on 2026-09-14.

**No "next free" number is stated, and that is a deliberate refusal rather than an
omission.** The namespace is being allocated *right now* by sibling items revising against
this same W2-REST ruling in this shared worktree, and it moved between two runs of
`rest-conformance-r2.sh` while this revision was being written: four numbers that were
absent on the first run were present on the second. Any figure of the form "the next free
number is OV-nn" would therefore be false before an auditor read it. The evidence log
carries the enumeration as a timestamped snapshot, explicitly labelled as one, and the
script asserts only what survives another agent's commit: that `OV-01` is taken, that the
namespace is populated rather than empty, and that this decision allocates nothing from
it. An item that needs a number must enumerate at its own commit.

**What P03 must additionally validate under this revision.** That the assembled
`exposed_headers` list actually names every standard-bound header the finished stack
emits — this run measured the mechanism with a three-name stand-in, not the real list,
which only exists once R70, R72, R74, R75 and R80 have landed. And that R75's published
order puts every preflight-stamping layer outside `CorsLayer`, which check `X7` shows is
the only arrangement satisfying R11.7 on a preflight.

**What reproduced, what did not, and what this run corrected.** With one engine there are
no inter-engine disagreements to settle; what follows is this synthesis against its single
report.

1. **Reproduced exactly.** Every crates.io figure (90-day **149,725,960**, all-time
   **462,114,603**, 0.7.1 at `2026-08-31T14:49:25.697237Z`, 0.7.0 at
   `2026-06-15T14:01:18.432430Z`, 33 non-yanked of 39); every GitHub figure (**913** stars,
   `archived: false`, `pushed_at 2026-09-13T22:53:22Z`, **30** open issues by
   `search/issues`, `open_issues_count` **37**, `loco` **9,152**, `console` **4,598**);
   **3,486** reverse dependencies; the `cors` keyword enumeration (**36** total, 30 + 6
   across two pages, and the same six on page 2); every excluded candidate's
   `rust_version`; the RustSec state and `RUSTSEC-2022-0043`'s `patched`/`os`/`ServeDir`
   fields; every source line cited in `tower-http-0.7.1` (`default = []` at `:161`,
   `cors = []` at `:117`, `#![deny(unsafe_code)]` at `lib.rs:200`, the sole `unsafe` at
   `serve_dir/tests.rs:1246`, `ensure_usable_cors_rules` at `mod.rs:820`); the
   `rust-lang/crates.io` `=0.7.1` pin at `Cargo.toml:170`; the three adopter manifest
   lines; upstream CI's OS and MSRV jobs; the dependency-tree delta (57 versus 55, exactly
   `tower-http` + `bitflags`, the same nine undeclared packages, maximum 1.80); and
   **every behavioural observation the report tabulated, character for character** in
   status and header set.
2. **Gap closed.** The report stated plainly that `.max_age(Duration::from_secs(600))`
   appeared in its recommendation "**not** on an executed check in this run", resting on
   the method signature and on `loco`'s own call. This run **compiled and measured it**:
   check `E` observes `access-control-max-age: 600` on the preflight response. The gap no
   longer exists.
3. **Figure recomputed, and one of its two components corrected.** The report gave issue
   responsiveness as `#713` answered "**3 minutes**" after opening and `#702`
   "**4 h 41 m**". Recomputing from the API by `author_association` rather than by
   maintainer name gives `#713` at **0.05 h** (2 min 52 s, so "3 minutes" is right to the
   stated precision) and `#702` at **4.55 h** — **4 h 33 m, not 4 h 41 m**. The report's
   structure (2 of 10 answered, 8 unanswered, 4 of those closed, 2 opened by a maintainer)
   is otherwise confirmed. **A limit the report did not state, added here:** the fetched
   comments page reaches back only to `2026-05-22`, so for `#676` and `#668` — both opened
   earlier — the absence of a maintainer comment is *unproven* rather than measured.
4. **Claim narrowed on new evidence.** The report wrote that the `cors` module's "only
   change across 0.7.0 is 'relax the `Vary` header defaults (#674)' — non-breaking for this
   use". The changelog reading is exact. But this run measured the change rather than
   inferring it, by running the same probe against 0.6.11 and 0.7.1: in **this template's
   own recommended configuration** the emitted `Vary` value narrows from
   `origin, access-control-request-method, access-control-request-headers` to `origin`.
   The 0.6→0.7 move is therefore compatible but **not unobservable**, and the decision now
   says which observable changes and in which direction. The source cause was read too:
   0.7.1 derives the header in `update_vary_header`, a function 0.6.11 does not have.
5. **Framing corrected on measurement.** The report rejected alternative C on the ground
   that `tower::util::option_layer` "promotes `tower` from *dev-dependency only* … to a
   normal dependency of `crates/web`", which reads as a tree or feature cost. Measured:
   `tower` 0.5.3 is **already** in the non-dev graph through `axum`, and **`axum` already
   activates `tower`'s `util` feature**, so `option_layer` adds no crate and no feature at
   all. Its real and only cost is a **direct dependency declaration** on `crates/web`,
   moving `tower` out of the dev-dependency slot R69 fixed. The alternative is still
   rejected, on that precise ground plus the `axum-extra` 0.9 body-type break; the
   reasoning is now accurate about what it costs. The same measurement is what lets this
   decision state positively that adopting `tower-http` leaves `tower` a dev-dependency.
6. **Could not reproduce, and withdrawn.** The report's gate-6 compile-time figure —
   "`+4.1 s` of clean release build" — did not reproduce. Across two clean release builds
   per arm on this host the arms did not separate beyond run-to-run variation: the cited
   `probe-checks.log` records **17.7 s** and **21.4 s** without the dependency against
   **16.4 s** and **13.3 s** with it, and an immediate re-run of the same script recorded
   **15.0 s** and **14.8 s** without against **17.8 s** and **13.6 s** with. The arm
   carrying the extra crate was the faster one on the first of those runs and the slower
   one on the second, and the within-arm spread (13.3 s to 21.4 s) is larger than any
   between-arm gap. **This decision therefore claims no compile-time cost at all.** The binary-size direction and order of magnitude did reproduce, on a differently
   shaped probe: **+166,480 B** here against the report's **+149,056 B**; both are the
   same finding and neither percentage form should be carried forward.
7. **Over-claim found and repaired.** The report wrote that all 36 `cors`-keyword crates
   were read and that "each is dispositioned in `### Excluded by gate` or
   `### Up-and-comers`". The reading is confirmed, but the disposition was not complete:
   **fourteen** of the 36 are named nowhere in the report — `tauri-plugin-cors-fetch`
   (35,062 all-time, the third-largest crate on the list), `tauri-plugin-better-cors-fetch`,
   `pdk-cors-lib`, `reinhardt-middleware`, `warp-cors`, `wasm-dev-server`, `cors-proxy`,
   `rocket_ext`, `elif-security`, `armature-security`, `oxidite-middleware`, `just-serve`,
   `htmstd` and `fandhe-backend-plugin-cors`. All fourteen are dispositioned in this
   decision, on scope (Tauri webview plugins, gateway policy libraries, forwarding proxies
   and static development servers) or on gate 5 and fit (another framework's middleware
   set). None changes the outcome, and `registry-figures.sh` now prints every one of the 36
   by name with its figures so the enumeration is auditable rather than asserted.
8. **Stale citations corrected.** The report cited **R02 revision 1** and **R05 revision
   2**. The current accepted revisions are **R02 revision 2** (four-package workspace,
   composition root in the root package) and **R05 revision 3** (synchronous core,
   `spawn_blocking` in the web handlers). Both still hold everything this item leans on;
   the citations are updated and the conclusions are unchanged.

**Uncertainty, stated where the evidence is incomplete.** Confidence is **high on the
crate** — the category was enumerated rather than recalled, three independent well-regarded
projects were shown activating this exact feature by reading their manifest lines, and the
framework's own maintainers document the idiom in their own example. Confidence is **high
on the mechanism**, because the alternative was not argued away but measured away.
Confidence is **medium on the version**: 0.7.1 was 18 days old at retrieval and the owner
reference says 0.6, and while the `cors` module's only 0.7 change is the narrowing measured
here and the Rust project's own registry already pins `=0.7.1`, a caret requirement on a
young minor line carries more exposure than a mature one. Two further limits are named
rather than papered over. First, **no published Rust web-service *template* was found that
documents allowlist-gated CORS installation as a named, reusable pattern** — the prompt's
LOW question is therefore answered *affirmatively for a framework* (`loco-rs/loco`'s
`is_enabled()` registry) and *negatively for templates*. Second, **single-engine
synthesis** means every judgement above rests on one model's survey plus this
synthesizer's own re-verification, with no adversarial second lens; where that matters
most is the negative claim that no maintained tower-native alternative exists, which rests
on the enumeration rather than on two engines agreeing.

**What P03 must validate.** (1) That the conditional branch survives contact with R69's
real `build_router` and R77's real settings type, with `Router::layer` still
type-preserving at whatever axum version the template pins. (2) The six acceptance
criteria as ordinary integration tests, with the empty-allowlist cases asserting the
absence of both `access-control-allow-origin` and `vary` and asserting `405` on an
unconfigured preflight — the assertions that fail if the branch is ever "simplified" away.
(3) That `cargo tree -e normal` on the default build finds no `tower-http`. (4) That
`cargo +1.96 check --features web --locked` passes over the real tree, not the probe's.
(5) That `cargo deny check advisories` is clean over the real graph. (6) That `.max_age`
survives whatever shape R77 gives the settings type. (7) The compile-time and binary-size
cost of the dependency **in the real template**, where the surrounding code is large enough
for the figures to mean something — this run's probe is too small for its percentages to
transfer, and its build-second measurement produced no usable signal at all.
