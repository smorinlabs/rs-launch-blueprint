# R34 — scheduled-freshness-lanes (bundle) — Opus raw report

All endpoint retrievals in this report were performed on **2026-09-10** unless a
different date is stated inline. Source-repository citations are read through the
programme pins: Python `b08bccfb55d05f15e46a83b52c5660b1881d19f5` (written
`py@b08bccfb`), TypeScript `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` (written
`ts@cb1cbcb2`). Third-party repository files cited as `HEAD` were fetched from
`https://raw.githubusercontent.com/<owner>/<repo>/HEAD/<path>` on 2026-09-10;
their line numbers are the line numbers in that retrieved file.

### Landscape

**Category this item decides.** Not a library category. It decides two *CI lane
policies* and the mechanisms that implement them: (a) a **dependency-freshness
lane** — does the repository periodically re-resolve its dependency graph to the
newest versions its `Cargo.toml` bounds allow and run the suite against that
graph, outside the merge gate; and (b) a **toolchain-freshness lane** — does the
repository periodically build and test under a Rust channel that is ahead of
stable, non-gating, as early warning. Both are "detect upstream breakage before
it becomes urgent" mechanisms. Neither is a crate-selection problem in the usual
sense: the primary mechanisms are Cargo built-ins and GitHub Actions triggers,
and the only genuine crate candidate in the whole map is `cargo-edit`.

**Three-bin map of the Rust field.**

| Bin | Candidates found | What it does here |
|---|---|---|
| Built-in / first-party toolchain | `cargo update` (Cargo built-in); `cargo update --breaking` (nightly-only); `cargo generate-lockfile -Z minimal-versions` (nightly-only); `cargo report future-incompatibilities` (Cargo built-in); `rustup toolchain install beta` (rustup, preinstalled on both required runners); the Cargo Book's own `latest_deps` CI recipe; `actions/checkout`; the GitHub Actions `schedule:` / `workflow_dispatch:` triggers, `permissions:`, `concurrency:`, `timeout-minutes:`, `continue-on-error:`; `gh` (GitHub CLI, preinstalled on both required runners); `actions/github-script` | the freshness resolution step, the alternate-toolchain install, the trigger and guardrail surface, and the failure-reporting surface |
| Established industry standard | `dtolnay/rust-toolchain` (the de-facto Rust toolchain action; used by every practice project surveyed below); `Swatinem/rust-cache` (owned by R10, mentioned here only to argue *against* using it on this lane); `cargo-edit` `cargo upgrade` / `cargo upgrade --incompatible` (the only stable-channel way to bump SemVer-incompatible bounds); `cargo-hack` (`--rust-version`, cited by the Cargo Book for the adjacent MSRV lane); Dependabot / Renovate as the *alternative architecture* to a scheduled canary | toolchain provisioning, bound-rewriting upgrades, and the competing "PR-per-upgrade" architecture |
| Up-and-comer | `cargo-minimal-versions` (taiki-e; wraps the nightly `-Z minimal-versions` flag for stable use); `taiki-e/install-action` (fast prebuilt-binary installer for cargo subcommands, cited by the Cargo Book's own MSRV example); `peter-evans/create-issue-from-file` and `JasonEtco/create-an-issue` (issue-filing actions) | the *lower*-bound freshness direction and the failure-reporting alternatives |
| Excluded from the map | `actions-rs/toolchain` — `archived: true`, `pushed_at: 2023-06-18T05:26:38Z` (`GET https://api.github.com/repos/actions-rs/toolchain`, 2026-09-10). Named only so a P03 implementer does not resurrect it from an old tutorial. | — |

**Authoritative sources used, and why each is authoritative.**

1. **The Cargo Book, "Continuous Integration → Verifying Latest Dependencies"** —
   https://doc.rust-lang.org/cargo/guide/continuous-integration.html#verifying-latest-dependencies
   (2026-09-10). This is the Cargo team's own published guidance and it addresses
   *exactly* this item: it enumerates four architectures for the problem (do not
   commit `Cargo.lock`; a `continue-on-error` job on every run; a scheduled job;
   PR-based updates via Dependabot/Renovate), states each one's cost, and gives a
   concrete GitHub Actions recipe. It is linked from the Cargo guide
   (https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html: "We
   recommend pairing this with Verifying Latest Dependencies") and from the Cargo
   FAQ. This is a *specification-grade* source for this item, not a blog lead.
2. **The Cargo Book reference chapters** — `cargo-update(1)`
   (https://doc.rust-lang.org/cargo/commands/cargo-update.html), the resolver
   chapter (https://doc.rust-lang.org/cargo/reference/resolver.html), the config
   reference (https://doc.rust-lang.org/cargo/reference/config.html), and the
   future-incompat report chapter
   (https://doc.rust-lang.org/cargo/reference/future-incompat-report.html), all
   2026-09-10. Authoritative because they are the normative documentation of the
   tool whose behavior the lane depends on.
3. **The Rust Programming Language, Appendix G ("How Rust is Made and 'Nightly
   Rust'")** — https://doc.rust-lang.org/book/appendix-07-nightly-rust.html
   (2026-09-10). The Rust project's own description of the six-week release train
   and, verbatim: "Most Rust users do not use beta releases actively, but test
   against beta in their CI system to help Rust discover possible regressions,"
   and "if a beta release doesn't work as expected, you can report it to the team
   and get it fixed before the next stable release happens!" This is the Rust
   project *asking* downstream repositories to run the lane this item is deciding.
4. **GitHub Actions reference, "Events that trigger workflows → schedule"** —
   https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
   (2026-09-10). The platform's own normative statement of the constraints a
   scheduled lane must survive: "In a public repository, scheduled workflows are
   automatically disabled when no repository activity has occurred in 60 days";
   "Scheduled workflows will only run on the default branch"; "The `schedule`
   event can be delayed during periods of high loads … To decrease the chance of
   delay, schedule your workflow to run at a different time of the hour"; minimum
   interval 5 minutes; `@weekly`/`@daily` shorthand is not supported.
5. **`actions/runner-images` image manifests** —
   `images/ubuntu/Ubuntu2404-Readme.md` and `images/macos/macos-15-Readme.md` at
   `main` (2026-09-10). The runner platform's own inventory; it settles which
   tools the lane gets for free rather than by installing an action.
6. **Rust release channel manifests** —
   `https://static.rust-lang.org/dist/channel-rust-stable.toml` and
   `channel-rust-beta.toml` (2026-09-10). The distribution's own machine-readable
   truth about what `stable` and `beta` currently are.

I did **not** find an annual Rust survey question specific to scheduled CI lanes
and therefore cite no survey figure rather than invent one — recorded as an
evidence gap under `### Sources`.

**Practice evidence — well-regarded Rust projects surveyed, with the evidence
that they are well regarded.** All files retrieved 2026-09-10 from
`raw.githubusercontent.com/<repo>/HEAD/…`; star counts from
`GET https://api.github.com/repos/<o>/<r>`.

| Project | Why it is a relevant, well-regarded reference | What its CI does for this item |
|---|---|---|
| `BurntSushi/ripgrep` | The reference Rust *CLI* — the closest shape match to this template's CLI surface; maintained by Andrew Gallant, also the maintainer of `regex` and `memchr`, two of the most-depended-upon crates in the ecosystem | `.github/workflows/ci.yml:7-8` — `schedule: - cron: '00 01 * * *'` (daily). `:53-66` — matrix `include:` legs `pinned` (`rust: 1.96.0`), `stable`, `beta`, `nightly`, with `fail-fast: false` at `:51`. `:26-28` — a top-level `permissions: contents: read` whose comment explains it exists "to drop write-all permissions that are granted on `schedule` event" |
| `dtolnay/anyhow` | One of the two most-used Rust error crates; its author's CI layout is copied across a large part of the ecosystem | `.github/workflows/ci.yml:7` — `schedule: [cron: "40 1 * * *"]`; `:5` `workflow_dispatch:`; `:9-10` `permissions: contents: read`; `:27` `rust: [nightly, beta, stable, 1.88.0]`; `:25` `fail-fast: false`; `:30` `timeout-minutes: 45`; `:78-79` a separate nightly `cargo generate-lockfile -Z minimal-versions` job |
| `serde-rs/serde` | The de-facto serialization framework; among the highest reverse-dependency counts on crates.io | `.github/workflows/ci.yml:7` — `schedule: [cron: "40 1 * * *"]`; `:46` `rust: [stable, beta]`; `:57` a separate `nightly:` job; `:29` `continue-on-error: true` on the non-gating leg; `:121-122` minimal-versions job |
| `rustls/rustls` | The memory-safe TLS stack adopted across the Rust HTTP ecosystem (the web-service half of this template's shape) | `.github/workflows/build.yml:13-14` — `schedule: - cron: '0 18 * * *'`; `:33-50` matrix legs including `beta` and `nightly`; `:463` a *date-pinned* nightly (`nightly-2026-03-20`) for the jobs where nightly churn would be noise |
| `clap-rs/clap` | The dominant Rust CLI argument parser (this template's CLI layer will almost certainly consume it) | `.github/workflows/ci.yml:63` — `continue-on-error: ${{ matrix.rust != 'stable' }}`, the idiomatic *advisory-leg* guard; `:170` MSRV pinned `"1.98"  # STABLE`; `:192` `cargo +nightly generate-lockfile -Z minimal-versions`; `:206` `cargo update --workspace --locked` as a separate lockfile-currency job. Honest caveat: at the retrieved HEAD every leg of clap's matrix is `stable`, so the `continue-on-error` guard is currently vestigial — it evidences the *idiom*, not a live beta leg |
| `tokio-rs/axum` | The dominant Tokio-stack web framework — the direct reference for this template's web-service surface | `.github/workflows/CI.yml:88` — `rust: [stable, beta]`; `:22` `dtolnay/rust-toolchain@beta`; `:103` a separate `test-nightly` job; `:150` `continue-on-error: ${{ matrix.checks == 'advisories' }}`; `:131` minimal-versions |

Two findings fall straight out of this survey and shape everything below.

- **Toolchain-freshness is mainstream Rust practice; dependency-freshness is
  comparatively rare in these libraries — and the reason is structural, not
  cultural.** Every one of the six projects runs a beta and/or nightly leg. None
  runs a "newest dependencies" job. But five of the six run the *opposite*
  direction (`-Z minimal-versions`). The explanation is in the Cargo FAQ
  (https://doc.rust-lang.org/cargo/faq.html#why-have-cargolock-in-version-control,
  2026-09-10): a library's consumers never see its `Cargo.lock` — `cargo install`
  and `cargo add` select the *latest* compatible versions regardless — so for a
  library the newest-versions case is the *default* consumers get and the
  *oldest*-versions case is the untested one. This template is not a library
  only: spec §4 D7 makes it CLI + library + web service, and it will commit a
  `Cargo.lock` for its binary. That inverts the calculus and is precisely why the
  Cargo Book's "Verifying Latest Dependencies" section exists.
- **`dtolnay/rust-toolchain` is the field's toolchain action without a serious
  rival**; all six projects use it, and the only historical alternative,
  `actions-rs/toolchain`, is archived.

### Principles and implementation

**The shared requirement, its source, and its agreement level.**

The principle both source repositories are expressing is one principle, not two:

> **Breakage that originates upstream — in a dependency or in the language
> toolchain — should be discovered by a run that nobody is waiting on, before it
> is discovered by a contributor waiting on an unrelated pull request.**

- Source: py@b08bccfb `.github/workflows/canary.yml:1-11`, whose header comment
  states the principle in the repository's own words — "an upstream breaking
  change in a transitive dep … surfaces in a calm scheduled run we can triage —
  not inside an unrelated feature PR weeks later. It NEVER gates a PR (schedule +
  manual dispatch only), so a red canary is a signal, not a blocker." And
  ts@cb1cbcb2 `.github/workflows/ci.yml:130-140` + `docs/port/TS_PORT_DECISIONS.md`
  D-036, which states the same shape for the other upstream axis — "a
  forward-compatibility signal, not a required gate."
- **Agreement level: `capability/standard`.** What must agree across py, ts and
  rs is *that an early-warning-without-gating capability exists for upstream
  change*, and the two observable properties that make it a capability rather
  than a slogan: it exercises a configuration the merge gate deliberately does
  not (an unpinned dependency graph, or a not-yet-stable toolchain), and it can
  never block a merge. The *mechanism* is explicitly free to vary by ecosystem —
  which is exactly why py and ts diverged in opposite directions without either
  being wrong.

**What must agree, and what may vary.**

| Must agree (capability level) | May vary (mechanism level) |
|---|---|
| An unpinned/ahead-of-stable configuration is exercised on a cadence, outside the merge gate | Whether the cadence is a `schedule:` cron or "every regular run with `continue-on-error`" |
| The lane cannot block a merge, by construction and not by convention | Which axis of upstream change is covered (deps, runtime, compiler) — the ecosystem decides which axis actually moves |
| A failure is routed to somebody who can act on it | Whether routing is a red run, an email, or a filed issue |
| The lane is manually re-runnable for triage (`workflow_dispatch` in both sources) | The upgrade command itself (`uv sync --upgrade`, `cargo update`, `pnpm update`) |

**Is the shared *architectural pattern* still appropriate in Rust? Yes for both
axes, but the axes must be re-mapped, and the mapping is not one-to-one.**

*Dependency axis (F126).* `cargo update` is the faithful analogue of
`uv sync --upgrade`. Both re-resolve to the newest versions the manifest's
declared bounds allow, and neither rewrites those bounds. `cargo-update(1)`
(2026-09-10): "This command will update dependencies in the `Cargo.lock` file to
the latest version." py's canary is explicit that it must not pass `--locked`
("do NOT add `--locked` here", py@b08bccfb `.github/workflows/canary.yml:44-45`);
the Rust mirror-image of that instruction is that `cargo update` is the whole
point and `--locked` would negate it. The Cargo Book endorses the pattern
directly and publishes the recipe. **The pattern ports.**

*Runtime axis (F127) — this is the mapping that requires an argument.* ts's Bun
lane substitutes a *competing implementation of the same language runtime*. Rust
has no competing rustc. The prompt proposes the alternate-*channel* analogue and
that proposal survives scrutiny, but for a stronger reason than "closest
available substitute":

- Bun's advisory status is a *deficiency* argument — D-036 (ts@cb1cbcb2
  `docs/port/TS_PORT_DECISIONS.md:417`): Bun "tracks Node v23 parity — one major
  behind the floor, hence advisory-not-gating." The lane is non-gating because
  the alternate runtime is behind, so its failures may be its own fault.
- A Rust `beta` lane's advisory status is a *direction* argument: beta is what
  stable becomes in at most six weeks (Rust Book Appendix G, 2026-09-10 — the
  six-week train, verified against the live manifests: stable is 1.98.1 at dist
  date 2026-09-03, beta is `1.99.0-beta.4` at dist date 2026-09-06). A beta failure is
  therefore a *dated prediction* of a stable failure, and the Rust project
  explicitly solicits it: "test against beta in their CI system to help Rust
  discover possible regressions … you can report it to the team and get it fixed
  before the next stable release happens."

So the analogue is not merely available, it is *stronger* than the thing it
mirrors: the ts lane can only tell you about Bun, whereas the rs lane tells you
about your own near future and gives you an upstream escalation path. That
answers the DIVERGENCE-ANALYSIS open question on F127 ("is that worth the
ci-cost given Rust's own stable/beta/nightly cadence already exists") — the
cadence's existence is the *reason* the lane is cheap and actionable, not a
reason to skip it. `nightly` is a different matter and is rejected below.

**Architectural alternatives compared before any library was chosen.** The Cargo
Book's "Verifying Latest Dependencies" section enumerates four; I evaluate all
four against this template.

| Architecture | How it satisfies the principle | Why it is or is not the fit here |
|---|---|---|
| **A. Do not commit `Cargo.lock`** | Every CI run resolves fresh, so newest-deps is continuously tested | **Rejected.** The Cargo FAQ lists what a committed lockfile buys — `git bisect`, "ensuring CI only fails due to new commits and not external factors", contributor/CI reproducibility, and MSRV verification against a consistent graph. This template ships a binary and a fixed `msrv-policy`; losing determinism to gain freshness trades the merge gate's reliability for the canary's job. The Cargo Book itself names the cost: "This comes at the cost of determinism" |
| **B. A `continue-on-error` latest-deps job inside the regular CI workflow** | Runs on every push/PR, cannot block | **Rejected as the primary.** The Cargo Book's own stated cost: "Depending on the CI service, failures might not be obvious" and "Depending on PR velocity, may use more resources than necessary". On a *template* repository the second cost is real: every downstream fork inherits an extra full build+test on every PR. This is nonetheless the shape ts chose for its Bun lane, and it is the ranked runner-up |
| **C. A scheduled job verifying latest dependencies** | Runs on a cadence, structurally cannot gate | **Recommended.** It is py's shape, it is the Cargo Book's third option, and its two stated costs are both *closable*: "a hosted CI service may disable scheduled jobs for repositories that haven't been touched in a while" (GitHub: 60 days of no activity in a public repo — closable by `workflow_dispatch` plus a documented re-enable step) and "notifications might not be routed to people who can act on the failure" (closable by filing an issue — see member M4) |
| **D. Dependabot / Renovate PRs** | Each upgrade arrives as its own PR, tested by the *gating* suite | **Complementary, not a substitute, and it is not this item's to decide.** R19 owns `dependabot-config-shape`. The distinction that matters: Dependabot bumps the *lockfile and manifests* and its PRs run the gating suite, so a breaking upgrade blocks *that PR*; the canary tests the graph the repository's *published bounds* permit — including transitive versions Dependabot may not propose — and blocks nothing. They answer different questions. Recording this so P03 does not treat R19's answer as making this lane redundant |

**The decisive implementation detail nobody can skip: the MSRV-aware resolver
will silently defeat a naive canary in this template.** This template is
`rust-edition = 2024` (owner-fixed, `docs/port/PARAMETERS.md`). Per the Cargo
Book resolver chapter (2026-09-10), resolver `"3"` is "the `edition = "2024"`
default, requires Rust 1.84+" and it "Change[s] the default for
`resolver.incompatible-rust-versions` from `allow` to `fallback`". Under
`fallback`, "the resolver will prefer packages with a Rust version that is less
than or equal to your own Rust version" — and the documented example is exactly
the failure mode: with `rust-version = "1.62"`, `clap = "4.0"` resolves to
`4.0.32` and *not* to `4.5.20`. A `cargo update` canary in an edition-2024
workspace with a `rust-version` floor therefore does **not** test the newest
versions; it tests the newest MSRV-compatible versions, which is the same graph
the gating build already has. The Cargo Book's recipe sets
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow` for precisely this reason and
says so in its own note: "set to ensure the resolver doesn't limit selected
dependencies because of your project's Rust version." Omitting that one
environment variable turns the entire lane into a no-op that looks green. This is
the single highest-value finding in this report.

Note the necessary consequence, so P03 does not read it as a policy breach: the
canary deliberately resolves *past* the `msrv-policy` floor. That is correct —
the canary answers "will tomorrow's dependency versions break us", while "does
our declared `rust-version` hold" is a *separate, gating* job. The Cargo Book
publishes that one too, under "Verifying rust-version": `taiki-e/install-action`
plus `cargo hack check --rust-version --workspace --all-targets --ignore-private`.
That MSRV job is R11's/R30's to place; it is named here only to show the two
lanes are complements and that this item does not weaken the MSRV parameter.

**Recommended composition, and how it preserves each principle.** One workflow
file, three matrix legs plus a reporting job, isolating one variable per leg:

```yaml
# .github/workflows/canary.yml
name: canary
on:
  schedule:
    - cron: '17 6 * * 2'   # weekly, Tue 06:17 UTC — off the top of the hour
  workflow_dispatch:
permissions: {}
concurrency:
  group: canary
  cancel-in-progress: true
jobs:
  canary:
    name: canary (${{ matrix.lane }}, ${{ matrix.toolchain }}, ${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    timeout-minutes: 30
    permissions:
      contents: read
    strategy:
      fail-fast: false
      matrix:
        include:
          - { lane: latest-deps,    os: ubuntu-latest, toolchain: stable, refresh: update }
          - { lane: latest-deps,    os: macos-latest,  toolchain: stable, refresh: update }
          - { lane: next-toolchain, os: ubuntu-latest, toolchain: beta,   refresh: locked }
    env:
      CARGO_TERM_COLOR: always
      RUST_BACKTRACE: 1
    steps:
      - uses: actions/checkout@<sha>            # v7.0.1; persist-credentials: false
      - uses: dtolnay/rust-toolchain@<sha>      # master rev; with: toolchain: ${{ matrix.toolchain }}
      - if: matrix.refresh == 'update'
        env: { CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow }
        run: cargo update --verbose
      - run: cargo test --workspace --all-features --all-targets ${{ matrix.refresh == 'locked' && '--locked' || '' }}
      - run: cargo test --workspace --all-features --doc
      - if: always()
        run: cargo report future-incompatibilities || true
  report: { needs: [canary], if: "failure() && github.event_name == 'schedule'", … }  # see member M4
```

Why the legs are split this way: with `latest-deps` holding the toolchain at
`stable` and `next-toolchain` holding the graph at `--locked`, exactly one
variable moves per leg, so a red leg is self-diagnosing. Running both variables
at once would produce failures nobody can attribute — the fastest way to make a
weekly lane get ignored. `fail-fast: false` mirrors py's explicit choice
(py@b08bccfb `.github/workflows/canary.yml:36-37`: "report both Python legs even
if one breaks") and ripgrep's `:51`.

Why there is no `continue-on-error:` anywhere. Its purpose in the Cargo Book
recipe and in clap `:63` is to stop an advisory job from failing a workflow that
*also* gates. This workflow gates nothing — it is `schedule` + `workflow_dispatch`
only, so a red run cannot reach a merge gate. Adding `continue-on-error: true`
here would make a broken canary render **green**, defeating both the red-run
signal and the `if: failure()` reporting job. This composition point is easy to
get backwards by copying the Cargo Book recipe verbatim into a standalone file.

Why `nightly` is not a leg. Beta gives a dated, actionable prediction with an
upstream escalation path (Rust Book Appendix G). Nightly gives churn: rustls
`build.yml:463` date-pins nightly (`nightly-2026-03-20`) and rustls
`build.yml:449` comments "Do not deny warnings, as nightly clippy sometimes has
false negatives" — two independent mitigations that exist because floating
nightly is noisy. A template hands that noise to every fork. Recommend beta only,
and record "add a date-pinned nightly leg" as an explicitly available extension
if the template ever needs a nightly-only feature.

Why no `Swatinem/rust-cache` on this workflow. Its default cache key includes
`Cargo.lock`, which the `latest-deps` leg rewrites — so the leg would miss the
cache every week *and* deposit a cache entry keyed to a lockfile that exists
nowhere in the repository. Caching also directly opposes the lane's purpose on
the `next-toolchain` leg, where the point is a clean build under a new compiler.
R10 owns the caching decision for the *gating* workflow; this workflow opts out,
and that is a design statement, not an omission.

**Production usage and maintained reference implementations.** The recommended
composition is not novel; it is the intersection of published first-party
guidance and observed practice. Reference implementations, all retrieved
2026-09-10: the Cargo Book's `latest_deps` job (first-party, the freshness half);
`dtolnay/anyhow` `.github/workflows/ci.yml` (cron + `workflow_dispatch` +
`permissions: contents: read` + `fail-fast: false` + `timeout-minutes` + a beta
matrix leg — the closest single file to the recommended shape, missing only the
`cargo update` step); `BurntSushi/ripgrep` `.github/workflows/ci.yml` (cron +
pinned/stable/beta/nightly legs, with the least-privilege comment); py@b08bccfb
`.github/workflows/canary.yml` (the standalone schedule-only workflow shape,
`permissions: {}`, `concurrency`, `workflow_dispatch`, explicit "do NOT add
`--locked`"). I found **no** single public repository combining `cargo update`
freshness *and* a beta leg *and* issue-filing in one scheduled workflow — that
composition is this report's synthesis, and I state it as an evidence gap rather
than claim a reference implementation for the whole.

**Maturity, dependability, performance and integration cost.** Performance here
is CI wall-clock and runner-minutes, not throughput. Workload: one full
`cargo build` + `cargo test` of a CLI + library + web-service template, from a
cold `target/` (no cache, by design), three legs, once per week. I have **not**
measured this — no Rust template exists yet, so any minute figure would be
invented. What I can state with sources: both required runner images ship
Rust/Cargo 1.98.0 and Rustup 1.29.0 preinstalled (`actions/runner-images`
`images/ubuntu/Ubuntu2404-Readme.md` and `images/macos/macos-15-Readme.md`,
2026-09-10), so toolchain acquisition is a rustup delta, not a full install; and
`dtolnay/anyhow` — a much smaller crate — sets `timeout-minutes: 45`, which is
the practice anchor for the 30-minute guardrail proposed here. GitHub Actions is
free for public repositories, so for the template itself the marginal cost is
zero; the cost that matters is the one every *fork* inherits, which is the whole
reason architecture C (weekly) beats architecture B (every run).

**Minimal realistic example and acceptance check.** Minimal example: the workflow
above, against a workspace whose `Cargo.toml` declares at least one dependency
with a caret bound and a `rust-version` at the `msrv-policy` floor — the caret
bound is what gives `cargo update` room to move, and the floor is what makes the
resolver-override observable. Executable acceptance checks are specified under
`### Validation strategy`; every one of them is **proposed, not executed** — see
that section for what I did and did not run.

**BASELINE-REVIEW findings.**

BASELINE-REVIEW: F127 — early-warning-without-gating for upstream change — the ledger row's file-evidence pointer should include the CI job, not only the local recipe — `docs/port/COMMONALITY.md:133` and `docs/port/DIVERGENCE-ANALYSIS.md:146` both cite ts's advisory lane with the single file reference `Justfile:169`. Scope of this finding, stated precisely so it is not read as broader than it is: the prompt's `## Context` is **not** at fault — its D-036 summary (prompt line 11) does name a "non-required CI job via `oven-sh/setup-bun`", so the prompt already carries the fact; what is incomplete is the ledger's and the divergence analysis's *file-and-line evidence*, which is what a downstream item greps. ts@cb1cbcb2 `.github/workflows/ci.yml:141-188` also carries a full `bun-lane` job (`:142` `name: bun-lane (advisory, non-gating)`, `:144` `continue-on-error: true`, `:145-147` `permissions: contents: read`, `:175` `oven-sh/setup-bun@0c5077e51419868618aeaa5fe8019c62421857d6 # v2.2.0`, `:177` `bun-version: 1.3.14`, `:188` `bun run vitest run --exclude tests/e2e.test.ts`). This is load-bearing for R34: read as a Justfile recipe only, the ts precedent looks like a *local developer convenience* and the natural Rust analogue would be a `just` recipe; read with the CI job, ts's precedent is an automated, permission-scoped, SHA-pinned advisory CI lane, which is what this report recommends porting. Affected items: R34 (this item), and R11 `ci-workflow-job-structure` if it inventories ts's job list from the ledger rather than from the file. No ledger edit made here.

BASELINE-REVIEW: F126 + F127 — early-warning-without-gating for upstream change — the two rows describe one capability on two axes and should be satisfied by one workflow with isolated legs, not by two independently-shaped mechanisms — `docs/port/COMMONALITY.md:132-133` and `docs/port/DIVERGENCE-ANALYSIS.md:145-146` treat F126 (py-only, class D) and F127 (ts-only, class C) as separate facts whose Rust answers are independent, and DIVERGENCE-ANALYSIS's F127 question ("is that worth the ci-cost") is asked as if the beta lane must justify its own scheduling overhead. Evidence that they are one capability on two axes: py's own workflow header (py@b08bccfb `.github/workflows/canary.yml:1-11`) and ts's own job header (ts@cb1cbcb2 `.github/workflows/ci.yml:130-140`) state the same principle in the same terms — exercise a configuration the gate does not, never block a merge. Evidence that one file serves both in Rust: six surveyed projects (ripgrep, anyhow, serde, rustls, axum, clap) all express the toolchain axis as *matrix legs of an existing workflow*, never as a dedicated workflow; and py's canary already carries a matrix (py@b08bccfb `.github/workflows/canary.yml:38-40`, `python-version: ["3.12","3.13"]`) whose Rust analogue is a *channel* axis, not an interpreter axis. Consequence for the F127 cost question: the beta leg's marginal cost is one weekly ubuntu job on a schedule that already exists, so the answer is yes-for-beta / no-for-nightly, at a cost the standalone framing overstates. Affected items: R34 (this item), R11 `ci-workflow-job-structure` (which must know this workflow exists and is *not* part of the aggregate required check). No ledger edit made here.

### Recommendation

**One stack: a single weekly, non-gating `.github/workflows/canary.yml` that
varies exactly one upstream axis per matrix leg and files a de-duplicated issue
when a scheduled run fails.** Concretely — `on: schedule: cron '17 6 * * 2'` plus
`workflow_dispatch`; `permissions: {}` at the top with per-job grants;
`concurrency: {group: canary, cancel-in-progress: true}`; `timeout-minutes: 30`;
`fail-fast: false`; three legs — `latest-deps` on `stable` × {`ubuntu-latest`,
`macos-latest`} running `cargo update --verbose` under
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow` then `cargo test --workspace
--all-features --all-targets` and `cargo test --doc`, and `next-toolchain` on
`beta` × `ubuntu-latest` running the same tests with `--locked`; toolchains
installed by `dtolnay/rust-toolchain` (SHA-pinned); no dependency cache; a
`report` job gated on `failure() && github.event_name == 'schedule'` that uses
the preinstalled `gh` CLI to open or comment on one `canary`-labelled issue. No
`continue-on-error` anywhere, because the workflow is schedule-only and therefore
already incapable of gating. `cargo-edit`'s `cargo upgrade --incompatible` is
**not** in the stack; it is the documented ranked runner-up for a later
bound-rewriting lane.

Members: **M1 `cargo update` (Cargo built-in)**, **M2 `dtolnay/rust-toolchain`**,
**M3 the GitHub Actions scheduled-workflow guardrail pattern**, **M4 the GitHub
CLI (`gh`) failure-reporting step**.

### Members

#### M1 — `cargo update` (Cargo built-in dependency re-resolution)

##### Landscape
Bin: **built-in / first-party toolchain**. This is the freshness *mechanism* — the
step that makes the lane test something the merge gate does not. The Rust field
offers exactly four ways to reach a newer dependency graph: `cargo update`
(stable, respects declared bounds — the direct `uv sync --upgrade` analogue);
`cargo update --breaking` (rewrites bounds, but **nightly-only**);
`cargo-edit`'s `cargo upgrade --incompatible` (stable, rewrites bounds); and
deleting `Cargo.lock` (architecture A, rejected above). No other candidate exists
in the ecosystem. Authorities: `cargo-update(1)` and the Cargo Book's "Verifying
Latest Dependencies" recipe, which uses `cargo update --verbose` verbatim.

##### Principles and implementation
Preserves "exercise a configuration the gate deliberately does not" by
re-resolving `Cargo.lock` to the newest versions `Cargo.toml`'s bounds permit,
which is precisely the graph a downstream `cargo install` or `cargo add` user
gets and precisely the graph the pinned gating build never sees (Cargo FAQ,
2026-09-10: "`cargo install` will select the latest dependencies unless
`--locked` is passed in"). It mirrors py's semantics exactly — neither
`uv sync --upgrade` nor `cargo update` touches the declared bounds — so it
preserves the principle *at the same strength*, without escalating scope.
Implementation is one step, plus the environment variable that makes it
meaningful under edition 2024, plus its inverse on the toolchain leg:
```
CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow cargo update --verbose   # latest-deps leg
cargo test --workspace --all-features --all-targets --locked             # next-toolchain leg
```
`--verbose` is the Cargo Book's own choice and matters operationally: it prints
each version change, so the failing run's log names the dependency that moved.
Add `cargo report future-incompatibilities` as a final `if: always()` step: Cargo
already collects future-incompatibility warnings for all dependencies and prints
only a pointer notice (Cargo Book, future-incompat report, 2026-09-10), so the
report is a free third early-warning signal on a run where nobody is waiting.

##### Dominant choice
`cargo update`, from Cargo itself. Cargo ships with every Rust toolchain, is
preinstalled on both required runners (1.98.0), and the Cargo team publishes this
exact step for this exact purpose. There is no competing stable-channel tool for
the bounds-respecting upgrade.

##### Qualified shortlist
1. **`cargo update` (Cargo built-in)** — recommended. Figures below.
2. **`cargo-edit` `cargo upgrade --incompatible`** — the only stable-channel way
   to rewrite SemVer-incompatible bounds. `GET https://crates.io/api/v1/crates/cargo-edit`
   (2026-09-10): `crate.recent_downloads` 481,434; `crate.downloads` 3,546,657.
   `GET https://crates.io/api/v1/crates/cargo-edit/versions` (2026-09-10): newest
   non-yanked `0.13.13`, `created_at` 2026-07-15T18:05:21Z, `license`
   "Apache-2.0 OR MIT", `rust_version` "1.92", `crate_size` 78,869 bytes.
   `GET https://api.github.com/repos/killercup/cargo-edit` (2026-09-10):
   `stargazers_count` 3,451, `archived` false, `pushed_at` 2026-07-15T18:05:24Z.
   `GET https://api.github.com/search/issues?q=repo:killercup/cargo-edit+is:issue+is:open`
   (2026-09-10): `total_count` 68. Responsiveness, 10 most recently opened issues
   (8 were issues rather than pull requests): median 1.62 days to first
   maintainer comment (`author_association` ∈ OWNER/MEMBER/COLLABORATOR), 1
   unanswered. RustSec: `https://rustsec.org/packages/cargo-edit.html` returns
   HTTP 404 (2026-09-10) — no advisory page, i.e. no recorded advisory.
   Maintenance: **active**. Ranked second, not excluded — see `Ranked runner-up`.
3. **`cargo-minimal-versions`** — the *lower*-bound direction.
   `GET https://crates.io/api/v1/crates/cargo-minimal-versions` (2026-09-10):
   `recent_downloads` 17,382; `downloads` 112,918. Newest non-yanked `0.1.37`,
   `created_at` 2026-03-20T08:39:14Z. `GET https://api.github.com/repos/taiki-e/cargo-minimal-versions`
   (2026-09-10): `stargazers_count` 76, `archived` false, `pushed_at`
   2026-09-04T13:23:45Z. Open issues `total_count` 7. Maintenance: **active**
   (pushed within a week despite the 6-month release gap — the gap is a trigger
   to investigate, and the investigation shows an actively-pushed repository, so
   not `at-risk`). Solves a real and adjacent problem — five of the six surveyed
   projects run it — but it is not this item's problem, and it needs nightly to
   generate the lockfile. Recorded under `Up-and-comers`, not adopted.

##### Excluded by gate
- **`cargo update --breaking`** — excluded by the **stable Rust only** constraint
  (`## Constraints`). `cargo-update(1)` (2026-09-10): "This option is unstable and
  available only on the nightly channel and requires the `-Z unstable-options`
  flag to enable. See https://github.com/rust-lang/cargo/issues/12425". This is
  the decisive fact for the MEDIUM question on bound-rewriting: on stable, the
  built-in cannot do it, so `cargo-edit` is the *only* stable option, and that is
  why it stays on the shortlist rather than being dismissed as redundant.
- **Deleting `Cargo.lock` (architecture A)** — excluded on fit, not on a listed
  gate: it removes the determinism the Cargo FAQ names as the lockfile's purpose
  and would break the MSRV verification this template's fixed `msrv-policy`
  requires.
**All six fitness gates, per candidate in this member, stated rather than skipped.**

*`cargo update` (the recommendation).* (1) **License** — `inapplicable`: it is a
subcommand of the Cargo binary that ships with the toolchain and is preinstalled
on the runners; nothing is added to this repository's dependency tree or
redistributed, so there is no licence to reconcile with `MIT OR Apache-2.0`.
Recorded anyway: `rust-lang/cargo` reports `license.spdx_id` Apache-2.0
(`GET https://api.github.com/repos/rust-lang/cargo`, 2026-09-10), and Rust itself
is dual `MIT OR Apache-2.0`. (2) **MSRV** — `inapplicable`: Cargo is not a
dependency of this workspace, so it contributes no `rust-version` to the tree; the
relevant constraint is the inverse and is handled in the body — Cargo must be
*new enough* to honour `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS`, which needs
resolver `"3"`, i.e. Rust 1.84+, and both runners ship 1.98.0. (3) **Advisory /
`unsafe` posture** — no open RustSec advisory (`https://rustsec.org/packages/cargo.html`,
2026-09-10, lists only CVE-2019-16760, fixed in Rust 1.26.0). `unsafe` posture:
`inapplicable` as a code-safety property, because Cargo is an *executed tool*, not
linked into this template's binaries; whatever `unsafe` exists inside Cargo is
already inside every Rust installation this template requires. (4) **OS coverage** —
**passed**: Cargo 1.98.0 is preinstalled on both `ubuntu-24.04` and `macos-15`
(`actions/runner-images`, 2026-09-10). Windows: supported by Cargo, not exercised
here since `windows-latest` is outside the fixed matrix. (5) **Default features /
async-runtime coupling** — `inapplicable`: `cargo update` is a CLI invocation, not
a crate dependency, so it has no Cargo features to enable and no async runtime to
couple to. (6) **Binary size / compile time** — `inapplicable` as stated (nothing
is compiled *into* the template); the analogous cost is stated instead: `cargo
update` itself is a resolution step of seconds, and the compile cost it *causes* is
one cold-cache rebuild per leg, bounded by M3's `timeout-minutes: 30`.

*`cargo-edit` (the shortlisted, unadopted runner-up).* (1) **License** — **passed**:
manifest declares `license = "Apache-2.0 OR MIT"` (`https://raw.githubusercontent.com/killercup/cargo-edit/HEAD/Cargo.toml`
and `GET https://crates.io/api/v1/crates/cargo-edit/versions`, both 2026-09-10),
compatible with `MIT OR Apache-2.0`. (2) **MSRV** — **passed**: `rust_version`
`1.92` at 0.13.13, at or below `stable minus 2 minor` (1.96 as of stable 1.98.1
on 2026-09-10). Note it would be installed as a *dev tool binary*, never as a
dependency, so it contributes nothing to this workspace's MSRV either way. (3)
**Advisory / `unsafe` posture** — no open advisory (`https://rustsec.org/packages/cargo-edit.html`
returns HTTP 404, 2026-09-10, i.e. no advisory page exists). `unsafe` posture
**verified, not assumed**: the published 0.13.13 crate tarball
(`https://crates.io/api/v1/crates/cargo-edit/0.13.13/download`, retrieved and
extracted 2026-09-10) contains 84 `.rs` files and **zero `unsafe` blocks**; the
only five occurrences of the token are the identifier `unsafe_code` inside
`#![warn(...)]` attributes at `src/lib.rs:15` and the four binary entry points
(`src/bin/{add,rm,upgrade,set-version}/main.rs:8`) — lint-warned rather than
`#![forbid(unsafe_code)]`. (4) **OS coverage** — **passed**: a pure-Rust cargo
subcommand with no platform-specific code path in its manifest; it builds and runs
on both `ubuntu-latest` and `macos-latest`. Windows: supported upstream, not
exercised here. (5) **Default features / async-runtime coupling** — no async
runtime; it is a synchronous CLI, so there is no runtime coupling to declare. Its
own Cargo features are irrelevant to this template because it would be consumed as
an installed binary, not as a library dependency. (6) **Binary size / compile
time** — qualitatively: `crate_size` 78,869 bytes source, but a `cargo install
cargo-edit` from source is a multi-minute compile of a `cargo`-library-backed tool.
This is precisely why the runner-up entry specifies installing it via
`taiki-e/install-action` (a prebuilt binary, seconds) rather than `cargo install`,
should it ever be adopted. It adds **zero** bytes to this template's shipped
binaries, since it is a build-time tool that is never linked.

*`cargo update --breaking` and "delete `Cargo.lock`"* are excluded above on the
stable-only constraint and on fit respectively; neither reaches the remaining
gates.

##### Up-and-comers
`cargo-minimal-versions` (figures above) — wraps the nightly `-Z minimal-versions`
resolution so the *build* can still run on stable; it is the direction the Rust
library ecosystem actually invests in (anyhow `ci.yml:78-79`, serde
`ci.yml:121-122`, clap `ci.yml:192`, axum `CI.yml:131`, all HEAD 2026-09-10).
Worth revisiting for this template only if it begins publishing library crates
with wide caret bounds that consumers resolve downward; it does not serve the
early-warning principle this item owns.

##### Fit for this template
Strong, and specifically stronger here than for the libraries surveyed. This
template is CLI + library + web service (spec §4 D7) and will commit a
`Cargo.lock` for its binary — so newest-versions is *not* something CI sees for
free, unlike a lockfile-less library. The `--all-features` flag matters given
R69's `web-extra-surface` parameter is expected to put the web surface behind a
Cargo feature: without `--all-features` the canary would silently skip the entire
web dependency subtree, which is where the heaviest and fastest-moving
dependencies will live. The one hard requirement is
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow`, forced by the owner-fixed
`rust-edition = 2024` (→ resolver `"3"` → `fallback` default) combined with the
owner-fixed `msrv-policy` (→ a `rust-version` floor exists to fall back to).

##### Recommendation
Use `cargo update --verbose` with
`CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow` on the `latest-deps` legs, and
`--locked` on every `cargo test` invocation of the `next-toolchain` leg. Add
`cargo report future-incompatibilities` as an `if: always()` trailing step. Do
not adopt `cargo-edit` now.

##### Ranked runner-up
`cargo-edit` `cargo upgrade --incompatible --dry-run`. Rank 2. Adopt it if and
when the owner wants the canary to answer "are our *declared bounds* stale", a
strictly larger question than py's canary asks. Deliberately not adopted now for
three reasons: (i) it exceeds the source precedent — `uv sync --upgrade` does not
rewrite `pyproject.toml` bounds, so adopting `--incompatible` would make the Rust
lane test something neither source tests, which the research mandate treats as a
change requiring its own evidence rather than a port; (ii) a SemVer-incompatible
upgrade is *expected* to break compilation, so the leg would be red by design and
would train maintainers to ignore the canary — the exact failure mode a weekly
lane cannot survive; (iii) it adds an installed binary to a workflow that
currently needs none. If adopted, install it with `taiki-e/install-action`
(`GET https://api.github.com/repos/taiki-e/install-action`, 2026-09-10:
`stargazers_count` 537, `archived` false, `pushed_at` 2026-09-10T14:56:01Z,
`license.spdx_id` Apache-2.0), which the Cargo Book itself uses in its
"Verifying rust-version" example, and run it `--dry-run` into the run summary
rather than as a test gate.

##### Tradeoffs
Gains: exact semantic parity with py's canary; zero added dependencies; zero
added supply-chain surface; first-party documented recipe. Costs: (a) it cannot
see breakage that only a bound *rewrite* would expose — accepted, that is the
runner-up's job; (b) `cargo update` is only as useful as the bounds are loose, so
a template that pins `=x.y.z` anywhere makes the lane blind for those crates —
P03 should keep caret bounds in `Cargo.toml`; (c) the resolver-override env var is
an easy omission whose failure mode is a green no-op — mitigated by the
`Validation strategy` check that asserts the lockfile actually changed.

##### Parameters
`assumes rust-edition = 2024` — this is what forces resolver `"3"` and therefore
the `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow` override.
`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — the canary deliberately resolves past this floor; the floor is verified by a separate gating job (Cargo Book, "Verifying rust-version"), not by this lane.
`assumes web-extra-surface (R69)` — if the web surface is feature-gated, `--all-features` is required or the canary under-tests. Not a conflict: `--all-features` covers either outcome.
No `CONFLICT:` lines. This member owns no parameter.

##### Migration implications
`.github/workflows/canary.yml` — new file (see M3 for the full skeleton). No
change to `Cargo.toml`, `Cargo.lock`, or any source file. One documentation
paragraph in `CONTRIBUTING.md` explaining that a red canary is a signal, not a
blocker, mirroring py@b08bccfb `.github/workflows/canary.yml:1-11`.

##### Validation strategy
Proposed, not executed (no Rust template exists yet):
1. `git diff --exit-code Cargo.lock` immediately after
   `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow cargo update --verbose` in a
   workspace with at least one out-of-date caret-bounded dependency — expect
   **exit 1** (the lockfile changed). This is the check that proves the lane is
   not a green no-op.
2. Run `cargo update --dry-run` twice, once with and once without
   `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow`, in a workspace whose
   `rust-version` is below a dependency's — expect **different** proposed
   versions, proving the override is load-bearing rather than cargo-cult.
3. `cargo test --workspace --all-features --all-targets` after the update —
   expect pass on a healthy graph.

##### Confidence & re-verify trigger
**High.** The mechanism is first-party, the recipe is published by the Cargo team,
and the resolver interaction is documented normatively rather than inferred.
Re-verify when: `cargo update --breaking` stabilizes (watch
https://github.com/rust-lang/cargo/issues/12425 — stabilization would make the
`cargo-edit` runner-up unnecessary); the Cargo Book's "Verifying Latest
Dependencies" recipe changes; or the resolver default for
`resolver.incompatible-rust-versions` changes in a future edition.

##### Sources
- https://doc.rust-lang.org/cargo/guide/continuous-integration.html#verifying-latest-dependencies (2026-09-10) — the `latest_deps` recipe and the four architectures with their stated costs
- https://doc.rust-lang.org/cargo/commands/cargo-update.html (2026-09-10) — `cargo update` semantics; `--breaking` is nightly-only, `-Z unstable-options`, rust-lang/cargo#12425
- https://doc.rust-lang.org/cargo/reference/resolver.html (2026-09-10) — resolver `"3"` is the edition-2024 default (Rust 1.84+) and changes `resolver.incompatible-rust-versions` from `allow` to `fallback`; the `clap 4.0.32` vs `4.5.20` worked example
- https://doc.rust-lang.org/cargo/reference/config.html (2026-09-10) — `resolver.incompatible-rust-versions`, env `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS`, values `allow` / `fallback`
- https://doc.rust-lang.org/cargo/reference/future-incompat-report.html (2026-09-10) — `cargo report future-incompatibilities --id <ID>`, `[future-incompat-report] frequency`
- https://doc.rust-lang.org/cargo/faq.html#why-have-cargolock-in-version-control (2026-09-10) — determinism benefits; `cargo install` selects latest unless `--locked`
- `GET https://crates.io/api/v1/crates/cargo-edit` and `/versions` (2026-09-10); `GET https://api.github.com/repos/killercup/cargo-edit` (2026-09-10); `GET https://api.github.com/search/issues?q=repo:killercup/cargo-edit+is:issue+is:open` (2026-09-10); https://rustsec.org/packages/cargo-edit.html → HTTP 404 (2026-09-10)
- `GET https://crates.io/api/v1/crates/cargo-minimal-versions` and `/versions`; `GET https://api.github.com/repos/taiki-e/cargo-minimal-versions` (both 2026-09-10)
- py@b08bccfb `.github/workflows/canary.yml:44-47` — "do NOT add `--locked` here"; `uv sync --upgrade --group dev --extra web`

#### M2 — `dtolnay/rust-toolchain` (advisory `beta` toolchain leg)

##### Landscape
Bin: **established industry standard**, with a **built-in** fallback. Two ways to
put `beta` on a runner: the `dtolnay/rust-toolchain` action, or bare `rustup`
(preinstalled — `actions/runner-images` `images/ubuntu/Ubuntu2404-Readme.md` and
`images/macos/macos-15-Readme.md`, 2026-09-10, both list Rustup 1.29.0 and Rust
1.98.0). The historical third option, `actions-rs/toolchain`, is archived. All six
surveyed projects use `dtolnay/rust-toolchain` (ripgrep `ci.yml:128`, anyhow
`ci.yml:31`, serde `ci.yml:22`, rustls `build.yml:281`, clap `ci.yml:72`, axum
`CI.yml:22` — all HEAD, 2026-09-10); the Cargo Book's own examples use bare
`rustup update`.

##### Principles and implementation
Preserves the same principle on the toolchain axis and preserves the *non-gating*
property structurally (schedule-only workflow), not by convention. It is a
justified ecosystem *difference* from ts rather than a copy: ts substitutes a
competing runtime because JS has one; Rust substitutes a *future* compiler
because Rust's release train guarantees one exists and the Rust project asks
downstream CI to test it (Rust Book Appendix G, 2026-09-10). Implementation:
```yaml
- uses: dtolnay/rust-toolchain@<full-sha>   # master rev, version comment
  with:
    toolchain: beta
```
Referencing `@master` with an explicit `toolchain:` input is the documented usage
when the channel is parameterised — the action's README (HEAD, 2026-09-10) states
"the default is to match the `@rev` … When passing an explicit `toolchain` as an
input instead of `@rev`, you'll want to use `dtolnay/rust-toolchain@master`".
Under a SHA-pinning policy (R20) the pin is the SHA and the comment records the
rev. HEAD of `master` at 2026-09-03T15:22:19Z is
`d1031067263f94b142dd6c0ce24c5eb9d02d52a0`
(`GET https://api.github.com/repos/dtolnay/rust-toolchain/commits/master`, 2026-09-10);
P03 must re-read this rather than copy it, since it moves.

##### Dominant choice
`dtolnay/rust-toolchain`. Unanimous across the practice survey; no maintained
alternative action exists.

##### Qualified shortlist
1. **`dtolnay/rust-toolchain`** — recommended.
   `GET https://api.github.com/repos/dtolnay/rust-toolchain` (2026-09-10):
   `stargazers_count` 1,574; `archived` false; `pushed_at` 2026-09-03T15:22:58Z;
   `license.spdx_id` MIT.
   `GET https://api.github.com/search/issues?q=repo:dtolnay/rust-toolchain+is:issue+is:open`
   (2026-09-10): `total_count` 8.
   Responsiveness, 10 most recently opened items (9 were issues): only 1 received
   a maintainer comment, at 0.05 days; 8 had no maintainer comment. That figure
   overstates neglect and I investigated rather than reporting it flat: issue #176
   was closed 5 h 28 min after opening with 0 comments and #175 was closed 19 min
   after opening with 0 comments
   (`GET https://api.github.com/repos/dtolnay/rust-toolchain/issues?state=all&sort=created&direction=desc`,
   2026-09-10) — this maintainer resolves by commit rather than by comment, so
   time-to-*resolution* is hours while time-to-*comment* is undefined. Both
   figures are reported; neither is presented as the other.
   Maintenance: **active** (pushed within 7 days; 8 open issues total).
2. **Bare `rustup toolchain install beta --profile minimal && rustup default beta`** —
   zero third-party actions. Rank 2; see `Ranked runner-up`.

##### Excluded by gate
**All six fitness gates on `dtolnay/rust-toolchain`, the recommendation, stated
rather than skipped.** (1) **License** — `inapplicable` as a distribution
constraint: a GitHub Action is executed on a runner, never vendored into this
repository or linked into its binaries, so it imposes nothing on the template's
`MIT OR Apache-2.0` licence. Recorded anyway: `license.spdx_id` **MIT**
(`GET https://api.github.com/repos/dtolnay/rust-toolchain`, 2026-09-10), which is
compatible in any case. (2) **MSRV** — `inapplicable`: the action is a composite
action of shell steps driving `rustup`; it contains no Rust crate and enters no
dependency tree, so it declares and constrains no `rust-version`. (3) **Advisory /
`unsafe` posture** — `inapplicable`: not a crate, so no RustSec package page
exists and `unsafe` has no meaning for it. The analogous risk is supply-chain
(an action executes on the runner with the job's token), addressed by the SHA pin
required under R20 and by the job's `permissions: contents: read`. (4) **OS
coverage** — **passed**: it drives `rustup`, and Rustup 1.29.0 is preinstalled on
both `ubuntu-24.04` and `macos-15` (`actions/runner-images`, 2026-09-10), so the
action works identically on both OSes in the fixed matrix. Windows: supported
upstream, outside this template's matrix. (5) **Default features / async-runtime
coupling** — `inapplicable`: no Cargo features and no Rust async runtime; a
composite action has neither. (6) **Binary size / compile time** — `inapplicable`
as stated (nothing is compiled into the template); the analogous cost is stated
instead: the action installs a **minimal** rustup profile, so the beta leg pays a
toolchain-download delta of tens of seconds rather than a full install, and adds
zero bytes to any shipped artifact.

Genuinely excluded in this member:
- **`actions-rs/toolchain`** — excluded: `archived: true`, `pushed_at`
  2023-06-18T05:26:38Z (`GET https://api.github.com/repos/actions-rs/toolchain`,
  2026-09-10). Fails the maintenance rubric outright (`archived`) — the rubric's
  own `archived` verdict, needing no further signal.
- **`Swatinem/rust-cache`** — not excluded by a gate but explicitly *not used on
  this workflow*: its default cache key includes `Cargo.lock`, which the
  `latest-deps` leg rewrites, so it would miss every week and pollute the cache;
  and caching opposes the clean-build purpose of the `next-toolchain` leg. Noted
  additionally because `GET https://api.github.com/repos/Swatinem/rust-cache`
  (2026-09-10) reports `license.spdx_id` **LGPL-3.0**, which is a licensing fact
  R10 should weigh for the gating workflow; a GitHub Action is executed, not
  linked into the binary, so it does not affect this template's
  `MIT OR Apache-2.0` distribution — flagged for R10, not decided here.

##### Up-and-comers
None with traction. Worth recording that `dtolnay/rust-toolchain`'s `action.yml`
(HEAD, 2026-09-10) accepts a `stable <N> <unit>s ago` toolchain specification
(e.g. `stable 12 weeks ago`), which is a direct mechanical expression of this
template's `msrv-policy` ("stable minus 2 minor versions" ≈ `stable 12 weeks
ago`). That is R11's/R30's to use for the MSRV job, not this lane's, but it is a
concrete reason the same action will already be pinned in the repository.

##### Fit for this template
Good, with one composition caveat and one deliberate scope limit.
Caveat: the beta leg must run `--locked` so the dependency graph is held constant
and a failure is attributable to the compiler. Without it, a red beta leg could
be a dependency's fault and the lane loses its diagnostic value.
**Reconciling this member with the `Stable Rust only` constraint** (`## Constraints`),
which the same report invokes to exclude `cargo update --breaking`. The two are
consistent, and the distinction is what the constraint governs: it governs what
the template *requires in order to build and ship* — its source may use no
unstable feature, and no gate may depend on a non-stable channel. `cargo update
--breaking` would violate that, because adopting it makes a lane *depend* on
nightly to function at all. The beta leg violates nothing, because it **requires
nothing of the code**: it compiles the same edition-2024, stable-only source with
the same `--locked` dependency graph, enables no `#![feature(...)]`, gates no
merge, and is never a prerequisite for building, testing or releasing the
template. It is an *observer* of a compiler the project does not depend on. A red
beta leg is therefore information about a future stable release — the Rust
project's own stated purpose for such a lane (Rust Book Appendix G, 2026-09-10) —
and never a statement that this template needs a non-stable toolchain. The
operative test: delete the beta leg and every gate, build and release path is
unchanged; delete stable and nothing works. The same reasoning is why a *nightly*
leg would also not breach the constraint — nightly is rejected on noise (see
`### Principles and implementation`), not on the stable-only rule.

Scope limit: the beta leg runs on `ubuntu-latest` only. This is a *cost* choice,
not a support gap — `rustup`, and therefore this action, works identically on
`macos-latest` (Rustup 1.29.0 is preinstalled on `macos-15`), and compiler
regressions in a pure-Rust CLI/library/web template are overwhelmingly
platform-independent. The `latest-deps` legs cover both OSes in the fixed
`target-os-matrix`, so the workflow as a whole satisfies the constraint that every
recommendation work on both. Widening trigger recorded below.

##### Recommendation
`dtolnay/rust-toolchain@<sha>  # master` with `toolchain: ${{ matrix.toolchain }}`,
one `beta` leg on `ubuntu-latest`, `--locked` on its `cargo test`. No `nightly`
leg. No `continue-on-error` (the workflow is schedule-only).

##### Ranked runner-up
Bare `rustup`: `rustup toolchain install beta --profile minimal && rustup default beta`.
Rank 2. Genuinely attractive — it removes a third-party action from an advisory
workflow, which is the least valuable place to spend supply-chain surface, and
`rustup` is preinstalled on both required images. It is ranked second only
because the gating workflow (R11) will almost certainly pin
`dtolnay/rust-toolchain` anyway, so reusing it here adds **zero new** pinned
third-party surface while gaining `--profile minimal` behavior, the `cachekey`
output, and consistency across the two workflows. **Conditional switch:** if R11
decides the gating workflow uses bare `rustup`, this member should follow R11 and
use bare `rustup` too, rather than introducing the repository's only
`dtolnay/rust-toolchain` pin for a non-gating lane.

##### Tradeoffs
Gains: one line; unanimous ecosystem practice; installs a minimal profile so the
leg does not pay for docs it will not read; upstream-reportable failures. Costs:
one more SHA to pin and to keep current (shared with R11/R20); a `@master` pin
needs a version *comment* rather than a tag, since the repository publishes only
`v1` plus per-version branches (`GET https://api.github.com/repos/dtolnay/rust-toolchain/tags`,
2026-09-10: single tag `v1`); and the beta leg costs one weekly ubuntu job whose
value is zero in any week when beta has no regression — which is most weeks
("Breakage in a beta release is relatively rare", Rust Book Appendix G).

##### Parameters
`assumes target-os-matrix = ubuntu-latest, macos-latest` — the `latest-deps` legs
cover both; the `beta` leg covers `ubuntu-latest` only, by cost, and would work
unchanged on `macos-latest`.
`assumes ci-job-structure (R11)` — specifically, that R11 does **not** include
this workflow's jobs in the aggregate required status check (R12), or the lane
would gate and the principle would be violated. Not a conflict: R12's aggregate
check enumerates jobs from the gating workflow, and this is a separate file.
No `CONFLICT:` lines. This member owns no parameter.

##### Migration implications
`.github/workflows/canary.yml` — the toolchain step and the `next-toolchain`
matrix leg. If R20's pinning policy requires full-SHA pins with version comments
(as ts does — ts@cb1cbcb2 `.github/workflows/ci.yml:168-175`), this line carries
one. Nothing else in the template changes.

##### Validation strategy
Proposed, not executed:
1. `rustc +beta --version` printed as the leg's first step — expect a version one
   minor above stable (today: `1.99.0-beta.4` against stable `1.98.1` — the `[pkg.rustc] version` field of
   `https://static.rust-lang.org/dist/channel-rust-beta.toml` and the `cargo-1.98.1-*` artifact names in
   `channel-rust-stable.toml`, both 2026-09-10). This asserts the leg is actually on
   beta rather than silently falling back to the preinstalled stable.
2. `cargo +beta test --workspace --all-features --all-targets --locked` — expect
   pass; expect `git diff --exit-code Cargo.lock` to report **no change**,
   asserting the toolchain leg held its graph constant.
3. `actionlint .github/workflows/canary.yml` — expect clean.

##### Confidence & re-verify trigger
**High** for the action choice (unanimous practice, active maintenance).
**Medium-high** for the beta-only, ubuntu-only scoping — it is a cost judgment,
not a fact. Re-verify when: the template adds platform-specific code, `unsafe`,
build scripts, or a `windows-latest` runner (widen the beta leg to the full OS
matrix); the template adopts a nightly-only feature (add a *date-pinned* nightly
leg, following rustls `build.yml:463`); `dtolnay/rust-toolchain` goes 6 months
without a push or is archived; or R11 selects bare `rustup` for the gating
workflow.

##### Sources
- https://doc.rust-lang.org/book/appendix-07-nightly-rust.html (2026-09-10) — the six-week train; "test against beta in their CI system to help Rust discover possible regressions"; "you can report it to the team and get it fixed before the next stable release happens"; "Breakage in a beta release is relatively rare"
- https://static.rust-lang.org/dist/channel-rust-stable.toml (2026-09-10) — `date = "2026-09-03"`; `[pkg.cargo] version = "0.99.0 (797e8a9bc 2026-08-05)"`; artifact URLs named `cargo-1.98.1-<target>`, i.e. stable is Rust 1.98.1
- https://static.rust-lang.org/dist/channel-rust-beta.toml (2026-09-10) — `date = "2026-09-06"`; `[pkg.rustc] version = "1.99.0-beta.4 (948ec4e1e 2026-09-04)"`; `[pkg.cargo] version = "0.100.0-beta.4"`
- https://raw.githubusercontent.com/dtolnay/rust-toolchain/HEAD/README.md and `/action.yml` (2026-09-10) — `@rev` selects the channel; `@master` + `toolchain:` input; `stable <N> <unit>s ago` specification; `cachekey` output
- `GET https://api.github.com/repos/dtolnay/rust-toolchain`, `/commits/master`, `/tags`, `/issues?state=all&sort=created&direction=desc`; `GET https://api.github.com/search/issues?q=repo:dtolnay/rust-toolchain+is:issue+is:open` (all 2026-09-10)
- `GET https://api.github.com/repos/actions-rs/toolchain` (2026-09-10) — `archived: true`
- `GET https://api.github.com/repos/Swatinem/rust-cache` (2026-09-10) — `license.spdx_id` LGPL-3.0
- https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md and `/images/macos/macos-15-Readme.md` (2026-09-10) — Rust 1.98.0, Rustup 1.29.0 preinstalled
- Practice files (HEAD, 2026-09-10): ripgrep `ci.yml:128`; anyhow `ci.yml:27,31`; serde `ci.yml:22,46,57`; rustls `build.yml:33-50,449,463`; clap `ci.yml:63,72`; axum `CI.yml:22,88,103`
- ts@cb1cbcb2 `docs/port/TS_PORT_DECISIONS.md:413-417` (D-036) and `.github/workflows/ci.yml:141-188`

#### M3 — GitHub Actions scheduled-workflow guardrail pattern

##### Landscape
Bin: **built-in / first-party** (GitHub Actions workflow syntax). This member is
a pattern, not a crate: the trigger, permission, concurrency, timeout and
matrix surface that makes a weekly lane cheap, safe and non-gating. Candidates in
the field are the trigger shapes themselves — `schedule:` (py's choice and the
Cargo Book's third architecture), `on: push/pull_request` with
`continue-on-error: true` (ts's choice and the Cargo Book's second architecture),
and `repository_dispatch`/`workflow_call` (neither used by any surveyed project
for this purpose). Authorities: the GitHub Actions events reference, and the
Cargo Book's enumeration of the schedule architecture's two costs.

##### Principles and implementation
This is the member that makes "cannot block a merge" **structural**. A workflow
whose only triggers are `schedule` and `workflow_dispatch` never runs on a pull
request, so it cannot appear in a required status check and cannot be the reason
a merge is blocked — the same guarantee py states in prose (py@b08bccfb
`.github/workflows/canary.yml:9-11`) and ts obtains instead via
`continue-on-error: true` because its lane shares a gating workflow (ts@cb1cbcb2
`.github/workflows/ci.yml:144`). Rust can take the stronger, structural form.

The guardrails, each with its source and its reason:

| Guardrail | Value | Why |
|---|---|---|
| `on: schedule: cron` | `'17 6 * * 2'` | Weekly, matching py's cadence (py@b08bccfb `.github/workflows/canary.yml:16`, `'0 6 * * 2'`). Minute 17 rather than 0: GitHub's own advice — "The `schedule` event can be delayed during periods of high loads … To decrease the chance of delay, schedule your workflow to run at a different time of the hour" (GitHub Actions events reference, 2026-09-10). `@weekly` is unavailable: "GitHub Actions does not support the non-standard syntax `@yearly`, `@monthly`, `@weekly`, `@daily`, `@hourly`, and `@reboot`" |
| `workflow_dispatch:` | present | Manual triage re-run; both sources have it in spirit (py@b08bccfb `.github/workflows/canary.yml:17`) and it is the mitigation for GitHub's 60-day auto-disable |
| `permissions: {}` top-level | empty, per-job grants below | py's exact shape (py@b08bccfb `.github/workflows/canary.yml:19`). ripgrep `ci.yml:10-28` gives the rationale in a comment: the top-level block exists "to drop write-all permissions that are granted on `schedule` event … By specifying any permission explicitly all others are set to none." Canary job: `contents: read`. Report job: `contents: read` + `issues: write` |
| `concurrency` | `group: canary`, `cancel-in-progress: true` | py's exact shape (py@b08bccfb `.github/workflows/canary.yml:21-23`). Tradeoff to record: with `cancel-in-progress: true`, a manual `workflow_dispatch` cancels an in-flight scheduled run. Acceptable for a lane whose whole point is the *latest* answer; set `false` if P03 prefers both to complete |
| `timeout-minutes` | `30` | py's canary has **none** — a gap this port closes. Practice anchor: `dtolnay/anyhow` `ci.yml:30` sets `timeout-minutes: 45` for a far smaller crate. A weekly cold-cache build of a CLI + library + web-service template should not be allowed to burn the 6-hour job default on a hang |
| `fail-fast: false` | present | py's explicit choice with its reason (py@b08bccfb `.github/workflows/canary.yml:36-37`: "report both Python legs even if one breaks"); ripgrep `ci.yml:51`; anyhow `ci.yml:25`. Without it, one red leg hides the other two |
| `continue-on-error` | **absent** | See `Excluded by gate` — including it here would be a bug, not a safety belt |
| matrix `include:` | 3 explicit legs | An explicit `include:` list, not a cross product, so exactly one upstream variable moves per leg. ripgrep `ci.yml:53-66` uses the same technique |

##### Dominant choice
The schedule-only standalone workflow (Cargo Book architecture C), carrying the
guardrail set above. This is py's shape, hardened with the `timeout-minutes` py
lacks and the matrix axis re-mapped from interpreter versions to the
freshness/toolchain axes.

##### Qualified shortlist
1. **Schedule-only standalone workflow** — recommended.
2. **`continue-on-error` job inside the gating `ci.yml`** (ts's shape, Cargo Book
   architecture B) — rank 2, see `Ranked runner-up`.
3. **Both** — a weekly canary *and* a per-run advisory beta job. Rejected on cost
   for a template: every fork pays for a full extra build on every PR forever, to
   compress detection latency from ≤7 days to ≤1 PR on an axis (beta) whose
   change cadence is 6 weeks. The latency reduction buys nothing against a
   six-week train.

##### Excluded by gate
The six crate fitness gates are **inapplicable** to this member and I state each
reason rather than omitting them: (1) *license* — inapplicable: GitHub Actions
workflow syntax is a platform feature, not a distributed artifact, so it carries
no license to reconcile with `MIT OR Apache-2.0`; (2) *MSRV* — inapplicable: YAML
triggers execute on GitHub's runners and enter no Rust dependency tree; (3)
*RustSec advisory / `unsafe` posture* — inapplicable: not a crate, so RustSec has
no package page and `unsafe` has no meaning; the analogous risk is workflow
permission scope, addressed above with `permissions: {}` and per-job grants, and
owned in general by R08; (4) *OS coverage* — **applicable and passed**:
`schedule`, `workflow_dispatch`, `permissions`, `concurrency`, `timeout-minutes`
and `strategy.matrix` are runner-independent workflow syntax and behave
identically for `ubuntu-latest` and `macos-latest` jobs; (5) *default features /
async-runtime coupling* — inapplicable: no crate features and no Rust runtime; (6)
*binary size / compile time* — inapplicable as stated, and its analogue is stated
instead: the pattern's cost is runner-minutes, bounded by `timeout-minutes: 30` ×
3 legs weekly, on a platform that bills public repositories nothing.
Genuinely excluded here: **`continue-on-error: true`** — excluded on correctness.
In a schedule-only workflow it converts a failed canary into a green run,
suppressing both the red-run signal and the `if: failure()` reporting job. It
belongs to architecture B, where the job shares a gating workflow, and copying it
across from the Cargo Book recipe into a standalone file is the single most
likely implementation error in this whole item.

##### Up-and-comers
None. Trigger syntax is stable platform surface; the only recent movement is
`schedule`'s optional IANA `timezone:` field (GitHub Actions events reference,
2026-09-10, with a documented daylight-saving caveat: "during DST spring-forward
transitions, scheduled workflows in skipped hours advance to the next valid
time"). Not adopted — UTC is unambiguous and the lane is weekly, so an hour of
seasonal drift is meaningless.

##### Fit for this template
Strong, with one platform hazard that must be documented rather than solved in
YAML. GitHub Actions events reference (2026-09-10): "In a public repository,
scheduled workflows are automatically disabled when no repository activity has
occurred in 60 days." The Cargo Book independently names this exact cost of
architecture C: "A hosted CI service may disable scheduled jobs for repositories
that haven't been touched in a while, affecting passively maintained packages."
For a **template** repository this is a sharp edge: forks are often quiet for
months, so a fork's canary can be silently off when it is most needed. There is
no YAML mitigation. Mitigations that do work, and belong in P03's docs: (a)
`workflow_dispatch` so it can always be run by hand; (b) a `CONTRIBUTING.md` note
that a quiet fork must re-enable the workflow in the Actions tab; (c) the M4
issue-filing job, which makes a *working* canary visible enough that its absence
is noticed. Two further platform facts constrain the design: scheduled workflows
"will only run on the default branch", so the file must be merged to `main`
before it ever runs and cannot be tested on a branch by schedule alone
(`workflow_dispatch` is the only branch-testable path); and the minimum interval
is 5 minutes, far below anything wanted here.

##### Recommendation
Adopt the guardrail set in the table above verbatim, as one standalone
`.github/workflows/canary.yml`. Ship the 60-day auto-disable caveat and the
"a red canary is a signal, not a blocker" statement as a documented paragraph,
mirroring py's in-file header comment (py@b08bccfb
`.github/workflows/canary.yml:1-11`), which is itself the best precedent in
either source repository for making a lane's non-gating status legible.

##### Ranked runner-up
Architecture B — a `continue-on-error: true` job inside the gating `ci.yml`, as
ts does (ts@cb1cbcb2 `.github/workflows/ci.yml:141-144`) and as the Cargo Book
lists second. Rank 2. Its one real advantage is that it cannot be auto-disabled
by inactivity, which is precisely the recommended architecture's one real
weakness. Adopt it instead if the owner judges the 60-day auto-disable
unacceptable for a template whose forks go quiet; the price is a permanent
per-PR build for every fork, and the Cargo Book's own warning that "failures
might not be obvious" when a green-looking run contains a red advisory job.

##### Tradeoffs
Gains: non-gating by construction rather than by flag; costs only weekly
runner-minutes; least-privilege by default; py-precedented and Cargo-Book-listed.
Costs: the 60-day auto-disable; scheduled runs can be delayed or dropped under
platform load ("If the load is sufficiently high enough, some queued jobs may be
dropped" — GitHub Actions events reference, 2026-09-10), so a missed week is
possible and the lane must not be treated as a guarantee; and detection latency is
up to 7 days.

##### Parameters
`assumes target-os-matrix = ubuntu-latest, macos-latest` — the matrix legs use
both.
`assumes ci-job-structure (R11)` and the aggregate required check (R12) — this
workflow's jobs must not be enumerated in the required check. Structurally they
cannot be, since they never run on a pull request; recorded so R12 does not add
them by name.
`assumes third-party-action-pinning-policy (R20)` — whatever pin form R20
selects applies to the `actions/checkout` and `dtolnay/rust-toolchain` uses here.
`assumes workflow-permission-hardening (R08)` — the `permissions: {}` + per-job
grant shape used here should match whatever R08 standardises; it already matches
both sources.
Cadence coupling, not a conflict: py deliberately offsets its canary from its
dependency-audit workflow (py@b08bccfb `.github/workflows/canary.yml:16` —
"weekly, Tuesday 06:00 UTC (offset from dep-audit's Monday)"). R13 owns the
vulnerability-scan schedule; P03 should keep the two on different days for the
same reason py does. No `CONFLICT:` lines. This member owns no parameter.

##### Migration implications
`.github/workflows/canary.yml` — new file, the container for M1, M2 and M4.
`CONTRIBUTING.md` (or the template's maintenance doc) — a short section: what the
canary is, that a red canary blocks nothing, that a quiet fork must re-enable it
after 60 days, and how to re-run it by hand. No change to `Cargo.toml`,
`Cargo.lock`, `Justfile`, `lefthook.yml` or any source file. Explicitly **not**
added to the aggregate required status check (R12).

##### Validation strategy
Proposed, not executed:
1. `actionlint .github/workflows/canary.yml` — expect clean. (ts pins an
   `actionlint` action schema config at ts@cb1cbcb2 `.github/actionlint.yaml:1`,
   so the tool is already precedented in the org.)
2. `gh workflow run canary.yml --ref main` then `gh run watch` — expect three
   `canary` legs, `fail-fast: false` behavior on an induced single-leg failure,
   and **no** `report` job (because `github.event_name` is `workflow_dispatch`,
   not `schedule`).
3. `gh api repos/<o>/<r>/branches/main/protection/required_status_checks` —
   expect the canary job names to be **absent**, proving the lane cannot gate.
4. Induce a failure on one leg and confirm the workflow run is **red**, not green
   — the regression test for an accidental `continue-on-error: true`.

##### Confidence & re-verify trigger
**High** for the guardrail set (first-party documented behavior plus two
source-repo precedents). **Medium** for the weekly-versus-daily cadence: four of
the six surveyed projects run *daily* (ripgrep `'00 01 * * *'`, anyhow and serde
`'40 1 * * *'`, rustls `'0 18 * * *'`), and weekly is chosen here to match py's
recorded cadence and to keep a template's inherited cost low, not because daily
was shown to be wrong. Re-verify when: GitHub changes the 60-day auto-disable or
the `schedule` semantics; R13 sets its scan day (to keep the offset); the
template's dependency graph grows enough that weekly detection latency starts
producing multi-cause failures that are hard to triage — that is the concrete
trigger to move to daily.

##### Sources
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows (2026-09-10) — `schedule`: 60-day auto-disable in public repositories; default-branch-only; high-load delay and dropped jobs; 5-minute minimum; no `@weekly` shorthand; optional `timezone:` with the DST caveat
- https://doc.rust-lang.org/cargo/guide/continuous-integration.html#verifying-latest-dependencies (2026-09-10) — the four architectures and the two stated costs of the scheduled one
- py@b08bccfb `.github/workflows/canary.yml:1-11` (principle), `:16-17` (cron + dispatch), `:19` (`permissions: {}`), `:21-23` (concurrency), `:36-40` (`fail-fast: false`, matrix)
- ts@cb1cbcb2 `.github/workflows/ci.yml:130-147` (advisory job header, `continue-on-error: true`, `permissions: contents: read`); `.github/actionlint.yaml:1`
- Practice files (HEAD, 2026-09-10): ripgrep `.github/workflows/ci.yml:7-8,10-28,51,53-66`; anyhow `.github/workflows/ci.yml:5,7,9-10,25,27,30`; serde `.github/workflows/ci.yml:7,29,46,57`; rustls `.github/workflows/build.yml:13-14,33-50`; clap `.github/workflows/ci.yml:63`; axum `.github/workflows/CI.yml:88,150`

#### M4 — GitHub CLI (`gh`) de-duplicated failure reporting

##### Landscape
Bin: **built-in / first-party** on the runner (`gh` is preinstalled), with
**established industry standard** alternatives as actions. This member answers the
MEDIUM question: should the canary open an issue or only fail loudly, and by what
mechanism? Candidates: the preinstalled `gh` CLI; `actions/github-script`
(GitHub's own JS wrapper around Octokit); `peter-evans/create-issue-from-file`;
`JasonEtco/create-an-issue`; or nothing at all (py's actual behavior — py's canary
files nothing; py@b08bccfb `.github/workflows/canary.yml` has no reporting step).

##### Principles and implementation
This is the member that satisfies "a failure is routed to somebody who can act on
it", the third must-agree property. The Cargo Book names its absence as a specific
cost of the scheduled architecture: "Depending on the CI service, notifications
might not be routed to people who can act on the failure." On GitHub, a failed
scheduled run notifies the last committer to the default branch, who is very
often not the person who can act, and it produces no artifact anyone reviews. An
issue is durable, assignable, searchable, and its *absence* over weeks is itself
a signal that the workflow was auto-disabled. Implementation, as a job:
```yaml
report:
  needs: [canary]
  if: failure() && github.event_name == 'schedule'
  runs-on: ubuntu-latest
  permissions: { contents: read, issues: write }
  steps:
    - env:
        GH_TOKEN: ${{ github.token }}
        RUN_URL: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
      run: |
        set -euo pipefail
        gh label create canary --color FBCA04 --description "Scheduled freshness lane" --force
        n=$(gh issue list --label canary --state open --limit 1 --json number --jq '.[0].number // empty')
        if [ -n "$n" ]; then
          gh issue comment "$n" --body "Canary failed again: $RUN_URL"
        else
          gh issue create --label canary \
            --title "canary: scheduled freshness run failed" \
            --body "The weekly dependency/toolchain freshness lane failed. This blocks nothing. Run: $RUN_URL"
        fi
```
Three details carry the design. `if: failure() && github.event_name == 'schedule'`
— a `workflow_dispatch` run is being watched by a human, so filing an issue for it
is noise. The `gh issue list --label canary --state open` lookup before creating
— without de-duplication a persistent upstream breakage files a new issue every
week, and a weekly-noise lane gets muted, which is the failure mode this member
exists to prevent. `gh label create --force` — `gh issue create --label` fails if
the label does not exist, and `--force` makes the step idempotent so a fresh fork
of the template works on its first red canary without manual setup.

##### Dominant choice
No single dominant choice exists in the surveyed Rust projects: **none of the six
files a canary issue**, and neither does py. This member is therefore an
*improvement on both sources' precedent*, justified by the Cargo Book's own
stated cost of the architecture and by GitHub's 60-day auto-disable, not by a
practice majority. I state that plainly rather than manufacturing a consensus.

##### Qualified shortlist
1. **`gh` CLI, preinstalled** — recommended. Figures for the tool itself:
   `GET https://api.github.com/repos/cli/cli` (2026-09-10) —
   `stargazers_count` 46,219; `archived` false; `pushed_at` 2026-09-10T14:05:34Z;
   `license.spdx_id` MIT. Latest release `v2.100.0`, `published_at`
   2026-09-03T15:43:20Z (`GET https://api.github.com/repos/cli/cli/releases`).
   Open issues `total_count` 1,025
   (`GET https://api.github.com/search/issues?q=repo:cli/cli+is:issue+is:open`).
   Preinstalled version on both required images: **GitHub CLI 2.98.0**
   (`actions/runner-images` `images/ubuntu/Ubuntu2404-Readme.md` and
   `images/macos/macos-15-Readme.md`, main, 2026-09-10). Maintenance: **active**.
2. **`actions/github-script`** — rank 2. `GET https://api.github.com/repos/actions/github-script`
   (2026-09-10): `stargazers_count` 5,018; `archived` false; `pushed_at`
   2026-04-09T22:46:34Z; `license.spdx_id` MIT. Latest release `v9.0.0`,
   `published_at` 2026-04-09T22:57:15Z. Open issues `total_count` 58.
   Responsiveness, 10 most recently opened items (6 were issues): **0** received a
   maintainer comment; median undefined. Maintenance: **stable-quiet** — 5 months
   since the last push and no maintainer engagement on recent issues are triggers
   to investigate, but the repository is GitHub-owned, is a thin wrapper over
   Octokit, and has no unpatched advisory, broken build or maintainer notice, so
   the rubric's bar for `at-risk` (a concrete signal) is not met. Reported with
   the caveat visible rather than rounded to "active".
3. **`peter-evans/create-issue-from-file`** — rank 3.
   `GET https://api.github.com/repos/peter-evans/create-issue-from-file`
   (2026-09-10): `stargazers_count` 177; `archived` false; `pushed_at`
   2026-09-03T00:38:34Z; `license.spdx_id` MIT. Latest release `v6.0.0`,
   `published_at` 2025-10-01T14:45:11Z. Open issues `total_count` 6.
   Responsiveness: of the 10 most recently opened items, 0 had a maintainer
   comment; note the repository has only 6 open issues in total, so that sample
   is dominated by already-closed items and the figure should not be read as
   neglect. Maintenance: **active** (pushed within a week). Ranked below
   `github-script` only because it adds a third-party pin for a task the
   preinstalled `gh` already does.

##### Excluded by gate
- **`JasonEtco/create-an-issue`** — excluded by the maintenance rubric.
  `GET https://api.github.com/repos/JasonEtco/create-an-issue` (2026-09-10):
  `pushed_at` 2024-02-15T00:16:05Z — over 18 months without a push; latest
  release `v2.9.2`, `published_at` 2024-02-15T00:15:33Z; open issues
  `total_count` 29 against a repository that has not been pushed since. Verdict
  **at-risk**, on the concrete signal of 29 open issues accumulating against a
  repository with zero maintenance activity for 18 months (a release gap alone
  would only have been a trigger to investigate). Not `dormant`: no unpatched
  advisory, broken build or maintainer notice was found.
- **Filing nothing (py's actual behavior)** — excluded on fit. It is what py does,
  and it is the gap the Cargo Book names. For a *template* whose forks may go
  quiet, silent failure is the specific risk this lane cannot carry.
Crate gates for this member: *license* — inapplicable for `gh` as a preinstalled
runner tool that this repository neither vendors nor distributes (recorded
anyway: `cli/cli` is MIT, compatible); *MSRV* — inapplicable, `gh` is a Go binary
outside the Rust dependency tree; *RustSec / `unsafe`* — inapplicable, not a
crate, no RustSec package page exists; *OS coverage* — **applicable and passed**,
GitHub CLI 2.98.0 is preinstalled on both `ubuntu-24.04` and `macos-15` (the
report job runs on `ubuntu-latest` regardless); *default features / async-runtime
coupling* — inapplicable, not a Rust crate; *binary size / compile time* —
inapplicable, nothing is compiled, and the analogous cost is a few seconds of one
runner job that only executes on failure.

##### Up-and-comers
None worth adopting. GitHub's own `gh issue` surface has been stable for years,
and the alternatives are all mature-or-stale rather than emerging.

##### Fit for this template
Strong, and better-fitting than any action for three template-specific reasons.
(1) **Zero new third-party pins.** `gh` is preinstalled; every action alternative
adds a SHA that R20's policy obliges the template — and every fork — to keep
current, for a job that runs only when something is already broken. (2)
**Least-privilege stays legible.** The job's `issues: write` grant is visible in
the workflow and applies to a shell step whose entire behavior is three `gh`
commands, rather than to an opaque JavaScript action. (3) **A fresh fork works
unconfigured**, because `gh label create --force` bootstraps the label. The one
honest caveat: shell-plus-`gh` is more brittle than a typed action if the logic
grows; `set -euo pipefail` plus keeping the logic to three commands is the
mitigation, and `actions/github-script` is the documented escape hatch if it ever
needs more.

##### Recommendation
A `report` job as written above: `needs: [canary]`,
`if: failure() && github.event_name == 'schedule'`, `permissions: {contents: read,
issues: write}`, `GH_TOKEN: ${{ github.token }}`, `gh label create --force` then
list-then-create-or-comment on a single `canary`-labelled issue. Answering the
MEDIUM question directly: **do both** — fail loudly (which is automatic, since
M3's workflow has no `continue-on-error`) **and** file one de-duplicated issue.
py's canary does only the first, and the Cargo Book explains why that is not
enough.

##### Ranked runner-up
`actions/github-script@v9` calling `github.rest.issues.listForRepo` then
`github.rest.issues.create` / `createComment`. Rank 2. Switch to it if the
reporting logic needs to grow beyond a handful of commands — for example
attaching the failing leg's `cargo update --verbose` diff to the issue body, or
labelling by which leg failed. Its cost is one more third-party-ish pin (it is
GitHub-owned but still an external action) and a maintainer-responsiveness
profile weaker than `cli/cli`'s, as the figures above show.

##### Tradeoffs
Gains: routes the failure to a durable, assignable artifact; de-duplicates so a
long-lived breakage produces one thread rather than a weekly stream; adds no pin;
works on a fresh fork with no setup. Costs: requires `issues: write` on one job,
which is a real (if narrow) permission escalation over py's all-read canary — kept
narrow by living in a separate job with its own `permissions:` block; shell logic
is less robust than typed code; and if the repository's issue tracker is disabled
(some template forks disable issues) the step fails — that failure is visible in
an already-red workflow, which is acceptable, and P03 may add
`continue-on-error: true` **on this reporting step only** (never on the canary
legs) if it prefers not to compound the noise.

##### Parameters
`assumes workflow-permission-hardening (R08)` — the per-job `permissions:` block
shape; `issues: write` is scoped to the report job alone and to no other job in
the repository.
`assumes third-party-action-pinning-policy (R20)` — satisfied trivially, since
this member introduces no action to pin.
No `CONFLICT:` lines. This member owns no parameter.

##### Migration implications
`.github/workflows/canary.yml` — the `report` job. One repository label, `canary`,
created idempotently by the job itself (no manual setup, no committed config).
`CONTRIBUTING.md` — one line saying that a `canary`-labelled issue means the
weekly lane went red and blocks nothing. No source-file change.

##### Validation strategy
Proposed, not executed:
1. Force a red canary on a scratch repository (add a step that exits 1), let the
   scheduled run fire, and confirm exactly one issue is created with the `canary`
   label — `gh issue list --label canary --state open --json number,title`.
2. Force a second consecutive red run and confirm **no second issue** is created
   and a comment is appended instead — `gh issue view <n> --comments`.
3. Run the workflow via `gh workflow run canary.yml` with an induced failure and
   confirm the `report` job is **skipped** (the `github.event_name == 'schedule'`
   guard).
4. Confirm the token scope is sufficient and no PAT is needed: the job uses
   `${{ github.token }}` with `issues: write`, so `gh issue create` should
   succeed with no repository secret configured.

##### Confidence & re-verify trigger
**Medium-high.** The mechanism is simple and first-party, and every command used
is stable `gh` surface. Confidence is not "high" because, unlike M1–M3, this
member has **no** reference implementation among the six surveyed Rust projects or
either source repository — it is reasoned from the Cargo Book's stated cost and
GitHub's auto-disable behavior rather than copied from working practice.
Re-verify when: `gh` changes `issue list --json` output or label semantics;
GitHub ships first-party scheduled-failure notification routing (which would make
this member redundant); the template's issue tracker policy changes; or P03
finds that the label bootstrap conflicts with a repository-settings-managed label
set.

##### Sources
- https://doc.rust-lang.org/cargo/guide/continuous-integration.html#verifying-latest-dependencies (2026-09-10) — "Depending on the CI service, notifications might not be routed to people who can act on the failure"
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows (2026-09-10) — the 60-day auto-disable that makes an issue-shaped artifact valuable
- https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md and `/images/macos/macos-15-Readme.md` (2026-09-10) — GitHub CLI 2.98.0 preinstalled on both required images
- `GET https://api.github.com/repos/cli/cli`, `/releases`; `GET https://api.github.com/search/issues?q=repo:cli/cli+is:issue+is:open` (2026-09-10)
- `GET https://api.github.com/repos/actions/github-script`, `/releases`, `/issues?state=all&sort=created&direction=desc`; `GET https://api.github.com/search/issues?q=repo:actions/github-script+is:issue+is:open` (2026-09-10)
- `GET https://api.github.com/repos/peter-evans/create-issue-from-file`, `/releases`; open-issue search (2026-09-10)
- `GET https://api.github.com/repos/JasonEtco/create-an-issue`, `/releases`; open-issue search (2026-09-10)
- py@b08bccfb `.github/workflows/canary.yml` — the whole 52-line file, which contains no reporting step

### Compatibility

The four members are not independently-chosen libraries that need a
version-matrix proof; three of them (M1, M3, M4) are surfaces of two systems that
ship as units — the Rust toolchain and GitHub Actions — and the fourth (M2) is a
thin `rustup` wrapper. The compatibility evidence is therefore of three kinds.

**1. A single shared platform, verified from the platform's own manifests.** Both
runner images in the fixed `target-os-matrix` carry every non-action member at a
known version simultaneously: `images/ubuntu/Ubuntu2404-Readme.md` and
`images/macos/macos-15-Readme.md` (`actions/runner-images` at `main`, 2026-09-10)
each list **Cargo 1.98.0, Rust 1.98.0, Rustup 1.29.0** and **GitHub CLI 2.98.0**.
M1 (`cargo update`), M2's underlying `rustup`, and M4 (`gh`) are therefore proven
co-installed and co-versioned on both required OSes by the platform vendor's own
inventory, on the same date, with no version reconciliation left to this template.

**2. Shared adopters for each pair that has one.** No single public repository
runs all four members together — I searched the six surveyed projects and found
none, and I record that as an evidence gap rather than assert a false shared
adopter. The pairs that *are* jointly evidenced:

| Pairing | Shared adopter / evidence | Retrieved |
|---|---|---|
| M2 + M3 (`dtolnay/rust-toolchain` inside a cron-triggered, `fail-fast: false`, `timeout-minutes`-bounded, `permissions`-scoped matrix with a `beta` leg) | `dtolnay/anyhow` `.github/workflows/ci.yml:5,7,9-10,25,27,30,31` — every one of M3's guardrails plus M2's action and a `beta` leg, in one file | 2026-09-10 |
| M2 + M3, second independent adopter | `BurntSushi/ripgrep` `.github/workflows/ci.yml:7-8,10-28,51,53-66,128` — cron, least-privilege `permissions`, `fail-fast: false`, explicit `include:` matrix with a `beta` leg, `dtolnay/rust-toolchain` | 2026-09-10 |
| M1 + M3 (`cargo update` inside a non-gating CI lane with the resolver override) | The Cargo Book's own `latest_deps` job — `continue-on-error`, `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow`, `cargo update --verbose`, `cargo build`, `cargo test` | 2026-09-10 |
| M1 + M2 (`cargo update` under a `dtolnay/rust-toolchain`-installed channel) | `clap-rs/clap` `.github/workflows/ci.yml:201-206` — `dtolnay/rust-toolchain` then `cargo update --workspace --locked` in a dedicated job | 2026-09-10 |
| M3 + M4 analogue (a non-gating lane whose non-gating status is enforced and documented in-file) | py@b08bccfb `.github/workflows/canary.yml:1-11,16-23,36-40` — the standalone schedule-only workflow with `permissions: {}`, `concurrency`, `workflow_dispatch`, `fail-fast: false` | pin |

**3. Version-matrix reasoning where no adopter exists.** M4 is the member with no
shared adopter. Its compatibility claim is narrower and checkable: it depends only
on `gh issue list --json`, `gh issue create --label`, `gh issue comment` and
`gh label create --force`, all long-stable surface in `cli/cli` (latest release
`v2.100.0`, 2026-09-03; preinstalled 2.98.0), and on `${{ github.token }}` plus a
job-scoped `issues: write` grant. It shares no state with M1 or M2 — it runs in a
separate job, on a separate runner, after `needs: [canary]`, and touches no Rust
toolchain. The only coupling is the workflow-level `permissions: {}` default that
M3 establishes and M4 overrides per-job, which is the documented GitHub
mechanism.

**Interaction risks actively checked, not assumed away.** (a) M1 rewrites
`Cargo.lock`; nothing downstream in the workflow reads a *committed* lockfile
afterwards, and no cache is keyed on it because M2's `Excluded by gate` removes
`Swatinem/rust-cache` from this workflow — this is the one real cross-member
hazard and it is closed by design. (b) M2's `beta` leg passes `--locked`, so M1's
rewrite never happens on that leg and the two members' effects never overlap
within one job. (c) M3's `permissions: {}` would break M4 if M4 did not declare
its own job-level block — it does.

### Parameters

This item's `owns:` field in `## Couplings` is empty, and its `consumes:` field is
empty. Therefore:

- **owns:** none. This item introduces no new entry to `docs/port/PARAMETERS.md`.
- `assumes rust-edition = 2024` (fixed, owner, `docs/port/PARAMETERS.md`) — load-bearing: edition 2024 selects resolver `"3"`, which defaults `resolver.incompatible-rust-versions` to `fallback`, which is why the `latest-deps` legs must set `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow`.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed, owner) — load-bearing in two directions: the declared `rust-version` is what the resolver falls back to (hence the override), and the policy's "tested in CI" clause is satisfied by a *separate gating* MSRV job, not by this lane. This lane deliberately resolves past the floor and that is not a policy departure.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed, owner) — the `latest-deps` legs run on both. The `beta` leg runs on `ubuntu-latest` only as a cost choice; it works unchanged on `macos-latest`, so no recommendation here fails to work on any OS in the matrix.
- `assumes license = MIT OR Apache-2.0` (fixed, owner) — no member adds a crate to the dependency tree, so nothing in this stack constrains the distribution licence. Recorded for completeness: `cargo-edit` (the unadopted runner-up) declares `Apache-2.0 OR MIT` in its manifest, which is compatible.
- `assumes ci-job-structure` (researched, R11) — this workflow is a **separate file** from the gating workflow and its jobs must not enter the aggregate required status check owned by R12. If R11 selects bare `rustup` over `dtolnay/rust-toolchain` for the gating workflow, M2 should follow R11.
- `assumes package-manager-invocation` (researched, R42) — R42's rule is that a tool named `cargo-<sub>` is invoked as `cargo <sub>`. Consistent with this stack, which invokes only Cargo built-ins (`cargo update`, `cargo test`, `cargo report`) plus the bare executable `gh` on PATH. Should the `cargo-edit` runner-up ever be adopted, R42 requires it be invoked as `cargo upgrade`.
- `assumes web-extra-surface` (researched, R69) — if the web surface is a Cargo feature, `--all-features` is required for the canary to cover it. `--all-features` is correct under either outcome, so this is not a dependency that can break.

**No `CONFLICT:` lines.** Every consumed parameter's current value is compatible
with the recommendation as written; none needs to change.

Cadence coupling to record for P03 (not a parameter, not a conflict): py offsets
its canary from its dependency-audit workflow on purpose (py@b08bccfb
`.github/workflows/canary.yml:16` — "offset from dep-audit's Monday"). R13 owns
the vulnerability-scan schedule; keep the two on different days.

### Migration implications

File-level changes in the template, all additive:

| File | Change |
|---|---|
| `.github/workflows/canary.yml` | **New.** ~60 lines. `on: {schedule: [{cron: '17 6 * * 2'}], workflow_dispatch: {}}`; `permissions: {}`; `concurrency: {group: canary, cancel-in-progress: true}`. Job `canary`: `runs-on: ${{ matrix.os }}`, `timeout-minutes: 30`, `permissions: {contents: read}`, `strategy: {fail-fast: false, matrix: {include: [ {lane: latest-deps, os: ubuntu-latest, toolchain: stable, refresh: update}, {lane: latest-deps, os: macos-latest, toolchain: stable, refresh: update}, {lane: next-toolchain, os: ubuntu-latest, toolchain: beta, refresh: locked} ]}}`; steps `actions/checkout` (SHA-pinned, `persist-credentials: false`) → `dtolnay/rust-toolchain` (SHA-pinned `master`, `toolchain: ${{ matrix.toolchain }}`) → conditional `cargo update --verbose` under `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow` → `cargo test --workspace --all-features --all-targets` (`--locked` on the toolchain leg) → `cargo test --workspace --all-features --doc` → `if: always()` `cargo report future-incompatibilities`. Job `report`: `needs: [canary]`, `if: failure() && github.event_name == 'schedule'`, `permissions: {contents: read, issues: write}`, the `gh` label-and-issue step. **No `continue-on-error` on any canary leg.** |
| `CONTRIBUTING.md` (or the template's maintenance doc) | **New section, ~8 lines.** What the canary is; that a red canary blocks nothing (mirroring py@b08bccfb `.github/workflows/canary.yml:1-11`); that a fork with 60 days of no activity has the workflow auto-disabled and must re-enable it in the Actions tab; how to re-run it by hand (`gh workflow run canary.yml`); what a `canary`-labelled issue means. |
| `README.md` | Optional one-line mention in a CI/badges section, if the template lists its workflows. **Do not** add a canary status badge to a prominent position — a badge that is red for reasons that block nothing trains readers to ignore badges. |
| Branch protection / required status checks | **Explicit non-change.** No job from this workflow is added to the required check set owned by R12. Recorded here so the omission is deliberate and auditable rather than forgotten. |
| `Cargo.toml`, `Cargo.lock`, `Justfile`, `lefthook.yml`, `src/**` | **Unchanged.** This item adds no dependency, no dev-tool, no hook and no recipe. If a local convenience recipe is ever wanted, `just canary` running the two `latest-deps` commands would mirror ts's `just test-bun` (ts@cb1cbcb2 `Justfile:160-169`) — recorded as available, not recommended, since the lane's value is the cadence, which a local recipe cannot supply. |
| Repository labels | One label, `canary`, created idempotently by the report job (`gh label create --force`). No committed label configuration. |

Sequencing note for P03: `schedule` fires only on the default branch (GitHub
Actions events reference, 2026-09-10), so the workflow cannot be observed running
on schedule until it is merged to `main`. Verify pre-merge with `actionlint` and a
`workflow_dispatch` run from the branch; verify the schedule path post-merge.

### Validation strategy

Every check below is **proposed, not executed**. No Rust template exists yet
(P03 builds it), so nothing in this section was run against
`rs-launch-blueprint`. What *was* actually executed for this report is stated at
the end of `### Sources` under `Method notes` — it is endpoint retrieval and
source-repository reading, nothing more.

**Tier 1 — proves the freshness mechanism is real, not a green no-op** (run in the
generated template, locally or on the canary leg):
```bash
cargo fetch --locked                                   # baseline: lockfile is current
CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow \
  cargo update --verbose
git diff --exit-code Cargo.lock                        # EXPECT exit 1 (lockfile moved)
cargo test --workspace --all-features --all-targets    # EXPECT pass on a healthy graph
cargo test --workspace --all-features --doc            # EXPECT pass
```
Expected behavior and why it is the right check: step 3 is the acceptance
criterion for the whole `latest-deps` lane. If `Cargo.lock` does not move on a
template whose `Cargo.toml` uses caret bounds, the lane is testing the same graph
the gate already tests and is worthless. Exit 1 from `git diff --exit-code` is
success here.

**Tier 2 — proves the resolver override is load-bearing** (the check that catches
the single most likely silent misconfiguration):
```bash
cargo update --dry-run > /tmp/with-msrv-fallback.txt
CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow \
  cargo update --dry-run > /tmp/with-allow.txt
diff /tmp/with-msrv-fallback.txt /tmp/with-allow.txt   # EXPECT a non-empty diff
```
Expected behavior: a non-empty diff, in any workspace whose declared
`rust-version` floor is below the `rust-version` of some newer version of a
dependency. If the diff is empty, either the template has no such dependency yet
(record it and re-run when it does) or the override is not doing what the
resolver docs say — either way, the result must be inspected rather than assumed.
This is the executable form of the report's highest-value finding.

**Tier 3 — proves the toolchain lane is on beta and holds its graph constant:**
```bash
rustup toolchain install beta --profile minimal
rustc +beta --version                                  # EXPECT one minor above stable
cargo +beta test --workspace --all-features --all-targets --locked
git diff --exit-code Cargo.lock                        # EXPECT exit 0 (no change)
```
Expected behavior: as of 2026-09-10 the version line should read `1.99.0-beta.4`
against a stable of `1.98.1` (`[pkg.rustc] version` in `https://static.rust-lang.org/dist/channel-rust-beta.toml`
and `channel-rust-stable.toml`, 2026-09-10). Exit 0 from the final `git diff`
proves the toolchain leg isolated its variable.

**Tier 4 — proves the lane cannot gate** (run against the repository, post-merge):
```bash
actionlint .github/workflows/canary.yml                              # EXPECT clean
gh workflow run canary.yml --ref main && gh run watch                # EXPECT 3 canary legs
gh api repos/<owner>/<repo>/branches/main/protection/required_status_checks \
  --jq '.contexts'                                                   # EXPECT no canary job names
grep -c 'continue-on-error' .github/workflows/canary.yml             # EXPECT 0 (or 1, only if
                                                                     # placed on the report step)
```
Expected behavior: the `workflow_dispatch` run produces three `canary` jobs and
**no** `report` job (the `github.event_name == 'schedule'` guard), and the
required-status-check contexts contain none of this workflow's job names. The
`grep` is a cheap regression test against the composition error identified in M3.

**Tier 5 — proves failure routing works and does not spam** (run on a scratch
repository, since it requires an induced failure):
```bash
# with a deliberately failing step added to one leg, on a schedule trigger:
gh issue list --label canary --state open --json number,title   # EXPECT exactly 1
# after a second consecutive red scheduled run:
gh issue list --label canary --state open --json number         # EXPECT still exactly 1
gh issue view <n> --comments                                    # EXPECT a second comment
```
Expected behavior: one issue, then a comment rather than a second issue. This is
the acceptance criterion for M4's de-duplication, which is the property that keeps
a weekly lane from being muted.

**Item-specific empirical acceptance check (mandatory, per `## Required
evidence`).** The single check that decides whether this item's answer is right:
**a `cargo update` run under `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=allow`
must produce a `Cargo.lock` that differs from the committed one, and the suite
must then run to completion against that graph** (Tier 1, steps 2–5, plus Tier 2's
non-empty diff). If Tier 1 step 3 yields exit 0 on a template with caret-bounded
dependencies, or Tier 2's diff is empty on a template with an MSRV floor below a
dependency's, the recommended lane is not testing what this item claims and the
recommendation must be revisited before P03 ships it.

### Confidence & re-verify trigger

**Overall confidence: high on the decision, high on M1/M2/M3, medium-high on M4,
medium on two named calibrations.**

| Element | Confidence | Basis |
|---|---|---|
| **Decision: run both lanes** (a weekly dependency-freshness canary *and* a non-gating beta toolchain lane) | **High** | The dependency lane is published first-party guidance for exactly this situation (Cargo Book, "Verifying Latest Dependencies") and is py's recorded precedent. The toolchain lane is unanimous across six well-regarded projects and is solicited by the Rust project itself (Rust Book Appendix G) |
| **M1 `cargo update` + the resolver override** | **High** | Normative documentation, not inference: `cargo-update(1)`, the resolver chapter, and the config reference all read directly, and the Cargo Book's recipe sets the same variable for the same stated reason |
| **M2 `dtolnay/rust-toolchain`, `beta` only** | **High** on the action (unanimous, active); **medium-high** on beta-only/ubuntu-only, which is a cost judgment |
| **M3 guardrail set** | **High** on the guardrails (first-party documented behavior, two source-repo precedents); **medium** on weekly-versus-daily — four of six surveyed projects run daily, and weekly is chosen to match py and to keep an inherited template cost low, not because daily was shown wrong |
| **M4 `gh` issue reporting** | **Medium-high** | Simple, stable, first-party surface — but with **no** reference implementation in any surveyed project or either source repository. It is reasoned from the Cargo Book's stated cost and GitHub's auto-disable, not copied from working practice, and that gap is the reason it is not "high" |
| **Rejecting `cargo-edit` / `cargo upgrade --incompatible` for now** | **High** | Three independent reasons, one of which is decisive on its own: adopting it would make the Rust lane test something neither source tests |
| **Rejecting a `nightly` leg** | **Medium-high** | Argued from the six-week train's actionability plus two observed mitigations in rustls (`build.yml:449,463`) that exist because floating nightly is noisy. A template owner who values nightly-only features may reasonably differ |

**Re-verify triggers, each with the observable that fires it:**
1. **`cargo update --breaking` stabilizes** — watch https://github.com/rust-lang/cargo/issues/12425. Stabilization removes the only reason `cargo-edit` is on the shortlist and would let the bound-rewriting lane be a built-in.
2. **The Cargo Book's "Verifying Latest Dependencies" recipe changes** — it is the primary authority for M1; a change to its architecture list or to the `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS` note invalidates M1's core reasoning.
3. **The resolver default changes** — a future edition altering `resolver.incompatible-rust-versions`' default would make the override redundant or wrong.
4. **GitHub changes the 60-day scheduled-workflow auto-disable** — it is the single strongest argument for M4 and the single strongest argument *against* architecture C; a change moves both.
5. **`dtolnay/rust-toolchain` goes 6 months without a push, or is archived** — re-run the M2 shortlist; the bare-`rustup` runner-up becomes the recommendation.
6. **R11 selects bare `rustup` for the gating workflow** — M2 follows R11 rather than introducing the repository's only `dtolnay/rust-toolchain` pin for a non-gating lane.
7. **R13 fixes its dependency-audit schedule** — adjust this cron to a different day, preserving py's offset rationale.
8. **The template adds platform-specific code, `unsafe`, a build script, or a `windows-latest` runner** — widen the `beta` leg to the full OS matrix.
9. **Triage of a red canary starts needing more than one bisect step** — that is the concrete signal that weekly latency is producing multi-cause failures; move to daily, following ripgrep/anyhow/serde/rustls.
10. **A `canary`-labelled issue goes unactioned for two consecutive weeks** — the lane is being ignored; that is a signal to reduce its scope (drop a leg) rather than to keep filing.

### Sources

**Pinned source repositories** (read through the pin, never the working tree):
- py@`b08bccfb55d05f15e46a83b52c5660b1881d19f5` `.github/workflows/canary.yml` — the complete 52-line file. `:1-11` header comment stating the principle and the never-gates guarantee; `:14-17` `on: schedule: - cron: '0 6 * * 2'` + `workflow_dispatch:`; `:19` `permissions: {}`; `:21-23` `concurrency: {group: canary, cancel-in-progress: true}`; `:26-30` job, `runs-on: ${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`, `permissions: contents: read`; `:36-40` `fail-fast: false`, `matrix: python-version: ["3.12","3.13"]`; `:44-45` "do NOT add `--locked` here"; `:47` `uv sync --upgrade --group dev --extra web`; `:49-52` `uv run --no-sync pytest -m "" -n auto`. **No `timeout-minutes` and no failure-reporting step** — both gaps this port closes.
- py@`b08bccfb` `.github/workflows/` directory listing (19 workflow files) — confirms `canary.yml` is a standalone file, separate from `ci.yml` and `dep-audit.yml`.
- ts@`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` `Justfile:160-169` — the `test-bun` recipe, `bun run vitest run --exclude tests/e2e.test.ts`, with its own "advisory-only, D-036" message.
- ts@`cb1cbcb2` `.github/workflows/ci.yml:130-188` — the `bun-lane` job: `:141` job id, `:142` `name: bun-lane (advisory, non-gating)`, `:144` `continue-on-error: true`, `:145-147` `permissions: contents: read`, `:151-154` `actions/checkout@v7` with `persist-credentials: false`, `:175` `oven-sh/setup-bun@0c5077e51419868618aeaa5fe8019c62421857d6 # v2.2.0`, `:177` `bun-version: 1.3.14`, `:188` the test command. **This is the file the F127 BASELINE-REVIEW above concerns.**
- ts@`cb1cbcb2` `docs/port/TS_PORT_DECISIONS.md:413-417` — D-036 in full, including "Bun tracks Node v23 parity — one major behind the floor, hence advisory-not-gating".
- ts@`cb1cbcb2` `.github/workflows/` directory listing (8 files) — confirms no `canary.yml` or scheduled workflow exists, as the ledger states.
- Both commits were read for this item; where a claim comes from only one, the pin is named inline. I found **no** disagreement between the two pins relevant to this item (the action-pinning discrepancy noted in the role file concerns py's pinning style, which this item does not decide — R20 does).

**Repository ledger and analysis** (read from the working tree, as programme documents rather than source evidence): `docs/port/COMMONALITY.md:132-133` (F126, F127); `docs/port/DIVERGENCE-ANALYSIS.md:144-146` (R34 item row and both sub-rows); `docs/port/PARAMETERS.md` (the four fixed parameters and the researched-parameter registry).

**First-party Rust and Cargo documentation** (all 2026-09-10):
- https://doc.rust-lang.org/cargo/guide/continuous-integration.html — the whole page: the stable/beta/nightly matrix starter, the "Verifying Latest Dependencies" section (four architectures, their costs, the `latest_deps` recipe with `continue-on-error: true` and `CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS: allow`), the "Verifying rust-version" section (`taiki-e/install-action` + `cargo hack check --rust-version`), and the "Checking for warnings" section (`build.warnings = "deny"`); the GitLab example's `allow_failure: true` with the note "any breakage in nightly will not fail your overall build"
- https://doc.rust-lang.org/cargo/commands/cargo-update.html
- https://doc.rust-lang.org/cargo/reference/resolver.html
- https://doc.rust-lang.org/cargo/reference/config.html
- https://doc.rust-lang.org/cargo/reference/future-incompat-report.html
- https://doc.rust-lang.org/cargo/faq.html
- https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html
- https://doc.rust-lang.org/book/appendix-07-nightly-rust.html
- https://static.rust-lang.org/dist/channel-rust-stable.toml and https://static.rust-lang.org/dist/channel-rust-beta.toml

**Platform documentation** (2026-09-10):
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
- https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md
- https://raw.githubusercontent.com/actions/runner-images/main/images/macos/macos-15-Readme.md (and `macos-14-Readme.md`, which lists GitHub CLI 2.95.0)

**Figure endpoints** (all queried 2026-09-10; every number in this report traces to one of these):
- `GET https://crates.io/api/v1/crates/{cargo,cargo-edit,cargo-minimal-versions,cargo-hack}` — `crate.recent_downloads`, `crate.downloads`, `crate.max_stable_version`
- `GET https://crates.io/api/v1/crates/{cargo,cargo-edit,cargo-minimal-versions}/versions` — newest `yanked: false` entry's `num`, `created_at`, `license`, `rust_version`, `crate_size`
- `GET https://api.github.com/repos/{rust-lang/cargo,killercup/cargo-edit,dtolnay/rust-toolchain,actions/github-script,JasonEtco/create-an-issue,peter-evans/create-issue-from-file,Swatinem/rust-cache,actions-rs/toolchain,taiki-e/cargo-minimal-versions,taiki-e/install-action,cli/cli,actions/checkout}` — `stargazers_count`, `archived`, `pushed_at`, `license.spdx_id`
- `GET https://api.github.com/repos/<o>/<r>/releases` — latest `tag_name`, `published_at`
- `GET https://api.github.com/repos/dtolnay/rust-toolchain/{commits/master,tags,issues?state=all&sort=created&direction=desc}`
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` — `total_count` (never `open_issues_count`)
- `https://rustsec.org/packages/cargo.html` (CVE-2019-16760, fixed in Rust 1.26.0 — historical, no current open advisory) and `https://rustsec.org/packages/cargo-edit.html` (**HTTP 404** — no advisory page exists, i.e. no recorded advisory)

**Practice evidence files** (all `https://raw.githubusercontent.com/<repo>/HEAD/<path>`, retrieved 2026-09-10; line numbers are those of the retrieved file):
`BurntSushi/ripgrep .github/workflows/ci.yml`; `dtolnay/anyhow .github/workflows/ci.yml`; `serde-rs/serde .github/workflows/ci.yml`; `rustls/rustls .github/workflows/build.yml`; `clap-rs/clap .github/workflows/ci.yml`; `tokio-rs/axum .github/workflows/CI.yml`; `dtolnay/rust-toolchain README.md` and `action.yml`; `killercup/cargo-edit Cargo.toml`.

**Figure reference table** (endpoint per row is one of the above; all 2026-09-10):

| Crate / repo | 90-day dl (`recent_downloads`) | All-time (`downloads`) | Last non-yanked release | Stars | Archived | `pushed_at` | Open issues (`search` `total_count`) | RustSec |
|---|---|---|---|---|---|---|---|---|
| `cargo` (rust-lang/cargo) | 721,453 | 7,752,515 | 0.99.0, 2026-08-20T17:10:57Z | 15,462 | false | 2026-09-08T15:46:17Z | 1,578 | CVE-2019-16760, fixed in Rust 1.26.0; none open |
| `cargo-edit` (killercup/cargo-edit) | 481,434 | 3,546,657 | 0.13.13, 2026-07-15T18:05:21Z | 3,451 | false | 2026-07-15T18:05:24Z | 68 | page 404 — none recorded |
| `cargo-minimal-versions` (taiki-e) | 17,382 | 112,918 | 0.1.37, 2026-03-20T08:39:14Z | 76 | false | 2026-09-04T13:23:45Z | 7 | not queried (not adopted) |
| `cargo-hack` (taiki-e) | 212,277 | 1,867,598 | not queried | not queried | — | — | — | mentioned only as the Cargo Book's MSRV-job tool |
| `dtolnay/rust-toolchain` | inapplicable — a GitHub Action, not published to crates.io | inapplicable | tag `v1` only (2022-07-15); `master` HEAD `d1031067263f94b142dd6c0ce24c5eb9d02d52a0`, 2026-09-03T15:22:19Z | 1,574 | false | 2026-09-03T15:22:58Z | 8 | inapplicable — not a crate |
| `actions/github-script` | inapplicable — a GitHub Action | inapplicable | v9.0.0, 2026-04-09T22:57:15Z | 5,018 | false | 2026-04-09T22:46:34Z | 58 | inapplicable |
| `peter-evans/create-issue-from-file` | inapplicable | inapplicable | v6.0.0, 2025-10-01T14:45:11Z | 177 | false | 2026-09-03T00:38:34Z | 6 | inapplicable |
| `JasonEtco/create-an-issue` | inapplicable | inapplicable | v2.9.2, 2024-02-15T00:15:33Z | 303 | false | 2024-02-15T00:16:05Z | 29 | inapplicable |
| `cli/cli` (`gh`) | inapplicable — a Go binary preinstalled on the runner | inapplicable | v2.100.0, 2026-09-03T15:43:20Z | 46,219 | false | 2026-09-10T14:05:34Z | 1,025 | inapplicable |
| `actions-rs/toolchain` | inapplicable | inapplicable | — | 606 | **true** | 2023-06-18T05:26:38Z | not queried (archived) | inapplicable |
| `Swatinem/rust-cache` | inapplicable | inapplicable | not queried | 1,911 | false | 2026-09-07T21:44:07Z | not queried (owned by R10) | inapplicable |
| `actions/checkout` | inapplicable | inapplicable | v7.0.1, 2026-07-20T15:10:05Z | 8,860 | false | 2026-09-10T03:02:44Z | not queried | inapplicable |

**Maintenance verdicts by the rubric** — `cargo` (rust-lang/cargo): **active**;
`cargo-edit`: **active**; `cargo-minimal-versions`: **active** (the ~6-month
release gap was a trigger to investigate, and the investigation found a
repository pushed within a week, so not `at-risk`); `dtolnay/rust-toolchain`:
**active**; `cli/cli`: **active**; `peter-evans/create-issue-from-file`:
**active**; `actions/github-script`: **stable-quiet** (5 months since last push
and 0 maintainer comments on the 6 most recent issues are triggers to
investigate, but no concrete `at-risk` signal — no unpatched advisory, no broken
build, no maintainer notice — so `stable-quiet`, with the caveat reported rather
than hidden); `JasonEtco/create-an-issue`: **at-risk** (18 months with no push
while 29 open issues accumulate — that accumulation is the concrete signal;
not `dormant`, since no unpatched advisory, broken build or maintainer notice was
found); `actions-rs/toolchain`: **archived**.

**Method notes.** I queried, on 2026-09-10: the crates.io API
(`https://crates.io/api/v1/crates/<name>` and `/versions`, with a `User-Agent`
header) for `cargo`, `cargo-edit`, `cargo-minimal-versions` and `cargo-hack`; the
GitHub REST API (`https://api.github.com/repos/<o>/<r>`, `/releases`, `/tags`,
`/commits/master`, `/issues?state=all&sort=created&direction=desc`,
`/issues/<n>/comments`, and `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`)
for the twelve repositories in the figure table; RustSec package pages for `cargo`
and `cargo-edit`; the Cargo Book, the Rust Book Appendix G, and the GitHub
Actions events reference over HTTPS; the Rust distribution channel manifests at
`static.rust-lang.org`; the `actions/runner-images` image manifests; and
`raw.githubusercontent.com` for the eight practice files. Source-repository
evidence was read exclusively through `git -C ~/c/py-launch-blueprint show
b08bccfb:<path>` and `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>`, never
from a working tree.

Unauthenticated GitHub REST was rate-limited part-way through
(`https://api.github.com/rate_limit` reported `core.remaining: 0` on 2026-09-10);
the remaining repository figures were retrieved through the authenticated `gh api`
REST client against the same endpoints, so the field names and values are the
endpoints specified in `## Required evidence`, not a substitute source.

**What I could not verify, stated rather than filled in:**
1. **No annual Rust survey figure for scheduled or beta CI lanes.** The survey is
   named in `## Required evidence` as an authority; I found no question in it
   addressing this item's subject and therefore cite no survey number. The
   practice evidence stands on the six surveyed repositories instead.
2. **No measured CI cost.** No wall-clock or runner-minute figure appears in this
   report because no Rust template exists to measure. The only cost anchors given
   are `dtolnay/anyhow`'s declared `timeout-minutes: 45` and the fact that public
   repositories are not billed for GitHub-hosted minutes. The proposed
   `timeout-minutes: 30` is a guardrail, not a measurement.
3. **No reference implementation for the full composition.** I found no public
   repository running `cargo update` freshness *and* a beta leg *and* issue-filing
   in one scheduled workflow. M1+M2, M1+M3, M2+M3 and M3's guardrail set each have
   named adopters (see `### Compatibility`); the four-member whole is this
   report's synthesis and is labelled as such.
4. **M4 has no adopter at all** among the surveyed projects or either source
   repository. Its confidence is set to medium-high for exactly this reason.
5. **`clap`'s `continue-on-error` guard is currently vestigial.** At the retrieved
   HEAD every leg of clap's matrix is `stable`, so `ci.yml:63` guards nothing
   today. It is cited as evidence of the *idiom*, not of a live beta lane, and
   that limitation is stated where it is cited.
6. **Nothing in `### Validation strategy` was executed.** Every command there is
   proposed for P03.
