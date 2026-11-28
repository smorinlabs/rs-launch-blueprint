//! XDG-compliant per-user directory resolution (`R57`, CLI Design Standard R5.3).
//!
//! Resolves the four per-user directory kinds (config, data, state, cache) once via `etcetera`
//! (`choose_base_strategy()`, which uses XDG on both Linux and macOS) namespaced under
//! [`TOOL_NAME`] (`rslbp`).
//!
//! Resolution is completely pure: it never creates directories or touches the filesystem.
//! A `runtime_dir()` accessor is deliberately omitted until a feature needs sockets, FIFOs, or
//! lock files (at which point it delegates to `etcetera::base_strategy::BaseStrategy::runtime_dir`).

use std::path::{Path, PathBuf};

use etcetera::HomeDirError;
use etcetera::base_strategy::{BaseStrategy, choose_base_strategy};

/// Single namespace segment under every XDG base directory (`R49`, `R57`).
pub const TOOL_NAME: &str = "rslbp";

/// Canonical configuration filename across system, user, and project tiers (`R54`, CLI R5.2).
pub const CONFIG_FILE_NAME: &str = "rslbp_config.toml";

/// Project-local configuration directory walked upward from the working directory (`R54`).
pub const PROJECT_CONFIG_DIR: &str = ".rslbp";

/// Dedicated stored-credentials filename under [`Paths::state_dir`] (`R56`).
pub const CREDENTIALS_FILE_NAME: &str = "credentials.toml";

/// Default CLI file-log filename under [`Paths::state_dir`] (`R59`).
pub const LOG_FILE_NAME: &str = "rslbp.log";

/// Default CLI crash-record filename under [`Paths::state_dir`] (`R57`, `R67`).
pub const CRASH_LOG_FILE_NAME: &str = "rslbp_crash.jsonl";

/// Resolved per-user directories for `rslbp` (`R57`).
///
/// Construct once at the composition root and pass down; no other module reads raw `XDG_*`
/// variables for per-user directories.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Paths {
    config: PathBuf,
    data: PathBuf,
    state: PathBuf,
    cache: PathBuf,
}

impl Paths {
    /// Resolve all four namespaced directories from any `etcetera` [`BaseStrategy`].
    ///
    /// Pure: touches no filesystem. When `strategy.state_dir()` returns `None` (non-XDG
    /// strategies such as Windows), state collapses onto the data directory so the accessor
    /// stays total.
    #[must_use]
    pub fn from_strategy(strategy: &impl BaseStrategy) -> Self {
        let data = strategy.data_dir().join(TOOL_NAME);
        let state = strategy
            .state_dir()
            .map_or_else(|| data.clone(), |dir| dir.join(TOOL_NAME));
        Self {
            config: strategy.config_dir().join(TOOL_NAME),
            state,
            cache: strategy.cache_dir().join(TOOL_NAME),
            data,
        }
    }

    /// Construct [`Paths`] from explicit un-namespaced base root directories.
    ///
    /// Appends [`TOOL_NAME`] to each base root. Useful for deterministic tests and library
    /// embedders without importing `etcetera` types.
    #[must_use]
    pub fn from_roots(config: PathBuf, data: PathBuf, state: PathBuf, cache: PathBuf) -> Self {
        Self {
            config: config.join(TOOL_NAME),
            data: data.join(TOOL_NAME),
            state: state.join(TOOL_NAME),
            cache: cache.join(TOOL_NAME),
        }
    }

    /// Resolve per-user directories from the current process environment via `etcetera`.
    ///
    /// Fails with [`HomeDirError`] only when the platform home directory cannot be determined
    /// (for example, a container running under a numeric UID absent from `/etc/passwd`).
    pub fn from_process_env() -> Result<Self, HomeDirError> {
        let strategy = choose_base_strategy()?;
        Ok(Self::from_strategy(&strategy))
    }

    /// User configuration directory (`$XDG_CONFIG_HOME/rslbp`).
    #[must_use]
    pub fn config_dir(&self) -> &Path {
        &self.config
    }

    /// User data directory (`$XDG_DATA_HOME/rslbp`).
    #[must_use]
    pub fn data_dir(&self) -> &Path {
        &self.data
    }

    /// User state directory (`$XDG_STATE_HOME/rslbp`).
    #[must_use]
    pub fn state_dir(&self) -> &Path {
        &self.state
    }

    /// User cache directory (`$XDG_CACHE_HOME/rslbp`).
    #[must_use]
    pub fn cache_dir(&self) -> &Path {
        &self.cache
    }

    /// User configuration file path (`<config_dir>/rslbp_config.toml`).
    #[must_use]
    pub fn config_file(&self) -> PathBuf {
        self.config.join(CONFIG_FILE_NAME)
    }

    /// Dedicated credential store file path (`<state_dir>/credentials.toml`, `R56`).
    #[must_use]
    pub fn credentials_file(&self) -> PathBuf {
        self.state.join(CREDENTIALS_FILE_NAME)
    }

    /// Default CLI rotating log file path (`<state_dir>/rslbp.log`, `R59`).
    #[must_use]
    pub fn log_file(&self) -> PathBuf {
        self.state.join(LOG_FILE_NAME)
    }

    /// Default CLI crash-record file path (`<state_dir>/rslbp_crash.jsonl`, `R67`).
    #[must_use]
    pub fn crash_log_file(&self) -> PathBuf {
        self.state.join(CRASH_LOG_FILE_NAME)
    }
}

#[cfg(test)]
mod tests {
    use std::path::{Path, PathBuf};

    use etcetera::base_strategy::BaseStrategy;

    use super::Paths;

    struct FakeStrategy {
        home: PathBuf,
        state: Option<PathBuf>,
    }

    impl BaseStrategy for FakeStrategy {
        fn home_dir(&self) -> &Path {
            &self.home
        }
        fn config_dir(&self) -> PathBuf {
            self.home.join(".config")
        }
        fn data_dir(&self) -> PathBuf {
            self.home.join(".local/share")
        }
        fn cache_dir(&self) -> PathBuf {
            self.home.join(".cache")
        }
        fn state_dir(&self) -> Option<PathBuf> {
            self.state.clone()
        }
        fn runtime_dir(&self) -> Option<PathBuf> {
            None
        }
    }

    #[test]
    fn from_strategy_uses_state_dir_when_present_and_falls_back_to_data_when_absent() {
        let with_state = Paths::from_strategy(&FakeStrategy {
            home: PathBuf::from("/tmp/fake-home"),
            state: Some(PathBuf::from("/tmp/fake-home/.local/state")),
        });
        assert_eq!(
            with_state.state_dir(),
            Path::new("/tmp/fake-home/.local/state/rslbp")
        );

        let without_state = Paths::from_strategy(&FakeStrategy {
            home: PathBuf::from("/tmp/fake-home"),
            state: None,
        });
        assert_eq!(without_state.state_dir(), without_state.data_dir());
    }
}
