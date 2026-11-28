//! Four-tier template + `anstream` color-enablement chain (`R65`).
//!
//! Resolution order (highest precedence first):
//! 1. Per-invocation `--color <auto|always|never>` / `--no-color` flag
//! 2. Config file `[output].color`
//! 3. `NO_COLOR` (present and non-empty -> `Never`)
//! 4. `FORCE_COLOR` (present, non-empty, and `!= "0"` -> `Always`)
//! 5. Tiers 5–7 delegated via `ColorChoice::Auto` to `anstream` per output stream
//!    (`CLICOLOR_FORCE`, `CLICOLOR=0`, `stream.is_terminal() && (term || clicolor || is_ci)`).

use std::collections::BTreeMap;
use std::env;
use std::ffi::OsString;

use anstream::ColorChoice;
use rs_launch_blueprint_core::ColorPreference;

/// Read-only environment lookup seam keeping color, pager, spinner, and diagnostics pure.
pub trait EnvLookup: Send + Sync {
    /// Look up raw OS value of environment variable `key`.
    fn var_os(&self, key: &str) -> Option<OsString>;

    /// Return all `(key, value)` pairs whose key begins with `prefix`, sorted by key.
    fn iter_prefixed(&self, prefix: &str) -> Vec<(String, String)>;

    /// Look up UTF-8 lossy string value of `key`.
    fn var_string(&self, key: &str) -> Option<String> {
        self.var_os(key).map(|v| v.to_string_lossy().into_owned())
    }
}

/// Production [`EnvLookup`] backed by `std::env`.
#[derive(Debug, Default, Clone, Copy)]
pub struct ProcessEnv;

impl EnvLookup for ProcessEnv {
    fn var_os(&self, key: &str) -> Option<OsString> {
        env::var_os(key)
    }

    fn iter_prefixed(&self, prefix: &str) -> Vec<(String, String)> {
        let mut pairs: Vec<(String, String)> = env::vars_os()
            .filter_map(|(k, v)| {
                let ks = k.to_string_lossy();
                if ks.starts_with(prefix) {
                    Some((ks.into_owned(), v.to_string_lossy().into_owned()))
                } else {
                    None
                }
            })
            .collect();
        pairs.sort_by(|a, b| a.0.cmp(&b.0));
        pairs
    }
}

/// Deterministic in-memory [`EnvLookup`] for hermetic tests (`R65` AC10).
#[derive(Debug, Default, Clone)]
pub struct MapEnv {
    vars: BTreeMap<String, OsString>,
}

impl MapEnv {
    /// Construct an empty [`MapEnv`].
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Insert or replace `key` with `value` (builder style).
    #[must_use]
    pub fn with(mut self, key: impl Into<String>, value: impl Into<OsString>) -> Self {
        self.vars.insert(key.into(), value.into());
        self
    }

    /// Construct a [`MapEnv`] from an iterator of `(key, value)` string pairs.
    #[must_use]
    pub fn from_pairs<'a>(pairs: impl IntoIterator<Item = (&'a str, &'a str)>) -> Self {
        let mut map = Self::new();
        for (k, v) in pairs {
            map.set(k, v);
        }
        map
    }

    /// Insert or replace `key` with `value`.
    pub fn set(&mut self, key: impl Into<String>, value: impl Into<OsString>) {
        self.vars.insert(key.into(), value.into());
    }
}

impl EnvLookup for MapEnv {
    fn var_os(&self, key: &str) -> Option<OsString> {
        self.vars.get(key).cloned()
    }

    fn iter_prefixed(&self, prefix: &str) -> Vec<(String, String)> {
        self.vars
            .iter()
            .filter(|(k, _)| k.starts_with(prefix))
            .map(|(k, v)| (k.clone(), v.to_string_lossy().into_owned()))
            .collect()
    }
}

/// Resolve tiers 1–4 of the R65 color chain into an [`anstream::ColorChoice`].
///
/// Returning [`ColorChoice::Auto`] delegates tiers 5–7 to `anstream::AutoStream` per stream.
#[must_use]
pub fn resolve_color(
    flag: Option<ColorPreference>,
    config: ColorPreference,
    env: &dyn EnvLookup,
) -> ColorChoice {
    // Tier 1: per-invocation CLI flag.
    if let Some(pref) = flag {
        match pref {
            ColorPreference::Always => return ColorChoice::Always,
            ColorPreference::Never => return ColorChoice::Never,
            ColorPreference::Auto => {}
        }
    }

    // Tier 2: config-file key `[output].color`.
    match config {
        ColorPreference::Always => return ColorChoice::Always,
        ColorPreference::Never => return ColorChoice::Never,
        ColorPreference::Auto => {}
    }

    // Tier 3: NO_COLOR present and non-empty (empty string treated as unset per no-color.org).
    if env.var_os("NO_COLOR").is_some_and(|v| !v.is_empty()) {
        return ColorChoice::Never;
    }

    // Tier 4: FORCE_COLOR present, non-empty, and not "0".
    if env
        .var_os("FORCE_COLOR")
        .is_some_and(|v| !v.is_empty() && v != "0")
    {
        return ColorChoice::Always;
    }

    // Tiers 5–7: delegated to anstream per stream.
    ColorChoice::Auto
}

/// Evaluate effective per-stream color enablement for an in-process or virtual stream (`R65`).
///
/// Mirrors `anstream::AutoStream::choice` tiers 5–7 (`CLICOLOR_FORCE`, `CLICOLOR=0`,
/// `stream_is_tty && (term_supports_color || clicolor_enabled || is_ci)`) so in-process tests
/// can verify all 12 R65 acceptance criteria deterministically without mutating process env.
#[must_use]
pub fn resolve_stream_color(choice: ColorChoice, stream_is_tty: bool, env: &dyn EnvLookup) -> bool {
    match choice {
        ColorChoice::Always | ColorChoice::AlwaysAnsi => true,
        ColorChoice::Never => false,
        ColorChoice::Auto => {
            // Tier 5: CLICOLOR_FORCE present and non-empty and != "0".
            if env
                .var_os("CLICOLOR_FORCE")
                .is_some_and(|v| !v.is_empty() && v != "0")
            {
                return true;
            }
            // Tier 6: CLICOLOR=0 disables color.
            let clicolor_val = env.var_os("CLICOLOR");
            if clicolor_val.as_deref() == Some(std::ffi::OsStr::new("0")) {
                return false;
            }
            let clicolor_enabled = clicolor_val.is_some_and(|v| !v.is_empty());
            let term_supports = env
                .var_string("TERM")
                .is_some_and(|t| !t.is_empty() && t != "dumb");
            let is_ci = env.var_os("CI").is_some();
            // Tier 7: stream's own is_terminal() && (TERM supports color || CLICOLOR || CI).
            stream_is_tty && (term_supports || clicolor_enabled || is_ci)
        }
    }
}
