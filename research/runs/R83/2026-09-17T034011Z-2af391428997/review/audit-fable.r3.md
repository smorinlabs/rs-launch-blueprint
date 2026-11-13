# R83 — openapi-contract-fuzzing — judgment audit of decision revision 3

actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 9197c005a053eb476fe3ed4e7905700f243a3dd5f357082d7698de908ad5f331
verdict: reject
unresolved-findings: JF3-1-1 (Generation row omits query parameters while asserting query-parameter targets); JF3-1-2 (acceptance criterion 7 is unachievable under the 16-case boundary-invalid mode as written)

## Scope and method

This is a fresh judgment audit of `review/DECISION.md` revision 3. The file's sha256 was
recomputed with `shasum -a 256` before any other read; it equals the expected
`9197c005…d5f331`. The audit judges reasoning and fidelity, not execution. No script was
rerun. Per this seat's instructions, no `review/audit-*.md` file of any seat or revision and
no `review/R83-r*-snapshot.md` was opened. The decision's citation of
`review/audit-claude.r2.md:54`–`:61` for the 73-PASS total was therefore not read; the
counts were verified directly from the logs instead (JF-8).

Read: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §2 and §5 (roles, decision
shape, audit contract); `raw/opus.md`, `raw/muse.md`; the consumed prerequisite R69
(`research/topics/69-web-framework-stack/DECISION.md`) and the cited decisions of R11, R33,
R72, R70 (run tree, revision 4), R69 revision 10 (run tree) and R02 revision 2 (run tree);
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md`; the cited lines of
`docs/planning/p02/owner-decisions.md` and `execution-ledger.md`; py-launch-blueprint at
pin `b08bccfb` and its installed `schemathesis` 4.21.5; the probe fixture and the seven
evidence logs.

**The recommendation is not in question.** `oas3 = "0.22.0"` as a `crates/web`
`[dev-dependencies]` entry, the runner-up, P1 and P3–P5, the three oracles and every
`assumes` line all hold on the evidence. Both findings below sit in the text cluster that
revision 3 introduced — the Generation row, the Case count row and acceptance criterion 7.
Revision 4 needs a text repair, not new research.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | Two contradictions inside the design table and acceptance criteria; findings JF3-1-1 and JF3-1-2 below. Other candidates were examined and cleared: the probe's `limit` `"minimum": 0` versus R72's `1..=100` is explained at `DECISION.md:287`–`:289`; the revision note calling P2's "including its declared boundary values" superseded while the new P2 keeps "including the declared boundary values" for the valid mode reads as a widening, not a contradiction; the `tower` observation (`:265`–`:271`) is consistent with the `assumes` line |
| JF-2 questions answered, constraints honoured | pass | Decision question answered first (`:39`–`:52`); HIGH Q1 by A1–A5 and the landscape carried from `raw/opus.md`; HIGH Q2 in its own paragraph (`:151`–`:181`); HIGH Q3 by P1–P5 with levels and the ts structural-absence argument (`:85`–`:108`); MEDIUM checks (`:228`, P3), MEDIUM discovery (`:223`), LOW maturity (`:243`–`:244`, B23/B24). Out-of-scope items are handed to R71, R84, R69 and R32, not decided. Gate 1 recorded `inapplicable` with the Q7.B reason, as the prompt requires for an inapplicable metric |
| JF-3 `## Engines` fidelity and adjudication | pass | Muse citations spot-checked at `raw/muse.md:23`, `:25`, `:27`, `:35`, `:42`, `:43`, `:45`, `:47`, `:51`, `:58`, `:64`, `:65`, `:69`, `:73`, `:85`, `:86`, `:91`–`:93`, `:105`, `:109`, `:118`; each says what D1–D10 attribute to it. Opus citations `raw/opus.md:111` (P2 "including its boundary values"), `:363` (Generation row) and `:380` ("negative testing" with the runner-up) match D10. D10 adjudicates the new generation-scope disagreement on the prompt, py's library source and a stated inference. Muse bytes on disk hash to `dbd36128…c5df`, the adjudicated bytes; `manifest.json` still shows `operations.muse.state` `submitting`, exactly as `:633`–`:639` records |
| JF-4 load-bearing claims trace to sources | pass | The new ground 2 of HIGH Q2 was traced end to end: py `uv.lock:2257`–`:2258` at `b08bccfb` is `schemathesis` 4.21.5; the installed dist-info is `schemathesis-4.21.5`; `builder.py:103` is `st.one_of(... for mode in generation.modes)`; `_projects.py:396`–`:418` returns `self.generation` when no operation or phase config applies; `_generation.py:63` is `self.modes = modes or list(GenerationMode)`; `modes.py` defines `POSITIVE` and `NEGATIVE`; `tests/web/test_contract.py:21`–`:30` sets only `max_examples` and `checks`; the pin has no `schemathesis.toml` and `pyproject.toml` has no `[tool.schemathesis]`. Probe `contract_fuzz.rs:347`–`:355` is the valid-only `Union` the decision describes, and the file is 482 lines. REST-standard rule lines were covered through the log's `B11`–`B26` PASS lines, not by opening the pinned blob |
| JF-5 couplings hand over owned choices | pass | R32 keeps the exclusion mechanism and step-or-job placement (`:230`, `:336`–`:342`); R11 lines `:202`, `:278`, `:282`, `:320` quoted accurately; R72's exact `422` stays R72's (`:225`, `:351`); R71 keeps generator, version and serving path with conditional outcomes stated; R70's envelope quoted accurately at its run-tree `:131`–`:139` and `:407`–`:410` |
| JF-6 `assumes` lines byte-identical to live registry | pass | All five `- assumes` values equal the value cell of their row in `docs/port/PARAMETERS.md`, checked against both the working tree (which `git status` shows modified) and `HEAD`. The `web-extra-surface` bytes are R69 revision 9's, as `:411`–`:423` explains |
| JF-7 no conflict with accepted prerequisite values | pass | `research/topics/69-web-framework-stack/DECISION.md` sha256 `d4507f5b…10d` and `acceptance.json` `48a7dce8…338` equal `inputs/prerequisites.json`. R33 `:27` pins `proptest` 1.11.0; R72 (revision 5) `:154`–`:155` rejects `limit=0` and `limit=101` with `422`; R69 revision 10 `:1791` puts web tests in `crates/web/tests/` with no file-level `cfg`; R02 revision 2 `:128` carries check `B3` |
| JF-8 evidence scripts exist, counts match | pass | Logs end `PASS=24`, `PASS=29`, `PASS=8`, `PASS=12` with `FAIL=0 SKIP=0`, total 73; the pre-fix log ends `PASS=5 FAIL=7`; `r2-copy-rerun.log` shows 8/12/29; `clean-extraction.log` 24/29. All four scripts are present. `stat` shows every script and log last modified at or before 2026-09-27T00:43 local, against `DECISION.md` at 08:45, which supports "no script, log or fixture was edited" (`:488`–`:490`). Probe log shows `operations discovered: 2`, `20/20` versus `2/20`, and `16 cases, no finding` as cited |
| JF-9 decision shape | pass | H2s are `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, in order, with one non-empty `### Principles and implementation` and exactly one `re-verify:` line, matching `_validate_decision_text` in `scripts/research_validation.py` and the published R53 decision |
| JF-10 recommendation follows from evidence | pass | Gate failures of every A1 candidate, the measured `openapiv3` 3.1 parse failures (M2, M4) and missing `rust-version` (B27), the executed A2 probe and the in-process transport already resident through R69 support `oas3` 0.22.0 and the assembled harness. The two JF-1 defects concern how the new mode is specified, not whether the recommendation stands |

## Findings

1. **JF3-1-1 (JF-1; blocking) — the Generation row omits query parameters while asserting
   query-parameter targets.**
   - **Failed claim**, `DECISION.md:225`, Generation row: "Per operation, a
     `BoxedStrategy<serde_json::Value>` built from the operation's path-parameter schemas and
     its `application/json` request-body schema …". The same row then says: "For R72's
     published `limit` (`1..=100` …) the valid boundary targets are therefore `1` and `100`,
     and the boundary-invalid targets are `0` and `101`. The harness asserts only that those
     two produce no 5xx".
   - **Evidence.** `limit` is a query parameter. The decision itself says "R72's
     `cursor`/`limit` query parameters" (`:349`). It calls query generation "a P03
     requirement, not an optional extra" (`:280`), and P03 item (6) repeats that (`:740`).
     So the design table's Decision column specifies generation inputs that cannot produce
     the values the same row promises. The `crates/web/tests/contract_fuzz.rs` migration row
     (`:311`) and the `common/mod.rs` row (`:312`) do not mention query parameters either.
     The Opus report's own Generation row included them: "path/query parameter schemas"
     (`raw/opus.md:363`). A P03 implementer building from the design table would build path
     and body generation only, and R72's `limit` — revision 3's motivating example for the
     boundary-invalid mode — would go ungenerated.
   - **Repair.** Add `in: query` parameter schemas to the Generation row's inputs, and state
     whether header and cookie parameters are in or out. Carry the same wording into the
     `contract_fuzz.rs` and `common/mod.rs` migration rows. The coverage-boundary paragraph
     (`:273`–`:290`) can stay as it is, because it describes the probe.

2. **JF3-1-2 (JF-1; blocking) — acceptance criterion 7 is unachievable under the
   boundary-invalid mode's 16-case budget as written.**
   - **Failed claim**, `DECISION.md:124`–`:127`, criterion 7: "For each operation, the
     generator produced at least one valid case at each declared boundary and at least one
     boundary-invalid case just outside each declared bound". Also `:386`–`:388`: "every
     bounded number, string and array admits a value just outside its bound, so the harness
     generates one."
   - **Evidence.** The Case count row fixes 16 cases per operation per mode (`:227`). The
     boundary-invalid strategy "takes a valid case and violates exactly one declared
     constraint, drawn from a `Union`" over all arms (`:225`). So each operation gets 16
     violations in total, shared among every bound neighbour of every bounded field and every
     `enum`, type and `required` arm. An operation with more than 16 such targets cannot meet
     criterion 7 in one run. An operation with a handful of bounded fields will miss some bound
     neighbours on most seeds. The valid mode does not have this problem: each field's `Union`
     draws independently in every case, which is why check `A14`'s 20/20 holds. The
     boundary-invalid mode draws one arm per case across the whole operation. The Mapper row
     (`:226`) assigns "criterion 7's guarantee" to the default-tier `contract_mapper.rs` on
     inline schemas, but criterion 7's own text is "for each operation", which reads as the
     fuzz run against the served document. The residual-risk paragraph (`:299`–`:303`) then
     relies on criterion 7 as the guard for the boundary-invalid mode.
   - **Repair.** Choose one option and state it in criterion 7, the Generation row and the
     Case count row:
     - (a) Criterion 7 is a property of the mapper. It is verified by `contract_mapper.rs` over
       a stated draw budget on inline schemas, not by the 16-case run. The `:386`–`:388`
       sentence is then reworded to "the mapper can generate one".
     - (b) The boundary-invalid mode enumerates one case per declared constraint arm
       deterministically, before any random draws. The Case count row then states that this
       mode's count is the number of arms, not 16.

## Observations (not findings)

- The Generation row's "a value of a different JSON type" arm has no direct meaning for a
  path parameter, which is always a string on the wire. P03 will meet this. It does not
  contradict the decision.
- R72's `:154` states the cap and the `422` rejections but not the lower bound `1` in so
  many words. `1..=100` is the direct reading of "`limit=0` … rejected".
