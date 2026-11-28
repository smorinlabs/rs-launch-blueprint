# 2026-09-27 — R77 — web-env-settings (crate, Focused) — decision (revision 6)

**Revision 6 is a flag-day re-copy of one `assumes` line. The recommendation does not
move: no crate, template code over `std::env::vars_os` and `str::FromStr`.** Revision 5
(sha256 `a3c2dc6ca904b80f8e565f9ad0999cb3a0ab3f78f5d0f9e8d53c1b9d97765b55`) is kept byte
for byte as `review/R77-r5-snapshot.md`. Owner ruling W1-R02 (a four-package workspace
with `crates/web` as the optional web member) changed R69's owned `web-extra-surface` at
R69 revision 10. R69 revision 11 carries that value unchanged and is approved for
re-accept. Under owner decision Q3.A (flag day now), every consumer re-copies it at once
rather than waiting for the registry row to be republished. This revision copies the
`- owns web-extra-surface = ` line of R69 revision 11 (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`,
sha256 `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`, line 1885) verbatim, with the
prefix changed to `- assumes web-extra-surface = `. The value after the prefix is
byte-identical to R69's (`cmp`; 2,783 bytes after the prefix).

| What | Revision 5 | Revision 6 |
|---|---|---|
| `- assumes web-extra-surface = ` | the revision-9 registry bytes: `web` declared "on whichever crate hosts the binary targets (R02 decides which)", `web = ["dep:axum", "dep:tokio"]` with both crates optional, the tree at `src/web/`, file-level `#![cfg(feature = "web")]` on the tests, skip-gating on `src/web/**` | R69 revision 11's bytes: `web` declared on the root package `rs-launch-blueprint`, `web = ["dep:rs-launch-blueprint-web"]`, `axum` and `tokio` declared non-optionally in `crates/web/Cargo.toml`, the tree at `crates/web/src/`, the tests in `crates/web/tests/` with no file-level `cfg`, skip-gating on `crates/web/**` |
| `## Parameters`: provenance sentence, the `web-extra-surface` paragraph, and the second expected-`CONFLICT:` case | explained why the line carried revision-9 bytes while the design used revision 10's paths | state that the line is R69 revision 11's value; the path mismatch they explained no longer exists |
| `re-verify:` clause on R69 | "when R69 republishes and the registry bytes move from `src/web/` to `crates/web`" | when the registry row is republished, or R69 revises the owned value again |
| `review/evidence/sources.sh` | compared all six `assumes` lines with the live registry; pinned R69's owned line at revision 10's `:1791` | compares `web-extra-surface` with R69 revision 11's `:1885` (sha pinned) and the other five with the registry; the R69 pin moves to `:1885`. Recorded to `review/evidence/sources-r6.log` |

No design claim changed. Every path in this decision was already revision 10's
(`crates/web/src/settings.rs`, `crates/web/Cargo.toml`, `crates/web/tests/`), and those are
revision 11's paths too. The service knobs this item names (host, port, log format, drain
deadline and the rest) are the environment variables the revision-11 value says R77
names; that clause is unchanged from revision 9.

**Evidence after this revision.** `sources.sh` was edited as tabulated, passes
`shellcheck`, and was rerun into the new `review/evidence/sources-r6.log`:
**PASS=85 FAIL=0 SKIP=0**, exit **0**. `review/evidence/sources.log` (2026-09-18) is kept
unchanged. Before the edit, the unmodified script reported PASS=83 FAIL=1: its one failure
was the R69 pin at revision 10's `:1791`, which R69 revision 11 moved to `:1885`.
`r4-checks.sh` was not edited or re-recorded. Rerun against this file, it reports
PASS=172 FAIL=13. Three failures follow from this revision by design: `H1 names revision 4`,
the F5 `this file` label check (which expects revision 5), and the sha pin on the carried
`sources.sh`. The other ten are drift in files other sessions own (the live prompt's
sha256, R74 and R58 re-pins and line checks); drift is not repaired here.

**Revision 5 is a directed repair of revision 4 (sha256
`7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884`, kept as
`review/R77-r4-snapshot.md`). The recommendation does not move: no crate, template code
over `std::env::vars_os` and `str::FromStr`.** Both round-2 audits rejected revision 4
(`review/audit-claude.r4.md`, empirical, 1 finding; `review/audit-fable.r4.md`, judgment,
2 findings). All three are mechanical and are repaired here as the audits specify. The other changes are the lead-in to the reproducibility rule, which now says revision 5 states
it; the revision-history roll below, which now calls revision 5 `this file`; the F5 label
check, which now expects revision 5; and the two `r4-checks.sh` figures that the paragraph
after the table explains. All
dates are UTC.

| Finding | What was wrong in revision 4 | Revision 5 |
|---|---|---|
| claude r4 E1 | The reproducibility rule claimed to list every kind of line that varies, but item 2 said "in `probes.log` only" and missed the inherited `CARGO_TARGET_DIR` path and the order of cargo's parallel test result lines. | Item 2 names `probes.log`, `probes-r4.log` and `probes-rerun-r4.log`, and adds the inherited `CARGO_TARGET_DIR` path (the `# inherited` header, the `## run 1` header, cargo's `Running …` line) and the order of cargo's `test … ok` lines. No script or figure changed. |
| fable r4 1 | R74's citations pointed at "revision 1 … `:410-414` … `:452`". The cited path now holds R74 revision 2, whose lines 410–414 are a different paragraph. `r4-checks.sh` group C pinned R74 at `84c01ec0…`. | Re-pinned to R74 revision 2, sha256 `68e19cf3…`: members at `:511-513`, the `OVERRIDE (OV-17)` reason at `:515`, the hand-off at `:560`. "Revision 1" became "revision 2" in the field-count paragraph, Move 2 item 1, AC14 and the re-verify line. Group C pins the new sha and lines. Its "R74 answers the floor" check (rev 1 `:414`) has no counterpart in revision 2 and is dropped, so the group has six checks. |
| fable r4 2 | The counts paragraph said `rest-conformance-r2.sh` **PASS=90 FAIL=1** and a total of 372 PASS and 1 FAIL, then called those "the committed logs' counts". The committed log ends 91/0/0. | The paragraph states the committed counts, 373 checks and 373 PASS, and attributes the 90/1/0 figure to the later-title rerun recorded in `ov-allocation-r3.log`. |

**`r4-checks.sh` after this revision.** Group C was edited as above, its F5 label check
now expects revision 5's `this file` label, and the script was rerun into
`review/evidence/r4-checks.log` against this file: **PASS=184 FAIL=1 SKIP=0**, exit **1**.
The one failure is its own `H1 names revision 4` check, which binds revision 4's
title by design and must fail once the title says revision 5, the same disposition as
`rest-conformance-r2.sh`'s revision-2 title check. No other script was edited or rerun.

**Revision 4 answers the two round-1 audits of revision 3 and synthesizes the second
engine report. The recommendation does not move: no crate, template code over
`std::env::vars_os` and `str::FromStr`.** Both audits rejected revision 3
(`review/audit-fable.r1.md`, judgment, 6 findings, 2 blocking;
`review/audit-claude.md`, empirical, 5 findings). All eleven are answered here, and
`review/evidence/r4-checks.sh` asserts each repair in this file. All dates are UTC.

| Finding | What was wrong in revision 3 | Revision 4 |
|---|---|---|
| fable F1 (blocking) | `## Engines` called the item single-engine ("codex — absent", `required_engines: [codex, opus]`). The binding prompt now reads `- engines: muse, opus`, and the Muse report `raw/muse.md` (sha256 `a2e9a208…`, 2026-09-25) recommends `config`. Its six disagreements were never adjudicated. | `## Engines` lists both reports and the engine migration history. `#### Disagreements between the engines, and what settled each` adjudicates all six disagreements plus three further differences. Muse's recommendation is rejected on measured and owner-accepted evidence. One new probe (P7) shows that Muse's exact `config` loader silently drops a multi-word variable. |
| fable F2 | The decision set an "at least four members" floor on R74's rate-limit family and claimed the field count "is still twelve". R74 revision 1 fixes three members. | The floor is withdrawn. R8.10's dimensions are handed to R74 as input. The field count is restated as eleven py-derived scalar fields plus one field per R74 member plus the readiness pause. AC14 and the re-verify line point at R74's published membership. |
| fable F3 (blocking) | Each of R77 and R80 said the other decided the readiness-propagation pause. R77 also quoted a sentence from R80's raw report that R80's own decision had withdrawn. | **R77 accepts the requirement.** It names `RSLBP_WEB_READINESS_PAUSE_SECONDS`, sets default `0`, and adds a boot-time rule: the pause must be strictly less than `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`, and it is spent from that budget. R80 revision 3 is cited at its lines. See `#### The readiness-propagation pause`. |
| fable F4 | R77 and R58 each claimed the first statement of the serve binary's `main`. | Handshake stated: `WebSettings::from_env()` runs first and logs nothing. Its `log_level` and `log_format` fields are the values `telemetry::init(Profile::Service { .. })` receives. Telemetry reads no environment variable itself. New AC16 checks this, and it is a request to R58. |
| fable F5 | A stale "(this file)" label on revision 2; R80 was called "published"; and a vacuous check was described as a working control. | Revision history relabelled by commit. R80 is described as "landed". The `rest-conformance-r2.sh` bullet is marked as superseded. |
| fable F6, claude 4 | `config` figures were cited at 0.15.25 / 1.85.0. 0.15.26 (2026-09-21, `rust-version` 1.88.0) is now the newest release, inside the runner-up range. | Both versions are recorded. 0.15.26 was measured: 11 packages, +83,200 B, and the identical error string (`probes-r4.sh` P3r4, P6r4). The re-verify line now says 1.88.0 and adds a new-0.15.x trigger. |
| claude 1 | `probes.sh` P6 measured a missing binary as 0 B under an inherited `CARGO_TARGET_DIR`, so two size checks passed on nothing. | `probes-r4.sh` supersedes P6. It unsets the variable, passes an explicit `--target-dir`, treats a failed build or a missing or empty binary as FAIL, and has a negative control. The carried script was rerun both ways: 31/3/0 as written, 34/0/0 with the variable removed (`review/evidence/probes-rerun-r4.log`). |
| claude 2 | `ov-allocation-r3.sh` counted any Markdown file quoting `OVERRIDE (OV-04)`, including auditor reports, as a claim. | `ov-allocation-r4.sh` counts only declaring headings in `DECISION.md` files. It has positive and negative controls (10/0/0, `review/evidence/ov-allocation-r4.log`). |
| claude 3 | The "exactly three kinds of line vary" reproducibility rule is false. | Rule rewritten to list tree-census counts, toolchain lines, toolchain-sensitive sizes and two-way rolling counters. The table cell that said `rest-conformance-r2.sh` exits 0 is corrected. |
| claude 5 | Figment's `pushed_at` moved from 2024-09-13 to 2026-09-27. | Re-recorded. The `at-risk` label is reassessed on the new signal and kept, with its ground restated. `serde-env` and `config` repository figures are refreshed. |

**Revision 3 corrected how this item's override number is justified, and reported a defect
in revision 2's own evidence. Nothing in the conformance pass moved.** The recommendation,
both moves, `OVERRIDE (OV-04)`'s argument and options, the rule-by-rule table, the
acceptance criteria and every parameter line are revision 2's, unchanged.

Two things happened after revision 2 landed at commit `d36492b`, and neither is something
revision 2 could have known:

| What | Consequence for this decision |
|---|---|
| **R80 revision 2 allocated `OV-04` at the same time**, by the same kind of "next free number" search, in the same shared worktree. The controller recorded the clash and resolved it (`docs/planning/p02/execution-ledger.md`): "OVERRIDE NUMBER COLLISION, 2026-09-18 … Resolution: OV numbers are allocated by the controller from now on", with an allocation table giving "OV-04 R77 revision 2 (R8.1 plaintext listener; committed first, keeps the number)" and "OV-05 R80 (renumbered from OV-04 in a revision 3)". R80's revision 3 has since landed (commit `53b13f45`; R80 is not published) carrying `OVERRIDE (OV-05)`, and it names `OV-04` only when recounting the collision. | **The number does not change — R77 keeps `OV-04`.** What changes is its ground: revision 2 justified it by a search of the tree, and the correct justification is now that it is **allocated by the controller**. Revision 2's sentence claiming the number was "unused elsewhere" is superseded, because two files outside this item legitimately name it: R80's record of its own renumber, and the ledger's allocation table. |
| **Re-running revision 2's own script after it was committed exposed a vacuous check.** Its OV check excluded `runs/R77/` from a path it had never resolved — `"$run/../../../.."` — so every candidate path began `…/runs/R77/<run-id>/review/evidence/../../…` and the exclusion discarded **all** of its input. The check reported PASS against an empty set: it **could not fail, and revision 3 says so** rather than quietly repairing it. | `review/evidence/ov-allocation-r3.sh` **reproduces the defect** — it runs revision 2's exact expression, shows three files matching and zero surviving the exclusion — and then runs the corrected search on a fully resolved root, which sees the two outside holders. Revision 2's script is **not edited**: it remains the record of what revision 2 checked. It exited 0 at 91/0/0 against revision 2; against any later title it reports 90/1/0 (see `## Empirical check`); and one of its 91 checks is the one this script supersedes. |

Neither correction touched a figure, a probe, a quotation of the standard, or a rule
disposition. Revision 2 reached the right number for a reason that was not sound and
proved it with a check that was not a check; revision 3 kept the number and replaced the
reason. Revision 3's own census then proved too broad (claude finding 2 above), and
revision 4 narrows it to declarations.

**Revision 2 answers one new binding input: owner ruling W2-REST.** On 2026-09-18 the
owner ruled (`docs/port/OWNER-REVIEW.md`, "2026-09-18 — the REST API Design Standard
binds the HTTP surface (W2-REST)") that the organisation's REST API Design Standard
v2.0.0 — local clone `/Users/stevemorin/c/rest-standards/rest-api-standard.md`, commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`, file blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9` — "governs this template's optional HTTP
surface the way the CLI Design Standard (ruling of 2026-09-14) governs its CLI", and
that "Every web item (R70 R72 R73 R74 R76 R77 R80 and the later R71 R83 R84) designs to
the standard, quotes the rules it relies on at their lines, and records any departure as
an `OVERRIDE (OV-nn)` in the shape of the standard's own section 1.9 deviation note."
Revision 1 was written before that ruling. This revision reads the standard at that blob
against this item's `RSLBP_WEB_*` surface, rule by rule.

**The crate recommendation does not move.** No crate is adopted; the settings are still
decoded by the template's own module over `std::env::vars_os` and `str::FromStr`, under a
`const fn`-derived `RSLBP_WEB_` prefix, threaded through the framework's own state
mechanism. Nothing in `## Parameters` moves. What moves is the **naming rule and the
reserved variable set**, in two places, and one departure is recorded:

| What | Disposition |
|---|---|
| **Move 1 — R9.1, the version marker** | The naming rule now forbids any environment variable that carries or overrides the API version, and constrains `RSLBP_WEB_ROOT_PATH` to a mount prefix that never replaces the `/v1` segment. |
| **Move 2 — R8.10's rate-limit axis and R11.2** | The single reserved scalar `RSLBP_WEB_RATE_LIMIT` is withdrawn and replaced by the reserved family `RSLBP_WEB_RATE_LIMIT_*`, whose membership and defaults R74 fixes, with the constraint that no member's default may disable rate limiting. |
| **`OVERRIDE (OV-04)` — R8.1, TLS** | The template's listener is plaintext and this surface ships no TLS setting. Recorded in the shape of the standard's §1.9 deviation note, with its argument and the options weighed. |
| Twelve further rules | Conform as written, three of them as N/A-with-reason under the standard's own §1.8 discipline. The full table is in `#### Conformance to the org REST API Design Standard v2.0.0 (W2-REST)`. |

**Moving a recommendation before acceptance is allowed**, and this revision says so
plainly rather than recording the two moves as deviations: R77 has no owner acceptance
bound to it, so revision 2 states the new, standard-conformant naming rule as the
recommendation rather than shipping revision 1's rule with two exceptions attached.

Revision history: **Revision 6** (2026-09-27, this file) — the flag-day re-copy of
`web-extra-surface` tabulated at the top; the revision-5 text is preserved at
`review/R77-r5-snapshot.md` (sha256
`a3c2dc6ca904b80f8e565f9ad0999cb3a0ab3f78f5d0f9e8d53c1b9d97765b55`).
**Revision 5** (2026-09-27, sha256
`a3c2dc6ca904b80f8e565f9ad0999cb3a0ab3f78f5d0f9e8d53c1b9d97765b55`) — the directed repair of revision 4
tabulated at the top; the revision-4 text is preserved at `review/R77-r4-snapshot.md`
(sha256 `7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884`).
**Revision 4** (2026-09-27, sha256
`7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884`) — the round-1 audit repairs
tabulated at the top, and synthesis of the Muse report; the revision-3 text is preserved
at `review/R77-r3-snapshot.md` (sha256
`5985ee47d5c714fdc317d5b8a8c58aff9c01b3f552834de8ac0b9c5282bb92fd`). Every earlier
evidence file is carried byte-identical and is pinned by sha256 in `r4-checks.sh`.
*Completion note.* The first revision-4 pass was interrupted by a session-usage limit
before it wrote `r4-checks.sh`. A second pass on 2026-09-27 wrote and ran `r4-checks.sh`,
reran the carried `probes.sh` and `ov-allocation-r3.sh` into logs, ran
`ov-allocation-r4.sh`, verified every citation in this file against its file, line and
log, and corrected the `## Empirical check` text the first pass had not reached. The
recommendation is unchanged, and so is the revision number.
**Revision 3** (2026-09-18, commit `1e3cdb5`, sha256
`5985ee47d5c714fdc317d5b8a8c58aff9c01b3f552834de8ac0b9c5282bb92fd`) — the override number is
re-grounded on the controller's allocation and revision 2's vacuous OV check is reported
and superseded by `review/evidence/ov-allocation-r3.sh`; revision 2's four evidence files
and revision 1's ten are carried **byte-identical**, and group C of the new script pins
fourteen of them by sha256 and re-runs the fifteenth. **Revision 1** (2026-09-18, sha256
`b2b2e678a9866fd8f743d2431edcda2dc03a9e4ed03c9670457081360121b546`) — first synthesis
from the single registered Opus report, the Codex leg deferred under `W1-CODEX3`; 239
checks across `figures.sh`, `sources.sh` and `probes.sh`, 0 FAIL, 0 SKIP. **Revision 2**
(2026-09-18, commit `d36492b`) — the W2-REST conformance pass above. Revision 1's four evidence
scripts and six logs are carried **byte-identical and are not re-run**;
`review/evidence/rest-conformance-r2.sh` is the only new check and
`review/evidence/rest-conformance-r2.log` its log, and its group D pins that byte-identity
by sha256. **Revision 2** landed at sha256
`46b2a05f40f6a3ea27b5fdef415c50adccd27ade5ed6fa94f83ed933503d7f68`, commit `d36492b`.

## Decision

**Adopt no new crate for this item.** The web service's runtime settings are decoded
by the template's own module `crates/web/src/settings.rs`, over `std::env::vars_os`
and `str::FromStr`, under the environment-variable prefix `RSLBP_WEB_` derived at
compile time from R57 revision 2's single `TOOL_NAME` constant by a `const fn`
ASCII-uppercase containing no `unsafe`; the resulting `WebSettings` value is
constructed exactly once, in the serve binary, before anything that can log or bind.
Its `log_level` and `log_format` fields are the values R58's logging initialisation
receives, so that initialisation runs second and reads no environment variable itself.
The value reaches request handlers as `Arc<WebSettings>` through the web framework's own
state mechanism — `axum::extract::State` with `FromRef` under R69's accepted stack,
`actix_web::web::Data` or `poem`'s `AddData` under any other.

This is a `crate`-kind item, so the crate rows that make the answer complete:

| Slot | Selection | Version range | Where declared |
|---|---|---|---|
| Reading and decoding the environment | **`std`** — `std::env::vars_os`, `str::FromStr` | the toolchain itself, governed by `msrv-policy`; floor **1.96** against stable **1.98.1** | nowhere — no manifest entry |
| The data model the settings sit beside (HTTP bodies, not the environment) | **`serde`**, `features = ["derive"]` | **`>= 1.0.229, < 2.0.0`** | already non-optional under R69's owned `web-extra-surface`; **this item adds nothing** |
| Environment → struct mapping crate | **none** | — | — |

**Ledger row settled:** `F324` (`docs/port/COMMONALITY.md:328`, *typed env settings with
an app-derived env-var prefix*, origin `py-only`, verdict `DIVERGENT`). No other row is
touched. **No `BASELINE-REVIEW:` finding is raised** — `BASELINE-REVIEW:` adjudicates
inherited `COMMON → REUSE` and `ADOPT` rows, and F324 inherits nothing. **No `CONFLICT:`
line is raised**; nothing here needs a consumed parameter to change.

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. What P03 must validate is listed under
`## Engines`. A decision that does not survive implementation is revised against this
recorded research, not researched again from scratch.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

> **Principle (F324).** The web service's runtime knobs are a *single typed value*,
> resolved *once at process start*, from the *environment only*, under a prefix
> *derived from the one app-name constant* — so a fork's rename carries without editing
> call sites, a misconfigured deployment fails loudly at boot instead of silently at
> request time, and no request handler ever reads the environment.

Source: py at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
`src/py_launch_blueprint/web/settings.py`. Its own module docstring states the intent —
"Every knob resolves from an env var with the ``<APP_NAME>_WEB_`` prefix (derived from
the single ``APP_NAME`` source in ``core/paths.py``, so a fork's rename keeps working).
Validation happens at construction, so a misconfigured deployment fails loudly at boot
instead of silently at request time." — and line 38 is
`ENV_PREFIX: str = f"{APP_NAME.upper()}_WEB_"`, with `APP_NAME = "plbp"` at
`core/paths.py:58` in the same pin. Both lines and the docstring are asserted in
`review/evidence/sources.log`.

**Agreement level: architectural pattern and policy — not library, and not the wire
encoding of individual values.**

| Must agree (pattern / policy) | May vary (ecosystem-native) |
|---|---|
| Web knobs come from the environment, never from the CLI's config file | which crate or standard-library facility decodes them |
| One typed value, constructed once at the composition root | whether decoding is derive-driven or hand-written |
| The prefix derives from the single app-name constant | how the derivation is spelled (f-string, `const fn`, code generation) |
| Construction fails loudly, at boot, naming the offending variable | the concrete error type and the message wording |
| The value reaches handlers through the framework's own state/DI mechanism, never a global | `Depends`/`app.state` in FastAPI, `State`/`FromRef` in axum |
| No secret is a field of this object | — |
| An exported-but-empty variable means unset (the default stands) | — |
| List-valued knobs have **one documented encoding** | **which** encoding (py's JSON, Rust's comma-separated) |

**ts is not a harmonization target for this row, and the reason is structural rather
than a preference.** `git ls-tree -r --name-only cb1cbcb2e88b898e8c081b0abbfabc1630079c00`
in `ts-launch-blueprint` lists no `web/` or `server/` source path — re-run in
`review/evidence/sources.log`, which asserts a match count of **0**. That absence is
what ledger row F303 (`docs/port/COMMONALITY.md:307`, *web service exists at all*,
origin `py-only`) records, and `TS_PORT_DECISIONS.md` has no entry on the subject.
There is no ts `WebSettings` to agree or disagree with. The rationale this item supplies
for the follow-on ts project is therefore forward-looking: if ts later grows a web
service it should realize the same *pattern* with its own idiom — a `zod` schema over a
small reader that takes an injected `Record<string, string>` rather than reaching
`process.env` inside the schema, with the prefix built from ts's own app-name constant —
and should not import py's library choice, because `pydantic-settings` has no ts
equivalent whose tradeoffs match. The divergence analysis marked this row
`harmonize: no`; this decision reaches the same label on reasoned ground rather than by
inheriting it: the pattern is shared and should be stated in all three repositories'
documentation, while the mechanism is ecosystem-bound in each.

**Whether the inherited pattern still holds in Rust — checked, not assumed. Two halves,
and only one of them ports.**

*The env-only, prefix-derived, boot-validated settings object ports, and is
strengthened.* The 12-factor argument that motivates it ("An app's config is everything
that is likely to vary between deploys"; "The twelve-factor app stores config in
environment variables" — `https://12factor.net/config`, retrieved 2026-09-18) is
language-neutral, and the org CLI Design Standard v1.4.14 independently **requires** the
prefix: `R5.4` at line 321 of blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` reads
"Environment variables **MUST** use the uppercase `TOOL_*` prefix with a deterministic
mapping … Only a **curated subset** of settings **SHOULD** read from the environment …
and the tool **MUST NOT** auto-expose every flag as an env var." Rust adds a property py
cannot have: the settings type can be made unconstructible except through the loader, so
"validated at construction" is enforced by the type system rather than by convention.

*py's lazy-load fallback does not port, and has already been adjudicated elsewhere.*
py's `web/deps.py` re-loads configuration when the lifespan has not run — "Falls back to
loading lazily when the lifespan hasn't run (raw ASGI callers like schemathesis)". R69
revision 10 raised and carries `BASELINE-REVIEW: F330` against exactly that, on the
ground that axum 0.8.9 makes the unconfigured state unrepresentable because
`with_state` is what turns a `Router<S>` into a service. **This item does not re-raise
that finding; the design satisfies it**: `WebSettings` has no lazily-loadable global, no
`OnceLock` and no default-on-read path, and the only way a handler sees one is through
`AppState`, which `build_router` requires.

#### Architectural alternatives, compared before any library was chosen

| # | Shape | Verdict |
|---|---|---|
| **A1** | **One layering engine owns web settings too** — `figment` or `config` takes defaults → file → env and produces `WebSettings`. This is the owner-reference C9 shape. | **Rejected.** It adds a *file* tier the surface does not have, and it collides with R54 revision 3 (owner-accepted), which rejected exactly this engine for the CLI because "It takes ownership of three things already decided elsewhere: the parse (R52's `toml` 1.1.6), the typed pass (R53's per-key loop over `toml::Table`, `D06`), and the per-layer sanitize step and warning list (R55, `D01`, `D03`)". Adopting it for the web surface alone would put a rejected engine in the dependency tree for a surface that needs none of its layering. |
| **A2** | **Web settings reuse the CLI's `Config`** — one type, one loader, `RSLBP_*` for everything. | **Rejected.** It breaks `R5.4`'s curated-subset rule (host, port, drain deadline and log format would become either CLI flags, which R69's `R4.1` table forbids on the serve binary, or unbacked variables in the CLI's namespace); it puts a token field beside web knobs, contradicting R56 revision 2; and it makes `--config` on the serve binary silently able to set a listen address, which `R5.2`'s file semantics were never meant to carry. |
| **A3** | **Two settings objects in disjoint namespaces** — `WebSettings` env-only under `RSLBP_WEB_`, and the core `Config` from R53/R54/R55 through the same composition root the CLI uses; the serve binary builds both. | **Selected.** It is py's actual shape (`create_app` takes `WebSettings`; `_lifespan` calls `load_config()`), and it keeps each surface's rules intact. `--config` on the serve binary binds the **core** `Config`'s file, exactly as `R5.2` describes, and touches no web knob. |
| **A4** | Inside A3: **(a)** a serde `Deserializer` over the environment via a derive, versus **(b)** an explicit per-field parse naming each variable and parsing it with `FromStr`. | **(b) selected**, and this is the sub-choice a reasonable owner could weigh the other way. (b) yields an exact error per field, is trivially injectable, and makes the curated set literally readable in one function. (a) is shorter to write and harder to drift. The measured error strings below are the ground for choosing (b). |

#### How the recommended design preserves each principle

```rust
// crates/web/src/settings.rs — illustrative. P03 writes the real thing.
#![forbid(unsafe_code)]
use std::{collections::HashMap, ffi::OsString, net::IpAddr, time::Duration};

use crate::TOOL_NAME;                       // R57 revision 2's one segment: "rslbp"

const SUFFIX: &str = "_WEB_";
const PREFIX_LEN: usize = TOOL_NAME.len() + SUFFIX.len();

const fn upper_concat<const N: usize>(name: &str, suffix: &str) -> [u8; N] {
    let (n, s) = (name.as_bytes(), suffix.as_bytes());
    let mut out = [0u8; N];
    let mut i = 0;
    while i < n.len() { out[i] = n[i].to_ascii_uppercase(); i += 1; }
    let mut j = 0;
    while j < s.len() { out[i + j] = s[j].to_ascii_uppercase(); j += 1; }
    out
}
const PREFIX_BYTES: [u8; PREFIX_LEN] = upper_concat::<PREFIX_LEN>(TOOL_NAME, SUFFIX);

/// `"RSLBP_WEB_"`, derived at compile time from the one app-name constant.
pub const WEB_ENV_PREFIX: &str = match core::str::from_utf8(&PREFIX_BYTES) {
    Ok(s) => s,
    Err(_) => panic!("app name must be ASCII"),
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WebSettings {
    pub host: IpAddr,
    pub port: u16,
    pub graceful_shutdown: Duration,
    pub readiness_pause: Duration,          // spent from graceful_shutdown; < it
    // log_level / log_format: named here, valued by R58, handed to telemetry::init
    // cors_origins, one field per RSLBP_WEB_RATE_LIMIT_* member R74 publishes,
    // idempotency_*, metrics_enabled, otel_enabled, root_path: named here,
    // semantics owned by R69 and R72-R80. No field carries an API version: see
    // Move 1 under "Conformance to the org REST API Design Standard".
}

impl WebSettings {
    /// The whole surface. `from_env` is the only caller that touches the process.
    pub fn from_vars<I>(vars: I) -> Result<Self, SettingsError>
    where I: IntoIterator<Item = (OsString, OsString)> { /* ... */ }

    pub fn from_env() -> Result<Self, SettingsError> { Self::from_vars(std::env::vars_os()) }
}
```

- *Derived prefix.* `WEB_ENV_PREFIX` is a `const` computed from `TOOL_NAME` by a
  `const fn` containing no `unsafe`. **Re-verified in this run** (`probes.log`, P1): it
  compiles and evaluates on stable 1.98.0 under edition 2024 and under
  `#![forbid(unsafe_code)]`; a fork changing the app-name constant to `"acme"` and
  nothing else yields `"ACME_WEB_"`. The const path exists because
  `core::str::from_utf8` is const-stable, and the `match`/`panic!` form replaces
  `unwrap`, which is not const.
- *One value, once, at the composition root.* `from_env()` is called exactly once, in
  the serve binary, before the router exists. R69 revision 10's `AppState` holds it as
  `Arc<WebSettings>` and `impl FromRef<AppState> for Arc<WebSettings>` lets a handler
  write `State(cfg): State<Arc<WebSettings>>`. **Re-verified against real axum 0.8.9**
  (`probes.log`, P4).
- *Fails loudly, naming the input.* See the measured error table below. The failure maps
  to R67's published `RSLB203` ("config value invalid" → exit `2`) with no translation
  layer, because `SettingsError` carries `var`, `value`, `expected` and `cause` — exactly
  the material R67's envelope says `hint` "must be able to name the offending input per
  R7.6".
- *No handler reads the environment.* `std::env` appears once in the whole `crates/web`
  member, inside `from_env`. A CI grep or a `clippy` deny can enforce it (AC7, proposed).
- *No secret field.* R56 revision 2 (owner-accepted) fixes the credential chain as
  `--token-file` > `RSLBP_TOKEN` > stored credential and rules the config file out as a
  token source. `WebSettings` declares no credential of any kind, so 12-factor's litmus
  test ("whether the codebase could be made open source at any moment, without
  compromising any credentials") holds for the whole web surface and `R5.6`'s redaction
  obligation has nothing to redact in this object. The token stays with the core
  resolver, which the serve binary builds through the same composition root the CLI uses.
- *An exported-but-empty variable is unset.* `Some(raw) if raw.is_empty() => Ok(default)`.
  F242 fixes this rule for the token; applying it to every `RSLBP_WEB_*` variable is a
  consistency choice **this item makes**, not an inherited requirement. **Re-verified**
  (`probes.log`, P4 `unprefixed_and_empty_are_ignored`).

#### Measured: the error shape for a malformed variable

One input — `RSLBP_WEB_PORT=eighty`, everything else valid — through every candidate.
Each `Display` string below was re-executed in this run and is asserted verbatim in
`review/evidence/probes.sh` (P3.1–P3.5); `probes.log` carries the output.

| Mechanism | `Display` for `RSLBP_WEB_PORT=eighty` | names the variable? | the value? | the expectation? |
|---|---|---|---|---|
| **template code** | `RSLBP_WEB_PORT: invalid value "eighty": expected a TCP port in 0..=65535 (invalid digit found in string)` | **yes, in full** | yes | **domain-level** |
| `confique` 0.4.0 | ``failed to deserialize value `WebSettingsC::port` from environment variable `RSLBP_WEB_PORT`: invalid value 'eighty' for type u16: invalid digit found in string`` | **yes, in full** | yes | the Rust type `u16` |
| `figment` 0.10.19 | ``invalid type: found string "eighty", expected u16 for key "PORT" in `RSLBP_WEB_` environment variable(s)`` | yes (prefix + key, separately) | yes | the Rust type `u16` |
| `config` 0.15.25, and 0.15.26 identically (`probes-r4.log` P3r4.1) | ``invalid type: string "eighty", expected an integer for key `port` in the environment`` | **no** — a lowercased key `port` | yes | "an integer" |
| `envy` 0.4.2 | `invalid digit found in string while parsing value 'eighty' provided by PORT` | partial — `PORT`, no prefix | yes | **none** |

The `confique` row names the struct as the probe declared it (`WebSettingsC`); the
struct name is the probe's, the rest of the string is the crate's. `config`'s message is
the weakest of the five for this purpose: an operator reading the key name `port` must
know the crate's lowercasing rule to recover `RSLBP_WEB_PORT`.

#### Measured: testability under edition 2024, and the injection seam

`std::env::set_var("RSLBP_WEB_PORT", "8000")` in an edition-2024 crate fails to compile
with ``error[E0133]: call to unsafe function `set_var` is unsafe and requires unsafe
block``. **Re-verified with a control** (`probes.log`, P2): the identical source compiles
and runs under edition 2021, so it is the edition — not a change of API — that converts
the call into an `unsafe` one. The Rust project's own edition documentation gives the
reason: "It can be unsound to call `std::env::set_var` or `std::env::remove_var` in a
multithreaded program due to safety limitations of the way the process environment is
handled on some platforms"
(`https://doc.rust-lang.org/edition-guide/rust-2024/newly-unsafe-functions.html`,
retrieved 2026-09-18).

That is not a style point. It makes the loader's *signature* a design decision: a loader
that can read only the real process environment cannot be unit-tested by template code
that honours R06's unsafe policy, and process-wide environment mutation is in any case
order-dependent under `cargo test`'s thread-parallel harness.

**Re-verified, and sharper than the raw report stated it** (`probes.log`, P3 run 2): with
the process environment *clean* and the malformed value present only in an injected map,
template code, `envy` and `config` all report the error, while `figment` and `confique`
silently return their defaults — they never saw the injected map at all.

| Mechanism | Injected variable set? | Evidence |
|---|---|---|
| **template code** | **yes** — `from_vars(impl IntoIterator<Item = (OsString, OsString)>)` | P4: four tests pass, none touching the process environment |
| `envy` 0.4.2 | yes — `from_iter` free and prefixed | `envy-0.4.2/src/lib.rs:301` and `:324`; measured working (P3.8) |
| `config` 0.15.25 and 0.15.26 | yes — `Environment::…​.source(Some(HashMap))` | measured working (P3.9; for 0.15.26, `probes-r4.log` P3r4.3) |
| `confique` 0.4.0 | **no** — `pub fn env(mut self) -> Self` takes no argument, and the generated code calls `std::env::var($key)` | `confique-0.4.0/src/builder.rs:38`, `src/internal.rs:54`; measured ignoring the map (P3.11) |
| `figment` 0.10.19 | **no** — only `Env::raw()` / `Env::prefixed()`, both reading `std::env::vars_os()` | `figment-0.10.19/src/providers/env.rs:171`, `:198`, `:505`; measured ignoring the map (P3.10). Its test story is `figment::Jail`, behind the non-default `test` feature, which calls `std::env::set_var` itself at `src/jail.rs:353` and serialises tests behind a lock |

Every line number in that table was re-read from the local Cargo registry cache at the
exact published version and is asserted in `review/evidence/sources.sh`.

#### Measured: dependency and binary cost

Package counts are `cargo tree --locked -e normal --prefix none | sed 's/ (\*)//' |
sort -u | grep -c .` — the way R56 counts them — over a crate that already has `serde`
with `derive`. Stripped sizes are `cargo build --release` under
`strip = true, opt-level = "z", lto = true, codegen-units = 1, panic = "abort"`,
target `aarch64-apple-darwin`, on 2026-09-18 with `rustc 1.98.0 (88d9e12ae 2026-08-18)`.

| Mechanism | packages (Δ over the 8-package baseline) | stripped size Δ over baseline | what the delta is made of |
|---|---|---|---|
| **template code** | **8 (+0)** | **0 B** (it *is* the baseline) | nothing |
| `envy` 0.4.2 | 9 (+1) | +16,576 B | `envy` alone |
| `confique` 0.4.0 | 12 (+4) | +16,480 B on rustc 1.98.0; +16,496 B on 1.98.1 | `confique`, `confique-macro`, `heck`, `syn` |
| `config` 0.15.25, `default-features = false` | 11 (+3) | +83,200 B | `config`, `pathdiff`, `winnow` |
| `config` 0.15.26, `default-features = false` (revision 4, rustc 1.98.1) | 11 (+3) | +83,200 B | the same three packages |
| `figment` 0.10.19, `features = ["env"]` | 16 (+8) | +99,920 B | `figment`, `pear`, `pear_codegen`, `proc-macro2-diagnostics`, `syn`, `uncased`, `inlinable_string`, `yansi` |
| `config` 0.15.25, **default features** | **55 (+47)** | +132,912 B | adds `json5`, `ron`, `rust-ini`, `yaml-rust2`, `toml`, `serde_json`, `encoding_rs`, `pest` + `pest_derive`, `async-trait`, … |

**Revision 4 re-measured every row** with `review/evidence/probes-r4.sh` group P6r4, on
rustc 1.98.1 on 2026-09-27. Every package count and every size delta above reproduced,
except that `confique`'s delta moved by 16 B with the toolchain patch. P6r4 supersedes
revision 1's P6. Revision 1's P6 read each binary from a fixed path. An inherited
`CARGO_TARGET_DIR` sends the build elsewhere, and P6 then reported the missing binary as
0 B, so its two "under 50 KB" checks passed on nothing (claude audit finding 1). P6r4
fails on a failed build or a missing or empty binary.

**The package counts are the reproducible figures and are asserted individually**
(`probes.sh` P6, and `probes-r4.sh` P6r4). The *size* figures are deltas over a
baseline whose source is in `probes.sh` itself, printed there in one line and asserted
as five thresholds (six in P6r4, which adds `config` 0.15.26 at more than 50 KB):
`config` without default features and `figment` each cost **more than 50 KB** of stripped
binary over hand-written code; `envy` and `confique` each cost **less than 50 KB**;
`config` with default features costs **more than 100 KB**. Absolute byte counts are
specific to this machine, this toolchain, this date and the exact body of the baseline
program; they are reported so the deltas can be read, not as portable constants, and no
absolute figure is asserted anywhere.

Clean release build wall time on the same machine, one sample each: baseline 6.15 s;
`envy` 7.07 s; `confique` 7.30 s; `config` without default features 7.07 s; `figment`
14.11 s; `config` with default features 19.05 s. Only the last figure is treated as a
signal, and only as a ratio — roughly **3×** the baseline. It matters because `config`'s
default feature set pulls four document parsers (`json5`, `ron`, `ini`, `yaml`) into a
binary whose only configuration format is fixed by `R5.2` to TOML and whose web surface
has no file at all. The `figment` figure is a single sample on a machine also running
network polling and is not treated as a finding either way (see `## Engines`).

#### Fitness gates, answered per candidate before popularity was weighed

**Gate 1 (licence) is recorded for every candidate as:
`inapplicable — owner ruling 2026-09-12 (Q7.B)`: licence compatibility is not evaluated
for any dependency or tool** (`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check
for anything the template uses (Q4, superseded and widened by Q7.B)"). Licence strings
below are metadata only and nothing is excluded on them.

**Gate 2 is applied under the strict reading settled 2026-09-11.**
`docs/planning/p02/owner-decisions.md`, "Two things you should know, which are not
decisions", records the owner's provisional lenient ruling, the auditors' argument, and
the outcome: "The ruling is withdrawn. One item's exclusions stand; the other must
switch to the runner-up it already recorded." R69 revision 10 applies it by that name.
The *third*, stricter reading — under which every transitive dependency at every depth
must also declare a version — is the one the same file says "is not on the table unless
you put it there"; it is **not** applied here, which is why `config`'s transitive
dependency **`pathdiff` 0.2.3** (`rust_version: null`,
`GET https://crates.io/api/v1/crates/pathdiff/versions`, retrieved 2026-09-18) does not
exclude `config`. `config`'s other added package, `winnow` 1.0.4, declares `1.65.0`.

**MSRV floor, re-derived in this run rather than carried:** current stable is
**1.98.1 (48a229cea 2026-09-01)**
(`https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust] version`,
retrieved 2026-09-18 and again on 2026-09-27 into `review/evidence/snapshots-r4/`), so
`msrv-policy`'s "stable minus 2 minor versions" puts the floor at **1.96**.

**The table's figures are dated 2026-09-18 unless marked otherwise.** Revision 4
re-fetched the newest non-yanked release of all eleven crates on 2026-09-27
(`review/evidence/drift-r4.sh`). Only `config` moved: 0.15.26 was released on
2026-09-21 and declares `rust-version` 1.88.0. That is still below the 1.96 floor, so
no gate result moves.

| Gate | `std` | `serde` 1.0.229 | `config` 0.15.25 | `confique` 0.4.0 | `envy` 0.4.2 | `figment` 0.10.19 | `envconfig` 0.11.1 | `serde-env` 0.3.0 | `envious` 0.3.0 |
|---|---|---|---|---|---|---|---|---|---|
| **1 · licence** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; metadata `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT` | same ruling; `Apache-2.0` | same ruling; `MIT OR Apache-2.0` |
| **2 · MSRV ≤ 1.96** | `inapplicable` — `std` *is* the toolchain; the floor is `msrv-policy`'s own | declares **1.56** — passes | declares **1.85.0** at 0.15.25; **1.88.0** at 0.15.26, the newest release on 2026-09-27 — passes | declares **1.68.2** — passes | **declares none — fails** | **declares none — fails** | **declares none — fails** | **declares none — fails** | **declares none — fails** |
| **3a · RustSec** | `inapplicable` (not a crates.io package) | no advisory page | no advisory page | no advisory page | no advisory page | no advisory page | no advisory page | no advisory page | no advisory page |
| **3b · `unsafe` posture** | the standard library contains `unsafe`; the recommended module contains none and compiles under `#![forbid(unsafe_code)]` — measured (P1) | **2** `unsafe` blocks in `src/`, both `str::from_utf8_unchecked` — re-audited here, not carried | **0** in `src/`; no crate-level lint | **0** in `confique` and `confique-macro` `src/`; no crate-level lint | **0** in `src/` | **0** in `src/` — but `Jail` mutates the process environment (`src/jail.rs:353`), the hazard edition 2024 marks `unsafe` | **0** in `envconfig` and `envconfig_derive` `src/` | **0** in `src/` | **0** in `src/` |
| **4 · ubuntu-latest + macos-latest** | yes by construction; `std::env::vars_os` and `str::FromStr` carry no platform `cfg` | yes | built here on `aarch64-apple-darwin`; no platform `cfg` on the `Environment` path | built here on `aarch64-apple-darwin` | built here on `aarch64-apple-darwin` | built here on `aarch64-apple-darwin` | fetched, not built here | fetched, not built here | fetched, not built here |
| **5 · default features / async coupling** | none | `derive` only; no runtime | defaults are `toml, json, yaml, ini, ron, json5, convert-case, async` — the `async` default pulls `async-trait`, a proc macro, **not** a runtime; `default-features = false` drops all of it | nothing of consequence; no async coupling | none; no async coupling | `env` pulls `pear` + `parse-value`; `test` pulls `tempfile` + `parking_lot`; no async coupling | edition 2021; derive only | edition 2021 | edition 2021 |
| **6 · binary size / compile time** | **+0 packages, the baseline** | already in the tree; no marginal cost | **+3 packages, +83,200 B** with default features off; **+47 packages and ≈3× clean build** with them on | **+4 packages, +16,480 B** | **+1 package, +16,576 B** | **+8 packages, +99,920 B** | not measured — excluded at gate 2 | not measured — excluded at gate 2 | not measured — excluded at gate 2 |

The RustSec row is a 404 on `https://rustsec.org/packages/<name>.html` for all eight
crates, retrieved 2026-09-18, with `atty` and `time` fetched in the same run as HTTP 200
controls carrying four `RUSTSEC-` mentions each — which is what makes the 404s readable
as "no advisory" rather than as a broken method. Both halves are asserted in
`review/evidence/figures.sh`.

**Excluded by gate, with the ground.**

- **`envy` 0.4.2 — excluded by gate 2.** No declared `rust-version`
  (`GET https://crates.io/api/v1/crates/envy/versions`, newest non-yanked `0.4.2`,
  `created_at` 2021-01-04, `rust_version: null`, retrieved 2026-09-18). Maintenance
  **at-risk**, on the concrete signals the rubric demands: no release in 5 years
  8 months; repository `pushed_at` **2024-06-07**; 14 open issues
  (`GET https://api.github.com/search/issues?q=repo:softprops/envy+is:issue+is:open`,
  `total_count`); `archived: false`; 981 stars. Not `dormant` — it compiles and runs
  correctly on stable 1.98.0, measured here. **This is the crate the prompt's own
  candidate list names first and the one whose shape fits best**; it is excluded on a
  declaration it never made rather than on behaviour, and that is recorded plainly
  because it is the exclusion most likely to be revisited.
- **`figment` 0.10.19 — excluded by gate 2.** No declared `rust-version` (same endpoint,
  newest non-yanked `0.10.19`, `created_at` 2024-05-17, and still the newest on
  2026-09-27). Maintenance **at-risk**. The signals: no release in 2 years 4 months;
  21 open issues; 913 stars; `archived: false`; and 1 of 10 recent issues answered, with
  a 185-day median first response. The Opus report measured that last figure, and the
  Muse report measured it independently on 2026-09-25 (`raw/muse.md:88`). On 2026-09-18
  the repository's `pushed_at` was **2024-09-13**. On 2026-09-27 it was
  **2026-09-27T00:54:08Z** (claude audit finding 5). Revision 4 checked what that push
  was. The commits endpoint lists **zero** commits on the default branch since
  2024-09-14 (`review/evidence/snapshots-r4/gh-commits-SergioBenitez__Figment-since-2024-09-14.json`).
  `pushed_at` moves on a push to *any* branch, so the renewed timestamp is not release
  or mainline activity, and the label stands. A new `figment` release is a re-verify
  trigger. It builds and runs on stable 1.98.0, measured. **This is the row the
  owner-supplied reference architecture names for C9**, which is why the exclusion is
  argued below on three independent grounds rather than on the gate alone.
- **`envconfig` 0.11.1 — excluded by gate 2** (no `rust-version`; released 2025-12-10;
  `greyblake/envconfig-rs`, 232 stars, `pushed_at` 2025-12-10, 6 open issues; maintenance
  **stable-quiet**). Its per-field attribute takes a **string-literal** value and offers
  no prefix support at all, a stricter form of `confique`'s limitation.
- **`serde-env` 0.3.0 — excluded by gate 2** (no `rust-version`; released 2026-04-15;
  `Xuanwo/serde-env`, 25 stars; on 2026-09-18 `pushed_at` 2026-04-15 and 1 open issue,
  on 2026-09-27 `pushed_at` 2026-09-19 and 0 open issues; **stable-quiet**).
- **`envious` 0.3.0 — excluded by gate 2** (no `rust-version`; released 2026-05-29;
  `TheNeikos/envious`, 60 stars, `pushed_at` 2026-05-30, 2 open issues; **stable-quiet**).
- **`dotenvy` 0.15.7 — not excluded by a gate; excluded by category.** It loads a `.env`
  file *into* the process environment and produces no typed value. It composes with the
  recommendation and with every alternative, and P03 may adopt it separately for
  developer convenience; it answers none of this item's questions. Its 46,188,632 90-day
  downloads are named here only so a reader does not mistake them for evidence about this
  category.

#### The landscape this decision sits in, and why it has no dominant choice

The category is not "a config crate". It is precisely: *the mechanism that turns the
process environment into one typed, validated Rust value for the optional `web` surface,
under a prefix derived from the single app-name constant, plus the path by which that
value reaches request handlers.* Three properties make it its own category: it is
**env-only** (R69's owned value puts every service knob in an environment variable and
gives the serve binary no flags for them); it must be **constructible from an injected
variable set** (edition 2024's `unsafe set_var`); and its failure message must **name the
offending variable, its value and the expectation** (R67's `hint`).

- **Bin 1 — built-in or first-party toolchain.** `std::env::vars_os` / `var_os` plus
  `str::FromStr`, with the template writing the mapping. `serde` 1.0.229 sits beside it
  as an already non-optional dependency, but it is a *data-model* crate, not an
  environment reader.
- **Bin 2 — established industry standard.** `config` 0.15.25, and 0.15.26 since
  2026-09-21 (maintained in the
  `rust-cli` GitHub organisation, which also hosts `clap`, the parser R60 selected);
  `figment` 0.10.19 (the engine Rocket is built on, by Rocket's author); `envy` 0.4.2
  (the original serde-over-environment idiom); `envconfig` 0.11.1.
- **Bin 3 — up-and-comers.** `confique` 0.4.0 (derive macro, per-field
  `#[config(env = "…")]`, layered, generates a reference config file); `serde-env` 0.3.0;
  `envious` 0.3.0 (nested structures from flat variables).

| Crate | 90-day downloads | all-time | what it actually dominates |
|---|---|---|---|
| `config` 0.15.25 | 18,581,807 | 114,271,945 | layered multi-format configuration |
| `figment` 0.10.19 | 10,072,166 | 38,648,096 | layered configuration, chiefly through Rocket |
| `envy` 0.4.2 | 3,574,490 | 20,877,399 | the thin serde-over-environment idiom — the closest fit, and the least maintained |
| `envconfig` 0.11.1 | 1,472,437 | 10,008,963 | per-field derive over the environment |
| `serde-env` 0.3.0 | 944,262 | 2,883,110 | environment → serde with nesting |
| `confique` 0.4.0 | 158,359 | 490,326 | per-field derive, layered, generates a reference config file |
| `envious` 0.3.0 | 66,319 | 570,440 | nested structures from the environment |

All figures: `GET https://crates.io/api/v1/crates/<name>`, fields
`crate.recent_downloads` and `crate.downloads`, retrieved 2026-09-18; each is asserted
against a committed snapshot in `review/evidence/figures.sh`.

**There is no dominant choice, and that is the finding.** Read as a field map rather than
a leaderboard, the category has a hole exactly where this item sits: the crates *shaped*
like the requirement (thin env-only mappers) are small and lightly maintained, and the
crates *maintained* like infrastructure are layering engines whose extra tier this
surface must not have. Rust has no `pydantic-settings`. That is why the recommendation is
a design rather than a purchase.

**Practice evidence.** Adoption was confirmed in the raw report through
`GET https://crates.io/api/v1/crates/<adopter>/<version>/dependencies` rather than
asserted: `config` `^0.15.25` is a required normal dependency of `nextest-runner`
0.124.0 (the library behind `cargo-nextest`) and `leptos_config` 0.8.10, and is used by
`deadpool` and `rumqttd`; `figment` `^0.10.18` is a required dependency of `tor-config`
0.46.0 (the Tor Project's Arti — genuinely independent of figment's author, unlike
`rocket` 0.5.1, which shares its maintainer) and of `apple-codesign`, `pijul` and
`taplo-lsp`; `envy` `^0.4.2` is a **build** dependency of `esp-idf-sys` 0.38.1 and a
normal dependency of `axum-client-ip` 1.3.1; `confique` `^0.4` is a required dependency
of `mise` 2026.9.11. **What the practice evidence does not show:** no surveyed project
uses any of these crates to do what this item needs. `config`'s and `figment`'s adopters
use them for layered file-plus-environment configuration, which is R54's problem;
`envy`'s most prominent adopter uses it in a build script.

**Issue responsiveness** (10 most recently opened issues per repository, first response
by a maintainer-class author) is carried from the raw report and was **not** re-sampled
here — see `## Engines`. It recorded `rust-cli/config-rs` 9 of 10 answered, median 0.22
days; `LukasKalbertodt/confique` 7 of 10, median 68.06 days, strongly bimodal;
`softprops/envy` 1 of 10, 73.42 days; `SergioBenitez/Figment` 1 of 10, 185.0 days. Those
figures are the ground for `envy` and `figment` being recorded `at-risk` rather than
merely quiet, and for `confique` being `stable-quiet` rather than `at-risk`.

#### Why the recommendation is no crate, and not the crate the prompt names first

Five grounds, in order of force, each resting on something measured in this run or on an
owner-accepted decision:

1. **The gate eliminates the whole matching bin.** Every crate whose *shape* matches this
   requirement — `envy`, `envconfig`, `serde-env`, `envious` — and the reference
   architecture's `figment` all fail fitness gate 2, because not one declares a
   `rust-version`. The two survivors are layering engines. Recommending a layering engine
   for an env-only surface is a strictly worse answer than writing the forty lines.
2. **Edition 2024 turned the loader's signature into a design decision.** A loader taking
   `impl IntoIterator<Item = (OsString, OsString)>` is testable by ordinary safe code, in
   parallel, with no global lock; a loader that reads only the real process environment is
   not. `confique` and `figment` offer no seam, measured; `config` does, but only
   alongside everything else it brings.
3. **The error message is the deliverable, not a detail.** R67 requires `hint` to name the
   offending input. The template's own parse produces the full variable name as the
   operator typed it, the value, and a *domain* expectation ("a TCP port in 0..=65535")
   rather than a Rust type name. `config`'s best effort is ``key `port` in the
   environment``. No translation layer is needed to reach `RSLB203` and exit `2`.
4. **The derived prefix survives.** F324's whole point is that a fork's rename carries.
   `envy`, `config` and `figment` take the prefix as a runtime string, so a derived
   `const` works with them; `confique` and `envconfig` require a literal per field, and a
   fork would have to edit one attribute per field, about fifteen. **Re-verified** (`probes.log`, P5):
   `#[config(env = ENV_PORT)]` with `const ENV_PORT: &str` is rejected at compile time
   with `error: expected string literal`.
5. **It is the house shape, and consistency here has a concrete payoff.** R53 revision 2
   chose `serde` and no validation crate; R54 revision 3 chose a six-rung chain with no
   layering crate and no new dependency; R55 revision 3 sanitizes per layer in template
   code; R56 revision 2 uses `std::os::unix::fs` directly. A reviewer reading
   `crates/web/src/settings.rs` after reading the CLI's config module meets the same
   idiom, and a template whose product *is* the readable example teaches one pattern
   rather than two.

**The cost, stated so it is not discovered later.** Roughly one `FromStr` arm per field,
about fifteen of them (eleven py-derived scalars, one per rate-limit member R74 publishes,
and the readiness pause), each about three lines; a `Default` impl; and a test per field. That is
the price of the error message, the test seam and the zero dependency. It is also code
the template exists to show rather than code the template hides.

#### Ranked runner-up, and the condition under which it wins

**`config >= 0.15.25, < 0.16.0` with `default-features = false`, used only for its
`Environment` source**, with the prefix supplied from the same derived `WEB_ENV_PREFIX`
const and the struct deserialized by `serde`:

```rust
let settings: WebSettings = config::Config::builder()
    .add_source(config::Environment::with_prefix(WEB_ENV_PREFIX.trim_end_matches('_'))
        .source(Some(injected)))      // None in production; Some(map) in tests
    .build()?
    .try_deserialize()?;
```

The builder sets **no** `.separator("_")`. The Muse report's loader does set one, and
probe P7 shows the effect with `config` 0.15.26. The separator splits a multi-word
variable such as `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS` into a nested key, so the flat
field silently keeps its default: 3 was set and 8 was read (`probes-r4.log`, P7.2). Without
the separator the value is read (P7.1). The range `>= 0.15.25, < 0.16.0` admits 0.15.26,
the newest release on 2026-09-27. Revision 4 measured it: 11 packages, a +83,200 B
stripped delta, the identical error string, and a working injected source
(`probes-r4.log` P6r4, P3r4). The runner-up's claims therefore hold across the range as
it stands.

It wins if either of two things turns out to be true in P03:

- **the field set grows past hand-maintenance** — if R72 to R80 add enough web knobs that
  the roughly fifteen fields become thirty, the per-field arm stops being a readable list and becomes
  a chore, and derive-driven mapping is the better trade; or
- **the web surface acquires a file tier** — if the owner later rules that `--config` on
  the serve binary should reach web knobs as well as the core `Config`, this item's
  env-only premise is gone and a layering engine is the right shape. `config` already
  provides the tier, is the engine R54 evaluated in detail (so the comparison is on the
  record), and is the only gate-passing candidate with an injected-source test seam.

**`confique >= 0.4.0, < 0.5.0` is ranked third.** It produces the best library error
message measured anywhere in this run and the smallest gate-passing footprint
(+4 packages, +16,480 B), so it is not rejected on cost. It is ranked below `config` for
one reason that outranks both of its advantages: it has no injected-variable-set seam, so
under edition 2024 the template could not unit-test its own settings loading without
`unsafe`. It wins over `config` only if the owner values the generated reference config
file and the sharper error more than testability — a trade this decision does not
recommend but records as coherent.

#### Tradeoffs

**Versus `config` 0.15.25 — what the recommendation gives up:**

- *A derive instead of about fifteen hand-written arms.* Real. Accepted because the arms are
  where the good error message and the domain-level expectation come from, and because
  fifteen is a number a reader can hold.
- *A file tier ready for free if the surface ever wants one.* Accepted because the surface
  is env-only under R69's owned value, and because adopting an engine for a tier that does
  not exist is the exact mistake R54 declined for the CLI.
- *3,210 stars and 18,581,807 quarterly downloads of maintenance behind the parsing.*
  Accepted because `std::env::vars_os` and `u16::from_str` are maintained by the Rust
  project, and what `config` maintains beyond them is the layering this item does not use.
- *Cost avoided, measured:* +3 packages and +83,200 B stripped with default features off,
  or +47 packages and roughly a 3× clean build with them on.

**Versus `confique` 0.4.0 — what the recommendation gives up:**

- *A marginally more precise error* (a struct field path beside the variable name).
  Accepted; the template's message already carries the variable, the value and a better
  expectation, and the field path is recoverable from the variable name.
- *A generated reference configuration file.* Real and genuinely useful for documentation.
  Accepted because it documents a *file* this surface does not have; the equivalent
  artifact here is a table in the web documentation listing every `RSLBP_WEB_*` variable
  and its default, which a test can check against the struct (AC9, proposed).
- *Nothing on dependency cost.* `confique` measured +4 packages and +16,480 B, close to
  `envy`'s +16,576 B, so this is not a cost-based rejection. It is rejected on the derived
  prefix (literal-only attribute, measured) and on testability (no injected source,
  measured).

**Versus `envy` 0.4.2 — recorded even though gate 2 already excluded it:**

- *The shortest possible code.* `envy::prefixed(WEB_ENV_PREFIX).from_iter(vars)` is one
  line, keeps the derived prefix, and has the injected-iterator seam. It is the closest
  shape to `pydantic-settings` in the whole Rust field. **If the owner ever strikes gate 2
  the way gate 1 was struck, it deserves re-evaluation as the primary** — with its
  maintenance signals weighed openly (no release since 2021-01-04, no commit since
  2024-06-07, 1 of 10 recent issues answered) and with the knowledge that its error
  message names `PORT`, not `RSLBP_WEB_PORT`.

**Versus `figment` 0.10.19 — what is given up:**

- *Agreement with the owner-supplied reference architecture's C9 row.* This is the most
  significant cost in this decision and the one a reviewer should check hardest. It is
  accepted on three independent grounds, each re-verified in this run, any one of which
  would stand alone: the gate-2 failure (`rust_version: null` at the versions endpoint);
  the absent injected source under edition 2024's `unsafe set_var`
  (`src/providers/env.rs:505`, and measured returning defaults from a clean environment);
  and the file tier this surface does not have.

#### Fit for this template

**CLI (`crates/cli`, binary `rslbp`).** Nothing from this item ships in it. The CLI's
environment tier is R54's: `RSLBP_*` through the parser R60 selected, over the six-rung
`R5.1` chain with three file tiers. The two namespaces are disjoint by construction —
every variable this item names carries the `_WEB_` segment, so `RSLBP_CONFIG` (R54) and
`RSLBP_TOKEN` (R56) can never collide with a web knob, and no web knob can be set by a
CLI flag. `R5.4`'s curated-subset **MUST NOT** ("the tool **MUST NOT** auto-expose every
flag as an env var") is satisfied in the strongest available way on the web side: the
serve binary has **no flags at all** for service knobs, so nothing can be auto-exposed,
and the curated set is literally the field list of one struct in one file.

**Library (`crates/core`).** Nothing from this item ships in it either, and that is a
positive requirement rather than an absence: the core library must contain no `std::env`
call — it receives values. Keeping `WebSettings` in `crates/web` is what makes that
checkable with a one-line grep (AC7b, proposed), and it is consistent with R67's rule
that the library crate "must install no signal handler or panic hook, and must write to
no process stream or file".

**Web (`crates/web`, plus the root package's serve binary).** This is the whole of the
item. `crates/web/src/settings.rs` holds `WEB_ENV_PREFIX`, `WebSettings`,
`SettingsError`, `from_vars` and `from_env`. `src/bin/rslbp-serve.rs` calls `from_env()`
once, before anything that can log or bind, maps a failure to `RSLB203` / exit `2`, then
builds `AppState { config: Arc::new(settings), projects: … }` and hands it to
`build_router`. Handlers reach it as `State(cfg): State<Arc<WebSettings>>` through
`impl FromRef<AppState> for Arc<WebSettings>`. Because the whole member is optional under
R69 revision 10's `web = ["dep:rs-launch-blueprint-web"]`, no `#[cfg(feature = "web")]`
appears inside the file, and with the feature off neither the settings type nor the
environment read exists in the binary at all.

**The start of `main`, reconciled with R58.** R58's revision 1 (in the working tree, not
yet accepted) also claims the serve binary's first statement. Its migration table says:
"first statement of `main`: `telemetry::init(Profile::Service { .. })` with level and
format from `RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT`"
(`research/runs/R58/2026-09-18T215915Z-184041b91674/review/DECISION.md:1405`). If
telemetry read those two variables itself, the environment would have a second reader.
That would break this item's "one value, once" rule and AC7. The handshake is:

1. `WebSettings::from_env()` runs first. It writes to no stream and emits no log event.
   On failure, `main` renders R67's stderr envelope directly, which needs no logging
   pipeline.
2. `telemetry::init(Profile::Service { .. })` runs second. It receives
   `settings.log_level` and `settings.log_format` as arguments and reads no environment
   variable.

R58 keeps everything it owns: the value sets for both variables, the parse from string
to its level and format types (a `FromStr` that `from_env` calls, so a bad value fails as
`RSLB203` like any other), and the initialisation. Only the *order* and the *source*
of those two values are this item's. This is a request to R58, recorded as AC16 and
as a re-verify trigger.

**Framework-agnostic, as the prompt requires.** The settings value is a plain `Clone`
struct behind `Arc`. In `axum` it enters via `State`/`FromRef` — measured against real
axum 0.8.9 in this run. In `actix-web` the same `Arc<WebSettings>` enters via
`App::app_data(web::Data::from(settings))` and is extracted as `web::Data<WebSettings>`.
In `poem` it is `AddData`. In every case the parsing lives outside the framework and the
framework only carries a value, which is exactly why `from_env()` is called at the
composition root rather than by the framework. That is also py's shape:
`create_app(settings: WebSettings | None = None)` takes the value.

#### The variable set, and who owns each value

The **naming rule** and the **mechanism** are this item's for every knob:
`<WEB_ENV_PREFIX><FIELD_IN_SCREAMING_SNAKE_CASE>` — `RSLBP_WEB_HOST`, `RSLBP_WEB_PORT`,
`RSLBP_WEB_ROOT_PATH`, `RSLBP_WEB_LOG_LEVEL`, `RSLBP_WEB_LOG_FORMAT`,
`RSLBP_WEB_CORS_ORIGINS`, `RSLBP_WEB_METRICS_ENABLED`, `RSLBP_WEB_OTEL_ENABLED`,
`RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS`, `RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES`,
`RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`, plus the reserved family
`RSLBP_WEB_RATE_LIMIT_*`. Those eleven names plus that family cover the twelve-field set
py declares at `web/settings.py` in pin `b08bccfb`, renamed by the rule; py's field count
is asserted in `review/evidence/sources.sh`. Revision 4 adds one name py does not have,
`RSLBP_WEB_READINESS_PAUSE_SECONDS` (see `#### The readiness-propagation pause`).

**The `WebSettings` field count is eleven py-derived scalar fields, plus one field per
rate-limit member R74 publishes, plus the readiness pause.** R74 owns the membership.
R74's revision 2, in the working tree and not yet accepted (sha256
`68e19cf3d99567dce2b6864ac968d652f1ae93d116c5f43e187fac82fbb6e246`), fixes three members
(`research/runs/R74/2026-09-18T215916Z-14066395aaea/review/DECISION.md:511-513`), argues
why at `:515`, and hands this item "Three fields for the `RSLBP_WEB_RATE_LIMIT_*` family"
(`:560`). If that
holds, the struct has fifteen fields. Revision 3 said py's single `rate_limit` field
would stay one typed field; R74 made each member its own field, and that is R74's call.
The hand-maintenance cost argued in `#### Tradeoffs` is restated at fifteen and still
holds; the runner-up's trigger is thirty.
Two constraints the org REST API Design Standard puts on this rule, argued in full under
`#### Conformance to the org REST API Design Standard v2.0.0 (W2-REST)`:
the version marker is never an environment variable (Move 1), and
no member's default may disable rate limiting (Move 2). The **values and semantics** are not all this item's:

| Knob | Value decided here | Owner of the semantics |
|---|---|---|
| `HOST`, `PORT` | `127.0.0.1`, `8000` — py's defaults, ported unchanged; loopback by default so a container must opt into `0.0.0.0` | this item |
| `GRACEFUL_SHUTDOWN_SECONDS` | **8**, not py's 10 — argued below | this item (the mechanism is R69's) |
| `READINESS_PAUSE_SECONDS` | **0**, and strictly less than `GRACEFUL_SHUTDOWN_SECONDS` — argued below; not a py knob | this item (the latch and the pause mechanism are R80's) |
| `LOG_LEVEL`, `LOG_FORMAT` | **not decided** — named only | R58 (`logging-pipeline-contract`, registry value `—`, unpublished) |
| `CORS_ORIGINS` | **not decided** — named only; its *encoding* is fixed below | R76 |
| `RATE_LIMIT_*` (the reserved family) | **not decided** — named only. The members, their units and their defaults are R74's. This item hands R74 R8.10's rate-limit dimensions as input and sets no floor on the member count | R74 |
| `IDEMPOTENCY_TTL_SECONDS`, `IDEMPOTENCY_MAX_ENTRIES` | not decided | R73 |
| `METRICS_ENABLED` | not decided | R79 |
| `OTEL_ENABLED` | not decided | R78 |
| `ROOT_PATH` | **not decided as a value**; constrained here to a deployment mount prefix that is prepended to, and never replaces, the version segment (Move 1) | R69 / R75 |

**The drain-deadline default is one of the two *values* this item owns, and it departs
from py's on a platform datum R69 handed over.** The other is the readiness pause, below. R69 revision 10 records, verified at Google's own
page and asserted in its own evidence log, that Cloud Run "sends a SIGTERM signal to all
the containers in an instance, indicating the start of a 10 second period before the
actual shutdown occurs, at which point Cloud Run sends a SIGKILL signal", and states the
hand-off: "on that platform a drain deadline is honoured only if it is strictly shorter
than 10 seconds **measured from SIGTERM**, because the SIGKILL is unconditional at the
deadline and the process never reaches its own exit path — so R67's 143 would never be
observed." py's default is `graceful_shutdown_seconds: int = 10`; ported literally it is
the one value that can never be observed on the platform the programme's own reference
architecture names.

- **Recommended: `8`, read as a total shutdown budget measured from SIGTERM**, not as a
  pure drain deadline. It is strictly under the platform kill point, with margin for the
  drain's own completion, stream flush and R67's `ExitCode` return from `main`. It is
  safe on every platform, including the two in `target-os-matrix`, where nothing kills
  the process at all.
- **The alternative an owner could reasonably prefer: keep `10`** and document that on
  Cloud Run an operator must lower it. Rejected, because a default whose only documented
  effect is to be overridden is not a default.
- **Cloud Run is not adopted as a deployment target by this decision.** R69 says so
  explicitly and `target-os-matrix` is `ubuntu-latest, macos-latest`. The datum is used
  as a constraint on a default, not as a platform commitment.
- **The budget is shared with the readiness pause below.** The pause is spent *from*
  the 8 seconds, never added to them.

#### The readiness-propagation pause — R80's requirement, accepted

**This item owns the pause's value.** R80 revision 3
(`research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md`, landed at commit
`53b13f45`, not published) says at lines 314–318 that "**no item owns its value today**"
and that it "**hands R77 a requirement rather than citing a fact**". At lines 750–752 it
says: "This item hands R77 the requirement; if R77 declines it, the pause needs an
owner." Revision 3 of this decision instead quoted R80's raw report ("R77 owns the
window's value…") and said "R80 decides the split". R80's decision had already withdrawn
that raw sentence (its lines 1197–1201), so each item said the other decided. Revision 4
ends the loop by accepting the requirement.

- **Name:** `RSLBP_WEB_READINESS_PAUSE_SECONDS`, under this item's naming rule. It is a
  non-negative integer number of seconds, and set-but-empty means unset.
- **Default: `0`.**
- **Budget rule, checked at boot:** the pause must be strictly less than
  `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`. The pause is spent from that budget, and the
  drain gets the remainder: drain deadline = budget − pause. A pause equal to or greater
  than the budget is a boot failure under `RSLB203`, naming both variables. With the
  defaults, the pause is 0 s and the drain gets all 8 s. An operator who sets a pause of
  3 s gets a 5 s drain, and the total stays inside the 8-second budget.
- **What the pause does is R80's.** R80 flips its readiness latch, keeps the listener
  open for the pause, and then lets the drain begin. Whether the pause also applies on
  SIGINT is part of that mechanism and is R80's and R69's to state. This item hands
  them the value and the rule.

**Why the default is 0.** The pause buys time for an endpoint controller, such as
Kubernetes' EndpointSlice controller in R80's account, to stop routing to the process.
The platforms this template records have no such controller. The CI runners in
`target-os-matrix` and a developer's machine have none, so a non-zero default would only
delay every shutdown there. Cloud Run is the one platform datum on record, and it gives
10 seconds from SIGTERM. Any pause there comes out of drain time. This research has not
verified whether Cloud Run keeps routing new requests after SIGTERM: R69's datum does not
say, and no source for it is in this run. So a non-zero default would spend drain budget
for a benefit nothing on record shows.

**The consequence is stated, not hidden: at the default, R80's readiness latch closes no
race.** R80 says so itself ("The mechanism is inert if that window is zero"). An operator
on a platform with endpoint propagation opts in by setting the pause, and raises the
budget to fit their platform's kill window. The web documentation table (AC9) must say
exactly that beside the variable.

**The alternative an owner could reasonably prefer: default `2`, leaving a 6-second
drain.** That default would make R80's latch effective out of the box on Kubernetes. It
is rejected because no platform the template records needs it, and every recorded
platform pays for it. The number is a judgement, not a measurement; the
budget rule is the part this decision is confident in. AC15 makes the rule checkable.
R80 is being revised in parallel (revision 4), so R80's next landed revision is
a re-verify trigger.

**List encoding — a justified difference from py, stated rather than left implicit.** py
encodes list-valued knobs as JSON; its docstring says "List values parse from JSON,
e.g.:: `PLBP_WEB_CORS_ORIGINS='["https://app.example.com"]'`" (asserted in
`review/evidence/sources.log`). This item fixes the Rust encoding as **comma-separated,
with an empty or unset variable meaning the empty list**:
`RSLBP_WEB_CORS_ORIGINS=https://a.example,https://b.example`. Grounds: it is the Rust
ecosystem's own convention for the same problem — `envy` splits sequences on `,`
(`envy-0.4.2/src/lib.rs:153`, re-read in this run), `config` exposes `list_separator`,
`figment` exposes `Env::split(pattern)` — and it is what `PATH`-shaped shell habits
produce. It yields exactly what R76's raw asks of this item, "a possibly-empty ordered
collection of allowed origins". Cost, recorded honestly: JSON round-trips values
containing the separator and comma-splitting does not; no value in this field set
(origins, header names) may contain a comma, so the cost is nil *for this field set* and
would have to be revisited if a later item adds a free-text list. The principle — one
documented encoding, validated at boot — is preserved; only the encoding differs, and it
differs on ecosystem-idiom ground.

#### Conformance to the org REST API Design Standard v2.0.0 (W2-REST)

**The frame, and it decides most of the rows below.** The standard contains the string
"environment variable" **zero** times — asserted in `review/evidence/rest-conformance-r2.sh`
against the pinned blob, beside nineteen positive quotations that show the search works.
No rule in it names a setting, requires one, or turns on one. Every rule therefore reaches
this item's surface in exactly one of three ways: a setting *selects* behaviour the rule
governs (then the setting's shape and default must be able to express a conformant
posture); a setting *could* select behaviour the rule fixes (then the naming rule must
forbid it); or the rule governs something no setting touches (then this item conforms by
having nothing to say, and owes a forward rule so a later item does not break it).

Rules quoted at blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`; the line number after
each is asserted in `review/evidence/rest-conformance-r2.sh`.

| Rule | Line | What it requires | This surface |
|---|---|---|---|
| `R1.5` | 210 | "Every API declares one **conformance tier** in its conformance note (§1.9)." | **CONFORMS.** The tier is a property of the artifact, declared in a note, not of a deployment. No `RSLBP_WEB_*` name selects it and none may; the declaration belongs to whichever item writes the conformance note (R69 or R71), not here. |
| `R1.6` | 229, 237 | Capability rules are scoped by named switches — "The switch vocabulary: `webhooks` · `async-operations` · `bulk-operations` · `streaming`" — and "A declaration that a switch is off … MUST carry a stated reason". | **CONFORMS, with a forward rule.** All four switches are off for this template and the reason is the same one for each: this item names no webhook, async-operation, bulk-operation or streaming knob, and py's twelve-field object has none either, so the capabilities do not exist to be configured. They are **declared off with a stated reason** rather than left silent. Forward rule: **no environment variable may turn an applicability switch on**, because a switch whose state varies per deployment cannot be declared in a static conformance note. A later item adding one of those capabilities adds it as code, and only its *tunable values* come under this naming rule. |
| `R1.7` | 271, 291 | "An API deviates from this standard only in writing… silent deviation from any rule strength is nonconformance regardless of the deviation's merits", with the note's deviation line shaped `- <rule ID> · <rule strength> · what differs · why · approver · date`. | **CONFORMS.** The one departure this item owns is written down below as `OVERRIDE (OV-04)` in that shape. Nothing else departs. |
| `R7.1` | 1259 | "Every response MUST carry an explicit `Cache-Control` header — stating freshness, `no-cache`, or `no-store` per the R7.3 posture". | **CONFORMS.** No caching setting exists and the standard requires none; the header is emitted by the response layer R70 and R75 own. |
| `R7.2` | 1271 | "Responses carrying user-specific or authenticated data MUST be marked `private` or `no-store` — a shared cache may otherwise serve one user's data to another." | **CONFORMS, with a forward rule.** A future `RSLBP_WEB_CACHE_*` knob **may never flip a resource from `private` or `no-store` to `public`**; it may only tune a `max-age` on a resource already documented as immutable or stale-tolerant. The rule names the hazard exactly — a deployment-tunable cache posture is how one operator's misconfiguration becomes a cross-user leak. |
| `R7.3` | 1281 | "Within the mechanism above, the default posture is three-tier" — `private, no-cache` for authenticated or mutable resources, `no-store` reserved for genuinely sensitive payloads, `public` with `max-age` only where documented immutable. | **CONFORMS.** The posture is a per-resource property fixed in code, not a deployment knob; this item adds nothing and constrains any future knob as the row above says. |
| `R8.1` | 1317 | "APIs MUST be served only over TLS 1.2 or higher, preferring 1.3; SSL 2/3 and TLS 1.0/1.1 MUST be rejected." | **`OVERRIDE (OV-04)`** — recorded below. The template's listener is plaintext and this surface ships no TLS setting. |
| `R8.2` | 1323 | "Access tokens MUST NOT be accepted or emitted in URI query parameters." | **CONFORMS, by construction.** `WebSettings` declares no credential of any kind (R56 revision 2 owns the token chain), so no setting can place a token anywhere, least of all in a URI. The rule binds the request layer, and this surface cannot weaken it. |
| `R8.5` | 1348 | "Credentials SHOULD be scoped and expiring; long-lived unscoped tokens SHOULD be avoided." | **CONFORMS as N/A-with-reason for this surface**, and the reason is the design rule rather than an absence: no credential is a field of `WebSettings`, so there is no credential lifetime for a web setting to govern. R56's `RSLBP_TOKEN` tier is where the rule binds. |
| `R8.10` | 1387, 1397, 1398 | "An API MUST adopt each axis default unless a named trigger applies, and MUST record any flip in its conformance note", over five axes. The rate-limit axis default is "Multi-dimensional tiered posture, published: per-principal sustained + token-bucket burst … unauthenticated per-IP an order of magnitude lower; auth endpoints strictly stricter … failed-auth budget; concurrency separate". The replay-window axis default is "300 s past / 60 s future, asymmetric + mandatory dedup cache held at least the past window". | **MOVED for the rate-limit axis (Move 2); N/A-with-reason for the replay window; not a settings matter for the other three.** The rate-limit axis is the one axis whose numbers genuinely vary per deployment, and revision 1 reserved a single scalar `RSLBP_WEB_RATE_LIMIT` — py's name, py's `None` default — which cannot express a four-dimensional posture and whose inherited default is "off". Move 2 replaces it. The replay window governs *signature* replay (its triggers name NTP skew and RFC 9530 body binding); this template signs nothing and accepts nothing signed, which is the `webhooks`-off reason already given, so the axis has nothing to apply to. Sender-constrained tokens, token format and object-level authorization are code and note properties; **no deployment-profile selector belongs on this surface**, because R8.10 requires each flip to be *recorded in the conformance note*, and a profile chosen by an environment variable could not be. |
| `R8.12` | 1422 | "Secrets, credentials, and PII MUST NOT appear in problem `detail`, in echoed request input, or in any other response content." | **CONFORMS, on two independent grounds.** First, no secret is a field of `WebSettings`, so the loader's deliberate echo of the offending value — `RSLBP_WEB_PORT: invalid value "eighty"` — can never carry one. Second, the settings failure **precedes the listener**: `from_env()` runs at the composition root before the router exists, so its message is a boot-time stderr envelope and never response content. AC11 makes the first ground checkable rather than merely intended. |
| `R9.1` | 1435 | "An API MUST use one uniform version-marker placement: the major version in the path (`/v1`), never `/v1.0`; minor and patch versions never appear in URIs." | **MOVED (Move 1).** Revision 1 named `RSLBP_WEB_ROOT_PATH` and handed its semantics on with no constraint. A mount prefix that an operator may set freely can carry or overwrite the version segment, which would make the API's version a deployment property — the precise opposite of "one uniform version-marker placement", and it would move a segment R9.4 freezes. |
| `R10.1` | 1546 | "Every `202 Accepted` MUST return an addressable operation resource with defined terminal states, an expiry, and a failure representation." | **N/A-with-reason.** Scoped by the `async-operations` switch (the standard says so at line 1541), which is off: no endpoint returns `202` and no knob exists to make one. |
| `R10.6` | 1606 | "The provider MUST publish the acknowledgement timeout and the retry schedule." | **N/A-with-reason, with a forward rule.** Scoped by the `webhooks` switch, which is off. Forward rule: if webhooks are ever turned on, the acknowledgement timeout and any tunable part of the retry schedule are `RSLBP_WEB_*` names under this item's rule, and their defaults must satisfy the rule's "at least 72 hours" and "at least 30 days" floors. |
| `R11.2` | 1686 | "An API MUST apply rate limits and communicate exhaustion via the published HTTP mechanism: `429 Too Many Requests` with `Retry-After`. This MUST is a deliberate tightening of RFC 6585 §4's MAY". | **MOVED (Move 2), and this rule is why the move is not optional.** py's `rate_limit: str | None = None` disables rate limiting by default. Porting that default would ship a template whose out-of-the-box posture violates a MUST, silently — exactly what `R1.7` calls nonconformance regardless of merit. |

**Move 1 (R9.1) — the version marker is never a setting.** The naming rule gains two
clauses, both of which this item owns outright because it owns the names and the parse:

1. This item reserves **no** environment variable that carries, selects or overrides the
   API version or its base path:
   `RSLBP_WEB_API_VERSION`, `RSLBP_WEB_BASE_PATH` and every synonym are outside the surface.
   The `/v1` segment is a compile-time constant in the route tree, where R9.4's frozen
   surface can hold it. Put the other way round, and this is the whole of Move 1:
   the version marker is never an environment variable.
2. `RSLBP_WEB_ROOT_PATH` stays, with its py meaning — a mount prefix for a path-stripping
   proxy — and is constrained so that it is prepended to, and
   **never replaces the version segment**. A value whose own segments look like a version
   marker (`/v1`, `/v2`, `/v1.0`) is a boot failure under `RSLB203`, for the same reason
   the standard bans `/v1.0` outright: two version markers on one path is not one uniform
   placement. AC12 makes this checkable.

**Move 2 (R8.10 rate-limit axis, R11.2) — one scalar becomes a reserved family.**
`RSLBP_WEB_RATE_LIMIT` is withdrawn as a reserved name. In its place this item reserves
the prefix `RSLBP_WEB_RATE_LIMIT_*` and states three constraints, leaving every value and
the exact membership to R74, which owns rate-limiting semantics and is being researched in
parallel:

1. **The family's size is whatever R74 publishes; this item sets no floor.** R8.10's axis
   default names four dimensions — per-principal sustained, token-bucket burst,
   unauthenticated per-IP, and a stricter auth-endpoint rate. They are an *input this item
   hands to R74*, not a member count. Revision 3 said the family has "at least four
   members". That floor constrained a choice R74 owns and is withdrawn. R74 revision 2
   fixes three members at its lines 511–513 and argues why at its line 515
   (`OVERRIDE (OV-17)` ships one dimension).
2. **No member's default may disable rate limiting.** R11.2 makes limits a MUST; py's
   `None`-means-off default is not portable into a conformant template.
3. The family is a naming reservation, not a schema: R74 fixes which members exist, their
   units and their values, and R8.10's `[POLICY]` starting points ("≈100 rps/account,
   25 rps/endpoint", "≤5/min per IP+account") are the figures it must argue from or flip
   against a named trigger.

This is a coupling statement to R74, not a decision for it. If R74 publishes a posture
that needs a different member set, the family prefix still holds and only the membership
moves.

#### OVERRIDE (OV-04) — R8.1 (MUST), TLS termination is not a setting on this surface

In the shape of the standard's §1.9 deviation note
(`- <rule ID> · <rule strength> · what differs · why · approver · date`):

> `R8.1` · MUST · The template's HTTP listener is plaintext, and this item's settings
> surface ships no TLS configuration — no certificate path, no key path, no protocol
> floor. TLS for a deployed instance is terminated upstream. · Because in-process TLS
> would put private-key material on the one settings object this template keeps
> credential-free, and the server stack that would terminate it is R69's, not this
> item's. · approver: pending owner review · date: 2026-09-18

**Argument:** R8.1 binds how an API is *served*, and the template as it ships does not
serve it. R69 revision 10's accepted stack is `axum` 0.8.9 with its default features
(`form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing`) on
`tokio` 1.53.1 — no `rustls`, no `native-tls`, no `axum-server`. The owner-supplied
reference architecture deploys behind Cloud Run, whose edge terminates TLS, and
`target-os-matrix` is `ubuntu-latest, macos-latest`, CI runners that hold no certificate
material. The conformant posture actually available to a *settings* item is not to add
TLS but to make the plaintext listener unreachable unless an operator deliberately
exposes it: `RSLBP_WEB_HOST` defaults to `127.0.0.1`, so the process answers nobody off
the host until someone sets `0.0.0.0` — and that moment, which R51's Dockerfile makes
explicit, is exactly when the operator takes on R8.1's duty at the edge. Recording this
rather than passing over it is what `R1.7` requires: a deviation from a MUST makes the
API nonconformant *unless* it is recorded, and silence would be nonconformance "regardless
of the deviation's merits".

**Options:**

- **(a) Record the exception; keep the loopback default; document the duty beside
  `RSLBP_WEB_HOST` — selected.** Costs nothing in dependencies, keeps the credential-free
  settings object intact, and puts the obligation where the operator meets it. It leaves
  the template unable to satisfy R8.1 by itself, which is the honest state of affairs and
  is why this is an override rather than a conformance claim.
- **(b) Terminate TLS in process**, adding `rustls` plus `RSLBP_WEB_TLS_CERT_FILE` and
  `RSLBP_WEB_TLS_KEY_FILE` to this surface. **Rejected on three grounds:** it puts
  private-key paths next to web knobs, which is the coupling R56 revision 2 and `R8.12`
  exist to prevent; it adds a TLS stack to a dependency tree this item's whole
  recommendation is about not growing; and the server stack is R69's owned value, so this
  item cannot make that choice unilaterally.
- **(c) Refuse the `0.0.0.0` bind altogether**, so the process can never be exposed
  without an edge. **Rejected:** it would make R51's container image unusable, and R51
  owns the Dockerfile.

**The number is allocated by the controller, not claimed by a search.** `OV-04` belongs to
this item under the allocation table in `docs/planning/p02/execution-ledger.md`
("OV-04 R77 revision 2 (R8.1 plaintext listener; committed first, keeps the number)"),
recorded after R80 revision 2 had allocated the same number concurrently; R80 renumbered
to `OV-05` in its own revision 3, and the ledger's resolution ends the practice this item
used in revision 2: "Resolution: OV numbers are allocated by the controller from now on …
Later items ask the controller for a number instead of searching." At the time revision 3 was written the live census of the literal
`OVERRIDE (OV-04)` is **two files** — this decision and the ledger's allocation table —
R80 having completed its renumber to `OV-05`. `review/evidence/ov-allocation-r3.sh`
asserts that census rather than the emptiness revision 2 claimed, and it asserts it in the
form the shared worktree allows: this item and the ledger **must** name the number, R80
**may** name it in a renumber note without failing the check, and **no third item may**.
That census counted quotations as claims, and it fails in the live tree once auditor
reports quote the literal. Revision 4's `review/evidence/ov-allocation-r4.sh` counts
declarations instead: exactly one `DECISION.md` has a heading naming `OVERRIDE (OV-04)`,
and it is this one (`review/evidence/ov-allocation-r4.log`).

**Withdrawal condition, recorded so the override does not outlive its reason:** if R69
later adopts an in-process TLS terminator, OV-04 is withdrawn and this item names the
certificate and key settings under the same prefix rule — with `R8.12`'s redaction
obligation applied to them from the first line. That is a re-verify trigger below.

#### Observable acceptance criteria

AC1 to AC5 were executed in revision 1; AC6 to AC16 are proposed for P03 and nothing here
claims they have been run. AC11 to AC14 are new in revision 2 and come from the
conformance pass above. AC15 and AC16 are new in revision 4 and come from the readiness
pause and the R58 handshake.

| # | Criterion | Status |
|---|---|---|
| AC1 | `WEB_ENV_PREFIX == "RSLBP_WEB_"`, and changing the app-name constant alone changes it | **executed** (`probes.log` P1, P4) |
| AC2 | `RSLBP_WEB_PORT=eighty` fails construction with a message naming the variable, the value and the expectation | **executed** (`probes.log` P3, P4) |
| AC3 | An unprefixed `PORT`, and a set-but-empty `RSLBP_WEB_PORT`, both leave the default in place | **executed** (`probes.log` P4) |
| AC4 | A handler receives the settings through `State<Arc<WebSettings>>` with no process environment touched | **executed** (`probes.log` P4) |
| AC5 | The template's own test suite cannot call `std::env::set_var` without `unsafe` | **executed** (`probes.log` P2 — the edition-2024 compile error is the enforcement, and the edition-2021 control shows the edition is the cause) |
| AC6 | The serve binary with a malformed `RSLBP_WEB_*` variable exits `2`, emits R67's one-line stderr envelope with `code: "RSLB203"`, and writes nothing to stdout | proposed |
| AC7 | `grep -rn 'std::env::' crates/web/src/` matches exactly one file, `settings.rs` | proposed |
| AC7b | `grep -rn 'std::env::' crates/core/src/` matches nothing | proposed |
| AC8 | `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS` is honoured: a SIGTERM during an in-flight request drains, then the process exits `143` within the window | proposed (the drain mechanism is R69's; only the variable, its default and the budget reading are this item's) |
| AC9 | The documented `RSLBP_WEB_*` table and the struct's field list cannot drift | proposed |
| AC10 | With the `web` feature off, neither the settings type nor the environment read exists in the binary | proposed |
| AC11 | No `RSLBP_WEB_*` value reaches any HTTP response, and `WebSettings` declares no field whose name matches a secret-shaped pattern (`*_TOKEN`, `*_SECRET`, `*_KEY`, `*_PASSWORD`) — the checkable form of `R8.12` | proposed (new in revision 2) |
| AC12 | `RSLBP_WEB_ROOT_PATH=/v1` (and `/v2`, `/v1.0`) is a boot failure with `RSLB203`, while `RSLBP_WEB_ROOT_PATH=/api` is accepted and the served path is `/api/v1/...` — the checkable form of `R9.1` and Move 1 | proposed (new in revision 2) |
| AC13 | No environment variable named by this template selects an applicability switch: `grep -riE 'RSLBP_WEB_(WEBHOOK|ASYNC|BULK|STREAM)' crates/ docs/ README.md` matches nothing — the checkable form of `R1.6`'s forward rule | proposed (new in revision 2) |
| AC14 | With no `RSLBP_WEB_RATE_LIMIT_*` variable set, the service still applies the default limits of every member R74 publishes (three in R74's revision 2: `RSLBP_WEB_RATE_LIMIT_PER_IP`, `_PER_IP_BURST`, `_MAX_ENTRIES`), and answers an exhausted caller with `429` and `Retry-After` — the checkable form of `R11.2` and Move 2's second constraint. The member list is checked against R74's *published* membership, not this item's | proposed (new in revision 2, re-pointed in revision 4; the limiter is R74's, the variable family and the no-disabling-default rule are this item's) |
| AC15 | With defaults, the readiness pause is 0 s and the drain gets the whole 8 s budget. `RSLBP_WEB_READINESS_PAUSE_SECONDS=3` gives a 5 s drain. `RSLBP_WEB_READINESS_PAUSE_SECONDS=8` with the default budget is a boot failure with `RSLB203` naming both variables | proposed (new in revision 4; the pause mechanism is R80's) |
| AC16 | In the serve binary, `WebSettings::from_env()` runs before `telemetry::init`, and emits nothing before it. R58's telemetry module contains no `std::env::` call, and a level set only in the injected variable list that `from_vars` receives is the level telemetry applies | proposed (new in revision 4; a request to R58) |

#### Reconciliation with the owner-supplied reference architecture

`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, treated as a standing input
under `docs/planning/p02/owner-decisions.md` section 11 — an owner-supplied research
input, not a binding standard and not a pre-decision. Its line 16 assigns "R77 — config
and secrets (C9)" to this item. Every row this item touches, with agreement or a ground
for differing; each quotation is asserted at its line in `review/evidence/sources.sh`.

| Reference row | What it says | This item |
|---|---|---|
| **C9 Config** (table row at line 66, prose at 108) | "**figment** 0.10.x" for layered config, "defaults → TOML file → env"; runner-up `config-rs`, rejected as "less ergonomic layering" | **Differ**, on three measured grounds: (i) `figment` 0.10.19 declares no `rust-version` and so fails gate 2 under the strict reading settled 2026-09-11; (ii) its `Env` provider has no injected-source constructor, so under edition 2024's `unsafe set_var` the template cannot unit-test the loader without `figment::Jail`, which mutates the process environment behind a lock; (iii) the *file* tier the row exists to provide is a tier this surface does not have, and R54 revision 3 already rejected a layering engine for the surface that does. |
| **C9 Secrets** (line 108) | "`--set-secrets` env-var injection from Secret Manager" is the default; a runtime SDK fetch only for rotation | **Agree, and already settled elsewhere.** Secrets arriving as environment variables is exactly R56's `RSLBP_TOKEN` tier. This item adds the sharper rule that keeps the two apart: `WebSettings` declares **no** secret field at all, so the token never enters the web settings object and nothing in it needs `R5.6` redaction. |
| **C13** — `AppState` (line 120) | "`AppState` holds `PgPool`, config, and shared clients; use `FromRef` to hand sub-state to extractors" | **Agree.** R69 revision 10's sketch is reused rather than redesigned: `pub config: Arc<WebConfig>` with `impl FromRef<AppState> for Arc<WebConfig>`. This item supplies the type in that slot and names it `WebSettings`, matching py's name and F324's wording. Measured working against axum 0.8.9. |
| **C13** — dependency injection (line 120) | "Dependency injection via **traits behind concrete types** … keeps handlers testable without a DI framework" | **Agree.** No DI container; the settings value is constructed by plain code at the composition root and handed in. |
| **Sample `Cargo.toml`** (line 174) | `figment = { version = "0.10", features = ["toml","env"] }` | **Differ.** `crates/web/Cargo.toml` gains **no** configuration crate under this recommendation. |
| **Sample `main.rs`** (line 325) | `let cfg = config::load()?;  // figment: defaults → file → env` | **Partly agree.** Agree on *load once at startup, before anything that can log or serve* — the same invariant F330 and py's `create_app` carry. Differ on the tiers: **defaults → env**, no file tier, for the web knobs; the file tier belongs to the core `Config` the same binary also builds through R54's stack. |
| **Sample layout** (line 237) | `src/config.rs  # figment layered config` | **Agree on the shape, differ on the engine.** One module owns settings: `crates/web/src/settings.rs`. |
| **C15 Cloud Run runbook** | SIGTERM, then SIGKILL after 10 s | **Agree, and it is load-bearing here** — it is the ground for the 8-second budget above. |

**Tally: 4 agree, 3 differ, 1 partly** (agree on the invariant, differ on the tiers).
Every "differ" rests on a measured fact re-verified in this run or on an owner-accepted
decision, not on preference.

#### Migration implications

`rs-launch-blueprint` has no Rust source yet, so these are the files P03 creates or
changes, in R69 revision 10's tree.

| Path | Change |
|---|---|
| `crates/web/src/settings.rs` | **new.** `WEB_ENV_PREFIX` (the `const fn` derivation from `TOOL_NAME`), `WebSettings`, its `Default`, `SettingsError` (`thiserror` in the library crate, per R67), `from_vars`, `from_env`. `#![forbid(unsafe_code)]` at module scope. The only `std::env` call in the whole member. |
| `crates/web/src/lib.rs` | `pub mod settings;` and `pub use settings::{WebSettings, WEB_ENV_PREFIX};`. `AppState` gains `pub config: Arc<WebSettings>` and `impl FromRef<AppState> for Arc<WebSettings>` — R69 revision 10 already reserves that slot as `Arc<WebConfig>`; this item supplies the type and the name. |
| `crates/web/Cargo.toml` | **no new dependency.** The `[dependencies]` block gains nothing from this item. |
| `crates/core/src/**` | **unchanged, and guarded**: no `std::env` call may appear here. |
| `src/bin/rslbp-serve.rs` (root package) | gains, as the first statements of `main`: `let settings = WebSettings::from_env().map_err(…)?;` mapped to `RSLB203` / exit `2`; then R58's `telemetry::init(Profile::Service { .. })` fed `settings.log_level` and `settings.log_format` (AC16); then `let state = AppState { config: Arc::new(settings.clone()), projects: … };`. The bind address, the shutdown budget and the readiness pause are read from `settings` rather than from constants. |
| `crates/web/tests/settings.rs` | **new.** The AC1 to AC4 tests, all over injected variable lists, none touching the process environment. |
| `crates/web/tests/web_api.rs` | gains the `ServiceExt::oneshot` case asserting that a handler sees the injected settings through `State`. |
| `README.md` / `docs/` (web section) | **new table** listing every `RSLBP_WEB_*` variable, its type, its default and its owning item, plus the one-line statement of the naming rule `R5.4` expects to be documented. A test can assert the table's variable list equals the struct's field list (AC9). |
| `Justfile` | R69's `serve` / `serve-once` recipes already export `<APP>_WEB_HOST`, `<APP>_WEB_PORT` and `<APP>_WEB_LOG_FORMAT`; substitute `RSLBP` for `<APP>`. No other change. |
| `Dockerfile` (R51) | sets `RSLBP_WEB_HOST=0.0.0.0` explicitly, because the default is loopback — the same note py carries at `settings.py`. |
| `docs/port/COMMONALITY.md` | **untouched by this decision.** F324's row is the owner's to update when R77 publishes. |

re-verify: if the controller reallocates `OV-04` away from this item or the owner rules on it (the allocation table in `docs/planning/p02/execution-ledger.md` is the register, and a later override for this item is asked of the controller rather than searched for), when the org REST API Design Standard moves off blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` or amends any of R1.5, R1.6, R1.7, R7.1, R7.2, R7.3, R8.1, R8.2, R8.5, R8.10, R8.12, R9.1, R10.1, R10.6 or R11.2, when R74 publishes the membership and defaults of the `RSLBP_WEB_RATE_LIMIT_*` family (then AC14's member list and the field count are re-checked against the published members; R74's working-tree revision 2 names three), when R69 adopts an in-process TLS terminator (which withdraws `OVERRIDE (OV-04)` and brings certificate and key settings under this naming rule), when any later item turns an applicability switch on and so brings its published values under this naming rule, when `docs/port/PARAMETERS.md`'s `web-extra-surface` row is republished (its bytes must then equal R69 revision 11's value carried in the `assumes` line below) or R69 revises that owned value again (the `assumes` line must then be re-copied and this decision's paths re-checked against it), when R58 publishes `logging-pipeline-contract` and fixes the value sets for `RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT`, or publishes a serve-binary start that does not take those two values from `WebSettings::from_env()` as AC16 requests, when R80 lands or publishes a revision that changes the readiness-pause mechanism, declines the value this item fixes for `RSLBP_WEB_READINESS_PAUSE_SECONDS`, or needs the pause on a signal this item did not consider, when R76 publishes an origins encoding that a comma cannot survive or any later item adds a web knob whose value may contain a comma, when R67 revises `RSLB203` or the error envelope, when R54 and R56 publish so the namespace-disjointness claim can be checked against a published curated set rather than an accepted-but-unpublished one, when the owner revisits the gate-2 strict reading (which would readmit `envy` and `figment`), when `envy` or `figment` publishes a new release (in particular one declaring a `rust-version`), when `config` publishes a new 0.15.x release (the runner-up range admits it unmeasured) or 0.16, when R53 is revised to adopt `config` (the reuse premium the Muse report argued from), at the next `msrv-policy` floor advance past 1.96 (which neither `config` 0.15.26's 1.88.0 nor `confique`'s 1.68.2 is near), or by 2027-03-18, whichever comes first

## Parameters

R77 owns no registry parameter: the binding prompt's `## Couplings` block carries an
empty `- owns:` line, `research/CLAUDE.md`'s R77 row carries `—` in its `owns` column,
and `docs/port/PARAMETERS.md` lists no parameter owned by R77. Its `- consumes:` line is
empty too, so no parameter is a registry dependency of this item. The `assumes` lines
below are declared because the recommendation genuinely rests on those values. Five were
extracted programmatically from the live `docs/port/PARAMETERS.md` row. The sixth,
`web-extra-surface`, is R69 revision 11's owned value at line 1885, copied verbatim under
owner decision Q3.A. `review/evidence/sources.sh` re-compares each byte for byte with its
source.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on the root package rs-launch-blueprint; web = ["dep:rs-launch-blueprint-web"], with axum 0.8.9 declared non-optionally in crates/web/Cargo.toml and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 declared non-optionally in crates/web/Cargo.toml with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is crates/web's dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module crates/web/src/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests in crates/web/tests/, with no file-level #![cfg(feature = "web")] because the whole member is optional, and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated crates/web/src/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on crates/web/**, the serve binary's source file and the web test files
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**How the assumed parameters bear on the decision.** `rust-edition = 2024` is the single
most load-bearing value here: it is what makes `std::env::set_var` `unsafe`, what makes
`from_vars` the required signature, and what eliminates `confique` and `figment` on
testability. `msrv-policy` fixes the gate-2 floor at 1.96 against stable 1.98.1 and, read
strictly, is what excludes five of the eight candidate crates. `target-os-matrix` keeps
the design free of any platform `cfg` — `std::env::vars_os` and `str::FromStr` are
identical on both runners — and is also why Cloud Run's 10-second window is used as a
constraint on a default rather than as a platform commitment. `license` is `inapplicable`
here under the 2026-09-12 (Q7.B) ruling. `web-extra-surface` supplies the feature gate,
the serve binary, the tree the settings module lives in, and the sentence that makes this
item the namer of every service knob. `error-taxonomy-exit-codes` supplies `RSLB203` and
exit `2`, the single stderr JSON envelope the failure renders into, and the requirement
that `hint` be able to name the offending input — which is what makes the variable name,
the value and the expectation load-bearing rather than cosmetic — as well as the
`thiserror`-in-the-library rule `SettingsError` follows.

**`web-extra-surface` — the bytes above are R69 revision 11's, not the registry's.**
The live registry row still reads "the library module `src/web/`…" and "path-based
skip-gating keys on `src/web/**`", which are revision 9's bytes. Owner ruling W1-R02 moved
the gated tree to the optional workspace member `crates/web` at R69 revision 10, and R69
revision 11 carries that value unchanged
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, sha256
`2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`, owned value at line 1885):
`web = ["dep:rs-launch-blueprint-web"]` on the root package, the library module at
`crates/web/src/`, the web tests at `crates/web/tests/` with no file-level
`#![cfg(feature = "web")]`, and skip-gating on `crates/web/**`. Under owner decision Q3.A
(flag day now), the `assumes` line carries those bytes verbatim, so the line and every path
in this decision now agree. This is not a `CONFLICT:`: the registry row is expected to be
republished to the same bytes, which is recorded above as a re-verify trigger.

**Two parameters a reader might expect on this list, and why neither is there.**
`build-tool-output-shape` (R49) bears on the decision only through where the serve binary
target is declared, which is R69's to state and not this item's; R49's own revision 8 is
unpublished, so carrying its registry bytes here would add staleness risk without adding
an argument. `logging-pipeline-contract` (R58) has the registry value `—`: R58 has
published nothing, which is precisely why `RSLBP_WEB_LOG_LEVEL` and
`RSLBP_WEB_LOG_FORMAT` are **named** here and **valued** there.

**No `CONFLICT:` line is raised, and the raw report raised none.** Two places a reader
might expect one: R69's exit-code enumeration does not list a settings failure, but a
malformed `RSLBP_WEB_*` variable is `RSLB203` at exit `2` under R67's published catalog —
an answer R67 already supplies, not a change R69's value needs. The other, a web tree at
`src/web/` in R69's value, no longer arises: the revision-11 value above places it at
`crates/web/src/`, where this decision puts the settings module.

## Empirical check

**Toolchain and environment.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `Darwin arm64`
(`aarch64-apple-darwin`); `bash 3.2.57(1)-release`; `/usr/bin/grep` is
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`. All work on 2026-09-18 (UTC). Current
stable Rust is **1.98.1 (48a229cea 2026-09-01)** per the release channel; the local
toolchain is one patch behind it, which affects no claim here — the MSRV floor is derived
from the channel figure, not from the local one. **Nothing was implemented:** every Rust
crate below was created under a `mktemp -d` directory beneath `$TMPDIR` and deleted when
the script exited; no Rust file was written into this repository and no nested git
repository or `target/` tree was created. **Revision 4's scripts ran on 2026-09-27 (UTC)**
with `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, under the same no-files-in-the-repository
rule.

**Working directory for every command:** the repository root,
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Each script also resolves its paths
from its own location, so it runs from anywhere.

| Script | Revision | Log | Result |
|---|---|---|---|
| `review/evidence/figures.sh` | 1, carried unchanged | `review/evidence/figures.log` | exit **0** |
| `review/evidence/sources.sh` | 1, carried unchanged | `review/evidence/sources.log` | exit **0** |
| `review/evidence/probes.sh` | 1, carried unchanged | `review/evidence/probes.log` | exit **0** with `CARGO_TARGET_DIR` unset; exit **1** at 31/3/0 with it set (`review/evidence/probes-rerun-r4.log`); P6 superseded by `probes-r4.sh` |
| `review/evidence/rest-conformance-r2.sh` | 2, carried unchanged | `review/evidence/rest-conformance-r2.log` (the revision-2 run, 91/0/0) | exit **1** at 90/1/0 against any later title, by design |
| `review/evidence/ov-allocation-r3.sh` | 3, carried unchanged | `review/evidence/ov-allocation-r3.log` | exit **0** at the revision-3 tree (`archive-rerun-r3.log`); exit **1** at 39/4/0 in the live tree (`review/evidence/ov-allocation-r3-rerun-r4.log`); its census superseded by `ov-allocation-r4.sh` |
| `review/evidence/fetch-snapshots-r4.sh` | **4, new** — retriever, no assertions | `review/evidence/fetch-snapshots-r4.log` | wrote 27 files into `review/evidence/snapshots-r4/` |
| `review/evidence/drift-r4.sh` | **4, new** | `review/evidence/drift-r4.log` | exit **0** |
| `review/evidence/probes-r4.sh` | **4, new** | `review/evidence/probes-r4.log` | exit **0** |
| `review/evidence/probes-rerun-r4.sh` | **4, new** — reruns `probes.sh` both ways | `review/evidence/probes-rerun-r4.log` | exit **0** |
| `review/evidence/ov-allocation-r4.sh` | **4, new** | `review/evidence/ov-allocation-r4.log` | exit **0** |
| `review/evidence/r4-checks.sh` | **4, new**; group C re-pinned in revision 5 | `review/evidence/r4-checks.log` (rerun at revision 5, 184/1/0) | exit **1** at 184/1/0 against the revision-5 title, by design; exit **0** at 186/0/0 at revision 4 |

Each is run as `bash research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/evidence/<name>`.

**One revision-2 check is superseded, and it is named.** Group E of
`rest-conformance-r2.sh` contains the line
`| /usr/bin/grep -v 'runs/R77/'`, applied to paths built from an unresolved
`"$run/../../../.."`. Every such path carries `runs/R77/` in its own prefix, so the
exclusion discarded all of its input and the check passed against an empty set — a check
that **could not fail, and revision 3 says so**. The script is deliberately left unedited, because 90 of its 91 checks are sound and
rewriting a landed revision's evidence would destroy the record of what that revision
actually verified. **It no longer exits 0, and that is reported rather than hidden:**
re-run against this file it reports **PASS=90 FAIL=1 SKIP=0**, and the single failure is
its own `H1 is the date-first revision-2 title` check, which binds revision 2's title by
design and must fail once the title says revision 3 — the same disposition R02 revision 2
recorded for its `S1a`. `ov-allocation-r3.sh` asserts both the 90/1/0 counts and that the
one failing line is exactly that title check, so a second, real regression in that script
could not hide behind this expected one. `ov-allocation-r3.sh` group B reproduces the defect from
revision 2's own expression and supplies the corrected search beside it; its `root` is
resolved with `cd … && pwd`, and one of its own checks asserts that no `..` segment
survives in it.

**Revision 1's evidence is carried, not re-run.** The three revision-1 scripts, the
one-shot fetcher and all six revision-1 logs are byte-identical to the files accepted at
revision 1's sha256 `b2b2e678a9866fd8f743d2431edcda2dc03a9e4ed03c9670457081360121b546`;
group D of `rest-conformance-r2.sh` asserts each of those ten files by sha256, so a
reader does not have to take the word "unchanged" on trust. Nothing in revision 2 changes
a figure, a probe or a quotation that those scripts cover: the W2-REST pass adds a
standard, not new measurements.

`review/evidence/fetch-snapshots.sh` is **not** an evidence check and makes no
assertions: it is the one-shot retriever that wrote `review/evidence/snapshots/` on
2026-09-18, with GitHub REST called no more often than once per 21 seconds. Its output
is `review/evidence/fetch-snapshots.log`. **That log lists nine crates; the directory
holds eleven.** The two extra rows, `pathdiff` and `winnow`, were retrieved by hand later
the same day — same endpoints, same User-Agent, same date — when `config`'s transitive
dependencies became load-bearing for the gate-2 reading, and the script's crate list was
then extended to include them so that any future refresh covers all eleven. The committed
`fetch-snapshots.log` is therefore the record of the first fetch rather than of the
script's current list; `figures.sh` asserts against all eleven snapshots regardless of
which run produced each one.

**What each script proves.**

- **`figures.sh`** asserts every published figure this decision cites — crates.io
  `crate.recent_downloads` / `crate.downloads`, the newest non-yanked version's `num`,
  `created_at`, `rust_version` and `license`, GitHub `stargazers_count`, `archived`,
  `pushed_at` and open-issue `total_count` from `search/issues` (never
  `open_issues_count`), and `[pkg.rust] version` — against the committed snapshots, then
  re-fetches the **immutable** half live and asserts it again. Download counters are
  printed as `DRIFT` lines and never asserted, because they only move upward. The RustSec
  block asserts a 404 for all eight crates *and* asserts HTTP 200 with `RUSTSEC-` hits for
  two known-advisory controls, so a site-wide outage cannot pass as "no advisory".
- **`sources.sh`** asserts, at a named line or in a named file, every quotation this
  decision makes: the ledger rows, the owner rulings, the prompt's empty `owns`/`consumes`
  lines, the eight owner-reference rows, R69 revision 10's owned value and `AppState`
  sketch, R57 revision 2's `TOOL_NAME`, R76/R79/R80's coupling sentences, nine lines of
  the org CLI Design Standard at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, the four
  quotations this decision takes from R53, R54, R56 and R67, nine py claims and one ts
  claim at their pins, nine candidate source lines at exact published versions, the
  `unsafe` posture of eight crates, and each `- assumes` line against the live registry
  row.
- **`probes.sh`** re-executes the six Rust probes described above.
- **`rest-conformance-r2.sh`** (new in revision 2) asserts the owner ruling W2-REST in
  `docs/port/OWNER-REVIEW.md`; the pinned blob's identity (3427 lines, `Version 2.0.0` at
  line 3, and that commit `0850d43e45d919ef5e37f7174c4212b46013c49f` carries exactly this
  blob as `rest-api-standard.md`); each of the nineteen rule quotations above **at its
  exact line**; the finding that the standard contains "environment variable" zero times,
  which is only readable as a finding because those nineteen positive quotations show the
  search working; every conformance disposition, both moves and `OVERRIDE (OV-04)` in this
  file; the ten revision-1 files by sha256; and the revision-2 document discipline,
  including that `OV-04` is unused elsewhere while `OV-01`, `OV-02` and `OV-03` are taken —
  the control that makes the next-free-number search mean something (this group-E check was
  vacuous; superseded by `ov-allocation-r3.sh` group B).
- **`ov-allocation-r3.sh`** (revision 3) reproduces revision 2's vacuous exclusion, pins
  fourteen carried files and reruns `rest-conformance-r2.sh` at exactly 90/1/0. Its group-B
  census counts every Markdown file quoting `OVERRIDE (OV-04)` as a claim, so it fails in
  the live tree once auditor reports quote the literal (claude audit finding 2).
- **`ov-allocation-r4.sh`** (revision 4) supersedes that census. It counts only a Markdown
  heading naming `OVERRIDE (OV-04)` in a `DECISION.md` under `research/runs` or
  `research/topics`, and asserts that exactly one such file exists: this one. A positive
  control finds R80's `OVERRIDE (OV-05)` heading by the same search. A negative control
  plants a heading, a prose quotation and an audit file in a scratch tree and finds only
  the heading.
- **`fetch-snapshots-r4.sh`** and **`drift-r4.sh`** (revision 4) re-fetch the newest
  non-yanked release of all eleven crates, the stable channel and the repository figures
  on 2026-09-27, assert them against the new snapshots and against revision 1's, and
  assert the gate-2 consequences. Newest-release fields are also re-fetched live and printed
  as `DRIFT` lines, so a later release surfaces in the log.
- **`probes-r4.sh`** (revision 4) supersedes P6 and adds P3r4 and P7 for `config` 0.15.26.
  It unsets `CARGO_TARGET_DIR`, passes an explicit `--target-dir`, counts a failed build or
  a missing or empty binary as FAIL, and carries a negative control for the size reader.
- **`probes-rerun-r4.sh`** (revision 4) reruns the carried `probes.sh` unedited, once with
  `CARGO_TARGET_DIR` inherited and once with it removed, and asserts both totals.
- **`r4-checks.sh`** (revision 4) asserts each revision-4 repair in this file, pins every
  carried evidence file and `review/evidence/snapshots/` by sha256, counts the `REST`,
  `R8.1`, `R9.1` and `R11.2` absences in `raw/muse.md`, asserts the uncommitted policy
  inputs, pins R74, R58 and R80 at the revisions read and asserts the cited lines, and
  asserts the totals line of every revision-4 log.

**Counts, in place.** Revision 1, carried: `figures.sh` **PASS=121 FAIL=0 SKIP=0**;
`sources.sh` **PASS=84 FAIL=0 SKIP=0**; `probes.sh` **PASS=34 FAIL=0 SKIP=0** — 239.
Revision 2, carried: `rest-conformance-r2.sh` **PASS=91 FAIL=0 SKIP=0**, the revision-2
run. Revision 3, new:
`ov-allocation-r3.sh` **PASS=43 FAIL=0 SKIP=0**. Total **373 checks, 373 PASS, 0 FAIL,
0 SKIP**. Those are the committed logs' counts. Rerun against a later title,
`rest-conformance-r2.sh` gives **PASS=90 FAIL=1 SKIP=0**, the one failure being its own
revision-2 title check, named and accounted for above; that rerun is recorded in
`ov-allocation-r3.log`.

**Revision 4, new, on 2026-09-27:** `drift-r4.sh` **PASS=32 FAIL=0 SKIP=0**;
`probes-r4.sh` **PASS=37 FAIL=0 SKIP=0**; `probes-rerun-r4.sh` **PASS=6 FAIL=0 SKIP=0**;
`ov-allocation-r4.sh` **PASS=10 FAIL=0 SKIP=0**; `r4-checks.sh` **PASS=186 FAIL=0 SKIP=0**
at revision 4. Rerun at revision 5 after its group-C re-pin, `r4-checks.sh` reports
**PASS=184 FAIL=1 SKIP=0**; the one failure is its own revision-4 title check, by design.

**Carried scripts rerun in place on 2026-09-27, and what they report now.** `probes.sh`
reports **PASS=31 FAIL=3 SKIP=0** with `CARGO_TARGET_DIR` inherited and **PASS=34 FAIL=0
SKIP=0** with it removed (`probes-rerun-r4.log`). Revision 1's P6 sizes are therefore valid
only with `CARGO_TARGET_DIR` unset. `ov-allocation-r3.sh` reports **PASS=39 FAIL=4 SKIP=0 TOTAL=43** in the live
tree (`ov-allocation-r3-rerun-r4.log`). One of the four failures is its "no third item
claims OV-04" check, which fails because auditor reports quote the literal;
`ov-allocation-r4.sh` supersedes that census. The other three bind revision 3's own text
by design, as `rest-conformance-r2.sh`'s title check binds revision 2's: the revision-3
title, the history entry that called revision 3 "this file" and now names its commit
`1e3cdb5`, and revision 3's present-tense sentence that nothing in the conformance pass
moves, which revision 4 puts in the past tense. Its group-C pins and its 90/1/0 rerun of
`rest-conformance-r2.sh` still pass.

**Reproducibility, established rather than asserted.** The three revision-1 scripts were
re-run immediately after the run whose log is committed, and the second run's output was
diffed against that log; the diffs are recorded verbatim in
`review/evidence/rerun-diff.log`. `rest-conformance-r2.sh` was likewise re-run and diffed
at revision 2, and `review/evidence/rerun-diff-r2.log` records that diff; its only
differing line was the script's own timestamp header. Every input it reads is a file in the
tree or a git blob, with no network call, but its `OV-01`/`OV-02`/`OV-03` controls count
files in the live tree, and those counts grow as other items land (13 → 19 files for
`OV-01` by 2026-09-27, per claude audit finding 3). That log
is carried from revision 2 and is **not** regenerated here: re-running it now would show
the expected title failure and overwrite the record of the clean revision-2 run.
`ov-allocation-r3.sh` was re-run and diffed the same way, in
`review/evidence/rerun-diff-r3.log`, and differs only in its own timestamp header.
**Every `PASS` / `FAIL` / `SKIP` line is identical across the two runs**, which is
asserted in that log by a second diff taken over those lines alone. Revision 3 stated
that exactly three kinds of line vary. The empirical audit's rerun nine days later
refuted that (claude audit finding 3). Revision 4's item 2 still missed three kinds, found
by the round-2 empirical audit's rerun (`review/audit-claude.r4.md`, E1). The rule for
comparing across a re-run, as revision 5 states it, lists every kind of line that may vary
by design:

1. each script's own `# R77 … — <timestamp>` header line, and a resolved root path when
   the script runs from an extraction;
2. in `probes.log`, `probes-r4.log` and `probes-rerun-r4.log` (which embeds the output of
   `probes.sh` twice), lines that depend on the run or its environment rather than on a
   result:
   - inside cargo's captured output, the `mktemp -d` scratch directory name, which is new
     on every run, and cargo's own `Finished … target(s) in N.NNs` wall-time line;
   - the inherited `CARGO_TARGET_DIR` path, which appears in `probes-r4.log`'s
     `# inherited CARGO_TARGET_DIR:` header, in `probes-rerun-r4.log`'s `## run 1` header,
     and in cargo's `Running …` line;
   - the order of cargo's `test … ok` result lines, because cargo runs tests in parallel;
3. toolchain version lines (`# rustc:`, `# cargo:`) and the toolchain-sensitive absolute
   sizes and deltas they govern. `confique`'s delta moved from +16,480 B to +16,496 B
   between rustc 1.98.0 and 1.98.1. Only the size *thresholds* are asserted, and they held;
4. `DRIFT` lines, in `figures.log` and `drift-r4.log`. These are rolling-window counters,
   such as `recent_downloads`, which may move in either direction, plus newest-release
   fields, which move forward. They are never asserted. `figures.sh`'s own header says a
   counter moves only upward; that is wrong for a rolling window, and it is cosmetic
   because no `DRIFT` line is asserted;
5. tree-census counts: the `OV-01`/`OV-02`/`OV-03` file counts in `rest-conformance-r2.sh`,
   and the holder list and match counts in `ov-allocation-r3.sh`. These grow as other items
   land. `ov-allocation-r4.sh` counts declaring headings only, so its census changes only
   when a decision declares a number.

A `PASS` line that becomes `FAIL`, or a `SNAPSHOT` line that changes, is a real
difference.

**Rerun from a clean extraction.** `git archive 484fd2e | tar -x -C <tmpdir>` extracted
commit `484fd2e`, the revision *that* paragraph was written against — a revision-1 commit,
so `rest-conformance-r2.sh` did not yet exist in it. The extracted tree has no `.git` at
all — tested with `-e`, not `-d`, because a worktree's `.git` is a *file* rather than a
directory. All three revision-1 scripts were re-run from that extraction and gave the same
counts as in place at that commit: `figures.sh` **PASS=121 FAIL=0 SKIP=0**, `sources.sh`
**PASS=80 FAIL=0 SKIP=0** — 84 after four later additions — and `probes.sh` **PASS=34
FAIL=0 SKIP=0**. The full output, with the extracted commit named in its header, is
`review/evidence/archive-rerun.log`, and it is carried byte-identical from revision 1.
Revision 3 repeats the exercise for `ov-allocation-r3.sh` in
`review/evidence/archive-rerun-r3.log`, extracting the revision-3 tree and re-running from
it at the same **PASS=43 FAIL=0 SKIP=0**. That script has no SKIP branch to exercise:
every input it reads — the execution ledger, R80's decision, this file and the evidence
directory — is inside the repository and therefore inside the archive. Revision 2 had repeated it for its own script:
`review/evidence/archive-rerun-r2.log` records `git archive <tree> | tar -x` of the
revision-2 tree as staged — which is this commit's tree except for that log file itself,
since a log cannot carry the hash of the tree containing it — and
`rest-conformance-r2.sh` re-run from the extraction, giving the same **PASS=91 FAIL=0
SKIP=0**. The same log then exercises the one SKIP branch by re-running with `HOME`
pointed at an empty directory: the standard's clone is outside this repository and an
archive can never contain it, so group B must SKIP **by name**, and it does —
**PASS=67 FAIL=0 SKIP=1**, the single SKIP standing for the group's 24 checks, 67 plus 24
being the 91 above.

**The SKIP branches, exercised rather than assumed.** That extraction SKIPped nothing,
because every out-of-repository input — the org CLI Design Standard clone, the py and ts
clones, the local Cargo registry cache — was still present on this machine. A run in
which nothing SKIPs proves nothing about the SKIP paths, so `sources.sh` was run once
more from the same extraction with `HOME` pointed at an empty directory, which hides all
three. It produced, at commit `484fd2e`, **PASS=43 FAIL=0 SKIP=4** with each group named
individually: the standard blob (9 checks), the py pin (9), the ts pin (1) and the
registry cache (18). 43 plus those 37 is 80, that commit's in-place total — so nothing is
lost silently, and a missing external input is a named SKIP rather than a FAIL or an
invisible pass.

**Answer-shape validation.** `validate_answer_text(text, "crate")` from
`scripts/research_validation.py` returns no diagnostics for this item's raw report,
`raw/opus.md`. It is not applied to `DECISION.md`, and would not pass there: that
validator requires the prompt's fifteen `###` answer fields in order, while a decision
follows the synthesizer role contract's four `##` sections with a single
`### Principles and implementation` inside `## Decision` — the same shape as the accepted
R68 decision. `bash scripts/check-research-tree.sh .` passed at revision 1; it was not re-run
in revision 4, because it takes the publication lock and sibling items were being written in
the same checkout.

## Engines

**Two engine reports are required, and both are on disk.** The binding prompt reads
`- engines: muse, opus` (line 24 of
`research/topics/77-web-env-settings/prompts/web-env-settings.prompt.md`), and
`inputs/prompt.md` is byte-identical to it (sha256 `48610c1a…` for both).

- opus `raw/opus.md` — Claude Opus 5, sha256
  `a81c6372fe084f805fa4058c68e60af7064b354de69a2a0da0360b9c2a0ac533`, byte-identical to
  the registered `raw/opus-a81c6372….md`, answer shape OK under
  `validate_answer_text(..., "crate")`. Recommends adopting no crate: template code
  over `std::env::vars_os` and `str::FromStr`, prefix `RSLBP_WEB_` derived by `const fn`
  from R57's `TOOL_NAME`, value threaded through the framework's own state mechanism;
  runner-up `config` 0.15.25 with default features off; `confique` third.
- muse `raw/muse.md` — Muse (Meta), model `muse-spark` per the run manifest's Muse
  operation, researched 2026-09-25, 204 lines, sha256
  `a2e9a208f6e8bb269ac396ea1f1bff605cb549c403ce676539cbb61dc2123426`. The ledger records
  the collection and a crate-shape pass: "R77 MUSE LEG COLLECTED, 2026-09-25: sha
  a2e9a208 (204 lines, crate OK)" (`docs/planning/p02/execution-ledger.md:1173`).
  Recommends `config = { version = "0.15", default-features = false }`, verified at
  0.15.26 (`raw/muse.md:118-125`); runner-up `envy` 0.4 (`:129`); `figment` shortlisted
  third; nothing excluded by a gate (`:102`).

**How the engine requirement changed, and on whose authority.** At admission the item
required Codex and Opus. The Codex leg was deferred under owner ruling `W1-CODEX3` of
2026-09-18, which is why revisions 1–3 were synthesized from Opus alone. On 2026-09-21
the controller migrated the leg from Codex to Muse. The run manifest records the event:
`"from": "codex"`, `"to": "muse"`, `"reason": "muse bulk substitution (owner decision
Q5.A 2026-09-21)"`, `"previous_required_engines": ["codex", "opus"]`, and the manifest's
`required_engines` is now `["muse", "opus"]`. Owner decision Q9.B then retired Codex from
P02. The live policy is the `engine_overrides` pilot as extended by owner decision Q17.A
(2026-09-27). `research/RUNBOOK.md` lines 69–75 list R77 in the Muse substitution set,
and `research/EXECUTION.json` gives R77 `["muse", "opus"]` both under `engine_overrides`
and under `items`. `inputs/EXECUTION.json` carries the same R77 entry. These policy and
prompt files, and `raw/muse.md` itself, were uncommitted working-tree state when this
revision was written. The run manifest and `operations/muse.json` still record the Muse
operation as `submitting`, with no collection event. Registering the collection is
the controller's step, and it is recorded as a gap under **Where evidence is incomplete, stated plainly** below.

- **No engine report cites the org REST API Design Standard v2.0.0.** The Opus report
  was produced on 2026-09-18 before owner ruling W2-REST landed. The Muse report was
  produced on 2026-09-25, after it, and still cites no rule of the standard: `raw/muse.md`
  contains none of `REST`, `R8.1`, `R9.1` or `R11.2` (`r4-checks.sh` counts them). Every
  claim in `#### Conformance to the org REST API Design Standard v2.0.0 (W2-REST)`, both
  moves and `OVERRIDE (OV-04)` are therefore the synthesizer's reading of the standard at
  its pinned blob, not a synthesis of engine output. No engine has reviewed that reading,
  so the nineteen rule quotations are asserted at their lines. A reader can check the
  reading against the text, not against an engine's summary.

#### Disagreements between the engines, and what settled each

Fable's audit listed six disagreements (items 1–6 below). Items 7–10 are further
differences found while reading the Muse report in full. Each is settled by evidence
already in this run, by a new probe, or by an owner-accepted decision. **None moves the
recommendation, the runner-up or the `envy` re-evaluation condition.**

| # | Point | Opus, and this decision | Muse | What settled it | Outcome |
|---|---|---|---|---|---|
| 1 | Recommendation | No crate; template code | `config` 0.15 without default features (`raw/muse.md:118-125`), on adoption, maintenance and "reuse with R53" (`:81`, `:112`) | Items 2–5 and 7 below remove Muse's grounds one by one. Adoption is not a fitness gate. The reuse premium assumes "if R53 also selects `config`" (`:112`). R53 is published: "`serde` with the `derive` feature … and no dedicated validation crate", and "No dependency is added by this item" (`research/topics/53-config-schema-validation/DECISION.md:67-69`, `:81`). R54's current revision rejects `config` and `figment` as layer-merging engines for the CLI (`research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md:303`). Muse rejects hand-rolled code because "every fork re-implements prefix stripping, type parsing and error rendering" (`:45`). A template's forks inherit the module; they do not re-implement it | **Recommendation holds.** Muse's pick is this decision's runner-up, so both reports rank `config` first among crates |
| 2 | Fitness gate 2 | Strict reading: `envy`, `figment` and three others fail for declaring no `rust-version` | Passes `envy` and `figment` "by construction age plus current-toolchain evidence" and "Rocket-canary reasoning", and excludes nothing (`:94`, `:102`) | The owner withdrew the lenient reading on 2026-09-11: "The ruling is withdrawn" (`docs/planning/p02/owner-decisions.md:460`). The strict reading is the one R69 applies | **Exclusions stand.** Muse's runner-up `envy` is not admissible under the strict reading, so the runner-up stays `config` |
| 3 | Maintenance labels for `figment` and `envy` | `at-risk` | `stable-quiet` (`:88`, `:89`) | Both engines measured the same signal: Figment 1 of 10 recent issues answered, 185 days to first response (`:88` for Muse). The prompt's rubric says "`at-risk` needs a concrete signal" (prompt line 61), and 1-of-10 with a 185-day response is concrete. Revision 4 added a new signal: Figment's default branch has zero commits since 2024-09-14 despite a renewed `pushed_at` (`drift-r4.sh`). For `envy`, Muse's responsiveness window was "partially unretrievable" (`:89`); Opus's 1 of 10 at 73.42 days is carried | **`at-risk` stands** for both. The two engines differ on the label, not on the measurement |
| 4 | Error shape | Template code names the variable; `config` names only a lowercased key, so reaching R67's `hint` needs a translation layer | `config`'s error "names field, expected type and offending value", and "a thin `map_err`" maps it (`:53`) | P3 run 1, and P3r4.1 for 0.15.26: ``… for key `port` in the environment``. Muse's own observed string (`:53`) also says `port`. R67 requires `hint` to "name the offending input", and the input is `RSLBP_WEB_PORT`. Rebuilding that from `port` requires the prefix and the case rule, which is the translation layer | **The measured table stands** |
| 5 | Placement | `crates/web/src/settings.rs`; `crates/core` must contain no `std::env` call (AC7b) | "the library crate" (`:113`) | Under R69 revision 10, `crates/web` is itself a library crate: an optional workspace member. If Muse means `crates/core`, three things rule it out: AC7b; `web-extra-surface`, under which the settings must not exist when the `web` feature is off; and R67's layering, which keeps process-level concerns out of the core library | **`crates/web`** |
| 6 | Figures | `config` 0.15.25, `rust-version` 1.85.0 (2026-09-18) | 0.15.26, 1.88.0, released 2026-09-21 (`:125`) | Muse was right as of its date. `drift-r4.sh` confirms 0.15.26 / 1.88.0 on 2026-09-27; `probes-r4.sh` measured it | **Both recorded.** No gate moves; the runner-up range already admits 0.15.26 |
| 7 | Loader shape | `Environment::with_prefix(…)` with no separator | `.separator("_")` (`:71`) | Probe P7, `config` 0.15.26, injected map: with the separator, `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS=3` deserializes to the default 8, silently; without it, to 3 (`probes-r4.log` P7.1, P7.2). Muse's own trailing-underscore observation (`:77`) reproduces as P7.3 | **Muse's exact loader would silently ignore every multi-word variable in this surface.** The runner-up snippet sets no separator |
| 8 | Prefix derivation | `const fn` over R57's `TOOL_NAME = "rslbp"`, checked at compile time (P1) | Runtime `format!` over `APP_NAME = "rs_launch_blueprint"` (`:65`, `:68`) | R57 is published with `pub const TOOL_NAME: &str = "rslbp";` (`research/topics/57-xdg-directory-set/DECISION.md:254`). Muse's constant would yield `RS_LAUNCH_BLUEPRINT_WEB_`. Either derivation satisfies F324; the `const fn` form also fails at compile time on a non-ASCII name | **`RSLBP_WEB_`, derived by `const fn`** |
| 9 | Tests | Injected variable list, no `unsafe` (P2, P4) | Tests that mutate the environment "need `unsafe` blocks or an injection seam", run with `--test-threads=1` (`:125`) | R06's unsafe policy rules out the first option. P4 shows the seam working, with four tests in parallel and the environment untouched | **The seam is the only path.** Muse names it as one of two |
| 10 | Gate 1 | `inapplicable — owner ruling 2026-09-12 (Q7.B)` | Licence "pass" for all three (`:93`) | Q7.B makes gate 1 inapplicable to every dependency | **Inapplicable**; no candidate changes |

**Where the two reports agree, which counts as corroboration from a second model
family:**

- Edition 2024 makes `std::env::set_var` unsafe (`:125`; P2).
- `config` takes its prefix without the trailing separator (`:77`; the runner-up's
  `trim_end_matches('_')`; P7.3).
- No RustSec advisory for `config`, `figment` or `envy`, and 0 `unsafe` in their `src/`
  (`:95`).
- `config`'s default features are dead weight for an env-only surface, so it is taken
  with `default-features = false` (`:97`).
- Threading through `State`/`Data` as a plain owned value (`:49`).
- ts has no web service (F303), so ts gets a forward-looking pattern only (`:38`).
- No `CONFLICT:` line and no `BASELINE-REVIEW:` line (`:38`, `:145`).

**Re-verified in this run — claim by claim.**

| Claim | How it was re-verified | Outcome |
|---|---|---|
| Gate 2: `envy` 0.4.2, `figment` 0.10.19, `envconfig` 0.11.1, `serde-env` 0.3.0, `envious` 0.3.0 declare no `rust-version`; `config` declares 1.85.0, `confique` 1.68.2, `serde` 1.56 | crates.io `/versions`, snapshot **and** live re-fetch of the immutable per-version field | **reproduced exactly** for the pinned versions. Revision 4 adds that `config` 0.15.26, the newest release since 2026-09-21, declares 1.88.0 (`drift-r4.sh`) |
| Every download, star, `archived`, `pushed_at` and open-issue figure cited | crates.io and GitHub REST, snapshot + live | **reproduced exactly on 2026-09-18.** On 2026-09-27 (`drift-r4.sh`) three repository figures had moved: Figment `pushed_at` 2024-09-13 → 2026-09-27; `serde-env` `pushed_at` 2026-04-15 → 2026-09-19 and open issues 1 → 0; `config-rs` stars 3,210 → 3,214 and `pushed_at` → 2026-09-25. None moves a label; see the Figment bullet under `#### Fitness gates` |
| Current stable is 1.98.1, so the floor is 1.96 | `channel-rust-stable.toml`, `[pkg.rust] version` | **reproduced exactly** |
| No RustSec advisory for any of the eight crates | 404 for all eight, with `atty` and `time` as HTTP 200 controls | **reproduced exactly** |
| The `const fn` prefix derivation compiles, evaluates in const context, and follows a renamed `TOOL_NAME` | probe P1, strengthened with `const _: () = assert!(…)` so a wrong value is a compile error | **reproduced** |
| Edition 2024 makes `set_var` unsafe | probe P2, strengthened with an edition-2021 control that compiles and runs | **reproduced, with a control the raw did not run** |
| The five `Display` strings for `RSLBP_WEB_PORT=eighty` | probe P3 run 1, asserted verbatim | **reproduced exactly** (the `confique` string names the probe's struct, `WebSettingsC`) |
| `figment` and `confique` have no injected-source seam | probe P3 run 2, with the process environment cleaned via `env -u`, plus the source lines at `figment/src/providers/env.rs:171,:198,:505` and `confique/src/builder.rs:38`, `src/internal.rs:54` | **reproduced, and sharper**: both silently return defaults while template code, `envy` and `config` report the error |
| The four axum tests, including `FromRef<AppState> for Arc<WebSettings>` | probe P4 against real axum 0.8.9 / tokio 1.53.1 / tower 0.5.3 | **reproduced** — 4 passed, 0 failed |
| `confique` rejects a non-literal env name | probe P5 | **reproduced** — `error: expected string literal` |
| Package counts 8 / 9 / 12 / 11 / 16 / 55 | probe P6, asserted individually; revision 4's P6r4, with build status checked and `config` 0.15.26 added (11) | **reproduced exactly**. Revision 1's P6 sizes are valid only with `CARGO_TARGET_DIR` unset; see `## Empirical check` |
| `unsafe` posture of `config`, `confique`, `envy`, `figment` | registry cache at exact versions | **reproduced** — 0 in each `src/` |
| Every quotation from the org CLI Design Standard, the owner rulings, the ledger, the owner-reference document, R69 revision 10, R57 revision 2, and the py and ts pins | `sources.sh`, at the cited line | **reproduced exactly**, every line number included |
| Each `- assumes` line | extracted from the live `docs/port/PARAMETERS.md` by script and compared | **byte-identical**; `inputs/PARAMETERS.md` and the live registry are also identical, so nothing moved during the run |

**Gaps the raw report stated, and what this run did about them.**

| Gap | Disposition |
|---|---|
| `unsafe` posture, default features and platform support of `envconfig`, `serde-env`, `envious` "not extracted" | **closed for `unsafe` and features.** The three crates were fetched and their `src/` trees audited: **0** `unsafe` in each; all three are edition 2021 with no async coupling. They were not *built*, so gate 4 remains stated rather than measured for them — they are excluded at gate 2 regardless. |
| `serde`'s own `unsafe` posture, carried from R53 revision 2 | **closed.** Re-audited here: exactly **2** `unsafe` blocks in `serde-1.0.229/src/`, both `str::from_utf8_unchecked`, matching R53's recorded figure. |
| `confique`'s declared `rust-version = 1.68.2` never compiled on 1.68.2 | **still unproven.** Only current stable was exercised; proving it needs an old toolchain. It does not bear on the recommendation, which does not adopt `confique`. |
| Windows behaviour | **still unproven, and not required.** `target-os-matrix` is `ubuntu-latest, macos-latest`. |
| Binary sizes are `aarch64-apple-darwin` only | **unchanged.** `x86_64-unknown-linux-gnu` was not measured; only the deltas and the three thresholds asserted in P6 are treated as findings. |

**Claims carried, not re-verified.**

- **Issue-responsiveness medians** (`config-rs` 0.22 days / 9 of 10 answered; `confique`
  68.06 / 7 of 10; `envy` 73.42 / 1 of 10; `figment` 185.0 / 1 of 10). Re-sampling them
  costs roughly 44 further GitHub calls at a 21-second floor and they do not decide the
  answer — gate 2 does. They are carried from `raw/opus.md` and labelled as carried
  wherever they support a maintenance verdict.
- **Adoption rows** (`nextest-runner`, `leptos_config`, `tor-config`, `mise`,
  `esp-idf-sys`, `axum-client-ip` and the rest). The raw report confirmed each through
  `GET https://crates.io/api/v1/crates/<adopter>/<version>/dependencies`; those calls were
  not repeated here. They inform the landscape, not the gates.
- **py's and the owner-reference document's wider content** beyond the lines asserted in
  `sources.log`.

**Claims from the raw report that this run could NOT reproduce.**

1. **The baseline stripped binary size of 302,704 B.** Re-measuring gave **286,048 B**
   for a baseline built here. The figure is not recoverable, because the raw report did
   not publish the body of its baseline program and a stripped size depends on it. The
   consequence is favourable rather than adverse: the raw reported template code as
   80 bytes *larger* than `envy`, while this run measures it **16,576 bytes smaller**.
   Because of this, `## Decision` cites only **deltas** over a baseline whose source is
   in `probes.sh`, and `probes.sh` asserts five size *thresholds* and never an absolute
   byte count.
2. **The raw's statement that the first five clean-build times "are within this machine's
   noise of each other".** This run measured `figment` at 14.11 s against a 6.15 s
   baseline — about 2.3× — which is outside anything this run can call noise. It is a
   single sample on a machine also running network polling, so it is not asserted either
   way and no conclusion is drawn from it; the sentence is simply not carried. The one
   build-time figure this decision does use is `config` with default features at
   roughly 3× the baseline, which reproduced in direction and magnitude (19.05 s versus
   the raw's 25.88 s, against baselines of 6.15 s and 8.48 s).

**One claim the raw stated with a qualifier this decision keeps.** `config`'s transitive
`pathdiff` 0.2.3 declares no `rust-version` (re-verified here at the versions endpoint).
`config` is not excluded for it only because the *third*, strictest reading of gate 2 is
the one `docs/planning/p02/owner-decisions.md` says "is not on the table unless you put
it there". If the owner ever puts it there, `config` — the ranked runner-up — falls too,
and template code becomes the only surviving answer rather than the preferred one.

**Where evidence is incomplete, stated plainly.** The 8-second shutdown budget is the
weakest-supported value in this decision: the *rule* (strictly less than the platform's
SIGKILL point, measured from the signal) is high-confidence, but the number is a judgement
about margin, resting on a platform datum for a platform this template does not target.
The readiness pause is now the second consumer of the same budget, and it is bounded by
the budget rule. An owner could reasonably set 5, 8 or 9. The pause default of 0 is
likewise a judgement. The part not verified is whether Cloud Run stops routing at
SIGTERM, and no source for that is in this run. The comma-separated list encoding is likewise medium-confidence:
it is the Rust idiom and it is safe for this field set, but R76 owns CORS semantics and
could need an encoding that survives a comma.

Four further gaps are recorded in revision 4:

- **The Muse collection is not registered.** `raw/muse.md` is on disk and untracked. The
  run manifest and `operations/muse.json` still show the Muse operation as `submitting`.
  This decision synthesizes the file by its sha256 `a2e9a208…`. The controller must
  register that hash before acceptance can bind to it.
- **The policy inputs are uncommitted.** The live prompt's `- engines: muse, opus`
  line, the Q17.A `engine_overrides` extension, the RUNBOOK paragraph and ledger lines
  1173 and 1215 were working-tree edits when this revision was written. Their content was
  read and asserted (`r4-checks.sh`), but it is not yet at a commit.
- **Three coupled decisions cited here are unaccepted.** R74 revision 1 and R58 revision
  1 are untracked working-tree files. R80 revision 3 is landed but unpublished. Revision 4
  pins each by sha256 in `r4-checks.sh`. R74 and R80 are being revised in parallel with
  this revision, so their line numbers may move.
- **`confique`'s `rust-version` 1.68.2 has never been compiled on 1.68.2.** This is
  carried from revision 1 and does not bear on the recommendation.

**What P03 must validate.** AC6 (a malformed variable exits `2` with R67's `RSLB203`
envelope on stderr and a byte-empty stdout); AC7 and AC7b (the environment is read in
exactly one file in `crates/web`, and never in `crates/core`); AC8 (a SIGTERM during an
in-flight request drains and the process exits `143` within the budget); AC9 (the
documented variable table and the struct's field list cannot drift); AC10 (with the `web`
feature off, neither the settings type nor the environment read exists in the binary);
and AC15 (the readiness pause and the drain together fit inside the 8-second budget,
and a pause that does not fit is a boot failure).

**Added by revision 4.** AC16 (the serve binary builds `WebSettings` before
`telemetry::init`, and telemetry reads no environment variable). AC14 is re-pointed at
R74's published membership.

**Added by revision 2, from the W2-REST pass.** AC11 (no `RSLBP_WEB_*` value reaches a
response and no field is secret-shaped — `R8.12`); AC12 (`RSLBP_WEB_ROOT_PATH` carrying a
version-shaped segment is a boot failure while an ordinary prefix is accepted — `R9.1` and
Move 1); AC13 (no template-named variable selects an applicability switch — `R1.6`); AC14
(with no rate-limit variable set the service still limits and answers `429` with
`Retry-After` — `R11.2` and Move 2). Two further things P03 inherits rather than checks:
`OVERRIDE (OV-04)` needs an approver and a date before the conformance note can be
written — the note itself is R69's or R71's artifact, not this item's — and the
`RSLBP_WEB_RATE_LIMIT_*` family has no *published* members until R74 publishes, so AC14
cannot run before it does.
