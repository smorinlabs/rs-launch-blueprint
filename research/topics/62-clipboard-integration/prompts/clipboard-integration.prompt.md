# Deep-research prompt — Clipboard integration (R62, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a cross-platform clipboard-write crate for a `--copy` flag on command results, and how a clipboard write degrades cleanly instead of crashing in a headless/CI environment with no display server. Item kind: `bundle`. Value test: if this answer is wrong, whether a `--copy` flag and clipboard-writer dependency exist at all, and the function/trait wrapping the write plus its headless-degrade error path, get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): this bundle is ts-only — py ships no clipboard integration to compare against. ts's `--copy` flag copies command results to the OS clipboard, with the write wrapped to degrade instead of crash when no clipboard is available. Evidence: ts `src/commands/projects.ts:84` — `.option('--copy', 'copy results to clipboard', false)`; ts `src/lib/adapters.ts:49` — `export const realClipboard: ClipboardWriter = async (text) => {`; failure is caught and re-raised as a `CliError` (`src/commands/projects.ts:193`) instead of crashing. Ledger rows: F281, F282 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-016(7) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — `clipboardy` 5.3.1, wrapped to degrade with a clear stderr error in headless/CI environments instead of crashing; chosen as "the only serious cross-platform Node clipboard lib (macOS/Windows native, Linux `xsel`/`wl-clipboard`)," with upstream confirming headless Linux has no clipboard, making graceful degradation mandatory rather than optional.

## Out of scope
- Which CLI-parsing framework hosts the `--copy` flag; R60 (`cli-parsing-framework`) owns that bundle — this item's crate choice only needs to compose with whatever R60 selects.
- The exact error code and exit status a clipboard-write failure maps to; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` — this item decides only that a clipboard-write failure raises a typed, catchable error, not its catalog entry or exit code.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R62
- owns:
- consumes:
- related (not a registry dependency): R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes`; the typed error this item's clipboard-write function raises on failure eventually gets a catalog entry and exit code from R67, but this item does not need that value to make its own recommendation.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether/which Rust crate provides cross-platform clipboard write for `--copy`, and how a clipboard-write failure in a headless/CI environment degrades cleanly instead of crashing the command.
- HIGH: What is the dominant Rust crate for cross-platform clipboard write covering macOS, Windows, and Linux (X11 and Wayland, mirroring `clipboardy`'s `xsel`/`wl-clipboard` coverage) — e.g. `arboard`, `copypasta`, `clipboard-win`+platform-specific crates — and does it reach parity with `clipboardy`'s platform matrix?
- HIGH: How does the candidate crate behave on headless Linux (no X11/Wayland display server) — does it return a typed, catchable error the template can turn into a clean stderr message, or does it hang, panic, or require an external binary (`xsel`/`xclip`) to be present on PATH?
- MEDIUM: Does the candidate crate require any external system binary at runtime (as `xsel`/`wl-clipboard` are external processes `clipboardy` shells out to on Linux), or does it use native platform APIs/libraries with no external process dependency?
- MEDIUM: What is the idiomatic Rust error type for a clipboard-write failure that lets the call site convert it into the template's domain error uniformly, without this item pre-deciding the catalog entry R67 owns?
- LOW: Should the flag be named `--copy` (matching ts) or does the chosen CLI framework's (R60) conventions suggest a different name or short form?

## Required evidence
Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Recommendation
One stack.
### Members
The full `crate` field set for each member.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
