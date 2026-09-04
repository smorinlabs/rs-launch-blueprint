# Area: config-env-logging

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|---|
| F224 | config file format | `src/py_launch_blueprint/core/config.py:91` — `tomllib.loads(...)` (TOML) | `src/lib/config.ts:118` — `parse(raw)` (smol-toml, TOML) | same | D-017(1) | Both standardize on TOML; py stdlib `tomllib`, ts `smol-toml`. |
| F225 | TOML parse library | `src/py_launch_blueprint/core/config.py:40` — `import tomllib` (stdlib) | `src/lib/config.ts:20` — `import { parse, stringify } from 'smol-toml'` | different | D-017(2) | — |
| F226 | TOML write library | `src/py_launch_blueprint/core/config.py:45` — `import tomli_w` | `src/lib/config.ts:20` — `import { parse, stringify } from 'smol-toml'` | different | D-017(2) | py uses a separate write library; ts's smol-toml both parses and stringifies. |
| F227 | config file naming convention (`<tool>_config.toml`) | `src/py_launch_blueprint/core/paths.py:171` — `CONFIG_FILENAME = f"{APP_NAME}_config.toml"` | `src/lib/config.ts:27` — `export const CONFIG_FILE_NAME = 'ts-projects_config.toml';` | same | D-029 | Same `<tool>_config.toml` shape, different tool name. |
| F228 | config schema validation library | `src/py_launch_blueprint/core/settings.py:33` — `from pydantic import BaseModel, ValidationError` | `src/lib/config.ts:21` — `import { z } from 'zod';` | different | D-017(4) | — |
| F229 | typed config schema with per-key validation | `src/py_launch_blueprint/core/settings.py:40` — `class OutputSettings(BaseModel):` (`format`/`color` literals) | `src/lib/config.ts:33` — `configFileSchema` (`token`/`workspace`/`limit`) | same | D-017(4) | Both validate the parsed file against a typed schema before use. |
| F230 | layered config discovery (system → user → project, later wins) | `src/py_launch_blueprint/core/config.py:134` — `layers = [*reversed(paths.system_config_files()), target, paths.project_config_file()]` | — | py-only | D-017(1) | ts has a single discovery tier (the default user path); no system or project-local layer. |
| F231 | system-wide config directory (`$XDG_CONFIG_DIRS`/`%PROGRAMDATA%`) | `src/py_launch_blueprint/core/paths.py:108` — `def config_dirs() -> list[Path]:` (multi-dir, Windows `%PROGRAMDATA%` fallback) | — | py-only | — | No system-config-dir concept in ts; only the per-user `$XDG_CONFIG_HOME` tier exists. |
| F232 | project-local config file discovery (`./<tool>_config.toml`, dotfile preferred) | `src/py_launch_blueprint/core/paths.py:184` — `def project_config_file(start: Path &#124; None = None) -> Path:` | — | py-only | — | ts has no cwd-relative discovery tier at all. |
| F233 | `--config` flag replaces discovery entirely | `src/py_launch_blueprint/core/config.py:124` — `def _discovery_paths(config_file: str &#124; None) -> tuple[Path, list[Path]]:` | `src/lib/config.ts:152` — `if (options.configPathFlag !== undefined) {` | same | D-017(1) | Both treat an explicit `--config` path as a full override of discovery, not an additional layer. |
| F234 | `--config` env-var alias | `src/py_launch_blueprint/cli/options.py:107` — `envvar="PLBP_CONFIG",` | — | py-only | — | ts's `--config <path>` option has no environment-variable equivalent. |
| F235 | explicit `--config` pointing at a missing file | `src/py_launch_blueprint/core/config.py:114` — `if not path.exists(): return {}` (tolerated, valid `config set` target) | `src/lib/config.ts:153` — `if (!fs.existsSync(options.configPathFlag)) { throw new UsageError(...)`, exit 2 | different | — | py accepts a missing explicit path as an empty layer; ts's comment cites `click.Path(exists=True)` parity, but this pinned py commit's `--config` option (`cli/options.py:105`, `click.Path(dir_okay=False)`) does not set `exists=True`. |
| F236 | unparsable *discovered* config layer degrades to a warning, not a crash | `src/py_launch_blueprint/core/config.py:102` — `except (OSError, tomllib.TOMLDecodeError) as exc: return {}, f"ignoring unreadable config file {path}: {exc}"` | — | py-only | — | ts has no discovered-and-tolerated tier; its one discovered file, if present, is read the same strict way as `--config`. |
| F237 | unparsable *explicit* config file raises loudly | `src/py_launch_blueprint/core/config.py:118` — `raise ConfigError(f"invalid TOML in config file {path}: {exc}")` | `src/lib/config.ts:119` — `throw new ConfigError(...)` on parse failure | same | D-017(1) | Both treat a corrupt file the user explicitly named/found as a hard configuration error. |
| F238 | invalid config *values* (right TOML, wrong value) degrade to a warning and are dropped | `src/py_launch_blueprint/core/settings.py:169` — `warnings.append(f"ignoring invalid config value {section}.{key} = {bad!r}{suffix}")` | — | py-only | — | ts's zod `safeParse` failure raises `ConfigError` for the whole file (`src/lib/config.ts:129`) instead of dropping the one bad key. |
| F239 | config file secrets rule | `src/py_launch_blueprint/core/config.py:164` — `settings, value_warnings = settings_from_layers(layers)` merges only `[output]`/`[logging]`; a `token` key is never read from any layer | `src/lib/config.ts:177` — `else if (fileValues.token !== undefined ...) { token = fileValues.token; tokenSource = 'file'; }` | different | D-017(1), D-017(5) | py (ADR 0002): token comes from `--token`/env only, never a file, and a `token` key is silently ignored. ts allows the config file as the lowest-precedence token source. |
| F240 | token resolution precedence | `src/py_launch_blueprint/core/config.py:169` — flag then `os.getenv(TOKEN_ENV_VAR)` (only two tiers) | `src/lib/config.ts:171` — flag `>` env `>` file (three tiers) | different | D-017(5) | Direct consequence of the secrets-rule row above: ts's chain has one more tier than py's. |
| F241 | token env var name | `src/py_launch_blueprint/core/config.py:56` — `TOKEN_ENV_VAR = "PLBP_TOKEN"` | `src/lib/config.ts:30` — `export const TOKEN_ENV_VAR = 'TS_PROJECTS_TOKEN';` | same | D-029 | Same role, renamed per the port's naming scheme. |
| F242 | empty-string env/flag token treated as unset | `src/py_launch_blueprint/core/config.py:173` — `if env_token:` (falsy check) | `src/lib/config.ts:171` — `options.flagToken !== undefined && options.flagToken !== ''` | same | — | Both fall through to the next tier on an empty string rather than accepting it. |
| F243 | config file written with restrictive permissions | `src/py_launch_blueprint/core/config.py:224` — `tempfile.mkstemp(dir=config_path.parent, prefix=...)` (0600 from first byte) then `os.replace` | `src/lib/config.ts:264` — `fs.writeFileSync(path, data, { mode: 0o600 }); fs.chmodSync(path, 0o600);` | same | D-017(6) | Both restrict the written file to the owner on POSIX; py's is atomic (`os.replace`) while ts writes/chmods in place. |
| F244 | Windows write-permission handling | — | `src/lib/config.ts:261` — `if (platform === 'win32') { fs.writeFileSync(path, data, {}); }` (mode skipped) | ts-only | D-017(6) | py's `write_config_data` (`core/config.py:213`) has no Windows branch — `mkstemp`'s POSIX-style mode is applied unconditionally. |
| F245 | non-fatal warning for a loosely-permissioned on-disk config file | — | `src/lib/config.ts:135` — `if ((mode & 0o077) !== 0) { warn(...) }` | ts-only | D-017(6) | Only meaningful because ts's config file can carry a token (see F239); py never checks discovered-file permissions. |
| F246 | secret masking for display | `src/py_launch_blueprint/cli/commands/config.py:212` — `def _mask(secret: str) -> str:` (`"****" + secret[-4:]`) | `src/lib/config.ts:233` — `export function redactToken(token: string): string` (`***` + last 4) | same | — | Same reveal-last-4 masking shape for showing the resolved token. |
| F247 | XDG override mechanism (env var must be set, non-empty, absolute) | `src/py_launch_blueprint/core/paths.py:65` — `def _xdg_override(env_var: str) -> Path &#124; None:` | `src/lib/xdg-paths.ts:22` — `if (xdgConfigHome !== undefined && xdgConfigHome !== '') {` | same | D-017(3) | py additionally requires the override to be an absolute path; ts's check does not test absoluteness. |
| F248 | config directory default on Windows | `src/py_launch_blueprint/core/paths.py:104` — `default = _windows_roaming() if _WINDOWS else _home() / ".config"` (`%APPDATA%\plbp`) | `src/lib/xdg-paths.ts:26` — `return join(homedir(), '.config', TOOL_DIR_NAME);` (`%USERPROFILE%\.config\ts-projects`, same on every OS) | different | D-017(3) | py (ADR 0011) uses platform-native `%APPDATA%`; ts deliberately keeps the POSIX `~/.config` shape on Windows too. |
| F249 | separate XDG-style data/state/cache directories beyond config | `src/py_launch_blueprint/core/paths.py:130` — `def data_home()`, `def state_home()`, `def cache_home()` | — | py-only | — | ts resolves only a config directory (`src/lib/xdg-paths.ts:21`); no data/state/cache dirs exist because there is no log file or local database to place in them. |
| F250 | console log format auto-selects JSON vs. human text from TTY-ness | `src/py_launch_blueprint/core/logging.py:120` — `def _resolve_format(fmt: LogFormat) -> LogFormat:` (`sys.stderr.isatty()`) | — | py-only | D-018(1) | ts's `createLogger` (`src/lib/logger.ts:58`) always writes plain leveled text lines; there is no JSON console mode. |
| F251 | structured (key/value) logging pipeline | `src/py_launch_blueprint/core/logging.py:154` — `def _shared_processors() -> list[Processor]:` (structlog processor chain) | — | py-only | D-018(1) | ts's logger (`src/lib/logger.ts:47`) is a hand-rolled leveled line writer with no structured-event/key-value model. |
| F252 | key-based secret redaction in log output | `src/py_launch_blueprint/core/logging.py:93` — `SENSITIVE_KEY_PARTS: tuple[str, ...] = ("token", "password", ...)` applied by `_redact_sensitive` (`logging.py:143`) | — | py-only | — | No redaction step exists in ts's logger; it only ever writes the message string passed to it. |
| F253 | trace/span correlation in logs (OpenTelemetry) | `src/py_launch_blueprint/core/logging.py:106` — `_otel_trace: Any = importlib.import_module("opentelemetry.trace")` (soft-imported, optional extra) | — | py-only | — | No tracing integration in ts's logger. |
| — | verbosity-to-level ladder consulting a configured/env log level ahead of `-v`/`-q` | `src/py_launch_blueprint/cli/context.py:200` — `def _resolve_console_level(...)`: `--log-level` (flag/env) `>` `-q`/`-v` `>` config `>` default | `src/lib/logger.ts:29` — `export function resolveLevel(flags: VerbosityFlags): LogLevel {}` consults only `debug`/`quiet`/`verbose` flags | different | D-018(3) | py's console level has two upstream overrides (an explicit flag/env and a config-file default) that ts has no equivalent for; the flag-count-to-level mapping itself is covered separately in `cli-framework-ux.md`; see F274 |
| F254 | explicit console log-level flag/env (`--log-level`/`PLBP_LOG_LEVEL`) | `src/py_launch_blueprint/cli/options.py:85` — `"--log-level", ... envvar="PLBP_LOG_LEVEL",` | — | py-only | D-018(3) | ts has no way to set an exact level directly; only the relative `-v`/`-q`/`--debug` flags exist. |
| F255 | `[logging]` table in the config file (level/file/file_level/format defaults) | `src/py_launch_blueprint/core/settings.py:49` — `class LoggingSettings(BaseModel):` (`level`, `file`, `file_level`, `format` fields) | — | py-only | D-017(1) | ts's config schema (`src/lib/config.ts:33`) carries only `token`/`workspace`/`limit`; no logging settings live in the file. |
| F256 | optional rotating file log sink | `src/py_launch_blueprint/core/logging.py:241` — `file_handler = RotatingFileHandler(file_path, maxBytes=ROTATE_MAX_BYTES, backupCount=ROTATE_BACKUP_COUNT, ...)` | — | py-only | D-018(1) | ts's logger writes only to the injected stderr writer (`src/lib/logger.ts:58`); no file sink exists at all. |
| F257 | file log sink rotation policy (size + backup count) | `src/py_launch_blueprint/core/logging.py:82` — `ROTATE_MAX_BYTES = 10 * 1024 * 1024` / `ROTATE_BACKUP_COUNT = 5` | — | py-only | D-018(1) | Depends on the file-sink row above; no ts equivalent. |
| F258 | file sink enable flag/env (`--log-file`/`PLBP_LOG_FILE`, default XDG state path) | `src/py_launch_blueprint/cli/options.py:93` — `"--log-file", ... envvar="PLBP_LOG_FILE",` | — | py-only | D-018(1) | — |
| F259 | file sink path precedence (flag/env > config `logging.file` > off) | `src/py_launch_blueprint/cli/context.py:212` — `def _resolve_log_file(...)` | — | py-only | D-018(1) | — |
| F260 | file sink format override via env (`PLBP_LOG_FORMAT`, validated) | `src/py_launch_blueprint/cli/context.py:233` — `def _resolve_log_format(config_format: str) -> str:` | — | py-only | — | — |
| F261 | file sink independent level from the console sink (dual-sink floor) | `src/py_launch_blueprint/core/logging.py:259` — `floor = min(level, file_level)` then `root.setLevel(floor)` (`logging.py:262`) | — | py-only | D-018(1) | Depends on the file-sink row above; no ts equivalent since there is only one sink. |
| F262 | logging reconfiguration only tears down handlers it owns (idempotent, host-safe) | `src/py_launch_blueprint/core/logging.py:226` — `for handler in root.handlers[:]: if getattr(handler, _OWNED_FLAG, False): ...` | — | py-only | — | ts's `createLogger` (`src/lib/logger.ts:58`) returns a fresh closure per call with no global logging registry to protect. |
| F263 | one shared logging pipeline expressed as per-front-end policy profiles | `src/py_launch_blueprint/web/logging.py:20` — web profile docstring: "Same engine as the CLI (`core/logging.py`), different policy" | — | py-only | — | Depends on cross-area `web-extra-surface`: this pattern exists because py ships a second (web) front-end sharing the pipeline; ts has only the CLI front-end. |
| — | unexpected errors persisted to a best-effort crash log file | `src/py_launch_blueprint/cli/options.py:143` — `crash_path = paths.state_file("crash")` then appended to on `except OSError:` swallow (`options.py:150`) | — | py-only | — | No crash-log file exists in ts; unexpected errors surface only via the stderr logger/stack trace, per `src/router.ts` (see `cli-framework-ux.md` for the exit-code side of this); see F302 |

## Language-bound tools
- `pydantic` (py) — config schema definition and validation (`Settings`/`OutputSettings`/`LoggingSettings`)
- `tomllib` (py) — stdlib TOML parsing
- `tomli_w` (py) — TOML serialization for config writes
- `structlog` (py) — structured logging pipeline: processors, renderers, redaction, stdlib integration
- `opentelemetry` (py) — optional trace/span correlation extra consumed by the logging pipeline
- `zod` (ts) — config file schema validation (`configFileSchema`)
- `smol-toml` (ts) — TOML parsing and serialization

## Cross-area parameters
- `error-taxonomy-exit-codes` — the crash-log write and the config/auth error classes feed each language's exit-code mapping, decided in `cli-framework-ux.md`.
- `web-extra-surface` — the "one pipeline, two profiles" pattern exists only because py carries an optional web front-end sharing `core/logging.py`; whether ts carries an equivalent web surface is decided outside this area.

## Files read
- py: `src/py_launch_blueprint/core/config.py`
- py: `src/py_launch_blueprint/core/logging.py`
- py: `src/py_launch_blueprint/core/paths.py`
- py: `src/py_launch_blueprint/core/settings.py`
- py: `src/py_launch_blueprint/core/errors.py` — no feature: exit-code/error-code taxonomy belongs to `cli-framework-ux.md`; only used here for the crash-log cross-reference
- py: `src/py_launch_blueprint/cli/context.py`
- py: `src/py_launch_blueprint/cli/options.py`
- py: `src/py_launch_blueprint/cli/commands/config.py`
- py: `src/py_launch_blueprint/web/logging.py`
- py: `docs/adr/0002-no-secrets-in-config-file.md`
- py: `docs/adr/0004-config-errors-degrade-to-warnings.md`
- py: `docs/adr/0006-stable-error-codes-hints-crash-log.md` — no feature: read for crash-log context; the error-code/exit-code contract itself belongs to `cli-framework-ux.md`
- py: `docs/adr/0011-windows-native-paths-xdg-overrides.md`
- py: `docs/adr/0015-one-logging-pipeline-two-profiles.md`
- ts: `src/lib/config.ts`
- ts: `src/lib/xdg-paths.ts`
- ts: `src/lib/logger.ts`
- ts: `src/lib/colors.ts` — no feature: color enablement/rendering belongs to `cli-framework-ux.md`, not config/env/logging
- ts: `src/lib/errors.ts` — no feature: exit-code taxonomy belongs to `cli-framework-ux.md`
- ts: `src/router.ts` — no feature: global-option wiring (`-v`/`-q`/`--debug`/`--no-color`) and the machine-mode JSON error envelope belong to `cli-framework-ux.md`; consulted here only to confirm no config-file-sourced logging knobs exist
- ts: `src/cli.ts` — no feature: signal/EPIPE handling belongs to `cli-framework-ux.md`; confirmed no crash-log equivalent
- ts: `tests/config.test.ts`
- ts: `docs/reference/configuration-files.md`
- ts: `docs/tasks/debugging-configuration.md`
- ts: `docs/port/TS_PORT_DECISIONS.md`
