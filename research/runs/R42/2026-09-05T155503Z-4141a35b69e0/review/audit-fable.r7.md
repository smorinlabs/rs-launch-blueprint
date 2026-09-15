decision-sha256: fd09fa1c682c049be39bfb841c0a57b1c6fff557ce5a16f0ba828dc4ceecabd1
actor: audit-fable-2026-09-05T155503Z-4141a35b69e0-r7
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: J1 — fitness gate 5's answer was deleted by this revision, leaving the gate unanswered and the sentence ungrammatical, and the revision's own "exhaustive" twenty-one-location edit list does not name it; J2 — fitness gate 3 still credits `--locked` with narrowing the recommended backend's supply-chain risk, which check 15 limits to the compile fallback, and the prebuilt path's integrity posture is neither examined, nor recorded as unproven, nor put to the owner

## Principle and agreement level

The shared requirement is stated at the right level and is unchanged from
revision 6: *a contributor runs one command, learns exactly which development
tools are missing, receives the exact command that installs each one, and every
repeatable task then invokes those tools by a single stable name that does not
depend on how they were installed.* The agreement level is named as
**architectural pattern plus policy** — a discover-report-remediate loop and a
stable invocation vocabulary — and explicitly not a capability and not a specific
tool. What must agree (one presence-check command; one remediation string per
missing tool; one invocation form per tool class; exactly one authoritative
location for the declared tool set) is separated from what may vary (the
acquisition backend, the number of tools, which tools are chosen, whether the
residue slot is ever occupied).

That separation is load-bearing for this revision and it holds. The backend is
named in the "may vary" list, so substituting `cargo binstall` for
`cargo install` is a change inside the space the principle already permits. The
owned parameter is **obeyed rather than amended**: `cargo-binstall`'s executable
is named `cargo-binstall`, so the parameter's own `cargo-<sub>` → `cargo <sub>`
rule invokes it as `cargo binstall` with no new rule, and its presence test is
the crates.io-class `command -v cargo-binstall` the parameter already prescribes.
I verified the parameter's value is byte-identical to the live registry (below),
so the claim that the substitution needed no parameter change is true rather than
asserted.

The native-design justification survives the ruling intact and is argued
structurally, not by preference: py's per-tool installer layer exists because
`uv` installs Python distributions and cannot reach `taplo`, `gitleaks`,
`actionlint` or `yamlfmt`, whereas the Rust equivalents are themselves crates and
rustup reaches `rustfmt` and `clippy` by definition. The per-tool layer is
therefore dropped for a stated mechanical reason rather than because ts dropped
it. Recording fitness gate 1 as struck under the owner's Q7.B ruling is correct
and I raise no finding on it; the repository's own `license = MIT OR Apache-2.0`
is correctly described as unaffected in reach-versus-value terms.

## Design and evidence

**Architecture alternatives were genuinely compared, and the comparison is
licence-independent.** Five architectures are tabulated with grounds. The
hermetic-environment row is the test of whether the ruling was allowed to
rewrite conclusions it does not reach: `flox`'s GPL-2.0 is correctly demoted from
a ground to a recorded figure, and the row's two surviving grounds — a Nix
installation imposed on every downstream consumer, and an environment prefix on
every recipe and hook line — are both independent of any licence and were already
the load-bearing ones. That is the right handling. The provisioner rejection
rests on a re-measured survey (0 of 17 carrying `mise.toml`/`.mise.toml`/
`.tool-versions`/`.flox`, 5 of 17 carrying `flake.nix`, 9 of 17 carrying
`rust-toolchain.toml`), not on repository agreement — and the decision explicitly
records that three of five engines wanted `mise` and were overruled by
measurement, quoting openai's own concession against its own position.

**The three corrections this audit was asked to press hardest on.** I judge two
of the three fully honest and the third honest in `## Decision` but unpropagated.

1. **`--locked` binds only the `cargo install` fallback.** Stated correctly and
   without hedging in three places: layer 2's table row ("downloads a prebuilt
   artifact where one exists for the target and otherwise runs
   `cargo install --locked` itself"), the dedicated bullet quoting
   `args.rs:346-350` verbatim, and unproven item 4 ("the `--locked` pass-through
   to the compile fallback"). The mechanical claim is quoted from source at an
   immutable tag and the fallback was observed, not inferred. **But one passage
   does still credit `--locked` beyond its reach — fitness gate 3 — and that is
   finding J2.**
2. **`cargo-binstall` must itself join the tool table.** Owned, not
   re-described. The decision writes "The one-line half is too narrow, in three
   respects", layer 2's row carries the reason inline ("`cargo-binstall` is
   itself a declared tool, because `cargo binstall` needs it on `PATH` where
   `cargo install` needs nothing"), the revision-history entry says the check
   "surfaced a cost the 'one line' phrasing hid", and the `## Supersedes` block
   lists it as one of the reversals. It also declines to decide how P03
   bootstraps it, which is correct for a research phase, and cites `biomejs/biome`
   as a maintained project with exactly that shape. No softening.
3. **Prebuilt availability is per tool and per target.** Scoped exactly to what
   was observed and no wider. `cargo-shear@1.13.1` resolving an artifact and
   `taplo-cli@0.10.0` falling through to source on the same target are both
   quoted from the run, the benefit is stated as "an upper bound each selected
   tool either earns or does not", the worst case is named as revision 6's
   recommendation exactly, and "**How large the saving is was not measured**" is
   stated in bold with unproven item 5 asking for the measurement. A reader does
   understand that some tools will compile from source. This is the strongest
   part of the revision.

**Does the recommendation still follow?** Conditionally — and the condition is
finding J2. The licence ground for preferring the slower first-party backend is
genuinely gone, the owner's ruling is wider than the condition revision 6 named,
and the substitution is therefore authorised. What does not follow as written is
the recommendation's *integrity* posture. Revision 6's backend was
`cargo install --locked` against the crates.io registry, where `--locked` pinned
the transitive graph and the registry supplied the trust anchor; revision 7's fast
path fetches a release artifact from GitHub, and the decision's own check 15
establishes that `--locked` reaches none of that. The decision states that
mechanical fact in `## Decision` and then never carries it to the one place where
the consequence bites. `evidence/binstall-backend.log:176-179` — the only prebuilt
resolution the run captured — prints `WARN The package cargo-shear v1.13.1
(aarch64-apple-darwin) has been downloaded from github.com` and nothing else: no
signature, checksum or verification line. So what secures the fast path is not
merely unstated, it is **unexamined**, and the decision contains no occurrence of
"trust", no mention of a GitHub release artifact's verification, and no unproven
item asking for it. The owner ruled on licence; the owner was not asked to accept
a different integrity posture, and this decision absorbs that tradeoff silently.
The recommendation follows once gate 3 is rewritten to scope `--locked` to the
compile fallback and the prebuilt path's integrity is either examined and cited or
recorded as unproven with what would prove it.

**Claims are matched to their evidence elsewhere.** The decision does not
implement its own recommendation and is not faulted for declining to: "**This
example was not built**", "Nothing recommended was implemented", and check 15's
own scope statement ("That verifies the command and its flags; it does not build
the `install-tool` recipe, the tool table or anything else") are all explicit. Ten
unproven items each name what would prove them. Prescriptions are repeatedly
stated at the strength of their evidence — the `command -v` failure for rustup
components is prescribed "for this template on the strength of that recorded
failure, not asserted as a property every rustup installation has", and the alias
shadowing is demoted to "the third and lesser reason" because Cargo warns rather
than failing silently. Host dependence is enumerated line by line in the evidence
log's rerun rule. The UTC-versus-local date question raised by a
`2026-09-13T06:50Z` stamp on a decision dated 2026-09-12 is explained in the text
and is not a defect.

**The audit-codex rerun is consistent with the decision.** Round 7 (family
openai) approved with no findings, replayed check 15 with only `CARGO_HOME`
redirected, and independently confirms all three corrections. Its one divergent
branch — `cargo-machete` resolving instead of short-circuiting — is exactly the
host-state difference the decision's rerun rule declares in advance. Its remark
that the live owned-value cell is a `—` placeholder describes the frozen
`inputs/PARAMETERS.md`; I compared against live `docs/port/PARAMETERS.md` instead
and all five lines match byte for byte, so the two audits do not actually
disagree.

## Completeness

Verified by diff and byte-comparison rather than accepted:

- **`## Supersedes` payload.** Extracted everything after "The complete
  revision-6 entry follows, preserved verbatim." and hashed it:
  `ca5a731081e51ab5d0eea91dd9f4ef8a456855df026354ed1f8146bea77f6d7f`, identical to
  `research/topics/42-dev-toolchain-provisioning/DECISION.md`. **Byte-identical,
  confirmed.** The H2 itself is spec-permitted for reversals (spec lines 475 and
  516). It sits last, and `re-verify:` remains the final line of `## Decision`.
- **Owned parameter and all four `- assumes` lines.** Parsed each and compared to
  the live registry table in `docs/port/PARAMETERS.md`:
  `package-manager-invocation` (667 chars), `msrv-policy` (118),
  `rust-edition` (4), `target-os-matrix` (27), `license` (17) — **all five
  MATCH byte for byte.** The format note explaining revision 5's backtick refusal
  is accurate and the lines carry a value and nothing else.
- **Acceptance criteria (A)–(E).** Extracted from both revisions and compared:
  1177 bytes each, **identical**. Each is backend-agnostic; none names an
  installer, so the substitution genuinely leaves them untouched.
- **Fitness gates.** Gate 1 struck with the ruling and its reason — correct, not
  a finding. Gates 2, 4 and 6 answered and correctly rescoped for the two-path
  backend. Gate 3 answered but **overstated** — finding J2. Gate 5 **unanswered**
  — finding J1.
- **`BASELINE-REVIEW:` lines.** Two, both well-formed with feature ID, principle,
  proposed change, evidence and `Affected:` — F181 (retain `just check-deps`,
  test presence by acquisition channel) and F179 (retain the two-layer split,
  record `make` as a consistency choice with a measured cost). Neither silently
  changes another item or the ledger.
- **`CONFLICT:` lines.** None owed and the absence is justified: `- consumes:` is
  empty, no raw report raised one, and the R27 `channel` overlap is correctly
  recorded as a coordination note rather than a conflict.
- **Source dates.** Every figure carries its endpoint and retrieval date;
  revision 7's re-query is dated and attributed to check 15.
- **Privacy check.** Check 15's User-Agent is
  `rs-launch-blueprint-research (+https://github.com/smorinlabs/rs-launch-blueprint)` —
  repository URL only, no personal contact address, as the log states at
  `binstall-backend.log:13-14`. I scanned every file in the run directory for
  email-shaped strings: **no new evidence artifact contains a personal address**,
  and the only occurrence anywhere in the run is a `git log` author line inside
  the frozen `review/audit-codex-r6-transcript.txt`. See observation O1 — the
  decision makes no disclosure about that residue, and none is required of it.

## Findings

**J1 — fitness gate 5 is no longer answered, and the revision's own exhaustive
edit list does not account for the change.** At line 611 the decision reads:

> Gate 5 (default features, async coupling with R05's execution model can occur.

The preserved revision-6 bytes at line 1698 read:

> Gate 5 (default features, async coupling): **inapplicable** — nothing is
> linked, so no feature unification or coupling with R05's execution model can
> occur.

A word-level diff of the fitness-gate paragraph shows a bare DELETE of
`coupling): **inapplicable** — nothing is linked, so no feature unification or`
with nothing inserted in its place. The verdict, the reason and the closing
parenthesis are all gone. This is a revision-7 regression, not a pre-existing
defect: the published revision 6 carries the complete sentence. The prompt's
tier-execution guidance is explicit — "Apply every fitness gate above. If a
metric is inapplicable to this item kind, state `inapplicable` and the reason in
the answer; **do not omit it silently**" — and the decision now does exactly
that. The second half of the finding is worse than the typo: the revision-history
entry asserts "**Twenty-one locations** make up this revision, and this list is
exhaustive", naming "(14) fitness gates 1 and 2" and "(15) fitness gate 6" as the
only gate edits. Gate 5 also changed. The decision's own bytes falsify its own
completeness claim, which is the kind of assertion a reader is invited to rely on
when checking that a reversal stayed inside its authorised scope. Fix: restore
gate 5's `inapplicable` verdict and its reason, and correct the edit list to
account for every location that in fact moved.

**J2 — fitness gate 3 still credits `--locked` with an integrity contribution the
revision's own check refutes, and the prebuilt path's integrity posture is
unexamined, unrecorded and never put to the owner.** Gate 3 reads, carried
forward from revision 6 untouched:

> the residual risk is supply-chain, which the pinned `name@version` spec and
> `--locked` narrow but do not eliminate.

That sentence was true when the recipe body was `cargo install --locked`. Under
revision 7's body it is overstated, and the decision itself is what establishes
this: check 15 reads `args.rs:346-350` at tag `v1.23.0` and concludes `--locked`
"constrains the **compile fallback** and says nothing about a prebuilt download,
which resolves no lockfile at all." The prebuilt download is the path the entire
substitution exists to reach. So the one place in the decision where `--locked` is
credited with a *security* property is the one place the correction did not
propagate — and it sits between two clauses the revision claims it did edit
(locations 14 and 15 are gates 1, 2 and 6). This is a claim asserted beyond what
the evidence shows, not a claim recorded as unproven.

The gap behind the sentence is the substantive half. `evidence/binstall-backend.log:176-179`
captures the run's only prebuilt resolution and prints
`WARN The package cargo-shear v1.13.1 (aarch64-apple-darwin) has been downloaded
from github.com` followed by `Dry-run: Not proceeding to install fetched
binaries` — no signature, checksum or verification output of any kind. Nothing in
this decision examines what `cargo-binstall` verifies before placing a GitHub
release artifact on a contributor's `PATH`; the words "trust" and "signature" do
not appear in revision 7 at all, and no unproven item asks for it. Revision 6
called `cargo install --locked` "the price paid for the licence-clean backend";
revision 7 deletes that clause and books the benefit without booking the cost.
The owner's ruling of 2026-09-12 covers licence and nothing else, so the weaker
integrity guarantee on the fast path is a tradeoff the owner has not been asked
to accept. Fix, in three parts: rewrite gate 3 to scope `--locked` to the compile
fallback and say what does and does not narrow the prebuilt path; either cite what
`cargo-binstall` 1.23.0 verifies for a release artifact or add an unproven item
naming that as unexamined with what would prove it; and surface the integrity
delta as an owner decision rather than absorbing it, since the ruling that
authorised the substitution did not reach it.

## Assessment

**Reject**, on two findings, neither of which touches the research, the
architecture comparison or the owner's ruling.

This is a careful revision and it is candid about the things it was most tempted
to soften. All three of the corrections that contradict revision 6's own
prediction are made in the open: the "one line" claim is retracted in terms and
the reason named, the per-tool/per-target scoping is stated as a bound rather than
a benefit with both observed outcomes quoted, and `--locked`'s narrow reach is
quoted from source at an immutable tag. Gate 1's striking is recorded correctly
with the ruling's own wording, licence-independent grounds are preserved where
they were already load-bearing, and the `## Supersedes` payload, the five
parameter lines and acceptance criteria (A)–(E) are all byte-identical where the
decision says they are. The empirical audit's approval is consistent with all of
that.

The two findings are both failures of *propagation* rather than of research.
J1 destroyed a required gate answer as collateral of an adjacent edit and then
asserted an exhaustive edit list that does not contain it. J2 is the more
consequential: the decision proves that `--locked` does not bind the prebuilt
path and then leaves standing the one sentence that relies on `--locked` binding
it, while the integrity mechanism that actually governs the fast path goes
unexamined and the resulting tradeoff is absorbed rather than surfaced. Both are
narrow, mechanical repairs — restore one sentence, rewrite one sentence, add one
unproven item, and put the integrity delta to the owner. Once gate 3 is scoped to
what check 15 showed and the prebuilt path's integrity is either cited or booked
as unproven, the recommendation follows and the item is ready to publish.
