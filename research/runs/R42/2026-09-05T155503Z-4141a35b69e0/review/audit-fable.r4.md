decision-sha256: 7ad0e5dabe14d5004054cf7ee729f9dd82fdda9321d9086856eaaa8f99510aa4
actor: audit-fable-2026-09-05T155503Z-4141a35b69e0-r4
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: unproven item 1 states "Checks 9-12 postdate that audit and have no Linux leg", which the decision's own live `BASELINE-REVIEW: F181` line and sweep row 3 contradict — the r2 and r3 empirical audits reproduced check 9's matrix and check 11's precedence probes on a Lima Ubuntu VM, so the item is false for checks 9 and 11 and its lead sentence "in both revisions" is stale at revision 4; the figure table is headed "Figures, all retrieved 2026-09-10" but the `rustup` row's RustSec cell "none (404)" was never queried by check 7 and is carried unattributed from `raw/opus.md:283` (retrieved 2026-09-05), and the same row's "Apache-2.0 OR MIT" sits under a "Licence (crates.io)" header with no crates.io query for `rustup` in any log

## Principle and agreement level

Unchanged from revision 1 and still correct; my predecessor's assessment of this
section stands and I re-verified only that revisions 2 through 4 did not disturb
it. The shared requirement is stated once — *one command reports exactly which
dev tools are missing with the exact remediation for each, and every repeatable
task then invokes those tools by a single stable name that does not depend on
how they were installed* — at the agreement level **architectural pattern plus
policy**, which matches spec §2's table: a discover-report-remediate loop is a
responsibilities-and-relationships claim, and a stable invocation vocabulary is
a deliberately shared mechanism. The must-agree / may-vary split is explicit.

Spec §2's fitness test for a shared pattern is performed rather than asserted,
and it splits the pattern from the mechanism for a structural reason: py's four
tools sat outside `uv`'s reach because `uv` installs Python distributions,
whereas `taplo-cli`, `typos-cli` and `cargo-nextest` are themselves crates that
Cargo reaches and rustup reaches `rustfmt` and `clippy` by definition. The loop
survives; the per-tool layer dies. That argument is independent of the
repository count, which is the right shape for a conclusion that also rests on a
negative survey.

No `OVERRIDE` is owed. F183, F187, F188 and F189 are `py-only` / `DIVERGENT`
rows assigned to R42 (`docs/port/COMMONALITY.md:187`, `:191`–`:193`), so
declining to port them is this item's decision; the two `COMMON → REUSE` rows it
touches, F179 (`:183`) and F181 (`:185`), are both **retained**, so no displaced
pattern exists. Building nothing is correct under the programme's research-only
ruling, not a gap.

## Design and evidence

**The three findings of `review/audit-fable.r1.md` are genuinely closed.** I
checked each against the current text and against the evidence it now cites,
not against the revision history's account of itself.

*F1 — the presence test.* The owned parameter (`## Parameters`, `DECISION.md:287`)
no longer keys presence on the executable's name. It now keys it on acquisition:
a tool installed from crates.io or from a release — `cargo-<sub>` plugin or bare
binary alike — is tested with `command -v <executable>`; a tool rustup installs
is tested with `rustup component list --installed`, remediated by
`rustup component add <component>`, with `rustup which <executable>` named as
the per-tool equivalent. It states in terms that "**`command -v` is never the
test for a rustup component**". The rule is now proved in both polarities rather
than assumed: check 9 ran nine commands in three pinned-toolchain directories and
`evidence/presence-test.log` records `command -v cargo-fmt` and
`command -v cargo-clippy` exiting 0 in all six cells — including `neg/`
(`1.97.1`, carrying neither component) and `c196/` (`1.96.0`, carrying `rustfmt`
but not `clippy`) — while `cargo fmt --version` exits 1 in `neg/` with
`error: 'cargo-fmt' is not installed for the toolchain
'1.97.1-aarch64-apple-darwin'`, and the component-state test returns rustfmt
`1/0/0` and clippy `1/0/1` across `neg`/`pos`/`c196`, matching the truth in every
cell. Check 12 shows the defect is not confined to `cargo-<sub>` names: 13
entries in `~/.cargo/bin` are symlinks to `rustup`, so `command -v rustfmt
rust-analyzer` exits 0 in `neg/` while both `--version` calls exit 1. That is the
sound test my predecessor's option (b) asked for, and the parameter reserves
`command -v` for the class the stub experiment actually covered.

*F2 — the omitted disagreement.* `## Engines` now carries disagreement 6, "How
is presence tested — an ambient `PATH` search, or declared state?". I verified
both quotations against the raws: `raw/doxa-openai.normalized.md:201` reads
verbatim as quoted, and `raw/doxa-gemini.normalized.md:48` reads "Eliminate the
`command -v` loop presence tests in `check-deps`" with the rationale "Because
`mise` and `cargo-run-bin` deterministically ensure tool presence before
execution, manual presence testing becomes redundant boilerplate". The
decision's handling is the one my predecessor asked for and is better than
required: it separates gemini's rationale, which is *entirely*
provisioner-dependent and therefore falls with disagreement 1, from openai's two
halves, adopts the mise-independent half ("rustup component state") and records
that openai's stated diagnosis — "search ambient `PATH`" — is right for one class
and wrong for the other.

*F3 — Cargo aliases.* The parameter now names the alias as the fourth invocation
form, states that the template defines none, gives three reasons at the strength
each is supported (duplicated naming location; invisibility to the prescribed
presence test, verified by check 11's `command -v cargo-myver` exit 1 against
`cargo myver` exit 0; and the warned, future-fatal shadowing, explicitly demoted
to a lesser third reason), and — the half that matters to a consumer — permits
an alias in a **consuming repository** as a spelling of the `cargo <sub>` form
with its presence test targeting the underlying tool, "for `lint = "clippy …"`,
clippy's component state", never `cargo-<alias>`. R28, my predecessor's worked
example, can now spell both its invocation and its presence test without
guessing. Acceptance criterion (E) adds the `[alias]` prohibition, and check 13
measures the alias form in the field it cites (`oxc` 14 justfile lines, `biome`
three, `just` and `cargo-binstall` HTTP 404 for `.cargo/config.toml`), correcting
the r1 sentence that claimed all four `justfile`s exemplified the split rule.

**The recommendation still follows from the evidence, and its central negative
finding is not the load-bearing member.** The 0-of-17 provisioner result is
scoped in the decision's own words throughout ("0 of 17 surveyed", "measured
adoption in the surveyed Rust field"), reproduces `raw/opus.md`'s independent
2026-09-05 measurement, was rerun on Linux by the r1 empirical audit, and carries
a re-verify trigger if a repeat finds provisioner manifests in a material
fraction. It is not asked to carry the conclusion alone: the structural argument
above does that, and the decision rejects the option with the *best* declarative
adoption in its own sample (`flake.nix`, 5/17) on a template-specific argument
rather than on adoption. Three of five engines recommended `mise` and are settled
against by re-measurement, with openai's own concession quoted against its
position and gemini's `uv`/`dioxus`/`leptos` adoption claim falsified against
`astral-sh/uv`'s root. That is the opposite of selection by agreement, which
spec §2 forbids.

**The licence exclusion is still posed as an owner ruling, not asserted.**
`docs/port/PARAMETERS.md:10` words gate 1 as "candidate **crates** must be
compatible", and `cargo-binstall` is a separate process linked into nothing, so
the gate's reach is a reading of a fixed owner parameter rather than an
evidentiary question. The decision supplies what a ruling needs — the verified
fact (`1.23.0`, `GPL-3.0-only`, `2026-09-05T16:59:01Z`, matching
`evidence/crates-io.log`), both readings with their advocates, the one-line
consequence, a default clean under either reading, and `cargo-quickinstall`
0.3.53 as the licence-clean prebuilt alternative — and explicitly does not adopt
opus's mere-aggregation argument. Unproven item 7 classifies it as not
researchable. Unchanged from revision 1 and still right.

**Assertion strength, re-checked in the two places revision 4 edited.** I read
the live `BASELINE-REVIEW: F181` clause (`:55`–`:97`) and the owned parameter's
closing clause (`:287`) directly rather than through the sweep table. Both now
assert only observed cells and both name the scope: the macOS 26.4/arm64 host,
rustup 1.29.1, four already-installed toolchains, the six check-9 cells, and the
one Linux VM the r2/r3 audits add, each closing with a statement that no other
machine or rustup version was tested. The universals the r3 audit rejected ("on
any machine where rustup itself is installed"; "wherever rustup is installed")
are gone from the live text and survive only as retrospective quotations in the
sweep table, which is the correct place for them. My own grep for absolute
characterisations across the whole file returns hits only inside the sweep
table's quoted phrases, inside normative statements of what the template *must*
do, and at `:394` (fitness gate 3's process-isolation claim), which sweep row 18
classifies as a property rather than an observation. One class of overstatement
survives, in a section neither sweep looked at — Finding 2.

## Completeness

Present and correct: the four required H2s in order with `### Principles and
implementation` nested under `## Decision`; `re-verify: 2027-03-10` plus six
named earlier trigger events; settled rows F183 (decided), F187/F188/F189 (not
adopted) with verdict strings left to the controller as `docs/port/README.md`
requires; the owned parameter and four assumed fixed parameters quoted with their
registry values; an explicit statement that no `CONFLICT:` line is owed with the
reason; the toolchain, OS, UTC convention and a working-directory paragraph that
enumerates every scratch file written outside the repository; all six fitness
gates answered with `inapplicable` plus a reason where inapplicable; the prompt's
figure table with endpoints and the `search/issues` `total_count` rule honoured;
maintenance state by the prompt's rubric with `at-risk` resting on concrete
signals.

Both `BASELINE-REVIEW:` lines still carry the runbook's four fields plus an
`Affected:` list and are responsive to what `docs/port/BASELINE-REVIEW.md` asked
of R42: F179 (`:276`) asked that Make be justified against R42 rather than
asserted as the only dependency-free entry point, and the decision answers with a
measurement (0/17 root `Makefile`) that concedes the cost; F181 (`:86`, `:316`)
was blocked pending R42 with "may collapse into F180", and the decision retains
it as a distinct Level-2 check on a disjoint-scope argument and now settles the
presence-test half the ledger row explicitly deferred to
`package-manager-invocation`. Neither edits the ledger. The F190/F103 handling
still matches the reconciliation record (`:258`, `:311`): `profile` and
`components` only, `channel` left to R27, labelled a coordination note rather
than a `CONFLICT:`.

**The owned parameter is complete enough for a downstream item to apply without
guessing**, which is the standard that matters for a parameter six items consume
(`docs/port/PARAMETERS.md:14`). I walked all six consumers: R27 and R28 take the
rustup-component branch on both axes with the alias question answered explicitly;
R29 and R40 take the bare-binary branch; R32 takes the `cargo-<sub>` plugin
branch; R37 is the only awkward case, because lefthook's distribution channel is
R37's to choose and may be neither crates.io nor a GitHub release — but axis (ii)
gives the *reason* for its split ("where the `PATH` entry *is* the tool"), which
classifies a novel channel without a further ruling, and R37's own prompt already
records the dependency.

**`review/audit-codex.md` (r4) is consistent with the decision** and its own
scope is stated honestly: no rerun, matching the host constraint; it verified all
eighteen sweep rows against their cited current locations, confirmed the live
F181 text and the owned parameter are scoped to the tested cells, and confirmed
revision 4's commit touched `DECISION.md` and no evidence log. Its scope did not
reach `## Engines`' unproven list, which is where Finding 1 sits.

**The unproven list is honest in intent and complete in coverage** — ten items,
each naming what would prove it, covering the Linux gap, proxy resolution, the
whole loop, the acquisition backend, the compile-time cost the licence-clean
choice buys, layer 4's zero occupants with its maintainer's counter-recommendation
quoted rather than suppressed, the owner's gate-1 reading, R27's channel, the
unenforced prohibition and the unmeasured issue-response medians. Item 1's text,
however, no longer describes the record (Finding 1). One class the parameter
names is not separately dispositioned in the presence axis — Cargo's built-in
subcommands — and I record below why that is not a finding.

## Findings

**1. Unproven item 1 contradicts the decision's own live text: checks 9 and 11
do have a Linux leg, added by the r2 and r3 empirical audits and credited twice
elsewhere in this file.**

`DECISION.md:714`–`:715` closes unproven item 1 with: "Checks 9–12 postdate that
audit and have no Linux leg." Three passages in the same file say otherwise:

- `:77`–`:79`, the **live** `BASELINE-REVIEW: F181` clause — the sentence
  revision 4 was written to land — reads "the archived audits
  `review/audit-codex.r2.md` and `review/audit-codex.r3.md` add the same
  three-cell result on one Linux VM."
- `:508`–`:512`, the revision-2 history: that audit "reran check 9's nine
  commands in each, on macOS **and** on a Linux VM, and matched both matrices".
- `:570`–`:574`, the revision-3 history: that audit "repeated the check-9 matrix
  and the check-11 precedence probes on Lima Ubuntu".
- `:548`, sweep row 3, names "the one Linux VM the r2 and r3 audits add" as part
  of the scope the corrected F181 clause states.

The audits themselves confirm it. `review/audit-codex.r2.md:14`–`:16`: "The same
Linux VM matrix selected the corresponding `aarch64-unknown-linux-gnu` channels
and matched the results… both proxy lookups exited 0 in all three cells;
component-state and `rustup which` results were rustfmt `1/0/0` and clippy
`1/0/1` for neg/pos/c196". `review/audit-codex.r3.md:15`–`:16`: "On Lima Ubuntu,
after `source $HOME/.cargo/env`, repeated the check-9 matrix and the check-11
precedence probes against Linux-target fixtures."

So the item is accurate for checks 10, 12 and 13 and false for checks 9 and 11.
Its lead sentence, "Every command in `## Empirical check`, in **both revisions**,
ran on macOS 26.4 / arm64 only", is additionally stale: the document now has four
revisions, and while revisions 3 and 4 ran nothing, the phrase reads as a count
of the document's revisions rather than of the check-running ones.

Why this blocks rather than being conservative over-listing. The owner's rule
protects a claim recorded as unproven with what would prove it; it does not
protect a sentence that the same document's load-bearing clause falsifies. The
direction of the error is toward understatement, which is the safe direction for
a *claim* — but this is not a claim about the world, it is a statement about what
a named audit did, and it is wrong about that. It also lands on the exact
sentence revision 4 exists to support: the scoping of the F181 clause leans on
"one Linux VM", and the unproven list denies that VM exists. A P03 reader taking
the unproven list at face value would either re-run a matrix already reproduced
on two operating systems, or conclude that one of the two passages is unreliable
and not know which. The standard this programme applied to revisions 2 and 3 —
each rejected on a single sentence describing the record differently from what
the record holds — applies here unchanged.

What would resolve it: replace the closing sentence of item 1 with what the
audits actually did, e.g. "Checks 9 and 11 were reproduced on one Lima Ubuntu
arm64 VM by the r2 and r3 empirical audits; checks 10, 12 and 13 have no Linux
leg; none of the checks has run on `ubuntu-latest`, which is what the proof line
asks for." Adjust "in both revisions" to name the revisions that ran checks.

**2. The figure table is headed "all retrieved 2026-09-10", but two cells of the
`rustup` row were not retrieved by any check in this decision.**

`DECISION.md:356`–`:357` heads the table "**Figures, all retrieved 2026-09-10**
(endpoints per the prompt's evidence table…)". The `rustup` row (`:370`) reports
RustSec "none (404)" and Licence "Apache-2.0 OR MIT" under a column headed
"Licence (crates.io)". Neither was retrieved here:

- `evidence/github-rustsec.log:31`–`:39` records the check-7 probe for exactly
  five names — `cargo-binstall`, `ubi`, `mise`, `just`, `cargo-run-bin` — plus
  the `time` and `atty` HTTP-200 controls. `rustup` is absent, and check 7's own
  row in the table (`:348`) lists the same five. No other evidence log contains a
  `rustsec.org/packages/rustup.html` probe.
- `evidence/crates-io.log` queries seven crates; `rustup` is not among them. The
  only recorded licence figure for `rustup` is `github-rustsec.log`'s
  `"license":"Apache-2.0"` from the GitHub endpoint, which is neither the
  crates.io field the column names nor the dual value printed.

The figure itself is true and is sourced *inside this run*: `raw/opus.md:283`
records `https://rustsec.org/packages/rustup.html` → HTTP 404 on **2026-09-05**,
with the same two controls. So this is a provenance and date error, not a
fabricated number, and it is materially harmless — `rustup`'s advisory status
selects nothing. It is a finding for three reasons: the prompt's constraint is
"Every claim carries a source URL and retrieval date"; the decision already
demonstrates the correct convention two paragraphs later, where the maintenance
paragraph says issue-responsiveness medians "are carried from `raw/opus.md` where
cited"; and the same table marks genuinely unqueried cells "not queried"
(`cargo-quickinstall`, `cargo-make`), so this row is inconsistent with its own
neighbours. `## Fitness gates`' sentence "Gate 3: no RustSec page for any
candidate, verified against HTTP-200 controls" inherits the same overreach.

What would resolve it: mark the two `rustup` cells as carried from
`raw/opus.md:283` at 2026-09-05, or as "not queried", and narrow gate 3's
sentence to the names check 7 probed.

## Assessment

**Reject**, on two findings, both in text that lags the record rather than in the
research. The repair I asked for as this decision's r1 judgment auditor landed
and landed well: the presence test is now keyed on acquisition, proved in both
polarities across six cells and three pinned toolchains and reproduced on two
operating systems by the empirical audits; the omitted disagreement is recorded
with both engines quoted and openai's mise-independent half separated and
adopted; and the alias form is answered on both axes, including the presence
target a consuming repository needs. **The owned parameter itself is now safe for
a downstream item to apply.** Neither finding touches it, neither touches the
five-layer recommendation, and neither requires new research; both are one
sentence each.

Recorded explicitly so they are **not** re-litigated on revision 5, in addition
to everything `review/audit-fable.r1.md` recorded as settled (the 17-repository
survey, the licence ruling's form, both `BASELINE-REVIEW:` lines, the F190/F103
coordination, and building nothing):

- **The presence axis's silence on Cargo's built-in subcommands is not a
  finding.** Axis (i) names built-ins as a distinct invocation form and states
  they "ship inside Cargo and have no `cargo-<sub>` executable at all", which
  forecloses `command -v cargo-test` in good faith; check 11 records that probe
  exiting 1 for four built-ins in the same document. Cargo is itself a rustup
  component — `evidence/presence-test.log` shows `cargo-aarch64-apple-darwin` as
  the first line of `rustup component list --installed` — so axis (ii)'s rustup
  branch reaches it literally if a consumer ever needs it. The
  `BASELINE-REVIEW: F181` clause states that F181 "may assume `cargo` exists", so
  built-ins sit outside `check-deps`' inventory by construction rather than by
  omission. And if a consumer did misapply the crates.io branch, the failure is a
  loud false MISSING, not the silent false pass finding F1 was about. No consumer
  faces two live readings that yield a wrong test.
- **Revision 4's three scoping edits are landed, not merely described.** I read
  both edited sentences at their locations rather than through the sweep table;
  `review/audit-codex.md` independently re-opened all eighteen rows at their
  cited locations and confirmed the same.
- **The unproven list's coverage is not at issue** — only item 1's final sentence
  is. The other nine items, including layer 4's zero occupants with `ubi`'s own
  maintainer quoted against it and item 7's classification of the licence gate as
  not researchable, are honest and complete.
