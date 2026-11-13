# Raw research answer — R28 linter-and-editor-tooling (bundle, engine muse)

Engine: muse (Meta). Retrieval date for all live figures: 2026-09-26.
Local toolchain used for the executed checks: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` /
`cargo 1.98.1` / `clippy 0.1.98` / `rust-analyzer 1.94.0 (4a4ef493 2026-03-02)` on macOS aarch64.
Under `msrv-policy` (stable minus 2 minors) the floor today is therefore **1.96**.
No member of this bundle is a crates.io package — clippy and rust-analyzer ship as rustup
components, the VS Code extensions ship via the Marketplace (not a topic-named endpoint, not
queried) — so every crates.io figure row (`recent_downloads`, `downloads`, versions endpoint)
is recorded `inapplicable` per member with that reason, never silently omitted. Population
figures below come from the named `api.github.com` endpoints; advisory checks from the named
`rustsec.org` pages; behavior claims from executed local probes.

### Landscape

**Category this item decides.** The template's static-analysis gate and its editor surface:
one linter tool and its rule-selection mechanism, its autofix default, its per-context
relaxation for test code, its built-in security-rule coverage, and the recommended VS Code
extension set (lint/format, type-check, debugger) plus whether a version-pin settings file
is needed. It does **not** decide rustfmt's config (R27), non-Rust formatting (R29), the
type-checker engine or its CI/hook shape (R30), any standalone security scanner (R31), the
CI job shape (R11), or invocation syntax (R42).

**Three-bin map of the Rust field.**

| Bin | Members found | Why in this bin |
|---|---|---|
| Built-in / first-party toolchain | `clippy` 0.1.98 (rustup component, `rust-lang/rust-clippy`); `rustc` lints (`[lints.rust]`, e.g. `unsafe_code`); `rust-analyzer` 1.94.0 (rustup component, `rust-lang/rust-analyzer`); `[lints]` manifest tables + `clippy.toml`; `#[allow]` / `#[cfg_attr]` attributes | Shipped by the Rust project with every toolchain; no crate to select. `rustup component list --installed` on the probe host shows all three installed (executed 2026-09-26). |
| Established industry standard | CodeLLDB (`vadimcn/codelldb`, extension `vadimcn.vscode-lldb`) — the de-facto Rust debug adapter; the `rust-lang.rust-analyzer` VS Code extension — the official editing surface | Multi-year history, thousands of stars, pushed within weeks (figures under `##### Sources` of each member). |
| Up-and-comer | `marker` (rust-marker/marker, lint-framework for custom lints on stable); `dylint` (dynamic custom-lint loading) | Real projects, but both author *custom* lints rather than replace the default gate; neither was shortlisted as the template linter. No credible clippy replacement and no credible CodeLLDB replacement was found in this survey. |

**Authorities used, and why each is authoritative.**

1. The maintainers' own repositories at the named API endpoints — `rust-lang/rust-clippy`,
   `rust-lang/rust-analyzer`, `vadimcn/codelldb` (`GET https://api.github.com/repos/<o>/<r>`,
   2026-09-26). Authoritative as the projects' own standing and activity record.
2. The installed toolchain itself — `cargo clippy --version`, `rustup component list
   --installed`, `cargo clippy --help`, executed probes of `[lints.clippy]`, `clippy.toml`
   discovery, and `#[allow]` relaxation (2026-09-26). Authoritative because it is the exact
   behavior the template's gates will execute, not documentation prose.
3. `docs/port/DIVERGENCE-ANALYSIS.md` R28 rows (class B item, `harmonize: partly`; F093 class
   A `harmonize: yes`). Authoritative as the programme's recorded comparison scope.
4. The prompt's `## Context` evidence (py `Justfile:228`, `pyproject.toml:150` etc.; ts
   `Justfile:123`, `.oxlintrc.json:15` etc.) — accepted as cited, not re-read in this pass;
   every cross-repo claim below names the prompt citation it rests on.
5. `https://rustsec.org/packages/<name>.html` (named endpoint): `clippy` and `rust-analyzer`
   both return HTTP 404 = no advisory filed, consistent with neither being a crates.io
   package (2026-09-26).

What is *not* treated as authority: no blog post, no extension-marketplace install count
(Marketplace is not a named endpoint and was not queried — gap G2), and no doc-page prose
that was not executed (`doc.rust-lang.org` hosts are not named endpoints; the Cargo `[lints]`
reference and the Clippy book are cited below as background pointers, with every load-bearing
behavior verified by the local probe instead — gap G4).

**Well-regarded projects surveyed, with the evidence that they are well regarded.**
Named-adopter `Cargo.toml` manifests were not fetched (would need the rate-exhausted
`contents` API or non-named hosts — gap G3). Standing evidence therefore rests on the
toolchain-bundled fact plus repository standing, both strong: `rust-lang/rust-clippy`
13,535 stars, pushed 2026-09-24; `rust-lang/rust-analyzer` 16,876 stars, pushed 2026-09-26
(same day); `vadimcn/codelldb` 3,309 stars, pushed 2026-08-23; none archived (all
`archived: false`, 2026-09-26). A linter that ships inside every rustup toolchain and is
maintained by the Rust project needs no adopter list to establish dominance; the question
this bundle answers was always the config surface, exactly as the ledger's F085 note frames
it and the prompt directs.

**Fit over abstract best.** The template is a CLI + library + optional web service whose
precedent runs one linter through three identical surfaces (Justfile recipe, hook, CI job).
Candidates are judged on: in-manifest configuration a template can ship, a check-only gate
that composes with R11's `check` job, relaxation that fits Rust's module system rather than
file globs, and one editor extension replacing py's three (`ruff`, `pylance`) / ts's split
(`oxc` + built-in TS service) — not on abstract lint counts.

### Principles and implementation

**The shared requirement, its source and agreement level.** From `docs/port/COMMONALITY.md`
rows F085/F086/F093/F094/F096/F101/F109/F195/F196 and `docs/port/DIVERGENCE-ANALYSIS.md`
R28 rows (item class B `harmonize: partly`): the template ships **one dedicated linter,
configured in-repo, enforced through the same three surfaces** (Justfile recipe, commit
hook, CI job). Agreement level is **capability + policy**: every repo must be able to gate
on a configured, in-repo linter through those surfaces; the tool name, rule language and
editor wiring are ecosystem mechanics that may vary. The B-class tool difference
(ruff / oxlint / clippy) is therefore a justified native design in each repo, not drift —
each is that ecosystem's dominant instrument, and clippy is additionally not a choice at
all (it ships with the toolchain).

**Per-feature adjudication (cross-repo HIGH question).**

- *F085/F086/F094/F096/F101 (class B, harmonize: no — Rust decides).* The `categories` +
  `plugins`/`rules` model (ts) and the `lint.select` code-prefix model (py) are both
  "select rule sets in a config file"; Rust's native equivalent is clippy's lint groups
  (`all`, `pedantic`, `nursery`, `cargo`, `restriction`) selected in the `[lints.clippy]`
  manifest table, with threshold-style options in `clippy.toml`. Both files verified by
  execution (see `### Validation strategy`). Test relaxation likewise keeps the *policy*
  (tests linted more loosely) while changing the *mechanism*: py's `per-file-ignores` and
  ts's `overrides` globs exist because those tools select by file path; Rust's module
  system makes globs unnecessary — `#[allow(...)]` on `#[cfg(test)]` modules is the idiom,
  verified by execution. Security coverage keeps the ts *layering* (linter built-ins +
  CI-level SAST) rather than py's in-linter `S` bandit set, because clippy — like oxlint
  per D-014(5) — has security-*adjacent* lints but no bandit-equivalent suite.
- *F093 autofix default (class A setting drift, harmonize: yes — one value for all three
  repos).* Py defaults autofix on (`fix = true`); ts requires `--fix`; the analysis records
  "no D-0nn cited … no recorded reason for this specific policy split", i.e. accidental
  drift, not a justified difference. Recommended shared value: **lint surfaces are
  check-only by default; autofix is an explicit developer action.** Rationale supplied for
  the py/ts follow-on: a default that rewrites code makes CI and hooks non-deterministic
  and can mask the diff under review; clippy's `--fix` additionally "implies --no-deps and
  --all-targets" (`cargo clippy --help`, executed) and applies suggestions the author has
  not reviewed, so it stays behind an explicit flag/recipe like ts's `--fix`. No py/ts file
  is changed by this answer.
- *F109 type-checker extension (class E, harmonize: no — mirror ts, not py).* Py needs
  Pylance because its checker is IDE-only; ts needs nothing because the language service
  is built into the editor. Rust matches ts: rust-analyzer *is* the language service and
  surfaces type diagnostics in the editor, so no second extension is recommended.
- *F195 debugger (class B, harmonize: no — presumption of reuse).* F194 settles the
  committed-`launch.json` pattern; only the debug adapter is language-bound. Rust's is
  CodeLLDB (`"type": "lldb"`), which needs no platform split on this repo's
  `ubuntu-latest, macos-latest` matrix.
- *F196 settings pin (class C, harmonize: no — collapses).* The ts pin exists only because
  the TS engine resolves from `node_modules`; rust-analyzer resolves the toolchain via
  `rust-toolchain.toml`, so there is no equivalent pin to set: no `.vscode/settings.json`
  for this purpose.

**Essential behaviors and observable acceptance criteria.**

1. `cargo clippy --all-targets` fails the gate on a correctness/style regression and
   modifies no file (check-only default). *Executed:* probe emits deny-level errors on
   deliberate violations and `Finished` clean after the fix, with no source rewrite.
2. Rule selection lives in `Cargo.toml` `[lints.clippy]` (+ optional `clippy.toml`); a
   group/member mix carries explicit `priority` keys. *Executed:* the no-priority mix is a
   manifest error (`lint group 'all' has the same priority (0) as a lint`); the priority
   form passes.
3. Test modules relax via `#[allow]` attributes; no glob config exists. *Executed:* sloppy
   test code under `#[allow(clippy::all, clippy::pedantic)]` passes while the same
   violations outside would fail.
4. `clippy.toml` is discovered from the project root; unknown keys are a hard error, so
   typos cannot silently disable configuration. *Executed:* bogus key errors listing valid
   keys.
5. The editor surfaces lint, format and type diagnostics through the one
   `rust-lang.rust-analyzer` extension, and debugging through `vadimcn.vscode-lldb`.
   *Not executed* (no VS Code on the probe host — planned check under `### Validation
   strategy`).

**Architectural alternatives compared before any tool was weighed.**

| Alternative | Shape | Verdict |
|---|---|---|
| A. rustup-component linter (clippy) + manifest selection | `cargo clippy` + `[lints.clippy]` + `clippy.toml` | **Chosen.** Zero install step, versions with the toolchain, in-manifest config the template can ship. |
| B. Third-party linter crate as the gate | any non-clippy Rust linter | Rejected. The survey found no credible clippy replacement (up-and-comers `marker`/`dylint` author custom lints; they are not gates). The prompt's near-certain baseline is confirmed. |
| C. `rustc` lints only, no clippy | `[lints.rust]` alone | Rejected. Keeps `unsafe_code = "forbid"`-class guarantees but drops every style/complexity/correctness lint clippy adds; strictly less coverage for the same invocation cost. |
| D. rust-analyzer + a separate clippy extension | two lint extensions | Rejected. rust-analyzer already surfaces `cargo check`/clippy diagnostics; no maintained clippy-specific extension fills a gap. |
| E. rust-analyzer's (nonexistent) bundled debugging | no debug extension | Rejected. rust-analyzer ships no debug adapter; the maintained native adapter is CodeLLDB. |

No `BASELINE-REVIEW:` finding: the clippy-near-certain baseline is confirmed, not
challenged, and no ledger row is disputed. No ledger change is proposed.

**Minimal realistic example.** A library crate whose `Cargo.toml` carries
`[lints.rust] unsafe_code = "forbid"` and `[lints.clippy] all = deny / pedantic = warn`
(priority form where mixed with per-lint overrides), a `clippy.toml` with one threshold
key, `#[allow]`-scoped `#[cfg(test)]` modules, `.vscode/extensions.json` recommending the
two extensions, and a `launch.json` with an `"type": "lldb"` config. The probe in
`### Validation strategy` executes the clippy half; the editor half is a planned check.

### Recommendation

One stack: `clippy` (rustup component, version = the pinned toolchain) invoked as
`cargo clippy --all-targets` (check-only; `--fix` stays an explicit separate action),
configured by `[lints.clippy]` in `Cargo.toml` (`all = "deny"`, `pedantic = "warn"`,
`undocumented_unsafe_blocks = "warn"`, priority keys wherever a group and a member mix)
plus a committed `clippy.toml` for threshold-style options; test relaxation via
`#[allow(...)]` on `#[cfg(test)]` modules (no glob mechanism); security posture =
clippy's built-in security-adjacent lints with the residual bandit-gap covered by a
CI-level SAST layer (noted, not decided here; standalone-scanner adoption is R31's);
editor = `rust-lang.rust-analyzer` alone for lint/format/type-check plus
`vadimcn.vscode-lldb` for debugging; no `.vscode/settings.json` toolchain pin
(`rust-toolchain.toml` already resolves the toolchain).

### Members

#### clippy (linter tool + rule selection)

##### Landscape
Category: the Rust linter and its rule-selection surface. Same three bins as the
top-level map; the candidates in this member's scope are clippy (built-in), rustc-lints-only
(built-in subset), and a hypothetical third-party gate (none found — the up-and-comer bin
holds only custom-lint frameworks `marker`/`dylint`, which extend rather than replace the
gate). Every selection below comes from that map.
##### Principles and implementation
Shared principle (F085/F086, class B): rule selection is declared in a committed config
file using the ecosystem's native grouping. Py selects by code prefix, ts by
`categories`+`plugins`/`rules`; Rust's native grouping is clippy's lint groups chosen in
`[lints.clippy]`, with per-lint threshold/allow-list options in `clippy.toml`. The probe
executed both halves: a `[lints.clippy]` table with `all`/`pedantic` groups plus a per-lint
override, and a `clippy.toml` whose bogus key is a hard error (proving discovery) and whose
`too-many-arguments-threshold` is accepted silently. `[lints]` tables require a toolchain
with manifest-lint support (stable since 1.74 per the Rust release history — background
reference, gap G4); the 1.96 floor holds trivially.
##### Dominant choice
`clippy` 0.1.98 as the rustup component, invoked `cargo clippy`, configured by
`[lints.clippy]` + `clippy.toml`. Standing (named endpoints, 2026-09-26):
`GET https://api.github.com/repos/rust-lang/rust-clippy` → stars 13,535, `archived:
false`, `pushed_at` 2026-09-24T14:26:18Z, reported SPDX Apache-2.0;
`GET https://api.github.com/search/issues?q=repo:rust-lang/rust-clippy+is:issue+is:open`
→ `total_count` 2,506 (never `open_issues_count`); `https://rustsec.org/packages/clippy.html`
→ HTTP 404 (no advisory filed; not a crates.io package). Maintenance state: active
(pushed 2 days ago, ships with every stable toolchain).
##### Qualified shortlist
One qualifies; fewer is a finding, as the prompt anticipates ("do not spend significant
budget surveying alternatives"):
- `clippy` (rustup component) · the gate + its config surface · stars 13,535 ·
  pushed 2026-09-24 · active · notable standing: maintained by the Rust project, installed
  with every rustup toolchain (executed: present in `rustup component list --installed`) ·
  trade-off: versions with the toolchain rather than semver, so lint evolution is coupled
  to toolchain bumps (accepted: the template already pins the toolchain).
##### Excluded by gate
`rustc`-lints-only is not gate-excluded but is not shortlisted: it passes every applicable
fitness gate yet is strictly less capable than clippy for the same invocation cost (it is a
subset, not an alternative). No third-party candidate reached gate evaluation because none
was found. Per-gate record for clippy: (1) license pass (Apache-2.0 as reported, compatible
with `MIT OR Apache-2.0`); (2) MSRV inapplicable — ships with the toolchain, no
`rust-version` of its own; requires only that the pinned toolchain supports `[lints]`
tables, true at the 1.96 floor; (3) advisories: rustsec 404, none filed; `unsafe` posture
inapplicable — not linked into the template; (4) OS pass — rustup ships the component for
every target including ubuntu/macos runners (executed: installed on macOS aarch64);
(5) features/async-runtime inapplicable — a compiler driver, not a library; (6) cost: one
additional check pass over the compile, zero runtime or binary-size cost.
##### Up-and-comers
`marker` and `dylint`: custom-lint authoring frameworks, evaluated and set aside — neither
offers a maintained default lint set that could gate the template. No up-and-coming
replacement gate exists in this survey.
##### Fit for this template
CLI: direct — `cargo clippy --all-targets` gates bins, lib, tests and examples in one
invocation (executed). Library: direct — `[lints.clippy]` + `clippy.toml` ship in the
crate, so consumers of the template inherit the gate by copying the manifest. Web: direct
— same invocation covers the web member; no per-target config needed. Template ergonomics:
`[lints.rust] unsafe_code = "forbid"` rides in the same table, giving the R06-adjacent
unsafe posture a one-line enforcement point.
##### Recommendation
Adopt clippy via the pinned toolchain with this manifest shape (executed end to end on
1.98.1): `[lints.rust] unsafe_code = "forbid"`; `[lints.clippy] all = { level = "deny",
priority = -1 }`, `pedantic = { level = "warn", priority = -1 }`,
`undocumented_unsafe_blocks = "warn"`; plus a committed `clippy.toml` for threshold-style
options. Groups without per-lint mixing need no `priority` keys; wherever a group and a
member mix, the priority form is mandatory (the bare mix is a manifest error — executed).
`nursery`/`cargo`/`restriction` stay off except for named opt-ins.
##### Ranked runner-up
None. There is no second credible gate; the only fallback is `rustc` lints alone, which is
a degraded subset rather than a runner-up. If clippy were ever uninstallable from the
pinned toolchain (no evidence this can happen on stable), the gate would degrade to
`cargo check` + `[lints.rust]` with a recorded loss of coverage.
##### Tradeoffs
What the pick gives up versus a hypothetical versioned linter crate: independent semver —
clippy's lint set evolves with the toolchain, so a toolchain bump can introduce new
deny-level failures. Accepted because the template pins its toolchain (so bumps are deliberate
PRs, surfacing new lints as reviewable diffs) and because no versioned alternative exists.
What it gives up versus `nursery`/`restriction` maximalism: ultimate strictness — accepted
because nursery lints are explicitly experimental and restriction lints (e.g. banning
`unwrap` in tests) fight normal template code; named opt-ins recover the valuable ones.
##### Parameters
No owned parameters (this item owns none per `## Couplings`). Assumes
`package-manager-invocation` (invocation spelling owned by R42; this member requires only
that the recipe can spell `cargo clippy` — satisfied by the recorded value's
cargo-subcommand rule).
##### Migration implications
`Cargo.toml`: add the `[lints.rust]` + `[lints.clippy]` tables (priority form where group
and member mix). Add a committed `clippy.toml` (starts with threshold keys in use; may
start minimal). Justfile: `lint` recipe runs `cargo clippy --all-targets` check-only (exact
spelling per R42's recorded value). CI: a clippy step inside R11's `check` job (placement
owned by R11; this member supplies only the command and its exit-code contract).
##### Validation strategy
Executed 2026-09-26 on the probe crate (`/tmp/r28probe`, since removed; recipe
reproducible): (1) bare group+member mix → manifest error naming the priority conflict;
(2) priority form + clean code → `Finished`, exit 0; (3) deliberate `clone_on_copy` /
`let_and_return` violations → deny-level errors, nonzero exit; (4) `clippy.toml` with a
bogus key → hard error listing valid keys (discovery proven); with a real key → silent
accept. Planned (not executed): run the same manifest shape on ubuntu-latest + macos-latest
in CI (gate 4's second leg; the macOS leg is executed here).
##### Confidence & re-verify trigger
High. The tool is uncontested and the config surface is executed, not cited. Re-verify if:
the `[lints]` table syntax changes in a future stable; clippy renames a recommended group
or lint (check the toolchain-bump PR that surfaces it); or 2027-03-26 passes without
reviewing whether newly stabilized lints warrant promotion into the table.
##### Sources
- Repo: `GET https://api.github.com/repos/rust-lang/rust-clippy` (stars 13535, archived
  false, pushed 2026-09-24T14:26:18Z, license Apache-2.0, 2026-09-26)
- Open issues: `GET
  https://api.github.com/search/issues?q=repo:rust-lang/rust-clippy+is:issue+is:open`
  (total_count 2506, 2026-09-26)
- Advisories: `https://rustsec.org/packages/clippy.html` (HTTP 404 = no advisory filed,
  2026-09-26)
- Executed: `cargo clippy --version` (clippy 0.1.98), `rustup component list --installed`
  (clippy present), probe runs (1)–(4) above on rustc/cargo 1.98.1
- Background (not fetched, gap G4): `[lints]` manifest reference and Clippy book lint
  list; group names cross-checked by probe acceptance of `all`/`pedantic` plus the
  `clippy.toml` valid-keys error output

#### autofix-default-policy (check-only default; --fix opt-in)

##### Landscape
Category: whether the linter's autofix applies by default or behind an explicit flag. This
is a policy member, not a tool: the field is the two observed policies (py `fix = true`
vs ts `--fix` opt-in) plus clippy's native behavior. No crate figures apply to any policy
candidate (inapplicable — policies have no registry entries).
##### Principles and implementation
Shared principle (F093, class A, `harmonize: yes`): a lint surface must be deterministic
under CI and hooks — the same tree always yields the same verdict and the tool never
rewrites code unless asked. Both source repos share the check-only *gate*; they differ only
in the developer-facing default, with no recorded reason. Clippy's native behavior matches
ts: plain `cargo clippy` emits diagnostics and exits nonzero without touching sources
(executed — probe files byte-identical after the run), while `--fix` ("Automatically apply
lint suggestions. This flag implies --no-deps and --all-targets", `cargo clippy --help`,
executed) is the explicit opt-in. Adopting clippy's native default therefore both follows
fit-over-abstract-best and resolves the py/ts drift toward the check-only value.
##### Dominant choice
Check-only default with explicit `--fix`: the `lint` recipe and every automated surface
run plain `cargo clippy` (diagnostics + exit code, no rewrites); developers run
`cargo clippy --fix` (or a separate `lint-fix` recipe) as a deliberate action whose diff
they review.
##### Qualified shortlist
- Check-only default + explicit `--fix` · matches clippy's native behavior and ts's
  recorded policy · zero implementation cost (the default needs no flag) · trade-off:
  developers must learn the second command (accepted: one documented recipe).
##### Excluded by gate
Default-on autofix (py's `fix = true` analogue, e.g. a `lint` recipe that always passes
`--fix`, or `--fix` in hooks/CI): excluded by design fit, not by numbered gate — every
numbered gate is inapplicable to a policy (no license/MSRV/advisory/OS/feature/size
surface). It is rejected because (a) hooks/CI that rewrite sources are non-deterministic
and can mask the diff under review, (b) `--fix` implies `--all-targets`/`--no-deps`,
widening what a "quick lint" touches, and (c) applied suggestions bypass review by
construction. Recorded here rather than silently dropped.
##### Up-and-comers
None — this is a two-policy field with no emerging third option.
##### Fit for this template
CLI/library/web: uniform — one check-only invocation gates all targets in all members
(executed with `--all-targets`). Composes with R11's `check` job (a step that fails the
job on diagnostics) and with R42's invocation spelling (no provisioner prefix either way).
The explicit `--fix` path gives template users the py-style convenience without making it
the default.
##### Recommendation
Ship check-only as the only automated behavior: `lint` recipe = `cargo clippy
--all-targets` with no `--fix`; document `cargo clippy --fix` as the explicit developer
action (optionally as a second recipe). Never pass `--fix` in hooks or CI.
##### Ranked runner-up
A `lint-fix` convenience recipe that runs `cargo clippy --fix` on demand. It wins only as
an addition to, never a replacement of, the check-only default — it is the sanctioned
shape of the explicit action, not a competing default.
##### Tradeoffs
What check-only gives up versus default-on: one-step "lint and repair" convenience —
accepted because the repair diff deserves review, and the runner-up recipe recovers most
of the convenience. What it gives up versus py parity: none at the gate level (py's CI
also gates on the diagnostic verdict); the follow-on py change (if the owner takes it) is
confined to the developer-facing default.
##### Parameters
No owned parameters. Assumes `package-manager-invocation` (recipe spelling owned by R42)
and `ci-job-structure` (whether the gate is a step or a job owned by R11); this member
constrains only the flags, not the placement.
##### Migration implications
Justfile: `lint` recipe without `--fix`; optional second recipe with `--fix` for explicit
use. Hook config: the lint hook invokes the check-only recipe. CI: the clippy step passes
no `--fix` flag. No manifest or config-file change (the default needs no declaration).
##### Validation strategy
Executed 2026-09-26: probe run of plain `cargo clippy --all-targets` over violating code
exited nonzero and left sources byte-identical (check-only proven); `cargo clippy --help`
confirms `--fix` exists as an explicit flag. Planned (not executed): a template-level test
asserting the `lint` recipe text contains no `--fix` and that running it twice yields
identical trees.
##### Confidence & re-verify trigger
High. The behavior is executed and the cross-repo adjudication follows the recorded
(no-reason) drift analysis. Re-verify if: clippy changes its `--fix` semantics in a future
stable (watch toolchain-bump changelogs); or the owner dispositions the F093 follow-on for
py/ts differently (this answer's rs value stands regardless).
##### Sources
- Executed: `cargo clippy --help` (`--fix` flag text, 2026-09-26); probe check-only run
  (nonzero exit, byte-identical sources, 2026-09-26)
- Recorded: `docs/port/DIVERGENCE-ANALYSIS.md` R28/F093 sub-row (class A, "no recorded
  reason for this specific policy split", harmonize yes); prompt `## Context` py/ts
  evidence (`pyproject.toml:177`, ts `Justfile:130`)

#### test-lint-relaxation (allow-attributes on test modules)

##### Landscape
Category: the per-context relaxation mechanism for test code. Candidates: Rust's
`#[allow(...)]` / `#[cfg_attr(test, allow(...))]` attributes (built-in); a hypothetical
path-scoped `[lints]` override (does not exist in Cargo — no glob analogue of
`per-file-ignores`/`overrides`); CLI `-A` flags (global, not per-context). No crate figures
apply (inapplicable — language mechanisms, not packages).
##### Principles and implementation
Shared principle (F094, class B): test code is linted more loosely than production code,
and the relaxation is declared next to the code it covers. Py declares it centrally by
path (`per-file-ignores` for `"tests/*"`); ts declares it centrally by glob (`overrides`
for `tests/**`); both central forms exist because those tools select by file. Rust's module
system makes the file indirection unnecessary: `#[cfg(test)] #[allow(clippy::all,
clippy::pedantic)] mod ...` scopes the relaxation to exactly the test module, travels with
the code if the file moves, and needs no path list to keep in sync. Executed: deliberately
sloppy test code (`clone` on `Copy`, `assert!(true)`) passes under the attribute while the
gate stays deny-level elsewhere. `#[cfg_attr(test, allow(...))]` covers the inline
`#[cfg(test)] mod tests` inside production files — the same one-line shape.
##### Dominant choice
`#[allow(...)]` attributes on `#[cfg(test)]` modules (whole-module `allow(clippy::all,
clippy::pedantic)` for test-support modules; narrower per-item allows where only one rule
chafes), with `#[cfg_attr(test, allow(...))]` for inline test modules.
##### Qualified shortlist
- `#[allow]` on test modules · zero config files, travels with the code, finest scope ·
  trade-off: each test module carries its own attribute (accepted: explicit and greppable).
- `#[cfg_attr(test, allow(...))]` on inline test modules · same mechanism, covers the
  `mod tests` inside `src/` files · trade-off: none material; it is the same idiom.
##### Excluded by gate
Path-scoped `[lints]` overrides: excluded by existence, not by numbered gate (all six gates
inapplicable — mechanisms, not packages): Cargo offers no per-path lint table, so there is
nothing to adopt. CLI `-A` flags: excluded by fit — global to the invocation, they would
relax production code too, violating the per-context policy. Both recorded here rather
than silently dropped.
##### Up-and-comers
None — the attribute mechanism is stable and complete for this purpose.
##### Fit for this template
CLI/library/web: uniform — unit tests live in `#[cfg(test)]` modules in every member and
integration tests in `tests/` dirs whose files are each a crate root (attributes apply at
the top of the file identically). No coordination with R27's formatter excludes is needed
beyond noting the asymmetry: formatting excludes are path-based (R27's call), lint
relaxation is module-based (this member) — F100's exclude-scope question therefore concerns
only the formatter side.
##### Recommendation
Relax test lints with `#[allow(clippy::all, clippy::pedantic)]` (or narrower) on
`#[cfg(test)]` modules and `#[cfg_attr(test, allow(...))]` on inline test modules. Ship no
glob config for lint relaxation; document that none exists and none is needed.
##### Ranked runner-up
Per-item `#[allow(clippy::specific_lint)]` at the exact expression that needs it. It wins
where a test module is mostly clean and one line chafes; it loses as the default because
test-support code (builders, fixtures) trips many style lints at once and item-level allows
would drown it.
##### Tradeoffs
What attributes give up versus central globs: one-place auditability of "which paths are
relaxed" — accepted because `grep -rn 'cfg(test)' --include='*.rs' -A1 | grep allow`
recovers the list, and because attributes cannot drift out of sync with moved files while
globs can. What whole-module allow gives up versus per-item allow: precision — mitigated by
recommending the narrow form where it suffices.
##### Parameters
No owned parameters. No consumed-parameter interaction (pure source-code idiom; no
recipe, job, or manifest coupling).
##### Migration implications
Source files only: each `#[cfg(test)]` module gains its `#[allow]` line; no `Cargo.toml`,
hook, CI, or config-file change. Template documentation shows the two-line shape once.
##### Validation strategy
Executed 2026-09-26: probe `#[cfg(test)]` module with `#[allow(clippy::all,
clippy::pedantic)]` containing `clone`-on-`Copy` and `assert!(true)` passes `cargo clippy
--all-targets` with the workspace gate at deny/warn; the pre-attribute run failed on the
same violations (negative control from the first probe iteration). Planned (not executed):
a template hygiene test grepping that every `#[cfg(test)]` module carries an explicit
allow or a comment stating none is needed.
##### Confidence & re-verify trigger
High. Executed both directions (fails without, passes with). Re-verify if: Cargo ever
ships path-scoped lint tables (reassess whether central config beats attributes — unlikely
to win); or clippy introduces a test-specific lint group (adopt the group name into the
attribute).
##### Sources
- Executed: probe runs with and without the attribute on rustc/cargo 1.98.1 (2026-09-26)
- Recorded: prompt `## Context` py/ts evidence (`pyproject.toml:195`,
  `.oxlintrc.json:52`); D-014(4) structural-equivalence note for ts `overrides`

#### linter-security-coverage (clippy built-ins + SAST layering note)

##### Landscape
Category: what security coverage the linter itself provides. Candidates: clippy's built-in
security-adjacent lints (built-in); py-style in-linter bandit suite (no Rust analogue);
CI-level SAST workflow (established practice, engine owned elsewhere — R16/R31). No crate
figures apply (inapplicable — lint subsets and noted-not-decided workflows, not packages).
##### Principles and implementation
Shared principle (F096, class B): the linter catches the security-adjacent mistakes it can
see cheaply, and the residual gap is covered one layer up, not pretended away. Py covers
the gap inside the linter (`"S"` bandit set); ts covers it by layering (oxlint built-ins
like `no-eval` plus a CI CodeQL workflow, per D-014(5), which explicitly records that no
bandit-equivalent exists). Rust matches ts, not py: clippy ships security-adjacent lints
(`undocumented_unsafe_blocks`, `missing_safety_doc`, the configurable `disallowed_*`
family for banning dangerous APIs, `unwrap_used`/`expect_used`-class restriction lints for
panic-surface control) but no taint tracking, secret detection, or weak-crypto suite — no
bandit analogue. The residual gap is therefore noted as covered by a CI-level SAST layer,
exactly as ts does; whether a *standalone* AST scanner is additionally adopted is R31's
decision (F114/F115), explicitly not taken here.
##### Dominant choice
Clippy built-ins at the gate (`undocumented_unsafe_blocks = "warn"` in `[lints.clippy]`,
`missing_safety_doc` via `pedantic = "warn"`, `disallowed-methods` entries in `clippy.toml`
where the template bans an API) plus a recorded expectation that CI-level SAST covers the
residual bandit-gap (workflow existence and engine owned by R16/R31, not this item).
##### Qualified shortlist
- Clippy built-ins + noted SAST layer · matches the ts precedent structurally; zero new
  tools in this item · trade-off: the SAST layer is a cross-item expectation, not a
  decision (accepted: deciding it here would trespass on R16/R31).
##### Excluded by gate
A py-style in-linter bandit-equivalent suite: excluded by existence (all six gates
inapplicable — no such suite exists for Rust, per the same D-014(5)-style finding for the
Rust field). Adopting a standalone scanner inside this item: excluded by scope (R31 owns
F114/F115; this member decides only clippy's own coverage per `## Out of scope`). Both
recorded here rather than silently dropped.
##### Up-and-comers
None in the linter-built-in space. Scanner-side movement belongs to R31's survey, not this
member's.
##### Fit for this template
CLI/library/web: uniform — the recommended lints are crate-agnostic (`unsafe`-adjacency
matters most in the library crate; `disallowed_*` can ban e.g. blocking-IO APIs in the web
member, configured per-member in each `clippy.toml` or workspace-root file). The SAST
expectation composes with R11's job structure (a non-compiling scan fits a non-compile
job) without this member placing it.
##### Recommendation
Enable the security-adjacent clippy lints named above at warn-or-higher in the template's
`[lints.clippy]`; use `clippy.toml` `disallowed-methods` where the template bans a specific
API; record (in the decision, not as a second tool) that residual SAST coverage rides a
CI-level workflow whose engine R16/R31 decide.
##### Ranked runner-up
`pedantic`-only coverage with no named security opt-ins (i.e. dropping
`undocumented_unsafe_blocks`). It wins only if the template forbids `unsafe` outright so
thoroughly that the lint never fires — but `[lints.rust] unsafe_code = "forbid"` already
covers that case, and the warn-level lint is free insurance where `unsafe` is locally
allowed. Kept as runner-up, not the pick.
##### Tradeoffs
What built-ins-only gives up versus py's bandit suite: taint/secret/crypto coverage at the
lint tier — accepted because no Rust linter offers it and the SAST layer (per ts precedent)
is the honest place for it. What noting-but-not-deciding SAST gives up: decisional closure
— accepted because closure belongs to R16/R31 and premature closure here would conflict.
##### Parameters
No owned parameters. No consumed-parameter interaction beyond the shared gate placement
(clippy command and flags, already covered by the `clippy` and `autofix-default-policy`
members).
##### Migration implications
`Cargo.toml`: the two named lint levels inside the existing `[lints.clippy]` table (no new
file). `clippy.toml`: `disallowed-methods` entries if the template bans any API (starts
empty or with an example entry). No hook/CI change in this member (the SAST workflow is
another item's file).
##### Validation strategy
Planned (not executed — the probe exercised the table mechanics, not these specific lints):
(1) add an undocumented `unsafe` block to the probe and assert `undocumented_unsafe_blocks`
warns; (2) add a `disallowed-methods` entry and assert its use warns; (3) assert the
decision text names the SAST expectation and the R31 deferral. The table/priority mechanics
those checks rely on are executed (see the `clippy` member).
##### Confidence & re-verify trigger
Medium-high. The clippy-side recommendation is executed-mechanics-backed; the SAST-layer
expectation is precedent-backed (D-014(5)) but its Rust realization is genuinely another
item's call. Re-verify if: R31 adopts a standalone scanner (narrow or restate the SAST
expectation to avoid double coverage claims); clippy stabilizes new security-group lints
(promote them into the table); or 2027-03-26 passes without that review.
##### Sources
- Executed: `[lints.clippy]` + `clippy.toml` mechanics (see `clippy` member — same
  machinery, 2026-09-26)
- Recorded: prompt `## Context` py/ts evidence (`pyproject.toml:161`,
  `.oxlintrc.json:35`); D-014(5) bandit-gap finding; `## Out of scope` R31 boundary
  (F114/F115)

#### rust-analyzer-vscode (editor extension for lint/format/type-check)

##### Landscape
Category: the VS Code extension covering lint, format, and type diagnostics. Candidates:
the official `rust-lang.rust-analyzer` extension (first-party — developed in
`rust-lang/rust-analyzer` itself); a separate clippy-specific extension (no maintained,
needed candidate found); no extension (rust-analyzer via rustup CLI only — loses in-editor
diagnostics). Marketplace figures inapplicable (not a named endpoint — gap G2); standing
rests on the repo figures plus first-party status.
##### Principles and implementation
Shared principle (F101/F109, classes B/E): the editor surfaces the same checks CI runs,
through the fewest extensions that cover them. Py needs two (`ruff` for lint/format,
`pylance` for the IDE-only checker); ts needs one plus a builtin (`oxc` + the built-in TS
service). Rust needs one: the official rust-analyzer extension drives editing, runs
`cargo check` (diagnostics incl. type errors) on save, formats via rustfmt, and can run
clippy as its check command — replacing all three source-repo extensions with a single
recommendation. The extension and the rustup `rust-analyzer` component are the same
project (executed: component version 1.94.0 installed locally), so editor and CLI cannot
drift the way py's ruff-vs-pylance split can.
##### Dominant choice
`rust-lang.rust-analyzer` (official extension, developed in `rust-lang/rust-analyzer`,
`editors/vscode`). Standing (named endpoints, 2026-09-26):
`GET https://api.github.com/repos/rust-lang/rust-analyzer` → stars 16,876, `archived:
false`, `pushed_at` 2026-09-26T10:35:50Z (same day), reported SPDX Apache-2.0;
`GET https://api.github.com/search/issues?q=repo:rust-lang/rust-analyzer+is:issue+is:open`
→ `total_count` 1,695; `https://rustsec.org/packages/rust-analyzer.html` → HTTP 404 (no
advisory filed; not a crates.io package). Recent window (10 most recently created items,
2026-09-20 → 2026-09-26): 3 issues (two <1 day old with 0 comments, one 2 days old with 1
comment) + 7 PRs with 0–4 comments — too thin and PR-mixed for a maintainer-response
median; consistent with same-day-active maintenance, recorded as observed, not as a
verdict. Maintenance state: active.
##### Qualified shortlist
- `rust-lang.rust-analyzer` · lint + format + type diagnostics in one official extension ·
  stars 16,876 · pushed same-day · active · notable standing: the Rust project's own
  language server, installed as a rustup component (executed) · trade-off: none material
  within its scope (debugging is out of scope — see the `codelldb` member).
##### Excluded by gate
A separate clippy-specific extension: excluded by need, not by numbered gate (all six gates
inapplicable to extensions except license/OS, both of which any candidate would pass):
rust-analyzer already surfaces clippy diagnostics via its check command, so a second
extension would duplicate the signal. No-extension (CLI-only rust-analyzer): excluded by
fit — it abandons in-editor diagnostics, the capability F101/F109 exist to provide. Both
recorded here rather than silently dropped. Per-gate record for the pick: (1) license pass
(Apache-2.0 as reported, compatible); (2) MSRV inapplicable — editor extension, not
compiled into the template; (3) advisories: rustsec 404; `unsafe` inapplicable — not
linked; (4) OS pass — the extension host is platform-independent and the project ships
server binaries for all Tier-1 targets incl. linux/macOS (release-matrix detail not
fetched — gap G2/G3); (5) features/async inapplicable — not a Rust library dependency;
(6) size/compile cost: zero template cost (editor-side only; the `cargo check` it runs is
the same check CI runs).
##### Up-and-comers
None. No competing Rust language server is credible for a template recommendation; Zed's
bundled Rust support is an editor choice, not a VS Code extension candidate, and this item
does not pick editors.
##### Fit for this template
CLI/library/web: uniform — one extension recommendation covers every member because
rust-analyzer operates at the workspace level. It composes with R27 (rustfmt as the format
backend — config owned there) and R30 (the `cargo check`-based diagnostics it surfaces are
the same command family R30's gate uses — engine owned there). `.vscode/extensions.json`
carries IDs only (VS Code recommendations are unversioned by design), so no version pin is
possible or needed.
##### Recommendation
Recommend `rust-lang.rust-analyzer` in `.vscode/extensions.json` as the sole lint/format/
type-check extension. Recommend no clippy-specific extension. Set no extension version
(the recommendations file has no version field).
##### Ranked runner-up
None within VS Code. If the template ever documented a second editor, that editor's
rust-analyzer client would be the parallel pick — out of scope for this item, which follows
the source repos' VS Code surface.
##### Tradeoffs
What one extension gives up versus py's two: nothing — the split existed because py's
checker is IDE-only while its linter is not; rust-analyzer unifies both roles. What it
gives up versus ts's zero-extension type story: one install — unavoidable, since VS Code
ships no Rust service builtin; the `extensions.json` recommendation makes it one click.
##### Parameters
No owned parameters. Assumes `package-manager-invocation` only insofar as the extension
runs bare `cargo` commands (consistent with R42's recorded value — no provisioner prefix
for rustup components).
##### Migration implications
`.vscode/extensions.json`: add `rust-lang.rust-analyzer` to `recommendations` (alongside
the debugger entry below; unrelated existing recommendations untouched). No
`.vscode/settings.json` change for this member (see the `editor-settings-pin` member: no
pin). No manifest, hook, or CI change.
##### Validation strategy
Planned (not executed — no VS Code on the probe host): (1) open the template in VS Code
with only the recommended extensions, assert the extension activates on a `.rs` file and
that an intentional type error plus a clippy warning both surface as editor diagnostics;
(2) assert `extensions.json` parses and contains exactly the recommended IDs. Executed
support: the rustup-side `rust-analyzer 1.94.0` binary runs (`--version`, 2026-09-26), so
the language server the extension drives is present in the toolchain.
##### Confidence & re-verify trigger
High on the extension pick (official, same-day-active, uncontested); medium on the
unexecuted editor-surface assertions. Re-verify if: the project renames the extension ID
(breaks `extensions.json`); the extension splits diagnostics into a second required
install; or 2027-03-26 passes without re-checking the recommendation list.
##### Sources
- Repo: `GET https://api.github.com/repos/rust-lang/rust-analyzer` (stars 16876, archived
  false, pushed 2026-09-26T10:35:50Z, license Apache-2.0, 2026-09-26)
- Open issues: `GET
  https://api.github.com/search/issues?q=repo:rust-lang/rust-analyzer+is:issue+is:open`
  (total_count 1695, 2026-09-26)
- Recent window: `GET
  https://api.github.com/repos/rust-lang/rust-analyzer/issues?state=open&sort=created&direction=desc&per_page=10`
  (3 issues + 7 PRs, 2026-09-20 → 2026-09-26, 2026-09-26)
- Advisories: `https://rustsec.org/packages/rust-analyzer.html` (HTTP 404 = no advisory
  filed, 2026-09-26)
- Executed: `rust-analyzer --version` (1.94.0), `rustup component list --installed`
  (rust-analyzer present, 2026-09-26)
- Gaps: Marketplace install counts / publisher badge not queried (G2); per-platform
  server-binary matrix not fetched (G2/G3)

#### codelldb-debugger (debug extension + launch.json adapter)

##### Landscape
Category: the Rust-native debug adapter behind the committed `launch.json`. Candidates:
CodeLLDB (`vadimcn.vscode-lldb`, LLDB-based DAP adapter — established); Microsoft's C/C++
extension `ms-vscode.cpptools` with `lldb-mi` (established but C++-general, heavier);
rust-analyzer's bundled debugging (does not exist — rust-analyzer ships no debug adapter).
Marketplace figures inapplicable (not a named endpoint — gap G2).
##### Principles and implementation
Shared principle (F195, class B, presumption of reuse): the committed-`launch.json`
pattern (F194) is inherited as-is; only the `type` + program shape change per language
(py `"type": "python"` → ts `"type": "node"` → rs `"type": "lldb"`). CodeLLDB is the
maintained native adapter: it debugs the `target/debug` binaries Cargo builds, needs no
platform split on the `ubuntu-latest, macos-latest` matrix (LLDB backs both; no Windows
debugger needed per the fixed matrix), and pairs with rust-analyzer as the documented
two-extension Rust setup. `lldb-mi` via cpptools is the same debugger behind a heavier,
C++-general extension the template would not otherwise recommend.
##### Dominant choice
`vadimcn.vscode-lldb` (CodeLLDB) with `"type": "lldb"` launch configs. Standing (named
endpoints, 2026-09-26): `GET https://api.github.com/repos/vadimcn/codelldb` → stars
3,309, `archived: false`, `pushed_at` 2026-08-23T22:32:49Z, reported SPDX MIT;
`GET https://api.github.com/search/issues?q=repo:vadimcn/codelldb+is:issue+is:open` →
`total_count` 166. Maintenance state: active (pushed 5 weeks ago; single-maintainer project
with a multi-year release history — the concentration risk is real and is priced into the
runner-up, not hidden).
##### Qualified shortlist
- `vadimcn.vscode-lldb` · native Rust/LLDB DAP adapter · stars 3,309 · pushed 2026-08-23 ·
  active · notable standing: the recommended Rust debug adapter across the ecosystem's own
  documentation · trade-off: single maintainer (accepted with the cpptools runner-up as
  the fallback).
##### Excluded by gate
rust-analyzer bundled debugging: excluded by existence (all six gates inapplicable — there
is no such adapter to evaluate). A platform-split choice (different adapters for Linux vs
macOS): excluded by need — LLDB backs both matrix runners, so a split buys nothing.
Per-gate record for the pick: (1) license pass (MIT as reported, compatible); (2) MSRV
inapplicable — editor extension + prebuilt adapter binary, not compiled into the template;
(3) advisories inapplicable — not a crates.io package (no rustsec page expected; not
queried beyond the two fetched 404s); `unsafe` inapplicable — not linked; (4) OS: Linux
and macOS builds published (publisher's release matrix; not fetched — gap G2); Windows
noted as supported upstream but not required by the fixed matrix; (5) features/async
inapplicable — not a Rust library dependency; (6) size/compile cost: zero template cost
(editor-side only; debugs the binaries Cargo already builds).
##### Up-and-comers
None. No emerging Rust debug adapter challenges CodeLLDB in this survey; DAP-side
innovation (e.g. `codelldb`'s own disassembly/views work) happens inside the incumbent.
##### Fit for this template
CLI: direct — the launch config runs `target/debug/<cli-bin>` (the F195 program-shape
question, answered per binary). Library: via integration-test configs (debug the test
binary), same adapter. Web: via the serve-binary config once R69's binary exists (config
shape ports unchanged). One adapter for all three surfaces; `preLaunchTask: cargo build`
keeps the binary fresh without coupling to R42 beyond bare `cargo` spelling.
##### Recommendation
Recommend `vadimcn.vscode-lldb` in `.vscode/extensions.json` and ship `launch.json`
configs with `"type": "lldb"` per debuggable binary (CLI bin, serve bin, test binaries as
the template's target list settles — target enumeration owned by R49, not fixed here).
Recommend no platform split.
##### Ranked runner-up
`ms-vscode.cpptools` driving `lldb-mi`. It wins if and only if CodeLLDB becomes unmaintained
or drops a matrix platform: same LLDB engine underneath, far larger maintainer base, but a
heavier install whose C++ scope the template otherwise never uses. Under that condition the
`launch.json` `type` changes and the extension ID swaps; the committed-`launch.json`
pattern itself is unaffected.
##### Tradeoffs
What CodeLLDB gives up versus cpptools: maintainer-base depth (single maintainer vs
Microsoft) — accepted because CodeLLDB is purpose-built (Rust pretty-printing, Cargo
integration) where cpptools is C++-general, and the runner-up condition covers the
abandonment case explicitly. What it gives up versus a hypothetical rust-analyzer-bundled
adapter: one-click zero-extra-install — moot, since no such adapter exists.
##### Parameters
No owned parameters. Assumes `package-manager-invocation` (bare `cargo build` in
`preLaunchTask` — consistent with R42's recorded value).
##### Migration implications
`.vscode/extensions.json`: add `vadimcn.vscode-lldb` to `recommendations`.
`.vscode/launch.json`: committed configs with `"type": "lldb"`, `program` pointing at the
template's debug binaries, `preLaunchTask` building them (exact binary list follows R49's
target declaration). No manifest, hook, or CI change.
##### Validation strategy
Planned (not executed — no VS Code on the probe host): (1) open the template, accept the
extension recommendations, set a breakpoint in the CLI bin, run the `lldb` launch config on
Linux and macOS, assert the breakpoint binds and locals render; (2) assert `launch.json`
parses and every `program` path resolves after `cargo build`. No executed support beyond
the repo-standing figures — the debug path is the least-executed member of this bundle
(gap, recorded not filled).
##### Confidence & re-verify trigger
Medium-high. The adapter pick is strongly evidenced (standing, native fit, presumption of
reuse); the residual uncertainty is the unexecuted debug session plus single-maintainer
concentration. Re-verify if: CodeLLDB goes 6 months without a push (active-state review);
it drops a matrix platform (adopt the runner-up); or the template's binary list changes
(add/remove configs accordingly).
##### Sources
- Repo: `GET https://api.github.com/repos/vadimcn/codelldb` (stars 3309, archived false,
  pushed 2026-08-23T22:32:49Z, license MIT, 2026-09-26)
- Open issues: `GET
  https://api.github.com/search/issues?q=repo:vadimcn/codelldb+is:issue+is:open`
  (total_count 166, 2026-09-26)
- Recorded: F194 presumption-of-reuse (prompt `## Context`); fixed `target-os-matrix`
  (`docs/port/PARAMETERS.md` via `inputs/parameters.json`)
- Gaps: recent-issue responsiveness window not sampled (shared-IP rate limit — G1);
  per-platform adapter builds not verified from the release matrix (G2)

#### editor-settings-pin (no settings.json pin)

##### Landscape
Category: whether the template commits a `.vscode/settings.json` pinning the editor's
language-service version. Candidates: a rust-analyzer pin (no such setting exists —
rust-analyzer resolves the toolchain from `rust-toolchain.toml`/rustup, not from an
editor-side path); "no pin" (collapse to nothing). No crate figures apply (inapplicable —
a file-existence question, not a package).
##### Principles and implementation
Shared principle (F196, class C language-bound mechanic): editor and CI must run the same
language engine. Ts enforces it with a pin (`"typescript.tsdk": "node_modules/typescript/
lib"`) only because the TS engine resolves from a `node_modules` path the editor would
otherwise guess — D-032 calls it "a narrow, deliberate exception to the source's
no-`settings.json` principle", and py has no pin at all. Rust resolves the engine one level
up: rust-analyzer shells out to the toolchain selected by `rust-toolchain.toml`/rustup,
which is the same toolchain CI uses — there is no editor-guessed path to pin, hence no
equivalent setting to set. The prompt's own LOW question leans this way ("no equivalent
pin needed"); this member confirms it. Agreement is preserved at the principle level
(same engine in editor and CI) while the mechanism collapses to nothing, exactly as class
C anticipates.
##### Dominant choice
No `.vscode/settings.json` pin for the language service: the toolchain file
(`rust-toolchain.toml`, cf. R42's component-state check referencing the active toolchain)
is the single version authority for editor and CI alike.
##### Qualified shortlist
- No pin · zero files, zero drift surface, matches py (which also ships no pin) ·
  trade-off: none within this member's scope (any future `settings.json` need from another
  item — e.g. formatter defaults — is that item's file-content decision, not a pin).
##### Excluded by gate
A `rust-analyzer`-path pin (e.g. hard-coding a server binary path in `settings.json`):
excluded by fit, not by numbered gate (all six inapplicable — a file-content question):
it would pin the editor to one machine's toolchain layout, breaking the portability the
toolchain file provides, and it would duplicate the version authority (two pins to drift).
Recorded here rather than silently dropped.
##### Up-and-comers
None — a collapse-to-nothing has no emerging alternative.
##### Fit for this template
CLI/library/web: inapplicable-distinct — the absence of a file fits all members equally.
Consistent with R42 (toolchain provisioning owns the version authority) and with the
source repos' default posture (py ships no `settings.json`; ts's one key is the recorded
exception). If a future item needs `settings.json` content for another purpose, that
content composes with this member (no conflict: this member forbids only the toolchain
pin, not the file).
##### Recommendation
Ship no `.vscode/settings.json` toolchain pin. Document that `rust-toolchain.toml` is the
version authority and that editor/CI agreement rides it.
##### Ranked runner-up
None. Any pin-shaped content is the excluded option above; there is no second "no pin"
form to rank.
##### Tradeoffs
What no-pin gives up versus ts's pin: protection against editor/CI engine skew — moot,
because the skew vector (a `node_modules`-resolved engine) does not exist for Rust; the
toolchain file already provides the protection. No operative trade-off remains.
##### Parameters
No owned parameters. Assumes the existence of a toolchain authority (`rust-toolchain.toml`
— provisioning owned by R42; this member consumes the assumption, not the value).
##### Migration implications
No file created. If the template later gains a `.vscode/settings.json` for another item's
purpose, this member contributes no keys to it. One documentation line stating the
no-pin rationale.
##### Validation strategy
Planned (not executed): (1) assert the template tree contains no `.vscode/settings.json`
toolchain-pin key; (2) with rust-analyzer running, assert the server reports the toolchain
selected by `rust-toolchain.toml` (e.g. via the server's version command against a sloping
toolchain file). Executed support: `rustup component list --installed` shows the toolchain
resolving components (rust-analyzer included) from the active toolchain — the mechanism
the no-pin relies on.
##### Confidence & re-verify trigger
High. The collapse follows directly from the resolution mechanism, and the prompt's own
question anticipates it. Re-verify if: rust-analyzer introduces an editor-side toolchain
override that a template would need to pin (no such setting exists today); or R42 removes
the toolchain file (the version authority this member leans on would need a successor).
##### Sources
- Recorded: `docs/port/DIVERGENCE-ANALYSIS.md` R28/F196 sub-row (class C, D-032 rationale,
  harmonize no); prompt `## Context` (`rust-toolchain.toml` resolution, ts
  `.vscode/settings.json:2`)
- Executed: `rustup component list --installed` (toolchain-resolved components incl.
  rust-analyzer, 2026-09-26)

### Compatibility

The members are tested together in two senses. First, the executed probe ran the `clippy`,
`autofix-default-policy`, and `test-lint-relaxation` members as one gate: a single crate
carrying the `[lints.clippy]` priority-form table, a `clippy.toml`, deny-level production
code, and `#[allow]`-scoped test modules passed `cargo clippy --all-targets` check-only
in one invocation (2026-09-26). Second, co-installation: `rustup component list
--installed` on the probe host shows `clippy` and `rust-analyzer` resolved from the same
active toolchain, so the gate and the editor's language server cannot disagree on the
toolchain (this is also what makes the `editor-settings-pin` collapse sound). No version
matrix is needed or possible: no member carries independent semver — clippy and
rust-analyzer version with the pinned toolchain, and `.vscode/extensions.json`
recommendations are unversioned IDs by VS Code design. The compatibility contract is
therefore the toolchain pin itself: one `rust-toolchain.toml` versions the gate, the
editor server, and the binaries CodeLLDB debugs.

### Parameters

- assumes ci-job-structure = (R11's recorded value in `inputs/parameters.json`: one
  `check` job per matrix OS hosting the compiling checks as ordered steps; this bundle
  supplies the clippy step's command and exit-code contract, not its placement)
- assumes package-manager-invocation = (R42's recorded value in
  `inputs/parameters.json`: rustup components as `cargo <sub>`, everything else as a bare
  executable; this bundle's recipes spell `cargo clippy` accordingly)
- No CONFLICT lines. No owned parameters (this item owns none per `## Couplings`).

### Migration implications

Template file-level changes: `Cargo.toml` gains `[lints.rust]` (`unsafe_code = "forbid"`)
and `[lints.clippy]` (`all` deny / `pedantic` warn / `undocumented_unsafe_blocks` warn,
priority form where group and member mix); a committed `clippy.toml` holds threshold-style
options and any `disallowed-methods` entries; the Justfile's `lint` recipe runs
`cargo clippy --all-targets` check-only (plus an optional explicit `lint-fix` recipe);
`.vscode/extensions.json` recommends `rust-lang.rust-analyzer` and `vadimcn.vscode-lldb`;
`.vscode/launch.json` carries `"type": "lldb"` configs per debuggable binary; no
`.vscode/settings.json` toolchain pin is created. Test modules carry their `#[allow]`
attributes in-source. No new config-key or parameter is defined here.

### Validation strategy

Executed 2026-09-26 (probe crate, rustc/cargo 1.98.1, clippy 0.1.98 — recipe reproducible,
crate since removed): (1) `[lints.clippy]` bare group+member mix → manifest error naming
the priority conflict (expected: error; observed: error); (2) priority form + clean code →
`Finished`, exit 0 (expected: pass; observed: pass); (3) deliberate `clone_on_copy` /
`let_and_return` violations → deny-level errors, nonzero exit, sources byte-identical
(expected: check-only failure; observed: check-only failure); (4) `clippy.toml` bogus key →
hard error listing valid keys, real key → silent accept (expected: discovery proven;
observed: proven); (5) `#[allow(clippy::all, clippy::pedantic)]` on the `#[cfg(test)]`
module → sloppy test code passes with the gate deny-level elsewhere (expected: scoped
relaxation; observed: scoped relaxation); (6) `cargo clippy --help` → `--fix` documented
as an explicit flag implying `--no-deps`/`--all-targets`; (7) `rustup component list
--installed` → clippy + rust-analyzer present; `rust-analyzer --version` → 1.94.0;
(8) rustsec `clippy`/`rust-analyzer` pages → HTTP 404 (expected: no advisories filed;
observed: 404s). Planned, not executed: CI run of the same manifest on ubuntu-latest +
macos-latest; VS Code session asserting diagnostics surface via rust-analyzer alone and a
breakpoint binds via the `lldb` config on both matrix OSs; template hygiene tests asserting
no `--fix` in automated recipes and explicit allow-or-comment on every `#[cfg(test)]`
module.

### Confidence & re-verify trigger

High on the clippy gate (tool uncontested, config surface executed both directions),
the check-only default (executed, drift analysis recorded), test relaxation (executed),
and the no-pin collapse (mechanism-verified); medium-high on the security layering (clippy
side executed, SAST side correctly deferred) and the debugger pick (strong standing
evidence, debug session unexecuted). Re-verify the bundle if: a toolchain bump renames a
recommended lint/group or changes `[lints]`/`--fix` semantics (review the bump PR); R31
adopts a standalone scanner (restate the SAST expectation); CodeLLDB goes 6 months without
a push or drops a matrix platform (adopt the cpptools runner-up); the extension IDs change;
or 2027-03-26 passes without the annual review.

### Sources

Named-endpoint fetches (all 2026-09-26; crates.io figure rows inapplicable to every
member — no member is a crates.io package):

- `GET https://api.github.com/repos/rust-lang/rust-clippy` → stars 13535, archived
  false, pushed 2026-09-24T14:26:18Z, SPDX Apache-2.0
- `GET https://api.github.com/search/issues?q=repo:rust-lang/rust-clippy+is:issue+is:open`
  → total_count 2506
- `GET https://api.github.com/repos/rust-lang/rust-analyzer` → stars 16876, archived
  false, pushed 2026-09-26T10:35:50Z, SPDX Apache-2.0
- `GET https://api.github.com/search/issues?q=repo:rust-lang/rust-analyzer+is:issue+is:open`
  → total_count 1695
- `GET https://api.github.com/repos/rust-lang/rust-analyzer/issues?state=open&sort=created&direction=desc&per_page=10`
  → 3 issues + 7 PRs, 2026-09-20 → 2026-09-26
- `GET https://api.github.com/repos/vadimcn/codelldb` → stars 3309, archived false,
  pushed 2026-08-23T22:32:49Z, SPDX MIT
- `GET https://api.github.com/search/issues?q=repo:vadimcn/codelldb+is:issue+is:open` →
  total_count 166
- `https://rustsec.org/packages/clippy.html` → HTTP 404 (no advisory filed)
- `https://rustsec.org/packages/rust-analyzer.html` → HTTP 404 (no advisory filed)

In-repo records: `docs/port/DIVERGENCE-ANALYSIS.md` R28 item + sub-rows (classes,
`harmonize` scope, D-014/D-024/D-032 notes); `research/CLAUDE.md` R28 row (kind `bundle`);
run `inputs/parameters.json` (fixed params + R11/R42 recorded values);
`inputs/prerequisites.json` (R11/R42 acceptance hashes); prompt `## Context` py/ts
evidence (accepted as cited, not re-read).

Executed local evidence: `rustc/cargo 1.98.1`, `clippy 0.1.98`, `rust-analyzer 1.94.0`;
`rustup component list --installed`; `cargo clippy --help`; probe runs (1)–(8) under
`### Validation strategy`.

Gaps recorded, not filled: G1 — CodeLLDB recent-issue window + clippy-book contents fetch
blocked by shared-IP GitHub rate exhaustion (reset after this pass); G2 — VS Code
Marketplace figures (install counts, publisher badges, per-platform build matrices) not
queried (not a named endpoint); G3 — named-adopter manifests not fetched (needs G1-blocked
API or non-named hosts); standing rests on bundled status + repo figures instead; G4 —
`doc.rust-lang.org` reference pages not fetched (non-named hosts); cited as background
only, with load-bearing behaviors executed locally instead.
