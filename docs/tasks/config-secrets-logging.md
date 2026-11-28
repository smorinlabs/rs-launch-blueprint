# Configuration, Secrets, and Logging

This guide covers how `rslbp` and `rslbp-serve` discover layered configuration,
protect credentials, and format redacted diagnostic logs (`R52`–`R59`).

## Six-Rung Configuration Precedence (`R54`)

Every non-secret CLI setting resolves through six layers, highest precedence
first:

1. **CLI flags** (`-o`, `--color`, `--log-level`, `--config`, ...)
2. **Environment variables** (`RSLBP_OUTPUT`, `RSLBP_LOG_LEVEL`,
   `RSLBP_LOG_FORMAT`, `RSLBP_CONFIG`)
3. **Project layer:** nearest `.rslbp/rslbp_config.toml` discovered walking
   upward from the working directory, stopping inclusively at `.git` or a
   `Cargo.toml` declaring `[workspace]`
4. **User layer:** `$XDG_CONFIG_HOME/rslbp/rslbp_config.toml` (via `etcetera`)
5. **System layer:** each `$XDG_CONFIG_DIRS` entry (defaults to `/etc/xdg`)
6. **Built-in defaults** (`crates/core/src/config/schema.rs`)

Passing `--config <PATH>` (or `RSLBP_CONFIG=<PATH>`) replaces layered discovery
entirely.

## Error Tolerance & Comment-Preserving Writes (`R52`, `R53`, `R55`)

- **Two-phase validation:** raw TOML layers are parsed with `toml 1.1.6`,
  validated per key in deterministic sorted order (`UnvalidatedConfig` ->
  `ValidConfig`), merged recursively, and typed once via `serde`.
- **Provenance-aware failures:** an unreadable or unparsable _explicit_
  `--config` file fails loudly (`RSLB104` exit `1` / `RSLB202` exit `2`). A
  missing explicit path or defective _discovered_ layer degrades to a warning so
  a stray file never bricks the CLI. Invalid leaf values drop with a warning
  naming the file and dotted key path.
- **Writing config safely:** `rslbp config set <key> <value>` uses
  `toml_edit 0.25.15` to preserve existing comments and formatting and writes
  atomically with POSIX mode `0600` at creation (`F243`).

## XDG Directory Set (`R57`)

`crates/core/src/paths.rs` resolves all four directories once at the composition
root via `etcetera 0.11.0` (XDG strategy on both Linux and macOS):

| Directory | Default Path (Linux & macOS) | Contents                                             |
| --------- | ---------------------------- | ---------------------------------------------------- |
| Config    | `$XDG_CONFIG_HOME/rslbp/`    | `rslbp_config.toml`                                  |
| Data      | `$XDG_DATA_HOME/rslbp/`      | Persistent application data                          |
| State     | `$XDG_STATE_HOME/rslbp/`     | `credentials.toml`, `rslbp.log`, `rslbp_crash.jsonl` |
| Cache     | `$XDG_CACHE_HOME/rslbp/`     | Disposable cache artifacts                           |

## Secret Policy (`R56`)

Layered configuration files **never** carry secrets:

- Any `token` key found in `rslbp_config.toml` is ignored with a warning.
- `rslbp config set token <value>` is refused with `RSLB204` (exit `2`).
- Credentials resolve strictly across three tiers:
  1. `--token-file <PATH>` (or `--token-file -` for stdin; missing/empty fails
     with `RSLB401` and never falls through)
  2. `RSLBP_TOKEN` environment variable (empty string treated as unset)
  3. Dedicated `0600` credential store (`$XDG_STATE_HOME/rslbp/credentials.toml`,
     or OS keychain when built with `--features keychain`)
- Files containing secrets with group/other permission bits (`mode & 0o077 != 0`)
  emit a non-fatal remediation warning (`chmod 600 ...`).
- In memory, tokens are held in `secrecy::SecretString` / `zeroize` and display
  only as `***<last4>` (for length >= 8) or `***`.

## Structured Logging & Redaction (`R58`, `R59`)

`src/telemetry.rs` initializes one `tracing` + `tracing-subscriber` pipeline
writing exclusively to `stderr` (never `stdout`), using a `reload::Handle` so
the log level updates after config loads without dropping early startup events:

- **CLI profile (`Profile::Cli`):** default level `warn`; `--log-format auto`
  renders human console lines on a TTY and NDJSON when piped. Precedence ladder:
  `--debug` > `--log-level` > `--quiet` (`error`) > `-v/-vv/-vvv` >
  `RSLBP_LOG_LEVEL` > `[logging].level` > `warn`.
- **Service profile (`Profile::Service`):** configured solely via
  `RSLBP_WEB_LOG_LEVEL` (default `info`) and `RSLBP_WEB_LOG_FORMAT` (`json`
  default or `console`; `auto` is rejected with `RSLB203`).
- **Format-time redaction:** template-owned console and JSON formatters mask
  keys matching `token`, `password`, `secret`, `authorization`, `api_key`,
  `apikey`, `credential`, and `cookie` (case-insensitive substring) to
  `[REDACTED]`. `SecretString` provides type-level first-line protection
  (`OV-09` records the residual gap for non-sensitive key names carrying raw
  strings).
- **Optional CLI file sink (`R59`):** `--log-file[=PATH]` or `[logging].file`
  attaches an std-only `0600` rotating file writer (10 MiB x 5 backups) with its
  own independent level (`[logging].file-level`) and format
  (`[logging].file-format`: `text` or `json`).
