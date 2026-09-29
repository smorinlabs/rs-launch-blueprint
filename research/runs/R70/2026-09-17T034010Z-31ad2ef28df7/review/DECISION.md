# 2026-09-27 — R70 — http-problem-envelope (bundle, Focused) — decision (revision 5)

## Decision

**Revision note (revision 5).** Both audits of revision 4 (sha256
`7a9345c67b42d504501e2039214fd42d9d31b69d61402c958c62c5bf7448a410`, preserved
byte-identical at `review/R70-r4-snapshot.md`) rejected it. The judgment audit
(`review/audit-fable.r4.md`) rejected it on F-1 and F-2. The empirical audit
(`review/audit-claude.r4.md`) rejected it on EA-1. Separately, R80 published
revision 6 (`research/topics/80-health-probe-endpoints/DECISION.md`), which
hands this item the choice of how `/readyz`'s 503 carries R80's diagnostic
report: "R70 owns the choice" (R80 revision 6, `:859-865`). Revision 5 applies
only the repairs the coordinator's repair brief enumerates. **The recommendation
does not move except for the one choice R80 assigned here: the carrier is a
`diagnostics` extension member**, with the rationale under `## Engines`, "The
`/readyz` diagnostic carrier". No criterion changes, and OV-06 is still unused.

| Finding or event | What was wrong in revision 4 | What revision 5 does |
|---|---|---|
| R80 revision 6 (carrier) | The R80 coupling said R80 was "being researched in parallel" and that a fifth extension member was "R80's to justify"; the trigger set waited on "R80 justifying a fifth extension member" | R80 is published and deferred the choice to this item. The coupling and the trigger now state the accepted choice, a `diagnostics` extension member that R80's `/readyz` route appends under the contract's append-only rule. `## Engines` records the choice among R80's three ways and why the other two fail this decision's own rules |
| F-1 (1) | The `/upstream` body's redaction proof was attributed to revision 1's `AC5` | Attributed to `R8` (`probe-r2.sh:979-990`) plus the whole-file negative (`probe-r2.sh:1309`) |
| F-1 (2) | "AC16 walks twelve hand-listed requests" | "`R24` walks fourteen hand-listed requests (twelve failing, two succeeding)" (`probe-r2.sh:1225-1262`) |
| F-1 (3) | The W5 rule "executed here as AC3" | "executed here as `R3`" (`probe-r2.sh:914`) |
| F-2 | "Both … reject a derive and a runtime type map (`:136`)" credited the Opus report with a rejection it never makes | Both reject a derive, each cited; Muse alone rejects a runtime `HashMap<TypeId, StatusCode>` |
| EA-1 | `engines-r4.sh:181` pinned line 20 of R80's mutable working-tree `DECISION.md`, which has since moved | The R80 check reads R80's published revision 6 and pins the `OVERRIDE (OV-05)` heading at its `:790`. The revision-5 rerun found the same failure class at the R02 check: R02's `DECISION.md` is now revision 3, and "Depends on `core` only" has left `:29`. That check now reads R02's committed revision-2 snapshot, `review/R02-r2-snapshot.md`, whose sha256 `9e8f8e8c…` is the revision this decision cites. No decision text changes for it |
| Stale op-state gate (S1 ruling) | `engines-r4.sh:87-95` asserted `operations.muse.state` is `submitting` and the run state `partial`. The controller has ruled these states intent paperwork; both legs are verified on disk (`execution-ledger.md:1380`, commit `3b0d45a3`) | Those three assertions now check that both legs are present and well-shaped, and that the Opus receipt matches its file. The manifest still reads `submitting`, so the `## Engines` sentence reporting that state still holds; the evidence no longer gates on it |

Three places change only because a repair above changed what they describe,
and each is listed here so none changes silently. The `engines-r4.sh`
description under `## Empirical check` said the script asserts "the manifest's
missing receipt"; it now says the Muse leg's presence and shape. The same
section's result row for `engines-r4.sh` is restated from the regenerated log,
because the script gained the carrier checks. The revision history below gains a
revision-5 entry.

**Checked and holding, so not edited.** The revision-4 table's JF-1 (5) row still
reads that R80 "now claims" OV-05; R80 revision 6 carries the heading
`#### OVERRIDE (OV-05)` at `:790`. The number paragraph's "R80 took it" (OV-04)
still describes what happened; R80 revision 6 records the collision and its
renumbering at `:792-798`. "`/readyz`'s failure payload (R80)" under "Not created
by this item" still holds: this item chooses the member, and R80 builds the
report it carries. Five passages still describe nine members and four extensions:
the envelope contract table, the R1.8 conformance row, the R71 coupling's "four
extensions", the performance paragraph's "at most nine members", and the
`ProblemExt` field list in the migration table. All five describe the base
contract this item ships, which is unchanged. The `diagnostics` member is scoped
to one route and arrives with R80's implementation. These passages are not
edited under the enumerated-repairs rule and are flagged for the controller.

**Revision note (revision 4).** Both audits of revision 3 (sha256
`802e5292157c97b8530445a7a5c637d8ebcb71c4a3fe232eadd882c7dea5cc8b`, preserved
byte-identical at `review/R70-r3-snapshot.md`) rejected it. The judgment audit
(`review/audit-fable.r1.md`) rejected it on JF-3, JF-1 and JF-2. The empirical
audit (`review/audit-claude.md`) rejected it on EF-1 and EF-2. Both audits found
the recommendation supported and every executed figure reproducing; every finding
is a fidelity or prose defect. **The recommendation does not move, no criterion
changes, and OV-06 is still unused.** Each repair, and where it lands:

| Finding | What was wrong in revision 3 | What revision 4 does |
|---|---|---|
| JF-3 | `## Engines` said the item had one engine and no inter-engine disagreements. The pinned prompt names `muse, opus`, and a Muse report (`raw/muse.md`) that recommends a different crate was neither listed nor adjudicated | `## Engines` names both engines under the Q5.A substitution, lists `raw/muse.md` with its sha256 and collection record, states the manifest's unwritten receipt, and adjudicates Muse's three divergent positions as Disagreements 1–3. The Codex/W1-CODEX3 framing survives only as revision-1 history. The single-engine weakening paragraph, the corrections lead-in and the confidence paragraph are requalified |
| JF-1 (1) | "Twelve carry … **Twelve are new**" and "revision 1's twelve surviving behaviours" | **Thirteen** carried (`R1`–`R3`, `R7`–`R10`, `R12`–`R17`) and **eleven** new (`R4`–`R6`, `R11`, `R18`–`R24`), the partition `probe-r2.sh` defines. `engines-r4.sh` derives both counts from the script |
| JF-1 (2) | "The five items under 'What these checks do not prove'" | "The nine items", counted by `engines-r4.sh` |
| JF-1 (3) | J6: "The fourteen executed criteria prove …" | "The twenty-four executed criteria, `R1`–`R24`, prove …" |
| JF-1 (4) and EF-2 | "The four bodies, captured verbatim by this run:" introduced two revision-1 bodies and six revision-2 bodies | The sentence is deleted. Each of the two body blocks keeps its own attributed lead-in |
| JF-1 (5) | Group C described as the control "for OV-05 and OV-06 being free" | "for OV-06 being free". `rest-r2.sh:255-264` asserts nothing about OV-05, which R80 now claims |
| JF-2 | The prompt's LOW question had no answer | Answered under `### Principles and implementation`, "The prompt's LOW question" |
| EF-1 | R67's "silent refactor" sentence cited at `DECISION.md:135` | Cited at `:136`, the A4 row where it appears |

Two new evidence scripts back the repairs. `review/evidence/engines-r4.sh`
asserts every source fact the new `## Engines` text and the corrected counts
cite. `review/evidence/rerun-r4.sh` reruns all five earlier scripts without
writing over any committed log. Both are reported under `## Empirical check`.
The reruns found one source-side drift: IANA now spells the media-type reference
`[RFC 9457]` rather than `[RFC9457]`, which trips one literal-match check in
`registry.sh`. The registration itself is unchanged and re-asserted; the drift
moves nothing.

**Found while repairing, not raised by either audit.** Revision 3 placed
`impl ProblemSource for <domain error>` in `crates/core/src/error.rs`, in three
places: the migration table's row, its lead-in, and the minimal-example
sentence. That is impossible. The trait is defined in `crates/web`, and
`crates/web` depends on `crates/core` (R02 revision 2, `:29`), so `crates/core`
cannot name the trait without a dependency cycle. It also contradicted this
decision's own R02 coupling, which already puts the trait in `crates/web`.
Revision 4 moves the impl to `crates/web/src/problems.rs`, where the probe
already has it (`probe-r2.sh:359`); `crates/core` now needs no change. This is
prose only and moves no recommendation.

**Revision note (revision 3).** The first judgment audit
(`review/audit-fable.md`, verdict **reject**) found revision 2's recommendation
sound and its evidence reproducing, but blocked publication on **JF-1**: three
revision-1 sentences surviving into revision 2 and contradicting move M-2, the
envelope's member count, and R80's extension-member arithmetic. This revision
rewrites all three to the revision-2 truth and folds in the sentence-level
repairs for **JF-2 through JF-7** (the `R5` claim, the run-date sentence, the
missing R5.10 N/A bullet, the §4.2 sweep, the C1 citation, the unexercised body
carriage of `stream`); JF-8 through JF-10 are recorded and untouched. **No
evidence moves, no criterion changes, and the recommendation is untouched**:
`rest-r2.sh` re-runs PASS 79 / FAIL 0 / SKIP 0 and `probe-r2.sh` PASS 25 /
FAIL 0 / SKIP 0, verdicts identical to the committed logs. Revision 2 is
preserved byte-identical at `review/R70-r2-snapshot.md` (sha256 `fe895588…`).

**Revision note (revision 2).** Owner ruling **W2-REST** (2026-09-18,
`docs/port/OWNER-REVIEW.md`, "2026-09-18 — the REST API Design Standard binds the
HTTP surface (W2-REST)") makes the organisation's **REST API Design Standard
v2.0.0** bind this template's HTTP surface the way the CLI Design Standard binds
its CLI. Revision 1 was written before that ruling. **The recommendation moves on
five points and the crate does not.** `problem_details` 0.10.0 still carries the
document, every fitness gate still passes, every status row is unchanged, the
funnel is unchanged, and the five `- assumes` lines are byte-identical. What moves
is the *shape of the body*, because the standard fixes members RFC 9457 leaves
optional. The standard is read at the pinned blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9` (commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`,
`/Users/stevemorin/c/rest-standards/rest-api-standard.md`); every rule quoted
below is asserted at its line by `review/evidence/rest-r2.sh`.

| # | What moves | The rule that moves it | Was (revision 1) | Is (revision 2) |
|---|---|---|---|---|
| **M-1** | `type` becomes **mandatory** and template-bound | **R5.13** point 5 (`:1076`): "`type` MUST be present on every problem document, and `about:blank` MUST NOT be used" | `type` deliberately **omitted**, which RFC 9457 §3.1.1 defines as `about:blank` | `type` always present, `https`, under a provider-controlled base, bound to `code` by R5.13.1's fixed template `<https base>/<code, underscores to hyphens>` |
| **M-2** | `code` becomes a **snake_case code this item owns**; R67's token moves to `catalog_code` | **R5.13** point 1 (`:1066`): "The `code` grammar is `^[a-z][a-z0-9_]*$` (snake_case, hyphens excluded)" | `code` = R67's `RSLB301` verbatim | `code` = `resource_not_found`, from a total injective `const fn http_code(ErrorCode) -> &'static str`; `catalog_code` = `RSLB301` |
| **M-3** | `errors` becomes an **array**, not a map | **R5.15** (`:1105`): "an array whose entries each carry a JSON Pointer to the offending input location (`pointer`), a stable machine-readable `code`, and a human-readable `detail`" | `errors: BTreeMap<String, Vec<String>>` | `errors: Vec<FieldError>` with `pointer` (RFC 6901), `code`, `detail` |
| **M-4** | a framework rejection's raw text **never reaches the body** | **R8.12** (`:1422`): "Secrets, credentials, and PII MUST NOT appear in problem `detail`, in echoed request input, or in any other response content" | `errors.body` carried `rejection.body_text()` verbatim | the rejection text is logged; the body carries a location, a class code and a fixed detail |
| **M-5** | two new artifacts: the **published catalog** and the **`documentation` member** | **R5.16** (`:1114`): "An API MUST publish a catalog of every problem `type`/`code` pair it can return"; **R5.13** point 4 (`:1074`) | neither existed; docs were deferred whole to R81 | the catalog is *generated* from `ErrorCode::ALL`, so it cannot drift from the status table; `documentation` is an optional member, omitted when absent |

**M-4 is the one that would have shipped a defect.** Revision 1 put axum's
rejection text straight into the body, and serde renders a type mismatch as
``invalid type: integer `12345` ``— the offending **value**. For a `password` or
token field that is a credential in a response body, which R8.12 forbids
outright. Criterion `R18` is the executed proof that the value no longer leaks.

**No `OVERRIDE (OV-nn)` is recorded, and each place one was considered is named.**
The one candidate was R4.10's "the default media type — served when a request
carries no `Accept` header — is `application/json`" (`:846`) against this
envelope's unconditional `application/problem+json`. It is **not** a deviation:
the standard itself rules at `:2218` that "R4.10's default clause carries no BCP
14 keyword, so this is a taxonomy hole rather than a live conflict", and under
R1.1 (`:128`) a clause with no all-capitals keyword states no requirement. R5.12
(`:1035`) separately contemplates exactly this design, calling `application/json`
mirroring a measure it "neither requires nor forbids".

**On the number itself.** Override numbers are now allocated by the controller
rather than found by searching, because two syntheses collided on **OV-04** by
searching concurrently — this analysis found it free and R80 took it while the
analysis ran. **OV-06 is allocated to this item and is deliberately left unused**,
since this revision records no override; gaps in the sequence are expected under
controller allocation. `review/evidence/rest-r2.sh` group C asserts that this
decision declares no `OVERRIDE` heading and that OV-06 is claimed by no decision,
with OV-01 through OV-04 asserted **claimed** as the control that keeps those
zeros from being vacuous.

**Revision history.** **Revision 1**, 2026-09-18 (sha256
`ad568a68c7735cbf642d1d6438ab96dad50148d708f5d39fad23e2ac358ca253`, commits
`c41ff27`, `28d9f76` and `f010b8e`): first synthesis from the single Opus report,
the Codex leg deferred under W1-CODEX3; 65 registry checks, 33 probe checks, 11
archive-rerun checks; no audit has run against it. **Revision 2**, 2026-09-18
(sha256 `fe8955887eb29d3f22c06506fecfea5b4af732096da198eff98429afa0b2c3f1`):
the five moves above under W2-REST; judgment-audited at that hash, verdict
reject on JF-1. **Between revisions 2 and 3**, owner decision Q5.A
(2026-09-21) substituted Muse for Codex on this item, and the Muse leg was
collected on 2026-09-23 (`raw/muse.md`); revision 3 did not represent it.
**Revision 3**, 2026-09-27 (sha256 `802e5292…`, preserved at
`review/R70-r3-snapshot.md`): the JF-1 rewrite plus the JF-2–JF-7 repairs, prose
only; rejected by both audits. **Revision 4**, 2026-09-27 (sha256 `7a9345c6…`,
preserved at `review/R70-r4-snapshot.md`): the Muse leg represented and
adjudicated, the count and citation repairs, and two new evidence scripts;
rejected by both audits. **Revision 5**, 2026-09-27 (this file): the `/readyz`
carrier choice R80 revision 6 assigned here, the F-1, F-2 and EA-1 repairs, and
`engines-r4.sh` rebound off mutable state. **Every revision-1 script and log
is carried byte-identical and none is re-run** — `registry.sh`, `registry.log`,
`registry-figures.log`, `probe.sh`, `probe.log`, `archive-check.sh`,
`archive-check.log`, `registry-archive.log` and `probe-archive.log`, each pinned
by sha256 in `rest-r2.sh` group B. Revision 2's new evidence is two files,
`review/evidence/rest-r2.sh` and `review/evidence/probe-r2.sh`, with their logs.
Revision 4 adds `engines-r4.sh` and `rerun-r4.sh`, with their logs.
No `## Supersedes` section is added: this item is not yet published.

**`rs-launch-blueprint`'s optional `web` surface renders every non-2xx response —
domain failure, router miss, extractor rejection and blocking-bridge panic alike —
as one RFC 9457 `application/problem+json` document conforming to the org REST API
Design Standard v2.0.0 §5, built in `crates/web/src/problems.rs` by
`problem_details` 0.10.0 (`features = ["axum", "json"]`) typed as
`ProblemDetails<ProblemExt>`. Every document carries `type`, `title`, `status` and
`code`, where `code` is a snake_case identifier this item owns and publishes and
`type` is that code under a declared `https` base by the standard's fixed
template; R67's catalog token rides beside them as `catalog_code`, so one HTTP
error correlates with one CLI error. A domain failure's status comes from a free
`pub const fn http_status(ErrorCode) -> StatusCode` and its code from a free
`pub const fn http_code(ErrorCode) -> &'static str`, both proved total over
`ErrorCode::ALL` by tests; a framework failure keeps the status axum already
computed. The funnel is wired at axum's four extension points —
`impl IntoResponse for WebError`, `Router::fallback`,
`Router::method_not_allowed_fallback`, and newtype extractors whose
`type Rejection = WebError` — adding no Cargo feature, no `macros` feature, and no
crate beyond `problem_details` and its one transitive addition `http-serde`.**

**Ledger rows settled.** **F305** "single RFC 9457 error envelope for every
non-2xx response" (`docs/port/COMMONALITY.md:309`, `py-only` · `DIVERGENT`) and
**F306** "domain-error-to-HTTP-status mapping table" (`:310`, `py-only` ·
`DIVERGENT`). No `BASELINE-REVIEW:` line is raised: both rows are this item's own
`DIVERGENT` rows, not settled `COMMON → REUSE` or `ADOPT` rows, and R67 recorded
the trap of filing an answer under a review label
(`research/topics/67-error-and-exit-code-contract/DECISION.md:683-689`).

**This is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds
the template and its CI proves the recommendation. What P03 must validate is
listed under `## Engines`. A decision that does not survive implementation is
revised against this recorded research, not researched again from scratch.

**One stack — four members, one crate.**

| # | Member | What it is | Version |
|---|---|---|---|
| M1 | `problem_details` | the RFC 9457 document type and its axum `IntoResponse`, reached only from `crates/web/src/problems.rs` | **0.10.0**, `features = ["axum", "json"]` |
| M2 | Envelope contract `problem+json/v1` | the exact member set, media type and omission rules of the body | repository-owned contract, append-only |
| M3 | Domain-code-to-status table | `pub const fn http_status(ErrorCode) -> StatusCode` plus `NOT_REQUEST_REACHABLE` and a coverage test over `ErrorCode::ALL` | template code, no crate |
| M4 | Framework error funnel | `IntoResponse` + `fallback` + `method_not_allowed_fallback` + newtype extractors with `type Rejection = WebError` | template code, no crate |

M2, M3 and M4 are crate-agnostic: substituting a hand-rolled document struct for
M1 changes none of them. That is the escape hatch, and it is the answer to M1's
one real risk (below).

### The envelope contract — `problem+json/v1`

| Member | Source | Rule |
|---|---|---|
| `type` | RFC 9457 §3.1.1 · **R5.13.5 MUST** | **always present**, never `about:blank`. An absolute `https` URI under the base the deployment declares, bound to `code` by R5.13.1's fixed template `<https base>/<code, underscores to hyphens>`, so `resource_not_found` gives `…/resource-not-found`. Dereferencing it is a courtesy, never a contract (R5.13.3) |
| `status` | RFC 9457 §3.1.2 · **R5.13 MUST** | the numeric status, always present, always equal to the response's own status line |
| `title` | RFC 9457 §3.1.3 · **R5.13 MUST** | `StatusCode::canonical_reason()` — the analogue of py's `HTTPStatus(status_code).phrase` |
| `detail` | RFC 9457 §3.1.4 | present only when a public message exists; replaced by a fixed generic string when the W5 rule withholds it; never `null`; never echoes caller input (R8.12) |
| `instance` | RFC 9457 §3.1.5 | the request **path only**. `Uri::path()`, not the whole URI, because R5.17 bans a query fragment from every response body |
| `code` | RFC 9457 §3.2 extension · **R5.13 MUST** | **always present.** A snake_case identifier matching `^[a-z][a-z0-9_]*$` (R5.13.1), from `http_code(ErrorCode)`; this item owns the value space and R5.16 publishes it |
| `catalog_code` | RFC 9457 §3.2 extension | **always present.** R67's `ErrorCode::as_str()` token verbatim (`RSLB301`), the correlation field between this surface and the CLI's stderr envelope. Not a reserved name (R1.8) and snake_case (R4.4) |
| `documentation` | RFC 9457 §3.2 extension · **R5.13.4** | optional human documentation, omitted when absent. Human text lives here and never in `type` |
| `errors` | RFC 9457 §3.2 extension · **R5.15 SHOULD** | an **array**, omitted when absent, whose entries carry `pointer` (an RFC 6901 JSON Pointer to the offending input location), a stable machine-readable `code`, and a human-readable `detail` |

Media type `application/problem+json`, taken from
`JsonProblemDetails::CONTENT_TYPE` so the string exists once (verified in the
vendored 0.10.0 copy, `probe.log` section 6). Two omission rules, both inherited
from py and both enforced by serde rather than by convention: every optional
member carries `#[serde(skip_serializing_if = "Option::is_none")]` (py's
`exclude_none=True`), and no member is ever serialized as `null` — the same rule
R67 states for `hint`. The contract is **append-only**: a member may be added;
none may be removed, renamed or retyped without a new contract name.

Three consequences are deliberate rules rather than defaults:

1. **`type` and `code` are one pair; `catalog_code` is a second, differently
   purposed, string.** R5.13.1 makes `type` the normative identifier and `code`
   its short form, bound by a template, and R5.13.2 freezes both once published.
   That pair is this item's to own. R67's `RSLB` token cannot serve as `code`
   because it fails R5.13.1's grammar, so it rides as `catalog_code`. **Revision
   1's claim of "one identity string across both surfaces" does not survive the
   standard and is withdrawn**: the identity is R67's *catalog row*, rendered
   `RSLB301` by the CLI and `resource_not_found` over HTTP, with `catalog_code`
   carrying the CLI's spelling on the wire and R5.16's catalog publishing the
   mapping. The mapping is total, injective and grammar-checked by criterion `R4`,
   not asserted in prose. This is the answer to the question R69 revision 10
   handed this item
   (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1396-1399`).
2. **`hint` is not an HTTP member.** R67 defines `hint` as a CLI remediation line
   "rendered as its own line in human output". Its HTTP analogue is the
   `documentation` member R5.13.4 reserves for exactly that purpose, not a
   re-spelling of `hint`.
3. **py's `"type": "about:blank"` is not carried, and neither is revision 1's
   omission.** R5.13.5 bans `about:blank` outright and requires `type` to be
   present, so both the py shape and the revision-1 shape are nonconformant. The
   template URI replaces both.

### The catalog-to-`code` map, and the published catalog

R5.13.1 fixes the grammar and the template; this item fixes the seventeen values.
`pub const fn http_code(ErrorCode) -> &'static str` is an explicit match in R67's
own discipline — never derived from a variant identifier, so a rename cannot
silently change the wire — and `problem_type(code)` applies the template to it.

| R67 `catalog_code` | HTTP `code` | `type` (under the declared base) | status |
|---|---|---|---|
| `RSLB000` | `internal_error` | `…/internal-error` | 500 |
| `RSLB101` | `io_failure` | `…/io-failure` | 500 |
| `RSLB102` | `upstream_unreachable` | `…/upstream-unreachable` | 502 |
| `RSLB103` | `upstream_failed` | `…/upstream-failed` | 502 |
| `RSLB104` | `service_misconfigured` | `…/service-misconfigured` | 500 |
| `RSLB201` | `request_invalid` | `…/request-invalid` | 400, or the framework's own 422/400/415 |
| `RSLB202` | `service_config_unparsable` | `…/service-config-unparsable` | 500 |
| `RSLB203` | `service_config_invalid` | `…/service-config-invalid` | 500 |
| `RSLB204` | `service_secret_channel_invalid` | `…/service-secret-channel-invalid` | 500 |
| `RSLB205` | `input_unavailable` | `…/input-unavailable` | 500 |
| `RSLB301` | `resource_not_found` | `…/resource-not-found` | 404 |
| `RSLB401` | `credentials_absent` | `…/credentials-absent` | 401 |
| `RSLB402` | `credentials_rejected` | `…/credentials-rejected` | 401 |
| `RSLB501` | `conflict` | `…/conflict` | 409 |
| `RSLB901` | `interrupted` | `…/interrupted` | 500 |
| `RSLB902` | `terminated` | `…/terminated` | 500 |
| `RSLB903` | `prompt_interrupted` | `…/prompt-interrupted` | 500 |

**The names are proposals; the mechanism is verified.** Criterion `R4` proves the
map is total over `ErrorCode::ALL`, injective, and grammar-conformant; `R6` proves
every `type` is `https`, template-bound and never `about:blank`; `R23` proves the
R5.16 catalog is **generated from `ErrorCode::ALL`**, so it has one row per catalog
member by construction and cannot drift from the status table. An owner who
prefers different names changes seventeen string literals and nothing else.

**The base URI is a deployment setting, not a constant, and that is R5.13.1's
doing.** The rule requires `type` to sit "under a domain the provider controls".
A *template* has no provider domain, and shipping a placeholder would ship a
nonconformant default to every copy. **Recommendation: the problem-type base is a
required setting of the web surface with no default, and the serve binary refuses
to start without it** — which makes every copy conformant by construction. The
environment variable's name and its loading are **R77's** (`web-env-settings`), not
this item's; the fallback, if the owner prefers a softer failure, is a documented
placeholder that each copy must change, and that option is recorded rather than
taken. R5.13.6's URN alternative is not available: this template operates no
IANA-registered URN namespace.

### The domain-code-to-HTTP-status table

Every row is a **proposal** for P03; the *mechanism* is what this decision
verifies. The keys are R67's seventeen published catalog rows.

| R67 code | Meaning | HTTP | Ground |
|---|---|---|---|
| `RSLB301` | resource not found | **404** | py maps `ProjectNotFoundError`/`WorkspaceNotFoundError` to 404; R03 revision 1 states the same edge from the other side — "The web handler maps the same absence to HTTP 404 with no second translation site … R70 owns the status table" (`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/DECISION.md:168`) |
| `RSLB401` | credentials absent | **401** | py maps `AuthError` to 401 |
| `RSLB402` | credentials rejected | **401**, not 403 | RFC 9110 §15.5.2: "If the request included authentication credentials, then the 401 response indicates that authorization has been refused for those credentials." §15.5.4 reserves 403 for credentials the server "considers them insufficient to grant access" — an *authorization* failure R67's catalog does not yet name. Both sentences re-fetched and asserted (`registry.log`, section 6) |
| `RSLB501` | conflict / precondition failed | **409** | R67's exit 5 is "conflict/precondition failed" |
| `RSLB201` | usage/parse | **400** when a *domain* error raises it; **the framework's own status** (422 / 400 / 415) when a rejection raises it | the request extractor is the HTTP analogue of the CLI parser; see the two-status-sources rule below |
| `RSLB102`, `RSLB103` | transport, remote-API failure | **502** | py maps `APIError` to `HTTP_502_BAD_GATEWAY` |
| `RSLB000`, `RSLB101`, `RSLB104`, `RSLB202`, `RSLB203`, `RSLB204` | unexpected, I/O, config layer unreadable, config unparsable, config value invalid, secret via prohibited channel | **500** | py maps `ConfigError` to 500 and its `Exception` catch-all to 500. The config codes are 500 and never 4xx because in the web binary they describe *this process's own* configuration — a startup failure, not a request failure |
| `RSLB205`, `RSLB901`, `RSLB902`, `RSLB903` | prompting unavailable, SIGINT, SIGTERM, prompt interrupted | **500**, and listed in `NOT_REQUEST_REACHABLE` | no HTTP request can raise them; they get a row so the table is total and a named constant so the intent is recorded rather than buried in a catch-all |

**Two status sources, and why that is not a defect.** py has three
(`ERROR_STATUS.get(type(exc), 500)` for domain errors, `exc.status_code` passed
through for `StarletteHTTPException`, a hardcoded 422 for
`RequestValidationError`). This design has two: the table for a domain failure,
and `WebError::framework(status, code)` for a failure whose status the framework
already computed. Keeping axum's status is what preserves the 422-versus-400-
versus-415 distinction axum has already made — information a single table row
would discard.

**The mechanism, and why it is not a `match`, a trait method or a derive.**
`ErrorCode` is `#[non_exhaustive]` and lives in another crate, so a match in
`crates/web` **cannot** be exhaustive and needs a `_ =>` arm. R67 anticipated
exactly this consumer and supplied the compensation: "R70's status table is
coverage-tested by iterating `ErrorCode::ALL` and asserting every member maps, so
totality is enforced by a failing test instead of by the compiler"
(`research/topics/67-error-and-exit-code-contract/DECISION.md:148-153`; resolution
at `:653-662`). This decision adopts that unchanged and **verified it in both
directions**: with the enum in the same crate the `_` arm drew
`warning: unreachable pattern … no value can reach this`; with the enum behind a
crate boundary the identical arm compiled silently (`probe.log`, section 5). A
trait method **defined in `crates/core`** was rejected on layering — it would put
`http::StatusCode` in `crates/core`, which `crates/cli` also depends on under R02's
topology. A trait defined in `crates/web` and implemented there for R67's type
avoids that objection; it is the Muse report's proposal and is adjudicated as
Disagreement 3 under `## Engines`. A derive was rejected on R67's own ground: "A
variant rename is a compiler-checked, silent refactor in Rust — which is exactly
why a derived code is dangerous" (`…/67-…/DECISION.md:136`).

### The funnel, and the two header obligations it must not drop

| py source | py handler | Rust analogue | Mechanism |
|---|---|---|---|
| `PyError` | `handle_py_error` | a handler returning `Err(WebError)` | `impl IntoResponse for WebError` |
| `StarletteHTTPException` | `handle_http_exception` | a router-level miss | `Router::fallback` (404) and `Router::method_not_allowed_fallback` (405) |
| `RequestValidationError` | `handle_validation_error` | an extractor rejection | a newtype extractor whose `type Rejection = WebError`, preserving `rejection.status()` and `rejection.body_text()` |
| bare `Exception` | `handle_unexpected_error` | a panic in R05's blocking bridge | `tokio::task::JoinError` → `RSLB000`/500 |

The hook that reshapes the framework's own validation body is the extractor's
associated `Rejection` type — about ten lines per input extractor family
(`Json`, `Query`, `Path`), and **no `macros` feature**, which matters because
R69's owned `web-extra-surface` value does not enable it and this item does not
own that value. `#[derive(FromRequest)]` would give the same behaviour in fewer
lines and becomes the recommendation the moment R69 enables `macros` for another
reason. `axum_extra::extract::WithRejection` was not taken: it adds a crate, it
changes the handler signature, and R69 records `axum-extra` as an open hand-off
(`…/R69/…/review/DECISION.md:214`).

Two RFC 9110 obligations survive the envelope, and both were executed rather than
assumed:

- **`Allow` on a 405.** RFC 9110 §15.5.6: "The origin server MUST generate an
  Allow header field in a 405 response containing a list of the target resource's
  currently supported methods." axum sets it before the fallback renders and it is
  still present after `method_not_allowed_fallback` replaces the body — asserted
  as `Allow: GET,HEAD` on a `DELETE` against a `GET`-only route.
- **`WWW-Authenticate` on a 401.** RFC 9110 §15.5.2: "The server generating a 401
  response MUST send a WWW-Authenticate header field (Section 11.6.1) containing
  at least one challenge." `WebError` carries `headers: Vec<(HeaderName, HeaderValue)>`
  with a `with_header` builder, and `IntoResponse` inserts them after the body is
  rendered. **The challenge string itself is not this item's** — no P02 item
  selects an authentication scheme — so this item supplies the mechanism and
  records the obligation for whichever item lands auth.

### Conformance to the REST API Design Standard v2.0.0

Every rule below is quoted from the pinned blob and asserted **at its line** by
`review/evidence/rest-r2.sh` (group A, 63 checks); the conformance verdicts are
asserted by `review/evidence/probe-r2.sh` (25 checks, of which criteria `R1`–`R24`
are one). "N/A" carries a reason, because R1.6 (`:232`) makes a reasonless N/A a
deviation rather than an exemption.

| Rule | Line | Strength | What it requires | Verdict |
|---|---|---|---|---|
| R5.1 | `:916` | MUST | the status matches the outcome; a failed operation never returns 2xx | **conform** — `R15`, `R24` |
| R5.2 | `:934` | MUST | no unregistered status codes | **conform** — the nine statuses used (400, 401, 404, 405, 409, 415, 422, 500, 502) are all IANA-registered; `R1` bounds the table to 4xx/5xx |
| R5.3 | `:939` | SHOULD | 422 for well-formed-but-invalid, 409 for state conflicts, 400 for malformed syntax | **conform** — and it is axum's own rejection split, not a re-implementation: `R11` (422), `R12` (400), `R23`'s `RSLB501`→409 |
| R5.4 | `:948` | SHOULD NOT | 410 only with recorded permanence | **N/A** — no catalog row maps to 410 and this item defines no tombstoning |
| R5.5 | `:956` | MUST | 307/308 where method and body survive a redirect | **N/A** — this item emits no redirect; no 3xx appears in the table |
| R5.6 | `:966` | MUST | creates return 201 with `Location` | **N/A to this item** — success statuses belong to the route items (R69/R71); this item governs non-2xx only |
| R5.7 | `:975` | — | DELETE returns 204 | **N/A to this item** — same reason |
| R5.8 | `:985` | MUST | partial bulk returns 200 with the per-item envelope | **N/A** — switch `bulk-operations` is off |
| R5.9 | `:994` | MUST NOT | 401 and 403 never conflated | **conform** — `RSLB401` (credentials absent) and `RSLB402` (credentials rejected) are both *unauthenticated* and map to 401; the catalog names no authorization failure, so 403 is **unused rather than conflated**. `R16` |
| R5.10 | `:1000` | — | an object-level authorization denial defaults to 404 | **N/A today, binding tomorrow** — no P02 item implements authorization. Recorded as a requirement on whichever item does: the masking 404 is `resource_not_found`/`RSLB301`, the same row `R7` exercises |
| R5.11 | `:1008` | MUST | 405 carries `Allow`; 415 answers an unsupported request media type; 428 where `If-Match` is demanded | **conform on the first two** — `R10` asserts `Allow: GET,HEAD` survives the envelope, `R13` asserts the 415. **428 N/A** — this item defines no conditional operation; §7.3 and R3.11 are not its |
| R5.12 | `:1019` | MUST | every application-generated error servable as `problem+json`; the infrastructure carve-out documented | **conform, and exceeded** — every non-2xx is problem+json unconditionally rather than on request (`R24`). The carve-out is documented in the conformance note below |
| R5.13 | `:1049` | MUST | `type`, `title`, `status`, `code`; template binding; grammar; immutability; no `about:blank`; `documentation` separate | **conform — this is move M-1, M-2 and M-5.** `R4` (grammar, totality, injectivity), `R6` (template, https, no `about:blank`), `R7` (the full member set on a real response), `R22` (`documentation`). Revision 1 **violated point 5** |
| R5.14 | `:1098` | MUST NOT | RFC 7807 never cited, except in a note explicitly labeled historical | **conform** — this decision cites RFC 9457 throughout. The two places RFC 7807 is named are labeled historical: this row, and the R73 coupling below, which records that an IETF draft still cites the obsoleted RFC |
| R5.15 | `:1105` | SHOULD | field failures carry `errors[]` with JSON Pointers | **conform — this is move M-3.** `R11` asserts the array shape and the `pointer`/`code`/`detail` entries |
| R5.16 | `:1114` | MUST | a published catalog of every `type`/`code` pair | **conform — this is move M-5.** The catalog is *generated* from `ErrorCode::ALL` (`R23`), so it cannot drift. Its publication surface is R81's; its content is this item's |
| R5.17 | `:1120` | — | no stack traces, query fragments, internal hostnames or dependency detail | **conform** — `R8` (host and token withheld), `R14` (panic text withheld), `R19` (**`instance` carries the path only**, so a query fragment cannot reach the body) |
| R8.12 | `:1422` | MUST NOT | secrets, credentials and PII never in `detail`, in echoed input, or anywhere | **conform — this is move M-4**, and it is the rule revision 1 would have broken. `R18` is the executed proof that an offending request value is not echoed |
| R4.3 | `:762` | MUST | an object at the top level | **conform** — `R21` |
| R4.4 | `:768` | MUST | snake_case body properties, `^[a-z_][a-z_0-9]*$` | **conform** — `R21` checks every member name on nine distinct bodies, including the `errors[]` entries' fields |
| R4.8 | `:818` | MUST | the contract states how null and omission differ | **conform, and stronger** — no member is ever `null`; absent means omitted. `R21` |
| R4.5, R4.6, R4.7, R4.9, R4.16 | `:792`, `:798`, `:804`, `:826`, `:779` | — | identifiers as JSON strings; RFC 3339 timestamps; no floating-point money; enum additions documented non-breaking; path placeholders | **N/A** — the body carries no timestamp, monetary amount or path placeholder; `code` and `catalog_code` are already JSON strings; R4.9 is discharged by the append-only contract plus the generated R5.16 catalog |
| R4.10 | `:846` | *no BCP 14 keyword* | default media type `application/json`; no `format` parameter; 406 for an unsatisfiable `Accept` | **conform; no deviation to record.** The standard rules at `:2218` that this clause "carries no BCP 14 keyword", and R1.1 (`:128`) binds only all-capitals keywords. R5.12 (`:1035`) contemplates this exact design. No `format` parameter exists; 406 is a SHOULD this item does not reach, since it negotiates nothing |
| R4.11 | `:856` | MUST | `Vary` on any response whose content a request header selected | **conform through its own exception** (`:858`, "responses with no negotiation") — nothing here is selected by a request header |
| R4.12–R4.15 | `:880`–`:899` | SHOULD/MAY | structured header fields, registered link relations, URI templates, `Prefer` | **N/A** — this item defines no new header, expresses no link relation, describes no URI family and supports no `Prefer` |
| R4.17 | `:864` | MUST | cross-origin responses list standard-bound headers in `Access-Control-Expose-Headers` | **N/A to this item, binding on R76** — this envelope's error path emits `WWW-Authenticate` and `Allow`, and R75/R74 add `request-id` and `Retry-After`; **R76 must expose all of them** or a browser client cannot read them |
| R1.6 | `:229` | MUST | switches declared, each "off" with a reason | **conform** — declared in the conformance note below |
| R1.7 | `:271` | MUST | no silent deviation | **conform** — no deviation is taken; the one candidate (R4.10) is shown above not to bind |
| R1.8 | `:312` | MUST NOT | a reserved name never repurposed | **conform** — the nine members are RFC 9457's five plus `code`, `catalog_code`, `documentation` and `errors`; the standard itself registers `code`, `documentation`, `errors` and `pointer` with these meanings, and `catalog_code` is not a reserved name |
| R1.9 / R13.3 | `:318` / `:339` | MUST | `dry_run` (and `stream`) to an endpoint that does not implement it is rejected with 400 | **conform — this is J7.** These bind **per endpoint even with every switch off** (`:258`). `R20` executes all three forms; the guard's *placement* is R75's |
| R12.6, R12.7 | `:1815`, `:1819` | SHOULD / MUST NOT | client obligations | **N/A** — client-side rules; recorded because R12.7's "branch on the status first" is what makes R5.12's infrastructure carve-out survivable, and this template ships no client |

**Conformance note fragment**, in R1.9's template shape (`:279`). This item owns
only the error half; the API-level note has **no P02 owner**, which is recorded
below as an owner question.

```markdown
## Conformance note — rs-launch-blueprint web surface (error responses)

Standard: rest-api-standard v2.0.0
Tier: internal            (a template's default; each copy re-declares)
Switches: webhooks=off, async-operations=off, bulk-operations=off, streaming=off
  webhooks=off          — no P02 item defines a webhook surface
  async-operations=off  — no P02 item defines an operation resource
  bulk-operations=off   — no P02 item defines a bulk endpoint
  streaming=off         — R69's accepted surface serves whole JSON documents;
                          no route streams
Context: single-tenant by default; no PII in the shipped example domain; the
  audience is the developer copying the template. Errors emitted by
  infrastructure in front of the application — a reverse proxy, a load balancer,
  or the platform's own 502/503 before the process is reached — are outside
  application control and are NOT problem documents (R5.12's first carve-out).

Deviations:
- (none)

N/A declarations:
- R5.4, R5.5 · no 410 row and no redirect in the error map
- R5.6, R5.7 · success statuses belong to the route items, not to this one
- R5.8 · bulk-operations=off
- R5.10 · no P02 item implements authorization; the masking 404 is
  `resource_not_found`/`RSLB301` when one does
- R5.11 (428 limb) · no conditional operation is defined
- R4.12–R4.15 · no new header, link relation, URI template or Prefer support
- R4.17 · this item emits the headers; R76 owns the CORS exposure list
- R12.6, R12.7 · client-side obligations; this template ships no client
```

### Judgements carrying the weight

Separated so a reviewer can accept or reject them independently.

| # | What is decided | Force | Ground |
|---|---|---|---|
| J1 | RFC 9457 rather than a house shape | **Recommended, and checked against a counter-example** | The RFC is an IETF Proposed Standard on the IETF stream with both media types IANA-registered citing RFC 9457 (`registry.log`, section 5, where the registry spelled it `[RFC9457]` on 2026-09-18; on 2026-09-27 it spells it `[RFC 9457]`, asserted in `rerun-r4.log`); ISRG's `divviup/janus` declares `http-api-problem = "0.60.0"` in its workspace manifest (re-fetched, `registry.log` section 7). Against: Oxide's `dropshot` ships a bespoke `HttpErrorResponseBody { request_id, error_code, message }` and no problem+json (re-fetched, same section). Its three ideas map onto this design without contradiction — its `error_code` is this design's `code`, its `message` this design's `detail`; the disagreement is about the wrapper, not about what a client needs |
| J2 | Take `problem_details` 0.10.0 rather than hand-roll the ~50-line struct | **Recommended, and the closest call in this decision** | Measured: one added crate in the resolved tree (`http-serde` v2.1.1 — executed as a tree diff against a control member with the identical dependencies minus `problem_details`, `probe.log` section 4); declared `rust-version = "1.85"` against a 1.96 floor; `#![forbid(unsafe_code)]`; no RustSec page; a `utoipa` `ToSchema` derive already on the struct for R71. Against: **bus factor 1** — 10 stars, 1 subscriber, 1 maintainer. Answered structurally, not verbally: the crate is named only from `crates/web/src/problems.rs`, so the replacement is a struct behind an unchanged module surface |
| J3 | `code` is a snake_case value space this item owns, with R67's token beside it as `catalog_code` | **Forced by R5.13.1's grammar, then chosen among three conforming shapes** | `RSLB301` fails `^[a-z][a-z0-9_]*$`, so it cannot be `code`. Three shapes conform: (a) this one; (b) `code: "rslb301"`, a mechanical lowercasing — **ranked runner-up**, rejected because it makes `type` URIs and the R5.16 catalog opaque and tautological, and the standard's own worked example (`…/validation-failed`, `code: validation_failed`) is semantic; (c) an `OVERRIDE` keeping `RSLB301` verbatim — rejected because the deviation is **not needed**, and R1.7 makes an unnecessary recorded exception a cost with no benefit |
| J7 | The two per-endpoint reserved-parameter guards are this envelope's to render | **Forced** | R1.6 (`:258`) states that "a switch never waives a guard" and that R1.9 and R13.3 bind **per endpoint**, not per API. A mutating request carrying `dry_run` — or a request carrying `stream` — to an endpoint that does not implement it MUST be rejected with `400` (R1.9, `:318`), and that rejection is an error response, so it is this envelope. Criterion `R20` executes all three forms. Where the guard *lives* (middleware or handler) is R75's |
| J4 | The table is a free `const fn` over `ErrorCode`, not an inline `match` in `into_response` | **Recommended, on testability** | A table inside a response method cannot be called by a test iterating `ErrorCode::ALL` without building a `Response` per code. The three coverage tests here are plain `#[test]` functions with no runtime, no router and no request |
| J5 | No content negotiation; JSON only | **Recommended, on scope** | R69's accepted surface has no templating, static assets or HTML route, and R69 revision 10 records templating as having "No P02 item; pending owner scoping". Adding negotiation would settle a scoping question this item does not own. `impl IntoResponse for WebError` is the single place a later item adds it |
| J6 | The individual status rows | **Proposals the owner may revise without touching anything verified** | Calibrated against py's five mappings and R67's exit semantics. The twenty-four executed criteria, `R1`–`R24`, prove one envelope can cover domain, router, extractor and panic failures at these versions on a supported OS; they do not prove that `RSLB102` should be 502 rather than 504 |

**W5 — the disclosure rule, and the real opposition it resolves.** The config
items require the *opposite* of redaction for a terminal user (R55's "the warning
names the file and the key"; the org CLI Design Standard's R7.6 "name the
offending input in quotes"). Over HTTP a server-side path or config key **is** an
internal disclosure. The rule that satisfies both is not a compromise: the full
message is produced exactly as the CLI items require and written to the log, and
`detail_is_public(code)` decides whether that same text reaches the client.
`WebError::log_detail()` exists for that split. The mechanical enforcement is a
test — **no code whose status is 5xx may be marked detail-public** — executed here
as `R3` (`probe-r2.sh:914`; revision 1's `AC3`).

### Corrections to `raw/opus.md`

This decision is synthesized from **two** engine reports, Opus and Muse (see
`## Engines`). Only the Opus report executed anything: every check in the Muse
report is marked "Proposed, not executed" (`raw/muse.md:37`). The Opus report's
load-bearing claims were therefore re-checked at source, and they are the ones
corrected here. Three things were found wrong or unreproducible; everything else
reproduced. The Muse report's divergent positions are adjudicated under
`## Engines`, not here.

| # | The report's claim | What the source says | Effect |
|---|---|---|---|
| C1 | The envelope table cites **§3.1.2 for `title`** and **§3.1.3 for `status`** (`raw/opus.md:737-738`) | RFC 9457 numbers them the other way round: §3.1.2 is `"status"` and §3.1.3 is `"title"`. Asserted line-by-line for all five members (`registry.log`, section 5) | **Corrected above.** No behavioural effect — the member names and rules are unchanged |
| C2 | "R69 records `axum-extra` as an open hand-off (`…/R69/…:2342`)" | Line 2342 of R69 revision 10 is about the `bacon` dev watcher. The `axum-extra` hand-off is at **`:214`** (Disagreement 3, row 10); R69's own change table at `:97` is what carries the stale `2342` | **Corrected above** to `:214`. The substance — `axum-extra` is R69's open hand-off — is confirmed |
| C3 | "exactly one: `http-serde` 2.1.1 … (executed: `cargo tree -p problem_details --edges normal`)" | True, and now proved a stronger way. `cargo tree -p problem_details` shows that crate's own subtree, which cannot by itself show what is *added* to a tree that already has axum. The check here diffs the resolved trees of two workspace members differing only in `problem_details` | **Method strengthened, conclusion unchanged**: `http-serde v2.1.1` and `problem_details v0.10.0`, nothing else |

Two smaller notes, neither a correction: the report renders
`problem_details` 0.10.0's `created_at` as `2026-08-16T14:36:14Z` where crates.io
returns `2026-08-16T14:36:14.921547Z` (truncation, not error); and the probe here
emits `"instance":"/upstream"` on the 502 where the report's captured body has no
`instance` — a difference in how the two probes wired one handler, not in the
contract, which makes `instance` optional.

**What reproduced exactly.** Every registry figure the decision rests on, on the
same UTC day: 90-day downloads 38,904; all-time 142,723; newest non-yanked 0.10.0
at 2026-08-16; `rust_version` 1.85; 10 stars, 1 subscriber, 1 open issue; repository
pushed 2026-09-12T12:31:02Z; `http-api-problem` and `http-problem` declaring
`rust_version` on **zero** published versions; `http-problem` 0.3.0 requiring
`http ^0.2.8` and `axum ^0.6`; RustSec 404 for all five crates and 200 for `http`
with both 2019 advisories patched in `>= 0.1.20`; upstream CI ubuntu-only with a
1.85 MSRV job. And all four response bodies the report captured came back
**byte-identical from an independently written probe**, down to the 422's
`"… invalid type: integer \`42\`, expected a string at line 1 column 11"`.

### Couplings

- **R67 `error-and-exit-code-contract`** (published, sha256 `16947ab1…`) — consumed.
  This item maps R67's seventeen catalog rows onto statuses and codes, carrying
  `ErrorCode::as_str()` verbatim as `catalog_code` beside the owned snake_case
  `code` (M-2). **No `CONFLICT:` is raised**, and the
  pressure point is named rather than hidden: R67's catalog, written for a CLI, has
  no code meaning "the client's request body failed validation". The resolution is
  py's own structure — a framework rejection keeps axum's status and carries
  `RSLB201` — so `RSLB201` names one thing ("the caller's input was not usable")
  while 422, 400 and 415 distinguish *how*. Asking R67 to append
  `RSLB206 request payload invalid` is a legitimate future append against an
  append-only catalog and would cost one table row and no redesign; it is recorded
  as a documented option and a re-verify trigger, not as a needed change.
- **R69 `web-framework-stack`** (owner-accepted at revision 10, unpublished) —
  related, not a registry dependency. It fixes axum 0.8.9, tokio 1.53.1 and tower
  0.5.3, names `problems.rs` as this item's file (`…:1615`), and hands this item the
  `code` question answered at J3. See `## Parameters` for why it is not an
  `- assumes` line and what its republication changes.
- **R03 `port-absence-vs-failure-contract`** (revision 1, sha256 `610e3338…`) —
  absence is `Ok(None)` and the use case constructs `DomainError::NotFound`; this
  item's 404 row is the HTTP half of R03's AC10, which R03 explicitly assigns here.
- **R02 `crate-boundary-enforcement`** (revision 2, sha256 `9e8f8e8c…`) — the
  four-package workspace with `crates/web` depending on `core` only (`:29`) is why
  the table and the `ProblemSource` trait live in `crates/web` and not in `core`.
- **R05 `sync-async-execution-model`** (revision 3, sha256 `3ca4b81a…`) — the
  synchronous core reached through `tokio::task::spawn_blocking` is why
  `JoinError` is a funnel source and why AC11 exists.
- **R77 `web-env-settings`** (not researched) — **new under W2-REST.** R5.13.1
  requires `type` to sit under a provider-controlled domain, and a template has no
  provider. The problem-type base URI is therefore a required setting of the web
  surface with no default. R77 names the environment variable and owns its
  loading; this item owns only the requirement and the consequence, which is that
  the serve binary refuses to start without it.
- **R71 `openapi-generation-pipeline`** (not researched) — must document this
  envelope, and now has a fixed shape to document: R5.13's four required members
  plus this item's four extensions. The standard's own OpenAPI checklist (`:2892`)
  requires "a shared problem schema under `components.schemas`" with 4xx/5xx
  responses keyed by `application/problem+json`. Recorded affordance, not a
  decision for R71:
  `problem_details` carries `#[cfg_attr(feature = "utoipa", derive(utoipa::ToSchema))]`
  with `schema(inline)` on the extensions field (vendored 0.10.0
  `src/problem_details.rs:117,170`, both asserted here).
- **R75 `http-middleware-stack`** (not researched) — the one gap in W3's coverage.
  Middleware-originated errors and panics outside the blocking bridge are R75's
  and were not exercised. The rule R75 inherits: any layer added to the stack must
  render its own rejection through `WebError`, and the enforcement is a route-walk
  test that also asserts the RFC 9110 header obligations, because a layer can strip
  a header as easily as a body. **Three
  further obligations reach R75 under W2-REST**: §1.10 (`:348`) reserves
  `request-id` as a response header "emitted on every response **including
  errors**", so the error path must not drop it; §7.2 (`:1281`) sets the caching
  posture, and the standard's own error examples carry `Cache-Control: no-store`;
  and R1.9's `dry_run` guard is naturally a layer rather than a per-handler check,
  which is why criterion `R20` proves the *behaviour* here and leaves the
  *placement* to R75.
- **Stated as couplings, decided here only where this item owns the answer.**
  None of these items contradicts this envelope. **R80** is resolved: its
  published revision 6 (`research/topics/80-health-probe-endpoints/DECISION.md`)
  has `/readyz`'s 503 reuse this envelope, requires its diagnostic report to be
  reachable from that response, names three ways to satisfy that, and states
  "R70 owns the choice" (`:859-865`). **This item's choice is a `diagnostics`
  extension member**, appended by R80's `/readyz` route under
  `problem+json/v1`'s append-only rule; the nine-member base this item ships is
  unchanged. It is present only on `/readyz`'s 503 and omitted everywhere
  else, and it is never `null`. The report it carries, and that report's R5.17
  redaction, are R80's (`:1007`). The rationale, and why the other two ways fail
  this decision's own rules, is under `## Engines`, "The `/readyz` diagnostic
  carrier"; **R72** hands this item a pagination rejection type and records that
  axum's `Query` rejection today is `text/plain` and "neither RFC 9457 nor R67's
  envelope" (`…/R72/…/raw/opus.md:277,903-905`); **R73** hands over five bodies
  (400 / 409 / 413 / 422 / 503) and notes the IETF idempotency draft still cites
  RFC 7807, which RFC 9457 obsoletes (`…/R73/…/raw/opus.md:1226-1232`); **R74**
  renders its 429 through this envelope and has **no catalog code** — R67 has no
  rate-limit row, and that gap is R74's to raise, not this item's
  (`…/R74/…/raw/opus.md:146,407`) — under R5.16 that gap is now sharper, because a
  429 needs a published `type`/`code` pair and the standard's own example names
  `rate_limit_exceeded` (`:3205`); **R76** records this item as unaffected by CORS
  (`…/R76/…/raw/opus.md:706`), which W2-REST reverses in one direction only: R4.17
  makes R76 responsible for exposing the headers this error path emits.

  On R73's note that the IETF idempotency draft still cites RFC 7807 — recorded
  here as a **historical note, explicitly labeled as such** under R5.14's own
  exception (`:1099`) — the standard agrees: RFC 9457 obsoletes RFC 7807 and this
  envelope is the current shape.
- **C4 validation ownership is unresolved and is deliberately left to the owner.**
  R69 revision 10 records C4 validation as "No P02 item; pending owner scoping"
  (`…/R69/…:2400`); R53 revision 2 says the opposite — "if the web surface wants
  request validation, that is R69/R70's decision and `garde` is a live candidate
  there". Both are owner-accepted and unpublished. This decision takes no position:
  `errors` is defined producer-agnostically, so whichever reading wins, a chosen
  validator's field report fills the same member through the same
  `type Rejection = WebError` hook, with no redesign.

### Principles and implementation

**The shared requirement.** A caller must be able to handle *any* failure of this
service without knowing which layer produced it: one media type, one member set,
one place to read the machine identity. The source is py, which states the
requirement in its own module docstring — "EVERY non-2xx response body is an
``application/problem+json`` document with the same shape, including FastAPI's own
422 validation errors and bare ``HTTPException``s"
(`py src/py_launch_blueprint/web/problems.py` at pin `b08bccfb`) — implemented by
four handlers registered in `install_problem_handlers`. ts contributes nothing: it
has no web service, no dependency and no decision entry
(`docs/port/areas/web-service.md:98-100`). The verdict is `DIVERGENT` on a
one-sided precedent, which is why the research mandate (spec §2, owner amendment
A5) rather than the precedent decides the Rust shape.

**Agreement levels — what must agree and what may vary.**

| # | Principle | Agreement level | Must agree | May vary |
|---|---|---|---|---|
| W1 | Every non-2xx response carries one media type and one member set | **standard** (RFC 9457) | `application/problem+json`; the RFC's member names for the members present | whether absent members are omitted or spelled out |
| W2 | Every non-2xx response carries the failure's stable machine identity | **standard, shared with R67; now also R5.13** | that one catalog row is identifiable from the body. Under R5.13 the HTTP identity is the `type`/`code` pair this item owns, and R67's token rides beside it as `catalog_code`, so the CLI's `RSLB301` and the API's `resource_not_found` name the same row | which member carries which spelling; whether a deployment points `type` at published documentation |
| W3 | Every layer's failure — domain, framework, extractor, panic — goes through one funnel | **architectural pattern** | that no code path can emit a non-2xx body that bypassed the funnel | how many extension points the ecosystem needs to reach that |
| W4 | A domain failure's HTTP status is a reviewable table, not scattered literals | **architectural pattern** | one place, total over the published catalog, tested | `match`, trait method, or derive |
| W5 | A failure message never discloses server internals to a client | **policy** | which classes are withheld, and that the full text is still logged | the wording of the substitute |

W1, W2 and W5 are inherited from py; W3 and W4 restate py's structure so a Rust
implementation can be judged against them rather than against FastAPI's mechanics.
W4 is also **stronger than py**: py's `ERROR_STATUS: dict[type[PyError], int]` has
no completeness test, so a new `PyError` subclass silently falls to
`ERROR_STATUS.get(type(exc), 500)`.

**Observable acceptance criteria.** Revision 1 re-ran the raw report's fourteen
criteria and added two, `AC1`–`AC16`, all passing; `probe.log` is carried
byte-identical and is **not** re-run, because those criteria bind revision 1's
envelope. Revision 2 states its own twenty-four, `R1`–`R24`, in
`review/evidence/probe-r2.sh`, and all twenty-four pass at the 1.96 MSRV floor and
on the host toolchain. Thirteen carry revision 1's behaviour forward unchanged
(`R1`–`R3` the table's totality, redaction and the unreachable rows; `R7`–`R10`
and `R12`–`R17` the four funnel sources, the `Allow` and `WWW-Authenticate`
obligations, the 2xx pass-through and the blocking-bridge panic). **Eleven are new
and exist because of the standard**: `R4` the `code` map is total, injective and
matches `^[a-z][a-z0-9_]*$`; `R5` checks the `catalog_code` token shape (`RSLB`
prefix, length 7) across `ALL`, while verbatim-ness holds by construction
(`catalog()` inserts `code.as_str()` directly) and is executed by `R23`
(`catalog_codes_unique 17`, `rslb_ok`) and on real bodies by `R7`/`R8`; `R6`
every `type` is `https`, template-bound and never `about:blank`; `R11` `errors` is
an array of `{pointer, code, detail}`; `R18` no offending request **value** is
echoed into the body; `R19` `instance` carries no query fragment; `R20` the
`dry_run` and `stream` guards answer 400 through this envelope; `R21` every member
name on every body is snake_case, every body is an object at the top level and no
member is ever `null`; `R22` `documentation` is omitted when absent and present
when set; `R23` the R5.16 catalog is generated from `ErrorCode::ALL` and covers
every row; and `R24` every failing request answers `application/problem+json`
carrying a `type` and no `about:blank`. The superseded revision-1 sentence is kept
here for the record: it read that AC8 renders 422 "with the field detail under
`errors.body`", which M-3 and M-4 have both replaced. Revision 1's AC16 walked
twelve requests asserting every failing one answers `application/problem+json` and
every 2xx does not.

**Architectural alternatives, compared before any library was chosen.**

| Alt | Shape | Verdict |
|---|---|---|
| **B1** | **One RFC 9457 envelope for every non-2xx, conforming to REST standard §5: template-bound `type`, owned snake_case `code`, R67's token as `catalog_code`, status from a table keyed on `ErrorCode`** | **Chosen.** The only shape that preserves W1–W5 *and* satisfies R5.13 without a recorded deviation |
| B2 | Mirror R67's CLI envelope verbatim over HTTP: `{"error":{"code","message","hint"?}}` | Rejected. Not RFC 9457, so W1 fails and R71 publishes a house schema; and it reuses a *stderr process* contract as a *wire* contract, which R69 revision 10 warns is a different thing (`…/R69/…:1393-1394`: "R67's envelope is the CLI process's stderr contract, not an HTTP response body") |
| B3 | RFC 9457 with the identity in `type` only, no `code` member | **Rejected, and now forbidden.** R5.13 makes `code` a MUST beside `type`, so this is no longer an available shape; revision 1 kept it as an optional addition and revision 2 withdraws that |
| B4 | Per-handler ad-hoc bodies, no single funnel | Rejected. It is what a framework gives for free and is exactly the defect py's module exists to prevent; W3 fails by construction |
| B5 | Content-negotiated envelope: problem+json for `Accept: application/json`, HTML otherwise (the owner reference's C4) | Rejected for this template (J5) |
| B6 | Map the status inside `into_response` with an inline `match` (the owner reference's wiring block) | Rejected (J4) |

**Is the shared pattern still appropriate in Rust?** The check is not rhetorical.
Against: the first-party tier offers no help — the vendored sources of `axum`
0.8.9, `axum-core` 0.5.6, `tower` 0.5.3 and `hyper` 1.11.1 contain **zero**
case-insensitive matches for `problem+json` (asserted, `probe.log` section 6) — and
Rust's most visible single-org HTTP framework ships a bespoke body. For: an IETF
Proposed Standard with registered media types; a well-regarded Rust service at
ISRG using it; a template whose purpose is to be copied, where a documented
standard beats a house shape; and R71 must publish a schema for the error body
either way, so a standard shape is the one a generated client already understands.
**Keep the pattern.**

**The prompt's LOW question — does a published template or style guide name
this pattern?** No published Rust web-service template was found that names a
"one envelope for every non-2xx response" policy. That is the Muse report's
stated negative result, retrieved 2026-09-25 ("No published Rust template found
that names a 'one envelope for every non-2xx response' policy verbatim",
`raw/muse.md:19`), and the Opus report does not address the question. The
adopting projects cited under J1 (`divviup/janus`, `oxidecomputer/dropshot`) are
practice evidence, not templates or style guides. One style guide does require
the pattern: the org REST API Design Standard v2.0.0, R5.12 (`:1019`), requires
every application-generated error to be servable as `application/problem+json`,
and owner ruling W2-REST makes that standard bind this template.

**The landscape, and the one fact that decides how to weigh it.** The category has
four RFC 9457 crates and **no dominant one**: the largest by all-time downloads
(`http-api-problem`, 62 stars) has had no release since 2025-01-06 and declares no
`rust_version`; the most actively maintained (`problem_details`) has 10 stars.
There is not enough adoption in this category to discriminate, which is why the
fitness gates and the executed check carry the decision rather than popularity.

**Fitness gates, per candidate, before popularity.**

| Gate | `problem_details` 0.10.0 (recommended) | `problemdetails` 0.7.0 (runner-up) |
|---|---|---|
| 1 — licence | `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` | same ruling, same disposition |
| 2 — MSRV | **Pass.** Declares `rust-version = "1.85"`; current stable is 1.98 (`channel-rust-stable.toml`, `date = "2026-09-03"`), so the floor is 1.96 and 1.85 ≤ 1.96. Executed: the probe declared `rust-version = "1.96"`, Cargo reported `Locking 56 packages to latest Rust 1.96 compatible versions`, **and the whole workspace compiled and its sixteen tests ran under rustc 1.96.0** | **Pass.** Declares `rust-version = "1.85.1"` |
| 3 — advisories and `unsafe` | **Pass.** `https://rustsec.org/packages/problem_details.html` returns 404, as does `http-serde`; `#![forbid(unsafe_code)]` at `src/lib.rs`, so the compiler rejects `unsafe` outright | **Pass.** RustSec 404 |
| 4 — OS matrix | **Pass, with the gap recorded.** Upstream CI is `ubuntu-latest` for every job and has **no macOS runner**; macOS is covered here by execution instead — macOS 26.4, `aarch64-apple-darwin`, sixteen tests passing. Windows: untested, not required | not separately executed |
| 5 — default features, runtime coupling | **Pass.** Defaults `["serde", "json"]`; this template adds `axum` and keeps them. **No async-runtime coupling** — the crate names no runtime, and its axum dependency is `{ version = "0.8", default-features = false, features = ["json"] }`, so it does not widen R69's owned feature list (asserted from the crates.io dependency endpoint) | pulls `serde_json/preserve_order`, dragging `indexmap` in for a property this envelope does not need |
| 6 — binary size, compile cost | **Pass.** Adds exactly one crate to a tree that already has axum, serde and serde_json: `http-serde` v2.1.1, whose only dependencies are `http` and `serde` (executed tree diff). All of it sits behind R69's optional member, so none reaches a default build | comparable |

**Excluded by gate.** `http-api-problem` 0.60.0 — **fails gate 2**: zero of its
published versions declare `rust_version` (asserted). Recorded against the
exclusion because it is the strongest candidate on every other axis: the highest
adoption in the category, in production at ISRG, `axum-core ^0.5.0` current for
axum 0.8, no advisory. Its maintenance rubric is **stable-quiet**, not at-risk — 20
months without a release is a trigger to investigate, and the investigation found
no advisory, no archive flag, no maintainer notice and current dependencies.
`http-problem` 0.3.0 — **fails gate 2** and is **at-risk** on a retrieved signal:
its manifest requires `http ^0.2.8` and `axum ^0.6` against this template's `http`
1.5.0 and axum 0.8.9, so it cannot enter the tree without a second, incompatible
`http` major. `rfc7807` 0.0.1 — fails gate 2, 17 all-time downloads, no repository
field, so gates 3, 4 and 6 cannot be evaluated at all.

**Maintenance state.** `problem_details`: **active** — release 0.10.0 on
2026-08-16, repository pushed 2026-09-12, one open issue, CI that denies warnings,
runs clippy, builds every feature in isolation with `cargo hack`, pins an MSRV job
at 1.85 and dry-runs `cargo publish`. Issue responsiveness rests on **three**
issues, because the repository has only three non-PR issues in its whole history;
the rubric's ten-item window is mostly pull requests. That is stated rather than
padded.

**The evidence gap, named rather than softened.** There is **no well-regarded
public adopter** of `problem_details`, and no public repository was found pairing
it with axum 0.8.9. Its two reverse dependents are not reference projects. The
category's one genuinely well-regarded adopter — ISRG's `divviup/janus` — uses the
*excluded* crate. The compensating evidence is the executed probe plus the crate's
own dev-dependency suite, which tests against `axum` 0.8 and `utoipa-axum` 0.2 —
the exact pairings R69 and R71 need.

**Performance.** No latency or throughput figure is claimed and none was measured.
The envelope is a single `serde_json` serialization of a struct with at most nine
members, on a path taken only by failing requests, behind the same `Json` writer
axum uses for success bodies. A throughput comparison between this and a
hand-rolled struct would be measuring `serde_json`, not this decision.

**The owner reference, row by row.** The document is a standing input that binds
process, not outcome (`docs/planning/p02/owner-decisions.md` §11: "an
owner-supplied research input, not a binding standard and not a pre-decision");
owner-fixed parameters override any value it states. The report tallies **3 agree,
2 agree-with-additions, 7 differ**; each cited line was re-read and the tally
holds. The seven differs and what each rests on:

| Reference row | Verdict | Ground |
|---|---|---|
| `:54`, `:93` — "most such crates unmaintained; hand-roll the small struct" | **differ** | The *premise* fails for the current field, on figures re-fetched 2026-09-18: `problem_details` 0.10.0 released 2026-08-16 and its repository pushed 2026-09-12. It holds for `http-api-problem` (2025-01-06) and `http-problem` (2023), which are the two this decision excludes anyway. The reference's instinct is preserved as the escape hatch |
| `:93` — content negotiation, "a rendered HTML page for browser/HTMX requests" | **differ** | J5; R69's accepted surface has no templating or HTML route, and R69 records templating as having no P02 item |
| `:274-283` — status and title from an inline `match &self` inside `into_response` | **differ** | J4; the table is a separate `const fn` the coverage test calls directly |
| `:271` — `#[error(transparent)] Other(#[from] anyhow::Error)` in the web error type | **differ** | R67's layering rule is explicit: "`anyhow` … in binary crates only; the library crate must not depend on `anyhow`". `crates/web` is a library. The unexpected path is `RSLB000`/500 with the cause logged |
| `:186` — `thiserror = "2"` in the web manifest | **differ** | `thiserror` stays where R67 put it, the library crate; `crates/web`'s error type is a struct with no derive macro and needs none |
| `:270` — `Db(#[from] sqlx::Error)` | **differ (not applicable)** | No database in this template; databases are in the reference's own "no P02 item" set |
| `:238` — layout `src/error.rs` | **differ** | `crates/web/src/problems.rs`, the path R69 revision 10 already assigns to this item (`…:1615`) |

And the row this decision explicitly does **not** rule on: `:53`'s
"garde + axum-valid 0.24" validation stack — see the C4 coupling above.

**Minimal realistic example.** `crates/web/src/problems.rs` plus two lines in
`build_router`, with the one `impl ProblemSource` for the domain error inside
`problems.rs`. Its executable
acceptance check is the twenty-four criteria `R1`–`R24` in `## Empirical check`;
what they prove and what they do not is stated there.

**The trigger set, and which member of it is the binding one.** Nine events would
send a reader back to part of this decision, and they are recorded where they
belong rather than piled into one line: R69 republishing `web-extra-surface` moves
the file paths only (`## Parameters`); R71 selecting an OpenAPI generator, R75
publishing its layer stack, R80 building `/readyz` on the accepted `diagnostics`
carrier and the owner settling C4 validation each land in `### Couplings`; a RustSec advisory against
`problem_details` or `http-serde`, `http-api-problem` publishing a version that
declares `rust-version`, and an axum minor release changing a rejection's default
status are each noted at the gate or criterion they would move. **Three events
move the recommendation itself**: R67 appending a request-validation catalog row,
which would shift the 422 identity off `RSLB201` and add a row to the `code` map;
`problem_details` falling dormant, which would make the hand-rolled struct the
member; and the REST API Design Standard revising §5 or §4.2, which is what moved
this recommendation once already and is now the most likely thing to move it
again. Those three are the binding trigger.

re-verify: the REST API Design Standard is revised past v2.0.0 in section 4.2 or section 5, R67 appends a request-validation catalog row, or problem_details goes 12 months from 2026-09-12 with no release or repository push

## Parameters

This item registers no parameter of its own: the prompt's `- owns:` line is empty,
so there is no `owns` line. The five lines below are the four `fixed` registry rows
plus the one row the prompt's `- consumes:` line names, which is the complete set
the acceptance grammar allows.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**No `CONFLICT:` line.** The recommendation needs no consumed value changed. The
one place pressure could have produced a conflict — R67's catalog having no code
meaning "the client's request body was invalid" — is resolved inside this item by
taking the framework's own status for a framework rejection while carrying
`RSLB201` as its identity, which is py's own three-source structure. An append of a
dedicated request-validation code remains available to R67 later and would cost one
table row.

**`web-extra-surface` is deliberately not an `- assumes` line.** The prompt's
Couplings declare `- consumes: R67: error-taxonomy-exit-codes` and place R69 under
`- related (not a registry dependency)`, and the packaging validator computes the
expected `assumes` set as exactly the `fixed` rows plus the prompt's consumed rows.
R05 revision 3 records the same reasoning in the same situation.

**R69's value nonetheless binds this design, and the binding is stated rather than
hidden.** The `web-extra-surface` row in `docs/port/PARAMETERS.md` is one revision
behind its owner-accepted value: it still reads `web = ["dep:axum", "dep:tokio"]`
with the gated tree at `src/web/`, the tests at `tests/` and skip-gating on
`src/web/**`. **R69 revision 10** (sha256 `d34ab6e8…`, the `- owns web-extra-surface`
line at `:1791`, owner-accepted W0-R69c, not yet published) replaces that with
`web = ["dep:rs-launch-blueprint-web"]`, `axum 0.8.9` and `tokio 1.53.1` declared
non-optionally inside `crates/web/Cargo.toml`, the gated tree at `crates/web/src/`,
the web tests at `crates/web/tests/` and skip-gating on `crates/web/**`. **Every
path in this decision uses revision 10's form**, and the probe workspace was built
in revision 10's topology. **This is not a conflict**: R69's change is already
ruled and in flight, and this recommendation is unaffected by which mechanism
lands, because the envelope, the table and the funnel all sit inside the gated tree
wherever that tree sits. R69's republication is a re-verify trigger for the file
paths in the migration list and for nothing else.

**Two other owner-accepted, unpublished values bind this design and are likewise
not `- assumes` lines**, because neither registers a parameter this item consumes:
R02 revision 2 (sha256 `9e8f8e8c…`) fixes the four-package workspace and
`crates/web` "Depends on `core` only" (`:29`); R05 revision 3 (sha256 `3ca4b81a…`)
fixes the synchronous core reached through `tokio::task::spawn_blocking`.

**Migration implications, at R69 revision 10's paths.** Nothing outside
`crates/web` changes.

| Path | Change |
|---|---|
| `crates/web/Cargo.toml` | one `[dependencies]` line: `problem_details = { version = "0.10.0", features = ["axum", "json"] }`. No `optional = true` — the whole member is already optional at the root |
| `crates/web/src/problems.rs` | **new**, and the only file that names `problem_details`. `ProblemExt` (`code`, `catalog_code`, `documentation`, `errors`), `FieldError` (`pointer`, `code`, `detail`), `pub type Problem`, `pub trait ProblemSource` and its `impl` for the domain error, `pub struct WebError` with its builders and `log_detail`, `impl IntoResponse for WebError`, `pub const fn http_status`, **`pub const fn http_code`**, **`problem_type`**, `pub const fn detail_is_public`, `pub const NOT_REQUEST_REACHABLE`, `From<JsonRejection>`/`From<PathRejection>`/`From<QueryRejection>`, `ProblemJson<T>`/`ProblemPath<T>`/`ProblemQuery<T>`, `not_found`, `method_not_allowed`, **`reserved_parameter_guard`**, **`catalog()`**, `join_error_to_web_error`, and the `headers` field with its `with_header` builder that RFC 9110's `WWW-Authenticate` obligation requires. The bolded items are new in revision 2 |
| `crates/web/src/lib.rs` | `mod problems;` plus re-exports, and two lines in `build_router`: `.fallback(problems::not_found)` and `.method_not_allowed_fallback(problems::method_not_allowed)` |
| `crates/web/src/routes/*.rs` | handler return types become `Result<Json<T>, WebError>`; input extractors become the `Problem*` newtypes; the `spawn_blocking` join result maps through `join_error_to_web_error` |
| `crates/core/src/error.rs` | **no change.** The `impl ProblemSource for <domain error>`, about six lines, lives in `crates/web/src/problems.rs` beside the trait, because `crates/core` cannot depend on `crates/web` (R02 revision 2, `:29`). This is where `probe-r2.sh:359` puts it |
| `crates/web/tests/problems.rs` | **new**: the twenty-four criteria `R1`–`R24`, retargeted at R67's real catalog and at the deployment's declared problem-type base |
| `docs/` | the **R5.16 catalog** — one row per `ErrorCode::ALL` member with its `type`, `code`, `catalog_code` and status — generated from the same list the coverage test walks, so it cannot drift. Publishing it is a **MUST**, not a nicety; the delivery surface is R81's and the content is this item's |
| the web surface's settings | one **required** value with no default: the problem-type base URI (R5.13.1). Named and loaded by R77; the serve binary refuses to start without it |

Not created by this item: `openapi.rs` (R71), the middleware stack and its
rejection rendering (R75), `/readyz`'s failure payload (R80), and a validator with
its `errors` report (ownership unresolved, above).

## Empirical check

**Verification, not implementation.** Nothing here builds the template. The probe
is a throwaway two-crate workspace created under `$TMPDIR` and deleted on exit,
whose only purpose is to decide whether what the Opus report asserts is true.

**Toolchain and host.** macOS 26.4, `aarch64-apple-darwin`.
`rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, and `rustc 1.96.0 (ac68faa20
2026-05-25)` via `rustup run 1.96.0` for the MSRV-floor build.
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` at `/usr/bin/grep`,
`curl 8.7.1`, `Python 3.14.7`, `ShellCheck 0.11.0`. Revision-1 runs are
2026-09-18 UTC; the two revision-2 logs are bannered 2026-09-19T01:16:49Z
(`probe-r2.log`) and 2026-09-19T01:25:52Z (`rest-r2.log`). Neither revision-2
script retrieves from a network, so no figure turns on the date. Revision 4's
two scripts ran on 2026-09-27 UTC on the same host, whose stable toolchain has
since moved to `rustc 1.98.1 (48a229cea 2026-09-01)` and `cargo 1.98.1`; the
1.96.0 MSRV toolchain is unchanged, and `rerun-r4.log`'s banner records both.
Cargo ran with a private `CARGO_HOME`.
Working directory for every command:
`research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/evidence/`.

| Script | Command | Result | Log |
|---|---|---|---|
| `registry.sh` | `./registry.sh > registry.log 2>&1` | **PASS 65, FAIL 0, SKIP 0, exit 0** | `review/evidence/registry.log`, moving counters in `review/evidence/registry-figures.log` |
| `probe.sh` | `./probe.sh > probe.log 2>&1` | **PASS 33, FAIL 0, SKIP 0, exit 0** | `review/evidence/probe.log` |
| `archive-check.sh` | `./archive-check.sh > archive-check.log 2>&1` | **PASS 11, FAIL 0, SKIP 0, exit 0** | `review/evidence/archive-check.log`, with the reruns at `registry-archive.log` and `probe-archive.log` |
| **`rest-r2.sh`** (new) | `./rest-r2.sh > rest-r2.log 2>&1` | **PASS 79, FAIL 0, SKIP 0, exit 0** | `review/evidence/rest-r2.log` |
| **`probe-r2.sh`** (new) | `./probe-r2.sh > probe-r2.log 2>&1` | **PASS 25, FAIL 0, SKIP 0, exit 0** | `review/evidence/probe-r2.log` |
| **`engines-r4.sh`** (revision 4, extended in revision 5) | `./engines-r4.sh > engines-r4.log 2>&1` | **PASS 87, FAIL 0, SKIP 0, exit 0** | `review/evidence/engines-r4.log` |
| **`rerun-r4.sh`** (revision 4) | `./rerun-r4.sh > rerun-r4.log 2>&1` | **PASS 30, FAIL 0, SKIP 0, exit 0**, with the one IANA drift pinned | `review/evidence/rerun-r4.log` |

**Revision 4 adds two scripts and reruns all five earlier ones, writing over no
committed log.** `engines-r4.sh` is read-only and offline. It asserts every
source fact that the revision-4 `## Engines` text and the corrected counts cite:
the two reports' hashes, the prompt's engine line and substitution sentence, the
policy and manifest engine lists, the Q5.A migration, the ledger's collection
entry, the Muse leg's presence and shape, the Muse report at each cited line, the
evidence settling Disagreements 1–3, and the 13/11 criterion partition, nine
unproven items and 2 + 6 quoted bodies. Revision 5 binds its R80 and R02 checks
to fixed revisions rather than to those items' working files: R80's published
revision 6, and R02's committed revision-2 snapshot (sha256 `9e8f8e8c…`). It
also adds group F, which asserts the R80 revision-6 lines behind the `/readyz`
carrier choice. `rerun-r4.sh` runs `archive-check.sh`,
which itself reruns `registry.sh` and `probe.sh` from a `git archive HEAD`
extraction, inside a throwaway clone of HEAD. It runs `probe-r2.sh` and
`rest-r2.sh` in place with their output captured under `$TMPDIR`; `rest-r2.sh`
must run in place, because its group C reads the current `DECISION.md`. It
hashes all thirteen committed evidence files before and after, and asserts that
none moved.

**What the reruns found:**

- `probe.sh` reproduced: 33 of 33, every verdict and body identical.
- `probe-r2.sh` reproduced: 25 of 25, every verdict, body and catalog line
  identical, under rustc 1.98.1 on the host and 1.96.0 at the floor.
- `rest-r2.sh` reproduced: 79 of 79 against this revision's text. Group C still
  finds OV-01 to OV-04 claimed, OV-06 free, and no `OVERRIDE` heading here.
- **`registry.sh` drifted on one of 65 checks.** Its check "IANA problem+json
  cites RFC9457" (`registry.sh:251`) greps the literal `RFC9457`. IANA's
  `application.csv` now reads `problem+json,application/problem+json,[RFC 9457]`,
  with a space. The substance still holds: `rerun-r4.sh` re-fetches the CSV and
  asserts, with a whitespace-tolerant match, that both `problem+json` and
  `problem+xml` cite RFC 9457. It also asserts that the rerun differs from the
  committed `registry.log` on that one verdict and on the summary line, and
  nowhere else. The committed `registry.sh` is not edited, because group B pins
  it. `archive-check.sh` therefore now reports 9 of 11: its two failures are
  that drift and the non-zero exit it causes. Both are pinned by `rerun-r4.sh`.

**Revision 2 adds two scripts and re-runs none of revision 1's.** The five
revision-1 scripts and their four logs are carried **byte-identical**, asserted by
sha256 in `rest-r2.sh` group B (9 checks) rather than by inspection. Two of them
could not be meaningfully re-run in any case: `probe.sh` builds revision 1's
envelope, whose shape R5.13 has since forbidden, and `archive-check.sh` pins
`probe.log`'s summary line. `probe-r2.sh` is the revision-2 successor and carries
revision 1's thirteen surviving behaviours forward as `R1`–`R3`, `R7`–`R10` and
`R12`–`R17`, so nothing revision 1 proved is dropped rather than re-proved.

**`rest-r2.sh` — 79 checks in three groups.** Group A (63) extracts the standard
at the pinned blob, asserts the extraction hashes **back** to that blob and that
the pinned commit carries it as `rest-api-standard.md`, then asserts each quoted
rule twice: its identifier at its exact line, and its sentence by a
whitespace-collapsing match, because the standard is hard-wrapped and a rule's
sentence spans line breaks. It also pins the standard's own worked error body from
appendix E, which is the shape this revision adopts rather than interprets.
Group B (9) is the revision-1 byte-identity. Group C (7) is the `OVERRIDE`
numbering search, with OV-01 through OV-04 asserted **claimed** as the
non-vacuous control for OV-06 being free, and an assertion that this
decision declares no `OVERRIDE` heading.

**`probe-r2.sh` — 25 checks over a rebuilt three-member workspace.** Same topology
as revision 1's probe and the same control member, so the dependency comparison
is unchanged; the web member is rewritten to the moved envelope. It builds and
runs the twenty-four criteria under **rustc 1.96.0** and again on the host
toolchain, asserting `24 passed; 0 failed` and no `warning:` from either; prints
six response bodies and asserts four of them literally plus three
whole-file negatives (no `about:blank`, no `null`, no upstream token); generates
the R5.16 catalog and asserts eight properties of it, including that all
seventeen `code` values are unique and grammar-conformant and every `type` is
template-bound; and re-runs the tree diff, which still shows the moved envelope
adding exactly `http-serde v2.1.1` and `problem_details v0.10.0` and
`problem_details` named from `problems.rs` alone.

All seven are `set -euo pipefail` with `set -o pipefail` restated, assert on
content rather than on exit status, count PASS/FAIL/SKIP, sum them and exit
non-zero on any FAIL. All seven are `shellcheck` 0.11.0 clean. No script contains a
personal email address or a token; the `User-Agent` sent to crates.io is the
repository URL `https://github.com/smorinlabs/rs-launch-blueprint`. GitHub REST is
reached through keyring-authenticated `gh api` at no more than one call per 20 s.

**`registry.sh` — 65 checks re-verifying the published record.** crates.io
`/crates/<name>`, `/versions`, `/<v>/dependencies` for `problem_details`,
`problemdetails`, `http-api-problem`, `http-problem` and `rfc7807`;
`static.rust-lang.org`'s stable channel manifest, from which the 1.96 floor is
re-derived rather than assumed; `rustsec.org/packages/<name>.html` for five crates
plus the two `http` advisories read from `advisory-db`; RFC 9457 at the datatracker
(`std_level`, `stream`, `title`) and at the RFC Editor, where every load-bearing
sentence is matched **after collapsing whitespace**, because the RFC body is
hard-wrapped and a line-oriented `grep` cannot see a sentence that spans a break;
the IANA `application` media-types registry; RFC 9110's two `MUST` sentences and
the 401-versus-403 pair, with the three section headings pinned at the exact line
numbers `raw/opus.md` cites (7548, 7569, 7601 — all three correct); and five
`gh api` reads covering the repository's archived flag, its open-issue count,
`divviup/janus`'s manifest, `oxidecomputer/dropshot`'s error type and the crate's
own CI workflow.

**`probe.sh` — 33 checks, of which the sixteen acceptance criteria are one.** It
writes a three-member workspace under `$TMPDIR` (`r70core` holding a 17-row
stand-in for R67's catalog with `ALL` and `as_str`; `r70web` holding the envelope,
the table and the funnel; `r70ctl`, a control member with the identical
dependencies **minus** `problem_details`), then:

1. builds and tests the workspace under **rustc 1.96.0** — this closes the
   report's own stated gap (1) — with `Locking 56 packages to latest Rust 1.96
   compatible versions` asserted, and `16 passed; 0 failed`;
2. builds and tests it under the host stable toolchain, asserting `16 passed;
   0 failed` **and that the build emits no `warning:` at all**;
3. runs a `dump` example that prints four response bodies and asserts each one
   against the literal `raw/opus.md` captured, plus that no body carries a `type`
   member and none carries a `null`;
4. diffs the resolved trees of `r70web` and `r70ctl` and asserts the added set is
   exactly `http-serde v2.1.1 problem_details v0.10.0`, that axum resolves to
   0.8.9 and tokio to 1.53.1, and that `problem_details` is named from
   `problems.rs` and nowhere else;
5. proves the `#[non_exhaustive]` claim **in both directions** — a purpose-built
   single-crate build whose `_` arm draws `unreachable pattern … no value can
   reach this`, against the cross-crate build where the identical arm draws
   nothing;
6. asserts eleven source facts in the vendored crates at their exact cited lines —
   `#![forbid(unsafe_code)]`, `CONTENT_TYPE`, the two `utoipa` attributes at
   `problem_details.rs:117,170`, the three axum rejection statuses at
   `rejection.rs:11,23,34`, `Router::fallback` at `routing/mod.rs:345`,
   `method_not_allowed_fallback` at `:374`, and that **no** crate in the framework
   tree mentions `problem+json`.

Revision 1's bodies, kept as the record of what the standard changed:

```
GET /projects/demo -> 404 Not Found application/problem+json
{"status":404,"title":"Not Found","detail":"project 'demo' not found","instance":"/projects/demo","code":"RSLB301"}
POST /projects -> 422 Unprocessable Entity application/problem+json
{"status":422,"title":"Unprocessable Entity","detail":"Request validation failed.","code":"RSLB201","errors":{"body":["Failed to deserialize the JSON body into the target type: name: invalid type: integer `42`, expected a string at line 1 column 11"]}}
```

Revision 2's bodies, captured verbatim by `probe-r2.sh`. The 422 is the one to
read against the 422 above: no `type`, a map-shaped `errors`, and the offending
value `42` echoed — three rules broken — become a template-bound `type`, an
`errors` array, and a body that names the location without the value.

```
GET /projects/demo -> 404 Not Found application/problem+json
{"type":"https://problems.example.com/resource-not-found","status":404,"title":"Not Found","detail":"project 'demo' not found","instance":"/projects/demo","code":"resource_not_found","catalog_code":"RSLB301"}
GET /upstream -> 502 Bad Gateway application/problem+json
{"type":"https://problems.example.com/upstream-failed","status":502,"title":"Bad Gateway","detail":"An unexpected error occurred.","instance":"/upstream","code":"upstream_failed","catalog_code":"RSLB103"}
POST /projects -> 422 Unprocessable Entity application/problem+json
{"type":"https://problems.example.com/request-invalid","status":422,"title":"Unprocessable Entity","detail":"The request could not be processed as submitted.","code":"request_invalid","catalog_code":"RSLB201","errors":[{"pointer":"","code":"invalid_body_type","detail":"The request body did not match the expected shape."}]}
DELETE /ok -> 405 Method Not Allowed application/problem+json
{"type":"https://problems.example.com/request-invalid","status":405,"title":"Method Not Allowed","detail":"This method is not allowed for this path.","code":"request_invalid","catalog_code":"RSLB201"}
GET /documented -> 409 Conflict application/problem+json
{"type":"https://problems.example.com/conflict","status":409,"title":"Conflict","detail":"The project already exists.","code":"conflict","catalog_code":"RSLB501","documentation":"https://developers.example.com/errors#conflict"}
POST /projects?dry_run=true -> 400 Bad Request application/problem+json
{"type":"https://problems.example.com/request-invalid","status":400,"title":"Bad Request","detail":"This endpoint does not implement the requested capability.","instance":"/projects","code":"request_invalid","catalog_code":"RSLB201","errors":[{"pointer":"","code":"unsupported_reserved_parameter","detail":"A reserved request parameter was sent to an endpoint that does not implement it."}]}
```

The `/upstream` handler's domain message is
`GET https://api.example.com/x?token=s3cret failed: 500`; `R8` asserts
(`probe-r2.sh:979-990`), and a whole-file negative over every captured body
confirms (`probe-r2.sh:1309`), that neither `s3cret` nor `api.example.com`
occurs anywhere in the response body, as revision 1's `AC5` did for its own
envelope, and neither does. That is the executed form of py's SEC-4 rule.

**Reproduction, stated as a claim that can be kept.** `archive-check.sh` extracts
`git archive HEAD` into a clean `$TMPDIR` tree — asserting first that the worktree
marker exists (a worktree's `.git` is a **file**, tested with `-e`, not `-d`) and
that the extraction contains no nested repository — runs both scripts *there*, and
diffs their output against the committed logs. It passes 11 of 11: both scripts
exit 0 from the extraction; `registry.log` and `registry-archive.log` are
**identical below the three-line banner** (line 2 carries the run date); and
`probe.log` and `probe-archive.log` **agree on every one of the 33 verdicts and on
every captured body**, compared line-for-line rather than asserted. The probe log's
banner does move — it carries the run timestamp and the scratch directory's random
suffix — and the resolver's `Locking 56 packages` line is printed only against a
cold registry, which is why the probe comparison is over the verdict and body lines
rather than over the whole file; the rule is stated in the script beside the check
that applies it. The moving registry counters — download totals, star count,
`pushed_at`, the open-issue total — are deliberately kept out of the diffed log and
written to `registry-figures.log`, which is a dated snapshot and is **not** claimed
to reproduce. This paragraph is written after running the comparison, not before:
the first attempt **failed**, because the committed `registry.log` predated a fix to
one RFC 9110 phrase; the log was regenerated and the comparison re-run.

**What these checks do not prove, and is therefore left for P03.**

- **No Linux execution.** Everything here ran on macOS. `problem_details`'s
  upstream CI covers `ubuntu-latest` and does not cover macOS, so the two halves of
  `target-os-matrix` are covered by different evidence.
- **No feature-off tree.** The probe has no Cargo feature, so "the crate is absent
  from a default build" is inherited from R69's and R05's measurements, not
  re-measured here.
- **No route-walk over a real router.** `R24` walks fourteen hand-listed requests
  (twelve failing, two succeeding), not an enumeration of `build_router`'s routes. The mechanical form of W3 is a P03
  test.
- **No `cargo-deny` run.** Advisories were verified by RustSec page and
  `advisory-db` raw file, not by R13's tool, which is not yet wired.
- **No middleware-originated error.** Those are R75's.
- **No `request-id` header.** §1.10 reserves it on every response including
  errors, but nothing in this item emits it and no middleware exists to set it, so
  "the error path does not drop it" is a P03 check, not one run here.
- **No body-carried `stream`.** `R20` loops over three *query* strings
  (`dry_run=true`, `dry_run`, `stream=1`), but §1.10 reserves `stream` "in
  **either** carriage — query parameter or request-body member" (`:339`); a
  `stream` member inside a request body is untested. The guard's *placement* is
  R75's either way.
- **The `type` base URI is a probe constant, not a setting.** `PROBLEM_BASE` is a
  `const` in the probe. That the base can be *required* at startup, and that the
  binary refuses to start without it, is R77's to build and P03's to prove.
- **No API-level conformance note.** The fragment above covers this item's rules
  only. Whether one document carries the whole API's note, and who owns it, is an
  **open owner question** this decision raises and does not answer.

## Engines

**Two engines produced raw reports: Muse and Opus.** The pinned prompt
(`inputs/prompt.md`, sha256 `b47f8a26…`, equal to the manifest's
`input_hashes.prompt`) reads `- engines: muse, opus` (`:23`) and states "This
item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its
mirrored `- engines:` line is authoritative" (`:69`). `research/EXECUTION.json`
records both `engine_overrides.R70` and `items.R70.engines` as
`["muse", "opus"]`. The substitution is owner decision **Q5.A** (2026-09-21):
"Muse-bulk all 17 remaining legs" (`docs/planning/p02/execution-ledger.md:1114`).
The manifest applies it to this run as a migration event at
2026-09-21T23:06:20Z, `from: codex`, `to: muse`, citing "owner decision Q5.A
2026-09-21".

| Engine | Report | sha256 | Model | Dated | Shape |
|---|---|---|---|---|---|
| **Opus** | `raw/opus.md`, byte-identical to the collected `raw/opus-82538638….md` | `82538638b5f54017c22853eb9e52e6d4e6c71b78e35fad8ed6ea68be3fefe39e` | `claude-opus-5` (manifest `actual_model`) | written 2026-09-18 | bundle template, four `####` members |
| **Muse** | `raw/muse.md` | `989725675cb0f0c7d0dbb975435097d4d0f837e0ec32c137fc4cf64b3c4a7249` | `muse-spark` requested; the resolved model is not recorded (below) | live figures retrieved 2026-09-25 (`raw/muse.md:3`) | `scripts/check-answer-shape.sh raw/muse.md bundle` prints `OK: validation passed`; two `####` members |

**The Muse leg's collection record, and the receipt the manifest lacks.** The
controller's ledger records the leg as collected: "R70 sha 98972567 (218 lines,
bundle OK) — http-api-problem 0.60.0 envelope + HttpStatus trait"
(`execution-ledger.md:1157`, in the entry headed "R58 + R70 MUSE LEGS COLLECTED
(retries), 2026-09-23"). `98972567` is the leading digits of `raw/muse.md`'s
sha256. The run manifest has not caught up: `operations.muse.state` is still
`submitting`, with no `raw_sha256` and no `actual_model`; `operations/muse.json`
says the same; and the run `state` is `partial`. So the collection receipt exists
only in the ledger, and the model behind the requested `muse-spark` label is
recorded nowhere in the run. This synthesis treats `raw/muse.md` as the collected
Muse leg on the ledger's authority. Writing the manifest receipt is a runner
operation outside a synthesis, so the missing receipt is recorded as a gap for
the controller.

**Why revisions 1 to 3 described one engine.** Revision 1 was written when this
item's engines were `codex` and `opus` and the Codex leg was deferred under owner
ruling W1-CODEX3 (2026-09-18). That framing is history only: the pinned prompt
supersedes it, and owner decision Q9.B has since retired Codex from P02
(`research/RUNBOOK.md:72-73`).

**Where the two engines agree.** Both recommend one RFC 9457
`application/problem+json` envelope for every non-2xx response (`raw/muse.md:41`).
Both route framework 404/405 through the router's fallback and reshape extractor
rejections into the same envelope (`:27`, `:124`). Both keep the status table
hand-written and reject a derive (`raw/muse.md:136`; `raw/opus.md:288-289`,
`:868-872`); Muse alone also rejects a runtime `HashMap<TypeId, StatusCode>`
(`raw/muse.md:136`), an option the Opus report does not consider. Both rank
`problemdetails` 0.7.0 as runner-up (`:61`, `:81`). Neither raises a `CONFLICT:`
or a `BASELINE-REVIEW:` line (`:25`, `:89`, `:160`).

**The three disagreements, each settled by evidence this decision already
carries.** None moves the recommendation.

**Disagreement 1 — the envelope crate.** Muse makes `http-api-problem` 0.60.0 its
dominant choice and recommendation (`raw/muse.md:57`, `:77`) and states "None of
the envelope-crate candidates fails a fitness gate" (`:65`). It does not survey
`problem_details` at all. Opus and this decision recommend `problem_details`
0.10.0 and exclude `http-api-problem` by gate 2. The crux is gate 2's wording in
the prompt: "crate and dependency-tree MSRV within `stable minus 2 minor
versions, raised only in a minor release, declared as rust-version in Cargo.toml
and tested in CI`" (`inputs/prompt.md:62`). Muse itself records that the crate
"declares no rust-version (None)" (`raw/muse.md:73`). It applied the "within"
half of the gate and not the "declared as rust-version" half. `registry.log:24`
asserts that zero published versions declare one. **Resolved for this decision:**
`http-api-problem` stays excluded by gate 2. Muse's adoption figures agree with
this decision's own reading that it is the strongest candidate on every other
axis (`### Principles and implementation`, "Excluded by gate"). Because Muse
never weighed `problem_details`, it supplies no evidence against the recommended
crate. The trigger that would reopen this, `http-api-problem` publishing a version
that declares `rust-version`, is already in the trigger set.

**Disagreement 2 — how totality is enforced.** Muse's status table is an
"exhaustive `match` over variants (no wildcard arm)" (`raw/muse.md:124`), so that
"adding a domain variant without a mapping fails to compile" (`:29`), with a
planned negative check expecting that compile error (`:209`). This decision holds
that this is impossible across the crate boundary, because R67's `ErrorCode` is
`#[non_exhaustive]`. The evidence is executed in both directions at
`probe.log:46-48`: in one crate the `_` arm draws `unreachable pattern`; across a
crate boundary the same arm compiles with no warning. R67 anticipated this
consumer and prescribed the `ErrorCode::ALL` coverage test
(`research/topics/67-error-and-exit-code-contract/DECISION.md:148-153`, resolved
at `:653-662`). Muse designed against an undecided R67: its `assumes` line for
`error-taxonomy-exit-codes` is a placeholder, "(R67 undecided; …)"
(`raw/muse.md:187`), which the prompt's own wording "(not yet decided)"
(`inputs/prompt.md:34`) invited, although `inputs/prerequisites.json` pins R67's
published decision `16947ab1…`. **Resolved for this decision:** Muse's planned
negative check would compile silently rather than fail, so totality is enforced
by the `ALL` test, as R67 prescribes.

**Disagreement 3 — the seam.** Muse puts the table behind a trait,
`HttpStatus::status_code(&self) -> StatusCode`, "template-owned in
`web::problems`" (`raw/muse.md:128`) and implemented for R67's type (`:124`,
`:148`). This decision uses a free `pub const fn http_status(ErrorCode) ->
StatusCode`. The layering objection in `### The domain-code-to-HTTP-status table`
does **not** refute Muse's form: it applies to a trait defined in `crates/core`,
and a trait defined in `crates/web` and implemented there for a foreign type is
legal Rust with no `StatusCode` in `crates/core`. This decision already uses that
seam shape for a different job, `ProblemSource` (`probe-r2.sh:349`, implemented at
`:359`). The free function is kept on three grounds that do survive:

1. Muse's reason for a trait is genericity over an R67 that had not decided
   (`raw/muse.md:124`, `:160`). R67 has since published one `#[non_exhaustive]`
   enum, `ErrorCode`, so the trait would have one implementor and adds indirection
   with no second implementation to serve.
2. Muse's payoff for the trait body, compiler-checked totality, is removed by
   Disagreement 2. The body needs the same `_ =>` arm, so totality is the `ALL`
   test either way.
3. Implemented on the domain *error* type, as Muse's `impl HttpStatus for
   R67Error` reads (`:124`), the trait cannot serve a `JoinError` mapped to
   `RSLB000` or a framework rejection carrying `RSLB201`, because neither is a
   domain error value. Implemented on `ErrorCode` instead, it is the free function
   called with method syntax.

**Resolved for this decision:** this is a close call on form, not on behaviour.
The free `const fn` is kept. An owner who prefers method syntax can wrap it in a
web-local trait on `ErrorCode` without changing any status row or any criterion's
verdict.

**Other Muse positions, none load-bearing.** Muse's figures are dated
2026-09-25 and this decision's 2026-09-18, so they differ (for example,
`problemdetails` at 48,464 all-time downloads in `raw/muse.md:13`). Muse values
`http-api-problem`'s many optional framework integrations because R69 was open
(`:73`); R69 revision 10 has since fixed axum 0.8.9, so that breadth buys nothing
here. Muse's envelope field list for R71 is `type`, `title`, `status`, `detail`
and `instance` (`:199`); W2-REST's R5.13 has since made `code` mandatory and
`type` always present, which this decision's contract carries. Neither engine was
prompted with the REST standard. Muse's `assumes` lines for
`error-taxonomy-exit-codes` and `web-framework-stack` (`:187-188`) are
placeholders rather than registry values, and bind nothing; this decision's five
`- assumes` lines are the registry's.

**The `/readyz` diagnostic carrier — this item's choice under R80 revision 6.**
R80's published revision 6 requires that "the diagnostic report must be
reachable from the 503 response", names three ways to satisfy it, and states
"R70 owns the choice"
(`research/topics/80-health-probe-endpoints/DECISION.md:859-865`). Neither
engine report addresses the question, because R80 raised it after both legs
ran; the choice rests on this decision's own rules and R80's published text.
**Chosen: (a), a `diagnostics` extension member.** Each way is tested against a
rule this decision already states:

| R80's way | Verdict | Ground |
|---|---|---|
| (a) a second extension member named `diagnostics` | **chosen** | It is py's own shape: `extensions={"diagnostics": report.model_dump(mode="json")}` (R80 revision 6, `:853`). R80's executed probe already carries the report under that name (`T4`, `:1155`). The name is snake_case (R4.4), and the pinned standard contains no occurrence of `diagnostics` (`git cat-file -p 71bd813c…` in the standard's repository, then a case-insensitive search: 0 matches; checked by hand, not by a script, because `engines-r4.sh` reads only this repository), so it repurposes no reserved name (R1.8). `problem+json/v1` is append-only, so R80's `/readyz` route may append the member; the nine-member base this item ships, the grammar and every criterion are unchanged |
| (b) the report folded into a structured error-detail member | rejected | The only structured member is `errors`, whose entries each carry an RFC 6901 `pointer` to an offending *input* location (R5.15, the contract table). A health check has no input location, so folding the report into `errors` would give a member the standard registers a different meaning (R1.8) |
| (c) a `detail` string naming the failing checks, the full report left to the logs | rejected | The W5 rule, executed as `R3`, forbids any 5xx code from being detail-public, so a 503's `detail` is replaced by the fixed generic string and could not name the failing checks. Choosing (c) would require an exception to an executed criterion |

The member follows the contract's omission rules: it is omitted when absent,
which is on every response except `/readyz`'s 503, and it is never `null`. This
item owns the member's name and its omission rule. R80 owns the report's
content and its R5.17 redaction, which R80 revision 6 builds "redacted at its
source" (`:1007`).

**What revision 2 changed, and on whose authority.** The five moves under
`### Conformance to the REST API Design Standard v2.0.0` come from the standard
at its pinned blob, not from an engine report. No research leg ran for revision 2
(2026-09-18). The Muse leg ran afterwards, and it touches none of the five moves,
because neither engine was prompted with the REST standard. Every move
is traceable to a rule asserted at its line, and each is executed: M-1 by `R6`,
M-2 by `R4`, `R5` and `R23`, M-3 by `R11`, M-4 by `R18`, M-5 by `R22` and `R23`. **The
single most consequential finding is M-4**: revision 1's design placed axum's
rejection text — which renders the offending request *value* — into the response
body, and R8.12 forbids exactly that. It was found by reading the rule, not by
the probe, and only then made executable.

**How much the second engine adds, stated plainly.** Muse is a different model
family (Meta) from Opus and from this synthesizer, so the design now has a second
family's independent judgment behind it, and that judgment agrees on the pattern.
It is judgment, not replication: Muse executed nothing ("Proposed, not executed",
`raw/muse.md:37`; gap 5 at `:218`). Every executed fact in this decision still
comes from this synthesis's own re-verification — 65 registry checks and 33 probe
checks in revision 1, 79 and 25 in revision 2 — and the three things in the Opus
report that came back wrong are tabled under `### Corrections to raw/opus.md`.

**Re-verified by this synthesis** (claim → where it was checked): every crates.io
figure and every gate-2 exclusion; the RustSec posture of all five crates; the
`#![forbid(unsafe_code)]` posture; the 1.96 MSRV floor, re-derived from the live
stable channel; RFC 9457's standards status, its IANA registration, its
`about:blank` rule, its extension-member clause and the true numbering of §3.1.1
to §3.1.5; RFC 9110's `Allow` and `WWW-Authenticate` `MUST`s and the
401-versus-403 pair; `divviup/janus`'s and `oxidecomputer/dropshot`'s current
sources; the crate's ubuntu-only CI and its 1.85 MSRV job; the absence of
problem-details support anywhere in the framework tree; the cited line numbers in
the vendored `problem_details` and `axum` sources; the cross-crate
`#[non_exhaustive]` behaviour, in both directions; the dependency cost, by tree
diff against a control member; and, in revision 1, all fourteen of the Opus
report's acceptance criteria, re-run from an independently written probe, plus two
additions (`AC1`–`AC16`), which revision 2 replaced with `R1`–`R24` — and
**better than the Opus report on one axis**, because both suites also compiled and
ran at the 1.96 MSRV floor, which the report explicitly could not do.

**Carried from revision 1 unchanged**, and therefore still resting on revision
1's evidence: the crate selection and all six fitness gates, every status row,
the funnel's four extension points, the landscape and the excluded candidates,
and the whole owner-reference tally. W2-REST reaches the body's *shape*, not the
crate, and `probe-r2.sh` confirms the crate carries the moved shape with no new
dependency.

**Carried from the Opus report without independent re-verification**, each with what
would prove it:

| Carried claim | What would prove it |
|---|---|
| py's `problems.py` at pin `b08bccfb` — the docstring, the four handlers, `ERROR_STATUS`, the SEC-4 comment | reading `py src/py_launch_blueprint/web/problems.py` through the pin in the py checkout, which is outside this repository and therefore outside a `git archive` rerun |
| Issue-responsiveness medians (4.49 d median, zero unanswered, over three issues) | re-reading the `/issues` and `/issues/{n}/comments` endpoints; the open-issue **count** was re-fetched here, the medians were not |
| The report's own compile-cost figures (0.75 s dev build, 224,880-byte debug rlib) | a timed `cargo clean -p && cargo build -p`; this synthesis measured the dependency *count* instead, which is the figure the decision actually uses |
| That `explicit-error-http`, `problem-details-mapper` and `zekurix-server` are the only reverse dependents | re-reading the `reverse_dependencies` endpoint; the adopter *gap* is what the decision relies on, and that is stated as a gap either way |

**Unproven, and left for P03 to prove in the real template.** The nine items under
"What these checks do not prove" above, and specifically: `cargo build --features
web` and `cargo test --features web` against the real crate; `cargo tree -i
problem_details` with `web` off, showing the crate absent from the default tree; a
route-walk test issuing a malformed request to every route in `build_router` and
asserting the content type **and** the RFC 9110 header obligations; the same suite
on `ubuntu-latest`; `cargo deny check advisories` once R13's tool is wired; and a
snapshot test over one body per distinct status so an accidental member rename
fails a test rather than a client.

**Where the evidence is incomplete, stated plainly.** Confidence is **high** that
the envelope-plus-table-plus-funnel design is correct and implementable at R69's
pinned versions on macOS at both 1.96 and 1.98 — that is executed, not argued.
Confidence is **medium-high** on `problem_details` as the document type: six gates
cleared, one of them by execution rather than by upstream CI, with the residual
risk concentrated and named — one maintainer, 10 stars, 1 subscriber, no
well-regarded public adopter — and mitigated structurally by the containment rule
rather than verbally. The two engines split on this crate, and the split is
settled by gate 2's wording and an executed registry check (Disagreement 1), not
by counting reports. Confidence is **medium** on the individual status rows, which
are proposals, and **medium** on the funnel's completeness, because
middleware-originated errors belong to R75 and were not exercised. The single
question this decision deliberately leaves to the owner is who owns C4 validation.
