# 2026-09-27 — R30 — type-check-gate (bundle, Focused) — decision (revision 3)

**Revision note, revision 3.** Revision 2 (sha256 `d15d4cee636494fac69c6996017c9c099860dad8b1c205d1b45fbde7ac86d687`, preserved verbatim at `review/R30-r2-snapshot.md`, `I-r2-snapshot`) drew two rejects, one finding each. **The recommendation, all seven stack members, the eight settled rows, every disagreement resolution and every acceptance criterion do not move.** This revision makes four changes:
- **Judgment audit, finding 1 (JF-5, `review/audit-fable.r2.md`).** Revision 2 handed the toolchain pin to R42 and never told anyone that member 3 needs Cargo ≥ 1.97. R42 is published and disclaims the channel: "The `channel` **value** is R27's through F103/F190 and is not set here" (R42 `DECISION.md:26`). The R27 prompt claims it: "The file's `channel` and `components` are decided here (F103)" (R27 prompt `:14`). This revision re-routes the pin hand-off to **R27 (F103)** and adds the constraint that the channel the recipe, hook and `check` job run on must carry Cargo ≥ 1.97, because `CARGO_BUILD_WARNINGS=deny` is inert below it (`W1`). It does not choose R27's value. R42 keeps the file and its components. The changed places are the versions line, member 3, the severity bullet, the `msrv-policy` bullet under `## Parameters`, the cost bullet of disagreement D1, the hand-offs and the re-verify line (`I-jf5`).
- **Empirical audit, finding 1 (I-policy, `review/audit-claude.r2.md`).** After revision 2 was written, the live `research/EXECUTION.json` gained 44 `empirical_auditor_overrides` entries, R30 among them, so the frozen copy no longer matched and `I-policy` failed (36 of 37). This revision re-freezes `inputs/EXECUTION.json` to the live file (`acdcbfff…`) and records what the added entry means for this item under `## Engines` (`I-eao-r30`). No seat or engine claim changes.
- It reruns all seven evidence scripts once, sequentially, and re-derives every timing, log timestamp and path in this file from those logs. Host load was far higher than in revision 2's pass (1-minute load 75.62 before, 102.40 after, against 4.65 and 5.36). The cold gate took 16.01 s, and one hook commit took 0.69 s. **Revision 2's statement that every hook commit stayed under 0.6 s is therefore withdrawn**; this file now states the measured range and "under 1 s" for this pass. The empirical auditor's rerun of revision 2, at a 1-minute load of about 250, measured 0.56–2.41 s for `H3a`–`H3f` and 11.36 s cold (`review/audit-claude.r2.md`, "Figures and inputs re-derived at source"). The hook-tier resolution (D5) does not move; the reasoning is under D5 and gap 10.
- `review/evidence/r30-inputs.sh` gains checks for the new citations (`I-r42-channel`, `I-r27-f103`), for the absence of the old R42 routing (`I-jf5`), for the revision-2 snapshot, and for the overrides entry. Its expected `CARGO_HOME` and its stale-figure list now match revision 3.

**Revision note, revision 2.** Revision 1 (sha256 `bde05533efb747334a6f79755706c0ad964bb0e720adaa96d1c9a528c62ba45c`, preserved verbatim at `review/R30-r1-snapshot.md`, `I-r1-snapshot`) drew two rejects. The judgment audit (`review/audit-fable.md`, findings 1–5) and the empirical audit (`review/audit-claude.md`, findings 1–4) found the same defect: four timing figures in the prose (6.11 s cold, 0.18–0.26 s incremental, 0.26–0.56 s per hook commit, 0.26 s for clippy after the gate) and the stated log timestamps and `CARGO_HOME` did not match the committed logs. The judgment audit traces the cause to the files' timestamps: revision 1 refreshed only its excerpt block after its final rerun and kept an earlier pass's figures in the prose. **The recommendation, all seven stack members, the eight settled rows, every disagreement resolution and every acceptance criterion do not move.** This revision makes three changes:
- It reruns all seven evidence scripts once, sequentially, and re-derives every timing, timestamp and path in this file from those logs in one pass. The new figures differ from both revision 1's prose and its logs, because timings vary between runs; every one stays sub-second warm.
- It adds `review/evidence/r30-inputs.sh`, which checks each quoted figure against its case's `wall-clock:` line (`I-fig-*`), every excerpt line against the logs (`I-excerpt`), the log headers (`I-hdr-*`), and the inputs and shape checks below. Revision 1 had no mechanical check between prose figures and logs; this is the class of defect the audits found.
- It re-freezes `inputs/prompt.md` and `inputs/EXECUTION.json` to the live files, which now record the Muse-for-Codex substitution, and cites owner decision Q17.A as the authority for it (see `## Engines`).

Nothing has been published for R30, so there is no `## Supersedes`.

**Revision note, revision 1.** This is the first synthesis of R30. There is no prior revision, no audit, and nothing superseded. The recommendation below is the synthesizer's; neither raw report recommends it exactly as written. The Opus report comes closest. The synthesis departs from it on one point that a fresh check decided (disagreement **D3**, the feature scope of the gate).

Item R30 (`type-check-gate`, kind `bundle`, Focused tier, owns no parameter, consumes `R11: ci-job-structure`). Run `research/runs/R30/2026-09-26T190200Z-c5c1105074c1`. Synthesizer of revision 1: a fresh context in the Opus seat (`claude-opus-5-5`, CLI), which produced neither raw report. Synthesizer of revision 2: another fresh context in the Opus seat (`claude-opus-5-5`, CLI), which produced neither raw report nor either audit and read the two audits as its job input. Synthesizer of revision 3: another fresh context in the Opus seat (`claude-opus-5-5`, CLI), which produced neither raw report nor any audit and read only the two revision-2 audits (`review/audit-fable.r2.md`, `review/audit-claude.r2.md`) as its job input. Inputs, with sha256:

| Input | sha256 |
|---|---|
| `inputs/prompt.md`, re-frozen in revision 2; byte-identical to the live `research/topics/30-type-check-gate/prompts/type-check-gate.prompt.md` (`I-prompt`). Revision 1's frozen copy was `a883b22d…`; the live prompt since gained `- engines: muse, opus` and one substitution sentence | `2c83ee19a44b571265d1ab29db7470ed90eaad4f704a9b036ed9badbf85250de` |
| `inputs/EXECUTION.json`, re-frozen in revision 3; byte-identical to the live `research/EXECUTION.json` (`I-policy`). Revision 1's frozen copy was `2a3ca155…` and revision 2's was `c670184d…`. The only difference from revision 2's copy is 44 added `empirical_auditor_overrides` entries (6 to 50), all `"claude"`, R30 among them; no entry was changed or removed. The live file is a working-tree edit: `HEAD:research/EXECUTION.json` is `ac4561fe…` (see gap 11) | `acdcbfff5fa46a68cd0999147b294e41fa6c4d6c88428c9fc7c46cdedfabf137` |
| `raw/muse.md` (301 lines; the Codex seat, filled by Muse — see `## Engines`) | `7661d2e338ecb9aaed6867a4da9ed0bbcfa968da12f0de215ba8f17df7db4665` |
| `raw/opus.md` (1130 lines) | `bbda3effca84026560506c1082c870322a69ebe9d70ec32ecb1109d56f2540cc` |
| `inputs/parameters.json` | `15e7e98ec46a110e555959e48c1b87e042f43397d6264a5d82ae17b848b231cd` |
| `inputs/prerequisites.json` | `63a5620cfc9d15f77870d405f34fadf5be1a5f7fe0b0b6ffcfbee2590ce864b8` |
| `research/topics/11-ci-workflow-job-structure/DECISION.md` (R11 revision 7, the one consumed prerequisite) | `410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c`, matching `prerequisites.json`; R11 `acceptance.json` `774f76490a7f968960e71f5e1e38866592a064e3c17a453dd5223add0628eac1`, also matching |

Both raws date their retrievals 2026-09-26. Every check under `## Empirical check` was rerun fresh by revision 3 on 2026-09-27 (Pacific). The logs stamp UTC: of the seven evidence-script headers, the first reads `run 2026-09-27T07:24:53Z` (`r30-lints.log:1`) and the last reads `run 2026-09-27T07:25:58Z` (`r30-wiring-severity.log:1`) (`I-hdr-utc`). `r30-inputs.sh` runs after them, after this file is written, and stamps its own log. Citations of the form `muse.md:N` and `opus.md:N` refer to line N of `raw/muse.md` and `raw/opus.md`. Citations of the form `S4`, `W3d`, `X9a`, `L2b` and `H3e` are case identifiers in the evidence logs under `review/evidence/`.

## Decision

**Recommendation.** The Rust compiler, invoked as `cargo check`, is the CI-authoritative type checker. There is no wrapper and no second checker. What survives from the py and ts precedent is not "add a type checker". It is a **named, cheap, explicit gate**: one `typecheck` recipe that runs the same two commands in the Justfile, in the pre-commit hook, and as ordered steps of R11's `check` job. The two commands are:

```bash
CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --locked --keep-going
CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --all-features --locked --keep-going
```

The first command type-checks the default configuration, where `web` is off. The second type-checks every feature on. Both are needed, because each configuration contains diagnostics the other cannot see (`S4`, `S5`, `S6`). Every lint warning from a workspace package fails the gate through Cargo's `build.warnings` setting. Plain `cargo check`, `cargo build` and the editor stay lax. Strictness is declared once, in `[workspace.lints.rust]`. Suppressions name their lint, and `#[expect(lint, reason = "...")]` is the house form.

**Versions.** No crate is added. The stack is Cargo and rustc from the toolchain whose `channel` R27 settles under F103 in the `rust-toolchain.toml` that R42 commits (R42 `DECISION.md:26`; R27 prompt `:14`). One member has a version floor: `build.warnings` needs Cargo ≥ 1.97, stabilized in Cargo 1.97 (2026-07-09) (`r30-upstream-docs.log`, `CHANGELOG.md:394`, `:399`). Below 1.97 the variable is silently inert (`W1`, `W2`). On R11's `msrv-floor` job, which runs the declared 1.96 floor, that is acceptable, because that job proves compilation, not warning-cleanliness (R11 `DECISION.md:227`; disagreement **D1**). On the recipe, the hook and the `check` job it is not acceptable, so the channel R27 settles must carry Cargo ≥ 1.97; that constraint is handed to R27 under `### Hand-offs`.

### The recommended stack

| # | Member | What the template ships | Deciding evidence |
|---|---|---|---|
| 1 | **Engine** | rustc via `cargo check`; no wrapper crate, no second checker; rust-analyzer's default flycheck (`check_command = "check"`, `config.rs:891`) is the editor side | `S1`–`S6`, `H4b`; upstream `config.rs:884`, `:891` |
| 2 | **Scope** | `--workspace --all-targets`, run twice: default features, then `--all-features`; `--locked` (R11's rule for every cargo command); `--keep-going`. Doctests are out of scope and handed to R32 | `S1`–`S3` (targets), `S4`–`S6` (both configurations), `S7` (doctests), `S8` (`--keep-going`) |
| 3 | **Severity** | a single failing tier through `CARGO_BUILD_WARNINGS=deny`. It is set only as an environment variable on the recipe lines, the hook jobs and the CI steps. It is never set in a committed `.cargo/config.toml`, never as `#![deny(warnings)]`, and never as a `[lints]` entry. It denies only when the running Cargo is ≥ 1.97; the recipe, hook and `check` job must therefore run on such a channel (R27's F103; see `### Hand-offs`). Runner-up: `RUSTFLAGS="-D warnings"`, which also denies on older Cargo | `W1`–`W4`; through the real recipe and hook `V1b`, `V1c`; Cargo guide `continuous-integration.md:207-210` |
| 4 | **Strictness** | root `Cargo.toml` `[workspace.lints.rust]` with `rust_2018_idioms = { level = "warn", priority = -1 }`; `[lints] workspace = true` in **every** package, the root package included | `L1a`–`L1f`, `L0a`–`L0b`; `manifest.md:532`, `:553` |
| 5 | **Suppression** | `#[expect(<lint>, reason = "...")]` by default. A lint that fires in only one feature configuration is suppressed with `#[cfg_attr(<that configuration>, expect(<lint>, reason = "..."))]`. `#[allow(<lint>, reason = "...")]` is used only where the firing condition cannot be written as a `cfg`. `allow(warnings)` is never allowed; mechanical enforcement is handed to R28/R40 | `X1`–`X12`; `levels.md:37`, `:278` |
| 6 | **Hook tier** | lefthook **pre-commit**, running the same two commands with the same variable | `H2a`–`H2f`, `H3a`–`H3f`, `V1c`, `V2b`, `V3` |
| 7 | **CI** | two ordered steps of R11's `check` job, ahead of the clippy steps, each `if: ${{ !cancelled() }}` with step-level `CARGO_BUILD_WARNINGS: deny` | R11 `DECISION.md:278`, `:286`; `H1b` |

The template files, as proposed. Not executed in the template, which does not yet exist. The same text ran in the synthetic workspace of `r30-wiring-cost.sh`, which is exercised by `H1`–`H3`.

Root `Cargo.toml` (other items append their own entries to the same table; `unsafe_code` is R06's, `clippy::` entries are R28's):

```toml
[workspace.lints.rust]
rust_2018_idioms = { level = "warn", priority = -1 }
```

Every package's `Cargo.toml`, the root package included (`L1a`: a member without this block silently ignores the table):

```toml
[lints]
workspace = true
```

`Justfile`:

```just
# Type-check every target in both feature configurations; lint warnings from workspace packages fail
[group('dev')]
typecheck:
    CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --locked --keep-going
    CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --all-features --locked --keep-going

alias tc := typecheck
```

`lefthook.yml`. Whether the jobs repeat the commands, as here, or call `just typecheck` is R37's decision; see disagreement **D6**.

```yaml
pre-commit:
  jobs:
    - name: typecheck (default features)
      env:
        CARGO_BUILD_WARNINGS: deny
      run: cargo check --workspace --all-targets --locked --keep-going
    - name: typecheck (all features)
      env:
        CARGO_BUILD_WARNINGS: deny
      run: cargo check --workspace --all-targets --all-features --locked --keep-going
```

`.github/workflows/ci.yml`. Two steps inside R11's `check` job. R11 owns the job; this item supplies the steps.

```yaml
      - name: typecheck (default features)
        if: ${{ !cancelled() }}
        env:
          CARGO_BUILD_WARNINGS: deny
        run: cargo check --workspace --all-targets --locked --keep-going
      - name: typecheck (all features)
        if: ${{ !cancelled() }}
        env:
          CARGO_BUILD_WARNINGS: deny
        run: cargo check --workspace --all-targets --all-features --locked --keep-going
```

`CONTRIBUTING.md`: one "Suppressing a lint" paragraph that states member 5.

### Settled ledger rows

The rows this item decides are F105–F108 and F110–F113, as the prompt quotes them. F109, the editor extension, is R28's. The ledger's own row text lives in `docs/port/COMMONALITY.md`, which is outside this synthesis's read set. Rows are identified through `inputs/prompt.md`.

| Row | Settled value for rs | Evidence |
|---|---|---|
| **F105** engine | `rustc` via `cargo check` is the CI-authoritative type checker. No wrapper and no second tool. A distinct named `typecheck` recipe and CI steps exist anyway (ts D-015(1) shape), because the gate must be invocable, attributable, and independent of R28's lint policy | `S1`–`S6`, `H4a`, `H4b`; option table below |
| **F106** hook tier | **pre-commit** (ts's tier), from measured cost | `H2b`–`H2f`: warm no-op 0.12–0.14 s (`H2b`, `H2c`), incremental 0.22–0.49 s (`H2d`–`H2f`); `H3e`/`H3f`: a real commit through the installed hook takes 0.49–0.69 s wall-clock (`r30-wiring-cost.log:168`, `:184`) |
| **F107** one engine for editor and CI | yes, by default: rust-analyzer's check-on-save runs `cargo check` (`config.rs:884`, `:891`) with all targets (`:787`) across the workspace (`:962`). Feature parity is **not** default, because the editor checks default features (`:847`). What it then misses depends on the package layout. Under R69's registered row, where `src/web/` is a module of the feature-gated crate, the editor shows no web error at all. Under R02's owner-accepted four-package layout, where `crates/web` is a workspace member that `--workspace` compiles with the feature off (R11 `DECISION.md:221`), the editor does check `crates/web`; it misses the facade's `#[cfg(feature = "web")]` items, the serve binary (`required-features`) and file-level `#![cfg(feature = "web")]` tests. The Rust analogue of ts's `tsdk` pin (D-032) is a rust-analyzer features setting, which is R28's to commit or not | upstream `config.rs` lines in `r30-upstream-docs.log`; `S4` shows what a default-features check misses in the single-crate layout |
| **F108** second, IDE-only checker | none. rust-analyzer's native diagnostics are advisory, and no gate runs them | both raws agree (`muse.md:26`, `opus.md:178-181`) |
| **F110** opt-in strictness | `[workspace.lints.rust]` in the root `Cargo.toml`, inherited per package. rustc's type rules have no strict mode to opt into. The one entry this item contributes is `rust_2018_idioms` at `warn`, `priority = -1` | `L1a`–`L1f`; `L0a` shows what the entry does **not** add |
| **F111** suppression discipline | every suppression names its lint (the syntax forces it, `X1`). Unknown names and unfulfilled expectations fail the denying gate (`X3`, `X4`). `#[expect(lint, reason)]` is the house form. The one unclosed hole is `#![allow(warnings)]` (`X6`) | `X1`–`X12` |
| **F112** warning-vs-error tier | a single failing tier in the gate, and lax everywhere else. There is no py-style "warnings inform" tier inside the gate. A lint that must only inform is set to `allow` in the table instead | `W1`–`W4` |
| **F113** scope includes tests | yes: `--all-targets` (lib, bins, `#[cfg(test)]`, `tests/`, examples, benches) in **both** feature configurations. Doctests are the one exception, handed to R32 | `S1`–`S7` |

### Principles and implementation

**Shared principle** (prompt `## Context`; spec §2, owner amendment A5): *every change is gated by one CI-authoritative static type check. The gate is one named command, the same locally, in the hook and in CI. The editor surfaces the same engine's verdict. Suppressions are named and auditable. The gate's severity and scope are explicit, not implicit.* Both raws derive this principle independently (`muse.md:23-29`, `opus.md:114-124`). The cross-repo shared-principle source both raws cite, `docs/port/DIVERGENCE-ANALYSIS.md`, is outside this synthesis's read set. It is therefore cited through the raws, not re-read.

**Agreement level: capability plus policy.** The three repositories must agree on six things:
- a named `typecheck` recipe exists;
- it is CI-authoritative;
- it covers test code;
- every suppression names its rule;
- the severity rule is written down;
- the hook tier is chosen from measured cost.

The engine, the flags, the tier value and the file layout may differ by ecosystem.

| Row | Must agree across py / ts / rs | May vary | Rust realization |
|---|---|---|---|
| F105 | one CI-authoritative engine behind a named recipe | the binary | `cargo check` |
| F106 | tier chosen from measured cost | the tier | pre-commit |
| F107 | the editor shows the gate engine's verdict | mechanism | rust-analyzer flycheck; feature setting handed to R28 |
| F108 | no unexplained second engine | whether one exists | none |
| F110 | strictness declared in one committed file | rule-based vs flag-based | `[workspace.lints.rust]` |
| F111 | suppressions name their rule; unknown names fail | syntax | `#[expect(lint, reason)]`, `unknown_lints`, `unfulfilled_lint_expectations` |
| F112 | warn-vs-fail rule explicit and deterministic | one tier or two | one failing tier in the gate, lax outside it |
| F113 | test code is inside the gate | mechanism | `--all-targets`, both feature configurations |

**Is the shared pattern still appropriate in Rust?** Partly, and the difference is structural. py and ts needed a separate tool because their runtimes execute code that never type-checked. Rust cannot build code that fails type checking. Every `cargo build`, `cargo test` and `cargo clippy` already gates on types (`H4b`: clippy reports `error[E0308]`). Three duties survive the port:
1. give the type check a named, cheap, attributable invocation;
2. decide how *warnings*, the only configurable part of rustc's verdict, are treated;
3. make the scope explicit, so that test code and the off-by-default `web` tree are inside it.

**Architectural alternatives.**

| Option | What the gate is | Consequence | Verdict |
|---|---|---|---|
| **A2. Named `cargo check` gate, both feature configurations** (recommended) | recipe, hook and CI run the two commands above | a type error or warning in either configuration fails a step named `typecheck`; costs 0.12–0.14 s warm no-op and 0.22–0.49 s incremental on the synthetic workspace (`H2`) | **chosen** |
| A1. Named gate, `--all-features` only (Opus, `opus.md:152`, `:253`) | one command | misses feature-off-only warnings (`S5`) and feature-off-only type errors (`S6`) | rejected on `S5`, `S6` |
| B. No distinct step; clippy is the type gate (the surveyed majority: `opus.md:90-92`, uv, ruff, axum, cargo) | clippy's steps, which R11 already runs with the feature off and on | one fewer step; but the type verdict follows R28's lint policy, a type error is reported under "clippy", and the hook tier depends on where R28 places clippy | **ranked runner-up**; chosen against majority practice, on principle preservation plus measured cost: clippy after the gate re-checks only the 4 workspace members, 0 dependencies, 0.62 s wall-clock (`H4a`, `r30-wiring-cost.log:200`), which reproduces the shape of Opus's E10 (`opus.md:294`) |
| C. Wrapper: `cargo hack check --each-feature` / `--feature-powerset` | a third-party binary enumerates feature sets | with one additive feature and two that nest under it (`otel`, `metrics` require `web`, registry row R69), "none" and "all" are the only realistic configurations, and A2 covers both | rejected now; becomes the runner-up for scope if a feature appears that does not nest under `web` (`opus.md:518-520`) |
| D. Build-based gate (`cargo build`, `cargo test --no-run`) | type check as a side effect of codegen | codegen and link cost for no extra type signal; R11's test and build steps already catch monomorphization-time errors | rejected (both raws) |

**How the design preserves each principle, and where Rust differs.**

- *One named command everywhere (F105, F106).* Identity across the three places is a checkable property, not a convention. `H1a` and `H1b` diff the `cargo check` lines of the Justfile, `lefthook.yml` and the CI steps and find them identical. `H1c` shows that the diff catches a drifted hook. P03 should keep that diff as an acceptance check.
- *Severity (F112).* The Cargo team's guide says: "Customarily, projects want to be "warnings clean" on official branches while being lax for local development. [`build.warnings = "deny"`] can be used to fail a CI job if warnings are present" (`continuous-integration.md:209-210`, blob `f1261a53`). This template puts the denying variable on the **gate**, meaning recipe, hook and CI. The lax tier is everything else: plain `cargo check`, `cargo build`, `cargo test` and the editor.
  - `build.warnings` changes no fingerprint. A denying run after a plain run re-checks 0 units and replays the cached warning as a failure (`W3b`). `RUSTFLAGS=-Dwarnings` re-checks every unit (`W3d`) and keeps a second artifact set (`W3e`).
  - So the hook's denying run and the editor's lax run share one `target/`.
  - py's reason for a non-failing tier, a new upstream deprecation failing every fork, is confined here by `--locked`. A dependency changes only through a pull request that edits `Cargo.lock`. The residual source of spontaneous failure is a new stable toolchain. Whether the channel is pinned is R27's decision under F103 (R27 prompt `:14`). R42 commits the file (R11 `DECISION.md:268`) but does not set its channel (R42 `DECISION.md:26`, `:458`), and R42's cited reference implementation commits the unpinned `channel = "stable"` (R42 `DECISION.md:439`). So no published item yet guarantees a pin.
- *Strictness (F110).* There is no `any`, no implicit numeric conversion and no unchecked cast to opt out of, so "type strictness" in Rust means lint levels only.
  - The workspace table is stable since Cargo 1.74 (`CHANGELOG.md:4151`, `:4156`), is read by the 1.96 floor (`L1c`), and applies only to packages that opt in (`L1a`).
  - `rust_2018_idioms` adds `elided_lifetimes_in_paths`, `explicit_outlives_requirements` and `unused_extern_crates` beyond the edition-2024 defaults. Its other members, `bare_trait_objects` and `ellipsis_inclusive_range_patterns`, are already hard errors in edition 2024 with no table entry (`L4a`, `L4b`; group membership from `rustc -W help` on 1.98.1 and 1.96.0, printed in `L4`).
  - Its type-surface effect is that a borrowed type in argument position must show its lifetime: `fn len(w: Wrap<'_>)`, not `fn len(w: Wrap)` (`L1a`, `L1e`).
  - `priority = -1` lets a later individual entry override the group (`manifest.md:553-554`).
- *Suppression (F111).* rustc already forces a named lint. Bare `#[allow]` is a hard error (`X1`), and `#[allow()]` warns "unused attribute" (`X2`). A misspelled name warns `unknown_lints` (`X3`), and an `#[expect]` that suppresses nothing warns `unfulfilled_lint_expectations` (`X4`). Under the denying gate, all three fail. That matches py's `ignore-comment-unknown-rule` and goes further, because py's cited `ty` configuration has no unfulfilled-ignore check (per `opus.md:207-209`).
  - **The two-configuration gate changes the house rule.** A bare `#[expect(dead_code)]` on a helper used only by `web` code is fulfilled with the feature off and unfulfilled with it on, so the gate fails (`X8a`, `X8b`).
  - Scoping the expectation to the configuration where the lint fires keeps it self-cleaning and green in both (`X9a`, `X9b`). `#[allow(lint, reason)]` is also green in both (`X10a`, `X10b`), but it never reports that it has become unnecessary.
  - `#![allow(warnings)]` passes the gate (`X6`). rustc has no lint against it.
- *Scope (F113).* Plain `cargo check` misses `tests/` (`S1`), `#[cfg(test)]` modules (`S2`) and examples (`S3`). `--all-targets` finds all three.
  - `web` is off by default (registry row R69). In a single-crate layout, a default-features gate therefore never compiles the web tree (`S4`). In R02's four-package layout it compiles `crates/web` but still skips every feature-gated item in the other packages. Either way, an `--all-features` run is needed.
  - An `--all-features`-only gate misses an import that only web code uses, which is unused only with the feature off (`S5`). It also misses a type error under `#[cfg(not(feature = "web"))]` (`S6`). Hence two commands.
  - Doctests are outside every `cargo check` form (`S7`: the gate exits 0, while `cargo test --doc` reports `error[E0308]`). They are R32's.
- *Hook tier (F106).* py put `ty` at pre-push because a full-tree scan was judged too slow per commit (ADR-0018, per the prompt). ts put `tsc --noEmit` at pre-commit (D-020(6)). The deciding quantity is warm incremental cost:
  - On a synthetic four-member workspace over 24 generated dependency crates (8,664 generated lines, 29 units cold), the full gate costs 16.01 s cold (`H2a`, `r30-wiring-cost.log:35`), 0.12–0.14 s warm no-op (`H2b`, `H2c`, `:42`, `:49`) and 0.22–0.49 s after an edit (`H2d`, `H2e`, `H2f`, `:61`, `:70`, `:82`). These are the script's `wall-clock` values, which include `just` and both cargo invocations.
  - A real `git commit` through the installed hook took 0.49–0.69 s wall-clock (`H3e` 0.69 s, `H3f` 0.49 s, `r30-wiring-cost.log:168`, `:184`); lefthook's own summaries for the same two cases read `done in 0.14 seconds` and `done in 0.39 seconds` (`:165`, `:181`).
  - Opus measured the same order of magnitude on a real 76-package tree with clap, axum and tokio: 0.13–0.39 s warm, 8.72–11.46 s cold (`opus.md:293`). This synthesis could not rerun that measurement (see `## Engines`).
  - py's cost argument therefore does not transfer; its follow-on rationale is that the argument is tool-specific.
  - Four costs remain, each recorded rather than hidden. First, the hook and rust-analyzer share `target/` and Cargo's build lock (`config.rs:878` default `None`), so a commit can wait on an in-flight editor check. Second, lefthook 2.x skips both jobs when nothing is staged (`H3a`), which is harmless for a commit hook. Third, `--locked` at pre-commit refuses a commit whose `Cargo.toml` edit lacks the matching `Cargo.lock` update (`V3`; also `opus.md:946-947`). That is consistent with R11's `--locked` rule for CI. Fourth, the recipe and the hook run the same command text (`H1`) but differ in failure behavior: `just` stops at the first failing line, so a default-features failure hides the all-features result locally (`V2a`), while lefthook runs every job (`V2b`) and CI runs both steps under `!cancelled()`. `--keep-going` keeps every failing crate visible within one command; it does not carry across the recipe's two lines.

**Acceptance criteria.** Each is labelled with what was actually executed.

| # | Criterion | Status |
|---|---|---|
| 1 | a type error in any target of any package, in either feature configuration, fails `typecheck` | **executed** in scratch workspaces: `S1`–`S6`, `H3c`, `H3d`; proposed in the template |
| 2 | a lint warning from a workspace package fails `typecheck`, while plain `cargo check` stays green | **executed** with direct cargo calls (`W1`, `W3b`/`W3c`, `L1a`/`L1b`) and through the real recipe and hook, where the variable is a `just` line prefix and a lefthook `env:` key (`V1a`–`V1e`) |
| 3 | the recipe, hook and CI commands are byte-identical | **executed** on fixtures: `H1a`–`H1c`; proposed as a P03 check on the real files |
| 4 | an unknown lint name, an unfulfilled `#[expect]` and a bare `#[allow]` fail the gate | **executed**: `X1`–`X4` |
| 5 | a staged type error refuses a real commit through the installed hook | **executed**: `H3e` (HEAD unchanged), `H3f` (accepted after restore) |
| 6 | the gate is green on a clean tree on the 1.96 floor rustc and on 1.98.1 | **executed**: `S9`, `W4`, `L1e`, `L1f` |
| 7 | the CI `typecheck` steps go red on a pull request that plants `E0308`, while `hygiene` still reports | **proposed** (needs the template and a runner) |
| 8 | warm incremental `typecheck` stays under about 2 s on `ubuntu-latest` in the rendered template | **proposed**; only macOS was measured |

**`BASELINE-REVIEW:`** none. Both raws confirm the recorded baseline ("the Rust baseline is `rustc`/`cargo check`") and propose no classification change (`muse.md:39`, `opus.md:302`). Opus reports that the prompt's py and ts line numbers have drifted at the source heads (`opus.md:303-308`). The source repositories are outside this synthesis's read set, so that note is carried as Opus's claim, not re-verified.

### Hand-offs

Nothing in this list changes a registered value.

- **R28** (linter and editor tooling):
  - whether to commit a rust-analyzer features setting, so that the editor shows feature-gated code. What the default misses depends on the layout (see F107). The key is `cargo.features` or `check.features`, at `config.rs:847` and `:901`. The editor can show only one configuration; the gate covers both.
  - optionally `cargo.targetDir` (`config.rs:878`), to remove build-lock waits.
  - the clippy lints `allow_attributes` and `allow_attributes_without_reason`, which enforce member 5 mechanically. Opus reports that both exist in clippy 0.1.98 (`opus.md:211-212`).
  - whether R11's clippy steps keep `-- -D warnings` (R11 `DECISION.md:268`) or move to `build.warnings`.
- **R40** (auxiliary hygiene hooks): a text check that rejects `allow(warnings)`, because no compiler lint does (`X6`).
- **R32** (test harness): doctests are type-checked only by `cargo test --doc` (`S7`).
- **R37** (hook manager): the form of the hook jobs, whether inline commands or `just typecheck`, under the identity invariant `H1`.
- **R27** (formatter config surface; F103, the `channel` of `rust-toolchain.toml`), one constraint and one open choice, without choosing R27's value:
  - the channel the recipe, the hook and the `check` job run on must carry Cargo ≥ 1.97, or `CARGO_BUILD_WARNINGS=deny` is inert and criterion 2 fails silently (`W1`: exit 0 on cargo 1.96.0, exit 101 on 1.97.1). A channel pinned to the `msrv-policy` floor, currently 1.96, would violate it. If R27 cannot meet the floor, this item's recorded fallback is the runner-up `RUSTFLAGS="-D warnings"` on the same three places;
  - whether to pin the channel or track `stable` remains R27's decision. The consequence of `stable` is that a new stable's lints can fail forks spontaneously (Cargo guide, `continuous-integration.md`, "Checking for warnings").
- **R42** (toolchain provisioning): none beyond what R42 already records. It owns the `rust-toolchain.toml` file and its `components`, and defers the `channel` value to R27 (R42 `DECISION.md:26`).
- **P03**: keep the `H1` diff as an acceptance check, and run criteria 7 and 8.

re-verify: 2027-03-26, or earlier on any of — the declared `rust-version` reaching 1.97, after which `CARGO_BUILD_WARNINGS=deny` also denies on the floor and the floor note under member 3 is removed; R27 settling F103 on an unpinned `stable` channel, which lets a new stable's lints fail forks spontaneously, or on a channel whose Cargo is below 1.97, which leaves member 3 inert in the recipe, hook and `check` job; R02 or R69 adding a Cargo feature that does not nest under `web`, which breaks the two-configuration coverage argument and promotes `cargo hack check --each-feature` to the scope runner-up; R11 changing the `check` job's ordered-step model, its `--locked` rule or its `!cancelled()` rule; R28 placing clippy at pre-commit with both feature configurations, which makes the pre-commit `typecheck` jobs redundant and moves them to pre-push; R28 and R40 both declining mechanical enforcement of named suppressions, which leaves `#![allow(warnings)]` to review alone; R37 choosing a hook manager or version that skips jobs even when files are staged; rustc gaining a lint against `allow(warnings)`, or Cargo changing `build.warnings` so that it alters fingerprints or reaches beyond local packages; or a measured warm incremental `typecheck` above 2 s on `ubuntu-latest` in the rendered template.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner

Owned parameters: none. The prompt's `- owns:` line is empty. Consumed parameter: `ci-job-structure`, owned by R11, byte-identical to `inputs/parameters.json` and to R11's published revision 7 (sha256 above). **No `CONFLICT:` line** is raised by either raw report (`muse.md:253`, `opus.md:1009`) or by this synthesis.

How each assumed value bears on the decision:

- **`ci-job-structure`.** R11's partition rule makes the gate "an ordered step of `check`", because it compiles what `check` already compiles (R11 `DECISION.md:278`, and its slot row for R30 at `:286`). The two `typecheck` steps inherit R11's `--locked` on every cargo command and its `!cancelled()` on every cargo step. They add no job and no cache-bearing job id. They type-check "none" and "all" in the job that already compiles both. R11's `msrv-floor` job proves that the floor compiles; it does not prove that the floor is warning-clean (`DECISION.md:227`). So the floor-inert severity switch weakens nothing that R11 asserts.
- **`msrv-policy`.** The floor is 1.96 while stable is 1.98.1. The `[lints]` table (Cargo 1.74), `#[expect]` (Rust 1.81) and `--keep-going` all work on the 1.96 floor rustc (`L1c`, `X11`, `S8`). `build.warnings` is inert there (`W1`, `W2`). No change to the policy is needed. The floor governs `rust-version` and R11's `msrv-floor` job only; the development channel is a separate value, R27's under F103 (R27 prompt `:14`), and it must not be the floor (see `### Hand-offs`).
- **`rust-edition`.** Edition 2024 already turns two of `rust_2018_idioms`' five lints into hard errors (`L4a`, `L4b`), which is why the entry adds only three lints.
- **`target-os-matrix`.** Both `check` legs run the steps. Every executed check ran on macOS arm64 only, so `ubuntu-latest` is proposed (criterion 8).
- **`license`.** It constrains nothing, because no dependency is added.

Registry rows read as prose, not as `assumes` lines, because neither is on this prompt's `- consumes:` line. Opus wrote `assumes` lines for both (`opus.md:1007-1008`); this synthesis does not carry them over.
- R69 `web-extra-surface` (`inputs/PARAMETERS.md:17`): `web` is off by default, and `otel` and `metrics` require `web`. This is why the gate needs two configurations and no more.
- R42 `package-manager-invocation` (`inputs/PARAMETERS.md:14`): "use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job". The recommended recipe and jobs invoke bare `cargo check`, so they comply either way. Disagreement **D6** records the one reading question this raises.

## Empirical check

**Host and toolchains.**
- Host: macOS (Darwin 25.4.0), arm64, 14 CPUs.
- Private `CARGO_HOME=/tmp/cargo-s34-R30-r3`, as printed on line 2 of the five logs whose scripts print it (`r30-lints.log`, `r30-scope.log`, `r30-severity.log`, `r30-suppression.log`, `r30-wiring-cost.log`; `I-hdr-cargo-home`). It stays empty of crates: every scratch workspace has zero registry dependencies. `r30-wiring-severity.sh` and `r30-upstream-docs.sh` do not print it.
- Each cargo-running script exports its own `CARGO_TARGET_DIR` inside its `mktemp -d` scratch directory and logs it as `# CARGO_TARGET_DIR=<ws>/target`, so the session's shared `CARGO_TARGET_DIR=/tmp/cargo-s34-R30-r3-target` cannot make a "cold" run warm. Revision 1 recorded that its own first pass lacked this pinning and was discarded.
- Revision 3 ran the seven scripts once, one after another in the order lints, scope, severity, suppression, upstream-docs, wiring-cost, wiring-severity, so the timing script competed with no other evidence run. `uptime` printed 1-minute load averages of 75.62 just before the pass and 102.40 just after it; the 15-minute averages were 57.15 and 61.97, left by other work on this shared host. The same scripts give different timings on different runs and loads. The cold gate (`H2a`) measured 6.12 s in revision 1's logs (`review/R30-r1-snapshot.md`, excerpt block), 5.53 s in revision 2's logs at a load of about 5 (`review/R30-r2-snapshot.md`, excerpt block), 11.36 s in the empirical auditor's rerun of revision 2 at a load of about 250 (`review/audit-claude.r2.md`), and 16.01 s here. The hook commits (`H3e`, `H3f`) measured 0.26–0.50 s in revision 2's pass and 0.49–0.69 s here; the auditor measured 0.56–2.41 s across `H3a`–`H3f`. The figures quoted in this file are this run's only.

| Name | Binary | Version |
|---|---|---|
| stable | Homebrew `cargo` / `rustc` on `PATH` | cargo 1.98.1 (797e8a9bc 2026-08-05), rustc 1.98.1 (48a229cea 2026-09-01), clippy 0.1.98 |
| 1.97.1 | `rustup which --toolchain 1.97.1 cargo` with `RUSTC` pinned to the same toolchain's `rustc` | cargo 1.97.1 (c980f4866 2026-06-30), rustc 1.97.1 (8bab26f4f 2026-07-14) |
| floor | `rustup which --toolchain 1.96.0 cargo` with `RUSTC` pinned likewise | cargo 1.96.0 (30a34c682 2026-05-25), rustc 1.96.0 (ac68faa20 2026-05-25) |
| tools | `just`, `lefthook`, `git`, `gh` | just 1.57.0, lefthook 2.1.14, git 2.50.1, gh 2.101.0 |

**Why `RUSTC` is pinned.** On this host, `rustup run 1.96.0 cargo` runs cargo 1.96.0, but that cargo resolves `rustc` through `PATH` to Homebrew's 1.98.1. So a "floor" compile made that way is not a floor compile. `rustup run 1.97.1 which rustc` printed `/opt/homebrew/bin/rustc`. Every script calls toolchain T as `RUSTC="$(rustup which --toolchain T rustc)" "$(rustup which --toolchain T cargo)"` (function `tcargo`), and each log header prints both versions. For `build.warnings`, only cargo's version matters, so Opus's E3/E4 conclusions stand. For lint behavior on the floor (E12, E13), see `## Engines`, **D8**.

**Checks.** All eight scripts are `shellcheck`-clean (re-run in revision 3), run from `review/evidence/` as `bash <script> > <log> 2>&1`, and exit with their failure count. The working directory of each cargo command is a `mktemp -d` scratch workspace, shown as `<ws>` or `<root>/proj` in the logs.

| Script / log | What it establishes | Cases | Result |
|---|---|---|---|
| `r30-scope.sh` / `.log` | target scope (`S1`–`S3`); feature scope, and that both configurations are needed (`S4`–`S6`); doctests outside `cargo check` (`S7`); `--keep-going` reports both independent failures and is accepted by the 1.96 floor (`S8`); floor green (`S9`) | 20 | 20 PASS, 0 FAIL |
| `r30-severity.sh` / `.log` | `CARGO_BUILD_WARNINGS=deny` inert on 1.96.0, denying on 1.97.1 and 1.98.1 (`W1`); `RUSTFLAGS` works on the floor (`W1`); committed-config form ignored by 1.96 and denying every local build on 1.98.1 (`W2`); fingerprint effect (`W3a`–`W3e`); clean tree green on all three (`W4`) | 17 | 17 PASS, 0 FAIL |
| `r30-suppression.sh` / `.log` | suppression forms under the gate (`X1`–`X6`); configuration-dependent lints (`X7`–`X10`); `#[expect]` on the 1.96 floor rustc (`X11`, `X12`) | 16 | 16 PASS, 0 FAIL |
| `r30-lints.sh` / `.log` | Opus's E13 example already warns by default (`L0`); `rust_2018_idioms` through the table, inherited only by opt-in packages, on stable and on the floor rustc (`L1`); a misspelled feature `cfg` warns with no table entry (`L2`); Muse's `unexpected_cfgs = "deny"` makes plain local builds fail (`L3`); the group's members, two of which edition 2024 already rejects (`L4`) | 14 | 14 PASS, 0 FAIL |
| `r30-wiring-cost.sh` / `.log` | identity of recipe, hook and CI commands (`H1`); cost (`H2`); the real `just` recipe and the real lefthook pre-commit hook, including a refused commit (`H3`); clippy after the gate and clippy's `E0308` (`H4`) | 17 | 17 PASS, 0 FAIL |
| `r30-wiring-severity.sh` / `.log` | the severity switch through the real wiring: a lint warning fails `just typecheck` (line-prefix variable) and `lefthook run pre-commit` (per-job `env:` key), while plain `cargo check` stays green (`V1`); `just` stops at its first failing line while lefthook runs both jobs (`V2`); `--locked` at the hook refuses an un-updated lockfile (`V3`). A separate script, so `H2`'s quoted timings are unaffected | 8 | 8 PASS, 0 FAIL |
| `r30-upstream-docs.sh` / `.log` | every upstream sentence and default quoted in this file, fetched through `GET https://api.github.com/repos/<o>/<r>/contents/<path>`, with blob sha and line numbers | 22 patterns in 6 files | 22 found, 0 missing |
| `r30-inputs.sh` / `.log` (new in revision 2, extended in revision 3) | the re-frozen prompt and policy are byte-identical to the live files (`I-prompt`, `I-policy`); the Q17.A seat authority (`I-prompt-engines`, `I-override`, `I-runbook-q17a`) and the audit-seat entry (`I-eao-r30`); the R42 and R27 lines this file cites for the channel owner (`I-r42-channel`, `I-r27-f103`) and the absence of the revision-2 R42 routing outside the revision notes (`I-jf5`); revision 2 preserved (`I-r2-snapshot`); the manifest's pre-amendment dispatch record (`I-manifest-dispatch`); revision 1 preserved (`I-r1-snapshot`); every timing figure quoted in this file equals its case's `wall-clock:` value (`I-fig-*`); every excerpt line below occurs in a log (`I-excerpt`); log timestamps and `CARGO_HOME` (`I-hdr-*`); every evidence log ends `failures=0` with the stated PASS count (`I-counts`); this file's H2 order, revision header, five byte-exact `assumes` lines, and that every cited case ID has a PASS line (`I-dec-*`) | 43 | 43 PASS, 0 FAIL |

**Observed output, key cases** (quoted from the logs; `<ws>` is the scratch workspace):

```text
== S5 feature-off-only unused import — gate with --all-features only
$ env CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --all-features --locked --keep-going
exit=0 (expected 0) PASS
== S5 feature-off-only unused import — gate with default features
warning: unused import: `core_crate::answer as core_answer`
error: warnings are denied by `build.warnings` configuration
exit=101 (expected 101) PASS

== W1 1.96.0 CARGO_BUILD_WARNINGS=deny
units re-checked: 0
exit=0 (expected 0) PASS
== W1 1.97.1 CARGO_BUILD_WARNINGS=deny
units re-checked: 0
exit=101 (expected 101) PASS
== W3b CARGO_BUILD_WARNINGS=deny after plain — expect 0 units re-checked, warning replayed as failure
units re-checked: 0
exit=101 (expected 101) PASS
== W3d RUSTFLAGS=-Dwarnings after plain — expect every unit re-checked (new fingerprint)
units re-checked: 2
exit=101 (expected 101) PASS

== X8b #[expect] on the configuration-dependent lint, --all-features — unfulfilled, gate fails
warning: this lint expectation is unfulfilled
exit=101 (expected 101) PASS

== L0a fn mk(s: &str) -> Wrap in the member WITHOUT the table — default lint warns, gate fails
  = note: `#[warn(mismatched_lifetime_syntaxes)]` on by default

== H2a cold: just typecheck (both configurations)
units re-checked: 29  wall-clock: 16.01 s
== H2b warm no-op: just typecheck
units re-checked: 0  wall-clock: 0.14 s
== H2d after editing crates/core (every workspace member depends on it)
units re-checked: 5  wall-clock: 0.29 s
== H3e the same through a real commit with the hook installed — commit refused
exit=1 (expected 1) PASS
HEAD subject after H3e (must still be the H2 commit): H2 edits
```

**Limits of what was executed.**
- The template does not exist, so every check ran in a scratch workspace built to R02's accepted shape (facade, core, cli, web) and R69's feature shape.
- There is no registry dependency: crate downloads come from hosts outside the topic's named endpoints. The dependency-bearing timing is therefore Opus's (`opus.md:293`), not rerun.
- Timings are from one macOS arm64 host.
- rust-analyzer was not executed; its defaults are read from its source (`config.rs`, blob `1e7c8257`).
- The CI steps ran only as a fixture diff (`H1b`), not on a runner.

## Engines

**Reports.** Two raw reports, both on the prompt's engine list, `- engines: muse, opus` (`inputs/prompt.md:25`):

| Seat | File | Engine and model as stated | Independence | Executed checks |
|---|---|---|---|---|
| muse (the dispatch-time Codex seat, under Q17.A) | `raw/muse.md` | "muse (Meta)" (`muse.md:3`) | a separate leg; opened neither the other raw nor any audit | one narrow probe on rustc 1.98.1 (`muse.md:37`), no timings |
| opus | `raw/opus.md` | `claude-opus-5-5`, CLI (`opus.md:3`) | "no other engine's report for this run was opened" (`opus.md:6-7`) | E1–E13 (`opus.md:283-297`) |

**Seat authority: Muse in place of Codex.** The Codex seat was filled by Muse. The authority is owner decision **Q17.A (2026-09-27)**, which extends the `engine_overrides` pilot's Muse-for-Codex substitution to the research wave, R30 included; the owner had earlier retired Codex from P02 under Q9.B. The authority is recorded in four live places, each checked by `r30-inputs.sh`:
- `research/RUNBOOK.md:73-76` names Q17.A and lists R30 among the wave items (`I-runbook-q17a`).
- `research/EXECUTION.json` sets `engine_overrides.R30` and `items.R30.engines` both to `["muse", "opus"]` (`I-override`).
- The topic prompt's `- engines: muse, opus` line (`inputs/prompt.md:25`, `I-prompt-engines`) and its sentence "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative" (`inputs/prompt.md:74`).
- `inputs/prompt.md` and `inputs/EXECUTION.json` are re-frozen byte-identical to those live files (`I-prompt`, `I-policy`).

**Recorded overrides extension: the empirical audit seat.** The re-frozen policy lists R30 in `empirical_auditor_overrides` with the value `"claude"`, added with 43 other items after revision 2 was written (`I-eao-r30`). RUNBOOK `:98-104` defines the entry: the item's empirical audit runs on the named seat, files as `audit-claude.md` with an anthropic identity, and the different-family rule is waived for this item only, at the cost of the cross-family check on the rerun. It governs who audits, not who researches or synthesizes. `engine_overrides.R30` and `items.R30.engines` are unchanged at `["muse", "opus"]` (`I-override`), so every seat and engine claim above holds. The revision-2 empirical audit is filed as `review/audit-claude.r2.md` with `family: anthropic`, which matches the entry.

The engine policy for this item changed after dispatch; the legs did not. Both raw reports are the ones revision 1 synthesized, with the same hashes. `manifest.json` is left as the pre-amendment dispatch record: `required_engines` `["codex", "opus"]`, `input_hashes.prompt` `a883b22d…`, and an empty `operations` map (`I-manifest-dispatch`). The synthesis may not write the manifest; re-snapshotting it to the amended engine set and recording the legs' operations are the controller's steps.

**Where the legs agree**, with the evidence that makes each agreement more than agreement:
- The engine is `cargo check` with no wrapper, because type errors are hard errors in every cargo command (`S1`–`S6`, `H4b`).
- There is no second checker.
- `--all-targets` is required for test code (`S1`–`S3`; the Muse probe at `muse.md:37`, Opus E1).
- The table is `[workspace.lints]` with `[lints] workspace = true` (`L1a`).
- Suppressions are named, and `#![allow(warnings)]` is the gap (`X6`).
- The gate is a distinct named step, chosen against the surveyed clippy-only majority (see option B above).
- No `CONFLICT:` line and no `BASELINE-REVIEW:` finding.

**Disagreements and their resolution.**

- **D1 — severity mechanism.** Muse puts `RUSTFLAGS="-D warnings"` on the CI steps (`muse.md:33`, `:59`, `:121`). Opus uses Cargo's `build.warnings` through `CARGO_BUILD_WARNINGS=deny` (`opus.md:319-324`). **Resolved for Opus**, on three executed facts and one upstream text:
  - `build.warnings` denies on 1.97.1 and 1.98.1 (`W1`).
  - It changes no fingerprint, so the gate and the lax editor share artifacts (`W3b`, `W3c`). `RUSTFLAGS` re-checks every unit and doubles the artifact set (`W3d`, `W3e`).
  - The Cargo guide names `build.warnings` as its CI mechanism (`continuous-integration.md:209-210`), and cargo 1.97's changelog stabilizes it (`CHANGELOG.md:399`).
  - The cost of the choice is real and recorded: on the 1.96 floor the variable does nothing and prints nothing (`W1`). That leaves no gap in R11's `msrv-floor` job, because that job proves compilation, not warning-cleanliness (R11 `DECISION.md:227`). It would leave a gap everywhere else if the development channel carried Cargo below 1.97, which is why that constraint is handed to R27. The note disappears when the declared floor reaches 1.97. `RUSTFLAGS` is the ranked runner-up for anyone who must deny on a pre-1.97 toolchain (`W1`: it works on 1.96).
- **D2 — does the recipe deny locally?** Muse's local recipe is lax, and CI alone adds the flag through a `ci=true` parameter or step env (`muse.md:121`, `:161`, `:259`). Opus's recipe, hook and CI step deny identically (`opus.md:253`, `:319-323`). **Resolved for Opus on the shared principle.** The principle both raws state is one named command, identical locally, in the hook and in CI, which is ts's `tsc --noEmit` precedent. A mode switch breaks that identity. Muse's reason is that a new-toolchain lint must not break the inner loop. That is met without the switch, because the lax tier is plain `cargo` and the editor, not the recipe (`L1b`: plain `cargo check` exits 0 on the warning the gate rejects). A committed `.cargo/config.toml` would remove the lax tier for everyone (`W2`); both raws reject it.
- **D3 — feature scope.** Opus runs one `--all-features` command (`opus.md:152`, `:253`, `:513`). Muse runs a feature-off and a feature-on leg, but scopes the feature-off leg `-p` to non-web packages "per R11's contract" (`muse.md:91`, `:221`, `:251`, `:259`). **Resolved for neither as written.**
  - Against Opus: `S5` and `S6` show that an `--all-features`-only gate passes a tree with a feature-off-only unused import and a feature-off-only type error. Under a denying gate, both are holes. The template's feature gating makes the first kind routine (`X7a` is the same shape as a dead-code warning).
  - Against Muse's attribution: R11's `-p` scoping belongs to the feature-off **test** step, "cargo test with the feature off scoped by -p to the non-web packages" (`inputs/parameters.json`; R11 `DECISION.md:221`). It does not belong to any check step, so the gate does not inherit it. Muse's two-leg instinct is right.
  - The adopted shape is two whole-workspace commands, default features and `--all-features`, each `--all-targets`.
  - Consequence for suppressions (member 5): a bare `#[expect]` on a configuration-dependent lint fails one of the two configurations (`X8b`).
- **D4 — lints table contents.** Muse denies `unexpected_cfgs` with an explicit `check-cfg` list, "so a typo'd feature flag fails the gate" (`muse.md:117`, `:125`). Opus adds `rust_2018_idioms` at `warn`, `priority = -1` (`opus.md:325-327`, `:727-729`).
  - **Muse's entry is rejected.** Cargo already passes feature `--check-cfg` to rustc, so a misspelled feature warns with no entry, on stable and on the floor (`L2a`, `L2c`), and the denying gate fails on it (`L2b`). The table entry therefore adds nothing for features. Its `deny` level makes every plain local build fail (`L3`), which is the lax local tier `D2` keeps. A `check-cfg` list is needed only for custom, non-feature `cfg`s, and the template declares none.
  - **Opus's entry is adopted, but its evidence is corrected.** Opus's E13 example, `fn mk(s: &str) -> Wrap` (`opus.md:297`), already warns under the default `mismatched_lifetime_syntaxes` lint in a package that has no table at all (`L0a`, `L0b`). So E13 does not show what the entry adds. The contribution is shown by `fn len(w: Wrap)`, which only `elided_lifetimes_in_paths` flags (`L1a`: the inheriting package fails, while the opt-out package with identical code is silent).
  - Confidence in the entry is **medium**; it is a taste call with cargo and axum as precedent (`opus.md:80`, `:83`, not re-fetched here). The ranked runner-up is an empty table with the inheritance wiring only (`opus.md:733-736`).
- **D5 — hook tier.** Muse chooses pre-push. Its reason is that the full-tree check is "minutes-scale" cold and needs a warm cache, citing F147's tiering and py's ADR-0018 (`muse.md:185`, `:262`). It measured nothing and asked for the measurement (`muse.md:276`). Opus chooses pre-commit on measured warm cost (`opus.md:333`, `:293`). **Resolved for Opus on measurement**:
  - `H2`: 0.12–0.14 s no-op, 0.22–0.49 s incremental, 16.01 s cold once. `H3e`/`H3f`: a real commit through the hook in 0.49–0.69 s wall-clock, under 1 s. These figures were measured at a 1-minute host load of 75–102 on 14 CPUs; revision 2's pass at a load of about 5 measured 0.26–0.50 s, and the empirical auditor's rerun at a load of about 250 measured up to 2.41 s (`review/audit-claude.r2.md`). The warm cost rises with host contention. The resolution rests on the lightly loaded figures, which are sub-second on this workspace and agree in order of magnitude with Opus's real-dependency 0.13–0.39 s (`opus.md:293`); criterion 8 measures the rendered template on `ubuntu-latest`, and its re-verify trigger moves the tier if that exceeds 2 s.
  - Opus's real-dependency figures (`opus.md:293`) agree in order of magnitude but were not rerun (see gaps).
  - The cold cost is paid once, and a contributor's first `cargo build` pays the same dependency compile.
  - Muse's F147 citation could not be checked: the ledger is outside this synthesis's read set.
  - Pre-push stays the ranked runner-up under Opus's own condition (`opus.md:934-936`): if R28 or R37 put clippy at pre-commit with both feature configurations, then clippy already type-checks there.
- **D6 — hook job body.** Muse's hook runs `just typecheck` (`muse.md:225`, `:262`). Opus repeats the cargo command because "R42 forbids a runner prefix in lefthook jobs" (`opus.md:258-259`). **Not decided here.** The form of `lefthook.yml` is R37's, and R42 is not on this item's `consumes:` line.
  - R42's text, "use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job" (`inputs/PARAMETERS.md:14`), targets prefixes placed *before a tool*, such as a `mise exec --`-style wrapper around `cargo`. Whether a job that invokes `just` is such a prefix is R42's reading to give, not this item's.
  - What this item fixes is the invariant under either form: the hook runs exactly the recipe's commands with the same variable. `H1` checks it for the inline form, and `just typecheck` satisfies it by construction.
- **D7 — suppressing a configuration-dependent lint.** Opus uses `#[allow(lint, reason)]` wherever a lint fires only under some features (`opus.md:800-801`, `:814-817`). Muse prefers `#[expect]` without that distinction (`muse.md:145`). **Resolved by execution for a third form, with Opus's as fallback.**
  - `#[cfg_attr(not(feature = "web"), expect(dead_code, reason = "..."))]` is green in both configurations (`X9a`, `X9b`) and remains self-cleaning.
  - `#[allow(dead_code, reason = "...")]` is also green (`X10a`, `X10b`) but never reports when it becomes unnecessary.
  - Muse's bare `#[expect]` fails the two-configuration gate (`X8b`).
- **D8 — Opus's floor evidence.** Opus ran its floor checks as `rustup run 1.96.0 cargo` (`opus.md:14`, `:296`) on the same host, where that form drives Homebrew's rustc 1.98.1 (see `## Empirical check`). Its E12 (floor compile) and E13 on 1.96.0 (lint behavior) may therefore have exercised rustc 1.98.1. This synthesis cannot inspect Opus's environment, so it records the uncertainty and does not assert contamination. The conclusions were rerun against the pinned 1.96.0 rustc, and they hold:
  - the table is read (`L1c`);
  - `#[expect]` works and its unfulfilled form warns (`X11`, `X12`);
  - `--keep-going` is accepted (`S8`);
  - the floor is green (`S9`, `W4`).
  Opus's `build.warnings` findings (E3, E4) are cargo-side and unaffected.
- **D9 — unverified claims in the Muse report.** Three claims were not checked, and none decides anything here:
  - that tokio's and clap's CI deny warnings (`muse.md:17`, "cited from ecosystem knowledge … not live-fetched", `muse.md:287`);
  - the 2024 State of Rust survey's "7,310 completed responses" (`muse.md:15`);
  - the F147 tiering citation (`muse.md:185`).

**Gaps recorded.**
1. Dependency-bearing timings were not rerun, because registry crate downloads are outside the topic's named endpoints. The figures come from Opus (`opus.md:293`), on one macOS M4 Pro host. This synthesis's own timings use a synthetic, registry-free workspace.
2. No `ubuntu-latest` measurement exists (criterion 8, proposed).
3. rust-analyzer was not executed; editor behavior rests on its source defaults (`config.rs`, blob `1e7c8257`).
4. `#![allow(warnings)]` passes the gate (`X6`). The fix is handed to R28/R40, and no rustc mechanism closes it.
5. Doctests are outside every `cargo check` form (`S7`); they are handed to R32.
6. Opus's seven-project practice survey, its `cargo-hack`, `cargo-all-features`, `bacon` and `cargo-watch` figures, and its source-repository line-drift note were not re-fetched. They are cited as Opus's. They decide the runner-up ranking (option B, option C), not the recommendation.
7. The ledger rows and cross-repo analysis (`docs/port/COMMONALITY.md`, `docs/port/DIVERGENCE-ANALYSIS.md`) and the py and ts source files are outside this synthesis's read set. They are cited through `inputs/prompt.md` and the raws.
8. The run manifest still records the pre-amendment dispatch (`required_engines` codex and opus, prompt `a883b22d…`) and no operation identifiers. The prompt and the policy now record the Muse-for-Codex substitution under Q17.A. Re-snapshotting the manifest is flagged for the controller.
9. Two of Opus's recorded gaps remain untested because the gate does not depend on them: whether `--force-warn` escapes `build.warnings`, and whether `build.warnings` covers rustdoc lints (`opus.md:1080-1081`).
10. Every timing is from one sequential pass on one shared macOS arm64 host whose load varied from pass to pass. Repeated runs of the same scripts gave cold figures of 5.53–16.01 s and hook-case figures (`H3a`–`H3f`) of 0.15–2.41 s across the passes listed under `## Empirical check`; no controlled run-to-run distribution was measured, and no pass ran on an idle host.
11. `inputs/EXECUTION.json` is frozen against the working-tree `research/EXECUTION.json`, whose `empirical_auditor_overrides` edit is not yet committed (`HEAD:research/EXECUTION.json` is `ac4561fe28cc219a5a8ded5a53607bddb3ab84a7c42b87edcf38bf0043d27f2b`). The controller states that the live policy is stable. If it changes again before acceptance, `I-policy` fails and the file must be re-frozen.
