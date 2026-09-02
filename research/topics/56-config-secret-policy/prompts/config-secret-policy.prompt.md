# Deep-research prompt — Config secret policy (R56, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint`'s config file is permitted to carry the auth token as its lowest-precedence source (ts's shape) or is forbidden from ever carrying it (py's ADR-0002 rule), and — if permitted — the resulting token-resolution precedence chain and the non-fatal warning for a loosely-permissioned config file that carrying a secret in it implies. Item kind: `bundle`. Value test: if this answer is wrong, whether the config schema (R53) has a `token` field at all, the token-resolution function's precedence chain (two-tier flag>env versus three-tier flag>env>file), and whether a file-permission check exists all get rewritten.

## Context
- Inherited pattern (spec §2): the repos take opposite positions by design. py's ADR 0002 forbids reading a token from any config layer — a `token` key in the file is silently ignored — so its precedence chain has only two tiers (flag, then env). ts allows the config file as the lowest-precedence token source, giving it a three-tier chain (flag > env > file), and because a token can now live on disk, ts also warns (non-fatally) when that file's permissions are looser than expected. Evidence: F239 py `src/py_launch_blueprint/core/config.py:147` — `settings, value_warnings = settings_from_layers(layers)` merges only `[output]`/`[logging]`; a `token` key is never read from any layer; ts `src/lib/config.ts:177` — `else if (fileValues.token !== undefined ...) { token = fileValues.token; tokenSource = 'file'; }`. F240 py `src/py_launch_blueprint/core/config.py:169` — flag then `os.getenv(TOKEN_ENV_VAR)` (only two tiers); ts `src/lib/config.ts:171` — flag > env > file (three tiers). F245 py: none (py never checks discovered-file permissions, since it never carries a secret there); ts `src/lib/config.ts:135` — `if ((mode & 0o077) !== 0) { warn(...) }`. Ledger rows F239, F240 (origin `different`) and F245 (origin `ts-only`) (`docs/port/COMMONALITY.md`), all verdict `DIVERGENT`.
- Already decided, do not re-open: the config file is written with restrictive (0600) permissions regardless of whether it carries a secret (F243, `COMMON → REUSE`, inherited as-is); an empty-string env/flag token is treated as unset in both repos (F242, `COMMON → REUSE`); the token env-var name pattern and secret-masking-for-display convention are inherited (F241, F246, `COMMON → REUSE`) — this item decides only whether the *file* may be a token source and, if so, its place in the precedence chain and the associated permission warning. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-017(5) and D-017(6) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — D-017(5) explicitly omits a runtime `.env` secrets tier and keeps the flag > env > TOML-config `token`-key chain, "preserv[ing] the multi-remedy missing-token error with updated remedies"; D-017(6) covers the 0600 write plus the non-fatal loose-permissions warning and documents a Windows caveat (`fs.chmod` can only toggle the read-only bit there) that is out of scope for this item since `target-os-matrix` already excludes Windows.

## Out of scope
- Whether the config file exists at all and how many discovery tiers it has; R54 (`config-discovery-tiers`) owns F230-F234 — this item decides what the file (wherever discovery finds it) may contain, not how it's found.
- Whether an individually invalid config value degrades to a warning or fails the file; R55 (`config-error-tolerance`) owns F235/F236/F238 — this item's `token` field (if any) is subject to whatever tolerance rule R55 sets.
- Which crate performs schema validation on the parsed config, including any `token` field this item adds to that schema; R53 (`config-schema-validation`) owns F228 — this item decides whether the field exists and its precedence, not the validation mechanism.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R56
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R53 (`config-schema-validation`) — if this item concludes the file may carry a token, that field must be added to R53's schema. R54 (`config-discovery-tiers`) — this item's precedence chain composes with however many tiers R54 lands on.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does `rs-launch-blueprint` follow py's ADR-0002 rule (config file may never carry the token; two-tier flag>env precedence) or ts's shape (config file is the lowest-precedence token source; three-tier flag>env>file precedence, plus a non-fatal loose-permissions warning on that file) — and, if the latter, exactly how the permission check and precedence chain are implemented in Rust.
- HIGH: py's ADR-0002 is a security-motivated architectural decision (never persist a bearer token to disk); is there a Rust-specific reason to depart from that stance, or does the presumption-of-reuse default (spec §2) instead favor picking one of the two source behaviors outright rather than inventing a third? State which source behavior this item recommends and why.
- HIGH: If the file-as-token-source shape is adopted, what Rust mechanism performs the file-permission check on POSIX (matching ts's `mode & 0o077` check) — `std::os::unix::fs::PermissionsExt`, or a crate — and how does it degrade cleanly to a no-op on the owner-fixed `target-os-matrix` (`ubuntu-latest, macos-latest`, both POSIX) without needing a Windows branch?
- MEDIUM: How does the chosen precedence chain compose with R54's discovery tiers — does "config file" mean the single resolved/merged config value, or does each discovered layer independently get token-extraction priority?
- MEDIUM: What warning mechanism (see R58/R59's eventual logging pipeline) surfaces the loose-permissions warning, and is it emitted once at config-load time or on every token read?
- LOW: Is there published Rust CLI security guidance (e.g. from RustSec or a CLI style guide) on whether config files should ever be a credential-file source, for a second opinion on the ADR-0002-vs-ts tradeoff?

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
