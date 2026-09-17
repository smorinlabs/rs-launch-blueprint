decision-sha256: 4287ea4daa3b13c4efc6d6229052123bf3ea16e0ebfd4a3f964aa29015ab86d8
actor: audit-fable-2026-09-17T020714Z-4e96c68a620c-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

Judgment auditor for R52 (`toml-crate`, kind `bundle`, Focused tier, owns nothing),
revision 1, run `2026-09-17T020714Z-4e96c68a620c`. I produced none of this item's
artifacts. The hash above was taken before I read the decision and re-taken immediately
before writing this file; it was unchanged across the audit, so this report binds one
version.

Read in full: `inputs/prompt.md`; `inputs/prerequisites.json`; both raws (`raw/codex.md`,
sha256 `8918f7a9…1edd6`, and `raw/opus.md`, sha256 `88e0d54e…f54d`, each re-hashed here and
matching the decision's citation); `review/DECISION.md`; `review/evidence/r52-toml-crate.log`
and `review/evidence/r52-first-run.log`; `review/evidence/verify.sh`;
`docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md` rows F224/F225/F226/F227/F243;
`docs/port/BASELINE-REVIEW.md` rows F224/F227/F243 and the F243 disposition at `:150`,
`:260`, `:325`; `docs/port/OWNER-REVIEW.md:47`; `docs/planning/p02/owner-decisions.md:157`;
`research/RUNBOOK.md` §4–§5; `docs/superpowers/plans/p02-roles/synthesizer.md`; spec §2;
`scripts/research_validation.py`; `research/topics/67-error-and-exit-code-contract/DECISION.md`;
`research/topics/64-…/DECISION.md` for the gate-2 precedent; and the org CLI Design Standard
v1.4.14 extracted from blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` in
`/Users/stevemorin/c/cli-standards`.

**Scope statements the role obliges me to make.** I did not rerun `verify.sh`; reproducibility
is the empirical audit's lane. `review/audit-codex.md` did not exist when I began and landed
while I was working; I deliberately did not read the in-flight
`review/audit-codex-r1-transcript.txt`, and I read `review/audit-codex.md` only after my own
verdict was settled, so the two family judgments stayed independent. I wrote nothing under
`review/evidence/`. Settled owner items (2026-09-10 proposal-validated-in-P03, 2026-09-12
Q7.B, 2026-09-14 the standard binds the port) are treated as settled and are not findings.

## Principle and agreement level

**The requirement is stated at the level the evidence supports, and the level is argued
rather than assumed.** The shared principle is written as *capability and observable
behaviour* — "the tool's persistent configuration is a human-authored, human-editable text
document that the tool reads into a validated typed value and writes back after a
programmatic change, without the user losing what they wrote" — with the library count left
free. That is the only defensible level here, and the decision proves it from the sources
rather than asserting it: py already splits `tomllib` from `tomli_w` while ts uses one
`smol-toml`, so the two repositories agree on behaviour and disagree on library count. That
disagreement is exactly what `COMMONALITY.md:229` and `:230` record as `DIVERGENT` for F225
and F226 with `R52` as owner. Setting agreement at "library" would have made the ledger rows
incoherent; setting it at "capability and observable behaviour" makes them the question this
item answers.

**No `OVERRIDE (OV-nn)` is required and none is claimed, correctly.** An override sits on a
recorded shared pattern (spec §2). F225 and F226 are `DIVERGENT`, so there is no shared
pattern to depart from; F224, F227 and F243 are `COMMON → REUSE` and the decision consumes
all three unchanged rather than re-litigating them. Nor is this a `SUBSTITUTE`: no tool row
is being swapped under a retained pattern row.

**What must agree versus what may vary is separated concretely, not rhetorically.** P1–P4
are behaviours traced to a source line or to a standard clause, and AC1–AC6 are written
library-agnostically so a later revision can re-test them against a different crate. AC5 is
explicitly marked F243's and *not this item's to prove* — both in the criteria table and
again in the P03 validation table as V5 — which is the right handling of an inherited row.

**Owner direction is used for what it settles and no more.** Gate 1 is recorded as
`inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate, and I verified both
pointers the decision cites: `docs/port/OWNER-REVIEW.md:47` carries the heading verbatim, and
`docs/planning/p02/owner-decisions.md:157` carries `## 5. The licence gate's reach --
ANSWERED 2026-09-12 (Q7.B)`. The decision raises no licence finding and excludes nothing on
licence, including `basic-toml`, whose `MIT OR Apache-2.0` string it explicitly says
"excludes nothing and rescues nothing". That is the ruling applied exactly.

**The standard is read for what it binds and the silence is characterised honestly.** I
extracted the pinned blob myself and checked both quoted rules. R5.2 at `:303` reads "The
canonical config format **MUST** be **TOML**" verbatim. R5.8 at `:340` carries all three
quoted clauses, and the decision's reading of them is right on the point that matters: "back
up files before rewriting them" sits inside the schema-migration sentence, so the decision is
correct to say it is *not* a comment-preservation clause — it does not recruit the standard
for the conclusion it wants. The conclusion that the crate choice is not org-locked survives
independently: Appendix E is labelled "guidance, not a requirement", and its Rust paragraph
names `clap`, `figment`/`config` and `directories`/`etcetera` while naming no TOML crate.

## Design and evidence

**Architecture was compared before libraries, and the discriminator is named in advance.**
A1–A4 are four genuinely different shapes, AC3 is declared the discriminator, and A3 (py's
literal parse/write split) is rejected *on the merits* — "any crate that can write TOML can
also parse it" — rather than on availability. That is the spec §2 shape: py's two-crate count
is retained only after being re-motivated onto a different axis (operation, not direction),
and the decision says so rather than claiming the sources chose correctly.

**The mandate is applied to the engine conflict instead of being cited decoratively.** The
first and heaviest ground for A4 over A1 is that Codex's ground for A1 — "the source
precedent needs semantic preservation, not a user-authored-format preservation guarantee" —
is the argument the prompt's `## Context` forbids: source implementations "are evidence, not
predetermined winners". I checked the prompt itself; it also lists round-trip fidelity as a
HIGH question rather than a settled non-requirement. Treating "py loses comments too" as a
description of the baseline rather than a justification for reproducing it is the correct
reading, and it is the difference between the two engines' recommendations.

**The demonstrations were executed and the prose matches the log lines it cites.** I read
every cited line rather than the decision's summary of them. `r52-toml-crate.log:360`–`:361`
carry `P2_PLAIN_KEEPS_HEADER = false` and `P2_PLAIN_KEEPS_TRAILING = false` (A1's defect);
`:370`–`:371` carry `P6_NAIVE_KEEPS_TRAILING = false` with `P6_NAIVE_APPLIED = true` (the
decor trap); `:372`–`:375` carry `P7_DECOR_KEEPS_HEADER`, `_PERKEY`, `_TRAILING` and
`_APPLIED` all `true` (the recipe). The prose is careful in the one place it could have
overreached: the naive assignment is said to lose "the trailing comment on that key's line",
which is exactly what the probe shows, since `P6_NAIVE_KEEPS_HEADER` and `_PERKEY` are `true`
at `:368`–`:369`. The decision does not claim the naive edit destroys more than it does, and
AC3 still fails on the trailing comment alone. I also checked that the `toml_edit` rustdoc's
own example assigns into a *new* key, so the maintainers' documented idiom does not
contradict this finding — it simply never exercises the case the template's `config set` hits.

**Gate 3 is settled on a control, which is the methodologically correct resolution.** Codex
recorded gate 3 `unverified` from a bare HTTP 404; Opus recorded `pass` after validating what
a 404 means. The log carries both halves at `:5`–`:8`: `time` returns HTTP 200 and its page
lists `RUSTSEC-2020-0071`, while `toml`, `toml_edit` and `basic-toml` return 404, with an
independent OSV `{}` for both members. The decision's summary — "a 404 with no control proves
nothing, and a 404 with a control proves that no advisory page exists" — concedes Codex's
caution was right and explains why its conclusion was avoidable. Neither engine is flattened.

**The responsiveness recount is correct; I reproduced it independently rather than reading
it.** Codex asserted "unanswered count is 10/10" (`raw/codex.md:9`); Opus asserted 3 of 10
unanswered (`raw/opus.md:264`). I queried GitHub myself with `gh api`, without printing any
token. `repos/toml-rs/toml/issues?state=all&sort=created&direction=desc&per_page=100` with
pull requests filtered returns, as its ten most recently opened issues, exactly the ten both
raws named: 1214, 1213, 1210, 1206, 1188, 1181, 1175, 1172, 1162, 1158. Fetching each issue's
comments gives maintainer-association counts of 1, 0, 2, 2, 0, 4, 0, 1, 3, 2 — **7 issues
carry at least one `OWNER`/`MEMBER`/`COLLABORATOR` comment and 3 carry none**, and the
maintainer-association comment lines total **15, every one of them `epage` as `MEMBER`**. That
matches the committed log at `:196`–`:197` line for line and issue for issue. Codex's figure
is wrong, the decision's correction is right, and the decision is also right to leave Opus's
0.67-day median unverified, because counting responders is not measuring elapsed time. The
decision states that nothing in the recommendation turned on the figure and corrects it
anyway so a false "the maintainers never reply" is not carried into a future re-verification
— which is the right reason to spend the query.

**The invented parameter is caught and the response is structural.** `raw/codex.md:73` and
`:97` both declare ``owns `toml-codec-stack = …` ``. No such parameter exists: the prompt's
`## Couplings` carries an empty `- owns:` line (`inputs/prompt.md:20`), `research/CLAUDE.md`
records `—` for R52, and `docs/port/PARAMETERS.md` has no such row. The decision declares zero
`- owns` lines and records the two version pins and the feature selection as unregistered
values in prose instead, noting they move unchanged if a later item registers a pinning
parameter. I confirmed against `scripts/research_validation.py:747`–`:766` that this is what
the packaging validator requires; a declared `toml-codec-stack` would have failed publication.

**Feature selection is argued by name and the manifests back it.** I did not take the log's
word for this. I fetched the published `toml` 1.1.6+spec-1.1.0 `.crate` myself: its manifest
carries `preserve_order = [` / `"dep:indexmap",` / `"std",` at `:113`–`:116`, and its
`[dependencies.indexmap]` block carries `optional = true` at `:178`. I fetched `toml_edit`
0.25.15+spec-1.1.0 likewise: its `[dependencies.indexmap]` block at `:133`–`:135` carries
`version`, `features = ["std"]` and **no** `optional = true`, so `indexmap` is genuinely
non-optional there. Both halves of the decision's asymmetry are true as written.

**Gate 2's exclusion of `basic-toml` is a rule, not a judgment, and it is programme-consistent.**
`rust_version` is `null` for its newest unyanked version and the count of published versions
declaring one is `0` of `12` (log `:38` region). I checked the precedent the decision invokes:
`research/topics/64-…/DECISION.md:7` records that the controller's provisional lenient reading
was **withdrawn on 2026-09-11** in favour of the strict one, and `:278` excludes `shell-words`
on exactly this clause. The same reading applied here is consistency, not new strictness. The
decision is also right to keep the archived repository as the maintenance rubric's verdict
rather than the exclusion ground — `gh api repos/dtolnay/basic-toml` reporting `archived: true`
is recorded as corroboration, which is the distinction between a rule and a judgment.

**The whole-tree MSRV claim survives a check the script does not make.** The script computes
the graph maximum with `jq … | select(.rust_version != null) … | max`, so a member declaring
no `rust-version` would be dropped silently rather than failing. I therefore queried
crates.io for every one of the fifteen non-probe packages in the resolved graph at the exact
versions the tree prints. All fifteen declare a `rust_version` (`serde` 1.56, `serde_core`
1.56, `serde_derive` 1.71, `proc-macro2` 1.71, `unicode-ident` 1.71, `quote` 1.71, `syn` 1.71,
`serde_spanned` 1.85, `toml_datetime` 1.85, `toml_parser` 1.85, `toml_writer` 1.85, `winnow`
1.65.0, `indexmap` 1.85, `equivalent` 1.6, `hashbrown` 1.85.0). The filter drops nothing, the
maximum really is `1.85.0`, and the gate-2 statement holds for the whole tree rather than for
a declaring subset.

**Practice evidence is read at pins and is not doing the deciding.** All three adopters ship
both crates, read at pinned SHAs rather than moving branches (log section 8: `rust-lang/cargo`
at `495c385d`, `astral-sh/uv` at `6b40d9e5`, `starship/starship` at `4ff40d06`), and starship
is argued as the closest analogue because its whole configuration surface is a user-edited
TOML file. The decision is explicit that adoption is the *third* and lightest ground for A4,
behind the mandate and the executed measurement. That ordering is what the prompt requires:
popularity does not select the design. I verified the one adopter-adjacent claim that no check
asserts — `https://raw.githubusercontent.com/toml-rs/toml/main/README.md:2`–`:3` reads
"[`toml` crate] for serde support" and "[`toml_edit` crate] for format-preserving editing of
TOML", and the published `toml_edit` rustdoc header reads "If you also need the ease of a more
traditional API, see the [`toml`] crate". The maintainers do document the division of labour
the decision attributes to them.

**Performance is handled by declaring the axis irrelevant, with the workload stated.** The
workload is one sub-kilobyte read per process start plus an occasional single-key write, so no
throughput benchmark is cited or relied on and no candidate is ranked on speed. The decision
notices that this is itself a finding, because it removes the only axis on which the `no_std`
minimalists could have competed. That is the prompt's "do not infer an absolute fastest option
from unlike benchmarks" honoured rather than evaded.

**The `BASELINE-REVIEW: F243` disposition is right, and I checked the count as well as the
handling.** `raw/codex.md` contains exactly one occurrence of the token and `raw/opus.md`'s two
are both statements that it raises none, so one finding is the complete set and nothing was
dropped. The disposition — carried, not a challenge, row stays `COMMON → REUSE` — is correct
on the substance: the line asserts a scope boundary (no TOML crate performs file I/O, so
F243's guarantee is hand-rolled `std::fs` whatever crate is chosen), which is an argument for
or against no candidate. `COMMONALITY.md:247` still reads `COMMON → REUSE` and no ledger change
is proposed. F243's own earlier challenge in `BASELINE-REVIEW.md:150` was already accepted and
closed with the row kept (`:260`, `:325`), so there is nothing reopened here. No `CONFLICT:`
line was raised by either engine and none is raised; the decision consumes R67's
`error-taxonomy-exit-codes` unchanged and says so.

## Completeness

**Structure.** Exactly four H2 sections, `## Decision`, `## Parameters`, `## Empirical check`,
`## Engines`, in that order, with no `## Supersedes` — correct for a first revision and
matching `scripts/research_validation.py:493`. `## Decision` carries exactly one non-empty
`### Principles and implementation`. Exactly one `re-verify:` line outside a fence, inside
`## Decision`, carrying a date plus seven mechanical triggers that are all checkable without
judgment (a version string, an advisory filing, an `archived` flag, a downstream item's
conclusion, an owner choice).

**Parameters.** I rebuilt the comparison mechanically with the validator's own parser rather
than by reading. Zero `- owns` lines, matching the prompt's empty `- owns:`. Five `- assumes`
lines — `msrv-policy`, `rust-edition`, `target-os-matrix`, `license`,
`error-taxonomy-exit-codes` — and **all five compare byte-identical to
`docs/port/PARAMETERS.md`**. The consumed value is the owner-accepted prerequisite's:
`research/topics/67-error-and-exit-code-contract/DECISION.md` hashes to
`16947ab1…9497`, which is exactly the value `inputs/prerequisites.json` records, and R67's own
`- owns error-taxonomy-exit-codes` line matches the registry. The long `error-contract/v1`
value is carried verbatim with no backticks wrapped around it, no citation and no commentary
on the line, which is the format the validator demands; all commentary on how the parameters
bear on the decision sits in prose after the list.

**Gates and figures.** All six fitness gates are answered per candidate before popularity is
weighed, with gate 1 `inapplicable` and a reason rather than omitted. Every figure in the
maturity table names its endpoint, and the retrieval date 2026-09-17 is stated once for the
table and repeated for the up-and-comers. The decision uses `search/issues` `total_count` (57)
and explicitly rejects `open_issues_count` (71) with the reason — the field the prompt's
evidence table forbids is named and refused rather than silently avoided. Volatile figures are
marked `VOLATILE` in the log and are recorded, never asserted on an exact value.

**Unproven rows are honest and complete on the claims that matter.** Seven items are recorded
as unproven with what would prove each: the binary-size and build-time series (attributed to
Opus's single machine, not re-measured, with P03's CI release build named as the proof), the
`unsafe` counts inside `indexmap`/`hashbrown`, Opus's 0.67-day median, the pinned source
repositories, `taplo`'s repository figures, `basic-toml`'s README notice, and AC5. I checked
every carried figure against `raw/opus.md` and each matches the raw exactly. Nothing is
overstated relative to `review/evidence/r52-toml-crate.log`: the decision does not claim
executed status for anything the log does not carry, and where the log's coverage is narrower
than the prose I verified the gap myself and found the prose true (see JF-3).

**The check does not implement the recommendation.** The only Rust compiled is a throwaway
probe in `$TMPDIR` holding a two-field struct and a `main` that prints booleans — "run the
recommended tool against a few sample inputs", which the synthesizer role permits — and the
decision states plainly that no template file, config adapter, file I/O, error mapping, schema
or CI wiring was produced. Nothing was written into the repository outside `review/`. This is
a research programme and P03 proves the recommendation; declining to build it is correct, not
a deficiency, and `## Engines` closes with the eight-row V1–V8 table of what P03 must validate
and what evidence closes each.

**The harness is capable of failing, and that is shown rather than asserted.** `verify.sh` is
690 lines, opens with `set -uo pipefail`, routes every load-bearing claim through one of five
content-comparing helpers, and carries 108 assertions with 108 distinct identifiers — I
counted the `PASS` lines and the distinct ids and both are 108, matching the log's summary of
"108 run, 0 failed, 0 skipped". I ran `shellcheck -S style` against it myself: exit 0, empty
output, and the file carries no `disable` directive, so "ShellCheck-clean" is true at the
strictest severity. The counts claim also holds: the three `head` invocations in the script are
two version banners and one display block, and none of them feeds an assertion or a count —
`S76`, the one assertion near a `head`, is applied to the untruncated `indexmap-block.txt`.

**The retained earlier log cannot be mistaken for the cited run.** `r52-first-run.log`'s very
first line reads "NOTE — THIS LOG IS NOT THE OUTPUT OF THE COMMITTED verify.sh.", followed by
four lines explaining it is an earlier draft retained as proof the harness can fail, and its
summary records 89 run, 19 failed, 4 skipped against the cited log's 108/0/0. The two files
have different names, different first lines and different summaries, and the decision's
evidence table labels the sha256 of each with what it is. There is no way to confuse them.

**Consistency with the empirical audit.** `review/audit-codex.md` (family `openai`, model
`gpt-5.6-terra`) binds the same decision hash `4287ea4d…86d8`, records `approve` with no
unresolved findings, and reports the recorded argv exiting 0 with 108/0/0 both in place and
from a clean `git archive HEAD` extraction. Its comparison — the live rerun differing from the
committed log "only in the two throwaway probe-directory PID paths" — confirms the decision's
own rerun claim, which I did not test. Its independent recount found 7 answered, 3 unanswered
and 15 `epage MEMBER` comments, which is a third independent census agreeing with mine and
with the committed log. The two audits are consistent with each other and with the decision.

## Findings

**No unresolved findings.** The four items below are recorded observations that do not block
acceptance. Each is a precision or presentation improvement for a future revision; none
changes a conclusion, a gate result, a parameter or the recommendation.

1. **JF-1 (non-blocking) — one of the four causes listed for the earlier draft's 19 failures
   actually produced skips, not failures.** The decision writes, at `:369`–`:375`:
   "`review/evidence/r52-first-run.log` is an **earlier** draft's output, in which 19
   assertions failed and the run exited `19` — because that draft computed the repository root
   one directory too shallow, looked for `uv` on `PATH` only, expected the published
   manifests' `[features] default` arrays on one line, and compared the graph MSRV against
   `1.85` where `hashbrown` declares `1.85.0`." I enumerated the draft log's outcomes rather
   than reading its prose: the 19 `FAIL` lines are `S01`–`S04`, `S09`–`S16`, `S18`–`S21`
   (sixteen, from the root-path defect), `S63` and `S73` (the multi-line feature arrays), and
   `S99` (the MSRV comparison) — sixteen plus two plus one. The `uv`-on-`PATH` defect produced
   the four `SKIP` lines `S05`–`S08`, which the same log counts separately as "sections
   skipped: 4". So three causes account for all 19 failures and the fourth accounts for the
   skips. The retained log's own header states this correctly, separating "`S05-S08` were
   skipped because…" from the failure causes; only the decision's one-sentence compression
   merges them. Nothing downstream depends on it — the point being made, that the harness can
   fail and that all its defects were in the check rather than in a finding, is true either
   way. **What resolves it:** split the sentence so the `uv` clause is attributed to the four
   skips rather than to the 19 failures, as the log's own header already does.

2. **JF-2 (non-blocking) — two small quote-fidelity slips, neither altering meaning.** First,
   the indented block at `:429`–`:448` is introduced as "**The observations that decide
   something**, quoted from the log:" and then carries three editorial arrows that are not in
   the log — "`P2_PLAIN_KEEPS_HEADER = false          <- A1's defect, measured`",
   "`P6_NAIVE_KEEPS_TRAILING = false        <- the decor trap`" and
   "`P7_DECOR_KEEPS_TRAILING = true         <- the recipe that works`" — and elides
   `P6_NAIVE_KEEPS_HEADER`/`_PERKEY` and `P7_DECOR_KEEPS_HEADER`/`_PERKEY`. The data lines
   themselves are verbatim, the annotations are true, the selection is announced, and the two
   elided `P7` lines are quoted correctly in prose at `:187`–`:188`, so no claim is affected.
   Second, at `:534`–`:536` the decision writes "Codex's line reads:" and then ends the
   quotation at "do not attribute either property to the selected TOML crate", where
   `raw/codex.md:19` continues "— evidence: [F243 baseline review](…), retrieved 2026-09-16".
   The omitted tail is the evidence pointer, not the assertion, and the truncation carries no
   ellipsis. **What resolves it:** mark the block as a selection with annotations added rather
   than as a quotation, and close the Codex quotation with an ellipsis before the evidence
   tail.

3. **JF-3 (non-blocking) — two supporting clauses reach slightly past the checks cited beside
   them; I verified both are true.** At `:45`–`:47` the decision writes "`toml`'s published
   manifest makes `preserve_order` a non-default feature that pulls `dep:indexmap` into `toml`
   (evidence checks `S63e`, `S63f`). Cargo and starship both enable it because they
   re-serialize whole manifests through `toml::Value`". `S63e` shows `preserve_order` absent
   from the default array and `S63f` shows that a `preserve_order = [` stanza exists; neither
   asserts the stanza's contents, and no check anywhere establishes *why* Cargo and starship
   enable the feature. Both clauses are nonetheless accurate. I fetched the published
   `.crate` myself and the manifest reads `preserve_order = [` / `"dep:indexmap",` / `"std",`
   with `optional = true` on the `indexmap` dependency, so the "pulls `dep:indexmap`" half is
   exactly right; and the log's own section 8 shows both projects enabling the feature
   (`rust-lang/cargo` at `:224`, `starship/starship` at `:88`), so only the *motive* attributed
   to their maintainers is unsourced. Nothing turns on the motive: the ground for leaving the
   feature off is that this template's write path goes through `toml_edit`, which is argued
   independently. **What resolves it:** add the manifest's `preserve_order` stanza to the
   printed evidence, and mark the Cargo/starship motive as inference rather than stating it
   with "because".

4. **JF-4 (non-blocking) — a piece of standard text that supports the recommendation is not
   cited.** At `:108`–`:110` the decision argues the standard's silence on a TOML crate is
   deliberate: "its Appendix E does name Rust crates for other roles — `clap`,
   `figment`/`config`, `directories`/`etcetera` (`S28`) — while no TOML crate appears anywhere
   in the document (`S29`)." That sentence is literally true, and `S29`'s pattern
   (`toml_edit|basic-toml|toml-span|toml = `) finds no match. But Appendix E's *Python*
   paragraph, at `:765` of the pinned blob, reads "For XDG use `platformdirs`; for config,
   `tomllib` (stdlib read) plus `tomli-w` to write." Those are libraries rather than crates, so
   the sentence stands as written and the conclusion — that the Rust crate choice is this
   template's to make — is untouched, since Appendix E is labelled "guidance, not a
   requirement" and its Rust paragraph names no TOML crate. The omission is a missed piece of
   *corroborating* evidence rather than an error: the standard's own informative mapping
   endorses precisely the two-library read/write split for Python that A4 re-motivates for
   Rust. **What resolves it:** note the Python line and say why it does not make the crate
   choice org-locked, which strengthens the paragraph rather than weakening it.

**A latent robustness note that is the empirical lane's, recorded here only so it is not
lost.** `verify.sh:611`–`:612` compares declared `rust_version` values as strings via `jq …
| max`, so a future graph member declaring, say, `1.9` would sort above `1.85` and be reported
as the maximum. It affects nothing in this run — I confirmed all fifteen non-probe members
declare a version and that `1.85.0` is genuinely the largest — and it is not a defect in any
finding.

## Assessment

Approve. The recommendation follows from the evidence as written: A4 is chosen on a
discriminator declared before the comparison, its advantage over A1 was executed rather than
inferred, and its advantage over A2 rests on a dependency-graph delta that was counted
(`toml_edit`, `indexmap`, `equivalent`, `hashbrown` — four crates) rather than estimated. All
six engine disagreements are settled on grounds rather than by preferring an engine: the
mandate disposes of "py loses comments too", the executed probe disposes of A1's fidelity, a
validated control disposes of the RustSec 404, a recount I independently reproduced disposes
of the responsiveness conflict, the prompt and registry dispose of the invented
`toml-codec-stack`, and the published manifests dispose of the feature question. Codex is
credited where it was right — its gate-3 caution was methodologically correct, and its
one-crate position is preserved as the named fallback inside the `re-verify:` triggers rather
than discarded. BASELINE-REVIEW F243's disposition is right: it is a scope boundary, not a
challenge, and the row stays `COMMON → REUSE`. The `## Parameters` grammar and the H2 set are
correct, the five `- assumes` lines are byte-identical to the registry, and the unproven rows
are honest, each with what would prove it. The four findings above are presentational or
concern supporting clauses whose substance I verified true by independent retrieval. **The
recommendation does not move under any finding: `toml` 1.1.6 for the typed read without
`preserve_order`, `toml_edit` 0.25.15 for the comment-preserving `config set` write without
`serde`, and `basic-toml` excluded on gate 2 with its archived status as corroboration, all
stand exactly as written.**
