# excerpt of cli-design-standard.md v1.4.14, git blob f9de0437baece3383e73ca2c5f48b7ab399b51c7
# from /Users/stevemorin/c/cli-standards, read 2026-09-18 UTC
**R4.1 — Standard option tiers. (MUST)**
Standard options are split into three tiers, each with exactly these names and meanings. Every CLI **MUST** implement the **required global core**. Commands that emit formatted result data **MUST** implement the **result-output options**. **Safety/action options** are reserved standard names: when a command supports that concept, it **MUST** use the listed name and meaning, and **SHOULD** keep the option command-local unless it is meaningful globally. Letters not listed here **SHOULD NOT** be reassigned to conflicting meanings.

| Tier | Option | Short | Meaning |
|------|--------|-------|---------|
| Required global core | `--help` | `-h` | Print help for the current command and exit `0`. Also `acme help [command]`. |
| Required global core | `--version` | `-V` | Print version and exit `0`. **`-v` is not version.** |
| Required global core | `--verbose` | `-v` | Increase diagnostic detail (repeatable; see R4.4). |
**R4.6 — Version output format. (SHOULD)**
`--version`/`-V` **SHOULD** print a single line `acme <semver>` (GNU name-and-version style); a build **MAY** append commit/date for pre-release builds. `--version` **MAY** honor `-o json`/`--output json` even when normal result-output options are otherwise command-scoped. If JSON version output is supported, it **SHOULD** emit an object such as `{"version":"1.4.0","commit":"abc123","built":"2026-06-27T12:00:00Z"}`; `version` **MUST** be SemVer without a leading `v`, while `commit` and `built` **MAY** be omitted or `null` when unknown.
✅ `acme 1.4.0`; `acme --version -o json` → `{"version":"1.4.0","commit":"abc123","built":"2026-06-27T12:00:00Z"}` ❌ `Acme CLI — Version Info: v1.4.0 ©2026 …` as the only output

