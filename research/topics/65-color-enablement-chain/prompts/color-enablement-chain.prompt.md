# Deep-research prompt — Color enablement chain (R65, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: what precedence chain gates ANSI color output — a `--no-color` flag, `NO_COLOR`/`FORCE_COLOR` environment variables, TTY detection, and optionally a config-file layer — and whether color is gated once for both stdout and stderr or per-stream on stderr only. Item kind: `bundle`. Value test: if this answer is wrong, the color-gate function's precedence order, whether a config-layer color setting exists, whether stdout and stderr share one gate or two, and the TTY-detection mechanism backing it, all get rewritten across every colored-output call site.

## Context
- Inherited pattern (spec §2, presumption of reuse): py and ts each gate color with a different-shaped precedence chain and a different stream-scoping rule. py's chain is flag > `NO_COLOR` env > config, with one gate reused for both stdout and stderr; ts's chain is flag > `NO_COLOR` > `FORCE_COLOR` > TTY, with no config layer, and the gate is computed from stderr TTY-ness only. Evidence: py `src/py_launch_blueprint/cli/context.py:188` — `def _resolve_color(no_color_flag: bool, config_color: str) -> str:`; ts `src/lib/colors.ts:26` — `export function colorEnabled(gate: ColorGate): boolean {`. Ledger rows: F287, F288, F289, F290 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F288 `FORCE_COLOR` forces color on — py: none; ts `src/lib/colors.ts:34` — `const forceColor = gate.env['FORCE_COLOR'];`. F289 color gated once for both streams vs. per-stream — py `src/py_launch_blueprint/cli/output.py:144` — `self.out = Console(highlight=False, no_color=nc, force_terminal=force)`, the same `nc`/`force` values are reused to construct the stderr console; ts `src/router.ts:100` — `isTTY: deps.stderrIsTTY,` — gate computed from stderr TTY-ness only; py's stdout result table can carry color (`header_style`, `src/py_launch_blueprint/cli/output.py:232`), while ts's stdout result document is never styled. F290 TTY-detection mechanism — py `src/py_launch_blueprint/cli/output.py:94` — `def _isatty(console: Console) -> bool:` checks the stream's own `isatty()` apart from Rich's own `is_terminal`; ts `src/router.ts:65` — `stdoutIsTTY: process.stdout.isTTY ?? false,` — reads the process stream flag directly, injected via `CliDeps` for testability.
- Already decided, do not re-open: that a `--no-color` flag exists (F286) is inherited as-is (`COMMON → REUSE`); this item decides the flag's position in the precedence chain, not whether it exists. Target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-018(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — per-stream color enablement gated `--no-color` > `NO_COLOR` > `FORCE_COLOR` > `isTTY`, chosen for honoring `NO_COLOR`/`FORCE_COLOR` and being Node's official chalk replacement at the time; D-038 — later switched the underlying color-rendering library from `node:util styleText` to `picocolors` 1.1.1 via `createColors(enabled)`, a user selection that "fully overrides picocolors' module-load env detection... so the repo's `--no-color`/`NO_COLOR`/`FORCE_COLOR`/TTY precedence stays authoritative," preserving D-018(2)'s chain shape while changing only the rendering dependency.

## Out of scope
- The stderr progress spinner and pager-output gating that reuse whatever TTY-detection mechanism this item selects; R63 (`progress-spinner`) and R64 (`pager-integration`) consume this item's F290 answer but do not decide it here.
- Which output formats exist (text/json/csv) and the file-redirection flag; R66 (`output-format-surface`) owns F291/F293 — this item decides whether/how the text-mode format carries color, not which formats exist.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R65
- owns:
- consumes:
- related (not a registry dependency): R63 (`progress-spinner`) and R64 (`pager-integration`) each reuse this item's TTY-detection mechanism (F290) for their own stream-is-a-terminal checks; neither needs a registered parameter from this item, just its chosen mechanism. R66 (`output-format-surface`) decides which output formats exist and their rendering; whether the resulting text-mode table carries color styling (F289) is this item's concern, applied to whatever text-mode rendering R66's answer produces.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what precedence chain gates ANSI color output for `rs-launch-blueprint`, and whether color is gated once for both stdout and stderr or per-stream.
- HIGH: Should `rs-launch-blueprint` adopt py's three-tier chain (flag > `NO_COLOR` env > config), ts's four-tier chain (flag > `NO_COLOR` > `FORCE_COLOR` > TTY, no config layer), or synthesize both (a config layer plus `FORCE_COLOR` support) — and what does the wider Rust CLI ecosystem's convention (e.g. `anstream`'s or `supports-color`'s documented precedence) suggest as the canonical order?
- HIGH: What Rust crate implements `NO_COLOR`/`FORCE_COLOR`/TTY-aware color gating — e.g. `anstream`, `supports-color`, `anstyle` plus `is-terminal`, or `owo-colors` with hand-rolled gating — and does it provide the full flag-then-env-then-env-then-TTY chain out of the box, or does the template need to hand-roll the precedence logic around a lower-level color-rendering crate?
- MEDIUM: Should color be gated once for both stdout and stderr (py's shape — one gate reused for both) or per-stream, each independently gated on that stream's own TTY-ness (ts's shape, stderr-only in ts's case) — given the template's stdout may carry a styled text-mode result table (F289)?
- MEDIUM: What TTY-detection mechanism should gate color (and, by extension, the spinner and pager)? py checks the stream's own `isatty()` apart from Rich's `is_terminal`; ts injects a mockable `stderrIsTTY`/`stdoutIsTTY` flag on its deps object for testability. Does the candidate crate provide an equivalently testable seam, or does the template need its own injectable wrapper?
- LOW: Does the Rust config schema need a `color` key at all (py's config layer, part of F287), and if so, is defining that key this item's concern, or does it belong to R53 (`config-schema-validation`)/R55 (`config-error-tolerance`) as "a plain string/enum field" this item only names?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).

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
