# R82 — docs-correctness-gate (bundle) — Opus raw research report

Engine: `claude-opus-5-5` (Opus seat, CLI run 2026-09-26). This is an independent
leg: no other engine's report for this run was opened. Source repositories are read
at the programme pins: `py-launch-blueprint` at
`b08bccfb55d05f15e46a83b52c5660b1881d19f5`, `ts-launch-blueprint` at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, via `git -C <repo> show <sha>:<path> | nl -ba`,
so every quoted line number is the file's own.

Evidence labels used throughout:

- **executed** — run on this host during this leg; command, toolchain and observed
  exit code are recorded in `### Validation strategy`.
- **read** — read from a named file or API response during this leg.
- **proposed** — a command or configuration recommended here that was not run.
- **carried** — a fact taken from an accepted programme decision (R11, R69) or the
  item prompt, cited to its file.

Retrieval window for every network figure: 2026-09-26 US Pacific
(approximately 2026-09-26T23:30Z to 2026-09-27T01:00Z UTC). Endpoints used, and only
these: `crates.io/api/v1` (with a `User-Agent`), `api.github.com` through `gh api`
(repository, search, issues, contents, commits, releases, git refs), and `rustsec.org/packages/`.
Upstream file contents (READMEs, workflows, sources) were read through the
`api.github.com/repos/<o>/<r>/contents/<path>` endpoint, never `raw.githubusercontent.com`.

Host for every executed check: macOS 26.4 `arm64`. Current stable: Homebrew
`rustc 1.98.1 (48a229cea 2026-09-01)`, `cargo 1.98.1 (797e8a9bc 2026-08-05)`,
`rustdoc 1.98.1`. MSRV floor (stable minus 2): rustup `1.96.0`
(`cargo 1.96.0 (30a34c682 2026-05-25)`, `rustdoc 1.96.0 (ac68faa20 2026-05-25)`), invoked as
`rustup run 1.96.0 cargo`. Note: rustup's `stable` alias on this host is stale at `1.94.0`
and was not used. Scratch lived under one `mktemp -d` directory in `$TMPDIR`; nothing was
written outside it except this file, and the scratch directory was deleted after the run.
All cargo runs were offline (`CARGO_NET_OFFLINE=true`); the fixture has no registry dependencies.

**Not executed (gap, stated once here and repeated where it matters):** `lychee` was not
installed or run. Every install path (`cargo install`/`cargo binstall` → `static.crates.io`
and `index.crates.io`; Homebrew bottles; GitHub release assets) is a host this leg's
constraints do not name. Every `lychee` flag cited below was verified against lychee's own
README and source at tag `lychee-v0.24.2` or `master` through the contents API, not from memory,
and every `lychee` command is labelled **proposed**.

### Landscape

**Category this item decides.** A documentation-correctness gate with three parts, one per
ledger row: (F349) offline resolution of internal/relative links in the prose tree,
(F350) reachability of external URLs, and (F353) correctness of the generated API
reference — for Rust, `rustdoc`'s intra-doc links and related doc lints.

**Three-bin map of the Rust field** (figures in `#### ` member sections and the table below):

| Bin | Candidate | What it checks | Status in this report |
|---|---|---|---|
| Built-in / first-party toolchain | `rustdoc` lints via `cargo doc` (`rustdoc::broken_intra_doc_links`, `private_intra_doc_links`, `bare_urls`, `invalid_html_tags`, `invalid_rust_codeblocks`, `invalid_codeblock_attributes`, `redundant_explicit_links`) | API-reference link and markup correctness | **selected** (F353) |
| Built-in / first-party toolchain | `cargo test --doc` | doctest execution | adjacent; owned by R32 test tiers, shown separate in E6 |
| Built-in / first-party toolchain | Cargo `[lints.rustdoc]` / `[workspace.lints.rustdoc]` table | same lints, declared in the manifest | runner-up mechanism for F353 |
| Built-in / first-party project tool | rust-lang/rust `src/tools/linkchecker` (`linkcheck.sh`) | built HTML of Rust-project books | evidence only: rust-lang/book fetches it by URL (`.github/workflows/main.yml:102-105`); not a distributed crate |
| Established industry standard | `lychee` 0.24.2 (+ `lycheeverse/lychee-action` v2.9.0) | Markdown, HTML, text; local files **and** external URLs; `--offline` mode | **selected** (F349, F350) |
| Established | `mdbook-linkcheck` 0.7.7 | mdBook backend: internal + optional web links | excluded on maintenance (`at-risk`: broken with mdBook 0.5) |
| Established | `cargo-deadlinks` 0.8.1 | built `cargo doc` HTML | redundant with rustdoc's own link resolution (E2); no upstream deprecation notice; last release 2021-10-13 |
| Established | `hyperlink` 0.3.2 | built static-site HTML, internal only, `--check-anchors` | qualified; runner-up for F349 as a second, built-output check of R81's mdBook site |
| Established | `mlc` 1.2.0 | Markdown + HTML, internal + external | qualified but at-risk (8 of 10 recent issues unanswered) |
| Up-and-comer | `mdbook-linkcheck2` 0.13.0 | maintained fork of `mdbook-linkcheck`, mdBook 0.5 | up-and-comer; used by rust-lang/rustc-dev-guide |
| Up-and-comer | lychee's newer surface: `--include-fragments[=anchor-only|text-only|full]`, `--include-wikilinks`, `--host-concurrency`, `--host-request-interval` | fragment and per-host rate control | adopted inside the lychee recommendation |
| Out of category (not Rust) | Sphinx `-W` / `-b linkcheck` (py), `scripts/check-links.mjs` (ts), `markdown-link-check` (npm), `htmltest`, `muffet` (Go) | — | precedent only; would add a Python or Node runtime to a Rust template's `hygiene` job |

**Authoritative sources used, and why each counts.**

1. The rustdoc book, `rust-lang/rust` `src/doc/rustdoc/src/lints.md` — the Rust project's own
   normative documentation for rustdoc lints; states `broken_intra_doc_links` "**warns by
   default**" (line 18) and `private_intra_doc_links` "**warns by default**" (line 69). **read**
2. `rustdoc -W help` on 1.98.1 and 1.96.0 — the toolchain's own statement of lint names and
   default levels on the exact versions the template supports (identical at both: 11 `rustdoc::`
   lints, 4 allow and 7 warn, plus the `rustdoc::all` group). **executed**
3. Cargo itself — the `[lints.rustdoc]` table and `RUSTDOCFLAGS` behavior were established by
   running cargo 1.96.0 and 1.98.1 (E2, E3, E7), not by quoting docs. **executed**
4. lychee maintainers' README and source at tag `lychee-v0.24.2` (`lychee-bin/src/client.rs:22-26`,
   `lychee-lib/src/filter/mod.rs:170-240`) — the primary source for what `--offline` does. **read**
5. `lycheeverse/lychee-action` `action.yml` at `v2.9.0` (commit `e7477775783ea5526144ba13e8db5eec57747ce8`) —
   the primary source for defaults (`fail: true`, `failIfEmpty: true`, `lycheeVersion: v0.24.2`,
   `token: ${{ github.token }}`). **read**
6. `hyperlink`'s README — a competing maintainer's own comparison ("An invocation of
   `lychee --offline public/` is more or less equivalent to `hyperlink public/`"). **read**
7. rust-lang/rustc-dev-guide and rust-lang/book CI — the Rust project's own practice for
   checking prose links. **read**
8. crates.io API, GitHub REST API and rustsec.org — the prompt's mandated figure endpoints. **read**

Not consulted (gap): the annual Rust survey; no RFC was fetched.

**Well-regarded projects surveyed, with the evidence that they are well regarded and what they do.**

| Project | Regard evidence (GitHub `stargazers_count`, retrieved 2026-09-26) | Doc gate observed (file:line, commit) |
|---|---|---|
| BurntSushi/ripgrep | 68,632 stars | `RUSTDOCFLAGS: -D warnings` + `cargo doc --no-deps --document-private-items --workspace`, stable toolchain (`.github/workflows/ci.yml:239-246`, `d958105d412b`) |
| tokio-rs/tokio | 33,247 stars | `RUSTDOCFLAGS: --cfg docsrs --cfg tokio_unstable -Dwarnings`, `cargo doc --lib --no-deps --document-private-items --features ...`, nightly (`ci.yml:896-905`, `f26c9663546a`) |
| tokio-rs/axum | 27,260 stars | `RUSTDOCFLAGS: "-D rustdoc::all -A rustdoc::private-doc-tests"`, `cargo doc --package <p> --all-features --no-deps`, stable (`CI.yml:34-49`, `8a68ea9da77e`) |
| serde-rs/serde | 10,835 stars | `RUSTDOCFLAGS: -Dwarnings` + `cargo docs-rs -p serde` on nightly (`ci.yml:125-138`, `6dec3b751126`) |
| lycheeverse/lychee | 3,949 stars; 70,748 90-day downloads | its own `cargo doc --workspace --no-deps` with `RUSTDOCFLAGS: -D warnings` (`ci.yml:67-70`); its own link check runs on `schedule: cron "00 18 * * *"` plus `repository_dispatch` and `workflow_dispatch`, with no `pull_request` or `push` trigger (`links.yml:3-22`, `6163192f069f`) |
| DioxusLabs/dioxus | 39,261 stars | `lycheeverse/lychee-action@v2` with `--config ./lychee.toml './**/*.md'` on every push (`main.yml:74-89`); `lychee.toml`: `cache = true`, `max_cache_age = "10d"`, `accept = ["200..=204", "429"]` (`2c28fd4707ae`) |
| rolldown/rolldown | 13,957 stars | `lychee-action@e7477775...` (v2.9.0) with `--accept 200,429 --verbose --no-progress --exclude 'https://twitter\.com/*' .` on path-filtered PR/push (`link-check.yml:5-41`, `c32d9ee0720e`) |
| rerun-io/rerun | 11,498 stars | nightly full lychee run with `--cache --max-cache-age 1d`, `continue-on-error: true`, `GITHUB_TOKEN`; PRs check added lines only (`reusable_checks.yml:290-346`, `167a5ce3b428`) |
| rust-lang/rustc-dev-guide | 1,914 stars; Rust project repository | `mdbook-linkcheck2 0.13.0`; `MDBOOK_OUTPUT__LINKCHECK__FOLLOW_WEB_LINKS: ${{ github.event_name != 'pull_request' }}` — web links only on push/schedule, `cron: "0 */8 * * *"` (`ci.yml:3-20`, `71b709a3379d`) |
| rust-lang/book | 18,337 stars; Rust project repository | in-tree `linkcheck.sh` from rust-lang/rust against built HTML (`main.yml:102-105`) |

Pattern across the survey (**read**): every surveyed Rust project that gates rustdoc does it with
`-D warnings` (or `-D rustdoc::all`) in `RUSTDOCFLAGS` scoped to the doc job or step, not with a
manifest lint table; and the three projects that separate prose link checks by trigger
(lychee itself, rerun, rustc-dev-guide) keep external-URL checking off the pull-request path.

### Principles and implementation

**Shared requirement.** Documentation that ships with the template must not silently rot: a
broken reference must fail a check the author sees before merge when the failure is
deterministic, and must be reported on a cadence when it is not.
Source: py `ci.yml:226-229` ("Broken cross-references and autodoc failures block the PR instead of
surfacing on ReadTheDocs after merge. Link checking is external-network-flaky, so it lives in the
weekly workflow") and `dep-audit.yml:9` ("external links rot independently of PRs"); ts
`scripts/check-links.mjs:1-23` ("OFFLINE relative-link checker ... Never makes a network call").
**read**

**Agreement level.** *Policy*, not mechanism. Both sources agree on two policies:
(P1) deterministic, offline correctness is a blocking pull-request gate;
(P2) network-dependent checking never blocks a pull request.
They diverge on scope: py covers API-reference cross-references (Sphinx `-W`) and external URLs
(weekly); ts covers only relative Markdown links and has no external check. The mechanisms
(Sphinx, a Node script) do not transfer to a Rust template and need not agree.

**Essential behaviors (must agree).**

1. B1 — every relative link in the prose tree resolves to an existing file, offline, on every pull request; failure exits non-zero.
2. B2 — every intra-doc link in the public API reference resolves, on every pull request that can change Rust code; failure exits non-zero. This is the `sphinx-build -W` parity point.
3. B3 — external URLs are checked with retries, a timeout, a result cache and an explicit exclusion list, on a schedule, and never as a required pull-request check.
4. B4 — the gate is independent of R81's delivery model: it checks Markdown sources, which exist under either outcome.

**R81 and R34 have since resolved** (`research/CLAUDE.md` lists both `resolved`; the prompt predates this).
Read, not re-decided: R81 ships "a single CommonMark/GFM documentation corpus under `docs/` that GitHub
renders in place, **and** build[s] it with `mdbook` 0.5.4 into a GitHub Pages site"
(`research/topics/81-docs-delivery-model/DECISION.md:146-150`), with `docs/SUMMARY.md` as "the single
navigation source ... a plain nested bullet list of relative `.md` links" (`:157`) and heading attributes
`{ #id }` forbidden (`:156`). R81 hands R82 two requirements: acceptance criterion (b) "every relative link
in `README.md` and under `docs/` resolves to an existing file — R82 owns the checker" (`:655-657`), and "the
link walk should treat `docs/SUMMARY.md` as the authoritative navigation artifact, so that navigation drift is
caught even in a fork that has not run the book build" (`:1274-1277`). The Markdown-source design meets both:
lychee's walk of `.` includes `docs/SUMMARY.md`, so a navigation entry naming a missing page fails the offline
check with no mdBook present. It does **not** detect an orphan page (a file under `docs/` that `SUMMARY.md` never
lists); that is not a link property, and R81's criterion (c) keeps it (gap, stated in the summary). R34 ships
one schedule-only workflow, `.github/workflows/canary.yml`, weekly plus `workflow_dispatch`, with
`permissions: {}` at the top and per-job grants (`research/topics/34-scheduled-freshness-lanes/DECISION.md:31-35`;
its candidate file uses `cron: '0 6 * * 2'`, `:420`).

**What may vary.** The tool, whether anchors (fragments) are checked, whether private items are
documented, the cadence of the scheduled run (R34), and job topology (R11).

**Observable acceptance criteria.**

- AC1: a pull request that adds `[x](docs/missing.md)` to any tracked `*.md` fails the `hygiene` job. **proposed**
- AC2: a pull request that adds ``[`Nope`]`` to any doc comment fails `check`'s "Doc build" step on both `ubuntu-latest` and `macos-latest`. **executed** locally as E2b on 1.98.1 and 1.96.0; the CI leg is **proposed**.
- AC3: a pull request that adds a link to an unreachable external URL does **not** fail any required check. **proposed**
- AC4: the scheduled run reports that same URL as broken after `max_retries` retries. **proposed**
- AC5: the doc step does not execute doctests (E6a) and the doctest step is unaffected by the doc step's flags (E7 shows why the flag must be step-scoped). **executed**

**Architectural alternatives compared before libraries.**

| Alternative | Description | Verdict |
|---|---|---|
| A. Check Markdown sources (chosen for F349) | Point the link checker at `*.md` in the repository | Works whether R81 ships a plain tree or an mdBook site, because both keep Markdown sources; needs no build; runs in R11's toolchain-free `hygiene` job |
| B. Check the built site | Build mdBook (or rustdoc) HTML, then check `book/` | Applicable since R81 builds an mdBook site; needs `mdbook` in `hygiene`, which R11 keeps build-free; catches template/renderer breakage that A misses |
| C. Renderer-integrated check (`mdbook-linkcheck2` as an mdBook backend) | Link check runs inside `mdbook build` | Couples the gate to R81 picking mdBook; the Rust project uses it for rustc-dev-guide |
| D. One unified invocation for internal + external | Same command on PR and schedule | Rejected by P2: external reachability is non-deterministic; py already learned this (`ci.yml:228-229`) |
| E. One tool, two invocations (chosen) | Same binary and config; `--offline` on PR, network mode on schedule | Satisfies P1 and P2 with one config file and one pinned version |
| F. API-reference gate via env flag (chosen for F353) | `RUSTDOCFLAGS=-D warnings` on the doc step only | Mirrors `sphinx-build -W` exactly: every rustdoc warning, including lints added in future toolchains, fails |
| G. API-reference gate via manifest lints | `[workspace.lints.rustdoc] broken_intra_doc_links = "deny"` | Also works at the floor (E3); applies to local `cargo doc` too; but only the listed lints fail, so it is weaker than `-W` parity unless every warn-by-default lint is listed |
| H. Built-HTML checker for rustdoc (`cargo-deadlinks`, rust-lang `linkchecker`) | Check `target/doc` HTML | Redundant for intra-doc links since rustdoc resolves them itself; `cargo-deadlinks` last released 2021-10-13 |

**How the design preserves each principle.** P1 is preserved by two blocking checks: lychee
`--offline` in `hygiene` (B1) and `-D warnings` on `check`'s doc step (B2). P2 is preserved by moving
the network invocation to R34's scheduled lane (B3). The ts precedent's reason for a
hand-written script — "lychee (not installed on this machine/CI image)" (`check-links.mjs:5-6`) —
no longer holds, because `lychee-action` installs a prebuilt Linux binary into `$RUNNER_TEMP`
(`action.yml` at v2.9.0, lines 53-112) and needs no project dependency. The ts script's
anchor limitation ("anchor-level checking is out of scope by design", `check-links.mjs:17-19`) is
lifted by `--include-fragments`, which restores part of what Sphinx's `-W` gave py
(broken `:ref:` labels).

**Where the Rust ecosystem needs a different design.** py's API-reference gate needed a docs
environment with the web extra so autodoc imports resolve (`ci.yml:239-240`). In Rust the same
concern is feature selection: a facade doc comment that links into the `web`-gated re-export fails
with the feature off (E4a) and passes with it on (E4b). Therefore the doc step must build with the
web feature enabled, exactly as py synced `--extra web`.

**Production usage and reference examples.** See the practice table in `### Landscape`. Maintained
reference implementations: for the rustdoc gate, ripgrep `ci.yml:234-246` (stable,
`--document-private-items --workspace`, `-D warnings`) is the closest match to this template's shape;
for lychee, rolldown `link-check.yml` pins `lychee-action` to the same v2.9.0 commit recommended here,
and lychee's own `links.yml` shows the scheduled external lane.

**Maturity, dependability, performance, integration cost.**

- rustdoc gate: zero added dependencies; ships with every toolchain; the fixture's full
  `cargo doc --locked --workspace --no-deps --features web` with `-D warnings` took 0.327 s wall,
  0.70 s user (4 packages, no registry deps, warm `target/`, M-series `arm64`). **executed** (E10). This
  is not representative of the real template, whose `axum`/`tokio` dependency tree must be
  check-built once; in R11's `check` job that metadata is shared with the preceding
  `cargo clippy --features web` step, so the marginal cost is rustdoc over the workspace's own crates.
- lychee: static binary, no runtime; lychee-action download plus an offline pass over a small
  Markdown tree is expected to take seconds, but this was **not measured** (not executed).
- Performance claims from hyperlink's README ("1.1 GB of HTML ... in 4 seconds on a MacBook Pro 2018")
  are a maintainer's own single measurement on a different workload; they are not used to rank tools.

**Minimal realistic example and executable acceptance check.** The executed fixture mirrors R02's
four-package workspace as R11 records it (root facade `rs-launch-blueprint`, `crates/core`,
`crates/cli`, optional `crates/web` behind feature `web`), edition 2024, `rust-version = "1.96"`,
`license = "MIT OR Apache-2.0"`, and runs R11's exact doc-step command
(`ci.candidate.r2.yml:201-203`, sha256 `4eb498c2...71bef`) with and without R82's flags. Results
(E1–E10) are in `### Validation strategy`. The lychee half is **proposed** only.

**BASELINE-REVIEW findings.**

- `BASELINE-REVIEW: F353 — a configured API-reference generator must be a gated one — proposed change: from "configured-but-unused latent investment" (py sphinx.ext.autodoc wired with zero directives, docs/source/conf.py:27; ts TypeDoc as an optional ungated just docs-api, Justfile:198-211) to a CI-gated cargo doc with RUSTDOCFLAGS=-D warnings on every code-changing pull request — evidence: rustdoc ships with the toolchain so the latent-cost reason does not apply; R11 revision 7 already places "the rustdoc part" as check's doc build step (research/topics/11-ci-workflow-job-structure/DECISION.md:294); E2b/E4a show the gate fires on 1.96.0 and 1.98.1; affected items: R11 (step flags), R32 (doctests stay in the test tier).`
- `BASELINE-REVIEW: F350 — external links rot independently of pull requests — proposed change: ts's "no external check" posture is replaced by a scheduled lychee network run, restoring py's weekly behavior (dep-audit.yml:9,17,67-70) — evidence: lychee's own repository, rerun and rustc-dev-guide all keep an external run off the PR path; affected items: R34 (cadence), R20 (action pin).`

### Recommendation

One stack: **`lychee` 0.24.2, installed by `lycheeverse/lychee-action` v2.9.0 (commit
`e7477775783ea5526144ba13e8db5eec57747ce8`), with one repository `lychee.toml`, run twice — offline as a
blocking step of R11's `hygiene` job, and with network access in R34's scheduled lane — plus the
toolchain's own `rustdoc` gated by `RUSTDOCFLAGS: -D warnings` scoped to R11's `check` "Doc build" step,
whose command becomes `cargo doc --locked --workspace --no-deps --features web --document-private-items`.**

| Part | Ledger row | Tool | Trigger | Blocking |
|---|---|---|---|---|
| Internal/relative links in `*.md` | F349 | `lychee --offline --include-fragments` | every PR, push to `main`, `merge_group` (R11 `hygiene`, never path-gated) | yes |
| External URLs | F350 | `lychee` network mode, cached, retried | R34's `canary.yml`: weekly `schedule` + `workflow_dispatch` (py precedent: weekly) | no (reports) |
| API reference | F353 | `cargo doc` + `RUSTDOCFLAGS=-D warnings` | R11 `check` job, both OS legs, when `code == 'true'` | yes |

Answers to the prompt's questions:

- **HIGH (lychee as the single tool):** Yes for the two link-check parts, with one caveat that
  changes the shape: one *tool and config*, two *invocations*. lychee has the highest 90-day
  downloads of the Rust link checkers surveyed (70,748), the most responsive issue tracker
  (median 0.09 days to first maintainer response), explicit `--offline` support that excludes
  every non-`file` URL (`lychee-bin/src/client.rs:22-26` at `lychee-v0.24.2`), and a first-party
  GitHub Action. It does not replace rustdoc: intra-doc links are resolved by rustdoc, not by any
  HTML or Markdown link checker.
- **HIGH (`-D warnings` on `cargo doc`):** Yes. Executed on 1.98.1 and 1.96.0: a broken
  intra-doc link warns and exits 0 without the flag (E2a), and exits 101 with
  ``error: unresolved link to `Nope` `` and ``note: `-D rustdoc::broken-intra-doc-links` implied by `-D warnings` ``
  with it (E2b). It is free: no crate, no config. Two strictness details matter:
  broken links on private items are invisible without `--document-private-items` (E5a exit 0,
  E5b exit 101), and the flag must be scoped to the doc step because cargo also passes
  `RUSTDOCFLAGS` to `rustdoc --test` (E7).
- **MEDIUM (which surface to walk):** Point lychee at Markdown sources, not a build artifact.
  Markdown sources exist under either R81 outcome, and R81 has resolved to both at once (a GitHub-rendered
  `docs/` corpus plus an mdBook 0.5.4 build); `book/` does not exist in the build-free `hygiene` job.
  Add a second, build-output check of the mdBook site only if template/renderer
  breakage becomes a real failure mode (runner-up `hyperlink` or `mdbook-linkcheck2`).
- **MEDIUM (external cadence and flakiness):** Scheduled, never a required PR check; `--max-retries 3`
  (lychee default), `--retry-wait-time 2`, `--timeout 20` (default), `--accept` adds `429`,
  `--cache --max-cache-age 1d` with `.lycheecache` restored by `actions/cache`, `GITHUB_TOKEN`
  (the action's default `token`) for `github.com` links, and a `.lycheeignore` or `exclude` list
  for known-hostile hosts. Practice evidence: rolldown and dioxus accept 429; rerun and dioxus cache;
  lychee, rerun and rustc-dev-guide keep network checks off pull requests.
- **LOW (feature flags for `cargo doc`):** Use the same explicit feature list as R11's other
  feature-on steps (`--features web`), not `--all-features`. Today the two are equivalent
  (E4b and E4c both exit 0). Keeping the list identical to `cargo clippy ... --features web` lets
  the doc step reuse the check-mode dependency metadata already in the shared `target/`; when R78
  (`otel`) and R79 (`metrics`) add features, both steps change together.

### Members

#### lychee offline internal-link check (F349)

##### Landscape

The internal-link bin holds lychee (`--offline`), `hyperlink` (built HTML only), `mlc`,
`mdbook-linkcheck` and its fork `mdbook-linkcheck2` (mdBook only), plus the ts precedent,
a dependency-free Node script (`check-links.mjs`). The first-party Rust tool
(`rust-lang/rust` `src/tools/linkchecker`) is not distributed as a crate; rust-lang/book fetches its
shell wrapper by URL (`main.yml:102-105`).

Figures (endpoints per prompt §7.6; retrieved 2026-09-26 US Pacific):

| Crate | 90-day downloads | All-time | Last non-yanked release | `rust_version` | License (crate) | Repo stars / archived / pushed | Open issues (`search/issues`) | RustSec |
|---|---|---|---|---|---|---|---|---|
| `lychee` | 70,748 | 221,916 | 0.24.2, 2026-05-01T15:41:34Z | 1.88.0 | Apache-2.0 OR MIT | 3,949 / false / 2026-09-21 | 59 | none (404) |
| `lychee-lib` | 73,291 | 198,644 | 0.24.2, 2026-05-01T15:40:44Z | 1.88.0 | Apache-2.0 OR MIT | same repo | same | none (404) |
| `hyperlink` | 614 | 48,460 | 0.3.2, 2026-06-27T22:47:33Z | not declared | MIT | 229 / false / 2026-07-30 | 6 | none (404) |
| `mlc` | 1,516 | 102,553 | 1.2.0, 2025-12-13T22:02:19Z | not declared | MIT | 166 / false / 2026-09-14 | 11 | none (404) |
| `mdbook-linkcheck` | 25,194 | 493,297 | 0.7.7, 2022-10-03T12:51:13Z | not declared | MIT | 170 / false / 2024-08-15 | 31 | none (404) |
| `mdbook-linkcheck2` | 12,894 | 65,963 | 0.13.0, 2026-08-16T06:54:23Z | 1.90 | MIT | 8 / false / 2026-08-16 | 3 | none (404) |

A `rustsec.org/packages/<name>.html` 404 was confirmed to mean "no advisories" by checking that a
crate with advisories (`time`) returns 200.

Issue responsiveness (10 most recently opened issues; first comment by `author_association` OWNER,
MEMBER or COLLABORATOR) and maintenance state by the prompt's rubric:

| Crate | Answered / sample | Median days to first maintainer response | Unanswered | Rubric state and signal |
|---|---|---|---|---|
| `lychee` | 7 / 10 | 0.09 (0.01, 0.05, 0.05, 0.09, 0.85, 1.64, 8.28) | 3 (#2303, #2302 under 11 days old; #2275) | `active` — release 2026-05-01, pushed 2026-09-21 |
| `hyperlink` | 7 / 9 externally opened | 0.29 (0.00, 0.00, 0.01, 0.29, 0.50, 15.63, 15.63) | 2 (#192, #191) | `active` — release 2026-06-27; owner-authored #197 excluded from the median |
| `mlc` | 2 / 10 | 4.67 (2.95, 6.39) | 8, back to 2025-02 | `at-risk` — unanswered backlog is the concrete signal; release 2025-12-13 |
| `mdbook-linkcheck` | 0 / 10 | — | 10 (#89–#99) | `at-risk` — open #96 "fails on mdbook 0.5" and #92, no release since 2022-10-03 |
| `mdbook-linkcheck2` | 5 / 6 (all issues) | 2.90 (0.15, 0.73, 2.90, 3.38, 6.02) | 1 | `active` — release 2026-08-16 |
| `cargo-deadlinks` | not sampled | — | — | `stable-quiet` — no release since 2021-10-13, pushed 2024-12-10, no advisory, no deprecation notice in README; no concrete at-risk signal collected |

##### Principles and implementation

Principle P1 via behavior B1: a relative link in any tracked Markdown file must resolve to an
existing path, checked offline so the result is deterministic. Implementation (**proposed**): a step
in R11's `hygiene` job, after checkout:

```yaml
      - name: Docs link check, offline (R82)
        uses: lycheeverse/lychee-action@e7477775783ea5526144ba13e8db5eec57747ce8 # v2.9.0
        with:
          lycheeVersion: v0.24.2
          args: >-
            --offline
            --include-fragments
            --no-progress
            --root-dir "$(pwd)"
            .
          fail: true
          jobSummary: false
```

`--offline` "Only check local files and block network requests" (lychee README, parameters block);
in source, offline mode replaces the accepted scheme set with `["file"]`
(`lychee-bin/src/client.rs:22-26` at `lychee-v0.24.2`), and a URI whose scheme is not in that set is
`Status::Excluded` (`lychee-lib/src/filter/mod.rs:173-178` and `client.rs:570` on `master` `2c1fb3ad`).
So external URLs are skipped, not failed. `--root-dir` is required "if absolute links appear in local
files, otherwise those links will be flagged as errors" (README); `"$(pwd)"` is the form lychee-action's
README uses (`args: --root-dir "$(pwd)" ...`). A directory input `.` scans lychee's default extensions
(`md,markdown,mdx,...,html,htm,css,txt,xml`). `.lycheeignore` and `exclude_path` handle exceptions.

##### Dominant choice

`lychee` 0.24.2. It has the highest 90-day downloads of the link checkers surveyed, the only
first-party GitHub Action among them, and both modes (offline and network) in one binary.

##### Qualified shortlist

1. `lychee` 0.24.2 — passes every gate (below).
2. `hyperlink` 0.3.2 — passes gates 1 (MIT) and 3 (no advisory); gate 2 not declared
   (`rust-version` absent, `edition = "2018"`; a binary tool, not a dependency); gates 4–6 not examined
   in this leg (gap). It checks built HTML only, so it cannot check the plain-Markdown outcome of R81.
3. `mlc` 1.2.0 — passes gates 1 and 3; maintenance `at-risk` (below).

Gate results for `lychee` (the dominant choice):

1. License: `Apache-2.0 OR MIT` (crate metadata; `lychee-bin/Cargo.toml:9` at the tag) — compatible with `MIT OR Apache-2.0`. Pass.
2. MSRV: `rust-version = "1.88.0"` (`lychee-bin/Cargo.toml:13`), below the 1.96 floor. It is a CI tool binary, not a template dependency, so it never enters the template's dependency tree. Pass.
3. Advisories: none open (rustsec 404, confirmed meaningful). `unsafe`: neither `lychee-lib/src/lib.rs` nor `lychee-bin/src/main.rs` declares `#![forbid(unsafe_code)]` (lint headers read at lines 33-47 and 46-59). Pass with that posture stated.
4. OS: release assets exist for `aarch64-apple-darwin`, `x86_64-apple-darwin`, `x86_64-unknown-linux-gnu` and others, and `x86_64-pc-windows-msvc` (releases API, `lychee-v0.24.2`). lychee's own CI jobs run on `ubuntu-latest` only (`ci.yml` `runs-on` lines 23-104). In this template the check runs only on `ubuntu-latest` (R11's `hygiene`); macOS contributors can install the darwin binary. Pass for the stated use; macOS is built, not CI-tested upstream.
5. Default features: `lychee-lib` `default = ["email-check"]` (`lychee-lib/Cargo.toml:98`); TLS via `rustls` (`:41`); async runtime `tokio` with `features = ["full"]` (`lychee-bin/Cargo.toml:54`). Irrelevant to the template's graph because it is a prebuilt binary.
6. Binary size / compile time: qualitatively large to compile (reqwest, tokio, html5ever-class parsers), which is why the template uses the prebuilt binary; zero compile time added to the template.

##### Excluded by gate

- `mdbook-linkcheck` 0.7.7 — passes numbered gates 1 (MIT) and 3 (no advisory); excluded on the
  maintenance rubric and function, not a numbered gate: open issue #96 "fails on mdbook 0.5" (2025-11-24)
  and #92 "RenderContext parsing error: unknown variant `2024`"; last release 2022-10-03; zero maintainer
  responses in the 10 most recent issues (#89–#99). State: `at-risk` — the concrete signal is
  incompatibility with current mdBook 0.5.x (mdBook 0.5.4, 2026-07-06); there is no unpatched advisory
  or maintainer notice, so `dormant` is not claimed.
- `cargo-deadlinks` 0.8.1 — not excluded by a gate but out of category for F349: it checks `cargo doc` HTML, not the prose tree; last release 2021-10-13; README carries no deprecation notice (read).
- Non-Rust tools (`markdown-link-check`, Sphinx linkcheck, `check-links.mjs`) — out of category; they would add a Node or Python runtime to a Rust template's `hygiene` job. ts rejected `markdown-link-check` because it "adds a network-capable dependency and still needs config to skip external URLs" (`check-links.mjs:6-7`); lychee's `--offline` is that config as a single flag.

##### Up-and-comers

`mdbook-linkcheck2` 0.13.0 (fork of `mdbook-linkcheck`; `rust_version` 1.90; 12,894 90-day downloads;
5 of its 6 issues answered, median 2.90 days; adopted by rust-lang/rustc-dev-guide at 0.13.0 with mdBook
0.5.2, `ci.yml:17-18`). R81 now builds with mdBook 0.5.4, so it is a viable renderer-integrated addition if a build-output check is ever wanted.

##### Fit for this template

Fits all three surfaces (CLI, library, web service) identically, because the prose tree is shared.
It fits R11's `hygiene` constraints: no Rust toolchain, no cache, no `target/`, `ubuntu-latest`.
`cargo install lychee` is ruled out there by R11 (no cache; a from-source build would dominate the job),
hence the prebuilt binary via the action. It fits R81's resolved model (GitHub-rendered `docs/` plus an mdBook build) because it reads the Markdown sources both consume, including `docs/SUMMARY.md`.
mdBook-specific syntax (`{{#include}}`) is not a link and is ignored; mdBook's `.md`→`.html`
rewriting means source links target `.md` files, which is what lychee resolves.

##### Recommendation

`lychee` 0.24.2 via `lycheeverse/lychee-action` at commit `e7477775783ea5526144ba13e8db5eec57747ce8`
(tag `v2.9.0`, whose `action.yml` default `lycheeVersion` is already `v0.24.2`), invoked with
`--offline --include-fragments --no-progress --root-dir "$(pwd)" .` as a blocking step of `hygiene`.
The pin *format* (full SHA plus version comment) is R20's; the SHA above is the one R20's format would
carry for this tag.

##### Ranked runner-up

`hyperlink` 0.3.2 — the right tool if the gate must also check R81's rendered mdBook
output (`hyperlink public/ --sources src/ --check-anchors`). It has no network mode, so it would need
lychee for F350 anyway, which is why it ranks second.

##### Tradeoffs

- One binary for both link parts versus the best-in-class HTML checker: accepted, because
  hyperlink's maintainer calls `lychee --offline public/` "more or less equivalent".
- `--include-fragments` gains anchor checking over ts's script, at the risk of false positives where
  lychee's heading-slug generation differs from GitHub's or mdBook's renderer. The risk is concrete for
  this template: R81 forbids explicit `{ #id }` heading attributes (`DECISION.md:156`), so every anchor is an
  auto-generated slug, and the same bytes are rendered by both GitHub and mdBook 0.5.4. Not executed; this
  is the first thing P03 must validate. Fallback: drop the flag (ts parity).
- lychee-action's installer downloads the release tarball with `curl -sfLO` and extracts it without a
  checksum step (`action.yml` v2.9.0, `curl -sfLO` at line 89, `tar -xvzf` at line 92; no `sha256` in the file). A SHA-pinned
  action pins the installer script, not the binary. Accepted with the version pinned via
  `lycheeVersion`; noted for R20/R08.
- `failIfEmpty` defaults to `true`: an empty docs tree fails the step. Acceptable; the template always has links.

##### Parameters

- assumes ci-job-structure: the link check is a step of `hygiene`, never path-gated (R11 `DECISION.md:294`).
- no owned parameter.

##### Migration implications

Add the `hygiene` step above (replacing R11's placeholder `Docs link-check slot (R82)`,
`ci.candidate.r2.yml:141-142`); add `lychee.toml` and optionally `.lycheeignore` at the repository root;
add a `just docs-check` recipe (`lychee --offline --include-fragments --no-progress --root-dir "$(pwd)" .`)
so the local command matches ts's recipe name (`Justfile:195-196` in ts). Delete nothing: the template
has no predecessor script.

##### Validation strategy

**Proposed** (not executed — lychee not installed): in a fixture with `README.md` linking
`[a](docs/a.md)` and `[b](docs/missing.md)`, `lychee --offline --no-progress --root-dir "$(pwd)" .`
must exit **2** ("Link check failures", README exit-code table) naming `docs/missing.md`; after removing the
broken link it must exit **0**; a link to `https://unreachable.invalid/` must appear as excluded, not failed,
under `--offline`. Repeat with `--include-fragments` and a `[c](docs/a.md#no-such-heading)` link, expecting exit 2.

##### Confidence & re-verify trigger

High for the choice of lychee and the `--offline` semantics (read at the release tag). Medium for
`--include-fragments` (not executed). Re-verify on a lychee minor release (0.25), a lychee-action major
(v3), an R81 revision, or 2027-03-26.

##### Sources

- crates.io `GET /api/v1/crates/{lychee,lychee-lib,hyperlink,mlc,mdbook-linkcheck,mdbook-linkcheck2,cargo-deadlinks}` and `/versions`, retrieved 2026-09-26.
- `GET https://api.github.com/repos/lycheeverse/lychee` and `search/issues?q=repo:lycheeverse/lychee+is:issue+is:open`, retrieved 2026-09-26.
- lychee README (`api.github.com/repos/lycheeverse/lychee/contents/README.md`), sections "Commandline Parameters", "Exit codes", "Ignoring and excluding links", "Caching", "Users", retrieved 2026-09-26.
- `lychee-bin/src/client.rs`, `lychee-bin/Cargo.toml`, `lychee-lib/Cargo.toml` at ref `lychee-v0.24.2`; `lychee-lib/src/filter/mod.rs`, `lychee-lib/src/client.rs` at `master` `2c1fb3ad1373`, retrieved 2026-09-26.
- `lycheeverse/lychee-action` `action.yml` and README at `v2.9.0`, retrieved 2026-09-26.
- hyperlink README (`api.github.com/repos/untitaker/hyperlink/contents/README.md`), retrieved 2026-09-26.
- `rustsec.org/packages/<name>.html` for each crate above and `time.html` as the positive control, retrieved 2026-09-26.
- ts `scripts/check-links.mjs:1-23`, `Justfile:195-196`, `.github/workflows/ci.yml:97-98` at `cb1cbcb2`.

#### lychee external-URL check (F350)

##### Landscape

Same binary and figures as the F349 member (`lychee` 0.24.2). Other network-capable Rust
checkers: `mlc` 1.2.0 and `mdbook-linkcheck2` (web links as an mdBook backend option, as used by
rustc-dev-guide with `FOLLOW_WEB_LINKS`). `hyperlink` has no network mode ("Hyperlink does not know how
to make network calls", README). Precedent: py's weekly `sphinx-build -b linkcheck` (`dep-audit.yml:53-70`,
`cron: '0 5 * * 1'` at line 17); ts has none.

##### Principles and implementation

Principle P2 via behavior B3: external reachability is non-deterministic (hosts rate-limit, time out,
block CI IP ranges), so it must never block a pull request, but it must run often enough that rot is
reported. Implementation (**proposed**), as its own job in R34's `.github/workflows/canary.yml` — a
separate job, not a leg of R34's freshness matrix, because it varies no upstream toolchain or dependency:

```yaml
  docs-external-links:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - name: Restore lychee cache
        uses: actions/cache/restore@<R20-pinned sha> # v5
        with:
          path: .lycheecache
          key: cache-lychee-${{ github.sha }}
          restore-keys: cache-lychee-
      - name: External link check (R82)
        uses: lycheeverse/lychee-action@e7477775783ea5526144ba13e8db5eec57747ce8 # v2.9.0
        with:
          lycheeVersion: v0.24.2
          args: >-
            --cache --max-cache-age 1d
            --cache-exclude-status '429, 500..'
            --max-retries 3 --retry-wait-time 2 --timeout 20
            --accept '100..=103, 200..=299, 429'
            --no-progress
            --root-dir "$(pwd)"
            .
          fail: true
      - name: Save lychee cache
        if: ${{ !cancelled() }}
        uses: actions/cache/save@<R20-pinned sha> # v5
        with:
          path: .lycheecache
          key: cache-lychee-${{ github.sha }}
```

Every flag above is quoted from lychee's parameter block: `--max-retries` (default 3),
`-r, --retry-wait-time` (default 1), `-t, --timeout` (default 20), `-a, --accept`
(default `100..=103,200..=299`), `--cache`, `--max-cache-age` (default `1d`),
`--cache-exclude-status` (range syntax `500..`). The action's `token` input defaults to
`${{ github.token }}`, which lychee uses "to avoid getting rate-limited while checking GitHub links"
(README, "GitHub Token"). The split restore/save cache pattern is lychee-action's own README example.

##### Dominant choice

`lychee` 0.24.2, the same pinned binary and `lychee.toml` as the F349 member, in network mode.

##### Qualified shortlist

1. `lychee` — retry and backoff, per-host throttling, respects rate limits (README feature table),
   on-disk cache, first-party action.
2. `mlc` 1.2.0 — network-capable; ranks below on maintenance (below).
3. `mdbook-linkcheck2` — viable now that R81 builds with mdBook; ties the lane to `mdbook build`.

##### Excluded by gate

- `mdbook-linkcheck` — same gate-4 failure as in the F349 member.
- `hyperlink` — not excluded by a gate but lacks the capability (no network calls).

##### Up-and-comers

lychee's own newer controls: `--host-concurrency` and `--host-request-interval` (README examples:
"`--host-request-interval 1s` # Conservative for rate-limited APIs") and `--suggest` with a web archive for
replacements. `mdbook-linkcheck2` as above.

##### Fit for this template

Fits: the template's docs will link to crates.io, docs.rs, GitHub and standards bodies — hosts that
rate-limit. Maintenance evidence for the dominant choice: lychee median first maintainer response
0.09 days across the 10 most recently opened issues (7 answered: 0.01, 0.05, 0.05, 0.09, 0.85, 1.64,
8.28 days; 3 unanswered, two of them under 11 days old at retrieval) — `active`. For comparison, `mlc`:
2 of its 10 most recent issues answered (median 4.67 days), 8 unanswered back to 2025-02 — `at-risk`
(concrete signal: unanswered issue backlog), though it released 1.2.0 on 2025-12-13 and was pushed
2026-09-14.

##### Recommendation

Run lychee in network mode as a job of R34's `canary.yml` (weekly `schedule` plus `workflow_dispatch`); never add it to
`ci.yml` or to required checks (R11 `DECISION.md:294`: "An external-URL check R82 puts on a schedule
belongs to R34's scheduled lane, not `ci.yml`"). This item's posture for R34: the check is
network-flaky and rate-limited, so it belongs on a schedule; py's precedent is weekly;
lychee's own repository runs it daily (`links.yml:6-7`) and rustc-dev-guide every 8 hours (`ci.yml:8-10`).
A failure should be visible (failed scheduled run, or an issue) rather than silently ignored.

##### Ranked runner-up

Same tool, same scheduled lane, plus a non-blocking PR run limited to URLs added by the diff, as rerun
does (`reusable_checks.yml:325-333`, a custom `link-check-pr` script). It catches a typo'd new URL
before merge at the cost of a custom script; rejected for the template on the no-single-use-helper principle.

##### Tradeoffs

- Scheduled-only means a broken external URL can merge and live until the next run; accepted, matching py.
- Accepting 429 hides a real 429-returning dead link; accepted because rolldown and dioxus do the same
  and 429 means "rate-limited", not "missing".
- `--cache-exclude-status '429, 500..'` re-checks transient failures next run rather than caching them.

##### Parameters

- assumes ci-job-structure: the scheduled lane is outside `ci.yml` (R11 `DECISION.md:294`).
- no owned parameter; cadence is R34's.

##### Migration implications

A job in R34's scheduled workflow file (not `ci.yml`); a shared `lychee.toml` at the root holding only
`exclude_path = ["target"]` and any `exclude` patterns (keys as used in DioxusLabs/dioxus `lychee.toml:2-3`);
`.lycheecache` added to `.gitignore`.

##### Validation strategy

**Proposed:** `lychee --no-progress --max-retries 1 --timeout 5 README.md` on a fixture containing one
reachable and one `https://unreachable.invalid/` link must exit 2 and name only the second;
re-running with `--accept '200..=299, 429'` must not change the result; a second run with `--cache` must
create `.lycheecache`. In CI (P03): a manual `workflow_dispatch` of the scheduled job on the template must
complete and upload a job summary.

##### Confidence & re-verify trigger

High that external checking belongs off the PR path (py, lychee, rerun, rustc-dev-guide agree; flakiness
is inherent). Medium on the exact retry/accept values (practice-derived, not measured). Re-verify when
R34 is revised, on a lychee minor release, or 2027-03-26.

##### Sources

- py `.github/workflows/dep-audit.yml:1-17,53-70`, `.github/workflows/ci.yml:226-229` at `b08bccfb`.
- lychee README "Commandline Parameters", "GitHub Token", "Caching"; lychee `.github/workflows/links.yml:1-22` (`6163192f069f`).
- lychee-action README "Utilising the cache feature" and `action.yml` at `v2.9.0`.
- DioxusLabs/dioxus `lychee.toml` (`2c28fd4707ae`); rolldown `link-check.yml` (`c32d9ee0720e`); rerun `reusable_checks.yml` (`167a5ce3b428`); rust-lang/rustc-dev-guide `ci.yml` (`71b709a3379d`), all via the contents API, retrieved 2026-09-26.
- GitHub issues API for `becheran/mlc` and `lycheeverse/lychee` (10 most recent issues and their comments), retrieved 2026-09-26.

#### rustdoc API-reference gate (F353)

##### Landscape

Built-in: `rustdoc` with its lint group (`rustdoc -W help` lists 11 `rustdoc::` lints plus the
`rustdoc::all` group on both 1.98.1 and 1.96.0; 4 are allow-by-default and 7 are warn-by-default: `bare-urls`, `broken-intra-doc-links`,
`invalid-codeblock-attributes`, `invalid-html-tags`, `invalid-rust-codeblocks`, `private-intra-doc-links`,
`redundant-explicit-links`). Two ways to raise them: `RUSTDOCFLAGS` (env) or Cargo's `[lints.rustdoc]`
manifest table. Adjacent: `cargo test --doc` (R32), `cargo docs-rs` (dtolnay; needs nightly, as serde's
job shows at `ci.yml:133-135`), `cargo-deadlinks` (built HTML; last release 2021-10-13).

Crate figures: `inapplicable — rustdoc is a toolchain component shipped with every Rust toolchain, not a crate`
for 90-day downloads, all-time downloads, last release, stars, open issues, issue responsiveness, advisories
and reverse dependencies. Adopter evidence is taken from project workflows instead (ripgrep, tokio, axum,
serde, lychee — see `### Landscape`).

##### Principles and implementation

Principle P1 via behavior B2, the `sphinx-build -W` parity point: every warning the API-reference
generator emits fails the pull request. Implementation (**proposed** for CI; the command itself **executed**):
R11's existing step, with R82's flags:

```yaml
      - name: Doc build
        if: ${{ !cancelled() }}
        env:
          RUSTDOCFLAGS: -D warnings
        run: cargo doc --locked --workspace --no-deps --features web --document-private-items
```

- `-D warnings` turns every warn-by-default rustdoc lint into an error (E2b, E8), including lints that
  future toolchains add — the same open-ended strictness as Sphinx `-W`.
- `--document-private-items` extends link checking to private items' docs; without it a broken link on a
  private item passes (E5a exit 0; E5b exit 101). It does not mask the public-to-private link error
  (E9: exit 101 with and without the flag, on 1.98.1 and 1.96.0). ripgrep and tokio use it.
- `--features web` makes the facade's feature-gated re-export exist, so doc links into it resolve (E4a vs E4b).
- `env:` on the step, not the job: cargo passes `RUSTDOCFLAGS` to `rustdoc --test` too (E7: the verbose
  doctest invocation carries `-D warnings`), so a job-level setting would change R32's doctest step.

##### Dominant choice

`RUSTDOCFLAGS=-D warnings` on `cargo doc`, the form used by ripgrep (`-D warnings`), serde (`-Dwarnings`),
tokio (`-Dwarnings`), lychee itself (`-D warnings`), and — in its `-D rustdoc::all` variant — axum.

##### Qualified shortlist

1. `RUSTDOCFLAGS=-D warnings`, step-scoped (recommended).
2. `[workspace.lints.rustdoc]` with each warn-by-default lint set to `"deny"`, members opting in with
   `[lints] workspace = true` — executed working at both 1.96.0 and 1.98.1 (E3, exit 101).
3. `RUSTDOCFLAGS="-D rustdoc::all -A rustdoc::private-doc-tests"` (axum) — stricter: also enables the
   allow-by-default `missing-crate-level-docs` and `unescaped-backticks`.

Gate results (toolchain component): 1 license — the Rust toolchain is `MIT OR Apache-2.0`, pass;
2 MSRV — lint names and behavior identical on 1.96.0 and 1.98.1 (E1–E9 both), pass; 3 advisories —
inapplicable to a toolchain component; `unsafe` posture inapplicable; 4 OS — executed on macOS `arm64`;
runs in R11's `check` matrix on both `ubuntu-latest` and `macos-latest` (**proposed**); 5 default features —
inapplicable; the feature question is the template's own (`--features web`); 6 size/compile time — no binary
added; compile cost is rustdoc over workspace crates plus dependency metadata shared with the clippy step.

##### Excluded by gate

- `cargo docs-rs` and `--cfg docsrs` / `doc_cfg` badges — fail the stable-only constraint (`cargo docs-rs`
  requires nightly; serde runs it on `dtolnay/rust-toolchain@nightly`, `ci.yml:133`).
- `cargo-deadlinks` 0.8.1 — not a gate failure (license `MIT OR Apache-2.0`, no advisory), but redundant:
  rustdoc resolves intra-doc links itself and reports them (E2), and the crate's last release was 2021-10-13.

##### Up-and-comers

None in this bin. rustdoc's allow-by-default `unescaped-backticks` and `missing-crate-level-docs` (the
latter "intended to make this a warning" per `lints.md:151`) would be picked up automatically by `-D warnings`
if a future toolchain promotes them — a deliberate property of the recommendation.

##### Fit for this template

CLI, library and web: all three are library crates in R02's four-package workspace plus binaries, and
`--workspace` documents every member, including `crates/web` even with the feature off. The facade's
re-export is the only feature-dependent doc surface, which `--features web` covers. Running on both OS
legs costs little and catches `cfg(target_os)`-gated doc links; that placement is R11's.

##### Recommendation

`RUSTDOCFLAGS: -D warnings` as step-level `env:` on R11's `Doc build` step, with the command
`cargo doc --locked --workspace --no-deps --features web --document-private-items`.

##### Ranked runner-up

The manifest lint table (`[workspace.lints.rustdoc]`, each warn-by-default lint `= "deny"`). It gives
local `cargo doc` the same failure as CI, but fails only on listed lints, so it is weaker than `-W` parity,
and it touches the shared `[workspace.lints]` table that the lint-policy items own. Adding
`broken_intra_doc_links = "deny"` there is compatible with the recommendation and can be done by those items.

##### Tradeoffs

- Toolchain bumps can introduce new rustdoc warnings that fail CI (same as `clippy -D warnings`); accepted
  as the price of `-W` parity.
- `--document-private-items` makes private docs part of the gate, adding friction for contributors
  writing internal comments; accepted because broken private links otherwise go unseen (E5a).
- A lib and a bin with the same name make `cargo doc` warn about an output-filename collision; that is a
  cargo warning, not a rustdoc one, so `RUSTDOCFLAGS` does not fail it. R02's binary names
  (`rslbp-serve` per R11's candidate) do not collide with the library name.

##### Parameters

- assumes web-extra-surface: the feature is named `web` and consumers select it with `--features web` or `--all-features` (R69).
- assumes ci-job-structure: the rustdoc part is `check`'s doc build step, whose flags are R82's (R11 `DECISION.md:294`).
- no owned parameter.

##### Migration implications

One edit to R11's `ci.yml` `Doc build` step (add `env: RUSTDOCFLAGS: -D warnings` and
`--document-private-items`); a `just docs-api` recipe (name kept from ts, `Justfile:203`) running the same
command locally with the same env; no crate added. When R78 (`otel`) and R79 (`metrics`) add features,
extend this step's feature list together with R11's clippy feature-on step.

##### Validation strategy

**Executed** (E1–E10, full commands and outputs in `### Validation strategy` below): clean pass; broken
link warns without the flag and fails with it; the lint-table alternative fails; feature-gated link fails
without `--features web` and passes with it; private broken link caught only with
`--document-private-items`; doctest runtime failure not seen by `cargo doc` but seen by `cargo test --doc`;
`RUSTDOCFLAGS` reaches `rustdoc --test`; bare URL fails under `-D warnings`; public-to-private link fails in
both modes. All on 1.98.1 and 1.96.0.

##### Confidence & re-verify trigger

High: executed on the current stable and the MSRV floor, and matched by five well-regarded projects.
Re-verify on R02 changing the package graph, on R69 adding features, on a rustdoc lint promotion that
breaks the template's docs, or 2027-03-26.

##### Sources

- `rust-lang/rust` `src/doc/rustdoc/src/lints.md:16-18,67-69,151` via contents API, retrieved 2026-09-26.
- `rustdoc -W help` on 1.98.1 (Homebrew) and 1.96.0 (rustup), executed 2026-09-27 UTC.
- BurntSushi/ripgrep `ci.yml:234-246`; tokio `ci.yml:896-905`; axum `CI.yml:34-49`; serde `ci.yml:125-138`; lychee `ci.yml:67-70`, via contents API, retrieved 2026-09-26.
- R11 `research/topics/11-ci-workflow-job-structure/DECISION.md:294,442`; `research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/evidence/ci.candidate.r2.yml:119-142,161-203`.
- py `docs/source/conf.py:26-30`, `.github/workflows/ci.yml:230-242`; ts `Justfile:198-211` at the pins.

### Compatibility

The three members share no library boundary: the two lychee members are the same pinned binary and
the same `lychee.toml`, and the rustdoc member is the toolchain. The evidence that they are used together:

- **lycheeverse/lychee itself** runs `cargo doc --workspace --no-deps` with `RUSTDOCFLAGS: -D warnings`
  in `ci.yml:67-70` and a scheduled lychee link check in `links.yml:3-22` — the exact pairing recommended
  here (rustdoc gate on PR, network link check on a schedule), in one maintained repository.
- **DioxusLabs/dioxus** runs lychee on every push next to Rust jobs in the same `main.yml` (`:4`,
  "Language linting (typos, link-check) runs on every push; Rust jobs are gated behind path checks") — the
  same always-run-hygiene / gated-compile split R11 adopted.
- **Version matrix** for this stack: `lychee` 0.24.2 (`rust-version` 1.88.0, prebuilt) × `lychee-action`
  v2.9.0 (default `lycheeVersion: v0.24.2`, so the pin agrees with the action's own default) × rustdoc
  1.96.0–1.98.1 (executed). The lychee binary never links against the template, so there is no
  dependency-resolution interaction.

### Parameters

- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner
- (reading of ci-job-structure this item relies on: R82's link check is a step of the always-run `hygiene` job, never path-gated; R82's rustdoc part is `check`'s doc build step, whose flags are R82's; an external-URL check belongs to R34's scheduled lane, not `ci.yml`; the `docs` detector output gates no job — R11 `DECISION.md:294`.)
- assumes rust-edition = `2024`; msrv-policy = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license = `MIT OR Apache-2.0`; target-os-matrix = `ubuntu-latest, macos-latest` (fixed, owner).
- owns: none (the prompt's `owns:` is empty).
- No `CONFLICT:` lines. The recommendation fits every consumed value as written.

### Migration implications

| File | Change | Owner of the surrounding structure |
|---|---|---|
| `.github/workflows/ci.yml` — `hygiene` job | replace the `Docs link-check slot (R82)` placeholder with the `lychee-action` offline step | R11 (placement), R20 (pin format) |
| `.github/workflows/ci.yml` — `check` job `Doc build` step | add step-level `env: RUSTDOCFLAGS: -D warnings`; append `--document-private-items` | R11 (step), R82 (flags) |
| `.github/workflows/canary.yml` (R34's schedule-only workflow) | add a `docs-external-links` job (network lychee, cache restore/save), separate from R34's freshness matrix | R34 (cadence and file) |
| `lychee.toml` (new, repo root) | `exclude_path = ["target"]`; `exclude = [...]` only for known-hostile hosts | R82 |
| `.lycheeignore` (optional, new) | per-URL exclusions, one regex per line | R82 |
| `.gitignore` | add `.lycheecache` | R82 |
| `Justfile` | `docs-check` → `lychee --offline --include-fragments --no-progress --root-dir "$(pwd)" .`; `docs-api` → `RUSTDOCFLAGS="-D warnings" cargo doc --locked --workspace --no-deps --features web --document-private-items` | the task-runner item |
| `CONTRIBUTING.md` / docs | one line: install lychee (`brew install lychee` or `cargo binstall lychee`) to run `just docs-check` locally | R81 (docs tree) |

Removed relative to the sources: Sphinx configuration (py) and `scripts/check-links.mjs` (ts) have no
equivalent file in the template.

### Validation strategy

**Executed checks (this leg).** Fixture: a four-package workspace mirroring R02 as R11 records it —
root facade `rs-launch-blueprint` (`[features] web = ["dep:rs-launch-blueprint-web"]`, `#[cfg(feature = "web")] pub use rs_launch_blueprint_web as web;`),
`crates/core` (one doctest), `crates/cli`, `crates/web`; `resolver = "3"`, edition 2024,
`rust-version = "1.96"`, `license = "MIT OR Apache-2.0"`; `Cargo.lock` generated offline. Each case copies
the clean fixture, applies one mutation, and runs one command. Script sha256
`a7b5204f97972fda3207702ca35b3f57049b0cc15098c01e84fcd2ba0e2d4fcc`; output files sha256
`1607cfb391527d56363d2014196ca426c4930700a7ed97f458207cb4c09b50f8` (1.98.1) and
`452cf5f783c7ba703d5113a07ddc5f13b7da24c79814efcb873247a397a8d98a` (1.96.0). Run 2026-09-27T00:54:30Z–00:54:46Z UTC.
Working directory: the per-case copy `c_<id>` under the scratch root.
Base command below is `cargo doc --locked --workspace --no-deps`, abbreviated `DOC`.

| ID | Mutation | Command | 1.98.1 exit | 1.96.0 exit | Key output |
|---|---|---|---|---|---|
| E1 | none | `RUSTDOCFLAGS="-D warnings" DOC --features web` | 0 | 0 | — |
| E2a | ``/// Broken link to [`Nope`].`` on a pub fn in core | `DOC --features web` (no `RUSTDOCFLAGS`) | 0 | 0 | ``warning: unresolved link to `Nope` `` |
| E2b | same | `RUSTDOCFLAGS="-D warnings" DOC --features web` | 101 | 101 | ``error: unresolved link to `Nope` ``; ``note: `-D rustdoc::broken-intra-doc-links` implied by `-D warnings` `` |
| E3 | same + `[workspace.lints.rustdoc] broken_intra_doc_links = "deny"`, `[lints] workspace = true` in all four manifests | `DOC --features web` (no `RUSTDOCFLAGS`) | 101 | 101 | ``error: unresolved link to `Nope` ``; ``error: could not document `rs-launch-blueprint-core` `` |
| E4a | facade crate doc gains ``[`web::serve`]`` | `RUSTDOCFLAGS="-D warnings" DOC` (feature off) | 101 | 101 | ``error: unresolved link to `web::serve` `` |
| E4b | same | `RUSTDOCFLAGS="-D warnings" DOC --features web` | 0 | 0 | — |
| E4c | same | `RUSTDOCFLAGS="-D warnings" DOC --all-features` | 0 | 0 | — |
| E5a | private fn with ``[`AlsoNope`]`` | `RUSTDOCFLAGS="-D warnings" DOC --features web` | 0 | 0 | none — not reported |
| E5b | same | `... --document-private-items` | 101 | 101 | ``error: unresolved link to `AlsoNope` `` |
| E6a | doctest asserts `"goodbye"` | `RUSTDOCFLAGS="-D warnings" DOC --features web` | 0 | 0 | — (doctests not run) |
| E6b | same | `cargo test --locked --doc -p rs-launch-blueprint-core` | 101 | 101 | `test crates/core/src/lib.rs - greet (line 5) ... FAILED` |
| E7 | none | `RUSTDOCFLAGS="-D warnings" cargo test --locked --doc -p rs-launch-blueprint-core -v` | — | — | the `rustdoc ... --test` argv contains `-D warnings` (count 1 on both) |
| E8 | `/// See https://example.com/spec for details.` | `RUSTDOCFLAGS="-D warnings" DOC --features web` | 101 | 101 | `error: this URL is not a hyperlink`; ``note: `-D rustdoc::bare-urls` implied by `-D warnings` `` |
| E9 | pub fn doc links ``[`hidden`]`` (private fn) | `RUSTDOCFLAGS="-D warnings" DOC --features web` with and without `--document-private-items` | 101 / 101 | 101 / 101 | ``error: public documentation for `exposed` links to private item `hidden` `` |
| E10 | none | E1's command, timed | 0 | not timed | 0.327 s wall, 0.70 s user, 0.21 s system |

Reproduction: the fixture and script are small enough to rebuild from the table; the per-case commands
are exactly as listed, run with `CARGO_NET_OFFLINE=true`, using `/opt/homebrew/bin/cargo` (1.98.1) and
`rustup run 1.96.0 cargo` (1.96.0).

**Planned checks (not executed here), for P03 against the real template:**

1. `just docs-check` on the template tree exits 0; adding `[x](docs/missing.md)` to `README.md` makes it exit 2; adding `- [Missing](missing.md)` to `docs/SUMMARY.md` also makes it exit 2 without mdBook installed (R81's `DECISION.md:1274-1277` requirement). (lychee, **proposed**)
2. `--include-fragments` produces no false positives on the template's real headings, under both the plain-tree and the mdBook outcome of R81. (**proposed**; fallback: drop the flag)
3. In GitHub Actions: a PR adding a broken relative link fails `hygiene`; a PR adding ``[`Nope`]`` fails `check (ubuntu-latest)` and `check (macos-latest)` at `Doc build`, while `Test, web feature on` still runs and reports (R11's `!cancelled()`). (**proposed**)
4. A PR adding an unreachable external URL passes every required check; a `workflow_dispatch` of R34's lane reports it. (**proposed**)
5. `cargo doc` on the real template with `axum`/`tokio` resolves every intra-doc link into those crates with `--no-deps` (rustdoc resolves external-crate paths from metadata). (**proposed**)

### Confidence & re-verify trigger

- **rustdoc gate — high.** Executed on the current stable (1.98.1) and the MSRV floor (1.96.0);
  identical results; matches ripgrep, tokio, serde, axum and lychee.
- **lychee for both link parts — high on tool choice, medium on flags.** Tool choice rests on figures,
  maintainer responsiveness, the release-tag source for `--offline`, and adopters' workflows. Flags are
  verified against lychee's own documentation, but lychee was **not executed**; `--include-fragments`
  false-positive behavior is the largest open risk.
- **Trigger split (PR offline, scheduled external) — high.** Both source repos' intent, three Rust
  adopters, and lychee's own repository agree.

re-verify: 2027-03-26, or earlier on any of — an R81 revision (docs tree shape; `docs/SUMMARY.md` role); an R34 revision (cadence and file for the external job); R69 or R78/R79 adding
Cargo features (doc step feature list); R02 changing the package graph; a lychee 0.25 or lychee-action v3
release; a Rust release that promotes an allow-by-default rustdoc lint.

### Sources

All retrieved 2026-09-26 US Pacific unless marked executed.

1. crates.io API — `https://crates.io/api/v1/crates/{lychee,lychee-lib,hyperlink,mlc,mdbook-linkcheck,mdbook-linkcheck2,cargo-deadlinks,linkcheck,mdbook}` and `/versions`; `/reverse_dependencies` for `lychee-lib` (total 3: `refman`, `lychee`, `acorn-lib`), `lychee`, `hyperlink`, `mdbook-linkcheck2` (total 0 each).
2. GitHub REST — `https://api.github.com/repos/<o>/<r>` for lycheeverse/lychee, lycheeverse/lychee-action, untitaker/hyperlink, Michael-F-Bryan/mdbook-linkcheck, marxin/mdbook-linkcheck2, becheran/mlc, deadlinks/cargo-deadlinks, tokio-rs/tokio, tokio-rs/axum, serde-rs/serde, BurntSushi/ripgrep, rerun-io/rerun, DioxusLabs/dioxus, rolldown/rolldown, rust-lang/rustc-dev-guide, rust-lang/book, rust-lang/mdBook.
3. GitHub search — `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` `total_count` for the seven candidate repositories.
4. GitHub issues and comments — `repos/<o>/<r>/issues?state=all&sort=created&direction=desc` and `issues/<n>/comments` for lychee, hyperlink, mdbook-linkcheck, mdbook-linkcheck2, mlc; maintainer = `author_association` in {OWNER, MEMBER, COLLABORATOR}.
5. RustSec — `https://rustsec.org/packages/<name>.html` for each candidate (all 404 = no advisories) and `time.html` (200) as the positive control.
6. lychee README, `lychee-bin/src/client.rs`, `lychee-bin/Cargo.toml`, `lychee-lib/Cargo.toml`, `lychee-lib/src/lib.rs`, `lychee-bin/src/main.rs` at `lychee-v0.24.2`; `lychee-lib/src/filter/mod.rs`, `lychee-lib/src/client.rs` at `master` `2c1fb3ad1373`; `.github/workflows/ci.yml`, `.github/workflows/links.yml`, `lychee.toml` at `master` — via `api.github.com/repos/lycheeverse/lychee/contents/`.
7. lychee releases — `repos/lycheeverse/lychee/releases` (asset list for `lychee-v0.24.2`, 2026-05-01T15:41:38Z).
8. lychee-action — `action.yml` and README at `v2.9.0`; `git/ref/tags/v2.9.0` → `e7477775783ea5526144ba13e8db5eec57747ce8`; releases list (v2.9.0 2026-07-09, v2.8.0 2026-02-25).
9. hyperlink README; cargo-deadlinks README; mdbook-linkcheck2 README; mdbook-linkcheck issues #92, #96, #98.
10. rustdoc book — `rust-lang/rust` `src/doc/rustdoc/src/lints.md`.
11. Workflows — ripgrep `.github/workflows/ci.yml` (`d958105d412b`), tokio `ci.yml` (`f26c9663546a`), axum `CI.yml` (`8a68ea9da77e`), serde `ci.yml` (`6dec3b751126`), rerun `reusable_checks.yml` (`167a5ce3b428`), dioxus `main.yml` and `lychee.toml` (`2c28fd4707ae`), rolldown `link-check.yml` (`c32d9ee0720e`), rustc-dev-guide `ci.yml` (`71b709a3379d`), rust-lang/book `main.yml`.
12. Source repositories at the pins — py `.github/workflows/ci.yml:225-242`, `.github/workflows/dep-audit.yml:1-17,53-70`, `docs/source/conf.py:23-30`; ts `.github/workflows/ci.yml:85-101`, `scripts/check-links.mjs:1-70`, `Justfile:195-211`.
13. Programme inputs — `research/runs/R82/2026-09-26T190316Z-971c9d005dbf/inputs/{prompt.md,PARAMETERS.md,parameters.json,prerequisites.json}`; R11 `DECISION.md:93,191,294,442`; R11 `ci.candidate.r2.yml` (sha256 `4eb498c2a9bde032cd9202aaed69bc898d7a63a51e423e740a1b3bd1db371bef`).
14. Executed — `rustdoc -W help` on 1.98.1 and 1.96.0; experiments E1–E10 as tabulated in `### Validation strategy`, 2026-09-27T00:54Z UTC.
