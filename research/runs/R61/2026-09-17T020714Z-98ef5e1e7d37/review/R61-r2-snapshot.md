# 2026-09-17 — R61 — interactive-prompts (bundle, Focused) — decision (revision 2)

Item R61 (`interactive-prompts`, kind `bundle`, Focused tier; the prompt's `## Couplings` carries an empty `- owns:` line and an empty `- consumes:` line, so this item registers no parameter and consumes none). Run `research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37`. Two engines, no Doxa.

Inputs read for this decision: `inputs/prompt.md` (binding), `inputs/PARAMETERS.md`, the live registry `docs/port/PARAMETERS.md`, the published prerequisite `research/topics/67-error-and-exit-code-contract/DECISION.md` (R67, owner-accepted), `raw/codex.md` (Codex, model `gpt-5.6-terra`, sha256 `a22fcc08990a3db262b3c950447646fac3d0293d284e55b484e2233320444f2e`) and `raw/opus.md` (Claude Opus 5, sha256 `162d21eddec4acbf60828bc9e92adc353c3bbc983c2e079b7ee35a199b323fa7`). The synthesizer produced neither raw report.

**Dates.** The run identifier `2026-09-17T020714Z` is a UTC instant and 2026-09-17 (UTC) is the date on this decision. The two raws disagree by one day for the same reason: the Codex raw stamps its retrievals 2026-09-16 (host local time), the Opus raw stamps them 2026-09-17 (UTC). They are the same calendar day in UTC terms for every figure both report, and every figure this decision cites was re-retrieved by this synthesizer's own check, in the run that recorded `2026-09-17T05:43:30Z` (retained byte-for-byte as `review/evidence/r61-claims-r1.log`; committed as `r61-claims.log` at `da52246c`).

**Evidence.** `review/evidence/r61-claims.sh` (shellcheck-clean; `set -o pipefail`; 97 named assertions, each on content, counting its failures and exiting with that count), its output `review/evidence/r61-claims.log`, and `review/evidence/r61-claims-rerun.diff`, the diff between two consecutive runs of that script. `review/evidence/r61-claims-r1.log` is the revision-1 run's log, kept unchanged because the figures table under `## Decision` and the case B row below were read from it. `## Empirical check` records the toolchain, the command, the working directory, the observed output, and the rerun-and-diff comparison rule.

**Revision 2 (2026-09-23 UTC; 2026-09-22 Pacific).** Revision 1 (sha256 `3131e895187c096c8866f0f7b4a520549804cd67b32f848b6239cd652b636281`, preserved byte-for-byte at `review/R61-r1-snapshot.md`) was approved by the empirical audit `review/audit-claude.md`. That audit's rerun exited 5, so revision 2 repairs only what blocked a clean rerun. It changes no recommendation, parameter, figure or passing claim. (1) Check `C15a` no longer counts the owner's own acceptance row for R61 in `docs/port/OWNER-ACCEPTANCES.md`; that row quotes OV-02 and was added after revision 1. (2) Checks `C13c`–`C13f` (case B) record an explicit environmental SKIP, with its reason, when the seat is refused a pseudo-terminal (`openpty` `EPERM`). (3) The retrieval instant in `**Dates.**` is corrected from `05:23:18Z`, which neither retained run recorded, to `05:43:30Z`. (4) The result, toolchain, case B, section 15 and rerun-diff sentences under `## Empirical check` now carry revision 2's rerun, and the revision-1 log is kept as `r61-claims-r1.log`. `## Engines` is unchanged. Its `C15a` scope phrase, "outside this item", already covers R61's own acceptance row.

**The org CLI Design Standard binds.** Version 1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` in `smorinlabs/cli-standards`, per the owner ruling of 2026-09-14 (`docs/port/OWNER-REVIEW.md`, "the CLI Design Standard binds, and OV-01 is refused"). Every `:<line>` citation below is a line of that blob, read this run with `git -C /Users/stevemorin/c/cli-standards cat-file blob f9de0437…` and asserted to hash `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f` (check `C8a`).

**Licence gate.** Fitness gate 1 is recorded as `inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate (`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check…"). Declared licence strings appear below as observed fact only. **Nothing is excluded, preferred or ranked on licence.**

---

## Decision

**Adopt one interactive-prompt crate, in the CLI binary crate only, behind a template-owned trait, with the interactivity gate owned by the call site.** The bundle has three members:

| # | Member | Selection | Where it goes |
|---|---|---|---|
| 1 | Prompt widgets — confirm, free value, single choice, multi-select | **`inquire = { version = "0.9.4", default-features = false, features = ["crossterm", "macros"] }`** | the CLI binary crate's `[dependencies]`, and nowhere else |
| 2 | Terminal back-end, and the typed `^C` that makes R67's `RSLB903` reachable | **`crossterm` 0.29.0**, reached **only** through `inquire`'s `crossterm` feature | transitive; never a direct dependency line |
| 3 | The interactivity gate | **`std::io::IsTerminal`** — a stabilized standard-library trait, no crate | the CLI binary crate, one function, called before any prompt type is constructed |

The swap point is a template-owned `trait Prompter: Send + Sync` in the CLI crate, with a production `InquirePrompter` — the only file in the template that names `inquire` — and a `ScriptedPrompter` test double that needs no terminal.

**Ranked runner-up: `dialoguer = { version = "0.12.0", default-features = false }`.** It is a close second and wins two axes outright (dependency cost and maintainer activity, both measured below). It loses on the two questions the prompt marks HIGH and on one R67 obligation, and the `Prompter` seam is what makes that a one-file contingency rather than a reason to lead with it. `### Principles and implementation` argues the choice; `## Engines` records that the Codex engine reached the opposite conclusion and what settles it.

**Prompt shapes, one per ledger row:**

| Ledger row | Shape | `inquire` type | Call |
|---|---|---|---|
| F276 | yes/no confirm before a destructive write | `Confirm` | `Confirm::new(msg).with_default(false).prompt_skippable()` |
| F279 | guided free value during `config init` | `Text` (free string) or `CustomType<T>` (a value that must parse) | `.with_default(current).with_validator(…).prompt_skippable()` |
| F279 | guided value over a closed set — py's `click.Choice` branch | `Select` | `Select::new(key, allowed).prompt_skippable()` |
| F280 | multi-select over already-fetched results | `MultiSelect` | `MultiSelect::new(msg, choices).prompt_skippable()` |

Every call site uses `prompt_skippable()`, never `prompt()`, so ESC returns `Ok(None)` instead of `Err(OperationCanceled)` (verified: `src/prompts/confirm/mod.rs`, checks `C5c`/`C5d`). `Ok(None)` (backed out with ESC) and `Ok(Some(vec![]))` (submitted with nothing ticked) are treated identically on the multi-select: a notice on stderr, nothing on stdout, exit `0`.

**This decision is a proposal validated in the implementation phase** (owner ruling, 2026-09-10). It records what this research found and what it recommends; P03 builds the template and its CI proves the recommendation. If implementation contradicts it, the decision is revised against this recorded research rather than researched again from scratch. Everything not yet proven, and what would prove it, is enumerated under `## Engines`.

**Ledger rows settled.** `F276` (interactive yes/no confirmation prompt for destructive actions, area `cli-framework-ux`, origin `py-only`, verdict `DIVERGENT`, item R61), `F279` (interactive guided value prompt, `py-only`, `DIVERGENT`, R61), `F280` (interactive multi-select prompt over fetched results, `ts-only`, `DIVERGENT`, R61) and `F360` (`--no-input` behaviour when a prompt would have been shown, origin `different`, `DIVERGENT`, R61 — split from F275 at the Phase 4 review). This decision names the Rust realization of all four. It changes no row's verdict and edits no ledger, index or registry file.

**Rows preserved, not redesigned.** `F277` (`--dry-run`) and `F278` (`-y`/`--yes`) are plain `ADOPT` mutation-safety flags (`docs/port/COMMONALITY.md`, checks `C16c`/`C16d`). Both remain plain booleans read by the command before any prompt type is constructed; neither needs a bypass hook inside a prompt crate and neither candidate crate offers one. `F275` (the `--no-input` flag itself) is `COMMON → REUSE` and assigned to no research item; this decision consumes that flag through R60's `GlobalArgs` and declares no new flag.

### The interactivity gate, and why it cannot be delegated to the crate

**The gate, stated once.** One predicate, three inputs, evaluated at the call site before any prompt type is constructed:

```
interactive(g) = !g.no_input
              && std::io::stdin().is_terminal()
              && std::io::stderr().is_terminal()
```

`stdin` because that is the file descriptor R8.1 names ("when stdin is a TTY", `:456`) and the one whose non-TTY-ness triggers the `/dev/tty` fallback below. `stderr` because that is where a prompt renders (R7.1 at `:381`: "fd 2 (stderr) carries everything else: diagnostics, progress, **prompts**, warnings, and errors"), and a prompt drawn into a redirected stderr is a prompt nobody can answer. This is the same conjunction the TypeScript port already computes at `ts: src/commands/projects.ts:146` (pin `cb1cbcb2`), so the principle is preserved at the same level with the same three inputs in both ecosystems.

**Why the gate is the template's and not the crate's — observed, not inferred.** Both terminal back-ends in this field open the *controlling terminal* directly when stdin is not a terminal:

- `crossterm` 0.29.0 `src/terminal/sys/file_descriptor.rs`, `tty_fd()`: uses `STDIN_FILENO` only when `libc::isatty(libc::STDIN_FILENO) == 1`, and otherwise `OpenOptions::new().read(true).write(true).open("/dev/tty")?`. `enable_raw_mode()` in `src/terminal/sys/unix.rs` is built on it (`let tty = tty_fd()?;`). Checks `C3a`–`C3d`.
- `console` 0.16.6 `src/unix_term.rs`, `Input::unbuffered()`: uses `io::stdin()` when `is_a_terminal(&stdin)`, and otherwise opens `/dev/tty`. Checks `C3e`/`C3f`.

`dialoguer` carries the closest thing to a built-in guard — `if !term.is_term() { Err(NotConnected) }` in `src/prompts/multi_select.rs` (check `C6b`) — but the `Term` it tests is the **output** terminal (stderr), not stdin, so the pipe case slips past it.

This decision does not rest on reading that code. **It was executed** (`## Empirical check`, section 13; checks `C13a`–`C13f`). A throwaway binary outside this repository called `crossterm::terminal::enable_raw_mode()` and `console::Term::stderr().is_term()` — the exact predicate `dialoguer` tests — under two conditions, with stdin redirected from `/dev/null` in both. Case B executed in the revision-1 run (`review/evidence/r61-claims-r1.log`). The revision-2 rerun's seat is refused a pseudo-terminal (`openpty` errno 1, `EPERM`), so that run records `C13c`–`C13f` as SKIP with that reason and a pty-capable seat should re-run case B:

| Condition | `stdin_is_terminal` | `dialoguer`'s guard, `Term::stderr().is_term()` | `crossterm::enable_raw_mode()` |
|---|---|---|---|
| **A** — no controlling terminal (negative control) | `false` | `false` | `Err`, `raw_os_error = Some(6)` (`ENXIO`) |
| **B** — a controlling PTY present | `false` | **`true`** | **`Ok` — a terminal was acquired** |

Case B is the finding. With a human's terminal attached and stdin coming from a pipe or a file, `dialoguer`'s own guard says "go ahead" and `crossterm` acquires the terminal anyway. That is exactly the behaviour R8.1 forbids at `:456` — "Tools **SHOULD NOT** open `/dev/tty` or another controlling terminal for surprise prompts when stdin is not a TTY" — and **no candidate crate prevents it**. The gate is therefore a member of this bundle, not an implementation detail, and the choice of crate does not change that.

**Precedence, which settles the prompt's LOW question.** `--yes` is read before the gate, and the gate before the crate:

```
if global.yes          -> proceed; no prompt type is constructed        (F278 bypass)
else if !interactive   -> the class rule below                          (F360)
else                   -> construct the prompt                          (F276 / F279 / F280)
```

`--dry-run` (F277) is evaluated by the command **after** consent is obtained and before the write, exactly as py does at the pin (`py: src/py_launch_blueprint/cli/commands/config.py:180-183`, which renders `[dry-run] would set …` and returns). Both flags compose by the prompt never being reached; neither needs a crate-side bypass.

### F360 — one rule per prompt *class*, and it fits all three repositories

py and ts disagree today: py raises a `ConfigError` unless `--yes` (`py: src/py_launch_blueprint/cli/options.py:265-278` at pin `b08bccfb`), ts skips the prompt and selects every fetched result (`ts: src/commands/projects.ts:146,166-168` at pin `cb1cbcb2`). `docs/port/DIVERGENCE-ANALYSIS.md:199` marks this item `harmonize = partly`. The two behaviours stop conflicting once the prompts are classified, because R8.2's `MUST` is scoped to "required non-auth input **or consent**" (`:461`) and only two of the three prompts carry either:

| Class | This template's example | Required input or consent? | Rule for py, ts and rs | Standard |
|---|---|---|---|---|
| **Consent** | the overwrite confirm before `config set` writes (F276) | consent, explicitly | **Refuse.** No mutation; exit `2`; `RSLB205`; hint "pass `--yes` to confirm non-interactively". `--yes` supplies the consent | R8.1 `:456` — "Under `--no-input` with no required bypass flag, the command **MUST** fail rather than guess" |
| **Required value** | the `config init` guided values (F279) | required input | **Refuse.** Exit `2`; `RSLB205`; hint naming the flag-based path. `--yes` accepts the already-resolved defaults, which is py's own non-interactive path (`py: config.py:82-83`, `if assume_yes: chosen = current`) | R8.5 `:472` — "Under `--no-input`, they **MUST** fail rather than prompt" |
| **Narrowing** | the multi-select over already-fetched projects (F280) | **neither** | **Proceed with the complete, unnarrowed result**; emit every row; exit `0` | R8.2 `:461` is engaged by *missing* input ("it uses provided flags/env or fails"); nothing is missing here |

The single cross-repo rule: **refuse when the missing answer is consent or a required value; proceed with the complete result when the missing answer only narrows output.** py implements the first two classes and has no third; ts implements the third and has no first two; neither repo needs a behaviour change to satisfy the rule, which is the strongest available outcome for a `harmonize = partly` item. rs is the only repo that ships all three, so rs is where the rule becomes visible. Propagating the *wording* to py's and ts's documentation is the follow-on project, not a change this decision makes.

**The narrowing rule carries a scope condition, and it is load-bearing.** "Proceed with everything" is correct **only because F280's selection subsets output the command already holds and would otherwise print in full**. A future multi-select whose result feeds a mutation — selecting which resources to delete, say — is consent by another name, and takes the refuse-with-`RSLB205` rule instead. This condition is the disposition of the Codex raw's `BASELINE-REVIEW: F360` line (see `## Engines`, Disagreement 4): the concern it names is real and is honoured as a boundary on the rule rather than as a change to F280's behaviour.

### OVERRIDE (OV-02) — a declined confirm exits `0` in rs, where py exits `5`

**Numbering.** OV-01 is taken: it was requested on 2026-09-12 as a waiver of the standard's R4.6 for R60 and **refused** by the owner on 2026-09-14, retired-as-refused rather than deleted (`docs/port/OWNER-REVIEW.md`, check `C15b`; `research/topics/60-cli-parsing-framework/DECISION.md`, "RETIRED OVERRIDE (OV-01)", check `C15c`). OV-02 is the next free number and is used by no other published decision or port document (check `C15a`, a scoped search over `docs/port/` and every `research/topics/*/DECISION.md` outside this item). The Opus raw wrote this same override as "OV-01"; it is renumbered here, and `## Engines` records that.

**This is an `OVERRIDE (OV-nn)` in the AGENTS.md sense** — a departure from a recorded source pattern, argued with options — and **not** the ledger verdict `COMMON → OVERRIDE (OV-nn)`, which is legal only for origin `same`. F276's verdict stays `DIVERGENT` and no ledger file changes. This is the same sense in which R60's OV-01 was a departure from the standard rather than from a `same` row.

**Argument:** py maps a refused overwrite to `SystemExit(int(ExitCode.INTERRUPT))` with `ExitCode.INTERRUPT = 5` and error code `PLBP004` (`py: src/py_launch_blueprint/cli/commands/config.py:193-203`; `py: src/py_launch_blueprint/core/errors.py:45,55`, at pin `b08bccfb`, quoted from the Opus raw's reading of the pin). rs cannot copy the integer. **Under R67's published taxonomy, exit `5` means conflict/precondition failed** (`RSLB501`; check `C16i`), so reusing py's integer would label a user's deliberate "no" as a precondition failure. R67's catalogue is stable and append-only and carries no "declined" row; adding one is out of scope for this item and would be a `CONFLICT:` escalation. The standard is silent: R8.1 requires the confirmation to exist and to be bypassable and says nothing about the refusal's exit code. The template's own precedent points the other way: ts treats the analogous "user selected nothing" as success with a stderr notice (`ts: src/commands/projects.ts:170-174`). A refusal is the confirmation *working*: stdout stays byte-empty, the mutation does not happen, a stderr notice says so, and a script that needs to know whether the write happened reads the write's own output rather than a failure code.

**Which R67 row the declined-confirm outcome maps onto.** It maps onto R67's **exit taxonomy** row `0` **success**, and onto **no `RSLB` catalogue row at all**. R67's catalogue rows are error codes carried in the stderr envelope `{"error":{"code","message","hint"?}}`; a declined confirm emits no envelope, so it has no code. The nearest catalogue row — the one py's integer would land on — is `RSLB501` conflict/precondition failed → 5, and that meaning is wrong for a deliberate refusal. `docs/error-codes.md` gains no row from this decision.

**Options:**
- **(a) exit `0` with a stderr notice — chosen.** Needs no new R67 row; consistent with ts's empty-selection rule and with R67's stdout-clean requirement; a refusal is not an error.
- (b) exit `1` (`RSLB000`, the unexpected sentinel) — makes "the user said no" indistinguishable from "something broke". Rejected.
- (c) exit `5` (`RSLB501`) to match py's integer — reuses a code whose published meaning is "conflict/precondition failed". Rejected: it would corrupt R67's taxonomy to preserve a coincidence of digits.
- (d) add a new R67 catalogue row for "declined" — out of scope for this item, and a `CONFLICT:` escalation. Not needed, because (a) requires no row.

Cost if wrong: one match arm and one documented line. No code, no catalogue change, no ledger change.

### Every prompt outcome, mapped onto R67's published catalogue

Every failure this item can produce is expressible with a row R67 already publishes, which is why **this decision raises no `CONFLICT:` line**.

| Outcome at the call site | R67 row | Exit | Why that row |
|---|---|---|---|
| Gate false (`--no-input`, or stdin/stderr not a TTY) with no `--yes`, **consent** or **required-value** class | `RSLB205` | 2 | R67 words `RSLB205` "required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin", which is all three of this item's triggers verbatim (check `C16e`) |
| Gate false, **narrowing** class | — | 0 | Success path; no error row is used |
| `Err(InquireError::NotTTY)` — raw mode refused (`ENOTTY`/`ENXIO`) | `RSLB205` | 2 | The same condition reached one layer later; the gate should have caught it, so this arm is defence in depth. **Class-scoped like the gate**: `RSLB205`/2 for consent and required-value, fall back to the complete result and `0` for narrowing, so the two paths cannot disagree about one command |
| `Err(InquireError::OperationInterrupted)` — `^C` | `RSLB903` | 130 | R67 defines `RSLB903` "prompt interrupted by Ctrl-C → 130" and requires the chosen crate be adapted to it without leaking the crate's own error text (check `C16f`) |
| `Ok(None)` from `prompt_skippable` (ESC), or `Ok(false)` from `Confirm` | — | 0 | OV-02 above: stderr notice, no mutation. On the narrowing prompt an ESC is treated exactly like an empty selection |
| `Err(InquireError::OperationCanceled)` — ESC reaching a plain `prompt()` | — | 0 | Same outcome. Every call site here uses `prompt_skippable()`, so this arm should be unreachable; it is written anyway so the match over `InquireError` is exhaustive and a future non-skippable call cannot fall through to `RSLB000` |
| `Ok(vec![])` from `MultiSelect` | — | 0 | Empty selection is a graceful no-op; ts parity |
| `Err(InquireError::IO(e))` | `RSLB101` | 1 | Ordinary I/O failure |
| `Err(InquireError::InvalidConfiguration(_))` or `Err(Custom(_))` | `RSLB000` | 1 | Programmer error; the unexpected sentinel |

**R67's no-prompt-local-handler rule is satisfied by construction.** R67 rules that "No prompt-local Ctrl-C handler may be installed — it would race the process-level contract and can produce duplicate output" (check `C16h`). `inquire` installs no signal handler; with the `crossterm` back-end the terminal is in raw mode for the prompt's duration, so the line discipline generates no `SIGINT` at all and `^C` arrives as an ordinary key event that the prompt loop turns into a typed value — `src/prompts/prompt.rs`, `Action::Interrupt => return Err(InquireError::OperationInterrupted)` (check `C5b`). That rule is also what rules out the `demand` candidate on contract fit (below).

**ESC and `^C` must stay distinguishable.** R67 explicitly leaves this "a product question for R61", and this item answers it: they are different outcomes (`0` versus `130`), so a crate that collapses them cannot serve. `inquire` separates them in the same loop — `Action::Cancel` → `OperationCanceled`, `Action::Interrupt` → `OperationInterrupted` (checks `C5a`/`C5b`).

### Colour, and the R65 coupling

`inquire`'s `RenderConfig::default()` consults one environment variable and nothing else, `NO_COLOR` (check `C5h`). R65 resolved a multi-tier colour chain for this template, so letting `inquire` decide would put a second, shorter colour policy in the same binary. The template passes an explicit `RenderConfig` through `with_render_config` — `RenderConfig::empty()` when R65's resolved answer is "no colour", `RenderConfig::default_colored()` when it is "colour". `inquire`'s own documentation states the consequence ("When overriding the config in a prompt, `NO_COLOR` is no longer considered"), which is the intent: R65's chain already accounts for `NO_COLOR`. This is a design note, not a `CONFLICT:`; R65's parameter value is unchanged and unconsulted here.

### Principles and implementation

**The shared requirement.** Across `py-launch-blueprint`, `ts-launch-blueprint` and `rs-launch-blueprint`:

> A command that needs consent, a required value, or a narrowing choice asks a human for it **only when a human is demonstrably there**, asks on stderr, and behaves predictably and documentedly when a human is not there.

**Its source, its agreement level, and what may vary.**

| # | Principle | Agreement level | Must agree across py / ts / rs | May vary per ecosystem |
|---|---|---|---|---|
| P1 | A destructive action confirms, and offers a non-interactive bypass | **standard** — R8.1 `MUST` (`:456`); ledger F276/F278 | that a confirm exists; that `--yes`/`-y` is the consent bypass; that under `--no-input` with no bypass the command **fails rather than guesses** | which library renders the y/n line; the wording |
| P2 | Prompts render on stderr; stdout carries only the requested result | **standard** — R7.1 (`:381`), restated by R8.1 (`:456`) | that no prompt byte reaches stdout | whether the library hard-wires stderr or accepts a stream handle |
| P3 | The tool is fully usable with no TTY and never blocks on a prompt when input is unavailable | **standard** — R8.2 `MUST` (`:461`) | that a headless run terminates with a defined outcome, and that the outcome is exit `2` when required non-auth input or consent is missing | which predicate detects "no human" |
| P4 | An interactive setup flow has a non-interactive path and fails under `--no-input` | **standard** — R8.5 (`:472`) | that `config init` is reachable with flags alone and refuses to prompt under `--no-input` | whether the flow is one prompt loop or several |
| P5 | Prompt cancellation is a defined outcome, not a panic or a stray exit code | **capability** — ledger F299, published by R67 as `RSLB903 → 130` | that `^C` mid-prompt ends the process at 130 | whether the library reports it as a typed value or as a raised signal |
| P6 | Selecting nothing is a graceful no-op, not an error | **capability** — ts `src/commands/projects.ts:170-174` at the pin | that an empty selection is success | the notice text |

What must **not** agree: the widget library, its key bindings, its theme, and the concrete type each prompt returns. Those are ecosystem mechanics.

**Is the shared architectural pattern still appropriate in Rust?** The pattern ts records is *prompt behind one injectable seam* — `Prompter` as a function type at `ts: src/lib/adapters.ts:22`, with `realPrompter` at `:41` importing `@inquirer/prompts` dynamically so non-interactive runs never load the prompt stack. In Rust, yes, and more strongly. The template already has the shape as a decided parameter: R01 fixed `http-transport-injection-seam` as a dyn-compatible trait erased at the composition root. A `trait Prompter: Send + Sync` in the CLI crate, with `InquirePrompter` in production and a `ScriptedPrompter` in tests, is that same shape one layer out, and it buys three things this item specifically needs: the prompt crate never appears in the library crate's dependency graph (which R67's layering rule requires, and which the web surface requires because there is no terminal there); the whole confirm/value/select surface becomes testable with no pseudo-terminal; and, because this category has no first-party option and the recommended crate's maintenance is its weakest figure, **the crate choice becomes reversible at one file**.

**Landscape — the three-bin map, and the one fact that shapes the decision.**

| Bin | Members found | Evidence |
|---|---|---|
| **Built-in / first-party toolchain** | `std::io::IsTerminal` (a TTY predicate) and `std::io::stdin().read_line()` (a line read) — **no prompt widget of any kind** | `IsTerminal` stabilized in Rust 1.70.0 (2023-06-01), `rust-lang/rust` `RELEASES.md`. The Rust CLI working group's book names no prompt crate: its search index contains zero occurrences of `dialoguer`, `inquire`, `requestty` or `prompt` (`https://rust-cli.github.io/book/searchindex.json`, counted by the Opus raw, retrieved 2026-09-17) |
| **Established industry standard** | `inquire` 0.9.4, `dialoguer` 0.12.0; back-ends `console` 0.16.6 and `crossterm` 0.29.0 | figures below. `blessed.rs` lists exactly one crate under "Interactive prompts" — `inquire` — and does not list `dialoguer` at all (`https://blessed.rs/crates`, Opus raw, 2026-09-17) |
| **Up-and-comer** | `cliclack` 0.5.6, `demand` 2.1.0, `promkit` 0.17.0, `requestty` 0.6.3 | figures below; `promkit` is a prompt *toolkit* rather than a widget set and `requestty`'s last release is 2025-12-02, so neither was shortlisted |

The first bin's emptiness is the consequential landscape fact. There is no `std` type, no `rustup` component and no Rust-project-blessed prompt widget, so a template that wants a multi-select must take a third-party dependency or write a terminal state machine itself. That makes maintenance and swap cost first-order design inputs rather than footnotes, and it is why the crate sits behind a trait.

**Authorities, and why each counts.** The org CLI Design Standard at the pinned blob (org-locked and binding on this port by the 2026-09-14 owner ruling) supplies the acceptance criteria rather than preferences. `rust-lang/rust`'s own `RELEASES.md` establishes `IsTerminal`'s availability. The Rust CLI working group's book is the closest thing to first-party CLI guidance and is used here for *negative* evidence, verified by searching its index rather than by failing to notice a mention. `blessed.rs` is widely cited independent curation organized by use case. Each crate's own source, read from a tarball whose sha256 was compared against crates.io's recorded `version.checksum` (six of six matched, checks `C2-*`), settles every behavioural claim. crates.io and the GitHub REST API supply every figure. No blog post is used as an authority anywhere in this decision.

**Practice evidence — well-regarded projects, with the evidence that they are well regarded.**

| Project | Stars (`GET https://api.github.com/repos/<o>/<r>`, `stargazers_count`, 2026-09-17) | Prompt crate declared | Source |
|---|---|---|---|
| `ast-grep/ast-grep` | 15,932 | **`inquire = "0.9.0"`**, in the same manifest as `clap = { version = "4.5.4", features = ["derive"] }` and `clap_complete = "4.5.2"` | `https://raw.githubusercontent.com/ast-grep/ast-grep/main/crates/cli/Cargo.toml`, re-read this run (checks `C11a`/`C11b`) |
| `bitwarden/clients` (ships `bitwarden-cli`) | 13,792 (Opus raw) | `inquire` | crates.io reverse-dependency listing |
| `tauri-apps/tauri` (ships `tauri-cli`) | 111,123 (Opus raw) | `dialoguer` | crates.io reverse-dependency listing |
| `transact-rs/sqlx` (ships `sqlx-cli`) | 17,501 (Opus raw) | `dialoguer` | crates.io reverse-dependency listing |
| `cargo-generate/cargo-generate` | 2,487 (Codex raw) | `dialoguer = "~0.12"` | `cargo-generate` root `Cargo.toml` (Codex raw) |
| `wasm-bindgen/wasm-pack` | 7,283 (Opus raw) | `dialoguer` | crates.io reverse-dependency listing |

Reverse-dependency totals, same endpoints: `dialoguer` 2,356, `inquire` 1,061 (both raws agree). Both are mainstream. `dialoguer` is the older and broader; `inquire` is the one the newer curation recommends and the one the highest-profile *newer* CLI in the survey declares. `ast-grep` is doubly relevant here because it is the single manifest proving that R60's selected parser and this item's selected prompt crate ship together in an actively developed, widely used Rust CLI.

**Architectural alternatives, compared before libraries.**

| # | Architecture | What it gives | What it costs here |
|---|---|---|---|
| A | **No prompt dependency at all**: flags only; `config init` writes resolved defaults; the fetch command always emits every row | zero dependency; trivially headless | deletes F276, F279 and F280 outright. R8.1 permits a tool with no destructive command to skip confirming, but this template has `config set` overwriting an existing value, so the confirm is required. **Rejected** |
| B | **Hand-rolled**: `stdin().read_line()` for confirm and value; no multi-select | no new crate; roughly forty lines | cannot express F280 at all, and a line-based read cannot give the in-place retry `click.prompt` gives. **Rejected on the multi-select alone** |
| C | **Split**: hand-rolled confirm and value, a crate for the multi-select only | smallest crate surface for two shapes of three | two input models in one binary — raw-mode key events for the list, cooked line input for the rest — with two different cancellation stories. More code *and* a crate. **Rejected** |
| D | **One crate for all three shapes, behind a template-owned trait, gate owned by the call site** | one input model; one cancellation story; one swap point; a gate testable with no terminal | one dependency subtree. **Selected** |
| E | As D, but the gate delegated to the crate's own detection | less template code | **impossible as specified.** No candidate tests stdin, and both back-ends open `/dev/tty`. Rejected on the executed observation in the table above, not on a reading. **Rejected** |

**How the selected design preserves each principle.** P1: the confirm exists, `--yes` bypasses it before any prompt type is constructed, and the gate refuses rather than guesses. P2: `inquire`'s `crossterm` back-end constructs `IO::Std(stderr())` and the string `stdout` appears in **zero** files under `inquire-0.9.4/src` in any case (counted by `/usr/bin/grep -rilF`, case-insensitive, check `C5f`), and the `IO` enum that `CrosstermTerminal` writes through is crate-private with its only non-stderr variant constructed under `#[cfg(test)]` (checks `C5l`/`C5m`) — so no public API hands `inquire` a stream, and a shipped build offers no path by which a prompt byte reaches fd 1. That is a stronger guarantee than the explicit output-stream override ts needed, because `@inquirer/prompts` defaults to stdout and must be redirected. P3: the gate is a pure function of three booleans, so all four combinations are unit-testable with no terminal, and its refusal outcome is exit `2` via `RSLB205`. P4: `config init --yes` writes from resolved defaults with no prompt constructed; `config init --no-input` refuses. P5: `^C` is a typed value, not a raised signal, because the `crossterm` back-end holds the terminal in raw mode. P6: `Ok(vec![])` and `Ok(None)` both mean success with a stderr notice.

**Defaults, validation and retry — the prompt's MEDIUM question — are native, not built.** `Confirm` carries `with_default(bool)`, a default parser and a settable error message that is re-rendered in place when parsing fails. `Text` carries `with_default`, `with_initial_value`, `with_placeholder` and `with_validator`/`with_validators`. `CustomType<T>` adds `with_parser` and `with_error_message` over the same validator surface. Retry is in place and native: the loop in `src/prompts/prompt.rs` treats a failed `submit()` as "needs redraw", re-renders with the error message and keeps reading — `click.prompt`'s behaviour with nothing built by the template. (Read from the checksum-verified tarball by the Opus raw; this synthesizer re-verified the loop's two cancellation arms and `prompt_skippable`, checks `C5a`–`C5d`.)

**Fitness gates, answered per candidate before popularity was weighed.** Gate 2 is read **strictly**: a candidate that declares no `rust-version` has not cleared the bar, per the controller's withdrawal of the provisional lenient reading (`docs/planning/p02/execution-ledger.md`, "RULING WITHDRAWN: fitness gate 2 is read strictly"). That reading changes the Opus raw's result, and `## Engines` records it as a settled disagreement.

| Gate | `inquire` 0.9.4 | `dialoguer` 0.12.0 | `cliclack` 0.5.6 | `demand` 2.1.0 |
|---|---|---|---|---|
| 1 · Licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; observed only: `MIT` | same ruling; observed `MIT` | same ruling; observed `MIT` | same ruling; observed `MIT` |
| 2 · MSRV (policy floor **1.96**; stable **1.98.1**, 2026-09-01) | `rust-version = "1.80.0"` (check `C5i`); resolved-tree maximum **1.85.0** (`unicode-segmentation`), measured (check `C12d`); CI matrix runs an `msrv` job. **Pass** | `rust-version = "1.66"` (check `C6d`); CI pins a `1.85.0` toolchain job. **Pass** | **no `rust-version` key** (check `C7-cliclack-0.5.6`). **Fail** | **no `rust-version` key** (check `C7-demand-2.1.0`). **Fail** |
| 3 · Advisories; `unsafe` posture | `https://rustsec.org/packages/inquire.html` → **404** (check `C9-inquire`), with `atty` → **200** as the positive control (checks `C9-ctl`, `C9-ctl-body`): **no advisory**. Zero `unsafe` tokens in `inquire-0.9.4/src` (Opus raw); the `unsafe` in the subtree is `crossterm`/`libc`/`rustix`/`parking_lot` FFI | 404: no advisory; `unsafe` lives in `console` + `libc` | 404: no advisory; `#![forbid(unsafe_code)]` | 404: no advisory; `unsafe` FFI in `src/event.rs` |
| 4 · Builds and is tested on `ubuntu-latest, macos-latest` | CI matrix `["ubuntu-latest","macOS-latest","windows-latest"]` × `[msrv, stable]` (Opus raw, E15). **Pass**; Windows also covered, not required | CI matrix `[macos-latest, ubuntu-latest, windows-latest]` on stable plus a pinned-toolchain job (Opus raw, E15). **Pass** | not verified — gate 2 already failed | not verified — gate 2 already failed |
| 5 · Default features; async coupling | defaults `["macros","crossterm","one-liners","fuzzy"]` (checks `C5j`/`C5k`); **this stack takes `default-features = false, features = ["crossterm","macros"]`**. **No async runtime at any depth**, measured (check `C12e`) | defaults `["editor","password"]`, both dropped; no async | no async | no async |
| 6 · Binary size and compile time (qualitative, as the gate permits) | **the stack's main cost**; measured like-for-like below | **much cheaper**; measured like-for-like below | `console`-based, same order as `dialoguer` | `console`-based plus `signal-hook` |

**Excluded by gate.** `cliclack` 0.5.6 and `demand` 2.1.0 both fail fitness gate 2: neither manifest declares `rust-version`, so neither clears a bar the prompt requires every candidate to clear before popularity is weighed. Gates 4 and 6 were not applied to either and are recorded as `unverified` rather than assumed in either direction.

Each also carries a contract-fit finding that is recorded **separately, so the distinction from the gate is not lost**, and that would have excluded it even had gate 2 passed:

- **`demand` 2.1.0 installs a process-wide `SIGINT` handler for every prompt.** `src/ctrlc.rs` imports `signal_hook::{consts::SIGINT, iterator::{Handle, Signals}}` and holds the handle in a `static LazyLock<RwLock<…>>` (check `C7e`), and `src/multiselect.rs` calls into it. R67 rules in terms that no prompt-local Ctrl-C handler may be installed, so `demand` cannot be used without violating that rule.
- **`cliclack` 0.5.6 cannot distinguish ESC from `^C`.** `src/prompt/interaction.rs` maps `Key::Escape` and `Key::CtrlC` to the same `State::Cancel`, and turns that single state into a single `io::ErrorKind::Interrupted` (checks `C7c`/`C7d`). This template needs `0` for the first and `130` for the second (OV-02 and `RSLB903`), and no call-site logic can recover a distinction the crate erased. It is otherwise the most attractive up-and-comer — `#![forbid(unsafe_code)]`, `console`-based, and it reads keys with `read_key_raw()` so it never raises `SIGINT` from library code. Note the symmetry with ts: D-016(6) chose `@inquirer/prompts` over `@clack/prompts`; the Rust field reproduces the same pair, and this item reaches the same conclusion for a different and stronger reason.

**Registry and repository figures** (`GET https://crates.io/api/v1/crates/<name>` → `crate.recent_downloads`, `crate.downloads`; newest `versions[]` entry with `yanked: false` → `num`, `created_at`; `GET https://api.github.com/repos/<o>/<r>` → `stargazers_count`, `archived`, `pushed_at`; `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count`, never `open_issues_count`). Every number below was re-retrieved by this synthesizer on 2026-09-17 and is in `review/evidence/r61-claims-r1.log`, section 10 (the run at `2026-09-17T05:43:30Z`). The revision-2 log re-reads them; they moved only within the vary-by-design set under `## Empirical check`.

| Crate | 90-day downloads | All-time | Newest non-yanked | Stars | Archived | Pushed | Open issues | Open PRs |
|---|---|---|---|---|---|---|---|---|
| `inquire` | 4,978,577 | 20,585,265 | 0.9.4 (2026-02-24) | 2,626 | false | 2026-03-02 | 59 | 30 |
| `dialoguer` | 16,348,116 | 82,200,680 | 0.12.0 (2025-08-23) | 1,614 | false | 2026-09-16 | 71 | 28 |
| `crossterm` | 43,995,611 | 191,657,943 | 0.29.0 (2025-04-05) | 4,223 | false | 2026-09-14 | 170 | 76 |
| `console` | 80,406,869 | 349,775,351 | 0.16.6 (2026-09-10) | 1,195 | false | 2026-09-10 | 48 | 22 |
| `cliclack` | 1,036,365 | 3,429,371 | 0.5.6 (2026-08-10) | 367 | false | 2026-08-10 | 10 | 0 |
| `demand` | 256,972 | 593,441 | 2.1.0 (2026-08-25) | 258 | false | 2026-09-15 | 8 | 4 |

There is **no dominant choice** in this category, and it is reported as a two-horse field rather than as a leader with challengers: `dialoguer` leads on downloads and reverse dependencies, `inquire` holds the single curated recommendation and the more recent release.

**Maintenance, by the prompt's rubric.** `inquire` is **`at-risk`**, on three concrete signals rather than on release age alone: (i) its newest release and its newest commit are the same commit, `chore: release v0.9.4`, dated **2026-02-24** — roughly 6.7 months with no commit of any kind, re-read this run from `GET https://api.github.com/repos/mikaelmello/inquire/commits?per_page=1`, `.[0].commit.committer.date` (check `C10d`); (ii) **30 open pull requests** are queued behind that silence (check `C10e`); (iii) 7 of the 10 most recently opened issues have no maintainer reply at all, so the median days-to-first-maintainer-response is undefined over that window (Opus raw, E5, measured with `author_association ∈ {OWNER, MEMBER, COLLABORATOR}` and excluding the reporter). It is **not `dormant`**: there is no advisory, no maintainer notice of abandonment, and its CI builds on current stable. `crossterm` is **`stable-quiet`** — the 6-month release trigger fires (0.29.0, 2025-04-05) and is rebutted rather than confirmed: the repository was pushed 2026-09-14, 76 open PRs indicate flow rather than silence, and there is no advisory. `dialoguer` is **`active`**: pushed 2026-09-16, with an unreleased MSRV bump on master.

**The cost, measured like-for-like rather than asserted.** The Opus raw's headline comparison — 32 packages against 8 — compared unlike manifests: `inquire` alone against `dialoguer` *plus* R63's `indicatif`. This synthesizer re-measured with three manifests that differ **only** in the prompt crate, each carrying R63's `indicatif = "0.18"` and R67's `signal-hook = { version = "0.4.4", default-features = false }` (`## Empirical check`, section 12; checks `C12a`–`C12c`). Unique packages in the normal dependency tree for `x86_64-unknown-linux-gnu`, excluding the spike's own root package:

| Manifest | Packages | Marginal over the shared base |
|---|---|---|
| base: `indicatif` + `signal-hook` 0.4.4 | 9 | — |
| base + `inquire` (recommended features) | 35 | **+26** |
| base + `dialoguer` (`default-features = false`) | 11 | **+2** |

So the honest cost of this recommendation over its runner-up is **24 additional packages** in a template that is copied and then audited by its users. That is the strongest argument for `dialoguer` and it is not minimized here. The added weight is `crossterm` and its subtree: two proc-macro chains (`derive_more`/`derive_more-impl`/`convert_case`, and `document-features`/`litrs`), plus `mio`, `parking_lot`, `rustix`, `signal-hook` and `signal-hook-mio`. `syn`/`quote`/`proc-macro2` are already present through R60's `clap` derive and R66's `serde` derive, so they are not marginal. No binary-size figure is claimed: gate 6 permits a qualitative answer and there is no binary to measure.

**Why the recommendation is still `inquire`, stated as a tradeoff and not as a sweep.** Three things that `dialoguer` cannot supply, against a cost of 24 packages that it can:

1. **The multi-select's name/value question, which the prompt marks HIGH.** `inquire`'s `MultiSelect::prompt()` returns `Vec<T>` — the selected **values** (check `C5g`) — with `T: Display` supplying the name, which is Rust's expression of ts's `Choice{name,value}` pair; `raw_prompt()` returns `Vec<ListOption<T>>` carrying `{index, value}` when position matters too. `dialoguer`'s `MultiSelect::interact()` returns `Vec<usize>`, indices into the list (check `C6a`), so the caller re-indexes to recover the domain value. That works, and the Codex raw argues positively that indices keep display text out of the domain type; it is nonetheless a weaker answer to the question actually asked.
2. **The output-stream half of the same HIGH question.** ts needed `{ output: process.stderr }` because `@inquirer/prompts` defaults to stdout. `inquire` exposes no way to select the stream: its `src` names `stdout` in zero files even case-insensitively, and its `IO` enum is crate-private with the non-stderr variant test-gated (checks `C5f`, `C5l`, `C5m`). `dialoguer` answers it the way ts did, with an explicit `Term` handle; both pass, `inquire` by construction.
3. **R67's `RSLB903`.** `dialoguer` reads keys with `console`'s `read_single_key`, which on `^C` **raises `SIGINT` to the process itself** — the source says so in a comment (checks `C4a`/`C4b`). That is not forbidden: it defers to the process-level contract rather than racing it, and R67's `RSLB901`/130 would catch it after `console` restores the original termios. But it leaves `RSLB903` unreachable, which is precisely the branch R67's own re-verify trigger names — "`RSLB903` is wired to a typed variant **or retired** before first release". Choosing `dialoguer` is choosing the "retired" half, and that is a published decision's contract changing to accommodate a dependency.

A reviewer who weights template dependency weight or maintainer responsiveness above the `RSLB903` mapping should reach `dialoguer`; the runner-up is written so that the swap is a one-file change with its consequence stated up front, and the re-verify triggers below fire on exactly the signals that would flip it.

**Why the `crossterm` back-end and not `console`.** `inquire` offers both. With `console` behind `inquire`, `^C` becomes a raised `SIGINT` and `RSLB903` becomes unreachable — `inquire`'s own error documentation says so, and `console`'s source is quoted above. Choosing `console` would save roughly fifteen packages and reuse the `console` that R63's `indicatif` already pulls, and cost `RSLB903`. Take it only if the workspace's compile time becomes a *measured* problem **and** the owner accepts retiring `RSLB903`. The feature string is therefore load-bearing and must be documented as such, so a future "trim the tree" pass does not silently swap it.

**The one interaction with an already-published decision, measured.** R67 selected `signal-hook = { version = "0.4.4", default-features = false }` under `[target.'cfg(unix)'.dependencies]`; `crossterm` 0.29.0's default `events` feature requires `signal-hook` 0.3.x. Resolving both together produces **exactly one duplicated package** (checks `C12f`–`C12h`): `signal-hook` v0.3.18 (via `crossterm`, and via `signal-hook-mio`) beside `signal-hook` v0.4.4 (direct). It is benign — both majors depend on `signal-hook-registry ^1.4` and resolve to the same registry crate, so there is one handler table; `crossterm` registers only `SIGWINCH`, a signal R67 does not handle; and R67's `SIGINT`/`SIGTERM` flags are untouched. It is nonetheless a duplicate the workspace did not have, where R67's own evidence recorded zero. The `dialoguer` manifest resolves with **no** duplicates (check `C12i`). If the template later adopts a `cargo deny` "no duplicates" rule, this is the row that needs an allowance.

**Interaction with R63 and R66.** R63 selected `indicatif`, which brings `console` 0.16.6; with this bundle the binary carries both terminal libraries, `console` for the spinner and `crossterm` for prompts. They do not conflict — a spinner and a prompt are never live at the same time, and ts already sequences them that way (stopping the spinner in a `finally` before the prompt) — but it is two terminal stacks in one binary, and it is the arithmetic that would favour the `console` back-end or `dialoguer` if compile time ever becomes binding. R66 owns stdout's locked-handle writer; `inquire` writes only to stderr, so the two never contend for fd 1.

**Performance.** No like-for-like benchmark was found or run, and none is claimed. Prompt latency is dominated by human input, so no throughput claim follows from download counts; the relevant cost is dependency and compile footprint, measured above as package counts with the workload (a `cargo generate-lockfile` plus `cargo tree -e normal` on three manifests differing in one line), the configuration (`x86_64-unknown-linux-gnu`, normal edges only, root excluded) and the instrumentation (`cargo tree`, `cargo metadata`) stated. No latency, throughput or byte figure is inferred from unlike benchmarks.

**Minimal realistic example** (proposed for P03; no Rust code exists in this repository and none was written):

```
crates/cli/src/prompt.rs         trait Prompter { confirm, value, choose_one, choose_many }
                                 struct InquirePrompter;   // the only file naming `inquire`
                                 struct ScriptedPrompter;  // test double, no terminal
crates/cli/src/interactive.rs    fn interactive(&GlobalArgs) -> bool   // the gate
crates/cli/src/commands/config.rs   init / set call sites
crates/cli/src/commands/project.rs  fetch -> choose_many call site
crates/cli/src/main.rs           the composition root builds InquirePrompter only when the gate
                                 is true and hands the command Option<&dyn Prompter>, so a
                                 non-interactive run has nothing to call
```

`ProjectChoice(Project)` implements `Display` as `"{name} ({workspace})"`: the *name* is the `Display` rendering and the *value* is the wrapped domain object `MultiSelect::prompt()` hands straight back.

**File-level changes in the template** (all proposed). One dependency line in `crates/cli/Cargo.toml`; nothing added to the library crate's manifest or the web surface's. Two new files, `prompt.rs` and `interactive.rs`. One `no_input` field on R60's `GlobalArgs` — that is F275's existing flag taking its place in R60's struct, not a new flag introduced here. Call-site wiring in `commands/config.rs` and `commands/project.rs`. One documentation page covering the three prompt classes, the `--yes`/`--no-input` matrix and the exit codes, because R8.5 requires the non-interactive path to be documented and R8.1 requires any `/dev/tty` behaviour to be documented — this template has none, and saying so is the documentation. `docs/error-codes.md` gains **no row**; `RSLB205` and `RSLB903` merely become reachable.

**Observable acceptance criteria.** A1–A9 are the contract. **None of them was executed** — the template does not exist and P03 builds it; `## Engines` lists them as unproven with what would prove each.

1. `rslbp config set k v2 < /dev/null` from a terminal, with `k` already `v1`: **no prompt appears on the controlling terminal**, exit `2`, the `RSLB205` envelope on stderr, `k` still `v1`.
2. The same command with `--no-input`: exit `2`, `RSLB205`, no write.
3. The same command with `--yes`: exit `0`, `k == v2`, **no prompt type constructed** — asserted by running under a `ScriptedPrompter` that panics if called.
4. The same command with `--dry-run --yes`: exit `0`, `[dry-run] would set …` on stderr, `k` unchanged.
5. `config init --no-input`: exit `2`, `RSLB205`. `config init --yes`: exit `0`, file written from resolved defaults, no prompt.
6. `rslbp project list --no-input -o json > out.json`: exit `0`, **every** fetched row present, no prompt bytes in the file.
7. On a pseudo-terminal, answering `n` to the overwrite confirm: exit `0`, notice on stderr, stdout byte-empty, no write (OV-02).
8. On a pseudo-terminal, `^C` during the multi-select: exit `130`, the `RSLB903` envelope on stderr, **no `inquire` error text** in it.
9. On a pseudo-terminal with stdout redirected to a file, any prompt: the file receives zero prompt bytes (R7.1).

Criteria 1, 2, 5 and 6 need no pseudo-terminal and are runnable in an ordinary CI job through built-binary invocations; 7, 8 and 9 need a PTY harness. The gate's four boolean combinations and the whole `InquireError` → `ErrorCode` mapping are unit-provable with no terminal at all, by constructing the variants directly — which is the point of the `Prompter` seam.

re-verify: 2026-12-17, or earlier on any of — `mikaelmello/inquire` reaching twelve months with no commit, detectable by `GET https://api.github.com/repos/mikaelmello/inquire/commits?per_page=1` → `.[0].commit.committer.date` staying older than twelve months (today it reads `2026-02-24T17:21:29Z`, asserted by check `C10d`, which fails the moment a newer commit lands and the `at-risk` verdict must be re-argued), or the maintainer posting a status notice — either sends this item to `dialoguer`; `https://rustsec.org/packages/<name>.html` returning **200** for any of `inquire`, `crossterm`, `console`, `mio`, `rustix` or either `signal-hook` major, where the atty control at `https://rustsec.org/packages/atty.html` still returns 200 (checks `C9-*`); `GET https://crates.io/api/v1/crates/inquire` → newest non-yanked `versions[].num` ceasing to be `0.9.4` (check `C10a`) **in a release that changes the `InquireError` variants, the back-end feature set or `RenderConfig::default()`'s environment behaviour**; `GET https://crates.io/api/v1/crates/dialoguer` → newest non-yanked `num` ceasing to be `0.12.0` (check `C10b`) **in a release shipping a value-returning multi-select or a typed `^C`**, either of which flips the ranking; the org CLI Design Standard moving off blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, detectable by check `C8a` failing its content hash, with an amendment to R4.2's `--no-input` row, R7.1, R8.1, R8.2 or R8.5 changing the substance as well; R67 being revised in a way that changes `RSLB205` or `RSLB903`, or that adds a "declined" row (which would retire OV-02); R63 or R58 changing the `console`/`indicatif` footprint enough to make the `console`-back-end arithmetic decisive against the 24-package gap measured by checks `C12a`–`C12c`; P03 measuring `cargo build --timings` on the built template and finding this subtree on the critical path of a full debug build on either runner; or Rust stable advancing far enough that the policy floor rises above 1.85.0, the highest declared `rust-version` anywhere in the resolved tree (check `C12d`), which at the current 1.96 floor leaves eleven minors of headroom and makes this trigger remote.

## Parameters

The prompt's `## Couplings` carries an empty `- owns:` line, so this item owns no registry parameter and there are no `- owns` lines (check `C14d`). Its `- consumes:` line is likewise empty, so there is no consumed registry parameter. **No `CONFLICT:` line** (check `C14e`): neither raw raised one, and nothing recommended here needs a registered value changed.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

The four lines above were generated from `docs/port/PARAMETERS.md` by the `awk` extraction in `review/evidence/r61-claims.sh` section 14 and diffed against this file; the diff is empty and its result is recorded in the log (check `C14c`). The same extraction was run against `inputs/PARAMETERS.md` and against the live registry, and those two are byte-identical to each other (check `C14b`).

How the four bear on the decision. **`msrv-policy`** is the single gate that excluded two of the four shortlisted candidates, read strictly: `cliclack` and `demand` declare no `rust-version` at all, so they cannot clear a bar the prompt requires every candidate to clear. Read positively, it resolves to a 1.96 floor against the current stable 1.98.1, and the recommended tree's maximum declared `rust-version` is 1.85.0, measured rather than assumed — eleven minors of headroom. **`rust-edition`** is 2024 for the CLI crate that carries the dependency; no candidate constrains it. **`target-os-matrix`** is satisfied with room to spare: `inquire` and `crossterm` both test Ubuntu, macOS and Windows upstream, and Windows support is noted, not required. **`license`** is not used to rank anything — gate 1 is `inapplicable` by the owner's 2026-09-12 ruling — and the declared strings are recorded above as observation only.

**R67's `error-taxonomy-exit-codes` is not an `- assumes` line, deliberately.** R61's prompt registers no dependency on it: the coupling is recorded in the prompt's `## Couplings` as `related (not a registry dependency)`, and it runs the other way — R67 needed to know whether this item adopts a prompt crate at all. This decision nonetheless *binds itself* to R67's published `error-contract/v1` rows `RSLB205`, `RSLB903`, `RSLB101` and `RSLB000` and to its no-prompt-local-handler rule, and every outcome this item can produce maps onto a row R67 already publishes, which is why no `CONFLICT:` line is raised and no catalogue row is added. The rows were re-read from `research/topics/67-error-and-exit-code-contract/DECISION.md` this run (checks `C16e`, `C16f`, `C16h`, `C16i`).

## Empirical check

**Toolchain and platform.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`; `cargo 1.98.0 (797e8a9bc 2026-08-05)`; macOS 26.4 on `Darwin arm64`; `python3` from the system; `bash`; `/usr/bin/shasum`; `/usr/bin/curl`; `gh` authenticated on this machine (no token or environment value is printed by the script or by this decision); `/usr/bin/grep` (BSD grep) used by absolute path for every count, never a shell alias. The policy floor is computed against the published stable channel, **1.98.1 (2026-09-01)**; the locally installed 1.98.0 differs by a patch level and changes no floor arithmetic. The revision-2 rerun ran on `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and `cargo 1.98.1`, the same stable release as the floor basis.

**Command and working directory.**

```
cd research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/evidence
bash r61-claims.sh > r61-claims.log 2>&1 ; echo "exit=$?"
```

**Result, revision 1 (`2026-09-17T05:43:30Z`, `r61-claims-r1.log`): `exit=0` — 97 assertions pass, 0 fail, 0 skip** on this machine. **Result, revision 2 (`2026-09-23T05:14:20Z`, `r61-claims.log`): `exit=0` — 93 pass, 0 fail, 4 skip.** The four SKIPs are `C13c`–`C13f`, case B of section 13: this seat is refused a pseudo-terminal (`openpty` errno 1, `EPERM`). The script records each as an environmental SKIP naming its fallback evidence (`C3a`–`C3f` and case A's `C13b`, both passing) and asking a pty-capable seat to re-run case B. The script skips only on that errno; any other case B outcome runs the four assertions and can fail. The script exits with its failure count, so `exit=0` is the count of failed assertions and not merely a shell success. Every assertion is on content; each of the handful that reads an HTTP status is paired with a content assertion on the same artifact (the RustSec 404s are paired with the `atty` control returning 200 **and** that page naming `RUSTSEC-2021-0145`).

**Verify claims; never implement the recommendation.** Nothing from the template was built. Three throwaway Cargo manifests and one throwaway binary were created under `$TMPDIR`, outside this repository, and removed by the script's `EXIT` trap. They are not a seam, a service, a hook pipeline, an acceptance script or a template scaffold: two resolve dependency graphs and one calls two library functions and prints their results.

**What the check establishes, section by section** (full output in `review/evidence/r61-claims.log`):

| § | What it does | Result |
|---|---|---|
| 1 | Records the toolchain, platform and the grep binary | `rustc 1.98.0`, `cargo 1.98.0`, `Darwin arm64` / macOS 26.4 |
| 2 | Downloads six candidate tarballs from `https://static.crates.io/crates/<n>/<n>-<v>.crate` and compares each sha256 with `GET https://crates.io/api/v1/crates/<n>/<v>` → `version.checksum` | **6 of 6 match.** `inquire` 0.9.4 `6654738b…9756`, `dialoguer` 0.12.0 `25f104b5…ad96`, `crossterm` 0.29.0 `d8b9f2e4…f87b`, `console` 0.16.6 `e96a4956…64e3`, `cliclack` 0.5.6 `134778b6…f30b`, `demand` 2.1.0 `c578ab33…07f2`. Every source citation in this decision is a line of a tarball that passed this comparison |
| 3 | Prints and asserts the `/dev/tty` fallbacks in `crossterm`'s `tty_fd()` and `console`'s `Input::unbuffered()`, and that `enable_raw_mode()` is built on `tty_fd()` | all four assertions pass |
| 4 | Prints and asserts `console`'s `libc::raise(libc::SIGINT)` and its own comment | passes — this is why `dialoguer` leaves `RSLB903` unreachable |
| 5 | `inquire` 0.9.4: the `Action::Cancel`/`Action::Interrupt` split, `prompt_skippable`, the stderr-only back-end, the crate-private `IO` enum, `MultiSelect::prompt -> Vec<T>`, `NO_COLOR` in `RenderConfig`, `rust-version`, the default feature list | all thirteen pass; **files under `inquire-0.9.4/src` containing `stdout` in any case, counted by `/usr/bin/grep -rilF`: 0**; lines matching `^pub enum IO`: 0 |
| 6 | `dialoguer` 0.12.0: `interact -> Vec<usize>`, the `!term.is_term()` guard on the *output* terminal, the stderr default, `rust-version` | all four pass |
| 7 | Fitness gate 2 read strictly, plus the two contract-fit findings | `cliclack` and `demand` have **no** `rust-version` key; `cliclack` collapses ESC and `^C` into one `State::Cancel`; `demand` imports `signal_hook::consts::SIGINT` |
| 8 | Reads the CLI Design Standard at blob `f9de0437…`, asserts the blob's content hash, prints `:253`, `:381`, `:456`, `:461`, `:472` and asserts each carries the clause cited | seven assertions pass; blob sha256 `9fb05d3d…463f`, 773 lines. **SKIPs by name** if the `cli-standards` checkout is absent |
| 9 | `https://rustsec.org/packages/<name>.html` for all six candidates, with `atty` as the positive control | **404 for all six**; `atty` returns **200** and its body names `RUSTSEC-2021-0145`, so the 404s are real negatives and not a broken endpoint. This closes the evidence gap the Codex raw recorded as blocking |
| 10 | crates.io and GitHub figures; the `inquire` newest-commit date and open-PR count | every figure in the table above; `inquire`'s newest commit is still `2026-02-24T17:21:29Z`, 30 open PRs |
| 11 | `ast-grep`'s CLI manifest | declares `inquire` and `clap` in one file — the R60 + R61 compatibility proof |
| 12 | **Like-for-like** dependency cost: three manifests differing only in the prompt crate, each with `indicatif` and `signal-hook` 0.4.4 | 9 / 35 / 11 packages; max declared `rust_version` 1.85.0 (`unicode-segmentation`); no async runtime at any depth; `signal-hook` is the only duplicate in the `inquire` tree and the `dialoguer` tree has none |
| 13 | **Executed observation** of the `/dev/tty` fallback, two conditions | case A (no controlling terminal): `Err`, `raw_os_error = Some(6)`. case B (controlling PTY, stdin from `/dev/null`), executed in revision 1: `stdin_is_terminal=false`, `dialoguer_guard_term_stderr_is_term=true`, `crossterm_enable_raw_mode=Ok`. **The gate cannot be delegated to any candidate crate.** Revision 2: case A reproduced; case B SKIPped on this seat (`openpty` `EPERM`) |
| 14 | Generates the four fixed `- assumes` lines from `docs/port/PARAMETERS.md` and diffs them against this decision and against `inputs/PARAMETERS.md`; counts `- owns` and `CONFLICT:` lines | both diffs empty; 0 `- owns` lines; 0 `CONFLICT:` lines |
| 15 | Scoped search for the **bare string** `OV-02` over `docs/port/` and every `research/topics/*/DECISION.md` outside this item. Revision 2 excludes only the `docs/port/OWNER-ACCEPTANCES.md` rows whose item column is `R61`: the owner's acceptance of this decision quotes OV-02, and was added after revision 1. Any other file, or an acceptance row for another item, still counts | **0 files** — OV-02 does not collide. OV-01 is confirmed taken in `OWNER-REVIEW.md` and in R60's decision |
| 16 | F360's status and R67's rows, read from the repository | **0 rows** whose first column is `F360` in `docs/port/BASELINE-REVIEW.md`; F360 is `DIVERGENT` and owned by R61 in `COMMONALITY.md`; F277 and F278 are `ADOPT`; R67's `RSLB205`, `RSLB903`, the no-prompt-local-handler rule and the exit-`5` meaning are all present |
| 17 | sha256 of both raws, and the four claims this synthesis carries or renumbers from them | both raws hash as named in the task; the Codex `BASELINE-REVIEW: F360` line, the Codex `dialoguer` recommendation, the Opus `inquire` recommendation and the Opus `OV-01` numbering are each confirmed present |

**Rerun and diff — what is reproducible and what is not.** For revision 1, the script was run twice on this machine, the second time immediately before this decision was written, and the two logs were compared. For revision 2, it was run once in this worktree (the retained `r61-claims.log`) and once from a clean `git archive HEAD` extraction at `e0b0d1c1` under `/tmp/r61-arch`. The only uncommitted file overlaid onto that extraction was `review/evidence/r61-claims.sh`. The extraction therefore read revision 1 of this file, and checks `C14c`–`C14e` read only its `- assumes`, `- owns` and `CONFLICT:` lines, which revision 2 does not change. **The log is not byte-for-byte reproducible, and the comparison rule is this:**

- **Varies by design on every run:** the `executed at` timestamp in the header; the `$TMPDIR` path embedded in `cargo tree -d` output (it contains the script's PID); the six `recent_downloads` / `downloads` figures in section 10; `pushed_at` and `stars`; the `open issues` / `open PRs` counts; and, when upstream publishes, a patch-level version inside a resolved tree.
- **Must not vary, and every one of them is an assertion that fails if it does:** all six tarball checksums; every quoted source line; the CLI standard's blob hash and its five cited lines; the six RustSec 404s and the `atty` 200; the two newest-non-yanked versions (`0.9.4`, `0.12.0`); `inquire`'s newest-commit date; the three package counts (9 / 35 / 11); the maximum tree `rust_version` (1.85.0); the single `signal-hook` duplicate; both `/dev/tty` observations (on a seat refused a pseudo-terminal, case B SKIPs by name with its reason; it never passes silently); the parameter diffs; the OV-02 count; the F360 count; and both raw hashes.
- **Observed between the two revision-2 runs, exactly** (`review/evidence/r61-claims-rerun.diff`, 36 lines including headers): **five lines changed. They were the `executed at` timestamp, the two `$TMPDIR` paths inside the `cargo tree -d` output, and the two lines that print a repository path (`run directory` and section 14's `generated from`), which differ because one run was in the extraction. Nothing else.** Both runs printed `TOTAL  pass=93  fail=0  skip=4`.
- **Observed between the two revision-1 runs, exactly** (that diff is superseded by the file above and is retained in git at `da52246c`, 26 lines including headers): **three lines changed — the `executed at` timestamp and the two `$TMPDIR` paths inside the `cargo tree -d` output, which carry the script's PID. Nothing else.** Every figure, every version, every count and every assertion result was identical, because the two runs were just over a minute apart and the volatile fields had not moved in that window. Across a longer interval the fields in the first list will move; this diff is evidence that the *stable* set is stable, not a claim that the volatile set never moves.
- The one figure that moved against the raws is `jdx/demand`'s star count, which the Opus raw recorded as 257 and both of this synthesizer's runs read as 258. It changes nothing: `demand` is excluded at fitness gate 2.

A rerun that differs in anything from the second list is a real change and must be investigated, not absorbed. Nothing in this decision is cited as "the complete reproduced output of a command" beyond the assertions named above, each of which the script re-runs — and the cited log is the output of the run whose diff is recorded here, not of an earlier run.

## Engines

- Codex (`gpt-5.6-terra`) — `raw/codex.md`, sha256 `a22fcc08990a3db262b3c950447646fac3d0293d284e55b484e2233320444f2e`, 10 H3 fields, one member.
- Opus (`claude-opus-5`) — `raw/opus.md`, sha256 `162d21eddec4acbf60828bc9e92adc353c3bbc983c2e079b7ee35a199b323fa7`, 10 H3 fields, three members.

Both engines agree on the load-bearing architecture: adopt one prompt crate, confine it to the CLI binary crate, hide it behind a template-owned `Prompter` port, own the interactivity gate at the call site, keep the library and web surface prompt-free, and compose `--dry-run`/`--yes` by never reaching the prompt. They disagree on five things.

**Disagreement 1 — which crate. Codex says `dialoguer` 0.12.0; Opus says `inquire` 0.9.4. Settled for Opus, with the cost restated honestly.** Codex's grounds are real and are not dismissed: `dialoguer` is the download and adoption leader, it is the cheaper dependency by a wide margin, its maintainers are demonstrably active, and its `interact_on(&Term)` is the literal property ts's D-016(6) prized. Three things settle it the other way, all re-verified here rather than taken from the raw. (i) R67 publishes `RSLB903` "prompt interrupted by Ctrl-C → 130" and requires the chosen crate be adapted to it; `dialoguer` reads keys through `console`, which **raises `SIGINT` to the process** on `^C` (checks `C4a`/`C4b`), so under `dialoguer` the row is unreachable and R67's contract must change to accommodate the dependency. `inquire`'s loop returns a typed `OperationInterrupted` (check `C5b`). (ii) The prompt's HIGH question asks whether the candidate renders `Choice`-style name/value pairs the way ts's checkbox does; `inquire` returns the **values** (check `C5g`), `dialoguer` returns **indices** (check `C6a`). (iii) The same HIGH question's output-stream half: `inquire` exposes no public path to stdout (checks `C5f`, `C5l`, `C5m`). The cost is the 24-package gap measured like-for-like in `## Empirical check` section 12, and it is recorded as the strongest argument for the runner-up rather than argued away. **Uncertainty is real here:** this is the judgement in this decision most likely to be overturned, and a reviewer who weights template dependency weight above the `RSLB903` mapping should reach `dialoguer`. The `Prompter` seam is what makes that a one-file change, and the re-verify triggers fire on exactly the signals that would flip it.

**Disagreement 2 — can the crate detect a non-interactive context itself? Codex writes that "`dialoguer` itself also rejects a nonterminal `Term`"; Opus says no candidate can. Settled for Opus, and settled by execution rather than by reading.** Codex's sentence is true of the *output* terminal and does not cover the case that matters. The guard `dialoguer` applies is `if !term.is_term()` on the `Term` it renders to, which is stderr (check `C6b`). With a controlling terminal attached and stdin coming from a pipe, that guard is **true** and the prompt proceeds, while `console`/`crossterm` open `/dev/tty` underneath (checks `C3a`–`C3f`). The synthesizer observed exactly this: case B in `## Empirical check` section 13 shows `stdin_is_terminal=false`, `dialoguer_guard_term_stderr_is_term=true`, `crossterm_enable_raw_mode=Ok`. This is the case R8.1 forbids at `:456`, no candidate crate prevents it, and it is why the gate is a member of this bundle. Codex's own recommendation already puts an application-owned TTY gate in front of the crate, so the two raws' *designs* agree even where their sentences do not.

**Disagreement 3 — advisory evidence. Codex records the RustSec 404s as a blocking evidence gap and makes its recommendation conditional on a future `cargo deny check advisories`; Opus treats the 404 as "no advisory", established by a positive control. Settled for Opus, and the gap is closed here.** The synthesizer re-ran it: `https://rustsec.org/packages/atty.html` returns **200** and its body names `RUSTSEC-2021-0145`, while all six candidates return **404** (checks `C9-*`). A 404 on that path therefore means "no advisory page", not "endpoint broken", and gate 3 is passed on evidence rather than deferred. The planned `cargo deny check advisories` in CI remains sound practice and is P03's, but it is no longer a condition on this recommendation.

**Disagreement 4 — F360, and the `BASELINE-REVIEW:` line. Carried verbatim, not adopted as a ledger change; its concern is honoured as a scope condition.** The Codex raw emits:

> `BASELINE-REVIEW: F360 — noninteractive commands must not silently widen an interactive choice — replace TypeScript's select-all fallback with refusal unless an explicit documented all-selection flag is supplied; Python already refuses unless --yes, while TypeScript selects every fetched project — evidence: py pin options.py, ts pin projects.ts, and Divergence Analysis R61`

Opus raises no `BASELINE-REVIEW:` line and instead classifies the three prompts, refusing for consent and required-value and proceeding with everything for narrowing.

**Disposition: recorded and carried here, not forwarded as a ledger change, and partially honoured.** Two reasons. Procedurally, the `BASELINE-REVIEW:` process adjudicates *inherited* baselines — `COMMON → REUSE` and `ADOPT` rows retained under owner amendment A5 — and F360 is neither: it is `DIVERGENT`, owned by R61 (check `C16b`), and carries **no row** in `docs/port/BASELINE-REVIEW.md` (check `C16a`, which counts rows whose first column is F360 and finds zero). A line challenging F360 is therefore answering this item's own scoped question, and the right vehicle is this decision, not a forwarded finding — the same treatment R19 gave a Codex `BASELINE-REVIEW:` line against a `DIVERGENT` row. Substantively, its concern is correct and is written into the rule: the narrowing class proceeds with everything **only because F280's selection subsets output the command already holds and would otherwise print in full**, and a multi-select whose result feeds a mutation is consent and takes the refuse-with-`RSLB205` path. What is **not** adopted is Codex's stronger proposal — that ts's select-all be replaced with refusal absent an explicit all-selection flag — because on a read-only listing the complete result *is* the non-interactive answer, R8.2's obligation is engaged by *missing* input and nothing is missing, and adopting it would require a behaviour change in ts that this item has no authority to make. No py, ts or ledger file is changed by this decision.

**Disagreement 5 — the fitness-gate result for `cliclack` and `demand`. Opus records "**None**" excluded by gate and excludes both on contract fit; Codex excludes `cliclack` at the declared-MSRV and platform gates. Settled for Codex's classification, on a rule neither raw applied.** Fitness gate 2 is read **strictly** since the controller withdrew the lenient provisional reading (`docs/planning/p02/execution-ledger.md`, "RULING WITHDRAWN: fitness gate 2 is read strictly"): an undeclared `rust-version` is not evidence of incompatibility but is insufficient evidence to *pass* a bar every candidate must clear before popularity is weighed. Neither `cliclack` 0.5.6 nor `demand` 2.1.0 declares one (checks `C7-cliclack-0.5.6`, `C7-demand-2.1.0`), so both move to *Excluded by gate*. Opus's two contract-fit findings — `demand`'s process-wide `SIGINT` handler and `cliclack`'s ESC/`^C` collapse — are retained and verified (checks `C7c`–`C7e`), and are recorded separately as fit evidence that would have excluded each anyway, so the gate-versus-fit distinction is not lost. Gates 4 and 6 remain **unverified** for both and are reported as unverified rather than assumed.

**A renumbering, not a disagreement.** The Opus raw records its override as `OVERRIDE (OV-01)`. OV-01 is taken by R60's CLI-standard waiver, requested 2026-09-12 and **refused** by the owner 2026-09-14, retired-as-refused rather than deleted (checks `C15b`/`C15c`). This decision carries the override as **OV-02**, the next free number, verified unused by a scoped search for the bare string `OV-02` over `docs/port/` and every `research/topics/*/DECISION.md` outside this item (check `C15a`). The argument and options are the Opus raw's, restated and extended with the explicit R67 mapping.

**A figure that moved.** `jdx/demand`'s star count reads 258 in both of this synthesizer's runs against the Opus raw's 257. Recorded for honesty; it changes nothing, because `demand` is excluded at gate 2.

**What P03 must validate, because this research did not.**

| # | Unproven claim | What would prove it |
|---|---|---|
| U1 | Acceptance criteria 1, 2, 5 and 6 — the gate refuses correctly and the narrowing class proceeds with everything | built-binary invocations in an ordinary CI job on both matrix runners: `< /dev/null` from a terminal, `--no-input`, `--yes`, and stdout redirected |
| U2 | Acceptance criterion 7 — a declined confirm exits `0` with stdout byte-empty and no write (OV-02's observable form) | a PTY harness answering `n` |
| U3 | Acceptance criterion 8 — `^C` mid-`MultiSelect` reaches exit `130` through `RSLB903` with no `inquire` error text in the envelope | a PTY harness sending a real `^C`. **R67 recorded this same gap and this run did not close it either**: `inquire`'s typed variants were read from source and never triggered |
| U4 | Acceptance criterion 9 — no prompt byte reaches a redirected stdout | a PTY harness with `1>file`. Section 5's zero-`stdout` count is strong evidence and is not the observation |
| U5 | That the gated template never opens `/dev/tty` | the observation in section 13 proves the *crate* does; it cannot prove the *template* does not, because the template does not exist |
| U6 | That `cargo tree -d` shows the `signal-hook` duplicate and nothing else in the real workspace | a CI step asserting exactly one duplicate; measured here on a spike manifest, not on the template's workspace |
| U7 | That the 24-package gap is or is not a real compile-time cost | `cargo build --timings` on the built template, both runners. Gate 6 permits the qualitative answer given here, and no byte or second figure is claimed |
| U8 | Fitness gates 4 and 6 for `cliclack` and `demand` | not applied; both failed gate 2 first. Reported as unverified, not assumed |
| U9 | `inquire`'s CI declares an MSRV job at 1.82.0 while its published 0.9.4 manifest declares `rust-version = "1.80.0"`; `dialoguer` declares 1.66 and pins a 1.85.0 CI job | the discrepancies are reported, not reconciled. Both crates satisfy gate 2's two halves — a declaration *and* a CI test — and both numbers are far below the 1.96 floor, so no gate result turns on them |
| U10 | Issue responsiveness for `crossterm`, `console`, `cliclack` and `demand` | not measured. Those maintenance verdicts rest on commit recency, push date, release history and open-PR flow, with no response-time median |
| U11 | The `promkit` and `requestty` reads are shallow — registry and repository metadata plus a one-line characterisation of the programming model | neither tarball was downloaded; neither was shortlisted, and gates were not applied to either |
