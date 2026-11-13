# 2026-09-27 — R29 — non-code-file-formatting (bundle, Focused) — decision (revision 2)

**Revision note, revision 2.** This is a repair round, written 2026-09-27 (US/Pacific) by actor `repair-opus-2026-09-26T190157Z-3dd868e1695b-r2`, model `claude-opus-5-5` (Anthropic family), Claude Code CLI. That is the Opus leg's model, and Disagreement J below adjudicates Muse against Opus; J therefore rests on the run prompt's coupling text and on R27's own recipe wording, not on either leg's prose. Revision 1 had sha256 `fb003aecddf145c2fd8ad3bca2c6f3aa2367201f8ed563d11b82c2884b6ec5c2` and is preserved byte-for-byte at `review/R29-r1-snapshot.md`. The empirical audit, `review/audit-claude.md`, approves. The judgment audit, `review/audit-fable.md`, rejects with one finding, and revision 2 repairs only that finding. The recommendation does not move: the host, the four plugins, the pins, `dprint.json`, the hook job and the CI step are unchanged. No finding is a reversal, so there is no `## Supersedes`.

| Finding | Repair in revision 2 |
|---|---|
| `audit-fable.md` finding 1 (JF-2, JF-3, JF-5): the wiring table handed R27 the choice of whether the composite `check`/`all` recipes run the non-code formatters, although `inputs/prompt.md:29` assigns that choice to R29; the Muse-versus-Opus disagreement on it was not adjudicated | R29 now states its own answer, option (a): the composite gate that checks also runs `check-files`, and the composite that writes also runs `format-files` (`Justfile` row of the wiring table). `## Engines` gains Disagreement J, settled for Muse's substance. The **Hand-offs** paragraph records the coordination with R27 as a hand-off. R27's F102, whether the composite includes the Rust format-check step, is not re-decided |

**Evidence.** The repair is prose in this file, but `review/evidence/r29-decision-checks.sh` asserts this file's own title, revision note and citations, so it was edited and rerun: `C1a` expects the revision-2 title; `C1c` also expects this note and its actor; `C4` gains rows for the eight newly cited raw lines, `raw/muse.md:832-835` and `raw/opus.md:373,843,844,854`. It still counts 11 checks. `r29-decision-checks.log` and `shellcheck.log` were regenerated. The other six scripts, their logs, `fixtures/` and `snapshots/` are byte-unchanged. The composite recipe itself was **not executed**, because R27 is `open` and the composite's name is not fixed; the recipe it calls is executed (`D14`, `D15c`).

**Not repaired; observations from `review/audit-claude.md`, carried forward.** O1: the sentence "Each writes `<name>.log` beside itself" under `## Empirical check` is inaccurate; the logs are captured stdout and stderr. O2: `D0b`'s size tolerance depends on the length of the `CARGO_HOME` path, so the committed built-module digests do not reproduce elsewhere. O3: `C3c` and `C5` must change if the controller re-freezes this run's inputs under Q17.A.

**Revision note, revision 1.** This is the first synthesis for R29. It adjudicates the two raw reports of run `2026-09-26T190157Z-3dd868e1695b`, `raw/muse.md` (916 lines) and `raw/opus.md` (942 lines), against sources re-captured for this revision and against checks executed for this revision. Nothing has been published for R29, so there is no `## Supersedes`. The two legs agree on the host for YAML, JSON and Markdown and disagree on the TOML owner; this revision settles that disagreement for the Opus leg on four executed grounds (`## Engines`, Disagreement A).

Actor `synth-opus-2026-09-26T190157Z-3dd868e1695b-r1`, model `claude-opus-5-5` (Anthropic family), a fresh context that wrote neither raw report and ran every check below. Item kind `bundle`, effort tier `focused` (two engines). **Staffing flag for the controller:** the run's policy snapshot lists R29's engines as `codex, opus` (`inputs/EXECUTION.json`, `items.R29`), R29 is absent from that snapshot's `engine_overrides`, and `manifest.json` records `required_engines: ["codex", "opus"]`; yet the raw directory holds a Muse leg and no Codex leg. **During this synthesis the live topic prompt was edited** (file time 2026-09-26 19:56:53 local, 02:56:53Z; uncommitted) to read `- engines: muse, opus` and to add "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot"; those two lines are its only difference from the run's `inputs/prompt.md` (`C3c`). The run's snapshot therefore predates the substitution record, and the run's prompt hash no longer equals the live prompt's; RUNBOOK §3 routes a changed prompt to revalidation against current inputs, which is the controller's. The synthesizer is also the same model as the Opus leg, where the RUNBOOK's synthesizer row names a fresh Claude Fable context. This decision invents no override; it records both facts for reconciliation.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12: licence compatibility is not evaluated for any tool or library the template uses`** (R42 `DECISION.md:12-17`; R11 `DECISION.md:82`). Licences are still recorded as figures.

## Decision

**Status.** This decision is a **proposal validated in the implementation phase**. `rs-launch-blueprint` has no template tree yet; P03 builds it. Everything under `## Empirical check` ran on a fixture tree on macOS 26.4 arm64, not on a GitHub-hosted runner.

**Recommendation — one stack: one Rust-native formatter host, `dprint` 0.57.4, loading four checksum-pinned Wasm plugins.** WebAssembly (Wasm) plugins are platform-independent modules the host runs in an embedded sandbox, so no Node, Python or Go runtime enters the template.

| Family | Files it owns in the template | Plugin, version | Checksum pin (`sha256` of `plugin.wasm`, from the GitHub release API) |
|---|---|---|---|
| TOML | `Cargo.toml`, `rust-toolchain.toml`, `rustfmt.toml`, any `*.toml` another item adds | `dprint-plugin-toml` 0.8.0, `cargo.applyConventions` left at its default `true` | `69cb40cb…976945d` |
| YAML | `.github/workflows/*.yml`, `lefthook.yml`, `.github/dependabot.yml` | `pretty_yaml` 0.6.0 (`g-plane/pretty_yaml`) | `40a2fdda…eba01ae` |
| JSON, JSONC | `release-please-config.json`, `.vscode/*.json`, `dprint.json` | `dprint-plugin-json` 0.24.0 | `07316f98…28bc48f1` |
| Markdown | `README.md`, `docs/**`, `.github/*.md` | `dprint-plugin-markdown` 0.24.0 | `cf7e6567…81217764` |

The whole stack is one committed file, executed as `fixtures/tree/dprint.json` (`review/evidence/`):

```json
{
  "lineWidth": 100,
  "toml": {
    "indentWidth": 4
  },
  "excludes": [
    "**/target",
    "CHANGELOG.md",
    ".release-please-manifest.json"
  ],
  "plugins": [
    "https://plugins.dprint.dev/toml-0.8.0.wasm@69cb40cba5e8a53560ccea7fdced073a55d04eb05492f0d9b877f916b976945d",
    "https://plugins.dprint.dev/json-0.24.0.wasm@07316f98ceda3761d31569795d82b8a104cb078e54e46fb542c2a81728bc48f1",
    "https://plugins.dprint.dev/markdown-0.24.0.wasm@cf7e65674b7eb5d91f85152ae9020dc8b3e73bd7944efcbfb05df71081217764",
    "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm@40a2fdda7040317eb1b23520f3a00769a5571eedb049c4ca9175c1b9eeba01ae"
  ]
}
```

- `lineWidth` 100 tracks `rustfmt`'s `max_width`, whose value is R27's (F087); 100 is `rustfmt`'s default. `toml.indentWidth` 4 applies the Rust Style Guide's "Use the same line width and indentation as Rust code" (`cargo.md:5`).
- `excludes`: `**/target` is build output. `CHANGELOG.md` and `.release-please-manifest.json` are written by release-please, whose output this stack would otherwise reject on every release pull request (`D16`). `Cargo.lock` needs no entry: no plugin claims a file without an extension (`D2`).
- The four pins are the `digest` values the GitHub release API reports for each `plugin.wasm` (`S6`). That `plugins.dprint.dev` serves those exact bytes is **expected, not verified** here, because downloading from it is outside the prompt's named endpoints; P03's first cold-cache `dprint check` verifies it, since dprint refuses a module whose checksum mismatches (`D18`).

**Wiring.** Every invocation is the bare `dprint` executable on `PATH`, per R42's `package-manager-invocation`.

| Surface | What this decision specifies | Owned elsewhere |
|---|---|---|
| Tool table | `dprint@0.57.4`, a crates.io tool installed by R42's generic `install-tool` recipe (`cargo binstall --locked --no-confirm dprint@0.57.4`); presence test `command -v dprint` | the recipe body and table format: R42 |
| `Justfile` | `format-files` runs `dprint fmt`; `check-files` runs `dprint check` (executed, `D14`, `D15c`). **The composite gate that checks, R27's `check`/`all` path, also runs `check-files`**, immediately after R27's Rust format-check step and ahead of every compile-heavy step. **The composite that writes also runs `format-files`**, beside R27's `format`. `dprint check` compiles nothing, so the gate fails on non-code drift before it compiles (Disagreement J). The composite itself is not executed here; `D15c` shows `just check-files` exits `20` on drift | R27, F102: whether the composite includes the Rust format-check step, and the composite recipes' names and order of the other members. R29 hands its membership answer to R27 (**Hand-offs**) |
| `lefthook.yml` | one job, `format-files`, in **the same hook stage as `rustfmt`**, with `glob: "*.{toml,json,jsonc,md,yml,yaml}"`, an `exclude:` list mirroring `dprint.json`'s release-please entries, and `run: dprint check --allow-no-files {staged_files}` (executed at `pre-commit`, `H0`–`H5`) | the stage (`pre-commit` or `pre-push`) and check-versus-write mode: R27, F104. At `pre-push`, `{staged_files}` becomes `{push_files}`; in write mode, `dprint fmt --allow-no-files {staged_files}` with `stage_fixed: true` |
| `.github/workflows/ci.yml` | two steps in R11's always-run `hygiene` job: the `install-tool` step, then `run: dprint check` (the step lints clean, `D11`) | job shape: R11 |

**Answers to the prompt's questions.**

- **HIGH — one tool or a per-format split?** One tool exists and is recommended: `dprint` with four plugins covers all four families in one process, one config, one hook job and one CI step. `rustfmt` formats only Rust, so Rust needs a second tool dedicated to non-code files; ts's "one tool" intent survives as "one non-code tool".
- **HIGH — is `taplo` dominant, and is it `cargo install`-able?** It has the largest TOML install base (`taplo-cli` 194,730 downloads in 90 days against `dprint-plugin-toml`'s 2,223, `S8`) and is on crates.io (0.10.0, `rust-version` 1.74), so its current distribution is not npm-only. It is **not** chosen: its owner withdrew in writing, it applies no Style Guide key order, and R42's `install-tool` compiles it from source on every cacheless run (Disagreement A).
- **MEDIUM — YAML?** A maintained Rust-native YAML formatter exists: `pretty_yaml`, run as a dprint plugin, as deno runs it (`deno .dprint.json:95`, `S3d`). No Go binary is needed and YAML is enforced, unlike py's unwired `yamlfmt`.
- **MEDIUM — JSON and Markdown worth it?** Yes. The template carries release-please JSON, JSONC editor settings, `README.md` and `docs/`, and each family costs one plugin line in an already-provisioned host. The Markdown plugin also formats fenced JSON and TOML blocks in the README (`D13`).
- **LOW — hook tier?** The same tier as `rustfmt`. The scope difference the question raises disappears in a hook, because lefthook hands the job only the staged files; the whole-repository scan happens once, in CI's `hygiene` job.

**Ledger rows this decision settles: F097, F098, F099** (`docs/port/COMMONALITY.md`; verdict strings remain the controller's). F097 — TOML formatting is a plugin of the non-code host, not a separate tool; F098 — YAML formatting is owned by the same host and enforced in hooks and CI; F099 — JSON and Markdown are covered, with release-please's generated files excluded.

**BASELINE-REVIEW.** None raised. Neither leg raised one (`raw/muse.md:112`; `raw/opus.md:221`), and this decision challenges no inherited baseline.

### Principles and implementation

**The shared requirement.** Both source repositories intend the same outcome, at the **policy** level: every committed non-Rust configuration or documentation file has one canonical machine-produced layout; a check fails when a file deviates; one local command fixes it. py realised this for TOML only and left YAML configured but unwired; ts realised it for YAML, JSON and Markdown and had no TOML. The tool is not required to agree across repositories.

**What must agree, and how the recommendation meets it.**

| # | Acceptance criterion | Met by | Evidence |
|---|---|---|---|
| 1 | Every tracked `*.toml`, `*.yml`/`*.yaml`, `*.json`/`*.jsonc`, `*.md` is formatted or excluded for a stated reason | four plugins by extension; three `excludes` entries with reasons | `D1`, `D2`, `D2b` |
| 2 | The check fails on any unformatted covered file, including when R11 skips the compile tier | `dprint check` exits `20` and names each file; it is a step of `hygiene`, which has no `needs:` edge | `D3`, `D15`, `D15b`; R11 `DECISION.md:188` |
| 3 | One command writes, one command checks, and writing converges | `dprint fmt`, `dprint check`; the second `fmt` is a no-op | `D4`, `D6`, `D7` |
| 4 | Formatting never changes meaning | every YAML, TOML and JSON(C) file parses to identical data before and after; `cargo metadata` reads the reordered manifest; `actionlint` and `lefthook validate` accept the formatted files | `D5`, `D9`, `D9b`, `D11`, `D12` |
| 5 | Files another tool owns are never touched | `Cargo.lock`, `target/`, `CHANGELOG.md`, `.release-please-manifest.json` byte-identical after `fmt` | `D5b` |
| 6 | `Cargo.toml` follows the Rust Style Guide, the only first-party authority on non-Rust formatting | `[package]` becomes `name`, `version`, …, `description`; dependency tables are sorted | `D8`, `D8b`; `cargo.md:11-15` (`S4a`) |
| 7 | A release-please pull request, which touches only generated files, passes both the hook and CI | the `excludes` entries; the hook's `exclude:` plus `--allow-no-files` | `D16`, `D17`, `D17b`, `H2`, `H4`, `H5` |
| 8 | Runs on `ubuntu-latest` and `macos-latest` without a non-Rust runtime | `dprint` publishes `dprint-x86_64-unknown-linux-gnu.zip` and `dprint-aarch64-apple-darwin.zip`, names `cargo-binstall`'s default templates produce; plugins are Wasm | `S2a`, `S2b`; executed on macOS arm64 only |

What may vary: style knobs (quote style, `lineWidth` when R27 moves F087), and whether the hook writes or checks (F104).

**Architectures compared before libraries.**

| Architecture | Realised by | Families covered | Verdict |
|---|---|---|---|
| One host, per-format plugins | `dprint` + four Wasm plugins | all four | **recommended** |
| A TOML specialist plus a host for the rest | `taplo-cli` 0.10.0 + `dprint` (the Muse leg's stack) | all four, two binaries | runner-up; loses on maintenance, conventions and provisioning (Disagreement A) |
| One monolithic multi-format binary | `oxfmt` 0.70.0 standalone | TOML, YAML, JSON; Markdown only under Node per the Opus leg's reading of oxc source (`raw/opus.md:136`), unverified here | not adopted; the Markdown claim is an open gap, and `oxfmt` ignores TOML options per the Opus leg (oxc#18580) |
| Per-format tools, py's shape | `taplo` + `yamlfmt` | TOML, YAML | fails criterion 1 for JSON and Markdown and needs a Go binary |
| Node-hosted Prettier or ts's `oxfmt` | Prettier / `@oxc` npm | YAML, JSON, Markdown | adds a Node toolchain the template otherwise lacks |
| No enforcement | — | none | the modal practice among large Rust repositories per the Opus survey (`raw/opus.md:90`), but it fails criteria 1–3 |

**Figures** (this revision's snapshot, retrieved 2026-09-27; `S8`–`S10`). Downloads are crates.io's `recent_downloads` (90 days) and `downloads`; the plugins are mostly fetched as Wasm from `plugins.dprint.dev`, so crates.io undercounts them.

| Artifact | 90-day / all-time downloads | Newest release | Stars, archived, last push | RustSec | Maintenance (prompt rubric) |
|---|---|---|---|---|---|
| `dprint` | 11,573 / 239,963 | 0.57.4, 2026-09-05 | 4,079, no, 2026-09-15 | no package page | `active` |
| `dprint-plugin-toml` | 2,223 / 19,633 | 0.8.0, 2026-08-18 | 24, no, 2026-09-05 | no package page | `active` |
| `dprint-plugin-json` | 159,493 / 869,002 | 0.24.0, 2026-09-15 | not re-queried | no package page | `active` |
| `dprint-plugin-markdown` | 148,650 / 904,256 | 0.24.0, 2026-09-10 | not re-queried | no package page | `active` |
| `pretty_yaml` | 241,855 / 840,275 | 0.6.0, 2026-01-09 | 52, no, 2026-08-26 | no package page | `stable-quiet`: no release in 8.5 months triggers investigation; pushed 2026-08-26, no at-risk signal |
| `taplo-cli` (runner-up) | 194,730 / 2,224,667 | 0.10.0, 2025-05-23 | 2,402, no, 2026-07-28 | no package page | `at-risk`: the owner's written withdrawal (`S1b`–`S1d`) |

**Minimal realistic example and its verification.** `review/evidence/fixtures/tree/` is a template-shaped tree: a `Cargo.toml` whose `[package]` keys and dependencies violate the Style Guide, `rust-toolchain.toml`, `rustfmt.toml`, a workflow with `${{ }}` expressions and a `run: |` block, `lefthook.yml` holding the recommended job, `dependabot.yml`, JSONC editor settings, release-please's config and manifest, a README with a table, a task list and fenced JSON and TOML, the first 12 lines of release-please's own generated `CHANGELOG.md` (`S7`), a `Cargo.lock` decoy, `target/` decoys created at run time, and pretty_yaml issue #4's own reproduction with each chomping indicator. `r29-dprint-stack.sh`, `r29-lefthook.sh` and `r29-taplo-compare.sh` run the stack and its runner-up on that tree. What they could not run is listed under `## Empirical check`.

**Where Rust needs a different design from both sources.** ts collapsed everything into its code formatter because `oxfmt` already was ts's code formatter; in Rust the code formatter formats nothing else. py's instinct, a dedicated TOML tool, was right about the weight of TOML in a Rust repository; its tool has since lost its owner, and the Style Guide's `Cargo.toml` conventions are applied by the plugin chosen here and by neither py tool.

**Hand-offs.** R27: F087 (`lineWidth`), F104 (hook mode), and the hook stage. F102 stays R27's: whether the composite includes the Rust format-check step. R29 does not re-decide it. R29 hands R27 its own answer on the non-code members, which `inputs/prompt.md:29` assigns to R29: the checking composite runs `check-files` right after R27's format-check step, and the writing composite runs `format-files`. R27's revision 3, which is `open` and cited point-in-time, leaves those members to their owners: the composite gate "lists `format-check` first; its name and its other members belong to their owning items" (`research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/DECISION.md:51`). If R27 publishes F102 without a format-check step, `check-files` still belongs in the composite, ahead of compile-heavy steps. R28: an editor running taplo-based "Even Better TOML" with format-on-save does not fight this stack on the fixture — taplo's default formatter accepts dprint's output unchanged (`T6c`) — but that was measured with taplo's CLI defaults, not the extension's settings. R40: yamllint rules (F168) must not contradict `pretty_yaml`'s output. R42: one tool-table entry.

re-verify: 2027-03-27, or earlier on any of — dprint 0.58 or any plugin's next minor release; P03's first cold-cache `dprint check` (proves the four pins against `plugins.dprint.dev`) and first `cargo binstall dprint@0.57.4` on each runner (proves the prebuilt path); pretty_yaml#4 or a similar block-scalar report shown to alter formatted output; taplo cutting a release under new ownership, or `tombi` publishing a real crates.io release; oxc#18580 closing or `oxfmt` formatting Markdown without Node; R27 publishing F087, F102 or F104; R40 publishing yamllint rules; release-please changing which files it writes; deno dropping dprint.

## Parameters

R29 owns no parameter, so there is no `owns` line.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner
- assumes package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component

**No `CONFLICT:` line.** Each `assumes` value is byte-identical to `inputs/parameters.json` (`C2a` in `r29-decision-checks.sh`), and the prerequisite files are at the hashes `inputs/prerequisites.json` records (`C3a`). How the recommendation satisfies the two researched values: `dprint` is not a `cargo-<sub>` executable, so every recipe and hook line names bare `dprint`, with presence tested by `command -v dprint`; `dprint check` compiles nothing, so it is a step of `hygiene`, the slot R11 names for R29. The rust-edition and msrv-policy values bind template code; the host is a separate-process tool installed from a prebuilt release, and its Wasm plugins are never compiled by the template toolchain.

## Empirical check

**Host and toolchain, each read from the tool.** macOS 26.4, `Darwin 25.4.0 arm64`. `dprint 0.57.4`, built by `cargo install dprint --version 0.57.4 --locked` from crates.io into the private `CARGO_HOME=/tmp/cargo-s13-R29` with Homebrew `cargo 1.98.1` (log `review/evidence/build/cargo-install-dprint.log`, `EXIT=0`, 02:37:39Z–02:39:46Z, about two minutes on 14 cores). Plugins built from their tagged sources with rustup toolchain `1.93.0-aarch64-apple-darwin`, the only local toolchain carrying `wasm32-unknown-unknown`. `taplo 0.10.0` (mise shim), `lefthook 2.1.14`, `actionlint 1.7.12`, `just 1.57.0`, `python3 3.14.7` with PyYAML 6.0.3 and `tomllib`, `shellcheck 0.11.0`.

**Working directory:** the repository root, `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Each script resolves its inputs from its own location and works in a fresh `mktemp -d` under `/tmp`, with `DPRINT_CACHE_DIR` inside it, and removes it on success.

**Hosts contacted.** `crates.io` (API and `.crate` downloads, which redirect to `static.crates.io`), `api.github.com` through `gh api`, and `rustsec.org`. Not contacted: `plugins.dprint.dev`, `github.com` release downloads, npm, and any rustup distribution server.

**One deviation from the recommended configuration.** The executed `dprint.json` differs from the recommended one only in its four plugin entries: each `https://plugins.dprint.dev/…wasm@<sha256>` is replaced by the path of a module built from the same tagged source (`r29-provision.sh`), because the published modules are outside the named endpoints. The built modules are within 3.1% of the published sizes (`D0b`: json 643,865 against 636,736 bytes, markdown 743,253 against 761,907, toml 514,607 against 510,627, pretty_yaml 594,430 against 576,981) but are not byte-identical, so their digests are not the pins; the pins come from the release API (`S6`). The pretty_yaml wrapper crate, `dprint_plugin_yaml`, is `publish = false` (`S5b`), so its three source files and the repository `LICENSE` it embeds were taken from tag `v0.6.0` through the contents API, over the published `pretty_yaml` 0.6.0 library.

**Commands, run from the repository root:**

```
bash research/runs/R29/2026-09-26T190157Z-3dd868e1695b/review/evidence/r29-snapshots.sh
bash research/runs/R29/2026-09-26T190157Z-3dd868e1695b/review/evidence/r29-provision.sh
bash research/runs/R29/2026-09-26T190157Z-3dd868e1695b/review/evidence/r29-sources.sh
bash research/runs/R29/2026-09-26T190157Z-3dd868e1695b/review/evidence/r29-dprint-stack.sh
bash research/runs/R29/2026-09-26T190157Z-3dd868e1695b/review/evidence/r29-lefthook.sh
bash research/runs/R29/2026-09-26T190157Z-3dd868e1695b/review/evidence/r29-taplo-compare.sh
bash research/runs/R29/2026-09-26T190157Z-3dd868e1695b/review/evidence/r29-decision-checks.sh
```

Each writes `<name>.log` beside itself and exits non-zero on any `FAIL`. **For the audit rerun:** `r29-snapshots.sh` is this revision's capture, and the rerun is the six other scripts against the committed `snapshots/`. Rerunning the capture refreshes rolling figures, so `S8` and `S9` would then fail until re-read against the new values. `r29-snapshots.sh` is the only script that reads the network for evidence; every other check reads its snapshots offline, and `snapshots/PROVENANCE.tsv` records each file's endpoint, UTC retrieval time and status.

| Script | Checks | What it decides |
|---|---|---|
| `r29-snapshots.sh` | 51 captures, 2026-09-27T02:58:30Z–02:58:48Z, each status asserted `200`, `404` or `gh` exit 0 | the source set: crates.io records, repository and release metadata, taplo#715 and its comments, pretty_yaml#4, dprint's docs and own config, deno's and rustup's configs, the Style Guide chapter, plugin sources, `cargo-binstall` 1.23.0's URL templates, RustSec pages |
| `r29-provision.sh` | provisioning, no assertions beyond versions and build success | the `dprint` host and four plugin modules the other checks run |
| `r29-sources.sh` | 25 | `S1a`–`S1f` taplo#715 and taplo's release state; `S2a`–`S2d` `cargo-binstall` template matching for dprint and taplo assets; `S3a`–`S3e` dprint exit codes, plugin paths, checksums, dprint's and deno's own configs, rustup's CI; `S4a`–`S4b` Style Guide and the plugin's Cargo conventions; `S5a`–`S5c` pretty_yaml#4, the wrapper's identity, absent crates; `S6` pins equal release digests; `S7` the CHANGELOG fixture is release-please's own bytes; `S8`–`S10` every figure quoted here |
| `r29-dprint-stack.sh` | 34 | `D0`–`D18d` below |
| `r29-lefthook.sh` | 6 | `H0`–`H5` below |
| `r29-taplo-compare.sh` | 12 | `T0`–`T6c` below |
| `r29-decision-checks.sh` | 11 | `C1a`–`C1d` shape of this file against published R11; `C2a`–`C2b` `assumes` lines against `inputs/parameters.json`, no `owns` or `CONFLICT:`; `C3a`–`C3c` prerequisite and prompt hashes, and the live prompt's edit; `C4` every `raw/…:N` and prerequisite `DECISION.md:N` citation resolves to the quoted text; `C5` the staffing facts in the header |

**Observed output, the load-bearing lines.**

| Id | Command or probe | Observed |
|---|---|---|
| `D0b` | built module sizes against the release API's sizes | every module within 3.1% |
| `D1`, `D2`, `D2b` | `dprint output-file-paths` (also with `--no-gitignore`) | exactly the 13 covered files; `CHANGELOG.md`, `.release-please-manifest.json`, `Cargo.lock` and `target/` absent, `target/` absent even with `.gitignore` disabled |
| `D3`, `D4b` | `dprint check` on the authored tree | exit `20`, 11 files listed; `dprint fmt` changes exactly those 11 |
| `D5`, `D5b` | parse every YAML, TOML and JSON(C) file before and after `fmt` | identical data; excluded files byte-identical |
| `D6`, `D7` | `dprint check`; `dprint fmt` again | exit `0`; second `fmt` changes nothing |
| `D8`, `D8b` | key order in the formatted `Cargo.toml` | `[package]`: `name,version,edition,include,license,rust-version,description`; `[dependencies]`: `anyhow,clap,serde` |
| `D9`, `D9b` | `cargo metadata --no-deps --offline` | exit `0`; package `rs-launch-blueprint`, `rust-version` 1.96, lib `rs_launch_blueprint`, bin `rslbp` |
| `D10`, `D10b` | pretty_yaml#4's reproduction plus `|+`, `|-`, `>`, an anchor and merge key | lines 1–17 byte-identical after `fmt`; `a` and `b` load as `"hello\nworld\n"`; `${{ matrix.os }}` survives |
| `D11`, `D12`, `D14` | `actionlint`, `lefthook validate`, `just check-files` | exit `0` on the formatted tree |
| `D13`, `D13b` | README and docs | fenced JSON becomes `{ "a": 1, "b": [1, 2] }`, fenced TOML `name = "demo"`; prose not reflowed |
| `D15`, `D15b`, `D15c` | one perturbation each in `lefthook.yml`, `Cargo.toml`, `release-please-config.json`, `docs/guide.md` | exit `20` naming exactly those 4; `just check-files` propagates `20` |
| `D16`, `D16b` | release-please's generated files with the exclusion removed | `CHANGELOG.md` fails (exit `20`: its double blank line collapses and `*` bullets become `-`); the manifest passes (exit `0`), so its exclusion is precautionary |
| `D17`, `D17b` | `dprint check CHANGELOG.md` without and with `--allow-no-files` | exit `14`, then `0` |
| `D18`–`D18d` | a wrong `@sha256` on the json plugin | cold cache: exit `12`, "Invalid checksum specified in configuration file"; correct pin on a cold cache: exit `0`; the wrong pin against a warm cache: exit `0` — a cached module is not re-verified |
| `H1` | commit a staged, unformatted `.github/workflows/ci.yml` | blocked: the glob reaches nested paths, dprint exits `20` |
| `H2`, `H3` | commit only `CHANGELOG.md`; commit a formatted new doc | pass: job skipped ("no files for inspection"); pass: job ran |
| `H4`, `H5` | the job without `exclude:`; then also without `--allow-no-files` | pass; then fails with `exit status 14` — either guard alone keeps release commits green |
| `T1`, `T3c` | `taplo format --check` with default configuration | collects `Cargo.toml`, `rust-toolchain.toml`, `rustfmt.toml` and the git-ignored `target/debug/decoy.toml`, and rewrites the decoy; never `Cargo.lock` |
| `T3b`, `T5`, `T5b` | taplo's key order: defaults; global `reorder_keys`; a rule scoped to dependency tables | authored order kept; `[package]` sorted alphabetically with `description` first, against `cargo.md:11-15`; dependencies sorted and `[package]` untouched |
| `T6`–`T6c` | each tool on the other's output | dprint rejects taplo's `Cargo.toml` on key order only; taplo accepts dprint's output unchanged |

**What no check here establishes.**

1. That `plugins.dprint.dev` serves bytes matching the four pins. They are the GitHub release digests; P03's first cold-cache run proves or refutes the match.
2. That `cargo binstall --locked --no-confirm dprint@0.57.4` downloads a prebuilt on each runner. `S2a`/`S2b` show a default template names the published assets exactly, and `S2d` shows no stanza overrides the defaults; the download itself is on `github.com`, outside the endpoints. If it compiles instead, the cacheless `hygiene` job pays the `wasmtime`/`cranelift` build that took this 14-core host about two minutes.
3. Anything on `ubuntu-latest`. Every check ran on macOS arm64.
4. Wall-clock cost of `dprint check` in CI, cold or warm. Not measured.
5. Style Guide conformance beyond the keys the fixture exercises: multi-line strings, long arrays and long inline tables were not tested.
6. `pretty_yaml` on the template's real workflows, which do not exist yet; its own issue #4 case is covered.
7. Behaviour of the published modules where it could differ from the tag builds.

The repository's structural checker `scripts/check-research-tree.sh` was not run: it takes the publication lock, a write outside this run's `review/` directory.

## Engines

| Leg | Actor identity recorded in the report | Model family | Retrieval date | Stack recommended |
|---|---|---|---|---|
| `raw/muse.md` | "Engine: muse" (`raw/muse.md:3`); no model id stated | Meta (Muse) | 2026-09-27 (`raw/muse.md:4`) | `taplo-cli` 0.10.0 for TOML plus `dprint` 0.57.4 with json, markdown and pretty_yaml plugins (`raw/muse.md:118`) |
| `raw/opus.md` | "Engine: claude-opus-5-5 (Opus seat, CLI run 2026-09-26)" (`raw/opus.md:3`) | Anthropic | 2026-09-26 | `dprint` 0.57.4 with toml, json, markdown and pretty_yaml plugins (`raw/opus.md:236`) |

No evidence check was run by another engine; this item's policy lists none. The synthesizer shares the Opus leg's model, which weakens the independence of Disagreement A's resolution; every point there therefore rests on an executed check or a captured source, not on either leg's prose.

**Where the legs agree**, and this decision adopts after re-checking: the `dprint` host at 0.57.4; `pretty_yaml` 0.6.0 for YAML, `dprint-plugin-json` 0.24.0 and `dprint-plugin-markdown` 0.24.0; `dprint check` as a step of R11's `hygiene` job; no `BASELINE-REVIEW:`, no `CONFLICT:`; the prompt's claim that taplo is "cited by `rustfmt`'s own config-schema tooling" is unverified in both (`raw/muse.md:281`, `raw/opus.md:230`), and nothing here depends on it.

**Disagreement A — who owns TOML.** Muse: `taplo-cli` 0.10.0, maintenance `stable-quiet` (`raw/muse.md:179`). Opus: `dprint-plugin-toml` 0.8.0, taplo `at-risk` (`raw/opus.md:442`). **Settled for Opus, on four executed grounds.**

1. *Maintenance.* The owner's own statements in the project's "The future of the project" issue: "Whatever plans I had with this project do not really exist anymore" (2025-11-10), "it has a lot of bugs and the code is unmaintainable as-is … it is destined to eventually die" (2025-11-11), "I don't want to be involved anymore" (2025-11-13) (`S1b`–`S1d`). A collaborator with push rights answered on 2026-03-22 that his plan is "to just keep merging and creating new releases here as long as I can" (`S1e`), and no release has followed 0.10.0 of 2025-05-23 (`S1f`). The prompt's rubric names a maintainer's own notice as a `dormant` trigger; a maintainer with push rights stating continued maintenance keeps it at `at-risk`, which requires a concrete signal, and the owner's withdrawal is one. Muse's `stable-quiet` omits the owner's notice.
2. *Style Guide conventions.* The plugin rewrites `[package]` to `name`, `version`, …, `description` and sorts dependencies (`D8`, `D8b`), which is the Style Guide's rule (`S4a`) and the plugin's default (`S4b`). taplo's defaults keep the authored order (`T3b`); its global `reorder_keys` sorts `[package]` alphabetically, putting `description` first, against the Style Guide (`T5`); a rule scoped to dependency tables sorts those and leaves `[package]` alone (`T5b`). taplo can approximate half of the rule; the plugin applies all of it that the fixture exercises.
3. *Provisioning under R42.* taplo's release assets carry no target triple and the crate is `taplo-cli`, so no `cargo-binstall` default template can name them (`S2c`), which matches R42's observed fall-through to a source build for `taplo-cli@0.10.0` on `aarch64-apple-darwin` (R42 `DECISION.md:91-93`). R11's `hygiene` has no cache, so that build would repeat on every run. dprint's assets match a default template (`S2b`). This ground is static evidence plus R42's executed probe, not a CI run.
4. *One binary instead of two.* taplo would add a second tool, a second configuration file, a second hook job and a second CI step. With default configuration it also walks into the git-ignored `target/` and rewrites what it finds (`T1`, `T3c`), so its `.taplo.toml` would need an exclude that dprint's `.gitignore` handling and `**/target` entry already provide (`D2b`).

What Muse's pick has that this one lacks: an install base about 88 times larger (`taplo-cli` 194,730 against 2,223 downloads in 90 days, `S8`), and schema-aware `taplo lint`. Muse itself recommends schema linting only as opt-in (`raw/muse.md:211`), and a malformed manifest fails Cargo itself. The residual risk of the choice is the plugin's small footprint: 24 stars (`S9`) and, per the Opus leg, a median 44.2 days to first maintainer response over its 10 newest issues (`raw/opus.md:428`), which this revision did not re-sample. **Runner-up and switch cost:** `taplo-cli` 0.10.0 with a committed `.taplo.toml` that excludes `target/` and scopes `reorder_keys` to dependency tables, or `tombi` if a real crates.io release appears. Switching deletes the `toml` plugin line and adds one binary, one config file, one hook job and one CI step.

**Disagreement B — one lefthook job or one per tool; one CI step or two.** Muse: two jobs and two steps (`raw/muse.md:122`); Opus: one of each. Follows from A: one tool, one job, one step.

**Disagreement C — how `Cargo.lock` is kept out.** Muse: `Cargo.lock` "must never be claimed by the JSON formatter" and its validation plants a `Cargo.lock` decoy "containing deliberately non-canonical JSON" (`raw/muse.md:475-476`, `raw/muse.md:585-586`). `Cargo.lock` is TOML syntax, not JSON. Opus: it has no extension, so no plugin matches it. **Settled for Opus's mechanism by execution:** neither dprint nor taplo collects it (`D2`, `T1`), and it is byte-identical after `fmt` (`D5b`). Muse's conclusion, that no formatter may touch it, holds.

**Disagreement D — which generated files are excluded.** Muse excludes `Cargo.lock` and `target/` only. Opus also excludes release-please's `CHANGELOG.md` and `.release-please-manifest.json` (`raw/opus.md:122`). **Settled for Opus on `CHANGELOG.md`, and for Opus as a precaution on the manifest.** release-please's own generated bytes fail `dprint check` when not excluded (`D16`, with the fixture taken from release-please's repository, `S7`), so without the entry every release pull request would fail `hygiene`. The manifest as release-please writes it passes unexcluded (`D16b`); the entry stays because the file is machine-owned. The hook needs the same entries or `--allow-no-files`: either one alone keeps a release commit green, and with both removed the commit fails with exit `14` (`H2`, `H4`, `H5`).

**Disagreement E — the hook stage.** Muse: `pre-push`, because whole-repository scans are seconds-bounded (`raw/muse.md:837`). Opus: `pre-commit`, because `{staged_files}` removes the scope difference (`raw/opus.md:267-268`). Both say "the same tier as `rustfmt`", and both defer the stage to R27. **Settled as: the same stage R27 gives `rustfmt`**, with the job text executed at `pre-commit` (`H0`–`H5`). Neither leg's stage is adopted over R27's open decision.

**Disagreement F — what dprint's own `dprint.json` shows.** Muse: it dogfoods `dprint-plugin-yaml@0.6.0` and contains "one entry with an `@sha` checksum suffix proving checksum-pinned plugin refs are supported" (`raw/muse.md:53`, `raw/muse.md:776-777`). Opus: it loads `npm:` specifiers, and the npm package's identity with `pretty_yaml` is unverified (`raw/opus.md:725`, `raw/opus.md:933`). **Settled for Opus on the facts** (`S3c`): every plugin is an `npm:` specifier, the YAML one is `npm:dprint-plugin-yaml@0.6.0`, and the only `@sha` belongs to the `exec` process plugin, which the docs say always requires one. Muse's conclusion that Wasm pins work is still right, on different evidence: dprint's configuration docs (`S3b`) and the executed refusal of a wrong pin (`D18`). Partly narrowing Opus's gap 6: the wrapper crate at tag `v0.6.0` is named `dprint_plugin_yaml` and describes itself as "pretty_yaml as dprint plugin." (`S5b`); the npm package itself was not read.

**Disagreement G — how much pretty_yaml#4 weighs.** Muse carries #4, an open block-scalar parse report, as the YAML member's explicit caveat (`raw/muse.md:339`); Opus does not mention it. The issue is open with no comments (`S5a`). **Resolved by execution:** the issue's own reproduction and every chomping variant format byte-identically and load to the same values (`D10`, `D10b`). The parse-tree defect does not reach this plugin's output on these inputs. Muse's fallback trigger stays in `re-verify:`. The two legs' responsiveness figures for pretty_yaml and dprint disagree because their methods differ — Muse samples open issues only (2 of 2 unanswered, `raw/muse.md:449`), Opus samples the 10 newest issues in any state (median 0.6 days, `raw/opus.md:735`) — and this decision relies on neither.

**Disagreement H — the licence gate.** Muse evaluates licences as gate 1 (`raw/muse.md:169`); Opus strikes it under the owner ruling (`raw/opus.md:324`). **Settled for Opus** on the ruling (R42 `DECISION.md:12-17`). Muse's licence findings stand as figures.

**Disagreement I — dprint's exit status and `binstall` resolution.** Muse says only that `dprint check` "fails" (`raw/muse.md:100`); Opus gives exit `20` (`raw/opus.md:147`). Confirmed `20` in the docs (`S3a`) and by execution (`D3`, `D15`). Opus left `binstall`'s prebuilt resolution for dprint unverified (`raw/opus.md:345`); this revision narrows it statically (`S2a`, `S2b`, `S2d`) and carries the download as item 2 of what no check establishes.

**Disagreement J — whether the composite `check`/`all` path runs the non-code formatters** (added in revision 2). Muse recommends that "the two checks also run inside the composite `check`/`all` path rather than only standalone, since non-code drift should fail the same gate as source drift" (`raw/muse.md:832-835`). Opus adds `format-files`/`check-files` "which R27 may fold into its composite under F102" (`raw/opus.md:373`), and says "composite recipe inclusion follows R27's F102" (`raw/opus.md:843-844`, `raw/opus.md:854`). **Settled for Muse's substance: option (a).** The checking composite runs `check-files`; the writing composite runs `format-files`.

1. *Ownership.* Opus's deferral is a scoping error, not an argument against inclusion. The run prompt assigns R27 only the Rust format-check step (F102) and assigns R29 "whether that same composite recipe, or a separate one, also runs the TOML/YAML/JSON/Markdown formatters chosen here" (`inputs/prompt.md:29`). The ledger scopes F102 the same way: "whether Rust's `check`-style composite recipe includes a format-check step" (`docs/port/COMMONALITY.md:108`). R27's own open revision 3 leaves the composite's other members "to their owning items" (**Hand-offs**). Deferring to R27 therefore left the question with no owner.
2. *One local gate.* The composite is the one command a contributor runs before pushing. Without `check-files` in it, a clean `just check` can still be followed by a red `hygiene` job on a TOML, YAML, JSON or Markdown file (`D15`: exit `20` naming each perturbed file). Muse's reason holds: non-code drift should fail the same gate as source drift.
3. *Cost and failure behaviour.* `dprint check` compiles nothing, and `just check-files` propagates dprint's exit `20` (`D15c`), so the composite stops on drift before its compile-heavy steps. Its wall-clock cost is not measured here (item 4 of what no check establishes).
4. *Option (b), standalone recipes, rejected.* No stated reason favours it. Keeping the recipes standalone would not reduce CI cost, because CI runs `dprint check` in `hygiene` either way; it would only remove the local signal.

Coordination with R27 is recorded under **Hand-offs**. Nothing here sets R27's composite name, its Rust format-check step or the order of its other members.

**Corrections to individual claims, none of which moves the recommendation.**

- Muse writes R11's acceptance hash with a trailing extra `c`, `…0628eac1c` (`raw/muse.md:803`); `inputs/prerequisites.json` records `…0628eac1`, which `C3a` asserts.
- Muse says pretty_yaml's `dprint_plugin` builds on `dprint-core 0.69` (`raw/muse.md:324-325`); at tag `v0.6.0` its manifest reads `dprint-core = { version = "0.66"` (snapshot `pretty_yaml-dprint_plugin-Cargo.toml`), probably a default-branch reading.
- Muse's landscape omits `tombi`, `oxfmt`, rustup's `taplo`-plus-`oxfmt` CI, and the Opus leg's 48-repository survey. Of the Opus survey, rustup's CI lines (`S3e`) and deno's plugin lines (`S3d`) were re-read and hold; the rest — polars, starship, pixi, biome, bevy, servo, swc, uv, rustls, and "no formatter" at 18 large repositories (`raw/opus.md:90`) — is carried unverified.
- Opus's "Unverified" TOML-editor concern (`raw/opus.md:481`) is narrower than stated for taplo's CLI defaults: taplo accepts dprint's output (`T6c`).
- Opus's two prompt-context corrections (the `@taplo/cli` npm note's location in ts `TS_PORT_DECISIONS.md:140`, `raw/opus.md:225`) lie outside this synthesis's permitted reads; recorded, not adopted.
- Opus's `oxfmt` Markdown claim (Markdown formatted only under the `napi` feature, `raw/opus.md:136`) and its gap 10 (`raw/opus.md:937`) were not re-read. `oxfmt` is not recommended here on other grounds as well, so the recommendation does not depend on it.
- Download figures differ by one day's rolling window (Opus's `taplo-cli` 197,076 against this snapshot's 194,730); every figure quoted in this decision comes from this revision's snapshot (`S8`, `S9`).

**Uncertainty, stated.** High confidence in the host and in the JSON and Markdown members: executed end to end, with dprint active. Medium-high in the TOML member: its behaviour is executed and matches the Style Guide, but its footprint is small and its issue response is slow per the Opus leg. Medium-high in the YAML member: the executed cases are clean, but it is a single-maintainer plugin with 52 stars (`S9`) and an open parser issue. Medium on the delivery path until P03 proves the pins against `plugins.dprint.dev` and the prebuilt install on both runners.
