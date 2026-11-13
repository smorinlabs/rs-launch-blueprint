decision-sha256: 5935af16e9b1ba082099b20fa8ca84ee7aea49965feab702eb97477f484d6239
actor: audit-fable-2026-09-05T155503Z-4141a35b69e0
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: the owned parameter prescribes `command -v cargo-<sub>` as the presence test for the rustup-component class, where the PATH entry is an unconditional rustup proxy, so the test cannot fail — and the F181 BASELINE-REVIEW line asserts `command -v` is "provably the correct test for both tool classes", which the stub experiment does not establish; `## Engines` omits the presence-test disagreement although doxa/openai and doxa/gemini both took the opposite position, and rejecting mise does not dispose of openai's mise-independent half ("rustup component state"); the owned parameter is silent on Cargo aliases, a third invocation form used by two of the four reference `justfile`s the decision cites as showing "what all four surveyed justfiles do"

## Principle and agreement level

The stated principle is right and is stated at the right level. The decision
names one shared requirement — *one command reports exactly which dev tools are
missing with the exact remediation for each, and every repeatable task then
invokes those tools by a single stable name that does not depend on how they
were installed* — and sets the agreement level at **architectural pattern plus
policy**, not capability and not a specific tool. That matches spec §2's table:
the discover-report-remediate loop is a responsibilities-and-relationships
claim, and the invocation vocabulary is a deliberately shared mechanism. The
must-agree / may-vary split is explicit and correctly drawn: one presence-check
command, one remediation string, one invocation form per tool class and exactly
one authoritative tool list must agree; backend, tool count and tool identity
may vary and are left to R27–R29, R32, R37 and R40.

The fitness test spec §2 requires for a shared pattern is performed rather than
asserted, and it reaches a split answer with a structural reason: py's four
tools (`taplo`, `gitleaks`, `actionlint`, `yamlfmt`) sat outside `uv`'s reach
because `uv` installs Python distributions, whereas the Rust equivalents are
themselves crates that the primary package manager does reach, and rustup
reaches `rustfmt` and `clippy` by definition. The loop therefore survives and
the per-tool layer dies. That argument is independent of any repository count,
which is the right shape for a conclusion resting partly on a negative survey.

No `OVERRIDE` is owed. F183, F187, F188 and F189 are all `py-only` /
`DIVERGENT` rows assigned to R42 (`docs/port/COMMONALITY.md:187`, `:191`–`:193`),
so declining to port them is the item's decision to make, not a change to a
recorded shared pattern; the two `COMMON → REUSE` rows the decision touches
(F179, F181) are both **retained**, so no displaced pattern exists.

The decision's Status paragraph — every P02 decision is a proposal validated in
the implementation phase — reproduces the programme-wide ruling at
`docs/planning/p02/execution-ledger.md:213`, and its refusal to build the
template is correct under that ruling rather than a gap.

## Design and evidence

**Architecture before libraries.** Five architectures are compared before any
tool is named — toolchain file plus package-manager acquisition, polyglot
version manager, hermetic environment, per-tool installer recipes, in-repo Rust
automation — each with a stated reason for rejection tied to a principle or a
measurement, and a ranked runner-up (`xtask`, 2/17) that is admitted to leave
the parameter intact. The hermetic option is rejected on a template-specific
argument (it imposes a Nix installation on every downstream consumer and puts a
prefix on every recipe line), not on adoption, even though it has the *best*
declarative adoption in the sample (5/17). That is the correct direction of
reasoning under spec §2 and is evidence against selection-by-familiarity.

**The negative finding does not rest on the count alone.** I reproduced the
survey arithmetic from `evidence/repo-survey.log`: 9 `rust-toolchain.toml`,
5 `flake.nix`, 4 `justfile`, 0 `Makefile`, 0 across `mise.toml` / `.mise.toml` /
`.tool-versions` / `.flox`, over 17 named repositories with star counts. The
conclusions drawn from it are scoped in the decision's own words — "0 of 17
surveyed", "measured adoption in the surveyed Rust field", "any
declarative-provisioner argument in the Rust field has to be made against
`flake.nix`, not `mise.toml`" — never widened into "no Rust project uses mise".
It reproduces `raw/opus.md`'s independent 2026-09-05 measurement, `audit-codex`
reproduced it again on Linux, a re-verify trigger fires if a repeat survey finds
provisioner manifests in a material fraction, and the structural argument above
carries the conclusion on its own. A 0/17 result from top-star flagship
repositories bounds prevalence only loosely and the selection criterion is never
stated in prose — but every repository and its star count is in the cited log,
and the conclusion is not asserted more strongly than that. This is honest.

**Disagreement handling is by evidence, not by engine count**, and says so:
three of five engines recommended `mise` and the decision settles against them
by re-measurement, quotes openai's own concession verbatim against its own
position, catches gemini's `uv`/`dioxus`/`leptos` adoption claim failing against
`astral-sh/uv`'s actual repository root, and independently verifies
`cargo-run-bin` as at-risk where gemini rated its own stack "Extremely High"
confidence without assessing it. Gemini's bare `[cite: N]` markers and
perplexity's four missing top-level fields are both handled by *limiting* what
those reports are counted for rather than by discarding them, and perplexity's
one checkable figure (`mise` `rust-version` 1.85) is verified and corrected to
1.95. One disagreement is nonetheless missing — Finding 2.

**The licence exclusion is correctly a ruling, not an assertion, and it is
decidable as posed.** `docs/port/PARAMETERS.md` words gate 1 as "candidate
**crates** must be compatible", and `cargo-binstall` is a separate process
linked into nothing, so the gate's reach is genuinely a reading of a fixed
owner parameter and not an evidentiary question. The decision gives the owner
what a ruling needs: the verified fact (`1.23.0`, `GPL-3.0-only`,
`2026-09-05T16:59:01Z`), both readings with their advocates, the consequence of
each (the recipe *body* changes on one line; no invocation line anywhere
changes), a licence-clean default that is valid under either reading, a named
prebuilt alternative if compile time proves unacceptable
(`cargo-quickinstall` 0.3.53, `MIT OR Apache-2.0`), and the cost it is paying
meanwhile (one source compile per tool). Recording opus's mere-aggregation
argument and *not adopting* it is the right call: adopting it would have settled
an owner parameter's scope inside a research item.

**Empirical claims match what was run.** Check 3 exercises Cargo's documented
custom-subcommand dispatch against a stub with a working negative control; check
4 proves the toolchain-file override and component availability; check 8 reads
four maintained projects' committed files. The one place the host cannot support
the claim — whether `cargo fmt` routed *through* the rustup proxy, given
Homebrew's `cargo`/`cargo-fmt`/`cargo-clippy` shadowing it on `PATH` — is
flagged three times (check 4's caveat, the hazard note, unproven item 2) and
turned into evidence *for* the `cargo <sub>` half of the parameter rather than
suppressed. Nothing recommended is claimed to have been built.

## Completeness

Present and correct: the four required H2s in order with `### Principles and
implementation` nested under `## Decision`; `re-verify: 2027-03-10` plus six
named earlier trigger events; settled rows F183 (decided), F187/F188/F189 (not
adopted) with verdict strings left to the controller as `docs/port/README.md`
requires; the owned parameter and four assumed fixed parameters quoted with
their registry values; an explicit statement that no `CONFLICT:` line is owed,
with the reason (`- consumes:` is empty and no raw report raised one); toolchain,
OS, UTC convention, working directory and the two scratch files written outside
the repository; all six fitness gates answered per candidate with `inapplicable`
plus a reason where inapplicable, never silently skipped; the prompt's full
figure table with endpoints and the `search/issues` `total_count` rule honoured;
maintenance state by the prompt's rubric with `at-risk` resting on concrete
signals rather than the six-month trigger.

Both `BASELINE-REVIEW:` lines carry the runbook's four fields
(`F### — principle — proposed change — evidence`) plus an `Affected:` list, and
both are responsive to what `docs/port/BASELINE-REVIEW.md` actually asked. F179
was recorded there (`:276`) as needing Make justified "against R42 rather than
asserting it as the only dependency-free entry point"; the decision retains the
layering and answers with a measurement (0/17 root `Makefile`) that concedes the
ecosystem cost instead of defending the assertion. F181 was `blocked pending
R42` (`:86`, `:316`) with "may collapse into F180"; the decision retains it as a
distinct Level-2 check on a disjoint-scope argument. Neither edits the ledger,
which is the controller's to adjudicate (RUNBOOK §4). The F190/F103 handling
matches the reconciliation record's "channel decided by R27 with R42"
(`docs/port/BASELINE-REVIEW.md:258`, `:311`): the decision recommends `profile`
and `components` only, marks layer 1 as evidence rather than a settled row,
hands R27 the measured channel evidence (8 of 9 pin an exact version), and
labels it a coordination note rather than a `CONFLICT:`.

The ten unproven items are honest and, with one exception, complete. Each names
what would prove it; the list covers the Linux gap, proxy resolution, the whole
loop, the acquisition backend, the compile-time cost the licence-clean choice
buys, the unenforced prohibition, R27's channel, the unmeasured issue-response
medians, and — the hardest one to write — layer 4, which has zero occupants, no
reference implementation composing it, and a quoted counter-recommendation from
`ubi`'s own maintainer that per-project tooling should use `mise` instead. Item
7 correctly classifies the licence gate as not researchable. The exception is
the presence-test soundness question, which is neither proven nor listed
(Finding 1), and the invocation rule's silence on Cargo aliases (Finding 3).

`audit-codex` is consistent with the decision: it reran the survey, mechanism,
registry, GitHub, RustSec and reference reads on Linux/arm64, matched every
displayed figure, reproduced the negative control, and its Linux run resolves
unproven item 2's hazard (there `cargo` *is* the rustup proxy). Its HTTP 403 →
200 User-Agent retry is disclosed as an access condition, not a changed claim.
It does not reach the three findings below, which are judgment questions about
the parameter's text rather than reproduction questions about the logs.

## Findings

**1. The owned parameter prescribes a presence test that cannot fail for the
tool class it explicitly names, and the F181 line overstates what was proven.**

`## Parameters` sets `package-manager-invocation` to include: "presence tested
with `command -v <executable>`, where the executable is `cargo-<sub>` for the
first class" — and the first class is defined as "any tool whose executable is
named `cargo-<sub>` — **including the rustup components rustfmt and clippy**".
The `BASELINE-REVIEW: F181` line then asserts that "`command -v` is **provably
the correct test for both tool classes** because Cargo dispatches `cargo <sub>`
to a `cargo-<sub>` executable found on `PATH`", citing the stub experiment.

The stub experiment proves PATH dispatch for a *crates.io-installed* cargo
plugin, and `command -v cargo-<sub>` is sound for that subclass, where the
binary in `$CARGO_HOME/bin` is the tool. It does not extend to the rustup
components. There the `PATH` entry is an unconditional rustup **proxy**,
installed for a fixed name list whether or not the component exists in the
selected toolchain. Verified on this host, read-only, 2026-09-10T05:56:58Z:

- `ls -la ~/.cargo/bin/cargo-fmt` → `cargo-fmt -> rustup` (a symlink to the
  rustup binary, not to any rustfmt build).
- `ls ~/.rustup/toolchains/1.97.1-aarch64-apple-darwin/bin` → `cargo`,
  `rust-gdb`, `rust-gdbgui`, `rust-lldb`, `rustc`, `rustdoc` — no `cargo-fmt`,
  no `cargo-clippy`.
- `rustup which --toolchain 1.97.1-aarch64-apple-darwin cargo-fmt` → exit 1,
  `error: 'cargo-fmt' is not installed for the toolchain
  '1.97.1-aarch64-apple-darwin'.`

So for a toolchain lacking the component, `command -v cargo-fmt` still resolves
the proxy and exits 0 while `cargo fmt` fails. The prescribed test reports
present for a tool that does not run, which is precisely the silent false-pass
acceptance criterion (A) — "prints one `MISSING <tool> -> RUN <command>` line
per absent tool" — is written to prevent. The decision's own evidence contains
the shadowing half of this (`evidence/invocation-mechanism.log` records
`command -v cargo-fmt` → `/opt/homebrew/bin/cargo-fmt`) without drawing the
inference; `raw/opus.md:1214` even states that "rustup places component proxies
there" and likewise does not.

Severity, stated honestly: layer 1's `components = ["rustfmt", "clippy"]` in
`rust-toolchain.toml` makes rustup install the declared components on first
in-directory use, so within the recommended design the test is **vacuous rather
than dangerous**. The defect is in the published parameter text, which six items
consume and which is not scoped to the recommended design.

What would resolve it: either (a) exclude the rustup-component class from the
presence test and state why (the toolchain file already guarantees it), or (b)
use for that class the sound checks this decision **already ran** in check 4 —
`rustup component list --installed` and `rustup which cargo-fmt` — and reserve
`command -v` for the crates.io-installed class the stub experiment covers.
Either way the F181 line's "provably the correct test for both tool classes"
needs narrowing to the class the experiment actually covers.

**2. `## Engines` omits the presence-test disagreement, and rejecting `mise`
does not dispose of the mise-independent half of it.**

RUNBOOK §5 requires `## Engines` to record "all reports and evidence checks,
disagreements, and the evidence that resolved each disagreement". Five
disagreements are recorded (provisioner, wrapper prefix, `cargo-run-bin`,
`cargo-binstall`'s licence, per-tool versus generic recipe). A sixth exists and
is not recorded, although the decision emits a `BASELINE-REVIEW:` line settling
it. Two of five engines opposed the `command -v` loop:

- `raw/doxa-openai.normalized.md:201`, verbatim: `BASELINE-REVIEW: F181 —
  verify declarative state rather than search ambient PATH — keep check-deps
  distinct from F180/bootstrap, implementing it with mise ls --missing and
  rustup component state rather than a command -v loop — this item therefore
  does not collapse F181 into F180.`
- `raw/doxa-gemini.normalized.md:48`: "Eliminate the `command -v` loop presence
  tests in `check-deps`."

Disagreement 1 settles `mise` against openai, which disposes of
`mise ls --missing`. It does not touch "**rustup component state**", which
depends on no provisioner and is exactly the sound test Finding 1 calls for on
the class the parameter names. The decision instead asserts the opposite
position — `command -v` is "provably the correct test for both tool classes" —
without recording either engine's contrary line or rebutting its rationale
("search ambient `PATH`"), which is the rationale my verification confirms.

What would resolve it: record the disagreement in `## Engines` with openai's
line quoted, separate its mise-dependent half from its mise-independent half,
and state which part survives disagreement 1 and on what evidence.

**3. The owned parameter is silent on Cargo aliases, a third invocation form
used by two of the four reference `justfile`s cited as proving the rule.**

The rule keys strictly on an executable name: "`cargo <sub>` for any tool whose
executable is named `cargo-<sub>`; a bare `<tool>` binary resolved on `PATH` for
every other tool". Answering the MEDIUM question the decision writes: "it is
what all four surveyed `justfile`s do — zero wrapper-prefix lines across `oxc`,
`biome`, `just` and `cargo-binstall`". The zero-prefix count is true and I
verified it against `evidence/reference-impls.log`. The wider claim that those
four exemplify the split rule is not: `oxc`'s justfile lines recorded in that
same log — `51: cargo ck {{args}}`, `60: … cargo lint {{args}}`,
`40: cargo lintgen`, `307: cargo lint-timings` — are **Cargo aliases**, not
PATH-dispatched executables. `oxc-project/oxc` `.cargo/config.toml`, retrieved
2026-09-10T05:55Z, defines `[alias]` with `ck = "check --all-features
--all-targets --locked"`, `lint = "clippy --all-targets --all-features"`,
`lintgen = "run -p oxc_linter_codegen"` and `lint-timings = "run -p
oxc_track_linter_timings --profile coverage --"`. `casey/just`'s
`19: cargo lclippy` is the same shape; its root `.cargo/config.toml` returns 404
so the alias location is unverified and I do not assert it.

Under the parameter as written, `cargo lint` matches neither permitted form
(there is no executable named `cargo-lint`), and its prescribed presence test,
`command -v cargo-lint`, resolves nothing. A consuming item — R28 in particular,
whose clippy invocation is exactly this shape — cannot tell from the parameter
whether an alias is permitted, and if it is, which executable the presence test
should target (`cargo-clippy`, presumably, but that is a guess).

What would resolve it: one clause in the parameter saying whether a Cargo alias
defined in `.cargo/config.toml` is a permitted spelling of the `cargo <sub>`
form and, if so, what the presence test targets; and narrowing the "what all
four surveyed justfiles do" sentence to the claim the log supports (zero wrapper
prefixes).

## Assessment

**Reject**, on three findings, all of them in the text of the owned parameter
and its supporting `BASELINE-REVIEW` line rather than in the research behind
them. The recommendation itself follows from the evidence and not from
familiarity: it rejects the option with the best declarative adoption in its own
sample (`flake.nix`, 5/17) on a template-specific argument, settles against
three of five engines by re-measurement rather than by vote, refuses to adopt
the reading of a fixed parameter that would have been convenient
(`cargo-binstall`), and repeats the maintainer's own counter-recommendation
against a component it nonetheless names. That is the opposite of a
familiarity-driven answer, and the fix required here is narrow.

Recorded explicitly so they are not re-litigated on the next revision, these are
**not** findings: the 17-repository survey carries what it is used for, because
its conclusions are scoped in the decision's own wording, corroborated by an
independent structural argument, reproduced twice, and fitted with a re-verify
trigger — the unstated selection criterion and the loose prevalence bound of a
0/17 top-star sample are worth a sentence in a future revision, not a rejection;
the licence exclusion is correctly recorded as an owner ruling rather than
asserted, and it is posed in a form the owner can decide, with both readings,
the one-line consequence and a clean default named; both `BASELINE-REVIEW:`
lines are in the runbook's four-field form, are responsive to what
`docs/port/BASELINE-REVIEW.md` asked of R42, and leave verdict strings and
ledger edits to the controller; the F190/F103 coordination matches the
reconciliation record; the ten unproven items are honest, including layer 4's
zero occupants and its maintainer's advice against it; and building nothing is
correct under the programme-wide research-only ruling, not a deficiency.

The three findings are independent of the recommendation's substance. Fixing
them means narrowing one clause of the parameter's presence test (or replacing
it with the rustup checks the decision already ran), adding one disagreement to
`## Engines`, and adding one sentence on Cargo aliases. None requires new
research, and none disturbs the five-layer stack.
