# R34 scheduled-freshness-lanes — decision (revision 1, 2026-09-10)

Item R34 (`scheduled-freshness-lanes`, kind `bundle`, Focused tier, owns no
parameter, consumes no parameter). Run
`research/runs/R34/2026-09-05T165440Z-d2e35904dc88`. Synthesizer: a fresh context
that produced none of this item's raw reports. Inputs: `inputs/prompt.md`
(sha256 `f820af6992b3036dcbd9f1aa100ecb53d520caec90483c77982d4bc83655ed05`),
`raw/codex-c1a5048bf89b5e78eb852736516f690c55fd95421660b30e71fd4bde4be6da36.md`
(sha256 `c1a5048bf89b5e78eb852736516f690c55fd95421660b30e71fd4bde4be6da36`,
retrievals dated 2026-09-05),
`raw/opus-c722a6a56b9280b86ff5315b534863ad1e7c0e05677d845ac5d22ec8d36c33ff.md`
(sha256 `c722a6a56b9280b86ff5315b534863ad1e7c0e05677d845ac5d22ec8d36c33ff`,
retrievals dated 2026-09-10), and `docs/port/PARAMETERS.md`. Source-repository
evidence is read through the programme pins: py
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` (written `py@b08bccfb`), ts
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` (written `ts@cb1cbcb2`). Retrieval
dates from the raws are carried unchanged and are not homogenized: a citation
dated 2026-09-05 comes from the Codex raw, one dated 2026-09-10 from the Opus raw
or from this synthesis.

## Decision

This decision is a **proposal validated in the implementation phase** (owner
ruling, 2026-09-10). It records what the research found and what it recommends;
P03 builds the template and its CI proves the recommendation. A decision that
does not survive implementation is revised against this recorded research, not
researched again from scratch. Nothing here has been implemented: no workflow was
written into any repository, nothing was scheduled, and no issue was opened. What
`## Empirical check` reports is verification of the raws' claims.

**Recommendation — run both lanes, as one schedule-only workflow that isolates
one upstream variable per matrix leg.** `.github/workflows/canary.yml`, triggered
by `schedule` (weekly, a fixed minute off the top of the hour) plus
`workflow_dispatch`, with `permissions: {}` at the top and per-job grants,
`concurrency: {group: canary, cancel-in-progress: true}`, `timeout-minutes: 30`,
`strategy.fail-fast: false`, and an explicit `matrix.include` of three legs:

| Leg | Runners | Toolchain | Dependency graph | Freshness step |
|---|---|---|---|---|
| `latest-deps` | `ubuntu-latest`, `macos-latest` | stable | re-resolved | `cargo update --verbose` with `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow` in the step's `env` |
| `next-toolchain` | `ubuntu-latest` | `beta` | held constant (`--locked`) | none |

Each leg then runs the test command R32 selects (this item does not choose the
harness; see the two requirements it places on that command, below). A `report`
job, `needs: [canary]`, `if: failure() && github.event_name == 'schedule'`,
`permissions: {contents: read, issues: write}`, uses the runner-preinstalled `gh`
CLI to open or comment on a single `canary`-labelled issue. **No
`continue-on-error` on any canary leg** — the workflow has no pull-request or
push trigger, so it already cannot gate, and the flag would render a broken
canary green and suppress the `if: failure()` reporting job. No dependency cache
on this workflow. Toolchains are installed by `dtolnay/rust-toolchain`
(`archived: false`, `pushed_at` 2026-09-03T15:22:58Z, MIT —
`GET https://api.github.com/repos/dtolnay/rust-toolchain`, verified 2026-09-10),
referenced as `@master` with an explicit `toolchain:` input and pinned in
whatever form R20 selects; the only maintained alternative,
`actions-rs/toolchain`, is `archived: true` since 2023-06-18 (same endpoint
family, verified 2026-09-10).

**Ledger rows settled.** `F126` (scheduled dependency-freshness canary run):
**yes** — adopt it, as the `latest-deps` legs. `F127` (advisory alternate JS
runtime test lane): **yes, re-mapped** — Rust's analogue is the official `beta`
channel, not an alternate package manager or installer, and it is expressed as a
leg of the same scheduled workflow rather than as a separate mechanism. A
`nightly` leg is rejected on noise, not on the stable-only constraint.

**The interaction with `rust-edition` that gives the recommendation its shape,
stated at the width the evidence supports.** Under `edition = "2024"` Cargo
selects resolver version `"3"`, whose documented effect is to change the default
of `resolver.incompatible-rust-versions` from `allow` to `fallback`; under
`fallback` the resolver prefers dependency versions whose declared `rust-version`
is at or below the workspace's own declared `rust-version` — which `msrv-policy`
requires this template to declare. The consequence for this item: **for those
dependencies that have published a newer in-bounds version declaring a
`rust-version` above the template's floor, a `cargo update` canary run without
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow` re-tests the same graph the
gating build already has**, which is the one outcome a freshness lane cannot
tolerate. That chain is verified end-to-end in `## Empirical check`, from the
edition to the resolver version to the default to the observed selection, against
Cargo's own shipped documentation and a live resolution. Three limits on that
sentence, all from the same verified run, so it is not read more widely than it
holds:

1. The lane is **not inert without the override**. Dependencies whose newer
   versions stay within the floor still move. In the probe, 9 packages were
   locked and exactly 1 was held back.
2. The suppression is **visible in the run log, not silent**: Cargo prints
   `Locking 9 packages to latest Rust 1.85 compatible versions` and
   `Adding icu_locale_core v2.1.1 (available: v2.3.0, requires Rust 1.88)`. What
   it cannot show is a pass/fail difference — the leg goes green either way — so
   the defect survives any review that reads only the job result.
3. The affected class is **bounded and dated**: edition 2024 refuses a declared
   `rust-version` below 1.85 outright (observed, see the log), and under
   `msrv-policy` the floor tracks stable minus two minors, so the dependencies the
   default holds back are those that raised their MSRV within roughly the last two
   release cycles. That is a small class, and it is exactly where the
   fastest-moving crates sit — which is why the override is required rather than
   optional.

**Two requirements this lane places on the R32-selected test command** (R32 owns
the command; this item does not re-decide it): it must accept `--locked` so the
`next-toolchain` leg can hold its dependency graph constant and keep a red leg
attributable to the compiler; and it must cover feature-gated code — if R69 puts
the web surface behind a Cargo feature, a canary that omits `--all-features`
silently skips the web dependency subtree, where the heaviest and fastest-moving
dependencies will live.

### Principles and implementation

**Shared requirement, its source, and its agreement level.** Breakage that
originates upstream — in a dependency or in the language toolchain — should be
discovered by a run nobody is waiting on, before a contributor discovers it while
waiting on an unrelated pull request. Both source repositories state this in
their own words: py@b08bccfb `.github/workflows/canary.yml:1-11` ("an upstream
breaking change in a transitive dep … surfaces in a calm scheduled run we can
triage — not inside an unrelated feature PR weeks later. It NEVER gates a PR
(schedule + manual dispatch only), so a red canary is a signal, not a blocker" —
read at the pin, quoted in the log), and ts@cb1cbcb2
`.github/workflows/ci.yml:130-140` for the other axis ("a forward-compatibility
signal, not a required gate"), recorded as D-036 in
`docs/port/TS_PORT_DECISIONS.md`. **Agreement level: capability / standard.**
What must agree across py, ts and rs is that an early-warning-without-gating
capability exists for upstream change, with two observable properties. The
mechanism is free to vary by ecosystem, which is why py and ts diverged in
opposite directions without either being wrong.

| Must agree (capability level) | May vary (mechanism level) |
|---|---|
| A configuration the merge gate deliberately does not exercise — an unpinned dependency graph, or an ahead-of-stable toolchain — is exercised on a cadence | Whether the cadence is a `schedule:` cron or "every regular run, marked non-blocking" |
| The lane cannot block a merge, by construction rather than by convention | Which axis of upstream change is covered (dependencies, runtime, compiler) — the ecosystem decides which axis actually moves |
| A failure is routed to somebody who can act on it | Whether routing is a red run, an email, or a filed issue |
| The lane is manually re-runnable for triage (`workflow_dispatch` in both sources) | The refresh command itself (`uv sync --upgrade`, `cargo update`, `pnpm update`) |

**Observable acceptance criteria** (each is a check P03 can run; none has been
run here — see `## Empirical check` for what was, and `## Engines` for the gap):
after the freshness step, `Cargo.lock` differs from the committed lockfile;
`cargo update --dry-run` produces a different result with and without
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow` in a workspace where some
dependency's newer version declares a `rust-version` above the floor; the
`next-toolchain` leg's `rustc --version` reports a beta version one minor above
stable and leaves `Cargo.lock` unchanged; none of this workflow's job names
appears in the branch's required status checks; a deliberately failed leg leaves
the workflow run red rather than green; two consecutive red scheduled runs produce
one issue plus one comment, not two issues.

**Is the shared architectural pattern still appropriate in Rust? Yes on both
axes, with the F127 axis re-mapped rather than copied.** On the dependency axis,
`cargo update` is the faithful analogue of `uv sync --upgrade`: both re-resolve to
the newest versions the declared bounds allow, and neither rewrites those bounds.
py's canary is explicit that `--locked` must not be added there (py@b08bccfb
`.github/workflows/canary.yml:44-45`, read at the pin). On the runtime axis, ts
substitutes a competing implementation of the same runtime because JavaScript has
one; Rust has no competing rustc. The `beta` channel is a stronger analogue than
"closest available substitute", and for a different reason than ts's: ts's lane is
advisory because Bun trails the Node floor (D-036: "Bun tracks Node v23 parity —
one major behind the floor, hence advisory-not-gating"), a deficiency argument;
a beta failure is a dated prediction of a stable failure within at most six weeks,
and the Rust project solicits exactly this — "Most Rust users do not use beta
releases actively, but test against beta in their CI system to help Rust discover
possible regressions" (The Rust Programming Language, Appendix G,
https://doc.rust-lang.org/book/appendix-07-nightly-rust.html, 2026-09-10). The
live channel manifests confirm the train is where the argument assumes: stable
`1.98.1 (48a229cea 2026-09-01)`, beta `1.99.0-beta.4 (948ec4e1e 2026-09-04)`
(`https://static.rust-lang.org/dist/channel-rust-{stable,beta}.toml`, verified
2026-09-10). `nightly` is rejected as a standing leg on noise: rustls both
date-pins its nightly (`build.yml:463`, `nightly-2026-03-20`) and declines to deny
warnings under it (`build.yml:449`), two independent mitigations that exist
because floating nightly is noisy, and a template hands that noise to every fork.

**Architectural alternatives compared before any tool was chosen.** The Cargo
Book's "Verifying Latest Dependencies" section enumerates four architectures with
their costs; the text below is quoted from the copy shipped with the local
toolchain (rustup `stable` = rustc 1.94.0,
`share/doc/rust/html/cargo/guide/continuous-integration.html`; the same page is
published at
https://doc.rust-lang.org/cargo/guide/continuous-integration.html#verifying-latest-dependencies,
2026-09-10).

| Architecture | Cargo Book's stated cost | Verdict here |
|---|---|---|
| A — do not commit `Cargo.lock` | "This comes at the cost of determinism"; "Depending on PR velocity, many versions may go untested" | Rejected. The template ships a binary and has a fixed `msrv-policy`; losing determinism trades the merge gate's reliability for the canary's job |
| B — a latest-dependencies job in regular CI marked "continue on failure" | "Depending on the CI service, failures might not be obvious"; "Depending on PR velocity, may use more resources than necessary" | Rejected as primary, recorded as ranked runner-up. This is ts's shape. On a template the resource cost is inherited by every fork, on every pull request, forever |
| C — a scheduled job verifying latest dependencies | "A hosted CI service may disable scheduled jobs for repositories that haven't been touched in a while"; "notifications might not be routed to people who can act on the failure" | **Recommended.** It is py's shape, and both stated costs are closable — the first by `workflow_dispatch` plus a documented re-enable step, the second by the `report` job |
| D — regular dependency-update pull requests (Dependabot, Renovate) | "Only uses the resources necessary"; frequency configurable | Complementary, and **not this item's to decide** — R19 owns `dependabot-config-shape`. It answers a different question: its bumps run the *gating* suite and block that pull request, while the canary tests the graph the published bounds permit and blocks nothing. Recorded so P03 does not read R19's answer as making this lane redundant |

The two costs of architecture C are real and one of them has no YAML mitigation:
"In a public repository, scheduled workflows are automatically disabled when no
repository activity has occurred in 60 days" (GitHub Actions events reference,
https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows,
2026-09-10). For a template whose forks go quiet this is a sharp edge, and it is
the reason the ranked runner-up (architecture B) is recorded rather than
dismissed. The mitigations belong in P03's documentation: `workflow_dispatch`, a
`CONTRIBUTING.md` note that a quiet fork must re-enable the workflow, and the
`report` job that makes a working canary visible enough for its absence to be
noticed. The same reference records two further constraints on the design:
scheduled workflows "will only run on the default branch", so the file cannot be
observed running on schedule until it is merged; and schedule delivery can be
delayed or dropped under platform load, so a missed week is possible and the lane
must not be described as a guarantee.

**How the selected design preserves each principle.** Non-gating is structural,
not conventional: a workflow whose only triggers are `schedule` and
`workflow_dispatch` never runs on a pull request, so it cannot appear in a
required status check — the stronger form of the guarantee py states in prose and
ts obtains with `continue-on-error: true` because its lane shares a gating
workflow (ts@cb1cbcb2 `.github/workflows/ci.yml:144`). One variable moves per leg,
so a red leg is self-diagnosing: `latest-deps` holds the toolchain at stable while
the graph moves, `next-toolchain` holds the graph at `--locked` while the compiler
moves. `fail-fast: false` keeps one red leg from hiding the others, mirroring py's
explicit choice and its reason (py@b08bccfb `.github/workflows/canary.yml:32`,
"report both Python legs even if one breaks"). Failure routing is the third
must-agree property and the one neither source implements: py's canary is 52 lines
with no `timeout-minutes` and no reporting step (both verified at the pin — see
the log), and a failed scheduled run notifies the last committer to the default
branch, who is often not the person who can act. Two guardrails close py's gaps
rather than copy them: `timeout-minutes: 30`, and the `report` job.

**Reference implementations, and the gap.** The dependency half is first-party:
the Cargo Book publishes the `latest_deps` recipe, including the
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow` line and its stated reason
("set to ensure the resolver doesn't limit selected dependencies because of your
project's Rust version"). The toolchain half is unanimous practice: six
well-regarded projects run a beta and/or nightly leg — `BurntSushi/ripgrep`
(`ci.yml:7-8,51,53-66`), `dtolnay/anyhow` (`ci.yml:5,7,9-10,25,27,30,31`),
`serde-rs/serde` (`ci.yml:7,29,46,57`), `rustls/rustls`
(`build.yml:13-14,33-50,463`), `clap-rs/clap` (`ci.yml:63,72,206`),
`tokio-rs/axum` (`CI.yml:22,88,103,150`), all retrieved from
`raw.githubusercontent.com/<repo>/HEAD/<path>` on 2026-09-10 by the Opus raw.
`dtolnay/anyhow`'s file is the closest single reference to the recommended shape —
cron, `workflow_dispatch`, `permissions: contents: read`, `fail-fast: false`,
`timeout-minutes`, and a beta matrix leg in one file — missing only the freshness
step. **No public repository was found combining all four members** (freshness
step, beta leg, guardrail set, issue filing) in one scheduled workflow; the
four-member composition is this decision's synthesis and is recorded as an
evidence gap under `## Engines`, not as a cited reference implementation.

**BASELINE-REVIEW findings — carried through as the prompt instructs, not
resolved here. No ledger edit was made and none is proposed in this file.**

BASELINE-REVIEW: F127 — early-warning-without-gating for upstream change — the
row's file evidence should include ts's CI job, not only the local recipe — the
Opus raw reports that `docs/port/COMMONALITY.md:133` and
`docs/port/DIVERGENCE-ANALYSIS.md:146` both cite the advisory lane by the single
reference `Justfile:169`. Verified against the working-tree ledger at this width:
`DIVERGENCE-ANALYSIS.md:146` cites `Justfile:169` and nothing else, and
`COMMONALITY.md:133` carries **no** file evidence at all (its row has no evidence
column entry, so the "both cite `Justfile:169`" phrasing is exact for the first
row and understates the second). The factual half of the claim is verified at the
pin: ts@cb1cbcb2 `.github/workflows/ci.yml` carries a full `bun-lane` job —
`:141` job id, `:142` `name: bun-lane (advisory, non-gating)`, `:144`
`continue-on-error: true`, `:145-147` `permissions: contents: read`, `:175`
`oven-sh/setup-bun@0c5077e51419868618aeaa5fe8019c62421857d6 # v2.2.0`, `:177`
`bun-version: 1.3.14`, `:188` `bun run vitest run --exclude tests/e2e.test.ts`
(command output in the log). This is load-bearing for R34: read as a Justfile
recipe only, ts's precedent looks like a local developer convenience whose Rust
analogue would be a `just` recipe; read with the CI job, it is an automated,
permission-scoped, SHA-pinned advisory CI lane, which is what this decision ports.
The prompt's `## Context` is not at fault — its D-036 summary already names a
"non-required CI job via `oven-sh/setup-bun`". Affected items: R34 (this item) and
R11 `ci-workflow-job-structure` if it inventories ts's job list from the ledger
rather than from the file.

BASELINE-REVIEW: F126 + F127 — early-warning-without-gating for upstream change —
the two rows describe one capability on two axes and should be satisfied by one
workflow with isolated legs, not by two independently-shaped mechanisms —
`docs/port/COMMONALITY.md:132-133` and `docs/port/DIVERGENCE-ANALYSIS.md:145-146`
treat F126 (py-only, class D) and F127 (ts-only, class C) as separate facts with
independent Rust answers, and the F127 question is posed as though the beta lane
must justify its own scheduling overhead ("is that worth the ci-cost given Rust's
own stable/beta/nightly cadence already exists"). Evidence that they are one
capability on two axes: py's workflow header and ts's job header state the same
principle in the same terms (both quoted above, both read at their pins). Evidence
that one file serves both in Rust: all six surveyed projects express the toolchain
axis as matrix legs of an existing workflow rather than a dedicated workflow, and
py's canary already carries a matrix whose Rust analogue is a channel axis rather
than an interpreter axis (py@b08bccfb `.github/workflows/canary.yml:31-34`).
Consequence for the F127 cost question: the beta leg's marginal cost is one weekly
Ubuntu job on a schedule that already exists, so the answer is yes-for-beta and
no-for-nightly, at a cost the standalone framing overstates. Affected items: R34
(this item) and R11 (which must know this workflow exists and is not part of the
aggregate required check owned by R12).

re-verify: 2027-03-01, or earlier on any of — `cargo update --breaking` stabilizing (https://github.com/rust-lang/cargo/issues/12425), which would remove the only reason `cargo-edit` remains the ranked runner-up for a bound-rewriting lane; a change to the Cargo Book's "Verifying Latest Dependencies" architecture list, recipe, or its `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS` note; a change to the default of `resolver.incompatible-rust-versions` or to which resolver version an edition selects; GitHub changing the 60-day scheduled-workflow auto-disable, the default-branch-only rule, or job-level failure semantics; `dtolnay/rust-toolchain` being archived or going six months without a push, which promotes the bare-`rustup` runner-up; R11 selecting bare `rustup` for the gating workflow, which this lane should then follow rather than introduce the repository's only `dtolnay/rust-toolchain` pin; R32 selecting a test command that cannot accept `--locked` or `--all-features`; R13 fixing its dependency-audit day, so the cron can keep py's deliberate offset; R20 fixing the action-pinning form; the template gaining platform-specific code, `unsafe`, a build script, or a `windows-latest` runner, which widens the beta leg to the full OS matrix; triage of a red canary needing more than one bisect step, which is the concrete signal to move from weekly to daily; or a `canary`-labelled issue going unactioned for two consecutive weeks, which is the signal to reduce the lane's scope rather than keep filing.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

Owned parameters: none — the prompt's `- owns:` line is empty. Consumed
parameters: none — the prompt's `- consumes:` line is empty. No `CONFLICT:` line
was raised by either raw report, and none is raised here.

How the four fixed parameters bear on the decision. `rust-edition` is the
load-bearing one: edition 2024 selects resolver `"3"`, which defaults
`resolver.incompatible-rust-versions` to `fallback`, which is why the
`latest-deps` legs must set `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow`
(verified in `## Empirical check`). `msrv-policy` is load-bearing in two
directions: the `rust-version` it requires the template to declare is what the
resolver falls back to, and the policy's "tested in CI" clause is satisfied by a
separate gating MSRV job, not by this lane — the canary deliberately resolves past
the floor, and that is a complement to the MSRV job rather than a departure from
the policy. `target-os-matrix` is covered as a whole by the workflow: the
`latest-deps` legs run on both runners; the `beta` leg runs on `ubuntu-latest`
only, as a cost choice rather than a support gap, since `rustup` behaves
identically on `macos-latest` and compiler regressions in a pure-Rust template are
overwhelmingly platform-independent. `license` constrains nothing here: no member
adds a crate to the dependency tree. Recorded for completeness — `cargo-edit`, the
unadopted runner-up for a future bound-rewriting lane, declares `Apache-2.0 OR
MIT` (`GET https://crates.io/api/v1/crates/cargo-edit/versions`, 2026-09-10),
which is compatible.

Adjacent items this decision depends on without consuming their parameters, all
recorded so P03 does not have to rediscover them: R32 owns the test command and
this lane requires only that it accept `--locked` and cover feature-gated code;
R11 and R12 must keep this workflow's jobs out of the aggregate required status
check, which is structurally already the case because they never run on a pull
request; R20 fixes the pin form for `actions/checkout` and
`dtolnay/rust-toolchain`; R08 fixes the `permissions` shape, which this lane
already matches in both sources; R10 owns dependency caching, and this workflow
deliberately opts out (a cache keyed on `Cargo.lock` would miss every week on a leg
that rewrites it, and caching opposes the clean-build purpose of the beta leg);
R13 owns the vulnerability-scan schedule, and py deliberately offsets its canary
from it by a day (py@b08bccfb `.github/workflows/canary.yml:16`), which P03 should
preserve; R69 decides whether the web surface is feature-gated, which is why the
test command must cover features.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4 (build 25E246),
`arm64`. The documentation quoted from disk is the `rust-docs` component of the
rustup `stable` toolchain on this machine, `rustc 1.94.0 (4a4ef493e 2026-03-02)`,
at
`~/.rustup/toolchains/stable-aarch64-apple-darwin/share/doc/rust/html/cargo/`.
Working directory for the resolution probe:
`/private/tmp/claude-501/-Users-stevemorin-c-rs-launch-blueprint-p02-plan/b7c06b2f-d78d-4987-b237-63eeced4bd23/scratchpad/r34-fixture`
(scratchpad, outside every repository); for the repository reads, the programme
checkout `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.

**This check verifies the raws' claims and implements nothing.** No workflow file
was written into any repository, nothing was scheduled, no issue was opened, and
nothing was built or tested. The one fixture is two files — a `Cargo.toml` and an
empty `src/lib.rs` — used solely as input to a dependency-resolution query; it is
never compiled. Full output: `review/evidence/resolver-fallback-chain.log`
(sha256 `ef7c1528c6b45a22b499e103a259eecd97de179cc42a1ec634016e4229f856f3`).

**(1) The edition → resolver → default chain, in Cargo's own shipped
documentation.** From `reference/resolver.html` of the 1.94.0 book: `"3"`
(`edition = "2024"` default, requires Rust 1.84+): "Change the default for
resolver.incompatible-rust-versions from allow to fallback", and "With the
fallback setting, the resolver will prefer packages with a Rust version that is
less than or equal to your own Rust version" — with a worked example in which a
package declaring `rust-version = "1.62"` on a 1.85 toolchain resolves
`clap = "4.0"` to `4.0.32` rather than `4.5.20`, because "4.5.20 … has a Rust
version of 1.74.0". "Your own Rust version" there is the package's declared
`rust-version`, not the installed toolchain. From `reference/config.html`:
`resolver.incompatible-rust-versions`, `Environment:
CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS`, values `allow` ("treat rust-version-incompatible
versions like any other version") and `fallback` ("only consider
rust-version-incompatible versions if no other version matched"). The same book
ships the CI recipe, which sets that variable with its reason stated. Both pages
are published online at https://doc.rust-lang.org/cargo/reference/resolver.html
and .../config.html (2026-09-10).

**(2) The chain, executed.** In the fixture, `edition = "2024"`:

```
$ cargo generate-lockfile                    # default (fallback), rust-version = "1.85"
     Locking 9 packages to latest Rust 1.85 compatible versions
      Adding icu_locale_core v2.1.1 (available: v2.3.0, requires Rust 1.88)
$ grep -A1 'name = "icu_locale_core"' Cargo.lock   ->  version = "2.1.1"

$ CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow cargo generate-lockfile
     Locking 9 packages to latest compatible versions
$ grep -A1 'name = "icu_locale_core"' Cargo.lock   ->  version = "2.3.0"
```

Both exit 0. `icu_locale_core` 2.3.0 declares `rust_version` 1.88
(`https://index.crates.io/ic/u_/icu_locale_core`, 2026-09-10). This is the
decision's headline finding executed rather than inferred, and it is what limits
the claim to the width written in `## Decision`: one of nine packages was held
back, and Cargo named it in the log.

An earlier attempt used the Cargo Book's own example floor and was refused:
`rust-version 1.62 is incompatible with the version (1.85.0) required by the
specified edition (2024)` (exit 101). That refusal is itself evidence — under this
template's fixed edition the declared floor can never be below 1.85, which bounds
how far the fallback default can hold a dependency back.

**(3) `cargo update --breaking` is not available on stable.** `cargo update
--breaking` in the fixture: `error: the `--breaking` flag is unstable, and only
available on the nightly channel of Cargo, but this is the `stable` channel`
(exit 101), citing rust-lang/cargo#12425. This settles the prompt's MEDIUM
question on bound rewriting: under the stable-only constraint the built-in cannot
rewrite bounds, so `cargo-edit`'s `cargo upgrade --incompatible` is the only
stable option, and it stays a documented runner-up rather than part of this stack.

**(4) `cargo update --workspace` is a narrowing flag, not the freshness step.**
`cargo update --help` on 1.98.0: `-w, --workspace  Only update the workspace
packages`. Against the same fixture, with its lockfile reset to the
fallback-resolved graph and the override set:

```
$ ... cargo update --workspace --dry-run     # the step written in raw/codex
     Locking 0 packages to latest compatible versions
     note: pass `--verbose` to see 1 unchanged dependencies behind latest

$ ... cargo update --verbose --dry-run       # the step written in raw/opus and the Cargo Book
     Locking 1 package to latest compatible version
    Updating icu_locale_core v2.1.1 -> v2.3.0
```

Both exit 0. The evidence is one workspace with one member and one registry
dependency; the flag's documented meaning makes the behavior general, but this run
demonstrates it on that single shape, not across workspace layouts.

**(5) Source repositories, read through the pins.** py@b08bccfb
`.github/workflows/canary.yml` printed in full (52 lines): `:16` `cron: '0 6 * * 2'`
with the comment "offset from dep-audit's Monday"; `:17` `workflow_dispatch:`;
`:19` `permissions: {}`; `:21-23` `concurrency` with `cancel-in-progress: true`;
`:32` `fail-fast: false`; `:44-46` "do NOT add --locked here"; `:47`
`uv sync --upgrade --group dev --extra web`. `grep -c 'timeout-minutes'` → 0 and
`grep -ci 'issue'` → 0, confirming the two gaps this decision closes. ts@cb1cbcb2
`.github/workflows/ci.yml` grepped for the advisory job: the `bun-lane` lines
listed in the F127 baseline-review above, at the stated line numbers.
`Justfile:160-169` printed, confirming the recipe the ledger cites is a local
convenience wrapper whose CI counterpart is the job.

**(6) Two spot-checks of raw figures on the day of synthesis.**
`gh api repos/dtolnay/rust-toolchain` → `{"archived":false,"license":"MIT","pushed_at":"2026-09-03T15:22:58Z","stars":1574}`;
`gh api repos/actions-rs/toolchain` → `{"archived":true,"pushed_at":"2023-06-18T05:26:38Z"}`;
`channel-rust-stable.toml` → `1.98.1 (48a229cea 2026-09-01)`;
`channel-rust-beta.toml` → `1.99.0-beta.4 (948ec4e1e 2026-09-04)`. All four match
the Opus raw's 2026-09-10 figures.

**What this check does not establish.** It does not show that the recommended
workflow behaves as designed on GitHub's runners: nothing here ran in Actions.
It does not measure the lane's wall-clock or runner-minute cost. It does not prove
the de-duplicated issue-filing job works. Those are recorded under `## Engines`
with what would prove them.

## Engines

- codex `raw/codex-c1a5048bf89b5e78eb852736516f690c55fd95421660b30e71fd4bde4be6da36.md` — Focused-tier raw answer, retrievals 2026-09-05. Recommends the same two capabilities: a weekly two-OS `scheduled-freshness.yml` and an advisory beta lane. Its GitHub REST repository figures are missing, by its own statement: `GET https://api.github.com/repos/...` returned an unauthenticated core-rate-limit error on 2026-09-05, so stars, `archived`, `pushed_at` and issue-responsiveness for the three action repositories are unverified in that report and it correctly declines to guess them.
- opus `raw/opus-c722a6a56b9280b86ff5315b534863ad1e7c0e05677d845ac5d22ec8d36c33ff.md` — Focused-tier raw answer, retrievals 2026-09-10. Four members (`cargo update`, `dtolnay/rust-toolchain`, the scheduled-workflow guardrail pattern, `gh` failure reporting), a six-project practice survey, the Cargo Book's four-architecture comparison, and the resolver interaction that shapes this decision. Its GitHub figures were completed through an authenticated `gh api` client against the same endpoints after the unauthenticated limit was reached, and it says so.

**Disagreement 1 — the resolver override.** The Codex raw does not mention
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS` at all; the Opus raw makes it the
report's highest-value finding. Settled for Opus by `## Empirical check` (1) and
(2): the chain holds in Cargo's own documentation and in a live resolution. The
Opus raw's wording — the omission "turns the entire lane into a no-op that looks
green" — is wider than the evidence: the probe moved 9 packages and held back 1,
and Cargo printed the holdback. This decision states the narrower claim, in
`## Decision`, with the three limits listed there.

**Disagreement 2 — the freshness command.** Codex specifies `cargo update
--workspace`; Opus specifies `cargo update --verbose`, following the Cargo Book.
Settled for Opus by `## Empirical check` (4): `--workspace` means "only update the
workspace packages" and, on the probe, refreshed no registry dependency while the
plain form moved one. Adopting the Codex form would leave the freshness step
testing the committed graph on that probe's shape, for a reason independent of the
resolver default — though, as with the resolver default, Cargo left a trace rather
than saying nothing: it printed `note: pass --verbose to see 1 unchanged
dependencies behind latest`. `--verbose` is kept for an
operational reason, not style: it names each version that moved, so a failing run's
log identifies the dependency.

**Disagreement 3 — where the beta lane lives.** Codex places it as a job on
ordinary `push`/`pull_request` CI with job-level `continue-on-error: true` (the
Cargo Book's architecture B, ts's shape); Opus places it as a leg of the
schedule-only workflow (architecture C). Both are Cargo-Book-listed and neither is
wrong on the capability. Decided for Opus on the discriminating constraint that
this repository is a template: architecture B's cost is a full extra build on every
pull request in every fork, forever, to compress detection latency from at most
seven days to one pull request on an axis whose release train is six weeks — the
latency reduction buys nothing against that cadence. Architecture B is recorded as
the ranked runner-up, and it has one real advantage this decision gives up: it
cannot be auto-disabled by 60 days of inactivity. If the owner judges that
auto-disable unacceptable for a template, architecture B is the documented switch.
A consequence of choosing C: `continue-on-error` must not appear on any canary
leg, because in a schedule-only file it would make a broken canary green — this is
the single most likely implementation error, since the Cargo Book recipe carries
the flag for architecture B and is easy to copy verbatim.

**Disagreement 4 — issue filing.** Codex recommends against it: an automatic issue
"creates a second state machine (deduplication, close/reopen policy, and a
write-capable token) without improving detection", and GitHub's guidance is to
grant minimum `GITHUB_TOKEN` permissions. Opus recommends it, from the Cargo
Book's own stated cost of architecture C ("notifications might not be routed to
people who can act on the failure") and GitHub's 60-day auto-disable. Adopted, with
Codex's objection carried rather than dismissed, and at **medium-high confidence,
which is where the evidence puts it**: this is the one member with no reference
implementation in any surveyed project and in neither source repository — py's
canary files nothing (verified: `grep -ci 'issue'` → 0 at the pin). The
deduplication requirement Codex names is real and is the reason the design does a
`gh issue list --label canary --state open` lookup before creating; without it a
persistent breakage files a new issue weekly and the lane gets muted. The
`issues: write` escalation is real too and is confined to one job that runs only
on a failed scheduled run. **P03 must validate this member specifically**: that a
first red run creates exactly one labelled issue, that a second creates a comment
rather than a second issue, that a `workflow_dispatch` run files nothing, that
`${{ github.token }}` with a job-scoped `issues: write` suffices with no repository
secret, and that a fork with its issue tracker disabled fails visibly inside an
already-red workflow rather than silently.

**Disagreement 5 — `--locked`, apparent rather than real.** Codex runs `cargo
update` and then the test command with `--locked`; Opus says `--locked` must never
appear on the freshness leg. They reconcile: after the update step has already
rewritten the lockfile, `--locked` on the following test asserts only that no
*further* resolution is needed, which is a useful assertion and is not the
`--locked` py forbids (py forbids the flag on the *refresh* step, where it would
negate the refresh). This decision leaves the choice to P03 and requires `--locked`
only on the `next-toolchain` leg, where it is load-bearing for attribution.

**Disagreement 6 — the test command.** The Opus raw hardcodes `cargo test
--workspace --all-features --all-targets` plus a `--doc` pass; the prompt puts the
harness out of scope, R32 owns it. This decision names "the R32-selected command"
and converts the Opus specifics into the two requirements the lane places on that
command (`--locked`-capable; covers feature-gated code).

**Where the raws' figures differ, and which is used.** The Codex raw's crate
figures for `cargo-edit` (505,345 recent / 3,524,290 all-time, 2026-09-05) and the
Opus raw's (481,434 / 3,546,657, 2026-09-10) are five days apart and both are
reported as retrieved; neither is corrected against the other. For the GitHub
repository fields the Opus figures are used, because the Codex raw's were blocked
by an unauthenticated rate limit and it says so; two of them are independently
corroborated in `## Empirical check` (6).

**Gaps carried forward, each with what would prove it.**

1. **No four-member reference implementation.** No public repository was found
   running the freshness step, a beta leg, the guardrail set and issue filing in
   one scheduled workflow. What would prove it: the P03 template itself becomes the
   first adopter, and its first weeks of scheduled runs are the evidence. Until
   then the pairs are separately evidenced — `dtolnay/anyhow` and `BurntSushi/ripgrep`
   for the toolchain leg inside the guardrail set, the Cargo Book's `latest_deps`
   job for the freshness step with the resolver override, `clap-rs/clap`
   (`ci.yml:201-206`) for `cargo update` under an action-installed toolchain, and
   py@b08bccfb `.github/workflows/canary.yml` for the standalone schedule-only shape
   (all 2026-09-10 except the pin).
2. **No measured wall-clock or runner-minute figure, because no template exists to
   measure.** The `timeout-minutes: 30` guardrail is a bound, not a measurement;
   the only anchors are `dtolnay/anyhow`'s declared `timeout-minutes: 45` for a far
   smaller crate and the fact that GitHub-hosted minutes are unbilled for public
   repositories. What would prove it: the first scheduled runs on the built
   template, three legs from a cold `target/`, on both required runners.
3. **Every validation command is proposed, not executed.** Nothing in the
   acceptance criteria above has been run against `rs-launch-blueprint`, which has
   no Rust code, no lockfile and no R32 command. What was executed is `## Empirical
   check`, which verifies the resolver chain, the two command semantics, the pinned
   source files and four figures — not the workflow's behavior on GitHub. What would
   prove the rest: in P03's template, the lockfile-moved and override-is-load-bearing
   checks locally; then, post-merge, `actionlint`, a `workflow_dispatch` run showing
   three legs and no `report` job, the required-status-check contexts showing none of
   these job names, an induced single-leg failure leaving the run red, and the
   two-consecutive-failure issue-then-comment sequence.
4. **The cadence is a calibration, not a finding.** Weekly matches py's recorded
   cadence and keeps a template's inherited cost low; four of the six surveyed
   projects run daily (`ripgrep '00 01 * * *'`, `anyhow` and `serde '40 1 * * *'`,
   `rustls '0 18 * * *'`, all 2026-09-10). Confidence on weekly-versus-daily is
   medium. What would settle it: triage experience on the built template — a red
   canary needing more than one bisect step is the concrete signal that weekly
   latency is producing multi-cause failures.
5. **`clap`'s `continue-on-error` guard is cited for the idiom only.** The Opus raw
   records that at the retrieved HEAD every leg of clap's matrix is `stable`, so
   `ci.yml:63` guards nothing today. It is evidence of the pattern, not of a live
   beta lane, and is used here only that way.
6. **No annual Rust survey figure exists for this subject.** The Opus raw searched
   for one and cites none rather than inventing one; the practice evidence rests on
   the six surveyed repositories instead.
