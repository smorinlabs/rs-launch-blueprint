# 2026-09-26 — R27 — formatter-config-surface (bundle, Focused) — decision (revision 3)

**Revision note, revision 3.** This is fix round 2, against revision 2 (sha256 `59972facff399c5712e45f18af321588d6a0c1ba39b205d1ef06e09a7e6ee388`, preserved byte-identical at `review/R27-r2-snapshot.md`). The revision-2 judgment audit (`review/audit-fable.r2.md`) rejected it with one finding, JF-2/JF-4, and one non-blocking citation note. The concurrent empirical audit (`review/audit-claude.r2.md`) approved revision 2 (101 assertions, 101 pass, 0 fail, 0 skipped). Neither the finding nor the note reopens the recommendation, the five config keys, the channel value, the hook mode, the composite placement or any executed check, and revision 3 moves none of them. **The five existing evidence scripts and logs are byte-unchanged.** One observation-only pair, `evidence/r27-husky-defaults.sh` and `.log` (check F11), is new; it makes no assertions, so the assertion total stays 101.

| Finding | What the audit found | Disposition in revision 3 |
|---|---|---|
| **Finding 1 (JF-2/JF-4)** | The hook-mode section said popular Rust "project templates default to check mode (`cargo-husky` …)". cargo-husky's default is a pre-push hook that runs `cargo test` only; `cargo fmt --check` needs the opt-in `run-cargo-fmt` feature. "Project templates" also widened the Opus leg's "hook templates" | **Fixed.** The sentence is replaced with the audit's repair wording. It says "hook templates", states cargo-husky's default and the opt-in feature, and cites the new F11 read (`evidence/r27-husky-defaults.log`, retrieved 2026-09-27T07:24:00Z) for the default-feature fact, which the Opus leg does not contain |
| **Note (JF-4, non-blocking)** | The gate-2 row cited only the "C1 header" for rustfmt 1.8.0 in 1.93.0, but 1.93.0 appears in `r27-channel-pin.log` C4.1 | **Fixed.** The row now cites "C1 header and C4.1" |

**Revision note, revision 2.** This is fix round 1, against revision 1 (sha256 `89824ad9c99c6de6b1594456e15f17235118ae22f2208860f2a84de2e50ae2ad`, preserved byte-identical at `review/R27-r1-snapshot.md`). The revision-1 judgment audit (`review/audit-fable.md`) rejected it with two fidelity findings, F1 (JF-3) and F2 (JF-2). The concurrent empirical audit (`review/audit-claude.md`) approved revision 1 (101 assertions, 101 pass, 0 fail, 0 skipped). Neither finding reopens the recommendation, the five config keys, the channel value, the hook mode, the composite placement or any executed check, and revision 2 moves none of them. **Both fixes are prose-only; all evidence bytes are unchanged.**

| Finding | What the audit found | Disposition in revision 2 |
|---|---|---|
| **F1 (JF-3)** | The `## Engines` row 1 and the channel body misstated the Muse leg's channel position as "no version number exists", and C4.1 rebutted a position Muse never took | **Fixed.** Row 1 and the channel body now quote Muse verbatim (`raw/muse.md:801-805`), cite Muse's real rejection of an exact channel as unneeded rigidity (`raw/muse.md:834-837`), and answer that argument with C4.6, F5, R42's survey, F8 and C4.5. C4.1 stands as mechanism evidence only |
| **F2 (JF-2)** | The LOW hook-mode question's template sub-question ("what do popular Rust project templates default to?") was unanswered | **Fixed.** The hook-mode section now answers it in one sentence, carried from the Opus leg (`raw/opus.md:123-127`, `raw/opus.md:801-802`) |

**Revision note, revision 1.** This is the first synthesis of R27. It adjudicates two raw reports: `raw/muse.md` (the Muse leg, standing in the Codex seat) and `raw/opus.md` (the Opus leg). Nothing has been published for R27, so there is no `## Supersedes`. `review/evidence/` was regenerated from scratch in this synthesis. A previous, interrupted synthesis attempt had left 14 untracked files there (seven `.sh`/`.log` pairs, written 17:54–17:58 local time). They were moved out of the repository to `$TMPDIR/r27-prior-attempt-evidence-1790471219/`. Only the first lines of two of the scripts and the last lines of two of the logs were read, to identify them. Nothing in this decision depends on them.

**Actor and provenance.** Synthesizer: a fresh Claude context on the Opus seat, model `claude-opus-5-5`, CLI run 2026-09-26. The context produced neither raw report and none of their checks. **Two provenance facts for the controller**, neither of which this synthesis can resolve: (1) `research/RUNBOOK.md:83` names a fresh Claude **Fable** context as the synthesizer, and this synthesis ran on the Opus seat, the same model family as the Opus leg; (2) the run's policy snapshot lists `codex` and `opus` for R27 (`inputs/EXECUTION.json`, item `R27`; `manifest.json` `required_engines`) and has no `engine_overrides` entry for R27, yet the collected second leg is Muse (`raw/muse.md:3`).

**Retrieval dates.** Figures this synthesis fetched itself: **2026-09-27T01:15:13Z (UTC)**, which is 2026-09-26 in Pacific time (`evidence/r27-figures.log:1`). Figures carried from a raw report carry that report's date, 2026-09-26. The H1 date is the run date, 2026-09-26; the figures stamp is recorded separately because the fetch crossed midnight UTC. Revision 3 adds one fetch, check F11: **2026-09-27T07:24:00Z (UTC)**, which is 2026-09-27 in Pacific time (`evidence/r27-husky-defaults.log:1`).

**Fitness gate 1 (licence) is inapplicable** for every member: the owner ruled on 2026-09-12 that there is no licence check for any tool or library the template uses (`research/topics/42-dev-toolchain-provisioning/DECISION.md:12-16`). Licence strings below are recorded figures, not tests.

## Decision

**Recommendation — one stack.** Format Rust source with **rustfmt**, the rustup component, invoked as `cargo fmt --all`. Configure it with a five-key, stable-only `rustfmt.toml`. Fix its version with R42's `rust-toolchain.toml` at the exact channel **`1.98.1`**, the current stable release on the retrieval date. That channel supplies **rustfmt 1.9.0**, the build observed with Homebrew's rustc 1.98.1. Exclude nothing. Enforce formatting with the same verdict command, `cargo fmt --all --check`, on three surfaces: a blocking lefthook pre-commit job, the first step of the composite gate recipe, and a step of R11's `hygiene` CI job. The composite and CI also run two cheap guards: one fails on a `rustfmt.toml` key that the toolchain ignores, and one fails on a tracked `.rs` file that `cargo fmt` never reaches. Every file below was executed on this host except the channel value and the CI step; the CI step ran only as the recipe body (`## Empirical check`).

### The files

`rustfmt.toml` at the repository root, byte for byte (sha256 `a714037d3cb8919614f9b8619ff9a940ac858e5da22b25298abb7f68c310bea8`, `evidence/r27-config-surface.log:9-17`):

```toml
# Rust source formatting (R27). Every key is stable: no nightly toolchain is needed.
edition = "2024"        # bare rustfmt callers parse 2024 syntax; cargo fmt passes Cargo.toml's edition
style_edition = "2024"  # the 2024 style edition
max_width = 100         # F087: rustfmt's default width, stated
newline_style = "Unix"  # F089: LF bytes on every OS; "Auto" keeps whatever a file already has
reorder_imports = true  # F092: the formatter owns import order (rustfmt's default, stated)
```

`rust-toolchain.toml`, R42's file (`research/topics/42-dev-toolchain-provisioning/DECISION.md:26`), with this item's `channel` value. The `profile` and `components` lines are R42's and unchanged:

```toml
[toolchain]
channel = "1.98.1"
profile = "minimal"
components = ["rustfmt", "clippy"]
```

`Justfile` recipes. Their names follow the prompt's own `format`/`check` wording (`inputs/prompt.md:4`). The composite gate recipe lists `format-check` first; its name and its other members belong to their owning items. Executed through `just` 1.51.0 (`evidence/r27-workspace-scope.log`, C2.1 and C2.3–C2.7):

```just
# Format every Rust source file in the workspace in place
format:
    cargo fmt --all

# Check formatting without writing; also fail on an ignored rustfmt.toml key or an unreached .rs file
format-check:
    #!/usr/bin/env bash
    set -euo pipefail
    rc=0
    out=$(cargo fmt --all -- --check --verbose 2>&1) || rc=$?
    grep -v -e '^Formatting ' -e '^Using rustfmt config file ' -e '^Spent ' <<<"$out" || true
    if [ "$rc" -ne 0 ]; then exit "$rc"; fi
    if grep -q "can't set" <<<"$out"; then
        echo "error: rustfmt.toml sets a key this toolchain ignores" >&2
        exit 1
    fi
    root=$(pwd -P)
    unreached=$(comm -23 <(git ls-files -- '*.rs' | sort) <(sed -n "s|^Formatting $root/||p" <<<"$out" | sort -u))
    if [ -n "$unreached" ]; then
        printf 'error: tracked .rs files that cargo fmt does not reach:\n%s\n' "$unreached" >&2
        exit 1
    fi
```

`cargo fmt --all -- --check --verbose` passes `--check --verbose` through to rustfmt. The exit status is the same verdict as `cargo fmt --all --check`, and `--verbose` adds one `Formatting <path>` line for every file rustfmt reaches, which is the reachability guard's input.

`lefthook.yml` pre-commit job. It is check-and-block, with no `glob`, no `exclude` and no `stage_fixed` (executed with lefthook 2.1.14, `evidence/r27-hook.log`, variant A):

```yaml
pre-commit:
  jobs:
    - name: rustfmt
      run: cargo fmt --all --check
```

`.github/workflows/ci.yml`: the `format-check` body as a step of R11's `hygiene` job, the slot R11 assigns to a non-compiling formatter (`research/topics/11-ci-workflow-job-structure/DECISION.md:286`). Whether the step calls `just format-check` or inlines the body is R11's and R42's phrasing, not this item's.

### Settled rows

| Row | Question | Settled value | Evidence |
|---|---|---|---|
| F084 | formatter tool | rustfmt via `cargo fmt --all`; no alternative named | both legs; F9, F10; C2 |
| F087 | line width | `max_width = 100`, rustfmt's default, stated | C1.2, C1.5 (byte-identical to the default) |
| F089 | line endings | `newline_style = "Unix"` | C1.5: CRLF fails under `Unix`, passes under `Auto` |
| F091 | trailing comma | not configured: the key is unstable; the stable default `Vertical` adds a trailing comma to vertical lists | C1.3, C1.5 |
| F092 | import ordering | formatter-owned: `reorder_imports = true` (the default, stated); grouping and merging keys left unset (unstable) | C1.2, C1.3, C1.5 |
| F100 | exclude scope | no exclude list in any file; the scope is every tracked `.rs` file, enforced by the reachability guard | C1.3b, C2.3–C2.5 |
| F102 | composite placement | `format-check` is the composite gate's first step | C2.7, C2.8 |
| F103 / F190 | version pinning | `rust-toolchain.toml` `channel = "1.98.1"`, bumped per stable release | C4.1–C4.6, F1, F5, F8 |
| F104 | pre-commit hook mode | check-and-block, whole workspace, no glob | C3 A-H1…A-H6, C-H6, W1, W2 |
| F162 | exclude-list drift guard | no mirror test: there is no second list. The reachability and ignored-key guards replace it | C2.3–C2.6 |

### Principles and implementation

**The shared requirement.** The prompt records the same precedent in both source repositories: one dedicated formatter runs through three surfaces, a Justfile recipe, a lefthook hook and a CI job (`inputs/prompt.md:8`). Both legs state the requirement the same way: one tool and one configuration give one verdict on every surface, so code formatted locally passes CI unchanged (`raw/muse.md:91-94`, `raw/opus.md:141-144`). This decision adopts that statement.

**Agreement levels.**

| Level | What must agree across py, ts and rs | What may vary |
|---|---|---|
| Policy | one dedicated formatter; the same check on the recipe, hook and CI surfaces; CI is authoritative | which tool |
| Capability | bounded width; normalized line endings; formatter-owned import order; every tracked source file covered; a checked-in artefact fixes the formatter's version | the literal values where the ecosystem norm differs, such as py's 88-column width |
| Mechanism | nothing | config file shape, exclusion mechanism, pin artefact, hook mode |

Both legs place the same three rows at the value level of "may vary": width, trailing comma and pinning mechanism (`raw/muse.md:100-106`, `raw/opus.md:172-183`). They differ on line endings: the Opus leg calls LF a shared value because the tradeoff is identical everywhere, and the Muse leg recommends LF for every repository while calling it a principle repair rather than a value mandate (`raw/opus.md:176`, `raw/muse.md:158-161`). The two positions produce the same file bytes, and this decision records LF as the shared value.

**Acceptance criteria — every one observed in this synthesis.**

1. One command gives the verdict for the whole workspace: `cargo fmt --all --check` exits 1 on an unformatted file in any member and 0 after `just format`, from the root and from a member directory (C2.2, C2.7).
2. The configuration is stable-only: the file produces zero `can't set` warnings on rustfmt 1.8.0 and 1.9.0, and the guard fails the recipe when an ignored key is added (C1.1, C2.6).
3. Line endings are LF: a CRLF file fails the check with `Incorrect newline style` (C1.5).
4. The formatter orders imports (C1.5).
5. Nothing is silently excluded: every tracked `.rs` file is reached, or the recipe names the file that is not (C2.1, C2.3–C2.5).
6. The hook blocks a commit whose staged Rust is unformatted and never modifies a file (C3 A-H1, A-H5).
7. The hook, the composite and CI give the same formatting verdict, because all three run `cargo fmt --all --check`, directly or as the recipe's first command (C2.7, C3 A-H1/A-H2).
8. A checked-in file fixes the toolchain that supplies rustfmt, and rustup honours it (C4.1).

**Architectural alternatives compared before choosing mechanisms.**

| Decision | Alternatives | Chosen, and why |
|---|---|---|
| Formatter topology | (a) first-party rustfmt with a checked-in config; (b) a multi-language host wrapping rustfmt (dprint); (c) an independent engine (genemichaels, topiary) | (a). (b) adds a second tool without changing Rust output and is R29's territory for non-Rust files. (c) forfeits the ecosystem-wide style; `genemichaels` has 4,317 recent downloads and `topiary-cli` 153, against rustfmt shipping in every toolchain (F9) |
| Config surface | (a) stable keys only; (b) nightly keys (`imports_granularity`, `group_imports`, `trailing_comma`, `ignore`) | (a). (b) needs a nightly toolchain, which the stable-only constraint forbids. On stable, each key is warned about and ignored while the exit status stays 0 (C1.3) |
| Exclusion | (a) config `ignore` list; (b) structural scope: workspace membership, `[workspace] exclude`, `#[rustfmt::skip]` on a `mod`; (c) no exclusion, and a guard that names any unreached file | (c). (a) has no effect on stable (C1.3b). (b) works (C2.3, C2.4) but excludes silently, and an orphan file or a macro-declared module is also skipped silently (C2.5). (c) makes every exclusion visible (C2.3–C2.5) |
| Hook mode | (a) check-and-block; (b) write-and-restage (`stage_fixed`, the ts shape); (c) write-and-fail | (a). `cargo fmt` cannot be scoped to the staged files (W1, W2), so (b) rewrote a file the contributor never staged (C-H6) |
| Version fixing | (a) exact channel in `rust-toolchain.toml`; (b) `channel = "stable"`; (c) the MSRV floor | (a); see the channel discussion below. (c) is excluded by the F190 baseline review (`inputs/prompt.md:14`) |

**Why rustfmt, and the fitness gates.** rustfmt is the only candidate that formats human-edited Rust in place, and it is the formatter both legs found in every surveyed project's CI (`raw/muse.md:76-78`, `raw/opus.md:116-123`). The gates, for the one crate-like member:

| Gate | rustfmt |
|---|---|
| 1 licence | inapplicable (owner ruling, above). Recorded: GitHub detects `Apache-2.0` on `rust-lang/rustfmt` (F2); both legs report `LICENSE-MIT` and `LICENSE-APACHE` at the root (`raw/muse.md:384`, `raw/opus.md:343`), not re-fetched here |
| 2 MSRV | ships with each toolchain: rustfmt 1.8.0 in 1.93.0 and 1.94.0, 1.9.0 in 1.96.0, 1.96.1 and Homebrew's 1.98.1 (C1 header and C4.1). The floor, 1.96, carries it |
| 3 advisories, `unsafe` | no RustSec page for `rustfmt-nightly` (HTTP 404, F10); `unsafe` is irrelevant because rustfmt is a separate developer process, never linked into an artefact |
| 4 OS | executed on macOS 26.4 arm64 only. `ubuntu-latest` was not exercised (gap); R11 runs `hygiene` on a single runner by design (`research/topics/11-ci-workflow-job-structure/DECISION.md:259`) |
| 5 features, runtime | none |
| 6 size, compile time | zero for the template: nothing is compiled; `cargo fmt --all --check` took 0.07–0.08 s and `just format-check` 0.54 s on the scratch workspace (C2.8) |

Maintenance: **active**. `rust-lang/rustfmt` has 6,974 stars, `archived: false`, `pushed_at` 2026-09-24T13:36:12Z, and 718 open issues (F2, F3). Of the 10 most recently opened issues, 1 received a first comment from an OWNER, MEMBER or COLLABORATOR, after 0.6 days, and 9 received none. That rule undercounts rust-lang members whose membership is private (F4). The other members of the stack — the config file, the toolchain pin, the recipes and the hook job — are not crates, so crate figures are inapplicable to them; their evidence is the executed checks.

**The `rustfmt.toml` keys.** Both legs recommend four keys and agree on three of them: `style_edition = "2024"`, `max_width = 100` and `newline_style = "Unix"`. They differ on one key each:

- `edition = "2024"` (Opus sets it; Muse omits it as a second copy that can only drift, `raw/muse.md:419`). **Kept.** A bare `rustfmt` call, which is what an editor plugin or a `rustfmt` pre-commit entry runs, rejects 2024 syntax with no config or with `style_edition` alone, and parses it with `edition = "2024"` (C1.4). The drift objection does not reach the three enforcement surfaces: `cargo fmt` passed `--edition 2024` over a `rustfmt.toml` that said `2021` (C1.4b). The residual cost is that an edition bump must update this key too; that is a re-verify event below.
- `reorder_imports = true` (Muse sets it; Opus relies on the default). **Kept.** It restates the default and is silent on every build (C1.2). It records the F092 ownership decision in the file, by the same reasoning both legs use to state `max_width = 100`, which also restates the default (C1.5).

`style_edition` is stable in the binaries: rustfmt 1.8.0 and 1.9.0 accept it with no warning (C1.2). The Opus leg reports that `Configurations.md` at tag `v1.9.0` still marks it unstable (`raw/opus.md:434-437`). This synthesis did not re-fetch that document, and the binaries' behaviour is the authority.

**The channel: `1.98.1`, not `stable`.** This is the widest disagreement between the legs. The Muse leg recommends `channel = "stable"` (`raw/muse.md:804-805`). Muse's point that rustfmt has no version separate from its toolchain is correct: "There is no version number to float or pin: `cargo fmt --version` reports the component build of the active toolchain, and the only selectors rustup offers are the channel (`stable`, `beta`, `nightly`, or a dated/archive version) and the component set." (`raw/muse.md:801-805`). Muse names a dated or archive version as an available selector there, and rejects an exact channel as unneeded rigidity for a formatter (`raw/muse.md:834-837`). The Opus leg recommends the exact current release (`raw/opus.md:718-723`). The evidence:

- *A version can be pinned.* The exact channels `1.93.0` and `1.96` were honoured, with both components present and R42's presence test passing (C4.1). C4.1 shows the pin mechanism works; it answers no claim of Muse's, who never denied it. Muse's stated reason for rejecting an exact channel is maintenance fit: it "freezes the whole toolchain (compiler, cargo, clippy, rustfmt) for the sake of a formatter whose formatting rules the template already constrains via `style_edition`", and "no surveyed project does this for formatting" (`raw/muse.md:834-837`). C4.6 answers the first half — the channel also fixes clippy's lint set under R11's `-D warnings`; F5 and R42's survey answer the field-practice claim; F8 answers the upkeep cost; C4.5 concedes the formatter-only point.
- *`stable` fixes nothing.* On this host `stable` resolves to rustc 1.94.0 and rustfmt 1.8.0, while the current release is 1.98.1 (C4.2, F1). The same committed file therefore names a different toolchain on each machine. Both source repositories fix their formatter's version with a checked-in artefact — py with a lockfile, ts with an exact pin (`inputs/prompt.md:9`) — and `stable` does not meet that principle.
- *The formatter alone would tolerate `stable`.* Four rustfmt builds, 1.8.0 twice and 1.9.0 twice, produced byte-identical output for a 20-line sample under the recommended file (C4.5). This supports the Muse leg's point that `style_edition` contains formatting drift. It weakens the Opus leg's formatter-specific reason, and this decision does not rest on it.
- *The channel carries more than the formatter.* The same file supplies clippy. Its warn-by-default set gained six lints between 1.94.0 and 1.96.1 (C4.6), and R11's clippy steps run with `-D warnings` (`research/topics/11-ci-workflow-job-structure/DECISION.md:268`). Under `stable`, a contributor's or runner's `rustup update` can turn CI red with no repository change.
- *Field practice.* uv and zed pin `1.98.1`, ruff `1.98.0` and nushell `1.96.1`; cargo-binstall uses `stable` (F5). R42's own survey found 8 of 9 repositories pinning an exact version (`research/topics/42-dev-toolchain-provisioning/DECISION.md:302-305`).
- *Cost.* One bump pull request per six-week release. Dependabot has a `rust_toolchain` ecosystem (F8); adding the `rust-toolchain` entry to `.github/dependabot.yml` belongs to R19, which this synthesis could not read (read scope). A runner whose preinstalled stable differs from the pin also downloads the pinned toolchain, and that cost is unmeasured; R11 records the same gap for `hygiene` (`research/topics/11-ci-workflow-job-structure/DECISION.md:383`).
- *Not exercised.* The value `1.98.1` is not installed under rustup here, and the check fails closed rather than downloading (C4.3). Homebrew's rustfmt 1.9.0, shipped with Homebrew's rustc 1.98.1, ran every config check (C1). The pin **mechanism** executed; the pin **value** did not.

Ranked runner-up: `channel = "stable"`, which costs no upkeep and keeps formatting stable within the style edition (C4.5), but leaves clippy's lint set and the toolchain unfixed. The MSRV floor stays where the fixed parameter puts it: `rust-version` plus R11's `msrv-floor` job, never this channel (`inputs/prompt.md:14`).

A hazard outside this item: when a non-rustup `cargo-fmt` resolves first on `PATH` (Homebrew's, on this host), the toolchain file is ignored and rustup still reports the override as active (C4.4). This is R42's acquisition question; it is recorded here because it defeats any pin value.

**Scope and exclusion (F100, F162).** Both legs agree that a config `ignore` list is unavailable on stable. This synthesis confirmed that a listed file is still checked (C1.3b). They differ on what "nothing is excluded" means:

- The Muse leg's criterion that "every `.rs` file the workspace owns is covered" (`raw/muse.md:127-129`) is false as written. `cargo fmt` reaches only files named by a `mod` item it can see. An orphan file and a module declared inside `macro_rules!` were both left unformatted while `cargo fmt --all --check` exited 0; the macro-declared module compiled (C2.5). The Opus leg found this hazard (`raw/opus.md:242-249`).
- The Opus leg's recommended scope mechanism, `[workspace] exclude` plus `#[rustfmt::skip]` on a `mod` (`raw/opus.md:593`), works (C2.3, C2.4). Both mechanisms are silent, however, so this decision adopts the Opus leg's proposed reachability guard (`raw/opus.md:642-645`) as a standing check, and adopts none of the exclusions today. The guard names the excluded, skipped, orphan and macro-declared files, and passes a baseline that includes `tests/`, `examples/` and `build.rs` (C2.1, C2.3–C2.5).
- If an exclusion is ever needed — a vendored crate, or a checked-in generated module from R71 — the same change adds a filter for it to the guard. The guard then holds the only exclusion list in the repository, so no second list can drift from it.
- The ignored-key guard is the Opus leg's criterion A2 (`raw/opus.md:157-160`), executed here (C2.6).

The F162 test in ts compares each lefthook job's `exclude` with the same tool's `ignorePatterns` (`inputs/prompt.md:9`; the Opus leg reads the test the same way, `raw/opus.md:574`). It is not a comparison of formatter and linter lists. The rs hook passes no file list, so there is nothing to mirror.

For R28, which is open, both outcomes are covered. (i) Clippy uses no path list — the Opus leg reads `clippy.toml` as having no path-exclude setting (`raw/opus.md:561-563`) — so the reachability guard's scope is the single scope, and no test is needed. (ii) R28 introduces a path list for clippy, such as a lefthook `exclude` on its job. Then a hygiene test must assert that list equals the reachability guard's exclusions, which are empty today. That is ts's F162 pattern, re-keyed to this repository's only list.

**Hook mode (F104).** Both legs choose check-and-block. The Opus leg also adds `glob: "*.rs"` (`raw/opus.md:831-837`). **The glob is rejected.** A commit that changes only `rustfmt.toml`, to `max_width = 40`, leaves the tree unformatted. The job without the glob blocked that commit; the job with the glob skipped and accepted it (C3 A-H4, B-H4). The glob would save about 0.08 s per commit, the measured cost of `cargo fmt --all --check` (C2.8). The job without it matches R11's `hygiene`, which always runs (`research/topics/11-ci-workflow-job-structure/DECISION.md:93`).

Rust hook templates run the formatter in check mode or in write-and-fail mode, and none restages. `cargo-husky` (3,630,801 crates.io downloads) generates `cargo fmt --check` only when its opt-in `run-cargo-fmt` feature is enabled; its default is a pre-push hook that runs `cargo test` alone (`rhysd/cargo-husky` `Cargo.toml` `[features] default`, `build.rs:141-142`; read in check F11, `evidence/r27-husky-defaults.log:5`, `:20-21`, `:29-30` and `:40`, retrieved 2026-09-27). `doublify/pre-commit-rust` (204 stars) runs `entry: cargo fmt` in write mode and fails the commit when the hook modifies files (`raw/opus.md:123-129`, `raw/opus.md:801-802`; figures carried from the Opus leg, dated 2026-09-26). The recommended check-and-block job therefore matches the hook-template field and never restages.

The whole-workspace check has two observed working-tree interactions:

- lefthook 2.1.14 hides the unstaged part of a **partially staged** file, so the check read the staged bytes and blocked (A-H5).
- lefthook does **not** hide a file that has only unstaged changes. An unrelated unstaged unformatted edit therefore blocked a commit whose staged content was formatted (A-H6). This is a conservative false block, fixed by `just format` or by stashing, and never a false pass. It corrects the Opus leg's unqualified statement that lefthook hides unstaged changes (`raw/opus.md:782-784`).

The ts write mode does not transfer to Rust. ts can restage because `oxfmt` accepts `{staged_files}` (`raw/opus.md:789-791`). Under R42's invocation rule the formatter is called as `cargo fmt`, which cannot be scoped. Naming one file still checked and rewrote another (W1, W2), and the `stage_fixed` job rewrote a file the contributor never staged (C-H6). The ts shape stays a justified ecosystem difference for ts; it is not drift.

**Composite placement (F102).** Both legs include the check in the composite, ahead of compile-heavy steps (`raw/muse.md:730-732`, `raw/opus.md:905-907`). This decision adopts that. The recipe runs in 0.54 s on the scratch workspace (C2.8).

**`--all`.** The Muse leg writes `cargo fmt --check` (`raw/muse.md:213-215`); the Opus leg writes `cargo fmt --all --check`. At the workspace root the two forms agree. From a member directory, the plain form passed a tree with an unformatted file in another member, and `--all` failed it (C2.2). `--all` removes the dependence on the working directory, so every surface uses it.

**Cross-repo rationale for the follow-on project (py and ts are not changed here).** Both legs agree on the substance: py's `line-ending = "auto"` (F089) and py's composite omitting the format check (F102) are accidental drift against the shared capabilities; ts conforms to both (`raw/muse.md:158-161`, `raw/muse.md:173-176`, `raw/opus.md:263`, `raw/opus.md:265`). Every other row difference is a justified ecosystem difference: width, trailing comma, import mechanism, pin artefact and hook mode. **These are recorded as follow-on rationale, not as `BASELINE-REVIEW:` lines.** `research/RUNBOOK.md:18-22` scopes that form to REUSE and ADOPT baselines. Every row here is `DIVERGENT` and keeps its classification, and the prompt assigns py and ts changes to a follow-on project (`inputs/prompt.md:38`). The Opus leg's py line citations (`pyproject.toml:209`, `Justfile:277`, `.github/CONTRIBUTING.md:32`) are carried and **not re-verified**, because py is outside this synthesis's read scope. The controller may lift either item into a `BASELINE-REVIEW:` line under `research/RUNBOOK.md:178`.

**Handoffs (inputs to other items, not `CONFLICT:` lines).**

| Item | What this decision hands over |
|---|---|
| R42 | the `channel = "1.98.1"` value for its file; `profile` and `components` unchanged. The C4.4 `PATH` hazard defeats any pin |
| R11 | the `hygiene` step body is `format-check`'s; nothing in it compiles |
| R19 | `.github/dependabot.yml` needs a `rust-toolchain` entry to keep the exact channel current (F8) |
| R28 | the shared `clippy` component; outcome (ii) above if clippy gains a path list |
| R37 | the formatter job is blocking with no `glob` and no `stage_fixed`; the hook manager is assumed to be lefthook |
| R29 | `rustfmt.toml` and `rust-toolchain.toml` are TOML files in its scope; this decision fixes their keys, not their layout |

re-verify: 2027-03-26, or earlier on any of — each Rust stable release, which is the channel-bump pull request, re-running `cargo fmt --all --check` and `just format-check` on the new channel; the first CI run on `ubuntu-latest`, the runner this synthesis never exercised; a rustfmt release that stabilizes `ignore`, `imports_granularity`, `group_imports` or `trailing_comma`, or changes a stable default, re-running `evidence/r27-config-surface.sh`; a new Rust edition or style edition, which must update both `edition` and `style_edition` in `rustfmt.toml`; R28 publishing a clippy path list, which triggers outcome (ii); R42 changing its invocation rule to allow a bare `rustfmt`, which reopens a file-scoped hook, or changing `profile`/`components`; R11 moving non-compiling checks out of `hygiene`; R37 choosing a hook manager other than lefthook, or lefthook changing how it hides unstaged changes of partially staged files; R19 declining the `rust-toolchain` Dependabot entry, which leaves the exact channel without an upkeep path and reopens the runner-up; R32, R33 or R71 committing intentionally unformatted `.rs` fixtures or generated modules, which must be named in the reachability guard

## Parameters

R27 owns no registry parameter: the prompt's `## Couplings` block has an empty `- owns:` line (`inputs/prompt.md:25`). It consumes R11's `ci-job-structure` and R42's `package-manager-invocation` (`inputs/prompt.md:26`). The values below are copied from the run's snapshot `inputs/parameters.json`, and both prerequisite decisions match the hashes in `inputs/prerequisites.json`. No recommendation needs a registered value changed, so there is no `CONFLICT:` line.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner
- assumes package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component

## Empirical check

**Host and toolchains, each read from the tool.** macOS 26.4, `Darwin 25.4.0 arm64`. `rustup 1.29.1`. Rust toolchains, all selected under the restricted `PATH=$HOME/.cargo/bin:/usr/bin:/bin` so that the rustup proxy resolves before Homebrew:

| Build | rustc | rustfmt | clippy |
|---|---|---|---|
| rustup `1.93.0` | 1.93.0 | `1.8.0-stable (254b59607d 2026-01-19)` | 0.1.93 |
| rustup `stable` | 1.94.0 | `1.8.0-stable (4a4ef493e3 2026-03-02)` | 0.1.94 |
| rustup `1.96.0` | 1.96.0 | `1.9.0-stable (ac68faa20c 2026-05-25)` | not installed |
| rustup `1.96` | 1.96.1 | `1.9.0-stable (31fca3adb2 2026-06-26)` | 0.1.96 |
| Homebrew `/opt/homebrew/bin` | `1.98.1 (48a229cea 2026-09-01) (Homebrew)` | `1.9.0` | — |

Also: lefthook 2.1.14, `just` 1.51.0, `git` 2.50.1, `gh` 2.101.0, `jq-1.8.2`, ShellCheck 0.11.0 (`/opt/homebrew/bin/shellcheck`). `CARGO_HOME=/tmp/cargo-s9-R27` (private). Every script sets `RUSTUP_AUTO_INSTALL=0`, so a missing toolchain is an error rather than a download (pre-validated: pinning `1.98.1` printed `error: toolchain '1.98.1-aarch64-apple-darwin' is not installed`, exit 1). No rustup install ran. **This is not current stable under rustup, and not Ubuntu:** the 1.98.1 checks used Homebrew's build of rustfmt, and `ubuntu-latest` was not exercised.

**Commands and working directory.** Each check is one script run from the repository root. Each script builds its own scratch tree under `$TMPDIR/r27s/` and writes nothing into the repository except its own log. C1 and C2 write the recommended `rustfmt.toml` byte for byte (sha256 `a714037d…`); C3 and C4 write the same five keys without the comment lines:

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan
E=research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/evidence
for c in r27-config-surface r27-workspace-scope r27-hook r27-channel-pin r27-figures; do
  shellcheck "$E/$c.sh" && "$E/$c.sh" > "$E/$c.log" 2>&1; echo "$c exit=$?"
done
```

`shellcheck` exits 0 with no finding on all five scripts. The four assertion scripts exit 0: **101 assertions, 101 pass, 0 fail, 0 skipped**. `r27-figures.sh` records observations and makes no assertions.

**Revision 3.** The new observation-only script ran once into its own log, `"$E/r27-husky-defaults.sh" > "$E/r27-husky-defaults.log"`; `shellcheck` exits 0 on it and it exits 0. The five scripts above were rerun into a scratch directory, `/tmp/r27-r3-rerun/`, with a private `CARGO_HOME=/tmp/cargo-s35-R27-r3`, and compared with `cmp`; the committed logs were not overwritten. All five pass `shellcheck` and exit 0, and the four assertion scripts again give **101 assertions, 101 pass, 0 fail, 0 skipped**. `r27-config-surface`, `r27-hook` and `r27-channel-pin` reproduce byte for byte. `r27-workspace-scope` differs only in the C2.8 wall-clock lines (`just format-check` 0.28 s against 0.54 s; the "under 5 s" assertion passes). `r27-figures` differs only in live data bound to its retrieval stamp (rustfmt 6,975 stars against 6,974; issue #7138 answered after the original retrieval, giving 2 answered and 8 unanswered). No claim here rests on the rerun values; F2 and F4 are quoted as of `evidence/r27-figures.log:1`.

| Check | Script / log | Assertions | Observed |
|---|---|---|---|
| C1 config surface | `r27-config-surface` | 65 / 65 | The recommended file, byte for byte, gives exit 0, zero warnings and empty output on all four rustfmt builds (C1.1). Each recommended key alone is silent on all four (C1.2). `trailing_comma`, `imports_granularity`, `group_imports`, `imports_layout` and `ignore` each print `Warning: can't set …, unstable features are only available in nightly channel.` while exiting 0 (C1.3). A file listed in `ignore` is still diffed, exit 1 (C1.3b). Bare `rustfmt --check` rejects a let-chain with `let chains are only allowed in Rust 2024 or later` under no config and under `style_edition` alone, and parses it under `edition = "2024"` (C1.4). `cargo fmt` runs `rustfmt --edition 2024` over a `rustfmt.toml` that says `2021` (C1.4b). A CRLF file fails with `Incorrect newline style` under `Unix` and passes under `Auto`; imports come out as `HashMap; fmt; io::{Read, Write}`; a struct gains `pub b: u32,`; and `max_width = 100` output is byte-identical to the default (C1.5) |
| C2 workspace scope | `r27-workspace-scope` | 14 / 14 | Root package, members `crates/core` and `crates/web`, plus `tests/`, `examples/` and `build.rs`, pinned by the recommended file shape at channel `1.96`. `just format-check` exits 0 and reaches all 6 tracked files (C2.1). With an unformatted web member: from the root, both `cargo fmt --check` and `--all` exit 1; from `crates/core`, the plain form exits **0** and `--all` exits 1 (C2.2). `[workspace] exclude` leaves `vendor/legacy` untouched, and the guard names it (C2.3). `#[rustfmt::skip] mod generated;` passes the check and leaves the file untouched, and the guard names it (C2.4). An orphan file and a macro-declared module pass `cargo fmt --all --check` with exit 0, the module compiles, and the guard names both (C2.5). `imports_granularity` leaves `cargo fmt` at exit 0, while the recipe fails with `rustfmt.toml sets a key this toolchain ignores` (C2.6). An unformatted file makes the recipe exit 1 and `just format` repairs it (C2.7). `cargo fmt --all --check` takes 0.08, 0.07 and 0.07 s on three runs, and `just format-check` 0.54 s (C2.8) |
| C3 hook | `r27-hook` | 13 / 13 | Real `git commit` with lefthook-installed hooks. Variants A (recommended) and B (`glob: "*.rs"`): a staged unformatted file is rejected with its bytes unchanged (H1); a formatted file is accepted (H2); a README-only commit is accepted, with A's job running and B's skipped (H3). A config-only change to `max_width = 40` is **rejected by A and accepted by B** (H4). A, partially staged file with an unformatted index and a formatted working tree: rejected, with the unstaged bytes restored (H5). A, formatted staged change plus an unrelated unstaged unformatted edit: rejected (H6). C, the write mode with `stage_fixed` in the H6 situation: accepted, with `src/web.rs` rewritten in the working tree but absent from the commit (C-H6). `cargo fmt -- --check src/web.rs` still diffs `lib.rs` (W1), and `cargo fmt -- src/web.rs` rewrites `lib.rs` (W2) |
| C4 channel pin | `r27-channel-pin` | 9 / 9 | `channel = "1.93.0"` and `"1.96"`, each with `profile = "minimal"` and both components: `rustup show active-toolchain` reports `(overridden by '…/rust-toolchain.toml')`, both components are installed, and the check exits 0 (C4.1). `"stable"` resolves to rustc 1.94.0 (C4.2). `"1.98.1"` fails with `is not installed`, exit 1 (C4.3). With `/opt/homebrew/bin` first on `PATH`, `cargo fmt --version` prints `rustfmt 1.9.0` in a directory pinned to 1.93.0 while rustup still reports the override (C4.4). The four rustfmt builds give identical output, sha256 `a251383e89c8906f…` (C4.5). Clippy has 806 / 811 / 819 lints and 410 / 408 / 414 warn-by-default on 1.93.0 / 1.94.0 / 1.96.1; six warn-by-default lints are new in 1.96.1 against 1.94.0, including `clippy::manual-take` and `clippy::manual-pop-if` (C4.6) |
| F figures | `r27-figures` | — | One call per endpoint, no polling, `NO DATA` on failure (none occurred). F1: `1.98.1` published 2026-09-03T13:14:07Z. F2: rustfmt 6,974 stars, `archived=false`, `pushed_at=2026-09-24T13:36:12Z`. F3: 718 open issues. F4: responsiveness 1 answered after 0.6 days, 9 unanswered. F5: toolchain files — uv `1.98.1`, ruff `1.98.0`, zed `1.98.1`, cargo-binstall `stable`, nushell `1.96.1`. F6: no `rustfmt.toml` in tokio, clap, serde or rust-lang/crates.io; stable-only files in uv, ripgrep, just, tauri and cargo. F7: tokio `ci.yml:846` runs `rustfmt --check --edition 2021 $(git ls-files '*.rs')`. F8: `dependabot-core` has `rust_toolchain/`. F9: crates.io figures. F10: RustSec pages return HTTP 404 for all four names |
| F11 cargo-husky defaults (revision 3) | `r27-husky-defaults` | — | One call per file, `NO DATA` on failure (none occurred). `Cargo.toml` `[features]` line 28: `default = ["prepush-hook", "run-cargo-test", "run-for-all"]`; `run-cargo-fmt = []` is a separate, opt-in feature (line 35). `build.rs:132-134` adds `cargo test` under `run-cargo-test`; `build.rs:141-142` adds `cargo fmt` with `--check` only under `run-cargo-fmt`; `build.rs:301` selects the pre-push hook under `prepush-hook` |

**What no check here establishes.** No GitHub Actions job ran, and nothing ran on `ubuntu-latest`. The pinned value `1.98.1` was never selected through rustup; Homebrew's 1.98.1 rustfmt stood in for the config checks only. The runner download cost of an exact pin is unmeasured. Dependabot's `rust-toolchain` updates were not exercised; only the ecosystem's existence was read (F8). Clippy's own configuration and exclusion behaviour belong to R28 and were not tested. The timing figures come from a six-file scratch workspace on one host, not the template.

## Engines

**The two reports.**

- Muse (`muse-spark`, Meta) — `raw/muse.md`, sha256 `cef378c1a4d836b923b9f420a05a146b06a44f5d87f0b4b2908f820cebfc326c`, 1,186 lines, dated 2026-09-26 (`raw/muse.md:3-4`). It recommends rustfmt; a four-key file (`max_width`, `newline_style`, `reorder_imports`, `style_edition`); `channel = "stable"`; no exclusions and no drift test; the composite includes `cargo fmt --check`; and a blocking hook (`raw/muse.md:207-231`). It reports no `BASELINE-REVIEW:` and no `CONFLICT:`.
- Claude Opus 5 (`claude-opus-5-5`) — `raw/opus.md`, sha256 `1f99cfaf16b6145972f2a0bdc0eb4c9c06468573c48f27b57adb50491b40f4bd`, 1,097 lines, dated 2026-09-26 (`raw/opus.md:3-5`). It recommends rustfmt; a four-key file (`edition`, `style_edition`, `max_width`, `newline_style`); `channel = "1.98.1"` with R42's profile and components; structural scope; a blocking hook with `glob: "*.rs"`; `format-check` first in the composite; and two proposed guards (`raw/opus.md:269-291`). It carries two `BASELINE-REVIEW:` lines, F102 and F089, and no `CONFLICT:`.

**Evidence checks.** C1–C4 and F (F11 added in revision 3), all written and run in this synthesis (`## Empirical check`). Neither leg's scratch trees or logs were available or used.

**Disagreements and how each was settled.**

| # | Topic | Muse | Opus | Settled | By |
|---|---|---|---|---|---|
| 1 | channel | `stable`: "There is no version number to float or pin: `cargo fmt --version` reports the component build of the active toolchain, and the only selectors rustup offers are the channel (`stable`, `beta`, `nightly`, or a dated/archive version) and the component set." (`raw/muse.md:801-805`); exact pin rejected as unneeded rigidity (`raw/muse.md:834-837`) | `1.98.1` (`raw/opus.md:718-723`) | **Opus** | C4.1 (mechanism works), C4.2–C4.3, C4.6, F1, F5, F8; C4.5 concedes the formatter-only point to Muse |
| 2 | `edition` key | omit (`raw/muse.md:419`) | set (`raw/opus.md:474-478`) | **Opus** | C1.4, C1.4b |
| 3 | `reorder_imports` key | set (`raw/muse.md:481`) | default, not written | **Muse** | C1.2; the legibility argument both legs apply to `max_width` |
| 4 | `--all` | `cargo fmt --check` (`raw/muse.md:213-215`) | `cargo fmt --all --check` | **Opus** | C2.2 |
| 5 | hook `glob` | none (`raw/muse.md:989-990`) | `glob: "*.rs"` (`raw/opus.md:835`) | **Muse** | C3 A-H4 vs B-H4 |
| 6 | "every `.rs` file covered" | asserted (`raw/muse.md:127-129`) | scope hazard (`raw/opus.md:242-249`) | **Opus** | C2.5 |
| 7 | exclusion mechanism | none, plus `#[rustfmt::skip]` (`raw/muse.md:572-575`) | `[workspace] exclude` + `#[rustfmt::skip]` (`raw/opus.md:285-287`) | **neither as a silent mechanism**: no exclusions, and the guard surfaces any | C2.3–C2.5 |
| 8 | guards | none | proposed, not run (`raw/opus.md:1044-1052`) | **Opus, now executed** | C2.3–C2.6 |
| 9 | lefthook hides unstaged changes | — | stated unqualified (`raw/opus.md:782-784`) | **corrected**: partially staged files only | C3 A-H5, A-H6 |
| 10 | `profile = "minimal"` | absent (`raw/muse.md:859-863`) | R42's (`raw/opus.md:721`) | **R42's value**; it is not this item's to change | `research/topics/42-dev-toolchain-provisioning/DECISION.md:26` |
| 11 | recipe names | `fmt`/`fmt-check` (`raw/muse.md:1100-1102`) | `format`/`format-check` | **Opus** | `inputs/prompt.md:4` names `format` |
| 12 | `BASELINE-REVIEW:` form | none (`raw/muse.md:192-194`) | F102, F089 (`raw/opus.md:263`, `:265`) | **substance agreed; recorded as follow-on rationale** | `research/RUNBOOK.md:18-22` |
| 13 | host toolchain | "rustc 1.98.1 with rustfmt 1.9.0 on the active stable toolchain" (`raw/muse.md:7-8`) | rustup `stable` is 1.94.0; Homebrew shadows rustup (`raw/opus.md:18-25`) | **Opus**: Muse measured Homebrew's build | C1 header, C4.2, C4.4 |
| 14 | practice sample | 4 of 5 ship no config, so "defaults" is the standard (`raw/muse.md:76-78`) | 13 of 20 have a config (`raw/opus.md:116-117`) | **both samples are correct; the larger one governs the generalization** | F6 confirms the four absences and five stable-only files |
| 15 | issue responsiveness | 3 answered, median ~0.23 days (`raw/muse.md:276-279`) | 1 answered, 0.6 days (`raw/opus.md:334-338`) | **Opus's figure reproduced** under the stated `author_association` rule; Muse's rule is unstated | F4 |

**Smaller corrections.** Both legs give `rustfmt-nightly`'s newest release as 1.4.21 (`raw/muse.md:283`, `raw/opus.md:53`). By `created_at` over non-yanked versions, the newest is 1.4.20 at 2020-09-06T02:12:50Z (F9). Either way, the crate has been dormant since 2020-09-06. Download counts moved by small amounts between the legs' fetches and this one (F9); the retrieval date is on each.

**Carried and not re-verified (read scope).** Everything the Opus leg cites from R19's decision (`raw/opus.md:713-714`, `raw/opus.md:745-748`), from `docs/port/DIVERGENCE-ANALYSIS.md` and `docs/port/BASELINE-REVIEW.md`, and from the py and ts source repositories. The same applies to the Muse leg's citations of those documents. The Opus leg's reading that `topiary-queries` lists `rust` (`raw/opus.md:50`) contradicts the Muse leg's "no Rust support evidenced" (`raw/muse.md:307-309`). It was not re-fetched, and it does not matter here: topiary is excluded on fit and adoption either way.

**What P03 must validate.** The five files above in the real template. `cargo fmt --all --check` and `just format-check` exiting 0 on `ubuntu-latest` and `macos-latest` under channel `1.98.1`. `rustup show active-toolchain` naming the committed file on both runners. The three hook cases (H1, H4, H6) through installed hooks. The runner download time of the pinned toolchain. Dependabot opening a channel-bump pull request once R19 adds the entry.

**Uncertainty.** High for the tool, the config keys, the scope rule, the hook mode and the composite placement: each was executed, on the recommended bytes where bytes matter. Medium for the channel value: the mechanism executed and the value did not, and its upkeep depends on R19. The false block in A-H6 is a known, conservative limitation of a whole-workspace hook.
