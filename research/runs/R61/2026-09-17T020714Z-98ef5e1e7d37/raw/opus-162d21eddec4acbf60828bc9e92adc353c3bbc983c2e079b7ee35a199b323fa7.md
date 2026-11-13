# R61 — interactive-prompts — raw report (Opus engine)

Actor `research-opus-2026-09-17T020714Z-98ef5e1e7d37`, model `claude-opus-5`, item
kind `bundle`, effort tier `focused`. No Rust code exists in this repository and
none was written; every design below is a *proposal for P03*, not an implemented
result.

**Retrieval date.** Every figure, source line and endpoint result in this report was
retrieved by this run on **2026-09-17 (UTC)** unless a different date is written on
the line. The host's local clock read 2026-09-16 during the run; the run identifier
`2026-09-17T020714Z` is the UTC instant and is the date used throughout.

**Licence gate.** Gate 1 is recorded as `inapplicable — owner ruling 2026-09-12
(Q7.B)` for every candidate. Declared licence strings are reproduced as observed
fact only; no candidate is excluded, preferred or ranked on licence.

**Standard pin.** The org CLI Design Standard **v1.4.14**, blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7` in `smorinlabs/cli-standards`, read this
run with `git -C /Users/stevemorin/c/cli-standards show f9de0437…`. Line numbers
below (`:456`, `:461`, …) are lines of that blob.

**Source-repository pins.** Python quotations are read through
`git -C ~/c/py-launch-blueprint show b08bccfb:<path>`; TypeScript quotations through
`git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>`. Every `py:`/`ts:` citation in
this report is at the pin, never at either working tree's HEAD.

---

### Landscape

**The category this item decides.** Not "a prompt library". The category is *how a
non-interactive-safe CLI obtains three classes of human input* — consent before a
mutation, a required value during setup, and a narrowing selection over data the
command already holds — such that the tool remains "fully usable without a TTY"
(R8.2 `MUST`, `:461`). The library is the small half of the decision; the gate in
front of it is the load-bearing half, and §*Principles and implementation* shows
why no crate in this field supplies that gate.

**Three-bin map of the Rust field.**

| Bin | Members found | Evidence |
|---|---|---|
| **Built-in / first-party toolchain** | `std::io::IsTerminal` (the TTY predicate) and `std::io::stdin().read_line()` (a line read) — **no prompt widget of any kind** | `IsTerminal` stabilized in **Rust 1.70.0 (2023-06-01)**, `rust-lang/rust` `RELEASES.md:3817` under the 1.70.0 section beginning `RELEASES.md:3732` (`https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md`). The Rust CLI working group's own book names **no** prompt crate: its search index contains zero occurrences of `dialoguer`, `inquire`, `requestty` or even the word `prompt` (`https://rust-cli.github.io/book/searchindex.json`, counted this run) |
| **Established industry standard** | `dialoguer` 0.12.0, `inquire` 0.9.4; terminal back-ends `console` 0.16.6 and `crossterm` 0.29.0 | figures in the member fields below; `blessed.rs` lists exactly one crate under the heading **"Interactive prompts"** — `inquire`, glossed "Ask for confirmation, selection, text input and more" (`https://blessed.rs/crates`). `dialoguer` does not appear on that page at all |
| **Up-and-comer** | `cliclack` 0.5.6, `demand` 2.1.0, `promkit` 0.17.0, `requestty` 0.6.3 | figures in `##### Up-and-comers` below |

The first bin's emptiness is the single most consequential landscape fact. There is
no `std`, no `rustup` component and no Rust-project-blessed prompt widget, so a
template that wants a multi-select **must** take a third-party dependency or write a
terminal state machine itself. That makes the *maintenance* and *swap cost* of the
chosen crate a first-order design input rather than a footnote, and it is why the
recommendation puts the crate behind a template-owned trait seam.

**Authorities used, and why each counts.**

| Source | Why authoritative | What it contributed |
|---|---|---|
| **The org CLI Design Standard v1.4.14** (pinned blob above) | Org-locked and binding on this port by owner ruling 2026-09-14 (recorded in `research/topics/60-cli-parsing-framework/DECISION.md`, "THE STANDARD PIN") | R8.1 (`:456`), R8.2 (`:461`), R8.5 (`:472`), R7.1 (`:381`), R7.3 (`:390`), R4.2 flag table (`:252-253`). These supply the *acceptance criteria*, not preferences |
| **`rust-lang/rust` `RELEASES.md`** | The Rust project's own release record | `IsTerminal` availability and its MSRV floor |
| **Rust CLI working group book** (`rust-cli.github.io/book`) | Working-group output, the closest thing to first-party CLI guidance | Establishes the *absence* of a blessed prompt crate (negative evidence, verified by index search, not by not-finding-it) |
| **`blessed.rs`** | Widely cited independent curation of recommended crates, organised by use case | The one-crate recommendation for the "Interactive prompts" use case |
| **Maintainers' own source** (crate tarballs, checksum-verified against crates.io) | Primary text; settles what an API can express | Every behavioural claim in this report about `inquire`, `dialoguer`, `cliclack`, `demand`, `console` and `crossterm` |
| **crates.io and GitHub REST** | The registries themselves | Every download, release, star, issue and PR figure |

A blog post was not used as an authority anywhere in this report.

**Well-regarded Rust projects surveyed, with the evidence that they are well
regarded** (stars from `GET https://api.github.com/repos/<o>/<r>`, this run;
dependency declarations from the named manifest):

| Project | Stars | Prompt crate declared | Evidence |
|---|---|---|---|
| `ast-grep/ast-grep` | 15,932 | **`inquire = "0.9.0"`** alongside `clap = { version = "4.5.4", features = ["derive"] }` and `clap_complete = "4.5.2"` | `https://raw.githubusercontent.com/ast-grep/ast-grep/main/crates/cli/Cargo.toml`, lines 38/46/54 |
| `bitwarden/clients` (publishes `bitwarden-cli`) | 13,792 | `inquire` (crates.io reverse-dependency listing) | `GET https://crates.io/api/v1/crates/inquire/reverse_dependencies` |
| `transact-rs/sqlx` (publishes `sqlx-cli`) | 17,501 | `dialoguer` | `GET https://crates.io/api/v1/crates/dialoguer/reverse_dependencies` |
| `tauri-apps/tauri` (publishes `tauri-cli`) | 111,123 | `dialoguer` | same endpoint |
| `wasm-bindgen/wasm-pack` | 7,283 | `dialoguer` | same endpoint |
| `axodotdev/cargo-dist` | 2,115 | `dialoguer` | same endpoint |

Reverse-dependency totals, same endpoints: **`inquire` 1,061**, **`dialoguer`
2,356**. Both are mainstream; `dialoguer` is the older and broader of the two, and
`inquire` is the one the newer curation recommends and the one the highest-profile
*newer* CLI in the survey (`ast-grep`) actually declares.

**Fit framing.** This template is CLI + library + web service. Only the **CLI binary
crate** may prompt: the library crate must be usable from the web surface, where
there is no terminal and no user, and R67's layering rule already forbids the
library crate from writing to a process stream. Every candidate below is therefore
judged as a *binary-crate-only* dependency, and "does it work headless" is judged by
what the **call site** does, not by what the crate does when called.

---

### Principles and implementation

**The shared requirement.** Across `py-launch-blueprint`, `ts-launch-blueprint` and
`rs-launch-blueprint`, the requirement is:

> A command that needs consent, a required value, or a narrowing choice asks a human
> for it **only when a human is demonstrably there**, asks on stderr, and behaves
> predictably and documentedly when a human is not there.

**Source and agreement level.**

| # | Principle | Agreement level | Must agree across py/ts/rs | May vary per ecosystem |
|---|---|---|---|---|
| P1 | A destructive action confirms, and offers a non-interactive bypass | **standard, one value for all three repos** — R8.1 `MUST` (`:456`); ledger F276/F278 | that a confirm exists, that `--yes`/`-y` is the consent bypass, and that under `--no-input` with no bypass the command **fails rather than guesses** (`:456`, final sentence) | which crate renders the y/n line; the wording |
| P2 | Prompts render on stderr; stdout carries only the requested result | **standard** — R7.1 (`:381`, "fd 2 (stderr) carries … prompts"), restated by R8.1 (`:456`) | that no prompt byte ever reaches stdout | whether the crate hard-wires stderr or accepts a stream handle |
| P3 | The tool is fully usable with no TTY, and never blocks on a prompt when input is unavailable | **standard** — R8.2 `MUST` (`:461`) | that a headless run terminates with a defined outcome, and that the outcome is exit `2` when *required non-auth input or consent* is missing | which predicate detects "no human" |
| P4 | An interactive setup flow has a non-interactive path and fails under `--no-input` | **standard** — R8.5 (`:472`) | that `config init` is reachable with flags alone, and refuses to prompt under `--no-input` | whether the flow is one prompt loop or several |
| P5 | Prompt cancellation is a defined outcome, not a panic or a stray exit code | **capability** — ledger F299, published in R67 as `RSLB903 → 130` | that Ctrl-C mid-prompt ends the process at 130 | whether the crate reports it as a typed value or as a signal |
| P6 | Selecting nothing is a graceful no-op, not an error | **capability** — ts `projects.ts:170-174` at the pin, exit 0 with a stderr notice | that an empty selection is success | the notice text |

What **must not** agree: the widget library, its key bindings, its theme, and the
concrete type each prompt returns. Those are ecosystem mechanics.

**Is the shared architectural pattern still appropriate in Rust?** The pattern ts
records is *prompt behind one injectable seam* — `Prompter` as a function type in
`ts: src/lib/adapters.ts:22` at the pin, with `realPrompter` at `:41` dynamically
importing `@inquirer/prompts` "so non-interactive runs never load the prompt stack".
Yes, and more so. Rust's analogue of that seam already exists as a decided
parameter: R01 fixed `http-transport-injection-seam` as a dyn-compatible trait
erased at the composition root. A `trait Prompter: Send + Sync` in the CLI crate,
with `InquirePrompter` as the production implementor and a scripted
`ScriptedPrompter` for tests, is the same shape one layer over. It buys three things
Rust specifically needs: the prompt crate never appears in the library crate's
dependency graph; the whole confirm/value/select surface is testable with no PTY;
and — given this category has no first-party option and its best candidates are
small third-party crates — **the crate choice becomes reversible at one file**, which
is the mitigation for the maintenance risk recorded against the recommended crate.

**Architectural alternatives, compared before libraries.**

| # | Architecture | What it gives | What it costs here |
|---|---|---|---|
| A | **No prompt dependency at all**: `--yes`/flags only; `config init` writes resolved defaults; the fetch command always emits every row | Zero dependency; trivially headless | Deletes F276, F279 and F280 outright. R8.1 *permits* a tool with no destructive command to skip confirming, but this template has `config set` overwriting an existing value (py `config.py:193-203`), so the confirm is required, not optional. Rejected |
| B | **Hand-rolled**: `stdin().read_line()` for confirm and value; no multi-select | No new crate; ~40 lines | Cannot express F280. A line-based read also cannot offer the in-place retry `click.prompt` gives. Rejected for the multi-select alone |
| C | **Split**: hand-rolled confirm/value + a crate for multi-select only | Smallest crate surface for two of three shapes | Two input models in one binary: raw-mode key events for the list, cooked line input for the rest, with two different cancellation stories. More code *and* a crate. Rejected |
| D | **One crate for all three shapes, called behind a template-owned trait seam, with the interactivity gate owned by the call site** | One input model; one cancellation story; one swap point; the gate is testable without a terminal | One dependency subtree. **Selected** |
| E | Same as D but with the gate delegated to the crate's own detection | Less template code | **This is the load-bearing rejection.** No crate in this field implements the gate this template needs — see immediately below |

**Why the gate cannot be delegated (the decisive finding of this run).** Every
serious candidate reads keys through a back-end that, when stdin is *not* a
terminal, **opens the controlling terminal directly**:

- `crossterm` 0.29.0 `src/terminal/sys/file_descriptor.rs:123-139`: `tty_fd()` uses
  `STDIN_FILENO` only `if isatty(STDIN_FILENO)`, else
  `OpenOptions::new().read(true).write(true).open("/dev/tty")?`. `enable_raw_mode()`
  is built on it (`src/terminal/sys/unix.rs:108-123`).
- `console` 0.16.6 `src/unix_term.rs:88-99`: `Input::unbuffered()` uses `io::stdin()`
  `if is_a_terminal(&stdin)`, else opens `/dev/tty`.

So `printf 'data' | rslbp config set k v < /dev/null` run from a terminal window
would, with no template-side gate, **prompt on the operator's terminal** — precisely
the behaviour R8.1 forbids: "Tools **SHOULD NOT** open `/dev/tty` or another
controlling terminal for surprise prompts when stdin is not a TTY" (`:456`).
`dialoguer` gets closest to a built-in guard — `src/prompts/multi_select.rs:204-205`
returns `io::ErrorKind::NotConnected` when `!term.is_term()` — but that tests the
**output** `Term` (stderr), not stdin, so the same pipe case slips through. The gate
is therefore the template's, in every candidate world. That makes it a **member of
this bundle**, not an implementation detail.

**The gate, stated once.** One predicate, three inputs, evaluated at the call site
before any prompt type is constructed:

```
interactive = !global.no_input
           && std::io::stdin().is_terminal()
           && std::io::stderr().is_terminal()
```

`stdin` because that is the fd R8.1 names ("when stdin is a TTY", `:456`) and the fd
whose non-TTY-ness triggers the `/dev/tty` fallback above. `stderr` because that is
where the prompt renders (R7.1, `:381`) and a prompt drawn into a redirected stderr
is a prompt nobody can answer. This is byte-for-byte the predicate ts already
computes — `ts: src/commands/projects.ts:146` at the pin,
`opts.input !== false && deps.stdinIsTTY && deps.stderrIsTTY` — so P3 is preserved at
the same level in both repos with the same three inputs. It is also the same
call-site-owns-the-gate architecture R63 selected for the spinner (design C, "the
crate renders; the application decides whether it renders at all"), which keeps one
rule in the template rather than two.

**Precedence, which settles the LOW question.** `--yes` is checked **before** the
gate, and the gate before the crate:

```
if global.yes            -> proceed, no prompt constructed          (F278 bypass)
else if !interactive     -> class rule below                        (F360)
else                     -> construct the prompt                    (F276/F279/F280)
```

`--dry-run` (F277) is evaluated by the command *after* consent is obtained, exactly as
py does (`py: src/py_launch_blueprint/cli/commands/config.py:180-183` renders the
`[dry-run] would set …` line and returns before any write). Neither flag needs a
bypass hook inside the prompt crate, and neither crate offers one; both are plain
booleans read before the call. This confirms the F278 baseline review of 2026-09-04
unchanged: py's `confirm()` returns `True` before touching `click.confirm`
(`py: src/py_launch_blueprint/cli/options.py:271-272`), and the Rust shape keeps that
independence. **No `BASELINE-REVIEW:` line is raised by this item.**

**F360 — one rule per prompt *class*, for all three repos.** py and ts disagree
(py raises `ConfigError` unless `--yes`; ts selects every fetched result) and the
divergence analysis marks this item `harmonize = partly`. The two behaviours are not
in conflict once the prompts are classified, because R8.2's `MUST` is scoped to
"required non-auth input **or consent**" (`:461`) and only two of the three prompts
carry either:

| Class | Example | Is it required input or consent? | Rule for py, ts and rs | Standard line |
|---|---|---|---|---|
| **Consent** | overwrite confirm before `config set` writes (F276) | consent, explicitly | **Refuse**: no mutation, exit `2`, `RSLB205`, hint "pass `--yes` to confirm non-interactively". `--yes` supplies the consent | R8.1 "Under `--no-input` with no required bypass flag, the command **MUST** fail rather than guess" (`:456`) |
| **Required value** | `config init` guided values (F279) | required input | **Refuse**: exit `2`, `RSLB205`, hint "pass `--yes` to write the current resolved defaults". `--yes` accepts the already-resolved values, which is py's own non-interactive path (`config.py:82-83`, `if assume_yes: chosen = current`; the `--no-input` refusal is `:84-88`) | R8.5 "Under `--no-input`, they **MUST** fail rather than prompt" (`:472`) |
| **Narrowing** | multi-select over already-fetched projects (F280) | **neither** — the command has the data and would otherwise print all of it; the prompt only subsets the output | **Proceed with all results**, emit them, exit `0` | R8.2's obligation is not engaged; R8.2's own framing is "it uses provided flags/env **or fails**" for *missing* input (`:461`), and here nothing is missing |

So the single cross-repo rule is: **refuse when the missing answer is consent or a
required value; proceed with the complete, unnarrowed result when the missing answer
only narrows output.** py implements the first two and has no third; ts implements
the third and has no first two. Neither repo is wrong today and neither needs to
change to satisfy this rule — which is the strongest possible outcome for a
`harmonize = partly` item. rs is the only repo that ships all three, so rs is where
the rule becomes visible; propagating the wording (not a behaviour change) to py's
and ts's docs is the follow-on project.

**The `--no-input` flag itself.** R4.2's global table lists `--no-input` with no
short flag, "Never prompt; fail if input would be required" (`:253`, repeated
`:609`). R60 fixed the mechanism for every global — one `#[derive(Args)] struct
GlobalArgs`, `#[command(flatten)]`-ed at the root with `global = true` (F270) — so
`--no-input` is a field of that struct and reaches the gate the same way `--quiet`
reaches R63's spinner predicate. **This item declares no new flag**: `--no-input` is
ledger row **F275, verdict `COMMON → REUSE`** — "the `--no-input` flag exists on
both" (`docs/port/COMMONALITY.md:279`) — already decided and assigned to no research
item, with only the behavioural fork under it (F360) split out to R61. This item
consumes that field. Where `### Migration implications` lists a `no_input` field on
`GlobalArgs`, that is F275's existing flag taking its place in R60's struct, not a
new flag introduced here.

**OVERRIDE (OV-01) — a declined confirm exits `0` in rs, where py exits `5`.**

**Argument:** py maps a refused overwrite to `SystemExit(int(ExitCode.INTERRUPT))`
with `ExitCode.INTERRUPT = 5` and error code `PLBP004`
(`py: src/py_launch_blueprint/cli/commands/config.py:200-203`;
`py: src/py_launch_blueprint/core/errors.py:45,55`). rs cannot copy the value: R67's
taxonomy assigns `5` to *conflict/precondition failed*, so reusing it would label a
user's deliberate "no" as a precondition failure. R67's catalogue has no row for a
declined prompt and this item may not add one. The standard is silent: R8.1 requires
the confirm to exist and to be bypassable, and says nothing about the refusal's exit
code. The template's own precedent points to `0`: ts treats the analogous "user
selected nothing" as success with a stderr notice and no error
(`ts: src/commands/projects.ts:170-174`). A refusal is the confirm working as
designed; stdout stays byte-empty, the mutation does not happen, a stderr notice says
so, and a script that wants to know whether the write happened asks for the write's
own output rather than reading a failure code.

**Options:**
- (a) **exit `0` with a stderr notice** — chosen. No new R67 row; consistent with
  ts's empty-selection rule; a refusal is not an error.
- (b) exit `1` (`RSLB000`/generic) — makes "the user said no" indistinguishable from
  "something broke". Rejected.
- (c) exit `5` (`RSLB501`) to match py's integer — reuses a code whose published
  meaning is "conflict/precondition failed". Rejected; it would corrupt R67's
  taxonomy to preserve a coincidence of digits.
- (d) add a new R67 row for "declined" — out of scope for this item, and would be a
  `CONFLICT:` escalation. Not needed, because (a) requires no row.

Cost if wrong: one match arm and one documented line; no code, no catalogue change.

**Mapping every prompt outcome onto R67's published catalogue.** Every failure this
item can produce is expressible with an existing row, so **this item raises no
`CONFLICT:` line.**

| Outcome at the call site | R67 row | Exit | Why that row |
|---|---|---|---|
| Gate false (`--no-input`, or stdin/stderr not a TTY) and no `--yes`, for the consent or required-value class | `RSLB205` | 2 | R67's `RSLB205` is worded "required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin" — all three of this item's triggers, verbatim |
| Gate false, narrowing class | — | 0 | Success path; no error row is used |
| `Err(InquireError::NotTTY)` (raw mode refused; `ENOTTY`/`ENXIO`) | `RSLB205` | 2 | Same condition reached one layer later; the gate should normally have caught it, so this arm is defence in depth. **Class-scoped like the gate itself**: for the consent and required-value classes it is `RSLB205`/2, and for the **narrowing** class it falls back to the complete result and exit `0`, so the two paths cannot disagree about the same command |
| `Err(InquireError::OperationInterrupted)` (Ctrl-C) | `RSLB903` | 130 | R67 defines `RSLB903` "prompt interrupted by Ctrl-C → 130" and requires the crate be adapted to it "without leaking the crate's own error text" |
| `Ok(None)` from `prompt_skippable` (ESC) or `Ok(false)` from `Confirm` | — | 0 | OV-01 above; stderr notice, no mutation. On the **narrowing** prompt an ESC is treated exactly like an empty selection: notice on stderr, nothing on stdout, exit `0` |
| `Err(InquireError::OperationCanceled)` (ESC reaching a plain `prompt()`) | — | 0 | Same outcome as the row above. **Every** call site in this design uses `prompt_skippable()`, so this arm should be unreachable; it is written anyway so the `InquirePrompter` match is exhaustive over `InquireError` and a future non-skippable call cannot fall through to `RSLB000` |
| `Ok(vec![])` from `MultiSelect` | — | 0 | P6; ts parity |
| `Err(InquireError::IO(e))` | `RSLB101` | 1 | Ordinary I/O failure |
| `Err(InquireError::InvalidConfiguration(_))` / `Err(Custom(_))` | `RSLB000` | 1 | Programmer error; the unexpected sentinel |

R67 also rules that "No prompt-local Ctrl-C handler may be installed — it would race
the process-level contract". The recommended combination satisfies this by
construction: `inquire` installs no signal handler; with the `crossterm` back-end the
terminal is in raw mode, so `ISIG` is off, no `SIGINT` is generated at all, and
`^C` arrives as an ordinary key event that the prompt loop converts to a typed
value — `src/prompts/prompt.rs:153`, `Action::Interrupt => return
Err(InquireError::OperationInterrupted)`. **This rule is what excludes `demand`** (see
`##### Excluded by gate`), which registers a real `SIGINT` handler per prompt.

**ESC and Ctrl-C must stay distinguishable.** R67 calls this "a product question for
R61", and this item answers it: they are different outcomes (`0` versus `130`), so a
crate that collapses them cannot serve. `inquire` separates them at
`src/prompts/prompt.rs:141-153` (`Action::Cancel` → `OperationCanceled`;
`Action::Interrupt` → `OperationInterrupted`) and offers `prompt_skippable()` which
converts the ESC case to `Ok(None)` rather than an error
(`src/prompts/confirm/mod.rs:205-213`). This requirement is what excludes `cliclack`.

**Colour, and the R65 coupling.** `inquire`'s `RenderConfig::default()` consults one
variable and nothing else: `match env::var("NO_COLOR") { Ok(_) => Self::empty(),
Err(_) => Self::default_colored() }` (`src/ui/api/render_config.rs:351-356`). R65
resolved a **multi-tier** chain for this template, so letting `inquire` decide would
put a second, shorter colour policy in the binary. The template must therefore pass
an explicit config — `RenderConfig::empty()` when R65's resolved answer is "no
colour", `RenderConfig::default_colored()` when it is "colour"
(`src/ui/api/render_config.rs:166,200`) — through
`with_render_config`. `inquire`'s own docs state the consequence of doing so
("When overriding the config in a prompt, NO_COLOR is no longer considered",
`src/prompts/password/mod.rs:126-128`), which is exactly the intent: R65's chain
already accounts for `NO_COLOR`. This is a design note, not a `CONFLICT:`; R65's
parameter value is unchanged and unconsulted by this item.

**Minimal realistic example** (proposed for P03; no code exists):

```
crates/cli/src/prompt.rs     trait Prompter { confirm, value, choose, select_many }
                             struct InquirePrompter;   // the only file naming `inquire`
                             struct ScriptedPrompter;  // test double, no terminal
crates/cli/src/interactive.rs  fn interactive(g:&GlobalArgs)->bool  // the gate
crates/cli/src/commands/config.rs  init/set call sites
crates/cli/src/commands/project.rs fetch → select_many call site
```

`ProjectChoice(Project)` implements `Display` as `"{name} ({workspace})"`, which is
how ts's `Choice{name,value}` pair is expressed in Rust: the *name* is the `Display`
rendering and the *value* is the wrapped domain object that
`MultiSelect::prompt()` hands straight back.

**Observable acceptance criteria** (A1–A9 are the contract; `## Validation strategy`
says which are proposed and which were run):

1. `rslbp config set k v2 < /dev/null` from a terminal, with `k` already set to `v1`:
   **no prompt appears on the controlling terminal**, exit `2`, stderr carries the
   `RSLB205` envelope, `k` still equals `v1`.
2. Same command with `--no-input`: exit `2`, `RSLB205`, no write.
3. Same command with `--yes`: exit `0`, `k == v2`, **no prompt constructed**.
4. Same command with `--dry-run --yes`: exit `0`, `[dry-run] would set …` on stderr,
   `k` unchanged.
5. `config init --no-input`: exit `2`, `RSLB205`. `config init --yes`: exit `0`,
   file written from resolved defaults, no prompt.
6. `rslbp project list --no-input -o json > out.json`: exit `0`, **every** fetched
   row present in `out.json`, `out.json` contains no prompt bytes.
7. On a PTY, answering `n` to the overwrite confirm: exit `0`, `Aborted.` on stderr,
   stdout byte-empty, no write.
8. On a PTY, `^C` during the multi-select: exit `130`, stderr carries the `RSLB903`
   envelope and **no `inquire` error text**.
9. On a PTY with stdout redirected to a file, any prompt: the file receives zero
   prompt bytes (R7.1).

---

### Recommendation

**One stack.** Adopt one interactive-prompt crate, in the CLI binary crate only,
behind a template-owned `Prompter` trait, with the interactivity gate owned by the
call site:

| Role | Selection | Where it goes |
|---|---|---|
| Prompt widgets (confirm · value · single choice · multi-select) | **`inquire = { version = "0.9.4", default-features = false, features = ["crossterm", "macros"] }`** | CLI binary crate only |
| Terminal back-end and typed `^C` | **`crossterm 0.29.0`**, selected through `inquire`'s `crossterm` feature — never a direct dependency | transitive, pinned by `inquire` |
| Interactivity gate | **`std::io::IsTerminal`** — no crate | CLI binary crate |
| Swap point | a template-owned `trait Prompter` with `InquirePrompter` / `ScriptedPrompter` | CLI binary crate |

Prompt shapes:

| Ledger row | Shape | `inquire` type | Call |
|---|---|---|---|
| F276 | yes/no confirm before a destructive write | `Confirm` | `Confirm::new(msg).with_default(false).prompt_skippable()` |
| F279 | guided free value, `config init` | `Text` (free string) · `CustomType<T>` (value that must parse) | `.with_default(current).with_validator(…).prompt_skippable()` |
| F279 | guided value **with a closed set** — py's `click.Choice` branch | `Select` | `Select::new(key, allowed).prompt_skippable()` |
| F280 | multi-select over fetched results | `MultiSelect` | `MultiSelect::new(msg, choices).prompt_skippable()` — **`prompt_skippable`, not `prompt`**, so ESC returns `Ok(None)` instead of `Err(OperationCanceled)`. `Ok(None)` (backed out) and `Ok(Some(vec![]))` (submitted with nothing ticked) are treated identically: stderr notice, no result on stdout, exit `0`. All four shapes use the skippable form for this reason |

`default-features = false` is deliberate and drops two of `inquire`'s four defaults.
`fuzzy` pulls `fuzzy-matcher`, whose newest non-yanked release is **0.3.7,
2020-10-04** (`GET https://crates.io/api/v1/crates/fuzzy-matcher/versions`) — six
years without a release, for a filter this template does not need. Turning it off is
free rather than lossy: `inquire` compiles a substring `DEFAULT_SCORER` in its place
(`src/prompts/multiselect/mod.rs:187-194`, `string_value.to_lowercase().contains(&filter)`).
`one-liners` is dropped because the template calls the builder API, not the
free-function shortcuts (`src/prompts/mod.rs:25`). `macros` is kept: it carries the
`macro_rules!` helpers the guided-value prompt uses — read at their definitions
rather than inferred from the `cfg` line: `required!` (`src/validator.rs:364-372`)
and the `parse_type!` family (`src/parser.rs:70-80`), each `#[macro_export]`ed under
`#[cfg(feature = "macros")]` (further gates at `src/validator.rs:471,580,686`). `crossterm` is kept and is the whole point —
see `#### crossterm`.

**Why a crate at all, restated in one line:** F280 is a multi-select over a fetched
list; no `std` primitive can render one, and architecture B/C above cost more code
than D while delivering less.

---

### Members

#### inquire

##### Landscape

Bin: **established industry standard**. `inquire` is the only crate `blessed.rs`
lists under "Interactive prompts" (`https://blessed.rs/crates`), and the only
candidate declared by a top-tier *newer* Rust CLI in this survey
(`ast-grep/ast-grep`, 15,932 stars, `crates/cli/Cargo.toml:46`, `inquire = "0.9.0"`).
Its peers in the bin are `dialoguer` (older, broader adoption) and, one layer down,
the back-ends `console` and `crossterm`.

##### Principles and implementation

`inquire` realises P2 by construction and P5 by type. **P2**: its `crossterm`
back-end writes to `stderr` and to nothing else — `src/terminal/crossterm.rs:2`
imports `Stderr`, `:97` constructs `IO::Std(stderr())`, `:91` and `:237` execute
bracketed-paste toggles against `stderr()`. A repository-wide grep of
`inquire-0.9.4/src` for `stdout` returns **zero matches**, so there is no
configuration under which a prompt byte reaches fd 1. That is stronger than the
"explicit output-stream override" the prompt's HIGH question asks for: ts needed
`{ output: process.stderr }` because `@inquirer/prompts` defaults to stdout;
`inquire` cannot be pointed at stdout at all. **P5**: the prompt loop yields two
different typed values for two different user intents —
`src/prompts/prompt.rs:141-153`, `Action::Cancel` → `InquireError::OperationCanceled`
(ESC), `Action::Interrupt` → `InquireError::OperationInterrupted` (`^C`) — and
`prompt_skippable()` converts the ESC case to `Ok(None)`
(`src/prompts/confirm/mod.rs:205-213`, doc: "it does not return
`Err(InquireError::OperationCanceled)`, but `Ok(None)`"). R67 read these same two
variants from source as evidence that a typed-adapter contract is achievable; this
item takes them up.

The MEDIUM question about defaults and validation is answered in the same source.
`Confirm` carries `with_default(bool)` (`src/prompts/confirm/mod.rs:150`), a
`DEFAULT_PARSER` (`:110`) and a settable `error_message` (`:180-181`) that is
re-rendered in place when parsing fails. `Text` carries `with_default`
(`src/prompts/text/mod.rs:187`), `with_initial_value` (`:181`), `with_placeholder`
(`:193`) and `with_validator`/`with_validators` (`:227,243`). `CustomType<T>` adds
`with_parser` (`src/prompts/custom_type/mod.rs:202`), `with_error_message` (`:239`)
and the same validator surface. **Retry is in-place and native**: the loop at
`src/prompts/prompt.rs:134-139` treats a failed `submit()` as `None`, redraws with the
error message and keeps reading, which is `click.prompt`'s behaviour without the
template building anything. The one thing `inquire` does **not** do is decide whether
to prompt — see `#### interactivity gate`.

##### Dominant choice

There is no dominant choice in this category: `dialoguer` leads on downloads
(16,348,116 in 90 days versus `inquire`'s 4,978,577) and reverse dependencies (2,356
versus 1,061), while `inquire` holds the single curated recommendation and the more
recent release. Both endpoints:
`GET https://crates.io/api/v1/crates/<name>` and `…/reverse_dependencies`. Reported as
a two-horse field rather than a dominant crate plus challengers.

##### Qualified shortlist

`inquire` 0.9.4, `dialoguer` 0.12.0, `cliclack` 0.5.6, `demand` 2.1.0. All four
render all three required shapes. Figures, all from
`GET https://crates.io/api/v1/crates/<name>`, `…/versions` and
`GET https://api.github.com/repos/<o>/<r>` plus
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`:

| Crate | 90-day downloads | All-time | Newest non-yanked | Stars | Archived | Pushed | Open issues | Open PRs |
|---|---|---|---|---|---|---|---|---|
| `inquire` | 4,978,577 | 20,585,265 | 0.9.4 (2026-02-24) | 2,626 | false | 2026-03-02 | 59 | 30 |
| `dialoguer` | 16,348,116 | 82,200,680 | 0.12.0 (2025-08-23) | 1,614 | false | 2026-09-16 | 71 | 28 |
| `cliclack` | 1,036,365 | 3,429,371 | 0.5.6 (2026-08-10) | 367 | false | 2026-08-10 | 10 | not queried |
| `demand` | 256,972 | 593,441 | 2.1.0 (2026-08-25) | 257 | false | 2026-09-15 | 8 | not queried |

**Fitness gates applied before any of those numbers were weighed.**

| Gate | `inquire` 0.9.4 | `dialoguer` 0.12.0 | `cliclack` 0.5.6 | `demand` 2.1.0 |
|---|---|---|---|---|
| 1 · Licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Observed only: `MIT` | same ruling; observed `MIT` | same ruling; observed `MIT` | same ruling; observed `MIT` |
| 2 · MSRV (policy floor **1.96**; stable is **1.98.1 (2026-09-01)**, `https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust]`) | `rust-version = "1.80.0"`; **resolved-tree maximum 1.85.0** (`unicode-segmentation` 1.13.3) — measured, see `## Validation strategy` E9. **Pass**, 11 minors of headroom | `1.66`; master has an unreleased "Bump MSRV to 1.83 (for getrandom)" commit dated 2026-09-16. **Pass** | not declared | not declared |
| 3 · Advisories / `unsafe` | `https://rustsec.org/packages/inquire.html` → **HTTP 404**, and `repos/rustsec/advisory-db/contents/crates/inquire` → 404: **no advisory**. `unsafe` posture: **zero `unsafe` tokens** in `inquire-0.9.4/src` (grep, this run); the `unsafe` in the subtree is `crossterm`/`libc`/`rustix`/`parking_lot` FFI | 404 / 404: no advisory; `unsafe` lives in `console`+`libc` | 404 / 404; `#![forbid(unsafe_code)]` at `src/lib.rs:287` | 404 / 404; `unsafe` FFI in `src/event.rs:56,81-88` |
| 4 · Builds/tested on `ubuntu-latest, macos-latest` | CI matrix `["ubuntu-latest", "macOS-latest", "windows-latest"]` × `[msrv, stable]`, `MSRV: 1.82.0` — `.github/workflows/build.yml:39-43,11`. **Pass**; Windows also covered, not required | CI matrix `[macos-latest, ubuntu-latest, windows-latest]` on `stable`, plus a separate job pinning toolchain `1.85.0` — `.github/workflows/ci.yml:12-20,54`. **Pass** | not verified | not verified |
| 5 · Default features / async coupling | defaults are `["macros","crossterm","one-liners","fuzzy"]` (`Cargo.toml` `[features]`); **this stack takes `default-features = false, features = ["crossterm","macros"]`**. **No async runtime anywhere in the tree** — measured, E9 | defaults `["editor","password"]`; no async | no async | no async |
| 6 · Binary size / compile time (qualitative) | **the stack's main cost.** Resolved subtree is 32 packages for a `cfg(unix)` x86-64 target (E9), of which `derive_more-impl` and `document-features` are additional **proc-macro** crates, and `mio`, `parking_lot`, `rustix` and `signal-hook` are new runtime crates. `syn`/`quote`/`proc-macro2` are already present via R60's `clap` derive and R66's `serde` derive, so they are not marginal | **much cheaper**: with `default-features = false`, `dialoguer` + R63's already-selected `indicatif` resolve to **8 packages total**, adding only `dialoguer` and `shell-words` over what `indicatif` already brings (E10) | console-based, similar order to `dialoguer` | console-based, plus `signal-hook` |

No candidate fails a gate. The separation is made on fit, below.

##### Excluded by gate

**None.** All four shortlisted crates pass gates 1–6 (gate 1 `inapplicable` by owner
ruling; gates 4 and 6 are recorded as `unverified` for `cliclack` and `demand`
because neither survived the fit comparison, and an unverified gate is reported as
unverified rather than assumed).

Two crates are **excluded on contract fit — which is not a fitness gate, and is
labelled separately so the distinction is not lost**:

- **`demand` 2.1.0 — excluded: it installs a process-wide `SIGINT` handler for every
  prompt.** `src/multiselect.rs:176` calls `ctrlc::show_cursor_after_ctrlc(&self.term)`,
  and that module registers a real handler on a background thread:
  `src/ctrlc.rs:1-50` imports `signal_hook::{consts::SIGINT,
  iterator::{Handle, Signals}}` and holds it in a `static HANDLE: LazyLock<RwLock<…>>`.
  R67 rules, in terms, that "No prompt-local Ctrl-C handler may be installed — it
  would race the process-level contract and can produce duplicate output". `demand`
  cannot be used without violating that rule.
- **`cliclack` 0.5.6 — excluded: it cannot distinguish ESC from `^C`.**
  `src/prompt/interaction.rs:102-112` maps `Key::Escape` **and** `Key::CtrlC` to the
  same `State::Cancel`, and `:97` turns that single state into a single
  `io::ErrorKind::Interrupted`. This template needs `0` for the first and `130` for
  the second (OV-01 and `RSLB903`), and no call-site logic can recover a distinction
  the crate erased. It is otherwise the most attractive of the up-and-comers —
  `#![forbid(unsafe_code)]`, `console`-based so it adds no new terminal back-end, and
  it reads keys with `read_key_raw()` so it never raises `SIGINT` from library code.

##### Up-and-comers

| Crate | 90-day downloads | All-time | Newest non-yanked | Stars | Pushed | Open issues | Read |
|---|---|---|---|---|---|---|---|
| `cliclack` | 1,036,365 | 3,429,371 | 0.5.6 (2026-08-10) | 367 | 2026-08-10 | 10 | Rust port of the `@clack/prompts` aesthetic. Note the symmetry with ts: ts's D-016(6) chose `@inquirer/prompts` **over** `@clack/prompts`; the Rust field reproduces the same pair and this item reaches the same conclusion, for a different and stronger reason (the ESC/`^C` collapse above) |
| `demand` | 256,972 | 593,441 | 2.1.0 (2026-08-25) | 257 | 2026-09-15 | 8 | From the `mise`/`jdx` stable; a Rust take on charmbracelet's `huh`. Actively developed. Blocked by the `SIGINT` handler above |
| `promkit` | 22,661 | 105,241 | 0.17.0 (2026-09-14) | 468 | 2026-09-14 | 9 | A prompt *toolkit* (compose your own prompt) rather than a set of ready widgets; the template wants widgets. Not shortlisted; gates not applied |
| `requestty` | 29,928 | 410,280 | 0.6.3 (2025-12-02) | 215 | 2025-12-02 | 3 | An `Inquirer.js` port, the closest structural analogue to ts's choice. Last release **2025-12-02** and last push the same day; the 6-month trigger fires and nothing rebuts it. Not shortlisted; gates not applied |

##### Fit for this template

| Requirement | `inquire` 0.9.4 | Evidence |
|---|---|---|
| All three shapes in one crate (HIGH) | **yes** — `Confirm`, `Text`/`CustomType`, `Select`, `MultiSelect` | `src/prompts/{confirm,text,custom_type,select,multiselect}/mod.rs` |
| `Choice`-style name/value pairs like ts's checkbox (HIGH) | **yes, and by value** — `MultiSelect::new(message, options: Vec<T>)` where `T: Display` supplies the *name*, and `prompt()`/`prompt_skippable()` return `Vec<T>` / `Option<Vec<T>>`: the *values* themselves, not indices. `raw_prompt()` returns `Vec<ListOption<T>>` carrying `{index, value}` when the original position is also wanted | `src/prompts/multiselect/mod.rs:222,385,415`; `src/list_option.rs:8-15` |
| Prompts on stderr, never stdout (HIGH) | **yes, unconditionally** — no stream override exists and none is needed | `src/terminal/crossterm.rs:2,97`; zero `stdout` matches in `src` |
| Typed `^C` distinct from ESC (P5, `RSLB903`) | **yes** | `src/prompts/prompt.rs:141-153` |
| Default value + validation with retry (MEDIUM) | **yes, native** | `confirm/mod.rs:150,180`; `text/mod.rs:187,227`; `custom_type/mod.rs:169,202,239`; retry loop `prompts/prompt.rs:134-139` |
| Detects non-interactive context itself (MEDIUM) | **no — and neither does any candidate.** `NotTTY` is only inferred *after* a failed syscall, from `raw_os_error()` 25 (`ENOTTY`) or 6 (`ENXIO`) (`src/error.rs:66-73`), and the `crossterm` back-end will have opened `/dev/tty` first. The gate is the template's | `src/error.rs:66-73`; `crossterm-0.29.0/src/terminal/sys/file_descriptor.rs:123-139` |
| Composes with `--dry-run`/`-y` (LOW) | **yes, by not being called** — both are plain booleans read before the prompt is constructed; no crate-side bypass needed or offered | precedence ladder in `### Principles and implementation` |
| Library crate stays prompt-free | **yes** — binary-crate dependency only | R67 layering rule |

##### Recommendation

`inquire = { version = "0.9.4", default-features = false, features = ["crossterm", "macros"] }`,
in the CLI binary crate, reached only through the template's `Prompter` trait, and
called only when the call-site gate is true.

##### Ranked runner-up

**`dialoguer 0.12.0`, with `default-features = false`** — and it is a close second
that would be the winner on two axes.

Where it wins: **cost** — with R63's `indicatif` already pulling `console` 0.16.6,
`dialoguer` adds `dialoguer` plus `shell-words` and nothing else (8 packages total
versus `inquire`'s 32; measured, E10), with no proc-macro crates, no `mio`, no
`rustix` and no duplicate `signal-hook`. **Maintenance** — `console-rs/dialoguer` was
pushed 2026-09-16 with commits from `djc`, including an unreleased MSRV bump, and 6
of its 10 most recently opened issues got a maintainer reply, each inside a day
(median over the answered set ≈ **0.2 days**); `inquire`'s record is worse on both
counts (below). It also has the literal property ts's D-016(6) prized — an explicit
output-stream handle, `interact_on(&Term)` with `Term::stderr()` as the default
(`src/prompts/multi_select.rs:150,191`) — and the closest thing to a built-in guard,
`if !term.is_term() { Err(NotConnected) }` (`:204-205`).

Where it loses: **`MultiSelect::interact()` returns `Vec<usize>`**
(`src/prompts/multi_select.rs:149`), indices into the list, so the caller re-indexes
to recover the domain values — a working but weaker answer to the HIGH name/value
question than `inquire`'s `Vec<T>`. And **`^C` is not a typed value**: `dialoguer`
reads keys with `term.read_key()` (`src/prompts/multi_select.rs:253` and siblings),
which is `console`'s `read_single_key(false)`, which on `^C` **raises `SIGINT` to the
process itself** (`console-0.16.6/src/unix_term.rs:356-362`, comment: "if the user hit
^C we want to signal SIGINT to ourselves"). That is not forbidden — it defers to the
process-level contract rather than racing it, and R67's `RSLB901`/130 would catch it
after `console` restores the original termios at `:354` — but it leaves `RSLB903`
unreachable, which is the branch R67's re-verify trigger describes as "`RSLB903` is
wired to a typed variant **or retired** before first release". Choosing `dialoguer`
means choosing the "retired" half.

The tie is broken by fit, not by figures: `inquire` answers both halves of the HIGH
multi-select question and both halves of the cancellation question directly, and the
`Prompter` seam converts `dialoguer`'s maintenance advantage into a cheap
contingency rather than a reason to lead with it.

##### Tradeoffs

- **Maintenance is this member's weak point, and it is stated plainly.** Verdict
  **`at-risk`**, on three concrete signals, not on the age of the release alone:
  (i) the newest release and the newest commit are the same commit, `chore: release
  v0.9.4`, **2026-02-24** — **≈6.7 months with no commit of any kind**
  (`GET https://api.github.com/repos/mikaelmello/inquire/commits?per_page=8`);
  (ii) **30 open pull requests** are queued behind that silence
  (`GET …/search/issues?q=repo:mikaelmello/inquire+is:pr+is:open`);
  (iii) **issue responsiveness: 7 of the 10 most recently opened issues have no
  maintainer reply at all** (#348, #344, #341, #337, #325, #322, #303), so the median
  days-to-first-maintainer-response is **undefined** over that window; the three that
  were answered were answered in 5 minutes (#329), 9 minutes (#314) and 2.9 days
  (#301). It is **not** `dormant`: there is no advisory, no maintainer notice of
  abandonment, and its CI builds on current stable. Mitigations: the version is
  pinned; the crate is one file behind a trait; `dialoguer` is a ranked, gate-passing
  replacement; and the re-verify trigger below fires on exactly this signal.
- **Dependency weight.** 32 packages resolved for the recommended feature set,
  against `dialoguer`'s marginal 2. For a *template*, which is copied and then
  audited by its users, that is a real cost and is the strongest argument for the
  runner-up.
- **`crossterm` brings `signal-hook 0.3.18` while R67 selected `signal-hook 0.4.4`.**
  Measured, not inferred: `cargo tree -d` on a manifest carrying both prints exactly
  one duplicate (E11). It is benign — both resolve on the same
  `signal-hook-registry 1.4.8`, and `crossterm` registers only `SIGWINCH`
  (`crossterm-0.29.0/src/event/source/unix/{tty.rs:72,mio.rs:48}`), a signal R67 does
  not handle — but it is a duplicate the workspace did not have before, and R67's own
  E13 recorded "zero duplicate resolutions" for its tree. Recorded in
  `### Compatibility`.
- **This member raises the workspace's binding tree MSRV to 1.85.0**
  (`unicode-segmentation` 1.13.3), up from the 1.71 R67 measured. Still 11 minors
  under the 1.96 floor, but it is the new binding number.
- **`inquire` cannot be tested without a terminal, but the template can.** The crate
  has no public test harness (its `src/terminal/test.rs` is `#[cfg(test)]`-private),
  so acceptance criteria 7–9 need a PTY. That cost is why the `Prompter` trait exists:
  everything except those three criteria is provable against `ScriptedPrompter`.

##### Parameters

This member owns no registry parameter and consumes none. Non-registry assumptions
are listed once in the item-level `### Parameters` field.

##### Migration implications

Adds one line to `crates/cli/Cargo.toml`. Creates `crates/cli/src/prompt.rs`
(`trait Prompter`, `InquirePrompter`, `ScriptedPrompter`). `inquire` is named in that
one file and nowhere else in the template.

##### Validation strategy

Acceptance criteria 5, 7 and 8 exercise this member specifically: `config init --yes`
writes without constructing a prompt; answering `n` exits `0`; `^C` mid-prompt maps
`OperationInterrupted` to `RSLB903`/130 with no `inquire` text in the envelope. The
last requires a PTY harness and is **proposed, not run** — R67 recorded the same gap
("`inquire`'s typed variants were read from source but never triggered"), and this
run did not close it either.

##### Confidence & re-verify trigger

**Confidence: medium-high on fit, medium on durability.** The API facts are read from
the checksum-verified tarball and are not in doubt; the maintenance signal is the
uncertainty. Re-verify **2026-12-17**, or earlier on any of: a commit-free interval
reaching 12 months in `mikaelmello/inquire`; a RustSec advisory against `inquire`,
`crossterm`, `mio` or `signal-hook`; an `inquire` release that changes the back-end
feature set or the `InquireError` variants; `dialoguer` shipping a value-returning
multi-select or a typed `^C` (which would flip the runner-up ahead); or Rust stable
advancing so far that the 1.96-style floor rises above 1.85.

##### Sources

- `GET https://crates.io/api/v1/crates/inquire`, `…/versions`, `…/reverse_dependencies` (2026-09-17)
- `GET https://api.github.com/repos/mikaelmello/inquire`; `…/commits?per_page=8`; `…/contents/.github/workflows/build.yml`; `GET https://api.github.com/search/issues?q=repo:mikaelmello/inquire+is:issue+is:open`; `…+is:pr+is:open`; `GET …/repos/mikaelmello/inquire/issues?state=all&sort=created&direction=desc&per_page=100` and the `…/issues/<n>/comments` of the 10 newest non-PR issues (2026-09-17)
- `https://static.crates.io/crates/inquire/inquire-0.9.4.crate`, sha256 `6654738b8024300cf062d04a1c13c10c8e2cea598ec1c47dc9b6641159429756`, **verified equal to crates.io's recorded `version.checksum`** for 0.9.4 (2026-09-17). All `src/...` line citations for this member are from that tarball
- `https://rustsec.org/packages/inquire.html` → 404; `GET https://api.github.com/repos/rustsec/advisory-db/contents/crates/inquire` → 404 (2026-09-17)
- `https://blessed.rs/crates` (2026-09-17)
- `https://raw.githubusercontent.com/ast-grep/ast-grep/main/crates/cli/Cargo.toml` (2026-09-17)

#### crossterm

##### Landscape

Bin: **established industry standard** — but for *terminal manipulation*, not for
prompts. `blessed.rs` lists `crossterm` under "TUI", beside `ratatui`
(`https://blessed.rs/crates`). It enters this bundle only as `inquire`'s back-end,
and it is a member rather than a footnote because the choice between `inquire`'s
`crossterm` and `console` back-ends **changes an observable behaviour of the
template**.

##### Principles and implementation

`crossterm` is what makes P5 expressible as a value. With this back-end the terminal
is in raw mode for the duration of the prompt (`inquire`
`src/terminal/crossterm.rs:89-98` calls `terminal::enable_raw_mode()` in
`CrosstermTerminal::new()`), so the line discipline generates no `SIGINT`, `^C`
arrives as a key event, and `inquire`'s loop returns `OperationInterrupted`
(`src/prompts/prompt.rs:153`). No handler is installed by anyone, which is what R67
requires. The alternative is `inquire`'s `console` back-end, and it is not
equivalent: `src/terminal/console.rs:27-29` reads keys with `self.term.read_key()`,
which is `console`'s `read_single_key(false)`, which raises `SIGINT`
(`console-0.16.6/src/unix_term.rs:356-362`) — `inquire`'s own documentation says so
(`src/error.rs:28-32`: "This error will be returned only when using `crossterm` or
`termion` … If using `console`, pressing Ctrl+C will trigger SIGINT"). Choosing
`console` would save the whole `crossterm` subtree and cost `RSLB903`.

`crossterm` also supplies the report's sharpest gate evidence:
`src/terminal/sys/file_descriptor.rs:123-139` (`tty_fd()` opens `/dev/tty` when stdin
is not a terminal) and `src/terminal/sys/unix.rs:108-123` (`enable_raw_mode()` is
built on `tty_fd()`).

##### Dominant choice

**Yes, in its own category.** `crossterm` is the mainstream cross-platform terminal
back-end: 43,995,611 downloads in 90 days, 191,657,943 all-time
(`GET https://crates.io/api/v1/crates/crossterm`), 4,223 stars
(`GET https://api.github.com/repos/crossterm-rs/crossterm`). Its only peer in
`inquire`'s feature set is `termion` (Unix-only, not considered: the template's
matrix is Unix but its users' forks may not be) and `console`.

##### Qualified shortlist

`crossterm` 0.29.0 and `console` 0.16.6 — the two back-ends `inquire` offers that
build on both required OSes.

| Crate | 90-day downloads | All-time | Newest non-yanked | Stars | Archived | Pushed | Open issues |
|---|---|---|---|---|---|---|---|
| `crossterm` | 43,995,611 | 191,657,943 | 0.29.0 (2025-04-05) | 4,223 | false | 2026-09-14 | 170 |
| `console` | 80,406,869 | 349,775,351 | 0.16.6 (2026-09-10) | 1,195 | false | 2026-09-10 | 48 |

**Fitness gates, `crossterm` 0.29.0.**

| Gate | Result |
|---|---|
| 1 · Licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Observed only: `MIT` |
| 2 · MSRV | `rust-version = "1.63.0"`; the highest in the whole resolved subtree is 1.85.0 (`unicode-segmentation`), floor 1.96. **Pass** |
| 3 · Advisories / `unsafe` | `https://rustsec.org/packages/crossterm.html` → 404 and `advisory-db/contents/crates/crossterm` → 404: **none open**. `unsafe`: yes, necessarily — `libc`/`rustix` FFI for `termios`, `ioctl` and fd handling. Posture: encapsulated in `src/terminal/sys/*` behind safe wrappers |
| 4 · Platforms | CI matrix `[ubuntu-24.04, windows-2022, macos-15]` (`.github/workflows/ci.yml:124`), plus Unix and Windows feature-test jobs (`:216,255`). **Pass** — both required OSes, Windows also covered |
| 5 · Default features / async | defaults `["bracketed-paste","events","windows","derive-more"]`. `events` is what pulls `mio 1.0`, `signal-hook 0.3.17` and `signal-hook-mio 0.2.4` under `cfg(unix)`, and `inquire` depends on `crossterm` **with default features**, so `events` cannot be dropped from inside this stack. **No async runtime**: `mio` is a poll abstraction, not an executor, and `event-stream` (the `futures-core` feature) is **not** a default. Measured: E9 shows no `tokio`, `async-std` or `futures-executor` in the tree |
| 6 · Size / compile time | the dominant part of this stack's cost: `crossterm` itself plus `derive_more`+`derive_more-impl`+`convert_case` (a proc-macro chain), `document-features`+`litrs` (another), `mio`, `parking_lot`(+`lock_api`,`parking_lot_core`,`scopeguard`,`smallvec`), `rustix`(+`linux-raw-sys`,`errno`), `signal-hook`(+`signal-hook-registry`), `signal-hook-mio`, `log`, `libc`, `bitflags` |

##### Excluded by gate

**None.** `console` 0.16.6 is not excluded by any gate — it is *not selected*,
because with `console` behind `inquire` a `^C` becomes a raised `SIGINT` and
`RSLB903` becomes unreachable (evidence in `##### Principles and implementation`).
Recorded as a fit decision, not a gate failure, and reversible: it is one feature
string.

##### Up-and-comers

None applicable to this member. The terminal-back-end field is settled between
`crossterm` and `console`; `termion` (Unix-only) is `inquire`'s third option and is a
narrowing, not an up-and-comer. `inapplicable` for the up-and-comer bin, with that
reason.

##### Fit for this template

Selected **through `inquire`'s feature flag, never as a direct dependency** — the same
discipline R60 applied to `strsim` ("transitive through clap's default `suggestions`
feature — never a direct dependency"). It brings a typed `^C`, works on both matrix
OSes, and its one overlap with an existing decision (`signal-hook`) is a benign
duplicate rather than a conflict. Its cost is the honest reason the runner-up crate
exists.

##### Recommendation

Keep `inquire`'s `crossterm` feature and do not add `crossterm` to any
`[dependencies]` table. Record in the template's dependency documentation that the
feature is load-bearing for the `RSLB903` mapping, so a future "trim the tree" pass
does not silently swap it for `console`.

##### Ranked runner-up

`console 0.16.6` via `inquire`'s `console` feature. It would remove ~15 packages,
reuse the `console` that R63's `indicatif` already pulls, and cost the typed `^C`
(`RSLB903` retired, `RSLB901` catching the raised `SIGINT` instead). Take it only if
the workspace's compile time becomes a measured problem **and** the owner accepts
retiring `RSLB903`.

##### Tradeoffs

- The proc-macro chain (`derive_more-impl`, `document-features`) is compile-time cost
  paid on every clean build of the CLI crate.
- Maintenance: **`stable-quiet`.** The trigger fires — last release **0.29.0,
  2025-04-05**, ~17 months — and is rebutted rather than confirmed: the repository was
  pushed **2026-09-14**, with substantive feature and fix commits through 2026-08
  (`GET …/repos/crossterm-rs/crossterm/commits?per_page=8`), 76 open PRs indicating
  flow rather than silence, no advisory, and CI green on a matrix including current
  toolchains. Slow release cadence, live development.
- 170 open issues is the highest count in this report; for a crate with 191.7M
  all-time downloads that reads as surface area, not neglect. No concrete `at-risk`
  signal was found.

##### Parameters

Owns none, consumes none.

##### Migration implications

No manifest line of its own. One sentence in the template's dependency notes
explaining why the feature is not merely a default.

##### Validation strategy

Covered by acceptance criteria 1 and 8: criterion 1 proves the `/dev/tty` fallback
never fires because the gate runs first; criterion 8 proves the typed `^C` reaches
`RSLB903`. Both need a PTY or a controlling terminal and are **proposed, not run**.

##### Confidence & re-verify trigger

**High** on the API and platform facts (read from the checksum-verified tarball and
from the repository's own CI file); **medium** on cadence. Re-verify with `inquire`,
and additionally on: a `crossterm` 0.30 that changes the `events` feature's
dependency set; any RustSec advisory against `crossterm`, `mio`, `rustix` or
`signal-hook`; or R63/R58 changing the `console`/`indicatif` footprint in a way that
makes the `console` back-end's arithmetic decisive.

##### Sources

- `GET https://crates.io/api/v1/crates/crossterm`, `…/versions`; `GET https://crates.io/api/v1/crates/console`, `…/versions` (2026-09-17)
- `GET https://api.github.com/repos/crossterm-rs/crossterm`; `…/commits?per_page=8`; `…/contents/.github/workflows/ci.yml`; `GET …/search/issues?q=repo:crossterm-rs/crossterm+is:issue+is:open`; `…+is:pr+is:open` (2026-09-17)
- `https://static.crates.io/crates/crossterm/crossterm-0.29.0.crate`, sha256 `d8b9f2e4c67f833b660cdb0a3523065869fb35570177239812ed4c905aeff87b`, **verified equal to crates.io's recorded checksum** (2026-09-17)
- `https://static.crates.io/crates/console/console-0.16.6.crate`, sha256 `e96a4956774c13c126a8b5af4daa79384f4d826534c95a02d76afb39e2ab64e3`, **verified equal** (2026-09-17)
- `https://rustsec.org/packages/crossterm.html` → 404; `…/console.html` → 404; the matching `advisory-db` content paths → 404 (2026-09-17)
- `GET https://crates.io/api/v1/crates/signal-hook/0.3.18/dependencies` and `…/0.4.4/dependencies` (2026-09-17)

#### interactivity gate (`std::io::IsTerminal`)

##### Landscape

Bin: **built-in / first-party toolchain** — and it is the only member of this bundle
that lives there. `std::io::IsTerminal` stabilized in **Rust 1.70.0 (2023-06-01)**
(`rust-lang/rust` `RELEASES.md:3817`, section header `:3732`). Before it stabilized
the ecosystem used `atty`, which now carries two RustSec advisories
(`advisory-db/contents/crates/atty` lists `RUSTSEC-2021-0145.md` and
`RUSTSEC-2024-0375.md`) — which is exactly why the first-party predicate is the right
answer and why *this member exists as a member*: the gate is a decision, and the
wrong version of it is a known vulnerability class.

##### Principles and implementation

This member is a **pattern**, so the crate figures in `## Required evidence` —
90-day downloads, all-time downloads, last release, stars, open issues, issue
responsiveness, advisories, adopters — are **`inapplicable`, because there is no
crate**: the mechanism is a trait in the standard library, versioned with the
toolchain and covered by the `msrv-policy` parameter rather than by a crate's own
`rust-version`. The pattern fields are the gate's shape, its inputs and its
outcomes.

The pattern, in full:

```
interactive(g) = !g.no_input && stdin().is_terminal() && stderr().is_terminal()
```

evaluated **once per call site**, before any prompt type is constructed, and used in
the precedence ladder `--yes` → gate → prompt. Its three outcomes are the three rows
of the F360 table in `### Principles and implementation`: refuse with `RSLB205`/2 for
the consent and required-value classes, proceed with the complete result for the
narrowing class.

Why it is the template's and not the crate's is established in
`### Principles and implementation` and rests on two primary-source facts:
`crossterm-0.29.0/src/terminal/sys/file_descriptor.rs:123-139` and
`console-0.16.6/src/unix_term.rs:88-99` both fall back to `/dev/tty`. The gate is the
only thing standing between this template and the "surprise prompt" R8.1 forbids
(`:456`).

Why both file descriptors: R8.1 conditions the confirm on **stdin** ("when stdin is a
TTY", `:456`) and R7.1 puts prompts on **stderr** (`:381`). ts computes the identical
conjunction at `ts: src/commands/projects.ts:146`. This is the item's clearest
"same principle, same mechanism, both ecosystems" finding.

##### Dominant choice

`std::io::IsTerminal` — `inapplicable` as a popularity claim (it is the standard
library), dominant as a matter of fact: since 1.70 there is no reason for a Rust
program to reach for a TTY-detection crate, and the crate that used to serve that
role carries two advisories.

##### Qualified shortlist

Three designs for the gate, not three crates:

| Design | What it is | Verdict |
|---|---|---|
| **G1** | call-site predicate over `std::io::IsTerminal` + `--no-input` | **Selected** |
| G2 | delegate to the prompt crate's own detection | Impossible as specified: no candidate tests stdin, and two of them open `/dev/tty`. Rejected on primary-source evidence |
| G3 | a TTY-detection crate (`is-terminal`, `atty`) | Redundant since Rust 1.70 and, for `atty`, advisory-bearing. Rejected |

##### Excluded by gate

Gates 1–6 are **`inapplicable` to this member**, individually and with reasons, since
no crate is added: 1 licence — `inapplicable — owner ruling 2026-09-12 (Q7.B)`, and
doubly so for `std`; 2 MSRV — `inapplicable` as a crate gate, but the pattern imposes
a **floor of Rust 1.70.0**, which the `msrv-policy` floor of 1.96 clears by 26 minor
versions; 3 advisories — `inapplicable`, no crate, no `unsafe` written by the
template (`IsTerminal::is_terminal` encapsulates the platform call); 4 platforms —
`IsTerminal` is implemented for `Stdin`/`Stdout`/`Stderr` on both matrix OSes and on
Windows; 5 default features / async — `inapplicable`, no features, no runtime;
6 size / compile time — `inapplicable`, no new code generation beyond two calls.

##### Up-and-comers

`inapplicable` — a stabilized `std` trait has no up-and-comer field. The only
movement worth watching would be a future `std` API for "is there a controlling
terminal", which does not exist today.

##### Fit for this template

It is the piece that makes the whole bundle conform. Without it the template ships
the exact anti-pattern R8.1 names; with it, criteria 1, 2, 5 and 6 pass with no
terminal in sight, because the gate is a pure function of three booleans and is
therefore unit-testable by injecting them — which is how the `Prompter` seam and the
gate compose: the seam removes the crate from the test, the gate's injectability
removes the terminal.

##### Recommendation

One `fn interactive(&GlobalArgs) -> bool` in the CLI crate, over
`std::io::IsTerminal`, taking its two TTY inputs through injectable accessors so
tests can drive all four combinations. No crate. Same call-site-owns-the-gate
architecture R63 chose for the spinner, so the template has one rule for "should this
terminal nicety happen", not two.

##### Ranked runner-up

`is-terminal` 0.4.x, the community crate that pre-dates the `std` trait and now
mostly forwards to it. Take it only if the template's MSRV floor were ever driven
below 1.70, which the fixed `msrv-policy` makes impossible.

##### Tradeoffs

- The gate is template-owned code, so it is template-owned risk: if a future call
  site forgets to consult it, that call site will prompt into a pipe. Mitigation:
  the `Prompter` trait is the only path to a prompt, and the gate can be enforced by
  construction — for example by having the composition root hand the command an
  `Option<&dyn Prompter>` that is `None` when the gate is false, so a non-interactive
  run has no prompter to call.
- `IsTerminal` answers "is this fd a terminal", not "does this process have a
  controlling terminal". They differ in the piped-stdin-from-a-terminal-window case,
  which is precisely the case the gate is written to catch, so the difference is the
  point rather than a limitation.

##### Parameters

Owns none. Its Rust-version floor (1.70.0) is subsumed by the fixed `msrv-policy`.

##### Migration implications

One new file, `crates/cli/src/interactive.rs`; one field (`no_input`) on R60's
`GlobalArgs`; one call per prompt site.

##### Validation strategy

This member carries the acceptance criteria that need **no PTY** and are therefore
the ones a normal CI job can run: criteria 1, 2, 5 and 6, driven through
`assert_cmd`-style built-binary invocations with `< /dev/null`, with `--no-input`,
and with stdout redirected. All **proposed**; none was run, because no template
exists to run them against.

##### Confidence & re-verify trigger

**High.** The mechanism is a stabilized `std` trait, the rule it implements is quoted
from the pinned standard, and the two `/dev/tty` fallbacks that motivate it were read
from checksum-verified source. Re-verify only if the pinned CLI Design Standard is
re-pinned to a revision that changes R8.1, R8.2 or R8.5, or if `--no-input`'s meaning
changes in R4.2's global table.

##### Sources

- CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`: R4.2 (`:252-253`, `:609`), R7.1 (`:381`), R7.3 (`:390`), R8.1 (`:456`), R8.2 (`:461`), R8.5 (`:472`), checklist (`:650`)
- `https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md` — `IsTerminal` at `:3817`, under `Version 1.70.0 (2023-06-01)` at `:3732` (2026-09-17)
- `crossterm-0.29.0/src/terminal/sys/file_descriptor.rs:123-139`; `console-0.16.6/src/unix_term.rs:88-99` (checksum-verified tarballs above)
- `GET https://api.github.com/repos/rustsec/advisory-db/contents/crates/atty` → `RUSTSEC-2021-0145.md`, `RUSTSEC-2024-0375.md` (2026-09-17) — the negative control that establishes what a 404 on that path means
- `ts: src/commands/projects.ts:146` at pin `cb1cbcb2`

---

### Compatibility

**Shared adopter, covering R60 and R61 in one manifest.** `ast-grep/ast-grep`
(15,932 stars) declares, in the same `crates/cli/Cargo.toml`:
`clap = { version = "4.5.4", features = ["derive"] }` (line 38),
`inquire = "0.9.0"` (line 46) and `clap_complete = "4.5.2"` (line 54)
(`https://raw.githubusercontent.com/ast-grep/ast-grep/main/crates/cli/Cargo.toml`,
retrieved 2026-09-17). That is direct evidence that R60's selected parser and this
item's selected prompt crate ship together in a widely used, actively developed Rust
CLI — the composition this bundle needs proven.

**Version matrix, resolved rather than asserted.** Resolving
`inquire = { version = "0.9.4", default-features = false, features = ["crossterm","macros"] }`
on 2026-09-17 with the local toolchain produced a lockfile of **40 packages**, of
which **32** are in the `cfg(unix)` x86-64 normal tree (E9). Highest declared
`rust-version` anywhere in it: **1.85.0** (`unicode-segmentation` 1.13.3), against a
policy floor of **1.96** (stable 1.98.1, 2026-09-01). Every declared licence string in
the tree is MIT, `MIT OR Apache-2.0`, `Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR
MIT`, or `(MIT OR Apache-2.0) AND Unicode-3.0` — recorded as observation only, per the
owner's licence ruling. No async runtime appears at any depth.

**The one interaction with an already-published decision, measured.** R67 selected
`signal-hook = { version = "0.4.4", default-features = false }` under
`[target.'cfg(unix)'.dependencies]`. `crossterm` 0.29.0's default `events` feature
requires `signal-hook 0.3.17` (`Cargo.toml`, `[target."cfg(unix)".dependencies.signal-hook]`).
Resolving both together yields **exactly one duplicate** (E11):

```
signal-hook v0.3.18   ← crossterm ← inquire        (and ← signal-hook-mio ← crossterm)
signal-hook v0.4.4    ← the template               (R67)
```

This is benign and is stated rather than escalated: both majors depend on
`signal-hook-registry ^1.4` and resolve to the **same** `signal-hook-registry 1.4.8`,
so there is one registry and no possibility of two independent handler tables;
`crossterm` registers only `SIGWINCH`
(`src/event/source/unix/tty.rs:72`, `src/event/source/unix/mio.rs:48`), which R67
does not handle; and R67's `SIGINT`/`SIGTERM` flags are untouched. The cost is one
extra compiled crate and a non-empty `cargo tree -d`, where R67's own E13 recorded
zero duplicates. If the workspace later adopts a `cargo deny` "no duplicates" rule,
this is the row that needs an allowance.

**Interaction with R63.** R63 selected `indicatif = "0.18"`, which brings `console`
0.16.6. With this bundle the template carries **both** terminal libraries: `console`
for the spinner and `crossterm` (through `inquire`) for prompts. They do not conflict
— the spinner and a prompt are never live at the same time, and ts already sequences
them that way (`ts: src/commands/projects.ts:129-135` stops the spinner in a
`finally` before the prompt at `:157`) — but it is two terminal stacks in one binary,
and it is the arithmetic that would favour the `console` back-end or `dialoguer` if
compile time ever becomes the binding constraint.

**Interaction with R65.** Covered in `### Principles and implementation`: the
template passes an explicit `RenderConfig` so R65's resolved chain, not `inquire`'s
single `NO_COLOR` check, decides colour.

**Interaction with R66.** `inquire` writes only to stderr, and R66 owns stdout's
locked-handle writer. The two never contend for fd 1; acceptance criterion 9 is the
observable proof.

---

### Parameters

This item owns **no** registry parameter (`- owns:` is empty in the prompt's
`## Couplings`) and consumes **no** registry parameter (`- consumes:` is empty). The
lines below are therefore *non-registry* assumptions on published decisions, recorded
so a reviewer can check them, not parameter declarations:

- assumes (non-registry) `error-taxonomy-exit-codes` = R67's published
  `error-contract/v1`, specifically the rows `RSLB205` (required non-auth input or
  consent missing because prompting is disabled or unavailable → 2), `RSLB903`
  (prompt interrupted by Ctrl-C → 130), `RSLB101` (I/O → 1) and `RSLB000`
  (unexpected → 1), plus the rule that no prompt-local Ctrl-C handler may be
  installed. Every outcome this item can produce maps onto an existing row.
- assumes (non-registry) R60's `clap` 4.6.6 with `derive` and F270's single
  `#[derive(Args)] struct GlobalArgs` flattened at the root with `global = true`, as
  the carrier of `--no-input`, `--yes`/`-y` and `--dry-run`.
- assumes (non-registry) R65's resolved colour chain as the input to `inquire`'s
  `RenderConfig`.
- assumes (non-registry) R63's `indicatif` 0.18 as the reason `console` 0.16.6 is
  already in the tree (relevant only to the runner-up arithmetic).
- assumes (fixed) `msrv-policy`, `rust-edition = 2024`, `license = MIT OR Apache-2.0`,
  `target-os-matrix = ubuntu-latest, macos-latest`.

**No `CONFLICT:` line.** No recommendation here needs a consumed parameter to change.

**No `BASELINE-REVIEW:` line.** The two recorded baselines in scope — F277
(`--dry-run`, `ADOPT`) and F278 (`-y`/`--yes`, `ADOPT`) — are preserved exactly: both
remain plain flags, the `--yes` bypass returns before any prompt is constructed, and
`--dry-run` is evaluated after consent and before the write, as py does at the pin.

**Recorded override.** OVERRIDE (OV-01) — a declined confirm exits `0` in rs where py
exits `5`; argument and options in `### Principles and implementation`.

---

### Migration implications

File-level changes in the template (all **proposed**; the template does not exist and
P03 builds it):

| File | Change |
|---|---|
| `crates/cli/Cargo.toml` | add `inquire = { version = "0.9.4", default-features = false, features = ["crossterm", "macros"] }`. Nothing is added to the library crate's manifest or to the web surface's |
| `crates/cli/src/prompt.rs` | **new.** `pub trait Prompter: Send + Sync` with `confirm`, `value`, `choose_one`, `choose_many`; `pub struct InquirePrompter` (the only file in the template that names `inquire`); `pub struct ScriptedPrompter` for tests; the `InquireError` → `ErrorCode` match arms of the mapping table |
| `crates/cli/src/interactive.rs` | **new.** `fn interactive(&GlobalArgs) -> bool` over `std::io::IsTerminal`, with injectable TTY accessors |
| `crates/cli/src/cli.rs` (R60's `GlobalArgs`) | add the `--no-input` field; `--yes`/`--dry-run` already exist per F277/F278 |
| `crates/cli/src/commands/config.rs` | `init`: the guided-value loop behind the gate, `--yes` accepting resolved defaults (py parity). `set`: the overwrite confirm behind the gate, `--yes` bypassing it, decline → notice + exit `0` |
| `crates/cli/src/commands/project.rs` | after the fetch: preview table on stderr when interactive; `choose_many` when interactive; **all** rows when not; empty selection → stderr notice, exit `0` |
| `crates/cli/src/main.rs` | the composition root builds `InquirePrompter` only when the gate is true, and hands the command `Option<&dyn Prompter>` so a non-interactive command has nothing to call |
| `docs/` | one page documenting the three prompt classes, the `--yes`/`--no-input` matrix and the exit codes; R8.5 requires the non-interactive path be documented, and R8.1 requires any `/dev/tty` behaviour be documented — the template has none, and saying so is the documentation |
| `docs/error-codes.md` | no new row. `RSLB205` and `RSLB903` become *reachable*; `RSLB903` ceases to be dormant |

---

### Validation strategy

**Checks actually executed in this run** (evidence about the *ecosystem*, not about
the template, which does not exist). Every tarball line citation in this report comes
from a tarball whose sha256 was compared against the `checksum` field crates.io
returns for that exact version.

| # | Command | Result |
|---|---|---|
| E1 | `curl https://crates.io/api/v1/crates/<name>` for `inquire`, `dialoguer`, `demand`, `cliclack`, `promkit`, `requestty`, `crossterm`, `console` | the 90-day and all-time download figures in this report |
| E2 | `curl …/crates/<name>/versions` for the same eight | newest non-yanked version and `created_at` for each |
| E3 | `gh api repos/<o>/<r>` for the eight repositories | stars, `archived: false` for all eight, `pushed_at` |
| E4 | `gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"` and `…+is:pr+is:open` | open-issue and open-PR counts (never `open_issues_count`) |
| E5 | `gh api "repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=100"`, filter `pull_request == null`, take 10, then `…/issues/<n>/comments` filtered to `author_association` ∈ {OWNER, MEMBER, COLLABORATOR} and ≠ the reporter | `inquire`: 7 of 10 unanswered, median undefined; the three answered at 5 min, 9 min, 2.9 d. `dialoguer`: 6 of 10 answered, all < 1 day, median of the answered set ≈ 0.2 d; the 4 unanswered all pre-date 2025-10 |
| E6 | `curl https://rustsec.org/packages/<name>.html` for all eight | **HTTP 404 for all eight**; negative control `atty` and `time` both return **200**, so 404 means "no advisory page", not "endpoint broken" |
| E7 | `gh api repos/rustsec/advisory-db/contents/crates/<name>` for six | 404 for all six; control `crates/atty` lists `RUSTSEC-2021-0145.md`, `RUSTSEC-2024-0375.md` |
| E8 | `curl https://static.crates.io/crates/<n>/<n>-<v>.crate` → `tar xzf` → `shasum -a 256`, compared with `curl https://crates.io/api/v1/crates/<n>/<v>` `.version.checksum` | **4 of 4 match**: `inquire` 0.9.4 `6654738b…9756`, `dialoguer` 0.12.0 `25f104b5…ad96`, `crossterm` 0.29.0 `d8b9f2e4…f87b`, `console` 0.16.6 `e96a4956…64e3` |
| E9 | throwaway manifest with the recommended `inquire` line → `cargo generate-lockfile` → `cargo tree -e normal` → `cargo metadata --filter-platform x86_64-unknown-linux-gnu` | "Locking 40 packages"; 32 in the normal unix tree; **max declared `rust-version` 1.85.0** (`unicode-segmentation`); no async runtime at any depth |
| E10 | same for `dialoguer` (`default-features = false`) **plus** R63's `indicatif = "0.18"` | 8 packages total; `dialoguer` adds only itself and `shell-words` over `indicatif`'s `console`; `cargo tree -d` prints nothing |
| E11 | E9's manifest **plus** R67's `signal-hook = { version = "0.4.4", default-features = false }` → `cargo tree -d -e normal` | exactly one duplicate: `signal-hook` 0.3.18 (via `crossterm`) and 0.4.4 (direct); one shared `signal-hook-registry` 1.4.8 |
| E12 | `curl https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust]` | stable **1.98.1 (48a229cea 2026-09-01)**, channel date 2026-09-03 → policy floor **1.96** |
| E13 | `curl https://rust-cli.github.io/book/searchindex.json` → count `dialoguer`, `inquire`, `requestty`, `prompt` | **0, 0, 0, 0** |
| E14 | `curl https://blessed.rs/crates` → strip tags → search | "Interactive prompts → `inquire`"; `dialoguer`, `cliclack`, `demand`, `requestty`, `promkit` absent |
| E15 | `gh api repos/<o>/<r>/contents/.github/workflows/<f> --jq .content \| base64 -d` for `inquire`, `crossterm` and `dialoguer` | `inquire`: `["ubuntu-latest","macOS-latest","windows-latest"]` × `[msrv, stable]`, `MSRV: 1.82.0`. `crossterm`: `[ubuntu-24.04, windows-2022, macos-15]`. `dialoguer`: `[macos-latest, ubuntu-latest, windows-latest]` on `stable`, plus a job pinning `1.85.0` |
| E16 | `git -C ~/c/py-launch-blueprint show b08bccfb:<path>` and `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>` | every `py:`/`ts:` quotation in this report, read through the pins |

**Checks proposed for P03, not run** (no Rust code exists):

| # | Command (proposed) | Expected |
|---|---|---|
| P1 | `printf '' \| rslbp config set core.key v2 < /dev/null; echo $?` from a terminal, with `core.key=v1` | `2`; `RSLB205` envelope on stderr; **no prompt on the controlling terminal**; stdout byte-empty; `core.key` still `v1` (criterion 1) |
| P2 | `rslbp config set core.key v2 --no-input; echo $?` | `2`, `RSLB205`, no write (criterion 2) |
| P3 | `rslbp config set core.key v2 --yes; echo $?` | `0`, written, no prompt constructed — assert by running under a `ScriptedPrompter` that panics if called (criterion 3) |
| P4 | `rslbp config set core.key v2 --dry-run --yes` | `0`, `[dry-run] would set …` on stderr, no write (criterion 4) |
| P5 | `rslbp config init --no-input; echo $?` then `rslbp config init --yes; echo $?` | `2`/`RSLB205`, then `0` with the file written from resolved defaults (criterion 5) |
| P6 | `rslbp project list --no-input -o json > out.json; echo $?` | `0`; every fetched row in `out.json`; no prompt bytes in it (criterion 6) |
| P7 | PTY harness: answer `n` to the overwrite confirm | `0`, `Aborted.` on stderr, stdout byte-empty, no write (criterion 7, OV-01) |
| P8 | PTY harness: send `^C` mid-`MultiSelect` | `130`; `RSLB903` envelope; **no `inquire` error text** in it (criterion 8; this is R67's own open proof #4) |
| P9 | PTY harness with `1>file`: any prompt | `file` contains zero prompt bytes (criterion 9, R7.1) |
| P10 | `cargo tree -d -e normal` in CI | the `signal-hook` duplicate is the **only** duplicate; a second one is a regression |

Unit-provable without a terminal: the gate's four boolean combinations, the whole
`InquireError` → `ErrorCode` mapping table (constructing the variants directly), and
every command path through `ScriptedPrompter`. PTY-only: P7, P8, P9.

---

### Confidence & re-verify trigger

**Confidence: medium-high.** The behavioural claims are read from checksum-verified
primary source, the conformance claims are quoted line-by-line from the pinned
standard, and the cross-repo claims are read through both repository pins. Two things
temper it. First, **nothing here was executed against a Rust template**, because none
exists; the nine acceptance criteria are proposed. Second, the recommended crate's
maintenance is the weakest figure in the report — `at-risk`, on three concrete
signals — and it is the reason the design puts the crate behind a trait rather than
calling it from four command modules.

The judgement that could most plausibly be overturned is the choice of `inquire` over
`dialoguer`. It rests on fit (value-returning multi-select; typed `^C` distinct from
ESC) beating cost and maintenance (2 marginal packages versus 26; an active
maintainer versus a quiet one). A reviewer who weights template dependency weight or
maintainer responsiveness above the `RSLB903` mapping should reach `dialoguer`, and
the runner-up field is written so that swap is a one-file change with its consequence
(retiring `RSLB903`) stated up front.

**Re-verify 2026-12-17**, or earlier on any of:

- `mikaelmello/inquire` reaching 12 months without a commit, or the maintainer posting
  a status notice (→ `dialoguer`);
- a RustSec advisory against `inquire`, `crossterm`, `console`, `mio`, `rustix` or
  either `signal-hook` major;
- `dialoguer` shipping a value-returning multi-select **or** a typed `^C` (either
  would flip the ranking);
- an `inquire` release that changes the `InquireError` variants, the back-end feature
  set, or `RenderConfig::default()`'s environment behaviour;
- R63 or R58 changing the `console`/`indicatif` footprint enough to make the
  `console` back-end's arithmetic decisive;
- the owner re-pinning the CLI Design Standard to a revision that changes R8.1, R8.2
  or R8.5;
- R67 being revised in a way that changes `RSLB205` or `RSLB903`;
- P03 measuring compile time and finding this subtree binding.

---

### Sources

**Pinned documents**

- Org CLI Design Standard **v1.4.14**, `smorinlabs/cli-standards`, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, read 2026-09-17 via `git -C /Users/stevemorin/c/cli-standards show f9de0437…`. Cited: R3.9 (`:226`), R4.2 (`:252-253`, `:609`), R7.1 (`:381`), R7.3 (`:390`), R7.4 (`:395`), R8.1 (`:456`), R8.2 (`:461`), R8.4 (`:468`), R8.5 (`:472`), checklist (`:650`)
- `py-launch-blueprint` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`: `src/py_launch_blueprint/cli/options.py:265-278` (the `confirm` gate, `--yes` short-circuit, `--no-input` refusal, `err=True`), `src/py_launch_blueprint/cli/commands/config.py:85-100` (the `--yes`/`--no-input`/prompt ladder and `click.prompt(… type=click.Choice(choices) …, err=True)`), `:180-183` (dry-run), `:193-203` (overwrite confirm and `SystemExit(ExitCode.INTERRUPT)`), `src/py_launch_blueprint/core/errors.py:45,55` (`INTERRUPT = 5`, `PLBP004`)
- `ts-launch-blueprint` at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`: `src/commands/projects.ts:146` (the three-input interactivity predicate), `:150-152` (stderr preview table), `:157-165` (the checkbox call with `{name, value}` choices), `:166-168` (non-interactive select-all), `:170-174` (empty selection → exit 0), `src/lib/adapters.ts:22` (`Prompter` seam), `:41-45` (`realPrompter`, `checkbox(… , { output: process.stderr })`)
- Repository decisions read for couplings: `research/topics/67-error-and-exit-code-contract/DECISION.md` (the published `error-contract/v1`; the "Prompt cancellation (F299) is defined and dormant" passage; the no-prompt-local-handler rule; open proof #4), `research/topics/60-cli-parsing-framework/DECISION.md` (clap 4.6.6 + `derive`, F270 global args, the standard pin), `research/topics/63-progress-spinner/DECISION.md` (`indicatif = "0.18"`, call-site gating), `research/topics/65-color-enablement-chain/DECISION.md` (colour chain), `docs/port/COMMONALITY.md` rows F276–F280, F298–F299, F360, `docs/port/DIVERGENCE-ANALYSIS.md:199,213` and the `harmonize = partly` list, `docs/port/PARAMETERS.md`

**Endpoints queried** (all 2026-09-17 unless noted)

- `GET https://crates.io/api/v1/crates/{inquire,dialoguer,demand,cliclack,promkit,requestty,crossterm,console,fuzzy-matcher}` and `…/versions`
- `GET https://crates.io/api/v1/crates/{inquire,dialoguer}/reverse_dependencies?per_page=50`
- `GET https://crates.io/api/v1/crates/{inquire/0.9.4,dialoguer/0.12.0,crossterm/0.29.0,console/0.16.6}` (checksum field)
- `GET https://crates.io/api/v1/crates/signal-hook/{0.3.18,0.4.4}/dependencies`
- `GET https://api.github.com/repos/{mikaelmello/inquire,console-rs/dialoguer,jdx/demand,fadeevab/cliclack,ynqa/promkit,Lutetium-Vanadium/requestty,crossterm-rs/crossterm,console-rs/console,ast-grep/ast-grep,wasm-bindgen/wasm-pack,transact-rs/sqlx,tauri-apps/tauri,axodotdev/cargo-dist,bitwarden/clients}`
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` and `…+is:pr+is:open`
- `GET https://api.github.com/repos/<o>/<r>/commits?per_page=8`; `…/issues?state=all&sort=created&direction=desc&per_page=100`; `…/issues/<n>/comments`; `…/contents/.github/workflows/…`
- `GET https://api.github.com/repos/rustsec/advisory-db/contents/crates/<name>`; `https://rustsec.org/packages/<name>.html`
- `https://static.crates.io/crates/<n>/<n>-<v>.crate` for `inquire-0.9.4`, `dialoguer-0.12.0`, `crossterm-0.29.0`, `console-0.16.6`, `demand-2.1.0`, `cliclack-0.5.6`
- `https://static.rust-lang.org/dist/channel-rust-stable.toml`; `https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md`
- `https://rust-cli.github.io/book/searchindex.json`; `https://rust-cli.github.io/book/in-depth/human-communication.html`; `https://blessed.rs/crates`
- `https://raw.githubusercontent.com/ast-grep/ast-grep/main/crates/cli/Cargo.toml`

**Method notes.** Figures came from `GET https://crates.io/api/v1/crates/<name>`
(`crate.recent_downloads`, `crate.downloads`) and `…/versions` (newest entry with
`yanked: false`); repository figures from `GET https://api.github.com/repos/<o>/<r>`
(`stargazers_count`, `archived`, `pushed_at`); open-issue counts **only** from
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`), never `open_issues_count`; advisories from
`https://rustsec.org/packages/<name>.html` cross-checked against
`repos/rustsec/advisory-db/contents/crates/<name>`, with `atty` and `time` as
positive controls establishing that a 404 means "no advisory" rather than a broken
path; adopters from the crates.io reverse-dependency listings plus the adopters' own
`Cargo.toml`. Every behavioural claim about a crate was read from a tarball whose
sha256 was compared against crates.io's recorded checksum (four matched, listed in
E8). Both source repositories were read only through their programme pins.

**What could not be verified, stated as gaps rather than filled.**

1. **Nothing was executed against a Rust template**, because none exists. All nine
   acceptance criteria and all ten P-checks are **proposed**. In particular the two
   claims a reviewer would most want proven — that a gated run never opens `/dev/tty`,
   and that `^C` mid-prompt reaches exit `130` through `RSLB903` — were derived from
   source, not observed. R67 recorded the same gap for the same reason.
2. **Gates 4 and 6 were not applied to `cliclack`, `demand`, `promkit` or
   `requestty`.** The first two were excluded on contract fit before the gates would
   have mattered; the last two were not shortlisted. Recorded as `unverified`, not
   assumed either way.
3. **Issue responsiveness was measured for `inquire` and `dialoguer` only.** For
   `crossterm`, `console`, `cliclack` and `demand` the maintenance verdict rests on
   commit recency, push date, release history and open-PR flow, without a
   response-time median.
4. **Binary-size cost is qualitative**, as gate 6 permits: package counts and crate
   character are given, and no byte figure was measured, because there is no binary to
   measure.
5. **`inquire`'s CI declares `MSRV: 1.82.0` while the published 0.9.4 manifest
   declares `rust-version = "1.80.0"`.** The discrepancy is reported, not reconciled;
   both are far below the 1.96 floor, so it changes no gate result.
6. **The `promkit` and `requestty` reads are shallow** — registry and repository
   metadata plus a one-line characterisation of their programming model. Neither
   tarball was downloaded.
