# R64 — pager-integration — DECISION

## Decision

**Adopt paging, in the CLI binary crate only, as a three-part stack:**

> **`shell-words = "1.1"`** (resolving today to 1.1.1) for tokenizing the pager command
> string into argv — called only as `shell_words::split`, never its `quote`/`join` side;
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

**What may justifiably vary:** the tokenizer (`shlex` module in Python, `shell-words` in Rust,
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

**Why `shell-words`, and the gate result stated honestly.** Neither shortlisted tokenizer
clears every fitness gate on its own metadata, and saying otherwise would be the
over-claim this programme keeps rejecting:

| | `shell-words` 1.1.1 | `shlex` 2.0.1 |
|---|---|---|
| 1 · Licence | `MIT/Apache-2.0` (old slash spelling of the dual licence) — **pass** | `MIT OR Apache-2.0` — **pass** |
| 2 · MSRV | `rust_version: null`; `edition` absent (2015 ruleset); **fails the policy's "declared as `rust-version` in Cargo.toml" clause** under the reading R63 applied | `rust-version = "1.46.0"` declared, and an MSRV job pins toolchain 1.46 in CI — **pass**, the only unqualified gate-2 pass of the two tokenizers |
| 3 · Advisory / `unsafe` | `rustsec.org/packages/shell-words.html` → HTTP 404 (no advisory page); `#![forbid(unsafe_code)]` at `src/lib.rs:12` — **pass, strongest posture** | page → HTTP 200 listing exactly one advisory, RUSTSEC-2024-0006, `patched = [">= 1.3.0"]`, affected functions `quote`/`join` only, all `< 1.2.1` — 2.0.1 is outside the affected range and the recommended call site is `split`, so **no open advisory: pass**. `unsafe` posture: `split` (`lib.rs:100-104`) collects from `Iterator::next` (`lib.rs:80-88`), whose body is `unsafe { String::from_utf8_unchecked(byte_word) }` under a stated invariant — one unchecked conversion on the selected path |
| 4 · OS matrix | **fail on a CI-badge reading** — no CI workflow exists at all; the repository tree is `.gitignore, Cargo.toml, LICENSE-APACHE, LICENSE-MIT, README.md, rustfmt.toml, src, src/lib.rs`, with no `.github`. This is the exact criterion R63 applied to exclude `cliclack` ("repository contains no `.github` directory, so no CI is evidenced") | **partial on a CI-badge reading** — CI is four jobs, **all `runs-on: ubuntu-latest`**, so the `ubuntu-latest` leg is evidenced and the `macos-latest` leg is not |
| 5 · Features / async | `default = ["std"]`, only other feature `std`; no async coupling; **no `[dependencies]` section at all** | `default = ["std"]`; no async coupling; no `[dependencies]` section at all |
| 6 · Size / compile cost | one 508-line module, no dependencies — qualitatively a single small codegen unit. No measurement taken and none claimed | 840 lines across two modules, no dependencies — same order. No measurement taken |

**The count, stated exactly.** Under the readings R63 applied, `shell-words` fails **two**
gates — 2 (undeclared `rust-version`) and 4 (no CI evidenced) — and `shlex` fails **one**, the
`macos-latest` leg of gate 4. Writing this as "one gate each" would be the over-claim; it is
written out because the selection has to survive the true count.

**Why gate 4 is answered on source here, and not on a CI badge.** Applied strictly, gate 4
excludes *both* tokenizers and leaves the item with no splitter, and the two crate-free
fallbacks each fail an approved requirement rather than the gate: `split_whitespace` cannot
reconstruct `PAGER="/opt/my pager/less"`, which is the case P1 exists to serve, and `sh -c`
turns a malformed `PAGER` into a shell error instead of a recoverable one, adds a second
process, and is a shape none of the five surveyed tools takes. A gate whose strict application
removes every candidate is being asked a question its evidence cannot answer. For a leaf,
dependency-free, pure-Rust crate the same question has a direct source answer: every `cfg(` in
either crate's `src/` is a `feature`/`test` gate, and neither contains `target_os`,
`cfg(unix)` or `cfg(windows)` code (greps in the evidence log, section 14), so neither crate
*has* a branch that could behave differently on the two runners, and the template's own CI on
both runners is what would observe it. Under that reading both candidates pass gate 4 on the
same evidence — and **gate 2 is then the only gate that separates them**, which is exactly why
the strict gate-2 reading is named below as the condition that inverts the pick. Read on a
badge instead, gate 4 excludes both and the item has no answer; that is the reason for the
source reading, not a preference for the outcome.

With gate 4 answered the same way for both, the selection is made on gate 3 and on the
survey method's steps 3 and 4 (practice evidence, then fit): `shell-words` forbids `unsafe`
outright where `shlex`'s selected path performs an unchecked UTF-8 conversion, and
`shell-words` is what **both** reference implementations use **for this identical job** —
`bat` declares `shell-words = { version = "1.1.0", optional = true }` (`Cargo.toml:54`)
inside `paging = [ "shell-words", "grep-cli", "minus"]` (`:36`), i.e. the crate is in `bat`
*because of* paging; `delta` declares `shell-words = "1.0.0"` (`Cargo.toml:51`) and calls
`shell_words::split` on the resolved pager command (`src/utils/bat/output.rs:120`). Both read
at their pinned tags, 2026-09-10. The MSRV question `shell-words`' metadata leaves open is
answered empirically by the template's own MSRV CI job, which the `msrv-policy` parameter
already requires.

**Ranked runner-up, and the condition under which it wins.** `shlex = "2.0"`. It wins
outright **if the controller applies R63's strict reading of gate 2 to dependencies** — R63's
accepted decision excluded four crates on gate 2 for exactly this, an undeclared
`rust-version` (`research/runs/R63/…/review/DECISION.md`, "Excluded on gate 2"), which would
place `shell-words` under *Excluded by gate* here — and gate 2 is, once gate 4 is answered on
source for both, the single gate separating the two. It also wins if `shell-words` acquires an
advisory, is archived, or lets a correctness report sit 90 days. The switch is mechanical and
costs one dependency line and one call site: `shell_words::split(s) -> Result<Vec<String>,
ParseError>` becomes `shlex::split(s) -> Option<Vec<String>>`, and **no other part of this
decision changes** — not the resolution policy, not the invocation shape, not one acceptance
criterion.

**Excluded, with the reason.** `pager` 0.16.1 — architecture B above; additionally
`rust_version: null`, last release 2022-09-22, hosted on GitLab where an unauthenticated API
call returns `open_issues_count: null` and `archived: null`, so those figures are
**unverified, not zero**. `minus` 5.7.2 and `sapling-streampager` 0.12.0 — architecture C
above, excluded on fit before popularity or safety is weighed; `minus`'s `unsafe` posture was
therefore **not audited**, and is recorded as unaudited rather than asserted.
`terminal_size` 0.4.4 is not excluded on any gate — it passes all six, including gate 2
outright with `rust-version = "1.71"` — it is simply not needed by a design with no height
check, and it is the fourth member the buffered variant would add.

**Reference implementations, read at pinned tags (2026-09-10).** `bat` v0.26.1
(`Cargo.toml`, `src/pager.rs`, `src/output.rs`) — 60,399 stars, `archived: false`,
`pushed_at 2026-09-04T19:10:30Z`; `delta` 0.19.2 (`Cargo.toml`, `src/env.rs`,
`src/utils/bat/output.rs`) — 32,138 stars, `pushed_at 2026-09-02T15:36:17Z`; `jj` v0.45.1
(`cli/src/ui.rs`, `cli/src/config/misc.toml`, `docs/config.md`) — 31,499 stars,
`pushed_at 2026-09-10T13:51:41Z`; `git` v2.51.0 (`pager.c`, `Makefile`) as the reference the
convention descends from. All GitHub figures via `gh api repos/<o>/<r>`, and open-issue
counts via the mandated `search/issues … total_count` endpoint, not `open_issues_count`.

**One dissenter on the chain, recorded rather than smoothed over.** `jj` deliberately ignores
the generic `PAGER`: "The `JJ_PAGER` environment variable overrides `ui.pager`… `PAGER`
environment variable is ignored" (`docs/config.md:895-897`, v0.45.1), with its default
`pager = { command = ["less", "-FRXK"], env = { LESSCHARSET = "utf-8" } }`
(`cli/src/config/misc.toml:39`) — note that `jj` also injects environment into the pager
child. Ignoring `PAGER` is the wrong choice for a *template*, which should not surprise a
user whose `PAGER` works everywhere else, and `jj` is 1 of 5 surveyed tools in doing it.

**File-level shape P03 builds** (proposed; no Rust template file exists today).
`crates/<cli>/Cargo.toml` gains one line, `shell-words = "1.1"`, and nothing is added to the
library or web crates. A new `crates/<cli>/src/pager.rs` (roughly 60 lines) holds
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

**One requirement this decision places on R67, stated once.** While a pager child is alive,
the `SIGINT` path must finish the pager before the process returns its `ExitCode`; it must not
exit `130` and hand the shell prompt back while `less` still owns the terminal. R67 already
owns the mechanism (`RSLB901` SIGINT → 130); this is an ordering constraint on it, not a change
to any value it fixed, so no `CONFLICT:` is raised. If R67 declines the constraint, the fallback
is to change the default command to `less -FRXK` — `jj`'s exact default, whose `-K` /
`--quit-on-intr` makes `less` exit on `^C` by itself — at the cost of one flag of drift from
py's `less -FRX`.

re-verify: on the earliest of — the controller applying R63's strict gate-2 reading to dependencies, which selects the runner-up `shlex = "2.0"`; R65 (`color-enablement-chain`) resolving F290, especially if it wraps the written stream in an auto-detecting colour stream; R05 putting the CLI on an async runtime, which makes the blocking `child.wait()` need a blocking-safe context; R54 landing a config file, which inserts a config tier between `RSLB_PAGER` and `PAGER`; R60 declining a global `--no-pager`; a later item registering an app env-var prefix other than `RSLB`; `shell-words` gaining a RustSec advisory or being archived; a maintained pager-invocation crate appearing with `bat`, `delta` or `jj` as an adopter; otherwise 2027-03-10.

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
(`https://static.rust-lang.org/dist/channel-rust-stable.toml`, retrieved 2026-09-10), and it
is the gate that separates the two tokenizers: `shlex` 2.0.1 declares 1.46.0 and tests it in
CI, `shell-words` 1.1.1 declares nothing. Everything else in the recommendation is
Rust-1.0-era standard library (`std::env::var`, `std::process::Command`, `Stdio::piped`,
`Child::wait`, `io::ErrorKind::BrokenPipe`), so the floor costs the design nothing. The
**edition** is not exercised: editions are per-crate, and a 2015-edition (`shell-words`) or
2018-edition (`shlex`) dependency links into a 2024-edition consumer unchanged. The
**licence** is satisfied — the one added crate is dual MIT/Apache-2.0 under either candidate,
and nothing in the tree is copyleft. The **OS matrix** is where this item's honesty matters
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
`git version 2.50.1 (Apple Git-155)`, both as installed on this host.

**What this check does and does not do.** It verifies the raws' claims by querying the
recorded endpoints, reading both pinned source repositories through their pins, reading the
candidate crates' source from their **published crates.io artifacts**, reading the four
reference implementations at pinned tags, and **observing two behaviours directly under a
pseudo-terminal** — what `less` does with ANSI bytes with and without `-R`, and what git
actually puts in its pager child's environment. It implements nothing: no crate was
scaffolded, no pager was wired, no `Cargo.toml` was written, no `cargo build` or `cargo test`
was run, and no template file exists to run anything against.

**Working directory.**
`/private/tmp/claude-501/-Users-stevemorin-c-rs-launch-blueprint-p02-plan/b7c06b2f-d78d-4987-b237-63eeced4bd23/scratchpad/r64`
(published `.crate` artifacts downloaded and unpacked read-only under `./src`). The two
pinned repositories were read in place with `git -C … show <pin>:<path>`; neither working
tree was consulted.

**Command.** One script, `verify.sh`, run as
`bash verify.sh > <run-dir>/review/evidence/r64-pager-claims.log 2>&1`. **Exit status 0.**
Section 14 was appended by a follow-up invocation of the same shape after the first pass.
Greps whose expected result is "no match" print their exit status and the expected value on
the following line, so an expected `1` is never mistaken for a failure. Sections:

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
        shell-words' full repository tree; shlex's CI workflow
    8   RustSec pages for 6 candidates plus the `time` control; RUSTSEC-2024-0006's own TOML
    9   published artifacts of shell-words 1.1.1 and shlex 2.0.1: manifest, crate attributes,
        every `unsafe`, the split entry point, dependencies, line counts
    10  bat v0.26.1, delta 0.19.2, jj v0.45.1, git v2.51.0 at pinned tags: the spawn, the
        Drop-time wait, the shell-words call, the chain — and whether any measures terminal height
    11  whether `less` is present on the CI runners
    12  this repository: ledger rows, owner direction, divergence rows, the couplings block
    14  platform-conditional code in the two tokenizers; the exact unsafe site on shlex::split

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
  `shell-words = "1.0.0"`.
- **Registry figures, retrieved 2026-09-10** (`GET https://crates.io/api/v1/crates/<name>`,
  `crate.recent_downloads` / `crate.downloads`; newest unyanked from `…/versions`):
  `shell-words` 36,835,500 / 143,814,152, newest 1.1.1 `2025-12-10T20:48:28.942402Z`,
  `license: MIT/Apache-2.0`, `rust_version: None`, `edition: None`, `features {default:[std], std:[]}`;
  `shlex` 235,305,397 / 808,753,085, newest 2.0.1 `2026-05-17T18:56:12.775983Z`,
  `MIT OR Apache-2.0`, `rust_version: 1.46.0`, `edition: 2018`;
  `pager` 114,359 / 838,897, newest 0.16.1 `2022-09-22T15:56:55.250446Z`, `rust_version: None`,
  repository on GitLab; `minus` 436,903 / 1,592,326, newest 5.7.2
  `2026-07-15T06:58:43.195787Z`, `rust_version: None`, `edition: 2024`;
  `sapling-streampager` 1,126,040 / 2,910,416, newest 0.12.0 `2026-01-15T18:58:13.235965Z`,
  `license: MIT`, `repository: None`; `terminal_size` 37,832,505 / 201,468,090, newest 0.4.4
  `2026-03-23T16:39:14.510986Z`, `rust-version 1.71`; `grep-cli` 1,998,102 / 9,440,829;
  `bat` 777,983 / 4,561,460, newest 0.26.1, `rust-version 1.87`.
- **GitHub, retrieved 2026-09-10 via `gh api` (authenticated with the user's token, not
  anonymous):** `tmiasko/shell-words` 86 stars, `archived: false`,
  `pushed_at 2025-12-10T20:50:02Z`, **3** open issues by `search/issues` `total_count`;
  `comex/rust-shlex` 156 stars, `pushed_at 2026-06-12T19:38:35Z`, **4** open issues;
  `sharkdp/bat` 60,399 / 328; `dandavison/delta` 32,138 / 309; `jj-vcs/jj` 31,499 / 813;
  `AMythicDev/minus` 372 / 10.
- **`shell-words` has no CI, and `shlex`'s CI has no macOS.** `shell-words`' full repository
  tree is `.gitignore, Cargo.toml, LICENSE-APACHE, LICENSE-MIT, README.md, rustfmt.toml, src,
  src/lib.rs` — no `.github`. `shlex`'s workflow (read at `master`, **not** at the 2.0.1 tag,
  and labelled as such) is four jobs — stable, beta, `--no-default-features`, and an MSRV job
  installing toolchain 1.46 — every one `runs-on: ubuntu-latest`; the stable job also builds
  a `fuzz` workspace.
- **RustSec, retrieved 2026-09-10, with a control.** HTTP 404 for `shell-words`, `pager`,
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
  is a `feature` or `test` gate, and neither has `target_os`, `cfg(unix)` or `cfg(windows)`
  code (the `unix`/`windows` hits are prose in comments and documentation).
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

**Full output:**
`research/runs/R64/2026-09-05T183457Z-3c53ded23d05/review/evidence/r64-pager-claims.log`

## Engines

- codex `raw/codex-0e3536a58a5718d98015052e96f5ddff83f0fdf2f953008f64761a3551254066.md` — figures retrieved 2026-09-05; recommends `shlex` 2.0.1 + `std::process::{Command, Stdio}` with a render-buffer sink; env var `RS_LAUNCH_BLUEPRINT_PAGER`; no `LESS` injection; excludes `pager` and `minus`.
- opus `raw/opus-739eedc3784ce02fbca5a4bd8cc08490e3b0cd1be8435f4aad1bf184b77f4f49.md` — figures retrieved 2026-09-10; recommends `shell-words` 1.1.1 + a two-tier resolution policy with `LESS`/`LV` injection + streaming spawn-and-pipe; env var `RSLB_PAGER`; emits the two py-facing `BASELINE-REVIEW:` lines.

Both engines independently reached the same architecture — external pager, resolved from an
app-specific variable before `PAGER` with a `less -FRX` default, spawned through
`std::process::Command` with a piped stdin, argv passed literally and never through a shell,
falling through to stdout on any failure — and both excluded the `pager` crate and the
in-process pagers on the same structural grounds. The disagreements, and the evidence that
settled each:

1. **The tokenizer — the one disagreement that changes a `Cargo.toml` line.** Codex picks
   `shlex` 2.0.1 because it declares `rust-version = 1.46.0` and tests it in CI; Opus picks
   `shell-words` 1.1.1 on `bat` and `delta` precedent and `#![forbid(unsafe_code)]`.
   **Both raws overstate their candidate's gate result**, and re-checking every gate here
   showed by how much: on R63's applied readings `shell-words` fails **two** gates — 2, an
   undeclared `rust-version`, and 4, no CI evidenced at all, which is R63's own `cliclack`
   criterion — while `shlex` fails **one**, gate 4's `macos-latest` leg, and its `split` path
   executes one `unsafe` unchecked-UTF-8 conversion. Because a strict gate 4 excludes both and
   leaves the item with no splitter, gate 4 is answered on source for both (neither crate has
   any platform-conditional code), which leaves **gate 2 as the only gate separating them**.
   **Settled in Opus's favour** on gate 3's `unsafe` posture plus survey steps 3-4 — `bat`
   (`Cargo.toml:36,54`) and `delta` (`Cargo.toml:51`, `output.rs:120`) both use `shell-words`
   for this identical job — with the strict gate-2 reading recorded in `## Decision` as the
   named condition under which `shlex` wins instead. The programme has precedent both ways:
   R63 excluded four crates on gate 2 for an undeclared `rust-version`, while R33 selected a
   stack in which two surveyed crates carried none. This is the closest call in the item, and
   the controller's reading of gate 2 is what decides it. Whichever way it goes, the design —
   policy, invocation shape and all twelve acceptance criteria — is unchanged.
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
6. **Figure drift.** The two raws' download figures differ by their retrieval dates
   (2026-09-05 versus 2026-09-10). This review's re-query on 2026-09-10 reproduces Opus's
   `shell-words` and `shlex` figures exactly; Codex's are not wrong, only five days older.
   Every figure quoted in this decision carries the 2026-09-10 date. One figure moved between
   the raws and this check: `bat`'s all-time downloads, 4,521,315 in the Codex raw against
   4,561,460 today — a five-day increment, not a discrepancy.
7. **Codex's GitHub rate-limiting.** Codex recorded `shlex`'s stars, `archived` and
   `pushed_at` as unverified after anonymous rate-limiting. This review supplied them through
   `gh api`: 156 stars, `archived: false`, `pushed_at 2026-06-12T19:38:35Z`. The
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
  `cargo tree -p <library-crate> | grep shell-words` returning nothing and
  `cargo tree -p <cli-crate> -i shell-words` showing the crate with no children, to prove A11.
- **`shell-words`' effective MSRV.** Its manifest declares none. That its floor sits below
  1.96 is inferred from the crate declaring no `edition` (so the 2015 ruleset), having no
  dependencies, and being 508 lines of string scanning — an inference from source, not a
  compilation. *What would prove it*: the `cargo +<floor> check` MSRV job the `msrv-policy`
  parameter already requires.
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
