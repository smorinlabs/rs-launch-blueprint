# 2026-09-22 — R72 — api-pagination (bundle, Deep) — decision (revision 5)

Revision 1: actor `synth-opus-2026-09-18T215915Z-af997c2abb5a`, model `claude-opus-5`.
Revision 2: actor `synth-opus-2026-09-18T215915Z-af997c2abb5a-r2`, model `claude-opus-5-5`.
Revision 3: actor `synth-opus-2026-09-18T215915Z-af997c2abb5a-r3`, model `claude-opus-5-5`.
Revision 4: actor `synth-opus-2026-09-18T215915Z-af997c2abb5a-r4`, model `claude-opus-5-5`.
Revision 5: actor `synth-opus-2026-09-18T215915Z-af997c2abb5a-r5`, model `claude-opus-5-5`.
Item kind `bundle`, effort tier `deep` (three engines: Muse, Opus, Doxa). None of the
synthesizers produced any of the three raw reports. Nothing has been published for R72, so
there is no `## Supersedes`.

**Revision note (revision 5).** The judgment audit of revision 4 (`review/audit-fable.r4.md`,
against revision 4's sha256 `05b4985aefdabdc8496b0d0ec8abe54482b6a615a519cf3265b71559fb19f95a`,
preserved byte for byte at `review/R72-r4-snapshot.md`) rejected it on four fidelity findings.
**The recommendation does not move**, and OV-10 is still returned unused. Each repair is listed
below with where it lands.

| Audit finding | What was wrong | What revision 5 does |
|---|---|---|
| JA4-01 (JF-3) | "This decision follows Opus on the contract" hid a departure: Opus rejects `limit=0` and `limit=101` with `400`, this decision with `422`, and no Disagreement recorded it | The Opus row states Opus's `400`; Disagreement 7 quotes `raw/opus-…332d0.md:168`, `:278`, `:437` and `:1093`–`:1094` (`I71`–`I75`) and adjudicates the status on R5.3 (`S39`–`S44`); the lead sentence of `## Engines` excludes the status from "follows Opus on the contract" |
| JA4-02 (JF-1 / JF-5) | The R6.4 ground and the planned P03 tests carried `P09`'s exact header set into the template, which R7.1 and R11.7 would make fail; R11.7 had no disposition | The R6.4 ground is restated as the two absences. `P09`'s exact-set assertion is marked probe-scoped in the Migration table, in Validation strategy item 1 and in the `P09` check row. The R7.x row now disposes R7.1 and R11.7 as `N/A with reason`, owned elsewhere, with the note that R72's tests must not constrain those headers (`S80`–`S82`, `I76`–`I78`). The row is extended, not added, so the tally is unchanged |
| JA4-03 (JF-4 / JF-7) | "R01 fixes the port's return type" cited checks on R01's handler observable and fake; R01's behavior 6 changes form and was not reconciled | The port claim is re-cited to R03's rule 1, owner-accepted and unpublished (`I81`–`I84`); R01 declares no port method signature (`I80`). `I19` is no longer cited for a port signature. Coupling 3 states that behavior 6's handler observable is superseded in form by R6.1's envelope, that its principle is preserved by `P08`, and that no `BASELINE-REVIEW:` or `CONFLICT:` line is needed (`I79`, `I86`) |
| JA4-04 (JF-7) | "axum and serde are already required by the `web` feature" contradicted R69's value, which leaves `serde` ungated | The sentence is replaced with the audit's text verbatim (`I85`) |

The revision-4 note below is kept as history.

**Revision note (revision 4).** The judgment audit of revision 3 (`review/audit-fable.r3.md`,
against revision 3's sha256 `fd47a10100ed1e32001858c705c2ac79b7f142e0e7e87feb482f308de07584b0`,
preserved byte for byte at `review/R72-r3-snapshot.md`) rejected it on two findings. **The
recommendation does not move**, and OV-10 is still returned unused: R13.3 is met by a guard,
not departed from. Each repair is listed below with where it lands.

| Audit finding | What was wrong | What revision 4 does |
|---|---|---|
| 1 (JF-5 / JF-1 / JF-4) | The `R13.x` row disposed R13.3, the per-endpoint `stream` rejection guard, as switch-scoped `N/A`; the clause "R69's surface declares no streamed collection" cited nothing | R13.3 is split into its own row and **conforms**: the `Pagination` extractor refuses `stream`, with any value, with `400` (`P15`), and the standard's text is asserted (`S68`–`S79`). The remaining §13 rules keep the switch-scoped `N/A`. The uncited R69 clause, and the uncited allocation of the switch declaration to R69, are removed. The tally is recounted: twenty-two rows, fourteen `conforms` |
| 2 (JF-2 / JF-4) | No repository or open-issue figures for `axum-api-kit` and `page-turner`; the `axum-api-kit` push claim cited other repositories' figures; `page-turner` had no maintenance state | A fifth, additive fetch retrieved both repository records, both open-issue counts and `page-turner`'s README (`r72-fetch-revision4.sh`, 5 endpoints, 0 gaps). The values are asserted (`F74`–`F79`), the push claim cites `F74.c`, and `page-turner` is rated **stable-quiet** on the rubric |

The revision-3 note below is kept as history.

**Revision note (revision 3).** The judgment audit of revision 2 (`review/audit-fable.r2.md`,
against revision 2's sha256 `fd632ba827ce04b1e22f16c22a7af863071aa388b3b8035b8a9de69c5067961c`,
preserved byte for byte at `review/R72-r2-snapshot.md`) rejected it on six findings. **The
recommendation does not move**, and OV-10 is still returned unused. Each repair is listed
below with where it lands.

| Audit finding | What was wrong | What revision 3 does |
|---|---|---|
| 1 (JF-3) | `## Engines` omitted the four raw `CONFLICT:` lines two Doxa legs raised against R69 | Each is quoted with its leg and raw line and disposed, and RUNBOOK §4 is stated not to apply (`## Engines`; checks `I44`–`I56`) |
| 2 (JF-4 / JF-7) | Coupling 1's third ground quoted R69's `axum-extra` sentence in part and reversed its reading | R69's sentence is quoted in full, and the ground is dropped and restated accurately. The placement of `dep:base64` in `web`, rather than in a separate feature that requires `web`, is argued from the value's own partition of later items (coupling 1; `I57`–`I70`). No `CONFLICT:` line: the argument holds on the value's text, and the one inference it rests on is stated |
| 3 (JF-4) | Alternative D and the page-envelope runner-up misstated what `api-bones` offers | `KeysetPaginatedResponse<T>` and the crate's cursor types are named, the runner-up is re-derived, and the refusal is restated on the actual differences (`C49`–`C63`) |
| 4 (JF-4 / JF-8) | "Seven of the ten candidates" declare no `rust-version` | Six of the eleven candidate crates, which is five of the ten gate-table rows, at both places (`F73`) |
| 5 (JF-1 / JF-5) | R6.8 was called `MAY`, and two passages prescribed opposite conformance-note contents | R6.8's ground is restated. Both passages now say the note gains no `N/A declarations:` row from R72 (`S62`–`S67`) |
| 6 (JF-2) | Issue responsiveness was missing for the seven declined candidates' repositories that `F41` and `F42` do not cover | Computed for all seven by a fourth, additive fetch, and tabulated for all nine repositories (`F66`–`F72`) |

The revision-2 note below is kept as history.

**Revision note (revision 2).** The judgment audit of revision 1 (`review/audit-fable.md`,
against revision 1's sha256 `cbd4f1023f110ea13efc78bb512860e5849f8d9207e1dac274e0dc1d564965d6`)
rejected it on nine findings. **The recommendation does not move.** No pagination crate is
adopted, the contract is `cursor`/`limit`, and `base64` 0.23.1 is still the single added
dependency. Each repair is listed below with where it lands.

| Finding | What was wrong | What revision 2 does |
|---|---|---|
| JA-01 | The `Cargo.toml` line dropped `default-features = false`, and the `web` feature change was unargued | One exact dependency line everywhere, the exact feature array, and the argument from R69's clause (4) under coupling 1 |
| JA-02 | R6.3 "conforms" rested on an unstated reading of *non-constructable* | The reading is stated in the R6.3 row on the standard's own text, including its example cursor. No override is needed; OV-10 stays unused |
| JA-03 | R6.9 had no row | An R6.9 row (`N/A with reason`) and its line assertions (`S60`, `S61`) |
| JA-04 | `## Engines` omitted the three `BASELINE-REVIEW: F311` lines the Doxa legs raised | Each is listed with its leg, raw line and disposition |
| JA-05 | Two sentences misstated which Doxa legs keep a page index and `total` | Corrected: all three keep both, each named |
| JA-06 | The prompt's LOW question was unanswered | Answered under `### Landscape` from the three templates Muse named, read at source |
| JA-07 | R70 was called published | R70 is still open; the P03 check through its envelope waits on it |
| JA-08 | Endpoint and assertion counts disagreed | One count and one range each |
| JA-09 | Issue responsiveness mixed pull requests into the population | Re-fetched as the ten most recently opened issues; `F41` and `F42` recomputed |

One change is not an audit finding. Between the two revisions, Homebrew moved the host
toolchain from rustc 1.98.0 to 1.98.1. The probe was rerun on 1.98.1 so that its committed log
reproduces. Every one of its 19 checks gives the same result, and the log differs only in the
two host-version lines. A second correction is also not an audit finding: revision 1 gave the
practice sources' retrieval time as `2026-09-21T23:25:54Z`, but `RETRIEVED-practice.txt`
records `2026-09-22T01:16:23Z`, which **Retrieval dates** now states.

**Retrieval dates.** Everything this decision checked itself carries one of five UTC
timestamps. The popularity snapshot set records `2026-09-21T23:16:25Z`
(`review/evidence/snapshots/RETRIEVED.txt`). The practice sources record
`2026-09-22T01:16:23Z` (`RETRIEVED-practice.txt`). The revision-2 sources record
`2026-09-22T17:48:52Z` (`RETRIEVED-revision2.txt`): the issue population behind `F41` and
`F42`, and the three templates behind the LOW answer. The revision-3 sources record
`2026-09-22T19:16:07Z` (`RETRIEVED-revision3.txt`): the issue populations behind `F66`–`F72`.
The revision-4 sources record `2026-09-23T05:20:39Z` (`RETRIEVED-revision4.txt`): the
repository records, open-issue counts and README behind `F74`–`F79`.
Anything carried from
a raw carries that raw's own date: **2026-09-19** for `raw/muse-…a079.md` (Muse, sha256
`107925801a224c71ad22e4d6ca4425223700e99163c709fd96d3fde558aca079`), **2026-09-18** for
`raw/opus-…332d0.md` (Claude Opus 5, sha256
`95db4ad7bf2bda0242c0bc7c4f7be2de289bde6da989fa3d126635af3ea332d0`) and for
`raw/doxa-…2da540.md` (Doxa, operation `research-20260918-150431-3cb17a06c88b457a`, three
provider legs, sha256 `6f73f6c3bcca672d641c5cd77e178bbad8296d3feaa808e5c18ad5e0d62da540`).
All three hashes are asserted from the repository at `I01`–`I03`.

**Every figure in this decision was re-retrieved by this synthesis, not carried.** The Muse
leg recorded that `api.github.com`, `docs.rs`, `static.crates.io` and `rustsec.org` were all
unreachable from its sandbox, so its GitHub numbers came from HTML pages and its `unsafe` and
CI evidence was recorded as gaps. From this synthesis all of those endpoints answered: 59
endpoints in `r72-fetch.sh`, 4 in `r72-fetch-practice.sh`, 33 in `r72-fetch-revision2.sh`,
32 in `r72-fetch-revision3.sh` and 5 in `r72-fetch-revision4.sh`, with **zero gaps**. `r72-fetch-revision2.sh` also recorded two 404s as `ABSENT`. Both are for
a template repository that no longer exists, and that absence is itself a finding
(`### Landscape`). Where a
raw's figure and this decision's figure differ, this decision's is the one to use and the
difference is recorded under `## Engines`.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q4, widened by
Q7.B)`** for every candidate below (`docs/port/OWNER-REVIEW.md:47`, "**Fitness gate 1 …** is
struck from every item's evaluation"). Licence strings are reported as metadata only and
**nothing is excluded on licence** — which reverses one exclusion a Doxa leg made; see
`## Engines`.

## Decision

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). No Rust source exists in this repository — `rs-launch-blueprint` is still a
research tree — so nothing here is an implemented result. The one piece of Rust this
synthesis compiled is a throwaway probe built under `$TMPDIR` and deleted after the run
(`## Empirical check`); it is not template code and no Rust file was written into the
repository. A decision that does not survive implementation is revised against this recorded
research, not researched again from scratch.

### The recommended mechanism

**No pagination crate is adopted. The template ships a first-party `cursor`/`limit` contract
conforming to the org REST API Design Standard v2.0.0 §6, with `base64` `>= 0.23.1, < 0.24.0`
with its default features **off** — Cargo
`base64 = { version = "0.23.1", optional = true, default-features = false, features = ["std"] }`,
enabled by the `web` feature — as the single added dependency.**

The bundle has three members. Two of them add no crate; the third is the whole of the new
dependency cost.

| Member | What it is | What it supplies |
|---|---|---|
| **`page-window-request`** — template-owned | A `Limit` newtype whose only constructor enforces `1..=100`, a `PageRequest { after, limit }`, and one `impl<S> FromRequestParts<S> for Pagination where PaginationLimits: FromRef<S>` reading the documented default and maximum out of `AppState` | The reserved request names `cursor` and `limit` (R6.5), the documented default (50) and maximum (100) enforced rather than merely published (R11.1), and a rejection decision — `422` for a well-formed out-of-range window, `400` for malformed syntax (R5.3), and `400` for any `stream` parameter on a route that does not stream (R13.3). No crate |
| **`page-envelope`** — template-owned | `ListResponse<T> { items: Vec<T>, next_cursor: Option<String> }`, a plain `serde` generic struct | A top-level object carrying items plus continuation, never a bare array (R6.1); `200` with an empty array for an empty window (R6.2); items that are the caller's own `T`, byte-identical to serializing the domain value directly (py's WEB-03 principle). No crate |
| **`cursor-codec`** — `base64` `0.23.1`, `optional = true` under `web`, `default-features = false`, `features = ["std"]` | `URL_SAFE_NO_PAD` over the boundary row's immutable key | The opaque continuation token R6.3 asks for. It is non-constructable **by contract**, which is how the standard itself defines that property (R6.3 read with R12.5; see the R6.3 row), not by cryptography. It uses the same engine and alphabet `rust-lang/crates.io` uses for its own `?seek=` token (`C07`). **The only dependency this item adds** — and `cargo tree -e normal` shows it exactly once, so it is a direct addition and nothing else in the R69 stack already pulls it (`E01`). Turning the default features off is not housekeeping: it is what makes the added crate an `unsafe`-free build, and it is checked (`C19`–`C22`, `E06`) |

**The wire contract, stated once.**

```
GET /v1/projects?limit=25
GET /v1/projects?cursor=cHJqXzAwMDI&limit=25

200 OK
{"items": [ {...domain object...}, ... ], "next_cursor": "cHJqXzAwMDU"}
```

`limit` defaults to 50 and is capped at 100. `limit=0` and `limit=101` are **rejected with
`422`**, not clamped. `limit=abc` and an undecodable `cursor` are **`400`**. The last page
carries `"next_cursor": null`. A window past the end is `200` with `"items": []`. No `Link`
header and no `X-Total-Count` header is emitted. A `stream` parameter, with any value, is
**`400`**, because the route does not stream. Every one of those sentences is an executed
assertion, not a design intention: `P01`–`P15` in `## Empirical check`.

**The default and the maximum are py's own numbers, read at the pin.**
`fastapi_pagination/default.py` declares `size: int = Query(50, ge=1, le=100, description="Page size")`
(`I29`) — default 50, maximum 100, and `le=100` **rejects** an over-maximum request rather
than clamping it. The template keeps both the numbers and the rejection behaviour and changes
only what the binding standard requires: the parameter's name and the window's mechanics.
`rust-lang/crates.io` independently rejects rather than clamps —
`if per_page > MAX_PER_PAGE { … "cannot request more than {MAX_PER_PAGE} items" }` (`C05`,
`C06`) — with the same maximum of 100 (`C02`).

**Ledger rows this settles.**

- **F310** (`docs/port/COMMONALITY.md:314`, `DIVERGENT`, owner `R72`): "collection pagination
  via page/size query params and items/total envelope". The answer is that **Rust has no
  `fastapi-pagination`**, and that the template should not want one: the contract is fixed by
  a binding org standard the crates do not implement, and the code the crates would have
  replaced is roughly sixty lines the template can own. The envelope survives as a principle;
  `page`/`size` and `total` do not survive as a wire shape.
- **F311** (`:315`, `DIVERGENT`, owner `R72`): "pagination is wired app-wide via one factory
  call". py's `add_pagination(app)` (`I25`) has **no direct counterpart** — axum exposes no
  application-wide extractor-registration hook (`C14`) — but the row's *intent* does have a
  faithful Rust realization, and this decision records it as the answer rather than as a
  gap: **the policy value is declared once in `AppState` and reached through `FromRef`
  (`C13`), and one `FromRequestParts` extractor reads it.** Adding a collection route is one
  argument in the handler signature and no configuration at all; changing the maximum is one
  edit in one place. `P11` proves it on a second collection route, which inherits the whole
  policy — including the `422` — with no extra wiring. What Rust withholds is the *runtime
  patching* FastAPI does, not the uniformity the row cares about.

**No `OVERRIDE (OV-nn)` is declared.** OV-10 was pre-allocated to this item by the controller
(`docs/planning/p02/execution-ledger.md:1107`) against the possibility that the recommendation
would need to depart from a rule of the standard. It does not: every rule of §6 that binds
this item is met as written, the two request names are the reserved ones, the envelope is the
standard's own `items`-plus-continuation shape, and no `Link` header is emitted. **OV-10 is
returned to the controller unused.** The one rule where an override was genuinely in question
is R6.3's "non-constructable". The choice is made in that row: the standard defines the
property contractually (R6.3's own text names R12.5 as its client half), and its own example
cursor is plain base64, so the SHOULD is met as written and R1.7 owes no `Deviations:` row.
The full rule-by-rule disposition is
`### The org REST API Design Standard, rule by rule` below; across twenty-two rows it
contains fourteen `conforms`, seven `N/A with reason`, one `moved` and zero overrides.

**No `CONFLICT:` line is raised.** No registered parameter value needs to change. That
includes R69's `web-extra-surface`, whose clause (4) already provides for this item's one
dependency (coupling 1 below). The four `CONFLICT:` lines that two Doxa legs raised against
R69 are each quoted and disposed under `## Engines`; none is well formed or needs anything
changed, so RUNBOOK §4 is not triggered. This synthesis emits no `BASELINE-REVIEW:` finding of its
own: F310 and F311 are both `DIVERGENT`, and `docs/port/BASELINE-REVIEW.md` adjudicates
`COMMON → REUSE` and `ADOPT` rows only. The three `BASELINE-REVIEW: F311` lines that Doxa
legs raised are each listed and disposed under `## Engines`.

**What this decision does not decide.**

- *How a rejected window is rendered* — R70 (F305/F306). This item decides **which** status a
  rejected window carries and why (`422` semantically invalid, `400` malformed — R5.3, checks
  `S39`–`S44`); the problem document that carries it is R70's, still open: nothing is
  published under `research/topics/70-http-problem-envelope/`, and the research index lists
  R70 as `open` (`I42`, `I43`). The probe returns a bare `StatusCode` for exactly this
  reason.
- *How the contract reaches the OpenAPI document* — R71 (F307/F312/F332/F333). This item owes
  R71 only one property, and it holds: both types are plain `serde` structs that a derive can
  attach to. The production precedent is direct — `rust-lang/crates.io` carries
  `#[derive(Debug, Deserialize, FromRequestParts, utoipa::IntoParams)]` on the *same* struct
  axum extracts (`C03`), so a hand-rolled params struct costs nothing at generation time.
- *Which framework hosts the extractor, and where the web tree lives* — R69. See the
  couplings below.
- *Whether sorting, filtering or sparse fieldsets are offered* — the template offers none of
  the three for now. Sorting (R6.7) and sparse fieldsets (R6.10) are `MAY` (`S36`, `S38`), and
  declining a `MAY` is not a deviation. R6.8 is not a `MAY` rule (`S37`, `S62`): it fixes the
  filter grammar, so it binds only when filtering is offered, and no filter parameters are
  offered. R6.9's `MUST NOT` binds filter parameters, so it is met with none (`S60`). None of
  the four is a deviation or an inapplicable switch, so **the conformance note gains no
  `Deviations:` row and no `N/A declarations:` row from R72**. That matches the standard's
  own filled-in note, which records "N/A declarations: none beyond the switch reasons above"
  (`S65`); the slot is for a rule or switch and "why it cannot apply" (`S63`, `S64`), and an
  unexercised capability is not that. A switch declared off, such as `streaming`, carries its
  reason on the note's `Switches:` line under R1.6 (`S66`, `S67`), not in the
  `N/A declarations:` slot. R72 designs no streaming endpoint and writes no switch
  declaration. The one §13 rule the switch does not scope, R13.3, is met in this item's
  extractor (the R13.3 row below).
- *The type of `Project::id`* — no accepted decision declares it. R01 declares no port method
  signature (`I80`); the collection read's return type, `Result<Vec<T>, PortError>`, is fixed
  by R03's rule 1, owner-accepted and unpublished (`I81`–`I84`). R01 declares no `Project`
  struct at all (`I21`). The cursor is therefore specified as *the immutable unique key of the collection's
  documented total order*; the probe uses a `String` id mirroring py's `id: str` (`I26`).
  P03 binds the concrete type.

**Couplings, stated rather than re-decided.**

1. **R69 is consumed as published, and the published layout is the one used here.**
   `prerequisites.json` pins R69's decision at `d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d`
   (`I13`), which is exactly the published `research/topics/69-web-framework-stack/DECISION.md`
   (`I14`). That published revision places the web tree at **`src/web/`** (`I15`, `I16`) and
   never uses the string `crates/web` (`I18`). Every path in `### Migration implications`
   follows it. R69 revision 10 — owner-accepted and unpublished — moves the tree to
   `crates/web/`; the `raw/opus.md` leg wrote all of its paths in that form. That revision is
   a **design input noted in prose only**, and R69's republication is a re-verify trigger
   below. Nothing in this recommendation needs R69's value changed, so this is not a
   `CONFLICT:` line. The `Cargo.toml` change this item makes, two edits, is argued next.

   **Why `dep:base64` goes into the `web` feature, and why that leaves R69's registered
   value unchanged.** `base64` must be compiled when `web` is on and absent when it is off.
   On a single manifest, Cargo has one way to say that: an optional dependency named in a
   feature. The feature therefore reads `web = ["dep:axum", "dep:tokio", "dep:base64"]`.
   That text differs from the registered value's literal `web = ["dep:axum", "dep:tokio"]`
   (`I36`). Two questions follow. First, does the value fix the array's full text, or R69's
   two dependencies inside it? Second, even if an addition is allowed, does it belong in
   `web` itself, or in a separate feature that requires `web`, under the value's clause on
   heavier opt-ins?

   The value answers both, because it sorts every later item into one of two places
   (`docs/port/PARAMETERS.md:17`):

   | Where the value puts a later item | Items it names there | What the value says about them |
   |---|---|---|
   | Thing (4), inside `web` | R70, R71, R72 to R76, R77, R80 | "(4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off" (`I37`, `I38`, `I63`) |
   | Heavier opt-ins, beside `web` | R78 (`otel`), R79 (`metrics`) | "heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras" (`I64`) |

   Four grounds follow from that partition.
   - **The value puts R72 in thing (4) by name, not among the heavier opt-ins, and a
     separate feature would break thing (4).** Thing (4) requires R72's module to be on
     whenever `web` is on. Suppose the codec sat behind `pagination = ["web", "dep:base64"]`.
     Then under `--features web` alone the pagination module would either fail to compile,
     or it would have to be gated on `pagination` and so be off while `web` is on. Either
     outcome contradicts thing (4). So for a thing-(4) layer that needs a crate, the only
     placement the value allows is the `web` array itself.
   - **Thing (4) presupposes such additions.** A thing-(4) layer that needs a crate can meet
     "absent when it is off" only by adding that crate to `web`. If the array literal were a
     closed list of `dep:` entries, thing (4) could not be met by any such layer. So the
     literal records R69's own two dependencies; it does not close the list.
   - **"Exactly four things" counts what is gated, not which `dep:` entries the array
     holds.** This item's module sits inside thing (4). Nothing is gated that the value
     does not already list.
   - **Pagination is not an opt-in beside `web`.** Under W2-REST, §6 binds every collection
     route. Thing (1) gates "the per-resource route modules" (`I69`), and published R69's route
     module `src/web/routes/projects.rs` (`I16`) serves a collection. With pagination behind
     its own feature, `--features web` would ship that route with no conforming collection
     contract. py draws the line in the same place:
     its `web` extra carries `"fastapi-pagination>=0.12.26",              # WEB-03 pagination conventions`
     (`I65`, `I66`), and `otel` is an extra of its own (`I67`). py's placement does not decide
     the question by itself, because R69 made metrics a separate feature although py keeps
     `prometheus-fastapi-instrumentator` inside `web` (`I68`). The value's own partition is
     what decides it.

   **What R69 said about `axum-extra`, in full.** Revision 2 quoted this passage in part and
   drew the wrong conclusion from it. The whole sentence reads: "Either way the mechanism is
   already fixed by the owned parameter and needs no change here: `axum-extra` would be an
   **additive** dependency of a later layer nested inside the gated `src/web/` tree, under
   the clause *"heavier opt-ins nest on top rather than widening it"*. **This item neither
   selects nor excludes it on fitness** — no gate is answered for it, because it is not a
   candidate here — and the owned value is byte-identical."
   (`research/topics/69-web-framework-stack/DECISION.md:2340-2345`, `I57`–`I62`; the two
   fragments revision 2 quoted are also `I39`, `I40`.) So R69 filed a possible `axum-extra`
   dependency under the heavier-opt-ins clause, not under thing (4). "The owned value is
   byte-identical" describes R69's own decision, which neither selected nor excluded the
   crate. The passage therefore does not show that R69 read an addition to the `web` array as
   leaving the value unchanged, and **this decision no longer uses it as a ground**. It does
   not count against this item either. `axum-extra`'s cookie jars and typed headers are
   capabilities a later layer may or may not need, which is what an opt-in is. The value
   names R72 itself in thing (4).

   **Why the array literal cannot be a closed list.** That the literal records R69's
   dependencies rather than a closed list is a reading of the value, not a quotation from it.
   The grounds above are why it is the only reading under which thing (4) can be met. This
   item is the first thing-(4) layer to add a crate under the published single-manifest
   layout: no other run or published decision adds a `dep:` entry to the `web` array (`I70`). If the owner
   reads the literal as closed, the right instrument is a conflict line against R69's
   `web-extra-surface` asking for this array, never a separate `pagination` feature, because
   a separate feature breaks thing (4). No such line is raised, because the value's own text
   carries the reading.

   Under R69 revision 10 the question disappears: the feature becomes
   `web = ["dep:rs-launch-blueprint-web"]`, and `base64` becomes one plain line in
   `crates/web/Cargo.toml`. R70's run decision already writes its own crate that way (`I41`).
2. **The framework assumption is narrow and is stated, not assumed silently.** The prompt puts
   the framework out of scope and tells this item to fit whichever extractor model wins.
   Published R69 selected axum 0.8.9 (`I17`), and the probe resolves that exact version
   (`E02`). The design needs only two properties of a framework: a typed request-parts
   extractor, and application state a shared value can be read out of. Both are ordinary; an
   actix-web or poem realization would differ in spelling, not in shape.
3. **The port is unchanged; R01's behavior-6 handler observable changes form.** The keyset
   window is applied *above* the port, over the `Vec<Project>` its collection read already
   returns. That return type, `Result<Vec<T>, PortError>`, is fixed by R03's rule 1
   (owner-accepted at `610e3338…`, unpublished; `I81`–`I84`), not by R01, which declares no
   port method signature (`I80`). No port signature is asked to change, so R03's rule 1 is
   untouched and no revision of an accepted decision is requested.

   R01's accepted behavior 6 is a different matter. Its observable reads: "the handler returns
   `Json<Vec<Project>>` and `Json<Option<Project>>` from the library's contract module, no
   mirror struct exists, and a real HTTP GET against a bound listener decodes into the
   library's `Vec<Project>` and equals the CLI's output"
   (`research/topics/01-ports-and-adapters-seam/DECISION.md:53`, `I79`). This item changes the
   collection handler to return `Json<ListResponse<Project>>`, because R6.1 forbids a bare
   array (`S18`–`S20`). **Behavior 6's collection-handler observable is therefore superseded in
   form by R6.1's envelope.** Its principle, no mirror struct and the library's own types on
   the wire, is preserved, and `P08` shows it: the envelope's `items` equals serializing the
   domain values directly. P03 therefore checks that `ListResponse<Project>.items` decodes
   into the library's `Vec<Project>` and equals the CLI's output. The single-resource half,
   `Json<Option<Project>>`, is not touched by this item.

   **This reconciliation needs no `BASELINE-REVIEW:` line and no `CONFLICT:` line.** R01 owns
   one registered parameter, `http-transport-injection-seam` (`docs/port/PARAMETERS.md:11`,
   `I86`). Behavior 6 is an acceptance criterion of R01's decision, not a registered value, so
   no registered value changes and RUNBOOK §4 has nothing to act on. `BASELINE-REVIEW.md`
   adjudicates `COMMON → REUSE` and `ADOPT` rows only, as stated above. The reconciliation is
   recorded here in prose, for P03 to apply.
4. **R05's synchronous port bounds what pagination can honestly claim here.** py's own
   docstring says it plainly at the pin: pages are sliced from one upstream fetch, so a total
   reflects the fetched window, not the upstream universe, and "**True pass-through pagination
   needs cursor support in `ProjectsService`**" (`I24`). That is py's own design note pointing
   at the mechanism this decision adopts. Until the port itself pages, the cursor is a stable
   window over a materialized collection; the contract is then already correct when the port
   gains a real continuation, which is the point of choosing it now.

**Re-verification triggers**, each mechanical enough to be checked without judgment:

1. **R69 republishes** (revision 10 or later). Re-read the placement clause and restate the
   file paths; the mechanism does not move, only the directory does.
2. **The org REST API Design Standard changes §6, §1.10 or R5.3** at a commit later than
   `0850d43e45d919ef5e37f7174c4212b46013c49f` — in particular if it registers a page-index
   parameter name, relaxes R6.5, or reverses R6.4's header prohibition.
3. **A RustSec advisory is filed against `base64` with a patched version above 0.23.1.** The
   one advisory on record, RUSTSEC-2017-0004, is patched at `>= 0.5.2` (`F48`), far below the
   selected version; the package page answers 200 and the `rsa` control renders
   RUSTSEC-2023-0071 in the same run (`F44`, `F45`), so the reading is calibrated.
4. **`base64` publishes 0.24 or 1.0**, or its declared `rust_version` (1.71.0 — `F24`) rises
   above the then-current stable-minus-2 floor.
5. **A pagination crate appears that implements the reserved names.** The concrete watch:
   `paginator-axum` renaming `per_page` to `limit`, dropping `create_link_header` and the
   `X-Total-Count` response header, declaring a `rust-version`, and gaining an external
   adopter that is not a sibling crate; or `api-paginate` reaching 1.x with a current `utoipa`
   and real adopters.
6. **R71 selects a generator that cannot derive parameters from a plain `serde` struct.** That
   is the only OpenAPI outcome that would disturb this design.
7. **R05 makes the port itself paging.** The wire contract is already the right one, but the
   cursor's meaning moves from "key within a materialized window" to "upstream continuation",
   and `### Validation strategy`'s stability check should then run against the real upstream.

Otherwise re-verify at **2026-12-20**, 90 days from this run, because `recent_downloads` is a
rolling 90-day window and every popularity figure here ages out together.

re-verify: 2026-12-20, or earlier on any of — R69 republishing (revision 10 or later) and moving the web tree; the org REST API Design Standard changing section 6, section 1.10 or R5.3 above commit 0850d43e45d919ef5e37f7174c4212b46013c49f; a RustSec advisory against base64 patched above 0.23.1; base64 publishing 0.24 or 1.0, or its declared rust_version rising above the then-current stable-minus-2 floor; a pagination crate implementing the reserved cursor and limit names with an external adopter (concretely paginator-axum renaming per_page, dropping create_link_header and the X-Total-Count header, and declaring a rust-version, or api-paginate reaching 1.x); R71 selecting a generator that cannot derive parameters from a plain serde struct; or R05 making the port itself paging.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

Extracted from py's code rather than from the ledger row: *a collection route returns a
uniform envelope whose items are the same core-model objects every other surface renders, the
window parameters have one name everywhere, and the machinery is declared once rather than
restated per route.* The evidence is three lines at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`:
`web/routers/projects.py:30` `from fastapi_pagination import Page, paginate` (`I22`), the
router docstring naming WEB-03's `page`/`size` params and `items`/`total` body (`I23`), and
`web/app.py:204` `add_pagination(app)` (`I25`). ts has no web service, so there is nothing to
reconcile with.

**The level of agreement is `standard`, and that is the finding that reorders this item.**
It is not merely a capability ("collections must paginate somehow") and not merely an
architectural pattern. On **2026-09-18 the owner ruled (W2-REST)** that the organisation's
REST API Design Standard v2.0.0 governs this template's HTTP surface the way the CLI Design
Standard governs its CLI (`docs/port/OWNER-REVIEW.md:187`, checks `I30`–`I33`). The wire
contract is therefore fixed by an external, versioned document with a 145-rule conformance
checklist, and the only open question this item answers is *how Rust realizes it*.

**What must agree, and what may vary.**

| Must agree (fixed by the standard) | Rule | May vary (this item's choice) |
|---|---|---|
| A top-level object carrying items plus continuation, never a bare array | R6.1 (`S18`–`S20`) | The continuation member's spelling; `next_cursor` follows the standard's own example (`S51`) |
| `200` + empty array for an empty collection or window, never `404` | R6.2 (`S21`, `S22`), conformance probe row (`S53`) | — |
| Opaque, non-constructable cursors | R6.3 (`S23`–`S27`) | What the cursor encodes; here, the boundary row's `id` |
| Pagination state only in the body; no RFC 8288 `Link` headers | R6.4 (`S28`, `S29`) | — |
| The request parameters are `cursor` and `limit`; the default and maximum are documented | R6.5 (`S30`–`S32`), §1.10 register (`S12`, `S13`) | The values: 50 and 100, taken from py |
| A total, stable default order with an immutable-key tiebreak | R6.6 (`S33`–`S35`) | The order itself; ascending `id` here |
| The maximum is enforced, not merely published | R11.1 (`S45`, `S46`) | Whether over-maximum rejects or clamps; this item rejects, with py and crates.io as precedent |

**Why py's shape cannot simply be respelled, and why the exception does not rescue it.**
The Muse leg proposed keeping page-index pagination and spelling the size parameter `limit`,
claiming R6.3's small-collection exception. Three independent grounds refuse that, and the
first two are in the standard's own text rather than in the ruling:

1. **The exception has a precondition this template cannot meet.** R6.3's exception "applies
   only where the contract documents the property claimed — a bounded size or an
   append-only/immutable mutation pattern" (`S25`, `S26`, `S27`). `rs-launch-blueprint` is a
   *template*: `/v1/projects` returns whatever the port returns, for an adopter's workspace
   the template has never seen. Neither boundedness nor an append-only mutation pattern can
   be documented by the template, because neither is a property the template controls.
   Claiming the exception would be asserting a property on an adopter's behalf.
2. **Even inside the exception there is no conforming name for the page parameter.** The
   standard registers `cursor`, `limit`, `sort`, `fields`, `dry_run`, `stream`,
   `stream_position` and the bracket range filters — and nothing else. A census of the whole
   blob finds **zero** occurrences of `` `page` ``, `` `offset` `` or `` `size` `` as
   parameter names (`S14`, `S15`, `S16`). So a page-index contract is not a differently-named
   conforming contract; it is a contract the standard has no vocabulary for, which R1.7 would
   then require to be carried as a written deviation ("A deviation from a **MUST** makes the
   API nonconformant unless it is recorded as an approved exception in the conformance
   note" — `S03`–`S07`). That deviation is exactly the `OVERRIDE (OV-10)` this decision would
   have had to open, and it would have been opened to preserve a source-repo spelling rather
   than to protect anything the template needs.
3. **The owner already ruled on this precise question.** The W2-REST entry states the
   consequence in its own words: under the standard "py's `page`/`size` request and
   `items`/`total` body are nonconformant and the first-party cursor contract stands", and it
   records the declined option as "treating the standard as a reference input only, which
   would have made R72's cursor contract an override needing its own argument against py's
   precedent" (`docs/port/OWNER-REVIEW.md:187`, `I30`–`I33`). The ruling was raised *by this
   item's own Opus report*, so the cursor contract is not a synthesis preference; it is the
   thing the owner was asked about and approved.

**What is lost by leaving `total` out, and why that is the right trade.** py's envelope
carries `total` and `pages`; this one does not. Three reasons, in order of weight. First, the
standard's own rendering of a conforming collection carries `items` plus `next_cursor` and no
count (`S50`, `S51`), and its Appendix D row specifies "`items` + continuation member"
(`S49`). Second, a `total` is exactly the field that becomes a lie under the R05 coupling: py
had to write a docstring explaining that its `total` "reflects the fetched window, not the
upstream universe" (`I24`), and shipping a number that needs a paragraph of explanation is
worse than not shipping it. Third, `total` is *unreserved*, so R6.1's "metadata can be added
without a breaking change" (`S20`) means adding it later is additive and safe — which is the
asymmetry that decides it: omitting now and adding later is free, shipping now and removing
later is a break. An adopter whose collection is materialized and who wants a count adds one
member to `ListResponse`; nothing in this decision forbids it.

**Architectural alternatives, compared before any library was weighed.**

| # | Alternative | Disposition |
|---|---|---|
| A | Adopt `paginator-axum` + `paginator-utils` + `paginator-rs` — the only axum-integrated extractor-plus-envelope family in the ecosystem | **Refused on the contract, before maturity is even reached.** Its wire name is `per_page` (`F54`, `F55`), its envelope member is `data` not `items` (`F60`), it exports `create_link_header` (`F58`), and its `IntoResponse` sets an `X-Total-Count` **header** (`F59`) — pagination state in a header, which R6.4's first sentence puts only in the body (`S28`). Adopting it means either accepting a nonconformant contract or wrapping every one of its types, which is more code than owning the sixty lines. Maturity confirms rather than drives the refusal: 6 stars (`F25`), one external adopter that is not a reference (`F63`), and no declared `rust-version` (`F13`). Responsiveness is the one maturity signal in its favour: a 1.3-day median time to a maintainer's first reply across all eight issues ever opened, none unanswered (`F42`). It does not touch the contract grounds |
| B | Adopt `sqlx-paginated` | **Refused on layer.** It couples `sqlx` and `tokio` as normal dependencies (`F53`); the template's P02 web service has no database at all. Choosing it would decide the persistence layer in order to obtain pagination |
| C | Adopt `paginate` for the window arithmetic and own the HTTP types | **Refused on value.** It has no HTTP surface and no serde support; it would save a `partition_point` call and a subtraction while adding a dependency last released 2022-04-11 (`F16`) with no declared MSRV. The arithmetic stays inline and is tested (`P06`, `P12`) |
| D | Borrow an `api_bones::pagination` envelope, as one Doxa leg proposed with `PaginatedResponse<T>` | **Refused, on the actual differences.** The crate's file defines three envelopes. `PaginatedResponse<T>`, the one the leg named, names `items` (`C15`, `C16`) but is an *offset* envelope: `offset: u64` and `total_count: u64` are its continuation state (`C17`, `C18`). `CursorPaginatedResponse<T>` names its items `data` (`C55`, `C56`). `KeysetPaginatedResponse<T>` is the closest third-party match to the adopted contract: `items` plus `next_cursor`, with `has_next`, `has_prev` and `prev_cursor` beside them (`C49`–`C54`). Even that one is refused on three grounds. Its request types spell the position `after` and `before`, not R6.5's `cursor` (`C57`–`C63`), and `KeysetPaginationParams<K>` takes the raw key type itself (`after: Option<K>`, `C61`), so a client supplies a key rather than an opaque token. It carries three members this contract does not use. And it would bring a 4-star API-scaffolding crate (`F32`) into the tree to save one struct declaration |
| E | Make pagination a tower middleware layer, so it is "registered once" the way py registers it | **Refused on type safety.** A layer sees bytes and headers, not the handler's typed arguments; it could parse the query but could not hand a validated `PageRequest` to the handler, so every handler would re-read and re-validate it. The uniformity gain is illusory and the loss is the compiler's involvement |
| F | Template-owned types on the R69 stack, with `base64` for the token | **Recommended.** Roughly sixty lines in one module, exact control of names the standard fixes, one added dependency, derive-ready for R71, and the same shape the Rust project's own registry service runs in production (`C01`–`C09`) |

**How the recommended design preserves each principle.** *Uniform envelope*: one generic
`ListResponse<T>` used by every collection route (`P10`, `P11`). *Items stay domain objects*:
proven by comparing the serialized envelope's `items` against serializing the domain values
directly — they are equal (`P08`), so the wrapper is the only web-specific thing, exactly as
py's WEB-03 requires. *One name everywhere*: the names are the standard's reserved ones and
there is a single struct to change. *Declared once*: `PaginationLimits` lives in `AppState`
and is reached through `FromRef`; `P11` shows a second route inheriting the whole policy with
no configuration.

**Where a different ecosystem needs a different design.** py's `add_pagination(app)` works
because FastAPI patches route response models at runtime; the machinery is discovered by the
framework after the routes exist. Rust resolves extractors at compile time through
`FromRequestParts`, so the equivalent of "register once" is "declare the value once and let
the type system carry it". That is not a weaker mechanism: py's factory call can be forgotten
and the failure appears at request time, whereas a missing `FromRef` impl is a compile error.
The crate that most resembles `fastapi-pagination` confirms the constraint rather than
escaping it — `paginator-axum`'s `PaginationQuery` is itself a per-handler
`FromRequestParts` extractor (`F57`) and the crate exports no application-level registration
function at all (`F62`).

### The org REST API Design Standard, rule by rule

Every rule quoted below is cut from blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` at commit
`0850d43e45d919ef5e37f7174c4212b46013c49f` and asserted at its own line number by
`review/evidence/r72-standard.sh` (82 checks, 0 failures). Dispositions use the vocabulary the
W2-REST ruling fixes: **conforms**, **N/A with reason**, **moved**, **override**. **N/A with
reason** here is this decision's disposition for a rule the item does not exercise. It is not
a row in the conformance note's `N/A declarations:` slot, which R72 leaves empty (see *What
this decision does not decide*).

| Rule | Line | Disposition | Ground |
|---|---|---|---|
| **R1.7** no silent deviation | 271–275 (`S03`–`S07`) | **conforms** | Nothing here deviates, so the conformance note this template ships carries no `Deviations:` row from R72 |
| **R1.8** reservation discipline | 312–315 (`S08`–`S11`) | **conforms** | The two request names used are the reserved ones, used for their registered meanings. No reserved name is reused for anything else |
| **§1.10** register: `cursor`, `limit` | 336–337 (`S12`, `S13`) | **conforms** | `cursor` = opaque pagination position; `limit` = requested page size, with a documented default and maximum |
| **R5.3** 422 vs 400 | 939–942 (`S39`–`S42`); quick map 2847, 2853 (`S43`, `S44`) | **conforms** | `limit=0` and `limit=101` are well formed and semantically invalid → `422` (`P02`, `P03`); `limit=abc` and an undecodable cursor are malformed syntax → `400` (`P04`, `P05`) |
| **R6.1** envelope | 1133–1135 (`S18`–`S20`) | **conforms** | A top-level object with exactly `items` and `next_cursor`, asserted on the parsed body (`P10`) |
| **R6.2** empty collection | 1154–1155 (`S21`, `S22`); probe row 3414 (`S53`) | **conforms** | A window past the end returns `200` and `{"items":[],"next_cursor":null}` (`P07`) |
| **R6.3** opaque cursors | 1170–1175 (`S23`–`S27`, `S56`); checklist 2716 (`S55`) | **conforms**, under the standard's own reading of *non-constructable* | Cursor pagination is adopted, so the SHOULD is met directly and the exception is not claimed. *Non-constructable* is read as the standard defines it: a contractual property with a server half and a client half, not a cryptographic one. The evidence is the standard's own text. R6.3 names its counterpart: "The corresponding client obligation not to construct or modify cursors is R12.5" (:1175, `S56`). The register ties the property to criterion `AC-013` (:336, `S57`), which the traceability table maps to both R6.3 and R12.5 (:2497, `S58`). The standard's own conforming example cursor, `b3BhcXVlLW5vdC1jb25zdHJ1Y3RhYmxl` (:3050, `S51`), is plain base64 of the text `opaque-not-constructable` (`S59`): decodable and unsigned. The server's half is to document the token as opaque and to give it no documented structure. This token is base64url over the boundary key (`P06`), the construction `rust-lang/crates.io` ships (`C07`). A client *can* decode it, exactly as it can decode the standard's example; R12.5 forbids it to. So R1.7 owes no `Deviations:` row, and no override is needed |
| **R6.4** no `Link` headers | 1180–1185 (`S28`, `S29`) | **conforms** | No `link` and no `x-total-count` header is emitted (`P09`) |
| **R6.5** `cursor` + `limit`, documented default and maximum | 1194–1196 (`S30`–`S32`); checklist 2718 (`S54`) | **conforms** | Default 50, maximum 100, both declared in one place and read by the extractor (`P01`) |
| **R6.6** stable total order, `id` tiebreak | 1207–1209 (`S33`–`S35`) | **conforms** | Ascending `id`; `P06` asserts the two windows are ordered, disjoint and contiguous |
| **R6.7** sorting | 1215 (`S36`) | **N/A with reason** | `MAY`. The template offers no sorting, so the `sort` grammar never arises. Declining a `MAY` is not a deviation |
| **R6.8** filter grammar | 1226 (`S37`, `S62`) | **N/A with reason** | Not a `MAY` rule: it fixes the filter grammar, so it binds only when filtering is offered, and the template's single collection offers no filter parameters. The probe's second route filters by a path segment, not a query filter |
| **R6.9** no storage or query-engine syntax in filters | 1235 (`S60`); criterion `AC-015` at 2499 (`S61`) | **N/A with reason** | A `MUST NOT` that binds only filter parameters, and no filter parameters are offered (see R6.8). If a later item adds filters, this rule binds them |
| **R6.10** sparse fieldsets | 1244 (`S38`) | **N/A with reason** | `MAY`, not offered |
| **R11.1** publish *and enforce* a maximum | 1678–1679 (`S45`, `S46`) | **conforms** | Enforcement is in the type: `Limit`'s only constructor refuses anything outside `1..=100` (`P13`), so no handler can receive an over-maximum window however the transport is written |
| **R12.5** clients treat cursors as opaque | 1807 (`S47`) | **N/A with reason** — *with a stated limit* | A client obligation, not a server one. The server's part is to emit a token that does not invite construction; base64url over a key is **opaque by contract, not cryptographically non-constructable**. A determined client can decode it, as it can decode the standard's own example cursor (`S59`); that contractual sense is the one R6.3 uses (see its row). If that ever matters, the codec is the one place to change and R6.3 is still satisfied |
| **Appendix C** collections summary | 2861 (`S48`) | **conforms** | "`cursor` + `limit` in; `items` + continuation out" is this contract verbatim |
| **Appendix D** OpenAPI mapping | 2895 (`S49`) | **moved — to R71, as a stated requirement** | The row asks for "a shared collection envelope schema … shared `cursor`/`limit` query parameters with documented default and maximum". This item supplies the two derive-ready types and the two values; **R71 owes the shared `components.parameters` entry and the shared envelope schema**. Recorded here as an obligation on R71, not as something this item did |
| **Appendix E.4** the worked example | 3039, 3050, 3058 (`S50`–`S52`) | **conforms** | The recommended body is the example's shape, with `next_cursor` as the continuation member |
| **R13.3** the `stream` rejection guard | 1935–1939 (`S74`–`S77`); switch scope 1896–1899 (`S71`–`S73`); §1.8 guard rule 258–263 (`S68`–`S70`); checklist 2776 (`S78`); probe row 3422 (`S79`) | **conforms** | R13.3 is not scoped by the `streaming` switch; it binds every endpoint that does not implement streaming (:1898–1899). The collection route does not stream, so it owes the guard. The `Pagination` extractor refuses `stream`, as a query parameter with any value, with `400`, and never answers with a silent non-streamed `200`. `P15` sends `stream=true` (the standard's own probe row), `stream=false` and an empty `stream=` to `/v1/projects`, and `stream=true` to the second collection route, and asserts `400` each time. R13.3 fixes the status itself, so R5.3's `422`/`400` distinction is not reached. The route reads no request body, so the rule's body-member form does not arise. In P02 scope the extractor is the only reader of the collection route's query string, so it carries the guard. A route-wide guard for the endpoints this item does not design, such as a single-resource `GET`, is not decided here; if one lands later, the extractor's check is redundant but harmless |
| **R13.x** streaming, other than R13.3 | 1896–1898 (`S71`, `S72`) | **N/A with reason** | R13.1, R13.2, R13.4–R13.11 and R13.12–R13.17 are scoped by the `streaming` applicability switch (:1896–1898). This item designs no streaming endpoint: its collection routes return `axum::Json`. The streamed forms these rules govern therefore never arise here |
| **R2.x / R7.x / R8.x / R9.x** paths, caching, auth, versioning; **R11.7** the `request-id` header | R7.1 1259 (`S80`); R11.7 1752–1753 (`S81`, `S82`) | **N/A with reason** — owned elsewhere | Paths, auth and versioning are owned by other items — R69 (routing and the `/v1` base), R76, R77, R80. This item adds no path, no header and no auth surface. Two of these rules still bind the collection route's response: R7.1, "Every response MUST carry an explicit `Cache-Control` header", and R11.7, "Every response, including errors, MUST carry the `request-id` correlation header". Both are whole-API response-header obligations, not pagination ones, so neither is this item's. R11.7 is R75's: its prompt scopes request-id propagation and the `x-request-id` response header (`I76`, `I77`). No item prompt names `Cache-Control` (`I78`), so R7.1 has no assigned owner yet; that gap is recorded for the controller, not decided here. **R72's tests must not constrain either header.** The P03 form of `P09` therefore asserts only that `link` and `x-total-count` are absent (see `### Validation strategy`) |

**Zero rules needed an override.** The one place an override was genuinely in question,
R6.3's *non-constructable*, is settled in its row on the standard's own definition, not by
assumption. OV-10 is unused and returned.

### The six fitness gates, per candidate

Answered before popularity is weighed. Gate 1 is struck programme-wide by the owner ruling
above and is reported as metadata. A candidate excluded by a gate is listed under *Excluded by
gate*; every other rejection is a fitness judgment and is named as one.

| Candidate | 1 licence (struck) | 2 MSRV | 3 advisory / `unsafe` | 4 OS matrix | 5 default features / async coupling | 6 size and compile cost |
|---|---|---|---|---|---|---|
| **`base64` 0.23.1** *(recommended)* | `MIT OR Apache-2.0` (`F24.e`) | declares `rust-version = 1.71.0` (`F24`), far below the 1.96 floor, and its CI **actually builds that floor** — the MSRV job pins the `rust:1.71.0` image (`C25`). The whole probe builds and tests at 1.96.0 (`E04`) | RUSTSEC-2017-0004 exists but is patched at `>= 0.5.2` (`F47`, `F48`) — **not open against 0.23.1**. `unsafe`: **read, not assumed.** All of it sits behind one feature — `#![cfg_attr(not(feature = "simd-unsafe"), forbid(unsafe_code))]` and `#![cfg_attr(feature = "simd-unsafe", deny(unsafe_code))]` (`C19`, `C20`) — and `simd-unsafe` is **on by default** (`C21`). The recommendation therefore takes the crate with `default-features = false, features = ["std"]`, which is the `forbid(unsafe_code)` build, and the probe is built that way (`E06`). 48 non-comment occurrences of the word exist in the crate, confined to the SIMD engine the feature gates (`C22`) | **read, not inferred**: the project runs CircleCI on Linux Docker images and has **no** macOS or Xcode executor (`C24`, `C26`). Linux is covered by the maintainer's CI; **macOS is covered by this run's own execution** on `aarch64-apple-darwin` (`E03`, `E04`). Windows is covered by neither, and is not required | **no normal dependencies at all** (`F50`); no async runtime anywhere in its tree | negligible: one small crate, appearing exactly once in `cargo tree -e normal` (`E01`) |
| `paginator-axum` 0.4.0 | MIT (`F13`) | **no `rust-version` declared** (`F13`) — unverifiable from metadata; recorded as a gap, not a pass | rustsec 404 (`F43`), calibrated (`F44`, `F45`); **zero** occurrences of `unsafe` in its published source (`C23`) | not verified — gap | `async-trait`, `axum`, `form_urlencoded`, `http`, `paginator-rs`, `paginator-utils`, `serde`, `serde_json` (`F49`); `tokio` is dev-only (`F52`), so no runtime coupling | small, and mostly overlapping the R69 stack; `async-trait` and `form_urlencoded` are the net additions |
| `paginator-utils` / `paginator-rs` 0.4.0 | MIT (`F14`, `F15`) | none declared — gap | rustsec 404 (`F43`); **zero** occurrences of `unsafe` in `paginator-utils`' published source (`C27`) | not verified — gap | serde-family only | negligible |
| `paginate` 1.1.11 | Apache-2.0 (`F16`) | none declared — gap; edition 2018 | rustsec 404 (`F43`) | not verified — gap | **no dependencies** | negligible |
| `sqlx-paginated` 0.6.2 | MIT (`F17`) | none declared — gap | rustsec 404 (`F43`) | not verified — gap | **couples `sqlx` and `tokio` as normal dependencies** (`F53`) | heaviest of the field: a database framework enters the tree |
| `api-paginate` 0.1.1 | `MIT OR Apache-2.0` (`F18.e`) | declares 1.85 (`F18`) | rustsec 404 (`F43`) | not verified — gap | zero required dependencies; optional serde and utoipa | negligible |
| `page-hunter` 0.7.0 | **`non-standard`** (`F19`) | none declared — gap | rustsec 404 (`F43`) | not verified — gap | not evaluated further | — |
| `api-bones` 6.12.0 | MIT (`F20`) | declares 1.85 (`F20`) | rustsec 404 (`F43`); five occurrences of `unsafe`, four of them `std::env::set_var` blocks in its own `#[test]` code (`C28`) | not verified — gap | not evaluated further | a whole API-scaffolding crate for one struct |
| `axum-api-kit` 2.2.0 | MIT (`F21`) | declares 1.81 (`F21`) | rustsec 404 (`F43`) | not verified — gap | not evaluated further | — |
| `page-turner` 1.0.0 | `MIT OR Apache-2.0` (`F22.e`) | declares 1.75 (`F22`) | rustsec 404 (`F43`) | not verified — gap | client-side paging abstraction | — |

**Excluded by gate: none.** Gate 1 is struck, so `page-hunter`'s `non-standard` licence
excludes nothing — which reverses a Doxa exclusion; see `## Engines`. No candidate has an open
advisory. Gates 2 and 4 are **gaps** rather than failures where evidence is missing. Six of
the eleven candidate crates, which is five of the ten gate-table rows, declare no
`rust-version` at all (`F73`), and gate 4 is unverified for every declined candidate. A gap
withholds a pass without earning a failure. Every rejection recorded in this decision is therefore a fitness judgment against
this template's binding contract, argued on evidence, not a gate exclusion.

**Maintenance state, by the rubric.** `paginator-*` — **active** (released 2026-09-07,
`F13`–`F15`; repo pushed the same day, `F25`), brand-new and single-maintainer, though
quick to answer issues (a 1.3-day median across all eight issues ever opened, none
unanswered — `F42`). `paginate` — **stable-quiet**: no release since
2022-04-11 (`F16`) and no push since 2024-01-23 (`F26`), which is a trigger to investigate,
not a verdict; it has no advisory, no maintainer notice and no broken build on record, so
`dormant` is **not** the rubric's answer. `sqlx-paginated`, `api-paginate`, `api-bones`,
`axum-api-kit` — **active**, all pushed within the last six weeks (`F29`, `F30`, `F32`,
`F74.c`). `axum-api-kit`'s repository was pushed 2026-08-18 (`F74.c`), after its 2.2.0
release of 2026-08-12 (`F21.b`); it has 0 stars, is not archived (`F74`, `F74.b`) and has 0
open issues (`F76`).
`page-turner` — **stable-quiet**. No release since 1.0.0 on 2024-01-15 (`F22.b`) and no push
since the same day (`F75.c`): the rubric's trigger to investigate, as for `paginate`, whose
last push is 2024-01-23 (`F26`). The investigation found no `dormant` signal. There is no
advisory (`F43`). The README carries no maintainer notice (`F79`, README blob `2c0cf245`).
The owner was still commenting on the repository's issues on 2026-07-26 (`F78`). No build
on current stable was attempted, so a broken build is neither on record nor ruled out. The
repository has 63 stars, is not archived (`F75`, `F75.b`) and has 3 open issues (`F77`). No
`at-risk` signal is concrete. Its one issue opened by an outsider, in 2024, received no
maintainer reply (`F72`), which is a single data point, not a pattern.
`page-hunter` — **stable-quiet** (last release and last push both 2026-03-07, `F19`, `F31`).
`base64` — **active**: pushed 2026-08-18 (`F27`), released 2026-08-04 (`F24`), 737 stars,
11 open issues (`F35`), a 0.4-day median first response across its ten most recently opened
issues, three of them unanswered (`F41`), and more than a thousand reverse dependencies
(`F65`).

**Issue responsiveness, for every candidate repository.** The prompt's figure is the ten
most recently opened issues, the median days to a maintainer's first response, and the
unanswered count. The population excludes pull requests in the search query itself. A
maintainer is a commenter whose GitHub association is `OWNER`, `MEMBER` or `COLLABORATOR`
and who did not open the issue. Revision 3 computed the seven rows revision 2 lacked, from
the retrieval of 2026-09-22T19:16:07Z (`F66`–`F72`).

| Crate | Repository (`crate.repository`) | Issues (up to ten newest) | Answered | Unanswered | Median days to first maintainer reply | Of those issues, opened by a maintainer |
|---|---|---|---|---|---|---|
| `base64` | `marshallpierce/rust-base64` | 10 | 7 | 3 | 0.4 | 0 (`F41`, `F41.b`) |
| `paginator-axum`, `-utils`, `-rs` | `maulanasdqn/paginator-rs` | 8 | 8 | 0 | 1.3 | 0 (`F42`, `F42.b`) |
| `paginate` | `daniel-samson/paginate` | 4 | 0 | 4 | none | 4 (`F66`) |
| `sqlx-paginated` | `alexandrughinea/sqlx-paginated` | 0 | — | — | **inapplicable** — no issue has ever been opened | — (`F67`) |
| `api-paginate` | `WyattAu/paginate` | 0 | — | — | **inapplicable** — no issue has ever been opened | — (`F68`) |
| `page-hunter` | `jmtamayo/page-hunter` | 8 | 2 | 6 | 266.8 | 6 (`F69`) |
| `api-bones` | `brefwiz/api-bones` | 8 | 0 | 8 | none | 0 (`F70`) |
| `axum-api-kit` | `rodmen07/axum-api-kit` | 0 | — | — | **inapplicable** — no issue has ever been opened | — (`F71`) |
| `page-turner` | `a1akris/page-turner` | 5 | 0 | 5 | none | 4 (`F72`) |

The unanswered counts overstate neglect for three of these repositories. An issue a
maintainer opened can never receive a reply from a maintainer who is not its author, so it
always counts as unanswered. That covers all four of `paginate`'s issues, six of
`page-hunter`'s eight and four of `page-turner`'s five. `page-hunter`'s median rests on the
two issues outsiders opened. `api-bones`' eight issues were all opened by one account,
`gsalingu`, whose reported association is `CONTRIBUTOR`, and no maintainer comment appears on
any of them (`F70.c`). Whether that account is an unlisted member of the `brefwiz`
organisation was not checked. **No outcome depends on these figures.** Every declined
candidate was refused on the contract, on layer or on value before maturity was weighed.

### Landscape

**The category.** The HTTP collection contract of the template's optional web surface: the
request parameters that walk a collection, the body a collection route returns, where the
continuation state lives, and whether a crate supplies any of it. It is a contract decision
first and a library decision second — which is why the binding standard reorders the whole
item.

**The three-bin map. Every shortlisted candidate comes from it.**

| Bin | What is in it |
|---|---|
| **Built-in / first-party toolchain** | `axum` 0.8.9's `extract::Query` and `extract::FromRequestParts`, `axum_core`'s `FromRef` (`C13`), `serde` derive, `axum::Json`. axum's own documentation teaches pagination as a *caller-owned* struct — `struct Pagination { … }` extracted as `Query<Pagination>` (`C11`, `C12`). There is **no first-party pagination crate and no global pagination hook** (`C14`) |
| **Established industry standard** | **Empty.** There is no widely adopted standalone Rust pagination extractor. The nearest analogues are first-party helpers *inside* larger products: `rust-lang/crates.io`'s own `src/controllers/helpers/pagination.rs`, `oxidecomputer/dropshot`'s `ResultsPage<T>` (`C10`), `sea-orm`'s `Paginator`. None is reusable outside its host. **This emptiness is the answer to HIGH-1**, and it is a positive finding: the three engines searched independently, by crates.io full-text search and by name probes, and converged on the same absence |
| **Up-and-comers** | `paginator-rs` / `-utils` / `-axum` 0.4.0 (2026-09-07); `sqlx-paginated` 0.6.2; `api-paginate` 0.1.1 (2026-09-12, nine days old at synthesis, 31 all-time downloads — `F06`); `api-bones` 6.12.0; `axum-api-kit` 2.2.0; `page-hunter` 0.7.0; `page-turner` 1.0.0 (client-side). Every one is either younger than two years in its current shape or bound to a database driver |

**Authoritative sources, and why each counts.**

| Source | Why it is authoritative here |
|---|---|
| Org **REST API Design Standard v2.0.0**, blob `71bd813c` at commit `0850d43e` | The organisation's own released standard, and — since the W2-REST ruling — *binding* on this surface, not advisory. It is the same artefact class R67 and R69 already bind to on the CLI side |
| **`rust-lang/crates.io`**, `src/controllers/helpers/pagination.rs` at commit `30c4ed7fd9b79eba10e42d5c173e9bdd8aab1b4c` | The Rust project's own registry service: a production axum API maintained by the Rust infrastructure team, and the service every crates.io figure in this decision was fetched from. Running code, not a write-up |
| **`oxidecomputer/dropshot`** 0.17.1 | Oxide Computer's production API framework: 1 202 stars, not archived, pushed 2026-09-21 (`F28`), 58 open issues (`F36`), 862 512 all-time downloads (`F11`). Its `ResultsPage` carries `items` plus `next_page` (`C10`) — an independent arrival at items-plus-continuation |
| **axum 0.8.9's own source**, read from the local registry cache | R69's selected framework. The extractor model is read from the code and its documentation tests, not from a summary |
| **py-launch-blueprint** at pin `b08bccfb…`, and `fastapi-pagination` 0.15.15 as resolved in its `uv.lock` (`I27`) | The source precedent this item is measured against, read at the programme's pin |
| **RustSec advisory database**, with `rsa` as an in-run control | Gate 3's authority. The control makes a 404 evidence of absence rather than evidence of a broken fetch (`F44`, `F45`) |

**Practice evidence: what well-regarded projects actually do.** Both production services
surveyed **hand-roll** the contract and use no pagination crate (`C09`). `rust-lang/crates.io`
declares its own `PaginationQueryParams` (`C04`) with `DEFAULT_PER_PAGE = 10` (`C01`) and
`MAX_PER_PAGE = 100` (`C02`), rejects an over-maximum request (`C05`, `C06`), and carries a
`seek` token encoded with `URL_SAFE_NO_PAD` (`C07`, `C08`) — the same construction recommended
here. Crucially for R71, it puts `FromRequestParts` and `utoipa::IntoParams` on **one** struct
(`C03`), which is the direct evidence that a hand-rolled params struct costs nothing at
OpenAPI-generation time. `dropshot` reaches the same envelope shape from a different starting
point. Against that, the strongest crate candidate has one external adopter that is itself a
minor crate (`F63`), and the most-downloaded pagination crate in the field, `paginate`, has
exactly one reverse dependency (`F64`).

**Published Rust API templates: the prompt's LOW question.** The question asks: *do any
published Rust API templates document a page/size-plus-items/total pagination convention as
a named pattern, and where?* **No template this synthesis could read documents that
convention.** The Muse leg answered yes and named three repositories
(`raw/muse-…a079.md:93-101`, `:196-200`). Each was read at source on 2026-09-22, pinned to a
commit (`r72-fetch-revision2.sh`, checks `C29`–`C48`).

| Template Muse named | What is actually there |
|---|---|
| `99minutos/template-agents-rust` | **It does not exist publicly.** The authenticated GitHub API and the web page both answer 404, and the Wayback Machine holds no snapshot of the repository or of its `AGENTS.md` (`C29`–`C31`). So Muse's `Pagination { page, limit }` and `GenericApiResponse::paginated(items, total, page, limit)` cannot be verified. The only public repository carrying the name is `joshua-mo-143/99minutos-template-agents-rust` (0 stars, not a fork, commit `9142f998`); a name search, `gh api "search/repositories?q=99minutos-template-agents-rust+in:name"`, run once on 2026-09-22 and not scripted, returns `total_count` 1. It has no `AGENTS.md` and no pagination code or text at all (`C32`–`C34`) |
| `hendrixmar/rust-axum-seaorm-boilerplate` | A 1-star fork of `nakamuraos/rust-axum-seaorm-boilerplate` (31 stars). It carries the upstream's `src/common/pagination.rs` byte for byte (commits `9bb388c7` and `2ad8073c`; `C35`–`C37`). That file documents **two** modes. Page mode is `?page=1&per_page=20`, returning `data` plus `meta { total, page, per_page, total_pages }`. Cursor mode is `?cursor=<id>&per_page=20`, returning `data` plus `meta { per_page, next_cursor }`. An over-maximum `per_page` is clamped to 100 (`C38`–`C43`). This is the one real page-window-plus-total template in the set. But its parameter is `per_page`, not `size`; its member is `data`, not `items`; and it ships a cursor mode beside the page mode |
| `coreapostrophe/axum-template` | **It has no pagination.** Its collection route returns the whole list as `ApiDataResponse<Vec<Todo>>`, a `{status, data}` envelope (commit `f1bd22bf`). No file path or handler line names a page, limit or cursor (`C44`–`C48`) |

So the answer to LOW is **no** for the named pattern. One of the three templates documents a
page window with a total, under names that differ from py's and alongside a cursor mode. None
of the three uses a pagination crate. That agrees with the practice finding above: the
contract is hand-rolled everywhere. It carries no weight against a binding standard. Its
bearing on Disagreement 1 is recorded under `## Engines`.

**Fit for this template.** CLI + library + web service, where the web service is an optional
off-by-default feature over an in-memory port with no database and, in P02 scope, one
collection route. That single fact disqualifies the DB-coupled half of the field on fit before
any gate applies. What remains is a choice between sixty lines the template owns and a 6-star
crate whose wire contract the template would have to override the standard to accept.

### Members

#### page-window-request

##### Recommendation

`axum::extract::FromRequestParts` over a template-owned `Pagination` extractor, reading a
`PaginationLimits { default: 50, max: 100 }` value out of `AppState` through `FromRef`.
Reserved wire names only: `cursor` and `limit`. **No crate is added.**

##### Dominant choice, shortlist, and what is refused

Dominant by first-party standing (axum's own docs teach the caller-owned struct — `C11`,
`C12`) and by production precedent (`C03`, `C04`). Crate figures are **inapplicable**: this
member adds no crate, and axum's own figures belong to R69, which owns the framework decision.
The one genuine alternative, `paginator-axum::PaginationQuery`, is refused on the contract
(`per_page`, `F54`) and offers no compensating advantage, since it is itself a per-route
extractor (`F57`) with no registration hook (`F62`). `api-paginate::PaginationParams` has the
right shape and is nine days old with 31 downloads (`F06`) — a re-verify candidate, not a
selection.

##### Ranked runner-up

`paginator-axum::PaginationQuery` 0.4.0 — the only axum-integrated extractor in the ecosystem.
It becomes selectable if a future release renames `per_page` to `limit`, drops the Link-header
helper and the `X-Total-Count` header, declares a `rust-version`, and gains an external
adopter.

##### Migration implications

`src/web/pagination.rs` (new, inside published R69's gated `src/web/` tree): `Limit`,
`PageRequest`, `PaginationLimits`, `Pagination`. `src/web/mod.rs`: one field on `AppState` and
one `FromRef` impl. `src/web/routes/projects.rs`: one `Pagination` argument on the collection
handler. No `Cargo.toml` change: axum is already enabled by the `web` feature, and `serde` is an ungated dependency under R69's value.

##### Validation strategy · Confidence & re-verify trigger · Sources

Executed: `P01`–`P05`, `P11`, `P13`, `P15`. Confidence **high** — the mechanism is exercised end to
end on the exact framework version R69 published, at both the host toolchain and the MSRV
floor. Re-verify on triggers 1, 2, 5 and 6. Sources: the standard at the pin (`S08`–`S13`,
`S30`–`S32`, `S39`–`S46`, `S68`–`S79`); axum 0.8.9 source (`C11`–`C14`); `rust-lang/crates.io` (`C01`–`C09`);
crates.io API for every crate figure (`F01`–`F65`).

#### page-envelope

##### Recommendation

A template-owned `ListResponse<T> { items: Vec<T>, next_cursor: Option<String> }`, a plain
`serde` generic struct returned through `axum::Json`. **No crate is added.**

##### Dominant choice, shortlist, and what is refused

There is no dominant crate; the dominant *practice* is a hand-rolled generic envelope, and
both production services surveyed do exactly that (`C09`, `C10`). `paginator-utils::PaginatorResponse<T>`
is refused because its member is `data`, not `items` (`F60`, `F61`), and because its response
path sets `X-Total-Count` (`F59`). `api-bones` defines three envelopes in one file.
`PaginatedResponse<T>` names `items` (`C16`) but carries an offset contract (`C17`, `C18`).
`CursorPaginatedResponse<T>` names its items `data` (`C55`, `C56`). `KeysetPaginatedResponse<T>`
carries `items` and `next_cursor` (`C49`–`C54`) and is the closest match; it is the runner-up
below.

##### Ranked runner-up

`api_bones::pagination::KeysetPaginatedResponse<T>` 6.12.0 — `items`, `next_cursor`, and
three more members: `has_next`, `has_prev` and `prev_cursor` (`C49`–`C54`). It is the only
third-party envelope in the field whose item and continuation members match this contract's
names. It is refused on three differences. Its request types spell the position `after` and
`before`, not R6.5's `cursor` (`C57`–`C63`). It carries three members this contract does not
use. And it brings a 4-star API-scaffolding crate (`F32`) into the tree for one struct.

##### Migration implications

`src/web/pagination.rs`: the `ListResponse<T>` declaration and the `encode_cursor` /
`decode_cursor` pair. Every collection handler's return type becomes
`Json<ListResponse<DomainType>>`.

##### Validation strategy · Confidence & re-verify trigger · Sources

Executed: `P06`–`P10`. `P08` is the load-bearing one: the envelope's `items` is byte-equal to
serializing the domain values directly, so the wrapper is provably the only web-specific
thing. Confidence **high**. Re-verify on triggers 2 and 6. Sources: the standard (`S18`–`S22`,
`S48`–`S53`); `paginator-utils` and `api-bones` published sources (`F60`, `F61`, `C15`–`C18`,
`C49`–`C63`); dropshot (`C10`).

#### cursor-codec — `base64` 0.23.1

##### Recommendation

`base64 = { version = "0.23.1", optional = true, default-features = false, features = ["std"] }`
(`>= 0.23.1, < 0.24.0`), enabled by `web = ["dep:axum", "dep:tokio", "dep:base64"]`, engine
`URL_SAFE_NO_PAD`, encoding the boundary row's immutable key.
**The only dependency this bundle adds, and with default features off it adds no `unsafe`
either** — the probe is built with the same `default-features = false, features = ["std"]`
setting (a scratch crate, so without the `web` feature) and all 15 contract tests pass on it (`E06`,
`E03`, `E04`).

##### Figures, gates, and standing

90-day downloads **329 396 349**; all-time **1 596 330 399** (`F12`). Newest unyanked version
**0.23.1**, released **2026-08-04**, `MIT OR Apache-2.0`, `rust-version` **1.71.0** (`F24`,
`F24.e`). Repository `marshallpierce/rust-base64`: 737 stars, not archived, pushed 2026-08-18
(`F27`), 11 open issues by the search endpoint (`F35`), median 0.4 days to a maintainer's
first reply across the ten most recently opened issues, three of them unanswered (`F41`). More than a
thousand reverse dependencies (`F65`). No open advisory against this version (`F46`–`F48`).
**Zero normal dependencies** (`F50`), so no async runtime is coupled. Maintenance state:
**active**. `unsafe` posture: every site is gated behind the default-on `simd-unsafe`
feature, and with that feature off the crate is `#![forbid(unsafe_code)]` (`C19`–`C22`) —
which is how this decision takes it.

##### Ranked runner-up

Hex encoding via `std`, adding no dependency at all — a longer token and a departure from the
`rust-lang/crates.io` precedent, but a genuine zero-dependency fallback if the single added
crate is ever judged not worth it. The contract does not change either way, because the
cursor is opaque by construction.

##### Tradeoffs

The honest limit, stated rather than glossed: **base64url over a key is opaque by contract,
not cryptographically non-constructable.** R6.3 asks for non-constructable cursors and R12.5
places the matching obligation on clients (`S47`); a determined client can still decode this
token. It can equally decode the standard's own example cursor (`S59`), which is why the R6.3
row reads the property as contractual and records **conforms**. `rust-lang/crates.io` ships the same construction (`C07`). If opacity ever needs to be
enforced rather than asked for, the codec is the single place that changes — signing or
encrypting the payload leaves every other part of this decision untouched.

##### Validation strategy · Confidence & re-verify trigger · Sources

Executed: `E01` (it appears exactly once in the normal dependency tree), `P05`, `P06`.
Confidence **high**. Re-verify on triggers 3 and 4. Sources: crates.io API (`F12`, `F24`);
GitHub API (`F27`, `F35`, `F41`); rustsec (`F46`–`F48`); `rust-lang/crates.io` (`C07`).

### Compatibility

The three members are proven together rather than argued together: **one probe crate compiles
all three into one axum 0.8.9 service and passes 15 contract tests on two toolchains**
(`E01`–`E06`). The version matrix exercised is axum 0.8.9 · tokio 1.53.1 · tower 0.5.3 (dev)
· serde 1 · base64 0.23.1, at rustc **1.98.1** (host) and rustc **1.96.0** (the MSRV floor).
That is the R69-published stack plus exactly one crate. The shared external adopter for the
*pattern* — reserved-name params, an opaque base64url token, a generic items-plus-continuation
envelope, and OpenAPI parameters derived from the same struct axum extracts — is
`rust-lang/crates.io` (`C01`–`C09`).

### Migration implications

Against published R69's `src/web/` layout (`I15`, `I16`):

| File | Change |
|---|---|
| `src/web/pagination.rs` | **New.** `Limit`, `PageRequest`, `Page<T>`, the seek window, `PaginationLimits`, `Pagination` (the extractor), `ListResponse<T>`, `encode_cursor` / `decode_cursor`. About sixty lines |
| The collection handler's ordering step | **Required, not optional.** The seek window is a binary search, so it is correct only over the documented total order; the route applies that order (ascending `id`) before taking a window. This is why the standard calls a stable order "a soundness requirement for R6.3" (`S35`). In the probe it is an `ordered` helper plus a `debug_assert` inside `seek_page`, and `P14` proves an unordered source still pages correctly |
| `src/web/mod.rs` | `AppState` gains a `limits: PaginationLimits` field and an `impl FromRef<AppState> for PaginationLimits` |
| `src/web/routes/projects.rs` | The collection handler takes one `Pagination` argument and returns `Json<ListResponse<Project>>` |
| `Cargo.toml` | Two edits. Under `[dependencies]`: `base64 = { version = "0.23.1", optional = true, default-features = false, features = ["std"] }`. Under `[features]`: `web = ["dep:axum", "dep:tokio", "dep:base64"]`. Nothing else changes. Why this leaves R69's registered `web-extra-surface` value unchanged is argued under coupling 1 of `## Decision` |
| The web tests | Gain all 15 assertions, `P01`–`P15`. Thirteen run against the real route (`P01`–`P11`, `P14`, `P15`). `P09`'s exact-set assertion is **probe-scoped**: the template's `P09` asserts only that `link` and `x-total-count` are absent, never the probe's exact set of `content-type` and `content-length`, because R7.1 and R11.7 require headers other items add to every response (`S80`–`S82`). `P12` calls the window function directly to compare keyset with offset, and `P13` is the type-level `Limit::new` check, so both are unit tests of `src/web/pagination.rs` |
| The API's conformance note (R1.7's template) | Gains **no** `Deviations:` row and **no** `N/A declarations:` row from R72. R6.7 and R6.10 are declined `MAY`s, and R6.8 and R6.9 bind only filter parameters, of which none are offered; none of the four is a rule or switch that "cannot apply" in the template's sense (`S63`–`S65`). The reasoning is under *What this decision does not decide* |

Because everything lands inside the gated `src/web/` tree, the whole contract is absent when
the `web` feature is off, and `base64` is an optional dependency that is not compiled either.

### Validation strategy

Executed in this run, reproducibly (`## Empirical check`): the 15 contract tests, on two
toolchains, from a scratch crate built offline on the published stack.

Planned for P03, against the template's own route rather than a probe:

1. The same 15 assertions, `P01`–`P15`, re-expressed against the template: `P01`–`P11`,
   `P14` and `P15` as web integration tests on `GET /v1/projects`, and `P12` and `P13` as unit tests,
   since neither goes through a route. `P09`'s exact-set assertion is probe-scoped: in the
   template, `P09` asserts only the absence of `link` and `x-total-count`, so it cannot fail
   when R75 adds the `request-id` header (R11.7) or a `Cache-Control` header lands (R7.1).
2. A conformance pass binding each assertion to its rule ID, so a future change to the
   standard has one place to be checked against.
3. The rejection statuses re-checked **through R70's problem envelope**, confirming that a
   `422` from this extractor renders as a conforming problem document with a catalogued code —
   the one thing the probe deliberately does not test, because it returns a bare status.
   **This check waits on R70's publication.** R70 is still open (`I42`, `I43`), so the
   envelope it would run through is not yet decided.
4. Once R71 lands: assert that the generated OpenAPI document contains one shared
   `components.parameters` entry for `cursor` and `limit` and one shared envelope schema, per
   Appendix D's row (`S49`).
5. The stability property (`P12`) re-run against a real mutating source once R05's port pages
   upstream, rather than against an in-memory insertion.

### Confidence & re-verify trigger

**High** on the contract and on the mechanism; the contract is fixed by a binding standard
asserted by 82 checks, and the mechanism is executed rather than described. **Moderate**
on one point, stated above rather than buried: the OS-matrix limb of gate 4. `base64`'s own
CI is CircleCI on Linux Docker images with **no** macOS executor (`C24`, `C26`), so Linux
rests on the maintainer's CI and macOS rests on this run's own execution (`E03`, `E04`). The
`unsafe` limb, which an earlier draft of this decision left as a gap, is now read at the
source and closed (`C19`–`C22`). Re-verify on the seven triggers listed under `## Decision`,
or at **2026-12-20**.

### Sources

The org REST API Design Standard v2.0.0, `smorinlabs/rest-standards` commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`, blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`
(read-only via `git show`, 2026-09-21) · `docs/port/OWNER-REVIEW.md:187` (W2-REST) and `:47`
(the licence ruling) · `research/topics/69-web-framework-stack/DECISION.md` at
`d4507f5b…` · `research/topics/01-ports-and-adapters-seam/DECISION.md` ·
`docs/port/COMMONALITY.md:314-315` · `py-launch-blueprint` at pin
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` and its resolved `fastapi-pagination` 0.15.15 ·
`rust-lang/crates.io` `src/controllers/helpers/pagination.rs` at commit
`30c4ed7fd9b79eba10e42d5c173e9bdd8aab1b4c` · `oxidecomputer/dropshot` 0.17.1 `ResultsPage` ·
`axum` 0.8.9 and `axum-core` 0.5.6 sources from the local registry cache ·
`GET https://crates.io/api/v1/crates/<name>`, `/versions`, `/<version>/dependencies`,
`/reverse_dependencies` for twelve crates · `GET https://api.github.com/repos/<o>/<r>`,
`/search/issues`, `/repos/<o>/<r>/issues` and per-issue comments for eight repositories, and
`GET https://api.github.com/repos/<o>/<r>` and the open-issue search for
`rodmen07/axum-api-kit` and `a1akris/page-turner`, plus `page-turner`'s README
(`r72-fetch-revision4.sh`) ·
`https://rustsec.org/packages/<name>.html` for twelve crates plus the `rsa` control, and
`https://rustsec.org/advisories/RUSTSEC-2017-0004.html` · the published `.crate` sources of
`paginator-axum` 0.4.0, `paginator-utils` 0.4.0 and `api-bones` 6.12.0 ·
`gh api search/issues?q=repo:<o>/<r>+is:issue&sort=created&order=desc&per_page=10` and
per-issue comments for `marshallpierce/rust-base64` and `maulanasdqn/paginator-rs` · the same
query and per-issue comments for `daniel-samson/paginate`, `alexandrughinea/sqlx-paginated`,
`WyattAu/paginate`, `jmtamayo/page-hunter`, `brefwiz/api-bones`, `rodmen07/axum-api-kit` and
`a1akris/page-turner` (`r72-fetch-revision3.sh`) · `py-launch-blueprint`'s `pyproject.toml`
extras at the pin ·
`nakamuraos/rust-axum-seaorm-boilerplate` at `2ad8073c13404a0a2e49845938a2301dfdf433fd`,
`hendrixmar/rust-axum-seaorm-boilerplate` at `9bb388c706ab7b789b6edf8a79dce5453b8b00f1`,
`coreapostrophe/axum-template` at `f1bd22bfe07a2c58ee21d30d9d92e51814e0adc6`,
`joshua-mo-143/99minutos-template-agents-rust` at
`9142f9985ffb3b52980a9792b900b844521ee92e`, and the 404s plus empty Wayback records for
`99minutos/template-agents-rust`. Timestamps are those under **Retrieval dates** above:
2026-09-21 (UTC) for the popularity snapshots, 2026-09-22 (UTC) for the practice,
revision-2 and revision-3 sources, and 2026-09-23 (UTC) for the revision-4 sources, unless a
pin states otherwise.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**This item owns no parameter**, and the four `assumes` lines above are the complete set. The
prompt's `## Couplings` block declares an empty `consumes:` list (`I10`) and
`inputs/parameters.json` carries exactly these four fixed values (`I04`–`I08`), byte-identical
to the live registry in `docs/port/PARAMETERS.md` (`I09`). **No `assumes web-extra-surface`
line is written**, following the precedent R79 set for an item whose prompt consumes nothing:
R69's value is quoted in prose instead, under the couplings above. The `raw/opus.md` leg wrote
six `assumes` lines, including `web-extra-surface` and `http-transport-injection-seam`; those
two are not registry dependencies of this item and are carried as prose.

**No `CONFLICT:` lines.** The four that two Doxa legs raised against R69 are disposed under
`## Engines`, and none triggers RUNBOOK §4. This synthesis emits no `BASELINE-REVIEW:` finding
of its own; the three that Doxa legs raised are disposed under `## Engines`.

## Empirical check

**Toolchain and OS.** macOS 15 on Apple silicon (Darwin 25.4.0, `aarch64-apple-darwin`).
`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` / `cargo 1.98.1` as the host, and
`rustc 1.96.0` as the MSRV floor — stable minus two minors under the fixed policy. All builds
run `--offline` from the local registry cache, so no crate was downloaded during the build.

**Working directory.** A scratch crate created with `mktemp -d` under `$TMPDIR` and removed by
the script's `trap` on exit. **No Rust file was written into this repository**, which is still
a research tree.

**Command.** `bash review/evidence/r72-probe.sh`, which writes the crate, runs `cargo tree`,
then `cargo test --offline` on the host and again under `rustup run 1.96.0`.

**Observed output: 20 checks, 0 failures, 0 skips** (`review/evidence/r72-probe.log`). The 15
contract tests pass on both toolchains.

| Check | What it proves | Observed |
|---|---|---|
| `E01` | `base64` is a direct addition and nothing else in the stack pulls it | one occurrence in `cargo tree -e normal` |
| `E02` | the probe runs on the version published R69 selects | `axum v0.8.9` resolved |
| `E03` / `E04` | the design compiles and passes at the host and at the MSRV floor | `test result: ok. 15 passed; 0 failed` on both |
| `P01` | the documented default comes from the one value in state | bare `/v1/projects` returns 50 items |
| `P02` | the maximum is enforced, and rejected rather than clamped | `limit=101` → `422`; `limit=100` → `200` |
| `P03` | a zero window is semantically invalid, not malformed | `limit=0` → `422` |
| `P04` | a non-numeric window is malformed syntax | `limit=abc` → `400` |
| `P05` | an undecodable cursor is malformed syntax | `cursor=!!!not-base64!!!` → `400` |
| `P06` | the cursor round-trips and the windows are ordered, disjoint and contiguous | pages `prj_0000..0002` then `prj_0003..0005`; the token is `base64url("prj_0002")` |
| `P07` | the last page has no continuation, and a window past the end is not a `404` | `next_cursor: null`; then `200` with `{"items":[],"next_cursor":null}` |
| `P08` | the items are the caller's own domain objects | the envelope's `items` equals `serde_json::to_value(&rows)` exactly |
| `P09` | pagination state lives only in the body | response headers are `content-type` and `content-length`, an exact set that holds only in this middleware-free probe (probe-scoped; see `### Validation strategy`); no `link`, no `x-total-count` |
| `P10` | the envelope is an object with items plus continuation | keys are exactly `["items", "next_cursor"]` |
| `P11` | one extractor serves every collection with no per-route configuration | a second route filters correctly and rejects `limit=0` with the same `422` |
| `P12` | the property R6.3 exists for | after an insertion between two reads, the keyset window returns `prj_0003..0005` while the offset window repeats `prj_0002` and loses `prj_0005` |
| `P13` | an out-of-range window is unrepresentable | `Limit::new(0, 100)` and `Limit::new(101, 100)` are both errors |
| `P14` | the route establishes the documented order rather than assuming it | a reversed-and-shuffled source still pages `prj_0000..0002` with the matching cursor |
| `P15` | a route that does not stream refuses `stream` with any value (R13.3) | `stream=true`, `stream=false` and `stream=` on `/v1/projects`, and `stream=true` on the second route → `400`; the same request without `stream` → `200` |
| `E06` | the added crate is taken without its `unsafe`-bearing default feature | the manifest that built carries `default-features = false, features = ["std"]` |

**The other checks in `review/evidence/`**, each with its script and its committed log:

| Script | Checks | Result |
|---|---|---|
| `r72-standard.sh` | `S01`–`S82` — every rule quoted at its line in blob `71bd813c`, the decoded example cursor, R6.9, R6.8's lack of any RFC 2119 keyword, the conformance note's `N/A declarations:` slot, R1.6's switch reasons, R13.3 with its switch scope, guard rule, checklist row and probe row, and the R7.1 and R11.7 response-header rules | 82 pass, 0 fail, 0 skip |
| `r72-inputs.sh` | `I01`–`I86` — raw hashes, all four fixed parameters against the live registry, R69 and R01 as published, R69's clause (4) and its full `axum-extra` sentence, the value's heavier-opt-ins clause, py's extras, every raw `CONFLICT:` line, R70 still open, the py precedent at its pin, the W2-REST ruling, Opus's `400` rejection lines, the owners of R7.1 and R11.7, R01's behavior 6 and its registered parameter, R03's rule 1 at its accepted hash, and R69's ungated `serde` | 89 pass, 0 fail, 0 skip |
| `r72-figures.sh` | `F01`–`F79` — every candidate figure and every gate, asserted offline against the snapshots (`F41` and `F42` against the revision-2 issue population, `F66`–`F72` against the revision-3 one, `F73` the missing-`rust-version` count, `F74`–`F79` against the revision-4 retrieval) | 167 pass, 0 fail, 3 skip |
| `r72-practice.sh` | `C01`–`C63` — crates.io's production helper, dropshot, api-bones' three envelopes and their request types, axum's extractor model, the `unsafe` census, `base64`'s CI platform list, and the three templates Muse named | 65 pass, 0 fail, 0 skip |
| `r72-probe.sh` | `E01`–`E06`, `P01`–`P15` | 20 pass, 0 fail, 0 skip |
| `r72-fetch.sh` | the network snapshot set | 59 endpoints answered, **0 gaps** |
| `r72-fetch-practice.sh` | the two production sources, the api-bones crate, and `base64`'s CI configuration | 4 answered, **0 gaps** |
| `r72-fetch-revision2.sh` | the ten most recently opened issues of `base64` and `paginator-rs` with every comment, and the three templates | 33 answered, 2 recorded `ABSENT` (the missing template repository), **0 gaps** |
| `r72-fetch-revision3.sh` | the ten most recently opened issues of the seven other candidate repositories, with every comment | 32 answered, **0 gaps** |
| `r72-fetch-revision4.sh` | the repository records and open-issue counts of `rodmen07/axum-api-kit` and `a1akris/page-turner`, and `page-turner`'s README | 5 answered, **0 gaps** |
| `r72-archive-rerun.sh` | reproducibility | 5 pass, 0 fail |

The three `r72-figures.sh` skips are the three SPDX licence strings containing a space
(`MIT OR Apache-2.0`), which the whitespace-delimited assertion table cannot carry; each is
asserted literally on the line below its skip (`F18.e`, `F22.e`, `F24.e`), so nothing is
unchecked.

**Reproducibility, itself checked rather than asserted.** `r72-archive-rerun.sh` extracts the
repository at `HEAD` (`e0b0d1c1762ee8aa4b28c62282a2225103e594eb`, 7 365 files) into a clean
scratch tree with `git archive`, copies this directory's scripts and snapshots in, reruns all
five deterministic scripts there, and byte-compares each log against the one committed beside
it. **All five reproduce.** One line of two logs legitimately differs — the `root:` /
`snapshots:` line of the environment block, which names the tree the script ran in and cannot
be equal across two trees. That line is normalised before the comparison, the normalisation
guards against producing an empty file (a bug that would make two empty streams compare equal,
and which this check caught during development), and both versions of the line are printed in
full at the end of the log so the normalisation hides nothing. The five fetch logs are
deliberately not compared: they carry retrieval timestamps, and their output is the
`snapshots/` directory that `r72-figures.sh` and `r72-practice.sh` assert offline.

`shellcheck` 0.11.0 reports **no findings** on all eleven scripts.

## Engines

Three engines produced raw reports: **Muse** (Meta, substituted for Codex under the
`engine_overrides` pilot), **Opus** (Claude Opus 5), and **Doxa** with three provider legs —
`openai` / `gpt-5.6-sol`, `perplexity` / `sonar-deep-research`, `gemini` /
`deep-research-preview-04-2026`, all under operation
`research-20260918-150431-3cb17a06c88b457a`. Five positions, because the Doxa legs disagree
with each other.

| Engine / leg | Position on the contract | Position on the crate |
|---|---|---|
| **Muse** (2026-09-19) | `page` + `limit` in, `items`/`total`/`page`/`limit`/`total_pages` out; claims R6.3's small-collection exception | **No crate.** Template-owned types on axum |
| **Opus** (2026-09-18) | `cursor` + `limit` in, `items`/`next_cursor` out; keyset window; rejects `limit=0` and `limit=101` with **`400`** | **No crate**, plus `base64` 0.23.1 for the token |
| **Doxa · openai** | `page` + `size` in, `items`/`total` out — py's shape unchanged | **No crate.** A local `web::pagination` module |
| **Doxa · perplexity** | page/size, with an app-wide `configure_pagination` call in the composition root | **Adopt** `paginator-rs` + `paginator-utils` + `paginator-axum`, with `api_bones::PaginatedResponse<T>` for the envelope |
| **Doxa · gemini** | page/per_page, `PaginatedJson<T>` envelope | **Adopt** the `paginator-rs` bundle |

**This decision follows Opus on the contract, except for the status of an out-of-range
`limit` (Opus `400`, this decision `422`; Disagreement 7), and all five engines' majority on
the crate question, and it does so on re-derived evidence rather than by counting votes.** Every
load-bearing claim below was re-checked at its source by this synthesis.

**The three `BASELINE-REVIEW:` lines the Doxa legs raised, each disposed.** All three
challenge F311, the app-wide registration row. None of the other engines raised one.

| Leg | Raw line | What it proposes for F311 | Disposition |
|---|---|---|---|
| **openai** | `raw/doxa-…a540.md:483` | Replace the runtime `add_pagination`-equivalent call with "one composition-root PaginationPolicy value plus a reusable typed extractor named by each collection handler; forbid per-router pagination layers" | **Adopted.** It is this decision's F311 answer: `PaginationLimits` declared once in `AppState`, reached through `FromRef`, read by one `FromRequestParts` extractor (`P11`). The line leaves F310 unchanged. The same leg's F310 position, keeping `page`/`size`, is the one Disagreement 1 rejects |
| **perplexity** | `:1337` | Adopt `paginator-rs` with a generic `PaginatedResponse` envelope, "registered once at the composition root" | **Refuted** by Disagreement 3: the family exports no registration function to call once (`F57`, `F62`). The crate family also fails the contract (Disagreement 2) |
| **gemini** | `:2025` | "explicit typed pagination contracts per-route": the extractor and the envelope type on each handler signature, and no global middleware | **Consistent with the adopted design.** A typed extractor and `Json<ListResponse<T>>` on each collection handler is exactly that; alternative E's refusal says the same thing. The leg's crate choice is disposed separately (Disagreements 2 and 4) |

None of the three changes another item or the ledger. F311 is settled in prose under
`## Decision`, and `docs/port/BASELINE-REVIEW.md` has no row for a `DIVERGENT` item to move.

**The four `CONFLICT:` lines the Doxa legs raised, each disposed.** Two legs wrote conflict
lines against R69. Muse and Opus raised none, and the openai leg wrote `CONFLICT: none`
(`raw/doxa-…a540.md:749`; `I48`, `I53`). The combined Doxa report carries exactly four lines
naming an item (`I52`). Each is quoted verbatim below; the leg follows from the report's leg
headers at `:15`, `:1074` and `:1758` (`I49`–`I51`).

The perplexity leg, `raw/doxa-…a540.md:1420` (`I44`):

> CONFLICT: R69 `web-framework-stack` — **needed value: one of `axum`, `actix-web`, or `rocket`** — **reason: `paginator-rs` currently provides integration crates only for these frameworks and must integrate with the chosen extractor model.**

The perplexity leg, `:1636` (`I45`):

> CONFLICT: R69 `web-framework-stack` — **needed value: one of `axum`, `actix-web`, or `rocket`** — **reason: required for `paginator-rs` integration; other frameworks would require additional integration work or a different pagination bundle.**

The gemini leg, `:2105` and again, identically, `:2151` (`I46`, `I47`):

> *   `CONFLICT: R69 web-framework-stack — axum — The paginator-axum crate requires Axum as the host web framework; if R69 resolves to Actix-Web or Rocket, the equivalent paginator-actix or paginator-rocket crates must be substituted in the dependency manifest.`

All four fail on the same three grounds, and any one of them would dispose them.

| Ground | Evidence |
|---|---|
| **Malformed.** The format is `CONFLICT: R## <param> — <needed value> — <reason>`, and the `<param>` slot must name a registered parameter. All four name R69's slug, `web-framework-stack`. The parameter R69 owns is `web-extra-surface` | `research/CLAUDE.md`'s R69 row: slug `web-framework-stack`, owns `web-extra-surface` (`I54`); `docs/port/PARAMETERS.md` registers `web-extra-surface` under R69 (`I56`) and has no row named `web-framework-stack` (`I55`) |
| **The needed value is already satisfied.** The perplexity lines ask for one of `axum`, `actix-web` or `rocket`; the gemini lines ask for `axum`. Published R69 selects axum | "axum 0.8.9 optional and its default features on" (`I17`); the probe resolves `axum v0.8.9` (`E02`) |
| **Void in any case.** Every line exists to serve the `paginator-rs` family, and this decision refuses that family on the contract | Disagreements 2 and 3 below; alternative A |

**RUNBOOK §4 is therefore not triggered.** Its procedure keeps the consumer in progress,
appends the line under a `### Conflict from R72` subsection of R69's `## Context`, and
reopens R69. None of that applies: no registered value is asked to change, and the value
the lines ask for is the one R69 already published.

**Disagreement 1 — page-index versus cursor. Adjudicated for cursor.** This is the split the
controller flagged. Muse and all three Doxa legs keep a page index; Opus moves to
cursors. Three independent grounds decide it, set out in full under
`### Principles and implementation`: R6.3's exception carries a precondition a *template*
cannot document (`S25`–`S27`); the standard registers no page-index parameter name at all, so
there is no conforming spelling for one (`S14`–`S16`) and R1.7 would force a written deviation
(`S03`–`S07`); and the owner's W2-REST ruling states the consequence explicitly, that py's
shape "is nonconformant and the first-party cursor contract stands" (`I30`–`I33`). **The Muse
leg postdates that ruling by a day and cites it, but reaches the opposite conclusion from
it** — it reads R6.5 as reserving only `limit` and treats the exception as available. Its
reading of R6.5 is incomplete at the text: the rule's first sentence is "The pagination request
parameters are `cursor` and `limit`" (`S30`), the conformance checklist row says "`cursor` and
`limit` names" (`S54`), and Appendix C's one-line summary of §6 reads "`cursor` + `limit` in;
`items` + continuation out" (`S48`). The three Doxa legs, which keep `page`/`size` (openai,
perplexity) or `page`/`per_page` (gemini), were never shown the standard — it is not in their
prompt — so their position is evidence about the ecosystem, not about conformance, and it is
treated that way.

**The template evidence Muse offered for the page-index side does not move this either.** It
was re-read at source for the LOW question (`### Landscape`, `C29`–`C48`). Of the three
templates, one does not exist publicly, and one has no pagination at all. The third offers a
page window with a total, spelled `page`/`per_page`/`data`, and ships a cursor mode beside
it. That is evidence that a page window is a familiar template convention, which this
decision does not dispute. It is not evidence for a *conforming* page-index contract, because
the standard has no name for one (`S14`–`S16`).

**Disagreement 2 — adopt the `paginator-rs` bundle, or not. Adjudicated against, at source.**
Two Doxa legs recommend adopting it. This synthesis downloaded and read the published crate
rather than its documentation, and found four independent contract defects: the wire name is
`per_page` (`F54`, `F55`), the envelope member is `data` (`F60`), `create_link_header` is
exported (`F58`), and `IntoResponse` sets an `X-Total-Count` header (`F59`) — pagination state
in a header, which R6.4 puts only in the body (`S28`). Each would have to be wrapped away, at
which point the wrapper is the design and the crate is dead weight.

**Disagreement 3 — Perplexity's "single configuration call in the composition root".
Refuted.** The leg's central argument for adoption is that the family can be "wired via a
single configuration call", mirroring `add_pagination(app)`. It cannot: `PaginationQuery` is an
`impl FromRequestParts` taken per handler (`F57`), and a census of both crates' sources finds
**no** exported registration function of any spelling (`F62`). The claim is false at the
source, and with it the leg's main reason to prefer the crate over template-owned types.

**Disagreement 4 — Gemini's utoipa compatibility claim. Not supported.** The leg states
`PaginatedJson<T>` is "fully compatible with Utoipa 5.0's schema generation engine", implying
the crate emits schema components. The type exists — that much is right — but
`paginator-axum` declares **no `utoipa` dependency of any kind** (`F51`), so it emits nothing;
a consumer would derive the schema themselves, exactly as with a template-owned type. The
member's OpenAPI advantage over hand-rolling is therefore zero, and the production precedent
shows hand-rolling is already free (`C03`).

**Disagreement 5 — Gemini's gate exclusions. Two are rubric errors; one figure is right.**
The leg excludes `page-hunter` on gate 1 for a "non-standard" licence and `paginate` and
`paging` as "dormant". The licence figure is **correct** and this synthesis reproduces it
(`F19`), but the exclusion is not: gate 1 is struck programme-wide by the owner ruling of
2026-09-12, so nothing may be excluded on licence. The "dormant" verdicts misapply the
prompt's own rubric, which requires an unpatched advisory, a broken build on current stable,
or a maintainer's notice; `paginate` has none of those, so it is **stable-quiet** — age alone
is "a trigger to investigate, never the verdict". Neither correction changes any outcome:
both crates are refused on fit regardless.

**Disagreement 6 — the default page size: 20, 50 or 10.** Muse proposes 20, Opus 50,
`rust-lang/crates.io` runs 10 (`C01`). Settled at the source precedent: py declares
`size: int = Query(50, ge=1, le=100)` (`I29`), so **50 and 100** carry the source's own values
into the port and need no independent justification.

**Disagreement 7 — clamp or reject an over-maximum `limit`.** Muse clamps to 100; Opus
rejects. R11.1 says "publish and enforce" (`S45`) and either satisfies it, so the tie is broken
by precedent, and both precedents point the same way: py's `le=100` rejects (`I29`), and
`rust-lang/crates.io` rejects with an explicit message (`C05`, `C06`). Rejection also tells a
client its request was not honoured, where clamping silently returns something other than what
was asked for. **Reject, with `422`.**

**Which status the rejection carries: Opus's `400` or `422`. Adjudicated for `422`, on R5.3.**
Opus rejects too, but with `400`. Its contract call is "made as **reject with `400`**"
(`raw/opus-…332d0.md:168`, `I71`); its verification table records that the extractor
"rejects `limit=0`, `limit=101` and a malformed `cursor` with `400`" (`:278`, `I72`); its
contract states "**rejected with `400`, never clamped**" (`:437`, `I73`); and its probe
printed `CUSTOM limit=0 -> 400 Bad Request` and `CUSTOM limit=101 -> 400 Bad Request`
(`:1093`–`:1094`, `I74`, `I75`). Opus's two stated grounds, observability and the
`rust-lang/crates.io` precedent (`:168`–`:171`), argue for rejecting rather than clamping;
neither addresses which status. The standard does. R5.3 reads "`422 Unprocessable Content`
SHOULD be used for semantically invalid but well-formed requests" and "`400 Bad Request`
remains correct for malformed syntax" (:939–942, `S39`–`S42`), and its quick map repeats the
split (:2847, :2853, `S43`, `S44`). `limit=0` and `limit=101` parse as integers, so they are
well formed and semantically invalid: `422`. Answering them with `400` would depart from a
SHOULD, which R1.7 allows only in writing, as a `Deviations:` row (`S03`–`S07`). The two
positions agree that a malformed `cursor` is `400`.

**Disagreement 8 — whether `total` survives.** Muse and all three Doxa legs keep it: Muse as
`total` beside `total_pages`; openai as `total` in its `Page<T>` (`raw/doxa-…a540.md:299`);
perplexity as an "items/total" envelope (`:1341`) built on `api_bones`' `total_count`
(`:1398`); and gemini as `total` and `total_pages` in `PaginatedJson<T>` (`:2067`). Opus drops
it. Dropped, for the three reasons under `### Principles and implementation`, of
which the decisive one is that `total` is additive later and breaking to remove.

**Disagreement 9 — where the web tree lives.** The Opus leg wrote every path as
`crates/web/…`, following R69 revision 10, which is owner-accepted but **unpublished**. The
prerequisite this run pins is the published R69 (`I13`, `I14`), whose layout is `src/web/`
(`I15`, `I16`) and which never says `crates/web` (`I18`). **This decision uses the published
layout** and records R69's republication as re-verify trigger 1.

**Disagreement 10 — how many `assumes` lines the Parameters block carries.** Opus wrote six,
including `web-extra-surface` and `http-transport-injection-seam`. The prompt declares an empty
`consumes:` list (`I10`), and `parameters.json` carries only the four fixed values
(`I04`–`I08`). **Four lines**, with R69 quoted in prose — the shape R79 established for an
item that consumes nothing.

**Where the raws' figures and this decision's differ.** Muse's GitHub numbers came from HTML
pages because the API was unreachable from its sandbox, and it recorded issue-responsiveness
medians as an unrecoverable gap. Every endpoint answered this time, so the figures here are
first-hand and the gap is closed. `F41` and `F42` report the medians the prompt asks for, over
the prompt's population: the ten most recently opened issues, with pull requests excluded by
the query. Revision 1 measured the ten newest issues and pull requests together, which left
only 2 and 4 issues; `paginator-rs` has 8 issues in all, so its figure covers all of them.
Revision 3 extends the same figure to the seven other candidate repositories (`F66`–`F72`,
tabulated under *Maintenance state*).
Download counts differ slightly from every raw's — `paginator-axum` 6 714 recent here against
Muse's 7 012, for instance — which is ordinary drift in a rolling 90-day window over two days,
not a discrepancy. **Use the figures in this decision;** they are the ones the committed
snapshots support.

**Where evidence is incomplete, stated plainly.** Three things this decision does not know —
one fewer than an earlier draft, because the `unsafe` limb was closed by reading the sources
rather than left as a gap (`C19`–`C23`, `C27`, `C28`; `api-bones`' five occurrences turn out
to be four `unsafe` blocks around `std::env::set_var` in its own `#[test]` code plus one
comment, which is why the census reports the count instead of judging it). (1) Gate 4 is read
for the recommended crate, but **no CI configuration was read for any declined candidate**,
so their gate-4 cells stay gaps. (2) Six of the eleven candidate crates, which is five of the
ten gate-table rows, declare no `rust-version` (`F73`), so their MSRV is unverifiable from
metadata — recorded as gaps, which is why none is *excluded* on gate 2. (3) The type of `Project::id` is undecided by any accepted decision, so the
cursor's payload is specified by role and demonstrated with a `String`. Issue responsiveness
is not a gap: it is computed for all nine candidate repositories, and it is `inapplicable`
only for the three that have never had an issue (`F67`, `F68`, `F71`).

**What P03 must validate**, beyond re-running the probe's assertions against the real route:
the five items under `### Validation strategy`, and in particular the interaction with R70,
once R70 publishes — a `422` from this extractor must render as a conforming problem document
with a catalogued code, which is the one part of the path this synthesis deliberately did not
test.
