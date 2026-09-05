# R47 contributors-recipe-mode — decision (revision 1, 2026-09-05)

Item R47 (`contributors-recipe-mode`, kind `pattern`, Light tier, owns nothing). Run `research/runs/R47/2026-09-05T160304Z-99a3dd6456c0`. Synthesizer: actor `synth-fable-2026-09-05T160304Z-99a3dd6456c0`, model `claude-fable-5-1` (family anthropic), a fresh context that produced none of the raw reports. Inputs: `inputs/prompt.md`, `raw/codex.md`, `raw/evidence-terra.md`, `docs/port/PARAMETERS.md`. No prerequisite decisions (`inputs/prerequisites.json` is `{}`; the item consumes no parameter).

## Decision

**The local Justfile recipe's steady-state body is the ledger-render subcommand `contributors-please render --config-file .contributors.yml` (ts's pattern), which reproduces the projection stage of the CI bot's `contributors-please-action` `mode: pull-request`; it is wrapped in a file-existence guard that runs the from-scratch bootstrap `contributors-please init --non-interactive --owner <owner> --repo <repo> --config-file .contributors.yml` (py's pattern) exactly once, when `.contributors.jsonl` is absent.** Tool: `contributors-please` 1.4.3 (npm, `latest`, MIT, `engines.node >=24`), the same package the settled CI action embeds. Unconditional `init` (py) and unconditional `render` (ts) are the runner-ups; neither is adopted unchanged. The runner spelling (`npx`, `pnpm dlx`, `bun x`) and its version pin are R42's `package-manager-invocation` parameter, not decided here.

Ledger row this settles (`docs/port/COMMONALITY.md:214`):

| Row | Settled value |
|---|---|
| F210 local Justfile recipe's subcommand vs. the CI bot's action mode | `render` when `.contributors.jsonl` exists, else `init --non-interactive`; both against `.contributors.yml`, the committed `.contributors.jsonl`, and the marked `CONTRIBUTORS.md` — the same three files the action reads (`config-file`, `state-file`, `output-file`) |

No baseline row is challenged: F060 (the CI workflow, `COMMON → REUSE`) and F209 (the config schema, `COMMON → REUSE`) are consumed as they stand. The Codex raw's `BASELINE-REVIEW: F210 …` line targets this item's own `DIVERGENT` row, not a `REUSE`/`ADOPT` baseline, so it is recorded below as a refinement of the D-024(9) rationale rather than forwarded for adjudication.

### Principles and implementation

**Shared requirement and agreement level.** Contributor recognition has one implementation: the local recipe and the CI bot run the same engine with the same rendering rules over one committed configuration (`.contributors.yml`) and one committed machine-readable ledger (`.contributors.jsonl`), and the Markdown projection (`CONTRIBUTORS.md`) is reproducible from those committed files without network access. The agreement level is **architectural pattern**: `docs/port/DIVERGENCE-ANALYSIS.md:175` classes F210 as class A (setting drift, `harmonize: yes`) and `docs/port/OWNER-REVIEW.md:88` records `accept`; D-024(9) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md:317-320`) is the source of the "single implementation" principle. What must agree across py, ts and rs is the subcommand semantics (project from committed state; discover only to bootstrap); what may vary is the package runner, Justfile syntax and provisioning.

**Refinement of the D-024(9) rationale (from `raw/codex.md`, verified against source).** D-024(9) says ts's `render` "reproduces the same ledger-to-Markdown step the CI action performs". That is true of the projection stage only. The action's `pull-request` mode calls `Contributors.openPullRequest()`, which first runs `Contributors.run()` — shallow-checkout check, `GET /repos/{owner}/{repo}/contributors`, `git log` discovery, identity join, path classification, merge into the ledger, render — and then commits, pushes, labels and opens the PR (`contributors-please/src/engine/contributors.ts:129-236,278-290`; `contributors-please-action/src/index.ts:531-551`). The standalone `render` subcommand starts after discovery and merge: it reads the config, reads the state file, reads the output file when `in_place` is set, and writes the projection (`contributors-please/src/cli.ts:51-77`). So `render` is the correct single implementation of the projection, not a lifecycle equivalent of the whole mode. Two consequences follow. (1) `render` has no bootstrap path: `readStateFile` is a bare `readFile` (`src/engine/state.ts:45-48`), and the engine's own bootstrap only exists behind `bootstrap: true`, which `init` sets and the action exposes as its `bootstrap` input (`src/cli.ts:104-107`; `action.yml` `bootstrap`). (2) ts's own pinned checkout demonstrates the gap: `~/c/ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` has `CONTRIBUTORS.md` but no `.contributors.jsonl`, so its `pnpm dlx contributors-please render` recipe exits 1 with `ENOENT` there (reproduced as case 08 below); ts's CI survives only because its workflow passes `bootstrap: 'true'` (`.github/workflows/update-contributors.yml:74-86`).

**Essential behaviors** (any candidate recipe must do all five): (1) with a committed ledger, produce the projection from the committed files alone — no GitHub call, no credential, no ledger mutation; (2) with no ledger, bootstrap it through the engine's discovery path with explicit owner and repository, then stop so the result can be reviewed and committed; (3) fail non-zero, writing nothing, when bootstrap inputs are missing, the API fails, or history is shallow; (4) produce byte-identical output on repeated runs over identical inputs; (5) read the same three files, by the same names, that the action reads.

**Observable acceptance criteria**, each mapped to an executed case (`review/evidence/contributors-please-1.4.3-recipe-acceptance.log`):

| Criterion | Case | Observed |
|---|---|---|
| Committed ledger + marked `CONTRIBUTORS.md`: recipe exits 0 and writes the same bytes as a direct engine `render` | 02, 02b | 0; byte-identical; ledger sha256 unchanged; 0 requests to the (fake) GitHub API |
| Repeat run is deterministic and touches nothing else | 03 | byte-identical; `git status` shows only ` M CONTRIBUTORS.md` |
| No ledger: recipe selects `init`, creates `.contributors.jsonl` with the discovered record and updates the projection | 04 | 0; `initialized 1 contributor`; record `alice` `commits=2` `categories=["code","docs"]` `source=commit`; exactly one `GET /api/v3/repos/smorinlabs/rs-launch-blueprint/contributors?per_page=100` |
| Once the ledger exists the guard flips to `render` with no discovery | 05 | `rendered 1 contributor`; request count unchanged; ledger unchanged |
| Missing owner fails loudly with nothing written | 06 | 1; `Provide --owner and --repo, or set GITHUB_REPOSITORY.`; no ledger; output untouched |
| API failure during bootstrap fails loudly with no fabricated ledger | 07 | 1; `GitHub API request failed: 500`; the failing call was made (request count +1); no ledger |
| Direct `render` with no ledger is the Codex negative control | 08 | 1; `ENOENT … .contributors.jsonl` |
| `in_place` needs the marked output file to exist | 09 | 1; `ENOENT … CONTRIBUTORS.md` |
| Shallow history cannot bootstrap | 10 | 1; `contributors-please requires a full checkout. Set actions/checkout fetch-depth: 0.`; no ledger |
| The body is runner-agnostic | 11 | `just --set contributors_runner "bun x contributors-please@1.4.3"` exits 0 with byte-identical output and no runner artifacts in the repository |

**Architecture alternatives compared** (before any tool choice, per owner amendment A5):

- (A) *Unconditional `init --non-interactive`* — py `Justfile:461-462` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`. Every local run performs remote discovery and rewrites the ledger; it needs network access and, for private repositories or beyond the unauthenticated rate limit, a token; a routine "refresh the Markdown" becomes a state mutation that must be reviewed. It is the only candidate that covers the first run.
- (B) *Unconditional `render`* — ts `Justfile:243-244` at `cb1cbcb`. Offline, deterministic, credential-free — but unusable on a fresh template or any clone without a committed ledger (case 08), which is exactly the state `rs-launch-blueprint` starts in.
- (C) *Guarded bootstrap plus render* — (B) as the steady state with (A) confined to the missing-ledger branch. Preserves every essential behavior; the only added cost is a four-line conditional. Selected.
- (D) *A Rust-native contributor-ledger tool* — would remove the Node runtime but must reimplement identity join, path classification, the `.contributors.jsonl` schema (F209, `REUSE`) and stay byte-compatible with the action's projection. Neither raw found a maintained candidate (`https://crates.io/search?q=contributors`, 2026-09-05; the evidence check could not rerun the search, HTTP 403). Excluded for lack of a candidate, not by popularity.
- (E) *`git-cliff`* — a maintained Rust changelog generator (`MIT OR Apache-2.0`), excluded by capability: it renders commit history into a changelog and has no contributor ledger, identity join or path classification (`https://git-cliff.org/docs/`, 2026-09-05).

**Why (C) preserves each principle.** Single implementation: both branches call the package the action embeds (the action's lockfile tracks `contributors-please` 1.4.3, verified by the evidence check), and the steady-state branch is the action's own projection stage. Reproducibility: case 03. Explicit bootstrap: case 04, with the same owner/repository/config inputs the action derives from `GITHUB_REPOSITORY` and its `config-file` input. Loud failure: cases 06, 07, 10. Same files: the recipe names `.contributors.yml`, `.contributors.jsonl` and, through the config, `CONTRIBUTORS.md` — the ts and py workflows pass those same three paths to the action.

**Fitness gates for the pattern.** Gate 1 license: pass — `contributors-please@1.4.3` is MIT (`https://registry.npmjs.org/contributors-please`, 2026-09-05; verified by the evidence check), compatible with the fixed `MIT OR Apache-2.0`. Gates 2, 3, 5 and 6 (crate MSRV, RustSec advisory and `unsafe` posture, Cargo features and async coupling, binary size and compile time): `inapplicable` — the tool is a developer-machine and CI process, never a Cargo dependency, so nothing enters the template's dependency graph, MSRV, binary or compile time; the runtime gate that replaces them is Node `>=24`, which the action declares as `runs.using: node24`. Gate 4 OS matrix: the action runs on `ubuntu-latest` in both source repos and the package is pure JavaScript; executed here on macOS 26.4 arm64 only; Linux is inferred from the action's runtime and from the CI evidence in both sources; local Node provisioning on both runners is R42's. Crate figures (downloads, release, stars, open issues, responsiveness, adopters) are `inapplicable` to an npm-package recipe pattern; the figures that matter — `latest` = 1.4.3 published 2026-06-17, MIT, Node `>=24`, action 1.3.9 with `node24`, both repositories pushed 2026-09-01 — were checked by the evidence check (`raw/evidence-terra.md`, verdict sound, 13 ok / 0 wrong / 2 unverifiable). Maintenance state: **active** (commits 2026-09-01 in both repositories; local clones `~/c/contributors-please` at `c9b7b0754b0654630305af6c39142fcfdf126b51` and `~/c/contributors-please-action` at `cbb1fd47b8ef9781c1557230034c37dc51c15e18`).

**Reference implementations.** ts's `render` recipe and py's `init` recipe (pinned above); ts's workflow with `mode: pull-request` and `bootstrap: 'true'`; the package README's first-run flow (`npx contributors-please@1 init --non-interactive --owner OWNER --repo REPO --config-file .contributors.yml`, `contributors-please/README.md:18-27`) and the action README's identical local bootstrap block (`contributors-please-action/README.md:104-110`); the engine's own error text, which prescribes exactly this split — `No state file found at .contributors.jsonl. Run npx contributors-please init locally to bootstrap, then commit the result.` (`src/engine/contributors.ts:140-142`). No surveyed repository practices the guard itself; the fixture in `review/empirical/` is the executed reference implementation.

**Selected design — the recipe the template carries** (the fixture copy in `review/empirical/Justfile`, executed by every case):

```just
contributors_runner := "npx --yes contributors-please@1.4.3"   # R42's parameter; pinned here for reproducible evidence
contributors_owner := "smorinlabs"
repo_name := "rs-launch-blueprint"
contributors_config := ".contributors.yml"
contributors_state := ".contributors.jsonl"

alias contributors := contributors-update

# Render CONTRIBUTORS.md from the committed ledger; bootstrap the ledger on first run
contributors-update:
    #!/usr/bin/env sh
    set -eu
    if test -f "{{contributors_state}}"; then
        {{contributors_runner}} render --config-file "{{contributors_config}}"
    else
        # GITHUB_SERVER_URL is the action's own fallback (input -> env -> github.com);
        # unset locally means no flag, i.e. https://github.com.
        {{contributors_runner}} init --non-interactive \
            --owner "{{contributors_owner}}" --repo "{{repo_name}}" \
            --config-file "{{contributors_config}}" \
            ${GITHUB_SERVER_URL:+--github-server-url "$GITHUB_SERVER_URL"}
    fi
```

Why each non-obvious choice: the guard tests the state-file path rather than asking the engine, because `render` has no "bootstrap if missing" mode (case 08) and the path is already duplicated by both workflows' `state-file:` input. `--config-file` is passed explicitly, matching the action's `config-file` input, although `.contributors.yml` is also the CLI default. The `GITHUB_SERVER_URL` passthrough is a departure from both precedent recipes: it mirrors the action's own resolution chain — input `github-server-url`, then `env.GITHUB_SERVER_URL`, then `https://github.com` (`contributors-please-action/src/index.ts:99-102`) — so a GitHub Enterprise instance is handled the way the action handles it, and it costs nothing on github.com (the variable is unset locally; the `${VAR:+…}` form expands to no argument, verified). It is also what lets the empirical check drive the bootstrap branch against a local stand-in server instead of the live API. The recipe carries no `@` prefix: on `just 1.57.0` a `@` on a shebang recipe echoes the whole script body rather than silencing it (verified in this run's pre-check). The recipe name and alias follow the sources (`contributors` in ts; `alias contributors := update-contributors` in py); naming is F178 territory, not this item's.

**Preconditions the template must satisfy** (each executed): `CONTRIBUTORS.md` is committed with both in-place markers, because with `in_place: true` both `render` and `init` read the output file first (case 09; `src/cli.ts:61-65,212-227`) — both sources already commit it. `.contributors.jsonl` is committed after the first bootstrap, otherwise every clone re-bootstraps, needs GitHub access, and a shallow CI checkout cannot bootstrap at all (case 10). The first bootstrap runs in a full clone with GitHub reachable; a token is optional for public repositories (`--token` or `GITHUB_TOKEN`) and the unauthenticated rate limit applies.

**Answers to the prompt's remaining questions.** MEDIUM — yes, `init` serves a purpose `render` cannot: first-time seeding of `.contributors.jsonl` from GitHub and git history (cases 04 versus 08). An intentionally empty committed ledger would let `render` run but would render nothing and discover nobody, so it is not a substitute. LOW — the `@1` major pin versus an exact pin belongs to R42; this fixture pins `@1.4.3` so the evidence is reproducible, and case 11 shows the body is indifferent to the runner. HIGH (subcommands) — 1.4.3 exposes `validate`, `render`, `init` and `--version` (`src/cli.ts`); the built CLI's usage string omits `init` (`src/cli.ts:131-134`) but the README, source and tests carry it. HIGH (Rust-native equivalent) — none found; the recipe shells out to a Node `>=24` runner either way.

**Cross-repo rationale** (follow-on project; no py or ts file is changed here). py: replace unconditional `init` with the guard — its current recipe performs remote discovery and rewrites the ledger on every local run, where a committed-ledger projection suffices. ts: add the guard — its recipe fails on its own pinned checkout (no committed `.contributors.jsonl` at `cb1cbcb`), and its CI-side `bootstrap: 'true'` masks that locally. Both keep the config and ledger unchanged (F209).

**Performance.** Workload: one local invocation per contributor update. `render` is offline and linear in ledger records (one file read, one write); `init` is bounded by one paginated REST call to `/contributors` plus a `git log --no-merges --name-only` over the full history. No throughput figure was measured or claimed; the recipe is not selected on speed.

**Fit per surface.** CLI: the recipe is developer-facing repository furniture; a short external command with an offline steady state fits a Rust CLI repository that otherwise needs no Node at runtime. Library: nothing enters the published crate's dependency tree, docs.rs build or MSRV; `package.json` and `node_modules` never appear (`npx`/`bun x` fetch into their own caches — case 11's `git status` is clean). Web service: no request path touches contributor data; discovery stays an explicit maintenance operation in a developer or CI context.

**Validation that remains planned, not executed.** The same runner on `ubuntu-latest` (this run exercised macOS 26.4 arm64 only). A live bootstrap against a real GitHub repository with the org's credentials. Action parity — the action's `pull-request` projection bytes compared with a local `render` from the resulting committed ledger — which needs a live repository and the App secrets. The `pnpm dlx` spelling (pnpm is not installed on this host; `npx` and `bun x` were executed).

re-verify: 2027-03-01, or earlier when the npm `latest` tag moves past 1.4.3, the package raises its Node engine, the action changes its embedded engine or `mode`/`bootstrap` semantics, `render` gains a bootstrap path, R42 selects a runner unavailable on either runner, or the template starts shipping a pre-seeded ledger

## Parameters

The prompt's `- owns:` line is empty; this item owns no parameter.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

Consumed parameters: none (`- consumes:` is empty in the prompt). Neither the raw report nor the evidence check raised a `CONFLICT:` line and none is raised here. Note for R42 (`package-manager-invocation`): the recipe requires a runner that executes `contributors-please` under Node `>=24` on both runners; `npx --yes contributors-please@1.4.3` and `bun x contributors-please@1.4.3` both executed here with identical output (case 11); `pnpm dlx` was not exercised.

## Empirical check

Toolchain: `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`; `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)` — recorded per contract, though no Rust code runs in this check; exercised: `node v26.5.0`, `npx 12.0.1`, `just 1.57.0`, `git version 2.50.1 (Apple Git-155)`, `bun 1.4.0`, `contributors-please` 1.4.3; OS `Darwin 25.4.0 arm64`, macOS 26.4 (build 25E246). Executed by the synthesizer on 2026-09-05 (run start `2026-09-05T16:34:05Z`).

Working directory: `research/runs/R47/2026-09-05T160304Z-99a3dd6456c0/review/empirical` (fixture: `Justfile`, `.contributors.yml` — ts's evidenced-common key set —, a marked `CONTRIBUTORS.md`, `seed/.contributors.jsonl` with one human and one `[bot]` record, `fake-github.mjs`, `run-checks.sh`; `.work/` is git-ignored and recreated by the runner).

Command: `bash run-checks.sh` — exit status **0**. Full output: `review/evidence/contributors-please-1.4.3-recipe-acceptance.log`. Summary line observed: `summary: PASS=51 FAIL=0` then `RESULT: PASS`. The runner needs npm-registry access or a warm `npx` cache (and `bun`'s cache for case 11) and no GitHub access: `fake-github.mjs` listens on `127.0.0.1:47470` and serves the one endpoint `init` calls, `GET /api/v3/repos/<owner>/<repo>/contributors?per_page=100` (the `/api/v3` prefix is what `GitHubClient.deriveUrls` derives for a non-github.com server URL), logging every non-control request so the render cases can assert zero calls; `POST /__fail/500` drives case 07. The runner starts it, polls readiness (bounded, 40 × 0.25 s), and kills it on exit. Each case builds a throwaway repository with two commits by `alice@users.noreply.127.0.0.1:47470` (the no-reply domain the engine derives from that server URL, port included), one touching `src/lib.rs` and one `docs/guide.md`.

Observed per case (recipe = `just contributors-update` in the throwaway repository; `$RUNNER` = `npx --yes contributors-please@1.4.3`):

| Case | Scenario | Observed |
|---|---|---|
| 01 | `$RUNNER --version` | 0; `1.4.3` |
| 02 | committed seed ledger + marked output; recipe | 0; `contributors-please rendered 1 contributor`; line `- [Alice Example](https://github.com/alice) - Code Contributor (2 commits)`; `dependabot[bot]` filtered; ledger sha256 `57bf136e…` unchanged; 0 API requests |
| 02b | direct `$RUNNER render --config-file .contributors.yml` in a copy | 0; byte-identical to the recipe's output; `git status --porcelain` of the recipe repo is ` M CONTRIBUTORS.md` only |
| 03 | recipe again | 0; byte-identical; ledger unchanged; 0 API requests |
| 04 | no ledger; `GITHUB_SERVER_URL=http://127.0.0.1:47470` recipe | 0; argv logged by npm: `init --non-interactive --owner smorinlabs --repo rs-launch-blueprint --config-file .contributors.yml --github-server-url http://127.0.0.1:47470`; `contributors-please initialized 1 contributor`; ledger `{"login":"alice","name":"alice","profile":"http://127.0.0.1:47470/alice",…,"source":"commit","pinned":false,"categories":["code","docs"],"title":"Documentation Contributor","commits":2,"first_seen":"2026-09-05","last_updated":"2026-09-05"}`; rendered `- [alice](http://127.0.0.1:47470/alice) - Documentation Contributor (2 commits)`; exactly 1 request, `GET /api/v3/repos/smorinlabs/rs-launch-blueprint/contributors?per_page=100`; `git status` = ` M CONTRIBUTORS.md` + `?? .contributors.jsonl` |
| 05 | same repository, recipe again | 0; `rendered 1 contributor`; output byte-identical; ledger sha256 unchanged; request count still 1 |
| 06 | no ledger; `just --set contributors_owner "" …` | 1; `Provide --owner and --repo, or set GITHUB_REPOSITORY.`; no ledger; output untouched; request count unchanged |
| 07 | no ledger; fake API answers 500 | 1; `GitHub API request failed: 500`; request count +1 (the call was made); no ledger; output untouched |
| 08 | no ledger; direct `$RUNNER render` | 1; `ENOENT: no such file or directory, open '…/.contributors.jsonl'` |
| 09 | seed ledger, `CONTRIBUTORS.md` removed; recipe | 1; `ENOENT: no such file or directory, open '…/CONTRIBUTORS.md'` |
| 10 | `git clone --depth 1` of the case-04 repository (ledger never committed there); recipe | shallow = `true`; 1; `contributors-please requires a full checkout. Set actions/checkout fetch-depth: 0.`; no ledger |
| 11 | case-02 repository; `just --set contributors_runner "bun x contributors-please@1.4.3" contributors-update` | 0; output byte-identical to the `npx` run; request count unchanged; `git status` = ` M CONTRIBUTORS.md` only |

Two observations explained from source rather than asserted: the case-04 display name is `alice` because `listContributors` sets `name: row.login` (`src/engine/github.ts:110-116`) — the REST `/contributors` rows carry no display name — and the title is `Documentation Contributor` because the config's default `multi_category_resolution` is `priority` (`src/engine/config.ts:98`), which takes the first configured category in config order among those matched (`src/engine/classifiers/path.ts:50-66`); ts's config lists `docs` before the `code` default.

## Engines

- codex `raw/codex.md` — actor `research-codex-2026-09-05T160304Z-99a3dd6456c0`, model `gpt-5.6-luna` via `codex-cli-0.153.2` (family openai), sha256 `e9c3dc411ff95aaebc09a201a7816dccec152a9b5da2f2dd9587fd4ec8dc176d`; shape check passed; recommends `render` as the steady-state subcommand with a missing-ledger `init --non-interactive` branch, runner deferred to R42; executed `npx --yes contributors-please@1.4.3 --version` and a missing-ledger `render` negative control in a fresh ts checkout (exit 1, `ENOENT`).
- evidence check terra `raw/evidence-terra.md` — actor `evidence-terra-2026-09-05T160304Z-99a3dd6456c0`, model `gpt-5.6-terra` via `codex-cli-0.153.2` (family openai), sha256 `77600b697983e079f572741e77dc6e4be95697891b9a385cf984f16be1c755d0`; verdict **sound** — 13 ok, 0 wrong, 2 unverifiable (the bounded crates.io absence search and the GitHub repository endpoint both returned HTTP 403 to the checker).
- Light tier (`research/EXECUTION.json` R47: `engines: [codex]`, `evidence_checks: [terra]`): one research engine plus a fresh evidence check is the complete required input; no second engine is required and none was run.

Disagreements between engines: none — a single engine reported, and the evidence check contradicted none of its checked figures, gates or references. The synthesis adopts the Codex recommendation and extends it where reading the source and executing the fixture found more than the raw stated:

| # | Topic | Codex raw | Settled by | Outcome |
|---|---|---|---|---|
| 1 | `render`'s second precondition | Not stated | `src/cli.ts:61-65,212-227` read `CONTRIBUTORS.md` when `in_place` is set; case 09 | The template must commit the marked output file; added to acceptance criteria and preconditions |
| 2 | `BASELINE-REVIEW: F210 …` line | Raised as a baseline finding | F210 is this item's own `DIVERGENT` row (`COMMONALITY.md:214`), not a `REUSE`/`ADOPT` baseline | Recorded as a refinement of the D-024(9) rationale; F060 and F209 stand unchallenged |
| 3 | ts's recipe on a fresh checkout | Reproduced in a fresh clone | Local pinned checkout `~/c/ts-launch-blueprint` at `cb1cbcb` has no `.contributors.jsonl`; case 08 | Corroborated with a second, local reproduction |
| 4 | Server URL handling in the bootstrap branch | Not addressed | Action resolves `github-server-url` input → `GITHUB_SERVER_URL` → `https://github.com` (`src/index.ts:99-102`) | Recipe passes `--github-server-url` only when `GITHUB_SERVER_URL` is set; a stated departure from both precedents |
| 5 | Recipe echo | Snippet used `@contributors-update:` | `just 1.57.0` echoes the script body of a `@`-prefixed shebang recipe (pre-check) | `@` dropped |
| 6 | Bootstrap branch executed | Proposed, not run | Cases 04-07, 10 against a local stand-in for the one endpoint `init` calls | The guard's `init` branch, its guard flip and its three failure modes are executed evidence, not proposals |

Remaining uncertainty: the absence of a Rust-native equivalent rests on Codex's bounded crates.io search, which the evidence check could not rerun (HTTP 403) and this synthesis did not retry; Linux was not exercised locally (inferred from the action's `node24` runtime and both sources' `ubuntu-latest` workflows); no live GitHub bootstrap or action-parity comparison was executed; `pnpm dlx` was not exercised on this host.

Sources carried over from the raws (retrieved 2026-09-05): `https://registry.npmjs.org/contributors-please`; `https://github.com/smorinlabs/contributors-please/blob/main/README.md`, `…/src/cli.ts`, `…/src/engine/contributors.ts`, `…/test/cli.test.ts`; `https://raw.githubusercontent.com/smorinlabs/contributors-please-action/main/action.yml`, `…/README.md`, `…/src/index.ts`, `…/package.json`, `…/package-lock.json`; `https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/Justfile#L457-L462`; `https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/Justfile#L237-L244` and `…/.github/workflows/update-contributors.yml#L68-L86`; `https://git-cliff.org/docs/`, `https://docs.rs/crate/git-cliff/2.13.1/source/Cargo.toml`; `https://crates.io/search?q=contributors`; `https://doc.rust-lang.org/cargo/commands/cargo-install.html`; `https://docs.npmjs.com/cli/v11/commands/npm-exec`. Read by the synthesizer on 2026-09-05 from local clones: `~/c/contributors-please` at `c9b7b0754b0654630305af6c39142fcfdf126b51` (`package.json`, `src/cli.ts`, `src/engine/{contributors,github,state,identity-join,config}.ts`, `src/engine/classifiers/path.ts`, `schemas/state.schema.json`, `README.md`); `~/c/contributors-please-action` at `cbb1fd47b8ef9781c1557230034c37dc51c15e18` (`action.yml`, `src/index.ts`, `README.md`); `~/c/py-launch-blueprint` at `b08bccf` (`Justfile`, `.contributors.yml`, `.contributors.jsonl`, `CONTRIBUTORS.md`); `~/c/ts-launch-blueprint` at `cb1cbcb` (`Justfile`, `.contributors.yml`, `CONTRIBUTORS.md`, `.github/workflows/update-contributors.yml`, `docs/port/TS_PORT_DECISIONS.md`); this repository's `docs/port/{COMMONALITY,PARAMETERS,DIVERGENCE-ANALYSIS,OWNER-REVIEW,BASELINE-REVIEW}.md` and `research/EXECUTION.json`; `npm view contributors-please` (registry, 2026-09-05).
