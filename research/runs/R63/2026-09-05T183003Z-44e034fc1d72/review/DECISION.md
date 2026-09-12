# R63 — progress-spinner — decision (revision 2, 2026-09-12)

Item R63 (`progress-spinner`, kind `crate`, Focused tier, owns no parameter). Run
`research/runs/R63/2026-09-05T183003Z-44e034fc1d72`. Revision 2 rewrites revision 1
(sha256 `a56ff2ed50059c93b4874c77b236c2cb67130462bceb7ed7b0adcfc1bbfbb069`) in place. There
is no `## Supersedes` section because no revision of this decision has been published;
R63's index row is still `open`.

**Revision 2 answers the single finding of the empirical audit `review/audit-codex.r1.md`**
(actor `audit-codex-2026-09-05T183003Z-44e034fc1d72-r1`, model `gpt-5.6-terra`, family
openai, audit sha256 `1e4b6e32c6b4e52fd8817f5d8649316e4e9c11f23a1ed92e4b998bb877f99206`,
verdict reject). The finding was a reproducibility mismatch, not a wrong conclusion: the
saved script defined the checks the decision called sections 12-18 inside an uninvoked
`supplements()` function whose call site was commented out, so the auditor's rerun emitted
sections 0-11 and `DONE` only and could not reproduce seven sections the decision
attributed to it. **No design choice changes in revision 2.** The recommendation,
the rejected alternatives, the fitness-gate outcomes, the exclusions, the runner-up
condition and the acceptance criteria are revision 1's.

What revision 2 changed, and nothing else:

1. **The archived check is now one script that emits every section it is credited with.**
   Sections 12-18 are inline code in `review/evidence/r63-spinner-claims.sh`, in the same
   order and under the same titles the cited log carries. One run emits sections 0-18 and
   the `DONE` summary; `set -o pipefail` is on; every fetch writes a file before anything
   reads it; each claim is asserted on the content it expects; the run ends
   `checks: N pass / M fail` and exits non-zero on any failure. The log was regenerated
   from that script and the rerun was diffed against it before the sentences describing it
   were written. Revision 1's script and log are archived unmodified beside the new ones as
   `r63-spinner-claims.r1.sh` and `r63-spinner-claims.r1.log`.
2. **Two numbers that the regenerated log contradicts were corrected.** The count of
   environment variables `is_ci` 1.2.0 presence-checks besides `CI` is **35**, not the 33
   revision 1 stated in three places; the empirical check now enumerates all 35 names, and
   revision 1's own log already contained the full `src/lib.rs` that shows them. The
   auditor's own summary of this artifact said "then checks additional provider variables"
   without a count, so the corrected figure does not disturb anything the audit confirmed.
   The `indicatif` 0.18.6 default-feature list is asserted as a parsed **value**, because
   the published manifest writes the array across four lines and revision 1 quoted it in
   its inline form; the value is unchanged.
3. **Time-varying figures were re-quoted from the regenerated log at its own date,**
   2026-09-12, and the three-way drift between the Codex raw (2026-09-05), the Opus raw and
   revision 1 (2026-09-10) and this log (2026-09-12) is stated under `## Engines`. Every
   pinned-source citation was re-read on 2026-09-12 and is unchanged, so those citations
   keep their 2026-09-10 retrieval dates. Which dates sit where is **not** uniform across
   the document, and `## Engines` item 5 states it exactly, including the two 2026-09-10
   citations this check does not cover at all.

**What the audit confirmed is preserved verbatim, and revision 2 does not reopen it.** The
environment-gate adjudication — in which both raw reports proposed a wrong predicate in
opposite directions and this decision adopted a third form matching the inherited contract
— stands as written, as does the qualification that the zero-column claim is source read at
pinned versions rather than observed behaviour, as do the four fixed parameter lines. The
audit also recorded that it disagreed with the controller's provisional relaxed reading of
fitness gate 2 and that this decision's strict reading was correct. That provisional
controller reading was **withdrawn on 2026-09-11** after two auditors argued for the strict
reading, so this decision's gate-2 exclusions stand exactly as recorded and revision 2
changes none of them.

## Decision

**Recommendation: `indicatif = "0.18"` (Cargo requirement `0.18`, resolving today to
0.18.6), in the CLI crate only, with the render/suppress decision owned by the call site
and expressed as a `ProgressDrawTarget`.** The `CI` half of the gate is
`std::env::var_os("CI")` read directly from `std`, with no helper crate; the TTY half is
whatever check R65 lands for F290, called once. Add `indicatif` a second time under the
CLI crate's `[dev-dependencies]` with `features = ["in_memory"]` so the acceptance tests
can assert rendered output through `InMemoryTerm` without a pseudo-terminal.

This decision is a **proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what this research found and what it recommends; P03 builds the
template and its CI proves the recommendation. If implementation contradicts it, the
decision is revised against this recorded research rather than researched again from
scratch. The claims that are not yet proven, and what would prove them, are listed under
`## Engines`.

**Ledger rows settled.** `F283` — "Progress spinner during network fetch", area
`cli-framework-ux`, origin `ts-only`, verdict `DIVERGENT`, owner R63
(`docs/port/COMMONALITY.md:287`; `docs/port/areas/cli-framework-ux.md:27`, retrieved
2026-09-10). This decision names the Rust realization of that row. It does not change the
row's `DIVERGENT` verdict, which correctly records that py ships no progress indicator
today. No other ledger row is settled here.

**No `BASELINE-REVIEW:` line is emitted.** Neither raw report emitted one, and this
review found no reason to add one: F283's recorded requirement — a stderr spinner gated
on stderr TTY-ness and the absence of `CI` — survives scrutiny unchanged. The one element
of the shipped TypeScript implementation this decision deliberately does not port (the
D-033 zero-column guard) is an implementation workaround inside `yocto-spinner`, not part
of F283's recorded requirement; it is recorded as a deliberate non-port with its evidence
and its evidence's limits below, not as a challenge to the baseline.

### Principles and implementation

**The shared requirement.** A user-attended run of a command whose wall-clock time is
dominated by one network call must show that the program is alive; a run that is not user
attended must emit nothing extra, so that redirected or piped output is byte-identical to
what a machine consumer expects.

**Source and agreement level.** The requirement is recorded as ledger row `F283`
(`docs/port/COMMONALITY.md:287`, verdict `DIVERGENT`, origin ts-only) and in
`docs/port/areas/cli-framework-ux.md:27`. Its agreement level is **capability and
standard**, with two halves that must agree across py, ts and rs:

1. **Stream placement — must agree.** Progress is diagnostics, so it is written to stderr
   and never to stdout. The TypeScript decision record states the rule and the wart it
   repairs: "Stderr-by-default satisfies cli-standards R7.1 (progress=diagnostics) and
   fixes the source wart where progress text polluted stdout"
   (`git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:docs/port/TS_PORT_DECISIONS.md`,
   line 174, read at the pin, retrieved 2026-09-10).
2. **The suppression predicate — must agree.** Render only when stderr is a TTY **and**
   `CI` is absent or empty. Verbatim at the pin
   (`git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:src/commands/projects.ts`,
   lines 127-129, retrieved 2026-09-10):

       const ci = deps.env['CI'];
       const spinnerEnabled = deps.stderrIsTTY && (ci === undefined || ci === '');
       const spinner = spinnerEnabled ? deps.spinner('Fetching projects...') : undefined;

   The exact semantics are: **any non-empty `CI`, whatever its value, suppresses; an
   empty `CI` does not.**

**What may vary.** The rendering crate, the frame set, the tick interval, and the
mechanism by which "disabled" is expressed are ecosystem-local. Nothing in the principle
requires Rust to reproduce `yocto-spinner`'s API or frames.

**Essential behaviors.** One spinner, on stderr, started before the fetch and cleared on
both the success and the error path; no renderer constructed at all on any suppressed
path; stdout untouched by the spinner in every case.

**Observable acceptance criteria.** These are the criteria; the commands that would check
them are P03's, and none of them has been run (see `## Empirical check` for what *was*
run).

1. With stdout redirected and stderr attached to a terminal, stdout parses as JSON with
   no stripping.
2. With `CI` set to any non-empty value and stderr a TTY, stderr carries no spinner
   frames and no cursor-control sequences.
3. With stderr not a TTY, stderr carries no spinner frames.
4. With stderr a TTY and `CI` unset or empty, stderr carries spinner frames, and after the
   command exits no partial spinner line and no hidden cursor remain.
5. The predicate deciding 2-4 is a single function, and its TTY half is the one function
   R65 selects for F290 — a search of the workspace finds exactly one TTY test.

**Architecture alternatives compared, before any library was picked.**

| Alternative | Outcome |
|---|---|
| A — no indicator at all | Rejected: abandons the standard rather than realizing it, and reproduces py's gap in a third repository. |
| B — hand-rolled spinner (thread, frame array, `eprint!("\r…")`) | Rejected: the template would own cursor hide/show, panic- and signal-safe restore, and width awareness, to save one small dependency subtree. |
| C — spinner crate, gating owned by the call site | **Selected.** The crate renders; the application decides whether it renders at all and expresses "no" as a value the crate understands. |
| D — spinner crate, gating delegated to the crate's own TTY detection | Rejected; this is the load-bearing rejection. See below. |

**Why design D is rejected, and the residual asymmetry named rather than glossed.**
`indicatif` performs its own terminal test: `ProgressDrawTarget::term` begins
`if !term.is_term() || is_dumb() { return Self::hidden(); }` (published artifact
`indicatif-0.18.6/src/draw_target.rs:79-82`, verified in this review, retrieved
2026-09-10). Leaning on it would put a second TTY check beside whatever R65 lands for
F290 — which this item's `## Out of scope` forbids — and would still not cover `CI`:
`indicatif` 0.18.6 makes no environment access at all, verified by grep over every file
under `src/` in the published artifact for `std::env`, `env::var` and the literal `"CI"`
(all three greps exit 1). Under design C the call site's answer is converted into a
`ProgressDrawTarget`: `hidden()` when the gate is false, `stderr()` when it is true.
Reading the 0.18.6 control flow — not executing it — when the gate is false `term()` is
not reached, so on that path the two checks have no opportunity to disagree observably.
When the gate is true, `indicatif` may still additionally hide, because `is_dumb()`
(which lives in `console` 0.16.6, `src/term.rs:579-586`, and reads `TERM`) fires when
`TERM` is unset or `dumb`, a condition R65's TTY check does not evaluate. On the same
source reading, that residual asymmetry can only suppress output and cannot write to
stdout, because both branches of the gate yield a draw target that is either `hidden()`
or `stderr()`; it is benign, and it is why P03's rendering tests must pin `TERM` to a
non-`dumb` value, or they will pass without exercising the gate.

**Why the `CI` half uses `std` and not a helper crate — the named reason.** The two
candidate helper crates encode a *different predicate* from the one F283 inherits, so
substituting either would silently change the contract. Verified at a published version,
not from a branch: `is_ci` 1.2.0 (`static.crates.io/crates/is_ci/is_ci-1.2.0.crate`,
`src/lib.rs:25-70`, retrieved 2026-09-10) is

    let ci_var = std::env::var("CI");
    ci_var == Ok("true".into()) || ci_var == Ok("1".into()) || ci_var == Ok("woodpecker".into())
        || check("CI_NAME") || check("GITHUB_ACTION") || check("GITLAB_CI") || … (32 further, 35 in all)

with `fn check(name: &str) -> bool { std::env::var(name).is_ok() }`. Its predicate
requires `CI` to **equal** one of three literal values, where the inherited contract
suppresses on **any non-empty** value. The divergence runs in both directions: under
`CI=yes` the inherited contract suppresses and `is_ci` (absent any of its other 35
variables) does not; with `CI` unset but `GITHUB_ACTION` set, `is_ci` reports CI and the
inherited contract does not. `ci_info` 0.14.15 answers a different question again — which
provider is running. The Opus report's distinction therefore **holds**, and it is recorded
here as the reason: use `std::env::var_os("CI")` with the predicate
`is_none_or(|v| v.is_empty())`, which reproduces `ci === undefined || ci === ''` exactly
and adds no dependency. If the owner later wants provider sniffing, that is a new decision
on F283, not a silent substitution.

**The zero-column question — what the evidence is, and what it is not.** The shipped
TypeScript implementation adds a guard that treats a stderr width of zero as non-TTY and
skips the spinner (`git show cb1cbcb2…:src/lib/adapters.ts`, lines 55-64, retrieved
2026-09-10), and its own comment gives the cause: `yocto-spinner`'s line-clear loop
divides the rendered length by the stream width, so `Math.ceil(len/0) = Infinity` floods
stderr. That is a defect workaround in one JavaScript library, not a principle.

> **Zero-column evidence note (referenced from every later mention of this claim).**
> The Rust behaviour asserted below is established by **reading source at pinned
> versions, not by executing the crate against a zero-column terminal.** Reading source
> is evidence; it is not the same evidence as observing behaviour, and this decision has
> only the former. What would settle it: a `TermLike` fake reporting `width() == 0`
> driven through `ProgressDrawTarget::term_like`, and a pseudo-terminal reporting
> `ws_col == 0`. P03 must run both before the non-port is treated as proven.

Read at the pinned versions in this review (retrieved 2026-09-10):

- `console-0.16.6/src/unix_term.rs:53-71` — `terminal_size` returns `Some((rows, cols))`
  only `if winsize.ws_row > 0 && winsize.ws_col > 0`, else `None`.
- `console-0.16.6/src/term.rs:414-418` — `Term::size` is
  `self.size_checked().unwrap_or((24, DEFAULT_WIDTH))`, with
  `DEFAULT_WIDTH: u16 = 80` (`unix_term.rs:18`).
- `indicatif-0.18.6/src/term_like.rs:39-42` — `impl TermLike for Term { fn width(&self)
  -> u16 { self.size().1 } }`, which is the width the recommended `stderr()` draw target
  consumes.

So on the recommended path a zero-column TTY yields an 80-column assumption rather than a
division by zero, subject to the zero-column evidence note above. Two further precisions
this review adds, both from the published 0.18.6 artifact:

- The only division-by-width in `indicatif` 0.18.6 (`src/draw_target.rs:702`,
  `(unwrapped_width as f64 / width as f64).ceil()`) sits under
  `#[cfg(not(feature = "unicode-width"))]`. `unicode-width` is a **default** feature
  (`Cargo.toml`, `default = ["unicode-width", "wasmbind"]`), so with default features the
  compiled path is the per-character loop at `src/draw_target.rs:667-695`, which contains
  no division.
- A `TermLike` implementor that reports `width() == 0` — which `InMemoryTerm` can — is
  **not** guarded inside `indicatif` 0.18.6. Upstream added a `NarrowTerm` regression test
  for exactly that case *after* 0.18.6; it is present on `main` and absent from both the
  0.18.6 tag and the published 0.18.6 artifact (see `## Engines`). This does not affect
  the recommended production path, whose width comes from `console::Term`, but it does
  mean P03's zero-width test must be written as a deliberate check rather than assumed to
  be covered upstream.

**Decision: do not port the D-033 guard**, and record the non-port with its citation and
with the zero-column evidence note, so a future reader does not re-add it as parity.

**Why the selected design preserves each principle.** Stream placement is preserved
without configuration: `ProgressBar::new_spinner()` is
`Self::with_draw_target(None, ProgressDrawTarget::stderr())` and its doc comment reads
"This spinner by default draws directly to stderr" (published artifact
`indicatif-0.18.6/src/progress_bar.rs:147-154`, verified here, retrieved 2026-09-10);
`ProgressDrawTarget::stderr()`'s own doc adds "This is the default draw target for
progress bars" (`src/draw_target.rs:41-47`). The suppression predicate is *designed* to
be preserved exactly — it is written in `std` directly against the inherited semantics,
and the disabled path yields `ProgressDrawTarget::hidden()` (`src/draw_target.rs:123-130`),
a first-class "render nothing" value, so no second TTY check is consulted. That the
implementation actually preserves it is not established here; acceptance criteria 2-4,
including the `CI=""` case, are what would establish it, and they are P03's to run.

**Reference implementations.** `astral-sh/uv` implements design C directly:
`crates/uv/src/printer.rs` folds every suppression reason into one enum and maps it to
`ProgressDrawTarget::hidden()` or `::stderr()` in a single `target()` method (cited by the
Opus raw at `https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv/src/printer.rs`,
retrieved 2026-09-10 — a moving branch, so P03 should re-read it at a tag if it relies on
the exact shape). `rust-lang/rustup` declares `indicatif = "0.18"` (Opus raw, same
retrieval date), which is first-party Rust project practice. Further adopters named in the
Opus raw from `indicatif`'s reverse-dependency listing: `uutils/coreutils`,
`nextest-rs/nextest`, `cargo-generate`, `huggingface/tokenizers`, `rerun-io/rerun`,
`flamegraph-rs/flamegraph`.

**Fitness gates, `indicatif` 0.18.6, re-verified in this review (retrieved 2026-09-10).**

| Gate | Result |
|---|---|
| 1 · License | `MIT`; tree is `MIT` / `MIT OR Apache-2.0` / `Apache-2.0 OR MIT`. No copyleft. **Pass.** |
| 2 · MSRV | `rust-version = "1.85"`; tree maxima `console` 1.71, `unicode-width` 1.66, `portable-atomic` 1.34, `unit-prefix` 1.31.0. Stable is 1.98.1, so the policy floor is 1.96. **Pass.** |
| 3 · Advisories / unsafe | `rustsec.org/packages/indicatif.html` HTTP 404, as for `console`, `unicode-width`, `portable-atomic`, `unit-prefix`, `libc`; control crates `time`/`openssl`/`atty` return HTTP 200 with 4/20/4 `RUSTSEC-` mentions, so 404 reads as "no advisory page". No `unsafe` in `indicatif`'s own `src` (grep over the published artifact). **Pass.** |
| 4 · OS matrix | CI at tag 0.18.6 is `os: [ubuntu-latest, macos-latest, windows-latest]`, `rust: [stable]`, plus a `toolchain: "1.85"` MSRV job. **Pass.** |
| 5 · Default features / async | `default = ["unicode-width", "wasmbind"]`; `tokio`, `futures-core` and `rayon` are optional and off. **No async-runtime coupling**, which matters because R05 has not settled the execution model. **Pass.** |
| 6 · Binary size / compile time | Stated qualitatively: five crates, no proc-macro derive, no async runtime, no build script of consequence. No measured byte or second figure is quoted, because no crate exists in this repository to build. **Pass, qualitatively.** |

**Shortlist, exclusions and the finding they carry.** The candidate set gate-checked here
is the **union of both raws' landscapes**: `indicatif`, `spinners`, `spinoff`, `spinach`,
`cliclack`, `throbber-widgets-tui` (from the Opus raw) plus `prodash` and `spinner` (from
the Codex raw). **Of those eight, exactly one — `indicatif` — passed every gate**, which
the prompt correctly calls a finding. Every exclusion below was re-verified in this
review, not inherited.

| Excluded | Gate failed | Evidence (retrieved 2026-09-10) |
|---|---|---|
| `spinners` 4.2.0 | 2 | `rust_version: None` on 4.2.0, 4.1.1, 4.1.0 (crates.io versions endpoint) and no `rust-version` key in the published manifest |
| `spinoff` 0.8.0 | 2 | no `rust-version` key in the published manifest |
| `spinach` 3.2.0 | 2 | `rust_version: None` |
| `cliclack` 0.5.6 | 2 and 4 | `rust_version: None` on 0.5.6/0.5.5/0.5.4/0.5.3; repository contents are `.gitignore, Cargo.toml, LICENSE, README.md, examples, media, src` — no `.github`, and `contents/.github/workflows` returns HTTP 404, so no CI is evidenced |
| `prodash` 31.0.0 | 4 | its CI workflow runs on `ubuntu-latest` (three jobs) and `windows-latest` (one job); **no macOS job**, and the matrix requires `macos-latest`. Gates 1, 2, 3 pass: `license = "MIT"`, published `rust-version = "1.74"`, RustSec HTTP 404 |
| `spinner` 0.5.0 | 1, plus maintenance | `license: LGPL-3.0` (crates.io versions endpoint) — not compatible with `MIT OR Apache-2.0`; `TheNeikos/spinner` is `archived: true`, last pushed 2020-04-20 → **archived** by the maintenance rubric |
| `throbber-widgets-tui` 0.11.1 | category | a `ratatui` widget requiring a full-screen alternate-screen application; no gate outcome could make it fit a one-shot command |

Two exclusions carry a further finding worth recording because each would have decided the
candidate anyway. `spinoff` documents that its ordinary constructor "outputs to the
`stdout` stream" (published artifact `spinoff-0.8.0/src/lib.rs:137`) — the exact failure
mode the ts port was written to repair. `spinners` does write to stderr by default
(`Stream` derives `Default` with `#[default] Stderr`,
`spinners-4.2.0/src/utils/stream.rs:14-18`), but its render loop is
`stream.write(…).expect("IO Error")` (`spinners-4.2.0/src/lib.rs:119`), so an `EPIPE` on
stderr aborts the process. Under the looser reading in which an undeclared `rust-version`
is a finding rather than a gate failure, `spinners` would reach the shortlist and would
still lose on that panic path; the recommendation does not change, only the shortlist's
length.

**Fit for this template.** *CLI*: direct fit, and the whole decision lives here. One
detail P03 must get right — `enable_steady_tick(Duration::from_millis(100))` is required
around a blocking call. Its doc comment at 0.18.6 reads "Spawns a background thread to
tick the progress bar… This is useful to advance progress bars that are very slow by
themselves" (`indicatif-0.18.6/src/progress_bar.rs:174-181`, verified here). That a
spinner without it would render one frame and then sit still for the duration of the
fetch follows from that documented mechanism; it is an inference from the source, not an
observed run, and criterion 4 is what would confirm it. *Library*: `indicatif` must not appear in the
library crate's `[dependencies]`; if a caller ever needs progress, the R01 seam should
carry a caller-supplied `impl Fn(&str)` rather than an `indicatif` type, so the crate
never becomes a semver obligation of the library's public API. *Web service*:
`inapplicable` — an HTTP handler has no controlling terminal, and progress there belongs
to the response, to structured logs (R58) or to metrics (R79).

**Runner-up and its condition.** `cliclack` 0.5.6 wins **only if R61
(`interactive-prompts`) independently selects it** and thereby accepts its two gate
failures. In that world `cliclack` is already in the CLI dependency graph, its spinner is
`indicatif` underneath, and a separate direct `indicatif` dependency would mean two
renderers contending for the same stderr line. On R63's own gates it does not win, and
adopting it here would decide R61 by side effect.

**Python's position, supplied for the follow-on project.** At pin `b08bccfb`,
`git -C ~/c/py-launch-blueprint grep -il` for `spinner|tqdm|progressbar|rich.progress|Progress(`
over `*.py` and `*.toml` returns **no matches** (exit 1), while `pyproject.toml` lists
`rich>=13.0.0` for output rendering (verified in this review, retrieved 2026-09-10). py
therefore *has the capability available* and does not use it: a missing capability, not a
justified ecosystem difference. The rationale this decision supplies to the follow-on
project is that py should adopt `rich.Console(stderr=True).status()` under the same
two-clause gate. This decision changes nothing in py and does not challenge F283's
`DIVERGENT` verdict.

re-verify: 2027-03-10, or earlier on any of: R61 (`interactive-prompts`) resolving in favour of `cliclack` (then drop the direct `indicatif` dependency in favour of `cliclack`'s, so two renderers do not contend for the same stderr line); R65 (`color-enablement-chain`) resolving F290 (confirm the predicate consumes R65's check and that acceptance criterion 5 still finds exactly one TTY test); R05 selecting an async runtime (re-evaluate `indicatif`'s optional `tokio` feature, deliberately left off today); `indicatif` publishing 0.19 or raising `rust-version` above the then-current policy floor (it moved 1.71 → 1.85 between 0.18.4 and 0.18.5, so this is a live pattern); any RustSec advisory appearing for `indicatif`, `console` or `libc`; the `console-rs` maintainer concentration changing (all eight measured responses came from one `MEMBER`).

## Parameters

The prompt's `- owns:` line is empty; this item owns no parameter, so there are no `owns`
lines. Its `- consumes:` line is empty; no consumed parameter. No `CONFLICT:` line:
neither raw raised one, and the recommendation needs no registered value changed.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

How the four fixed parameters bear on the decision. The MSRV policy resolves to a 1.96
floor against the current stable 1.98.1, and the recommended dependency tree's maximum
declared `rust-version` is 1.85, so the pick costs the policy nothing; it is also the
single gate that excluded four of the eight candidates gate-checked. The Rust edition is
irrelevant to the dependency — editions are per-crate, and `indicatif` 0.18.6 is itself
`edition = "2021"` while linking into a 2024-edition consumer — except that 1.85 is the
edition-2024 floor the template already sits on. The license parameter is satisfied
because an MIT dependency imposes no obligation that a `MIT OR Apache-2.0` template does
not already accept, and no crate in the recommended tree is copyleft. The OS matrix is
satisfied by `indicatif`'s own CI, which tests both required runners at tag 0.18.6;
Windows is additionally covered though not required. There is one informal, non-registry
dependency: R65's F290 TTY-detection mechanism. This decision is written so that whatever
R65 selects is called once and converted into a `ProgressDrawTarget`; R63 introduces no
TTY check of its own.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4, arm64. Current stable
channel at check time: `1.98.1 (48a229cea 2026-09-01)`
(`https://static.rust-lang.org/dist/channel-rust-stable.toml`, retrieved 2026-09-10).

**What this check does and does not do.** It verifies the raw reports' claims by querying
the recorded endpoints, reading both pinned source repositories through their pins, and
reading the candidate crates' source from their **published crates.io artifacts** at
pinned versions. It implements nothing: no crate was scaffolded, no spinner was written,
no `cargo build`, `cargo test` or `cargo audit` was run, and no terminal was driven.

**Working directory.** `/private/tmp/claude-501/-Users-stevemorin-c-rs-launch-blueprint-p02-plan/b7c06b2f-d78d-4987-b237-63eeced4bd23/scratchpad/r63`
(downloaded `.crate` artifacts unpacked under `./src`). The two pinned repositories were
read in place with `git -C … show <pin>:<path>`; neither working tree was consulted, and
their default locations are `$HOME/c/ts-launch-blueprint` and
`$HOME/c/py-launch-blueprint`. **All three paths are overridable**, which matters because
the scratch path above is macOS-specific and a Linux rerun cannot create it: pass
`R63_WORK` for the scratch directory and `TS_REPO` / `PY_REPO` for the checkouts. Section 0
records the host, so a rerun on another machine declares which host it ran on rather than
appearing to reproduce this one; those lines carry the `HOST:` prefix.

**Command.** A single script, `review/evidence/r63-spinner-claims.sh`, run from the run
directory `research/runs/R63/2026-09-05T183003Z-44e034fc1d72` as

    bash review/evidence/r63-spinner-claims.sh \
      > review/evidence/r63-spinner-claims.log 2>&1

**Exit status 0**, ending `checks: 168 pass / 0 fail` and
`RESULT: PASS`. Its nineteen sections, every one of them emitted by that one run:

    0  toolchain, host, current stable channel version
    1  ts pin cb1cbcb2…: projects.ts:120-140, adapters.ts:25-72, package.json, TS_PORT_DECISIONS.md
    2  py pin b08bccfb…: git grep for any progress indicator; pyproject.toml
    3  is_ci: newest unyanked version from crates.io; full src/lib.rs of the published 1.2.0 artifact, and every variable it presence-checks
    4  indicatif 0.18.6 published artifact: Cargo.toml, new_spinner, stderr()/hidden()/term(), in_memory, unsafe
    5  console 0.16.6 published artifact: terminal_size, Term::size, DEFAULT_WIDTH
    6  indicatif CI matrix at git tag 0.18.6
    7  crates.io figures for 10 crates; newest unyanked version + rust_version for 6
    8  GitHub repo figures; open issues via the mandated search total_count
    9  RustSec pages for 11 crates plus the time/openssl/atty control
    10 excluded-candidate claims at published versions (spinoff, spinners, cliclack)
    11 MSRV arithmetic across the recommended tree, and the floor against the tree maximum
    12 spinoff's default stream, spinners' default Stream variant, and the zero-width regression test in the published artifact, at the git tag and on main
    13 the width path at 0.18.6: TermLike, its one division by a width value, prodash's published rust-version
    14 the divide-by-width site at 0.18.6 and the cfg attribute guarding it
    15 the default-feature width path at 0.18.6 and whether it divides at all
    16 whether indicatif 0.18.6 reads any environment variable, and where the TERM read lives
    17 enable_steady_tick, finish_and_clear and is_hidden at 0.18.6, with their doc comments
    18 the two candidates only the Codex raw surveyed: prodash's manifest, CI matrix, features and advisory page, and spinner's license and archived state
    DONE  the pass/fail summary and the process exit status

**How the script is built so that it can fail, which revision 1's could not.** Revision 1
ran sections 12-18 by hand and archived them inside an uninvoked `supplements()` function,
so a rerun emitted thirteen section headers where the decision cited twenty; the empirical
audit `review/audit-codex.r1.md` rejected the decision on exactly that. In revision 2 every
section is inline code in the one script. `set -o pipefail` is set, and every `curl`,
`git show` and `gh api` writes a file that a later command reads, so the pipeline failure
that produced this programme's original `git show <bad path> | head` defect — a failing
command masked by a succeeding one — cannot occur here: a failed fetch is reported as
`FAIL <label>: curl exit N` and the assertions that depend on it then fail too. **Every
claim is asserted on the content it expects**, not on an exit code: `chk` compares a value
to the value this decision records, `lit` requires a literal string in a named file, `nolit`
requires its absence, `cnt` asserts a match count so that an absence is asserted as "zero
matches" rather than as "grep exited 1", and `code` asserts an HTTP status. Where revision 1
read a grep's exit code, the script still prints that exit code as raw observation and adds
the content assertion beside it, so the sentences below that say "grep exit 1" remain
literally true of the log and are no longer the whole of the evidence for their claim. The
run ends with `checks: N pass / M fail` and exits 1 if any assertion failed.

**The check is falsifiable, and here is the run that proves it.** Two expectations in the
first draft of revision 2's script failed against the live artifacts and are what produced
the two corrections listed in the revision preamble. Beyond that, a recorded negative
control run with the ts checkout pointed at a path that does not exist is archived at
`review/evidence/r63-spinner-claims-negative-control.log`: it ends
`checks: 155 pass / 13 fail`, `RESULT: FAIL`, and exits 1, with the four `git show`
failures and the nine content assertions that depend on them each named. Reproduce it with

    R63_WORK=<a fresh scratch dir> TS_REPO=/nonexistent-repo \
      bash review/evidence/r63-spinner-claims.sh

**Reproducibility, stated after rerunning and diffing rather than before.** The cited log
was generated by the script above; the script was then run a second time and that rerun was
diffed against the cited log. The log is **not** byte-for-byte reproducible, and it cannot
be: it reads live registry, GitHub and documentation endpoints whose figures move. So every
time-varying line carries the literal prefix `VOLATILE: ` and every host-specific line the
prefix `HOST: `, and the comparison rule across them is mechanical:

    diff <(grep -vE '^(VOLATILE|HOST): ' a.log) \
         <(grep -vE '^(VOLATILE|HOST): ' b.log)

Under that rule both reruns were **identical to the cited log, with no differing line**. In
the raw undiffed comparison each rerun — one 31 seconds after the cited log, one 7 minutes
38 seconds after it — differed from it in exactly one line, the `VOLATILE: date:` stamp,
because no registry or GitHub figure happened to move inside either window. That is a
property of the window, not a guarantee: a rerun days later will differ in the `VOLATILE:`
download, star, `pushed_at` and open-issue lines, and under the rule above that is expected
rather than a mismatch. 101 of the log's 1045 lines carry one of the two prefixes. What is **not** volatile, and what a rerun must therefore
reproduce exactly, is every reading of a pinned crate artifact, a pinned git blob or a git
tag, and every one of the 168 PASS assertion lines; a moved figure that would change a gate
outcome is caught rather than tolerated, because the newest-unyanked version and declared
`rust-version` of each candidate are asserted against the values this decision records and
a mismatch fails the run with "registry moved — re-verify due".

Revision 1's script and log are archived unmodified as
`review/evidence/r63-spinner-claims.r1.sh` (sha256
`19b2d62a98a383c67a3b23ef6d299cc6730268e15bfc32fb35c653d21b040cf3`) and
`review/evidence/r63-spinner-claims.r1.log` (sha256
`1efbfb8a518bba0940058a1201507e8fbc6648af496366ced4637ab497df8329`), and the r1 auditor's
own rerun remains at `review/evidence/audit-r63-spinner-r1.log`.

**Pinned sources re-read on 2026-09-12 and unchanged.** Every citation in this decision to
a pinned crate artifact (`is_ci` 1.2.0, `indicatif` 0.18.6, `console` 0.16.6, `spinoff`
0.8.0, `spinners` 4.2.0, `prodash` 31.0.0), to the `indicatif` 0.18.6 git tag, or to a blob
at the ts pin `cb1cbcb2…` or the py pin `b08bccfb…` was re-read by the regenerated log on
2026-09-12 and asserted to carry the same text. Those citations therefore keep their
2026-09-10 retrieval dates, which is when the reading they support was first taken. The live
registry and GitHub figures are re-quoted at 2026-09-12 below; the live facts inside the
`## Decision` tables keep their 2026-09-10 dates and were re-asserted unchanged rather than
re-quoted. The two citations this check does not cover at all — the `astral-sh/uv`
`printer.rs` read on a moving branch and the two in-repository ledger reads — are named
under `## Engines`, item 5.

**Observed output — the findings that bear on the decision.**

- **The inherited contract is exactly as the Opus raw states.** `projects.ts:127-129` at
  the pin reads `const ci = deps.env['CI'];` /
  `const spinnerEnabled = deps.stderrIsTTY && (ci === undefined || ci === '');` /
  `const spinner = spinnerEnabled ? deps.spinner('Fetching projects...') : undefined;`.
  Any non-empty `CI` suppresses; an empty `CI` does not.
- **`is_ci`'s predicate is value-equality, at a pinned version.** `is_ci` 1.2.0 (newest
  unyanked, published 2024-02-04, license ISC, `rust_version: None`) requires
  `CI == "true" | "1" | "woodpecker"`, or any of 35 other named variables to be set. The
  distinction the Opus raw draws therefore **holds**; it is recorded as a named reason in
  `## Decision`.
- **`indicatif` 0.18.6, from the published artifact:** `license = "MIT"`,
  `rust-version = "1.85"`, `edition = "2021"`, `default = ["unicode-width", "wasmbind"]`,
  `tokio`/`futures-core`/`rayon` all optional; `new_spinner()` is
  `Self::with_draw_target(None, ProgressDrawTarget::stderr())` at `progress_bar.rs:150`;
  `ProgressDrawTarget::term` is `if !term.is_term() || is_dumb() { return Self::hidden(); }`
  at `draw_target.rs:79-82`; `hidden()` at `draw_target.rs:126`; `in_memory = ["vt100"]`
  with `InMemoryTerm::contents` and `impl TermLike for InMemoryTerm`; no file under `src/`
  contains the string `unsafe`.
- **`indicatif` 0.18.6 reads no environment variable.** Greps over every file under
  `src/` in the published artifact for `std::env`, `env::var` and the literal `"CI"` all
  exit 1. The `TERM` read behind `is_dumb()` lives in `console` 0.16.6
  (`src/term.rs:579-586`). This is what makes the `CI` half of the gate unavoidably the
  call site's job.
- **`console` 0.16.6, from the published artifact:** `terminal_size` returns `Some` only
  `if winsize.ws_row > 0 && winsize.ws_col > 0`; `Term::size` is
  `self.size_checked().unwrap_or((24, DEFAULT_WIDTH))` with `DEFAULT_WIDTH = 80`;
  `rust-version = "1.71"`, `license = "MIT"`. This is a **source read, not an executed
  zero-column test** — see the zero-column evidence note in `## Decision`.
- **The Codex raw's zero-width regression test is not in the recommended version.**
  `draw_to_term_narrower_than_its_content` is absent from the published 0.18.6 artifact
  (grep exit 1 over every shipped file) and absent from `src/draw_target.rs` at git tag
  0.18.6 (grep exit 1); each absence is additionally asserted as a zero match count. It
  is present on the moving `main` branch, at line 880 when that branch was read on
  2026-09-12, which is the URL the Codex raw cited. Recorded in `## Engines`.
- **The divide-by-width site is compiled out under default features.**
  `draw_target.rs:702` `(unwrapped_width as f64 / width as f64).ceil()` sits under
  `#[cfg(not(feature = "unicode-width"))]`; the default-feature path is the
  per-character loop at `draw_target.rs:667-695`, which has no division.
- **CI matrix at tag 0.18.6:** `os: [ubuntu-latest, macos-latest, windows-latest]`,
  `rust: [stable]`, plus a `toolchain: "1.85"` job.
- **Registry figures, retrieved 2026-09-12** and re-quoted from the regenerated log
  (`GET https://crates.io/api/v1/crates/<name>`, `crate.recent_downloads` /
  `crate.downloads`): `indicatif` 47,933,805 / 215,677,764; `console` 80,670,316 /
  345,406,499; `prodash` 12,886,331 / 53,745,381; `is_ci` 12,070,556 / 53,618,506;
  `cliclack` 1,050,733 / 3,370,549; `ci_info` 768,740 / 6,362,771; `spinners` 667,982 /
  7,142,166; `throbber-widgets-tui` 206,705 / 891,138; `spinoff` 102,741 / 740,480;
  `spinach` 1,533 / 46,033. These are the download counters that move between runs; they
  decide no gate, and they carry the `VOLATILE:` prefix in the log for exactly that
  reason. Newest unyanked versions and declared MSRVs — which **do** decide gate 2, are
  asserted rather than merely recorded, and are unchanged from revision 1: `indicatif`
  0.18.6, 2026-07-01, MIT, `1.85`; `prodash` 31.0.0, 2026-01-08, MIT, `1.74`; `spinners`
  4.2.0, `spinoff` 0.8.0, `cliclack` 0.5.6 and `spinach` 3.2.0 all `rust_version: None`.
- **GitHub, retrieved 2026-09-12:** `console-rs/indicatif` 5,211 stars, not archived,
  `pushed_at 2026-09-10T15:39:00Z`, **79** open issues by the mandated
  `search/issues` `total_count` (against 94 from `open_issues_count`, which counts pull
  requests). `fadeevab/cliclack` 367 stars; `FGRibreau/spinners` 602;
  `ad4mx/spinoff` 576, `pushed_at 2025-01-16`; `GitoxideLabs/prodash` 399; `zkat/is_ci` 15.
  Two days after revision 1 the star and issue counters moved by one to three — 5,212 to
  5,211, 80 open issues to 79, 366 to 367 — and `pushed_at` advanced; none of it changes a
  gate or the maintenance verdict, which rests on `archived: false` (asserted) and the
  release date. `fadeevab/cliclack`'s repository contents are `.gitignore, Cargo.toml,
  LICENSE, README.md, examples, media, src` — no `.github` (asserted absent), and
  `contents/.github/workflows` returns HTTP 404 (asserted).
- **RustSec, retrieved 2026-09-12:** HTTP 404 for `indicatif`, `console`, `unicode-width`,
  `portable-atomic`, `unit-prefix`, `libc`, `is_ci`, `ci_info`, `spinners`, `spinoff`,
  `cliclack`. Control: `time` 200 (4 `RUSTSEC-` mentions), `openssl` 200 (20), `atty` 200
  (4). Each status is asserted against its expected value, so a 200 where the decision
  expects 404 fails the run. The control establishes that 404 is "no advisory page", not an
  endpoint failure.
- **The two candidates only the Codex raw surveyed, verified independently.** `prodash`:
  published 31.0.0 declares `license = "MIT"` and `rust-version = "1.74"`, RustSec HTTP
  404, `default = ["progress-tree"]`; its CI workflow has three `ubuntu-latest` jobs and
  one `windows-latest` job and **no macOS job**, so gate 4 fails against the required
  matrix. Its `main` manifest declares `rust-version = "1.85"` where the published
  artifact declares `1.74` — the source of the Codex raw's figure. `spinner`: newest
  unyanked 0.5.0, published 2019-11-04, `license: LGPL-3.0`; `TheNeikos/spinner` is
  `archived: true`, 10 stars, last pushed 2020-04-20.
- **py pin `b08bccfb`:** the progress-indicator grep returns no matches (exit 1);
  `pyproject.toml` declares `rich>=13.0.0`.

**No error line remains in the log.** Revision 1's section 0 recorded
`curl: (56) Failure writing output to destination`, which was `curl` writing into a pipe
closed by `grep -m1`. Under `set -o pipefail` that would now fail the pipeline, so every
fetch writes a file before anything reads it and the message is gone: the regenerated log
contains no `curl:` error, no `FAIL` line and no non-zero command status other than the
grep exit codes that are printed deliberately as the raw form of an asserted absence.

**Full output:**
`research/runs/R63/2026-09-05T183003Z-44e034fc1d72/review/evidence/r63-spinner-claims.log`

## Engines

- `codex raw/codex-c403161bd4a74b45107f0a9680daf9a8f9d2d30023bd93afb9a69ca2d928898c.md`: Codex `gpt-5.6-terra` via `codex-cli-0.153.2` (`manifest.json`, `operations.codex.actual_model`); shape check passed; ran no checks of its own (its validation strategy is labeled planned). Figures retrieved 2026-09-05. Recommends `indicatif = "0.18"` pinned through `Cargo.lock` to 0.18.6; runner-up `prodash`.
- `opus raw/opus-9c0a786feae86166d2b76da49efa96e32bf0ecec3431b8c61be4c1bbecdcd751.md`: Claude `claude-opus-5` via `claude-agent-tool` (`operations.opus.actual_model`); shape check passed; ran read-only evidence collection of its own (`git show` at both pins, `curl`, `gh api`) and no build or test. Figures retrieved 2026-09-10. Recommends `indicatif = "0.18"` in the CLI crate only, design C, `std` for the `CI` gate; runner-up `cliclack`. No Doxa report is required for the Focused tier.

Both engines converged on `indicatif` at the `0.18` requirement, on stderr-by-default, on
call-site-owned gating, and on excluding `spinoff` (stdout default) and `spinners`
(undeclared MSRV). The disagreements and what settled each:

1. **The `CI` predicate — the one disagreement that would have changed shipped
   behaviour.** Codex recommends `std::env::var_os("CI").is_none()`, explicitly so that
   "an empty-but-present variable still counts as CI". Opus recommends
   `is_none_or(|v| v.is_empty())`. **Settled against Codex** by reading the ts pin:
   `ci === undefined || ci === ''` means an empty `CI` does **not** suppress, so Codex's
   form inverts the inherited contract for `CI=""`. Opus's form is adopted, and `CI=""`
   is added to the acceptance criteria as the case that pins the difference.
2. **Zero-column degradation.** Codex asserts `indicatif` "has a zero-width source
   regression test", citing `draw_target.rs` on the moving `main` branch. Opus asserts the
   safety comes from `console`'s positive-dimension check and 80-column fallback, read at
   tag 0.16.6, and says plainly that this is a source read rather than an executed test.
   **Settled in Opus's favour**: the test Codex names is absent from both the 0.18.6 tag
   and the published 0.18.6 artifact and exists only on `main`, so it is not evidence
   about the recommended version. Codex's claim is an instance of citing a moving branch
   for a pinned-version property. This review adds two precisions Opus did not have: the
   divide-by-width form in 0.18.6 is compiled out by the default `unicode-width` feature,
   and a `TermLike` implementor reporting width 0 is unguarded at 0.18.6.
3. **Landscape coverage.** Codex surveyed `prodash`, `spinoff`, `spinners`, `spinner`;
   Opus surveyed `cliclack`, `spinners`, `spinoff`, `spinach`, `throbber-widgets-tui`,
   `is_ci`, `ci_info`. Neither map is complete on its own, so the union of the two was
   gate-checked here and both of Codex's exclusive candidates were independently verified:
   `prodash` fails gate 4 (its CI workflow has ubuntu and windows jobs and **no macOS
   job**, confirming Codex's reading), and `spinner` 0.5.0 is `LGPL-3.0` with an archived
   repository, failing gate 1. **Codex's `prodash` figure `rust-version = "1.85"` is the
   same main-versus-pinned defect as item 2, not an invented number**: the moving `main`
   manifest does declare `1.85`, while the published 31.0.0 artifact declares `1.74` (both
   read 2026-09-10 and both re-read 2026-09-12, unchanged; both readings are asserted, so a
   change on either side fails the check). Neither value changes a gate outcome, since both sit below the 1.96
   floor — but the pattern is worth naming twice, because the two occurrences share one
   cause: citing a branch for a property of a released version.
4. **What HTTP 404 from RustSec means.** Codex recorded the 404s as evidence that
   advisory absence "was not verified"; Opus ran a control against crates known to have
   advisories. **Settled in Opus's favour** by re-running that control here: `time`,
   `openssl` and `atty` return HTTP 200 with advisory content, so 404 reads as "no
   advisory page". `cargo audit` in P03's CI remains worth having, but gate 3 is met.
5. **Figure drift, now three-way.** Three sets of download, star and open-issue figures
   exist for this item, and they differ only by when they were taken: the Codex raw's
   (2026-09-05), the Opus raw's and revision 1's (2026-09-10), and revision 2's
   regenerated log (2026-09-12). Revision 1's re-query on 2026-09-10 matched Opus's
   figures exactly. Revision 2's re-query on 2026-09-12 moved them again — `indicatif`
   47,129,967 to 47,933,805 recent downloads, 5,212 to 5,211 stars, 80 to 79 open issues,
   `cliclack` 366 to 367 stars — and **none of the movements changes a gate outcome, a
   candidate's rank or the recommendation**. No set is wrong; each is its own date. The
   rule for comparing across them, which is why the log prefixes these lines `VOLATILE:`:
   a counter that moves is not a mismatch, whereas a newest-unyanked version, a declared
   `rust-version`, an `archived` flag or an HTTP status that moves is, and each of those is
   asserted against the value this decision records. Where the dates sit is worth stating
   exactly, because the rule is not uniform across the document. The `## Empirical check`
   bullets re-quote every live registry and GitHub figure at **2026-09-12**. The
   `## Decision` fitness-gate and exclusions tables, and the `## Empirical check` toolchain
   paragraph, deliberately keep **2026-09-10**: they are preserved verbatim from revision 1,
   and every live fact in them — each RustSec HTTP status, each `archived` flag, the
   `contents/.github/workflows` 404, the CI-matrix shape at tag 0.18.6, `prodash`'s CI
   matrix on `main`, each newest-unyanked version and declared `rust-version`, and the
   current stable channel `1.98.1` — was re-asserted unchanged by the 2026-09-12 log rather
   than merely carried forward. Readings of pinned crate artifacts, pinned git blobs and the
   0.18.6 git tag likewise keep 2026-09-10, the date the reading they support was first
   taken, and were re-read unchanged on 2026-09-12. **Two 2026-09-10 citations are neither
   re-quoted nor re-asserted, and are named here rather than covered by the sentence
   above**: the `astral-sh/uv` `crates/uv/src/printer.rs` reference implementation, read on
   a moving branch, which this decision already tells P03 to re-read at a tag; and the
   in-repository ledger reads of `docs/port/COMMONALITY.md:287` and
   `docs/port/areas/cli-framework-ux.md:27`, which are files in this repository rather than
   external sources and which the empirical check does not query.
6. **Decision revision history.** **Revision 1** (sha256
   `a56ff2ed50059c93b4874c77b236c2cb67130462bceb7ed7b0adcfc1bbfbb069`, 2026-09-10,
   synthesizer `claude-opus-5`): rejected by the empirical audit `review/audit-codex.r1.md`
   (actor `audit-codex-2026-09-05T183003Z-44e034fc1d72-r1`, `gpt-5.6-terra`, family openai,
   audit sha256 `1e4b6e32c6b4e52fd8817f5d8649316e4e9c11f23a1ed92e4b998bb877f99206`) on one
   finding: the saved script held sections 12-18 in an uninvoked `supplements()` function,
   so the auditor's rerun (`review/evidence/audit-r63-spinner-r1.log`) emitted thirteen
   section headers where the decision cited twenty. The same audit verified the
   environment-gate adjudication, the strict gate-2 reading, the zero-column
   qualification, the four byte-exact `assumes` lines and six cited network endpoints.
   **Revision 2** (2026-09-12) integrates sections 12-18 into the script as code, adds
   `set -o pipefail`, replaces exit-code evidence with content assertions, regenerates the
   cited log, reruns and diffs it, records a negative control, corrects the `is_ci`
   variable count from 33 to 35 in the three places it appeared, asserts the
   default-feature list as a parsed value, and re-quotes the live figures at 2026-09-12.
   **No design choice, gate outcome, exclusion or acceptance criterion changed.**

**Uncertainty.** The evidence here is registry queries, GitHub API queries, and source
read from published crate artifacts and from two pinned git trees. **No Rust code was
compiled and no terminal was driven**, so every behavioral claim about the recommended
design is a reading of source rather than an observation of behaviour, and is qualified as
such wherever it appears. Revision 2 did not change this: the negative control and the
pass/fail summary are shell and `curl` output, not compiled Rust, and the auditor's own
`CI=""` Rust probe is deliberately **not** adopted into this check, because running it
would falsify the sentence above. Codex's figures were not re-queried at their own
retrieval date (2026-09-05); where the two raws differ numerically this decision quotes the
2026-09-12 values for live figures and the 2026-09-10 values for pinned-source readings,
both re-taken by revision 2's log. The Opus raw's issue responsiveness median is carried
forward unconfirmed (see below).

**Unproven claims, carried forward for P03 to prove in the real template.**

- **Zero-column behaviour.** Established by source reading at pinned versions only — see
  the zero-column evidence note in `## Decision`. *What would prove it*: a `TermLike` fake
  with `width() == 0` driven through `ProgressDrawTarget::term_like`, and a
  pseudo-terminal reporting `ws_col == 0`. Until then, the decision not to port the D-033
  guard rests on source reading, not on observed behaviour.
- **Every one of the five observable acceptance criteria.** No Rust crate exists in this
  repository, so none has been executed. *What would prove them*: the integration tests
  named in `## Decision`, with `TERM` pinned to a non-`dumb` value so `is_dumb()` cannot
  make a test pass for the wrong reason, and `cargo tree -p <library-crate> -i indicatif`
  to prove the library and web crates stay clean.
- **Dependency-tree resolution on the policy floor.** Both raws state, and this review
  confirms, that every declared `rust-version` in the recommended tree is at or below
  1.85. Neither a resolved `Cargo.lock` nor a `cargo +1.96 check` has been run, because
  there is no workspace to resolve. *What would prove it*: that MSRV job in P03's CI.
- **`indicatif` issue responsiveness.** Opus measured a median of 0.13 days to first
  maintainer response across 8 of the 10 most recently opened issues, with 2 closed
  unanswered and every response from the same `MEMBER`. This review re-verified the
  open-issue count (80 on 2026-09-10, 79 on 2026-09-12) but did not re-walk the per-issue
  comment endpoints, so the
  responsiveness median is carried from the Opus raw rather than independently confirmed.
  The maintenance verdict **active** rests on the release date, `pushed_at` and
  `archived: false`, all re-verified here.
- **Binary size and compile time.** Stated qualitatively by both raws and by this
  decision. No measured figure exists, and none can until P03 builds the template.
