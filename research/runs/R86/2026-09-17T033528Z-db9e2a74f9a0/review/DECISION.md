# 2026-09-17 — R86 — codex-assisted-review-workflows (bundle, Deep) — decision (revision 1)

## Decision

**Status.** This decision is a **proposal validated in the implementation phase**
(owner ruling, 2026-09-10). It records what the research found and what it
recommends; **P03 builds the template and its CI proves the recommendation.**
`rs-launch-blueprint` has no `.github/workflows/` tree, no Rust source and no
configured credential today, so nothing here is an implemented result. The two
workflow files this decision describes exist only as **fixtures under
`review/evidence/`**, written so `actionlint` could decide whether the guard set
and the credential relay are expressible and type-correct; they are input to a
check, not template code. `## Engines` lists what P03 must validate. A decision
that does not survive implementation is revised against this recorded research,
not researched again from scratch.

**Fitness gate 1 (licence) is recorded for every candidate named below as
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not
evaluated for any dependency or tool`.** Nothing here is excluded on licence.
Licence strings appear only as metadata: the action's own source tree is
`Apache-2.0` (check `V04`), and so are both npm packages it installs (`P07`).

**Recommendation in one sentence.** Ship **both** Codex workflow files, as one
bundle, with the template, by default, with no enable variable — built on the
**first-party** action `openai/codex-action` at **`v1.12`** (annotated tag object
`cac08775a978ba35a8174558cd9fabab2c09670c` → commit
`86365089eb2b84e0a8fb0717b304f8bdcb13b20e`, tagged 2026-08-20T23:40:26Z), with
the Codex CLI pinned explicitly to `@openai/codex@0.154.0`, each lane gated on
the presence of the repository **secret** `OPENAI_API_KEY` through an always-run
`credential-preflight` job whose output a **positive** `needs` predicate
consumes, each lane split into three jobs so that the job holding the model
credential holds no write permission and the job holding `pull-requests: write`
holds no model credential, and each lane rejecting bots by **actor type** and
gating the assistant on an `author_association` prefilter.

| Component | Version / coordinate evaluated | Role | Evidence |
|---|---|---|---|
| `openai/codex-action` | **`v1.12`** → commit `86365089eb2b84e0a8fb0717b304f8bdcb13b20e` | the invocation mechanism for both lanes | `V01`–`V15` |
| `@openai/codex` | **`0.154.0`**, pinned through the action's `codex-version` input | the agent the action installs and runs | `P01`, `P03`, `P04` |
| `@openai/codex-responses-api-proxy` | **`0.154.0`** — pinned by the *same* input, not separately | the credential proxy the action starts | `P02`, `P05`, `P06` |
| `permission-profile` | **`":read-only"`** on both lanes | no filesystem write and no network for the agent | `FR05`, `FA05` |
| `safety-strategy` | **`drop-sudo`** (the action's default, kept) | `sudo` revoked before the agent starts, and the revocation verified | `FR06`, `FA06` |
| Prompt source | template-local `.github/codex/review-pr.md` and `.github/codex/assist.md`, passed as `prompt-file:` | the lane's instructions are versioned with the template | mirrors R18's revision-4 clause; see `### Principles and implementation` |
| `actions/checkout` | `v5` — the version the vendor's own example uses | checks out the **trusted** base or default branch, never the pull request's tree | `FR21` |
| Credential | repository **secret** `OPENAI_API_KEY` | the single credential path the mechanism supports | `C01`–`C05` |
| Credential gate | always-run `credential-preflight` publishing `credential` ∈ {`present`, `none`}, consumed by `== 'present'` | satisfies owner behaviours 2 and 3 | `G01`–`G04`, `L01`–`L05` |
| Comment posting | a third job holding `pull-requests: write` and **no** model credential, running `gh pr comment` | forced by the mechanism, and the containment the vendor itself recommends | `S05`, `S06`, `D05` |

**The pin *format* — floating major tag, full commit SHA plus comment, or
otherwise — is R20's, not this item's.** This decision names the action and the
version it evaluated and records one thing R20 will need: **no reference in
either lane is structurally unpinnable.** The one mutable reference the
mechanism has is the run-time `npm install` of the Codex CLI, and it is pinnable
through the `codex-version` input, which this recommendation pins. That is the
opposite of what R18 found on the Claude side, where the review lane's
plugin-marketplace URL was structurally unpinnable and had to be removed.

**One resolution detail that would produce a wrong pin if taken at face value,
and neither raw report caught it.** `GET /repos/openai/codex-action/git/ref/tags/v1.12`
returns `object.sha` = `cac08775a978ba35a8174558cd9fabab2c09670c`. That is the
**annotated tag object**, not the commit. A `uses:` pin written from that field
would name an object GitHub Actions does not resolve. The commit is
`86365089eb2b84e0a8fb0717b304f8bdcb13b20e`, reached either by dereferencing the
tag object (`V10`) or by reading `/tags`, which reports `commit.sha` directly
(`V08`). The moving `v1` tag is a *different* tag object
(`f367b1e9572fd064ea71ef925ca24ee0f01080af`) that dereferences to the **same**
commit at retrieval (`V09`), which is also the commit `trailofbits/coop` pins in
production (`X01`).

**Ledger rows settled.** `F361` (Codex-driven PR code review workflow) and
`F362` (Codex-driven assistant workflow triggered by comment),
`docs/port/COMMONALITY.md:365-366`, both origin `none`, both `RUST-ONLY`, both
bundled here. This decision recommends **shipping both files**. Assigning the
final verdict and editing the ledger are the controller's, not this item's.

**No `BASELINE-REVIEW:` finding is raised, and that is a result rather than an
omission.** Two things are true and both were checked. First, F361 and F362 have
**no row in `docs/port/BASELINE-REVIEW.md`** to challenge: that document
adjudicated every `COMMON → REUSE` and `ADOPT` row, and these two are origin
`none` / `RUST-ONLY`, created on the 2026-09-12 amendment. Second, nothing found
here contradicts R18's published Claude configuration. Where this decision's
shape differs from R18's — no `id-token` grant, no write permission on the
credential-bearing job, a three-job split, two events rather than four — every
difference traces to a **vendor** difference read in source, not to a defect in
R18's choices: the Claude action posts comments itself and exchanges an OIDC
token for a GitHub App installation token, and `openai/codex-action` does
neither (`C06`–`C09`, `S05`, `S06`). A disagreement with R18 would have to be a
claim that R18 chose wrongly *for the Claude action*, and this research found no
evidence for one.

**The membership question the prompt posed is answered: together.** The prompt
asked whether the two lanes are in fact adopted or dropped together rather than
assuming it. They are adopted together, and the reason is a property of the
*pair* rather than of either lane. The review lane carries a fork guard, so
**pull requests from forks are never reviewed automatically** — which, for a
public template whose contributions arrive mostly from forks, is most of the
traffic. The assistant lane is the only way such a pull request gets a Codex
review at all: a maintainer reads it and comments `/codex`, and the
`author_association` prefilter is satisfied by the **maintainer**, not by the
contributor, so the guard holds while the capability reaches the fork. Dropping
the assistant lane would leave fork pull requests with no Codex review by any
route. `supabase/cli` documents and accepts exactly this division (`X09`).

### Landscape

**The category this item decides is GitHub Actions workflow configuration, not a
Rust crate.** No crate exists in this category, so every crates.io figure in the
prompt's evidence table is recorded as `inapplicable` with its reason under each
member, and the substitutes the prompt directs for a GitHub Action candidate —
the repository figures, the vendor's own versioning and support statement, and
the licence of the action's own source tree — are supplied instead.

**Three-bin map of the field.**

| Bin | Candidate | What it is | Evidence |
|---|---|---|---|
| Built-in / first-party | **`openai/codex-action`** | A composite GitHub Action published by the vendor: `action.yml` carries `author: "OpenAI"` and `name: "Codex Exec Action"`, and the repository sits under the `openai` organisation. It installs the Codex CLI and a Responses-API proxy, runs `codex exec`, and returns the model's final message as a step output. | `V01`, `V02`, `V05`, `V06` |
| Built-in / first-party | **Codex cloud code review** (the hosted `chatgpt-codex-connector` GitHub App) | A vendor-hosted App enabled per repository from Codex settings, not from a file in the tree. It claims the `@codex review` and `@codex security review` commands and, with automatic review on, reviews new pull requests unprompted. Configured through `AGENTS.md`. | `X14`, `X15`; named as the alternative by the action's own README (`D10`) |
| Built-in / first-party | **The Codex CLI in a bare `run:` step** | `npm install -g @openai/codex@<version>` then `codex exec`, with no action wrapper. This is what the action does internally, minus the privilege reduction, the profile selection and the credential proxy. | `P01`, `S01` |
| Established industry standard (a *pattern*) | **The two-job split** — a model job with no write permission, a poster job with no model credential | The model runs holding `contents: read`; its output crosses a job boundary as a `needs` output; a second job holding `pull-requests: write` and no credential posts it. | the vendor's README example (`D09`) and `docs/security.md` (`D05`); `trailofbits/coop` (`X05`) |
| Established industry standard (a pattern) | **An `author_association` prefilter in a job-level `if:`** | `contains(fromJSON('["OWNER","MEMBER","COLLABORATOR"]'), github.event.comment.author_association)` | reached independently by `trailofbits/coop` (`X02`) and by R18 |
| Up-and-comer | **Codex permission profiles** (`":read-only"`, `":workspace"`) | The vendor's replacement for the legacy `sandbox:` input, **beta**, requiring CLI `0.138.0` or later. | `P10`; CHANGELOG v1.10 (2026-07-02) |
| Up-and-comer | **Third-party Codex action wrappers** | Present in the ecosystem and, as this research found, *more visible than the first-party action* — see the Marketplace finding below. Not evaluated individually: a first-party, Apache-2.0, vendor-dogfooded alternative exists, so a wrapper adds a supply-chain hop for no capability this item needs. Recorded so the bin is not empty by omission. | `M05`, `M08`, `M09`, `M10` |

**A finding about the vendor's support statement that changes how "first-party"
should be read, and that no raw report made.** There is **no vendor support
statement and no Marketplace listing.** Issue `#168`, "Publish codex-action to
GitHub Marketplace and request verified creator status", has been **open with
zero comments** since 2026-08-26 (`M01`, `M02`). The Marketplace slug the
action's own `name:` would produce, `/marketplace/actions/codex-exec-action`,
returns **HTTP 404** (`M03`). The slug a maintainer would actually type,
`/marketplace/actions/codex-action`, returns **HTTP 200** — and resolves to
`icoretech/codex-action`, a **third-party** repository with 8 stars that names
`openai/codex-action` nowhere on the page (`M04`, `M05`, `M06`, `M10`). A
Marketplace search for "codex" lists no first-party entry at all (`M07`); the
codex-named listings it does return are `gersmann/codex-review-action` and
`p2achAI/codex-reviewer` (`M08`, `M09`). So "first-party" here is established by
the repository owner and by `action.yml`'s `author:` field — **not** by a
Marketplace badge, because there is none, and a maintainer who reaches for the
Marketplace finds somebody else's action under the obvious name. That is a
concrete supply-chain confusion hazard, and it is the strongest argument in this
decision for naming the action by its **full repository coordinate** wherever it
is documented.

**Authority, established rather than assumed.** Five classes of source, each with
why it counts.

1. **The platform's own normative surface.** GitHub's context-availability table
   was fetched and the four relevant rows extracted mechanically rather than
   quoted from memory (`G01`–`G04`), and the rule was then **executed** against
   `actionlint` 1.7.12 with a reproducing negative control (`L03`).
2. **The vendor's own source and documentation, read at the pin.** `action.yml`,
   `README.md`, `CHANGELOG.md`, `docs/security.md`, `src/checkActorPermissions.ts`
   and `src/main.ts`, every one fetched at commit
   `86365089eb2b84e0a8fb0717b304f8bdcb13b20e` rather than at `main` — which
   matters, because `main`'s `pushed_at` is 2026-09-11, **after** the v1.12 tag,
   so `main` carries unreleased commits (`A08`). No vendor behaviour is asserted
   in this decision that is not read from one of those six files, and the source
   tree is eight files in total (`S10`), so the absences reported below are a
   complete census rather than a sample.
3. **The vendor dogfooding the action inside a large Rust project.**
   `openai/codex` is itself a Rust codebase and runs this action in three
   workflows. Weighted as a reference implementation rather than as independent
   adoption, because it is the vendor. *Carried from `raw/opus.md`* — this
   synthesis did not re-fetch those three files.
4. **Independent, well-regarded adopters**, each re-fetched here and named below.
5. **The normalizer's own record** of what the Doxa legs did and did not produce
   (`N01`–`N06`), so that engine disagreement is weighed against what each leg
   actually delivered.

**Practice evidence — the projects surveyed, and why each counts.**

| Project | Why it is a relevant, well-regarded reference | What its file shows | Evidence |
|---|---|---|---|
| `trailofbits/coop` | Trail of Bits is a security-research firm whose published work on agent workflows is widely cited; this is the closest thing found to a security-reviewed reference implementation of the comment-triggered lane. | `issue_comment` + `pull_request_review_comment`; the `author_association` gate; `permission-profile: :read-only`; `safety-strategy: drop-sudo`; a literal `UNTRUSTED PR DATA` warning in the packet; a poster job commented `pull-requests: write # No model credential; only posts the completed review.`; the action pinned to the same commit this decision resolved. | `X01`–`X06` |
| `supabase/cli` | A widely used vendor CLI, and the only surveyed project running **two vendors' reviewers on one pull request** — the direct evidence the two-vendor question asks for. | Both vendors in parallel read-only jobs, a third job adjudicating and tagging findings `sources: claude \| codex \| both`, one job posting. Its design document states the churn it was built to end and the operating instruction it cannot enforce. | `X07`–`X11` |
| `astral-sh/uv` | A Rust project by the maintainers of the toolchain `py-launch-blueprint` standardises on, and therefore a project this programme already treats as authoritative elsewhere. | `issue_comment: [created]`; the action pinned by commit; **`codex-version` pinned explicitly to `0.147.0`**; `safety-strategy: drop-sudo`. | `X12`, `X13` |
| `openai/codex` | The vendor's own Rust product. Three Codex workflows, each with the model job on `contents: read` and a separate `issues: write` job. | *Carried from `raw/opus.md`*, not re-fetched here. | — |

**Fit over abstract best.** The use case is a **public Rust template whose
consumers fork it**: a CLI, a library crate and an optional web service, with no
Rust code written yet. Two consequences drive every choice below, and neither is
a general best-practice argument. First, **the adopter installs the credential,
not the template owner**, so the mechanism must behave correctly and quietly
with no credential at all. Second, **the template's own repository is public**,
so the lanes must be safe against a stranger commenting on it — a different
problem from the same lanes on a private application repository.

**Source precedent.** Origin `none`. Neither `py-launch-blueprint` nor
`ts-launch-blueprint` ships any Codex or OpenAI workflow, so there is nothing to
port, inherit or override. *Carried from `raw/opus.md`*, which verified this
against both pinned trees; this synthesis did not re-run that search.

### Principles and implementation

**The shared requirement, its source, and its agreement level.** The requirement
is the **owner amendment of 2026-09-12** (`docs/planning/p02/owner-decisions.md`
§4; `docs/planning/p02/execution-ledger.md:435` and `:439`): a Codex equivalent
of both Claude workflows exists in the template, so that both vendors' workflows
ship. Its agreement level is **policy or mechanism** — the same level R18
assigned the Claude pair, and for the same reason: the reviewing entity is a
paid third-party service reached with an organization credential, so whether to
spend it here needs an owner decision, which is exactly what exists. The
amendment binds the *rs* template only; it registers nothing across `py` and
`ts`, neither of which ships a Codex workflow.

**What must agree and what may vary.** What must agree is the **guard contract**,
because it is simultaneously a security property and a correctness property and
is ecosystem-neutral. R18 states it in four clauses, and **this item mirrors all
four**, naming each clause it mirrors and stating where the vendor differs.

- **R18 clause (a) — the review lane never runs on a fork pull request.**
  Mirrored unchanged. Here it has a second, sharper reason than R18's
  runner-minute argument: on a `pull_request` event from a fork, GitHub exposes
  no repository secret to the run, so a preflight *without* a fork guard would
  read an empty `OPENAI_API_KEY` on a **fully configured** repository and print
  "the key needs setting" on every external contributor's pull request — a
  message that is false, that instructs a maintainer to do something already
  done, and that would recur forever. Guard: `FR17`.
- **R18 clause (b) — neither lane runs when the triggering content's author or
  the run's initiator is a bot.** Mirrored on both lanes, type-based rather than
  a name denylist, for the reason R18 gives: a type check is name-independent
  and needs no enumeration. `FR04`, `FR19`, `FA04`, `FA22`. **Where the vendor
  differs, and it differs in the template's favour**, is under "Bot exclusion"
  below.
- **R18 clause (c) — no credential is reachable from a run whose content an
  untrusted contributor controls.** Mirrored by the fork guard upstream, by
  credential presence downstream, and by one thing R18's vendor could not offer:
  the action's write-access check runs **before** the credential reaches any
  process (`S01`, `S02`).
- **R18 clause (d) — on a public repository the assistant lane never *starts* for
  an author outside `OWNER`, `MEMBER` or `COLLABORATOR`.** Mirrored in the exact
  expression shape R18 specifies (`FA20`). What it does not do is restated with
  it, unchanged: it is **not** a write-access check, and it does not stop a
  trusted author who pastes untrusted text.

What may vary per repository: whether a credential is installed at all, or
whether the file is deleted — which is the owner's chosen way to refuse the
capability outright.

**Architectural alternatives, compared before the mechanism was chosen.** Three
architectures can deliver "a Codex reviewer answers on this repository", and the
choice among them precedes every configuration question.

| Architecture | Expressed as | Travels through "Use this template"? | Verdict |
|---|---|---|---|
| **A. Workflow-file agent** (`openai/codex-action` in `.github/workflows/`) | YAML in the tree, versioned and reviewed like code | **Yes** — the file *is* tree content | **Chosen.** The only architecture that is itself a template artifact, and the only one that can satisfy owner behaviours 1, 3 and 4. |
| **B. Vendor-hosted App** (Codex cloud code review, the `chatgpt-codex-connector`) | repository *state*, enabled from Codex settings | **No** | **Rejected on the owner's own requirements**, not on a fitness gate: there is no file to ship by default, no file to delete as the opt-out, and no credential in the repository whose absence could be detected and printed about. It fails owner behaviours 1, 3 and 4 by construction. It is also the source of a live interaction cost, below. |
| **C. Bare CLI in a `run:` step** | bespoke YAML plus `npm install -g` | Yes | **Rejected on privilege posture.** It reproduces none of the action's privilege reduction, and the vendor's own security page documents the concrete exfiltration path that omission opens: read-only filesystem access plus passwordless `sudo` — the default on GitHub-hosted runners — is enough to read `OPENAI_API_KEY` out of process memory (`D11`), and names `drop-sudo` or `unprivileged-user` as what closes it (`D12`) — which both lanes keep. |

**Why the selected design preserves each principle, mechanism by mechanism.**

*The credential is a secret, and that is not a configuration choice.* The action
declares exactly **one** credential input, `openai-api-key` (`C01`). There is no
`azure-openai-api-key` input and the string `AZURE_OPENAI_API_KEY` appears
nowhere in `action.yml` (`C02`, `C03`); an Azure-hosted deployment is reached by
overriding `responses-api-endpoint` while still supplying the same key input,
and the input's own description gives an Azure endpoint as its worked example
(`C04`, `C05`). **So there is exactly one credential path, and its kind is a
GitHub Actions secret.** This is a structural difference from the Claude side,
where R18 found a second path — workload-identity federation through repository
**variables**, which a job-level `if:` *can* read. No such path exists here.
The one-line job-level gate is therefore unavailable **in principle**, not merely
unused, and the preflight indirection is forced rather than preferred.

*The gate is a preflight job, verified three ways.* GitHub's own context table
lists exactly `github, needs, vars, inputs` for `jobs.<job_id>.if` — `secrets` is
absent (`G01`) — and lists `secrets` as available in `jobs.<job_id>.env` (`G02`),
which is what makes the relay possible at all. The gate cannot simply move down
one level, because `secrets` is absent from `jobs.<job_id>.steps.if` too (`G03`).
And a job **output** *may* carry a secret-derived value (`G04`), which is why the
preflight publishes one of the literal strings `present` or `none` rather than
anything derived from the key: a secret-derived output would be masked. The rule
was then executed: `actionlint` 1.7.12 rejects
`if: secrets.OPENAI_API_KEY != ''` at the job level with exit 1 and the
diagnostic `context "secrets" is not allowed here. available contexts are
"github", "inputs", "needs", "vars"` (`L03`).

*The gate is written as a positive predicate, and that is a correctness fix
rather than a style preference.* **This is R18's finding, mirrored deliberately.**
A skipped job's outputs are **empty**, so if the preflight is skipped — which is
exactly what a rejected fork, draft, bot or association guard does to it — then
`needs.credential-preflight.outputs.credential` is the empty string, and a
negative gate (`!= 'none'`) evaluates **true**. Written that way, the real job's
skip would rest *entirely* on skip propagation, the one leg of the mechanism no
check here observed. Both fixtures therefore gate on `== 'present'`, which is
false on an empty output as well as on `'none'`, so the guards bind the model job
**through the value as well as through the dependency** (`FR01`, `FR02`, `FA01`,
`FA02`). **And the honest limit is recorded rather than glossed**: the negative
form also lints clean (`L05`), so the linter does *not* establish the polarity;
the argument for the positive form is the empty-output semantics of a skipped
dependency, which is documented platform behaviour and **was not observed here**.

*What the clean lint does and does not establish.* It is a statement about the
**wiring**, not only the syntax: a deliberately misspelled
`needs.credential-preflight.outputs.credentail` is rejected with `property
"credentail" is not defined in object type {credential: string}` (`L04`), so
`actionlint` type-checks the relay between the preflight's declared `outputs:`
and the consumer's reference. **Nothing about runtime behaviour follows from any
of it.**

*The permission split is forced by the mechanism, not chosen for elegance.* The
action **cannot post a comment**: no comment-creating call appears in `action.yml`
or in `src/main.ts` (`S05`, `S06`), across a source tree of eight files (`S10`),
and its single output is `final-message` (`S07`). So a separate poster job is the
only way to build either lane. That the ecosystem independently recommends the
same containment — the vendor's own `docs/security.md` ("it is possible to take
the output of the `openai/codex-action` and then pass it along to a new job",
`D05`), its README example (`D09`), and `trailofbits/coop`'s poster job commented
"No model credential; only posts the completed review" (`X05`) — makes it a
convergence rather than an invention.

*The mechanism requests no additional token of its own.* There is no OIDC step
and no `id-token` request anywhere in `action.yml` (`C06`, `C07`), no
`getIDToken` call in the source (`C08`), and **no App-installation-token
exchange** (`C09`). The only GitHub credential the action touches is the
workflow's own `github.token`, passed to the write-access check (`C10`).
**R18's central finding for the Claude action therefore has no analogue here**:
there is no write-capable App token minted before any actor-trust check returns,
because no such token is minted at all. Neither lane requests `id-token` on any
job (`FR09`, `FA09`).

*The checkout is of the trusted branch, and that closes an exposure the vendor
names.* The Codex CLI reads `AGENTS.md` from its working directory
automatically, and `docs/security.md` lists repository instruction files under
pull-request control as "part of the untrusted input surface" (`D03`). Checking
out the pull request's tree would hand the agent instructions written by the
pull request's author. The review lane therefore checks out
`github.event.pull_request.base.sha` and fetches the head as a **ref only**
(`FR21`); the assistant lane checks out the default branch. **This constrains the
checkout and decides nothing about `AGENTS.md`'s content or placement, which are
F197's.**

**Bot exclusion — the vendor's internal check is better than the Claude action's
and still does not substitute for the workflow guard.** R18 found the Claude
action's `checkWritePermissions` returns `true` **unconditionally** for any actor
whose login ends in `[bot]`. That is **not** what this vendor does, and the
difference was read in source rather than assumed:

| Fact | Where | Consequence |
|---|---|---|
| `isBotActor` is `actor.toLowerCase().endsWith("[bot]")` | `checkActorPermissions.ts:205-207` | the same predicate the Claude action uses |
| but the shortcut is `if (allowBotActors && isTrustedGitHubBotActor(actor))`, and `TRUSTED_GITHUB_BOT_ACTORS` is `new Set(["github-actions[bot]"])` | `:79`, `:184` (`B02`, `B03`) | **no unconditional bot approval exists.** The shortcut needs `allow-bots` *and* that one specific login |
| `allowBotActors` defaults to `false` | `:50` (`B04`) | and by default it is off, so by default no bot is shortcut-approved |
| a bot that is not shortcut-approved falls through to `getCollaboratorPermissionLevel`, which approves `admin \| write \| maintain` | `:139`, `:168` (`B05`) | **a bot holding write access still passes.** The internal check is a write-permission test, not a bot test |
| the actor it checks is `process.env.GITHUB_ACTOR` | `:48` (`B06`) | it never sees the **comment author**, so it cannot be the comment-author guard |

So the workflow's two type checks are load-bearing for **two independent
reasons**: the internal check admits write-holding bots, and it inspects the
wrong principal on a comment event. They are also the control that stops the
lane answering **itself** — the poster job's comment is authored by
`github-actions[bot]`, and `issue_comment` fires on it.

**The trusted-author residual — identical in its input half, materially narrower
in its consequence half, and wider in exactly one place.** R18's finding is that a
trusted author routinely quotes untrusted content into text the lane processes,
and that no `author_association` prefilter separates the author's own words from
text that author pasted.

- **Identical in the input half.** The vendor states the exposure class in its own
  words and enumerates **four** vectors where R18 named three: "these same
  sources can also be used as vehicles for _prompt injection_" (`D01`), including
  a pull-request body where "it is fairly easy to hide information … using an
  HTML comment" (`D02`), commit messages, repository instruction files (`D03`)
  and screenshots. Nothing in `author_association` distinguishes any of these
  from the author's own words. **No published advisory names this as a
  vulnerability in `openai/codex-action`**: the repository publishes zero
  security advisories (`A01`) and the GitHub Advisory Database returns zero
  `actions`-ecosystem advisories matching `codex` (`A02`). The class is
  documented by the vendor as a **design property**, not as a defect.
- **Narrower in the consequence half, for three reasons read in source.**
  (i) There is no App-installation-token exchange, so the escalation path R18
  traced does not exist (`C09`). (ii) The agent runs under `drop-sudo`, which the
  action **verifies**, failing the job if `sudo` survives. (iii) Under
  `":read-only"` the agent has no filesystem write and no network, so a
  successful injection cannot exfiltrate over the network from inside the
  sandbox and cannot modify the checkout. What it *can* still do is shape the
  text the model returns, which the poster job publishes verbatim.
- **Wider in exactly one place, and it is named.** The returned text crosses a job
  boundary as a `needs` output and reaches a `run:` script. Vendor issue `#175`,
  "Codex output containing GitHub workflow commands can fail an otherwise
  successful action", is **open** (`A09`): model-authored text that happens to
  contain Actions workflow commands is interpreted by the runner. The mitigation
  is the vendor's own guidance — pass every value through `env:` and quote the
  shell variable (`D04`) — which both poster jobs and the assistant's request
  packet do (`FA24`).

**The one place the owner's requirement and the mechanism genuinely disagree,
stated rather than smoothed over.** The owner ruled that the author-trust test is
an `author_association` check and **not** a write-permission check, having
considered and rejected the latter. This decision adds no write-permission check
at the workflow level. **But the vendor's action runs one of its own, and this
template cannot remove it**: `docs/security.md` states that "By default,
`openai/codex-action` can only be run by a user who has _write_ access to your
repository" (`B10`), and a rejected actor **throws** (`B08`, `B09`), so the model
job ends **`failure`** — a red check — rather than skipping. The observable
consequence: an organisation `MEMBER` holding only `read` **passes** the
preflight's association guard and then **fails** the model job. Three options
exist and each has a cost; **P03 decides, and the option the owner already ruled
out is not among them.**

| Option | Effect | Cost |
|---|---|---|
| Accept the failure as the signal | the account learns it lacks write, from the action's own message | a red check on the pull request for a legitimate-looking request |
| Name such accounts in `allow-users` | they proceed | `allow-users` bypasses the collateral check for those logins, and `"*"` would neutralise it entirely (`B07`) — the vendor names the API-key abuse that invites (`D06`) |
| Narrow the association list to `OWNER` | no such gap | the assistant becomes unusable by collaborators, which is most of its point |

Adding a write-permission check to the workflow's `if:` would close the gap and
is **not admissible**: the owner ruled it out on 2026-09-12. `supabase/cli` made
the opposite choice for itself — "Authorization for `/ai-review` requires
repository write, not org membership" (`X11`) — and that divergence is recorded
here rather than used to reopen the ruling.

**Essential behaviors and observable acceptance criteria.** Each is for P03 to
prove; none was observed here.

| # | Essential behavior | Observable acceptance criterion |
|---|---|---|
| B1 | A qualifying same-repository pull request starts the review lane and it posts | `credential-preflight success`, `codex-review success`, exactly one `github-actions` comment on the pull request |
| B2 | **The credential-absent path — the owner requirement this research could not observe.** A clone with no `OPENAI_API_KEY` does not run the lane, does not error, and prints which key needs setting | for a qualifying pull request and a qualifying `/codex` comment: `credential-preflight` `conclusion == "success"` with output `credential=none`; `codex-review` / `codex-assistant` `conclusion == "skipped"`, **not** `failure`; **no red check**; one `::notice` naming `OPENAI_API_KEY`; a step summary naming the secret **and** file deletion as the opt-out. Also assert the opt-out itself: with the file deleted, no run is created |
| B3 | **The pre-existing-credential path.** A repository that already holds `OPENAI_API_KEY` for an unrelated purpose | the preflight publishes `credential=present`, the lane runs, and the `present` branch prints the line naming the detected credential and the deletion opt-out. This is the only channel that reaches an adopter who performed no act of acceptance — see below |
| B4 | **Bot rejection, both lanes** | a `github-actions[bot]`-opened pull request, and a `[bot]`-authored comment beginning `/codex`, each on a **credentialed** repository: assert either no run is created or the **model job's** `conclusion == "skipped"`. Asserting only the preflight's conclusion is **not sufficient** — that passes whether or not the model job ran |
| B5 | **Author trust** | `/codex` from an account whose `author_association` is `NONE` starts no run, and bills no runner minutes |
| B6 | **The `MEMBER`-without-write window** | from an organisation `MEMBER` holding only `read`, comment `/codex`: assert `credential-preflight success` and the model job `failure`, with the action's step reporting `Actor '<login>' must have write access`. P03 then chooses among the three options above |
| B7 | **No self-reply loop** | after a successful assistant invocation, the workflow's run count increased by exactly 1 |
| B8 | **Permission minimality** | `gh pr comment` succeeds with `pull-requests: write` and **no** `issues: write` — the one permission row this research could not settle |
| B9 | **The CLI pin is honoured** | the `Install Codex CLI` step's log line reads `npm install -g "@openai/codex@0.154.0"`, not `@openai/codex@` |
| B10 | **A draft that becomes ready produces exactly one review run** | open a draft pull request, mark it ready; the review workflow has exactly one run for that number |

**What installing a credential costs the adopter, and the case that argument does
not cover.** The template consumer is not exposed by the files alone: with no
credential, the preflight reads an empty value, publishes `credential=none`,
prints that the key needs setting, exits 0, and the model job is skipped. That
defence rests on **B2**, which is an acceptance criterion rather than an observed
outcome; if it fails, a stranger gets a red check instead of a skipped job.
Installing the credential is the act of acceptance, and it is taken by whoever
installs it. **One case defeats that sentence, and it is stated here rather than
left for an adopter to discover**: a repository created from this template that
**already holds `OPENAI_API_KEY`** — the vendor's generic name, not one this
template coined — takes no act of acceptance at all, and on the next qualifying
event both lanes go live. This decision therefore has the `present` branch print
one line naming the detected credential and the deletion opt-out (`FR22`, `FA26`), which R18
recommended to P03 and which is adopted here from the start, because it is the **only** channel that reaches that adopter.

**Rust-specific configuration.** Under `":read-only"` **none is required**: no
toolchain step, no build, no network. The Rust knowledge the lanes need — edition
2024, the MSRV policy, the CLI / library / web-service surfaces — lives in the
two template-local prompt files P03 authors. If the owner later wants
build-informed review, that is the `":workspace"` runner-up, and it costs a
toolchain step plus `cargo fetch` **before** the Codex step, because that profile
grants no network access.

### Recommendation

One stack: **`openai/codex-action@v1.12`** (commit
`86365089eb2b84e0a8fb0717b304f8bdcb13b20e`) × **`@openai/codex@0.154.0`** ×
`permission-profile: ":read-only"` × `safety-strategy: drop-sudo` ×
`actions/checkout@v5` × `ubuntu-latest`, invoked from **two** workflow files each
built as **three jobs** — `credential-preflight` → model job → poster job — with
the repository secret `OPENAI_API_KEY` as the single credential, an always-run
preflight publishing a literal `present`/`none` output that a **positive**
`needs` predicate consumes, and template-local prompt files passed as
`prompt-file:`.

**Trigger vocabulary: `/codex` as a leading command token, not `@codex`.** This is
the one place the recommendation departs from its best reference implementation,
and it has two independent reasons, both evidenced. `trailofbits/coop` uses
`contains(github.event.comment.body, '@codex')`. Both halves are worse here.
**`@codex` is the token the vendor's own hosted connector already claims** — it
documents "request reviews with `@codex review` and `@codex security review`"
(`X14`) and "Mention `@codex` in your pull request to ask questions or start a
task" (`X15`) — so on any adopter repository with Codex cloud enabled, one
comment would wake both the connector and this lane. And `contains()` matches
**anywhere** in the body, so a maintainer *quoting* a comment that carries the
token re-fires the lane, which is precisely the residual vector. `startsWith(…,
'/codex')` collides with neither the connector's `@codex` namespace nor R18's
`@claude` (`FA17`, `FA18`, `FA19`, `FA25`), and fires only when the token begins
the comment — which is also `supabase/cli`'s choice, whose command match requires that "the
comment's first line, trimmed, must be" the token (`X16`). **R45 owns whether this token is documented in
`.github/pull_request_template.md`; this item states only what the lane responds
to.**

### Members

#### Codex pull-request code review lane — `.github/workflows/codex-code-review.yml` (F361)

##### Landscape

The mechanism candidates are the four mapped at item level and are not restated.
The *pattern* layer adds one candidate specific to this member: the triggering
event, where the field offers `pull_request` (the vendor's README example and
`supabase/cli`) and `pull_request_target` (`Expensify/App`, *carried from
`raw/opus.md`*). The practice evidence for this member is the vendor's README
example (`D09`), `trailofbits/coop` (`X01`–`X06`) and `supabase/cli`
(`X07`–`X11`).

##### Principles and implementation

The principle this lane realises: **an automatic reviewer must be reachable only
from content the repository already trusts, must hold no write capability while
it reads that content, and must cost nothing on a clone that has not opted in.**
It is realised by four separable controls — three guards on the preflight (fork,
draft, two bot type checks) and the three-job permission split. `pull_request_target`
is **rejected**: it runs in the base repository's context with the base
repository's secrets while the event payload is attacker-authored, which is the
combination this design spends its guards avoiding (`FR16`).

##### Dominant choice

`openai/codex-action@v1.12` (`86365089eb2b84e0a8fb0717b304f8bdcb13b20e`),
invoked from a three-job file: `credential-preflight` → `codex-review` →
`post-review`.

Substituted figures, per the prompt's direction for a GitHub Action candidate
that publishes no crate. **Retrieval date for every row: 2026-09-17 (UTC)**,
recorded in `snapshots/fetched-at.txt` as `Thu Sep 17 22:51:43 UTC 2026`.

| Figure | Value | Endpoint / rule |
|---|---|---|
| 90-day downloads | `inapplicable` — a GitHub Action, publishes no crate | `crate.recent_downloads` has no analogue |
| All-time downloads | `inapplicable` — same reason | — |
| Last release | **`v1.12`, tagged 2026-08-20T23:40:26Z** | `GET /repos/openai/codex-action/releases` returns an **empty array** (`V07`): the project publishes no GitHub Releases, so the version is carried by git tags plus `CHANGELOG.md` (`V08`, `V12`, `V15`) |
| Stars | **1241** | `GET /repos/openai/codex-action` → `stargazers_count`. *Volatile; snapshot value.* |
| Archived | **`false`** (also not a fork, not private) | same → `archived` (`V03`) |
| Last push | **`2026-09-11T00:26:35Z`** | same → `pushed_at` (`A08`). **After** the v1.12 tag: `main` carries unreleased commits, which is why every source read here is at the pin |
| Open issues | **37** | `GET /search/issues?q=repo:openai/codex-action+is:issue+is:open` → `total_count` (`A05`). **Not** `open_issues_count`, which reads **80** because it conflates the **43** open pull requests (`A06`, `A07`) |
| Issue responsiveness | **0 of the 10 most recently opened issues has any maintainer comment; 10 unanswered; median days to first maintainer response undefined** | *Carried from `raw/opus.md`* — this synthesis did not re-run the ten-issue sweep. What it did verify: each of the six issues cited here was opened by a non-maintainer (`A14`), and `#168`, `#171` and `#175` all have **zero** comments (`M01`, `P08`, `A09`) |
| Advisories | **None against the action** (`A01`), and none in the `actions` ecosystem matching `codex` (`A02`). **Two against the CLI it installs** (`A03`, `A04`): `GHSA-xrxf-jgv3-qmrm` (critical, `<= 0.23.0`) and `GHSA-w5fx-fh39-j5rw` (high, `>= 0.2.0, <= 0.38.0`, first patched `0.39.0`). **Both ranges end far below the recommended `0.154.0` pin** | `GET /repos/openai/codex-action/security-advisories`; `GET /advisories?ecosystem=npm&affects=@openai/codex`; `GET /advisories?ecosystem=actions` |
| Adopters | `trailofbits/coop`, `supabase/cli`, `astral-sh/uv` — each re-fetched here (`X01`–`X13`); `openai/codex` and `Expensify/App` *carried from `raw/opus.md`* | `GET /repos/<o>/<r>/contents/.github/workflows/<file>` |

**Maintenance state: `active`, with one concrete deficiency named.** Cadence
supports it: 13 `v1.x` tags from `v1.0` (2025-10-06) to `v1.12` (2026-08-20)
(`V13`, `V16`), no `v2` (`V14`), substantive security work in the recent
releases including `#91` "tighten what bots are allowed" (`V17`), and a
`pushed_at` six days before retrieval. The deficiency is **issue triage** —
`#168`, `#171` and `#175` are each open with zero comments — compounded by the
**absent Marketplace listing and absent support statement** (`M01`–`M10`). The
rubric's `at-risk` verdict is **not** assigned: it requires a concrete signal
about the code's maintenance, and release and commit cadence both contradict
one. The triage gap and the Marketplace absence are carried as re-verification
triggers instead.

##### Qualified shortlist

1. **`openai/codex-action@v1.12` with `permission-profile: ":read-only"`** —
   recommended.
2. **The same action with `permission-profile: ":workspace"` plus a Rust
   toolchain and `cargo fetch`** — a real alternative, not a strawman:
   `":workspace"` lets the agent write the checkout, so it could run
   `cargo clippy` and review with compiler output in hand. Two costs: the profile
   grants **no network access**, so every dependency must be fetched *before* the
   Codex step, and the dependency tree of a template with an optional web service
   is not small; and a write-capable agent over pull-request-derived text is a
   wider residual for a review-quality gain this research did not measure.
3. **The same lane scoped to `pull_request: [opened]` only** — narrower; loses the
   review of a draft that becomes ready, which is the common path for a
   contribution prepared in the open.

##### Excluded by gate

- **Codex cloud code review (the hosted App)** — excluded on **owner behaviours 1,
  3 and 4**, not on a fitness gate: no file to ship, no file to delete, no
  credential to detect, nothing to print. Argued as architecture B above.
- **The Codex CLI in a bare `run:` step** — excluded on **gate 3 posture**: it
  reproduces none of the action's privilege reduction, and the vendor's own
  security page documents the exfiltration path that omission opens.
- **`pull_request_target` as the trigger** — excluded on the same gate-3 posture
  reasoning (`FR16`).
- **Third-party Codex action wrappers** — excluded on supply-chain fitness with a
  first-party alternative available. Named as a bin member rather than evaluated
  individually; this is an explicit scope limit, not a claim that none is good.
  The Marketplace finding (`M03`–`M10`) sharpens the reason rather than softening
  it: three of the codex-named Marketplace listings are third-party, and one of
  them holds the name a maintainer would search for.

**Fitness gates, answered before popularity was weighed.**

1. **Licence** — `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
   compatibility is not evaluated for any dependency or tool`. Metadata only: the
   action's tree is `Apache-2.0` (`V04`), as are both npm packages (`P07`).
2. **MSRV** — `inapplicable`: no crate, no `rust-version`, no Rust dependency
   tree. The action's runtime is Node.js 24, which the action installs itself and
   which is not a template dependency.
3. **Advisories and `unsafe` posture** — no advisory against the action (`A01`,
   `A02`); two historic advisories against the CLI, both below the pin (`A03`,
   `A04`). `unsafe` is `inapplicable` for a Node action; the **privilege** posture
   is stated instead and is the strongest of any candidate: `drop-sudo` by
   default, with a verification step that fails the job if `sudo` survives.
4. **OS matrix** — **passes.** "Linux/macOS: All options for `safety-strategy` are
   supported" (`D07`); Windows requires `safety-strategy: unsafe` and is noted,
   not required (`D08`). The lane pins `runs-on: ubuntu-latest`, which is inside
   `ubuntu-latest, macos-latest`; nothing in it needs `macos-latest`, and running
   a reviewer on two runners would double spend for no additional signal.
5. **Default features and async-runtime coupling** — `inapplicable` (no crate, no
   Cargo features, no async runtime). The action's equivalent defaults are stated
   instead, and this recommendation **overrides two of them**: `codex-version`
   defaults to `""` (**overridden** to `"0.154.0"`), and omitting both
   `permission-profile` and `sandbox` falls back to the legacy `workspace-write`
   sandbox (**overridden** to `":read-only"`). Two defaults are **kept**:
   `safety-strategy: drop-sudo` and `allow-bots: false`.
6. **Binary size and compile time** — `inapplicable`: nothing is compiled into the
   template and nothing links into the shipped binary. The runtime cost is stated
   under *Tradeoffs*.

##### Up-and-comers

**Codex permission profiles**, beta as of the README read at the pin, requiring
CLI `0.138.0` or later (`P10`) and introduced at `v1.10` (2026-07-02). Adopted
despite the beta label for three reasons: the alternative is the surface the
vendor is migrating away from; one surveyed adopter already runs a named profile
in production and another runs `:read-only` (`X03`); and the recommended CLI pin
`0.154.0` is sixteen minor versions above the floor. The beta status is carried
as a re-verification trigger, not hidden.

##### Fit for this template

**Fit 1 — an unconfigured fork is the normal case.** The template's consumers
fork it with no `OPENAI_API_KEY`. The preflight relay makes that state quiet and
self-describing: one short `ubuntu-latest` job per qualifying event, a `::notice`
naming the secret, a job summary naming both the secret and the deletion opt-out,
and a skipped dependent job.

**Fit 2 — the review target is Rust, and `:read-only` is enough for it.** Codex
reads the diff and the surrounding source; it does not build. No Rust toolchain
step is required in the recommended lane.

**Fit 3 — the permission split is free here.** Because the action cannot post
(`S05`, `S06`), the containment the ecosystem recommends is not an extra design
decision; it is the only way to build the lane.

**Misfit — the template owner pays for the origin repository's own runs.** Every
pull request opened against `rs-launch-blueprint` itself is one Codex run billed
to whoever installed `OPENAI_API_KEY` on the origin repository.

##### Recommendation

Ship `.github/workflows/codex-code-review.yml` as three jobs. The fixture is
`review/evidence/candidate-codex-code-review.yml`.

- `on: pull_request: types: [opened, ready_for_review, reopened]`; top-level
  `permissions: {}`.
- **`credential-preflight`** — `runs-on: ubuntu-latest`, `permissions: {}`, no
  checkout, always exits 0, `timeout-minutes: 5`. Its job-level `if:` carries
  **all four guards**: the fork guard (`FR17`), the draft clause (`FR18`), and two
  type-based bot checks — the pull request's author (`FR19`) and the run's
  initiator (`FR04`). One step reads `secrets.OPENAI_API_KEY` into a job-level
  `env:` value, publishes `credential=present|none`, and on the `none` branch
  prints a `::notice` naming `OPENAI_API_KEY` plus a `$GITHUB_STEP_SUMMARY` block
  naming the secret and naming file deletion as the opt-out. **On the `present`
  branch it also prints one line** naming the detected credential and the
  deletion opt-out — the only channel that reaches an adopter whose repository
  already carried the key.
- **`codex-review`** — `needs: credential-preflight`;
  `if: needs.credential-preflight.outputs.credential == 'present'` (**positive**);
  `permissions: contents: read`; `timeout-minutes: 20`. Checks out the base
  branch with `persist-credentials: false`, fetches the head as a ref, then runs
  the action with `openai-api-key`, `codex-version: "0.154.0"`,
  `permission-profile: ":read-only"`, `safety-strategy: drop-sudo` and
  `prompt-file: .github/codex/review-pr.md`. Publishes `final-message`.
- **`post-review`** — `needs: codex-review`;
  `if: needs.codex-review.outputs.final_message != ''`;
  `permissions: pull-requests: write`; **no model credential**; `gh pr comment`
  with every value passed through `env:`.

**Permissions, per job and per permission, with the evidence for each grant.**

| Permission | `credential-preflight` | `codex-review` | `post-review` | Evidence |
|---|---|---|---|---|
| `contents` | none | **read** | none | `actions/checkout` needs it; the action's own steps need nothing more |
| `pull-requests` | none | none | **write** | required to create the comment. `trailofbits/coop` grants exactly this and nothing else for `gh pr comment` (`X05`); the vendor's README example instead grants `issues: write` **and** `pull-requests: write`. **Which is minimal is not settled here** — acceptance criterion B8 |
| `issues` | none | none | none, **pending B8** | same |
| `id-token` | none | **none** | none | no OIDC step and no token exchange anywhere (`C06`–`C09`, `FR09`) |
| `actions` | none | none | none | neither lane reads workflow-run data |
| any other | none | none | none | top-level `permissions: {}` makes every unlisted scope `none` (`FR03`) |

**Does the mechanism request any additional token of its own? No.** The only
GitHub credential `action.yml` touches is `GITHUB_TOKEN: ${{ github.token }}`
(`C10`), used for one read in the write-access check. There is no App-token
exchange, so R18's "at what point relative to the actor check" question **does
not arise for this vendor** — and the ordering that does exist runs the right
way round: the write-access check precedes the CLI install, the credential-bearing
proxy and `codex exec` (`S01`, `S02`).

##### Ranked runner-up

**Ship this lane with `permission-profile: ":workspace"` plus a Rust toolchain and
`cargo fetch` before the Codex step**, so the reviewer can compile. It wins if the
owner judges that a reviewer which cannot run `cargo clippy` adds too little on a
Rust template to justify the runner minutes. It loses because it widens the
agent's capability over pull-request-derived text for a benefit this research did
not measure, and because the pre-fetch step must keep working as the dependency
tree grows.

**Second runner-up: ship neither Codex file.** It wins on any of three owner
judgements — declining recurring third-party spend on the origin repository;
declining a second vendor's AI exemplar in a public template tree; or judging
that two automatic reviewers on one pull request is worse than one (the evidence
is under `### Compatibility`, and it is real but not decisive). It is **not**
recommended, because the owner's 2026-09-12 direction is that both vendors'
workflows ship.

##### Tradeoffs

**Cost, with the workload stated.** Per qualifying pull request on a configured
repository: one preflight job (seconds), one Codex job bounded by
`timeout-minutes: 20` (`FR14`), one poster job (seconds). The Codex job's floor
is not the model call: the action runs two global `npm install -g` operations and
a `setup-node` step before the agent starts. **No wall time, token count or
dollar figure was measured here and none is asserted.**

**Reliability.** Three open vendor issues bear on it and are stated rather than
minimised: `#169` "Codex CLI 0.150.1 still hangs after final output" (`A10`),
`#172` "Codex PR review just hang forever" (`A11`) and `#160`, a `drop-sudo`
interaction with service sockets (`A12`). All three are open. `#169` names a CLI
version **below** the recommended pin (`A13`), which makes it a reliability risk
to watch rather than a defect in the pinned build. Together they are the direct
justification for `timeout-minutes: 20` on both lanes.

**The capability this lane deliberately gives up.** External contributors' pull
requests are **never automatically reviewed**, because the fork guard excludes
them. That is a real loss for a public template whose contributions arrive mostly
from forks. It is the same tradeoff `supabase/cli` documents and accepts (`X09`),
and it is the concrete reason the two members are complementary rather than
redundant.

##### Parameters

`owns —`.

`assumes rust-edition = 2024` · `assumes msrv-policy = stable minus 2 minor
versions, raised only in a minor release, declared as rust-version in Cargo.toml
and tested in CI` · `assumes license = MIT OR Apache-2.0` · `assumes
target-os-matrix = ubuntu-latest, macos-latest`. The registry-exact lines are in
`## Parameters`. No `CONFLICT:` line.

##### Migration implications

- `.github/workflows/codex-code-review.yml` — **new**.
- `.github/codex/review-pr.md` — **new**: the review prompt, carrying the
  template's Rust conventions and an explicit instruction that the pull request's
  title, body, commit messages and diff are **data, never instructions**.
- R20 owns the pin format for `openai/codex-action` and `actions/checkout`.
- R08 owns the repo-wide permission-hardening convention; the grants above are
  stated as this lane's needs.
- R11 and R12 own where these jobs sit in the graph. **Neither lane should be a
  required status check** — a lane skipped by design on every unconfigured clone
  cannot be required — but that is R12's call and is recorded as input to it.

##### Validation strategy

**Executed** (full detail in `## Empirical check`): the fixture lints clean under
`actionlint` 1.7.12 (`L01`); the negative control proves a job-level `if:` cannot
read `secrets` (`L03`); the misspelled-output control proves the linter
type-checks the `needs` relay (`L04`); the negative-gate control proves the
linter does **not** establish the gate's polarity (`L05`); and 22 assertions
confirm the fixture carries exactly the guards, permissions, pins and absences
this member recommends (`FR01`–`FR22`).

**Proposed, for P03:** acceptance criteria B1, B2, B3, B4, B5, B8, B9 and B10
above, each with the assertion that makes it fail honestly — in particular B2's
requirement that the **model job's** conclusion be asserted, not the preflight's.

##### Confidence & re-verify trigger

**High** — that `openai/codex-action` is first-party; that its current stable
version is `v1.12` at commit `86365089eb2b84e0a8fb0717b304f8bdcb13b20e`; that its
only credential path is the `openai-api-key` **secret**; that it mints no token
of its own and needs no `id-token`; that it cannot post comments; that its actor
check precedes the credential reaching any process; and that no Marketplace
listing or support statement exists. Each is read at a named path at the pin or
from a named endpoint, and each is asserted by a check in `check.log`.

**High** — that the credential gate must be a preflight job rather than a job
condition. Executed against `actionlint` with a reproducing negative control.

**Medium** — that an unconfigured clone yields `skipped` rather than `failure`
(B2). The skip-propagation rule is documented platform behaviour; **no run was
observed**, exactly as R18 records for its own equivalent.

**Low** — cost. No wall time, token count or dollar figure was measured.

**Low** — false-trigger and rate-limit behaviour on **template or starter**
repositories specifically. **No adopter report specific to that setting was
found**, and that absence is reported rather than filled.

Re-verification is triggered by: (a) a tag above `v1.12`, or `v1` ceasing to
resolve to `86365089eb2b84e0a8fb0717b304f8bdcb13b20e`; (b) issue `#171` closing,
since a `codex-version` default would change the explicit pin's rationale;
(c) `permission-profile` leaving beta, or `sandbox:` being removed; (d) an
advisory against the action, or against `@openai/codex` at or above `0.154.0`;
(e) Marketplace publication (`#168`), which would supply the support statement
this decision records as absent; (f) a further sweep finding continued zero
maintainer responses, which would move the maintenance verdict toward `at-risk`;
(g) `@openai/codex` and `@openai/codex-responses-api-proxy` ceasing to publish
the same version, which would break the single shared pin; (h) R18 publishing a
revision that changes the Claude lanes' trigger vocabulary.

##### Sources

`GET https://api.github.com/repos/openai/codex-action` ·
`.../git/ref/tags/v1.12` · `.../git/ref/tags/v1` · `.../git/tags/{cac08775…,f367b1e9…}` ·
`.../releases` · `.../tags` ·
`.../contents/{action.yml,README.md,CHANGELOG.md,docs/security.md,src/checkActorPermissions.ts,src/main.ts,examples,src}?ref=86365089eb2b84e0a8fb0717b304f8bdcb13b20e` ·
`.../security-advisories` ·
`GET https://api.github.com/search/issues?q=repo:openai/codex-action+is:issue+is:open` ·
`...+is:pr+is:open` · `.../issues/{160,168,169,171,172,175}` ·
`GET https://api.github.com/advisories?ecosystem=npm&affects=@openai/codex` ·
`GET https://api.github.com/advisories?ecosystem=actions` ·
`https://registry.npmjs.org/@openai/codex` ·
`https://registry.npmjs.org/@openai/codex-responses-api-proxy` ·
`https://github.com/marketplace/actions/{codex-exec-action,codex-action,codex-code-review-actor,codex-reviewer}` ·
`https://github.com/marketplace?query=codex&type=actions` ·
`https://api.github.com/repos/icoretech/codex-action` ·
`https://docs.github.com/en/actions/reference/workflows-and-actions/contexts` ·
`https://learn.chatgpt.com/docs/third-party/github` ·
`GET https://api.github.com/repos/{supabase/cli,trailofbits/coop,astral-sh/uv}/contents/...`.
All retrieved **2026-09-17 (UTC)** and snapshotted under
`review/evidence/snapshots/`.

#### Codex comment-triggered assistant lane — `.github/workflows/codex.yml` (F362)

##### Landscape

The mechanism candidates are the same four and are not restated. What differs for
this member is the single most consequential landscape finding in this decision:
**`openai/codex-action` has no interactive or mention-listening mode.**
`action.yml` requires `prompt` or `prompt-file` in its own words (`S04`), and the
`Run codex exec` step is gated `if: ${{ inputs.prompt != '' || inputs['prompt-file']
!= '' }}` (`S03`). There is **no analogue** of the Claude action's "Without
`prompt` input: Runs in interactive mode — waits for @claude mentions in
comments" that R18 quotes. **The assistant lane must therefore be built from
parts** — match the comment, extract its body, hand it to the model as data, post
the reply — rather than configured.

**The vendor ships no comment-triggered example.** `examples/` contains exactly
two files, `test-sandbox-protections.yml` and `unprivileged-user.yml`, neither a
comment lane and neither a review lane (`S08`, `S09`); the README's only worked
example is the `pull_request` bot. **This is an evidence gap in the vendor's own
material and it is reported as one.** The pattern evidence comes entirely from
independent adopters, of whom three run this lane: `trailofbits/coop` (`X01`),
`supabase/cli` (`X07`) and `astral-sh/uv` (`X12`).

##### Principles and implementation

The same principle as the review lane, with one addition forced by the trigger:
**the text that reaches the model is written by a human at run time, so the guard
must bind the author of that text and not only the initiator of the run.** Two
distinct actors exist on these events and they can differ —
`github.event.sender` is who caused the run, `github.event.comment.user` is who
wrote the text — so the lane checks **both** types (`FA04`, `FA22`), as R18 does,
because the cost is one clause and the failure mode is silent. This is doubly
necessary here because the action's internal check inspects `GITHUB_ACTOR` only
(`B06`).

**What this lane cannot do that R18's Claude assistant can.** R18's assistant
carries `contents: write` and can commit. This lane carries `contents: read` and
cannot (`FA21`). That is a deliberate narrowing, not an oversight: under
`":read-only"` the agent cannot write the checkout, so a committing lane would
need `":workspace"`, `contents: write` and a push step — three widenings on the
lane whose input is a comment. **If the owner wants a committing Codex assistant,
that is a different lane and this decision does not recommend it.**

##### Dominant choice

The same `openai/codex-action@v1.12` (`86365089eb2b84e0a8fb0717b304f8bdcb13b20e`)
with `codex-version: "0.154.0"`, `permission-profile: ":read-only"` and
`safety-strategy: drop-sudo`, invoked from a three-job file whose skeleton is the
review lane's.

**Figures.** Every crate figure is `inapplicable` for the same reason as the
review member — this lane is a workflow file invoking a GitHub Action and
publishes no crate — and the substituted repository figures, version resolution,
advisory position, maintenance verdict and adopter list are **the same artifact**
as the review member's and are not duplicated. They are: stars **1241**, archived
**false**, `pushed_at` **2026-09-11T00:26:35Z**, open issues **37** (open pull
requests **43**), last release **`v1.12`, tagged 2026-08-20T23:40:26Z**, no
GitHub Releases, no Marketplace listing, advisories **none against the action and
two against the CLI, both below the pin**, maintenance **`active` with an
issue-triage deficiency**.

##### Qualified shortlist

1. **`openai/codex-action@v1.12`, `":read-only"`, `startsWith(…, '/codex')`** —
   recommended.
2. **The same lane with `contains(github.event.comment.body, '@codex')`** — what
   `trailofbits/coop` ships. Rejected on two evidenced grounds: the token collides
   with the hosted connector's namespace (`X14`, `X15`), and `contains()`
   re-fires on quoted text, which is precisely the residual vector.
3. **The same lane scoped to `issue_comment` only** — narrower and simpler; loses
   the ability to invoke the assistant from an inline review thread, which is
   where a reviewer most naturally asks a question.
4. **A `workflow_dispatch` lane with a pull-request-number input** — no comment
   surface, so no comment residual. Rejected as the primary because the owner
   directed a **comment-triggered** Codex equivalent of the Claude assistant.

##### Excluded by gate

- **Codex cloud's `@codex` assistant commands** — excluded on the same
  owner-mechanism grounds as the hosted review: no file to ship, no file to
  delete, no credential to detect, nothing to print.
- **A committing assistant (`":workspace"` + `contents: write` + push)** —
  excluded on posture: it widens capability on the lane with the most
  attacker-reachable input, and no compensating benefit was evidenced.
- **`pull_request_review: submitted` as a third event** — excluded, and this is a
  disagreement settled against a Doxa leg rather than a strawman. That event
  carries **no comment body**, so neither `startsWith(github.event.comment.body,
  '/codex')` nor `github.event.comment.author_association` has a field to bind;
  admitting it would mean a *different, weaker* guard set on a wider surface for
  no capability this lane lacks. R18's Claude lane carries four events because
  the Claude action's interactive mode listens on all four; this action has no
  interactive mode (`S03`, `S04`), so the reason does not transfer.
- **`issues:` as an event** — excluded: this lane is scoped to pull-request
  conversations, which is where a Rust template's review assistance is wanted,
  and each omitted event is one fewer attacker-reachable entry point (`FA23`).
- **`allow-users: "*"`** — excluded explicitly. Surveyed adopters set it on
  **issue-triage** lanes whose model output is schema-constrained. On a lane that
  answers arbitrary free-text requests it approves every actor (`B07`) and invites
  the API-key abuse the vendor's security page describes (`D06`). The fixture
  sets no `allow-users` at all (`FA11`).

**Fitness gates.** Identical to the review member and not restated field by
field: gate 1 `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`; gate 2
`inapplicable` (no crate, no MSRV surface); gate 3 no advisory against the
action, two historic CLI advisories below the pin, `unsafe` `inapplicable` with
the privilege posture stated instead; gate 4 **passes** (`D07`, `D08`); gate 5
`inapplicable`, with the same two overrides and two kept defaults; gate 6
`inapplicable`.

##### Up-and-comers

The same beta permission-profile surface, adopted for the same reasons. One
additional up-and-comer specific to this member and **not** adopted: the action's
`output-schema` / `output-schema-file` inputs, which constrain the model to
structured JSON. For a free-text assistant whose reply is meant to be read by a
human, a schema adds a file to maintain for no gain; for the **review** lane it is
the path to inline, line-anchored comments, and is recorded there as a future
option rather than adopted.

##### Fit for this template

**Fit — this is how an external contributor's pull request gets reviewed at all.**
The review lane's fork guard means fork pull requests are never reviewed
automatically. This lane is the answer, and `author_association` is satisfied by
the **maintainer** who asks, not by the contributor — the same division
`supabase/cli` documents (`X09`). That turns the two members from duplicates into
a pair, and it is why the membership question resolves to "together".

**Fit — the trigger token is ours to choose.** Unlike the Claude assistant, whose
`@claude` token is the action's own internal convention, **nothing in
`openai/codex-action` fixes a token**: the workflow's `if:` is the entire matcher.
That freedom is what makes the collision fix available at zero cost.

**Misfit — the lane is bespoke.** With no vendor interactive mode and no vendor
example, the template owner maintains the comment match, the pull-request-number
resolution, the untrusted-request packet, the prompt file and the poster step —
every line of it the owner's to keep working.

##### Recommendation

Ship `.github/workflows/codex.yml` as three jobs. The fixture is
`review/evidence/candidate-codex.yml`.

- `on: issue_comment: types: [created]` and
  `pull_request_review_comment: types: [created]`; top-level `permissions: {}`.
- **`credential-preflight`** — `permissions: {}`, no checkout, always exits 0. Its
  `if:` carries **five** clauses: the command match
  `startsWith(github.event.comment.body, '/codex')` (`FA17`); the
  `author_association` prefilter in R18 clause (d)'s exact shape (`FA20`); two
  type-based bot checks, on the comment author and on the run's initiator
  (`FA22`, `FA04`); and a pull-request scope clause so a plain issue comment never
  starts a run (`FA23`). Same detection step and same printed output as the review
  lane, naming `.github/workflows/codex.yml` as the file to delete.
- **`codex-assistant`** — `needs: credential-preflight`; the same positive gate
  (`FA02`); `permissions: contents: read, pull-requests: read`;
  `timeout-minutes: 20`. Resolves the pull-request number, checks out the
  **default** branch with `persist-credentials: false`, writes the comment body
  and author into a JSON packet carrying a literal untrusted-data warning
  (`FA24`), then runs the action with `prompt-file: .github/codex/assist.md`. The
  prompt file instructs the model to read that packet **as data**.
  `pull-requests: read` is granted so the prompt can be extended to pull in prior
  review threads, as `trailofbits/coop` does.
- **`post-reply`** — `needs: codex-assistant`; `permissions: pull-requests: write`;
  **no model credential**; `gh pr comment` with every value through `env:`.

**Permissions per job and per permission:** `credential-preflight` `{}`;
`codex-assistant` `contents: read` + `pull-requests: read`; `post-reply`
`pull-requests: write`. `id-token`: **none on any job** — no OIDC exchange exists
(`FA09`). `actions`: none. `issues`: none, subject to the same unsettled
minimality question as the review lane (B8). The mechanism requests **no
additional token of its own**.

**Bot rejection, exactly as the owner requires.** The two type checks on the
preflight are the controls that satisfy owner behaviour 5, and they are the
controls that do the work: the action's `allow-bots: false` default is **better
than the Claude action's equivalent** — it does not shortcut-approve `[bot]`
actors (`B03`, `B04`) — but it is a *write-permission* test, so a bot holding
write still passes it (`B05`), it inspects the run actor rather than the comment
author (`B06`), and in any case it fires downstream, after the job is scheduled
and runner minutes are spent.

##### Ranked runner-up

**Drop this member and ship the review lane alone.** It wins if the owner judges
the bespoke maintenance surface too high for a template, or the comment residual
unacceptable on a public repository. It loses on two grounds. First, the marginal
cost is small: the two lanes share the preflight, the credential, the guards, the
action pin and the poster shape, so the second file is largely the first with a
different trigger and a different prompt — which is the same-vendor,
same-action-family argument that bundles F361 and F362, now confirmed by
construction rather than assumed. Second, and decisively, **dropping this member
leaves fork pull requests with no Codex review at all.**

**Second runner-up:** ship it scoped to `issue_comment` only.

##### Tradeoffs

Per invocation on a configured repository: one preflight job, one Codex job
bounded at 20 minutes (`FA14`), one poster job — the same profile as the review
lane. **Spend on this lane is driven by humans asking, not by repository
traffic**, the opposite of the review lane. Here the security ranking does **not**
point the other way as strongly as R18 found for Claude, because this lane holds
no write capability and mints no token; the widest thing it does is publish
model-authored text.

**False triggers and loops.** No adopter report specific to template or starter
repositories was found, and that absence is reported rather than filled. What was
found is general and bears directly on the design: the lane's own comment is
posted by `github-actions[bot]` and `issue_comment` fires on it, so **without a
bot check the lane answers itself** — which is what the two type checks prevent,
and why they are not merely an owner requirement.

**Rust-specific configuration.** Under `":read-only"` none is required. One
interaction matters and is stated because it is easy to get wrong: the Codex CLI
loads `AGENTS.md` from its working directory, so the checkout of the **default**
branch is what keeps the loaded `AGENTS.md` trusted (`D03`). This constrains the
checkout only; `AGENTS.md`'s content and placement are F197's.

##### Parameters

`owns —`. Same four `assumes` values as the review member; the registry-exact
lines are in `## Parameters`. No `CONFLICT:` line.

##### Migration implications

- `.github/workflows/codex.yml` — **new**.
- `.github/codex/assist.md` — **new**: the assistant prompt, carrying the same
  untrusted-input instruction as the review prompt plus how to read
  `.codex-request.json`.
- R45 owns whether `/codex` is documented in `.github/pull_request_template.md`
  and must name whichever bots are actually configured; this item supplies the
  token and nothing more. **Input to R45**, not a decision taken here: the hosted
  `chatgpt-codex-connector` is a bot an adopter may well have configured, and
  `supabase/cli` had to state its disabling as an operating instruction it cannot
  enforce (`X10`).
- R20 owns the pin format.

##### Validation strategy

**Executed:** the fixture lints clean under `actionlint` 1.7.12 (`L02`), sharing
the three controls with the review member, and 26 assertions confirm it carries
the five preflight clauses, the positive gate, the permission split, the pins and
the required absences — including that **no configuration line names `@claude` or
`@codex`** once comments are stripped (`FA19`, `FA25`), which is the collision
claim checked rather than asserted.

**Proposed, for P03:** acceptance criteria B2 through B8, plus the self-reply
check (B7) and the `MEMBER`-without-write window (B6). One further check is
**specific to this lane and could not be run here**: that a comment beginning
`/codex` does **not** wake the hosted connector on a repository where it is
enabled. That is the single most checkable unverified claim in this member.

##### Confidence & re-verify trigger

**High** — that no interactive mode exists and the lane must be built from parts
(`S03`, `S04`), confirmed by the absence of any vendor comment-triggered example
(`S08`, `S09`).

**High** — on the guard set, and on the fact that the action's bot default does
not substitute for it (`B03`–`B06`).

**Medium** — the trigger-token recommendation. The collision with the connector's
`@codex` namespace is **documented** (`X14`, `X15`); that a comment beginning
`/codex` does not wake the connector was **not tested**.

**Medium** — the interaction between the owner's association guard and the
action's internal write check. That an organisation `MEMBER` holding only `read`
passes the first and fails the second follows from the definition of
`author_association` and from the `admin|write|maintain` predicate, both read
(`B05`, `B08`); **the resulting failed job was not observed**, and what P03
should do about it is framed above rather than decided.

**Low** — cost, and false-trigger behaviour on template repositories specifically.

The review member's triggers (a) through (h) apply unchanged, plus: (i) the vendor
adding an interactive or mention-listening mode, which would make this lane's
bespoke machinery obsolete; (j) the hosted connector's trigger vocabulary
changing, which would change the collision analysis.

##### Sources

The endpoint list is the review member's and is not duplicated. The
member-specific citations are:
`.../contents/action.yml?ref=86365089…` (the `prompt`/`prompt-file` requirement
and the `Run codex exec` gate) ·
`.../contents/examples?ref=86365089…` (exactly two files, neither
comment-triggered) ·
`.../contents/docs/security.md?ref=86365089…` ("Defending against untrusted
input", the four vectors, "Avoid shell injection in workflow steps") ·
`.../issues/175` (model output containing workflow commands) ·
`https://learn.chatgpt.com/docs/third-party/github` (`@codex review` and the bare
`@codex` mention as the connector's triggers) ·
`.../repos/trailofbits/coop/contents/.github/workflows/codex-review.yml` and
`.../repos/supabase/cli/contents/.github/ai-review/README.md` (the two reference
comment lanes) · `actionlint` 1.7.12, executed locally on both fixtures and three
controls.

### Compatibility

**The two members are proven to compose, by construction and by a shared
reference.** They are the same action at the same pin, the same credential, the
same preflight relay, the same permission split and the same poster shape; the
only differences are the trigger block, the guard set and the prompt file. The
shared adopter demonstrating the harder half on one repository is
`trailofbits/coop`, which runs the comment-triggered lane against the same action
at the same commit with the same `":read-only"` + `drop-sudo` configuration
(`X01`, `X03`, `X04`). The shared version matrix is one row:
`openai/codex-action@v1.12` (`86365089eb2b84e0a8fb0717b304f8bdcb13b20e`) ×
`@openai/codex@0.154.0` × `@openai/codex-responses-api-proxy@0.154.0` ×
`ubuntu-latest` × `actions/checkout@v5`. **That row was not executed here** — no
lane was run — and it is the subject of acceptance criteria B1 and B9.

**One compatibility fact inside the stack that neither raw report checked, and it
is load-bearing for the pin.** The single `codex-version` input pins **two** npm
packages, `@openai/codex` and `@openai/codex-responses-api-proxy` (`P01`, `P02`).
A version published for one but not the other would make the action's second
`npm install -g` fail. Parity was verified: both are at `0.154.0`, and the proxy
genuinely publishes that version (`P05`, `P06`). This is why re-verification
trigger (g) exists.

**Do these two lanes coexist with R18's Claude lanes on one pull request?** On
**trigger collision, yes, with no collision**, and the evidence is the guard text
itself, checked rather than asserted: R18's assistant fires on
`contains(github.event.comment.body, '@claude')`; this lane fires on
`startsWith(github.event.comment.body, '/codex')`, and no configuration line of
the fixture names `@claude` at all (`FA19`). A comment cannot both begin with
`/codex` and contain `@claude` unless it deliberately contains both, in which case
both lanes firing is the author's explicit request. The review lanes share no
trigger surface beyond the `pull_request` event itself, which fires both
workflows independently by design. **Not verified at runtime** — no repository was
configured with both.

**On duplicated comment volume, the honest answer is that both lanes will comment,
and that this is a real, measured cost.** The best evidence found is
`supabase/cli`, the only surveyed project running both vendors on one pull
request. Its design document states the problem in its own words: the pipeline
exists instead of the churn of the Codex GitHub App's automatic per-push reviews,
"which re-reviewed a PR 30-40 times as commits landed" (`X07`), "burning reviewer
attention on" churn rather than substance (`X08`). Their response was **not** to
pick one vendor: it was to run both in parallel read-only jobs and add a third job
that adjudicates, merging duplicates and tagging each finding
`sources: claude | codex | both`, then posting one consolidated review. **That
tagging is itself the evidence that the two vendors' findings overlap
materially** — a `both` bucket would be empty otherwise — and equally that they
are distinguishable, since `claude`-only and `codex`-only buckets exist.

**The limits of that evidence, stated rather than dressed up.** It is one
project's design document, not a controlled study. It measures the **hosted
connector's per-push** review, not two workflow-file reviewers on the trigger list
this decision recommends. No figure for comments-per-pull-request with one
reviewer versus two, no duplicate-finding rate and no review-fatigue measurement
was found in any source, and none is asserted here. A population-scale figure
that appeared in one raw report was **not carried**, for the reason that report
itself gave: fetching the paper did not confirm the figure described the
single-versus-multiple comparison.

**Should one lane be scoped to a narrower trigger than the other? Yes, and the
recommended configuration already is.** The Codex review lane is scoped to
`opened, ready_for_review, reopened` and **not** to `synchronize` (`FR20`) —
which is exactly the per-push re-review that produced those 30-40 rounds. That
scoping is mirrored from R18's trigger list rather than invented here, and
`X07` is the independent confirmation that it is the right list. **This is also
the disagreement settled against the `doxa-openai` leg**, which recommended
adding `synchronize`.

**Does the answer differ for a public template repository that downstream
consumers fork? Yes, in one direction that matters and is specific to this
vendor.** An adopter who forks the template **and** enables Codex cloud code
review gets **three** reviewers on every pull request: this template's Codex lane,
R18's Claude lane, and the hosted connector reviewing on every push. Two of the
three are files the adopter can delete; **the third is not in the tree and cannot
be deleted from it.** `supabase/cli` had to state this as an operating
instruction rather than enforce it (`X10`). **Recommendation to R45, not a
decision this item may take:** that interaction belongs in whatever documentation
R45 produces, because R45 must name whichever bots are actually configured and
the connector is one an adopter may well have configured.

### Parameters

`owns —` — R86's `## Couplings` block lists no owned parameter, and this decision
creates none. The four assumed values are in `## Parameters` below, byte-identical
to `docs/port/PARAMETERS.md`. **No `CONFLICT:` line is emitted:** R86's
`consumes:` line is empty, so there is no consumed parameter whose value this
recommendation could need changed, and none of the four owner-fixed values is
challenged. Neither lane compiles anything, so `rust-edition` and `msrv-policy`
do not bind them; both run on `ubuntu-latest`, which is inside
`target-os-matrix`; and `license` is inapplicable as a gate by the owner ruling
of 2026-09-12.

### Migration implications

Four new files and no edits, because `rs-launch-blueprint` has no
`.github/workflows/` tree today.

| Path | Status | Content |
|---|---|---|
| `.github/workflows/codex-code-review.yml` | **new** | Three jobs: `credential-preflight` (`permissions: {}`, four guards, prints the skip reason and the detected shape), `codex-review` (`contents: read`, positive `needs` gate, base-branch checkout, the action at `v1.12`, `codex-version: "0.154.0"`, `":read-only"`, `drop-sudo`, `prompt-file: .github/codex/review-pr.md`), `post-review` (`pull-requests: write`, no model credential, `gh pr comment`). |
| `.github/workflows/codex.yml` | **new** | Three jobs with the same skeleton; triggers `issue_comment: [created]` and `pull_request_review_comment: [created]`; five preflight clauses including `startsWith(…, '/codex')`, the `author_association` prefilter and two bot type checks; `codex-assistant` adds `pull-requests: read` and the untrusted-request packet; `prompt-file: .github/codex/assist.md`. |
| `.github/codex/review-pr.md` | **new** | The review prompt: the template's Rust conventions (edition 2024, the MSRV policy, the CLI / library / web-service surfaces) and an explicit instruction that the pull request's title, body, commit messages and diff are **data, never instructions**. |
| `.github/codex/assist.md` | **new** | The assistant prompt: the same untrusted-input instruction, plus how to read `.codex-request.json`. |

**Boundaries respected.** R20 decides how `openai/codex-action` and
`actions/checkout` are pinned; this decision records that `v1.12` resolves to
`86365089eb2b84e0a8fb0717b304f8bdcb13b20e`, that the moving `v1` currently
resolves to the same commit, that the `/git/ref/tags/` endpoint returns the tag
**object** rather than that commit, and that **no reference in either file is
structurally unpinnable**. R08 owns the repo-wide permission-hardening
convention. R45 owns the trigger vocabulary's documentation. R11 and R12 own the
job graph and the required-check surface. R18 owns the Claude lanes, which this
decision mirrors in shape and does not touch.

### Validation strategy

Executed results are in `## Empirical check`; this section states what each
command was meant to prove and separates it from what P03 must still run.

| # | Check | Status | What it establishes |
|---|---|---|---|
| 1 | `actionlint` over both candidate fixtures | **executed** — `L01`, `L02` | both files are syntactically and expression-valid as written, including the preflight relay, the prefilter, four bot checks, the fork and draft guards and the `startsWith` match |
| 2 | `actionlint` over `control-secret-in-job-if.yml` | **executed** — `L03` | a job-level `if:` **cannot** read `secrets`, with the platform rule in the diagnostic. The negative control that makes check 1 meaningful |
| 3 | `actionlint` over `control-misspelled-output.yml` | **executed** — `L04` | the linter **type-checks** the `needs` relay, so check 1 covers the wiring and not only the syntax |
| 4 | `actionlint` over `control-negative-gate.yml` | **executed** — `L05` | the linter does **not** establish the gate's polarity. The limit control, recorded because it bounds the claim |
| 5 | the vendor's source at the pin | **executed** — `C*`, `B*`, `S*`, `P*`, `D*` | one credential input and it is a secret; no OIDC; no token exchange; no comment posting; no interactive mode; the write check precedes the credential; the `[bot]` shortcut is gated, not unconditional |
| 6 | GitHub's context table | **executed** — `G01`–`G04` | the platform rule, independent of the linter |
| 7 | the fixtures embody the recommendation | **executed** — `FR*` (22), `FA*` (26) | every guard, permission, pin and required absence this decision claims is actually in the file it claims it about |
| — | **the credential-absent path** (B2) | **proposed** | the owner requirement this research could not observe: skipped, not failed, with the key named |
| — | the credential-present path (B1), bot rejection (B4), author trust (B5), the `MEMBER`-without-write window (B6), the self-reply loop (B7), permission minimality (B8), the CLI pin in the log (B9), the draft path (B10) | **proposed** | the runtime behaviour of the design |
| — | pin drift | **proposed** | `gh api repos/openai/codex-action/git/ref/tags/v1.12 --jq '.object.sha'` then dereference; expect commit `86365089eb2b84e0a8fb0717b304f8bdcb13b20e` |

### Confidence & re-verify trigger

Confidence is stated per member above and is not restated. The item-level
summary: **high** on every fact read from the vendor's source at the pin and from
the named endpoints, each of which is asserted by a check that fails if the value
moves; **high** that the preflight gate is required rather than preferred, since
this vendor offers no variable-based credential path at all; **medium** that an
unconfigured clone yields `skipped` rather than `failure`, which is documented
platform behaviour and unobserved here; **medium** on the trigger-token collision,
which is documented and untested; and **low** on cost and on template-specific
false-trigger behaviour, where no measurement and no adopter report were found and
the gaps are reported rather than filled.

### Sources

Every endpoint is listed under the two members' `##### Sources`, retrieved
**2026-09-17 (UTC)** and snapshotted under `review/evidence/snapshots/`. The
binaries that produced every count and check are named in `## Empirical check`
beside their versions. The raw reports this synthesis read are listed with their
sha256 digests in `## Engines`.

re-verify: 2026-12-17, or earlier on any trigger (a) through (j) listed under the members

## Parameters

- owns — **none**. R86's `## Couplings` block has an empty `owns:` line and `research/CLAUDE.md` records R86's `owns` column as `—`, so this item contributes no row to `docs/port/PARAMETERS.md`.
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- No `CONFLICT:` line is emitted. R86's `## Couplings` block lists an empty `consumes:`, so there is no consumed parameter whose value this recommendation could need changed, and none of the four owner-fixed values above is challenged.

**How each assumed parameter bears on this decision.** The four lines above carry
the registry value and nothing else, because the packaging validator reads
everything after `= ` as the value and compares it byte-for-byte with
`docs/port/PARAMETERS.md`. The engagement notes therefore sit here rather than on
those lines.

- `msrv-policy` is **not engaged**: neither member adds a crate to the dependency tree, so no minimum supported Rust version is constrained by anything recommended here. The action's own runtime is Node.js 24, installed by the action itself.
- `rust-edition` is **not engaged** by the workflow files themselves; it is engaged by the two prompt files P03 authors, which state the template's conventions to the reviewer, and `2024` is the value they must state.
- `target-os-matrix` is **engaged only in the negative**: both members are deliberately single non-matrix jobs on one Linux runner and do not join the OS matrix, because the reviewed artifact is a diff rather than a build. The mechanism would support `macos-latest` — "Linux/macOS: All options for `safety-strategy` are supported" — so this is a cost choice, not a capability limit.
- `license` is **inapplicable as a gate** by the owner ruling of 2026-09-12 (Q7.B), and satisfied anyway as metadata: the action's own tree and both npm packages are `Apache-2.0`.

## Empirical check

**Working directory** for every command:
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R86/2026-09-17T033528Z-db9e2a74f9a0/review/evidence`,
except the clean-extraction rerun, whose working directory is the same relative
path inside a throwaway `git archive HEAD` extraction under `$TMPDIR` that was
created and deleted by the command that used it. The `actionlint` invocations run
inside a `mktemp -d` scratch directory the script creates and removes on exit,
because `actionlint` applies its workflow rules by path.

**Toolchain and OS**, as printed in the header of `review/evidence/check.log`:

```
rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)
uname -srm            Darwin 25.4.0 arm64
/usr/bin/grep         grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
actionlint            /opt/homebrew/bin/actionlint version 1.7.12
python3               Python 3.14.7
gh                    gh version 2.98.0 (2026-08-20)     [used by fetch.sh only]
shellcheck            0.11.0                              [pre-commit gate]
```

`rustc` and `cargo` are recorded because the role contract asks for them. **They
are not used by any check in this item**: nothing here compiles Rust, because the
artifact under decision is workflow configuration.

**The commands.**

```
$ ./fetch.sh                       # once, 2026-09-17; writes snapshots/ and fetched-at.txt
$ ./check.sh > check.log 2>&1      # exit 0
$ ./check.sh > check-rerun.log 2>&1 && diff check.log check-rerun.log
$ git archive HEAD | tar -x -C "$W" && (cd "$W/.../review/evidence" && ./check.sh)
$ shellcheck check.sh fetch.sh     # clean, no output
```

**Observed result — `check.log`, last line:**

```
passed=173 failures=0 skipped=0 total=173
```

173 PASS, **0 FAIL, 0 SKIP**, summed by the script and exiting 0. The counts by
group: `V` 17 (the action's identity, version and cadence), `M` 10 (the
Marketplace finding), `C` 10 (the credential), `G` 4 (the context rule), `B` 10
(bots and actor trust), `S` 10 (step order and capabilities), `P` 10 (the CLI
pin), `A` 14 (advisories and maintenance), `D` 12 (the vendor's security
guidance), `X` 16 (adopter practice), `L` 5 (`actionlint` and its three
controls), `FR` 22 and `FA` 26 (the two fixtures embody the recommendation),
`N` 7 (this run's engine record).

**Reproduction, stated as measured rather than asserted.** `check.sh` was re-run
in place immediately before the decision was written and its output is
**byte-identical** to `check.log` (`diff` reported no differences). It was then
re-run from a clean `git archive HEAD` extraction, after the evidence directory
was committed. That run also reported `passed=173 failures=0 skipped=0
total=173` with exit 0, and its complete output is committed as
`check-archive.log`. **Exactly one line differs** between `check.log` and
`check-archive.log`, and it is line 2, `evidence dir:`, which names the
extraction root. **That is the comparison rule**: `check-archive.log` and
`check.log` are identical except for line 2. No SKIP was emitted in either run,
so no check is named as skipped.

**Why the checks read snapshots rather than the live endpoints, stated as a
limitation rather than a convenience.** Every live source this decision cites is
volatile — `stargazers_count` and `pushed_at` move, issue counts move, and
`docs.github.com` and the Marketplace re-template their rendered HTML. A check
that hit them live could not be re-run byte-identically, and the role contract
requires that it can. `fetch.sh` therefore performed one pass on 2026-09-17
(`snapshots/fetched-at.txt`: `Thu Sep 17 22:51:43 UTC 2026`) and committed what
it received; `check.sh` asserts against those bytes. **The cost is explicit: a
figure that has moved since will not be caught until `fetch.sh` is re-run**, at
which point the moved figure surfaces as a FAIL, which is the intended behaviour.
Two snapshots are **pruned** rather than whole, and the pruning is named in both
scripts' headers: the two npm registry documents carry `versions` maps of several
thousand entries, 17 MB between them, so the committed `*.pruned.json` keep the
documents' own `name`, `license` and `dist-tags` unaltered, their `time` entries
for `created`, `modified` and the seven versions this decision cites, and
`versions` restricted to those same seven. **No value is rewritten**; entries this
decision does not cite are dropped.

**The `actionlint` results in full, because they are the item's central executed
evidence.** Binary `/opt/homebrew/bin/actionlint`, version `1.7.12`.

```
candidate-codex-code-review.yml   exit=0, 0 diagnostics
candidate-codex.yml               exit=0, 0 diagnostics

control-secret-in-job-if.yml      exit=1
  .github/workflows/control-secret-in-job-if.yml:11:9: context "secrets" is not
  allowed here. available contexts are "github", "inputs", "needs", "vars". see
  https://docs.github.com/en/actions/learn-github-actions/contexts#context-availability
  for more details [expression]

control-misspelled-output.yml     exit=1
  .github/workflows/control-misspelled-output.yml:22:9: property "credentail" is
  not defined in object type {credential: string} [expression]

control-negative-gate.yml         exit=0, 0 diagnostics
```

**Exactly four things follow, and only these four.** **First**, the owner's
credential-presence requirement **cannot** be expressed as a job-level condition
for `OPENAI_API_KEY`, because it is a secret and `secrets` is not available in
`jobs.<job_id>.if` — established twice over, by GitHub's own table and by the
linter. **Second**, both candidate files are syntactically and expression-valid as
written. **Third**, the linter type-checks the `needs` relay, so the second point
is a statement about the wiring and not only the syntax. **Fourth**, the negative
gate form *also* lints clean, so **the linter does not establish that the positive
gate is the correct one**; that argument rests on the empty-output semantics of a
skipped dependency, which is documented platform behaviour and was not observed
here. **Nothing about runtime behaviour follows from any of it.**

**Validator runs.**

```
$ uv run --offline --no-project --no-python-downloads --no-cache python3 -c \
    'from research_validation import validate_answer_text; ...'    # kind "bundle"
(no diagnostics)

$ bash scripts/check-research-tree.sh .
```

The answer-shape validator reports **no diagnostics**: the ten H3 fields appear
in the order `BUNDLE_FIELDS` requires, each member inside the `### Members`
window carries the fifteen `#####` crate fields in order, and **no `#####`
heading appears anywhere outside that window**. The two `## Supersedes`-free H2s
beyond the role contract's four are not present: this document carries exactly
`## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, and
revision 1 carries no `## Supersedes`. `bash scripts/check-research-tree.sh .` exits **0** and
prints `OK: research tree structure valid`.

**What was deliberately NOT done, because the role contract forbids it.** No
workflow was installed in any repository, no run was triggered, no credential was
configured, no comment was posted, and no `OPENAI_API_KEY` exists anywhere in
this run. The five `.yml` files under `review/evidence/` are **fixtures given to
a linter**, not a template scaffold: they are the minimum input a check needs.
Every claim about what happens when a lane actually runs is recorded as an
acceptance criterion for P03, never as a result.

## Engines

- **opus** `raw/opus.md` — registered as `raw/opus-7122daa4e1279754f6ed5508274f9a6afb5a7369eab7c8e6171daafdd11ca94d.md`. Complete against the answer template: both members, all fifteen fields each, with its own executed `actionlint` run.
- **doxa** `raw/doxa.md` — the three-provider report, operation `research-20260917-081418-d364fa415a4a4224` (`N06`), submitted 2026-09-17 15:14Z, all three providers completed. Normalized twins: `raw/doxa.normalized.md` (the merged bundle twin, the one that **passes** the shape check, `N05`), and the per-provider `raw/doxa-openai.normalized.md` (`gpt-5.6-sol`), `raw/doxa-gemini.normalized.md` (`deep-research-preview-04-2026`) and `raw/doxa-perplexity.normalized.md` (`sonar-deep-research`).
- **codex** — **absent, and this is the controller's deferral rather than a failed engine.** Owner ruling **W1-CODEX**, recorded at `docs/planning/p02/owner-decisions.md` §12 (2026-09-16): "Let's skip codex for now". Under that ruling both Codex runners stay stopped, Codex research legs and empirical audits are deferred, and Opus legs, syntheses, Doxa and acceptance asks continue. No Codex report was requested, none was attempted, and none failed. Check `N07` asserts that no `raw/codex.md` exists in this run, so the absence is recorded rather than assumed. **The consequence for this item is stated rather than glossed**: the prompt's tier policy specifies three engines for a Deep item, and this synthesis had two. The independent second lens a different model family would have supplied is missing, and the empirical audit this item still needs is itself deferred under the same ruling, so **this decision must not publish without it.**

**sha256 of every raw report this synthesis read**, printed by `check.sh` into
`check.log` (group `N`):

```
SHA256 raw/opus.md                        7122daa4e1279754f6ed5508274f9a6afb5a7369eab7c8e6171daafdd11ca94d
SHA256 raw/doxa.md                        0763bafe2c1637777f8e38a4d378e5a53f35b49c459080031108d3da10ee9c44
SHA256 raw/doxa.normalized.md             273f1246618f949e60c9d7c87d4f023edbc50649963ae700403ea28ea554c138
SHA256 raw/doxa-openai.normalized.md      a9f95dc1738265b37a6b914459adc783d7334f18884a0c0f06e29e5c18ba2df7
SHA256 raw/doxa-perplexity.normalized.md  35483d2094f54725b5ed984c020adecc0d828f8cc39b6629366334491337270b
SHA256 raw/doxa-gemini.normalized.md      ef692132a2b5c49cc57d624dbd42f3803dfd518d9a9120ca917c41d43f91a717
```

`raw/opus.md`'s digest is the run's registered filename,
`raw/opus-7122daa4e1279754f6ed5508274f9a6afb5a7369eab7c8e6171daafdd11ca94d.md`,
and `raw/doxa.md`'s is `raw/doxa-0763bafe2c1637777f8e38a4d378e5a53f35b49c459080031108d3da10ee9c44.md`,
so each digest is checkable against the name the run recorded as well as against
the bytes. The digests are printed rather than asserted, because an assertion on
a digest would only restate that the file is present and unchanged, which the
run's own manifest already records.

**Known Doxa limits, stated rather than repaired.** The perplexity twin **fails
its own per-provider shape check** (`N01`): five top-level fields are absent —
`Compatibility`, `Parameters`, `Migration implications`, `Validation strategy`
and `Confidence & re-verify trigger` (`N02`); its F361 member carries all fifteen
crate fields but **not in the order the validator requires**, because its
headings use non-breaking hyphens (`Up‑and‑comers`, `Confidence & re‑verify
trigger`) that do not match the expected strings byte-for-byte; and its **F362
member stops after five fields** — `Landscape`, `Principles and implementation`,
`Dominant choice`, `Qualified shortlist`, `Excluded by gate` — with
`finish_reason` `stop`, meaning the model ended early (`N04`). Both perplexity
members were consequently **demoted to bold text** by the merge (`N03`), so
neither survives as a member of the merged bundle twin. **Its F362 material is
therefore treated as incomplete and weighed accordingly throughout**: where a
perplexity claim about the assistant lane is settled against below, the
settlement rests on executed evidence and the incompleteness is an additional
reason not to rely on it, never the reason on its own.

**Disagreements between the engines, and the evidence that settled each.** Every
settlement below is an executed check in `check.log`, not a vote.

1. **The action's coordinate and version.** `opus` named `v1.12` at commit
   `86365089eb2b84e0a8fb0717b304f8bdcb13b20e`; `doxa-openai` named `v1.12` but
   gave the coordinate as `openai/codex-action@v1`; `doxa-perplexity` gave only
   `openai/codex-action@v1`, "assuming the latest v1 release"; `doxa-gemini`
   named the action with no resolved version. **Settled by re-derivation** (`V07`
   through `V15`): the project publishes **no GitHub Releases**, so a "latest
   release" cannot be read from the releases endpoint at all — it returns an
   empty array. `v1.12` is the current stable tag, annotated, dereferencing to
   commit `86365089eb2b84e0a8fb0717b304f8bdcb13b20e`, tagged 2026-08-20T23:40:26Z;
   `v1` is a separate moving tag dereferencing to the same commit at retrieval.
   **A refinement none of the four legs made and which would produce a broken
   pin**: `/git/ref/tags/v1.12` returns the **tag object** sha
   `cac08775a978ba35a8174558cd9fabab2c09670c`, not the commit.
2. **The Codex CLI version.** `opus` said `0.154.0`. `doxa-openai` said the
   current CLI release "could not be reliably resolved from the official release
   endpoint in this run" and named `0.150.1` as the highest version it could see,
   in an open hang report. **Settled against `doxa-openai`** (`P03`, `P04`):
   `dist-tags.latest` is `0.154.0`, published 2026-09-09T22:40:10.746Z. The leg's
   underlying warning — that leaving `codex-version` blank means "latest" even
   when the action is pinned — is **correct and adopted**, and issue `#171`
   evidences it (`P08`, `P09`). **A fact neither engine checked**: the same input
   pins the Responses-API proxy package too, and parity at `0.154.0` was verified
   (`P02`, `P05`, `P06`).
3. **The credential paths.** `doxa-perplexity` reported two — `OPENAI_API_KEY`
   "or `AZURE_OPENAI_API_KEY` for Azure-hosted models" — and recommended
   configuring the secret as an **environment** secret on a GitHub environment
   for extra gatekeeping. **Settled against it** (`C01`–`C05`): `action.yml`
   declares exactly **one** credential input, `openai-api-key`; there is no
   `azure-openai-api-key` input and the string `AZURE_OPENAI_API_KEY` appears
   nowhere. Azure is reached by overriding `responses-api-endpoint` while
   supplying the same key input. The environment-secret suggestion is not adopted
   for a separate reason: an environment with required reviewers turns a skipped
   lane into a **pending** one, which is not "does not run, does not error".
4. **Whether `actionlint` was run.** `doxa-perplexity` states plainly: "R86 did
   not re-run `actionlint`, but it relies on GitHub's documented table and R18's
   executed checks." **This synthesis re-ran it** (`L01`–`L05`) with three
   controls, two of which are new to this item: the misspelled-output control
   that shows the linter type-checks the relay, and the negative-gate control that
   shows it does **not** establish the gate's polarity. The second is a limit on
   the evidence, and it is recorded because relying on R18's run would have hidden
   it.
5. **The review lane's trigger list.** `doxa-openai` recommended adding
   `synchronize`. **Settled against it** on cited evidence (`X07`, `X08`,
   `FR20`): automatic per-push review is precisely what produced 30-40 review
   rounds on one pull request at `supabase/cli`, at a cost that project describes
   as reviewer attention. The recommended list mirrors R18's.
6. **The assistant lane's event list.** `doxa-openai` added
   `pull_request_review: submitted`. **Settled against it on the mechanism**: that
   event carries no comment body, so neither the `startsWith` command match nor
   the `comment.author_association` prefilter has a field to bind; it would widen
   the attack surface while weakening the guard. R18's Claude lane carries four
   events because that action's interactive mode listens on four; this action has
   **no interactive mode** (`S03`, `S04`), so the reason does not transfer.
7. **Per-lane permissions.** `doxa-perplexity` put `contents: read` **and**
   `pull-requests: write` on the review job, and `contents: write` on the
   assistant "if the lane is configured to apply edits … as in Codex Code Review &
   Actor's 'Act' mode". **Settled against it, and the source of the error is
   identifiable** (`S05`, `S06`, `S10`, `M08`): the action contains **no**
   comment-posting call anywhere in a source tree of eight files, so
   `pull-requests: write` on the model job grants a capability the action cannot
   use while placing write next to the credential; and "Codex Code Review &
   Actor" is **`gersmann/codex-review-action`, a third-party Marketplace
   listing**, not this vendor. That leg drew its permission model and its "Act
   mode" from a different product.
8. **The `[bot]` actor question.** `doxa-perplexity` asserted that "OpenAI's
   Codex action documentation does not publish any special treatment of `[bot]`
   logins, unlike the finding R18 reported for Claude". **Half-right in
   conclusion, wrong in method, and settled in source** (`B02`–`B06`): special
   treatment **does** exist — `isBotActor` is an `endsWith("[bot]")` test and
   there is a shortcut approval — but it is gated on `allow-bots` (default
   `false`) **and** on a one-login trusted set, so it is not the unconditional
   approval R18 found. The leg reached a safe conclusion from documentation where
   the source says something more specific, and the specifics matter: the
   fallthrough is a **write-permission** test that a write-holding bot passes, and
   it inspects `GITHUB_ACTOR` rather than the comment author, which is why the
   workflow's type checks are load-bearing for two independent reasons rather
   than one.
9. **The stack's membership.** `doxa-gemini` proposed a **four-member** stack:
   the action, two workflow files, and **`AGENTS.md`**. **Rejected**: this
   bundle's members are the two ledger rows `F361` and `F362`, and `AGENTS.md`'s
   content and placement are `F197`'s. The underlying observation — that the CLI
   loads `AGENTS.md` from its working directory — is **correct, adopted, and
   evidenced** (`D03`), but it constrains this decision's *checkout* rather than
   adding a member. `doxa-gemini`'s members are also the thinnest of the four
   legs, several fields running to a sentence, and it is weighted accordingly.
10. **The model.** `doxa-openai` specified `gpt-5.5` at medium effort "pending
    availability verification at integration time". The action does expose `model`
    and `effort` inputs, read in `action.yml`. **This decision sets neither**, and
    the reason is an evidence gap stated rather than filled: **no model catalogue
    was retrieved in this run**, so the string `gpt-5.5` is unverified here. P03
    may pin a model after verifying it; leaving both unset takes the CLI's own
    default.
11. **The prompt source.** `doxa-openai` recommended "inline trusted workflow
    text; no remote plugin and **no PR-checkout prompt file**". **Partly adopted,
    partly settled against.** Its concern is correct and is the vendor's own
    (`D03`): a prompt file read out of a **pull-request** checkout is
    attacker-controlled. But this decision's checkout is of the **base** or
    **default** branch (`FR21`), so a template-local `prompt-file:` is trusted
    content — and it is what the vendor's own reference and `trailofbits/coop`
    both use. **The R18 clause mirrored here is its revision-4 finding**, which
    removed the unpinnable marketplace fetch and replaced it with a
    template-local command file, at a cost R18 states and this decision inherits:
    the template owner authors and maintains the review prompt.
12. **The two-vendor question.** All four legs called the pair complementary.
    `doxa-perplexity` supported that with a qualitative pattern and no measured
    figure. **The settlement keeps the conclusion but changes its basis**: the
    only measured evidence found is `supabase/cli`'s, and it measures the
    **hosted connector's per-push** review rather than two workflow reviewers on
    this trigger list. Its `sources: claude | codex | both` tagging is the
    overlap evidence. **No figure for comments-per-pull-request with one reviewer
    versus two, no duplicate-finding rate and no fatigue measurement exists in any
    source consulted**, and none is asserted. A population-scale figure that
    appeared in one raw report is explicitly **not carried**.

**What is carried rather than re-derived, named so an auditor can tell them
apart.** Four things: the ten-most-recent-issues responsiveness sweep (0 of 10
answered by a maintainer); the `openai/codex` and `Expensify/App` workflow
readings; the code-search population figure of 181 public workflows combining the
action with `issue_comment`; and the confirmation that neither `py` nor `ts` at
their pinned commits carries any Codex or OpenAI workflow. Each is from
`raw/opus.md`. Everything else in this decision is asserted by a check in
`check.log`.

**What P03 must validate, listed once.** Acceptance criteria **B1 through B10**
under `### Principles and implementation`. Three of them carry the weight: **B2**,
the credential-absent path, which is the owner requirement this research could
not observe and whose failure would make the runner-up win outright; **B4**, bot
rejection, which must assert the **model job's** conclusion rather than the
preflight's, because asserting the preflight passes whether or not the model job
ran; and **B6**, the `MEMBER`-without-write window, where the owner's chosen guard
and the vendor's unremovable internal check genuinely disagree and P03 must
choose among three options with a fourth ruled out.

**Where evidence is incomplete, stated plainly.** No lane was run, so every
runtime claim is an acceptance criterion. Skip propagation is documented and
unobserved. The trigger-token collision with the hosted connector is documented
and untested. Cost is unmeasured. Template-specific false-trigger behaviour has
no adopter report. The `issues: write` versus `pull-requests: write` minimality
question for `gh pr comment` is unsettled. And the Codex engine leg that would
have supplied an independent second lens is deferred under W1-CODEX, as is this
item's empirical audit — so this decision is complete as research and **not ready
to publish**.
