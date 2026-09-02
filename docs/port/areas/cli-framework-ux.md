# Area: cli-framework-ux

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|---|
| F264 | CLI framework/parsing library | `src/py_launch_blueprint/cli/main.py:29` — `import click` | `src/router.ts:13` — `import { Command, CommanderError } from 'commander';` | different | D-016(1) | Tie-break picked Commander over oclif/`node:util parseArgs`. |
| F265 | Command surface shape: noun-verb subcommand groups vs. one default command | `src/py_launch_blueprint/cli/commands/__init__.py:26` — `COMMAND_GROUPS = [projects_group, config_group]`, each with its own verbs | `src/commands/projects.ts:70` — `.command('projects', { isDefault: true })`; `config` is a flat command, not a group | different | — | ts ported an older flat py CLI that predates the current noun-verb refactor. |
| F266 | `-V`/`--version` flag | `src/py_launch_blueprint/cli/main.py:71` — `"--version",` eager option triggers a callback | `src/router.ts:116` — `.version(...)` Commander built-in | same | — | — |
| F267 | Extended version output (runtime/platform info) | `src/py_launch_blueprint/cli/main.py:52` — prints tool, Python, and platform lines | — | py-only | — | ts's `--version` prints only the version string. |
| F268 | Shell completion script generation command | `src/py_launch_blueprint/cli/main.py:89` — `def completion(shell: str) -> None:` emits bash/zsh/fish completion | — | py-only | — | — |
| F269 | Blanket env-var binding for every global option | `src/py_launch_blueprint/cli/main.py:66` — `"auto_envvar_prefix": APP_NAME.upper(),` | — | py-only | — | click resolves any unlisted option from `PLBP_*`; no Commander equivalent is used. |
| F270 | Global options stackable on every (sub)command | `src/py_launch_blueprint/cli/options.py:232` — decorator reapplies `_GLOBAL_OPTIONS` on each command function | `src/router.ts:125` — options declared once on the root `program` object only | different | — | py's design lets flags land after the verb (`plbp projects list --json`). |
| F271 | Did-you-mean suggestion on an unknown command | `src/py_launch_blueprint/cli/groups.py:41` — `def resolve_command(` overrides `click.Group` | `src/router.ts:120` — `.showSuggestionAfterError(true)` | same | D-016(8) | — |
| F272 | Did-you-mean matching implementation | `src/py_launch_blueprint/cli/groups.py:48` — `matches = difflib.get_close_matches(` stdlib, cutoff 0.6 | `src/router.ts:120` — same call as above; matching logic is internal to Commander, no app code | different | D-016(8) | D-016(8) supersedes a hand-rolled did-you-mean with the framework's built-in. |
| F273 | Repeatable `-v`/`--verbose` flag | `src/py_launch_blueprint/cli/options.py:79` — `"-v", "--verbose", count=True` | `src/router.ts:126` — `'-v, --verbose',` with an accumulator callback | same | — | — |
| F274 | Verbosity-to-log-level resolution ladder | `src/py_launch_blueprint/cli/context.py:197` — `def _resolve_console_level(` | `src/lib/logger.ts:29` — `export function resolveLevel(flags: VerbosityFlags): LogLevel {` | different | D-018(3) | py maps to Python `logging` levels (WARNING default); ts maps to a 5-rung ladder incl. `--debug`. |
| F275 | `--no-input` flag disables interactive prompting | `src/py_launch_blueprint/cli/options.py:116` — `"--no-input", is_flag=True` | `src/router.ts:134` — `.option('--no-input', 'never prompt; select all fetched projects')` | same | — | REUSE covers the flag's existence only; py fails the command on `--no-input`, ts selects every fetched result instead — a real behavioral fork under one shared flag name, logged here per the governing rule rather than silently inherited. |
| F276 | Interactive yes/no confirmation prompt for destructive actions | `src/py_launch_blueprint/cli/options.py:278` — `return click.confirm(prompt, default=False, err=True)` | — | py-only | — | ts ships no mutating command needing a confirm gate at this commit. |
| F277 | `--dry-run` mutation-safety flag | `src/py_launch_blueprint/cli/options.py:242` — `"--dry-run",` | — | py-only | — | split from the prior combined row; attached via `mutation_options` to `config init`/`config set` |
| F278 | `-y`/`--yes` mutation-safety flag | `src/py_launch_blueprint/cli/options.py:248` — `"--yes",` | — | py-only | — | split from the prior combined row; attached via `mutation_options` to `config init`/`config set` |
| F279 | Interactive guided value prompt (config init) | `src/py_launch_blueprint/cli/commands/config.py:94` — `chosen[dotted] = click.prompt(` | — | py-only | — | — |
| F280 | Interactive multi-select prompt over fetched results | — | `src/commands/projects.ts:157` — `selected = await deps.prompter(`; `src/lib/adapters.ts:41` — `realPrompter` | ts-only | D-016(6) | `@inquirer/prompts` checkbox, rendered on stderr. |
| F281 | Clipboard-copy flag for command results | — | `src/commands/projects.ts:84` — `.option('--copy', 'copy results to clipboard', false)` | ts-only | D-016(7) | — |
| F282 | Clipboard write with headless-degrade handling | — | `src/lib/adapters.ts:49` — `export const realClipboard: ClipboardWriter = async (text) => {` | ts-only | D-016(7) | Failure is caught and re-raised as a `CliError` (`src/commands/projects.ts:193`) instead of crashing. |
| F283 | Progress spinner during network fetch | — | `src/commands/projects.ts:129` — `const spinner = spinnerEnabled ? deps.spinner('Fetching projects...') : undefined;` | ts-only | D-016(5) | Gated on stderr TTY and absence of `CI` env (`src/commands/projects.ts:127`). |
| F284 | Text-mode output paged through the user's pager | `src/py_launch_blueprint/cli/output.py:177` — `if not (self.paging and self.out.is_terminal and _isatty(self.out)):` | — | py-only | — | ADR 0008. |
| F285 | Pager command resolution precedence | `src/py_launch_blueprint/cli/output.py:88` — `for var in ("PLBP_PAGER", "PAGER"):` | — | py-only | — | Falls back to `less -FRX` (`src/py_launch_blueprint/cli/output.py:56`). |
| F286 | `--no-color` flag | `src/py_launch_blueprint/cli/options.py:101` — `click.option("--no-color", is_flag=True, ...)` | `src/router.ts:133` — `.option('--no-color', 'disable colored output')` | same | — | — |
| F287 | Color enablement precedence chain | `src/py_launch_blueprint/cli/context.py:188` — `def _resolve_color(no_color_flag: bool, config_color: str) -> str:` | `src/lib/colors.ts:26` — `export function colorEnabled(gate: ColorGate): boolean {` | different | D-018(2), D-038 | py chain: flag > `NO_COLOR` env > config; ts chain: flag > `NO_COLOR` > `FORCE_COLOR` > TTY (no config layer). |
| F288 | `FORCE_COLOR` env var forces color on | — | `src/lib/colors.ts:34` — `const forceColor = gate.env['FORCE_COLOR'];` | ts-only | D-018(2) | — |
| F289 | Color gated once for both streams vs. per-stream on stderr only | `src/py_launch_blueprint/cli/output.py:144` — `self.out = Console(highlight=False, no_color=nc, force_terminal=force)`, same `nc`/`force` reused for stderr | `src/router.ts:100` — `isTTY: deps.stderrIsTTY,` — gate computed from stderr TTY-ness only | different | — | py's stdout result table can carry color (`header_style`, `src/py_launch_blueprint/cli/output.py:232`); ts's stdout result document is never styled. |
| F290 | TTY detection mechanism gating interactive behavior | `src/py_launch_blueprint/cli/output.py:94` — `def _isatty(console: Console) -> bool:` checks the stream's own `isatty()` apart from rich's `is_terminal` | `src/router.ts:65` — `stdoutIsTTY: process.stdout.isTTY ?? false,` — reads the process stream flag directly, injected via `CliDeps` | different | — | — |
| F291 | Output-format choices | `src/py_launch_blueprint/cli/output.py:47` — `class OutputMode(StrEnum):` (`text`/`json`/`markdown`) | `src/lib/format.ts:16` — `export const OUTPUT_FORMATS = ['text', 'json', 'csv'] as const;` | different | — | py offers markdown; ts offers csv instead. |
| F292 | `--json` shorthand flag | `src/py_launch_blueprint/cli/options.py:66` — `"--json",` | `src/commands/projects.ts:82` — `.addOption(new Option('--json', ...).conflicts('format'))` | same | — | ts declares an explicit conflict with `--format`; py resolves precedence in `context.py:_resolve_mode`. |
| F293 | Result-to-file redirection flag | `src/py_launch_blueprint/cli/options.py:72` — `"--output-file",`, separate from format selection | `src/commands/projects.ts:83` — `.option('--output <file>', 'write results to file')` | different | — | Naming collision: ts's `--output` is py's `--output-file`; py's format flag is `-o`/`--output`, ts's is `--format`. |
| F294 | JSON machine-readable error envelope on stderr | `src/py_launch_blueprint/cli/output.py:283` — builds the `detail` dict inside `error()` | `src/router.ts:216` — `deps.stderr(\`${JSON.stringify({ error: { code, message: concise } })}\n\`);` | same | D-018(4), D-033 | — |
| F295 | Error-envelope "code" field source | `src/py_launch_blueprint/core/errors.py:51` — `ERROR_CODE_UNEXPECTED = "PLBP000"` stable string catalog | `src/router.ts:211` — `const code = err instanceof Error ? err.name : 'Error';` transient exception class name | different | — | py's codes are an append-only documented table; ts has no equivalent catalog. |
| F296 | Structured `hint` field on an error, rendered separately from the message | `src/py_launch_blueprint/core/errors.py:76` — `self.hint = hint` (rendered at `src/py_launch_blueprint/cli/output.py:298`) | — | py-only | — | ts inlines remedy text directly into the error message instead (e.g. `missingTokenMessage`). |
| F297 | Exit-code taxonomy | `src/py_launch_blueprint/core/errors.py:34` — `class ExitCode(IntEnum):` (SUCCESS/CONFIG/AUTH/API/IO/INTERRUPT = 0-5) | `src/lib/errors.ts:13` — `export const EXIT_CODES = {` (success/error/usage/notFound/auth/conflict/sigint/sigterm = 0,1,2,3,4,5,130,143) | different | D-016(2) | — |
| F298 | Process-interrupt (Ctrl-C) exit-code contract | `src/py_launch_blueprint/cli/options.py:215` — `except KeyboardInterrupt:` exits `ExitCode.INTERRUPT` (5) | `src/cli.ts:21` — `process.on('SIGINT', () => {` exits 130 | different | D-016(2), D-033 | ts also handles `SIGTERM` separately (exit 143), which py does not. |
| F299 | Interactive-prompt cancellation (^C mid-prompt) | — | `src/router.ts:200` — `if (err instanceof Error && err.name === 'ExitPromptError') {` | ts-only | D-033 | py has no interactive multi-select to cancel. |
| F300 | Broken-pipe (EPIPE) handling | — | `src/cli.ts:17` — `process.stdout.on('error', ignoreEpipe);` | ts-only | — | Lets a downstream pipe reader (e.g. `head`) close early without a crash. |
| F301 | Unexpected-error stack trace shown to the user only under verbose/debug | `src/py_launch_blueprint/cli/options.py:227` — `if app.verbose:` then `app.renderer.err.print_exception()` | `src/router.ts:223` — debug or verbose >= 1 gate before printing `err.stack` | same | — | — |
| F302 | Unexpected errors persisted to a crash log file | `src/py_launch_blueprint/cli/options.py:143` — `crash_path = paths.state_file("crash")` | — | py-only | — | Best-effort append to `<state>/plbp/plbp_crash.log`; ADR 0006. |

## Language-bound tools
- `click` (py) — CLI parsing framework: groups, options, eager callbacks, shell-completion helpers
- `rich` (py) — console rendering: colored/plain text, tables, pager capture buffer
- `difflib` (py) — stdlib fuzzy matching backing the did-you-mean suggestions
- `commander` (ts) — CLI parsing framework: commands, options, built-in did-you-mean and version handling
- `@inquirer/prompts` (ts) — interactive checkbox multi-select prompt
- `clipboardy` (ts) — cross-platform OS clipboard writer for `--copy`
- `yocto-spinner` (ts) — stderr progress spinner during the network fetch
- `picocolors` (ts) — `createColors(enabled)` semantic color wrapper gated by `colorEnabled()`
- `cli-table3` (ts) — pre-selection preview table rendering

## Cross-area parameters
- `http-transport-injection-seam` — `CliDeps.fetchImpl` is the same injection seam a testing-focused area would fake to unit-test `runProjects`.
- `error-taxonomy-exit-codes` — this area owns the exit-code mapping consumed elsewhere; not a dependency of this area.

## Files read
- py: `src/py_launch_blueprint/cli/__init__.py` — no feature: re-exports `cli`, no CLI-UX logic of its own
- py: `src/py_launch_blueprint/cli/main.py`
- py: `src/py_launch_blueprint/cli/context.py`
- py: `src/py_launch_blueprint/cli/groups.py`
- py: `src/py_launch_blueprint/cli/options.py`
- py: `src/py_launch_blueprint/cli/output.py`
- py: `src/py_launch_blueprint/cli/exit_codes.py` — no feature: re-exports `core.errors.ExitCode` for a local import point
- py: `src/py_launch_blueprint/cli/commands/__init__.py`
- py: `src/py_launch_blueprint/cli/commands/config.py`
- py: `src/py_launch_blueprint/cli/commands/projects.py`
- py: `src/py_launch_blueprint/core/errors.py`
- py: `docs/adr/0006-stable-error-codes-hints-crash-log.md`
- py: `docs/adr/0007-did-you-mean-stdlib-difflib.md`
- py: `docs/adr/0008-pager-for-long-text-output.md`
- ts: `src/cli.ts`
- ts: `src/router.ts`
- ts: `src/lib/colors.ts`
- ts: `src/lib/errors.ts`
- ts: `src/lib/logger.ts`
- ts: `src/lib/adapters.ts`
- ts: `src/lib/format.ts`
- ts: `src/commands/projects.ts`
- ts: `src/lib/config.ts` — no feature: token/workspace/limit resolution is the config-loading area's territory; only the missing-token remedy message (cited above) belongs to this area
- ts: `src/lib/api.ts` — no feature: HTTP client/data-fetching, not CLI parsing or UX
- ts: `src/lib.ts` — no feature: library re-export surface, not CLI-specific
- ts: `src/version.ts` — no feature: version constant only, consumed by the `--version` row already cited
- ts: `docs/port/TS_PORT_DECISIONS.md`
