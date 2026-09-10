decision-sha256: ca5a731081e51ab5d0eea91dd9f4ef8a456855df026354ed1f8146bea77f6d7f
actor: audit-fable-2026-09-05T155503Z-4141a35b69e0-r6
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Unchanged from revision 5 and still correct, and I established that mechanically
rather than by re-derivation. `git diff 27556ab 2b8e2ce -- …/review/DECISION.md`
touches exactly five regions: the title's revision label, the five declaration
lines in `## Parameters`, three new paragraphs immediately after that list, and
two additions to the revision history (the revision-5 approval record and the
revision-6 entry). `### Principles and implementation`, the architecture
comparison, the five answers, the fourteen checks, the figure table, the fitness
gates, the six disagreements and the ten unproven items are byte-identical to the
text both revision-5 audits approved. That revision-5 text hashes to
`189bb6e3ee4cd786ebfc9b677f780213733fd3a599821c993e17639818a4c677`, which I
computed from the committed blob and which is the hash carried in the header of
the revision-5 judgment audit this file replaces.

So the shared requirement stands as stated — *one command reports exactly which
dev tools are missing with the exact remediation for each, and every repeatable
task then invokes those tools by a single stable name that does not depend on how
they were installed* — at agreement level **architectural pattern plus policy**,
with the must-agree / may-vary split intact and no `OVERRIDE` owed.

## Design and evidence

**Why the raw reports were not re-read.** The role contract has me read every
raw report; the owner narrowed this seat on 2026-09-10 to the packaging
correction. I checked that the narrowing is sound rather than assuming it:
`git diff --stat 27556ab HEAD -- …/raw …/inputs …/review/evidence` reports two
added files and nothing else — `evidence/audit-dev-toolchain-provisioning-r5.log`
and `…-r6.log`, the two audits' own logs. No raw report, no `inputs/prompt.md`,
and no evidence log the decision cites has changed since the revision-5 pair
approved them. Revision 6 also reran no check and cites no new evidence, so there
is no new claim for a raw report to support.

**(1) The five declaration lines, compared character by character with
`docs/port/PARAMETERS.md`.** I parsed the registry table the way
`scripts/research_package.py` does — split the row on `|`, strip each cell, take
the `value` column — and compared with the text the declaration regex
`^- (owns|assumes)\s+([a-z0-9-]+)\s*=\s*(.+?)\s*$` extracts from the decision:

| line | registry cell | comparison |
|---|---|---|
| `- assumes msrv-policy` | `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` | equal |
| `- assumes rust-edition` | `2024` | equal |
| `- assumes target-os-matrix` | `ubuntu-latest, macos-latest` | equal |
| `- assumes license` | `MIT OR Apache-2.0` | equal |
| `- owns package-manager-invocation` | `—` (unpublished placeholder) | not comparable before publication; projection checked below |

All four fixed values are byte-equal, not merely equivalent: no backticks, no
citation, no trailing commentary, no trailing whitespace, and no non-ASCII
character in any of the five lines. Exactly five lines in the whole file match
the declaration regex, all inside `## Parameters`, and that section contains no
code fence, so `_outside_fences` in `scripts/research_validation.py` sees all
five and nothing else. The three new paragraphs sit in the same section and start
with prose, so none of them is parsed as a declaration.

The owned line cannot be compared with the registry before publication, because
the registry still carries the `—` placeholder every unpublished `researched` row
carries. What I checked instead is the projection that publication performs. I
applied `publish_values` (`scripts/research_package.py:182`–`:206`) in memory:
its three guards pass (`"|" not in value`, non-empty, not `—`), the projected row
still has five cells, and re-parsing the projected registry the way
`scripts/research_validation.py:766` re-parses it returns the declaration
byte-for-byte. The published cell and the decision line will therefore agree
under the post-publication validator, which is the check that would otherwise
fail later.

**Is the owned value a rule rather than an argument?** Yes. It is 667 characters,
one sentence, containing no backtick, asterisk, underscore, bracket, pipe or
citation, and it states only what a consuming item must do. The revision-5 line
it replaces was a multi-paragraph argument carrying bold, backticks, an alias
rationale, a `check 11` citation and a scope disclaimer — none of which a registry
cell can hold, and all of which now sits in prose. The value is imperative
throughout: what to invoke as `cargo <sub>`, what to invoke bare, what to write
unchanged, what never to write, and how to test presence in each of the two
acquisition channels.

**(2) Nothing substantive was lost in the move.** I extracted the whole
`## Parameters` section from the committed revision 5 and from revision 6 and
compared their token multisets after stripping markdown emphasis. Nothing at all
is gained or lost except these fourteen tokens, every one of which I traced to
its rewrite:

- `docs/port/PARAMETERS.md` ×4 and `fixed` ×2 — the four `(fixed,
  docs/port/PARAMETERS.md)` citations on the `- assumes` lines. Deliberately
  dropped; they are the defect. The path appears once in the new format note, and
  the registry itself is the definitional source for a value the line must now
  equal exactly.
- `Every`/`runs` → "means every recommended component must run on both runners";
  `Gate` → "fitness gate 1"; `How` → the axis heading; `Used`/`here` → "is used
  only to establish"; `differently` → `differently.`; `required.` → `required`
  followed by the new gate-4 clause; `listed`/`unproven.` → "is unproven item 7".
  Each is a rephrase in place, and three of them are strictly more precise than
  the text they replace (the licence pointer now names item 7 by number, and the
  target-matrix note now records that the OS question was verified on macOS/arm64
  only).
- `restated` → `stated`, in "the argument is stated to match". One word inside
  the moved alias rationale; the sentence's meaning is unchanged.

The two notes the task names both survive, and I read them at their new
locations. **`docs/port/PARAMETERS.md` target matrix**: "`target-os-matrix` means
every recommended component must run on both runners, which each does; **Windows
support is noted where it exists and is not required**, and gate 4 records that
this decision verified the OS question on macOS/arm64 only." **Licence gate
pointer**: "`license` is applied as fitness gate 1 to every candidate; the
`cargo-binstall` finding is recorded in `## Decision` as a finding rather than a
ruling, and **the owner ruling it needs — whether gate 1 reaches separate-process
developer tools — is unproven item 7**." Sweep rows 1, 2 and 5 of the revision-3
table cite `## Parameters` as the location of the phrases they adjudicate; those
phrases moved within that section, not out of it, and I re-read all three at
their new coordinates — they read as the table says.

**(3) The rest of the decision is unchanged from revision 5.** Established by the
diff above rather than by the decision's account of itself. The two history
additions are accurate: revision 5 was approved by both audits with no findings,
and the revision-6 entry describes the edit that the diff shows.

**(4) Is the owned parameter safe for its six consumers?** The registry cell will
carry text those six items have never seen, so I re-derived this against the new
value rather than relying on the revision-4 walk, which was against different
text. The property most at risk in compressing an argument to a rule is the
independence of the two axes, and it survives, because each axis names its own
key: invocation is keyed on the executable's **name**, presence on how the tool
was **acquired**. The case that would break a merged rule is a rustup component
whose executable is not named `cargo-<sub>` — `rustfmt` or `rust-analyzer`
invoked bare. Under the bare value, axis (i) sends it to "a bare executable
resolved on PATH", because its name is not `cargo-<sub>`; axis (ii) sends it to
"the active toolchain's component state via rustup component list --installed for
a tool rustup installs, never command -v for a rustup component". Both clauses
fire independently and give the right answer, which is exactly the failure check
12 recorded (`command -v rustfmt rust-analyzer` exit 0 in `neg/` while both
`--version` calls exit 1). Spot-checking the six by their likely picks: R27
(`cargo fmt` as a component, `taplo` bare from crates.io), R28 (`cargo clippy`,
and "define no Cargo alias in the template" answers the `cargo lint` question
that was finding F3 of the first round), R29 (`yamlfmt`/`taplo` bare), R32
(`cargo test` under "write Cargo's own built-in subcommands as they are", `cargo
nextest` under the `cargo-<sub>` rule), R37 (lefthook, a release-acquired bare
binary, and the value names lefthook jobs explicitly), R40 (`gitleaks`,
`actionlint` bare). Every one is answered on both axes by the bare value alone,
with no recourse to the prose.

What the bare value does **not** carry, and should not: the remediation strings
(`just install-tool <name>@<version>`, `rustup component add <component>`), which
belong to F181 and the acceptance criteria; the alias carve-out for a **consuming
repository**, which is scoped by "in the template" and does not reach the six
consuming research items, all of which are template items; and the evidence and
scope disclaimers, which are now prose. None of the six needs any of it to apply
the rule.

## Completeness

Every required field is present and correct after the edit. The `## Parameters`
section declares one `owns` line for the item's single owned parameter and four
`- assumes` lines for exactly the four `fixed` registry rows, which is the set
`research_validation.py` expects. The explicit "No `CONFLICT:` line" statement,
its justification and both `BASELINE-REVIEW:` lines are untouched and remain in
the runbook's four-field form. `re-verify: 2027-03-10` and its six earlier events
are untouched. The status paragraph still opens the decision, still says P02 is
research only and that P03 builds and proves the template, and still disclaims
owner acceptance. The ten unproven items stand unedited, item 7 among them, which
is what the licence prose now points at by number.

The empirical audit of this revision (`review/audit-codex.md`, actor
`audit-codex-2026-09-05T155503Z-4141a35b69e0-r6`, gpt-5.6-terra, openai) approves
with no findings and is consistent with the decision: it reran no check because
revision 6 records none, it reports the four fixed comparisons and the owned-value
projection I reproduced independently above, and it reaches the same revision-5
hash. Nothing in it conflicts with anything I found.

## Findings

None.

Two things were checked and deliberately not raised, recorded here so the next
seat need not re-litigate them.

**(a) "Every word those five lines previously carried is preserved in prose".**
Read literally this is slightly wide: the four `(fixed,
docs/port/PARAMETERS.md)` citations are gone, and one word changed
(`restated` → `stated`). It is not a finding, for two reasons. The format note
two paragraphs earlier states plainly that the lines now carry "no backticks, no
citation, no commentary", so the same section says what was removed and why; and
its companion claim — "Everything those lines used to say is below, unchanged in
substance" — is accurate, which my token comparison confirms. This programme's
three earlier rejections were for absolute characterisations of *recorded
evidence*; this is editorial self-description, disambiguated in place, with no
information lost that the registry does not already carry.

**(b) The owned value's `<sub>`, `<executable>` and `<tool>` placeholders enter a
markdown table cell unquoted.** The `http-transport-injection-seam` row already
carries `Arc<T>` and `ProjectsService<P: ProjectsPort>` the same way, so this
matches established registry practice; the value contains no `|`, which is the
character that would actually break the row.

## Assessment

Approve. Revision 6 does exactly what it says and nothing else, and it fixes a
defect that would have blocked publication for a reason no research audit
examines. The four fixed values are byte-equal to the registry, the owned value
is a single bare imperative rule that projects into the registry and round-trips
back byte-for-byte, both load-bearing notes survive the move at their new
locations with two of them sharpened, and the token comparison shows the moved
prose lost nothing else.

**The decision is ready to publish, and the owned parameter is safe for its six
consumers to apply.** Five substantive revisions preceded this one and every
finding raised across them is closed against the current text: the presence-test
class rule (round 1, F1) is live in both the `BASELINE-REVIEW: F181` line and the
owned value's second clause; the omitted disagreement (F2) is disagreement 6; the
alias silence (F3) is answered in the value itself and in the prose; the
shadowing wording, the unlanded sweep rows, the audit-credit standard and the two
unattributed figures are all closed in revisions 3 through 5 and unedited here.

**One publication prerequisite is outstanding, and it is the controller's, not a
defect in the decision.** `review/identities.json` still records the revision-5
identities: `audits.empirical.actor` reads
`audit-codex-2026-09-05T155503Z-4141a35b69e0-r5` and `audits.judgment.actor` reads
`audit-fable-2026-09-05T155503Z-4141a35b69e0-r5`, while the two audit files at
those recorded paths now carry the `-r6` actors.
`scripts/research_package.py:297`–`:299` requires the `actor`, `model` and
`family` fields of each audit file to equal the recorded identity, so packaging
will refuse the bundle with "empirical audit records actor … not the recorded
identity" until both are refreshed. The `model` and `family` values already agree
in both cases, and the judgment identity's model — `claude-opus-5` — is mine, so
only the two actor strings need to change. `synthesis.actor` likewise still reads
`synth-opus-…-r5`; that one blocks nothing, but it misattributes the revision-6
synthesis. I did not edit that file: it is not mine to write, and any edit to it
does not unbind these audits, so it can be corrected without another round. This
is the same class of mechanical, publication-only defect that cost the revision-6
round, which is why it is flagged here rather than left to the packager.
