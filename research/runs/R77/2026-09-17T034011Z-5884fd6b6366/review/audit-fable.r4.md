actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884
verdict: reject
unresolved-findings:
  1. JF-4/JF-5/JF-8 — claim: "R74's revision 1 … fixes three members (`research/runs/R74/2026-09-18T215916Z-14066395aaea/review/DECISION.md:410-414`) and hands this item 'Three fields …' (`:452`)". Evidence: that path now holds R74 revision 2 (sha256 `68e19cf3…`). Lines 410–414 there are a citation-drift paragraph. The members are at `:511-513`, OV-17 is at `:515` and the hand-off is at `:560`. The `r4-checks.sh` group C pin `84c01ec0…` no longer matches. Repair: re-pin to R74 revision 2 by sha256 and these lines, or to `R74-r1-snapshot.md` at `84c01ec0…`. Update "revision 1" in the field-count paragraph, Move 2 item 1, AC14 and the re-verify line, and update group C.
  2. JF-1/JF-8 — claim (lines 1290–1293): "`rest-conformance-r2.sh` **PASS=90 FAIL=1 SKIP=0** … Total **373 checks, 372 PASS, 1 expected FAIL** … Those are the committed logs' counts." Evidence: the committed `rest-conformance-r2.log` ends `PASS=91 FAIL=0 SKIP=0 TOTAL=91`, and line 1181 says 91/0/0. The 90/1/0 figure is the rerun inside `ov-allocation-r3.log`. Revision 4 added the sentence; revision 3 (`1e3cdb5`) did not have it. Repair: delete the sentence, or state committed 373/373 PASS with the 90/1/0 rerun attributed to `ov-allocation-r3.log`. `r4-checks.sh` does not assert this sentence, so the repair is text-only.

# R77 web-env-settings — judgment audit of revision 4

Auditor: fable (fresh Claude Opus context, `claude-opus-5-5`). I am independent of the
synthesizer and have no prior context on this item. Audited on 2026-09-27 (UTC).

**Target.** `review/DECISION.md`, revision 4. The expected sha256 was
`7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884`. `shasum -a 256`
recomputed the same value before anything else was read.

**Read.**
- the decision in full (1599 lines);
- `inputs/prompt.md`, which is byte-identical to the topic prompt (both sha256 `48610c1a…`, and line 24 reads `- engines: muse, opus`);
- `research/RUNBOOK.md` §4–§5 and lines 69–75;
- `raw/muse.md`, sha256 `a2e9a208…`, 204 lines, at the cited lines;
- the published prerequisite decisions R53, R57 and R67;
- the accepted-but-unpublished coupled decisions R54 rev 3, R56 rev 2, R69 rev 10 and R02 rev 2, whose acceptance rows are in `docs/port/OWNER-ACCEPTANCES.md`;
- the live coupled working copies of R74, R80 and R58, plus R80 rev 3 at commit `53b13f45`;
- `docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md`, `docs/planning/p02/owner-decisions.md` and `docs/planning/p02/execution-ledger.md`;
- the totals lines of every evidence log.

**Not read, as forbidden:** any `review/audit-*.md` of any seat or revision, and any
`review/Rxx-r*-snapshot.md`. For `R74-r1-snapshot.md` I checked existence by `ls` only.

**Summary.** The reasoning is sound, and the recommendation follows from the evidence.
Revision 4 closes the substantive problems that revision 3 carried:
- the Muse report is adjudicated line by line, and each citation I spot-checked is faithful;
- the readiness-pause ownership loop is closed;
- the R58 handshake is stated.

Two defects remain, both mechanical and both low severity. They do not move the
recommendation. Because each is a false or unresolvable statement in the audited bytes,
I record them as unresolved findings and return `reject`. Each repair is a text edit.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (finding 2) | Otherwise consistent. The field count, "about fifteen", the trigger at thirty, the 8 s budget and the pause rule, the R58 order, AC14–AC16 and the re-verify line all agree with each other and with `## Parameters`. The one contradiction is between line 1181 and lines 1290–1293 (finding 2). |
| JF-2 prompt questions and constraints | pass | Every question is answered. **HIGH 1:** the landscape across three bins with the candidates. **HIGH 2:** a `const fn` prefix, proven by probe P1; the per-field literals of `confique` and `envconfig` are rejected, proven by probe P5. **HIGH 3:** the principle, the agreement level and the must-agree / may-vary table, with ts treated as forward-looking because of F303. **MEDIUM:** `State`/`FromRef`, `web::Data` and `AddData` are handled generically. **MEDIUM:** the measured error table for five mechanisms, mapped to R67 `RSLB203`. **LOW:** layering is covered through the landscape and the runner-up's "file tier" trigger. No framework is assumed beyond R69's accepted stack. No CONFLICT is raised and no BASELINE-REVIEW is raised, and both absences carry their reasons. The decision cites no owner prior art. Gate 1 is correctly marked `inapplicable` under Q7.B, and gate 2 is applied under the strict reading that `owner-decisions.md:460` withdrew back to. |
| JF-3 `## Engines` fidelity and adjudication | pass | Muse is represented accurately. I checked the citations `:45`, `:53`, `:65`, `:68`, `:71`, `:77`, `:81`, `:88`, `:89`, `:93`–`:97`, `:102`, `:112`, `:113`, `:118`–`:125`, `:129` and `:145`; each says what the decision attributes to it. Examples: `:88` does record "1/10 answered, 185 days"; `:71` does set `.separator("_")`; `:125` does give "`unsafe` blocks or an injection seam" and `--test-threads=1`. All ten disagreements are settled with evidence: probe P7 for the separator, R53's published text for the reuse premium, the owner withdrawal for gate 2, and R57's published `TOOL_NAME` for the prefix. **Observation, per controller note (a):** `operations/muse.json` reads `submitting / muse-spark`, and `raw/muse.md` is untracked. This is expected at pack time, and the decision states it as a gap. |
| JF-4 load-bearing claims trace | **fail** (finding 1) | The following resolve: R53 `:67-69` and `:81`; R57 `:254`; R54 rev 3 `:303`; `owner-decisions.md:460` and `:198`; RUNBOOK `:69-75`; ledger `:1173` and `:1215`; COMMONALITY `:328` and `:307`; R69 rev 10, whose sha `d34ab6e8…` equals its acceptance row, with `FromRef<AppState> for Arc<WebConfig>` present; R80 rev 3 `:313-318`, `:750-752` and `:1197-1201` at commit `53b13f45`; and R58 `:1405` at the pinned sha `d06a6961…`. The R74 citations do not resolve (finding 1). |
| JF-5 couplings hand over owned choices | pass, with finding 1 as a pointer defect only | Every value R74, R76, R73, R78, R79 and R58 own is marked "named only". R74's membership is explicitly R74's, and the old floor is withdrawn. The readiness pause is accepted as a hand-off that R80 offers explicitly. R80 rev 4, in the live working tree, still says "hands R77 the requirement; if R77 declines it, the pause needs an owner" (`:829-831`), so accepting it causes no conflict. The R58 order is framed as a request (AC16) and leaves R58's value sets, parse and initialisation with R58. R77 owns every service-knob name under R69's owned value, so the `ROOT_PATH` version-segment constraint sits within R77's name-and-parse authority. |
| JF-6 assumes lines byte-identical | pass | I extracted all six `- assumes` lines programmatically and compared them with the live `PARAMETERS.md` value column. All six are IDENTICAL, including `web-extra-surface` at 2638 characters and `error-taxonomy-exit-codes` at 4057. Published R69 is still revision 9 (commit `28909acb`), so the decision's "revision 9 bytes, revision 10 paths" paragraph is accurate. |
| JF-7 no conflict with accepted or published values | pass | The `serde >= 1.0.229, < 2.0.0` range matches R53. `TOOL_NAME = "rslbp"` matches R57. `RSLB203` → exit 2, the envelope and `thiserror`-in-the-library match R67. The axum 0.8.9 and tokio 1.53.1 stack and `crates/web` match R69 rev 10 and R02 rev 2. The token chain matches R56 rev 2. Rejecting the layering engine matches R54 rev 3. **Observation:** the sketch's `use crate::TOOL_NAME;` inside `crates/web` is illustrative. R02 rev 2 has `crates/web` depending on `core` only, and R57 places `TOOL_NAME` in "the library crate", so the constant is reachable. P03 should import or re-export it from core rather than redeclare it. This is not a finding. |
| JF-8 evidence scripts exist, and counts match | **fail** (findings 1 and 2) | All eleven scripts named in the `## Empirical check` table exist with their logs. The log totals match the stated counts: figures 121/0/0; sources 84/0/0; probes 34/0/0; rest-conformance-r2 91/0/0 as committed; ov-allocation-r3 43/0/0; its rerun 39/4/0; drift-r4 32/0/0; probes-r4 37/0/0, which includes P3r4.1–3 and P7.1–3; probes-rerun-r4 6/0/0, with 31/3/0 and 34/0/0 inside; ov-allocation-r4 10/0/0; r4-checks 186/0/0. The Figment zero-commits check is in `drift-r4.log:33`. There are two exceptions. The counts paragraph misstates one committed log (finding 2). `r4-checks.sh` group C pins R74 at `84c01ec0…`, while the live file is now `68e19cf3…`, so that group no longer holds (finding 1). |
| JF-9 decision shape | pass | There are exactly four H2s, `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, and no `## Supersedes`, which is correct because nothing reverses. `### Principles and implementation` sits inside `## Decision`. F324 is settled. There is a single `re-verify:` line. The version range is stated. The empirical check gives toolchain, OS, working directory, command and observed output. |
| JF-10 the recommendation follows | pass | Every thin env-only mapper fails gate 2. The two survivors are layering engines, and the owner-accepted R54 rejected a layering engine. Edition 2024 makes an injected-source signature necessary, and P3 run 2 shows figment and confique ignoring an injected map. R67's `hint` favours the domain-level message. The runner-up `config` and its two win conditions are coherent, and P7 validates the no-separator snippet. |

## Unresolved findings

### 1. The R74 citations point at text that is no longer there (JF-4, JF-5, JF-8), low severity, re-pin repair

**Failed claims.** These appear at lines 768–770 and 945–947, in AC14, and in the re-verify line:
- "R74's revision 1, in the working tree and not yet accepted, fixes three members (`research/runs/R74/2026-09-18T215916Z-14066395aaea/review/DECISION.md:410-414`) and hands this item 'Three fields for the `RSLBP_WEB_RATE_LIMIT_*` family' (`:452`)"
- "R74 revision 1 fixes three members and argues why at its lines 410–415"
- "R74's working-tree revision 1 names three"

**Evidence.**
- The cited path now holds R74 **revision 2**. Its H1 reads "`# 2026-09-27 — R74 — rate-limiting-middleware (bundle, Deep) — decision (revision 2)`", and its sha256 is `68e19cf3d99567dc…`. Its mtime is 00:19, after R77's DECISION.md at 00:08.
- Lines 410–414 of that file are now a paragraph about citation drift.
- In revision 2, the three members sit at `:511-513`, the OV-17 reason at `:515`, and the "Three fields" hand-off at `:560`.
- `r4-checks.sh` group C pins R74 at `84c01ec019f9…`, which is the sha that R74 revision 2's own header records for revision 1. That pin no longer matches.
- Revision 1 was untracked, so git cannot recover it. The only surviving copy is R74's own `review/R74-r1-snapshot.md`.
- The substance still holds. Revision 2 keeps the same three members with the same names (`RSLBP_WEB_RATE_LIMIT_PER_IP`, `_PER_IP_BURST` and `_MAX_ENTRIES`) and cites R77 revision 4 in return.
- By contrast, the R80 rev 3 pins resolve, because they bind commit `53b13f45`. The R58 pin also resolves, because R58's file is unchanged at `d06a6961…`.

**Repair.** Re-pin to R74 revision 2:
- give its sha256 `68e19cf3…` and its lines `:511-513` (members), `:515` (OV-17) and `:560` (the hand-off);
- change "revision 1" to "revision 2" in the field-count paragraph, in Move 2 item 1, in AC14 and in the re-verify line;
- update `r4-checks.sh` group C to match.

Alternatively, cite the rev-1 text through `R74-r1-snapshot.md` by its sha256 `84c01ec0…`. No recommendation, value or AC semantics change.

### 2. The counts paragraph misstates a committed log (JF-1, JF-8), low severity

**Failed claim.** Lines 1290–1293: "Revision 2, carried: `rest-conformance-r2.sh` **PASS=90 FAIL=1 SKIP=0** … Total **373 checks, 372 PASS, 1 expected FAIL, 0 SKIP**. Those are the committed logs' counts."

**Evidence.**
- The committed `review/evidence/rest-conformance-r2.log`, last changed in commit `d36492b6`, ends `PASS=91 FAIL=0 SKIP=0 TOTAL=91`.
- The decision's own table at line 1181 describes that log as "(the revision-2 run, 91/0/0)".
- The 90/1/0 figure is the *rerun* recorded inside `ov-allocation-r3.log`: "now 90/1/0 against a revision-3 title".
- Revision 3's version of this paragraph (commit `1e3cdb5`, lines 1092–1097) did not contain the final sentence. Revision 4 added it, and it is false for one of the five logs it covers.
- As a result, the 373/372/1 total mixes committed counts with one rerun count.

**Repair.** Do one of the following:
- delete "Those are the committed logs' counts"; or
- state that the committed logs total 373 checks with 373 PASS, and that `rest-conformance-r2.sh` rerun against a later title gives 90/1/0 as recorded in `ov-allocation-r3.log`. A grep found no assertion of this sentence in `r4-checks.sh`, so the repair is text-only.

## Observations (not findings)

- **The Muse leg is unregistered.** `operations/muse.json` shows `submitting` and `raw/muse.md` is untracked. This is expected per controller note (a), and the decision records it plainly as a gap.
- **R80 rev 4 does not acknowledge R77's acceptance yet.** It still says "R77's in-flight report … names no pause" (`:829-831`, `:1456-1458`). That staleness is R80's to repair, not R77's. R77's re-verify line already fires when R80 lands a revision.
- **`crates/web` needs to reach `TOOL_NAME`.** Under R02 rev 2, `crates/web` depends only on `core`. P03 must therefore place R57's constant in `core`, or re-export it from `core`. That keeps the single-constant principle; see JF-7.
- **The re-pin will break a pin in the other direction.** R74 revision 2 pins R77
  revision 4 by sha256 `7e0cc569…` at `R74 DECISION.md:501`. Repairing finding 1 produces
  an R77 revision 5 with a new sha, and that breaks R74's pin in turn. Sequencing the two
  re-pins is the controller's decision, and it does not change this verdict.
- **The shutdown budget and the pause default are judgement calls.** The 8 s budget and the 0 s pause default are openly labelled as judgements with a stated alternative. I accept them as reasoned, not as measured.
