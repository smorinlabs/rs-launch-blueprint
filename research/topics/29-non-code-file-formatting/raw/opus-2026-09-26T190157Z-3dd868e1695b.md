# R29 — non-code-file-formatting (bundle) — Opus raw research report

Engine: claude-opus-5-5 (Opus seat, CLI run 2026-09-26). Run directory:
`research/runs/R29/2026-09-26T190157Z-3dd868e1695b`. Every retrieval date below is
2026-09-26 (UTC). Source repositories are read at the programme pins:
`py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
`ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`. Network access was
limited to the endpoints the prompt names: `crates.io/api/v1`, `api.github.com`
(including repository contents, releases, issues and code search) and `rustsec.org`.
No other engine's report was opened.

**Terms used throughout.** A *host* is the one executable a contributor or CI runs. A
*plugin* is a formatter for one file family that the host loads. *Wasm* is WebAssembly: a
plugin compiled to Wasm is a platform-independent module that the host executes in a
sandbox, so no Node, Python or Go runtime is needed. *Check mode* reports unformatted
files and exits non-zero. *Write mode* rewrites them in place.

**Answer in one paragraph.** No Rust-ecosystem tool is first-party for these formats: no
rustup component formats TOML, YAML, JSON or Markdown. The Rust project's only
authority on the subject is the Style Guide's `Cargo.toml` conventions chapter, which
no first-party tool enforces. One Rust-native tool does cover all four families without
a non-Rust runtime: **`dprint` 0.57.4**, a crates.io-published host, loading four Wasm
plugins written in Rust. The plugins are `dprint-plugin-toml` 0.8.0,
`dprint-plugin-json` 0.24.0, `dprint-plugin-markdown` 0.24.0 and `pretty_yaml` v0.6.0.
Deno runs exactly this combination (`denoland/deno` `.dprint.json:89-96`). The TOML
plugin applies the Style Guide's `Cargo.toml` conventions by default. The stack is one
config file (`dprint.json`), one CI step (`dprint check`) in R11's `hygiene` job, and
one lefthook pre-commit job. The alternatives fail a stated requirement or are weaker.
`oxfmt`'s standalone binary cannot format Markdown without Node. `taplo` is `at-risk`:
its owner withdrew in writing in 2025-11. `tombi` is release-only, which R42 permits
only with a justification. py's split-tool pattern leaves JSON and Markdown uncovered.

### Landscape

**Category decided.** The formatter, or formatters, that normalise and check the
template's non-Rust text files: TOML (`Cargo.toml`, `rust-toolchain.toml`,
`rustfmt.toml`, and any `clippy.toml` or `deny.toml` other items add), YAML
(`.github/workflows/*.yml`, `lefthook.yml`, `.github/dependabot.yml`, issue-template
forms), JSON (`release-please-config.json`, `.release-please-manifest.json`,
`.vscode/*.json`) and Markdown (`README.md`, `CHANGELOG.md`, `docs/**`,
`.github/*.md`). The category also covers how that check is wired into the hook and CI
pipeline.

**Three-bin map (Rust field, retrieved 2026-09-26).**

| Bin | Candidates found | Formats covered | Distribution |
|---|---|---|---|
| Built-in / first-party toolchain | **None.** The rustup component set on this host is `cargo`, `clippy`, `llvm-bitcode-linker`, `llvm-tools`, `rust-analysis`, `rust-analyzer`, `rust-docs`, `rust-src`, `rust-std`, `rustc`, `rustc-dev` and `rustfmt` (local `rustup component list`, rustup 1.29.1). `rustfmt` formats Rust only. The Rust Style Guide prescribes `Cargo.toml` formatting (`rust-lang/rust` `src/doc/style-guide/src/cargo.md:1-54`), but no first-party tool implements it. | — | — |
| Established industry standard | `taplo` / `taplo-cli` (TOML); `dprint` host with its first-party plugins (TOML, JSON, Markdown, and more) plus the third-party `pretty_yaml` plugin (YAML); Prettier (Node; YAML, JSON, Markdown, no TOML); google `yamlfmt` (Go; YAML only, py's precedent) | see left | crates.io (`taplo-cli`, `dprint`); npm; GitHub releases |
| Up-and-comer | `tombi` (TOML formatter, linter and language server, v1.5.5); `oxfmt` (oxc project; JS/TS plus JSON, YAML and TOML natively, and Markdown through Prettier under Node; 0.70.0, pre-1.0); `rumdl` (Markdown linter with a `fmt` subcommand, 0.2.77); Biome (Rust; JSON but no YAML, TOML or Markdown per ts `TS_PORT_DECISIONS.md:135` and rustup#4091); `cargo-sort` (sorts `Cargo.toml` dependency tables only, so it is not a general TOML formatter) | see left | GitHub releases, PyPI/npm/Homebrew (`tombi`); npm and GitHub releases (`oxfmt`); crates.io (`rumdl`, `cargo-sort`) |

**Authoritative sources used, and why each counts.**

| Source | Why it is authoritative |
|---|---|
| Rust Style Guide, `Cargo.toml` conventions (`rust-lang/rust` `src/doc/style-guide/src/cargo.md`) | Published by the Rust style team in the Rust project's own repository. It is the only first-party statement on formatting a Rust project's TOML: "Use the same line width and indentation as Rust code" (`:5`), and version-sort keys within each section except `[package]` (`:11-15`). |
| `rust-lang/rustup` maintainers' issue #4091 and PR #5013 | The rustup maintainers, a Rust-project team, chose non-code formatters for a Rust repository in 2026-08. The thread records both the reasoning and a dissent. |
| `taplo`'s own "future of the project" issue (tamasfe/taplo#715) | The owner's own statement about maintenance. The prompt's maintenance rubric treats a maintainer's notice as primary evidence. |
| Maintainers' documentation and source: dprint `website/src/{config,cli,ci,install}.md`, plugin `wasm_plugin.rs`/`resolve_config.rs`; tombi `docs/src/routes/docs/**`; oxc `apps/oxfmt/src/core/support.rs` | What each tool actually does, read at the default branch on the retrieval date rather than taken from a summary. |
| crates.io API, GitHub API, rustsec.org | The figure sources the prompt mandates. |
| ts `docs/port/TS_PORT_DECISIONS.md` D-014(6)/(7) and py `Justfile`/`lefthook.yml`/`ci.yml` | Source precedent. It is evidence of intent, not a predetermined winner. |

No Rust annual survey question covers non-code formatters. I found no RFC or
working-group output on the subject beyond the Style Guide chapter. That absence is
itself the evidence for the empty first-party bin.

**Well-regarded Rust projects surveyed (root listing and CI workflows via `GET
https://api.github.com/repos/<o>/<r>/contents/...`, 2026-09-26).** I checked 48
repositories. The table lists those that run a non-code formatter. Stars come from
`GET https://api.github.com/repos/<o>/<r>` `stargazers_count` and are the evidence that
each project is well regarded.

| Project (stars) | TOML | YAML | JSON | Markdown | Wiring evidence |
|---|---|---|---|---|---|
| `denoland/deno` (108,526) | dprint `toml-0.7.0` | dprint `g-plane/pretty_yaml-v0.6.0` | dprint `json-0.21.3` | dprint `markdown-0.21.1` | `.dprint.json:89-96` |
| `pola-rs/polars` (39,869) | dprint `toml-0.6.2` | — | dprint `json-0.19.3` | dprint `markdown-0.17.1` | `dprint.json`; CI `lint-global.yml:16` `uses: dprint/check@v2.3` |
| `starship/starship` (60,051) | dprint `toml` 0.8.0 (taplo only for schema *lint* of presets) | — (`.github/*` excluded) | dprint `json` 0.24.0 | dprint `markdown` 0.24.0 | `.dprint.json`; `format-workflow.yml:10-17` (`dprint/check`), `:20-30` (`taplo lint --schema`) |
| `prefix-dev/pixi` (7,778) | tombi (`tombi.toml`) | dprint `pretty_yaml-v0.5.1` | — | — | `lefthook.yaml:48-62` (tombi and dprint jobs, `stage_fixed`) |
| `biomejs/biome` (25,863) | tombi | — | Biome itself | markdownlint-cli2 (lint) | `main.yml:58-62` `tombi format --check` via `tombi-toml/setup-tombi` |
| `rust-lang/rustup` (7,052) | taplo (`.taplo.toml`, `reorder_keys` on dependency tables) | oxfmt | oxfmt | oxfmt configured since 2026-08-15. Whether the standalone binary it installs actually formats Markdown is unverified; see gap 10. | `ci.yaml:1679-1690` (`taiki-e/install-action` `tool: taplo,oxfmt`; `oxfmt . --check`; `taplo fmt` + `git diff --exit-code`) |
| `bevyengine/bevy` (48,405) | taplo 0.10.0 | — | — | markdownlint (lint) | `ci.yml:342-345` (curl release asset; `taplo fmt --check --diff`) |
| `servo/servo` (38,044) | taplo (`taplo.toml`) | — | — | — | `lint.yml:59-63` (`cargo-install` `taplo-cli`) |
| `swc-project/swc` (34,207) | taplo (`.taplo.toml`) | Prettier (`.prettierrc`) | Prettier | Prettier | root config files |
| `astral-sh/uv` (90,201) | — | Prettier | Prettier | Prettier | `check-fmt.yml:22-29` (`npx prettier@3.9.0 --check .`) |
| `rustls/rustls` (7,638) | `.taplo.toml` present, **no workflow invokes taplo** (0 matches across `build.yml`, `cifuzz.yml`, `cross.yml`, `daily-tests.yml`, `docs.yml`) | — | — | — | consistent with maintainer djc's statement in rustup#4091 that he removed taplo from rustls CI |

Of the 48, `rust-lang/rust`, `rust-lang/cargo`, `rust-analyzer`, `rustfmt`,
`rust-clippy`, `tokio`, `axum`, `ripgrep`, `bat`, `helix`, `typst`, `clap`, `nushell`,
`jj`, `just`, `hyper`, `reqwest` and `serde` have no TOML, YAML, JSON or Markdown
formatter configuration at their root. The dominant practice among large Rust
projects is therefore **no non-code formatter at all**. Among projects that do enforce
one, the clusters are dprint (deno, polars, starship; YAML-only at pixi), taplo (bevy,
servo, swc, rustup) and, arriving in 2026, tombi (biome, pixi) and oxfmt (rustup).

**Fit judgement framing.** This template is a CLI, a library and a web service. It
carries at least three TOML files that always exist, plus YAML workflows and
`lefthook.yml`, release-please JSON (the release tooling is inherited; ledger rows
F063/F066) and a README with docs. ts's precedent intends every config format to be
machine-formatted (`.oxfmtrc.json:14-16`). py's precedent enforces TOML only
(`lefthook.yml:120-125`, `ci.yml:246-262`) and leaves YAML configured but unwired
(`.yamlfmt:1-31`; `Justfile:752-754` is never called from a hook or CI).

### Principles and implementation

**Shared requirement and its agreement level.** Both sources intend the same outcome:
*every committed non-Rust config or doc file has one canonical machine-produced
layout, a check that fails when a file deviates, and a local command that fixes it*.
ts states the intent outright (`.oxfmtrc.json:14-16`: "the source's taplo/yamlfmt
intent (every config format machine-formatted) collapses into this one tool"). py
realises it only for TOML. Agreement is required at the **policy** level: which
families are covered, where the check runs, and that it is enforced. The tool is not
required to agree; ts and py already differ on it, and Rust has its own options.

**What must agree and what may vary.**

| Must agree (acceptance criteria) | May vary |
|---|---|
| A1. All four families are covered: every tracked `*.toml`, `*.yml`/`*.yaml`, `*.json`/`*.jsonc` and `*.md` is either formatted or explicitly excluded with a stated reason. | Which tool or tools do it. |
| A2. A CI check fails on any unformatted covered file, including on pull requests whose compile tier R11 skips. | The CI step's install mechanism, which is R42's. |
| A3. One local command rewrites all covered files, and one local command checks them. | Recipe names, which R27 composes under F102. |
| A4. The formatter never changes meaning: each rewritten TOML, YAML and JSON file parses to the same data. | Style knobs such as quote style and indentation. |
| A5. Generated files whose layout belongs to another tool (release-please's `CHANGELOG.md` and `.release-please-manifest.json`) are excluded, so release pull requests do not fail the check. | Where the exclusion list lives. |
| A6. `Cargo.toml` follows the Rust Style Guide conventions, because that is the one first-party authority. | Whether key sorting is enforced or merely permitted. |
| A7. Runs on `ubuntu-latest` and `macos-latest` without Node, Python or Go. | Windows support (noted, not required). |

A7 is this report's reading of R42's standing rule ("prefer a crates.io-published
tool; a release-only tool must justify itself") and of the prompt's "Rust-ecosystem
native" framing. It is **not** an owner-fixed parameter. If the owner rejects it, the
runner-up analysis below still stands.

**Architectural alternatives, compared before libraries.**

| # | Architecture | Realised by | A1 coverage | Runtime | Configs | Hook/CI jobs | Verdict |
|---|---|---|---|---|---|---|---|
| **A** | **One host, per-format plugins** | `dprint` + toml/json/markdown/pretty_yaml Wasm plugins | all four | Rust binary; Wasm plugins in an embedded `wasmtime` 43 sandbox | 1 (`dprint.json`) | 1 lefthook job, 1 CI step | **Recommended** |
| B | One monolithic multi-format formatter | `oxfmt` 0.70.0 standalone binary | TOML, YAML, JSON natively. **Markdown only with the `napi` feature** (Prettier under Node): `apps/oxfmt/src/core/support.rs:74-89` routes `md` through `#[cfg(feature = "napi")]` and otherwise returns `None` (`:91`). | Rust binary, plus Node for Markdown | 1 | 1 + 1 | Fails A7 for Markdown, per the source at `main`; the release binary's behaviour is unverified (gap 10). TOML options are ignored (oxc-project/oxc#18580, open since 2026-01-26). Pre-1.0. Not on crates.io: the crates.io crate named `oxfmt` is an unrelated publisher's (`septech/oxfmt`, 1.0.0). |
| C | Split per-format tools (py's shape) | `taplo`/`tombi` for TOML + `yamlfmt` for YAML + nothing for JSON/Markdown | TOML and YAML only | Rust + Go binaries | 2 | 2 + 2 | Fails A1 for JSON/Markdown. Needs a Go release binary. py itself never wired the YAML half. |
| D | Split, best tool per format (rustup's shape) | `taplo` (TOML) + `oxfmt` (JSON/YAML/Markdown) | all four, with Markdown through Node as above | Rust + Node | 2 | 2 + 2 | Maintainer djc argues for it in rustup#4091 ("use multiple tools that are especially good at what they do"). But rustup's own TOML half is `taplo`, which is `at-risk`, and the Markdown half inherits B's Node dependency. |
| E | Node-hosted Prettier or ts's `oxfmt` npm package | Prettier / `oxfmt` via npm | YAML, JSON, Markdown; TOML only through `oxfmt` | Node | 1–2 | 1–2 | Correct for ts; wrong for Rust, because it adds a Node toolchain to a template that otherwise needs none (uv accepts this cost; rustup#4091's first objection was exactly this). |
| F | No enforcement (dominant among large Rust repos) | — | none | — | 0 | 0 | Fails A1–A3. It is the modal practice, but it contradicts both sources' intent. |

**Why A preserves each principle.** A1: the four plugins claim `toml`
(`dprint-plugin-toml/src/wasm_plugin.rs:27`), `json` and `jsonc`
(`dprint-plugin-json/src/wasm_plugin.rs:31`), `md` and related extensions
(`dprint-plugin-markdown/src/wasm_plugin.rs:39-47`), and `yaml` and `yml`
(`pretty_yaml/dprint_plugin/src/config.rs:145`). `Cargo.lock` has no extension, so no
plugin matches it. A2: `dprint check` exits `20` when a file is unformatted
(`website/src/cli.md:223`) and compiles nothing, so it is a step of R11's always-run
`hygiene`. A3: `dprint fmt` writes and `dprint check` checks (`cli.md:117`). A4: each
plugin is a structure-aware formatter over a parsed tree; A4 is still an acceptance
check below, not an assumption. A5: `excludes` in `dprint.json` (`config.md:29`).
A6: `dprint-plugin-toml` applies `cargo.applyConventions`, **on by default**
(`src/configuration/resolve_config.rs:70`), which sorts `[package]`, the dependency
tables and `workspace.members` (`src/cargo.rs:16-40`). The TOML plugin's
`indentWidth` and `lineWidth` then carry the Style Guide's "same line width and
indentation as Rust code". A7: `dprint` is on crates.io (0.57.4) with prebuilt
archives for both matrix OSes, and the plugins are Wasm.

**Where Rust needs a different design from both sources.** ts collapsed everything
into its code formatter because `oxfmt` already was ts's code formatter. In Rust the
code formatter is `rustfmt`, which formats nothing else, so the "one tool" intent must
be met by a *second* tool dedicated to non-code files. py's instinct, a dedicated TOML
tool, was right about Rust's heavier TOML surface. Its choice (`taplo`) has since lost
its owner, and its YAML half was never enforced.

**Production usage and maturity (figures under each member).** dprint is the only
candidate that one well-regarded Rust project (deno) runs across all four families at
once. taplo has the widest TOML install base (`taplo-cli` 197,076 downloads in 90 days)
but no release since 2025-05-23. tombi is the fastest-moving (v1.5.1 to v1.5.5 between
2026-09-03 and 2026-09-12) and is adopted by biome and pixi.

**Representative performance.** None of these tools was measured here, and no
like-for-like benchmark was found. Performance is therefore not a selection criterion.
The only performance-relevant behaviours stated in primary docs are: dprint's
incremental mode skips files unchanged since the last run (`cli.md:157-171`), and
compiled Wasm modules are cached under `<dprint-cache>/plugins/` (`config.md:206`).
P03 should time `dprint check` on the real template: wall-clock seconds on
`ubuntu-latest`, cold cache (first plugin download and Wasm compile) versus warm
cache.

**Integration cost.** One tool entry in R42's declared tool table (`dprint@0.57.4`).
One committed `dprint.json`. One `hygiene` step. One lefthook job. Plugins are
downloaded from `plugins.dprint.dev` on first run and cached. That is a network
dependency in hooks and CI, so every plugin URL carries an `@<sha256>` checksum
(`config.md:100-103`, `dprint add --checksum`). This mirrors the integrity scrutiny R42
applied to `cargo-binstall`.

**Minimal realistic example (proposed; not executed).**

```jsonc
// dprint.json
{
  "lineWidth": 100,           // tracks R27's rustfmt max_width (F087); 100 is rustfmt's default
  "toml": { "indentWidth": 4 }, // Style Guide cargo.md:5 — same indentation as Rust code
  "excludes": [
    "**/target",
    "CHANGELOG.md",                  // release-please output (A5); ts precedent .oxfmtrc.json:28-30
    ".release-please-manifest.json"  // release-please output (A5)
  ],
  "plugins": [
    "https://plugins.dprint.dev/toml-0.8.0.wasm@<sha256>",
    "https://plugins.dprint.dev/json-0.24.0.wasm@<sha256>",
    "https://plugins.dprint.dev/markdown-0.24.0.wasm@<sha256>",
    "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm@<sha256>"
  ]
}
```

The `<sha256>` values were **not** computed here, because computing them requires
downloading from `plugins.dprint.dev`, which is outside the named endpoints. P03
fills them with `dprint config add --checksum` or by hashing the downloaded modules.

**Executable acceptance check.** The full command list is under `### Validation
strategy`. The load-bearing checks are: `dprint check` exits `0` on the formatted
tree and `20` after a perturbation; `dprint fmt` is idempotent; `cargo metadata
--locked` and `actionlint` still pass after formatting (A4); and a lone excluded
staged file yields exit `0` with `--allow-no-files` rather than `14` (`cli.md:222`).
**No check was executed against the recommended stack.** `dprint` is not installed on
this host, and installing it or its plugins requires endpoints outside the named set.

**BASELINE-REVIEW.** None. The recommendation keeps F097/F098/F099 `DIVERGENT` and
realises the shared intent. Two prompt-context corrections, which are not ledger
challenges:

1. The npm-staleness note for `@taplo/cli` is in ts `TS_PORT_DECISIONS.md:140`
   (D-014 "Why" 6: "taplo's npm CLI is stale (0.7.0, last modified 2024-02-01)"). It
   is not in `docs/port/areas/lint-format.md`: a search of that file for `taplo`
   returns only `:21` (row F097), `:33` (the tool list) and `:48` (the config-file
   list), and none of those lines mentions npm.
2. The prompt's parenthetical that taplo is "cited by `rustfmt`'s own config-schema
   tooling" was not verified. `rust-lang/rustfmt`'s root has no taplo config. This
   report does not rely on the claim.

### Recommendation

**One stack: `dprint` 0.57.4 as the single non-code formatter host, loading four
checksum-pinned Wasm plugins: `dprint-plugin-toml` 0.8.0 (TOML, with Cargo
conventions on), `pretty_yaml` v0.6.0 (YAML), `dprint-plugin-json` 0.24.0 (JSON and
JSONC) and `dprint-plugin-markdown` 0.24.0 (Markdown).** The stack is configured by
one root `dprint.json`, which excludes release-please outputs. It is installed through
R42's generic `install-tool` recipe as `dprint@0.57.4` and invoked as bare `dprint`,
per R42's `package-manager-invocation`. It is enforced by one `dprint check` step in
R11's always-run `hygiene` job and one lefthook pre-commit job in the same tier as
`rustfmt`. That job globs `*.{toml,json,jsonc,md,yml,yaml}`, mirrors the excludes and
passes `--allow-no-files`. Its check-versus-write mode follows R27's F104 answer.
`lineWidth` tracks R27's `rustfmt` `max_width` (F087), and TOML indentation is 4 per
the Style Guide.

Answers to the prompt's questions:

- **HIGH, one tool or split?** One tool exists: `dprint` with plugins. `oxfmt` is the
  other one-tool candidate, but it needs Node for Markdown. Rust idiom does not
  require a split. The split seen at rustup is one maintainer's preference and was
  disputed in that same thread.
- **HIGH, taplo?** taplo is still the most-installed Rust TOML formatter, and it is
  `cargo install`-able (`taplo-cli` 0.10.0 on crates.io, MSRV 1.74). Its current
  distribution is not npm-only: GitHub release 0.10.0 ships 13 prebuilt assets, and
  only the npm `@taplo/cli` is stale. It is **not** the right choice. Its owner wrote
  "I don't want to be involved anymore" (2025-11-13, tamasfe/taplo#715). There has
  been no release since 2025-05-23, and 8 of its 10 newest issues are unanswered.
- **MEDIUM, YAML?** Yes: a maintained Rust-native YAML formatter exists. `pretty_yaml`
  (g-plane) runs as a dprint plugin, and deno and pixi enforce it. No Go binary is
  needed and nothing is left unwired.
- **MEDIUM, JSON/Markdown worth it?** Yes. The template carries release-please JSON,
  `.vscode` JSONC, `README.md` and `docs/`. Under architecture A, adding the two
  families costs two plugin lines, not two tools.
- **LOW, hook tier?** The same pre-commit tier as `rustfmt`. Lefthook's
  `{staged_files}` scoping makes the whole-repo-versus-source-tree scope difference
  irrelevant at commit time. CI's `dprint check` covers the whole repository.

### Members

#### dprint

##### Landscape
`dprint` is the host executable (crates.io `dprint`, repository `dprint/dprint`). It is
the only Rust-native, crates.io-published program that formats TOML, YAML, JSON and
Markdown together without a non-Rust runtime. It has one competitor for that role:
`oxfmt`'s standalone binary, which covers three of the four families natively. See
`### Landscape` for the full three-bin map.

##### Principles and implementation
The host realises A1–A3 and A7. It discovers files, applies `includes`/`excludes`,
dispatches each file to the plugin that claims its extension, and returns exit `20`
when `check` finds a difference (`website/src/cli.md:214-223`). Plugins run inside an
embedded `wasmtime` sandbox (`crates/dprint/Cargo.toml:70-84`, `wasmtime =43.0.2`,
`cranelift` feature). A plugin therefore cannot touch the filesystem or network
itself; the host owns I/O. Plugin resolution is by URL or `npm:` specifier. Wasm
plugins may carry an optional `@<sha256>` checksum (`config.md:100-103`), and process
plugins require one.

##### Dominant choice
Among Rust projects that enforce a multi-format formatter without Node, `dprint`
dominates. The evidence is deno (all four families, `.dprint.json:89-96`), polars
(TOML, JSON and Markdown via `dprint/check@v2.3`), starship (TOML, JSON and Markdown
via `dprint/check`) and pixi (YAML). Figures:

| Figure | Value | Endpoint (2026-09-26) |
|---|---|---|
| 90-day downloads | 11,656 | `GET https://crates.io/api/v1/crates/dprint` `crate.recent_downloads` |
| All-time downloads | 239,963 | same, `crate.downloads` |
| Last release | 0.57.4, 2026-09-05 | `GET https://crates.io/api/v1/crates/dprint/versions` (newest unyanked) |
| Stars, archived, pushed | 4,079; `false`; 2026-09-15T17:23:31Z | `GET https://api.github.com/repos/dprint/dprint` |
| Open issues | 59 | `GET https://api.github.com/search/issues?q=repo:dprint/dprint+is:issue+is:open` `total_count` |
| Issue responsiveness | median 6.0 days to first maintainer response; 0 unanswered (10 newest issues, #1198–#1251, window from 2026-06-30) | `GET https://api.github.com/repos/dprint/dprint/issues?state=all&sort=created&direction=desc` + per-issue comments |
| Advisories | none (no package page: HTTP 404; control pages `time.html` and `yaml-rust.html` return 200) | `https://rustsec.org/packages/dprint.html` |
| Maintenance | **active** | release within 6 months; weekly cadence in 2026-08/09 |

crates.io downloads undercount this tool. Its documented installers are
`curl … install.sh`, Homebrew, npm and `cargo install --locked dprint`
(`install.md:14-50`), and npm figures are outside the named endpoints.

##### Qualified shortlist
1. `dprint` 0.57.4. It passes every applicable gate:
   - Licence `MIT`, recorded as a figure only (see gate 1 below).
   - No `rust-version` declared. Upstream pins toolchain `1.97.1` (`rust-toolchain.toml`), which is at or below current stable 1.98.1 (local Homebrew `rustc`).
   - No RustSec advisory.
   - `unsafe` posture: the host embeds `wasmtime` 43, a JIT runtime in which `unsafe` is inherent. Its posture was not audited here. The plugins' posture is stated under each plugin member.
   - Prebuilt assets for `x86_64`/`aarch64` `unknown-linux-gnu`/`musl` and `apple-darwin`, plus Windows, with `SHASUMS256.txt` (release 0.57.4).
   - The internal `tokio` runtime has no bearing on the template, because the tool runs as a separate process.
   - Compile-from-source is heavy (`wasmtime` + `cranelift`). The prebuilt archive avoids it.
2. `oxfmt` 0.70.0 standalone. It passes the gates, but fails fit A7 for Markdown. See `#### dprint-plugin-markdown`.

**Gate 1 (licence)** is struck for every candidate by the owner ruling of 2026-09-12:
"no licence check for any tool or library the template uses"
(`docs/planning/p02/execution-ledger.md:495`, extended at `:505`; applied in R42's
`DECISION.md`). Each licence is still recorded as a figure.

##### Excluded by gate
None. No host candidate fails a fitness gate. `oxfmt` is set aside on fit (A7), not
on a gate.

##### Up-and-comers
`oxfmt` (oxc-project, 0.70.0 released 2026-09-21). Its native TOML, YAML and JSON
formatters are Rust (`apps/oxfmt/Cargo.toml` deps `oxc_formatter_json`,
`oxc_formatter_yaml`, `oxc-toml`), and its workspace MSRV is `1.96.0` (`Cargo.toml:18`).
If a future release formats Markdown natively and honours TOML options (oxc#18580), it
becomes a credible single-binary alternative. Hazard: crates.io's `oxfmt` is an
unrelated crate (`septech/oxfmt` 1.0.0, 113 downloads in 90 days), so `cargo install
oxfmt` or `cargo binstall oxfmt` would fetch the wrong program.

##### Fit for this template
Good. It adds one crates.io tool to R42's table and needs no Node, Python or Go. It is
invoked as a bare `dprint` on `PATH`, in R42's form. It compiles nothing, so under R11
it is a `hygiene` step. **Unverified:** whether `cargo binstall --locked --no-confirm
dprint@0.57.4` resolves the prebuilt `dprint-<target>.zip`. The crate's manifest
carries no `[package.metadata.binstall]` stanza (a grep of
`crates/dprint/Cargo.toml` for `binstall` found nothing), so the result rests on
binstall's default URL guesses. If binstall falls back to compiling, `hygiene` pays a
`wasmtime`/`cranelift` build on every run, because R11 gives `hygiene` no cache.

##### Recommendation
Adopt `dprint` 0.57.4 as the host. Declare it in R42's tool table as `dprint@0.57.4`.

##### Ranked runner-up
`oxfmt` standalone binary (0.70.0), installed from GitHub releases through R42's `ubi`
route. Choose it only if the owner accepts that Markdown then needs Node or goes
unformatted.

##### Tradeoffs
- Gains: one config, one command, one CI step and one hook job; Wasm sandboxing of every formatter; incremental re-checks.
- Costs: plugin downloads on first run (a network dependency at hook and CI time, mitigated by checksum pins and the cache); a heavy source build if the prebuilt path fails; and a second formatter configuration vocabulary beside `rustfmt.toml`.

##### Parameters
Owns nothing. Consumes R42's `package-manager-invocation`: bare `dprint` on `PATH`,
presence tested with `command -v dprint`, and no runner prefix. Consumes R11's
`ci-job-structure`: a no-compile check is a step of `hygiene`. Both values are quoted
verbatim under the top-level `### Parameters`. No `CONFLICT:`.

##### Migration implications
Add `dprint@0.57.4` to R42's declared tool table. Add the root `dprint.json`. Add the
`hygiene` step `dprint check`. Add one lefthook job. Add `format-files`/`check-files`
Justfile recipes, which R27 may fold into its composite under F102.

##### Validation strategy
Proposed: `dprint --version` prints `dprint 0.57.4`. `dprint output-file-paths` lists
every covered file and none of the excluded ones. The cold-cache and warm-cache
`dprint check` wall-clock times are recorded on `ubuntu-latest`. `cargo binstall
--dry-run dprint@0.57.4` reports a download, not `will be installed from source`. Not
executed.

##### Confidence & re-verify trigger
High on capability and adoption. Medium on the install path, because of the binstall
question. Re-verify when dprint 0.58 ships, when binstall resolution is tested in P03,
or if deno drops dprint.

##### Sources
- `GET https://crates.io/api/v1/crates/dprint` and `/versions` (2026-09-26)
- `GET https://api.github.com/repos/dprint/dprint`, `/releases/tags/0.57.4`, `/contents/rust-toolchain.toml`, `/contents/crates/dprint/Cargo.toml`, `/contents/website/src/{config,cli,ci,install}.md`, `/contents/dprint.json` (2026-09-26)
- `GET https://api.github.com/search/issues?q=repo:dprint/dprint+is:issue+is:open` (2026-09-26)
- `https://rustsec.org/packages/dprint.html` (404 = no advisories, 2026-09-26)
- `denoland/deno` `.dprint.json:89-96`; `pola-rs/polars` `dprint.json`, `.github/workflows/lint-global.yml:16`; `starship/starship` `.dprint.json`, `.github/workflows/format-workflow.yml:10-17` (2026-09-26)

#### dprint-plugin-toml

##### Landscape
There are four TOML formatters in the Rust field: `taplo` (established, now at-risk),
`dprint-plugin-toml` (established, dprint's first-party plugin), `tombi` (up-and-comer),
and `oxfmt`'s taplo-derived `oxc-toml`, which runs with default options only.
`cargo-sort` only sorts `Cargo.toml` tables. It is a narrow check, not a formatter.

##### Principles and implementation
The plugin realises A1 for TOML and A6. `cargo.applyConventions` defaults to `true`
(`src/configuration/resolve_config.rs:70`). It recognises `Cargo.toml` by file name
(`src/cargo.rs:10-14`) and rearranges `[package]`, `[dependencies]`,
`[dev-dependencies]`, `[workspace.dependencies]` and `workspace.members`
(`src/cargo.rs:16-40`), in line with the Style Guide's version-sort rule
(`cargo.md:11-15`). This report did not check line by line whether the plugin's
ordering matches the Style Guide in every case, for example `description` placed last
in `[package]`. That comparison is an acceptance check below. The configuration
surface includes `lineWidth`, `indentWidth`, `sortKeys` (default `false`),
`sortArrays` (default `false`) and `quoteStyle` (`src/configuration/configuration.rs:59-77`).
The plugin claims only the `toml` extension (`src/wasm_plugin.rs:27-28`), so
`Cargo.lock` is untouched.

##### Dominant choice
Among TOML formatters, taplo has the largest install base, but it fails the
maintenance rubric (see below). Among maintained options run inside a multi-format
host, `dprint-plugin-toml` is dominant: deno, polars and starship use it.

| Figure | Value | Endpoint (2026-09-26) |
|---|---|---|
| 90-day downloads | 2,233 | `GET https://crates.io/api/v1/crates/dprint-plugin-toml` |
| All-time downloads | 19,633 | same |
| Last release | 0.8.0, 2026-08-18 | `/versions` |
| Stars, archived, pushed | 24; `false`; 2026-09-05T15:54:44Z | `GET https://api.github.com/repos/dprint/dprint-plugin-toml` |
| Open issues | 2 | search API `total_count` |
| Issue responsiveness | median 44.2 days; 1 unanswered (10 newest issues, window from 2024-06-25; slow but low-volume) | issues and comments API |
| Advisories | none (404) | `https://rustsec.org/packages/dprint-plugin-toml.html` |
| Maintenance | **active** | release within 6 months |

The crate download figures undercount usage: adopters load the Wasm from
`plugins.dprint.dev`, npm or GitHub releases, not from crates.io.

Comparison figures for the same row:

| Candidate | 90d / all-time | Last release | Stars / open issues | Responsiveness | Advisories | Maintenance |
|---|---|---|---|---|---|---|
| `taplo-cli` | 197,076 / 2,224,667 | 0.10.0, 2025-05-23 | 2,402 / 199 | 8 of 10 newest unanswered (window from 2026-05-28); median 1.1 days over the 2 answered | none (404) | **at-risk** (see below) |
| `tombi` (GitHub v1.5.5) | crates.io holds only placeholders: `tombi-cli` 0.0.1 (82 / 1,032), `tombi` 0.0.1 (134 / 1,616) | v1.5.5, 2026-09-12 (GitHub releases) | 1,135 / 13 | 8 of 10 newest are maintainer-opened; the 2 external ones (#2210, #2213, opened 2026-09-25/26) were unanswered at retrieval, aged under 1 day | none (404) | **active** |

**taplo's rubric label.** The label is `at-risk`, not `dormant`. The owner's own notice
exists: "Whatever plans I had with this project do not really exist anymore"
(2025-11-10, tamasfe/taplo#715 comment 3513470749) and "I don't want to be involved
anymore" (2025-11-13, comment 3524761328). The owner also called Tombi "a good
successor" (quoted in comment 3524678252). That notice would satisfy the rubric's
`dormant` trigger. However, a collaborator with push rights stated on 2026-03-22 a
plan to "keep merging and creating new releases here as long as I can", and landed
commits on 2026-07-28 (`08f343be02`, `af60e64d6d`). Hand-off rather than stoppage is
the concrete state, and `at-risk` records it. rustup's maintainer djc independently
reported that taplo "was causing more false positives in CI than actual issues" and
removed it from rustls CI (rust-lang/rustup#4091, comment 5278501263). The rustls
workflows confirm the removal: 0 `taplo` matches.

##### Qualified shortlist
1. `dprint-plugin-toml` 0.8.0. Licence `MIT` (figure only). Consumed as Wasm, so no local compile and the MSRV gate does not bind. No advisory. Platform-independent Wasm, so both OSes. No default-feature or runtime coupling. No binary-size or compile cost to the template.
2. `tombi` v1.5.5. Licence MIT. Release binaries for `x86_64`/`aarch64` `apple-darwin` and `x86_64`/`aarch64` `unknown-linux-musl` (release assets). No advisory. Not on crates.io.
3. `taplo-cli` 0.10.0. Licence MIT. MSRV 1.74. Prebuilt for both OSes (13 assets), although R42's check 15 found that binstall falls back to a source build for `taplo-cli@0.10.0` on `aarch64-apple-darwin`.

##### Excluded by gate
None fail a fitness gate. `oxfmt`'s TOML path is set aside on fit: it passes taplo's
*default* options and ignores configuration (oxc#18580, open).

##### Up-and-comers
`tombi`. It offers a formatter, a linter and a language server. It is schema-aware
through the JSON Schema Store and endorsed by taplo's owner as successor. It is
adopted by biome (`main.yml:58-62`, `tombi format --check`) and pixi (`lefthook.yaml:48-53`).
Two defaults need care in a template:
- Schema-driven auto-sorting of `Cargo.toml` is on by default. `docs/formatter/auto-sorting.mdx` documents how to disable it.
- Schemas are fetched remotely unless `--offline` is passed (`docs/cli/offline-mode.mdx`). That is a CI determinism concern.

pixi also documents a TOML-1.1 hazard: tools such as Renovate parse `Cargo.toml` as TOML
1.0 (pixi `tombi.toml`). tombi defaults to v1.0.0 (`docs/reference/toml-versions.mdx`).

##### Fit for this template
Strong. It covers `Cargo.toml`, `rust-toolchain.toml`, `rustfmt.toml` and any
`clippy.toml`/`deny.toml` another item adds. Its Style-Guide-aligned Cargo conventions
satisfy A6 without extra configuration. Set `"toml": { "indentWidth": 4 }` and let
`lineWidth` track R27's F087. The first run reorders keys in existing `Cargo.toml`
files: a one-time diff that should land in the same commit that adds `dprint.json`.
Editor interplay: contributors whose VS Code runs "Even Better TOML" (taplo) with
format-on-save will fight the plugin's output. That setting belongs to R28's
editor-tooling rows; this item flags it only.

##### Recommendation
Adopt `dprint-plugin-toml` 0.8.0 with `cargo.applyConventions` left at its default
(`true`) and TOML `indentWidth` 4.

##### Ranked runner-up
`tombi` v1.5.5, run standalone through R42's `ubi` route with `--offline`, a
committed `tombi.toml` and a stated reason for the release-only exception. It becomes
first choice if its schema-aware lint is wanted, or if `dprint-plugin-toml`'s slow issue
response (median 44.2 days) becomes a blocker.

##### Tradeoffs
- Gains: Style Guide conventions by default; one host; no separate TOML tool.
- Costs: low direct usage figures; slow issue response on a low-volume tracker; no schema validation of `Cargo.toml`. tombi offers that validation. `cargo` itself rejects invalid manifests at build time.

##### Parameters
Owns nothing. Assumes `rust-edition = 2024` only in the sense that `Cargo.toml` must
stay parseable by Cargo after formatting, which acceptance check A4 enforces. No
`CONFLICT:`.

##### Migration implications
The `toml` block in `dprint.json`. A one-time reordering commit of every `Cargo.toml`.
Nothing named `.taplo.toml` is created. py's `.taplo.toml` and `install-taplo` recipe
are not ported.

##### Validation strategy
Proposed checks:
- Commit a `Cargo.toml` that violates `cargo.md:11-15`. Expect `dprint check` to exit `20`.
- Run `dprint fmt`, then `cargo metadata --locked --format-version 1 >/dev/null`. Expect exit 0: meaning is preserved.
- Diff the result against the Style Guide ordering, including whether `description` is last in `[package]`.

Not executed.

##### Confidence & re-verify trigger
Medium-high. The capability is confirmed from source; Style Guide conformance is
unmeasured. Re-verify when the Style Guide's `cargo.md` changes, when oxc#18580
closes, when tombi publishes to crates.io, or when taplo cuts a release under new
ownership.

##### Sources
- `GET https://crates.io/api/v1/crates/{dprint-plugin-toml,taplo-cli,taplo,tombi,tombi-cli}` and `/versions` (2026-09-26)
- `GET https://api.github.com/repos/dprint/dprint-plugin-toml/contents/src/{wasm_plugin.rs,cargo.rs,configuration/configuration.rs,configuration/resolve_config.rs}` (2026-09-26)
- `GET https://api.github.com/repos/tamasfe/taplo/issues/715/comments`, `/issues/819`, `/commits`, `/releases` (2026-09-26)
- `GET https://api.github.com/repos/tombi-toml/tombi/releases/tags/v1.5.5`, `/contents/docs/src/routes/docs/{formatter/auto-sorting,cli/formatter,cli/offline-mode,installation,reference/toml-versions}.mdx`, `/contents/rust/tombi-cli/src/app/command/format.rs` (2026-09-26)
- `GET https://api.github.com/repos/rust-lang/rust/contents/src/doc/style-guide/src/cargo.md` (2026-09-26)
- `GET https://api.github.com/repos/rust-lang/rustup/issues/4091/comments`, `/pulls/5013` (2026-09-26)
- `https://rustsec.org/packages/{dprint-plugin-toml,taplo,taplo-cli,tombi}.html` (all 404, 2026-09-26)

#### dprint-plugin-json

##### Landscape
The Rust-native JSON formatters are `dprint-plugin-json` (dprint first-party), Biome
(Rust; distributed through npm and GitHub releases; not on crates.io under
`biome_cli`) and `oxfmt`'s native `oxc_formatter_json`. `jsonformat` (crates.io 2.1.0)
is a minimal pretty-printer with no check mode in scope here. Prettier is the Node
standard.

##### Principles and implementation
The plugin realises A1 for JSON and JSONC. It claims the `json` and `jsonc` extensions
(`src/wasm_plugin.rs:31-32`), which covers `release-please-config.json`,
`.vscode/*.json` (JSONC with comments) and any devcontainer JSON another item adds.
`.release-please-manifest.json` is written by the release-please bot and is excluded
(A5), so bot commits never fail the check.

##### Dominant choice
Across the Rust adopters surveyed, the formatters in use are dprint (deno, polars,
starship), Prettier (uv, swc, zed, tauri) and Biome (biome). Without Node, dprint's
plugin is the dominant choice.

| Figure | Value | Endpoint (2026-09-26) |
|---|---|---|
| 90-day downloads | 161,033 | `GET https://crates.io/api/v1/crates/dprint-plugin-json` |
| All-time downloads | 869,002 | same |
| Last release | 0.24.0, 2026-09-15 | `/versions` |
| Stars, archived, pushed | 30; `false`; 2026-09-15T20:07:45Z | `GET https://api.github.com/repos/dprint/dprint-plugin-json` |
| Open issues | 6 | search API |
| Issue responsiveness | median 3.9 days; 2 unanswered (10 newest issues, window from 2023-10-12) | issues and comments API |
| Advisories | none (404) | `https://rustsec.org/packages/dprint-plugin-json.html` |
| Maintenance | **active** | |

##### Qualified shortlist
1. `dprint-plugin-json` 0.24.0. Licence MIT (figure only). Wasm, so no local compile. No advisory. Both OSes. GitHub code search for `unsafe` in the repository returned 0 hits (`GET https://api.github.com/search/code?q=unsafe+language:rust+repo:dprint/dprint-plugin-json`), and the plugin runs inside the Wasm sandbox regardless.
2. `oxfmt` native JSON. Rust; Prettier-compatible output (ts precedent).

##### Excluded by gate
None.

##### Up-and-comers
The `oxfmt` native JSON formatter (`oxc_formatter_json`), subject to the host-level
caveats under `#### dprint`.

##### Fit for this template
Good. The template's JSON is small and hand-edited, except for the release-please
manifest, which is excluded. JSONC support matters for `.vscode/settings.json`.

##### Recommendation
Adopt `dprint-plugin-json` 0.24.0 with defaults, and exclude `.release-please-manifest.json`.

##### Ranked runner-up
`oxfmt`'s JSON formatter. It is only relevant if the host changes to `oxfmt`.

##### Tradeoffs
- Gain: JSON coverage for one plugin line.
- Cost: a style distinct from release-please's own serialiser. This is why the manifest is excluded rather than formatted.

##### Parameters
Owns nothing; consumes nothing specific to this member. No `CONFLICT:`.

##### Migration implications
One plugin line in `dprint.json`. One `excludes` entry for `.release-please-manifest.json`.

##### Validation strategy
Proposed checks:
- Reformat `release-please-config.json`, then parse it with `jq . >/dev/null`. Expect exit 0.
- Confirm that `dprint output-file-paths` omits `.release-please-manifest.json`.
- Confirm that a release-please pull request that touches only the manifest and `CHANGELOG.md` passes `dprint check`.

Not executed.

##### Confidence & re-verify trigger
High. Re-verify if release-please starts writing other JSON files, or when the
plugin's major version changes.

##### Sources
- `GET https://crates.io/api/v1/crates/dprint-plugin-json` and `/versions` (2026-09-26)
- `GET https://api.github.com/repos/dprint/dprint-plugin-json`, `/contents/src/wasm_plugin.rs`, `/contents/src/lib.rs` (2026-09-26)
- `GET https://api.github.com/search/code?q=unsafe+language:rust+repo:dprint/dprint-plugin-json` (2026-09-26)
- `https://rustsec.org/packages/dprint-plugin-json.html` (404, 2026-09-26)

#### dprint-plugin-markdown

##### Landscape
The Rust-native Markdown formatters are `dprint-plugin-markdown` (dprint first-party,
built on a CommonMark parser) and `rumdl` (a Rust Markdown linter with `rumdl fmt`).
`oxfmt` formats Markdown only by delegating to Prettier under Node
(`apps/oxfmt/src/core/support.rs:74-89`, `#[cfg(feature = "napi")]`). Prettier is the
Node standard. `markdownlint`/`markdownlint-cli2` is a Node linter, not a formatter
(bevy, biome, ruff).

##### Principles and implementation
The plugin realises A1 for Markdown. It claims `md` and related extensions
(`src/wasm_plugin.rs:39-47`). It also formats fenced code blocks by handing them to
the other loaded plugins by language tag, so JSON and TOML snippets in the README are
normalised too (`src/wasm_plugin.rs:138-147`). Keep the default `textWrap`,
`"maintain"`, so prose is not reflowed.

##### Dominant choice
Without Node, dprint's plugin dominates. Deno, polars and starship format Markdown with
it.

| Figure | Value | Endpoint (2026-09-26) |
|---|---|---|
| 90-day downloads | 150,205 | `GET https://crates.io/api/v1/crates/dprint-plugin-markdown` |
| All-time downloads | 904,256 | same |
| Last release | 0.24.0, 2026-09-10 | `/versions` |
| Stars, archived, pushed | 58; `false`; 2026-09-10T20:53:08Z | `GET https://api.github.com/repos/dprint/dprint-plugin-markdown` |
| Open issues | 4 | search API |
| Issue responsiveness | median 0.1 days; 0 unanswered (10 newest issues, window from 2026-08-22; 5 of 10 maintainer-opened) | issues and comments API |
| Advisories | none (404) | `https://rustsec.org/packages/dprint-plugin-markdown.html` |
| Maintenance | **active** | |

Comparison, `rumdl`: 23,932 downloads in 90 days and 111,384 all-time; 0.2.77 released
2026-09-23; MIT; MSRV `1.94.0`, which is within the floor of 1.96. It has 1,528 stars
and 26 open issues. Responsiveness: median 3.0 days, with 4 of 10 unanswered, 3 of
them under 5 days old at retrieval. No advisory. Maintenance: **active**.

##### Qualified shortlist
1. `dprint-plugin-markdown` 0.24.0. Licence MIT (figure only). Wasm. No advisory. Both OSes. GitHub code search returned 0 `unsafe` hits, and no `#![forbid(unsafe_code)]` attribute was found in `src/lib.rs`. Code search is not exhaustive; the plugin runs inside the Wasm sandbox regardless.
2. `rumdl` 0.2.77. Crates.io-installable; a lint-plus-format combination.

##### Excluded by gate
None. `oxfmt` for Markdown is set aside on fit (A7: it needs Node), not on a gate.

##### Up-and-comers
`rumdl`: fast-moving, with 14 prebuilt assets per release. It adds markdownlint-style
rules. No owner of this item decides whether the template wants Markdown *lint*;
R82 owns docs correctness (link checks).

##### Fit for this template
Good. It covers `README.md`, `docs/**` and `.github/*.md`. `CHANGELOG.md` is excluded
because release-please owns its layout (ts precedent `.oxfmtrc.json:28-30`). If P03
adopts a doctested README (`#![doc = include_str!(…)]`), R11's detector treats that
file as a compile input. That does not change this formatter.

##### Recommendation
Adopt `dprint-plugin-markdown` 0.24.0 with the default `textWrap`, and exclude
`CHANGELOG.md`.

##### Ranked runner-up
`rumdl` 0.2.77, invoked as `rumdl fmt`/`rumdl check`, if the owner also wants Markdown
lint rules.

##### Tradeoffs
- Gains: README and docs normalisation, including embedded code blocks; no Node.
- Cost: formatting is not linting. Heading-structure or line-length rules would need a linter.

##### Parameters
Owns nothing. No `CONFLICT:`.

##### Migration implications
One plugin line. One `excludes` entry for `CHANGELOG.md`, mirrored in lefthook's
`exclude:`.

##### Validation strategy
Proposed checks:
- Introduce a trailing-space and list-marker inconsistency in `README.md`. Expect `dprint check` to exit `20`, and `dprint fmt` to fix it.
- Stage only `CHANGELOG.md`. The hook must pass: either lefthook skips the job because the exclude leaves no files, or dprint exits `0` under `--allow-no-files`, where it would otherwise exit `14`.

Not executed.

##### Confidence & re-verify trigger
High. Re-verify when `oxfmt` gains native Markdown, or when dprint-plugin-markdown
changes its major version.

##### Sources
- `GET https://crates.io/api/v1/crates/{dprint-plugin-markdown,rumdl}` and `/versions` (2026-09-26)
- `GET https://api.github.com/repos/dprint/dprint-plugin-markdown`, `/contents/src/wasm_plugin.rs`, `/contents/src/lib.rs` (2026-09-26)
- `GET https://api.github.com/repos/rvben/rumdl`, `/releases` (2026-09-26)
- `GET https://api.github.com/repos/oxc-project/oxc/contents/apps/oxfmt/src/core/support.rs`, `/contents/apps/oxfmt/Cargo.toml` (2026-09-26)
- `https://rustsec.org/packages/{dprint-plugin-markdown,rumdl}.html` (404, 2026-09-26)

#### pretty_yaml

##### Landscape
The YAML formatters are `pretty_yaml` (g-plane, Rust; runs as the dprint plugin
`g-plane/pretty_yaml`), `oxfmt`'s native `oxc_formatter_yaml`, google `yamlfmt` (Go;
py's precedent) and Prettier (Node). No crates.io crate named `yamlfmt` or
`dprint-plugin-yaml` exists: both lookups returned "does not exist".

##### Principles and implementation
`pretty_yaml` realises A1 for YAML: GitHub Actions workflows, `lefthook.yml`,
`.github/dependabot.yml` and issue-template forms. It claims `yaml` and `yml`
(`dprint_plugin/src/config.rs:145`). It is a formatter, not a linter. YAML *lint*
(ledger F168, yamllint) belongs to R40, and workflow lint (actionlint) is in R11's
`workflow-lint` job. Both run on the formatter's output, so style knobs such as line
width and quoting must not contradict R40's yamllint rules. That is a coordination
point, not a decision taken here.

##### Dominant choice
Without Node, `pretty_yaml` dominates in Rust projects that enforce YAML formatting:
deno (`pretty_yaml-v0.6.0`) and pixi (`pretty_yaml-v0.5.1`, with a `lefthook.yaml`
job). dprint's own `dprint.json` loads `npm:dprint-plugin-yaml@0.6.0`. Its version
matches pretty_yaml's, but the package identity was not verified here.

| Figure | Value | Endpoint (2026-09-26) |
|---|---|---|
| 90-day downloads | 245,957 | `GET https://crates.io/api/v1/crates/pretty_yaml` |
| All-time downloads | 840,275 | same |
| Last release | 0.6.0, 2026-01-09 | `/versions`; GitHub release `v0.6.0` same date |
| Stars, archived, pushed | 52; `false`; 2026-08-26T03:56:51Z | `GET https://api.github.com/repos/g-plane/pretty_yaml` |
| Open issues | 2 | search API |
| Issue responsiveness | median 0.6 days; 1 unanswered (10 newest issues, window from 2025-04-06) | issues and comments API |
| Advisories | none (404) | `https://rustsec.org/packages/pretty_yaml.html` |
| Maintenance | **stable-quiet** | no release for 8.5 months, which triggered investigation: pushed 2026-08-26, 2 open issues, sub-day responses. No at-risk signal was found. |

Comparison, google `yamlfmt` (Go, not a crate): v0.21.0 released 2026-01-05; 1,830
stars; 51 open issues; median 12.3 days with 5 of 10 unanswered (window from
2025-12-24); Apache-2.0; **stable-quiet**.

##### Qualified shortlist
1. `pretty_yaml` v0.6.0 as a dprint plugin:
   - Licence MIT (figure only).
   - Edition 2024 (`pretty_yaml/Cargo.toml`).
   - Wasm, so no local compile.
   - No advisory.
   - One `unsafe` use in `yaml_parser/src/lib.rs:140`, a `std::mem::transmute::<u16, SyntaxKind>`. It executes inside the Wasm sandbox.
   - Both OSes.
2. `oxfmt` native YAML (Rust).
3. `yamlfmt` 0.21.0 (Go release binary, through R42's `ubi` route).

##### Excluded by gate
None fail a fitness gate. `yamlfmt` and Prettier are set aside on fit (A7: a non-Rust
runtime or binary).

##### Up-and-comers
`oxfmt`'s `oxc_formatter_yaml`, a native Rust implementation aiming for Prettier
compatibility.

##### Fit for this template
Good, with one caution. GitHub Actions workflows embed `${{ }}` expressions and shell
in block scalars. A formatter that re-quotes strings changes bytes, not meaning.
Acceptance check A4 (actionlint plus parse-equivalence after `dprint fmt`) is the
guard. py's precedent configured `yamlfmt` with `max_width: 160` (`.yamlfmt:19`); that
is not portable intent, and the shared `lineWidth` applies.

##### Recommendation
Adopt `pretty_yaml` v0.6.0 through the dprint URL
`https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm@<sha256>`, with defaults.

##### Ranked runner-up
`yamlfmt` 0.21.0 (Go). It is py's recorded tool and ts's documented fallback (D-014(7)).
Choose it only if `pretty_yaml` mangles workflow files in P03's acceptance check.

##### Tradeoffs
- Gain: enforced YAML formatting, which py never wired.
- Costs: a third-party plugin maintained by one developer (g-plane) at 52 stars. Mitigations: deno's adoption, and the checksum pin, which prevents silent replacement.

##### Parameters
Owns nothing. No `CONFLICT:`. Coordination with R40's yamllint configuration (F168) is
recorded above.

##### Migration implications
One plugin line in `dprint.json`. py's `.yamlfmt` and `install-yamlfmt` recipe are not
ported.

##### Validation strategy
Proposed checks:
- Run `dprint fmt` on `.github/workflows/*.yml` and `lefthook.yml`. Then run `actionlint`, which must exit 0.
- Compare each workflow's YAML-to-JSON projection before and after formatting; they must be equal. The parser for this projection is not fixed here; see gaps.
- `lefthook validate` must succeed.

Not executed.

##### Confidence & re-verify trigger
Medium-high. Re-verify when pretty_yaml releases 0.7, if deno drops it, or if the
acceptance check shows a semantic change in any workflow.

##### Sources
- `GET https://crates.io/api/v1/crates/pretty_yaml` and `/versions`; `.../crates/yamlfmt` and `.../crates/dprint-plugin-yaml` (both "does not exist") (2026-09-26)
- `GET https://api.github.com/repos/g-plane/pretty_yaml`, `/releases`, `/contents/dprint_plugin/src/{lib.rs,config.rs}`, `/contents/pretty_yaml/Cargo.toml` (2026-09-26)
- `GET https://api.github.com/search/code?q=unsafe+language:rust+repo:g-plane/pretty_yaml` (2026-09-26)
- `GET https://api.github.com/repos/google/yamlfmt`, `/releases` (2026-09-26)
- `denoland/deno` `.dprint.json:95`; `prefix-dev/pixi` `.dprint.jsonc`, `lefthook.yaml:54-62` (2026-09-26)
- `https://rustsec.org/packages/pretty_yaml.html` (404, 2026-09-26)

### Compatibility

The members are tested together in two maintained configurations, and each runs all
of them in one `dprint` process.

| Configuration | dprint host | toml | json | markdown | YAML | Evidence |
|---|---|---|---|---|---|---|
| `denoland/deno` (shared adopter; all four families) | not pinned in config | 0.7.0 | 0.21.3 | 0.21.1 | `g-plane/pretty_yaml-v0.6.0` | `.dprint.json:89-96` (2026-09-26) |
| `dprint/dprint` (the host's own repository, formatted by its own CI) | built from `main` (0.57.x) | `npm:@dprint/toml@0.8.0` | `npm:@dprint/json@0.23.0` | `npm:@dprint/markdown@0.23.0` | `npm:dprint-plugin-yaml@0.6.0` | `dprint.json` at `main` (2026-09-26) |
| starship (three of four) | via `dprint/check` v2.5 | 0.8.0 | 0.24.0 | 0.24.0 | — | `.dprint.json` (GitHub release URLs) |

The recommended pins (`json` 0.24.0 and `markdown` 0.24.0 with `toml` 0.8.0 and
`pretty_yaml` v0.6.0) match starship's for three members. They are one minor version
newer than dprint's own configuration for JSON and Markdown. No surveyed adopter runs
exactly the recommended four-plugin set at these versions. Plugins communicate with
the host through dprint's Wasm plugin schema. It is **expected, not verified here**,
that the host rejects a plugin whose schema version it does not support, so that a
mismatch fails loudly rather than silently. P03's first `dprint check` (V3) is the
compatibility proof for the exact set.

### Parameters

- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner
- assumes package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component
- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes license = MIT OR Apache-2.0
- assumes target-os-matrix = ubuntu-latest, macos-latest

- No owned parameter: R29's `- owns:` list is empty.
- No `CONFLICT:`. Bare `dprint` on `PATH`, presence tested with `command -v dprint`, a
  crates.io tool installed through R42's generic recipe, and one `hygiene` step all
  satisfy the consumed values as registered.
- Coordination, not parameters: `lineWidth` follows R27's `rustfmt` `max_width`
  (F087); the lefthook job's check-versus-write mode follows R27's F104; composite
  recipe inclusion follows R27's F102. R27 is `open`, so this report does not invent
  those values.

### Migration implications

File-level changes in the template (proposed):

| File | Change |
|---|---|
| `dprint.json` (new, root) | The configuration shown under `### Principles and implementation`: `lineWidth`, `toml.indentWidth: 4`, `excludes` (`**/target`, `CHANGELOG.md`, `.release-please-manifest.json`), four checksum-pinned plugin URLs. |
| `Justfile` | Add `dprint@0.57.4` to R42's declared tool table. Add `format-files` (`dprint fmt`) and `check-files` (`dprint check`). R27 decides whether its composite `check`/`all` recipes call them (F102). |
| `lefthook.yml` | One `pre-commit` job named `format-files`. It has `glob: "*.{toml,json,jsonc,md,yml,yaml}"`, an `exclude:` list mirroring `dprint.json`'s `excludes` (ts precedent `lefthook.yml:18-31`), and `run: dprint check --allow-no-files {staged_files}`. If R27's F104 chooses write mode, the run line becomes `dprint fmt --allow-no-files {staged_files}` with `stage_fixed: true`. |
| `.github/workflows/ci.yml` | In R11's `hygiene` job: the install step R42's recipe prescribes, then `run: dprint check`. |
| Every `Cargo.toml` | A one-time reordering by `cargo.applyConventions`, committed together with `dprint.json`. |
| Not created | `.taplo.toml`, `.yamlfmt`, `tombi.toml`, `.oxfmtrc.json`, any `package.json`. |

### Validation strategy

**Status: all checks below are planned. None was executed against the recommended
stack**, because `dprint` and its plugins are absent from this host and fetching them
needs endpoints outside the named set. What this run *did* execute is evidence
retrieval: crates.io, GitHub and RustSec reads, the adopter survey, and the
issue-responsiveness sampling.

Run in a scratch copy of the P03 template, on `ubuntu-latest` and `macos-latest`,
from the repository root:

| # | Command | Expected |
|---|---|---|
| V1 | `dprint --version` | `dprint 0.57.4` |
| V2 | `dprint output-file-paths` | Lists every tracked `*.toml`, `*.yml`, `*.json`, `*.md`. Omits `CHANGELOG.md`, `.release-please-manifest.json`, `Cargo.lock` and `target/`. |
| V3 | `dprint check; echo $?` on the committed tree | `0` |
| V4 | Append two trailing spaces to a line in `lefthook.yml`, move `[dependencies]` keys out of order in `Cargo.toml`, then `dprint check; echo $?` | `20`, with diffs for both files |
| V5 | `dprint fmt && dprint fmt && git diff --stat` | The second run changes nothing (idempotence). |
| V6 | `cargo metadata --locked --format-version 1 >/dev/null && actionlint && lefthook validate` after V5 | All exit `0` (A4: meaning preserved) |
| V7 | `dprint check --allow-no-files CHANGELOG.md; echo $?` and the same without the flag | `0` with the flag; `14` without it (`cli.md:222`) |
| V8 | Replace one hex digit of a plugin's `@sha256`, clear the cache (`dprint clear-cache`), then `dprint check` | Non-zero exit, refusing the plugin |
| V9 | After V3, run `dprint check` with networking disabled | `0`, served from the plugin cache |
| V10 | Stage an unformatted workflow and `git commit` | The hook fails (check mode) or rewrites and re-stages it (write mode, per F104). |
| V11 | Open a pull request that touches only `docs/*.md` | R11's `hygiene` job runs `dprint check` even though the compile tier is skipped. |
| V12 | `cargo binstall --locked --no-confirm --dry-run dprint@0.57.4` | Reports a prebuilt download, not a source build. |

### Confidence & re-verify trigger

**Confidence: medium-high.**
- Confirmed from primary sources: the capability claims (file claims, Cargo
  conventions on by default, exit codes, `oxfmt`'s Markdown routing), the adoption
  claims and every figure.
- Not measured: performance, `pretty_yaml`'s behaviour on this template's workflows,
  Style Guide conformance of the TOML ordering, and binstall's prebuilt resolution.

**Re-verify when:**
- dprint 0.58 ships, or any plugin's major version changes;
- oxc-project/oxc#18580 closes, or `oxfmt` formats Markdown without Node;
- tombi publishes a real crates.io release;
- taplo cuts a release under new ownership;
- deno or starship drops dprint;
- R27 publishes F087, F102 or F104;
- R40 publishes yamllint rules that conflict with `pretty_yaml` output;
- P03's first run of V1–V12;
- otherwise, 2027-03-26.

### Sources

All retrieved 2026-09-26 (UTC).

- crates.io API: `https://crates.io/api/v1/crates/{taplo-cli,taplo,tombi,tombi-cli,dprint,dprint-plugin-toml,dprint-plugin-json,dprint-plugin-markdown,pretty_yaml,rumdl,oxfmt,cargo-sort,markdown,comrak,jsonformat,mdsf}`; `dprint-plugin-yaml`, `biome_cli` and `yamlfmt` return "does not exist".
- GitHub repository metadata (`GET https://api.github.com/repos/<o>/<r>`) and open-issue search (`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`) for `tamasfe/taplo`, `dprint/dprint`, `dprint/dprint-plugin-{toml,json,markdown}`, `g-plane/pretty_yaml`, `tombi-toml/tombi`, `rvben/rumdl`, `oxc-project/oxc`, `google/yamlfmt`, `biomejs/biome`, `DevinR528/cargo-sort`, `prettier/prettier`.
- Issue responsiveness: `GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=100`, pull requests filtered out, the 10 newest issues, and `.../issues/<n>/comments`. A first response is a comment by `OWNER`/`MEMBER`/`COLLABORATOR` or a close by a maintainer. Maintainer-opened issues count as 0 days.
- Releases: `GET https://api.github.com/repos/{tamasfe/taplo,tombi-toml/tombi,dprint/dprint,g-plane/pretty_yaml,rvben/rumdl,google/yamlfmt,dprint/dprint-plugin-toml,oxc-project/oxc}/releases`.
- RustSec: `https://rustsec.org/packages/<name>.html` for every candidate crate. All return 404, meaning no advisory page exists. Controls `time.html` and `yaml-rust.html` return 200.
- Rust Style Guide: `rust-lang/rust` `src/doc/style-guide/src/cargo.md:1-54`.
- rustup: `rust-lang/rustup` `.oxfmtrc.json`, `.taplo.toml`, `.github/workflows/ci.yaml:1679-1690`, PR #5013, issue #4091 comments 5278062828, 5278107358, 5278257569, 5278501263 and 5278765611; commits `1098ed6e0b` and `268f3cc257`.
- taplo: tamasfe/taplo#715 (comments 2560061826, 2645851329, 3513470749, 3516463115, 3524678252, 3524761328), #819, commits `08f343be02`, `af60e64d6d`; release 0.10.0 assets.
- tombi: `README.md`, `rust-toolchain.toml`, `Cargo.toml`, `docs/src/routes/docs/{installation,cli/formatter,cli/offline-mode,formatter/auto-sorting,reference/toml-versions}.mdx`, `rust/tombi-cli/src/app/command/format.rs`, release v1.5.5 assets; issues #2210 and #2213.
- dprint: `website/src/{config,cli,ci,install,plugins}.md`, `website/src/plugins/{toml,pretty_yaml}.md`, `dprint.json`, `rust-toolchain.toml`, `crates/dprint/Cargo.toml`, release 0.57.4 assets.
- dprint plugins: `dprint-plugin-toml` `src/{wasm_plugin.rs,cargo.rs,configuration/configuration.rs,configuration/resolve_config.rs}`; `dprint-plugin-json` `src/wasm_plugin.rs`; `dprint-plugin-markdown` `src/{wasm_plugin.rs,lib.rs}`; `pretty_yaml` `dprint_plugin/src/{lib.rs,config.rs}`, `pretty_yaml/Cargo.toml`, `yaml_parser/src/lib.rs:140`.
- oxfmt: `oxc-project/oxc` `apps/oxfmt/Cargo.toml`, `apps/oxfmt/src/core/support.rs:30-110,170-200,421-431`, `Cargo.toml:11,18`; issue #18580; release `oxfmt_v0.70.0` assets; `taiki-e/install-action` `manifests/oxfmt.json`.
- Adopters: `denoland/deno` `.dprint.json`; `pola-rs/polars` `dprint.json`, `.github/workflows/lint-global.yml`; `starship/starship` `.dprint.json`, `.github/workflows/format-workflow.yml`; `prefix-dev/pixi` `.dprint.jsonc`, `tombi.toml`, `lefthook.yaml`; `biomejs/biome` `tombi.toml`, `.github/workflows/main.yml`; `bevyengine/bevy` `.github/workflows/ci.yml`; `servo/servo` `.github/workflows/lint.yml`; `astral-sh/uv` `.github/workflows/check-fmt.yml`; `rustls/rustls` `.github/workflows/*`; root listings of the 48 surveyed repositories.
- py precedent at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`: `.taplo.toml:20-33`, `.yamlfmt:1-31`, `Justfile:151-219,705-765`, `lefthook.yml:85-125`, `.github/workflows/ci.yml:244-262`.
- ts precedent at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`: `.oxfmtrc.json:1-32`, `lefthook.yml:9-33`, `Justfile:100-114`, `package.json:55`, `docs/port/TS_PORT_DECISIONS.md:123-141` (D-014); zero tracked `*.toml` files (`git ls-tree -r --name-only`).
- This repository: `docs/port/COMMONALITY.md:103-105,172` (F097, F098, F099, F168); `docs/port/areas/lint-format.md:21-23,33-36`; `research/topics/11-ci-workflow-job-structure/DECISION.md` (`hygiene` slot for R29); `research/topics/42-dev-toolchain-provisioning/DECISION.md` (invocation rule, `install-tool`, binstall check 15); `docs/planning/p02/execution-ledger.md:495,505` (licence ruling); `docs/port/PARAMETERS.md`.

**Gaps recorded.**
1. Plugin `@sha256` checksums were not computed; this needs `plugins.dprint.dev` access.
2. `cargo binstall` prebuilt resolution for `dprint@0.57.4` is unverified (no binstall metadata in the manifest).
3. Performance was not measured.
4. `dprint-plugin-toml`'s ordering was not compared against every Style Guide rule.
5. `pretty_yaml`'s effect on real GitHub Actions workflows was not exercised. The YAML parse-equivalence tool for V6 is not fixed.
6. `npm:dprint-plugin-yaml`'s identity with `pretty_yaml` was not verified.
7. npm, PyPI and Homebrew install counts are outside the named endpoints, so crates.io figures undercount dprint, its plugins and tombi.
8. Adopter files were read at default-branch `main` without recording commit SHAs.
9. The prompt's "taplo cited by rustfmt's config-schema tooling" claim is unverified.
10. Whether the standalone `oxfmt` release binary formats Markdown is unverified. The
    source at `main` (`apps/oxfmt/src/core/support.rs:74-91`) routes Markdown only
    under the `napi` feature, yet rustup runs that binary after a commit titled
    "use `oxfmt` for Markdown files". To settle it, run the release binary on a `.md`
    file. If the file is formatted, the Markdown (A7) objection to architectures B and D
    falls. dprint would still lead on TOML options (oxc#18580) and crates.io presence.
