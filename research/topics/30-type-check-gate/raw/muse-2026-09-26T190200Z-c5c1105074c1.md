# Raw research answer — R30 type-check gate (bundle, engine muse)

Engine: muse (Meta). Retrieval date for cited pages: 2026-09-26. No crate members are recommended, so no crates.io / GitHub / RustSec figures apply; each member states why. One narrow `cargo check` probe was executed locally (rustc/cargo 1.98.1, `/tmp`, 2026-09-26); everything else is proposed, not executed.

### Landscape

**Decision category.** R30 decides the template's CI-authoritative type-correctness gate: which engine checks types, how strictness/suppression/severity are configured, what scope it covers, and where it runs in the hook/CI pipeline (F105–F108, F110–F113). It does not decide rustfmt/clippy config surfaces (R27/R28), the editor extension (R28/F109), a standalone security scanner (R31), or CI job shape (R11, consumed).

**Three-bin map of the Rust field.** Every candidate below comes from this map.

- Built-in / first-party toolchain: `rustc` itself (type errors are hard errors emitted during compilation); `cargo check` (workspace-aware driver that runs `rustc` to metadata without codegen); `cargo build` (same type signal plus codegen); `rust-analyzer` with its `cargo check` flycheck (first-party via the rust-lang organization); the `[lints]` / `[workspace.lints]` manifest table (Cargo's stable lint-configuration surface); lint-level attributes (`#[allow]`, `#[warn]`, `#[deny]`, `#[forbid]`, `#[expect]`).
- Established industry standard: the `cargo check --workspace --all-targets --locked` CI pattern, usually with warnings denied (`RUSTFLAGS="-D warnings"`); rust-analyzer diagnostics in the editor driven by the same `cargo check` invocation; the Cargo Book's continuous-integration guidance (locked, workspace-wide checks on a fixed toolchain). Practice evidence below shows this is what maintained projects run.
- Up-and-comer / specialized: `cargo-hack` (feature-combination checking wrapper); background-check UX (`bacon`, `cargo-watch`); `cargo-minimal-versions` / `-Z minimal-versions` (floor checking, adjacent to R11's msrv-floor). None of these replaces `cargo check` as the gate engine; they wrap or watch it.

**Authorities and why each counts.** The Cargo Book (`cargo check` command page, `[lints]` manifest reference, workspace inheritance, continuous-integration guide) is the maintained first-party documentation of the exact commands and tables recommended here. The rustc book's lint listing is the authoritative lint-level reference. The rust-analyzer manual is the authoritative source for its check-on-save/flycheck behavior (single-engine claim). The 2024 State of Rust survey (Rust Project publication, 7,310 completed responses) is authoritative ecosystem context for rust-analyzer's dominance as the editor engine, not a crate selector. The executed probe in this report (rustc 1.98.1) is authoritative only for the narrow behaviors it ran. No single blog post decides any claim; two widely cited independent write-ups on deny-warnings practice are corroboration only.

**Practice evidence.** Well-regarded standing is evidenced by maintenance under major organizations and broad adoption, not asserted: `tokio` (tokio-rs organization, the flagship async runtime; its CI denies warnings on its check/clippy gates); `clap` (the leading CLI parser; its CI runs workspace-wide check/clippy gates with warnings denied); `rust-analyzer` itself (rust-lang organization; its manual documents `cargo check` as the default flycheck command, i.e. the editor runs the same engine as CI); the Cargo Book's own CI guide (first-party recommended shape: locked, matrix-wide `cargo check`/`cargo test`). These corroborate one-engine + deny-warnings + workspace-wide scope as mainstream production practice.

**Fit over abstract best.** The template is a CLI + library + web service rendered from one workspace with an optional feature leg (per R11's check job: feature-off and feature-on legs). Candidates are judged on: zero extra dependencies for the gate, correctness of feature/test coverage, hook-tier cost under cold and warm caches, and preservation of the py/ts precedent at capability/policy level — not on standalone popularity.

### Principles and implementation

**Shared requirement and agreement levels (HIGH owner-clarification question).** The shared principle, scoped to this item's rows in `docs/port/DIVERGENCE-ANALYSIS.md` (R30 item row plus F106/F111/F113 sub-rows, class C/A/D pattern), is *machine-checked type correctness gates every merge*. Agreement levels:

1. Capability + policy (must agree): every merge is gated on a named, CI-authoritative type-correctness check that is distinct from build/packaging and from style linting. py realizes it with `ty`, ts with `tsc --noEmit`, rs with `cargo check --workspace --all-targets`. The different engines are a justified ecosystem difference (Rust checks at compile time by construction; py/ts need a separate tool), and the ledger's F105 note already records this baseline. Preserved by keeping a distinct named `typecheck` recipe and CI step in each repo (ts D-015(1) shape).
2. Architectural pattern (must agree): one engine serves both CI and the editor (F107). ts proves the shape (`tsc` + `tsdk` pin, D-015(2)/D-032); rs adopts it natively because rust-analyzer's default flycheck *is* `cargo check` (member 1). py's two-engine split (F108: `ty` for CI + `pyright strict` for the IDE) is the justified outlier of an ecosystem that is untyped by default. No rs second checker; py/ts need no change here (their follow-on rationale is that the pattern, not the tool count, is what agrees).
3. Policy (must agree): every suppression names its rule (F111). py enforces it in `ty` config; ts has no convention (class D omission — eslint/oxlint rules for this exist); rs gets it free from `#[allow(lint_name)]`/`#[expect(lint_name)]` syntax, which cannot name nothing. rs adopts the discipline explicitly (member 2); the ts follow-on is to adopt an equivalent `@ts-expect-error` convention, supplied as rationale only.
4. Policy-explicitness (must agree that the behavior is explicit; the value may differ with reason): warning-vs-error severity (F112). py documents `error-on-warning = false` (warnings inform); ts has no warn tier (every diagnostic fails). rs follows ts: warnings fail the gate via `RUSTFLAGS="-D warnings"` in CI (member 2). Justification: rustc warnings include future-compat and soundness-adjacent signals, and a template that tolerates warnings rots silently; the local dev invocation stays warning-tolerant so a new-toolchain lint never breaks an inner loop.
5. Policy (must agree): the gate covers shipped and test code (F113). ts deliberately fixed py's under-checking of tests (D-013(4)); rs follows ts via `--all-targets` (member 3). The executed probe proves bare `cargo check` misses `tests/` while `--all-targets` catches it — scope is a real decision, not a default.

**Architectural alternatives compared.** (A) `cargo check` as the gate engine with no wrapper (recommended): zero dependencies, fastest compile gate (no codegen), workspace-aware. (B) `cargo build`/`clippy` as the type gate: rejected as the *type* gate — build adds codegen cost for zero extra type signal; clippy is R28's lint gate and must stay a separate step (ts D-015(1) "distinct step" pattern). (C) A third-party wrapper (`cargo-hack --feature-powerset`, background watchers): rejected as the gate — `cargo-hack` multiplies legs beyond R11's two-leg feature contract, and watchers are dev UX, not CI gates. Libraries were not separately evaluated because no library can add type signal beyond `rustc`; strictness lives in the `[lints]` table (member 2).

**Recommended Rust design.** A distinct named `typecheck` recipe (`just typecheck`, alias `tc`) running `RUSTFLAGS="-D warnings" cargo check --workspace --all-targets --locked`, executed twice in CI per R11's contract (feature-off leg scoped `-p` to non-web packages, feature-on leg workspace-wide); a `[workspace.lints.rust]` table in the root `Cargo.toml` with inherited `[lints] workspace = true` in every member; named-`#[allow]`/`#[expect]` suppression discipline with blanket `allow(warnings)` forbidden by review; pre-push hook tier running `just typecheck` without `-D warnings` promotion beyond the committed table; rust-analyzer as the editor engine reading the same workspace (R28 owns the extension pick, F109). Maturity: every piece is stable toolchain surface (cargo 1.74+ lints tables; `#[expect]` stable since 1.81). Dependability: no third-party dependency, no advisory surface, MSRV-safe by construction. Performance: `check` is the cheapest compile gate; incremental cache makes warm runs seconds, but cold-cache plus two feature legs keeps it out of pre-commit (member 3). Integration cost: four template files (see Migration implications).

**Minimal realistic example and acceptance criteria.** A workspace (`cli` binary + `lib` + `web` member with the optional feature, `tests/` integration tests) where: (1) `just typecheck` exits 0 on a clean tree; (2) a type error in any member, any feature leg, or `tests/` fails it; (3) an unused-variable warning fails it under CI flags and passes locally; (4) an `#[allow(unused_variables)]` on the same line passes CI while `#[allow(warnings)]` is rejected in review. Criteria 2–4 are proposed checks, distinguished from the executed narrow probe below.

**Executed narrow probe (2026-09-26, rustc/cargo 1.98.1, `/tmp/r30probe`, not the template).** Mismatched-type lib: `cargo check` → `error[E0308]`, exit 101. Unused variable: plain `cargo check` → warning, exit 0; `RUSTFLAGS="-D warnings" cargo check` → error, exit 101. Broken `tests/it.rs`: bare `cargo check` → exit 0 (missed); `cargo check --all-targets` → `error[E0308]`, exit 101. This proves the severity-tier and scope mechanisms on the local toolchain only; it does not prove feature-leg behavior, hook timing, MSRV-floor behavior, or any template file.

**No `BASELINE-REVIEW:` finding.** The ledger's F105 baseline (`rustc`/`cargo check`, open wrapper question) is confirmed, not challenged: no wrapper is adopted, and F106–F108/F110–F113 resolve as recorded in the members. No ledger or parameter change is proposed.

### Recommendation

Adopt one stack: **`cargo check --workspace --all-targets --locked` (toolchain `rustc`, no wrapper crate) as the sole CI-authoritative type gate, run as a distinct named `typecheck` step; single-engine editor≡CI via rust-analyzer's `cargo check` flycheck; `[workspace.lints.rust]` strictness table; named-suppression discipline; warnings denied in CI (`RUSTFLAGS="-D warnings"`); tests included via `--all-targets`; pre-push hook tier.** Versioning: the gate is versioned by the Rust stable toolchain R42 provisions (floor declared as `rust-version`, stable-minus-2 per owner-fixed MSRV policy); no crate versions apply.

### Members

#### check-engine

##### Landscape

Category facet: the gate engine (F105) and the single-engine CI≡editor design (F107/F108). Bins: built-in — `cargo check`, `cargo build`, `rustc`, rust-analyzer flycheck; established — the workspace-wide locked `cargo check` CI pattern plus the Cargo Book CI guide; up-and-comer — `cargo-hack`, `bacon`/`cargo-watch` (wrappers/watchers, not engines). No shortlisted candidate comes from familiarity: `cargo check` is the ledger's own recorded baseline and the only engine that adds no dependency while covering the whole workspace. Crate figures (downloads, stars, issues, advisories) are inapplicable to every candidate here: all are toolchain components distributed via rustup, not crates.io packages; fitness is judged by the gate rubric instead (see Fit for this template).

##### Principles and implementation

F105 asks whether `rustc`/`cargo check` suffices or a wrapper/strictness layer is needed. It suffices: Rust type errors (E-numbers, e.g. E0308 in the executed probe) are hard errors that fail any `cargo check` invocation with no configuration, unlike py/ts where checking is opt-in tooling. The "distinct step" half of the question resolves ts-side (D-015(1)): the template still wants a distinct named `typecheck` Justfile recipe and CI step so the gate is invocable, hookable, and reportable independently of build and lint — distinctness of the *step*, not of the *tool*. F107/F108 resolve to ts's one-engine design: rust-analyzer's default check command is `cargo check` (rust-analyzer manual, configuration `rust-analyzer.check.command`), so the editor literally runs the gate engine against the same workspace; py's second IDE-only checker has no rs analogue and none is needed. R28 owns the extension recommendation (F109); this member only constrains it to an engine that matches `cargo check` semantics.

##### Dominant choice

`cargo check --workspace --all-targets --locked`, invoked by the `typecheck` recipe, with `RUSTFLAGS="-D warnings"` in CI (severity itself is member 2's decision; the engine is identical with or without the flag). `--workspace` covers the CLI + library + web members; `--all-targets` adds tests/benches/examples (member 3 proves it is load-bearing); `--locked` pins the dependency graph per the Cargo Book CI guide. [Cargo `cargo check` reference](https://doc.rust-lang.org/cargo/commands/cargo-check.html) and [Cargo continuous-integration guide](https://doc.rust-lang.org/cargo/guide/continuous-integration.html) (retrieved 2026-09-26).

##### Qualified shortlist

Two qualify; fewer would be a finding, more would be padding: (1) `cargo build --workspace --all-targets --locked` — identical type signal, qualifies as a fallback where a consumer needs artifacts too, but pays full codegen for no extra checking; (2) direct `rustc --emit=metadata` invocation — qualifies for single-file or embedded cases, but has no workspace awareness and duplicates what `cargo check` already drives. Both pass every applicable gate; neither beats `cargo check` on cost or coverage for this template.

##### Excluded by gate

No candidate is gate-excluded: there is no third-party engine candidate to fail a gate, and the toolchain candidates pass (see Fit). `cargo clippy` is explicitly *not* listed here — it is R28's adjacent lint gate, not a rejected type engine; conflating the two would violate the D-015(1) distinct-step pattern this answer preserves. `cargo-hack --feature-powerset` is not gate-excluded either; it is design-rejected (see Up-and-comers) for exceeding R11's two-leg feature contract.

##### Up-and-comers

`cargo-hack` (feature-combination wrapper) and `bacon`/`cargo-watch` (background re-check UX). Neither qualifies as the gate: `cargo-hack`'s powerset multiplies CI legs beyond what R11's check job defines (feature-off + feature-on only), and the watchers are local-dev ergonomics with no CI-gate role. Monitored, not adopted; no crates.io figures collected because no adoption is recommended (a deliberately narrow evidence gap, recorded not filled).

##### Fit for this template

Fitness gates, toolchain-applied: (1) License: pass — rustc/cargo/rust-analyzer ship under `MIT OR Apache-2.0`, matching the owner-fixed license. (2) MSRV: pass by construction — the gate *is* the toolchain; it runs at the declared `rust-version` floor (R11 msrv-floor) and at latest (R11 check matrix). (3) Advisories/`unsafe`: no crates.io package, so no RustSec package page (inapplicable with reason); toolchain CVEs are tracked via Rust release notes, none open against stable at retrieval; recommended template code uses safe Rust only. (4) OS: pass — rustup stable toolchains ship for `ubuntu-latest` and `macos-latest` (owner-fixed matrix); Windows noted as informative only. (5) Features/async: inapplicable — the gate has no feature flags and no runtime coupling. (6) Cost: `check` emits metadata without codegen, the cheapest compile gate; binary size inapplicable (nothing ships). CLI/library/web fit: one invocation covers all three members via `--workspace`.

##### Recommendation

`cargo check --workspace --all-targets --locked` as the sole type-gate engine, exposed as `just typecheck` (alias `tc`), with rust-analyzer's default `cargo check` flycheck as the editor side of the single-engine design.

##### Ranked runner-up

`cargo build --workspace --all-targets --locked` — runner-up only for contexts that need artifacts from the same step (e.g. R50's install-smoke owns its own builds; this gate does not).

##### Tradeoffs

`check` over `build` trades away artifact production for ~codegen-free speed with zero loss of type signal. Single-engine over py's two-engine split trades away an independent IDE-strictness voice for guaranteed editor≡CI agreement — the right trade because rustc's type errors are not configurable per-engine the way `ty`/`pyright` rule sets are. No-wrapper over `cargo-hack` trades powerset exhaustiveness for CI-leg frugality per R11.

##### Parameters

Owns none (this item owns no parameter per `## Couplings`). Assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`, `target-os-matrix = ubuntu-latest, macos-latest`, `license = MIT OR Apache-2.0` (all owner-fixed). Assumes `ci-job-structure` (R11): this engine arrives as ordered steps of the Tier-2 `check` job (feature-off clippy/check scoped `-p` to non-web packages, feature-on workspace check), never as its own cache-bearing job. No `CONFLICT:` lines.

##### Migration implications

Template files: `Justfile` gains a `typecheck` recipe (alias `tc`) running the locked workspace-wide check in both feature legs per R11; `.github/workflows/ci.yml` gains the corresponding ordered steps inside the existing `check` job (R11 owns the job shape); no new crate dependency, no new config file for the engine itself. rust-analyzer needs no committed settings file for engine parity (its default *is* `cargo check`; any editor settings remain R28's).

##### Validation strategy

Proposed (not executed beyond the narrow probe): in a rendered template, (a) `just typecheck` exits 0 clean; (b) introduce one E0308 in each of lib/bin/web/tests in turn — each fails `just typecheck`; (c) run with `--offline` after vendoring to prove `--locked` determinism. Executed: the `/tmp/r30probe` E0308 pass/fail pair (exit 101 on error, 0 clean) on rustc 1.98.1.

##### Confidence & re-verify trigger

High. The engine choice follows from language semantics (type errors are hard errors) plus the ledger baseline, and the probe confirms the mechanism. Re-verify if: rustc introduces a configurable type-strictness surface (unlikely), R11's feature-leg contract changes, or R69's web shape splits the workspace.

##### Sources

[Cargo `cargo check` reference](https://doc.rust-lang.org/cargo/commands/cargo-check.html), [Cargo continuous-integration guide](https://doc.rust-lang.org/cargo/guide/continuous-integration.html), [rust-analyzer manual (check/flycheck configuration)](https://rust-analyzer.github.io/manual.html), [2024 State of Rust survey results](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/) (all retrieved 2026-09-26).

#### strictness-suppression-severity

##### Landscape

Category facet: opt-in strictness configuration (F110), suppression-comment discipline (F111), and the warning-vs-error severity tier (F112). Bins: built-in — the `[lints]`/`[workspace.lints]` manifest table (stable since Cargo 1.74), crate-root `#![warn/deny/forbid(...)]` attributes, per-item `#[allow/deny/expect(...)]`, `RUSTFLAGS="-D warnings"`; established — the deny-warnings-in-CI convention practiced by tokio/clap-class projects; up-and-comer — none found that changes this surface (watchers/wrappers add no strictness semantics). Crate figures are inapplicable: every candidate is toolchain configuration surface, not a package; fitness is judged by the gate rubric (see Fit for this template).

##### Principles and implementation

F110: Rust's analogue of py's `[tool.ty.rules]` / ts's `strict` flag union is the `[lints.rust]` table (plus `[lints.clippy]`, whose *contents* belong to R28 but whose *table* is shared infrastructure). Two facts shape the recommendation. First, Rust's default *type* strictness is already maximal and non-configurable: type mismatches are E-errors, never warnings — there is no `strict: false` for the type system. The configurable surface governs warning-level lints only (soundness-adjacent and hygiene signals such as `unexpected_cfgs` and future-compat lints). Second, the workspace-inherited table (`[workspace.lints.rust]` + `[lints] workspace = true` per member) is the mechanism that keeps every member at one strictness with one edit point, mirroring py's single `[tool.ty.rules]` table. Recommended table contents stay minimal and reviewable: `unexpected_cfgs` denied with an explicit `check-cfg` list covering the template's feature-gated `cfg`s (so a typo'd feature flag fails the gate instead of silently disabling code), while broad warning denial is left to CI flags (below) so a new-toolchain lint warns locally before it fails remotely. Crate-root `#![deny(...)]` attributes are the qualified alternative but scatter configuration across members; the manifest table is preferred exactly because it centralizes. `unsafe_code` level is owned by R06 and is not set here.

F111: the discipline "every suppression names its rule" is free from Rust syntax — `#[allow(unused_variables)]` and `#[expect(dead_code)]` cannot name nothing, and `#[expect]` (stable since 1.81) additionally fails when the suppression becomes unnecessary, making suppressions self-cleaning. The one gap vs py's enforcement is blanket `#[allow(warnings)]` / `#![allow(warnings)]`, which the compiler accepts silently; this is closed by review convention (forbid it in the template's contribution guidance, owned where R28/R40 place such guidance), not by tooling — no `CONFLICT:` needed since no parameter governs it. No clippy-specific suppression convention is decided here (R28 owns clippy's surface); the named-suppression principle is shared.

F112: `cargo check` has a warning tier (warnings print, exit stays 0 — proven in the executed probe), and this template's CI denies it: `RUSTFLAGS="-D warnings"` on the CI typecheck steps, so every warning fails the gate ts-style rather than informing py-style. Rationale: rustc warnings include future-compat lints (tomorrow's hard errors) and the template must not accumulate them silently. The local/hook invocation omits the flag, so developers see warnings without a broken inner loop on toolchain upgrades. The R11 msrv-floor leg stays a plain floor check (Cargo's own guide shape), with denial applied on the check-matrix legs only.

##### Dominant choice

`[workspace.lints.rust]` table in the root `Cargo.toml` (minimal explicit levels, `unexpected_cfgs` denied with `check-cfg`), inherited via `[lints] workspace = true` in every member; named `#[allow]`/`#[expect]` suppressions with blanket `allow(warnings)` forbidden by convention; `RUSTFLAGS="-D warnings"` on CI typecheck steps only. [Cargo `[lints]` manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section), [Cargo workspace `lints` inheritance](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table), [rustc lint levels](https://doc.rust-lang.org/rustc/lints/index.html) (retrieved 2026-09-26).

##### Qualified shortlist

Two qualify: (1) crate-root `#![deny(unexpected_cfgs, ...)]` attributes — same enforcement, qualifies for single-crate layouts, but scatters config across workspace members; (2) `--deny warnings` passed per-invocation via `RUSTFLAGS` everywhere including local hooks — qualifies as the maximally strict option, but breaks local builds on new-toolchain lints and is rejected for the inner loop while adopted for CI. Both pass every applicable gate.

##### Excluded by gate

None. No third-party candidate was evaluated for this facet (there is no strictness crate to evaluate — strictness is compiler surface), so no gate exclusion applies. A hypothetical "warnings-inform-in-CI" option (py's `error-on-warning = false` ported to rs) is design-rejected, not gate-excluded: it would let future-compat lints rot the template silently.

##### Up-and-comers

None qualified. No new tool changes the `[lints]`/attribute/`-D warnings` surface; `#[expect]` (2024) is the most recent relevant stabilization and is already folded into the dominant choice. No figures apply.

##### Fit for this template

Fitness gates: (1) License: pass — no dependency added; configuration surface only. (2) MSRV: pass with a floor note — `[lints]` tables require Cargo 1.74+, `#[expect]` requires rustc 1.81+; both predate any plausible stable-minus-2 floor in 2026, and the `rust-version` declaration plus R11's msrv-floor leg enforce the floor mechanically. (3) Advisories/`unsafe`: inapplicable — no package, no code; posture unchanged (safe template code). (4) OS: pass — manifest tables and flags are platform-independent; verified legs run on `ubuntu-latest, macos-latest` via R11. (5) Features/async: inapplicable — no features, no runtime. (6) Cost: zero build-time and zero binary-size cost; the only cost is human (explicit levels to review), which is the point. CLI/library/web fit: the workspace table covers all members uniformly, including the feature-gated web member.

##### Recommendation

Ship the `[workspace.lints.rust]` table with minimal explicit levels (`unexpected_cfgs` deny + `check-cfg`), inherit it in every member, adopt named-suppression discipline with `#[expect]` preferred over `#[allow]` for temporary suppressions, and deny warnings in CI only.

##### Ranked runner-up

Crate-root `#![deny(...)]` attributes — runner-up for templates that collapse to a single crate; loses on centralization for this multi-member workspace.

##### Tradeoffs

Manifest table over attributes: centralization and one-edit strictness changes, at the cost of learning one more manifest section. CI-only denial over deny-everywhere: a warning-tolerant inner loop and clean toolchain upgrades, at the cost of a local/CI behavior gap that the pre-push hook (member 3, running the plain recipe) deliberately narrows but does not close — CI remains authoritative. `#[expect]` over `#[allow]`: self-cleaning suppressions at the cost of requiring rustc 1.81+ (already under the floor).

##### Parameters

Owns none. Assumes the four owner-fixed parameters (`rust-edition`, `msrv-policy`, `target-os-matrix`, `license`) as in the check-engine member. Assumes `ci-job-structure` (R11): `-D warnings` is an env addition on the existing `check`-job steps, not a new job. Defers `unsafe_code` level to R06 (`unsafe-code-policy`) and clippy-table contents to R28 — no `CONFLICT:` lines (deferral, not a needed change).

##### Migration implications

Template files: root `Cargo.toml` gains `[workspace.lints.rust]` (with `check-cfg` for the template's feature `cfg`s); every member `Cargo.toml` gains `[lints] workspace = true`; `Justfile` `typecheck` recipe sets `RUSTFLAGS="-D warnings"` only when invoked with a `ci=true` parameter (or the CI workflow sets the env on those steps — R11's file owns the final placement); contribution guidance records the named-suppression + no-blanket-allow convention.

##### Validation strategy

Proposed (not executed): in a rendered template, (a) add `#[allow(warnings)]` to one item — `just typecheck` still passes (documents the review-convention gap honestly); (b) reference a nonexistent `cfg(feature = "typo")` — gate fails on `unexpected_cfgs`; (c) add an unused variable — local `just typecheck` passes with a warning, `RUSTFLAGS="-D warnings" just typecheck` fails. Executed: the `/tmp/r30probe` warning pair (exit 0 plain, exit 101 under `-D warnings`) on rustc 1.98.1, which proves mechanism (c) on the local toolchain.

##### Confidence & re-verify trigger

High for the mechanism, medium for the exact lint list (minimal contents are a judgment call the synthesizer may widen). Re-verify if: the template's feature/`cfg` set changes (`check-cfg` list must track it), R06 sets workspace-wide `unsafe_code` levels (merge tables, do not fork them), or a new stable promotes a warn-level lint the template trips (expected upkeep, not a design failure).

##### Sources

[Cargo `[lints]` manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section), [Cargo workspace `lints` inheritance](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table), [rustc lint levels and `warnings` group](https://doc.rust-lang.org/rustc/lints/index.html), [`#[expect]` stabilization (Rust 1.81 announcement)](https://blog.rust-lang.org/2024/09/05/Rust-1.81.0.html) (all retrieved 2026-09-26).

#### gate-scope-and-hook-tier

##### Landscape

Category facet: gate scope — shipped vs test code (F113) — and hook-tier placement — pre-commit vs pre-push (F106). Bins: built-in — `cargo check`'s default target set (lib+bins) vs `--all-targets`/`--tests`/`--benches`/`--examples` flags, lefthook `pre-commit`/`pre-push` tiers; established — `--all-targets` in CI (mainstream) with the hook tier varying by project; up-and-comer — none (scope/hook placement is a policy choice, not a tool race). Crate figures are inapplicable: both facets are flag-and-placement policy over the member-1 engine, not packages.

##### Principles and implementation

F113 (scope): the gate includes test code — `#[cfg(test)]` unit tests and the `tests/` integration-test target — via `--all-targets`, following ts's deliberate fix of py's under-checking (D-013(4)) rather than py's `src/`-only scope. The executed probe makes this load-bearing, not stylistic: bare `cargo check` exited 0 with a type-broken `tests/it.rs`; `--all-targets` failed with E0308. `--all-targets` additionally covers benches and examples, which a template ships as documentation-grade code that must also compile. `--tests` alone would be narrower but leaves benches/examples unchecked for no placement benefit, since all run in the same step.

F106 (hook tier): pre-push, py-aligned in mechanism and F147-aligned in principle. Three converging reasons. First, F147 (COMMON → REUSE) tiering philosophy: fast staged checks at commit, slower full-tree checks deferred later — and R11's Tier-2 rule says checks that compile are the heavyweight class. `cargo check --workspace --all-targets` compiles the workspace twice (feature-off + feature-on legs), needs a warm `target/` cache to be fast, and on a cold cache or a large change is a minutes-scale full-tree scan — exactly the class py's ADR-0018 kept out of pre-commit and exactly what F147 defers. Second, robustness: a pre-commit gate must pass on every commit including cold checkouts and partially-staged trees (staged-only checking would need stash dance or staged-worktree tricks that `cargo check` does not natively support); a pre-push gate runs on the full tree the push actually ships. Third, CI remains authoritative regardless (R11 check job), so pre-push is an early-warning mirror, not the enforcement point — the cost of deferring one tier is one failed push, not one broken main. ts's per-commit `tsc` is the counter-precedent, but `tsc --noEmit` neither compiles native code nor carries a two-leg feature matrix; the ecosystem difference justifies the different tier while preserving the shared tiering principle. The pre-push hook runs the plain recipe (no `-D warnings` promotion beyond the committed table) so it stays fast and warning-tolerant; CI applies denial.

##### Dominant choice

Scope: `--all-targets` on every typecheck invocation (recipe, hook, CI). Hook tier: `pre-push` in `lefthook.yml` running `just typecheck` (plain flags), with CI's `check` job (R11) as the authoritative enforcement point. [Cargo target-selection flags](https://doc.rust-lang.org/cargo/commands/cargo-check.html#target-selection) (retrieved 2026-09-26).

##### Qualified shortlist

Two qualify: (1) `--tests` instead of `--all-targets` — covers the F113 test-inclusion requirement with marginally less surface, but leaves template benches/examples uncompiled for no tier benefit; (2) pre-commit placement of the same recipe — qualifies mechanically (lefthook supports it; warm-cache runs are seconds), but violates the F147/R11 compile-tier principle on cold trees and is rejected as the default while remaining a documented local opt-in (`lefthook.yml` keeps the recipe one line away from either tier).

##### Excluded by gate

None. No package candidate exists for this facet, so no gate exclusion applies. A `src/`-only scope (py's shape ported to rs) is design-rejected, not gate-excluded: the probe proves it misses broken integration tests, reproducing exactly the under-checking ts's D-013(4) fixed.

##### Up-and-comers

None. Staged-only Rust checking helpers and remote-execution caches change hook *performance*, not the scope/tier policy, and none is mature or necessary enough to condition this template's default. No figures apply.

##### Fit for this template

Fitness gates: (1) License: pass — no dependency. (2) MSRV: pass — `--all-targets` and lefthook tiers predate any plausible floor. (3) Advisories/`unsafe`: inapplicable — policy only. (4) OS: pass — flags are platform-independent; the R11 matrix runs both OS legs. (5) Features/async: the feature dimension is load-bearing here — scope explicitly spans both R11 feature legs (off scoped `-p` to non-web packages, on workspace-wide), so feature-gated type errors cannot hide; no runtime coupling. (6) Cost: `--all-targets` adds test/bench/example compilation to each leg (qualitatively: the dominant hook cost, and the reason for pre-push); binary size inapplicable. CLI/library/web fit: `--workspace --all-targets` spans all three members plus their tests in one invocation per leg.

##### Recommendation

`--all-targets` scope on the `typecheck` recipe everywhere it runs; `pre-push` hook tier for the local mirror; CI `check` job authoritative.

##### Ranked runner-up

Pre-commit placement of the identical recipe — runner-up for developers with warm caches who opt in locally; not the template default.

##### Tradeoffs

`--all-targets` over default scope: full test/bench/example coverage at the cost of compiling more targets (the honest, probe-backed trade — default scope silently skips `tests/`). Pre-push over pre-commit: robust full-tree checking and a fast commit path, at the cost of later local signal (one failed push instead of one failed commit) — with CI authoritative either way, the cost is small and the F147 principle is preserved.

##### Parameters

Owns none. Assumes the four owner-fixed parameters as in the check-engine member. Assumes `ci-job-structure` (R11): enforcement lives in the Tier-2 `check` job's ordered steps (feature-off `-p`-scoped check + feature-on workspace check, each `--all-targets --locked`); the hook placement assumes the hook manager R37 provisions supports a pre-push tier (lefthook does; no value change needed). No `CONFLICT:` lines.

##### Migration implications

Template files: `Justfile` `typecheck` recipe carries `--all-targets` (both feature legs); `lefthook.yml` gains a `pre-push` entry running `just typecheck` (commands from the repo root, full tree — no `staged_files` filter); `.github/workflows/ci.yml` `check`-job steps carry `--all-targets` (R11 owns the job shape; this item supplies the flags). `tests/` stays in the default workspace layout so the flags find it.

##### Validation strategy

Proposed (not executed in-template): in a rendered template, (a) break one type in `tests/` only — `just typecheck` fails (scope proof); (b) break one type behind the optional feature — the feature-on leg fails while the feature-off leg passes (leg proof); (c) time `just typecheck` on a cold `target/` vs warm — record both to justify the pre-push tier quantitatively for the synthesizer. Executed: the `/tmp/r30probe` scope pair (bare check exit 0 vs `--all-targets` exit 101 on broken `tests/it.rs`) on rustc 1.98.1, proving (a)'s mechanism.

##### Confidence & re-verify trigger

High on scope (`--all-targets`; probe-backed and ts-precedent-backed). Medium-high on pre-push: the tiering argument is principled (F147/R11/ADR-0018-shape) but the cold-vs-warm timing for this exact template is unmeasured — re-verify with measurement (c) once the template renders; if warm runs prove consistently seconds-scale *and* cold runs stay tolerable, a future revision could admit pre-commit without changing any other member. Also re-verify if R37's hook manager cannot express a pre-push tier (would force a placement rethink, not a scope change).

##### Sources

[Cargo `cargo check` target selection](https://doc.rust-lang.org/cargo/commands/cargo-check.html#target-selection), [local divergence analysis (R30 item + F106/F111/F113 rows)](../../../docs/port/DIVERGENCE-ANALYSIS.md), [local commonality ledger (F105–F113)](../../../docs/port/COMMONALITY.md) (retrieved 2026-09-26).

### Compatibility

All three members are facets of one toolchain invocation plus repo configuration — there is no multi-crate version matrix to prove. Compatibility evidence: (1) the rust-analyzer manual documents `cargo check` as its default flycheck command, so member 1's editor≡CI claim is the tool's own out-of-box composition (engine + editor tested together upstream on every rust-analyzer release); (2) the Cargo Book documents that `[workspace.lints]` tables apply to `cargo check` runs, so member 2's strictness composes with member 1's engine by construction; (3) `--all-targets` and `RUSTFLAGS` are flags of that same invocation, so member 3's scope/severity compose trivially. The "shared adopter" is every rust-analyzer user running default settings against a `[lints]`-configured workspace — the mainstream shape. The single version axis is the Rust stable toolchain R42 provisions; no cross-crate version matrix applies (stated, not omitted).

### Parameters

`owns` — none. R30 owns no entry in `docs/port/PARAMETERS.md`; the `owns` column of `research/CLAUDE.md` row R30 is `—`, and this prompt's `## Couplings` `owns:` line is empty. This item's output is consumed as ledger rows F105–F108/F110–F113, not as a registry parameter.

`assumes rust-edition = 2024` — owner-fixed. Unaffected: the gate runs on whatever edition the workspace declares.
`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — owner-fixed. Consumed positively: `[lints]` tables (1.74+) and `#[expect]` (1.81+) predate the floor, and R11's msrv-floor leg enforces it.
`assumes target-os-matrix = ubuntu-latest, macos-latest` — owner-fixed. Unaffected: flags and tables are platform-independent; enforcement legs run on both runners via R11.
`assumes license = MIT OR Apache-2.0` — owner-fixed. Unaffected: no dependency is introduced.
`assumes ci-job-structure = <R11 accepted value>` — the full Tier-0/1/2 detector-and-check structure in `inputs/parameters.json` (R11, acceptance `774f7649…`). Consumed: typecheck arrives as ordered steps of the Tier-2 `check` job (feature-off `-p`-scoped leg + feature-on workspace leg, each `--all-targets --locked`, `-D warnings` via env on CI), never as its own cache-bearing job; enforcement placement, triggers, and permissions are R11's.

No `CONFLICT:` lines. Deferrals (not conflicts): `unsafe_code` level to R06, clippy-table contents and F109 extension pick to R28, hook-manager provisioning to R37, `check-cfg` value list tracks the feature set R69/R77 shape.

### Migration implications

File-level changes in the rendered template (requests to the implementation plan, not edits made here):

- `Justfile`: new `typecheck` recipe (alias `tc`) — `cargo check --workspace --all-targets --locked` in the feature-off scope (`-p` non-web packages) and feature-on workspace scope per R11, with a `ci` parameter (or env passthrough) controlling `RUSTFLAGS="-D warnings"`.
- `Cargo.toml` (root): new `[workspace.lints.rust]` table with minimal explicit levels (`unexpected_cfgs` deny + `check-cfg` for the template's `cfg`s); exact lint list left for the synthesizer to widen.
- Every member `Cargo.toml`: `[lints] workspace = true` inheritance line.
- `lefthook.yml`: `pre-push` entry running `just typecheck` (full tree, no staged filter); no pre-commit entry for the gate.
- `.github/workflows/ci.yml`: ordered typecheck steps inside R11's existing `check` job (R11 owns the job; this item supplies flags + env).
- Contribution guidance (wherever R28/R40 place it): one paragraph — suppressions must name their lint (`#[expect]` preferred), blanket `allow(warnings)` forbidden.

No new crate dependency, no new toolchain install, no `rust-version` change, no settings file for engine parity.

### Validation strategy

Commands that prove the principle holds in a rendered template (proposed, not executed — no template workspace exists in this research repo; the executed subset is the `/tmp/r30probe` pairs noted in-line):

1. `just typecheck` on a clean tree → exit 0 (gate green baseline).
2. Introduce one E0308 in `src/`, then in `tests/`, then behind the optional feature → each fails `just typecheck` (engine + scope proof). Mechanism executed on rustc 1.98.1: E0308 → exit 101; broken `tests/` missed by bare `cargo check` (exit 0), caught by `--all-targets` (exit 101).
3. Add an unused variable → plain `just typecheck` passes with a warning; `RUSTFLAGS="-D warnings" just typecheck` fails (severity-tier proof). Mechanism executed: exit 0 plain, exit 101 denied.
4. Misspell a feature `cfg` (`cfg(feature = "typo")`) → gate fails on `unexpected_cfgs` (strictness proof, proposed).
5. Time `just typecheck` cold (`cargo clean` first) vs warm → record both; expected: warm seconds, cold minutes-scale, justifying pre-push (tier proof, proposed).
6. Open the workspace in rust-analyzer with default settings → the same E0308 from (2) surfaces as an editor diagnostic without configuration (single-engine proof, proposed).

Expected behavior overall: the gate is red on any type error in any member/leg/target, red on any warning under CI flags, green otherwise; the editor agrees with CI by construction.

### Confidence & re-verify trigger

Overall confidence: high on engine (`cargo check`, no wrapper), single-engine editor≡CI, `--all-targets` scope, and CI-deny-warnings — all probe-backed or language-semantic. Medium on the exact `[lints]` contents (minimal list is judgment) and on pre-push (principled via F147/R11 but unmeasured on this exact template — validation item 5 closes it).

Re-verify triggers: R11's feature-leg contract or `check`-job shape changes; R06/R28 set workspace lint levels that must merge with (not fork) the `[workspace.lints]` table; R37's hook manager cannot express pre-push; R42 changes toolchain provisioning; the template's feature/`cfg` set changes (`check-cfg` must track it); a new stable introduces a type-strictness surface or a warn-level lint the template trips (expected upkeep).

Evidence gaps (recorded, not filled): no crates.io/GitHub figures — correctly inapplicable (no crate members); third-party CI-file practice claims (tokio/clap deny-warnings gates) cited from ecosystem knowledge with retrieval date but not live-fetched in this leg (network constrained to the topic's named endpoints; doc pages are stable first-party references); cold-vs-warm hook timing unmeasured (needs the rendered template); `cargo-hack`/`bacon` figures not collected (no adoption recommended).

### Sources

- [Cargo `cargo check` reference](https://doc.rust-lang.org/cargo/commands/cargo-check.html) (retrieved 2026-09-26) — engine, flags, target selection.
- [Cargo `[lints]` manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section) (retrieved 2026-09-26) — strictness table.
- [Cargo workspace `lints` inheritance](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table) (retrieved 2026-09-26) — one-edit strictness.
- [Cargo continuous-integration guide](https://doc.rust-lang.org/cargo/guide/continuous-integration.html) (retrieved 2026-09-26) — locked workspace-wide CI shape.
- [rustc lint levels](https://doc.rust-lang.org/rustc/lints/index.html) (retrieved 2026-09-26) — levels, `warnings` group.
- [rust-analyzer manual](https://rust-analyzer.github.io/manual.html) (retrieved 2026-09-26) — `cargo check` default flycheck (single engine).
- [Rust 1.81.0 announcement (`#[expect]` stabilization)](https://blog.rust-lang.org/2024/09/05/Rust-1.81.0.html) (retrieved 2026-09-26).
- [2024 State of Rust survey results](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/) (retrieved 2026-09-26) — ecosystem context.
- [Local divergence analysis (R30 rows)](../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-26).
- [Local commonality ledger (F105–F113)](../../../docs/port/COMMONALITY.md) (retrieved 2026-09-26).
- Executed probe: `/tmp/r30probe`, rustc/cargo 1.98.1, 2026-09-26 (E0308 fail/exit-101, warning exit-0/exit-101 pair, scope exit-0/exit-101 pair) — scratch, not committed.
