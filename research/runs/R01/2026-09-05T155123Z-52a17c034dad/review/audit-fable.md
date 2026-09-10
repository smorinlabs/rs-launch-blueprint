decision-sha256: 8025fd5b1a959b1e76fa9a738176071b418fd411aa2ba6ad5c6e4bffbd9a018f
actor: audit-fable-2026-09-05T155123Z-52a17c034dad-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

The shared requirement (`DECISION.md:31`) is stated as an outcome, not as a mechanism: the use case
depends on a named driven-I/O contract, is exercisable against a substitutable implementation, that
substitute is a shipped artifact rather than a per-test improvisation, one contract is asserted
against every implementation, and every inbound front end calls one transport-neutral application
contract and emits one shared data contract. That is the right shape under spec §2, which separates
principle from architecture from implementation and forbids inferring the required level from how a
source happens to be implemented.

The bundle's six-row split is correct and verified against source, not taken from memory.
`docs/port/DIVERGENCE-ANALYSIS.md:70-76` records the item as cause class **F** with
`harmonize: partly — see sub-rows`, and the sub-rows carry `harmonize: no` for F001, F002 and F011
and `harmonize: yes` for F013, F018 and F121. The decision's table (`DECISION.md:36-42`) reproduces
that split exactly. None of the six rows appears in `docs/port/BASELINE-REVIEW.md`, which adjudicates
only `COMMON → REUSE` and `ADOPT` rows — so the decision's statement that these are `DIVERGENT`
research rows with no retained baseline to challenge is accurate, and I confirmed it by grep rather
than accepting the assertion.

The level assignment survives the harder test: it does not let repository agreement do the work. py's
`Protocol` + `ty` (`core/ports.py:40`, `pyproject.toml:253`), ts's `CliDeps` function record
(`router.ts:31`, D-019(5)) and Rust's nominal trait are treated as three realizations of one
capability, and ts's D-019(5) is explicitly preserved as defensible in a structurally typed language
rather than being overruled because py did something else. The cross-repo adjudication
(`DECISION.md:76`) is correspondingly disciplined: F013 in ts is named accidental drift with the
evidence for that call (no `D-0nn` exists, and nothing in TypeScript prevents exporting a factory);
F121 is contingent on F013; F018 is an absent capability carried once on R69, not drift; F001/F002/
F011 are justified ecosystem differences. No ledger row, index entry or other item was silently
changed, as the charter requires.

Two qualifications. First, `DECISION.md:44` claims "All five engines agree on this framing." At the
coarse level (a capability must agree, a mechanism may vary) that holds, but the label does not:
codex, gemini and perplexity each place the shared level at **architectural pattern**, and openai's
per-requirement table puts "Production dependency graph is explicit" (F002) at *Architectural policy
— must agree* and "Compile-time adapter/API conformance" (F011) at *Capability — must agree* — two
rows this decision assigns to "mechanism, Rust decides alone." Only opus uses this decision's table
verbatim, and the decision is drawn from opus. Second, calling F018 a "capability" is loose: "web
layer as a thin adapter reusing the CLI's data contract" reads as spec §2's *architectural pattern*
row (responsibilities and relationships). Neither qualification changes an outcome, for a reason I
checked rather than assumed: the decision's own criteria 2 and 4 already require centralized
production wiring and mechanical conformance of every adapter, so the substance openai wants held is
held; ts's `realDeps()` already centralizes production construction, so nothing moves onto the ts
follow-on list; and consumers inherit the parameter value and the acceptance criteria, not the level
labels. Recorded as finding 2, not blocking.

## Design and evidence

**Does the recommendation follow from evidence rather than agreement or popularity?** Substantially
yes, and the decision is unusually explicit about the discipline. Six architectural alternatives are
compared before any crate is weighed (`DECISION.md:59-66`). Option B is ts's own shape and is
rejected on argued grounds — per-field boxing, loss of the invariant that related operations share
one backend, no home for a stateful fake, one contract per function for F121 — not because py
disagrees. Option F (DI containers) is rejected on a principle argument (a wiring error becomes a
resolution-time failure where Rust already has a compile error) *before* the adoption figures are
cited, which is the correct order under the prompt's fitness-gates-before-popularity rule; the
figures I spot-checked against the raws are real (`shaku` 34,716 / 240,829 and `dill` 5,580, both in
`raw/opus.md`, `shaku` also in `raw/codex.md`). The chosen option E is *not* the popular answer among
the engines — codex and gemini recommend D, openai recommends C — so the recommendation cannot have
been produced by counting engines.

**Is the E-over-D argument itself carried by its evidence?** Partly, and this is the sharpest
qualification in the decision. Design E's distinguishing element is the generic `ProjectsService<P>`
plus the blanket `impl<T: ProjectsPort + ?Sized> ProjectsPort for Arc<T>`, so that library consumers
monomorphize while the CLI and web share `ProjectsService<Arc<dyn ProjectsPort>>`. The three
reference projects cited in support of E (`DECISION.md:65`, detailed at `:84-86`) are, by the
decision's own citations, D-shaped: `crates.io` holds `pub github: Arc<dyn GitHubClient>` in `App`,
`jj` holds `Box<dyn Backend>` in `Store`, `sccache` declares `pub trait Storage: Send + Sync`. Line
64 calls that same set "the `jj`/`sccache` shape" while rejecting D. The distinguishing half of E has
normative support (the Rust API Guidelines C-OBJECT point that declaring the trait dyn compatible is
the load-bearing decision), Tower's `BoxService` "generic first, erase at the boundary" precedent
(openai's citation), and the opus report's executed probe — but not those three projects. Recorded as
finding 1. It does not block, for three reasons: at the composition root E *is* D, so the practice
evidence genuinely supports the shape the shipped binaries carry; D is ranked first runner-up with
its cost stated ("library consumers pay a vtable call they cannot opt out of"), so a P03 collapse to
D is a documented and cheap fallback; and the engine split on this exact question is disclosed as
disagreement 1 rather than smoothed.

**Sub-decisions.** Each of the remaining engine disagreements is settled with a stated discriminator
rather than a vote: `Send + Sync` as supertraits (four engines plus all three surveyed projects, with
openai's bound-at-the-web-state variation recorded for a consumer that does not exist); `Mutex` over
`RwLock` as the simplest std primitive keeping the fake `Send + Sync`, with `RwLock` called an
equivalent variant and perplexity's `&mut self` sketch rejected on a type-level consequence of the
erasure; a generic contract function over `rstest`/`test-case` because the thing that varies is a
*type*, with the observation that `jj` uses `test-case` only because its backend selector is a value
(`TestRepoBackend` enum) — a fit argument, not a popularity one. The `serde` selection is the one
place where an ecosystem default is adopted, and it is gated explicitly (`DECISION.md:109`).

**Empirical evidence, and what it is allowed to carry.** Four checks were run, and the decision's
scope claims about them are honest to the logs, which I read. `compile-fail-reasons.log` shows
`error[E0046]: not all trait items implemented, missing: get` at exit 101 and `error[E0038]: the
trait NotDynCompatible is not dyn compatible ... because method pick has generic type parameters` at
exit 101 — precisely the two codes criterion 4 and the `BASELINE-REVIEW: F011` line rest on.
`dependency-msrv-license.log` shows the member subtree resolving with a maximum declared
`rust-version` of 1.71 against a 1.96 floor, all licences permissive. `cargo-audit.log` shows 1,243
advisories loaded, 53 dependencies scanned, exit 0. `macos-stable-clippy-fmt.log` shows `cargo fmt
--check` and `cargo clippy --locked --all-targets -- -D warnings` both at exit 0. Check 1 runs
against revision 1's retained fixture; the decision discloses that plainly, states the single fact it
takes from that compile, and says a compile is not an execution. Revision 2 did not build anything,
so the narrowed role contract's prohibition is not breached — the fixture is disclosed history, and
that framing is right.

## Completeness

**Required structure.** The four H2s the runbook §5 requires are present and in order: `## Decision`
(carrying `### Principles and implementation`, the settled rows F001/F002/F011/F013/F018/F121, and a
`re-verify:` line at `:132`), `## Parameters`, `## Empirical check` (toolchain, OS, working
directories, commands, exits, observed output), `## Engines`. `## Supersedes` is correctly absent:
revision 2 is not a reversal — the recommendation and the owned value are unchanged — and the
revision history is recorded under `## Engines` instead.

**The owned parameter.** `http-transport-injection-seam` (`DECISION.md:136`) is complete against the
registry's description in `docs/port/PARAMETERS.md` ("the shape of the driven-I/O seam that fakes are
injected through (trait object, generic bound, or an injected client value)"): it names the trait and
its dyn-compatibility constraints, the blanket `Arc<T>` impl, the generic use case, the erasure at
the composition root, the single erased service handed to both front ends, how fakes are injected
(as any `ProjectsPort` implementor, never as function values and never by transport patching), and
the conditional `async-trait` clause. It is consistent with the recommendation table at `:13-18` and
with every design paragraph; I found no clause in the value that the body contradicts. The four
`assumes` values are quoted character-for-character from `docs/port/PARAMETERS.md` — I diffed them.
The value carries illustrative identifiers (`ProjectsPort`, `ProjectsService`, `InMemoryProjectsPort`)
for a template that does not exist yet; that is unavoidable at P02 and the decision defers crate name
and placement to R02 explicitly. One small gap: the input handed to R69 at `:152` describes the web
state type as `Clone + Send + Sync + 'static`, and `Clone` depends on a derive the design text never
states (it is present in the retained fixture's `service.rs` and compiled under check 1, so it is
true, but it is neither one of the four verified facts nor one of the six unproven rows). Worth
adding for R69's benefit; too small to block.

**The six unproven claims.** Honest, and each paired with a test that would actually discriminate.
Row 1 is the strongest: it restates the rejected revision's finding as the claim it is, and its proof
is specified to *fail* if `production_service` stops erasing the production adapter — a discriminating
test, not a smoke test. Row 2 (one erased service reaching both front ends), row 3 (live web path,
correctly marked blocked on R69), row 4 (the matrix and MSRV legs, with the honest admission that
only the macOS host toolchain at 1.98.0 ran), row 5 (`async-trait` restoring dyn compatibility,
correctly attributed to the opus report as engine-reported rather than claimed as re-executed) and
row 6 (vtable cost, deliberately unmeasured with the reason stated) are all claims the body genuinely
makes and no check establishes. I looked for claims that should be in the table and are not; the two
candidates are the `Clone` bound above and the blanket impl's legality, and the latter is materially
covered because the erasure site compiling is the fact check 1 takes. The confidence paragraph at
`:128` is calibrated the same way — high on the parts as researched, explicitly *not* on their
assembly.

**Perplexity.** Weighed for content and not leaned on for its gaps. `## Engines` records the shape
FAIL, names the truncation point ("Axum Web Adapter Layer" after two fields) and the five missing
top-level fields; I reran `scripts/check-answer-shape.sh` against the normalized file and it fails on
exactly the recorded fields and that member. What the decision draws from it — trait port, generics
inside the library with trait objects at the boundaries, shipped in-memory adapter, generic contract
function, `serde` DTOs, no mocking crate for F011/F121, `hexser` not adopted — is all present in the
file I read, and its `&mut self` fake sketch is recorded as *not* adopted with a reason. It is
credited as recommending design E "in prose," which its `### Recommendation` paragraph supports. No
figure is attributed to it, correctly, since it carries none. The claim that no field or member is
left unsupported holds: codex, opus and openai cover every required field. No narrowed resubmission
was made, so runbook §3's `narrowed: yes` marker is not owed here.

**BASELINE-REVIEW and CONFLICT.** Both handled as the runbook requires. The `BASELINE-REVIEW: F011`
line (`:80`) carries all four required fields — feature ID, principle, proposed change, evidence —
names both affected items (R01 and R30, with the specific instruction that R30 must not scope
adapter-port conformance into a checker gate), and cites the executed log rather than asserting the
diagnostics from memory. Nothing was written to the ledger, index or registry, which is correct: the
controller adjudicates. The `CONFLICT` line is the one place a transcription error would matter, so I
checked it against the source: `raw/codex.md:299`, under codex's top-level `### Parameters`, reads
exactly as quoted at `DECISION.md:148`. (Codex also emits a differently worded conflict line at
`:85` inside a member's `##### Parameters`; the decision quotes and cites the top-level one, which is
the right one.) The adjudication that this is not a registry conflict under runbook §4 is correct and
I verified its premise independently: §4's mechanism requires a registered value to change, and
`docs/port/PARAMETERS.md` shows R05 owning no parameter at all, so there is nothing to reopen and no
consumer to hold `in-progress`. The coupling is real, is resolved inside the decision under either
R05 outcome, and is made the first `re-verify` trigger.

**Required figures.** One omission. The prompt's evidence table makes issue responsiveness (median
days to first maintainer response; unanswered count) a required figure per candidate, and the tier
guidance says an inapplicable metric must be stated as `inapplicable` with its reason and never
omitted silently. The crate table at `:93-107` carries responsiveness for `mockall` and `rstest` only.
`serde` — the sole mandatory crate member of the base stack — is given "active (120,056 reverse
deps)" with no responsiveness figure, although `raw/opus.md:991-996` captured one: of the 10 most
recently opened `serde-rs/serde` issues, **0** drew a first maintainer comment, so no median can be
computed and the unanswered count is 10, which opus then contextualizes (3 of the 10 were closed
within 0–2 days with no comment — `#3090`, `#3087`, `#3084` — the maintainer's documented
triage-by-close style) and explicitly declines to smooth. The decision drops both halves. Recorded as
finding 3. It does not block: the `active` verdict rests on release date 2026-07-18 and `pushed_at`
2026-08-25 under the stated rubric, the crate is the ecosystem's data model with 120,056 reverse
dependencies, and no reading of the omitted figure unseats it. It would block on a contested
candidate, because the figure that went missing is the unflattering one.

**The concurrent empirical audit.** `review/audit-codex.md` was absent when I began and present when
I finished (3,173 bytes, 19:19; I checked again at 02:20Z before writing). It approves with no
unresolved findings, and it is consistent with the decision and with my own reading: it reproduces
all four checks in a copied fixture, records the same `E0046`/`E0038` exits, the same 1.71 subtree
maximum, the same 1,243-advisory / 53-dependency scan (via `--db` after the sandbox's shared
advisory-cache lock failed, the same environment issue its revision-1 run hit), curl-checks five
cited sources at HTTP 200, and states the same limits the decision states. Its own header is
defective, however: `decision-sha256` reads `8025fd5b1e76fa9a738176071b418fd411aa2ba6ad5c6e4bffbd9a018f`
— 58 hex characters, with `1a959b` dropped from the true digest. Its body demonstrably reviewed this
revision (it reruns revision 2's four checks and enumerates revision 2's six-row unproven table), so
this is a transcription defect, not a wrong-revision audit. Recorded as finding 5, addressed to the
controller: runbook §5 requires both auditors to review the exact revision, and the record should
carry a digest that matches. It is not a defect of the decision and does not affect my verdict.

## Findings

1. **practice-evidence-cited-for-both-E-and-D — note, does not block.** `DECISION.md:65` supports the
   chosen design E with "the three reference projects below," and `:64` describes the rejected design
   D as "the `jj`/`sccache` shape." By the decision's own citations at `:84-86`, all three projects
   are D-shaped (`Arc<dyn GitHubClient>` in `crates.io`'s `App`, `Box<dyn Backend>` in `jj`'s `Store`,
   `sccache`'s `Storage` trait); none exhibits E's distinguishing generic service plus blanket
   `Arc<T>` impl, whose practice support is Tower's `BoxService` pattern and the opus probe. Not
   blocking: at the composition root E is D, so the citation is sound for the shape the binaries
   carry; the distinguishing half has C-OBJECT plus Tower plus an engine-executed probe; and D is
   ranked first runner-up with its cost stated, making a P03 collapse to D cheap and documented.

2. **engine-consensus-on-agreement-level-overstated — note, does not block.** `DECISION.md:44` says
   "All five engines agree on this framing." Codex, gemini and perplexity label the shared level
   *architectural pattern*; openai's per-requirement table places F002 at *Architectural policy — must
   agree* and F011 at *Capability — must agree*, both of which this decision assigns to "mechanism —
   Rust decides alone." Only opus, the report this synthesis follows, uses the decision's table.
   Not blocking: criteria 2 and 4 already hold the substance openai wants held, ts's `realDeps()`
   already centralizes production construction so the ts follow-on list is unchanged, and consumers
   inherit the parameter and the criteria rather than the level labels.

3. **serde-issue-responsiveness-omitted — note, does not block.** The prompt requires an issue-
   responsiveness figure per candidate, or an explicit `inapplicable` with a reason. The crate table
   supplies it for `mockall` and `rstest` only; for `serde`, the base stack's sole mandatory crate,
   `raw/opus.md:991-996` captured "0 of 10 answered, median uncomputable, unanswered count 10" plus
   opus's triage-by-close mitigation, and the decision carries neither half. Not blocking: the
   `active` verdict rests on release and push dates under the stated rubric and the figure would not
   unseat serde — but the omitted figure is the adverse one, so it should be restored with its
   context if the decision is revised for any other reason.

4. **check-1-scope-disclaimer-contradicted — note, does not block.** `DECISION.md:180` says of check
   1 that "Nothing else that compiled is relied on," while `:109` closes serde's macOS CI-coverage
   gap by asserting that "the pin-resolution and lint checks ... compiled `serde` 1.0.229 and
   `serde_json` 1.0.151 on macOS 26.4 aarch64 at 1.98.0." That is a second fact taken from check 1's
   compile, and the sentence also credits check 3, which runs `cargo metadata`/`cargo tree` and
   compiles nothing. Not blocking: the underlying fact is true and visible in the cited log
   (`macos-stable-clippy-fmt.log` shows `Compiling serde v1.0.229` and `Compiling serde_json
   v1.0.151`), so the defect is over-strict disclaiming prose in one place and a mis-attributed check
   in another, not an unsupported claim.

5. **audit-codex-header-sha-truncated — note, not a defect of the decision; controller action.**
   `review/audit-codex.md:1` records `decision-sha256:
   8025fd5b1e76fa9a738176071b418fd411aa2ba6ad5c6e4bffbd9a018f`, 58 hex characters, with `1a959b`
   dropped from the true digest `8025fd5b1a959b1e76fa9a738176071b418fd411aa2ba6ad5c6e4bffbd9a018f`.
   That audit's body plainly reviewed revision 2 (it reruns its four checks and enumerates its six
   unproven rows), so this is transcription, not a wrong-revision review; but runbook §5 requires both
   auditors to review the exact revision, so the header should be corrected before acceptance is
   recorded. Outside my verdict on `DECISION.md`.

## Assessment

**Yes — I would stake the 38-item subtree on this decision.** Two things carry that answer. First,
the part of the parameter that most consumers actually read is the part that is verified. Clause 1 —
a dyn-compatible trait port with fakes injected as any implementor, no injected function values, no
transport patching — is what R48 consumes (it receives "the recommended seam needs no HTTP-mocking
crate," which follows directly) and what R32 consumes (the one-generic-function, one-call-site-per-
adapter suite shape), and its load-bearing property is the one thing this run proved at the compiler:
`E0046` for a missing method and `E0038` for a non-dyn-compatible port, both reproduced by the
empirical auditor in a copied fixture. Second, the part that is *not* verified is fenced honestly.
Clause 2 — production erasure at the root, one erased service reaching both front ends — is what R69
consumes, and it sits in the unproven table as rows 1 and 2 with a test specified to fail if the
erasure disappears. A consumer that reads the parameter and the table together cannot mistake a
proposal for a proven design, which is exactly what the owner's 2026-09-10 scope ruling asks of a P02
decision.

The residual risks are bounded and named. The E-versus-D choice (finding 1) is the one place where
the practice evidence does not discriminate as strongly as the prose implies — but D is E minus the
generic half, D is the ranked runner-up, and the shipped CLI and web binaries get identical shapes
under either, so a P03 correction is a local edit to the service's type parameter, not a re-research.
The R05 coupling is the largest genuine open variable, and it is handled better than a deferral: the
port stays dyn compatible under either outcome, the async route is named with a pinned version and a
production precedent (`crates.io`'s `async-trait = "=0.1.92"`), the async half is listed as unproven
row 5 rather than asserted, and R05's publication is the first re-verify trigger. The `serde` pins
are correctly marked medium confidence pending the template's real lockfile.

What makes this safe to build 38 items on is not that it proves much — it proves four narrow things
and says so — but that it is accurate about which of its claims are which. The rejected revision 1
answered its auditor by building a working seam; revision 2 answered by deleting the claims that
seam was standing in for, which is the correct move under the narrowed contract and the harder one to
make. Its alternatives table, engine-disagreement ledger and evidence logs are detailed enough that a
claim failing in P03 can be revised against this recorded research rather than sending the keystone
back to research — which is the property a keystone actually needs. My four notes on the decision are
prose and completeness defects that a single revision pass would clear; none of them moves the
recommendation, the owned value, or any of the six settled rows. Approve.
