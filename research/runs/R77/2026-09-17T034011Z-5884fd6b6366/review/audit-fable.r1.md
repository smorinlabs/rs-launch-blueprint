actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 5985ee47d5c714fdc317d5b8a8c58aff9c01b3f552834de8ac0b9c5282bb92fd
verdict: reject
unresolved-findings:
- F1 (blocking; JF-3, JF-2): `## Engines` omits the collected Muse report and states a stale engine requirement.
- F2 (non-blocking; JF-5): R77 decides R74's owned rate-limit family membership ("at least four members"), and R74 has since fixed three.
- F3 (blocking; JF-5): the readiness-propagation pause has no owner, because R77 and R80 each say the other decides it.
- F4 (non-blocking; JF-5): the ordering of `from_env()` and R58's `telemetry::init` at the start of the serve binary's `main` is unreconciled.
- F5 (non-blocking; JF-1): the file describes itself, R80 and one revision-2 check in terms that are now stale.
- F6 (non-blocking; JF-8 drift): the `config` gate-2 figures cite 0.15.25, but 0.15.26 is now the newest release.

# R77 web-env-settings — judgment audit, round 1, against revision 3

**Purpose.** This file judges whether revision 3 of R77's `DECISION.md` reasons soundly
and represents its inputs faithfully. It does not rerun the decision's scripts; the
empirical audit owns that. The verdict is **reject**. Two findings block acceptance
(F1 and F3). Neither of them shows that the recommendation (no crate: template code over
`std::env::vars_os` and `str::FromStr`) is wrong. They show that the decision was not
synthesized from both required engines (F1), and that the readiness-propagation pause is
owned by no item (F3). Four non-blocking findings (F2, F4, F5, F6) are text or coupling
repairs.

**Target.** `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md`,
revision 3, dated 2026-09-18. The expected sha256 was
`5985ee47d5c714fdc317d5b8a8c58aff9c01b3f552834de8ac0b9c5282bb92fd`, and `shasum -a 256`
recomputed the same value before any other read.

**What was judged against.** Everything was judged against the state on 2026-09-26, as
instructed, not against the state on 2026-09-18:

- the live prompt `research/topics/77-web-env-settings/prompts/web-env-settings.prompt.md`
  (identical to `inputs/prompt.md`; both now read `- engines: muse, opus`);
- the live `docs/port/PARAMETERS.md`;
- `research/RUNBOOK.md` §5, the synthesizer and auditor contract;
- the raw reports under `raw/`;
- the published prerequisite decisions under `research/topics/*/DECISION.md` (R53, R55,
  R57, R67, R69 revision 9);
- the owner-accepted but unpublished revisions the decision relies on (R69 revision 10,
  R54 revision 3, R56 revision 2, per `docs/port/OWNER-ACCEPTANCES.md`);
- the latest landed revisions of the coupled items R58, R74, R76 and R80.

No `review/audit-*.md` file and no `review/Rxx-r*-snapshot.md` file was read.

## Check results

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (F5; F2 also creates an internal contradiction) | Stale self-labels are listed under F5. The recommendation, the parameters and the acceptance criteria are otherwise consistent with one another. |
| JF-2 prompt questions and constraints | **fail** on the engine constraint (F1). The questions pass. | All six questions are answered: the HIGH crate question (the landscape, the gates, "no crate"); compile-time prefix derivation (`const fn`, probe P1, and P5 for `confique`'s literal-only attribute); the cross-repo principle (the must-agree / may-vary table, and why ts is not a harmonization target); threading through state (`State`/`FromRef`, `web::Data`, `AddData`; probe P4); the error shape (the measured five-row table, and `RSLB203` with no translation layer); layering (A1, and the runner-up's file-tier condition). The binding `- engines: muse, opus` line is not honored (F1). |
| JF-3 `## Engines` fidelity | **fail** (F1) | The Opus report is represented faithfully. I compared `raw/opus.md` `### Recommendation` with the decision: same slots, same five grounds, runner-up `config`, `confique` third. The Muse report is absent. |
| JF-4 load-bearing claims trace to sources | **pass** | See the spot-check list below this table. |
| JF-5 couplings hand over owned choices | **fail** (F2, F3, F4) | R76's encoding hand-off is clean: R76 revision 2 lines 278–284 consume exactly "a possibly-empty ordered collection" and leave naming and decoding to R77. The R58 hand-off of log values is clean on values. R74 and R80 are not clean. |
| JF-6 `assumes` lines byte-identical to the registry | **pass** | Each of the six `- assumes` values is exactly equal to the `value` cell of its row in the live `docs/port/PARAMETERS.md`. The comparison was a cell-equality test, not a substring test. The working-tree change to that file touches only `ci-job-structure`. |
| JF-7 no conflict with accepted or published prerequisite values | **pass**, with notes | `RSLB203` → exit `2` matches R67's published value. `TOOL_NAME = "rslbp"` is at R57 `DECISION.md:254`. `inputs/prerequisites.json` pins R69 at `d4507f5b…`, which is still the published revision 9. The use of revision 10's `crates/web` paths is declared, justified and carried as a re-verify trigger, and it matches the owner re-bind W0-R69c and R02 revision 2. R54 and R56 have since landed revisions 4 and 3. Both are evidence-only repairs that leave the recommendation unchanged. The A1 quotation still appears verbatim at R54 revision 4 line 269, and the chain `--token-file` > `RSLBP_TOKEN` > stored credential still appears at R56 revision 3 line 103. |
| JF-8 evidence scripts exist and counts match | **pass**, with drift F6 | The committed logs report: `figures.log` 121/0/0; `sources.log` 84/0/0; `probes.log` 34/0/0; `rest-conformance-r2.log` 91/0/0 (the revision-2 run); `ov-allocation-r3.log` 43/0/0. `ov-allocation-r3.log` lines 41–42 assert the expected 90/1/0 result and the single title failure. `archive-rerun.log` records 121, 80, 34 and the HOME-hidden run at 43/0/4. `archive-rerun-r2.log` records 91/0/0 and 67/0/1. `archive-rerun-r3.log` records 43/0/0. Every script the decision cites has a log. |
| JF-9 decision shape | **pass** on structure | The H2 order is `## Decision` (containing `### Principles and implementation` and a `re-verify:` line), `## Parameters`, `## Empirical check`, `## Engines`. `## Supersedes` is correctly absent because this is not a reversal. The *content* of `## Engines` fails under F1. |
| JF-10 recommendation follows from the evidence | **pass on the evidence assembled**, subject to F1 | The recommendation follows from gate 2 under the strict reading, the edition-2024 injection seam (P2, P3 run 2), the measured error strings (P3) and the prefix survival test (P5). F1 must still show that the recommendation survives the Muse dissent. I expect it to survive, because Muse's `config` pick rests on a gate-2 reading the owner withdrew, and `config` is already the decision's runner-up. |

### JF-4 spot-checks

Each item below is a load-bearing claim and the evidence line that supports it.

- **The template-code error string.** `probes.log` lines 40 and 52: `RSLBP_WEB_PORT: invalid value "eighty": expected a TCP port in 0..=65535 (invalid digit found in string)`.
- **`confique` rejects a non-literal environment-variable name.** `probes.log` line 29: `error: expected string literal`.
- **`envy` declares no `rust-version`.** `figures.log` line 10 (`rust_version (None)`), and the committed snapshot `cratesio-envy-versions.json` (0.4.2, 2021-01-04, `None`).
- **py's field count.** `sources.log` line 67: `py WebSettings declares 12 fields`.
- **Current stable Rust.** Re-fetched today from `https://static.rust-lang.org/dist/channel-rust-stable.toml`: `1.98.1 (48a229cea 2026-09-01)`. The 1.96 floor still holds.
- **The OV-04 allocation.** `docs/planning/p02/execution-ledger.md` lines 1073, 1080 and 1082 record the collision, R80's renumber to `OV-05`, and R77 keeping `OV-04`. A census today finds the literal `OVERRIDE (OV-04)` in exactly two files, this decision and the ledger. R51, R70, R76, R79 and R80 mention the number only by bare reference.

## Findings

### F1 — `## Engines` omits the collected Muse report and states a stale engine requirement (blocking; JF-3, JF-2)

**Failed claims.**

> "codex — **absent.** The focused-tier Codex research leg is deferred by the controller
> under owner ruling **W1-CODEX3** … and the run manifest records `state: partial` with
> `required_engines: [codex, opus]`. **This decision is therefore synthesized from a
> single engine.** There are no inter-engine disagreements to settle"

> "The org REST API Design Standard v2.0.0 is a binding input that neither engine had."

**Evidence.**

- **The requirement changed.** The live prompt and `inputs/prompt.md` now read
  `- engines: muse, opus`, and add "This item substitutes Muse (Meta) for Codex under the
  `engine_overrides` pilot; its mirrored `- engines:` line is authoritative."
  `manifest.json` records the migration event: `"from": "codex"`, `"to": "muse"`,
  `"reason": "muse bulk substitution (owner decision Q5.A 2026-09-21)"`, and
  `"required_engines": ["muse", "opus"]`. `RUNBOOK.md` §2 lists R77 in the Muse bulk set
  and records Q9.B retiring Codex from P02. The owner authorization is recorded at
  `execution-ledger.md` line 1114: "Owner decision (2026-09-21, Q5.A): Muse-bulk all 17
  remaining legs".
- **These inputs are uncommitted working-tree state.** At `HEAD`,
  `research/EXECUTION.json`'s `engine_overrides` lists only R72 and R84, and
  `git show HEAD:research/RUNBOOK.md` does not list R77 in the Muse set. The `- engines:`
  change in both prompts, the manifest migration event, the RUNBOOK paragraph and ledger
  line 1173 are all working-tree modifications. This audit is therefore bound to
  uncommitted inputs. The controller should commit them before acceptance binds to them.
- **The Muse report exists and was collected.** `execution-ledger.md` line 1173 reads:
  "R77 MUSE LEG COLLECTED, 2026-09-25: sha a2e9a208 (204 lines, crate OK) — config ^0.15
  (verified 0.15.26) with default-features=false; runner-up envy 0.4." The file
  `raw/muse.md` has sha256
  `a2e9a208f6e8bb269ac396ea1f1bff605cb549c403ce676539cbb61dc2123426`.
- **The collection is not registered.** `operations/muse.json` and the manifest's
  `operations.muse` still read `"state": "submitting"`, and `raw/muse.md` is untracked.
  This is controller bookkeeping, but acceptance cannot bind an unregistered report.
- **Muse disagrees with the decision on substance.** Every one of these points is
  unadjudicated. Line numbers refer to `raw/muse.md`.
  1. **Recommendation** (lines 116–122). Muse recommends `config = { version = "0.15", default-features = false }`. The decision recommends no crate.
  2. **Gate 2** (Qualified shortlist, gate 2). Muse *passes* `envy` and `figment` by "construction age plus current-toolchain evidence" and "Rocket-canary reasoning", and lists nothing under `### Excluded by gate`. That reading conflicts with the strict gate-2 reading the decision applies, which `docs/planning/p02/owner-decisions.md` records as settled on 2026-09-11 ("The ruling is withdrawn").
  3. **Maintenance states.** Muse rates `figment` and `envy` `stable-quiet`. The decision rates both `at-risk`, and that rating rests on responsiveness figures the decision carries without re-sampling.
  4. **Error shape.** Muse credits `config` with "structured errors (expected type + offending value)" and proposes "a thin `map_e[rr]`" into R67's taxonomy. The decision's measured P3 string shows that `config` names only a lowercased key `port`, and the decision claims that no translation layer is needed.
  5. **Placement.** Muse places `WebSettings` and the prefix derivation "in the library crate". The decision places them in `crates/web`, with `crates/core` barred from reading the environment (AC7b).
  6. **Figures.** Muse cites `config` 0.15.26, released 2026-09-21, declaring `rust-version` 1.88.0. The decision cites 0.15.25 declaring 1.85.0 (see F6).
- **Consequence.** The decision's statements that there are "no inter-engine
  disagreements to settle" and that "a second engine has reviewed none of it" are no
  longer true as descriptions of the item's evidence. RUNBOOK §5 requires `## Engines` to
  cover "all reports and evidence checks, disagreements, and the evidence that resolved
  each disagreement".

**Repair.**

1. The controller records the Muse collection in the manifest and in
   `operations/muse.json`, with the raw sha256 `a2e9a208…`.
2. A revision 4 lists `raw/muse.md` under `## Engines`, with its model identity and hash.
3. Revision 4 adjudicates disagreements 1–6 with evidence. Most of that evidence is
   already in the run: the strict gate-2 ruling for point 2; P3 run 1 for point 4; AC7b
   and R67's rule that the library crate must write to no process stream for point 5; a
   refreshed snapshot for point 6.
4. Revision 4 states whether the recommendation, the runner-up or the `envy`
   re-evaluation condition moves.
5. Revision 4 replaces the "codex — absent" bullet and the `required_engines: [codex, opus]`
   quotation with the migration history. It also reconsiders whether "neither engine had"
   the REST standard is still accurate. Muse ran on 2026-09-25, after W2-REST, and cites
   no REST rule.

### F2 — R77 decides R74's owned rate-limit family membership (non-blocking; JF-5, and an internal contradiction under JF-1)

**Failed claims.**

> "The family has **at least four members**, because R8.10's axis default names at least
> four dimensions … and a single scalar cannot carry them."

The same decision also states:

> "R74 fixes which members exist, their units and their values"

and:

> "**The `WebSettings` field count is still twelve** — py's single `rate_limit` field
> becomes one typed field whose members R74 fixes".

The variable-set table repeats the four-member floor: "so the family has at least four
members".

**Evidence.**

- **The floor constrains R74's owned choice.** The decision's own table assigns
  membership to R74, yet the decision sets a numeric floor on that membership.
- **R74 has since fixed a different number.** R74 revision 1
  (`research/runs/R74/2026-09-18T215916Z-14066395aaea/review/DECISION.md`) lines 410–414
  fix three members: `RSLBP_WEB_RATE_LIMIT_PER_IP`, `_PER_IP_BURST` and `_MAX_ENTRIES`.
  R74 states: "R77 infers *'at least four members'* from R8.10's four dimensions; three
  suffice **because** `OVERRIDE (OV-17)` ships one dimension".
- **R74 contradicts the field count.** R74 line 452 hands R77 "Three fields for the
  `RSLBP_WEB_RATE_LIMIT_*` family". That contradicts "one typed field" and "still twelve".
- **R77's own escape clause does not cure the floor.** R77 already says: "If R74
  publishes a posture that needs a different member set, the family prefix still holds
  and only the membership moves." R74 lines 414–415 quote that clause. So R77 does hand
  membership over. The defect is that the "at least four" floor and the "still twelve"
  count are inconsistent with that clause and with R74's result. This is why F2 is
  non-blocking: it is a text repair, not a missing hand-off.
- **The two items' texts conflict.** R74 is not yet accepted, but as written the texts
  disagree. The no-disabling-default constraint is acceptable, because R11.2 grounds it
  and R74 adopts it.

**Repair.**

1. Revision 4 withdraws the "at least four members" floor. In its place it states that
   R8.10's dimensions are an *input R77 hands to R74*, and that the family's size is
   whatever R74 publishes.
2. Revision 4 restates the field-count and hand-maintenance claim so that it survives
   R74's shape, either as "twelve py-derived fields, with the rate-limit family
   contributing one field per member R74 publishes" or as the explicit count once R74 is
   accepted.
3. Revision 4 re-points AC14 and the re-verify trigger at R74's published membership.

### F3 — The readiness-propagation pause has no owner (blocking; JF-5)

**Failed claim.**

> "R80's raw says of its pre-drain readiness pause: 'R77 owns the window's value, and the
> mechanism is inert if that value is zero' … This decision therefore fixes **8 seconds as
> the budget** and records that, if R80 publishes a non-zero readiness pause, that pause
> is spent *from* the 8 seconds rather than added to them. R80 decides the split; this
> item decides the budget."

**Evidence.**

- **R80's decision withdrew the sentence R77 quotes.** R80 revision 3 has landed; R77
  revision 3 itself cites R80's renumber in that revision. At lines 314–318, R80
  revision 3 says: "**no item owns its value today** — see the correction under
  `## Engines`: `raw/opus.md` says R77 owns it, and R77's own in-flight report owns a
  drain *deadline* … and names no propagation pause on any line … This decision therefore
  **hands R77 a requirement rather than citing a fact**".
- **R80 hands the pause back to R77.** R80 lines 750–752 say: "This item hands R77 the
  requirement; if R77 declines it, the pause needs an owner."
- **Each item now says the other decides.** R77 says "R80 decides the split". R80 says R77
  must choose, or the pause needs a new owner. The pause's value, and therefore whether
  R80's readiness latch is reachable at all, is decided by neither item.
- **R77 builds on a withdrawn statement.** R77 still quotes R80's raw report as settled
  context, although R80's decision has corrected that sentence.

**Repair.** Revision 4 does one of two things:

- **Accept the requirement.** Name the pause variable under the prefix rule (for example
  `RSLBP_WEB_…`), state its default, and show that the pause plus the drain fit inside the
  8-second budget.
- **Decline it explicitly.** Ask the controller to assign an owner, and record that as an
  open coupling.

In either case, revision 4 stops quoting R80's raw sentence as if it were R80's position.
It instead cites R80 revision 3 at lines 314–318 and 750–752. The corresponding re-verify
clause, "when R80 publishes and fixes a readiness-propagation pause", becomes wrong
whichever option is taken, and must be rewritten.

### F4 — The start of the serve binary's `main` is unreconciled with R58 (non-blocking; JF-5)

**Failed claim.**

> "`src/bin/rslbp-serve.rs` calls `from_env()` once, before anything that can log or
> bind"

This sits together with AC7: "`grep -rn 'std::env::' crates/web/src/` matches exactly one
file, `settings.rs`".

**Evidence.** R58 revision 1 (`research/runs/R58/2026-09-18T215915Z-184041b91674/review/DECISION.md`,
migration table near line 1405) specifies the serve binary's "first statement of `main`:
`telemetry::init(Profile::Service { .. })` with level and format from
`RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT`". Both items claim the first statement.
If telemetry reads those variables itself, the environment has a second reader, which
contradicts "no handler reads the environment / one value, once". R58 is unaccepted and
R77 correctly leaves the log *values* to R58. The *order* and *source* of those two
variables, however, are this item's mechanism.

**Repair.** Revision 4 states the handshake: `WebSettings::from_env()` runs first and does
not log, and its `log_level` and `log_format` fields feed `telemetry::init`. Revision 4
also adds R58's publication as a check on that handshake in the re-verify line.

### F5 — Stale self-descriptions (non-blocking; JF-1)

**Failed claims and evidence.**

1. **A stale "this file" label.** The revision history reads "**Revision 2** (2026-09-18,
   this file) — the W2-REST conformance pass above", in a file whose title and first
   history entry say revision 3.
2. **R80 is described as published.** The decision says "R80 has since published its
   revision 3 carrying `OVERRIDE (OV-05)`". R80 is not published:
   `research/CLAUDE.md` lists R80 as `open`, and no `research/topics/80-*/DECISION.md`
   exists. Revision 3 has *landed* (ledger line 1080).
3. **A vacuous check is described as a working control.** The "What each script proves"
   bullet for `rest-conformance-r2.sh` still says that it asserts "that `OV-04` is unused
   elsewhere while `OV-01`, `OV-02` and `OV-03` are taken — the control that makes the
   next-free-number search mean something". The decision's own revision-3 note calls that
   check vacuous. The bullet itself does not.

**Repair.**

1. Change the revision-2 history label to "(2026-09-18, commit `d36492b`)".
2. Change "published" to "landed" for R80.
3. Qualify the `rest-conformance-r2.sh` bullet with "(this group-E check was vacuous; superseded by `ov-allocation-r3.sh` group B)".

### F6 — The `config` gate-2 figures are stale (non-blocking; JF-8 drift)

**Failed claim.** "`config` 0.15.25 … declares **1.85.0** — passes", together with the
re-verify clause "at the next `msrv-policy` floor advance past 1.96 (which neither
`config`'s 1.85.0 nor …)".

**Evidence.** A live query today of `GET https://crates.io/api/v1/crates/config/versions`
returns the newest non-yanked release as `0.15.26`, `created_at`
2026-09-21T13:08:27Z, `rust_version` `1.88.0`. The runner-up range
`>= 0.15.25, < 0.16.0` still covers 0.15.26, and 1.88.0 is still below the 1.96 floor,
so no disposition moves. However, the decision's "newest non-yanked" figures and its
landscape row no longer describe the current state, and the Muse report already cites
the new release (F1, point 6).

**Repair.** Revision 4 refreshes the `config` snapshot and its row, or explicitly records
the figures as dated 2026-09-18. It also updates the trigger text to 1.88.0.

## Judgment on the design itself

These notes are recorded so that the repair does not reopen settled ground. The
principle statement, the agreement-level table, the A1–A4 comparison, the edition-2024
injection-seam argument, the measured error-shape table and the W2-REST conformance
reading are sound. They are also well evidenced. The three `MOVED` and `OVERRIDE` rows
(R9.1, R8.10/R11.2 and R8.1 `OV-04`) are argued in the §1.9 shape and are tied to
checkable acceptance criteria. Once F1 and F3 are repaired, I expect the recommendation to
hold.
