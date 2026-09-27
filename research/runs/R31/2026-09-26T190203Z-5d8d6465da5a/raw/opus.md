# R31 — standalone-security-analyzer (bundle) — Opus raw report

Engine: Opus seat (`claude-opus-5-5`), Claude Code CLI, run
`research/runs/R31/2026-09-26T190203Z-5d8d6465da5a`, written 2026-09-26. This is an
independent leg: no other engine's report for this run was opened.

Retrieval dates. Every endpoint figure below was retrieved on **2026-09-26 US/Pacific**
(the GitHub calls ran between about 2026-09-26T23:40Z and 2026-09-27T00:17Z UTC).
crates.io figures come from `GET https://crates.io/api/v1/crates/<name>` and
`.../versions`; GitHub figures from `GET https://api.github.com/repos/<o>/<r>` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`; advisory
state from `https://rustsec.org/packages/<name>.html`. Additional `api.github.com`
paths were used on the same host (`/contents/...`, `/readme`, `/license`,
`/releases/latest`, `/issues`, `/issues/<n>/comments`, `/search/code`); each is listed
under `### Sources`.

Source-repository citations are read at the programme pins: Python
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` (written `py@b08bccfb`) and TypeScript
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` (written `ts@cb1cbcb2`), read from the local
clones with `git show <pin>:<path>`.

Local toolchain for every executed check: `ast-grep 0.45.3` (Homebrew,
`/opt/homebrew/bin/ast-grep`), `rustc 1.98.1 (48a229cea 2026-09-01)`, macOS 26
(Darwin 25.4.0) on an Apple M4 Pro with 14 cores. No executed check wrote a file into
the repository; fixtures were passed on stdin or read from the local Cargo registry.

Terms used throughout:

- **SAST** (static application security testing): analysis of first-party source code
  for insecure patterns, without running it.
- **SCA** (software composition analysis): checking the dependency graph against
  vulnerability advisories. `cargo-audit` and `cargo-deny` are SCA tools.
- **bandit-class scanner**: a separate tool, distinct from the general linter, that
  matches security rules against the project's own source — py's `bandit`.
- **rule set**: the YAML rule files the scanner evaluates. For ast-grep, a rule is one
  YAML document with an `id`, a `language`, a `rule` pattern and optional `ignores`.

### Landscape

**Category this item decides.** Whether the template carries a first-party SAST tool
of its own — a scanner separate from clippy (R28, F096) and separate from dependency
scanning (R13, F042/F048/F049) — and, if so, its hook tier (F115) and its exclude
configuration.

**Evidence the category is real in both sources.**

- py runs `bandit` in CI: `py@b08bccfb:.github/workflows/lint.yml:114` —
  `run: uv run --no-sync bandit -r src/py_launch_blueprint/ -c pyproject.toml`. The
  comment on lines 112–113 records a real failure: after the src-layout move "the old
  flat `py_launch_blueprint/` path no longer exists, so the scan was silently covering
  nothing." That silent-empty-scan failure shapes acceptance criterion A3 below.
- py config: `py@b08bccfb:pyproject.toml:267` — `[tool.bandit]`,
  `exclude_dirs = ["tests", ".venv", "build", "dist"]`, `skips = []` with the comment
  "No global skips; add with rationale only".
- py hook tier: `py@b08bccfb:lefthook.yml:160-161` — a `bandit` job at pre-push; the
  comment on lines 157–158 gives the reason: "pre-push, not pre-commit, since full-tree
  scan is too slow per commit".
- ts has no scanner. `ts@cb1cbcb2:docs/port/TS_PORT_DECISIONS.md:131` records D-014(5)
  as "Layered: oxlint built-in security-adjacent rules (no-eval etc.) + CodeQL workflow
  carried by the CI topic + eslint-plugin-security **deferred until Oxlint JS plugins
  leave alpha**", and line 139 gives the reason: "Neither Oxlint (no security plugin
  among its 16 built-ins) nor Biome offers a node-security/bandit equivalent". The ts
  gap is therefore a tooling-availability deferral with a stated trigger, not a
  principled rejection of the capability.

**Three-bin map of the Rust field.**

| Bin | Candidate | What it actually analyses | Bandit-class? |
|---|---|---|---|
| Built-in / first-party | `rustc` lints (`unsafe_code`, R06) | Compiler lint levels | No — one lint, owned by R06 |
| Built-in / first-party | clippy (`rust-lang/rust-clippy`, 13,536★) | General lints, some security-adjacent | No — R28 owns it (F096) |
| Built-in / first-party | Miri, `cargo-careful` 0.4.10 | Undefined behaviour at *run time*, nightly | No — dynamic, not SAST |
| Established standard | CodeQL for Rust (`github/codeql`, 10,128★) | Dataflow and taint SAST, 19 Rust security queries at bundle 2.26.4 | Yes, and stronger than bandit — already inherited (F027, R16) |
| Established standard | Semgrep (`semgrep/semgrep`, 16,774★, LGPL-2.1) | Pattern and dataflow SAST; Rust "Generally available" with "40+ Pro rules" | Yes — but only 10 community Rust rules |
| Established standard | `cargo-audit` 0.22.2, `cargo-deny` 0.20.2 | Dependency graph vs RustSec advisories | No — SCA, owned by R13 |
| Established standard | `cargo-geiger` 0.13.0 | Counts `unsafe` in the dependency tree | No — an inventory, not a rule scanner |
| Up-and-comer | ast-grep (`ast-grep/ast-grep`, 16,052★, MIT) | Tree-sitter structural pattern rules with YAML rule files and built-in rule tests | Yes, as an engine — the rules are the template's |
| Up-and-comer | opengrep (`opengrep/opengrep`, 3,118★, LGPL-2.1) | Community fork of Semgrep CE | Yes, as an engine — its rules repository is archived |
| Up-and-comer | Dylint (`trailofbits/dylint`, 672★) | Type-aware custom lints as compiler plugins | Could host security lints; requires a nightly toolchain |
| Research, inactive | Rudra (archived 2026-04), MIRAI (archived; last push 2024-08-22), lockbud (BSD-3, not on crates.io) | Memory-safety and concurrency bug finding | No — research analysers, not maintained products |

**Direct answer to the HIGH landscape question.** No maintained, dedicated,
bandit-style source scanner exists for Rust in the way `bandit` exists for Python.
Rust's security tooling concentrates on two other places: dependency scanning (RustSec,
`cargo-audit`, `cargo-deny`) and language-level prevention (the type system, `unsafe`
policy, clippy). The closest real analogues are general multi-language SAST engines
that support Rust — CodeQL, Semgrep and opengrep — and rule engines such as ast-grep
on which a small security rule set can be written. The largest *free community*
security rule set for Rust found in this survey is Semgrep's 10 rules; the
ast-grep community set (`coderabbitai/ast-grep-essentials`, 8 Rust security rules) was
archived on 2026-06-03.

**Authoritative sources used, and why each counts.**

| Source | Why it is authoritative for this question |
|---|---|
| `rust-lang/rust-clippy` repository metadata | The Rust project's own linter; defines the baseline this item must go beyond |
| RustSec (`rustsec.org`, `rustsec/rustsec`) | The Rust Secure Code working group's advisory database; the canonical Rust advisory source |
| `github/codeql` and R16's executed `codeql resolve queries` log | The vendor's own query packs, resolved by an executed command in this programme |
| `semgrep/semgrep-docs` `docs/supported-languages.mdx` | The vendor's own statement of Rust support maturity |
| `semgrep/semgrep-rules` `rust/lang/security/` listing and `LICENSE` | The vendor's own community rule set and its licence |
| `trailofbits/dylint` README and `examples/general/rust-toolchain.toml` | The maintainer's own documentation of toolchain requirements |
| `ast-grep/ast-grep` Cargo manifests, releases and workflows | The maintainer's own build, feature and platform declarations |
| crates.io API | The registry of record for versions, licences, `rust-version` and downloads |

The annual Rust survey was not consulted: it is not among this topic's named
endpoints, and it does not ask about SAST tooling as far as this leg knows. This is
recorded as a gap, not used as evidence.

**Practice evidence — what well-regarded Rust projects do.**

- ast-grep is adopted by large Rust projects, for *project conventions*, not security.
  Found by `GET /search/code?q=filename:sgconfig.yml+ruleDirs` (856 hits) and read
  from each project's files:
  - `nushell/nushell` (40,580★): root `sgconfig.yml` with `ruleDirs: [ast-grep/rules]`
    and `testConfigs`; 8 rules, all style (for example `if-matches.yml`,
    `span-unknown.yml`).
  - `qdrant/qdrant` (34,838★): `tools/ast-grep/sgconfig.yml`; 3 rules
    (`no-allow-dead-code.yml`, `no-default-batch-methods.yml`,
    `no-raw-requests-without-headers.yml`). Its `.github/workflows/rust-lint.yml:49-62`
    runs an `ast-grep` job on `ubuntu-latest` with
    `sg test --config tools/ast-grep/sgconfig.yml --skip-snapshot-tests` and
    `sg scan --config tools/ast-grep/sgconfig.yml`, beside its clippy job.
  - `swc-project/swc` (34,207★): `sgconfig.yml` with `ruleDirs: [rules]`; 1 rule.
  - `TabbyML/tabby` (33,894★): 6 architecture rules; `.github/workflows/ast-grep-lint.yml`
    runs `ast-grep/action@v1.4` on `ubuntu-latest`.
  - `DataDog/lading` (100★; included for its config shape, not its standing):
    `sgconfig.yml` uses `globalRules.ignores` for `**/fuzz/target/**` and `**/target/**`.
  These projects are well regarded by star count (33,894–40,580) and by being
  production systems (a shell, a vector database, a compiler, a code assistant). None
  of their rule files is a security rule; that is an evidence gap for the security use.
- Security scanners in mainstream Rust CI are rare. A rate-limited spot check with
  `GET /search/code?q=<tool>+repo:<o>/<r>+path:.github` found `semgrep=0`, `codeql=0`
  and `ast-grep=0` in `astral-sh/ruff` (49,805★) and `zed-industries/zed` (90,933★);
  `semgrep=0` and `codeql=0` in `BurntSushi/ripgrep` (68,630★); `cargo-deny` hits (2)
  in both `astral-sh/ruff` and `astral-sh/uv` (90,200★). Several further queries
  returned HTTP 403 (secondary rate limit) and are not counted. GitHub code search
  does not index every file, so a zero is weak evidence of absence.

**Fit for this template, in one paragraph.** The template is a CLI, a library and a
web service. The web service is where bandit's surviving classes matter most (SQL
text, TLS client configuration, outbound requests); the CLI adds process spawning and
temporary files; the library adds little beyond `unsafe`, which R06 already governs.
The template already inherits CodeQL for Rust (F027, configured by R16), but only for
public repositories: the ledger records that "public-only is a selected policy, not an
availability check" (`docs/port/COMMONALITY.md:33`). A private repository created from
the template therefore runs no SAST at all unless it has GitHub Code Security enabled.

### Principles and implementation

**Shared requirement.**
First-party source is checked for known-insecure patterns by a tool separate from the
general linter. The check runs before code leaves the developer's machine, runs in CI,
and does not depend on the repository's hosting plan or visibility.

- *Source:* py `bandit` (CI at `lint.yml:114`, pre-push at `lefthook.yml:160-161`),
  plus the owner direction of 2026-09-04 (`docs/port/OWNER-REVIEW.md:259`): "Make sure
  there's a security scanner … Same thing with Rust".
- *Agreement level:* capability and policy, not tool. The tool, the rule contents
  and the tier may vary by ecosystem. What must agree is that a separate scanner
  exists, that it fails the build on a finding, that its exclusions are declared in
  a file, and that it runs locally and in CI.

**How bandit's rule classes survive in Rust.** This is the answer to the second HIGH
question. Bandit test IDs are from bandit's plugin naming; "CodeQL" names the Rust
query IDs resolved at bundle 2.26.4 in R16's executed
`research/topics/16-codeql-config-customization/evidence/2026-09-05T163018Z-61c8f49b581d-resolve-queries.log`.

| Bandit class (IDs) | Rust status | CodeQL for Rust (inherited, public repos) | Semgrep community rule | Proposed ast-grep rule |
|---|---|---|---|---|
| `eval`/`exec` (B102, B307) | Eliminated — no runtime code evaluation | — | — | — |
| Unsafe deserialisation (B301, B403, B506) | Eliminated by default — serde builds typed values only | — | — | — |
| `assert` stripped in optimised builds (B101) | Different — `assert!` stays in release; only `debug_assert!` is removed | — | — | — |
| Shell invocation (B602, B605) | Survives — `Command::new("sh").arg("-c")` | `rust/command-line-injection` exists at `codeql-cli/v2.27.0`, not at the 2.26.4 pin (R16 `DECISION.md:100`) | — | `rs-shell-invocation` |
| SQL built from strings (B608) | Survives — `sqlx::query(&format!(..))` | `rust/sql-injection` | — | `rs-sql-format` |
| Weak hash (B303, B324) | Survives — `md5`, `sha1` crates | `rust/weak-sensitive-data-hashing`, `BrokenCryptoAlgorithm.ql` | `insecure-hashes` | `rs-weak-hash` |
| TLS verification off (B501) | Survives — `danger_accept_invalid_certs(true)` | `rust/disabled-certificate-check` | `reqwest-accept-invalid`, `rustls-dangerous`, `ssl-verify-none` | `rs-tls-verification-disabled` |
| Predictable temp file (B108) | Survives — `std::env::temp_dir().join("x")` | — | `temp-dir` | `rs-predictable-temp` |
| Hard-coded passwords (B105–B107) | Survives | `rust/hard-coded-cryptographic-value` (keys, not passwords) | — | None — secrets belong to R17/R39 |
| Bind all interfaces (B104) | Survives for the web service | — | — | Candidate, not executed |

Reading of the table. Rust eliminates two bandit classes outright (five bandit IDs:
B102, B307, B301, B403, B506), and changes the meaning of a third (`assert`, B101).
Six classes survive: shell invocation, SQL strings, weak hashes, TLS verification,
predictable temp files and hard-coded secrets, plus the web-service bind-all class.
At the template's pinned bundle 2.26.4, CodeQL covers three of the first five with
taint tracking (SQL, weak hashes, TLS verification), which is stronger than bandit's
own single-file pattern matching. It covers a fourth, shell invocation, only after a
pin bump to 2.27.0 or later. Temp files are covered by no CodeQL query, and
hard-coded secrets only partly (keys, not passwords). So Rust's case for a *second* scanner
is weaker than py's on coverage. It is stronger than ts's on availability: ts had no
tool to adopt (D-014(5)), while Rust has a fast, native rule engine. The deciding
argument is F027's public-only policy. Without a local scanner, a private instance of
the template has no SAST at all.

**Architectural alternatives compared before choosing a tool.**

| # | Alternative | Local tier | Runs on private repos free | Rust rules available | Stable toolchain | Verdict |
|---|---|---|---|---|---|---|
| Alt-0 | No separate scanner; rely on clippy + CodeQL + R13 SCA; document the gap (ts's path) | No | No SAST | CodeQL's 19 | Yes | Rejected — fails the owner direction and leaves private instances without SAST |
| Alt-1 | Structural pattern engine with template-owned, self-tested rules (ast-grep) | Yes — pre-commit speed | Yes | Template writes 5 | Yes | **Selected** |
| Alt-2 | Semgrep CE or opengrep with registry rules | Yes — pre-push | Yes | 10 community rules; Pro rules need an account | Yes, but a Python or OCaml binary | Runner-up |
| Alt-3 | Type-aware compiler-plugin lints (Dylint) | Yes — slow, compiles | Yes | Template writes them in Rust | No — the libraries pin `nightly-2026-08-20` with `rustc-dev` | Excluded by gate |
| Alt-4 | Run the CodeQL CLI locally in a hook | Minutes per run, not measured here | Not established | 19 | Yes | Rejected for the hook tier; kept in CI where R16 already put it |
| Alt-5 | `unsafe` inventory (`cargo-geiger`) | Yes | Yes | Not rule-based | Yes | Out of category — an `unsafe` count, closer to R06/R13 |

**Design selected.** Two members.

1. **M1 — ast-grep with a template-owned security rule set** (F114). A committed
   `sgconfig.yml` points at `rules/security/`, one YAML file per rule. Each rule has a
   test file of `valid:` and `invalid:` snippets that `ast-grep test` checks. This is
   the reference pattern `qdrant/qdrant` runs in CI.
2. **M2 — placement and exclusion pattern** (F115 and the LOW question). The scan is
   a lefthook **pre-commit** job on staged `*.rs` files, a `just security` recipe for
   the full tree, and a step of R11's `hygiene` job. The recipe fails when the scan
   covered zero files. Test, bench and fuzz directories are excluded by the same globs
   R16 gave CodeQL.

CodeQL is not a member: R16 and F027 own it. It remains the dataflow complement for
public repositories.

**How the design preserves each principle.**

- *Separate from the linter:* the scanner runs from its own config and rule files.
  It does not re-decide clippy's lint selection (R28).
- *Fails on a finding:* every rule is `severity: error`; `ast-grep scan` exits 1 on an
  error-level match (executed, below).
- *Exclusions declared in a file:* rule-level `ignores:` globs, the Rust analogue of
  `[tool.bandit] exclude_dirs`.
- *Local and CI:* one recipe feeds both the hook and the CI step.
- *Independent of hosting plan:* ast-grep is MIT-licensed and runs offline.
- *Where Rust needs a different design:* py puts the scan at pre-push because a
  full-tree bandit scan is slow. ast-grep scanned tokio's 555 files in 0.09 s wall, so
  pre-commit is affordable and the py reason does not transfer.

**Acceptance criteria (observable).**

| ID | Criterion | Check | Status |
|---|---|---|---|
| A1 | Each rule flags its insecure form and passes its safe form | stdin fixture: 6 insecure lines flagged, 0 of 5 safe lines flagged | **Executed, met** |
| A2 | A finding fails the command | `--error` on the fixture → exit 1; a clean snippet → exit 0 | **Executed, met** |
| A3 | A scan that covers zero files fails | `--inspect summary` prints `scannedFileCount=0` for a missing path and a Rust-free path, and `555` for tokio; ast-grep's own exit is **0** for a missing path | **Executed** for the signal; the failing guard is proposed |
| A4 | Tests, benches and fuzz targets are excluded | tokio: 7 shell-invocation hits, all under `tests/`; with `ignores: ["**/tests/**", ...]` → 0; the exclusion also applies to an explicitly named staged file | **Executed, met** |
| A5 | Fast enough for pre-commit on a template-sized tree | tokio 1.53.1 (555 files, 139,608 lines): 0.09 s wall | **Executed, met** |
| A6 | Rules are self-tested | `ast-grep test` over `rules/security/` test files | **Proposed** — no rule-test files were written, because this leg writes one file |
| A7 | Runs on `ubuntu-latest` and `macos-latest` | macOS executed locally; Linux prebuilt `app-x86_64-unknown-linux-gnu.zip` and `app-aarch64-unknown-linux-gnu.zip` exist for 0.45.3; qdrant runs it on `ubuntu-latest` | macOS executed; Linux by release asset and adopter, not executed here |

**Minimal realistic example (proposed files).**

```yaml
# sgconfig.yml
ruleDirs:
  - rules/security
testConfigs:
  - testDir: rules/security-tests
```

```yaml
# rules/security/rs-tls-verification-disabled.yml
id: rs-tls-verification-disabled
language: rust
severity: error
message: TLS certificate or hostname verification is disabled (bandit B501 analogue)
ignores:
  - "**/tests/**"
  - "**/benches/**"
  - "**/fuzz/**"
rule:
  any:
    - pattern: $B.danger_accept_invalid_certs(true)
    - pattern: $B.danger_accept_invalid_hostnames(true)
```

```yaml
# rules/security-tests/rs-tls-verification-disabled-test.yml
id: rs-tls-verification-disabled
valid:
  - reqwest::Client::builder().danger_accept_invalid_certs(false).build()
invalid:
  - reqwest::Client::builder().danger_accept_invalid_certs(true).build()
```

The other four rules have the same shape. Their `rule:` bodies are the ones executed
below.

**Executed check 1 — rule behaviour on a fixture passed on stdin.** Working directory
`/tmp`; nothing written. The five inline rules were `rs-shell-invocation`
(`Command::new($SH)` with `$SH` matching `^"(sh|bash|zsh|cmd|cmd\.exe|powershell)"$`),
`rs-tls-verification-disabled`, `rs-weak-hash` (`md5::compute($$$)`, `Md5::new()`,
`Sha1::new()`), `rs-sql-format` (`$Q(&format!($$$))` with `$Q` matching
`(^|::)(query|query_as|query_scalar|execute)$`) and `rs-predictable-temp`
(`std::env::temp_dir()`). The fixture had a `bad` function with 6 insecure lines and a
`good` function with 5 safe counterparts: `Command::new("git")`,
`danger_accept_invalid_certs(false)`, `Sha256::new()`, a bound `sqlx::query("… $1")`
and `tempfile::NamedTempFile::new()`.

```text
$ print -r -- "$CODE" | ast-grep scan --inline-rules "$RULES" --stdin --json=compact
rs-shell-invocation line 3
rs-sql-format line 7
rs-tls-verification-disabled line 4
rs-weak-hash line 5
rs-weak-hash line 6
rs-predictable-temp line 8
total 6
$ ... --stdin --error            -> exit_with_error_flag=1
$ fn main() { println!("ok"); }  -> exit_clean=0
```

**Executed check 2 — performance.** Workload: all 5 rules, JSON output, default
thread count, warm file cache, one run each (no repetition, so no variance figure).

| Workload | Files | Wall | User CPU | Matches |
|---|---|---|---|---|
| `tokio-1.53.1` crate source | 555 `.rs` files, 139,608 lines | 0.09 s | 0.59 s | 7 (all in `tests/`) |
| Entire local Cargo registry (`~/.cargo/registry/src/index.crates.io-*`) | 31,616 `.rs` files | 11.71 s | 84.86 s | 73 (44 shell, 13 temp, 8 TLS, 7 hash, 1 SQL) |

The template will be far smaller than tokio, so a staged-file pre-commit run finishes
well under one second on this hardware. The registry figure is an upper bound for a
very large monorepo, not a template workload. The 73 registry matches were not triaged
for false positives; only tokio's 7 were read, and all 7 are process tests spawning
`sh`, `bash` or `cmd`.

**Executed check 3 — exclusions and the zero-file signal.**

```text
tokio, rs-shell-invocation without ignores ........ 7 matches
tokio, same rule with ignores: ["**/tests/**", "**/benches/**", "**/fuzz/**"] .. 0
explicit path tests/process_smoke.rs, with ignores ... 0; without ignores ... 2
ast-grep scan ... /nonexistent/path  -> "ERROR: ... No such file or directory", exit 0
--inspect summary: docs/port -> scannedFileCount=0; /nonexistent -> 0; tokio -> 555
```

The exit-0-on-missing-path result is the same silent-empty-scan failure py's
`lint.yml:112-113` comment records for bandit. The recipe must therefore fail on
`scannedFileCount=0`, which is criterion A3.

**Reference implementation.** `qdrant/qdrant` is the maintained reference for the
mechanism: `tools/ast-grep/sgconfig.yml`, rule tests, and a CI job running
`sg test` then `sg scan`. No surveyed Rust project uses ast-grep for *security*
rules. That is an evidence gap: the security rule set is template-authored, and its
value rests on the executed fixture above, not on production precedent.

**BASELINE-REVIEW.** None raised against F114/F115. One observation is passed to the
F027 owner without changing it: F027's public-only visibility gate is the reason this
item's local scanner carries real weight. If F027 is widened to private repositories
with Code Security, the scanner's marginal value falls to local speed and offline use.

### Recommendation

Adopt **ast-grep 0.45.3** (crate `ast-grep`, MIT, `rust-version` 1.88.0) as
`rs-launch-blueprint`'s standalone security scanner. It runs a template-owned,
self-tested rule set of five `severity: error` rules in `rules/security/`
(`rs-shell-invocation`, `rs-sql-format`, `rs-weak-hash`,
`rs-tls-verification-disabled`, `rs-predictable-temp`), wired through a root
`sgconfig.yml`. Each rule excludes `**/tests/**`, `**/benches/**` and `**/fuzz/**`,
matching R16's CodeQL `paths-ignore`.

Placement:

- a lefthook **pre-commit** job on staged `*.rs` files, not py's pre-push, because the
  measured cost is sub-second;
- a `just security` recipe that runs `ast-grep test` and then a full-tree
  `ast-grep scan --error`, and fails when the scan covered zero files;
- that recipe as a step of R11's `hygiene` job, because the scan compiles nothing.

CodeQL for Rust (F027, R16) stays the CI dataflow complement for public repositories.
Dependency scanning stays with R13. Clippy's security-adjacent lints stay with R28.

### Members

#### M1 — `ast-grep` scanner with template-owned security rules (F114)

##### Landscape

Candidates for the engine: ast-grep (up-and-comer, Rust-native), Semgrep CE
(established, OCaml core with a Python CLI), opengrep (fork of Semgrep CE), Dylint
(compiler-plugin lints), CodeQL CLI (established, already in CI), and `cargo-geiger`
(an `unsafe` inventory). Only ast-grep, Semgrep and opengrep are rule-driven SAST
engines that run offline at hook speed on stable Rust.

Figures (crates.io and GitHub endpoints, retrieved 2026-09-26):

| Figure | `ast-grep` | `cargo-geiger` | `cargo-dylint` |
|---|---|---|---|
| 90-day downloads (`crate.recent_downloads`) | 38,405 | 53,864 | 173,742 |
| All-time downloads (`crate.downloads`) | 655,796 | 243,823 | 582,851 |
| Last non-yanked release (`num`, `created_at`) | 0.45.3, 2026-08-31T01:40:29Z | 0.13.0, 2025-08-31T08:40:31Z | 6.1.0, 2026-09-23T12:55:04Z |
| Licence (crates.io) | MIT | Apache-2.0 OR MIT | MIT OR Apache-2.0 |
| `rust_version` | 1.88.0 | 1.85 | not declared |
| Stars / archived / `pushed_at` | 16,052 / false / 2026-09-25T15:23:54Z | 1,651 / false / 2026-09-14T02:03:51Z (repo now `geiger-rs/cargo-geiger`; GitHub licence field `none`) | 672 / false / 2026-09-23T12:48:52Z |
| Open issues (`search/issues` `total_count`) | 47 | 46 | 54 |
| Issue responsiveness (10 newest issues) | window 2026-09-12..09-24: 2 answered by maintainer comment (1.34 d, 1.79 d; median 1.56 d); #2944 closed by the maintainer `HerringtonDarkholme` 0.13 d after opening, without a comment; 7 not yet answered | window 2024-05-24..2026-09-16: 6 answered (median 1.88 d); 4 not answered | window 2026-08-13..09-26: 3 answered (median 0.43 d); 7 not answered |
| RustSec advisories | none — `rustsec.org/packages/ast-grep.html` returns 404 (no advisory page); control `tokio.html` returns 200 | none (404) | none (404) |

Non-crate engines, GitHub figures: `semgrep/semgrep` 16,774★, LGPL-2.1, 882 open
issues, 0 of its 10 newest issues (2026-09-14..09-25) answered by a maintainer comment
at retrieval; `opengrep/opengrep` 3,118★, LGPL-2.1, 76 open issues, 3 of 10 newest
answered (median 0.17 d), latest release `v1.30.0` (2026-09-07T11:20:14Z) with
`manylinux`, `musllinux`, `osx` and `windows` assets.

Responsiveness method. For each of the 10 most recently opened issues (pull requests
removed), the response is the first comment whose `author_association` is `OWNER`,
`MEMBER` or `COLLABORATOR`, whose author is not the issue's author, and whose login does
not end in `[bot]`. Two limitations apply:

- An organisation whose members keep their membership private shows them as
  `CONTRIBUTOR`. So "0 of 10 answered" for `semgrep/semgrep` may be an artefact of the
  method rather than silence.
- A maintainer who closes an issue without commenting is not counted. ast-grep #2944 is
  such a case, and was checked by hand.

The ast-grep window is under two weeks, so "7 not yet answered" is partly a recency
effect.

##### Principles and implementation

The principle is capability-level: a separate SAST tool with declared rules, a failing
exit on findings, and declared exclusions. ast-grep realises it through three things:

- a project file, `sgconfig.yml`, that names `ruleDirs` and `testConfigs`;
- one YAML rule per insecure pattern, written as Rust code with metavariables
  (`$B`, `$$$`) plus `constraints` regexes;
- `ast-grep test`, which proves every rule against `valid:` and `invalid:` snippets,
  so a rule that silently stops matching fails CI.

Architecturally, ast-grep is a pattern engine without taint tracking. It reports that
`sqlx::query(&format!(..))` occurs, not that user input reaches it. That is the same
analysis depth as bandit, which also matches per-file syntax. Taint depth is CodeQL's
job in this template. The two are complementary rather than redundant: CodeQL is deep
but CI-only and public-only; ast-grep is shallow but local, instant and independent of
the hosting plan.

##### Dominant choice

No dominant bandit-class scanner exists for Rust. Among Rust projects that run a
structural rule engine in CI, ast-grep is the one found in well-regarded repositories
(nushell, qdrant, swc, tabby), used for conventions. Semgrep dominates multi-language
enterprise SAST, and its Rust support is stated as "Generally available" with
"40+ Pro rules" (`semgrep-docs/docs/supported-languages.mdx:25`). Those Pro rules
require a Semgrep account; the free community set for Rust is 10 rules.

##### Qualified shortlist

1. **ast-grep 0.45.3** — passes every gate (below); fastest measured; native Rust tool;
   rules and rule tests in one config; installable from crates.io under R42's
   `install-tool` recipe.
2. **opengrep** `v1.30.0` (2026-09-07; Linux and macOS assets) — LGPL-2.1 engine, can run the same kind
   of template-owned YAML rules, 3,118★; its rules repository `opengrep/opengrep-rules`
   is archived (6★, last push 2025-11-28). Not a crate, so crate figures are
   inapplicable. Installation needs a release binary, which R42 routes through `ubi`
   and discourages ("a release-only tool must justify itself").
3. **Semgrep CE** — the most capable free engine, with cross-function dataflow in Pro.
   Its 10 community Rust rules
   (`args`, `args-os`, `current-exe`, `insecure-hashes`, `reqwest-accept-invalid`,
   `reqwest-set-sensitive`, `rustls-dangerous`, `ssl-verify-none`, `temp-dir`,
   `unsafe-usage`) are under the "Semgrep Rules License v1.0". The retrieved `LICENSE`
   file contains only that name and the URL `https://semgrep.dev/legal/rules-license`.
   The terms at that URL were not retrieved in this leg, and the name is not an SPDX
   identifier. The conservative choice is therefore not to vendor these rules into
   this repository's own MIT OR Apache-2.0 source. They would have to be fetched from
   the registry at scan time, which makes the hook network-dependent.

##### Excluded by gate

- **Dylint** — fails the "stable Rust only" constraint. Its lint libraries build
  against compiler internals: `examples/general/rust-toolchain.toml` pins
  `channel = "nightly-2026-08-20"` with `components = ["llvm-tools-preview", "rustc-dev"]`,
  and the README (line 198) sets `rustc_private = true`.
- **CodeQL CLI as a local hook** — not excluded by a gate but by tier. It is already
  in CI under F027/R16. Its local install size and run time were not measured in this
  leg, and its licence terms for private code were not retrieved (gap).
- **Rudra** (archived 2026-04-02), **MIRAI** (archived; last push 2024-08-22) —
  archived, so maintenance state `archived`.
- **lockbud** — not published on crates.io (`GET /api/v1/crates/lockbud` → "crate
  `lockbud` does not exist"); a research tool for deadlocks and memory bugs.
- **`cargo-audit` / `cargo-deny`** — not gate failures but out of category: they check
  the dependency graph (SCA), which R13 owns (`research/topics/13-…/prompts`, Out of
  scope: "The standalone AST-based security static analyzer … R31 … owns F114/F115 — a
  code-analysis concern, not a dependency-vulnerability one"). This answers the MEDIUM
  question: they are not a better analogue, because they scan a different thing.
- **`cargo-geiger`** — out of category: it counts `unsafe` in dependencies and matches
  no security rules. First-party `unsafe` is R06's policy.

##### Up-and-comers

- **opengrep** — the community fork created after Semgrep's licensing change; active
  (pushed 2026-09-26T08:18:39Z), but its rule repository is archived, so a Rust user
  would still write rules.
- **ast-grep community rule sets** — `coderabbitai/ast-grep-essentials`
  (Apache-2.0, 149★) shipped 8 Rust security rules (for example
  `reqwest-accept-invalid-rust.yml`, `hardcoded-password-rust.yml`,
  `tokio-postgres-hardcoded-password-rust.yml`), but was archived on
  2026-06-03T18:52:15Z. If a maintained successor appears, the template could consume
  it instead of owning rules.

##### Fit for this template

- *Web service:* the SQL, TLS and weak-hash rules target the crates a Rust web service
  typically uses (`sqlx`, `reqwest`, `rustls`, the `md-5`/`sha1` crates). A bind-all
  (`0.0.0.0`) rule is a reasonable sixth rule but was not executed here.
- *CLI:* the shell and temp-file rules target the CLI.
- *Library:* little bandit-class surface beyond `unsafe` (R06).
- *py precedent:* matches bandit's shape — a config file, declared exclusions and no
  global skips.
- *ts precedent:* closes the gap ts deferred.

The scanner compiles nothing and never touches `target/`, so it fits R11's `hygiene`
job with no cache.

##### Recommendation

`ast-grep` **0.45.3**, installed through R42's generic recipe as
`cargo binstall --locked --no-confirm ast-grep@0.45.3`. Invoke it as the bare
`ast-grep` executable, per R42's `package-manager-invocation`. Do not use the `sg`
alias the crate also installs (`crates/cli/Cargo.toml:23-24`). The reason, a possible
name collision with a Linux `sg` (switch group) command, is from this leg's background
knowledge and was not verified here; `/usr/bin/sg` does not exist on the macOS host.
The bare `ast-grep` name avoids the question either way. Commit
`sgconfig.yml`, the five rules and one test file per rule.

##### Ranked runner-up

**opengrep running template-owned rules**, then **Semgrep CE with registry `p/rust`**.
opengrep ranks second because it can run template-owned rules offline with a real
dataflow engine. It ranks behind ast-grep because it is a release-only binary under
R42's routing rule, and because no hook-tier timing was measured for it. Semgrep ranks
third because its community rules cannot be vendored and must be fetched at scan
time. Switch to opengrep if the template's rules begin to need intra-procedural taint
(for example, "only flag `format!` SQL when an argument comes from a request").

##### Tradeoffs

- **Hand-written rules are a maintenance burden.** The template owns five rules with
  no upstream to track, and they will miss APIs they do not name (for example a
  different HTTP client's TLS switch).
- **A scanner with no rules would be a placebo.** Pre-commit speed is worth nothing if
  the rule set is empty or silently stops matching. `ast-grep test` and the
  zero-file guard exist to prevent both.
- **No taint tracking.** Findings are syntactic: a constant `format!` SQL string is
  flagged too. Suppressions are inline `// ast-grep-ignore: <rule-id>` comments, which
  should carry a reason in the same spirit as py's "add with rationale only".
- **ast-grep's own tests run on ubuntu only.** Its `coverage.yaml` runs on
  `ubuntu-latest`; macOS is covered by release builds (`release.yml`) and by this leg's
  local execution.
- **Pre-0.x versioning.** ast-grep is at 0.45; rule-syntax changes between minor
  versions are possible, so the version stays pinned.

##### Parameters

- `assumes ci-job-structure` = R11's registered value (quoted in full under the
  top-level `### Parameters`).
- `assumes rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions, raised
  only in a minor release, declared as rust-version in Cargo.toml and tested in CI`,
  `license = MIT OR Apache-2.0`, `target-os-matrix = ubuntu-latest, macos-latest`.
- The member owns no registry parameter.

Fitness gates for `ast-grep` 0.45.3:

1. *Licence* — MIT, compatible. Owner ruling 2026-09-12
   (`docs/planning/p02/execution-ledger.md:495`) limits the licence parameter to this
   repository's own source, so the gate is answered but not binding for a tool. The
   rule files the template writes are its own source and inherit MIT OR Apache-2.0.
2. *MSRV* — `rust-version = "1.88.0"`; the current stable is 1.98.1, so the policy floor
   is 1.96 and ast-grep builds well within it. It is a separate-process dev tool, so it
   never constrains the template's own `rust-version`.
3. *Advisories and `unsafe`* — no RustSec page. The parser depends on `tree-sitter`
   (`crates/core/Cargo.toml:20`, `default = ["tree-sitter"]`), a C runtime reached
   through FFI, so the tool contains `unsafe` through that dependency. It runs as a
   separate process over source text and is not linked into the template.
4. *OS* — prebuilt `aarch64`/`x86_64` `apple-darwin` and `unknown-linux-gnu` assets for
   0.45.3; macOS executed locally; Windows assets also exist (noted, not required).
5. *Features and runtime* — CLI default features; the CLI depends on
   `tokio = { version = "1.37.0", features = ["rt-multi-thread", "io-std"] }` for its own
   use. There is no coupling to the template's async runtime.
6. *Binary size and compile time* — qualitative: a single binary with bundled
   tree-sitter grammars. A prebuilt download costs seconds; a `cargo install` fallback
   is a multi-minute compile (not measured). No effect on the template's own build.

##### Migration implications

- Add `sgconfig.yml` at the repository root.
- Add `rules/security/` with the 5 rule files named above.
- Add `rules/security-tests/` with one `-test.yml` per rule.
- Add an `ast-grep@0.45.3` entry to R42's tool table in the `Justfile`.
- `SECURITY.md` or the contributor docs, whichever R43 settles: one paragraph naming
  the scanner, its rule directory, how to suppress with a reason, and that CodeQL
  covers public repositories in CI.

##### Validation strategy

Planned, in P03:

1. `ast-grep test` exits 0, with every rule's `invalid:` case matching and every
   `valid:` case passing.
2. `ast-grep scan --error` exits 0 on the template, and `scannedFileCount` is greater
   than 0.
3. A seeded mutation adds `danger_accept_invalid_certs(true)` to a web source file;
   `ast-grep scan --error` must exit 1 and name `rs-tls-verification-disabled`.
4. The same seeded line placed under `tests/` must not be flagged.

Already executed in this leg: the stdin fixture, the exit-code behaviour, the timing,
the exclusion behaviour and the zero-file signal, all under
`### Principles and implementation`.

##### Confidence & re-verify trigger

Confidence **medium-high** that ast-grep is the right engine: the gates, speed and
exit behaviour were executed, and large adopters exist. Confidence **medium** in the
rule set's value, because no production Rust project was found using ast-grep for
security.

Re-verify when any of these happens:

- ast-grep reaches 1.0 or changes rule syntax;
- a maintained community Rust security rule set for ast-grep or opengrep appears;
- F027 is widened to private repositories;
- CodeQL's Rust pack gains local-tier tooling;
- or by 2027-03-26 at the latest.

##### Sources

- `https://crates.io/api/v1/crates/ast-grep`, `/versions` (2026-09-26)
- `https://crates.io/api/v1/crates/cargo-geiger`, `cargo-dylint`, `dylint_linting`,
  `cargo-audit`, `cargo-deny`, `cargo-careful`, `lockbud` and each `/versions`
  (2026-09-26)
- `https://api.github.com/repos/ast-grep/ast-grep` (2026-09-26);
  `/releases/latest`; `/contents/Cargo.toml`, `/contents/crates/core/Cargo.toml`,
  `/contents/crates/cli/Cargo.toml`, `/contents/.github/workflows/*`
- `https://api.github.com/search/issues?q=repo:ast-grep/ast-grep+is:issue+is:open` (2026-09-26)
- `https://api.github.com/repos/ast-grep/ast-grep/issues?state=all&sort=created&direction=desc`
  and `/issues/<n>/comments` for #2963–#2934 (2026-09-26)
- `https://rustsec.org/packages/ast-grep.html`, `ast-grep-core.html`,
  `ast-grep-config.html`, `cargo-geiger.html`, `cargo-dylint.html`,
  `dylint_linting.html` (404) and control `tokio.html` (200) (2026-09-26)
- `https://api.github.com/repos/semgrep/semgrep-docs/contents/docs/supported-languages.mdx` (2026-09-26)
- `https://api.github.com/repos/semgrep/semgrep-rules/contents/rust/lang/security` and `/license` (2026-09-26)
- `https://api.github.com/repos/coderabbitai/ast-grep-essentials` and
  `/contents/rules/rust/security` (2026-09-26)
- `https://api.github.com/repos/trailofbits/dylint/readme` and
  `/contents/examples/general/rust-toolchain.toml` (2026-09-26)
- `https://api.github.com/repos/qdrant/qdrant/contents/.github/workflows/rust-lint.yml` (2026-09-26)
- Local execution logs are reproduced in `### Principles and implementation` (2026-09-26)

#### M2 — Hook-tier placement and exclusion pattern (F115)

##### Landscape

This member is a pattern, not a crate: it decides where the M1 scan runs and what it
skips. Options surveyed:

- py's pre-push full-tree scan (`lefthook.yml:160-161`);
- a pre-commit scan of staged files (the F147 tiering philosophy: fast staged checks at
  commit, slower full-tree checks later — `docs/port/COMMONALITY.md:151`);
- CI only;
- R11's rule for where non-compiling checks go — "a check that compiles nothing is a
  step of hygiene".

Exclusion options surveyed:

- rule-level `ignores:` globs;
- `sgconfig.yml` `globalRules.ignores`, used by `DataDog/lading`;
- `--globs` on the command line;
- relying on `.gitignore`, which ast-grep honours by default (`ast-grep scan --help`,
  `--no-ignore` entry: "Do not respect hidden file system or ignore files (.gitignore,
  .ignore, etc.)").

Crate figures (downloads, releases, stars, issues, advisories) are **inapplicable**:
the member names no crate beyond M1's, and lefthook's selection belongs to R37.

##### Principles and implementation

Principle: the scan tier follows the scan's measured cost, not py's historical
placement. py's bandit sits at pre-push because "full-tree scan is too slow per
commit". ast-grep's measured cost (0.09 s wall for 555 files) removes that reason, so
the scan moves to pre-commit on staged files. That gives earlier feedback, and
pre-commit already hosts the other fast staged checks.

The full-tree scan (`just security`) runs in CI, so the hook is a convenience and never
the only gate. A hook can be skipped with `--no-verify`; the CI step cannot.

Exclusions live in each rule's `ignores:` list, not only on the command line, so that
the hook, the recipe and an editor integration all apply the same exclusions. It was
executed that rule-level `ignores` also filter an explicitly named staged file (0
matches with ignores, 2 without, on `tests/process_smoke.rs`). A rule-level list is
therefore safe for lefthook's `{staged_files}`.

Proposed configuration:

```yaml
# lefthook.yml (pre-commit section; R37 owns the hook manager and file layout)
pre-commit:
  jobs:
    - name: security-scan
      glob: "*.rs"
      run: ast-grep scan --error {staged_files}
```

```make
# Justfile (the recipe body is bash so the zero-file guard is exact)
security:
    #!/usr/bin/env bash
    set -euo pipefail
    ast-grep test
    summary=$(ast-grep scan --error --inspect summary 2>&1 >/dev/null) || { ast-grep scan --error; exit 1; }
    count=$(printf '%s\n' "$summary" | sed -n 's/.*scannedFileCount=\([0-9]*\).*/\1/p')
    if [ "${count:-0}" -eq 0 ]; then echo "security: scanned 0 files" >&2; exit 1; fi
```

The guard's parsing was executed with a `bash -c` harness on three paths: `docs/port`
gave `scannedFileCount=0`, `/nonexistent` gave 0, and tokio gave 555. The exact recipe
above was not run as a `just` recipe, because this leg writes no Justfile.

##### Dominant choice

There is no dominant Rust convention, because Rust projects rarely run such a scanner.
Among ast-grep adopters, `qdrant/qdrant` and `TabbyML/tabby` run it in CI on
`ubuntu-latest`; no adopter hook configuration was inspected. The dominant convention
for exclusions is the tool's own config file, as with bandit's `[tool.bandit]` and
DataDog/lading's `globalRules.ignores`.

##### Qualified shortlist

1. **Pre-commit on staged `*.rs` plus a CI full-tree step, with rule-level `ignores`**
   (selected).
2. **Pre-push full tree plus a CI step** — py's placement. It remains correct if the
   rule set grows or a slower engine (opengrep) replaces ast-grep.
3. **CI only** — the smallest change, but it loses the local-feedback half of the
   principle.

##### Excluded by gate

- *A dedicated CI job for the scan* — excluded by R11's registered
  `ci-job-structure`. A check that compiles nothing is a step of `hygiene`, or its own
  cheap job only when a path gate contains its whole input. The scan's input is the
  whole Rust tree plus `rules/` and `sgconfig.yml`, and it does not warrant its own
  job.
- *`globalRules.ignores` in `sgconfig.yml`* — not a gate failure, but not selected. It
  is a valid alternative. Its interaction with explicitly named staged files was not
  executed here; the rule-level form was.

##### Up-and-comers

None for the placement pattern. The ast-grep LSP (`ast-grep lsp`, shipped in the same
binary) could surface the same rules in the editor. That is R28's editor-tooling
territory and is noted only.

##### Fit for this template

- The CLI, library and web crates are all Rust sources under the workspace, so one
  `*.rs` glob covers them.
- The exclusion list equals R16's CodeQL `paths-ignore`, so both SAST layers agree on
  what is shipped code.
- The scan never touches `target/`, and ast-grep honours `.gitignore`.
- Both `ubuntu-latest` and `macos-latest` developers get the same hook.

##### Recommendation

Place the scan at **pre-commit** (staged `*.rs`) and as a step of R11's **`hygiene`**
CI job, via the `just security` recipe with its zero-file guard. Declare
`**/tests/**`, `**/benches/**` and `**/fuzz/**` in every rule's `ignores:`. There are no
global skips; a suppression is an inline `ast-grep-ignore` comment with a reason.

##### Ranked runner-up

Pre-push full-tree scan plus the same CI step. It becomes preferable if a future rule
set or engine makes the staged scan take more than about one second on the template,
which is the cost py's ADR-0018 tiering reason addresses.

##### Tradeoffs

- **Pre-commit is skippable.** `--no-verify` bypasses it, so the CI step is the real
  gate; the hook only moves the feedback earlier.
- **Staged-file scans do not detect removals.** They see only changed files, which is
  fine for pattern rules but means the hook alone is not a full audit.
- **The zero-file guard needs bash.** It parses `--inspect summary` output, a tracing
  format rather than a documented stable interface. A change in ast-grep's summary
  format would make the guard fail closed (count missing → treated as 0 → exit 1),
  which is the safe direction.

##### Parameters

- `assumes ci-job-structure` = R11's registered value, as quoted under the top-level
  `### Parameters`. Placement as a `hygiene` step follows its rule for non-compiling
  checks.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — `hygiene` is an
  ubuntu-latest job under R11, and developer hooks run on both OSes.
- The member owns nothing.

Fitness gates: gates 1–3, 5 and 6 are inapplicable to a placement pattern, because it
adds no crate (M1 carries them). Gate 4 is met by M1's platform evidence.

##### Migration implications

- `lefthook.yml`: add the `security-scan` pre-commit job. R37 owns the file's overall
  shape.
- `Justfile`: add the `security` recipe; include it in whatever aggregate `check` or
  `all` recipe R32/R37 define.
- `.github/workflows/ci.yml`: add a `just security` step to the `hygiene` job. R11 owns
  the job; this is a named slot under its rule.
- No `.gitignore` change.

##### Validation strategy

Planned, in P03:

1. `lefthook run pre-commit` with a staged file containing
   `Command::new("sh")` fails and names `rs-shell-invocation`.
2. The same line under `tests/` passes.
3. `just security` on a checkout whose `rules/` directory is temporarily renamed fails
   with a config error. On a tree with no `.rs` files it fails with
   "scanned 0 files".
4. The CI `hygiene` step goes red on the seeded TLS line and green without it.

Executed in this leg: the tier-deciding timing, the ignores behaviour on directory and
explicit-file inputs, and the zero-file signal.

##### Confidence & re-verify trigger

Confidence **high** on tier, based on measured speed. Confidence **medium** on the exact
recipe text, which was not executed as a `just` recipe. Re-verify when R37 settles the
hook-manager layout, when R11's `ci-job-structure` changes, or when the M1 engine
changes.

##### Sources

- `py@b08bccfb:lefthook.yml:156-163`; `py@b08bccfb:pyproject.toml:265-269`;
  `py@b08bccfb:.github/workflows/lint.yml:111-114` (local clone, read 2026-09-26)
- `docs/port/COMMONALITY.md:120-121` (F114, F115) and `:151` (F147)
- `research/runs/R31/2026-09-26T190203Z-5d8d6465da5a/inputs/parameters.json` (R11 `ci-job-structure`)
- `research/topics/16-codeql-config-customization/DECISION.md` (`paths-ignore` list)
- `https://api.github.com/repos/DataDog/lading/contents/sgconfig.yml`,
  `qdrant/qdrant/contents/tools/ast-grep/sgconfig.yml`,
  `TabbyML/tabby/contents/.github/workflows/ast-grep-lint.yml` (2026-09-26)
- Local executions (ignores, explicit-file, `--inspect summary`), 2026-09-26

### Compatibility

The two members are one tool plus its placement, so compatibility means ast-grep
running the rule layout under a hook and in CI. That combination is tested together
by a shared adopter, not by this template:

- `qdrant/qdrant` runs `sg test --config tools/ast-grep/sgconfig.yml` and
  `sg scan --config tools/ast-grep/sgconfig.yml` in `.github/workflows/rust-lint.yml`
  on `ubuntu-latest`, pinned via `uv tool install ast-grep-cli==0.44.1`.

Version matrix actually exercised:

| Component | Version | Where |
|---|---|---|
| ast-grep | 0.45.3 | executed locally (macOS 26, Apple M4 Pro) |
| ast-grep | 0.44.1 | qdrant CI (ubuntu-latest) — observed in config, not executed |
| rustc (for the fixture's Rust syntax) | 1.98.1 | local; ast-grep parses syntax and does not invoke rustc |

Not tested together: lefthook with ast-grep, because no adopter hook was inspected and
the hook was not executed here.

### Parameters

- owns: nothing (the prompt's `owns:` line is empty).
- `assumes rust-edition = 2024`
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- `assumes license = MIT OR Apache-2.0` — applied to the rule files the template
  writes. Separate-process tools are outside it, per the owner ruling of 2026-09-12
  (`docs/planning/p02/execution-ledger.md:495`).
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- `assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner`
- CONFLICT: none. The scan lands as a step of `hygiene` under the registered rule
  "a check that compiles nothing is a step of hygiene", which needs no change to R11's
  value. `hygiene` has no path gate, so the scan runs on every event, which matches the
  fail-closed intent.

### Migration implications

File-level changes to the template (P03), all proposed:

| File | Change | Owner of the surrounding file |
|---|---|---|
| `sgconfig.yml` (new, repository root) | `ruleDirs: [rules/security]`, `testConfigs: [{testDir: rules/security-tests}]` | R31 |
| `rules/security/*.yml` (new, 5 files) | The five `severity: error` rules, each with `ignores` for `**/tests/**`, `**/benches/**` and `**/fuzz/**` | R31 |
| `rules/security-tests/*-test.yml` (new, 5 files) | `valid:`/`invalid:` cases per rule | R31 |
| `Justfile` | `security` recipe (test, scan, zero-file guard); `ast-grep@0.45.3` entry in R42's tool table | R42 table; R31 recipe |
| `lefthook.yml` | `security-scan` pre-commit job, `glob: "*.rs"`, `run: ast-grep scan --error {staged_files}` | R37 |
| `.github/workflows/ci.yml` | `just security` step in the `hygiene` job | R11 |
| Contributor or security docs | Scanner, rule directory, suppression-with-reason policy; CodeQL covers public repositories | R43 or R81 |

Nothing py-shaped is ported literally. There is no `[tool.bandit]` equivalent in
`Cargo.toml`, and no pre-push job.

### Validation strategy

**Executed in this leg** (2026-09-26, macOS 26, Apple M4 Pro, ast-grep 0.45.3, working
directory `/tmp` or the tokio source directory, no repository writes):

1. Five inline rules over a stdin fixture: 6 of 6 insecure lines flagged; 0 of 5 safe
   counterparts flagged.
2. `--error`: exit 1 with findings, exit 0 on a clean snippet.
3. Timing: tokio 1.53.1, 555 files and 139,608 lines, 0.09 s wall and 0.59 s user.
   Whole registry, 31,616 files, 11.71 s wall.
4. Exclusions: 7 → 0 on tokio with rule-level `ignores`; 2 → 0 on an explicitly named
   test file.
5. Zero-file signal: `scannedFileCount=0` for a missing path and for a Rust-free
   directory, 555 for tokio. Missing path exit code without the guard: 0.

**Planned for P03** (commands to run in the real template on both OSes):

```bash
ast-grep --version                       # expect: ast-grep 0.45.3
ast-grep test                            # expect exit 0; every rule's cases pass
just security                            # expect exit 0 and scannedFileCount > 0
# seeded mutation (reverted afterwards):
printf 'fn f(){ let _ = reqwest::Client::builder().danger_accept_invalid_certs(true); }\n' >> crates/web/src/lib.rs
just security                            # expect exit 1, names rs-tls-verification-disabled
git checkout -- crates/web/src/lib.rs
lefthook run pre-commit                  # with a staged Command::new("sh") line: expect failure
```

The crate path in the mutation is illustrative. P03 substitutes the web member's real
path from R02/R49.

### Confidence & re-verify trigger

**Overall confidence: medium-high** on the decision to adopt and on the engine, and
**medium** on the rule set's long-term value.

- What is solid: the landscape conclusion (no maintained bandit-class Rust scanner);
  the class mapping; the speed and exit-code behaviour, which were executed; and
  adopter evidence for ast-grep as a CI rule engine.
- What is thin: no production Rust project was found using ast-grep, or any
  standalone scanner, for security rules. The five rules are template-authored. The
  practice spot-check was cut short by GitHub's code-search rate limit.

Re-verify triggers:

- ast-grep 1.0 or any rule-syntax change;
- a maintained, openly licensed Rust security rule set appears (for ast-grep or
  opengrep);
- F027 is widened to private repositories;
- R37 changes the hook manager;
- R11's `ci-job-structure` changes;
- or 2027-03-26, whichever comes first.

### Sources

Source repositories (local clones, read 2026-09-26):

- `py@b08bccfb:.github/workflows/lint.yml:111-114`
- `py@b08bccfb:pyproject.toml:265-269`
- `py@b08bccfb:lefthook.yml:156-163`
- `ts@cb1cbcb2:docs/port/TS_PORT_DECISIONS.md:123-139` (D-014, item 5 at lines 131 and 139)

This repository (read 2026-09-26):

- `research/runs/R31/2026-09-26T190203Z-5d8d6465da5a/inputs/prompt.md`, `parameters.json`, `prerequisites.json`
- `docs/port/COMMONALITY.md:33` (F027), `:51` (F045), `:102` (F096), `:120-121` (F114, F115), `:151` (F147)
- `docs/port/OWNER-REVIEW.md:32`, `:259`
- `docs/port/DIVERGENCE-ANALYSIS.md:131`
- `docs/planning/p02/execution-ledger.md:495` (owner licence ruling, 2026-09-12)
- `research/topics/16-codeql-config-customization/DECISION.md` (lines 79, 100, 112, 114; config file) and `evidence/2026-09-05T163018Z-61c8f49b581d-resolve-queries.log`
- `research/topics/42-dev-toolchain-provisioning/DECISION.md:22-30`
- `research/topics/13-dependency-vulnerability-scanning/prompts/dependency-vulnerability-scanning.prompt.md` (Out of scope)

crates.io API (2026-09-26):

- `https://crates.io/api/v1/crates/{ast-grep,cargo-geiger,cargo-dylint,dylint_linting,cargo-audit,cargo-deny,cargo-careful,lockbud}` and `/versions`

GitHub REST API (2026-09-26 US/Pacific):

- `https://api.github.com/repos/{ast-grep/ast-grep, coderabbitai/ast-grep-essentials, semgrep/semgrep, semgrep/semgrep-rules, opengrep/opengrep, opengrep/opengrep-rules, github/codeql, rust-secure-code/cargo-geiger (→ geiger-rs/cargo-geiger), trailofbits/dylint, rust-lang/rust-clippy, facebookexperimental/MIRAI, sslab-gatech/Rudra, BurtonQin/lockbud, rustsec/rustsec, EmbarkStudios/cargo-deny}`
- `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for ast-grep, semgrep, opengrep, dylint, cargo-geiger and codeql
- `https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=100` and `/issues/<n>/comments` for ast-grep, opengrep, semgrep, dylint and cargo-geiger
- `https://api.github.com/repos/ast-grep/ast-grep/releases/latest` and `/contents/README.md`
- `https://api.github.com/repos/opengrep/opengrep/releases/latest`
- `https://api.github.com/repos/ast-grep/ast-grep/contents/{Cargo.toml,crates/core/Cargo.toml,crates/cli/Cargo.toml,.github/workflows}`
- `https://api.github.com/repos/semgrep/semgrep-docs/contents/docs/supported-languages.mdx`
- `https://api.github.com/repos/semgrep/semgrep-rules/contents/rust`, `/contents/rust/lang/security` and `/license`
- `https://api.github.com/repos/coderabbitai/ast-grep-essentials/contents/rules`, `/contents/rules/rust/security` and `/readme`
- `https://api.github.com/repos/trailofbits/dylint/readme` and `/contents/examples/general/rust-toolchain.toml`
- `https://api.github.com/search/code?q=filename:sgconfig.yml+ruleDirs` (856 results)
- Adopter repositories and their files: `repos/{nushell/nushell, qdrant/qdrant, swc-project/swc, DataDog/lading, TabbyML/tabby}` and their `sgconfig.yml`, rule directories, `qdrant/qdrant/.github/workflows/rust-lint.yml` and `TabbyML/tabby/.github/workflows/ast-grep-lint.yml`
- `https://api.github.com/search/code?q=<tool>+repo:<o>/<r>+path:.github` for astral-sh/uv, astral-sh/ruff, BurntSushi/ripgrep, tokio-rs/axum, rust-lang/cargo and zed-industries/zed (partial; HTTP 403 rate limit on several queries)

RustSec (2026-09-26):

- `https://rustsec.org/packages/{ast-grep,ast-grep-core,ast-grep-config,cargo-geiger,cargo-dylint,dylint_linting,tree-sitter}.html` (all 404)
- control `https://rustsec.org/packages/tokio.html` (200)
