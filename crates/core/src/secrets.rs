//! Secret policy, redacted [`Token`] carrier, credential stores, and three-tier resolution
//! (`R56`, CLI Design Standard R5.5 / R5.6 / R10.1).
//!
//! Layered configuration files (`rslbp_config.toml`) NEVER supply credentials. Credentials
//! resolve strictly in the order:
//!
//! 1. `--token-file <PATH>` (or `-` for stdin)
//! 2. `RSLBP_TOKEN` environment variable (empty string treated as unset per F242)
//! 3. Stored credential (`0600 credentials.toml` under `state_dir()`, or optional OS keychain)

use std::fmt;
use std::fs::{self, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::Mutex;
use std::sync::atomic::{AtomicU64, Ordering};

use secrecy::{ExposeSecret, SecretString};
use zeroize::Zeroize;

use crate::error::AuthError;

/// Environment variable supplying an API token (`R56` F241).
pub const TOKEN_ENV_VAR: &str = "RSLBP_TOKEN";

static NEXT_TMP_SEQ: AtomicU64 = AtomicU64::new(0);

/// Redacted API token backed by [`secrecy::SecretString`] (`R56`).
///
/// Deliberately does **not** implement `Serialize` so it can never be written into a config
/// document or JSON log accidentally. `Debug` delegates to `SecretString`'s redacted placeholder
/// and `Display` prints a masked preview (`***` + last 4 chars for tokens of length ≥ 8).
#[derive(Clone)]
pub struct Token(SecretString);

impl Token {
    /// Wrap a raw secret string in a zeroizing [`Token`].
    #[must_use]
    pub fn new(value: impl Into<String>) -> Self {
        Self(SecretString::from(value.into()))
    }

    /// Access the raw secret bytes at a deliberate, reviewable boundary (e.g., HTTP header).
    #[must_use]
    pub fn expose_secret(&self) -> &str {
        self.0.expose_secret()
    }

    /// Format a safe display preview (`***` + last 4 Unicode scalars when length ≥ 8, else `***`).
    #[must_use]
    pub fn masked(&self) -> String {
        let raw = self.0.expose_secret();
        let count = raw.chars().count();
        if count >= 8 {
            let suffix: String = raw.chars().skip(count - 4).collect();
            format!("***{suffix}")
        } else {
            "***".to_owned()
        }
    }
}

impl fmt::Debug for Token {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_tuple("Token").field(&self.0).finish()
    }
}

impl fmt::Display for Token {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.masked())
    }
}

/// Which channel supplied a resolved [`Token`] (`R56`, CLI R5.7).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TokenSource {
    /// Supplied via `--token-file <PATH>`.
    TokenFile,
    /// Supplied via `--token-file -` (standard input).
    Stdin,
    /// Supplied via `RSLBP_TOKEN`.
    Env,
    /// Supplied by the dedicated credential store (`credentials.toml` or OS keychain).
    Stored,
}

impl TokenSource {
    /// Stable display label for `--show-origin` and diagnostics.
    #[must_use]
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::TokenFile => "token-file",
            Self::Stdin => "stdin",
            Self::Env => "env",
            Self::Stored => "stored",
        }
    }
}

impl fmt::Display for TokenSource {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// A resolved token paired with its provenance (`R56`).
#[derive(Debug, Clone)]
pub struct ResolvedToken {
    /// The redacted credential value.
    pub token: Token,
    /// Which precedence tier supplied the token.
    pub source: TokenSource,
}

/// Kind of non-fatal warning detected during credential resolution (`R56`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CredentialWarningKind {
    /// Credential or token file is readable/writable/executable by group or others (`mode & 0o077 != 0`).
    LoosePermissions {
        /// Observed POSIX mode bits (`mode & 0o7777`).
        mode: u32,
    },
}

/// Non-fatal credential warning returned as data so the library never writes to stderr (`R56` AC10).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CredentialWarning {
    /// File path carrying loose permissions.
    pub path: PathBuf,
    /// Warning classification.
    pub kind: CredentialWarningKind,
}

impl fmt::Display for CredentialWarning {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self.kind {
            CredentialWarningKind::LoosePermissions { mode } => write!(
                f,
                "credential file '{}' is accessible to group/others (mode {:04o}); restrict it with: chmod 600 '{}'",
                self.path.display(),
                mode,
                self.path.display()
            ),
        }
    }
}

/// Outcome of [`resolve_token`]: optional resolved token plus non-fatal warnings (`R56`).
#[derive(Debug, Clone)]
pub struct TokenResolution {
    /// Resolved credential if any tier supplied one.
    pub resolved: Option<ResolvedToken>,
    /// Non-fatal warnings (for example, loose permissions on a credential file).
    pub warnings: Vec<CredentialWarning>,
}

/// Result of inspecting POSIX permissions on a file containing a secret (`R56`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PermissionCheck {
    /// File is restricted to its owner (`mode & 0o077 == 0`).
    Secure,
    /// File grants at least one permission bit to group or others.
    Loose {
        /// Observed POSIX mode bits (`mode & 0o7777`).
        mode: u32,
    },
    /// Platform does not expose POSIX permission bits; reported as unchecked, never clean.
    Unchecked,
}

/// Inspect file permissions for group/other accessibility (`mode & 0o077 != 0`, `R56`).
pub fn inspect_file_permissions(path: &Path) -> io::Result<PermissionCheck> {
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mode = fs::metadata(path)?.permissions().mode();
        if mode & 0o077 != 0 {
            Ok(PermissionCheck::Loose {
                mode: mode & 0o7777,
            })
        } else {
            Ok(PermissionCheck::Secure)
        }
    }
    #[cfg(not(unix))]
    {
        let _ = fs::metadata(path)?;
        Ok(PermissionCheck::Unchecked)
    }
}

fn check_loose_permissions(path: &Path) -> Option<CredentialWarning> {
    match inspect_file_permissions(path) {
        Ok(PermissionCheck::Loose { mode }) => Some(CredentialWarning {
            path: path.to_path_buf(),
            kind: CredentialWarningKind::LoosePermissions { mode },
        }),
        Ok(PermissionCheck::Secure | PermissionCheck::Unchecked) | Err(_) => None,
    }
}

/// Dedicated credential storage backend (`R56`, tier 3).
pub trait CredentialStore: Send + Sync {
    /// Load the stored credential, returning `Ok((None, ...))` when no credential is stored.
    fn load(&self) -> Result<(Option<Token>, Vec<CredentialWarning>), AuthError>;

    /// Persist `token` securely at rest.
    fn save(&self, token: &Token) -> Result<(), AuthError>;

    /// Delete any stored credential, returning `Ok(true)` if removed or `Ok(false)` if absent.
    fn delete(&self) -> Result<bool, AuthError>;
}

/// Default plaintext `0600` TOML credential file store under `state_dir()` (`R56`).
#[derive(Debug, Clone)]
pub struct FileCredentialStore {
    path: PathBuf,
}

impl FileCredentialStore {
    /// Create a file-backed credential store at `path` (typically `paths.credentials_file()`).
    #[must_use]
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self { path: path.into() }
    }

    /// Return the underlying credential file path.
    #[must_use]
    pub fn path(&self) -> &Path {
        &self.path
    }
}

impl CredentialStore for FileCredentialStore {
    fn load(&self) -> Result<(Option<Token>, Vec<CredentialWarning>), AuthError> {
        let mut raw = match fs::read_to_string(&self.path) {
            Ok(content) => content,
            Err(err) if err.kind() == io::ErrorKind::NotFound => {
                return Ok((None, Vec::new()));
            }
            Err(err) => {
                return Err(AuthError::Io {
                    path: self.path.clone(),
                    source: err,
                });
            }
        };

        let mut warnings = Vec::new();
        if let Some(warning) = check_loose_permissions(&self.path) {
            warnings.push(warning);
        }

        let parsed: Result<toml::Table, _> = toml::from_str(&raw);
        raw.zeroize();

        let table = parsed.map_err(|err| AuthError::StoreUnavailable {
            detail: format!(
                "invalid TOML in credentials file '{}': {}",
                self.path.display(),
                err.message()
            ),
        })?;

        let raw_token = table
            .get("token")
            .and_then(toml::Value::as_str)
            .or_else(|| {
                table
                    .get("auth")
                    .and_then(toml::Value::as_table)
                    .and_then(|auth| auth.get("token"))
                    .and_then(toml::Value::as_str)
            });

        let token = raw_token
            .map(|s| s.trim_end_matches(['\r', '\n']))
            .filter(|s| !s.is_empty())
            .map(Token::new);

        Ok((token, warnings))
    }

    fn save(&self, token: &Token) -> Result<(), AuthError> {
        let mut doc = toml_edit::DocumentMut::new();
        doc["token"] = toml_edit::value(token.expose_secret());
        let mut rendered = doc.to_string();
        let result =
            write_atomic_0600(&self.path, rendered.as_bytes()).map_err(|source| AuthError::Io {
                path: self.path.clone(),
                source,
            });
        rendered.zeroize();
        result
    }

    fn delete(&self) -> Result<bool, AuthError> {
        match fs::remove_file(&self.path) {
            Ok(()) => Ok(true),
            Err(err) if err.kind() == io::ErrorKind::NotFound => Ok(false),
            Err(source) => Err(AuthError::Io {
                path: self.path.clone(),
                source,
            }),
        }
    }
}

/// In-memory [`CredentialStore`] test double.
#[derive(Debug, Default)]
pub struct InMemoryCredentialStore {
    token: Mutex<Option<Token>>,
}

impl InMemoryCredentialStore {
    /// Create a new empty in-memory credential store.
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Create an in-memory credential store pre-populated with `token`.
    #[must_use]
    pub fn with_token(token: Token) -> Self {
        Self {
            token: Mutex::new(Some(token)),
        }
    }

    fn lock_token(&self) -> Result<std::sync::MutexGuard<'_, Option<Token>>, AuthError> {
        self.token.lock().map_err(|_| AuthError::StoreUnavailable {
            detail: "in-memory credential lock poisoned".to_owned(),
        })
    }
}

impl CredentialStore for InMemoryCredentialStore {
    fn load(&self) -> Result<(Option<Token>, Vec<CredentialWarning>), AuthError> {
        let guard = self.lock_token()?;
        Ok((guard.clone(), Vec::new()))
    }

    fn save(&self, token: &Token) -> Result<(), AuthError> {
        let mut guard = self.lock_token()?;
        *guard = Some(token.clone());
        Ok(())
    }

    fn delete(&self) -> Result<bool, AuthError> {
        let mut guard = self.lock_token()?;
        Ok(guard.take().is_some())
    }
}

/// Inputs to [`resolve_token`], injected so resolution stays pure and hermetically testable.
#[derive(Default)]
pub struct TokenResolutionInputs<'a> {
    /// Value of `--token-file <PATH>` (`Path::new("-")` selects stdin).
    pub token_file: Option<&'a Path>,
    /// Pre-read stdin contents used when `token_file == Some(Path::new("-"))`.
    pub stdin_token: Option<&'a str>,
    /// Value of `RSLBP_TOKEN` environment variable (empty string treated as unset per F242).
    pub env_token: Option<&'a str>,
    /// Dedicated stored-credential backend (`FileCredentialStore` or OS keychain).
    pub store: Option<&'a dyn CredentialStore>,
}

/// Resolve an API token across the three R56 tiers (`--token-file` > `RSLBP_TOKEN` > stored).
///
/// Never reads the layered config file and never writes to stdout or stderr (`R56` AC10).
/// An explicit `--token-file` pointing to a missing or empty file fails with
/// [`AuthError::CredentialsAbsent`] (`RSLB401`) and never falls through to lower tiers (`R56` AC6).
pub fn resolve_token(inputs: &TokenResolutionInputs<'_>) -> Result<TokenResolution, AuthError> {
    // Tier 1: --token-file <PATH> (or `-` for stdin).
    if let Some(path) = inputs.token_file {
        if path == Path::new("-") {
            let trimmed = inputs
                .stdin_token
                .map(|s| s.trim_end_matches(['\r', '\n']).trim())
                .filter(|s| !s.is_empty())
                .ok_or_else(|| AuthError::CredentialsAbsent {
                    detail: "standard input supplied an empty token".to_owned(),
                })?;
            return Ok(TokenResolution {
                resolved: Some(ResolvedToken {
                    token: Token::new(trimmed),
                    source: TokenSource::Stdin,
                }),
                warnings: Vec::new(),
            });
        }

        let mut raw = match fs::read_to_string(path) {
            Ok(content) => content,
            Err(err) if err.kind() == io::ErrorKind::NotFound => {
                return Err(AuthError::CredentialsAbsent {
                    detail: format!("token file '{}' does not exist", path.display()),
                });
            }
            Err(source) => {
                return Err(AuthError::Io {
                    path: path.to_path_buf(),
                    source,
                });
            }
        };

        let mut warnings = Vec::new();
        if let Some(warning) = check_loose_permissions(path) {
            warnings.push(warning);
        }

        let trimmed = raw.trim_end_matches(['\r', '\n']).trim().to_owned();
        raw.zeroize();
        if trimmed.is_empty() {
            return Err(AuthError::CredentialsAbsent {
                detail: format!("token file '{}' is empty", path.display()),
            });
        }

        return Ok(TokenResolution {
            resolved: Some(ResolvedToken {
                token: Token::new(trimmed),
                source: TokenSource::TokenFile,
            }),
            warnings,
        });
    }

    // Tier 2: RSLBP_TOKEN (empty string treated as unset per F242).
    if let Some(env_val) = inputs.env_token {
        let trimmed = env_val.trim_end_matches(['\r', '\n']);
        if !trimmed.is_empty() {
            return Ok(TokenResolution {
                resolved: Some(ResolvedToken {
                    token: Token::new(trimmed),
                    source: TokenSource::Env,
                }),
                warnings: Vec::new(),
            });
        }
    }

    // Tier 3: dedicated credential store.
    if let Some(store) = inputs.store {
        let (maybe_token, warnings) = store.load()?;
        let resolved = maybe_token.map(|token| ResolvedToken {
            token,
            source: TokenSource::Stored,
        });
        return Ok(TokenResolution { resolved, warnings });
    }

    Ok(TokenResolution {
        resolved: None,
        warnings: Vec::new(),
    })
}

/// Atomically write `bytes` to `target` using a sibling temporary file created with mode `0600`
/// at `O_CREAT` (`F243`, `R52` AC5, `R56` AC3).
///
/// Creates parent directories with mode `0700` on Unix. Never uses `std::env::temp_dir()` so the
/// rename is guaranteed same-filesystem and atomic.
pub(crate) fn write_atomic_0600(target: &Path, bytes: &[u8]) -> io::Result<()> {
    let parent = target
        .parent()
        .filter(|p| !p.as_os_str().is_empty())
        .unwrap_or_else(|| Path::new("."));
    let mut dir_builder = fs::DirBuilder::new();
    dir_builder.recursive(true);
    #[cfg(unix)]
    std::os::unix::fs::DirBuilderExt::mode(&mut dir_builder, 0o700);
    dir_builder.create(parent)?;

    let file_name = target
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("rslbp");
    let pid = std::process::id();

    let (tmp_path, mut file) = loop {
        let seq = NEXT_TMP_SEQ.fetch_add(1, Ordering::Relaxed);
        let candidate = parent.join(format!(".{file_name}.tmp.{pid}.{seq}"));
        let mut opts = OpenOptions::new();
        opts.write(true).create_new(true);
        #[cfg(unix)]
        std::os::unix::fs::OpenOptionsExt::mode(&mut opts, 0o600);

        match opts.open(&candidate) {
            Ok(f) => break (candidate, f),
            Err(err) if err.kind() == io::ErrorKind::AlreadyExists => continue,
            Err(err) => return Err(err),
        }
    };

    let write_res = (|| -> io::Result<()> {
        file.write_all(bytes)?;
        file.sync_all()?;
        Ok(())
    })();

    drop(file);

    if let Err(err) = write_res {
        let _ = fs::remove_file(&tmp_path);
        return Err(err);
    }

    if let Err(err) = fs::rename(&tmp_path, target) {
        let _ = fs::remove_file(&tmp_path);
        return Err(err);
    }

    Ok(())
}
