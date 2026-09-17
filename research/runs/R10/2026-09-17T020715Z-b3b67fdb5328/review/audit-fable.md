decision-sha256: 3ebb09ce641aed0d74da8130ea4ec7dc70de4a2b9940b2d2472c2acbda49037b
actor: audit-fable-2026-09-17T020715Z-b3b67fdb5328-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# R10 dependency-cache-action — judgment audit (revision 1, 2026-09-17)

Fresh context; I wrote none of this item's artifacts. The sha256 above was recomputed
over `review/DECISION.md` as read (`shasum -a 256`) and binds this audit to that exact
byte sequence. No prior `review/audit-fable.md` existed in this run. The empirical
(Codex) audit is deferred — the Codex account is out of usage — so this audit runs
alone and says explicitly, below, which of the decision's claims no audit has
re-executed.

## Principle and agreement level

**The shared requirement is stated at the level the evidence supports.** F035
(`docs/port/COMMONALITY.md:41`, `COMMON → REUSE`) is a pattern row that already carries
its 2026-09-04 restatement — *dependency fetches and Cargo build artifacts are cached
across CI runs; "integrated into the language-setup step" was the py/ts mechanism* — and
F036 (`:42`, `COMMON → SUBSTITUTE`, item `R10`) is its tool row. I read both rows in the
live ledger; they are what the decision says they are, and what assertions A9.6 and A9.7
assert. The decision raises the requirement to a **capability plus a correctness policy**
(P1 reuse, P2 no stale dependency, P3 bounded cost) and pushes the py/ts *packaging* —
caching arriving inside the language-setup action — down into "may vary". That demotion
is not asserted; it is earned twice over. Once by the source-level reading that `target/`
is invalidated by inputs no lockfile hash can see, which is why the py/ts one-store,
one-lockfile shape cannot simply port. Once by falsifying the prompt's own premise:
`actions-rust-lang/setup-rust-toolchain` *does* package caching into the setup step, and
does it by delegating to the identical commit this decision pins (assertions A6.1, A6.2,
re-executed in this run rather than carried). With the setup-integrated shape shown to
exist and to be the same engine, "which step it hangs off" is demonstrably packaging and
"what the key contains" is demonstrably the substance. That is the right agreement level
for a `SUBSTITUTE` row, and it is why the same finding does not disturb the verdict.

**The F036 disposition is a legitimate evidence-note amendment, and the routing is
real.** "Routed to the controller" means what `research/RUNBOOK.md` §4 requires of a
`BASELINE-REVIEW:` finding: the controller adjudicates it with the affected decision
owners, and the raising item must not silently change another item or the ledger. The
decision's obligations are therefore to carry the line verbatim, state its own
disposition, and leave the edit. All three hold, checked rather than assumed:

- The `BASELINE-REVIEW: F036` line in `review/DECISION.md` is **byte-identical** to the
  line in `raw/opus.md` (compared programmatically; one such line in each file).
- **The ledger is unedited.** The only commit that touched this run's `review/DECISION.md`
  (`a7d201f`) touched no other path, and the two most recent commits to
  `docs/port/COMMONALITY.md` both predate this run. F036's evidence note still reads the
  pre-amendment wording, "py/ts each get caching free from their language-setup action,
  Rust has no single canonical equivalent" — i.e. the amendment is proposed, not applied.
  Migration obligation 6 says so in the same terms.
- It is an amendment and not an `OVERRIDE`: the verdict `COMMON → SUBSTITUTE` and the
  `F036 → R10` assignment are untouched, so neither the pattern nor the tool classification
  moves. The decision's citation of `docs/port/README.md:77` is a compressed paraphrase —
  that line distinguishes swapping a *tool* (`SUBSTITUTE`) from changing the *pattern*
  (`OVERRIDE`) rather than naming verdict changes as such — but it supports the conclusion
  drawn from it, because an evidence-note correction changes neither.

The decision also declines to raise anything against F035 and says why (the row's own
restatement already carries this item's conclusion). That is correct: a confirming finding
is not a baseline review.

## Design and evidence

**The recommendation follows from the evidence as written.** Every load-bearing element of
the recommended clause is tied to an assertion executed in this run, and I checked each
against `review/evidence/r10-pinned-sources.log` rather than against the decision's prose:

| Element | Evidence in the log |
|---|---|
| `@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2` | A1.1–A1.4 — the annotated tag `v2.9.2` dereferenced to that commit here, not copied |
| range `>= 2.9.1, < 3` | A4.2 (2.9.1's sole entry is `Fix regression in hash calculation`, so the floor is not 2.9.0), A4.3/A4.4 (what 2.9.0 added and why a `< 3` ceiling protects the reading) |
| the two-key split answering the HIGH key question | A3.7 (restore key snapshotted before the lockfile digest), A3.8 (the lockfile digest excludes workspace-own crates) |
| `env-vars: "ImageOS"` | A3.1–A3.3 (appended to the six built-in prefixes; case-sensitive `startsWith` **and** a non-empty value required), A3.4/A3.5 (the key carries `os.type()`/`os.arch()` and no image identity — the #341 defect), A8.1/A8.2 |
| `cache-on-failure: "true"` | A2.5, A2.6 (the input exists and documents its own default as false), A2.2 (`post-if` implements it) |
| `prefix-key: "v1-rslbp"` | A2.3 (the default is `v0-rust`) |
| placement after the toolchain step | A4.3 — 2.9.0 keys on *all installed toolchains*, so a cache taken before the toolchain exists is keyed to the wrong compiler |
| R20 compliance | A9.4; the clause is a full 40-hex SHA plus a trailing version comment, which is `enforced-owner-prefix-pinning` for an owner that is neither `actions` nor `github`, verified against `research/topics/20-third-party-action-pinning-policy/DECISION.md` |
| the rejected alternative | A7.1–A7.3 — GitHub's published Rust recipe quoted verbatim, with `restore-keys` counted at zero |

Architectural alternatives A–E are compared before any library is named, and the
comparison is against the three principles rather than against popularity; E is
identified as the same engine at a different call site rather than as a rival.

**The five engine disagreements are settled on grounds, not on preference.**

1. **Licence.** Codex excluded `Swatinem/rust-cache` on fitness gate 1. That exclusion is
   void under the standing owner ruling of 2026-09-12 (Q7.B), which strikes gate 1 from
   every item (assertion A9.5); the decision records the licence as a figure that excludes
   nothing and names the ruling. Consistent with `docs/port/OWNER-REVIEW.md` as I read it,
   and no licence finding is raised here.
2. **Derived versus hand-written key — Codex is credited fairly, which is the test that
   mattered.** The decision does not flatten Codex's key into GitHub's published recipe. It
   quotes Codex's actual key and restore prefix (both verbatim from `raw/codex.md`, compared
   here) and concedes that they are a genuine two-key split carrying compiler identity that
   satisfies P1 and P2. It then settles on three grounds Codex's key does not answer: no
   `target/` pruning at all, so P3 is unaddressed; no per-job or per-feature `target/`
   separation, which the feature-gated web surface and the MSRV floor job both need — and
   which is the point of `raw/codex.md`'s own claim that the same step "may be placed in
   each R11-defined job"; and hand re-derivation on every fork edit, in a template whose
   purpose is to be forked. The agreement between the engines is recorded as agreement.
3. **Save on failure — enforced by the key, and booked as unproven.** The ground given is
   that P2 is carried by the key rather than by the save condition: a `target/` saved after
   a failure is keyed to the exact lockfile and compiler that produced it, so it cannot be
   served to a different dependency set. That reasoning rests on A3.7/A3.8 and on A2.2, and
   the decision does not stop there — it records the argument as a reading rather than an
   observation and books it as U8 with the exact experiment that would settle it. Codex's
   contrary criterion is described as resting on `actions/cache`'s `post-if: success()`
   default "and offering no argument for it", which matches `raw/codex.md`.
4. **The setup-integrated premise — falsified and re-executed** (A6.1–A6.3), with the
   prompt's narrower true claim about `dtolnay/rust-toolchain` preserved rather than
   overturned. A6.3 also establishes the cost of the runner-up path: no `env-vars`
   passthrough, hence U10.
5. **Figures — re-queried, and no disagreement survives.** I checked the decision's tables
   against `r10-live-figures.log` line by line; every number matches, including the
   3-of-10 responsiveness count and the undefined all-ten median.

**The new `ImageOS` finding is sourced to the runner-image repositories and correctly makes
A7/U5 mandatory.** Both export paths were read at primary source through the contents API
of `actions/runner-images` — `images/ubuntu/scripts/build/configure-environment.sh` writing
`ImageOS` to `/etc/environment` (process-wide), and
`images/macos/scripts/build/configure-preimagedata.sh` appending `export ImageOS=...` to
`$HOME/.bashrc` (shell-scoped) — printed verbatim in the log at A8 and asserted as A8.1 and
A8.2. The consequence the decision draws is exact and is the reason the criterion is not
cosmetic: `src/config.ts` folds an environment variable into the key only when its value is
non-empty (A3.3), so on `macos-latest` the remedy could be configured and contribute
nothing, silently. Raising A7 to mandatory and U5 to "the highest-value unproven row" is the
right disposition, and the finding is correctly presented as the synthesis's own — `raw/opus.md`
read the Ubuntu path only and said so. The one drift surface is declared rather than hidden:
these two reads are the only unpinned remote reads in the script, taken from the default
branch.

**The decision does not implement its own recommendation, and is not faulted for declining
to.** P03 builds and proves the template; every behavioural claim about hits, misses,
restores and build time is carried in the U-table with what would settle it.

## Completeness

**H2 set and `## Parameters` grammar are right.** The file carries exactly `## Decision`,
`## Parameters`, `## Empirical check` and `## Engines`, in that order, with
`### Principles and implementation` and a `re-verify:` line inside `## Decision` — the set
`research/RUNBOOK.md` §5 requires. `## Supersedes` is correctly absent: this is revision 1
and no reversal. The parameter block is four `- assumes` lines with no `- owns` line and no
`CONFLICT:` line, which matches `inputs/prompt.md`'s `## Couplings` (`owns:` and `consumes:`
both empty); no file in the run emits a line beginning `CONFLICT:`, checked directly.

**The four `- assumes` lines are byte-identical to the registry.** I extracted the four
`fixed` rows from `docs/port/PARAMETERS.md` independently and compared the composed strings
to the decision's lines: `msrv-policy`, `rust-edition`, `target-os-matrix` and `license` all
match exactly, and the run's `inputs/PARAMETERS.md` snapshot agrees with the live registry
on all four (the log's A10 says the same; I did not take its word for it). The prerequisite
binding also holds: `research/topics/42-dev-toolchain-provisioning/DECISION.md` hashes to
`a2504aa7e3ad210e788e41ef53fbf37505a5254f54fd31955f9d1d2b574f5e1c`, exactly the value
`inputs/prerequisites.json` binds this run to, and R42 names no CI toolchain-install action
(A9.1, A9.2, both re-checked here).

**The evidence claims stay inside what the logs show.** `r10-pinned-sources.log` ends
`checks: 60 passed, 0 failed, 0 skipped` / `VERDICT: PASS`, and counting the result lines
gives 60 `PASS`, 0 `FAIL`, 0 `SKIP` — the decision's figure, not a rounding of it. Section
A13's four negative controls each print `control fired` with the perturbed expectation shown
beside the real value, so the assertions are demonstrated able to fail rather than asserted
to be. `r10-live-figures.log` reports figures and says it reports no verdict, which is how
the decision describes it. Every number in the decision's live-figures table, crate-figures
paragraph, responsiveness paragraph and RustSec paragraph appears in that log with the same
digits, including the positive control (`atty` → 200) that makes the 404s an absence of
advisory rather than a broken lookup. No figure in the decision exceeds its log.

**Every figure carries an endpoint and a retrieval date.** The decision names the endpoint
per column and the retrieval date per table, and each citable figure is also snapshotted:
all sixteen JSON files under `review/evidence/figures/` carry both an `endpoint` and a
`retrieved` field, checked file by file, with `rustsec-status.txt` beside them.

**Carried readings are labelled as carried.** The 10 GB storage budget (with a sentence
saying every later mention refers back to it), the adoption counts and README/OS-matrix
readings (U12, U13, U14), the `cargo-binstall` `resolve.rs` reading (U7) and the gate-4
three-OS matrix are each marked as carried from `raw/opus.md` and not re-executed. One
load-bearing exception is JF-1 below.

**"No CI run is possible here" is stated honestly, and U1–U14 carry the consequences.** The
claim appears in `## Decision`, again in `## Empirical check` ("these scripts verify; they
build nothing"), and again above the U-table. U11 exists only to make the absence of any
speed figure explicit, and no speedup number appears anywhere in the decision — I looked.
The one claim in `## Empirical check` with no committed artifact is `shellcheck` exit 0 with
"no findings"; I ran `shellcheck` locally over both scripts (read-only, not a rerun of the
evidence scripts) and it is clean, so the claim is true, though a future revision should
capture its output the way the two script logs are captured.

## Findings

**JF-1 — non-blocking. The pruning claims are load-bearing but are neither asserted nor
labelled as carried.** The decision states P3 as met "by pruning before save" and lists the
prune rules — files present in `$CARGO_HOME/bin` before the action ran, unused dependencies,
non-dependencies, incremental artifacts, artifacts older than a week, plus
`CARGO_INCREMENTAL=0`. The pre-existing-file snapshot half then carries two further
conclusions: the `cache-bin` default is kept because a tool installed *after* the step is
cached, and migration obligation 1 makes "before the tool-install steps" a *correctness*
requirement. None of that is among the 60 assertions —
`/usr/bin/grep -c -i -E "prune|cleanup|CARGO_INCREMENTAL"` over `r10-pinned-sources.sh`
returns 0 — and, unlike every other carried reading, it is not labelled carried and has no
U-row. Partial corroboration does sit inside the log: the CHANGELOG printed verbatim at A4
shows `Improvements to cleanup, preserving more valid targets`, `Fix credentials.toml
cleanup` and `Improvements to cargo install handling` at 2.9.2, so cleanup demonstrably
exists at the pin; the specific snapshot rule does not. Disposition: recorded, no change
required to accept this revision — the reading is sourced in `raw/opus.md` from the action's
README and save path and is corroborated at the pin. A later revision should either assert
the snapshot rule against `src/` or label it the way the other carried readings are labelled.

**JF-2 — non-blocking. The probe assigned to settle U5 observes a different process from the
one U5 is about.** U5's claim is about `process.env.ImageOS` inside the action's Node
process. Acceptance criterion A7's probe is `- run: echo "ImageOS=$ImageOS"`, a shell step,
and the decision's own A8.2 finding is precisely that macOS delivers `ImageOS` through a
shell startup file rather than process-wide. Under the default step shell (`bash -e {0}`,
neither login nor interactive) that shell inherits the runner process environment, the same
environment the action's Node process inherits, and the probe is sound — but that
equivalence is the assumption A8.2 puts in question, and the decision does not state it. A
job that changes the shell (a login shell, or `BASH_ENV`) could make the probe report a
non-empty value while the action's own process sees none: a false pass on exactly the runner
the remedy exists for. The stated macOS fallback — "an explicit key segment carrying the same
value from the workflow expression context" — has the same exposure and is under-specified,
because the `env` expression context is populated from workflow, job and step `env:` blocks
and `$GITHUB_ENV` rather than from the runner's ambient environment; the identical
substitute is already booked unproven at U10 for the runner-up path. Disposition: recorded;
it moves nothing in the recommendation, since `env-vars: "ImageOS"` is the right
configuration under either reading and the remedy is already carried as unproven. What it
sharpens is P03's obligation — read the value from a process shaped like the action's, and
spell the fallback as a value the workflow can be shown to produce.

**JF-3 — non-blocking. The `cache-bin` tradeoff drops adverse practice evidence its own raw
report carries.** `raw/opus.md` records that `tokio-rs/tokio` disables the implicated input
per OS — `cache-bin: ${{ matrix.os != 'macos-latest' }}`, with a `FIXME` citing issue #341 —
and the decision's `cache-bin` row argues for keeping the default without naming that
mitigation or saying why it was not taken; the string does not appear in the decision at
all. The row is not wrong: `env-vars: "ImageOS"` addresses the cause rather than dropping
the feature, and R42's binstalled tools are what make the feature pay. But the same decision
records that #341 is live at the pin and that the remedy's effect on `macos-latest` is
unproven (U5), so a forker reading only the decision cannot see the one-line alternative the
best-known adopter in the survey uses. Disposition: recorded; the recommendation does not
move, and the ordering requirement that makes `cache-bin` pay is unaffected. The naming
belongs in the tradeoff record, beside the honest statement already there.

**Observations, recorded as not findings.** (1) `raw/opus.md` puts issue #370's first
maintainer reply at 1.00 d where this run measures 1.171 d; the sentence "no figure
disagreement survives" is about figures *the two engines report in common*, and Codex reports
no #370 figure, so the claim holds as written and neither the 3-of-10 count nor the 0.115 d
median moves. (2) The `docs/port/README.md:77` citation is the compressed paraphrase noted
above. (3) The claim that the key carries every installed toolchain's `rustc -vV` is not
asserted directly in A3, but A4.3 asserts the CHANGELOG entry that introduced it, which is
the same fact from the other side.

## Assessment

Approve. The decision states the shared principle at the level its own evidence supports,
and it earns that level rather than declaring it: the prompt's premise that Rust has no
setup-integrated caching action is falsified against primary source and re-executed in this
run, which is what converts "which step it hangs off" into packaging and "what the key
contains" into substance. The recommendation follows from that reading — a derived key, read
from the implementation at the pinned commit rather than from documentation, with the save
key strictly finer than the restore key — and every element of the recommended clause, down
to the range floor of 2.9.1 and the `v0-rust` default that `prefix-key` overrides, is tied to
an assertion that ran here and that section A13 shows could have failed. The five engine
disagreements are settled on grounds: the licence exclusion is void under a standing ruling
rather than argued away; Codex's hand-rolled key is credited as a real two-key split and
defeated on pruning, per-job separation and fork maintenance rather than on the weaker
published recipe; `cache-on-failure` rests on P2 being carried by the key, with the residual
booked as U8; the premise falsification and the figures were re-executed. The F036 finding is
carried byte-identical, disposed of as an evidence-note amendment, and routed — the ledger is
demonstrably unedited. The item's sharpest new contribution is its own: reading both
`ImageOS` export paths and discovering they are not equivalent, which turns a remedy that
looked settled into a named, testable uncertainty and makes criterion A7 mandatory. Where the
research could not close a claim from a workstation, the decision says so fourteen times over
rather than once, and asserts no build-time number anywhere. The three findings above are
labelling, verification-design and tradeoff-completeness matters; **none of them moves the
recommendation**, the pinned reference, the range, the placement or any of the three
configured inputs, and none is left unresolved against this revision.
