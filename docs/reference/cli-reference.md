# CLI Reference (`rslbp`)

`rslbp` is the primary command-line binary built from `rs-launch-blueprint`
(`crates/cli/src/args.rs`, `R60`–`R67`, `R85`).

## Command Tree

```text
rslbp [GLOBAL FLAGS] <COMMAND>

Commands:
  project      Manage project resources (alias: projects)
    list       List project records [--workspace <NAME>] [--limit <N>] [--select]
    get        Fetch a single project by ID <ID>
    create     Create a project <NAME> [--workspace <NAME>] [--dry-run]
    delete     Delete a project <ID> [--dry-run] [-y|--yes]
  config       Inspect and edit layered TOML configuration
    show       Show merged effective configuration and contributing sources
    get        Show one resolved dotted key (or `token` for masked status) <KEY>
    set        Write a non-secret dotted key <KEY> <VALUE> [--dry-run] [-y|--yes]
    path       Show active user config file path and existence status
    init       Create or update config via guided prompts [--dry-run] [-y|--yes]
  version      Print SemVer version, target triple, and rustc release
  diagnostics  Inspect environment, config, and credential readiness (alias: doctor)
               [--bundle]
  completion   Print shell completion script <bash|zsh|fish|elvish|powershell>
```

## Global Flags & Curated Environment Variables

All global flags are stackable before or after any subcommand. Only four
curated environment bindings appear directly on the `clap` command (`R60` AC5):

| Flag                    | Env Binding        | Values / Default                                           |
| ----------------------- | ------------------ | ---------------------------------------------------------- |
| `-o, --output <FORMAT>` | `RSLBP_OUTPUT`     | `table` (default), `json`, `markdown`, `name`              |
| `--json`                | —                  | Shorthand for `--output json`                              |
| `--output-file <PATH>`  | —                  | Destination path (`-` writes to `stdout`)                  |
| `--no-clobber`          | —                  | Refuse overwrite of existing `--output-file` (`RSLB501`)   |
| `--copy`                | —                  | Copy rendered output to clipboard (`clipboard` feature)    |
| `--no-pager`            | —                  | Disable automatic `table` paging                           |
| `--no-input`            | —                  | Forbid interactive prompts (`RSLB205` if input required)   |
| `--color <WHEN>`        | —                  | `auto` (default), `always`, `never`                        |
| `--no-color`            | —                  | Alias for `--color never`                                  |
| `-v, --verbose`         | —                  | Repeatable count (`-v` info, `-vv` debug, `-vvv` trace)    |
| `-q, --quiet`           | —                  | Console level `error`; suppresses progress spinner         |
| `--debug`               | —                  | `trace` level with source file, line, and thread metadata  |
| `--log-level <LEVEL>`   | `RSLBP_LOG_LEVEL`  | `off`, `error`, `warn` (default), `info`, `debug`, `trace` |
| `--log-format <FORMAT>` | `RSLBP_LOG_FORMAT` | `auto` (default), `console`, `json`                        |
| `--log-file[=PATH]`     | —                  | Enable rotating file sink (omit value for XDG state path)  |
| `--config <PATH>`       | `RSLBP_CONFIG`     | Explicit TOML config file (replaces 6-rung discovery)      |
| `--token-file <PATH>`   | —                  | Read API token from file (`-` reads `stdin`)               |
| `-V, --version`         | —                  | Single-line `rslbp <semver>` to `stdout`, exit `0`         |
| `-h, --help`            | —                  | Rendered help text to `stdout`, exit `0`                   |

Additional environment variables honored outside `clap`:

- `RSLBP_TOKEN` — Tier 2 credential source (`R56`; empty string treated as unset)
- `RSLBP_PAGER` / `PAGER` — Pager command override (empty string disables paging, `R64`)
- `NO_COLOR` / `FORCE_COLOR` / `CLICOLOR_FORCE` — Color precedence chain (`R65`)
- `CI` — Suppresses interactive progress spinner (`R63`)
- `XDG_CONFIG_HOME`, `XDG_CONFIG_DIRS`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME` — XDG paths (`R54`, `R57`)

## Writable Configuration Keys

| Dotted Key            | Type / Allowed Values                            | Default   |
| --------------------- | ------------------------------------------------ | --------- |
| `output.format`       | `table`, `json`, `markdown`, `name`              | `table`   |
| `output.color`        | `auto`, `always`, `never`                        | `auto`    |
| `output.limit`        | Positive integer (`>= 1`)                        | _(unset)_ |
| `logging.level`       | `off`, `error`, `warn`, `info`, `debug`, `trace` | `warn`    |
| `logging.file`        | Filesystem path                                  | _(unset)_ |
| `logging.file-format` | `text`, `json`                                   | `text`    |
| `logging.file-level`  | `off`, `error`, `warn`, `info`, `debug`, `trace` | _(unset)_ |

Attempting `rslbp config set token <value>` is always refused with `RSLB204`
(exit `2`).

## Append-Only `error-contract/v1` Catalog (`R67`)

| Code      | Exit  | Meaning                                             |
| --------- | ----- | --------------------------------------------------- |
| `RSLB000` | `1`   | Unexpected/internal error (persisted to crash sink) |
| `RSLB101` | `1`   | Local I/O, clipboard, or unavailable adapter error  |
| `RSLB102` | `1`   | Network transport failure (DNS/connect/timeout/TLS) |
| `RSLB103` | `1`   | Remote API status or payload failure                |
| `RSLB104` | `1`   | Explicit configuration file unreadable              |
| `RSLB201` | `2`   | CLI usage or argument parse error                   |
| `RSLB202` | `2`   | Explicit configuration file unparsable TOML         |
| `RSLB203` | `2`   | Configuration key or value invalid                  |
| `RSLB204` | `2`   | Secret supplied through prohibited config channel   |
| `RSLB205` | `2`   | Required non-auth input or consent unavailable      |
| `RSLB301` | `3`   | Requested resource not found                        |
| `RSLB401` | `4`   | Required credentials absent                         |
| `RSLB402` | `4`   | Credentials rejected by remote API (`401`/`403`)    |
| `RSLB501` | `5`   | Resource conflict or precondition failed            |
| `RSLB901` | `130` | Process interrupted by `SIGINT`                     |
| `RSLB902` | `143` | Process terminated by `SIGTERM`                     |
| `RSLB903` | `130` | Interactive prompt interrupted by `Ctrl-C`          |

For a hands-on walkthrough with examples, see `EXAMPLECLI.md` at the repository
root.
