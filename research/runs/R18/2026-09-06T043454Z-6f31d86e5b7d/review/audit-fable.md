decision-sha256: b45a17a342bfa49689c3571e71c14ab55c2fa64e0f9337032876739babdae205
actor: audit-fable-2026-09-06T043454Z-6f31d86e5b7d-r5
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

The shared requirement is stated at the right grain and sourced: *every pull request
receives a first-pass automated review before a human reads it, and a maintainer can
summon an agent into an issue or review thread without leaving GitHub*, from `py` at
pinned commit `b08bccfb` plus ledger rows F051/F052.

**JA-04 is closed, and I checked the closure rather than accepting the claim.** Revision 2
called policy-or-mechanism "the weakest of the three levels in `docs/port/README.md`". The
decision now withdraws that on both counts and cites spec §2 instead. I read
`docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md:47` directly: the row
reads "Policy or mechanism | Any deliberately shared value, protocol detail or tool, with
its owner decision or evidence | Only the aspects outside that agreement; low-level choices
can be shared when that level is intentional". The decision's quotation is verbatim, its
"unordered" characterisation matches a table that carries no rank, and its observation that
this level permits the *narrowest* variation of the three is correct against the third
column. The miscitation is named rather than quietly dropped.

The assignment itself is argued from §2's text, not from a rank, and the argument holds.
§2 requires a policy-or-mechanism agreement to carry "its owner decision or evidence"; no
owner decision registers this pair, and the decision says so plainly ("the owner has
reviewed R01 only"). The three supporting observations are each evidence-backed rather than
asserted: `ts` ships eight workflow files and zero `claude` paths at `cb1cbcb2` (check 6,
with both exits named including the `grep -c` exit 1 that *is* the zero result); nothing in
the capability is ecosystem-shaped, so no architectural pattern's Rust fitness is at stake;
and the reviewing entity is a paid third party reached with an organization credential,
which is exactly what §2 says needs an owner decision.

That last point is what makes the recommendation's conditional form coherent rather than
evasive: the level assignment and the recommendation are the same argument. If the
agreement level requires an owner decision and no owner decision exists, a decision that
asserted enablement would be contradicting its own §2 analysis.

**BASELINE-REVIEW.md.** F051 and F052 are `py-only`/`DIVERGENT`; `docs/port/BASELINE-REVIEW.md`
adjudicates only `COMMON → REUSE` and `ADOPT` rows, and `grep -n 'F051\|F052'` returns
nothing. There are no baseline-review rows this item touches, and the decision correctly
cites none.

**The verdict abstention is right.** The decision declines to assign `ADOPT` and states why
against `docs/port/README.md:70`'s definition ("taken as-is"), enumerating seven departures
from `py`'s configuration. Assigning the final verdict and editing the ledger are left to
the controller. That is the correct boundary.

## Design and evidence

**The four architectures were genuinely compared, and before the vendor choice.** A/B/C/D
are discriminated on a stated test — does the capability travel through "Use this
template"? — which is the right test because it is the prompt's own value test. B and C are
rejected on fit with the reason stated (repository *state*, not tree content), D on
maintenance cost. Inside A, `claude-code-action` is selected on three criteria, each with a
check behind it, not on popularity: it is the only candidate covering both members with one
component/credential/App installation; `v2` returns HTTP 404 across 287 tag refs; and the
maintainer runs both shapes against its own repository in a form readable at a tag. Adoption
figures appear *after* the fitness gates, which is the required order.

**The guard table is accurate as read in source.** I verified the load-bearing rows against
`review/evidence/action-entrypoint-plugins-v1.0.220.log` rather than accepting the
decision's summary:

- E2 quotes `sed -n '36,55p' src/entrypoints/prepare.ts` (exit 0): `setupGitHubToken()` at
  `:37`, `checkWritePermissions(` at `:44`. The ordering is read, not inferred.
- E2's `grep -c checkWritePermissions` returns 0 for both `src/modes/tag/index.ts` and
  `src/modes/agent/index.ts`; `checkHumanActor` is called per mode at `tag:43` and
  `agent:30`. The revision-4 topology correction (F1) is right and revision 3's was wrong.
- E3 quotes `token.ts:69-73` — `DEFAULT_PERMISSIONS` = `contents: "write"`,
  `pull_requests: "write"`, `issues: "write"` — plus `:100`'s merge,
  `:115-123`'s "body only when `permissions` is truthy", and `:121`'s exchange URL.

**So the central finding is established: on the assistant lane a write-capable Claude GitHub
App installation token is requested before any actor-trust check inside the action returns.**
The chain is complete and each link is quoted: `additional_permissions` is set, so
`parseAdditionalPermissions()` returns a value, so a body is sent carrying the merged
defaults, and the exchange at `:121` happens at `prepare.ts:37` — ahead of `:44` and ahead
of both mode calls at `:83`/`:85`. This is a fact neither prior auditor had, it strengthens
the objection my predecessor raised rather than answering it away, and the decision does not
soften it. One scope nuance, correctly handled by omission: `setupGitHubToken()` is
conditional on no `github_token` input being supplied, and the recommended configuration
supplies none, so the claim is made exactly for the configuration recommended.

**The review lane's unknown is handled in the honest direction.** No `additional_permissions`
means no body means a server-side scope that is "not readable from this source" — U17. The
decision refuses the convenient inference that `contents: read` on the job implies a
read-only token, writes "*unknown is not read-only*", and instructs "Treat the review lane
as write-capable until U17 says otherwise." An auditor's usual complaint is a gap resolved
toward the author's recommendation; here it is resolved against it.

**The subprocess scrub is recorded honestly, and the honest treatment cost the decision a
mitigation.** E4 quotes `action.yml:301` — the flag resolves from
`env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB || (inputs.allowed_non_write_users != '' && '1') || ''` —
and `:228`, with `:250`, `:269` and `:395` carrying the same non-empty gate. With
`allowed_non_write_users` at `""` and neither fixture setting the `env` variable, the flag is
empty and `bubblewrap`/`socat` are never installed. The decision states this at three sites,
removes the scrub from the standing mitigation set (security-claims row 8), and writes that
it "cannot be counted as an effective control in this configuration".

The question in my task is whether that is honest *given the recommendation leaves the
activating list empty*. It is, for two reasons. First, the decision declines the cheap route
it was offered: setting `env: CLAUDE_CODE_SUBPROCESS_ENV_SCRUB: '1'` would satisfy `:301` and
license the claim, while `:228` would still withhold the isolation dependencies — a flag
without the isolation it names. That half-state is recorded as U16 rather than recommended,
which trades a claimable control for an accurate one. Second, the empty list is not an
oversight the decision could costlessly fix: `allowed_non_write_users: "*"` is precisely S2
Phase 1's precondition, so the supported activation path would open the phase this
configuration is outside of. The decision names that tension itself at line 144. Three of the
disclosure's four remediations are claimed as active; the fourth is not; and revision 3's
"all four present at the pin" is withdrawn as the conflation it was.

**The marketplace removal is complete and its cost is stated rather than absorbed.** I
checked the fixtures, not the prose: `grep -c 'plugin_marketplaces\|plugins:'` returns 3 on
`candidate-claude-code-review.r4.yml` and 0 on `candidate-claude.r4.yml`, and reading the
file shows all three hits sit in the explanatory header comment — there is no active input.
`actionlint` is clean on both (check 16), and the assistant lane's YAML is byte-identical to
revision 3's below the header (`diff` exit 0). The three configuration changes the decision
claims — `plugin_marketplaces` removed, `plugins` removed, `prompt:` substituted — are
exactly what the fixtures show, with both prompt values quoted verbatim.

The mechanism behind the removal is read, not assumed: `MARKETPLACE_URL_REGEX`
(`install-plugins.ts:7-8`) anchors the string end to `.git`, so no ref, tag, commit or
fragment is expressible and the reference is *structurally* unpinnable rather than merely
unpinned; `addMarketplace` clones at run time (`:191-202`); `installPlugins` runs at
`base-action/src/index.ts:36`, after `setupWorkloadIdentity()` at `:18`, i.e. inside the
already-credentialed job; and even the marketplace *name* the `plugins:` input binds to lives
in `anthropics/claude-code@main`. Pinning the action pinned nothing about what the lane
executed, which is the contradiction the decision names against architecture A's own stated
virtue.

The cost is stated at full size: the template owner now authors and maintains
`.claude/commands/review-pr.md` and its `claude_args` tool allowance instead of inheriting a
maintained upstream plugin; P03 must write that file before the lane does anything useful;
and U18 records that *nothing here proves* the replacement resolves as a slash command, can
post, or is comparable in quality, with a P03 procedure that runs both forms on the same pull
request before the plugin option is deleted from the documentation. "Revision 4 removes a
maintained upstream prompt and replaces it with a file that does not yet exist, and says so"
is an accurate self-description. Only the general pin-form question goes to R20; the
configuration question is decided here, which repairs exactly the routing-instead-of-deciding
defect the empirical audit found. The decision also names its own provenance failure: the two
inputs came from `py` lines 49-51 and revision 3 inherited them unadjudicated — "the same
'`py` does it' failure the mandate exists to prevent, appearing in a decision that names that
failure elsewhere."

**JA-05 is closed with the citations checked.** I resolved the decision's raw-report citations
against the raws by line rather than trusting them: `opus:93`, `:95` (the two
`BASELINE-REVIEW:` lines), `:105` (the "fires at most once" claim the draft objection
refutes), `:167` (the ten-issue sample), `:589` (the marketplace trust edge); `codex:21`,
`:91`; `doxa-openai:138`, `:140`, `:348`, `:350`, `:388`; `doxa-gemini:185`;
`doxa-perplexity:41`. All resolve to the content claimed. One off-by-two, recorded as
observation 3 below.

## Completeness

**Structure.** The four H2s the runbook §5 requires are present and carry what it names:
`## Decision` with `### Principles and implementation` and a `re-verify:` line;
`## Parameters`; `## Empirical check` with toolchain, OS, working directory, command and
observed output; `## Engines` with all five reports, the disagreements and what resolved
each. No `## Supersedes`, correctly — this is a revision, not a reversal. The runbook's
"configuration, command and version-pin recommendations must execute" is satisfied within
P02's limits: `actionlint` executes on the recommended fixtures, and the pin resolves through
its annotated tag to a commit.

**Parameters — the reason revision 5 exists.** R18 owns nothing, matching the empty `owns:`
in `## Couplings` and the `—` in `research/CLAUDE.md`. The four `assumes` lines now carry the
registry value bare. I compared them against `docs/port/PARAMETERS.md:7-10` and all four match
byte-for-byte, including `msrv-policy`'s full sentence. The revision-4 commentary is moved to
prose below the list and loses nothing. No `CONFLICT:` line is correct: `consumes:` is empty
and none of the four fixed values is challenged.

**The eighteen unproven items are honest and complete.** U1 through U18 are contiguous, with
no gap and no duplicate, and each names a concrete P03 procedure rather than a wish. They
span the causal claim under the permission grant (U1), the inertness the entire shipping case
rests on (U2), the skip-not-fail guards (U3), the action-side gate (U4), CI reading (U5), the
trigger trade (U6), credential billing plus the `classify_inline_comments` behaviour change
(U7), variable shape (U8), responsiveness as a rate (U9), the adopter disable rate (U10),
exactly-once firing (U11), the prefilter's runtime effect (U12), the checkout ref against the
vendor's own wrong annotation (U13), the pre-check window (U14), two unfetched citations
(U15), the scrub half-state (U16), the review lane's token scope (U17), and the replacement
prompt (U18).

I tested them for the failure that got revision 1 rejected — a runtime behaviour asserted in
prose while an unproven row lists it as open. Each site is hedged: the recommendation
paragraph itself carries the U2 caveat; "What enabling costs" point (1) says the
consumer-inertness defence "rests entirely on U2" and that if U2 fails "the runner-up would
then win outright"; the enable-flag paragraph calls the inert effect "a design purpose, not
an observed one"; and §1 of the disagreements says that if U2 or U12 fails in P03 the
"neither" case wins outright. The prefilter, the checkout, the scrub and the token scope are
hedged the same way at every site I checked. B1–B8 are stated as proposed with none executed.

**The `re-verify:` line is a real trigger set, not a date.** It fires on the owner recording
acceptance *or refusal* — the condition the recommendation turns on; on upstream making the
scrub independent of `allowed_non_write_users` or a marketplace URL pinnable, either of which
reopens a revision-4 decision; on a disclosure with no advisory, which is the reporting gap
this item found; and on `#1068` closing. It also states that the pin is stale on a scale of
days and must be re-resolved unconditionally at implementation time.

**Consistency with the empirical audit.** `review/audit-codex.md` records the same decision
sha256 I computed, `approve`, no findings. Its five points and my independent reads agree on
every fact: the entrypoint ordering, the merged write permissions, U17's server-side scope,
the scrub's inactivity, the fixtures' freedom from active marketplace inputs, and the
registry match on the four `assumes` lines. It notes one GitHub Docs raw URL now 404s as
documentation-path drift; that touches no decisive claim, since check 11's substance is
carried by the quoted excerpts in `github-docs-pull-request-ref.log`. I found no conflict
between the two audits.

**Scope discipline.** The decision claims no file outside this run's `review/` directory was
created or modified, that no workflow was installed, no credential used and no provider run
occurred, and that `claude plugin marketplace add` is quoted from source and never executed.
The evidence log's commands are read-only `curl`/`grep`/`sed`/`git show`/`actionlint`/`diff`
throughout, consistent with that claim. Both post-capture log corrections — E7's mislabelled
command line at revision 4, G3's at revision 3 — are disclosed in the decision with the
statement that no output line was altered, and revision 4 re-ran the affected fetch under its
real argv as block E9. Disclosing a mislabelled command line that no one would have caught is
the behaviour that makes the rest of the evidence trustworthy.

## Findings

No acceptance-blocking finding. Four non-blocking observations, recorded because the record
should carry them, and none of which changes the recommendation, misstates a risk, or leaves
the owner unable to decide.

1. **B9 quotes a run-log string and a source line this run's evidence does not carry.** B9
   asks P03 to assert the run log contains `No marketplaces specified, skipping marketplace
   setup`, attributed to `base-action/src/install-plugins.ts:230`. Neither the string nor line
   230 appears anywhere in `action-entrypoint-plugins-v1.0.220.log`: E5's `grep` covers `:7-8`
   and `:191-202` only. E1 fetched the whole file (HTTP 200, 7918 bytes), so the line was
   plausibly read in the scratch copy, but the decision's own standard — the one that
   motivated its two disclosed log corrections — is that anything relied on appears in the
   log. Non-blocking because B9 is a proposed P03 assertion, not a claim about anything
   observed here, and a wrong string simply fails at P03 and is corrected. Closed by grepping
   `:230` at the pin and recording the quotation.

2. **The residual's consequence ceiling is stated at two sizes and never reconciled.** Line
   22 quotes the disclosure describing the exchange output as an installation token with write
   access to "contents, issues, pull requests **and workflows**". Lines 24, 34 and 114 and both
   fixture headers state the *requested* set from `token.ts:69-73` as contents/pull_requests/issues
   write, with no `workflows`. Both are accurately sourced and the decision never claims they
   are the same set, but an adopter reading only the fixture header — which the decision says
   is what gets copied — takes away the smaller number, and `workflows: write` is materially
   worse than `contents: write` because it reaches the workflows that gate the token. U17
   holds the review lane's scope open; nothing holds this open for the assistant lane. One
   sentence reconciling requested scope with the disclosure's observed scope would close it.

3. **One corroborating citation is off by two lines.** The decision attributes "a trusted
   association prefilter where practicable" to `raw/doxa-openai.normalized.md:388`; the quote
   is at `:386`, and `:388` is "a same-repository check before operating on a PR" — which the
   decision separately and correctly cites as `:388` in §13. The quotation is verbatim and the
   engine does make the ask, so the substance is unaffected.

4. **Every named bound on the residual is workflow-side.** The six bounds are the fork guard,
   the bot guards, the enable flag, the `author_association` prefilter, a pin above both fix
   versions, and a configuration outside every published phase. No repository-side control —
   branch protection, rulesets, required reviews, environment protection — is named, and those
   materially change what a write-capable token can actually land. This does not make the
   residual undecidable, since "a write-capable App token on this repository" is decidable as
   stated, and the owner deciding is the same person who controls those settings. Worth naming
   because P03 will need them.

## Assessment

**I now agree the evidence supports this recommendation, and I did not expect to write that
sentence from this seat.** My predecessor rejected revision 2 and answered "would you ship
this to strangers" with "not as it stands". Revision 5 is a different recommendation, not a
better-argued version of the one that was refused.

**The moved recommendation is genuinely supported and does not merely relocate a decision the
research should have made.** I applied two tests. First: could further research collapse the
choice? No — the decision establishes that the residual is a property of the *capability*,
not of the files, so the runner-up inherits it at adoption time rather than removing it, and
no configuration separates a trusted author's own words from untrusted text that author
pasted. Both branches carry the same residual and differ only in who accepts it and when.
That is definitionally an owner risk judgement, and spec §2's own requirement for this
agreement level — "with its owner decision or evidence" — says so independently. Second: does
the conditional leave P03 with a buildable state under every branch? It does. Acceptance
recorded → both files ship and the origin enables. Acceptance withheld → both files are
deleted and the opt-in recipe ships. Acceptance not yet recorded → the files sit with their
variables unset, which the decision itself says is functionally equivalent to the runner-up
because nothing runs either way. All three are stated; none is left for someone to invent.

Decisive for me: the research did not decline the questions it *could* settle. Whether the
guard is expressible at the job level — settled, by the context table and by `actionlint`
rejecting the alternative. Whether the marketplace admits a pin — settled in source, and then
*acted on* rather than routed. Whether the scrub is active — settled, against the decision's
own interest. What the assistant lane's token carries and when it is minted — settled in
source. What the review lane's token carries — recorded as unreadable, with the unknown
resolved toward "assume write-capable". The owner is left exactly one question, and it is the
one only an owner can answer.

Two conditions of different kinds sit under the recommendation, and the decision states both
where a reader meets them rather than burying one: owner acceptance gates *enablement*, and
U2 gates whether shipping inert files is defensible at all. Point (1) of "What enabling costs"
says so plainly — if U2 fails, a stranger gets a red check rather than an inert file, "which
is precisely the `codex`/`doxa-openai` objection and a reason the runner-up would then win
outright." A decision that hid that dependency would be the dodge; this one names it inside
the recommendation paragraph.

**The named residual is described precisely enough to accept or decline, which is the hinge.**
Trigger: text an OWNER, MEMBER or COLLABORATOR writes into any of four surfaces on a public
repository. Mechanism: nothing separates that author's own words from untrusted content they
quoted. Capability at stake: an App installation token requested before any actor-trust check
returns, write-capable on the assistant lane as read in source, unknown-and-assumed-write on
the review lane. Bounds: six, enumerated. Non-bounds: enumerated too — the prefilter is not a
permission check, the scrub is inactive, U2 and U12 are unproven. Class evidence: the
researcher's own "~50 separate vulnerabilities … bypass the permission system", plus S2's
variants exploited in the wild. Five things an adopter must understand are written into the
fixture headers, where the copy happens, rather than only into a document nobody carries
forward; I read both headers and all five are there, distributed across the two lanes they
apply to. Observations 2 and 4 above would sharpen the ceiling and the repository-side bounds,
but an owner can answer the question as posed today.

**On the specific things I was asked to judge:** the guard table is accurate against the
source the log quotes, including the finding that a write-capable App token is minted before
either actor check runs — I verified the whole chain link by link rather than accepting the
summary. Recording the scrub as available-but-inactive is the honest treatment precisely
because the activating list is empty: the decision refused the half-state that would have let
it claim the control, and the supported activation path would open the S2 phase this
configuration is outside of. The marketplace removal is complete in the fixtures, not merely
in the prose, and its cost is stated at full size — a maintained upstream artifact traded for
one that does not yet exist, with U18 refusing to claim the replacement works. The eighteen
unproven items are honest, contiguous and complete, and I found no site where prose asserts
what an unproven row holds open. Nothing is asserted more strongly than its evidence supports,
with the four observations above as the exceptions, all of them minor and none load-bearing.

This decision repeatedly resolves ambiguity against its own recommendation — the token scope,
the scrub, the marketplace, the `py` inheritance it names as its own failure, the two log
corrections nobody would have caught. That pattern is the reason I credit the conditional
rather than reading it as hedging.

**Ready to publish: yes.** Verdict `approve`, no unresolved findings. Both prior objections
are answered; the two audit seats now concur; the recommendation stands in a form neither
prior objector refused. **This approves a P02 research decision and nothing else.** It is not
approval to implement, to configure a credential, to enable either lane anywhere, or to run a
live validation — and it does not record the owner acceptance the recommendation turns on.
That acceptance is the owner's to give or withhold, and until it is on record the shipped
state and the runner-up are the same inert thing.
