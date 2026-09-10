# R65 — color-enablement-chain — DECISION

## Decision

This decision is a **proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. A decision that does not survive
implementation is revised against this recorded research, not researched again from
scratch. What P03 must validate is listed under `## Engines`.

**Recommended stack.** One stream-adapter stack plus one template-owned resolution
function:

| Role | Item | Version | How it enters the graph |
|---|---|---|---|
| Style vocabulary; the only colour type allowed in the library crate's public API | `anstyle` | 1.0.14 | direct dependency (also arrives via `clap`) |
| Per-stream adaptive writer; applies the decision at the stream boundary | `anstream` | 1.0.0, default features `auto` + `wincon`; `test` feature in `[dev-dependencies]` | direct dependency of the CLI crate (or behind the CLI feature) |
| Environment probes (`no_color`, `clicolor`, `clicolor_force`, `term_supports_color`, `is_ci`, `truecolor`, `term_supports_ansi_color`) | `anstyle-query` | 1.1.5 | transitive, via `anstream`'s default `auto` feature |
| Carrier for an explicit override | `colorchoice` | 1.0.5 | transitive, via `anstream`; **its process global is never written** |
| TTY primitive (F290) | `std::io::IsTerminal` | standard library (stable since Rust 1.70.0) | `std`; also reached inside `anstream` through `is_terminal_polyfill`, whose body delegates to the same `std` trait |
| Tiers the surveyed crates do not supply | a template-owned pure function, `resolve_color(flag, config, env) -> anstream::ColorChoice` | — | P03 writes it; this decision fixes only its inputs and its resolution order |

**Resolved precedence chain (F287), highest precedence first.** Tiers 1–4 are the
template's; tiers 5–7 are `anstream`'s and are reached by returning
`anstream::ColorChoice::Auto`:

| # | Input | Effect | Owned by |
|---|---|---|---|
| 1 | `--color <auto\|always\|never>` / `--no-color` (per-invocation flag) | explicit `always`/`never` decides; `auto` or absent falls through | template |
| 2 | config-file key `color = "auto" \| "always" \| "never"` | explicit `always`/`never` decides; `auto` or absent falls through | template |
| 3 | `NO_COLOR`, present and non-empty | never | template |
| 4 | `FORCE_COLOR`, present, non-empty and not `"0"` | always | template |
| 5 | `CLICOLOR_FORCE`, present and non-empty | always | `anstream` |
| 6 | `CLICOLOR=0` | never | `anstream` |
| 7 | *this stream's own* `is_terminal()` and (`TERM` supports colour, or `CLICOLOR` enabled, or `CI` set) | always, else never | `anstream` |

The resolver's inputs are exactly four: the parsed flag value, the config value, an
injected environment source, and — only for tiers 5–7, and only inside `AutoStream` —
each stream's own handle. **This decision describes the resolution order and its inputs;
it writes no code.** The function body, its types and its module placement are P03's.

**F288 — force-on.** Both `FORCE_COLOR` (tier 4, template-owned) and `CLICOLOR_FORCE`
(tier 5, free from `anstream`) force colour on, and `NO_COLOR` beats both.

**F289 — one gate or two.** Resolved **once per invocation, applied per stream**: the
single `ColorChoice` value is handed to `AutoStream::new(std::io::stdout(), choice)` and
`AutoStream::new(std::io::stderr(), choice)`, so when it is `Auto` each stream consults its
own `is_terminal()` independently. This is neither py's shape (one gate forces both streams)
nor ts's (stderr's TTY-ness decides for everything). It matters here because this template's
stdout carries a styled text-mode result table, so a piped table must not be coloured merely
because stderr happens to be a terminal.

**F290 — TTY mechanism.** `std::io::IsTerminal`. No `atty`, no `is-terminal` crate, no
`libc::isatty`. R63 (`progress-spinner`) and R64 (`pager-integration`) take the same
primitive. The pager check in particular must read the stream's own `is_terminal()` and not
the colour decision — `ColorChoice::Always` and `stdout().is_terminal()` stay two separate
values, which preserves for free the distinction py had to write out by hand.

**Config-schema scope (the prompt's LOW question).** This item **names** one config key,
`color`, a plain string enum with variants `auto | always | never` defaulting to `auto`, and
fixes its position in the chain (tier 2). Defining the field's type, validating it and
deciding how a bad value is reported belong to R53 (`config-schema-validation`) and R55
(`config-error-tolerance`).

**Ledger rows this settles:** F287 (precedence chain), F288 (`FORCE_COLOR` forces colour
on), F289 (gated once for both streams versus per-stream), F290 (TTY-detection mechanism).
F286 (that a `--no-color` flag exists) is inherited `COMMON → REUSE` and is **not** settled
here; it is carried forward with the `BASELINE-REVIEW:` line below.

### Principles and implementation

**Shared requirement, its source, and the level at which agreement is required.** The
principle both source repositories implement is: *the user, not the program, decides whether
ANSI colour appears, and the program resolves that decision once, from an ordered set of
increasingly specific inputs, before any styled byte is written.* Its sources are the two
informal web standards — `https://no-color.org/` and `https://force-color.org/`, both
retrieved 2026-09-10 — and the source repos' own recorded decisions: py's `R5.5`, in the
docstring at `src/py_launch_blueprint/cli/context.py:189` at pin `b08bccfb`, and ts's
`D-018(2)`/`D-038` in `docs/port/TS_PORT_DECISIONS.md`. **Agreement is required at the level
of capability and observable behaviour, not at the level of variable names or libraries.**

| Must agree across py, ts, rs | May justifiably vary by ecosystem |
|---|---|
| A per-invocation command-line flag is the most specific input and beats everything else | The flag's spelling and arity (boolean `--no-color` versus tri-state `--color <when>`) |
| `NO_COLOR`, present and non-empty, disables colour when no more specific input speaks | Whether an *additional* vendor variable (`CLICOLOR`, `CARGO_TERM_COLOR`) is also read |
| Some environment variable can force colour on for a non-TTY destination | Whether that variable is spelled `FORCE_COLOR`, `CLICOLOR_FORCE`, or both |
| An explicit force-on input never beats a more specific explicit disable | The exact tie-break between two force variables set at once |
| The decision resolves once, from injected inputs, and is deterministic under test | Whether the seam is a deps object (ts), a constructor argument (py), or a value passed to a stream adapter (rs) |
| Colour is decided per output stream, from that stream's own terminal-ness | Whether both streams are in fact styled |

**Observable acceptance criteria.** Given a program invocation:

1. `--no-color` (or `--color=never`) ⇒ no `ESC [` byte on either stream, whatever the environment says.
2. `--color=always` ⇒ SGR sequences on both streams even when both are pipes.
3. `NO_COLOR=1`, no flag, no config value ⇒ no SGR sequences.
4. `NO_COLOR=` (set, empty) ⇒ treated as unset.
5. `FORCE_COLOR=1` (or `CLICOLOR_FORCE=1`), nothing more specific set, both streams piped ⇒ SGR sequences on both.
6. `NO_COLOR=1` **and** `FORCE_COLOR=1` ⇒ no colour.
7. Both streams piped, nothing else set ⇒ no colour on either.
8. stdout piped, stderr a TTY, nothing else set ⇒ stderr coloured, **stdout not**.
9. `TERM=dumb` on a TTY ⇒ no colour.
10. The library crate exposes no function that reads the process environment or writes a process global; a caller can construct a fully-determined renderer.

Criterion 8 is the one that separates the three candidate architectures. Criterion 9 is the
one that separates the two candidate resolver shapes (see `## Engines`, Disagreement 2).

**Architectural alternatives, compared before any library was chosen.**

- **(A) A boolean gate plus conditional styling at each call site** — ts's shape
  (`colorEnabled(gate)` → `createColors(enabled)`), and in Rust `owo-colors`'
  `if_supports_color(Stream::Stdout, …)`. Every call site must remember to ask, and
  `owo-colors` keeps its override in a process global (`pub(crate) struct
  Override(AtomicU8);`, `src/overrides.rs:78` at tag `v4.4.0`, verified) scoped only by
  `with_override`. Cost: the gate becomes a cross-cutting concern smeared over every
  formatting site, and the global is hostile to `cargo test`'s in-process thread parallelism.
- **(B) Always emit ANSI into a stream adapter that strips when the destination cannot use
  it** — `anstream::AutoStream`. Writing code is colour-blind; one object per stream holds the
  decision. Cost: with colour off, `StripStream` runs a `utf8parse`-driven state machine over
  every written byte, so the *un-coloured* path pays.
- **(C) A console object that owns detection, styling, width and paging together** — py's
  shape (`rich.Console`), and in Rust the `console` crate. Cost: it couples this item's
  decision to R63's and R64's implementations, and `console` runs a second, differently
  ordered detection stack (verified below).

**(B) is recommended.** It is the only one of the three that satisfies criterion 8 without
threading a second boolean through every call site; it keeps the library crate's public API
free of a renderer type; and it is the pattern the Rust toolchain itself ships.

**Why the template owns tiers 1–4 rather than taking a dependency — the central finding, and
it was checked against the candidates' own source.** Seven candidate crates were read at
pinned tags (`anstyle-query` 1.1.5, `anstream` 1.0.0, `colorchoice` 1.0.5, `supports-color`
3.0.2, `termcolor` 1.4.1, `console` 0.16.6, `owo-colors` 4.4.0). **None of those seven
composes an application-supplied flag or config tier with a `FORCE_COLOR` tier ordered below
`NO_COLOR`**, and the flag and config tiers are application-owned by construction: no crate
parses this application's argv or config file, and `env::args` appears nowhere in the
candidates read (verified, `## Empirical check` §3). Concretely:

- `anstyle-query` 1.1.5 contains **zero** occurrences of `FORCE_COLOR` (`grep -c` = 0 over
  its whole `src/lib.rs` at tag `anstyle-query-v1.1.5`). It ships probes, not a policy.
- The omission is **deliberate, and its maintainer says so on the record.** `rust-cli/anstyle`
  issue #192, "Supporting FORCE_COLOR as an alias to CLICOLOR_FORCE", opened 2024-06-02 and
  still open: `epage` (`author_association: COLLABORATOR`, a `clap` and `cargo` maintainer)
  wrote on 2024-06-04T02:23:48Z — *"When I was weighing what to build-in, I was less
  interested in how wide spread something is about how consistently its expected to be
  implemented. People can always build their own thing on top but I didn't feel like
  arbitrating between parties arguing over 3 different implementations."* Title, opening date,
  author, association, comment timestamp and the quoted sentence were all verified against the
  GitHub API and snapshotted (`review/evidence/anstyle-issue-192*.json`).
- `supports-color` 3.0.2 is the **only** candidate that reads `FORCE_COLOR` natively, and it
  evaluates it **above** `NO_COLOR` (`let force_color = env_force_color();` at line 91
  precedes `env_no_color()` at line 94, verified at tag `v3.0.2`). That inverts
  `no-color.org`, CPython, `anstream` and the ts port, and would break acceptance criterion 6.
  `owo-colors` reaches `FORCE_COLOR` only by depending on `supports-color`, inheriting the
  inversion.
- `console` 0.16.6 lets `CLICOLOR_FORCE` override `NO_COLOR` (`src/utils.rs:18`) and treats
  `NO_COLOR=` (set, empty) as disabling (`env::var("NO_COLOR").is_ok()`, `src/unix_term.rs:30`),
  against the standard's non-empty rule.
- `termcolor` 1.4.1 accepts an explicit `ColorChoice` and reads `NO_COLOR` and `TERM`, but
  contains **zero** occurrences of `FORCE_COLOR` and of `CLICOLOR`: it has no force tier at all.

So the template writing its own resolver is not a preference; it is what the ecosystem's own
maintainers expect callers to do. This is a claim about the seven candidates read at their
tags, not about every crate on crates.io.

**Where the recommended chain departs from py, and why.** py resolves
`--no-color > NO_COLOR > config`: at pin `b08bccfb`, `context.py` returns `"never"` on
`NO_COLOR` at line 192, *before* `return config_color` at line 194 (verified). A user with
`NO_COLOR=1` exported globally therefore cannot re-enable colour for that one program in its
own config file. `no-color.org`'s FAQ states the opposite intent — *"User-level configuration
files and per-instance command-line arguments should override the NO_COLOR environment
variable"* (verified) — and `cargo` implements the opposite: at tag `0.99.0`,
`src/cargo/util/context/mod.rs:1209` reads `let color = color.or_else(|| term.color.as_deref());`
(the `--color` flag, else the `[term] color` config key) and hands the result to
`set_color_choice`, whose `Auto` then defers to the environment-and-TTY chain. This decision
follows the standard and the toolchain: an *explicit* config `always`/`never` sits above
`NO_COLOR`, while an absent or `auto` value falls through and costs nothing. **This is the
recorded rationale for a follow-on py change; no py file and no ledger row is edited here.**

**Where the recommended chain departs from `force-color.org`, and why.** That standard says
`FORCE_COLOR` counts when *"present and not an empty string (regardless of its value)"*
(verified), and its own example applies it after argument and config parsing — i.e. the
variable would beat an explicit `--no-color`. Two departures are taken deliberately: the
per-invocation flag wins (both source repos, CPython, `anstream` and `cargo` agree, and
`no-color.org`'s FAQ states the general rule), and `FORCE_COLOR="0"` falls through rather than
forcing, following the ts port (`src/lib/colors.ts:35` at pin `cb1cbcb2`: `forceColor !== '0'`,
verified) and `supports-color`'s `"false" => 0` mapping.

**Why `FORCE_COLOR` is kept at all, given `anstream` supplies `CLICOLOR_FORCE` for free.**
F288's capability is satisfied by `CLICOLOR_FORCE` alone, so F288 as recorded is preserved
literally and needs no baseline review. The *spelling* is widened because
`https://bixense.com/clicolors/` — the standard `anstyle-query` actually implements — now
opens with *"Note: This standard is deprecated… Software that already supports this standard
should treat FORCE_COLOR as an alias for CLICOLOR_FORCE"* (verified), CPython reads
`FORCE_COLOR`, and the ts port already does.

**BASELINE-REVIEW.** One inherited row is challenged, on capability grounds, and is carried
through unresolved as the prompt requires. The ledger is not edited.

BASELINE-REVIEW: F286 — the user must be able to state colour policy per invocation in both directions — keep the inherited boolean `--no-color` and add a tri-state `--color <auto|always|never>` alongside it, with `--no-color` defined as an alias for `--color=never` and an explicit conflict when both are given with opposite senses; affected items are F286 (row wording), R60 (`cli-parsing-framework`, which defines the global flag block) and R66 (`output-format-surface`, which shares that block) — evidence: a boolean flag can only turn colour off, so a user piping into `less -R` or writing a CI log has no per-invocation way to turn it on and must fall back to an environment variable, while all three surveyed reference implementations take a *value* rather than a boolean: `cargo`, the Rust project's own CLI, parses `--color` as exactly `always | never | auto` at `crates/cargo-util-terminal/src/shell.rs:573-576` in tag 0.99.0; `clap`, the argument parser the Opus raw records at 226,398,266 90-day downloads (`GET https://crates.io/api/v1/crates/clap`, retrieved 2026-09-10), ships `pub enum ColorChoice { Auto, Always, Never }` at `clap_builder/src/util/color.rs:6,27,42,57` in tag v4.6.6; and `ripgrep`, which the same raw records at 68,148 GitHub stars (`GET https://api.github.com/repos/BurntSushi/ripgrep`, retrieved 2026-09-10), declares `--color` with metavariable `WHEN` at `crates/core/flags/defs.rs:698-701` in tag 15.2.0 and accepts **four** values, `never | auto | always | ansi`, not three — every one of those file:line citations re-read at its tag and asserted by this decision's check script, and `anstream::ColorChoice` is itself tri-state, so a boolean-only surface discards a state the chosen stack already models; cost of declining: the force-on path exists only through `FORCE_COLOR`/`CLICOLOR_FORCE`, discoverable only from documentation.

**Reference implementations.** `rust-lang/cargo` at tag `0.99.0` is the closest maintained
reference for the whole design: it declares `anstream = "1.0.0"` and `anstyle = "1.0.14"`
(`Cargo.toml:21-22`), resolves the flag and config tiers itself
(`src/cargo/util/context/mod.rs:1209-1210`), constructs one `AutoStream` per stream with an
explicitly resolved choice (`crates/cargo-util-terminal/src/shell.rs:53-54`, rebuilt at
`:262-263`), never calls `colorchoice`'s `write_global` (`grep -c` = 0 over that file), and
renders into a captured buffer with `AutoStream::never` for deterministic tests (`:71`) — all
verified. `clap_builder` v4.6.6 declares the same two versions
(`clap_builder/Cargo.toml:64-65`), so with `clap` in the graph the template links crates it
would already carry, at one `anstyle` major.

**Performance.** No throughput or binary-size number is claimed. The chain resolves once per
process and performs at most four environment lookups plus one `is_terminal()` call per
stream. `anstream` ships `divan` benchmarks for `strip`, `stream` and `wincon`; **none was
executed here**, so `StripStream`'s per-byte cost on the un-coloured path is described
qualitatively and left unmeasured for P03.

**Fitness gates** (verified, `## Empirical check` §6): (1) licence — `anstyle`, `anstream`,
`anstyle-query` and `colorchoice` are all `MIT OR Apache-2.0`; `colored` 3.1.1 is `MPL-2.0`
and is **excluded by gate 1**. (2) MSRV — the four crates in the stack table each declare
`rust-version = "1.66.0"`, far below any floor the policy can produce against a 1.9x stable;
the resolved dependency tree must still be checked against the then-current floor once a
lockfile exists, so this is a qualified pass. (3) advisories — `anstyle` has no RustSec page
(HTTP 404); `anstream`'s only advisory is `RUSTSEC-2024-0404` (INFO/unsound), patched at
`>= 0.6.8` and therefore not applicable at 1.0.0; `atty` carries two open advisories
(`RUSTSEC-2021-0145`, `RUSTSEC-2024-0375`) and is **excluded by gate 3**. `unsafe` posture:
`anstyle` and `colorchoice` contain none; `anstream` has two `unsafe` blocks, inside one `unsafe fn` that takes a written `safety_justification` and validates with `str::from_utf8(…).expect(…)` under `cfg!(debug_assertions)` instead of assuming, wrapping
`str::from_utf8_unchecked` in `src/adapter/strip.rs`; `anstyle-query`'s `unsafe` Win32 calls
sit under `#[cfg(windows)]` and are not compiled for this template's matrix. (4) OS matrix —
`rust-cli/anstyle` CI runs `ubuntu-latest` and `macos-latest` (and `windows-latest`, which is
not required). (5) default features — `anstream` is `default = ["auto", "wincon"]`; `auto` is
what supplies tiers 5–7 and must stay on; no `tokio`, `async-std` or `futures` dependency, so
there is no async-runtime coupling. (6) binary size and compile time — qualitatively low
(`anstyle` is dependency-free; `anstream`'s tree is `anstyle`, `anstyle-parse`, `utf8parse`,
`colorchoice`, `anstyle-query`, `is_terminal_polyfill`, plus a Windows-only adapter) and
**unmeasured**.

re-verify: before P03 implements the colour gate, or earlier on any of — `rust-cli/anstyle`
issue #192 closing (built-in `FORCE_COLOR` would let the template drop tier 4); an `anstream`
2.0 or `anstyle` 2.0; `clap` changing the `anstyle` major it depends on; a new RustSec
advisory against any member; `no-color.org`, `force-color.org` or `bixense.com/clicolors`
changing their current text; R63 selecting `indicatif`/`console`, which activates the
second-detection-stack caveat; R60 selecting a non-`clap` parser.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

This item's `- owns:` and `- consumes:` lines in the prompt's `## Couplings` are both empty,
so it registers no parameter value and consumes none. F287, F288, F289 and F290 are ledger
rows, not registry parameters; their answers are stated in `## Decision` rather than
registered. No conflict line is raised, by either raw report or by this decision: nothing
recommended here requires a consumed parameter to change.

How the four fixed parameters bear on the decision. `license` excluded `colored` 3.1.1
(`MPL-2.0`) before popularity was weighed, even though the Opus raw records it as the
most-depended-on candidate in this field at 6,631 reverse dependencies
(`GET https://crates.io/api/v1/crates/colored/reverse_dependencies`, retrieved 2026-09-10). `msrv-policy` is satisfied with a wide margin — the four crates in the stack table each declare
`rust-version = "1.66.0"` and `std::io::IsTerminal` needs 1.70.0 — so this item never forces
an MSRV bump; the dependency-tree check against the then-current floor still belongs to P03's
CI. `target-os-matrix` is satisfied and exceeded, and it is why `anstream`'s `wincon` default
feature is kept but not relied on. `rust-edition` has one concrete consequence in the design:
`std::env::set_var` is `unsafe` in edition 2024, which is an additional reason the resolver
takes an injected environment source rather than having tests mutate the process environment.
Each recommended crate is itself `edition = "2021"`, which constrains only its own source; a
2024-edition workspace consumes it normally.

## Empirical check

**Toolchain.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4 (build 25E246), Darwin arm64.

**Command and working directory.**

```
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R65/2026-09-05T183457Z-cc32974b5d89
bash review/evidence/check-color-enablement-chain.sh
```

**Exit status:** `0` (all 146 assertions passed). The run takes a few minutes: crates.io
rate-limits a burst of requests, so each crate's `/versions` document is fetched once per
run, paced, retried with exponential backoff, and snapshotted into
`review/evidence/crates-io-<crate>-versions.json`. **A registry endpoint that cannot be
retrieved fails the check loudly; it is never silently treated as a pass.**
**Full output:** `review/evidence/check-color-enablement-chain.log`.
**Script:** `review/evidence/check-color-enablement-chain.sh`.

The script **verifies claims and implements nothing**: it scaffolds no crate, writes no
resolver, and creates no template file. It starts with `set -o pipefail`, and every check
asserts on expected *content* — a substring or an exact count — rather than on an exit code,
counting passes and failures and returning non-zero if any failed. Its nine sections:

1. **Pinned source repositories**, read only through `git show <pin>:<path>` — py
   `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, ts `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`.
   Confirms py's `_resolve_color` signature; that py's `NO_COLOR` branch (line 192) precedes
   `return config_color` (line 194), which is the departure this decision records; that both
   py consoles are built from the same `nc`/`force` pair; that py styles its stdout table
   (`header_style="bold cyan"`); that py checks the stream's own `isatty()`; and ts's
   `colorEnabled`, its `FORCE_COLOR` read, its `'0'` carve-out, and `isTTY: deps.stderrIsTTY`.
2. **Tag re-reads.** Every source the Opus raw disclosed as read from a default branch is
   re-read at an immutable tag: `clap-rs/clap@v4.6.6`, `rust-lang/cargo@0.99.0`,
   `BurntSushi/ripgrep@15.2.0`, `console-rs/console@0.16.6`, `owo-colors/owo-colors@v4.4.0`,
   `eyre-rs/eyre@color-eyre-v0.6.5`, `BurntSushi/termcolor@1.4.1`, plus
   `zkat/supports-color@v3.0.2`. Each tag's existence is asserted before it is read.
3. **The core claim.** The tier audit over the seven candidates described in
   `### Principles and implementation`, including the `grep -c FORCE_COLOR` = 0 result for
   `anstyle-query`, `anstream`'s `fn choice()` printed verbatim, and a line-order assertion
   that `no_color()` (line 205) precedes `clicolor_force()` (207) precedes `raw.is_terminal()`
   (211).
4. **Issue #192**, fetched from the GitHub API, snapshotted, and asserted from the snapshot.
5. **The three standards pages**, fetched live, snapshotted alongside the log, and asserted on
   the exact sentences quoted in this decision.
6. **Fitness gates**: crates.io per-version metadata (`license`, `rust_version`, `edition`,
   `created_at`, newest non-yanked `num`), the `anstream` manifest's default and `test`
   features, the `anstyle` workspace `rust-version`, `is_terminal_polyfill`'s delegation to
   `std`, the CI matrix, and the RustSec pages for `anstream`, `anstyle` and `atty`.
7. **First-party practice at tags**: cargo's and clap's declared versions, cargo's two
   per-stream `AutoStream::new` constructions, its `AutoStream::never` test seam, its zero
   `write_global` calls, and its flag-above-config line.
8. **BASELINE-REVIEW F286 evidence**: the flag shapes of cargo, clap and ripgrep at their tags.
9. **Parameters**: the four `- assumes` lines are *generated* by `awk` from
   `docs/port/PARAMETERS.md` into `review/evidence/params-generated.txt` and `diff`ed against
   the lines in this file; the diff must be empty.
10. **Line-number ledger**: every `file:line` citation appearing in this decision — 35 of
    them, across the two source pins and eight upstream tags — is re-read at that exact line
    number and asserted to carry the expected text. This is what makes the sentence "every
    line number cited here is a tag or pin offset" a claim an auditor can rerun rather than a
    claim to be taken on trust.

**Reproducibility, stated exactly.** The script was run twice in succession and the two logs
were diffed; they are byte-for-byte identical, and the saved log is the output of that second
run. Reruns stay byte-identical **while five live inputs hold their current values**, and a
rerun that differs is evidence one of them moved, not that the log was mis-saved:

| Volatile input | Current value | Where it is pinned for comparison |
|---|---|---|
| `rust-cli/anstyle` issue #192 state | `open` (printed as an `INFO` line, not asserted) | `review/evidence/anstyle-issue-192.json` |
| the three standards pages' text | as quoted above | `review/evidence/snapshot-no-color.org.txt`, `snapshot-force-color.org.txt`, `snapshot-bixense-clicolors.txt` |
| newest non-yanked version of `anstream`, `anstyle`, `anstyle-query`, `colorchoice` | `1.0.0`, `1.0.14`, `1.1.5`, `1.0.5` | asserted, each marked `VOLATILE` in the log; the fetched documents are snapshotted as `review/evidence/crates-io-<crate>-versions.json` |
| `zkat/supports-color` tag count | 15 | the assertion needs only `v3.0.2` to exist |

Everything else the log prints comes from immutable sources: git tags, `git show` at a commit
pin, and crates.io per-version fields for versions already published. **No download count and
no `pushed_at` value is printed**, because those move daily; the adoption and responsiveness
figures cited in the raws are carried with the raws' own retrieval dates (Codex 2026-09-05,
Opus 2026-09-10) and are not re-asserted here.

**What the check does not establish.** It does not run any Rust code, because the template
does not exist. Acceptance criteria 1–10 are therefore **proposed, not executed**; so are the
`cargo tree` graph-hygiene assertions and the pty-based per-stream test. Those are listed
under `## Engines` as what P03 must prove.

## Engines

- codex `raw/codex-5df6c0a31e49b8cfa8401fb94d64a97e9858516d0ec6962993df20d984362b94.md`
- opus `raw/opus-a92869ae8e70073d1a94ec2e3df1ef8d700d2cc91b324064903391fe3babfa33.md`

The two engines agree on the load-bearing shape: `anstream` as the stream adapter; an
explicitly resolved `ColorChoice` passed into `AutoStream::new` per stream rather than
`AutoStream::auto` or `colorchoice`'s process global; `std::io::IsTerminal` as the sole TTY
primitive for F290; `NO_COLOR` above any force variable; `FORCE_COLOR="0"` not forcing; and
the template owning the tiers the surveyed crates do not supply. Four things they did not agree on, and one
misdirected line, are settled here.

**Disagreement 1 — the config tier.** Codex recommends **no** `color` config key in the
initial schema, to avoid "an untested fourth input"; Opus recommends naming the key and
placing an explicit `always`/`never` **above** `NO_COLOR`. Settled for Opus, on two pieces of
evidence both verified by the check: `no-color.org`'s FAQ states that user-level configuration
files and per-instance command-line arguments *should* override `NO_COLOR`, and `cargo` 0.99.0
implements exactly that (`let color = color.or_else(|| term.color.as_deref());`). Codex offers
no counter-evidence, only a preference for fewer inputs. Two consequences are recorded rather
than smoothed over: this inverts py's implemented order, which is why the departure is written
out in full in `### Principles and implementation`; and it adds one config key whose type,
validation and error reporting are R53's and R55's, not this item's.

**Disagreement 2 — the resolver's return type and its test seam.** Codex's resolver takes
injected `stdout_is_terminal` / `stderr_is_terminal` booleans and returns `Always` or `Never`
per stream, *deliberately excluding* `CLICOLOR`, `CLICOLOR_FORCE`, `TERM` and `CI` so that the
whole chain is unit-testable without touching the process environment. Opus's resolver returns
`Auto` for anything it cannot decide and lets `AutoStream` resolve tiers 5–7 against the real
environment and the real descriptor. Both produce identical observable behaviour for tiers
1–4. Settled for Opus's shape, because Codex's excludes `TERM=dumb` handling, and acceptance
criterion 9 — no colour on a `TERM=dumb` terminal — is behaviour the recommended stack
already implements for free (`anstream` via `anstyle_query::term_supports_color()`), and so
does the runner-up adapter (`termcolor` via its own `TERM` check); both were verified. **The cost of that choice is recorded plainly: tiers 5, 6 and 7
are then provable only end-to-end, against a real pipe and a real pty, because
`resolve_color` returns `Auto` and `anstream` reads the real environment from there.** Codex's
alternative buys unit-testability of the TTY tier and pays for it with `TERM` and `CI`
handling; if P03 finds the pty harness unworkable on both runners, that trade is the fallback
already on the record.

**Disagreement 3 — `anstyle` as a direct dependency.** Opus takes it as a direct workspace
dependency and makes `anstyle::Style` the only colour type permitted in the library crate's
public API; Codex leaves styling-crate selection outside R65 entirely. Settled for Opus: the
prompt asks for a stack, and the public-API constraint is a real interaction with R04
(`public-api-surface-enforcement`) that has to be decided by someone. Codex's position is not
contradicted — it simply does not answer the question.

**Disagreement 4 — the `test` dev-feature.** Opus recommends enabling `anstream`'s `test`
feature in `[dev-dependencies]`; Codex does not mention it. The feature exists and its manifest
describes it as "Enable in `dev-dependencies` to make sure output is captured for tests"
(verified at tag `anstream-v1.0.0`), so Opus's recommendation is adopted; there is no conflict.

**A misdirected line, not carried through.** Codex emits `BASELINE-REVIEW: F287`. F287 is a
`DIVERGENT` row that **this item decides outright**, not an inherited baseline it must
challenge — so its content is simply this decision's answer to F287 and is recorded as such in
`## Decision`. Only Opus's `BASELINE-REVIEW: F286` is carried through, because F286 is the row
the prompt marks inherited `COMMON → REUSE`.

**A raw disclosure that is wrong, and what replaced it.** The Opus raw disclosed under method
note (b) that `zkat/supports-color` "has no release tags, so its source was read from `main`",
and inferred identity with the published 3.0.2 from matching timestamps. **That is false**: the
repository publishes 15 tags, including `v3.0.2` (verified). The inversion claim — `FORCE_COLOR`
evaluated above `NO_COLOR` — was therefore re-verified at tag `v3.0.2` rather than on `main`, and
holds there (`let force_color = env_force_color();` at line 91, `env_no_color()` at line 94). The
five other default-branch reads disclosed under (c) — `console`, `owo-colors`, `clap`, `cargo`,
`ripgrep`, `color-eyre` — were likewise re-read at tags, and every substantive claim held. Their
**line numbers did not**: the raw's `master` offsets differ from the tagged ones
(cargo's `--color` parse is at `shell.rs:573-576` at `0.99.0`, not `584-599`; its flag-above-config
line is `context/mod.rs:1209`, not `1207`; `colorchoice`'s global is `static USER: AtomicChoice`
at `lib.rs:41` over `AtomicChoice(AtomicUsize)` at `:44`, not "`AtomicUsize` at `:31-38,41`";
`color-eyre`'s `owo-colors` dependency is at `Cargo.toml:25` and is workspace-inherited, not `:26`).
Every line number cited in this decision is a tag offset, verified by the check.

**One raw claim corrected in the BASELINE-REVIEW evidence.** The Opus raw's F286 line asserts
that "every first-party Rust CLI exposes the tri-state form". Verified at tags, cargo and clap
are exactly tri-state, but `ripgrep` 15.2.0's `--color` accepts **four** values
(`never | auto | always | ansi`). The carried-through line states what the three tools actually
do — all take a value rather than a boolean — rather than the stronger claim.

**Where evidence is incomplete, and what P03 must validate.** Every item below is unproven
here because no Rust template exists to run it against; none is treated as established.

1. **Acceptance criteria 1–10** as executed tests. Criteria 1–4, 6 and the `FORCE_COLOR` half
   of 5 are unit-provable over `resolve_color` with an injected environment source. Criteria 7,
   9 and the `CLICOLOR_FORCE` half of 5 are not, for the reason recorded under Disagreement 2.
2. **Criterion 8 end-to-end**, the only check in this list that distinguishes a per-stream
   gate from a shared one: run the built binary with stdout redirected to a file and stderr attached
   to a pty, assert no `0x1b` in the file and `0x1b` in the captured stderr, then the reverse.
   The pty harness is R32's decision, and **allocating a pty portably on both `ubuntu-latest`
   and `macos-latest` is the one part of this plan with real portability risk**; pilot it early.
3. **Graph hygiene**: `cargo tree -i anstyle` yielding exactly one version, `cargo tree -i atty`
   and `cargo tree -i is-terminal` yielding "package not found", and `cargo deny check advisories`
   clean for the colour stack.
4. **Dependency-tree MSRV** against the then-current floor, which needs a lockfile that does not
   yet exist. The per-crate `rust-version = "1.66.0"` figures are verified; the resolved tree is not.
5. **`StripStream`'s runtime cost** on this template's workloads. `anstream` ships `divan`
   benchmarks for it; none was run, and no throughput or binary-size number is claimed anywhere
   in this decision.
6. **`anstyle::Style` in the library crate's public API** passing R04's enforcement, which R04
   owns; this decision only records that the type is intended to cross that boundary.
7. **The `console` collision**, if R63 selects `indicatif`: `console` 0.16.6 runs a second
   detection stack with `CLICOLOR_FORCE` above `NO_COLOR` and an `is_ok()` test for `NO_COLOR`
   (both verified), so the template would have to force its own decision onto it through
   `console::set_colors_enabled` / `set_colors_enabled_stderr`. That is R63's decision to make,
   handed over as evidence, not decided here.
