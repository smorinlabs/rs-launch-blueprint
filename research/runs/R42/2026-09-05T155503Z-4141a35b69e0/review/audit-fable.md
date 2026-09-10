decision-sha256: 189bb6e3ee4cd786ebfc9b677f780213733fd3a599821c993e17639818a4c677
actor: audit-fable-2026-09-05T155503Z-4141a35b69e0-r5
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Unchanged and still correct. I did not re-derive this section: `review/audit-fable.r1.md`
established it and `review/audit-fable.r4.md` re-verified it, and the revision-4
→ revision-5 diff (`git diff 1c9b403 27556ab -- …/review/DECISION.md`) touches
neither `### Principles and implementation` nor the architecture comparison. What
I checked myself is that the diff is confined to what it claims: the title line,
check 14's new row, the figure-table heading and column header, three licence
cells and the `rustup` RustSec cell, fitness gates 1 and 3, the revision-2
history sentence about unproven item 1, the revision-4/5 history block, and
unproven item 1. Nothing else in the file moved.

The shared requirement stands as stated — *one command reports exactly which dev
tools are missing with the exact remediation for each, and every repeatable task
then invokes those tools by a single stable name that does not depend on how they
were installed* — at agreement level **architectural pattern plus policy**, with
an explicit must-agree / may-vary split. The fitness test for carrying the
pattern into Rust is performed rather than asserted, on the structural argument
that py's four tools sat outside `uv`'s reach while their Rust analogues are
themselves crates. No `OVERRIDE` is owed, for the reasons r4 recorded.

## Design and evidence

**Repair 1 (r4 finding F1) — the one credit standard, verified against the
archived audits rather than against the decision's account of itself.**
`DECISION.md:775`–`:796` now states one rule ("a rerun discharges the checks it
names, whoever ran it") and applies it in both directions. I checked each
credit and each denial at its source:

- *Checks 2–8, credited to `review/audit-codex.r1.md` on Lima Ubuntu arm64.*
  `evidence/audit-dev-toolchain-provisioning.log` records the Linux rerun of the
  17-repository survey, the `cargo-demo` dispatch and its off-`PATH` negative
  control, the crates.io and GitHub queries, the RustSec probes and the four
  reference reads. Check 4 is credited in full and is present in full: the log
  carries `rustup show active-toolchain` (`:36`), `cargo fmt --version; cargo
  clippy --version` (`:39`), `rustup which cargo-fmt` (`:43`) and `rustup
  component list --installed` (`:47`).
- *Check 9's nine-command matrix, credited to `audit-codex.r2.md` and
  `audit-codex.r3.md`.* `…-r2.log:116`–`:135` records the Linux VM matrix over
  `1.97.1`/`stable`/`1.96.0-aarch64-unknown-linux-gnu` with lookups 0/0 in all
  three cells and component-state and `rustup which` at rustfmt `1/0/0`, clippy
  `1/0/1`. `…-r3.log:281`–`:383` records the same three cells command by command
  on the same VM.
- *Check 11's precedence probes, credited to `audit-codex.r3.md`.*
  `…-r3.log:384`–`:418` records, on Linux, `cargo myver` exit 0 against
  `command -v cargo-myver` exit 1, the alias-shadowing warning with the
  `rust-lang/cargo#10049` URL, the external-stub dispatch outside `alias/`, and
  the four built-in `command -v` probes exiting 1 against `cargo test --help`
  exit 0.
- *Checks 10 and 12 denied a Linux leg.* Confirmed by exclusion. `audit-codex.r3.md`
  ran check 10 in all four channel directories and check 12's bare-name negative
  case **on macOS only**; its Linux section contains neither. `…-r2.log`'s
  "Bare names, built-ins, and aliases" section sits after the Linux paragraph but
  is macOS — every path is `/Users/stevemorin/.cargo/bin` and every toolchain id
  is `-aarch64-apple-darwin`. So no archived audit runs either check on Linux,
  and the decision's "every rerun of those was on macOS" is exact.

The classification sentence is also right on its own terms: checks 3, 4, 9, 10,
11 and 12 execute local binaries and are host-dependent; 2, 5, 6, 7, 8, 13 and 14
are HTTP reads; check 1 records the host. The finding my predecessor raised is
closed, and closed by stating the record rather than by softening the claim.

**Repair 2 (r4 finding F2) — the two figures were probed, not re-attributed.**
This is the stronger of the two available repairs and it changed a fact. New
check 14 (`DECISION.md:355`) is backed by `evidence/rustup-figures.log`, which I
read: `rustsec.org/packages/rustup.html` → 404 with the `time` and `atty`
controls → 200, `GET https://crates.io/api/v1/crates/rustup` → `newest_version`
`0.0.0`, `max_stable_version` `None`, sole version `0.1.0` with `yanked: True`,
and GitHub `license.spdx_id` `Apache-2.0` for both `rust-lang/rustup` and
`rust-lang/cargo`. Every clause of the check-14 row is in that log. The probe
found something the re-attribution my predecessor offered would have missed: the
crates.io crate named `rustup` is a placeholder, so there is no registry licence
for the toolchain manager to quote at all, and the row now says so instead of
printing a dual value under a crates.io header.

The downstream sentences were narrowed to match. Gate 3 now reads "no RustSec
page for any of the six candidates that were probed" and names them —
`cargo-binstall`, `ubi`, `mise`, `just`, `cargo-run-bin` from check 7 and
`rustup` from check 14, which is exactly the five names in
`evidence/github-rustsec.log`'s check-7 block plus the new one — and says plainly
that `cargo-quickinstall` and `cargo-make` were not queried. Gate 1 no longer
prints `Apache-2.0 OR MIT` for `cargo install --locked`; it reports the one
`license.spdx_id` GitHub holds and attributes the dual reading to `raw/opus.md`
as unconfirmed. I checked the seven registry licence cells against
`evidence/crates-io.log`, which carries all seven under check 5:
`cargo-binstall` GPL-3.0-only, `cargo-quickinstall` and `ubi` MIT OR Apache-2.0,
`cargo-run-bin` and `mise` MIT, `just` CC0-1.0, `cargo-make` Apache-2.0. No
figure in the table is now credited to a check that did not produce it.

**The recommendation still follows from the evidence.** I did not re-derive it —
r1 and r4 did, and the revision-5 diff touches no premise of it. What I confirmed
is that the diff leaves the 0-of-17 survey, the structural argument that carries
the conclusion independently of the count, the rejection of `flake.nix` (the
best-adopted declarative option in the decision's own sample) on a
template-specific argument rather than on adoption, and the five architecture
alternatives untouched. Selection is not by engine agreement: three of five
engines recommended `mise` and are settled against by re-measurement.

**The licence question is still an owner ruling, and revision 5 strengthened
rather than weakened it.** `docs/port/PARAMETERS.md:10`'s gate 1 reads "candidate
**crates** must be compatible", `cargo-binstall` 1.23.0 is `GPL-3.0-only`
(`evidence/crates-io.log`, `2026-09-05T16:59:01.959145Z`), and it is executed as
a separate process linked into nothing the template ships — so whether the gate
reaches it is a reading of a fixed owner parameter, not an evidentiary question.
The decision records opus's mere-aggregation argument with its FSF citation and
explicitly declines to adopt it, recommends the backend clean under either
reading, states the reversal cost as one recipe line, names `cargo-quickinstall`
0.3.53 as the licence-clean prebuilt alternative, and lists the ruling as
unproven item 7 with "the owner rules" as its proof. That is a decision request
with the fact, both readings, the consequence and a default — the correct form,
and unchanged from revision 1 apart from gate 1 now naming its sources.

**Assertion strength, swept once more.** This is the defect family that consumed
four rounds, so I re-grepped the live text outside the eighteen-row sweep table
and the revision histories for absolutes (`cannot`, `never`, `always`, `provably`,
`guarantee`, `unconditional`, `any machine`, `wherever`). Every hit is either a
normative statement of what the template must do ("`command -v` is **never** the
test for a rustup component"; the presence test targets the underlying tool,
"never `cargo-<alias>`"), a statement about this decision's own work ("layer 4
has never been exercised"), a retrospective quotation, or the classified
process-isolation property at gate 3. The universals the r3 audit rejected are
absent from the live text. Revision 5 introduced one new absolute — see
`## Assessment`, where I record why it is not a finding.

## Completeness

I read `inputs/prompt.md` in full for this section rather than inheriting r4's
reading. The prompt's binding constraint is line 106, "Every claim carries a
source URL and retrieval date; every number carries its endpoint," and its
evidence table (`:52`–`:61`) fixes the endpoint and field for each figure,
including `total_count` for open issues rather than `open_issues_count`. The
figure table honours both; revision 5 closed the last two cells that did not.

Present and correct: the runbook's four H2s in order with
`### Principles and implementation` nested under `## Decision` (RUNBOOK `:181`–`:188`);
`re-verify: 2027-03-10` plus six named earlier trigger events; settled rows F183
(decided) and F187/F188/F189 (not adopted) with verdict strings left to the
controller; `owns package-manager-invocation` with a full value and four
`assumes` lines quoting the fixed registry values; an explicit statement that no
`CONFLICT:` line is owed, with the reason (`- consumes:` is empty in the prompt's
`## Couplings`, and no raw report raised one); toolchain, OS, UTC convention and a
working-directory paragraph enumerating every scratch file written outside the
repository; all six fitness gates answered, with `inapplicable` plus a reason
where inapplicable; maintenance state by the prompt's rubric with `at-risk`
resting on concrete signals rather than the six-month trigger alone. The one figure
the prompt's table asks for that this decision does not carry —
issue-responsiveness medians — is recorded as unproven item 10 with its proof
method, and is carried from `raw/opus.md` where cited, which is the honest form
for a research-only item, not an omission. The adopter row is satisfied in a
different form and legitimately so: the "Reference implementations" paragraph
(`DECISION.md:244`–`:262`) names `cargo-binstall`, `zed-industries/zed`,
`oxc-project/oxc` (22694 stars) and `biomejs/biome` (25753 stars) with what each
commits and the date each was read, in place of a reverse-dependency page, which
does not exist for a binary that nothing depends on as a library.

Both `BASELINE-REVIEW:` lines still carry the runbook's four fields
(`RUNBOOK.md:22`) plus an `Affected:` list, are responsive to what
`docs/port/BASELINE-REVIEW.md` asked of R42 for F179 and F181, and edit no
ledger row. The F190/F103 handling is still a coordination note rather than a
`CONFLICT:`, with `channel` left to R27.

**The owned parameter.** `docs/port/PARAMETERS.md:14` names six consumers — R27,
R28, R29, R32, R37 and R40. My predecessor walked all six and found the parameter
safe for each; I spot-checked the case it called awkward rather than assuming.
`topics/37-hook-manager-distribution/prompts/hook-manager-distribution.prompt.md:38`
asks in terms "how does the choice interact with `package-manager-invocation`
(R42)'s pick of how dev tools are invoked?", for a tool Cargo cannot install as a
crate dependency. The parameter answers it without a further ruling: axis (i)
gives lefthook a bare `<tool>` on `PATH` (it is not named `cargo-<sub>`), and
axis (ii) gives the *reason* for its split — "where the `PATH` entry *is* the
tool" — which classifies a release-installed binary as the `command -v` class
whatever channel R37 picks, with layer 4's `ubi` slot reserved for exactly that
residue. `topics/29-…:17` and `topics/28-…:20` likewise defer only the
invocation syntax, which the parameter states. I found no consumer facing two
live readings.

`review/audit-codex.md` (the r5 empirical audit, actor
`audit-codex-…-r5`) is consistent with the decision and honest about its scope:
it reran check 14's probes on macOS, disclosed the crates.io 403 and the
documented descriptive-User-Agent retry, started no Linux VM, installed nothing,
and independently walked the Linux-leg inventory against the archived audits to
the same conclusion I reached. Its extra query — the crates.io `versions`
endpoint, needed because "its only version is yanked" is a claim about the
version list — is a strengthening check, not a divergence.

**The unproven list is honest and complete after five rounds.** Ten items, each
naming what would prove it: the Linux gap now stated per check, proxy resolution
on a single-installation machine, the whole `check-deps` loop, the acquisition
backend end to end, the compile-time cost the licence-clean choice buys, layer 4's
zero occupants with `ubi`'s own maintainer quoted *against* it, the owner's
gate-1 reading classified as not researchable, R27's `channel`, the unenforced
prohibition, and the unmeasured issue-response medians. Item 1 was the last one
lagging the record and now leads the list in precision.

## Findings

None.

## Assessment

**Approve.** Both repairs land, and both were verified against the logs and the
archived audits rather than against the decision's account of itself. The
credit-standard repair states one rule and applies it in both directions, and
every credit and every denial in it matches what the audit logs contain. The
figure repair went past what I asked for as this decision's r4 judgment auditor:
instead of re-attributing two cells to `raw/opus.md`, it probed them, which
turned up the placeholder-crate fact and made the `rustup` row true rather than
merely sourced. Nothing else in the document moved, and the recommendation, the
owned parameter, the survey, the licence question, the presence-test matrix and
the eighteen-row sweep stand as r1 and r4 left them.

Three things I considered and am recording as **not** findings, so a sixth round
is not spawned on them:

1. *The figure table's heading says "the licence column names a source per row",
   but seven rows name no source in-cell.* Those seven are the crates.io rows,
   covered by the heading's own default ("each retrieved 2026-09-10 from the
   endpoint its column names") and by check 5's table row, and all seven values
   are in `evidence/crates-io.log`. Loose wording about the table's shape, not an
   unattributed figure — the defect class my r4 F2 was about does not recur.
2. *"checks 2, 5, 6, 7, 8, 13 and 14 are network reads whose results cannot
   depend on the runner's operating system"* is the one new absolute revision 5
   introduces. It is a classification of what an HTTP GET of a registry JSON
   document is, in the same category as sweep row 18's process-isolation claim,
   not a characterisation of recorded output; and the sentence immediately
   concedes that `audit-codex.r1.md` reran five of those on Linux anyway.
3. *The Linux legs on record are Lima Ubuntu **arm64**, not `ubuntu-latest`.* The
   decision names the VM and its architecture where it credits r1, never claims
   `ubuntu-latest` coverage for any check, and sends P03 to both runners in
   acceptance criterion (C) and in item 1's own proof line. Recording this as a
   gap would be re-listing a proof obligation the item already carries.

**The item is ready to publish.** Publication here means the controller may now
set the ledger verdict strings for F183, F187, F188 and F189, adjudicate the two
`BASELINE-REVIEW:` findings against F179 and F181, and write the
`package-manager-invocation` value into `docs/port/PARAMETERS.md`; this audit
does none of those and edits nothing. The decision remains a proposal for P03 to
validate, which is correct under the owner's research-only ruling, and its ten
unproven items are the validation list P03 inherits.

My actor id was not supplied in the task message; it follows this seat's
convention as `audit-fable-2026-09-05T155503Z-4141a35b69e0-r5`.
