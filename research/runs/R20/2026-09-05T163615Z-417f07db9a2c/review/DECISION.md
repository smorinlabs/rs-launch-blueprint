# R20 — third-party-action-pinning-policy

## Decision

**Recommendation: adopt the named pattern `enforced-owner-prefix-pinning`.** Every
`uses:` clause in `.github/workflows/` whose owner is neither `actions` nor
`github` is pinned to a full 40-character commit SHA with a trailing release
comment in Dependabot's documented form:

```yaml
- uses: smorinlabs/contributors-please-action@3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1 # v1.3.9
```

This is the TypeScript shape (`ts` D-022(9)), made explicit, scoped by a rule a
machine can evaluate, and gated in CI. It is a **proposal validated in the
implementation phase** (owner ruling, 2026-09-10): this document records what the
research found and what it recommends; P03 builds the template and its CI proves
the recommendation. A decision that does not survive implementation is revised
against this recorded research, not researched again from scratch. What P03 must
validate is listed under `## Engines`.

The pattern has three parts and is incomplete if any one ships without the others.

1. **Format.** `owner/repo@<40-hex> # vX.Y.Z` for every third-party clause.
   `actions/*` and `github/*` remain major-tag-pinned — fixed by this item's
   scope, not by evidence (see the `BASELINE-REVIEW` line below).
2. **Scope rule.** *Third-party* means **owner-prefix**: any `uses:` whose owner
   is neither `actions` nor `github`. `smorinlabs/*`, `googleapis/*` and
   `google/*` are inside that set; there is no owner-trust carve-out. Local
   actions (`./…`) are outside the policy because they are not remote
   dependencies.
3. **Enforcement.** A repository-root `zizmor.yml` declaring
   `rules.unpinned-uses.config.policies` with `"actions/*": ref-pin`,
   `"github/*": ref-pin` and `"*": hash-pin`, plus a CI step running `zizmor`
   over `.github/`. `zizmor` 1.30.1 (MIT, released 2026-09-09) is acquired as a
   **prebuilt release binary**, never `cargo install`-ed on the MSRV toolchain —
   see `## Parameters`.

**Freshness is a prerequisite this item does not decide.** The pattern presumes
R19 (`dependabot-config-shape`) enables the `github-actions` ecosystem so the SHA
pins are advanced by reviewable pull requests. R19 owns the ecosystem list,
schedule, grouping and any cooldown; this item states only that without a
freshness path the pattern degrades into frozen pins. The Opus report's `lead 2`
evidence — a `claude-code-action` permission-model fix shipped in v1.0.94
(2026-04-13) with no actions-ecosystem advisory, verified today against the
GitHub Advisory API — bears on R19's *version-versus-security-only* choice and is
handed to R19 rather than decided here.

**One exemption, expressed per file.** `.github/workflows/difftree-pr-comment.yml`
is a byte-identical copy of the vendor's canonical consumer workflow, whose
inherited value (ledger row F062, `COMMON → REUSE`) is that byte identity. It
carries `smorinlabs/difftree-action@v0`. `BASELINE-REVIEW.md` open question 6
recommends option (a), exempting vendor-canonical templates, "recorded in R20's
decision" — that is a recommendation to the owner, not an owner decision, and
this document records it as such. The empirical check establishes its factual
basis: the vendor file, the py copy at the programme pin and the ts copy at the
programme pin are all 3771 bytes and `diff`-identical, and the vendor's
`examples/` directory publishes no SHA-pinned variant. Two constraints follow.
First, the exemption is **per file**, not per owner:
`smorinlabs/contributors-please-action` stays SHA-pinned. Second, it must be
written as a path-scoped ignore rule in `zizmor.yml`
(`rules.unpinned-uses.ignore: [difftree-pr-comment.yml:63]`), never as an inline
`# zizmor: ignore[unpinned-uses]` comment — an inline comment edits the file and
destroys the byte identity the exemption exists to protect. `BASELINE-REVIEW`
option (c) — ask the maintainer for a SHA-pinned variant — is open today, and the
maintainer is the owner's own org; if such a variant is published, the exemption
is retired rather than kept.

**Ledger rows settled.** `F055` (third-party GitHub Action pinning policy,
verdict `DIVERGENT`) resolves to the ts shape. The row's characterisation of py
as a "floating major-version tag" is imprecise and is corrected here from the
pinned source: at `b08bccfb` py holds 30 third-party `uses:` occurrences, 14
distinct values across 13 distinct action repositories, **zero** SHA pins, and
two ref shapes — 4 floating-major (`astral-sh/setup-uv@v7`,
`extractions/setup-just@v4`, `pyupio/safety-action@v1`,
`smorinlabs/difftree-action@v0`) and the remainder exact patch tags (including
`smorinlabs/contributors-please-action@v1.3.9` at `update-contributors.yml:27`,
the clause the prompt cites). An exact patch tag pins more than a major tag and
is still a mutable ref, so the verdict is unchanged; only the description is.
`F062` is touched, not re-decided: its `COMMON → REUSE` verdict stands and this
item records the exemption that keeps it true.

BASELINE-REVIEW: F055 — reference integrity applies to every `uses:` clause, not
only the third-party half — extend the pinning policy to `actions/*` and
`github/*` (change `"actions/*": ref-pin` to `hash-pin` in `zizmor.yml`) —
evidence: GitHub's *Secure use reference* states no exemption for `actions/*`,
OpenSSF Scorecard's `Pinned-Dependencies` section names no GitHub-owned
exception, zizmor's default since v1.20.0 requires hash-pinning on all actions,
ts already SHA-pins `actions/dependency-review-action` at
`dependency-review.yml:66` at the programme pin, and `astral-sh/uv`,
`astral-sh/ruff` and `zizmorcore/zizmor` hash-pin `actions/*` uniformly. Recorded,
not acted on: the prompt fixes the official half as out of scope, and the change
is one line of `zizmor.yml` if the owner accepts it.

### Principles and implementation

**Shared requirement, source, and agreement level.**

| # | Principle | Source | Agreement level |
|---|---|---|---|
| P1 | Third-party code executing in a credentialed CI job is identified by a reference the upstream cannot silently change | GitHub Docs, [*Secure use reference*](https://docs.github.com/en/actions/reference/security/secure-use): "Pinning an action to a full-length commit SHA is currently the only way to use an action as an immutable release"; "a tag can be moved or deleted if a bad actor gains access to the repository" (retrieved 2026-09-10) | **Policy** — a rule about repository content; identical in py, ts and rs because the mechanism is GitHub's, not the language's |
| P2 | A pin is maintained, not merely set | GitHub Changelog, [*Dependabot now updates comments in GitHub Actions workflows referencing action versions*](https://github.blog/changelog/2022-10-31-dependabot-now-updates-comments-in-github-actions-workflows-referencing-action-versions/), 2022-10-31, retrieved 2026-09-10: the bot rewrites the SHA and its version comment together | **Policy**; its *mechanism* is R19's |
| P3 | The policy is machine-checked | Neither source repo runs a checker that could evaluate a pin format (verified below): py carries no stated pinning rule at the pin and holds three shapes of `astral-sh/setup-uv` at HEAD; ts's stated rule has exactly one deviation, whose status — violation or F062 exemption — is the open question this decision answers | **Capability** — the checker may differ per ecosystem; the observable behavior (CI fails on a non-conforming `uses:`) must agree |
| P4 | The scope rule is stated over action owners | `uses:` carries `owner/repo[/path]@ref`; an owner prefix is the only partition an enforcer can evaluate | **Policy** |

**Essential behaviors.** A conforming repository (a) resolves every third-party
action to one reviewed commit; (b) carries a human-readable release identity next
to each SHA; (c) fails CI on a non-conforming clause; (d) has a bot path that can
advance both the SHA and its comment.

**Observable acceptance criteria.**

1. The enforcer exits non-zero on a workflow where a non-`actions/*`,
   non-`github/*` `uses:` clause carries a tag or branch ref, naming the file and
   line.
2. The enforcer exits zero on the conforming tree, including the one
   path-scoped F062 exemption.
3. Every SHA-pinned clause carries a trailing comment matching
   `# v[0-9]+\.[0-9]+(\.[0-9]+)?`.
4. A Dependabot `github-actions` pull request advances the SHA and the comment
   together (R19's deliverable; asserted here as a prerequisite).

**What must agree, and what may vary.** P1–P4 and criteria 1–4 must agree across
py, ts and rs: nothing about Python, TypeScript or Rust changes how GitHub
resolves a `uses:` ref, so this is accidental drift rather than a justified
ecosystem difference. What may vary is the **enforcer binary** and its
**acquisition channel** — py already runs `rhysd/actionlint@v1.7.12`, which
validates workflow syntax and expressions and has no pin-format audit, so py
would need to add a checker, not swap one. Changes to py and ts remain a
follow-on project; this decision supplies their rationale.

**Architectural alternatives compared** (not merely tool substitution):

| Alternative | What it does | Why it is not the pick |
|---|---|---|
| A. Reference-format policy (SHA pin) | Consumer-side, available today, no upstream cooperation | **Selected.** Complete and enforceable now |
| B. Publisher-side immutability ([GitHub immutable releases](https://github.blog/changelog/2025-10-28-immutable-releases-are-now-generally-available/), GA 2025-10-28, retrieved 2026-09-10) | Makes a tag as strong as a SHA | Requires publisher opt-in and there is **no consumer-side enforcement primitive** — no `uses:` syntax or repository setting requires a ref to resolve to an immutable release. Ranked runner-up |
| C. Inventory reduction (allowlist, vendoring, removal) | An action never run cannot be compromised | Strictly stronger where it applies; does not scale to a template that must demonstrate realistic CI. Composes with A |
| D. Runtime containment (egress filtering) | Limits blast radius *after* malicious code runs | Solves a different principle, adds a third-party action and a hosted dependency. Composes with A |

**Why the selected design preserves each principle.** P1: a 40-hex SHA is the
only ref GitHub will not re-resolve. P2: the comment is what makes the bot's pull
request reviewable and the workflow readable. P3: part 3 turns the criteria into
an executed gate — the part both source repos lack. P4: the policy is literally
written as owner-prefix patterns, so the definition of "third-party" and its
enforcement are the same three lines of configuration.

**Reference implementations.** `astral-sh/uv`, `astral-sh/ruff` and
`zizmorcore/zizmor` hash-pin every `uses:` clause (Opus survey, 2026-09-10);
`ts-launch-blueprint` at `cb1cbcb` SHA-pins 11 of its 12 live third-party clauses
(verified here). The counter-evidence is recorded rather than suppressed:
`tokio-rs/tokio`, `rustls/rustls` and `BurntSushi/ripgrep` ref-pin, and all three
accept `dtolnay/rust-toolchain@master`, a branch pin, which no policy statement
endorses. **The Rust ecosystem has no consensus on pin format**; what discriminates
the two groups in that six-project sample is security posture and recency, not
language, popularity or download volume.

**What this pattern does not claim.** It removes the silent substitution of code
behind an unchanged reference. It does not make CI safe. Three verified classes
sit outside it: fetches below the `uses:` layer (Opus `lead 1`:
`anthropics/claude-code-action`'s `plugin_marketplaces` input accepts only a URL
ending in `.git`, so no ref can be expressed, and the marketplace repository's
default branch is then cloned inside a job holding `id-token: write`); cache and
trigger poisoning; and fixes that ship with no advisory. A template that says
"pinned, therefore safe" states more than this evidence supports.

**Re-verify triggers.** Six events invalidate part of this decision before its
calendar date. GitHub shipping a consumer-side immutable-release enforcement
primitive flips the recommendation to alternative B. The owner accepting
`BASELINE-REVIEW: F055` changes one line of `zizmor.yml`. R19 concluding that the
`github-actions` ecosystem gets security-only updates removes the freshness leg,
and the pattern must then be re-argued rather than patched. zizmor changing the
`unpinned-uses` default or its policy grammar again — the v1.20.0 precedent shows
it happens — requires re-reading `docs/audits.md`. The vendor publishing a
SHA-pinned `difftree-pr-comment.yml` retires the F062 exemption. And any newly
published GitHub Actions tag-compromise incident is a reason to re-read the
practice evidence early.

re-verify: 2027-03-10, or earlier on any trigger listed above

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

R20 owns no registered parameter and consumes none; the prompt's `- owns:` and
`- consumes:` lines are both empty, so no row is added to
`docs/port/PARAMETERS.md` and no `CONFLICT:` line is raised.

How the fixed parameters bear on the decision. `msrv-policy` is the only one that
constrains anything, and it does so through the enforcer rather than the pin
format: zizmor 1.30.1 declares `rust-version = "1.97.0"`, while the current
stable is 1.98.1 (`channel-rust-stable.toml`, manifest date 2026-09-03, retrieved
2026-09-10), which puts the template's floor at 1.96. As a Cargo dependency zizmor
would fail the MSRV gate; it is consumed as a prebuilt release binary and
therefore enters neither `Cargo.toml` nor the MSRV job — which is exactly why the
acquisition channel is part of the recommendation and not an implementation
detail. `target-os-matrix` is satisfied: release v1.30.1 ships x86_64 and aarch64
archives for both `unknown-linux-gnu` and `apple-darwin` (Windows also, not
required), though the audit job itself need run only once on `ubuntu-latest`.
`license` is satisfied — zizmor is MIT, compatible with `MIT OR Apache-2.0`, and
is not linked into the template. `rust-edition` has no bearing on a workflow ref.

## Empirical check

Toolchain and environment, captured at the head of the log: `rustc 1.98.0
(88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0 (797e8a9bc 2026-08-05)
(Homebrew)`, macOS 26.4 (arm64), `gh` 2.98.0. Current stable per
`https://static.rust-lang.org/dist/channel-rust-stable.toml` is `1.98.1
(48a229cea 2026-09-01)`, manifest date 2026-09-03.

Working directory: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Sources
read at their programme pins — py at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`
via `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`, ts at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` via
`git -C ~/c/ts-launch-blueprint show cb1cbcb:<path>`. The py clone's HEAD is
`c1216c6089f768ae0a3f3a465460d2d384f5fa44`, a descendant of the pin; every claim
below states which commit it comes from.

Command (verification only — it reads pinned sources, resolves refs and queries
the recorded endpoints; it builds no workflow, scaffold or fixture):

```sh
bash research/runs/R20/2026-09-05T163615Z-417f07db9a2c/review/evidence/action-pin-verification.sh \
  > research/runs/R20/2026-09-05T163615Z-417f07db9a2c/review/evidence/action-pin-verification.log 2>&1
```

Exit status `0`. Full output:
`research/runs/R20/2026-09-05T163615Z-417f07db9a2c/review/evidence/action-pin-verification.log`;
the script is saved beside it as `action-pin-verification.sh`. Sections
Addendum 1 through Addendum 4 of the log were appended by follow-up commands
during the same session; those commands are now part of the saved script, so a
re-run reproduces the whole log (the addendum section headers are normalized).

Observed, all retrieved 2026-09-10:

1. **py is entirely ref-pinned at the programme pin.** 19 workflow files, 30
   third-party `uses:` occurrences, 14 distinct values, 13 distinct action
   repositories, **0** matches for `@[0-9a-f]{40}`. `publish-container.yml` does
   not exist at the pin. This settles the pinned-source question: the py↔ts
   divergence the ledger records is real at the pin.
2. **py at HEAD (`c1216c60…`) has begun SHA-pinning** — `lint.yml:140` and
   `publish-container.yml:24,49,76` pin `astral-sh/setup-uv@11f9893b… # v8.3.2`,
   and `publish-container.yml:20,43,70` pin the *official*
   `actions/checkout@3d3c42e5… # v7`. `astral-sh/setup-uv` therefore appears in
   three shapes (`@v7`, `@v8.3.2`, `@11f9893b…`) in one repository at HEAD. This
   is evidence of direction of travel **at HEAD only**, not of the pinned state.
   (A first pass of this check used `git grep -E` with `\s`, which git's ERE does
   not honour, and reported no SHA pins at HEAD; the correction is recorded in
   the log's Addendum 1.)
3. **ts at its pin has 12 live third-party clauses, 11 SHA-pinned**; the single
   exception is `smorinlabs/difftree-action@v0` at `difftree-pr-comment.yml:63`.
   A thirteenth is commented out — `ci.yml:115` reads
   `#   uses: codecov/codecov-action@v5` — and is invisible to any YAML-parsing
   linter.
4. **ts SHA-pins an official action at its pin**:
   `actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294 # v5.0.0`
   at `dependency-review.yml:66`.
5. **Neither repo gates on the policy.** `git ls-tree -r --name-only cb1cbcb |
   grep -i zizmor` returns nothing, yet six ts workflows carry comments citing
   zizmor findings by audit name (`ci.yml:57,153`, `codeql.yml:101`,
   `dependency-review.yml:57`, `manual-pr-security-scan.yml:67`,
   `publish.yml:51`). The evidence establishes that zizmor findings were applied
   to those files and that no zizmor configuration or workflow is committed at
   the pin; how often it was run is not established.
6. **The pins resolve to the same code today.**
   `repos/smorinlabs/contributors-please-action/git/ref/tags/v1.3.9` →
   `3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1`, which is exactly the SHA ts pins;
   `refs/tags/v1` currently points at the same commit. py's tag pin and ts's SHA
   pin execute identical code right now — the difference is entirely whether the
   reference *can be moved*, which is the whole of P1.
7. **`actions/dependency-review-action` publishes no `v5` tag but does publish a
   `v5` branch.** `git/ref/tags/v5` returns HTTP 404; `git/ref/heads/v5` returns
   `a1d282b36b6f3519aa1f3fc636f609c47dddb294` — the same commit ts pins. So py's
   `actions/dependency-review-action@v5` at the pin resolves, via a *branch*: the
   weakest ref class, movable by an ordinary push rather than only a force-push.
8. **The F062 exemption's factual basis holds.** The vendor's
   `smorinlabs/difftree-action` `examples/difftree-pr-comment.yml`, py's copy at
   `b08bccfb` and ts's copy at `cb1cbcb` are each 3771 bytes and `diff`-identical.
   The vendor's `examples/` directory contains only that file and a Markdown
   document — no SHA-pinned variant. The vendor does publish a `v0` tag
   (→ `d898da36…`, currently equal to `v0.7.2`), so the tag is a choice, not a
   forced one.
9. **zizmor figures and gates.** crates.io: `recent_downloads` 51,298 (90 d),
   `downloads` 238,904 all-time, newest unyanked `1.30.1` (2026-09-09), license
   MIT. Manifest: `edition = "2024"`, `rust-version = "1.97.0"`. Repo: 6,474
   stars, `archived: false`, `pushed_at` 2026-09-09, 140 open issues. Release
   v1.30.1 ships linux-gnu and apple-darwin archives for x86_64 and aarch64.
   Advisory gate passes on **two corroborating sources**, not on an absence:
   `rustsec.org/packages/zizmor.html` returns 404 while
   `…/openssl.html` and `…/time.html` return 200 (so the 404 discriminates), and
   `gh api "advisories?ecosystem=rust&affects=zizmor"` returns an empty list.
10. **zizmor's policy grammar is as the recommendation assumes.**
    `docs/audits.md` @ `main` documents `rules.unpinned-uses.config.policies` with
    `hash-pin` / `ref-pin` / `any`, "the most specific one is used regardless of
    definition order", and an implicit `"*": hash-pin` for unmatched clauses;
    line 2203 states "Starting with zizmor v1.20.0, the default policy for
    `unpinned-uses` is to require hash-pinning on *all* actions". `docs/usage.md`
    line 834 documents inline `# zizmor: ignore[rulename]` comments **and** the
    `zizmor.yml` `rules.<id>.ignore` list with `workflow.yml[:line[:col]]`
    entries — the path-scoped form the F062 exemption requires.
11. **Dependabot's comment-drift issues are real and partly open.**
    `dependabot-core#7912` open since 2023-08-28, `#14716` open since
    2026-04-14, `#13466` closed.
12. **The GitHub guidance boundary, stated precisely.** On *Secure use reference*
    the sentence "You can help mitigate this risk by following these good
    practices: Pin actions to a full-length commit SHA" sits under the heading
    **"Using third-party actions"**, introduced by "there is significant risk in
    sourcing actions from third-party repositories on GitHub". The page states
    **no exemption for `actions/*`** and offers repository- and organization-level
    policies that "require actions to be pinned to a full-length commit SHA". The
    accurate reading is therefore neither "GitHub draws the same boundary py/ts
    draw" nor "GitHub draws no boundary": the recommendation is *framed* for
    third-party actions and *exempts* nothing. OpenSSF Scorecard's
    `Pinned-Dependencies` section (`checks.md` lines 471-518, read in full)
    contains no occurrence of "third-party", "third party" or "GitHub-owned", so
    its text names no GitHub-owned exception; Scorecard's *implementation* was not
    inspected and no claim is made about it.
13. **Opus's `lead 2` spot-check confirmed.**
    `repos/anthropics/claude-code-action/security-advisories` returns exactly one
    record (`GHSA-8q5r-mmjf-575q` / `CVE-2026-47751`, published 2026-05-20, about
    malicious MCP configuration), and
    `advisories?ecosystem=actions&affects=anthropics/claude-code-action` returns
    the same single record — so no actions-ecosystem advisory covers the v1.0.94
    permission-model fix.

## Engines

- `codex raw/codex-db71a9b72cf03c0f904f06fcdba885ea3bb9dc6c8aa7f5570ee7b1465c881c7a.md`: Codex `gpt-5.6-terra` (`manifest.json`, `operations.codex.actual_model`), collected 2026-09-05; shape check passed; ran no check of its own — its validation strategy is labeled proposed and unexecuted.
- `opus raw/opus-58c5f071d001f86ffd01706183151dd214489bea062095c77d0ef8def72d0495.md`: Claude `claude-opus-5[1m]` (`operations.opus.actual_model`), collected 2026-09-10; shape check passed; executed its own source and endpoint checks, listed in its `Validation strategy`. No Doxa report is required for the Focused tier.

Both engines reach the same format answer — full SHA plus version comment for
third-party actions, kept fresh by Dependabot — from GitHub's own guidance, an
incident record, and the ts precedent. Five substantive disagreements were
settled by evidence, and one by scope.

**Disagreement 1 — the F062 exemption.** Codex records
`BASELINE-REVIEW: F062` and exempts the vendor-canonical
`difftree-pr-comment.yml`; Opus never mentions F062 and reads
`smorinlabs/difftree-action@v0` as an unenforced violation of ts's own policy.
Settled by reading the local ledger and by check 8: `BASELINE-REVIEW.md` open
question 6 does recommend option (a), and the three copies of the file are
byte-identical at 3771 bytes with no SHA-pinned variant published, so the
exemption has a factual basis. Opus is nonetheless right that the two halves
collide unless the exemption is *expressible without editing the file*: check 10
shows zizmor's `rules.<id>.ignore` path syntax provides exactly that, whereas an
inline `# zizmor: ignore[…]` comment would break the byte identity. Both engines'
positions survive, split as per-file (exempt) versus per-owner (never exempt).
`BASELINE-REVIEW.md` is a recommendation to the owner, not an owner decision;
this document records it, and if the owner rejects option (a) the exemption is
deleted and the vendor file diverges by one line.

**Disagreement 2 — is zizmor excluded by the MSRV gate?** Codex excludes it
(`rust-version = 1.97.0` exceeds the 1.96 floor) and proposes a repository-local
shell script instead; Opus calls the gate inapplicable to a prebuilt CI binary.
Settled by the gate's own wording — "crate and dependency-tree MSRV" — which a
release binary is in neither: the gate reads as inapplicable, but only while the
acquisition channel is a release binary, which is why the recommendation names
the channel. Codex's shell script remains the documented fallback if zizmor fails
in P03. Both engines agree the enforcer choice does not change the format
answer, which is the prompt's MEDIUM question answered in the negative.

**Disagreement 3 — what GitHub's guidance actually says.** Opus: the page "draws
no official-vs-third-party boundary". Codex: it "recommends SHA pinning for
third-party actions". Settled by check 12 against the page text: the
recommendation sits under a *third-party* heading and states no exemption for
`actions/*`. Codex's framing is right about where the sentence lives; Opus's is
right about what it excludes, and its stronger phrasing overstates the page.
This decision states both halves rather than either.

**Disagreement 4 — whether the official/third-party split is mechanically
operable.** Opus argues it is not, because
`actions/dependency-review-action` publishes no major tag for a `ref-pin` policy
to point at. Check 7 confirms the tag's absence and **corrects the inference**: a
`refs/heads/v5` branch exists at the same commit ts pins, so `@v5` resolves and a
`ref-pin` policy is satisfied. The rule is operable; what the evidence actually
shows is that satisfying it can silently mean accepting a *branch*, the weakest
ref class. The conclusion Opus draws survives on better grounds than the ones it
used, and the ts inline comment's claim that `@v5` "would fail to resolve on
first run" is false as of today — whether it was true when written is not
established here.

**Disagreement 5 — figures.** Codex reports zizmor at 52,621 recent / 236,005
all-time downloads with newest release 1.30.0 (2026-08-30); Opus reports 51,298 /
238,904 with 1.30.1 (2026-09-09). Both are consistent with their own retrieval
dates (2026-09-05 and 2026-09-10); check 9 re-ran the endpoints today and
reproduces Opus's figures. Codex's RustSec result is recorded as "unverified"
because a bare 404 does not distinguish "no advisory" from "endpoint moved";
check 9 supplies the discrimination Codex lacked and the gate now passes.

**Scope, not disagreement.** Opus raises `BASELINE-REVIEW: F055` (extend the
policy to `actions/*`) and would prefer blanket hash-pinning on the merits; Codex
stays inside the prompt's scope. The prompt fixes the official half as out of
scope, so the finding is recorded in `## Decision` and not acted on. Neither
engine decides R19's cooldown or version-versus-security-only question, and
neither should.

**Unproven, left for P03 to prove in the real template.**

1. **That zizmor's policy map produces the intended verdicts.** Nothing here ran
   zizmor: the template does not exist, and running it would require building the
   thing being recommended. What would prove it: a conforming
   `.github/workflows/` tree plus `zizmor.yml`; assert `zizmor .github/` exits 0;
   rewrite one third-party clause from `@<sha> # v1.3.9` to `@v1.3.9` and assert
   a non-zero exit with an `unpinned-uses` finding naming that file and line.
   Assert the exit code, not the message text. The negative half is the one that
   matters — a gate never observed to fail has not been validated.
2. **That the F062 path-scoped ignore behaves as documented** — that
   `rules.unpinned-uses.ignore` accepts `difftree-pr-comment.yml:63`, suppresses
   exactly that finding, and leaves the file byte-identical to the vendor's. The
   grammar is documented (check 10); its behavior on this file is untested.
3. **That the `"actions/*": ref-pin` → `hash-pin` switch is a one-line change**,
   the migration path for `BASELINE-REVIEW: F055`.
4. **That a Dependabot `github-actions` pull request advances the SHA and the
   comment together** in this repository. `#7912` and `#14716` are open, so the
   failure mode is live; the cheap guard is a CI assertion that every SHA-pinned
   clause carries a trailing `# vX.Y.Z`, which catches a dropped comment but
   cannot catch a wrong one. Depends on R19.
5. **How the enforcer treats `docker://` `uses:` clauses and reusable-workflow
   `uses:` references.** Neither raw verified either, and the current inventory
   contains no Docker action; both are outside what this evidence covers rather
   than covered by it.
6. **The rs action inventory itself.** No Rust template exists yet, so the
   migration scope is projected from the py and ts inventories. Likely rs-only
   entries — `Swatinem/rust-cache`, `taiki-e/install-action`,
   `dtolnay/rust-toolchain` or `actions-rust-lang/setup-rust-toolchain` — are
   named as a projection, not as an inventory.

**Carried from Opus without independent re-verification** (its retrieval date,
2026-09-10, and its sourcing): the Aqua Security post-mortem of the 2026-03-19
`aquasecurity/trivy-action` tag force-push (76 of 77 tags per the vendor; 75 of
76 per secondary coverage), the six-project Rust practice survey, and `lead 1`'s
reading of `install-plugins.ts`. The TanStack May 2026 cache-poisoning incident is
recorded by Opus as secondary-source-only and no part of this decision rests on
it.

**Sources.** URLs and retrieval dates, carried over from the raws and re-retrieved
by the empirical check unless noted. Platform and standards guidance: GitHub Docs,
[*Secure use reference*](https://docs.github.com/en/actions/reference/security/secure-use)
(2026-09-10); GitHub Changelog,
[Dependabot comment updating](https://github.blog/changelog/2022-10-31-dependabot-now-updates-comments-in-github-actions-workflows-referencing-action-versions/)
(2022-10-31, retrieved 2026-09-10) and
[immutable releases GA](https://github.blog/changelog/2025-10-28-immutable-releases-are-now-generally-available/)
(2025-10-28, retrieved 2026-09-10); GitHub Docs,
[managing GitHub Actions settings for a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)
(the repository- and organization-level SHA-pinning policies, via Codex,
2026-09-05); OpenSSF Scorecard
[`docs/checks.md`](https://raw.githubusercontent.com/ossf/scorecard/main/docs/checks.md),
`Pinned-Dependencies` (2026-09-10). Enforcement tooling: zizmor
[`docs/audits.md`](https://raw.githubusercontent.com/zizmorcore/zizmor/main/docs/audits.md)
and [`docs/usage.md`](https://raw.githubusercontent.com/zizmorcore/zizmor/main/docs/usage.md)
@ `main`, [`Cargo.toml`](https://raw.githubusercontent.com/zizmorcore/zizmor/main/Cargo.toml),
`GET https://crates.io/api/v1/crates/zizmor` and `/versions`,
`GET https://api.github.com/repos/zizmorcore/zizmor` and `/releases/latest`,
`GET "https://api.github.com/search/issues?q=repo:zizmorcore/zizmor+is:issue+is:open"`,
`https://rustsec.org/packages/zizmor.html` (404, discriminated against
`…/openssl.html` and `…/time.html`, both 200) and
`GET "https://api.github.com/advisories?ecosystem=rust&affects=zizmor"` (empty) —
all 2026-09-10; `rhysd/actionlint`
[`docs/checks.md`](https://github.com/rhysd/actionlint/blob/main/docs/checks.md)
(via Codex, 2026-09-05), which has no pin-format audit. Ref resolution:
`GET https://api.github.com/repos/smorinlabs/contributors-please-action/git/ref/tags/v1.3.9`,
`…/actions/dependency-review-action/git/ref/tags/v5` (404) and `…/git/ref/heads/v5`,
`…/smorinlabs/difftree-action/git/matching-refs/tags`,
`…/smorinlabs/difftree-action/contents/examples/difftree-pr-comment.yml` — all
2026-09-10. Dependabot comment drift:
`GET https://api.github.com/repos/dependabot/dependabot-core/issues/{7912,13466,14716}`
(2026-09-10). Incidents and research, carried from Opus at its 2026-09-10
retrieval and not re-retrieved here: Aqua Security,
[*Trivy supply chain attack*](https://www.aquasec.com/blog/trivy-supply-chain-attack-what-you-need-to-know/);
RyotaK / GMO Flatt Security,
[*Poisoning Claude Code*](https://flatt.tech/research/posts/poisoning-claude-code-one-github-issue-to-break-the-supply-chain/)
(2026-06-01); ENOSUCHBLOG,
[*We should all be using dependency cooldowns*](https://blog.yossarian.net/2025/11/21/We-should-all-be-using-dependency-cooldowns)
(2025-11-21); StepSecurity's
[`tj-actions/changed-files` incident report](https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised)
(via Codex, 2026-09-05). `anthropics/claude-code-action` advisory spot-check:
`GET https://api.github.com/repos/anthropics/claude-code-action/security-advisories`
and `GET "https://api.github.com/advisories?ecosystem=actions&affects=anthropics/claude-code-action"`
(2026-09-10). Toolchain:
`https://static.rust-lang.org/dist/channel-rust-stable.toml` (2026-09-10). Local:
`docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md:61` (F055), `:68` (F062),
`docs/port/areas/ci-workflows.md:54` and `:66`, `docs/port/BASELINE-REVIEW.md`
open question 6; py at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and ts at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, both read from the local pinned
clones (the ts GitHub repository is private).
