decision-sha256: ef22112dc9e1cb59fc018f51a7df74ea4730f7fff754b33ae306d72760097101
actor: audit-fable-2026-09-05T151356Z-c46d732f98ed-r7
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: The revision-5 judgment audit is cited at `review/audit-fable.md`, which is this revision-7 judgment audit's own destination — the same audit-path provenance defect that rejected revision 4, and the decision applies its own repair to the empirical audit's path but not to this one

## Principle and agreement level

This audit was produced by a fresh context that wrote none of the five raw
reports, none of the seven decision revisions, none of the empirical audits and
none of the earlier judgment audits (`review/audit-fable.r2.md`,
`review/audit-fable.r3.md`, `review/audit-fable.r5.md`). I read
`inputs/prompt.md`, all five raw reports in `raw/` (`codex.md`, `opus.md` and
the three normalized Doxa provider reports), `review/DECISION.md`,
`review/audit-codex.md` with its predecessors `.r4.md` and `.r6.md`,
`docs/port/PARAMETERS.md`, the spec's governing rule
(`docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` §2 as
carried into the prompt's `## Context` and `## Required evidence`),
`research/RUNBOOK.md` §4, and the `docs/port/BASELINE-REVIEW.md`,
`docs/port/DIVERGENCE-ANALYSIS.md` and `docs/port/COMMONALITY.md` rows this item
touches. I bound the decision at sha256
`ef22112dc9e1cb59fc018f51a7df74ea4730f7fff754b33ae306d72760097101`, which is the
hash given in my task and the hash `review/audit-codex.md` binds.

**The level is read correctly and the sources back it.** The decision states
**capability/standard** and cites `docs/port/BASELINE-REVIEW.md:75`, which I
read: F148, "Enforce the selected commit-message convention at `commit-msg`
time", class `capability/standard`, retained. `docs/port/DIVERGENCE-ANALYSIS.md:155`
classes the R38 item row **B** with `harmonize: partly` and its cause note
D-020(2); the value rows at `:159` and its neighbours are class **A** with
`harmonize: yes` and the open question "pick one footer length cap (or accept
config-conventional's default)". The decision's reading — the *contract* must
agree across py, ts and rs, the *program* that checks it may differ per
ecosystem — is the reading those three rows support, not a convenient one.

**The level is not inferred from repository agreement.** The decision quotes all
five reports reaching the same level and I verified each quotation is in the
file it is attributed to. That is corroboration, and the decision treats it as
corroboration: the binding citation is `BASELINE-REVIEW.md:75`, a recorded
classification, not a vote. This distinction matters more in revision 7 than in
any earlier revision, because the item was reopened precisely for leaning on a
provider's column.

**The five essential behaviors** are derived from the contract, not from either
source tool's feature list, and each is an exclusion criterion that actually
excluded something: (3) header and body/footer caps excludes `convco` and
`cocogitto` from the source files and now excludes `conventional_commits_linter`
from an executed run; (5) fail-loudly excludes `cargo-commitlint`'s installed
hook template. A criterion that never binds is decoration; these bind.

## Design and evidence

**Architecture before libraries.** Alternatives (A) provision a JS runtime, (B)
native binary, (C) hand-rolled regex are compared on costs that are stated in
units and sourced: (A) carries `engines.node >= 22.12.0` and re-imports py's
three measured silent-pass modes from `lefthook.yml:18-58`; (B) loses
config-file identity, which the agreement level does not bind, and converts one
silent-pass mode into a loud 127 (case 16); (C) re-derives a specification.
This is a real comparison with a losing side, not a ratification of the pick.

**The provider-column question, which is why this item was reopened.** I walked
every ground in `## Decision` back to its source. The result:

- The new exclusion sentence for `conventional_commits_linter` 0.17.1 rests on
  five clauses and each maps to an executed row I read in
  `review/evidence/conventional_commits_linter-0.17.1-evaluation.log`: "caps the
  header only" → B2 (`expected=1 observed=1`); "no body-line and no footer-line
  rule of any kind" → B3 (`expected=0 observed=0`) with same-run behavioral
  controls C04 `0` against `C04-ctl` `1` and C08 `0` against `C08-ctl` `1`;
  "two-valued type preset" → B4 and B5 (`--type chore` exits 2 at the parser);
  "declares no `rust-version`" → D2 and D6; "neither a macOS binary nor a macOS
  CI job" → D11, D12, D14, D15. None of these is a provider claim.
- I independently verified the attribution that caused the reopening. The
  OpenAI report's statement about this candidate is at
  `raw/doxa-openai.normalized.md:294` and `:318` and is about **0.16.x** (both
  citations are `https://docs.rs/crate/conventional_commits_linter/0.16.1`); it
  asserts "its preset-oriented interface is below the required configurability"
  and, in the same row, that "License, resolved MSRV, RustSec and macOS-test
  evidence were not established". So the decision's row-19 **O** column —
  "excluded on capability and evidence gates — its own words about 0.16.1, with
  no evidence recorded for the capability half" — is accurate, and the AGPL-3.0
  finding is indeed Perplexity's (`raw/doxa-perplexity.normalized.md:101`). The
  decision's outcome column now reads "O's capability claim is corroborated for
  0.17.1 by measurement — it is not adopted as a citation, and it was about a
  different version." That is the correct disposal: the provider's claim is
  demoted to a lead and the ground is the measurement.
- The remaining provider-attributed material in `## Decision` is either a
  statement *about* what a provider picked (used to show the field was
  surveyed, never as a ground), or is labelled as unverified where it is:
  the four adopters the OpenAI report added are marked "retrieved 2026-09-09 by
  that report and not re-fetched here" and repeated in the uncertainty list;
  `gitfluff` is marked "classified from the Gemini report's own exclusion and
  the crates.io record, not executed"; the Gemini figures are named wrong
  against the endpoints and discarded. Provider-sourced **and disclosed as
  provider-sourced** is the opposite of the defect this item was reopened for.

**The owned parameter is justified, and not from py/ts agreement.** I extracted
the `- owns` value and the `docs/port/PARAMETERS.md:13` value cell and diffed
them: 508 bytes each, byte-identical. On its justification:

- *Eleven-member enum* — ts's explicit list plus py's inherited
  config-conventional default already equal it, but the decision does not stop
  at that. Its binding argument is the downstream one: all eleven appear in
  `conventional-changelog-conventionalcommits` `DEFAULT_COMMIT_TYPES` with a
  section and a bump effect each, so the enum maps to changelog sections without
  renaming — the release-tooling coupling, named to R24 and the release-please
  rows F063/F066/F073, with the mapping itself left to R24. `committed`'s own
  default is eight members, which is *why* `allowed_types` must be explicit; the
  missing three (`build`, `ci`, `revert`) are the ones the container and
  deployment surfaces use. R25's territory is named where it belongs (line 138:
  the bypass-actor Apps' message shapes "belong to R07, R21 and R25, not to this
  item"), which is the correct boundary — R25 is not a registry dependency of
  R38 and the prompt's `## Couplings` does not list it.
- *Header cap 50* — decided against the OpenAI report's 72 on `git-commit`
  DISCUSSION and Pro Git guidance, ts's explicit `header-max-length` 50, and an
  executed measurement (case 21: a 66-column header whose description alone is
  41 columns fails at 50 under both `committed` and commitlint), which dissolves
  the report's subject-versus-header distinction. The decision says four of five
  reports also say 50 and immediately marks that as corroboration that "does not
  decide". Correct ordering.
- *Body and footer 72* — decided against the 100 all three provider reports
  propose, on the ground that 100 is config-conventional's inherited default
  that ts never chose (`DIVERGENCE-ANALYSIS.md:159` asks this item to pick), and
  on executed cases: the org's real trailers pass at 72 under soft-line
  measurement (05, 07) while a spaced 96-column `Reviewed-by:` is rejected (08).
  Three reports agreeing is explicitly not the reason. The single-knob
  consequence is recorded as stated gap 1 rather than presented as a choice.

**Where the linter runs, and what a contributor sees.** Hook plus CI follows
from a stated principle — every commit that lands satisfies one contract, and
`git commit --no-verify` must not evade it — and that principle is executed, not
asserted: H2 then H3 shows the bypass succeeding locally and the range check
catching the commit. The contributor-facing surface is concrete and verified:
the `.gitmessage` template is given verbatim and is comment-only, so an unedited
template aborts; the rejection messages are quoted from observed output rather
than paraphrased; the two documented-but-unenforced conventions (lower-case
subject, imperative mood) are marked as such inside the template itself, which
is the defect ts's `.gitmessage:12` carries and this one deliberately does not.
The CI job is labelled "illustrative" and defers structure to R11, pinning to
R20 and permissions to R08 — correct scope discipline for an item that owns the
tool and its rules, not the workflow. Two contributor obligations are stated as
obligations rather than hidden: `CONTRIBUTING.md` must require rebasing, because
`committed` rejects local merge commits at the hook (case H5); and R19 must set
dependabot's `commit-message.prefix`, or the bot path's type check turns every
dependabot PR red.

**What is verified is separated from what P03 must prove.** `## Validation that
remains planned, not executed` names three items — x86_64 `ubuntu-latest` (the
Linux leg ran on aarch64 in a Lima VM), the SHA-pinned action on a live pull
request, and the hook through R37's chosen manager with the `{1}` placeholder —
and each is a genuine gap with the thing that would close it. The decision does
not implement its own recommendation, which is correct for this programme, and
it is not faulted here for declining to.

**The empirical check verifies the claims it is cited for.** I confirmed by
reading the logs, not the prose: `committed-1.1.11-acceptance-r4.log` ends
`summary: PASS=35 FAIL=0 RECORD=5` / `RESULT: PASS` / `RUN_CHECKS_EXIT=0`, and
the T1 row's `running 4 tests` / `4 passed` is present. The evaluation log's
asserted rows are all `expected=` equal to `observed=`, and it ends
`PASS=55 FAIL=0 CONTRACT_VIOLATIONS=3` with the three violations being C04, C08
and C06 exactly as the decision reports, including the decision's careful
statement that C06 is against the recommended `committed.toml`'s
`subject_not_punctuated` criterion and *not* against `commit-message-convention`,
which states no punctuation rule. That distinction is the kind a decision under
pressure usually blurs; here it is drawn correctly.

**The revision-7 repair is real and I checked it independently of both the
decision and the empirical audit.** The revision-6 log
(`conventional_commits_linter-0.17.1-evaluation.r6.log:82`) carries the absolute
`/Users/stevemorin/.../.work/upper-bad.txt` in the C23-ctl diagnostic; the cited
revision-7 log carries `upper-bad.txt: error Disallowed type \`WIBBLE\` ...` at
line 86, and a grep of that log for `/Users/`, `/private/tmp` and `/tmp/`
returns **zero** matches. The stated difference rule is demonstrated rather than
asserted: `r38-crossrun-compare.log` ends `failed assertions: 0` with exactly
**102** `PASS`-prefixed assertions and **0** `FAIL`-prefixed — the decision's
"102 assertions" is the literal count — across five classification comparisons
(PHASE C) plus negative controls that refuse an altered assertion row, the
revision-6 absolute-path line substituted back in, head and tail line-count
changes, and each class shape placed out of position. The decision's own
statement of what was *not* observed live (class F never moved inside the
comparator's window; classes H and S cannot vary on one host) is honest and
matches the log.

**The audit-codex rerun is consistent with the decision.** `review/audit-codex.md`
binds the same hash, verdict approve, findings none. Its reruns reach the same
asserted result lines from a clean `git archive HEAD` extraction, and its
`audit-r7-cited-vs-pure-archive.diff` — which I read — shows the cold rerun
differing from the cited log in exactly two places: the `[volatile line]`
timestamp and two counters inside the `[volatile section]` figures block. That
is classes T and F and nothing else, which is what the decision's rule permits
and what revision 6 could not claim. Its `audit-r7-citation-checks.log`
independently confirms `rust_version` `None` and `AGPL-3.0` at 0.17.1, the two
Linux-musl-only release assets, the `architecture: [ubuntu-24.04,
ubuntu-24.04-arm]` matrix with no macOS job, and `committed`'s own
`os: ["ubuntu-latest", "windows-latest", "macos-latest"]` — so gate 4 pass for
the selected tool and gate 4 unmet for the candidate both rest on read sources.

## Completeness

**Required fields.** `## Decision`, `## Parameters`, `## Empirical check`,
`## Engines` in order, with `## Supersedes` last as the spec permits for a
reversal of a published exclusion, and `re-verify:` still the final line of
`## Decision`. Ledger rows F149-F157 are all settled with values; the two
`ADOPT` rows the baseline review left blocked receive derived values, and I
confirmed those are `docs/port/BASELINE-REVIEW.md:76` (F158) and `:78` (F160) as
cited.

**Parameters.** One `- owns` line, four `- assumes` lines (`msrv-policy`,
`rust-edition`, `target-os-matrix`, `license`), `Consumed parameters: none`
matching the prompt's empty `- consumes:`. The owned value is byte-identical to
`docs/port/PARAMETERS.md:13` as measured above, and the registry note correctly
proposes a *description*-column edit for the bot clause rather than a value
change.

**Fitness gates.** All six are present for `committed` 1.1.11 with evidence
columns. Gate 1 is recorded `inapplicable` with the owner's 2026-09-12 Q7.B
ruling named and the reason for keeping the row rather than deleting it; per my
task's settled ruling this is correct and is not a finding. Gate 4's treatment
of the excluded candidate is the strongest piece of gate reasoning in the
document: it separates the gate's "builds" half (met, and demonstrated by this
very run producing a working macOS arm64 binary) from its "tested" half
(unmet), instead of collapsing both into a convenient failure.

**Source dates.** Every figure carries its endpoint and a retrieval date, and
the re-reads are dated separately (2026-09-05, 2026-09-09, 2026-09-13). The
maintenance-state rubric is applied rather than asserted: for the excluded
candidate the decision declines to claim `at-risk` because 9 of the 10 most
recent issues were filed by the sole maintainer, so the responsiveness metric
has no sample — and records single-maintainer concentration instead. That is
the rubric used honestly against the decision's own interest.

**`BASELINE-REVIEW:` and `CONFLICT:` handling.** No `CONFLICT:` line exists in
any raw; I grepped all five and confirm the decision's account, including that
the Gemini report's malformed `assumes` lines are not parameter conflicts. On
`BASELINE-REVIEW:`, I counted the lines myself: Codex 1, OpenAI 4, Perplexity 2,
Gemini 6, Opus none (it states none). All thirteen target F149-F157 — rows R38
itself owns and settles — and none targets a `REUSE` or `ADOPT` baseline
belonging to another item, so under `RUNBOOK.md` §4, where adjudication is the
controller's act with the affected decision owners, none requires adjudication.
Their substance is disposed of in disagreement rows 1, 9, 10, 11, 16, 17 and 18.
The decision names only the Codex line; that the twelve Doxa lines are not named
remains open observation 1 below, not a finding.

**Supersedes.** I extracted the payload (line 308 to end of file), measured it
at 82,801 bytes with sha256
`97da7f169f26fce8f9b43c3d6c2eb0971b991f45b0d00ae2a91c5ddc3cbe4437`, and ran
`diff` against `research/topics/38-commit-message-linter/DECISION.md`: **no
differences**. Byte-for-byte verbatim, matching the published file's size and
hash exactly.

**Scope of the revision, verified by diff rather than accepted from the note.**
`## Decision` differs from the published revision 5 in exactly **seven** lines:
the opening decision paragraph (gains the exclusion sentence), the field
paragraph, the gate-1 row, the figures paragraph, the reference-implementation
paragraph, the runner-up paragraph and the `re-verify:` line. No ledger row, no
acceptance-criterion row, no configuration snippet, no hook command and no CI
snippet changed — so the decision's claim that the recommendation, the pin,
every ledger row and every acceptance criterion are untouched is true as
measured. `## Parameters` is byte-identical between the two revisions. I also
recovered revision 6 from git (`34add70`, sha256 `389fbbc0…`) and diffed it
against revision 7: `## Decision`, `## Parameters` and the `## Supersedes`
payload are **byte-identical**, and only seven lines differ in the whole file —
the title, the preamble, the reproducibility passage, the revision note, the
uncertainty list, the Doxa source list and the Supersedes prose. Revision 7's
claim that it adopts the empirical finding "and nothing else" is therefore
literally true, which is the property a repair revision most needs and most
often lacks.

## Findings

Unresolved findings: one.

1. **The revision-5 judgment audit is cited at a path that this audit occupies.**
   The decision's preamble names the revision-5 approving judgment audit as
   "`review/audit-fable.md` (actor `audit-fable-2026-09-05T151356Z-c46d732f98ed-r5`,
   verdict approve, unresolved findings none, eight text observations left for a
   future revision), **still under its live name**". `review/audit-fable.md` is
   the required destination for this revision-7 judgment audit — the role
   contract fixes it at `docs/superpowers/plans/p02-roles/judgment-auditor.md:23`
   ("Write `review/audit-fable.md` with these one-per-line fields first"), and
   the round-7 task message instructed me to archive the revision-5 file as
   `review/audit-fable.r5.md` first, which I did before writing. From this
   moment the decision text attributes a revision-7 report's path to the
   revision-5 audit.

   This is the defect that rejected revision 4. `review/audit-codex.r4.md`
   states it in two parts: the named paths did not hold the cited artifacts,
   **and** "`review/audit-codex.md` is the required destination for this
   revision-4 audit, so the current text would attribute a revision-4 report to
   revision 3." The second part is the part that binds here, and it binds
   identically. Revision 5 existed only to make that correction.

   What makes this a finding rather than bad luck is that the decision applies
   the repair asymmetrically. For the empirical audit it writes the forward
   clause — "read at `review/audit-codex.md` and expected to be archived as
   `review/audit-codex.r6.md` when the controller launches the revision-7 audit,
   which is the pattern that produced `review/audit-codex.r5.md`" — and that
   clause is now correct, because `review/audit-codex.r6.md` exists and
   `review/audit-codex.md` holds the revision-7 empirical audit. The same
   sentence declines to write the parallel clause for the judgment audit, whose
   live name rotates on exactly the same schedule and for exactly the same
   reason. The decision demonstrably knew the rule and did not finish applying
   it.

   The correction is one clause and touches nothing else: replace "still under
   its live name" with a forward-looking form such as "read at
   `review/audit-fable.md` and expected to be archived as
   `review/audit-fable.r5.md` when the controller launches the revision-7
   judgment audit". No ground, gate, parameter, ledger row or piece of evidence
   moves. I reject only until that citation is accurate.

**Observations (no decision change required; recorded for the controller and for
a future revision).** Observations 1, 2, 3, 5, 6, 7 and 8 left by the
revision-5 judgment audit remain open and are correctly listed as open in
`## Engines`; revision 6 applied observation 4. I do not re-open them here,
because each would change text both revision-5 auditors approved on a question
neither revision 6's scope nor revision 7's touches. I add three:

- **The revision note under-enumerates its own `## Decision` edits.** The note
  says revision 6 changes "the gate-1 row and the two other places that reported
  a licence exclusion; the field paragraph ...". In published revision 5 the
  licence exclusion is reported in `## Decision` in exactly **one** place (the
  field paragraph), and the seven changed lines I measured include four the note
  does not enumerate: the opening decision paragraph, the figures paragraph, the
  reference-implementation paragraph and the runner-up paragraph. All four are
  the same substantive change — recording the executed evaluation of the
  re-entered candidate — all four are additions rather than reversals, and all
  four are described in substance in the `## Supersedes` prose, so nothing is
  hidden. The note's "two other places" may well be counting across the whole
  document (row 19 in `## Engines`, and prose that did not yet exist), which I
  cannot disprove; the observation is only that a reader who takes the note as
  an inventory of `## Decision` edits will find four more than it lists. A
  future revision could say "the field paragraph and the four other places that
  now record the candidate's evaluation".
- **The `(?i)` claim is a source read with no saved artifact.** The decision
  explains `committed`'s and the candidate's case-insensitive type matching by
  `ANGULAR_TYPE` being "compiled with `(?i)`", citing
  `src/commits/commit/constants/mod.rs` in the published crate. No D-check in
  the evaluation log reads that file — I grepped the log for `constants`,
  `ANGULAR` and `(?i)` and found none — so the mechanism rests on an
  unpreserved read. The *behavior* it explains is proven by C22/C22-ctl and
  C23/C23-ctl, which is what the decision actually uses, so this is
  presentational.
- **The 263-repository figure has no saved artifact, and the decision says so.**
  The companion 18-repository count is printed in the cited evaluation log; the
  263 is not, and the decision states plainly that "neither number is asserted
  by the evaluation script" and lists both in the uncertainty paragraph as
  indexed code-search output rather than a census. Correctly labelled; recorded
  only so a future revision does not mistake it for measured evidence.

## Assessment

Revision 7 is a narrow, correct repair of a real defect, and the narrowness is
demonstrated rather than claimed: `## Decision`, `## Parameters` and the
`## Supersedes` payload are byte-identical to revision 6, and the payload is
byte-identical to the published revision 5.

On the question this item was reopened for, revision 7 is clean. Every ground in
the outcome text traces to the decision's own reasoning, to a primary source it
names with a date, or to an executed check whose asserted row I read in the log
— including, critically, the new `conventional_commits_linter` exclusion
sentence, whose five clauses each land on a check (B2, B3 with the C04/C08
same-run controls, B4/B5, D2/D6, D11/D12/D14/D15). The OpenAI report's
capability claim, which is the ground that sat in a provider column and caused
the reopening, is now handled exactly as it should be: verified against a
different version than the one the report discussed, demoted to a lead, and
replaced by measurement that the decision states is "not adopted as a citation".
Where provider material does remain load-bearing-adjacent — four adopters,
`gitfluff`'s capability exclusion — it is labelled provider-sourced and repeated
in the uncertainty list, which is the disclosure the R38 lesson asks for.

The owned parameter is byte-identical to the registry and is justified from Git's
own guidance, from the release-tooling mapping in
`conventional-changelog-conventionalcommits`, and from executed measurement of
what each cap accepts and rejects — with agreement among reports explicitly
marked as corroboration that does not decide. The hook-plus-CI placement follows
from a stated bypass-resistance principle that is executed (H2/H3), and the
unexecuted remainder is named with what would prove it.

I reject on one narrow point, and I want to be precise about what it is and is
not. It is not about the pick, the pin, the gates, the parameter, the evidence,
or the repair — all of which I checked and all of which hold. It is that the
decision cites the revision-5 judgment audit at the path this revision-7
judgment audit is required to occupy, and so, from the moment this file is
written, misdirects a reader by one revision. The programme has already rejected
a revision of this item on precisely that ground, and the decision applies the
forward-looking repair to the empirical auditor's path in the same sentence
where it omits it for the judgment auditor's. One clause closes it.
