decision-sha256: 16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497
actor: audit-fable-2026-09-05T155124Z-2271e140a7ef-r4
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

I rejected revision 2 of this decision, so I re-read the standard at source rather
than carrying my earlier reading forward. Every rule the decision leans on is
quoted accurately in revision 4:

| Rule | Source line | What the decision claims | Standing |
|---|---|---|---|
| R6.1 `(MUST)` | `/Users/stevemorin/c/cli-standards/cli-design-standard.md:351-366` | the table `0/1/2/3/4/5/130/143` with the quoted meanings, "Unlisted failures collapse to `1`", `sysexits.h` (64–78) rejected by name as "over-specified and unavailable on Windows" | exact, including the org-lock row at `:70` ("Exit codes … reject sysexits.h · org-locked") |
| R7.7 `(MUST)` | `:427` | flush all streams before exiting on every path — success, error, and signal | exact |
| R7.8 `(MUST)` | `:431-433` | single stderr object `{"error":{"code","message"}}`, `code` a stable documented string, object **MAY** carry "other documented fields" | exact; this is genuinely the authority that lets `hint` be a peer field rather than inlined prose |
| R8.2 `(MUST)` | `:460-461` | exit `2` for required non-auth input or consent **missing** because prompting is disabled/unavailable; exit `4` for missing auth input; exit `1` for "runtime input failures such as unreadable files" | exact, and now quoted verbatim rather than paraphrased |
| R9.6 `(MUST)` | `:502-503` | clean `SIGINT`→130, `SIGTERM`→143, `SIGPIPE`/EPIPE quiet "without a broken-pipe stack trace" | exact |
| R5.5 / R5.6 `(MUST)` | `:326-333` | govern secrets and assign no exit code | correct — neither rule mentions an exit code |

The five-level decomposition P1–P5 (`:68-74`) is unchanged from revision 2 and is
still the load-bearing move: each principle carries its own agreement level and an
explicit split between what must agree across py, ts and rs and what may vary.
Those levels map onto spec §2's own taxonomy — P2 is a "policy or mechanism"
shared value and is raised to "standard, one value for all three repos" on an
owner decision (the org-locked row), not on the item's judgement, which is exactly
what §2 requires of a deliberately shared low-level value. P3 and P5 stay at
*capability*, which is why the hint's rendering and the crash record's location
can be left to other items without weakening the principle.

**The repair I rejected revision 2 for.** My first finding was that the decision
rendered R8.2 as covering input "missing **or invalid**" — words the rule does not
contain — and presented `RSLB203` (config value invalid → 2) as standard-derived.
I swept every occurrence of `R6.1`, `R8.2`, `R7.6`, `R7.7`, `R7.8`, `R9.6`, `R5.5`,
`R5.6`, "the standard", "standard-derived", "org-locked" and "MUST" in revision 4.
The repair holds in all of them:

- `## Decision`'s configuration paragraph (`:255-276`) — the passage the empirical
  auditor rejected revision 3 over — now separates the two standard-settled rows
  (`RSLB104`→1 on R8.2's unreadable-file clause, `RSLB202`→2 on R6.1's parse limb)
  from `RSLB203`, states in the decision's own words that "R8.2's exit-`2` clause
  is about required non-auth input or consent that is **missing** … not an invalid
  value", records R6.1's unlisted-failure default of `1`, and labels the row
  "**this template's choice, not a standard-derived requirement**".
- The owned parameter (`:383`) labels `RSLB203` and `RSLB204` as choices inline,
  where a consumer reading only that line will see them.
- Disagreement 4's basis table (`:587-591`) assigns each of the five rows one
  basis and no more: `RSLB104`/`RSLB202`/`RSLB205` standard-derived, `RSLB203`/
  `RSLB204` template choices.
- AC3 (`:122`) states only R6.1's own categories and claims no derivation. E10
  (`:464`) records the standard's 2/4/1 split as read, without extending it.
- The historical revision records (`:575`, `:730`, `:769`) quote the rejected
  wording as the defect being described, framed as corrected, and nowhere
  reintroduce it as current contract.

Both template choices carry their reasoning and their cost. `RSLB203`: kept at 2
because it is the same user-facing failure as `RSLB202` with the same remedy, and
routing it to 1 would split one condition across two codes and put "your input is
wrong" in the same bucket as "the network failed"; cost if wrong, "one catalog row
and one arm of the `exit()` match" (`:268-273`, expanded at `:594-603`). `RSLB204`:
the same shape, a rejection of user-supplied configuration input, with the same
stated cost and an explicit note that "a conformance audit reading R6.1 strictly
could call `2` over-broad here, and R55/R56 are the items positioned to raise it"
(`:600-603`). That is the honest form — a labelled choice with a named challenger
— and it is what my finding asked for.

My second finding, that the trace-exclusion rule was disclaimed in prose and
published in the owned parameter, is also repaired, by a different route than I
proposed; I address that under `## Completeness`.

**Evidence, not majority or familiarity.** The three places where this could have
gone wrong all resolve on evidence:

- `ctrlc` is proposed by exactly one provider body, Perplexity
  (`raw/doxa-perplexity.normalized.md:77`, which recommends it "with `termination`
  feature enabled" on the ground that the template is not a daemon).
  `signal-hook` is chosen by codex, opus, OpenAI and Gemini. The decision reaches
  the majority's answer while replacing the majority's reason: Gemini's stated
  ground — that `ctrlc` "does not provide native `SIGTERM` capture" — is false, and
  the decision instead reads the published tarball. I confirmed the read against
  `review/evidence/ctrlc-source-3.5.2.log`: `set_handler` at `src/lib.rs:93` takes
  `F: FnMut()` with no signal argument, the crate's own doc comment at `:44-46`
  says the `termination` feature routes `SIGINT`, `SIGTERM` and `SIGHUP` to that
  same callback, and `src/platform/unix/mod.rs:100-123` installs one `sigaction`
  across all three. 130 and 143 therefore cannot be told apart, which R9.6
  requires. The decision also records that the Rust CLI Working Group book — a
  genuine ecosystem authority — names `ctrlc`, and treats that as a fit failure
  rather than a dismissal of the source (`:227-240`). That is the survey method
  working as specified.
- `strum` is rejected against 133.6M 90-day downloads and its use in Ruff and
  Nushell, because deriving the wire code from a variant identifier reproduces the
  exact ts defect (`src/router.ts:211`) this item exists to fix (`:136`, `:530-542`).
- The configuration block follows neither engine camp wholesale, which is the
  strongest single sign that the synthesis is not vote-counting. Of the four
  bodies weighed on this question, codex maps every configuration fault to 1 and
  opus, OpenAI and Perplexity map them all to 2 (`:257`, `:570`; Gemini's own table
  is internally inconsistent and was set aside). The decision sides with codex
  against the other three on `RSLB104`→1, because R8.2 says "runtime input
  failures such as unreadable files" in those words, and with the other three
  against codex on `RSLB202`→2, because a malformed document is a parse failure on
  R6.1's face — then declines to derive `RSLB203` from either rule at all. The
  split tracks the standard's text row by row rather than any report's position.

## Design and evidence

The five architectural alternatives A1–A5 (`:129-137`) are compared before any
crate is named, each rejected against a named principle and a named downstream
consumer — A1 against R70's need for an exhaustive domain-error→HTTP-status table,
A5 against the same, A4 against P1 — and A3 is chosen for reasons that trace to
the parameter registry rather than to precedent. Seven reference manifests are
fetched at a stated endpoint and date, and four of them ship the
`thiserror`-in-library / `anyhow`-in-binary split. As I noted at revision 2, the
sentence "four of the seven do exactly that, and the one that does not is the one
with no library surface" (`:324-326`) still under-describes its own table —
ripgrep and fd are both carrier-only, and cargo-nextest is the same two-layer
shape with `color-eyre` as the carrier — so the evidence supports the conclusion
slightly more strongly than the prose claims. Unchanged, and still not a defect.

Two mechanism checks the empirical audit did not cover, both load-bearing for a
consumer and both resolvable without compiling anything:

- **`signal-hook` with `default-features = false` still exposes the recommended
  API.** Nothing was built, so E13's resolution would not have caught `flag` being
  feature-gated. `review/evidence/signal-hook-inquire-source.log:48-58` shows the
  crate's `[features]` block as `channel`, `default = ["channel","iterator"]`,
  `extended-siginfo`, `extended-siginfo-raw`, `iterator` — no feature named `flag`
  — and I confirmed against the same version in the local registry
  (`signal-hook-0.4.4/src/lib.rs:352-355`) that `pub mod flag;` is ungated while
  `pub mod iterator;` carries `#[cfg(all(not(windows), feature = "iterator"))]`.
  The recommended manifest line is therefore sound, and the decision's stated
  reason for taking it (the `flag` API needs neither default, and `iterator` would
  introduce a helper thread) is correct.
- **The Cargo SemVer citation survives its live URL.** The empirical auditor
  reports that E9's rendered-book URL now returns 404. The claim is preserved in
  this run's dated log: `review/evidence/ecosystem-authorities.log:141,159-161`
  carries "Major: adding new enum variants (without non_exhaustive)" and `:201`
  carries "Adding variants to a default representation enum, if the enum uses
  non_exhaustive", retrieved 2026-09-09 from both the rendered book and the
  cargo source `semver.md`. For a research decision a dated log preserving the
  quoted text is sufficient, and the `#[non_exhaustive]` + `ALL` + coverage-test
  shape R70 consumes does not rest on a live fetch.

**Empirical check.** Revision 4 states plainly that it reran nothing and that the
repair is textual (`:802-805`), which is the right claim for a one-passage edit.
The prior figures still reproduce: `review/evidence/dependency-resolution.log`
carries "Locking 20 packages to latest Rust 1.96 compatible versions", 22 crate
dependencies scanned with no findings, the `=1.0.102` control still reporting
RUSTSEC-2026-0190, no `etcetera` in the resolved tree, and the superseded
one-package observation retained above a dated continuation header with its
narrower scope labelled rather than deleted. `review/audit-codex.md` (r4, approve)
reran E13 on a Linux VM and E14 on macOS against a byte-identical copy of the
fixture and reproduced the same numbers; its account and the decision's do not
diverge anywhere I could test. E4's paired-control framing and E6/E7's
"source-interface finding only" qualifiers remain stated where the claims are made.

## Completeness

Exactly the four mandated H2 headings appear in order (`## Decision` `:7`,
`## Parameters` `:381`, `## Empirical check` `:417`, `## Engines` `:523`), with
`### Principles and implementation` inside `## Decision` (`:54`) and `re-verify:`
as that section's final line (`:379`). The owned parameter is the one the registry
assigns and the only one: `docs/port/PARAMETERS.md:16` gives R67
`error-taxonomy-exit-codes` and no other, and Gemini's five self-claimed
parameters are correctly read for content and disregarded for scope. The four
fixed parameters are quoted exactly against `docs/port/PARAMETERS.md:7-10`.
`consumes:` is empty in the prompt and no consumed parameter is invented. All six
fitness gates are answered per crate before popularity is weighed, with gate 2
executed rather than deferred. Every figure carries an endpoint and a retrieval
date.

**The owned parameter is complete, unambiguous and internally consistent**, tested
row by row. Every non-zero R6.1 code has at least one catalog row (1: `RSLB000`,
`101`–`104`; 2: `RSLB201`–`205`; 3: `RSLB301`; 4: `RSLB401`, `402`; 5: `RSLB501`;
130: `RSLB901`, `903`; 143: `RSLB902`). The "hundreds digit = exit code" mnemonic
is scoped to the `1xx`–`5xx` blocks, so the `9xx` signal block and the `RSLB000`
sentinel are stated exceptions rather than violations. The three-way broken-pipe
rule (result stream → 0; a failed stderr envelope write → retain the already
selected status; any other stream → `RSLB101`/1) is exhaustive over the streams it
names, and it disambiguates essential behaviour 6's precedence shorthand at
`:108`, which the prose alone does not. `RSLB205` reproduces R8.2's exit-2 case
including its "prompting is disabled/unavailable" condition, so the revision-3
widening beyond `--no-input` follows the rule rather than extending it.

**Declining the backtrace rule is right, and revision 4 states it cleanly enough
to act on — by a different route than I proposed.** My revision-2 repair suggested
saying that the envelope's closed field set already answers F301's question (b),
leaving only (a), the capture mechanism, open. Revisions 3 and 4 took the other
route: the trace rule was *removed* from the owned parameter, and `## Decision`
(`:362-378`) now says the item "publishes no trace rule in its owned parameter
either", states both criteria as assumptions, and explains that "a trace therefore
has no field to occupy — but that is a consequence of the field list, not a
disclosure rule, and this item asserts none". I accept that route and prefer it to
mine: declaring (b) settled would have decided an owner question by side-effect,
which is the very thing the `- owns:` line forbids. The parameter text is
consistent with it — "This item defines exactly those three keys and defines no
trace, cause-array or diagnostic field; R7.8 permits further documented fields,
and any such field is a separate addition owned by the item that needs it" is a
scope statement, not a prohibition, so no consumer reads a disclosure rule the
prose disclaims. The `BASELINE-REVIEW:` line itself (`:360`) is carried verbatim
in `## Decision`, names F301, its proposed change, its affected item and its
evidence, matches `docs/port/BASELINE-REVIEW.md:154` and the owner question at
`:194`, and touches no other item and no ledger row. OpenAI's `force_capture`
proposal is recorded as a competing position and explicitly not adopted, with the
reason (it would change a cost and privacy contract the owner has not
dispositioned). The owner has what an owner needs: the question, the two options,
the evidence, and what happens under each disposition.

**`CONFLICT:` handling re-verified, not assumed.** Perplexity's line is quoted in
full (`:391-396`) and not escalated. Each of the three stated reasons is
checkable and checks out: `consumes:` is empty in `inputs/prompt.md`;
`research/CLAUDE.md:62` shows R57 with no owned parameter, so no
`state-directory` parameter exists to conflict with; and the prompt's own
`related` note directs the item to treat the state-directory question as open and
not to block. The substance is answered rather than deferred — the decision
assumes no default path at all, which removes the dependency the line describes.
codex and opus each state they raise none, as the decision records.

**Perplexity was weighed for what it contains and not leaned on for what it
lacks.** I confirmed the shape claim directly: `raw/doxa-perplexity.normalized.md`
carries `Landscape`, `Principles and implementation`, `Recommendation`, `Members`,
`Compatibility` and `Sources` and no `Parameters`, `Migration implications`,
`Validation strategy` or `Confidence & re-verify trigger`. The decision records
this once with the consequence stated (no parameter value, no re-verify trigger)
and then uses the body on the merits in six of the eight disagreements, including
where it agrees with it. Its `ctrlc` recommendation is defeated by a source read,
not by its incompleteness; its `RSBP` prefix is set aside for having no stated
rule behind it, not for coming from the short report; its `CONFLICT:` line is
quoted in full and answered on substance; and the misfiled `BASELINE-REVIEW:`
lines it shares with OpenAI are recorded and not propagated.

**The eight unproven items are honest and complete.** They cover every runtime
claim the design makes: AC1–AC8 on both matrix OSes; destructor and flush
behaviour under real signal delivery (R7.7's `MUST`); the parser's exit 2, which
belongs to R60; `RSLB903`'s reachability; the web `SIGTERM` drain; the crash
record's permissions and location; append-only enforcement by test rather than by
documentation; and compile time and binary size. Each names its proof. The two
structural admissions are stated rather than buried (`:806-812`): no runtime
behaviour was executed on any platform, and the resolution checks ran on macOS
only, so the Linux half of `target-os-matrix` is unexercised even for resolution.
opus's measured results — the 101-versus-0 `println!`/`writeln!` control, the
`Drop` guard, `clap` exiting 2 — are recorded as opus-measured and not
independently re-executed, and are used as corroboration rather than as this
decision's own evidence. This is a research decision that declines to implement
its recommendation, which is what P02 requires, and I fault it for none of that.

## Findings

No unresolved findings. Three precision notes, none blocking, none touching the
recommendation or a consumed value:

1. **R7.6 is a `SHOULD` clause about error messages, rendered as a requirement
   about the hint.** `:169` and the owned parameter at `:383` say the hint's type
   "must be able to name the offending input as R7.6 requires". R7.6 at
   `/Users/stevemorin/c/cli-standards/cli-design-standard.md:421-422` reads
   "Errors **MUST** be written to stderr (R7.1) and **SHOULD** be lowercase-first,
   … name the offending input in quotes …" — the naming clause is `SHOULD`, and it
   governs the message, not the hint. This is a strength overstatement rather than
   an attribution of something the standard does not cover, and the only
   consequence — preferring a borrowed-or-owned string to `&'static str` — is
   explicitly labelled P03's choice and would be the right default under a
   `SHOULD` in any case. Worth one word ("as R7.6 asks") whenever the file is next
   touched; not worth a revision of its own.
2. **`RSLB901` versus `RSLB903` is resolved by an unstated assumption.** Both exit
   130, so no exit code is ambiguous, but the *code* is: boundary precedence is
   "signal → broken pipe → domain downcast" (`:383`), so a Ctrl-C that sets the
   process flag yields `RSLB901`, and `RSLB903` is reachable only if the prompt
   crate's raw-mode terminal suppresses `SIGINT` so the typed variant arrives
   without the flag. The decision forbids a prompt-local handler (`:305`) but never
   states that assumption. It does flag the consequence honestly — unproven item 4
   is "*That `RSLB903` is reachable*", with a PTY-driven test as the proof — and no
   formal consumer matches on either code, so this is a note for R61 and P03, not
   a defect in the contract.
3. **The layering evidence is stronger than the sentence describing it.** `:324-326`
   glosses three deviations from the `thiserror`+`anyhow` split as one; ripgrep and
   fd are both carrier-only binaries and cargo-nextest is the same two-layer shape
   with `color-eyre`. Carried forward unchanged from my revision-2 audit.

## Assessment

Approve. The two findings I rejected revision 2 on are repaired, and I verified
the repairs rather than accepting the revision record's account of them. No
sentence, criterion, table row, owned-parameter clause or engines entry now
attributes to the org CLI Design Standard anything the standard does not cover:
the five configuration and input rows each carry one basis, the two that the
standard does not reach are labelled this template's choices in the artifact
consumers actually read, and both carry their reasoning and the cost if the choice
is wrong. The trace rule is gone from the owned parameter, and the route taken —
declining to publish rather than declaring the question answered — is better than
the repair I suggested, because it leaves the owner's F301 question with the owner.

**Would I stake the seven formal consumers on it?** Yes, without the reservation I
attached last time. The registry records R03, R52, R53, R54, R55 and R56 and R70
as consumers of `error-taxonomy-exit-codes` (`docs/port/PARAMETERS.md:16`), with
five further items coupled without consuming — R57, R60, R61, R66 and R05/R69 —
each named in the decision with the direction of the dependency. The staking case
rests on where the risk sits. The exit integers are org-locked and quoted exactly,
so the part R03 and R70 pattern-match against cannot move under them. The
catalog's shape — `#[non_exhaustive]` plus `ALL` plus a pinned-row coverage test —
is settled by the Cargo SemVer reference and is the one place this design is
defensibly stronger than either source repo; append-only means a code added later
never invalidates an existing match. The residual risk sat in the configuration
block, which is exactly where R52–R56 live, and that is what has changed since
revision 2: `RSLB203` and `RSLB204` no longer arrive with an argument that does not
close. They arrive as choices, with a rationale, a stated cost of one catalog row
and one match arm, and a named challenger in R55/R56. A consumer can now inherit
them knowingly or overturn them cheaply, which is the disposition a dependent
needs.

One structural fact the owner should carry forward rather than read as a caveat on
this verdict: every runtime property in this contract is unexecuted, on both
platforms. The decision says so twice, names eight proofs, and hands them to P03.
That is the correct posture for a P02 research decision — the eight items are its
validation set, not a gap in it — and the dependents are staking on a proposal
whose runtime half is proved in the implementation phase, exactly as the programme
intends.
