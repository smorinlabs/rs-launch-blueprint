## Reasoning Summary
**Evaluating candidate stacks**

I'm considering candidates like clap 4.5.x, serde 1.0.x, and toml 0.9. Should I also look into secrecy 0.10 and tracing 0.1? I need to determine the exact specifications. R56 seems to own the token source and the associated permission warning, which makes me think about a reference pattern with existing stack members. I need to recommend specific named crate versions and think through different approaches carefully, balancing security principles with operational usability.

### Landscape

**Research cutoff and retrieval date:** September 17, 2026. Rust **1.98.1**, released September 3, 2026, is the current stable toolchain; therefore the owner’s “stable minus two minor versions” policy currently yields `rust-version = "1.96"`. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

**Category decided:** local credential-source policy for a layered Rust application configuration, including at-rest exposure controls and startup diagnostics.

#### Three-bin map

| Bin | Approaches found | Disposition for R56 |
|---|---|---|
| **Built-in / first-party toolchain** | Explicit Rust provider-chain function; `std::fs::File`; Unix `std::os::unix::fs::PermissionsExt`; Cargo’s flag/environment/credentials-file pattern | **Shortlisted and selected.** It provides the exact behavior without a new dependency. Cargo is the strongest first-party precedent, although it prefers a separate `credentials.toml` rather than mixing secrets with ordinary configuration. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html)) |
| **Established industry standard** | Explicit value > environment > user credential/config file; separate credential file; OS keyring with plaintext fallback; mounted secret files; deterministic provider chains | **Policy evidence.** AWS, Cargo and GitHub tools all support persisted credentials below explicit/environment sources, while generally preferring a dedicated credentials file or OS credential store. ([docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)) |
| **Up-and-comer / higher-assurance direction** | External credential-provider processes, OS keyrings, systemd service credentials, secret references rather than literal values, dynamic secret managers | **Future enhancement, not this item.** These reduce plaintext persistence or environment inheritance but would add capability and dependency ownership beyond R56. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/credential-provider-protocol.html)) |

Generic configuration-merger crates, keyring crates and secret-wrapper crates were deliberately not promoted into the R56 bundle: R53 owns schema validation, R54 owns discovery/merging, F246 owns secret-display masking, and R58/R59 own the logging pipeline. Adding dependencies for those concerns from R56 would violate the stated ownership boundary.

#### Authority used

| Authority | Why it counts |
|---|---|
| Rust standard-library documentation | Normative source for `PermissionsExt`, Unix availability and the ACL limitation of mode-bit inspection. `https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html`; `https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html`; retrieved 2026-09-17. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html)) |
| Cargo Book and Cargo authentication documentation | First-party Rust toolchain precedent for persistent tokens, environment overrides, command-line overrides and credential providers. `https://doc.rust-lang.org/cargo/reference/config.html`; `https://doc.rust-lang.org/cargo/reference/registry-authentication.html`; retrieved 2026-09-17. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/reference/config.html)) |
| Rust CLI Working Group book | Rust working-group output establishing the relevant CLI/configuration ecosystem, although the surveyed material contains no normative “tokens must/must not be in config” rule. `https://rust-cli.github.io/book/index.html`; retrieved 2026-09-17. ([github.com](https://github.com/rust-cli/book)) |
| AWS CLI and AWS SDK for Rust documentation/source | Vendor-maintained production provider chains with environment-before-file behavior. `https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html`; `https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs`; retrieved 2026-09-17. ([docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)) |
| GitHub CLI documentation | Mainstream CLI evidence for secure-store-first behavior, environment use in automation, and plaintext-file fallback when necessary. `https://cli.github.com/manual/gh_auth_login`; retrieved 2026-09-17. ([cli.github.com](https://cli.github.com/manual/gh_auth_login)) |
| OWASP, MITRE CWE and systemd credentials documentation | Independent security perspectives: plaintext storage creates exposure; environment variables also have leakage/inheritance risks; restrictive files or dedicated credential files can be acceptable bounded mechanisms. `https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html`; `https://cwe.mitre.org/data/definitions/312.html`; `https://github.com/systemd/systemd/blob/main/docs/CREDENTIALS.md`; retrieved 2026-09-17. ([cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)) |

#### Practice evidence

| Project/tool | Standing and observed practice | Relevance |
|---|---|---|
| **Cargo** | Rust’s first-party package manager stores registry tokens in a dedicated TOML credentials file, accepts environment tokens, supports `--token`, and now documents OS credential providers with plaintext-token fallback. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-login.html)) | Strong Rust precedent for a three-tier chain, but also evidence that separating credentials from ordinary configuration is preferable when scope permits. |
| **AWS SDK for Rust / AWS CLI** | Official AWS implementations search environment variables before shared credential/config files; the SDK chain stops at the first valid provider. ([github.com](https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs)) | Strong production precedent for deterministic environment-before-file credential resolution. |
| **GitHub CLI** | Official CLI uses the OS credential store first, environment tokens for headless use, and can fall back to plaintext configuration. Its issue tracker also shows that users consider silent plaintext fallback controversial. ([cli.github.com](https://cli.github.com/manual/gh_auth_login)) | Supports file storage only as a bounded fallback, not as equivalent to a keyring. |
| **systemd credentials** | Supplies service credentials as access-controlled files and explicitly avoids propagating secret contents down the process environment. ([github.com](https://github.com/systemd/systemd/blob/main/docs/CREDENTIALS.md?plain=1)) | Evidence that “environment is always safer than file” is not a sound general rule, especially for services. |
| **Rust CLI WG** | Covers configuration and diagnostics but, in the material surveyed, does not prescribe whether an authentication token may be stored in configuration. ([github.com](https://github.com/rust-cli/book)) | There is no Rust-specific style-guide mandate deciding ADR-0002 versus the TS policy. Cargo is the closest first-party second opinion. |

**Metric applicability:** the recommended R56 bundle contains project-authored patterns plus the first-party standard library, not a crates.io dependency. Therefore 90-day downloads, all-time downloads, crate release dates, repository stars, open issues, issue responsiveness, RustSec package advisories and reverse-dependency adopters are **inapplicable**, not omitted. The optional `tracing` adapter remains owned by R58/R59 and is not an R56 bundle member.

### Principles and implementation

#### Shared principle and required agreement level

The principle behind Python ADR-0002 is **secret-source minimization and non-persistence**: if the schema cannot represent a token, ordinary configuration cannot accidentally become a plaintext credential store.

The principle behind the TypeScript design is **deterministic, usable credential acquisition with defense in depth**: a persistent local source is permitted for unattended use, but explicit and ephemeral sources override it, writes are restrictive, and unsafe mode bits produce a visible warning.

The shared higher-level requirement should be:

> **Minimize unnecessary credential exposure while providing an explicit, deterministic and testable credential-provider chain whose risks are visible to operators.**

The required agreement levels are:

| Level | Must agree across Python, TypeScript and Rust | May vary by ecosystem |
|---|---|---|
| **Product policy** | Whether a file token is a supported capability; exact precedence; what “unset” means; whether unsafe file permissions are non-fatal | Nothing language-specific justifies different product policy here |
| **Architectural pattern** | Resolve once at startup; preserve source provenance; never log the token; emit permission diagnostics during loading rather than during every read | Data structures and bootstrap sequencing |
| **POSIX standard** | If a secret-capable file is supported on Unix, `mode & 0o077 != 0` means group/other bits are present | Python `stat`, Node `fs.stat`, Rust `PermissionsExt` |
| **Library implementation** | Observable outcomes and warning code/message intent | Parser crate, secret wrapper, logging facade and error types remain separately owned |

Python and TypeScript do not have materially different file, environment or command-line threat models that justify opposite token-source policies. Their present difference is therefore a **product-policy divergence**, not a necessary ecosystem adaptation.

#### Architectural alternatives

| Architecture | Security properties | Usability and template fit | Decision |
|---|---|---|---|
| **Flag and environment only** | Avoids a sanctioned persistent token in configuration. It does not make the flag safe from shell history/process inspection, nor the environment safe from inheritance, dumps or accidental logging. OWASP and systemd both document environment-related exposure. ([cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)) | Good for CI and orchestrated services; poor for a durable local CLI login unless a keyring/helper also exists. Users may create unofficial `.env` or shell-script persistence instead. | **Runner-up.** Choose only if the owner threat model becomes “no persistent plaintext credentials anywhere.” |
| **Token in the normal user config, lowest precedence** | Plaintext at rest and susceptible to same-user malware, backups, synchronization or accidental source control. A `0600` write policy and mode warning reduce accidental cross-user exposure but do not make it a vault. ([cwe.mitre.org](https://cwe.mitre.org/data/definitions/312.html)) | Minimal implementation, supports local unattended CLI use and is compatible with a service overriding it through environment injection. | **Recommended within the two allowed choices.** |
| **Separate credentials file** | Better semantic boundary; easier to exclude from checked-in configuration; still plaintext unless combined with a credential provider. Cargo and AWS prefer this organization. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/reference/config.html)) | Strong long-term fit, but creates a new discovery/lifecycle concern outside R56/R54. | Future architectural improvement; not silently substituted here. |
| **OS keyring or external credential provider** | Better at-rest protection and central lifecycle management; availability and headless behavior vary. Cargo and GitHub use or recommend this direction. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)) | Best local-desktop default, but adds login, failure and platform behavior outside the fixed scope. | Future additive tier, requiring a new owner decision. |
| **Mounted/ephemeral credential file or secret manager** | Strong service deployment pattern; avoids long-lived environment inheritance and can use dynamic credentials. ([cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)) | Deployment-specific and unsuitable as the only local CLI mechanism. | Operational guidance for the web service, not an R56 source tier. |

#### Decision

**Adopt the TypeScript product shape for Rust:**

1. The config schema **does have an optional `token` field**.
2. Resolve once using **non-empty flag > non-empty environment variable > R54-resolved file token**.
3. The file source remains optional and lowest precedence.
4. Every physical config file loaded by R54 is checked once at load time.
5. On Unix, emit a non-fatal warning when `mode & 0o077 != 0`.
6. The warning never alters token selection, startup success or R67’s exit code.
7. The warning is buffered as a typed diagnostic and emitted once by the application’s R58/R59 logging/diagnostic adapter.
8. Repeated access to the resolved token emits nothing.

This is not a claim that plaintext configuration is secure. It is a deliberately supported convenience source with explicit limits. Production web-service documentation should prefer orchestrator credentials, a mounted secret file or environment injection over committing a token to ordinary configuration. ([cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html))

#### R54 composition

“Config file” means **one file-source candidate after R54 has completed its own selection or merge policy**:

```text
R54 discovers and loads physical files
    ├── R56 checks each loaded physical file's mode once
    └── R53/R55 parse, validate and merge them
             └── one resolved file token + provenance
flag candidate ─┐
env candidate  ─┼── R56: flag > env > resolved file candidate
file candidate ─┘
```

R56 must not assign an extra credential priority to every discovery layer. Otherwise R54’s merge contract would be duplicated inside credential resolution. It should consume:

```rust
struct ResolvedFileToken<T> {
    value: Option<T>,
    // Provenance is retained for diagnostics, but it does not form another
    // priority tier inside R56.
    source_path: Option<PathBuf>,
}
```

Permission checks remain per physical loaded file, including shadowed layers, because an overridden token can still be exposed on disk. If R54 selects only one file rather than merging, this naturally becomes one check.

#### Rust reference pattern

The resolver should be explicit rather than hidden inside a generic configuration merger:

```rust
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TokenSource {
    Flag,
    Environment,
    ConfigFile,
}

#[derive(Debug)]
pub struct ResolvedToken<T> {
    pub value: T,
    pub source: TokenSource,
}

/// Apply this only to flag and environment inputs, preserving F242.
/// Do not trim: the fixed rule says an empty string is unset, not that
/// arbitrary whitespace may be rewritten.
pub fn non_empty(raw: Option<String>) -> Option<String> {
    raw.filter(|value| !value.is_empty())
}

pub fn resolve_token<T>(
    flag: Option<T>,
    environment: Option<T>,
    file: Option<T>,
) -> Option<ResolvedToken<T>> {
    if let Some(value) = flag {
        return Some(ResolvedToken {
            value,
            source: TokenSource::Flag,
        });
    }

    if let Some(value) = environment {
        return Some(ResolvedToken {
            value,
            source: TokenSource::Environment,
        });
    }

    file.map(|value| ResolvedToken {
        value,
        source: TokenSource::ConfigFile,
    })
}
```

The generic `T` lets F246’s existing secret wrapper remain authoritative. R56 does not introduce another `SecretString` type or masking implementation.

The file check should inspect the same opened file handle that is subsequently read:

```rust
use std::{
    fs::File,
    io::{self, Read},
    path::{Path, PathBuf},
};

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ConfigWarning {
    LoosePermissions {
        path: PathBuf,
        /// Permission bits only, for safe octal display.
        mode: u32,
    },
}

#[cfg(unix)]
fn loose_permission_mode(file: &File) -> io::Result<Option<u32>> {
    use std::os::unix::fs::PermissionsExt as _;

    let mode = file.metadata()?.permissions().mode();
    Ok(((mode & 0o077) != 0).then_some(mode & 0o777))
}

#[cfg(not(unix))]
fn loose_permission_mode(_file: &File) -> io::Result<Option<u32>> {
    // Generic non-Unix fallback. No cfg(windows) branch is needed.
    Ok(None)
}

pub struct LoadedConfigText {
    pub contents: String,
    pub warnings: Vec<ConfigWarning>,
}

pub fn load_config_text(path: &Path) -> io::Result<LoadedConfigText> {
    let mut file = File::open(path)?;
    let mut warnings = Vec::new();

    if let Some(mode) = loose_permission_mode(&file)? {
        warnings.push(ConfigWarning::LoosePermissions {
            path: path.to_owned(),
            mode,
        });
    }

    let mut contents = String::new();
    file.read_to_string(&mut contents)?;

    Ok(LoadedConfigText { contents, warnings })
}
```

`PermissionsExt` is a stable, Unix-only standard-library trait providing `mode()`. Both `ubuntu-latest` and `macos-latest` compile the Unix implementation. A crate such as `rustix` can obtain the same `stat` data, but it adds a dependency and an `fs` feature without improving this exact mode-bit check. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html))

The generic `#[cfg(not(unix))]` function is the clean no-op. There is no Windows-specific branch, and the owner-fixed CI matrix never exercises the no-op because both targets are Unix.

#### Permission-check guarantee and limits

The exact condition is:

```rust
(mode & 0o077) != 0
```

That warns for any group/other read, write or execute bit. It does **not** require the file to be exactly `0600`: `0400` and `0700` pass the TS-compatible condition, whereas `0640`, `0604` and `0660` warn.

The check intentionally does not:

- inspect owner bits beyond displaying them;
- change permissions automatically;
- reject the token;
- inspect parent-directory permissions;
- detect backup, synchronization or source-control copies;
- protect against root or another process running as the same user;
- inspect POSIX ACLs.

Rust’s standard-library documentation explicitly notes that mode-bit APIs do not account for ACLs or all effective-access nuances, including on macOS. Therefore the warning is a useful defense-in-depth diagnostic, not proof that only the owner can read the secret. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html))

#### Warning mechanism

R56 should return typed warnings from the library. The CLI/web-service application should emit them after R58/R59 initializes the logging pipeline:

```rust
pub fn emit_config_warning(warning: &ConfigWarning) {
    match warning {
        ConfigWarning::LoosePermissions { path, mode } => {
            tracing::warn!(
                target: "rs_launch_blueprint::config",
                warning_code = "config_file_permissions_too_open",
                config_path = %path.display(),
                actual_mode = %format_args!("{mode:04o}"),
                recommended_mode = "0600",
                "config file permits group/other access and may contain an authentication token"
            );
        }
    }
}
```

This adapter is illustrative and belongs at the application boundary. `tracing` 0.1.44 is the current maintained reference release and does not require the Tokio runtime, but R58/R59 retains dependency/version ownership. ([docs.rs](https://docs.rs/crate/tracing/latest/source/README.md))

Emission semantics:

- once per loaded physical file per configuration load;
- a deliberate hot reload may warn again;
- never from a token getter;
- no token value or masked prefix in the warning;
- warning remains non-fatal;
- library consumers can inspect warnings even without a logging subscriber.

#### Observable acceptance criteria

1. **AC-R56-01:** R53’s file schema contains optional `token`.
2. **AC-R56-02:** non-empty flag, environment and file values resolve to the flag.
3. **AC-R56-03:** absent/empty flag plus non-empty environment and file values resolve to environment.
4. **AC-R56-04:** absent/empty flag and environment plus valid file value resolve to file.
5. **AC-R56-05:** no candidate produces the R67-owned missing-token error with three remedies: flag, inherited environment variable and config `token`.
6. **AC-R56-06:** `ResolvedToken.source` reports `Flag`, `Environment` or `ConfigFile` without exposing the value.
7. **AC-R56-07:** mode `0600` produces no permission warning.
8. **AC-R56-08:** modes with any `0o077` bit produce exactly one warning and continue successfully.
9. **AC-R56-09:** mode `0700` produces no warning, proving the check is the exact TS-compatible mask rather than equality with `0600`.
10. **AC-R56-10:** reading the resolved token repeatedly produces no additional warning.
11. **AC-R56-11:** warning output does not contain any supplied test token.
12. **AC-R56-12:** R54 merging occurs before file-token source selection; physical-file permission diagnostics remain per loaded file.
13. **AC-R56-13:** the Unix check runs on both fixed CI operating systems; a generic non-Unix build compiles to a no-op without `cfg(windows)`.
14. **AC-R56-14:** loose permissions do not change the selected credential or R67 exit status.

#### Performance and integration cost

The evaluated workload is startup loading of `N` physical configuration files, one token resolution and arbitrary subsequent CLI/service token reads. The design adds one metadata query per loaded file and three constant-time `Option` checks. It adds no request-path work, async runtime, background task or persistent resource. Instrumentation should count loaded files, permission assessments and emitted warning codes; no comparative benchmark was run, and no “fastest” claim is made. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html))

#### Baseline review

`BASELINE-REVIEW: F239 — credential-source availability is a cross-repo product policy — add an optional Rust file token and propose reopening Python ADR-0002 in a follow-on; leave the ledger unchanged until approved — Cargo, AWS and GitHub provider chains support bounded persistent fallback, while OWASP/MITRE establish its residual plaintext risk.` ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/reference/config.html))

`BASELINE-REVIEW: F240 — deterministic override order should agree across ecosystems — standardize non-empty flag > non-empty environment > R54-resolved file token — Cargo and AWS use explicit/environment sources ahead of credential/config files.` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/config.html))

`BASELINE-REVIEW: F245 — a secret-capable Unix file needs a visible defense-in-depth diagnostic — preserve the TS-compatible mode & 0o077 check and one-time non-fatal warning in Rust; apply to Python only if its policy later permits a file token — Rust std provides the exact mode-bit mechanism and documents its ACL limits.` ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html))

### Recommendation

Adopt the named bundle **`R56 explicit-chain / std-posix-mode / buffered-warning v1`**:

- **Policy:** config file may carry an optional auth token.
- **Precedence:** non-empty flag > non-empty environment > R54-resolved file token.
- **Permission mechanism:** Rust standard library `std::os::unix::fs::PermissionsExt`; no permission crate.
- **Check:** `(mode & 0o077) != 0`.
- **Warning:** typed, non-fatal, once per physical file per config load; application adapter emits through R58/R59.
- **Crate stack:** no new R56-specific third-party dependency.
- **Toolchain version:** edition 2024; `rust-version = "1.96"`; verify on Rust 1.96.1 and current stable 1.98.1.
- **Downstream logging reference only:** `tracing = "0.1.44"` if R58/R59 selects it; not owned or pinned by R56. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

### Members

#### explicit three-tier token resolver (R56 pattern v1)

##### Landscape

The relevant native approaches are an explicit `if let` chain, a generic provider trait/iterator, or allowing a generic config-merger to determine precedence. Cargo and AWS demonstrate explicit provider-chain semantics; the Rust Cookbook demonstrates ordinary layered configuration but does not address secret-specific provenance or diagnostics. ([github.com](https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs))

Crates.io and repository figures are **inapplicable** because this member is project-authored code, not a crate dependency.

##### Principles and implementation

The member implements product-policy agreement, deterministic first-match semantics and source provenance. Flag/environment empty strings are filtered before resolution; the file candidate is the single validated result produced by R53/R54/R55.

##### Dominant choice

A short explicit resolver is dominant for this use case because there are only three fixed providers and source provenance is part of the public behavior.

##### Qualified shortlist

| Pattern | License | MSRV | Advisory / unsafe | OS | Features/runtime | Build cost |
|---|---|---|---|---|---|---|
| Explicit `if let` resolver | Project’s `MIT OR Apache-2.0` | Rust 1.96 | RustSec inapplicable; no `unsafe` | Portable | None | Negligible |
| Generic internal `CredentialProvider` iterator | Project’s `MIT OR Apache-2.0` | Rust 1.96 | RustSec inapplicable; no `unsafe` required | Portable | None | Small, but unnecessary abstraction |

Both pass formal gates. The explicit function wins on fit and auditability.

##### Excluded by gate

No project-authored resolver pattern failed the six formal package gates. Generic config, keyring and secret-wrapper crates were excluded before package selection by **scope and dependency ownership**, not by popularity or an asserted maintenance defect.

##### Up-and-comers

A future credential-provider trait could support keyrings, external commands or workload-identity providers. Cargo’s credential-provider protocol is a maintained example of that architecture. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/credential-provider-protocol.html))

##### Fit for this template

The explicit function works identically in the CLI, library and web-service entry points. The library resolves once and returns a value/source pair; executables determine how missing-token errors map through R67.

##### Recommendation

Use the explicit generic `resolve_token<T>` function shown above. Do not delegate the token to a generic all-settings merge because that obscures the security-sensitive order and provenance.

##### Ranked runner-up

The two-tier Python policy, flag > environment, is the runner-up if the owner adopts a stronger requirement forbidding all persistent plaintext credentials.

##### Tradeoffs

The selected policy sanctions a plaintext local fallback and adds a `token` schema field. In return it supports unattended local use without requiring a new keyring/login subsystem. The risk must be documented rather than presented as secure storage.

##### Parameters

- `owns config-secret-policy = file-permitted`
- `owns token-resolution-precedence = non-empty flag > non-empty environment > R54-resolved file token`
- `owns token-source-provenance = Flag | Environment | ConfigFile`
- `assumes R67 error-taxonomy-exit-codes = missing-token classification and exit code remain R67-owned`

##### Migration implications

Add `TokenSource`, `ResolvedToken<T>`, the explicit resolver, file-source error remedies and table-driven tests. R53 must add the optional field; R54 must provide one merged candidate and provenance.

##### Validation strategy

Planned tests cover all eight presence/absence combinations, empty flag/environment values, source provenance and a missing-token error mentioning all three remedies. No implementation tests were executed during this research response.

##### Confidence & re-verify trigger

**Confidence: high** for the chain and architecture; **medium-high** for the product policy. Re-verify if R54 introduces repository-local or remotely supplied configuration, or if the owner changes the threat model to prohibit persistent plaintext.

##### Sources

- Cargo configuration and credentials, retrieved 2026-09-17: `https://doc.rust-lang.org/cargo/reference/config.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/reference/config.html))
- AWS SDK for Rust provider chain, retrieved 2026-09-17: `https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs`. ([github.com](https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs))
- AWS CLI precedence, retrieved 2026-09-17: `https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html`. ([docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html))
- Owner-supplied F239/F240/F242 evidence, received 2026-09-17: public URL not provided.

#### POSIX mode-bit probe (`std::os::unix::fs::PermissionsExt`)

##### Landscape

The native options are `PermissionsExt::mode()`, `MetadataExt::mode()`, or a syscall wrapper such as `rustix::fs::stat`. The first two are first-party and already expose the required Unix mode bits; `rustix` adds value only if broader descriptor/syscall control is required. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html))

Crates.io and GitHub package figures are **inapplicable** because the selected member is the standard-library `std` crate distributed with the Rust toolchain, not a crates.io package.

##### Principles and implementation

The check realizes least-privilege-at-rest as a visible diagnostic while preserving availability. It checks the opened file’s mode, does not mutate user files, and does not claim ACL-aware authorization.

##### Dominant choice

`file.metadata()?.permissions().mode()` via `PermissionsExt` is the smallest exact expression of the required TS-compatible condition.

##### Qualified shortlist

| Mechanism | License gate | MSRV gate | Advisory / unsafe gate | OS gate | Features/runtime | Cost |
|---|---|---|---|---|---|---|
| `PermissionsExt` | First-party toolchain; no added dependency | API stable since Rust 1.1; passes 1.96 | RustSec package check inapplicable; R56 code has no `unsafe` | Unix; active on Linux and macOS | None | No dependency |
| `MetadataExt` | Same | Same | Same | Unix; active on Linux and macOS | None | No dependency |

Both pass. `PermissionsExt` aligns directly with the prompt and reads clearly as a permission check.

##### Excluded by gate

Raw `libc` calls are excluded by the implementation’s unnecessary `unsafe` and platform-detail burden. No crates.io syscall wrapper failed a formal maintenance gate; they were not promoted because the standard library already satisfies the capability.

##### Up-and-comers

Descriptor-relative, no-follow and ACL-aware checks could provide stronger guarantees against namespace races and ACL grants. They would define a materially stronger security item rather than an implementation substitution for F245.

##### Fit for this template

The target matrix is entirely Unix. The library remains source-portable through one generic `#[cfg(not(unix))]` no-op and requires no Windows API or Windows caveat.

##### Recommendation

Use `std::os::unix::fs::PermissionsExt` and:

```rust
let mode = file.metadata()?.permissions().mode();
let loose = (mode & 0o077) != 0;
```

Display only `mode & 0o777`.

##### Ranked runner-up

`std::os::unix::fs::MetadataExt::mode()` is the ranked runner-up. It returns equivalent mode data but is a broader metadata API than needed.

##### Tradeoffs

Mode bits are simple, portable across the fixed matrix and match TypeScript. They do not evaluate ACLs or effective access and therefore cannot justify wording such as “only you can read this file.” ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html))

##### Parameters

- `owns loose-permission-condition = (mode & 0o077) != 0`
- `owns permission-check-platform-policy = active on cfg(unix), no-op on cfg(not(unix))`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- `assumes rust-version = 1.96`

##### Migration implications

Add a small Unix-gated helper in the config loader. Check each physical file handle once before parsing/merging. Do not add `nix`, `rustix`, `libc` or platform-specific Windows code.

##### Validation strategy

Planned Unix table:

| Mode | Expected |
|---:|---|
| `0600` | no warning |
| `0400` | no warning |
| `0700` | no warning |
| `0640` | warning |
| `0604` | warning |
| `0660` | warning |
| `0777` | warning |

Run on Ubuntu and macOS under both MSRV and stable. No filesystem tests were executed in this research response.

##### Confidence & re-verify trigger

**Confidence: very high.** Re-verify if Windows enters the required matrix, if owner requirements expand to ACL/effective-access checks, or if configuration is accepted from hostile writable directories.

##### Sources

- `PermissionsExt`, retrieved 2026-09-17: `https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html))
- `MetadataExt`, retrieved 2026-09-17: `https://doc.rust-lang.org/std/os/unix/fs/trait.MetadataExt.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.MetadataExt.html))
- Standard permission/ACL caveats, retrieved 2026-09-17: `https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html))
- `rustix::fs::stat` alternative, retrieved 2026-09-17: `https://docs.rs/rustix/latest/rustix/fs/fn.stat.html`. ([docs.rs](https://docs.rs/rustix/latest/rustix/fs/fn.stat.html))
- Owner-supplied F245 TypeScript mode check, received 2026-09-17: public URL not provided.

#### buffered one-shot configuration warning (diagnostic pattern v1)

##### Landscape

The alternatives are a typed warning returned by the library, a direct logging call inside the loader, or unconditional `stderr` output. `tracing` is the established Rust structured-diagnostics reference and is maintained by the Tokio project without requiring the Tokio runtime. ([docs.rs](https://docs.rs/crate/tracing/latest/source/README.md))

Crate metrics are **inapplicable** because the selected member is a project-authored diagnostic contract. `tracing` is an optional downstream adapter owned by R58/R59, not an R56 bundle dependency.

##### Principles and implementation

Libraries should not install a global logger or make diagnostic delivery depend on whether a subscriber happened to exist during parsing. Returning `ConfigWarning` values preserves observability and testability; the executable emits them after logging initialization.

##### Dominant choice

A buffered typed warning plus application-boundary adapter best serves a CLI + library + web-service template.

##### Qualified shortlist

| Pattern | License | MSRV | Advisory / unsafe | OS | Runtime/features | Cost |
|---|---|---|---|---|---|---|
| Return `Vec<ConfigWarning>` and emit at boundary | Project license | Rust 1.96 | RustSec inapplicable; no `unsafe` | Portable | None in core | One small vector at startup |
| Direct `tracing::warn!` in loader | Depends on R58/R59 | Compatible in principle | R58/R59 must audit selected version | Portable | No Tokio runtime required by `tracing` | Lower code, weaker library determinism |
| Direct `eprintln!` | Project license | Rust 1.96 | Inapplicable | Portable | None | Bypasses structured pipeline |

##### Excluded by gate

No project-authored pattern fails the package gates. A direct `tracing` dependency is excluded from R56 by dependency ownership, and unconditional `stderr` is rejected on architectural fit rather than license or maintenance.

##### Up-and-comers

A unified typed diagnostic sink could render the same warning as human text, JSON or telemetry while keeping the stable warning code `config_file_permissions_too_open`.

##### Fit for this template

- CLI: render after config-driven logging is initialized.
- Library: caller receives warnings without global side effects.
- Web service: emit once during startup, never per request.
- Tests: inspect typed values or capture one structured event.

##### Recommendation

Return `ConfigWarning::LoosePermissions { path, mode }` from loading and emit it once at the application boundary. Do not log inside `ResolvedToken::value`, an accessor or the HTTP client.

##### Ranked runner-up

A direct `tracing::warn!` call in the loader is acceptable only if R58/R59 guarantees a subscriber exists before config loading and library consumers accept side effects.

##### Tradeoffs

Buffering adds a small report type and bootstrap step. It prevents silently lost early warnings, avoids duplicate token-read warnings, and makes redaction tests independent of formatting.

##### Parameters

- `owns permission-warning-severity = warning`
- `owns permission-warning-fatality = non-fatal`
- `owns permission-warning-frequency = once per physical file per configuration load`
- `owns permission-warning-code = config_file_permissions_too_open`
- `assumes R58/R59 logging pipeline = supplies a user-visible startup-warning adapter`
- `assumes R67 error-taxonomy-exit-codes = warnings do not alter exit status`

##### Migration implications

Add `ConfigWarning`, `LoadReport` or an equivalent report object; initialize logging; then iterate through warnings exactly once. Preserve the warning for library callers even when no logging subscriber is installed.

##### Validation strategy

Planned tests attach a recording diagnostic sink, load a `0644` file, resolve/read the token repeatedly and assert exactly one warning event. The event fields must include path, mode and remediation, and must exclude every fake token value.

##### Confidence & re-verify trigger

**Confidence: high** for buffering; **medium** for the final adapter until R58/R59 is decided. Re-verify if logging initialization moves before config loading or if structured JSON diagnostics become a public interface.

##### Sources

- `tracing` 0.1.44 documentation, retrieved 2026-09-17: `https://docs.rs/crate/tracing/latest/source/README.md`. ([docs.rs](https://docs.rs/crate/tracing/latest/source/README.md))
- Tokio tracing repository and runtime-coupling statement, retrieved 2026-09-17: `https://github.com/tokio-rs/tracing`. ([github.com](https://github.com/tokio-rs/tracing))
- Rust CLI Working Group diagnostics scope, retrieved 2026-09-17: `https://github.com/rust-cli/team`. ([github.com](https://github.com/rust-cli/team))

### Compatibility

The members have no third-party feature or runtime interaction: the resolver and warning types are project code, and the permission probe is `std`. Compatibility is therefore primarily a toolchain/OS matrix rather than an inter-crate version problem.

| OS | MSRV lane | Stable lane | Expected implementation |
|---|---|---|---|
| `ubuntu-latest` | Rust 1.96.1 | Rust 1.98.1 | `cfg(unix)` mode check active |
| `macos-latest` | Rust 1.96.1 | Rust 1.98.1 | `cfg(unix)` mode check active |

`PermissionsExt` predates the MSRV by many releases, and edition 2024 is supported by the selected floor. Current stable/version dates are from the official Rust release record. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html))

Cargo and the AWS SDK for Rust are shared reference implementations for the provider-chain portion. There is an evidence gap for a maintained Rust project implementing the exact combination of normal config token + `mode & 0o077` warning + buffered diagnostic; therefore the integration test below is load-bearing rather than replaced by an adopter assertion.

**Status:** compatibility commands are proposed; they were not executed during this research response.

### Parameters

- `owns config-secret-policy = config file may carry an optional authentication token`
- `owns token-resolution-precedence = non-empty flag > non-empty environment > R54-resolved file token`
- `owns config-file-permission-condition = (mode & 0o077) != 0`
- `owns config-file-permission-warning = non-fatal, redacted, once per physical file per configuration load`
- `owns permission-check-mechanism = std::os::unix::fs::PermissionsExt`
- `owns non-unix-permission-policy = no-op through cfg(not(unix)); no Windows-specific branch`
- `assumes R67 error-taxonomy-exit-codes = missing-token remains an error; permission warning never changes exit status`
- `assumes rust-edition = 2024`
- `assumes rust-version = 1.96`
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release and tested in CI`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- `assumes license = MIT OR Apache-2.0`
- `assumes R53 config-schema-validation = validates and exposes an optional file token`
- `assumes R54 config-discovery-tiers = produces one resolved file candidate plus physical-file provenance`
- `assumes R58/R59 logging pipeline = can render a typed startup warning`

No `CONFLICT:` is required.

### Migration implications

Representative file-level changes:

| File/area | Change |
|---|---|
| `Cargo.toml` | Set edition 2024 and `rust-version = "1.96"` if not already fixed. Add **no R56-specific dependency**. |
| Config wire model owned by R53, e.g. `src/config/schema.rs` | Add optional `token` string field. Convert it promptly to the F246-owned secret representation after validation. |
| Config loader, e.g. `src/config/load.rs` | Open each R54-discovered file once, inspect its handle with `PermissionsExt`, buffer any warning, then read/parse it. |
| Token resolver, e.g. `src/auth/token.rs` | Add `TokenSource`, `ResolvedToken<T>`, empty flag/environment normalization and explicit three-tier resolution. |
| Diagnostics, e.g. `src/config/warning.rs` | Add stable `ConfigWarning::LoosePermissions` and warning code. |
| CLI/service bootstrap, e.g. `src/bin/*/main.rs` | Load config, initialize R58/R59, emit buffered warnings once, resolve token, then start command/service. |
| Missing-token error | Add the config-file remedy while retaining R67’s taxonomy and exit behavior. |
| Configuration documentation | State that file storage is plaintext convenience, recommend `0600`, warn against checked-in tokens, and recommend deployment credentials for production services. |
| Sample configuration | Include no live token. At most show a commented placeholder with a warning that it must not be committed. |
| Tests | Add precedence, permission-mode, warning-frequency, redaction and R54-composition tests. |
| `docs/port/COMMONALITY.md` / divergence analysis | Record the recommendation and `BASELINE-REVIEW` findings; do not change Python or its ADR silently. |
| Python follow-on | Reopen ADR-0002 if cross-repo policy convergence is approved. |
| TypeScript follow-on | Confirm its warning is once per loaded file, non-fatal and redacted; no policy change is otherwise required. |

### Validation strategy

**Executed during this response:** documentation/API research only. No repository checkout, compile, test or benchmark was available, so all commands below are **planned acceptance checks**.

#### Toolchain and static validation

Run on both `ubuntu-latest` and `macos-latest`:

```bash
rustup toolchain install 1.96.1
rustup toolchain install 1.98.1

cargo +1.96.1 check --workspace --all-targets
cargo +1.96.1 test --workspace --all-targets

cargo +1.98.1 check --workspace --all-targets
cargo +1.98.1 test --workspace --all-targets
cargo +1.98.1 clippy --workspace --all-targets -- -D warnings
cargo +1.98.1 fmt --all -- --check
```

Expected:

- edition 2024 builds at the declared MSRV;
- no R56 code contains `unsafe`;
- no non-Unix import leaks outside `#[cfg(unix)]`;
- no third-party R56 dependency appears in `cargo tree`.

Whole-project supply-chain check:

```bash
cargo audit
cargo tree -e features
```

The R56 member itself has no crates.io advisory surface; these commands verify the complete template graph.

#### Resolver integration tests

```bash
cargo test --workspace token_resolution
```

Required table:

| Flag | Environment | File | Expected |
|---|---|---|---|
| `flag` | `env` | `file` | `flag`, source `Flag` |
| absent | `env` | `file` | `env`, source `Environment` |
| absent | absent | `file` | `file`, source `ConfigFile` |
| `""` | `env` | `file` | `env` |
| absent | `""` | `file` | `file` |
| absent | absent | absent | R67 missing-token error with three remedies |

Use distinct fake values and assert the selected outbound authorization value through a fake local transport. Never print the selected token.

#### POSIX permission tests

```bash
cargo test --workspace --test config_secret_policy permissions_
```

A table-driven Unix test should create one file per mode and call `set_permissions`:

```rust
#[cfg(unix)]
#[test]
fn permission_mask_matches_policy() {
    // 0600, 0400, 0700 => no warning
    // 0640, 0604, 0660, 0777 => exactly one warning
}
```

Expected:

- warning condition is exactly `mode & 0o077`;
- loose mode does not prevent config parsing or file-token selection;
- warning contains the path, octal mode and recommended `0600`;
- warning contains none of the fake token’s bytes.

#### Warning-frequency test

```bash
cargo test --workspace --test config_secret_policy warning_is_once_per_load
```

Test sequence:

1. Load a `0644` config.
2. Capture one typed warning.
3. Resolve the file token.
4. Access/use the resolved token at least 100 times.
5. Assert warning count remains one.
6. Reload configuration deliberately.
7. Assert the new load produces one new warning.

#### R54 composition test

```bash
cargo test --workspace --test config_secret_policy merged_file_candidate
```

Given two R54 layers:

- user file has token `user`;
- higher-precedence explicit config file has token `explicit`;
- environment has token `env`.

Expected:

- R54 first resolves file candidate `explicit`;
- R56 resolves `env`;
- each loose physical file generates its own one-time warning;
- R56 never treats each physical layer as a separate tier above/below environment.

#### Logging adapter test

```bash
cargo test --workspace --test config_secret_policy warning_adapter
```

Attach a recording R58/R59 test sink and assert one event with:

```text
warning_code = config_file_permissions_too_open
actual_mode = 0644
recommended_mode = 0600
```

No token field, token fragment or authorization header may appear.

### Confidence & re-verify trigger

**Overall confidence: high (approximately 0.86).**

- **Very high:** `PermissionsExt`, `mode & 0o077`, Unix gating and no need for a permission crate.
- **High:** explicit three-tier resolver and R54 composition.
- **Medium-high:** choosing file-permitted over Python ADR-0002, because it is a product threat-model decision rather than a purely technical conclusion.
- **Medium:** final warning adapter until R58/R59 is settled.

Re-verify when any of these occurs:

1. R54 adds repository-local, remotely supplied or other lower-trust config tiers.
2. The owner changes the requirement to prohibit persistent plaintext secrets.
3. A keyring, credential-provider process or separate credentials file enters scope.
4. Windows enters the required OS matrix.
5. ACL-aware or hostile-directory guarantees become required.
6. Configuration hot reload becomes automatic rather than explicit.
7. R58/R59 cannot guarantee visible startup warnings.
8. The implementation occurs after stable Rust advances beyond 1.98; recompute the MSRV floor, but raise it only in a template minor release as required.
9. Python or TypeScript changes its credential policy before the Rust implementation lands.
10. Production deployments require dynamic/short-lived credentials rather than a static API token.

### Sources

All web sources below were retrieved on **September 17, 2026**.

1. Rust release announcements: `https://blog.rust-lang.org/releases/`. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
2. Rust release notes: `https://doc.rust-lang.org/releases.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/releases.html))
3. Rust `PermissionsExt`: `https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html))
4. Rust `MetadataExt`: `https://doc.rust-lang.org/std/os/unix/fs/trait.MetadataExt.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/std/os/unix/fs/trait.MetadataExt.html))
5. Rust permission and ACL caveats: `https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html))
6. Cargo configuration and credentials: `https://doc.rust-lang.org/cargo/reference/config.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/reference/config.html))
7. Cargo registry authentication: `https://doc.rust-lang.org/cargo/reference/registry-authentication.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/registry-authentication.html))
8. Cargo registries/token configuration: `https://doc.rust-lang.org/cargo/reference/registries.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/registries.html))
9. Cargo credential-provider protocol: `https://doc.rust-lang.org/cargo/reference/credential-provider-protocol.html`. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/credential-provider-protocol.html))
10. AWS CLI configuration precedence: `https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html`. ([docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html))
11. AWS credential/config files: `https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html`. ([docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html))
12. AWS SDK for Rust provider-chain source: `https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs`. ([github.com](https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs))
13. GitHub CLI authentication storage: `https://cli.github.com/manual/gh_auth_login`. ([cli.github.com](https://cli.github.com/manual/gh_auth_login))
14. GitHub CLI plaintext-fallback criticism: `https://github.com/cli/cli/issues/8954`. ([github.com](https://github.com/cli/cli/issues/8954))
15. OWASP Secrets Management Cheat Sheet: `https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html`. ([cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html))
16. OWASP Cryptographic Storage Cheat Sheet: `https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html`. ([cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html))
17. MITRE CWE-312: `https://cwe.mitre.org/data/definitions/312.html`. ([cwe.mitre.org](https://cwe.mitre.org/data/definitions/312.html))
18. systemd credentials design: `https://github.com/systemd/systemd/blob/main/docs/CREDENTIALS.md`. ([github.com](https://github.com/systemd/systemd/blob/main/docs/CREDENTIALS.md?plain=1))
19. Rust CLI Working Group book: `https://rust-cli.github.io/book/index.html`. ([rust-cli.github.io](https://rust-cli.github.io/book/index.html))
20. Rust CLI Working Group scope: `https://github.com/rust-cli/team`. ([github.com](https://github.com/rust-cli/team))
21. RustSec package index: `https://rustsec.org/packages/`. ([rustsec.org](https://rustsec.org/packages/))
22. `rustix::fs::stat` alternative: `https://docs.rs/rustix/latest/rustix/fs/fn.stat.html`. ([docs.rs](https://docs.rs/rustix/latest/rustix/fs/fn.stat.html))
23. `tracing` 0.1.44 documentation: `https://docs.rs/crate/tracing/latest/source/README.md`. ([docs.rs](https://docs.rs/crate/tracing/latest/source/README.md))
24. Tokio `tracing` repository: `https://github.com/tokio-rs/tracing`. ([github.com](https://github.com/tokio-rs/tracing))
25. Owner-supplied F239/F240/F242/F243/F245/F246 and TypeScript/Python source precedent: supplied in the prompt on 2026-09-17; no public URL was provided.

## Sources

- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html](https://doc.rust-lang.org/std/os/unix/fs/trait.PermissionsExt.html)
- [https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- [https://doc.rust-lang.org/cargo/reference/credential-provider-protocol.html](https://doc.rust-lang.org/cargo/reference/credential-provider-protocol.html)
- [https://doc.rust-lang.org/nightly/cargo/reference/config.html](https://doc.rust-lang.org/nightly/cargo/reference/config.html)
- [https://github.com/rust-cli/book](https://github.com/rust-cli/book)
- [https://cli.github.com/manual/gh_auth_login](https://cli.github.com/manual/gh_auth_login)
- [https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [https://doc.rust-lang.org/cargo/commands/cargo-login.html](https://doc.rust-lang.org/cargo/commands/cargo-login.html)
- [https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs](https://github.com/awslabs/aws-sdk-rust/blob/main/sdk/aws-config/src/default_provider/credentials.rs)
- [https://github.com/systemd/systemd/blob/main/docs/CREDENTIALS.md?plain=1](https://github.com/systemd/systemd/blob/main/docs/CREDENTIALS.md?plain=1)
- [https://cwe.mitre.org/data/definitions/312.html](https://cwe.mitre.org/data/definitions/312.html)
- [https://doc.rust-lang.org/cargo/reference/registry-authentication.html](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)
- [https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html](https://doc.rust-lang.org/stable/std/fs/struct.Permissions.html)
- [https://docs.rs/crate/tracing/latest/source/README.md](https://docs.rs/crate/tracing/latest/source/README.md)
- [https://doc.rust-lang.org/cargo/reference/config.html](https://doc.rust-lang.org/cargo/reference/config.html)
- [https://doc.rust-lang.org/std/os/unix/fs/trait.MetadataExt.html](https://doc.rust-lang.org/std/os/unix/fs/trait.MetadataExt.html)
- [https://docs.rs/rustix/latest/rustix/fs/fn.stat.html](https://docs.rs/rustix/latest/rustix/fs/fn.stat.html)
- [https://github.com/tokio-rs/tracing](https://github.com/tokio-rs/tracing)
- [https://github.com/rust-cli/team](https://github.com/rust-cli/team)
- [https://doc.rust-lang.org/releases.html](https://doc.rust-lang.org/releases.html)
- [https://doc.rust-lang.org/cargo/reference/registries.html](https://doc.rust-lang.org/cargo/reference/registries.html)
- [https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [https://github.com/cli/cli/issues/8954](https://github.com/cli/cli/issues/8954)
- [https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
- [https://rust-cli.github.io/book/index.html](https://rust-cli.github.io/book/index.html)
- [https://rustsec.org/packages/](https://rustsec.org/packages/)
