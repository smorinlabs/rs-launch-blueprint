# `rslbp` — Noun-Verb CLI Walkthrough

`rslbp` is the command-line entry point for `rs-launch-blueprint`. Commands
follow a `rslbp <noun> <verb>` grammar built with `clap` derive (`R60`), share
one set of stackable global flags, enforce a strict stdout/stderr contract, and
emit structured, redacted diagnostics out of the box.

## Architecture

The Cargo workspace separates domain logic from front-end adapters (`R01`,
`R02`, `R05`):

| Package / Path        | Crate Name                 | Role                                                                                                        |
| --------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `crates/core/`        | `rs-launch-blueprint-core` | Pure synchronous domain models, `ProjectsPort`, `ProjectsService`, config (`config`), secrets, errors.      |
| `Cargo.toml` / `src/` | `rs-launch-blueprint`      | Standalone `[lib]`-only Rust library: `HttpProjectsPort` (`http`), optional `keychain`, curated facade.     |
| `crates/cli/`         | `rs-launch-blueprint-cli`  | Published CLI binary (`rslbp`): `clap`, renderers, color, pager, prompter, clipboard, crash sink, logs.     |
| `crates/web/`         | `rs-launch-blueprint-web`  | Optional internal Axum HTTP service (`publish = false`, `rslbp-serve`). See [EXAMPLEWEB.md](EXAMPLEWEB.md). |

Every command operates on typed `crates/core` models (`Project`, `Diagnostics`,
`ValidConfig`) that serialize directly to JSON and render through `crates/cli`
into `table`, `json`, `markdown`, or `name` output.

## Global Flags (Accepted on Every Command)

Global flags are stackable before or after any subcommand (`R60` F270):

| Flag / Option                   | Env Var            | Purpose                                                                          |
| ------------------------------- | ------------------ | -------------------------------------------------------------------------------- |
| `-o, --output <FORMAT>`         | `RSLBP_OUTPUT`     | Output format: `table` (default), `json`, `markdown`, or `name` (`R66`).         |
| `--json`                        | —                  | Shorthand for `--output json`.                                                   |
| `--output-file <PATH>`          | —                  | Write result output to `<PATH>` (`-` selects stdout).                            |
| `--no-clobber`                  | —                  | Refuse to overwrite an existing `--output-file` target (`RSLB501`, exit `5`).    |
| `--copy`                        | —                  | Copy rendered result to the system clipboard (`arboard`, `clipboard` feature).   |
| `--no-pager`                    | —                  | Disable automatic terminal paging for `table` output (`R64`).                    |
| `--no-input`                    | —                  | Never prompt interactively; fail with `RSLB205` (exit `2`) if input is required. |
| `--color <auto\|always\|never>` | —                  | Control ANSI color emission (`R65`).                                             |
| `--no-color`                    | —                  | Alias for `--color never`.                                                       |
| `-v, --verbose`                 | —                  | Increase console log level (`-v` info, `-vv` debug, `-vvv` trace).               |
| `-q, --quiet`                   | —                  | Lower console log level to `error` and suppress progress indicators.             |
| `--debug`                       | —                  | Enable `trace` logs with source file, line, and thread metadata.                 |
| `--log-level <LEVEL>`           | `RSLBP_LOG_LEVEL`  | Explicit console log level: `off`, `error`, `warn`, `info`, `debug`, `trace`.    |
| `--log-format <FORMAT>`         | `RSLBP_LOG_FORMAT` | Console log format: `auto` (TTY -> console, pipe -> JSON), `console`, or `json`. |
| `--log-file[=PATH]`             | —                  | Enable rotating file logging (bare `--log-file` uses `<state>/rslbp/rslbp.log`). |
| `--config <PATH>`               | `RSLBP_CONFIG`     | Explicit TOML config path (replaces layered discovery entirely).                 |
| `--token-file <PATH>`           | —                  | Read API token from `<PATH>` (`-` reads stdin); never pass tokens on argv.       |
| `-V, --version`                 | —                  | Print single-line `rslbp <semver>` to stdout and exit `0`.                       |
| `-h, --help`                    | —                  | Print command help to stdout and exit `0` at every level.                        |

## Output Contract

- **Stream discipline:** primary command results go exclusively to `stdout` (or
  `--output-file`); logs, progress spinners, prompts, warnings, and errors go
  exclusively to `stderr`. `rslbp ... --json | jq` remains safe at any verbosity.
- **Format stability:** output never auto-switches format when piped. Specify
  `-o json`, `--json`, `-o markdown`, or `-o name` explicitly (or set
  `RSLBP_OUTPUT` / `[output].format`).
- **4-tier color chain (`R65`, `anstream`/`anstyle`):**
  `--no-color` / `--color` > `NO_COLOR` > `FORCE_COLOR` / `CLICOLOR_FORCE` >
  `[output].color` config > per-stream TTY auto-detection.
- **2-tier pager (`R64`, `shlex`):** interactive `table` output taller than the
  terminal pipes through `RSLBP_PAGER` > `PAGER` > `less -FRX` (set-but-empty
  disables paging, git-style). Disabled when piped, under `--no-pager`,
  `--no-input`, `--output-file`, or non-table formats; falls back cleanly if the
  pager binary is missing.
- **Rich terminal rows (`R85`):** on capable interactive terminals in `table`
  mode, URLs render as OSC-8 clickable hyperlinks and timestamps render as
  relative times. `--json` always emits raw fields and ISO-8601 UTC timestamps;
  `markdown` and `name` emit plain text.
- **Progress spinner (`R63`, `indicatif`):** shown on `stderr` during network
  fetches only when `stderr` is a TTY, `--quiet` is off, and `CI` is unset.
- **Broken pipe (`R67`):** a `BrokenPipe` writing primary output to `stdout`
  exits `0` silently (e.g., `rslbp project list | head -n 1`).

## Exit Codes & Stable Error Catalog (`error-contract/v1`)

Both tables are **stable and append-only** (`crates/core/src/error.rs`, `R67`).
In JSON mode, failures write a single JSON object to `stderr` while keeping
`stdout` byte-empty on pre-result errors:

```json
{
  "error": {
    "code": "RSLB301",
    "message": "project 'missing-id' not found"
  }
}
```

When an actionable remediation exists, `"hint"` is included alongside `"code"`
and `"message"` (and omitted, never `null`, when absent).

| Exit  | Taxonomy  | Error Codes                                                                                                                                                      |
| ----- | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `0`   | Success   | — (also returned when user declines a confirmation prompt per `OV-02`)                                                                                           |
| `1`   | Runtime   | `RSLB000` unexpected, `RSLB101` I/O/clipboard, `RSLB102` transport, `RSLB103` API, `RSLB104` config unreadable                                                   |
| `2`   | Usage     | `RSLB201` CLI parse/usage, `RSLB202` config TOML unparsable, `RSLB203` config invalid, `RSLB204` prohibited secret channel, `RSLB205` required input unavailable |
| `3`   | Not Found | `RSLB301` resource not found                                                                                                                                     |
| `4`   | Auth      | `RSLB401` credentials absent, `RSLB402` credentials rejected (`401`/`403`)                                                                                       |
| `5`   | Conflict  | `RSLB501` conflict or precondition failed (e.g., `--no-clobber` target exists)                                                                                   |
| `130` | `SIGINT`  | `RSLB901` process `SIGINT`, `RSLB903` interactive prompt interrupted (`Ctrl-C`)                                                                                  |
| `143` | `SIGTERM` | `RSLB902` process `SIGTERM`                                                                                                                                      |

Unexpected errors (`RSLB000`) append a sanitized `0600` NDJSON crash record
(timestamp, version, PID, code, sanitized cause chain — never argv, env,
headers, or tokens) to `$XDG_STATE_HOME/rslbp/rslbp_crash.jsonl`.

## Usage Examples

```bash
# Version & build metadata
rslbp --version                          # single-line `rslbp 0.1.0`
rslbp version --json                     # version, target triple, and rustc release

# Projects (noun) -> list / get / create / delete (verbs)
rslbp project list
rslbp project list --workspace "Core" --limit 25 --json
rslbp project list -o markdown --output-file projects.md --no-clobber
rslbp project list --select              # interactive multi-select on a TTY (`inquire`)
rslbp project get proj-123
rslbp project create "New Service" --workspace "Core" --dry-run
rslbp project delete proj-123 --dry-run  # preview without mutating
rslbp project delete proj-123 --yes      # skip confirmation prompt

# Configuration (non-secret TOML keys, comment-preserving writes via toml_edit)
rslbp config init                        # guided setup (prompts on stderr)
rslbp config init --yes                  # accept resolved defaults without prompting
rslbp config path                        # active config file path & existence status
rslbp config show --json                 # merged configuration + contributing layers
rslbp config get output.format           # resolved value + provenance
rslbp config set output.color always --dry-run
rslbp config set logging.level info --yes
rslbp config get token --json            # masked token preview + channel provenance

# Environment & credential diagnostics (exits non-zero on error checks)
rslbp diagnostics
rslbp doctor --json                      # `doctor` is a built-in alias for `diagnostics`
rslbp diagnostics --bundle --json        # redacted snapshot safe for bug reports

# Shell completions (bash, zsh, fish, elvish, powershell)
rslbp completion bash >> ~/.bashrc
eval "$(rslbp completion zsh)"
rslbp completion fish > ~/.config/fish/completions/rslbp.fish
```

## Configuration & XDG Paths

Configuration resolves across six layers (highest precedence wins, `R54`):

1. CLI flags (`-o`, `--color`, `--log-level`, ...)
2. Environment variables (`RSLBP_OUTPUT`, `RSLBP_LOG_LEVEL`, `RSLBP_LOG_FORMAT`, `RSLBP_CONFIG`)
3. Project config: nearest `.rslbp/rslbp_config.toml` walking upward from `cwd` (stopping at `.git` or a workspace `Cargo.toml`)
4. User config: `$XDG_CONFIG_HOME/rslbp/rslbp_config.toml` (default `~/.config/rslbp/rslbp_config.toml`)
5. System config: `$XDG_CONFIG_DIRS` entries (default `/etc/xdg/rslbp/rslbp_config.toml`)
6. Built-in typed defaults (`crates/core/src/config/schema.rs`)

Example `rslbp_config.toml`:

```toml
# Non-secret configuration only — tokens are refused (`RSLB204`).
[output]
format = "table" # table | json | markdown | name
color = "auto" # auto | always | never

[logging]
level = "warn" # off | error | warn | info | debug | trace
file-format = "text" # text | json
```

All four per-user directories resolve through `etcetera` (`crates/core/src/paths.rs`, `R57`):

- **Config:** `$XDG_CONFIG_HOME/rslbp/rslbp_config.toml`
- **Data:** `$XDG_DATA_HOME/rslbp/`
- **State:** `$XDG_STATE_HOME/rslbp/` (`credentials.toml`, `rslbp.log`, `rslbp_crash.jsonl`)
- **Cache:** `$XDG_CACHE_HOME/rslbp/`

### Secret Policy (`R56`)

Layered configuration files **never** supply secrets (`rslbp config set token ...`
exits `2` with `RSLB204`). Credentials resolve strictly in three tiers:

1. `--token-file <PATH>` (or `--token-file -` to read from `stdin`)
2. `RSLBP_TOKEN` environment variable (empty string treated as unset)
3. Dedicated `0600` credential store (`$XDG_STATE_HOME/rslbp/credentials.toml`,
   or the OS keychain when compiled with `--features keychain`)

Secrets are wrapped in `secrecy::SecretString` / `zeroize`, never serialized to
JSON logs, and masked (`***<last4>` for lengths >= 8, `***` otherwise) in display
output.

## Structured Logging (`R58`, `R59`)

Diagnostics use `tracing` + `tracing-subscriber` with template-owned redacting
formatters (masking sensitive keys `token`, `password`, `secret`, `authorization`,
`api_key`, `apikey`, `credential`, and `cookie` with `[REDACTED]`):

- **Console sink (`stderr`, always active):** defaults to `warn`; `--log-format auto`
  emits human console lines on a TTY and NDJSON when piped. Level ladder:
  `--debug` > `--log-level` > `--quiet` > `-v/-vv/-vvv` > `RSLBP_LOG_LEVEL` >
  `[logging].level` > `warn`.
- **Rotating file sink (opt-in):** enable via `--log-file`, `--log-file=/path/to/app.log`,
  or `[logging].file`. Rotates at 10 MiB with 5 backups using an std-only `0600`
  rotating writer and independent `[logging].file-level` / `[logging].file-format`.

```bash
rslbp diagnostics -vv                                  # debug console logs on stderr
rslbp diagnostics --log-file                           # default XDG state rotating log
rslbp diagnostics --log-file=/tmp/rslbp.log -q         # quiet console, full file sink
```
