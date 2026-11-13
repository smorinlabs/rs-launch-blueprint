# Local research CLI contract

The new offline research commands use the organization's CLI Design Standard
1.4.14 as a design reference. Scope is the repository's internal runner and
validator. This record does not claim conformance for the external Codex,
Claude or Doxa CLIs, or retroactively change the existing Bash interfaces.

`scripts/research_cli.py` supplies the shared argument and error behavior.
Configuration is explicit: `--config FILE` reads a JSON object with an optional
`root` directory, relative to that file. An explicit root argument takes
precedence. The commands perform no implicit credential or config discovery.

| Surface | Contract |
|---|---|
| Help and version | Empty top-level invocation, `help`, and `-h`/`--help` print help and exit 0; `-V`/`--version` prints version |
| Command groups | Runner uses `run`, `queue`, and `publication` groups; a group missing its action is usage error 2 |
| Machine results | `--json` and `-o json` are equivalent; success emits one JSON object on stdout |
| Errors | Usage errors exit 2; ordinary failures exit 1; JSON errors emit one `error` object on stderr with stdout empty; interruption exits 130 |
| Diagnostics | Repeat `-v`/`--verbose`; `-q`/`--quiet` suppresses informational diagnostics, never requested results; `--debug` overrides quiet |
| Parsing | Long-option abbreviation is disabled; long options accept separate or `=` values; short core flags retain their standard meanings |
| Authorization | Commands record local state and never submit paid work; no prompt or flag creates paid authorization |
| Publication | Expected content hashes and safe paths are required; there is no force flag that bypasses a stale-input or publication guard |

The legacy Bash checker and answer wrapper retain their positional forms and
`FAIL:` diagnostics on stdout for existing callers. New automation should use
the Python JSON interface. Human runner results remain formatted records rather
than a table. These compatibility choices are documented differences from a
general-purpose public CLI, not evidence of a full standard-conformance audit.

Validation CLI modes `tree`, `topic`, and `check-tree` hold the publication
lock through their complete read and result. `check-tree` includes the original
Bash structural checks and supports `--require-owner-review`; the public Bash
entrypoint invokes this mode. Import APIs remain lock-neutral for use within a
caller-owned publication transaction. Lock directories are temporary metadata.
