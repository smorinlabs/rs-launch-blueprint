# 2026-09-27 — R08 — workflow-permission-hardening (bundle, Focused) — decision (revision 4)

**Revision note, revision 4.** Revision 4 is a **findings repair**. It
answers the three round-3 findings: one in `audit-fable.r3.md` (JF-1) and
two in `audit-codex.r3.md` (F1, F2). Revision 3 (sha256 `0153ff05…59b8065`)
is preserved byte-identical at `review/R08-r3-snapshot.md` (sha256
`0153ff05b2612fd5827817c182e12824bada33c70b9ff7bb86d38ae1759b8065`).
**The recommendation does not move.** The values stay as they were:
deny-all at the top level, `false` by default, and an explicit commented
`true` as the only credential exception. One enforcement claim narrows: CI
checks that an exception's comment is present, and review checks that it
names the later step (F2).

| Audit finding | What changed | Where |
|---|---|---|
| `audit-fable.r3.md` JF-1: the follow-on counts "py 7 / ts 2 top-level rewrites" contradict the difftree exemption | **Counts corrected, no value moved.** py needs 6 top-level rewrites and ts needs 1. Those are the files the script names on the pinned trees (`r08-policy.log:49-56`). The seventh py file and the second ts file are the verbatim `difftree-pr-comment.yml`, which stays exempt in py and ts as it does in rs (D3). The census counts (7 of 19, 2 of 8) are unchanged, because they count files whose top level is not `{}` | `### Principles and implementation`, migration paragraph; `## Engines`, "What P03 must validate" |
| `audit-codex.r3.md` F1: `inputs/EXECUTION.json` is no longer byte-identical to the live policy; `I-policy-live` fails | **Invariant scoped to R08; frozen inputs not rewritten.** This worker may write only under `review/`, so a second re-freeze of `inputs/` and `manifest.json` was not possible. The live policy is shared: other items' `empirical_auditor_overrides` entries changed after the freeze (6 keys frozen, 37 live), and nothing that names R08 changed. `I-policy-live` now asserts that the frozen and live files agree on every R08 key: `items.R08`, `engine_overrides.R08` and `empirical_auditor_overrides.R08`. R08 has no `empirical_auditor_overrides` entry in either file, so its empirical seat is the codex default. That default is the seat that wrote `audit-codex.r3.md`. The log prints both file hashes and both key lists, so the drift is dated. **Extension, disclosed:** the rerun found a second failure of the same kind, not named by the audit. `I-other-CLAUDE.md` failed because the live `research/CLAUDE.md` changed other items' rows after the freeze. It is scoped to R08's row in the same way. `r08-refreeze.sh` is not edited or rerun. Its committed log is the one record of the write, and its no-write guard compares `required_engines` with `items.R08.engines`, which is an R08-scoped test | `r08-inputs.sh` (`I-policy-live`, `I-other-CLAUDE.md`); `r08-inputs.log:48-53,65-67`; observation 18; `## Engines` evidence checks; gap (a) |
| `audit-codex.r3.md` F2: the candidate accepts `persist-credentials: true # ok`, so B4's "checked by CI" overstates what CI checks | **Weakened to presence plus review; no new check.** A machine-checkable reference to the later step would be a new evidence programme. The line check accepts any non-empty trailing comment (`check-workflow-permissions.candidate.sh:74`). The decision now says so: CI owns the presence of the comment, and review owns whether it names a real later step. The candidate's header comment made the same overclaim and is corrected. Only comment lines changed; the code is byte-identical. The candidate's sha256 moves to `6176af76…9f1357b` | Recommendation paragraph; B4; LOW paragraph; migration paragraph; candidate header `:8-15`, `:35-37` |

**Reruns in this revision.** `r08-inputs.sh` and `r08-policy.sh` were
rerun between 2026-09-27T18:15Z and 18:20Z. `r08-inputs.sh`: 24 PASS, 0 FAIL
(`r08-inputs.log:92`). `r08-policy.sh`: 28 PASS, 0 FAIL. Its log differs
from revision 3's only on line 2 (timestamp) and line 7 (the candidate's
new sha256), so no citation into it moved. `r08-refreeze.log`,
`r08-zizmor.log` and `r08-sources.log` are carried from revision 3
unchanged. Revision 3's `r08-inputs.log` is preserved at
`review/evidence/r3-logs/r08-inputs.log`. Every `r08-inputs.log:N`
citation in the revision 3 and revision 2 notes below points into that
preserved file. Every such citation outside those notes was re-resolved
against the new log. The revision 3 note's statements that the
frozen policy is "byte-identical to the live policy" and that
`I-policy-live` tests byte identity describe revision 3's check. F1
above supersedes them.

Actor `synth-opus-R08-r4-2026-09-27`, model `claude-opus-5-5`, family
anthropic, item kind `bundle`, effort tier `focused` (two engines), CLI run
2026-09-27 (UTC, per the log timestamps). **Independence disclosure.** This
synthesizer runs on the same model ID as the Opus leg (`raw/opus.md:3`). It
is a fresh context that produced neither raw report and none of revisions
1–3's evidence. RUNBOOK §2 names a fresh Fable context as the default
synthesizer; this revision was dispatched to an Opus seat.

**Revision note, revision 3.** Revision 3 is an **inputs re-freeze, not a
findings repair**. It carries out the controller ruling for revision 3:
re-freeze this run's `inputs/` against the current prompt and policy, update
the I1 hash, rerun `r08-inputs.sh` to green, and cite the live Q17.A override
as the authority for the Codex-to-Muse engine substitution, without weakening
any check. Revision 2 (sha256 `701603be…f37cc5`) is preserved byte-identical
at `review/R08-r2-snapshot.md` (sha256
`701603bea4f8dcc2b82f3c4c3b28d60568379d106c008e1d37503f3208f37cc5`).
Revision 2 had already answered both round-1 findings (table under revision
2's note, below); revision 3 changes nothing else. **The recommendation does
not move.** The re-freeze changed only the engine lines of the frozen prompt
and policy, and no part of the recommendation rests on which engine
produced a leg.

| Input | Revision 2 | Revision 3 | Evidence |
|---|---|---|---|
| `inputs/prompt.md` | sha256 `656dc096…`, line 22 `- engines: codex, opus` | sha256 `4eb4fd64…`, byte-identical to the canonical prompt | `r08-refreeze.log:20`; `r08-inputs.log:17-19` |
| `inputs/EXECUTION.json` | sha256 `2a3ca155…`, `items.R08.engines` = `codex, opus`, no R08 override | sha256 `c670184d…`, byte-identical to the live policy | `r08-refreeze.log:16`; `r08-inputs.log:42-48` |
| `manifest.json` `input_hashes` (the I1 hash) | `prompt`, `policy`, `policy_item` as recorded at preparation | those three rewritten; the other five unchanged | `r08-refreeze.log:8,13`; `r08-inputs.log:6-12,27` |
| `manifest.json` `required_engines` | `codex, opus` | `muse, opus`, equal to the live policy | `r08-refreeze.log:6,12`; `r08-inputs.log:13-14` |
| `manifest.json` `events` | one `ready` event | plus one migration event holding the previous engines, tier and all eight previous hashes | `r08-refreeze.log:14`; `r08-inputs.log:21-27` |
| `I-prompt-canon` | FAIL, left failing on purpose | PASS; the assertion is unchanged | `r08-inputs.log:19` |

**How the re-freeze was done: `manifest.json` was hand-edited.** The
controller ruling's "update the I1 hash" clause is the authority. The edit
was made by `review/evidence/r08-refreeze.sh`, **not** by `run
migrate-engines`: runner commands were outside this worker's permit. The
script is the file-level equivalent of that command. It copies the canonical
prompt and the live `EXECUTION.json`, `CLAUDE.md` and `PARAMETERS.md`
verbatim. It writes `parameters.json` and `prerequisites.json` in the
runner's `write_json` format and computes all eight hashes as
`refresh_input_snapshots` does (`scripts/research_runner.py:198-218`). It
applies `migrate_engines`'s refusals and appends an event in that command's
shape (`:241-300`). `state` and `operations` were not touched. The proof
that the result is what the runner would have produced is the runner's own
read-only `freshness_errors` (`:168-183`): it returns 0 errors
(`r08-refreeze.log:22-23`, `r08-inputs.log:66-67`). Only `prompt.md` and
`EXECUTION.json` changed bytes; the other four snapshots are byte-identical
to revision 2's (`I-migration-scope`, `r08-inputs.log:27`). The run
directory is not tracked by git, so the two replaced files are preserved at
`review/evidence/r2-frozen/`. Their hashes equal the event's previous
hashes (`r08-inputs.log:28-29`). With those files and the event, the
controller can restore revision 2's inputs byte for byte and apply `run
migrate-engines` instead, or accept this edit.

**Check changes, none weakening.** `I-prompt-canon` is unchanged and now
passes. I1 grew from four to six file snapshots, and `I1-engines` now
requires the manifest's engines to equal the live policy's
(`r08-inputs.log:6-14`). `I-prompt-delta` keeps its assertion that the
difference is exactly the two Q17.A hunks, line 22 and the line-69
substitution sentence. It now compares the preserved revision 2 prompt
with the re-frozen one (`:31-40`). Revision 2's `I-policy-frozen` assertion
(codex, opus, no R08 override) survives as `I-policy-r2` on the preserved
bytes. `I-policy-frozen` now asserts `muse, opus` in both places.
`I-policy-live` is tightened from item equality to byte identity
(`:46-48`). The new cases are `I-migration-engines`, `I-migration-hashes`,
`I-migration-scope`, `I-r2-prompt`, `I-r2-policy` and `R-fresh`.
Totals: revision 2 had 13 PASS and 1 FAIL; revision 3 has 24 PASS and 0
FAIL (`:85`).

**Engine substitution authority (Q17.A).** Owner decision Q17.A
(2026-09-27) extends the Muse-for-Codex substitution to R08
(`research/RUNBOOK.md:73-76`, `r08-inputs.log:51-56`). The live policy
names `muse, opus` in both `items.R08.engines` and `engine_overrides.R08`
(`r08-inputs.log:45`). Q17.A is the authority for the `raw/muse.md` leg.
The run's frozen inputs and manifest now say the same
(`r08-inputs.log:13-14,44`).

**Other reruns.** `r08-policy.sh`, `r08-zizmor.sh` and `r08-sources.sh` were
rerun. Each log is byte-identical to revision 2's except the timestamp on
line 2, with one exception: a single live figure moved. zizmor's `pushed_at`
changed from `2026-09-26T00:26:56Z` to `2026-09-27T05:17:46Z`
(`r08-sources.log:230`, observation 6). No line moved, so every revision 2
citation into those three logs still resolves to the same text. The
`r08-inputs.log` layout changed, and every citation into it was re-resolved.

Actor `synth-opus-R08-r3-2026-09-27`, model `claude-opus-5-5`, family
anthropic, item kind `bundle`, effort tier `focused` (two engines), CLI run
2026-09-27. **Independence disclosure.** This synthesizer runs on the same
model ID as the Opus leg (`raw/opus.md:3`). It is a fresh context that
produced neither raw report and none of revisions 1–2's evidence. RUNBOOK §2
names a fresh Fable context as the default synthesizer; this revision was
dispatched to an Opus seat.

**Revision note, revision 2.** Revision 2 answers both round-1 audits of
revision 1 (sha256 `157de4a6…0939076`), each verdict `reject` with one
finding. Revision 1 is preserved byte-identical at
`review/R08-r1-snapshot.md` (sha256
`157de4a6604594ff1bb0b2681c61118149e7036bcd2728467cd04a3cd0939076`).

| Audit finding | What changed | Where |
|---|---|---|
| `audit-fable.md` Finding 1 (JF-1/JF-10): the bot job re-granted `contents`/`pull-requests`/`issues: write` to `GITHUB_TOKEN`, which no step in the job uses under R21's credential | **Recommendation value moved.** The bot job's re-grant is now `contents: read` alone. The commit, push, pull request and label ride the action's own App installation or fine-grained PAT token (R21 DECISION:15, :23). The scope table, the minimal example, `fixtures/contributors.good.yml`, D6, the migration paragraph and the py/ts follow-on are corrected; D10 records that this overrules both legs; criterion 12 is the P03 check. For internal consistency (JF-1), the same test was applied to the only other job whose action carries its own token. **The `release-please.yml` job's re-grant moves from `contents`/`pull-requests: write` to none.** The action's `github.token` default applies only when `token:` is not specified (`metadata-syntax.md:84`); F072's shape always specifies it; and an empty value fails `required: true` (`core.ts:154-155`). So no configuration reaches `GITHUB_TOKEN` (obs. 19, D11, criterion 13) | `### Principles and implementation`; `## Engines` D6, D10, D11 |
| `audit-claude.md` Finding 1: rule 2 missed `persist-credentials: 'true'`, zizmor's default persona misses it too, so B3/B4 were falsified | **Enforcement rule widened, recommendation unchanged.** Rule 2 now flags any explicit `persist-credentials` value other than `false` that lacks a non-empty trailing comment — every quoting, every case (checkout upper-cases the input, `input-helper.ts:167-168`), and `${{ … }}` expressions — and rejects the key inside a flow-style map. Seven new fixtures (NC2b, NC4c–NC4h) execute each case under the script, and four of them under zizmor. The candidate header now states that zizmor's default persona is not a backstop for rule 2, and corrects the flow-style rule-1 statement the audit flagged | B3, B4, LOW paragraph, criteria 3 and 5, observations 14–15, 17 |

The claude audit's two non-blocking observations are also repaired: the
candidate header's flow-style statement (now "rejected rather than evaded",
executed as NC2b, `r08-policy.log:20`), and the drift-table citation for "py:
7 of 19 workflows not `{}`", which now cites the census for the 7 and the
policy log for the 6 files the script names with the difftree file exempt.

Every script under `review/evidence/` was rerun by this revision and every
log was overwritten; no log is carried. `r08-sources.sh` gained §6 (credential
sources and flag parsing) appended after its former last section, so every
revision-1 citation into `r08-sources.log:1-384` still resolves to the same
text; the live figures and pins reproduced unchanged. `r08-inputs.sh` is new.

Revision 2's engine-substitution paragraph reported `I-prompt-canon` as a
FAIL and recorded the re-freeze as a gap for the controller. It is preserved
at `review/R08-r2-snapshot.md:26-39`, and its `r08-inputs.log` citations
point into revision 2's log, which revision 3 overwrote. Revision 3's
re-freeze, above, supersedes it.

Revision 2 actor `synth-opus-R08-r2-2026-09-27`, model `claude-opus-5-5`, family
anthropic, item kind `bundle`, effort tier `focused` (two engines), CLI run
2026-09-27. **Independence disclosure.** This synthesizer runs on the same
model ID as the Opus leg (`raw/opus.md:3`). It is a fresh context that
produced neither raw report and none of revision 1's evidence. RUNBOOK §2
names a fresh Fable context as the default synthesizer; this revision was
dispatched to an Opus seat.

**Revision note, revision 1.** First synthesis of the two Focused legs,
`raw/muse.md` (262 lines) and `raw/opus.md` (947 lines, `claude-opus-5-5` per
its header). Nothing has been published for R08, so there is no
`## Supersedes`. This revision was written under the S10 race protocol: the
incumbent synthesizer produced no decision, so every byte of
`review/evidence/` below was produced fresh by this synthesis and no finding
rests on the stalled attempt's files.

Revision 1 actor `s10-race-challenger-2026-09-27`, model Muse Spark (Meta
contributor model; exact build unstated by the harness), family meta. The
`codex` seat's leg arrived as `raw/muse.md`, which states no model string;
the `opus` seat's leg arrived as `raw/opus.md`, which states
`claude-opus-5-5`. (Revision 2 reading: under Q17.A the first seat is the
`muse` seat, not a `codex` seat.)

## Decision

**Status.** This decision is a **proposal validated in the implementation
phase** (owner ruling, 2026-09-10). `rs-launch-blueprint` has no `.github/`
tree today. P02 is research; P03 builds the template and its CI proves or
disproves what is recorded here. Nothing below has run on a GitHub-hosted
runner: no workflow was dispatched and no gate has failed a real pull request.
A recommendation that does not survive implementation is **revised against
this recorded research**, not researched again from scratch.

**Recommendation — one stack: the named pattern `uniform default-deny
workflow tokens`.** Every template-authored workflow declares top-level
`permissions: {}` — the contributors-bot workflow included, with no
discretionary exception. Every job that needs a scope re-grants it in its own
`permissions:` block, with a per-scope reason comment on every scope other
than `contents: read`. A job's re-grant covers only the steps that
authenticate with `GITHUB_TOKEN`; a step that authenticates with its own App
or PAT token adds nothing to it, so the contributors-bot job re-grants
`contents: read` alone and the release-please job re-grants nothing
(revision 2). Every `actions/checkout` step sets
`persist-credentials: false`. The only exception to the credential rule is
an explicit `persist-credentials: true` with a trailing reason comment naming
the later step that needs the credential; no template workflow uses it
today. Enforcement is two checks, each rule owned by exactly one of them:
R20's existing `zizmor .github/` step (default persona, non-SARIF, no
`min-severity` above `low`, `artipacked` and `excessive-permissions` not
disabled) owns credential persistence on an unset checkout, and
`scripts/check-workflow-permissions.sh`, a step of R11's always-run
`hygiene` job, owns the `{}` rule and the presence of a reason comment on
any explicit value other than `false`. Whether that comment names the later
step is checked in review, not by CI (revision 4). One vendor-canonical file adopted
byte-identical, `difftree-pr-comment.yml`, is exempt from the `{}` rule by
exact name, mirroring R20's per-file exemption for the same file (R20
DECISION:148-166).

**Ledger rows this decision settles: F029 and F030**
(`docs/port/COMMONALITY.md:35-36`, both `ci-workflows`, both `different`,
both `DIVERGENT`, both `Item: R08`). F029 (checkout
credential-persistence breadth) resolves to the ts shape: broad
default-`false`. F030 (contributors-bot declaration style) resolves to the
ts shape: deny-all-plus-re-grant, bot included; the job's re-grant is
`contents: read`, because R21's accepted credential carries the writes
(revision 2). F028 (the deny-all baseline itself, `COMMON → REUSE`) is
inherited and not re-decided; its conformance gap is carried below.

**BASELINE-REVIEW carried through for controller adjudication, not resolved
here.** The opus leg raises a line against F028; this synthesis re-ran the
census behind it and confirms the numbers, so the line is forwarded with this
run's evidence rather than the leg's:

> BASELINE-REVIEW: F028 — top-level deny-all permissions baseline with
> per-job least-privilege grants — the ledger records it as COMMON → REUSE
> "inherited as-is", but neither source applies it to every workflow: py
> declares top-level deny-all in 12 of 19 workflow files and ts in 6 of 8
> (fresh census at the programme pins, `review/evidence/r08-sources.log`
> §1–§2; non-conformant: py `claude-code-review`, `claude`,
> `dependency-review`, `difftree-pr-comment`, `press-verify`,
> `template-receipt-guard`, `update-contributors`; ts `dependency-review`,
> `difftree-pr-comment`) — propose re-describing F028 as "principle common,
> conformance partial in both sources" and routing the universal application
> to R08's recommendation. Affected items: R08 (this), R11
> (`ci-job-structure` names the placement), R20 (its `zizmor` step carries
> half the enforcement). The ledger is not edited here; the controller
> adjudicates it.

### Principles and implementation

**Shared requirement, source, and agreement level.** The principle is **least
privilege for the workflow token, applied by default rather than by
demonstrated need**. Its sources are GitHub's secure-use page ("make sure that the
`GITHUB_TOKEN` is granted the minimum required permissions", good practice
"to set the default permission ... to read access only ... increased, as
required, for individual jobs", `r08-sources.log:265-270`) and zizmor's
`artipacked` and `excessive-permissions` audits (remediation text at
`r08-sources.log:315-331`). It is agreed at the **policy** level: every
repository in the family states the same rule and enforces it mechanically.
Nothing in it is language-specific — a workflow token behaves identically
whether the job runs `cargo`, `uv` or `pnpm` — so the low-level values
(`permissions: {}`, `persist-credentials: false`) are identical across py,
ts and rs. This is the rare case where the evidence supports the same
low-level value in every ecosystem.

| Must agree across py, ts, rs | May vary |
|---|---|
| B1–B4 below: deny-all top, per-job re-grant, `false` default, explicit commented non-`false` value as the only credential exception, CI enforcement | Comment wording, the local check's implementation language, which enforcement layer reports first |
| The per-workflow scope sets (bot: `contents: read`, its writes riding the App or PAT token; release: none, its writes riding F072's App or PAT token; publish: contents read + id-token write) | Nothing further varies; the values are platform facts |

**Essential behaviors.**

- **B1.** No template-authored workflow grants any scope at the top level.
  Every token scope a job holds is visible in that job's own `permissions:`
  block, and a job holds only the scopes that its `GITHUB_TOKEN`-using steps
  need.
- **B2.** No checkout step leaves a reusable credential on disk unless a named
  later step needs it.
- **B3.** An exception to B2 is explicit and carries a non-empty trailing
  reason comment. Any explicit `persist-credentials` value other than `false`
  counts as an exception, whatever its quoting, its case or whether it is an
  expression, because `actions/checkout` upper-cases the input and compares
  it with `TRUE` (`input-helper.ts:167-168`, `r08-sources.log:422-425`). The
  template spells an exception `persist-credentials: true`, block style. An
  exception is never an omission.
- **B4.** B1, B2 on an unset checkout, and B3's explicit-and-commented form
  are checked by CI, so a new workflow or a new job cannot silently regress
  them. Every spelling that revision 1 let through, and every other
  spelling executed here, now fails the check that owns it (criteria 2–4).
  CI does not check what the comment says. The script accepts any
  non-empty trailing comment (`check-workflow-permissions.candidate.sh:74`),
  so `persist-credentials: true # ok` passes. Whether an exception names a
  real later step, as B2 requires, is a review check (revision 4).

**HIGH Q1 — broad or narrow `persist-credentials: false`? Broad.** Three
grounds, each executed or pinned-read here. First, the threat is ambient:
with the default, the checkout step persists a token (checkout README:
"The auth token is persisted in the local git config", opt out with
`persist-credentials: false`, `r08-sources.log:271-274`), and any later step
in the job inherits it; a "demonstrated risk" standard inverts the burden.
Second, the reference auditor checks exactly the broad rule: zizmor
`artipacked` reports an unset input at the default persona and only an
explicit `true` at the auditor persona (`artipacked.rs:133-141`,
`r08-sources.log:293-302`), executed as exit 12 on NC1 and exit 0 on NC4b
(`r08-zizmor.log` §2). Third, v6's `$RUNNER_TEMP` storage narrows only
artifact leakage; a hostile step in the same job reads `$RUNNER_TEMP` as
easily as `.git/config`, which is why zizmor still reports v6+ at `Low`
(`determine_severity`, `r08-sources.log:275-292`) rather than going silent.

**HIGH Q2 — contributors-bot: deny-all or explicit top-level grant?
Deny-all, no exception.** py's shape (three writes at top level,
`r08-sources.log:88-103`) and ts's shape (`{}` at top, re-granted at job
level, `r08-sources.log:104-121`) grant the same effective token today. The
uniform shape wins on growth-safety and single-rule enforceability, and the
growth case is executed, not argued: appending a second job to py's shape
silently endows it with three write scopes, which zizmor flags at the
default persona (NC3: three `excessive-permissions` findings, exit 14,
`r08-zizmor.log` §2–§3) while `actionlint` stays silent
(`r08-policy.log:66`). Under the uniform shape the same second job holds no
scope until someone writes one — top-level `{}` applies to all jobs in the
workflow (`r08-sources.log:257-264`), and GitHub then adjusts per job
configuration. A "small fixed set" is not a stable property of a file that
template adopters will edit. What the bot job re-grants is a separate
question, answered in the scope table below: under R21's credential it is
`contents: read` alone.

**HIGH (owner clarification) — principles across py, ts, rs; drift
classified.** No ecosystem difference is justified: the token model is the
platform's. Every observed difference is drift:

| Observation | Classification | Evidence |
|---|---|---|
| py: 31 of 32 checkouts unset | missing capability — the policy was never stated in py | census `r08-sources.log:13-66`; py's one `false` is inherited from the verbatim difftree template (`:205-212`) |
| py: 7 of 19 workflows not `{}` | accidental drift from py's own 12-of-19 majority | census `r08-sources.log:13-66` (7 files); the script names 6 of them at `r08-policy.log:48-54`, the seventh being the exempt verbatim difftree file |
| ts: bot checkout at `update-contributors.yml:67` without the flag | accidental drift against ts's own "Every checkout step sets `persist-credentials: false`" | `r08-sources.log:85-86` vs `:149-152` |
| ts: `dependency-review.yml` top-level grant | accidental drift against ts's own "other six workflows follow the same shape (deny-all baseline...)" | `r08-sources.log:67-84` vs `:147-148` |
| `difftree-pr-comment.yml` top-level grant in both repos | inherited from the vendor-canonical template ("copy it verbatim"), byte-identical 3771 bytes in both | `r08-sources.log:128-146`; vendor identity per R20's accepted exemption |
| Release job token writes in both repos | a copied convention: both grant `contents`/`pull-requests: write` while passing release-please an always-specified App-or-PAT `token:` that never reaches `GITHUB_TOKEN`; ts's own comment says `GITHUB_TOKEN` is "intentionally NOT a fallback" | `r08-sources.log:164-181`, `:420-421`, `:454-459` |
| Bot job token writes in both repos | a credential consequence, not a shape choice: ts grants them because its `pat:` input *is* `secrets.GITHUB_TOKEN` (`r08-sources.log:126`); py grants them at top level while its `pat:` is already R21's dedicated secret | R21 DECISION:15 rejects `GITHUB_TOKEN` as the credential; `r08-sources.log:409-412` |

**MEDIUM — where `false` breaks a legitimate step.** Two real breakage
classes. (1) A later step pushes with the checkout token: the answer is B3,
an explicit commented `true` (precedent: `clap-rs/clap` `template.yml`,
carried from the opus leg, not re-fetched). (2) A later step re-fetches on a
private repository: ts records that with `false`, "a fetch here dies with
'could not read Username' (v0.1.2's publish failed exactly so)" and the fix
is structural — `fetch-depth: 0` at checkout, never re-fetch
(`r08-sources.log:182-195`). **No rs template workflow needs `true`
today**: `ci.yml` fetches once (R11's owned value already states
"fetch-depth 0 and persist-credentials false"); `release-please.yml` has no
checkout; `publish.yml` fetches once and publishes through OIDC; and the
contributors action sets its own authenticated origin URL (`set-url` at
`src/index.ts:592`, `x-access-token` at `:614`,
`r08-sources.log:355-384`), so the checkout token is unnecessary there too.
The exception path exists for adopters.

**LOW — mechanical enforcement.** Yes, and most of it is already in the tree
through R20. `persist-credentials` on an unset checkout is enforced by zizmor
`artipacked` at the default persona (executed: NC1 exit 12, P0 exit 0). The
top-level `{}` rule and the reason-comment rule are enforced by the
repo-local script, because zizmor's default persona covers neither:

- zizmor demotes the single-job top-level finding to pedantic (executed:
  NC2 exit 0 at default, exit 14 at `--persona=pedantic`, `r08-zizmor.log`
  §2/§4), and R20 has already rejected `--persona=pedantic` as a global
  switch (R20 DECISION:124-136).
- zizmor is **not** a backstop for the reason-comment rule. `artipacked`
  matches the parsed value exactly (`r08-sources.log:427-442`): `true`,
  `'true'` and `True` all parse to `"true"` and are auditor-only, and a
  non-constant `${{ … }}` expression is pedantic-only. Executed: NC4a, NC4c,
  NC4d and NC4f all exit 0 at the default persona (`r08-zizmor.log:21-25`),
  and each shows `artipacked` only at the escalated persona (`:35-40`).

The script's rule 2 therefore flags every explicit value other than
`false` that has no non-empty trailing comment (executed: NC4a, NC4c, NC4d,
NC4f exit 1 with file:line findings; NC4b, NC4e and the quoted-`false`
control NC4g exit 0; `r08-policy.log:18-25`), and rejects the key inside a
flow-style map, where a line check cannot read the value (NC4h exit 1,
`:26`, finding text `:47`). Rule 1 accepts only the literal
`permissions: {}` at column 0, so a flow-style top-level map is rejected,
not evaded (NC2b exit 1, `:20`). `actionlint` 1.7.12 exits 0 on every
negative case (`r08-policy.log:59-68`): syntax linting is not policy
enforcement. Each rule has exactly one owning check. The comment's
content is left to review: rule 2 checks only that a comment is present
(B4).

**The scope sets R08 supplies (R11 places them).** Each value below is
read from a pinned precedent or, where the precedent's reason no longer
applies, derived from the pinned action source:

| Workflow / job | Scopes | Precedent |
|---|---|---|
| `ci.yml`, every job | `contents: read` | ts `ci.yml` job grant (`r08-sources.log:153-163`); R11 `plan` body (checkout + diff) needs read only |
| `release-please.yml` job | none (no job `permissions:` block; the top-level `{}` applies) | Derived, not copied. Both repos grant `contents`/`pull-requests: write` (py `:32-34`, ts `:51-55`, `r08-sources.log:164-181`), but both pass `token: ${{ steps.app-token.outputs.token \|\| secrets.RELEASE_PLEASE_APP_TOKEN }}` (`:420-421`), the F072 App-or-PAT shape. The action's `github.token` default (`:414-417`) is "used when an input parameter isn't specified" (`metadata-syntax.md:84`, `:443-446`); `token:` is always specified, and the action reads it with `required: true` (`src/index.ts:52`, `:418`), and an empty value then throws "Input required and not supplied" (`core.ts:154-155`, `:447-453`). ts states the intent: "GITHUB_TOKEN is intentionally NOT a fallback" (`:454-459`). No step uses the job token, so it holds no scope |
| `publish.yml` verify | `contents: read`, `fetch-depth: 0`, no re-fetch | ts `:42-52` + no-refetch comment `:74-79` (`r08-sources.log:182-195`) |
| `publish.yml` publish | `contents: read`, `id-token: write` (OIDC trusted publishing, the only auth) | ts `:151-155` (`r08-sources.log:196-204`) |
| `update-contributors.yml` job | `contents: read` only (checkout), with a comment saying why there is no write | Derived, not copied. The action reads credentials only from `app-id`, `private-key` and `pat` (`src/index.ts:394-396`), builds its API client and push remote from that token (`:131`, `:164`), and references neither `github.token` nor `GITHUB_TOKEN` in `action.yml` or `src/index.ts` (count 0 and 0) — `r08-sources.log:386-408`. R21 puts the three writes on the fine-grained PAT (Contents, Pull requests, Issues: write; R21 DECISION:23, `r08-sources.log:412`) or on the App installation. The precedent writes (py `:11-14`, ts `:61-64`) existed because ts passes `pat: ${{ secrets.GITHUB_TOKEN }}` (`r08-sources.log:126`); R21 rejected that input |
| `difftree-pr-comment.yml`, if adopted verbatim | keeps upstream `contents: read` + `pull-requests: write` at top level; named in the script's exception list | vendor-canonical 3771-byte file, R20's per-file exemption |

**Minimal realistic example.** The bot workflow is the F030 case. Its
trigger is R07's accepted block (push to `main` with `paths-ignore` on the
two generated files, plus `workflow_dispatch`, no `schedule`), its
credential inputs are R21's (App credentials, then `CONTRIBUTORS_PLEASE_PAT`,
never `GITHUB_TOKEN`), its pins are R20's; R08 decides only the
`permissions:` blocks and the `persist-credentials` line. Full file at
`review/evidence/fixtures/contributors.good.yml`:

```yaml
permissions: {}
jobs:
  update-contributors:
    runs-on: ubuntu-latest
    permissions:
      # Checkout only. The action commits, pushes, opens and labels the pull
      # request with its own App installation or PAT token (R21), never with
      # GITHUB_TOKEN, so the job token needs no write scope.
      contents: read
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
          # The action sets its own authenticated origin URL from its App or
          # PAT token before pushing, so the checkout token is not needed.
          persist-credentials: false
      - uses: smorinlabs/contributors-please-action@3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1 # v1.3.9
```

The four-file P0 tree, with the revised bot and release files, plus R20's
`zizmor.yml` exits 0 under zizmor 1.30.1 offline and online, 0 under the
candidate script, and 0 under `actionlint` (`r08-zizmor.log:17,53`,
`r08-policy.log:14,60-63`). The release fixture models only the
release-please step; F072's App-token mint step is F072's and is not
modelled, and the source-shaped mint step raises a separate zizmor finding
forwarded under Gaps (obs. 19).

**Observable acceptance criteria, each labelled by what was run.**

| # | Criterion | Status |
|---|---|---|
| 1 | Candidate script exits 0 on the conforming four-workflow tree, the bot job at `contents: read` and the release job with no re-grant | Executed — `r08-policy.log:14` |
| 2 | Candidate script exits 1 on top-level grants (single-job, grown, and flow-style), and names the file (text shown for the single-job and grown cases) | Executed — `r08-policy.log:16-17,20,34-37` |
| 3 | Candidate script exits 1 naming the line on an uncommented non-`false` value in every executed spelling (`true`, `'true'`, `True`, non-constant expression) and on a flow-style `with:` map; exits 0 on commented `true`/`True` and on quoted `false` | Executed — `r08-policy.log:18-26,38-47` |
| 4 | zizmor 1.30.1 default persona exits 12 with `artipacked` on an unset checkout, 0 on the P0 tree | Executed — `r08-zizmor.log` §2–§3 |
| 5 | zizmor default persona is silent on explicit true in every executed spelling (auditor-only) and on a non-constant expression (pedantic-only), silent on single-job top-level grants (pedantic-only), loud on multi-job grants. An auditor-persona exit 12 alone does not identify `artipacked`, because other auditor-only audits fire on clean files, so each escalation is asserted by finding name | Executed — `r08-zizmor.log:19-25,33-43` |
| 6 | zizmor SARIF mode exits 0 and `--min-severity=medium` silences the Low finding, so the gate is non-SARIF with no `min-severity` above `low` | Executed — `r08-zizmor.log` §5 |
| 7 | `actionlint` exits 0 on every negative case: it cannot substitute for either gate | Executed — `r08-policy.log:59-68` |
| 8 | Verbatim difftree file passes rule 1 by exact-name exemption; the same bytes under another name fail | Executed — `r08-policy.log:27-28` |
| 9 | `hygiene` fails on a pull request that adds a workflow without `permissions: {}`, on `ubuntu-latest` | Proposed for P03 (this run's host is macOS; the `hygiene` job is R11's) |
| 10 | The real bot workflow opens its pull request with the job-level grant and `persist-credentials: false` | Proposed for P03 (needs a live fork run) |
| 11 | The publish verify job runs green on a private fork (no post-checkout fetch) | Proposed for P03 |
| 12 | The bot run commits, pushes, opens and labels its pull request with the job token at `contents: read` alone, once under App credentials and once under the PAT fallback | Proposed for P03 (needs a live fork run and both credential kinds) |
| 13 | The release-please job opens its release pull request and creates the release and tag with no job-token scope, once under F072's App token and once under the PAT fallback; with neither configured it fails fast rather than falling back to `GITHUB_TOKEN` | Proposed for P03 (live confirmation of Uncertainty 5) |

**Fitness gates, answered before popularity is weighed.** This item selects
no crate; gates are answered for the YAML pattern, and for zizmor as the
CI tool that enforces it.

1. **License.** The pattern is YAML text and carries no license.
   Inapplicable as a dependency evaluation. The one named tool, zizmor, is
   MIT (`r08-sources.log:229-230`), compatible with `MIT OR Apache-2.0`,
   and is not linked into the template.
2. **MSRV.** Inapplicable to the pattern: nothing enters `Cargo.toml`.
   zizmor is acquired as a prebuilt release binary per R20's accepted
   ruling (R20 DECISION part 3.1), never built on the MSRV toolchain; it
   enters neither the manifest nor the MSRV job.
3. **Advisories and `unsafe`.** No advisory applies to a checkout input or a
   `permissions` map: 0 advisories for `actions/checkout`, 0 for rust
   `zizmor`, against a control query returning 2 for
   `tj-actions/changed-files`, and no RustSec entry for zizmor (HTTP 404),
   all `r08-sources.log:237-244`. `unsafe` is inapplicable.
4. **Both runners.** The YAML policy is runner-independent. zizmor 1.30.1
   ships prebuilt archives for both target OSes (R20 DECISION:323-325,
   carried, not re-derived); the gate step itself runs once on
   `ubuntu-latest` in `hygiene`. This run executed on macOS only.
5. **Default features and async-runtime coupling.** Inapplicable: a
   standalone binary plus a bash/`grep` script.
6. **Binary size and compile-time cost.** None to the artifact. CI cost is
   one binary download (already paid by R20) plus one `grep` step; it was
   not timed, and nothing here runs on a hot path.

**Migration implications (file-level).** Every `.github/workflows/*.yml`:
top-level `permissions: {}` plus a minimal per-job re-grant. Every
`actions/checkout` step: add `with: persist-credentials: false`.
`update-contributors.yml`: top-level `{}`, a job re-grant of `contents:
read` with the no-write comment, and the flag with the own-remote comment.
`release-please.yml`: top-level `{}` and no job re-grant, with a comment
saying the release token is F072's.
`hygiene` job (`ci.yml`, R11's file): add the `bash
scripts/check-workflow-permissions.sh` step; zizmor needs no new step, only
the standing R20 invocation with the constraints of criterion 6. New file
`scripts/check-workflow-permissions.sh` (candidate at
`review/evidence/check-workflow-permissions.candidate.sh`, sha256
`6176af76…9f1357b`, `r08-policy.log:7`). Follow-on, not in this template,
counted from this run's census and policy run: py needs 31 checkout edits
and 6 top-level rewrites (`r08-policy.log:49-54`), its bot job holds
`contents: read` only (its `pat:` is already R21's secret), and its
release job drops both writes; ts needs 1 checkout edit, 1 top-level
rewrite (`dependency-review.yml`, `r08-policy.log:56`) and 3 doc
corrections
(`docs/tools/github-actions.md:55`, `:75`, `:76`,
`r08-sources.log:147-152`), its release job drops both writes, and its bot
job drops to `contents: read` once it adopts R21's `pat:` input. Until then
ts's bot writes are used, because its `pat:` is the job token. In both
repos the verbatim `difftree-pr-comment.yml` stays exempt and keeps its
upstream top-level grant, as it does in rs (D3); it is not rewritten.

re-verify: 2027-03-27, or earlier on any of — `actions/checkout` changing
the `persist-credentials` default, storage location or input parsing;
zizmor changing the persona or severity of `artipacked` or
`excessive-permissions`, or how `artipacked` matches the input value; R20
changing its `zizmor` invocation or `zizmor.yml`; R11 moving the `hygiene`
placement; any template workflow adding a `git push` or post-checkout
fetch; the contributors action no longer setting its own remote URL, or
reading `GITHUB_TOKEN`; R21 changing the bot credential; F072 or
release-please-action changing the release token path, or GitHub changing
when an input's default applies (criterion 13);
GitHub changing `permissions` block semantics; the template adopting or
dropping the verbatim difftree file; or the controller acting on the
carried F028 line above.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

R08 owns no registered parameter (`## Couplings`, `owns:` empty) and
consumes none, so no row is added to `docs/port/PARAMETERS.md` and no
`CONFLICT:` line is raised. It supplies the `permissions:` scope values
that R11's owned `ci-job-structure` places (R11 DECISION:100, repeated in
the owned value at :320: the per-job re-grant "whose scopes are R08's").

How the fixed parameters bear on the decision. `msrv-policy` constrains
only the acquisition channel of the zizmor enforcer (prebuilt binary, per
R20 — see fitness gate 2), never the policy text.
`target-os-matrix` is satisfied trivially for the YAML and, for zizmor,
through R20's accepted prebuilt-binary line. `license` is satisfied
(zizmor is MIT, unlinked). `rust-edition` has no bearing on a workflow
file.

## Empirical check

Toolchain and environment, captured at the head of the logs: `rustc
1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc
2026-08-05) (Homebrew)`, macOS 26.4 arm64 (`Darwin 25.4.0`), `actionlint`
1.7.12, `zizmor` 1.30.1 (the binary revision 1 installed under
`/tmp/cargo-s10`, invoked by absolute path; nothing was installed in this
revision, whose private `CARGO_HOME` is `/tmp/cargo-s25-R08-r3`), GNU bash
5.3.20, Python 3.14.7, `gh` authenticated as `smorin`.

Working directory: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.
Sources read at their programme pins — py at
`b08bccfb55d05f15e46a83b52c5660b1881d19f5`, ts at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` — via local clones whose HEADs
(`b55b8c2`, `e5100b4`) are descendants of the pins; every claim below
states which commit it comes from. Authority sources read at pinned
commits: zizmor `99a054ed` (= tag `v1.30.1`, the executed binary),
`github/docs` `18945a31`, `actions/checkout` `3d3c42e5` (= tag `v7`),
`contributors-please-action` `3c6dbff9` (= tag `v1.3.9`),
`release-please-action` `45996ed1` (= tag `v5.0.0`).

Commands, run in this order. `r08-refreeze.sh` writes only this run's
`inputs/` and `manifest.json` (see the revision 3 note). Its committed log
is the single run that wrote. It is idempotent, and that path was executed
after all the runs below. A second run printed "already re-frozen ... no
write", then `R-fresh` PASS, and exited 0. `manifest.json` kept sha256
`be4b7ccc…81eb27`, and all six `inputs/` files kept their hashes. That
run's log stayed in `/tmp` so the committed log remains the record of the
write. Every other
script writes nothing outside `review/evidence/` and `/tmp` scratch.

```sh
E=research/runs/R08/2026-09-26T190123Z-08fb558146f7/review/evidence
bash $E/r08-refreeze.sh > $E/r08-refreeze.log 2>&1
bash $E/r08-inputs.sh  > $E/r08-inputs.log  2>&1
bash $E/r08-policy.sh  > $E/r08-policy.log  2>&1
bash $E/r08-zizmor.sh  > $E/r08-zizmor.log  2>&1
bash $E/r08-sources.sh > $E/r08-sources.log 2>&1
```

Exit statuses. Run 2026-09-27T06:20–06:22Z by revision 3 and carried:
`r08-refreeze.sh` exit 0 (`R-fresh` PASS, `r08-refreeze.log:23`);
`r08-zizmor.sh` exit 0 (32 PASS, 0 FAIL); `r08-sources.sh` exit 0
(460-line log). Rerun 2026-09-27T18:15–18:20Z by revision 4: `r08-inputs.sh`
exit 0 (24 PASS, 0 FAIL, `r08-inputs.log:92`); `r08-policy.sh` exit 0 (28
PASS, 0 FAIL). All six scripts, the candidate included, are `shellcheck -S
warning` clean (shellcheck 0.11.0) and pass `bash -n`. `SHA256SUMS` holds
32 entries: the six scripts, five logs, the two `r2-frozen/` files, the
preserved `r3-logs/r08-inputs.log` and eighteen fixtures. The policy,
zizmor and sources scripts and every fixture keep their revision 2
digests. The candidate changed only in comment lines (revision 4, F2), and
`r08-inputs.sh` changed in two checks (revision 4, F1).

Observed, all retrieved or executed 2026-09-27:

1. **py census (19 files):** 12 top-level deny-all, 5 top-level grants, 2
   absent (`claude-code-review.yml`, `claude.yml`); 1 of 32 checkouts sets
   `persist-credentials: false` (the verbatim difftree file),
   `r08-sources.log:13-66`.
2. **ts census (8 files):** 6 deny-all, 2 grants (`dependency-review.yml`,
   `difftree-pr-comment.yml`); 8 of 9 checkouts set `false`, the unset one
   the bot workflow's (`update-contributors.yml:67`),
   `r08-sources.log:67-86`.
3. **Difftree byte identity:** py and ts copies are each 3771 bytes and
   `diff`-identical, carrying "copy it verbatim" (`:10`) and a top-level
   `contents: read` + `pull-requests: write` grant (`:21-23`),
   `r08-sources.log:128-146`.
4. **ts's documentation contradictions:** its docs claim six workflows
   "follow the same shape (deny-all baseline ...)" while
   `dependency-review.yml` carries a top-level grant, and "Every checkout
   step sets `persist-credentials: false`" while the bot checkout omits it;
   its `:75` justifies the bot writes as "they open/update PRs", which holds
   only while `pat:` is the job token, `r08-sources.log:147-152` against §2.
5. **Scope precedents:** release-please `contents:write` +
   `pull-requests:write` in both repos; publish verify `contents:read`
   with `fetch-depth: 0` and the no-refetch comment; publish
   `contents:read` + `id-token:write` with the Trusted-Publishing-only
   comment, `r08-sources.log:164-204`.
6. **zizmor standing:** 6,580 stars, not archived, pushed 2026-09-27
   (`2026-09-27T05:17:46Z`), MIT; 137 open issues; 47,504 / 247,294
   downloads (90-day / all-time); latest non-yanked `1.30.1` (2026-09-09),
   `r08-sources.log:229-236`. Every figure reproduced unchanged from
   revisions 1 and 2 except `pushed_at`, which was `2026-09-26T00:26:56Z`
   in revision 2's log. A newer push to the repository is activity. It
   changes no pin: `v1.30.1` still resolves to `99a054ed` (observation 8).
7. **Advisories:** 0 for `actions/checkout`, 0 for rust `zizmor`, control
   2 for `tj-actions/changed-files`; RustSec has no zizmor page (404),
   `r08-sources.log:237-244`.
8. **Pin resolutions:** zizmor `v1.30.1` → `99a054ed`; checkout `v7` →
   `3d3c42e5`; contributors-please `v1.3.9` → `3c6dbff9` (matches R20/R21);
   release-please `v5.0.0` → `45996ed1`; `github/docs` main →
   `18945a31`, `r08-sources.log:245-250`.
9. **Vendor semantics:** `permissions: {}` disables all scopes
   (available-permissions `:39`); workflow-level applies to all jobs and
   per-job configuration adjusts after it (workflow-syntax `:348-354`);
   secure-use mandates minimum privilege with per-job increase and names
   Scorecard (`:34`, `:224`), `r08-sources.log:252-270`.
10. **Checkout mechanics:** token persisted by default with documented
    opt-out (`:33`); v6+ stores under `$RUNNER_TEMP` (`:16`),
    `r08-sources.log:271-274`.
11. **zizmor rules as code (v1.30.1):** v6+ without vulnerable uploads →
    `Low` (`artipacked.rs:76-92`); explicit `true` → auditor persona,
    unset → default persona (`:133-141`); single-job top-level grants →
    pedantic (`excessive_permissions.rs:79-89`),
    `r08-sources.log:275-314`.
12. **zizmor rules as docs:** "made explicit with
    `persist-credentials: true`" (audits `:222-227`); "almost always set
    `permissions: {}` ... then job-level as needed" (`:700-703`); jobs
    inherit broad top-level grants (`:678-682`); exit 0/12/14 and SARIF
    suppression (usage `:563-579`, `:595-598`),
    `r08-sources.log:315-354`.
13. **Contributors action autonomy:** pushes via `git remote set-url`
    with an `x-access-token` URL from its own token
    (`src/index.ts:588-616`), so the checkout credential is unnecessary,
    `r08-sources.log:355-384`.
14. **Policy matrix:** 19 candidate-script expectations (P0; NC1–NC3 and
    NC2b; NC4a–NC4h; verbatim exemption + rename control; both pinned
    trees; two usage errors) plus 9 `actionlint` insufficiency runs — 28
    PASS, `r08-policy.log:13-69`.
15. **zizmor matrix:** P0 exit 0 offline and online; NC1 exit 12
    `artipacked`; NC2 silent at default, exit 14 at pedantic; NC3 exit 14
    `excessive-permissions`; NC4a/NC4b/NC4c/NC4d/NC4f silent at default;
    NC4a/NC4c/NC4d show `artipacked` at auditor and NC4f at pedantic;
    NC4g clean at default, and its auditor exit 12 comes from
    `concurrency-limits` with no `artipacked`; the source-shaped F072 mint
    step exits 14 with `github-app` (§4b, obs. 19); SARIF exit 0;
    `min-severity=medium` silences, `=low` keeps — 32 PASS,
    `r08-zizmor.log` §2–§6.
16. **Credential sources (revision 2):** the contributors action's only
    credential inputs are `app-id`, `private-key` and `pat`, each defaulting
    to `''` (`action.yml:7-19`); `src/index.ts:394-396` reads them, `:131`
    and `:164` use the resulting token; neither file references
    `github.token` or `GITHUB_TOKEN`. R21 DECISION (sha256 `66d566a5…`)
    `:15` adopts App-then-`CONTRIBUTORS_PLEASE_PAT` and `:23` scopes the PAT
    to Contents, Pull requests and Issues write. release-please-action's
    `token` input defaults to `${{ github.token }}` and is read with
    `required: true`; py `:55` and ts `:79` pass
    `steps.app-token.outputs.token || secrets.RELEASE_PLEASE_APP_TOKEN`,
    `r08-sources.log:385-421`.
17. **Flag parsing (revision 2):** checkout sets `persistCredentials` from
    `(getInput('persist-credentials') || 'false').toUpperCase() === 'TRUE'`
    (`input-helper.ts:166-168`); zizmor's full match is `"false"` →
    skip, `"true"` → auditor, `${{ … }}` → pedantic, anything else →
    default (`artipacked.rs:127-142`), `r08-sources.log:422-442`.
18. **Inputs (revision 3 re-freeze, checked by revision 4):** all six frozen inputs
    hash to `manifest.json`'s recorded values, and the manifest requires
    `muse, opus`, as the live policy does (`r08-inputs.log:6-14`). The
    frozen prompt is byte-identical to the canonical prompt (`:17-19`).
    The migration event records revision 2's engines and hashes, and only
    `prompt`, `policy` and `policy_item` changed (`:21-29`). The re-freeze
    changed the prompt only at line 22 (`codex, opus` → `muse, opus`) and
    by the line-69 substitution sentence (`:31-40`). It changed the policy
    for R08 only in `engines` and the new `engine_overrides.R08`
    (`:42-47`). The frozen and live policies agree on every R08 key, and
    R08 has no `empirical_auditor_overrides` entry in either, so its
    empirical seat is the codex default (`:48-53`). The two files are not
    byte-identical: the live one has 37 override keys against 6 frozen,
    all for other items (`:48-50`; revision 4, F1). `inputs/PARAMETERS.md`
    matches its live file, and `inputs/CLAUDE.md` matches the live index on
    R08's row (`:63-67`). R11's decision and acceptance match
    `inputs/prerequisites.json` (`:69-71`). The runner's
    `freshness_errors` returns no error (`:73-74`).
19. **When an input default applies (revision 2):** `github/docs`
    metadata-syntax: "The default value is used when an input parameter
    isn't specified in a workflow file" (`:84`); `actions/toolkit`
    `a7911ca4` `core.getInput` returns `''` for an unset or empty input and,
    with `required`, throws "Input required and not supplied"
    (`core.ts:151-156`); ts's release workflow states "GITHUB_TOKEN is
    intentionally NOT a fallback — with neither configured, fail fast"
    (`:61-65`), `r08-sources.log:443-459`. Cross-item: the mint step as
    py (`:42-48`) and ts (`:66-72`) write it, with no `permission-*` input,
    exits 14 under zizmor 1.30.1's default persona with `github-app` ("app
    token inherits blanket installation permissions"),
    `r08-zizmor.log:44-47`.

## Engines

**Reports.** Two legs, both read in full: `raw/muse.md` (the `muse` seat's
leg under Q17.A, 262 lines, sha256 `e5fa3cb6…70722964`; figures retrieved
2026-09-26, probe executed on macOS with `actionlint` 1.7.x and
Python/PyYAML) and `raw/opus.md` (the `opus` seat's leg, 947 lines, sha256
`7c752538…d78adb`, `claude-opus-5-5`, retrieval window
2026-09-26T19:52–20:40Z, executed checks on macOS with `actionlint`
1.7.12). Both hashes and line counts: `r08-inputs.log:77,84`. Both legs agree on the direction: broad `false`
default, uniform deny-all including the bot, and a zizmor-plus-local-check
gate in R11's `hygiene` job. Neither leg executed zizmor; both left that
half proposed. This synthesis executed it (observation 15). **Engine
authority:** Q17.A (2026-09-27, `research/RUNBOOK.md:73-76`) authorizes the
Muse leg in the seat the pre-Q17.A inputs named `codex`. The live
`research/EXECUTION.json` has `engine_overrides.R08 = ["muse","opus"]`.
Since revision 3's re-freeze, the run's frozen policy and `manifest.json`
`required_engines` say the same (`r08-inputs.log:13-14,44-45,56-61`).

**Evidence checks.** Five scripts. Revision 3 ran all five under a
private cargo home; revision 4 reran `r08-inputs.sh` (24 PASS, 0 FAIL, two
checks scoped to R08) and `r08-policy.sh` (28 PASS) and carries the other
three: `r08-refreeze.sh` (exit 0, `R-fresh` PASS), `r08-zizmor.sh` (32
PASS) and `r08-sources.sh` (exit 0, 460 lines). Total across the two self-asserting
policy scripts: 60 asserted expectations, 0 failures (revision 1: 38).
The two input scripts add 25 more, also with 0 failures.

**Disagreements, each adjudicated with evidence — none silently
picked.**

| # | Disagreement | Verdict and evidence |
|---|---|---|
| D1 | Push-job exception form: muse's omit-the-flag-with-comment (`raw/muse.md:42`) vs opus's explicit-`true`-with-comment (`raw/opus.md:155-159`, B3) | **Opus.** zizmor's remediation says an unneeded credential "should be made explicit with `persist-credentials: true`" (obs. 12), and the code reports unset at the default persona but explicit `true` only at auditor (obs. 11). Executed: NC1 (unset) exits 12, NC4b (commented `true`) exits 0 (obs. 15). Muse's form fails muse's own recommended gate. |
| D2 | Enforcement split: muse overlaps (local check covers the checkout flag and per-job presence too, `raw/muse.md:44,156`) vs opus disjoint — script covers `{}` + comment, zizmor covers unset (`raw/opus.md:415-418`) | **Opus's split.** The gap that motivated overlap — an unexecuted zizmor — is now closed (obs. 15, 32 PASS). A scopeless job needs no `permissions` block, so per-job presence is not a rule; a missing grant fails loudly at runtime (403). Matches R20's accepted disjoint-checks shape. Revision 2 confirms that zizmor cannot take over the comment rule at the default persona (obs. 15, 17). |
| D3 | Verbatim difftree file: opus prefers (a) wrap in `{}` and record the deviation (`raw/opus.md:850-856`) over (b) a named exception | **(b), overruling opus.** R20's accepted decision exempts this exact file per-file to protect F062 byte identity (3771 bytes, diff-identical, obs. 3). Wrapping edits the file and destroys the value R20's exemption exists to protect. The script's exact-name exemption executes correctly on the real bytes (obs. 14: verbatim passes, renamed fails). |
| D4 | Script language: muse's Python/PyYAML (`raw/muse.md:186`) vs opus's bash/`grep` (`raw/opus.md:375-397`) | **Opus (bash).** R11's detector body is bash and R20's comment check is specified as shell; muse's own report flags PyYAML-on-runners as unasserted (`raw/muse.md:171,192`). The executed candidate is bash + `grep` only. Revision 2's widening of rule 2 stays within line-based `grep` and names its one structural limit (flow maps), which it rejects outright. |
| D5 | F028 conformance: muse raises no finding (`raw/muse.md:36`) vs opus's `BASELINE-REVIEW: F028` (`raw/opus.md:243-255`) | **Opus, carried.** This synthesis re-ran the census: py 12/19, ts 6/8 (obs. 1–2). The line is forwarded under `## Decision` with this run's evidence; the controller adjudicates. |
| D6 | Opus's example bot workflow uses a `schedule` trigger and `pat: GITHUB_TOKEN` (`raw/opus.md:341-369`) | **Both stale; corrected.** R07's accepted block is push + `workflow_dispatch`, no `schedule` (R07 DECISION:195-204, owner ruling W0-R07b); R21's accepted fallback is `CONTRIBUTORS_PLEASE_PAT`, explicitly rejecting `GITHUB_TOKEN` (R21 DECISION:15). The example above uses the accepted values. **Revision 2:** correcting the credential also changes the scope set. With `GITHUB_TOKEN` no longer the action's credential, the job token's three writes serve no step, so the re-grant becomes `contents: read` (see D10). |
| D7 | Opus cites an "unspecified scopes are set to `none`" sentence to `section-assigning-permissions-to-jobs-specific.md` (`raw/opus.md:48-57`) | **Citation does not resolve; conclusion re-grounded.** The exact file at the exact commit holds two different paragraphs (verified by fetch). The operative semantics rest instead on workflow-syntax `:348-354` (per-job configuration adjusts after workflow-level), the `{}` disable-all quote (obs. 9), and zizmor's inheritance model (obs. 12). |
| D8 | Per-scope reason comments: opus recommends them (`raw/opus.md:371-373`, `432-433`); muse is silent | **Adopted as unenforced convention.** Zero cost, satisfies the pedantic-only `undocumented-permissions` audit if sensitivity ever rises, and the P0 fixtures carrying them exit 0 (obs. 14–15). The bot job now carries a comment explaining the absence of writes rather than per-write comments. |
| D9 | Practice survey: muse ran none (admitted gap, `raw/muse.md:28,250`) vs opus's eight-repo survey (`raw/opus.md:85-121`) | **Opus's figures carried, not re-run.** The 235/237 tooled-group count and the `{}`-vs-`contents: read` split are leg evidence; no load-bearing claim here depends on them. Load-bearing claims rest on observations 1–19. See Uncertainty. |
| D10 | Bot job scope set (revision 2): both legs re-grant `contents`/`pull-requests`/`issues: write` at job level (`raw/muse.md:40,109`; `raw/opus.md:351-355`) | **Both overruled.** Both legs copied the precedent's set as "zero privilege change". The precedent's writes serve ts's `pat: ${{ secrets.GITHUB_TOKEN }}`, which R21 rejected. Under R21's credential the action authenticates only with its App or PAT token and never reads `GITHUB_TOKEN` (obs. 16), so least privilege (obs. 9) leaves `contents: read` for checkout. The P0 tree with the reduced grant passes both gates (criterion 1, obs. 15); the live run is criterion 12. |
| D11 | Release job scope set (revision 2): opus re-grants `contents`/`pull-requests: write` (`raw/opus.md:633-634`, `:845-846`); muse states no release scope | **Opus overruled.** Opus copied the precedent's pair. Both precedents pass the release-please action an always-specified App-or-PAT `token:`. Under that shape the action's `github.token` default never applies, and an empty value fails fast (obs. 16, 19), so no step uses the job token. The P0 tree with no release re-grant passes all three tools (criterion 1, `r08-zizmor.log:17`, `r08-policy.log:62`); the live run is criterion 13. |

**Uncertainty, stated.** (1) The eight-repo survey figures are carried
from the opus leg and were not independently re-run; they inform
direction only. (2) Nothing ran on a GitHub-hosted runner or on Linux;
criteria 9–13 are P03's. (3) Whether a persisted checkout credential would
take precedence over the contributors action's own URL credential
(extraheader question, `raw/opus.md:288-294`) is unverified; it is a P03
live check, not an asserted reason. (4) The `clap` push-precedent for B3
is carried from the opus leg, not re-fetched; B3's standing does not
depend on it (zizmor's remediation + executed NC4b do the work). (5)
**release-please token path.** The release job's empty grant rests on
vendor documentation and toolkit source (obs. 19), not on a run: this
synthesis did not dispatch a workflow to watch the runner leave an
explicitly-specified empty `token:` without the `github.token` default.
If the runner behaved otherwise, the failure would be loud (a 403 when
the release pull request is opened), not a silent widening. Criterion 13
is the live check. (6) The
bot's reduced grant is derived from pinned action source, not from a live
run; criterion 12 converts it to observed fact.

**What P03 must validate** (beyond criteria 9–13): the `hygiene` step
wiring in R11's file; the standing R20 invocation kept non-SARIF with no
`min-severity` above `low`; the extraheader-precedence question on a
live fork; and the follow-on py/ts alignment counts (py: 31 checkouts, 6
top-levels, bot job to `contents: read`, release job to no grant; ts: 1
checkout, 1 top-level, 3 doc lines, release job to no grant, bot job to
`contents: read` after adopting R21's `pat:`; the verbatim difftree file
stays exempt in both, D3).

**Gaps recorded for the controller.** (a) **Closed by revision 3, with one
residue.** Revision 2 recorded that `inputs/` and `manifest.json` still
carried the pre-Q17.A engines. Revision 3 re-froze both, and
`r08-inputs.sh` is green (revision 3 note). Since then the live policy
and index have changed for other items. Revision 4 therefore checks the
frozen inputs against the live files on R08's entries only; the frozen
files were not rewritten (revision 4, F1). If the controller wants
whole-file identity again, `run migrate-engines` or a new preparation
re-freezes them. The residue is how the revision 3 re-freeze was done.
`manifest.json` was hand-edited by `r08-refreeze.sh` under the ruling's
"update the I1 hash" clause; `run migrate-engines` was not used. The
runner's own `freshness_errors` accepts the result (`r08-refreeze.log:23`).
The migration event's actor is this synthesizer, not a controller, and its
`reason` says the edit was hand-applied. If the controller wants a
runner-authored event, it can restore revision 2's inputs from
`review/evidence/r2-frozen/` and the event's `previous_input_hashes`, then
run the command. (b) Cross-item, not
R08's to decide: the F072 App-token mint step as both sources write it has
no `permission-*` input, and zizmor 1.30.1's default persona fails it with
a High `github-app` finding (obs. 19, `r08-zizmor.log:44-47`). A template
that inherits F072 verbatim would therefore fail R20's standing `zizmor
.github/` gate. The owners are F072 (`COMMON → REUSE`, inherited), R20 (the
gate) and R09 (F058, the same step's `actionlint` metadata). A likely
repair is `permission-contents: write` and `permission-pull-requests:
write` on the mint step, but this run did not execute it.
