//! Output format resolution, exporter seam, renderers, atomic file writes, and error envelopes
//! (`R66`, `R67`, `R85`).

use std::collections::BTreeMap;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};

use anstyle::{AnsiColor, Color, Style};
use rs_launch_blueprint_core::{DomainError, ErrorCode, ErrorEnvelope, OutputFormat, Project};
use serde::Serialize;
use tabled::builder::Builder;
use tabled::settings::Style as TableStyle;
use tempfile::NamedTempFile;

use crate::args::{BuildInfo, render_version_line};
use crate::rich::{TermCaps, escape_label, format_file_link};

/// Return `true` if `format` is a machine-readable format under CLI Design Standard R7.2 / R7.8
/// (`json` and `name`).
#[must_use]
pub const fn is_machine_format(format: OutputFormat) -> bool {
    matches!(format, OutputFormat::Json | OutputFormat::Name)
}

/// Resolve the active [`OutputFormat`] from explicit CLI flags, `RSLBP_OUTPUT`, `--json`, and
/// layered config (`R66` AC1–AC4).
///
/// Rejects `--json` paired with any explicit `-o`/`--output <format>` (including `-o json`) with
/// `RSLB201` (exit `2`).
pub fn resolve_output_format(
    explicit_flag: Option<OutputFormat>,
    env_output: Option<OutputFormat>,
    json_flag: bool,
    config_format: OutputFormat,
) -> Result<OutputFormat, DomainError> {
    if json_flag && explicit_flag.is_some() {
        return Err(DomainError::Usage {
            message: "conflicting flags: --json cannot be combined with --output (-o)".to_owned(),
            hint: Some("pass either --json or -o/--output <format>, not both".to_owned()),
        });
    }
    if json_flag {
        return Ok(OutputFormat::Json);
    }
    if let Some(fmt) = explicit_flag {
        return Ok(fmt);
    }
    if let Some(fmt) = env_output {
        return Ok(fmt);
    }
    Ok(config_format)
}

/// Single result contract consumed by all four format renderers (`R66` ALT-3, `R85` A1).
///
/// Lives strictly inside `crates/cli` so `crates/core` and `crates/web` never couple to
/// terminal presentation (`R85` Amendment 2 / HEX-15).
pub trait CliView {
    /// Optional heading displayed above human table / Markdown output.
    fn table_title(&self) -> Option<String> {
        None
    }

    /// Column headers for table and Markdown renderers.
    fn columns(&self) -> Vec<&'static str>;

    /// Plain string cell rows aligned with [`Self::columns`].
    fn rows(&self) -> Vec<Vec<String>>;

    /// Capability-gated rich rows for the `table` renderer only (`R85`).
    ///
    /// Defaults to [`Self::rows`]; JSON, Markdown, and `name` never call this method.
    fn rows_rich(&self, _caps: TermCaps) -> Vec<Vec<String>> {
        self.rows()
    }

    /// Bare identifiers emitted one per line by the `name` renderer (`R66`).
    fn names(&self) -> Vec<String>;

    /// Plain fallback line emitted when [`Self::rows`] is empty.
    fn human_note(&self) -> Option<String> {
        None
    }

    /// Structured JSON wire representation (`R66`).
    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error>;
}

/// Renderable list of [`Project`] records.
#[derive(Debug, Clone, Serialize)]
pub struct ProjectListView {
    /// Projects returned by the service.
    pub projects: Vec<Project>,
}

impl CliView for ProjectListView {
    fn table_title(&self) -> Option<String> {
        Some(format!("Projects ({})", self.projects.len()))
    }

    fn columns(&self) -> Vec<&'static str> {
        vec!["Name", "Workspace", "ID"]
    }

    fn rows(&self) -> Vec<Vec<String>> {
        self.projects
            .iter()
            .map(|p| {
                vec![
                    p.name.clone(),
                    p.workspace.clone().unwrap_or_else(|| "-".to_owned()),
                    p.id.clone(),
                ]
            })
            .collect()
    }

    fn names(&self) -> Vec<String> {
        self.projects.iter().map(|p| p.id.clone()).collect()
    }

    fn human_note(&self) -> Option<String> {
        self.projects
            .is_empty()
            .then(|| "No project entries found.".to_owned())
    }

    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error> {
        serde_json::to_value(self)
    }
}

/// Renderable result for `project delete`.
#[derive(Debug, Clone, Serialize)]
pub struct ProjectDeletedView {
    /// Deleted project ID.
    pub id: String,
    /// `true` when executed with `--dry-run`.
    pub dry_run: bool,
}

impl CliView for ProjectDeletedView {
    fn columns(&self) -> Vec<&'static str> {
        vec!["ID", "Status"]
    }

    fn rows(&self) -> Vec<Vec<String>> {
        let status = if self.dry_run { "dry-run" } else { "deleted" };
        vec![vec![self.id.clone(), status.to_owned()]]
    }

    fn names(&self) -> Vec<String> {
        vec![self.id.clone()]
    }

    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error> {
        serde_json::to_value(self)
    }
}

/// Renderable single resolved configuration key/value/source (`config get` / `config set`).
#[derive(Debug, Clone, Serialize)]
pub struct ConfigValueView {
    /// Dotted configuration key name.
    pub key: String,
    /// Resolved value (masked for `token`, or `None` when unset).
    pub value: Option<String>,
    /// Provenance label (`config`, `default`, `file`, `dry-run`, `env`, `stored`, etc.).
    pub source: String,
}

impl CliView for ConfigValueView {
    fn columns(&self) -> Vec<&'static str> {
        vec!["Key", "Value", "Source"]
    }

    fn rows(&self) -> Vec<Vec<String>> {
        vec![vec![
            self.key.clone(),
            self.value.clone().unwrap_or_default(),
            self.source.clone(),
        ]]
    }

    fn names(&self) -> Vec<String> {
        vec![self.value.clone().unwrap_or_default()]
    }

    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error> {
        serde_json::to_value(self)
    }
}

/// Renderable full effective configuration (`config show`).
#[derive(Debug, Clone, Serialize)]
pub struct ConfigShowView {
    /// Effective configuration entries in deterministic order.
    pub entries: Vec<ConfigValueView>,
    /// Contributing configuration file paths in precedence order.
    pub sources: Vec<String>,
}

impl CliView for ConfigShowView {
    fn table_title(&self) -> Option<String> {
        Some("Configuration".to_owned())
    }

    fn columns(&self) -> Vec<&'static str> {
        vec!["Key", "Value", "Source"]
    }

    fn rows(&self) -> Vec<Vec<String>> {
        self.entries
            .iter()
            .map(|e| {
                vec![
                    e.key.clone(),
                    e.value.clone().unwrap_or_else(|| "-".to_owned()),
                    e.source.clone(),
                ]
            })
            .collect()
    }

    fn names(&self) -> Vec<String> {
        self.entries.iter().map(|e| e.key.clone()).collect()
    }

    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error> {
        serde_json::to_value(self)
    }
}

/// Renderable config file path carrying capability-gated OSC-8 `file://` links (`R85`).
#[derive(Debug, Clone, Serialize)]
pub struct ConfigPathView {
    /// Resolved configuration path.
    pub path: PathBuf,
    /// Whether the path currently exists on disk.
    pub exists: bool,
}

impl CliView for ConfigPathView {
    fn columns(&self) -> Vec<&'static str> {
        vec!["Config path", "Exists"]
    }

    fn rows(&self) -> Vec<Vec<String>> {
        vec![vec![
            self.path.display().to_string(),
            if self.exists { "yes" } else { "no" }.to_owned(),
        ]]
    }

    fn rows_rich(&self, caps: TermCaps) -> Vec<Vec<String>> {
        vec![vec![
            format_file_link(&self.path, caps.hyperlinks),
            if self.exists { "yes" } else { "no" }.to_owned(),
        ]]
    }

    fn names(&self) -> Vec<String> {
        vec![self.path.display().to_string()]
    }

    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error> {
        serde_json::to_value(self)
    }
}

/// Renderable version and build metadata (`R60` F267).
#[derive(Debug, Clone, Copy, Serialize)]
pub struct VersionView {
    /// Build metadata (`version`, `target`, `rustc`).
    #[serde(flatten)]
    pub build: BuildInfo,
}

impl CliView for VersionView {
    fn columns(&self) -> Vec<&'static str> {
        vec!["Version", "Target", "Rustc"]
    }

    fn rows(&self) -> Vec<Vec<String>> {
        vec![vec![
            self.build.version.to_owned(),
            self.build.target.to_owned(),
            self.build.rustc.to_owned(),
        ]]
    }

    fn names(&self) -> Vec<String> {
        vec![self.build.version.to_owned()]
    }

    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error> {
        serde_json::to_value(self.build)
    }
}

/// One diagnostic check row emitted by `rslbp diagnostics`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DiagnosticCheck {
    /// Check identifier.
    pub name: String,
    /// Status string (`ok`, `warn`, `error`).
    pub status: &'static str,
    /// Human-readable check detail.
    pub detail: String,
}

/// Renderable diagnostics report (`rslbp diagnostics`).
#[derive(Debug, Clone, Serialize)]
pub struct DiagnosticsReportView {
    /// Ordered diagnostic check results.
    pub checks: Vec<DiagnosticCheck>,
}

impl DiagnosticsReportView {
    /// Return `true` if any diagnostic check reported `"error"`.
    #[must_use]
    pub fn has_error(&self) -> bool {
        self.checks.iter().any(|c| c.status == "error")
    }
}

impl CliView for DiagnosticsReportView {
    fn table_title(&self) -> Option<String> {
        Some("Diagnostics".to_owned())
    }

    fn columns(&self) -> Vec<&'static str> {
        vec!["Check", "Status", "Detail"]
    }

    fn rows(&self) -> Vec<Vec<String>> {
        self.checks
            .iter()
            .map(|c| vec![c.name.clone(), c.status.to_owned(), c.detail.clone()])
            .collect()
    }

    fn names(&self) -> Vec<String> {
        self.checks.iter().map(|c| c.name.clone()).collect()
    }

    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error> {
        serde_json::to_value(self)
    }
}

/// Redacted diagnostics bundle (`rslbp diagnostics --bundle`).
#[derive(Debug, Clone, Serialize)]
pub struct DiagnosticsBundleView {
    /// Binary SemVer version.
    pub version: String,
    /// Compilation target triple.
    pub target: String,
    /// Compiler version string.
    pub rustc: String,
    /// Individual diagnostic check rows.
    pub checks: Vec<DiagnosticCheck>,
    /// Active config file path.
    pub config_path: String,
    /// Whether the config file currently exists.
    pub config_exists: bool,
    /// Contributing config files actually loaded.
    pub loaded_paths: Vec<String>,
    /// Whether any credential was resolved.
    pub token_present: bool,
    /// Credential provenance when present.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token_source: Option<String>,
    /// `RSLBP_*` environment variables with sensitive keys redacted to `[REDACTED]`.
    pub env: BTreeMap<String, String>,
    /// Resolved default rotating log file path.
    pub log_file: String,
}

impl CliView for DiagnosticsBundleView {
    fn table_title(&self) -> Option<String> {
        Some("Diagnostics bundle".to_owned())
    }

    fn columns(&self) -> Vec<&'static str> {
        vec!["Field", "Value"]
    }

    fn rows(&self) -> Vec<Vec<String>> {
        let ok = self.checks.iter().filter(|c| c.status == "ok").count();
        let warn = self.checks.iter().filter(|c| c.status == "warn").count();
        let err = self.checks.iter().filter(|c| c.status == "error").count();
        let token = if self.token_present {
            format!(
                "present ({})",
                self.token_source.as_deref().unwrap_or("unknown")
            )
        } else {
            "absent".to_owned()
        };
        let loaded = if self.loaded_paths.is_empty() {
            "-".to_owned()
        } else {
            self.loaded_paths.join(", ")
        };
        let env_keys = if self.env.is_empty() {
            "-".to_owned()
        } else {
            self.env.keys().cloned().collect::<Vec<_>>().join(", ")
        };
        vec![
            vec!["version".to_owned(), self.version.clone()],
            vec!["target".to_owned(), self.target.clone()],
            vec!["rustc".to_owned(), self.rustc.clone()],
            vec![
                "checks".to_owned(),
                format!("{ok} ok / {warn} warn / {err} error"),
            ],
            vec!["config path".to_owned(), self.config_path.clone()],
            vec![
                "config exists".to_owned(),
                if self.config_exists { "yes" } else { "no" }.to_owned(),
            ],
            vec!["loaded configs".to_owned(), loaded],
            vec!["token".to_owned(), token],
            vec!["env".to_owned(), env_keys],
            vec!["log file".to_owned(), self.log_file.clone()],
        ]
    }

    fn names(&self) -> Vec<String> {
        vec![self.version.clone()]
    }

    fn to_json_value(&self) -> Result<serde_json::Value, serde_json::Error> {
        serde_json::to_value(self)
    }
}

/// Escape a single GFM table cell (`R66` AC10).
///
/// Escapes `\` and `|`, flattens embedded newlines to single spaces, and escapes any
/// remaining control bytes (including `ESC` `0x1b` and `BEL` `0x07`).
#[must_use]
pub fn escape_markdown_cell(cell: &str) -> String {
    let mut out = String::with_capacity(cell.len());
    let mut chars = cell.chars().peekable();
    while let Some(ch) = chars.next() {
        match ch {
            '\\' => out.push_str(r"\\"),
            '|' => out.push_str(r"\|"),
            '\r' => {
                if chars.peek() == Some(&'\n') {
                    let _ = chars.next();
                }
                out.push(' ');
            }
            '\n' => out.push(' '),
            c if c.is_control() => {
                for esc in c.escape_default() {
                    out.push(esc);
                }
            }
            other => out.push(other),
        }
    }
    out
}

fn json_io_error(err: serde_json::Error) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, err)
}

/// Render `view` into `out` in `format` (`R66`, `R85`).
///
/// Only `OutputFormat::Table` consults `caps` or `rows_rich`; `Json`, `Markdown`, and `Name`
/// emit zero ANSI/OSC escape bytes under all terminal states (`R66` AC11).
pub fn render_view(
    view: &dyn CliView,
    format: OutputFormat,
    caps: TermCaps,
    out: &mut dyn Write,
) -> io::Result<()> {
    match format {
        OutputFormat::Json => {
            let value = view.to_json_value().map_err(json_io_error)?;
            serde_json::to_writer_pretty(&mut *out, &value).map_err(json_io_error)?;
            out.write_all(b"\n")
        }
        OutputFormat::Markdown => render_markdown(view, out),
        OutputFormat::Name => {
            for name in view.names() {
                let safe = escape_label(&name);
                writeln!(out, "{safe}")?;
            }
            Ok(())
        }
        OutputFormat::Table => render_table(view, caps, out),
    }
}

/// Render version output adhering to R60 F267 option (b): single line `rslbp <semver>\n` for
/// human/name modes and `{"version","target","rustc"}` JSON for `-o json` / `--json`.
pub fn render_version(format: OutputFormat, out: &mut dyn Write) -> io::Result<()> {
    match format {
        OutputFormat::Json => {
            let view = VersionView {
                build: crate::args::build_info(),
            };
            render_view(&view, OutputFormat::Json, TermCaps::plain(), out)
        }
        OutputFormat::Markdown => {
            let view = VersionView {
                build: crate::args::build_info(),
            };
            render_view(&view, OutputFormat::Markdown, TermCaps::plain(), out)
        }
        OutputFormat::Table | OutputFormat::Name => out.write_all(render_version_line().as_bytes()),
    }
}

fn render_table(view: &dyn CliView, caps: TermCaps, out: &mut dyn Write) -> io::Result<()> {
    let columns = view.columns();
    let rows = view.rows_rich(caps);
    if columns.is_empty() || rows.is_empty() {
        if let Some(note) = view.human_note() {
            writeln!(out, "{}", escape_label(&note))?;
        }
        return Ok(());
    }

    if let Some(title) = view.table_title() {
        let safe_title = escape_label(&title);
        if caps.color {
            let style = Style::new().bold();
            writeln!(out, "{style}{safe_title}{style:#}")?;
        } else {
            writeln!(out, "{safe_title}")?;
        }
    }

    let mut builder = Builder::default();
    if caps.color {
        let header_style = Style::new()
            .bold()
            .fg_color(Some(Color::Ansi(AnsiColor::Cyan)));
        builder.push_record(
            columns
                .iter()
                .map(|c| format!("{header_style}{c}{header_style:#}")),
        );
    } else {
        builder.push_record(columns.iter().copied());
    }

    for row in rows {
        let sanitized: Vec<String> = row
            .into_iter()
            .map(|cell| {
                // Preserve intentional OSC-8 hyperlinks emitted by `rows_rich` when hyperlinks
                // are active, while flattening raw newlines to keep single-line row geometry.
                if caps.hyperlinks && cell.contains("\x1b]8;;") {
                    cell.replace(['\r', '\n'], " ")
                } else {
                    escape_label(&cell.replace(['\r', '\n'], " "))
                }
            })
            .collect();
        builder.push_record(sanitized);
    }

    let mut table = builder.build();
    table.with(TableStyle::sharp());
    writeln!(out, "{table}")
}

fn render_markdown(view: &dyn CliView, out: &mut dyn Write) -> io::Result<()> {
    let columns = view.columns();
    let rows = view.rows();
    if columns.is_empty() || rows.is_empty() {
        if let Some(note) = view.human_note() {
            writeln!(out, "{}", escape_markdown_cell(&note))?;
        }
        return Ok(());
    }

    if let Some(title) = view.table_title() {
        writeln!(out, "## {}", escape_markdown_cell(&title))?;
        writeln!(out)?;
    }

    let escaped_cols: Vec<String> = columns.iter().map(|c| escape_markdown_cell(c)).collect();
    writeln!(out, "| {} |", escaped_cols.join(" | "))?;
    let sep: Vec<&str> = columns.iter().map(|_| "---").collect();
    writeln!(out, "| {} |", sep.join(" | "))?;

    for row in rows {
        let cells: Vec<String> = row.iter().map(|c| escape_markdown_cell(c)).collect();
        writeln!(out, "| {} |", cells.join(" | "))?;
    }
    Ok(())
}

fn port_io_error(source: io::Error) -> DomainError {
    DomainError::Port(rs_launch_blueprint_core::PortError::Io { source })
}

/// Atomically persist `bytes` to `target` using a same-directory [`NamedTempFile`] (`R66` AC12,
/// AC13).
///
/// When `no_clobber` is `true` and `target` already exists, returns [`DomainError::Conflict`]
/// (`RSLB501`, exit `5`) without modifying the existing file.
pub fn write_output_file_atomic(
    target: &Path,
    bytes: &[u8],
    no_clobber: bool,
) -> Result<(), DomainError> {
    let parent = match target.parent() {
        Some(p) if !p.as_os_str().is_empty() => p,
        _ => Path::new("."),
    };
    fs::create_dir_all(parent).map_err(port_io_error)?;

    let mut temp = NamedTempFile::new_in(parent).map_err(port_io_error)?;
    temp.write_all(bytes).map_err(port_io_error)?;
    temp.as_file().sync_all().map_err(port_io_error)?;

    if no_clobber {
        temp.persist_noclobber(target).map_err(|persist_err| {
            if persist_err.error.kind() == io::ErrorKind::AlreadyExists {
                DomainError::Conflict {
                    message: format!(
                        "refusing to overwrite existing output file '{}' (--no-clobber)",
                        target.display()
                    ),
                    hint: Some("omit --no-clobber or choose a different --output-file".to_owned()),
                }
            } else {
                port_io_error(persist_err.error)
            }
        })?;
    } else {
        temp.persist(target)
            .map_err(|persist_err| port_io_error(persist_err.error))?;
    }

    Ok(())
}

/// Emit a formatted error to `err` following `R66` AC14 and `R67` AC1/AC2.
///
/// - Machine formats (`json`, `name`): one JSON line `{"error":{"code","message","hint"?}}\n`.
/// - Human formats (`table`, `markdown`): `error[<CODE>]: <message>\n` plus optional `hint: <text>\n`.
pub fn render_error(
    code: ErrorCode,
    message: &str,
    hint: Option<&str>,
    format: OutputFormat,
    stderr_color: bool,
    err: &mut dyn Write,
) -> io::Result<()> {
    if is_machine_format(format) {
        let envelope = ErrorEnvelope::new(code, message, hint.map(str::to_owned));
        serde_json::to_writer(&mut *err, &envelope).map_err(json_io_error)?;
        err.write_all(b"\n")
    } else if format == OutputFormat::Table && stderr_color {
        let err_style = Style::new()
            .bold()
            .fg_color(Some(Color::Ansi(AnsiColor::Red)));
        let hint_style = Style::new()
            .bold()
            .fg_color(Some(Color::Ansi(AnsiColor::Yellow)));
        writeln!(
            err,
            "{err_style}error[{}]:{err_style:#} {message}",
            code.as_str()
        )?;
        if let Some(h) = hint {
            writeln!(err, "{hint_style}hint:{hint_style:#} {h}")?;
        }
        Ok(())
    } else {
        writeln!(err, "error[{}]: {message}", code.as_str())?;
        if let Some(h) = hint {
            writeln!(err, "hint: {h}")?;
        }
        Ok(())
    }
}
