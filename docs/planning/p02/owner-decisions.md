# Open owner decisions — P02 research programme

Purpose: this is the list of things the programme cannot decide for itself. Each
entry states what is being asked, quotes the evidence that creates the question,
gives the options with their consequences, recommends one, and says exactly what
response settles it.

Everything else has been researched. Nothing here is waiting on more research,
with one exception that is named as such (decision 3).

Status as of 2026-09-10. Fourteen items are published. The programme is
`research/CLAUDE.md`; the narrative record is `docs/planning/p02/execution-ledger.md`.

## What is blocked, and by what

| Decision | Blocks | Cost of leaving it open |
|---|---|---|
| 1. Wave 0 review gate | all 52 unadmitted items | the programme stops when Wave 0 finishes |
| 2. R69 early admission | 19 items directly, 33 transitively | the largest dependency cluster stays idle |
| 3. R66 paid providers | one item's evidence base | R66 decides on three reports instead of five |
| 4. R18 residual acceptance | ANSWERED 2026-09-12 | R18 reopens for a revision; one fact still needed |
| 5. Licence gate reach | one item, not three (corrected) | P03 uses the slower install backend |
| 6. R25 prompt correction | nothing | a defective prompt stays on the record |
| 7. Baseline-review questions | nothing yet; several are inputs to unadmitted items | later items research around them |
| 8. Model substitution acknowledgment | nothing | an approval record stays incomplete |
| 9. CLI standard, and one waiver under it | two items, one already published | R60 cites it as R67 does, and needs a waiver recorded |

Decisions 4 through 9 block no research. They can be answered at any time. Only
1, 2 and 3 change what happens next.

## 1. The Wave 0 review gate -- SATISFIED 2026-09-16

**Status (2026-09-16).** The review this gate waited on is complete: every Wave 0 item is accepted at a named sha (section 10, W0-R01 through W0-R69b; `docs/port/OWNER-ACCEPTANCES.md`). Wave 1 admission proceeds under the schedule; paid Doxa for the Deep tier remains a separate authorisation (section 12). The text below is the original ask, kept as history.


**What is being asked.** You set a gate: no Wave 1 item is admitted until you
review the Wave 0 keystones. Wave 0 is close to finishing. The question is what
review actually satisfies the gate.

**Evidence.** You said, when the programme started, that you wanted to review
key research and key recommendations to make sure we agree before going on. R01
is the only item with recorded acceptance. Thirteen further items are published
and unreviewed, and eighteen are still in the loop.

**Options.**

- **(a) Review the published keystones, then admit Wave 1 as a whole.** You read
  the decisions that later items consume as inputs. Cost: your reading time,
  concentrated once. Consequence: Wave 1 opens fully.
- **(b) Review a named subset now and admit Wave 1 in stages.** Cheaper per
  sitting, but the gate recurs and the programme pauses each time it does.
- **(c) Drop the gate and admit Wave 1 on publication.** Fastest. Consequence: a
  wrong keystone propagates into dependent items before you see it, and the
  revision cost lands on the dependents rather than on the keystone.

**Recommendation: (a).** The published decisions are audited twice each and the
audits reject far more often than they approve, so the marginal value of your
review is highest on the recommendations themselves rather than on their
evidence. Reviewing once, in a block, costs less of your attention than a gate
that recurs.

**Response that settles it.** Either "review these, then admit Wave 1", naming
the items, or "drop the gate".

## 2. R69, and whether it starts before the gate lifts

**What is being asked.** Whether to admit one item, `web-framework-stack`, ahead
of the gate.

**Evidence.** From `docs/planning/p02/item-graph.json`, recomputed 2026-09-10:
R69 is a prerequisite of 19 items directly and 33 transitively, and its own
prerequisite list is exactly one item, R01, which you have already accepted. It
is the largest single unblocking in the programme and it needs nothing that is
not already settled.

**Options.**

- **(a) Admit R69 now.** The 33-item cluster starts moving while Wave 0 finishes.
  Consequence: if your later review changes R01, R69 is revised against recorded
  research rather than researched again.
- **(b) Hold it until the gate lifts.** No risk, and the cluster stays idle for
  as long as decision 1 takes.

**Recommendation: (a).** It consumes only the item you have already accepted, so
admitting it does not pre-empt anything you have not seen.

**Response that settles it.** "Admit R69" or "hold it".

## 3. R66's paid orphan -- ANSWERED 2026-09-15

**DECIDED: (b), accept the single-provider result (W0-R66 option A).** No further spend; synthesis proceeds on the Codex, Opus and OpenAI reports, and the decision records that the Perplexity and Gemini engines are missing and claims only what those three reports plus the source reading establish.

**What is being asked.** Whether to spend again on two research providers for
one item.

**Evidence.** R66's three-provider operation
`research-20260909-003306-9390be364d324b9d` failed part-way. The OpenAI job
completed and was recovered read-only; Perplexity refused its submission against
a concurrency limit; Gemini was never attempted. The item has its Codex report
and, as of today, an Opus report in progress. So R66's Deep-tier evidence base is
one paid engine instead of three.

**Options.**

- **(a) Re-approve the Perplexity and Gemini subset.** Estimated USD 1.30 to 7.
  Consequence: R66 gets the evidence base its tier calls for.
- **(b) Accept the single-provider result.** No spend. Consequence: the decision
  records that two of its three required engines are missing, and the audits will
  hold it to a narrower claim.

**Recommendation, revised 2026-09-10 after R66's Opus report landed: (b),
accept.** When this entry was written the item had one paid report and the
recommendation was to re-spend. It now has three substantive reports, and more
importantly the strongest finding on the item did not come from provider breadth
at all. It came from reading commits and a design record in the pinned sources:
the TypeScript repository's flag shape is a faithful port of the pre-rewrite
Python command-line interface, and the Python repository's own design record
directed the rename before it could spread. So what the divergence analysis
recorded as an adjudicated divergence is stale-port drift. Two further providers
would add breadth on ecosystem practice, which is not where this item turned.
Spend if you want the tier honoured for its own sake; the evidence does not
require it.

**Response that settles it.** "Re-run Perplexity and Gemini for R66" or "accept
one provider".

## 4. R18's residual risk -- ANSWERED 2026-09-12, and it changed the design

You did not answer this as posed; you gave direction that dissolves it. Recorded
as an owner amendment to published R18.

**What you decided.** Both Claude workflows ship with the template by default.
They run whenever the credential they need is present, with no enable variable
at all. When the credential is absent they do not run, do not error, and print
that the key needs setting. Anyone who does not want them deletes the files.
Both lanes must reject bots. The author-trust test stays the association check
already specified; you considered a real write-permission check and chose
association as the more accurate test.

**Why that answers the residual question.** The question was whether you accept
the exposure in order to switch a lane on. Under your design there is no switch.
A lane runs when a credential exists, so installing the credential *is* the act
of acceptance, and it is taken by whoever installs it, including every adopter
for their own repository. There is no separate flag for you to set here.

**What it costs.** R18 must be reopened for a revision carrying a supersedes
section, which the approved spec permits for a reversal. That revision changes
the gate, adds bot exclusion to the assistant lane, and reruns both audits.

**Still outstanding, and it is a fact not a decision.** Whether you have admin
access to an Anthropic organisation. Federation uses three repository variables,
which a job condition can read directly. An API key or token is a secret, which
a job condition cannot read at all, and that is the case requiring the preflight
job you chose. Your instruction reads as the secret path. The revision cannot be
written correctly without the answer.

## 5. The licence gate's reach -- ANSWERED 2026-09-12 (Q7.B)

**Status.** Answered by the owner's ruling recorded verbatim in `docs/port/OWNER-REVIEW.md` under "2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)": licence compatibility is not evaluated for any dependency or tool; every decision records fitness gate 1 as `inapplicable — owner ruling 2026-09-12 (Q7.B)`. The text below is the original ask, kept as history.


**What is being asked.** Whether the fixed `license` fitness gate reaches a
developer tool that runs as a separate process and is never linked into the
template's artifact.

**Evidence, quoted from the published decision.** The fast install backend,
`cargo-binstall`, declares `GPL-3.0-only`. The decision says:

> Under the plain reading `cargo-binstall` **fails gate 1** and is excluded,
> which is codex's position. `raw/opus.md` argues it should pass because the tool
> is executed as a separate process and never linked into the template's
> artifact, citing the FSF's mere-aggregation position. **That argument is
> recorded, not adopted:** whether gate 1 covers separate-process developer tools
> is an owner ruling, and no owner ruling exists.

The decision therefore chose the backend that is clean under either reading, and
recorded what changes if you rule otherwise: substituting the fast backend edits
one line of the recipe body and no invocation anywhere.

**Options.**

- **(a) Rule that the gate does not reach separate-process developer tools.**
  P03 uses the fast backend. Consequence: the ruling applies programme-wide, not
  just here.
- **(b) Rule that it does.** The current recommendation stands unchanged and
  contributors pay in compile time.
- **(c) Leave it, and use the licence-clean prebuilt alternative if compile time
  proves unacceptable.** The decision names one.

**CORRECTION, 2026-09-11: this reaches fewer items than I told you.** I
reported that three items depend on this ruling and that the strict branch
leaves no proven snapshot testing stack. R33's judgment auditor established that
R33 does **not** depend on your ruling at all. Its recommended crates carry
`Apache-2.0`, which is one arm of the fixed `license` value, so they pass on the
registry's own wording without the contested never-linked argument. The
no-stack outcome belongs to a **third, stricter reading** that no one has
adopted, under which every dependency at every depth would have to carry the
dual expression. That reading is not on the table unless you put it there.

R81 is in the same position and its own audit will confirm or correct that. So
the ruling's real reach is R42's install backend, which carries `GPL-3.0-only`
and genuinely is excluded under the plain reading, plus any future item that
recommends a copyleft tool. That is a narrower and more answerable question than
the one I put to you, and I should have checked the licence values against the
registry's own wording before widening it.

**Recommendation: (b), with (c) as the escape hatch.** A programme-wide licence
ruling made to speed up one install step is a large lever for a small gain, and
(c) gets most of the speed without the ruling.

**Response that settles it.** "Gate 1 does not reach separate-process tools",
"it does", or "leave it".

## 6. R25's defective binding prompt

**What is being asked.** Whether to correct a prompt that was already used.

**Evidence.** R25's binding prompt glosses two release-please flags as "feat
commits bump the minor digit, not major; fix commits bump patch even under a 0.x
minor". The tool's own schema at the pinned version says the opposite: one flag
makes a *breaking* change bump the minor digit, the other makes a *feature* bump
the patch digit. Two engines and one audit established this independently against
the source. The defect is in the prompt file alone; an earlier ledger entry also
blamed the commonality file, and that was wrong — its row names the two flags and
glosses neither, and never did.

**Options.**

- **(a) Correct the prompt.** Future readers see the right thing. Consequence:
  R25's acceptance record continues to cite the prompt hash it actually ran
  against, so the record and the file will differ by design.
- **(b) Leave it.** The decision is the correction of record. Consequence: anyone
  reading the prompt without the decision is misled.

**Recommendation: (a).** The hash mismatch is explainable in one line; a wrong
prompt is a trap.

**Response that settles it.** "Correct the R25 prompt" or "leave it".

## 7. The baseline-review questions

**What is being asked.** Nine questions consolidated at
`docs/port/BASELINE-REVIEW.md`, each with options and a recommendation already
written. Eight are fully open. One, the ninth, is half-answered: R67 answered the
ownership half and declined the rest, and the acceptance criteria remain open with
two competing capture proposals.

One of the nine, the sixth, has already been acted on in a published decision:
R20 recorded the vendor-canonical exemption as a path-scoped ignore. That is the
recommendation the baseline review made, so ratifying it costs nothing.

**Recommendation.** Take them as a block and accept the written recommendations
except where you disagree. They were written with the options and consequences
already laid out.

**Response that settles it.** "Accept the baseline-review recommendations", with
any exceptions named.

## 8. The model substitution acknowledgment

**What is being asked.** The approval record asked you to acknowledge that one
provider's deep-research model was substituted. It was never recorded.

**Recommendation.** Acknowledge it. Nothing depends on it, but the approval
record is incomplete without it.

**Response that settles it.** "Acknowledged".

## 9. Whether your CLI Design Standard binds this port -- ANSWERED 2026-09-14

**DECIDED.** The standard BINDS. Override OV-01 is NOT waived; the owner
selected R60's own conformant option (b).

The ask was re-put after the owner said the first version was unclear. The
rewrite named the document (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`,
version 1.4.14), quoted its own scope line ("Applies to: All new CLIs, any
language"), showed that R67 is already published relying on its rule R6.1, and
reduced the real question to one thing: what `--version` prints. The binding
question was presented as a confirmation the document already answers, not as an
open choice, which is what it always was.

**Effect on R60.** `-V` and `--version` both print the single conformant line
`<tool> <semver>`; the target-triple and rustc lines move behind
`<tool> --version -o json`, which R4.6 explicitly permits at `:277-279` and
whose object shape it specifies. AC2 and AC3 are rewritten and nothing else in
R60 changes, exactly as R60 itself predicted for options (b) and (c).

**OV-01 is retired rather than deleted.** The programme's first override ends
as a waiver REQUESTED 2026-09-12 and REFUSED 2026-09-14, with the argument and
options table kept as the record of how the choice was reached. R60 now carries
zero overrides, and the template conforms to the pinned standard with no waived
SHOULD on file.

**One consequence that needs work rather than bookkeeping.** R60's own text
warns that option (b) "couples F267 to R66's output-format surface, which R60's
prompt puts out of scope." That coupling is now real. The revision is directed
to establish what R66 actually owns and either record a `related (not a registry
dependency)` note naming what R66 must stay compatible with, or write a
`CONFLICT: R66 ...` line if R60's recommendation genuinely needs a value R66
owns. It may not change another item.

---

## 9. Whether your CLI Design Standard binds this port

**What is being asked.** To confirm, not to decide. R60 flagged as an owner call
whether the organisation's CLI Design Standard at
`/Users/stevemorin/c/cli-standards/cli-design-standard.md` governs this template.

**Evidence.** It is already load-bearing in a published decision. R67 read the
standard on 2026-09-09, adjudicated one of its rules as a requirement that is
org-locked, and quoted its exit-code table verbatim as the contract this template
adopts. R60 reaches the same document independently for command ordering and
completion behaviour, and its report notes the TypeScript repository had already
reconciled onto it.

**Options.**

- **(a) Confirm it binds.** Nothing changes. R60 cites it the way R67 already
  does, and future items do the same.
- **(b) Say it does not bind.** R67 is reopened along with R60, because R67's
  exit-code contract rests on it.

**Recommendation: (a).** This is a confirmation of something two independent
items found and one published decision already relies on. Denying it costs a
resolved item.

**A waiver rides with this answer.** R60 recorded the programme's first
override, `OV-01`: its recommendation deviates from the standard's rule on
extended version output, so the tool would print target and compiler lines the
rule does not call for. The decision records the argument and three options as
the charter requires, and it cannot grant itself the waiver, because the
standard's own conformance clause reserves that to you. If the standard binds,
this needs a yes or a no.

**Recommendation on the waiver: grant it.** The rule it deviates from is a
should, not a must, and extended version output is what a Rust command-line tool
is expected to print. Refusing costs nothing either, since the decision names
the conforming alternative.

**Response that settles both.** "The CLI standard binds, and OV-01 is waived",
or either half negated.

## 10. The Wave 0 review walk -- COMPLETE 2026-09-16 (started 2026-09-14)

One question per item, asked in order, each answered before the next is put.
Every acceptance binds the recommendation at a `DECISION.md` sha256 and is
recorded in the "Wave 0 owner acceptances" table of `docs/port/OWNER-ACCEPTANCES.md` (moved there from `docs/port/OWNER-REVIEW.md` on 2026-09-16, see the ledger);
a later revision that changes only reasoning or evidence re-binds it, one that
moves the recommendation re-asks it. The briefs put to the owner are drafted
from each item's own decision text (scratchpad `owner-briefs/`), reviewed
against the cited lines, and presented with options A accept / B hold / C
reject.

| question | item | answer | date | bound sha256 | note |
|---|---|---|---|---|---|
| W0-R67 | R67 error-and-exit-code-contract | A accept | 2026-09-14 | `16947ab1…` | two-layer contract, `thiserror`/`anyhow`/`signal-hook`, exit codes from standard R6.1; `ctrlc` runner-up loses on R9.6 |
| W0-R42 | R42 dev-toolchain-provisioning | A accept | 2026-09-15 | `a2504aa7…` | first put 2026-09-14 as one combined question and withdrawn at the owner's request; re-put split in two with the keyboard-level table and the controller's reasoning for its recommendation made explicit |
| W0-R42i | R42 install-integrity posture | A = decision's option 3, signed/unsigned column | 2026-09-15 | — | recorded as a binding ruling in `docs/port/OWNER-REVIEW.md`; options 1 (as written) and 2 (`--only-signed`) declined |
| W0-R49 | R49 build-target-declaration | A accept | 2026-09-15 | `319a5356…` → re-bound `86b7f925…` (revision 8, the rslbp rename, 2026-09-15) | first put 2026-09-15 and withdrawn at the owner's request; re-put as a full brief with the cross-platform implications (Linux, macOS, occasional Windows) and a four-way comparison of the architectural alternatives |
| W0-R49n | R49 binary name | B = direct a short name: `rslbp` | 2026-09-15 | — | the decision kept `rs-launch-blueprint` as owner-reviewable; the owner chose `rslbp` (the Opus engine's proposal) from `rslbp` / `rsbp`; recorded as a ruling in `docs/port/OWNER-REVIEW.md` |
| W0-R38 | R38 commit-message-linter | A accept | 2026-09-15 | `7e88ba81…` → re-bound `c2e9b6e1…` (revision 9, 2026-09-16) | `committed` 1.1.11 at commit-msg and in CI; runner-up commitlint wins only if a Node/Bun runtime is provisioned for another tool; footer cap 72 accepted |
| W0-R66 | R66 output-format-surface spend | A accept one provider | 2026-09-15 | — | section 3 above; no re-run of Perplexity/Gemini; synthesis starts on three reports |
| W0-R60 | R60 cli-parsing-framework | A accept | 2026-09-15 | `67d7a7d2…` | `clap` derive; `bpaf` runner-up on a two-part condition; the OV-01 ruling implemented |
| W0-R01 | R01 ports-and-adapters-seam re-bind | A re-bind to revision 3 | 2026-09-15 | `44bf9ae9…` | reasoning repair; every crate, version and parameter value byte-identical to the accepted revision 2 |
| W0-R04 | R04 public-api-surface-enforcement | A accept | 2026-09-15 | `0d4f2e60…` | runner-up `cargo-public-api` needs a pinned nightly; method-level gap accepted |
| W0-R06 | R06 unsafe-code-policy | A accept | 2026-09-15 | `343a7fc5…` | runner-up `deny` + `#[expect]` wins only for FFI/systems forks |
| W0-R07 | R07 contributors-bot-trigger-cadence | A accept + add the monthly backstop | 2026-09-15 | `0b3dde8f…` → revision 2 | the decision's runner-up E condition (R21 settles on an expiring credential) was already met; owner directs the two-line backstop now |
| W0-R15 | R15 template-drift-receipt-guard | A accept | 2026-09-15 | `7dd84b81…` | one press mechanism for the family; substring rule forced by run-1 failure |
| W0-R16 | R16 codeql-config-customization | A accept | 2026-09-15 | `d7946ed6…` | config file with `paths-ignore`; inline runner-up cannot express the exclusion |
| W0-R17 | R17 secret-scanning-ci-workflow | REDIRECT: "do what the other projects do; validate that py/ts use TruffleHog and if so use it" | 2026-09-15 | — | superseded by W0-R17b after validation (py runs TruffleHog in CI; ts has no secret-scan CI) |
| W0-R17b | R17 secret scanner form | A = TruffleHog CLI as a pinned binary on both runners | 2026-09-15 | → revision 7 | ruling recorded in `docs/port/OWNER-REVIEW.md`; py's Action form declined (ubuntu-only, docker, first-push failure) |
| W0-R18 | R18 ai-assisted-review-workflows | A accept | 2026-09-15 | `c9e44318…` | the owner's own 2026-09-12 design as implemented |
| W0-R19 | R19 dependabot-config-shape | A accept | 2026-09-15 | `17854730…` | catch-all groups; runner-up filtered groups is the recorded successor |
| W0-R07b | R07 backstop, re-put on a corrected fact | A revert to push-only | 2026-09-15 | → revision 3 → re-bound `cb183382…` (revision 4, retitle, 2026-09-16) | supersedes W0-R07: GitHub keeps one state per workflow file, so a `schedule` key exposes the whole file to the 60-idle-day / fork switch-off; the backstop was declined for converting a bounded lag into a silent-off state |
| W0-R20 | R20 third-party-action-pinning-policy | A accept | 2026-09-15 | `02fee7a4…` | hash-pin plus release comment, two disjoint checks |
| W0-R21 | R21 contributors-bot-credential-source | A accept | 2026-09-15 | `66d566a5…` | dedicated fine-grained PAT fallback; ts's GITHUB_TOKEN shape rejected on approval-required runs |
| W0-R23 | R23 lockfile-version-sync | A accept | 2026-09-15 | `ea269dd6…` | native Rust release strategy; jsonpath runner-up silently no-ops |
| W0-R25 | R25 semver-bump-strategy | A accept | 2026-09-15 | `978ec707…` | `0.1.0` with dampening; `1.0.0` runner-up waits on R04's surface |
| W0-R26 | R26 packed-artifact-content-guard | A accept | 2026-09-15 | `013fe4c3…` | first-party diff/assert/dry-run guard |
| W0-R33 | R33 property-and-snapshot-testing | A accept | 2026-09-15 | `39a5e39c…` → re-bound `4e0ae20a…` (revision 6, retitle, 2026-09-16) | separate-file snapshots; `snapbox` runner-up needs the inline relaxation |
| W0-R34 | R34 scheduled-freshness-lanes | A accept | 2026-09-15 | `14d35261…` | scheduled canary; the auto-disable closed by `workflow_dispatch` plus a documented re-enable |
| W0-R41 | R41 lockfile-freshness-check | A accept | 2026-09-15 | `efc7614a…` | unlocked resolve asks py's question; `--locked` cannot |
| W0-R43 | R43 ai-assistant-repo-furniture | A accept | 2026-09-15 | `b9c83036…` | AGENTS.md hub; announcement entry |
| W0-R45 | R45 pr-comment-bot-trigger-block | A accept + update the R18 precondition | 2026-09-15 | `1e7fe249…` → revision 3 → re-bound `a272f615…` (revision 5, 2026-09-17) | R45's re-verify trigger (R18's enablement decision) fired with W0-R18 |
| W0-R46 | R46 per-file-license-header | A accept | 2026-09-15 | `a95cbbfa…` | no headers; SPDX runner-up needs vendored/mixed-licence source |
| W0-R47 | R47 contributors-recipe-mode | A accept | 2026-09-15 | `20693ce1…` | guarded render/init recipe |
| W0-R64 | R64 pager-integration | A accept | 2026-09-15 | `39f0df04…` | `shlex` over `shell-words` on the strict MSRV gate |
| W0-R81 | R81 docs-delivery-model | A accept | 2026-09-15 | `4329ce48…` | generator shipped at medium confidence; plain-tree runner-up wins for a flat corpus |
| W0-R85 | R85 rich-terminal-row-niceties | A accept | 2026-09-15 | `1a81ae3a…` | `rows_rich` opt-in; requirement on R66's table crate ANSI-width feature |
| W0-R63 | R63 progress-spinner | A accept | 2026-09-15 | `0ce8e437…` | `indicatif`; `--quiet` per standard R7.4 |
| W0-R65 | R65 color-enablement-chain | A accept | 2026-09-15 | `4b9b21a1…` | seven-tier chain; `NO_COLOR` beats force variables |
| W0-R66 | R66 output-format-surface (decision) | A accept | 2026-09-15 | `a7958d3f…` | the surface rests on standard MUSTs plus the stale-port finding; `tabled` medium with a named swap trigger; `table` kept as the default's name |
| W0-R69 | R69 web-framework-stack | DECLINED as put (2026-09-15/16): the owner rejected the first ask and supplied the reference architecture with "Include things like bacon, and here is a bunch of information of things to fold in" | 2026-09-16 | — | recorded as the standing input of section 11; revisions 6-9 reconcile it row by row; re-put pending both round-9 audits |
| W0-R60b | R60 cli-parsing-framework: removal of the clap `string` feature | A accept the three-feature set (`derive`, `env`, `wrap_help`) | 2026-09-16 | `16d2db72…` (revision 9) | both recorded grounds gone (runtime `long_version` — removed by OV-01 option (b); the `mut_args` env pass — forbidden by standard R5.4); no replacement ground found (r60-feature-ground-r8.sh); adding the feature back is one additive Cargo.toml line if P03 needs it; crate, pins, build.rs, option (b) unchanged |
| W0-R69b | R69 web-framework-stack (re-put at revision 9 with the reference comparison and the bacon dev loop) | A accept | 2026-09-16 | `d4507f5b…` (revision 9) | axum 0.8.9 / tokio 1.53.1 behind `web`; tower dev-only; State+FromRef; `<app>-serve` with R4.1 core and R67 exits 143/130/1/0; drain clock at the signal; bacon with kill override; reference rows: 4 agree, 5 differ with ground, the rest hand-offs; actix-web runner-up on a measured-advantage condition; R67 asked for a drain-deadline exit row |
| W0-R69p | Cargo release build profile ownership (`[profile.release]`: lto, codegen-units, opt-level, strip), which no prompt named | A = R68 release-binary-artifacts, by amending its prompt before it is prepared | 2026-09-16 | — | raised by R69 revision 9's census over all 85 prompts and the ledger (confirmed by both round-9 auditors); R49 owns the manifest declaration surface but sets no profile key and is accepted and published; the owner's reference architecture's `[profile.release]` row (lto = "thin", codegen-units = 1) is an input to R68, not a pre-decision (§11) |
| W0-R69c | R69 web-framework-stack re-bind | A re-bind to revision 10 | 2026-09-18 | `d34ab6e8…` (revision 10) | the six W1-R02 substitutions only (judgment approve at revision 10, 20 hunks all classified); republication pending the empirical audit; the seven prepared Wave 2 runs re-prepare after it |
| W0-R17c | R17 secret-scanning-ci-workflow (acceptance at a sha; W0-R17b was a direction) | A accept | 2026-09-16 | `32b4a390…` (revision 12) | TruffleHog OSS CLI pinned binary per W0-R17b; gate {0} of {0,1,183}; `--fail-on-scan-errors`; no `--redact` exists (executed) so no secret-printing output mode; limits stated: PR-level failure on a hosted runner unobserved, cosign availability, one adverse detector-coverage data point (localhost Postgres URI undetected) |

## 11. Owner-supplied reference architecture (2026-09-16) -- STANDING INPUT

The owner supplied "The Axum Companion Stack — Reference Architecture (September
2026)", recorded verbatim at `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`,
with two instructions: fold it into R69 (`web-framework-stack`) now, and for every
later item it overlaps, "don't answer our items that haven't been researched yet,
but just include this ... any places where overlap, include it in that further
research."

**Ruling as applied.** The document is an owner-supplied research input, not a
binding standard and not a pre-decision. It binds process, not outcome:

- R69 revision 6 reconciles with it row by row where they overlap (framework,
  runtime and features, exact pin, dev loop, graceful shutdown and the Cloud Run
  SIGTERM window, WebSocket task tracking, test idiom, layout) and records
  agreement or a ground for differing; rows belonging to other items are recorded
  as hand-offs, not decided.
- When any overlapping item is prepared, the controller copies the document into
  that run's `inputs/` as `owner-reference-axum-companion-stack-2026-09-16.md` and
  every engine and synthesizer task message names it as a required input. Overlap
  set: R70 (C4 error contract), R71 (C3 OpenAPI), R72–R76 (C11 middleware, rate
  limiting, security headers), R77 (C9 config and secrets), R78/R79 (C10
  observability), R80 (C15 probes), R32 (C12 testing), R05 (async model), R58
  (C10 logging), R51/R68 (C15 container and release). Owner-fixed parameters
  override any value the document states (edition 2024 over 2021; `msrv-policy`
  over `rust-version = "1.85"`).
- Rows with no P02 item — templating, static assets, database and migrations,
  sessions and auth, WebSockets, background jobs, Cloud Run deployment, the
  HTMX-versus-SPA head — are NOT decided and NOT researched by this instruction.
  They are listed in the file's overlap map for a later scoping decision by the
  owner.

## Retired from this list

Two items previously carried here are not owner decisions.

**The OpenTelemetry clause.** The approved plan says the required web example
uses OpenTelemetry and that feature selection must not make it optional. That is
a constraint on the template P03 builds, not an instruction to build an
observability example during research, so it does not conflict with the
research-only ruling. The baseline review reaches the same conclusion, recording
that its own finding on the subject is "coordination of existing research, not
permission to relax OpenTelemetry".

**Whether you have an Anthropic organisation.** This was a live question while
R18 proposed workload identity federation as a mitigation. Revision 3 withdrew
that mitigation and revision 4 folded what remained into decision 4 above. It
survives only as a fact you supply when answering that one.

## Two things you should know, which are not decisions

**A gate reading I ruled on was overturned by the auditors, which is the
outcome the process is for.** Two items applied the minimum-supported-Rust-version
fitness gate differently. I ruled provisionally that a candidate which declares
no version is unproven rather than failed, weighed against it but not excluding,
and put that ruling to both items' auditors. Both argued independently for the
strict reading and they are right: the gate quotes the policy in full, and the
instruction that follows says a failed gate excludes the candidate, so an
unknown version is insufficient to clear a bar the prompt says must be cleared.
The ruling is withdrawn. One item's exclusions stand; the other must switch to
the runner-up it already recorded. No decision was published under the wrong
reading.



**R41 ran to eight audit rounds** against a runbook limit of five. It published.
The limit exists to stop an item circling; R41 was converging, not circling, and
the rounds are recorded.

**R25 is at its fifth revision.** Four consecutive audits rejected it for the
same defect shape — a supporting sentence stated more absolutely than its
evidence — and never for its recommendation, which has not changed once. The
contract has been amended to require the revision sweep be done by search rather
than by re-reading, which is the specific failure each time. If revision 5 is
rejected, the item comes to you for adjudication rather than a sixth round.

## 12. Wave 1 admission (2026-09-16) -- ANSWERED

Context put to the owner: the twelve no-spend Wave 1 items were prepared under the schedule once section 1's gate was satisfied; the Deep tier, R86 and the GitHub budget needed rulings.

| question | answer | date | effect |
|---|---|---|---|
| W1-DOXA: paid Doxa for the six Deep-tier Wave 1 items (R02 R03 R05 R54 R56 R68), estimated USD 25-55 against the USD 300 ceiling (USD 36.5-61.5 spent) | A: authorise all six | 2026-09-16 | prepared with authorization ref `OWNER-2026-09-16-W1-DOXA`; Codex and Opus legs run now; Doxa in batches of three, at least 30 s apart, no automatic retry |
| W1-R86: placement of R86 codex-assisted-review-workflows (owner-created 2026-09-12, Deep, no prerequisites, runner-ready, in no wave) | A: admit now with Wave 1 | 2026-09-16 | prepared alongside the Deep six; its Doxa leg is covered by W1-DOXA (a seventh Deep operation) |
| W1-GH: authenticated GitHub API budget for Codex research workers instead of the anonymous 60/hour per-IP budget | B: use the owner's existing `gh` login token | 2026-09-16 | `codex-research.sh` exports `GH_TOKEN` from `gh auth token` into the research sandbox environment only; never written to disk or logs; every report and transcript is swept for the token bytes before it is registered or committed; the recommended read-only token (option A) was declined for speed |
| W1-CODEX: the Codex CLI account hit its usage limit ("try again at Sep 19th, 2026 7:28 AM") with fourteen research legs and every empirical audit waiting on it | "Let's skip codex for now" | 2026-09-16 | both runners stay stopped; Codex research legs and empirical audits are deferred; Opus legs, syntheses, judgment audits, Doxa and acceptance asks continue; no item publishes without its empirical audit, so publication of Wave 1 items waits; the controller does not resume Codex without telling the owner |

## 13. Wave 1 acceptances (from 2026-09-16) -- IN PROGRESS

Same rule as section 10: an acceptance binds the recommendation at one `review/DECISION.md` sha256; evidence-only revisions re-bind, recommendation moves re-ask. Rows are added as items complete both audits.

| question | item | answer | date | bound sha256 | note |
|---|---|---|---|---|---|
| W1-R52 | R52 toml-crate (TOML crate) | A accept | 2026-09-16 | `4287ea4d…` (revision 1) | toml 1.1.6 read + toml_edit 0.25.15 write; basic-toml out on gate 2; F243 stays inherited; codex's responsiveness figure corrected (7/10 answered) |
| W1-R57 | R57 xdg-directory-set | A accept | 2026-09-16 | `44e94504…` (revision 2) | etcetera 0.11.0 on a template-owned Paths, namespace rslbp; R5.3 MUST makes the location rule unconditional; judgment-only acceptance under W1-CODEX; publication waits for the empirical audit |
| W1-R48 | R48 mocking-crates | A accept | 2026-09-16 | `dc1ef152…` (revision 3) | fakes + spy default; mockall 0.15.0 optional behind `mock`; httpmock 0.8.3 dev-only; wiremock out on gate 2 |
| W1-R53 | R53 config-schema-validation | A accept | 2026-09-16 | `be59d65b…` (revision 2) | serde only, type-state, per-key loop; garde runner-up; judgment-only under W1-CODEX |
| W1-R44 | R44 devcontainer-environment | A accept | 2026-09-16 | `ea398dda…` (revision 1) | image-only digest-pinned devcontainer; omission runner-up; digest refreshed by hand; judgment-only under W1-CODEX |
| W1-R10 | R10 dependency-cache-action | A accept | 2026-09-16 | `3ebb09ce…` (revision 1) | rust-cache v2.9.2 by commit; ImageOS assertion mandatory; judgment-only under W1-CODEX |
| W1-R61 | R61 interactive-prompts | A accept | 2026-09-16 | `3131e895…` (revision 1) | inquire 0.9.4 behind Prompter; gate at the call site; OV-02 declined confirm exits 0; judgment-only under W1-CODEX |
| W1-R50 | R50 install-smoke-test | A accept | 2026-09-17 | `316dd29d…` (revision 2) | pack → extract → install → run rslbp --version; ubuntu-only smoke job; judgment-only under W1-CODEX |
| W1-R03 | R03 port-absence-vs-failure-contract | A accept | 2026-09-17 | `610e3338…` (revision 1) | Result<Option<T>, PortError>, adapter maps 404 → Ok(None), use case owns NotFound (RSLB301); judgment-only under W1-CODEX |
| W1-R02 | R02 crate-boundary-enforcement + the R69 conflict | A accept R02, revise R69 | 2026-09-17 | `78788f7f…` (revision 1) | four-package workspace (OV-03); R69 web-extra-surface to be revised to name the optional member and the crates/web/** paths (option 1 of R02's disposition); the seven prepared Wave 2 runs re-prepare after R69 republishes; judgment-only under W1-CODEX |
| W1-R62 | R62 clipboard-integration | A accept, ratify the R67 reading | 2026-09-17 | `fb0a58c9…` (revision 2) | --copy, arboard 3.6.1, ClipboardPort, Linux re-exec holder; failed copy fatal post-result; R67's byte-empty clause read as before-result only, substitute wording at R67's next revision; judgment-only under W1-CODEX |
| W1-R55 | R55 config-error-tolerance | A accept | 2026-09-17 | `5d358c1f…` (revision 3) | no R55 crate; four-clause rule; moved once at revision 2; judgment-only under W1-CODEX |
| W1-R68 | R68 release-binary-artifacts | A accept | 2026-09-17 | `070b7ae1…` (revision 1) | .crate + cargo-dist 0.33.0 follower mode; profile lto = "fat" + codegen-units = 1 on measured ground; judgment-only under W1-CODEX |
| W1-R05 | R05 sync-async-execution-model | A accept | 2026-09-18 | `03d50063…` (revision 2) | sync library + CLI, async only inside the web feature via spawn_blocking, ureq 3.4.2, no async-trait; re-verify note under R69 revision 10 as an evidence-only revision; judgment-only under W1-CODEX |
| W1-R56 | R56 config-secret-policy | A accept | 2026-09-18 | `c2b4da75…` (revision 2) | config file never a token source; three tiers per R10.1; secrecy/zeroize; keychain behind a non-default feature; F240 adopted; judgment-only under W1-CODEX |
| W1-R86 | R86 codex-assisted-review-workflows | A accept | 2026-09-18 | `5a63655c…` (revision 1) | both lanes on openai/codex-action v1.12 @ 86365089 with codex 0.154.0; secret-gated preflight; three minimal-permission jobs; bot and author guards; /codex token; judgment-only under W1-CODEX |
| W1-R86m | the MEMBER-without-write red failure in the /codex assistant lane | A defer to P03 | 2026-09-18 | — | P03 proves criterion B6 and chooses among R86's three options (accept the red failure; allow-users; narrow to OWNER); the workflow-level write check remains excluded by the 2026-09-12 ruling |
| W1-R54 | R54 config-discovery-tiers | A accept | 2026-09-18 | `1348f6b3…` (revision 3) | six-rung precedence, no layering crate, walk-up bounded by .git or a workspace-declaring Cargo.toml, std resolvers for the project and system tiers; judgment-only under W1-CODEX |

