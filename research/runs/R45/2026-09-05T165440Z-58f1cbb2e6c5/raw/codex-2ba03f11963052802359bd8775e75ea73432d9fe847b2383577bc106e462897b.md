### Landscape

**Category and three-bin map.** This is a GitHub pull-request-template convention that exposes a recovery path for an enabled AI reviewer; it is neither Rust code nor a Rust crate. The built-in/first-party option is a `.github/pull_request_template.md` section, which GitHub injects into each new pull request. The established convention is a short checklist plus automatic review on new pushes, with an optional documented manual re-run. The up-and-comer options are vendor-specific `@`-mention commands and local/agent review tools. GitHub documents the template location and its purpose; that makes the Markdown template, rather than a Rust library, the appropriate implementation mechanism. ([GitHub: creating a PR template](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), retrieved 2026-09-05)

**Authorities.** GitHub is authoritative for what a PR template displays. CodeRabbit, Greptile, and cubic are authoritative for their own current trigger syntax. Their maintained documentation confirms that all three retain manual comment triggers despite automatic review features. ([GitHub template documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), [CodeRabbit command guide](https://docs.coderabbit.ai/guides/commands), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), [cubic interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), all retrieved 2026-09-05)

**Practice evidence.** The pinned py template is a maintained reference implementation of a visible trigger block; its pinned ts sibling instead has no such block and retains the checklist. Current Tokio and Tauri templates also concentrate on change context and pre-flight guidance, not bot commands, so an explicit bot-command block is not a universal Rust-project convention. Tokio is a strong Rust reference because the Rust Book calls it the most widely used async runtime, and Tauri is a maintained Rust-based application framework; their templates demonstrate the lighter option, not a mandate to omit recovery instructions. ([py template at pinned revision](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/pull_request_template.md#L90-L97), [ts template at pinned revision](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/pull_request_template.md#L104-L119), [Rust Book on Tokio](https://doc.rust-lang.org/book/ch17-01-futures-and-syntax.html), [Tokio template](https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/PULL_REQUEST_TEMPLATE.md), [Tauri template](https://raw.githubusercontent.com/tauri-apps/tauri/dev/.github/PULL_REQUEST_TEMPLATE.md), all retrieved 2026-09-05)

No crate candidate exists. Therefore crates.io downloads, releases, reverse dependencies, RustSec advisories, GitHub repository figures, issue responsiveness, and crate fitness figures are **inapplicable**: this decision adds Markdown only and introduces no Cargo dependency.

### Principles and implementation

The shared requirement is **recoverable, discoverable AI review** at the capability/policy agreement level: an author who has pushed a fix can request another review without knowing a vendor's undocumented interface. F204 records py's capability and ts's omission as a DIVERGENT source fact, while F203 separately fixes the pre-flight checklist as `COMMON → REUSE`; therefore the checklist must remain independent from this decision. ([F203/F204 ledger](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L207-L209), retrieved 2026-09-05)

The recommended architecture is a short `## Review Trigger` section in the PR template, immediately before the checklist. It says that automatic reviews may occur after pushes, then lists only the commands for bots that R18 actually enables, with each vendor name linked to its documentation. This keeps the discovery point per-PR while making the bot inventory an R18-owned configuration decision. GitHub confirms that PR-template text is shown to the author for every new PR; CodeRabbit documents both auto-review and manual review; Greptile and cubic document an on-demand mention. ([GitHub template documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), [CodeRabbit auto-review controls](https://docs.coderabbit.ai/configuration/auto-review), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), [cubic interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), all retrieved 2026-09-05)

The meaningful alternatives are: omit the block and rely on push automation; put commands only in `CONTRIBUTING.md`; or copy static commands with no ownership boundary. Omission preserves a smaller PR body but removes recovery when auto-review is paused, filtered, or not yet installed. A contributor document is less stale-looking but is not presented at the moment a PR author needs the command. Static copying is unsafe because vendor handles and syntax change: the py command `@greptile-apps review` is not the current official Greptile invocation, whose documentation specifies `@greptileai`. ([py template at pinned revision](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/pull_request_template.md#L90-L97), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), retrieved 2026-09-05)

Minimal proposed template content, parameterized by R18, is:

```markdown
## Review Trigger
<!-- Enabled bots may also review automatically after a push. To request a re-review, post one applicable command as a PR comment. -->
- CodeRabbit (if enabled): `@coderabbitai review` ([commands](https://docs.coderabbit.ai/guides/commands))
- Greptile (if enabled): `@greptileai` ([commands](https://www.greptile.com/docs/code-review/developer-essentials))
- cubic (if enabled): `@cubic-dev-ai review this PR` ([commands](https://docs.cubic.dev/ai-review/interactive-comments))
```

The commands above are vendor-documented as follows: CodeRabbit's `review` is incremental and `full review` is the full alternative; Greptile accepts the bare `@greptileai` mention; cubic accepts `@cubic-dev-ai review this PR` for a full review. `claude-code-review` has no confirmed comment syntax in the R45 evidence, so it must not receive a row until R18 supplies one. ([CodeRabbit command guide](https://docs.coderabbit.ai/guides/commands), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), [cubic interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), all retrieved 2026-09-05)

**Observable acceptance criteria (proposed, not run).** The rendered template has one `Review Trigger` heading before `Checklist`; it says automatic review may occur; every listed command is for an R18-enabled bot and matches its current vendor documentation; the obsolete `@greptile-apps` handle is absent; and the pre-flight checklist remains. These criteria are OS-neutral Markdown checks, so they impose no Rust runtime, performance, compile-time, binary-size, async-runtime, `unsafe`, license, MSRV, or RustSec consequence.

BASELINE-REVIEW: F204 — recoverable, discoverable on-demand AI review — retain a conditional PR-template trigger block but replace py's stale `@greptile-apps review` spelling and let R18 select rows — current Greptile documentation specifies `@greptileai`; affected items R45 and R18. ([F204 source evidence](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/dev-experience-repo-hygiene.md#L35), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), retrieved 2026-09-05)

### Dominant choice

**Conditional, vendor-linked `Review Trigger` section in `.github/pull_request_template.md`.** Keep the section only for bots R18 enables; preserve the auto-review note and link each selected row to the vendor's canonical command page. This preserves the capability while preventing R45 from selecting a bot. ([GitHub template documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), [CodeRabbit command guide](https://docs.coderabbit.ai/guides/commands), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), [cubic interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), all retrieved 2026-09-05)

Fitness gates are assessed before popularity: license, MSRV/dependency tree, RustSec/`unsafe`, OS build matrix, default features/async coupling, and binary/compile cost are each **inapplicable** because this is repository Markdown with no crate, executable, or dependency tree. The validation itself is portable shell text matching on the fixed Ubuntu and macOS CI runners.

### Options

| name | where documented | adopters that practice it | most recent authoritative write-up |
|---|---|---|---|
| Conditional template trigger block | GitHub template mechanism plus current vendor command pages | py-launch-blueprint's pinned template supplies the reference block; use its placement, not its stale Greptile syntax | [GitHub](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), [CodeRabbit](https://docs.coderabbit.ai/guides/commands), [Greptile](https://www.greptile.com/docs/code-review/developer-essentials), [cubic](https://docs.cubic.dev/ai-review/interactive-comments), retrieved 2026-09-05 |
| Omit and rely on auto-review-on-push | Vendor auto-review configuration | ts-launch-blueprint's pinned template; Tokio and Tauri templates similarly omit bot instructions | [CodeRabbit auto-review controls](https://docs.coderabbit.ai/configuration/auto-review), [ts template](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/pull_request_template.md#L104-L119), retrieved 2026-09-05 |
| Contributor-doc link only | GitHub supports PR templates and contribution guidance, but does not prescribe this placement | no maintained reference identified in this focused survey | [GitHub template documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), retrieved 2026-09-05 |

### Excluded by gate

**Static copied three-command block** is excluded by the correctness/maintainability gate: it would advertise `@greptile-apps review`, while Greptile's current documentation requires `@greptileai` to trigger a review. This is a documentation correctness failure, not a popularity comparison. All crate-specific fitness gates are inapplicable to this pattern. ([py template at pinned revision](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/pull_request_template.md#L90-L97), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), retrieved 2026-09-05)

### Up-and-comers

Vendor local-review and agent integrations can shorten the repair-and-review loop, but they do not replace a PR-visible recovery instruction for external contributors. CodeRabbit documents agent skills, Greptile documents a local CLI, and cubic documents local review; none supplies a cross-vendor stable PR-comment standard. Treat them as optional R18-era workflow enhancements, not content for F204. ([CodeRabbit changelog](https://docs.coderabbit.ai/changelog), [Greptile CLI](https://www.greptile.com/cli), [cubic local CLI review](https://docs.cubic.dev/ide/cli-review), retrieved 2026-09-05)

### Fit for this template

**CLI.** A CLI change is often small and iterative; a manual incremental review prevents an author from waiting for a policy that might have excluded a draft or paused automation. **Library.** Public API and compatibility changes benefit from a clearly available full-review request after cross-cutting edits. **Web.** Security- and deployment-sensitive changes benefit from an explicit on-demand review path after remediation. The same Markdown block serves all three without adding runtime code; it should not claim that any bot is a merge gate. ([CodeRabbit auto-review controls](https://docs.coderabbit.ai/configuration/auto-review), [cubic interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), retrieved 2026-09-05)

### Recommendation

Adopt the conditional `Review Trigger` section. Its single shared policy is that every enabled AI reviewer has a documented, copyable manual re-run path in the PR body; the bot list and syntax remain R18-derived. Link the vendor documentation beside each command, and make the automatic-on-push behavior explanatory rather than a promise. This is the smallest design that preserves py's recovery capability, accommodates ts's lower-noise preference, and fixes confirmed command drift. ([py template at pinned revision](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/pull_request_template.md#L90-L97), [ts template at pinned revision](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/pull_request_template.md#L104-L119), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), retrieved 2026-09-05)

### Ranked runner-up

**Omit the block and rely on auto-review-on-push.** It wins only if R18 selects no bot with a supported manual PR-comment trigger, or if the owner explicitly chooses a no-vendor-instructions PR body. CodeRabbit's own documentation establishes the opposite present condition: auto review can be paused or constrained while a manual command remains available. ([CodeRabbit auto-review controls](https://docs.coderabbit.ai/configuration/auto-review), retrieved 2026-09-05)

### Tradeoffs

The recommendation adds a small amount of PR-template text and an obligation to update a row when R18 changes providers. Compared with the omit option, that cost is accepted because recovery remains discoverable after automation is paused or filtered. Compared with a contributor-doc-only link, it accepts repeated visibility because GitHub displays the template exactly where authors open a PR. Compared with a static copied block, it adds conditional generation/review work because a stale command is worse than a missing one. ([GitHub template documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), [CodeRabbit auto-review controls](https://docs.coderabbit.ai/configuration/auto-review), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), retrieved 2026-09-05)

### Parameters

owns none.

assumes R18: enabled AI-review bot inventory and each bot's approved trigger syntax.

No `CONFLICT:` line: R45 does not need a consumed parameter changed; it defers the inventory to R18 as required by the coupling.

### Migration implications

After R18 resolves, create `.github/pull_request_template.md` with the independently required F203 checklist and add `## Review Trigger` immediately before it. Include only the R18-selected rows; use `@coderabbitai review` for CodeRabbit, `@greptileai` for Greptile, and `@cubic-dev-ai review this PR` for cubic only if that provider remains selected. Do not carry py's `@greptile-apps review` text forward. ([F203/F204 ledger](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L207-L209), [CodeRabbit command guide](https://docs.coderabbit.ai/guides/commands), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), [cubic interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), retrieved 2026-09-05)

### Validation strategy

**Planned, not executed** because the Rust template and R18 bot decision do not exist yet:

```sh
set -euo pipefail
template=.github/pull_request_template.md
rg -n '^## Review Trigger$' "$template"
rg -n '^## Checklist$' "$template"
! rg -nF '@greptile-apps' "$template"
```

Expected result: one trigger heading, one checklist heading, and no obsolete Greptile handle. At integration, add an R18-derived fixture that asserts the exact enabled-bot rows and rejects every unselected bot row; then run it on `ubuntu-latest` and `macos-latest`. A human PR smoke check should paste one documented command for each enabled GitHub App into a disposable PR and confirm that the app acknowledges or starts a review. That live action is planned, not executed; it requires the configured apps and is outside R45's authority. GitHub's template behavior and each vendor's syntax are the governing oracles. ([GitHub template documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), [CodeRabbit command guide](https://docs.coderabbit.ai/guides/commands), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), [cubic interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), retrieved 2026-09-05)

### Confidence & re-verify trigger

**Medium-high.** The recommendation rests on first-party GitHub behavior and current vendor documentation, but installed-app configuration, permissions, and R18's selected inventory remain unverified. Re-verify immediately before merging R18 or any PR-template change, whenever a selected vendor changes its GitHub App handle/command page, and whenever a manual smoke comment does not start a review. ([CodeRabbit command guide](https://docs.coderabbit.ai/guides/commands), [Greptile developer essentials](https://www.greptile.com/docs/code-review/developer-essentials), [cubic interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), retrieved 2026-09-05)

### Sources

- [GitHub: Creating a pull request template](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository), retrieved 2026-09-05.
- [CodeRabbit: Manage code reviews](https://docs.coderabbit.ai/guides/commands) and [automatic review controls](https://docs.coderabbit.ai/configuration/auto-review), retrieved 2026-09-05.
- [Greptile: Developer Essentials](https://www.greptile.com/docs/code-review/developer-essentials), retrieved 2026-09-05.
- [cubic: Interactive comments](https://docs.cubic.dev/ai-review/interactive-comments), retrieved 2026-09-05.
- [py source template, pinned](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/pull_request_template.md#L90-L97) and [ts source template, pinned](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/pull_request_template.md#L104-L119), retrieved 2026-09-05.

Method notes: Queried GitHub's PR-template documentation, CodeRabbit's command and auto-review pages, Greptile's developer-essentials page, cubic's interactive-comments page, and raw current Tokio/Tauri PR-template URLs on 2026-09-05. `GET https://api.github.com/repos/<owner>/<repo>` attempts for practice figures were rate-limited by GitHub, so no GitHub numerical figures are claimed; those crate/repository figures are inapplicable to this pattern in any event. No crates.io, RustSec, or reverse-dependency endpoint applies because no crate is evaluated. I verified the pinned py and ts source templates locally at their recorded revisions; I did not verify an installed bot inventory or a `claude-code-review` comment command, which R18 owns.
