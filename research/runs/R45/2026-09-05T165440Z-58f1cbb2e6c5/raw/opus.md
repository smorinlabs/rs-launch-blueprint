# R45 — pr-comment-bot-trigger-block (pattern, Focused) — Opus raw report

All retrieval dates are **2026-09-10** unless stated otherwise. Source repositories were read
through their programme pins: `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`
(`git -C ~/c/py-launch-blueprint show b08bccfb:<path>`), `ts-launch-blueprint` at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`. Both are private and return HTTP 404 from the network,
so no public URL is offered for their file contents.

### Landscape

**The category this item decides.** Not a library choice and not a workflow: it decides *where a
repository documents the act of asking an automated reviewer to look again*, and *whether that
documentation is inlined as literal command text or linked to its owner*. The artifact under
decision is Markdown inside `.github/pull_request_template.md`, whose contents GitHub inserts into
the **body of every new pull request** — "When you add a pull request template to your repository,
project contributors will automatically see the template's contents in the pull request body"
(<https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository>).
That mechanism fact is load-bearing throughout: the PR template is a **pull-request-description**
surface, whereas every re-review command under discussion is a **pull-request-comment** surface.
py bridges the two with an instruction to copy and paste.

**Three-bin map of the field.** Every candidate in `### Options` comes from this map.

*Bin 1 — built-in or first-party toolchain (GitHub-native and Rust-project-native mechanisms).*
- **Native re-request-review control.** GitHub's own AI reviewer uses it rather than ChatOps: "To
  manually request a re-review from Copilot, click the [Re-request review] button next to Copilot's
  name in the **Reviewers** menu", and repositories may enable a **Review new pushes** ruleset option
  to "automatically request re-reviews from Copilot on every push"
  (<https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review>).
  There is no command string to document, therefore nothing to go stale.
- **PR-description directives parsed by a bot.** The Rust project's own template carries
  `r? <reviewer name>` and `homu-ignore:start` / `homu-ignore:end` markers
  (<https://raw.githubusercontent.com/rust-lang/rust/main/.github/pull_request_template.md>);
  `rust-clippy`'s carries `changelog:` and `fixes #issue_number`
  (<https://raw.githubusercontent.com/rust-lang/rust-clippy/master/.github/PULL_REQUEST_TEMPLATE.md>).
  These are directives the bot reads *out of the description GitHub just created*, which is why they
  belong in a description template. Neither project puts a copy-paste-this-comment block there.
- **Contributor-guide hosting.** GitHub surfaces `CONTRIBUTING.md` to a contributor at the moment of
  opening a pull request — the documentation states that when someone opens a pull request or creates
  an issue "they will see a link to that file", and the file also appears as a Contributing tab and a
  sidebar link
  (<https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors>).
  The Rust project uses exactly this: `@rustbot` comment commands are documented in the
  rustc-dev-guide (<https://rustc-dev-guide.rust-lang.org/rustbot.html>), which defers to
  <https://forge.rust-lang.org/triagebot/shortcuts.html> — a contributor guide, not a PR template.
- **Saved replies.** GitHub's native answer to retyping the same comment; personal-account scoped
  ("Saved replies are tied to your personal account"), capped at 100
  (<https://docs.github.com/en/get-started/writing-on-github/working-with-saved-replies/about-saved-replies>).
  Useful to a maintainer, unavailable as a repository-shipped artifact — which is why it cannot
  replace documentation for a *template*.

*Bin 2 — established industry standard.* A PR template confined to intent, testing, breaking changes
and a checklist, with bot mechanics documented elsewhere or not at all. This is what the surveyed
mainstream Rust projects do, without exception (evidence below).

*Bin 3 — up-and-comer.* Inlining AI-review-vendor comment ChatOps into the PR template — py's F204
pattern, first committed 2026-06-21 (`git log -S'Review Trigger' -- .github/pull_request_template.md`
at the pin: `47edb56 2026-06-21 ci: add greptile and cubic pr review bots alongside coderabbit`).
Adjacent and newer: vendor-side re-trigger affordances that remove the need for a command at all —
Greptile shipped one and dated it, "**Re-trigger button** — Click 'Re-trigger Greptile' in the footer
to re-run a review without tagging @greptileai", under a changelog entry labeled *March 25, 2026*
(<https://www.greptile.com/docs/llms-full.txt>); and agent-driven re-review loops such as
`greptileai/skills` "greploop" (<https://github.com/greptileai/skills>).

**Authority, and why each source counts.**
- *Maintainers' own command references* — the only authority for a command's current syntax, because
  the vendor implements the parser: CodeRabbit's
  <https://docs.coderabbit.ai/reference/review-commands>, Greptile's published docs corpus
  <https://www.greptile.com/docs/llms-full.txt>, cubic's <https://docs.cubic.dev/llms-full.txt>,
  and `anthropics/claude-code-action` `docs/usage.md`
  (<https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md>).
- *GitHub's own product documentation* — authoritative for the platform mechanism the pattern runs
  on (what a PR template is, where CONTRIBUTING.md is surfaced, how re-request-review works).
- *The Rust project's own publications* — `rust-lang/rust`'s and `rust-clippy`'s shipped PR
  templates and the rustc-dev-guide are the Rust ecosystem's normative practice for how a Rust
  repository talks to its bots, published by the project itself rather than commentary about it.
- *GitHub's account registry* — `https://api.github.com/users/<login>` is authoritative for whether
  a handle a document tells a contributor to type actually exists.
No single blog post is relied on anywhere in this report.

**Practice evidence: what well-regarded Rust projects actually ship.** Twelve repositories, chosen
for standing in the Rust ecosystem and weighted toward newer popular ones (`uv`, `ruff`, `zed`,
`ratatui`). Stars and `pushed_at` from `GET https://api.github.com/repos/<o>/<r>`; `archived` was
`false` for all twelve. PR templates fetched from `raw.githubusercontent.com` at the default branch.
Bot-config presence probed with `GET https://api.github.com/repos/<o>/<r>/contents/<path>` for
`.coderabbit.yaml`, `.coderabbit.yml`, `.greptile/config.json`, `greptile.json`.

| Project | Stars | Last push | Documents an AI-bot re-review comment command in its PR template? | Repo-level AI-review-bot config? |
|---|---|---|---|---|
| zed-industries/zed | 90053 | 2026-09-10 | no | none |
| astral-sh/uv | 89684 | 2026-09-10 | no | none |
| BurntSushi/ripgrep | 68148 | 2026-08-04 | no template found at the four probed paths | none |
| starship/starship | 59846 | 2026-09-10 | no | none |
| astral-sh/ruff | 49573 | 2026-09-10 | no | none |
| bevyengine/bevy | 48125 | 2026-09-09 | no | none |
| nushell/nushell | 40471 | 2026-09-10 | no | none |
| tokio-rs/tokio | 33110 | 2026-09-10 | no | none |
| tokio-rs/axum | 27074 | 2026-09-09 | no | none |
| ratatui/ratatui | 22543 | 2026-09-07 | no (template is one comment line pointing at CONTRIBUTING.md) | none |
| clap-rs/clap | 16697 | 2026-09-09 | no | none |
| rust-lang/cargo | 15462 | 2026-09-08 | no | none |

Two further templates were read for the directive question rather than the count above:
`rust-lang/rust` (117997 stars, pushed 2026-09-10, 11223 open issues) and `rust-lang/rust-clippy`
(13499 stars, pushed 2026-09-09, 2533 open issues), open-issue counts from
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`. Both put **bot-parsed
directives** in the template and **no comment commands**.

**Stated limit of that negative finding.** The absence of `.coderabbit.yaml` or `.greptile/` proves
only the absence of a *repository-level* configuration file. These products can be installed
org-wide with no repo-level config, so the table shows that these projects do not *configure* the
bots in-repo and do not *document* commands, not that no such bot ever comments on their PRs. The
same caveat has a direct bearing on this template: `ts-launch-blueprint` at `cb1cbcb2` ships no bot
config yet its `docs/tools/vs-code.md:20` describes the CodeRabbit editor extension as "matching the
org's CodeRabbit usage on pull requests" — an org-level install invisible to the repository's own
files. A template cannot know which apps a consumer's organization has installed.

### Principles and implementation

**The shared requirement, and the level at which agreement is owed.** The principle both source
repositories are reaching for is: *after a contributor pushes a fix, obtaining a fresh automated
review must be a documented, discoverable act rather than folklore.* The agreement level is
**policy** — specifically a documentation-location policy — not a capability and not an
architectural pattern. What must agree across py, ts and rs is (a) that a re-review path exists and
(b) that it is documented once, in a place the platform surfaces to contributors, and kept true.
What may vary, legitimately and per repository, is (c) the literal command strings, because those are
owned by whichever bots that repository actually configures, and (d) the file the documentation
lives in, because the correct file follows from which surface the command uses.

**Essential behaviors.** (1) A contributor who has pushed a fix can discover how to get another
automated review without reading CI YAML. (2) Nothing the repository ships names a bot the repository
does not configure. (3) Nothing the repository ships pins syntax the repository does not own.

**Observable acceptance criteria.** (A1) Every `@handle` appearing in contributor-facing Markdown
resolves to a bot wired in this repository — mechanically checkable, and checked below. (A2) The
re-review instruction states who may use it, because rs's one comment trigger is author-gated.
(A3) No instruction in the PR template asserts a bot behavior the repository's workflows contradict.

**The decisive constraint, from a sibling item resolved the same day.** R18
(`ai-assisted-review-workflows`, `research/topics/18-ai-assisted-review-workflows/DECISION.md`,
revision 5, 2026-09-10) has resolved, and it removes the ground under a verbatim port of F204:
- It ships exactly two workflows, both from `anthropics/claude-code-action` at `v1.0.220`, and
  **rejects hosted third-party review apps** — the alternatives table records "Hosted third-party
  review app (PR-Agent as a service, CodeRabbit as an app) … Rejected on the same fit ground, plus a
  second vendor relationship" (`DECISION.md:96`). CodeRabbit, Greptile and cubic — all three bots py's
  block names — are therefore **not configured by this template**.
- The one comment-triggered lane is `.github/workflows/claude.yml`, gated on
  `vars.ENABLE_CLAUDE_ASSISTANT == 'true'` **and** a four-clause `contains(…, '@claude')` condition
  **and** `contains(fromJSON('["OWNER","MEMBER","COLLABORATOR"]'), github.event.<…>.author_association)`
  (`DECISION.md:12`). Its trigger phrase is the action's default, `"@claude"`
  (`DECISION.md:148`, corroborated at
  <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md>: the
  `trigger_phrase` input is "The trigger phrase to look for in comments, issue/PR bodies, and issue
  titles", default `@claude`).
- Both lanes **ship inert** and are not to be enabled anywhere until the owner records acceptance;
  if acceptance is withheld, both files are deleted and an opt-in recipe is published instead
  (`DECISION.md`, `## Decision`).

**A consequence that inverts one of this item's own questions.** R18's review lane fires on
`pull_request: types: [opened, ready_for_review, reopened]` — **no `synchronize`**
(`DECISION.md:11`), and R18 states the consequence outright: dropping `synchronize` "removes automatic
re-review after a fix-up push, and the replacement is a write-access user typing `@claude please
re-review`" (`DECISION.md:316`). So for `rs-launch-blueprint` the HIGH question "has
auto-review-on-push made explicit re-trigger documentation redundant?" resolves **the opposite way
from py**: under R18's shape there is no automatic re-review on push at all, and the manual comment is
the *only* re-review path. That argues for documenting the path — and against deleting it silently as
ts did. It also means py's own explanatory sentence, "Bots also auto-review on push", would be
**false** if copied into rs.

**Comparing the architectural alternatives, before any wording.** Three genuinely different designs
exist, and they differ in who owns the string that can go wrong.

| Design | Who owns the string | What breaks it | Who can act on it |
|---|---|---|---|
| Inline vendor commands in the PR template | the vendor | vendor renames a handle or changes syntax; repo swaps bots | anyone who can comment, if the bot is installed |
| Link out from a contributor guide; inline only phrases the template itself sets | the template, for `@claude`; the vendor's own doc page, for everything else | only a change the template made itself | write-access users, for `@claude` |
| Document nothing; rely on automation and native UI | nobody | nothing textual; but the path is undiscoverable | anyone, via the Reviewers menu |

**Measured evidence that inlining drifts — the MEDIUM question, answered with figures.** py's block
was committed 2026-06-21 and read at the pin on 2026-09-10: **81 days**. Checking each of its three
strings against the vendor's current documentation on that date:

| py's inlined string | Vendor's currently documented form | Verdict |
|---|---|---|
| `@coderabbitai review` | "`@coderabbitai review` … Triggers an incremental review of new changes only" (<https://docs.coderabbit.ai/reference/review-commands>) | matches verbatim |
| `@cubic-dev-ai review` | "You can still request a review with `@cubic-dev-ai review`" and "**Full review:** `@cubic-dev-ai` or `@cubic-dev-ai review this PR`" (<https://docs.cubic.dev/llms-full.txt>) | matches; a documented form |
| `@greptile-apps review` | Greptile's docs document `@greptileai` throughout — "Tag Greptile in a GitHub/GitLab comment to trigger a review: `@greptileai`", "**Force trigger:** Comment `@greptileai review this`" (<https://www.greptile.com/docs/llms-full.txt>) | **handle diverges from the vendor's documentation** |

Both handles are real GitHub accounts — `GET https://api.github.com/users/greptile-apps` returns
`greptile-apps`, `type: User` (the App's bot account), and `GET https://api.github.com/users/greptileai`
returns `greptileai`, `type: Organization`; `coderabbitai` (Organization) and `cubic-dev-ai` (User)
also exist. **Whether `@greptile-apps review` still triggers a Greptile review is undocumented; this
is a divergence from the vendor's published handle, not an observed failure.** Note also that
Greptile's docs domain moved: `docs.greptile.com:443` refused connection on 2026-09-10, and the live
corpus is served from `www.greptile.com/docs`. So one string in three drifted from its vendor's
documentation within one quarter, and the documentation's *address* drifted too.

Two further drift observations, both from py itself rather than from any vendor:
- py ships `.github/workflows/claude.yml` at the pin, yet its Review Trigger block names no `@claude`
  command. An inlined block drifts against **its own repository**, not only against vendors.
- CodeRabbit's own reference concedes the handle is environment-dependent: "Examples on this page use
  `@coderabbitai`. If CodeRabbit is installed with a different service-account handle on your
  platform, use that handle instead in PR comments and PR descriptions."
  (<https://docs.coderabbit.ai/reference/review-commands>). A template that inlines a handle asserts
  something about the *consumer's* installation that the template cannot know.

**Why the surface argument settles the LOW question rather than taste.** CodeRabbit's reference draws
the line for us. `@coderabbitai ignore` "must be placed in the PR description, not in comments", and
`@coderabbitai summary` is explicitly "not a command - it's a placeholder that you put in your PR
description". Those two belong in a PR template, because the template *is* the description. A
re-review request is the opposite: it is posted after the description exists, in reply to what the bot
said. Putting comment ChatOps in a description template is a category error that every surveyed Rust
project avoids and that the Rust project itself avoids deliberately — `r?` and `changelog:` are in the
template precisely because they are description-parsed, while `@rustbot` comment commands are in the
rustc-dev-guide. This is the structural rule the recommendation adopts.

**Production usage and maintained reference implementations.** The reference implementation for the
recommended documentation shape is the Rust project's own split: template carries description
directives (<https://raw.githubusercontent.com/rust-lang/rust/main/.github/pull_request_template.md>),
contributor guide carries comment commands (<https://rustc-dev-guide.rust-lang.org/rustbot.html>,
<https://forge.rust-lang.org/triagebot/shortcuts.html>). It is maintained (rust-lang/rust pushed
2026-09-10) and it is the normative Rust-ecosystem practice by construction, being the Rust project's
own. The reference implementation for the one command rs may inline is
`anthropics/claude-code-action` at `v1.0.220` (repository figures: 8835 stars, `archived: false`,
pushed 2026-09-09, 457 open issues — `GET https://api.github.com/repos/anthropics/claude-code-action`
and `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code-action+is:issue+is:open`),
whose `trigger_phrase` default the template itself pins, making it the only string in the whole field
that the template can keep true by its own action. Integration cost for the recommended design is one
Markdown heading and one bullet; representative performance and resource cost are not applicable —
no code runs (see `### Excluded by gate`).

**Maintenance state, by the rubric.** For a documentation-location pattern the rubric applies to the
practice, not to a crate: **active**. It is the shipped, currently-maintained arrangement in
`rust-lang/rust` and `rust-lang/rust-clippy` (both pushed within 24 hours of retrieval, neither
archived), and no maintainer notice, unpatched advisory or broken build exists to consider. The
inlined-block pattern of Bin 3 is **at-risk** on a concrete signal rather than on age: one of its
three strings in py diverged from vendor documentation within 81 days, and two of the three vendors
have since added or documented non-textual re-trigger affordances (Greptile's footer button, dated
March 25 2026; cubic's `ultrareview` and reply-to-comment flows).

**BASELINE-REVIEW.** One finding is ledger-shaped and is routed rather than acted on.

BASELINE-REVIEW: F204 — a PR-template trigger block can only name bots the repository actually configures, so its content is determined by the bot set rather than independent of it — record F204 as content-dependent on F051/F052 (R18) instead of `standalone`, so that a later change to R18's bot set or to the owner's enablement decision re-opens F204 — evidence: py's block names `@coderabbitai`, `@greptile-apps` and `@cubic-dev-ai` (py `.github/pull_request_template.md:90-96` at pin `b08bccfb`), and R18's resolved decision configures none of the three, rejecting hosted third-party review apps (`research/topics/18-ai-assisted-review-workflows/DECISION.md:96`) and shipping both `claude-code-action` lanes inert (same file, `## Decision`). Affected items: R45, R18, and ledger row F204 (`docs/port/COMMONALITY.md:208`, currently annotated `standalone`).

### Dominant choice

The dominant choice has two layers, and collapsing them loses the distinction that decides this item.

1. **In the PR template: no comment-command block.** Zero of the twelve surveyed mainstream Rust
   repositories documents an AI-bot re-review comment command in its PR template, and zero configures
   such a bot at repository level. `ts-launch-blueprint` at `cb1cbcb2` is in the same position.
2. **Where bot commands are documented at all: the contributor guide, not the template.** The Rust
   project — the ecosystem's own normative publisher — documents `@rustbot` comment shortcuts in the
   rustc-dev-guide and on forge.rust-lang.org, while reserving its PR template for directives the bot
   parses out of the description itself (`r?`, `homu-ignore`, `changelog:`).

The dominant choice is therefore **not** "say nothing anywhere". It is: the template carries only what
the description surface owns, and the comment surface is documented next to the rest of the
contribution process.

### Options

Qualified shortlist. Each entry gives name · where it is documented · adopters that practice it ·
date of the most recent authoritative write-up.

- **`contributing-hosted-trigger-reference`** (the recommended pattern; full name: *contributor-guide
  trigger reference, with inlining reserved for trigger phrases the template itself owns*) · a
  "Requesting another review" section in `CONTRIBUTING.md`, which GitHub links from the new-pull-request
  page (<https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors>)
  · adopters: the Rust project (`@rustbot` shortcuts in the rustc-dev-guide and on
  forge.rust-lang.org, with the PR template kept free of comment commands), ratatui (template is a
  single line deferring to `CONTRIBUTING.md`), tokio and axum (templates link the contributors guide
  in their opening comment) · most recent authoritative write-up:
  <https://rustc-dev-guide.rust-lang.org/rustbot.html> and
  <https://forge.rust-lang.org/triagebot/shortcuts.html>, both live and maintained as of 2026-09-10.

- **`pr-template-description-directives-only`** · the PR template itself, restricted to strings a bot
  parses from the pull-request description · adopters: `rust-lang/rust` (`r? <reviewer name>`,
  `homu-ignore:start`/`homu-ignore:end`), `rust-lang/rust-clippy` (`changelog:`, `fixes #issue_number`),
  and CodeRabbit's own documented description-placed forms `@coderabbitai ignore` and
  `@coderabbitai summary` · most recent authoritative write-up:
  <https://raw.githubusercontent.com/rust-lang/rust/main/.github/pull_request_template.md> and
  <https://docs.coderabbit.ai/reference/review-commands>, both retrieved 2026-09-10. This is the rule
  that governs what may remain in the template, and today it admits nothing, because
  `claude-code-action` parses no description directive that a template would seed.

- **`pr-template-inlined-chatops-block`** · the PR template, as a fenced block of literal vendor
  commands with a copy-and-paste instruction · adopters: `py-launch-blueprint` at pin `b08bccfb`
  (`.github/pull_request_template.md:90-96`), committed 2026-06-21; no adopter found among the twelve
  surveyed Rust projects · most recent authoritative write-up: none — no vendor documents its commands
  as PR-template content; CodeRabbit, Greptile and cubic all document them as comment usage
  (<https://docs.coderabbit.ai/reference/review-commands>, <https://www.greptile.com/docs/llms-full.txt>,
  <https://docs.cubic.dev/llms-full.txt>, all 2026-09-10).

- **`no-documented-trigger-anywhere`** · nowhere; the repository relies on automatic review and the
  contributor's own knowledge · adopters: `ts-launch-blueprint` at pin `cb1cbcb2` (no Review Trigger
  section, no bot config), plus all twelve surveyed Rust projects, none of which documents such a
  command in any contributor-facing file examined · most recent authoritative write-up: not
  applicable — this is an absence, evidenced by the templates themselves rather than by advocacy.

- **`native-ui-retrigger`** · no repository file at all; the platform's Reviewers menu and the
  vendor's own review footer · adopters: GitHub Copilot code review, whose documentation directs users
  to "click the [Re-request review] button next to Copilot's name in the **Reviewers** menu"
  (<https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review>);
  Greptile, whose review footer carries a "Re-trigger Greptile" button
  (<https://www.greptile.com/docs/llms-full.txt>, changelog entry labeled March 25, 2026) · most
  recent authoritative write-up: the Greptile changelog entry, March 25, 2026.

### Excluded by gate

**No candidate is excluded by a fitness gate.** All six gates are inapplicable to this item and the
reason is the same for each: the decision produces Markdown prose inside GitHub-side repository
metadata. It adds no crate, no dependency, no code and no build step. Stating each explicitly rather
than omitting it:

1. **License compatible with `MIT OR Apache-2.0`** — `inapplicable`. No third-party artifact is
   vendored. The Markdown authored here is original template content and carries the template's own
   `MIT OR Apache-2.0` licensing by inclusion.
2. **Crate and dependency-tree MSRV within "stable minus 2 minor versions…"** — `inapplicable`. There
   is no crate and no dependency tree; no `rust-version` field is affected.
3. **No open RustSec advisory; `unsafe` posture** — `inapplicable`. No crate exists to have an
   advisory (`https://rustsec.org/packages/<name>.html` has no subject here), and no Rust code, hence
   no `unsafe`. The nearest security-shaped consideration is not a gate but is recorded anyway: this
   item documents a trigger, it does not grant one; the author-trust gate on that trigger is R18's
   `author_association` prefilter (`DECISION.md:12`), not this file's.
4. **Builds and tested on `ubuntu-latest, macos-latest`; Windows noted** — `inapplicable`. Nothing
   builds or executes. The PR template is rendered by GitHub's servers into a pull-request body and is
   identical for every contributor regardless of operating system; Windows is therefore supported in
   the only sense available, and no CI matrix entry is implied.
5. **Default features and async-runtime coupling** — `inapplicable`. No Cargo features and no async
   runtime; the pattern has no configuration surface beyond the text itself.
6. **Binary-size and compile-time cost** — `inapplicable`, and the analogue is exact rather than
   asserted: zero bytes of binary, zero added compile time, because no `cargo` invocation is involved.
   The only cost is the number of lines a contributor reads in a pull-request body, which the
   recommendation reduces by roughly seven lines.

### Up-and-comers

- **Vendor-side re-trigger controls that eliminate the command.** Greptile's "Re-trigger Greptile"
  footer button (changelog entry labeled March 25, 2026, <https://www.greptile.com/docs/llms-full.txt>)
  and GitHub's Copilot **Re-request review** control plus the **Review new pushes** ruleset option
  (<https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review>).
  Direction of travel: the industry is moving re-review out of typed text and into the review UI and
  repository rulesets. Any inlined command block is documentation of a fallback, and a shrinking one.
- **Richer command vocabularies that make a single inlined line misleading.** cubic now documents a
  full/incremental/ultrareview split — "**Full review:** `@cubic-dev-ai` or `@cubic-dev-ai review this
  PR`", "**Incremental review:** `@cubic-dev-ai incremental review`", `@cubic-dev-ai ultrareview`
  (<https://docs.cubic.dev/llms-full.txt>) — and CodeRabbit distinguishes `@coderabbitai review`
  (incremental) from `@coderabbitai full review` (<https://docs.coderabbit.ai/reference/review-commands>).
  A one-line-per-bot block cannot express the distinction that actually matters after a fix-up push,
  which is precisely the incremental-versus-full choice.
- **Agent-driven re-review loops.** `greptileai/skills` publishes "greploop", which iterates a PR
  until the reviewer reports no unresolved comments (<https://github.com/greptileai/skills>). Treated
  as a lead, not a recommendation: it is vendor-specific and outside what a template can ship.

### Fit for this template

The artifact is repository metadata, so the three shapes share one file. The differences that are real
are differences in *who opens pull requests* and *what a re-review costs*, and they are argued
separately rather than asserted to be identical.

- **CLI.** The most likely PR is small and from a maintainer, and the release path is a tagged binary,
  so a missed re-review is cheap to correct. R18's assistant lane is usable here by exactly the people
  who open these PRs (`OWNER`/`MEMBER`/`COLLABORATOR`). A one-line note in `CONTRIBUTING.md` naming
  `@claude` is sufficient and correct; a fenced block in every PR body is pure overhead against the
  checklist F203 already imposes.

- **Library.** This is the shape that decides the item against inlining. A published Rust library is
  the shape most exposed to drive-by outside contributions, and an outside contributor is exactly whom
  R18's `author_association` prefilter silences: an `@claude` comment from an account with no
  association starts no job at all (`DECISION.md:12`, and R18's own unproven row **U12** records that
  this has not yet been demonstrated). A PR template that instructs every contributor to paste a
  command most of them cannot use converts a documented affordance into an unexplained silence, which
  is worse than no documentation. `CONTRIBUTING.md` can state the write-access precondition in the same
  sentence as the command; a copy-paste block in the PR body has no room for the caveat and no reason
  to be read carefully.

- **Web service.** Web-service pull requests are the widest — handlers, middleware, an OpenAPI
  document and its generated client move together — so the incremental-versus-full re-review
  distinction has the most value here, and it is exactly the distinction a single inlined line per bot
  destroys. It is also the shape where R18's missing `synchronize` bites hardest: a large PR that
  receives one review at `opened` and none after three rounds of fix-up pushes is under-reviewed
  unless someone knows to ask again. That is an argument for documenting the re-review path
  prominently — in the contributor guide, where the incremental/full distinction can be explained —
  and not for a fenced block of bare commands.

Against the py and ts precedent specifically: py's block presumes three installed vendor bots and
auto-review-on-push, and rs has neither; ts's silent omission presumes auto-review-on-push covers the
need, and under R18 it does not. Neither precedent transfers unchanged, which is why this item
recommends a third shape rather than picking a side.

### Recommendation

**`rs-launch-blueprint`'s `.github/pull_request_template.md` does not include a "Review Trigger"
comment-command section.** Adopt the pattern *contributor-guide trigger reference, with inlining
reserved for trigger phrases the template itself owns*:

1. **The PR template contains no `@`-mention of any review bot.** The template is a
   pull-request-description surface; comment ChatOps does not belong on it. The only strings that
   would earn a place are bot directives parsed from the description, and `claude-code-action` — the
   sole reviewer R18 configures — defines none, so today the correct number is zero. If a future
   revision adopts a bot with a description-parsed directive, `pr-template-description-directives-only`
   is the rule that admits it.

2. **`CONTRIBUTING.md` gains one short section, "Requesting another review",** stating in prose: that
   the automated review runs when a pull request is opened, marked ready, or reopened and **not on
   subsequent pushes**; that a maintainer or collaborator can request another review by commenting the
   template's configured trigger phrase; and that the phrase is `@claude` unless the repository has
   changed `trigger_phrase`. GitHub links `CONTRIBUTING.md` from the new-pull-request page, so this is
   discoverable at the moment it is needed
   (<https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors>).

3. **Inline `@claude` and nothing else, and only there.** This is the one string in the entire field
   whose value the template itself sets — `trigger_phrase` defaults to `@claude` in
   `anthropics/claude-code-action` and R18's workflows spell it literally in their `if:` conditions —
   so the template can keep it true by its own action. Every other bot's syntax is linked, never
   inlined: name the bot and link its command reference.

4. **The section states its own preconditions.** It says the lane is disabled unless
   `vars.ENABLE_CLAUDE_ASSISTANT` is `true`, and that only accounts with `OWNER`, `MEMBER` or
   `COLLABORATOR` association can summon it. Both facts come from R18 (`DECISION.md:12`) and both are
   the difference between a documented affordance and an unexplained silence for the outside
   contributor.

5. **A drift guard makes acceptance criterion A1 mechanical** rather than a promise — see
   `### Validation strategy`, where it is run against py at the pin and does fail on a real defect.

**Why this and not the two precedents.** It preserves the principle py was reaching for — a
discoverable re-review path — while removing the part that measurably decayed inside a quarter, and it
supplies the path ts silently lacks, which under R18's `synchronize`-free review lane is the only
re-review path that exists at all.

### Ranked runner-up

**`no-documented-trigger-anywhere`** — ts's shape: omit the block from the PR template and add nothing
to `CONTRIBUTING.md`.

**The condition under which it wins:** the owner declines to enable either `claude-code-action` lane.
R18's recommendation is explicitly conditional — if the owner withholds acceptance, "delete both files
and publish the opt-in recipe" (`DECISION.md`, `## Decision`). With both files deleted, the template
configures no automated reviewer at all, a "Requesting another review" section would document a
capability the repository does not have, and criterion A1 would fail on the very file meant to satisfy
it. In that world the honest artifact is the opt-in recipe R18 publishes, and this item contributes
nothing to the PR template. The runner-up therefore wins on the owner's enablement decision, which is
recorded below as the primary re-verify trigger.

Second runner-up, ranked below that one: **`pr-template-inlined-chatops-block`** — py's shape, copied
with rs's bot list. It becomes correct only if rs both enables a lane and adopts a bot whose command
the template can keep true; even then it costs seven lines in every pull-request body to save one
click in the Reviewers menu.

### Tradeoffs

**Versus `no-documented-trigger-anywhere` (the ranked runner-up).** The recommendation gives up
absolute minimalism: it adds a section that must be reviewed whenever R18's decision changes, and if
the owner never enables a lane that section is dead text. It also gives up the property that the
repository ships no claim about bot behavior at all. That cost is accepted because R18's review lane
omits `synchronize`, so with no documentation there is no discoverable re-review path whatsoever —
and the failure mode is invisible: a large pull request quietly receives one review at `opened` and
none thereafter. One paragraph in the file GitHub already links is a proportionate price for closing
that. The cost is also bounded by design: the section names one trigger phrase the template owns and
links everything else, so it cannot decay the way an inlined vendor block does.

**Versus `pr-template-inlined-chatops-block` (py's shape).** The recommendation gives up
copy-paste-at-the-point-of-need: a contributor reading the PR body no longer has the literal string in
front of them and must follow a link. It also gives up multi-bot coverage — a consumer who installs
CodeRabbit org-wide gets no per-bot command list from this template. Both costs are accepted. The
first is small and shrinking, because vendors are moving re-review into buttons rather than typed text
(Greptile's footer control, Copilot's Reviewers-menu control). The second is not a cost the template
can avoid honestly: it cannot know a consumer's org-level app installs, and CodeRabbit's own
documentation says the handle may differ per installation, so any inlined handle is a guess about
someone else's configuration. Against that, the recommendation buys a defect class removed —
1 of 3 inlined strings in py diverged from vendor documentation in 81 days, and py's block omits the
one bot py itself ships — plus a caveat the fenced block had no room for: who is actually allowed to
use the trigger.

**Versus `native-ui-retrigger`.** The recommendation gives up the ideal of zero documentation. That is
accepted because the native Reviewers-menu control re-requests review from a *reviewer* on the pull
request, and R18's assistant lane is a workflow triggered by a comment, not a registered reviewer; the
UI path does not reach it. The recommendation records the native control as the right answer for any
bot that does register as a reviewer, which keeps the section short.

### Parameters

`owns` — none. R45 owns no parameter (`docs/port/COMMONALITY.md:208`, F204; the item's `owns:` field
in `## Couplings` is empty).

`consumes` — none. The `consumes:` field in `## Couplings` is empty, and the recommendation needs no
consumed parameter to change.

The four owner-fixed parameters in `docs/port/PARAMETERS.md` are acknowledged and are inapplicable to
this item, each for a stated reason: `rust-edition = 2024` and
`msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version
in Cargo.toml and tested in CI` — no Rust code or manifest is produced; `target-os-matrix =
ubuntu-latest, macos-latest` — nothing executes on a runner, the artifact is rendered by GitHub;
`license = MIT OR Apache-2.0` — the Markdown is original template content covered by the template's own
licensing, and no third-party text is vendored.

No `CONFLICT:` lines. The recommendation is expressible entirely within the fixed parameters and
requires no change to any of them.

One non-parameter dependency is recorded for the controller: the content of the `CONTRIBUTING.md`
section named in `### Recommendation` is determined by R18's resolved bot set and by the owner's
enablement decision. This is the substance of the `BASELINE-REVIEW:` line in
`### Principles and implementation`.

### Migration implications

File-level changes in `rs-launch-blueprint`, stated against the py precedent that would otherwise be
ported. `rs-launch-blueprint` has no `.github/` tree today; P03 authors these files, so every entry
below is a *do-not-create* or a *create* instruction rather than an edit.

- **`.github/pull_request_template.md` — do not create the "Review Trigger" section.** The seven lines
  at py `.github/pull_request_template.md:90-96` (heading, the HTML comment "Bots also auto-review on
  push; use this block to (re)request a review on demand.", and the fenced `text` block containing
  `@coderabbitai review`, `@greptile-apps review`, `@cubic-dev-ai review`) are not carried forward.
  Two independent reasons, either sufficient: the three bots are not configured by this template
  (R18 rejects hosted third-party review apps, `DECISION.md:96`), and the explanatory comment would be
  **false** in rs, whose review lane omits `synchronize` and therefore does *not* auto-review on push
  (`DECISION.md:11`, `DECISION.md:316`).
- **`.github/pull_request_template.md` — the checklist is untouched.** F203 (`COMMON → REUSE`,
  `docs/port/COMMONALITY.md:207`) is outside this item's scope and no checklist line is added, removed
  or reworded here.
- **`CONTRIBUTING.md` (or `.github/CONTRIBUTING.md`, matching whichever path the template adopts) —
  add one section, "Requesting another review".** Contents per `### Recommendation` items 2 to 4: when
  the automated review runs and that it does not run on subsequent pushes; the trigger phrase
  `@claude`; the `vars.ENABLE_CLAUDE_ASSISTANT` precondition; the
  `OWNER`/`MEMBER`/`COLLABORATOR` restriction; and links, not inlined syntax, for any other reviewer a
  consumer installs. Both source repositories already ship this file (py and ts each have
  `.github/CONTRIBUTING.md` at their pins), so no new file class is introduced.
- **New: `scripts/check-documented-bot-handles.sh` plus one CI step.** The drift guard in
  `### Validation strategy`. Roughly twenty lines of `bash`, no dependency beyond `grep`, runs on
  `ubuntu-latest` in well under a second.
- **Follow-on rationale for the source repositories** (a separate project, per the prompt; nothing
  here changes py or ts). For **py**: the block's `@greptile-apps review` line diverges from Greptile's
  currently documented handle `@greptileai`, and the block omits `@claude` although py ships
  `.github/workflows/claude.yml` — py should either move the block to `.github/CONTRIBUTING.md` with
  links in place of inlined syntax, or re-verify each string against its vendor's documentation on a
  schedule. For **ts**: its omission is currently harmless because it configures no comment-triggered
  reviewer in-repo; if it adopts one, the same `CONTRIBUTING.md` section applies. Both repositories
  would benefit from the same drift guard, which is the portable part of this answer.

### Validation strategy

The check that matters is acceptance criterion A1: *no contributor-facing file names a bot this
repository does not wire.* It is mechanical, and it was run.

**Executed — the drift guard, proved against `py-launch-blueprint` at pin `b08bccfb`.** The rs
template does not exist yet, so the guard was exercised against the one repository that does ship the
pattern. The pin was exported to a scratch directory (`git archive b08bccfb | tar -x`), and the script
below was run from its root. It collects every `@handle` appearing in `.github/pull_request_template.md`
and `CONTRIBUTING.md`/`.github/CONTRIBUTING.md`, then requires each to be wired — either the literal
string appears in `.github/workflows/`, or the vendor's own configuration path exists in the tree.

    #!/usr/bin/env bash
    # Fails when a contributor-facing file documents an @bot handle that this
    # repository does not actually configure.
    set -uo pipefail
    docs=(.github/pull_request_template.md .github/CONTRIBUTING.md CONTRIBUTING.md)
    declare -a documented=()
    for f in "${docs[@]}"; do
      [ -f "$f" ] || continue
      while read -r h; do documented+=("$h"); done \
        < <(grep -ohE '@[A-Za-z0-9][A-Za-z0-9._-]+' "$f" | sort -u)
    done
    rc=0
    for h in $(printf '%s\n' "${documented[@]}" | sort -u); do
      wired=no
      grep -rqF -- "$h" .github/workflows 2>/dev/null && wired=yes
      case "$h" in
        @coderabbitai) [ -f .coderabbit.yaml ] || [ -f .coderabbit.yml ] && wired=yes ;;
        @greptile-apps|@greptileai) [ -d .greptile ] || [ -f greptile.json ] && wired=yes ;;
        @cubic-dev-ai) [ -f .cubic.yaml ] || [ -f cubic.json ] || [ -d .cubic ] && wired=yes ;;
      esac
      printf '%-16s wired=%s\n' "$h" "$wired"
      [ "$wired" = no ] && rc=1
    done
    exit $rc

**Observed output and exit status, 2026-09-10:**

    @coderabbitai    wired=yes
    @cubic-dev-ai    wired=no
    @greptile-apps   wired=yes
    EXIT=1

This is a **true positive on a real defect**: py's PR template instructs contributors to comment
`@cubic-dev-ai review`, and py ships no cubic configuration anywhere in the tree at the pin
(`git ls-tree -r --name-only b08bccfb | grep -iE 'coderabbit|greptile|cubic'` returns only
`.coderabbit.yaml`, `.greptile/config.json`, `.greptile/rules.md`). Expected behavior in rs under the
recommendation: the same script exits `0`, because the PR template names no bot and
`CONTRIBUTING.md` names only `@claude`, which appears literally in `.github/workflows/claude.yml`'s
`contains(…, '@claude')` condition (`DECISION.md:12`).

**Two limitations of the guard, stated rather than glossed.** (i) It catches *documented but not
wired*; it does **not** catch *handle drifted against the vendor's documentation*. It passed
`@greptile-apps` because `.greptile/` exists, which is exactly the divergence this report found by
hand. No automatable check exists for that class — a vendor's handle is not discoverable from the
repository — and that irreducible gap is the strongest argument for linking to vendor documentation
instead of inlining it. (ii) The `@[A-Za-z0-9]…` pattern can match an email local part or a handle
inside prose; it produced no false positive on py at the pin, but the rs implementation should anchor
on fenced-block and list contexts if `CONTRIBUTING.md` grows email addresses.

**Proposed, not executed.** These require the P03 template and a live repository, and none is claimed
as a result here:
1. Wire the guard as a CI step on `ubuntu-latest` and assert exit `0` on a clean tree and exit `1`
   after deliberately inserting `@coderabbitai review` into the PR template.
2. Open a pull request from a template-derived repository and assert the rendered pull-request body
   contains no `@` mention of any bot.
3. With `vars.ENABLE_CLAUDE_ASSISTANT` set to `true`, post `@claude please re-review` from a
   collaborator account and assert a run is created; post the same from an account with no
   association and assert none is — this is R18's unproven row **U12**, referenced rather than
   duplicated, and it is R18's to close.
4. Assert the `CONTRIBUTING.md` claim about triggers by reading `.github/workflows/claude-code-review.yml`
   and confirming its `types:` list still omits `synchronize`; if P03 restores `synchronize`, the
   section's first sentence is wrong and must shrink.

**One unverified risk, recorded rather than resolved.** CodeRabbit documents `@coderabbitai ignore`
and `@coderabbitai summary` as directives read from the **pull-request description**
(<https://docs.coderabbit.ai/reference/review-commands>). Whether a bot that parses descriptions also
acts on a command sitting inside a fenced code block in a description — py's arrangement — was not
determined; no vendor documents fenced-block handling. It is a reason to prefer keeping such strings
out of the description surface entirely, and it is stated here as an open question, not as a finding
that py's block misfires. Relatedly, the common claim that GitHub suppresses `@`-mention notifications
inside code fences is **observed rendering behavior for which no authoritative documentation was
located**, and no part of this recommendation rests on it.

### Confidence & re-verify trigger

**Confidence: high** on the decision (no comment-command block in the PR template), **medium-high** on
the placement and content of the `CONTRIBUTING.md` section.

What makes the decision robust: it is over-determined. The bot list py inlines is not configured by
this template at all (R18, resolved 2026-09-10); zero of twelve well-regarded Rust projects practice
the inlined pattern; the surface argument (description template versus comment ChatOps) is confirmed
by the Rust project's own deliberate split and by CodeRabbit's own documentation of which of its
directives are description-placed; and one of py's three strings measurably diverged from vendor
documentation within 81 days. Any one of these alone would decide it; the four are independent.

What is softer, and why the section rather than the decision carries the residual: the exact wording
depends on an owner decision that has not been taken (R18 ships both lanes inert pending acceptance),
and on P03's `synchronize` choice. Those move the section's contents, not its existence or location.

**Re-verify triggers, each with what it changes:**
- **The owner's enablement decision on R18's two lanes.** If acceptance is withheld and both files are
  deleted, the ranked runner-up wins and the `CONTRIBUTING.md` section is not written. This is the
  primary trigger and it is currently open.
- **P03 restoring `synchronize` to `.github/workflows/claude-code-review.yml`.** The section's first
  sentence becomes false and the section shrinks to the write-access `@claude` note; the
  recommendation itself is unaffected.
- **R18 adopting any additional reviewer**, in particular one that registers as a pull-request reviewer
  (making the native Reviewers-menu control the documented path) or one that parses a
  pull-request-description directive (which `pr-template-description-directives-only` would then admit
  into the template). Re-open F204 per the `BASELINE-REVIEW:` line.
- **`anthropics/claude-code-action` changing the `trigger_phrase` default from `@claude`.** The one
  inlined string in the recommendation is invalidated; re-read `docs/usage.md` at the pinned tag.
- **Twelve months from 2026-09-10, or sooner if a vendor's documentation domain moves again.**
  `docs.greptile.com` refused connection on the retrieval date and the corpus now lives at
  `www.greptile.com/docs`; a moved link in `CONTRIBUTING.md` is the recommendation's own failure mode
  and it needs the same periodic check it prescribes for others.

### Sources

Repository sources, read through their programme pins (both repositories are private; no public URL
exists for their contents):
- `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, read 2026-09-10:
  `.github/pull_request_template.md` (the "Review Trigger" section at lines 90-96, the checklist,
  the "Bots also auto-review on push" comment); `.coderabbit.yaml` (`reviews.auto_review.enabled: true`,
  `fail_commit_status: false`); `.greptile/config.json` (`triggerOnUpdates: true`, `statusCheck: true`);
  `.github/workflows/` (including `claude.yml` and `claude-code-review.yml`); `.github/CONTRIBUTING.md`;
  `git ls-tree -r --name-only b08bccfb` for the absence of any cubic configuration;
  `git log -S'Review Trigger' -- .github/pull_request_template.md` → `47edb56 2026-06-21 ci: add
  greptile and cubic pr review bots alongside coderabbit`.
- `ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, read 2026-09-10:
  `.github/pull_request_template.md` (no Review Trigger section); `.github/` tree listing (no
  `claude*.yml`, no vendor bot config); `docs/tools/vs-code.md:20` (the CodeRabbit editor extension
  "matching the org's CodeRabbit usage on pull requests").
- Programme documents in this repository, read 2026-09-10: `docs/port/COMMONALITY.md:57-58` (F051,
  F052), `:207` (F203), `:208` (F204); `docs/port/PARAMETERS.md`;
  `research/topics/18-ai-assisted-review-workflows/DECISION.md` (revision 5, 2026-09-10) — lines 11,
  12, 96, 148, 316, and `## Decision`.

Vendor and platform documentation, all retrieved 2026-09-10:
- CodeRabbit code review commands — <https://docs.coderabbit.ai/reference/review-commands>
  (`@coderabbitai review`, `@coderabbitai full review`, `@coderabbitai pause` / `resume`,
  `@coderabbitai ignore` "must be placed in the PR description, not in comments", `@coderabbitai
  summary` as a description placeholder, and the per-installation handle caveat).
- Greptile documentation corpus — <https://www.greptile.com/docs/llms-full.txt> and
  <https://www.greptile.com/docs/llms.txt> (`@greptileai` as the documented handle;
  `@greptileai review this`; the "Re-trigger Greptile" footer button, changelog entry labeled
  March 25, 2026; `skipReview: "AUTOMATIC"` for manual-only triggering).
- cubic documentation corpus — <https://docs.cubic.dev/llms-full.txt> ("**Full review:**
  `@cubic-dev-ai` or `@cubic-dev-ai review this PR`"; "**Incremental review:** `@cubic-dev-ai
  incremental review`"; `@cubic-dev-ai ultrareview`; "`@cubic`, `@cubic-dev-ai`, and other supported
  cubic tags work"); <https://docs.cubic.dev/ai-review/interactive-comments>.
- `anthropics/claude-code-action` usage guide —
  <https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md> (default
  `trigger_phrase` `@claude`; automatic review configured with `on: pull_request` plus a `prompt:`);
  <https://raw.githubusercontent.com/anthropics/claude-code-action/main/README.md>.
- GitHub — pull request templates:
  <https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository>;
  contributing guidelines and where they are surfaced:
  <https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors>;
  saved replies: <https://docs.github.com/en/get-started/writing-on-github/working-with-saved-replies/about-saved-replies>;
  Copilot code review and re-request:
  <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review>.
- Rust project practice — <https://raw.githubusercontent.com/rust-lang/rust/main/.github/pull_request_template.md>
  (`r? <reviewer name>`, `homu-ignore`);
  <https://raw.githubusercontent.com/rust-lang/rust-clippy/master/.github/PULL_REQUEST_TEMPLATE.md>
  (`changelog:`); <https://rustc-dev-guide.rust-lang.org/rustbot.html> and
  <https://forge.rust-lang.org/triagebot/shortcuts.html> (comment commands documented in the
  contributor guide).
- Surveyed project templates, all fetched from `https://raw.githubusercontent.com/<o>/<r>/<branch>/`
  on 2026-09-10: tokio-rs/tokio, tokio-rs/axum, clap-rs/clap, rust-lang/cargo, ratatui/ratatui,
  bevyengine/bevy, nushell/nushell, starship/starship, zed-industries/zed, astral-sh/ruff,
  astral-sh/uv (`.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md`).
- Lead only, not relied on for any figure: <https://github.com/greptileai/skills> (the "greploop"
  re-review loop).

Endpoints queried for figures, all 2026-09-10:
`GET https://api.github.com/repos/<o>/<r>` → `stargazers_count`, `archived`, `pushed_at`;
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count`;
`GET https://api.github.com/repos/<o>/<r>/contents/<path>` → presence of `.coderabbit.yaml`,
`.coderabbit.yml`, `.greptile/config.json`, `greptile.json`;
`GET https://api.github.com/users/<login>` → `login`, `type` for `coderabbitai`, `greptile-apps`,
`greptileai`, `cubic-dev-ai`.

**Method notes.** Figures came from `api.github.com` (`/repos/<o>/<r>`, `/search/issues`,
`/repos/<o>/<r>/contents/<path>`, `/users/<login>`) and file contents from `raw.githubusercontent.com`
and the vendors' own documentation endpoints listed above; source-repository contents came from
`git show <pin>:<path>` against the two programme pins, never from a working tree. Four access
problems shaped the method and are recorded rather than worked around. (1) **Unauthenticated
`api.github.com` returned "API rate limit exceeded"** for the `/users/` probes; every GitHub figure in
this report was therefore re-collected through `gh api`, which authenticates, and the endpoint paths
quoted are the ones `gh api` calls. (2) **`docs.greptile.com:443` refused the connection** (`curl`
exit 28, then `ECONNREFUSED` via the fetch tool); Greptile's live corpus was read instead from
<https://www.greptile.com/docs/llms-full.txt>, and the rendered pages at `www.greptile.com/docs/...`
are client-rendered and yield no text to `curl`, so the `llms-full.txt` corpus is the citation of
record for every Greptile quote. (3) **`https://docs.cubic.dev/introduction` returned HTTP 404**;
cubic's commands were read from <https://docs.cubic.dev/llms-full.txt>, which corrected an earlier
paraphrase — `@cubic-dev-ai review` **is** a documented form, so py's cubic line is not stale and this
report does not claim it is. (4) A batch fetch of PR templates was silently clobbered by the
case-insensitive macOS filesystem, which collapsed `pull_request_template.md` and
`PULL_REQUEST_TEMPLATE.md` into one output path; the five affected repositories
(`rust-lang/rust`, `ratatui/ratatui`, `bevyengine/bevy`, `nushell/nushell`, `zed-industries/zed`) were
re-fetched individually and every template quoted here was read after that correction.
**Not verified, and named as such:** whether `@greptile-apps review` still triggers a Greptile review
(the handle exists as a GitHub account but is not the handle Greptile's current documentation uses —
a divergence, not an observed failure); whether any bot acts on a command inside a fenced code block
in a pull-request description; whether GitHub suppresses `@`-mention notifications inside code fences
(no authoritative documentation located, and nothing here depends on it); whether the twelve surveyed
Rust projects have org-level AI-review apps installed (only repository-level configuration files are
observable, so the survey shows non-configuration and non-documentation, not non-use); and every item
listed under "Proposed, not executed" in `### Validation strategy`, none of which could run because
`rs-launch-blueprint` has no `.github/` tree and P03 has not built the template. `ripgrep` was
probed at four conventional template paths and none returned HTTP 200; it is reported as "no template
found at the four probed paths" rather than as having no template.
