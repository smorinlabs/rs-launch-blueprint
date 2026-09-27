actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 950f53664fe727d3fc7f2ce4790ad62ef2e1eb626a0b9fc97d9f5404c55eafae
verdict: reject
unresolved-findings:
1. JF-1 / JF-4 / JF-8 — `hyper-cors` is gate-cleared by the decision's own text yet left off the qualified shortlist, and the count "two" contradicts it (blocking)
2. JF-1 — re-verify trigger 14 counts "two" Fetch Standard sentences; the Empirical-check prose and the log count three (minor, mechanical)

# Judgment audit — R76 cors-middleware, revision 3

Target: `research/runs/R76/2026-09-17T034010Z-d958540e8834/review/DECISION.md`.
I recomputed its sha256 with `shasum -a 256` before reading anything else. It matched
the expected value `950f5366…eafae`.
Auditor: fable seat, a fresh context, model `claude-opus-5-5`. I did not produce this
item's raw reports, its evidence, or its synthesis. I read no `review/audit-*.md` file
and no `review/R76-r2-snapshot.md`.
Date: 2026-09-27.

What I read:

- The decision, all 1,304 lines.
- `inputs/prompt.md`, `inputs/prerequisites.json` and `inputs/parameters.json`.
- `research/RUNBOOK.md` §2, §4, §5 and §6.
- `raw/muse.md` in full.
- The five evidence logs. I spot-read the relevant sections of each and did not rerun
  the scripts.
- The prerequisite and sibling artifacts: R69's published `DECISION.md`, R69 revision 10
  at line 1791, and the R69, R02 and R05 rows of `docs/port/OWNER-ACCEPTANCES.md`.
- `docs/port/COMMONALITY.md:326`, `docs/port/README.md:71` and `BASELINE-REVIEW.md`.

Spot-checks I ran myself, all read-only and scratch-only in `/tmp/r76aud`:

- I downloaded the published `tower-http-0.7.1`, `axum-0.8.9` and `hyper-cors-0.2.0`
  `.crate` files from static.crates.io.
- I extracted the pinned REST API Design Standard blob `71bd813c…` from
  `/Users/stevemorin/c/rest-standards`.
- I fetched the `rustsec.org/packages/hyper-cors.html` status code.

## Controller-note observations (not findings)

- **(a) The Muse leg is unregistered.** `operations/muse.json` reads
  `state: "submitting"` with model `muse-spark`. `raw/muse.md` is untracked. This state
  is expected per the controller note. The decision discloses it honestly under
  `## Engines` and in the Uncertainty paragraph. I judged the adjudication prose only.
- **(b) Sibling pins.** Every sibling pin resolves now:
  - R69's published `topics/69-web-framework-stack/DECISION.md` hashes to
    `d4507f5b…`. That equals `inputs/prerequisites.json`, and `acceptance.json` hashes
    to `48a7dce8…`.
  - R69 revision 10 hashes to `d34ab6e8…`. That matches its OWNER-ACCEPTANCES row
    (revision 10, accepted, unpublished). Its `- owns web-extra-surface` line is at line
    1791 as cited.
  - R02 revision 2 and R05 revision 3 are the accepted revisions in OWNER-ACCEPTANCES,
    as the decision states.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **FAIL** | Findings 1 and 2. Everything else I cross-checked agrees, including the criteria count (seven everywhere, the JA-3 repair), the up-and-comer bin (17 names, matching "seventeen"), the 36 keyword crates plus 3 name-search crates all dispositioned, the tally over the four reference rows, and the gate-2 figures (1.85 ≤ 1.96) |
| JF-2 prompt questions and constraints | pass | See JF-2 below |
| JF-3 engine positions and adjudication | pass, with observations | See JF-3 below |
| JF-4 load-bearing claims trace to sources | **FAIL** (Finding 1). All other spot-checks pass | See JF-4 below |
| JF-5 couplings | pass | See JF-5 below |
| JF-6 `assumes` lines byte-identical | pass | See JF-6 below |
| JF-7 no conflict with prerequisites | pass | See JF-7 below |
| JF-8 evidence scripts and counts | **FAIL** (Finding 1: no log line). Everything else passes | See JF-8 below |
| JF-9 decision shape | pass | See JF-9 below |
| JF-10 recommendation follows from evidence | pass | See JF-10 below |

**JF-2 — prompt questions and constraints.**

- HIGH question 1 (crate, runtime allowlist) is answered: `AllowOrigin::list`, a runtime
  iterator, and criterion 6.
- HIGH question 2 (conditional branch vs wrapper) is answered by alternatives A and C.
- HIGH question 3 (principle and agreement level) is answered under Principles: the
  policy level, with no shared low-level value, and a ts/Hono rationale.
- The MEDIUM question is answered by the py-vs-tower-http table and by alternative B,
  measured.
- The LOW question is answered: affirmative for a framework (loco) and negative for
  templates.
- All six gates are present. Gate 1 carries the `inapplicable` string and the ruling.
- Figures carry their endpoints and dates, and `total_count` is used rather than
  `open_issues_count`.
- Stable Rust, edition 2024 and both OS runners are honoured.

**JF-3 — engine positions and adjudication.** Both raw reports are listed with their
sha256 values. I recomputed both, and both match: `31be2e15…` and `c2792a69…`. The
engine set `muse, opus` is stated with its authority. The ten Muse disagreements and the
eight Opus points are each settled with evidence, and I checked each against
`raw/muse.md` and `muse-adjudication.log`. Three observations follow; none is a finding.

- **Observation 1 — the issue-responsiveness window.** Muse's own text reports six
  non-PR issues in its window: `#741`, `#740`, `#737`, `#732`, `#731` and `#701`.
  Disagreement 4 reports "Muse's window gives 0 of 4". That figure is the 2026-09-27
  recomputation (`#741`, `#740`, `#737`, `#736`), and the decision labels it as a
  recomputation. The substantive position is represented faithfully: no maintainer reply
  in either set. One clause noting that the set shrank between 2026-09-25 and 2026-09-27
  would close the gap.
- **Observation 2 — the "optional-layer wrapper" label.** Muse's alternative (B) is
  labelled "optional-layer wrapper". By its own parenthetical ("always register a layer
  that internally no-ops"), it is this decision's alternative B, always-installed. Muse
  never evaluated the real wrapper (`option_layer`, this decision's C). The decision's
  claim that both reports compared "the same three core shapes" is defensible on that
  description. Disagreement 10 could say so explicitly.
- **Observation 3 — the Muse model name.** The Muse model ID (`muse-spark`, from
  `operations/muse.json`) is not named under `## Engines`. This falls under controller
  note (a).

**JF-4 — load-bearing claims.** Finding 1 is the one failure. Every other claim I
spot-checked matches its source:

- `tower-http-0.7.1/src/cors/mod.rs`:
  - `:715` is `if parts.method == Method::OPTIONS`.
  - `:729` is `headers.extend(self.layer.expose_headers.to_header(&parts))`, on the
    non-preflight branch. `:728` is its comment.
  - `:820` is `fn ensure_usable_cors_rules`.
- `tower-http-0.7.1/src/lib.rs:200` is `#![deny(unsafe_code)]`.
- `tower-http-0.7.1/Cargo.toml:117` is `cors = []`, and `:161` is `default = []`.
- `tower-http-0.7.1/src/services/fs/serve_dir/tests.rs:1246` is the Windows `unsafe`
  block.
- `axum-0.8.9/src/routing/method_routing.rs:1168`–`1174` and
  `axum-0.8.9/src/routing/route.rs:180`–`182` are the `Allow` stamping.
- REST standard blob (190,161 bytes, 3,427 lines): R1.6 at lines 229, 237 and 241; R1.7
  at 271 and 273–275; the §1.10 rows at 348 and 351; R4.10 at 846; R4.11 at 856; R4.17
  at 864–870; R5.11 at 1008; R8.1 at 1317; R8.2 at 1323; R8.10 at 1387; R8.11 at 1414;
  R11.7 at 1752; the Appendix A row at 2696; Appendix E at 2913–2915. All match their
  quotations.
- Owner reference: lines 36 (the axum-extra `option_layer` break), 79–80 (Level One),
  87, 114 and 141 (`"0.6"`) match.
- `COMMONALITY.md:326` is F322, `DIVERGENT`, R76. `README.md:71` is the `DIVERGENT`
  definition.
- OV-08 was allocated to R76 in the table at commit `69a635ec`.
- The X4, X7, X10 and X11 header sets in `rest-conformance-r2.log` match the decision's
  table.

**JF-5 — couplings.** Each sibling receives its owned choice without the decision
making it:

- R75 gets the layer order, the aggregate feature list, the contents of
  `expose_headers`, and the option-2 stamp if the owner refuses OV-08. R76 fixes only the
  measured constraints.
- R77 gets the variable name and the parse.
- R67's `RSLB203`/`2` mapping is consumed, with no new row requested.
- R69's paths are consumed, and its republication is a re-verify trigger.
- The R8.10 axis input is handed to the auth owner and is not decided here.

**JF-6 — `assumes` lines.** I checked each of the six `- assumes` values against
`docs/port/PARAMETERS.md` by substring match. `decision-self-check.log` section B shows
the byte-for-byte `diff` of all six rows, in order, reporting `ASSERT ok`. There is no
`- owns` line and no `CONFLICT:` line, which is consistent with the empty `owns` and
`consumes` fields in the prompt.

**JF-7 — no conflict with prerequisites.** Four consumed values were compared:

- axum 0.8.9 and tokio 1.53.1 match R69.
- `tower` stays a dev-dependency, as R69 fixed it.
- `RSLB203` maps to `2`, per R67's registry value.
- The four-package workspace matches R02 revision 2.

The decision uses R69 revision 10's paths while keeping the registry's revision-9
bytes. It states this explicitly, and it is not a `CONFLICT:` because no value has to
change.

**JF-8 — evidence scripts and counts.** Finding 1 is the one failure: its CI-matrix
claim has no log line. Everything else passes:

- All five scripts and their logs exist.
- The PASS counts are 56, 29, 27, 73 and 66, each with `FAIL=0` and `SKIP=0`. Each
  matches the decision.
- Both scripts that read the decision print its sha256 as `950f5366…`, so they ran
  against these final bytes.
- The keyword enumeration lists 36 names.
- The issue-window figures match: 2 answered, 0.05 h and 4.55 h, a median of 2.30 h,
  8 unanswered, 2 closed, and 1 opened by a maintainer.
- The actix-cors gate figures match: 1.88, 110 packages, `forbid(unsafe_code)` at
  `:53`, RustSec 404 with the `atty` control answering 200.

**JF-9 — decision shape.** The four H2s appear in order: `## Decision`,
`## Parameters`, `## Empirical check`, `## Engines`. There is no `## Supersedes`, which
is correct because this is not a reversal. `### Principles and implementation` sits
under `## Decision`. One `re-verify:` line closes `## Decision`. The prompt's answer
fields are all present in substance. This matches RUNBOOK §5.

**JF-10 — the recommendation follows from the evidence.** The crate, the version floor,
the conditional mechanism and the OV-08 recommendation each follow from measured
evidence:

- Alternative B is falsified by `Q2` and `Q3`.
- Alternative C is costed by measurement.
- The version floor is argued narrowly and honestly.
- The OV-08 Argument rests on quoted Fetch text, and its option 2 is measured.

Finding 1 does not move the recommendation. It affects the shortlist field only.

## Findings

### Finding 1 — `hyper-cors`: gate-cleared by the decision's own text, but neither shortlisted nor held to the shortlist's standard (blocking)

**Failed claims.**

- Under `Excluded by gate`: "**Excluded on integration fit, with gates 2–5 cleared:**
  **`hyper-cors` 0.2.0.** `rust-version = "1.80"`, inside the floor;
  `unsafe_code = "deny"`; a CI matrix of exactly `[ubuntu-latest, macos-latest]`."
- The shortlist lead: "**Two candidates passed every gate evaluated; one fits.** … The
  qualified shortlist is `tower-http` and `actix-cors`."
- The revision note says: "`actix-cors` is re-dispositioned as **gate-passing and
  fit-excluded**, which changes `Qualified shortlist`."

**Evidence.**

1. **The decision's own rule contradicts the result.** Revision 3's repair of JA-1 set a
   rule: a candidate that passes the gates but fails fit goes on the qualified shortlist.
   `actix-cors` is shortlisted on that ground. Gate 1 is inapplicable to every
   candidate, so "gates 2–5 cleared" puts `hyper-cors` in the same position as
   `actix-cors`. Yet `hyper-cors` is listed under exclusions and absent from the
   shortlist. By the document's own words, three candidates passed every gate evaluated,
   not two.
2. **`hyper-cors` was not held to the standard applied to the shortlisted crates.**
   - Gate 2: the decision says "The gate applies to the dependency tree". It resolved a
     locked tree for `tower-http` (57 packages) and for `actix-cors` (110 packages,
     maximum 1.88.0). For `hyper-cors`, the only evidence is the crate-level
     `rust_version = 1.80` (`registry-figures.log:81`–`82`).
   - Gate 3: no RustSec reading for `hyper-cors` appears in any log. I found that
     `rustsec.org/packages/hyper-cors.html` answers 404 today, but the decision does not
     record it.
   - Gate 5: the decision text states nothing for `hyper-cors`.
   - Gate 4: the claim "a CI matrix of exactly `[ubuntu-latest, macos-latest]`" has no
     log line. `grep -n -i hyper-cors review/evidence/*.log` returns only the
     enumeration row, the gate-2 `rust_version` line, and the dependency list.
3. **What does hold.** The `unsafe_code = "deny"` claim is true. I read it at
   `hyper-cors-0.2.0/Cargo.toml:108`–`109` in the published `.crate`, but no log carries
   it.

**Why this matters.** The qualified shortlist is a prompt field: "Up to five that passed
every gate (fewer is a finding)". The disposition rule is the exact thing JA-1's repair
changed, so the decision needs to apply it consistently. The recommendation does not
move.

**Repair.** Choose one of two options.

- **(a) Evaluate `hyper-cors` to the actix-cors standard, then shortlist it.** Run a
  locked-tree MSRV probe, a RustSec read with the `atty` control, and a CI read at
  source with a log line. State gate 5, and state gate 6 qualitatively. Then add
  `hyper-cors` as a third qualified-shortlist row carrying the prompt's figures, and
  change "Two candidates" to "Three".
- **(b) Recommended: reword the entry to what was actually measured.** For example:
  "gate 2 cleared at crate level only; gates 3–6 not evaluated to the shortlist standard,
  because integration fit excludes it first". Keep "two". Add one sentence explaining
  why `actix-cors` received a full gate pass and `hyper-cors` did not. Either remove the
  CI-matrix claim or back it with a log line.

### Finding 2 — trigger 14 counts two Fetch sentences where the log asserts three (minor, mechanical)

**Failed claim.** Re-verify trigger 14 reads: "the WHATWG Fetch Standard changes the
**two** sentences OV-08's Argument quotes — re-run `rest-conformance-r2.sh`, whose
section G asserts them".

**Evidence.**

- `## Empirical check` says: "(G) The **three** Fetch Standard sentences OV-08's
  Argument quotes".
- `rest-conformance-r2.log` section G asserts three `HEAD` sentences. The third is the
  "CORS filtered response" definition.
- The Argument's third step rests on that sentence: "the header-name list is consumed by
  the CORS filtered response built for that actual response". The step paraphrases the
  sentence rather than quoting it.
- As written, the trigger's condition does not cover a change to a load-bearing
  sentence. The re-run it prescribes would still catch that change. This is the same
  class of defect as JA-3 (a count stated two ways), and the severity is low.

**Repair.** Make trigger 14 read "the three sentences OV-08's Argument rests on, two
quoted and one paraphrased". Alternatively, reword the Empirical-check prose so that
both places use the same count and the same description.
