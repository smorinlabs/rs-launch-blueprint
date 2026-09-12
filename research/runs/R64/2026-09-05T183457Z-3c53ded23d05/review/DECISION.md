# R64 — pager-integration — DECISION (revision 2, 2026-09-12)

**Revision note.** Revision 2 rewrites revision 1 (sha256 `920ea3e6d9f4a7ea494ac3f1f958d6682bfb053953450a36364e4b0fc32b9d92`) in place. It answers both findings of the revision-1 empirical audit (`review/audit-codex.md`, archived as `review/audit-codex.r1.md`; actor `audit-codex-2026-09-05T183457Z-3c53ded23d05-r1`, model `gpt-5.6-terra`, family openai, verdict **reject**).

**Finding 1 — the check the decision named was not retained.** Revision 1 said one `verify.sh` produced `review/evidence/r64-pager-claims.log` and that a follow-up invocation appended section 14. No such script was in the run, so an auditor could neither rerun the cited command nor tie that log to it: the log was an output artifact with no reproducible provenance. The script is now retained as `review/evidence/verify.sh` (sha256 `aa90cdc9feba9fae760f2d952fd63a24116ff37e516f8ad3a621d16fe6daaa48`). It runs under `set -o pipefail`, asserts on the **content** it expected through 103 named assertions rather than on any exit code, counts failures, and exits with that count, so it is a check capable of failing. Revision 1's log is preserved unedited as `review/evidence/r64-pager-claims.r1.log` (sha256 `71793a41f6683b395af72b7a40142205e6c827e45e38fe02ebf913961c2c568a`), and the cited log is regenerated from the retained script. `## Empirical check` records the rerun, both diffs and the comparison rule.

**Finding 2 — the recommendation changes, and the gate reading is what moved it.** The tokenizer is now **`shlex = "2.0"`**, not `shell-words = "1.1"`. No new evidence about either crate arrived; a rule changed. Revision 1 was written while the controller's **provisional** reading of fitness gate 2 stood — that a candidate declaring no `rust-version` is *gate-2 unproven*, a weakness to weigh rather than an exclusion. **That ruling was withdrawn on 2026-09-11**, after this item's auditor and R63's auditor independently argued for the strict reading and the controller accepted their argument over their own (`docs/planning/p02/execution-ledger.md`, "RULING WITHDRAWN: fitness gate 2 is read strictly"; quoted in the evidence log, section 15). Under the strict reading gate 2 is a **bar the candidate must clear**, quoting `msrv-policy` in full — declaration in `Cargo.toml` *and* CI testing — and an unknown effective version is not evidence of incompatibility but is insufficient evidence to pass. `shell-words` 1.1.1 declares no `rust-version` and has no CI at all, so it cannot clear the bar and moves to *Excluded by gate*. `shlex` 2.0.1 declares `rust-version = "1.46.0"` and ships an MSRV job that installs toolchain 1.46, so it clears both halves. **The practice evidence that favoured `shell-words` is not withdrawn — it is outranked**, because the prompt answers every fitness gate "per candidate **before** popularity is weighed" and lists a failed gate as an exclusion. The choice is re-argued from the evidence that survives under `### Principles and implementation`; what changes for the template is stated there and in the file-level shape, and it is two lines of code plus one error-handling consequence.

**What the audit confirmed, and this revision preserves.** Four things, each byte-identical to revision 1 and proven so by diff against the revision-1 blob (`## Empirical check`, "Protected regions"): the two behavioural observations reproduced under a pseudo-terminal — what `less` does with SGR bytes with and without `-R`, and what git puts in its pager child's environment, including that it does not override a parent-set value (audit findings 3 and 5a-5b); the **qualification** of the quit-if-one-screen line, which limits `-F` to a resolved pager that is `less` or honours `-F` and names the two things py's height gate also supplies (audit finding 4); the treatment of pager presence on the hosted runners as **unproven**, with the `NotFound` fall-through and stub-pager tests that make the gap harmless (audit finding 5); and the four fixed `- assumes` parameter lines (audit finding 6). Nothing in the tokenizer change touches any of them, and the enumeration that found every location carrying the moved claim is recorded in `## Empirical check`.

Item R64 (`pager-integration`, kind `bundle`, Focused tier, owns no parameter, consumes none). Run `research/runs/R64/2026-09-05T183457Z-3c53ded23d05`. Inputs: `inputs/prompt.md`, `raw/codex-0e3536a58a5718d98015052e96f5ddff83f0fdf2f953008f64761a3551254066.md`, `raw/opus-739eedc3784ce02fbca5a4bd8cc08490e3b0cd1be8435f4aad1bf184b77f4f49.md`, `docs/port/PARAMETERS.md`, and — as evidence for this revision — `review/audit-codex.r1.md` and the withdrawal record in `docs/planning/p02/execution-ledger.md`. Evidence log: `review/evidence/r64-pager-claims.log` (sha256 `d8b6d52cb1d270d3e9d0199c45586c2fc4200c6b3720e71883ed02da94198bf0`), regenerated in full by this revision's run of the retained script.

## Decision

**Adopt paging, in the CLI binary crate only, as a three-part stack:**

> **`shlex = "2.0"`** (resolving today to 2.0.1) for tokenizing the pager command
> string into argv — called only as `shlex::split`, never its `quote`/`join` side, which is
> both the advisory-free half of the crate and the only half this design needs;
> **a two-tier environment resolution policy** — `--no-pager` / `--no-input` / a non-text
> format / a non-terminal result stream disable paging outright, then `RSLB_PAGER`, then
> `PAGER`, then the built-in default `less -FRX`, with a resolved value that is empty or
> exactly `cat` disabling paging, and `LESS=FRX` and `LV=-c` set in the pager child's
> environment **only when the parent does not already set them**; and
> **spawn-and-pipe invocation** through `std::process::Command` with
> `.stdin(Stdio::piped())`, a `Drop` that takes the child's stdin handle (closing the pipe)
> before calling `child.wait()`, and a fall-through to `io::stdout()` whenever resolution,
> tokenization or `spawn()` fails.

No terminal-height measurement and no `terminal_size` dependency; the rendered result is
streamed into the child rather than buffered. Paging is gated on the *result stream* being
a terminal, reusing whatever TTY check R65 selects for F290 rather than adding a second
check, and on the active format being the human text format (R66's surface). The code is
portable `std::process` with no `#[cfg]` gating: where no pager binary exists, `spawn()`
returns `ErrorKind::NotFound` and the output prints normally.

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what this research found and what it recommends; P03 builds the
template and its CI proves the recommendation. If implementation contradicts it, the
decision is revised against this recorded research rather than researched again from
scratch. Every claim that is not yet proven, and what would prove it, is listed under
`## Engines`.

**Ledger rows settled.** `F284` — "Text-mode output paged through the user's pager" — and
`F285` — "Pager command resolution precedence" — area `cli-framework-ux`, origin `py-only`,
verdict `DIVERGENT`, owner R64 (`docs/port/COMMONALITY.md:288-289`;
`docs/port/areas/cli-framework-ux.md:28-29`, read 2026-09-10). This decision names the Rust
realization of both rows. It does not change either row's `DIVERGENT` verdict and it edits
no ledger, index or registry file.

**Owner direction, which settles the adopt-or-omit half of the question.**
`docs/port/OWNER-REVIEW.md:105` records disposition `accept` for R64 with the owner's
words: "Looking at architectural pattern, not the exact library. We'd like a similar pager
pattern for TypeScript and Rust" (2026-09-04, read 2026-09-10). What remained open, and what
this decision answers, is the pattern.

**Baseline-review findings carried forward.** Three `BASELINE-REVIEW:` lines were emitted by the raws. They are carried here as the prompt
requires, **not resolved**: the controller adjudicates them, and no py, ts or ledger file is
changed by this decision. For each, what this review verified and what it did **not** is
stated, because a baseline-review line that overstates its evidence is worse than none.

`BASELINE-REVIEW: F285 — the resolved pager command must carry raw-control-chars regardless of which layer supplied it — replace py's "bake -FRX into the default string only" with git's mechanism: default the command to less -FRX and inject LESS=FRX (and LV=-c) into the pager child's environment when those variables are unset — evidence: py at pin b08bccfb, PAGER=less makes _resolve_pager_command() return the bare "less" (src/py_launch_blueprint/cli/output.py:88,91), which output.py:194-196 runs with no flags, so py's own -R is bypassed precisely when the user has expressed a preference; git avoids this with PAGER_ENV = LESS=FRX LV=-c (Makefile:2288, v2.51.0) applied only if (!getenv(argv[i])) (pager.c:127). Affected items: R64 owns the fix for rs; the follow-on py/ts harmonization project would apply it to output.py:56,88.` (raw: opus)

*Verified in this review.* Four separate pieces, each observed rather than assumed
(full output in the evidence log, sections 1, 3, 4 and 5):

1. py at the pin does return the bare user value: `_resolve_pager_command` is
   `for var in ("PLBP_PAGER", "PAGER"): if var in os.environ: return os.environ[var].strip()`
   (`output.py:88-90`), and the only code path that yields the `-FRX` default is the
   `return DEFAULT_PAGER` at `output.py:91`, reached only when neither variable is set
   (`DEFAULT_PAGER = "less -FRX"` at `:56`; the string also appears in two docstrings,
   `:83` and `:175`, which produce no value).
2. py injects nothing into the child: `subprocess.run(_pager_argv(pager), input=text, text=True, check=False)`
   (`output.py:194-196`) passes no `env=`, and a grep of the whole module for `LESS`, `LV=`
   and `env=` returns no match (exit 1).
3. A `less` invoked without `-R` does display the escape bytes literally. Observed on this
   host under a pseudo-terminal, `less` 668: paging `A\033[31mRED\033[0m B` through
   `less -F` with `LESS` unset renders `A` then a reverse-video `ESC` followed by the
   literal text `[31m`; through `less -FR` the same input renders the raw `\033[31m`
   sequence. This is an observation of `less` on macOS, not of py: py's renderer was not
   executed, so **that py's captured text actually contains SGR sequences at that point is
   a reading of py's own `-R` default and its `rich` capture, not an executed result.**
4. git's injection does what the line says, observed rather than inferred: with `LESS` and
   `LV` unset in the parent, `git -c core.pager=env log -1` under a pseudo-terminal prints
   `LESS=FRX` and `LV=-c` in the pager child's environment; with `LESS=Q` set in the parent,
   the child sees `LESS=Q` — git does not override it. Observed with `git version 2.50.1
   (Apple Git-155)` on this host; the mechanism was separately read at tag v2.51.0
   (`Makefile:2288`, `pager.c:120-131`).

*Not verified.* That py's rendered text is byte-for-byte what a user sees under
`PAGER=less` — py was not run. The finding is a code reading plus an observation of `less`.

`BASELINE-REVIEW: F284 — the paging gate should be "is this an interactive text-mode result stream", not "…and is the rendered output taller than the terminal" — proposed change: drop py's explicit terminal-height measurement and its full-output capture buffer, and let less -F (--quit-if-one-screen) provide the one-screen behaviour, streaming into the pager instead of buffering — evidence: less -F "Causes less to automatically exit if the entire file can be displayed on the first screen" (less(1), less 668); none of git (pager.c, v2.51.0), bat (src/output.rs, v0.26.1), delta (src/utils/bat/output.rs, 0.19.2) or jj (cli/src/ui.rs, v0.45.1) measures terminal height before paging; py's own ADR 0008 gives the reason for the check as "non-less pagers would page one-line results". Cost of the change: terminal_size is not needed, the whole result no longer has to be held in memory, and the user sees the first screen before the command finishes. Cost if wrong: a user whose PAGER is more sees one-line results paged. Affected items: R64 owns the rs design; the follow-on project may apply it to py output.py:184-196.` (raw: opus)

*Verified in this review.* py's height gate and capture buffer are where the line says they
are: `with self.out.capture() as capture:` at `output.py:184`, `if text.count("\n") <
self.out.size.height:` at `output.py:187`. ADR 0008's *Alternatives considered* section says,
verbatim, "**Always page on TTY (no height check)** — rejected: `less -F` would handle it,
but non-less pagers would page one-line results" — so the line quotes py's own reasoning
accurately, and py's ADR itself concedes the `less -F` half. `less` 668's manual on this host
reads "-F or --quit-if-one-screen — Causes less to automatically exit if the entire file can
be displayed on the first screen". A grep for `terminal_size`, `height`, `ws_row`, `term_height`
and `LINES` over the four cited files — `git` `pager.c` at v2.51.0, `bat` `src/output.rs` at
v0.26.1, `delta` `src/utils/bat/output.rs` at 0.19.2, `jj` `cli/src/ui.rs` at v0.45.1 —
returns no match in any of them (four greps, each exit 1).

*Qualified, because the line as written is broader than its evidence.* `-F` supplies the
**display** effect of the height gate **only when the resolved pager is `less`, or another
pager honouring `-F`.** It does not supply two other things py's gate supplies: short output
under `PAGER=more` is still paged, and no child process is spawned at all for short output.
The `LESS=FRX` injection above narrows the first gap to the case where the user's pager is
not `less`; it does not close it. The four-implementation grep establishes that those four
files do not measure height — it does not establish that no part of those codebases ever
consults terminal geometry for another purpose.

*Scope.* This decision adopts the no-height-gate, streaming shape **for rs**, on the
reasoning under `### Principles and implementation`. That is this item's own design choice
and it does **not** adjudicate F284 for py: the ledger row is untouched and the proposal to
change `output.py` is the controller's to accept or reject.

`BASELINE-REVIEW: F284/F285 — readable user-controlled long text — adopt the external-pager capability but replace py's renderer-specific pager mechanism with a Rust render-buffer plus literal-argv subprocess pattern — py is one-sided precedent; bat demonstrates TTY-conditioned automatic paging in a maintained Rust CLI, and Rust Command requires explicit argv rather than shell execution.` (raw: codex)

*Carried, with its status named rather than dropped.* This line proposes no change to any
recorded py or ts behaviour: it proposes a Rust mechanism, which is R64's own scope, and both
raws agree on its literal-argv half (`Command` receives a program plus parsed arguments, never
a string handed to a shell), which this decision adopts. Its one substantive half — buffer the
render before choosing the sink — is the second engine disagreement and is settled under
`## Engines`, Disagreement 2, in favour of streaming. Recorded so the controller sees it; no
baseline change is requested by it.

### Principles and implementation

**The shared requirement, its source, and its agreement level.**

> **P1 (capability).** When a command writes long human-readable results to an interactive
> terminal, the user must be able to scroll them, and the program must obey the pager the
> user has already configured for their other tools rather than imposing one.
> *Source:* `clig.dev`, "Use a pager (e.g. `less`) if you are outputting a lot of text… Use
> a pager only if stdin or stdout is an interactive terminal" (<https://clig.dev/>, retrieved
> 2026-09-10 by the opus raw) — the same document py's `output.py` module docstring cites.
> py implements it (`output.py:177`, pin `b08bccfb`).
> *Agreement level: capability + policy.* All three repos should have the capability and
> share the resolution policy. The mechanism — subprocess plumbing, tokenizer, stream
> ownership — is ecosystem-local and may differ.

> **P2 (policy).** Paging must never change what a non-interactive consumer sees. A piped
> run, a redirected run, a machine format, a `--no-input` script and a CI job all get
> byte-identical output to a program with no pager at all.
> *Source:* py ADR 0008 ("piped runs, `--output-file`, JSON/Markdown modes, and `--no-input`
> scripts must behave exactly as before"), read at the pin; git's `if (!stdout_is_tty)
> return NULL;` (`pager.c:89-90`, v2.51.0, read 2026-09-10).
> *Agreement level: policy — must agree in all three repos.* This is what makes paging safe
> to add at all.

> **P3 (policy).** A pager failure must never lose the user's output and must never change
> the program's exit status.
> *Source:* py ADR 0008 ("a missing pager binary must not lose output"); `bat`
> `src/output.rs:169-172` at v0.26.1, where the fallback is written into the same expression
> as the spawn — `p.stdin(Stdio::piped()) … .unwrap_or_else(|_| OutputType::stdout())`
> (read 2026-09-10).
> *Agreement level: policy — must agree.*

**What must agree across py, ts and rs:** the capability (P1), non-interactive invariance
(P2), never-lose-output (P3), the resolution order `<APP>_PAGER` → `PAGER` → a
`less -FRX`-equivalent default, and the set-but-empty-disables convention. Each is a statement
about observable behaviour with a direct implementation in all three ecosystems.

**What may justifiably vary:** the tokenizer (the `shlex` module in Python's standard library,
the `shlex` crate in Rust — same name, unrelated code, same POSIX word-splitting rules — and
a splitter or `shell: true` in Node), the stream-ownership style (py buffers into a `rich`
capture; rs streams into the child's stdin), and the TTY-detection primitive (Python
`isatty`, Rust per R65, Node `tty.isatty`). None of these moves an acceptance criterion.

**Accidental drift versus justified difference.** ts's absence of paging is recorded as
`absent` with "no recorded reason; prompt notes no ts decision record even considered paging"
(`docs/port/DIVERGENCE-ANALYSIS.md:202`, read 2026-09-10), and `:303` itself flags that the
class-D assignment rests on the inference that this is a scope gap rather than a rejection. A
grep of the ts repository at pin `cb1cbcb2` for `pager` and `less -F` over `src`, `docs` and
`package.json` returns no file (exit 1), confirming the py-only origin. On that evidence ts's
absence is **unconsidered omission, not a considered rejection**; whether it is drift worth
repairing is the follow-on project's call, and this decision changes nothing in ts. py's
buffering, by contrast, is a **justified ecosystem difference**: it renders into a `rich`
capture because the renderer is a `Console` object that owns its own file handle, whereas
Rust's `dyn Write` seam makes streaming the natural shape.

**Two additions this decision makes that py does not have, labelled so they are not mistaken
for inherited behaviour.** (a) A resolved value of exactly `cat` disables paging — git does
this (`pager.c:103`, `if (!*pager || !strcmp(pager, "cat")) pager = NULL;`, read at v2.51.0);
py implements only the empty half. (b) `LESS=FRX` / `LV=-c` injection when unset — git does
this (observed, section 5 of the evidence log); py does not (grep, exit 1). Both are rs
additions matching git, and (b) is the mechanism `BASELINE-REVIEW: F285` proposes.

**Observable acceptance criteria.** These are the criteria; the commands that would check
them are P03's, and **none of them has been run** — no Rust template exists (see
`## Empirical check` for what *was* run).

| # | Given | Then |
|---|---|---|
| A1 | the result stream is not a terminal (`cmd \| cat`, `cmd > file`) | no pager process is created, and stdout bytes equal the same command run with paging disabled |
| A2 | the active format is not the human text format (`--format json`) | no pager process is created |
| A3 | `--no-pager` or `--no-input` is passed | no pager process is created |
| A4 | `RSLB_PAGER` and `PAGER` both set, result stream is a terminal | the process launched is the one named by `RSLB_PAGER` |
| A5 | only `PAGER` set | the process launched is the one named by `PAGER` |
| A6 | neither set | the process requested is `less` with `-F`, `-R` and `-X` in its argv |
| A7 | `RSLB_PAGER=""` (set but empty), or `RSLB_PAGER=cat` | no pager process is created; output goes straight to stdout |
| A8 | `RSLB_PAGER=/nonexistent/binary`, or a value with an unbalanced quote | exit status is unchanged, stderr carries at most a hint, and the full result appears exactly once on stdout |
| A9 | colour is active and a pager is used | the SGR sequences reach the pager's stdin unmodified |
| A10 | the user quits the pager before all output is written | the process exits `0` with no error envelope (R67's `BrokenPipe`-on-result-stream rule) |
| A11 | the crate is used as a library | no pager code runs and no pager dependency appears in the library crate's dependency graph |
| A12 | `LESS` is unset in the parent, and a pager is spawned | the child's environment carries `LESS=FRX`; when the parent sets `LESS`, the child sees the parent's value unchanged |

A4-A7 and A12 must be asserted against a **stub pager script on `PATH` that records its own
argv, its environment and its stdin** — never against a real `less`. Two reasons, and the
second is load-bearing: an integration harness gives the child no TTY, so a real `less`
behaves as `cat` and the *choice* of command is unobservable; and the presence of `less` on
the CI runners is not proven (see `## Engines`), so a check that needs a real `less` would be
a check that can fail for a reason unrelated to the code.

**Architecture alternatives, compared before any library was chosen.**

| Alternative | Representative | Outcome |
|---|---|---|
| A — no pager at all | ts today | Rejected: the owner has directed that rs carry the pattern (`OWNER-REVIEW.md:105`), and ts's absence is an unconsidered omission rather than a rejection. |
| B — self-redirect (`fork` + `dup2` + `exec`, the parent *becomes* the pager) | the `pager` crate 0.16.1; git itself | Rejected on three structural counts. After the redirect there is nothing to fall back to, so P3 cannot hold; it is a whole-process side effect, so A11 cannot be guaranteed for a crate that is also a library; and the crate's `Pager::with_env("MY_PAGER")` *substitutes* the variable consulted rather than layering it above `PAGER`, so the two-tier chain is unrepresentable. git can afford this shape because git owns its whole process. |
| C — in-process pager | `minus` 5.7.2, `sapling-streampager` 0.12.0 | Rejected as the *primary* path: an in-process pager never consults the user's configured pager, contradicting P1 at the root. It is the right shape for an optional built-in fallback, which is exactly how `bat` (`PAGER=builtin`) and `jj` (`ui.pager = ":builtin"`) use it. |
| D — spawn-and-pipe: render into a `Write` the composition root chose, child spawned with `Stdio::piped()`, `Drop`-time close-and-`wait`, fall-through to `io::stdout()` | `bat`, `delta`, `jj` | **Selected.** |

**Why D is *designed* to preserve each principle.** Everything in this paragraph is a
property of the design as specified, argued from the shape of the code and from the same
shape read in the reference implementations. **None of it is an executed result** — no Rust
template exists — and A1-A12 are what would establish that an implementation actually
preserves these principles. P1 is the design's entire mechanism: the user's command is what
gets executed. P2 is structural rather than conditional: paging is not a mode the renderer
switches into, it is a *different `Write` the renderer is handed*, so on every non-interactive
path no pager code is reached at all, which is what makes A11 a property of the composition
root rather than of a runtime check. P3 is served by making every step of resolution fallible
into the same fallback: an unset variable, an empty value, `cat`, an unparsable command and a
missing binary all converge on `io::stdout()`, and `spawn()` fails *before* any byte has been
written. A9 is served by writing the already-styled bytes into the pipe with no transformation
between the renderer and the child's stdin — with one requirement that is easy to get wrong
and is therefore stated: **colour must be resolved against the real stdout, before the pager
child exists.** The pipe is not a terminal, so if R65 lands an auto-detecting colour wrapper
and it were applied to the *pipe*, it would strip the very sequences `less -R` exists to
render.

**Why streaming rather than buffering, and what it costs.** The engines disagree here
(`## Engines`, Disagreement 2). Buffering's stated benefit — recovering when the pager cannot
start — is already provided by the streaming design, because `spawn()` fails before the first
write. The failure buffering uniquely covers is a pager dying *mid-write*, whose common cause
is the user quitting, where re-printing the remainder to the terminal would be wrong, not
right (A10). Streaming's gains follow from the design rather than from any measurement taken
here: peak memory is one write buffer instead of the whole result, and the first screen
reaches the terminal before the last row is produced. Its one real cost: the child is spawned
before the last byte is rendered, so a
renderer that could fail part-way would have already sent partial output. P03 must therefore
keep the rule that only a **completed** result is rendered, which is also what keeps R67's
"stdout stays byte-empty on the error path" intact.

**The lifecycle detail that is easy to get wrong.** The child's stdin handle must be dropped
**before** `wait()`. `less` reads until EOF, and EOF on the pipe is what dropping the write
end produces; calling `wait()` while still holding the handle deadlocks. Both reference
implementations encode this in `Drop` rather than at call sites — `bat` `src/output.rs:207-210`
and `delta` `src/utils/bat/output.rs:57-59`, both read at their pinned tags, 2026-09-10.

**Why `shlex`, with the gate that decides it read as the controller now reads it.** Gate 2 is
the gate that decides this member, and it is read **strictly**: the controller's provisional
"undeclared means unproven, not failed" reading was withdrawn on 2026-09-11 in favour of the
strict one, after this item's auditor and R63's auditor argued for it independently
(`docs/planning/p02/execution-ledger.md`, "RULING WITHDRAWN: fitness gate 2 is read strictly";
evidence log, section 15). The prompt writes each gate as a bar the candidate must clear
*before* popularity is weighed, and quotes `msrv-policy` in full, declaration and CI testing
included. So the question gate 2 asks is not "is this crate's floor low enough" but "is its
floor declared and tested", and one candidate answers it and the other cannot:

| | `shlex` 2.0.1 — **selected** | `shell-words` 1.1.1 — **excluded by gate 2** |
|---|---|---|
| 1 · Licence | `MIT OR Apache-2.0` — **pass** | `MIT/Apache-2.0` (old slash spelling of the dual licence) — **pass** |
| 2 · MSRV | `rust-version = "1.46.0"` in the **published 2.0.1 manifest** (exactly one `rust-version` line; assertion S64/S65) **and** an MSRV job installing toolchain 1.46 in the workflow the **2.0.1 artifact itself ships** (`.github/workflows/test.yml`, assertions S48-S49) — both halves of the policy clause, read at the released version rather than at a moving branch: **pass** | **zero `rust-version` lines** in the published 1.1.1 manifest (assertion S63) and no CI to test one in — **fail**, under the strict reading that is now the programme's. Its floor is probably far below the template's; "probably" is what the gate refuses |
| 3 · Advisory / `unsafe` | page → HTTP 200 listing exactly one advisory, RUSTSEC-2024-0006, `patched = [">= 1.3.0"]`, affected functions `quote`/`join` only, all `< 1.2.1`, and `shlex::split` absent from the affected set (assertions S55-S60) — 2.0.1 is outside the affected range and the only call site this design has is `split`, so **no open advisory: pass**. `unsafe` posture, stated because the gate requires it and because it is what this selection gives up: `split` (`lib.rs:100-104`) collects from `Iterator::next` (`lib.rs:80-88`), whose body is `unsafe { String::from_utf8_unchecked(byte_word) }` under the stated invariant "given valid UTF-8, `bytes::Shlex` will always return valid UTF-8" — **one** unchecked conversion on the selected path | `rustsec.org/packages/shell-words.html` → HTTP 404 (no advisory page); `#![forbid(unsafe_code)]` at `src/lib.rs:12`, the only line in its `src/` carrying the token — **pass, and the stronger `unsafe` posture of the two** |
| 4 · OS matrix | **partial on a CI-badge reading** — CI is four jobs, **all `runs-on: ubuntu-latest`** (assertions S50-S51), so the `ubuntu-latest` leg is evidenced and the `macos-latest` leg is not; answered on source below | **fail on a CI-badge reading** — no CI workflow exists at all; the repository tree is `.gitignore, Cargo.toml, LICENSE-APACHE, LICENSE-MIT, README.md, rustfmt.toml, src, src/lib.rs`, with no `.github` (assertion S46). This is the exact criterion R63 applied to exclude `cliclack` ("repository contains no `.github` directory, so no CI is evidenced") |
| 5 · Features / async | `default = ["std"]`, only other feature `std`, and `split` is **not** behind it (the feature gates only the `std::error::Error` impls); no async coupling; no `[dependencies]` section at all | `default = ["std"]`, only other feature `std`; no async coupling; **no `[dependencies]` section at all** |
| 6 · Size / compile cost | 840 lines across two modules, no dependencies — qualitatively one small codegen unit. No measurement taken and none claimed | one 508-line module, no dependencies — same order, marginally smaller. No measurement taken |

**The count, stated exactly.** Under the strict reading now in force, `shell-words` fails
**two** gates — 2 (no declaration and no CI to test one) and 4 (no CI evidenced at all) — and
`shlex` fails **none** outright, with gate 4 passed on source rather than on a badge, as the
next paragraph argues and limits. Writing this as "one clean pass and one clean fail" would
overstate it; the selection has to survive the true count, and the residual is named below.

**Why gate 4 is answered on source, and what that answer is worth.** Gate 4's own text accepts
"CI badge **or a stated platform list**", and `shlex` publishes neither for macOS. Read as
strictly as gate 2 is now read, gate 4 would exclude *both* tokenizers and leave the item with
no splitter, and the two crate-free fallbacks each fail an approved requirement rather than a
gate: `split_whitespace` cannot reconstruct `PAGER="/opt/my pager/less"`, which is the case P1
exists to serve, and `sh -c` turns a malformed `PAGER` into a shell error instead of a
recoverable one, adds a second process, and is a shape none of the five surveyed tools takes.
For a leaf, dependency-free, pure-Rust crate the gate's underlying question has a direct source
answer: every `cfg(` in either crate's `src/` is a `feature`, `test` or `doc` gate, and neither
contains `target_os`, `cfg(unix)` or `cfg(windows)` code (assertions S96-S98; greps in the
evidence log, section 14), so neither crate *has* a branch that could behave differently on the
two runners. **The residual, plainly:** that is source evidence of no platform-conditional
code, not a green macOS job, and it is weaker than one. It is weaker in a way this design can
absorb — the template's own test suite runs on both runners and would observe any difference,
and a splitter that mis-tokenizes on one OS shows up in the first stub-pager assertion — but an
auditor reading gate 4 as a bar, the way gate 2 is now read, should know that this member
clears it on a reading of its source and not on its CI. Read on the badge alone, the item has
no candidate at all; that is the reason for the source reading, not a preference for the
outcome.

**Why the argument that favoured `shell-words` does not rescue it, and is not withdrawn
either.** Two things told for `shell-words` and both are still true. Its `unsafe` posture is
the stronger: `#![forbid(unsafe_code)]` against one unchecked UTF-8 conversion on `shlex`'s
`split` path. And it is what **both** Rust reference implementations use **for this identical
job** — `bat` declares `shell-words = { version = "1.1.0", optional = true }`
(`Cargo.toml:54`) inside `paging = [ "shell-words", "grep-cli", "minus"]` (`:36`), i.e. the
crate is in `bat` *because of* paging; `delta` declares `shell-words = "1.0.0"`
(`Cargo.toml:51`) and calls `shell_words::split` on the resolved pager command
(`src/utils/bat/output.rs:120`). Both read at their pinned tags, 2026-09-10, and re-read
unchanged by this revision's check. **Neither survives as a selection argument, for a reason
stated in the prompt rather than invented here:** fitness gates are "answered per candidate
**before** popularity is weighed", and "a failed gate lists the candidate under *Excluded by
gate*". Practice evidence and `unsafe` posture are how a shortlist is ordered *after* the
gates, so they cannot promote a candidate that never reaches the ordering. That is also why
this revision does not re-litigate them: they are recorded, they are not contradicted, and
they are the cost of the selection rather than an argument against it.

**What `shlex` brings on its own evidence, weighed after the gate.** Practice evidence for
this identical job favours `shell-words`, and that asymmetry is not smoothed over: of the five
surveyed tools, no Rust one uses the `shlex` *crate* to split a pager command. The one
precedent that does exist for `shlex`-the-name doing exactly this job is py's own — py splits
its resolved pager command with Python's standard-library `shlex` module (`output.py:74`,
`shlex.split(pager)`), an unrelated implementation of the same POSIX rules. What `shlex` has
in Rust instead is the
larger general adoption of the two by roughly six times — 239,394,882 90-day downloads against
37,393,238, and 815,707,385 all-time against 144,826,399 (`crate.recent_downloads` /
`crate.downloads`, retrieved 2026-09-12) — a maintained repository (`archived: false`,
`pushed_at 2026-06-12T19:38:35Z`, 157 stars, 4 open issues, `gh api`, 2026-09-12), the same
POSIX word-splitting contract the design needs, and the one property gate 2 exists to establish:
a floor its maintainer declares and re-tests on every push. Its behaviour at the selected
version was exercised in the Codex raw, which ran the published crate's own suite on macOS
under Rust 1.98.0 — 7 unit tests and 1 doctest passing; **that result is carried from the raw
and was not re-executed here**, and it is evidence about the crate, not about a template that
does not exist.

**Ranked runner-up, and the condition under which it returns.** `shell-words = "1.1"`, on the
two strengths above, is the runner-up **and is currently excluded by gate 2, not merely ranked
second**. It returns to the shortlist on a single, checkable event: the crate publishes a
release declaring `rust-version` in `Cargo.toml` **and** a CI workflow that tests that floor —
both halves, since gate 2 quotes both. If only one half appears, the gate still fails. Nothing
else about it needs to change for the comparison to reopen, and the comparison would then turn
on exactly what it turned on in revision 1: `#![forbid(unsafe_code)]` and `bat`/`delta`
precedent against `shlex`'s larger adoption and its already-declared floor. The **second**
runner-up, if `shlex` itself became unusable — an advisory that reaches `split`, an archived
repository — is `std`-only hand-rolled splitting of the *restricted* grammar the two crate-free
fallbacks cannot handle, and it is recorded here as a shape rather than a recommendation:
quote-aware splitting of a `PAGER` value is a small state machine — `shell-words` implements
the *full* POSIX grammar in 508 lines — and writing it is strictly worse than either crate
while either is healthy, because it moves a correctness surface into the template.

**Excluded, with the reason.** `shell-words` 1.1.1 — **gate 2**, on the strict reading now in
force: no `rust-version` in its published manifest and no CI, so neither half of the policy
clause is evidenced. Its other gates pass and its `unsafe` posture is the best of any candidate
here, which is why it is also the ranked runner-up above rather than a discarded option; a gate
is a bar, and it does not clear this one. `pager` 0.16.1 — architecture B above; additionally
`rust_version: null`, last release 2022-09-22, hosted on GitLab where an unauthenticated API
call returns `open_issues_count: null` and `archived: null`, so those figures are
**unverified, not zero**. `minus` 5.7.2 and `sapling-streampager` 0.12.0 — architecture C
above, excluded on fit before popularity or safety is weighed; `minus`'s `unsafe` posture was
therefore **not audited**, and is recorded as unaudited rather than asserted.
`terminal_size` 0.4.4 is not excluded on any gate — it passes all six, including gate 2
outright with `rust-version = "1.71"` — it is simply not needed by a design with no height
check, and it is the fourth member the buffered variant would add.

**Reference implementations, read at pinned tags (first read 2026-09-10, re-read byte-unchanged
by this revision's check on 2026-09-12; repository figures retrieved 2026-09-12).** `bat`
v0.26.1 (`Cargo.toml`, `src/pager.rs`, `src/output.rs`) — 60,432 stars, `archived: false`,
`pushed_at 2026-09-04T19:10:30Z`; `delta` 0.19.2 (`Cargo.toml`, `src/env.rs`,
`src/utils/bat/output.rs`) — 32,162 stars, `pushed_at 2026-09-12T19:18:44Z`; `jj` v0.45.1
(`cli/src/ui.rs`, `cli/src/config/misc.toml`, `docs/config.md`) — 31,543 stars,
`pushed_at 2026-09-12T19:22:55Z`; `git` v2.51.0 (`pager.c`, `Makefile`) as the reference the
convention descends from. All GitHub figures via `gh api repos/<o>/<r>`, and open-issue
counts via the mandated `search/issues … total_count` endpoint, not `open_issues_count`. The
tag reads are pinned and therefore stable; the star and `pushed_at` figures are live and move,
which is why each carries its own retrieval date rather than one date for the paragraph.

**One dissenter on the chain, recorded rather than smoothed over.** `jj` deliberately ignores
the generic `PAGER`: "The `JJ_PAGER` environment variable overrides `ui.pager`… `PAGER`
environment variable is ignored" (`docs/config.md:895-897`, v0.45.1), with its default
`pager = { command = ["less", "-FRXK"], env = { LESSCHARSET = "utf-8" } }`
(`cli/src/config/misc.toml:39`) — note that `jj` also injects environment into the pager
child. Ignoring `PAGER` is the wrong choice for a *template*, which should not surprise a
user whose `PAGER` works everywhere else, and `jj` is 1 of 5 surveyed tools in doing it.

**File-level shape P03 builds** (proposed; no Rust template file exists today).
`crates/<cli>/Cargo.toml` gains one line, `shlex = "2.0"`, with default features left on —
`default = ["std"]` is what the `std::error::Error` impls need, and `split` itself is not
behind it — and nothing is added to the library or web crates. A new
`crates/<cli>/src/pager.rs` (roughly 60 lines) holds
`resolve_pager`, `spawn_pager` with the `LESS`/`LV` injection, and the paged/plain sink with
its `Write` and `Drop` impls. The renderer takes `&mut dyn Write` instead of writing to
stdout directly — **the one structural change this item causes**, and the one worth making
when the renderer is first written, because retrofitting it later touches every command.
R60's parser gains a global `--no-pager` flag alongside `--no-input`; `main` gains no new
error arm, since `BrokenPipe` on the result stream is already R67's exit-`0` path, but the
sink must be dropped — so the pager is waited on — before the process returns its `ExitCode`.
The generated CLI docs gain a "Paging" subsection naming `RSLB_PAGER`, `PAGER`, the
`less -FRX` default, `--no-pager` and the empty-value convention, because an undocumented off
switch is not an off switch.

**What the tokenizer change costs the template, because it is not literally nothing.** Three
things follow from `shlex` rather than `shell-words`, and only the second needs a decision.
(a) The call site is `shlex::split(&cmd) -> Option<Vec<String>>` rather than
`shell_words::split(&cmd) -> Result<Vec<String>, ParseError>`; both are one line and both
converge on the same fall-through. (b) `None` carries **no diagnostic**, where `ParseError`
has a `Display`. A8 requires that an unbalanced quote in `RSLB_PAGER` leave the exit status
unchanged, put at most a hint on stderr, and print the result exactly once — so the hint must
be composed by the template from the offending value (for example, "ignoring RSLB_PAGER: not
a parsable command"), not forwarded from an error type. That is a sentence P03 writes rather
than inherits, and it is the one behavioural difference between the two crates at this call
site. (c) **The crate must be called only through `split`**, never `quote`, `join` or
`Quoter`: those are the functions RUSTSEC-2024-0006 names, and although 2.0.1 is past its
`>= 1.3.0` patch, keeping the template off that surface means no future advisory on the
quoting side can reach it. P03 should carry the rule where it is enforceable — one import of
the free function, no glob import — because a rule that lives only in a decision document is
not a rule.

**One requirement this decision places on R67, stated once.** While a pager child is alive,
the `SIGINT` path must finish the pager before the process returns its `ExitCode`; it must not
exit `130` and hand the shell prompt back while `less` still owns the terminal. R67 already
owns the mechanism (`RSLB901` SIGINT → 130); this is an ordering constraint on it, not a change
to any value it fixed, so no `CONFLICT:` is raised. If R67 declines the constraint, the fallback
is to change the default command to `less -FRXK` — `jj`'s exact default, whose `-K` /
`--quit-on-intr` makes `less` exit on `^C` by itself — at the cost of one flag of drift from
py's `less -FRX`.

re-verify: on the earliest of — a new RustSec advisory for `shlex` whose affected functions include `split`, or `shlex` being archived, either of which promotes the runner-up if it has by then declared a `rust-version` and a CI job, and otherwise opens the hand-rolled option; `shell-words` publishing a release that declares `rust-version` **and** a CI workflow testing it, which reopens the tokenizer comparison that gate 2 currently closes; the controller or the owner overturning the strict gate-2 reading recorded on 2026-09-11, which would restore revision 1's pick; R65 (`color-enablement-chain`) resolving F290, especially if it wraps the written stream in an auto-detecting colour stream; R05 putting the CLI on an async runtime, which makes the blocking `child.wait()` need a blocking-safe context; R54 landing a config file, which inserts a config tier between `RSLB_PAGER` and `PAGER`; R60 declining a global `--no-pager`; a later item registering an app env-var prefix other than `RSLB`; a maintained pager-invocation crate appearing with `bat`, `delta` or `jj` as an adopter; otherwise 2027-03-12.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

R64's `## Couplings` block lists an empty `owns:` and an empty `consumes:` (quoted in the
evidence log, section 12), so this item registers no parameter in `docs/port/PARAMETERS.md`
and formally consumes none. **No `CONFLICT:` line:** nothing in this recommendation requires
a consumed parameter to change.

How the four fixed parameters bear on the decision. The **MSRV policy** resolves to a floor
of **1.96**, computed from `[pkg.rustc] version = "1.98.1 (48a229cea 2026-09-01)"`
(`https://static.rust-lang.org/dist/channel-rust-stable.toml`, retrieved 2026-09-12 and
unchanged from the 2026-09-10 read), and **it is the parameter that selected the tokenizer**.
Not by its numeric window — both candidates' floors sit far below 1.96 — but by the two
clauses that follow it in the registry value, "declared as rust-version in Cargo.toml and
tested in CI", which fitness gate 2 quotes in full and which the controller's withdrawal of
2026-09-11 made binding on each candidate rather than on the template alone. `shlex` 2.0.1
declares 1.46.0 and ships a CI job that installs 1.46; `shell-words` 1.1.1 declares nothing
and ships no CI. Everything else in the recommendation is
Rust-1.0-era standard library (`std::env::var`, `std::process::Command`, `Stdio::piped`,
`Child::wait`, `io::ErrorKind::BrokenPipe`), so the floor costs the design nothing. The
**edition** is not exercised: editions are per-crate, and the selected crate's declared
`edition = "2018"` links into a 2024-edition consumer unchanged (as would the runner-up's
absent `edition`, i.e. the 2015 ruleset). The **licence** is satisfied — the selected crate
declares `MIT OR Apache-2.0`, byte-identical to the registry value, and the runner-up's
`MIT/Apache-2.0` is the same dual licence in the older slash spelling; nothing in the tree is
copyleft, and neither crate has a `[dependencies]` section for a transitive licence to hide in. The **OS matrix** is where this item's honesty matters
most: the design must work on `ubuntu-latest` and `macos-latest`, and it does so *by
degrading correctly*, not by requiring a pager — where no pager binary exists, `spawn()`
returns `NotFound` and output prints normally. What is **not** established is that `less`
itself is present on either runner; see `## Engines`.

Two values this decision fixes that no registry row owns, recorded here rather than in the
registry. **`RSLB_PAGER`** is the app-specific variable name, derived from the `RSLB`
error-code prefix R67 fixed; a grep of `docs/port/PARAMETERS.md` for `short-name`,
`env-prefix`, `app-short` and `app-env` returns no match (exit 1, evidence log section 12),
so no parameter owns the application's environment-variable prefix and this is a **derived,
unregistered assumption**. If a later item registers a prefix parameter with a different
value, the variable is renamed and no part of the design changes. **`less -FRX`** is the
built-in default, byte-identical to py's `DEFAULT_PAGER` (`output.py:56`), preserving
cross-repo agreement at the value level; it diverges by one flag from `clig.dev`'s
`less -FIRX`, and that divergence is recorded here rather than silently dropped — `-I` only
affects case sensitivity of in-pager searches, which a user's own `LESS` can set.

Five couplings are related but **not registry-consumed**, and are named because they decide
whether the design works: R65 supplies the "is this stream a terminal" check this item's gate
reuses and must resolve colour against the real stdout rather than the pager pipe; R66
supplies "is the active format the human text format"; R67 supplies the
`BrokenPipe`-to-exit-`0` rule and the SIGINT handling; R60 owns registering `--no-pager`; R54
owns whether a config tier exists to slot between `RSLB_PAGER` and `PAGER`. None requires a
different value than it currently has.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4, build 25E246, `arm64`. Current
published stable at check time: `1.98.1 (48a229cea 2026-09-01)`. Also of record because two
checks depend on them: `less 668 (POSIX regular expressions)` and
`git version 2.50.1 (Apple Git-155)`, both as installed on this host. Every value in this
paragraph was re-observed unchanged by revision 2's run on 2026-09-12.

**What this check does and does not do.** It verifies the raws' claims by querying the
recorded endpoints, reading both pinned source repositories through their pins, reading the
candidate crates' source **and manifests** from their **published crates.io artifacts**,
reading the four reference implementations at pinned tags, and **observing two behaviours
directly under a pseudo-terminal** — what `less` does with ANSI bytes with and without `-R`,
and what git actually puts in its pager child's environment. Revision 2 adds the evidence the
strict gate-2 reading makes decisive: each candidate's `rust-version` declaration counted in
its own published manifest and cross-checked against the crates.io versions endpoint, and the
CI half of the same clause read **inside the published 2.0.1 artifact**, which ships
`.github/workflows/test.yml` and the release commit it was cut from — so the "tested in CI"
finding is tied to the version this decision names instead of to the crate's moving default
branch, which is where revision 1 read it and said so. It implements nothing: no crate was
scaffolded, no pager was wired, no `Cargo.toml` was written, no `cargo build` or `cargo test`
was run, and no template file exists to run anything against.

**Working directory.**
`/private/tmp/claude-501/-Users-stevemorin-c-rs-launch-blueprint-p02-plan/b7c06b2f-d78d-4987-b237-63eeced4bd23/scratchpad/r64`
(published `.crate` artifacts downloaded and unpacked read-only under `./src`). The two
pinned repositories were read in place with `git -C … show <pin>:<path>`; neither working
tree was consulted.

**Command, and this time it is retained.** One script, `review/evidence/verify.sh`
(sha256 `aa90cdc9feba9fae760f2d952fd63a24116ff37e516f8ad3a621d16fe6daaa48`), run from the evidence directory as

    bash verify.sh > r64-pager-claims.log 2>&1

**Exit status 0**, which for this script means **zero failed assertions**, because the script
counts its failures and exits with that count. It opens with `set -uo pipefail`, so a failing
command inside a pipeline cannot be masked by a succeeding `head` or `grep` after it, and
every load-bearing claim is checked by one of three helpers that compare the **content**
expected — `assert_has` (a literal substring must be present), `assert_hasre` (a pattern must
match), `assert_absent` (a pattern must **not** match) — or by `assert_eq`, which compares two
values and prints both when they differ. There are **103** such assertions, each printed
inline with its identifier (`S00`…`S99`, plus the four `S95-<param>` parameter comparisons) and
listed again in the new section 16. That the script is capable of failing is not asserted but
observed: its first run reported three failures — a grep pattern that did not emit py's height
gate, and two `LV=` captures the pseudo-terminal had prefixed so an anchored match missed
them. Both were defects in the check, both were fixed, and a script written to pass would have
reported neither.

Greps whose expected result is "no match" still print their exit status and the expected value
on the following line, so an expected `1` is never mistaken for a failure; the difference from
revision 1 is that each is now also backed by an `assert_absent` that fails loudly if a match
ever appears. Sections 0 to 14 keep revision 1's numbering **byte-identical**, including
section 13's "done" marker sitting between 12 and 14, so that every "section N" citation in
this decision still resolves; sections 15 and 16 are new. Sections:

    0   toolchain, host, current stable channel
    1   py pin b08bccfb: output.py lines 50-110 and 165-205 numbered, the load-bearing
        line numbers, ADR 0008's height reasoning, and whether py injects LESS/LV
    2   ts pin cb1cbcb2: git grep for any pager integration
    3   less 668 on this host: -F, -R, -X, -K and the LESS environment variable, from man
    4   OBSERVED under a pty: ANSI through `less -F`, `less -FR`, and bare `less` with LESS=FRX
    5   OBSERVED under a pty: git's pager-child environment, with LESS unset and with LESS set;
        git's own PAGER_ENV mechanism at tag v2.51.0
    6   crates.io figures for 8 crates: recent_downloads, downloads, newest unyanked version,
        created_at, license, rust_version, edition, features
    7   GitHub figures via gh api for 6 repositories; open issues via search/issues total_count;
        shell-words' full repository tree; shlex's CI workflow and release commit, read from
        inside the published 2.0.1 artifact
    8   RustSec pages for 6 candidates plus the `time` control; RUSTSEC-2024-0006's own TOML
    9   published artifacts of shell-words 1.1.1 and shlex 2.0.1: manifest, every rust-version
        line, crate attributes, every `unsafe`, the split entry point, dependencies, line counts
    10  bat v0.26.1, delta 0.19.2, jj v0.45.1, git v2.51.0 at pinned tags: the spawn, the
        Drop-time wait, the shell-words call, the chain — and whether any measures terminal height
    11  whether `less` is present on the CI runners
    12  this repository: ledger rows, owner direction, divergence rows, the couplings block, and
        the four fixed parameters compared byte-for-byte with the registry
    13  the first-pass timestamp, kept in revision 1's position so later citations still resolve
    14  platform-conditional code in the two tokenizers; the exact unsafe site on shlex::split
    15  NEW: gate 2 under the strict reading — each candidate's declared rust-version from two
        independent sources, the CI half read at the 2.0.1 release artifact, the floor the
        policy resolves to, and the controller's withdrawal record quoted from the ledger
    16  NEW: the assertion summary — all 103 identifiers with PASS/FAIL, the counts, and the
        retrieval timestamp

**The rerun, the diff, and the rule for comparing across them.** The cited log
`review/evidence/r64-pager-claims.log` (sha256 `d8b6d52cb1d270d3e9d0199c45586c2fc4200c6b3720e71883ed02da94198bf0`) is the output of one full run of
the retained script. The script was then run **a second time**, minutes later, into a scratch
path, and the two outputs diffed before this paragraph was written. **The rerun differs from
the cited log in exactly two lines, and both are timestamps** — section 13's `date -u` marker
and the closing `retrieved:` line. Everything else is byte-identical, the pseudo-terminal
captures and every registry and GitHub figure included, because the two runs are minutes apart.
**The comparison rule, for a reader rerunning this across days rather than minutes:** two
classes of line are live and will differ — (a) those two timestamps, and (b) every figure taken
from a live endpoint, namely `crate.recent_downloads`, `crate.downloads`, `"stars"`,
`"pushed_at"` and `open_issues_total_count`. A difference **anywhere else** is drift to
investigate, not noise to absorb: the pinned reads (py and ts at their commit pins;
`bat`/`delta`/`jj`/`git` at their tags; both crates from their immutable published artifacts),
the RustSec statuses and the advisory's own TOML, the runner-image match counts, this
repository's greps and all 103 assertion lines must reproduce byte-for-byte — and each of them
did, across both runs here.

**What revision 1's log is, and what this script is not.** Revision 1's log is retained
unedited as `review/evidence/r64-pager-claims.r1.log`. The retained script is a
**reconstruction** of the check revision 1 described, not a byte-for-byte reproducer of its
output, and nothing here claims otherwise: diffing the two logs shows 82 lines removed and 385
added. The differences are of five kinds, each named rather than waved at. (1) The 103
assertion lines and sections 15 and 16, which revision 1's log had no equivalent of. (2) The
`[HTTP nnn]` lines, which now carry the URL they belong to. (3) The `man less` extract,
rendered at a fixed `MANWIDTH=80` so it is reproducible, which rewraps the same sentences
revision 1 quoted. (4) The pseudo-terminal captures, whose framing bytes differ from revision
1's — this script uses the argv the revision-1 **audit** published, and reproduces that audit's
captures — while the load-bearing content is identical in both: `less -F` shows a reverse-video
`ESC` followed by the literal `[31m`, and `less -FR` and a bare `less` under `LESS=FRX` pass
`^[[31m` through. (5) The live figures, drifted by two days exactly as the rule above predicts.
What is provably unchanged: **every one of revision 1's fifteen section headers appears in the
new log, in the same order, with no header text altered**, so every "section N" citation in
this decision resolves against either log.

**Observed output — the findings that bear on the decision.**

- **py at the pin is exactly as the F285 line states.** `DEFAULT_PAGER = "less -FRX"` at
  `output.py:56`; `for var in ("PLBP_PAGER", "PAGER")` at `:88` returning
  `os.environ[var].strip()` at `:90`; the paging gate
  `if not (self.paging and self.out.is_terminal and _isatty(self.out)):` at `:177`; the
  capture buffer at `:184`; the height gate `if text.count("\n") < self.out.size.height:` at
  `:187`; `subprocess.run(_pager_argv(pager), input=text, text=True, check=False)` at
  `:194-196` with **no `env=` argument**. A grep of the module for `LESS`, `LV=` and `env=`
  returns no match (exit 1). Every line number the opus raw cited reproduces.
- **ADR 0008 concedes the `less -F` half itself.** "**Always page on TTY (no height check)**
  — rejected: `less -F` would handle it, but non-less pagers would page one-line results."
- **ts ships no pager integration.** `git -C ~/c/ts-launch-blueprint grep -il 'pager|less -F'
  cb1cbcb2… -- src docs package.json` returns no file (exit 1).
- **OBSERVED — a bare `less` does lose the colour.** Paging `A\033[31mRED\033[0m B` under a
  pseudo-terminal: with `LESS` unset, `less -F` renders a reverse-video `ESC` followed by the
  literal `[31m`; `less -FR` renders the raw `\033[31m` byte sequence; and bare `less` with
  only `LESS=FRX` in the environment also renders the raw sequence. This is `less` 668 on
  macOS; it is not an observation of py, which was not executed.
- **OBSERVED — git's injection, and its "only if unset" half.** `git -c core.pager=env log -1`
  under a pseudo-terminal, with `LESS` and `LV` unset, prints `LESS=FRX` and `LV=-c` in the
  child's environment. With `LESS=Q` set in the parent, the child prints `LESS=Q` — git does
  not override a value the user set. Source at v2.51.0: `PAGER_ENV = LESS=FRX LV=-c`
  (`Makefile:2288`) applied under `if (!getenv(argv[i]))` (`pager.c:127`).
- **git's own resolution chain, read at v2.51.0.** `pager.c:85-106`: return `NULL` unless
  stdout is a tty; `GIT_PAGER`, then `core.pager`, then `PAGER`, then `DEFAULT_PAGER`, which
  `pager.c:11-12` defines as the bare string `"less"` — git's flags come *entirely* from the
  `LESS` injection; and `if (!*pager || !strcmp(pager, "cat")) pager = NULL;` at `:103`.
- **None of the four cited pager files measures terminal height before paging.** Greps for
  `terminal_size|height|ws_row|term_height|LINES` over `git` `pager.c` (v2.51.0), `bat`
  `src/output.rs` (v0.26.1), `delta` `src/utils/bat/output.rs` (0.19.2) and `jj`
  `cli/src/ui.rs` (v0.45.1) each return no match (four greps, exit 1). This covers those four
  files, not those four codebases.
- **The spawn-and-pipe shape reproduces in all three Rust tools.** `bat`
  `src/output.rs:169-172` — `p.stdin(Stdio::piped()) … .unwrap_or_else(|_| OutputType::stdout())`
  — with `fn drop` at `:207` and `command.wait()` at `:210`; `delta`
  `src/utils/bat/output.rs:120` `shell_words::split(`, `:146` `.stdin(Stdio::piped())`,
  `fn drop` at `:57` and `command.wait()` at `:59`; `jj` `cli/src/ui.rs:78`
  `let mut child = cmd.stdin(Stdio::piped()).spawn()?;` and `child.wait()` at `:123`.
- **`bat` and `delta` use `shell-words` for this exact job.** `bat` `Cargo.toml:36`
  `paging = [ "shell-words", "grep-cli", "minus"]` and `:54`
  `shell-words = { version = "1.1.0", optional = true }`; `delta` `Cargo.toml:51`
  `shell-words = "1.0.0"`. This is the practice evidence that favoured the runner-up. It is
  recorded here because it is true and reproduces; it is **outranked** by gate 2 rather than
  withdrawn, for the reason given under `### Principles and implementation`.
- **Registry figures, retrieved 2026-09-12** (`GET https://crates.io/api/v1/crates/<name>`,
  `crate.recent_downloads` / `crate.downloads`; newest unyanked from `…/versions`):
  `shell-words` 37,393,238 / 144,826,399, newest 1.1.1 `2025-12-10T20:48:28.942402Z`,
  `license: MIT/Apache-2.0`, `rust_version: None`, `edition: None`, `features {default:[std], std:[]}`;
  `shlex` 239,394,882 / 815,707,385, newest 2.0.1 `2026-05-17T18:56:12.775983Z`,
  `MIT OR Apache-2.0`, `rust_version: 1.46.0`, `edition: 2018`,
  `features {default:[std], std:[]}`;
  `pager` 116,439 / 842,168, newest 0.16.1 `2022-09-22T15:56:55.250446Z`, `rust_version: None`,
  repository on GitLab; `minus` 436,236 / 1,603,141, newest 5.7.2
  `2026-07-15T06:58:43.195787Z`, `rust_version: None`, `edition: 2024`;
  `sapling-streampager` 1,146,228 / 2,943,290, newest 0.12.0 `2026-01-15T18:58:13.235965Z`,
  `license: MIT`, `repository: None`; `terminal_size` 38,531,925 / 202,655,785, newest 0.4.4
  `2026-03-23T16:39:14.510986Z`, `rust-version 1.71`; `grep-cli` 2,056,809 / 9,526,176;
  `bat` 781,615 / 4,581,131, newest 0.26.1, `rust-version 1.87`. Every one of these download
  counters moved between revision 1's read on 2026-09-10 and this one; the version numbers,
  release timestamps, licences, `rust_version` values and feature sets did not.
- **GitHub, retrieved 2026-09-12 via `gh api` (authenticated with the user's token, not
  anonymous):** `tmiasko/shell-words` 86 stars, `archived: false`,
  `pushed_at 2025-12-10T20:50:02Z`, **3** open issues by `search/issues` `total_count`;
  `comex/rust-shlex` 157 stars, `archived: false`, `pushed_at 2026-06-12T19:38:35Z`,
  **4** open issues; `sharkdp/bat` 60,432 / 331; `dandavison/delta` 32,162 / 310;
  `jj-vcs/jj` 31,543 / 810; `AMythicDev/minus` 372 / 10.
- **`shell-words` has no CI at all; `shlex` 2.0.1 ships its CI inside the published crate, and
  that CI has no macOS.** `shell-words`' full repository tree is `.gitignore, Cargo.toml,
  LICENSE-APACHE, LICENSE-MIT, README.md, rustfmt.toml, src, src/lib.rs` — no `.github`, so
  there is no workflow to read at any revision. `shlex`'s published 2.0.1 artifact **contains**
  `.github/workflows/test.yml` alongside `.cargo_vcs_info.json`, which records the release
  commit `e82b1411beb7c92871c2c078c9ab415bbcf207ef`; that workflow is four jobs — stable, beta,
  `--no-default-features`, and `name: Test (MSRV)` running `rustup toolchain install 1.46` /
  `rustup default 1.46` — **every one `runs-on: ubuntu-latest`**, zero occurrences of `macos`,
  and the stable job also builds a `fuzz` workspace. This replaces revision 1's reading of the
  same workflow at the moving `master` branch: the finding is now tied to the exact version the
  recommendation pins, which is what gate 2 asks about.
- **RustSec, retrieved 2026-09-12, with a control.** HTTP 404 for `shell-words`, `pager`,
  `minus`, `sapling-streampager` and `terminal_size` (0 `RUSTSEC-` mentions each); HTTP 200
  for `shlex` (the page lists exactly one advisory id, RUSTSEC-2024-0006) and for the control
  `time` (4 mentions). The control establishes that 404 means "no advisory page", not a
  failed retrieval. RUSTSEC-2024-0006's own TOML: `patched = [">= 1.3.0"]`,
  `[affected.functions]` = `shlex::quote`, `shlex::join`, `shlex::bytes::quote`,
  `shlex::bytes::join`, each `< 1.2.1`.
- **From the published artifacts.** `shell-words` 1.1.1: `#![forbid(unsafe_code)]`
  (`src/lib.rs:12`) and `#![cfg_attr(not(feature = "std"), no_std)]` (`:11`); the only line in
  `src/` containing the token `unsafe` is that `forbid` attribute; `pub fn split(s: &str) ->
  Result<Vec<String>, ParseError>` at `:126`; 508 lines; **no `[dependencies]` section**.
  `shlex` 2.0.1: `rust-version = "1.46.0"`, `edition = "2018"`; `pub fn split(in_str: &str) ->
  Option<Vec<String>>` at `:100`, which collects from `impl Iterator for Shlex::next`
  (`:80-88`) whose body is `unsafe { String::from_utf8_unchecked(byte_word) }` with the
  comment "given valid UTF-8, `bytes::Shlex` will always return valid UTF-8"; 840 lines
  across two modules; **no `[dependencies]` section**. In both crates every `cfg(` in `src/`
  is a `feature`, `test` or `doc` gate, and neither has `target_os`, `cfg(unix)` or
  `cfg(windows)` code (the `unix`/`windows` hits are prose in comments and documentation).
- **The gate-2 counts, taken from the manifests themselves rather than from a summary field.**
  Counting `^rust-version` lines in each published manifest: `shell-words` 1.1.1 has **0**,
  `shlex` 2.0.1 has **1**, and that one reads `rust-version = "1.46.0"` (assertions S63-S65,
  evidence log sections 9 and 15). Both counts agree with the `rust_version` field the
  crates.io versions endpoint returns for the same versions (assertions S39, S41), so the
  finding rests on two independent sources. `shlex`'s `split` is **not** behind its `std`
  feature — the feature gates the `std::error::Error` impls — so the declaration and the CI
  job cover the code path this design uses.
- **`less` on the CI runners — what is and is not established.** Observed on this macOS host:
  `/usr/bin/less`, `less 668`. The `actions/runner-images` README for Ubuntu 24.04 does not
  contain the word `less` anywhere (match count **0**), although it does carry an "Installed
  apt packages" section, so the silence is informative; the macOS 15 README likewise contains
  no match (count **0**); and the image's own `toolsets/toolset-2404.json` does not list
  `less` in `vital_packages`, `common_packages` or `cmd_packages`. `less` **is** packaged for
  Ubuntu noble — `packages.ubuntu.com/noble/less` returns HTTP 200 for
  `Package: less (590-2ubuntu2.1 and others)`. Presence on a GitHub-hosted runner is therefore
  **not proven**; carried under `## Engines`.
- **This repository.** `F284`/`F285` at `docs/port/COMMONALITY.md:288-289`, both `py-only`,
  `DIVERGENT`, item R64; `docs/port/OWNER-REVIEW.md:105` disposition `accept` with the owner's
  pattern direction; `docs/port/DIVERGENCE-ANALYSIS.md:202` (ts `absent`, class D, harmonize
  `partly`) and `:303` (the recorded caveat that R64's D-versus-F classification rests on an
  inference); the couplings block with `owns:` and `consumes:` both empty; and no
  env-var-prefix parameter in `docs/port/PARAMETERS.md` (grep exit 1).

**Enumeration before editing, and the protected regions proven by diff.** The contract's rule
for revising after a rejection is to enumerate mechanically rather than by re-reading, so
before any edit the revision-1 text was searched for every line carrying a subject the change
could move — `shell-words`, `shell_words`, `shlex`, `ParseError`, `Option<Vec`, `gate 2`,
`runner-up`, `tokeniz`, `forbid(unsafe_code)`, `1.1.1`, `2.0.1`, `"1.1"`, `"2.0"`, `strict`,
`provisional`, `UNPROVEN`/`unproven`, `effective MSRV`, `Settled in Opus`, `verify.sh`,
`r64-pager-claims`, `A11`, `cargo tree`, `unsafe` — giving **97 locations**, and that list was
the work queue. **66** were rewritten. **31** were left verbatim, each re-read and confirmed
still correct: the disagreements about streaming, `LESS`/`LV` injection and the variable name,
which the tokenizer does not touch; the observations about the two crates' source, which are
facts rather than arguments; the two raws' own recorded recommendations; and the
`bat`/`delta` practice evidence, which is preserved as the runner-up's case rather than
deleted. The same search was re-run against the edited file and every entry now carries either
the new selection or the condition under which the old one returns.

In the other direction, six regions the audit **confirmed** were extracted from the
revision-1 blob (`git show f80a0cf:…/review/DECISION.md`, sha256
`920ea3e6d9f4a7ea494ac3f1f958d6682bfb053953450a36364e4b0fc32b9d92`) and compared against this
revision: the carried `BASELINE-REVIEW` findings for F285 and F284 with their *Verified*,
*Qualified* and *Scope* paragraphs (73 lines); the A1-A12 acceptance criteria with the
stub-pager paragraph (25 lines); the four `- assumes` lines (4 lines); the two OBSERVED
pseudo-terminal bullets (10 lines); the `less`-on-the-runners empirical bullet (9 lines); and
the matching unproven item under `## Engines` (12 lines). **All six are byte-identical, 133
lines with zero differing lines.** The whole-file diff against that blob is 17 unified hunks,
147 lines removed and 354 added.

**Retained artifacts, all three under
`research/runs/R64/2026-09-05T183457Z-3c53ded23d05/review/evidence/`:** `verify.sh`, the check
itself; `r64-pager-claims.log`, its full output and the log every citation above points at;
and `r64-pager-claims.r1.log`, revision 1's output kept unedited so the reconstruction diff
described above can be reproduced.

## Engines

- codex `raw/codex-0e3536a58a5718d98015052e96f5ddff83f0fdf2f953008f64761a3551254066.md` — figures retrieved 2026-09-05; recommends `shlex` 2.0.1 + `std::process::{Command, Stdio}` with a render-buffer sink; env var `RS_LAUNCH_BLUEPRINT_PAGER`; no `LESS` injection; excludes `pager` and `minus`.
- opus `raw/opus-739eedc3784ce02fbca5a4bd8cc08490e3b0cd1be8435f4aad1bf184b77f4f49.md` — figures retrieved 2026-09-10; recommends `shell-words` 1.1.1 + a two-tier resolution policy with `LESS`/`LV` injection + streaming spawn-and-pipe; env var `RSLB_PAGER`; emits the two py-facing `BASELINE-REVIEW:` lines.

Both engines independently reached the same architecture — external pager, resolved from an
app-specific variable before `PAGER` with a `less -FRX` default, spawned through
`std::process::Command` with a piped stdin, argv passed literally and never through a shell,
falling through to stdout on any failure — and both excluded the `pager` crate and the
in-process pagers on the same structural grounds. The disagreements, and the evidence that
settled each:

1. **The tokenizer — the one disagreement that changes a `Cargo.toml` line, and the one this
   revision reverses.** Codex picks `shlex` 2.0.1 **because** it declares
   `rust-version = 1.46.0` and tests it in CI; Opus picks `shell-words` 1.1.1 on `bat` and
   `delta` precedent and `#![forbid(unsafe_code)]`. **Both raws overstate their candidate's
   gate result**, and re-checking every gate showed by how much: `shell-words` fails **two** —
   2, with zero `rust-version` lines in its published manifest and no CI to test one, and 4,
   no CI evidenced at all, which is R63's own `cliclack` criterion — while `shlex` fails none
   outright, its gate 4 being answered on source rather than on a macOS job, and its `split`
   path executing one `unsafe` unchecked-UTF-8 conversion. **Settled in Codex's favour**, and
   the reason is exactly the reason Codex gave: under the strict reading of gate 2 that the
   controller adopted on 2026-09-11, having a declared and CI-tested floor is not a tie-breaker
   but the bar, and only one candidate clears it. Revision 1 settled this the other way, on
   gate 3's `unsafe` posture plus survey steps 3-4, while the controller's provisional
   "unproven, not failed" reading stood; that reading was withdrawn, and with it the ranking in
   which practice evidence could outweigh an unmet gate. The programme's apparent precedent
   both ways — R63 excluding four crates on gate 2 for an undeclared `rust-version`, R33
   selecting a stack containing two crates that declared none — is now settled the strict way
   for every crate item, which was the point of raising it. What does **not** change either
   way: the design, its policy, its invocation shape and all twelve acceptance criteria.
2. **Buffer versus stream.** Codex renders into a `Vec<u8>` and then chooses a sink, "so
   pager startup failure is recoverable before bytes are lost"; Opus streams into a
   `Box<dyn Write>`. **Settled in Opus's favour**, on the observation that `spawn()` fails
   before the first byte is written, so the recoverability Codex is buying is already present
   — and that the failure buffering uniquely covers is the user quitting the pager, where
   re-printing would violate A10 rather than satisfy it. `bat`, `delta` and `jj` all stream
   (source lines in `## Empirical check`). The cost of the choice is named in `## Decision`
   rather than hidden: the child is spawned before rendering completes.
3. **The `LESS`/`LV` injection.** Codex's design has none, so under `PAGER=less` its
   recommendation reproduces the very defect Opus's F285 line reports. **Settled in Opus's
   favour** by direct observation: git injects `LESS=FRX` and `LV=-c` into the pager child
   and does not override a parent-set value, and a bare `less` displays ANSI escapes
   literally while the same `less` under `LESS=FRX` does not.
4. **The environment-variable name.** Codex proposes `RS_LAUNCH_BLUEPRINT_PAGER`, Opus
   `RSLB_PAGER`. **Settled in Opus's favour**: `RSLB` is the prefix R67 already fixed for the
   error-code catalog, and no registry row owns an env-var prefix (grep exit 1), so deriving
   from R67 is the only anchored choice available. It remains a derived, unregistered value.
5. **The `pager` crate's figures.** Codex reports it as excluded without GitHub figures; Opus
   queried GitLab, where an unauthenticated request returns `open_issues_count: null` and
   `archived: null`. Neither raw could measure its issue responsiveness, and this review did
   not re-attempt it. Those figures are **unverified, not zero** — the exclusion rests on
   architecture, not on them.
6. **Figure drift, now measured twice.** The two raws' download figures differ by their
   retrieval dates (2026-09-05 versus 2026-09-10), and revision 1's own figures are two days
   older than revision 2's. Revision 1 re-queried on 2026-09-10 and reproduced Opus's
   `shell-words` and `shlex` figures exactly; revision 2 re-queried on 2026-09-12 and **every**
   download counter had moved, in the direction and by the order of magnitude a two-day
   increment predicts (`shell-words` 36,835,500 → 37,393,238 90-day; `shlex` 235,305,397 →
   239,394,882). Every figure quoted in this decision now carries the 2026-09-12 date, and no
   version number, release timestamp, licence or `rust_version` value moved with them. This is
   the drift the comparison rule in `## Empirical check` exists to classify, and it is why that
   rule names the counters explicitly rather than saying "figures may vary".
7. **Codex's GitHub rate-limiting.** Codex recorded `shlex`'s stars, `archived` and
   `pushed_at` as unverified after anonymous rate-limiting. Revision 1 supplied them through
   `gh api`: 156 stars, `archived: false`, `pushed_at 2026-06-12T19:38:35Z`; revision 2's
   re-query returns 157 stars with the same `archived` and `pushed_at`. The
   ten-most-recent-issue responsiveness median for `shell-words` (46.91 days over 4 answered
   of 8) and for `minus` (70.87 days over 5 of 9) is **carried from the Opus raw and was not
   re-walked here**; only the open-issue totals were re-verified.

**Unproven claims, carried forward for P03 to prove in the real template.**

- **That `less` exists on the CI runners.** What is established: `less` 668 is at
  `/usr/bin/less` on this macOS development host (observed), and `less` is packaged for
  Ubuntu noble (`packages.ubuntu.com/noble/less`, HTTP 200). What is **not** established:
  presence on a GitHub-hosted `ubuntu-latest` or `macos-latest` runner. The Ubuntu 24.04 and
  macOS 15 runner-image READMEs contain no mention of `less` (match count 0 in each), and the
  Ubuntu image's `toolset-2404.json` does not install it explicitly, so its presence would
  rest on it being a base-system package — which this review did not verify on a runner. *What
  would prove it*: a one-line P03 CI step, `command -v less && less --version`, on both
  runners. Two consequences are already built into this decision so that the gap cannot
  break anything: the fallback for a missing pager is the same as for any other spawn failure
  (print normally), and every precedence acceptance check must assert on a stub pager's
  recorded argv rather than on a real `less`.
- **Every one of the twelve observable acceptance criteria.** No Rust crate exists in this
  repository, so none has been executed. *What would prove them*: the integration tests
  described in `## Decision`, driven by a stub pager script on `PATH` that records its argv,
  its environment and its stdin, run on both runners, plus
  `cargo tree -p <library-crate> | grep shlex` returning nothing and
  `cargo tree -p <cli-crate> -i shlex` showing the crate with no children, to prove A11.
- **That `shlex` 2.0.1 compiles at the template's own floor.** What is established is what
  gate 2 asks for and no more: the crate *declares* `rust-version = "1.46.0"` and its shipped
  CI installs toolchain 1.46 on every push. Neither is a compilation at **1.96**, the floor
  `msrv-policy` resolves to today, and a declaration below a floor is evidence rather than
  proof — a newer compiler can reject older code for reasons unrelated to the declaration.
  *What would prove it*: the `cargo +1.96 check --locked` MSRV job the `msrv-policy` parameter
  already requires, run against the template's real manifest. This replaces revision 1's
  unproven item, which was the *absence* of a declaration in `shell-words`; that gap is now an
  exclusion rather than an open question.
- **Identical tokenizer behaviour on Ubuntu and macOS.** Established by source reading — no
  `target_os`, `cfg(unix)` or `cfg(windows)` code in either crate — and **not** by CI, which
  neither crate provides for macOS. *What would prove it*: the template's own test suite
  running on both runners.
- **That py's captured text carries SGR sequences at the point it reaches the pager.** Read
  from py's `-R` default and its `rich` capture; py was not executed. This is the one
  inferential step inside `BASELINE-REVIEW: F285`, and the follow-on project should run py
  under `PAGER=less` before acting on the line.
- **Binary size and compile time.** Stated qualitatively by both raws and by this decision.
  No measured figure exists and none is claimed; none can until P03 builds the template.
- **Performance.** No benchmark was run for any candidate and none is claimed. The one
  quantitative statement either raw makes about spawn cost carries no workload,
  configuration, instrumentation or resource conditions, and is not repeated here.
