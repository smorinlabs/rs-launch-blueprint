# 2026-09-17 — R62 — clipboard-integration (bundle, Focused) — decision (revision 2)

**Revision note.** Revision 2 revises revision 1 (sha256
`10caee16f01cb2b39bad301c7669abb65cef4cb24b112fb0821bc23869bc73e7`, commits
`485f91a` and `4c495f1`) in place. It answers every finding of the revision-1
judgment audit (`review/audit-fable.md`, commit `b899491`; actor
`audit-fable-2026-09-17T020715Z-7f97cd917c54-r1`, model `claude-opus-5`, family
anthropic, verdict **reject**). **The recommendation does not move**: the three
members, the crate, the version, the feature set, the crate placement and the
fatal failure policy are unchanged, and the four `- assumes` lines are
byte-identical to revision 1. No parameter value moved and no `CONFLICT:` line
is written. The empirical audit is deferred for this item, so no
`review/audit-codex.md` exists and nothing here stands in for one.

| Finding | Repair |
|---|---|
| **JF-1 (blocking)** — *"Acceptance criteria AC2 and AC3 cannot both hold, and the tension with R67's envelope invariant is unrecorded."* | AC3's `**byte-empty stdout**` clause is struck and replaced with what the design actually produces; a new subsection *"What a post-result failure puts on each stream"* states both output modes, quotes R67's `"stdout stays byte-empty on the error path"` clause and its second location, and records the disposition (R62 qualifies the clause for post-result partial failures; R67's owned value need not move; the open end is a new re-verify trigger). The `## Parameters` sentence that repeated the clause is rewritten. Check A95 is no longer cited for two claims it does not assert — new checks `R08`, `R09`, `R11` and `R13` carry those. |
| **JF-2** — *"fitness gate 3's `unsafe` posture for `arboard` is stated nowhere."* | Gate 3's posture half is now stated and censused rather than asserted: new checks `R14`, `R15` count the `unsafe` keyword across `arboard` `v3.6.1`'s sources, and `R16` cites R06's `--cap-lints allow` scoping. |
| **JF-3** — *"the §7.6 issue-responsiveness figure is omitted."* | The figures table gains the column, computed here rather than inherited (new checks `R18*`), and the `copypasta` `at-risk` verdict now weighs the countervailing figure instead of omitting it. |
| **JF-4** — *"the `re-verify:` line names two alternatives the decision never defines."* | Both are defined in `### Principles and implementation` with their promotion condition and migration cost, sourced to `raw/opus.md` (new checks `R25`–`R28`). |
| **JF-5** — *"standard rule R5.6 is cited for a proposition it does not carry."* | The citation is corrected: R5.6 is motivation, not the governing rule; the operative reasons are stated, and new check `R21` asserts that R5.6's own text contains no mention of `argv`, a process listing or `/proc`. |
| **JF-6** — *"'verbatim' overstates the `nushell` reference, which pins 3.6.0."* | "verbatim" is replaced with the accurate claim about the dependency-line *shape*; new check `R24` asserts the version difference. |
| **JF-7** — *"the rejected warning policy is not recorded beside the fatal choice."* | The warning policy, its argument and the ground on which it was rejected are recorded beside the fatal choice, sourced to `raw/opus.md` (new checks `R29`–`R31`). |

**Revision history.** Revision 1 — 2026-09-17, commits `485f91a` (synthesis) and
`4c495f1` (claim qualification), sha256
`10caee16f01cb2b39bad301c7669abb65cef4cb24b112fb0821bc23869bc73e7`; rejected by
the round-1 judgment audit on JF-1 with JF-2 through JF-7 non-blocking.
Revision 2 — this file. No `## Supersedes` section: this item is unpublished, so
there is no published file to reverse.

**Artefact discipline for this revision.** `review/evidence/verify.sh`,
`review/evidence/spike-build.sh` and their two logs are **byte-identical to
revision 1** — the revision addendum requires that anything an audit reproduced
stay unedited. Every check this revision needs is new, in
`review/evidence/verify-r2.sh` with log
`review/evidence/r62-clipboard-claims-r2.log`, and every new check id is prefixed
`R` (`R01`–`R32`) so it cannot collide with revision 1's `A`/`S` ids.

## Decision

**Status.** This is a **proposal, validated in the implementation phase** (owner
ruling 2026-09-10). It records what the research found and what it recommends;
P03 builds the template and its CI proves the recommendation. Nothing here was
built: no `ClipboardPort` trait, no `--copy` flag, no re-exec helper, no
adapter, no test. The one compiled artefact in this run is a throwaway
dependency-resolution spike whose entire source is a dependency line and a
one-line `fn main` (`## Empirical check`, section B). A recommendation that does
not survive contact with the built template is corrected **against this recorded
research** — its principles, its compared alternatives, its verified mechanisms
— not by researching the item again from scratch. What P03 must validate is
listed under `## Engines`.

**Ship `--copy`, and ship it as three parts, not one dependency.**

| # | Member | Where it lives |
|---|---|---|
| 1 | `arboard = { version = "3.6.1", default-features = false, features = ["wayland-data-control"], optional = true }`, enabled by a default-on `clipboard` Cargo feature | the **binary crate only** |
| 2 | A `ClipboardPort` trait, a `ClipboardError` (`thiserror`) and two shipped test doubles; the write happens **after** the result reaches its primary sink | trait and error in the **library crate**; the `arboard` adapter in the binary crate |
| 3 | A `cfg(target_os = "linux")` selection-ownership helper: **probe** `Clipboard::new()` in the foreground and, **only on success**, re-execute the template's own binary with a hidden `--clipboard-daemon` flag, handing the payload over **stdin**, with `SetExtLinux::wait()` in the child and no `child.wait()` in the parent | the binary crate, one `cfg`-gated module |

The flag is spelled `--copy`, long-only, no short form. The success note goes to
**stderr** and is suppressed under `--quiet`. A failed copy is **fatal**: the
adapter composes its own message and hint, carries `arboard::Error` only as
`#[source]`, and the error boundary maps it to R67's published `RSLB101` → exit
`1`. R62 does not own that mapping and adds no catalogue row. The **rejected**
alternative policy, and why the owner may want to flip it, is recorded under
`### Principles and implementation` rather than left implicit.

**Ledger rows settled.** `F281` (clipboard-copy flag for command results) and
`F282` (clipboard write with headless-degrade handling), both `ts-only`
`DIVERGENT`, item `R62` (`docs/port/COMMONALITY.md:285-286`; verified, evidence
log section 11d). The verdicts are unchanged and **no `BASELINE-REVIEW:` line is
emitted** — the ledger row is correct as recorded; what needed correcting was
the prompt's gloss on it, recorded as a finding below.

**Member 3 is not polish.** On X11 and on Wayland the *copying process itself*
owns the selection and answers paste requests; a one-shot write from a
short-lived CLI dies with the CLI. Without Member 3 the copy is lost on every
Linux desktop that runs no clipboard manager, and racily on those that do — the
qualification is stated in full in the platform table under `### Principles and
implementation` and holds everywhere this claim appears — while the command
reports success either way. That finding, traced to
`arboard`'s own source and README at tag `v3.6.1`, is what makes this a
three-member stack and is developed below.

### Principles and implementation

#### A correction to the prompt's Context, recorded as a finding

The prompt's `## Context` states: *"this bundle is ts-only — py ships no
clipboard integration to compare against."* The first clause is correct at the
pin. The second is not correct as a statement about the py precedent, and the
difference bears directly on the question "should `--copy` exist at all".
**The prompt is immutable; this is a finding, not an edit.**

`py-launch-blueprint` shipped a `--copy` flag backed by `pyperclip`. It was
removed on **2026-06-09** in commit
`f587e48b41bcf6535ba1b62f348147294911c48d`, *"refactor: remove legacy
py-projects CLI and collapse command_name identity (#388)"*. The commit body,
read through the repository rather than quoted from memory, says why:

> the legacy flat-flag features (`--format csv`, `--copy`/clipboard, `--output`,
> interactive config setup) have no `plbp` equivalent and are dropped.

Two consequences, both verified in `## Empirical check` section A, checks
A67–A75:

1. **The ledger row needs no change.** At the pin
   `b08bccfb55d05f15e46a83b52c5660b1881d19f5` there are **zero** `pyperclip`
   occurrences across tracked `*.py` and `pyproject.toml` (check A75). `F281`
   and `F282`'s `ts-only` origin is accurate, so no `BASELINE-REVIEW:` line is
   emitted.
2. **The removal is not a rejection of the capability on its merits.** It is
   collateral of deleting an entire duplicated CLI — the commit's own wording
   records an unported feature, not a considered decision. Reading it as a
   rejection would be reading drift as design.

The pre-removal py code is the third data point this item has, and it
establishes the principle by *failing* to honour it. At `f587e48^`,
`src/py_launch_blueprint/projects.py` calls `pyperclip.copy(result)` with **no
`pyperclip`-specific `except` arm** (checks A73, A74): on headless Linux the
`PyperclipException` fell through to a generic handler that printed
`Error: …` after the result had already been printed. ts D-016(7) is precisely
the repair — `clipboardy` behind an injected `ClipboardWriter` whose failure
becomes a typed `CliError` (checks A76–A78). Read across all three
repositories the trajectory is: **py had the capability and got the failure
path wrong; ts kept the capability and fixed the failure path; rs keeps both
and must additionally fix a third thing neither source repo ever faced**,
because neither Python nor Node owns the selection.

#### The shared requirement, its source, and the level at which agreement is required

**Requirement.** A command that produces a textual result MAY additionally place
that result on the operating-system clipboard when the user asks for it with a
flag; the result MUST reach its primary sink regardless; and the clipboard write
MUST NOT be able to crash, hang, or silently mislead the user.

**Source.** `F281`/`F282` (`docs/port/COMMONALITY.md:285-286`), verdict
`DIVERGENT`, item `R62`; ts decision D-016(7); the pre-removal py
implementation above.

**Agreement level: capability and policy — not a library, not a low-level
value.** This is the "justified ecosystem difference" the owner clarification of
2026-09-04 asks for: the *principle* (an additive, best-effort side effect that
degrades to a clear diagnostic) ports unchanged; the *mechanism* cannot, for a
reason specific to Rust.

| Must agree across py, ts and rs | May differ per ecosystem |
|---|---|
| The capability is an **optional flag** on the result-emitting command, spelled `--copy` | The crate or package that performs the write |
| The write happens **after** the result has reached its primary sink, and never replaces it | Whether the write is synchronous or handed to a helper process |
| The success note goes to **stderr**, never stdout | The wording of the note |
| A failure is a **typed, catchable** error carrying a remedy — never a panic, an unhandled exception, or a silent no-op | The concrete error type, and which catalogue code it maps to |
| The facility's absence is a **normal, expected** runtime state (headless Linux, CI), not an exceptional one | How absence is detected |

#### The finding that dominates this item: Linux selection ownership

Neither py nor ts ever had to solve this, because **neither owns the
selection**. `pyperclip` and `clipboardy` are both process wrappers — they shell
out to `pbcopy`, `xsel`/`xclip` and `wl-copy`, and those external binaries keep
running after the caller exits, so the copy survives. A Rust program that links
`arboard` becomes the owner itself.

`arboard`'s README, section *Clipboard Ownership*, says so in the maintainers'
own words (verified, checks A31–A33):

> Some apps and users may notice that sometimes values copied to a Linux clipboard
> with this crate vanish before anyone gets the chance to paste […]

> If your application is exiting, you must make sure there is a clipboard manager
> running on the system. If nothing is listening for the clipboard ownership
> transfer, or made a copy previously, the data will be lost.

The Wayland path does **not** escape it. The X11 backend serves paste requests
from `std::thread::spawn` inside the copying process (`src/platform/linux/x11.rs`,
check A34); the Wayland backend passes `opts.foreground(matches!(wait,
WaitConfig::Forever))` (`src/platform/linux/wayland.rs`, check A35), and
`wl-clipboard-rs` documents `foreground` as *"the flag for not spawning a
separate **thread** for serving copy requests"* (check A41). A thread, not a
process — it dies with `exit()` either way. `wl-clipboard-rs`'s own doc comment
names the contrast: the serving loop can be started *"potentially past a fork
(which is how `wl-copy` uses it)"* (check A42) — `wl-copy` the **binary** forks;
the library called in-process does not.

So the platform matrix for a **short-lived CLI** is not the platform matrix for
a clipboard crate:

| Platform | Who stores the bytes | Does a one-shot write survive process exit? |
|---|---|---|
| macOS (`macos-latest`) | `NSPasteboard`, a system pasteboard server outside the process | **Yes.** Member 3 compiles out entirely |
| Windows (not in the matrix) | the Win32 clipboard, a kernel-managed store | Yes |
| Linux X11 / XWayland | the **copying process**, answering `SelectionRequest` events from a thread | **No**, unless a clipboard manager happens to be running and wins the race |
| Linux Wayland (`ext-data-control` / `wlr-data-control`) | the copying process, via a serving thread | **No**, same reason |
| Linux, headless (`ubuntu-latest`) | nothing; no display server exists | N/A — the write correctly fails at `Clipboard::new()` |

#### The headless path, traced to source

With `wayland-data-control` enabled, `arboard`'s Linux `Clipboard::new()` first
tests `std::env::var_os("WAYLAND_DISPLAY")` (check A25); a Wayland failure is
logged and **ignored**, falling through to
`Ok(Self::X11(x11::Clipboard::new()?))` (check A26). That reaches
`RustConnection::connect(None)` (check A27), x11rb's pure-Rust connection, which
with `DISPLAY` unset fails at display-string parsing — x11rb's `DisplayNotSet`
variant (check A44) — before any socket exists. Four properties decide the
wrapper design, and each is asserted against a named line in the evidence log:

1. **It returns; it does not hang or panic.** `Clipboard::new()` yields
   `Result<Clipboard, Error>` (check A30) and the module contains no `panic!`
   on that path (check A29). This answers the prompt's HIGH question about
   hanging **from source**, not from observation — see `## Engines`, Unproven 1.
2. **The failure is `Error::Unknown { description }`, not a dedicated variant.**
   `arboard::Error` is `#[non_exhaustive]` (check A20) with no headless variant
   at all (check A24), and its own doc comment says `description` *"should not
   be relied on as a means to identify an error case during runtime"* (check
   A23). **The template must therefore never match on the message to detect
   headlessness** — and never needs to, because every failure of
   `Clipboard::new()` means the same thing to a `--copy` user.
3. **The message `arboard` produces is wrong for this case.** It maps *any*
   connect failure to `Error::unknown("X11 server connection timed out because
   it was unreachable")` (check A28). Forwarded verbatim, a CI log would read
   *"timed out"* for a machine that never had an X server. The org CLI Design
   Standard v1.4.14 **R7.6** requires errors that *"name the offending input in
   quotes, and state a next step where possible"* (checks A81, A82), which a
   forwarded timeout message cannot do. The adapter supplies its own message and
   hint and carries `arboard::Error` as `#[source]` for `--debug`.
4. **`Error` implements `std::error::Error`** (check A21), so it composes with
   `thiserror`'s `#[source]` and with `anyhow` at the boundary under R67's
   layering rule with no adapter code (check A96).

`arboard`'s own CI corroborates this independently and unusually directly: the
clippy job runs on `[macos-latest, windows-latest, ubuntu-latest]` (check A37)
but the **test** job runs only on `[macos-latest, windows-latest]` (check A39),
above the maintainers' comment *"No Linux test for now as it just fails due to
not having a desktop environment."* (check A38). That is the same fact
`clipboardy`'s upstream gave ts in D-016(7), reached independently in the Rust
ecosystem.

#### Architectural alternatives, compared before libraries

**A — native crate (`arboard`), write in-process. Recommended.** Links platform
APIs directly: `objc2-app-kit`/`NSPasteboard` on macOS, `x11rb` and optionally
`wl-clipboard-rs` on Linux (checks A17, A18, S05, S11, S12). No external binary
on PATH. Costs a dependency subtree and inherits the ownership problem, which
Member 3 repairs.

**B — shell out to `pbcopy` / `wl-copy` / `xclip -selection clipboard`.** This
is literally what both source repos do, and the persistence problem vanishes
because those binaries fork on their own. It loses on three counts. The
`ubuntu-latest` (24.04) runner image ships **none** of `xclip`, `xsel` or
`wl-clipboard` (checks A64–A66, paired with an `xvfb` presence control, check
A63), so any CI test of the success path needs an `apt-get` step that
Alternative A does not. It reintroduces a runtime PATH dependency Rust otherwise
lets this template avoid. And it makes the error surface worse, not better: a
missing binary, a non-zero exit and a signal death are three failure shapes to
classify against one `Result`. **Ranked second**, and the design to fall back to
if `arboard` becomes unmaintainable.

**C — OSC 52 terminal escape sequence.** The only design that works over SSH,
and it needs no dependency. Rejected as the recommendation for one decisive
reason: the sequence is fire-and-forget, so the program cannot learn whether the
terminal honoured it — "degrade cleanly" becomes "cannot detect failure at all",
which is worse than the status quo. It is also useless in CI, which has no
terminal either. **Document it as an extension point; do not implement it.**

**D — do not ship `--copy`.** The honest case: the capability is a convenience
and `rslbp projects … | pbcopy` already works. It loses once py's history is
read correctly — py's removal was collateral, not a judgement (checks A71, A72),
and ts kept the capability deliberately after research (D-016(7)).

#### How the selected design preserves each principle

- *Additive, never replacing.* Member 2 fixes the call-site ordering: the result
  reaches its primary sink first, then the port is invoked. A fake writer proves
  the ordering on any machine, with no display server.
- *Typed, catchable failure with a remedy.* `ClipboardError` is a `thiserror`
  type in the **library** crate carrying `arboard::Error` as a boxed `#[source]`,
  so the library and the web-service build link no desktop dependency at all.
  R67's layering rule (check A96) is what makes that split the conforming shape
  rather than a taste.
- *Absence is normal, not exceptional.* Standard **R8.2** requires a tool to be
  *"fully usable without a TTY"* and routes *"runtime input failures"* to exit
  `1` (checks A79, A80). An absent display server is a runtime environmental
  failure, **not** missing required input or consent — so R67's `RSLB205` → `2`
  arm does not fit, and `RSLB101` → `1` does.
- *Presentation versus requested behaviour.* Standard **R7.3** separates TTY-gated
  niceties from selected behaviour (check A83). `--copy` is a **requested
  action**, so it must not be gated on `IsTerminal`; the *success note* is a
  diagnostic and belongs on stderr under R7.1/R7.4 (check A84), suppressed by
  `--quiet` under R4.4.
- *No payload in a process listing.* Member 3 hands the text to the child over
  **stdin** rather than `argv` for two operative reasons: on Linux `argv` is
  world-readable through `/proc/<pid>/cmdline` for the daemon's whole lifetime,
  and `ARG_MAX` bounds what `argv` can carry while a pipe does not. *Revision 1
  wrote "Standard **R5.6** (check A85) is why Member 3 hands the text to the
  child over **stdin** rather than `argv`", which overstated the rule.* R5.6 is
  *Secret redaction in output*: it requires secret values to be **masked in all
  output** and says nothing about `argv`, a process listing or `/proc` (checks
  R19, R20, R21). It is the standard's **motivation** here — a copied result may
  contain a secret — not the rule that requires the handoff. `code2prompt` makes
  the same choice in production (check A58).
- *No `unsafe` in the template's own code.* R06 sets `unsafe_code = "forbid"` in
  the workspace lint table, which is what selects **re-exec** over the `unsafe
  fn` `libc::fork()` for Member 3. **This is a statement about first-party
  crates only, and fitness gate 3's posture half is the separate question:**
  `arboard` **does** use `unsafe` internally — 67 lines carrying the keyword
  across its `lib.rs`, `common.rs`, both Linux backend files and the macOS and
  Windows backends (check R14), which is unsurprising for a crate whose macOS
  and Windows paths are FFI. That does not break R06's policy and is not covered
  by it: Cargo compiles dependencies with `--cap-lints allow`, and R06's own
  decision text says the template *"makes no claim about `unsafe` inside its
  dependency tree"* (check R16). The surface this template's adapter touches
  exposes none of it — `arboard`'s public error module contains zero `unsafe`
  occurrences (check R15) and every operation returns `Result`. **Gate 3,
  answered in full:** advisories — none, on the paired-control reading in
  `## Empirical check` section A; `unsafe` posture — **uses `unsafe` in platform
  FFI, stated, not zero; first-party code adds none.**

#### What a post-result failure puts on each stream, and the R67 clause it meets

**This is the finding revision 1 got wrong**, and it is worth stating at length
because R62 is the first item in this programme to present the shape. A failed
`--copy` is a **post-result partial failure**: the command's requested result has
already been written to its primary sink and is correct; only the additional side
effect the user asked for did not happen. Two streams are produced, and **neither
mode withholds the result** — withholding it would break the must-agree row above
("the write happens after the result has reached its primary sink, and never
replaces it") and, with it, the requirement this whole item exists to preserve.

| | Human mode | Machine mode (`-o json` / `--json`) |
|---|---|---|
| **stdout** (fd 1) | the formatted result, byte-identical to the same command run without `--copy` | the same result, in the selected machine format |
| **stderr** (fd 2) | the message and the hint, one line each | exactly one R67 object, `{"error":{"code":"RSLB101","message":…,"hint":…}}` |
| **exit** | `1` | `1` |

Three rules of the binding standard produce that table, each read at its own
scope. **R7.1** assigns fd 1 the command's *"requested result"* and fd 2
*"everything else: diagnostics, progress, prompts, warnings, and errors"*, and
says a diagnostic raised *during* a normal data command goes to stderr *"so it
never contaminates stdout"* — it routes the diagnostic, it does not withdraw the
data (checks R04, R04b). **R7.8** requires the single stderr object for ordinary
command failures *"including a failure that occurs mid-stream"*, and nowhere
requires stdout to be empty (checks R01, R02). **R8.2** assigns exit `1` to
runtime failures (check R07). **R6.3 is cited only as a shape analogy, not as a
governing rule**: its literal scope is *"a command operating on many items"*
(checks R05, R06), which `--copy` is not.

**The R67 clause, quoted, and this item's disposition.** R67's owned value ends
its *Envelope* paragraph with *"stdout stays byte-empty on the error path"*, and
R67's own AC2 repeats it — two locations, and the complete list (checks R08, R09,
R11). **R62's design does not satisfy that clause literally, and must not.** The
disposition is that **R62 qualifies the clause for post-result partial failures
rather than requiring R67's value to move**, on three grounds:

1. **R67's own contract already separates the result stream from the error
   path.** Its broken-pipe rule says *"a `BrokenPipe` result on the **result**
   stream ends the process at `0`, silently, with no envelope"* (check R10) — so
   the contract does contemplate a result stream with its own life, and "the
   error path" reads naturally as the path on which no result was produced,
   which is every failure R67 itself had in view.
2. **The org standard binds above R67** (owner ruling 2026-09-14) and settles the
   question in the opposite direction from an empty stdout: R7.8's mid-stream
   clause, and R7.1's routing of a mid-command diagnostic.
3. **Nothing in R67's value needs to change for R62 to conform.** The code
   (`RSLB101`), the exit status (`1`), the three envelope keys, the
   `hint`-omitted-not-`null` rule (check R13) and the `thiserror`/`anyhow`
   layering all apply to this item unchanged.

**Why no `CONFLICT:` line.** The prompt's grammar is
`CONFLICT: R## <param> — <needed value> — <reason>` and applies when a
recommendation *needs a consumed parameter to change*. R62's `## Couplings`
consumes nothing (checks A86, A87), and under the qualified reading above
`error-taxonomy-exit-codes` does not move. **What would be needed if the
controller reads the clause as unqualified and binding on every item** is stated
so the decision is overrulable rather than merely confident: R67's Envelope
sentence would become *"stdout stays byte-empty on the error path, except where
the command's requested result was already written before the failure"*, and the
same qualification would attach to R67's AC2. That is an R67 edit, not an R62
one, and it is now a re-verify trigger on this item.

#### Observable acceptance criteria

These are **proposed** criteria for P03, not executed results.

| # | Criterion |
|---|---|
| AC1 | On `macos-latest`, `--copy` leaves the normal result on stdout unchanged and the clipboard read back **in a following process** equals it |
| AC2 | With neither `DISPLAY` nor `WAYLAND_DISPLAY`, the command does not panic, does not hang under an external timeout, emits the result unharmed, and exits `1` |
| AC3 | Under a machine output format the failure puts **exactly one** R67 object on stderr — `{"error":{"code","message","hint"?}}` with `code == "RSLB101"` and a non-empty `hint`, `hint` omitted rather than `null` when absent — while **stdout carries the result, byte-identical to the same command run without `--copy`**. *Revision 1 wrote "and **byte-empty stdout**" here, which its own AC2 and must-agree ordering row contradict; see "What a post-result failure puts on each stream" above.* |
| AC4 | Under `xvfb-run`, a sentinel copied by a process that has since **exited** is still readable — the one check a naive implementation fails while passing every other |
| AC5 | `cargo tree -e normal` for the library crate shows no `arboard` under any feature combination; the same for the binary crate with the `clipboard` feature off |
| AC6 | The success note never reaches stdout, and is absent under `--quiet` |
| AC7 | `--copy` still copies when stdout is piped (it is a requested action, not a TTY nicety) |
| AC8 | No `--clipboard-daemon` child is spawned when the probe fails, and the payload never appears in the daemon's `argv` |

#### The failure policy, and the alternative the owner can flip

**Fatal (recommended).** The user asked for the side effect; it did not happen; a
script writing `rslbp projects --copy && pbpaste | …` would otherwise be lied to.
This is ts's behaviour at the pin (`throw new CliError`, check A78), it is what
R8.2 assigns exit `1` to, and the result still reaches stdout unchanged, so a
pipeline that only wanted the data is unaffected except by the status.

**Warning (rejected, and recorded so the owner sees a choice rather than a
conclusion).** Print the failure to stderr and exit `0`. It is friendlier for the
common interactive case, and it is what `py-launch-blueprint`'s own developer
recipe does today (`Justfile:608`, `… || echo "(Failed to copy command to
clipboard)"`). **Rejected because a template should teach the stricter default,
and because the friendlier behaviour is one line away for a fork that wants it**
(checks R29, R30). The flip costs no change to the port, the error type or
Member 1 — it is a change in the adapter's caller (check R31) — which is exactly
why it belongs here as a stated choice.

#### The two alternatives the `re-verify:` line names

Both are defined here so a reader can evaluate the trigger from this document
alone. Revision 1 named them and defined neither.

**Member 2's ranked runner-up — Alternative 2b, absence as a value.** Return
`Result<bool, E>` or an `Option`-shaped outcome from `ClipboardPort`, so "no
clipboard on this machine" is a **value** the caller may treat as success rather
than an `Err` (check R25). It has a real argument: it makes the warning policy
above natural. It is not the recommendation because **R03**
(`port-absence-vs-failure-contract`) owns the port-absence-versus-failure
question programme-wide and is unresolved; a two-variant error keeps the same
information (the `Unavailable` variant *is* the absence signal) without
pre-empting R03's shape. Migration cost if R03 settles toward absence-as-value:
**one trait signature and one match arm** (check R26). (`raw/opus.md` numbers it
2b and ranks it above 2a — a free function with no port — and 2c; the audit
narrative calls it 2a.)

**Member 3's acknowledgement-byte alternative — Alternative 3a.** Probe, spawn,
then wait for the child to write one acknowledgement byte before the parent
reports success (check R27). It strictly dominates the recommendation on
correctness: it closes the probe-to-write race and makes the success message
unconditionally true. It is not the recommendation because **it introduces a
timeout constant with no principled value** — too short and a loaded machine
reports a false failure, too long and the CLI hangs after the result is already
printed, and neither is tunable by a template author for a user's machine (check
R28). It becomes the right choice **if the owner inverts the fatal policy above**:
a warning policy needs to know reliably whether the copy happened, where a fatal
policy mostly needs to know that it *could*.

#### Reference implementations, and the one gap

| Claim | Maintained reference | Status |
|---|---|---|
| The dependency line's **shape** as recommended | `nushell/nushell` (`nu-command`) ships `arboard = { version = "3.6.0", default-features = false, features = ["wayland-data-control"] }` — the same `default-features = false` plus `wayland-data-control` configuration, pinned one patch earlier than this recommendation's 3.6.1 (checks A49, R23, R24). *Revision 1 said "verbatim", which the version difference makes wrong.* | verified |
| The **optional + feature-gated** shape | `nushell/reedline` ships it behind a `system_clipboard` feature (checks A51, A52) | verified |
| A short-lived CLI on the same configuration, running the Linux re-exec pattern | `mufeedvh/code2prompt` — hidden `--clipboard-daemon` flag, stdin handoff, `SetExtLinux::wait()` in the child (checks A54, A56–A59) | verified |
| **Probe-before-spawn** | **none found** | **evidence gap** |

The gap is stated rather than argued around, and it is the same file that
demonstrates why the probe is needed: `code2prompt`'s `spawn_clipboard_daemon`
contains **zero** `Clipboard::new()` calls (check A61) — it spawns
unconditionally, so on headless Linux it launches a child that dies silently and
logs *"Clipboard daemon launched successfully"*. The recommended probe is
reasoned from documented platform semantics plus that defect analysis, not
copied from a working example. AC2 and AC8 are what would close it.

re-verify: on the earliest of — a crates.io release after `arboard` 3.6.1 (re-read its changelog for Linux-ownership or `wayland-data-control` changes and re-run the spike); a RustSec advisory against `arboard`, `x11rb`, `wl-clipboard-rs` or the `objc2` family (`https://rustsec.org/packages/arboard.html` returning `200`, or a `crates/arboard` directory appearing in `rustsec/advisory-db`); `1Password/arboard` becoming archived, or `pushed_at` static for six months while no release lands; `arboard` enabling `wayland-data-control` by default or gaining a first-party daemonisation helper, either of which collapses Member 3; `wl-clipboard-rs` changing `foreground` from a thread to a forked process, which makes the Wayland half self-sufficient; **R03** settling the port-absence-versus-failure contract toward absence-as-value, which promotes Member 2's ranked runner-up; **R67** revisiting its *Envelope* wording — specifically whether *"stdout stays byte-empty on the error path"* is scoped to failures that produced no result, which is the reading this decision records; a controller or owner reading it as unqualified reopens the disposition under `### Principles and implementation`, *"What a post-result failure puts on each stream"*; **R66** fixing how `hint` renders in human output; **R05**/**R69** selecting an execution model, since the adapter is where a blocking hop would go; **R11** fixing `ci-job-structure`, which determines how AC1–AC8 are wired; a later R67 catalogue append giving clipboard failures a dedicated code; the owner inverting the fatal-versus-warning policy on a failed copy, which promotes Member 3's acknowledgement-byte alternative; `target-os-matrix` gaining `windows-latest`, which adds a `cfg` branch that needs no helper; otherwise figure freshness by 2027-03-17.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**No `owns` line, and no other `assumes` line.** The prompt's `## Couplings`
block carries an empty `owns:` and an empty `consumes:` (checks A86, A87), so
this item registers no parameter in `docs/port/PARAMETERS.md` and formally
consumes none. R67 is listed there as *"related (not a registry dependency)"*
(check A88); its `error-taxonomy-exit-codes` value is therefore discussed in
prose below and **not** written as an `assumes` line. The four lines above were
generated from `docs/port/PARAMETERS.md` rather than typed, and the run's
`inputs/PARAMETERS.md` rows were compared byte-for-byte against the live
registry (check A89, four rows).

**No `CONFLICT:` line.** Nothing in this recommendation requires a consumed
parameter to change.

How the four fixed parameters bear on the decision.

- **`target-os-matrix`** is the parameter that shapes the answer. The two legs
  behave differently in kind, not in degree: on `macos-latest` a one-shot write
  survives process exit because `NSPasteboard` is a server outside the process,
  and Member 3 compiles out; on `ubuntu-latest` there is no display server at
  all, so the write correctly fails at `Clipboard::new()`. Member 3's
  `cfg(target_os = "linux")` split is written against exactly these two legs;
  the absent third leg, Windows, would need no helper because the Win32
  clipboard is kernel-managed. Gate 4 passes for **build** on both legs and does
  **not** pass for a Linux end-to-end test — `arboard`'s own maintainers
  disabled theirs for the same reason (check A38), which is recorded honestly
  rather than glossed.
- **`msrv-policy`** costs the design nothing, but the raw reports' figure for it
  was wrong and is corrected here from an executed resolution. The highest
  **declared** `rust-version` differs per leg: **1.71.0** (`arboard` itself) on
  macOS, and **1.86** (`wayland-protocols`, reached through the
  `wayland-data-control` subtree) on Linux (spike checks S17, S18). Both sit far
  below the **1.96** floor R67 computed from the stable channel, so the verdict
  is unchanged — the figure was wrong, not the conclusion. The policy's two
  trailing clauses ("declared as rust-version in Cargo.toml and tested in CI")
  are satisfied by `arboard`: it declares `rust-version = "1.71.0"` (check A13)
  and tests on both fixed OSes to the extent a headless runner permits.
- **`rust-edition`** is not exercised. `arboard` 3.6.1 declares `edition =
  "2021"` (check A05); editions are per-crate, so it links into a 2024 workspace
  unchanged — verified by compiling it from an `edition = "2024"` package (spike
  check S19).
- **`license`** — **fitness gate 1 is `inapplicable — owner ruling 2026-09-12
  (Q7.B)`** (`docs/port/OWNER-REVIEW.md`, *"2026-09-12 — no licence check for
  anything the template uses"*). **Nothing was excluded on licence.** Recorded
  for completeness only: `arboard` 3.6.1 declares `MIT OR Apache-2.0`, the
  registry value byte-for-byte (checks A03, A12). The Linux and Windows subtrees
  contain other licences (`BSL-1.0` on `clipboard-win`, which is Windows-only
  and outside the matrix); under the ruling this is an observation, not a gate.

**R67's bearing, stated as prose because it is not a parameter of this item.**
R67's published, owner-accepted catalogue already expresses this item's only
failure mode: `RSLB101` I/O → exit `1` (check A94), carried in the single stderr
object `{"error":{"code","message","hint"?}}` (check A95) with `hint` omitted
rather than `null` when absent (check R13). *Revision 1's sentence continued "and
stdout byte-empty on the error path (check A95)", which attributed to A95 two
claims it does not assert and repeated a clause this item's design does not
satisfy.* A95 asserts the envelope substring and nothing more; the byte-empty
clause lives in R67 at two locations (checks R08, R09, R11) and R62's disposition
toward it — qualify for post-result partial failures, no value moved, no
`CONFLICT:` line, a re-verify trigger for the open end — is argued in full under
`### Principles and implementation`, *"What a post-result failure puts on each
stream"*. This item decides only that the clipboard-write failure **is** a typed,
catchable error; it adds no catalogue row and moves no value. The reason `RSLB101`/`1` fits and
`RSLB205`/`2` does not is the standard's own split, quoted in `### Principles
and implementation`: an absent display server is a runtime environmental
failure, not required input or consent that prompting cannot supply.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4 (Darwin 25.4.0,
`arm64`); `ShellCheck 0.11.0`; `/usr/bin/grep` (BSD grep, invoked by absolute
path throughout so an agent-shell `grep` alias cannot change a count);
authenticated `gh` for every GitHub endpoint (no token and no environment is
printed by either script).

**Working directory.** `research/runs/R62/2026-09-17T020715Z-7f97cd917c54/review/evidence`
(repository root `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`). Both
scripts locate the repository root by walking up to the directory that carries
`docs/port/PARAMETERS.md`, so they run from any extraction depth. All scratch
lives in a `mktemp -d` under `$TMPDIR`, removed by an `EXIT` trap.

**Verify claims; never implement the recommendation.** None of the three scripts
writes a trait, an error type, a flag, an adapter, a helper or a test. The spike's entire
Rust source is `fn main() { let _ = std::mem::size_of::<arboard::Clipboard>(); }`
— one line, naming a type so `cargo check` has something to check.

### A. Claim verification

    cd research/runs/R62/2026-09-17T020715Z-7f97cd917c54/review/evidence
    bash verify.sh > r62-clipboard-claims.log 2>&1

Observed: **exit `0` — 120 assertions, 0 failures, 0 skipped.** (The run
committed here was preceded by an identical run that reported one `SKIP`, for
check A91, because `DECISION.md` did not yet exist; A91 asserts that every
`assumes` line generated from the registry appears verbatim in this file, so it
can only run after the file is written. The committed log is the post-write
run.) The script's exit status **is** its failure count, so a non-zero exit is a
failed assertion and nothing else.

Sections 0-14: run header and toolchain (0); crates.io figures (1); GitHub repository figures (2); RustSec
with its paired positive control (3); `arboard` at tag `v3.6.1` — manifest,
error type, headless path, ownership, CI (4); `wl-clipboard-rs` and `x11rb`
(5); `copypasta`'s CI (6); adopters and the `code2prompt` defect (7); the py
prompt-gloss correction (8); the ts pin (9); the org CLI Design Standard blob
`f9de0437` (10); this item's couplings and the parameter registry (11); the R67
rows this failure lands on (12); a personal-data self-audit (13); summary (14).

**Method commitments the log keeps.** `set -o pipefail` is on, so a failing
`curl` cannot be masked by a succeeding `grep`. Every check asserts on the
**content** it expected — `assert_has` / `assert_re` / `assert_absent` /
`assert_eq` / `assert_count` — never on an exit code alone. Every count is taken
with `/usr/bin/grep -cF` over a **whole file**, and the log prints the binary's
absolute path beside each count, so no number in this decision comes from
`head`-truncated output. Every fetched figure carries its endpoint and UTC
retrieval date on the same line. HTTP status is asserted separately from
content, so a 404 that happened to contain the needle cannot pass.

**Rerunnability from a clean extraction.** The script was written to run against
a `git archive HEAD` extraction with no `.git` and no sibling clones. Three
groups depend on inputs an extraction lacks — the py reads (A67–A75), the ts
reads (A76–A78) and the CLI-standard blob (A79–A85) — and each is guarded and
emits `SKIP` **by name**, counted separately from PASS and FAIL, so an auditor
sees exactly which evidence a bare extraction cannot reproduce rather than a
silently shorter run.

**Reproducibility, checked rather than asserted.** `verify.sh` was rerun and the
two logs diffed before this sentence was written. Assertion lines, `SKIP` lines
and section structure reproduce **byte-for-byte**. `FIGURE` lines and the
`Run started` header do **not**, by design: they carry live counters. The
comparison rule is therefore:

    diff <(/usr/bin/grep -v -e '^FIGURE ' -e '^Run started' -e '^Scratch ' a.log) \
         <(/usr/bin/grep -v -e '^FIGURE ' -e '^Run started' -e '^Scratch ' b.log)

which is empty across the rerun. One asserted-on document is genuinely volatile
and is called out in the log itself: the `ubuntu-latest` runner-image readme
tracks the live image. Its three absences (`xclip`, `xsel`, `wl-clipboard`) are
meaningful only beside the `xvfb` **presence** control fetched in the same
request, which is why check A63 runs next to A64–A66.

**Figures, as retrieved 2026-09-17.**

| Crate | 90-day | all-time | newest non-yanked | stars / archived / pushed | open issues | issue responsiveness (median days to first maintainer response / unanswered, over the 10 most recently opened issues) | advisories | maintenance |
|---|---|---|---|---|---|---|---|---|
| `arboard` | 12,957,229 | 46,174,781 | 3.6.1 (2025-08-23) | 967 / false / 2026-09-16 | 19 | **1.68 / 8 of 10** | none (paired control) | **active** |
| `copypasta` | 857,282 | 5,559,318 | 0.10.2 (2025-04-25) | 350 / false / 2025-05-09 | 5 | **0.02 / 1 of 10** | none (paired control) | **at-risk** — see below |
| `clipboard-rs` | 284,058 | 475,548 | 0.3.5 (2026-06-30) | 180 / false / 2026-06-30 | 5 | **7.92 / 5 of 10** | none (paired control) | **stable-quiet** |

The responsiveness column was **omitted by revision 1** and is computed here
rather than inherited from a raw report (checks `R18*`, and the per-issue lines
in `r62-clipboard-claims-r2.log` section 4). Method, stated because the endpoint
mixes pull requests into `/issues`: the 10 most recently opened items with
`pull_request == null`; a "maintainer response" is the first comment whose
`author_association` is `OWNER`, `MEMBER` or `COLLABORATOR` and whose author is
not the issue author; the median is taken over the **answered** subset and the
unanswered count is reported beside it, never folded into it.

**The figure cuts against the crate this decision selects, and is recorded for
that reason.** `copypasta` is by a wide margin the most responsive of the three —
a median first maintainer response of about half an hour, with one unanswered
issue in ten — while `arboard`, the recommendation, leaves eight of its ten most
recent issues without a maintainer reply. Two things follow, and only the second
changes anything. The `at-risk` rubric verdict for `copypasta` **stands**,
because the rubric asks for concrete signals and there are two that
responsiveness does not touch: sixteen months with no release and no repository
push, and a CI matrix with no Ubuntu job (checks A46, A47) against a fixed
`target-os-matrix` that has one. Responsiveness measures attention to the issue
tracker; those two measure whether the crate is still being shipped and tested
where this template needs it. But **the selection is not a claim that `arboard`
is better maintained on every axis** — on this axis it is worse, and the
recommendation rests on the platform evidence, the adopters and the executed
resolution rather than on a maintenance sweep it would not win outright.

Endpoints: `https://crates.io/api/v1/crates/<name>` (`.crate.recent_downloads`,
`.crate.downloads`); `.../versions` (newest `yanked: false`);
`https://api.github.com/repos/<o>/<r>` (`.stargazers_count`, `.archived`,
`.pushed_at`); `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`.total_count`, **never** `.open_issues_count`). Consecutive `search/issues`
calls are 21 seconds apart; the two `gh` reads for one repository, and the four
advisory-db reads in section 3, are issued back to back.

**The advisory reading, and why a 404 is evidence here.** `https://rustsec.org/packages/arboard.html`
returns **404**, and so do `copypasta` and `clipboard-rs` (checks A06–A08). A
bare 404 proves nothing. It is zero-advisory evidence **only** because two
controls ran in the same pass: the same endpoint returns **200 for `anyhow`**,
whose page is backed by RUSTSEC-2026-0190 (check A09), and
`gh api repos/rustsec/advisory-db/contents/crates/<name>` agrees independently —
404 for each of the three, 200 listing one advisory file for `anyhow` (checks
A10, A11). This is R67's empirical row E4 applied to this item.

**Personal data.** Every `git` read uses an explicit `--format` that omits
`%an`/`%ae`/`%cn`/`%ce`; every `gh` read is projected with `--jq` to named
scalar fields. Section 13 asserts the result rather than trusting it: the
accumulated git output matches no e-mail pattern and no `Author:` /
`Signed-off-by:` line (checks A97, A98).

### B. Dependency-resolution and compile spike

    bash spike-build.sh > r62-spike-build.log 2>&1

Observed: **exit `0` — 21 assertions, 0 failures.** A throwaway package under
`$TMPDIR`, deleted by an `EXIT` trap; only the log survives. It carries the
recommended dependency line and nothing else, and converts three manifest claims
into resolved-and-compiled facts.

| Fact | Observed |
|---|---|
| Lock resolution | 70 packages, "latest Rust 1.98.0 compatible versions" |
| macOS leg (`aarch64-apple-darwin`), `cargo tree -e normal` | 9 distinct packages; `arboard v3.6.1`; `objc2-app-kit`; **no `image`**, **no `x11rb`**, **no `wl-clipboard-rs`** (S04–S08) |
| Linux leg (`x86_64-unknown-linux-gnu`) | 43 distinct packages; `arboard v3.6.1`; **both** `x11rb` and `wl-clipboard-rs`; **no `image`** (S10–S13) |
| Duplicate resolutions | macOS: none. **Linux: `hashbrown` resolves twice** — `wl-clipboard-rs → tree_magic_mini → petgraph` on one side, `petgraph → indexmap` on the other (S14, S15) |
| Highest declared `rust-version` | macOS leg **1.71.0** (`arboard`); Linux leg **1.86** (`wayland-protocols`) (S17, S18) |
| `cargo check` on this host | exit `0`, no `error[`, no unused-dependency warning — `arboard` 3.6.1 at these features type-checks from an `edition = "2024"` package (S19–S21) |

Three things fall out, and two of them correct the raw reports.

1. **`default-features = false` is load-bearing, not cosmetic.** `arboard`'s
   default feature set is `image-data` (check A14); disabling it removes the
   `image` crate from **both** legs (S06, S13).
2. **The cost of `wayland-data-control`, measured rather than adjectival.** The
   Linux leg is 43 packages against the macOS leg's 9. That is fitness gate 6's
   qualitative binary-size and compile-time answer, stated as a package count on
   this resolution.
3. **R67's zero-duplicate control does not hold here.** R67 recorded
   `cargo tree -d` printing nothing for its own dependency set. With
   `wayland-data-control` enabled, the Linux leg resolves two `hashbrown`
   versions. No fitness gate forbids duplicate resolutions, so this is a cost to
   record for P03, not a gate failure.

**Comparison rule for a rerun.** `cargo generate-lockfile` resolves the
*latest* compatible versions, so every number in the table above is a property
of the resolution on the run date and toolchain, not a fixed property of
`arboard` 3.6.1. A transitive release can move the package counts, the duplicate
report and the Linux-leg floor `S18` asserts; a rerun that fails `S18` after
such a release is expected drift and re-reads the new floor against the policy,
not a broken claim. What does not drift is the shape: `default-features = false`
keeps `image` off both legs, the macOS leg stays AppKit-only, and the Linux leg
carries both display backends.

`cargo tree --target x86_64-unknown-linux-gnu` resolves the Linux leg from the
lockfile without a Linux toolchain or host. It proves what **would** be linked
on `ubuntu-latest`; it does not compile or run anything for that target.
`cargo audit` was not run (no `cargo-audit` on this host); the RustSec HTTP
endpoints with their paired controls, section A above, carry the advisory
evidence instead.

### C. Revision-2 supplementary checks

    bash verify-r2.sh > r62-clipboard-claims-r2.log 2>&1

Observed: **exit `0` — 35 assertions, 0 failures, 0 skipped.** This file is
**additive**. `verify.sh`, `spike-build.sh` and their two logs are byte-identical
to revision 1, because the revision addendum requires anything an audit
reproduced to stay unedited; every check this revision needs is new here, with
ids prefixed `R` so they cannot collide with revision 1's `A` and `S` ids.

| Section | Answers | What it establishes |
|---|---|---|
| 1 | JF-1 | The standard's own text on a post-result failure: R7.8's mid-stream clause and the absence of any empty-stdout requirement (`R01`, `R02`); R7.1's result/diagnostic split and its mid-command-warning sentence (`R03`, `R04`, `R04b`); R6.3 read at its literal many-items scope so the decision cites it as an analogy, not a rule (`R05`, `R06`); R8.2's exit-`1` assignment (`R07`) |
| 2 | JF-1 | R67's `"stdout stays byte-empty on the error path"` quoted at both of its two locations, with the count as the complete location list (`R08`, `R09`, `R11`); R67's broken-pipe rule as the internal evidence that the contract separates the result stream (`R10`); what check A95 does and does not assert (`R12`, `R13`) |
| 3 | JF-2 | `arboard` `v3.6.1`'s `unsafe` census — 67 keyword lines across six surveyed files (`R14`), zero in the public error module (`R15`) — and R06's `--cap-lints allow` scoping (`R16`, `R17`) |
| 4 | JF-3 | The §7.6 issue-responsiveness figure for all three crates, computed from the issue and comment endpoints (`R18*`) |
| 5 | JF-5 | R5.6's actual title and text, and that it contains no mention of `argv`, a process listing or `/proc` (`R19`–`R21`) |
| 6 | JF-6 | `nushell` pins 3.6.0, not 3.6.1 (`R22`–`R24`) |
| 7 | JF-4, JF-7 | Alternatives 2b and 3a and the rejected warning policy, quoted from `raw/opus.md` (`R25`–`R31`) |
| 8 | — | No account identity in the GitHub sample this script held (`R32`) |

**Reproducibility, checked rather than asserted.** `verify-r2.sh` was rerun and
the two logs diffed. The filtered comparison is empty:

    diff <(/usr/bin/grep -v -e '^FIGURE ' -e '^Run started' -e '^Scratch ' a.log) \
         <(/usr/bin/grep -v -e '^FIGURE ' -e '^Run started' -e '^Scratch ' b.log)

and on this rerun — same UTC day, same 10-issue window — the whole raw diff was
two lines, the run timestamp and the scratch-directory name, so even the `FIGURE`
lines happened to reproduce. **The rule is still the filtered one**: the
responsiveness figures are a snapshot of a moving window and will differ once a
new issue is opened or answered.

**Logs.** `review/evidence/r62-clipboard-claims.log` (section A),
`review/evidence/r62-spike-build.log` (section B),
`review/evidence/r62-clipboard-claims-r2.log` (section C); scripts
`review/evidence/verify.sh`, `review/evidence/spike-build.sh` and
`review/evidence/verify-r2.sh`, all three ShellCheck-clean at 0.11.0.

## Engines

- codex `raw/codex.md` — Codex gpt-5.6-terra, sha256 `db997f3eab0c364a2f78dad4d149af504aa88a44c81701799595c73cc8da908b`; 10 H3 sections, a one-member stack.
- opus `raw/opus.md` — Claude Opus 5, sha256 `7ad84779707f6d67f7ce0b24d01dce0524e157a47bf96f1b68bcac1e964b2814`; 10 H3 sections, a three-member stack.

No Doxa engine ran: this item is Focused tier, whose approved engine set is
Codex and Opus.

Both engines independently selected `arboard` 3.6.1 with
`default-features = false, features = ["wayland-data-control"]`, both ranked
`copypasta` 0.10.2 second and `clipboard-rs` 0.3.5 as the up-and-comer, both
required an injected port rather than a direct call, both kept the flag spelled
`--copy`, and both emitted no `BASELINE-REVIEW:` line and no `CONFLICT:` line.
The decision follows them on all of that. Five things they did not agree on, and
the evidence that settled each:

**Disagreement 1 — one member or three (the stack's shape).** Codex recommends
`arboard` plus a synchronous `ClipboardWriter` and stops there; Opus adds the
Linux selection-ownership helper and calls it non-optional. This is an
**omission rather than a considered disagreement**: Codex's report does not
discuss selection ownership anywhere, so it neither weighed the helper nor
rejected it. Settled for Opus on source read at tag `v3.6.1`, four checks that
would each have to fail for Codex's shape to be sufficient: the README's
*Clipboard Ownership* section and its "the data will be lost" sentence (A31,
A33); the X11 backend's `std::thread::spawn` serving thread (A34); the Wayland
backend's `foreground(matches!(wait, WaitConfig::Forever))` (A35); and
`wl-clipboard-rs` documenting `foreground` as a **thread** switch (A41). All four
read as Opus describes. Codex's one-member stack would therefore produce a CLI
whose `--copy` reports success and loses the clipboard contents on every Linux
desktop that runs no clipboard manager, and racily on those that do (the
qualification in the platform table under `### Principles and implementation`).

**Disagreement 2 — where the dependency goes.** Codex says "the CLI-facing
package manifest"; Opus says optional in the **binary crate only**, behind a
default-on `clipboard` feature. Settled for Opus on the principle rather than on
preference: the library crate and the web-service build must never link a
desktop dependency, and Opus's shape is the one that makes that checkable
(AC5, `cargo tree` with the feature off). `nushell/reedline` ships exactly this
optional + feature-gated shape in production (checks A51, A52).

**Disagreement 3 — RustSec.** Codex reports the prescribed package page's 404
and records advisory status as *unverified*. Opus pairs it with controls.
Settled for Opus, and the pairing was re-run here rather than inherited: the
same endpoint returns 200 for `anyhow` (A09) and the advisory-db contents API
agrees independently (A10, A11). Codex's caution was right about a bare 404 and
wrong that the question could not be closed.

**Disagreement 4 — `copypasta`'s Ubuntu coverage.** Codex states the runner-up
"does not show an Ubuntu test job" and marks it a comparative concern; Opus does
not rest on the point. Settled as fact rather than impression by reading
`.github/workflows/ci.yml` at tag `v0.10.2`: the matrix is
`[windows-latest, macos-latest]` and the word `ubuntu` appears **nowhere** in
the file (checks A46, A47). Combined with 16 months since its last release and
last push (figures above), `copypasta`'s maintenance rubric is **at-risk**, which
is Codex's own verdict on independently re-read evidence — and which survives the
§7.6 responsiveness figure revision 2 adds, where `copypasta` scores best of the
three (`## Empirical check` section A, figures table and the paragraph beneath
it).

**Disagreement 5 — the MSRV figure.** Opus states the highest declared
`rust-version` in the resolved-as-recommended set is 1.71.0; Codex declines to
state one, calling the resolved-graph floor an unexecuted validation. **Both are
partly wrong.** The executed resolution (spike S17, S18) gives **1.71.0 on the
macOS leg and 1.86 on the Linux leg** — Opus's figure holds for one leg only,
and Codex's gap is now closed. Neither error changes the verdict: both floors
sit far below R67's 1.96.

**A defect this item's own engines carried, corrected in revision 2.** Both
raws are internally inconsistent about what a post-result failure leaves on
stdout: `raw/opus.md` argues the fatal policy on the ground that *"The result
still reaches stdout unchanged"* and then writes `[ ! -s out.txt ]` into its own
A3 validation command, and revision 1 of this decision carried the contradiction
across into AC2 and AC3. It is settled here from the binding standard rather than
from either engine — R7.1, R7.8 and R8.2, checks `R01`–`R07` — and the R67 clause
it meets is quoted and dispositioned under `### Principles and implementation`.
Codex reaches the same shape without the defect: its acceptance criterion 2 says
the command *"preserves the already-emitted result"* and says nothing about
emptying stdout.

**What P03 must validate.** Every acceptance criterion AC1–AC8 is unexecuted;
none could be run here. In priority order: **AC4** (a copy survives process exit
under `xvfb-run`) is the single check a missing Member 3 fails while passing
every other; **AC8** (no child spawned when the probe fails; no payload in
`argv`) is the check the best production reference implementation would fail;
**AC2** (clean degrade with no display, under an external timeout) converts this
decision's source-read headless claim into an observation; **AC5** proves the
library and web builds link no desktop dependency; **AC1/AC3/AC6/AC7** prove the
user-facing contract and R67's envelope.

**Unproven, and what would prove it.**

1. **`arboard`'s observed behaviour on headless Linux.** This machine is macOS
   and no headless Linux was available in this session. The claim that
   `Clipboard::new()` returns rather than hanging or panicking is read from
   `src/platform/linux/mod.rs`, `src/platform/linux/x11.rs` and x11rb's
   `DisplayNotSet` (checks A25–A30, A44), and corroborated by the maintainers'
   own disabled Linux test job (A38). **A code path read is not an execution.**
   AC2 on `ubuntu-latest` proves it.
2. **That the Linux leg compiles.** Section B resolves the Linux lockfile; it
   does not build it. No Linux toolchain or host exists here.
3. **The probe-then-re-exec ordering.** No production instance was found; the
   pattern's re-exec half has one (`code2prompt`), and that same file omits the
   probe (check A61). AC8 proves it.
4. **Whether GNOME/Mutter implements `ext-data-control` at the version Ubuntu
   ships.** Unresolved. It bounds how often the XWayland fallback is the live
   path on a **desktop** Linux machine; it changes nothing on `ubuntu-latest`,
   which has no compositor at all.
5. **`cargo audit` against a committed lockfile.** Not run (no `cargo-audit`
   here). The RustSec HTTP endpoints with their paired controls stand in;
   R67's positive-control method (`anyhow = "=1.0.102"` must reproduce
   RUSTSEC-2026-0190) is what P03 should re-run against the real lockfile.
6. **Any runtime clipboard behaviour on any platform.** Nothing was executed
   against a clipboard, including on this macOS host.
7. **Whether R67's owner reads *"stdout stays byte-empty on the error path"* as
   scoped to failures that produced no result.** Sections 1 and 2 of
   `r62-clipboard-claims-r2.log` establish what each document says; the reading
   is this decision's, argued from the binding standard and from R67's own
   broken-pipe rule, and it is not an owner ruling. The re-verify line records
   the trigger, and the exact substitute wording an unqualified reading would
   require of R67 is written out under `### Principles and implementation` so the
   controller can overrule this disposition without re-deriving it.
