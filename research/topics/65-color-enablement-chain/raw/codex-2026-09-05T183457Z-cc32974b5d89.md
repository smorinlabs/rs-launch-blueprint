### Landscape

**Category.** R65 decides a CLI presentation policy: when human-oriented ANSI
colour is emitted to each output stream. It is not a library or web-service
policy; those layers return plain data and must not write terminal sequences.
The Rust field is:

| Bin | Candidates and role | Evidence and retrieval |
|---|---|---|
| Built-in / first-party toolchain | `std::io::IsTerminal` answers whether a particular `stdout` or `stderr` handle is a terminal. It is the correct low-level, per-stream capability primitive. | [Rust standard-library API](https://doc.rust-lang.org/std/io/trait.IsTerminal.html), Rust Project authority, retrieved 2026-09-05. |
| Established industry standard | The [NO_COLOR convention](https://no-color.org/) says a non-empty `NO_COLOR` suppresses default ANSI colour. `CLICOLOR`/`CLICOLOR_FORCE` are a separate, older convention, documented by [clicolors](https://bixense.com/clicolors/). | [NO_COLOR specification](https://no-color.org/), convention authority, retrieved 2026-09-05; [clicolors specification](https://bixense.com/clicolors/), convention authority, retrieved 2026-09-05. |
| Established Rust implementation | `anstream` is a stream adapter that strips or passes ANSI sequences and has an explicit `AutoStream::new(stream, ColorChoice)` constructor. `supports-color` is a detector only. | [`anstream` source](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/auto.rs), maintainer implementation documentation, retrieved 2026-09-05; [`supports-color` source](https://github.com/zkat/supports-color/blob/main/src/lib.rs), maintainer implementation documentation, retrieved 2026-09-05. |
| Up-and-comer / alternative renderer | `owo-colors` can detect `NO_COLOR`/`FORCE_COLOR` with an optional feature, but combines rendering and global process policy. It is useful for rich styling, not the narrow, independently testable gate needed here. | [`owo-colors` README](https://github.com/owo-colors/owo-colors/blob/main/README.md), maintainer documentation, retrieved 2026-09-05. |

The authorities are deliberately mixed: the Rust Project defines the stable
capability API; NO_COLOR defines the cross-language opt-out convention; crate
maintainers document actual behaviour; and the production `clap` project is
practice evidence. `clap_builder` enables `anstream` for its default `color`
feature and declares both `anstream = "1.0.0"` and `anstyle = "1.0.14"`.
`clap` is relevant because it is the dominant Rust command-line parser, with
1,107,038,264 all-time and 225,333,330 90-day downloads at the queried registry
endpoint. [Its manifest](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/Cargo.toml)
and [crates.io record](https://crates.io/api/v1/crates/clap) were retrieved
2026-09-05. This is adoption evidence, not a selection rule.

The following comparable figures were collected before weighing popularity.
All registry numbers and releases come from the stated crate endpoint and
`/versions`; repository numbers and open-issue counts come from the stated
GitHub REST endpoints; all were retrieved 2026-09-05.

| Candidate | 90-day / all-time downloads | Latest non-yanked release | Repository stars; archived; pushed | Open issues | 10-most-recent open-issue responsiveness | Advisories | Sources |
|---|---:|---|---|---:|---|---|---|
| `anstream` | 174,382,863 / 660,913,310 | 1.0.0, 2026-02-11 | 170; false; 2026-09-02 | 15 | 8 maintainer responses; median 0.8 days; 2 unanswered | no unpatched advisory at 1.0.0; RUSTSEC-2024-0404 is fixed at >=0.6.8 | [crate](https://crates.io/api/v1/crates/anstream), [versions](https://crates.io/api/v1/crates/anstream/versions), [repo](https://api.github.com/repos/rust-cli/anstyle), [issues](https://api.github.com/search/issues?q=repo:rust-cli/anstyle+is:issue+is:open), [RustSec](https://rustsec.org/packages/anstream.html), [advisory](https://rustsec.org/advisories/RUSTSEC-2024-0404.html) |
| `supports-color` | 14,989,669 / 63,326,543 | 3.0.2, 2024-11-26 | 54; false; 2024-11-26 | 3 | only 3 open issues; 1 maintainer response in 0.13 days, 2 unanswered | none listed | [crate](https://crates.io/api/v1/crates/supports-color), [versions](https://crates.io/api/v1/crates/supports-color/versions), [repo](https://api.github.com/repos/zkat/supports-color), [issues](https://api.github.com/search/issues?q=repo:zkat/supports-color+is:issue+is:open), [RustSec](https://rustsec.org/packages/supports-color.html) |
| `owo-colors` | 33,556,933 / 160,354,536 | 4.4.0, 2026-08-27 | 808; false; 2026-08-27 | 16 | 4 maintainer responses among 8 available open issues; response times range from 0.2 to 735 days, so this small, sparse sample has no useful steady-state median | none listed | [crate](https://crates.io/api/v1/crates/owo-colors), [versions](https://crates.io/api/v1/crates/owo-colors/versions), [repo](https://api.github.com/repos/owo-colors/owo-colors), [issues](https://api.github.com/search/issues?q=repo:owo-colors/owo-colors+is:issue+is:open), [RustSec](https://rustsec.org/packages/owo-colors.html) |

The response figures inspect the ten newest *issues* rather than pull
requests, and count a first comment whose GitHub `author_association` is
`OWNER`, `MEMBER`, or `COLLABORATOR`; the underlying issue-search and comment
endpoints are the issue URLs in the table, retrieved 2026-09-05. They are a
maintenance signal, not a claim that an unanswered issue is a defect.

### Principles and implementation

The shared requirement is **predictable, user-controlled, stream-safe terminal
presentation**. Agreement is required at the capability and policy level:
every sibling has `--no-color`, honours a non-empty `NO_COLOR`, avoids ANSI in
non-terminal text output by default, and has an observable forced-colour path.
The implementation need not agree: Python's Rich consoles share one decision,
whereas TypeScript injects stream facts and styles only stderr. The pinned
Python source resolves `--no-color > NO_COLOR > config > auto` and constructs
stdout and stderr consoles with the same choice; the pinned TypeScript source
resolves `--no-color > NO_COLOR > FORCE_COLOR > supplied isTTY`. [Python
context](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/cli/context.py#L188-L195),
[Python output](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/cli/output.py#L144-L149),
and [TypeScript gate](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/src/lib/colors.ts#L26-L43)
were retrieved 2026-09-05.

The recommended Rust policy is evaluated once at startup for **each** stream:

```text
--no-color true                                      => Never
otherwise, NO_COLOR is present and non-empty         => Never
otherwise, FORCE_COLOR is present, non-empty, != "0" => Always
otherwise, this stream's is_terminal()               => Always
otherwise                                             => Never
```

`--no-color` is the explicit per-invocation override, and `NO_COLOR` is the
portable opt-out. `FORCE_COLOR` is retained for compatibility with the TypeScript
contract; it is a project policy, not a Rust standard. The rule intentionally
does not silently inherit `CLICOLOR`, `CLICOLOR_FORCE`, `CI`, `TERM`, or cached
process-global detection. `anstream` automatic mode would introduce those
inputs: its source checks `NO_COLOR`, `CLICOLOR_FORCE`, `CLICOLOR`, terminal
support, and `CI`. [anstream auto implementation](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/auto.rs#L141-L165),
retrieved 2026-09-05. `supports-color` similarly puts `FORCE_COLOR` before
`NO_COLOR`, which conflicts with the recorded sibling policy. [supports-color
implementation](https://github.com/zkat/supports-color/blob/main/src/lib.rs#L36-L111),
retrieved 2026-09-05.

Do not add a `color` configuration key to the initial Rust schema. That avoids
an untested fourth input and keeps the template's default behaviour entirely
visible at invocation time. If a later owner decision requires a persistent
`auto|always|never` choice, R65 must define its precedence before R53/R55 only
validate and report that enum. The NO_COLOR FAQ explicitly permits user
configuration to override its environment default, so a later config layer
cannot be inserted beneath `NO_COLOR` by accident. [NO_COLOR FAQ](https://no-color.org/),
retrieved 2026-09-05.

Use a tiny `ColorInputs` port containing `no_color_flag`, the two relevant
environment values, and `stdout_is_terminal`/`stderr_is_terminal`. Production
adapts those booleans from `std::io::stdout().is_terminal()` and
`std::io::stderr().is_terminal()`; tests construct them directly. This preserves
the TypeScript test seam while using Rust's first-party per-handle API. The
resolver returns `anstream::ColorChoice::Always` or `Never`; construct
`anstream::AutoStream::new(stdout, choice)` and the corresponding stderr stream
with its own choice. `AutoStream::new` passes or strips ANSI sequences under
that explicit choice. [Rust IsTerminal API](https://doc.rust-lang.org/std/io/trait.IsTerminal.html)
and [anstream constructor](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/auto.rs#L62-L71),
retrieved 2026-09-05.

Per-stream gating is the appropriate Rust architecture because R66 may style a
text-mode stdout table; stderr's interactivity must not decide whether that
table contains escape codes. It generalizes the source principle rather than
copying either accidental shape. The spinner and pager consumers (R63/R64) use
the same injected `stderr_is_terminal` or `stdout_is_terminal` facts, but make
their own interaction decisions.

Performance is not a throughput-sensitive selection: resolution happens once
per process and performs at most two environment lookups and one boolean read
per stream. The chosen configuration has no async-runtime coupling. The
adapter's extra cost is a small ANSI pass-through/strip wrapper; its published
crate archive is 28,916 bytes, but no comparable end-to-end latency, throughput,
or binary-size benchmark was found and none is claimed. [anstream version
metadata](https://crates.io/api/v1/crates/anstream/versions), retrieved
2026-09-05. A planned integration check measures a release binary with
`cargo bloat` only if the template's release-size budget is later defined.

Minimal realistic example: a CLI prints a styled success table to stdout and a
styled warning to stderr. With stdout piped and stderr attached, stdout is
plain while stderr is styled; with `FORCE_COLOR=1`, both are styled; with either
`--no-color` or non-empty `NO_COLOR`, both are plain. JSON/CSV output remains
unstyled because it bypasses presentation styling. These are proposed acceptance
checks, not checks run in this no-Rust-code research checkout.

BASELINE-REVIEW: F287 — predictable, user-controlled, stream-safe ANSI output — replace Python's single shared gate and TypeScript's stderr-only use with an injected per-stream resolver; omit the initial config layer — Python and TypeScript pinned sources above, Rust `IsTerminal`, NO_COLOR, and anstream's documented extra automatic inputs, retrieved 2026-09-05. Affected items: R65 directly; R63/R64 consume the terminal facts; R66 supplies styled text-mode stdout.

### Recommendation

Adopt **one direct dependency: `anstream = "1.0.0"` with default features**, but
do **not** call `anstream::stdout()`, `anstream::stderr()`, or
`AutoStream::auto`. Implement the five-branch resolver above in the CLI adapter
and pass its explicit `ColorChoice::Always` or `ColorChoice::Never` separately
to `AutoStream::new` for `stdout` and `stderr`. This supplies correct ANSI
stripping and platform adaptation without surrendering the template's
`--no-color > NO_COLOR > FORCE_COLOR > per-stream TTY` contract to a library's
larger environment policy. `anstream` defaults to `auto` and `wincon`; the
default has no async runtime. [anstream manifest](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/Cargo.toml),
retrieved 2026-09-05.

### Members

#### anstream 1.0.0

##### Landscape

`anstream` is the established Rust stream-adapter candidate. It accepts ANSI
text and either passes it through or strips it; its maintainers explicitly
describe it as handling non-terminals, NO_COLOR/CLICOLOR, and Windows console
fallback. [Source documentation](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/auto.rs#L9-L18),
retrieved 2026-09-05.

##### Principles and implementation

It separates terminal adaptation from style generation, which lets R65 own the
policy while later rendering work selects semantic styles. `AutoStream::new`
accepts an explicit `ColorChoice`; `Never` wraps a stripping stream and
`Always` passes ANSI through (with Windows handling where applicable). [Source
implementation](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/auto.rs#L62-L138),
retrieved 2026-09-05.

##### Dominant choice

`anstream` is the dominant choice for this narrow adapter role because `clap`
uses it for its default colour feature and because it provides explicit stream
construction. This is practice evidence rather than a popularity-only choice.
[clap manifest](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/Cargo.toml),
retrieved 2026-09-05.

##### Qualified shortlist

`anstream` 1.0.0, `supports-color` 3.0.2, and `owo-colors` 4.4.0 meet the
license, Linux/macOS, and no-unpatched-advisory screens documented in the
Landscape table. `supports-color` is detector-only; `owo-colors` combines the
gate with styling. Their current registry and advisory endpoints are cited in
that table, retrieved 2026-09-05.

##### Excluded by gate

None. `anstream` passes the applicable gates: its `MIT OR Apache-2.0` license
is compatible; workspace `rust-version` is 1.66.0, below the template's moving
stable-minus-two floor; RustSec's historical unsoundness advisory is fixed for
all versions >=0.6.8; and its CI tests Ubuntu, macOS, and Windows on stable.
The full resolved dependency graph must still be checked against the template's
then-current MSRV in CI, so this is a qualified MSRV pass rather than invented
lockfile evidence. [workspace manifest](https://github.com/rust-cli/anstyle/blob/main/Cargo.toml),
[advisory](https://rustsec.org/advisories/RUSTSEC-2024-0404.html), and [CI
workflow](https://github.com/rust-cli/anstyle/blob/main/.github/workflows/ci.yml)
were retrieved 2026-09-05.

##### Up-and-comers

`owo-colors` 4.4.0 is active and can apply `NO_COLOR`/`FORCE_COLOR` when its
`supports-colors` feature is enabled, but that feature chooses process-wide
detection rather than exposing the requested injected policy seam. [README](https://github.com/owo-colors/owo-colors/blob/main/README.md#L23-L28),
retrieved 2026-09-05.

##### Fit for this template

The direct dependency uses safe public Rust APIs; the optional Windows console
support contains platform-specific implementation work but Windows is not in
the owner target matrix. Default features are `auto` and `wincon`; there is no
async runtime. Its dependency set (`anstyle`, parser/query helpers,
`is_terminal_polyfill`, and a Windows-only adapter) is larger than a pure
styling crate but still a small terminal utility; compile-time and binary-size
effects are qualitatively low and require the planned release-binary check.
[manifest](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/Cargo.toml),
retrieved 2026-09-05.

##### Recommendation

Use `anstream = "1.0.0"` as the direct output adapter with explicit choices
from the template resolver. Keep styling-crate selection outside R65 unless an
output call site needs it; `anstream` accepts ANSI from multiple style crates.
[anstream library documentation](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/lib.rs#L1-L31),
retrieved 2026-09-05.

##### Ranked runner-up

`supports-color` 3.0.2 ranks second only if a future renderer already owns
ANSI stripping. It detects per stream and explicitly implements `FORCE_COLOR`,
but it has no stream wrapper and its source gives FORCE_COLOR priority over
NO_COLOR, so it cannot implement this item without more policy code. [source](https://github.com/zkat/supports-color/blob/main/src/lib.rs#L36-L111),
retrieved 2026-09-05.

##### Tradeoffs

The recommendation deliberately writes about 20 lines of pure resolver code.
That cost buys exact precedence and deterministic tests; using `AutoStream::auto`
would be shorter but would admit unrequested CLICOLOR, CI, and terminal-capability
inputs. `owo-colors` would reduce renderer plumbing but makes the shared policy
less visible. [anstream automatic choice](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/auto.rs#L141-L165),
retrieved 2026-09-05.

##### Parameters

No registered parameters are owned or consumed by R65. No `color` configuration
parameter is recommended in the initial schema. No `CONFLICT:` line is emitted.

##### Migration implications

Add the direct dependency, one CLI-owned resolver, and two explicitly chosen
stream wrappers. Remove any colour decision embedded in individual formatter,
table, logger, spinner, or pager call sites. The library and web-service
crates receive already-rendered/plain values and do not depend on `anstream`.

##### Validation strategy

Planned tests construct `ColorInputs` without changing process environment,
assert the five precedence branches for both streams, and assert stripping or
presence of `\x1b[` through `AutoStream::new`. Run them on Ubuntu and macOS.
The test is planned; no implementation test was run in this research-only
checkout. [constructor behaviour](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/auto.rs#L62-L80),
retrieved 2026-09-05.

##### Confidence & re-verify trigger

High confidence in the explicit-policy design; medium confidence in pinning
1.0.0 until the template lockfile exists. Re-verify before implementation if
anstream releases a semver-major version, the template's MSRV moves, R53/R55
introduce persistent colour configuration, or R66 decides stdout text is never
styled.

##### Sources

Figures: [crates.io crate endpoint](https://crates.io/api/v1/crates/anstream),
[versions endpoint](https://crates.io/api/v1/crates/anstream/versions), [GitHub
repository endpoint](https://api.github.com/repos/rust-cli/anstyle), [GitHub
open-issues endpoint](https://api.github.com/search/issues?q=repo:rust-cli/anstyle+is:issue+is:open),
and [RustSec package page](https://rustsec.org/packages/anstream.html), all
retrieved 2026-09-05. Behaviour and maintenance sources are linked in the
member fields above.

### Compatibility

The recommended direct member is compatible with its required internal style
components: `anstream` 1.0.0 declares `anstyle = "1.0.0"`; the production
`clap_builder` manifest declares `anstream = "1.0.0"` and `anstyle =
"1.0.14"` together. This is a maintained reference version matrix, not merely
a theoretical semver intersection. [anstream manifest](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/Cargo.toml)
and [clap manifest](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/Cargo.toml)
were retrieved 2026-09-05.

### Parameters

No registry parameter is owned or consumed: `owns —`; `consumes —`. No
`CONFLICT:` line is required. The absence of an initial config `color` key is a
R65 recommendation, not a newly invented shared parameter.

### Migration implications

Because the Rust template has no source yet, these are proposed files:

| Proposed file | Change |
|---|---|
| `Cargo.toml` | Add `anstream = "1.0.0"`. |
| `src/cli/color.rs` | Define `ColorInputs`, `ColorDecision`, and the pure five-branch resolver. |
| `src/cli/deps.rs` | Obtain and inject stdout/stderr terminal booleans in production; test doubles supply them directly. |
| `src/cli/output.rs` | Construct separate `AutoStream::new` wrappers from the two decisions. |
| `tests/cli/color.rs` | Cover precedence, independent stream output, pipe behaviour, and ANSI stripping. |

R63/R64 consume only the appropriate stream-terminal fact; R66 applies the
decision to text-mode styling and must leave machine formats free of ANSI.

### Validation strategy

These commands are **planned**, not executed, because this checkout has no
Rust implementation:

```sh
cargo test -p rs-launch-blueprint --test color
cargo test -p rs-launch-blueprint --test cli_output -- color
cargo test --workspace
```

The first test table must assert: (1) `--no-color` wins over all inputs; (2)
non-empty `NO_COLOR` wins over `FORCE_COLOR=1`; (3) `FORCE_COLOR=1` enables
both streams even when neither is a terminal; (4) `FORCE_COLOR=0` falls through
to the relevant stream's terminal fact; and (5) `stdout=true, stderr=false`
styles only stdout, with the inverse styling only stderr. The CLI-output test
must capture actual bytes and verify that disabled output lacks `\x1b[` while
enabled text output contains it. Run this matrix on `ubuntu-latest` and
`macos-latest`; use dependency MSRV checking consistent with the owner's policy.
`AutoStream::new` is the adapter under test, not `AutoStream::auto`. [anstream
source](https://github.com/rust-cli/anstyle/blob/main/crates/anstream/src/auto.rs#L62-L80),
retrieved 2026-09-05.

### Confidence & re-verify trigger

**Decision confidence: high.** The per-stream policy follows the actual output
capabilities, preserves the cross-language opt-out/force contract, and is
independent of any renderer. **Evidence confidence: medium-high.** Registry,
GitHub, RustSec, upstream source, and sibling source evidence were retrieved
2026-09-05, but no template code exists to execute the proposed acceptance
matrix. Re-verify the crate version, RustSec status, dependency-tree MSRV,
anstream's automatic-policy inputs, and the no-config decision immediately
before implementation or whenever R53/R55/R66 changes the affected surface.

### Sources

Primary external sources, all retrieved 2026-09-05: [Rust `IsTerminal`](https://doc.rust-lang.org/std/io/trait.IsTerminal.html);
[NO_COLOR](https://no-color.org/); [clicolors](https://bixense.com/clicolors/);
[anstream source](https://github.com/rust-cli/anstyle/tree/main/crates/anstream);
[anstream crates.io API](https://crates.io/api/v1/crates/anstream);
[anstream versions API](https://crates.io/api/v1/crates/anstream/versions);
[RustSec anstream page](https://rustsec.org/packages/anstream.html);
[RUSTSEC-2024-0404](https://rustsec.org/advisories/RUSTSEC-2024-0404.html);
[supports-color source](https://github.com/zkat/supports-color/blob/main/src/lib.rs);
[owo-colors README](https://github.com/owo-colors/owo-colors/blob/main/README.md);
and [clap's manifest](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/Cargo.toml).

Pinned sibling evidence, retrieved 2026-09-05: [py `context.py`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/cli/context.py#L188-L195),
[py `output.py`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/cli/output.py#L94-L104),
[py consoles](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/cli/output.py#L144-L149),
[ts `colors.ts`](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/src/lib/colors.ts#L26-L43),
and [ts injected terminal facts](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/src/router.ts#L58-L70).

Method notes: queried `GET https://crates.io/api/v1/crates/{anstream,supports-color,owo-colors,clap}` and each candidate's `/versions`, `GET https://api.github.com/repos/{owner}/{repo}`, GitHub's `search/issues` endpoint and issue-comment endpoints, RustSec package/advisory pages, the Rust standard library, convention sites, upstream source, and pinned sibling source. GitHub's unauthenticated core rate limit was exhausted after the required repository and issue figures were recorded, so no additional GitHub repository metadata was claimed. No performance benchmark, final dependency-lock MSRV check, or template acceptance command could be run because no Rust template code exists.
