# 2026-09-26 — R31 — standalone-security-analyzer (bundle, Focused) — decision (revision 1)

**Revision note, revision 1.** This is the first synthesis of R31. Nothing has been published
for R31 (`research/CLAUDE.md` lists it `open`), so there is no prior revision, no audit to
answer, and no `## Supersedes`. It adjudicates two raw reports that disagree at the top level:
the Muse leg recommends **no** standalone scanner, and the Opus leg recommends **ast-grep with
a template-owned rule set**. This revision adopts the Opus leg's direction, but it does not
adopt that leg's configuration as written. The synthesis executed that configuration and found
two defects, and it changes the rule patterns and the recipe to repair them (`## Engines`,
Disagreements 9 and 10). Every configuration file below is extracted from this document by the
evidence scripts and executed as extracted.

Actor: a fresh synthesizer context that produced neither raw report — the Opus seat, model
`claude-opus-5-5`, Claude Code CLI, 2026-09-26. Item kind `bundle`, effort tier `focused`.
Run `research/runs/R31/2026-09-26T190203Z-5d8d6465da5a`. Inputs read: `inputs/prompt.md`
(sha256 `17bd44fa…`, equal to the manifest's `input_hashes.prompt` and byte-identical to the
topic prompt), `inputs/parameters.json` (sha256 `15e7e98e…`, equal to
`input_hashes.parameters_semantic_file`), `inputs/prerequisites.json`, `inputs/PARAMETERS.md`,
`raw/muse.md` and `raw/opus.md` in full, and the one prerequisite decision,
`research/topics/11-ci-workflow-job-structure/DECISION.md`.

Raw reports:

| Leg | File | sha256 | Lines | Recommendation |
|---|---|---|---|---|
| Muse | `raw/muse.md` | `c5d89d3476f7cf6930898b4dfb9b4933c9cf378bea02e4a6132055e3fa3974cb` | 155 | Adopt nothing; F114 "not adopted, gap documented"; F115 moot |
| Opus (`claude-opus-5-5`) | `raw/opus.md` | `968006a7752f91ce1adf644dcaf73977b6ab6d4333d1028c01175e53661698d5` | 986 | ast-grep 0.45.3, five rules, pre-commit + `hygiene` step |

Retrieval dates: **2026-09-26** for everything this synthesis checked itself through
`review/evidence/`, and each raw's own date (2026-09-26 for both) for anything carried from a
raw and marked as carried.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12`** for every candidate.
The fixed `license = MIT OR Apache-2.0` binds only this repository's own source
(`docs/planning/p02/execution-ledger.md:495`; `docs/port/OWNER-REVIEW.md:47`). The five rule
files and the configuration this decision prescribes are repository source, so they carry the
template's licence. The LGPL-2.1 of Semgrep and opengrep and the MIT of ast-grep are reported
as metadata only.

## Decision

**This decision is a proposal validated in the implementation phase**
(`docs/planning/p02/execution-ledger.md:213`, the programme-wide ruling of 2026-09-10). No
Rust source exists in this repository yet. The checks below ran against a throwaway fixture
under `$TMPDIR`, built from the files quoted in this section, and against the tokio 1.53.1
source as a size workload. P03 builds the template, and its CI proves the recommendation.

**Recommendation: adopt `ast-grep` 0.45.3 as `rs-launch-blueprint`'s standalone security
scanner. It runs a template-owned, self-tested rule set of five `severity: error` rules. The
scan runs at pre-commit on staged `*.rs` files, and as a `just security` step of R11's
`hygiene` CI job.**

- *What the scanner is.* ast-grep is a tree-sitter structural pattern engine; crate
  `ast-grep`, MIT licence, `rust-version` 1.88.0, newest non-yanked release 0.45.3
  (2026-08-31). It is a separate-process developer tool. It is not a dependency of any
  template crate and never constrains the template's `rust-version`.
- *Install and invocation.* Install through R42's generic `install-tool` recipe, whose body
  is `cargo binstall --locked --no-confirm ast-grep@0.45.3`
  (`research/topics/42-dev-toolchain-provisioning/DECISION.md:27`). Invoke the bare
  `ast-grep` executable, per R42's `package-manager-invocation`. Never use the `sg` alias that
  the same crate installs (E4 shows both `[[bin]]` entries). One name everywhere avoids the
  Opus leg's concern that `sg` may clash with a Linux `sg` (switch group) command, which it
  did not verify, and neither did this synthesis (`raw/opus.md:515-519`).
- *The rule set.* Five rules, one YAML file each, under `rules/security/`. Each rule has a
  `valid:`/`invalid:` test file under `rules/security-tests/` that `ast-grep test` executes.

  | Rule id | Bandit analogue | What it flags |
  |---|---|---|
  | `rs-shell-invocation` | B602, B605 | `Command::new("<shell>")` under any path prefix (`std::process::`, `tokio::process::`) and absolute shell paths |
  | `rs-sql-format` | B608 | `query`, `query_as`, `query_scalar`, `execute`, `raw_sql` or `sql_query` called with a `format!` result as its first argument, with or without further arguments |
  | `rs-weak-hash` | B303, B324 | MD4, MD5 or SHA-1 constructors and one-shot digests, qualified or imported |
  | `rs-tls-verification-disabled` | B501 | `danger_accept_invalid_certs(true)` and `danger_accept_invalid_hostnames(true)` |
  | `rs-predictable-temp` | B108 | `temp_dir()` reached as `std::env::temp_dir`, `env::temp_dir` or an imported `temp_dir` |

- *Exclusions (the LOW question).* Every rule lists
  `ignores: ["**/tests/**", "**/benches/**", "**/fuzz/**"]`. This is the same list R16 gave
  CodeQL's `paths-ignore` (`research/topics/16-codeql-config-customization/DECISION.md:60`),
  and the Rust analogue of py's `[tool.bandit] exclude_dirs`. There are no global skips, as in
  py's `skips = []`. A single site is suppressed with an inline
  `// ast-grep-ignore: <rule-id>` comment, which must state its reason.
- *Hook tier (F115).* Pre-commit, on staged `*.rs` files — not py's pre-push. py placed
  bandit at pre-push because "full-tree scan is too slow per commit"
  (`py@b08bccfb:lefthook.yml:157-158`). This scan measured well under a second on a tree
  larger than the template will be (`## Empirical check`, check E3), so py's reason does not
  transfer. The pre-commit hook is a convenience that `--no-verify` bypasses. The `hygiene` CI
  step is the gate.
- *CI placement.* A step of R11's `hygiene` job. Under R11's rule, "a check that compiles
  nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's
  key contains the whole input of every check in the job". The scan compiles nothing. Its
  input is every `.rs` file plus `sgconfig.yml` and `rules/`. None of R11's four keys contains
  that input: `code` is the negation of a skip-list of paths that cannot affect a compile, so
  `rules/` and `sgconfig.yml` are skippable by `code`'s construction. The scan therefore
  lands in `hygiene`, which has no path gate and runs on every event.
- *What stays with other items.* CodeQL for Rust stays the CI dataflow layer for public
  repositories (F027 unchanged; R16's configuration). Dependency advisories stay with R13.
  Clippy's security-adjacent lints stay with R28. First-party `unsafe` stays with R06.
- *Not a member.* `cargo-audit`, `cargo-deny` and `cargo-geiger` are not adopted here. The
  first two are dependency scanners (R13's lane). The third is an `unsafe` inventory, which
  is vacuous for first-party code under R06's `forbid`.

Ledger rows settled:

- **F114** (`docs/port/COMMONALITY.md:120`, `DIVERGENT`, py-only) is resolved as *capability
  adopted from py, mechanism re-derived for Rust*. A separate first-party scanner is adopted.
  Its engine is ast-grep, and its rules are template-owned, because Rust has no maintained
  bandit analogue whose rules could be consumed.
- **F115** (`docs/port/COMMONALITY.md:121`, `DIVERGENT`, py-only) is resolved as
  *pre-commit on staged files, plus a CI step*. py's pre-push reason was scan cost, and the
  measured cost removes it. This is consistent with F147's tiering philosophy
  (`docs/port/COMMONALITY.md:151`): fast staged checks run at commit.

The files, exactly as the evidence scripts extract and execute them. The `# path:` first line
of each block names the file it becomes.

```yaml
# path: sgconfig.yml
ruleDirs:
  - rules/security
testConfigs:
  - testDir: rules/security-tests
```

```yaml
# path: rules/security/rs-shell-invocation.yml
id: rs-shell-invocation
language: rust
severity: error
message: A shell is spawned; build the argv directly instead of passing a command string to a shell (bandit B602/B605 analogue).
ignores:
  - "**/tests/**"
  - "**/benches/**"
  - "**/fuzz/**"
rule:
  pattern: $CMD($SH)
constraints:
  CMD:
    regex: '(^|::)Command::new$'
  SH:
    regex: '^"((/usr)?/bin/)?(sh|bash|zsh|dash|ksh|fish|cmd|cmd\.exe|powershell|powershell\.exe|pwsh)"$'
```

```yaml
# path: rules/security/rs-sql-format.yml
id: rs-sql-format
language: rust
severity: error
message: SQL text is built with format!; bind parameters instead (bandit B608 analogue).
ignores:
  - "**/tests/**"
  - "**/benches/**"
  - "**/fuzz/**"
rule:
  any:
    - pattern: $Q(&format!($$$A))
    - pattern: $Q(format!($$$A).as_str())
    - pattern: $Q(format!($$$A))
    - pattern: $Q(&format!($$$A), $$$REST)
    - pattern: $Q(format!($$$A).as_str(), $$$REST)
constraints:
  Q:
    regex: '(^|::|\.)(query|query_as|query_scalar|execute|raw_sql|sql_query)$'
```

```yaml
# path: rules/security/rs-weak-hash.yml
id: rs-weak-hash
language: rust
severity: error
message: MD4, MD5 or SHA-1 is used; use SHA-256 or stronger for anything security-relevant (bandit B303/B324 analogue).
ignores:
  - "**/tests/**"
  - "**/benches/**"
  - "**/fuzz/**"
rule:
  pattern: $F($$$ARGS)
constraints:
  F:
    regex: '((^|::)(Md4|Md5|Sha1)::(new|default|digest|new_with_prefix)|(^|::)md5::compute)$'
```

```yaml
# path: rules/security/rs-tls-verification-disabled.yml
id: rs-tls-verification-disabled
language: rust
severity: error
message: TLS certificate or hostname verification is disabled (bandit B501 analogue).
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
# path: rules/security/rs-predictable-temp.yml
id: rs-predictable-temp
language: rust
severity: error
message: A path under the shared temp directory is predictable; use the tempfile crate (bandit B108 analogue).
ignores:
  - "**/tests/**"
  - "**/benches/**"
  - "**/fuzz/**"
rule:
  pattern: $F()
constraints:
  F:
    regex: '^((std::)?env::)?temp_dir$'
```

```yaml
# path: rules/security-tests/rs-shell-invocation-test.yml
id: rs-shell-invocation
valid:
  - Command::new("git")
  - std::process::Command::new("cargo").arg("build")
invalid:
  - Command::new("sh").arg("-c").arg(cmd)
  - std::process::Command::new("bash")
  - tokio::process::Command::new("/bin/sh")
  - let c = Command::new("cmd.exe");
```

```yaml
# path: rules/security-tests/rs-sql-format-test.yml
id: rs-sql-format
valid:
  - sqlx::query("SELECT * FROM t WHERE id = $1").bind(id)
  - query_as::<_, Row>("SELECT 1")
  - conn.execute("DELETE FROM t WHERE id = ?1", [id])
invalid:
  - sqlx::query(&format!("SELECT * FROM t WHERE id = {id}"))
  - query(format!("DELETE FROM {t}").as_str())
  - conn.execute(&format!("DROP TABLE {t}"))
  - conn.execute(&format!("DELETE FROM {t}"), [])
  - diesel::sql_query(format!("SELECT {c}"))
```

```yaml
# path: rules/security-tests/rs-weak-hash-test.yml
id: rs-weak-hash
valid:
  - Sha256::new()
  - sha2::Sha512::digest(data)
invalid:
  - md5::compute(b"data")
  - md5::Md5::new()
  - sha1::Sha1::new()
  - Sha1::default()
  - Md5::digest(data)
```

```yaml
# path: rules/security-tests/rs-tls-verification-disabled-test.yml
id: rs-tls-verification-disabled
valid:
  - reqwest::Client::builder().danger_accept_invalid_certs(false).build()
invalid:
  - reqwest::Client::builder().danger_accept_invalid_certs(true).build()
  - builder.danger_accept_invalid_hostnames(true)
```

```yaml
# path: rules/security-tests/rs-predictable-temp-test.yml
id: rs-predictable-temp
valid:
  - tempfile::NamedTempFile::new()
  - tempfile::tempdir()
invalid:
  - std::env::temp_dir().join("app.lock")
  - env::temp_dir()
  - let d = temp_dir();
```

The Justfile recipe. Its body is bash, so that both guards are exact. The first guard fails a
scan that covered zero files, which is py's recorded silent-empty-scan failure
(`py@b08bccfb:.github/workflows/lint.yml:112-113`). The second guard fails a scan that loaded
zero rules. Without it, deleting every rule and every test passes silently: `ast-grep test`
reports "0 passed; 0 failed" and exits 0, and the scan exits 0 (check E2). `ast-grep test` runs
with `--skip-snapshot-tests` because the template keeps no snapshot baselines, and a bare
`ast-grep test` exits 4 without them (check E2).

```just
# path: Justfile
security:
    #!/usr/bin/env bash
    set -euo pipefail
    ast-grep test --skip-snapshot-tests
    summary=$(ast-grep scan --error --inspect summary 2>&1 >/dev/null) || { ast-grep scan --error; exit 1; }
    files=$(printf '%s\n' "$summary" | sed -n 's/.*scannedFileCount=\([0-9]*\).*/\1/p')
    rules=$(printf '%s\n' "$summary" | sed -n 's/.*effectiveRuleCount=\([0-9]*\).*/\1/p')
    if [ "${files:-0}" -eq 0 ]; then echo "security: scanned 0 files" >&2; exit 1; fi
    if [ "${rules:-0}" -eq 0 ]; then echo "security: loaded 0 rules" >&2; exit 1; fi
    echo "security: ${files} files, ${rules} rules, 0 findings"
```

The lefthook job. R37 owns `lefthook.yml`'s overall shape; this is R31's slot in it.

```yaml
# path: lefthook.yml
pre-commit:
  jobs:
    - name: security-scan
      glob: "*.rs"
      run: ast-grep scan --error {staged_files}
```

The CI slot, proposed and not executed. R11 owns `ci.yml` and the `hygiene` job; R42 owns how
`ast-grep` reaches `PATH` on the runner (its re-verify list names a CI toolchain-install action
as still open).

```yaml
      # .github/workflows/ci.yml, job hygiene — R31's slot (proposed, not executed)
      - name: Security scan (R31)
        run: just security
```

### Principles and implementation

**Shared requirement.** A tool separate from the general linter checks first-party source for
known-insecure patterns. It fails on a finding, it declares its exclusions in a file, and it
runs both locally and in CI. Its availability does not depend on the repository's hosting
plan or visibility.

- *Sources.* py runs `bandit` in CI (`py@b08bccfb:.github/workflows/lint.yml:114`) with a
  config table (`py@b08bccfb:pyproject.toml:267`) and at pre-push
  (`py@b08bccfb:lefthook.yml:160-161`). ts deferred its equivalent: its D-014(5) is
  "eslint-plugin-security deferred until Oxlint JS plugins leave alpha"
  (`ts@cb1cbcb2:docs/port/TS_PORT_DECISIONS.md:131`). The owner direction of 2026-09-04 is
  "Make sure there's a security scanner … Same thing with Rust"
  (`docs/port/OWNER-REVIEW.md:259`).
- *Agreement level.* Capability and policy, not tool. Both legs place it at the capability
  level (`raw/muse.md:25`, `raw/opus.md:159-162`). What must agree across py, ts and rs: a
  separate scanner exists, fails on a finding, declares exclusions in a file, and runs locally
  and in CI. What may vary: the engine, the rule contents, and the tier, which follows
  measured cost.

**Which bandit classes survive in Rust.** Both legs agree on this mapping, and the mapping
shapes the rule set.

| Bandit class | Status in Rust | CodeQL at the pinned bundle 2.26.4 (`security-extended`) | R31 rule |
|---|---|---|---|
| `eval`/`exec` (B102, B307) | Eliminated: no runtime code evaluation | — | — |
| Unsafe deserialization (B301, B403, B506) | Eliminated by default: serde builds typed values | — | — |
| Shell invocation (B602, B605) | Survives: `Command::new("sh").arg("-c")` | **None at 2.26.4.** `rust/command-line-injection` first appears at 2.27.0 (`research/topics/16-codeql-config-customization/DECISION.md:100`) | `rs-shell-invocation` |
| SQL from strings (B608) | Survives: `sqlx::query(&format!(..))` | `CWE-089/SqlInjection.ql` | `rs-sql-format` |
| Weak hash (B303, B324) | Survives: `md5`, `sha1` crates | `CWE-327/BrokenCryptoAlgorithm.ql`, `CWE-327/WeakSensitiveDataHashing.ql` | `rs-weak-hash` |
| TLS verification off (B501) | Survives: `danger_accept_invalid_certs(true)` | `CWE-295/DisabledCertificateCheck.ql` | `rs-tls-verification-disabled` |
| Predictable temp file (B108) | Survives: `std::env::temp_dir().join(..)` | None | `rs-predictable-temp` |
| Hard-coded secrets (B105–B107) | Survives | `CWE-798/HardcodedCryptographicValue.ql` covers keys, not passwords | None: secrets belong to R17/R39 |
| Bind all interfaces (B104) | Survives for the web service | None | None: a candidate sixth rule, not executed (gap) |

The CodeQL column is read from R16's executed query resolution
(`research/topics/16-codeql-config-customization/evidence/2026-09-05T163018Z-61c8f49b581d-resolve-queries.log`).
That log resolves 16 security queries for the default suite and **18** for
`security-extended`, the suite R16 adopted.

**Why a separate scanner, and why ast-grep.** Four facts decide it.

1. The owner asked for a scanner for Rust (`docs/port/OWNER-REVIEW.md:259`).
2. CodeQL does not reach every instance of the template. F027 gates CodeQL to public
   repositories, and the ledger records that "public-only is a selected policy, not an
   availability check" (`docs/port/COMMONALITY.md:33`). A private repository created from the
   template therefore runs no first-party SAST unless someone widens F027.
3. Where CodeQL does run, it misses two of the surviving classes at the pinned bundle: shell
   invocation and predictable temp files (table above).
4. Rust has a fast, native, maintained rule engine, which ts lacked. ts deferred its scanner
   because none was available (`ts@cb1cbcb2:docs/port/TS_PORT_DECISIONS.md:131`,
   `:139`). That reason does not hold for Rust.

The two layers are complementary rather than redundant. CodeQL tracks taint across functions,
but only in CI and only for public repositories. ast-grep matches syntax per file, as bandit
does, but it runs locally, in well under a second, and offline.

**Architectural alternatives compared before choosing a tool.**

| Alternative | Local tier | Private repos | Stable toolchain | Verdict |
|---|---|---|---|---|
| A0 — No scanner; clippy + CodeQL + R13; document the gap (Muse leg, ts's shape) | No | No first-party SAST | Yes | Rejected: fails the owner direction and leaves private instances without SAST |
| **A1 — Structural rule engine with template-owned, self-tested rules (ast-grep)** | Yes, pre-commit speed | Yes | Yes | **Selected** |
| A2 — opengrep with template-owned rules | Yes, pre-push | Yes | Yes (OCaml binary, release-only) | Runner-up |
| A3 — Semgrep CE with registry rules | Yes, pre-push | Yes, but the rules are fetched at scan time | Yes (Python/OCaml) | Third |
| A4 — Dylint compiler-plugin lints | Slow, compiles | Yes | **No**: nightly plus `rustc-dev` | Excluded by gate |
| A5 — CodeQL CLI in a hook | Not measured | Not established | Yes | Rejected for the hook tier; stays in CI (R16) |
| A6 — `cargo-geiger` | Yes | Yes | Yes | Out of category: an `unsafe` count, vacuous under R06 |

**Fitness gates for `ast-grep` 0.45.3, answered before popularity.**

| Gate | Answer | Evidence |
|---|---|---|
| 1. Licence | `inapplicable — owner ruling 2026-09-12`. The crate is MIT, reported as metadata | E4; `docs/planning/p02/execution-ledger.md:495` |
| 2. MSRV | Passes. `rust-version` 1.88.0, below the policy floor of 1.96 against stable 1.98.1. A separate-process tool never raises the template's own `rust-version` | E4 |
| 3. Advisories; `unsafe` | No RustSec page for `ast-grep` or `ast-grep-core` (404; control 200). The parser reaches the `tree-sitter` C runtime through FFI, so the tool contains `unsafe` through that dependency. It runs as a separate process over source text and is never linked into the template. The `unsafe` reading is carried from the Opus leg and was not re-read | E4; `raw/opus.md:567-570` |
| 4. OS | Passes for `ubuntu-latest` and `macos-latest` by published 0.45.3 assets for `x86_64`/`aarch64` Linux and Darwin. Executed on macOS only. Windows assets exist (noted, not required) | E4; E1–E3 |
| 5. Default features, async runtime | The CLI's default features. The CLI depends on `tokio` for its own use; there is no coupling to the template's async runtime, because nothing links it. Carried from the Opus leg | `raw/opus.md:573-575` |
| 6. Binary size, compile time | Qualitative: one binary with bundled tree-sitter grammars. A prebuilt download costs seconds; the `cargo install` fallback is a multi-minute compile, unmeasured. No effect on the template's build | `raw/opus.md:576-578` |

Crate figures are inapplicable to the placement pattern (M2 in the Opus leg), because it adds no
crate. They are also inapplicable to opengrep and Semgrep, which are not crates (Semgrep:
`GET https://crates.io/api/v1/crates/semgrep` returns "crate semgrep does not exist",
`raw/muse.md:92`); their GitHub figures are carried from the legs.

**Acceptance criteria, and where each was executed.**

| Id | Criterion | Status |
|---|---|---|
| A1 | Every rule's `invalid:` cases match and every `valid:` case does not (`ast-grep test`) | Executed, met (E1) |
| A2 | A finding fails the scan (exit 1) and names the rule; a clean tree exits 0 | Executed, met (E1) |
| A3 | Qualified and imported call forms are caught; safe counterparts are not | Executed, met, with stated misses (E1) |
| A4 | Findings under `tests/`, `benches/` and `fuzz/` are ignored, including a staged file named explicitly | Executed, met (E1, E2) |
| A5 | `just security` fails on zero scanned files, on a missing rule directory, and on zero loaded rules | Executed, met (E2) |
| A6 | The lefthook job fails on a staged finding in shipped code and passes when only a test file is staged | Executed, met (E2) |
| A7 | Fast enough for pre-commit on a tree larger than the template | Executed, met (E3) |
| A8 | Runs on `ubuntu-latest` and `macos-latest` | macOS executed; Linux by published release asset and adopter only (E4) |
| A9 | The `hygiene` CI step goes red on a seeded finding | Proposed for P03 |

**Known limitations, recorded rather than hidden.** The engine has no taint tracking. It flags a
`format!` SQL string even when every argument is a constant. It misses a shell name or SQL
text that reaches the call through a variable. It misses a type renamed on import, such as
`use std::process::Command as Cmd;` followed by `Cmd::new("sh")`. It misses any API the rules
do not name, for example another HTTP client's TLS switch. Check E1 shows the variable-carried
and renamed-import misses.
These limits are why CodeQL stays in CI, and why a rule that grows past syntax would move the
engine to opengrep (the runner-up).

No `BASELINE-REVIEW:` line is raised against F114 or F115. One observation passes to F027's
owner without changing F027: F027's public-only gate is what gives this scanner most of its
weight. If F027 is widened to private repositories with Code Security, the scanner's marginal
value narrows to local speed, offline use, and the two classes CodeQL lacks at the pin.

re-verify: 2027-03-26, or earlier on any of — ast-grep reaching 1.0 or changing rule or `--inspect summary` syntax (the recipe's guards parse `scannedFileCount=` and `effectiveRuleCount=`); `GET https://api.github.com/repos/ast-grep/ast-grep` returning `archived: true` or a RustSec advisory appearing at `https://rustsec.org/packages/ast-grep.html`; a maintained, openly licensed Rust security rule set appearing for ast-grep or opengrep, which the template could consume instead of owning rules; F027 being widened to private repositories; R16's `github/codeql-action` pin advancing to a bundle with `rust/command-line-injection` (2.27.0 or later), which narrows `rs-shell-invocation` to the local and private-repository case; R28 publishing a clippy selection that already denies any of the five patterns; R37 publishing a hook manager other than lefthook or a different job layout; R11 changing `ci-job-structure` or its rule for non-compiling checks; R42 naming the CI install action for release-backed tools, or `cargo binstall` failing to resolve a prebuilt `ast-grep` for `x86_64-unknown-linux-gnu`; R69 or R58 adding a crate whose insecure API none of the five rules names; P03's first scan of the real template producing a false positive that needs a suppression, which would test the suppression-with-reason policy.

## Parameters

R31 owns no registry parameter: the prompt's `## Couplings` block carries an empty `- owns:`
line, and `docs/port/PARAMETERS.md` lists no R31 owner. Its one consumed parameter is R11's,
named on the prompt's `- consumes: R11: ci-job-structure` line. The value below is extracted
byte-exact from `inputs/parameters.json` and checked against the registry row (check E5).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner

**No `CONFLICT:` line is emitted.** Neither raw raised one. The scan lands as a step of
`hygiene` under R11's registered rule, which needs no change to R11's value.

**How each assumed parameter bears on the decision.**

- `ci-job-structure` fixes the CI placement: the containment argument under `## Decision`
  puts the scan in `hygiene`. R11 makes `hygiene` single-runner by design
  (`research/topics/11-ci-workflow-job-structure/DECISION.md:259`), and its candidate workflow
  runs it on `ubuntu-latest`
  (`research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/evidence/ci.candidate.r6-audited.yml:118`).
- `msrv-policy` bears on nothing the template compiles. ast-grep declares `rust-version`
  1.88.0, below the policy floor of 1.96 against current stable 1.98.1. It is a
  separate-process tool, so it never raises the template's `rust-version`.
- `target-os-matrix` is gate 4: ast-grep publishes Linux and macOS release assets for 0.45.3
  (check E4); this synthesis executed on macOS only.
- `license` is recorded but not evaluated for any tool, per the 2026-09-12 ruling.
- `rust-edition = 2024` does not bear: ast-grep parses syntax through tree-sitter and never
  invokes `rustc`.

## Empirical check

**Toolchain and host.** `ast-grep 0.45.3` (Homebrew, `/opt/homebrew/bin/ast-grep`),
`just 1.57.0`, `lefthook 2.1.14`, `git 2.50.1`, `ShellCheck 0.11.0`, `curl 8.7.1`,
`gh 2.101.0`; `rustc 1.98.1 (48a229cea 2026-09-01)` is installed but never invoked, because
ast-grep parses syntax and does not compile. macOS 26.4, `Darwin 25.4.0 arm64`, Apple M4 Pro,
14 logical CPUs. **This is one macOS host, not the `target-os-matrix`.** Linux rests on the
published `x86_64-unknown-linux-gnu` and `aarch64-unknown-linux-gnu` release assets for 0.45.3
(E4) and on qdrant's `ubuntu-latest` job (E4), not on an execution.

**Commands and working directory.** Five scripts under `review/evidence/`. Each is
`shellcheck`-clean, prints only to stdout, writes nothing into the repository, and builds any
fixture under `$TMPDIR` and removes it on exit. Each committed `.log` is the script's
stdout and stderr from a fresh run by this synthesizer, invoked from `review/evidence/` as
`bash <script>.sh > <script>.log 2>&1`. E1–E3 extract every `# path:` block from this
document, so the files executed are the files quoted under `## Decision`. Each of those logs
prints a digest of the extracted files, and all three print the same one,
`62f24bce24a4030f5962b9a2583593ad86022953f1b35c02237fa9eef6b53bdc`. An auditor rerunning a
script should redirect to a scratch path, not over the committed log.

| Check | Script and log | What it settles |
|---|---|---|
| E1 | `r31-e1-rules.sh` / `.log` | The rule set: self-tests, exit codes, exclusions, alternate call forms, suppression, placebo guard |
| E2 | `r31-e2-recipe-hook.sh` / `.log` | The `just security` recipe and the lefthook job, as extracted |
| E3 | `r31-e3-workload.sh` / `.log` | Scan cost (F115) and exclusions on the published tokio 1.53.1 source |
| E4 | `r31-e4-figures.sh` / `.log` | Live figures at the prompt's named endpoints |
| E5 | `r31-e5-inputs-citations.sh` / `.log` | Input hashes, the byte-exact `assumes` value, and every file:line citation in this document |

**Observed output — E1, the rule set** (`r31-e1-rules.log`).

```text
E1.1  ast-grep test --skip-snapshot-tests      5 passed; 0 failed        exit=0
E1.2  ast-grep scan --error (clean tree)                                 exit=0
E1.3  seeded src/seeded.rs, one line per rule  5 findings, all 5 rule ids exit=1
E1.4a same seeds under tests/ benches/ fuzz/   0 findings                exit=0
E1.4b same seeds, each file named explicitly   0 findings                exit=0
E1.4c control: rs-tls rule with ignores stripped, tests/seeded.rs    matches: 1
E1.5  probe file, recommended rules            flagged lines: 15 (expected 15);
                                               L22-L29 (5 safe, 3 known misses) unflagged
E1.6  probe file, the Opus leg's patterns      flagged 6 of the 15 insecure lines
E1.7  // ast-grep-ignore: rs-weak-hash         only the unsuppressed line 4 flagged
E1.8  rs-tls pattern broken on purpose         ast-grep test: 4 passed; 1 failed (rs-tls)  exit=4
```

The first E1 run of this synthesis failed E1.1: `rs-sql-format` missed its own `invalid:` case
`conn.execute(&format!(..))`. The cause was the path regex `(^|::)execute$`: a method call
joins `conn` and `execute` with `.`, which the regex did not accept. The regex now reads
`(^|::|\.)…`, and the committed log is a fresh run after that fix. This is the self-test
guard working as intended on the template's own rule set.

**Observed output — E2, the recipe and hook** (`r31-e2-recipe-hook.log`).

```text
E2.1  just security, clean tree                  "security: 3 files, 5 rules, 0 findings"  exit=0
E2.2  seeded TLS line in crates/web/src/lib.rs   rs-tls-verification-disabled named        exit=1
E2.3  no .rs files anywhere                      "security: scanned 0 files"               exit=1
E2.4  rules/security renamed away                "Cannot read rule directory"              exit=6
E2.5a every rule and test deleted: ast-grep test "0 passed; 0 failed"                      exit=0
E2.5b every rule deleted: ast-grep scan --error                                            exit=0
E2.5c every rule and test deleted: just security "security: loaded 0 rules"                exit=1
E2.6  bare `ast-grep test` (no snapshot flag)    "0 passed; 5 failed" (mismatching snapshots) exit=4
E2.7a lefthook pre-commit, staged tests/spawn.rs only                                      exit=0
E2.7b lefthook pre-commit, + staged src/spawn.rs rs-shell-invocation named                 exit=1
```

E2.5a and E2.5b are the placebo the second guard exists for. E2.6 is why the recipe passes
`--skip-snapshot-tests`. E2.7 ran `lefthook run pre-commit --no-auto-install` in a scratch git
repository under `$TMPDIR`, which demonstrates `{staged_files}` together with rule-level
`ignores`. It does not settle lefthook's selection or file layout, which are R37's.

**Observed output — E3, scan cost and exclusions** (`r31-e3-workload.log`). The workload is the
tokio 1.53.1 `.crate` from `GET https://crates.io/api/v1/crates/tokio/1.53.1/download`
(redirected to `static.crates.io`). Its sha256 `202caea8…` matches `version.checksum` from
`GET https://crates.io/api/v1/crates/tokio/1.53.1`.

```text
E3.1  workload: 555 .rs files, 139,608 lines; ast-grep scannedFileCount=555
E3.2  full-tree scan, all 5 rules, JSON to /dev/null, 5 runs:
      real 0.09-0.13 s, user 0.80-0.95 s, sys 0.05-0.08 s
E3.3a recommended rules (ignores active):   total 0
E3.3b same rules, ignores stripped:         total 7 — rs-shell-invocation, all under tests/
```

Workload, configuration and instrumentation are stated. The measurement is `/usr/bin/time -p`
around one full-tree `ast-grep scan --json=compact`, with ast-grep's default thread count and
a warm file cache after run 1. Throughput is 555 files in at most 0.13 s of wall time, at
under 1 s of CPU. Resource cost beyond CPU time was not measured. The template will be
far smaller than tokio, and a pre-commit run scans staged files only, so this full-tree figure
is an upper bound for the hook. The result matches the Opus leg's figures (555 files, 139,608
lines, 0.09 s, 7 test-only findings) within run-to-run variation. Its separate 31,616-file whole-registry timing was not
rerun, because it is not a template workload.

**Observed output — E4, live figures** (`r31-e4-figures.log`, retrieved 2026-09-27T01:49Z,
which is 2026-09-26 US/Pacific).

| Figure | Endpoint | Value |
|---|---|---|
| ast-grep 90-day / all-time downloads | `GET https://crates.io/api/v1/crates/ast-grep` | 38,223 / 655,883 |
| ast-grep newest non-yanked release | `…/ast-grep/versions` | 0.45.3, 2026-08-31T01:40:29Z, `rust_version` 1.88.0, MIT |
| ast-grep stars, archived, pushed | `GET https://api.github.com/repos/ast-grep/ast-grep` | 16,053, `false`, 2026-09-25T15:23:54Z |
| ast-grep open issues | `GET https://api.github.com/search/issues?q=repo:ast-grep/ast-grep+is:issue+is:open` | `total_count` 47 |
| ast-grep 0.45.3 release assets | `…/releases/tags/0.45.3` | `app-{aarch64,x86_64}-{apple-darwin,unknown-linux-gnu}.zip` |
| ast-grep CLI binaries, binstall metadata | `…/contents/crates/cli/Cargo.toml` | `[[bin]]` `ast-grep` and `sg`; `package.metadata.binstall` present |
| ast-grep advisories | `https://rustsec.org/packages/ast-grep.html`, `ast-grep-core.html` | 404, 404 (control `tokio.html` 200) |
| cargo-geiger 90-day / all-time; newest | `GET https://crates.io/api/v1/crates/cargo-geiger` (+ `/versions`) | 53,508 / 243,879; 0.13.0, 2025-08-31, `rust_version` 1.85 |
| cargo-geiger advisories; issue #539 | `https://rustsec.org/packages/cargo-geiger.html`; `…/geiger-rs/cargo-geiger/issues/539` | 404; `open` since 2025-04-11 |
| qdrant's ast-grep job | `…/qdrant/qdrant/contents/.github/workflows/rust-lint.yml` | lines 49–62: `ubuntu-latest`, `uv tool install ast-grep-cli==0.44.1`, `sg test … --skip-snapshot-tests`, `sg scan` |
| Semgrep community Rust security rules | `…/semgrep/semgrep-rules/contents/rust/lang/security` | 10 rule files |
| opengrep-rules; ast-grep-essentials | `…/repos/opengrep/opengrep-rules`; `…/coderabbitai/ast-grep-essentials` | both `archived: true` |
| Rudra; MIRAI | `…/sslab-gatech/Rudra`; `…/facebookexperimental/MIRAI` | both `archived: true` |
| Dylint example toolchain | `…/trailofbits/dylint/contents/examples/general/rust-toolchain.toml` | `nightly-2026-08-20`, `rustc-dev` |

Issue responsiveness (the prompt's 10-newest-issues figure) was **not** re-collected. The
Opus leg's reading is carried and marked as carried: for ast-grep, 2 of the 10 newest issues
were answered by a maintainer comment (median 1.56 days), one was closed by the maintainer
without a comment, and 7 had no answer yet, in a window under two weeks
(`raw/opus.md:393`). Maintenance state by the prompt's rubric: **`active`**. The last release
was under a month before retrieval, the repository was pushed the day before, it is not
archived, and there is no advisory.

**Observed output — E5, inputs and citations** (`r31-e5-inputs-citations.log`).

```text
E5.1  prompt, parameters.json, prerequisites.json == manifest input_hashes        OK (4 checks)
      R11 DECISION.md 410e88e5…, acceptance.json 774f7649… == prerequisites.json    OK (2 checks)
E5.2  registry row == inputs/parameters.json; DECISION assumes line == both       OK
      the four fixed `assumes` lines == inputs/parameters.json                      OK (4 checks)
      raw/opus.md:867 quotation identical: True
      raw/muse.md:102 quotation identical: False — inserted words "a", "only"
E5.3  every file:line citation in this document, including the py and ts pins     65 OK, 0 FAIL
result: 0 failure(s)                                                                exit=0
```

E5.3 caught two wrong line numbers in a draft of this document: the R16 resolve-log counts sit
at lines 25 and 47, not 23 and 43. They were corrected before the committed run.

## Engines

- **Muse** — `raw/muse.md`, sha256 `c5d89d34…`, 155 lines, 10 H3 fields with one bundle
  member. Recommends **no standalone scanner**. F114 becomes "not adopted, gap documented
  (ts D-014(5) analogue)", and F115 is moot. The composition it relies on is R06 `forbid`,
  R28 clippy, R16 CodeQL, R17 TruffleHog and R13 SCA. Ranked runner-up: Semgrep. No
  `CONFLICT:`, no `BASELINE-REVIEW:`. It executed only read-only endpoint GETs and
  `rustc`/`cargo --version` (`raw/muse.md:147`). The report does not name its model.
- **Opus** (`claude-opus-5-5`) — `raw/opus.md`, sha256 `968006a7…`, 986 lines, 10 H3 fields
  with two bundle members (M1 engine, M2 placement). Recommends **ast-grep 0.45.3 with five
  template-owned rules**, at pre-commit plus a `hygiene` step. Ranked runner-up: opengrep,
  then Semgrep. No `CONFLICT:`, no `BASELINE-REVIEW:` (an observation passed to F027's owner).
  It executed stdin fixtures, exit codes, exclusions, the zero-file signal and the tokio
  timing (`raw/opus.md:892-903`).
- **No evidence-check leg.** R31 is Focused. No Doxa leg is required.
- **Engine identity gap (recorded, not resolved here).** `manifest.json` lists
  `required_engines: ["codex", "opus"]` and an empty `operations` map. The first leg on disk is
  `raw/muse.md`, but neither the run's `inputs/EXECUTION.json` nor the live
  `research/EXECUTION.json` has an `engine_overrides` entry for R31. RUNBOOK names the
  sanctioned Muse-for-Codex substitutions, and R31 is not among them (`research/RUNBOOK.md:70-72`).
  The execution ledger does record R31's legs as collected, in the entry headed
  `S5 HANDOFF VERIFIED, 2026-09-27` (`docs/planning/p02/execution-ledger.md:1207` at synthesis
  time; see the working-tree note below). This reads as a recording omission, not an
  undispatched leg.
  This synthesis treats `raw/muse.md` as one of the run's two legs because the dispatch said to. The
  controller should record the substitution, or say why none is needed, before acceptance.

**Where the legs agree.** Both find that no maintained, dedicated, bandit-style source scanner
exists for Rust (`raw/muse.md:57`, `raw/opus.md:82-86`). Both find that Rust's security tooling
concentrates on dependency scanning and language-level prevention. Both treat `cargo-audit` and
`cargo-deny` as dependency scanners in R13's lane, and so not the bandit analogue, which
answers the MEDIUM question (`raw/muse.md:31`, `raw/opus.md:477-481`). Both find that Rust
eliminates bandit's `eval`/`exec` and unsafe-deserialization classes. Both count the Semgrep
community Rust security rules at 10, which E4 re-confirms. Both reject Rudra and MIRAI as
archived, and E4 re-confirms both. Both decline `cargo-geiger`. Both place the question at the
capability level, not the tool level. Neither emits a `CONFLICT:`.

**Disagreement 1 — adopt a scanner, or document the gap? Settled for adopting ast-grep.** This
is the item's central question. The Muse leg's case rests on one premise: the composition "has
scanners at every lane" and so satisfies "make sure there's a security scanner"
(`raw/muse.md:39`). Four pieces of evidence defeat that premise.

1. *CodeQL does not run on every instance.* F027 gates CodeQL to public repositories, and "public-only is a
   selected policy, not an availability check" (`docs/port/COMMONALITY.md:33`). R16 records
   that CodeQL's own terms restrict where analysis may run, "which F027's visibility gate
   encodes" (`research/topics/16-codeql-config-customization/DECISION.md:110`). On a private
   instance the Muse composition therefore has no first-party SAST. R17's TruffleHog finds
   secrets, and R13 finds vulnerable dependencies; neither inspects first-party code for
   insecure patterns. The Muse leg never mentions F027.
2. *The owner's direction asks for the capability for Rust by name:* "Make sure there's a
   security scanner … Same thing with Rust" (`docs/port/OWNER-REVIEW.md:259`).
3. *The ts precedent is a deferral, not a rejection.* The Muse leg read only the prompt's
   quotation of D-014(5)'s rationale line. D-014(5) itself says "eslint-plugin-security
   deferred until Oxlint JS plugins leave alpha"
   (`ts@cb1cbcb2:docs/port/TS_PORT_DECISIONS.md:131`), and its reason is that no tool was
   available (`:139`). The Opus leg read the source (`raw/opus.md:58-64`). ts would have
   adopted a scanner if one had existed; for Rust, one exists.
4. *The Muse leg never evaluated the engine the Opus leg selected.* ast-grep and opengrep
   appear nowhere in `raw/muse.md`. Its three-bin map lists only `cargo-geiger`, Semgrep, the
   SCA tools, and the research prototypes (`raw/muse.md:7-17`). Its conclusion that no candidate
   "with fit" exists (`raw/muse.md:116`) therefore covers a narrower field than the Opus leg's.

What the Muse leg gets right is kept. The rule set is template-authored, with no production
security precedent, so confidence in its long-term value stays **medium**. CodeQL overlaps
three of the five rule classes on public repositories. This decision records that overlap as
two complementary layers — deep but CI-only and public-only, against shallow but local and
plan-independent — and does not claim a redundancy-free design.

**Disagreement 2 — how many Rust security queries CodeQL runs. Settled at 18.** The Opus leg
says "19 Rust security queries at bundle 2.26.4" (`raw/opus.md:73`). R16's executed
resolution records 16 for the default suite, **18 for `security-extended`** (the suite R16
adopted), and 19 only for `security-and-quality`, which R16 excluded
(`research/topics/16-codeql-config-customization/evidence/2026-09-05T163018Z-61c8f49b581d-resolve-queries.log`,
lines 5, 25 and 47). The Opus leg's figure is the wrong suite's count. The class mapping it
built does not depend on the count, and it survives the correction.

**Disagreement 3 — whether CodeQL already screens command handling. Settled: not at the
pin.** The Muse leg says the residual classes, "command-argument handling" first among them,
are "exactly what the adopted CodeQL `security-extended` suite already screens"
(`raw/muse.md:29`). R16 records that `rust/command-line-injection` is absent at
`codeql-cli/v2.26.4` and first present at `v2.27.0`
(`research/topics/16-codeql-config-customization/DECISION.md:100`). The resolve log has no
`CWE-078` entry at 2.26.4. The Muse leg also treats R16's two-query *delta* over the default
suite (`rust/log-injection`, `rust/access-after-lifetime-ended`) as if it were CodeQL's whole
Rust coverage ("two Rust queries beyond the default suite", `raw/muse.md:84`). Those are
different quantities. Predictable temp files have no CodeQL query at either bundle. So at
the pin, two surviving bandit classes are unscreened by CodeQL even on public repositories.

**Disagreement 4 — which engine. Settled for ast-grep.** The Muse leg did not consider it. The
Opus leg selects it (`raw/opus.md:196-205`) and ranks opengrep second and Semgrep third. The
deciding evidence is as follows.

- ast-grep is the only rule engine surveyed that is a crates.io crate. R42's standing rule
  for consuming items is "prefer a crates.io-published tool; a release-only tool must justify
  itself" (`research/topics/42-dev-toolchain-provisioning/DECISION.md:29`). Semgrep has no
  crate (`raw/muse.md:92`), and opengrep ships release binaries only (`raw/opus.md:448-452`).
- Semgrep's community Rust rules are 10 files (E4) under a non-SPDX "Semgrep Rules License
  v1.0" whose terms neither leg retrieved (`raw/opus.md:453-462`). Vendoring them is not
  established. Fetching them at scan time would make the hook network-dependent.
- opengrep's own rule repository is archived (E4). Its rules would be template-owned too, so
  it offers no rule advantage over ast-grep. Its advantage is intra-procedural dataflow, which
  is the stated trigger for switching to it.
- ast-grep's speed was measured (E3); opengrep's and Semgrep's were not.

Both legs' licence notes on LGPL-2.1 are moot under the 2026-09-12 ruling
(`docs/planning/p02/execution-ledger.md:495`).

**Disagreement 5 — hook tier (F115). Settled for pre-commit.** The Muse leg calls F115 moot,
because it adopts no tool. Where it does give conditional guidance, it keeps py's pre-push
(`raw/muse.md:84`). The Opus leg selects pre-commit on its measured timing
(`raw/opus.md:673-677`). E3 reproduces that timing: 555 files in 0.09–0.13 s of wall time over 5 runs.
py's stated reason for pre-push was cost (`py@b08bccfb:lefthook.yml:157-158`), and at this
cost that reason does not apply. The Opus leg's runner-up tier, pre-push, stays the fallback
if a future rule set or engine takes more than about a second on the template.

**Disagreement 6 — how to categorize `cargo-geiger`. No effect on the outcome.** The Muse leg
shortlists it, since it passes all six gates, and rejects it on fit (`raw/muse.md:61-72`). The
Opus leg calls it out of category (`raw/opus.md:482-483`). Both decline it for the same
reason: under R06's `forbid`, its first-party census is always empty, and its
dependency-tree census belongs to R13. R06 already records geiger as out of scope and unfit,
citing open issue #539 (`research/topics/06-unsafe-code-policy/DECISION.md:53`). E4 shows
#539 is still open. This decision lists geiger as out of category, as A6 in the alternatives
table.

**Disagreement 7 — Semgrep as runner-up (Muse) versus third (Opus). Settled for third.** The
reasons are in Disagreement 4. The Muse leg's ranking rested on Semgrep matching
vulnerability patterns, which geiger does not. That comparison does not reach opengrep, which
the Muse leg did not evaluate.

**Disagreement 8 — what the ts precedent licenses.** Settled within Disagreement 1, item 3.

**Disagreement 9 — the Opus leg's rule patterns miss ordinary call forms. Found by this
synthesis and repaired.** This is not a disagreement between the legs; it is a defect in the
selected leg. The patterns the Opus leg executed match literal path spellings only
(`raw/opus.md:287-295`). E1.6 runs them on a probe file with 15 insecure lines, and they flag
6. They miss `std::process::Command::new("sh")`, `tokio::process::Command::new("bash")`,
`Command::new("/bin/sh")`, `env::temp_dir()`, an imported `temp_dir()`, `md5::Md5::new()`,
`sha1::Sha1::new()`, `Sha1::default()`, and `query(format!(..).as_str())`. The Opus leg itself
warns that "a scanner with no rules would be a placebo" (`raw/opus.md:537-539`). A rule
bypassed by writing the full path is close to that. This decision widens every pattern to key
on the final path segments through `constraints` regexes, and E1.5 flags all 15 lines while
leaving the 5 safe counterparts unflagged. Each new form is also an `invalid:` case in the
committed tests, so a future narrowing fails `ast-grep test`. The misses that remain are the
ones no syntactic engine can close — a shell name or SQL text carried in a variable — plus a
type renamed on import (E1.5, probe lines 27–29). The last could be narrowed by a rule per
common alias, but no alias is predictable, so it is recorded rather than chased.

**Disagreement 10 — the Opus leg's recipe fails on a clean tree. Found by this synthesis and
repaired.** The recipe runs a bare `ast-grep test` (`raw/opus.md:704`). With no snapshot
baselines, that command exits 4 ("0 passed; 5 failed", mismatching snapshots, E2.6). As
written, `just security` would therefore fail on every tree. qdrant, the reference
implementation the Opus leg cites, passes `--skip-snapshot-tests` (E4, `rust-lint.yml`
line 60). This decision adds the flag. The Opus leg noted that its recipe "was not run as a
`just` recipe" (`raw/opus.md:711-712`), and this is the defect that gap concealed. The
synthesis also found a placebo the Opus guard does not catch: deleting every rule and test
passes both `ast-grep test` and the scan (E2.5a, E2.5b). The recipe now fails on
`effectiveRuleCount=0` (E2.5c).

**Disagreement 11 — the consumed R11 value.** The Muse leg's quotation of `ci-job-structure`
(`raw/muse.md:102`) differs from the registry by two inserted words, "a" and "only". It reads
"skipped by a path filtering" and "compiles only what check already compiles". The Opus
leg's quotation (`raw/opus.md:867`) is byte-identical to the registry. This decision's
`assumes` line is extracted from `inputs/parameters.json` and verified byte-exact (E5). Both
legs agree that the scan lands in `hygiene` with no `CONFLICT:`.

**Gaps, stated rather than smoothed.**

- *No production precedent for security rules on ast-grep.* The adopters found — nushell,
  qdrant, swc, tabby — run ast-grep for project conventions (`raw/opus.md:112-131`; only
  qdrant's CI wiring was re-read here, in E4). The five rules are template-authored, and their
  value rests on the executed fixtures, not on practice.
- *Linux not executed.* Gate 4 rests on the published Linux assets and qdrant's
  `ubuntu-latest` job. The `hygiene` step (A9) and the lefthook job on Linux are P03's.
- *Not re-collected here:* issue responsiveness (carried from `raw/opus.md:393`); the practice
  spot-checks of ruff, zed, ripgrep and uv, which the Opus leg ran under a code-search rate
  limit (`raw/opus.md:132-138`); and the annual Rust survey, which neither leg consulted.
- *Open dependencies.* R13, R28 and R37 have no published decision. Every coupling to them is
  an assumption: R13 owns dependency scanning, R28 owns clippy's security-adjacent lints, and
  R37 owns the hook manager and `lefthook.yml`'s shape. A R28 selection that denies one of the
  five patterns is a re-verify trigger.
- *Install path on the runner.* R42 names no CI install action for tools yet. ast-grep carries
  `package.metadata.binstall` (E4), but `cargo binstall ast-grep@0.45.3` was not executed.
- *A sixth rule, bind-all interfaces (B104),* is a reasonable web-service rule. It was
  neither written nor executed, and it is left for P03 once R69's listener code exists.
- *Engine identity.* See the gap recorded at the top of this section.

**Working-tree basis of this synthesis.** Several inputs exist only as uncommitted
working-tree content at synthesis time (2026-09-26); the last commit is `e0b0d1c1`. R11's
`DECISION.md` and `acceptance.json` are untracked. `docs/port/PARAMETERS.md`,
`research/RUNBOOK.md`, `research/EXECUTION.json`, `research/CLAUDE.md` and the execution
ledger carry uncommitted edits. At `HEAD`, the registry's `ci-job-structure` value differs from
the run's frozen `inputs/parameters.json`, and `research/RUNBOOK.md:70-72` reads differently.
This decision binds to the run's frozen inputs, which match the working tree (E5.1, E5.2). The
hashes E5 records pin the exact content cited. Ledger line numbers past the committed part can
drift as entries are appended, which is why the handoff entry is also cited by its heading.

**What this synthesis read, and what it did not.** Beyond the run directory, the RUNBOOK
contract, the item prompt and R11's decision, it read the following, to verify a citation or
for context: R06, R16 and R42's `DECISION.md`, R16's resolve-queries log, R13's prompt,
`docs/port/COMMONALITY.md`, `OWNER-REVIEW.md` and `DIVERGENCE-ANALYSIS.md`, the execution
ledger, `docs/port/PARAMETERS.md`, `research/EXECUTION.json`, `research/CLAUDE.md`, R11's
candidate workflow, and the py and ts clones at their pins. For conventions it also read
R53's `DECISION.md`, one R10 evidence script and `scripts/research_validation.py`. It opened
no audit file, no other item's `raw/`, and no `research/topics/31-*/raw/`.

**What P03 must validate.** (1) `ast-grep test --skip-snapshot-tests` and `just security` pass
on the real template on `ubuntu-latest` and `macos-latest`. (2) A seeded
`danger_accept_invalid_certs(true)` in the web member turns the `hygiene` step red, and the
same line under `tests/` does not (A9). (3) The lefthook job behaves as in E2.7 under R37's
layout. (4) `cargo binstall --locked --no-confirm ast-grep@0.45.3` installs a prebuilt binary
on both runners. (5) The first full scan of the real template is triaged; any finding is
either fixed or suppressed inline with a reason.
