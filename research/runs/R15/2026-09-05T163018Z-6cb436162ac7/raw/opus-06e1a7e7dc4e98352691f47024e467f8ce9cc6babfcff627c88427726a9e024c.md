# R15 — Template drift/receipt guard (pattern)

Engine: opus (`claude-opus-5[1m]`). All figures retrieved 2026-09-09 (UTC) unless a
row states otherwise. Empirical results marked **executed** were run by this engine
on macOS 15 (darwin arm64) against a synthetic Rust target built for the purpose;
everything else is marked **planned**.

### Landscape

**The category this item decides.** Not "how do we template a Rust project". Two
narrower capabilities, over a repository that is *already* a working project:

1. **Rebrand-verification** — a mechanical, per-PR proof that the repository can
   still have a new identity pressed onto it without any of the old identity
   surviving.
2. **Tool-byproduct rejection** — a guard that refuses to let the rebrand tool's
   per-run state file enter version control in the template.

The owner has fixed the mechanism for (1) and (2): `template-press`, the same tool
py-launch-blueprint uses ("You should be using template-press just the way PyLaunch
Blueprint does, and the same thing for TypeScript. We should all be using the same
mechanism." — `docs/port/OWNER-REVIEW.md:57`, 2026-09-04). The research question
that remains is what a *Rust* target must provide for that mechanism to work, and
what the Rust ecosystem's own regenerate-and-verify practice adds.

**Three-bin map of the Rust field.**

| Bin | Candidates found | Note |
|---|---|---|
| Built-in / first-party toolchain | `cargo new` / `cargo init` (The Cargo Book, https://doc.rust-lang.org/cargo/commands/cargo-new.html, retrieved 2026-09-09, HTTP 200); `cargo metadata` (machine-readable manifest introspection); GitHub *template repositories* (first-party to the forge, https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository, retrieved 2026-09-09, HTTP 200) | Cargo has **no** project-templating or template-verification feature. `cargo new` writes a fixed skeleton; there is no placeholder language and nothing to verify. GitHub template repositories copy a tree with **no substitution at all**, so the renaming is manual and unverifiable by construction. |
| Established industry standard | `cargo-generate` (https://github.com/cargo-generate/cargo-generate; 2,484 stars, `archived: false`, `pushed_at` 2026-09-07T20:02:34Z, `GET https://api.github.com/repos/cargo-generate/cargo-generate`; 26 open issues via `GET https://api.github.com/search/issues?q=repo:cargo-generate/cargo-generate+is:issue+is:open`; 90-day downloads 295,439 and all-time 2,382,113 via `GET https://crates.io/api/v1/crates/cargo-generate`, `crate.recent_downloads` / `crate.downloads`; newest non-yanked version 0.24.0 released 2026-08-31T21:59:00Z via `/versions`), with its companion `cargo-generate/cargo-generate-action` (7 stars, `pushed_at` 2024-08-04T09:00:22Z) | The de-facto Rust scaffolder. Placeholder-based (`{{project-name}}`, Liquid), so the *template repo itself is not a working project* — the inverse of the model this item needs. |
| Established (cross-ecosystem, cited as prior art only) | cookiecutter / copier / cruft — the "answers file committed into the generated project" family | Relevant because it is the exact **opposite** convention to the press receipt: those tools *require* the answers file to be committed so the project can be re-updated. |
| Up-and-comer | `esp-rs/esp-generate` (297 stars, `pushed_at` 2026-09-08T11:46:17Z); `iomentum/cargo-scaffold` (69 stars, `pushed_at` 2026-02-09T14:16:16Z; 90-day downloads 8,932; 0.15.0 released 2026-02-09); `Keats/kickstart` (476 stars, `pushed_at` 2025-12-21T22:50:42Z; 90-day downloads 143; 0.6.0 released 2025-12-21) | `esp-generate` is a purpose-built generator that *replaced* the archived `esp-rs/esp-template` (`archived: true`, `pushed_at` 2025-04-25) — evidence that the maintained end of this field is moving from "template repo + cargo-generate" toward "a bespoke generator binary". |
| Owner-fixed mechanism (not a bin candidate — it is the decision's input) | `template-press` 4.0.1, PyPI, released 2026-08-18T15:37:46Z (`GET https://pypi.org/pypi/template-press/json`); repo `smorinlabs/template-press` (0 stars, `archived: false`, `pushed_at` 2026-09-09T03:46:57Z, MIT) | A *rebrand-in-place* tool for external targets, not a generator: "It is **not** a project template you fork; it is a tool you run against other repos, one at a time." (PyPI description, retrieved 2026-09-09). |

Download counts appear above as landscape context only; per the prompt they carry no
weight in the choice and no download column appears in `### Options`.

**Authoritative sources used, and why each is authoritative.**

- **The Cargo Book** (`doc.rust-lang.org/cargo`) — the Rust project's own first-party
  documentation for the build tool; authoritative on what Cargo does and does not
  provide. Used to establish that templating/verification is *not* a Cargo feature.
- **rust-lang/cargo issue #9922**, "cargo runs in a wrong folder (in a parent
  directory where it should not run)", opened 2021-09-19, state `closed`
  (`GET https://api.github.com/repos/rust-lang/cargo/issues/9922`, retrieved
  2026-09-09) — the Cargo project's own defect record. Authoritative for the
  Rust-specific hazard that a generated/pressed copy left *inside* the template's
  directory tree is picked up by the parent manifest. `rust-github/template` cites
  this issue by URL in its CI as the reason it moves the generated project out.
- **`template-press` design records 0006 (external-target model, "Accepted
  2026-06-23") and 0007 (`press verify` design & decision record)** plus the shipped
  source (`discovery.py`, `verify_cli.py`, `verify_config.py`, `rules.py`) — the
  maintainer's own design record for the mechanism the owner fixed. A design doc plus
  the code that implements it is the highest authority available for a tool with one
  maintainer; I read the code rather than trusting the prose, and the empirical runs
  below check both.
- **Maintainer documentation of the de-facto standard**: the cargo-generate book
  (https://cargo-generate.github.io/cargo-generate/, retrieved 2026-09-09, HTTP 200)
  and the cargo-generate repository's own workflows.
- **GitHub's product documentation** on template repositories — first-party to the
  forge that hosts all three repos.
- **Evidence gap, stated rather than papered over**: the annual Rust survey does not
  report project-templating tool usage, and there is no RFC or working-group output
  on template self-verification. There is therefore *no* Rust-project-level authority
  on this pattern; authority here rests on first-party tool docs plus practice.

**Practice evidence — well-regarded Rust projects that run a regenerate-and-verify
check, with the evidence that they are well regarded.**

- **`cargo-generate` itself**, `.github/workflows/e2e-test.yml` (retrieved
  2026-09-09 from `raw.githubusercontent.com/cargo-generate/cargo-generate/main/`):
  a weekly cron job (`cron: '0 18 * * 5'`) that, on `macos-latest`, `ubuntu-latest`
  and `windows-latest`, runs `cargo install -f cargo-generate`, then
  `cargo generate rustwasm/wasm-pack-template --name demo`, then `cd demo &&
  cargo build`. Well-regarded evidence: it is the tool with 2,382,113 all-time
  crates.io downloads and 2,484 stars, actively pushed 2026-09-07, that the rest of
  this bin depends on.
- **`rust-github/template`**, `.github/workflows/build.yml` (retrieved 2026-09-09):
  `cargo-generate/cargo-generate-action@v0.20.0` generates the project with
  `--template-values-file .github/workflows/template_values.toml`, then
  `mv $PROJECT_NAME ${{ runner.temp }}/ && cd ${{ runner.temp }}/$PROJECT_NAME &&
  cargo check --tests`, with an in-file comment citing
  `https://github.com/rust-lang/cargo/issues/9922` as the reason for the move.
  Well-regarded evidence: 237 stars, `archived: false`, pushed 2026-07-02, only 3
  open issues; it is the template published by the `rust-github` organisation whose
  stated purpose is exactly this artifact.
- **`esp-rs/esp-template` → `esp-rs/esp-generate`**: the cargo-generate template is
  now `archived: true`; the successor generator is pushed 2026-09-08 with 297 stars.
  Well-regarded evidence: `esp-rs` is Espressif's official Rust organisation.

The pattern that survives contact with practice is narrow and consistent: **generate
the artifact in CI, move it away from the template's own tree, and prove it still
builds.** No project in this survey verifies a *rebrand* (identity rewrite of a real
repository) — that is what makes `template-press` an outlier rather than a
reimplementation of ecosystem practice, and it is why the verification it performs is
a different check from the ecosystem's (see the correction in the next field).

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

- **Source**: owner direction of 2026-09-04, recorded verbatim at
  `docs/port/OWNER-REVIEW.md:57` and repeated in this prompt's `## Context`.
- **Agreement level**: *capability + policy*, plus one architectural commitment
  (a single shared rebrand engine). Specifically:
  - **P1 (capability, must agree)** — every repo in the family is a
    `template-press` target: it commits `press/press-source.toml`, may commit
    `press/press-rules.toml`, and proves on every PR that a hermetic self-press
    leaves no source identity behind.
  - **P2 (policy, must agree)** — the press receipt
    (`press/press-receipt.toml`) is never committed *to the template*, because a
    committed receipt in the template would be copied into every fork and disarm
    that fork's own guard. The guard enforcing this is template-only and is deleted
    by the press in a fork (`press/press-rules.toml:118-120` in py: `[[remove]]
    file = ".github/workflows/template-receipt-guard.yml"`, reason "template-only
    receipt guard; a fork legitimately commits its receipt").
  - **P3 (architecture, must agree)** — the two responsibilities live in **two
    separate workflow files**, not one. This is forced by the mechanism, not by
    taste: `press-verify.yml` ships to generated forks and therefore must contain no
    identity literal, while `template-receipt-guard.yml` is identity-scoped to the
    template and is `[[remove]]`d in forks. py states this reason in the file itself
    (`.github/workflows/template-receipt-guard.yml:1-5`, retrieved 2026-09-09).
  - **May vary per ecosystem**: how the `press` executable is provisioned in CI;
    the `[[regenerate]]` / `[[reset]]` / `[[remove]]` entries in
    `press/press-rules.toml`; which files need `verify_exempt`; the compensating
    identity cross-check that substitutes for the tool's Python-only discovery.

**A correction to this prompt's description of the mechanism, on the record.**
The prompt's `## Objective` calls `press-verify.yml` "a hermetic self-press check
that verifies the template can re-generate itself" and its value test speaks of the
template "regenerating itself correctly". `press verify` does **not** build, test, or
otherwise execute the pressed copy. Its contract is narrower and its own header says
so: "`press verify` hermetically self-presses a sandbox copy and scans for surviving
identity: any added identity-bearing file that presses dirty fails this check (exit
1); config errors exit 2" (py `.github/workflows/press-verify.yml:2-4`). Design 0007
§1 states the same ("a zero-arg, hermetic, read-only CLI verb that proves a template
presses clean") and decision **D5** makes the exclusion deliberate: "Let verify also
run `uv lock` in the sandbox — rejected: breaks hermeticity, adds network dependency
and nondeterminism to a check meant to be fast and offline." So `press verify` is an
*identity-leak scan*, and the ecosystem's "does the generated project still build"
check (cargo-generate's `e2e-test.yml`, rust-github/template's `build.yml`) is a
**different, complementary** check that py does not run either. This matters for the
recommendation: adopting py's mechanism exactly gives rs the leak scan, and the
build-the-pressed-copy lane is a separate decision, taken below as the runner-up.
This is a correction of the prompt's paraphrase; the ledger row F044 and the area row
`docs/port/areas/ci-workflows.md:43` say "hermetic self-press check", which is
accurate, so **no `BASELINE-REVIEW:` finding is emitted for this item.**

**Architectural alternatives, compared before any library choice.**

| Alternative | How the template exists | What CI can prove | Why it wins or loses here |
|---|---|---|---|
| **A. Rebrand-in-place (`template-press`)** | The template is a *real, working, buildable repository* with a real identity. The press rewrites that identity in a copy. | That no old identity survives a press — occurrence-pinned, with file/line/column. Proven hermetically and offline. | **Chosen.** It is the owner-fixed mechanism, and it is the only model under which the template is simultaneously a working project and a rebrand source. Its verification is *stronger per-PR* than the ecosystem's because it is exhaustive over the identity token set rather than "one generated instance compiled". |
| **B. Generate-from-placeholders (`cargo-generate`)** | The template is a tree of `{{project-name}}` placeholders; it does not build as-is. | That one instantiation, with one set of values, compiles. | Loses on three counts: it is excluded by owner direction; the template stops being a working repo (so every other CI job in this template — clippy, tests, docs, coverage — would have nothing to run against); and it verifies one sample, not the absence of leaks. |
| **C. GitHub template repository + a `scripts/rename.sh`** | Real repo; renaming is a hand-rolled `sed` script. | Only what the script's own tests prove. | Loses: it is a private reimplementation of `template-press` with no leak scan, no receipt, no exit-code contract, and it breaks family agreement. |
| **D. No check (the ts status quo)** | Real repo; rebrandability asserted, never tested. | Nothing. | Loses by the item's own value test. |

**Does the shared architectural pattern remain appropriate in Rust?** Yes, and the
evidence is empirical rather than argued. `template-press` is language-agnostic by
construction: design 0006 states "the tool carries rewrite rules (boundary-safe by
default); it does not carry any target's identity or file list", the rules schema's
top-level tables are `{rules, replace, verify, regenerate, reset, remove, edit,
clean}` (`src/template_press/rebrand/rules.py:339`, retrieved 2026-09-09), and the
only tool `press` itself requires is `git`
(`src/template_press/rebrand/check_tools.py`: "``git`` — the only tool press itself
contributes after D1"). The six identity fields map onto Rust cleanly:

| `press` field | Rust surface | Validator constraint (`identity.py`, retrieved 2026-09-09) |
|---|---|---|
| `repo_name` | `Cargo.toml` `[package] name`, the GitHub repo name | lowercase alphanumeric + hyphens — matches Cargo's package-name convention |
| `package_name` | the lib target name / `use` path (`rs_launch_blueprint`) | must be a lowercase Python identifier — i.e. `snake_case`, which is exactly Cargo's default lib-target form (`name.replace('-', '_')`) |
| `app_name` | `[[bin]] name`, the installed binary | short-token; boundary-safe matching by default |
| `owner` | GitHub owner in `repository`/origin URL | 1–39 chars, alphanumeric + hyphens |
| `author`, `email` | `Cargo.toml` `authors` (optional in Cargo) | free-form; **not** in the default verify scan scope |

**The one real Rust-specific defect in the mechanism, quantified.** `press`'s safety
model is "config-first identity, discovery as a guard": the committed
`press/press-source.toml` is authoritative, and discovery cross-checks it and
"refuses to run on a mismatch" (PyPI description; design 0006 §1). That discovery is
**Python-only**. `src/template_press/rebrand/discovery.py:64-98` (retrieved
2026-09-09) reads `pyproject.toml` for `[project].name`, `[project.scripts]` keys and
`[project].authors`, and reads `git remote get-url origin` for owner/repo. On a Rust
target there is no `pyproject.toml`, so `package_name`, `app_name`, `author` and
`email` all come back `None`, and `mismatches()` skips them with the explicit comment
`# undiscoverable field — config stands unchallenged` (`discovery.py:114`). Only
`owner` and `repo_name` — the two fields derived from the git origin — are actually
cross-checked. **The cross-check that protects a Python target on 6 of 6 identity
fields protects a Rust target on 2 of 6.**

The fallback is weaker but real: `verify_cli._preflight` requires that any *scanned*
field discovery could not confirm must occur at least once in the target's text
corpus, else the run is classified `unverifiable` and exits 2
(`verify_cli.py:251-311`; design 0007 D2: "refusing to pass on historical prose").
The default scan scope is `("app_name", "package_name", "repo_name", "owner")`
(`verify_config.py:34`), so `author`/`email` are neither discovered nor presence-checked
on a Rust target — a typo in either is caught by nothing. Two consequences bind the
Rust template design:

1. The declared `package_name` (underscored) and `app_name` **must appear in tracked
   content** — satisfied naturally by `use rs_launch_blueprint::…` in integration
   tests and `[[bin]] name = "…"` in `Cargo.toml`, but it is now a *requirement*, not
   an accident. A template whose lib crate is never named in a `use` path would fail
   preflight with exit 2.
2. rs needs a **compensating control** that restores the discovery guard natively:
   a check that `press/press-source.toml` agrees with `cargo metadata`. This is the
   Rust-specific design difference that preserves the shared principle (P1's safety
   property) rather than diluting it.

**Executed empirical evidence.** I built a synthetic Rust target
(`Cargo.toml` with `[package] name = "rs-launch-blueprint"`, `[lib] name =
"rs_launch_blueprint"`, `[[bin]] name = "rslbp"`, `authors = ["Steve Morin
<steve.morin@gmail.com>"]`; `src/lib.rs`, `src/main.rs` and `tests/cli.rs` using
`use rs_launch_blueprint::run;`; `README.md`; `press/press-source.toml` with the six
fields; `press/press-rules.toml`), `git init`-ed it, set
`origin = https://github.com/smorinlabs/rs-launch-blueprint.git`, committed, and ran
`uvx --from 'template-press==4.0.1' press verify --target <dir>` on macOS
(darwin arm64), cargo 1.98.0. Results, all **executed** 2026-09-09:

| # | Target state | Observed output | Exit |
|---|---|---|---|
| A | Clean synthetic Rust target | `verified: no identity leftovers survived the hermetic self-press (clean over the scanned set).` | **0** |
| B | Added `pub const RSLBP_HOME` and `pub fn rslbp_config_path()` (glued `app_name` forms — py's G3 class) | same "verified" line | **0** — and run G below proves this is a *rewrite*, not a blind spot |
| C | Committed a binary blob (`GIF89a\x00…rs_launch_blueprint\x00…`) | same "verified" line | **0** — run G proves this too is a rewrite, not a blind spot |
| D | `docs/NOTES.md` containing "Generated by rs-launch-blueprint (rslbp)", declared in `[rules] extra_exclude_files` | `verify FAILED — source identity survived the hermetic self-press:` then `docs/NOTES.md` / `[content L3:C34] app_name='rslbp'` / `[content L3:C13] package_name='rs_launch_blueprint'` / `[content L3:C13] repo_name='rs-launch-blueprint'` | **1** |
| E | `press-source.toml` declaring a stale `package_name = "rs_launch_blueprint_core"` | `error: package_name: declared 'rs_launch_blueprint_core' is neither discoverable nor present anywhere in the target (undiscoverable and absent)` | **2** |
| F | `press-source.toml` declaring `owner = "wrongowner"` | `error: owner: source-config says 'wrongowner' but target shows 'smorinlabs'` | **2** |

An exit 0 from `press verify` means "no *source* identity survived the sandbox
press" — on its own it cannot distinguish "the token was rewritten" from "the token
was never scanned", so runs B and C were disambiguated by an actual press:

| # | Action | Observed output | Exit |
|---|---|---|---|
| G | `press rebrand --target <copy> --config answers.toml` on a copy carrying **both** the glued forms of B and the binary blob of C, toward a throwaway identity (`zz_pressed` / `zz-pressed` / `zzp`) | plan listed `[replace] assets/logo.bin — fields=['package_name']` and `[replace] src/lib.rs — fields=['app_name', 'app_name_upper']`; then `Applied: 6 replaced, 0 renamed, 0 reset, 0 removed, 0 regenerated, 0 skipped.` and `verified: no identity leftovers. receipt: …/press/press-receipt.toml` | **0** |

Post-press inspection (**executed**): `grep -rIn` over the pressed copy found the old
identity only inside `press/press-receipt.toml` (which records the pre-press identity
by design); `src/lib.rs` now reads `pub const ZZP_HOME` and `pub fn zzp_config_path()`;
and the binary asset's bytes changed from `…rs_launch_blueprint\x00trailer` to
`…zz_pressed\x00trailer`. So the identifier-aware matcher (0007 D1) does rewrite
`SCREAMING_SNAKE` and `snake_case` components of the app name **without**
`substring_rewrite_fields`, and non-UTF-8 assets **are** in the rewrite inventory
rather than being skipped. Both B and C were clean passes, not silent gaps, and the
apparent contradiction with design 0007 §5.3's binary-leak regression tests is
resolved: those tests describe a leak that survives, which is not what happened here.

Run G also produced, as a by-product, the executed proof of acceptance criterion 4:
with the press's own `press/press-receipt.toml` now present, py's receipt-guard shell
body (`if [ -f press/press-receipt.toml ]; then … exit 1; fi`) printed
`::error::press-receipt.toml committed in the template — it would disarm every fork's
guard. Revert.` and exited **1**.

**One caution that run G exposes, and it matters for rs.** The binary asset was
rewritten *as text*: 36 bytes became 27, because `rs_launch_blueprint` (19 bytes) was
replaced by `zz_pressed` (10). For my contrived blob that is harmless, but a real
length-sensitive binary — a PNG with per-chunk CRCs, an ICO, a compiled font, an
archive with an offset table — would be **corrupted** by a rewrite of an identity
string inside it, and `press verify` would report exit 0 because no identity survived.
Rule for rs: keep the identity out of binary assets, or declare each such asset in
`[rules] extra_exclude_files` together with a `[[regenerate]]` or `[[remove]]` entry
that neutralizes it. This is a real hazard the leak scan structurally cannot detect.

Run A is the acceptance proof that the owner-fixed mechanism works on a Rust target
today, with no changes to `template-press`. Runs D/E/F exercise all three exit codes
of the contract. Runs E and F together are the direct measurement of the discovery
gap: F shows `owner` (git-origin-derived) is genuinely cross-checked, E shows
`package_name` survives only on the weaker presence fallback and would pass silently
if the stale value happened to appear anywhere in the repo.

**The compensating control, also executed.** A 25-line checker comparing
`press/press-source.toml` to `cargo metadata --no-deps --format-version 1 --offline`
(package name vs `repo_name`; lib target name vs `package_name`; bin target names vs
`app_name`; `authors` entries vs `email`) printed
`press-source.toml agrees with cargo metadata` and exited 0 on the matching target,
and on a target whose `[[bin]] name` had drifted to `rslb` printed
`error: bin targets ['rslb'] do not include app_name 'rslbp'` and exited 1
(**executed** 2026-09-09). In the template this belongs as a Rust integration test
(py's analogue is its `tests/meta/*` suite, e.g. `tests/meta/test_contributors_state.py`
named in py `press/press-rules.toml:139`), so it runs inside `cargo test` with no new
CI job.

**One Rust-specific rule finding, and one non-finding.**

- *Finding — CLI help snapshots need `verify_exempt`.* py declares its help-snapshot
  file as `[[regenerate]] … verify_exempt = true` with the reason "CLI help snapshots
  re-wrap at the new name's length" (`press/press-rules.toml:43-47`). `clap` wraps
  `--help` output against the terminal width, so an `insta`/`trycmd` snapshot of
  `rslbp --help` has the identical length sensitivity. rs must declare the same
  exemption for whatever snapshot files R33 lands, with `verify_exempt = true` and a
  stated `reason` (the schema requires a non-empty reason whenever `verify_exempt` is
  set — `rules.py:681`).
- *Non-finding — `Cargo.lock` needs no `[[regenerate]]` analogue to py's `uv.lock`.*
  I ran `cargo generate-lockfile --offline` on the synthetic target and the lock's
  only identity-bearing entry is the root package's `name = "rs-launch-blueprint"`
  with **no `checksum` field** (**executed** 2026-09-09). Checksums attach to
  registry dependencies, whose names the press never touches, so a plain text rewrite
  of `Cargo.lock` is correct and hermetic verify handles it with no exemption. A
  `[[regenerate]] file = "Cargo.lock" command = ["cargo", "update", "--workspace",
  "--offline"]` entry is optional belt-and-braces, not a requirement; I recommend
  omitting it, because every declared regeneration command widens the press's
  ignore-policy/index fingerprint surface (design 0006 §3).

**Observable acceptance criteria.**

1. `press verify` exits **0** on `main` and on every PR head.
2. Introducing an identity-bearing file that the rules exclude from rewrite makes it
   exit **1** and name the file, line and column (demonstrated: run D).
3. Making `press/press-source.toml` disagree with the repository makes it exit **2**
   before any sandbox is built (demonstrated: runs E and F).
4. `press/press-receipt.toml` present in the tree fails `template-receipt-guard`
   with the message "press-receipt.toml committed in the template — it would disarm
   every fork's guard. Revert." and exit 1.
5. `cargo test` fails when `press/press-source.toml` disagrees with `cargo metadata`
   (demonstrated on the synthetic target).

**Ledger note (not a `BASELINE-REVIEW:` finding).** `docs/port/COVERAGE.md:41-43`
excludes `press/*`, `prototypes/press_tui/*` and `scripts/guard.sh` from the survey
on the ground that "whether rs-launch-blueprint is itself a rebrandable template is
R15's open question". The owner settled that question on 2026-09-04, so
`press/press-rules.toml` and `press/press-source.toml` are now the *reference
implementation* this item ports, and the exclusion rationale is stale. This is a
coverage-document rationale, not a numbered ledger baseline, so it is reported here
for the reconciliation task rather than as `BASELINE-REVIEW:`.

### Dominant choice

**Carry py's mechanism unchanged in shape — two workflow files driving the external
`template-press` CLI — with Rust-native press inputs and a `cargo metadata` identity
cross-check that replaces the tool's Python-only discovery guard.**

Concretely, rs ships: `press/press-source.toml` (six identity fields);
`press/press-rules.toml` (Rust `[[regenerate]]`/`[[reset]]`/`[[remove]]` entries);
`.github/workflows/press-verify.yml` (identity-literal-free, ships to forks);
`.github/workflows/template-receipt-guard.yml` (template-only, `[[remove]]`d by the
press in forks); and `tests/press_source.rs` (the compensating cross-check).
Run A above is the executed evidence that this works on a Rust target with the
released tool and no upstream change.

### Options

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **`template-press` `press verify` + template-only receipt guard** (the pair) | `template-press` design 0006 (external-target model) and 0007 (`press verify` design), plus PyPI project description | py-launch-blueprint (`.github/workflows/press-verify.yml`, `.github/workflows/template-receipt-guard.yml`, `press/press-rules.toml`, `press/press-source.toml`) | design 0007 / release 4.0.1, 2026-08-18 |
| **Generate-then-build CI over a `cargo-generate` template** | cargo-generate book; `cargo-generate-action` README | `cargo-generate` itself (`e2e-test.yml`, 3-OS weekly); `rust-github/template` (`build.yml`, `cargo check --tests` in `runner.temp`) | cargo-generate 0.24.0, 2026-08-31 |
| **Bespoke generator binary, tested like any other crate** | `esp-generate` README | `esp-rs/esp-generate` (replaced the now-archived `esp-rs/esp-template`) | repository pushed 2026-09-08 |
| **GitHub template repository + hand-rolled rename script** | GitHub docs on template repositories | widespread but unverified; no surveyed project pairs it with a CI proof | GitHub docs, retrieved 2026-09-09 |
| **Committed answers-file model (cookiecutter/copier/cruft)** | copier and cruft documentation | outside Rust | — (cited as the contrasting convention, not proposed) |
| **No check (status quo of ts-launch-blueprint)** | — | ts-launch-blueprint (`docs/port/areas/ci-workflows.md:43`) | — |

### Excluded by gate

The six fitness gates are written for *crate* candidates. This is a `pattern` item
whose realization pulls in **no runtime crate and no normal Cargo dependency**: the
tool is a CI-time Python executable, and the compensating control uses
`cargo metadata`, which ships with Cargo. Its one Cargo dependency is a
`[dev-dependencies]` TOML/JSON parser for `tests/press_source.rs`, whose own gates
belong to R52. Each gate is therefore answered for `template-press` (the thing
actually adopted) with `inapplicable` and a reason where it does not bear.

| Gate | Verdict for `template-press` 4.0.1 |
|---|---|
| 1. License compatible with `MIT OR Apache-2.0` | **Pass.** MIT (`GET https://api.github.com/repos/smorinlabs/template-press` → `license.spdx_id: "MIT"`; PyPI classifiers, retrieved 2026-09-09). MIT is compatible with a dual-licensed consumer, and the tool is never linked or vendored — it runs in CI and produces no artifact that ships. |
| 2. Crate and dependency-tree MSRV within `stable minus 2 minor versions…` | **Inapplicable** — no crate, no Cargo dependency, nothing enters `Cargo.toml`. The analogous constraint is the tool's own floor: `requires_python >=3.13` (PyPI metadata), satisfied by provisioning Python 3.13 in the workflow. |
| 3. No open RustSec advisory; `unsafe` posture | **Inapplicable for RustSec** (not a crate; `https://rustsec.org/packages/template-press.html` has no page). Checked the cross-ecosystem equivalent instead: `POST https://api.osv.dev/v1/query {"package":{"name":"template-press","ecosystem":"PyPI"}}` returned `{}` — no known advisories, retrieved 2026-09-09. `unsafe` posture: **inapplicable** (no Rust code); the analogue is that the rebrand engine is pure standard library with "zero runtime dependencies" (PyPI description), which is a genuine supply-chain positive for a tool with write access to the repository. |
| 4. Builds and is tested on `ubuntu-latest, macos-latest` | **Pass.** `smorinlabs/template-press/.github/workflows/ci.yml` runs its test matrix on `blacksmith-4vcpu-ubuntu-2404`, `blacksmith-6vcpu-macos-latest` and `blacksmith-4vcpu-windows-2025` × Python 3.13 (retrieved 2026-09-09). Windows supported and tested, though not required here. Independently: my run A executed successfully on macOS arm64. |
| 5. Default features and async-runtime coupling | **Inapplicable** — no Cargo features and no async runtime. The nearest real coupling is stated instead: `press verify` shells out to `git` only (`check_tools.py`), and is offline and network-free by design (0007 D5). |
| 6. Binary-size and compile-time cost | **Inapplicable** — nothing is compiled into the template and nothing ships in a release artifact. The real cost is CI wall-clock: one extra job that provisions uv + Python 3.13 and runs a text scan over the tracked tree. Qualitatively this is the cheapest job in the workflow set — no `cargo build`, no network, no cache. |

*Excluded candidates* (as the mechanism for this pattern):

- **`cargo-generate`** — excluded by owner direction (it is a placeholder generator,
  not a rebrand engine, and adopting it would make the template a non-buildable tree
  and break the three-repo agreement). Retained above as the source of the
  build-the-generated-copy practice, which informs the runner-up.
- **`create-rust-app` / `create-rust-app_cli`** — excluded on maintenance: newest
  non-yanked version 11.0.3 released 2025-06-22T04:28:11Z and `pushed_at`
  2025-06-22T04:27:04Z, i.e. ~14.5 months without a release or a push as of
  2026-09-09, with 22 open issues. Under the rubric that is a trigger to investigate;
  the concrete signal (repository and registry both silent for over a year while
  issues remain open) makes it **at-risk**, and it is a full-stack app generator, not
  a verification pattern, so it is out of scope on fit as well.
- **`iomentum/cargo-scaffold`** — excluded on gate 1 evidence quality: crates.io
  reports `license: "non-standard"` for 0.15.0 while the GitHub repository reports
  MIT. A candidate whose registry license metadata does not resolve cleanly cannot
  pass a license gate on the evidence available.
- **`backpack`** — excluded: the crates.io record for that name is an unrelated,
  abandoned crate (0.1.0 released 2022-01-19T22:45:00Z, no `repository` field, 9
  downloads in 90 days). Not the tool it is sometimes confused with, and dormant
  either way.
- **`Keats/kickstart`** — not excluded by a gate (MIT, `pushed_at` 2025-12-21, 0.6.0
  released 2025-12-21, 14 open issues; **stable-quiet** — a single maintainer with a
  long track record and no unpatched advisory or broken build reported). Excluded on
  **fit**: it is a placeholder scaffolder in the same architectural class as
  `cargo-generate`, so it loses for the same reasons and offers nothing
  `cargo-generate` does not.

**Maintenance rubric for `template-press` itself**: **active** — 9 releases between
2026-07-17 (3.0.0) and 2026-08-18 (4.0.1), `pushed_at` 2026-09-09T03:46:57Z,
`archived: false`, no OSV advisories. The honest dependability caveat, stated because
it is the mechanism a CI gate will depend on: 0 stars and a single-owner
organisation, i.e. **bus factor 1**, and its documentation site
`https://template-press.readthedocs.io/en/latest/` returned **HTTP 404** on
2026-09-09 (the design records in the repository are the working documentation).
This does not change the decision — the owner fixed the mechanism, and the risk is
already carried by py — but it justifies pinning an exact version (below) and
recording the fallback: if the tool became unavailable, the guard degrades to the
receipt check plus the `cargo metadata` cross-check, both of which are repo-local.

### Up-and-comers

- **`esp-rs/esp-generate`** (297 stars, pushed 2026-09-08): the maintained successor
  to an archived `cargo-generate` template. The trend it represents — replacing a
  placeholder template with a purpose-built generator binary that is tested like any
  other crate — is the ecosystem converging on *executable, testable* templating,
  which is the same instinct behind `press verify`. Worth re-checking at the
  re-verify trigger below, because a Rust-native rebrand engine emerging in this
  space would change the make-or-buy calculus for `template-press`.
- **`cargo-generate` 0.24.0** (2026-08-31) and `cargo-generate-action@v0.20.0`: the
  action is comparatively stale (`pushed_at` 2024-08-04) while the tool is not — if
  the runner-up lane below is ever adopted, drive it with the CLI, not the action.
- **copier's `update` model** (cross-ecosystem): a committed answers file that lets a
  generated project *re-pull* upstream template changes. This is the capability
  `template-press` deliberately does not have (a press is one-way), and it is the
  strongest argument that could later be made for changing mechanism. Not proposed:
  the owner fixed the mechanism, and one-way rebrand plus a leak scan is what all
  three repos must share.

### Fit for this template

The template is one repository presenting three shapes; the press acts on the
repository, so the pattern is shared, but each shape contributes different identity
surfaces and different exemptions.

**CLI.** The heaviest identity surface and the only one with a rewrapping hazard.
`app_name` is the `[[bin]] name`, the installed binary, the `Cargo.toml`
`[[bin]]` table, and every occurrence in `--help` text, README usage blocks, shell
completions and man pages. Two concrete consequences: (i) `clap`'s help output wraps
against the *name's length*, so any `insta`/`trycmd` snapshot of `--help` must be
declared `[[regenerate]] … verify_exempt = true` with a reason, exactly as py does
for its `.ambr` snapshots (`press/press-rules.toml:43-47`); (ii) glued forms
(`RSLBP_HOME`, `rslbp_config_path`) are handled by the identifier-aware matcher
without `substring_rewrite_fields` — **executed** as run B — so rs should *not*
copy py's `substring_rewrite_fields = ["app_name", "app_name_upper"]` line
speculatively; add it only if a real glued occurrence survives a `press verify`.
Prefer `env!("CARGO_PKG_NAME")` and `clap`'s derived name over hard-coded literals
where the crate needs its own name at runtime: identity that Cargo supplies is
identity the press never has to rewrite. (Coordinates with R22, runtime version
accessor.)

**Library.** `package_name` is the lib target name and the `use` path. The binding
constraint discovered here is that the underscored form **must appear in tracked
content** or `press verify` exits 2 as `unverifiable` (`verify_cli.py:251-311`,
default scan scope `verify_config.py:34`). For a library that is exercised by
integration tests under `tests/`, `use rs_launch_blueprint::…` satisfies this
naturally — but it means the template must keep at least one integration test that
names the crate, and a unit-test-only layout would break the guard silently. Also
note the interaction with a multi-crate workspace: if R49/R02 land
`crates/rs-launch-blueprint-cli/` and `crates/rs-launch-blueprint-core/`, the press
must rename *directories* as well as content, and the glued suffixes
(`-cli`, `-core`) reproduce py's G3 class, which is what
`[rules] substring_rewrite_fields` and `[[replace]]` exist for.

**Web service.** The lightest surface, but the one with runtime identity leakage:
service names in OpenAPI `info.title`, container image names, Prometheus metric
namespaces, health-probe payloads and log target fields all embed the identity.
Two rules follow. First, any generated artifact committed as a snapshot — an
`openapi.json` fixture (R71/R82) — is identity-bearing generated text and needs a
`[[regenerate]]` entry, with `verify_exempt` only if its content is
length-sensitive. Second, if the web surface lives behind a Cargo feature (R69's
`web-extra-surface`), the press still rewrites those files whether or not the feature
is enabled, because the press operates on the git tree, not on a build
configuration — feature-gating cannot be used to keep identity out of the scan.

### Recommendation

Ship the pattern as five files plus one CI provisioning decision.

**1. `press/press-source.toml`** — the six required identity fields, committed:

```toml
[identity]
package_name = "rs_launch_blueprint"
repo_name    = "rs-launch-blueprint"
app_name     = "rslbp"
author       = "Steve Morin"
email        = "steve.morin@gmail.com"
owner        = "smorinlabs"
```

`app_name` and the crate names are **provisional** until R49
(`build-tool-output-shape`) fixes the binary and library target names; the field
shape is not.

**2. `press/press-rules.toml`** — start minimal and let `press verify` earn every
entry. The two that are certain today:

```toml
[rules]

[[reset]]
file = "CHANGELOG.md"
stub = "# Changelog\n"

[[remove]]
file = ".github/workflows/template-receipt-guard.yml"
reason = "template-only receipt guard; a fork legitimately commits its receipt"
```

Add, when the corresponding item lands: a `[[regenerate]] … verify_exempt = true`
entry for CLI `--help` snapshots (R33); a `[[regenerate]]` entry for a committed
`openapi.json` (R71); `[[remove]]` entries for template-only workflows a fork cannot
run (mirroring py's treatment of `update-contributors.yml` and
`difftree-pr-comment.yml`). Do **not** pre-emptively add `substring_rewrite_fields`
or a `Cargo.lock` `[[regenerate]]`: run B and the `cargo generate-lockfile`
observation show neither is needed.

**3. `.github/workflows/press-verify.yml`** — identity-literal-free, ships to forks:

```yaml
# Press drift guard: `press verify` hermetically self-presses a sandbox copy
# and scans for surviving identity (exit 1); config errors exit 2. This
# workflow deliberately SHIPS to pressed forks and carries NO identity
# literals; the template-only receipt guard lives in
# template-receipt-guard.yml, which the press removes in forks.
name: press-verify

on:
  pull_request:
  merge_group:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  press-verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: astral-sh/setup-uv@v7
        with:
          python-version: "3.13"
      - name: press verify
        run: |
          uv venv --python 3.13
          uv pip sync press/requirements.txt
          uv run press verify
```

The three `run:` lines are **executed**, not proposed: with a `press/requirements.txt`
containing `template-press==4.0.1`, that exact sequence in the synthetic target
printed the "verified" line and exited 0 on 2026-09-09. `uv run press verify` needs no
`--no-project` flag in a directory with no `pyproject.toml` (both forms were tried and
both exited 0), and the `.venv/` directory uv creates is untracked, so the
index-driven scan ignores it. The surrounding YAML (triggers, permissions, action
versions, `setup-uv` inputs) is **planned**: action versions mirror py's
`press-verify.yml` as of 2026-09-09 and are a placeholder for R20's pinning policy.

`runs-on: ubuntu-latest` is deliberate and matches py's stated reason — this file
ships to generated repositories, which have no custom runners. It is also the one
place where the `target-os-matrix` parameter does *not* apply: the check is a text
scan of the git tree with no platform-dependent behavior, so a macOS leg would buy
nothing. (Action version pins are placeholders; R20 owns the pinning policy.)

**4. `press/requirements.txt`** — the version pin, and the one genuinely new
decision. py pins the tool through `uv.lock` under its WL-001 rule ("hook/CI tools
run from the locked dev group, never floating uvx" — `press-verify.yml:32-33`);
rs has no Python lockfile, so the pin needs a home. Three options:

| Option | Effect |
|---|---|
| Inline `uvx --from 'template-press==4.0.1' press verify` in the workflow | Simplest, and it is exactly what I executed. But Dependabot does not parse versions out of `run:` strings, so the pin rots silently. |
| **`press/requirements.txt` with `--generate-hashes`, plus a Dependabot `pip` entry for `/press`** | The pin becomes a dependency the bot owns and a human reviews; hashes make the CI tool supply-chain-pinned. One extra file. **Recommended.** |
| `uv tool install template-press@4.0.1` | Same rot problem as inline, plus a global-tool install in CI. |

Recommended content, generated with `uv pip compile --generate-hashes`:
`template-press==4.0.1` with its hashes. Coordinates with R19
(`dependabot-config-shape`), which owns whether a `pip` ecosystem entry is acceptable
in a Rust repo's `dependabot.yml`.

**5. `.github/workflows/template-receipt-guard.yml`** — take py's file as-is; its
job body is pure shell over a fixed control-file path and contains nothing
language-specific, so the only thing rs decides is the action pin (R20). py's own
file also carries a five-line header comment explaining why this guard lives apart
from `press-verify.yml`; carry that comment across too. Shown here with py's current
`actions/checkout@v7`:

```yaml
name: template-receipt-guard
on:
  pull_request:
  merge_group:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  no-committed-receipt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: No committed receipt in the template
        run: |
          if [ -f press/press-receipt.toml ]; then
            echo "::error::press-receipt.toml committed in the template —" \
              "it would disarm every fork's guard. Revert."
            exit 1
          fi
```

The guard's shell body was **executed** against a directory containing a real
`press/press-receipt.toml` (produced by run G) and exited 1 with the expected
`::error::` line.

**6. `tests/press_source.rs`** — the compensating control (a `cargo test` integration
test, not a CI job). Cargo auto-discovers integration tests as `tests/*.rs` or
`tests/<name>/main.rs`, so the file sits directly in `tests/`, not in a `tests/meta/`
subdirectory, which Cargo would not pick up. It parses `press/press-source.toml`,
shells out to `cargo metadata --no-deps --format-version 1 --offline`, and asserts
that `repo_name` equals the package name, `package_name` is a lib target name,
`app_name` is a bin target name, and `email` occurs in `authors`. This restores, in
Rust, the four discovery cross-checks that `discovery.py` can only perform against a
`pyproject.toml`, and it fails at `cargo test` time — before CI, before a press.
Executed in prototype (above, in Python), with both the passing and the drifted case.
It needs one **dev-dependency**: a TOML parser to read `press-source.toml` and a JSON
parser for `cargo metadata` output. That is the single Cargo dependency this pattern
adds, it is `[dev-dependencies]` only, and the crate choice is deferred to R52
(`toml-crate`) and the serialization item that owns JSON — so the fitness gates below,
which report "no crate is adopted", are answered for the mechanism itself and defer
this dev-dependency's gates to R52.

**On the receipt and `.gitignore` — do not "improve" on py here.** py does **not**
list `press/press-receipt.toml` in `.gitignore` (verified: no press/receipt/answers
lines in py's `.gitignore`, retrieved 2026-09-09), and that is correct rather than an
oversight: a fork *legitimately commits its receipt* (py `press/press-rules.toml:120`),
and a `.gitignore` line would survive the press — which removes whole files, not
single lines — and would silently prevent every fork from committing the receipt it
is supposed to have. The workflow guard is removable per-file; a `.gitignore` line is
not. Do ignore `press/press-answers.toml`, which is transient operator input that no
one should ever commit: "Keep your filled-in `press-answers.toml` out of the target
(it is transient operator input, not committed state)" (`template-press` PyPI
description, retrieved 2026-09-09). If a placeholder is wanted, commit
`press/press-answers.example.toml`, the convention the same paragraph describes.

**On generalizing the receipt guard (the MEDIUM question).** Keep it single-purpose.
The receipt guard is not tidiness — it protects a *semantic* invariant with a
blast radius beyond this repo (a committed receipt disarms every downstream fork's
guard), it is scoped to one exact path, and it must be `[[remove]]`d in forks while a
general hygiene check must not be. Folding it into a "no stray tool-output files"
deny-list would make it un-removable-in-forks and would bury a security-shaped
invariant in a lint. The general hygiene need is real for Rust — `target/`,
`*.profraw`/`*.profdata`, `flamegraph.svg`, `perf.data`, `*.orig`/`*.rej`,
`*.crate` — but it belongs to R14 (`large-file-guard-strategy`) and R26
(`packed-artifact-content-guard`), which already own committed-artifact hygiene;
this item should hand them the deny-list and keep its own guard narrow.

**On ts's silence (the LOW question).** The silence is an undocumented gap, not a
decision, and there is now dated evidence for why. `template-press` did not exist as
an installable standalone tool until **3.0.0 on 2026-07-17**, and its
*external-target* model — the design that lets it press a repository it was not
extracted from — is design 0006, accepted 2026-06-23 and shipped in **4.0.0 on
2026-08-18** (PyPI release history, retrieved 2026-09-09). A ts port completed before
mid-2026 could not have adopted a mechanism that was still py-internal. Combined with
the recorded absence of any `D-0xx` in ts's own decision log
(`docs/port/DIVERGENCE-ANALYSIS.md:99`: "no recorded reason; ts's own decision log
carries no D-0xx adopting or rejecting it") and the owner's 2026-09-04 direction that
ts should adopt it too, the correct reading is: **a gap explained by timing, not a
rejection.** Treating it as a considered rejection would be reasoning from silence
against the owner's explicit direction. Note for the follow-on ts project: ts is
better placed than rs on the discovery guard, because `discovery.py` reads
`pyproject.toml` only — a `package.json` backend does not exist either, so ts would
land in the same 2-of-6 position and wants the same compensating control, written
against `npm pkg get` or `package.json` directly.

**One upstream request worth filing** (not a blocker; run A passes without it): a
Cargo discovery backend for `template-press` that reads `Cargo.toml`
(`[package] name`, `[[bin]] name` / `src/bin/*`, `authors`) and the `src/lib.rs`
versus `src/main.rs` layout, restoring the 6-of-6 cross-check for Rust targets. The
`Discovered` dataclass already has the right fields; only the reader is
Python-specific.

### Ranked runner-up

**Add a second, separate lane that presses a copy into `$RUNNER_TEMP` and builds
it** — `press rebrand --target "$RUNNER_TEMP/pressed" --config <values>` followed by
`cargo build --workspace && cargo test --workspace` in that directory. This is the
Rust ecosystem's own practice (cargo-generate's `e2e-test.yml`; rust-github/template's
`build.yml`) transplanted onto the press.

**The condition under which it wins**: as soon as a `press verify` pass is observed
to co-exist with a pressed copy that does not compile. Concretely, that happens when
the identity is embedded somewhere the text scan cannot reason about — a `macro_rules!`
or `proc-macro` that reconstructs a path from fragments, an `include!`/`include_str!`
whose path is assembled at compile time, or a workspace member directory rename that
leaves a stale `[workspace] members` glob. A leak scan proves *no old identity
survives*; it does not prove *the new identity is coherent*. The moment rs has any of
those constructs, this lane becomes required rather than optional.

Two implementation constraints if it is adopted, both from the evidence above:
(i) the pressed copy **must** be built outside the template's directory tree —
rust-github/template moves the generated project to `${{ runner.temp }}` and cites
`rust-lang/cargo#9922` for the reason, and the same parent-manifest capture would
otherwise apply to a pressed copy; (ii) the pressed copy's `Cargo.lock` needs no
regeneration (the root package entry carries no checksum — executed observation), so
the lane is a plain `cargo build`/`cargo test` with no lock surgery.

I do **not** recommend it now, for one reason that is about agreement rather than
value: the owner's direction is that all three repos use the same mechanism the same
way, and py runs no such lane. Adding it to rs alone would make rs's press story
diverge from py's on day one. It is the right *first* addition once the family
agrees to add it everywhere.

### Tradeoffs

**Versus the runner-up (press-and-build lane).** The recommendation gives up
compile-level proof of the pressed copy. Accepted because: the leak scan is
exhaustive over the identity token set and reports file/line/column (run D), whereas
a build proves only that one instantiation compiles; the scan is hermetic, offline,
and takes seconds while a `cargo build --workspace` on two OS legs is the most
expensive job in the set; and py — the repo whose behavior the owner told us to
match — does not run it. The residual risk is precisely the macro/`include!`/workspace-glob
class named above, and the re-verify trigger below watches for it.

**Versus `cargo-generate` (the ecosystem-standard alternative).** The recommendation
gives up alignment with the tool most Rust developers already know, its documented
Liquid templating, its `--template-values-file` CI story, and its 2,484-star
community. Accepted because adopting it would cost strictly more: the template would
stop being a buildable repository, so every other CI gate in this template (clippy,
tests, docs, coverage, MSRV) would lose its subject; the family's shared mechanism
would break on day one against explicit owner direction; and its verification is
weaker (one sample compiles) than the one being replaced (no identity survives).

**Versus a hand-rolled rename script.** Gives up zero external dependencies and full
local control. Accepted because it would trade a maintained tool with an exit-code
contract, an occurrence-level scanner, symlink-escape hardening (0007 §5.1) and a
receipt model for a `sed` pipeline this repository would then have to test itself —
and it would break family agreement for no gain.

**Costs actually incurred, stated plainly.** (i) rs's CI acquires a **Python 3.13 +
uv provisioning step** in one job — a real cross-ecosystem dependency in a Rust
repository, mitigated by keeping it in a single leaf job that no other job depends
on. (ii) rs depends on a **bus-factor-1, 0-star tool** for a required check; mitigated
by an exact hash-pinned version, and bounded because a failure of the tool degrades
to the two repo-local checks (receipt guard, `cargo metadata` cross-check) rather
than to nothing. (iii) The identity guard is **weaker on Rust than on Python**
(2 of 6 fields cross-checked) until either the upstream Cargo discovery backend lands
or the compensating test is written — which is why the compensating test is part of
the recommendation and not an optional extra.

### Parameters

R15 owns no parameter (`research/CLAUDE.md`, R15 row: `owns` = `—`) and its
`Couplings` list no consumed parameter. No parameter value needs to change.

- `assumes rust-edition = 2024` — used only in the synthetic acceptance target's
  `Cargo.toml`; the pattern is edition-independent.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — no crate is added, so nothing here moves the MSRV floor. `rust-version` is one more identity-free `Cargo.toml` field the press does not touch.
- `assumes license = MIT OR Apache-2.0` — satisfied; `template-press` is MIT and is never linked or redistributed.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — both new workflows
  deliberately run on `ubuntu-latest` only. Rationale, stated so a reviewer can
  reject it knowingly: `press verify` is a platform-independent text scan of the git
  tree, and `press-verify.yml` ships to pressed forks, which have no guarantee of any
  particular runner (py states this reason in-file at
  `.github/workflows/press-verify.yml:23-24`). This is a single-OS job inside a
  two-OS repository, not a narrowing of the parameter.

**No `CONFLICT:` lines.**

Coordination notes for items that own parameters this pattern touches (flagged, not
consumed, and not conflicts):

- **R11 (`ci-job-structure`)** — the two-workflow split is *mandated by the
  mechanism*, not a style choice: `press-verify.yml` must ship to forks free of
  identity literals, and `template-receipt-guard.yml` must be `[[remove]]`-able as a
  whole file. R11 cannot fold these two into one job or one file without breaking the
  press. Both are leaf jobs with no dependents, so they compose with any job
  structure R11 picks.
- **R49 (`build-tool-output-shape`) and R02 (`crate-boundary-enforcement`)** — the
  `package_name`/`app_name` values above are provisional until R49 fixes the library
  and binary target names, and a multi-crate workspace adds directory renames plus
  glued-suffix (`-cli`, `-core`) rewrite rules.
- **R19 (`dependabot-config-shape`)** — the recommended `press/requirements.txt` pin
  needs a `pip` ecosystem entry pointed at `/press`.
- **R20 (`third-party-action-pinning-policy`)** — both workflows use
  `actions/checkout` and `astral-sh/setup-uv`; the version-pinning form shown is a
  placeholder for R20's policy.
- **R42 (`package-manager-invocation`)** and **R33 (property/snapshot testing)** —
  the `[[regenerate]]` commands in `press/press-rules.toml` must be spelled exactly
  as those items decide tools are invoked (`cargo insta test --accept` versus a
  provisioned binary), because `press check-tools` resolves `argv[0]` literally.
- **R14 / R26** — receive the "stray tool-output files" deny-list described above.

### Migration implications

File-level changes in `rs-launch-blueprint`. Nothing here touches Rust source
semantics; the whole pattern is control files, two workflows and one test.

**Added**

| Path | Content | Notes |
|---|---|---|
| `press/press-source.toml` | the six identity fields (`package_name`, `repo_name`, `app_name`, `author`, `email`, `owner`) | committed and authoritative; values provisional until R49 fixes target names |
| `press/press-rules.toml` | `[rules]`, the `CHANGELOG.md` `[[reset]]`, and the `[[remove]]` of `template-receipt-guard.yml` | grows as `press verify` reports leaks; add snapshot `verify_exempt` entries when R33 lands |
| `press/press-answers.example.toml` | placeholder advertising the `[answers]` field shape | optional; the convention `template-press` documents |
| `press/requirements.txt` | `template-press==4.0.1` with `--generate-hashes` hashes | the version pin Dependabot can own (needs an R19 `pip` entry for `/press`) |
| `.github/workflows/press-verify.yml` | provisions uv + Python 3.13, runs `uv run press verify` | **ships to pressed forks**; must contain no identity literal; `runs-on: ubuntu-latest` |
| `.github/workflows/template-receipt-guard.yml` | `[ -f press/press-receipt.toml ]` → error + exit 1 | **template-only**; copied verbatim from py; deleted in forks by the `[[remove]]` rule |
| `tests/press_source.rs` | asserts `press/press-source.toml` agrees with `cargo metadata --no-deps --format-version 1 --offline` | the compensating control for the Python-only discovery guard; runs inside `cargo test` |

**Modified**

- `.gitignore` — add `press/press-answers.toml` (transient operator input). Do **not**
  add `press/press-receipt.toml`: a fork legitimately commits its receipt, and the
  press removes whole files, not `.gitignore` lines.
- `.github/dependabot.yml` — add a `pip` ecosystem entry for `/press` (R19 owns the
  shape).
- `Cargo.toml` — keep `authors = ["Steve Morin <steve.morin@gmail.com>"]` even though
  Cargo no longer adds it by default, so `author`/`email` have a home in the tree if
  the verify scan scope is ever widened with `[verify] extra_fields`.
- Branch protection / the aggregate required check (R12) — add `press-verify` and
  `template-receipt-guard` as required contexts, otherwise both guards are advisory.

**Structural constraints created for other items**

- The two workflows must stay **two files** — R11 cannot merge them into one job or
  one file (see `### Parameters`).
- At least one integration test under `tests/` must name the library crate
  (`use rs_launch_blueprint::…`), because the underscored `package_name` must occur
  in tracked content or `press verify` exits 2 as `unverifiable`.
- Any committed generated snapshot whose text is length-sensitive (CLI `--help`,
  `openapi.json`) needs a `[[regenerate]]` entry, with `verify_exempt = true` and a
  non-empty `reason` where the command cannot run in the hermetic sandbox.

**Documentation drift to fix at reconciliation** — `docs/port/COVERAGE.md:41-43`
still excludes `press/*`, `prototypes/press_tui/*` and `scripts/guard.sh` on the
ground that rebrandability "is R15's open question". The owner settled it on
2026-09-04, and py's `press/press-rules.toml` and `press/press-source.toml` are the
reference implementation this item ports, so those exclusion rationales are stale.

### Validation strategy

**Executed (2026-09-09, macOS darwin arm64, cargo 1.98.0, `uvx` from uv at
`~/.local/bin/uvx`, `template-press==4.0.1` from PyPI), against a synthetic Rust
target in a scratch directory — no repository file was modified:**

```
# A — the acceptance proof: the owner-fixed mechanism works on a Rust target
uvx --from 'template-press==4.0.1' press verify --target "$T"
#   -> "verified: no identity leftovers survived the hermetic self-press
#       (clean over the scanned set)."   exit 0

# D — a leak is caught with file/line/column
#   (docs/NOTES.md listed in [rules] extra_exclude_files, containing the identity)
uvx --from 'template-press==4.0.1' press verify --target "$T"
#   -> "verify FAILED — source identity survived the hermetic self-press:"
#      "  docs/NOTES.md"
#      "    [content L3:C34] app_name='rslbp'"
#      "    [content L3:C13] package_name='rs_launch_blueprint'"
#      "    [content L3:C13] repo_name='rs-launch-blueprint'"   exit 1

# E — a stale package_name is caught only by the presence fallback on a Rust target
#   -> "error: package_name: declared 'rs_launch_blueprint_core' is neither
#       discoverable nor present anywhere in the target
#       (undiscoverable and absent)"                            exit 2

# F — owner IS cross-checked, because it comes from the git origin
#   -> "error: owner: source-config says 'wrongowner' but target shows
#       'smorinlabs'"                                           exit 2

# Compensating control, both directions
python3 check_press_source.py "$T"
#   -> "press-source.toml agrees with cargo metadata"           exit 0
#   with [[bin]] name drifted to "rslb":
#   -> "error: bin targets ['rslb'] do not include app_name 'rslbp'"
#      "MISMATCH"                                               exit 1

# Cargo.lock has no checksum on the identity-bearing entry
cargo generate-lockfile --offline
#   -> [[package]] name = "rs-launch-blueprint" / version = "0.1.0"; no checksum
```

Runs B (glued `RSLBP_HOME` / `rslbp_config_path` forms → exit 0) and C (a committed
binary blob carrying the identity → exit 0) were also executed, and run G — a real
`press rebrand --target <copy> --config answers.toml`, exit 0 — proved both were
rewrites rather than blind spots: the plan named `[replace] assets/logo.bin` and
`[replace] src/lib.rs — fields=['app_name', 'app_name_upper']`, the pressed
`src/lib.rs` reads `ZZP_HOME` / `zzp_config_path`, and the blob's bytes became
`…zz_pressed\x00trailer`. Run G also wrote `press/press-receipt.toml`, against which
py's receipt-guard shell body exited 1 with the expected `::error::` message. The
recommended workflow's three `run:` lines (`uv venv --python 3.13`;
`uv pip sync press/requirements.txt`; `uv run press verify`) were executed in the same
target and exited 0.

**Planned (to run in the template once the files exist):**

1. `uv run press verify` in CI on every PR and on `main` — expect exit 0.
2. Negative control, run once at implementation time and then reverted: add a file
   carrying the identity and list it in `[rules] extra_exclude_files`; expect exit 1
   naming that file, line and column.
3. Negative control for the receipt guard: `touch press/press-receipt.toml && git add
   -f press/press-receipt.toml`; expect the workflow to fail with
   "press-receipt.toml committed in the template — it would disarm every fork's
   guard. Revert." Reverted immediately.
4. `cargo test --test press_source` — expect pass; and with `[[bin]] name`
   temporarily drifted, expect a failure naming the drifted target.
5. `uvx --from 'template-press==4.0.1' press check-tools --target .` — expect exit 0,
   proving every `argv[0]` in the declared `[[regenerate]]`/`[[edit]]` commands
   resolves on the runner before a real press is ever attempted.
6. Full-press rehearsal, once, off CI: `press rebrand --target "$TMP/fork"` with a
   throwaway identity, then `cargo build --workspace && cargo test --workspace` in
   the pressed copy — the runner-up lane, run manually as a one-time proof that the
   template really is pressable end to end, even though it is not wired into CI.

### Confidence & re-verify trigger

**High** that the recommended pattern is correct and implementable as specified: the
mechanism is owner-fixed, the two workflow files are read from py at the cited lines,
and the central claim — that `template-press` 4.0.1 verifies a Rust target with no
upstream change — was executed rather than argued (run A), together with all three
exit-code branches.

**High** that the discovery gap is real and correctly quantified: it is read directly
from `discovery.py:64-134` and `verify_config.py:34` and confirmed by the paired
runs E and F.

**Medium** on the rules-file contents: `press/press-rules.toml` is inherently
empirical — py's grew out of five dogfood runs — so the entries above are the
certain minimum and the real file will grow as `press verify` reports leaks. Medium
also on the identity values themselves, which are provisional until R49 lands.

**High** that non-text assets are in the rewrite inventory rather than skipped —
resolved empirically by run G, which listed `[replace] assets/logo.bin` in its plan
and changed the blob's bytes. **Medium-confidence caution** attached to that same
finding: the rewrite is length-changing and format-blind, so a real binary with
CRCs, offsets or length prefixes would be silently corrupted by a press while
`press verify` still exits 0. I did not test a real PNG/font/archive, so the size of
that hazard for rs's eventual asset set is **unmeasured**.

**Re-verify triggers.**

1. A new `template-press` major version (4.x → 5.x), or any release changing
   `discovery.py`, the default `[verify]` scan scope, or the rules schema — re-run
   the A/D/E/F matrix against the real repository before bumping the pin.
2. The moment rs gains a `macro_rules!`/proc-macro, an `include!`/`include_str!` with
   a computed path, or a multi-crate workspace with renamed member directories:
   re-open the runner-up decision, because those are exactly the constructs a leak
   scan cannot certify.
3. A Cargo discovery backend landing upstream: re-run the E case to confirm the
   guard has moved from 2-of-6 to 6-of-6, and retire the compensating test's
   redundant assertions if so.
4. The ts adoption project starting: the same 2-of-6 analysis applies there, and the
   two repos should share the compensating-control design.
5. Any real binary asset (PNG, ICO, font, archive) entering the template: press a
   copy and open the pressed asset, because the rewrite is length-changing and
   format-blind and the leak scan cannot see the corruption it would cause.
6. `template-press` going quiet (no push for 6 months) or its sole maintainer
   signalling otherwise: re-assess under the maintenance rubric — the bus factor is
   the one structural risk this recommendation carries.

### Sources

Primary artifacts (all retrieved 2026-09-09 unless stated):

- py `.github/workflows/press-verify.yml` (36 lines; lines 2-4, 10, 23-25, 31-36) —
  https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/main/.github/workflows/press-verify.yml
- py `.github/workflows/template-receipt-guard.yml` (28 lines; lines 1-6, 22-28) —
  https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/main/.github/workflows/template-receipt-guard.yml
- py `press/press-source.toml` and `press/press-rules.toml` (lines 11-12, 15-21,
  34-36, 43-47, 54-56, 118-120, 139) —
  https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/main/press/
- py `pyproject.toml:102` (`"template-press>=3.6.0"` in the dev group) and py
  `.gitignore` (no press/receipt/answers entries) —
  https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/main/
- py repository file inventory — `GET https://api.github.com/repos/smorinlabs/py-launch-blueprint/git/trees/main?recursive=1`
- `template-press` on PyPI (version 4.0.1, `requires_python >=3.13`, release history
  3.0.0 2026-07-17 → 4.0.1 2026-08-18, project description including the exit-code
  table and the `press-answers.toml` guidance) — `GET https://pypi.org/pypi/template-press/json`
- `template-press` design 0006 (external-target model) —
  https://raw.githubusercontent.com/smorinlabs/template-press/main/docs/design/0006-external-target-model.md
- `template-press` design 0007 (`press verify` design; §1, D1, D2, D5, §5.1, §5.3) —
  https://raw.githubusercontent.com/smorinlabs/template-press/main/docs/design/0007-press-verify-design.md
- `template-press` source: `rebrand/discovery.py` (lines 64-134),
  `rebrand/verify_cli.py` (lines 251-311, 454-455, 513-529),
  `rebrand/verify_config.py` (line 34, `DEFAULT_FIELDS`), `rebrand/rules.py`
  (lines 339, 344, 659-698), `rebrand/identity.py` (lines 33-127),
  `rebrand/check_tools.py`, `rebrand/sandbox.py` —
  https://raw.githubusercontent.com/smorinlabs/template-press/main/src/template_press/
- `template-press` CI OS matrix (`ubuntu`, `macos`, `windows` Blacksmith runners ×
  Python 3.13) —
  https://raw.githubusercontent.com/smorinlabs/template-press/main/.github/workflows/ci.yml
- `cargo-generate` `.github/workflows/e2e-test.yml` (weekly 3-OS generate-then-build) —
  https://raw.githubusercontent.com/cargo-generate/cargo-generate/main/.github/workflows/e2e-test.yml
- `rust-github/template` `.github/workflows/build.yml` and `template_values.toml`
  (generate → move to `runner.temp` → `cargo check --tests`, citing cargo#9922) —
  https://raw.githubusercontent.com/rust-github/template/main/.github/workflows/build.yml
- rust-lang/cargo issue #9922 — `GET https://api.github.com/repos/rust-lang/cargo/issues/9922`
- The Cargo Book, `cargo new` — https://doc.rust-lang.org/cargo/commands/cargo-new.html (HTTP 200)
- cargo-generate book — https://cargo-generate.github.io/cargo-generate/ (HTTP 200)
- GitHub docs, template repositories — https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository (HTTP 200)
- Repository context in this worktree: `docs/port/COMMONALITY.md:50` (F044),
  `docs/port/areas/ci-workflows.md:43`, `docs/port/DIVERGENCE-ANALYSIS.md:99`,
  `docs/port/OWNER-REVIEW.md:32,57`, `docs/port/COVERAGE.md:29,41-43,102,106`,
  `docs/port/PARAMETERS.md`, `research/CLAUDE.md` (R15 row).

Figure endpoints (retrieved 2026-09-09): `GET https://crates.io/api/v1/crates/<name>`
(`crate.recent_downloads`, `crate.downloads`) and `/versions` (newest
`yanked: false`) for `cargo-generate`, `kickstart`, `cargo-scaffold`,
`create-rust-app_cli`, `backpack`; `GET https://api.github.com/repos/<o>/<r>`
(`stargazers_count`, `archived`, `pushed_at`, `license`) and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`) for `cargo-generate/cargo-generate`,
`cargo-generate/cargo-generate-action`, `iomentum/cargo-scaffold`, `Keats/kickstart`,
`Wulf/create-rust-app`, `rust-github/template`, `esp-rs/esp-template`,
`esp-rs/esp-generate`, `smorinlabs/template-press`, `smorinlabs/py-launch-blueprint`.

**Method notes.** Every figure above came from `curl -sS` with a `User-Agent` header
against the endpoints named in the prompt's figure table — crates.io
(`/api/v1/crates/<name>` and `/versions`), the GitHub REST API (`/repos/<o>/<r>` and
`/search/issues`), `rustsec.org/packages/<name>.html`, plus PyPI's JSON API and
`api.osv.dev` for the one candidate that is not a crate. All were retrieved on
2026-09-09 (UTC). Beyond the figures I read primary source: py's two workflow files
and its press control files, and `template-press`'s design records 0006 and 0007 plus
seven of its source modules, all fetched from `raw.githubusercontent.com`. The
acceptance evidence was executed, not modelled: a synthetic Rust target built in a
scratch directory outside this worktree, pressed with `uvx --from
'template-press==4.0.1' press verify` to produce exits 0, 1 and 2, plus a prototype
`cargo metadata` cross-check and a `cargo generate-lockfile --offline` observation.

Could not verify, stated rather than filled in: **(a)** ts-launch-blueprint's own
files — `GET https://api.github.com/repos/smorinlabs/ts-launch-blueprint` returned
`404 Not Found` on 2026-09-09, so every claim about ts rests on this repository's
recorded evidence (`docs/port/areas/ci-workflows.md:43`,
`docs/port/DIVERGENCE-ANALYSIS.md:99`) rather than on the source repo, as the
prompt's evidence note anticipated. **(b)** `template-press`'s published
documentation site: `https://template-press.readthedocs.io/en/latest/` returned
**HTTP 404**, so the repository's design records were used instead. **(c)** The
consequences of the press's format-blind, length-changing rewrite of a *real* binary
asset (PNG/ICO/font/archive) — run G proved such files are rewritten, not skipped,
but I tested only a contrived blob, so the corruption hazard is identified and
unmeasured. **(d)** Issue
responsiveness (median days to first maintainer response over the 10 most recently
opened issues) — **inapplicable and not collected**: no crate is adopted by this
item, and the one tool adopted is the owner-fixed mechanism rather than a candidate
being selected on maintainer responsiveness; the maintenance rubric for it is stated
from release cadence, push recency and archive status instead, with the bus-factor-1
caveat made explicit. **(e)** Adopters via reverse dependencies — **inapplicable**:
`template-press` is a CLI invoked in CI, has no crates.io reverse-dependency page,
and its only public adopter is py-launch-blueprint, cited directly.
