# R33 — property-and-snapshot-testing (bundle) — Opus raw report

All retrieval dates are `2026-09-10` unless a different date is stated inline. Every crates.io figure comes from `GET https://crates.io/api/v1/crates/<name>` or `.../versions`; every GitHub figure from `GET https://api.github.com/repos/<o>/<r>` or `GET https://api.github.com/search/issues`. Source repositories are read through their programme pins: py at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` (cited below as `py@b08bccfb`) and ts at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` (cited as `ts@cb1cbcb2`). Third-party repositories are cited at a commit fetched today, named inline.

The reference stable toolchain used for the MSRV gate is **Rust 1.98.1 (2026-09-01)**, read from `https://static.rust-lang.org/dist/channel-rust-stable.toml` (`[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`, retrieved 2026-09-10). Under `msrv-policy` = "stable minus 2 minor versions", the template's declared floor is therefore **1.96**, and every candidate's `rust-version` must be **≤ 1.96**.

### Landscape

**The category this item decides.** Two adjacent but separable test *kinds* that sit on top of whatever base runner R32 picks: (a) **generative / property-based testing** — a test states an invariant over a described input space, a generator produces many inputs, and a shrinker minimizes any counterexample; (b) **golden-snapshot testing** — a test captures a serialized artifact (here, CLI `--help` text) and compares it against a committed reference file, with a first-class workflow for reviewing and accepting intentional changes. They are decided together because they share one question — does the template ship dev-dependencies that neither the toolchain nor the base runner provides — but they have no crate in common, so each member is judged on its own.

**Three-bin map of the Rust field.**

| Bin | Property-based testing | Snapshot testing |
|---|---|---|
| Built-in / first-party toolchain | **None.** `cargo test` drives `libtest`, which supplies `#[test]`, `assert_eq!`, `#[should_panic]`, doc-tests and harness options only. There is no generator, no shrinker and no `Arbitrary`-style trait in `std` or in the shipped toolchain (The Cargo Book, "Tests", https://doc.rust-lang.org/cargo/guide/tests.html, retrieved 2026-09-10; The Rust Book ch. 11, https://doc.rust-lang.org/book/ch11-01-writing-tests.html, retrieved 2026-09-10). `cargo fuzz`/`libfuzzer` are a rust-fuzz working-group product, not a toolchain component, and target crash-finding rather than invariant assertion. | **None.** `libtest` has no snapshot concept and no update mode; the closest built-in is `assert_eq!` against a `include_str!` fixture, which has no accept workflow. |
| Established industry standard | **`proptest`** (Hypothesis-lineage: explicit `Strategy` objects, integrated shrinking) and **`quickcheck`** (Haskell QuickCheck lineage: type-directed `Arbitrary` + `shrink`). `arbitrary` is the standard *unstructured-bytes-to-typed-value* decoder for fuzzing, not a property-test runner, and appears here as an adjacent category rather than a candidate. | **`insta`** (external `.snap` files + `cargo insta review`), with **`snapbox`** (assert-rs; inline `str![]` and `file![]` data, `SNAPSHOTS` env update) and **`expect-test`** (rust-analyzer; minimal inline `expect![[...]]`) as the two established alternatives. |
| Up-and-comer | **`bolero`** — one façade over property testing *and* fuzzing engines (libFuzzer/AFL/honggfuzz/Kani), 0.13.4, 256 stars. Real but pre-1.0 and an order of magnitude smaller than proptest. | **`insta-cmd`** (0.7.0, 52 stars) — spawns a built binary and snapshots its stdout/stderr/exit code through insta; **`trycmd`** (assert-rs, snapbox's sibling) — runs `.trycmd`/`.md` transcript files as tests; **`goldenfile`** (1.11.0, 45 stars) — plain file-fixture comparison with a `REGENERATE_GOLDENFILES` mode. |

Every shortlisted candidate below is drawn from this map; none was admitted from familiarity.

**Authoritative sources used, and why each counts.**

1. **Rust project publications** (`doc.rust-lang.org` Cargo Book and Rust Book, retrieved 2026-09-10) — the normative statement of what the toolchain does and does not provide. This establishes the first bin as empty, which is the load-bearing fact: *any* answer here adds dev-dependencies or drops the capability.
2. **`rust-lang/cargo`'s own test suite** (https://github.com/rust-lang/cargo, `Cargo.toml:87` → `proptest = "1.11.0"`, used from `crates/resolver-tests/tests/proptests.rs`; commit `e7506208ff1b`, 2026-09-08, retrieved 2026-09-10). A rust-lang-org repository choosing a third-party crate for its own dependency-resolver invariants is Rust-project practice evidence, not a blog opinion.
3. **`rust-lang/rust-analyzer`** (https://github.com/rust-lang/rust-analyzer, `Cargo.toml:113` → `expect-test = "1.5.1"`, commit `a879a4cbadc3`, retrieved 2026-09-10) — a rust-lang-org repository that authored and uses its own snapshot crate. Authoritative for the *inline-snapshot* school, and the reason `expect-test` is on the shortlist at all.
4. **Maintainers' own documentation** — the proptest book's "Differences between QuickCheck and Proptest" (https://proptest-rs.github.io/proptest/proptest/vs-quickcheck.html, retrieved 2026-09-10) is the maintainers' own comparison and states proptest's *cost* as well as its benefit, which is why it is usable as evidence rather than marketing; insta's documentation site (https://insta.rs/docs/cli/ and https://insta.rs/docs/quickstart/, retrieved 2026-09-10) for the review workflow and CI behavior; `docs.rs` for `proptest::test_runner::Config`, `snapbox` and `clap::Command`.
5. **`clap-rs/clap`'s own `--help` tests** (https://github.com/clap-rs/clap, `tests/builder/help.rs`, commit `48ed7869b91a`, retrieved 2026-09-10) — the single most on-point practice evidence in the field, because it is a CLI framework snapshotting exactly the artifact this item is about.
6. **Annual Rust survey — checked and unusable.** The 2025 State of Rust Survey results (https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/, retrieved 2026-09-10) do not break out testing-crate adoption in the published page. I record this as an evidence gap rather than substituting a number from elsewhere.

**Well-regarded projects surveyed, with the evidence that they are well regarded.** Each is a widely depended-upon, actively developed Rust project whose `Cargo.toml` was read at a named commit today, not asserted from memory.

| Project | Why it is a relevant, well-regarded reference | What it uses (file:line, commit) |
|---|---|---|
| `rust-lang/cargo` | The Rust project's own package manager; rust-lang org | `proptest = "1.11.0"` (`Cargo.toml:87`, `e7506208ff1b`) |
| `rust-lang/rust-analyzer` | The Rust project's official language server; rust-lang org | `expect-test = "1.5.1"` (`Cargo.toml:113`, `a879a4cbadc3`) |
| `clap-rs/clap` | The dominant Rust CLI framework and the likely R60 outcome; its tests are the CLI-help snapshot reference | `snapbox = "1.2.0"` (`Cargo.toml:197`), `trycmd = "1.2.0"` (`:195`), commit `48ed7869b91a` |
| `astral-sh/ruff` | Widely adopted Rust-implemented Python linter; large, fast-moving, CI-disciplined workspace | `insta = "1.35.1"` (`Cargo.toml:124`), `insta-cmd = "0.7.0"` (`:125`), `quickcheck = "1.0.3"` (`:154`), `snapbox = "1.0.0"` (`:181`), commit `c3813a501faf` |
| `astral-sh/uv` | Widely adopted Rust-implemented Python package manager; heavy CLI surface | `insta = "1.46.0", features = ["json", "filters", "redactions"]` (`Cargo.toml:328`, `a22198b1b536`) |
| `paradigmxyz/reth` | Major Ethereum execution client in Rust; correctness-critical serialization | `insta = "1.47"` (`Cargo.toml:624`), `proptest = "1.7"` (`:625`), `proptest-derive = "0.7"` (`:626`), commit `040bef7b319c` |
| `apache/arrow-rs` | Apache-governed reference implementation of Arrow in Rust | `insta = "1.46.3"` (`Cargo.toml:111`, `f9e02ba76ad1`) |
| `BurntSushi/regex` | The de-facto Rust regex engine | `quickcheck = "0.4.1"` (`Cargo.toml:33`) — pinned to a pre-1.0 line, i.e. legacy usage |

**Fit framing (step 4).** The template is CLI + library + web service, on `ubuntu-latest, macos-latest`, edition 2024, MSRV floor 1.96, license `MIT OR Apache-2.0`. The property-test target named by F122 is round-trip invariants at serialization seams; the snapshot target named by F123 is every command's `--help`. Both are *dev*-only concerns, which removes binary size from the decision entirely and makes contributor workflow and CI enforcement the dominant criteria.

### Principles and implementation

**The shared requirement, its source, and its agreement level.**

Two distinct principles are in play, and they agree at different levels.

*Principle A (F122) — invariants at serialization seams are checked over a described input space, not over hand-picked examples.* Source: py@b08bccfb `tests/core/test_properties.py`, whose own docstring states the rationale: "Example-based tests check the cases we thought of; these check a *property* of every input Hypothesis can generate, at the two seams where a silent serialization bug would be costly: the domain model's JSON wire form and the config file's persist→reload cycle." Agreement level: **capability** — "the template ships generative round-trip testing at its serialization seams, with automatic counterexample minimization and reproducible replay of a discovered failure." The *library* is free to vary per ecosystem; the two named seams (domain-model wire form, config write→read) and the shrink-and-replay behavior are what must agree.

*Principle B (F123) — every command's help text is a reviewed artifact, and an unintended change to it fails the build.* Source: py@b08bccfb `tests/cli/test_help_snapshots.py`: "A renamed flag, reworded help line, or dropped command shows up as a reviewable snapshot diff in the PR instead of silently changing the CLI's UX." Agreement level: **policy plus one architectural property** — the policy is "help output for *every* command, discovered by walking the command tree rather than by an enumerated list, is compared against a committed reference; drift fails CI; regeneration is one documented command." The architectural property that must agree is that the reference lives in a **committed file separate from the test source**, because that is what makes the diff reviewable in a pull request. Presentation details — file format, macro spelling, review UI — may vary.

*What must vary by ecosystem, and why.* py's mechanism is `Hypothesis` + `pytest`-fixture-injected `syrupy` `snapshot`, both plugin-shaped because pytest's extension model is fixtures and plugins. Rust's `libtest` has no plugin model at all: a Rust test is a plain function, so the same principles are realized as a macro that *is* the test body (`proptest! { … }`) and a macro that *is* the assertion (`insta::assert_snapshot!`). This is a justified ecosystem difference, not drift.

**Observable acceptance criteria.** Independent of library choice, the answer is correct only if all of the following hold in the built template:

1. `cargo test` (no extra flag, no feature, no env var) runs both the property tests and the help snapshots. Both suites are in the default path, matching py, whose `addopts = "-m 'not live and not slow'"` (py@b08bccfb `pyproject.toml:278`) excludes neither file because neither carries a `slow` or `live` marker.
2. A deliberately introduced round-trip bug (for example, dropping a field in a serializer) makes `cargo test` fail with a **minimized** counterexample, not merely with the first random input that broke.
3. That failing input is **replayable**: rerunning the suite reproduces the same counterexample without relying on a remembered seed.
4. Renaming a CLI flag makes `cargo test` fail, and the failure output shows a textual diff of the old and new help.
5. A newly added subcommand is covered without editing a list of command names.
6. In CI, an unreviewed snapshot change **fails**; it is not silently accepted and it does not write files into the workspace.
7. Regenerating snapshots after an intentional change is one documented command, and the resulting file change is visible in `git diff`.

**Architectural alternatives compared before any library was chosen.**

*For Principle A:*

- **A1 — no generative testing; hand-written table tests over a fixed corpus.** Zero dependencies, zero compile cost. Rejected: it cannot satisfy criterion 2 (minimization) or the principle at all — it is the absence of the capability, and there is no Rust-specific reason the capability is inappropriate here. If adopted it would be a deliberate capability drop, and the ledger row F122 would need to change from "carry the principle" to "declined".
- **A2 — coverage-guided fuzzing instead of property testing** (`cargo-fuzz` + `arbitrary`, or `bolero` in fuzz mode). Rejected on fit, not quality: fuzz targets require a nightly toolchain for `cargo fuzz`, run as a separate long-lived job rather than inside `cargo test`, and are tuned for crash-finding. The template's constraint is stable Rust only, and criterion 1 requires the checks to run in the default `cargo test`. Note that `arbitrary` shows 39.9M 90-day downloads — larger than any snapshot crate — precisely because it is a fuzzing dependency, so download rank across bins is not comparable.
- **A3 — a strategy-based property runner inside `cargo test`.** The only alternative that satisfies criteria 1–3 on stable. This is the chosen architecture; the library question then reduces to `proptest` vs `quickcheck` vs `bolero`'s property mode.
- **A4 — round-trip invariants expressed as `#[test]` + an explicit generator loop written by hand.** Possible, but re-implements shrinking badly or not at all, and every template consumer inherits that code. Rejected.

*For Principle B:*

- **B1 — spawn the built binary and snapshot its stdout** (`insta-cmd`, `trycmd`, or `assert_cmd`). Faithful to "what the user sees", but it makes the test depend on a build artifact, it re-introduces terminal-width and color environment sensitivity, and process spawning per command is slow on macOS runners. It also crosses into R32's built-binary test tier, so choosing it here would pre-empt an item this one does not own.
- **B2 — render help in-process from the parsed command definition and snapshot the string.** This is the exact structural analogue of py's `CliRunner().invoke(cli, [*path, "--help"])`: no subprocess, no built artifact, deterministic. In Rust with clap it is `Command::render_long_help(&mut self) -> StyledStr` ("Render the long help message (`--help`) to a `StyledStr`", https://docs.rs/clap/latest/clap/struct.Command.html, retrieved 2026-09-10), and `StyledStr`'s `Display` impl is documented as "Color-unaware printing. Never uses coloring." while a separate `ansi()` method opts into escape codes (https://docs.rs/clap/latest/clap/builder/struct.StyledStr.html, retrieved 2026-09-10). So `format!("{}", cmd.render_long_help())` is ANSI-free by construction — the Rust equivalent of py's need to force `COLUMNS`, but stronger, because color determinism is a type-level property rather than an environment variable. Wrapping width is pinned with `Command::term_width(…)`; clap's own tests use `.term_width(0)` for this purpose (`clap tests/builder/help.rs:367`, commit `48ed7869b91a`, retrieved 2026-09-10). I could not retrieve the doc text for `term_width` itself — the fetched `docs.rs` `Command` page listed it in the method index without the excerpt including its prose; the clap test line is the evidence I have for its role. Command-tree discovery uses `Command::get_subcommands` (present in the same method index), which is the direct analogue of py's `_walk`.
- **B3 — inline snapshots kept in the test source** (`snapbox::str![]`, `expect_test::expect![[…]]`, or `insta`'s `@"…"` inline form). Excellent for a library's unit tests and demonstrably good enough for clap and rust-analyzer. Rejected *for this principle*: it collapses the reference into the test file, so the pull-request diff mixes assertion text with test logic, which is the specific property Principle B says must agree. It also makes the "committed snapshot fixture files" named in this item's value test cease to exist.
- **B4 — external committed snapshot files with a review workflow.** Preserves the reviewable-diff property, is the direct structural analogue of py's `tests/cli/__snapshots__/test_help_snapshots.ambr`, and is what `insta` provides by default. Chosen.

Note one correction to a tempting argument: py's *other* snapshot test, `tests/web/test_openapi_snapshot.py` (py@b08bccfb), is **not** syrupy — it is a hand-rolled comparison against `docs/api/openapi.json`. So "one snapshot library covers both the CLI and the OpenAPI contract" is a possible future benefit of a general-purpose snapshot crate, not an existing py precedent, and it is R71's decision to make. I do not lean on it.

**Maturity, dependability, performance and integration cost.** Full figures are in each member below. The performance question for this item is *test-suite wall-clock and compile time*, not runtime throughput, because every crate here is a dev-dependency. I did not run a benchmark; the one performance claim I make is the maintainers' own, from the proptest book: "Generating complex values in Proptest can be up to an order of magnitude slower than in QuickCheck" because proptest keeps intermediate state to support integrated shrinking, whereas quickcheck shrinks statelessly from output values (https://proptest-rs.github.io/proptest/proptest/vs-quickcheck.html, retrieved 2026-09-10). For the workload this template presents — two round-trip properties over small strings and a bounded config map, at proptest's default 256 cases per property (`PROPTEST_CASES` "Overrides the default test case count of 256", https://docs.rs/proptest/latest/proptest/test_runner/struct.Config.html, retrieved 2026-09-10) — that constant factor is not decision-relevant, and I do not claim an absolute fastest option from unlike benchmarks.

**Minimal realistic example (proposed; not executed — no Rust code exists in this repository yet).**

`crates/<lib>/tests/properties.rs` — the analogue of py's two properties:

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn project_survives_json_round_trip(
        id in "[^\\p{Cc}\\p{Cs}]{0,60}",
        name in "[^\\p{Cc}\\p{Cs}]{0,60}",
        workspace in proptest::option::of("[^\\p{Cc}\\p{Cs}]{0,60}"),
    ) {
        let project = Project { id, name, workspace };
        let encoded = serde_json::to_string(&project)?;
        prop_assert_eq!(serde_json::from_str::<Project>(&encoded)?, project);
    }
}
```

`crates/<cli>/tests/help_snapshots.rs` — the analogue of py's `_walk` + snapshot:

```rust
use clap::{CommandFactory, Command};

fn walk(cmd: &Command, path: Vec<String>, out: &mut Vec<Vec<String>>) {
    out.push(path.clone());
    let mut subs: Vec<_> = cmd.get_subcommands().collect();
    subs.sort_by_key(|c| c.get_name());
    for sub in subs {
        let mut p = path.clone();
        p.push(sub.get_name().to_string());
        walk(sub, p, out);
    }
}

#[test]
fn help_snapshots() {
    let root = Cli::command().term_width(80);
    let mut paths = Vec::new();
    walk(&root, vec![], &mut paths);
    for path in paths {
        let mut cmd = root.clone();
        for seg in &path { cmd = cmd.find_subcommand(seg).unwrap().clone(); }
        insta::with_settings!({ snapshot_suffix => path.join("_") }, {
            insta::assert_snapshot!(cmd.render_long_help().to_string());
        });
    }
}
```

**How the behavior is verified.** See `### Validation strategy` for the commands. Everything there is *proposed*; nothing in this report was executed against a Rust workspace, because none exists.

**BASELINE-REVIEW.** None emitted. The ledger's classification of F122 and F123 as `DIVERGENT` / origin `py-only` is factually correct at both pins: py@b08bccfb has both suites, and ts@cb1cbcb2 has neither — I verified the ts side directly (`git grep -l -E "toMatchSnapshot|toMatchInlineSnapshot|fast-check|fc\.assert" cb1cbcb2` returns no files; `package.json` at that pin lists `vitest ^4.1.10` and `@vitest/coverage-v8 ^4.1.10` with no `fast-check`). That verification does, however, change the *rationale* the follow-on py/ts project should carry: vitest ships `toMatchSnapshot` in the box, so ts could have satisfied Principle B at **zero added dependency cost** and did not; and `fast-check` is the established TypeScript analogue of Hypothesis, so Principle A was available too. `TS_PORT_DECISIONS.md` records no decision against either (per this prompt's `## Context`). The absence is therefore best read as **accidental drift, not a justified ecosystem difference**, and the follow-on project should add both to ts. That is a rationale contribution, not a challenge to a recorded baseline, so it is not written as a `BASELINE-REVIEW:` line.

### Recommendation

**Adopt both capabilities. One stack, three members:**

```toml
[dev-dependencies]
proptest = "1.11"   # property-based round-trip tests (F122)
insta    = "1.48"   # committed CLI --help golden snapshots (F123)
```

plus the **`cargo-insta` 1.48** binary as a provisioned developer tool (a `cargo-<sub>` executable invoked as `cargo insta`, per the `package-manager-invocation` parameter), used for `cargo insta review` locally and `cargo insta test --unreferenced=reject` in CI.

Both test kinds run unconditionally in the default `cargo test` — no Cargo feature, no separate test target, no env var (the LOW question). `proptest-derive` and `insta-cmd` are **not** adopted at template-creation time; the reasoning is under their respective members' `Ranked runner-up` and `Up-and-comers` fields.

### Members

#### proptest

##### Landscape

Category: property-based testing runner for stable `cargo test`. Bin: **established industry standard** — the Hypothesis-lineage entry, and the one a rust-lang-org repository picked for its own correctness-critical tests. Competitors considered from the same map: `quickcheck` (same bin, Haskell-QuickCheck lineage), `bolero` (up-and-comer, unifies property testing and fuzzing), `arbitrary` (adjacent category — a fuzzing input decoder, not a runner), and the no-library alternative A1/A4 above. `proptest`'s own crates.io keywords name the lineage explicitly: `["property", "testing", "quickcheck", "fuzz", "hypothesis"]` (`proptest/Cargo.toml`, proptest-rs/proptest default branch, retrieved 2026-09-10) — which is also why it is the closest structural analogue of py's Hypothesis suite.

##### Principles and implementation

Realizes **Principle A**. `proptest! { #[test] fn name(x in strategy) { … } }` expands to a plain `#[test]` function, so it needs nothing from the base runner and is therefore compatible with any R32 outcome that still runs `#[test]` functions. Strategies are explicit values rather than a per-type trait, which maps one-to-one onto py's explicit `st.text(st.characters(exclude_categories=("Cs","Cc")), max_size=60)` composition — py deliberately narrows the alphabet so "the property is about *our* round-trip, not the encoder's escaping minutiae" (py@b08bccfb `tests/core/test_properties.py`), and proptest's regex-syntax-backed string strategies express exactly that narrowing. The maintainers' own comparison states the design difference and its cost: "QuickCheck generates and shrinks values based on type alone, whereas Proptest uses explicit `Strategy` objects"; "QuickCheck can only define one generator and shrinker per type"; "Shrinking happens automatically in terms of the input types"; and the tradeoff, "Generating complex values in Proptest can be up to an order of magnitude slower than in QuickCheck" (https://proptest-rs.github.io/proptest/proptest/vs-quickcheck.html, retrieved 2026-09-10).

Acceptance criterion 3 (replay) is met by **failure persistence**: proptest writes a discovered counterexample's seed to a `proptest-regressions/<test-file>.txt` file next to the test, and replays it on subsequent runs; `Config::failure_persistence` and the `PROPTEST_DISABLE_FAILURE_PERSISTENCE` env var control it (https://docs.rs/proptest/latest/proptest/test_runner/struct.Config.html, retrieved 2026-09-10). This is a **file-level consequence for the template**: that directory must be committed, and `.gitignore` must not exclude it. py has no equivalent artifact — Hypothesis keeps its example database in a `.hypothesis/` cache directory that is not committed — so this is a justified ecosystem difference that *strengthens* the principle (the counterexample travels with the repository rather than living in a developer's cache).

Reference implementation: `rust-lang/cargo`'s `crates/resolver-tests/tests/proptests.rs` (commit `e7506208ff1b`, retrieved 2026-09-10) — a maintained, first-party-org property suite over the dependency resolver.

##### Dominant choice

**Yes — `proptest` is dominant, by every figure and by first-party practice.**

| Figure | proptest | quickcheck | Endpoint |
|---|---|---|---|
| 90-day downloads (`crate.recent_downloads`) | **46,574,976** | 10,550,560 | `GET https://crates.io/api/v1/crates/<name>` |
| All-time downloads (`crate.downloads`) | **184,292,444** | 67,598,302 | same |
| Reverse dependencies (`meta.total`) | **10,387** | 1,536 | `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=1` |
| Stars | 2,231 | 2,790 | `GET https://api.github.com/repos/<o>/<r>` |
| Latest non-yanked release | 1.11.0, 2026-03-24 | 1.1.0, 2026-02-10 | `.../crates/<name>/versions` |

All retrieved 2026-09-10. quickcheck leads on stars only — a lagging popularity indicator dominated by BurntSushi's personal-repo following — and trails 4.4× on 90-day downloads and 6.8× on reverse dependencies. The decisive non-numeric evidence is `rust-lang/cargo` choosing proptest.

##### Qualified shortlist

**`quickcheck` 1.1.0** — passes every gate; a legitimate second choice.
- crates.io `GET /api/v1/crates/quickcheck`, retrieved 2026-09-10: `recent_downloads` 10,550,560; `downloads` 67,598,302.
- `GET /api/v1/crates/quickcheck/versions`, retrieved 2026-09-10: newest non-yanked `1.1.0`, `created_at` 2026-02-10, `license` "Unlicense OR MIT", `rust_version` "1.85.0", edition 2021.
- `GET https://api.github.com/repos/BurntSushi/quickcheck`, retrieved 2026-09-10: `stargazers_count` 2,790; `archived` false; `pushed_at` 2026-04-03T00:52:54Z.
- `GET https://api.github.com/search/issues?q=repo:BurntSushi/quickcheck+is:issue+is:open`, retrieved 2026-09-10: `total_count` **19**.
- Issue responsiveness (10 most recently opened issues, `GET /repos/BurntSushi/quickcheck/issues?state=all&sort=created&direction=desc`, maintainer = a comment whose `author_association` is OWNER/MEMBER/COLLABORATOR, retrieved 2026-09-10): 3 answered, all on day 0 (0.0/0.0/0.0 days) → **median 0.0 days among answered**; **7 of 10 unanswered**, the two most recent (#344 2026-02-25, #343 2026-02-20) still unanswered.
- Advisories: `https://rustsec.org/packages/quickcheck.html` returned **HTTP 404** (retrieved 2026-09-10) — RustSec publishes a package page only when an advisory exists, so 404 means no advisory.
- Maintenance state: **stable-quiet.** 1.1.0 (2026-02-10) was substantive, not a version bump — commits that day add `Gen::from_size_and_seed`, a no-shrink `Arbitrary` wrapper, and a shrinking-logic refactor (`GET /repos/BurntSushi/quickcheck/commits`, retrieved 2026-09-10); the most recent commit is 2026-04-03. So the release-gap trigger is investigated and cleared. The concrete signal keeping it out of `active` is triage, not code: 7 of the 10 most recent issues have no maintainer reply, and the newest two have been open since February 2026.
- Why it loses: the type-directed model needs a newtype per distinct generation policy for the same type, which is heavier than py's inline strategy composition for exactly this suite's shape; and `astral-sh/ruff` pins `quickcheck = "1.0.3"` (`Cargo.toml:154`, commit `c3813a501faf`) while `BurntSushi/regex` still pins `quickcheck = "0.4.1"` (`Cargo.toml:33`) — the visible adoption is legacy, not new.

**`bolero` 0.13.4** — see `Up-and-comers`.

##### Excluded by gate

**None.** All three property-testing candidates (`proptest`, `quickcheck`, `bolero`) pass all six fitness gates. Gate-by-gate for `proptest` 1.11.0:

1. **License** — `MIT OR Apache-2.0` (`GET /api/v1/crates/proptest/versions`, `license` field on 1.11.0, retrieved 2026-09-10). Exactly the template's `license` parameter. **Pass.**
2. **MSRV** — the published 1.11.0 declares `rust_version` **1.85** (crates.io `/versions`, retrieved 2026-09-10). Note a discrepancy worth recording: the repository's `proptest/Cargo.toml` at the default branch reads `rust-version = "1.86"` and CI's `pinned` job uses `1.86.0` (proptest-rs/proptest, retrieved 2026-09-10), i.e. HEAD has raised the floor ahead of the next release. Both are ≤ 1.96. Dependency-tree floor: the highest `rust-version` among proptest's required dependencies is **1.85** (`rand` 0.10.2, `rand_chacha` 0.10.0, `rand_xorshift` 0.5.0, `bit-set` 0.11.1 all declare 1.85; `regex-syntax` 0.8.11 declares 1.65; `tempfile` 3.27.0 declares 1.63; `bitflags` 2.13.2 declares 1.56.0; `num-traits` 0.2.19 declares 1.60; `unarray` 0.1.4 and `rusty-fork` 0.3.1 declare none) — read from `GET /api/v1/crates/<dep>/versions?per_page=1`, retrieved 2026-09-10. **Caveat:** I checked the newest published version of each dependency, not the exact set Cargo would resolve for `proptest = "1.11"` (proptest 1.11.0 requires `rand ^0.9`, whose resolved floor I did not separately query). The tree floor is therefore **≤ 1.85 as resolved, and 1.85 as measured on newest**. Either way it clears 1.96 with 11 minor versions of headroom. **Pass.**
3. **Advisories / `unsafe`** — `https://rustsec.org/packages/proptest.html` returned **HTTP 404** (retrieved 2026-09-10) → no open advisory. `unsafe` posture: proptest is a test-only crate with no `#![forbid(unsafe_code)]` claim that I verified; it ships an optional `hardware-rng` feature gated to `x86` for `no_std` targets, which is the one place hardware intrinsics enter, and it is **off by default**. I did not audit the source for `unsafe` blocks and do not claim a count. Because it is a dev-dependency, no proptest code is linked into any shipped artifact. **Pass, with the `unsafe`-audit gap stated.**
4. **OS matrix** — **this is the one soft spot, and it does not fail the gate.** proptest's own CI (`.github/workflows/rust.yml`, proptest-rs/proptest, retrieved 2026-09-10) runs `os: ubuntu-24.04` for all four legs (`pinned` 1.86.0, `stable`, `beta`, `nightly`) — **no macOS and no Windows job**. The crate publishes no platform-support statement I could find. The macOS evidence is therefore indirect but strong: `rust-lang/cargo` depends on proptest and its CI matrix includes `macos-15` and `windows-latest` alongside `ubuntu-latest` and `ubuntu-24.04-arm` (`.github/workflows/main.yml`, commit `e7506208ff1b`, retrieved 2026-09-10), so proptest is exercised on macOS continuously by a first-party-org consumer. Structurally, the only platform-sensitive part is the default `fork`/`timeout` feature pair, which pulls `rusty-fork` + `tempfile` to run each case in a subprocess; that is a POSIX/Windows-portable mechanism, not a Linux one. **Pass on consumer-CI evidence; the absence of a first-party macOS job is recorded as a residual risk and a re-verify trigger.** Windows: not required by the template; covered by cargo's matrix.
5. **Default features / async coupling** — `default = ["std", "fork", "timeout", "bit-set"]` (`proptest/Cargo.toml`, proptest-rs/proptest, retrieved 2026-09-10). `fork = ["std", "rusty-fork", "tempfile"]`, `timeout = ["fork", "rusty-fork/timeout"]`. **No async runtime coupling at all** — proptest is synchronous and depends on no executor, so it is neutral to whatever R05 decides about the sync/async execution model. An `async` property would need the test body to block on a runtime the template already has, which is a template-side concern, not a proptest dependency.
6. **Binary size / compile time** — **binary size: zero.** As a `[dev-dependencies]` entry, proptest is compiled only for test targets and appears in neither the released binary nor the published library's dependency closure for downstream consumers. Compile-time cost, qualitatively: moderate — six required crates (`bitflags`, `num-traits`, `rand`, `rand_chacha`, `rand_xorshift`, `unarray`) plus four pulled by default features (`bit-set`, `bit-vec`, `regex-syntax`, `rusty-fork`, `tempfile`), of which `regex-syntax` is the largest single compilation unit. Turning off `fork`/`timeout` would trim `rusty-fork` and `tempfile` but also removes per-case isolation; I do **not** recommend that for a template. This is a qualitative statement — I did not measure a build.

##### Up-and-comers

**`bolero` 0.13.4** — crates.io `GET /api/v1/crates/bolero`, retrieved 2026-09-10: `recent_downloads` 1,419,933; `downloads` 5,470,669; `max_stable_version` 0.13.4. `GET https://api.github.com/repos/camshaft/bolero`, retrieved 2026-09-10: `stargazers_count` 256; `archived` false; `pushed_at` 2026-08-11T00:22:27Z; repo license MIT. Genuinely interesting: one test body drives property testing *and* libFuzzer/AFL/honggfuzz/Kani, so a template could grow into fuzzing without rewriting tests. Not recommended now for three reasons: it is pre-1.0 (0.13.x) so its API can break in a patch-shaped bump; its added value (fuzzing engines) requires nightly and a separate job, which this template's stable-only constraint excludes; and at 1.4M 90-day downloads it is 33× smaller than proptest, so the template would be teaching its users a minority tool. Worth re-checking if it reaches 1.0.

**`arbitrary` 1.4.2** — `recent_downloads` 39,901,832; `downloads` 156,961,548 (crates.io, retrieved 2026-09-10); `rust-fuzz/arbitrary` 877 stars, `pushed_at` 2026-06-22T23:06:16Z (GitHub, retrieved 2026-09-10). Listed to prevent a misreading: its download figure rivals proptest's but it is a *different category* — a decoder from unstructured fuzzer bytes to typed values, with no runner, no assertion form and no shrinker of its own. It is not a candidate. (`proptest-arbitrary-interop`, which reth uses at `Cargo.toml:594`, bridges the two — evidence that the ecosystem treats them as complements, not substitutes.)

##### Fit for this template

Excellent. The template's property targets are the two seams py names: the domain model's JSON wire form and the config file's write→read cycle. Both are pure, synchronous, fast functions — proptest's default 256 cases per property costs milliseconds at this shape. It is a dev-dependency, so it touches neither the CLI binary, the library's public API (R04), nor the web service. It is synchronous, so it is neutral to R05. It expands to `#[test]` functions, so it is neutral to R32's runner choice. The one template-visible artifact is the committed `proptest-regressions/` directory, which is a *benefit* under Principle A criterion 3 and a one-line note in `CONTRIBUTING`.

##### Recommendation

`proptest = "1.11"` in `[dev-dependencies]`, default features, no `proptest-derive`. Properties written with the `proptest!` macro and inline strategies, mirroring py's two named seams. `proptest-regressions/` committed. Case count left at the default 256 locally; CI may raise it via `PROPTEST_CASES` if a nightly/scheduled lane wants deeper search (R34's call, not this item's).

##### Ranked runner-up

1. **`quickcheck` 1.1.0** — the substitute if proptest's ubuntu-only CI ever becomes a real macOS problem, or if generation cost ever matters. Full figures above. Cost of switching: strategies become `Arbitrary` impls plus newtypes; failure replay changes from a committed regressions file to a printed seed, which weakens acceptance criterion 3.
2. **`proptest-derive` 0.8.0** — *not a substitute; a possible addition, deliberately deferred.* crates.io, retrieved 2026-09-10: `recent_downloads` 4,873,242; `downloads` 24,852,085; newest non-yanked 0.8.0, `created_at` 2026-02-05, `license` "MIT OR Apache-2.0", `rust_version` 1.84; it lives in the proptest-rs/proptest repository, so its GitHub figures are proptest's. `rustsec.org/packages/proptest-derive.html` → HTTP 404 (no advisory), retrieved 2026-09-10. Deferred because (a) it is 0.x, so it pins the template to a pre-1.0 API surface in a file every consumer inherits, and (b) the template's domain model is small enough that hand-written strategies read better *and* match py's explicit-strategy style more closely. `paradigmxyz/reth` uses it (`Cargo.toml:626`) because its type surface is enormous; a template's is not.

##### Tradeoffs

- **Cost paid:** ~10 extra crates compiled for the test profile; a committed `proptest-regressions/` directory that contributors must not delete; a macro-based test body that is less obvious to a Rust newcomer than a plain `#[test]`; up to an order-of-magnitude slower generation than quickcheck for complex values (maintainers' own figure, cited above) — immaterial at this suite's shape.
- **Cost avoided:** silent serialization regressions at exactly the two seams py identified as costly; hand-rolled generator/shrinker code inherited by every template consumer.
- **Residual risk:** proptest's first-party CI does not cover macOS, so a macOS-only regression would be caught by consumers (cargo) rather than by proptest's own gate. Mitigated by the template's own `macos-latest` leg running the property tests.
- **Reversibility:** high. Removing the capability is deleting one dev-dependency, one test file and one directory.

##### Parameters

Owns nothing (`owns:` is empty in `## Couplings`). Consumed parameters, all satisfied at their fixed values: `license` = `MIT OR Apache-2.0` (proptest is exactly this); `msrv-policy` floor 1.96 vs. proptest's 1.85 published / 1.86 at HEAD; `rust-edition` = 2024 — proptest 1.11.0 is itself edition 2021, which is fine because editions are per-crate and a 2024 crate may depend on a 2021 crate; `target-os-matrix` = `ubuntu-latest, macos-latest` — satisfied with the CI caveat in gate 4. No `CONFLICT:` lines.

##### Validation strategy

Proposed, not executed:
- `cargo test -p <lib> --test properties` — expect both properties to pass at 256 cases each.
- Mutate the serializer to drop `workspace`, rerun — expect a failure whose reported counterexample is minimal (e.g. `workspace = Some("")` rather than a 60-character random string), and expect a new entry in `crates/<lib>/proptest-regressions/properties.txt`.
- Rerun without reverting — expect the same counterexample first, proving replay (criterion 3).
- `PROPTEST_CASES=2048 cargo test -p <lib> --test properties` — expect a pass and a visibly longer run, proving the env override is wired.

##### Confidence & re-verify trigger

**High** on the capability and on proptest as the crate: first-party-org adoption, 4.4× download lead, 6.8× reverse-dependency lead, all gates passed, direct principle mapping to py's suite. **Medium** on the "no `proptest-derive`" call — it is a judgment about the template's domain-model size that P03 could reasonably reverse.

Re-verify if: proptest raises its published `rust-version` above the template's floor (currently 1.96; HEAD already reads 1.86); a RustSec advisory appears at `https://rustsec.org/packages/proptest.html`; proptest's CI still has no macOS leg *and* a macOS-specific failure is observed; `bolero` reaches 1.0 with a stable-only property mode; or `proptest-derive` reaches 1.0.

##### Sources

- `GET https://crates.io/api/v1/crates/proptest` — `recent_downloads` 46,574,976, `downloads` 184,292,444, `max_stable_version` 1.11.0, `repository` https://github.com/proptest-rs/proptest (2026-09-10)
- `GET https://crates.io/api/v1/crates/proptest/versions` — 1.11.0, 2026-03-24, `MIT OR Apache-2.0`, `rust_version` 1.85, edition 2021 (2026-09-10)
- `GET https://crates.io/api/v1/crates/proptest/reverse_dependencies?per_page=1` — `meta.total` 10,387 (2026-09-10)
- `GET https://api.github.com/repos/proptest-rs/proptest` — stars 2,231, `archived` false, `pushed_at` 2026-08-21T20:59:56Z (2026-09-10)
- `GET https://api.github.com/search/issues?q=repo:proptest-rs/proptest+is:issue+is:open` — `total_count` 124 (2026-09-10)
- `GET https://api.github.com/repos/proptest-rs/proptest/issues?state=all&sort=created&direction=desc` — responsiveness sample, 2026-09-10 (see `Confidence`/`Method notes`)
- `https://rustsec.org/packages/proptest.html` — HTTP 404, no advisory page (2026-09-10)
- `https://github.com/proptest-rs/proptest` `proptest/Cargo.toml` and `.github/workflows/rust.yml`, default branch (2026-09-10)
- https://proptest-rs.github.io/proptest/proptest/vs-quickcheck.html (2026-09-10)
- https://docs.rs/proptest/latest/proptest/test_runner/struct.Config.html (2026-09-10)
- https://github.com/rust-lang/cargo `Cargo.toml:87`, `crates/resolver-tests/tests/proptests.rs`, `.github/workflows/main.yml` @ `e7506208ff1b` (2026-09-10)
- https://github.com/paradigmxyz/reth `Cargo.toml:625-626,594` @ `040bef7b319c` (2026-09-10)
- quickcheck: `GET https://crates.io/api/v1/crates/quickcheck` and `/versions`; `GET https://api.github.com/repos/BurntSushi/quickcheck` and `/commits`; `GET https://api.github.com/search/issues?q=repo:BurntSushi/quickcheck+is:issue+is:open`; `https://rustsec.org/packages/quickcheck.html` (all 2026-09-10)
- bolero / arbitrary: `GET https://crates.io/api/v1/crates/{bolero,arbitrary}`; `GET https://api.github.com/repos/{camshaft/bolero,rust-fuzz/arbitrary}` (2026-09-10)
- py@b08bccfb `tests/core/test_properties.py`, `pyproject.toml:100,271-278` (read via `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`, 2026-09-10)

#### insta

##### Landscape

Category: golden-snapshot assertion library for `cargo test`, with committed reference files and a review workflow. Bin: **established industry standard** — the largest snapshot crate by every download and reverse-dependency measure, and the one the two most visible new Rust-implemented developer tools (`ruff`, `uv`) both use. Competitors from the same map: `snapbox` (assert-rs; the crate clap uses for its own `--help` tests), `expect-test` (rust-analyzer's minimal inline snapshotter), and from the up-and-comer bin `insta-cmd`, `trycmd` and `goldenfile`. The no-library alternative is a hand-rolled `include_str!` comparison — which is exactly what py itself does for its *OpenAPI* snapshot (py@b08bccfb `tests/web/test_openapi_snapshot.py`), so the ecosystem-neutral baseline is real and worth beating explicitly.

##### Principles and implementation

Realizes **Principle B**. `insta::assert_snapshot!(value)` writes the reference to `snapshots/<test-target>__<name>.snap` next to the test, i.e. a **committed file separate from the test source** — the structural analogue of py's `tests/cli/__snapshots__/test_help_snapshots.ambr`, and the property Principle B says must agree. On mismatch the test fails and the candidate is written beside the reference with a `.new` extension: "By default the new snapshots are stored next to the old ones with the extra `.new` extension" (https://insta.rs/docs/quickstart/, retrieved 2026-09-10).

**CI enforcement (acceptance criterion 6) is built in, and this is the strongest single reason to prefer insta here.** insta detects CI from the `CI` environment variable: "Insta behaves differently in CI environments. For instance it will not write new snapshot files," and "Please ensure that your CI system sets it" (https://insta.rs/docs/quickstart/, retrieved 2026-09-10). The `INSTA_UPDATE` variable's default mode `auto` is documented as "`no` for CI environments or `new` otherwise" (same page). Separately, `cargo insta test --unreferenced <mode>` takes `ignore | warn | reject | delete | auto`, where `auto` "behaves like `reject` in CI and like `delete` if not run from CI" (https://insta.rs/docs/cli/, retrieved 2026-09-10) — which catches the *other* drift direction: a snapshot file left behind after its test was deleted or renamed. py has no equivalent unreferenced-snapshot check; syrupy's `--snapshot-update` is the update path and unused-snapshot reporting is a separate concern. So insta *exceeds* the py baseline on enforcement rather than merely matching it.

**Dynamic content.** py pins terminal width with `monkeypatch.setenv("COLUMNS", "80")` and needs nothing else, because Click's help contains no timestamp or path. Rust `--help` output for this template will contain the crate version in the `-V, --version` line and possibly a path in an `[env: …]` or default-value annotation. insta's answer is `Settings::add_filter` (regex → replacement, gated behind the `filters` feature) and `redactions` for structured snapshots (https://docs.rs/insta/latest/insta/, retrieved 2026-09-10). `astral-sh/uv` enables exactly these: `insta = { version = "1.46.0", features = ["json", "filters", "redactions"] }` (`Cargo.toml:328`, commit `a22198b1b536`, retrieved 2026-09-10) — a maintained reference implementation of snapshotting a CLI whose output contains volatile paths and versions.

**Composition with clap (B2).** `Cli::command().term_width(80)` pins wrapping; `Command::render_long_help() -> StyledStr` renders help in-process; `StyledStr`'s `Display` is documented "Color-unaware printing. Never uses coloring." so the captured string carries no ANSI (https://docs.rs/clap/latest/clap/builder/struct.StyledStr.html, retrieved 2026-09-10); `Command::get_subcommands` walks the tree so a new subcommand is covered without editing a list (criterion 5). `insta::with_settings!({ snapshot_suffix => … })` gives each command path its own `.snap` file, the analogue of py's `pytest.mark.parametrize(… ids=lambda p: " ".join(("plbp", *p)))`.

##### Dominant choice

**Yes — `insta` is the dominant Rust snapshot crate**, and it is dominant by a wider margin in its bin than proptest is in its own.

| Figure | insta | snapbox | expect-test | Endpoint |
|---|---|---|---|---|
| 90-day downloads | **26,382,169** | 3,185,186 | 7,326,545 | `GET https://crates.io/api/v1/crates/<name>` |
| All-time downloads | **97,830,232** | 12,089,278 | 36,849,824 | same |
| Reverse dependencies | **4,383** | 156 | 313 | `.../reverse_dependencies?per_page=1` |
| Stars | **2,957** | 183 | 324 | `GET https://api.github.com/repos/<o>/<r>` |
| Last push | **2026-09-06** | 2026-09-01 | 2024-12-21 | same, `pushed_at` |
| Latest non-yanked release | 1.48.0, 2026-06-11 | 1.2.2, 2026-05-26 | 1.5.1, 2024-12-21 | `.../versions` |

All retrieved 2026-09-10. insta leads snapbox by 8.3× on 90-day downloads and 28× on reverse dependencies, and expect-test by 3.6× and 14×.

**On the specific `--help` question the prompt asks:** yes, insta supports it, but the capability is not insta-specific — it comes from the composition above (in-process render → plain `String` → `assert_snapshot!`), with stdout capture unnecessary because nothing is written to stdout, and redaction available via `filters`. If instead the template ever wants to snapshot a *spawned* binary's stdout/stderr/exit code, `insta-cmd` is the same author's adapter — see `Up-and-comers`.

##### Qualified shortlist

**`snapbox` 1.2.2** — the strongest rival, and the one with the most on-point practice evidence. Passes every gate, and beats insta on one of them.
- crates.io `GET /api/v1/crates/snapbox`, retrieved 2026-09-10: `recent_downloads` 3,185,186; `downloads` 12,089,278; `max_stable_version` 1.2.2; repository https://github.com/assert-rs/snapbox/.
- `GET /api/v1/crates/snapbox/versions`, retrieved 2026-09-10: newest non-yanked 1.2.2, `created_at` 2026-05-26, `license` **`MIT OR Apache-2.0`**, `rust_version` 1.85, edition 2024.
- `GET https://api.github.com/repos/assert-rs/snapbox`, retrieved 2026-09-10: `stargazers_count` 183; `archived` false; `pushed_at` 2026-09-01T12:11:04Z.
- `GET https://api.github.com/search/issues?q=repo:assert-rs/snapbox+is:issue+is:open`, retrieved 2026-09-10: `total_count` **44**.
- Issue responsiveness (issues endpoint as above, retrieved 2026-09-10): the sample yielded **7** issues, not 10, because the repository's recent activity is overwhelmingly pull requests; **1 answered at 0.1 days**, **6 unanswered**, the most recent unanswered since 2026-04-22 (#440). Caveat: this repository's maintainer commonly resolves issues through commits rather than comments, so an author-association-based measure understates responsiveness here.
- Advisories: `https://rustsec.org/packages/snapbox.html` → HTTP 404 (no advisory), retrieved 2026-09-10.
- OS gate: **snapbox beats insta and proptest here** — `.github/workflows/ci.yml` runs `os: ["ubuntu-latest", "windows-latest", "macos-latest"]` on the test job, with a separate `Check MSRV` job (assert-rs/snapbox, retrieved 2026-09-10).
- Default features `diff`, `color`, `color-auto`; optional `dir`, `cmd`, `json`, `regex`, `term-svg`, `detect-encoding` (https://docs.rs/snapbox/latest/snapbox/, retrieved 2026-09-10). `SNAPSHOTS` is the update env var (same page).
- Maintenance state: **active** — releases 1.2.0 (2026-03-23), 1.2.1 (2026-04-02), 1.2.2 (2026-05-26), pushed 2026-09-01.
- **Practice evidence in its favor:** `clap-rs/clap` tests its own `--help` output with snapbox. `tests/builder/help.rs` opens `use snapbox::assert_data_eq; use snapbox::str;` and asserts help text against inline `str![[r#"…"#]]` blocks, pinning width with `.term_width(0)`; the shared helper `tests/builder/utils.rs::assert_output` captures help by calling `try_get_matches_from` and writing the resulting `Error`'s `Display` into a buffer, then `assert_data_eq!` (commit `48ed7869b91a`, retrieved 2026-09-10). This is the closest thing in the ecosystem to the exact test this item specifies.
- **Why it still loses.** Its help snapshots are *inline* (`str![[…]]`), which collapses the reference into the test source and forfeits the reviewable-separate-file property that Principle B fixes at the architectural level (alternative B3). snapbox does offer `file![]` for external references, so this is a default and idiom mismatch rather than a hard incapability — but choosing snapbox and then using `file![]` against the grain of every published example buys the wrong ergonomics. Add the 8.3×/28× adoption gap, the absence of an interactive review command comparable to `cargo insta review`, and a documented-but-blunter CI story (`SNAPSHOTS=overwrite` as an env var, with no built-in `reject`-in-CI unreferenced sweep), and insta wins on the criteria this item actually weighs. **snapbox is the correct fallback if the `MIT OR Apache-2.0` licensing point below is treated as disqualifying.**

**`expect-test` 1.5.1** — passes every gate; the minimalist option.
- crates.io, retrieved 2026-09-10: `recent_downloads` 7,326,545; `downloads` 36,849,824; newest non-yanked 1.5.1, `created_at` **2024-12-21**, `license` `MIT OR Apache-2.0`, `rust_version` 1.60.0.
- GitHub `rust-analyzer/expect-test`, retrieved 2026-09-10: 324 stars, `archived` **false**, `pushed_at` 2024-12-21T13:05:36Z; open issues `total_count` **15** (search endpoint).
- Responsiveness: not sampled — see `Method notes`.
- Advisories: `https://rustsec.org/packages/expect-test.html` → HTTP 404 (no advisory), retrieved 2026-09-10.
- Maintenance state: **stable-quiet.** No release and no push since 2024-12-21 — 20 months, which under the rubric is a trigger to investigate, not a verdict. Investigating: the crate is small and feature-complete by design ("Minimalistic snapshot testing for Rust", https://github.com/rust-analyzer/expect-test README, retrieved 2026-09-10), it is not archived, and `rust-lang/rust-analyzer` still depends on the current version `1.5.1` at HEAD (`Cargo.toml:113`, commit `a879a4cbadc3`, retrieved 2026-09-10) — a first-party-org consumer on the latest release is a strong signal that quiet means finished, not abandoned. No `at-risk` signal (no unpatched advisory, no maintainer notice, no broken build reported); it does not meet `dormant`'s bar either.
- Why it loses: inline-only by design (alternative B3), so it forfeits the same architectural property snapbox does, and it has no review workflow at all beyond "run with `UPDATE_EXPECT=1`".

##### Excluded by gate

**None excluded — but one gate finding must be recorded rather than waved through.**

Gate-by-gate for `insta` 1.48.0:

1. **License — `Apache-2.0` only, not the dual `MIT OR Apache-2.0`.** Verified twice: crates.io `/versions` reports `license` "Apache-2.0" for 1.48.0, and the repository's `LICENSE` file begins "Apache License / Version 2.0, January 2004" (mitsuhiko/insta, retrieved 2026-09-10); the crate's own `insta/Cargo.toml:4` reads `license = "Apache-2.0"`. **This is a `pass`, and here is the reasoning, stated rather than assumed.** The gate asks whether the candidate's license is *compatible* with the template's `MIT OR Apache-2.0`, not whether it is identical. Apache-2.0 is one of the two arms the template already offers, so no license text new to the repository is introduced. More decisively, insta is a **`[dev-dependencies]`** entry: it is not in the published crate's dependency closure for downstream consumers (Cargo does not propagate dev-dependencies to dependents) and it is linked into no released binary, so no distribution of insta's code occurs through this template at all. `astral-sh/uv` and `astral-sh/ruff`, both Apache-2.0/MIT-dual projects, take the same dependency. **Recorded consequence:** if the owner's intent behind the `license` parameter is the stricter "every dependency at any depth must itself be dual-licensed" — for example because a `cargo-deny` license allowlist under R13 will encode it — then insta fails that stricter reading and `snapbox` (`MIT OR Apache-2.0`, gate-clean, clap's own choice) is the drop-in answer. I flag this as an owner-visible fact, not a `CONFLICT:`: the parameter's value does not need to change, only its interpretation needs to be confirmed when R13 writes the allowlist.
2. **MSRV** — `rust_version` **1.66.0** for 1.48.0, confirmed in both crates.io `/versions` and `insta/Cargo.toml:8` (`rust-version = "1.66.0"`, mitsuhiko/insta, retrieved 2026-09-10). Against the template's 1.96 floor that is 30 minor versions of headroom — the most conservative floor of any candidate in this item. Dependency-tree floor at default features: `similar` 3.2.0 declares 1.85, `console` 0.16.6 declares 1.71, `once_cell` 1.21.4 declares 1.65, `tempfile` 3.27.0 declares 1.63 (`GET /api/v1/crates/<dep>/versions?per_page=1`, retrieved 2026-09-10) → **tree floor 1.85**, well inside 1.96. Same newest-version caveat as proptest's gate 2. **Pass.**
3. **Advisories / `unsafe`** — `https://rustsec.org/packages/insta.html` → **HTTP 404** (retrieved 2026-09-10) → no open advisory. Same for `cargo-insta`. `unsafe` posture: I did not audit the source and make no claim about `unsafe` block counts; as a dev-dependency none of its code reaches a shipped artifact. **Pass, with the audit gap stated.**
4. **OS matrix** — **cleanly passed, unlike proptest.** insta's `.github/workflows/tests.yml` runs its main test job over `os: [ubuntu-latest, macos-latest, windows-latest]`, with separate `build-on-msrv` and lint jobs and a `rust-toolchain.toml`-pinned default (mitsuhiko/insta, retrieved 2026-09-10). Both required template OSes are first-party-tested; Windows is covered though not required. **Pass.**
5. **Default features / async coupling** — `default = ["colors"]`, where `colors = ["console"]`; `json = ["serde"]`, `yaml = ["serde"]`, `redactions = ["pest", "pest_derive", "serde"]`, `filters = ["regex", "strip-ansi-escapes"]`, `glob = ["walkdir", "globset"]`, plus `csv`, `ron`, `toml` (`insta/Cargo.toml:20-41`, mitsuhiko/insta, retrieved 2026-09-10). **Correction worth recording:** the rendered docs.rs front page lists "Default features: `colors`, `json`, `yaml`", which reflects the docs.rs build configuration, not the crate manifest — the manifest is authoritative and says `colors` only. **No async runtime coupling**; insta is synchronous and neutral to R05. For this template I recommend `features = ["filters"]` so the version string in `--help` can be redacted; `json`/`yaml`/`redactions` are unnecessary for plain-text help and should be added only if R71 later routes the OpenAPI snapshot through insta.
6. **Binary size / compile time** — **binary size: zero** (dev-dependency; not in the shipped binary, not propagated to downstream consumers). Compile time, qualitatively: **light** — three required crates (`once_cell`, `similar`, `tempfile`) plus `console` from the default `colors` feature. Adding `filters` pulls `regex` and `strip-ansi-escapes`, which is the single largest increment and is still modest; `redactions` would pull `pest` + `pest_derive` (a proc-macro, the most expensive option here) and is not recommended. Qualitative statement only — no build was measured.

##### Up-and-comers

**`insta-cmd` 0.7.0** — crates.io, retrieved 2026-09-10: `recent_downloads` 1,218,815; `downloads` 4,028,291; newest non-yanked 0.7.0, `created_at` 2026-06-14, `license` `Apache-2.0`, `rust_version` 1.68.0. GitHub `mitsuhiko/insta-cmd`, retrieved 2026-09-10: 52 stars, `archived` false, `pushed_at` 2026-06-14T18:11:21Z, `open_issues_count` 6. `https://rustsec.org/packages/insta-cmd.html` → HTTP 404 (no advisory), retrieved 2026-09-10. Same author as insta, snapshots a spawned command's stdout, stderr and exit status. `astral-sh/ruff` uses it (`Cargo.toml:125`, commit `c3813a501faf`). **Not adopted now** because the recommended architecture is B2 (in-process render), which needs no subprocess, and because spawning the built binary belongs to R32's built-binary test tier — adopting it here would pre-empt an item this one does not own. Revisit if R32 establishes a built-binary tier that wants end-to-end CLI transcripts.

**`trycmd` 1.2.1** — crates.io, retrieved 2026-09-10: `recent_downloads` 1,691,592; `downloads` 6,353,704; newest 1.2.1, repository https://github.com/assert-rs/snapbox/ (it ships from the snapbox workspace). Runs `.trycmd`/Markdown transcript files as tests; `clap-rs/clap` uses it alongside snapbox (`Cargo.toml:195`, commit `48ed7869b91a`). Same "spawns the binary / R32 territory" objection as insta-cmd.

**`goldenfile` 1.11.0** — crates.io, retrieved 2026-09-10: `recent_downloads` 847,497; `downloads` 3,827,073. GitHub `calder/rust-goldenfile`, retrieved 2026-09-10: 45 stars, `archived` false, `pushed_at` 2026-02-25T14:27:13Z, `open_issues_count` 0, license MIT. The minimal external-file option: write to a `Goldenfile` handle, regenerate with an env var. Listed because it is the closest packaged form of the hand-rolled baseline. Not adopted: at 45 stars and 847K 90-day downloads it is 31× smaller than insta with no diffing UI and no CI-unreviewed enforcement.

##### Fit for this template

Excellent, and specifically better than the alternatives on the two things this template cares most about. (1) **Reviewable diffs**: `.snap` files land in `git diff` exactly as py's `.ambr` file does, so the F123 principle survives the port unchanged. (2) **CI enforcement without extra wiring**: GitHub Actions sets `CI=true` on every runner, so `INSTA_UPDATE`'s `auto` mode resolves to `no` and an unreviewed snapshot fails the build with no template-side configuration — the workflow author cannot forget it. (3) **Multi-surface reach**: the template is CLI + library + web service, and insta is the only shortlisted crate that is equally idiomatic for a library's `assert_debug_snapshot!` and (with `json`) a future OpenAPI or HTTP-envelope snapshot, without a second snapshot tool entering the workspace. (4) **Cross-OS**: first-party CI on `ubuntu-latest` and `macos-latest`, both of the template's required runners. The one genuine cost is that `cargo insta review` is a *separate binary* a contributor must install — addressed by the third member.

##### Recommendation

`insta = { version = "1.48", features = ["filters"] }` in `[dev-dependencies]`. Help snapshots rendered in-process from clap (`term_width(80)` + `render_long_help()`), one `.snap` file per command path via `with_settings!(snapshot_suffix)`, tree walked with `get_subcommands` so new subcommands are covered automatically. A filter that replaces the crate version with a stable sentinel keeps a release bump from touching every snapshot. Snapshot files committed under `crates/<cli>/tests/snapshots/`.

##### Ranked runner-up

1. **`snapbox` 1.2.2** — the substitute, and the *required* substitute if the `license` parameter is later read strictly (gate 1 above). Full figures in `Qualified shortlist`. It is also the choice a reviewer could reasonably prefer outright, on the strength of clap's own usage; the deciding argument against it is architectural (inline references, alternative B3) rather than one of quality.
2. **`expect-test` 1.5.1** — the minimalist substitute if the template ever decides inline references are acceptable and wants the smallest possible dependency. Figures in `Qualified shortlist`.
3. **Hand-rolled `include_str!` comparison** — the zero-dependency floor, and what py itself does for its OpenAPI snapshot. Ranked last because it fails acceptance criteria 6 and 7: there is no update command and no CI-unreviewed distinction, so drift is fixed by hand-editing the fixture, which is precisely the reviewability that Principle B exists to protect.

##### Tradeoffs

- **Cost paid:** four to six extra crates in the test profile; one committed snapshot file per command path, which grows with the CLI's surface; a second developer tool (`cargo-insta`) to provision; an `Apache-2.0`-only dev-dependency in a dual-licensed repository (analyzed at gate 1).
- **Cost avoided:** silent CLI UX regressions; hand-edited fixtures; a bespoke update script; and — through `--unreferenced` — orphaned snapshot files that outlive their tests, a failure mode py does not guard against.
- **Residual risk:** the snapshot suite is only as good as its determinism pins. If a future clap version changes help layout, *every* snapshot changes at once — a large but honest diff, and the same risk py carries.
- **Reversibility:** high. Removing the capability is one dev-dependency, one test file and one `snapshots/` directory.

##### Parameters

Owns nothing. Consumed: `license` = `MIT OR Apache-2.0` — satisfied under the dev-dependency reading, with the strict reading flagged at gate 1; `msrv-policy` floor 1.96 vs. insta's 1.66.0 (tree floor 1.85); `rust-edition` = 2024 — insta 1.48.0 is edition 2021, which is fine per-crate; `target-os-matrix` — insta's own CI covers both required runners plus Windows. No `CONFLICT:` lines.

##### Validation strategy

Proposed, not executed:
- `cargo test -p <cli> --test help_snapshots` on a clean tree — expect a pass and no `.snap.new` files.
- Rename a flag, rerun — expect a failure whose output is a textual diff, and a `.snap.new` file beside the reference.
- `CI=true cargo test -p <cli> --test help_snapshots` with the rename still in place — expect a failure and **no** file written into the workspace (`git status` clean apart from the source edit).
- Add a subcommand, rerun — expect a *new* snapshot to be reported as unseen rather than silently accepted, proving the tree walk covered it without a list edit.

##### Confidence & re-verify trigger

**High** on insta as the crate: 8.3×/28× lead over its nearest rival, first-party CI on both required OSes, built-in CI enforcement that no rival matches, and four independently well-regarded adopters. **Medium** on the "in-process render rather than spawn" architecture — it is the right default and matches py's `CliRunner`, but R32's built-binary tier could later argue for an end-to-end transcript test alongside it (not instead of it). **Medium-low** confidence that the license reading will not be revisited; that is an owner call, and I have stated the fallback.

Re-verify if: R13's `cargo-deny` license policy adopts a strict all-dependencies-dual rule (→ switch to snapbox); R60 selects a CLI framework without an in-process help renderer (→ the example changes, likely to a spawn-based approach); insta raises `rust-version` above 1.96 (currently 1.66.0, no risk); a RustSec advisory appears at `https://rustsec.org/packages/insta.html`; or `snapbox` publishes an interactive review command and closes the adoption gap.

##### Sources

- `GET https://crates.io/api/v1/crates/insta` — `recent_downloads` 26,382,169, `downloads` 97,830,232, `max_stable_version` 1.48.0 (2026-09-10)
- `GET https://crates.io/api/v1/crates/insta/versions` — 1.48.0, 2026-06-11, `Apache-2.0`, `rust_version` 1.66.0 (2026-09-10)
- `GET https://crates.io/api/v1/crates/insta/reverse_dependencies?per_page=1` — `meta.total` 4,383 (2026-09-10)
- `GET https://api.github.com/repos/mitsuhiko/insta` — stars 2,957, `archived` false, `pushed_at` 2026-09-06T23:26:22Z (2026-09-10)
- `GET https://api.github.com/search/issues?q=repo:mitsuhiko/insta+is:issue+is:open` — `total_count` 55 (2026-09-10)
- `GET https://api.github.com/repos/mitsuhiko/insta/issues?state=all&sort=created&direction=desc` — responsiveness sample (2026-09-10)
- `https://rustsec.org/packages/insta.html` — HTTP 404, no advisory page (2026-09-10)
- mitsuhiko/insta `insta/Cargo.toml`, `Cargo.toml`, `LICENSE`, `.github/workflows/tests.yml`, default branch (2026-09-10)
- https://insta.rs/docs/quickstart/ and https://insta.rs/docs/cli/ (2026-09-10)
- https://docs.rs/insta/latest/insta/ (2026-09-10)
- https://docs.rs/clap/latest/clap/struct.Command.html and https://docs.rs/clap/latest/clap/builder/struct.StyledStr.html (2026-09-10)
- https://github.com/clap-rs/clap `tests/builder/help.rs`, `tests/builder/utils.rs`, `Cargo.toml:195,197` @ `48ed7869b91a` (2026-09-10)
- https://github.com/astral-sh/uv `Cargo.toml:328` @ `a22198b1b536`; https://github.com/astral-sh/ruff `Cargo.toml:124,125,154,181` @ `c3813a501faf`; https://github.com/apache/arrow-rs `Cargo.toml:111` @ `f9e02ba76ad1`; https://github.com/rust-lang/rust-analyzer `Cargo.toml:113` @ `a879a4cbadc3` (all 2026-09-10)
- snapbox / expect-test / insta-cmd / trycmd / goldenfile: `GET https://crates.io/api/v1/crates/<name>` and `/versions`; `GET https://api.github.com/repos/<o>/<r>`; `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`; `https://rustsec.org/packages/<name>.html`; https://docs.rs/snapbox/latest/snapbox/; assert-rs/snapbox `.github/workflows/ci.yml`; rust-analyzer/expect-test `README.md` (all 2026-09-10)
- py@b08bccfb `tests/cli/test_help_snapshots.py`, `tests/cli/__snapshots__/test_help_snapshots.ambr`, `tests/web/test_openapi_snapshot.py`, `pyproject.toml:93` (2026-09-10)

#### cargo-insta

##### Landscape

Category: the snapshot **review tool** — the developer-workflow half of Principle B, distinct from the assertion library. Bin: **established industry standard within the insta ecosystem**; it has no independent competitor because each snapshot library ships (or omits) its own updater. The alternatives are not other crates but other *mechanisms*: an environment variable (`INSTA_UPDATE=always`, snapbox's `SNAPSHOTS=overwrite`, expect-test's `UPDATE_EXPECT=1`, goldenfile's `REGENERATE_GOLDENFILES`) or hand-editing the fixture. It is listed as a member rather than folded into insta because it is a separately versioned, separately published artifact with its own figures, it is *not* a `[dev-dependencies]` entry, and it is a provisioning obligation that R42's `package-manager-invocation` parameter governs.

##### Principles and implementation

Realizes the *"regeneration is one documented command"* half of Principle B and acceptance criterion 7, and — via `--unreferenced` — criterion 6's stricter form. py's equivalent is a pytest flag, documented in the test file's own docstring: "After an intentional change, regenerate with: `uv run pytest tests/cli/test_help_snapshots.py --snapshot-update`" (py@b08bccfb `tests/cli/test_help_snapshots.py`).

**Contributor ergonomics compared with syrupy (the MEDIUM question).** These are not the same shape of workflow, and insta's is strictly richer:

| Aspect | py / syrupy | Rust / cargo-insta |
|---|---|---|
| Update mechanism | `pytest --snapshot-update` — accepts **everything** in the selected scope, unconditionally | `cargo insta review` — "scans for all non ignored snapshots … and then walks you through all of them", accepting (`a`), rejecting (`r`) or skipping (`s`) **each one** |
| Bulk accept | the only mode | `cargo insta accept` — "all snapshot changes will be accepted"; `cargo insta reject` for the inverse; `--accept-unseen` accepts "only … new (previously unseen) snapshots" |
| Reviewing before accepting | read the `git diff` afterwards | the diff is shown per snapshot *before* the accept decision |
| CI enforcement of unreviewed changes | test simply fails (no snapshot-specific mode) | `CI` env var → `INSTA_UPDATE=no`, no files written; plus `--unreferenced` with `ignore\|warn\|reject\|delete\|auto`, where `auto` is "`reject` in CI and … `delete` if not run from CI" |
| Editor integration | none specific | `cargo insta pending-snapshots` "Returns a list requiring review; useful for editor integrations" |

(All cargo-insta quotations: https://insta.rs/docs/cli/, retrieved 2026-09-10; the `INSTA_UPDATE`/`CI` behavior: https://insta.rs/docs/quickstart/, retrieved 2026-09-10.) The practical difference for a template: syrupy's blanket `--snapshot-update` makes it easy to accept an unintended change along with an intended one, which is the exact failure Principle B exists to prevent; `cargo insta review`'s per-snapshot gate closes that hole. This is a place where the Rust port *improves* on the py baseline while preserving the principle, and the follow-on py/ts project could note it (syrupy has no per-snapshot review UI; the closest py-side mitigation is scoping `--snapshot-update` to one test file, which py's docstring already does).

**Note on `--check`:** the prompt's MEDIUM question and common usage both suggest a `cargo insta test --check` flag. The insta CLI documentation page I retrieved (https://insta.rs/docs/cli/, 2026-09-10) documents `review`, `test`, `accept`, `reject`, `pending-snapshots`, and the flags `--unreferenced`, `--accept`, `--accept-unseen`, `--review`, `--snapshot` — it does **not** mention `--check`, and it does not mention `INSTA_UPDATE` on that page (that variable is documented on the quickstart page). I therefore do **not** assert that `--check` exists. The CI enforcement I do assert rests on two documented mechanisms: the `CI` environment variable changing `INSTA_UPDATE`'s `auto` default to `no`, and `--unreferenced=auto` behaving as `reject` in CI.

##### Dominant choice

**Yes, by construction** — it is insta's own review tool, released in lockstep from the same workspace (`mitsuhiko/insta` `Cargo.toml` declares `members = ["cargo-insta"]`, retrieved 2026-09-10), and both are at 1.48.0 dated 2026-06-11. Choosing insta and *not* cargo-insta would mean regenerating snapshots through `INSTA_UPDATE=always cargo test`, which discards the per-snapshot review that is the main ergonomic argument for insta over snapbox.

##### Qualified shortlist

**`INSTA_UPDATE=always cargo test` (no extra tool).** Zero provisioning cost; contributors need nothing beyond `cargo`. Rejected as the default because it reproduces syrupy's blanket-accept weakness exactly, and because it leaves `--unreferenced` unavailable (that flag lives on `cargo insta test`, not on the library). Retained as the documented fallback for a contributor who cannot install the binary.

##### Excluded by gate

**None.** Gate-by-gate for `cargo-insta` 1.48.0 (crates.io `/versions`, retrieved 2026-09-10):

1. **License** — `Apache-2.0`. Same analysis as insta's gate 1, and *weaker* in consequence: cargo-insta is not a dependency of the template at all, only a developer tool invoked from a Justfile recipe or lefthook job. It appears in no `Cargo.toml` of the template. **Pass.**
2. **MSRV** — `rust_version` 1.66.0, identical to insta's. It is built as a standalone binary, so it is not part of the template's dependency tree and does not constrain the workspace's resolved MSRV at all. **Pass.**
3. **Advisories / `unsafe`** — `https://rustsec.org/packages/cargo-insta.html` → HTTP 404 (no advisory), retrieved 2026-09-10. `unsafe`: not audited; no claim made. It is a developer-machine and CI binary, in no shipped artifact. **Pass, audit gap stated.**
4. **OS matrix** — **explicitly satisfied with prebuilt binaries.** The insta workspace's `[workspace.metadata.dist]` block declares `targets = ["aarch64-apple-darwin", "x86_64-apple-darwin", "x86_64-unknown-linux-gnu", "x86_64-unknown-linux-musl", "x86_64-pc-windows-msvc"]` with shell and PowerShell installers (mitsuhiko/insta `Cargo.toml`, retrieved 2026-09-10). Both required runners are covered — including Apple Silicon, which matters because `macos-latest` is ARM — and so is Windows. Additionally the repository's own CI runs on `ubuntu-latest`, `macos-latest` and `windows-latest`. **Pass.**
5. **Default features / async coupling** — not applicable in the dependency sense: it is a binary, not a linked dependency, so it contributes no features to the template's build and has **no async-runtime coupling** with it. Its own build depends on `clap 4.1` with `derive` and `env` features (`mitsuhiko/insta` `[workspace.dependencies]`, retrieved 2026-09-10), which is invisible to the template.
6. **Binary size / compile time** — **zero impact on the template's binary and on `cargo build`/`cargo test` compile time**, because it is never compiled as part of the workspace. The cost it *does* impose is provisioning: either a `cargo install cargo-insta` compile (a few minutes on a cold machine) or a prebuilt-binary download via the shell/PowerShell installer. On CI this is a cache-and-restore concern that R10 (`dependency-cache-action`) and R42 (`dev-toolchain-provisioning`) own, not this item.

##### Up-and-comers

None. There is no emerging competitor to a library's own first-party review tool, and the adjacent mechanisms (`SNAPSHOTS`, `UPDATE_EXPECT`, `REGENERATE_GOLDENFILES`) are plain environment variables belonging to their own libraries rather than tools in their own right.

##### Fit for this template

Good, with one honest cost. The fit argument: it is the only mechanism in the shortlist that gives per-snapshot review, it ships prebuilt for both required runners including Apple Silicon, and its `--unreferenced=reject` closes a drift hole py has no guard for. The cost: it is a **second class of dependency** — a provisioned binary rather than a `Cargo.toml` line — so it must be declared wherever R42 declares dev tools, presence-tested with `command -v cargo-insta` (R42's rule for a crates.io-installed executable, as opposed to `rustup component list --installed` for a rustup component), and invoked as `cargo insta …` because its executable is named `cargo-insta` (R42's `package-manager-invocation`). A contributor who skips installing it can still run the tests; only the review workflow is unavailable, which is a graceful degradation.

##### Recommendation

Provision `cargo-insta` 1.48 as a developer tool, invoked as `cargo insta`. Two documented entry points: `cargo insta review` for local acceptance after an intentional change, and `cargo insta test --unreferenced=reject` in the CI test job so both unreviewed changes *and* orphaned snapshot files fail the build. Document the regeneration command in the snapshot test file's own doc comment, mirroring py's docstring, so the instruction sits where a contributor hits the failure.

##### Ranked runner-up

1. **`INSTA_UPDATE=always cargo test`** — the no-install fallback; documented as such rather than as the primary path.
2. **`cargo insta accept`** — not a runner-up to the tool but to the *interactive* workflow: appropriate in a scripted bulk update (for example after a deliberate clap upgrade rewrites every help snapshot), where reviewing 30 mechanically identical diffs by hand adds nothing.

##### Tradeoffs

- **Cost paid:** one more provisioned binary in the contributor setup and in CI; a cache entry; a version to keep in step with the `insta` dev-dependency.
- **Cost avoided:** blanket snapshot acceptance (syrupy's failure mode); orphaned `.snap` files accumulating silently.
- **Residual risk:** version skew between the `insta` library and the `cargo-insta` binary. Low in practice — they are released together from one workspace — but the template should pin both to the same minor line and say so.
- **Reversibility:** total. Dropping it costs only the review UI; the library keeps working.

##### Parameters

Owns nothing. Consumed: `package-manager-invocation` (R42, resolved) — `cargo-insta`'s executable is named `cargo-<sub>`, so it is invoked as **`cargo insta`** in every Justfile recipe and lefthook job, and presence is tested with `command -v cargo-insta` because it is installed from crates.io rather than by rustup. `target-os-matrix` — prebuilt binaries cover `aarch64-apple-darwin` and `x86_64-unknown-linux-gnu`, matching both runners. `license`, `msrv-policy` — see gates 1 and 2. No `CONFLICT:` lines.

##### Validation strategy

Proposed, not executed:
- `command -v cargo-insta` — expect a path, proving R42-style presence testing works for this tool.
- `cargo insta --version` — expect `1.48.x`, matching the `insta` dev-dependency's minor line.
- Change a help string, then `cargo insta review` — expect an interactive per-snapshot diff, and after accepting, a modified `.snap` file in `git status`.
- Delete a snapshot's test but leave the `.snap` file, then `cargo insta test --unreferenced=reject` — expect a non-zero exit naming the orphaned file.

##### Confidence & re-verify trigger

**High** that the tool is the right companion to insta and that it runs on both required OSes (prebuilt targets are declared in the manifest). **Medium** on the exact CI invocation: I verified `--unreferenced` and its `auto`/`reject` semantics from the maintainer's documentation, but I did **not** verify `cargo insta test --check`, so P03 should confirm the precise flag string against `cargo insta test --help` before writing the workflow step.

Re-verify if: insta and cargo-insta stop releasing in lockstep; the `--unreferenced` flag or its mode names change; R42's provisioning decision changes how crates.io binaries are installed; or a RustSec advisory appears at `https://rustsec.org/packages/cargo-insta.html`.

##### Sources

- `GET https://crates.io/api/v1/crates/cargo-insta` — `recent_downloads` 204,308, `downloads` 1,555,508, `max_stable_version` 1.48.0 (2026-09-10)
- `GET https://crates.io/api/v1/crates/cargo-insta/versions` — 1.48.0, 2026-06-11, `Apache-2.0`, `rust_version` 1.66.0 (2026-09-10)
- `https://rustsec.org/packages/cargo-insta.html` — HTTP 404, no advisory page (2026-09-10)
- mitsuhiko/insta `Cargo.toml` (`members = ["cargo-insta"]`, `[workspace.metadata.dist] targets`, `[workspace.dependencies] clap`), `.github/workflows/tests.yml`, default branch (2026-09-10)
- https://insta.rs/docs/cli/ — `review`/`test`/`accept`/`reject`/`pending-snapshots`, `--unreferenced`, `--accept`, `--accept-unseen`, `--review`, `--snapshot` (2026-09-10)
- https://insta.rs/docs/quickstart/ — `CI` env var, `INSTA_UPDATE` modes, `.new` files (2026-09-10)
- py@b08bccfb `tests/cli/test_help_snapshots.py` (the `--snapshot-update` instruction) (2026-09-10)
- `docs/port/PARAMETERS.md` — `package-manager-invocation` (R42), read from this repository's working tree (2026-09-10)
