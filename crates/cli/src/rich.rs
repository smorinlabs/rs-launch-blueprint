//! Capability-gated rich terminal row niceties: OSC-8 hyperlinks and relative time (`R85`).

use std::path::Path;

use anstyle_hyperlink::Hyperlink;
use percent_encoding::{AsciiSet, CONTROLS, utf8_percent_encode};

/// Percent-encoding set covering all C0/DEL control bytes plus ASCII space (`R85`).
const URL_ENCODE_SET: &AsciiSet = &CONTROLS.add(b' ');

/// Resolved terminal capabilities passed into [`crate::output::CliView::rows_rich`] (`R85`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct TermCaps {
    /// Whether the target stream accepts ANSI SGR styling sequences (`R65`).
    pub color: bool,
    /// Whether the target stream accepts OSC-8 hyperlink escape sequences (`R85`).
    pub hyperlinks: bool,
}

impl TermCaps {
    /// Construct plain capabilities (no ANSI color, no OSC-8 hyperlinks).
    #[must_use]
    pub const fn plain() -> Self {
        Self {
            color: false,
            hyperlinks: false,
        }
    }

    /// Detect live stdout capabilities from resolved `color_enabled` (`R65` + `R85`).
    #[must_use]
    pub fn detect_stdout(color_enabled: bool) -> Self {
        let hyperlinks =
            color_enabled && supports_hyperlinks::on(supports_hyperlinks::Stream::Stdout);
        Self {
            color: color_enabled,
            hyperlinks,
        }
    }
}

/// Escape ASCII and Unicode control characters so untrusted cell labels can never forge
/// terminal escape sequences (`R85` P4 / AC5), leaving printable `[` and spaces literal.
#[must_use]
pub fn escape_label(label: &str) -> String {
    let mut out = String::with_capacity(label.len());
    for ch in label.chars() {
        if ch.is_control() {
            for esc in ch.escape_default() {
                out.push(esc);
            }
        } else {
            out.push(ch);
        }
    }
    out
}

/// Percent-encode control bytes and spaces in `url` before handing it to `anstyle-hyperlink`.
#[must_use]
pub fn sanitize_url(url: &str) -> String {
    utf8_percent_encode(url, URL_ENCODE_SET).to_string()
}

/// Wrap `label` in an OSC-8 hyperlink targeting `url` when `enabled` is true (`R85`).
///
/// Always control-escapes `label` and percent-encodes control/space bytes in `url`.
/// When `enabled` is false, `Hyperlink::default()` renders zero escape bytes.
#[must_use]
pub fn format_osc8_link(label: &str, url: &str, enabled: bool) -> String {
    let safe_label = escape_label(label);
    if !enabled {
        let link = Hyperlink::<&str>::default();
        return format!("{link}{safe_label}{link:#}");
    }
    let safe_url = sanitize_url(url);
    let link = Hyperlink::with_url(&safe_url);
    format!("{link}{safe_label}{link:#}")
}

/// Wrap a filesystem path in a clickable `file://` OSC-8 hyperlink when `enabled` is true (`R85`).
///
/// Relative paths (which have no valid `file://` URI) fall back cleanly to the escaped plain path.
#[must_use]
pub fn format_file_link(path: &Path, enabled: bool) -> String {
    let display = path.display().to_string();
    let safe_label = escape_label(&display);
    if !enabled || !path.is_absolute() {
        return safe_label;
    }
    match anstyle_hyperlink::path_to_url(path) {
        Some(url) => {
            let safe_url = sanitize_url(&url);
            let link = Hyperlink::with_url(&safe_url);
            format!("{link}{safe_label}{link:#}")
        }
        None => safe_label,
    }
}

/// Coarse relative-time buckets matching `py-launch-blueprint`'s `relative_time` contract (`R85`).
const RELATIVE_UNITS: &[(u64, &str)] = &[
    (365 * 86_400, "year"),
    (30 * 86_400, "month"),
    (86_400, "day"),
    (3_600, "hour"),
    (60, "minute"),
];

/// Render a coarse human delta (`"just now"`, `"2 days ago"`, `"in 2 days"`) from caller-supplied
/// UTC Unix timestamps (`R85` AC6).
#[must_use]
pub fn relative_time(moment_unix_secs: i64, now_unix_secs: i64) -> String {
    let diff = now_unix_secs.saturating_sub(moment_unix_secs);
    let future = diff < 0;
    let seconds = diff.unsigned_abs();
    if seconds < 60 {
        return "just now".to_owned();
    }
    for &(unit_seconds, name) in RELATIVE_UNITS {
        let count = seconds / unit_seconds;
        if count >= 1 {
            let suffix = if count == 1 { "" } else { "s" };
            let phrase = format!("{count} {name}{suffix}");
            return if future {
                format!("in {phrase}")
            } else {
                format!("{phrase} ago")
            };
        }
    }
    "just now".to_owned()
}
