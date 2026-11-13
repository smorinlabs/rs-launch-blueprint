decision-sha256: c22e74ed1190419913c22ecadce4cd7e84536a0f2bf3e123d394886c98f0e343
actor: audit-fable-2026-09-06T043454Z-6f31d86e5b7d-r2
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JA-01 issue #1068's substance dropped — the origin repository's open @claude trigger surface is unadjudicated and absent from the unproven list; JA-02 a second, CVSS-7.8, exploited-in-the-wild vulnerability class against the exact recommended claude.yml shape was neither checked nor recorded as unchecked, and doxa-gemini was dismissed on a collateral version error; JA-03 five engines raised BASELINE-REVIEW: lines, the decision carries two and states opus was the only engine to raise any, so three never reach the controller under RUNBOOK §4; JA-04 the agreement-level ranking is miscited — docs/port/README.md carries no three-level list and spec §2 does not make policy/mechanism the weakest level; JA-05 four objections to recommended triggers and guards (draft double-fire, pull_request_review submitted, issue-title matching, no fork clause on the assistant job) are neither adopted, rejected, nor recorded as unproven

## Principle and agreement level

The shared requirement is stated well and at the right grain. The decision names it
in one sentence — *every pull request receives a first-pass automated review before
a human reads it, and a maintainer can summon an agent into an issue or review
thread without leaving GitHub* — sources it to the `py` implementation at pinned
commit `b08bccfb55d05f15e46a83b52c5660b1881d19f5` read verbatim, and separates the
**guard contract** (what must agree) from enablement, event list, model and prompt
(what may vary). That split is the correct one: the guard contract is
ecosystem-neutral because it reads three language-independent webhook fields, and
the decision proves that rather than asserting it.

The decision also refuses the failure mode this programme exists to prevent. It
says in terms that "`py` does it" cannot settle the question, because the reviewing
entity is a paid third-party service reached with an organization credential and
whether to spend it is an owner policy question. Section `## Engines` §2 then
settles a live disagreement *against* an engine on evidence: `doxa-gemini`'s
Rust-specific bot **denylist** (`dependabot[bot]`, `renovate[bot]`,
`release-plz[bot]`) is refuted because `py`'s guard is *type*-based
(`github.event.pull_request.user.type != 'Bot'` and `github.event.sender.type !=
'Bot'`), which is name-independent and therefore already catches every bot without
enumeration — a denylist is strictly weaker. That is the prompt's HIGH question
answered from the artifact, not from precedent.

**JA-04.** The one defect here is the ranking claim the level assignment leans on.
`## Decision` says the agreement level is "**policy/mechanism** — the weakest of the
three levels in `docs/port/README.md`", and then uses "weakest" to license the
observation that `py` and `ts` already disagree ("that is only tolerable if the
thing they disagree about is a policy choice"). `docs/port/README.md` contains the
phrase "agreement level" exactly once, at line 56, in a passing clause about A5
adjudication; it carries no list of the three levels and no ranking among them. The
three levels are defined in the design spec §2 table
(`docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md`), which
presents them unordered and defines **Policy or mechanism** as "Any deliberately
shared value, protocol detail or tool, with its owner decision or evidence", varying
in "Only the aspects outside that agreement" — the *narrowest* variation allowance
of the three, not the widest. So the citation does not carry the claim, and the
source that does carry the levels does not support "weakest" either. The
substantive assignment may still be right — this genuinely is an owner spend
decision — but the argument as written rests on a miscitation, and the first
judgment axis of this seat is whether the level is stated correctly. Repairing it
means citing spec §2 and arguing the level from what §2 says, not from a rank.

## Design and evidence

**Architecture before vendor: done properly.** Four architectures are compared
before any vendor is named — workflow-file agent (A), platform-configured reviewer
(GitHub Copilot code review, B), hosted third-party review app (C), self-hosted
agent in a generic job (D) — and B and C are rejected on a fit ground that is
specific and checkable rather than rhetorical: they are repository *state*, not tree
content, so they cannot travel through "Use this template", and the prompt's value
test is about two files. Only inside A is `anthropics/claude-code-action` selected,
over `The-PR-Agent/pr-agent`, `google-github-actions/run-gemini-cli` and
`openai/codex-action`, on stated criteria (single component covering both members;
a stable `v1` with no `v2` among 287 tag refs; the maintainer running both shapes
against its own repository at a readable tag). The runner-up is ranked with the
condition under which it wins, and the decision does not pretend that condition is
an engineering question. All of that is sound.

**The inert-by-default design, on the evidence given.** Revision 2's repair here is
correct and I confirm it. What the checks establish is *syntactic*: `contexts.md`
gives `jobs.<job_id>.if` the contexts `github, needs, vars, inputs` with `secrets`
absent (`contexts-availability.log`, 29 quoted availability rows), and `actionlint`
independently rejects `if: secrets.CLAUDE_CODE_OAUTH_TOKEN != ''` at the job level
with exit 1 and the quoted diagnostic (`actionlint.log`). So a credential-independent
enable flag is *expressible*, and `doxa-perplexity`'s secret-presence guard is not
merely unproven but not expressible — the right conclusion, correctly labelled
syntactic. Whether an unset variable yields a **skipped** rather than a failed job
is routed to **U2** at every site, including the fixture's own inline comment. That
is exactly the discipline this programme asks for, and I do not fault it.

I record one piece of corroboration the decision could have used and did not, since
it strengthens rather than weakens the design: `py`'s own guard comment, read
verbatim in `source-repos-pinned.log`, states that the action "aborts on non-human
actors … which showed as a **false red check** on the v2.4.1 release PR (#470)", and
that "Skipping is a neutral (non-failing) outcome for this non-required job". That
is field evidence that an action-level abort produces red while an `if:`-false job
does not — which is the argument for gating at the job level. It is not proof of
U2, and the decision is right not to treat it as such, but it belongs in the record.

**The two security adjudications.** Both are structured honestly at the level of
what they claim, and the **Supported / Not supported / Not established** headings are
the right instrument. On F051 (`pull-requests: read` → `write`) the decision says
plainly that it rests on *concordance with three maintained references plus a
reproduced report*, not on a demonstrated causal chain; that no run of `py`'s own
workflow was inspected; and that whether the job's `pull-requests` grant bounds the
Claude App installation token or some writes go through the job's `GITHUB_TOKEN` is
not established, quoting `docs/security.md` to show it does not disambiguate. It
then states the consequence if wrong (an over-broad grant, which R08 narrows — a
strictly smaller failure than a review that silently never posts). I checked the
underlying evidence in `action-issues.log`: `#1121` is open, its body says "Posting
review comments requires `pull-requests: write`", and the single comment is
`author_association: NONE` dated 2026-05-09 reproducing the silent no-op with a
configuration the reproducer describes as lacking `--comment`. The decision's
characterization matches the log. This adjudication I accept.

On F051+F052 (workload identity federation) the two costs are named and both are
material and correctly stated: admin access to an Anthropic organization that every
downstream fork owner repeats, and the behavior change that `classify_inline_comments`
requires `anthropic_api_key` and is skipped under federation so unconfirmed inline
comments post directly. The billing relationship between `CLAUDE_CODE_OAUTH_TOKEN`
and a federated service-account token is explicitly *not established*, and the
finding is narrowed to "prefer federation where the owner has an Anthropic
organization and is not relying on subscription-backed OAuth", with the static token
kept as the documented fallback and **U7** carrying the gap. That is the right shape
for an unresolved billing question, and I accept it.

**JA-02 — where the security work stops short, and it is the serious one.**
`doxa-gemini` justifies its `v1.0.175` pin with a bot-spoofing/OIDC-theft
vulnerability it says was "patched definitively in `v1.0.94`", citing Microsoft
Threat Intelligence, GMO Flatt Security and The Hacker News. `## Engines` §3 refutes
the *version* claim — correctly, and with evidence: `security-advisories` returns
one row, `GHSA-8q5r-mmjf-575q` patched in `1.0.74`, and `releases/tags/v1.0.94`
describes a `PATH` change for `allowed_non_write_users` (`action-issues.log`,
`action-release.log`). The decision then stops. It never examines gemini's three
security-research citations, never records that it did not examine them, and
elsewhere presents "exactly **one** published advisory" as the security history.

I fetched the primary source gemini cites, credential-free and read-only:
<https://flatt.tech/research/posts/poisoning-claude-code-one-github-issue-to-break-the-supply-chain/>,
HTTP 200, retrieved 2026-09-10 UTC. It is a named disclosure by RyotaK of GMO Flatt
Security, published 2026-06-01, and it is **a different vulnerability class from
`GHSA-8q5r-mmjf-575q`**: not the `.mcp.json`-in-PR-head RCE, but a two-workflow
prompt-injection chain that escalates an untrusted external commenter to a Claude
GitHub App installation token with full write access, by exfiltrating
`ACTIONS_ID_TOKEN_REQUEST_TOKEN` and `ACTIONS_ID_TOKEN_REQUEST_URL` out of a
**tag-mode** run. Four facts from it bear directly on this decision:

1. The article reproduces "the default workflow created when you set up Claude Code
   GitHub Actions" as the escalation target. Its `on:` block — `issue_comment:
   [created]`, `pull_request_review_comment: [created]`, `issues: [opened,
   assigned]`, `pull_request_review: [submitted]` — and its four-clause
   `contains(…, '@claude')` `if:` are **character-identical** to
   `review/evidence/candidate-claude.yml` minus the `vars` gate, and it carries the
   same `id-token: write` plus `actions: read` this decision recommends.
2. Anthropic "rated these vulnerabilities **7.8 under CVSS v4.0**" and paid a bounty.
3. "Variants of the misconfiguration issues described in this article were **actively
   exploited in the wild** before this article was published", and the timeline
   records a similar misconfiguration in Cline's GitHub Actions exploited in the
   wild on 2026-02-17.
4. **No GitHub advisory exists for it** on `anthropics/claude-code-action`. That is
   precisely why `security-advisories` returning `length: 1` is not the security
   history, and why the decision's reliance on that one endpoint is the gap.

Two things must be said for fairness, and I hold to them. First, **the recommended
configuration is not the vulnerable pair.** The chain's Phase 1 requires a second
workflow — `examples/issue-triage.yml` with `allowed_non_write_users: "*"` and
`issues: write` — which this decision does not recommend and whose input it leaves
at the default `""`. Second, several defaults the decision reads as design features
are in fact **remediations from this incident**: the article records that Anthropic
responded by "disallowing GitHub Apps from triggering workflows by default" (the
`allowed_bots: ""` default the decision cites approvingly), disabling the run-summary
exfiltration channel, scrubbing environment variables from child processes, and
"ignoring issues and comments edited after the workflow is triggered". Knowing that
provenance changes how much weight `docs/security.md`'s sanitization claims can
carry, and it is provenance the decision does not have.

The finding is therefore not "the recommendation is exploitable". It is that a
CVSS-7.8, exploited-in-the-wild disclosure against the exact workflow shape being
recommended for a **public** template was surfaced by one of the five engines,
dismissed on a collateral error about a version number, and left out of the record
entirely — neither adjudicated nor listed as unchecked. The researcher's own closing
judgment is the sentence a decision recommending this to strangers most needed to
weigh and never saw: "The permission model around Claude Code isn't hardened enough
to safely handle untrusted input… at the time of writing, I have reported around 50
separate vulnerabilities to Anthropic that allow attackers to bypass the permission
system and execute arbitrary commands in Claude Code."

**Consistency with `audit-codex.md`.** The empirical rerun is consistent with the
decision on everything within its remit, and I reach the same conclusions on the
same artifacts. Its three checks hold: every exit cell now names its own command's
exit or says none was recorded; the three revision-2 evidence changes are strictly
append-only (I confirm the addenda in `action-release.log`, `source-repos-pinned.log`
and `action-source-v1.0.220.log` are dated `# ---- revision-2 addendum ----` blocks
appended after untouched revision-1 content); and the `label_trigger` correction is
right — `action.yml` at `v1.0.220` gives `label_trigger` the default `"claude"`, the
recommended `on:` blocks list no `issues: [labeled]` type, so a label event has no
route to start a run, and the decision now conditions the note on a later revision
adding `labeled`. That correction is handled honestly and I endorse it. JA-01 to
JA-05 are judgment gaps outside the empirical seat's remit; `audit-codex.md`'s
`approve` and this `reject` are not in conflict.

## Completeness

**Structure and required fields — all pass.** Exactly the four H2 sections the
synthesizer contract names, in order, outside fences: `## Decision`, `## Parameters`,
`## Empirical check`, `## Engines`. No extra H2, and no `## Supersedes` (revision
history is carried inside `## Engines`, which is correct for a revision). `## Decision`
carries the `### Principles and implementation` H3 with shared requirement, source,
agreement level, essential behaviors B1–B6 with observable acceptance criteria, what
must agree versus what may vary, the architecture comparison, why the design
preserves each principle, and reference implementations read at a pinned tag; its
final line is `re-verify: 2026-12-10, or earlier on any of …`, correctly placed.

`## Parameters` is correct. `owns` is **none**, which matches R18's empty `owns:`
line in `inputs/prompt.md` and the `—` in the `owns` column of `research/CLAUDE.md`;
no row is contributed to `docs/port/PARAMETERS.md`. All four fixed parameters appear
as `assumes` lines and I checked each against `docs/port/PARAMETERS.md` character by
character: `msrv-policy`, `rust-edition` = `2024`, `target-os-matrix` =
`ubuntu-latest, macos-latest`, `license` = `MIT OR Apache-2.0` all quote exactly. No
`CONFLICT:` line is emitted, correctly — `consumes:` is empty, so no consumed
parameter could need changing.

Fitness gates: all six answered before popularity is weighed, with each inapplicable
metric named and reasoned rather than silently omitted, as the prompt's tier
guidance requires for a `bundle` whose members are not crates. Gate 3's substitution
of the GitHub advisory database for RustSec is the right move for this item kind —
it is the failure of that substitution to be treated as *partial* that JA-02 records,
not the substitution itself.

Ledger handling is correct. F051 and F052 (`docs/port/COMMONALITY.md:57-58`, both
`py-only`, both `DIVERGENT`, both bundled to R18) are named as the rows settled, and
the decision explicitly declines to assign a verdict, noting that `ADOPT` is defined
in `docs/port/README.md:70` as "one-sided precedent, language-neutral; **taken
as-is**" and that this recommendation does not take `py`'s configuration as-is. I
verified that line. Assigning the verdict and editing the ledger are left to the
controller, which is right. I also confirmed there is no `docs/port/BASELINE-REVIEW.md`
row for F051 or F052 to handle — P02-T01 adjudicated only `COMMON → REUSE` and
`ADOPT` rows, and these are `DIVERGENT` — so the only `BASELINE-REVIEW:` obligation
here is to carry forward what the engines raised. Which brings the failure.

**JA-03 — three of five `BASELINE-REVIEW:` lines never reach the controller.**
`## Decision` states "Both were raised by the `opus` engine", and `## Engines` states
`opus` is "the only engine to raise `BASELINE-REVIEW:` lines". Both statements are
false against the raws. Five engines raised them:

| Engine | Location | Row(s) | Substance |
|---|---|---|---|
| `codex` | `raw/codex.md:21` | F051/F052 | change the baseline to an absent-by-default, documented opt-in pair |
| `opus` | `raw/opus.md:93` | F051 | raise `pull-requests: read` to `write` — **carried** |
| `opus` | `raw/opus.md:95` | F051+F052 | prefer federation over a static token — **carried** |
| `doxa-openai` | `raw/doxa-openai.normalized.md:138` | F051 | do not port the active review workflow; opt-in example only |
| `doxa-openai` | `raw/doxa-openai.normalized.md:140` | F052 | do not port an active `@claude` workflow; **split its ledger decision from F051** |
| `doxa-gemini` | `raw/doxa-gemini.normalized.md:25` | F051, F052 | `ts`'s omission is accidental drift, not a justified departure |
| `doxa-perplexity` | `raw/doxa-perplexity.normalized.md:41` | F051 | same claim: treat the `ts` absence as accidental drift |

`RUNBOOK.md` §4 (lines 167–172) makes the controller — not this item — the adjudicator
of `BASELINE-REVIEW:` findings "with the affected decision owners", reconciling
ledger, index, prompt and dependency changes together. The decision understands this
and says so for the two it carries. But folding the `codex` and `doxa-openai`
substance into `## Engines` disagreement 1, as the runner-up's *case*, does not
surface them to the controller **as baseline findings**, which is the channel §4
governs; and `doxa-openai:140` additionally asks that F052's ledger decision be split
from F051's, a ledger-shaped request that disagreement 6 discusses as a design
question without ever routing it. The `doxa-gemini` and `doxa-perplexity` lines make
a claim about `ts`'s baseline that this decision neither carries nor rejects. Three
of five are lost, and the count statement asserts they do not exist.

**JA-01 — `#1068`, and the gap in the unproven list.** The decision fetches
`anthropics/claude-code-action#1068` and reports it only as a count: "the three
issues examined here (`#1121`, `#1068`, `#1482`) are all open, two with zero comments
and one with a single non-maintainer comment". Its title, sitting in the decision's
own `action-issues.log`, is "**Default workflow template missing author trust gate —
secrets exposed on public repos**". `opus`, whose design this decision adopts, read
the issue and recorded its substance (`raw/opus.md:359`): the shipped
`examples/claude.yml` `if:` tests only the trigger phrase and no `author_association`,
so on a public repository any commenter can start a run that touches `secrets` and
requests an OIDC token, and — `opus`'s own words — "the issue's residual point is
about the run starting at all". `opus` offers two mitigations and lists `#1068`
closing as a re-verify trigger (`raw/opus.md:559`, `raw/opus.md:676`). It also states
the residual plainly in its tradeoff table (`raw/opus.md:507`): "the widest permission
grant of any workflow this item touches, on a job reachable from user-authored text;
mitigated by the action's write-access requirement and bot refusal, **not eliminated
(issue #1068)**."

The decision carries one of `opus`'s two mitigations (federation) and drops the
residual, the analysis and the re-verify trigger. The problem is that the *other*
mitigation — the enable flag — does not reach this case. The flag answers the
**downstream fork**, where it is unset. The **origin repository** is by construction
where the flag is `true`, where the federation identifiers are configured, and where
strangers interact with a public template. There, `candidate-claude.yml`'s `if:`
gates on the trigger phrase and nothing about the commenter, so any account that can
comment starts a job that runs `actions/checkout@v7` and reaches the action before
the action's own actor check applies. Whether the OIDC exchange happens before or
after that check is not established anywhere in this record — and that is the point:
it is unestablished and unrecorded.

**U4** does not cover it. U4 claims only "that a non-write user cannot **summon** the
assistant (the action-side gate, which no workflow condition enforces)" and proposes
proving it by asserting "no agent comment and no model run". That is the outcome
after the gate; the exposure is the run starting and the credential being reachable
at all, which no unproven item names. Nor is the available remedy weighed: an
`author_association` prefilter is expressible in `jobs.<job_id>.if` via the `github`
context — the same context table check 1 quotes — so `#1068`'s ask is a one-clause
change that the decision neither adopts nor rejects with reasons. In combination with
JA-02, this is the single place where a public template's exposure is greatest and
the decision's own mitigation does not reach, and it is unsaid.

**JA-05 — four recommended triggers and guards carry objections that are never
adjudicated.** `## Engines` adjudicates `issues: [assigned]` (disagreement 7) and
`synchronize` (disagreement 5), both well. Four more, all raised by `doxa-openai`,
appear nowhere in `## Engines` and nowhere in U1–U10:

- **Draft double-fire.** The recommended list is `pull_request: types: [opened,
  ready_for_review, reopened]` with no `draft` clause in the `if:`. `opened` fires
  when a pull request is opened as a draft, and `ready_for_review` fires when it is
  marked ready, so the common draft-first path yields **two** paid agent sessions for
  one pull request. The decision's stated ground for the list — "every retained event
  fires at most once per pull request per state change" — is true of each event and
  false of their composition, and it is the same bounded-spend argument used to drop
  `synchronize`. `doxa-openai` recommends `draft == false` plus per-PR `concurrency`
  with `cancel-in-progress: true` (`raw/doxa-openai.normalized.md:168-175`, `:236-239`);
  the maintainer's own reference (`types: [opened]` alone) does not have the property.
  I am not faulting P02 for declining to implement a guard — I am recording that a
  named objection to a recommended trigger was neither adopted, rejected, nor listed
  as unproven.
- **`pull_request_review: [submitted]`.** `doxa-openai` excludes it
  (`:348`) on the ground that it adds a content surface that makes quoted mentions in
  review summaries capable of triggering work. Note also that the prompt's MEDIUM
  question asks about scoping to "issue comments, PR review comments, issue bodies" —
  three surfaces — and the decision ships four plus title matching without noting the
  widening.
- **Issue-title matching.** `contains(github.event.issue.title, '@claude')` is in the
  recommended `if:`; `doxa-openai` excludes title matching (`:350`), "only issue
  bodies are in scope".
- **No fork or same-repo clause on the assistant job.** The guard contract's clause
  (a) at `## Decision` reads "the job never runs on a pull request from a fork", stated
  as a property of the contract that must agree across `py`, `ts` and `rs`.
  `candidate-claude.yml` has no such clause; only `candidate-claude-code-review.yml`
  does. `doxa-openai` asks for a same-repository preflight on this lane
  (`:388`, `:416`, `:479`). Either clause (a) binds both jobs and the fixture does not
  implement it, or it binds only the review job and the decision should say so.

Two smaller record gaps, noted but not raised as findings. The `## Decision` summary
table lists the review lane's action inputs as the three `anthropic_federation_*`
identifiers plus `plugins` and `prompt`, omitting `plugin_marketplaces`, which
`candidate-claude-code-review.yml` carries and without which the `plugins` reference
cannot resolve; and `opus`'s decoupling observation that the review lane fetches that
plugin from an external marketplace Git URL at run time — "one more moving part and
one more trust edge" (`raw/opus.md:589`) — is dropped, though it is exactly the kind
of supply-chain edge R20's pin-form decision would want as evidence. Separately, U9
records the issue-responsiveness figure as uncomputed when both `codex`
(`raw/codex.md:91`) and `opus` (`raw/opus.md:167`) computed it independently: zero of
the ten most recently opened issues received a first response from an OWNER, MEMBER
or COLLABORATOR, unanswered 10, median undefined. Deferring is conservative rather
than wrong, but the figure exists in the raws and is a required-evidence row.

## Findings

- **JA-01** — `anthropics/claude-code-action#1068` ("Default workflow template
  missing author trust gate — secrets exposed on public repos") is recorded only as a
  comment count. Its residual point, which `opus` analyzed and the decision adopts the
  design of, is that on a public repository any commenter can start a run holding
  `id-token: write` before the action's actor check. The enable flag answers the downstream
  fork, not the origin repository where the flag is `true`. No unproven item covers it
  — U4 asserts only that a non-write user cannot summon the assistant — and the
  `author_association` prefilter `#1068` asks for, expressible in `jobs.<job_id>.if`
  per check 1's own context table, is neither adopted nor rejected. `opus`'s
  `#1068` re-verify trigger is dropped from the `re-verify:` line.

- **JA-02** — `doxa-gemini`'s security claim was dismissed on a collateral error and
  its primary sources never checked or recorded as unchecked. The decision correctly
  refutes the `v1.0.94` version claim, then treats `security-advisories` returning one
  row as the security history. The source gemini cites —
  <https://flatt.tech/research/posts/poisoning-claude-code-one-github-issue-to-break-the-supply-chain/>,
  HTTP 200, retrieved by this audit 2026-09-10 UTC — is a distinct disclosure from
  `GHSA-8q5r-mmjf-575q`: a prompt-injection chain rated **CVSS v4.0 7.8** by
  Anthropic, whose variants were "actively exploited in the wild", targeting the
  **tag-mode** workflow whose `on:` block and four-clause `if:` are character-identical
  to `candidate-claude.yml`, and carrying **no GitHub advisory**. The recommended
  configuration is not the vulnerable pair — the chain's first phase needs
  `allowed_non_write_users: "*"`, which this decision leaves at `""` — but the
  disclosure, its exploited-in-the-wild status, and the fact that several cited action
  defaults are remediations from it are absent from the record.

- **JA-03** — `BASELINE-REVIEW:` lines are miscounted and three of five are not routed.
  `## Decision` and `## Engines` both state that `opus` was the only engine to raise
  them. `codex:21`, `doxa-openai:138`, `doxa-openai:140`, `doxa-gemini:25` and
  `doxa-perplexity:41` also raised them. `RUNBOOK.md` §4 makes these the controller's
  to adjudicate with the affected owners; folding their substance into a disagreement
  paragraph does not route them, and `doxa-openai:140`'s request to split F052's ledger
  decision from F051's is a ledger-shaped ask that reaches no one.

- **JA-04** — the agreement level's ranking is miscited. `docs/port/README.md` carries
  no list of the three levels and no ranking; spec §2, which defines them, makes
  Policy or mechanism "any deliberately shared value, protocol detail or tool", the
  narrowest variation allowance rather than "the weakest of the three levels". The
  claim is load-bearing, since it licenses the inference that `py`/`ts` disagreement
  is tolerable.

- **JA-05** — four objections to recommended triggers and guards go unadjudicated:
  the `opened` + `ready_for_review` draft double-fire with no `draft` clause (which
  contradicts the decision's own bounded-spend rationale), `pull_request_review:
  [submitted]`, issue-title matching, and the absence of any fork or same-repo clause
  on the assistant job even though guard-contract clause (a) states the job never runs
  on a fork pull request. All four are raised in `raw/doxa-openai.normalized.md`; none
  appears in `## Engines`; none appears in U1–U10.

## Assessment

**Reject.** This is a careful decision and revision 2 is a real repair, not a
cosmetic one: the exit column now distinguishes a command's process exit from the
check's outcome and says "not recorded in the log" where no exit exists; the runtime
inertness claim is gone from all three sites and routed to U2; the sweep found and
disclosed a defect in the decision's own recommendation — that the `label_trigger`
default cannot fire, because the recommended `on:` blocks carry no `issues: [labeled]`
event — and conditioned the note rather than deleting it. That is the behavior this
seat exists to reward, and I would not reject over U2, over the ten-item unproven
list, or over the decision declining to build anything. A claim recorded as unproven
with what would prove it is correct work.

I reject on what the decision did with security evidence it already held. Two of the
five findings are the same failure seen twice: a security signal was fetched,
reduced to a datum, and never adjudicated. `#1068`'s title is in the decision's own
log and its analysis is in the raw report the decision otherwise follows closely;
gemini's disclosure was dismissed on a version number while its substance went
unread. Both concern the same surface — the `@claude` lane on a **public**
repository, holding `contents: write`, `issues: write`, `pull-requests: write` and
`id-token: write` — and it is the one surface where the decision's central mitigation,
the enable flag, structurally cannot help, because the origin repository is where the
flag is on. JA-03 compounds this by keeping three engines' baseline challenges away
from the controller who is supposed to adjudicate them, and JA-05 leaves four
objections to recommended triggers unanswered, one of which contradicts the
decision's own spend argument.

**Would I ship this to strangers?** Not as it stands, and not because of U2. The
inert-by-default design is the right idea, the honesty about U2 is exactly right, and
a fork that never sets the variable is the case the decision handles well. My
objection is the case it does not address: the origin repository, flag on, credential
configured, public, where any account that can type a comment starts a job holding
`id-token: write` and reaches the action before any trust check the workflow
expresses — the shape a
named researcher demonstrated escalating to a Claude GitHub App installation token
with full write access, rated 7.8, with variants exploited in the wild. That risk may
well be acceptable; the recommended configuration omits the specific misconfiguration
the chain needed, and I would probably still ship after seeing it argued. But it has
not been argued, and I will not certify a public-template workflow that can spend
money and push commits on the strength of a security section that treats one endpoint
returning one row as the security history.

The path to approve is short and needs almost no new research, because the material
is already in this run. Revision 3 should: adjudicate `#1068` on the origin
repository and either adopt an `author_association` prefilter or record why not, with
the exposure added to the unproven list; read gemini's three cited sources, record
the CVSS-7.8 disclosure and its absence from `security-advisories`, and re-weigh the
`docs/security.md` mitigations knowing which of them are incident remediations; carry
all five `BASELINE-REVIEW:` lines and correct the count; cite spec §2 for the
agreement level and drop the ranking; and adjudicate the four trigger and guard
objections, in particular the draft double-fire, which the decision's own bounded-spend
reasoning already commits it to caring about. P03 then proves U2 and U4 against the
real template. None of that reopens the recommendation to ship both workflows as one
bundle, which the architecture comparison supports and which I would expect to
survive.
