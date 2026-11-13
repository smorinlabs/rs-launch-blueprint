# R20 — third-party-action-pinning-policy (revision 2, 2026-09-10)

**Revision note.** Revision 2 rewrites revision 1 (sha256
`248ee192ce441523759266f5a24b76507947c514dfe0e7141af931d245c908e7`) in place. It
answers the two findings of the revision-1 empirical audit
(`review/audit-codex.r1.md`, actor `audit-codex-2026-09-05T163615Z-417f07db9a2c-r1`,
model `gpt-5.6-terra`, family openai, verdict reject), both of which were the same
defect — a claim wider than its evidence — in two places.

*F1: the declared gate did not enforce the declared comment format.* Revision 1
required `owner/repo@<40-hex> # vX.Y.Z`, made that grammar acceptance criterion 3,
and named a `zizmor.yml` policy map plus one `zizmor .github/` invocation as the
complete enforcement. Verified at zizmor's pinned tag `v1.30.1` (observations 14
and 15 below), that invocation does not check the comment at all in the case that
matters: the `unpinned-uses` audit never mentions comments, and the
`ref-version-mismatch` audit reports a *missing* comment only under
`--persona=pedantic`, which is not the default. Revision 2 takes the first of the
two ways out the audit allowed — **add a check that enforces the grammar, name it
concretely, and pair it with the pass and fail cases P03 must test**. Part 3 of
the pattern is now two checks with disjoint jobs, criterion 3 names the check that
enforces it, and one regular expression is quoted verbatim everywhere the grammar
appears. Choosing this over narrowing the criterion to a convention: the comment
is the whole of principle P2 (a pin is maintained, not merely set) and of
essential behavior (b); demoting it to an unenforced convention would leave P2
with no observable criterion, and revision 1 had already identified the check as
"the cheap guard" under its own unproven list, so the honest move was to promote
it into the recommendation rather than to drop the requirement. The grammar
itself is widened from `# vX.Y.Z` to the exact shape the check accepts, because
upstream tags are not all v-prefixed three-component semver — evidence in
observation 15.

*F2: the reproduction claim was false as written.* Revision 1 said a re-run of
the saved script reproduces the whole evidence log apart from normalised headings;
the auditor reran it and found the four addenda materially reduced. Revision 2
restores every omitted command, heading, byte count, full value list,
commented-out-clause probe and prefix-match probe to
`review/evidence/action-pin-verification.sh`, reruns it to a new log
`review/evidence/action-pin-verification.r2.log` (exit 0), and states the
reproduction relation as a counted, checkable comparison rather than as
"the whole log". The revision-1 log is left untouched.

Nothing the audit confirmed was reworded: the pinned-tree counts for both source
repositories, the exemption's shape, and the four `assumes` lines under
`## Parameters`.

## Decision

**Recommendation: adopt the named pattern `enforced-owner-prefix-pinning`.** Every
`uses:` clause in `.github/workflows/` whose owner is neither `actions` nor
`github` is pinned to a full 40-character commit SHA, and every SHA-pinned clause
of any owner carries a trailing release comment in Dependabot's documented form:

```yaml
- uses: smorinlabs/contributors-please-action@3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1 # v1.3.9
```

This is the TypeScript shape (`ts` D-022(9)), made explicit, scoped by a rule a
machine can evaluate, and gated in CI by **two** checks with disjoint jobs — the
SHA-pin rule and the comment rule are not enforced by the same command, and part 3
below says which command enforces which. It is a **proposal validated in the
implementation phase** (owner ruling, 2026-09-10): this document records what the
research found and what it recommends; P03 builds the template and its CI proves
the recommendation. A decision that does not survive implementation is revised
against this recorded research, not researched again from scratch. What P03 must
validate is listed under `## Engines`.

The pattern has three parts and is incomplete if any one ships without the
others; part 3 is itself two checks, and is incomplete if either ships alone.

1. **Format.** `owner/repo@<40-hex> # vX.Y.Z` for every third-party clause. The
   `# vX.Y.Z` shown here is the **house convention** — write the upstream tag,
   and all 19 version comments on SHA-pinned clauses in the two source
   repositories today are v-prefixed — the 12 ts lines are printed in section 11a
   of `action-pin-verification.r2.log`, the 7 py lines in Addendum 1 of both
   logs. The **enforced contract** is deliberately wider, because upstream tags
   are not all v-prefixed
   three-component semver (observation 15: py at HEAD carries `# v7`; zizmor's own
   `ref-version-mismatch` test data accepts `# 2.7.0` with no `v`), and because
   Dependabot rewrites the comment to whatever the upstream tag is rather than to
   a normalised form. **The enforced contract is this extended regular
   expression, and it is the same expression everywhere it appears in this
   document:**

   ```
   @[0-9a-f]{40}[[:space:]]+#[[:space:]]v?[0-9]+(\.[0-9]+)*[[:space:]]*$
   ```

   In words: the 40-hex pin, whitespace, `#`, one space, an optional `v`, then a
   dot-separated run of digits, then end of line. It accepts `# v1.3.9`, `# v7`
   and `# 2.7.0`; it rejects a missing comment, `# pinned by hand`,
   `#v1.3.9 no space` and `# release 1.3.9`. Executed against both, pass and
   fail, under `## Empirical check` section 11.
   `actions/*` and `github/*` remain major-tag-pinned — fixed by this item's
   scope, not by evidence (see the `BASELINE-REVIEW` line below).
2. **Scope rule.** *Third-party* means **owner-prefix**: any `uses:` whose owner
   is neither `actions` nor `github`. `smorinlabs/*`, `googleapis/*` and
   `google/*` are inside that set; there is no owner-trust carve-out. Local
   actions (`./…`) are outside the policy because they are not remote
   dependencies. **The comment rule has a different scope from the SHA-pin
   rule**: it applies to *every* SHA-pinned clause, whatever the owner, because a
   voluntarily SHA-pinned `actions/*` clause (ts has one, at
   `dependency-review.yml:66`) needs the release identity for exactly the same
   reason a third-party one does.
3. **Enforcement — two checks, disjoint jobs.**
   1. *The SHA-pin rule* is enforced by a repository-root `zizmor.yml` declaring
      `rules.unpinned-uses.config.policies` with `"actions/*": ref-pin`,
      `"github/*": ref-pin` and `"*": hash-pin`, plus a CI step running `zizmor`
      over `.github/`. `zizmor` 1.30.1 (MIT, released 2026-09-09) is acquired as
      a **prebuilt release binary**, never `cargo install`-ed on the MSRV
      toolchain — see `## Parameters`. The same invocation additionally reports a
      version comment that is *present but does not resolve to the pinned
      commit*, through the separate `ref-version-mismatch` audit, at the default
      persona — read from that audit's own test-data labels rather than executed
      here (observation 15), and therefore listed as unproven item 1a for P03.
   2. *The comment rule* is enforced by a repository-local script — proposed name
      `scripts/check-action-pin-comments.sh`, written by P03 — that reports every
      SHA-pinned `uses:` line in `.github/workflows/` not matching the extended
      regular expression quoted in part 1 and exits non-zero if there is any. It
      is a text check over workflow files, needs no network and no token, and is
      the same shape as the fallback Codex proposed for the pin rule (see
      `## Engines`, disagreement 2) — but it is a *second* check, not that
      fallback: the two never enforce the same rule.

   **Why not simply `zizmor --persona=pedantic .github/` instead of the script.**
   Three reasons, all verified at tag `v1.30.1` (observations 14, 15): the
   pedantic persona is a *global* sensitivity switch that turns on code-smell
   findings across every audit — zizmor's own documentation illustrates it with a
   `template-injection` finding on an expansion that is not attacker-controllable
   — so adopting it to gain one check imports unrelated CI failures; zizmor has no
   per-audit persona setting (`rules.<id>` supports `disable`, `ignore`, `config`
   and `remap.severity`, and nothing else); and even under `pedantic` the audit
   does not establish this document's grammar, because its own test data records
   `# 2.7.0` as *no finding*. The two checks are complementary rather than
   redundant, and section 11e of the empirical check demonstrates the gap in the
   other direction: a line whose grammar conforms can still be a
   `ref-version-mismatch` finding.

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
| P3 | The policy is machine-checked | Neither source repo runs a checker that could evaluate a pin format (verified below): py carries no stated pinning rule at the pin and holds three shapes of `astral-sh/setup-uv` at HEAD; ts's stated rule has exactly one deviation, whose status — violation or F062 exemption — is the open question this decision answers | **Capability** — the checker may differ per ecosystem, and more than one checker may be needed (this recommendation uses two, part 3); what must agree is the observable behavior, CI failing on a non-conforming `uses:`, for each of the two non-conformances criteria 1 and 3 name |
| P4 | The scope rule is stated over action owners | `uses:` carries `owner/repo[/path]@ref`; an owner prefix is the only partition an enforcer can evaluate | **Policy** |

**Essential behaviors.** A conforming repository (a) resolves every third-party
action to one reviewed commit; (b) carries a human-readable release identity next
to each SHA; (c) fails CI on a clause non-conforming in either respect — (a) is
checked by `zizmor`, (b) by the comment-grammar script, and neither command
checks the other's rule; (d) has a bot path that can advance both the SHA and its
comment.

**Observable acceptance criteria.** Each names the command that produces the
observation, because revision 1's criterion 3 named a behavior no declared command
had.

1. **`zizmor .github/`** exits non-zero on a workflow where a non-`actions/*`,
   non-`github/*` `uses:` clause carries a tag or branch ref, naming the file and
   line.
2. **`zizmor .github/`** exits zero on the conforming tree, including the one
   path-scoped F062 exemption.
3. **`scripts/check-action-pin-comments.sh`** exits zero on the conforming tree
   and non-zero, listing the offending lines, on a tree where any SHA-pinned
   `uses:` line — of any owner — fails to match
   `@[0-9a-f]{40}[[:space:]]+#[[:space:]]v?[0-9]+(\.[0-9]+)*[[:space:]]*$`, the
   extended regular expression fixed in part 1 of `## Decision`. This criterion
   is about the comment's *shape*, not its truth: a comment that conforms but
   names the wrong release is criterion 3a's business, not this one's.
   3a. **`zizmor .github/`** exits non-zero, through its `ref-version-mismatch`
   audit at the default persona, when a present version comment does not resolve
   to the pinned commit.
4. A Dependabot `github-actions` pull request advances the SHA and the comment
   together (R19's deliverable; asserted here as a prerequisite).

**What must agree, and what may vary.** P1–P4 and criteria 1–4 must agree across
py, ts and rs: nothing about Python, TypeScript or Rust changes how GitHub
resolves a `uses:` ref, so this is accidental drift rather than a justified
ecosystem difference. What may vary is the **set of enforcer binaries** and their
**acquisition channels** — the criteria fix the observable behaviors, not the
number of commands that produce them, and this recommendation needs two because no
single available checker covers both rules. py already runs
`rhysd/actionlint@v1.7.12`, which validates workflow syntax and expressions and
has no pin-format audit, so py would need to add checkers, not swap one. Changes
to py and ts remain a follow-on project; this decision supplies their rationale.

**Architectural alternatives compared** (not merely tool substitution):

| Alternative | What it does | Why it is not the pick |
|---|---|---|
| A. Reference-format policy (SHA pin) | Consumer-side, available today, no upstream cooperation | **Selected.** Complete, and enforceable now by the two checks of part 3 — the SHA-pin half by an off-the-shelf tool, the comment half by a repository-local text check |
| B. Publisher-side immutability ([GitHub immutable releases](https://github.blog/changelog/2025-10-28-immutable-releases-are-now-generally-available/), GA 2025-10-28, retrieved 2026-09-10) | Makes a tag as strong as a SHA | Requires publisher opt-in and there is **no consumer-side enforcement primitive** — no `uses:` syntax or repository setting requires a ref to resolve to an immutable release. Ranked runner-up |
| C. Inventory reduction (allowlist, vendoring, removal) | An action never run cannot be compromised | Strictly stronger where it applies; does not scale to a template that must demonstrate realistic CI. Composes with A |
| D. Runtime containment (egress filtering) | Limits blast radius *after* malicious code runs | Solves a different principle, adds a third-party action and a hosted dependency. Composes with A |

**Why the selected design preserves each principle.** P1: a 40-hex SHA is the
only ref GitHub will not re-resolve. P2: the comment is what makes the bot's pull
request reviewable and the workflow readable, and part 3's second check is what
keeps the comment from being optional in practice. P3: part 3 turns criteria 1,
2, 3 and 3a into executed gates — the part both source repos lack — with each
criterion attached to the command that produces it, so no criterion is asserted
without an enforcer. P4: the *pin* policy is literally written as owner-prefix
patterns, so the definition of "third-party" and its enforcement are the same
three lines of configuration; the *comment* rule is not owner-partitioned at all
and needs no patterns.

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

**Re-verify triggers.** Seven events invalidate part of this decision before its
calendar date. GitHub shipping a consumer-side immutable-release enforcement
primitive flips the recommendation to alternative B. The owner accepting
`BASELINE-REVIEW: F055` changes one line of `zizmor.yml`. R19 concluding that the
`github-actions` ecosystem gets security-only updates removes the freshness leg,
and the pattern must then be re-argued rather than patched. zizmor changing the
`unpinned-uses` default or its policy grammar again — the v1.20.0 precedent shows
it happens — requires re-reading `docs/audits.md`. zizmor moving the
`ref-version-mismatch` missing-comment case out of the pedantic persona, or making
personas settable per audit, would let one command cover both rules and retires
part 3's second check — the trigger to re-read is that audit's section of
`docs/audits.md` together with `docs/configuration.md`. The vendor publishing a
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
constrains anything, and it does so through one of the two enforcers — zizmor,
part 3.1 — rather than through the pin format; part 3.2's comment check is a
repository-local shell script with no Rust toolchain of its own and no MSRV to
speak of. zizmor 1.30.1 declares `rust-version = "1.97.0"`, while the current
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

Toolchain and environment, captured at the head of both logs: `rustc 1.98.0
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

Command (verification only — it reads pinned sources, resolves refs, queries the
recorded endpoints, and runs a text check over sample `uses:` lines; it builds no
workflow, scaffold or fixture, installs nothing, and never invokes `zizmor`):

```sh
bash research/runs/R20/2026-09-05T163615Z-417f07db9a2c/review/evidence/action-pin-verification.sh \
  > research/runs/R20/2026-09-05T163615Z-417f07db9a2c/review/evidence/action-pin-verification.r2.log 2>&1
```

Exit status `0`, run 2026-09-10T15:23:30Z. Two logs sit in `review/evidence/`, and
they are not interchangeable:

- `action-pin-verification.log` — the revision-1 session log. Observations 1
  through 13 below were read from it. It is left byte-for-byte as it was.
- `action-pin-verification.r2.log` — the revision-2 re-run of the saved script,
  the command above. Observations 14 and 15 were read from it.

**What the saved script reproduces, stated as a counted comparison rather than as
"the whole log".** Revision 1 claimed a re-run reproduced the whole log apart from
normalised headings; the revision-1 audit reran it and found the four addenda
materially reduced, and the audit was right. Revision 2 restored the omitted
commands, headings, byte counts, full distinct-value listings, commented-out-clause
probe and prefix-match probe. The claim now made is this — truncate
`action-pin-verification.r2.log` at the first line of the revision-2-only
section 10 and `diff -u` the result against `action-pin-verification.log`:

```sh
cd research/runs/R20/2026-09-05T163615Z-417f07db9a2c/review/evidence
awk '/^===== 10\. what zizmor/{exit} {print}' action-pin-verification.r2.log \
  | diff -u action-pin-verification.log - \
  | grep '^[-+]' | grep -v '^[-+][-+]' | wc -l
```

**28 lines differ, and none of them is an observed value.** The 28 are the UTC
timestamp line (2 lines); one `curl` progress
message whose byte count is a transfer artifact (2 lines); the four `ADDENDUM n`
headings, whose revision-1 form carried a wall-clock time (8 lines); fourteen
lines that revision 1 lacked and revision 2 adds, every one of them an addition,
because revision 1's `awk` truncated the OpenSSF Scorecard `Pinned-Dependencies`
section and the restored script prints that section in full; and a
trailing-newline difference on the final line (2 lines). Sections 10 and 11
are new in revision 2 and have no counterpart in the revision-1 log. Byte identity
is not claimed and is not achievable: the script queries live endpoints, so a
future re-run will differ wherever a live figure has moved — observation 9's
download counts are the clearest example, and they happened not to move between
the two runs recorded here.

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
10. **zizmor's policy-map syntax and its ignore-list syntax are as the
    recommendation assumes.** This observation covers those two things only; what
    the tool does about the *version comment* is observation 14's subject, and
    revision 1 wrongly read this observation as covering that too.
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

Observations 14 and 15 were added for revision 2, from
`action-pin-verification.r2.log` sections 10 and 11. They read zizmor's
documentation and test data at the **pinned tag `v1.30.1`** — the version this
decision recommends — rather than at `main`, which is what observation 10 read;
the two agree on everything they both cover, and the line numbers quoted in
observation 10 are `main`'s.

14. **What `zizmor .github/` enforces about the version comment, at tag
    `v1.30.1`.** The `unpinned-uses` audit's documentation section contains **no
    occurrence of the word "comment"** — it is entirely about the ref. The
    comment is the business of a *different* audit, `ref-version-mismatch`
    (introduced v1.14.0), which "detects `uses:` clauses where a hash-pinned
    action's version comment … is mismatched with the pinned commit, or missing
    entirely" — but with this sentence attached: "**Missing version comments are
    reported only with the pedantic persona.**" The default persona is `regular`
    (`docs/usage.md` @ `v1.30.1`, the "Using personas" section: the regular
    persona "is best for ordinary local use as well as use in most CI/CD setups,
    **which is why it's the default**"). Therefore the invocation revision 1
    declared — plain `zizmor .github/` — accepts a SHA-pinned clause carrying no
    comment at all. This is the finding that revision 2 answers, and it is the
    reason part 3 now names a second check. Two further facts bound the
    alternatives: `docs/configuration.md` @ `v1.30.1` documents exactly four
    per-audit settings (`rules.<id>.disable`, `.ignore`, `.config`,
    `.remap.severity`) and **no per-audit persona**, so pedantic cannot be turned
    on for this one audit; and the pedantic persona is documented as a global
    sensitivity switch, illustrated in the same page by a `template-injection`
    finding on an expansion that is not attacker-controllable.
15. **The comment grammar, and what the proposed check does with it.** zizmor's
    own `ref-version-mismatch` test data
    (`crates/zizmor/tests/integration/test-data/ref-version-mismatch.yml` @
    `v1.30.1`, 34 lines, each case labelled by the maintainers) settles the
    grammar question: line 34, `# 2.7.0` with no `v` prefix, is labelled "**No
    finding, comment matches (even without v prefix)**". So not even the pedantic
    persona establishes revision 1's exact `# vX.Y.Z` form. The same file
    separates the two jobs cleanly: lines 16 and 19 (missing comment,
    non-version comment) are labelled *pedantic* findings, while lines 25 and 28
    (a comment naming the wrong release, and one naming no known tag) are
    labelled plain findings — the default-persona behavior criterion 3a rests on.
    The check proposed in part 3 was then run against samples, with its exit
    status recorded (section 11 of `action-pin-verification.r2.log`; it is a `grep`
    pipeline, nothing was
    installed and no tree was built). Pass: all 12 SHA-pinned `uses:` lines of ts
    at `cb1cbcb` — the 11 third-party ones plus the official
    `actions/dependency-review-action` line — exit `0`. Pass: all 7 SHA-pinned
    lines of py at HEAD `c1216c60`, which include `# v7`, a bare major, exit `0`.
    Fail: four synthetic lines, one per non-conforming shape (no comment,
    `# pinned by hand`, `#v1.3.9 no space`, `# release 1.3.9`) exit `1` with all
    four listed. Accept, deliberately: `# v7`, `# v5.0.0` and `# 2.7.0`. And the
    limit of the check, shown rather than asserted: the line
    `actions/setup-node@1a4442ca… # v3.8.1` passes the grammar check with exit
    `0`, yet is exactly the line zizmor's test data marks a `ref-version-mismatch`
    finding at line 25 — which is why part 3 keeps both checks and criterion 3
    disclaims the comment's truth.

## Engines

- `codex raw/codex-db71a9b72cf03c0f904f06fcdba885ea3bb9dc6c8aa7f5570ee7b1465c881c7a.md`: Codex `gpt-5.6-terra` (`manifest.json`, `operations.codex.actual_model`), collected 2026-09-05; shape check passed; ran no check of its own — its validation strategy is labeled proposed and unexecuted.
- `opus raw/opus-58c5f071d001f86ffd01706183151dd214489bea062095c77d0ef8def72d0495.md`: Claude `claude-opus-5[1m]` (`operations.opus.actual_model`), collected 2026-09-10; shape check passed; executed its own source and endpoint checks, listed in its `Validation strategy`. No Doxa report is required for the Focused tier.

Both engines reach the same format answer — full SHA plus version comment for
third-party actions, kept fresh by Dependabot — from GitHub's own guidance, an
incident record, and the ts precedent. Five substantive disagreements were
settled by evidence, and one by scope.

**A gap neither engine covered, found by the revision-1 audit.** Neither raw
report asked what any checker actually enforces about the *comment*, as distinct
from the ref: Codex proposed a policy map and a shell fallback for the pin rule,
Opus surveyed practice and pinning policy, and both treated "SHA plus version
comment" as one indivisible format with one gate behind it. Revision 1 inherited
that and named `zizmor .github/` as the complete enforcement of both halves. The
revision-1 audit read the tool's documentation and test data and found the two
halves come apart; observations 14 and 15 confirm the audit's reading at tag
`v1.30.1`, and part 3 of `## Decision` now splits the enforcement to match. This
is recorded here rather than in a disagreement because the engines did not
disagree — they agreed, and agreement was not evidence of fitness.

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
the channel. Codex's shell script remains the documented fallback **for the
SHA-pin rule only**, to be reached for if zizmor fails in P03; it is not the
comment-grammar script of part 3.2, which is a second check for a rule zizmor does
not cover rather than a replacement for zizmor. If both the fallback and the
grammar check were ever needed at once they would be two scripts with two rules,
not one script doing two jobs. Both engines agree the enforcer choice does not
change the format answer, which is the prompt's MEDIUM question answered in the
negative.

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
1a. **That criterion 3a's default-persona behavior holds in the real tree** —
   that `zizmor .github/`, with no `--persona` flag, exits non-zero on a clause
   whose comment names the wrong release. The maintainers' own test data labels
   that case a plain finding rather than a pedantic one (observation 15), which is
   documentation, not an execution. Related and also unproven: whether the
   mismatch half of `ref-version-mismatch` operates without network access or a
   GitHub token in CI. The audit's documentation table marks it "works offline",
   yet resolving a tag to a commit is inherently an online question; this decision
   asserts neither reading. What would prove it: run the audit over the conforming
   tree twice, once with a token and once with `--no-online-audits`, and compare
   the findings.
1b. **That the comment-grammar check of part 3.2 behaves the same over a real
   tree as it did over the sample lines.** Section 11 fed it lines extracted from
   the two pinned source repositories and four synthetic lines, and recorded its
   exit status; it has never walked a `.github/workflows/` directory. The pass and
   fail cases P03 must test are exactly the ones section 11 executed, restated as
   tree-level tests: **pass** — the conforming tree exits `0`, including the F062
   exemption file, whose two `uses:` clauses (`actions/checkout@v6` at line 48 and
   `smorinlabs/difftree-action@v0` at line 63) are both ref-pinned rather than
   SHA-pinned and so are not the comment rule's business at all; **fail** — with
   the SHA kept, delete the trailing comment from
   one clause and assert exit non-zero with that file and line listed; **fail** —
   replace the comment with `# release 1.3.9` and assert exit non-zero; **pass** —
   replace it with `# 2.7.0` and assert exit `0`, which is the case that pins the
   grammar's intended width and would catch a future narrowing of the regular
   expression to a v-prefix. Assert the exit code and the reported line, not the
   message wording. The negative cases are the ones that matter. One design
   question P03 must settle rather than inherit: the check is a text check, not a
   YAML parser, so unlike the linters observation 3 discusses it *does* see
   commented-out clauses such as `ci.yml:115`'s `#   uses: codecov/codecov-action@v5`
   — P03 decides whether it skips lines whose first non-blank character is `#`,
   and the decision here is only that the behavior must be chosen deliberately and
   covered by a test either way.
2. **That the F062 path-scoped ignore behaves as documented** — that
   `rules.unpinned-uses.ignore` accepts `difftree-pr-comment.yml:63`, suppresses
   exactly that finding, and leaves the file byte-identical to the vendor's. The
   *ignore-list* syntax is documented (check 10) — a different thing from the
   comment grammar of part 1; its behavior on this file is untested.
3. **That the `"actions/*": ref-pin` → `hash-pin` switch is a one-line change**,
   the migration path for `BASELINE-REVIEW: F055`.
4. **That a Dependabot `github-actions` pull request advances the SHA and the
   comment together** in this repository. `#7912` and `#14716` are open, so the
   failure mode is live. Revision 1 described the guard against it — a CI
   assertion that every SHA-pinned clause carries a trailing version comment — as
   a cheap thing that could be added; revision 2 makes it part 3.2 of the
   recommendation, so what remains unproven here is only the bot's behavior, not
   the guard's existence. The division of labour against this failure mode is:
   part 3.2 catches a *dropped* comment, criterion 3a catches a *stale* one, and
   neither can make the bot rewrite the pair correctly. Depends on R19.
4a. **Whether an upstream this template pins ever publishes a tag the grammar
   rejects.** The regular expression in part 1 accepts an optional `v` and a
   dot-separated run of digits; a tag such as `2026.09.1-rc1` or `release-7`
   would fail it, and Dependabot writes the upstream tag rather than a normalised
   form. No pin in either source repository has that shape today (observation 15
   fed all 19 SHA-pinned lines from both repositories through the check and none
   failed), and the concrete near-miss already in evidence is zizmor's own test
   data, whose `# 2.7.0` the grammar deliberately accepts. What would prove the
   remaining risk absent: run the check over the real rs inventory once it exists,
   and re-run it after the first Dependabot pull request lands. If a legitimate
   tag is ever rejected, the fix is to widen the regular expression in part 1 and
   in criterion 3 together — they are one expression and must not drift apart.
5. **How either enforcer treats `docker://` `uses:` clauses and
   reusable-workflow `uses:` references** — zizmor's policy map on the one hand,
   and part 3.2's line check, whose regular expression assumes an `owner/repo@sha`
   shape, on the other. Neither raw verified either, and the current inventory
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
@ `main` (observations 9–10, 2026-09-10) and the same two files plus
[`docs/configuration.md`](https://raw.githubusercontent.com/zizmorcore/zizmor/v1.30.1/docs/configuration.md)
and the audit's own test data
[`crates/zizmor/tests/integration/test-data/ref-version-mismatch.yml`](https://raw.githubusercontent.com/zizmorcore/zizmor/v1.30.1/crates/zizmor/tests/integration/test-data/ref-version-mismatch.yml)
at the pinned tag
[`v1.30.1`](https://raw.githubusercontent.com/zizmorcore/zizmor/v1.30.1/docs/audits.md)
(observations 14–15, 2026-09-10);
[`Cargo.toml`](https://raw.githubusercontent.com/zizmorcore/zizmor/main/Cargo.toml),
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
