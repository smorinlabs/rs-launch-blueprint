# R14 — large-file-guard-strategy (bundle) — Opus raw research report

Engine: `claude-opus-5-5` (Opus seat, Claude Code CLI), run
`2026-09-26T190144Z-53ff8e94fbd8`, prompt sha256
`2b501625f6b514bf908c075f3341ac6b2ed4672bd5fccda788141b75db7d6d7a` (matches
`manifest.json` `input_hashes.prompt`; `inputs/prompt.md` is byte-identical to
`research/topics/14-large-file-guard-strategy/prompts/large-file-guard-strategy.prompt.md`).
Independent leg: `raw/muse.md` and every other engine's report for this run
were never opened.

Source repositories are read at the programme pins: `py-launch-blueprint` at
`b08bccfb55d05f15e46a83b52c5660b1881d19f5`, `ts-launch-blueprint` at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`. The prerequisite R11 decision is
read at sha256 `410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c`
(matches `inputs/prerequisites.json`), and its candidate fixture
`research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/evidence/ci.candidate.r2.yml`
at sha256 `4eb498c2a9bde032cd9202aaed69bc898d7a63a51e423e740a1b3bd1db371bef`.
Every retrieval date is **2026-09-26** (UTC). Claims are labelled
**executed** (run on this host in this leg), **read** (file or API content
read in this leg), **computed** (arithmetic over read source, not run) or
**proposed** (not run).

Host for every executed check: macOS 26.4 `Darwin arm64`; `git` 2.50.1 (Apple
Git-155); `/bin/sh` = GNU bash 3.2.57 in POSIX mode; `/bin/dash` (the shell
Ubuntu installs as `/bin/sh`); `lefthook` 2.1.14; `git-lfs` 3.8.0;
`actionlint` 1.7.12; `shellcheck` from Homebrew; `cargo`/`rustc` 1.98.1.
Network endpoints used: `api.github.com` (through `gh api`) and `crates.io`
and `rustsec.org`, the endpoints the prompt's figure table names. Scratch
lived in `$TMPDIR/r14-opus` (outside the repository). Scratch artifacts and
their sha256:

| File | sha256 | Role |
|---|---|---|
| `check-large-files.sh` | `1ba847e3eaa187aa7dee161fb7154bf2a0e75fb5dafc99f94ec32db917241f30` | the reference implementation (46 lines, reproduced in full under `### Principles and implementation`) |
| `run-check.sh` | `85963ff32ed439d0c9c554343a3265bfcddb009501d161e85bb06cd276f308e2` | consolidated executed check; transcript under `### Validation strategy` |
| `run-check.log` | `b6d892645f3c62749e4be77bf9496145773ded53aa697fc10b9531410d968b1f` | its output: `FAILS=0 of 42` |
| `survey.sh` / `survey.log` | `b63aa25a…` / `ac11b98c…` | practice survey of 26 Rust repositories |
| `sizes.sh` / `sizes.log` | `40dc9ebf…` / `e2b783de…` | committed-blob size profile of 14 repositories |
| `py-ci-body.sh` | `d4534594…` | py `large-file-guard.yml:36-62` run body, verbatim (indent stripped) |
| `py-hook-body.txt` / `ts-hook-body.txt` | `7da0823e…` / `0adc87ad…` | py `lefthook.yml:137-148`, ts `lefthook.yml:38-48`, verbatim |
| `wf/.github/workflows/ci.yml` | `af5c874bf6fdc412a530d89db9193fcb7f437d0031e29b4aabfd97d8aab16942` | R11's fixture plus this item's step; `actionlint` exit 0 |

### Landscape

**The category this item decides.** Not a crate. It is the *repository
hygiene guard against accidentally committed large blobs*: at which points in
a change's life a size rule is enforced (the contributor's git hook, the CI
run on the pull request, the forge's push endpoint), what the rule measures
(a path event such as "file added", or a blob entering history), the byte
threshold, and how an intentional large file is exempted. Two ledger rows ride
on it: **F043** (CI tier, `ci-workflows`) and **F172** (hook tier,
`git-hooks-commit-hygiene`), both `DIVERGENT`, both `Item: R14`
(`docs/port/COMMONALITY.md:49`, `:176`).

**Three-bin map.** Every candidate below was found in the sources in this
section, not taken from familiarity.

| Bin | Candidate | Where it was observed (read 2026-09-26) |
|---|---|---|
| Built-in / first-party | **B1. `.gitignore` of `target/`** — the first line of defence against Rust build artifacts | **executed**: `cargo new` (Cargo 1.98.1, default `--vcs git`) writes a `.gitignore` whose only line is `/target`. It prevents *most* accidental binaries but not a binary copied out of `target/` |
| Built-in / first-party | **B2. GitHub's platform limits** — a Git warning above 50 MiB, a hard block above 100 MiB, 25 MiB for a browser upload | `github/docs` `data/variables/large_files.yml` at `18945a31a4f2d97beb6c5c1a7479102e23c25727` (`warning_size: '50 MiB'`, `max_github_size: '100 MiB'`, `max_github_browser_size: '25 MiB'`), used by `content/repositories/working-with-files/managing-large-files/about-large-files-on-github.md:34-39` |
| Built-in / first-party | **B3. GitHub push rulesets, "Restrict file size"** — the forge rejects the push itself, for the whole fork network, with allowed-exception paths | `available-rules-for-rulesets.md` "## Restrict file size"; availability in `data/reusables/gated-features/repo-rules.md`: "Push rulesets are available for the GitHub Team plan in internal and private repositories, and forks of repositories that have push rulesets enabled" |
| Built-in / first-party | **B4. Git LFS** — the routing mechanism for *intentional* large files: the commit carries a pointer blob | `about-git-large-file-storage.md` (same `github/docs` pin); executed: a 2 MiB LFS-tracked file stages a **132-byte** pointer blob (`H8`) |
| Built-in / first-party | **B5. Git primitives for a hand-written guard** — `git diff --cached --raw`, `git rev-list --objects`, `git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)'`, `git check-attr` | used by the reference implementation below; executed on git 2.50.1 |
| Established industry standard | **E1. `pre-commit/pre-commit-hooks` `check-added-large-files`** — the de-facto hook, default `--maxkb=500`, checks only files "staged for addition", skips LFS files, `--enforce-all` widens it | source at `44d7f9b7e32225d2bd590282037e4650064f3950`: `pre_commit_hooks/check_added_large_files.py:49-50` (`kb = math.ceil(os.stat(filename).st_size / 1024)`; `if kb > maxkb`), `:68` (`default=500`), `util.py:12` (`git diff --staged --name-only --diff-filter=A`); README lines 26-33. 6,691 stars, not archived, latest release `v6.0.0` 2025-08-09. Rust adopter: `pydantic/pydantic-core` `.pre-commit-config.yaml:11` at `383eb95a1943` |
| Established industry standard | **E2. Hand-rolled POSIX-shell hook in the hook manager's config** (py and ts at their pins) | py `lefthook.yml:132-148`; ts `lefthook.yml:34-48` |
| Established industry standard | **E3. Hand-rolled CI step over the pull request's diff** (py's `large-file-guard.yml`) | py `.github/workflows/large-file-guard.yml:1-62` |
| Established industry standard | **E4. Repository-specific "tidy"-style check** — the principle (no accidental binaries, because they bloat history) enforced by a proxy rule rather than a byte threshold | `rust-lang/rust` `src/tools/tidy/src/bins.rs:1-6` at `0b80633005f5`: "Tidy check to ensure that there are no binaries checked into the source tree by accident. In the past we've accidentally checked in test binaries and such which add a huge amount of bloat to the Git history"; its rule is the executable bit, not size. `style.rs:6` caps non-Rust files at 3000 lines |
| Up-and-comer | **U1. `prek` built-in `check-added-large-files`** — a Rust reimplementation of pre-commit that runs this hook natively, with no Python | `j178/prek` `crates/prek/src/hooks/pre_commit_hooks/check_added_large_files.rs` at `5ba6dc58a6285c551620354f139bbd8b5fa60e23` (`default_value = "500"` at `:22`; `metadata(file_path).await?.len() / 1024` then `if size > args.max_kb` at `:65-66`); registered as a builtin in `crates/prek/src/hooks/builtin_hooks/mod.rs:42`, `:159-167`. 8,471 stars; crate `prek` 0.5.3 |
| Up-and-comer | **U2. `ppremk/lfs-warning` (formerly `ActionsDesk/lfs-warning`)** — a JavaScript action that labels and comments on pull requests containing files above a size, default `10mb` | `action.yml` (`runs.using: "node20"`, `filesizelimit` default `"10mb"`); `src/index.ts:98`, `:102`, `:163` (`issues.addLabels`, `issues.createComment`, `issues.createLabel`). 39 stars, latest release `v3.3` 2024-04-04, last push 2024-09-07 |

**Authoritative sources and why each counts.**

- **GitHub's own documentation**, read from its source repository
  `github/docs` at `18945a31a4f2d97beb6c5c1a7479102e23c25727` through
  `api.github.com`. It is the platform owner's normative statement of the
  size limits (B2), push-ruleset behaviour and availability (B3), LFS (B4)
  and the `merge_group` payload (`src/webhooks/data/fpt/merge_group.child-params.json`:
  `base_sha` — "The SHA of the merge group's parent commit", `isRequired: true`).
- **The maintainers' own source for the two hook implementations**:
  `pre-commit/pre-commit-hooks` (E1) and `j178/prek` (U1), at the commits
  above. For a hook's semantics (which files, which rounding, LFS handling)
  the source is ground truth; the README is the maintainer's statement of
  intent.
- **The Rust project's own tooling**: `rust-lang/rust` `tidy` (E4). It is the
  Rust project stating the principle in its own words, which is why it is
  cited even though its rule differs.
- **`crates.io`, `api.github.com`, `rustsec.org`** — the endpoints the
  prompt's figure table names, for U1's figures.
- **Executed behaviour** on this host: 42 checks in `run-check.sh`, including
  py's and ts's guard bodies verbatim and `lefthook` 2.1.14 itself. For a
  guard's correctness, observed behaviour on fixtures outranks any prose.
- No single blog post is used as an authority anywhere.

**Practice evidence — what well-regarded Rust repositories do.** Survey of
26 repositories at their default-branch tips (`survey.sh`). **What was
searched, exactly:** (a) the repository root listing, for any of
`.pre-commit-config.yaml`, `.pre-commit-config.yml`, `prek.toml`,
`lefthook.yml`, `lefthook.yaml`, `.lefthook.yml`; (b) the *contents* of each
such file found, for the case-insensitive string `large`; (c) the *file
names* (not the contents) under `.github/workflows/`, for
`large|size|lfs|blob`.

| Repository @ commit | Stars | Hook config found | Large-file hook | Workflow *named* for a size check |
|---|---|---|---|---|
| `astral-sh/ruff` @ `e4dd9152790f` | 49,802 | `.pre-commit-config.yaml` | none | none |
| `astral-sh/uv` @ `136ef9733078` | 90,199 | none | — | none |
| `astral-sh/ty` @ `8e4aef298ab0` | 19,755 | `.pre-commit-config.yaml` | none | none |
| `bevyengine/bevy` @ `0f38358f573a` | 48,401 | none | — | none |
| `zed-industries/zed` @ `bda9c0bd43a8` | 90,932 | none | — | none |
| `tokio-rs/tokio` @ `facc6fc47eb2` | 33,246 | none | — | none |
| `tokio-rs/axum` @ `bc8d49124352` | 27,258 | none | — | none |
| `BurntSushi/ripgrep` @ `3fce3b5bb023` | 68,626 | none | — | none |
| `clap-rs/clap` @ `8ab46fe22b4a` | 16,725 | `.pre-commit-config.yaml` | none | none |
| `rust-lang/cargo` @ `07b80494920f` | 15,520 | none | — | none |
| `rust-lang/rust` @ `0b80633005f5` | 119,209 | none (tidy, E4) | — | none |
| `rust-lang/crates.io` @ `067b45e1a15f` | 3,703 | none | — | none |
| `rust-lang/rust-analyzer` @ `86493cee4d89` | 16,876 | none | — | none |
| `pola-rs/polars` @ `750bbaa9054c` | 39,869 | none | — | none |
| **`pydantic/pydantic-core` @ `383eb95a1943`** | 1,765 | `.pre-commit-config.yaml` | **`check-added-large-files`, default args** (line 11) | none |
| `denoland/deno` @ `b157cd27e153` | 108,525 | none | — | none |
| `biomejs/biome` @ `a62070a04bdb` | 25,863 | none | — | none |
| `tauri-apps/tauri` @ `447fa9f3f993` | 111,411 | none | — | none |
| `crate-ci/typos` @ `00f422f3b19c` | 4,158 | `.pre-commit-config.yaml` | none | none |
| `oxc-project/oxc` @ `e996e6c04f80` | 22,893 | none | — | none |
| `j178/prek` @ `5ba6dc58a628` | 8,471 | `prek.toml` | none | none |
| `sharkdp/bat` @ `4987f76709aa` | 60,582 | none | — | none |
| `nushell/nushell` @ `2459fdd134ea` | 40,580 | none | — | none |
| `helix-editor/helix` @ `079a789e8cb0` | 46,346 | none | — | none |
| `meilisearch/meilisearch` @ `909ef7fef5ba` | 59,414 | none | — | none |
| `swc-project/swc` @ `763cc20be690` | 34,207 | none | — | `binary-size.yml` (build-output size, not committed files) |

Result: **1 of 26** has a hook-tier large-file guard (a content read);
**0 of 26** has a workflow file *named* for a committed-file size check (a
file-name search only — a size check embedded in a differently named workflow
would not be found by this search, so this is not a census of CI-tier
guards). The honest reading is that a byte-threshold guard is **not** a
mainstream Rust-ecosystem practice; the mainstream practice is B1
(`.gitignore`) plus B2 (the forge's own limits) plus review. That is evidence
about *prevalence*, not about fitness: a template's job is to protect
contributors who have not yet learned the repository's norms, and the
principle (E4's own words) is endorsed by the Rust project. It means the
design must be justified from the principle, and cannot be justified by
"everyone does it".

**Committed-blob size profile** (`sizes.sh`, git trees API, recursive, none
truncated). This is the evidence the threshold question needs.

| Repository @ commit | Shape | Blobs | > 512000 B | > 1048576 B | `Cargo.lock` bytes | Largest blob |
|---|---|---|---|---|---|---|
| `tokio-rs/tokio` @ `facc6fc47eb2` | library | 882 | 0 | 0 | not committed | 179,850 `tokio/CHANGELOG.md` |
| `tokio-rs/axum` @ `bc8d49124352` | web library | 503 | 0 | 0 | 58,140 | 125,586 `examples/Cargo.lock` |
| `clap-rs/clap` @ `8ab46fe22b4a` | CLI library | 645 | 0 | 0 | 113,876 | 234,862 `CHANGELOG.md` |
| `BurntSushi/ripgrep` @ `3fce3b5bb023` | CLI | 237 | 0 | 0 | 13,550 | 246,353 `crates/core/flags/defs.rs` |
| `j178/prek` @ `5ba6dc58a628` | CLI | 352 | 0 | 0 | 97,822 | 236,257 `docs/assets/logo.png` |
| `pydantic/pydantic-core` @ `383eb95a1943` | library | 270 | 0 | 0 | 24,242 | 160,607 `uv.lock` |
| `rust-lang/crates.io` @ `067b45e1a15f` | web service | 2,259 | 0 | 0 | 231,200 | 335,981 `pnpm-lock.yaml` |
| `sharkdp/bat` @ `4987f76709aa` | CLI | 914 | 1 | 0 | 78,464 | 1,012,454 `assets/syntaxes.bin` (intentional) |
| `rust-lang/cargo` @ `07b80494920f` | CLI | 3,073 | 1 | 1 | 130,617 | 2,449,408 bench sample; `doc/book/src/CHANGELOG.md` 449,255 |
| `crate-ci/typos` @ `00f422f3b19c` | CLI | 251 | 12 | 9 | 52,512 | 12,706,587 generated `codegen.rs` |
| `astral-sh/uv` @ `136ef9733078` | CLI | 1,791 | 14 | 4 | 190,188 | 3,176,495 `download-metadata.json`; 2,107,264 insta `.snap` |
| `astral-sh/ruff` @ `e4dd9152790f` | CLI | 11,174 | 11 | 6 | 140,438 | 5,562,434 benchmark snapshot |
| `bevyengine/bevy` @ `0f38358f573a` | game engine | 3,032 | 29 | 17 | not committed | 6,792,052 `.ktx2` asset |
| `zed-industries/zed` @ `bda9c0bd43a8` | application | 4,324 | 20 | 5 | **503,922** | 4,471,092 `.gif` |

Two facts carry the threshold decision. (1) **Every repository shaped like
this template (library, CLI, web service) has zero blobs over 512000 bytes**
— seven of seven, largest 335,981 bytes. (2) **Legitimately growing generated
files approach 512000 bytes in mature projects**: zed's `Cargo.lock`
503,922 bytes (98.4 % of 512000), cargo's `CHANGELOG.md` 449,255 bytes, and
py's own `uv.lock` 445,494 bytes at its pin (`git ls-tree -l b08bccfb…`,
executed). Every file above 1 MiB in the table is intentional (generated code,
test snapshots, benchmark data, game assets).

**The accidental-artifact side, executed on this host** (`cargo build`,
offline, from the local registry cache): a `cargo new` hello-world is
**433,792 bytes** (release) and **437,464 bytes** (debug); a minimal
`clap` 4.6.7 derive CLI is **921,344 bytes** (release) and **3,671,864
bytes** (debug); a minimal `axum` 0.8.9 + `tokio` 1.53.1 server is
**1,631,984 bytes** (release). macOS `arm64`, default profiles; Linux
binaries differ in size and were not built.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** The principle is py's own recorded "Why" for F043: "accidental
binary commits bloat history permanently and are painful to excise"
(`docs/source/about/design_decisions.md:445-450` at the py pin), which the
Rust project states in the same terms for its own tree (`tidy/src/bins.rs:4-6`,
E4). Stated as a requirement: **a blob larger than a declared size cannot
enter the default branch's history by accident; an intentional one enters
only through a reviewable, declared exception; and the repository states the
rule once.** The level at which py, ts and rs must agree is **capability plus
policy**, not mechanism:

| Must agree — capability and policy | May vary — ecosystem-local |
|---|---|
| A local guard runs before the commit exists (fast feedback) | Which hook manager runs it (R37) and in which language the guard is written |
| A server-side guard that a contributor cannot skip backs it | Whether the server-side guard is a CI step or a forge rule (B3 is unavailable to public repositories on the plans in use) |
| The guard measures what bloats history — **every blob a change introduces, added or modified, in any commit** — not only "files added in the final tree" | The listing primitive (`git rev-list --objects`, a platform API) |
| Both tiers read **one** rule definition (threshold, comparison, exemption) | Where the definition lives, as long as both tiers read it |
| An unknown base, a git error or an unparseable name **fails closed** | — |
| Intentional large files are routed to LFS or declared per path | The declared exception syntax |
| The byte threshold is stated exactly (bytes and comparison operator) | The value, **if** an ecosystem's legitimate-file profile differs (the evidence says it does not; see below) |

**What the two source implementations do, and what fails, executed.** The
bodies were extracted verbatim from the pins and run on fixtures
(`run-check.sh`); IDs refer to the transcript under `### Validation strategy`.

| Behaviour | py CI `large-file-guard.yml` | py hook `lefthook.yml:135-148` | ts hook `lefthook.yml:36-48` | Reference script |
|---|---|---|---|---|
| Unit measured | added *paths* in the final tree (`--diff-filter=A`, `:42`; `[ -f "${FILE}" ] \|\| continue`, `:46`) | every staged path, working-tree size | every staged path, working-tree size | every introduced **blob** |
| Blob added in commit 1, deleted in commit 2 of the same PR | **passes** (`R1py`); after `git merge --no-ff` of that branch, the blob is reachable from `main` although absent from its tree (`R1m`) | n/a | n/a | fails (`R1`) |
| Modified file grown past the threshold | **passes** (`R4py`) | fails | fails (`L6`) | fails (`H5`, `R4`) |
| Empty or all-zero base | **skips with exit 0** — fails open (`:38-41`, `R3py`) | n/a | n/a | checks all history (`R3`, `R3e`) |
| File name containing a space | **word-splits and passes** (`for FILE in ${ADDED}`, `:44`; `R5py`) | rejected the spaced name when run by lefthook (`L4`) | fails correctly (`L5`) | fails (`H4`, `R5`) |
| Staged content differs from the working tree | n/a | reads the working tree | reads the working tree | reads the staged blob (`H7a`, `H7b`) |
| LFS-tracked large file | not special-cased | not special-cased | not special-cased | passes: the staged blob is a 132-byte pointer (`H8`) |
| Exemption | path prefix `docs/assets/` (`:34`) | `docs/assets/*` (`:140`) | none | per-path attribute `large-file-ok` (`H6`) |
| `wc -c` left padding on macOS (`[  600000]`) | stripped with `tr -d ' '` | stripped | **not stripped**, but `[ "$size" -gt 512000 ]` still compares numerically under bash 3.2 and dash (`W-sh`, `W-dash`) | not applicable (`cat-file` sizes) |

The single most important row is the first. The owner's organisation merges
with **merge commits** and has squash merging disabled (user instructions,
"Git Merge & Sync Strategy"; rebase merging also preserves every commit). So
every commit of a pull request lands on `main`, and a blob added and removed
inside a pull request is permanent history bloat that a final-tree check
cannot see. That is exactly the failure the principle names.

**Provenance finding for the controller (F172), not an edit.** The ledger and
`docs/port/DIVERGENCE-ANALYSIS.md:98` record F172 as class **A** with "no
recorded reason for the value difference", and the prompt describes 500 KB as
"the drift ts's port introduced". The pinned sources say otherwise:

1. py's own pre-lefthook configuration ran `check-added-large-files` with
   **no arguments**, i.e. the 500 KB default: `git show fe96899^:.pre-commit-config.yaml`,
   line 40 (`- id: check-added-large-files`), in the py repository; commit
   `fe96899` "feat: retire pre-commit framework (itm-020 partial)", 2026-05-24.
2. ts ported *that* hook and says so: ts `lefthook.yml:34-35` — "Reject staged
   files larger than 500KB (pre-commit's check-added-large-files intent;
   dependency-free POSIX shell)". `-gt 512000` is byte-exact with
   pre-commit-hooks' `math.ceil(size / 1024) > 500` (**computed**: both reject
   512001 bytes and accept 512000).
3. py **raised** its hook to 1 MB on 2026-06-14 so that it mirrors its CI
   guard: py `docs/adr/0018-hook-ci-parity-and-boundary-gate.md:88-90` —
   "Large-file guard at pre-commit: reject staged files over 1 MB outside
   `docs/assets/`, the same threshold and allowlist as the `large-file-guard`
   CI workflow"; the CI guard itself came from `7ac7716` "feat: add large-file
   ci guard (itm-028)", 2026-05-24.

So the difference is not accidental ts drift. ts kept the inherited
ecosystem default, while py deliberately aligned its hook with its CI tier
under a stated parity rule. **The sub-row class should read "py changed
deliberately (ADR 0018); ts retained the pre-commit default", not "no
recorded reason".** This is recorded as a finding here, following R11's
precedent of not raising `BASELINE-REVIEW:` against a `DIVERGENT` row that
the item itself decides. **No `BASELINE-REVIEW:` line is raised by this
report.**

**Second finding (the MEDIUM question): py's exemption names a directory that
does not exist.** `git ls-tree -r --name-only b08bccfb… -- docs/assets` lists
**0 entries** (executed). py's one sizeable image,
`assets/images/logos/py_launch_blueprint_logo_1024x1024.png` (289,468 bytes),
lives outside `docs/assets/` and is under both thresholds anyway. The
exemption has never exempted anything at the pin.

**Architectural alternatives, compared before any tool.**

| Alternative | Catches `--no-verify`, hook-less clones, web uploads, bots | Catches intermediate-commit blobs | Available to this public template | Cost | Verdict |
|---|---|---|---|---|---|
| **A. Hook tier only** (ts) | no — executed: `git commit --no-verify` commits a 2 MiB file past the installed hook (`L2`) | only per commit, locally | yes | none | **Rejected as sufficient** (HIGH question 1) |
| **B. CI tier only** | yes | if it walks the range | yes | one CI step | **Rejected as sufficient**: feedback arrives after the push, when the blob is already in the contributor's local history and must be rewritten out |
| **C. Hook + CI, independent definitions** (py; ts's drift risk) | yes | py's CI does not (`R1py`) | yes | two definitions that can drift | Rejected: the drift is the exact failure the LOW question describes |
| **D. Hook + CI, one script, blob scope, fail-closed** | yes (`L3`) | yes (`R1`) | yes | one 46-line script, one CI step | **Selected** |
| **E. Forge push ruleset "Restrict file size"** (B3) | yes, and rejects the push itself | yes | **no** — push rulesets are for private and internal repositories on paid plans (`repo-rules.md`); the template is public (`gh api repos/smorinlabs/rs-launch-blueprint` → `"visibility":"public"`) | settings, not files | Excluded for the template; documented as an optional layer for private adopters |
| **F. GitHub's 100 MiB block alone** (B2) | yes | yes | yes | none | Rejected as sufficient: two orders of magnitude above any threshold this principle needs; history is already bloated at 50 MiB |

**The recommended design, and how it preserves each principle.**

1. **One rule, stated once.** `scripts/check-large-files.sh` carries the
   threshold (`max=1048576`, comparison `>`) and reads exemptions from
   `.gitattributes`. The hook and the CI step both call the script, so a
   threshold change is a one-line diff reviewed once (LOW question).
2. **Blob scope.** `--staged` lists every blob the index would commit (added,
   modified or type-changed; gitlinks skipped, `H9`) and sizes the **staged
   blob** with `git cat-file`, not the working-tree file. `--range BASE HEAD`
   lists every object `git rev-list --objects BASE..HEAD` reports, which is
   every blob introduced by any commit in the range, including one deleted
   later (`R1`), and excludes a blob already in the base (`R6`).
3. **Fail closed.** An empty or all-zero base checks all of HEAD's history
   instead of skipping (`R3`, `R3e`); an unknown base is exit 2 (`R7`). No
   stage is a pipeline whose left side can fail silently: every git call
   writes a temporary file and is checked (the lesson R11 recorded as
   `R5-D4`/`R5-D8`).
4. **Exemptions are declared per path in `.gitattributes`**, the file that
   already carries LFS routing: `path/glob large-file-ok`. The script reads it
   with `git check-attr --cached`, so a hook sees the staged `.gitattributes`
   and CI sees HEAD's (`H6`). LFS needs no special case, because the committed
   blob is the pointer (`H8`).
5. **Portable.** POSIX `sh`, `git`, `awk`, `sed`, `mktemp` only; `shellcheck
   -s sh` clean; executed under bash 3.2 (macOS `/bin/sh`) and dash (Ubuntu's
   `/bin/sh`). No Rust crate, so no MSRV, binary-size or compile-time cost.

The complete reference implementation (**executed**; sha256
`1ba847e3eaa187aa7dee161fb7154bf2a0e75fb5dafc99f94ec32db917241f30`):

```sh
#!/bin/sh
# check-large-files.sh - R14 reference: one rule, two tiers.
#   --staged           hook tier: every blob the index would commit (added or modified)
#   --range BASE HEAD  CI tier: every blob any commit in BASE..HEAD introduces;
#                      an empty or all-zero BASE checks all of HEAD's history
# Rule: a blob larger than 1048576 bytes (1 MiB) fails unless .gitattributes
# gives its path the attribute large-file-ok. Git LFS pointers are small blobs.
# Exit 0 pass, 1 violation, 2 usage or git error (fails closed).
set -eu
max=1048576
tmp=$(mktemp) || exit 2
trap 'rm -f "$tmp"' EXIT

list_staged() {
  # :oldmode newmode oldsha newsha status<TAB>path ; gitlinks (160000) are not blobs
  git -c core.quotePath=false diff --cached --no-renames --no-ext-diff --raw \
    --diff-filter=AMT >"$tmp" || exit 2
  awk -F '\t' '{ split($1, m, " "); if (m[2] != "160000") print m[4] " " $2 }' "$tmp" >"$tmp.objs" || exit 2
  mv "$tmp.objs" "$tmp"
}

list_range() {
  base=$1 head=$2
  case "$base" in ''|0000000000000000000000000000000000000000) range=$head ;; *) range="$base..$head" ;; esac
  git -c core.quotePath=false rev-list --objects "$range" >"$tmp" || exit 2
}

case "${1:-}" in
  --staged) [ $# -eq 1 ] || exit 2; list_staged ;;
  --range) [ $# -eq 3 ] || exit 2; list_range "$2" "$3" ;;
  *) echo "usage: $0 --staged | --range BASE HEAD" >&2; exit 2 ;;
esac

git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' <"$tmp" >"$tmp.sizes" || exit 2
status=0
while IFS=' ' read -r type size path; do
  [ "$type" = blob ] && [ "$size" -gt "$max" ] || continue
  if [ "$(git check-attr --cached large-file-ok -- "$path" | sed 's/.*: large-file-ok: //')" = set ]; then
    echo "ALLOW: $path is $size bytes (large-file-ok)"
    continue
  fi
  echo "FAIL: $path is $size bytes (> $max). Remove it, track it with Git LFS, or mark it large-file-ok in .gitattributes." >&2
  status=1
done <"$tmp.sizes"
rm -f "$tmp.sizes"
exit "$status"
```

Known limits of this reference, stated rather than hidden: a path containing
a newline, tab, double quote or backslash is printed C-quoted by git, so it
is still size-checked (the size does not depend on the name) but cannot be
exempted by attribute, which fails closed. A path with trailing spaces loses
them to `read`, with the same fail-closed result. `rev-list --objects` names
a blob by the first path it meets, so a blob committed at two paths is judged
by one of them. The `trap` removes only `$tmp`; `$tmp.sizes` leaks on an
exit-2 path (cosmetic). The script under review is itself in the pull request,
so a contributor can weaken it in the same change; that edit is visible in the
diff, as for every in-repository check.

**Threshold (HIGH question 2): scope first, then value.** Because the guard
measures every introduced blob, modified files included, the threshold must
clear legitimately *growing* generated files, not just new ones. The profile
above puts those at 503,922 bytes (zed `Cargo.lock`), 449,255 bytes (cargo
`CHANGELOG.md`) and 445,494 bytes (py `uv.lock`): a 512000-byte limit clears
them by 1.6 % to 15 %, so a mature adopter's lockfile or release-please
changelog would start failing a guard meant only for accidents, which trains
the `--no-verify` habit the hook exists to avoid. **1048576 bytes gives at
least 2.08× headroom over every legitimate file observed in any template-shaped
repository and over every growing generated file observed anywhere.** What it
concedes, measured: a minimal `clap` release binary (921,344 bytes) and a
hello-world binary (433,792 bytes) pass it. The template's own artifacts do
not: its root package hosts the web-serving binary (R11's
`ci-job-structure`, "the root package that hosts the serve binary depends on
every member"), and even a minimal `axum` + `tokio` release binary is
1,631,984 bytes, and the `clap` debug binary is 3,671,864 bytes (the
hello-world debug binary, 437,464 bytes, passes). Binaries left inside
`target/` never reach the guard provided the template's `.gitignore` (a P03
file; the template has none yet) keeps `cargo new`'s `/target` line (B1).
**Recommendation: `> 1048576` bytes, on every introduced blob, both tiers.**
Had the scope been "added files only" (E1, py CI), 512000 would be the
defensible value (pre-commit's default, and no template-shaped repository has
a blob that large); the blob scope is chosen because it is what the principle
protects, and the value follows from it.

**Is a shared value justified across py, ts and rs?** The prompt allows a
shared low-level value only when evidence supports the same tradeoff in every
ecosystem. It does here, because the driver is ecosystem-general: each
template commits a generated lockfile that grows with its dependency count
(`uv.lock` 445,494 bytes in py, `pnpm-lock.yaml` 133,991 bytes in ts, and
`Cargo.lock` measured up to 503,922 bytes in Rust), and each ships a
release-please changelog. **Recommendation for the follow-on project:** all
three use 1048576 bytes on blob scope with one definition per repository.
**py:** keep the value; fix the four executed defects of its CI body
(`R1py`, `R3py`, `R4py`, `R5py`) and drop the dead `docs/assets/` prefix.
**ts:** add the CI tier; move to blob scope at 1 MiB, since its current
all-staged-files hook at 512000 bytes will start rejecting ordinary
`pnpm-lock.yaml` growth (`L6` shows it checks modified files).

**Placement relative to R11 (not a `CONFLICT:`).** R11's `ci-job-structure`
rule places "every non-compiling check whose input no key contains" in the
always-run `hygiene` job. The large-file guard compiles nothing and its input
is every changed path, so it is a **step of `hygiene`**, not a dedicated
workflow file as in py. One consequence R11's fixture does not yet carry:
`hygiene` checks out at the default depth (`ci.candidate.r2.yml:125-127`, no
`fetch-depth`), and a range walk needs the history. Options: (a) give
`hygiene`'s checkout `fetch-depth: 0`, as `plan` already has (`:54-57`);
(b) have the step deepen its own clone; (c) check only the tree at HEAD,
which needs no history but misses the intermediate-commit blob (`R1`).
**This report recommends (a)**: for a template-sized repository a full clone
costs little, and (c) gives up the principle's main case. Because R14 does not
consume `ci-job-structure`, this is written as a slot note for the controller
and R11's owner, not as a `CONFLICT:` line. The event bases are
`github.event.pull_request.base.sha` (`pull_request`),
`github.event.merge_group.base_sha` (`merge_group`) and `github.event.before`
(`push` to `main`; all zeros on the first push, which the script turns into a
full-history check). `actionlint` 1.7.12 accepts R11's fixture with the step
added (exit 0, zero diagnostics, file sha256 `af5c874b…`).

**Production usage and maintained reference examples.** No surveyed Rust
repository ships this exact two-tier shape (the survey above), so there is no
production adopter of the *combination*; this is an evidence gap, stated.
Each part has a maintained precedent: the hook contract is pre-commit-hooks'
(E1; `pydantic-core` uses it) and prek's (U1); the blob-scope principle is
the Rust project's own (E4); the listing primitives are git's. The composed
example is executed end to end on this host: `lefthook` 2.1.14 rejects the
commit (`L1`), `--no-verify` bypasses it (`L2`), and the CI mode catches the
bypass (`L3`). **Performance**: not benchmarked. The workload is one
`rev-list` plus one `cat-file --batch-check` over the objects a pull request
introduces; `run-check.sh`, which runs 42 checks and builds a new repository
for most of them, finished in well under a minute on this host (not
instrumented, so no figure is claimed).

**Acceptance criteria (observable).**

| # | Criterion | Status |
|---|---|---|
| 1 | A staged blob of 1048577 bytes blocks the commit; 1048576 bytes passes | **executed** `H2`, `H3` (both shells) |
| 2 | A modified file grown past the threshold is caught at both tiers | **executed** `H5`, `R4` |
| 3 | A blob added and deleted inside one pull request fails the CI tier | **executed** `R1` |
| 4 | An empty, all-zero or unknown base never passes silently | **executed** `R3`, `R3e`, `R7` |
| 5 | A name with spaces is checked and reported | **executed** `H4`, `R5` |
| 6 | A `.gitattributes` `large-file-ok` path passes and is reported `ALLOW:` | **executed** `H6` |
| 7 | An LFS-tracked file passes because its committed blob is a pointer | **executed** `H8` |
| 8 | A `--no-verify` commit is caught by the CI tier | **executed** `L1`–`L3` |
| 9 | The CI step is valid workflow YAML inside R11's graph | **executed** `actionlint` exit 0 |
| 10 | The step passes on `ubuntu-latest` and a real pull request, push and merge-queue run | **proposed** — not run on a GitHub-hosted runner |

### Recommendation

**One stack: the named pattern `single-rule blob-size guard, two tiers`** — a
46-line POSIX-sh script `scripts/check-large-files.sh` that fails any blob
larger than **1048576 bytes** entering history unless `.gitattributes` marks
its path **`large-file-ok`**. It runs in two places: (1) at **pre-commit** in
`--staged` mode through whichever hook manager R37 selects, and (2) as a step
of R11's always-run **`hygiene`** job in `ci.yml`, in `--range BASE HEAD`
mode over every commit of the change, which needs `fetch-depth: 0` on that
job's checkout. No crate, no third-party action, no dedicated workflow file.
The template ships **no path exemption**; intentional large files go to Git
LFS or get a per-path `large-file-ok` line. Private adopters may add a
GitHub push ruleset "Restrict file size" as a third layer.

### Members

#### Shared rule: threshold, blob scope and exemption

##### Landscape
The rule's reference points are pre-commit-hooks' `--maxkb=500` with ceil
rounding on added files (E1), prek's `--maxkb=500` with **floor** rounding on
added files (U1), py's `> 1048576` bytes with a `docs/assets/` prefix, ts's
`> 512000` bytes with no exemption, GitHub's 50 MiB warning and 100 MiB block
(B2), and the push-ruleset exception list (B3). Exemption mechanisms observed:
a path-prefix constant (py), none (ts), git attributes (E1 and U1 read
`filter=lfs` through `git check-attr` to skip LFS files), and ruleset
exception patterns (B3).

##### Principles and implementation
One definition read by both tiers, in bytes with a stated comparison, over
every introduced blob, failing closed. Implemented as the `max=1048576`
constant and the `large-file-ok` attribute query inside
`scripts/check-large-files.sh`; the hook and the CI step both call the script,
so neither can drift from the other.

##### Dominant choice
In practice, the pre-commit default (500 KiB on added files) is the dominant
*value*: it is the E1 default, ts inherits it, and `pydantic-core` uses it
unmodified. No ecosystem-dominant exemption mechanism exists beyond LFS.

##### Qualified shortlist
1. **1048576 bytes, blob scope, attribute exemption** (recommended).
2. 512000 bytes, added-files scope, attribute exemption (E1's contract).
3. 1048576 bytes, added-files scope, directory prefix (py's contract).
Crate figures are **inapplicable**: the rule is a constant and a git
attribute, not a crate.

##### Excluded by gate
None fails a numbered gate. Gate 1 (licence) passes: the script is template
code under `MIT OR Apache-2.0`. Gates 2, 3, 5 and 6 are **inapplicable**, since
there is no Rust code, no dependency tree, no `unsafe`, no features or async
runtime, and no binary or compile-time cost. Gate 4 passes on macOS
(executed) and is proposed for Ubuntu (dash executed as its `/bin/sh`).

##### Up-and-comers
Per-path size budgets (a different limit per glob) — not observed in any
surveyed repository; noted only as a possible extension of the attribute
(`large-file-ok=5MiB`), not recommended.

##### Fit for this template
Seven of seven template-shaped Rust repositories have zero blobs over 512000
bytes, so either value is quiet today. Under blob scope, only 1048576 stays
quiet as `Cargo.lock` and `CHANGELOG.md` grow (503,922 and 449,255 bytes
observed). R81 settles one `docs/` corpus built by mdBook and names no asset
directory in its Decision, and py's `docs/assets/` holds 0 files, so a
directory exemption has no natural home (MEDIUM question).

##### Recommendation
`> 1048576` bytes over every blob a change introduces; exemptions only via
`.gitattributes` `large-file-ok`, none shipped; LFS for intentional binaries.

##### Ranked runner-up
512000 bytes on **added** files only (E1's contract). It catches a minimal
`clap` release binary (921,344 bytes) that 1 MiB misses, and it is the
ecosystem default. It loses because it cannot see a file replaced in place or
a blob deleted before merge, which are the cases the principle is about.

##### Tradeoffs
1 MiB misses small release binaries (0.43–0.92 MB measured) that someone
copied out of `target/`; 512000 would catch them but would flag lockfile and
changelog growth at blob scope. An attribute exemption is reviewable and
per-path, but it is a git feature that fewer contributors know than a
directory convention. The error message names it.

##### Parameters
Owns no registered parameter. Values this member fixes: threshold
`1048576` bytes, comparison `>`; attribute name `large-file-ok`; no default
exempt path. Assumes the fixed parameters under `### Parameters`.

##### Migration implications
Adds `scripts/check-large-files.sh`; adds a commented `large-file-ok` example
line to `.gitattributes` (no active entry). Nothing to migrate: the template
has no committed files yet.

##### Validation strategy
`H2`/`H3` pin the boundary at both shells, `H6` the exemption and `H8` the
LFS path (all executed, `run-check.sh`). Proposed: the same cases on
`ubuntu-latest`.

##### Confidence & re-verify trigger
Medium-high on scope and value; the size profile is a 14-repository sample.
Re-verify if the template's own `Cargo.lock` or `CHANGELOG.md` passes 700,000
bytes, if R81 introduces an asset directory, or if GitHub makes push rulesets
available to public repositories.

##### Sources
py `lefthook.yml:137`, `.github/workflows/large-file-guard.yml:33-34`; ts
`lefthook.yml:42`; `pre-commit/pre-commit-hooks@44d7f9b7` `check_added_large_files.py:49-50,68`;
`j178/prek@5ba6dc58` `check_added_large_files.rs:22,65-66`; `sizes.log`
(git trees API, 2026-09-26); `github/docs@18945a31` `data/variables/large_files.yml`;
R81 `DECISION.md` (`## Decision`).

#### Hook-tier staged-blob check (F172)

##### Landscape
Built-in: a plain `.git/hooks/pre-commit` script. Established:
pre-commit-hooks `check-added-large-files` (E1, Python runtime required);
hand-rolled shell in `lefthook.yml` (E2, py and ts). Up-and-comer: prek's
native `check-added-large-files` (U1, no Python). Which manager runs the hook
is R37's decision, not this member's.

##### Principles and implementation
Fast local feedback before the blob exists in any commit. Implemented as one
hook-manager entry that runs `scripts/check-large-files.sh --staged` at
**pre-commit**; the script sizes staged blobs, so partial staging (`H7a`,
`H7b`) and LFS pointers (`H8`) are judged by what will actually be committed.
Example for lefthook, if R37 keeps it (**executed** in `L1`):

```yaml
pre-commit:
  jobs:
    - name: large-files
      run: scripts/check-large-files.sh --staged
```

##### Dominant choice
pre-commit-hooks `check-added-large-files` (6,691 stars; the one hook-tier
guard found in the 26-repository survey uses it).

##### Qualified shortlist
1. **Script call from the hook manager** (recommended) — the only option
   that shares the CI tier's rule and blob scope.
2. **prek builtin `check-added-large-files`** — viable only if R37 selects
   prek. Crate figures, per the prompt's table: 90-day downloads **9,768**,
   all-time **25,772** (`GET https://crates.io/api/v1/crates/prek`,
   `recent_downloads`, `downloads`); last release **0.5.3** at
   2026-09-13T08:39:55Z, `rust_version` **1.96**, licence `MIT`
   (`/versions`, newest non-yanked); **8,471** stars, not archived, pushed
   2026-09-24 (`GET https://api.github.com/repos/j178/prek`); **19** open
   issues (`search/issues?q=repo:j178/prek+is:issue+is:open`, `total_count`);
   responsiveness over the 10 newest issues (#2701–#2755): 5 answered by the
   owner, median first response **0.389 days** (0.042, 0.291, 0.389, 0.961,
   1.674), 5 with no maintainer comment, one of them the owner's own (#2730);
   advisories: `https://rustsec.org/packages/prek.html` returns **404**, i.e.
   no advisory page; adopter: `j178/prek` itself dogfoods `prek.toml`.
   Maintenance state **active**. Its `rust_version` 1.96 is exactly stable
   minus 2 against this host's 1.98.1, but prek is a developer tool installed
   as a binary, so it never enters the template's dependency tree.
3. pre-commit-hooks via the pre-commit framework — imposes a Python runtime,
   which D-020(1) rejected for ts for the same reason.

##### Excluded by gate
None by a numbered gate. For the recommended script, gates 2, 3, 5 and 6
are **inapplicable** (no crate); gate 1 passes (template code); gate 4 was
executed on macOS under bash 3.2 and dash and is proposed for Ubuntu.

##### Up-and-comers
prek (U1): Rust-native, fast, compatible with `.pre-commit-config.yaml`. Its
arithmetic differs from pre-commit's at the boundary: **computed** from both
sources, a file of 512001–513023 bytes is rejected by pre-commit-hooks
(`ceil`) and accepted by prek (floor division), which is concrete evidence
that "the same hook with the same default" still drifts unless the rule is
byte-exact and single-sourced.

##### Fit for this template
The script is dependency-free and hook-manager-neutral, so R37 can pick any
manager without reopening R14. Both E1 and U1 check *added* files only and
stat the working tree, so neither matches the CI tier's blob scope.

##### Recommendation
Keep the hook tier: a pre-commit entry calling
`scripts/check-large-files.sh --staged`, threshold and exemption from the
shared rule.

##### Ranked runner-up
prek's builtin with `args: ["--maxkb=1024", "--enforce-all"]`, if R37 picks
prek and prefers a declarative entry. It loses on three counts: floor
rounding (at `--maxkb=1024` it accepts up to 1,049,599 bytes), working-tree
sizing, and an exemption expressed as the hook's `exclude:` regex rather than
the attribute the CI tier reads.

##### Tradeoffs
The hook is bypassable (`--no-verify`, `L2`) and absent in clones where hooks
were never installed; that is why the CI tier exists. A hook written in a
script file is one more file than an inline block, but it is the price of one
definition.

##### Parameters
None owned. Assumes the hook manager is R37's; this entry needs only "run a
command at pre-commit".

##### Migration implications
One entry in the hook manager's config file (R37's file); no other change.

##### Validation strategy
Executed: `H1`–`H10` under `/bin/sh` and `/bin/dash`; `L1` through
`lefthook` 2.1.14. Proposed: repeat `L1` with R37's chosen manager.

##### Confidence & re-verify trigger
High on the mechanism (executed). Re-verify when R37 decides the hook
manager, or if prek fixes its rounding to match pre-commit's.

##### Sources
py `lefthook.yml:132-148`; ts `lefthook.yml:34-48`; ts
`docs/port/TS_PORT_DECISIONS.md:240` (D-020(6)); py `fe96899^:.pre-commit-config.yaml:40`;
py `docs/adr/0018-hook-ci-parity-and-boundary-gate.md:88-90`;
`pre-commit/pre-commit-hooks@44d7f9b7` `util.py:12`, README 26-33;
`j178/prek@5ba6dc58` `builtin_hooks/mod.rs:42,159-167`; crates.io and
api.github.com figures above (2026-09-26); `run-check.log`.

#### CI-tier range check (F043)

##### Landscape
Built-in: a `run:` step using git primitives (B5); GitHub's 100 MiB block
(B2); push rulesets (B3, private and internal only). Established: py's
dedicated `large-file-guard.yml` (E3). Up-and-comer: `ppremk/lfs-warning`
(U2).

##### Principles and implementation
A backstop that no contributor can skip, over every commit that will land.
Implemented as a step of R11's `hygiene` job (**executed** through
`actionlint`):

```yaml
      - uses: actions/checkout@v7
        with:
          # R14: the large-file guard walks every commit in the range.
          fetch-depth: 0
          persist-credentials: false
      - name: Large-file guard (R14)
        env:
          BASE_SHA: ${{ github.event.pull_request.base.sha || github.event.merge_group.base_sha || github.event.before }}
        run: scripts/check-large-files.sh --range "${BASE_SHA}" HEAD
```

##### Dominant choice
Across the survey, none: 0 of 26 repositories has a workflow file named for
a committed-file size check (a name-only search). Among the template
precedents, py's dedicated workflow (E3) is the only one.

##### Qualified shortlist
1. **`hygiene` step running the shared script in range mode** (recommended).
2. py's dedicated workflow body — rejected on four executed defects (`R1py`,
   `R3py`, `R4py`, `R5py`) and on R11's placement rule.
3. Push ruleset "Restrict file size" — not available to this public
   repository (`repo-rules.md`); an optional extra layer for private adopters.

##### Excluded by gate
None by a numbered gate. `ppremk/lfs-warning` (U2) passes gate 1 (MIT) but is
not shortlisted, for three reasons outside the gates: it needs
`issues`/`pull-requests` write scope to label and comment (`src/index.ts:98`,
`:102`, `:163`), against R11's `permissions: {}` baseline with per-job
`contents: read`; it runs on `node20`; and its maintenance signals are weak
(39 stars, last release `v3.3` on 2024-04-04, 4 open issues). Its default
`10mb` also checks only the pull request's file list, not history.

##### Up-and-comers
U2 as above; merge-queue-aware checking through the `merge_group` event, which
this step supports through `merge_group.base_sha`.

##### Fit for this template
It compiles nothing, so R11's rule puts it in `hygiene`, which runs on every
event with no `needs:` edge; its only cost is the full-depth checkout. The
merge-commit policy of the owner's organisation makes the range walk
necessary rather than optional (`R1`, `R1m`).

##### Recommendation
Keep the CI tier as a `hygiene` step calling
`scripts/check-large-files.sh --range "${BASE_SHA}" HEAD`, with
`fetch-depth: 0` on `hygiene`'s checkout.

##### Ranked runner-up
A tree-at-HEAD check (`git ls-tree -r -l HEAD`) in `hygiene` with no history.
It needs no deeper checkout and no base SHA, but it misses the blob added and
deleted inside a pull request, which merge commits keep.

##### Tradeoffs
Full-depth checkout in `hygiene` costs clone time, which grows with the
repository's age. A step inside `ci.yml` reports under the `hygiene` check
rather than under its own named check, so branch protection cannot require it
separately. A contributor can edit the script in the same pull request;
review sees it.

##### Parameters
None owned. Placement follows R11's `ci-job-structure`; the step adds
`fetch-depth: 0` to `hygiene`'s checkout (slot note, not a `CONFLICT:`).

##### Migration implications
Two edits to `.github/workflows/ci.yml` (the checkout option and the step).
No `.github/workflows/large-file-guard.yml` is created.

##### Validation strategy
Executed: `R1`–`R7` and `L3` against the script; `actionlint` 1.7.12 exit 0
on R11's fixture plus the step. Proposed: a pull request on the implemented
template that adds and then deletes a 2 MiB blob must fail `hygiene`; a
`merge_group` run and a `push` to `main` must pass on a clean change.

##### Confidence & re-verify trigger
Medium-high: mechanism executed locally, never on a GitHub-hosted runner.
Re-verify when R11's `hygiene` job changes, when R12 decides the required
checks, or if GitHub opens push rulesets to public repositories.

##### Sources
py `.github/workflows/large-file-guard.yml:1-62`; py
`docs/source/about/design_decisions.md:445-450`; R11 `DECISION.md` (sha256
`410e88e5…`) and `ci.candidate.r2.yml:54-57,119-142`;
`github/docs@18945a31` `repo-rules.md`, `available-rules-for-rulesets.md`
"Restrict file size", `merge_group.child-params.json`; `ppremk/lfs-warning`
`action.yml`, `src/index.ts`; `run-check.log`.

### Compatibility
The members are one script used twice, so "tested together" means both modes
on one fixture. Executed on this host: `L1` (hook mode under `lefthook`
2.1.14 rejects the commit), `L2` (`--no-verify` bypasses it) and `L3` (range
mode over the same repository catches the bypassed commit). The same rule and
exemption (`H6`) serve both. The CI half is validated as workflow YAML inside
R11's fixture (`actionlint` exit 0). No GitHub-hosted runner has run either
half, and no third-party adopter of the combination exists (see the gap under
`### Principles and implementation`).

### Parameters
- assumes `rust-edition` = `2024`
- assumes `msrv-policy` = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- assumes `license` = `MIT OR Apache-2.0`
- assumes `target-os-matrix` = `ubuntu-latest, macos-latest`
- R14 owns no registered parameter and consumes none (`- owns:` and
  `- consumes:` are empty in the prompt). It places its CI step according to
  R11's `ci-job-structure` and needs one addition to `hygiene`'s checkout
  (`fetch-depth: 0`), recorded as a slot note, not a `CONFLICT:`.
- No `CONFLICT:` lines.

### Migration implications
Proposed file-level changes to `rs-launch-blueprint` (P03 builds them; none
exist yet):

| File | Change |
|---|---|
| `scripts/check-large-files.sh` | new, the 46-line reference above, executable bit set |
| `.gitattributes` | a comment explaining `large-file-ok` and LFS routing; no active exemption |
| hook manager config (R37's file, e.g. `lefthook.yml`) | one pre-commit entry: `scripts/check-large-files.sh --staged` |
| `.github/workflows/ci.yml` | `hygiene`: `fetch-depth: 0` on `actions/checkout`, plus the "Large-file guard (R14)" step |
| `CONTRIBUTING.md` / docs | one paragraph: the 1 MiB rule, LFS, and how to declare `large-file-ok` |
| `.github/workflows/large-file-guard.yml` | **not created** (py's dedicated file is replaced by the `hygiene` step) |

Follow-on for the source repositories, with the rationale above: py keeps
1 MiB, fixes `large-file-guard.yml:38-46` (fail-open base, added-only,
final-tree, word splitting) and drops the empty `docs/assets/` prefix; ts adds
a CI tier and moves its hook to blob scope at 1 MiB.

### Validation strategy
**Executed** — the full transcript of `run-check.sh` (sha256 `85963ff3…`),
run with `GIT_CONFIG_GLOBAL=/dev/null` so no user configuration applied:

```text
host: macOS 26.4 arm64; git version 2.50.1 (Apple Git-155); lefthook 2.1.14; git-lfs/3.8.0; sh=GNU bash, version 3.2.57(1)-release (arm; dash=/bin/dash
guard sha256: 1ba847e3eaa187aa7dee161fb7154bf2a0e75fb5dafc99f94ec32db917241f30
== hook tier (--staged) under /bin/sh
H1   PASS  expected=0 got=0  nothing staged
H2   PASS  expected=0 got=0  1048576 bytes = threshold passes
H3   PASS  expected=1 got=1  1048577 bytes fails
H4   PASS  expected=1 got=1  spaced name fails; msg: FAIL: big file.bin is 2097152 bytes (> 10485
H5   PASS  expected=1 got=1  modified file grown to 2 MiB fails
H6   PASS  expected=0 got=0  exempt by attribute; msg: ALLOW: media/demo.gif is 2097152 bytes (large-file-ok)
H7a  PASS  expected=0 got=0  staged 10 B, worktree 2 MiB: blob checked, passes
H7b  PASS  expected=1 got=1  staged 2 MiB, worktree 10 B: blob checked, fails
H8   PASS  expected=0 got=0  LFS-tracked 2 MiB file stages a 132-byte pointer
H9   PASS  expected=0 got=0  gitlink entry skipped without error
H10  PASS  expected=1 got=1  unborn branch, first commit 2 MiB fails
== hook tier (--staged) under /bin/dash
H1   PASS  expected=0 got=0  nothing staged
H2   PASS  expected=0 got=0  1048576 bytes = threshold passes
H3   PASS  expected=1 got=1  1048577 bytes fails
H4   PASS  expected=1 got=1  spaced name fails; msg: FAIL: big file.bin is 2097152 bytes (> 10485
H5   PASS  expected=1 got=1  modified file grown to 2 MiB fails
H6   PASS  expected=0 got=0  exempt by attribute; msg: ALLOW: media/demo.gif is 2097152 bytes (large-file-ok)
H7a  PASS  expected=0 got=0  staged 10 B, worktree 2 MiB: blob checked, passes
H7b  PASS  expected=1 got=1  staged 2 MiB, worktree 10 B: blob checked, fails
H8   PASS  expected=0 got=0  LFS-tracked 2 MiB file stages a 132-byte pointer
H9   PASS  expected=0 got=0  gitlink entry skipped without error
H10  PASS  expected=1 got=1  unborn branch, first commit 2 MiB fails
== CI tier (--range) vs py large-file-guard.yml body (THRESHOLD 1048576, ALLOWLIST docs/assets/)
R1   PASS  expected=1 got=1  blob added then deleted inside the range fails (history bloat)
R1py PASS  expected=0 got=0  py body passes the same range (final-tree only)
R1m  PASS  expected=0 1 0 got=0 1 0  merge --no-ff of the PR: blob unreachable before, reachable from main after, absent from main's tree
R3   PASS  expected=1 got=1  all-zero base checks all history (fails closed)
R3py PASS  expected=0 got=0  py body skips on all-zero base (fails open)
R3e  PASS  expected=1 got=1  empty base checks all history
R4   PASS  expected=1 got=1  modified file grown past threshold fails
R4py PASS  expected=0 got=0  py body passes it (--diff-filter=A)
R5   PASS  expected=1 got=1  spaced filename fails
R5py PASS  expected=0 got=0  py body word-splits the name and passes
R6   PASS  expected=0 got=0  unchanged large blob already in base is not re-reported
R7   PASS  expected=2 got=2  unknown base sha is an error (fails closed)
== lefthook 2.1.14 integration
L1   PASS  expected=1 got=1  hook rejects the commit (HEAD unchanged: yes)
L2   PASS  expected=1 got=1  --no-verify commits it anyway
L3   PASS  expected=1 got=1  CI-tier range check catches the bypassed commit
L4   PASS  expected=1 got=1  py hook body under lefthook, spaced 2 MiB name
L5   PASS  expected=1 got=1  ts hook body under lefthook, spaced 600000-byte name
L6   PASS  expected=1 got=1  ts hook body also rejects a MODIFIED file (all staged files)
== wc -c padding (ts computes size without tr)
wc output: [  600000]
W-sh PASS  expected=0 got=0  padded size compares numerically under /bin/sh
W-dash PASS  expected=0 got=0  padded size compares numerically under /bin/dash
== boundary arithmetic read from source (pre-commit-hooks ceil vs prek floor), maxkb=500
  512000 bytes: pre-commit rejects=0 prek rejects=0 ts(-gt 512000) rejects=0
  512001 bytes: pre-commit rejects=1 prek rejects=0 ts(-gt 512000) rejects=1
  512500 bytes: pre-commit rejects=1 prek rejects=0 ts(-gt 512000) rejects=1
  513023 bytes: pre-commit rejects=1 prek rejects=0 ts(-gt 512000) rejects=1
  513024 bytes: pre-commit rejects=1 prek rejects=1 ts(-gt 512000) rejects=1
FAILS=0 of 42
```

How to read it: each line is one fixture repository built from scratch; a
`py` suffix runs py's pinned CI body on the same fixture, and its expected
value records py's *current* behaviour (a pass where the principle wants a
failure), so a `PASS` on an `…py` line confirms a defect rather than approving
it. The `R1m` line makes the add and delete on a branch, merges it into `main`
with `--no-ff`, and asserts three values: the blob was unreachable from
pre-merge `main` (0), is reachable from `main`'s HEAD after the merge (1), and
is absent from `main`'s tree (0). The final block is arithmetic over the two
hook sources, not an execution of pre-commit or prek (neither ran here;
`prek` is installed only as an unconfigured `mise` shim).

**Also executed:** `shellcheck -s sh check-large-files.sh` → no findings;
`actionlint` 1.7.12 on R11's fixture plus the step → exit 0; the binary-size
builds and the size and practice surveys cited under `### Landscape`.

**Planned (not run), for P03 on the implemented template:**

```sh
# ubuntu-latest and macos-latest, repository root
sh scripts/check-large-files.sh --staged            # expect exit 0 on a clean index
head -c 1048577 /dev/zero > big.bin && git add big.bin
sh scripts/check-large-files.sh --staged            # expect exit 1, "FAIL: big.bin is 1048577 bytes"
git reset -q big.bin && rm big.bin
sh scripts/check-large-files.sh --range "$(git rev-parse HEAD~1)" HEAD   # expect exit 0
```

and one pull request that adds then deletes a 2 MiB blob, whose `hygiene`
job must fail at the "Large-file guard (R14)" step.

### Confidence & re-verify trigger
**Confidence: medium-high.** High for the mechanism and for the defects in
the source implementations (all executed). Medium for the threshold value:
it rests on a 14-repository size sample and three local binary builds on one
OS. Low for prevalence claims about CI-tier guards, because that search read
workflow file names only. **Not verified:** any GitHub-hosted runner; Linux
binary sizes; prek and pre-commit executions (read and computed only).
**re-verify:** when R37 selects the hook manager; when R11's `hygiene` job or
R12's required-check set changes; when the template's `Cargo.lock` or
`CHANGELOG.md` passes 700,000 bytes; if GitHub makes push rulesets available
to public repositories; otherwise at P03's first CI run.

### Sources
All retrieved 2026-09-26 (UTC).

Pinned template sources (local clones, `git show`):
- py `b08bccfb55d05f15e46a83b52c5660b1881d19f5`: `.github/workflows/large-file-guard.yml:1-62`; `lefthook.yml:1-16,132-148`; `docs/adr/0018-hook-ci-parity-and-boundary-gate.md:1-30,88-90,124-127`; `docs/source/about/design_decisions.md:445-450`; `git ls-tree -r -l` (0 entries under `docs/assets/`; `uv.lock` 445,494 bytes). History: `fe96899` (2026-05-24) and `fe96899^:.pre-commit-config.yaml:40`; `7ac7716` (2026-05-24); `6a2f710` (2026-06-14).
- ts `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`: `lefthook.yml:1-48`; `docs/port/TS_PORT_DECISIONS.md:231-247` (D-020); `git ls-tree -r -l` (`pnpm-lock.yaml` 133,991 bytes).

Programme files: `docs/port/COMMONALITY.md:49,176`; `docs/port/DIVERGENCE-ANALYSIS.md:96-98,252`; `docs/port/PARAMETERS.md:12` (`ci-job-structure`); `research/topics/11-ci-workflow-job-structure/DECISION.md` (sha256 `410e88e5…`); `research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/evidence/ci.candidate.r2.yml` (sha256 `4eb498c2…`); `research/topics/81-docs-delivery-model/DECISION.md` (`## Decision`); `research/RUNBOOK.md` §5.

GitHub documentation (`github/docs` at `18945a31a4f2d97beb6c5c1a7479102e23c25727`, via `https://api.github.com/repos/github/docs/contents/...`):
- `content/repositories/working-with-files/managing-large-files/about-large-files-on-github.md:28-41,49-51`
- `data/variables/large_files.yml` (`warning_size`, `max_github_size`, `max_github_browser_size`)
- `content/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets.md` ("Restrict file size")
- `data/reusables/gated-features/repo-rules.md`; `data/reusables/repositories/push-rulesets-overview.md`; `data/reusables/repositories/rulesets-push-rulesets-fork-network-information.md`
- `src/webhooks/data/fpt/merge_group.child-params.json` (`base_sha`)
- `https://api.github.com/repos/smorinlabs/rs-launch-blueprint` (`"visibility":"public"`)

Tools and candidates:
- `https://github.com/pre-commit/pre-commit-hooks/blob/44d7f9b7e32225d2bd590282037e4650064f3950/pre_commit_hooks/check_added_large_files.py`; `.../pre_commit_hooks/util.py`; `.../README.md`; `https://api.github.com/repos/pre-commit/pre-commit-hooks` (6,691 stars, `archived: false`); `/releases/latest` (`v6.0.0`, 2025-08-09).
- `https://github.com/j178/prek/blob/5ba6dc58a6285c551620354f139bbd8b5fa60e23/crates/prek/src/hooks/pre_commit_hooks/check_added_large_files.rs`; `.../crates/prek/src/hooks/builtin_hooks/mod.rs`; `https://api.github.com/repos/j178/prek`; `https://crates.io/api/v1/crates/prek`; `https://crates.io/api/v1/crates/prek/versions`; `https://api.github.com/search/issues?q=repo:j178/prek+is:issue+is:open`; issues #2701–#2755 and their comments; `https://rustsec.org/packages/prek.html` (HTTP 404).
- `https://github.com/ppremk/lfs-warning` (`action.yml`, `src/index.ts`; API redirect from `ActionsDesk/lfs-warning`); `/releases/latest` (`v3.3`, 2024-04-04); `search/issues` open count 4.
- `https://github.com/rust-lang/rust/blob/0b80633005f5/src/tools/tidy/src/bins.rs`; `.../style.rs`.
- Practice survey (26 repositories) and size profile (14 repositories) at the commits listed in `### Landscape`, via `https://api.github.com/repos/<o>/<r>`, `/commits/<branch>`, `/contents`, `/git/trees/<sha>?recursive=1`.
- `https://github.com/pydantic/pydantic-core/blob/383eb95a1943/.pre-commit-config.yaml` (line 11).

Local executions: `run-check.sh` / `run-check.log`, `survey.sh` / `survey.log`, `sizes.sh` / `sizes.log`, `cargo build` of three scratch crates (`hello`, `cli` with `clap` 4.6.7, `web` with `axum` 0.8.9 and `tokio` 1.53.1), `shellcheck`, `actionlint` 1.7.12 — hashes in the header table.
