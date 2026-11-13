decision-sha256: 14d3526106bb7e670fe648fe3bad9e858a92ddb196603fb49d9090bdc08fee4e
actor: audit-fable-2026-09-05T165440Z-d2e35904dc88-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

Reviewed as a fresh context that produced none of this item's raw reports, the
decision, or the empirical audit. Read: `inputs/prompt.md`, both raws
(`raw/codex-c1a5048b….md`, `raw/opus-c722a6a5….md`), `review/DECISION.md`,
`review/audit-codex.md`, `review/evidence/resolver-fallback-chain.log` (sha256
`ef7c1528c6b45a22b499e103a259eecd97de179cc42a1ec634016e4229f856f3`, matching the
value the decision records), `docs/port/PARAMETERS.md`, spec §2,
`research/RUNBOOK.md` §1/§4/§5, `docs/port/BASELINE-REVIEW.md` (F126 and F127 are
`DIVERGENT` rows and are correctly absent from that REUSE/ADOPT review), and the
ledger rows this item touches (`docs/port/COMMONALITY.md:132-133`,
`docs/port/DIVERGENCE-ANALYSIS.md:144-146`). No empirical work was re-run.

## Principle and agreement level

The shared principle is stated as one principle on two axes — upstream breakage
should be found by a run nobody is waiting on — and is sourced to both
repositories' own words at the programme pins (py@b08bccfb
`.github/workflows/canary.yml:1-11`; ts@cb1cbcb2 `.github/workflows/ci.yml:130-140`
plus D-036). The agreement level `capability/standard` is argued, not inherited:
the must-agree / may-vary table separates the two observable properties (a
configuration the merge gate does not exercise is exercised on a cadence; the lane
cannot block a merge) from the mechanism, which is exactly the spec §2 row for that
level. Placing "which axis of upstream change is covered" on the may-vary side is
what licenses the F127 re-mapping, and the decision tests the ported pattern in the
target ecosystem rather than assuming it survives: `cargo update` is shown to be
the faithful analogue of `uv sync --upgrade` (neither rewrites bounds), while the
beta channel is argued to be a *stronger* analogue than Bun for a different reason
than ts's — ts's lane is advisory because Bun trails the Node floor (a deficiency
argument), a beta failure is a dated prediction of a stable failure (a direction
argument), with the Rust project's own solicitation quoted and the live channel
manifests checked. No `OVERRIDE (OV-nn)` is required: F126 and F127 are `py-only`
and `ts-only` `DIVERGENT` rows, not a recorded shared pattern being displaced.

The two `BASELINE-REVIEW:` lines are handled as the runbook requires — reported in
the decision with feature ID, principle, proposed change, evidence and affected
items; no ledger, index or prompt edit made or proposed in this file, leaving
adjudication to the controller (RUNBOOK §4). The first is independently checked
here and is accurate at the width it claims: `DIVERGENCE-ANALYSIS.md:146` cites
`Justfile:169` and nothing else, and `COMMONALITY.md:133` carries no file evidence
at all — which the decision itself says, rather than repeating the Opus raw's
looser "both cite" phrasing. No `CONFLICT:` line is present in either raw, and the
decision correctly raises none: the item owns and consumes no registered parameter.

## Design and evidence

**Shaped by the executed finding, correctly.** The load-bearing chain is edition
2024 → resolver `"3"` → `resolver.incompatible-rust-versions` default `fallback` →
a newer in-bounds dependency version held back. It is verified twice over — in
Cargo's own shipped documentation and in a live resolution — and the recommendation
is shaped by it rather than merely footnoting it: the override appears in the
recommendation table's `latest-deps` freshness-step cell, in the bolded paragraph
that follows, in `## Parameters` as the reason `rust-edition` is the load-bearing
parameter, and in the acceptance criteria as a check P03 can run. That is where an
implementer copying the workflow will see it. The `next-toolchain` leg correctly
carries no override because `--locked` means it performs no resolution.

**The narrowing is right, not over-cautious.** The Opus raw's "turns the entire
lane into a no-op that looks green" is wider than its own evidence; the decision
rejects that wording explicitly in Disagreement 1 and replaces it with a scoped
claim plus three limits from the same run: the lane is not inert (9 packages
locked, 1 held back); the holdback is printed in the log but produces no pass/fail
difference, so it survives any review that reads only the job result; and the
affected class is bounded by edition 2024's own 1.85 floor yet is "exactly where
the fastest-moving crates sit — which is why the override is required rather than
optional". The hazard is preserved with its reason, so the narrowing does not
understate it. The fixture's narrowness (one workspace, one member, one registry
dependency) is stated by the decision itself rather than glossed.

**The consolidation is argued.** One weekly non-gating workflow is chosen over two
mechanisms against the Cargo Book's four-architecture list, each architecture
carried with the Book's own stated cost, the rejections reasoned from this
repository being a template (architecture B's per-pull-request cost is inherited by
every fork, to compress detection latency on an axis whose train is six weeks), and
architecture B recorded as the ranked runner-up with the one real advantage it
keeps — immunity to the 60-day auto-disable — plus the condition under which the
owner should switch. The "two rows, one capability on two axes" claim carries four
pieces of evidence, not assertion: the two source headers stating the same
principle at their pins, all six surveyed projects expressing the toolchain axis as
matrix legs of an existing workflow, py's canary already carrying a matrix, and the
consequent marginal cost of the beta leg (one weekly Ubuntu job on a schedule that
already exists) which answers the ledger's standalone cost question. The survey
evidence supports "a leg, not a separate mechanism" more directly than it supports
schedule-versus-push, but the decision does not lean on it for that: the
architecture choice is settled separately in Disagreement 3, on the template
argument, and the closest single reference (`dtolnay/anyhow`) is described as
"missing only the freshness step" rather than as a full precedent.

**Alternatives and selection follow principles and evidence, not popularity.**
`cargo-edit` is excluded on fitness with an executed reason (`cargo update
--breaking` is nightly-only, exit 101) and kept as a documented runner-up;
`nightly` is rejected on observed noise mitigations in rustls rather than on the
stable-only constraint, which is the honest ground; `actions-rs/toolchain` is
excluded on `archived: true`; the choice between the raws' two freshness commands
is settled by executed behavior (`--workspace` refreshed no registry dependency on
the probe) rather than by preference. Guardrails that neither source implements
(`timeout-minutes`, failure routing) are added with py's gaps verified at the pin
(`grep -c 'timeout-minutes'` → 0, `grep -ci 'issue'` → 0) rather than assumed.

**Confidence is proportionate.** The absence of a four-member adopter is stated as
the decision's own synthesis and recorded as an evidence gap with the separately
evidenced pairs that do exist; the absence of any wall-clock or runner-minute
figure is stated with its cause (no template exists to measure) and the only
anchors available; the cadence is labelled a calibration at medium confidence
against four of six surveyed projects running daily; the issue-filing member is
held at medium-high with Codex's objection carried rather than dismissed and a
five-item P03 validation list; `clap`'s guard is cited for the idiom only; and the
absent Rust survey figure is reported as absent rather than invented. Each gap
names what would prove it. Per the P02 research contract and the owner ruling this
decision records, building the workflow is P03's work, and declining to build it is
not a deficiency.

## Completeness

Every required `DECISION.md` H2 is present and populated (RUNBOOK §5): `## Decision`
with the recommendation, the settled `F126`/`F127` rows, `### Principles and
implementation`, and a `re-verify` line with dated and event triggers;
`## Parameters`; `## Empirical check` with toolchain, OS, commands, working
directory and observed output; `## Engines` with both raws named by sha256, six
disagreements each with the evidence that resolved it, the figure-divergence note,
and six carried gaps. `## Supersedes` is correctly absent — this is revision 1, not
a reversal. Owned parameters: none, matching the prompt's empty `- owns:` line.
The four assumed values are quoted and match `docs/port/PARAMETERS.md` byte for
byte (independently re-read here, rows `msrv-policy`, `rust-edition`,
`target-os-matrix`, `license`), and each is given its bearing on the design rather
than merely listed. Fitness gates are `inapplicable` in the crate sense and the
decision says why (no member adds a crate to the dependency tree), while recording
`cargo-edit`'s compatible licence for the unadopted runner-up; the per-gate
enumeration lives in both raws, which are cited by sha256. Source dates are carried
per-raw and deliberately not homogenized, and the decision says so at the top.

The empirical audit is consistent with the decision: it reproduced the resolver
split and the selection of `icu_locale_core` 2.1.1 versus 2.3.0, confirmed the
narrowing by lockfile diff (only that package differs), reproduced both runner-up
command checks, verified the pinned TypeScript lines and the four assumed parameter
values, and returned approve with no findings. Its documented fallback from the
Lima VM to macOS is stated with the failure reason and does not affect what the
probe establishes.

## Findings

None unresolved. Three non-blocking observations for the controller, none of which
changes the recommendation or requires a new revision:

1. **Precision of one sentence.** The bolded headline sentence says an
   un-overridden run "re-tests the same graph the gating build already has". "Graph"
   is a whole-resolution word, while the evidence is that 8 of 9 packages moved.
   Limit 1 corrects this two lines later, so the decision is not wrong when read
   whole — but this is the sentence most likely to be quoted alone. Tightening it to
   "the same versions of those dependencies" would carry the narrowing into it.
2. **The executed chain was a package manifest, not a virtual workspace.** The
   fixture is a single package. This template is CLI + library + web service and
   will very likely have a virtual workspace root, where the Cargo reference states
   that `edition` "will have no effect on a resolver used in the workspace" and
   "`resolver` must be set explicitly in virtual workspaces as they have no
   package" (`reference/workspaces.html` and `reference/resolver.html` of the
   toolchain-installed book, read 2026-09-11). The decision's general sentence
   "Under `edition = "2024"` Cargo selects resolver version `"3"`" therefore holds
   for the package case it executed, not automatically for the workspace shape P03
   will build. The recommendation is unaffected — the override is required under
   resolver 3 and harmless under any other — so this is a precision note for P03
   (declare `resolver = "3"` in the virtual root, or the resolver premise silently
   differs from the one tested here), not a defect in the recommendation.
3. **Two presentation nits.** The second baseline-review line is keyed
   `F126 + F127`, where the runbook's recorded form is one `F###` per line; a
   controller tool matching a single ID will see only `F126`. And the recommendation
   announces "an explicit `matrix.include` of three legs" above a two-row table
   whose first row expands to two runners — the count is consistent (2 + 1), but the
   table's rows are lanes while the prose counts legs.

## Assessment

Approve. The decision states the shared principle at a defended agreement level,
tests the ported pattern in Rust rather than assuming it survives, compares the
architectures on a first-party list with each option's own stated cost before any
tool is named, and selects on principle and executed evidence rather than on
repository agreement or popularity. Its central finding is executed rather than
read, and the recommendation is shaped by it at the point an implementer will act:
the override appears in the recommendation itself, not only in the analysis. The
decision narrowed its strongest inherited claim to what the run supports while
keeping the hazard — and the reason the hazard matters — intact, which is the
harder of the two failure modes to avoid. Unproven claims are recorded as unproven
with what would prove them, and nothing was implemented: no workflow written,
nothing scheduled, no issue opened. Fit to publish as revision 1.
