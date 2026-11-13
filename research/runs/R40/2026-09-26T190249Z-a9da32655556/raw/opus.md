# R40 — auxiliary-hygiene-hooks (bundle, Focused) — Opus raw report

Engine: opus (`claude-opus-5-5`), independent leg. Item R40, kind `bundle`, ledger
rows F167, F168, F169, F170 (area `git-hooks-commit-hygiene`) and F191, F192 (area
`dev-experience-repo-hygiene`), all `DIVERGENT`, origin `py-only`. Run
`2026-09-26T190249Z-a9da32655556`. **All retrieval dates are 2026-09-26** unless a
line says otherwise. Every figure names the endpoint that produced it.

Source pins read for this report: py-launch-blueprint at `b55b8c2` (2026-09-22,
local checkout `~/c/py-launch-blueprint`); ts-launch-blueprint at `e5100b4`
(2026-09-15, HEAD) and at `cb1cbcb` (2026-09-01, the pin earlier decisions cite).
The prompt's py line numbers (`lefthook.yml:82/88/99/102`) have moved: at
`b55b8c2` the four jobs sit at `lefthook.yml:80` (editorconfig-checker), `:86`
(yamllint), `:97` (actionlint) and `:106` (codespell). This report cites the
current lines.

Label convention used throughout: **[executed]** means the command was run in this
leg on macOS (Darwin 25.4.0, Apple M4 Pro, 14 cores) and its output is quoted;
**[read]** means a maintainer source was read through `api.github.com` or
`crates.io`; **[proposed]** means a check or file is specified but was not run.

### Landscape

**The category this item decides.** Not a library choice. Nothing here is linked
into the template's crates. The category is *repository hygiene gates for
non-Rust-source properties of committed text*: four developer-machine and CI
binaries that run at the pre-commit tier, plus one declarative file
(`.editorconfig`) that editors read and one of the binaries enforces. Each of the
four hooks answers a different question about a committed file:

| Row | Question the gate answers | py's tool (py `lefthook.yml` line at `b55b8c2`) |
|---|---|---|
| F167 | Does every text file meet the declared whitespace, end-of-line, final-newline and charset baseline? | `editorconfig-checker` (`:80`), config `.editorconfig-checker.json` |
| F168 | Is every YAML file structurally sound: parseable, no duplicate keys, no ambiguous truthy values? | `yamllint` (`:86`), config `.yamllint` |
| F169 | Are prose, identifiers and file names free of known misspellings? | `codespell` (`:106`), config `[tool.codespell]` in `pyproject.toml:298` |
| F170 | Are GitHub Actions workflows type-correct (keys, expressions, `needs` edges, shell)? | `actionlint` (`:97`) |
| F191/F192 | What baseline do editors apply on save, and which file types are exempt? | `.editorconfig:3` `root = true`; exceptions `[*.md]` `:24`, `[*.ambr]` `:30` |

**Three-bin map of the Rust field** (candidates drawn from `crates.io` search
`GET https://crates.io/api/v1/crates?q=<term>` for `editorconfig`, `yamllint`,
`yaml lint`, `spell`, `typos`, `github actions`, `actionlint`, `whitespace`, plus
the tools the surveyed projects actually run):

| Capability | Built-in / first-party toolchain | Established industry standard | Up-and-comer |
|---|---|---|---|
| F167 whitespace/EOL validity | `rustfmt` (Rust files only); `git diff --check` with `core.whitespace` / `.gitattributes` (git itself); rust-lang/rust's in-repo `tidy` (`src/tools/tidy/src/style.rs`) and rust-analyzer's `xtask/src/tidy.rs` as the *in-repo test* pattern | `editorconfig-checker` (Go, MIT); `pre-commit-hooks` `end-of-file-fixer`/`trailing-whitespace` (Python) | `ecformat` (Rust, BlueOak-1.0.0, Codeberg); `prek` built-in hooks (Rust reimplementation of `pre-commit`) |
| F168 YAML structural lint | none — no Rust-project YAML linter | `yamllint` (Python, GPL-3.0); `pre-commit-hooks` `check-yaml` (Python) | `ryl` (Rust, MIT, 0.22.0); `yamllint-rs`, `yaml-lint`, `fast-yaml-linter` (all under 250 downloads/90 days) |
| F169 spell check | none | `typos-cli` (Rust, `crate-ci`); `codespell` (Python, GPL-2.0); `cspell` (Node) | `codebook-lsp` (Rust, code-aware, LSP-first) |
| F170 workflow lint | none | `actionlint` (Go, MIT); `zizmor` (Rust, security audit — R20's tool, a different question) | `action-validator` (Rust, GPL-3.0, JSON-schema only); `truss-cli` (Rust, 30 all-time downloads) |
| F191 editor baseline | none in Cargo; `rustfmt.toml` covers Rust only | EditorConfig (`editorconfig.org` spec) | — |

**Authorities used, and why each counts.**

- **Maintainers' own documentation**, read at source through `api.github.com`:
  `crate-ci/typos` `docs/reference.md` (config sources and precedence);
  `editorconfig-checker/editorconfig-checker` README and release notes for
  v4.0.0–v4.0.2 (default excludes, git-tracked-file behaviour, `--fix`, the v4
  rename); `owenlamont/ryl` README at `main` and `Cargo.toml` at `v0.22.0`;
  `mitsuhiko/insta` `insta/src/snapshot.rs` at tag `1.48.0` (commit
  `7f23d2e4684a789a85c50503004fb38a23c9ea58`). A maintainer's documentation is
  authoritative for what the tool does; it is not evidence of fitness.
- **Rust project and team practice**: `rust-lang/rust` (`.editorconfig`,
  `typos.toml`, `src/tools/tidy/src/style.rs` at
  `bec4db66e5f3d21e54da4a4ce4904eb58bce1aa0`), `rust-lang/cargo` (`typos.toml`,
  typos in `.github/workflows/main.yml`), `rust-lang/rust-analyzer`
  (`.editorconfig`, `.typos.toml`, `xtask/src/tidy.rs`). These are the Rust
  project's own repositories, so they show what the project itself enforces.
  `crate-ci` is the organisation of Ed Page, a Cargo team member; that is a
  maintainer-standing signal for `typos`, not a proof of quality.
- **The EditorConfig specification** at `editorconfig.org`, the only
  cross-editor standard in this category. Cited as the spec named in py's
  `.editorconfig:1`; not fetched (not a named endpoint for this topic).
- **The `crates.io`, `api.github.com` and `rustsec.org` endpoints** the prompt's
  figure table names, for every figure below.
- **Executed behaviour** of the tools themselves, used as instruments (the
  **[executed]** lines). No single blog post is used as an authority anywhere.

**Practice survey: what well-regarded Rust projects run.** Sixteen repositories,
chosen for standing (Rust project repositories, the most-starred Rust
applications, and the libraries a CLI + library + web template depends on). Star
counts are `stargazers_count` from `GET https://api.github.com/repos/<o>/<r>`.
Root files are from `GET https://api.github.com/repos/<o>/<r>/contents/`. Tool use
is from `GET https://api.github.com/search/code` with all sixteen `repo:`
qualifiers, one query per tool term; every query returned
`incomplete_results: false`. Code search indexes default branches only.

| Repository | Stars | `.editorconfig` | typos config / use | actionlint | yamllint | editorconfig-checker |
|---|---|---|---|---|---|---|
| rust-lang/rust | 119216 | yes | `typos.toml` | — | — | — (in-repo `tidy`) |
| denoland/deno | 108526 | yes | — | — | — | — |
| astral-sh/uv | 90201 | yes | `_typos.toml` | — | — | — |
| zed-industries/zed | 90933 | — | typos in `run_tests.yml` | `.github/actionlint.yml`, CI | — | — |
| BurntSushi/ripgrep | 68632 | — | — | — | — | — |
| sharkdp/bat | 60582 | — | — | — | — | — |
| astral-sh/ruff | 49805 | yes | `_typos.toml`, pre-commit | pre-commit v1.7.12 | — | — |
| bevyengine/bevy | 48404 | — | `typos.toml`, CI | — | — | — |
| helix-editor/helix | 46349 | — | — | — | — | — |
| nushell/nushell | 40580 | — | `typos.toml`, `typos.yml` workflow | — | — | — |
| tokio-rs/tokio | 33247 | — | — | — | — | — |
| tokio-rs/axum | 27259 | — | `[workspace.metadata.typos]` in `Cargo.toml`, CI | — | — | — |
| rust-lang/rust-analyzer | 16877 | yes | `.typos.toml`, CI | — | — | — (in-repo `tidy`) |
| clap-rs/clap | 16726 | — | `typos.toml`, pre-commit + `spelling.yml` | — | — | — |
| rust-lang/cargo | 15521 | — | `typos.toml`, `main.yml` | — | — | — |
| rust-lang/rustup | 7052 | — | — | — | — | — |

Totals: **typos 10 of 16**, `.editorconfig` 5 of 16, actionlint 2 of 16,
yamllint 0 of 16, editorconfig-checker 0 of 16. The two whitespace-enforcement
mechanisms observed are an **in-repo tidy test** (rust-lang/rust,
rust-analyzer) and **`pre-commit-hooks`** (ruff: `end-of-file-fixer`; clap:
`check-yaml`, `check-toml`, `check-json`). No surveyed repository runs a
dedicated YAML style linter; clap runs a YAML *parse* check.

**Fit, not abstract best.** A template differs from these projects in one way
that matters here: its value is the conventions it hands to every generated
repository, and most of its files are not Rust (workflows, `lefthook.yml`,
`dependabot.yml`, `Justfile`, Markdown, TOML, shell scripts, snapshot fixtures).
A gate that a large application can skip because reviewers catch drift is worth
more in a template, where the next user inherits whatever drift was committed.
That argument supports adoption; it does not select tools. Tool selection below
is gate-first, then R42's provisioning rule, then practice.

### Principles and implementation

**Shared principle and its agreement level.** `docs/port/DIVERGENCE-ANALYSIS.md:164`
classifies R40 as cause class **D** ("For each of the 4 tools: does the value
justify adoption for Rust, independent of language"), and `:165` classifies F167
as class **C** ("Does rustfmt plus the chosen non-Rust-file formatter already
cover trailing-whitespace/EOF-newline for every staged file type, or does a gap
remain"). From those rows and py's configuration, the shared principle is:

> Every committed text file is checked mechanically, before commit and again in
> CI, against properties that formatters and compilers do not check: a declared
> whitespace/encoding baseline, YAML structural soundness, spelling, and
> workflow type-correctness. The baseline is declared once, in a file editors
> also read, and its exceptions are documented in that file.

**Agreement level: capability and policy, not tool.** The three repositories
must agree that each of the four properties is gated at hook tier and in CI, and
that one editor-readable declaration carries the baseline and its exceptions.
They need not agree on the executable that checks each property. A different
tool is justified wherever the ecosystem's provisioning path differs; here R42
fixes that path for Rust.

**Essential behaviours and observable acceptance criteria.**

1. A staged text file with trailing whitespace, a missing final newline, CRLF
   endings or a non-UTF-8 charset fails the pre-commit hook, unless
   `.editorconfig` exempts that file type.
2. A Markdown hard break (two trailing spaces) and an `insta` snapshot line with
   trailing spaces pass, because `.editorconfig` exempts `*.md` and `*.snap`, and
   the checker reads that same file.
3. A YAML file with a duplicate key fails the hook, whether or not it is a
   workflow file.
4. A misspelling inside a `snake_case` identifier, a comment, a workflow or a
   file name fails the hook; a deliberate spelling can be allowed in one config
   file.
5. A workflow with a duplicated key, an unknown `needs` target or a type error in
   an expression fails the hook and the CI `workflow-lint` job.
6. The CI whole-tree run checks the same files the hook checks. Hidden
   directories such as `.github/` are not silently skipped by either.
7. A missing tool fails the hook loudly with a non-zero exit, never a silent pass.

**How the gates apply to these members (stated once, applied identically).** All
four tools are developer-machine and CI **binaries executed at arm's length**.
None is a `Cargo.toml` dependency, so none enters the template's dependency
graph, published crate, binary size, compile time or MSRV. R38's decision took
the same reading (`research/topics/38-commit-message-linter/DECISION.md:64`, "a
dev-tool binary, so the gate binds only the `cargo install` path; prebuilt
assets and the action need no toolchain"). Applied here:

- **Gate 1 (license).** The question is whether the template may *require* the
  tool. A tool executed as a separate process, and not redistributed by the
  template, does not relicense the template. GPL-licensed tools
  (`yamllint` GPL-3.0, `codespell` GPL-2.0, `action-validator` GPL-3.0-only) are
  therefore **not gate failures**; they are recorded as a tradeoff, because a
  downstream user who vendors or redistributes the tool inherits its terms.
- **Gate 2 (MSRV).** Binds only the source-build path (`cargo install` or
  `cargo binstall`'s compile fallback). The policy floor is **1.96**: stable is
  1.98.1 (`rustc 1.98.1 (48a229cea 2026-09-01)` on this host [executed]; R38's
  decision records the same stable at `:64`), minus two minor versions. Go
  binaries have no Rust MSRV; the gate is **inapplicable** to them.
- **Gate 3 (advisories, unsafe).** `rustsec.org/packages/<name>.html` for crate
  members. RustSec publishes a package page only when an advisory exists, so a
  404 means **no advisory has ever been published for that package**. Go tools
  are outside RustSec's scope; the gate is **inapplicable** there and the
  upstream CodeQL/GitHub advisory posture is noted instead.
- **Gate 4 (OS).** Evidence is each project's own CI workflow, read at source.
- **Gates 5 and 6 (features, runtime, size, compile time).** Stated per member
  qualitatively. No member couples to an async runtime the template uses.

**Architectural alternatives, compared before tools.** For F167, the only row
with a genuine architecture choice:

| # | Architecture | Where the baseline is declared | Covers non-Rust files | Measured gap |
|---|---|---|---|---|
| A | One validity checker that reads `.editorconfig` (py) | `.editorconfig` only | all git-tracked text files | none known; tool not executed here (not installed) |
| B | `git diff --check` with `.gitattributes whitespace=` | `.gitattributes`, a second declaration that must mirror `.editorconfig` | all | **[executed]** misses a missing final newline in `src/main.rs`; flags trailing spaces inside a Rust string literal that `rustfmt` preserves; flags the Markdown hard break and the `.snap` line unless `.gitattributes` repeats both exceptions |
| C | Fold into formatters (ts, D-014(7) and D-020(6)) | per-formatter config | only file types a formatter owns | shell scripts, `Justfile`, `.gitignore`, `LICENSE-*`, `proptest-regressions/*.txt`, `.snap` and any file R29 does not format are unchecked |
| D | In-repo tidy test (rust-lang/rust, rust-analyzer) | Rust code in the template | all | bespoke code every generated repo must maintain; runs in the compile tier (`cargo test`), not at hook tier |
| E | `prek` built-in hooks (Rust) | `.pre-commit-config.yaml` | all | requires `prek` as the hook manager; F142 fixes lefthook (R37's prompt), so excluded by fit |

**[executed]** evidence for B and C, scratch repository `/tmp/r40/e2`:

```text
$ git diff --cached --check
README.md:1: trailing whitespace.
blank.txt:2: new blank line at EOF.
cfg.toml:1: trailing whitespace.
run.sh:1: trailing whitespace.
src/main.rs:2: trailing whitespace.
src/main.rs:3: trailing whitespace.          <- inside "keep  \n", a string literal
exit=2                                        (src/main.rs has no final newline; not reported)

$ rustfmt --edition 2024 --check src/main.rs  # rustfmt 1.9.0
-    // a comment with trailing space
+    // a comment with trailing space
     let s = "keep                             <- literal kept
+                                             <- final newline added
exit=1
```

So `rustfmt` fully covers `.rs` files (it strips comment whitespace, keeps
literal whitespace and adds the final newline), which answers the first HIGH
question: **the gap is real and it is exactly the non-Rust files.** A is
recommended because it is the only architecture with one declaration and full
coverage. B is the runner-up because it needs no install.

**Architectural alternatives for F168.** The question is not only "which linter"
but "is a dedicated YAML lint needed once a YAML formatter (R29) and `actionlint`
exist". **[executed]** in `/tmp/r40/e1`:

| Input | `yamlfmt 0.17.2 -lint` | `actionlint 1.7.12` | `lefthook 2.1.14 validate` | `yamllint 1.38.0` |
|---|---|---|---|---|
| workflow with duplicated `runs-on` | — | exit 1, `key "runs-on" is duplicated` | — | — |
| `lefthook.yml` with duplicated `pre-commit` | exit 0 (passes) | — | exit 1, `mapping key "pre-commit" already defined` | exit 1, `key-duplicates` |
| `.github/dependabot.yml` with duplicated `schedule` | exit 0 (passes) | not a workflow (4 spurious errors) | — | exit 1, `key-duplicates` |

A formatter does not reject duplicate keys, and nothing else in the stack reads
`dependabot.yml`, issue forms or other non-workflow YAML. **A structural lint
therefore closes a measured gap**, though a small one: workflows are covered by
`actionlint` and `lefthook.yml` by `lefthook validate`.

**Architectural alternatives for F169 and F170** are single-tool questions; see
the members. F170's hook-tier question has a factual answer: `actionlint`
compiles nothing, so "Rust's slower iteration loop" does not apply to it.
**[executed]** `actionlint` over py's 22 workflow files took 0.21–0.51 s wall
(3 runs, warm cache, `shellcheck` on `PATH`).

**Representative performance (all [executed], same host, warm cache).** None is a
discriminator; every tool finishes well under one second at template scale.

| Tool | Workload | Wall time |
|---|---|---|
| `actionlint 1.7.12` | py `.github/workflows/*.yml`, 22 files | 0.21–0.51 s (3 runs) |
| `typos 1.32.0` | py tree, 337 tracked files | 0.06–0.09 s (3 runs) |
| `yamllint 1.38.0` | py's 35 tracked YAML files, py `.yamllint` | 0.20–0.30 s (3 runs) |
| `codespell 2.4.2` | py tree via `[tool.codespell]` | 0.17–0.22 s (2 runs) |
| full proposed `pre-commit` (typos + actionlint jobs; ec and ryl absent) | 3 staged files | 0.08 s (lefthook summary) |

**How the design preserves the principle in each ecosystem.** py realizes the
capability with Python-provisioned tools (`uv run ec`, `uv run yamllint`,
`uv run codespell`) plus one release binary (`actionlint`). rs realizes it with
two crates.io tools (`typos`, `ryl`) and two release binaries (`editorconfig-checker`,
`actionlint`), all provisioned through R42's single tool table. The difference is
justified by R42's decision: the Rust template has no Python runtime and no
declarative provisioner (R42 DECISION row 3, "None. No `mise.toml` …"), and
`yamllint`/`codespell` ship no standalone binary, so adopting them would add a
Python backend R42 excluded. ts lacks three of the four capabilities; that is
**drift with no recorded reason** for spell check and the `.editorconfig`
baseline, and a **recorded partial reason** for F167 (oxfmt folds whitespace
fixing for the formats it formats, D-014(7)/D-020(6)). ts's own file types
(shell scripts under `scripts/`, `Justfile`, `Makefile`) are outside oxfmt's
glob (`lefthook.yml:30` at `e5100b4`, `'*.{ts,tsx,js,mjs,cjs,json,jsonc,yml,yaml,md}'`),
so the same C-architecture gap exists there. Changing py and ts is a follow-on
project; this paragraph is its rationale.

**BASELINE-REVIEW findings.**

- `BASELINE-REVIEW: F170 — workflow type-correctness gated at hook tier and in CI — origin "py-only" no longer holds; ts now agrees on actionlint at both tiers, so the row's origin should read "same" (verdict for the controller) — ts cb1cbcb lefthook.yml: 0 occurrences of actionlint; ts e5100b4 lefthook.yml:15-17 "name: actionlint … run: command -v shellcheck >/dev/null && actionlint {staged_files}", added in commit 3799ac6 (2026-09-15, "ci: check shell scripts and workflow commands"); ts .github/workflows/ci.yml:90 "run: just check-shell check-workflows"; ts scripts/install-actionlint.sh pins ACTIONLINT_VERSION 1.7.12.` Affected items: R40 (this), R09 (actionlint config content), R11 (its `workflow-lint` occupant). The prompt's `## Context` claim "ts: none (… never wired into any hook or CI job)" is correct at `cb1cbcb` and stale at `e5100b4`.
- `BASELINE-REVIEW: F169 — spelling gate — follow-on for py: codespell misses misspellings inside snake_case identifiers and false-positives a short identifier that py already allow-lists; typos handles both — [executed] on /tmp/r40/e2/src/lib.rs, "fn recieve_porjects(ans: u32)": codespell 2.4.2 reports "ans ==> and" twice and does not report "recieve"; typos 1.32.0 reports "recieve -> receive" and "porjects -> projects", and does not report "ans". py pyproject.toml:301 already carries ignore-words-list = "ans,porjects,unparseable".` Affected items: R40 only; a py follow-on.
- `BASELINE-REVIEW: F167 — validity checker invocation — follow-on for py: editorconfig-checker v4.0.0 (2026-09-03) renamed the binary "ec" to "editorconfig-checker" and removed default discovery of ".ecrc"; py lefthook.yml:81-83 invokes "uv run ec -config .editorconfig-checker.json" against a PyPI wrapper pinned ">=3.0.0" (pyproject.toml:88) — release notes read from GET https://api.github.com/repos/editorconfig-checker/editorconfig-checker/releases.` Whether py's PyPI wrapper still exposes `ec` was not checked; the finding is a re-verify prompt for py, not a claimed breakage.

**Minimal realistic example.** Committed below as the migration content, and
**[executed]** in scratch repository `/tmp/r40/ex` (a `git init` tree with
`src/main.rs`, `tests/snapshots/cli__help.snap` carrying a trailing-space line,
a `README.md` hard break and one workflow):

```text
$ lefthook validate                                   -> All good, exit 0
$ actionlint                                          -> exit 0
$ typos                                               -> exit 0
$ yamllint -c .yamllint .github lefthook.yml          -> exit 0   (config-format proxy for ryl)
# then stage: dependabot.yml with duplicated "schedule", a workflow line "echo recieve", src/lib.rs
$ lefthook run pre-commit --no-tty
  yaml-lint ❯ sh: ryl: command not found              exit status 127
  editorconfig-checker ❯ sh: editorconfig-checker: command not found   exit status 127
  typos ❯ error: `recieve` should be `receive` --> .github/workflows/ci.yml:15:19   exit status 2
  actionlint ✔️ (0.08 seconds)
$ yamllint -c .yamllint .github/dependabot.yml        -> 7:5 error duplication of key "schedule" (key-duplicates), exit 1
```

The two 127 exits are the tools this host lacks (`editorconfig-checker`, `ryl`);
they also demonstrate criterion 7 (a missing tool fails loudly). Both tools'
own runs are **not executed** in this leg; see `### Validation strategy`.

### Recommendation

**Adopt all four capabilities and the `.editorconfig` baseline. One stack of five
members:**

| # | Member | Version | Provisioned via (R42) | Hook job (lefthook `pre-commit`) | CI placement (R11) | Settles |
|---|---|---|---|---|---|---|
| 1 | `editorconfig-checker` | 4.0.2 | `ubi` release residue slot | `editorconfig-checker {staged_files}` | step of `hygiene`: `editorconfig-checker` | F167 |
| 2 | `ryl` | 0.22.0 | `cargo binstall --locked ryl@0.22.0` | glob `*.{yml,yaml}`: `ryl {staged_files}` | step of `hygiene`: `ryl .` | F168 |
| 3 | `typos-cli` (executable `typos`) | 1.50.3 | `cargo binstall --locked typos-cli@1.50.3` | `typos --force-exclude {staged_files}` | step of `hygiene`: `typos` | F169 |
| 4 | `actionlint` | 1.7.12 | `ubi` release residue slot | glob `.github/**/*.{yml,yaml}`: `actionlint` (no file args) | the `workflow-lint` job R11 reserves: `actionlint` | F170 |
| 5 | `.editorconfig` baseline | EditorConfig spec | committed file | enforced by member 1 | enforced by member 1 | F191, F192 |

Exceptions (F192) for this template: `[*.md] trim_trailing_whitespace = false`
and `[*.snap] trim_trailing_whitespace = false`. py's `[*.ambr]` exception has
no Rust counterpart and is not carried. `[Makefile] indent_style = tab` is added
only if the template ships a `Makefile` (not decided here).

Not adopted: `yamllint`, `codespell` (Python-only distribution, excluded by fit
with R42), `git diff --check` (runner-up for F167), an in-repo tidy test, `prek`
built-ins, `action-validator`, `ecformat`, `codebook-lsp`, `yamllint-rs`,
`yaml-lint`, `fast-yaml-linter`, `truss-cli`.

### Members

#### editorconfig-checker

##### Landscape

Bin placement: established industry standard for "check files against
`.editorconfig`". Go, MIT, `editorconfig-checker/editorconfig-checker`. Rust-side
alternatives in the same category: `ecformat` 0.2.0 (up-and-comer, Codeberg),
`editorconfiger` 0.6.0 (a different category: it validates and compares
`.editorconfig` files themselves, not files against them), the in-repo tidy
pattern (rust-lang/rust, rust-analyzer) and `prek` built-ins. First-party:
`git diff --check`, `rustfmt` (Rust files only).

##### Principles and implementation

Realizes criteria 1, 2 and 7. It reads `.editorconfig` directly, so every
exception declared there binds both editors and the checker: one declaration,
no mirror to maintain. README [read]: "If you run this tool from a repository
root it will check all files which are added to the git repository and are text
files"; default excludes include `Cargo\.lock$` and `(^|/)target/`; binary and
non-UTF-8 files are skipped. `Indentation` and `IndentSize` checks are disabled
in `.editorconfig-checker.json`, as py does (py `.editorconfig-checker.json`
`_comment`: formatters own indentation; double enforcement produces spurious
failures). In Rust, `rustfmt`, `taplo` and R29's YAML formatter own indentation.
`--fix` exists for `trim_trailing_whitespace`, `end_of_line` and
`insert_final_newline` (README), but the hook runs check-only so it never
rewrites a staged file silently. The config key `"Version": "4.0.2"` makes the
binary refuse to run at any other version (README configuration table: "verifies
this value matches the binary version and exits with an error if they differ").

##### Dominant choice

`editorconfig-checker` 4.0.2 (release published 2026-09-19T11:47:24Z, `GET
https://api.github.com/repos/editorconfig-checker/editorconfig-checker/releases/latest`).
It is the only maintained tool whose whole job is this check.

##### Qualified shortlist

| Candidate | Gate 1 | Gate 2 | Gate 3 | Gate 4 | Gates 5/6 | Popularity / maintenance |
|---|---|---|---|---|---|---|
| `editorconfig-checker` 4.0.2 | MIT | inapplicable (Go) | inapplicable (not Rust); no RustSec scope | CI matrix `ubuntu-latest`, `macos-latest`, `windows-latest` (`.github/workflows/ci.yml:29-31`) [read] | single static binary; no features; negligible cost | 638 stars; `archived: false`; `pushed_at` 2026-09-21T08:14:54Z; 25 open issues (`search/issues … is:open`); responsiveness below |
| `git diff --check` (git) | GPL-2.0 git, executed at arm's length | inapplicable | inapplicable | ships with git on both runners | none | first-party; see runner-up |

Crate figures for `editorconfig-checker`: **inapplicable — not published on
crates.io** (Go binary); GitHub figures used instead. Issue responsiveness (10
most recently opened issues, `GET https://api.github.com/search/issues?q=repo:editorconfig-checker/editorconfig-checker+is:issue&sort=created&order=desc&per_page=10`,
first comment by an `OWNER`/`MEMBER`/`COLLABORATOR` other than the author):
**median 0.49 days** over 7 responded; **3 unanswered** (#597, #596, #574).
Maintenance state: **active** (three releases in September 2026: v4.0.0
2026-09-03, v4.0.1 2026-09-04, v4.0.2 2026-09-19).

##### Excluded by gate

None excluded by gate. `ecformat` passes gate 1 (BlueOak-1.0.0 is a permissive,
OSI-approved license, and the tool runs at arm's length) but is listed under
up-and-comers on maturity. `prek` built-ins are excluded **by fit**, not by gate:
they run only under `prek`, and F142 fixes lefthook as the hook manager (R37's
prompt, `## Context`).

##### Up-and-comers

- `ecformat` 0.2.0 — crates.io `recent_downloads` 29, `downloads` 120, last
  release 0.2.0 at 2026-06-06T13:02:55Z, license `BlueOak-1.0.0`, repository on
  Codeberg (`GET https://crates.io/api/v1/crates/ecformat`, `/versions`). Rust,
  crates.io-published, so it would fit R42's "prefer crates.io" rule; too young
  to recommend (120 all-time downloads).
- `prek` 0.5.3 — crates.io `recent_downloads` 9768, `downloads` 25773, MSRV
  1.96, MIT; GitHub 8471 stars, 19 open issues. Its built-in
  `trailing-whitespace` and `end-of-file-fixer` are Rust-native, but it is a
  hook manager and would displace lefthook.

##### Fit for this template

CLI, library and web service alike carry non-Rust text: workflows, `Justfile`,
shell scripts, TOML, Markdown, snapshot files, `proptest-regressions/`. The
checker covers all of them and is orthogonal to the `web-extra-surface` feature.
Nothing enters a published crate.

##### Recommendation

Adopt `editorconfig-checker` 4.0.2, provisioned through R42's `ubi` residue slot,
with `.editorconfig-checker.json` pinning `"Version": "4.0.2"` and disabling
`Indentation` and `IndentSize`. Hook: `editorconfig-checker {staged_files}`.
CI: a step of R11's `hygiene` job running `editorconfig-checker` with no
arguments (all git-tracked text files).

##### Ranked runner-up

`git diff --check`, driven by `core.whitespace` and `.gitattributes`: zero
install and first-party. It ranks second because it failed three **[executed]**
cases: it does not report a missing final newline; it reports trailing spaces
inside a Rust string literal that `rustfmt` preserves; and it reports the
Markdown hard break and the `.snap` line unless `.gitattributes` repeats both
exceptions (a second declaration that must track `.editorconfig`). It also
checks no charset. CI whole-tree use needs the empty-tree form
`git diff --check $(git hash-object -t tree /dev/null) HEAD`, which was
**[executed]** and reported `README.md:3` and `tests/snapshots/cli__help.snap:5`.

##### Tradeoffs

- A Go release binary, not a crates.io tool: it is the first occupant of R42's
  `ubi` residue slot, which R42 shipped empty with the rule "a release-only tool
  must justify itself". Justification: no crates.io tool covers the capability
  at usable maturity (`ecformat`: 29 downloads in 90 days), and the formatter
  fold leaves the measured gap above.
- v4.0.0 shipped breaking changes on 2026-09-03 (binary rename, `.ecrc` no
  longer discovered, latin1 no longer accepted as UTF-8). The template starts on
  v4, so it inherits none of the migration, but the cadence argues for the
  `Version` pin.
- Asset naming: the macOS asset is `editorconfig-checker-darwin-all.tar.gz`
  (universal). Whether `ubi` 0.12.0 selects a `-all` asset on
  `aarch64-apple-darwin` is **unverified**.

##### Parameters

No owned parameter. `assumes package-manager-invocation` = R42's value:
invoked as the bare executable `editorconfig-checker` on `PATH`, no prefix;
presence tested with `command -v editorconfig-checker`. `assumes
ci-job-structure` = R11's value: a non-compiling check, so a step of `hygiene`.
No `CONFLICT:`.

##### Migration implications

Add `.editorconfig-checker.json`. Add one row to R42's tool table (release spec
`editorconfig-checker/editorconfig-checker@v4.0.2` through `ubi`). Add the
lefthook job and the `hygiene` step. py's `Exclude` list (`\\.venv`,
`node_modules`, `uv\\.lock`, `__snapshots__`, …) is not carried: `target/` and
`Cargo.lock` are default excludes, and `.snap` files are handled by
`.editorconfig` rather than by exclusion.

##### Validation strategy

[proposed] In the P03 template: (1) `editorconfig-checker` exits 0 on the clean
tree on `ubuntu-latest` and `macos-latest`; (2) append `"x  "` to `Justfile`,
remove the final newline from `.github/dependabot.yml`, convert `README.md` to
CRLF — each must exit non-zero and name the file; (3) a two-space hard break in
`README.md` and a trailing-space line in `tests/snapshots/*.snap` must exit 0;
(4) set `"Version": "4.0.1"` and confirm the binary refuses to run. Not
executed in this leg: the binary is not installed on this host.

##### Confidence & re-verify trigger

Confidence **medium-high** on the choice (sole maintained tool, active,
tested on both runners), **medium** on provisioning (the `ubi` asset match is
unverified). Re-verify on: any v5 release; `ubi` failing to resolve the
`darwin-all` asset; R29 choosing a formatter that also checks final newlines for
every tracked file type (would reopen architecture C); or 2027-03-26.

##### Sources

- `GET https://api.github.com/repos/editorconfig-checker/editorconfig-checker` (stars, archived, pushed_at), retrieved 2026-09-26.
- `GET https://api.github.com/search/issues?q=repo:editorconfig-checker/editorconfig-checker+is:issue+is:open` (`total_count` 25), 2026-09-26.
- `GET https://api.github.com/repos/editorconfig-checker/editorconfig-checker/releases` (v4.0.0–v4.0.2 notes, assets), 2026-09-26.
- `GET https://api.github.com/repos/editorconfig-checker/editorconfig-checker/readme` (default excludes, `--fix`, `Version` key), 2026-09-26.
- `.github/workflows/ci.yml:29-31` of the same repository (OS matrix), 2026-09-26.
- py `b55b8c2` `lefthook.yml:80-85`, `.editorconfig-checker.json`; `pyproject.toml:88`.
- `GET https://crates.io/api/v1/crates/ecformat`, `/versions`; `GET https://crates.io/api/v1/crates/prek`, `/versions`, 2026-09-26.
- **[executed]** `/tmp/r40/e2` `git diff --cached --check`; `rustfmt 1.9.0 --edition 2024 --check`; `/tmp/r40/ex` empty-tree `git diff --check`.

#### ryl

##### Landscape

Bin placement: up-and-comer in the Rust field; the established standard in the
category is `yamllint` (Python). Other Rust candidates found by `crates.io`
search: `yamllint-rs` 0.1.4, `yaml-lint` 0.1.0 / `yaml-lint-core` 0.1.0,
`fast-yaml-linter` 0.6.6. First-party: none. Adjacent: `pre-commit-hooks`
`check-yaml` (parse check, clap's choice), R29's YAML formatter, `actionlint`
(workflows only), `lefthook validate` (lefthook config only).

##### Principles and implementation

Realizes criterion 3 for every YAML file, including those no other tool in the
stack reads (`dependabot.yml`, issue forms, `.github/actionlint.yaml`). ryl
README [read]: "All 23 yamllint rules are implemented"; "yamllint-style YAML
configuration is also accepted (`.yamllint`, `.yamllint.yml`, `.yamllint.yaml`)
for drop-in compatibility, including the built-in `default`, `relaxed`, and
`empty` presets via `extends`"; "ryl enables no rules by default, so it needs a
configuration that turns rules on". The configuration is written in yamllint's
format so that the same file works with `yamllint` if ryl must be replaced, and
so py and rs share the config format. Rules the YAML formatter owns are disabled
(`indentation`, `line-length`), which keeps the lint structural (`key-duplicates`,
`truthy`, `anchors`, `new-line-at-end-of-file`, …). A documented semantic
difference: ryl "targets YAML 1.2 strictly" while yamllint defaults to YAML 1.1,
so `yes`/`no` are strings in ryl and booleans in yamllint (README
"Compatibility note"). Whether ryl's `truthy` rule still flags `yes` under 1.2
semantics is **unverified**.

##### Dominant choice

In the category overall, `yamllint` (GitHub 3467 stars, latest v1.38.0
2026-01-13, 128 open issues). It is excluded by fit with R42 (see below), which
leaves `ryl` as the dominant Rust-native choice: 4814 downloads in 90 days,
more than all other Rust YAML linters combined (`yamllint-rs` 239,
`fast-yaml-linter` 249, `yaml-lint` 53).

##### Qualified shortlist

| Candidate | Gate 1 | Gate 2 | Gate 3 | Gate 4 | Gates 5/6 |
|---|---|---|---|---|---|
| `ryl` 0.22.0 | MIT (crate `license` field) | **qualified**: `Cargo.toml` at tag `v0.22.0` declares no `rust-version`; edition 2024 implies ≥ 1.85; the dependency tree's actual floor was not measured. `main`'s `Cargo.toml` declares `rust-version = "1.98.1"` and its README says building from source "needs Rust 1.98.1 or newer", so the next release is expected to fail the 1.96 floor on the source path. The prebuilt path needs no toolchain | 404 at `https://rustsec.org/packages/ryl.html`: no advisory ever published; `#![forbid(unsafe_code)]` at `src/lib.rs:1` and `src/main.rs:1` on `main` | **qualified**: full test suite on `ubuntu-latest` only (`.github/workflows/ci.yml:6`); release builds a macOS `aarch64` artifact on `macos-latest` and runs a `smoke-macos` job (`release.yml:305-334`) | default feature `lsp` (a language server; `--no-default-features` builds a linter-only binary); `rayon` for parallelism; no async runtime; crate size 433587 bytes |

Figures (`GET https://crates.io/api/v1/crates/ryl`, `/versions`; `GET
https://api.github.com/repos/owenlamont/ryl`; `search/issues`): 90-day downloads
**4814**; all-time **8802**; last release **0.22.0**, `created_at`
2026-09-06T13:24:10Z; **80 stars**; `archived: false`; `pushed_at`
2026-09-25T00:15:36Z; **43 open issues**. Responsiveness, 10 most recently
opened issues: maintainer response on **1** (3.57 days, #450); **6 unanswered**
non-maintainer issues, all opened 2026-09-08 to 2026-09-16; 3 are the owner's
own. Contributors: `owenlamont` 182 commits; next human 2 (`GET
.../contributors`). Adopter: `rvben/rumdl` (1528 stars, Rust Markdown linter,
pushed 2026-09-26) runs `ryl-pre-commit` rev `v0.4.0` in
`.pre-commit-config.yaml:81-84`. Maintenance state: **active** (0.22.0 twenty
days ago, pushes this week); the concentration risk is a sole maintainer.

##### Excluded by gate

None by gate. **Excluded by fit with R42**, not by gate:

- `yamllint` 1.38.0 (GPL-3.0, Python). Distributed on PyPI only; no standalone
  binary, so neither `cargo binstall` nor `ubi` can provision it. R42 decided
  "no `mise.toml` … no declarative provisioner" and a crates.io-first backend
  with `ubi` for release binaries. Adopting yamllint would add a Python runtime
  to the template solely for this check.
- `pre-commit-hooks` `check-yaml`: same Python distribution problem.

`yamllint-rs` 0.1.4 (last release 2025-11-07, 239 downloads/90 days), `yaml-lint`
0.1.0 (53) and `fast-yaml-linter` 0.6.6 (249) pass the gates as far as read but
are listed under up-and-comers on adoption.

##### Up-and-comers

`yamllint-rs`, `yaml-lint`/`yaml-lint-core`, `fast-yaml-linter`/`fast-yaml-cli`
(figures above, `GET https://crates.io/api/v1/crates?q=yamllint` and
`?q=yaml+lint`). ryl itself is an up-and-comer by age; it is recommended because
it is the only Rust candidate with yamllint parity, a config-compatible fallback,
and a named adopter.

##### Fit for this template

The template's YAML is small but load-bearing: CI workflows, `dependabot.yml`,
`lefthook.yml`, issue forms, `.github/actionlint.yaml` (R09). A duplicated key in
`dependabot.yml` silently changes update behaviour and no other gate reads that
file (**[executed]** table in `### Principles and implementation`). Orthogonal
to CLI, library and web surfaces.

##### Recommendation

Adopt `ryl` 0.22.0 via `cargo binstall --locked ryl@0.22.0`, with a `.yamllint`
file in yamllint's format:

```yaml
extends: default

rules:
  document-start: disable
  line-length: disable
  indentation: disable
  comments:
    min-spaces-from-content: 1
  truthy:
    allowed-values: ["true", "false"]
    check-keys: false
```

`comments.min-spaces-from-content: 1` keeps the one-space `# vX.Y.Z` pin comment
R20 requires after a SHA (R20 DECISION:70, `owner/repo@<40-hex> # vX.Y.Z`) (**[executed]**: without it, yamllint warned
`too few spaces before comment: expected 2` on the example workflow).
Hook: glob `*.{yml,yaml}`, `ryl {staged_files}`. CI: step of `hygiene`,
`ryl .`.

##### Ranked runner-up

**No dedicated YAML lint**: rely on R29's formatter for parse validity,
`actionlint` for workflows and `lefthook validate` for `lefthook.yml`. Measured
gap: duplicate keys in `dependabot.yml` and other non-workflow YAML pass
(**[executed]** `yamlfmt 0.17.2 -lint` exit 0). Switching cost from the
recommendation: delete one lefthook job, one `hygiene` step, one tool-table row
and `.yamllint`. Second runner-up: `yamllint` itself with the identical
`.yamllint`, if the owner accepts a Python provisioning path; switching cost is
one executable name.

##### Tradeoffs

- Maturity: 0.x with 22 minor releases, a sole maintainer, 6 of the 10 newest
  issues unanswered (all under three weeks old), one well-regarded adopter.
- MSRV trend: the next release is expected to require Rust 1.98.1 to build,
  i.e. current stable; the pick rests on the prebuilt path for any contributor
  below that.
- YAML 1.2 vs 1.1 semantics differ from py's yamllint for `yes`/`no`/`on`/`off`.
- macOS is release-smoke-tested, not suite-tested.
- In exchange: crates.io provisioning under R42 with no new runtime, and a config
  file that stays valid for `yamllint`.

##### Parameters

No owned parameter. `assumes package-manager-invocation` = R42's value: `ryl`
is a bare executable (not `cargo-<sub>`), invoked as `ryl`, presence tested with
`command -v ryl`, installed from crates.io. `assumes ci-job-structure` = R11's
value: a step of `hygiene`. No `CONFLICT:`.

##### Migration implications

Add `.yamllint`. Add one crates.io row to R42's tool table (`ryl@0.22.0`). Add
the lefthook job and the `hygiene` step. py's `.yamllint` `ignore:` block
(`.venv/`, `node_modules/`, `docs/_build/`, …) is not carried; if the template
generates YAML under `target/` it is git-ignored and never staged.

##### Validation strategy

[proposed] (1) `cargo binstall --locked --no-confirm --dry-run ryl@0.22.0` on
both runners must report a prebuilt artifact, not a source build; (2) `ryl .`
exits 0 on the clean template; (3) a duplicated `schedule` key in
`.github/dependabot.yml` exits non-zero with a `key-duplicates` diagnostic;
(4) a value `enabled: yes` in a non-workflow YAML file is flagged by `truthy`
(checks the YAML 1.2 question); (5) the same `.yamllint` run through
`yamllint -c .yamllint .` gives the same verdicts (fallback parity).
**[executed] in this leg**: only the config-format proxy — `yamllint 1.38.0 -c
.yamllint` exited 0 on the clean example and 1 on the duplicated key. `ryl` was
not run (not installed; installing would write outside the permitted file).

##### Confidence & re-verify trigger

Confidence **medium-low** on the tool, **high** on the capability. Carried
risks, not softened: sole maintainer; 0.x; the latest-stable MSRV pattern;
6/10 recent issues unanswered; one flagship adopter; macOS not suite-tested;
nothing executed with ryl itself. Re-verify on: any ryl release (MSRV and config
compatibility); P03's first `cargo binstall` of ryl on each runner; 90 days
without a ryl release; or 2027-03-26.

##### Sources

- `GET https://crates.io/api/v1/crates/ryl`, `/versions`; `GET https://crates.io/api/v1/crates?q=yamllint`, `?q=yaml+lint`, 2026-09-26.
- `GET https://api.github.com/repos/owenlamont/ryl`, `/readme`, `/contributors`, `/releases/latest`, `/contents/Cargo.toml?ref=v0.22.0`, `/contents/Cargo.toml`, `/contents/.github/workflows/ci.yml`, `/contents/.github/workflows/release.yml`, `/contents/src/lib.rs`, 2026-09-26.
- `GET https://api.github.com/search/issues?q=repo:owenlamont/ryl+is:issue+is:open` (43), 2026-09-26.
- `https://rustsec.org/packages/ryl.html` (HTTP 404), 2026-09-26.
- `GET https://api.github.com/repos/rvben/rumdl`, `/contents/.pre-commit-config.yaml`, 2026-09-26.
- `GET https://api.github.com/repos/adrienverge/yamllint` (3467 stars, GPL-3.0), 2026-09-26.
- py `b55b8c2` `lefthook.yml:86-88`, `.yamllint`.
- **[executed]** `/tmp/r40/e1` duplicate-key table; `/tmp/r40/ex` `.yamllint` proxy run.

#### typos-cli

##### Landscape

Bin placement: established industry standard in Rust (10 of 16 surveyed
repositories). Other candidates: `codespell` (Python, GPL-2.0, py's choice),
`cspell` (Node), `codebook-lsp` (Rust, up-and-comer). First-party: none.

##### Principles and implementation

Realizes criterion 4. typos looks up known misspellings in a curated
dictionary rather than flagging unknown words, and splits identifiers on case
and underscores, which fits source code. **[executed]** on
`fn recieve_porjects(ans: u32)`: typos 1.32.0 reported `recieve` and `porjects`
and not `ans`; codespell 2.4.2 reported `ans ==> and` twice and missed
`recieve`. Config discovery [read, `docs/reference.md`]: `typos.toml`,
`_typos.toml`, `.typos.toml`, `Cargo.toml` (`[workspace.metadata.typos]` or
`[package.metadata.typos]`), or `pyproject.toml` (`[tool.typos]`).

Two hook/CI parity details, both **[executed]** with typos 1.32.0:

- The whole-tree walk **skips hidden directories by default**: `typos .` did not
  scan `.github/workflows/ci.yml` (`typos --files . | grep -c github` → `0`), but
  `typos .github/workflows/ci.yml` found the misspelling. `[files]
  ignore-hidden = false` with `extend-exclude = [".git/"]` made the walk find it.
  Without that setting the hook (explicit paths) and CI (walk) disagree, which
  violates criterion 6.
- Explicit paths bypass `extend-exclude` unless `--force-exclude` is passed
  (`typos --help`: "Respect excluded files even for paths passed explicitly").
  The hook passes it.

##### Dominant choice

`typos-cli` 1.50.3 (executable `typos`).

##### Qualified shortlist

| Candidate | Gate 1 | Gate 2 | Gate 3 | Gate 4 | Gates 5/6 |
|---|---|---|---|---|---|
| `typos-cli` 1.50.3 | `MIT OR Apache-2.0` (crate field; GitHub's detector shows `Apache-2.0`) — identical to the template's | pass: `rust_version` **1.95** for 1.50.3 (`/versions`), under the 1.96 floor | 404 at `https://rustsec.org/packages/typos-cli.html` and `/typos.html`: no advisory ever published; workspace lints set `unsafe_op_in_unsafe_fn = "warn"` (`Cargo.toml:30`), no crate-level `forbid(unsafe_code)` found by code search | CI matrix `["ubuntu-latest", "windows-latest", "macos-latest"]` (`.github/workflows/ci.yml:40`) [read] | default features `dict`, `vars` (bundled dictionaries); no async runtime; crate size 51969 bytes; prebuilt release binaries |

Figures (`GET https://crates.io/api/v1/crates/typos-cli`, `/versions`; `GET
https://api.github.com/repos/crate-ci/typos`; `search/issues`): 90-day downloads
**115151**; all-time **1002030**; last release **1.50.3**, `created_at`
2026-09-25T18:41:04Z; **4158 stars**; `archived: false`; `pushed_at`
2026-09-25T18:41:08Z; **126 open issues**. Responsiveness, 10 most recently
opened issues: **median 0.03 days** over 8 responded; **0 unanswered**
non-maintainer issues (the other 2 were opened by a collaborator). Maintenance
state: **active**.

Adopters (each a repository whose standing is shown by its stars above and by
being a Rust project or flagship application): rust-lang/rust `typos.toml`;
rust-lang/cargo `typos.toml` and `.github/workflows/main.yml`;
rust-lang/rust-analyzer `.typos.toml` and `.github/workflows/ci.yaml`;
tokio-rs/axum `Cargo.toml` `[workspace.metadata.typos]` and
`.github/workflows/CI.yml`; bevyengine/bevy `typos.toml` and
`.github/workflows/ci.yml`; clap-rs/clap `typos.toml`, `.pre-commit-config.yaml`
(typos `v1.50.0`) and `.github/workflows/spelling.yml`; nushell/nushell
`typos.toml` and `.github/workflows/typos.yml`; astral-sh/ruff and astral-sh/uv
`_typos.toml`; zed-industries/zed `.github/workflows/run_tests.yml`.

##### Excluded by gate

None by gate. `codespell` (GPL-2.0, Python) is **excluded by fit with R42** for
the same reason as yamllint: PyPI-only distribution. It is also weaker on the
executed identifier case above.

##### Up-and-comers

`codebook-lsp` 0.3.42 (crates.io `recent_downloads` 2069, `downloads` 8930, last
release 2026-07-07, MIT): a code-aware spell checker built around a language
server; its CLI gate use is less established.

##### Fit for this template

Strongest practice fit in the bundle: the Rust project, Cargo, rust-analyzer,
axum and clap all run it, so it is what a Rust contributor expects. It checks
Rust identifiers, doc comments, Markdown, workflows and file names in one pass.
Orthogonal to the web feature.

##### Recommendation

Adopt `typos-cli` 1.50.3 via `cargo binstall --locked typos-cli@1.50.3`, with a
root `typos.toml`:

```toml
[files]
# Walk .github/ too, so the CI whole-tree run checks what the hook checks.
ignore-hidden = false
extend-exclude = [".git/"]
```

`typos.toml` is chosen over `[workspace.metadata.typos]` in `Cargo.toml`
because it is the majority form among the surveyed Rust-project adopters
(rust-lang/rust, cargo, bevy, clap, nushell) and it keeps tool config out of the
manifest a user edits most. Hook: `typos --force-exclude {staged_files}`. CI:
step of `hygiene`, `typos`.

##### Ranked runner-up

`codespell` 2.4.2 with a `[tool.codespell]`-equivalent config — only if the
owner accepts a Python provisioning path. It is py's tool, but it performed
worse on the executed identifier case.

##### Tradeoffs

- typos's dictionary is curated for low false positives, so it catches fewer
  novel misspellings than a dictionary-of-valid-words checker; accepted.
- Adopting typos on an existing tree needs a config pass: **[executed]** typos
  1.32.0 with no config reported 15 findings on py's tree, which codespell's
  config does not cover. For a new template this is a one-time cost.
- The `ignore-hidden` behaviour was observed at 1.32.0, not at 1.50.3.

##### Parameters

No owned parameter. `assumes package-manager-invocation` = R42's value: the
crate is `typos-cli` but the executable is `typos`, not `cargo-<sub>`, so it is
invoked as `typos` and presence-tested with `command -v typos`. `assumes
ci-job-structure` = R11's value: a step of `hygiene`. No `CONFLICT:`.

##### Migration implications

Add `typos.toml`. Add one crates.io row to R42's tool table. Add the lefthook job
and the `hygiene` step. Any deliberate misspelling in the template (py's
`porjects` did-you-mean fixture is the precedent) goes into
`[default.extend-words]` (**[executed]**: `porjects = "porjects"` suppressed it).

##### Validation strategy

[proposed] (1) `typos` exits 0 on the clean template on both runners;
(2) `recieve` in a `.github/workflows/*.yml` comment fails both
`typos --force-exclude <file>` and the whole-tree `typos` (criterion 6, to be
re-run at 1.50.3); (3) a misspelled `snake_case` identifier in `src/` fails;
(4) an `extend-words` entry suppresses a deliberate spelling. **[executed]
in this leg** at typos 1.32.0: (2)'s explicit-path half and walk half (after
`ignore-hidden = false`), (3), (4).

##### Confidence & re-verify trigger

Confidence **high**. Re-verify on: a typos 2.x release; a change to the default
of `ignore-hidden`; or 2027-03-26.

##### Sources

- `GET https://crates.io/api/v1/crates/typos-cli`, `/versions`; `GET https://crates.io/api/v1/crates?q=typos`, `?q=spell`, 2026-09-26.
- `GET https://api.github.com/repos/crate-ci/typos`, `/contents/docs/reference.md`, `/contents/Cargo.toml`, `/contents/crates/typos-cli/Cargo.toml`, `/contents/.github/workflows/ci.yml`, 2026-09-26.
- `GET https://api.github.com/search/issues?q=repo:crate-ci/typos+is:issue+is:open` (126), 2026-09-26.
- `https://rustsec.org/packages/typos-cli.html`, `/typos.html` (HTTP 404), 2026-09-26.
- `GET https://api.github.com/search/code?q=crate-ci/typos+<16 repo qualifiers>` and root listings of the 16 surveyed repositories, 2026-09-26.
- `GET https://api.github.com/repos/clap-rs/clap/contents/.pre-commit-config.yaml`, `repos/tokio-rs/axum/contents/Cargo.toml`, 2026-09-26.
- py `b55b8c2` `lefthook.yml:106-107`, `pyproject.toml:296-306`.
- **[executed]** `/tmp/r40/e2` typos vs codespell; hidden-directory runs; `/tmp/r40/ex` hook run.

#### actionlint

##### Landscape

Bin placement: established industry standard (Go, MIT, `rhysd/actionlint`).
Rust-side: `zizmor` (security audit of workflows; R20 already adopts it for pin
policy, and it answers a different question), `action-validator` (JSON-schema
validation only), `truss-cli` (30 all-time downloads). Adjacent Python tool:
`check-jsonschema`'s `check-github-workflows` (ruff runs it beside actionlint).

##### Principles and implementation

Realizes criterion 5. actionlint parses workflows strictly and type-checks keys,
`needs` edges, expressions and job outputs; with `shellcheck` on `PATH` it lints
`run:` blocks. **[executed]**: a duplicated `runs-on` exits 1 (`key "runs-on" is
duplicated in "test" job`); R11's decision records it catching a misspelled
relayed output, a `needs` edge to a missing job and a job `if:` reading
`secrets` (R11 DECISION criterion 1). A limit, also **[executed]**:
`${{ github.event.pull_request.titl }}` exits 0, because event-payload
properties are not typed.

**Hook tier, answered.** actionlint compiles nothing, so the "slower Rust
iteration loop" does not apply: 0.21–0.51 s for 22 workflows **[executed]**. It
runs at pre-commit **and** in CI, as py (`lefthook.yml:97`, `lint.yml:67-83`) and
now ts (`lefthook.yml:15-17`, `ci.yml:90`) both do.

**Hook shape differs from py's on purpose.** py passes `{staged_files}` with a
glob of `.github/workflows/*.{yml,yaml}`. R11 executed that actionlint's verdict
on an *unchanged* workflow changes when only a local action's `action.yml`
changes, or when only `.github/actionlint.yaml` changes (R11 DECISION `R6-L2`,
`R6-L3`). So the hook here triggers on any YAML under `.github/`
(`glob: ".github/**/*.{yml,yaml}"`) and runs `actionlint` with **no file
arguments**, which lints every workflow against the current actions and config.
**[executed]**: lefthook 2.1.14 selected the job for a staged
`.github/dependabot.yml` and `.github/workflows/ci.yml`, and actionlint ran in
0.08 s.

##### Dominant choice

`actionlint` 1.7.12 (release 2026-03-30T17:49:21Z, `GET
https://api.github.com/repos/rhysd/actionlint/releases/latest`), the version R11
and ts already pin.

##### Qualified shortlist

| Candidate | Gate 1 | Gate 2 | Gate 3 | Gate 4 | Gates 5/6 |
|---|---|---|---|---|---|
| `actionlint` 1.7.12 | MIT | inapplicable (Go) | inapplicable (not Rust); the repo runs CodeQL (`.github/workflows/codeql.yaml`) | CI matrix `ubuntu-latest, ubuntu-24.04-arm, macos-latest, windows-latest, macos-26-intel, windows-11-arm` (`.github/workflows/ci.yaml:9`) [read] | single static binary; optional `shellcheck`/`pyflakes` integration when on `PATH` |

Crate figures: **inapplicable — not published on crates.io** (Go binary). GitHub
figures (`GET https://api.github.com/repos/rhysd/actionlint`; `search/issues`):
**4265 stars**; `archived: false`; `pushed_at` 2026-07-16T06:05:57Z; **143 open
issues**. Adopters: astral-sh/ruff `.pre-commit-config.yaml` (actionlint
`v1.7.12`) and `.github/actionlint.yaml`; zed-industries/zed
`.github/actionlint.yml` and `.github/workflows/run_tests.yml`; rvben/rumdl
`.pre-commit-config.yaml:60-63`.

Maintenance, investigated because the last release is 180 days old (the
rubric's trigger): no commit on `main` since 2026-04-19 (`GET
.../commits?since=2026-04-20T00:00:00Z` → 0); the 10 most recently opened
issues (2026-08-04 to 2026-09-23) have **0 maintainer responses, 10
unanswered**; the two closed among them (#742, #736) were closed by their
authors (`GET .../issues/742/events`, `/736/events`). #742 asks for the
`ubuntu-26.04` runner labels, so the known-label list is ageing. State:
**at-risk**, on the concrete signal of 10/10 unanswered recent issues and five
months without a `main` commit. Not dormant: no advisory, no broken build, no
maintainer notice. `pushed_at` 2026-07-16 reflects a branch push
(`more-runner-checks` exists), not `main`.

##### Excluded by gate

- `action-validator` 0.9.0 — passes gate 1 under the arm's-length reading
  (GPL-3.0-only) but is **excluded by capability**: it validates workflow YAML
  against a JSON schema and does not type-check expressions or `needs` edges, so
  it cannot satisfy criterion 5. Figures: 90-day 6276, all-time 33548, MSRV
  1.84.0, 380 stars, 19 open issues.
- `zizmor` 1.30.1 — not excluded by any gate; out of category (security audit)
  and already R20's.

##### Up-and-comers

`truss-cli` 0.1.0 / `truss-core` 0.1.0 (Rust, "CLI tool for validating GitHub
Actions workflows"; 30 and 128 all-time downloads, one release 2026-02-26).

##### Fit for this template

Every generated repository carries R11's `ci.yml` and the release and scanning
workflows other items add; workflow errors otherwise surface only after push.
The tool is language-independent, so no Rust-specific cost exists.

##### Recommendation

Keep `actionlint` 1.7.12 at **both** tiers. Hook: glob
`.github/**/*.{yml,yaml}`, `run: actionlint` (no file arguments). CI: the
`workflow-lint` job R11 reserves for it, gated on `workflows == 'true'`. Its
config content (`.github/actionlint.yaml` runner labels) is R09's. The hook runs
whether or not `shellcheck` is present; making `shellcheck` a required tool is
an **unowned decision** (no ledger row or item names shellcheck) and is flagged
for the controller rather than decided here.

##### Ranked runner-up

CI only, no hook (the tier question's other answer). Cost: workflow errors reach
push; saving: 0.2–0.5 s per commit that touches `.github/`. Not recommended.

##### Tradeoffs

- **at-risk maintenance** of a single-maintainer Go project; no drop-in
  replacement covers expression type-checking.
- Go release binary: second occupant of R42's `ubi` residue slot. Justification:
  no crates.io tool offers the capability (`action-validator` lacks it,
  `truss-cli` is unproven).
- Ageing runner-label list; R09's config can declare labels to compensate.

##### Parameters

No owned parameter. `assumes package-manager-invocation` = R42's value: bare
executable `actionlint`, presence `command -v actionlint`, installed through the
`ubi` spec form. `assumes ci-job-structure` = R11's value: the `workflow-lint`
job, whose `workflows` key already contains `.github/workflows/`,
`.github/actions/` and `.github/actionlint.ya?ml`. No `CONFLICT:`.

##### Migration implications

Add one `ubi` row (`rhysd/actionlint@v1.7.12`) to R42's tool table. Add the
lefthook job. R11's `workflow-lint` step is already specified by R11.

##### Validation strategy

[proposed] (1) `actionlint` exits 0 on the template's workflows on both runners;
(2) a duplicated key, a `needs:` to a missing job and a misspelled
`needs.plan.outputs.<key>` each exit 1; (3) staging only
`.github/actionlint.yaml` triggers the hook. **[executed] in this leg**: (1) on
the example, (2) duplicated key, (3) the glob selection with
`.github/dependabot.yml` staged.

##### Confidence & re-verify trigger

Confidence **high** on the capability and tier, **medium** on the tool's
longevity. Re-verify on: a new actionlint release (resets the at-risk
assessment); a maintainer notice; a GitHub workflow-syntax feature actionlint
rejects; or 2027-03-26.

##### Sources

- `GET https://api.github.com/repos/rhysd/actionlint`, `/releases/latest`, `/commits?per_page=8`, `/commits?since=2026-04-20T00:00:00Z`, `/branches`, `/issues/742/events`, `/issues/736/events`, `/contents/.github/workflows/ci.yaml`, 2026-09-26.
- `GET https://api.github.com/search/issues?q=repo:rhysd/actionlint+is:issue+is:open` (143), and the 10-newest-issues query, 2026-09-26.
- `GET https://crates.io/api/v1/crates/action-validator`, `/versions`; `?q=actionlint`; `GET https://api.github.com/repos/mpalmer/action-validator`, 2026-09-26.
- `GET https://api.github.com/repos/astral-sh/ruff/contents/.pre-commit-config.yaml`; code search `actionlint` over the 16 surveyed repositories, 2026-09-26.
- `research/topics/11-ci-workflow-job-structure/DECISION.md:189`, `:239`, `:289` (R6-L2, R6-L3, criterion 1, slot row).
- py `b55b8c2` `lefthook.yml:97-104`, `.github/workflows/lint.yml:67-83`; ts `e5100b4` `lefthook.yml:15-17`, `.github/workflows/ci.yml:90`, `scripts/install-actionlint.sh`; ts `cb1cbcb` `lefthook.yml` (no actionlint).
- **[executed]** `/tmp/r40/e1` duplicated `runs-on`; `/tmp/r40/ex` example and lefthook run; py workflow timing.

#### .editorconfig baseline

##### Landscape

Bin placement: established industry standard (the EditorConfig specification,
`editorconfig.org`). There is no first-party Rust equivalent: `rustfmt.toml`
configures Rust formatting only and editors do not apply it to other files. No
up-and-comer competes for the cross-editor role. Adoption in the survey: **5 of
16** (rust-lang/rust, rust-lang/rust-analyzer, astral-sh/uv, astral-sh/ruff,
denoland/deno).

##### Principles and implementation

Realizes the "declared once, in a file editors also read" half of the principle
and criteria 1–2. It makes an editor produce compliant files on save, so the
gate in member 1 rarely fires. This answers the second HIGH question: rustfmt
and clippy own `.rs` files, but they do not act at edit time on TOML, YAML,
Markdown, shell or `Justfile` content, and ts's choice to carry none has no
recorded reason (`docs/port/DIVERGENCE-ANALYSIS.md:164`, "inferred: no recorded
reason for … `.editorconfig`"). Recency of the ts port is not evidence here.

**Exceptions (F192), each tied to a file type this template has:**

- `[*.md] trim_trailing_whitespace = false` — two trailing spaces are a
  Markdown hard break; trimming them changes the rendered document. Same
  exception and rationale in rust-lang/rust's `.editorconfig` ("double
  whitespace at end of line denotes a line break in Markdown") and py
  `.editorconfig:22-25`.
- `[*.snap] trim_trailing_whitespace = false` — R33 adopted `insta` 1.48.0 with
  committed `.snap` files. insta's `TextSnapshotContents::normalize`
  (`insta/src/snapshot.rs:753-765` at tag `1.48.0`) applies `trim_end()` to the
  **whole** body and replaces `\r\n` with `\n`; it does **not** trim per-line
  trailing whitespace, so a help line ending in spaces is compared byte-for-byte.
  `matches_fully` (`:645-647`) compares contents without normalization. Editor
  auto-trim would therefore break the snapshot test. astral-sh/uv and
  astral-sh/ruff carry exactly `[*.snap] trim_trailing_whitespace = false` for
  their insta snapshots: a maintained reference implementation.
- Not carried: py's `[*.ambr]` (syrupy, Python-only).

##### Dominant choice

A root `.editorconfig` with `root = true`, UTF-8, LF, final newline, trimmed
trailing whitespace, space indentation, and the two exceptions above.

##### Qualified shortlist

This member is a **pattern**, not a crate. Crate figures are **inapplicable**:
there is no package to download, release or audit. Pattern fields instead:

| Field | Value |
|---|---|
| Specification | EditorConfig, `editorconfig.org` |
| Reference implementations | rust-lang/rust `.editorconfig`; astral-sh/uv `.editorconfig` (with `[*.snap]`); astral-sh/ruff `.editorconfig` (with `[*.snap]`); rust-lang/rust-analyzer `.editorconfig` |
| Gate 1 | inapplicable — a config file the template authors, under the template's own license |
| Gates 2, 3, 5, 6 | inapplicable — nothing compiled or executed by the template |
| Gate 4 | editor-side; enforced on both CI runners by member 1 |

##### Excluded by gate

None.

##### Up-and-comers

None in this role.

##### Fit for this template

A template's generated repositories are edited in many editors by users who have
not yet configured anything; the file is the only mechanism that reaches all of
them without per-editor setup. It costs one small file and is orthogonal to the
CLI, library and web surfaces.

##### Recommendation

Commit this `.editorconfig` (**[executed]** as part of `/tmp/r40/ex`):

```ini
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

# Markdown: two trailing spaces are a hard line break; trimming them changes
# the rendered document.
[*.md]
trim_trailing_whitespace = false

# insta file snapshots (R33): insta compares snapshot lines byte-for-byte and
# trims only the end of the whole body, so trailing spaces inside a line are
# data. Editor auto-trim would make the snapshot test fail.
[*.snap]
trim_trailing_whitespace = false
```

Add `[Makefile]` with `indent_style = tab` only if the template ships a
`Makefile`. `max_line_length` is not set: R27 owns Rust line width, and the
`Indentation`/`IndentSize` checks are disabled in member 1.

##### Ranked runner-up

No `.editorconfig` (ts's shape), with each formatter's config as the only
declaration. It loses edit-time behaviour for unformatted file types and leaves
member 1 without an input, so F167 would fall back to architecture B or C.

##### Tradeoffs

- Some editors need a plugin to honour the file; the file is inert where
  unsupported.
- Two more exceptions means two file types where trailing whitespace goes
  unchecked; both are required by content semantics.

##### Parameters

No owned parameter. Consumes no registry parameter directly; it depends on R33's
decision (committed `.snap` files) and assumes `rust-edition = 2024` only in
that `rustfmt`'s 4-space default matches `indent_size = 4`. No `CONFLICT:`.

##### Migration implications

Add `.editorconfig` at the repository root. No other file changes.

##### Validation strategy

[proposed] Member 1's cases (2) and (3) exercise the exceptions: a hard break in
`README.md` and a trailing-space line in a `.snap` file must pass, and the same
trailing space in `src/lib.rs` or `Justfile` must fail. [proposed] Run
`cargo insta test` after an editor save of a `.snap` file with trailing spaces
to confirm no diff. **[executed]**: the file parses as part of the example; git's
`--check` flagged exactly the two exempted lines, which shows why an
`.editorconfig`-aware checker is needed.

##### Confidence & re-verify trigger

Confidence **high**. Re-verify on: R33 switching to inline snapshots (would need
a per-file exception like uv's `[crates/uv/tests/help.rs]`); R29 adopting a
Markdown formatter that rewrites hard breaks to backslashes (the `[*.md]`
exception could then go); or 2027-03-26.

##### Sources

- `GET https://api.github.com/repos/rust-lang/rust/contents/.editorconfig`, `repos/astral-sh/uv/contents/.editorconfig`, `repos/astral-sh/ruff/contents/.editorconfig`, `repos/rust-lang/rust-analyzer/contents/.editorconfig`, `repos/denoland/deno/contents/.editorconfig`, 2026-09-26.
- `GET https://api.github.com/repos/mitsuhiko/insta/contents/insta/src/snapshot.rs` (tag `1.48.0`, `7f23d2e`), lines 645-647 and 753-765, 2026-09-26.
- `research/topics/33-property-and-snapshot-testing/DECISION.md` (insta 1.48.0, committed `.snap` files).
- py `b55b8c2` `.editorconfig:1-31`.
- `docs/port/DIVERGENCE-ANALYSIS.md:164-165`.

### Compatibility

No single surveyed project runs all five members together; the evidence is a set
of partial matrices plus this leg's executed example.

| Evidence | Members together |
|---|---|
| astral-sh/ruff | `.editorconfig` with `[*.snap]` + typos (`_typos.toml`, pre-commit) + actionlint 1.7.12 (pre-commit); whitespace via `end-of-file-fixer`, not editorconfig-checker |
| astral-sh/uv | `.editorconfig` with `[*.snap]` + typos (`_typos.toml`) |
| rvben/rumdl | ryl (`ryl-pre-commit` v0.4.0) + actionlint, in one `.pre-commit-config.yaml` |
| clap-rs/clap | typos + pre-commit `check-yaml` (the YAML parse role) |
| py-launch-blueprint `b55b8c2` | all four capabilities + `.editorconfig`, with the Python-provisioned tools, under lefthook `pre-commit` with `parallel: true` (`lefthook.yml:68-69`) |
| **[executed]** `/tmp/r40/ex` | `.editorconfig`, `typos.toml`, `.yamllint`, `lefthook.yml` with all four jobs under `parallel: true`; `lefthook validate` → `All good`; typos and actionlint ran together; ec and ryl absent (exit 127) |

The members share no files and no runtime: each reads its own config, and the
only coupling is `.editorconfig` → `editorconfig-checker`. Overlap is avoided by
construction: ec's indentation checks are off (formatters own indent);
`.yamllint` disables `indentation` and `line-length` (R29 owns YAML style);
trailing-space and final-newline checks exist in both ec and ryl's `default`
preset, which yields at most a duplicate message on a YAML file, never a
contradiction, since both read the same rule direction.

### Parameters

- owns: none — R40 owns no registry parameter (`## Couplings`, `- owns:` is empty).
- assumes ci-job-structure = R11's published value (`inputs/parameters.json`, decision hash `410e88e5…`), unchanged. Used as: the three non-compiling checks (`editorconfig-checker`, `ryl .`, `typos`) are steps of the always-run `hygiene` job; `actionlint` is the one occupant of `workflow-lint`, gated on `workflows == 'true'`; if R37 re-runs the hook suite in CI, that run is a step of `hygiene`.
- assumes package-manager-invocation = R42's published value (`inputs/parameters.json`, decision hash `a2504aa7…`), unchanged: every member is a bare executable on `PATH` (`editorconfig-checker`, `ryl`, `typos`, `actionlint`), none is `cargo-<sub>`, no prefix, no alias; presence tested with `command -v`.
- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- No `CONFLICT:` line. Two release-only tools enter R42's `ubi` slot; that is the slot's documented use, justified per member, and changes no parameter value.

### Migration implications

File-level changes in the template (P03):

| File | Change | Member |
|---|---|---|
| `.editorconfig` | add (content in member 5) | 5 |
| `.editorconfig-checker.json` | add: `{"Version": "4.0.2", "Disable": {"Indentation": true, "IndentSize": true}}` | 1 |
| `.yamllint` | add (content in member 2) | 2 |
| `typos.toml` | add (content in member 3) | 3 |
| `lefthook.yml` | add four `pre-commit` jobs (below); R37 owns the manager and its tiers | 1–4 |
| `Justfile` tool table (R42) | add `editorconfig-checker` (ubi), `ryl@0.22.0` (crates.io), `typos-cli@1.50.3` (crates.io), `actionlint` (ubi) | 1–4 |
| `.github/workflows/ci.yml` | three `hygiene` steps; `workflow-lint` step already specified by R11 | 1–4 |

```yaml
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
      glob: ".github/**/*.{yml,yaml}"
      run: actionlint
```

Not carried from py: `.editorconfig` `[*.ambr]`; `[tool.codespell]`; py's
`uv run` prefixes (R42: no prefix); py's `.yamllint` `ignore:` list of Python
cache directories. ts receives no file changes from this item.

### Validation strategy

**Executed in this leg** (macOS only; outputs quoted in the sections above):

| # | Command | Observed |
|---|---|---|
| E1 | `git diff --cached --check` on `/tmp/r40/e2` | trailing whitespace reported in 5 files incl. a Rust string literal; missing final newline in `src/main.rs` **not** reported; exit 2 |
| E2 | `rustfmt --edition 2024 --check src/main.rs` (rustfmt 1.9.0) | strips comment whitespace, keeps literal, adds final newline; exit 1 |
| E3 | `actionlint` (1.7.12) on duplicated `runs-on` | exit 1, `syntax-check` |
| E4 | `yamlfmt -lint`, `lefthook validate`, `yamllint` on duplicate keys | 0 / 1 / 1 (table in `### Principles and implementation`) |
| E5 | `typos` (1.32.0) vs `codespell` (2.4.2) on `recieve_porjects(ans)` | typos 2 correct hits; codespell 2 false positives, 1 miss |
| E6 | `typos .` with and without `ignore-hidden = false` | `.github/` skipped by default; found after the setting |
| E7 | `/tmp/r40/ex`: `lefthook validate`, `actionlint`, `typos`, `yamllint -c .yamllint` | all exit 0 on the clean example |
| E8 | `/tmp/r40/ex`: `lefthook run pre-commit --no-tty` with three staged defects | typos exit 2 on the workflow typo; actionlint pass; ec and ryl exit 127 (absent) |
| E9 | empty-tree `git diff --check … HEAD` on `/tmp/r40/ex` | flags `README.md:3` and the `.snap` line: the two exempted lines |
| E10 | timings (table in `### Principles and implementation`) | all < 0.6 s |

**Planned for P03** (both runners; expected behaviour stated):

```bash
# Clean tree: every gate passes.
editorconfig-checker && ryl . && typos && actionlint                 # expect exit 0
# Negative controls, one at a time, each reverted after the run:
printf 'x  \n' >> Justfile;              editorconfig-checker        # expect non-zero, names Justfile
printf 'x' > t.txt; git add t.txt;       editorconfig-checker        # expect non-zero: missing final newline
# duplicated `schedule` in .github/dependabot.yml:   ryl .           # expect key-duplicates, non-zero
# `# recieve` in .github/workflows/ci.yml:           typos           # expect non-zero (walk covers .github/)
# `needs: nope` in a job:                            actionlint      # expect exit 1
# Exemptions: hard break in README.md, trailing-space line in tests/snapshots/*.snap:
editorconfig-checker                                                  # expect exit 0
cargo insta test                                                      # expect no snapshot diff
# Hook parity: stage each defect and run
lefthook run pre-commit                                               # expect the same verdicts as the CI commands
# Provisioning:
cargo binstall --locked --no-confirm --dry-run ryl@0.22.0 typos-cli@1.50.3   # expect prebuilt artifacts, no source build
```

Not executed and required before acceptance: `editorconfig-checker` 4.0.2 and
`ryl` 0.22.0 themselves; `typos` at 1.50.3; `ubi` resolving both release assets;
any run on `ubuntu-latest`.

### Confidence & re-verify trigger

| Member | Confidence | Main risk |
|---|---|---|
| typos-cli | high | none material |
| `.editorconfig` + exceptions | high | R33/R29 changes (member 5 triggers) |
| actionlint | high (capability), medium (longevity) | at-risk maintenance |
| editorconfig-checker | medium-high | `ubi` asset match unverified; not executed |
| ryl | medium-low (tool), high (capability) | sole maintainer, 0.x, MSRV at latest stable, not executed |

re-verify: 2027-03-26, or earlier on any of — a ryl release; an actionlint
release or maintainer notice; editorconfig-checker v5; R29 publishing its
formatter choice (could reopen F167's architecture C and ryl's rule overlap);
R37 publishing a CI hook-suite re-run (placement of these jobs in CI); R33
moving to inline snapshots; the owner deciding whether `shellcheck` is required.

### Sources

Endpoints (all retrieved 2026-09-26):

- `GET https://crates.io/api/v1/crates/<name>` and `/versions` for `typos-cli`, `ryl`, `action-validator`, `zizmor`, `prek`, `ecformat`, `editorconfiger`, `yamllint-rs`, `codebook-lsp`, `taplo-cli`.
- `GET https://crates.io/api/v1/crates?q=<term>` for `editorconfig`, `yamllint`, `yaml lint`, `spell`, `typos`, `github actions`, `actionlint`, `whitespace`.
- `GET https://api.github.com/repos/<o>/<r>` for `crate-ci/typos`, `owenlamont/ryl`, `rhysd/actionlint`, `editorconfig-checker/editorconfig-checker`, `adrienverge/yamllint`, `codespell-project/codespell`, `mpalmer/action-validator`, `j178/prek`, `zizmorcore/zizmor`, `rvben/rumdl`, and the 16 surveyed repositories.
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`) for the member repositories; `…+is:issue&sort=created&order=desc&per_page=10` plus `/issues/<n>/comments` for responsiveness.
- `GET https://api.github.com/search/code` with the 16 `repo:` qualifiers for `actionlint`, `yamllint`, `editorconfig-checker`, `crate-ci/typos`, `codespell`, `zizmor`.
- `GET https://api.github.com/repos/<o>/<r>/contents/<path>` for the files named in each member's `##### Sources`.
- `https://rustsec.org/packages/typos-cli.html`, `/typos.html`, `/ryl.html` (HTTP 404: no advisory ever published).

Repository evidence:

- py-launch-blueprint `b55b8c2`: `lefthook.yml:68-69`, `:80-107`; `.editorconfig:1-31`; `.editorconfig-checker.json`; `.yamllint`; `pyproject.toml:87-89`, `:296-306`; `.github/workflows/lint.yml:67-146`.
- ts-launch-blueprint `e5100b4`: `lefthook.yml:1-40`; `Justfile:81`, `:375-391`; `.github/workflows/ci.yml:90`; `scripts/install-actionlint.sh`; `.oxfmtrc.json`. ts `cb1cbcb`: `lefthook.yml` (no actionlint). ts commit `3799ac6`.
- This repository: `research/topics/40-auxiliary-hygiene-hooks/prompts/auxiliary-hygiene-hooks.prompt.md`; `docs/port/COMMONALITY.md:171-174`, `:195-196`; `docs/port/DIVERGENCE-ANALYSIS.md:164-165`, `:286-287`; `research/topics/11-ci-workflow-job-structure/DECISION.md:93-94`, `:186-191`, `:239`, `:289-292`; `research/topics/42-dev-toolchain-provisioning/DECISION.md:24-28`; `research/topics/38-commit-message-linter/DECISION.md:54`, `:64`; `research/topics/20-third-party-action-pinning-policy/DECISION.md:70`; `research/topics/33-property-and-snapshot-testing/DECISION.md`; `research/topics/37-hook-manager-distribution/prompts/hook-manager-distribution.prompt.md:19`, `:33`; `research/topics/29-non-code-file-formatting/prompts/non-code-file-formatting.prompt.md:34-37`; run inputs `inputs/parameters.json`, `inputs/prerequisites.json`.

Tools executed (versions as run): `actionlint 1.7.12`; `typos-cli 1.32.0`; `yamllint 1.38.0`; `codespell 2.4.2`; `yamlfmt 0.17.2`; `lefthook 2.1.14`; `rustfmt 1.9.0` with `rustc 1.98.1 (48a229cea 2026-09-01)` (Homebrew); git from the host; `shellcheck` from `/opt/homebrew/bin`. Scratch trees under `/tmp/r40/` only.
