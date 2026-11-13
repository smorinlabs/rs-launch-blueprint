### Landscape

This decision is GitHub Actions supply-chain reference integrity, not a Rust
runtime-library choice. The first-party support is GitHub's `github-actions`
Dependabot ecosystem and its repository policy that can require full SHAs. The
policy is stronger than this item's requested boundary: when enabled it applies
to GitHub-authored actions too, so the template's `actions/*` and `github/*`
major-tag exception is an owner-scoped compatibility rule, not a technical
claim that those tags are immutable. [GitHub repository-action policy](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository?apiVersion=2022-11-28), retrieved 2026-09-05.

The established alternatives are (1) immutable 40-hex commit SHA plus a
same-line release-version comment, and (2) a floating major or version tag.
GitHub's security guidance recommends the former for third-party actions
because tags can be moved; Dependabot recognizes and updates the SHA and the
same-line comment together. [GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), [GitHub Dependabot ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories), retrieved 2026-09-05. The up-and-comer enforcement option is `zizmor`'s configurable
`unpinned-uses` audit; its default is now stricter than the requested policy
(all actions hash-pinned), but it supports an `actions/*: ref-pin` exception.
[zizmor audit documentation](https://docs.zizmor.sh/audits/), retrieved 2026-09-05.

Authorities are diverse and fit their roles: GitHub documents the execution
and Dependabot behavior of its own platform; OpenSSF's Scorecard is an
industry security project whose automated metrics include dependency pinning;
and the `tj-actions/changed-files` incident is concrete independent evidence
that mutable action tags can redirect workflows to malicious code. [OpenSSF Scorecard overview](https://securityscorecards.dev/), [StepSecurity incident report](https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised), retrieved 2026-09-05. The incident report states that the compromised tags caused action code to change and recommends SHA pinning; it is supporting incident evidence, not the sole authority. [StepSecurity incident report](https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised), retrieved 2026-09-05.

Practice is mixed rather than Rust-specific. The Rust project's primary
`rust-lang/rust` workflow SHA-pins `actions/checkout` and
`actions/upload-artifact` with version comments, demonstrating a maintained,
large-project reference for the syntax; the project is a direct maintainer of
the Rust compiler, so it is a stronger Rust practice reference than a generic
example. [Rust CI workflow](https://github.com/rust-lang/rust/blob/main/.github/workflows/ci.yml), retrieved 2026-09-05. `zizmor` itself SHA-pins its third-party
`Swatinem/rust-cache`, `astral-sh/setup-uv`, and `re-actors/alls-green` calls
and tests on Ubuntu, macOS, and Windows. [zizmor CI workflow](https://github.com/zizmorcore/zizmor/blob/main/.github/workflows/ci.yml), retrieved 2026-09-05. Conversely, the pinned py and ts source snapshots establish the
actual local divergence: py uses `smorinlabs/contributors-please-action@v1.3.9`
and ts uses a 40-hex SHA followed by `# v1.3.9`. [py source snapshot](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/update-contributors.yml#L27), [ts source snapshot](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/workflows/update-contributors.yml#L74), retrieved 2026-09-05.

No crates.io figure applies to the two policy alternatives: each changes a
workflow reference format and adds no Rust crate. The optional `zizmor` tool
was separately measured only to assess enforcement: its crates.io endpoint
returned 52,621 recent (90-day) downloads and 236,005 total downloads; its
newest unyanked release was 1.30.0 on 2026-08-30. [crates.io crate endpoint](https://crates.io/api/v1/crates/zizmor), [crates.io versions endpoint](https://crates.io/api/v1/crates/zizmor/versions), retrieved 2026-09-05. GitHub REST repository metadata for `zizmorcore/zizmor` was rate-limited in this run, so stars, archived state, pushed time, issue responsiveness, and maintenance classification were not verified; its issue-search endpoint did return 138 open issues. [GitHub issue-search endpoint](https://api.github.com/search/issues?q=repo:zizmorcore/zizmor+is:issue+is:open), retrieved 2026-09-05.

### Principles and implementation

The shared requirement should be a security policy: every non-exempt,
third-party remote action executes a reviewed immutable revision, while a
repository-native updater proposes reviewable freshness changes. This is a
policy-level agreement across py, ts, and Rust, not a language-dependent
capability; GitHub Actions has identical mutable-tag semantics in all three.
[GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), retrieved 2026-09-05. The current py tag is therefore a policy gap, not a justified Python
ecosystem difference; changes to py remain follow-on work. The Rust and ts
implementations should agree at the low level because the security and
maintenance trade-off is identical. [ts decision D-022(9)](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/docs/port/TS_PORT_DECISIONS.md#L267-L293), retrieved 2026-09-05.

The recommended architecture is **reviewed immutable action reference +
same-line release hint + bot-proposed update**:

```yaml
- uses: owner/action@0123456789abcdef0123456789abcdef01234567 # v1.2.3
```

The full 40-character Git commit ID binds the step to the revision reviewed in
the pull request. The `# v1.2.3` hint preserves human auditability and lets
Dependabot update the hint with the SHA; it is not an execution input. [GitHub Dependabot comment support](https://github.blog/changelog/2022-10-31-dependabot-now-updates-comments-in-github-actions-workflows-referencing-action-versions/), retrieved 2026-09-05. A Dependabot pull request must change the SHA and its
same-line hint together, then pass the normal workflow checks before human
merge; pinning does not establish that a newly selected release is benign.
[GitHub Dependabot version updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates?learn=dependency_version_updates), retrieved 2026-09-05.

The precise scope is a remote action in a workflow step whose repository owner
is neither `actions` nor `github`, including `smorinlabs/*`; local actions
(`./...`) are not remote dependencies and are outside this policy. No Docker
action is in the inherited inventory. If one is added, the same immutable
reference principle needs a separate digest-specific rule because GitHub's
repository-action syntax and Dependabot support differ for `docker://` uses.
[GitHub Dependabot ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories), retrieved 2026-09-05.

The minimal realistic template example is the contributors workflow using
`smorinlabs/contributors-please-action` at its reviewed SHA and a version
comment, with `github-actions` updates enabled by R19. The planned acceptance
check parses each `uses:` value under `.github/workflows`, rejects a
third-party tag or abbreviated SHA, and permits only the owner-required
official major tags plus the F062 exception below. This check is proposed, not
executed, because no Rust template workflows exist yet. [GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), retrieved 2026-09-05.

`actionlint` is useful for workflow syntax, expression, permission, and action
format checks, but its documented focus is catching workflow mistakes rather
than enforcing a repository-specific SHA rule. [actionlint checks](https://github.com/rhysd/actionlint/blob/main/docs/checks.md), retrieved 2026-09-05. `zizmor` can enforce the rule, but it does not change the architectural
answer: it detects mutable references after the policy is selected. [zizmor `unpinned-uses`](https://docs.zizmor.sh/audits/), retrieved 2026-09-05.

BASELINE-REVIEW: F062 — canonical vendor workflow provenance — exempt only the
verbatim `difftree-pr-comment.yml` consumer workflow from the general
third-party SHA policy, because its inherited value is byte-for-byte fidelity
to the maintained vendor template; all other third-party action references use
the SHA-plus-comment pattern. This is the baseline review's recommended option
(a), not a claim that `@v0` is immutable. [baseline review finding](file:///Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/port/BASELINE-REVIEW.md#L364-L367), retrieved 2026-09-05.

### Dominant choice

**Immutable third-party action pins:** use a full 40-character commit SHA plus
same-line `# vX.Y.Z` release comment for every non-exempt remote action outside
`actions/*` and `github/*`; Dependabot proposes updates. GitHub explicitly
recommends SHA pinning for third-party actions, and Dependabot supports the
comment idiom. [GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), [GitHub Dependabot ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories), retrieved 2026-09-05.

### Options

| Name | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| Full SHA + same-line version comment | [GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats) | Rust compiler CI and zizmor CI use SHA-plus-comment references. [Rust CI](https://github.com/rust-lang/rust/blob/main/.github/workflows/ci.yml), [zizmor CI](https://github.com/zizmorcore/zizmor/blob/main/.github/workflows/ci.yml), retrieved 2026-09-05 | GitHub Docs crawled 2026-09-05 |
| Floating major/version tag | [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) | py source's contributors workflow uses `@v1.3.9`. [py source snapshot](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/update-contributors.yml#L27), retrieved 2026-09-05 | GitHub Docs crawled 2026-09-05 |
| Enforced SHA policy with zizmor | [zizmor `unpinned-uses`](https://docs.zizmor.sh/audits/) | zizmor's own CI SHA-pins its actions. [zizmor CI](https://github.com/zizmorcore/zizmor/blob/main/.github/workflows/ci.yml), retrieved 2026-09-05 | zizmor documentation crawled 2026-09-04 |

### Excluded by gate

The pinning-policy alternatives pass all six fitness gates as **inapplicable**:
they are text conventions, not Rust crates, so license, dependency-tree MSRV,
RustSec advisories, target-OS testing, features/runtime coupling, and
binary-size/compile-time cost do not exist for the policy itself. The policy
does not change workflow runtime latency, throughput, or resource use; its
only measurable cost is review work on update pull requests. [GitHub Dependabot version updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates?learn=dependency_version_updates), retrieved 2026-09-05.

`zizmor` is excluded as a required template tool by the MSRV gate. Its current
workspace declares `rust-version = "1.97.0"`, while the current stable compiler
in this research environment is 1.98.0 and the template's stated stable-minus-
two policy therefore requires compatibility with 1.96.0. [zizmor manifest](https://github.com/zizmorcore/zizmor/blob/main/Cargo.toml), retrieved 2026-09-05. Its license gate passes (MIT), its own CI tests Ubuntu/macOS/Windows and thus
passes the OS gate, and its source forbids `unsafe`; RustSec's package endpoint
returned HTTP 404 in this run, so its advisory gate is **unverified**, not
passed. [zizmor manifest](https://github.com/zizmorcore/zizmor/blob/main/Cargo.toml), [zizmor CI](https://github.com/zizmorcore/zizmor/blob/main/.github/workflows/ci.yml), [RustSec endpoint](https://rustsec.org/packages/zizmor.html), retrieved 2026-09-05. Its default `lsp` feature enables a language-server dependency, it couples to Tokio's
multi-thread runtime, and its parser/schema/network dependency set makes
compile time and binary size qualitatively nontrivial. [zizmor crate manifest](https://github.com/zizmorcore/zizmor/blob/main/crates/zizmor/Cargo.toml), retrieved 2026-09-05.

### Up-and-comers

`zizmor` is the credible future enforcement candidate because its
`unpinned-uses` audit understands the distinction between hash and symbolic
references, supports offline detection, and allows per-namespace `hash-pin` or
`ref-pin` policy. It must not be selected as the template's required tool until
its released MSRV is within the template policy and its RustSec advisory result
is successfully verified. [zizmor audit documentation](https://docs.zizmor.sh/audits/), [zizmor manifest](https://github.com/zizmorcore/zizmor/blob/main/Cargo.toml), retrieved 2026-09-05.

### Fit for this template

**CLI:** the example CLI has no special relationship to action pinning; a
compromised workflow can still publish or test it with repository credentials,
so immutable third-party references protect the delivery path without changing
the binary. [GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), retrieved 2026-09-05.

**Library:** consumers inherit workflow files when they fork the template, so
the committed reference must be safe at fork time rather than rely on each
consumer to discover a later tag rewrite. Dependabot converts the resulting
freshness work into visible update pull requests. [GitHub Dependabot version updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates?learn=dependency_version_updates), retrieved 2026-09-05.

**Web service:** deployment, publish, review, and security workflows are more
likely to hold secrets or write privileges than an ordinary local test. The
`tj-actions` incident demonstrated that mutable action references can expose
workflow secrets, so the benefit is greatest on this template shape. [StepSecurity incident report](https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised), retrieved 2026-09-05.

### Recommendation

Adopt **immutable third-party action pins**. For every remote third-party
workflow action except the documented F062 canonical-workflow exemption, write
the action as `owner/repo@<40-hex-sha> # vX.Y.Z`. Keep the existing owner-fixed
`actions/*` and `github/*` major-tag policy unchanged. R19 must retain a
`github-actions` Dependabot update source so SHA pins are refreshed by PRs; R20
does not choose that configuration's grouping or cadence. [GitHub Dependabot ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories), retrieved 2026-09-05.

Do not make `zizmor` required now. Add a repository-local policy test instead;
reconsider `zizmor` only after it passes the MSRV and advisory gates. [zizmor manifest](https://github.com/zizmorcore/zizmor/blob/main/Cargo.toml), [RustSec endpoint](https://rustsec.org/packages/zizmor.html), retrieved 2026-09-05.

### Ranked runner-up

**Floating major/version tags plus Dependabot** is the runner-up only when a
workflow must remain an exact vendor-supplied canonical file and that vendor
does not provide a SHA-pinned variant. That is the narrow F062 condition; it is
not a general third-party policy because the tag remains mutable. [baseline review finding](file:///Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/port/BASELINE-REVIEW.md#L364-L367), [GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), retrieved 2026-09-05.

### Tradeoffs

SHA pins give up the short, recognizable `@v1` form and require an update PR
for every chosen release. The comment restores release traceability and
Dependabot updates it with the SHA, so the ongoing cost is review rather than
manual reference discovery. [GitHub Dependabot comment support](https://github.blog/changelog/2022-10-31-dependabot-now-updates-comments-in-github-actions-workflows-referencing-action-versions/), retrieved 2026-09-05. Tags give up reviewed-byte immutability: a maintainer or attacker
able to move the tag can change the action without changing the workflow.
[GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), retrieved 2026-09-05. A mandatory `zizmor` gate would add independent enforcement but currently
gives up the template's MSRV guarantee and adds a nontrivial Rust toolchain
install; the small local policy test keeps the invariant without those costs.
[zizmor manifest](https://github.com/zizmorcore/zizmor/blob/main/Cargo.toml), retrieved 2026-09-05.

### Parameters

R20 owns no registered parameter and consumes none. No `CONFLICT:` line is
required. The recommendation assumes the owner-fixed `target-os-matrix =
ubuntu-latest, macos-latest` only for evaluating optional enforcement tooling;
the chosen policy itself is platform-independent. [parameter registry](file:///Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/port/PARAMETERS.md), retrieved 2026-09-05.

### Migration implications

1. Add the named pinning policy and its F062 exception to the Rust template's
   workflow-policy documentation or a clearly adjacent implementation comment.
   The exception must name `.github/workflows/difftree-pr-comment.yml` and
   preserve its vendor-canonical byte identity. [baseline review finding](file:///Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/port/BASELINE-REVIEW.md#L364-L367), retrieved 2026-09-05.
2. In every generated `.github/workflows/*.yml` file, convert each
   non-exempt remote `owner/repo@tag` to `owner/repo@<40-hex-sha> # vX.Y.Z`.
   This includes `smorinlabs/contributors-please-action`; it excludes only
   `actions/*`, `github/*`, local paths, and the documented F062 file. [GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), retrieved 2026-09-05.
3. Have R19 configure the `github-actions` Dependabot ecosystem and preserve
   same-line version comments, but do not decide its schedule, groups, or
   auto-merge behavior here. [GitHub Dependabot ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories), retrieved 2026-09-05.
4. Add `scripts/check-third-party-action-pins.sh` (or an equivalent
   repository-local test) and invoke it in CI. It must reject tags, abbreviated
   SHAs, missing comments, and an unapproved exception; it must positively
   accept an official major tag, a 40-hex third-party SHA with a same-line
   comment, and the exact F062 canonical file. This is proposed implementation
   work, not an executed change. [GitHub Dependabot comment support](https://github.blog/changelog/2022-10-31-dependabot-now-updates-comments-in-github-actions-workflows-referencing-action-versions/), retrieved 2026-09-05.

### Validation strategy

Planned checks, after workflows exist:

```sh
scripts/check-third-party-action-pins.sh .github/workflows
```

Expected result: exit 0 only when each in-scope reference has exactly 40
lowercase hexadecimal characters and a same-line release comment, with the
official and F062 exceptions above; each negative fixture exits nonzero. This
is a proposed parser/policy check, not run in this research-only repository.
[GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), retrieved 2026-09-05.

```sh
actionlint .github/workflows/*.yml
```

Expected result: exit 0 for syntactically valid workflows and legitimate
`uses:` forms. This complements rather than proves the pinning policy, because
actionlint validates workflow correctness rather than the selected SHA rule.
This command is proposed and unexecuted. [actionlint checks](https://github.com/rhysd/actionlint/blob/main/docs/checks.md), retrieved 2026-09-05.

For each Dependabot pull request, assert that a changed third-party SHA also
changes its same-line version comment and run the normal CI before merge. This
is a planned integration acceptance check; R19 owns its configuration. [GitHub Dependabot ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories), retrieved 2026-09-05.

### Confidence & re-verify trigger

Confidence: high for the policy choice, because GitHub's first-party security
guidance, its updater behavior, the documented incident, and maintained Rust
CI examples agree on immutable references. [GitHub hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), [GitHub Dependabot ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories), [Rust CI workflow](https://github.com/rust-lang/rust/blob/main/.github/workflows/ci.yml), retrieved 2026-09-05.

Re-verify before implementation if GitHub changes Dependabot's same-line
comment behavior, if the vendor canonical F062 workflow changes its pinning
contract, or if `zizmor` releases an MSRV-compatible version and its RustSec
advisory status can be verified. [GitHub Dependabot ecosystem reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories), [zizmor manifest](https://github.com/zizmorcore/zizmor/blob/main/Cargo.toml), retrieved 2026-09-05.

### Sources

- [GitHub secure-organization hardening guidance](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats), retrieved 2026-09-05.
- [GitHub repository action-policy documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository?apiVersion=2022-11-28), retrieved 2026-09-05.
- [GitHub Dependabot supported-ecosystems reference](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories) and [comment-update changelog](https://github.blog/changelog/2022-10-31-dependabot-now-updates-comments-in-github-actions-workflows-referencing-action-versions/), retrieved 2026-09-05.
- [OpenSSF Scorecard](https://securityscorecards.dev/) and [StepSecurity's `tj-actions/changed-files` incident report](https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised), retrieved 2026-09-05.
- [zizmor audit documentation](https://docs.zizmor.sh/audits/), [crates.io crate endpoint](https://crates.io/api/v1/crates/zizmor), [versions endpoint](https://crates.io/api/v1/crates/zizmor/versions), [manifest](https://github.com/zizmorcore/zizmor/blob/main/Cargo.toml), and [CI workflow](https://github.com/zizmorcore/zizmor/blob/main/.github/workflows/ci.yml), retrieved 2026-09-05.
- [py source snapshot](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/update-contributors.yml#L27), [ts source snapshot](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/workflows/update-contributors.yml#L74), and local [baseline review](file:///Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/port/BASELINE-REVIEW.md#L364-L367), retrieved 2026-09-05.

Method notes: queried `GET https://crates.io/api/v1/crates/zizmor` and
`GET https://crates.io/api/v1/crates/zizmor/versions` with the assigned actor
User-Agent; queried GitHub REST repository endpoints for `zizmorcore/zizmor`,
`rhysd/actionlint`, `rust-lang/cargo`, `tokio-rs/tokio`, and `serde-rs/serde`,
but the shared core rate limit returned HTTP 403, so no repository figures were
invented. The GitHub issue-search endpoint for zizmor succeeded. The required
`https://rustsec.org/packages/zizmor.html` endpoint returned HTTP 404, so open
advisories remain unverified. No crate metrics were collected for the two
pattern candidates because they do not add a crate.
