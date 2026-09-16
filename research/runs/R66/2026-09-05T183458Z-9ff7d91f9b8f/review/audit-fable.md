# R66 — output-format-surface — JUDGMENT AUDIT (round 1)

decision-sha256: a7958d3f38dfcdfe16e754b3e9e7a318bbb3a833fe86ebd663d28ef0696940ad
actor: audit-fable-2026-09-05T183458Z-9ff7d91f9b8f-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

Scope of this audit: `inputs/prompt.md`; all three raws (`raw/codex.md`,
`raw/opus.md`, `raw/doxa-openai.normalized.md`); `review/DECISION.md` at the bound
hash; `review/audit-codex.md` and both evidence logs; `docs/port/PARAMETERS.md`,
`BASELINE-REVIEW.md`, `COMMONALITY.md`, `DIVERGENCE-ANALYSIS.md`;
`research/RUNBOOK.md` §4–§5; and independent reads of the CLI Design Standard
v1.4.14 and of both source repositories at their pins. Settled owner items
(2026-09-12 Q7.B, 2026-09-14 standard/R60(b)/W0-R67, 2026-09-15 W0-R66 single
paid provider) are treated as settled and are not findings.

## Principle and agreement level

The stated principle — *one result value, rendered through one format-selection
surface, where format and destination are independent, explicitly selected, and
never inferred from the environment* — is the right abstraction for this item.
It is not "offer three formats", which is the artifact both sources happened to
produce; it is the invariant that makes the artifact correct. The four-row
agreement table separates the levels properly: **policy** (verbatim flag names)
is claimed only because the owner's 2026-09-14 ruling makes the org standard
binding and the standard's own text is `MUST` at those spellings; **capability**
(a human format, a stable machine format, the `--json` alias, a separate
destination) is the level F292 actually fixes; the **architectural pattern**
(one renderer over one columns/rows contract) is verified present in *both*
sources rather than asserted; and **stream policy** and **no TTY-driven format
switching** are cited to R7.1 and R7.3. What may vary — rendering libraries, the
human table's glyphs, which optional machine formats exist, the atomic-replace
mechanism — is correctly confined to implementation. The decision does not
inflate agreement above the level the evidence supports, which is the failure
mode this programme exists to prevent.

**The stale-port inversion — checked independently, at the pins, not carried.**
This is the item's centre of gravity, it inverts a recorded `DIVERGENT`
disposition, and I re-derived it from the source repositories rather than from
the decision or its evidence script:

- py at the pin (`b08bccfb`) is exactly as described: `OutputMode` is
  `text|json|markdown` with no `CSV`; `-o`/`--output` selects the format with
  `envvar="PLBP_OUTPUT"`; `--json` is documented "Shorthand for --output json."
  and resolves by silent precedence
  (`mode = OutputMode.JSON if json_mode else OutputMode(output_mode or "text")`);
  `--output-file` is the destination; there is **no** `--format` flag anywhere
  in `cli/options.py`; `_render_to_file` truncates non-atomically; `_render_text`
  consumes `table_rows_rich()` while `_to_markdown` consumes the plain
  `table_rows()` and escapes exactly one character
  (`cell.replace("|", "\\|")`).
- py's design 0001 Appendix D item 2 and ADR 0003 are quoted verbatim and in
  context. ADR 0003 is `Status: Accepted`, `Date: 2026-06-09`, and its rejected
  alternative is literally "**Strict spec compliance (drop markdown)** —
  rejected".
- The legacy py CLI at `f587e48^` declares `"--format"` with
  `click.Choice(["text", "json", "csv"])` (`projects.py:324-325`) and
  `@click.option("--output", type=click.Path(), …)` (`:330`) — ts's surface
  exactly, with no `--output-file` and no markdown.
- ts at the pin (`cb1cbcb2`) names its source in its first line —
  `// Pure output formatter — port of format_output (projects.py:273-291).` —
  documents `text` as "newline-joined project IDs (not names — shell
  composability)", and returns `projects.map((project) => project.id).join('\n')`.
- **The timeline strengthens the decision's claim rather than merely allowing
  it.** py's design 0001 landed 2026-06-09 (`e09dc2b`, PR #377) and the legacy
  CLI was deleted the same day (`f587e48`, PR #388); ts's repository begins
  2026-07-06 and `src/lib/format.ts` first appears 2026-07-09 (`6af76fe`). ts
  therefore ported `format_output (projects.py:273-291)` from a file that py had
  already removed a month earlier, under a rename py's own spec had already
  directed. "py's design spec directed the rename before ts was written" is
  correct.
- D-033 reads exactly as the decision says: the heading is
  "Interactive-prompt interrupt → exit 130; machine-mode error envelope", all
  three `Options:` are prompt-cancellation options, and the flag sentence
  appears only in the trailing `Why` line.
- I also read the record D-033 and `projects.ts:78-81` both point at, which the
  decision's evidence script asserts only the *existence* of: `EXAMPLECLI.md` at
  the ts pin carries a four-line block — "the standard's `-o/--output
  <table|json|...>` format enum is deliberately NOT adopted — `--output` remains
  the **file sink** for parity with the Python source". Its sole stated ground
  is source parity with the superseded file. It weighs no options and offers no
  rationale beyond parity, so it records the divergence without adjudicating it.
  The decision's reading survives the strongest document available against it.

Classifying this as "of the F265 class" is apt and not invented: F265 is already
recorded as "ts ported an older, pre-refactor flat py CLI shape … a stale-port
gap" (`DIVERGENCE-ANALYSIS.md:197`).

**BASELINE-REVIEW form.** Both lines follow `RUNBOOK.md:22`
(`F### — principle — proposed change — evidence`), quote the recorded target and
the recorded reason verbatim from `DIVERGENCE-ANALYSIS.md:206` and `:207`, name
affected items and affected records (`COMMONALITY.md:295,297`;
`DIVERGENCE-ANALYSIS.md:205,207`), and change no other item's record directly.
No `CONFLICT:` line is possible — R66's prompt `- owns:` and `- consumes:` are
both empty and `PARAMETERS.md` carries no output-format row — and R60's own
decision independently records that R66 owns no registry parameter.

## Design and evidence

**Architecture before libraries.** ALT-1 (serde-`Serializer`-per-format), ALT-2
(let the table crate emit Markdown) and ALT-3 (an exporter seam) are genuinely
compared, and each rejection turns on verified fact rather than taste: ALT-1 on
py's own three-way split between markup rows, plain rows and the wire DTO, which
I confirmed at the pin; ALT-2 on a counted absence inside the published
`tabled 0.22.0` tarball, guarded by a positive control (`A4a`) proving the tree
is the right one, plus the same absence in `hyperfine`'s exporter. A counted
absence with a positive control is the correct shape for a negative claim.

**`name` is justified from a principle, not added for symmetry.** ts's `text` is
bare identifiers; py's `text` is an aligned table; keeping only one silently
breaks one source's consumers. `name` is the standard's own spelling for that
format (R4.2), so the capability is preserved at zero conformance cost and one
`writeln!` of code. The decision flags it as going beyond every raw — Opus found
the underlying fact and deliberately left `name` out of its recommendation,
offering it as an owner option; neither Codex nor Doxa mentions it. That is the
honest attribution.

**Dropping `csv` to runner-up is argued, not assumed.** The grounds are
provenance (ts's `csv` is the legacy py CLI's `csv`, the same stale-port
mechanism the item rejects one row over), job coverage (`json` and `name` serve
the machine jobs; no recorded spreadsheet requirement), and contract cost (a
flat-schema commitment plus a formula-injection policy). Opus's dissent — that
this deletes a shipped ts capability — is stated at full strength rather than
paraphrased away, and the reversal is pre-paid: the trigger, the crate
(`csv 1.4.0`) and all six gates are recorded, so reversing needs no new research.
The ledger already frames F291 as an owner call, so making the call and
recording the dissent is the correct disposition.

**`markdown` hand-rolled for a stated reason.** Both maintained reference
renderers fail the escaping property this format needs, and the property is
correctness rather than presentation; width measurement — the one genuinely hard
part of the aligned table — is not needed for GFM. Being explicitly *stricter*
than the reference implementation, and saying so, is the right call.

**`tabled` against two of three raws.** The discriminator is in-scope and real:
neither Codex ("a bounded internal table function") nor Doxa (internal renderers
over `std::io::Write`) mentions a table crate at all — I confirmed zero mentions
of `tabled` or `comfy-table` in either raw — and neither addresses Unicode
display width, which is silently wrong on every CJK or emoji row if hand-rolled.
py does not hand-roll it either. The decision also declines the popularity
verdict and says so: `comfy-table` leads on downloads, open issues and semver
meaning. The gate-2 tie-break rests on each maintainer's own README sentence,
asserted verbatim (`A6a`, `A6b`, `A6f`). The `=0.22.0` pin is the maintainer's
own direction and is the right response to a stated breaking-minor policy; the
risk it does not remove — that the flagship adopter pins `0.21` and that nothing
states `0.22.0`'s floor — is recorded as `U4` and `U3` rather than hidden. I
verified one configuration claim the scripts do not assert: `tabled 0.22.0`'s
feature map is `default = [derive, macros, assert]` and `ansi = [… , "std"]`, so
`default-features = false, features = ["ansi"]` leaves exactly `ansi` and `std`
enabled — the gate-5 statement is precisely correct.

**`--output-file` against the binding standard.** R3.9 is quoted correctly and
the design matches it clause for clause: atomic temp+rename is the `SHOULD`,
silent overwrite is the explicit `MAY` ("Unix `>` convention"), and
`--no-clobber` is the offered refusal. R8.1's destructive-confirmation `MUST`
does not override it — R3.9 speaks to this exact flag and explicitly permits the
silent overwrite. Render-then-persist makes the "a failed render leaves the old
file intact" property true by construction, and it closes a verified capability
gap present in both sources rather than importing an ecosystem preference.

**`--json` versus `-o json`.** R4.2's "behave identically" is read as
byte-identical emission, which is what the standard's own ❌ example polices ("a
`--json` that emits a *different* shape than `-o json`"). The explicit-both
usage error is stricter than the standard requires and is not forbidden by it;
the `--paginate`/`--no-paginate` precedent is real at `:553`; ts ships exactly
this behavior and documents it ("`--json` and an explicit `--format` together
are a usage error (exit 2)"). Testing *explicit presence* rather than the
resolved value is what keeps the rule independent of R60's framework, and `AC4`
pins that distinction. Consistent with R67: exit `2`, `RSLB201`.

**Omitting `jsonl`, `yaml` and `wide` is conformant**, and on a firmer basis
than the decision states: the standard's own Appendix C conformance checklist
asks that "result-output commands support `-o`/`--output` and `--json`", not that
every enum member be implemented, and R4.2 calls the enum extensible.

**Empirical check.** 89 offline source checks and 108 live figure checks, all
asserting content (an exact line, an exact fixed string, a counted absence, or an
expected HTTP status) rather than an exit code. Failure capability is
demonstrated three ways, including two genuine authoring failures corrected
against the endpoint. `INDET` is a separate counter that never contributes to
`PASS`, prints its own lines, and forces exit `2`; the committed run is
`INDETERMINATE: 0`, and the rate-limit path was executed rather than described.
The split between *asserted* stable fields and *recorded* moving counters is the
right discipline, and the snapshot figures I sampled match the decision's text
(`tabled` 8,766,630 vs `comfy-table` 18,104,035; `serde` 306,342,347). `A1n-*`
pins each recommended version as the newest un-yanked one, so the version
recommendations are verified to the extent anything can be without a template to
build.

**Nothing is claimed beyond the evidence.** The decision states plainly that no
Rust code exists, that `AC1`–`AC16` have never been run, that no benchmark was
run and no performance figure is asserted, that the four members compose in no
known single repository, and that a `serde`/`serde_json` macOS pass is judged
rather than demonstrated. Declining to implement its own recommendation is
correct for this programme, not a gap.

## Completeness

- **Required H2s** present and in order: `## Decision` (with settled `F###`
  rows, `### Principles and implementation`, and a `re-verify:` line),
  `## Parameters`, `## Empirical check`, `## Engines`. `## Supersedes` is
  correctly absent for a first revision and its absence is explained.
- **Parameters.** The four `assumes` lines are byte-identical to the `value`
  cells in `docs/port/PARAMETERS.md` for `msrv-policy`, `rust-edition`,
  `target-os-matrix` and `license`. R66 owns nothing and consumes nothing
  (`C11a`, `C11b`), so no `owns:` line is expected and no `CONFLICT:` line is
  possible; the decision says so and R60's decision agrees. The two coordination
  notes (workspace-level `serde`; `tempfile` shared with R52/R59) are correctly
  raised as observations rather than registrations.
- **Couplings.** R60's three compatibility requirements are quoted accurately
  against R60's published decision, and all three are met; the one R66 outcome
  that would reopen F267 did not occur. R67's two assignments — render `hint` as
  a distinct field or line, and own the locked-handle writer its broken-pipe rule
  assumes — are both discharged, and the human/machine split for the envelope is
  derived from R7.8 rather than invented. No `CONFLICT:` is warranted.
- **Gates and dates.** All six fitness gates are answered for every member,
  including the crate-free `markdown`/`name` member and the deferred `csv`, with
  gate 1 recorded as `inapplicable` under the 2026-09-12 (Q7.B) ruling and each
  licence recorded as a fact carrying no verdict. `unsafe` counts are read from
  each crate's own published source with positive and negative controls rather
  than carried from a raw. Every member's `Sources` block carries a retrieval
  date; carried raw figures carry the raw's date; the snapshot carries
  `retrieved_utc`.
- **Unproven.** `U1`–`U8` each name a specific proof path and a phase. `U8`
  (issue-responsiveness medians) is recorded as a gap with the reason it does not
  affect any gate or selection, which is the honest handling rather than a quiet
  omission.
- **The prompt's approved questions are all answered.** HIGH third format →
  `markdown` kept on py's ADR, `csv` deferred with trigger and crate, plus
  `name`; HIGH flag naming → py's split, which is the standard's mandated split;
  HIGH principles/agreement levels → the agreement table plus the "what may vary"
  paragraph; MEDIUM `--json` alias and mutual exclusion → alias plus
  presence-based conflict, declarable in R60's `GlobalArgs`; MEDIUM crate need and
  R85 plainness → crates only for JSON and the aligned table, and resolution rule
  6 plus the plain-rows contract keep `markdown`/`name` free of terminal bytes
  (the sub-question "can markdown carry equivalent non-terminal formatting such
  as Markdown links" is answered only implicitly — the plain-row contract
  forecloses it — and would read better stated outright);
  LOW existing-file behavior → silent atomic overwrite, no append, `--no-clobber`.
- **audit-codex rerun** is consistent: same bound hash, both scripts re-run from
  a clean `git archive HEAD` extraction with `0` failures and `0` indeterminate,
  normalized diffs clean, `approve`, no unresolved findings, and it records the
  one audit-only normalization mistake rather than suppressing it.
- **Engines.** All three reports are identified with model, collection date and
  content hash; the missing Perplexity and Gemini jobs are recorded with the
  owner's 2026-09-15 acceptance and the preserved failure checkpoint, and the
  decision states the consequence plainly (one paid model's answer, not a
  three-provider consensus). Seven disagreements are each settled with named
  evidence, and I verified the characterization of each raw against the raw
  itself: Codex (`table|json|markdown`, no CSV, no table crate), Opus (all four
  formats, `text` default, `tabled` pinned), Doxa (`--format` selector, `-o` as
  file sink, no `--output-file`, `std::fs::write`).

## Findings

**No unresolved findings.** The five items below are recorded observations that
do not block acceptance; each is a precision or presentation improvement for a
future revision, and none changes a conclusion, a gate result or a parameter.

1. **Line citations drift by one or two lines in five places, and the
   heading-line and body-line conventions are mixed.** Every rule ID is correct
   and every quoted sentence is verbatim in the pinned blob (and content-asserted
   by `C9a`–`C9n`, which deliberately grep strings rather than line numbers), so
   nothing rests on the numbers — but a reader who follows them lands beside the
   sentence: R4.1's result-output row is `:248`, not `:246` (`:246` is the
   `--config` row); R7.3's "TTY state **MUST NOT** change the selected output
   *format*" is `:390`, not `:391` (the ✅ example); R7.7's flush `MUST` is
   `:427`, not `:429` (the ❌ example); R7.2's `-o table` sentence is `:386`, its
   heading `:385`; R7.8's envelope `MUST` is `:432`, its heading `:431`. R60
   cites rule headings (`R4.1 :237`, `R4.6 :275`); R66 mixes the two conventions.
2. **The F293 `BASELINE-REVIEW:` line does not surface the strongest document
   against it.** ts states the divergence deliberately in two places —
   `projects.ts:78-81` and `EXAMPLECLI.md`'s "deliberately NOT adopted" block.
   The decision asserts only that the source comment exists (`C7d`) and answers
   the point in `## Engines`, Disagreement 2. Having read both records myself I
   agree with the reading — their sole ground is parity with a file py had
   already deleted, and no options are weighed — but the controller adjudicates
   from the line, and the line would be stronger if it named `EXAMPLECLI.md` and
   `C7d` explicitly and said why "documented" is not "adjudicated".
3. **The `comfy-table` gate-2 exclusion leans on the point its own source rated
   weakest.** Opus, the only raw that surveyed table crates, called the MSRV
   posture "the weakest of the three points" and judged that "neither posture is
   satisfactory and both need the same compensating CI job", offering two further
   grounds the decision does not use (the default `tty` feature pulling
   `crossterm`; `pueue` as self-adoption). Relatedly, "Opus left
   `tabled`-versus-`comfy-table` to owner preference" understates Opus, which
   recommended `tabled` and listed `comfy-table` as a conditional runner-up. The
   selection is unaffected — the tie-break is still a primary-source statement,
   the exclusion is explicitly parameter-dependent, and the reversal condition is
   registered — but the record should carry that its source weighted the point
   lower.
4. **One `SHOULD` at the R60/R67 seam is neither honored nor waived.** R7.8's
   closing sentence — a usage error **SHOULD** use the machine-readable error
   contract when the parser can determine a machine format was requested — bears
   on `AC3`, where `--json -o json` makes the requested format determinable.
   `AC3` asserts exit `2`, `RSLB201` and a byte-empty stdout but does not say
   which error shape stderr carries. This is under-specification at a seam R67
   owns, not a waiver, and belongs on the P03 validation list.
5. **`--no-clobber`'s refusal names an exit code but not a catalog code.**
   Resolution rule 4 and `AC13` give exit `5`; R67's `RSLB501` is the
   corresponding row and naming it would complete the pairing, as `RSLB201` is
   named for the alias conflict.

## Assessment

**Approve.** The decision states the shared principle at the level the evidence
supports, keeps the policy claim inside the standard the owner made binding, and
preserves both sources' capabilities with a native Rust design rather than
importing either source's shape by default. Its centre of gravity — inverting a
recorded `DIVERGENT` disposition on the ground that ts's flag naming is
stale-port drift — is the part I pressed hardest, re-deriving it from the two
repositories at their pins rather than from the decision or its scripts, and it
holds on every document available, including the one record the evidence script
does not assert on. The library selection runs against popularity, against
repository agreement and against two of three raws, and in each case names the
principle and the primary source that carried it; where it is most contestable it
says so, names the runner-up, and states the parameter change that would reverse
it. The empirical check asserts content with controls, distinguishes asserted
figures from recorded ones, keeps `INDET` strictly separate from `PASS`, and
records a failed run rather than only a successful one. Required fields, gates,
parameter lines, couplings and source dates are complete and correct, and the
decision claims only what the evidence establishes, recording `U1`–`U8` and the
entire `AC1`–`AC16` suite as P03's to prove. The five observations above are
recorded for a future revision and, individually or together, do not withhold
acceptance.
