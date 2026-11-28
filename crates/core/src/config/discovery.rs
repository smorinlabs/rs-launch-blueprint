//! Layered configuration discovery, upward project walk, and documented precedence (`R54`).

use std::ffi::OsStr;
use std::fs;
use std::path::{Path, PathBuf};

use crate::paths::{CONFIG_FILE_NAME, PROJECT_CONFIG_DIR, Paths, TOOL_NAME};

/// Pinned six-rung configuration precedence order (`R54` AC9, CLI Design Standard R5.1).
pub const PRECEDENCE_CHAIN_DOC: &str = "\
Configuration precedence (highest to lowest):
1. Command-line flags
2. Environment variables
3. Project/local config file (.rslbp/rslbp_config.toml)
4. User config file ($XDG_CONFIG_HOME/rslbp/rslbp_config.toml)
5. System config file ($XDG_CONFIG_DIRS/rslbp/rslbp_config.toml, fallback /etc/xdg)
6. Built-in defaults";

/// Pinned layered TOML merge strategy (`R54` AC11).
pub const MERGE_STRATEGY_DOC: &str = "\
Layered TOML tables merge recursively across configuration tiers, while scalars and arrays \
replace wholesale with the nearer tier winning.";

/// Origin of an explicit configuration path override (`R54` AC4).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExplicitOrigin {
    /// Supplied via `--config <PATH>`.
    Flag,
    /// Supplied via `RSLBP_CONFIG`.
    Env,
}

/// Precedence tier of a configuration file source (`R54`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConfigTier {
    /// System-wide configuration (`$XDG_CONFIG_DIRS` or `/etc/xdg`).
    System,
    /// Per-user configuration (`Paths::config_file()`).
    User,
    /// Project-local configuration (`.rslbp/rslbp_config.toml`).
    Project,
    /// Explicit override replacing all discovered tiers.
    Explicit(ExplicitOrigin),
}

/// A discovered or explicitly supplied configuration file source.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConfigSource {
    /// Filesystem path to the TOML document.
    pub path: PathBuf,
    /// Precedence tier of this file.
    pub tier: ConfigTier,
}

/// Pure inputs for [`discover_config_sources`] and [`crate::load_config`].
#[derive(Debug, Clone, Copy)]
pub struct ConfigDiscoveryInputs<'a> {
    /// Value of `--config <PATH>`, if supplied.
    pub explicit_flag: Option<&'a Path>,
    /// Value of `RSLBP_CONFIG`, if set (empty value ignored per F242).
    pub explicit_env: Option<&'a OsStr>,
    /// Starting directory for the upward project config walk.
    pub cwd: &'a Path,
    /// Resolved per-user XDG paths (`R57`).
    pub paths: &'a Paths,
    /// Raw value of `$XDG_CONFIG_DIRS` (`None` falls back to `/etc/xdg`).
    pub xdg_config_dirs: Option<&'a OsStr>,
}

/// Resolve system configuration file candidates from `$XDG_CONFIG_DIRS` in priority order
/// (highest-priority directory first, `R54` AC2).
///
/// Per the XDG Base Directory Specification, relative entries are ignored. When unset, empty, or
/// containing no absolute paths, falls back to `/etc/xdg/rslbp/rslbp_config.toml`.
#[must_use]
pub fn discover_system_config_files(xdg_config_dirs: Option<&OsStr>) -> Vec<PathBuf> {
    let dirs: Vec<PathBuf> = xdg_config_dirs
        .filter(|raw| !raw.is_empty())
        .map(|raw| {
            std::env::split_paths(raw)
                .filter(|dir| dir.is_absolute())
                .map(|dir| dir.join(TOOL_NAME).join(CONFIG_FILE_NAME))
                .collect()
        })
        .unwrap_or_default();

    if dirs.is_empty() {
        vec![
            PathBuf::from("/etc/xdg")
                .join(TOOL_NAME)
                .join(CONFIG_FILE_NAME),
        ]
    } else {
        dirs
    }
}

/// Walk upward from `start` looking for `.rslbp/rslbp_config.toml`, stopping inclusively at a
/// `.git` directory/file or a Cargo workspace root (`Cargo.toml` containing `[workspace]`,
/// `R54` AC7 / AC7b).
#[must_use]
pub fn discover_project_config_file(start: &Path) -> Option<PathBuf> {
    for dir in start.ancestors() {
        let candidate = dir.join(PROJECT_CONFIG_DIR).join(CONFIG_FILE_NAME);
        if candidate.is_file() {
            return Some(candidate);
        }
        if is_project_boundary(dir) {
            break;
        }
    }
    None
}

fn is_project_boundary(dir: &Path) -> bool {
    // `.git` may be either a directory (standard repo) or a file (worktree/submodule).
    if dir.join(".git").exists() {
        return true;
    }
    is_cargo_workspace_root(dir)
}

fn is_cargo_workspace_root(dir: &Path) -> bool {
    let manifest = dir.join("Cargo.toml");
    if !manifest.is_file() {
        return false;
    }
    let Ok(raw) = fs::read_to_string(&manifest) else {
        return false;
    };
    let Ok(table) = toml::from_str::<toml::Table>(&raw) else {
        return false;
    };
    table.contains_key("workspace")
}

/// Discover configuration file sources ordered from lowest to highest precedence so callers can
/// merge them sequentially (`R54`).
///
/// When `explicit_flag` or a non-empty `explicit_env` is present, all discovered layers are
/// suppressed and only that single explicit source is returned (`R54` AC4).
#[must_use]
pub fn discover_config_sources(inputs: &ConfigDiscoveryInputs<'_>) -> Vec<ConfigSource> {
    if let Some(flag_path) = inputs.explicit_flag {
        return vec![ConfigSource {
            path: flag_path.to_path_buf(),
            tier: ConfigTier::Explicit(ExplicitOrigin::Flag),
        }];
    }
    if let Some(env_path) = inputs.explicit_env
        && !env_path.is_empty()
    {
        return vec![ConfigSource {
            path: PathBuf::from(env_path),
            tier: ConfigTier::Explicit(ExplicitOrigin::Env),
        }];
    }

    let mut sources = Vec::new();
    // System dirs are returned highest-priority first; reverse so lowest-priority merges first.
    for path in discover_system_config_files(inputs.xdg_config_dirs)
        .into_iter()
        .rev()
    {
        sources.push(ConfigSource {
            path,
            tier: ConfigTier::System,
        });
    }

    sources.push(ConfigSource {
        path: inputs.paths.config_file(),
        tier: ConfigTier::User,
    });

    if let Some(project_path) = discover_project_config_file(inputs.cwd) {
        sources.push(ConfigSource {
            path: project_path,
            tier: ConfigTier::Project,
        });
    }

    sources
}
