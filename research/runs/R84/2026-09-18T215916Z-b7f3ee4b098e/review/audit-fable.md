actor: audit-fable-r84r1-2026-09-25
model: claude-opus-5-5
family: anthropic
decision-sha256: 8c8620a217430589d92576edf4bcf217da37e2487ee86bbf9bd1099c6130c2ab
verdict: reject
unresolved-findings:
1. JF-3 / JF-1 — Disagreement 3 misrepresents Muse's position on progenitor.
   - Failed claim (`DECISION.md:613-614`): "**Disagreement 3 — progenitor as runner-up (all three Doxa legs) or excluded (Opus, Muse)? Settled: excluded.**"
   - Evidence: Muse's own `### Ranked runner-up` names progenitor
     (`raw/muse-caecee02….md:316-324`: "`progenitor` 0.15 — wins if and when Oxide ships OpenAPI 3.1
     support … On that event it is strictly stronger"). Its `### Excluded by gate` reads "None."
     (`:261-267`). The decision's own Muse bullet agrees with the raw report and contradicts line 613
     (`DECISION.md:566`: "Runner-up progenitor (if 3.1 lands), then OpenAPI Generator").
     Only Opus excluded progenitor.
   - Repair: restate the disagreement as "progenitor as runner-up (Muse, conditional on 3.1 support;
     all three Doxa legs) or excluded (Opus)". Adjudicate Muse's condition explicitly. Re-verify
     trigger 5 already carries that condition. The settlement itself (excluded, on `D01`–`D03` and
     `P02`) is sound and need not change.
2. JF-5 / JF-4 — The OV-11 Argument misstates what R5.12 guarantees a client that never asks for problem documents.
   - Failed claim (`DECISION.md:171-174`, option (a)): "It costs nothing at runtime against a server
     that honours R5.12's problem-document obligation. The only failure mode is a server that
     negotiates strictly and answers an error with `406`."
   - Evidence: R5.12 (`rest-api-standard.md:1019-1021` at blob `71bd813c`) obliges the server to
     return application errors as `application/problem+json` only "**when the client requests
     it**". Under OV-11 this client never requests it: `R12` and `D14` show it sends only
     `Accept: application/json`. A server that fully honours R5.12 may therefore answer this client's
     errors in another JSON shape. The generated client then keeps the status and raw bytes with
     `typed: None` (`R11`). That is a second failure mode: typed problem parsing is lost against a
     conforming server. It is not "nothing". Whether the template's own server emits problem
     documents regardless of `Accept` is R70's decision, and R70 is still open. The recommendation
     to accept the SHOULD departure (a) over the MUST departure (d) still follows. The recorded
     cost of that choice, however, is wrong.
   - Repair: rewrite option (a)'s cost to quote R5.12's "when the client requests it" condition.
     Name the degraded-parse failure mode. `R07` verifies only that the client parses a problem
     document into its typed form. It cannot show what the template's own server emits when
     `Accept` omits `application/problem+json`. That behaviour is R70's decision, so add R70 under
     `Couplings, stated rather than re-decided`. Otherwise, record the degradation as accepted.
3. JF-4 / JF-8 — A compile-time figure is attributed to a snapshot file that does not contain it.
   - Failed claim (`DECISION.md:347`, gate G6 cell): "clean `cargo check` 17–18 s in the committed
     `snapshots/openapi-to-rust-timings.txt` (22 s on an earlier run)".
   - Evidence: `review/evidence/snapshots/openapi-to-rust-timings.txt` reads "clean cargo check of
     generated client, stable: 16 s" and "…, 1.96.0: 16 s". Its build-and-run line reads 19 s.
     No line says 17 s, 18 s or 22 s. The figure is not load-bearing because G6 is qualitative.
     However, the decision cites a file for a number the file does not hold.
   - Repair: quote the snapshot's values (16 s stable, 16 s at 1.96.0). Alternatively, re-snapshot
     and cite the new file. Either way, drop the unsourced "22 s" or source it.

# Judgment audit — R84 openapi-typed-client-generation, DECISION.md revision 1

Auditor: `audit-fable-r84r1-2026-09-25`, a fresh Claude Opus context (`claude-opus-5-5`). It is
independent of the synthesizer and of all three raw reports. It did not read `review/audit-claude.md`.
Nothing was written except this file. Scratch files went to `/tmp`. Retrieval date for every
check below: **2026-09-25**.

**Hash.** `shasum -a 256 review/DECISION.md` →
`8c8620a217430589d92576edf4bcf217da37e2487ee86bbf9bd1099c6130c2ab`, which equals the expected value.

**Verdict: reject.** Three findings are unresolved. Finding 1 fails the engine-fidelity check
(JF-3) and the internal-consistency check (JF-1). Finding 2 is a misreading of the binding standard
inside the recorded override's cost analysis. Finding 3 is a transcription defect. **None of the
three changes the recommendation.** `openapi-to-rust` 0.17.0 behind `just client-rust`, with
uncommitted output outside the workspace, follows from the evidence. A revision 2 that repairs the
three passages should be approvable on this auditor's reading.

## The ten checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **Fail** (finding 1) | Line 613 says Muse excluded progenitor; line 566 says Muse's runner-up is progenitor. Otherwise consistent. Spot-checked: 33 versions from 2026-02-13 to 2026-09-14 matches "seven months"; trigger 8's "after 2027-03-14" is 0.17.0 + 6 months; the `re-verify: 2027-03-25` line lists the same eight triggers as the numbered list; the 1.96 floor equals stable 1.98.1 minus two minor versions, both in prose and in the recipe literal |
| JF-2 prompt questions and constraints | Pass | All six questions are answered in the table at `:140-147`, each with evidence. The crate is named with range `>= 0.17.0, < 0.18.0` and exact pin 0.17.0. All six fitness gates are applied per candidate, with licence marked `inapplicable` under Q7.B. Landscape uses three bins with authorities named. Architectures A–F are compared before tools. The shortlist of two is declared a finding. Runner-up conditions are stated. Stable-only is honoured; progenitor is excluded partly on `P03`, a stable-rustfmt panic. The Ubuntu half of the OS constraint is disclosed as unexecuted (AC9), not hidden |
| JF-3 engines represented and adjudicated | **Fail** (finding 1) | Spot-checked against the raw reports. Opus: OpenAPI Generator with `supportAsync=false`, uncommitted, root `exclude = ["clients"]` (`opus:417-445`, `:576`); the "`total_count: 0`" claim is at `:313`. Doxa-OpenAI: committed `crates/api-client` (`doxa:470`, `:530-533`); OpenAPI Generator excluded as "Not a Rust crate" (`:395`); `BASELINE-REVIEW: F335` (`:304`); "zero candidates are fully evidence-complete" (`:378`); `target/tools` install (`:444`). Perplexity: `owns` lines (`:1188-1196`); "npm-based CLI". Gemini: ">120" stars and "~16,000" downloads (`:1301+285-286`); gate-3 exclusion of OpenAPI Generator. The Muse errors table is right: "stable only" (`muse:463`) and `Justfile:321-323` (`:119`). Only the Disagreement-3 grouping is wrong. Opus's root-manifest `exclude` is replaced by an empty `[workspace]` in the client manifest; that change is justified by `T13` at coupling 3 and is not listed as a disagreement. It is a valid, evidenced alternative |
| JF-4 load-bearing claims traced | **Fail** (findings 2, 3) | All 127 check IDs cited in the decision exist in the four logs; zero are cited but missing. Registry figures match `snapshots/registry-figures.json`: 37 stars; 46,127 all-time and 45,469 90-day downloads; 0 reverse dependencies; 33 versions; issue median 0.485 days with 10 of 10 lacking a maintainer comment and 4 open from 2026-09-19; `meteora-api` 20 downloads; OpenAPI Generator 26,762 stars; `spargen` 0.5.0 on 2026-09-24; Rust 1.98.1 on 2026-09-03. The generator source was independently read at `~/.cargo/registry/src/…/openapi-to-rust-0.17.0/src/client_generator.rs`. The `accept` skip and forced `ACCEPT` are at `:1436-1447` (`D14`'s log says `:1436-1446`, which is immaterial). `HttpClient.http_client` is a private field and the only constructors are `new()` and `with_config(...)`, which confirms "offers no way to inject one" under R12.3. The R12.5 row cites a generated signature with no check ID; that is acceptable for a pass-through string |
| JF-5 REST dispositions and OV-11 | **Fail** (finding 2) | The standard was extracted at `0850d43e` and `git hash-object` gives `71bd813c1cf6…`, the blob the decision names. The cited lines are correct: R1.7 at `:272-273`; the §1.9 template at `:290`; R4.1 at `:742-747`; R4.2 at `:754-755`; §12 at `:1767-1823`; R12.6 at `:1815-1817`. Section 12 is dispositioned rule by rule; R12.8–R12.10 are correctly not reached. OV-11 is needed, because an unrecorded SHOULD departure is nonconformance under R1.7. It is recorded, and the number is the ledger's allocation (`execution-ledger.md:1114`: "OV-11 to R84"; `A14` census clean). The deviation line has all six template fields. Options (a)–(d) are genuine, and the need is verified at generator source. The one defect is option (a)'s cost statement; see finding 2 |
| JF-6 assumes lines and R69 revision 10 | Pass | All five `- assumes` lines are exactly equal to `inputs/parameters.json` and to the value cells of live `docs/port/PARAMETERS.md` (compared in Python). R69 revision 10 appears only in the prose note at `:465-471`; the `web-extra-surface` line carries revision 9's live value |
| JF-7 prerequisite values | Pass | `inputs/prerequisites.json` pins R69 decision `d4507f5b…` and acceptance `48a7dce8…`; both equal the current `research/topics/69-web-framework-stack/` files. R42's published `install-tool` recipe, `cargo binstall --locked --no-confirm`, bare-on-PATH invocation and `command -v` rule match `research/topics/42-*/DECISION.md:27-30` and `:249`. R49's "no build.rs" clause is `A08`. R02 and R05 are used only as accepted inputs (`A09`, `A10`). The client lives outside the workspace, so no accepted value is contradicted |
| JF-8 evidence scripts and counts | **Fail** (finding 3) | All five scripts exist. The log summary lines match the decision's table: 60/60/0/0, 36/31/0/5, 6/6/0/0, 31/30/0/1. The per-prefix ID counts sum to those totals; F01 has five sub-lines. The five `SKIP`s are exactly `R06`–`R10` (loopback bind refused) and `M01` (Maven unreachable), as disclosed. `r84-archive-rerun.log` shows three logs identical and one that differs only in `A13` PASS→SKIP, as described. Only the timings snapshot disagrees with the prose |
| JF-9 decision shape | Pass | RUNBOOK §5 is followed. `## Decision` carries the recommendation, version, settled F335, `### Principles and implementation` and a `re-verify:` line. The other sections are `## Parameters`, `## Empirical check` (toolchain, OS, commands, working directory, observed output) and `## Engines`. There is no `## Supersedes`, which is correct for a first revision. `scripts/check-answer-shape.sh` targets raw answers, not decisions, so it was not applied |
| JF-10 recommendation follows evidence | Pass | The pick is decided by gates the evidence settles: R12.4 is a MUST (`E04`, `E05` versus `R05`, `D11`, `D12`); R4.1's 3.1 requirement excludes progenitor (`D01`–`D03`, `P02`); R42's channel (`A06`, `A07`); edition 2024 (`E01`, `T09`). Adoption is stated as the main risk, not waved away, and engine agreement is explicitly disclaimed as a ground (`:587`). Architecture B is rejected on sourced py evidence (`B04`–`B06`) with a stated flip condition, trigger 6 |

## Notes that are not findings

- **Gate G4 for `openapi-to-rust`** reads "Pass on evidence, gap on the letter". Upstream CI covers
  Ubuntu (`G09`) and this host executed on macOS. The gap is disclosed and assigned to P03 (AC9). It
  is defensible as written.
- **"Only two surveyed tools can read the 3.1 document … and clear every applicable gate"**
  (`:357-358`) is loose. `spargen` also reads 3.1 but was not gate-assessed. The decision places it
  under up-and-comers on maturity and says so, so the sentence does not mislead the pick.
- **BASELINE-REVIEW handling** forwards the two Doxa F335 findings to the controller without adopting
  them. This matches RUNBOOK §4.
