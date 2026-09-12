# R65 — color-enablement-chain — DECISION (revision 2, 2026-09-12)

**Revision note.** Revision 2 rewrites revision 1 (sha256
`0582a7c58e78fe4a1ba3a9b01c321f6664eca7089c4f87a80972c593eb83e3af`) in place. No revision of
this decision has been published, so there is no `## Supersedes`. It answers the five findings
of the revision-1 audit (`review/audit-codex.md`, actor
`audit-codex-2026-09-05T183457Z-cc32974b5d89-r1`, model `gpt-5.6-terra`, family openai, verdict
reject): F1 the cited log was not the output of the current saved script (the script had grown
16 assertions after the log was saved, and the section count was misstated); F2 the three
unversioned standards pages were asserted live rather than from the snapshots saved beside the
log; F3 the resolver's input list contradicted the resolver signature in the same document; F4
the `BASELINE-REVIEW` line counted `clap`, an argument-parsing library, as a third surveyed
command-line flag; F5 the saved issue JSON did not establish the `clap`-and-`cargo`-maintainer
role attributed to the quoted commenter. Everything the audit did not challenge is carried
through unchanged, including the argument of `### Principles and implementation` for the
template owning tiers 1–4, the `BASELINE-REVIEW: F286` proposal, and the four `- assumes`
lines.

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

**The resolver's inputs are exactly three**, matching its signature in the table above: the
parsed flag value, the config value, and an injected environment source. No stream handle is
among them. The handle enters one tier lower, inside `anstream`, and only when the resolver
returns `Auto`: `AutoStream::new(raw, choice)` (`crates/anstream/src/auto.rs:62` at tag
`anstream-v1.0.0`) dispatches `ColorChoice::Auto` to `Self::auto(raw)` (`:65`), which calls
`Self::choice(&raw)` (`:78`) — the only point at which the stream handle can affect *whether
colour is emitted*. That function consults `ColorChoice::global()` first (`:199`, the
`colorchoice` process global this template never writes, so it is `Auto` and the chain
continues), then the `anstyle-query` environment probes, then `raw.is_terminal()` (`:211`).
Two other constructors also read the handle, and both are compiled on this template's
`target-os-matrix`: `always_ansi()` at `:95` (to call `enable_ansi_colors()`) and `always()`
at `:113` (to choose the `wincon` writer, inside an `if cfg!(windows)` whose branches both
compile because `cfg!` yields a `bool`). Neither decides *whether* colour is emitted — that is
already settled when they run — only *how* the already-chosen colour reaches the stream. So
the *chain* has four kinds of input and the *resolver* has three;
tiers 5–7 are the ones that consume the fourth, and they are not
the template's code. Every line number in this paragraph is asserted by the check script's
§10 ledger. **This decision describes the resolution order and its inputs; it writes no
code.** The function body, its types and its module placement are P03's.

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
informal web standards — `https://no-color.org/` and `https://force-color.org/` — and the
source repos' own recorded decisions: py's `R5.5`, in the
docstring at `src/py_launch_blueprint/cli/context.py:189` at pin `b08bccfb`, and ts's
`D-018(2)`/`D-038` in `docs/port/TS_PORT_DECISIONS.md`. **Agreement is required at the level
of capability and observable behaviour, not at the level of variable names or libraries.**

**Which copy of the three unversioned standards pages this decision reads, and why it
matters.** `no-color.org`, `force-color.org` and `bixense.com/clicolors` publish no version,
tag or date: their text can change under a citation without any signal. Every quotation from
them below is therefore read from a snapshot saved in this run's evidence directory, not from
the live page — the snapshot is the evidence, and the check script asserts against the file
and performs no fetch in that section:

| Page | Snapshot read | sha256 of the bytes asserted |
|---|---|---|
| `https://no-color.org/` | `review/evidence/snapshot-no-color.org.txt` | `4ce0cfb7f8c79fcf35cb86993863a739df8b8dd0fa49c2f02c4f39eed8db8992` |
| `https://force-color.org/` | `review/evidence/snapshot-force-color.org.txt` | `829aee8030f526ae6d684dc9e855c540d60ac1e7cd8084b1a54949d5e055ebe1` |
| `https://bixense.com/clicolors/` | `review/evidence/snapshot-bixense-clicolors.txt` | `d1872728a3c3442d5bcd90e0fc285ee49db000e13221334240e2703aced321f4` |

All three were retrieved 2026-09-10T16:10:03Z, stripped of HTML tags and whitespace-collapsed by
the same pipeline that now reads them back, and committed in `7f4c85e`. Re-reading the live
pages is a *re-verification* step, not the source of any claim here: it is opt-in
(`R65_REFRESH_SNAPSHOTS=1`), it writes `snapshot-<page>-live.txt` beside each snapshot and
diffs the two, and it never overwrites a snapshot. Below, "(snapshot)" marks a quotation
asserted against these files. What this costs: a quotation is only as current as
2026-09-10T16:10:03Z, which is why a change to any of the three pages is a `re-verify` trigger.

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
- The omission is **deliberate, and an owner of the crate that omits it says so on the
  record.** `rust-cli/anstyle` issue #192, "Supporting FORCE_COLOR as an alias to
  CLICOLOR_FORCE", opened 2024-06-02 and still open: `epage` wrote on 2024-06-04T02:23:48Z —
  *"When I was weighing what to build-in, I was less interested in how wide spread something
  is about how consistently its expected to be implemented. People can always build their own
  thing on top but I didn't feel like arbitrating between parties arguing over 3 different
  implementations."* Exactly two things are claimed about who said it, and each has its own
  source: the saved issue-comment JSON records `author_association: COLLABORATOR` on
  `rust-cli/anstyle` (`review/evidence/anstyle-issue-192-comments.json`), and the crates.io
  owners endpoint for the crate in question lists `epage` as an individual owner of
  `anstyle-query` itself (`GET https://crates.io/api/v1/crates/anstyle-query/owners`,
  retrieved 2026-09-12, snapshotted as
  `review/evidence/crates-io-anstyle-query-owners.json`). So the statement comes from someone
  who owns the crate whose omission is at issue — which is what the argument needs. **No
  `clap` or `cargo` maintainer role is claimed:** the same endpoint for `clap` lists
  `kbknapp` and two teams and does not name `epage` individually
  (`review/evidence/crates-io-clap-owners.json`), and no first-party source for `cargo` team
  membership was read here. Crate ownership is mutable, so it is listed as a volatile input
  below. Title, opening date, comment author, association, comment timestamp, the quoted
  sentence and the ownership line are each asserted by the check script (§4).
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

So the template writing its own resolver is not a preference; it is what an owner of the crate
that omits the tier says, on the record, that callers should do. This is a claim about the
seven candidates read at their tags and about one recorded statement by one crate owner, not
about every crate on crates.io and not about the Rust ecosystem's maintainers generally.

**Where the recommended chain departs from py, and why.** py resolves
`--no-color > NO_COLOR > config`: at pin `b08bccfb`, `context.py` returns `"never"` on
`NO_COLOR` at line 192, *before* `return config_color` at line 194 (verified). A user with
`NO_COLOR=1` exported globally therefore cannot re-enable colour for that one program in its
own config file. `no-color.org`'s FAQ states the opposite intent — *"User-level configuration
files and per-instance command-line arguments should override the NO_COLOR environment
variable"* (snapshot `snapshot-no-color.org.txt`) — and `cargo` implements the opposite: at tag `0.99.0`,
`src/cargo/util/context/mod.rs:1209` reads `let color = color.or_else(|| term.color.as_deref());`
(the `--color` flag, else the `[term] color` config key) and hands the result to
`set_color_choice`, whose `Auto` then defers to the environment-and-TTY chain. This decision
follows the standard and the toolchain: an *explicit* config `always`/`never` sits above
`NO_COLOR`, while an absent or `auto` value falls through and costs nothing. **This is the
recorded rationale for a follow-on py change; no py file and no ledger row is edited here.**

**Where the recommended chain departs from `force-color.org`, and why.** That standard says
`FORCE_COLOR` counts when *"present and not an empty string (regardless of its value)"*
(snapshot `snapshot-force-color.org.txt`), and its own example applies it after argument and
config parsing — i.e. the
variable would beat an explicit `--no-color`. Two departures are taken deliberately: the
per-invocation flag wins (both source repos, CPython, `anstream` and `cargo` agree, and
`no-color.org`'s FAQ states the general rule in the snapshot cited above), and `FORCE_COLOR="0"` falls through rather than
forcing, following the ts port (`src/lib/colors.ts:35` at pin `cb1cbcb2`: `forceColor !== '0'`,
verified) and `supports-color`'s `"false" => 0` mapping.

**Why `FORCE_COLOR` is kept at all, given `anstream` supplies `CLICOLOR_FORCE` for free.**
F288's capability is satisfied by `CLICOLOR_FORCE` alone, so F288 as recorded is preserved
literally and needs no baseline review. The *spelling* is widened because
`https://bixense.com/clicolors/` — the standard `anstyle-query` actually implements — opened
with *"Note: This standard is deprecated… Software that already supports this standard
should treat FORCE_COLOR as an alias for CLICOLOR_FORCE"* when it was snapshotted
(snapshot `snapshot-bixense-clicolors.txt`), CPython reads
`FORCE_COLOR`, and the ts port already does.

**BASELINE-REVIEW.** One inherited row is challenged, on capability grounds, and is carried
through unresolved as the prompt requires. The ledger is not edited.

BASELINE-REVIEW: F286 — the user must be able to state colour policy per invocation in both directions — keep the inherited boolean `--no-color` and add a tri-state `--color <auto|always|never>` alongside it, with `--no-color` defined as an alias for `--color=never` and an explicit conflict when both are given with opposite senses; affected items are F286 (row wording), R60 (`cli-parsing-framework`, which defines the global flag block) and R66 (`output-format-surface`, which shares that block) — evidence: a boolean flag can only turn colour off, so a user piping into `less -R` or writing a CI log has no per-invocation way to turn it on and must fall back to an environment variable, while both of the surveyed command-line tools take a *value* rather than a boolean, and the parser the template would use already models the same choice as a tri-state type in its API: `cargo`, the Rust project's own CLI, parses `--color` as exactly `always | never | auto` at `crates/cargo-util-terminal/src/shell.rs:573-576` in tag 0.99.0; `ripgrep`, which the Opus raw records at 68,148 GitHub stars (`GET https://api.github.com/repos/BurntSushi/ripgrep`, retrieved 2026-09-10), declares `--color` with metavariable `WHEN` at `crates/core/flags/defs.rs:698-701` in tag 15.2.0 and accepts **four** values, `never | auto | always | ansi`, not three; and `clap` — an argument-parsing *library*, not a CLI, so it has no `--color` flag of its own and none was surveyed or is claimed here — ships the library enum `clap_builder::util::color::ColorChoice`, `pub enum ColorChoice { Auto, Always, Never }`, at `clap_builder/src/util/color.rs:6,27,42,57` in tag v4.6.6, which is evidence that the parser R60 is most likely to select already carries the tri-state form as an API model, not evidence of a third observed command-line shape (the Opus raw records `clap` at 226,398,266 90-day downloads, `GET https://crates.io/api/v1/crates/clap`, retrieved 2026-09-10) — every one of those file:line citations re-read at its tag and asserted by this decision's check script, and `anstream::ColorChoice` is itself tri-state, so a boolean-only surface discards a state the chosen stack already models; cost of declining: the force-on path exists only through `FORCE_COLOR`/`CLICOLOR_FORCE`, discoverable only from documentation.

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
changing the text this decision quotes from their snapshots (run the check script with
`R65_REFRESH_SNAPSHOTS=1` to detect it); the `anstyle-query` crates.io ownership line
changing, which is what attributes the recorded statement quoted above; R63 selecting
`indicatif`/`console`, which activates the
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

**Exit status:** `0` (all 177 assertions passed, 0 failed). The run takes a few minutes: crates.io
rate-limits a burst of requests, so each crate's `/versions` document is fetched once per
run, paced, retried with exponential backoff, and snapshotted into
`review/evidence/crates-io-<crate>-versions.json`. **A registry endpoint that cannot be
retrieved fails the check loudly; it is never silently treated as a pass.**
**Full output:** `review/evidence/check-color-enablement-chain.log`.
**Script:** `review/evidence/check-color-enablement-chain.sh`.

The script **verifies claims and implements nothing**: it scaffolds no crate, writes no
resolver, and creates no template file. It starts with `set -o pipefail`, and every check
asserts on expected *content* — a substring or an exact count — rather than on an exit code,
counting passes and failures and returning non-zero if any failed. It prints **eleven**
sections, `## 0` through `## 10`: section 0 is the toolchain block quoted above, and sections
1–10 are these:

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
   `eyre-rs/eyre@color-eyre-v0.6.5`, `BurntSushi/termcolor@1.4.1`,
   `zkat/supports-color@v3.0.2`, `polyfill-rs/is_terminal_polyfill@v1.70.2`, plus the four
   `rust-cli/anstyle` tags the stack itself is read at — `anstream-v1.0.0`,
   `anstyle-query-v1.1.5`, `colorchoice-v1.0.5` and `v1.0.14`. That is thirteen tags, and
   each one's existence is asserted before any file is read from it.
3. **The core claim.** The tier audit over the seven candidates described in
   `### Principles and implementation`, including the `grep -c FORCE_COLOR` = 0 result for
   `anstyle-query`, `anstream`'s `fn choice()` printed verbatim, a line-order assertion
   that `no_color()` (line 205) precedes `clicolor_force()` (207) precedes `raw.is_terminal()`
   (211), and a sweep asserting zero occurrences of `env::args` in each candidate read — the
   evidence for "no crate parses this application's argv".
4. **Issue #192**, fetched from the GitHub API, snapshotted, and asserted from the snapshot;
   plus the crates.io owners endpoints for `anstyle-query` and `clap`, snapshotted, which fix
   exactly what is and is not claimed about the quoted commenter's role.
5. **The three standards pages**, read from the committed snapshots named in
   `### Principles and implementation` and asserted on the exact sentences quoted in this
   decision. This section performs no network fetch and overwrites no snapshot; each
   snapshot's sha256 is printed in the log beside the assertion that read it. Live
   re-verification is opt-in (`R65_REFRESH_SNAPSHOTS=1`), writes `*-live.txt` files and diffs
   them, and adds no assertion — so the pass inventory is identical with and without it.
6. **Fitness gates**: crates.io per-version metadata (`license`, `rust_version`, `edition`,
   `created_at`, newest non-yanked `num`), the `anstream` manifest's default and `test`
   features, its full `[dependencies]` list printed and asserted entry by entry, its
   Windows-only `anstyle-wincon` target dependency, the `anstyle` workspace `rust-version`,
   `is_terminal_polyfill`'s delegation to `std`, `anstyle-query`'s `unsafe` being confined to
   its `#[cfg(windows)]` module, the CI matrix, and the RustSec pages for `anstream`,
   `anstyle` and `atty`.
7. **First-party practice at tags**: cargo's and clap's declared versions, cargo's two
   per-stream `AutoStream::new` constructions, its `AutoStream::never` test seam, its zero
   `write_global` calls, and its flag-above-config line.
8. **BASELINE-REVIEW F286 evidence**: the `--color` flag shapes of the two surveyed CLIs,
   cargo and ripgrep, and `clap`'s library `ColorChoice` enum, each at its tag.
9. **Parameters**: the four `- assumes` lines are *generated* by `awk` from
   `docs/port/PARAMETERS.md` into `review/evidence/params-generated.txt` and `diff`ed against
   the lines in this file; the diff must be empty.
10. **Line-number ledger**: every `file:line` citation appearing in this decision — 41 of
    them, across the two source pins and nine upstream tags — is re-read at that exact line
    number and asserted to carry the expected text. This is what makes the sentence "every
    line number cited here is a tag or pin offset" a claim an auditor can rerun rather than a
    claim to be taken on trust.

**Reproducibility, stated exactly.** The cited log was regenerated from the script as it now
stands — this is what the revision-1 audit's F1 found wrong, the script having grown 16
assertions after the previous log was saved. The script was then run twice in succession on
2026-09-12 and the two logs were diffed with `diff -u`: the diff is empty, they are
byte-for-byte identical, and the saved log is the output of the second run. Reruns stay
byte-identical **while the five live inputs in the table below hold their current values**,
and a rerun that differs is evidence one of them moved, not that the log was mis-saved. The
three standards pages are no longer among them: since §5 reads the committed snapshots, their
contribution to the log is three fixed sha256 values.

| Volatile input | Current value | Where it is pinned for comparison |
|---|---|---|
| `rust-cli/anstyle` issue #192 state | `open` (printed as an `INFO` line, not asserted) | `review/evidence/anstyle-issue-192.json` |
| crates.io individual owners of `anstyle-query` / of `clap` | `epage` / `kbknapp` (asserted: `epage` present for `anstyle-query`, absent for `clap`) | `review/evidence/crates-io-anstyle-query-owners.json`, `review/evidence/crates-io-clap-owners.json` |
| newest non-yanked version of `anstream`, `anstyle`, `anstyle-query`, `colorchoice` | `1.0.0`, `1.0.14`, `1.1.5`, `1.0.5` | asserted, each marked `VOLATILE` in the log; the fetched documents are snapshotted as `review/evidence/crates-io-<crate>-versions.json` |
| the RustSec advisory lists for `anstream`, `anstyle`, `atty` | `RUSTSEC-2024-0404` / none (HTTP 404) / `RUSTSEC-2021-0145`, `RUSTSEC-2024-0375` | read live from `rustsec.org` and printed; a new advisory against any of the three changes the log and is a `re-verify` trigger |
| `zkat/supports-color` tag count | 15 | the assertion needs only `v3.0.2` to exist |

Everything else the log prints comes from immutable sources: git tags, `git show` at a commit
pin, and crates.io per-version fields for versions already published. **No download count and
no `pushed_at` value is printed**, because those move daily; the adoption and responsiveness
figures cited in the raws are carried with the raws' own retrieval dates (Codex 2026-09-05,
Opus 2026-09-10) and are not re-asserted here.

**Provenance of every source this decision reads, and what the weak ones cost.** Three
classes, and nothing sits outside them:

1. **Immutable, and all crate and repository source is here.** Both source repos at commit
   pins, and every upstream file at a release tag — thirteen distinct tags, each asserted to
   exist before any file is read from it; nine of the thirteen also carry `file:line`
   citations and so appear in the §10 ledger.
   **No crate source in this decision is read from a default branch.** The
   one raw report that disclosed such a read (the Opus raw on `zkat/supports-color`, "has no
   release tags, so its source was read from `main`") was refuted: the repository publishes 15
   tags including `v3.0.2`, and the claim was re-verified there. Cost: none, beyond the line
   numbers that had to be re-derived at tags (see `## Engines`).
2. **Unversioned but snapshotted, and read from the snapshot.** The three standards pages.
   Cost: the quotations are current as of 2026-09-10T16:10:03Z and no later, which is why a
   change to any of the three is a `re-verify` trigger and why the opt-in live re-read exists.
3. **Unversioned and read live, with no snapshot possible for the value asserted.** The
   RustSec advisory pages and the crates.io "newest non-yanked version" and owners lookups —
   each of these is a *current-state* question whose answer would be meaningless frozen. Cost:
   what the log records for them is true as of that run (2026-09-12) and can be falsified by
   upstream action at any time. They are the rows of the volatile table above, whose third
   column says for each row whether the log asserts the value or only prints it.

   One version-resolution gap is worth naming inside class 1: `is_terminal_polyfill` is read
   at tag `v1.70.2`, while `anstream` 1.0.0 declares `is_terminal_polyfill = "1.48"` and so
   resolves to whatever 1.x is current when a lockfile is written. The delegation-to-`std`
   claim is therefore established for `v1.70.2`, not for every version Cargo might resolve;
   P03's lockfile settles which one the template actually gets.

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
evidence both verified by the check: `no-color.org`'s FAQ — read from
`review/evidence/snapshot-no-color.org.txt`, not from the live page — states that user-level configuration
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
that "every first-party Rust CLI exposes the tri-state form". Verified at tags, `cargo`'s
`--color` flag is exactly tri-state and `clap`'s library enum has exactly three variants, but
`ripgrep` 15.2.0's `--color` accepts **four** values (`never | auto | always | ansi`). A second
correction, from the revision-1 audit's F4: of the three, only `cargo` and `ripgrep` are CLIs
with a surveyed `--color` flag — `clap` is the argument parser, and what was read is its
public API. The carried-through line therefore claims exactly that: the two surveyed CLIs take
a value rather than a boolean, and the parser's own enum is tri-state.

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
