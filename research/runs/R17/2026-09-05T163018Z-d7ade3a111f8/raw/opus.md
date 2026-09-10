# R17 — secret-scanning-ci-workflow (Opus raw report)

Item kind: `crate`. All figures retrieved 2026-09-10 unless a different date is given.

Terminology used throughout: **CI tier** = a job on a GitHub-hosted runner that a contributor
cannot skip locally; **hook tier** = a pre-commit / pre-push hook on the contributor's machine
(R39 owns it); **verified/validated finding** = a candidate secret the scanner sent to the issuing
provider's API and confirmed is still live, as opposed to a regex match.

### Landscape

**Category this item decides.** Server-side (CI-tier) detection of credentials that entered the
repository or a pull request, with a pass/fail signal a maintainer cannot bypass locally. This is a
*repository-security tooling* category, not a Rust-library category: no candidate is linked into
`rs-launch-blueprint`'s Cargo graph. That distinction drives most of the gate answers below.

**Three-bin map of the field as it applies to a Rust repository on GitHub.**

| Bin | Candidates found | Note |
|---|---|---|
| Built-in / first-party toolchain | **GitHub secret scanning + push protection** (first-party to the CI platform); **no Rust first-party tool exists** — `cargo` ships no secret scanner, and neither the Rust project, its RFC process, nor any working group publishes one | The Rust-side first-party bin is empty. Verified by absence: `cargo`'s own repository runs no secret-scan job (`GET https://api.github.com/repos/rust-lang/cargo/contents/.github/workflows` → `audit.yml, contrib.yml, main.yml, release.yml`, 2026-09-10) |
| Established industry standard | **TruffleHog OSS** (`trufflesecurity/trufflehog`, Go); **Gitleaks** (`gitleaks/gitleaks`, Go) and its Action wrapper `gitleaks/gitleaks-action`; **detect-secrets** (`Yelp/detect-secrets`, Python) | These three are the incumbents in every CI-tier secret-scan comparison |
| Up-and-comer | **Kingfisher** (`mongodb/kingfisher`, Rust, first release 2025); **Nosey Parker** (`praetorian-inc/noseyparker`, Rust) — now archived | Kingfisher is the only actively maintained Rust-native entrant |

Every shortlisted candidate below comes from this map. Excluded from consideration up front and
named so the omission is deliberate: commercial-key-gated scanners (**GitGuardian ggshield**,
**Semgrep Secrets**) require an account and an API token in CI, which contradicts a template that
must work on a fresh clone with no vendor onboarding.

**Authorities used, and why each is authoritative.**

1. **GitHub Docs** — the platform that hosts the CI tier and owns the competing built-in
   capability; it is the normative source for both what native secret scanning does and what a
   `macos-latest` runner can execute.
   `https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning`
   and `.../supported-secret-scanning-patterns` (retrieved 2026-09-10).
2. **OpenSSF Scorecard checks specification** — the most widely applied automated security-posture
   standard for open-source repositories, run by the OpenSSF; its check list defines what the
   industry treats as a required repository control.
   `https://github.com/ossf/scorecard/blob/main/docs/checks.md` (retrieved 2026-09-10).
3. **OpenSSF Open Source Project Security Baseline** — the OpenSSF's consensus control set for
   project security maturity. `https://baseline.openssf.org/versions/2025-02-25.html`
   (retrieved 2026-09-10).
4. **Maintainers' own documentation and source** — TruffleHog's `action.yml` at the exact tag py
   pins, TruffleHog's README, Kingfisher's `docs/USAGE.md`, `docs/INSTALLATION.md`,
   `docs/DEPLOYMENT.md`, `docs/COMPARISON.md`, and `gitleaks-action`'s README, all read through the
   GitHub contents API (retrieved 2026-09-10). Maintainer docs are authoritative for a tool's own
   semantics and self-declared licensing, and are explicitly *not* treated as authoritative for
   comparative performance claims (see the vendor-benchmark caveat in `### Principles and
   implementation`).
5. **The two source repositories at their programme pins** — `py-launch-blueprint`
   `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and `ts-launch-blueprint`
   `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, read via `git show <pin>:<path>`.

Deliberate non-authorities: no single blog post was used to establish any claim. Kingfisher's
`docs/COMPARISON.md` is a vendor-authored benchmark and is labelled as such everywhere it is cited.

**Practice evidence — what well-regarded Rust projects actually do.**

Ten Rust (or Rust-adjacent) projects were surveyed by listing `.github/workflows` through
`GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows` (retrieved 2026-09-10), then
five of them were code-searched for a scanner reference through
`GET https://api.github.com/search/code?q=repo:<o>/<r>+trufflehog+OR+gitleaks` (retrieved
2026-09-10).

| Project | Why it is a well-regarded reference | Workflow files | Dedicated secret-scan job? | Code-search hits for `trufflehog`/`gitleaks` |
|---|---|---|---|---|
| `tokio-rs/tokio` | the de-facto Rust async runtime; every web-service item in this programme depends on it transitively | `audit.yml, ci.yml, labeler.yml, loom.yml, pr-audit.yml, stress-test.yml, uring-kernel-version-test.yml` | no | 0 |
| `rust-lang/cargo` | the Rust project's own build tool, maintained by the Cargo team | `audit.yml, contrib.yml, main.yml, release.yml` | no | 0 |
| `BurntSushi/ripgrep` | the canonical well-engineered Rust CLI | `ci.yml, release.yml` | no | not searched |
| `rustls/rustls` | the memory-safe TLS stack, ISRG-funded and security-critical | `build.yml, cifuzz.yml, cross.yml, daily-tests.yml, docs.yml` | no | 0 |
| `clap-rs/clap` | the dominant Rust CLI argument parser; the most security- and hygiene-ceremonious workflow set in the sample | `audit.yml, bench-baseline.yml, ci.yml, committed.yml, post-release.yml, pre-commit.yml, release-notes.py, rust-next.yml, spelling.yml, template.yml` | no | 0 |
| `tokio-rs/axum` | the reference Rust web framework for the template's web surface | `CI.yml, release-plz.yml` | no | not searched |
| `astral-sh/ruff` | newer and very widely adopted; an unusually thorough release/CI estate | 21 workflow files, none secret-scan | no | not searched |
| `astral-sh/uv` | newest of the sample and the most CI-elaborate (it even runs `check-zizmor.yml` for workflow static analysis) | 25+ workflow files, none secret-scan | no | 0 |
| `rust-lang/rust-analyzer` | the Rust project's official language server | `autopublish.yaml, ci.yaml, coverage.yaml, fuzz.yml, gen-lints.yml, metrics.yaml, publish-libs.yaml, release.yaml, rustc-pull.yml, rustdoc.yaml` | no | not searched |
| `denoland/deno` | large, security-focused, Rust-implemented runtime | generated workflow set, none secret-scan | no | not searched |

**Finding: 0 of 10 surveyed well-regarded Rust projects run a repository-level secret-scanning CI
job.** They are all public repositories, so GitHub's free native secret scanning already covers
them, and neither OpenSSF Scorecard (20 checks, none about leaked credentials) nor the OpenSSF
Security Baseline requires a repository-level scanner. This is the strongest single piece of
evidence in the item, and it cuts against a dedicated workflow. `### Principles and implementation`
explains why the recommendation nevertheless keeps one: the template is cloned into *private*
repositories, where GitHub's free coverage stops.

Counter-evidence in favour of a dedicated job, kept honest: adoption counts for the TruffleHog and
Gitleaks Actions could not be measured. GitHub's code-search API refuses an unscoped query
(`GET https://api.github.com/search/code?q="trufflesecurity/trufflehog"+path:.github/workflows`
returned an empty body, 2026-09-10), so no global usage figure is reported rather than an invented
one. Within `mongodb`, `GET https://api.github.com/search/code?q=org:mongodb+kingfisher+path:.github/workflows`
returned `total_count` 4 (2026-09-10) — the vendor dogfoods its own scanner in CI.

### Principles and implementation

**The shared requirement.** *A credential that is live at merge time must not reach the default
branch without a server-side check failing first.* Source: ledger row F050 in
`docs/port/COMMONALITY.md:56` ("Dedicated secret-scanning CI workflow", area `ci-workflows`,
origin `py-only`, verdict `DIVERGENT`, item R17), realized in py by
`.github/workflows/secret-scan.yml` at pin `b08bccfb` (read 2026-09-10 via
`git show b08bccfb:.github/workflows/secret-scan.yml`).

**Agreement level: capability + policy, not tool and not configuration.** The three repositories
must agree that a CI-tier, non-bypassable check exists and that it fails on a *validated* (live)
credential. They need not agree on which scanner produces that verdict, because the scanner is a
build-time executable, not part of any repository's public API or dependency graph. Concretely:

| Must agree (capability/policy) | May vary (ecosystem-local) |
|---|---|
| A CI-tier job exists that fails on a live credential | Which scanner binary produces the verdict |
| The verdict is server-side and cannot be skipped by a contributor | How the binary is installed (Action, container, release tarball) |
| The job runs on `pull_request` and on `push` to `main` | Whether the scan is diff-scoped or full-history |
| The failure signal is a check the branch-protection rules can require | Which runner OS the single scan job lands on (R11 owns this) |

**Essential behaviors.** (1) Scan content that a pull request would add; (2) attempt live
validation against the issuing provider and distinguish *validated* from *candidate*; (3) exit
non-zero when a validated credential is present; (4) surface the finding location without printing
the secret; (5) require no vendor account or paid licence key.

**Observable acceptance criteria.** Committing a deliberately live-looking, non-live test
credential produces a **passing** job (no validated finding, so no false-positive gate); committing
a genuinely live throwaway credential produces a **failing** job naming the file and line. Both are
executable and both are stated as *proposed*, not executed, in `### Validation strategy`.

**Is the shared architectural pattern still appropriate in the target ecosystem?** Partly. The
pattern py chose — *dedicated workflow file, one scanner job, verified-only* — remains sound, but
its *justification* changes in Rust. In py's ecosystem the same reasoning applied; in the Rust
sample above, mainstream projects rely on GitHub's platform-native scanning instead. Two facts
decide the question for a **template**, and they are the reason I keep the workflow rather than
deleting it:

1. **Native scanning's free tier stops at public repositories.** "Secret scanning runs
   automatically for free" in public repositories; private and internal repositories require GitHub
   Secret Protection with GitHub Team or Enterprise Cloud
   (`https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning`,
   retrieved 2026-09-10). A template's whole purpose is to be cloned, and a large fraction of
   clones are private. The surveyed Rust projects are all public, so their choice does not transfer.
2. **Native scanning does not emit a pull-request check.** The GitHub documentation describes
   alerts and optional validity checks but no PR status check that branch protection can require
   (same page, retrieved 2026-09-10). R12 (`aggregate-required-status-check`) needs a check to fold
   in; an alert is not one.

Native scanning is therefore **complementary, not a substitute**: it should be enabled as an
always-on layer (it covers crates.io API tokens with push protection —
`https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns`,
retrieved 2026-09-10, entry "crates.io | Crates.io API Token | `cratesio_api_token` | ✓" — which is
directly relevant to a Rust template that will hold a publish token), and the dedicated workflow
remains the enforceable gate.

**Architectural alternatives compared before any tool was chosen.** Four shapes exist; the tool
choice only matters after this is settled.

| # | Architecture | What it gives | What it costs | Verdict |
|---|---|---|---|---|
| A | No dedicated workflow; rely on GitHub native scanning + the R39 hook tier | zero workflow code; matches 10/10 surveyed Rust projects | no coverage in private clones; no required check for R12; hook tier is bypassable with `--no-verify` | **rejected** — fails the requirement in private clones, which is the template's main deployment |
| B | Third-party vendor **Action** (`uses:`) that wraps a scanner | one `uses:` line; the vendor maintains the glue | inherits the Action's runtime constraints and licence; a supply-chain edge the template does not control | **viable, and is py's shape** |
| C | **Install a pinned scanner binary in a `run:` step** and invoke the CLI | full control of flags, exit codes, version pin, and provenance verification; no third-party Action in the trust path | ~6 extra workflow lines for the install step | **recommended** |
| D | Reuse the R39 hook-tier scanner binary at CI tier as well | one tool to learn and update | no detector diversity; and F050's row note currently asserts the two tiers use distinct tools | **possible; see the `BASELINE-REVIEW:` below** |

Shape C wins over B on evidence, not preference: the two leading Actions each fail a gate that the
underlying CLI passes (TruffleHog's Action is Docker-bound; Gitleaks' Action is proprietary and
licence-keyed — both documented in `### Excluded by gate`), so B's "one line" saving is not
actually available with either incumbent.

**Maturity, dependability, performance and integration cost of the tools, compared.**

*Maturity.* TruffleHog is the mature incumbent (27,746 stars, first commit 2016-12-31,
`GET https://api.github.com/repos/trufflesecurity/trufflehog`, 2026-09-10). Kingfisher is 16 months
old (created 2025-05-08T17:27:15Z, same endpoint, 2026-09-10) with 1,226 stars. On raw maturity
TruffleHog wins and this is the single strongest argument against my recommendation.

*Dependability, measured rather than asserted.* Issue responsiveness was computed by taking the 10
most recently created issues per repository
(`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+sort:created-desc&per_page=10`)
and finding the first comment whose `author_association` is `OWNER`, `MEMBER` or `COLLABORATOR`
(`GET https://api.github.com/repos/<o>/<r>/issues/<n>/comments`), all retrieved 2026-09-10:

| Repository | Issues with a maintainer reply | Median days to first maintainer reply | Unanswered |
|---|---|---|---|
| `trufflesecurity/trufflehog` | 0 of 10 | inapplicable — no data points | 10 |
| `gitleaks/gitleaks` | 0 of 10 | inapplicable — no data points | 10 |
| `mongodb/kingfisher` | 9 of 10 | 2.48 days | 1 |

Caveat stated because it could change the reading: the classification counts only `OWNER`/`MEMBER`/
`COLLABORATOR`; a maintainer replying from an account that is not a public organization member
would be scored as unanswered. Spot-checking `trufflesecurity/trufflehog` issue 5184 and
`gitleaks/gitleaks` issue 2198 showed the only repliers were `NONE`/`CONTRIBUTOR` community
accounts, which supports the reading but does not prove it across all ten.

*Representative performance — with the caveat stated first.* The only head-to-head figures
available are **vendor-authored by MongoDB**
(`https://github.com/mongodb/kingfisher/blob/main/docs/COMPARISON.md`, retrieved 2026-09-10) and
must be read as a vendor claim, not an independent measurement. Their stated instrumentation:
darwin/arm64, 16 CPU cores, 48.00 GB RAM, September 2026, wall-clock runtime per repository,
network requests counted per scan, executable sizes measured from the installed macOS arm64
binaries. Selected rows: on the `gitlab` repository, Kingfisher 135.41 s / 17 network requests,
TruffleHog 325.93 s / **15,624** network requests, Gitleaks 350.84 s / 0; both Kingfisher and
TruffleHog reported the same **6** validated/verified findings there, and Gitleaks 0 (Gitleaks does
not validate). Binary sizes: Gitleaks 8.30.1 = 14.6 MiB, Kingfisher 2.1.0 = 25.3 MiB, TruffleHog
3.97.2 = **162.7 MiB**. No absolute "fastest" conclusion is drawn from these unlike numbers; the
figure that matters for this item is the **network-request count**, because every validation
request transmits a candidate secret to a third party, and 15,624 versus 17 is a two-orders-of-
magnitude difference in exfiltration surface for the same 6 confirmed findings. That is a security
argument, not a speed argument, and it survives the vendor caveat because the two tools agree on
the finding count.

*Integration cost.* TruffleHog via its Action: 1 `uses:` line plus the `base`/`head` conditional py
needs (7 lines). Kingfisher via shape C: a 4-line download-and-verify step plus a 3-line scan step.
Difference is roughly a wash.

**Maintained reference implementations cited.** For the recommended design: `mongodb/kingfisher`'s
own repository runs Kingfisher-shaped CI on `ubuntu-24.04`, `ubuntu-24.04-arm` and `macos-14`
(`GET https://api.github.com/repos/mongodb/kingfisher/contents/.github/workflows/ci.yml`,
2026-09-10), and 4 workflow files inside the `mongodb` organization reference Kingfisher
(org-scoped code search, 2026-09-10). For the runner-up: py's own
`.github/workflows/secret-scan.yml` at pin `b08bccfb` is the maintained reference implementation
for the TruffleHog shape. **Evidence gap, stated rather than papered over:** I found no
*third-party*, well-regarded Rust project running Kingfisher in CI. Its adoption evidence is
vendor-internal plus star count. That gap is the reason the recommendation carries a
re-verify trigger and a named fallback.

**A supply-chain trap discovered while gathering crate figures, recorded because P03 could fall
into it.** `GET https://crates.io/api/v1/crates/kingfisher` (2026-09-10) returns a real crate —
`kingfisher` 0.1.2, published 2023-09-27T22:01:04Z, `repository` = `https://github.com/mongrov/kingfisher`
— which is **an unrelated project, not MongoDB's scanner**. MongoDB's workspace sets
`publish = false` (`GET https://api.github.com/repos/mongodb/kingfisher/contents/Cargo.toml`,
2026-09-10), so no Kingfisher crate exists on crates.io at all. **P03 must never run
`cargo install kingfisher`.** Install only from `https://github.com/mongodb/kingfisher/releases`,
Homebrew, or `ghcr.io/mongodb/kingfisher`.

**Baseline challenge.**

BASELINE-REVIEW: F050 — the invariant is a distinct CI *tier* (server-side and non-bypassable), not a distinct *tool* — F050's row note in `docs/port/COMMONALITY.md:56` reads "distinct tool and tier from git-hooks-commit-hygiene's gitleaks pre-commit/pre-push hooks"; it should be relaxed to "distinct tier required; distinct tool optional, justified only by detector diversity" — evidence: py's own workflow comments tie the two-tool split to TruffleHog's scan scope, not to a diversity principle (`.github/workflows/secret-scan.yml:1-2` "Pairs with gitleaks at lefthook (ITM-001/002) for two-layer coverage per ADR-02" and line 38 "ITM-031 round-3: verified-only (gitleaks covers unverified patterns)", read via `git show b08bccfb:.github/workflows/secret-scan.yml` on 2026-09-10). The second tool exists in py to recover the unverified-pattern coverage that `--only-verified` discards — a consequence of TruffleHog's mode, not an independent requirement. Affected items: R17 (this item) and R39 (`secret-scanning-hooks`, owns F163–F166). I am not changing the ledger or R39's answer; R39 remains free to pick a different tool, and a same-tool outcome should be a decision with a stated diversity trade-off rather than a rule violation.

No `CONFLICT:` line is needed: the recommendation requires no change to any consumed parameter.

### Dominant choice

**None — and that is the finding.** Two different "dominant" answers exist depending on which
question is asked, and neither dominates this item outright.

- **Dominant practice** among well-regarded Rust projects is *no dedicated secret-scan workflow at
  all*, relying on GitHub's platform-native scanning: 0 of 10 surveyed projects run one
  (`GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows` across the ten projects in
  `### Landscape`, plus 0 code-search hits in five of them, 2026-09-10). Neither OpenSSF Scorecard
  (20 checks, none about leaked credentials,
  `https://github.com/ossf/scorecard/blob/main/docs/checks.md`, retrieved 2026-09-10) nor the
  OpenSSF Security Baseline (`https://baseline.openssf.org/versions/2025-02-25.html`, retrieved
  2026-09-10) requires one.
- **Dominant tool** among projects that do run one is **TruffleHog OSS** — 27,746 stars, an
  official GitHub Action, releases 2–3 times a week (v3.97.4 published 2026-09-03T20:01:40Z,
  `GET https://api.github.com/repos/trufflesecurity/trufflehog/releases`, 2026-09-10). But its
  official Action fails fitness gate 4 on this template's runner matrix (see `### Excluded by
  gate`), so "dominant" and "fit" diverge here.

Because the two dominance readings point in different directions and the incumbent's packaging
fails a gate, this item is decided on fit rather than on popularity — which is what the survey
method demands.

### Qualified shortlist

Only **two** candidates pass every applicable gate. Fewer than five is a finding: the category is
thin once a licence-clean, non-Docker, actively maintained, validating scanner is required.

**Crate-figure applicability, stated once for the whole shortlist.** Every candidate is a
standalone executable invoked by a CI job — a Go binary, a Python package, or a Rust binary
distributed as a release tarball. **None is published on crates.io**, so `crate.recent_downloads`,
`crate.downloads`, the `/versions` last-release field and the RustSec advisory page are
`inapplicable` for every row, with the per-candidate evidence recorded in `### Sources`. GitHub
release cadence and repository figures are substituted, and are labelled as such.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| **Kingfisher** (`mongodb/kingfisher`) | CI-tier scanner CLI with live credential validation; Rust, Apache-2.0 | inapplicable — not on crates.io (`GET https://crates.io/api/v1/crates/kingfisher` returns an unrelated crate at `github.com/mongrov/kingfisher`; MongoDB's workspace sets `publish = false`), 2026-09-10 | inapplicable — same reason | 1,226 (`GET https://api.github.com/repos/mongodb/kingfisher`, 2026-09-10) | v2.2.0, 2026-09-09T08:15:21Z (`GET .../releases`, 2026-09-10) | **active** — released the day before retrieval; `pushed_at` 2026-09-09T08:15:20Z; 4 open issues; 9 of 10 recent issues answered by a maintainer, median 2.48 days | MongoDB itself (4 workflow files in `org:mongodb` reference it, org-scoped code search, 2026-09-10); no third-party well-regarded adopter found — **stated evidence gap** | Youngest and single-vendor, and ships no first-party GitHub Action, so the workflow must install the binary itself |
| **Gitleaks CLI** (`gitleaks/gitleaks`, run directly, *not* via `gitleaks-action`) | CI-tier regex/entropy scanner; Go, MIT | inapplicable — not on crates.io (`GET https://crates.io/api/v1/crates/gitleaks` → `crate 'gitleaks' does not exist`), 2026-09-10 | inapplicable — same reason | 29,207 (`GET https://api.github.com/repos/gitleaks/gitleaks`, 2026-09-10) | v8.30.1, 2026-03-21T02:17:58Z (`GET .../releases`, 2026-09-10) | **stable-quiet** — 5.7 months since the last release, which per the rubric is a trigger to investigate, not a verdict; investigation found `pushed_at` 2026-09-09T04:18:49Z (active commits) but 0 of 10 recent issues answered by a maintainer and 267 open issues. Not `at-risk`: no concrete failure signal, no unpatched advisory, no maintainer notice | Very widely used as a pre-commit hook, including in py's own hook tier (`ADR-02`, referenced from `.github/workflows/secret-scan.yml:2` at pin `b08bccfb`) | **Cannot validate credentials at all** — it reports candidates only, so it cannot satisfy the verified-only requirement on its own |

### Excluded by gate

**TruffleHog OSS Action (`trufflesecurity/trufflehog`) — fails gate 4 (must build/run on every OS
in `ubuntu-latest, macos-latest`).** The Action declares `runs: using: "composite"`, but its single
composite step is a bash script whose final command is `docker run --rm -v .:/tmp -w /tmp
"${IMAGE}:${VERSION}" git file:///tmp/ ...` (read verbatim from
`GET https://api.github.com/repos/trufflesecurity/trufflehog/contents/action.yml?ref=v3.95.9`,
2026-09-10 — the exact tag py pins). GitHub-hosted macOS runners have no Docker daemon and cannot
run container workloads (`https://github.com/orgs/community/discussions/25777` and
`https://github.com/actions/runner/issues/1866`, retrieved 2026-09-10), so the Action is
Linux-only in practice. **Scope of this exclusion, stated precisely:** it excludes the *Action*,
not the *CLI* — TruffleHog ships macOS binaries and would pass gate 4 under architecture shape C.
And R11 owns which runner the scan job lands on, so a single-runner ubuntu job would never hit this
in practice; the exclusion is recorded because this item's constraint says every recommendation
must work on all matrix runners, and because it removes the Action's only real advantage (the
one-line integration). Other gates for TruffleHog, answered for completeness: gate 1 — the CLI is
**AGPL-3.0** (`GET https://api.github.com/repos/trufflesecurity/trufflehog/license`, 2026-09-10);
this is *compatible with* an `MIT OR Apache-2.0` template because the scanner is **executed as a
build tool, never linked into or redistributed with the template's artifacts**, so no copyleft
obligation attaches to `rs-launch-blueprint` and AGPL §13's network clause is not engaged; gate 2 —
`inapplicable`, Go binary with no Cargo MSRV; gate 3 — `inapplicable` for RustSec (not a crate);
`unsafe` posture `inapplicable` (not Rust); gate 5 — no Cargo features, no async-runtime coupling
in the consuming template; gate 6 — 162.7 MiB executable, zero compile-time cost to the template.

**`gitleaks/gitleaks-action` — fails gate 1 (licence).** The GitHub API reports
`license.spdx_id: NOASSERTION` (`GET https://api.github.com/repos/gitleaks/gitleaks-action`,
2026-09-10), and its README confirms the change and the key requirement: "Since v2.0.0 of
Gitleaks-Action, the license has changed from MIT to a [license](LICENSE.txt)", and
"`GITLEAKS_LICENSE` (required for organizations, not required for user accounts)" — the key is
obtained from `gitleaks.io` behind a sign-up form
(`GET https://api.github.com/repos/gitleaks/gitleaks-action/readme`, decoded, 2026-09-10). A
template that lands in an organization would need a per-organization licence key registered as an
Actions secret before CI is green on a fresh clone. That is disqualifying for a template, and it is
also a *secret added to CI in order to run a secret scanner*. The MIT Gitleaks **CLI** is unaffected
and stays on the shortlist. Figures: 644 stars, 43 open issues
(`GET https://api.github.com/search/issues?q=repo:gitleaks/gitleaks-action+is:issue+is:open`,
2026-09-10), last release v3.0.0 2026-05-30T21:42:15Z.

**Nosey Parker (`praetorian-inc/noseyparker`) — fails the maintenance rubric.** `archived: true`,
`pushed_at` 2026-02-21T13:04:04Z, 2,343 stars, Apache-2.0
(`GET https://api.github.com/repos/praetorian-inc/noseyparker`, 2026-09-10). Maintenance state
**archived**, which the rubric treats as terminal without further investigation. Crate figures
`inapplicable`: `GET https://crates.io/api/v1/crates/noseyparker` returns
`crate 'noseyparker' does not exist` (2026-09-10). This is a genuine loss — it was the other
Rust-native option — and its archival is a material part of why Kingfisher has no Rust-native rival.

**`Yelp/detect-secrets` — fails the capability requirement, gates otherwise clean.** Apache-2.0,
4,633 stars, `pushed_at` 2026-04-02T17:10:40Z, not archived
(`GET https://api.github.com/repos/Yelp/detect-secrets`, 2026-09-10). It performs entropy and
regex detection with a baseline file and **does not validate credentials against provider APIs**,
so it cannot produce the verified-only verdict this item requires. It would also add a Python
toolchain to a Rust template's CI. Gate 2, gate 3 (RustSec) and the `unsafe` posture are
`inapplicable` — it is a Python package, not a crate.

**GitGuardian `ggshield` and Semgrep Secrets — excluded before gating.** Both require a vendor
account and an API token stored as a repository secret for CI to pass on a fresh clone, which
defeats a template. Not gated further; recorded so the omission is visible.

### Up-and-comers

**Kingfisher (`mongodb/kingfisher`)** is the only live up-and-comer and it is strong enough to be
the recommendation rather than a watch-list entry. Evidence of momentum, all retrieved 2026-09-10:
created 2025-05-08T17:27:15Z; 1,226 stars; v2.0.0 on 2026-08-23, v2.1.0 on 2026-08-30, v2.2.0 on
2026-09-09 — three releases in 18 days
(`GET https://api.github.com/repos/mongodb/kingfisher/releases`); only 4 open issues with a 2.48-day
median maintainer response. It is Rust (`edition = "2024"`, `rust-version = "1.96"`, Apache-2.0,
`GET https://api.github.com/repos/mongodb/kingfisher/contents/Cargo.toml`), it validates
(`--only-valid`, a documented alias for `--validation-filter active`,
`docs/USAGE.md:61-64`), it emits SARIF (`docs/USAGE.md:120-123`), and every release ships SLSA v1
build-provenance attestations verifiable with `gh attestation verify` or `cosign`
(`docs/INSTALLATION.md`, "Verifying Release Artifacts").

**Nosey Parker** was the previous up-and-comer in this bin and is now archived (see
`### Excluded by gate`). Recorded here so a future re-verification does not resurrect it by
memory.

Also noted and *not* a candidate, because it is adjacent rather than competing: **zizmor**, the
Rust workflow static-analyzer, which `astral-sh/uv` runs as `check-zizmor.yml`
(`GET https://api.github.com/repos/astral-sh/uv/contents/.github/workflows`, 2026-09-10). It
analyses workflow files for insecure patterns; it does not detect credentials. It belongs to R08's
territory, not this item's.

### Fit for this template

**CLI.** The scan is repository-wide and does not care which crate targets exist, so the CLI
surface imposes no requirement of its own. The one CLI-specific risk is the opposite direction:
integration snippets and `--help` fixtures in a CLI template often contain realistic-looking fake
tokens. A **candidate-matching** scanner (Gitleaks, detect-secrets) would flag those and force an
allowlist file; a **validation-filtering** scanner (Kingfisher `--only-valid`, TruffleHog
`--only-verified`) will not, because a fake token fails validation. This is the concrete reason
verified-only is the right mode for a template, and it answers the LOW question: **no
repository-specific configuration — no custom detectors, no path exclusions — is needed at the CI
tier**, because validation filtering already suppresses the false positives that would otherwise
require an allowlist. Any allowlist need belongs to R39's hook tier, which runs a
candidate-matching scanner.

**Library.** `inapplicable` as a code-level concern: nothing is added to the Cargo dependency
graph, so there is no MSRV pressure, no feature-flag surface, no `unsafe` in the template's tree,
and no compile-time or binary-size cost to the published library. The only library-tier interaction
is positive: GitHub native secret scanning covers crates.io API tokens with push protection
(`https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns`,
2026-09-10), which directly protects the `CARGO_REGISTRY_TOKEN` the library surface needs at
publish time — a good reason to enable native scanning alongside the workflow.

**Web service.** This is the surface with real exposure: a web template accumulates `.env.example`
files, database URLs, JWT signing keys and OIDC client secrets, and the `.env` → committed-by-accident
path is the single most common way a live credential enters a repository. Kingfisher validates
database credentials specifically — `CredentialUri` routes PostgreSQL, MySQL/MariaDB, MongoDB and
supported JDBC connection strings to database validators (`docs/USAGE.md:337`, retrieved
2026-09-10) — which is exactly the credential class a Rust web template leaks. This is the
strongest fit argument for the recommendation and it is specific to the web surface.

### Recommendation

**Keep the dedicated CI-tier secret-scanning workflow (F050 preserved), and implement it with the
Kingfisher CLI, version range `>= 2.2.0, < 3.0.0`, installed from a pinned GitHub release with
provenance verification and invoked as `kingfisher scan . --only-valid`.**

Answering the three HIGH questions directly:

**HIGH 1 — is there a Rust-relevant tool at verified-only parity, or must the template keep
TruffleHog's Action regardless of language?** Yes, one exists, and no, the template need not keep
TruffleHog. Kingfisher's `--only-valid` is documented as an alias for `--validation-filter active`
(`docs/USAGE.md:61-64`, 2026-09-10) — the same semantics as TruffleHog's `--only-verified`
("a verified result means TruffleHog confirmed the credential is valid by testing it against the
service's API", TruffleHog README line 406, retrieved 2026-09-10). The parity claim is supported by
an outcome comparison rather than by two vendors' adjectives: on the `gitlab` repository both tools
reported the **same 6** validated/verified findings (`docs/COMPARISON.md`, vendor-authored,
retrieved 2026-09-10). One data point is thin, and it is labelled as such, but it is a *matching*
data point on the metric that matters.

**HIGH 2 — diff-scan on PR and full scan on push, or a single mode?** **A single mode: full-history
scan on both triggers.** py's split is a **workaround for a tool defect, not a design principle**,
and py's own comment says so: "on push (esp. a new repo's FIRST push) base==head, which TruffleHog
rejects ('BASE and HEAD commits are the same')" (`.github/workflows/secret-scan.yml:33-38` at pin
`b08bccfb`, read 2026-09-10). The defect is real and I verified it in the Action's source: the
composite step contains `if [ "$base_commit" == "$head_commit" ] ; then echo "::error::BASE and
HEAD commits are the same..."; exit 1; fi`
(`GET .../contents/action.yml?ref=v3.95.9`, 2026-09-10). Kingfisher has no such constraint —
omitting `--since-commit` scans the full history, and `--since-commit` with `--branch` is available
purely as a speed optimization (`docs/USAGE.md:598-605,644`, 2026-09-10). Dropping the split
removes the two conditional GitHub-expression interpolations from the workflow, which is the
riskiest part of py's file. Cost, stated: a full-history scan on every PR is slower than a diff
scan; the vendor benchmark's smallest repository (`croc`) scanned in 2.64 s and even the Linux
kernel in 205.19 s (`docs/COMPARISON.md`, 2026-09-10), so for a fresh template the difference is
seconds, and the optimization can be added later without changing the tool.

**HIGH 3 — which principles must be preserved across the three repositories, and where must the
design differ?** The preserved principle is the capability-and-policy statement at the top of
`### Principles and implementation`: a server-side, non-bypassable check that fails on a live
credential. What must agree across py, ts and rs is the *existence and enforceability* of that
check and its verified-only failure policy. What may differ is the binary and its packaging,
because the scanner is never part of any repository's dependency graph or public API. Applying
that:

- **rs** should use Kingfisher via a pinned install step (shape C) for the reasons in this section.
- **py**'s TruffleHog choice remains defensible on its own terms; the one finding to carry forward
  is that its diff/full split is a TruffleHog artifact and would simplify away under a different
  tool.
- **ts has a genuine missing capability, not a justified ecosystem difference.** Verified at pin
  `cb1cbcb2`: its workflow set is `ci.yml, codeql.yml, dependency-review.yml,
  difftree-pr-comment.yml, manual-pr-security-scan.yml, publish.yml, release-please.yml,
  update-contributors.yml` (`git ls-tree -r --name-only cb1cbcb2 .github/workflows/`, 2026-09-10),
  and the one workflow whose name suggests otherwise, `manual-pr-security-scan.yml`, runs
  `google/osv-scanner-action` on `workflow_dispatch` — **dependency vulnerability scanning, not
  secret detection**, manually triggered, behind a `security-review` environment gate
  (`git show cb1cbcb2:.github/workflows/manual-pr-security-scan.yml`, 2026-09-10). The prompt's
  premise that ts has no CI secret-scan workflow is **confirmed**, and no BASELINE-REVIEW is needed
  on that point. Closing ts's gap is a follow-on project; this answer supplies its rationale.

**MEDIUM — maintenance and false-positive trade-off between the engines when run as a standalone
CI job.** Two distinct axes, and conflating them is the usual error. *False positives:* validation
filtering (`--only-valid`, `--only-verified`) drives the CI-tier false-positive rate toward zero
without any allowlist file, because a fake or expired token simply fails validation; a
candidate-matcher (Gitleaks, detect-secrets) has a non-trivial false-positive rate on a template
full of example credentials and therefore *requires* an allowlist and a fingerprint-suppression
file — which is precisely why py needs those files at its hook tier and not at its CI tier.
*Maintenance:* the measured issue-responsiveness table in `### Principles and implementation` is
the discriminator — 0 of 10 recent issues answered for both incumbents versus 9 of 10 at a 2.48-day
median for Kingfisher. The trade-off is therefore not "false positives versus maintenance"; on
current evidence Kingfisher leads on both, and pays for it with immaturity and single-vendor
concentration, which is the honest cost recorded in `### Tradeoffs`.

### Ranked runner-up

**TruffleHog OSS CLI, `>= 3.97.0, < 4`, run under architecture shape C** — that is, installed as a
pinned binary in a `run:` step rather than invoked through `trufflesecurity/trufflehog@<tag>`. Shape
C is what lets TruffleHog clear the gate its own Action fails, since the CLI ships macOS binaries
while the Action shells out to `docker run`.

**The condition under which it wins, stated so P03 can test it rather than re-argue it:** if the
owner weights *proven maturity and detector breadth* above *maintainer responsiveness and
ecosystem-native tooling* — concretely, if any one of the following becomes true, switch:

1. Kingfisher's release cadence stops (no release for 6 months) or MongoDB posts a maintenance
   notice — a single-vendor project has a single point of failure and this is that failure mode;
2. P03 measures a **missed** live credential that TruffleHog's 700+ verified detectors
   (TruffleHog README line 414, retrieved 2026-09-10) catch and Kingfisher's rule set does not;
3. the owner decides that the CI tier must use a first-party GitHub Action with no self-managed
   install step, **and** R11 pins the scan job to `ubuntu-latest` only — which together neutralize
   both of shape B's disqualifiers.

A third possibility worth naming: **Gitleaks CLI** is the runner-up's runner-up, and it wins only if
live validation is affirmatively *rejected* as a policy — for example if the owner decides no CI job
may transmit candidate credentials to third-party APIs at all. In that world the gate becomes
candidate-matching plus an allowlist, and Gitleaks (MIT, 0 network requests) is the right tool. That
is a policy reversal, not a tool preference, and it should be decided explicitly.

### Tradeoffs

**Versus TruffleHog (the ranked runner-up), the pick gives up:**

- **Maturity and battle-testing.** 1,226 stars and 16 months versus 27,746 stars and nearly 10
  years (both `GET https://api.github.com/repos/<o>/<r>`, 2026-09-10). *Accepted* because the
  maturity gap is offset by measurable maintenance quality (9/10 versus 0/10 recent issues answered)
  and because the exit condition is cheap: both tools consume the same repository and emit SARIF, so
  switching is a workflow-file edit with no template code change.
- **Detector breadth.** TruffleHog advertises "over 700 credential detectors that support active
  verification" (README line 414, 2026-09-10). Kingfisher publishes "hundreds of built-in rules"
  (README, 2026-09-10) — I could not obtain an exact comparable count and do not invent one.
  *Accepted* because the two agreed on validated findings in the only head-to-head data available,
  and because breadth on *unverified* patterns is the R39 hook tier's job.
- **One-line integration via a first-party Action.** *Accepted* because that advantage is not
  actually available: TruffleHog's Action fails gate 4 on `macos-latest`, so under this template's
  constraints both tools need an install step anyway.
- **Vendor neutrality.** Kingfisher is a single-company project; TruffleHog is a company project
  too, but with a far larger external contributor base. *Accepted*, and it is the risk the
  re-verify trigger exists to catch.

**Versus Gitleaks CLI (the shortlist's other passer), the pick gives up:**

- **Zero network egress.** Gitleaks makes 0 network requests per scan; validation necessarily
  transmits candidate secrets to the issuing providers (`docs/COMPARISON.md`, vendor-authored,
  2026-09-10). *Accepted* with a caveat that P03 must record in the workflow file: **live
  validation of pull-request content sends candidate strings from a fork's diff to third-party
  APIs.** This trade-off is inherent to the verified-only policy py already adopted, so the pick
  does not introduce it. Kingfisher makes it materially smaller than TruffleHog would — 17 versus
  15,624 requests on the same repository for the same 6 findings.
- **The smallest binary.** 14.6 MiB versus 25.3 MiB (same vendor benchmark). *Accepted* as
  immaterial: it is a CI download, not a shipped artifact, and both are an order of magnitude below
  TruffleHog's 162.7 MiB.
- **Longevity.** Gitleaks has 7+ years of history. *Accepted* because it cannot validate at all, so
  it cannot meet the requirement regardless of its longevity.

**Versus doing nothing (architecture A), the pick gives up** roughly 12 lines of workflow YAML, one
more third-party binary in the CI trust path, and a few seconds of PR latency. *Accepted* because
architecture A leaves private clones — the template's principal deployment — with no coverage at
all.

### Parameters

No parameter is owned by R17 (the `owns` column for R17 in `research/CLAUDE.md` is `—`), and no
consumed parameter needs to change.

- `assumes rust-edition = 2024` — inert for this item: no crate is added to the workspace.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — inert under the recommended install path. Recorded for completeness because it nearly bit: Kingfisher's own workspace declares `rust-version = "1.96"` (`GET https://api.github.com/repos/mongodb/kingfisher/contents/Cargo.toml`, 2026-09-10) and current stable is 1.98.1 (`[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`, `https://static.rust-lang.org/dist/channel-rust-stable.toml`, manifest date 2026-09-03, retrieved 2026-09-10), so `stable - 2` is exactly 1.96 and Kingfisher sits precisely on the floor. This matters **only** if P03 ever builds Kingfisher from source in CI; the recommendation installs a prebuilt release binary, for which the MSRV policy is `inapplicable`.
- `assumes license = MIT OR Apache-2.0` — satisfied. Kingfisher is Apache-2.0 (`GET https://api.github.com/repos/mongodb/kingfisher`, 2026-09-10), and as an executed build tool it imposes no obligation on the template's own artifacts in any case.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied. Kingfisher publishes `kingfisher-linux-x64.tgz`, `kingfisher-linux-arm64.tgz`, `kingfisher-darwin-x64.tgz`, `kingfisher-darwin-arm64.tgz` (plus `.deb`, `.rpm` and Windows archives) for v2.2.0 (`GET https://api.github.com/repos/mongodb/kingfisher/releases/tags/v2.2.0`, 2026-09-10), and its own CI runs on `ubuntu-24.04`, `ubuntu-24.04-arm` and `macos-14` (`GET .../contents/.github/workflows/ci.yml`, 2026-09-10). Windows is supported and, per the gate, noted but not required.

No `CONFLICT:` lines.

### Migration implications

File-level changes in the template, all new files unless stated. Nothing here is built by this
item — R17 is research and P03 implements.

1. **New `.github/workflows/secret-scan.yml`** — one job, `permissions: {}` at workflow level with
   `contents: read` on the job, `concurrency` group keyed on `github.ref` with
   `cancel-in-progress: true` (mirroring py's shape, which R08 may refine), triggers
   `push: branches: [main]` and `pull_request`, `actions/checkout` with `fetch-depth: 0` (full
   history is required because the scan covers history), then two steps: install the pinned
   Kingfisher release and verify its provenance, then `kingfisher scan . --only-valid --format sarif
   --output kingfisher.sarif`. **No `base`/`head` conditional expressions** — that is the
   simplification HIGH 2 buys.
2. **No configuration file.** No `.kingfisher.toml`, no allowlist, no fingerprint-suppression file
   at this tier — answering the LOW question. Validation filtering removes the need; adding one
   later is a pure addition.
3. **`.github/dependabot.yml` (owned by R19)** — the `github-actions` ecosystem entry keeps
   `actions/checkout` fresh. It will **not** track Kingfisher, because the version lives in a
   `run:` step, not a `uses:` line. **P03 must therefore add an explicit refresh path** for the
   pinned Kingfisher version: either a scheduled bump lane (R34's territory) or a note in the
   template's maintenance documentation. This is a real cost of architecture shape C and is
   recorded here so it is not discovered late.
4. **Repository settings, not files** — enable GitHub secret scanning and push protection as the
   complementary always-on layer. Free on public repositories; on private ones it requires GitHub
   Secret Protection, which is exactly why the workflow above is not redundant.
5. **Interfaces deliberately left to their owners.** Whether the job is a separate workflow file or
   a job inside the main CI workflow is **R11**'s (`ci-workflow-job-structure`) decision; how its
   result folds into a single required check is **R12**'s; the exact SHA-versus-tag pinning form for
   `actions/checkout` is **R20**'s; the hook-tier scanner and its allowlist are **R39**'s. This item
   supplies only the tool, the scan mode and the triggers.

### Validation strategy

**Status: every command below is proposed. None was executed** — no Rust template exists yet and
this item is research. Each is written so P03 can run it verbatim.

*Proposed acceptance check 1 — the gate fires on a live credential (the check that matters).*
Provision a throwaway credential that genuinely validates (for example an AWS IAM access key with
no permissions attached, or a personal-access token on a scratch account), commit it on a branch,
open a pull request. Expected: the `secret-scan` job **fails**; the log names the file and line;
Kingfisher's exit code is **205**, its documented code for "validated secrets are present"
(`docs/USAGE.md:644`, retrieved 2026-09-10). Revoke the credential immediately afterwards. This is
the only check that proves the principle rather than the plumbing.

*Proposed acceptance check 2 — no false-positive gate on template example credentials.* Commit a
realistic-looking but non-live token (a well-formed `AKIA`-prefixed string that is not a real key,
plus a fake `postgres://user:password@localhost/db` in `.env.example`). Expected: the job
**passes**, because `--only-valid` discards unvalidated candidates. This is the check that proves no
allowlist file is needed, which is the LOW question's answer.

*Proposed acceptance check 3 — the first-push case that broke py.* Push the initial commit to a
brand-new repository created from the template, where `github.event.before` is the all-zeroes SHA.
Expected: the job **passes cleanly with no error**, in contrast to the
`::error::BASE and HEAD commits are the same` failure that py's comment records for TruffleHog's
Action. This check exists specifically to confirm that dropping the diff/full split removed the
defect rather than hiding it.

*Proposed local reproduction, so a contributor can debug without pushing:*

```
kingfisher scan . --only-valid --format sarif --output kingfisher.sarif ; echo "exit=$?"
```
Expected: exit `0` on a clean tree, `200` when unvalidated findings exist, `205` when validated
secrets are present (`docs/USAGE.md:644`, 2026-09-10). P03 should confirm whether the workflow
should fail on `200` as well as `205`; the recommendation is to fail on `205` only, so that
`--only-valid` genuinely means verified-only.

*Proposed supply-chain verification of the scanner itself, run inside the install step:*

```
gh release download v2.2.0 --repo mongodb/kingfisher --pattern 'kingfisher-linux-x64.tgz'
gh attestation verify kingfisher-linux-x64.tgz --repo mongodb/kingfisher
```
Expected: verification succeeds, tying the artifact digest to Kingfisher's release workflow, tag and
source commit (`docs/INSTALLATION.md`, "Verifying Release Artifacts", retrieved 2026-09-10). This
step is the concrete reason shape C is *safer* than shape B rather than merely more verbose: a
tag-pinned third-party Action offers no equivalent attestation.

**Checks actually executed during this research**, distinguished as the prompt requires: only
read-only endpoint queries and `git show` reads against the two pinned source repositories. No
scanner was run, no workflow was executed, and no template was scaffolded.

### Confidence & re-verify trigger

**Confidence in *keeping* a dedicated CI-tier workflow: high.** It rests on two documented platform
facts (native scanning is free only on public repositories; it emits no PR status check) plus the
template's private-clone use case. The contrary evidence — 0 of 10 well-regarded Rust projects run
one — is fully accounted for: those projects are all public, so the free tier already covers them.

**Confidence in *Kingfisher* as the tool: medium.** Every gate answer, figure and semantic claim is
sourced, and the maintenance signals are unusually good. The uncertainty is concentrated in three
places, named rather than smoothed over: (a) the tool is 16 months old and single-vendor; (b) I
found **no third-party well-regarded adopter** — adoption evidence is MongoDB-internal plus star
count; (c) the only head-to-head performance and detection comparison is **vendor-authored by
MongoDB**, and although its validated-finding parity with TruffleHog is a matching outcome rather
than a self-assessment, it is one data point on one repository.

**Confidence in the single-scan-mode simplification: high.** It follows from source evidence on both
sides — py's own comment naming the defect, the defect's code in TruffleHog's `action.yml` at the
pinned tag, and Kingfisher's documented behaviour when `--since-commit` is omitted.

**Re-verify triggers — check this item again if any of these occurs:**

1. `GET https://api.github.com/repos/mongodb/kingfisher` shows `archived: true`, or
   `GET .../releases` shows no release for 6 months, or MongoDB posts a maintenance notice. Any one
   flips the recommendation to the ranked runner-up.
2. Kingfisher publishes a first-party GitHub Action, or TruffleHog's Action stops requiring Docker
   (re-read `GET https://api.github.com/repos/trufflesecurity/trufflehog/contents/action.yml?ref=<tag>`
   and check for `docker run`). Either changes the architecture-shape calculus.
3. GitHub makes secret scanning free on private repositories **and** adds a pull-request status
   check. Together those two would make architecture A viable and could retire this workflow
   entirely; either alone would not.
4. R39 selects a scanner for the hook tier. If it selects Kingfisher, the F050 `BASELINE-REVIEW:`
   above must be resolved by the owner before both tiers share a tool.
5. R11 or R12 constrains the scan job in a way that assumes a first-party Action or a specific
   runner OS.
6. A third-party, well-regarded Rust project adopts Kingfisher in CI — this would close the stated
   adoption gap and raise confidence from medium to high without changing the recommendation.

### Sources

All URLs retrieved **2026-09-10** unless stated otherwise.

**Source repositories, read through their programme pins.**
- py `.github/workflows/secret-scan.yml` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, via `git show b08bccfb:.github/workflows/secret-scan.yml` — TruffleHog `v3.95.9`, `--only-verified`, `base`/`head` conditional, `permissions: {}`, `fetch-depth: 0`, and the comments at lines 1-2 and 33-38 quoted in this report. **Pin-versus-HEAD check performed for this file:** `git show HEAD:.github/workflows/secret-scan.yml` at py HEAD `c1216c6` names the identical `uses:` lines (`actions/checkout@v7`, `trufflesecurity/trufflehog@v3.95.9`), so the pin/HEAD action-pinning divergence flagged in the role file **does not affect any claim in this report**.
- ts workflow inventory at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, via `git ls-tree -r --name-only cb1cbcb2 .github/workflows/` and `git show cb1cbcb2:.github/workflows/manual-pr-security-scan.yml` — confirms no CI secret-scan workflow, and that `manual-pr-security-scan.yml` is a manually dispatched `google/osv-scanner-action` dependency scan.
- `docs/port/COMMONALITY.md:56` (F050) and `:167-170` (F163-F166, R39's rows), read in the working tree.
- `research/runs/R17/.../inputs/parameters.json` and `inputs/PARAMETERS.md:7-10` for the four fixed parameters.

**crates.io — `GET https://crates.io/api/v1/crates/<name>` and `/versions`, User-Agent set.**
- `kingfisher` → a real but **unrelated** crate: `crate.recent_downloads` 48, `crate.downloads` 7,406, `crate.newest_version` 0.1.2, `repository` `https://github.com/mongrov/kingfisher`; newest non-yanked version 0.1.2 created 2023-09-27T22:01:04.728797Z, licence `MIT OR Apache-2.0`. **Not MongoDB's scanner.**
- `noseyparker`, `trufflehog`, `gitleaks`, `kingfisher-core`, `kingfisher-rules`, `kingfisher-scanner` → all return `crate '<name>' does not exist`. MongoDB's workspace sets `publish = false`.

**GitHub REST — `GET https://api.github.com/repos/<o>/<r>`.**
- `trufflesecurity/trufflehog`: 27,746 stars, `archived` false, `pushed_at` 2026-09-10T14:22:52Z, licence AGPL-3.0, Go, created 2016-12-31T05:08:12Z.
- `gitleaks/gitleaks`: 29,207 stars, `archived` false, `pushed_at` 2026-09-09T04:18:49Z, MIT, Go.
- `gitleaks/gitleaks-action`: 644 stars, `pushed_at` 2026-07-21T07:03:11Z, licence `NOASSERTION`.
- `mongodb/kingfisher`: 1,226 stars, `archived` false, `pushed_at` 2026-09-09T08:15:20Z, Apache-2.0, Rust, created 2025-05-08T17:27:15Z.
- `praetorian-inc/noseyparker`: 2,343 stars, **`archived` true**, `pushed_at` 2026-02-21T13:04:04Z, Apache-2.0.
- `Yelp/detect-secrets`: 4,633 stars, `archived` false, `pushed_at` 2026-04-02T17:10:40Z, Apache-2.0, Python.

**GitHub REST — open issues, `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, field `total_count`.** trufflehog 267 · gitleaks 267 · gitleaks-action 43 · kingfisher 4.

**GitHub REST — releases, `GET https://api.github.com/repos/<o>/<r>/releases`.** trufflehog v3.97.4 2026-09-03T20:01:40Z (also v3.97.3, v3.97.2 on 2026-09-03/02) · gitleaks v8.30.1 2026-03-21T02:17:58Z · gitleaks-action v3.0.0 2026-05-30T21:42:15Z · kingfisher v2.2.0 2026-09-09T08:15:21Z, v2.1.0 2026-08-30T22:55:10Z, v2.0.0 2026-08-23T23:23:16Z. Assets for `GET .../releases/tags/v2.2.0`: `kingfisher-darwin-arm64.tgz, kingfisher-darwin-x64.tgz, kingfisher-linux-arm64.deb/.rpm/.tgz, kingfisher-linux-x64.deb/.rpm/.tgz, kingfisher-windows-arm64.zip, kingfisher-windows-x64.zip, multiple.intoto.jsonl`.

**GitHub REST — issue responsiveness.** `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+sort:created-desc&per_page=10` for the 10 most recent issues, then `GET https://api.github.com/repos/<o>/<r>/issues/<n>/comments?per_page=40` filtered to `author_association` in {OWNER, MEMBER, COLLABORATOR}. trufflehog: 0/10 answered (issues 5299, 5276, 5262, 5254, 5232, 5218, 5205, 5190, 5187, 5184). gitleaks: 0/10 answered (2257, 2256, 2239, 2232, 2231, 2225, 2223, 2218, 2214, 2198). kingfisher: 9/10 answered, per-issue lags 2.50, 1.55, 4.23, 0.67, 0.27, 0.54, 2.68, none, 3.90, 2.48 days → median 2.48 days.

**GitHub REST — repository contents (all decoded from `GET .../contents/<path>`).**
- `trufflesecurity/trufflehog/action.yml?ref=v3.95.9` — `runs: using: "composite"`, the `BASE`/`HEAD` equality guard that exits 1, and the terminating `docker run --rm -v .:/tmp -w /tmp "${IMAGE}:${VERSION}" git file:///tmp/ ...`.
- `trufflesecurity/trufflehog` README — line 406 (verified = confirmed valid against the service's API), line 414 ("over 700 credential detectors that support active verification"), lines 420-428 (verified/unverified/unknown statuses). `GET .../license` → `AGPL-3.0`.
- `gitleaks/gitleaks-action` README — line 43 and line 75 (`GITLEAKS_LICENSE` "required for organizations, not required for user accounts"), lines 87-95 (free key via a sign-up form at gitleaks.io), lines 115-116 (licence changed from MIT at v2.0.0).
- `mongodb/kingfisher` README, `docs/USAGE.md` (lines 61-64 `--only-valid` = `--validation-filter active`; 120-123 SARIF output; 337 `CredentialUri` database validators; 598-605 and 644 `--since-commit`/`--branch` CI diff scanning and exit codes 200/205), `docs/INSTALLATION.md` (SLSA v1 provenance, `gh attestation verify`, cosign, Homebrew, mise, PyPI `kingfisher-bin`, Docker), `docs/DEPLOYMENT.md` (CI and pre-commit models; `kingfisher-core`/`-rules`/`-scanner` embeddable crates), `docs/COMPARISON.md` (vendor benchmark: runtimes, validated/verified counts, network requests, binary sizes, and the environment — darwin/arm64, 16 cores, 48.00 GB RAM, September 2026), `Cargo.toml` (`edition = "2024"`, `rust-version = "1.96"`, `license = "Apache-2.0"`, `publish = false`), `.github/workflows/ci.yml` (`ubuntu-24.04`, `ubuntu-24.04-arm`, `macos-14`).
- Workflow inventories for the ten surveyed projects, `GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows`.

**GitHub REST — code search.** `GET https://api.github.com/search/code?q=repo:<o>/<r>+trufflehog+OR+gitleaks` → `total_count` 0 for `tokio-rs/tokio`, `rust-lang/cargo`, `astral-sh/uv`, `rustls/rustls`, `clap-rs/clap`. `GET https://api.github.com/search/code?q=org:mongodb+kingfisher+path:.github/workflows` → `total_count` 4.

**RustSec.** `https://rustsec.org/packages/kingfisher.html` → HTTP 404 (retrieved 2026-09-10), consistent with there being no published `kingfisher` crate from MongoDB. Advisory checks are `inapplicable` for every candidate in this item, none of which is a crate in the template's dependency tree.

**Rust release channel.** `https://static.rust-lang.org/dist/channel-rust-stable.toml` — `[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`, manifest `date = "2026-09-03"`.

**Platform and standards documentation.**
- `https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning` — "Secret scanning runs automatically for free" in public repositories; private and internal repositories require GitHub Secret Protection with GitHub Team or GitHub Enterprise Cloud; "Validity checks help you prioritize which secrets to remediate first by verifying whether a detected secret is still active" (optional, must be enabled).
- `https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns` — "crates.io | Crates.io API Token | `cratesio_api_token` | ✓" with push protection supported.
- `https://github.com/ossf/scorecard/blob/main/docs/checks.md` — the 20 Scorecard checks; none concerns secret scanning or leaked credentials.
- `https://baseline.openssf.org/versions/2025-02-25.html` — no control mandates repository secret scanning at any maturity level.
- `https://github.com/orgs/community/discussions/25777` and `https://github.com/actions/runner/issues/1866` — Docker is not installed on GitHub-hosted macOS runners and container operations are unsupported there.

**Method notes.** Figures came from these endpoints only: crates.io `/api/v1/crates/<name>` and `/versions` (User-Agent set); GitHub REST `/repos/<o>/<r>`, `/repos/<o>/<r>/releases`, `/repos/<o>/<r>/releases/tags/<tag>`, `/repos/<o>/<r>/contents/<path>`, `/repos/<o>/<r>/issues/<n>/comments`, `/search/issues`, `/search/code`, `/repos/<o>/<r>/license`, `/repos/<o>/<r>/readme`; `https://rustsec.org/packages/kingfisher.html`; `https://static.rust-lang.org/dist/channel-rust-stable.toml`; and the maintainer/platform documentation URLs listed above. Both source repositories were read exclusively through `git show <pin>:<path>`, never from the working tree, and the py pin-versus-HEAD comparison for `secret-scan.yml` is recorded above. **What I could not verify, listed so nothing is inferred from silence:** (1) **global adoption counts** for the TruffleHog, Gitleaks and Kingfisher GitHub Actions — GitHub's code-search API rejects an unscoped query and returned an empty body for `q="trufflesecurity/trufflehog"+path:.github/workflows` and the two equivalents; only repo- and org-scoped counts are reported. (2) **Any third-party well-regarded Rust project using Kingfisher in CI** — none found; adoption evidence is MongoDB-internal plus star count, and this gap drives the medium confidence and re-verify trigger 6. (3) **Kingfisher's exact built-in rule count**, to compare against TruffleHog's stated 700+ detectors — its README says "hundreds" and no precise figure was published at a queried endpoint, so none is asserted. (4) **Independent (non-vendor) head-to-head benchmarks** of runtime, network requests, validated-finding counts or binary sizes — every comparative number in this report comes from MongoDB's own `docs/COMPARISON.md` and is labelled vendor-authored wherever cited. (5) **The precise runtime behaviour of py's push-path invocation.** py passes `base: ''` and `head: 'HEAD'`; in the Action's script the unquoted `${BASE:-''}` expansion drops the argument entirely, so the command becomes `... --since-commit --branch HEAD ...` with no value after `--since-commit`. Whether TruffleHog then consumes `--branch` as that flag's value, or tolerates it and performs the intended full-history scan, **cannot be determined without executing the tool**, which this research did not do. It is recorded as a P03 verification item and it does not affect any recommendation here, because the recommended design has no `--since-commit` flag at all. (6) A GitHub Docs page stating the macOS/Docker limitation normatively — `https://docs.github.com/en/actions/how-tos/create-and-publish-actions/about-custom-actions` returned HTTP 404 and the GitHub-hosted-runners reference page does not address macOS Docker support, so the claim rests on the GitHub community discussion and `actions/runner` issue cited above plus the primary evidence of the `docker run` line in `action.yml` itself.
