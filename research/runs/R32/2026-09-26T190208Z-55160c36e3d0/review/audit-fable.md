actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 8706d06dea3a4b75899193fbfb128364a57267994a3b9754b3ffc2e89ab07a39
verdict: reject
unresolved-findings:
1. JF-1/JF-2/JF-10 — feature scope of the local suite (`just test`) and the pre-push hook is undefined, and M2 claims a scope the recipe does not have (load-bearing)
2. JF-2/JF-3 — the HIGH question's "partitioned execution order" part is unanswered, and both legs' partitioning statements are absent from `## Engines`
3. JF-2 — `predicates` (a declared M3 crate member) lacks its open-issue and responsiveness figures, with no reason and no gap entry (low severity)

# R32 judgment audit — revision 1

Target: `research/runs/R32/2026-09-26T190208Z-55160c36e3d0/review/DECISION.md`. The sha256 was recomputed with `shasum -a 256` before anything else was read. It equals the expected `8706d06d…a07a39`.

Scope: this audit judges reasoning and fidelity, not execution. Log contents were spot-checked; no script was rerun. The auditor read these inputs: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §2–§5; the four raw reports at cited lines; `review/evidence/*.log`, `SHA256SUMS-fixture`, `fixture/` and `snapshots/`; and the cited lines of the R01, R11, R49 and R69 `DECISION.md` files. The auditor also read `docs/port/PARAMETERS.md` (live registry) and `docs/port/OWNER-ACCEPTANCES.md`. No `review/audit-*.md` of any seat or revision and no snapshot file was read. Git was not written, the runner was not called, and no paid API was used.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | See Finding 1. M2 (`DECISION.md:201`) claims `cargo test --doc` "runs with the same feature selection as the feature-on test step". The committed recipe (`:113-115`) cannot do that. Everything else is consistent: M1–M6 match the F-row table, the config, the recipes, the layout and the `CONFLICT:` line. The 30 s × 2 = 60 s cap is used the same way throughout. |
| JF-2 every question answered, every constraint honoured | **fail** | See Findings 1–3. The following are answered: runner choice (M1), timeouts (E3), shuffle (E4c, E9h), CLI tiers (M3/M4), taxonomy (M5), `serial_test`/parallelism (Disagreements 3 and 6), doc-tests (M2), the hook (M6) and the cross-repo principle (`:60-75`). The fitness gates are answered per crate; gate 1 is `inapplicable` per Q7.B, confirmed at R01 `DECISION.md:3`. Stable only, edition 2024 and the 1.96 floor are honoured (E7). Not answered: "partitioned" (Finding 2). One crate figure is missing (Finding 3). |
| JF-3 `## Engines` faithful, disagreements adjudicated | **fail (partial)** | Spot-checked representations are faithful: OpenAI 0.9.145 at `doxa-openai.normalized.md:285`, serial default `:86`/`:295`, `rs-launch` bin `:227`, no `assert_cmd` `:297`/`:627`, `RS_LAUNCH_PREPUSH_TESTS` `:718`. Gemini `slow-timeout = "60s"` at `:207`, `cargo_bin("rs-launch-blueprint")` `:166`, wrong figures `:176`/`:178`. Muse `serial_test` `:467` (3.5.0 at `:135`), timeout `:220-221`, abbreviated assumes `:687`. Opus `CONFLICT` `:1144`, `serial_test` exclusion `:436-448`. All 13 disagreements are resolved on executed or fetched evidence. Omission: partitioning (Finding 2). |
| JF-4 load-bearing claims trace | pass | Snapshot lines are verbatim at the cited numbers. `nx-running.md:58` says doctests are unsupported and must run with `cargo test --doc`. `nx-default-config.toml:25` is `test-threads = "num-cpus"`. `:63` is `slow-timeout = { period = "60s", on-timeout = "fail" }`, which has no `terminate-after`. `cargo-targets.md:126-127` says integration binaries run serially. `nx-test-groups.md:21` says in-process mutexes are unsupported and emulated by groups. `nx-setup-scripts.md:14` marks setup scripts experimental. `rustc-tests-index.md:211` marks `--shuffle` unstable. `serial_test-README.md:34` names `file_serial`. Every `### Members` figure equals `r32-sources.log:25-53`. |
| JF-5 couplings hand over owned choices | pass | The hook manager and file are left to R37 (`:209`). R35 still picks the coverage tool (`:177`, E9p). R48 is handed a doubles shape only. R33 suites are left untouched. `[lib] doctest` is left to R82 (`:201`). `run`'s signature is left to R60/R67 (`:173`). `axum-test` is decided because R69 handed that call to R32 (R69 `DECISION.md:2310-2316`, verified). R11's steps are not silently changed; a `CONFLICT:` line is raised instead. |
| JF-6 assumes lines byte-identical to live registry | pass | All nine `assumes` values were compared programmatically with the `docs/port/PARAMETERS.md` value column. All nine are equal, with equal lengths (118, 4, 27, 17, 763, 8093, 667, 1818, 2638 characters). |
| JF-7 no conflict with accepted/published prereq values | pass | All five prerequisite `DECISION.md`/`acceptance.json` pairs hash to the values in `inputs/prerequisites.json`. The following are respected: R01 port injection, R42 `cargo nextest` plus `command -v`, R49 `rslbp`/`CARGO_BIN_EXE_rslbp` (R49 `DECISION.md:13-14`, `:727-731`), and R69's file-level cfg and `tower` `oneshot`. The only departure from a registered value (R11 `cargo test`) is declared as `CONFLICT:`, not adopted. |
| JF-8 evidence scripts exist; counts match | pass | All 11 scripts and their logs exist. PASS/FAIL counts per log are 5, 29, 22, 12, 4, 22, 6, 8, 23, 116 and 4, with FAIL = 0 everywhere. The total is 251, as the decision states. `shasum -c SHA256SUMS-fixture` reports OK for 15 files. `fixture/.config/nextest.toml` sha256 is `e6ab4bed…`, as stated. `Cargo.lock` locks 26 packages, which is 25 plus the package itself, as stated. |
| JF-9 decision shape | pass | The four H2s required by RUNBOOK §5 are present: `## Decision` (recommendation, versions, F rows, `### Principles and implementation`, `re-verify:` at `:232`), `## Parameters` (fixed and assumed), `## Empirical check` (host, toolchains, working directory, commands, observed output) and `## Engines`. There is no `## Supersedes`, which is correct for revision 1. |
| JF-10 recommendation follows from evidence | pass, subject to Finding 1 | Alternative A is rejected on stable per-test timeouts (E3m, E3n), and B realises P3 without shuffle (E4a/E4b). The `serial_test` rejection is backed by E4e–E4j and the maintainer and nextest documentation. The tier-per-binary choice is backed by E5a/E9g and E2l–E2m2. The evidence supports the stack. What it does not support is the local suite's scope (Finding 1). |

## Findings

### Finding 1 — local suite and hook feature scope (JF-1, JF-2, JF-10; load-bearing)

**Failed claims.**
- M2 (`DECISION.md:201`): "It runs with the same feature selection as the feature-on test step, so examples inside the `web` module compile too."
- F132 row (`:34`): "`cargo test --doc --locked` in `just test`, the hook and the CI gate".
- F117 row (`:26`): "CI runs the same two commands".
- P10 / F173: the hook is the "pre-push full suite".

**Evidence.**
- The committed recipe `test *options:` forwards `{{options}}` only to `cargo nextest run --locked {{options}}`. `cargo test --doc --locked` receives no feature flag (`:113-115`, identical in `fixture/Justfile`).
- `tests/web/main.rs` is `#![cfg(feature = "web")]` (`:152`, E2i).
- The executed hook ran `just test` with the feature off: `r32-hook.log`, E8e, `Summary … 4 tests run: 4 passed, 2 skipped`. The web tier's 2 tests (E2m) did not run.

As a result, the default local suite and the opt-in pre-push "full suite" never run the web tier. They also never run doc examples under the feature-gated `src/web/` tree. `just test --features web` would run the web tier under nextest, but its doc-test step would still run feature-off. M2's feature claim holds only for the doc step proposed in the `CONFLICT:` line for CI. The decision never states which features `just test` runs. The prompt's value test names exactly this surface: "the CI test step, and any pre-push hook wiring all get rewritten".

**Repair.** Choose the local scope and state it. One option: `just test` runs the feature-on suite, with the same features passed to both the nextest step and the doc-test step. The other option: `just test` is deliberately feature-off, and a named recipe covers `web`, with the hook's "full suite" wording corrected. Then fix the recipe so the doc step receives the same feature selection as the nextest step. Rerun E8 with a web-tier test present, and rewrite M2 to name the command its feature claim applies to.

### Finding 2 — "partitioned execution order" unanswered (JF-2, JF-3; low severity)

**Failed claim.** The HIGH question (`inputs/prompt.md:34`) asks whether nextest provides "randomized/partitioned execution order (F124) natively". The decision answers only randomisation: "cargo-nextest has no shuffle" (`:39`). The words "partition" and "shard" appear nowhere in the decision except inside R11's `assumes` text.

**Evidence.** Opus reports that nextest offers partitioning (`raw/opus.md:196-197`: "sliced" and "hashed" sharding across CI machines, `ci-features/partitioning.md`). Muse says "sharding uses nextest `--partition` (CI concern, not template default)" (`raw/muse.md:555-557`). Neither position appears in `## Engines`.

**Repair.** Add one sentence with a pinned nextest documentation citation. It should say that nextest natively offers `--partition count:M/N` and `hash:M/N` sharding. It should say that sharding splits a run across machines and does not randomise order, so it does not realise F124. It should say that sharding is not adopted, because job and runner topology belongs to R11. Represent both legs' statements in `## Engines`.

### Finding 3 — missing `predicates` figures (JF-2; low severity)

**Failed claim.** The `### Members` table (`:194-195`) gives `predicates` open issues as "not fetched" and responsiveness as "not measured". Neither entry carries a reason, and neither appears in gaps G1–G8.

**Evidence.** The prompt (`inputs/prompt.md:75`) says: "bundle members require the crate figures for each crate member". It also says that if a metric is inapplicable, the answer must "state `inapplicable` and the reason … do not omit it silently". `predicates` 3.1.4 is a named M3 member. Its repository figures were fetched (`r32-sources.log:45`), but its open-issue search was not.

**Repair.** Run the read-only `GET https://api.github.com/search/issues?q=repo:assert-rs/predicates-rs+is:issue+is:open` and the 10-newest-issues responsiveness measure. Alternatively, record each metric as a gap with a reason. A valid reason would be "reached only through `assert_cmd`, never called directly", but it must be stated.

## Observations (not findings; controller/owner business)

- **Engine swap (controller note a).** The frozen `inputs/prompt.md:26` lists `codex, opus, doxa`, but the legs are Muse, Opus and Doxa. The decision explains this by citing Q17.A at `RUNBOOK.md:73-76`, which the auditor verified. Repair: the controller re-freezes the inputs and cites Q17.A. This is not a synthesis defect.
- **`CONFLICT: R11 ci-job-structure` (controller note b).** The conflict is well reasoned on its own terms:
  - The registered value names `cargo test` (R11 `DECISION.md:320`).
  - Stable libtest has no terminating per-test timeout (E3m, E3n), and nextest runs no doctests (`nx-running.md:58`).
  - R11's slot row hands R32 "the tier names inside `check`'s test steps" (R11 `:282`), and the "doc build" step is rustdoc (R11 `:294`).
  - The line adds no job and no cache-bearing job id.

  Disposition belongs to the controller.
- **Synthesizer staffing.** The synthesizer is `claude-opus-5-5`, the same model as the Opus leg, and RUNBOOK §2 names a fresh Claude Fable context. The decision flags this itself (G8). This auditor seat also resolves to `claude-opus-5-5`, so the family-independence limit applies to this audit too.
- **Owner-accepted, unpublished revisions.** R69 revision 10 (`OWNER-ACCEPTANCES.md` row at line 60) moves the web tests to `crates/web/tests/` (R11 `DECISION.md:329`). R02 revision 2 (line 71) sets a four-package workspace. The decision correctly consumes only the registered values and lists both as re-verify triggers (`:232`), in line with RUNBOOK §4 ("a consumer never adopts an unregistered value"). A related interaction must be settled in P03: R11's feature-off step is "scoped by -p to the non-web packages", while the root facade hosts `tests/cli/`. The decision lists this under "What P03 must validate".
- **`serial_test` version.** E4 ran `serial_test` 3.5.0, which is Muse's pin (`raw/muse.md:135`); the newest release is 4.0.1 (`r32-sources.log:37`). The rejection is scoped to that pin, and it rests on the in-process-lock mechanism, which the maintainer README and `nx-test-groups.md:21` also support. The rejection is acceptable as written.
- **"Byte-identical" wording.** `DECISION.md:110` calls the recipes and hook "byte-identical to `fixture/Justfile` and `fixture/lefthook.yml`". Both fixture files carry leading comment lines that the quoted blocks omit; the recipe and job bodies match exactly. `nextest.toml` is genuinely identical. Suggested wording repair: "the recipe and job bodies of…".
- **Muse provenance.** The Muse leg has no operation record in the run directory, and the decision states this.
- **Controller note c (tower-http 0.6.11 versus 0.7.x).** This concerns R75 and R78 and is not applicable to R32.
