# R21 — contributors-bot-credential-source (pattern) — Opus raw report

Engine: opus (claude-opus-5). Item kind: `pattern`. Tier: focused. All retrievals
dated 2026-09-10 unless stated otherwise. Source repositories were read through
their programme pins: `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`
(`git show b08bccfb:<path>`) and `ts-launch-blueprint` at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` (`git show cb1cbcb2:<path>`).

### Landscape

**Category this item decides.** The credential a GitHub Actions job passes to
`smorinlabs/contributors-please-action`'s `pat:` input when GitHub App credentials
are absent — that is, *bot-PR credential provisioning for a public template
repository*. It is a GitHub Actions / repository-administration decision, not a
Rust crate decision: the artifact changed is `.github/workflows/update-contributors.yml`
plus the template's repo-secrets documentation. No Rust code, crate, or `Cargo.toml`
entry is involved, which is why the crate figure table below is largely
`inapplicable` (each row states the reason).

**Three-bin map of the field.**

| Bin | Candidates found | Evidence |
|---|---|---|
| Built-in / first-party toolchain | (a) ambient `secrets.GITHUB_TOKEN` — an installation access token minted per job; (b) the repository/organization setting **Allow GitHub Actions to create and approve pull requests**; (c) `actions/create-github-app-token` — GitHub-owned action that mints an App installation token inside the workflow | GitHub Docs, `https://docs.github.com/en/actions/concepts/security/github_token` (retrieved 2026-09-10); `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository` (retrieved 2026-09-10); `GET https://api.github.com/repos/actions/create-github-app-token` → `stargazers_count` 885, `archived` false, `pushed_at` 2026-08-04T01:40:22Z, `license.spdx_id` MIT (retrieved 2026-09-10); `GET https://api.github.com/search/issues?q=repo:actions/create-github-app-token+is:issue+is:open` → `total_count` 10 (retrieved 2026-09-10) |
| Established industry standard | (d) a **dedicated fine-grained PAT** stored as a repository secret and passed as the bot credential; (e) **GitHub App credentials primary with a PAT fallback** — the shape both source repos already use | `peter-evans/create-pull-request` concepts guide, `https://github.com/peter-evans/create-pull-request/blob/main/docs/concepts-guidelines.md` (retrieved 2026-09-10): a PAT is "the standard workaround and recommended by GitHub"; `GET https://api.github.com/repos/peter-evans/create-pull-request` → `stargazers_count` 2847, `archived` false, `pushed_at` 2026-09-03T00:42:16Z, MIT (retrieved 2026-09-10); open issues `total_count` 18 via `GET /search/issues?q=repo:peter-evans/create-pull-request+is:issue+is:open` (retrieved 2026-09-10) |
| Up-and-comer | (f) first-party App-token minting replacing third-party App-token actions; (g) App-only configurations with **no** PAT fallback at all | `tibdex/github-app-token` — the previous third-party default — is now archived: `GET https://api.github.com/repos/tibdex/github-app-token` → `archived` true, `pushed_at` 2025-07-07T19:51:41Z, `stargazers_count` 564 (retrieved 2026-09-10). Its first-party successor is `actions/create-github-app-token` (row (c)) |

**Authoritative sources used, and why each counts.**

1. **GitHub Docs** — GitHub owns the semantics of `GITHUB_TOKEN`, installation
   access tokens, and the pull-request-creation setting; nothing else can be
   authoritative about them. Pages used: `github_token` concept page, the
   installation-access-token endpoint list, "Authenticating as a GitHub App
   installation", and the repository Actions-settings page (all retrieved
   2026-09-10).
2. **The tool's own maintainer documentation and source** —
   `smorinlabs/contributors-please-action`, which ledger row F060 fixes as the
   implementation for both repos (`docs/port/COMMONALITY.md:66`). Its README and
   its `src/index.ts` at the exact pinned commit decide what each credential value
   does. The pin is verifiable: `GET https://api.github.com/repos/smorinlabs/contributors-please-action/git/ref/tags/v1.3.9`
   → `object.sha` `3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1` (retrieved 2026-09-10),
   which is precisely the SHA `ts-launch-blueprint` pins at
   `.github/workflows/update-contributors.yml:80`, and the tag `py-launch-blueprint`
   pins at `.github/workflows/update-contributors.yml:27`.
3. **`peter-evans/create-pull-request` concepts-and-guidelines** — the most widely
   used bot-PR action outside GitHub itself (2847 stars, actively pushed
   2026-09-03); its guidance is the de-facto community standard on this exact
   trade-off, and the prompt's own question text names it.
4. **`release-plz` documentation** (`https://release-plz.dev/docs/github/token`,
   retrieved 2026-09-10) — the Rust-native authority. `release-plz` is the Rust
   ecosystem's dominant release-PR bot (the same architectural shape as this
   contributors bot: a scheduled job that opens a bot PR against `main`), and its
   token page exists solely because the default-token choice bites Rust projects.
5. Community discussion threads were treated as *leads only*; every load-bearing
   claim below is anchored to GitHub Docs, to the action's source at its pinned
   commit, or to a live GitHub REST response.

**Well-regarded projects surveyed, with the evidence that they are well regarded.**

- `release-plz` — the Rust release-automation project whose token page explicitly
  states "GitHub Actions using the default `GITHUB_TOKEN` cannot trigger other
  workflow runs" and "Workflows acting as checks on pull requests opened by GitHub
  Actions with the default GitHub token won't run", then lists three alternatives:
  a PAT ("the standard method recommended by GitHub"), a GitHub App (what the
  release-plz repository itself uses), and `actions/create-github-app-token`
  (retrieved 2026-09-10). Relevance: same bot-PR shape, same ecosystem as the
  target template.
- `peter-evans/create-pull-request` — 2847 stars, active (`pushed_at`
  2026-09-03T00:42:16Z), 18 open issues; recommends a PAT or an App-generated
  token and describes App tokens as superior because they have "fine-grained
  permissions and are scoped to only repositories where the App is installed"
  (retrieved 2026-09-10). Relevance: it is the step `py-launch-blueprint`'s
  ancestor pipeline used, per `docs/port/TS_PORT_DECISIONS.md` D-022(11).
- `smorinlabs/contributors-please-action` — small by stars (`stargazers_count` 0,
  1 open issue, `pushed_at` 2026-09-01T22:51:20Z, MIT, retrieved 2026-09-10), so
  it is *not* cited as a popularity authority; it is cited as the normative
  implementation both repos are pinned to, and its own end-to-end workflow is
  first-party evidence about which credential values are actually supported.

### Principles and implementation

**Shared requirement.** The contributors bot must open a pull request that behaves
like a human-authored pull request in a repository whose default branch has
required status checks, using a credential the repository owner provisions once,
and it must fail loudly rather than silently when no credential is provisioned.

**Source of the requirement.** Ledger rows F060 (`COMMON → REUSE`, both repos run
`smorinlabs/contributors-please-action` in `mode: pull-request`) and F061
(`DIVERGENT`, this item) in `docs/port/COMMONALITY.md:66-67`; the TypeScript port
decision D-022(11) ("branch-sync idempotency, bot commit, PR-not-push"); and the
owner direction of 2026-09-04 recorded in `docs/port/OWNER-REVIEW.md:63` ("For this
one, we should model it on what PyLaunch Blueprint does").

**Agreement level: policy.** The mechanism is entirely language-neutral — a YAML
input and a repository secret. Nothing about Rust, Python, or TypeScript changes
what a GitHub token can do. So this is one of the few items where a *shared
low-level value* across py, ts and rs is justified on evidence rather than on
taste, and where an ecosystem-specific divergence would be accidental drift rather
than a justified difference. What must agree: the credential *class* (a user- or
App-identity token capable of triggering downstream workflows). What may vary: the
secret's name, whether the App is installed, and the workflow's trigger cadence
(R07 owns that; out of scope here).

**Essential behaviors the credential must support.**

| ID | Behavior | Why it is essential |
|---|---|---|
| B1 | Credential resolution must yield a GitHub identity (login + e-mail) for commit attribution | `contributors-please-action` resolves the PAT path by calling `GET <api>/user` and *throws* if the call is not `ok`: `src/index.ts:432` builds the request, `src/index.ts:439` raises `` `GitHub token identity lookup failed: ${response.status}` `` (read at commit `3c6dbff9` = tag v1.3.9, retrieved 2026-09-10) |
| B2 | Credential must be able to push a branch and open/update a PR | `mode: pull-request` "push `contributors-please/update`, create or update a PR, and apply the `contributors-please: pending` label" (action README, retrieved 2026-09-10) |
| B3 | The resulting PR must trigger the repository's `pull_request` workflows so required checks report | GitHub Docs: "Events triggered by the `GITHUB_TOKEN` will not create a new workflow run, with the following exceptions: `workflow_dispatch` and `repository_dispatch`" (`https://docs.github.com/en/actions/concepts/security/github_token`, retrieved 2026-09-10) |
| B4 | The common path should avoid a long-lived credential | App installation tokens "expire after 1 hour" and are scoped to the installation (`https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation`, retrieved 2026-09-10) |
| B5 | An unprovisioned repository must fail fast with an actionable message | `src/index.ts:114`: `actionCore.setFailed("Provide either app-id + private-key, or pat.")` (commit `3c6dbff9`, retrieved 2026-09-10) |

**Observable acceptance criteria.** In a repository created from the template with
the App *not* installed and the fallback secret configured, a `workflow_dispatch`
run of `update-contributors.yml` finishes `success`, the action's outputs report
`token-source=pat` and `pr-opened=true` with a non-empty `pr-url`, and the opened
PR shows the repository's own CI checks *reporting a conclusion* (not stuck at
"Expected — waiting for status to be reported").

**Architectural alternatives compared before any library choice.**

1. **App credentials primary, dedicated PAT fallback** (py shape). Satisfies
   B1–B5. The PAT is the only path that works for a consumer who cannot install a
   GitHub App (a consumer may lack the rights to install an App on the account or organization
   that owns their copy; GitHub requires the installer to have the necessary access
   to the target account, `https://docs.github.com/en/apps/using-github-apps/installing-a-github-app-from-a-third-party`,
   retrieved 2026-09-10 — I have no frequency data and make no claim about how
   often this occurs).
2. **App credentials primary, `secrets.GITHUB_TOKEN` fallback** (ts shape).
   *Fails B1.* `secrets.GITHUB_TOKEN` is an installation access token
   ("At the start of each workflow job, GitHub automatically creates a unique
   `GITHUB_TOKEN` secret", `https://docs.github.com/en/actions/concepts/security/github_token`,
   retrieved 2026-09-10), and `GET /user` is **absent** from GitHub's list of
   endpoints available to installation access tokens — that page's `users` section
   lists `GET /user/{account_id}`, `GET /users`, `GET /users/{username}` and
   related endpoints but not the bare `GET /user`
   (`https://docs.github.com/en/rest/authentication/endpoints-available-for-github-app-installation-access-tokens?apiVersion=2022-11-28`,
   fetched and text-extracted 2026-09-10). The action's PAT path calls exactly that
   endpoint (`src/index.ts:432`), so the run is expected to abort at credential
   resolution with `GitHub token identity lookup failed: 403` before any PR is
   attempted. It *also* fails B3 independently, and B2 is conditionally blocked:
   "By default, when you create a new repository in your personal account,
   workflows are not allowed to create or approve pull requests"
   (`https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository`,
   retrieved 2026-09-10) — so the "zero extra setup" claim would require a
   repository-settings change even if B1 were satisfied.
3. **App credentials only, no `pat:` input.** Satisfies B2–B5 and sidesteps B1 by
   never taking the PAT path; the consumer without an App gets the clean
   `Provide either app-id + private-key, or pat.` failure instead of a 403. Costs:
   no supported path for a consumer who cannot install the App.
4. **Mint an App token in the workflow with `actions/create-github-app-token`,
   pass the result as `pat:`.** Architecturally redundant here — the action already
   mints its own installation token from `app-id`/`private-key` internally
   (`src/app-token.ts`, which resolves the App's committer identity through
   `GET /users/{username}` at `src/app-token.ts:57` (same commit `3c6dbff9`), an endpoint that *is*
   available to installation tokens). It would also re-introduce B1's failure,
   because a minted App installation token is still an installation token.

**How the recommended design preserves each principle, and where an ecosystem
would need something different.** Option 1 keeps the App as the preferred, short-lived,
scoped credential (B4) exactly as both source repos already do, and reserves the
long-lived secret for the case the App cannot cover — which is the same trade-off
`release-plz` documents for Rust and `peter-evans/create-pull-request` documents
generally. No ecosystem needs a different design here, because no part of the
mechanism touches the language toolchain; the Rust template differs only in *which
checks* the bot PR must trigger (`cargo fmt`/`clippy`/`test` on `ubuntu-latest` and
`macos-latest`), which strengthens rather than weakens B3.

**Corroborating detail from py's own workflow.** `py-launch-blueprint`'s workflow
overrides the action's default commit message with an explanatory comment (at pin
`b08bccfb`, `.github/workflows/update-contributors.yml`): "`[skip ci]` suppresses
the pull_request workflows behind main's required checks, leaving the bot PR
permanently blocked." A PR opened with `GITHUB_TOKEN` reaches the *same* blocked
end state by a different mechanism (no `pull_request` run is created at all). The
action's README carries the matching warning for `mode: pull-request` (retrieved
2026-09-10). So the capability a dedicated credential provides — triggering
downstream workflows — is not a nice-to-have for this template; it is what keeps
the bot PR mergeable under required checks.

**Whether the fallback has ever run.** Neither source repository has the fallback
configured in a way that exercises it. Repository secret listings (retrieved
2026-09-10, authenticated `gh api`):
`GET repos/smorinlabs/ts-launch-blueprint/actions/secrets` →
`CONTRIBUTORS_PLEASE_CLIENT_ID`, `CONTRIBUTORS_PLEASE_PRIVATE_KEY`,
`RELEASE_PLEASE_CLIENT_ID`, `RELEASE_PLEASE_PRIVATE_KEY`;
`GET repos/smorinlabs/py-launch-blueprint/actions/secrets` → the same four plus
`CLAUDE_CODE_OAUTH_TOKEN`, `CODECOV_TOKEN`, `RUNNER_MACOS`, `RUNNER_UBUNTU`,
`RUNNER_WINDOWS`, `SAFETY_API_KEY`. **`CONTRIBUTORS_PLEASE_PAT` is set in neither
repository.** Because `src/index.ts:397` takes the App branch whenever `app-id`
and `private-key` are both present, every green run in either repo used the App
path. The ts workflow's last six scheduled runs are green
(`GET repos/smorinlabs/ts-launch-blueprint/actions/workflows/310387832/runs`,
retrieved 2026-09-10: 2026-09-07, 2026-08-31, 2026-08-24, 2026-08-17, 2026-08-10,
2026-08-03 all `success`; 2026-07-27, 2026-07-20, 2026-07-13 `failure`), and the
job log for the newest run (`GET repos/smorinlabs/ts-launch-blueprint/actions/jobs/101745643227/logs`,
retrieved 2026-09-10) shows the step invoked with `app-id: ***`, `private-key: ***`
and `pat: ***` together — i.e. the App branch. The logs for the July failures are
no longer retrievable (the run-level logs endpoint returned a 22-byte stub), so I
cannot say what those failures were; I record that as unverified.

**Third-party corroboration that `GITHUB_TOKEN` is not a supported value for this
input.** The action's own end-to-end suite only ever exercises the PAT path with a
*real* PAT: `.github/workflows/e2e.yml` lines 107, 140, 234 and 294 pass
`pat: ${{ env.HAS_APP != 'true' && secrets.CONTRIBUTORS_PLEASE_PAT || '' }}`, and
line 370 passes `secrets.GHE_CONTRIBUTORS_PLEASE_PAT` for the GitHub Enterprise
lane (repository clone at HEAD `cbb1fd47`, retrieved 2026-09-10). No test anywhere
in the action's repository passes `secrets.GITHUB_TOKEN` to `pat:`.

BASELINE-REVIEW: F061 — a documented credential fallback must be functional and must have been exercised before it is recorded as a working property — replace the Notes text "ts's choice lets the template work with zero extra repo secrets configured" with "the `secrets.GITHUB_TOKEN` fallback is expected to be non-functional against `contributors-please-action` v1.3.9 and has never executed in either source repository" — evidence: (1) `GET /user` is absent from GitHub's installation-access-token endpoint list while `GITHUB_TOKEN` is an installation access token (GitHub Docs, retrieved 2026-09-10); (2) the action's PAT path calls `GET <api>/user` and throws on a non-ok response, `src/index.ts:432,439` at tag v1.3.9 = `3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1`; (3) `GITHUB_TOKEN`-created PRs do not trigger workflow runs (GitHub Docs, retrieved 2026-09-10), so required checks never report; (4) new repositories default to "workflows are not allowed to create or approve pull requests" (GitHub Docs, retrieved 2026-09-10), so the claim "zero extra setup" is false even before (1)–(3); (5) `CONTRIBUTORS_PLEASE_PAT` is unset and App credentials are set in **both** source repos, so no green run evidences the fallback. Affected items: F061 (R21) only; F060 (the action and `mode: pull-request`) and F026 (R07, cadence) are unaffected. I have not edited the ledger or any other item.

### Dominant choice

A **dedicated credential** — GitHub App credentials preferred, with a dedicated
fine-grained personal access token stored as a named repository secret as the
fallback. This is the shape `py-launch-blueprint` uses, the shape the action's own
end-to-end suite tests, the shape `peter-evans/create-pull-request` documents as
"the standard workaround and recommended by GitHub", and the shape `release-plz`
tells Rust projects to adopt. The ambient `GITHUB_TOKEN` is not a member of the
dominant choice for bot PRs that must pass required checks.

### Options

Qualified shortlist. No download columns apply — this is a `pattern` item with no
crate.

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **O1 — App credentials primary, dedicated PAT fallback** (`pat: ${{ secrets.CONTRIBUTORS_PLEASE_PAT }}`) | `contributors-please-action` README, "App credentials are preferred when both App and PAT inputs are present. The PAT is a fallback for repositories that have not installed the App yet" (retrieved 2026-09-10); `py-launch-blueprint/.github/workflows/update-contributors.yml:32-34` at pin `b08bccfb`; `py-launch-blueprint/docs/POST_INIT.md:118` at the same pin, which lists `CONTRIBUTORS_PLEASE_CLIENT_ID` + `CONTRIBUTORS_PLEASE_PRIVATE_KEY` + `CONTRIBUTORS_PLEASE_PAT` as the secrets `update-contributors.yml` requires | `py-launch-blueprint` (workflow at pin); `contributors-please-action`'s own e2e suite (`.github/workflows/e2e.yml:107,140,234,294`, retrieved 2026-09-10) — the only place the PAT path is actually exercised | `peter-evans/create-pull-request` concepts guide, repo `pushed_at` 2026-09-03T00:42:16Z (retrieved 2026-09-10) |
| **O2 — App credentials only, no `pat:` input** | Action fail-fast contract, `src/index.ts:114` at tag v1.3.9 (retrieved 2026-09-10) | No adopter observed among the two source repos or the action's own workflows; both source repos always pass a fallback input | Action README + `action.yml` (`pat` is `required: false`, `default: ''`), retrieved 2026-09-10 |
| **O3 — App credentials primary, token minted in-workflow by `actions/create-github-app-token`, passed as `pat:`** | `https://github.com/actions/create-github-app-token` (first-party); recommended as one of three options by `release-plz.dev/docs/github/token` (retrieved 2026-09-10) | `release-plz` documents it for Rust projects; widely used generally (885 stars, MIT, `pushed_at` 2026-08-04T01:40:22Z, 10 open issues; retrieved 2026-09-10) | `actions/create-github-app-token` repository, `pushed_at` 2026-08-04T01:40:22Z (retrieved 2026-09-10) |

### Excluded by gate

**Functional-fitness exclusion (this item's acceptance criteria).**

- **`pat: ${{ secrets.GITHUB_TOKEN }}` — the ts shape** (`ts-launch-blueprint/.github/workflows/update-contributors.yml:80`
  at pin `cb1cbcb2`). Excluded on behavior B1: `GITHUB_TOKEN` is an installation
  access token and `GET /user` is not among the endpoints available to installation
  access tokens, while the action's PAT path calls exactly that endpoint and throws
  on failure (`src/index.ts:432,439`, tag v1.3.9). It additionally fails B3
  (`GITHUB_TOKEN`-triggered events create no workflow run, so required checks never
  report) and is conditionally blocked on B2 by the repository setting "Allow GitHub
  Actions to create and approve pull requests", which defaults to *not allowed* for
  new repositories. All three citations are GitHub Docs or the action's pinned
  source, retrieved 2026-09-10. Residual uncertainty: I could not execute the failing
  configuration (see `### Validation strategy`), so the 403 is a documented-behavior
  prediction, not an observed run.
- **O3 as a fallback substitute for a PAT.** Excluded as redundant, not as broken:
  it mints another installation token, so it inherits B1's failure if passed to
  `pat:`, and it duplicates work `src/app-token.ts` already performs when `app-id`
  and `private-key` are supplied.

**The prompt's six crate fitness gates, applied per candidate before popularity.**
All three options are workflow-level patterns, so several gates have no crate to
bind to; each is stated with its reason rather than omitted.

| Gate | O1 (PAT fallback) | O2 (App only) | O3 (minted App token) |
|---|---|---|---|
| 1. License compatible with `MIT OR Apache-2.0` | **Pass** — `smorinlabs/contributors-please-action` is MIT (`license.spdx_id` MIT via `GET https://api.github.com/repos/smorinlabs/contributors-please-action`, retrieved 2026-09-10); a credential itself carries no license | **Pass** — same action, same license | **Pass** — `actions/create-github-app-token` is MIT (same endpoint, retrieved 2026-09-10) |
| 2. MSRV within `stable minus 2 minor versions…` | `inapplicable` — no Rust crate or dependency tree is added; the change is YAML plus a repository secret, compiled by nothing | `inapplicable`, same reason | `inapplicable`, same reason |
| 3. No open RustSec advisory; `unsafe` posture | `inapplicable` — RustSec indexes crates, and no crate is involved; `https://rustsec.org/packages/<name>.html` has no applicable `<name>`. Security posture examined instead: a long-lived fine-grained PAT (owner-set expiry, repo-scoped, revocable) versus a 1-hour installation token; the PAT is used only when the App is absent | `inapplicable` — no crate; posture is strictly better (no long-lived secret at all) | `inapplicable` — no crate; posture equals O2 |
| 4. Builds/tested on `ubuntu-latest, macos-latest` | Partially applicable: the bot job runs on `ubuntu-latest` only *by design* — it opens a PR rather than building the crate (`ts` pins `runs-on: ubuntu-latest` at line 60; `py` uses `${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}` at line 18). The credential mechanism is runner-independent, so a macOS runner would behave identically; Windows likewise, untested and not required. The *matrix* obligation lands on the CI workflow the bot PR must trigger, which is precisely behavior B3 | Same | Same |
| 5. Default features / async-runtime coupling | `inapplicable` (no Cargo features). Action-input analogue stated: `action.yml` declares `pat` as `required: false, default: ''` and `private-key`/`app-id` likewise, so omitting the fallback is legal and lands on the `src/index.ts:114` fail-fast (retrieved 2026-09-10) | Same analogue; `pat` simply omitted | Same |
| 6. Binary size / compile-time cost | `inapplicable` (nothing is compiled). CI-cost analogue, qualitative and measured: in the newest ts run the whole `update-contributors` job spanned 2026-09-07T12:40:41Z→12:40:53Z (~12 s) with the action step itself ~5 s (job log, retrieved 2026-09-10). None of the three options changes that materially | Same | Adds one extra step (token minting), a few seconds |

### Up-and-comers

- **`actions/create-github-app-token`** — the first-party successor to the archived
  third-party `tibdex/github-app-token` (`archived` true, `pushed_at`
  2025-07-07T19:51:41Z, 564 stars; retrieved 2026-09-10). It is the current
  direction of travel for bot credentials generally, and `release-plz` lists it as
  one of three sanctioned approaches (retrieved 2026-09-10). For *this* item it is
  redundant, because `contributors-please-action` mints its own App token; it
  becomes relevant if the template later needs the same App identity in a second
  step of the same job.
- **App-only, zero-fallback bot workflows** — a live pattern in projects that
  standardize on an organization-installed App; `release-plz`'s own repository uses
  a GitHub App for its release PRs (release-plz docs, retrieved 2026-09-10).
- **Fine-grained PATs with organization-level expiry and approval policies** — the
  direction that narrows the security gap between a PAT and an App token; relevant
  because it is what makes O1's fallback acceptable rather than merely convenient.

### Fit for this template

The credential is the *same* for all three target shapes, and that uniformity is
itself part of the argument: nothing about the shape changes what a token can do.
What differs per shape is how much the bot PR depends on behavior B3 (downstream
workflow triggering), and every shape depends on it.

- **CLI.** The template's default branch is expected to carry required checks
  (`cargo fmt --check`, `clippy`, `cargo test`) across `ubuntu-latest` and
  `macos-latest` (`docs/port/PARAMETERS.md`, `target-os-matrix`, owner-fixed
  2026-09-02). A contributors PR opened with `GITHUB_TOKEN` would create no
  `pull_request` run, so those required checks would sit at "Expected — waiting for
  status to be reported" and the PR could never merge without a manual close/reopen
  by a human — exactly the failure mode py's workflow comment already documents for
  `[skip ci]`. O1 avoids it; O2 avoids it by never producing a PR without an App.
- **Library.** Adds semver- and docs-oriented checks to the same required set, so
  the dependence on B3 only increases; the credential decision is unchanged. The
  library shape also makes the "consumer forks the template" case more common
  (crate authors adopting a scaffold), which is the population that may be unable
  to install an organization-level App — the argument for keeping a PAT fallback
  rather than going App-only.
- **Web service.** Adds the heaviest required checks (integration tests, OpenAPI
  conformance). Same conclusion, more strongly. There is no web-specific credential
  requirement: the bot job never touches the service.

Across all three, the template's *documentation* obligation is identical: one
either/or setup step ("install the App **or** set one repository secret"), which is
the honest version of the "zero extra secrets" story F061 currently records.

### Recommendation

Adopt **O1 — GitHub App credentials primary with a dedicated fine-grained PAT
fallback**, i.e. the `py-launch-blueprint` shape, in `rs-launch-blueprint`:

```yaml
- uses: smorinlabs/contributors-please-action@<sha> # v1.3.9
  with:
    app-id: ${{ secrets.CONTRIBUTORS_PLEASE_CLIENT_ID }}
    private-key: ${{ secrets.CONTRIBUTORS_PLEASE_PRIVATE_KEY }}
    pat: ${{ secrets.CONTRIBUTORS_PLEASE_PAT }}
    mode: pull-request
```

with three refinements over py's current text:

1. Document the credentials as **either/or**, not as a three-secret set. py's
   `docs/POST_INIT.md:118` (at pin `b08bccfb`) lists
   `CONTRIBUTORS_PLEASE_CLIENT_ID` + `CONTRIBUTORS_PLEASE_PRIVATE_KEY` +
   `CONTRIBUTORS_PLEASE_PAT` in a single "Required by" cell, which reads as "set all
   three". The action prefers the App whenever both App inputs are present
   (`src/index.ts:397`), so the PAT is dead weight in that configuration.
2. State explicitly in the template's repo-secrets documentation that
   `secrets.GITHUB_TOKEN` is **not** a valid value for `pat:`, with the reason
   (identity lookup, downstream triggering, the PR-creation repository setting).
   This is the one line that prevents the ts mistake from being re-derived.
3. Specify the PAT concretely: a fine-grained PAT scoped to the single repository
   with **Contents: write**, **Pull requests: write** and **Issues: write** (the
   three grants the workflow's `permissions:` block already names in both source
   repos), with an explicit expiry, and a note that a machine account is preferable
   to a maintainer's personal identity — the same advice
   `peter-evans/create-pull-request` gives ("recommends using a dedicated machine
   account rather than personal credentials", retrieved 2026-09-10).

The owner direction of 2026-09-04 and the independent evidence gathered here point
the same way; the recommendation does not rest on the direction alone. The evidence
is that the ts alternative is not merely less capable but expected to be
non-functional, and unexercised in practice.

Note the trigger cadence, the `permissions:` block shape, and the pinning style
(tag vs. SHA) are R07's, R08's and R20's decisions respectively; the snippet above
shows a SHA pin only as a placeholder and takes no position on it.

### Ranked runner-up

**O2 — App credentials only, no `pat:` input.** It wins when the owner decides that
installing the `contributors-please` GitHub App is the *only* supported way to run
the bot. Under that decision O2 is strictly better than O1: it removes the only
long-lived credential from the template's setup surface, it removes the class of
mistake where a consumer pastes a wrong token into `pat:` (the ts defect), and an
unconfigured consumer gets the clean, actionable failure
`Provide either app-id + private-key, or pat.` (`src/index.ts:114`) rather than a
403 from an identity lookup. Its cost is the consumer who cannot install an App —
a forker without organization-owner rights — for whom the workflow then has no
supported path at all and must be deleted or left permanently failing.

Second runner-up, distant: **O3**, which only becomes attractive if a future
workflow step in the same job needs the App identity independently of the action.

### Tradeoffs

**What O1 gives up versus O2 (App-only).** O1 keeps a long-lived credential in the
template's documented setup surface. A fine-grained PAT is owner-scoped and
owner-revocable but does not auto-rotate the way an installation token does (which
"will expire after 1 hour", GitHub Docs, retrieved 2026-09-10), and a public
template's consumers cannot be assumed to follow least-privilege PAT hygiene — the
prompt's MEDIUM question. This cost is accepted because the PAT is *only* used when
the App is absent, the recommended grants are three repository-scoped permissions
rather than a classic `repo`-scoped token, and the alternative is to leave
App-less consumers with no working path. The risk is bounded further by
documenting a machine account and an explicit expiry.

**What O1 gives up versus O3 (in-workflow minted App token).** Nothing material:
O3's advantage — a short-lived token — is already realized by O1's *primary* App
path, and O3 cannot serve as the fallback because a minted installation token hits
the same `GET /user` wall. O1 gives up one indirection layer that would have to be
kept pinned and updated.

**What O1 gives up versus the excluded ts shape.** The literal "zero repository
secrets" onboarding sentence. The evidence is that the sentence describes a
configuration that does not work: the fallback aborts at identity lookup, would not
trigger required checks even if it resolved, and would still need the repository's
Actions setting changed to create a PR at all. Trading a false zero-setup claim for
a true one-step setup claim is not a real cost — the prompt's LOW question about
first-run friction resolves against the ts shape once the setup step it hides is
counted. I found no adopter-feedback dataset comparing template setup guides; I
record that as an evidence gap rather than asserting a friction figure.

### Parameters

- `owns` — none. The item's `## Couplings` block lists an empty `owns:`, and this
  answer introduces no new owned parameter.
- `assumes rust-edition = 2024` (`docs/port/PARAMETERS.md`, fixed, owner-decided
  2026-09-02) — not exercised by this item; the workflow contains no Rust.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor
  release, declared as rust-version in Cargo.toml and tested in CI` — not exercised;
  no crate is added.
- `assumes license = MIT OR Apache-2.0` — satisfied; every action referenced is MIT
  (`license.spdx_id` MIT for `smorinlabs/contributors-please-action` and
  `actions/create-github-app-token`, retrieved 2026-09-10), which is compatible.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — the bot job itself runs
  on `ubuntu-latest` only, by design (it opens a PR, it does not build). The matrix
  obligation applies to the CI workflow that the bot PR must trigger, which is the
  behavior this recommendation protects.

No `CONFLICT:` lines. The recommendation requires no consumed parameter to change.

### Migration implications

File-level changes in `rs-launch-blueprint` (P03 builds these; nothing is created
by this report):

1. `.github/workflows/update-contributors.yml` — the credential block reads
   `app-id: ${{ secrets.CONTRIBUTORS_PLEASE_CLIENT_ID }}`,
   `private-key: ${{ secrets.CONTRIBUTORS_PLEASE_PRIVATE_KEY }}`,
   `pat: ${{ secrets.CONTRIBUTORS_PLEASE_PAT }}`. This is the single line the item
   decides; cadence, `permissions:` and pin style come from R07, R08 and R20.
2. The template's post-init / repo-secrets document (py's analogue is
   `docs/POST_INIT.md`, §2.1 "GitHub Actions secrets") — split the current
   single row into an either/or pair: *App path* (`CONTRIBUTORS_PLEASE_CLIENT_ID` +
   `CONTRIBUTORS_PLEASE_PRIVATE_KEY`) **or** *PAT path*
   (`CONTRIBUTORS_PLEASE_PAT`), with the fine-grained-PAT grants named
   (Contents: write, Pull requests: write, Issues: write), an expiry recommendation,
   and an explicit "do not use `secrets.GITHUB_TOKEN` here" note with the reason.
3. The template's CI documentation page (py/ts analogue:
   `docs/tools/github-actions.md`) — one sentence stating that the contributors bot
   PR must trigger the repository's CI, and that this is why the bot uses a
   dedicated credential.
4. No Cargo, Dependabot, or toolchain change. No new dependency of any kind.

Follow-on for the source repositories (a separate project, per the prompt; this
report supplies the rationale, not the edit): `ts-launch-blueprint`'s
`.github/workflows/update-contributors.yml:80` should change from
`secrets.GITHUB_TOKEN` to `secrets.CONTRIBUTORS_PLEASE_PAT`, or drop the `pat:`
input entirely; and `py-launch-blueprint`'s `docs/POST_INIT.md:118` should present
its three contributors secrets as either/or rather than as one required set.

### Validation strategy

Every command below is **proposed, not executed**. This is a research programme and
the Rust template does not exist yet; I created no repository, no secret, no App
installation, and no pull request, and I ran none of these.

*Proposed acceptance check A — the recommended configuration works with no App.*

```bash
# In a sandbox repository created from the template, with the App NOT installed
# and CONTRIBUTORS_PLEASE_PAT set to a fine-grained PAT
# (Contents: write, Pull requests: write, Issues: write):
gh workflow run update-contributors.yml -R <owner>/<sandbox>
gh run list -R <owner>/<sandbox> --workflow update-contributors.yml --limit 1
```

Expected: the run concludes `success`; the action's step summary reports
`token-source | pat`; outputs `pr-opened=true` with a non-empty `pr-url`; and

```bash
gh pr checks <pr-number> -R <owner>/<sandbox>
```

lists the template's CI checks with real conclusions rather than "Expected —
waiting for status to be reported". Passing A demonstrates B1, B2, B3 and B4's
fallback branch together.

*Proposed negative check B — the excluded configuration fails, and fails where
predicted.* Same sandbox, `pat:` temporarily set to `${{ secrets.GITHUB_TOKEN }}`.
Expected: the run concludes `failure` with `GitHub token identity lookup failed:
403` in the step log (predicted from `src/index.ts:432,439` plus the
installation-token endpoint list). This is the single check that would convert the
central claim of this report from documented-behavior prediction to observed fact;
it is the one I most want run before P03 freezes the workflow.

*Proposed check C — the unconfigured case fails cleanly.* Same sandbox, no App and
no `CONTRIBUTORS_PLEASE_PAT`. Expected: `failure` with
`Provide either app-id + private-key, or pat.` (`src/index.ts:114`), which is the
B5 acceptance criterion.

*Already executed, read-only, results reported above (no mutation):* the repository
secret listings for both source repos, the ts workflow run list and the newest job
log, the action's tag→SHA resolution, and the source read at that SHA.

### Confidence & re-verify trigger

**Confidence: high** on the recommendation (O1), for three independent reasons that
would each have to be wrong together: the owner direction of 2026-09-04, the
documented incapability of `GITHUB_TOKEN` on behaviors B1 and B3, and the action's
own e2e suite testing the PAT path only with a real PAT.

**Confidence: medium-high** on the specific *mechanism* of the ts failure (a 403 at
`GET /user`). It is derived from GitHub's endpoint list plus the action's source at
the pinned commit, not from an observed failing run — check B above closes it. Even
if that mechanism were wrong, behavior B3 alone excludes the ts shape, so the
recommendation does not depend on it.

**Confidence: low** on the LOW question about adopter-measured setup friction: I
found no dataset comparing first-run friction across template repositories and did
not manufacture one.

**Re-verify triggers.**

1. `smorinlabs/contributors-please-action` changes how it resolves the PAT identity
   — specifically if `lookupPatIdentity` stops calling `GET /user` or gains an
   installation-token branch. Watch `src/index.ts` and the CHANGELOG on any version
   bump past v1.3.9.
2. GitHub adds `GET /user` to the endpoints available to installation access tokens,
   or changes the rule that `GITHUB_TOKEN`-triggered events create no workflow run.
3. The default of "Allow GitHub Actions to create and approve pull requests" changes
   for newly created repositories.
4. The owner decides the App is the only supported installation path — at which
   point O2 becomes the answer without further research.
5. The template's default branch stops requiring status checks (removing the
   dependence on B3), which would reopen the trade-off.

### Sources

1. GitHub Docs — `GITHUB_TOKEN` concept page: automatic per-job creation, and
   "Events triggered by the `GITHUB_TOKEN` will not create a new workflow run, with
   the following exceptions: `workflow_dispatch` and `repository_dispatch` events
   always create workflow runs."
   `https://docs.github.com/en/actions/concepts/security/github_token` (retrieved
   2026-09-10).
2. GitHub Docs — endpoints available to GitHub App installation access tokens;
   "Your GitHub App can make requests to the following REST endpoints with an
   installation access token"; the `users` section lists `GET /user/{account_id}`,
   `GET /users`, `GET /users/{username}` and related endpoints, and does **not**
   list `GET /user`.
   `https://docs.github.com/en/rest/authentication/endpoints-available-for-github-app-installation-access-tokens?apiVersion=2022-11-28`
   (fetched with `curl` and text-extracted, 2026-09-10).
3. GitHub Docs — authenticating as a GitHub App installation: installation tokens
   are "server-to-server" and "will expire after 1 hour".
   `https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation`
   (retrieved 2026-09-10).
4. GitHub Docs — managing GitHub Actions settings for a repository: "By default,
   when you create a new repository in your personal account, workflows are not
   allowed to create or approve pull requests"; the setting controls "whether
   `GITHUB_TOKEN` can create and approve pull requests".
   `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository`
   (retrieved 2026-09-10).
5. `peter-evans/create-pull-request` — concepts and guidelines: "Pull requests
   created by the action using the default `GITHUB_TOKEN` cannot trigger other
   workflows"; a PAT is "the standard workaround and recommended by GitHub"; App
   tokens have "fine-grained permissions and are scoped to only repositories where
   the App is installed".
   `https://github.com/peter-evans/create-pull-request/blob/main/docs/concepts-guidelines.md`
   (retrieved 2026-09-10). Figures: `GET https://api.github.com/repos/peter-evans/create-pull-request`
   → 2847 stars, `archived` false, `pushed_at` 2026-09-03T00:42:16Z, MIT;
   `GET https://api.github.com/search/issues?q=repo:peter-evans/create-pull-request+is:issue+is:open`
   → `total_count` 18 (both retrieved 2026-09-10).
6. `release-plz` — GitHub token documentation (Rust-native authority): "GitHub
   Actions using the default `GITHUB_TOKEN` cannot trigger other workflow runs";
   "Workflows acting as checks on pull requests opened by GitHub Actions with the
   default GitHub token won't run"; recommends a PAT, a GitHub App, or
   `actions/create-github-app-token`. `https://release-plz.dev/docs/github/token`
   (retrieved 2026-09-10).
7. `smorinlabs/contributors-please-action` — README (App-over-PAT precedence; the
   `mode: pull-request` description; the `[skip ci]`/required-checks warning),
   `action.yml` (`pat`: "Personal access token fallback. Used when App credentials
   are absent.", `required: false`, `default: ''`; outputs include `token-source`,
   `pr-opened`, `pr-url`), and `src/index.ts` at tag **v1.3.9** =
   `3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1` (lines 114, 397, 426, 432, 439) and
   `src/app-token.ts:57`. Tag→SHA via
   `GET https://api.github.com/repos/smorinlabs/contributors-please-action/git/ref/tags/v1.3.9`.
   Figures: `GET https://api.github.com/repos/smorinlabs/contributors-please-action`
   → 0 stars, `archived` false, `pushed_at` 2026-09-01T22:51:20Z, MIT;
   open issues `total_count` 1. All retrieved 2026-09-10.
8. `smorinlabs/contributors-please-action` — `.github/workflows/e2e.yml` lines 107,
   140, 234, 294 (`secrets.CONTRIBUTORS_PLEASE_PAT`) and 370
   (`secrets.GHE_CONTRIBUTORS_PLEASE_PAT`); no test passes `secrets.GITHUB_TOKEN`
   to `pat:` (repository clone at HEAD `cbb1fd47`, retrieved 2026-09-10).
9. `py-launch-blueprint` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`:
   `.github/workflows/update-contributors.yml` lines 11 (`permissions:`), 18
   (`runs-on`), 27 (`uses: …@v1.3.9`), 32 (`app-id`), 34
   (`pat: ${{ secrets.CONTRIBUTORS_PLEASE_PAT }}`), and the `commit-message`
   comment about `[skip ci]` blocking the bot PR behind required checks;
   `docs/POST_INIT.md:118` (secrets table) and 122-123 ("`GITHUB_TOKEN` is provided
   automatically — no setup"). Read 2026-09-10.
10. `ts-launch-blueprint` at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`:
    `.github/workflows/update-contributors.yml` lines 51 (cron), 56
    (`permissions: {}`), 61-64 (job permissions), 74
    (`uses: …@3c6dbff9…  # v1.3.9`), 78 (`app-id`), 80 (`pat: ${{ secrets.GITHUB_TOKEN }}`), plus
    the header comment claiming "`pat` uses the workflow's own GITHUB_TOKEN so the
    template works out of the box with zero extra setup";
    `docs/tasks/using-ci-cd.md:68-70`; `docs/tools/github-actions.md:55,66,75`.
    Read 2026-09-10.
11. Live repository state (authenticated `gh api`, retrieved 2026-09-10):
    `repos/smorinlabs/ts-launch-blueprint/actions/secrets` →
    CONTRIBUTORS_PLEASE_CLIENT_ID, CONTRIBUTORS_PLEASE_PRIVATE_KEY,
    RELEASE_PLEASE_CLIENT_ID, RELEASE_PLEASE_PRIVATE_KEY;
    `repos/smorinlabs/py-launch-blueprint/actions/secrets` → those plus
    CLAUDE_CODE_OAUTH_TOKEN, CODECOV_TOKEN, RUNNER_MACOS, RUNNER_UBUNTU,
    RUNNER_WINDOWS, SAFETY_API_KEY. `CONTRIBUTORS_PLEASE_PAT` present in neither.
    `repos/smorinlabs/ts-launch-blueprint/actions/workflows/310387832/runs` →
    9 runs, six most recent `success` (2026-09-07 … 2026-08-03), three `failure`
    (2026-07-27, 2026-07-20, 2026-07-13).
    `repos/smorinlabs/ts-launch-blueprint/actions/jobs/101745643227/logs` → the
    2026-09-07 run's step inputs, showing `app-id`, `private-key` and `pat` all
    supplied and the job spanning 12:40:41Z→12:40:53Z.
12. `actions/create-github-app-token` figures:
    `GET https://api.github.com/repos/actions/create-github-app-token` → 885 stars,
    `archived` false, `pushed_at` 2026-08-04T01:40:22Z, MIT; open issues
    `total_count` 10. `tibdex/github-app-token` → `archived` true, `pushed_at`
    2025-07-07T19:51:41Z, 564 stars, open issues 6. Both retrieved 2026-09-10.
13. Programme documents read for context: `docs/port/COMMONALITY.md` rows F026,
    F060, F061, F209; `docs/port/DIVERGENCE-ANALYSIS.md:105,258`;
    `docs/port/OWNER-REVIEW.md:63`; `docs/port/PARAMETERS.md` (via
    `inputs/parameters.json`). Read 2026-09-10.

**Method notes.** Endpoints queried: `https://api.github.com/repos/<o>/<r>` and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for
`smorinlabs/contributors-please-action`, `actions/create-github-app-token`,
`peter-evans/create-pull-request` and `tibdex/github-app-token`;
`https://api.github.com/repos/smorinlabs/contributors-please-action/git/ref/tags/v1.3.9`;
`repos/<o>/<r>/actions/secrets`, `/actions/workflows`,
`/actions/workflows/<id>/runs`, `/actions/runs/<id>/jobs` and
`/actions/jobs/<id>/logs` for both source repositories; GitHub Docs and
release-plz pages by URL; and `raw.githubusercontent.com` plus a shallow clone for
the action's README, `action.yml`, `src/` and `.github/workflows/e2e.yml`. The
unauthenticated `curl` to `api.github.com` hit "API rate limit exceeded" at
2026-09-10T14:53:21Z, so every GitHub REST figure above was re-taken with the
authenticated `gh api` client; the values are from that authenticated retrieval.
**crates.io was not queried** (`https://crates.io/api/v1/crates/<name>`,
`/versions`) and **RustSec was not queried** (`https://rustsec.org/packages/<name>.html`):
this item adds no crate, so those endpoints have no applicable `<name>`; the
corresponding gate rows above say `inapplicable` with that reason rather than
omitting them. **Could not verify:** (a) the predicted `403` from
`GET /user` with a `GITHUB_TOKEN` — I did not execute the failing configuration,
because doing so would require creating a repository, a secret and a pull request,
which this research programme forbids; it is a documented-behavior prediction from
source 2 plus the action's pinned source; (b) the cause of the three `failure`
runs of the ts workflow in July 2026 — the run-level logs endpoint returned a
22-byte stub (logs expired), so those failures are recorded as unexplained and are
*not* used as evidence anywhere above; (c) the ts run's `token-source` output value
directly — the visible job log does not print the step summary table, so the App
path is inferred from `src/index.ts:397` (App branch taken whenever `app-id` and
`private-key` are both non-empty) plus the log line showing both inputs supplied;
(d) any adopter-feedback dataset on template setup friction (the prompt's LOW
question) — none found, recorded as an evidence gap.
