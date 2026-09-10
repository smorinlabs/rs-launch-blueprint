# R65 — color-enablement-chain (bundle) — Opus raw report

All figures and claims were retrieved on **2026-09-10** unless a different date is
stated inline. Endpoints are named at each figure. Source repositories were read
through their programme pins: py `b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
ts `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`.

### Landscape

**Category.** This item decides a *policy resolution function plus an output-stream
adapter*: how a CLI turns four inputs (a command-line flag, a config-file value,
environment variables, and each stream's terminal-ness) into a single decision about
whether ANSI SGR escape sequences reach stdout and stderr, and where that decision is
applied. It is not a decision about which colours look nice, and it is not the same as
the decision about which crate renders a style.

**Three-bin map of the Rust field.**

| Bin | Candidates found | Basis for the bin |
|---|---|---|
| Built-in / first-party toolchain | `std::io::IsTerminal` (TTY primitive, stable since Rust 1.70.0, 2023-06-01); the pattern used by `cargo` itself (`--color <when>` → `anstream::ColorChoice` → one `AutoStream` per stream) | `IsTerminal` is in `std`; `cargo` is the Rust project's own CLI (`https://github.com/rust-lang/cargo`) |
| Established industry standard | `anstyle` 1.0.14 + `anstream` 1.0.0 + `anstyle-query` 1.1.5 + `colorchoice` 1.0.5 (one repo, `rust-cli/anstyle`); `termcolor` 1.4.1; `owo-colors` 4.4.0; `colored` 3.1.1; `yansi` 1.0.1; `console` 0.16.6; `supports-color` 3.0.2; `is-terminal` 0.4.17 | all above 15M 90-day downloads on `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`), 2026-09-10 |
| Up-and-comer | `anstyle-progress` 0.1.4 (anstream-compatible progress styling, 733,392 90-day downloads, first-party-adjacent: already a `rust-lang/cargo` dependency); `is_terminal_polyfill` 1.70.2 (MSRV shim that delegates to `std`) | `GET https://crates.io/api/v1/crates/anstyle-progress` and `/is_terminal_polyfill`, 2026-09-10 |
| Excluded from the map | `atty` 0.2.14 (two RustSec advisories); `concolor` 0.1.1 (archived 2023-07-03, superseded by `anstream` in the same `rust-cli` org) | `https://rustsec.org/packages/atty.html`; `GET https://api.github.com/repos/rust-cli/concolor` → `archived: true` |

**Authorities used, and why each is authoritative.**

1. **`no-color.org`** (retrieved 2026-09-10; page states "Last updated: 2026-09-04").
   The informal standard that every candidate crate cites by name. Authoritative because
   it is the document the implementations point at, not because it is popular. Two clauses
   are load-bearing here: NO_COLOR counts when "present and not an empty string (regardless
   of its value)"; and, from its FAQ, *"User-level configuration files and per-instance
   command-line arguments should override the NO_COLOR environment variable."*
2. **`force-color.org`** (retrieved 2026-09-10; page states "Last Updated: 2026-08-05").
   The counterpart standard for forcing colour on, proposed in 2023: "Command-line software
   which outputs colored text should check for a FORCE_COLOR environment variable. When this
   variable is present and not an empty string (regardless of its value), it should force the
   addition of ANSI color."
3. **`bixense.com/clicolors`** (retrieved 2026-09-10). The `CLICOLOR`/`CLICOLOR_FORCE`
   standard that the Rust crates actually implement. It now opens with: *"Note: This standard
   is deprecated. For new applications, we recommend using the force-color and no-color
   standards instead of this standard. Software that already supports this standard should
   treat FORCE_COLOR as an alias for CLICOLOR_FORCE."* This reverses the naive reading that
   `CLICOLOR_FORCE` is the modern Rust-side spelling and `FORCE_COLOR` the legacy Node one.
4. **`rust-lang/cargo` source** (`crates/cargo-util-terminal/src/shell.rs` and
   `src/context/mod.rs`, `master`, retrieved 2026-09-10). First-party toolchain practice,
   not a blog post: it is the reference implementation of a Rust CLI colour chain.
5. **`rust-cli/anstyle` maintainer statements** — issue #192 and its comments
   (`https://github.com/rust-cli/anstyle/issues/192`, opened 2024-06-02, still open on
   2026-09-10). Ed Page (`epage`, `author_association: COLLABORATOR` there, and a `clap` and
   `cargo` maintainer) explains why `FORCE_COLOR` is deliberately **not** built in:
   *"When I was weighing what to build-in, I was less interested in how wide spread something
   is about how consistently its expected to be implemented. People can always build their own
   thing on top but I didn't feel like arbitrating between parties arguing over 3 different
   implementations."* (comment 2024-06-04T02:23:48Z). This is a maintainer's own documentation
   of a design boundary, which is exactly the boundary this item must fill.
6. **CPython documentation, "Controlling color"**
   (`https://docs.python.org/3/using/cmdline.html`, retrieved 2026-09-10): "If the `NO_COLOR`
   environment variable is set, Python will disable all color in the output. This takes
   precedence over `FORCE_COLOR`." Authoritative for the *cross-ecosystem* question, because
   it is the reference interpreter's own rule and it settles the NO_COLOR-versus-FORCE_COLOR
   ordering the two web standards leave open.
7. **Rust release notes** (`https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md`,
   retrieved 2026-09-10): `std::io::IsTerminal` is listed under "Version 1.70.0 (2023-06-01)".

*Authority gap, stated rather than papered over:* the Rust CLI working group's book
(`rust-cli/book`, `master`, retrieved 2026-09-10) has no colour-gating chapter — `grep -i
color` over `src/tutorial/output.md` and `src/in-depth/human-communication.md` returns
nothing. The annual Rust survey publishes no crate-level question that would rank these
crates. So there is no WG-level or survey-level ruling to cite; the strongest available
authority is first-party toolchain source plus the two informal web standards.

**Practice evidence — well-regarded projects surveyed.**

| Project | What it uses | Evidence it is well regarded | Source |
|---|---|---|---|
| `cargo` | `anstream = "1.0.0"`, `anstyle = "1.0.14"`, `anstyle-progress = "0.1.0"` (`Cargo.toml:21-24`) | the Rust project's official build tool; 15,462 stars, pushed 2026-09-08T15:46:17Z (`GET https://api.github.com/repos/rust-lang/cargo`) | `https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml` |
| `clap` | `clap_builder` 4.6.6 declares `anstyle = "1.0.14"` and `anstream = "1.0.0"` behind its `color` feature (`clap_builder/Cargo.toml:38,64-65`) | 226,398,266 90-day downloads, 1,119,879,906 all-time (`GET https://crates.io/api/v1/crates/clap`); 16,697 stars | `https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/Cargo.toml` |
| `ripgrep` | `termcolor = "1.4.0"` (`Cargo.toml:66`) | 68,148 stars (`GET https://api.github.com/repos/BurntSushi/ripgrep`) | `https://raw.githubusercontent.com/BurntSushi/ripgrep/master/Cargo.toml` |
| `color-eyre` | `owo-colors` (`color-eyre/Cargo.toml:26`) | the standard pretty-error reporter for `eyre`; `owo-colors` has 1,387 reverse dependencies (`GET https://crates.io/api/v1/crates/owo-colors/reverse_dependencies`) | `https://raw.githubusercontent.com/eyre-rs/eyre/master/color-eyre/Cargo.toml` |
| `indicatif` / `console` family | `console` 0.16.6 does its own detection (`unsafe { libc::isatty(...) }`, `src/unix_term.rs:21`) | 2,224 reverse dependencies; 79,354,377 90-day downloads | `https://raw.githubusercontent.com/console-rs/console/main/src/unix_term.rs` |

**Fit filter.** The template is CLI + library + web service (spec §4 D7). That shape rules
things in and out before popularity does: the *library* crate must not put a rendering type
in its public API and must not mutate process-global state; the *CLI* must gate two streams
that carry different content (a styled result table on stdout, diagnostics on stderr); the
*web service* must not link a terminal-detection stack into a server binary that never writes
to a terminal. Every judgement below is made against that, not against "best in general".

### Principles and implementation

**Shared requirement, its source, and the level at which agreement is required.**

The principle both source repositories implement is: *the user, not the program, decides
whether ANSI colour appears, and the program resolves that decision exactly once, from an
ordered set of increasingly specific inputs, before any styled byte is written.* Its source
is the two informal standards (`no-color.org`, `force-color.org`) plus the source repos'
own decisions (py `R5.5`, recorded in the docstring at
`src/py_launch_blueprint/cli/context.py:188` at the pin; ts `D-018(2)`/`D-038` in
`docs/port/TS_PORT_DECISIONS.md`).

Agreement is required at the level of **capability and observable behaviour**, not at the
level of the variable names or the library. Concretely:

| Must agree across py, ts, rs | May justifiably vary by ecosystem |
|---|---|
| A per-invocation command-line flag is the most specific input and wins over everything else | The flag's spelling and arity (`--no-color` boolean versus `--color <when>` tri-state) |
| `NO_COLOR`, present and non-empty, disables colour when no more specific input speaks | Whether an *additional* vendor variable (`CLICOLOR`, `CARGO_TERM_COLOR`) is also read |
| Some environment variable can force colour on for a non-TTY destination (CI, `\| less -R`) | Whether that variable is spelled `FORCE_COLOR`, `CLICOLOR_FORCE`, or both |
| An explicit force-on input never beats an explicit disable that is more specific | The exact tie-break between two env vars set at once |
| The decision is resolved once, from injected inputs, and is deterministic under test | Whether the injected seam is a deps object (ts), a constructor argument (py), or a value passed to a stream adapter (rs) |
| Colour is decided per output stream, from that stream's own terminal-ness | Whether both streams are actually styled |

**Essential behaviours and observable acceptance criteria.** Given a program invocation:

1. `--no-color` (or `--color=never`) ⇒ no ESC `[` byte on either stream, whatever the
   environment says.
2. `--color=always` ⇒ SGR sequences on both streams even when both are pipes.
3. `NO_COLOR=1` with no flag and no config value ⇒ no SGR sequences.
4. `NO_COLOR=` (set, empty) ⇒ treated as unset (spec text: "present and not an empty string").
5. `FORCE_COLOR=1` (or `CLICOLOR_FORCE=1`) with no flag, no config, no `NO_COLOR`, both
   streams piped ⇒ SGR sequences on both streams.
6. `NO_COLOR=1` **and** `FORCE_COLOR=1` ⇒ no colour (CPython's rule; also `anstream`'s).
7. Both streams piped, nothing else set ⇒ no colour on either.
8. stdout piped, stderr a TTY, nothing else set ⇒ stderr coloured, **stdout not**.
9. `TERM=dumb` on a TTY ⇒ no colour.
10. The library crate exposes no function that reads the process environment or writes a
    global; a caller can construct a fully-determined renderer.

Criterion 8 is the one that separates the three candidate architectures, and it is the one
the ts shape cannot satisfy: ts computes a single boolean from `deps.stderrIsTTY`
(`src/router.ts:100` at the pin — `isTTY: deps.stderrIsTTY,`) and uses it everywhere. That
is harmless in ts because its stdout result document is never styled, but this template's
stdout **is** styled (F289; py's analogue is the `header_style="bold cyan"` table at
`src/py_launch_blueprint/cli/output.py:232` at the pin). Carrying the ts shape over would
colour a piped table whenever the user's stderr happened to be a terminal.

**Architectural alternatives, compared before any library is chosen.**

- **(A) Boolean gate plus conditional styling at each call site.** The ts shape
  (`colorEnabled(gate)` → `createColors(enabled)`), and in Rust `owo-colors`'
  `"text".if_supports_color(Stream::Stdout, |t| t.red())`. Every call site must remember to
  ask. Detection state lives in a process global (`owo_colors::set_override`, an `AtomicU8`
  in `src/overrides.rs`), scoped only by `with_override(enabled, closure)`.
  Cost: the gate is a cross-cutting concern smeared over every formatting site, and the
  global is hostile to `cargo test`'s in-process thread parallelism.
- **(B) Always emit ANSI into a stream adapter that strips when the destination cannot use
  it.** `anstream::AutoStream`: writing code is colour-blind, one object per stream holds the
  decision. This is what `cargo` and `clap` do. Cost: `StripStream` runs a small state-machine
  parser over every written byte when colour is off (`crates/anstream/src/adapter/strip.rs`),
  so the "no colour" path is the one that pays, not the coloured path.
- **(C) A console object that owns detection, styling, width, and paging together.**
  py's shape (`rich.Console`, two instances at `src/py_launch_blueprint/cli/output.py:144`
  at the pin), and in Rust the `console` crate. Cost: it couples this item's decision to R63
  (spinner) and R64 (pager) implementations, and `console` reaches detection through
  `unsafe { libc::isatty(out.as_raw_fd()) }` (`src/unix_term.rs:21`) rather than `std`.

**(B) is recommended.** It is the only one of the three that satisfies criterion 8 without
threading a second boolean through every call, it keeps the *library* crate's public API free
of any rendering type (`anstyle`'s own stated purpose: "An argument parser allowing callers to
define the colors used in the help-output without putting the text formatting crate in the
public API", `crates/anstyle/src/lib.rs`), and it is the pattern the toolchain itself ships.
Its cost is real but bounded and lands on the un-coloured path, which is also the path that
writes to a file or a pipe where throughput matters least in this template's workloads.

**The precedence order the Rust ecosystem actually implements.** Read from
`anstream` 1.0.0, `crates/anstream/src/auto.rs:197-222` (tag `anstream-v1.0.0`, retrieved
2026-09-10):

```
fn choice(raw: &dyn RawStream) -> ColorChoice {
    let choice = ColorChoice::global();          // 1. explicit override (flag/config tier)
    match choice {
        ColorChoice::Auto => {
            ...
            if anstyle_query::no_color() {       // 2. NO_COLOR, non-empty
                ColorChoice::Never
            } else if anstyle_query::clicolor_force() {   // 3. CLICOLOR_FORCE, non-empty
                ColorChoice::Always
            } else if clicolor_disabled {        // 4. CLICOLOR=0
                ColorChoice::Never
            } else if raw.is_terminal()          // 5. this stream's own TTY-ness
                && (anstyle_query::term_supports_color() || clicolor_enabled
                    || anstyle_query::is_ci())
            { ColorChoice::Always } else { ColorChoice::Never }
        }
        ColorChoice::AlwaysAnsi | ColorChoice::Always | ColorChoice::Never => choice,
    }
}
```

So the canonical Rust order is **explicit choice > `NO_COLOR` > `CLICOLOR_FORCE` > `CLICOLOR=0`
> per-stream TTY** — structurally the same four-tier shape as ts, with the force tier spelled
`CLICOLOR_FORCE` and the `NO_COLOR`-beats-force ordering already correct. `anstyle-query` 1.1.5
(`crates/anstyle-query/src/lib.rs`, retrieved 2026-09-10) reads `CLICOLOR`, `CLICOLOR_FORCE`,
`NO_COLOR`, `TERM`, `COLORTERM` and `CI` — and **not** `FORCE_COLOR`, by the maintainer's
explicit decision (issue #192, quoted above).

**Where the flag and config tiers come from.** `anstream` does not implement them; it reads
them from `colorchoice::ColorChoice::global()`, an `AtomicUsize` process global
(`crates/colorchoice/src/lib.rs:31-38`, tag `colorchoice-v1.0.5`). `cargo` deliberately does
not use that global: it resolves the tiers itself and passes the result in explicitly —
`AutoStream::new(std::io::stdout(), stdout_choice)` and the same for stderr
(`crates/cargo-util-terminal/src/shell.rs:53-54`), rebuilt on
`Shell::set_color_choice(Option<&str>)` (`shell.rs:247-263`), with the flag/config precedence
one line in `src/context/mod.rs:1207`:

```
let color = color.or_else(|| term.color.as_deref());   // --color flag > [term] color config
self.shell().set_color_choice(color)?;                 // then Auto defers to the env+TTY chain
```

That is the whole synthesis this item is asked about, already shipping in the toolchain:
**flag > config > `NO_COLOR` > force-env > `CLICOLOR=0` > per-stream TTY**. It contains py's
config layer *and* ts's force-env layer, with the flag on top of both.

**Where the recommended chain departs from py, and why.** py resolves
`--no-color > NO_COLOR > config` (`context.py:188-195` at the pin: `NO_COLOR` returns
`"never"` *before* `config_color` is consulted), so a user with `NO_COLOR=1` exported globally
cannot re-enable colour for this one program in its own config file. `no-color.org`'s FAQ says
the opposite is intended, and `cargo` implements the opposite. The recommended order therefore
puts an *explicit* config value (`always`/`never`) above `NO_COLOR`, while an absent or `auto`
config value falls through to the environment chain — which is exactly `cargo`'s behaviour and
costs nothing when the key is unset. This is the rationale for the follow-on py change; it is
not applied here, and F287's py-side row is not edited by this report.

**Where the recommended chain departs from `force-color.org`, and why.** That standard's own
C example applies `FORCE_COLOR` *after* "getopt(3) and/or config-file parsing", i.e. the env
var would beat an explicit `--no-color`. Both source repos, CPython, `anstream` and `cargo`
put the per-invocation flag first, and `no-color.org`'s FAQ states the general rule
("per-instance command-line arguments should override"). The flag wins here; the departure is
recorded rather than silently taken.

**`FORCE_COLOR` in a Rust template — justified difference or accidental drift?** Neither: it
is a capability that must be preserved and a spelling that must be *widened*. F288's capability
("an env var forces colour on despite a non-TTY destination") is satisfied for free by
`CLICOLOR_FORCE` through `anstream`. But `bixense.com/clicolors` — the very standard
`anstyle-query` implements — now tells implementers to "treat `FORCE_COLOR` as an alias for
`CLICOLOR_FORCE`", CPython 3.13 reads `FORCE_COLOR`, and the ts port already does. The
recommendation is therefore to read **both**, `FORCE_COLOR` in the template's own resolver and
`CLICOLOR_FORCE` via `anstream`, with `NO_COLOR` above both. F288 as recorded is preserved
literally, so no `BASELINE-REVIEW` is filed against it.

**BASELINE-REVIEW.** One inherited row is challenged, on capability grounds:

BASELINE-REVIEW: F286 — the user must be able to state colour policy per invocation, in both directions — keep the inherited boolean `--no-color` and add a tri-state `--color <auto|always|never>` alongside it, with `--no-color` defined as an alias for `--color=never` and an explicit conflict when both are given with opposite senses; affected items are F286 (row wording), R60 (`cli-parsing-framework`, which defines the global flag block) and R66 (`output-format-surface`, which shares that block) — evidence: a boolean flag can only turn colour off, so a user piping into `less -R` or writing a CI log has no per-invocation way to turn it on and must fall back to an environment variable; every first-party Rust CLI exposes the tri-state form (`cargo` parses `--color` as exactly `always|never|auto` at `crates/cargo-util-terminal/src/shell.rs:584-599`, `master`, 2026-09-10; `clap` ships `pub enum ColorChoice { Auto, Always, Never }` as a `ValueEnum` at `clap_builder/src/util/color.rs:6-57`, `master`, 2026-09-10; `ripgrep` declares `--color WHEN` defaulting to `auto` at `crates/core/flags/defs.rs:765-800`, `master`, 2026-09-10), and `anstream::ColorChoice` is itself tri-state, so a boolean-only surface discards a state the chosen stack already models; cost of declining: the force-on path exists only through `FORCE_COLOR`/`CLICOLOR_FORCE`, discoverable only from documentation.

**Minimal realistic example** (design sketch for P03 — *no code is being added to any repo by
this report*). One template-owned pure function plus two stream constructions:

```rust
// crates/<cli>/src/color.rs — the only hand-rolled part of the chain.
pub fn resolve_color(
    flag: Option<ColorWhen>,      // --color / --no-color, already parsed
    config: Option<ColorWhen>,    // config `color` key, None when absent or "auto"
    env: &dyn EnvSource,          // injected; production impl reads std::env
) -> anstream::ColorChoice {
    match flag.or(config) {                                   // 1 & 2
        Some(ColorWhen::Never)  => return anstream::ColorChoice::Never,
        Some(ColorWhen::Always) => return anstream::ColorChoice::Always,
        Some(ColorWhen::Auto) | None => {}
    }
    if env.non_empty("NO_COLOR") { return anstream::ColorChoice::Never; }   // 3
    if env.forces("FORCE_COLOR") { return anstream::ColorChoice::Always; }  // 4 (FORCE_COLOR only)
    anstream::ColorChoice::Auto      // 5+: hand to anstream: CLICOLOR_FORCE, CLICOLOR, per-stream TTY
}

// crates/<cli>/src/output.rs
let choice = resolve_color(flag, config, &env);
let mut out = anstream::AutoStream::new(std::io::stdout(), choice); // stdout decides for itself
let mut err = anstream::AutoStream::new(std::io::stderr(), choice); // so does stderr
```

`colorchoice::ColorChoice::write_global()` is never called: the decision travels as a value, so
the library crate stays free of process-global state and parallel tests cannot race. Styles come
from `anstyle` constants and are written unconditionally; `AutoStream` strips them when the
resolved choice for that stream is `Never`.

**How behaviour will be verified.** See `### Validation strategy`. Every check listed there is
**proposed**, not run: this is a research report and the Rust template does not exist yet.
The one thing actually executed for this report was reading the pinned py and ts sources and
the upstream Rust sources cited above.

### Recommendation

**One stack:** `anstyle` 1.0.14 (style vocabulary, and the only colour type allowed in the
library crate's public API) + `anstream` 1.0.0 with default features `auto` and `wincon`
(one `AutoStream` per output stream, constructed with an explicitly resolved
`anstream::ColorChoice`) + `anstyle-query` 1.1.5 and `colorchoice` 1.0.5 (arriving through
`anstream`'s `auto` feature; `anstyle-query`'s probes may be called directly, `colorchoice`'s
global is deliberately not written) + `std::io::IsTerminal` from the standard library as the
sole TTY primitive, reached through `anstream` and used directly wherever R63/R64 need a
terminal check + one template-owned pure function `resolve_color(flag, config, env) ->
anstream::ColorChoice` supplying the two tiers `anstream` does not implement (the flag/config
override and the `FORCE_COLOR` spelling).

**Resolved chain (F287), highest precedence first:**

1. `--no-color` / `--color <auto|always|never>` — per-invocation flag
2. config-file `color = "auto" | "always" | "never"` — explicit `always`/`never` only
3. `NO_COLOR`, present and non-empty → never
4. `FORCE_COLOR`, present and non-empty and not `"0"` → always (F288). The `"0"` carve-out is a
   second, deliberate departure from `force-color.org`, whose text says "present and not an empty
   string (regardless of its value)": it follows the ts port (`src/lib/colors.ts:34-37` at the pin)
   and `supports-color`'s `"false" => 0` mapping, whereas CPython checks mere presence
5. `CLICOLOR_FORCE`, present and non-empty → always (free, via `anstream`)
6. `CLICOLOR=0` → never (free, via `anstream`)
7. this stream's `is_terminal()` and `TERM != dumb` (or `CI` set) → always, else never

**F289:** gated **once, applied per stream**. One resolved `ColorChoice` value is computed per
process invocation and handed to both `AutoStream::new(stdout, choice)` and
`AutoStream::new(stderr, choice)`; when it is `Auto`, each stream independently consults its own
`is_terminal()`. This is neither py's "one gate forces both" nor ts's "stderr decides for
everyone" — it is `cargo`'s shape, and it is the only one that satisfies acceptance criterion 8.

**F290:** `std::io::IsTerminal` (stable since Rust 1.70.0). No `atty`, no `is-terminal` crate,
no `libc::isatty`. R63 and R64 take the same primitive. The testable seam is *value injection*,
not TTY mocking: `AutoStream::new(raw, choice)` takes the choice, and `resolve_color` takes an
injected environment source — the direct Rust analogue of ts's `ColorGate` object.

### Members

Four members, decomposed by **role in the chain**, not by candidate. Members 1-3 all live in
the single repository `https://github.com/rust-cli/anstyle`, so their repository-level figures
(stars, archived, pushed, open issues, issue responsiveness, CI matrix) are **one shared set**,
measured once and repeated in each member's field with that fact stated — they are not three
independent maintenance signals.

Shared repository figures for members 1-3, `rust-cli/anstyle`, retrieved 2026-09-10:
`GET https://api.github.com/repos/rust-cli/anstyle` → `stargazers_count` 170,
`archived` false, `pushed_at` 2026-09-07T23:13:32Z.
`GET https://api.github.com/search/issues?q=repo:rust-cli/anstyle+is:issue+is:open` →
`total_count` 15. Issue responsiveness over the 10 most recently opened issues
(#339, #337, #302, #300, #298, #291, #282, #279, #256, #241, via
`GET https://api.github.com/repos/rust-cli/anstyle/issues?state=all&sort=created&direction=desc`
plus each issue's `/comments`): 8 of 10 answered by a maintainer, **median 0.11 days**
(≈2.7 hours) to first maintainer response, 2 unanswered (#291 opened 2025-12-17, #241 opened
2025-01-20). CI (`.github/workflows/ci.yml`, `main`, retrieved 2026-09-10) runs the `test` job
on `os: ["ubuntu-latest", "windows-latest", "macos-latest"]` with `rust: ["stable"]`, plus a
separate `msrv` job. The star count (170) is low relative to the download figures because these
are infrastructure crates consumed transitively through `clap` and `cargo` rather than chosen
directly by application authors; downloads and first-party adoption are the meaningful signals
here, and the star count is reported rather than used.

#### anstyle (style vocabulary)

##### Landscape
Bin: established industry standard. The category is "a dependency-free vocabulary of ANSI
styles that crates can exchange without agreeing on a renderer". Alternatives in the same bin
that also render: `owo-colors` 4.4.0, `termcolor` 1.4.1, `colored` 3.1.1, `yansi` 1.0.1,
`nu-ansi-term` 0.50.3. `anstyle` is the only one whose stated purpose is interoperability
rather than rendering: "`anstyle` provides core types describing ANSI styling escape codes for
interoperability between crates… Priorities: 1. API stability 2. Low compile-time and
binary-size overhead 3. `const` friendly API"
(`https://raw.githubusercontent.com/rust-cli/anstyle/v1.0.14/crates/anstyle/src/lib.rs`,
retrieved 2026-09-10).

##### Principles and implementation
The principle this member carries is *the styling vocabulary must be separable from the
rendering decision*, so that the library crate can describe a style in its public API without
committing its consumers to a colour crate or a colour policy. `anstyle::Style` values are
`const`-constructible and carry no I/O and no environment access; they are written into a
stream unconditionally, and the stream decides whether they survive. This is what allows the
gate to exist in exactly one place. It is directly relevant to R04
(`public-api-surface-enforcement`): a `pub fn` returning `anstyle::Style` commits the template
to a 1.x type with an explicit stability priority, whereas returning an `owo_colors` or
`colored` type would export a renderer.

##### Dominant choice
`anstyle` 1.0.14. 90-day downloads 190,641,519; all-time 724,856,563
(`GET https://crates.io/api/v1/crates/anstyle` → `crate.recent_downloads`, `crate.downloads`,
2026-09-10). Newest non-yanked version 1.0.14, published 2026-03-13T18:59:28.450723Z
(`GET https://crates.io/api/v1/crates/anstyle/versions`). 519 reverse dependencies
(`GET https://crates.io/api/v1/crates/anstyle/reverse_dependencies` → `meta.total`).

##### Qualified shortlist
- `owo-colors` 4.4.0 — renderer, not a vocabulary; would appear in the public API. Kept on the
  shortlist only as the member-2 alternative (see below).
- `yansi` 1.0.1 — `MIT OR Apache-2.0`, `rust-version` 1.63, 52,582,028 90-day downloads, last
  release 2024-03-13T07:48:07.624195Z; a renderer with its own global `enable()`/`disable()`
  switch, so it merges the vocabulary and the gate rather than separating them.
- `nu-ansi-term` 0.50.3 — 129,553,340 90-day downloads, but its reach is `tracing-subscriber`,
  not CLI colour policy; it is a renderer with no gate.

##### Excluded by gate
- `colored` 3.1.1 — **fails gate 1**. `license` is `MPL-2.0`
  (`GET https://crates.io/api/v1/crates/colored/versions` → newest non-yanked `license`,
  2026-09-10), a file-level copyleft that is not compatible with a clean
  `MIT OR Apache-2.0`-only dependency posture for a template other people will copy. It is
  otherwise the most-depended-on candidate (6,631 reverse dependencies, 44,397,983 90-day
  downloads), which is why the gate has to be applied before popularity.

##### Up-and-comers
`anstyle-progress` 0.1.4 (733,392 90-day downloads, 893,272 all-time,
`GET https://crates.io/api/v1/crates/anstyle-progress`, 2026-09-10) extends the same vocabulary
to progress rendering and is already a `rust-lang/cargo` dependency (`Cargo.toml:24`). It is
named here only as evidence that the vocabulary is being extended, not as an R63 decision.

##### Fit for this template
CLI: styles for the text-mode result table and for diagnostics. Library: `anstyle::Style` is
the only colour type that may cross the public API. Web service: not linked — `anstyle` with
`default-features = false` is `no_std` and dependency-free, so even if a shared crate names the
type, the server binary pays nothing but a handful of `const`s.

##### Recommendation
Adopt `anstyle` 1.0.14 as a direct workspace dependency (not merely a transitive one through
`clap`), with `default = ["std"]` left on for the CLI crate.

##### Ranked runner-up
`yansi` 1.0.1 — same license, same MSRV posture, permissively licensed, but it owns a global
enable/disable switch, which would put a second gate in the process and re-create exactly the
duplication this item exists to prevent.

##### Tradeoffs
Gains: zero dependencies, zero `unsafe` (`grep -c unsafe` over
`crates/anstyle/src/lib.rs` at tag `v1.0.14` → 0), `const`-friendly, API-stable 1.x, already in
the dependency graph via `clap` and `cargo`. Costs: it renders nothing, so a second crate is
required to write bytes (that is member 2, by design); its `Style` type must be threaded to
call sites rather than reached through an extension trait, which is slightly more verbose than
`owo-colors`' `"text".red()`.

##### Parameters
`assumes license = MIT OR Apache-2.0` — satisfied: `license` = `MIT OR Apache-2.0`.
`assumes msrv-policy = stable minus 2 minor versions…` — satisfied: `rust-version` = `1.66.0`,
far below the current floor (latest stable is 1.98.1, published 2026-09-03T13:14:07Z per
`GET https://api.github.com/repos/rust-lang/rust/releases/latest`, so stable-minus-2 is 1.96).
`assumes rust-edition = 2024` — the crate is `edition = "2021"`; this constrains the crate's own
source, not its consumers, and a 2024-edition workspace may depend on it. `assumes
target-os-matrix = ubuntu-latest, macos-latest` — satisfied and exceeded (CI also runs Windows).
No `CONFLICT:` lines; this item consumes no researched parameter.

##### Migration implications
Adds `anstyle` to the workspace `[dependencies]`; introduces a small `styles` module of `const
Style` values so the palette is declared once; makes `anstyle::Style` an allowed type in the
library crate's public API surface (a fact R04's enforcement list must know).

##### Validation strategy
Proposed, not run: a `#[test]` asserting that the rendered form of each palette constant is the
expected SGR sequence, and a `cargo tree -i anstyle` check in CI asserting exactly one version
of `anstyle` in the graph (it is also pulled by `clap`, so a duplicate would double the
vocabulary).

##### Confidence & re-verify trigger
High. Re-verify if `anstyle` publishes a 2.0, if `clap` changes the `anstyle` major it depends
on, or if the template's library crate stops exposing styled output.

##### Sources
- `GET https://crates.io/api/v1/crates/anstyle` and `/versions` (2026-09-10)
- `GET https://crates.io/api/v1/crates/anstyle/reverse_dependencies` (2026-09-10)
- `GET https://api.github.com/repos/rust-cli/anstyle` (2026-09-10)
- `https://raw.githubusercontent.com/rust-cli/anstyle/v1.0.14/crates/anstyle/src/lib.rs` and `/Cargo.toml` (2026-09-10)
- `https://raw.githubusercontent.com/rust-cli/anstyle/main/.github/workflows/ci.yml` (2026-09-10)
- `https://crates.io/api/v1/crates/colored/versions`, `/yansi/versions`, `/nu-ansi-term` (2026-09-10)
- `https://rustsec.org/packages/anstyle.html` → HTTP 404, i.e. no advisories (2026-09-10)

#### anstream (adaptive per-stream writer)

##### Landscape
Bin: established industry standard, with first-party toolchain adoption. Category: "an
`io::Write` adapter that accepts ANSI escapes unconditionally and passes, strips, or translates
them according to a `ColorChoice`". Alternatives: `termcolor::StandardStream` (write-through
API where the caller calls `set_color()` before and `reset()` after), `console::Term` (a
console object that also owns width, cursor movement, and paging), and architecture (A) —
no stream adapter at all, with `owo-colors::if_supports_color` at each call site.

##### Principles and implementation
This member carries the principle *the decision is applied once, at the stream boundary, and
per stream*. `AutoStream::new(raw, choice)` stores the resolved choice; `AutoStream::choice()`
resolves `Auto` against `raw.is_terminal()` for that specific raw stream
(`crates/anstream/src/auto.rs:197-222`). Writing code therefore never asks whether colour is
on. It also carries the *deterministic-under-test* principle: `AutoStream::never(writer)` is how
`cargo` renders into a captured buffer with all formatting stripped
(`crates/cargo-util-terminal/src/shell.rs:71` — `ShellOut::Write(AutoStream::never(out))`), and
`anstream` ships a dedicated `test` feature described in its own manifest as "Enable in
`dev-dependencies` to make sure output is captured for tests"
(`crates/anstream/Cargo.toml`, tag `anstream-v1.0.0`).

##### Dominant choice
`anstream` 1.0.0. 90-day downloads 175,572,974; all-time 670,994,993
(`GET https://crates.io/api/v1/crates/anstream`, 2026-09-10). Newest non-yanked version 1.0.0,
published 2026-02-11T13:23:11.167553Z (`/versions`). 347 direct reverse dependencies
(`/reverse_dependencies` → `meta.total`) — an undercount of reach, since `clap_builder`'s
optional `color` feature puts it in most Rust CLIs' graphs.

##### Qualified shortlist
- `termcolor` 1.4.1 — 75,490,014 90-day downloads, 508,531,957 all-time, last release
  2024-01-10T12:40:32.427230Z, license `Unlicense OR MIT`, no `rust-version` field, 649 reverse
  dependencies, repo `BurntSushi/termcolor` 491 stars, `pushed_at` 2024-12-31T13:59:34Z, 5 open
  issues, median first maintainer response 0.07 days over the 10 most recent issues (8 of 10
  answered). Used by `ripgrep` (`Cargo.toml:66`). Maintenance state: **stable-quiet** — no
  release since 2024-01-10 and no push since 2024-12-31, but the crate is feature-complete, the
  author is active elsewhere, there is no advisory, and it builds on current stable; that is a
  trigger to investigate, not a verdict. Rejected on fit, not on health: its
  `set_color`/`reset` API is the opposite of colour-blind writing, so every call site handles
  the gate again.
- `console` 0.16.6 — architecturally shape (C). Its separate detection stack and its inverted
  `CLICOLOR_FORCE`-versus-`NO_COLOR` ordering are set out in `### Compatibility`, because the crate
  becomes relevant only if R63 selects `indicatif`.

##### Excluded by gate
None of the shortlist fails a gate. Recorded for completeness against **gate 3**: `anstream`
*has* a RustSec entry, `RUSTSEC-2024-0404`, "Unsoundness in anstream", type `INFO`/`unsound`,
reported 2024-09-08, issued 2024-12-04, **patched in `>=0.6.8`**
(`https://rustsec.org/advisories/RUSTSEC-2024-0404.html`, retrieved 2026-09-10). The
recommended 1.0.0 is far past the patch, so the gate passes; it is reported rather than omitted
because the affected function is exactly the one on the hot path here
(`anstream::adapter::strip_str`).

##### Up-and-comers
None displacing it. `concolor` 0.1.1 was the earlier attempt at this role from the same
organisation and is **archived** (`GET https://api.github.com/repos/rust-cli/concolor` →
`archived: true`, `pushed_at` 2023-07-03T17:05:27Z); its existence is evidence that the design
space was explored and converged, not that the area is unsettled.

##### Fit for this template
CLI: two `AutoStream`s, one per stream, exactly as `cargo` does. Library: **not used** — the
library crate returns data and `anstyle` styles; only the CLI binary constructs streams, which
keeps the library free of I/O policy (relevant to R01's ports-and-adapters seam). Web service:
not linked at all if the CLI crate is a separate workspace member; if the workspace is one
crate with features, `anstream` should sit behind the CLI feature so the server binary does not
carry a terminal-detection stack.

##### Recommendation
Adopt `anstream` 1.0.0 with default features (`auto`, `wincon`). Construct one `AutoStream` per
output stream with an explicitly resolved `ColorChoice`; never call
`colorchoice::ColorChoice::write_global()`. Enable the `test` feature in `[dev-dependencies]`.

##### Ranked runner-up
`termcolor` 1.4.1. Same platform coverage, longer track record, permissive license, zero
advisories, and it is what `ripgrep` uses — but its API forces every call site to bracket
styled text with `set_color`/`reset`, which re-scatters the concern, and it does not compose
with `clap`'s help colouring the way `anstyle`/`anstream` do.

##### Tradeoffs
Gains: colour-blind writing code; per-stream `Auto` for free; the `NO_COLOR`/`CLICOLOR_FORCE`/
`CLICOLOR`/`TERM`/`CI` chain for free; Windows console fallback behind the `wincon` default
feature; already in the graph via `clap`. Costs: when colour is off, `StripStream` runs a
`utf8parse`-driven state machine over every byte written
(`crates/anstream/src/adapter/strip.rs`), so redirected output pays a per-byte parse — the crate
ships `divan` benchmarks for exactly this (`[[bench]] name = "strip"`, `"stream"`, `"wincon"` in
`crates/anstream/Cargo.toml`), and no throughput number is quoted here because none was measured
on this template's workload. `unsafe` posture: **two `unsafe` blocks**, both in
`crates/anstream/src/adapter/strip.rs:136-155`, wrapping `str::from_utf8_unchecked` behind a
written safety justification and a `cfg!(debug_assertions)` checked path that panics instead of
constructing an invalid `&str` in debug builds; the workspace sets
`unsafe_op_in_unsafe_fn = "warn"` (`Cargo.toml`, `[workspace.lints.rust]`) and the crate carries
`proptest` in `[dev-dependencies]`. Async-runtime coupling: **none** — no `tokio`, `async-std`,
or futures dependency; the whole tree is synchronous `io::Write`.

##### Parameters
`assumes license = MIT OR Apache-2.0` — satisfied (`license` = `MIT OR Apache-2.0`).
`assumes msrv-policy = …` — satisfied: workspace `rust-version = "1.66.0"`, and its dependency
tree (`anstyle`, `anstyle-parse`, `colorchoice`, `anstyle-query`, `utf8parse`,
`is_terminal_polyfill`, plus `anstyle-wincon` on Windows only) is from the same workspace or is
equally conservative — no dependency raises the floor above 1.96.
`assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied and exceeded.
`assumes rust-edition = 2024` — the crate is `edition = "2021"`; consumers may be 2024.
Default features: `default = ["auto", "wincon"]`; `auto` is what pulls `anstyle-query` and hence
the env chain, so it must stay on. No `CONFLICT:` lines.

##### Migration implications
The CLI crate gains a `color` module (the resolver) and an `output` module that owns the two
`AutoStream`s; `println!`/`eprintln!` at styled call sites become writes into those streams
(`anstream` ships `print!`, `println!`, `eprint!`, `eprintln!` and `panic!` macro equivalents at
`crates/anstream/src/_macros.rs:61,130,184,235,334`, tag `anstream-v1.0.0`, retrieved 2026-09-10).
The web-service surface must not pick the dependency up: it sits behind the CLI feature.

##### Validation strategy
Proposed, not run: the ten acceptance criteria in `### Principles and implementation`, each as
a CLI integration test that runs the built binary with a controlled environment and asserts
presence or absence of `\x1b[` on each stream separately; plus a unit test that
`AutoStream::never(Vec::new())` yields byte-identical output to the same render with styling
removed. The test harness itself is R32's decision, not this item's.

##### Confidence & re-verify trigger
High. Re-verify if `anstream` publishes a 2.0, if `anstyle-query` gains built-in `FORCE_COLOR`
support (issue #192 would then let the template delete its own force tier), or if a new RustSec
advisory appears for `anstream` at 1.x.

##### Sources
- `GET https://crates.io/api/v1/crates/anstream`, `/versions`, `/reverse_dependencies` (2026-09-10)
- `https://raw.githubusercontent.com/rust-cli/anstyle/anstream-v1.0.0/crates/anstream/src/auto.rs` (2026-09-10)
- `https://raw.githubusercontent.com/rust-cli/anstyle/anstream-v1.0.0/crates/anstream/src/adapter/strip.rs` (2026-09-10)
- `https://raw.githubusercontent.com/rust-cli/anstyle/anstream-v1.0.0/crates/anstream/Cargo.toml` and root `Cargo.toml` (2026-09-10)
- `https://rustsec.org/packages/anstream.html`, `https://rustsec.org/advisories/RUSTSEC-2024-0404.html` (2026-09-10)
- `https://raw.githubusercontent.com/rust-lang/cargo/master/crates/cargo-util-terminal/src/shell.rs` (2026-09-10)
- `GET https://crates.io/api/v1/crates/termcolor`, `/versions`, `/reverse_dependencies`; `GET https://api.github.com/repos/BurntSushi/termcolor`; `GET https://api.github.com/search/issues?q=repo:BurntSushi/termcolor+is:issue+is:open` (2026-09-10)
- `GET https://api.github.com/repos/rust-cli/concolor` (2026-09-10)

#### anstyle-query + colorchoice (environment-precedence detection)

##### Landscape
Bin: established industry standard (same repository as members 1-2). Category: "probes that
answer one environment question each, plus a carrier for an explicit override". Alternatives:
`supports-color` 3.0.2 (one function that returns a `ColorLevel` after evaluating the whole
chain itself), `console`'s internal `default_colors_enabled` (same idea, private), and
hand-rolling every probe against `std::env`.

##### Principles and implementation
The principle is *precedence must be owned by the application, not by a library*, because only
the application knows about its own flag and its own config file. `anstyle-query` deliberately
supplies **probes, not a policy**: `clicolor() -> Option<bool>`, `clicolor_force() -> bool`,
`no_color() -> bool`, `term_supports_color() -> bool`, `truecolor() -> bool`, `is_ci() -> bool`
(`crates/anstyle-query/src/lib.rs`, tag `anstyle-query-v1.1.5`). `anstream` composes them into
the canonical order quoted in `### Principles and implementation`; `colorchoice` carries the
explicit override. The one policy decision `anstyle-query` does encode is the correct one:
`no_color()` and `clicolor_force()` both go through `fn non_empty(...)`, so `NO_COLOR=` (set,
empty) is treated as unset, exactly as `no-color.org` requires.

**`FORCE_COLOR` is the documented gap and the template must fill it.** `anstyle-query` 1.1.5
reads no `FORCE_COLOR` (verified by reading the whole 163-line `lib.rs`), and the maintainer's
position on issue #192 (opened 2024-06-02, still open 2026-09-10) is that this is deliberate:
*"People can always build their own thing on top but I didn't feel like arbitrating between
parties arguing over 3 different implementations."* So the template's own
`resolve_color(flag, config, env)` supplies tiers 1, 2 and 4 of the recommended chain, and
`anstream` supplies 5, 6 and 7. That is the direct answer to this item's second HIGH question:
**no Rust crate ships the full flag-then-config-then-env-then-env-then-TTY chain; roughly 30
lines are hand-rolled around `anstream`, and the hand-rolled part is precisely the part that
encodes this template's policy.**

**`colorchoice`'s global must not be written.** `ColorChoice::global()`/`write_global()` are
backed by one process-wide `AtomicUsize` (`crates/colorchoice/src/lib.rs:31-38,41`). Writing it
from a library is a hidden side effect, and writing it from tests makes `cargo test`'s
in-process thread parallelism order-dependent. `cargo` does not write it — it passes the value
into each `AutoStream` (`crates/cargo-util-terminal/src/shell.rs:53-54, 247-263`). The template
follows `cargo`.

##### Dominant choice
`anstyle-query` 1.1.5, 90-day downloads 165,496,617, all-time 641,470,988, newest non-yanked
version published 2025-11-13T17:30:22.615151Z; `colorchoice` 1.0.5, 90-day downloads
170,108,614, all-time 641,274,523, published 2026-03-13T18:59:29.020348Z
(`GET https://crates.io/api/v1/crates/<name>` and `/versions`, 2026-09-10). Both arrive
transitively through `anstream`'s default `auto` feature; `anstyle-query` may additionally be
named directly if the resolver wants `is_ci()`.

##### Qualified shortlist
- `supports-color` 3.0.2 — 15,353,504 90-day downloads, 64,361,449 all-time, last release
  2024-11-26T09:05:02.178227Z, license `Apache-2.0`, `rust-version` 1.70.0, 139 reverse
  dependencies; repo `zkat/supports-color` 54 stars, `pushed_at` 2024-11-26T09:05:07Z, 3 open
  issues; responsiveness over its 7 ever-opened issues: 3 answered, median 0.76 days, 4
  unanswered (#22, #17, #12, #3). Maintenance state **stable-quiet**. It is the only candidate
  that reads `FORCE_COLOR` natively, with Node's numeric levels
  (`"true" | "" => 1`, `"false" => 0`, else `min(parse, 3)`), and it returns a `ColorLevel`
  (16 / 256 / 16m) rather than a boolean, which is strictly more information than this item
  needs.
- Hand-rolling every probe against `std::env` — viable, and it is what the resolver does for
  two variables anyway; rejected for the other five because `anstyle-query` already arrives
  transitively and encodes the empty-string rule correctly.

##### Excluded by gate
- `atty` 0.2.14 — **fails gate 3**. `https://rustsec.org/packages/atty.html` (retrieved
  2026-09-10) lists two open advisories: `RUSTSEC-2021-0145` and `RUSTSEC-2024-0375`. Not used,
  not to be used; named because it is still the first hit in older CLI tutorials.
- `supports-color` 3.0.2 is **not** gate-excluded, but it is **architecturally excluded on
  correctness**: it evaluates `FORCE_COLOR` *above* `NO_COLOR` —
  `fn supports_color(stream) { let force_color = env_force_color(); if force_color > 0 { force_color } else if env_no_color() || … { 0 } … }`
  (`https://raw.githubusercontent.com/zkat/supports-color/main/src/lib.rs:90-96`, `main`
  branch, retrieved 2026-09-10; the repository's last push equals its 3.0.2 release date, so
  `main` and 3.0.2 are the same code). That inverts `no-color.org`, CPython 3.13, `anstream`,
  and the ts port, and it would break acceptance criterion 6. It also treats `NO_COLOR=0` as
  *not* disabling (`Ok("0") | Err(_) => false`), another spec deviation.

##### Up-and-comers
None. This is a settled corner: the current probes have been stable at 1.x since 2023 and the
only open design question is `FORCE_COLOR` (issue #192), which the template answers itself.

##### Fit for this template
CLI: the resolver reads `NO_COLOR` and `FORCE_COLOR` from an injected environment source and
lets `anstream` handle the rest. Library: no environment access at all — the library crate
never calls `std::env`, so the resolver lives in the CLI crate and the resolved value is passed
inward. Web service: `CLICOLOR_FORCE` and friends are irrelevant to a server, and nothing links
this member unless the CLI feature is on.

##### Recommendation
Take `anstyle-query` 1.1.5 and `colorchoice` 1.0.5 as they arrive through `anstream`'s `auto`
feature; call `anstyle_query` probes directly only if the resolver needs `is_ci()`; never call
`colorchoice::ColorChoice::write_global()`. Hand-roll exactly two probes — `NO_COLOR` and
`FORCE_COLOR` — inside `resolve_color`, using the `no-color.org` rule (present and non-empty)
for the former and the `force-color.org` rule plus the ts port's `"0"` carve-out for the latter.

##### Ranked runner-up
`supports-color` 3.0.2, used *only* as a `FORCE_COLOR` parser and never as the precedence
authority — i.e. take its `env_force_color()` semantics but keep the ordering local. Given the
parser is about ten lines, the dependency does not pay for itself, so the runner-up is really
"copy the semantics, cite the source".

##### Tradeoffs
Gains: no new direct dependency (both crates are already in the graph through `anstream` and
`clap`); the empty-string rule is handled correctly; precedence stays visible in one readable
function in the template rather than buried in a dependency. Costs: the template owns two env
probes and must test them, and it must document that `FORCE_COLOR` is honoured while
`anstyle-query` does not know about it (so a future `anstyle-query` release adding it could
create two force tiers — the re-verify trigger below). `unsafe` posture: `anstyle-query`'s `lib.rs`
has no `unsafe`; its `windows` module declares `mod windows_console` under `#[cfg(windows)]` and
makes `unsafe` Win32 console calls inside it (`crates/anstyle-query/src/windows.rs:3-12`, retrieved
2026-09-10), so that code is not compiled for `ubuntu-latest` or `macos-latest`. `colorchoice` is `#![cfg_attr(not(test), no_std)]` with no
`unsafe`. No async-runtime coupling in either.

##### Parameters
`assumes license = MIT OR Apache-2.0` — satisfied for both (`MIT OR Apache-2.0`).
`assumes msrv-policy = …` — satisfied: both declare `rust-version = "1.66.0"`.
`assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied by the shared CI matrix.
`assumes rust-edition = 2024` — both are `edition = "2021"`; consumers may be 2024.
Config-schema note for the LOW question: this item **names** one config key,
`color = "auto" | "always" | "never"`, and asserts nothing about how it is parsed or how a bad
value is reported. Defining the field's type, validation and error tolerance belongs to R53
(`config-schema-validation`) and R55 (`config-error-tolerance`). No researched parameter is
consumed, so there is no `CONFLICT:` line; R53/R55 need only know that a plain string enum with
those three variants exists.

##### Migration implications
Adds a `resolve_color` function and an `EnvSource` trait (or a `&HashMap<String, String>`
snapshot) to the CLI crate; adds the `color` key to the config struct that R53 owns; adds a
documentation section listing all six honoured environment variables.

##### Validation strategy
Proposed, not run: table-driven unit tests over `resolve_color`, one row per acceptance
criterion, with the environment injected rather than set — so no test mutates process
environment and the suite stays safe under `cargo test`'s default thread parallelism.
`std::env::set_var` is deliberately avoided (it is `unsafe` in edition 2024).

##### Confidence & re-verify trigger
High for the composition; medium for the `FORCE_COLOR` semantics, because the two web standards
disagree with each other about ordering and neither is normative. Re-verify when
`rust-cli/anstyle` issue #192 closes, when `force-color.org` next changes (its page reports
"Last Updated: 2026-08-05"), or if `bixense.com/clicolors` — already marked deprecated —
is withdrawn.

##### Sources
- `https://raw.githubusercontent.com/rust-cli/anstyle/anstyle-query-v1.1.5/crates/anstyle-query/src/lib.rs` (2026-09-10)
- `https://raw.githubusercontent.com/rust-cli/anstyle/colorchoice-v1.0.5/crates/colorchoice/src/lib.rs` (2026-09-10)
- `https://github.com/rust-cli/anstyle/issues/192` and its comments, via `GET https://api.github.com/repos/rust-cli/anstyle/issues/192[/comments]` (2026-09-10)
- `https://no-color.org/`, `https://force-color.org/`, `https://bixense.com/clicolors/` (2026-09-10)
- `https://docs.python.org/3/using/cmdline.html` §"Controlling color" (2026-09-10)
- `https://raw.githubusercontent.com/zkat/supports-color/main/src/lib.rs` (2026-09-10)
- `GET https://crates.io/api/v1/crates/anstyle-query`, `/colorchoice`, `/supports-color` and their `/versions` (2026-09-10)
- `https://rustsec.org/packages/atty.html` (2026-09-10)

#### std::io::IsTerminal (TTY primitive)

##### Landscape
Bin: **built-in / first-party toolchain**. Category: "the single question `is this file
descriptor or handle attached to a terminal?`". Alternatives: the `is-terminal` crate 0.4.17,
the `atty` crate 0.2.14, `libc::isatty` called directly (what `console` does), and
`is_terminal_polyfill` 1.70.2 (a shim for older MSRVs).

##### Principles and implementation
The principle is *one terminal question, one answer, one implementation* — so that colour
(F290), the spinner (R63) and the pager (R64) cannot disagree about whether the same stream is
a terminal. `std::io::IsTerminal` is a `std` trait implemented for `Stdout`, `Stderr`, `Stdin`,
`File` and the raw handle types; it was stabilised in **Rust 1.70.0 (2023-06-01)**
(`https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md`, the entry
`` `std::io::IsTerminal` `` under "Version 1.70.0"). The recommended stack already bottoms out
there: `anstream` depends on `is_terminal_polyfill = "1.48"`, whose implementation is a
one-line delegation — `fn is_terminal(&self) -> bool { std::io::IsTerminal::is_terminal(self) }`
(`https://raw.githubusercontent.com/polyfill-rs/is_terminal_polyfill/main-v1.70/src/lib.rs`) —
so on any rustc at or above 1.70 the polyfill is `std` under a different name and adds no
detection logic of its own.

This member also carries the *testability* principle, and it does so by **not** being mocked.
py mocks nothing and re-checks `console.file.isatty()` itself (`output.py:94-105` at the pin,
because `Console.is_terminal` is forced true by `color="always"`); ts injects
`stdoutIsTTY`/`stderrIsTTY` booleans on `CliDeps` (`src/router.ts:65-67` at the pin). The Rust
equivalent is neither a mock nor an injected boolean: the resolved `ColorChoice` is a *value*
passed to `AutoStream::new`, and the TTY question is answered **inside** `AutoStream`, separately
for each stream — it is not a parameter of the resolver, which runs once per invocation and
therefore cannot carry a per-stream answer. A unit test constructs streams with `Always`/`Never`
directly and never mocks a terminal; the TTY call itself is reached exactly twice in the whole
program, once per stream.

The consequence, stated plainly rather than glossed: the injected seam covers chain tiers 1-4
only. When `resolve_color` returns `ColorChoice::Auto`, `anstream`'s `choice()` reads the **real**
process environment (`CLICOLOR_FORCE`, `CLICOLOR`, `TERM`, `CI`, and `NO_COLOR` a second time) and
the real file descriptor, so tiers 5-7 are provable only end-to-end, with a real pipe and a real
pty. The double evaluation of `NO_COLOR` is harmless: the resolver returns `Never` before
`anstream` is ever asked, and `anstream` would reach the same answer if it were.

##### Dominant choice
`std::io::IsTerminal`, in the standard library. **Crate figures are `inapplicable`: this is a
`std` item, so there is no crates.io entry, no version, no download count, no repository star
count, no issue tracker of its own, and no RustSec page.** Its supply-chain risk, license and
maintenance state are those of the Rust toolchain itself. For the transitive shim,
`is_terminal_polyfill` 1.70.2 reports 154,855,373 90-day downloads and 520,282,458 all-time
(`GET https://crates.io/api/v1/crates/is_terminal_polyfill`, 2026-09-10);
`GET https://api.github.com/repos/polyfill-rs/is_terminal_polyfill` → 5 stars, `archived` false,
`pushed_at` 2025-10-21T17:10:38Z. The low star count is expected for a delegation shim and is
not a maintenance signal; it contains no logic to maintain.

##### Qualified shortlist
- `is-terminal` 0.4.17 — 56,209,450 90-day downloads, 333,527,101 all-time, last release
  2025-10-23T18:19:40.385809Z, license `MIT`, `rust-version` 1.63; repo `sunfishcode/is-terminal`
  53 stars, 0 open issues
  (`GET https://api.github.com/search/issues?q=repo:sunfishcode/is-terminal+is:issue+is:open`
  → `total_count` 0). Maintenance state **stable-quiet**. It is the pre-1.70 crate that `std`
  absorbed; adopting it now would add a dependency for something `std` provides.
- `libc::isatty` called directly — what `console` 0.16.6 does
  (`unsafe { libc::isatty(out.as_raw_fd()) != 0 }`, `src/unix_term.rs:21`). Requires `unsafe`
  and a `libc` dependency, and does not work on Windows without a second path.

##### Excluded by gate
- `atty` 0.2.14 — **fails gate 3**: two open advisories at
  `https://rustsec.org/packages/atty.html` (`RUSTSEC-2021-0145`, `RUSTSEC-2024-0375`), retrieved
  2026-09-10. Last release 2020-01-05T22:19:33.123499Z. Maintenance state **dormant** by the
  rubric (an unpatched advisory, not merely an old release).

##### Up-and-comers
None, and none wanted: this question moved into `std` in 2023 and the correct direction of
travel is fewer crates, not more.

##### Fit for this template
CLI: two calls, one per stream, made inside `AutoStream`. Library: never — the library crate
must not ask about terminals. Web service: never linked. R63 (spinner) and R64 (pager) reuse
the same `std` trait; the pager check in particular must be the *stream's own* `is_terminal()`
and not the colour decision, which is the distinction py drew explicitly at `output.py:94-99`
("`Console.is_terminal` is forced True by `color="always"` — right for styling, wrong for
paging"). That distinction survives here for free, because `ColorChoice::Always` and
`stdout().is_terminal()` are two separate values.

##### Recommendation
Use `std::io::IsTerminal`. Add no TTY-detection crate. Do **not** pass a TTY boolean into
`resolve_color`: it runs once per invocation and cannot carry a per-stream answer, so it returns
`ColorChoice::Auto` and each `AutoStream` asks its own stream. Expose one tiny helper in the CLI
crate, e.g. `fn stream_is_tty(s: &impl std::io::IsTerminal) -> bool`, for the *other* consumers of
F290 — R63's spinner and R64's pager — so those checks share one named call site.

##### Ranked runner-up
`is-terminal` 0.4.17 — identical behaviour, permissive license, healthy; it is the runner-up
only for a hypothetical MSRV below 1.70, which this template's policy (stable minus 2, i.e.
1.96 against today's 1.98.1 stable) can never reach.

##### Tradeoffs
Gains: zero dependency, zero `unsafe` in template code, identical semantics for colour, spinner
and pager, and the same Windows msys/cygwin pseudo-terminal heuristics everywhere. Costs: it is
a trait, so `use std::io::IsTerminal;` must be in scope at each call site; and it cannot be
mocked, which is why the TTY-dependent tiers of the chain are covered by end-to-end tests against
a real pipe and a real pty rather than by unit tests. Binary-size and
compile-time cost: nil (already in `std`). Async-runtime coupling: none. Default features:
`inapplicable` — a `std` item has none.

##### Parameters
`assumes msrv-policy = stable minus 2 minor versions…` — satisfied with a very wide margin:
required 1.70.0, current stable 1.98.1 (published 2026-09-03T13:14:07Z,
`GET https://api.github.com/repos/rust-lang/rust/releases/latest`), so the policy floor is 1.96.
`assumes license = MIT OR Apache-2.0` — satisfied: the standard library is `MIT OR Apache-2.0`.
`assumes rust-edition = 2024`, `assumes target-os-matrix = ubuntu-latest, macos-latest` —
satisfied; `IsTerminal` is implemented on every tier-1 platform. No `CONFLICT:` lines.

##### Migration implications
No dependency change. One helper function in the CLI crate, referenced by this item, R63 and
R64. A note in the contributor documentation that `atty` and `is-terminal` must not be added.

##### Validation strategy
Proposed, not run: a CI check (`cargo tree` or `cargo deny`) asserting that neither `atty` nor
`is-terminal` appears anywhere in the dependency graph, and that `is_terminal_polyfill` appears
at most once; plus an integration test asserting criterion 8 (stdout piped, stderr a TTY), which
is the only criterion that can distinguish a per-stream check from a shared one and therefore
requires a real pty for stderr — the pty harness itself is R32's decision.

##### Confidence & re-verify trigger
Very high. Re-verify only if the template's MSRV policy is ever pinned below 1.70 (impossible
under the current fixed parameter) or if `std`'s Windows pseudo-terminal heuristics change in a
way the release notes flag.

##### Sources
- `https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md`, "Version 1.70.0 (2023-06-01)" (2026-09-10)
- `https://doc.rust-lang.org/stable/std/io/trait.IsTerminal.html` (linked from the release notes, 2026-09-10)
- `https://raw.githubusercontent.com/polyfill-rs/is_terminal_polyfill/main-v1.70/src/lib.rs` (2026-09-10)
- `GET https://crates.io/api/v1/crates/is_terminal_polyfill`, `/is-terminal`, `/atty` and their `/versions` (2026-09-10)
- `GET https://api.github.com/repos/sunfishcode/is-terminal`, `/softprops/atty`, `/polyfill-rs/is_terminal_polyfill` (2026-09-10)
- `GET https://api.github.com/search/issues?q=repo:sunfishcode/is-terminal+is:issue+is:open` (2026-09-10)
- `https://rustsec.org/packages/atty.html` (2026-09-10)
- `https://raw.githubusercontent.com/console-rs/console/main/src/unix_term.rs` (2026-09-10)
- py `src/py_launch_blueprint/cli/output.py:94-105` at pin `b08bccfb`; ts `src/router.ts:65-67` at pin `cb1cbcb2`

### Compatibility

The four members are proven together three ways.

**1. Members 1-3 are one release unit.** `anstyle`, `anstream`, `anstyle-query` and
`colorchoice` are crates in the single Cargo workspace at
`https://github.com/rust-cli/anstyle`, sharing `license`, `edition` and `rust-version` from
`[workspace.package]` (root `Cargo.toml` at tag `anstream-v1.0.0`: `license = "MIT OR
Apache-2.0"`, `edition = "2021"`, `rust-version = "1.66.0"  # MSRV`) and one CI workflow that
tests them together on `ubuntu-latest`, `windows-latest` and `macos-latest`. `anstream`'s own
manifest pins its siblings by path and version (`anstyle = { version = "1.0.0" }`,
`colorchoice = { version = "1.0.0" }`, `anstyle-query = { version = "1.0.0", optional = true }`),
so a resolved graph cannot mix incompatible majors.

**2. A shared, first-party adopter at the exact versions recommended.**
`rust-lang/cargo` (`Cargo.toml:21-24`, `master`, retrieved 2026-09-10) declares
`anstream = "1.0.0"` and `anstyle = "1.0.14"` in its workspace dependency table and uses them
together in `crates/cargo-util-terminal/src/shell.rs`. `clap_builder` 4.6.6
(`clap_builder/Cargo.toml:38,64-65`) declares `anstyle = "1.0.14"` and, behind its `color`
feature, `anstream = "1.0.0"`. Since R60 (`cli-parsing-framework`) will almost certainly select
`clap`, choosing this stack means the template depends on crates it would already be linking —
one `anstyle` version in the graph, not two.

**3. Member 4 is what members 1-3 already use.** `anstream`'s manifest lists
`is_terminal_polyfill = "1.48"`, and that crate's entire implementation delegates to
`std::io::IsTerminal::is_terminal`. So `AutoStream`'s TTY tier and any direct
`stdout().is_terminal()` call in the template return the same answer from the same code — which
is the property F290 needs and the property R63 and R64 will rely on.

**Version matrix as recommended (all retrieved 2026-09-10):**

| Member | Crate / item | Version | Released | License | MSRV | Where it enters the graph |
|---|---|---|---|---|---|---|
| 1 | `anstyle` | 1.0.14 | 2026-03-13 | MIT OR Apache-2.0 | 1.66.0 | direct dependency; also via `clap` |
| 2 | `anstream` | 1.0.0 | 2026-02-11 | MIT OR Apache-2.0 | 1.66.0 | direct dependency (CLI crate / CLI feature) |
| 3 | `anstyle-query` | 1.1.5 | 2025-11-13 | MIT OR Apache-2.0 | 1.66.0 | transitive, via `anstream`'s default `auto` feature |
| 3 | `colorchoice` | 1.0.5 | 2026-03-13 | MIT OR Apache-2.0 | 1.66.0 | transitive, via `anstream` (its global is not written) |
| 4 | `std::io::IsTerminal` | Rust ≥ 1.70.0 | 2023-06-01 | MIT OR Apache-2.0 (toolchain) | 1.70.0 | standard library; also via `is_terminal_polyfill` 1.70.2 |

**Known incompatibility to hand to R63 and R64, not decided here.** If R63
(`progress-spinner`) selects `indicatif`, it brings `console` 0.16.6, which runs a *second,
differently-ordered* detection stack: it reaches the terminal through
`unsafe { libc::isatty(out.as_raw_fd()) }` (`src/unix_term.rs:21`) rather than `std`; it
computes `default_colors_enabled` as `(is_a_color_terminal(out) && CLICOLOR != "0") ||
CLICOLOR_FORCE != "0"` (`src/utils.rs:15-19`), which lets `CLICOLOR_FORCE` override `NO_COLOR`
— the opposite of `anstream`, CPython and `no-color.org`; and it checks `NO_COLOR` with
`env::var("NO_COLOR").is_ok()` (`src/unix_term.rs:30`), so `NO_COLOR=` (set, empty) disables
colour there while it is correctly ignored here. `console` does expose
`console::set_colors_enabled(bool)` and `set_colors_enabled_stderr(bool)` (`src/utils.rs:65-74`),
so the template can force its own decision onto that stack if R63 lands on it. The
anstream-native alternative that avoids the second stack entirely is `anstyle-progress` 0.1.4,
already a `cargo` dependency — offered to R63 as evidence, not as R63's answer.

### Parameters

`owns` — **none.** This item's `owns:` line in `## Couplings` is empty; F287, F288, F289 and
F290 are ledger rows, not registry parameters, and their values are stated in
`### Recommendation` rather than registered.

`assumes rust-edition = 2024` (fixed, owner, `docs/port/PARAMETERS.md`) — every recommended
crate is itself `edition = "2021"`, which constrains only its own source; a 2024-edition
workspace consumes them normally. One 2024-specific consequence is noted in the design:
`std::env::set_var` is `unsafe` in edition 2024, which is an additional reason the resolver
takes an injected environment source instead of tests mutating the process environment.

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared
as rust-version in Cargo.toml and tested in CI` (fixed, owner) — the current floor is **1.96**
(latest stable 1.98.1, published 2026-09-03T13:14:07Z per
`GET https://api.github.com/repos/rust-lang/rust/releases/latest`, retrieved 2026-09-10). Every
member is far below it: `anstyle`/`anstream`/`anstyle-query`/`colorchoice` at 1.66.0,
`is_terminal_polyfill` resolved at 1.70.2 (its `rust-version` field was not fetched; its floor is at
most 1.70 by construction, because its whole body delegates to `std::io::IsTerminal`), and
`std::io::IsTerminal` at 1.70.0. No member constrains the
floor, so this item never forces an MSRV bump.

`assumes license = MIT OR Apache-2.0` (fixed, owner) — every recommended member is
`MIT OR Apache-2.0`. The one candidate this excluded is `colored` 3.1.1 (`MPL-2.0`).

`assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed, owner) — satisfied and
exceeded; `rust-cli/anstyle` CI additionally runs `windows-latest`, and `anstream`'s `wincon`
default feature supplies the Windows console path even though Windows is not required.

No `CONFLICT:` lines. This item's `consumes:` line is empty, so no consumed parameter needs to
change. Two items are *informed* rather than constrained: R53/R55 gain the config key
`color = "auto" | "always" | "never"` as a plain string enum (this item names it; R53 defines
and validates it), and R63/R64 gain `std::io::IsTerminal` as the shared F290 mechanism.

### Migration implications

File-level changes in the template (P03 work, described here, not performed):

| File | Change |
|---|---|
| `Cargo.toml` (workspace) | add `anstyle = "1.0.14"` and `anstream = "1.0.0"` to `[workspace.dependencies]`; add `anstream = { version = "1.0.0", features = ["test"] }` to the CLI crate's `[dev-dependencies]` |
| `Cargo.toml` (CLI crate) | take both as dependencies; if the web surface shares a crate, put `anstream` behind the CLI feature so the server binary does not link a terminal stack |
| `crates/<cli>/src/color.rs` (new) | `enum ColorWhen { Auto, Always, Never }`, the `EnvSource` seam, and `resolve_color(flag, config, env) -> anstream::ColorChoice` implementing tiers 1-4 |
| `crates/<cli>/src/cli.rs` | the global flag block gains `--color <auto\|always\|never>` alongside the inherited `--no-color` (subject to the `BASELINE-REVIEW: F286` decision; if it is declined, only `--no-color` maps to tier 1) — coordinate with R60 and R66, which own that block |
| `crates/<cli>/src/output.rs` (new/changed) | construct `AutoStream::new(std::io::stdout(), choice)` and `AutoStream::new(std::io::stderr(), choice)`; every styled write goes through one of them; the text-mode result table writes `anstyle` styles unconditionally |
| `crates/<cli>/src/styles.rs` (new) | `const` `anstyle::Style` palette (error / warn / success / dim, matching ts's semantic vocabulary at `src/lib/colors.ts:40-46` at the pin) |
| `crates/<lib>/src/…` | unchanged except that `anstyle::Style` becomes an allowed public-API type; no `std::env` access, no stream construction, no global writes |
| config schema (R53's file) | one new key, `color`, string enum `auto\|always\|never`, default `auto` |
| `docs/` | a "Colour" section listing the seven tiers and the six honoured environment variables |
| CI | a `cargo tree` assertion that `atty` and `is-terminal` are absent and `anstyle` appears once |

### Validation strategy

All of the following are **proposed checks, not executed results.** Nothing in this report was
run against a Rust template, because none exists yet; the executed work was reading the pinned
`py`/`ts` sources and the upstream Rust sources cited throughout. The harness that hosts these
checks is R32's decision; the commands below are written for `cargo test` plus a shell-level
smoke script so they remain harness-agnostic.

1. **Unit-level, table-driven, no process-environment mutation.**
   `cargo test -p <cli> color::` over `resolve_color`, with a stub `EnvSource`. This can prove
   **only the tiers the resolver owns**: criteria 1, 2, 3, 4, 6, and the `FORCE_COLOR` half of 5.
   Criteria 7, 9 and the `CLICOLOR_FORCE` half of 5 fall outside it, because `resolve_color` returns
   `ColorChoice::Auto` and `anstream` then reads the real environment and the real descriptor;
   checks 3 and 4 below cover those. Expected: the tier-1-to-4 mapping in `### Recommendation`,
   including `NO_COLOR=""` → falls through, `FORCE_COLOR="0"` → falls through, `NO_COLOR=1` +
   `FORCE_COLOR=1` → `Never`.
2. **Stream-level.** `cargo test -p <cli> output::` asserting that
   `AutoStream::new(Vec::<u8>::new(), ColorChoice::Never)` receives styled writes and yields
   bytes containing no `0x1b`, and that the same writes with `ColorChoice::Always` yield the
   expected SGR sequences. Expected: byte-exact equality with the unstyled render in the first
   case.
3. **End-to-end per-stream (criterion 8, the one that distinguishes the architectures).**
   Run the built binary with stdout redirected to a file and stderr attached to a pty:
   `<bin> <cmd> > out.txt` under a pty harness. Expected: `out.txt` contains no `0x1b`; the
   captured stderr does. Then the reverse (stdout to a pty, stderr to a file). A single shared
   gate fails this test in one direction or the other; that is its purpose.
4. **End-to-end environment matrix.** A shell loop over the seven tiers —
   `NO_COLOR=1 <bin> …`, `FORCE_COLOR=1 <bin> … | cat`, `CLICOLOR_FORCE=1 <bin> … | cat`,
   `CLICOLOR=0 <bin> …`, `TERM=dumb <bin> …`, `<bin> --color=always … | cat`,
   `NO_COLOR=1 <bin> --color=always …` — each asserting presence or absence of `\x1b[` in the
   captured stream. Expected: flag beats env; `NO_COLOR` beats both force variables; both force
   variables beat a pipe.
5. **Config tier.** With `color = "always"` in the config file and `NO_COLOR=1` exported and
   output piped: expected colour **on** (the departure from py's order, deliberately asserted so
   the choice is visible in the test suite rather than only in this document).
6. **Graph hygiene.** `cargo tree -i anstyle` (expect exactly one version),
   `cargo tree -i atty` and `cargo tree -i is-terminal` (expect "package not found"), and
   `cargo deny check advisories` (expect no `RUSTSEC` finding for the colour stack; the historic
   `RUSTSEC-2024-0404` is patched at `>= 0.6.8` and the recommendation is 1.0.0).
7. **Cross-platform.** The whole suite on `ubuntu-latest` and `macos-latest` per
   `target-os-matrix`; the pty-based test 3 needs a pty allocation that works on both, which is
   the only part of this plan with a real portability risk and should be piloted early in P03.

### Confidence & re-verify trigger

**High** on the stack and on the per-stream shape: the recommendation is the architecture the
Rust toolchain itself ships, read from `cargo`'s and `anstream`'s current source rather than
from documentation about them, and every gate is satisfied with a wide margin.

**High** on `NO_COLOR` and TTY semantics: `no-color.org`'s empty-string rule and CPython's
`NO_COLOR`-beats-`FORCE_COLOR` rule agree with `anstream`'s implementation and with the ts port.

**Medium** on two points, both flagged rather than smoothed over:
(a) the ordering of the config tier *above* `NO_COLOR` follows `no-color.org`'s FAQ and `cargo`,
and contradicts py's implemented order — a reviewer may prefer to keep py's order for
cross-repo symmetry, in which case the only change is moving one `match` arm and the departure
note becomes moot;
(b) `FORCE_COLOR` versus `CLICOLOR_FORCE` is governed by two informal standards that disagree
about ordering relative to flags, and by a deprecated third; the recommendation to honour both
is the conservative reading, at the cost of two variables to document.

**Re-verify triggers:** `rust-cli/anstyle` issue #192 closing (built-in `FORCE_COLOR` would let
the template delete its own force tier); an `anstream` 2.0 or an `anstyle` 2.0; `clap` changing
the `anstyle` major it depends on; a new RustSec advisory against any member; `force-color.org`
or `no-color.org` changing (they report "Last Updated" 2026-08-05 and 2026-09-04 respectively);
R63 selecting `indicatif`/`console`, which activates the second-detection-stack caveat in
`### Compatibility`; R60 selecting a non-`clap` parser, which would remove the "already in the
graph" argument without changing the recommendation.

### Sources

**Standards and specifications**
- `https://no-color.org/` — NO_COLOR standard and FAQ (page states "Last updated: 2026-09-04"; retrieved 2026-09-10)
- `https://force-color.org/` — FORCE_COLOR standard (page states "Last Updated: 2026-08-05"; retrieved 2026-09-10)
- `https://bixense.com/clicolors/` — CLICOLOR / CLICOLOR_FORCE, now marked deprecated in favour of the two above (retrieved 2026-09-10)
- `https://docs.python.org/3/using/cmdline.html` §1.1.4 "Controlling color" (retrieved 2026-09-10)
- `https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md` — `std::io::IsTerminal` under "Version 1.70.0 (2023-06-01)" (retrieved 2026-09-10)
- `https://doc.rust-lang.org/stable/std/io/trait.IsTerminal.html` (retrieved 2026-09-10)

**Upstream source read directly (tag or branch stated)**
- `rust-cli/anstyle` @ `anstream-v1.0.0`: `crates/anstream/src/auto.rs`, `crates/anstream/src/adapter/strip.rs`, `crates/anstream/Cargo.toml`, root `Cargo.toml`
- `rust-cli/anstyle` @ `anstyle-query-v1.1.5`: `crates/anstyle-query/src/lib.rs`
- `rust-cli/anstyle` @ `colorchoice-v1.0.5`: `crates/colorchoice/src/lib.rs`
- `rust-cli/anstyle` @ `v1.0.14`: `crates/anstyle/src/lib.rs`, `crates/anstyle/Cargo.toml`
- `rust-cli/anstyle` @ `main`: `.github/workflows/ci.yml`
- `rust-lang/cargo` @ `master`: `Cargo.toml`, `crates/cargo-util-terminal/src/shell.rs`, `src/context/mod.rs`
- `clap-rs/clap` @ `master`: `clap_builder/Cargo.toml`
- `BurntSushi/ripgrep` @ `master`: `Cargo.toml`, `crates/core/flags/defs.rs`
- `eyre-rs/eyre` @ `master`: `color-eyre/Cargo.toml`
- `console-rs/console` @ `main`: `src/unix_term.rs`, `src/utils.rs`, `Cargo.toml`
- `owo-colors/owo-colors` @ `main`: `src/supports_colors.rs`, `src/overrides.rs`, `Cargo.toml`
- `zkat/supports-color` @ `main`: `src/lib.rs`
- `polyfill-rs/is_terminal_polyfill` @ `main-v1.70`: `src/lib.rs`
- `rust-cli/book` @ `master`: `src/tutorial/output.md`, `src/in-depth/human-communication.md` (searched; no colour-gating guidance found)

**Pinned source repositories (programme pins)**
- py @ `b08bccfb`: `src/py_launch_blueprint/cli/context.py:188-195` (`_resolve_color`), `src/py_launch_blueprint/cli/output.py:94-105` (`_isatty`), `:107-117` (`_console_color_args`), `:129-146` (two `Console`s), `:232` (`header_style="bold cyan"`)
- ts @ `cb1cbcb2`: `src/lib/colors.ts:1-38` (`colorEnabled`), `:40-57` (`createColors`), `src/router.ts:55-73` (`realDeps`), `:93-108` (`buildContext`, `isTTY: deps.stderrIsTTY`)

**Registry and repository endpoints (all retrieved 2026-09-10)**
- `GET https://crates.io/api/v1/crates/<name>` for `anstyle`, `anstream`, `anstyle-query`, `colorchoice`, `anstyle-progress`, `owo-colors`, `termcolor`, `colored`, `yansi`, `supports-color`, `is-terminal`, `atty`, `console`, `concolor`, `nu-ansi-term`, `is_terminal_polyfill`, `clap` — fields `crate.recent_downloads`, `crate.downloads`, `crate.max_stable_version`, `crate.updated_at`, `crate.repository`
- `GET https://crates.io/api/v1/crates/<name>/versions` — newest entry with `yanked: false`: `num`, `created_at`, `license`, `rust_version`, `edition`
- `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=1` → `meta.total`
- `GET https://api.github.com/repos/<o>/<r>` for `rust-cli/anstyle`, `owo-colors/owo-colors`, `BurntSushi/termcolor`, `mackwic/colored` (redirects to `colored-rs/colored`), `SergioBenitez/yansi`, `zkat/supports-color`, `sunfishcode/is-terminal`, `softprops/atty`, `console-rs/console`, `rust-cli/concolor`, `polyfill-rs/is_terminal_polyfill`, `rust-lang/cargo`, `clap-rs/clap`, `BurntSushi/ripgrep` — fields `stargazers_count`, `archived`, `pushed_at`
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count`: `rust-cli/anstyle` 15, `owo-colors/owo-colors` 16, `BurntSushi/termcolor` 5, `colored-rs/colored` 39, `SergioBenitez/yansi` 2, `zkat/supports-color` 3, `sunfishcode/is-terminal` 0, `softprops/atty` 15, `console-rs/console` 48
- `GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc` plus each issue's `/comments`, first comment whose `author_association` is `OWNER`/`MEMBER`/`COLLABORATOR` and whose author is not the issue opener — medians reported per member
- `GET https://api.github.com/repos/rust-lang/rust/releases/latest` → `tag_name` `1.98.1`, `published_at` 2026-09-03T13:14:07Z
- `https://rustsec.org/packages/<name>.html` for all fifteen crate candidates; HTTP 404 means no advisory page exists; hits: `anstream` (`RUSTSEC-2024-0404`, INFO/unsound, patched `>=0.6.8`) and `atty` (`RUSTSEC-2021-0145`, `RUSTSEC-2024-0375`)
- `GET https://api.github.com/repos/rust-cli/anstyle/issues/192` and `/comments`

**Method notes.** Every crate figure in this report came from
`GET https://crates.io/api/v1/crates/<name>` and `…/versions` with an explicit `User-Agent`
header; every repository figure from `GET https://api.github.com/repos/<o>/<r>`; every open-issue
count from `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`, never `open_issues_count`); every advisory check from
`https://rustsec.org/packages/<name>.html`; the latest stable Rust version from
`GET https://api.github.com/repos/rust-lang/rust/releases/latest`. Source claims were read from
`raw.githubusercontent.com` at a named tag wherever the crate's repository tags releases, and
from the default branch otherwise, with the branch stated. Both pinned source repositories were
read through `git show <pin>:<path>`, never from a working tree. **Endpoints that failed or
could not be verified:** (a) `https://rustsec.org/packages/<name>.html` returns HTTP 404 for
crates with no advisories — that is the API's shape, not a failure, and it is recorded as "no
advisories" only for the twelve crates queried; (b) `zkat/supports-color` has no release tags, so
its source was read from `main` — the repository's `pushed_at` (2024-11-26T09:05:07Z) equals its
3.0.2 publication timestamp, so `main` and 3.0.2 are believed identical, but that identity is
inferred, not proven by a tag; (c) `console`, `owo-colors`, `clap`, `cargo`, `ripgrep` and
`color-eyre` were likewise read from their default branches, so their figures describe current
`master`/`main` rather than the exact published version cited alongside; (d) issue-responsiveness
medians for `colored-rs/colored`, `SergioBenitez/yansi` and `softprops/atty` were **not**
sampled, because none of those crates is recommended or shortlisted on its merits (two are
excluded by gate, one is a rejected renderer); their open-issue counts are reported and their
medians are simply absent rather than estimated; (e) no performance number is quoted anywhere in
this report — `anstream` ships `divan` benchmarks for `strip`, `stream` and `wincon`, but none
was executed, so the runtime cost of `StripStream` is described qualitatively and stated as
unmeasured; the performance clause of the fitness gates is otherwise **inapplicable**, because
the colour gate resolves once per stream at process start and does not appear in any hot loop;
(f) the Rust CLI working group's book **was** searched for a colour-gating ruling and contains none
(`src/tutorial/output.md`, `src/in-depth/human-communication.md`, `master`, 2026-09-10); the annual
Rust survey was **not** consulted, because it publishes no crate-level ranking question that could
settle this choice. The absence of a working-group or survey ruling is recorded as an authority gap
rather than filled with a blog post.
