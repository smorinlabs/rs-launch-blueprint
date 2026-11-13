# 2026-09-26 — R40 — auxiliary-hygiene-hooks (bundle, Focused) — decision (revision 1)

**Revision note, revision 1.** This is the first synthesis of R40. Nothing has been published for R40, so there is no `## Supersedes`. No audit has run against any revision.

Item R40 (`auxiliary-hygiene-hooks`, kind `bundle`, owns no parameter). Run `research/runs/R40/2026-09-26T190249Z-a9da32655556`. Synthesizer: actor `synth-opus-2026-09-26T190249Z-a9da32655556-r1`, model `claude-opus-5-5` (family anthropic), a fresh context that produced none of the raw reports. Inputs: `inputs/prompt.md` (sha256 `83eccf5e…`, byte-identical to the canonical prompt), `raw/muse.md` (sha256 `4d7c2634b7b34a9289d82b23ebbe6d95c9e6a9105b0b6ddd3b012211f132cdfd`), `raw/opus.md` (sha256 `4be5d4d1bbde408454b393c26dd9655f9e91945bf7056e9df43e6ef30c51772b`), `inputs/parameters.json`, and the two consumed decisions: R11 (`research/topics/11-ci-workflow-job-structure/DECISION.md`, sha256 `410e88e5…`) and R42 (`research/topics/42-dev-toolchain-provisioning/DECISION.md`, sha256 `a2504aa7…`). Both hashes equal the ones `inputs/prerequisites.json` records. `review/evidence/r40-citations.log` prints the two sets side by side.

**Engine provenance, flagged for the controller.** The run's `manifest.json` and the policy both name `codex` and `opus` for R40. `research/EXECUTION.json` has no `R40` entry under `engine_overrides`, but the Codex seat was filled by a Muse (Meta) report (`r40-citations.log`, "R40 is absent from engine_overrides"). `manifest.json` records no operations. This synthesis treats `raw/muse.md` as the second leg, because it is the report the run holds. The substitution itself is unrecorded. Recording it, or re-running the Codex leg, is the controller's decision and not made here.

**Retrieval dates.** Every figure and upstream read this synthesis cites was retrieved in the final evidence pass. That pass ran from `2026-09-27T02:34:09Z` to `02:36:27Z` UTC (`r40-rerun-all.log`), and the figures were taken at `retrieved_at=2026-09-27T02:35:36Z` (`r40-figures.log`). In the owner's Pacific time zone, that is the evening of 2026-09-26. This decision is dated by the Pacific date, which is also the run's date. Both raws are dated 2026-09-26.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every candidate below. The ruling is recorded in R42's decision: "no licence check for any tool or library the template uses" (R42 `DECISION.md:13`). R11 records the same ruling at `DECISION.md:82`. Both raws still weighed GPL licences as a tradeoff, and `raw/muse.md` used licence as one ground for replacing `codespell`. Every such argument is void here, and no member's selection rests on licence.

## Decision

**Status.** This decision is a proposal, validated in the implementation phase (owner ruling, 2026-09-10). `rs-launch-blueprint` has no `.github/` tree, no `lefthook.yml` and no Rust source yet. P03 builds the template, and its CI proves or disproves what is recorded here. Nothing below has run on a GitHub-hosted runner. Every tool below did run on this macOS host, together in one scratch repository (`## Empirical check`). A recommendation that does not survive implementation is revised against this recorded research, not researched again from scratch.

**Recommendation: one stack.** Adopt all four capabilities and the `.editorconfig` baseline. Each tool runs at pre-commit on staged files, inside the hook manager R37 owns, and again over the whole tree in CI, in the jobs R11 defines.

| # | Member (row) | Tool and version | Acquisition (R42) | Pre-commit job body (lefthook) | CI placement (R11) |
|---|---|---|---|---|---|
| 1 | whitespace/EOL/charset validity (F167) | `editorconfig-checker` 4.0.2 (Go, prebuilt) | release binary through R42's `ubi` residue slot: its first occupant | `editorconfig-checker {staged_files}` | step of `hygiene`: `editorconfig-checker` |
| 2 | YAML structural lint (F168) | `ryl` 0.22.0 (Rust) | crates.io tool table: `ryl@0.22.0` | glob `*.{yml,yaml}`: `ryl {staged_files}` | step of `hygiene`: `ryl .` |
| 3 | spell check (F169) | `typos-cli` 1.50.3, executable `typos` (Rust) | crates.io tool table: `typos-cli@1.50.3` | `typos --force-exclude {staged_files}` | step of `hygiene`: `typos` |
| 4 | workflow lint (F170) | `actionlint` 1.7.12 (Go, prebuilt) | release binary through R42's `ubi` residue slot: its second occupant | glob list `.github/*.{yml,yaml}` and `.github/**/*.{yml,yaml}`: `actionlint` with no file arguments | the `workflow-lint` job R11 reserves for it |
| 5 | cross-editor baseline and exceptions (F191, F192) | root `.editorconfig` (EditorConfig format) | committed file | enforced by member 1 | enforced by member 1 |

**The files this decision adds**, exactly as executed in `review/evidence/r40-compose.sh`:

```ini
# .editorconfig
# EditorConfig (https://editorconfig.org): the cross-editor baseline that
# editorconfig-checker enforces at pre-commit and in CI.
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.{yml,yaml,json}]
indent_size = 2

[Makefile]
indent_style = tab

# Markdown: two trailing spaces are a hard line break; trimming them changes
# the rendered document.
[*.md]
trim_trailing_whitespace = false

# insta file snapshots (R33): trailing spaces inside a snapshot line are data,
# and an editor trim makes the snapshot test fail.
[*.snap]
trim_trailing_whitespace = false
```

```json
{
  "Version": "v4.0.2",
  "Disable": {
    "Indentation": true,
    "IndentSize": true
  }
}
```

The block above is `.editorconfig-checker.json`. The pin value carries the leading `v`. The spelling `"4.0.2"` makes the binary refuse to run on a clean tree (`E0`).

```yaml
# .yamllint — read by ryl; the same file drives yamllint unchanged
extends: default

rules:
  document-start: disable
  line-length: disable
  indentation: disable
  comments:
    min-spaces-from-content: 1
  truthy:
    level: error
    allowed-values: ["true", "false"]
    check-keys: false
```

```toml
# typos.toml
[files]
# Walk .github/ too, so the CI whole-tree run checks what the hook checks.
ignore-hidden = false
extend-exclude = [".git/"]
```

```yaml
# lefthook.yml — the four jobs this item supplies; R37 owns the file's other content
pre-commit:
  parallel: true
  jobs:
    - name: editorconfig-checker
      run: editorconfig-checker {staged_files}
    - name: yaml-lint
      glob: "*.{yml,yaml}"
      run: ryl {staged_files}
    - name: typos
      run: typos --force-exclude {staged_files}
    - name: actionlint
      glob:
        - ".github/*.{yml,yaml}"
        - ".github/**/*.{yml,yaml}"
      run: actionlint
```

The CI commands are the four whole-tree forms `editorconfig-checker`, `ryl .`, `typos` and `actionlint`. Over the clean example they took 0.137–0.151 s together, measured over 3 runs (`C7`). No `.github/actionlint.yaml` is added by this item. That file's content is R09's (the prompt's `## Out of scope`), and R11's `workflows` key already contains it (R11 `DECISION.md:189`).

**Ledger rows this decision settles**: F167, F168, F169 and F170 (`docs/port/COMMONALITY.md:171-174`), and F191 and F192 (`:195-196`). All six are `py-only` and `DIVERGENT` with `Item: R40`.

**`BASELINE-REVIEW:` findings.** `raw/opus.md` raised three findings (`:279-281`), and this synthesis re-executed or re-read each one. `raw/muse.md` raised none. Each is carried for the controller and changes nothing in this item's recommendation:

- `BASELINE-REVIEW: F170 — workflow type-correctness gated at hook tier and in CI — the row's origin "py-only" is correct at the ledger pin and stale at the newer ts tip; the controller decides whether the ledger tracks the pin or the tip — ts cb1cbcb lefthook.yml has 0 occurrences of actionlint; ts e5100b4 lefthook.yml:15-17 wires "actionlint {staged_files}" on '.github/workflows/*.{yml,yaml}'; ts e5100b4 .github/workflows/ci.yml:90 runs "just check-shell check-workflows"; added by ts commit 3799ac6 (2026-09-15).` Verified in `r40-citations.log`. Affected items: R40, R09 and R11.
- `BASELINE-REVIEW: F169 — spelling gate — follow-on rationale for py: codespell misses a misspelling inside a snake_case identifier and flags a correct short identifier; typos does neither — T1: on "fn recieve_porjects(ans: u32)", codespell 2.4.2 reports "ans ==> and" twice, exits 65 and does not report "recieve"; typos 1.50.3 reports "recieve" and "porjects" and not "ans".` Affected items: R40 only; the py change is a follow-on.
- `BASELINE-REVIEW: F167 — validity-checker invocation — follow-on for py: editorconfig-checker 4.0.0 renamed the executable "ec" to "editorconfig-checker", and the 4.0.2 release tarball contains no "ec" — r40-install.log tarball listing; v4.0.0 release notes "rename ec to editorconfig-checker"; py b08bccf lefthook.yml:82 runs "uv run ec".` Whether py's PyPI wrapper still exposes `ec` was not checked. This is a re-verify prompt for py, not a claimed breakage.

**Answers to the prompt's questions.**

- **HIGH: is a separate whitespace/EOL linter needed, given `rustfmt`?** Yes, for everything that is not `.rs`. `rustfmt` owns Rust files. No decided formatter owns `Justfile`, shell scripts, `.gitignore`, licence files or snapshot fixtures, and R29, which covers TOML, YAML, JSON and Markdown, is still open. The architecture comparison under `### Principles and implementation` shows the gap and the rejected alternatives.
- **HIGH: ship an `.editorconfig` at all?** Yes. It is the only mechanism that reaches every contributor's editor at edit time for non-Rust files, and member 1 needs it as input. ts carries none, and the divergence analysis records no reason for that (`docs/port/DIVERGENCE-ANALYSIS.md:164`, "inferred: no recorded reason"). The ts port being more recent is not evidence either way.
- **HIGH: principles and agreement level.** Answered under `### Principles and implementation`: agreement is required at capability plus policy, not at tool level.
- **MEDIUM: keep `yamllint` and `codespell`?** Both are replaced. Neither can be acquired through R42's two sanctioned backends, and each has a Rust tool with executed parity or better: `ryl` for YAML (`Y1`–`Y9`) and `typos` for spelling (`T1`–`T5`).
- **MEDIUM: `actionlint`, and at which tier?** Keep it, at both tiers. It compiles nothing, so Rust's slower compile loop does not apply to it. It ran in 0.065–0.069 s over the example fixture (`A8`). Its hook shape changes from py's (see member 4).
- **LOW: which exceptions?** Keep `[*.md]` and replace py's `[*.ambr]` (a Python-only snapshot format) with `[*.snap]` for R33's `insta` files. Executed: an editor-style trim of a snapshot line breaks the `insta` 1.48.0 test (`I3`).

### Landscape

**The category.** This is not a library choice: none of these tools enters the template's Cargo graph. The category is *repository gates for properties of committed text that compilers and formatters do not check*. It consists of four developer-machine and CI binaries plus one declarative file that editors read and one of the binaries enforces.

**Three-bin map of the Rust field.** Candidates come from both raws' `crates.io` searches, their surveys, and this synthesis's re-reads.

| Capability | Built-in / first-party | Established industry standard | Up-and-comer |
|---|---|---|---|
| F167 whitespace/EOL/charset | `rustfmt` (`.rs` only); `git diff --check` with `.gitattributes`; in-repo tidy tests (rust-lang/rust, rust-analyzer) | `editorconfig-checker` (Go); `pre-commit-hooks` fixers (Python) | `ecformat` (Rust, 120 all-time downloads per `raw/opus.md`); `prek` built-ins (a hook manager, not a checker) |
| F168 YAML structural lint | none | `yamllint` (Python) | `ryl` (Rust, 0.22.0); `yamllint-rs`, `yaml-lint`, `fast-yaml-linter` (each under 250 downloads in 90 days per both raws) |
| F169 spell check | none | `typos-cli` (Rust); `codespell` (Python); `cspell` (Node) | `codebook-lsp` (Rust, LSP-first) |
| F170 workflow lint | none | `actionlint` (Go) | `zizmor` (Rust; a security audit, a different question, already R20's); `action-validator` (schema only); `truss-cli` (30 all-time downloads per `raw/opus.md`) |
| F191/F192 editor baseline | none (`rustfmt.toml` configures Rust only) | EditorConfig format | none |

**Authorities, and why each counts.** Maintainers' own documentation and release notes, read through `api.github.com`: `editorconfig-checker`'s README, including its "Default Excludes" list, and its v4.0.0 release notes; `ryl --help`; and `insta`'s `snapshot.rs` at tag 1.48.0 (commit `7f23d2e`). These are authoritative for what a tool does, not for whether it fits. The Rust project's own repositories (rust-lang/rust and rust-analyzer), which show what the project enforces on itself. The prompt's named endpoints (`crates.io`, `api.github.com`, `rustsec.org`) for every figure. The tools' executed behaviour, used as an instrument. No blog post is used as an authority.

**Practice evidence.** `raw/opus.md` surveyed 16 repositories through code search, and this synthesis did not re-run that survey. Its counts are carried as the leg's measurement: typos 10 of 16, `.editorconfig` 5 of 16, actionlint 2 of 16, yamllint 0 of 16 and editorconfig-checker 0 of 16. `raw/muse.md`'s narrower tree reads agree where they overlap: cargo runs typos, rust-lang/rust ships an `.editorconfig`, and neither tokio nor serde runs any of these tools. This synthesis re-read four `.editorconfig` files directly:

| Repository | TOML indent | YAML indent | Snapshot exception | Markdown exception |
|---|---|---|---|---|
| rust-lang/rust | 4 (default) | `[*.yml]` 2 | `[tests/**]` trim off | `[*.md]` trim off, "double whitespace at end of line denotes a line break in Markdown" |
| rust-lang/rust-analyzer | 4 (default) | `[*.{yml,yaml}]` 2 | — | — |
| astral-sh/ruff | `[*.{rs,py,pyi,toml}]` 4 | 2 (default) | `[*.snap]` trim off | — |
| astral-sh/uv | 2 (default) | 2 (default) | `[*.snap]` trim off | — |

These reads settle two details. TOML stays at indent 4, the three-of-four majority, where py's `[*.{yml,yaml,json,toml}]` (py `b08bccf` `.editorconfig:16`) and `raw/muse.md` used 2. `[*.snap]` has maintained Rust-project precedent in two insta-heavy repositories. The indent width is an editor-side default only: member 1 disables indentation checks, and R29's formatter owns TOML layout.

**Fit, not abstract best.** A template's value is the conventions it hands to every generated repository, and most of its files are not Rust: workflows, `lefthook.yml`, `dependabot.yml`, `Justfile`, Markdown, TOML and snapshot fixtures. A large application can skip these gates because reviewers catch drift. In a template, the next user inherits whatever drift was committed. That argument supports adoption; tool selection below is gate-first, then R42's acquisition rule, then practice.

### Members

**Fitness gates, stated once.** Gate 1 is inapplicable (owner ruling, above). None of these tools is a `Cargo.toml` dependency. So gates 2 (MSRV), 5 (features and runtime) and 6 (size and compile cost) bind only the path by which a tool is built, never the template's graph. The policy floor is **1.96**: stable is `rustc 1.98.1` on this host (`r40-install.log`), minus two minor versions. Gate 3 is read at `rustsec.org/packages/<crate>.html`. That site publishes a page only for a crate with an advisory, so HTTP 404 means none has ever been published. Go tools are outside RustSec's scope. Gate 4 is read from each project's own CI workflow (`r40-citations.log`, upstream section) and exercised here on macOS arm64 only.

#### 1 — `editorconfig-checker` 4.0.2 (F167)

- **Dominant choice and field.** It is the only maintained tool whose whole job is checking files against `.editorconfig`. `ecformat` is too young, per `raw/opus.md`'s figures. `git diff --check` ranks second (see runner-up).
- **Figures** (`r40-figures.log`): 638 stars; `archived: false`; `pushed_at` 2026-09-21T08:14:54Z; latest release v4.0.2 published 2026-09-19T11:47:24Z; 25 open issues by `search/issues` `total_count`. Of the 10 newest issues, 7 received a maintainer response, with a median of 0.49 days to first response, and 3 are unanswered. Maintenance state: **active**. Crate figures are **inapplicable**: it is not published on crates.io.
- **Gates.** 2, 3 and 5: inapplicable (a Go binary). Gate 4: the upstream CI matrix covers `ubuntu-latest`, `macos-latest` and `windows-latest` (`ci.yml:29-31`). The macOS asset `editorconfig-checker-darwin-all.tar.gz` is universal (`x86_64 arm64`, sha256 `ff59f577…`, `r40-install.log`). Gate 6: a single prebuilt binary, with no compile cost.
- **Behaviour executed** (`r40-ec.sh`, 14 of 14 assertions):

  | Case | Result |
  |---|---|
  | Clean tree | passes (`E1`) |
  | Trailing space in `Justfile` | fails (`E2`) |
  | Missing final newline | fails (`E3`) |
  | CRLF line endings | fails (`E4`) |
  | Trailing space in `src/lib.rs` | fails (`E5`) |
  | Version-pin mismatch | the binary refuses to run (`E6`) |
  | Explicit staged paths | checked (`E7`) |
  | Markdown hard break | passes through `[*.md]` (`E1`) |

  `Cargo.lock` and `target/` pass because they are default excludes. **Two behaviours differ from `raw/opus.md`'s README reading.** First, an untracked but not-ignored file *is* checked by the no-argument run (`E8`); a gitignored file is not (`E8b`). CI runs on a fresh checkout, so this changes nothing there, but a contributor's local whole-tree run can flag scratch files. Second, `.snap` is itself a default exclude, filed under "other binary or container formats". The `[*.snap]` stanza is therefore an editor-side protection and never reaches this checker (`I5n`, `I5d`); see member 5.
- **Recommendation.** Adopt, with the config and job above. Hook: `editorconfig-checker {staged_files}`. CI: a no-argument `hygiene` step. The `Version` key pins the binary. `Indentation` and `IndentSize` are disabled, as in py (py `b08bccf` `.editorconfig-checker.json:2`), because `rustfmt` and R29's formatters own indentation. py's `Exclude` list (`.venv`, `uv.lock`, `__snapshots__`, …) is not carried; the default excludes already cover `Cargo.lock` and `target/`.
- **Ranked runner-up.** `git diff --check` with `.gitattributes`: zero install and first-party. It ranks second because it does not report a missing final newline (`E3b` exits 0 on the same change `E3` rejects). It also needs a second declaration of both exceptions that must track `.editorconfig`, and it checks no charset. `raw/opus.md` executed the same three weaknesses.
- **Tradeoffs.** It is a Go release binary, the first occupant of R42's residue slot. R42's rule is "a release-only tool must justify itself" (R42 `DECISION.md:29`). The justification: no crates.io tool does this job at usable maturity, and the formatter fold leaves the non-Rust gap. v4.0.0 (2026-09-03) shipped breaking changes, including the executable rename and dropped `.ecrc` discovery. The template starts on v4 and inherits none of them, but that cadence is why the version is pinned.
- **Confidence: medium-high.** Behaviour is executed. Acquisition is not: `ubi` 0.12.0 resolving the `darwin-all` asset is unverified (`raw/opus.md:441`), because `ubi` is not installed on this host.

#### 2 — `ryl` 0.22.0 (F168)

- **Dominant choice and field.** In the category overall, `yamllint` dominates: 3,467 stars, v1.38.0 of 2026-01-13, and 128 open issues (`r40-figures.log`). It is **excluded by fit with R42, not by gate** (see Disagreement 1). That leaves `ryl` as the Rust choice. It has 4,750 downloads in 90 days, more than every other Rust YAML linter combined.
- **Figures** (`r40-figures.log`): 90-day downloads 4,750; all-time 8,802; newest non-yanked 0.22.0, `created_at` 2026-09-06T13:24:10Z; 80 stars; `archived: false`; `pushed_at` 2026-09-25T00:15:36Z; 43 open issues. Of the 10 newest issues, 3 were opened by the owner. Of the 7 others, 1 got a maintainer response (3.57 days) and **6 are unanswered**. Adopter: `rvben/rumdl` runs it through pre-commit (`raw/opus.md`; not re-read here). Maintenance state: **active**, with a sole-maintainer concentration risk.
- **Gates.** Gate 2 is qualified. The 0.22.0 crate record declares no `rust_version`, and its `Cargo.toml` at the tag declares only `edition = "2024"`. `main` declares `rust-version = "1.98.1"` (`r40-figures.log`), so the next release is expected to require current stable to build from source, above the 1.96 floor. On this host it built from source in 40 s on 1.98.1 (`r40-install.log`); no build at 1.96 was attempted. Gate 3: `rustsec.org/packages/ryl.html` returns 404, so no advisory has been published. `raw/opus.md` read `#![forbid(unsafe_code)]` on `main`, which this synthesis did not re-read. Gate 4 is qualified: the full suite runs on `ubuntu-latest` only (`ci.yml:6`), and macOS is covered by a release smoke job (`release.yml:327`). Gate 5: the default feature `lsp` adds a language server; no async runtime is involved.
- **Behaviour executed** (`r40-yaml.sh`, 19 of 19 assertions, each case run through both `ryl` 0.22.0 and `yamllint` 1.38.0 with the same `.yamllint`):

  | Case | Result |
  |---|---|
  | Clean workflow with an `on:` key and a one-space SHA-pin comment | both pass (`Y1`) |
  | Duplicated key in `dependabot.yml` | both fail, `key-duplicates` (`Y2`) |
  | Whole-tree walk from the root | both reach hidden `.github/` (`Y3`) |
  | `enabled: yes` | both flag `truthy` (`Y4`) |
  | Spacing violations | both fail (`Y5`) |
  | Missing final newline | both fail (`Y6`) |
  | Gitignored `target/` holding invalid YAML | skipped by `ryl .` (`Y9`) |

  The `truthy` case answers `raw/opus.md:516`'s open question: ryl's YAML 1.2 semantics do not hide YAML 1.1 truthy values from the rule. The same YAML file went through the formatter's lint mode, `yamlfmt 0.17.2 -lint`, which exits 0 on the duplicated key (`Y2f`). That confirms the gap a formatter leaves.
- **A correction to both legs' configs.** Under `extends: default`, `truthy` is a *warning*, so `enabled: yes` is reported and exits 0 in both tools (`Y4`). A staged truthy value would pass the hook. The synthesis config sets `truthy.level: error`, which fails in both tools (`Y4e`) and still passes the workflow `on:` key (`Y4c`). With no config, `ryl` refuses to run (exit 2, "ryl enables no rules by default", `Y8`), so the committed `.yamllint` is required. It is not optional. `comments.min-spaces-from-content: 1` keeps R20's one-space `# vX.Y.Z` pin comment (R20 `DECISION.md:70`) silent; without it, both tools warn (`Y7`).
- **Recommendation.** Adopt, with the config above. Hook: glob `*.{yml,yaml}`, `ryl {staged_files}`; this glob selects nested files such as `.github/dependabot.yml` (`C3`). CI: a `hygiene` step, `ryl .`. The config is in yamllint's format, so switching back to `yamllint` changes one executable name.
- **Ranked runner-up.** `yamllint` 1.38.0 with the identical `.yamllint`, whose verdicts match on every case tested. Adopting it requires the owner to reopen R42 for a Python acquisition path. Second runner-up: no dedicated YAML lint. That leaves a measured gap: duplicate keys in non-workflow YAML pass (`Y2f`).
- **Tradeoffs.** 0.x, a sole maintainer, 6 of 7 recent non-owner issues unanswered, one adopter, macOS covered only by smoke tests, and a source-build MSRV rising to current stable. In exchange: acquisition under R42 with no new runtime, and a config file that stays valid for `yamllint`.
- **Confidence: medium on the tool, high on the capability.**

#### 3 — `typos-cli` 1.50.3 (F169)

- **Dominant choice and field.** `typos-cli`, executable `typos`. It leads both raws' surveys; `raw/opus.md` counts 10 of 16 repositories, including rust-lang/rust, cargo, rust-analyzer, axum and clap. `codespell` is the incumbent in py and cannot be acquired through R42's backends (see Disagreement 1).
- **Figures** (`r40-figures.log`): 90-day downloads 114,493; all-time 1,002,583; newest non-yanked 1.50.3, `created_at` 2026-09-25T18:41:04Z, `rust_version` 1.95; 4,158 stars; `archived: false`; `pushed_at` 2026-09-25T18:41:08Z; 126 open issues. Responsiveness: 8 of 8 non-collaborator issues answered, with a median of 0.03 days; 0 unanswered. Maintenance state: **active**.
- **Gates.** Gate 2 passes: `rust_version` 1.95 is under the 1.96 floor, and the tool built from source in 36 s on 1.98.1. Gate 3: RustSec returns 404. Gate 4: the upstream matrix covers `ubuntu-latest`, `windows-latest` and `macos-latest` (`ci.yml:40`). Gate 5: the default features are bundled dictionaries; no runtime is involved.
- **Behaviour executed at 1.50.3** (`r40-typos.sh`, 11 of 11 assertions; both raws ran 1.32.0):

  | Case | Result |
  |---|---|
  | `recieve_porjects(ans)` | both misspellings found; `ans` not flagged (`T1`) |
  | Whole-tree walk, no config | **skips hidden `.github/`** (`T2a`) |
  | Explicit path into `.github/` | reports the misspelling (`T2b`) |
  | Walk with `ignore-hidden = false` | reaches `.github/` and not `.git/` (`T2c`) |
  | Excluded path passed explicitly | checked without `--force-exclude` (`T3a`), skipped with it (`T3b`) |
  | Deliberate spelling in `extend-words` | allowed (`T4`) |

  The walk config is therefore required for hook/CI parity. `raw/opus.md:692` observed the hidden-directory behaviour at 1.32.0, and it holds at 1.50.3.
- **Recommendation.** Adopt, with `typos.toml` as above. Hook: `typos --force-exclude {staged_files}`. CI: a `hygiene` step, `typos`. The file is named `typos.toml`, not `raw/muse.md`'s `_typos.toml`. Both names are discovered, and `typos.toml` is the form rust-lang/rust, cargo, bevy, clap and nushell use (per `raw/opus.md`'s survey, not re-read here).
- **Ranked runner-up.** `codespell` 2.4.2, only if the owner reopens R42 for Python. It missed the identifier misspelling in `T1`.
- **Confidence: high.**

#### 4 — `actionlint` 1.7.12 (F170)

- **Dominant choice and field.** It is the only tool that type-checks workflow keys, `needs` edges and expressions. `zizmor` audits workflow security and belongs to R20. `action-validator` checks the JSON schema only, which `raw/opus.md` excludes by capability.
- **Figures** (`r40-figures.log`): 4,265 stars; `archived: false`; `pushed_at` 2026-07-16T06:05:57Z; latest release v1.7.12 of 2026-03-30T17:49:21Z; 143 open issues. **Commits on `main` since 2026-04-20: 0**, and the newest is `011a6d15e749` of 2026-04-19. The 10 newest issues, 2026-08-04 to 2026-09-23, are **10 of 10 unanswered**. Maintenance state: **at-risk** (see Disagreement 5).
- **Gates.** 2, 3 and 5: inapplicable (a Go binary). Gate 4: the upstream matrix includes `ubuntu-latest` and `macos-latest` (`ci.yaml:9`). Gate 6: prebuilt, with no compile cost.
- **Behaviour executed** (`r40-actionlint.sh`, 17 of 17 assertions):

  | Case | Result |
  |---|---|
  | Missing `runs-on` | fails (`A2`) |
  | Duplicated `runs-on` | fails (`A3`) |
  | Typo in an event-payload property | not caught (`A4`), a stated limit |
  | Only a local action's `action.yml` changes | unchanged workflow fails (`A5`) |
  | Only `.github/actionlint.yaml` changes | unchanged workflow fails (`A6`) |

  `A5` and `A6` re-execute R11's `R6-L2` and `R6-L3` (R11 `DECISION.md:189`).
- **Hook shape, decided by execution.** Three shapes ran side by side under lefthook 2.1.14:

  | Shape | Glob | Command | Runs when only `action.yml` changes (`A5`) | …only `actionlint.yaml` (`A6`) | …only `dependabot.yml` (`A7`) |
  |---|---|---|---|---|---|
  | py's (`raw/muse.md`) | `.github/workflows/*.{yml,yaml}` | `actionlint {staged_files}` | skipped | skipped | skipped |
  | `raw/opus.md`'s | `.github/**/*.{yml,yaml}` | `actionlint` | runs, blocks | **skipped** | **skipped** |
  | this decision's | list: `.github/*.{yml,yaml}`, `.github/**/*.{yml,yaml}` | `actionlint` | runs, blocks | runs, blocks | runs, passes |

  Under lefthook's default matcher, `**` does not match zero directories. So `raw/opus.md`'s single glob misses files directly under `.github/`, including `actionlint.yaml`, the very case it was widened for. `raw/opus.md:855` reported the job as selected for a staged `dependabot.yml`; in `A7` it was not. The two-entry list is per-job and leaves R37's manager-level settings untouched. lefthook's global `glob_matcher: doublestar` option also fixed the single glob in a probe, but that setting is R37's.
- **Recommendation.** Keep it at both tiers, with the job above. CI: R11's `workflow-lint` job, gated on `workflows == 'true'` (R11 `DECISION.md:289`).
- **Ranked runner-up.** CI only, with no hook. It would save about 0.07 s per commit that touches `.github/` (`A8`) and let workflow errors reach a push. Not recommended.
- **Tradeoffs.** At-risk maintenance, with no drop-in replacement for expression type-checking. It is the second occupant of R42's residue slot, justified the same way as member 1. Its runner-label list is ageing, which R09's config can compensate for. `shellcheck` integration activates only when `shellcheck` is on `PATH`. Making `shellcheck` a required tool is an **unowned decision**, flagged for the controller as `raw/opus.md` flagged it.
- **Confidence: high on capability and tier, medium on longevity.**

#### 5 — `.editorconfig` baseline and exceptions (F191, F192)

- **Pattern, not crate.** Crate figures and gates 1–6 are **inapplicable**: this is a committed file in a standard format, with no package, release or advisory surface. Its reference implementations are rust-lang/rust, rust-analyzer, ruff and uv (table above).
- **Exceptions, each tied to a file type this template has.**
  - `[*.md]` keeps the hard break. py uses the same rationale (py `b08bccf` `.editorconfig:22-25`), and so does rust-lang/rust.
  - `[*.snap]` replaces py's `[*.ambr]`. R33 adopted `insta` 1.48.0 with committed file snapshots (R33 `DECISION.md:28`). Executed in `r40-insta.sh`, 8 of 8 assertions: insta writes `src/snapshots/<name>.snap`, which settles `raw/muse.md:775`'s gap G4 on the extension. A snapshot line ending in two spaces passes (`I2`). The same file with each line's trailing spaces trimmed, as an editor would, **fails** `cargo test` (`I3`). Trailing spaces added only to the body's final line pass (`I4`). This matches insta's source: `normalize` applies `trim_end()` to the whole body only, and `matches_fully` compares contents byte for byte (`insta/src/snapshot.rs:645-646`, `:753-765` at tag 1.48.0, re-read in `r40-citations.log`).
  - `[Makefile] indent_style = tab` is kept. It costs nothing, a Makefile requires tabs, and both py (`.editorconfig:19-20`) and rust-lang/rust carry it.
  - Not carried: `[*.ambr]` (syrupy, Python-only) and py's `[*.py]`.
- **Where each exception binds.** `[*.md]` binds both editors and member 1: the hard break passes the checker (`E1`) and is exempted from editor trim. `[*.snap]` binds editors only, because member 1 never reads `.snap` files (default exclude; `I5n` passes without the stanza, and `I5d` fails without it once defaults are ignored). The stanza is still needed, because the failure it prevents happens at edit time (`I3`).
- **Recommendation.** Commit the file above. `max_line_length` is not set, because R27 owns Rust line width.
- **Ranked runner-up.** No `.editorconfig` (ts's shape). It loses edit-time behaviour for unformatted file types and leaves member 1 without input.
- **Confidence: high.**

### Principles and implementation

**The shared principle.** `docs/port/DIVERGENCE-ANALYSIS.md:164` classes R40 as cause class **D**: "For each of the 4 tools: does the value justify adoption for Rust, independent of language". Line `:165` classes F167 as class **C**: "Does rustfmt plus the chosen non-Rust-file formatter already cover trailing-whitespace/EOF-newline for every staged file type". The two raws state the principle in nearly the same words, and this synthesis adopts their common content:

> Every committed text file is checked mechanically, before commit and again in CI, against properties that formatters and compilers do not check: a declared whitespace, line-ending and charset baseline; YAML structural soundness; spelling; and workflow type-correctness. The baseline is declared once, in a file editors also read, and each exception is documented in that file.

**Agreement level: capability plus policy, not tool.**

| Must agree across py, ts and rs | May vary by ecosystem |
|---|---|
| Each of the four properties is gated at hook tier and again in CI | Which executable checks each property |
| One editor-readable file declares the baseline and its exceptions, each with an inline reason | The exception list, which follows each repository's file types (`.ambr` in py, `.snap` here) |
| A missing tool fails loudly, never a silent pass | How tools are acquired: py through `uv`, rs through R42's crates.io and `ubi` backends |
| The CI whole-tree run checks what the hook checks, hidden directories included | Hook-manager specifics (R37) |

**Essential behaviours, with the executed check for each.**

| # | Criterion | Executed |
|---|---|---|
| 1 | A staged text file with trailing space, a missing final newline or CRLF endings fails, unless `.editorconfig` exempts its type | `E2`–`E5`, `C3` |
| 2 | A Markdown hard break passes the checker; an insta snapshot line keeps its trailing spaces through editing | `E1`, `I2`–`I3`, `C5` |
| 3 | A YAML file with a duplicate key or a YAML 1.1 truthy value fails, workflow or not | `Y2`, `Y3`, `Y4e`, `C3`, `C4` |
| 4 | A misspelling inside an identifier, a comment or a workflow fails; a deliberate spelling can be allowed in one file | `T1`, `T2b`, `T4`, `C3` |
| 5 | A workflow with a duplicated key, an unknown `needs` target, or a mismatch with a changed local action or linter config fails | `A3`, `A5`, `A6`, `C3` |
| 6 | The CI whole-tree run and the hook agree, and `.github/` is not skipped by either | `C3` against `C4`; `T2c`, `Y3` |
| 7 | A missing tool fails the hook with a non-zero exit | `C6` (exit 127) |

**Architectural alternatives for F167, compared before tools.** F167 is the only row with a genuine architecture choice.

| # | Architecture | Where the baseline is declared | Verdict and evidence |
|---|---|---|---|
| A | One checker that reads `.editorconfig` (py) | `.editorconfig` only | **Selected**: one declaration, full coverage of tracked text (`E1`–`E7`) |
| B | `git diff --check` with `.gitattributes` | a second file that must mirror `.editorconfig` | Runner-up: misses a missing final newline (`E3b`); no charset check |
| C | Fold into formatters (ts, D-020(6)) | per-formatter config | Rejected: `Justfile`, shell scripts, `.gitignore`, licence files and snapshot fixtures fall outside any decided formatter, and R29 is open |
| D | In-repo tidy test (rust-lang/rust, rust-analyzer) | Rust code | Rejected: bespoke code every generated repository must maintain, and it runs in the compile tier |
| E | `prek` built-in hooks | `.pre-commit-config.yaml` | Rejected by fit: it would displace the hook manager, which is R37's to decide |

F168 has the same question in a smaller form: is a dedicated YAML lint needed once a formatter and `actionlint` exist? Yes. The formatter's lint mode passes a duplicated key (`Y2f`), and `actionlint` reads only workflows.

**How the design preserves the principle per ecosystem; this is the rationale for the py and ts follow-on.** py realizes the capability with Python-provisioned tools plus one release binary. rs realizes it with two crates.io tools and two release binaries, all through R42's single tool table. R42 excludes a Python acquisition path (R42 `DECISION.md:28`, layer 3 "None"; `:29`, the residue rule), and that is why the tool names differ. ts lacks all four capabilities at its ledger pin. For spell check, YAML lint and `.editorconfig`, the divergence analysis records **no reason**, so that is drift. For F167, ts has a recorded partial reason: its formatter folds whitespace fixing for the formats it formats. ts has since wired `actionlint` at `e5100b4` (the F170 finding above).

**Minimal realistic example**, executed as `r40-compose.sh` (19 of 19 assertions). It is one repository with every file above, a workflow, `dependabot.yml`, an issue form, a Rust source file, a README with a hard break and an insta-format snapshot, with all four tools on `PATH` at the recommended versions. The example shows:

- lefthook accepts the config (`C1`), and the clean tree passes all four CI commands (`C2`).
- One staged defect per member (a trailing space in `Justfile`, a duplicated `schedule` key, `recieve` in a workflow comment, and `needs: nope`) fails each of the four hook jobs (`C3`).
- The same defects fail each of the four CI commands (`C4`).
- Reverting passes both, including a newly staged hard break (`C5`).
- Removing the crates.io tools from `PATH` fails the hook with exit 127 (`C6`).

### Compatibility

The members share no library, runtime or config file. The only coupling is `.editorconfig` → `editorconfig-checker`. Joint operation is executed, not inferred: `r40-compose.sh` runs all four tools at their pinned versions under one lefthook `pre-commit` stage with `parallel: true`. Every job reported its own defect and no job reported another's (`C3`). Partial matrices in the wild, per `raw/opus.md` and not re-read here:

- astral-sh/ruff runs `.editorconfig` with `[*.snap]`, typos and actionlint 1.7.12.
- rvben/rumdl runs ryl and actionlint.
- py runs all four capabilities with its own tool set.

Overlap is benign. The trailing-space and final-newline rules fire in both `editorconfig-checker` and `ryl` on a YAML file. That can produce a duplicate message, never a contradiction (`C3` shows only the rule each defect targets).

### Migration implications

| File in the template (P03) | Change | Member |
|---|---|---|
| `.editorconfig` | add, with the content above | 5 |
| `.editorconfig-checker.json` | add: `Version` `v4.0.2`; `Indentation` and `IndentSize` disabled | 1 |
| `.yamllint` | add, with the content above, including `truthy.level: error` | 2 |
| `typos.toml` | add: `ignore-hidden = false`, `extend-exclude = [".git/"]` | 3 |
| `lefthook.yml` | add the four `pre-commit` jobs above; R37 owns the rest of the file | 1–4 |
| `Justfile` tool table (R42) | add `typos-cli@1.50.3` and `ryl@0.22.0` (crates.io form), and `editorconfig-checker/editorconfig-checker@v4.0.2` and `rhysd/actionlint@v1.7.12` (`ubi` form) | 1–4 |
| `.github/workflows/ci.yml` | three `hygiene` steps (`editorconfig-checker`, `ryl .`, `typos`); `workflow-lint`'s `actionlint` step is R11's | 1–4 |

Not carried from py: the `uv run` prefixes (R42), the `ec` executable name and `-config` flag, `[*.ambr]`, `[tool.codespell]`, and the Python-cache entries of py's `Exclude` and `ignore` lists. Two carry-overs are deliberate: a deliberate misspelling goes into `[default.extend-words]` (`T4`), and a committed `.yamllint` is required, because `ryl` enables nothing without one (`Y8`).

### Validation strategy

**Executed in this synthesis** (macOS arm64 only): every row of the criteria table above. The command lines and outputs are under `## Empirical check`.

**Planned for P03, on both `ubuntu-latest` and `macos-latest`**, each with its expected result:

```bash
editorconfig-checker && ryl . && typos && actionlint        # clean template: exit 0
just install-tool ryl@0.22.0 && just install-tool typos-cli@1.50.3
# expect cargo-binstall to fetch a prebuilt artifact, or report that it compiles and how long it takes
ubi --project editorconfig-checker/editorconfig-checker --tag v4.0.2 --in ./bin
ubi --project rhysd/actionlint --tag v1.7.12 --in ./bin     # both assets resolve on both runners
lefthook run pre-commit                                      # after staging each r40-compose.sh C3 defect: same verdicts as CI
cargo insta test                                             # after an editor save of a .snap file: no diff
```

`cargo binstall` and `ubi` are named here in R42's recipe forms; their exact spellings are R42's. No hosted run, no `cargo binstall`, no `ubi` resolution and no MSRV-floor build was executed.

re-verify: 2027-03-26, or earlier on any of — any `ryl` release, which moves its source-build MSRV and possibly its config compatibility; `ryl` going 90 days without a release, or its first `cargo binstall` in P03 compiling from source instead of fetching a prebuilt; a new `actionlint` release or maintainer notice, which resets the at-risk assessment, or a GitHub workflow feature `actionlint` rejects; `editorconfig-checker` v5, or any change to its default excludes; `ubi` failing to resolve the `darwin-all` or `linux-amd64` asset on either runner; a `typos` 2.x release or a change in its `ignore-hidden` default; R29 publishing a formatter that covers every tracked file type, which reopens F167 architecture C, or choosing a TOML or YAML indent that disagrees with `.editorconfig`; R29 adopting a Markdown formatter that rewrites hard breaks, which would retire `[*.md]`; R33 moving to inline snapshots, which needs a per-file exception like uv's `[crates/uv/tests/help.rs]`; R37 choosing a hook manager other than lefthook, a CI re-run of the hook suite (which places these jobs inside `hygiene` per R11 `DECISION.md:292`), or a global `glob_matcher`; R09 publishing `actionlint` config content; the owner or controller deciding whether `shellcheck` is a required tool; the owner reopening R42 for a Python acquisition path, which would make `yamllint` and `codespell` eligible again; or the controller reconciling the Muse-for-Codex seat substitution recorded above.

## Parameters

R40 owns no registry parameter: the binding prompt's `## Couplings` block carries an empty `- owns:` line. It consumes R11's `ci-job-structure` and R42's `package-manager-invocation`, named on its `- consumes:` line, and the four fixed parameters. Each `assumes` line below reproduces the registry value byte for byte from `inputs/parameters.json`.

- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner
- assumes package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**How the consumed values are used.** Under `ci-job-structure`, the three non-compiling checks with inputs outside the workflow tree are steps of `hygiene`: "a check that compiles nothing is a step of `hygiene`" (R11 `DECISION.md:278`). `actionlint`, whose whole input is the workflow tree, is the one occupant of `workflow-lint` (`:289`). Under `package-manager-invocation`, every member is a bare executable on `PATH`: `editorconfig-checker`, `ryl`, `typos` and `actionlint`. None is `cargo-<sub>`, none takes a prefix, no Cargo alias is defined, and presence is tested with `command -v`. `typos` is the executable of the crate `typos-cli`, so it is invoked as `typos`, never `cargo typos`.

**No `CONFLICT:` line.** No consumed value needs to change. The two release-only tools enter R42's `ubi` residue slot, which R42 reserves for R37, R39 and R40 (R42 `DECISION.md:29`) and which it expects R40 may activate (`:470`, `:1701`). That is the slot's documented use and changes no parameter value. The registered `package-manager-invocation` value itself defines presence only for "a tool installed from crates.io or from a release" and for rustup components. A Python tool acquired through `pipx` is covered by neither, which is part of why `yamllint` and `codespell` are excluded by fit (Disagreement 1).

## Empirical check

**Host and toolchain, every version read from the tool.** macOS 26.4, `Darwin 25.4.0 arm64`. `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`. Private `CARGO_HOME=/tmp/cargo-s9r-R40`. Tools under test: `editorconfig-checker` v4.0.2 (release asset through `api.github.com`), `ryl` 0.22.0 and `typos-cli` 1.50.3 (both `cargo install --locked` into the private `CARGO_HOME`, each built into an empty target directory), and `actionlint` 1.7.12. Instruments: `yamllint` 1.38.0, `codespell` 2.4.2, `yamlfmt` 0.17.2, `lefthook` 2.1.14 and `shellcheck` 0.11.0 (`r40-install.log`). **This is the local stable toolchain, not the MSRV floor**, and no run used `ubuntu-latest`.

**Commands and working directory.** Every script lives in `review/evidence/`, is `shellcheck`-clean, and works in its own `mktemp -d` scratch repository under `/tmp`, never inside this repository. The one fresh ordered pass was run from the repository root:

```bash
bash research/runs/R40/2026-09-26T190249Z-a9da32655556/review/evidence/r40-rerun-all.sh \
  > research/runs/R40/2026-09-26T190249Z-a9da32655556/review/evidence/r40-rerun-all.log 2>&1
```

It uninstalls the scratch tools, runs `shellcheck` over all 10 scripts, then runs each script into its `.log`.

| Script | Assertions | What it establishes |
|---|---|---|
| `r40-install.sh` | records | tool builds (`typos-cli` 36 s, `ryl` 40 s) and the ec asset; the 4.0.2 tarball holds `editorconfig-checker` and no `ec` |
| `r40-ec.sh` | 14/14 | member 1's behaviour, the `v`-prefixed pin (`E0`, `E6`), untracked vs gitignored files (`E8`, `E8b`), the runner-up's missed final newline (`E3b`) |
| `r40-yaml.sh` | 19/19 | `ryl` and `yamllint` parity on one config, `truthy` warning vs error (`Y4`, `Y4e`), the formatter gap (`Y2f`), the walk over `.github/` and gitignored `target/` (`Y3`, `Y9`) |
| `r40-typos.sh` | 11/11 | `typos` 1.50.3 vs `codespell` 2.4.2 on identifiers, hidden directories, `--force-exclude`, `extend-words` |
| `r40-actionlint.sh` | 17/17 | the three hook shapes under lefthook (`A5`–`A7`), R11's `R6-L2`/`R6-L3` re-executed, timings |
| `r40-insta.sh` | 8/8 | an editor trim breaks an insta 1.48.0 snapshot (`I3`); `.snap` is an ec default exclude (`I5n`, `I5d`) |
| `r40-compose.sh` | 19/19 | the minimal realistic example, the hook/CI parity, the missing-tool failure |
| `r40-figures.sh` | records | every figure quoted above, from the named endpoints |
| `r40-citations.sh` | 104/104 | every `file:line` this decision cites, including sibling repositories at their pins and upstream sources, and every output line quoted below |

**Observed output, the lines the decision turns on.** Each line below is copied from the named log with only its leading indentation removed:

```text
r40-install.log     no executable named ec in the 4.0.2 darwin-all tarball
r40-ec.log          Version from config file is not the same as the version of the binary
r40-ec.log          Binary: v4.0.2, Config 4.0.2
r40-yaml.log        2:12      warning  truthy value should be one of [false, true]  (truthy)
r40-yaml.log        2:12      error    truthy value should be one of [false, true]  (truthy)
r40-typos.log       files walked containing .github: 0
r40-actionlint.log  │  opus-shape (skip) no matching staged files
r40-actionlint.log  ┃  synth-shape ❯
r40-insta.log       snapshot assertion for 'help_snapshot' failed in line 11
r40-insta.log       error: test failed, to rerun pass `--lib`
r40-compose.log     PASS C3-actionlint-failed (output contains: ✗ actionlint)
r40-figures.log     commits on main since 2026-04-20: 0
r40-figures.log     non-maintainer issues=10 responded=0 unanswered=10 median_days_to_first_maintainer_response=n/a (maintainer-opened, excluded=0)
```

The two `r40-yaml.log` lines come from `Y4` (warning, exit 0) and `Y4e` (error, exit 1). The two `r40-actionlint.log` lines come from `A6`, which stages only `.github/actionlint.yaml`. The `r40-insta.log` lines come from `I3`, the trimmed snapshot.

**Totals of the fresh pass** (`r40-rerun-all.log`): `shellcheck` is clean over all 10 scripts. All 9 evidence scripts exited 0, and the 7 asserting scripts passed 192 of 192 assertions (14 + 19 + 11 + 17 + 8 + 19 + 104). The other two scripts record the tool builds and figures and make no assertions. No assertion failed.

**What no check here establishes.** No run on `ubuntu-latest`. No build at the 1.96 MSRV floor: the host has Homebrew's toolchain and no `rustup`. No `cargo binstall` run, so whether `ryl` and `typos-cli` publish prebuilt artifacts that `cargo-binstall` 1.23.0 resolves is unknown. No `ubi` run, so asset resolution for both Go tools is unknown. No run inside R37's eventual hook configuration. The 16-repository practice survey and the adopter lists are `raw/opus.md`'s, not re-run. These are listed for P03 under `## Engines`.

## Engines

**Reports.**

- **Muse (Meta)**, `raw/muse.md`, sha256 `4d7c2634…`. Actor `research-muse-2026-09-26T190249Z-a9da32655556`; the report names the engine family and no model snapshot (`raw/muse.md:3`, `:17`). Written 2026-09-26. It filled the Codex seat without an `engine_overrides` entry; see the provenance note at the top. It recommends `editorconfig-checker` (invoked `ec -config`), `yamllint` through a `pipx`-isolated install, `typos` replacing `codespell`, and `actionlint` at both tiers on staged workflow files. It adds `.editorconfig` with `[*.md]` and `[*.snap]`. It raises no `BASELINE-REVIEW:` and no `CONFLICT:`. It executed typos 1.32.0, actionlint, yamllint and codespell; it did not execute `editorconfig-checker` (its gap G3).
- **Claude Opus**, `raw/opus.md`, sha256 `4be5d4d1…`, model `claude-opus-5-5` (family anthropic). Written 2026-09-26. It recommends `editorconfig-checker` (invoked by its v4 name), `ryl` through `cargo binstall`, `typos-cli` with `ignore-hidden = false`, and `actionlint` at both tiers with no file arguments. It adds `.editorconfig` with `[*.md]` and `[*.snap]`. It raises three `BASELINE-REVIEW:` lines and no `CONFLICT:`. It did not execute `editorconfig-checker` or `ryl` (exit 127 in its example).

Both raws agree on the capability set, the agreement level, `editorconfig-checker`, `typos`, `actionlint` at both tiers, `.editorconfig` with `[*.md]` and `[*.snap]`, and no `CONFLICT:`. Each disagreement below is settled by the evidence named.

**Disagreement 1: `yamllint` (`raw/muse.md`) or `ryl` (`raw/opus.md`) for F168; and `codespell`'s status. Settled for `ryl`, by R42 fit plus executed parity.** `raw/muse.md` keeps `yamllint` on maturity: "the only mature YAML linter in any language". It acquires it through a "pipx-style isolated install" invoked as a bare executable (`raw/muse.md:187`, `:360`). The invocation half fits the registered `package-manager-invocation` value. The acquisition half does not fit R42's decision:

- R42 has exactly two sanctioned backends: crates.io through the generic `cargo binstall` recipe (`DECISION.md:27`) and `ubi` for release-only tools (`:29`).
- R42 names **no** provisioner layer (`:28`).
- The registered value defines presence only for crates.io, release and rustup tools.

`yamllint` and `codespell` are PyPI-only, so neither backend can provision them (`raw/opus.md:550`). A `pipx` path is therefore a third backend R42 did not sanction. Adopting it would reopen R42, which is the owner's call, not a consumer's. Muse's maturity argument is real, so it is carried as `ryl`'s risk, not dismissed. The fit argument alone would not suffice if `ryl` behaved worse, so this synthesis executed both tools on one config. Their verdicts match on every case (`Y1`–`Y7`), and `ryl` handles the gitignored walk (`Y9`). `codespell` falls under the same fit exclusion. On function it also misses the identifier misspelling (`T1`). `raw/muse.md`'s licence ground for the `codespell` replacement is void under Q7.B.

**Disagreement 2: the `editorconfig-checker` executable. Settled for `raw/opus.md`.** `raw/muse.md` specifies `ec -config .editorconfig-checker.json {staged_files}` (`:275`, `:915`), copied from py (py `b08bccf` `lefthook.yml:82`). The 4.0.2 tarball contains only `editorconfig-checker` (`r40-install.log`), and the v4.0.0 notes read "rename ec to editorconfig-checker". Muse's hook body would exit 127 on every commit. The single-dash `-config` flag itself still works (`E9`). It is dropped anyway, because the config file is discovered with no flag (`E0` reads it).

**Disagreement 3: the `Version` pin value. Neither leg was right; settled by execution.** `raw/muse.md` sets no pin. `raw/opus.md` pins `"Version": "4.0.2"` (`:356`, `:1173`). The 4.0.2 binary reports itself as `v4.0.2` and compares literally, so `"4.0.2"` makes it **refuse to run on a clean tree** (`E0`). `"v4.0.2"` passes (`E1`), and a mismatched `"v4.0.1"` refuses (`E6`). The README's configuration table does not state the format. The pin is kept for the reason `raw/opus.md` gives: a v4 series that shipped breaking changes within 16 days.

**Disagreement 4: `editorconfig-checker`'s file selection. `raw/opus.md`'s README reading corrected.** `raw/opus.md` quotes the README as checking "all files which are added to the git repository". The no-argument run also checks an untracked, not-ignored file (`E8`); it skips a gitignored one (`E8b`). CI works on a fresh checkout, so the recommendation does not move. The behaviour is recorded so that local whole-tree runs are not misread.

**Disagreement 5: `actionlint`'s maintenance state, `stable-quiet` (`raw/muse.md:630`) or `at-risk` (`raw/opus.md:888`). Settled as `at-risk`.** The rubric requires a concrete signal for `at-risk`, and `r40-figures.log` supplies two: 0 commits on `main` since 2026-04-19, and 10 of the 10 newest issues without a maintainer response. `raw/muse.md` sampled 5 non-PR issues and read `pushed_at` 2026-07-16 as activity. That timestamp is later than `main`'s newest commit, so it reflects a push elsewhere, consistent with `raw/opus.md`'s branch reading. It is not `dormant`: there is no unpatched advisory, no broken build and no maintainer notice. The recommendation does not move, because no replacement offers expression type-checking.

**Disagreement 6: `actionlint`'s hook shape. Neither leg's shape is correct; settled by execution.** `raw/muse.md` keeps py's staged-files job on `.github/workflows/*` (`raw/muse.md:681-684`). `raw/opus.md` widens to `.github/**/*` with no file arguments (`raw/opus.md:855`), on R11's executed finding that a workflow's verdict moves with a local action or the linter config (R11 `DECISION.md:189`). Under lefthook 2.1.14, Muse's shape skips both of those changes (`A5`, `A6`). Opus's shape catches the `action.yml` change but skips `.github/actionlint.yaml` and `.github/dependabot.yml`, because `**` does not match zero directories (`A6`, `A7`). Opus reported the `dependabot.yml` selection as executed; the likely explanation is that its staged workflow file carried the job. The two-entry glob list is the only shape that runs on all three (`A5`–`A7`).

**Disagreement 7: `typos` configuration. Settled for `raw/opus.md`, re-executed at 1.50.3.** `raw/muse.md` seeds an `_typos.toml` with vocabulary only. `raw/opus.md` requires `ignore-hidden = false` and `--force-exclude` (`raw/opus.md:692`). At 1.50.3, the default walk skips `.github/` (`T2a`) while the explicit hook path does not (`T2b`). Without the setting, hook and CI disagree on workflow files, which violates criterion 6. The file name follows the majority form among Rust-project adopters.

**Disagreement 8: `.editorconfig` details. Settled by reference reads.** `raw/muse.md` keeps py's TOML indent 2 and `[Makefile]`. `raw/opus.md` drops TOML from the indent-2 set and adds `[Makefile]` only if a Makefile ships. TOML indent 4 follows three of the four Rust-project references read (`### Landscape`). `[Makefile]` is kept because a Makefile requires tabs and the stanza is inert otherwise; rust-lang/rust carries it too.

**Disagreement 9: whether `[*.snap]` is needed, and what it protects. Both legs asserted it; this synthesis executed it and corrected its scope.** Both legs assumed `editorconfig-checker` would read `.snap` files. It does not: `.snap` is a default exclude (`I5n`). The stanza is still required, because an editor trim breaks the snapshot test (`I3`). Its protection is editor-side, and the stanza's comment says so. `raw/muse.md`'s gap G4, the extension, is closed: insta 1.48.0 writes `.snap` files (`I1`).

**Disagreement 10: `truthy` severity. Neither leg noticed; settled by execution.** Both configs leave `truthy` at the default preset's warning level, which exits 0 (`Y4`), in `yamllint` and `ryl` alike. The synthesis config raises it to `error` (`Y4e`, `Y4c`).

**Disagreement 11: presence guards in hook bodies.** `raw/muse.md` wraps each job in a `command -v` guard that prints install guidance, as py does (ADR-0018). `raw/opus.md` uses bare invocations. The bare body is selected. A missing tool already fails loudly with exit 127 (`C6`). R42 places the remediation string in its presence check (`check-deps`), and wrapping hook bodies is a hook-manager convention R37 may still add. No criterion depends on the wrapper.

**Disagreement 12: `.github/actionlint.yaml`.** `raw/muse.md` has R40 ship a minimal skeleton. `raw/opus.md` leaves the file to R09. The prompt assigns its content to R09 (`## Out of scope`), and R11's `workflows` key already contains it whenever it exists. R40 adds no such file.

**Disagreement 13: source pins.** `raw/muse.md` read py at `b08bccf` and ts at `cb1cbcb`, the ledger pins (`docs/port/COMMONALITY.md:3`). `raw/opus.md` read py at `b55b8c2` and ts at `e5100b4`, noting that the prompt's line numbers moved. Both are consistent at their own pins (`r40-citations.log` checks both). This decision cites the ledger pins for ledger claims and `e5100b4` only for the F170 finding.

**Carried from the raws without re-execution.** `raw/opus.md`'s 16-repository survey counts and adopter lists. Its `git diff --check` and `rustfmt` runs, with the same conclusion this synthesis reached for B at `E3b`. `ryl`'s `forbid(unsafe_code)`. `ecformat`, `prek`, `codebook-lsp`, `action-validator` and `truss-cli` figures. `raw/muse.md`'s crates.io YAML-linter search figures, which agree with `raw/opus.md`'s where both report them.

**Uncertainty that remains.** The `ryl` pick carries real maturity risk: 0.x, a sole maintainer, and 6 of 7 recent non-owner issues unanswered. It also carries an MSRV trend toward current stable on the source path. Its prebuilt availability through `cargo-binstall` is unmeasured. `actionlint` is `at-risk`, with no replacement. Neither Go tool's `ubi` acquisition has run. Everything ran on one macOS host.

**What P03 must validate:**

1. All four CI commands and the lefthook stage on `ubuntu-latest` and `macos-latest`.
2. `cargo binstall` of `ryl@0.22.0` and `typos-cli@1.50.3`, prebuilt or compiled, with timing.
3. `ubi` resolving `editorconfig-checker-darwin-all.tar.gz` and `-linux-amd64.tar.gz`, and both `actionlint` assets.
4. A build of both crates at the 1.96 floor, or a documented reliance on prebuilt artifacts.
5. The `r40-compose.sh` defect set replayed inside R37's real `lefthook.yml`.
6. `cargo insta test` after an editor save of a `.snap` file.
7. An owner or controller ruling on whether `shellcheck` is a required tool.
