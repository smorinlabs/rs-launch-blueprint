decision-sha256: 3131e895187c096c8866f0f7b4a520549804cd67b32f848b6239cd652b636281
actor: audit-fable-2026-09-17T020714Z-98ef5e1e7d37-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

This audit binds revision 1 of
`research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md` at the hash
above, recomputed with `/usr/bin/shasum -a 256` immediately before writing and equal
to the hash in the task message. No prior judgment audit of this item exists: before
writing, `review/` held `DECISION.md` and `evidence/` only. The empirical (Codex)
audit is deferred, so `review/audit-codex.md` is absent and this approval is the
first of the two verdicts acceptance needs.

Read end to end for this audit: `docs/superpowers/plans/p02-roles/judgment-auditor.md`;
`inputs/prompt.md`; `raw/codex.md` (123 lines) and the parts of `raw/opus.md` (1,207
lines) the decision carries, renumbers or attributes; `review/DECISION.md` in full;
`review/evidence/r61-claims.log`, `r61-claims-rerun.diff` and the sections of
`r61-claims.sh` that produce sections 12 and 13; `research/RUNBOOK.md` §4-§5;
`research/topics/67-error-and-exit-code-contract/DECISION.md`; `AGENTS.md`;
`docs/port/OWNER-REVIEW.md`; `docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md`
rows F275-F280, F299 and F360; `docs/port/BASELINE-REVIEW.md`; the governing spec §2
agreement-level table; and the org CLI Design Standard v1.4.14 at blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7`. The evidence script was **read, not
rerun**, as the task requires. Independently of the script I recomputed the standard
blob's hash, read its five cited lines, read both pinned source trees at
`b08bccfb` (py) and `cb1cbcb2` (ts), searched for an `OV-02` collision, and read
`crossterm-0.29.0` and `inquire-0.9.4` in the local cargo registry.

## Principle and agreement level

**The requirement is stated once and at a level the spec actually defines.** The
shared requirement — ask a human only when a human is demonstrably there, ask on
stderr, behave predictably and documentedly when nobody is there — is decomposed into
six principles, each carrying its source and its level. The spec's own table
(`docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md:43-47`) names
`Capability or standard` and `Architectural pattern` as levels; P1-P4 are labelled
`standard` and P5-P6 `capability`, which are the two halves of that single row used
where each applies, not an invented compound and not a level the spec does not have.
Each `standard` principle names the rule that makes it one, and I read all four at
the blob rather than accepting the quotation:

- `:381` (R7.1) does carry "fd 2 (stderr) carries everything else: diagnostics,
  progress, prompts, warnings, and errors" — the decision's bolding of `prompts` adds
  emphasis, not words.
- `:456` (R8.1) carries the destructive-confirm `MUST`, the non-interactive bypass,
  the `SHOULD NOT` against opening `/dev/tty` "for surprise prompts when stdin is not
  a TTY", the documentation-and-disable obligation if a tool does it anyway, and
  "Under `--no-input` with no required bypass flag, the command **MUST** fail rather
  than guess".
- `:461` (R8.2) carries the no-TTY `MUST`, the "it uses provided flags/env or fails"
  clause and the exit-`2` assignment for missing non-auth input or consent.
- `:472` (R8.5) carries "Under `--no-input`, they **MUST** fail rather than prompt".

The blob hashes to `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f`
over 773 lines, which is the value the decision asserts through check `C8a`. Gate 1
is correctly recorded `inapplicable` against the 2026-09-12 owner ruling
(`docs/port/OWNER-REVIEW.md:47`) and no candidate is ranked on licence.

**The must-agree / may-vary split is the right shape and survives a source read.**
What must agree is behaviour (a confirm exists, `--yes` is the consent bypass, no
prompt byte on stdout, a headless run terminates with a defined outcome, `^C` ends at
130, an empty selection is success); what may vary is the widget library, its theme,
its key bindings and the concrete return type. I checked the one cross-repo claim the
gate rests on and it is exact: `ts: src/commands/projects.ts:146` at pin `cb1cbcb2`
reads `const interactive = opts.input !== false && deps.stdinIsTTY && deps.stderrIsTTY;`
— literally the same three inputs the Rust gate conjoins, so "the principle is
preserved at the same level with the same three inputs in both ecosystems" is a
verified statement, not a rhetorical one.

**The shared architectural pattern is re-justified rather than inherited.** ts's
pattern is a prompt behind one injectable seam (`ts: src/lib/adapters.ts:22`,
`export type Prompter = (message, choices) => Promise<Project[]>`, with `realPrompter`
at `:41` dynamically importing `@inquirer/prompts` and passing
`{ output: process.stderr }` — both read at the pin). The decision asks whether that
pattern still fits Rust, answers with a dyn-compatible trait erased at the
composition root, and ties it to R01's already-decided seam shape rather than to
familiarity. It then names three things the seam buys that this item specifically
needs, one of which — reversibility at one file — is the honest answer to the
weakest figure in the whole recommendation (`inquire`'s maintenance). That is the
mandate's ordering: principle, then ecosystem realization, then library.

## Design and evidence

**Alternatives were compared before libraries, and the decisive one was rejected on
an observation.** Architectures A-E are genuine alternatives (no dependency;
hand-rolled; split; one crate behind a trait; one crate with the gate delegated), not
a menu built around a predetermined winner: A is rejected against R8.1 plus this
template's own `config set`, B on F280 alone, C on carrying two input models and two
cancellation stories. E — delegate the gate to the crate — is the one that would
change the bundle's membership, and it is rejected "impossible as specified" on an
executed result rather than on a reading.

**The PTY spike is recorded with enough provenance and it grounds the claim it is
cited for.** `r61-claims.sh` section 13 builds a throwaway binary pinned to
`crossterm = "=0.29.0"` and `console = "=0.16.6"`, prints
`std::io::stdin().is_terminal()`, `std::io::stderr().is_terminal()`,
`console::Term::stderr().is_term()` — annotated in the script as the exact predicate
`dialoguer 0.12.0 src/prompts/multi_select.rs:204-205` tests — and the result of
`crossterm::terminal::enable_raw_mode()`. Case A runs it with stdin from `/dev/null`
and no controlling terminal; case B runs the same binary under `pty.fork()` with
stdin re-`dup2`'d to `/dev/null` so stdin is not a TTY while stdout and stderr are the
pty. The log prints both results verbatim: case A `crossterm_enable_raw_mode=Err
kind=Uncategorized raw_os_error=Some(6)`, case B `stdin_is_terminal=false`,
`dialoguer_guard_term_stderr_is_term=true`, `crossterm_enable_raw_mode=Ok`,
`child_exit_status=0`. Three properties make this sufficient rather than suggestive:
case A is a real negative control (`ENXIO` is errno 6, so the `/dev/tty` open failed
for want of a controlling terminal, not for want of a call); the two cases differ in
exactly one variable; and the source reads that explain the mechanism
(`crossterm`'s `tty_fd()`, `console`'s `Input::unbuffered()`, `dialoguer`'s
output-terminal guard) are labelled as reads, checks `C3a`-`C3f` and `C6b`, and are
never presented as executed. The conclusion the decision draws — the R8.1
surprise-prompt case is reachable, `dialoguer`'s own guard waves it through, and no
candidate crate prevents it, so the gate is a bundle member and not an implementation
detail — is exactly what those two rows support, and it does not overreach into the
template's own behaviour, which U5 explicitly records as unprovable here.

**The crate selection follows from the prompt's own weighting, not from popularity or
engine agreement.** `dialoguer` wins downloads (16,348,116 against 4,978,577 in 90
days), reverse dependencies, maintainer activity and cost; the decision says so in
its own voice, twice, and measures the cost like-for-like rather than accepting the
Opus raw's unlike 32-against-8 comparison — three manifests differing in exactly one
dependency line, 9 / 35 / 11 packages, a 24-package gap named "the strongest argument
for `dialoguer`". Against that it puts three things `dialoguer` cannot supply: the
value-returning multi-select and the no-public-path-to-stdout property, which are the
two halves of the prompt's HIGH question, and R67's `RSLB903`, whose alternative is
retiring a published catalogue row to accommodate a dependency. Two of those three
answer questions the prompt marks HIGH, so the ranking is prompt-weighted. The
decision then states that this is the judgement most likely to be overturned, names
the reviewer weighting that reaches `dialoguer`, and wires the re-verify triggers to
the signals that would flip it. Recording uncertainty at that grain is what the role
doc asks for, and it is the right disposition for a two-horse field that the decision
declines to describe as having a dominant choice.

**The empirical work verifies claims without implementing the recommendation.** The
three spike manifests carry the exact recommended dependency line —
`inquire = { version = "0.9.4", default-features = false, features = ["crossterm", "macros"] }`
— through `cargo generate-lockfile` and `cargo tree`, which satisfies the runbook's
"version-pin recommendations must execute" without building anything from the
template. Everything created lives under `$TMPDIR` and is removed by the script's
`EXIT` trap; no Rust file, `Cargo.toml` or seam was added to this repository.

**Every source citation I sampled is exact at its pin.** At `b08bccfb`:
`config.py:180-183` is the `[dry-run] would set …` block, `config.py:193-203` is the
`confirm(...)` guard ending `raise SystemExit(int(ExitCode.INTERRUPT))`,
`config.py:82-83` is `if assume_yes: chosen = current`, and `errors.py:45,55` are
`INTERRUPT = 5` and `ERROR_CODE_INTERRUPT = "PLBP004"`. `options.py:265-278` is the
whole `confirm()` ladder — `assume_yes` returns `True`, `app.no_input` raises
`ConfigError` with the hint "pass --yes to confirm non-interactively" (the wording the
decision reuses), then `click.confirm(prompt, default=False, err=True)`. At
`cb1cbcb2`: `projects.ts:166-168` is the select-all `else` branch and `:170-174` is
the empty-selection stderr notice with a bare `return`, and the `Choice`-style pairs
at `:157-163` are `name: \`${project.name} (${project.workspace.name})\`` with
`value: project` — which is why the decision's proposed `ProjectChoice(Project)`
`Display` of `"{name} ({workspace})"` is parity rather than invention.

**OV-02 is a legitimate override, correctly formed and correctly numbered.** It is a
departure from a recorded source pattern (py's exit `5` on a declined confirm), which
is what `AGENTS.md` asks be tracked, and the decision separates that sense from the
ledger verdict `COMMON → OVERRIDE (OV-nn)` that is legal only for origin `same` — no
ledger row moves and F276 stays `DIVERGENT`. The format is present: the heading
carries `OVERRIDE (OV-02)`, `**Argument:**` states py's mechanism with its pin and
the reason rs cannot copy the integer, and `**Options:**` lists four with the effect
of each, the chosen one marked, plus a cost-if-wrong line. The numbering is right:
OV-01 was requested 2026-09-12 and refused 2026-09-14 (`docs/port/OWNER-REVIEW.md:72-89`)
and is retired-not-deleted in R60's decision, and my own search over `docs/port/` and
every `research/topics/*/DECISION.md` found `OV-02` nowhere; the only occurrences
anywhere in the tree are inside R60's evidence logs, as the negative assertion
`OVERRIDE (OV-02..OV-09) declarations: 0`.

**The R67 mapping is correct on R67's published text.** R67 publishes the exit
taxonomy `0` success … `5` conflict and the catalogue rows `RSLB501` conflict/
precondition failed → 5, `RSLB205` "required non-auth input or consent missing because
prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin" → 2,
`RSLB903` prompt interrupted by Ctrl-C → 130, and the rule that no prompt-local
Ctrl-C handler may be installed; it states that ESC-versus-`^C` is "a product
question for R61" and its own re-verify trigger reads "`RSLB903` is wired to a typed
variant or retired before first release". Mapping a declined confirm onto `0 success`
with no catalogue row is therefore right on three counts: the envelope R67 defines
carries the code, and a declined confirm emits no envelope; the only near row is
`RSLB501`, whose published meaning would relabel a deliberate "no" as a precondition
failure; and the catalogue is append-only, so option (d) is correctly parked as an
escalation rather than taken. One consequence the decision leaves implicit and I
state here for the controller: the exit-`0` decline is reachable only when the gate
is true, i.e. with a human at the terminal, so it cannot be reached by a script that
would then misread success — the non-interactive paths all route to `RSLB205`/2.

**F360's handling is right, procedurally and substantively.** I counted the rows
myself: `docs/port/BASELINE-REVIEW.md` contains zero rows whose first column is F360,
and `docs/port/COMMONALITY.md:364` carries F360 as `DIVERGENT`, area
`cli-framework-ux`, item R61. A `BASELINE-REVIEW:` line adjudicates an inherited
baseline; against this item's own `DIVERGENT` row it is this item's scoped question,
and R19's decision (`research/topics/19-dependabot-config-shape/DECISION.md:69,350`)
established exactly that treatment for a Codex line against F054. The runbook's rule
that the controller adjudicates such findings is satisfied rather than bypassed: the
line is quoted verbatim under `## Engines`, its disposition is argued in four
sentences, and the part not adopted — replacing ts's select-all with refusal — is
refused on stated grounds (R8.2 is engaged by *missing* input; on a read-only listing
the complete result is the non-interactive answer) plus the correct no-authority
rule, so nothing is silently dropped. The scope condition is the substantive honour
of Codex's concern, and it is load-bearing rather than decorative: it is stated twice,
in the class table's neighbourhood and again under `## Engines`, and it names the case
that flips — a multi-select feeding a mutation is consent and takes `RSLB205`.

**The five disagreements are settled on grounds, in both directions.** 1 (crate) is
settled for Opus on three re-verified grounds with the cost restated and the
uncertainty declared. 2 (can the crate detect it) is settled by execution, and the
decision fairly notes that Codex's *design* already put an application-owned gate in
front of the crate even where its sentence did not. 3 (advisories) is settled by a
positive control — `atty` returns 200 and its body names `RUSTSEC-2021-0145` while
all six candidates return 404 — which converts Codex's declared blocking gap into a
closed one rather than waving it away. 4 is F360, above. 5 is settled **against** the
Opus raw and for Codex's classification, on the controller's ruling that I read at
`docs/planning/p02/execution-ledger.md:414` ("RULING WITHDRAWN: fitness gate 2 is read
strictly"), with Opus's two contract-fit findings kept but recorded separately so the
gate-versus-fit distinction survives, and gates 4 and 6 left `unverified` for both
excluded crates rather than assumed. A synthesis that overrules its own family's raw
on a rule neither raw applied is the opposite of deciding by agreement.

## Completeness

**Structure.** The four required H2s appear once each and in the runbook's order —
`## Decision` (17), `## Parameters` (295), `## Empirical check` (310), `## Engines`
(356) — with no `## Supersedes`, correct for a revision 1 that reverses nothing.
`## Decision` carries `### Principles and implementation` and a `re-verify:` line, as
`research/RUNBOOK.md:183-190` requires. `## Empirical check` states toolchain, OS,
working directory, command and observed output.

**Parameters.** The four `- assumes` lines reproduce the registry values byte for
byte (`docs/port/PARAMETERS.md` rows for `msrv-policy`, `rust-edition`,
`target-os-matrix`, `license`), and I confirmed byte-identity a second way: `diff`
and `cmp` of R61's four lines against the four published in
`research/topics/63-progress-spinner/DECISION.md` report no difference, and R65, R66
and R85 carry the same set. There is no `- owns` line, which matches the prompt's
empty `- owns:`, and no `CONFLICT:` line, which matches a recommendation that needs no
registered value changed. Explaining R67 in prose **without** an `- assumes` line is
the right call: the prompt's `- consumes:` line is empty and its `## Couplings`
classifies R67 as `related (not a registry dependency)`, so an `- assumes` line would
register a dependency the prompt does not declare, and every published sibling
decision carries exactly the four fixed parameters and nothing else. The decision
still binds itself to `RSLB205`, `RSLB903`, `RSLB101`, `RSLB000` and the
no-prompt-local-handler rule, and re-reads them from R67 this run, so the prose
carries the obligation the missing line would have carried.

**The evidence numbers are stated within what the logs show.** The log's own footer
reads `TOTAL  pass=97  fail=0  skip=0`, and an independent count of lines beginning
`PASS` gives 97 and of lines beginning `FAIL` gives 0; the three occurrences of the
string "skip" in the log are the `prompt_skippable` check names and the footer, not
skipped assertions, so "97 assertions pass, 0 fail, 0 skip" is exact. The rerun diff
is 26 lines and shows exactly three changed lines — the `executed at` timestamp and
two `$TMPDIR` paths carrying the script's PID inside `cargo tree -d` output — which
is what the decision says it shows. The comparison rule matters more than the diff,
and it is stated as a rule (which fields vary by design, which must not vary and are
each an assertion) before the diff is reported, with the explicit caveat that a
one-minute interval is evidence the stable set is stable and not a claim that the
volatile set never moves. The one figure that moved against a raw (`jdx/demand` 257 →
258) is reported rather than absorbed.

**The unproven rows are honest and correctly scoped.** Acceptance criteria 1-9 are
labelled "the contract" and immediately "**None of them was executed**", with U1-U4
naming the harness that would prove each and which four need no pseudo-terminal. U5
states plainly that section 13 proves the crate's behaviour and cannot prove the
template's, because the template does not exist. U3 records that R67 declared the same
`RSLB903` gap and that this run did not close it either — a decision volunteering that
it failed to close a predecessor's gap is the behaviour this role exists to reward.
U6 marks the duplicate measurement as a spike rather than the workspace, U8 keeps
gates 4 and 6 unverified for the excluded crates, U10 and U11 name the unmeasured
responsiveness and the shallow `promkit`/`requestty` reads. Under the role doc a
research decision must not implement its own recommendation, and this one declines
to, correctly.

**The MSRV discrepancy is handled honestly.** U9 states both numbers — `inquire`'s CI
declares `MSRV: 1.82.0` while its published 0.9.4 manifest declares
`rust-version = "1.80.0"` — declines to reconcile them, and explains why no gate
result turns on either: both halves of gate 2 exist (a declaration and a CI test),
both numbers sit far below the 1.96 floor, and the number that actually binds is the
measured tree maximum of 1.85.0 (`unicode-segmentation`), not either declaration.
Reporting a discrepancy in the recommended crate, in a decision that excluded two
rivals at the same gate, is the asymmetry-resistant behaviour; the only cost is that
the gate-2 row itself says "CI matrix runs an `msrv` job" and the reader meets the two
numbers thirty lines later at U9.

**Figures carry endpoint and date.** The registry and repository table names its four
endpoints and their fields, including the required `search/issues` `total_count`
rather than `open_issues_count`, and states that every number was re-retrieved
2026-09-17; the practice-evidence table names `GET https://api.github.com/repos/<o>/<r>`
with `stargazers_count` and 2026-09-17, and attributes each figure it did not
re-retrieve to the raw that did. The `Dates` paragraph reconciles the raws' one-day
disagreement as host-local versus UTC stamps of the same instants, which is correct
for a run whose identifier is `2026-09-17T020714Z`. Two exceptions are recorded below
as JF-1 and JF-4.

## Findings

Unresolved findings: **none**. None of the five entries below is blocking: no entry
changes a ground, a gate result, a parameter value, a ledger row, an acceptance
criterion, an exit-code mapping or a figure, none misstates what the evidence shows,
and none of them moves the recommendation. All five are recorded so the controller
and any revision can see they were weighed rather than missed.

**JF-1 — the retrieval instant named in the preamble belongs to a run that was not
filed.** `## Decision`'s `Dates` paragraph says "every figure this decision cites was
re-retrieved by this synthesizer's own check, which recorded `2026-09-17T05:23:18Z`".

*The problem.* That string appears in no filed artifact. `review/evidence/r61-claims.log`
records `executed at   : 2026-09-17T05:43:30Z (UTC)`, and `r61-claims-rerun.diff`
records the earlier of the two compared runs as `2026-09-17T05:42:12Z`. So the
paragraph names a third, earlier execution that is not the one whose output is filed —
while `## Empirical check` insists, correctly, that "the cited log is the output of the
run whose diff is recorded here, not of an earlier run". The two statements do not
agree about which run supplies the figures.

*Why it is not blocking.* Both instants fall on 2026-09-17 UTC, which is the date every
figure table already carries, so no figure's stated retrieval date changes. Every
number in the decision is an assertion in the filed log, all 97 of which pass in the
filed run, so the figures are re-established by the artifact that was filed regardless
of which run first produced them. The repair is one date: quote the filed log's
`05:43:30Z`, or say that an earlier run recorded `05:23:18Z` and the filed run
supersedes it.

**JF-2 — the two signal-handler claims about the recommended stack are carried from
the Opus raw without a check identifier or a source citation, while the symmetric
claim that excludes a rival carries one.** The decision asserts that "`inquire`
installs no signal handler" and that "`crossterm` registers only `SIGWINCH`, a signal
R67 does not handle"; neither sentence cites a file, a line or a check.

*The problem.* Those two claims carry R67's no-prompt-local-handler rule for the
recommended stack, and that same rule is what excludes `demand` — where the decision
does cite source and a check (`src/ctrlc.rs`, the `signal_hook::consts::SIGINT`
import held in a `static LazyLock<RwLock<…>>`, check `C7e`). The evidence script
never touches `crossterm`'s or `inquire`'s signal surface, so the rule is applied with
executed-and-cited evidence against the excluded crate and with uncited carried prose
in favour of the selected one.

*Why it is not blocking.* I verified both claims myself in the local cargo registry
rather than inferring them. `crossterm-0.29.0/src/event/source/unix/tty.rs:72`
registers `libc::SIGWINCH` (with the `rustix` `Signal::WINCH` arm beside it) and
`mio.rs:48` constructs `Signals::new([signal_hook::consts::SIGWINCH])`; a search of
the whole `crossterm-0.29.0/src` tree for `SIGINT` returns nothing, so the only signal
crossterm registers is `SIGWINCH` and R67's `SIGINT`/`SIGTERM` flags are untouched.
`inquire-0.9.4/src` contains one occurrence of the string "signal", in a doc comment
in `error.rs`, and no handler installation of any kind. Those are exactly the file and
line numbers the Opus raw cites, so the decision is carrying a true, sourced claim and
has merely dropped its citation in transit. The fix is to restore the two file:line
references, or to add the one-line check.

**JF-3 — check `C12h`'s predicate establishes less than its label and than the
sentence that cites it.** The decision states that resolving `inquire` beside R67's
`signal-hook` produces "**exactly one duplicated package** (checks `C12f`-`C12h`)".

*The problem.* `C12h` computes `grep -c '^signal-hook v'` over `cargo tree -d` output
and asserts the count equals 2. That proves two `signal-hook` majors are listed; it
does not by itself exclude a second duplicated package, since any other duplicate
would leave the count at 2. The check's own label — "signal-hook is the ONLY
duplicated package" — claims the stronger property its predicate does not test.

*Why it is not blocking.* The script prints the complete `cargo tree -d` output into
the log before asserting, and the printed output contains exactly two stanzas, both
`signal-hook` (`v0.3.18` via `crossterm` and `signal-hook-mio`, `v0.4.4` direct), so
the stronger claim is verifiable by inspection of the filed evidence and is true for
this resolution. The companion claim for the runner-up is asserted correctly, on
`cargo tree -d`'s own "nothing to print" (`C12i`). U6 already records that all of this
was measured on a spike manifest rather than on the template's workspace, and asks P03
for a CI step asserting exactly one duplicate — which is where the stronger predicate
belongs. A `wc -l` over the non-blank stanza heads would close it here.

**JF-4 — the two reverse-dependency totals are the only figures whose endpoint is not
named.** "Reverse-dependency totals, same endpoints: `dialoguer` 2,356, `inquire`
1,061 (both raws agree)" follows a table whose header names
`GET https://api.github.com/repos/<o>/<r>` and `stargazers_count`.

*The problem.* Reverse-dependency counts do not come from that endpoint. The intended
referent is the "crates.io reverse-dependency listing" named in the same table's
Source column, but the literal URL
(`https://crates.io/api/v1/crates/<name>/reverse_dependencies`) appears nowhere in the
decision and the two totals carry no retrieval date of their own, against a prompt
whose constraints say every number carries its endpoint.

*Why it is not blocking.* Both raws carry the endpoint explicitly — the Codex raw
cites `…/reverse_dependencies?per_page=10` retrieved 2026-09-16 and the Opus raw
`…/reverse_dependencies` retrieved 2026-09-17 — and report the same two totals, which
the decision states. The figures are traceable, agreed by two engines, and load-bearing
only for the sentence that calls both crates mainstream, a conclusion the download
figures carry independently.

**JF-5 — the per-candidate fitness-gate table covers the shortlisted prompt crates but
not the bundle's other two members.** The gate table's columns are `inquire`,
`dialoguer`, `cliclack` and `demand`.

*The problem.* The prompt's tier guidance says bundle members require the crate
figures for each crate member, and that a metric inapplicable to the item kind must be
stated `inapplicable` with its reason rather than omitted. Member 2, `crossterm`
0.29.0, gets its registry and repository figures, its advisory 404, its maintenance
state and its cost, but gate 4 — builds and is tested on `ubuntu-latest,
macos-latest` — is never stated for it; member 3, `std::io::IsTerminal`, gets no gate
row at all and is not declared `inapplicable` in the prompt's word, though the reason
it would be (it is a standard-library trait, not a crate) is stated plainly in the
bundle table and the landscape.

*Why it is not blocking.* Both gates pass substantively on evidence already in the
record. `crossterm` is compiled and exercised on `ubuntu-latest`, `macOS-latest` and
`windows-latest` by `inquire`'s own CI matrix, which the gate-4 row does state, because
`crossterm` is the back-end that matrix builds; the Opus raw additionally records
`crossterm`'s own matrix (`ubuntu-24.04`, `windows-2022`, `macos-15`), covering both
required platforms. `IsTerminal` is `std`, stabilized in Rust 1.70.0 with the release
cited, so licence, advisory, CI and feature gates have no subject, and its MSRV
implication is twenty-six minors below the 1.96 floor. No gate result, exclusion or
ranking turns on either omission.

## Assessment

**Approve**, with no unresolved findings, and the recommendation does not move under
any of the five. Each is a citation, a predicate or a table-coverage matter whose
underlying fact I confirmed independently — the crossterm and inquire signal surfaces
in the registry, the single duplicate in the printed tree, the endpoints in both raws,
the gate evidence in the gate table and the raw. None touches the crate, the feature
string, the gate predicate, the class rule, OV-02, the R67 mapping or a parameter.

What makes this decision approvable is that its three hardest points are carried on
something other than preference. The gate's ownership rests on an executed observation
with a negative control, not on a reading of two crates' source. The crate choice is
argued as a tradeoff in which the runner-up's advantages are measured like-for-like,
stated in the decision's own voice as the strongest counter-argument, and left
reversible at one file, with the uncertainty declared at the point a reviewer would
otherwise have to discover it. And the cross-repo rule for F360 is derived from the
standard's own scoping of `MUST` to "required non-auth input or consent", which is why
it can be named for all three repositories without asking either existing repository to
change behaviour — the strongest outcome available for a `harmonize = partly` row.

Three observations for the controller, none of them findings. First,
`docs/port/BASELINE-REVIEW.md:119` still carries F278 as `challenged` and its
`BASELINE-REVIEW: F278` line at `:153` proposes deleting "independent of R61's
prompt-crate choice" from the ledger note; this decision answers the half the prompt
scoped to it — how `--yes` composes with `--no-input` and the confirm — with an
explicit precedence ladder, and correctly leaves the ledger-note edit to the
controller, since a decision changes no ledger. Second, R19 declined to declare an
override for its `DIVERGENT` rows on the ground that there is no recorded common
pattern to depart from; R61 declares one anyway. I judge that legitimate rather than
inconsistent — `AGENTS.md` speaks of departures from *recorded* patterns, py's exit `5`
is recorded, and the decision distinguishes the `AGENTS.md` sense from the
ledger-verdict sense in the same paragraph — but the controller may wish to settle
which convention
the programme keeps, since the two published items now read differently. Third, this
approval is one of the two verdicts acceptance requires: the empirical audit is
deferred, `review/audit-codex.md` does not exist, and that auditor still owes a rerun
of `r61-claims.sh` against this same hash.
